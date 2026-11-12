#!/usr/bin/env python3
"""Diff two work-RAM dumps and annotate the changed regions.

Usage:
    python3 tools/ram_diff.py before.bin after.bin
    python3 tools/ram_diff.py before.bin after.bin --base 0xff0000
    python3 tools/ram_diff.py before.bin after.bin --region actor
    python3 tools/ram_diff.py before.bin after.bin --min-run 2 --json

Consecutive changed bytes are printed as runs with their old/new bytes. Runs are
annotated with the known actor slot, object record or race list they fall into,
using the shared tables in `ram_layout.py`. Unknown addresses stay unannotated.
"""
from __future__ import annotations

import argparse
import json
import sys

import ram_layout as layout

LIST_REGIONS = [
    (layout.OPPONENT_FREE_LIST, 0xFF19C4, "Race_ram_OpponentFreeList"),
    (layout.TRAFFIC_FREE_LIST, layout.ACTIVE_COUNT, "Race_ram_TrafficFreeList"),
    (layout.ACTIVE_COUNT, layout.ACTOR_LIST, "Race_ram_ActiveActorCount"),
    (layout.ACTOR_LIST, 0xFF1A4C, "actor list (ram_FF1A08/Race_ram_ActiveActorList)"),
    (layout.VISIBLE_LIST, 0xFF1E50, "Road_VisibleObjectList"),
    (0xFF272A, 0xFF2EAA, "actor shadow/snapshot region"),
]


def changed_runs(before: layout.Dump, after: layout.Dump) -> list[tuple[int, int]]:
    """Return inclusive `(start, end)` address runs of consecutive changes."""
    runs: list[tuple[int, int]] = []
    start: int | None = None
    previous: int | None = None
    for offset in range(before.size):
        if before.data[offset] == after.data[offset]:
            continue
        address = before.base + offset
        if start is None:
            start = address
        elif previous is not None and address != previous + 1:
            runs.append((start, previous))
            start = address
        previous = address
    if start is not None and previous is not None:
        runs.append((start, previous))
    return runs


def object_range(dump_before: layout.Dump, dump_after: layout.Dump) -> int:
    count = max(layout.object_count(dump_before), layout.object_count(dump_after))
    return layout.OBJECT_ARRAY + count * layout.OBJECT_SIZE


def classify(address: int, slots: list[tuple[int, str]], object_end: int) -> tuple[str, dict]:
    match = layout.actor_slot_for(address, slots)
    if match:
        return "actor", {"base": match[0], "name": match[1]}
    if layout.OBJECT_ARRAY <= address < object_end:
        record = (address - layout.OBJECT_ARRAY) // layout.OBJECT_SIZE
        offset = (address - layout.OBJECT_ARRAY) % layout.OBJECT_SIZE
        return "object", {"index": record, "offset": offset}
    for start, end, name in LIST_REGIONS:
        if start <= address < end:
            return "list", {"name": name}
    return "other", {}


def actor_annotations(dump_before: layout.Dump, dump_after: layout.Dump,
                      start: int, end: int, detail: dict,
                      symbols: dict[int, str]) -> list[str]:
    base, name = detail["base"], detail["name"]
    seen: list[int] = []
    lines: list[str] = []
    for address in range(start, end + 1):
        field = layout.actor_field_at(address - base)
        if field is None or field[0] in seen:
            continue
        offset, width = field
        seen.append(offset)
        old = dump_before.read(base + offset, width)
        new = dump_after.read(base + offset, width)
        symbol = symbols.get(offset, "(unnamed)")
        lines.append(
            f"    actor {name} @ 0x{base:06X}\n"
            f"      +${offset:02X} {layout.WIDTH_NAMES[width]} "
            f"{layout.format_value(old, width)} -> {layout.format_value(new, width)} "
            f"{symbol}"
        )
    return lines


def object_annotations(dump_before: layout.Dump, dump_after: layout.Dump,
                       start: int, end: int, detail: dict) -> list[str]:
    record = detail["index"]
    base = layout.OBJECT_ARRAY + record * layout.OBJECT_SIZE
    seen: list[int] = []
    lines: list[str] = []
    for address in range(start, end + 1):
        field = layout.object_field_at((address - base) % layout.OBJECT_SIZE)
        if field is None or field[0] in seen:
            continue
        offset, symbol = field
        old = dump_before.u16(base + offset)
        new = dump_after.u16(base + offset)
        seen.append(offset)
        lines.append(
            f"    object record {record} @ 0x{base:06X}\n"
            f"      +${offset:02X} word "
            f"{layout.format_value(old, 2)} -> {layout.format_value(new, 2)} {symbol}"
        )
    return lines


def bytes_hex(data: bytes) -> str:
    return " ".join(f"{value:02X}" for value in data)


def build_run(dump_before: layout.Dump, dump_after: layout.Dump,
              start: int, end: int, slots: list[tuple[int, str]],
              symbols: dict[int, str], object_end: int) -> dict:
    region, detail = classify(start, slots, object_end)
    old = dump_before.data[start - dump_before.base:end - dump_before.base + 1]
    new = dump_after.data[start - dump_after.base:end - dump_after.base + 1]
    annotations: list[str] = []
    if region == "actor":
        annotations = actor_annotations(dump_before, dump_after, start, end,
                                        detail, symbols)
    elif region == "object":
        annotations = object_annotations(dump_before, dump_after, start, end, detail)
    elif region == "list":
        annotations = [f"    list {detail['name']}"]
    return {
        "start": f"0x{start:06X}",
        "end": f"0x{end:06X}",
        "length": end - start + 1,
        "old": bytes_hex(old),
        "new": bytes_hex(new),
        "region": region,
        "annotations": annotations,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("before", help="earlier work-RAM dump")
    parser.add_argument("after", help="later work-RAM dump")
    parser.add_argument("--base", default=f"0x{layout.DEFAULT_BASE:06X}",
                        help="dump load address (default: 0xff0000)")
    parser.add_argument("--min-run", type=int, default=1,
                        help="ignore runs shorter than N bytes (default: 1)")
    parser.add_argument("--region", choices=("all", "actor", "object"), default="all",
                        help="only print runs from this region (default: all)")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    args = parser.parse_args()

    try:
        base = layout.parse_address(args.base)
    except ValueError:
        print(f"error: invalid base address: {args.base}", file=sys.stderr)
        return 2
    try:
        before = layout.Dump(args.before, base)
        after = layout.Dump(args.after, base)
    except OSError as exc:
        print(f"error: cannot read dump: {exc}", file=sys.stderr)
        return 2
    if before.size != after.size:
        print(f"error: dump sizes differ ({before.size} != {after.size})",
              file=sys.stderr)
        return 2
    if before.size != layout.RAM_SIZE:
        print(f"warning: expected {layout.RAM_SIZE} bytes, got {before.size}",
              file=sys.stderr)

    equates = layout.parse_equates()
    symbols = layout.actor_symbols(equates)
    slots = layout.actor_slots(equates)
    end = object_range(before, after)

    runs = []
    for start, stop in changed_runs(before, after):
        if stop - start + 1 < args.min_run:
            continue
        run = build_run(before, after, start, stop, slots, symbols, end)
        if args.region != "all" and run["region"] != args.region:
            continue
        runs.append(run)

    if args.json:
        print(json.dumps({
            "before": str(before.path),
            "after": str(after.path),
            "base": f"0x{base:06X}",
            "min_run": args.min_run,
            "region": args.region,
            "runs": runs,
        }, indent=2))
        return 0

    print(f"Before: {before.path}")
    print(f"After:  {after.path}")
    print(f"Base: 0x{base:06X}  min-run: {args.min_run}  region: {args.region}")
    print(f"Changed runs: {len(runs)}")
    for run in runs:
        print()
        print(f"{run['start']}-{run['end']} ({run['length']} bytes, {run['region']})")
        print(f"  old: {run['old']}")
        print(f"  new: {run['new']}")
        for annotation in run["annotations"]:
            print(annotation)
    return 0


if __name__ == "__main__":
    sys.exit(main())

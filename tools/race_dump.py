#!/usr/bin/env python3
"""Decode a 64 KiB Genesis work-RAM dump into race structures.

Usage:
    python3 tools/race_dump.py analysis/dumps/actor_running_ram.bin
    python3 tools/race_dump.py DUMP --actor 0xff1eaa
    python3 tools/race_dump.py DUMP --json
    python3 tools/race_dump.py DUMP --base 0xff0000

Summary mode prints the active/free lists, every named actor slot, the road
object array and the visible-object list. `--actor ADDR` prints all fields of a
single actor struct. Unknown offsets are shown as `$XX (unnamed)`; nothing is
guessed from a value.
"""
from __future__ import annotations

import argparse
import json
import sys

import ram_layout as layout


def actor_name(address: int, slots: list[tuple[int, str]]) -> str | None:
    match = layout.actor_slot_for(address, slots)
    return match[1] if match else None


def decode_actor(dump: layout.Dump, address: int, name: str | None,
                 symbols: dict[int, str]) -> dict:
    fields = []
    for offset, width in layout.ACTOR_FIELDS:
        fields.append({
            "offset": offset,
            "width": width,
            "symbol": symbols.get(offset),
            "value": dump.read(address + offset, width),
        })
    return {
        "address": f"0x{address:06X}",
        "name": name,
        "fields": fields,
    }


def selected_actor(dump: layout.Dump, address: int, name: str | None) -> dict:
    return {
        "address": f"0x{address:06X}",
        "name": name,
        "index": dump.u8(address + 0x71),
        "type": dump.u16(address + 0x16),
        "speed": dump.u16(address + 0x12),
        "x": dump.u32(address + 0x04),
        "pos_y": dump.u16(address + 0x30),
        "control_flags": dump.u8(address + 0x68),
        "state_flags": dump.u8(address + 0x69),
    }


def decode_list(dump: layout.Dump, address: int, slots: list[tuple[int, str]],
                limit: int = 32) -> dict:
    entries, terminated = layout.read_pointer_list(dump, address, limit)
    payload = []
    for value in entries:
        if value == 0xFFFFFFFF:
            break
        payload.append({
            "address": f"0x{value:08X}",
            "name": actor_name(value, slots),
            "valid": dump.valid(value, layout.ACTOR_SIZE),
        })
    return {
        "address": f"0x{address:06X}",
        "entries": payload,
        "terminated": terminated,
    }


def decode_free_list(dump: layout.Dump, address: int, slots: list[tuple[int, str]]) -> dict:
    count, entries, complete = layout.read_free_list(dump, address)
    payload = []
    for value in entries:
        payload.append({
            "address": f"0x{value:08X}",
            "name": actor_name(value, slots),
            "valid": dump.valid(value, layout.ACTOR_SIZE),
        })
    return {
        "address": f"0x{address:06X}",
        "count": count,
        "entries": payload,
        "complete": complete,
    }


def decode_objects(dump: layout.Dump) -> dict:
    count = layout.object_count(dump)
    records = []
    for index in range(count):
        address = layout.OBJECT_ARRAY + index * layout.OBJECT_SIZE
        fields = []
        for offset, name in layout.OBJECT_FIELDS:
            fields.append({
                "offset": offset,
                "symbol": name,
                "value": dump.u16(address + offset),
            })
        records.append({
            "index": index,
            "address": f"0x{address:06X}",
            "fields": fields,
        })
    return {
        "count": count,
        "count_address": f"0x{layout.OBJECT_ENTRY_COUNT:06X}",
        "track_object_count": dump.u16(layout.TRACK_OBJECT_COUNT),
        "array_address": f"0x{layout.OBJECT_ARRAY:06X}",
        "records": records,
    }


def decode_visible(dump: layout.Dump, count: int) -> dict:
    entries, terminated = layout.read_visible_list(dump, layout.VISIBLE_LIST)
    payload = []
    for value in entries:
        payload.append({
            "index": value,
            "valid": value < count,
        })
    return {
        "address": f"0x{layout.VISIBLE_LIST:06X}",
        "entries": payload,
        "terminated": terminated,
        "uninitialized": not terminated and not any(entries),
    }


def summary_payload(dump: layout.Dump, equates: dict[str, int],
                    slots: list[tuple[int, str]]) -> dict:
    count = dump.u16(layout.ACTIVE_COUNT)
    objects = decode_objects(dump)
    return {
        "dump": str(dump.path),
        "base": f"0x{dump.base:06X}",
        "size": dump.size,
        "active_actor_count": count,
        "actor_list": decode_list(dump, layout.ACTOR_LIST, slots),
        "active_list": decode_list(dump, layout.ACTIVE_LIST, slots),
        "opponent_free_list": decode_free_list(dump, layout.OPPONENT_FREE_LIST, slots),
        "traffic_free_list": decode_free_list(dump, layout.TRAFFIC_FREE_LIST, slots),
        "actors": [selected_actor(dump, address, name) for address, name in slots],
        "objects": objects,
        "visible_list": decode_visible(dump, objects["count"]),
    }


def hex_pointer(value: int) -> str:
    return f"${value:08X}"


def print_list(payload: dict, label: str) -> None:
    entries = payload["entries"]
    suffix = "" if payload["terminated"] else " (no terminator)"
    if payload.get("uninitialized"):
        suffix = " (uninitialized: no $FFFF terminator)"
    print(f"  {label} @ {payload['address']}: {len(entries)} entries{suffix}")
    for entry in entries:
        name = entry.get("name") or ""
        valid = "" if entry.get("valid", True) else " (out of dump)"
        print(f"    {entry['address']} {name}{valid}".rstrip())


def print_free_list(payload: dict, label: str) -> None:
    suffix = "" if payload["complete"] else " (count exceeds read limit)"
    print(f"  {label} @ {payload['address']}: count={payload['count']}{suffix}")
    for entry in payload["entries"]:
        name = entry.get("name") or ""
        valid = "" if entry.get("valid", True) else " (out of dump)"
        print(f"    {entry['address']} {name}{valid}".rstrip())


def print_summary(payload: dict) -> None:
    print(f"Dump: {payload['dump']}")
    print(f"Base: {payload['base']}  size: {payload['size']} bytes")
    print()
    print("Actor lists")
    print(f"  Race_ram_ActiveActorCount @ $FF1A06 = {payload['active_actor_count']}")
    print_list(payload["actor_list"], "actor list (AI loop, from Race_ActorList)")
    print_list(payload["active_list"], "active list (opponents; count includes PlayerA)")
    print_free_list(payload["opponent_free_list"], "Race_ram_OpponentFreeList")
    print_free_list(payload["traffic_free_list"], "Race_ram_TrafficFreeList")
    print()
    print("Actor slots")
    print("  address   name                 idx type speed  X          PosY ctl st")
    for actor in payload["actors"]:
        print(
            f"  {actor['address']}  {actor['name']:<19} "
            f"{_hex(actor['index'], 2)} {_hex(actor['type'], 4)} "
            f"{_hex(actor['speed'], 4)} {_hex(actor['x'], 8)} "
            f"{_hex(actor['pos_y'], 4)} {_hex(actor['control_flags'], 2)} "
            f"{_hex(actor['state_flags'], 2)}"
        )
    print()
    objects = payload["objects"]
    print("Objects")
    print(f"  Race_ram_TrackObjectCount @ $FFD7CA = "
          f"{_hex(objects['track_object_count'], 4)} (staged this frame)")
    print(f"  object count @ {objects['count_address']} = {objects['count']}")
    print(f"  Road_ObjectArray @ {objects['array_address']}: {objects['count']} records")
    print("  idx addr    X     Y     Scale Limit Shape Flags  XOff  Shape2")
    for record in objects["records"]:
        values = {field["offset"]: field["value"] for field in record["fields"]}
        print(
            f"  {record['index']:>3} {record['address']} "
            f"{_hex(values[0x00], 4)} {_hex(values[0x02], 4)} "
            f"{_hex(values[0x04], 4)} {_hex(values[0x06], 4)} "
            f"{_hex(values[0x08], 4)} {_hex(values[0x0A], 4)} "
            f"{_hex(values[0x0C], 4)} {_hex(values[0x12], 4)}"
        )
    print()
    visible = payload["visible_list"]
    suffix = "" if visible["terminated"] else " (no $FFFF terminator)"
    if visible["uninitialized"]:
        suffix = " (uninitialized: no $FFFF terminator)"
    print(f"  Road_VisibleObjectList @ {visible['address']}: "
          f"{len(visible['entries'])} entries{suffix}")
    if visible["entries"] and not visible["uninitialized"]:
        parts = []
        for entry in visible["entries"]:
            mark = "" if entry["valid"] else "!"
            parts.append(f"{entry['index']}{mark}")
        print("    " + " ".join(parts))


def _hex(value: int | None, width: int) -> str:
    if value is None:
        return "??" * width
    return f"{value:0{width}X}"


def print_actor(payload: dict) -> None:
    name = payload["name"] or "(unknown slot)"
    print(f"Actor {payload['address']} {name}")
    for field in payload["fields"]:
        width = field["width"]
        symbol = field["symbol"] or "(unnamed)"
        print(
            f"  +${field['offset']:02X} {layout.WIDTH_NAMES[width]:<4} "
            f"${layout.format_value(field['value'], width)}  {symbol}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("dump", help="64 KiB work-RAM dump ($FF0000-$FFFFFF)")
    parser.add_argument("--base", default=f"0x{layout.DEFAULT_BASE:06X}",
                        help="dump load address (default: 0xff0000)")
    parser.add_argument("--actor", metavar="ADDR",
                        help="print one actor struct at ADDR")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    args = parser.parse_args()

    try:
        base = layout.parse_address(args.base)
    except ValueError:
        print(f"error: invalid base address: {args.base}", file=sys.stderr)
        return 2
    try:
        dump = layout.Dump(args.dump, base)
    except OSError as exc:
        print(f"error: cannot read {args.dump}: {exc}", file=sys.stderr)
        return 2
    if dump.size != layout.RAM_SIZE:
        print(f"warning: expected {layout.RAM_SIZE} bytes, got {dump.size}",
              file=sys.stderr)

    equates = layout.parse_equates()
    symbols = layout.actor_symbols(equates)
    slots = layout.actor_slots(equates)

    if args.actor:
        try:
            address = layout.parse_address(args.actor)
        except ValueError:
            print(f"error: invalid actor address: {args.actor}", file=sys.stderr)
            return 2
        if not dump.valid(address, layout.ACTOR_SIZE):
            print(f"error: actor address 0x{address:06X} is outside the dump",
                  file=sys.stderr)
            return 1
        name = actor_name(address, slots)
        payload = decode_actor(dump, address, name, symbols)
        if args.json:
            print(json.dumps(payload, indent=2))
        else:
            print_actor(payload)
        return 0

    payload = summary_payload(dump, equates, slots)
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print_summary(payload)
    return 0


if __name__ == "__main__":
    sys.exit(main())

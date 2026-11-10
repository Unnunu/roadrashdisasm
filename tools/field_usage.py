#!/usr/bin/env python3
"""Rank functions by fan-in and actor-offset coverage.

Usage:
    python3 tools/field_usage.py
    python3 tools/field_usage.py --offsets 36,38,3A,4C,4E --top 40
    python3 tools/field_usage.py --source-dir src --top 30
    python3 tools/field_usage.py --offsets RaceActor_AttackPhase --actor a1,a2
    python3 tools/field_usage.py --format markdown -o analysis/field_usage.md

The tool is intentionally static and cheap. It answers "where should the next
targeted deep dive go?" without reading whole functions or disassembly listings.
Unknown fields are printed as offsets/symbols for follow-up experiments.
"""
import argparse
import collections
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EQUATE_FILES = [
    ROOT / "src/core/ram_const.asm",
    ROOT / "src/core/unknown.asm",
    ROOT / "src/core/hw_const.asm",
]
CALL_RE = re.compile(r"\b(?:jsr|bsr(?:\.w)?|jmp)\s+\(?([A-Za-z_][\w.$]*)", re.I)
LABEL_RE = re.compile(r"^([A-Za-z_][\w.$]*):")
OFFSET_RE = re.compile(
    r"(?:\$([0-9A-Fa-f]{1,4})|([A-Za-z_][\w.$]*))\(([aA][0-7])\)"
)
EQUATE_RE = re.compile(r"^\s*([A-Za-z_][\w.$]*)\s+equ\s+\$([0-9A-Fa-f]+)\s*(?:;.*)?$")


def strip_comment(line):
    return line.split(";", 1)[0]


def parse_equates():
    values = {}
    for path in EQUATE_FILES:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line in text.splitlines():
            m = EQUATE_RE.match(line)
            if m:
                values.setdefault(m.group(1), int(m.group(2), 16))
    return values


def parse_offset(text, equates):
    text = text.strip()
    if not text:
        return None, ""
    if text.startswith("$"):
        try:
            return int(text[1:], 16), text.upper()
        except ValueError:
            return None, text
    if re.fullmatch(r"[0-9A-Fa-f]+", text):
        return int(text, 16), "$" + text.upper()
    if text in equates:
        return equates[text], text
    return None, text


def parse_target(text, equates):
    value, label = parse_offset(text, equates)
    return value, label


def iter_sources(source_dir):
    root = Path(source_dir)
    if not root.is_absolute():
        root = ROOT / root
    if not root.exists():
        raise SystemExit(f"source directory not found: {root}")
    return sorted(root.rglob("*.asm"))


def scan(sources, actor_regs, equates):
    functions = {}
    callers = collections.Counter()

    for path in sources:
        current = None
        rel = str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path)
        for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = strip_comment(raw)
            label = LABEL_RE.match(line)
            if label:
                name = label.group(1)
                if not name.startswith("."):
                    current = name
                    functions.setdefault(name, {"file": rel, "offsets": set(),
                                                 "labels": []})
                    functions[name]["labels"].append((rel, raw.strip()))
            if current is None:
                continue
            for m in CALL_RE.finditer(line):
                target = m.group(1).split(".", 1)[0]
                callers[target] += 1
            for m in OFFSET_RE.finditer(line):
                reg = m.group(3).lower()
                if reg not in actor_regs:
                    continue
                value, label_text = parse_target(m.group(1) or m.group(2), equates)
                if value is None:
                    label_text = m.group(1) or m.group(2)
                    value = -1
                functions[current]["offsets"].add((value, label_text))

    return functions, callers


def fmt_offset(value, label):
    if value >= 0:
        return f"${value:02X}"
    return label


def format_table(headers, rows):
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(str(cell)))
    out = ["  ".join(h.ljust(widths[i]) for i, h in enumerate(headers))]
    out.append("  ".join("-" * w for w in widths))
    for row in rows:
        out.append("  ".join(str(cell).ljust(widths[i]) for i, cell in enumerate(row)))
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--source-dir", default="src/race",
                    help="source root (default: src/race)")
    ap.add_argument("--actor", default="a1,a2",
                    help="actor registers to inspect (default: a1,a2)")
    ap.add_argument("--offsets", default="",
                    help="comma-separated offsets/symbols to prioritize; empty = all")
    ap.add_argument("--top", type=int, default=40, help="rows per table (default: 40)")
    ap.add_argument("--format", choices=("text", "markdown"), default="text")
    ap.add_argument("-o", "--output", help="write report here instead of stdout")
    args = ap.parse_args()

    actor_regs = {r.strip().lower() for r in args.actor.split(",") if r.strip()}
    if not actor_regs:
        raise SystemExit("no actor registers selected")
    equates = parse_equates()

    wanted = {}
    for token in args.offsets.split(","):
        if not token.strip():
            continue
        value, label = parse_offset(token, equates)
        wanted[label] = value

    functions, callers = scan(iter_sources(args.source_dir), actor_regs, equates)

    rows = []
    offset_counts = collections.Counter()
    for name, info in sorted(functions.items()):
        values = {v for v, _ in info["offsets"] if v >= 0}
        labels = {l for _, l in info["offsets"]}
        matched = sorted(
            {fmt_offset(v, l) for l, v in wanted.items() if v >= 0 and v in values}
        )
        unknown = sorted(
            {fmt_offset(v, l) for l, v in wanted.items() if v >= 0 and v not in values}
        )
        rows.append({
            "function": name,
            "file": info["file"],
            "callers": callers.get(name, 0),
            "offsets": values,
            "labels": labels,
            "matched": matched,
            "unknown": unknown,
        })
        for value, label in info["offsets"]:
            offset_counts[fmt_offset(value, label)] += 1

    for row in rows:
        row["offset_text"] = ",".join(sorted(
            {fmt_offset(v, l) for v, l in functions[row["function"]]["offsets"]},
            key=lambda s: (len(s), s),
        ))

    lines = []
    if args.format == "markdown":
        lines.append("# Field usage / fan-in\n")
        lines.append("## Fan-in\n")
        lines.append("| Function | File | Callers | Actor offsets |")
        lines.append("|---|---|---|---|")
        for row in sorted(rows, key=lambda r: (-r["callers"], r["function"]))[:args.top]:
            lines.append(f"| `{row['function']}` | `{row['file']}` | {row['callers']} | "
                         f"`{row['offset_text'] or '-'}` |")
        lines.append("\n## Offset coverage\n")
        lines.append("| Function | File | Callers | Matched | Missing |")
        lines.append("|---|---|---|---|---|")
        for row in sorted(rows, key=lambda r: (-len(r["matched"]), -r["callers"],
                                               r["function"]))[:args.top]:
            if wanted and not row["matched"]:
                continue
            lines.append(f"| `{row['function']}` | `{row['file']}` | {row['callers']} | "
                         f"`{','.join(row['matched']) or '-'}` | "
                         f"`{','.join(row['unknown']) or '-'}` |")
        lines.append("\n## Offset use counts\n")
        lines.append("| Offset | Functions |")
        lines.append("|---|---|")
        for key, count in sorted(offset_counts.items()):
            lines.append(f"| `{key}` | {count} |")
    else:
        lines.append("Fan-in (top %d)" % args.top)
        top_rows = [
            (r["function"], r["file"], r["callers"], r["offset_text"] or "-")
            for r in sorted(rows, key=lambda r: (-r["callers"], r["function"]))[:args.top]
        ]
        lines.append(format_table(("function", "file", "callers", "offsets"), top_rows))
        if wanted:
            lines.append("\nOffset coverage")
            cover_rows = []
            for r in sorted(rows, key=lambda r: (-len(r["matched"]), -r["callers"],
                                                 r["function"]))[:args.top]:
                if not r["matched"]:
                    continue
                cover_rows.append((r["function"], r["file"], r["callers"],
                                   ",".join(r["matched"]), ",".join(r["unknown"]) or "-"))
            lines.append(format_table(("function", "file", "callers", "matched", "missing"),
                                      cover_rows))
        lines.append("\nOffset use counts")
        lines.append(format_table(("offset", "functions"),
                                  sorted(offset_counts.items())))

    report = "\n".join(lines) + "\n"
    if args.output:
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(report, encoding="utf-8")
    else:
        sys.stdout.write(report)


if __name__ == "__main__":
    main()

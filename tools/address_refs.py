#!/usr/bin/env python3
"""Report ROM/RAM address constants in known pointer tables.

Read-only helper for the gap-data symbolization work.  It parses the assembler
listing for labels/equates, then walks a small schema of known pointer tables
directly from the reference ROM and reports which targets already have a symbol.

Usage:
    python3 tools/address_refs.py
    python3 tools/address_refs.py --check        # exit 1 on unresolved pointers
    python3 tools/address_refs.py --json         # machine-readable report
"""
import argparse
import json
import re
import sys

ROM_PATH = "baserom.md"
LISTING_PATH = "build/roadrash.lst"

ROM_SIZE = 0xC0000
RAM_LO = 0xFF0000
RAM_HI = 0xFFFFFF
SENTINEL = 0xFFFFFFFF

# Data blobs whose entries are legitimately expressed as ``base+offset``.
BASE_RANGES = [
    (0x3C7EC, 0x7DCA8, "Road_ShapeData"),
]


def load_symbols(path):
    symbols = {}
    label_re = re.compile(r"/\s*([0-9A-F]{5,6})\s*:\s+([A-Za-z_][A-Za-z0-9_]*):")
    equ_re = re.compile(r"=\$([0-9A-Fa-f]+)\s+([A-Za-z_][A-Za-z0-9_]*)\s+equ")
    try:
        lines = open(path, encoding="latin1")
    except OSError as exc:
        sys.exit(f"error: cannot read {path}: {exc}")
    with lines:
        for line in lines:
            m = label_re.search(line)
            if m:
                symbols.setdefault(int(m.group(1), 16), m.group(2))
            m = equ_re.search(line)
            if m:
                symbols.setdefault(int(m.group(1), 16), m.group(2))
    return symbols


def load_rom(path):
    try:
        return open(path, "rb").read()
    except OSError as exc:
        sys.exit(f"error: cannot read {path}: {exc}")


def u16(rom, off):
    return (rom[off] << 8) | rom[off + 1]


def u32(rom, off):
    return int.from_bytes(rom[off:off + 4], "big")


def classify(value):
    if value == 0:
        return "zero"
    if value == SENTINEL:
        return "sentinel"
    if RAM_LO <= value <= RAM_HI:
        return "ram"
    if 0 <= value < ROM_SIZE:
        return "rom"
    return "numeric"


# Schema: (name, start, entries, reader) where reader(rom, off) -> value.
# dword tables are the common case; special readers cover word-pair pointers.
def schema():
    tables = []

    def dwords(name, start, count):
        tables.append((name, start, count,
                       lambda rom, off: u32(rom, off), 4, "rom"))

    # Race/intro/results tables (all 8-byte quote/image pairs).
    tables.append(("RiderIntro_RecordTable", 0x19A12, 100,
                   lambda rom, off: u32(rom, off), 4, "rom"))
    tables.append(("RiderIntro_RecordTable+4", 0x19A16, 100,
                   lambda rom, off: u32(rom, off), 4, "rom"))
    dwords("RaceResults_LevelTablePos", 0x19D32, 40)
    dwords("RaceResults_LevelTableNeg", 0x19DD2, 20)
    dwords("RaceResults_CopTablePos", 0x19E22, 40)
    dwords("RaceResults_CopTableNeg", 0x19EC2, 20)
    dwords("EndLevel_LevelRiderTable", 0x19F12, 20)

    # Track records.
    dwords("unk_25EC0 (track pointers)", 0x25EC0, 5)
    for i, rec in enumerate((0x25ED4, 0x2A770, 0x2E6F0, 0x325DC, 0x36732)):
        dwords(f"Track_Record{i}", rec, 6)

    # Actor tables.
    dwords("Race_ActorList+Mid (RAM)", 0x25856, 17)
    dwords("Race_StaticActorList (RAM)", 0x2589A, 3)
    dwords("Race_ActorGraphicsTable", 0x258EE, 10)

    dwords("ActorActionTable", 0x12D16, 99)
    dwords("unk_259C0 (ptr-to-ptr)", 0x259C0, 20)
    dwords("unk_25A10 (actor data ptrs)", 0x25A10, 13)
    dwords("unk_25B50 (bike data ptrs)", 0x25B50, 8)
    tables.append(("unk_25A44 (ptr,word,word)", 0x25A44, 16,
                   lambda rom, off: u32(rom, off), 8, "rom"))

    # Road shapes.
    dwords("Road_ShapeTable", 0x3BF1A, 564)

    # Misc tables embedded in binclude.
    dwords("unk_7E670 (track images)", 0x7E670, 5)
    tables.append(("unk_7DEAA (needle tilemap)", 0x7DEAA, 1,
                   lambda rom, off: u32(rom, off), 4, "rom"))
    dwords("unk_7DEAA frames", 0x7DEB0, 32)

    return tables


def analyze(symbols, rom):
    report = []
    for name, start, count, reader, stride, kind in schema():
        items = []
        for i in range(count):
            addr = start + i * stride
            value = reader(rom, addr)
            cls = classify(value)
            symbol = symbols.get(value) if cls in ("rom", "ram") else None
            base_relative = False
            if symbol is None and cls == "rom":
                for lo, hi, base in BASE_RANGES:
                    if lo <= value < hi and symbols.get(lo) == base:
                        symbol = f"{base}+${value - lo:X}"
                        base_relative = True
                        break
            items.append({
                "index": i,
                "table_addr": f"${addr:06X}",
                "value": f"${value:08X}",
                "class": cls,
                "symbol": symbol,
                "base_relative": base_relative,
            })
        unresolved = [it for it in items if it["class"] in ("rom", "ram") and not it["symbol"]]
        unique = sorted({it["value"] for it in unresolved})
        report.append({
            "name": name,
            "table_addr": f"${start:06X}",
            "count": count,
            "kind": kind,
            "unresolved": len(unresolved),
            "unique_unresolved": unique,
            "items": items,
        })
    return report


def print_report(report):
    total_unresolved = 0
    for table in report:
        total_unresolved += table["unresolved"]
        base_rel = sum(1 for it in table["items"] if it.get("base_relative"))
        extra = f" base-relative={base_rel:>3}" if base_rel else ""
        line = (f"{table['name']:<34} {table['table_addr']} "
                f"entries={table['count']:>3} unresolved={table['unresolved']:>3}{extra}")
        print(line)
        if table["unique_unresolved"]:
            preview = ", ".join(table["unique_unresolved"][:8])
            if len(table["unique_unresolved"]) > 8:
                preview += ", ..."
            print(f"    targets: {preview}")
    print(f"\nTotal unresolved address entries: {total_unresolved}")
    return total_unresolved


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--listing", default=LISTING_PATH)
    parser.add_argument("--rom", default=ROM_PATH)
    parser.add_argument("--json", action="store_true", help="print JSON instead of text")
    parser.add_argument("--check", action="store_true",
                        help="exit non-zero if unresolved address entries remain")
    args = parser.parse_args()

    symbols = load_symbols(args.listing)
    rom = load_rom(args.rom)
    report = analyze(symbols, rom)

    if args.json:
        print(json.dumps(report, indent=2))
        unresolved = sum(t["unresolved"] for t in report)
    else:
        unresolved = print_report(report)

    if args.check and unresolved:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

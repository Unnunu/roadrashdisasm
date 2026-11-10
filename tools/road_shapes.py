#!/usr/bin/env python3
"""Split Road_ShapeTable entries into per-ID raw shape files.

Usage:
    python3 tools/road_shapes.py split
    python3 tools/road_shapes.py render --ids 56,57,1C3,1C4,15E
    python3 tools/road_shapes.py split --out assets/shapes

The ROM table is at 0x3BF1A (564 entries); shape data is 0x3C7EC..0x7DCA7.
Each ID receives the byte range from its pointer to the next unique pointer,
so repeated pointers produce identical slices for aliased IDs.  The generated
tree is local-only (assets/ is git-ignored).
"""
import argparse
import csv
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROM = ROOT / "baserom.md"
TABLE = 0x3BF1A
COUNT = 0x234
DATA_START = 0x3C7EC
DATA_END = 0x7DCA8


def u32(b, off):
    return int.from_bytes(b[off:off + 4], "big")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=("split", "render"), nargs="?", default="split")
    ap.add_argument("--rom", default=str(ROM))
    ap.add_argument("--out", default=str(ROOT / "assets" / "shapes"))
    ap.add_argument("--ids", default="56,57,1C3,1C4,15E")
    args = ap.parse_args()

    rom = Path(args.rom).read_bytes()
    ptrs = [u32(rom, TABLE + i * 4) for i in range(COUNT)]
    unique = sorted(set(p for p in ptrs if p))
    if any(p < DATA_START or p >= DATA_END for p in unique):
        raise SystemExit("shape pointer outside Road_ShapeData")
    sizes = {}
    for i, p in enumerate(unique):
        end = unique[i + 1] if i + 1 < len(unique) else DATA_END
        sizes[p] = end - p

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    if args.command == "render":
        render(rom, out, args.ids, ptrs, sizes)
        return
    aliases = {}
    for sid, p in enumerate(ptrs):
        if p:
            aliases.setdefault(p, []).append(sid)

    rows = []
    for sid, p in enumerate(ptrs):
        if not p:
            rows.append((sid, 0, 0, "", "", "empty"))
            continue
        data = rom[p:p + sizes[p]]
        d = out / f"{sid:03X}"
        d.mkdir(parents=True, exist_ok=True)
        (d / "data.bin").write_bytes(data)
        alias_ids = [x for x in aliases[p] if x != sid]
        meta = {
            "id": f"0x{sid:03X}",
            "pointer": f"0x{p:06X}",
            "size": len(data),
            "header": data[:16].hex(" "),
            "aliases": [f"0x{x:03X}" for x in alias_ids],
            "source": "src/data/road_shapes.asm",
        }
        (d / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
        rows.append((sid, p, len(data), data[:4].hex(" "),
                     ",".join(meta["aliases"]), "data"))

    with open(out / "index.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(("id", "pointer", "size", "header", "aliases", "kind"))
        for sid, p, size, header, alias, kind in rows:
            w.writerow((f"0x{sid:03X}", f"0x{p:06X}", size, header, alias, kind))

    print(f"split {COUNT} shape IDs -> {out}")
    print(f"unique pointers: {len(unique)}; nonzero IDs: {sum(1 for p in ptrs if p)}")
    print(f"index: {out / 'index.csv'}")


def render(rom, out, ids, ptrs, sizes):
    try:
        from PIL import Image
    except ImportError:
        raise SystemExit("Pillow required for render")
    pal_path = ROOT / "assets" / "palettes" / "race_track0" / "palette.json"
    pal = [tuple(c["rgb"]) for c in json.loads(pal_path.read_text())]
    for token in ids.split(","):
        token = token.strip()
        if not token:
            continue
        sid = int(token, 16)
        p = ptrs[sid]
        if not p:
            continue
        data = rom[p:p + sizes[p]]
        d = out / f"{sid:03X}"
        d.mkdir(parents=True, exist_ok=True)
        for off, name in ((4, "p4"), (6, "p6")):
            payload = data[off:]
            if len(payload) < 32:
                continue
            n = len(payload) // 32
            cols = 16
            rows = (n + cols - 1) // cols
            img = Image.new("RGB", (cols * 8, rows * 8), (0, 0, 0))
            for ti in range(n):
                t = payload[ti * 32:(ti + 1) * 32]
                bx = (ti % cols) * 8
                by = (ti // cols) * 8
                for y in range(8):
                    b0, b1, b2, b3 = t[y * 4:y * 4 + 4]
                    for x in range(8):
                        bit = 7 - x
                        v = ((b0 >> bit) & 1) | (((b1 >> bit) & 1) << 1) | \
                            (((b2 >> bit) & 1) << 2) | (((b3 >> bit) & 1) << 3)
                        img.putpixel((bx + x, by + y), pal[v % len(pal)])
            img.save(d / f"preview_{name}.png")
        print(f"rendered {sid:03X}")

if __name__ == "__main__":
    main()

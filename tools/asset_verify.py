#!/usr/bin/env python3
"""Verify extracted asset bytes against ROM, layout metadata and runtime dumps.

Usage:
    python3 tools/asset_verify.py --asset race_track_background_0
    python3 tools/asset_verify.py --asset race_track_background_0 --golden analysis/golden

Checks:
  1. raw slice in `assets/` matches the ROM range;
  2. decompression succeeds;
  3. parsed layout matches the Data6 header offsets;
  4. optional runtime decompressed dump matches byte-for-byte.

Golden dumps are local-only (`analysis/golden/` is git-ignored).
"""
import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROM = ROOT / "baserom.md"
SPEC = ROOT / "tools" / "asset_specs.json"
ASSETS = ROOT / "assets"


def load_assets_module():
    spec = importlib.util.spec_from_file_location("assets_tool", ROOT / "tools" / "assets.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def load_spec():
    return json.loads(SPEC.read_text())


def verify(asset_id, golden_dir):
    a = load_assets_module()
    spec = load_spec()
    by_id = {x["id"]: x for x in spec["assets"]}
    if asset_id not in by_id:
        raise SystemExit(f"unknown asset: {asset_id}")
    asset = by_id[asset_id]
    rom = ROM.read_bytes()
    addr = int(asset["address"], 16)
    size = int(asset["size"], 16)
    raw = rom[addr:addr + size]
    data_path = ASSETS / asset["category"] / asset_id / "data.bin"

    failures = []
    print(f"asset: {asset_id} @ 0x{addr:06X} size 0x{size:X}")
    if data_path.exists():
        disk = data_path.read_bytes()
        if disk != raw:
            failures.append("raw slice differs from ROM")
        else:
            print("  raw slice: PASS")
    else:
        print("  raw slice: SKIP (not split)")

    out = a.decompress(raw, asset.get("compression") == "w")
    if out is None:
        failures.append("decompression failed")
        print("  decompress: FAIL")
        return failures, None
    print(f"  decompress: PASS ({len(out)} bytes, sha256 {sha256(out)})")

    layout = a.parse_layout(out, asset["category"])
    if layout is None:
        failures.append("layout not detected")
        print("  layout: FAIL")
        return failures, out
    print(f"  layout: {layout}")

    if asset_id.startswith("race_track_background_"):
        map_off = int.from_bytes(rom[addr - 4:addr - 2], "big")
        pal_off = int.from_bytes(rom[addr - 2:addr], "big")
        tile_off = int.from_bytes(rom[addr - 6:addr - 4], "big")
        expected = {"kind": "image_embedded", "tiles": 253, "tiles_offset": 4,
                    "palette_offset": pal_off, "palette_size": 128, "map_offset": map_off,
                    "width": 128, "height": 14}
        print(f"  Data6 header: tile=0x{tile_off:X} map=0x{map_off:X} palette=0x{pal_off:X}")
        if layout != expected:
            failures.append(f"layout mismatch: {layout} != {expected}")
        else:
            print("  Data6 header/layout: PASS")

    gold = Path(golden_dir) / f"{asset_id}_decompressed.bin"
    if gold.exists():
        gold_data = gold.read_bytes()
        if gold_data != out:
            failures.append("runtime decompressed dump differs")
            print(f"  runtime dump: FAIL ({gold})")
        else:
            print(f"  runtime dump: PASS ({gold}, sha256 {sha256(gold_data)})")
    else:
        print(f"  runtime dump: SKIP ({gold} missing)")

    return failures, out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--asset", action="append", default=[])
    ap.add_argument("--golden", default=str(ROOT / "analysis" / "golden"))
    args = ap.parse_args()
    ids = args.asset or ["race_track_background_0"]
    failed = False
    for aid in ids:
        failures, _ = verify(aid, args.golden)
        if failures:
            failed = True
            for f in failures:
                print(f"  FAIL: {f}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

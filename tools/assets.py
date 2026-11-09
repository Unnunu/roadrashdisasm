#!/usr/bin/env python3
"""Split, render and verify Road Rash ROM assets.

The asset payloads are generated from baserom.md and are intentionally not
committed (see .gitignore).  The build uses the generated .bin files via
binclude, never baserom.md directly.

Usage:
    python3 tools/assets.py split [--quiet]
    python3 tools/assets.py render
    python3 tools/assets.py check
    python3 tools/assets.py all
"""
import argparse
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPEC_PATH = ROOT / "tools" / "asset_specs.json"
ROM_PATH = ROOT / "baserom.md"
ASSETS_ROOT = ROOT / "assets"
SENTINEL = 0xFFFFFFFF


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
def load_spec():
    with open(SPEC_PATH, encoding="utf-8") as f:
        return json.load(f)


def load_rom():
    try:
        return ROM_PATH.read_bytes()
    except OSError as exc:
        sys.exit(f"error: cannot read {ROM_PATH}: {exc}")


def u16(b, off):
    return int.from_bytes(b[off:off + 2], "big")


def u32(b, off):
    return int.from_bytes(b[off:off + 4], "big")


def asset_dir(asset):
    return ASSETS_ROOT / asset["category"] / asset["id"]


def data_path(asset):
    return asset_dir(asset) / "data.bin"


def palette_dir(palette):
    return ASSETS_ROOT / "palettes" / palette["id"]


def palette_data_path(palette):
    return palette_dir(palette) / "data.bin"


def md_color(word):
    """Mega Drive CRAM word -> 8-bit RGB tuple."""
    hi = (word >> 8) & 0xFF
    lo = word & 0xFF
    blue = (hi >> 1) & 7
    green = (lo >> 5) & 7
    red = (lo >> 1) & 7
    return (red * 255 // 7, green * 255 // 7, blue * 255 // 7)


def palette_bytes_to_rgb(data, colors=64):
    out = []
    for i in range(colors):
        if i * 2 + 2 > len(data):
            out.append((0, 0, 0))
        else:
            out.append(md_color(u16(data, i * 2)))
    return out


def write_json(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2)
        f.write("\n")


# ---------------------------------------------------------------------------
# LZSS (same B/W formats as uncompress.asm / tools/extract.py)
# ---------------------------------------------------------------------------
def decompress(raw, word):
    if word:
        if len(raw) < 8:
            return None
        size = (raw[1] << 24) | (raw[3] << 16) | (raw[5] << 8) | raw[7]
        off = 8
    else:
        if len(raw) < 4:
            return None
        size = u32(raw, 0)
        off = 4
    if not (0 < size <= 0x80000):
        return None
    out = bytearray()
    ring = bytearray([0x20]) * 0x1000
    ti = 0xFEE
    try:
        while len(out) < size:
            if word:
                off += 1
            if off >= len(raw):
                return None
            mask = raw[off]
            off += 1
            for bit in f"{mask:08b}"[::-1]:
                if bit == "1":
                    if word:
                        off += 1
                    if off >= len(raw):
                        return None
                    val = raw[off]
                    off += 1
                    out.append(val)
                    ring[ti] = val
                    ti = (ti + 1) & 0xFFF
                else:
                    if word:
                        off += 1
                    if off >= len(raw):
                        return None
                    b1 = raw[off]
                    off += 1
                    if word:
                        off += 1
                    if off >= len(raw):
                        return None
                    b2 = raw[off]
                    off += 1
                    num = (b2 & 0xF) + 3
                    idx = b1 + ((b2 & 0xF0) << 4)
                    for _ in range(num):
                        val = ring[idx & 0xFFF]
                        idx += 1
                        out.append(val)
                        ring[ti] = val
                        ti = (ti + 1) & 0xFFF
                        if len(out) >= size:
                            break
                if len(out) >= size:
                    break
    except (IndexError, ValueError):
        return None
    return bytes(out)


# ---------------------------------------------------------------------------
# layout detection
# ---------------------------------------------------------------------------
def _valid_wh(w, h):
    return 0 < w <= 512 and 0 < h <= 512


def parse_layout(out, category):
    """Return a layout dict or None.

    kinds: image_embedded, image_external, map, tileset, raw_tiles, raw
    """
    if out is None:
        return None
    if len(out) >= 4 and (u32(out, 0) >> 16) == 0x0808:
        tiles = u16(out, 2)
        tiles_end = 4 + tiles * 32
        if tiles_end > len(out):
            return None
        rem = len(out) - tiles_end
        # embedded palette + nametable
        if rem >= 132:
            pal_off = tiles_end
            w = u16(out, pal_off + 128)
            h = u16(out, pal_off + 130)
            if _valid_wh(w, h) and rem == 128 + 4 + 2 * w * h:
                return {"kind": "image_embedded", "tiles": tiles,
                        "tiles_offset": 4, "palette_offset": pal_off,
                        "palette_size": 128, "map_offset": pal_off + 128,
                        "width": w, "height": h}
        # nametable only (external palette)
        if rem >= 4:
            w = u16(out, tiles_end)
            h = u16(out, tiles_end + 2)
            if _valid_wh(w, h) and rem == 4 + 2 * w * h:
                return {"kind": "image_external", "tiles": tiles,
                        "tiles_offset": 4, "map_offset": tiles_end,
                        "width": w, "height": h}
        if rem == 128:
            return {"kind": "tileset", "tiles": tiles, "tiles_offset": 4,
                    "palette_offset": tiles_end, "palette_size": 128}
        if rem == 0:
            return {"kind": "tileset", "tiles": tiles, "tiles_offset": 4}
        return {"kind": "tileset", "tiles": tiles, "tiles_offset": 4,
                "extra": rem}
    # map-only: first long is (width,height)
    if len(out) >= 4:
        w = u16(out, 0)
        h = u16(out, 2)
        if _valid_wh(w, h) and len(out) == 4 + 2 * w * h:
            return {"kind": "map", "map_offset": 0, "width": w, "height": h}
    if len(out) % 32 == 0 and len(out) > 0:
        return {"kind": "raw_tiles", "tiles": len(out) // 32,
                "tiles_offset": 0}
    return {"kind": "raw"}


# ---------------------------------------------------------------------------
# split / check
# ---------------------------------------------------------------------------
def split(args):
    rom = load_rom()
    spec = load_spec()
    quiet = args.quiet
    written = 0
    for asset in spec["assets"]:
        addr = int(asset["address"], 16)
        size = int(asset["size"], 16)
        payload = rom[addr:addr + size]
        if len(payload) != size:
            sys.exit(f"error: {asset['id']}: ROM slice out of range")
        p = data_path(asset)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(payload)
        meta = dict(asset)
        meta["data_file"] = str(p.relative_to(ROOT))
        write_json(asset_dir(asset) / "meta.json", meta)
        written += 1
    for pal in spec["palettes"]:
        addr = int(pal["address"], 16)
        size = int(pal["size"], 16)
        payload = rom[addr:addr + size]
        if len(payload) != size:
            sys.exit(f"error: {pal['id']}: ROM slice out of range")
        p = palette_data_path(pal)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(payload)
        meta = dict(pal)
        meta["data_file"] = str(p.relative_to(ROOT))
        write_json(palette_dir(pal) / "meta.json", meta)
        written += 1
    write_json(ASSETS_ROOT / "manifest.json", spec)
    if not quiet:
        print(f"assets split: {written} files under {ASSETS_ROOT.relative_to(ROOT)}")


def check(args):
    rom = load_rom()
    spec = load_spec()
    bad = 0
    checked = 0
    for asset in spec["assets"]:
        addr = int(asset["address"], 16)
        size = int(asset["size"], 16)
        p = data_path(asset)
        if not p.exists():
            print(f"MISSING {p}")
            bad += 1
            continue
        if p.read_bytes() != rom[addr:addr + size]:
            print(f"MISMATCH {p}")
            bad += 1
            continue
        checked += 1
    for pal in spec["palettes"]:
        addr = int(pal["address"], 16)
        size = int(pal["size"], 16)
        p = palette_data_path(pal)
        if not p.exists():
            print(f"MISSING {p}")
            bad += 1
            continue
        if p.read_bytes() != rom[addr:addr + size]:
            print(f"MISMATCH {p}")
            bad += 1
            continue
        checked += 1
    if bad:
        print(f"asset check FAILED: {bad} problem(s)")
        return 1
    print(f"asset check OK: {checked} slices match baserom.md")
    return 0


# ---------------------------------------------------------------------------
# rendering
# ---------------------------------------------------------------------------
def load_asset_data(asset):
    p = data_path(asset)
    if not p.exists():
        sys.exit(f"error: {p} missing; run assets.py split first")
    raw = p.read_bytes()
    return decompress(raw, asset["compression"] == "w")


def blob_tiles(blob, offset, count):
    return [blob[offset + i * 32: offset + (i + 1) * 32] for i in range(count)]


def tile_pixel(tile, x, y):
    byte = tile[y * 4 + (x // 2)]
    return (byte >> 4) if x % 2 == 0 else (byte & 0xF)


def palette_color(palette, line, value):
    idx = line * 16 + value
    if 0 <= idx < len(palette):
        return palette[idx]
    return (0, 0, 0)


def save_rgb_indexed(img_rgb, img_idx, palette, base, transparent0):
    from PIL import Image
    if img_idx is not None:
        p = img_idx.convert("P")
        p.putpalette([c for rgb in palette for c in rgb][:768] + [0] * (768 - len(palette) * 3))
        if transparent0:
            p.save(base.with_name(base.name.replace(".png", "_indexed.png")),
                   transparency=0)
        else:
            p.save(base.with_name(base.name.replace(".png", "_indexed.png")))
    if img_rgb is not None:
        img_rgb.save(base)


def render_map(out, layout, palette, path, transparent0, tiles=None):
    from PIL import Image
    if tiles is None:
        tiles = blob_tiles(out, layout["tiles_offset"], layout["tiles"])
    w = layout["width"]
    h = layout["height"]
    map_off = layout["map_offset"] + 4
    rgb = Image.new("RGBA" if transparent0 else "RGB", (w * 8, h * 8))
    idx = Image.new("P", (w * 8, h * 8))
    for cy in range(h):
        for cx in range(w):
            entry = u16(out, map_off + 2 * (cy * w + cx))
            tile = entry & 0x7FF
            line = (entry >> 13) & 3
            vflip = bool(entry & 0x1000)
            hflip = bool(entry & 0x800)
            if tile >= len(tiles):
                continue
            t = tiles[tile]
            for y in range(8):
                for x in range(8):
                    sx = 7 - x if hflip else x
                    sy = 7 - y if vflip else y
                    val = tile_pixel(t, sx, sy)
                    col = palette_color(palette, line, val)
                    px = cx * 8 + x
                    py = cy * 8 + y
                    if transparent0 and val == 0:
                        rgb.putpixel((px, py), (0, 0, 0, 0))
                    else:
                        rgb.putpixel((px, py), col if not transparent0 else (*col, 255))
                    idx.putpixel((px, py), (line * 16 + val) & 0xFF)
    save_rgb_indexed(rgb, idx, palette, path, transparent0)


def render_atlas(out, layout, palette, path, line, transparent0):
    from PIL import Image
    offset = layout.get("tiles_offset", 0)
    count = layout.get("tiles", len(out) // 32)
    tiles = blob_tiles(out, offset, count)
    cols = 16
    rows = (count + cols - 1) // cols
    rgb = Image.new("RGBA" if transparent0 else "RGB", (cols * 8, rows * 8))
    idx = Image.new("P", (cols * 8, rows * 8))
    for n, t in enumerate(tiles):
        cx = (n % cols) * 8
        cy = (n // cols) * 8
        for y in range(8):
            for x in range(8):
                val = tile_pixel(t, x, y)
                col = palette_color(palette, line, val)
                if transparent0 and val == 0:
                    rgb.putpixel((cx + x, cy + y), (0, 0, 0, 0))
                else:
                    rgb.putpixel((cx + x, cy + y), col if not transparent0 else (*col, 255))
                idx.putpixel((cx + x, cy + y), (line * 16 + val) & 0xFF)
    save_rgb_indexed(rgb, idx, palette, path, transparent0)


def write_palette_png(path, palette, cols=16):
    from PIL import Image
    rows = (len(palette) + cols - 1) // cols
    img = Image.new("RGB", (cols * 8, rows * 8))
    for i, col in enumerate(palette):
        x = (i % cols) * 8
        y = (i // cols) * 8
        for yy in range(8):
            for xx in range(8):
                img.putpixel((x + xx, y + yy), col)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def screen_palette(spec, group, cache):
    if group in cache:
        return cache[group]
    entry = spec["screen_palettes"][group]
    by_id = {a["id"]: a for a in spec["assets"]}
    src = by_id[entry["asset"]]
    out = load_asset_data(src)
    layout = parse_layout(out, src["category"])
    if layout is None:
        raise RuntimeError(f"cannot find screen palette {group}")
    off = int(entry["offset"], 16)
    data = out[off:off + entry["colors"] * 2]
    pal = palette_bytes_to_rgb(data, entry["colors"])
    cache[group] = pal
    return pal


def race_palette(spec, rom, track_index, cache):
    key = ("race", track_index)
    if key in cache:
        return cache[key]
    by_id = {a["id"]: a for a in spec["assets"]}
    hud = by_id["race_hud"]
    out = load_asset_data(hud)
    layout = parse_layout(out, hud["category"])
    if layout is None or layout.get("palette_offset") is None:
        raise RuntimeError("race HUD palette not found")
    pal = palette_bytes_to_rgb(
        out[layout["palette_offset"]:layout["palette_offset"] + 128], 64)
    if track_index is not None:
        entry = spec["race_palettes"][track_index]
        addr = int(entry["data6"], 16)
        dec = decompress(rom[addr:], False)
        if dec is None:
            raise RuntimeError(f"cannot decompress {entry['name']}")
        po = u16(rom, addr - 2)
        src = dec[po + 0x22:po + 0x22 + 0x22]
        pal = list(pal)
        pal[0x22:0x22 + len(src)] = palette_bytes_to_rgb(src, len(src) // 2)
        # preserve the first line-1 entry from the HUD palette, matching the
        # game's copy at Global_ram_Palette+$22.
        hud_line1 = pal[0x20]
        pal[0x20] = hud_line1
    cache[key] = pal
    return pal


def palette_asset(spec, pid):
    for pal in spec["palettes"]:
        if pal["id"] == pid:
            return pal
    raise KeyError(pid)


def render(args):
    try:
        from PIL import Image  # noqa: F401
    except ImportError:
        sys.exit("error: Pillow is required for rendering (pip install pillow)")
    spec = load_spec()
    by_id = {a["id"]: a for a in spec["assets"]}
    cache = {}

    # standalone palettes
    for pal in spec["palettes"]:
        p = palette_data_path(pal)
        if not p.exists():
            sys.exit(f"error: {p} missing; run assets.py split first")
        raw = p.read_bytes()
        colors = pal["colors"]
        entries = []
        for i in range(pal["count"]):
            data = raw[i * colors * 2:(i + 1) * colors * 2]
            rgb = palette_bytes_to_rgb(data, colors)
            entries.append(rgb)
            d = palette_dir(pal) / f"palette_{i}.png"
            write_palette_png(d, rgb)
            write_json(palette_dir(pal) / f"palette_{i}.json",
                       [{"index": j, "rgb": list(c)} for j, c in enumerate(rgb)])
        write_json(palette_dir(pal) / "palette.json", entries)

    # screen palettes (derived from source images)
    for group in spec["screen_palettes"]:
        pal = screen_palette(spec, group, cache)
        d = ASSETS_ROOT / "palettes" / group
        write_json(d / "palette.json",
                   [{"index": i, "rgb": list(c)} for i, c in enumerate(pal)])
        write_palette_png(d / "palette.png", pal)

    rom = load_rom()
    # race palettes: HUD base + per-track line-1 override from RaceTrack_Data6
    for i, entry in enumerate(spec.get("race_palettes", [])):
        pal = race_palette(spec, rom, i, cache)
        d = ASSETS_ROOT / "palettes" / f"race_{entry['name']}"
        write_json(d / "palette.json",
                   [{"index": j, "rgb": list(c)} for j, c in enumerate(pal)])
        write_palette_png(d / "palette.png", pal)
    pal = race_palette(spec, rom, None, cache)
    d = ASSETS_ROOT / "palettes" / "race_hud"
    write_json(d / "palette.json",
               [{"index": j, "rgb": list(c)} for j, c in enumerate(pal)])
    write_palette_png(d / "palette.png", pal)

    rendered = 0
    for asset in spec["assets"]:
        if not asset.get("preview"):
            continue
        out = load_asset_data(asset)
        layout = parse_layout(out, asset["category"])
        if layout is None:
            print(f"skip {asset['id']}: cannot detect layout")
            continue
        if layout["kind"] in ("raw",):
            print(f"skip {asset['id']}: raw data")
            continue
        d = asset_dir(asset)
        meta = dict(asset)
        meta["layout"] = layout

        if layout["kind"] == "image_embedded":
            pal = palette_bytes_to_rgb(out[layout["palette_offset"]:
                                          layout["palette_offset"] + 128], 64)
            write_json(d / "palette.json",
                       [{"index": i, "rgb": list(c)} for i, c in enumerate(pal)])
            write_palette_png(d / "palette.png", pal)
            render_map(out, layout, pal, d / "preview.png", asset["transparent0"])
            meta["palette"] = {"kind": "embedded",
                               "offset": f"0x{layout['palette_offset']:X}",
                               "colors": 64}
            rendered += 1

        elif layout["kind"] == "image_external" and asset.get("palette_group") == "race":
            tracks = asset.get("race_tracks") or []
            entries = list(range(tracks)) if tracks else [None]
            meta_palettes = []
            for ti in entries:
                pal = race_palette(spec, rom, ti, cache)
                suffix = f"_track{ti}" if ti is not None else ""
                pstem = f"palette_track{ti}" if ti is not None else "palette"
                write_json(d / f"{pstem}.json",
                           [{"index": j, "rgb": list(c)} for j, c in enumerate(pal)])
                write_palette_png(d / f"{pstem}.png", pal)
                render_map(out, layout, pal, d / f"preview{suffix}.png",
                           asset["transparent0"])
                meta_palettes.append({"kind": "race",
                                      "track": ti,
                                      "colors": len(pal)})
            meta["palette"] = meta_palettes[0] if len(meta_palettes) == 1 else meta_palettes
            rendered += 1

        elif layout["kind"] == "tileset" and asset.get("palette_group") == "race":
            tracks = asset.get("race_tracks") or []
            entries = list(range(tracks)) if tracks else [None]
            meta_palettes = []
            lines = asset.get("atlas_lines") or [0]
            for ti in entries:
                pal = race_palette(spec, rom, ti, cache)
                suffix = f"_track{ti}" if ti is not None else ""
                pstem = f"palette_track{ti}" if ti is not None else "palette"
                write_json(d / f"{pstem}.json",
                           [{"index": j, "rgb": list(c)} for j, c in enumerate(pal)])
                write_palette_png(d / f"{pstem}.png", pal)
                for line in lines:
                    render_atlas(out, layout, pal,
                                 d / f"atlas{suffix}_line{line}.png", line,
                                 asset["transparent0"])
                meta_palettes.append({"kind": "race", "track": ti,
                                      "colors": len(pal)})
            meta["palette"] = meta_palettes[0] if len(meta_palettes) == 1 else meta_palettes
            rendered += 1

        elif layout["kind"] == "image_external":
            groups = asset.get("palette_groups") or (
                [asset["palette_group"]] if asset.get("palette_group") else [])
            groups = [g for g in groups if g in spec["screen_palettes"]]
            if not groups:
                print(f"skip {asset['id']}: external palette unknown")
                continue
            multi = len(groups) > 1
            meta_palettes = []
            for group in groups:
                base = screen_palette(spec, group, cache)
                stem = f"preview_{group}" if multi else "preview"
                pstem = f"palette_{group}" if multi else "palette"
                write_json(d / f"{pstem}.json",
                           [{"index": i, "rgb": list(c)} for i, c in enumerate(base)])
                write_palette_png(d / f"{pstem}.png", base)
                render_map(out, layout, base, d / f"{stem}.png", asset["transparent0"])
                meta_palettes.append({"kind": "external", "group": group,
                                      "colors": len(base)})
                # palette variants (shop bikes; single base group)
                variants = asset.get("variants")
                if variants and variants.get("kind") == "bike":
                    pal_asset = palette_asset(spec, variants["palette_asset"])
                    praw = palette_data_path(pal_asset).read_bytes()
                    for i in range(variants["count"]):
                        pal = list(base)
                        bike = palette_bytes_to_rgb(
                            praw[i * pal_asset["colors"] * 2:
                                 (i + 1) * pal_asset["colors"] * 2],
                            pal_asset["colors"])
                        for line in variants["target_lines"]:
                            for j, col in enumerate(bike):
                                if line * 16 + j < len(pal):
                                    pal[line * 16 + j] = col
                        vstem = f"palette_{group}_bike{i}" if multi else f"palette_bike{i}"
                        write_json(d / f"{vstem}.json",
                                   [{"index": j, "rgb": list(c)}
                                    for j, c in enumerate(pal)])
                        write_palette_png(d / f"{vstem}.png", pal)
                        preview = f"preview_{group}_bike{i}" if multi else f"preview_bike{i}"
                        render_map(out, layout, pal, d / f"{preview}.png",
                                   asset["transparent0"])
                    meta["variants_rendered"] = variants["count"]
            meta["palette"] = meta_palettes[0] if len(meta_palettes) == 1 else meta_palettes
            rendered += 1

        elif layout["kind"] == "tileset":
            group = asset.get("palette_group")
            if group and group in spec["screen_palettes"]:
                pal = screen_palette(spec, group, cache)
            elif layout.get("palette_offset") is not None:
                pal = palette_bytes_to_rgb(
                    out[layout["palette_offset"]:
                        layout["palette_offset"] + 128], 64)
            else:
                pal = [(i * 4, i * 4, i * 4) for i in range(64)]
            write_json(d / "palette.json",
                       [{"index": i, "rgb": list(c)} for i, c in enumerate(pal)])
            write_palette_png(d / "palette.png", pal)
            lines = asset.get("atlas_lines") or [0]
            for line in lines:
                render_atlas(out, layout, pal, d / f"atlas_line{line}.png",
                             line, asset["transparent0"])
            meta["palette"] = {"kind": "external" if group else "generated",
                               "group": group, "colors": len(pal)}
            rendered += 1

        elif layout["kind"] == "raw_tiles":
            group = asset.get("palette_group")
            if group and group in spec["screen_palettes"]:
                pal = screen_palette(spec, group, cache)
            else:
                pal = [(i * 4, i * 4, i * 4) for i in range(64)]
            for line in (asset.get("atlas_lines") or [0]):
                render_atlas(out, layout, pal, d / f"atlas_line{line}.png",
                             line, asset["transparent0"])
            rendered += 1

        elif layout["kind"] == "map":
            ts_id = asset.get("tileset_asset")
            if not ts_id:
                meta["palette"] = {"kind": "deferred"}
                print(f"skip {asset['id']}: map preview deferred (needs tileset)")
                write_json(d / "meta.json", meta)
                continue
            ts = by_id[ts_id]
            ts_out = load_asset_data(ts)
            ts_layout = parse_layout(ts_out, ts["category"])
            if ts_layout is None:
                print(f"skip {asset['id']}: tileset layout unknown")
                write_json(d / "meta.json", meta)
                continue
            tiles = blob_tiles(ts_out, ts_layout.get("tiles_offset", 0),
                               ts_layout.get("tiles", len(ts_out) // 32))
            if asset.get("palette_group") == "race":
                tracks = asset.get("race_tracks") or []
                entries = list(range(tracks)) if tracks else [None]
                meta_palettes = []
                for ti in entries:
                    pal = race_palette(spec, rom, ti, cache)
                    suffix = f"_track{ti}" if ti is not None else ""
                    pstem = f"palette_track{ti}" if ti is not None else "palette"
                    write_json(d / f"{pstem}.json",
                               [{"index": j, "rgb": list(c)}
                                for j, c in enumerate(pal)])
                    write_palette_png(d / f"{pstem}.png", pal)
                    render_map(out, layout, pal, d / f"preview{suffix}.png",
                               asset["transparent0"], tiles=tiles)
                    meta_palettes.append({"kind": "race", "track": ti,
                                          "colors": len(pal)})
                meta["palette"] = meta_palettes[0] if len(meta_palettes) == 1 else meta_palettes
            else:
                meta["palette"] = {"kind": "deferred"}
                print(f"skip {asset['id']}: map palette unknown")
                write_json(d / "meta.json", meta)
                continue
            rendered += 1
        write_json(d / "meta.json", meta)

    print(f"rendered previews: {rendered}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("split", "render", "check", "all"))
    parser.add_argument("--quiet", action="store_true", help="less output for split")
    args = parser.parse_args()
    if args.command in ("split", "all"):
        split(args)
    if args.command in ("render", "all"):
        render(args)
    if args.command in ("check", "all"):
        return check(args)
    return 0


if __name__ == "__main__":
    sys.exit(main())

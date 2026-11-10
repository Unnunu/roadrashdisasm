# Asset verification

Purpose: prove that an extracted preview matches the ROM and the runtime data
before showing it for review. The first reference asset is
`race_track_background_0` (`Track_Data6_0`), because its decompressed layout is
self-describing and its visual identity is confirmed.

## Reference asset

- Asset: `race_track_background_0`
- ROM: `0x028A3E`, size `0x1B56`
- Data6 header: tile `0x0`, nametable `0x2024`, palette `0x1FA4`
- Decompressed: `11816` bytes, `128x14`, `253` tiles
- SHA-256: `e43cadd9f418e74f55b728f2ae69dbd0754dcbd2b7e9dac318987117c23162e1`

## Checks

```sh
python3 tools/asset_verify.py --asset race_track_background_0
```

| Check | Result |
|---|---|
| Raw `assets/images/race_track_background_0/data.bin` equals ROM slice | PASS |
| LZSS-B decompression succeeds | PASS |
| Parsed layout = `image_embedded` with 253 tiles | PASS |
| Parsed map offset equals `Data6-4` (`0x2024`) | PASS |
| Parsed palette offset equals `Data6-2` (`0x1FA4`) | PASS |
| Runtime `Intro_ram_ImageBuffer` dump matches decompressed bytes | PASS |
| SHA-256 of decoder output and runtime dump match | PASS |

Runtime dump is local-only:

```text
analysis/golden/race_track_background_0_decompressed.bin
```

## Consequence

- Data6 split/decompression/layout/preview pipeline is **verified** for this
  reference asset.
- The five track background previews are therefore trusted at the extraction
  level; visual semantics are already confirmed (far/near background strips).
- Shape previews remain **candidate**: they need the same treatment at
  `Road_WriteTileColumns`, including runtime destination tile bytes, offsets,
  palette line and SAT attributes.
- Map/tileset previews (`race_map_0/1`, `race_road`) stay deferred until a
  runtime VDP/tile-base capture is available.

## Shape runtime checkpoint

`Road_WriteTileColumns` was captured at `0x9318`/`0x93D0`. For shape `0x56`:
`Race_ShapeTable[0x56]=0x05994C`, writer source `0x05994E` (P+2), row data
`0x059952` (P+6), left count 4, right count `$35`, destination `$FF511C`.
The split bytes and special handoff are verified; the current candidate
`preview_p4_line3.png`/`preview_p6_line3.png` are **not** trusted until the
writer destination and palette line are modeled.
See `docs/analysis/shape_writer_verify.md`.

## Next verification targets

1. `Road_WriteTileColumns` shape output: source pointer, strip counts, offset
   arrays, destination tile array, palette line.
2. `race_map_0/1`: actual tile base `$3000`, tileset and CRAM.
3. `race_road`: road-tile table layout, not a normal image map.

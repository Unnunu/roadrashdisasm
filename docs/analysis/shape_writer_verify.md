# Shape writer runtime verification

Reference shape: `0x56` (sampled road/object shape). Goal: verify that the split
shape bytes and pointer/handoff are correct before attempting another visual
decoder.

## Runtime capture

GDB breakpoint at `Road_WriteTileColumns` after `a4` is loaded (`0x9318`), then
at its return (`0x93D0`). Full work RAM is dumped to the local git-ignored file
`analysis/golden/shape_writer_ram.bin`.

Observed first writer call:

| Field | Value |
|---|---|
| `Race_ShapeTable[0x56]` | `0x05994C` |
| writer source pointer (`ram_FF1348`) | `0x05994E` (P+2, special handoff) |
| row-data pointer (`ram_FF0D2A`) | `0x059952` (P+6) |
| left strip count (`ram_FF132E`) | 4 |
| right strip count (`ram_FF1330`) | `$35` |
| destination (`a4`) | `$FF511C` = `Race_ram_CurrentSpriteTileArray + $80` |
| source `a0` | `$059952` |
| strides `ram_FFDE66/68/6A` | `$5C/$200/$7C` |

The split files match this: `assets/shapes/056/data.bin` starts at `0x05994C`,
contains the header `10 37 20 36`, and the writer consumes `P+6` as row data.

A before/after capture of `0xFF509C..0xFF8000` confirms the writer actually
modifies the destination region starting at `0xFF511C`; the changed range is
`0xFF511C..0xFF5573` (local dumps `shape_writer_before.bin` /
`shape_writer_after.bin`). This is the authoritative destination data for the
next rendering model.

## What is verified

- shape table ID → pointer → split byte range;
- special/two-part pointer handoff `P+2` → `P+6`;
- runtime source pointer and strip counts;
- destination pointer calculation;
- actual written destination range;
- runtime dump availability for future comparisons.

## What is now verified (L6c)

The writer model was replayed against this golden dump: the left/right offset
lists, the `$DE6A/$DE68/$DE66` strides, the 32-row band wrap and the
`base + 4*r + c*(gap+4)` destination formula reproduce **all 1080 written bytes**
of the captured call with 0 mismatches. Shape `$56` writes `$FF511C..$FF5573`
as 5 columns x 54 rows; the 4 bytes per column/row are the 4bpp bitplanes of one
8-pixel scanline. See `docs/analysis/road_render.md` for the full contract and
E8-A for the live list/stride capture.

The `preview_p4_line3.png` / `preview_p6_line3.png` raw-source decodes are still
superseded by the writer-derived tile/SAT previews below. Only the composed,
cropped SAT image should be treated as final shape art.

## Runtime destination preview

The first verified destination preview is generated from the writer output, not
from the raw shape payload:

- destination `0xFF511C` (`CurrentSpriteTileArray + $80`);
- changed range `0xFF511C..0xFF5573`;
- palette line 1 (the `$2036` fill word selects line 1);
- `assets/shapes/056/preview_runtime.png` (34 tiles, raw destination layout);
- `assets/shapes/056/preview_sat_size_line0.png` — SAT entries 2..5 composed with
  the SAT size bits (H/V 4x4, 4x1, 3x4, 3x1) and runtime destination tile data,
  palette line 0. This is the current best candidate for the full shape image.
  The SAT x/y positions and tile indices come from
  `Race_ram_CurrentSpriteAttributeTable`; the chain starts at saved sprite index 2.

This is a runtime-derived tile/SAT composition, not a source-byte guess. The
final crop/width/height still needs confirmation against the object's SAT chain. `preview_p4_line3.png` /
`preview_p6_line3.png` remain candidate raw-source decodes.

## Next experiment

Optional visual check: compose the writer output with the live SAT chain and crop
`preview_runtime.png` to the true sprite. The layout (5 columns x 54 rows for
shape `$56`) is now known; only the final art/crop remains.

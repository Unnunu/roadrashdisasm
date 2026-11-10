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

## What is not verified

The current `preview_p4_line3.png` / `preview_p6_line3.png` are only candidate
4bpp decodes. They do not yet use the writer destination tile bytes, strip
offsets, destination strides, or SAT palette line, so their width/height and
black padding are not trustworthy.

## Runtime destination preview

The first verified destination preview is generated from the writer output, not
from the raw shape payload:

- destination `0xFF511C` (`CurrentSpriteTileArray + $80`);
- changed range `0xFF511C..0xFF5573`;
- palette line 1 (the `$2036` fill word selects line 1);
- `assets/shapes/056/preview_runtime.png` (34 tiles, 16-column layout).

This still needs the writer's actual row/column layout for a final shape crop,
but its bytes now come from the runtime destination. `preview_p4_line3.png` /
`preview_p6_line3.png` remain candidate raw-source decodes.

## Next experiment

Use `shape_writer_after.bin`, the writer's offset arrays and the actual palette
line to derive the final width/height/row layout, then crop
`preview_runtime.png` to the true shape. Only that output should be treated as
final shape art.

# Module card: `src/data/road_shapes.asm`

- **ROM range:** `0x03BF1A`–`0x07DCA7` (`unk_7DCA8` starts the next data)
- **Status:** analyzed (table/count/data, header/control/fill layout and the
  source-bitplane -> 4bpp sprite-tile mapping confirmed; L6c/E8)
- **Related:** `docs/analysis/road_shapes.md`, `docs/analysis/road_render.md`,
  `docs/analysis/race_track_data.md`, `docs/modules/road_render.md`,
  `docs/ram-map.md`

## Role / purpose

`Road_ShapeTable` maps an object shape index (`+8`/`+$12`) to a shape-data pointer.
`Road_ScaleShape`/`Road_ProjectShape` in `src/race/road_render.asm` and the race AI read the
shape bytes to project the object edge; `Road_DrawStrip`/`Road_WriteTileColumns` turn
the per-row bitplane stream into column-major 4bpp sprite tiles. The bytes are included
from `baserom.md`.

## Coverage matrix

| Data | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Road_ShapeTable` | `0x3BF1A` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `word_3C7EA` (count) | `0x3C7EA` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `Road_ShapeData` | `0x3C7EC` | [x] | [x] | [x] | - | [x] | [x] | analyzed |

Detailed analysis: `docs/analysis/road_shapes.md`.

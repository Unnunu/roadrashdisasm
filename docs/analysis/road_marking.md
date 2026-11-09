# Analysis: `road_marking.asm` (road markings -> sprites)

- **Module:** road marking scan, band sizing, sprite geometry/creation, tile patterns
- **ROM range:** `0x00E732`–`0x00EB33`
- **Status:** analyzed (partial; dynamic/visual TODO)
- **Source:** `road_marking.asm`
- **Related:** `docs/analysis/road_render.md`, `docs/analysis/animation.md`,
  `docs/modules/road_marking.md`, `docs/ram-map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `RoadMarking_dPatterns` | `0xE732` | 11 dword bit patterns (0, `$C0000000`..`$CCCCCCCC`). |
| `RoadMarking_Draw` | `0xE75E` | Loop: find line, size bands, clear tiles, create sprite. |
| `RoadMarking_FindUnprocessedLine` | `0xE7B0` | Highest line index with nonzero width. |
| `RoadMarking_GetMarkingsSizes` | `0xE7DA` | X/width bands for four 8-line cells. |
| `RoadMarking_SetSpriteGeometry` | `0xE934` | Sprite posX + 1/2-tile-high size. |
| `RoadMarking_ClearSpriteTiles` | `0xE9D2` | Clear the sprite's tile slots. |
| `RoadMarking_CreateSprite` | `0xE9F8` | Write SAT entry, fill tiles line by line. |

## Flow

`RoadMarking_Draw` clears 16 words of `RoadMarking_ram_WidthArray`, sets
`RoadMarking_TileOffset = Animation_ram_TileIndex*$20`, then loops:

1. `FindUnprocessedLine` scans `WidthArray` (`$98` cells) from the top for a nonzero
   width; returns `d0 = PosY` and pointers into `XArray`/`WidthArray`.
2. `GetMarkingsSizes` walks four 8-line cells and records min X/width in
   `ram_X1/X2/X3/X4` + `Width1..4`.
3. `SetSpriteGeometry` picks `SpritePosX`, `SpriteHorizontalSize`
   (`ceil(width/8)`, max 4) and `SpriteVerticalSize` (1 or 2).
4. `ClearSpriteTiles` clears `HorizontalSize*VerticalSize*8` longs at
   `CurrentSpriteTileArray+TileOffset`.
5. `CreateSprite` writes the SAT entry (posY, VS/HS + link, priority/palette/tile,
   posX), advances `Animation_ram_SpriteIndex`/`TileIndex`, then fills tiles from the
   X/width arrays using `RoadMarking_dPatterns` (clamped to 32 pixels; X_left rewrite
   when the right part spills into the next sprite).

The loop stops at `PosY < 0` or `Animation_ram_SpriteIndex >= 80` (comment says 128).

## Data / RAM

- `RoadMarking_dPatterns`: width -> 32-bit pixel mask (11 entries).
- `RoadMarking_ram_XArray $FF14E8` / `WidthArray $FF1618` (`$98` cells each).
- `RoadMarking_ram_X1..X4 $FF1748..$FF1756`, `Width1..4`.
- `RoadMarking_SpriteHorizontalSize $FF1758`, `SpriteVerticalSize $FF175A`,
  `SpritePosX $FF175C`, `ColumnSizeBytes $FF175E`, `TileOffset $FF1760`.
- Uses `Animation_ram_TileIndex/SpriteIndex/BaseTile` and
  `Race_ram_CurrentSpriteAttributeTable/TileArray`.

## Open questions

- `RoadMarking_dPatterns` exact bit/pixel orientation.
- `SetSpriteGeometry` tall-sprite branch and the 2-tile-high column split.
- The 80/128 sprite cap and whether all road lines are covered.
- Dynamic verification against a rendered frame.

## Rename proposals

Function names above are applied; data/fields are TODO.

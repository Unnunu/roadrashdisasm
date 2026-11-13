# Module card: `src/race/road_render.asm`

- **ROM range:** `0x008FB4`–`0x0098C1` (`src/race/race_hud_debug.asm` starts at `0x98C2`)
- **Status:** analyzed (object list/records, shape header/control/interpolator/tile-writer
  pixel map and Data4 flag path confirmed; L6c/E8)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/road_render.md`

## Role / purpose
Race object sprite-tile renderer. `src/race/race.asm` calls `Road_DrawObjects` after
the HUD updates; it walks the visible-object list and renders each object's 4bpp
sprite tiles and SAT chain (`RiderSprites_Build`). The `Road_*` names are historical:
the written tiles are object sprites, not the road surface.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Road_DrawObjects` | `0x942A` | `src/race/race.asm:1809` | Walk the visible-object list. |
| `Road_DrawObject` | `0x9484` | `Road_DrawObjects` | Render one 0x14-byte object record. |
| `Road_DrawStrip` | `0x8FB4` | `Road_DrawObject` | Road strip/tile + sprite chain. |
| `Road_InterpolateLeftEdge`/`Road_InterpolateRightEdge` | `0x9142`/`0x91F0` | `Road_DrawStrip` | Left/right edge interpolation. |
| `Road_WriteTileColumns`/`Road_ClearEdgeTiles` | `0x9306`/`0x93D2` | `Road_DrawStrip` | Road tile columns / clear edge tiles. |
| `Road_ScaleShape`/`Road_ProjectShapeSpecial`/`Road_ProjectShape` | - | `Road_DrawObject` | Shape/edge projection. |
| `Road_InterpolateRightEdgeAlt` | `0x9272` | — | Alternate/unused strip generator. |

## External calls / dependencies
- Caller: `src/race/race.asm` (`Road_DrawObjects`).
- Internal: `RiderSprites_Build` (rider sprite chain), `Animation_ram_*`/`Race_ram_*` state.
- `src/race/race.asm` also uses `Road_ShapeTable` (`0x10018`, `0x10352`).

## Hacks / bugs / quirks
- `Road_InterpolateRightEdgeAlt` has no direct caller; likely alternate/dead. `[static]`
- The module shares `Animation_ram_TileIndex`/`SpriteIndex` with the animation/sprite
  builders as a combined road/sprite cursor. `[static]`
- The SAT is double-buffered; the dynamic run showed `$FF479C`/`$FF4E1C`. `[dynamic]`

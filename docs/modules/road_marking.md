# Module card: `src/race/road_marking.asm`

- **ROM range:** `0x00E732`–`0x00EB33` (`src/race/race_ai.asm` starts at `0xEB34`)
- **Status:** analyzed (partial; pattern/visual + dynamic TODO)
- **Related:** `docs/analysis/road_marking.md`, `docs/analysis/road_render.md`,
  `docs/analysis/animation.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose
Scans the road X/width arrays for unprocessed lines, groups them into sprite bands,
chooses sprite geometry, and emits marking sprites with tiles filled from
`RoadMarking_dPatterns`. Called from `Race_Update` via `RoadMarking_Draw`.

## API
| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RoadMarking_Draw` | ``0xE75E`` |
| `RoadMarking_FindUnprocessedLine` | ``0xE7B0`` |
| `RoadMarking_GetMarkingsSizes` | ``0xE7DA`` |
| `RoadMarking_SetSpriteGeometry` | ``0xE934`` |
| `RoadMarking_ClearSpriteTiles` | ``0xE9D2`` |
| `RoadMarking_CreateSprite` | ``0xE9F8`` |

Full list: the related analysis page.

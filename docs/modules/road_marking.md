# Module card: `road_marking.asm`

- **ROM range:** `0x00E732`–`0x00EB33` (`race_ai.asm` starts at `0xEB34`)
- **Status:** TODO (region identified; road marking internals not analyzed)
- **Related:** `docs/analysis/road_render.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Road marking / sprite placement, called from `Race_Update` via `RoadMarking_Draw`;
works with the road arrays and the object/sprite pipeline.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RoadMarking_Draw` | `0xE75E` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

Detailed analysis: TODO.

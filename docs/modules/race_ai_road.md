# Module card: `src/race/race_ai_road.asm`

- **ROM range:** `0x00EB34`–`0x010DFF` (`src/race/race_ai.asm` starts at `0x10E00`)
- **Status:** partially analyzed (road/profile/objects/standings/speed regions identified; internals TODO)
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_spawn.md`,
  `docs/ram-map.md`, `docs/modules/race.md`, `docs/modules/race_ai.md`,
  `docs/modules/race_anim_audio.md`

## Role / purpose

Road profile/interpolation, visible object lists, sprite-tile staging, race
standings/results helpers and the speed display: `PiecewiseLinearInterpolation`,
`Road_FillProfileTables`, `sub_F40C`..`sub_10DDA`, `Road_BuildVisibleList`,
`Race_WriteSpriteTiles`, `Race_UpdateSpeedDisplay`, `Race_FormatDecimal`.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Road_FillProfileTables` | `0xECE0` | `Race_Update` | Road profile tables. |
| `PiecewiseLinearInterpolation` | `0xF180` | `Race_Update` | Road array interpolation. |
| `Road_BuildVisibleList` | `0x10D46` | `Race_Update` | Visible object list. |
| `Race_UpdateSpeedDisplay` | `0xF108` | `Race_Update` | Speed display. |
| `Race_FormatDecimal` | `0xF11C` | HUD/debug | Packed decimal. |
| `Race_WriteSpriteTiles` | `0x10972` | `Race_GameTick` | Sprite tile staging. |

## Key functions

- `Race_DrawRoadEdges` `0xEC90`: road edges in the HUD; `unk_EB34` data.
- `Road_FillProfileTables` `0xECE0`: per-line HScroll + marking X/width.
- `Race_IntegrateTrackCurve` `0xEDD0`: `Track_CurveBuffer` -> profile arrays.
- `PiecewiseLinearInterpolation` `0xF180`: road-array interpolation.
- `Race_ComputeStandings`/`Race_ScaleResultValue` `0xEFA4`/`0xF0E4`: standings/results.
- `Race_WriteSpriteTiles` `0x10972`: sprite-tile staging.
- `Road_BuildVisibleList` `0x10D46`: visible object list.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| speed/decimal | `0xF108`/`0xF11C` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| visible list | `0x10D46` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| road/profile/objects | `0xF40C`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

Detailed flow: `docs/analysis/race.md`; spawn: `docs/analysis/race_spawn.md`.

# Module card: `race_ai.asm`

- **ROM range:** `0x00EB34`–`0x01685F` (`animation.asm` starts at `0x16860`)
- **Status:** partially analyzed (region/roles identified; most functions TODO)
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_spawn.md`,
  `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Main gameplay/AI/physics after `road_marking.asm`: road profile interpolation, visible
object lists, actor movement/AI, collisions and the render-preparation chain called by
`Race_Update`. It starts with the `unk_EB34` data and ends at `sub_16732`.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `sub_EC90`..`sub_16732` | `0xEC90`–`0x16732` | `Race_Update` | AI/physics/render chain. |
| `Race_BuildVisibleList` | `0x10D46` | `Race_Update` | Visible object list. |
| `Race_UpdateSpeedDisplay` | `0xF108` | `Race_Update` | Speed display. |
| `Race_FormatDecimal` | `0xF11C` | HUD/debug | Packed decimal. |

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Road_BuildVisibleList` | `0x10D46` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_FormatDecimal` | `0xF11C` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| AI/physics chain | `0xEC90`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

Detailed flow: `docs/analysis/race.md`; spawn: `docs/analysis/race_spawn.md`.

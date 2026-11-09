# Module card: `race_ai.asm`

- **ROM range:** `0x010E00`–`0x014055` (`race_anim_audio.asm` starts at `0x14056`)
- **Status:** partially analyzed (region/roles identified; most functions TODO)
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_spawn.md`,
  `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Actor movement/AI/physics and input: `sub_10E00`..`sub_13FE6`, including
`Race_HandleInputOnFoot`/`Race_AnotherInputOnFoot` and the per-frame actor/opponent
update chain. Road/profile/objects/standings live in `race_ai_road.asm`; animations,
random and audio live in `race_anim_audio.asm`.

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
| actor/input/AI chain | `0x10E00`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

Detailed flow: `docs/analysis/race.md`; spawn: `docs/analysis/race_spawn.md`.

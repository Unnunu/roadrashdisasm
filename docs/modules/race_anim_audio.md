# Module card: `src/race/race_anim_audio.asm`

- **ROM range:** `0x014056`–`0x01685F` (`src/race/animation.asm` starts at `0x16860`)
- **Status:** TODO (region identified; animations/random/audio internals not analyzed)
- **Related:** `docs/analysis/race.md`, `docs/analysis/rider_sprites.md`,
  `docs/analysis/race_physics.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Actor/road animations, random helpers and engine-audio routines:
`Race_UpdateLeanCurve`..`Race_UpdateCollision`, `Rand_Init`/`Rand_GetWord`, `Audio_UpdateEngine0`,
`Audio_UpdateEngineState`/audio helpers, and the data tables in between. Feeds the animation engine
(`src/race/animation.asm`/`RiderSprites_Build`) and the engine sound.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Race_UpdateLeanCurve`..`Race_UpdateCollision` | `0x1406A`+ | race/AI | Animation/road/audio helpers. |
| `Rand_Init` | `0x15FE8` | boot/race | PRNG init. |
| `Rand_GetWord` | `0x16034` | many | PRNG word. |
| `Audio_UpdateEngine0`/`Audio_UpdateEngineState` | `0x16520`/`0x16548` | HInt/race | Engine audio. |

## Key functions

- `Race_UpdateLeanCurve` `0x1406A`: lean/curve `$3E/$40`.
- `Race_UpdatePlayerAnimation` `0x160E2`: player tile base `$5C`.
- `Race_UpdateNearestTarget` `0x1611A`: nearest actor by squared distance.
- `Race_UpdateCollision` `0x16732`: proximity/impact + engine/gear.
- `Audio_UpdateEngineState` `0x16548` / `Audio_UpdateEngine0` `0x16520`.
- `Rand_Init` `0x15FE8` / `Rand_GetWord` `0x16034`: 32-word sum PRNG.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| animations | `0x1406A`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| random | `0x15FE8`/`0x16034` | [ ] | [ ] | [ ] | - | [ ] | [ ] | TODO |
| engine audio | `0x16520`+ | [ ] | [ ] | [ ] | [x] | [ ] | [ ] | TODO |

Detailed flow: `docs/analysis/race.md`; animation: `docs/analysis/rider_sprites.md`.

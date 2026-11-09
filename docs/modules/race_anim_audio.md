# Module card: `race_anim_audio.asm`

- **ROM range:** `0x014056`–`0x01685F` (`animation.asm` starts at `0x16860`)
- **Status:** TODO (region identified; animations/random/audio internals not analyzed)
- **Related:** `docs/analysis/race.md`, `docs/analysis/rider_sprites.md`,
  `docs/analysis/race_physics.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Actor/road animations, random helpers and engine-audio routines:
`sub_1406A`..`sub_16732`, `Rand_Init`/`Rand_GetWord`, `Audio_UpdateEngine0`,
`sub_16548`/audio helpers, and the data tables in between. Feeds the animation engine
(`animation.asm`/`RiderSprites_Build`) and the engine sound.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `sub_1406A`..`sub_16732` | `0x1406A`+ | race/AI | Animation/road/audio helpers. |
| `Rand_Init` | `0x15FE8` | boot/race | PRNG init. |
| `Rand_GetWord` | `0x16034` | many | PRNG word. |
| `Audio_UpdateEngine0`/`sub_16548` | `0x16520`/`0x16548` | HInt/race | Engine audio. |

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| animations | `0x1406A`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| random | `0x15FE8`/`0x16034` | [ ] | [ ] | [ ] | - | [ ] | [ ] | TODO |
| engine audio | `0x16520`+ | [ ] | [ ] | [ ] | [x] | [ ] | [ ] | TODO |

Detailed flow: `docs/analysis/race.md`; animation: `docs/analysis/rider_sprites.md`.

# Module card: `race_spawn.asm`

- **ROM range:** `0x0169B0`–`0x016E6F` (after `animation.asm`)
- **Status:** analyzed (track data init/next chunk + dynamic spawn)
- **Related:** `docs/analysis/race_spawn.md`, `docs/analysis/race_actors.md`,
  `race_actor_tables.asm`,
  `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Track-data initialization/streaming, dynamic opponent/traffic spawn and the active/free
actor lists; the final part of the race module.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `TrackData_InitLevel` | `0x169B0` | `Race_Init` | Initial track data + scaling. |
| `TrackData_DecodeNextChunk` | `0x16A32` | `top_level.asm` | Next 64-sample chunk. |
| `Race_SpawnTick` | `0x16AF6` | `Race_Update` | Opponent/traffic spawn. |
| `Race_SpawnOpponent`/`Traffic` | `0x16BD6`/`0x16C1A` | spawn tick | Ahead/behind paths. |
| `Race_UpdateSpeedDisplay`/`Race_FormatDecimal` | `0xF108`/`0xF11C` | HUD/debug | Speed/decimal (`race_ai_road.asm`). |

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| track data init/chunk | `0x169B0`/`0x16A32` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| spawn tick/paths | `0x16AF6`+ | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| active/free lists | `0x16D0A`+ | [x] | [x] | [x] | - | [x] | [ ] | analyzed |

Detailed listing: `docs/analysis/race_spawn.md`.

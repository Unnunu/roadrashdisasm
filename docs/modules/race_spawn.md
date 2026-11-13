# Module card: `src/race/race_spawn.asm`

- **ROM range:** `0x0169B0`–`0x016E6F` (after `src/race/animation.asm`)
- **Status:** L5 complete (track data init/next chunk, Data5 normal/special lists, four-population lifecycle, E5 dynamic)
- **Related:** `docs/analysis/race_spawn.md`, `docs/analysis/race_actors.md`,
  `src/data/race_actor_tables.asm`,
  `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose
Track-data initialization/streaming, dynamic opponent/traffic spawn and the active/free
actor lists; the final part of the race module.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `TrackData_InitLevel` | `0x169B0` | `Race_Init` | Initial track data + scaling. |
| `TrackData_DecodeNextChunk` | `0x16A32` | `src/core/top_level.asm` | Next 64-sample chunk. |
| `Race_SpawnTick` | `0x16AF6` | `Race_Update` | Opponent/traffic spawn. |
| `Race_SpawnOpponent`/`Traffic` | `0x16BD6`/`0x16C1A` | spawn tick | Ahead/behind free-list paths. |
| `sub_13BF4`/`sub_13CFE` | `0x13BF4`/`0x13CFE` | `Race_Update` | Reserved `ram_FF1F2A` opponent (rating gate + `Data5` special list). |
| `sub_138CE`/`sub_13A26` | `0x138CE`/`0x13A26` | `Race_Update`/timer | Static pair respawn cycle. |
| `Race_InitExtraStaticActor`/`Update` | `0x128E0`/`0x12974` | `Race_Update` | `$FF2FAA` extra slot (`shape $186` marker). |
| `Race_UpdateSpeedDisplay`/`Race_FormatDecimal` | `0xF108`/`0xF11C` | HUD/debug | Speed/decimal (`src/race/race_ai_road.asm`). |

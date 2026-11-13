# Module card: `src/race/race_core.asm`

- **ROM range:** `0x00A4E2`–`0x00D277` (`src/race/race_hud.asm` follows at `0xD278`)
- **Status:** partially analyzed (top-level/init/results/actor tables; physics/AI TODO)
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_actors.md`,
  `src/data/race_actor_tables.asm` (actor tables),
  `docs/analysis/race_spawn.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose
Race top-level and setup: `Race_Init`, asset loaders, track/bike/actor initialization,
`Race_GameTick`, `Race_Update`, buffer rotation, input, race outcome helpers and the
actor definition tables. This is the code executed around the `race_hud` module.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Race_Init` | `0xA4E2` | `src/core/top_level.asm` | Full level setup + warm-up frames. |
| `Race_GameTick` | `0xBA76` | fade wrapper | VDP/input/pause/demo. |
| `Race_Update` | `0xC00C` | `src/core/top_level.asm` | Simulation + render prep driver. |
| `Race_GetInput`/`Demo` | `0xBE56`/`0xBE2C` | `Race_GameTick` | Steering/buttons/pause. |
| `Race_ComputeResults` | `0xC3F8` | race end | Outcome/places/password/money. |
| `Race_CreateActors` | `0xCAD0` | `Race_Init` | Actor structs from definitions. |

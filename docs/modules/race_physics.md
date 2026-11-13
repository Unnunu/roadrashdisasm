# Module card: `src/race/race_physics.asm`

- **ROM range:** `0x00D8FA`–`0x00E731` (`src/race/road_marking.asm` starts at `0xE732`)
- **Status:** L6a camera/progress/VScroll/HScroll complete (matrix v10, E6); U-0018 compaction closed (v13); rearview and engine-audio mapping remain TODO
- **Related:** `docs/analysis/race.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose
`DmaWriteVRAM` plus the actor/physics/AI functions placed after the HUD and before the
road-marking module. Called from `Race_GameTick`/`Race_Update` in `src/race/race_core.asm`.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `DmaWriteVRAM` | `0xD8FA` | `Race_GameTick` | DMA a RAM block to VRAM. |
| `Race_DrawRearviewMirror`..`Race_UpdateNearestOpponent` | `0xD9DA`–`0xE5EE` | `Race_Update` | Actor/road/physics helpers (TODO). |

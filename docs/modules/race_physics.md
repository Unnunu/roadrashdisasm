# Module card: `race_physics.asm`

- **ROM range:** `0x00D8FA`–`0x00E731` (`road_marking.asm` starts at `0xE732`)
- **Status:** partially analyzed (code region identified; actor/physics/AI functions TODO)
- **Related:** `docs/analysis/race.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

`DmaWriteVRAM` plus the actor/physics/AI functions placed after the HUD and before the
road-marking module. Called from `Race_GameTick`/`Race_Update` in `race_core.asm`.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `DmaWriteVRAM` | `0xD8FA` | `Race_GameTick` | DMA a RAM block to VRAM. |
| `Race_DrawRearviewMirror`..`Race_UpdateNearestOpponent` | `0xD9DA`–`0xE5EE` | `Race_Update` | Actor/road/physics helpers (TODO). |

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `DmaWriteVRAM` | `0xD8FA` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| actor/physics helpers | `0xD9DA`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

Detailed flow: `docs/analysis/race.md`.

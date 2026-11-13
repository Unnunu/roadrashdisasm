# Module card: `src/race/race_physics.asm`

- **ROM range:** `0x00D8FA`–`0x00E731` (`src/race/road_marking.asm` starts at `0xE732`)
- **Status:** L6a camera/progress/VScroll/HScroll complete (matrix v10, E6); rearview and engine-audio mapping remain TODO
- **Related:** `docs/analysis/race.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

`DmaWriteVRAM` plus the actor/physics/AI functions placed after the HUD and before the
road-marking module. Called from `Race_GameTick`/`Race_Update` in `src/race/race_core.asm`.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `DmaWriteVRAM` | `0xD8FA` | `Race_GameTick` | DMA a RAM block to VRAM. |
| `Race_DrawRearviewMirror`..`Race_UpdateNearestOpponent` | `0xD9DA`–`0xE5EE` | `Race_Update` | Actor/road/physics helpers (TODO). |

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `DmaWriteVRAM` | `0xD8FA` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| actor/physics helpers | `0xD9DA`+ | [~] | [~] | [~] | [ ] | [~] | [~] | partial |
| camera/progress | `0xDE9E` | [x] | [x] | [x] | [x] | [x] | [x] | L6a done (E6) |
| HInt VScroll/HScroll | `0xE004`/`0xE494` | [x] | [x] | [x] | [x] | [x] | [x] | L6a done (E6); `U-0018` compaction |
| nearest opponent | `0xE5EE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| actor sprite projection | `0xDAE2` | [x] | [~] | [x] | [x] | [~] | [~] | static + object snapshot |

Detailed flow: `docs/analysis/race_physics.md` (L6a contract), `docs/analysis/race.md`.

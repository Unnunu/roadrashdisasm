# Module card: `src/race/animation.asm`

- **ROM range:** `0x016860`–`0x0169AF` (`src/race/race_spawn.asm` starts at `0x169B0`)
- **Status:** analyzed (scripts/data + dynamic TODO)
- **Related:** `docs/analysis/animation.md`, `docs/analysis/rider_sprites.md`,
  `docs/analysis/race_hud.md`, `docs/analysis/race.md`, `docs/ram-map.md`,
  `docs/modules/race.md`

## Role / purpose

Sprite animation renderer: `UpdateAnimation`/`UpdateAnimation2` consume animation
scripts (`{tilemap, frame_count, frame_ptrs[]}`), write SAT entries, optionally copy
the needed tiles, and advance the animation tile/sprite indices. Used by race/actor
rendering, the HUD needles and the rider sprite chain.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `UpdateAnimation` | `0x16860` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `UpdateAnimation2` | `0x16926` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Animation_dTileCountMinus1` | `0x169A0` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |

Detailed analysis: `docs/analysis/animation.md`.

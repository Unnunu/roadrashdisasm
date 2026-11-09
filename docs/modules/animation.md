# Module card: `animation.asm`

- **ROM range:** `0x016860`–`0x0169AF` (`race_spawn.asm` starts at `0x169B0`)
- **Status:** partially analyzed (`UpdateAnimation`/`UpdateAnimation2` roles; scripts TODO)
- **Related:** `docs/analysis/rider_sprites.md`, `docs/analysis/race.md`,
  `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Sprite animation: `UpdateAnimation`/`UpdateAnimation2` consume the animation scripts,
write the SAT entries/tile copies and advance the animation tile/sprite indices; used
by the race/actor rendering and the rider sprite chain (`RiderSprites_Build`).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `UpdateAnimation` | `0x16860` | [x] | [~] | [x] | [x] | [x] | [ ] | partial |
| `UpdateAnimation2` | TODO | [x] | [~] | [x] | [x] | [x] | [ ] | partial |

Detailed analysis: `docs/analysis/rider_sprites.md`, `docs/analysis/race.md`.

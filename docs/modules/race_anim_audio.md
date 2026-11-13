# Module card: `src/race/race_anim_audio.asm`

- **ROM range:** `0x014056`–`0x016119` (`src/race/race_combat.asm` starts at `0x1611A`)
- **Status:** analyzed (audio helpers/player animation); PRNG in `rand.asm`; combat moved to `race_combat`
- **Related:** `docs/analysis/race.md`, `docs/analysis/rider_sprites.md`,
  `docs/analysis/race_physics.md`, `docs/analysis/combat.md`,
  `docs/analysis/rand.md`, `docs/ram-map.md`, `docs/modules/race.md`,
  `docs/modules/combat.md`, `docs/modules/rand.md`

## Role / purpose

Actor/road animation support, engine-audio helpers and the animation/impact data
tables. PRNG/LFSR helpers live in `src/race/rand.asm`. The player attack state, AI combat actions,
nearest-target selection and collision state now live in
`src/race/race_combat.asm` (`0x1611A`–`0x1685F`).

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Race_UpdateLeanCurve` | `0x1406A` | race/AI | Lean/curve `$3E/$40`. |
| `Race_UpdatePlayerAnimation` | `0x160E2` | race | Player tile base `$5C`. |
| `Race_ScaleImpactDamage`/`Race_ApplyCollisionImpact`/`Race_ExchangeCollisionSpeed` | `0x1434A`+ | combat/physics | Impact/damage helpers (shared with `race_combat`). |

## Key functions

- `Race_UpdateLeanCurve` `0x1406A`: lean/curve `$3E/$40`.
- `Race_UpdatePlayerAnimation` `0x160E2`: player tile base `$5C`.
- PRNG/LFSR helpers: see `src/race/rand.asm` and `docs/modules/rand.md`.
- Crash/action handlers (R30): `sub_140BC`, `sub_140EE`, `sub_141AE`,
  `sub_142B0`/`sub_142BE`/`sub_142CC`, `sub_142FE`, `sub_1436E`,
  `sub_14404`/`sub_14456`/`sub_1446E`; `sub_14DEC`; `sub_15580`.
- Tables: `unk_14744`/`unk_147FC` action handlers, `Race_TrackObjectTypeTable`,
  `unk_155A4`/`unk_155AC`/`unk_155D0`, `unk_15618`/`unk_1561C`/`unk_15624`.
- Impact/damage helpers `Race_ScaleImpactDamage`/`Race_ApplyCollisionImpact`/`Race_ExchangeCollisionSpeed` remain here; attack
  state and action dispatch are in `race_combat`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| animations | `0x1406A`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| random | `0x15FA8`+ | [x] | [x] | [x] | - | [x] | [ ] | moved to `rand.asm` |
| player animation | `0x160E2` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| impact/action handlers | `0x140BC`-`0x14486` | [~] | [~] | [x] | [x] | [~] | [ ] | disassembled (R30) |
| impact/damage helpers | `0x1434A`+ | [~] | [~] | [~] | [x] | [~] | [ ] | partial |

Detailed flow: `docs/analysis/race.md`; animation: `docs/analysis/rider_sprites.md`;
combat: `docs/analysis/combat.md`.

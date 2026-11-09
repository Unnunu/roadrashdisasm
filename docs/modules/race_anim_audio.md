# Module card: `src/race/race_anim_audio.asm`

- **ROM range:** `0x014056`–`0x016119` (`src/race/race_combat.asm` starts at `0x1611A`)
- **Status:** analyzed (PRNG/audio helpers/player animation); combat moved to `race_combat`
- **Related:** `docs/analysis/race.md`, `docs/analysis/rider_sprites.md`,
  `docs/analysis/race_physics.md`, `docs/analysis/combat.md`, `docs/ram-map.md`,
  `docs/modules/race.md`, `docs/modules/combat.md`

## Role / purpose

Actor/road animation support, PRNG helpers, engine-audio helpers and the
animation/impact data tables. The player attack state, AI combat actions,
nearest-target selection and collision state now live in
`src/race/race_combat.asm` (`0x1611A`–`0x1685F`).

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Race_UpdateLeanCurve` | `0x1406A` | race/AI | Lean/curve `$3E/$40`. |
| `Race_UpdatePlayerAnimation` | `0x160E2` | race | Player tile base `$5C`. |
| `Rand_Init` | `0x15FE8` | boot/race | PRNG init. |
| `Rand_GetWord` | `0x16034` | many | PRNG word. |
| `Race_ScaleImpactDamage`/`sub_14486`/`sub_14CEC` | `0x1434A`+ | combat/physics | Impact/damage helpers (shared with `race_combat`). |

## Key functions

- `Race_UpdateLeanCurve` `0x1406A`: lean/curve `$3E/$40`.
- `Race_UpdatePlayerAnimation` `0x160E2`: player tile base `$5C`.
- `Rand_Init` `0x15FE8` / `Rand_GetWord` `0x16034`: 32-word sum PRNG.
- Impact/damage helpers `Race_ScaleImpactDamage`/`sub_14486`/`sub_14CEC` remain here; attack
  state and action dispatch are in `race_combat`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| animations | `0x1406A`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| random | `0x15FE8`/`0x16034` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| player animation | `0x160E2` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| impact/damage helpers | `0x1434A`+ | [~] | [~] | [~] | [x] | [~] | [ ] | partial |

Detailed flow: `docs/analysis/race.md`; animation: `docs/analysis/rider_sprites.md`;
combat: `docs/analysis/combat.md`.

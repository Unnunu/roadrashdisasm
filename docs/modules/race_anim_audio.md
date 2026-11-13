# Module card: `src/race/race_anim_audio.asm`

- **ROM range:** `0x014056`–`0x016119` (`src/race/race_combat.asm` starts at `0x1611A`)
- **Status:** analyzed (audio helpers/player animation); crash/fall handler contracts and tables integrated (R30, matrix v5); L7/E7 decoded the `unk_15CE0`/`unk_15CFC` crash scripts; PRNG in `rand.asm`; combat moved to `race_combat`
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

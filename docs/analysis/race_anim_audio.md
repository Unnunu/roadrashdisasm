# Analysis: `src/race/race_anim_audio.asm` (audio/impact helpers, animation)

- **Module:** engine-audio helpers, player animation, impact/damage helpers, and the
  track/animation data tables; PRNG/LFSR helpers moved to `src/race/rand.asm`
- **ROM range:** `0x014056`–`0x016119`
- **Status:** partially analyzed (player animation/roles); PRNG analyzed in
  `docs/analysis/rand.md`; animation/impact internals TODO; combat moved to
  `src/race/race_combat.asm`
- **Source:** `src/race/race_anim_audio.asm`
- **Related:** `docs/analysis/combat.md` (attack input/state/actions),
  `docs/analysis/race.md`, `docs/analysis/race_ai.md`,
  `docs/analysis/race_physics.md`, `docs/analysis/rand.md`,
  `docs/modules/race_anim_audio.md`, `docs/ram-map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `Race_UpdateLeanCurve` | `0x1406A` | Lean/curve `$3E/$40` and `ram_FF3042`. |
| `Race_UpdatePlayerAnimation` | `0x160E2` | Player `$5C` animation/tile base clamp. |
| `sub_141...`..`sub_155...` | `0x1406A`+ | Animation/track/impact helpers (TODO). |
| `Race_ScaleImpactDamage`/`Race_ApplyCollisionImpact`/`Race_ExchangeCollisionSpeed` | `0x1434A`+ | Impact/damage helpers shared with combat. |

Combat/target/collision functions (`Race_UpdateNearestTarget`, `Race_UpdatePlayerAttack`,
`sub_1634E`, `Race_DispatchActorAction`, `Audio_UpdateEngine*`, action handlers,
`Race_UpdateCollision`) are now in `src/race/race_combat.asm`; see
`docs/analysis/combat.md`.

## PRNG

The 32-word lagged-sum PRNG and the two 16-bit LFSR helpers are now in
`src/race/rand.asm`, included at the original `$15FA8` location. See
`docs/analysis/rand.md` for contracts, the fixed 0/15 index quirk, caller map and
unreferenced helpers.

## Animation / impact

- `Race_UpdateLeanCurve` computes the lean/curve from `$3E`/d0 into `$40`/`ram_FF3042`.
- `Race_UpdatePlayerAnimation` advances the player tile base `$5C` up to `ram_FF18AA`
  by `Race_ram_FrameDelay` (on-foot/`$6E` gated).
- `Race_ScaleImpactDamage`/`Race_ApplyCollisionImpact`/`Race_ExchangeCollisionSpeed` handle impact/damage side effects; their
  callers and exact collision rules remain TODO.
- `Race_UpdateActorPairImpact` sets `ram_FF0520=3` when player A attacks the actor whose
  `$71` index equals `ram_FF1ADB`, i.e. Natasha (`U-0004`).

## Data / RAM

- `unk_14056` (curve speed limit; `Race_GetCurveSpeedLimit`), `unk_1471A` (track
  params; `Race_LoadTrackParams`), `word_14742` (curve speed), `unk_155A4`/
  `unk_15624`/`unk_15CE0`/`unk_15CFC` (animation data).
- PRNG/LFSR tables and RAM are documented in `docs/analysis/rand.md`.
- Actor fields: `$3E/$40/$42` lean, `$4A/$5A` impact/range, `$5C` tile base,
  `$6E` on-foot/animation gate. Attack fields: see `docs/ram-map.md` combat section.

## Open questions

- Exact animation table/scripts and `sub_141...`/`sub_155...` helpers.
- Impact/damage helper contracts and collision callers (shared with `race_combat`).
- Next: `src/race/race_hud.asm`/`src/race/road_marking.asm`/`src/race/animation.asm` cards/internals.

## Rename proposals

Animation/impact data/field names remain TODO. PRNG/LFSR rename proposals are in
`docs/analysis/rand.md`.

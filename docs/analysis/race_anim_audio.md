# Analysis: `src/race/race_anim_audio.asm` (audio/impact helpers, animation)

- **Module:** engine-audio helpers, player animation, impact/damage helpers, and the
  track/animation data tables; PRNG/LFSR helpers moved to `src/race/rand.asm`
- **ROM range:** `0x014056`–`0x016119`
- **Status:** partially analyzed (player animation/roles; impact/action handlers
  `0x140BC`-`0x14486` disassembled in R30); PRNG analyzed in
  `docs/analysis/rand.md`; remaining animation scripts TODO; combat moved to
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
| `sub_140BC` | `0x140BC` | X/PreviousX from a track-object byte + PlayerProgress. |
| `sub_140EE`/`sub_141AE` | `0x140EE`/`0x141AE` | Crash handlers (on-road / high-speed/off-road). |
| `sub_142B0`/`sub_142BE`/`sub_142CC` | `0x142B0`+ | Crash wrappers (`ram_FF1AD6=$F/$17`, `$6B` bit1). |
| `sub_142FE`/`sub_1436E` | `0x142FE`/`0x1436E` | Road-Y clamp / shadow-speed scale. |
| `sub_14404`/`sub_14456`/`sub_1446E` | `0x14404`+ | Collision-impact fallback and FallState timers. |
| `sub_14DEC` | `0x14DEC` | Frame-distance delta helper (`d0` always 0, `U-0015`). |
| `sub_15580` | `0x15580` | Random FallState from `unk_1561C`. |
| `sub_141...`..`sub_155...` | `0x1406A`+ | Remaining animation helpers/scripts (TODO). |
| `Race_ScaleImpactDamage`/`Race_ApplyCollisionImpact`/`Race_ExchangeCollisionSpeed` | `0x1434A`+ | Impact/damage helpers shared with combat. |

Combat/target/collision functions (`Race_UpdateNearestTarget`, `Race_UpdatePlayerAttack`,
`sub_1634E`, `Race_DispatchActorAction`, `Audio_UpdateEngine*`, action handlers,
`Race_UpdateCollision`) are now in `src/race/race_combat.asm`; see
`docs/analysis/combat.md`.

## Impact/action handlers (`0x140BC`-`0x14486`, R30)

| Function | Address | Role | Evidence |
|---|---|---|---|
| `sub_140BC` | `0x140BC` | `X/PreviousX = ($E(a0)<<8)+PlayerProgress`, `+$4000` or `-$A000` by `$69` bit3. | `[static]` |
| `sub_140EE` | `0x140EE` | Main on-road crash: Speed < `$FA0` -> `sub_142FE`; else X/shadow/SFX/damage. | `[static]` |
| `sub_141AE` | `0x141AE` | High-speed/off-road crash: Speed clamp `$2710`, X shift `$6000`, FallState `$9/$5`. | `[static]` |
| `sub_142B0` / `sub_142BE` / `sub_142CC` | `0x142B0`+ | `sub_140EE` + `ram_FF1AD6=$F` / `$17` / `$6B` bit1. | `[static]` |
| `sub_142FE` | `0x142FE` | `PosY/$1A = ram_FF1B14 +/- extent`; X -`$4000` when FrameDistance=0. | `[static]` |
| `sub_1436E` | `0x1436E` | Scales actor-shadow Speed by `d0` (16.16; `$C000` in the crash paths). | `[static]` |
| `sub_14404` | `0x14404` | Collision impact: `sub_1438E`, AnimState fallback, `ram_FF1AD6=$F`, optional `sub_140BC`. | `[static]` |
| `sub_14456` / `sub_1446E` | `0x14456`+ | `$68` bit5 + AnimTimer `$78`/`$1E` when `$6E < 3`. | `[static]` |
| `sub_14DEC` | `0x14DEC` | Returns `d0=0` and `d1=(FrameDistance(a1)-FrameDistance(a2))/FrameDelay`. | `[static]`, `U-0015` |
| `sub_15580` | `0x15580` | FallState = `unk_1561C[Rand_NextWord & 7]`. | `[static]` |

`unk_14744` holds the 8 action handlers dispatched via `unk_147FC`; `$15458-$15467`
is dead code inside `sub_15446`.

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

- `unk_14056` (10-word curve scale; `Race_GetCurveSpeedLimit`), `unk_1471A` (5x4
  track params; `Race_LoadTrackParams`), `word_14742` (unreachable curve timer limit).
- `unk_14744` (8 `dc.l` action handlers) + `unk_147FC` (128-byte handler index table)
  are consumed by `sub_12070`; `Race_TrackObjectTypeTable` is 19 x 8-byte records used
  by `sub_13D44` (index byte +2, filter word +6, `U-0014`).
- `unk_155A4` is a one-pointer + `$FFFFFFFF` list loaded but not read by `sub_15478`.
  `unk_155AC` is a 3-byte header + 8x4-byte records + `$FF` sentinel consumed by
  `sub_154D2`. `unk_155D0` is 18 FallState -> animation-sequence pointers.
- `unk_15618`/`unk_1561C`/`unk_15624` are 4/8/8-entry random FallState tables
  (`sub_15538`/`sub_15580`/`sub_1555C`). `unk_15CE0`/`unk_15CFC` remain animation data.
- PRNG/LFSR tables and RAM are documented in `docs/analysis/rand.md`.
- Actor fields: `$3E/$40/$42` lean, `$4A/$5A` impact/range, `$5C` tile base,
  `$6E` on-foot/animation gate. Attack fields: see `docs/ram-map.md` combat section.

## Open questions

- Remaining animation scripts targeted by `unk_155D0` and the `unk_155AC` sequencer
  fields.
- Dynamic confirmation of the crash-handler branches and damage timing; `sub_14DEC`
  has no static caller (`U-0015`).
- `unk_155A4`/`unk_15CE0`/`unk_15CFC` consumers and `unk_147FC` value distribution.
- Next: `src/race/race_hud.asm`/`src/race/road_marking.asm`/`src/race/animation.asm` cards/internals.

## Rename proposals

Proposed only; no rename applied. See `identifiers.md` (R30 rows).
`sub_140BC` -> `Race_UpdateActorXFromTrackObject`; `sub_140EE` ->
`Race_ApplyActorCrash`; `sub_141AE` -> `Race_ApplyActorHighSpeedCrash`;
`sub_142B0`/`sub_142BE`/`sub_142CC` -> `Race_ApplyCrash0F`/`17`/`WithAttackFlag`;
`sub_142FE` -> `Race_UpdateActorRoadY`; `sub_1436E` ->
`Race_ScaleActorShadowSpeed`; `sub_14404` -> `Race_HandleActorCollisionImpact`;
`sub_14456`/`sub_1446E` -> `Race_SetActorFallShort`/`Long`; `sub_14DEC` ->
`Race_GetActorFrameDistanceDelta`; `sub_15580` -> `Race_SetRandomFallState`;
`unk_14744` -> `Race_ActionHandlerTable`; `unk_147FC` ->
`Race_ActionHandlerIndexTable`; `unk_155D0` -> `Race_FallSequenceTable`.
PRNG/LFSR rename proposals are in `docs/analysis/rand.md`.

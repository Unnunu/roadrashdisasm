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
| `sub_14DEC` | `0x14DEC` | Frame-distance delta helper (`d0` always 0, no caller; `U-0015` closed). |
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
| `sub_14DEC` | `0x14DEC` | Returns `d0=0` (both Speed terms read `$12(a1)`) and `d1=(FrameDistance(a1)-FrameDistance(a2))/FrameDelay`; no caller/pointer reference (vestigial). | `[static]` `U-0015` closed |
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
- `Race_UpdatePlayerAnimation` advances the player **stamina** `$5C` up to
  `ram_FF18AA` by `Race_ram_FrameDelay` (on-foot/`$6E` gated).
- `Race_ScaleImpactDamage`/`Race_ApplyCollisionImpact`/`Race_ExchangeCollisionSpeed`
  handle impact/damage side effects. L4 (`tasks/race_L4_impact_contracts.md`, E4)
  confirmed both `Race_ApplyCollisionImpact` branches, the `ScaleImpactDamage =
  abs(x)>>11` scale (`ram_FF1768` suppression), and the knockdown `$5C` arithmetic;
  see `docs/analysis/race_impact.md`.
- `Race_UpdateActorPairImpact` sets `ram_FF0520=3` when player A attacks the actor whose
  `$71` index equals `ram_FF1ADB`, i.e. Natasha (`U-0004`).
- `sub_15014` is the fall/on-foot animation updater. `Race_BuildActorObjectList`
  calls it when actor `$68` bit4 is set and `$6E >= 0`; it first runs
  `sub_1533E`, then clamps `FallState ($54)` to `$11` and uses
  `unk_155D0[FallState]` as the AnimState -> frame-script sequence. For
  `AnimState == 3` (fall/crash) it chooses:
  - `d3 = $26 >> 8`, `d4 = |$22|`; if `d3 < d4` -> `unk_15CFC`
    (`ram_FF18BC = $B2`);
  - else if `$69` bit3 is clear and actor progress (`$4` high word) <
    `Race_ram_PlayerProgress` -> `unk_15CE0` (`ram_FF18BC = $B1`);
  - else if `$69` bit3 is set and the actor is not behind the player ->
    `unk_15CE0` (`$B1`);
  - otherwise the default sequence entry (`$15CC4` in the demo tables) stays
    (`ram_FF18BC = $B0`).
  This is the "close / relative-side" pair of crash scripts; it is unrelated to the
  `unk_155AC` sequence used by `sub_15478`.

## E7-B animation-script selection (`analysis/capture_L7_anim3.gdb`)

`analysis/notes/L7_anim3_trace.txt` forced PlayerA into the fall path (`$68` bit4,
AnimState 3) and set the three relative-position cases:

| Case | Forced state | Selected script | Token |
|---|---|---|---|
| close | `$22=$0100`, `$26>>8=0` | `unk_15CFC` | `$B2` |
| behind | `$69` bit3 clear, progress 0 | `unk_15CE0` | `$B1` |
| ahead/mismatch | progress `$7FFF...` | default `$15CC4` | `$B0` |

The 8 forced calls also confirmed the `$15054` -> `$150EE` fall path and that
`Race_BuildActorObjectList` only reaches `sub_15014` when the on-foot/fall gate
(`$68` bit4) is set; normal demo riding never exercises these alternate scripts.

## Data / RAM

- `unk_14056` (10-word curve scale; `Race_GetCurveSpeedLimit`), `unk_1471A` (5x4
  track params; `Race_LoadTrackParams`), `word_14742` (curve limit used while the
  `$78` fall timer is armed by `sub_14456`/`sub_1446E`).
- `unk_14744` (8 `dc.l` action handlers) + `unk_147FC` (128-byte handler index table)
  are consumed by `sub_12070`/`sub_11CC8`; `Race_TrackObjectTypeTable` is 19 x 8-byte
  records (`+0` flags, `+2` size, `+4` handler index, `+6` steerable word) used by
  `sub_13D44`/`sub_13DE0`/`sub_12070` (`U-0014` closed).
- `unk_155A4` is a one-pointer + `$FFFFFFFF` list loaded but not read by `sub_15478`.
  `unk_155AC` is a 3-byte header + 8x4-byte records + `$FF` sentinel consumed by
  `sub_154D2`. `unk_155D0` is 18 FallState -> animation-sequence pointers.
- `unk_15618`/`unk_1561C`/`unk_15624` are 4/8/8-entry random FallState tables
  (`sub_15538`/`sub_15580`/`sub_1555C`).
- `unk_15CE0`/`unk_15CFC` are alternate AnimState-3 fall/crash frame scripts selected
  by `sub_15014` (below). Both are 6-frame, single-sprite scripts with header
  `$00B3`, timer `4`, tile deltas `6..$B` -> tiles `$B9..$BE` (`unk_15CE0`) and
  `$C..$11` -> tiles `$BF..$C4` (`unk_15CFC`), followed by an `$FF` sentinel.
- PRNG/LFSR tables and RAM are documented in `docs/analysis/rand.md`.
- Actor fields: `$3E/$40/$42` lean, `$4A/$5A/$52` impact/range, `$5C` stamina,
  `$6E` on-foot/animation gate. Attack fields: see `docs/ram-map.md` combat section.

## Open questions

- Remaining animation scripts targeted by `unk_155D0` and the `unk_155AC` sequencer
  fields.
- L4 impact/damage/knockdown is confirmed (E4); the crash-handler branch timing
  (`sub_140EE`/`sub_141AE`) is still static-only because the demo never crashes.
  `sub_14DEC` is vestigial with no static caller (`U-0015` closed).
- `unk_155A4` is still a vestigial pointer list; `unk_147FC` value distribution is
  documented from the R30 table.
- Remaining individual FallState frame scripts (the `$156..$159` blocks) are byte
  data and not individually annotated.
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

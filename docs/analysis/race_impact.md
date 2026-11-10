# Race impact / fall contract

Scope: `Race_UpdateActorPairImpact`, `Race_ClampActorPairY`,
`Race_ApplyCollisionImpact`, `Race_ApplyCrashImpact`, `Race_ApplyFallKnockdown`,
`Race_ExchangeCollisionSpeed`, `Race_AdjustActorTrackPositions`.

## Entry paths

- `Race_UpdateActorPairCollision` decides whether two actors overlap and calls the
  impact path.
- `Race_ApplyCollisionImpact` handles object/road collision and sets the speed-loss
  state.
- `Race_ApplyCrashImpact` handles crash/fall animation entry.
- `Race_ApplyFallKnockdown` applies accumulated pair impact to the knockdown
  counter.

## `Race_UpdateActorPairImpact`

1. Clear `Race_ram_PairSpeedDeltaA/B`, `Race_ram_PairImpactA/B`.
2. Compare previous X positions:
   - if the gap is outside `$FFFFA000..ram_FF3038`, exchange collision speed;
   - otherwise clamp Y separation and process attack/overlap.
3. If `StateFlags` bit4 is clear or `AttackReach == 0`:
   - add `AttackOverlap` to `$22`;
   - clear overlap and `PairImpactB`.
4. If `AttackReach != 0` and the player attacks the selected target:
   - set `ram_FF0520=3`;
   - in attack phase 1, call `Race_StealClub`.
5. Repeat the same overlap/steal logic for the second actor.
6. Call `Race_AdjustActorTrackPositions` and `Race_ApplyFallKnockdown`.

`Race_ClampActorPairY` uses `CollisionExtentLower/Upper` plus `$10` to separate the
actors; it updates `$30` and the draw Y difference.

## `Race_ApplyCollisionImpact`

- `d0 = actor[+$1C]` (`PreviousCollisionOffset`), compared with `ram_FF303E`.
- If below the threshold:
  - `Race_UpdateCollisionSpeedState($1000)` -> `ram_FF18A6`;
  - player A: `Race_ScaleImpactDamage` -> `Race_ram_BikeDamage`, plus impact SFX;
  - copy `StateFlags` bit3 to the actor;
  - adjust `$12` Speed using the other actor and the impact result;
  - adjust animation offsets `$8/$C`;
  - if `AnimState < 0`: compute animation offset from the Y delta, set
    `$2C = |impact|>>3`, `$2E=0`, `$2A = PosZ + $30`, set `ControlFlags` bit0.
- Otherwise: `$2C = Speed>>3`, `$2E=0`, `$2A = PosZ + $30`, set bit0.

## `Race_ApplyCrashImpact`

- Reads a track curve byte into `$A`.
- Skips if `ControlFlags` bit0 is set or `AnimState >= 0`.
- Clamps the animation offset; if `LeanCurve + offset >= ram_FFD33E`, `$34 >= 3`,
  and `ControlFlags` bit4 is clear:
  - `AnimState=0`, `AnimFrame=$FF`, set `ControlFlags` bit4;
  - play the crash SFX (`sub_15538`/related);
  - set `$78=$1E` (hold timer).

## `Race_ApplyFallKnockdown`

- For each actor with `AnimState < 0` and nonzero `PairImpact`:
  - `delta = PairImpact * ram_FF18AC`;
  - `$5C -= delta`;
  - if it underflows: `$5C=0`, set `ControlFlags` bit4, `$54=$11`,
    `AnimState=0`, `AnimFrame=$FF`, play fall SFX (`$F`/`$D`), save shadow.
- The `$5C` value is used as a knockdown/health budget here; its separate role as
  animation tile base still needs a dedicated experiment.

## Fields used

| Offset | Name / role | Evidence |
|---|---|---|
| `+$1C` | previous collision offset | `[static]` R29 |
| `+$2A` | projected Y offset | `[static]` collision/crash |
| `+$2C` | impact scale / speed-loss amount | `[static]` |
| `+$2E` | speed-loss accumulator | `[static]` |
| `+$32` | current collision offset | `[static]` R25 |
| `+$4C/+$4E` | upper/lower collision extents | `[static/dynamic]` R27 |
| `+$54` | `RaceActor_FallState` (`$11` on knockdown) | `[static]` R30 |
| `+$56` | static respawn timer | `[static/dynamic]` R29 |
| `+$5C` | knockdown budget / animation base overlap | `[static]`; role split TODO |
| `+$68/+$69` | control/state bits used by impact/fall | `[confirmed]` combat |

## Dynamic hooks

Existing pair/combat captures (`analysis/capture_pair_*`,
`analysis/capture_combat_*`) cover attack overlap and contact. A focused forced
impact should log `$1C/$2A/$2C/$2E/$54/$5C` at `Race_ApplyCollisionImpact` and
`Race_ApplyFallKnockdown`.

`[dynamic]` Demo pair reached `Race_ApplyCollisionImpact` (`0x14486`):
`a1=$FF252A`, `a2=$FF2EAA`, pre-call `$1C=0`, `$2A=$1C39`, `$2C/$2E=0`,
`$5C=$0500`, `$68=$52`, `$69=$04`. The call is live; post-call
`$2A/$2C/$2E/$54/$5C` values still need a return-breakpoint capture.

## Open points

- Exact damage formula in `Race_ScaleImpactDamage` and the `$5C` dual role.
- Pair-impact edge cases when both actors fall on the same frame.
- Whether `$54=$11` is a generic fall state or a player-specific delay.

# Race speed, gear and curve limits

Scope: `Race_UpdateActorAI`, `Race_UpdateActorSpeedGear`,
`Race_UpdateActorSpeedState`, `Race_UpdateActorSpeedCurve`,
`Race_GetCurveSpeedLimit`.

## Frame path

`Race_UpdateActorAI` applies acceleration before the action handler:

- `$14` is signed acceleration per frame.
- If `ControlFlags` bit3 (off-road) is set, acceleration is reduced by `1/4`
  (`d1 -= d1/4`).
- `Speed += Acceleration * FrameDelay`, clamped to zero.
- `FrameDistance ($26) = Speed * FrameDelay`.

After movement, the action handler chooses one of the speed helpers:

| Handler | Call path | Effect |
|---|---|---|
| `Race_ActorNormalUpdate` | target found | `Race_UpdateActorSpeedCurve` |
| `Race_ActorNormalUpdate` | no target | `Race_UpdateActorRoadSteering`, then curve limit check |
| `Race_ActorNormalVariant` | target found | `Race_UpdateActorSpeedCurve` |
| `Race_ActorFollowPath` | - | `Race_UpdateActorSpeedCurve` + `Race_UpdateActorSpeedGear` |
| `Race_ActorStateCollision` | - | `Race_UpdateActorSpeedCurve` + `Race_UpdateActorSpeedState` |
| `Race_ActorSteer*` | - | road-steering / gear helpers |

## `Race_UpdateActorSpeedGear`

Compares the actor with PlayerA:

- If the actor is not `ram_FF1F2A` and `Speed < Rating`, it goes straight to the
  slowdown branch.
- Computes relative speed (`d6`) and relative X distance (`d7`).
- The ahead/behind branches use the type/gear table `unk_25A10`:
  - `type` selects a per-type record;
  - `gear` indexes words at `+2`, `+E`, `+1A`.
- It sets `ControlFlags` bit1 (accelerate) or bit2 (brake) based on the relative
  speed/distance and curve limit, then calls `Race_UpdateActorSpeedState`.

## `Race_UpdateActorSpeedState`

Order of branches:

1. `ControlFlags` bit7: set acceleration to `$FFEC` and return.
2. `ControlFlags` bit4 and `AnimState != 3`: on-foot helper `sub_13BBC`.
3. Otherwise select the per-type table `unk_25A10` and default acceleration `0`.
4. `ControlFlags` bit0 (collision latch): use a small negative acceleration
   (`$FFFB`).
5. `ControlFlags` bit1: gear up/down using thresholds at `+E`/`+1A`; gear is clamped
   by the type record's first word; acceleration comes from `+2`.
6. `ControlFlags` bit2: subtract `$40`.
7. `ControlFlags` bit1 clear: subtract `5`.
8. `ControlFlags` bit5 (curve): subtract `Curve * $60 >> 16`.
9. `ControlFlags` bit3 (off-road): subtract `Speed>>8` if acceleration is positive;
   force a downshift if the speed is below the current gear threshold.
10. Store the result in `$14`.

`Gear` is an index, not the display gear. In the demo trace it stayed `0` while
the player accelerated to `$2F1F`; the upshift condition is therefore still
unresolved (likely `ControlFlags` bit1 was set only after the sample window or the
player definition's table has a single gear).

## `Race_GetCurveSpeedLimit`

- Base limit: `TrackParam0`, or `TrackParam2` when `ControlFlags` bit3 is set.
- Shift left 3.
- Read a signed curve byte from `Track_CurveBuffer[(X+6)&$FF]`; use its absolute value.
- Scale through `unk_14056[GraphicsIndex]`.
- Divide base by scaled curve; return `$7FFF` when curve = 0, overflow, or negative.

## `Race_UpdateActorSpeedCurve`

Chooses ahead/behind target actors by scanning `Race_FindTargetActor` forward or
backward from the current AI target index, stores the two candidates in
`ram_FF1892/189C`, then applies the selected relative-speed correction. This is the
target-selection layer behind the speed state machine.

## Dynamic trace (`analysis/dumps/actor_speed_gear_ram.bin`)

Captured at `Race_UpdateActorAI` entry for PlayerA, every 10th frame, demo race:

| f | Speed | Accel | Gear | Ctl | St | PosY | 3A | 3C | 4C | 4E | 56 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | `$083C` | `$0022` | 0 | `$42` | `$02` | `$00A0` | 0 | 0 | `$0D` | `$0D` | `$FFFF` |
| 20 | `$1232` | `$0022` | 0 | `$42` | 0 | `$00A0` | `$0003` | 0 | `$0D` | `$0D` | `$FFFF` |
| 50 | `$2333` | `$0012` | 0 | `$42` | `$04` | `$0096` | `$003E` | `$0007` | `$0C` | `$0F` | `$FFFF` |
| 80 | `$2F0D` | `$FFFB` | 0 | `$42` | `$04` | `$0077` | `$0177` | `$000B` | `$0D` | `$0D` | `$FFFF` |
| 120 | `$2F1F` | `$FFFB` | 0 | `$42` | `$04` | `$0018` | `$01C5` | `$0002` | `$0C` | `$0F` | `$FFFF` |

`$32` (`RaceActor_CollisionOffset`) stayed 0 in all samples; it is set only by the
collision/impact path. `$4C/$4E` track collision extents and flip between `$0D/$0D`
and `$0C/$0F`.

## Open points

- Gear remained 0; test a forced accel/shift scenario or inspect the player's
  `unk_25A10` record.
- `$2C/$2E` are curve/scale accumulators and were not part of this trace.
- `$4C/$4E` side-index mapping still needs a forced pair test.

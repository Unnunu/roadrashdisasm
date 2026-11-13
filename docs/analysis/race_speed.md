# Race speed, gear and curve limits (L2 control contract)

> Status note: this page is the durable speed/gear/curve reference. It folds into
> `race_ai.md` after the line-by-line AI pass; until then it stays separate.

Scope: `Race_GetInput`, `Race_GetInputDemo`, `Race_UpdateActorAI` pre-step,
`Race_UpdateActorSpeedGear`, `Race_UpdateActorSpeedState`,
`Race_UpdateActorSpeedCurve`, `Race_UpdateActorRoadSteering`,
`Race_SteerTowardTarget`, `Race_UpdateBikeLean`, `Race_UpdateBikeCurve`,
`Race_UpdateLeanCurve`, `Race_GetCurveSpeedLimit`, `Race_LoadTrackParams`,
`Race_LoadBikeData`.

Status: L2 static and dynamic passes complete (Experiment Pack E2); matrix v4 in
`race_map.md`. No renames applied.

## Input path (`Race_GetInput`, `0xBE56`)

Pad byte is SACBRLDU: bit0 Up, bit1 Down, bit2 Left, bit3 Right, bit4 B,
bit5 C, bit6 A, bit7 Start.

- Left: `steering -= SteeringPower + (steering >= 0 ? ReturnToStraightPower : 0)`.
- Right: `steering += SteeringPower + (steering < 0 ? ReturnToStraightPower : 0)`.
  Note the asymmetry at zero: Left adds the return power at `steering == 0`, Right
  does not (`bmi` vs `bpl` gate). Static first-step values are `$48` (Left) and
  `$30` (Right) with the demo bike block.
- Left is tested before Right, so Left+Right applies Left.
- Neither held: `steering` moves toward zero by `ReturnToStraightPower` (the idle
  path and the "other button" path both do this; neither clamps to zero).
- Steering is clamped to `[-MaxSteering, +MaxSteering]`.
- B sets `$68` bit1 (accelerate); A sets `$68` bit2 (brake); both are cleared when
  the button is released.
- C only suppresses Start handling. Start toggles `Race_ram_State`, sets the pause
  timer (`-1` resume / `$16E` pause), toggles music and latches `ram_FF368E=1`
  until a completely idle pad clears it.

`Race_GetInputDemo` (`0xBE2C`) only ends the demo when either pad returns a
non-zero byte; it writes no steering/control fields.

E2-4 confirmed the mapping dynamically with pad injection at `0xBE6C` (sampled at
`0xC00A`): Left `$04` -> steering `$FA00` (`-$600` after repeated frames), Right `$08`
-> `+$390`, B `$10` -> `$68` bit1 with Speed `$61C`, A `$40` -> `$68` bit2 with
Speed 0, release clears both bits. See `analysis/notes/L2b_e2b2_trace.txt`.

## On-foot branches (gated by `$68` bit4 and `$6E == 3`)

`Race_HandleInputOnFoot` / `Race_AnotherInputOnFoot` write `$08`, `$12`, `$22`,
`$26` and `$69` bit3 (direction/reverse). The pad is used only for the player:
A stops (`$26=0`, `$22=0`), otherwise `Race_AnotherInputOnFoot` maps Left/Right
to turn `$08` and Up/Down to `$12`/`$69` bit3; `sub_11268`/`sub_112C8` normalize
the turn vector through `unk_7DCA8`.

## `Race_UpdateActorAI` pre-step (`0x10E66`)

Per actor, before the action handler:

- `$14` is signed acceleration per frame.
- If `$68` bit3 (off-road): `$14 -= $14/4` (arithmetic, so `3/4` of the value).
- `Speed ($12) += $14 * FrameDelay`, clamped at zero.
- `FrameDistance ($26) = Speed * FrameDelay`.

After movement the action handler chooses a speed helper (table below). The
player path additionally calls `Race_UpdateBikeLean` before `Race_UpdateActorAI`
and `Race_UpdateActorSpeedState` at `Race_Update` step 4.

| Handler | Call path | Effect |
|---|---|---|
| `Race_ActorNormalUpdate` | target found | `Race_UpdateActorSpeedCurve` |
| `Race_ActorNormalUpdate` | no target | `Race_UpdateActorRoadSteering`, then curve limit check |
| `Race_ActorNormalVariant` | target found | `Race_UpdateActorSpeedCurve` |
| `Race_ActorFollowPath` | - | `Race_UpdateActorSpeedCurve` + `Race_UpdateActorSpeedGear` |
| `Race_ActorStateCollision` | - | `Race_UpdateActorSpeedCurve` + `Race_UpdateActorSpeedState` |
| `Race_ActorSteer*` | - | road-steering / gear helpers |

## `Race_UpdateActorSpeedState` (`0x13A92`)

Branch order; the result is stored in `$14`:

1. `$68` bit7: `$14 = $FFEC` (`-20`, finish deceleration), return.
2. `$68` bit4 and `$6E != 3`: `sub_13BBC` (`$14 = -64`, or `-5` when bit0 is set).
3. Select `unk_25A10[$16]`; default `$14 = 0`.
4. `$68` bit0 (collision latch): `$14 = $FFFB` (`-5`).
5. `$68` bit1: gear logic (below), `$14 = +2[gear]`.
6. `$68` bit2: `$14 -= $40`.
7. `$68` bit1 clear: `$14 -= 5`.
8. `$68` bit5: `$14 -= (Curve * $60) >> 16` (unsigned; `$3E` from BikeCurve).
9. `$68` bit3: if `$14 >= 0`, `$14 -= Speed>>8`; a negative result runs the
   downshift test.
10. Store `$14`.

Gear logic (record layout is in `race_data_tables.md`):

- `d3 = record +E[gear]` (upshift threshold for the current gear).
- If `Speed >= d3` and `gear < record word0` (max gear): `gear++`.
  At max gear the code jumps to `$FFFB` instead of using `+2[gear]`.
- Downshift test: if `gear > 0` and `Speed < record +1A[gear]`, `gear--`.
- `$14 = record +2[gear]` (per-gear acceleration) before the bit2/bit5/bit3
  adjustments.

E2-1 confirmed the word width and threshold layout dynamically. It also exposed a real
same-call oscillation: the upshift test uses `+E[old]`, then the downshift test uses
`+1A[new]` in the same call. When `+E[old] <= Speed < +1A[new]` the routine increments
and immediately decrements the gear (observed at Speed `$1882`: 1->2 with `$1838`, then
2->1 with `$1BBC`). The demo player therefore stays at low gear until Speed exceeds the
next downshift threshold. At max gear (gear == record word0) the upshift branch jumps to
`$FFFB`; forced Speed `$2F00` produced gear 5 == max 5 and `$14 = $FFFB` (-5).

`Race_UpdateActorSpeedGear` (`0x131EE`) is the AI decision that sets bit1/bit2
before calling the state machine: it compares `Speed` and X against `RacePlayerA`,
uses `Rating` and the curve limit, and uses the same `unk_25A10` record for
`+2[gear]`. `Race_ActorStateCollision`/`Race_ActorNormalUpdate` force bit2 when
`$68` bit5 (curve active) is set.

## `Race_UpdateActorSpeedCurve` / `Race_SteerTowardTarget`

`Race_UpdateActorSpeedCurve` (`0x13422`) scans target buckets forward/backward
from the current target index (`Race_FindTargetActor`, `ram_FF1B46` ratio) and
keeps the two candidates in `ram_FF1892/ram_FF189C`. It selects the smaller
distance/speed ratio and calls `Race_SteerTowardTarget`; success sets `$68` bit1
(accelerate). If both candidates fail, it sets `$68` bit2 (brake). It does not
call `Race_UpdateActorRoadSteering`.

`Race_SteerTowardTarget` (`0x13892`) reads the `unk_12D0A` Y-offset table for the
bucket, subtracts `$30`, scales by `(Speed>>8) * (ram_FF1B46>>1)`, and writes
`$46` (signed) plus `$69` bit2. `Race_UpdateActorRoadSteering` (`0x1384C`) is the
same idea toward the road center when no target exists, using the
`$280`/speed/`|offset|` term.

## Lean / curve chain

`Race_UpdateBikeLean` (`0x13EA0`, player only, normal `$6E`):

```
$42 = sign(steering) * |steering| * ram_FF1AAA
      / ((ram_FF1AA6>>3) * (Speed * ram_FF1AB4 >> 8))
```

Zero when `Speed == 0` or the steering quotient is zero.

E2-2 forced `RaceBike_ram_CurrentSteering` to `+$600` and `-$600` at `0x13EA0` and
sampled the `$0C` store at `0x113D8`: `+$600` gave `$42=+$DFB`, `$0C=+$B5`;
`-$600` gave `$42=-$293`, `$0C=-$5B`. The sign follows steering and
`$0C = (FrameDistance>>8)*$42>>8` matched every sample.

`sub_113CA` (`0x113CA`, player/normal path) then:

```
$0C = (FrameDistance>>8) * $42 >> 8            ; curve step
$08 = $0C (when $6E is normal); $22/$00 updated from the curve term
```

(`sub_113A4` is the AI variant: `$22 = (FrameDistance>>8) * $08 >> 8`,
`$00 += $22`; `$08` here is the movement/animation side step.)

`Race_UpdateBikeCurve` (`0x13EFA`):

```
d0 = |$08|; if DemoMode != 0 or actor != PlayerA: d0 = |$08| * $200 >> 8
d1 = Speed * ram_FF1AB2 >> 8
d0 = d0 * d1 >> 3
limit = $78 timer != 0 ? word_14742 ($4CC2)
      : ($68 bit5 ? (bit3 ? TrackParam3 : TrackParam0)
                  : (bit3 ? TrackParam2 : TrackParam0))
if d0 < limit: clear $68 bit5, $3E = $40 = 0
else:          $3E = (limit<<8) / (d0>>8), set $68 bit5
```

`$78` is zeroed at actor creation and decremented here. R30 found its writers in the
fall handlers (`sub_14456` sets `$78`, `sub_1446E` sets `$1E`), so the `word_14742`
branch is reachable during a fall `[static]`.

E2-3 sampled the on-road path: `d0 = $5EC..$C2F` against TP0 `$E646`, so the routine
always took the `CLR` branch. Forcing `d1=$100` at `0x13FB0` reached the limit store and
confirmed `$3E = (limit<<8)/(d0>>8)` (`$2AAA`, `$3333`, `$4000` for successive samples)
plus `$68` bit5. TP2/TP3 selection remains `[static]`: the bit3/bit5 tests at
`0x13F96`/`0x13F78` choose `TrackParam2`/`TrackParam3`.

`Race_UpdateLeanCurve` (`0x1406A`, race_anim_audio) is called from
`sub_113A4`/`sub_113CA` only while `$68` bit5 is set:

```
ram_FF3042 = (d0 * $3E) >> 16                     ; signed
$40 = (d0 * ((($10000 / $3E) - 1)) * $140) >> 8  ; sign-preserving
```

## `Race_GetCurveSpeedLimit` (`0x13FE6`)

```
base = ($68 bit3 ? TrackParam2 : TrackParam0)
curve = |signed low byte of Track_CurveBuffer word [((X>>16)+6) & $FF]|
limit = (base<<3) / ((curve * unk_14056[$75]) >> 8)
```

Zero curve, DIVU overflow, or a negative quotient returns `$7FFF` (no limit).
`unk_14056` is a 10-word scale table indexed by `$75` (GraphicsIndex).

## Demo trace correction (gear)

The old trace printed `gear` as the **low byte** of the word at `$18`, which is
always `0` for gear values 0..5. The `actor_speed_gear_ram.bin` and
`actor_offroad_left_ram.bin` dumps show `RaceActor_Gear = 5` at Speed `$2F1F`/`$2CEE`.
So the earlier "demo stayed in gear 0" question was a read-width artifact.

E2-1 re-ran the demo with a word read: at low speed the gear oscillates 1<->2 in the
same call (see the gear-logic paragraph above), but it climbs once Speed passes each
downshift threshold; the max-gear `-5` branch then matches the `$FFFB` in the dump.

For the demo bike (id 0 -> `unk_25B50[0]` -> `ActorBikeRecord_2`):

- max gear word0 = `5`;
- upshift thresholds `+E..+18` = `$125C,$1838,$1E78,$23F0,$28A0,$2EE0`;
- downshift thresholds `+1A..+24` = `$0,$1518,$1BBC,$20D0,$25E4,$2A30`;
- the demo reached `Speed = $2F1F`, enough for gear 5 (`+E[4]=$28A0`);
- at max gear the state machine forces `$14 = $FFFB` (`-5`), matching the trace.

E2-1 only needs to re-read `$18` as a word to confirm this.

## Field/flag ownership (see `race_map.md` for the full matrix)

- `$12` Speed, `$14` Acceleration, `$16` Type, `$18` Gear — L2.
- `$42` Lean, `$3E` Curve, `$40` LeanCurve, `$46` CurveDirection — L2.
- `$68` bit1 accelerate, bit2 brake, bit3 off-road, bit5 curve active — L2;
  bit0 collision, bit4 fall/on-foot, bit6 AI active, bit7 finish — L3/L4/L5.
- `$69` bit2 steer/curve direction, bit3 direction sign — L2 set; other bits
  combat/fall (L4).

## Open points

- E2 is closed: E2-1..E2-5 are `[confirmed]` except TP2/TP3 selection, which remains
  `[static]` (only TP0 was sampled). `U-0011` is closed with spawn `d4=0`.
- `$40` (LeanCurve) was not sampled in E2-2/E2-3; its formula remains `[static]`.
- `$2C/$2E` curve/scale accumulators are L1/L4 scope.
- Exact reader of `$46` outside L2 is L3 movement/steer handler scope.

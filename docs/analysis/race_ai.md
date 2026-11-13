# Analysis: `src/race/race_ai.asm` (on-foot input, actor AI, bike lean/curve)

- **Module:** on-foot player/AI input, actor AI loop, static actor AI, bike lean/curve,
  curve speed limit, actor sprite setup, movement/collision helpers
- **ROM range:** `0x010E00`–`0x014055`
- **Status:** analyzed (roles/flow, target buckets/scan, movement/speed; impact handoff
  documented; gap functions `0x1131A`-`0x13DDF` disassembled in R30; L3 static
  contracts and E3 dynamics: candidate bucket/list, profile slot/budget, dispatcher
  branches, per-level budget, static respawn indexing)
- **Source:** `src/race/race_ai.asm`
- **Related:** `docs/analysis/combat.md` (fist/AI attack state), `docs/analysis/race.md`, `docs/analysis/race_ai_road.md`,
  `docs/analysis/race_physics.md`, `docs/modules/race_ai.md`, `docs/ram-map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `sub_10E00`/`unk_10E3E`/`sub_10E66` | `0x10E00`+ | Actor setup + `Race_UpdateActorAI`. |
| `Race_UpdateActorAI` | `0x10E66` | Main actor AI loop (player/opponents). |
| `Race_AdvanceActorProgress` | `0x1103A` | AI movement helper. |
| `Race_HandleInputOnFoot` | `0x110AE` | On-foot input/AI (player A). |
| `Race_AnotherInputOnFoot` | `0x111FA` | On-foot input/AI (other actor/pad). |
| `sub_11268`/`sub_112C8`/`sub_113A4`/`sub_113CA`/`Race_UpdateActorX`/`sub_115C6`/`Race_UpdateActorMovement`/`Race_UpdateActorShadow`/`Race_SaveActorShadow`/`Race_UpdateActorFallMovement`/`Race_ApplyCrashImpact` | `0x11268`+ | Turn/movement/lean helpers. |
| `sub_11C44`/`sub_11CC8`/`sub_12070`/`sub_1218C`/`sub_123A8`/`sub_12414`/`Race_UpdateActorPairCollision` | `0x11C44`+ | Opponent/AI logic. |
| `Race_ClearActorOnFootFlags`/`Race_UpdateStaticActors`/`Race_InitExtraStaticActor`/`Race_UpdateExtraStaticActor` | `0x1281E`+ | Static/police actor AI. |
| `sub_12...`/`sub_13...` | `0x12A88`+ | Road/actor movement, collision helpers. |
| `unk_12D0A`/`Race_ActorActionTable` | `0x12D0A`/`0x12D16` | 6-word offset table + 99-entry actor action code-pointer table. |
| `Race_ActorStateCollision`/`Race_ActorFollowPath`/`Race_ActorNormalUpdate`/`Race_ActorNormalVariant`/`Race_ActorRecovery` | `0x12FE4`+ | Actor action handlers (state/curve/recovery). |
| `Race_ClampActorY` | `0x13130` | Y clamp + `$46` sign flip (shared `Race_StaticActionTable` handler). |
| `Race_SetupActorSprite` | `0x13746` | Actor sprite/field setup (spawn). |
| `Race_UpdateBikeLean` | `0x13EA0` | Steering/lean from Speed/Steering. |
| `Race_UpdateBikeCurve` | `0x13EFA` | Bike curve/lean `$3E/$40` from speed/steering. |
| `Race_GetCurveSpeedLimit` | `0x13FE6` | Curve speed limit from `Track_CurveBuffer`/`unk_14056`. |

## Gap functions (`0x1131A`-`0x13DDF`, R30)

The remaining `dc.b` blobs in this range are now instructions/labels (byte-exact).
Roles below are inferred statically; names stay `sub_XXXX` until dynamic confirmation.

| Function | Address | Role | Evidence |
|---|---|---|---|
| `sub_1131A` | `0x1131A` | Shadow-follow: shadow PosY gap -> signed Y velocity; X via `Race_UpdateActorX`/fall helper. No static caller (dead twin of `Race_HandleInputOnFoot`). | `[static]` `U-0012` closed |
| `sub_11A5E` | `0x11A5E` | Integrates X along `Track_CurveBuffer`, updates road Y/curve offsets and `$2`; `$E/$10` are write-only. | `[static]` `U-0013` closed |
| `sub_12B2A` | `0x12B2A` | Close-attack reach from `unk_12BCC`; else `Race_GetAttackerReach`. | `[static]` |
| `sub_133F0` | `0x133F0` | Target-PosY delta -> signed `$46`; sets `$69` bit2. | `[static]` |
| `sub_135E8` | `0x135E8` | Clears `$68` bit1, sets bit2 (accelerate). | `[static]` |
| `sub_13704` | `0x13704` | `ram_FF1B46 = abs(ram_FF1EAE-X) / adjusted Speed`. | `[static]` |
| `sub_13A5C` | `0x13A5C` | Far respawn: `X=PlayerProgress-$1F8000`, clears/updates fall flags. | `[static]` |
| `sub_13D44` | `0x13D44` | Scans track-object records; type-table filter -> `Race_SteerTowardTarget`. Record/type-table fields decoded. | `[static]` `U-0014` closed |

Dead blocks kept byte-exact: `$11F54` (`bra.w .loc_1202E` inside `sub_11CC8`) and
`$139AC-$13A17` (inside `sub_138CE`; updates a respawn timer and calls `sub_13A5C`).

Tables: `unk_12168` (9 handler pointers, unreferenced dead data `U-0016` closed),
`unk_12B7C` (80-byte extent buckets) + `unk_12BCC` (6 close-attack reaches),
`unk_13A1A` (6 per-level words).
See `race_data_tables.md`.

## Flow

`Race_Update` runs `Race_UpdateActorAI`: it marks the player A `$68` bit6 and walks
`ram_FF1A08`. For the player A it handles the on-foot case
(`Race_HandleInputOnFoot` when `$68` bit4 and `$6E==3`), otherwise the normal input/AI
(`sub_113CA`/`sub_13EFA`, `Race_UpdateActorX`, `Race_UpdateActorFallMovement`). Opponents use
`Race_UpdateActorAI`/`Race_AdvanceActorProgress`/`sub_113A4`/`Race_UpdateActorMovement`. Static/police actors are
walked from `Race_StaticActorList` by `Race_UpdateStaticActors`
(`unk_25A10`, `sub_113A4`/`Race_UpdateActorMovement`/`Race_UpdateActorFallMovement`, `Race_BuildTargetCandidates`/`sub_12C9A`/
`sub_13DE0`).

## L3 static contracts (loop, targets, dispatch)

L3-relevant slice of the `Race_Update` order:

```
sub_1383E                 ; clear ram_FF178A candidate counts
Race_UpdateActorAI        ; per-actor speed/move; Race_SetupActorSprite adds candidates
Race_UpdateStaticActors   ; static actors move; Race_BuildTargetCandidates adds them
sub_138CE                 ; static respawn/profile assignment
sub_11C44..sub_123A8      ; collision/impact helpers (L4)
Race_UpdateNearestOpponent
Race_UpdateActorActions   ; profile selection + action handler
Race_UpdateStaticActions  ; static profile handler
Race_UpdateNearestTarget
```

The action pass runs after the candidate buckets are complete, so a handler's
`Race_FindTargetActor` sees the current frame's candidates.

| Function | Inputs | Outputs / side effects | Evidence |
|---|---|---|---|
| `Race_UpdateActorAI` (`0x10E66`) | `ram_FF1A08` list, `FrameDelay`, pad | Applies `$14` (off-road `>>2`), `Speed += $14*FrameDelay`, `$26 = Speed*FrameDelay`; player normal/on-foot vs AI branches; road-band clamp `$00/$22/$30` and `$68` bit3; `Race_SetupActorSprite`; crash/fall/shadow helpers. Does **not** run action handlers. | `[static]` + E1/E2 |
| `Race_AdvanceActorProgress` (`0x1103A`) | `a1`, `$26`, `d1` (PosZ) | `$1A = $30`, `$1C = $32`, `$1E = X`, `X += $26`; when the X high word reaches `RaceTrack_Data1` and bit7 is clear, sets finish latch `$68` bit7 and `$62` snapshot; clears bit4/bit0, `AnimState = $FF`, `$32/$2E/$2C = 0`; `sub_12BD2`. | `[static]` |
| `sub_1383E` (`0x1383E`) | - | Clears the six `ram_FF178A` byte counts (8 bytes incl. padding). Called once per frame before `Race_UpdateActorAI`. | `[static]` |
| `Race_SetupActorSprite` (`0x13746`) | `a1`, ambient `d4` | `AnimIndex = clamp(($30>>6)+3, 0, 5)`; appends the actor to that bucket and, when `d4 != 0`, the `$30 +- d4` buckets. E1/E2 saw `d4 = 0` on every path, so only the base bucket is produced in practice. | `[static]` + E1/E2 |
| `Race_BuildTargetCandidates` (`0x137E4`) | `a1` static actor | Sets `AnimIndex` to 0 (`$30 >= 0`) or 3 (`$30 < 0`) and appends to three consecutive buckets (0..2 or 3..5). Used by `Race_UpdateStaticActors`. | `[static]` |
| `Race_AddTargetCandidate` (`0x13812`) | `a1`, `d0` bucket | `ram_FF178A[d0]++`; stores `$71` at `ram_FF1792 + d0*16 + old_count`. Clobbers `d0/d1/a0`. | `[static]` |
| `Race_FindTargetActor` (`0x135F6`) | `d0` bucket | Sets `ram_FF1B46 = $F0`, scans the bucket, returns `a2` = best candidate or `$FFFFFFFF`. | `[static]` |
| `Race_ScanTargetDistance` (`0x13626`) | `a1`, `d0` bucket, `d1` count | Skips self (`$71`); resolves `< $10` via `Race_ActorList`, else `index-$10` via `Race_StaticActorList`; signed relative speed from `$12`/`StateFlags` bit3; requires a positive relative speed and `X2-X1 > 0`; keeps `min((X2-X1)/relSpeed)` in `ram_FF1B46`. | `[static]` |
| `Race_UpdateActorSpeedCurve` (`0x13422`) | `a1`, `d0` start bucket, `a2` last target | Scans buckets outward from the start (down then up when `$30 >= 0`, up then down when `$30 < 0`); if the last target's `$71` is `$10/$11` it starts at bucket 2/5; picks the smaller of the two ratios; `Race_SteerTowardTarget` + `$68` bit1, or `$68` bit2 when none. Does not call road steering. | `[static]` |
| `Race_SteerTowardTarget` (`0x13892`) | `a1`, `d0` bucket | `$46 = ((unk_12D0A[d0]-PosY)<<16) / (Speed>>8 * (ram_FF1B46>>1)) >> 8`; sets `$69` bit2. | `[static]` |
| `Race_UpdateActorRoadSteering` (`0x1384C`) | `a1`, `d0` bucket | `$46 = ((unk_12D0A[d0]-PosY)<<16) / ((Speed * |offset| * $280)>>16) >> 8`; sets `$69` bit2. | `[static]` |
| `sub_133F0` (`0x133F0`) | `a1`, `d0` target PosY | Same shape as `Race_SteerTowardTarget` from a raw target Y; sets `$46`, `$69` bit2. | `[static]` |
| `Race_UpdateActorActions` (`0x12EA2`) | actor list, `ram_FF1A68`, profile tables | Outside demo skips PlayerA; stamina regen `$5C`: add `FrameDelay` while `< ram_FF18A8($500)`, else store graphics `+$E` (page max); recycles actors below `-18` or at/above `+34` relative to PlayerA X; selects profile slot or slot+4; calls the handler. | `[confirmed]` U-0017 (E-stamina) + earlier demo traces |
| `Race_DispatchActorAction` (`0x16458`) | `a1`, `a4` = profile action-1 slot, `ram_FF1A68`, `Race_ram_NearestActor` | Decrements `$5A`; `$69` bit4 -> `Race_UpdateAttackPhase`; finds a target; `4(a4)` (action2) for a non-player target, `8(a4)` (action3) for far/no-close, `C(a4)` (action4) for close/final. | `[static]` + earlier forced traces |
| `Race_UpdateStaticActions` (`0x13106`) | `Race_StaticActorList` | Calls `Race_StaticActionTable[$74].handler` for every static actor (all entries currently point at `Race_ClampActorY`). | `[static]` |
| `sub_138CE` (`0x138CE`) | static list, `Menu_ram_PlayerLevel`, `Rand_NextWord` | Assigns a respawn timer, palette, PosY (`$70`/`-$70`), `$74` = random nibble, initial Speed and `$46` from `Race_StaticActionTable`; respawns via `sub_13A26` (+$208000) or the dead-path intent `sub_13A5C` (-$1F8000). | `[static]` R30 |
| `Race_ClampActorY` (`0x13130`) | `a1` | Clears `$68` bit6 beyond `$210000` from player progress; otherwise clamps `$30` to `$37..$A9` on-road or `-$57..-$C9` off-road (StateFlags bit3) and flips `$46` when clamped. | `[static]` |

Target-bucket model:

```
bucket b        = clamp(($30>>6)+3, 0, 5)          ; SetupActorSprite
bucket offsets  = -$A0,-$60,-$20,+$20,+$60,+$A0    ; unk_12D0A
count / list    = ram_FF178A[b] / ram_FF1792 + b*16
```

Players and opponents register through `Race_SetupActorSprite`; active static actors
register through `Race_BuildTargetCandidates`. Buckets are Y bands, not actor types.
The bucket counts are cleared once per frame by `sub_1383E`; the list bytes are
overwritten on append.

`[dynamic]` E3 (`capture_L3_a.gdb`) confirmed the append: `$71` is stored at
`ram_FF1792[bucket*16+count]` and `ram_FF178A[bucket]` advances. The demo produced
bucket 3 at `$30=$0020` and bucket 5 at `$30=$00A0`, matching
`clamp(($30>>6)+3,0,5)`.

`Race_StaticActionTable` (16 entries, each `dc.l handler`, `dc.w speed`,
`dc.w Y-offset`): every handler is `Race_ClampActorY`. `sub_138CE` writes the speed
and Y-offset pair into `$12`/`$46` on respawn; `Race_UpdateStaticActions` reads only
the handler pointer. The pairs repeat a small set:

| Index | Speed | Y-offset | Index | Speed | Y-offset |
|---|---|---|---|---|---|
| 0 | `$1770` | `+8` | 8 | `$1770` | `-8` |
| 1 | `$1B58` | `+$10` | 9 | `$1964` | `-$11` |
| 2 | `$1964` | `+$C` | 10 | `$1770` | `+8` |
| 3 | `$1770` | `-8` | 11 | `$1B58` | `+$10` |
| 4 | `$1B58` | `-$11` | 12 | `$1964` | `+$C` |
| 5 | `$1770` | `+8` | 13 | `$1770` | `-8` |
| 6 | `$1B58` | `+$10` | 14 | `$1B58` | `-$11` |
| 7 | `$1964` | `+$C` | 15 | `$1770` | `-$11` |

`[dynamic]` E3 (`capture_L3_c.gdb`) forced the respawn branch and observed `$74`
select `Race_StaticActionTable[$74]`; the written `$12`/`$46` matched that entry's
speed/Y-offset (`$01 -> $1B58/$0010`, `$07 -> $1964/$000C`, `$0D -> $1770/$FFF8`,
`$0E -> $1B58/$FFEF`). The expiry path reached `sub_13A26`.

## Bike lean / curve (L2 contract)

Canonical formulas and the table decode are in `race_speed.md` and
`race_data_tables.md`; this section records the code-level chain.

`Race_UpdateBikeLean` (`0x13EA0`, player only, normal `$6E`):

```
$42 = sign(steering) * |steering| * ram_FF1AAA
      / ((ram_FF1AA6>>3) * (Speed * ram_FF1AB4 >> 8))
```

zero when `Speed == 0` or the steering quotient is zero.

`sub_113CA` (`0x113CA`, player/normal path) turns `$42` into the curve step
`$0C = (FrameDistance>>8) * $42 >> 8`, copies it to `$08` on a normal animation
state, and updates `$22`/`$00` from the curve term. `sub_113A4` is the AI variant
(`$22 = (FrameDistance>>8) * $08 >> 8`, `$00 += $22`).

`Race_UpdateBikeCurve` (`0x13EFA`) derives `$3E/$40` and `$68` bit5:

- returns if `$68` bit0 is set;
- `d1 = Speed * ram_FF1AB2 >> 8`; `d0 = |8(a1)|`;
- for demo/non-player, `d0 = d0*$200 >>8`; then `d0 = d1*d0 >>3`;
- limit select: `$78 != 0` -> `word_14742`; `$78 == 0` and `$68` bit5 set ->
  `TrackParam3` (bit3) or `TrackParam0`; `$78 == 0` and bit5 clear ->
  `TrackParam2` (bit3) or `TrackParam0`;
- if `d0 < limit`, clear bit5 and zero `$3E/$40`; otherwise
  `$3E = (limit<<8)/(d0>>8)` and set bit5.

`$78` is zeroed at actor creation and decremented here; the R30 fall handlers
`sub_14456`/`sub_1446E` set it to `$78`/`$1E`, so the `word_14742` branch is
reachable during a fall `[static]`.

`Race_UpdateLeanCurve` (`0x1406A`, race_anim_audio) runs from
`sub_113A4`/`sub_113CA` only while `$68` bit5 is set and writes
`ram_FF3042 = (d0*$3E)>>16` and
`$40 = (d0*((($10000/$3E)-1))*$140)>>8` (sign-preserving).

`Race_GetCurveSpeedLimit` (`0x13FE6`):

```
limit = (($68 bit3 ? TrackParam2 : TrackParam0)<<3)
        / ((|signed low byte of Track_CurveBuffer[((X>>16)+6)&$FF]|
            * unk_14056[$75])>>8)
```

zero/overflow returns `$7FFF` (no limit).

`[dynamic]` L1 forced steering (`RaceBike_ram_CurrentSteering=±$600`) gave
`RaceActor_Lean=$FFB7`/`$0049` (signed); `$3E/$40` stayed zero in that snapshot
because the curve limit was not reached. E2-2 forced `±$600` again and confirmed the
sign and `$0C=(FrameDistance>>8)*$42>>8` at the `0x113D8` store. E2-3 forced the limit
branch and confirmed `$3E=(limit<<8)/(d0>>8)` and `$68` bit5; the natural on-road run
selected `TrackParam0`. See `analysis/notes/L2b_e2a_trace.txt`,
`L2b_e2b_trace.txt`.

## Target candidate selection

`sub_1383E` clears the six bucket counts at the start of the frame. Candidate
registration then happens from two places:

- normal actors: `Race_SetupActorSprite` (inside `Race_UpdateActorAI`) appends up to
  three Y-band entries per actor;
- active static actors: `Race_BuildTargetCandidates` appends three consecutive
  Y-band entries (`0..2` or `3..5`) per static actor.

- `ram_FF178A` = byte counts for buckets 0..5.
- `ram_FF1792` = six 16-byte buckets of actor-index bytes.
- `Race_AddTargetCandidate` appends `$71` to bucket `d0`; secondary actors use
  indices `$10+` and resolve through `Race_StaticActorList`.

`Race_FindTargetActor(d0)`:

1. Read `count = ram_FF178A[d0]`; zero -> no target.
2. Initialize `ram_FF1B46 = $F0`.
3. Scan the bucket; skip self (`$71` match).
4. Convert index `< $10` through `Race_ActorList`, otherwise `Race_StaticActorList`
   with `index-$10`.
5. Compute signed relative speed from `$12` (flip when `$69` bit3 is set) and
   require the candidate to be ahead (`X2-X1 > 0`) with positive relative speed.
6. Store `distance / relative_speed` if it is smaller than the current minimum.
7. Return `a2 = candidate` or `$FFFFFFFF`.

`Race_UpdateActorSpeedCurve` scans buckets forward/backward from the current target
index, keeping the two nearest candidates in `ram_FF1892/ram_FF189C`, then selects the
smaller distance/speed ratio. On success it calls `Race_SteerTowardTarget` and sets
`ControlFlags` bit1 (accelerate); if both candidates fail it sets bit2 (brake). It
does **not** call `Race_UpdateActorRoadSteering` (that is the no-target path in
`Race_ActorNormalUpdate` / `Race_UpdateActorSpeedGear`).

`Race_SteerTowardTarget` uses the `unk_12D0A` Y-offset table for the selected bucket,
subtracts the actor Y, scales by speed and the selected distance ratio, and writes
`RaceActor_CurveDirection` plus `StateFlags` bit2. `Race_UpdateActorRoadSteering` is
the same calculation toward the road center when no target exists.

## Actor action dispatch (`0x12D0A-0x131BE`)

- `unk_12D0A` is a 6-word offset table (`FF60,FFA0,FFE0,0020,0060,00A0` = -$A0..$A0).
- `Race_ActorActionTable` is a 99-entry dword table of actor action code pointers. `Race_ActorProfileTable`
  has 20 pointers indexed by `$74` (definition byte1); each points to a starting
  action slot. `Race_UpdateActorActions` calls `(a4)` (action0) or advances `a4 += 4`
  to the dispatcher slot; the full set of `+4` conditions is listed below.
- `Race_DispatchActorAction` is the dispatcher: it uses `4(a4)`/`8(a4)`/`C(a4)` to select the
  action-2/action-3/action-4 handler:
  - target is not `-1` and not PlayerA -> `4(a4)` (action2);
  - no target -> `sub_13D44`, fallback target = PlayerA;
  - target == PlayerA and `a1` is the first opponent or `$69` bit4 set ->
    `C(a4)` (action4);
  - otherwise compare `|4(target)-4(a1)|` with
    `(ram_FF1A68)[0] << 16`; distance >= threshold -> `8(a4)` (action3);
  - below threshold: if `a1 == Race_ram_NearestActor` and `$5A > 0` ->
    action3, else `C(a4)` (action4).

Profile map from the ROM (slot -> actions at `+0/+4/+8/+C`):

| `$74` | Slot | Action 0 (normal) | +4 (dispatcher) | +8 | +C |
|---|---|---|---|---|---|
| 0 | `$12D2A` | `Race_ActorNormalUpdate` | `Race_ActorNormalVariant` | `Race_ActorNormalUpdate` | `Race_ActorNormalUpdate` |
| 1 | `$12D16` | `Race_ActorRecovery` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` |
| 2 | `$12D3A` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerThrottle` |
| 3 | `$12D4E` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerThrottle` |
| 4 | `$12D62` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerThrottle` |
| 5 | `$12D76` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerThrottle` |
| 6 | `$12D8A` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` |
| 7 | `$12D9E` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` |
| 8 | `$12DB2` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` |
| 9 | `$12DC6` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` |
| 10 | `$12DDA` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` |
| 11 | `$12DEE` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` |
| 12 | `$12E02` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorStateCollision` | `Race_ActorSteerThrottle` |
| 13 | `$12E16` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorStateCollision` | `Race_ActorSteerThrottle` |
| 14 | `$12E2A` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorStateCollision` | `Race_ActorSteerThrottle` |
| 15 | `$12E3E` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorStateCollision` | `Race_ActorSteerThrottle` |
| 16 | `$12E52` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorStateCollision` | `Race_ActorSteerRoadCenter` |
| 17 | `$12E66` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorStateCollision` | `Race_ActorSteerRoadCenter` |
| 18 | `$12E7A` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorStateCollision` | `Race_ActorSteerRoadCenter` |
| 19 | `$12E8E` | `Race_ActorNormalUpdate` | `Race_DispatchActorAction` | `Race_ActorStateCollision` | `Race_ActorSteerRoadCenter` |

Action 4 (`a4+$10`, used by `Race_DispatchActorAction`'s final fallback) by profile:
`0 -> Race_ActorNormalUpdate`; `1 -> Race_ActorEvadePlayer`; `2/6/12/16 -> Race_ActorSteerCollide`;
`3/7/13/17 -> Race_ActorPursueAttack`; `4/8/14/18 -> Race_ActorCollideSteer`;
`5/9/15/19 -> Race_ActorAttackIfClose`; `10 -> Race_ActorRandomCombatChoice`; `11 -> Race_ActorProximityReaction`.

The profile pointer is a 5-dword group inside `Race_ActorActionTable`: `+0` action0,
`+4` action1 (the dispatcher slot), `+8` action2, `+C` action3, `+10` action4.
`Race_UpdateActorActions` calls `(a4)` (action0) or `4(a4)` (action1 =
`Race_DispatchActorAction`); the dispatcher then chooses `4(a4)`/`8(a4)`/`C(a4)`,
which are the profile's action2/action3/action4 entries. The columns above are the
`+0/+4/+8/+C` slots; the separate "Action 4" list is the `+10` slot.

### `$74` assignment and behaviour families

| Source | `$74` value |
|---|---|
| Player definition (`$4B`) byte1 | 0 |
| Opponent definition byte1 | 1..18 (see pages below) |
| `Race_CreateActors` static init | 0 |
| `sub_138CE` static respawn | `(rand & $F0) >> 4` -> 0..15 |

No other writer exists, so `$74` is fixed for an actor's lifetime. Profiles 17 and
19 are not reachable from any writer (the definition pages stop at 18 and the static
nibble stops at 15); profile 0 is the player (and the static pre-respawn default).

Per-level opponent profile assignment (`Race_ActorDefinitionTable` pages, definition
order; level 1 starts at id 0, each page is 15 entries):

| Level | ids | `name=profile` in definition order |
|---|---|---|
| 1 | 0-14 | O'Leary 1, Viper 11, Shiva 7, Natasha 16, Slater 9, Biff 18, Rex 6, Lester 11, Rude Boy 6, Grubb 8, Gunther 6, Sid 6, Axle 9, Hammer 8, Dread 8 |
| 2 | 15-29 | O'Rourke 1, Hoghide 4, Ikira 2, Natasha 16, Butch 3, Angel 14, Biff 18, Viper 11, BroomHelga 7, Axle 9, Rex 6, Lester 11, Shiva 7, Slater 9, Dread 8 |
| 3 | 30-44 | Flynn 1, Chip 2, Natasha 6, Sergio 5, Ikira 2, Spike 10, Zippy 4, Butch 2, Dread 8, Slater 9, Hoghide 14, Angel 14, Otis 10, Biff 8, Viper 11 |
| 4 | 45-59 | O'Shea 1, Helldog 14, Sergio 15, Chip 2, Natasha 16, Butch 13, Ikira 2, Bob 6, Otis 10, Biff 18, Viper 11, Zippy 4, Hoghide 4, Luna 14, Spike 6 |
| 5 | 60-74 | O'Connor 1, Chip 2, Helldog 14, Natasha 16, Sergio 15, Killjoy 14, Ikira 2, Bob 6, Viper 11, Zippy 4, Ollie 4, Luna 14, Hoghide 4, Spike 16, Butch 6 |

The profiles collapse into five static behaviour families (all action0 =
`Race_ActorNormalUpdate`, action1 = `Race_DispatchActorAction`, except profile 1):

| Profiles | action2 (`+8`) | action3 (`+C`) | action4 (`+10`) |
|---|---|---|---|
| 1 | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` | `Race_ActorEvadePlayer` (leader/recovery) |
| 2-5 | `Race_ActorFollowPath` | `Race_ActorSteerThrottle` | SteerCollide / PursueAttack / CollideSteer / AttackIfClose |
| 6-9 | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` | same four combat actions |
| 10 | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` | `Race_ActorRandomCombatChoice` |
| 11 | `Race_ActorFollowPath` | `Race_ActorSteerRoadCenter` | `Race_ActorProximityReaction` |
| 12-15 | `Race_ActorStateCollision` | `Race_ActorSteerThrottle` | same four combat actions |
| 16-19 | `Race_ActorStateCollision` | `Race_ActorSteerRoadCenter` | same four combat actions |

`Race_ActorNormalVariant` is the `+4` slot of profile 0. Profile 0 is the player
(and the static pre-respawn default); the player always takes the base slot and
static actors use `Race_StaticActionTable`, so this action-1 slot is not reachable
through `Race_UpdateActorActions` (static dead-table entry).

Action-profile budget: `ram_FF1A96` is loaded in `Race_LoadBikePalette` from
`unk_259B6[level-1]` = `[2,3,3,3,4]`; `ram_FF1A98` is reset to 0 at the start of
`Race_UpdateActorActions`. An actor takes the dispatcher slot (`a4 += 4`) when it is
Player B (`ram_FF1F2A`), is `Race_ram_NearestActor`, or has `Rating <= PlayerA Speed`
while `ram_FF1A98 < ram_FF1A96`; every `+4` selection increments `ram_FF1A98`
(including the nearest actor and Player B). The player, a Natasha-rivalry actor, and actors whose rating exceeds the
player's speed stay on action0.

- `[dynamic]` Demo trace at `0x12FD8` (before `jsr (a6)`) observed the normal path
  for every active actor: player `$74=0` -> `$12D2A`/`Race_ActorNormalUpdate`; opponents with
  `$74=6/8/9` -> `$12D8A/$12DB2/$12DC6` and also `Race_ActorNormalUpdate`.
- `[dynamic]` Forcing PlayerA Speed to `$3000` and `ram_FF1A96=$FFFF` at
  `Race_UpdateActorActions` entry made profiles `6/8/9` advance to slot+4 and call `Race_DispatchActorAction`
  (`$12D8E/$12DB6/$12DCA`), confirming the dispatcher path. A follow-up trace at
  `0x1651C` saw targets `PlayerA`, `$5A=0`, profiles 6/8/9.
- `[dynamic]` Forced branch checks confirmed all three dispatcher paths: setting a
  non-player target selected `0x164A2` (action2), setting `NearestActor=a1` and
  `$5A=1` selected `0x16510` (action3), and setting `$69` bit4 selected
  `0x16518` (action4).
- `[dynamic]` A handler-entry trace with forced speed showed the profile paths in
  action: profile `6` entered `16624`/`165E0`, profile `8` entered
  `13004`/`16612`, and profile `9` entered `166B0`/`16612`. This matches the
  profile/action4 table and confirms that action2/3/4 are live code, not just
  unreachable table entries.
- `[dynamic]` E3 (`capture_L3_a2.gdb`, PlayerA Speed forced to `$7FFF`): profiles
  `6`/`8` took `slot+4` while the actor was `Race_ram_NearestActor` or while
  `ram_FF1A98 < ram_FF1A96`; once the budget was full, non-nearest actors returned to
  the base slot. The counter incremented on every `+4` (nearest included) and never
  exceeded the budget. Profiles 17/19 never appeared.
- `[dynamic]` E3 (`capture_L3_level.gdb`) set `Menu_ram_PlayerALevel` before
  `Race_LoadBikePalette`; the stored `ram_FF1A96` was `[2,3,3,3,4]` for levels 1..5.
- `[dynamic]` E3 (`capture_L3_b2.gdb`) sampled the natural demo: 262 action3 hits
  (`near=0`, nearest mismatch) and 174 action4 hits (`near=1`, `$5A=0`, nearest with
  expired cooldown); action2 had 0 natural hits because every target was PlayerA.
  Forcing a non-player `a2` selected action2 (12 hits), and forcing `d0 >= d6`
  selected the distance-based action3 (6 hits).
- `Race_DispatchActorAction` is entered only after `Race_UpdateActorActions` selects slot+4. In the
  normal demo profiles `6/8/9` stay on `Race_ActorNormalUpdate`; the older trace
  forced PlayerA Speed `$3000` plus `ram_FF1A96=$FFFF` to make the dispatcher reachable.
- Handler roles: `Race_ActorNormalUpdate` normal target/curve update; `Race_ActorNormalVariant` variant
  (profile-0 `+4`, unreachable);
  `Race_ActorRecovery` recovery timer; `Race_ActorStateCollision` state/collision + `Race_UpdateActorSpeedState`;
  `Race_ActorFollowPath` movement/`Race_UpdateActorSpeedGear`; `Race_DispatchActorAction` dispatcher; `Race_ActorSteerRoadCenter/165E0`
  combat actions; `Race_ActorCollideSteer/16624/1662C/16644/1666A/166B0/166DC/166F0` deeper
  combat/action handlers (see `docs/analysis/combat.md`).

## Static actor action table (`Race_StaticActionTable`)

- 16 entries, each `dc.l handler` + `dc.w speed` + `dc.w Y offset`; all currently
  point at `Race_ClampActorY`.
- `Race_UpdateStaticActions` indexes it by `$74 * 8`; `Race_ClampActorY` clamps the actor Y:
  `|4(a1)-Race_ram_PlayerProgress| >= $210000` clears bit6; otherwise computes
  `$30 + ($46*$12 >> 8)*FrameDelay`, clamps on-road `$37..$A9` / off-road
  `-$57..-$C9`, and flips `$46` when clamped.
- The per-entry speed/offset words are not yet assigned; `$74` selects both the
  static profile and its speed/offset pair.

## RAM / fields

Actor fields used here: `$12` Speed, `$14` acceleration (`Speed += $14 * FrameDelay`
after the speed/on-foot gates), `$16` type (indexes `unk_25A10`), `$18` Gear (word;
demo reached 5), `$1C` previous collision offset, `$1E`
previous X, `$22`, `$26` frame distance = `Speed * FrameDelay`, `$30`/`$36/$38`
Y/road, `$3E/$40/$42` lean, `$46` curve direction, `$56` static respawn timer,
`$68` flags (bit1 accel, bit2 brake, bit3 off-road, bit5 curve, bit6 active),
`$69` flags (bit2 steer, bit3 direction), `$6E`,
`$71` index, `$73`, `$75`, `$78` (curve timer armed by `sub_14456`/`sub_1446E`). Data: `Race_ActorShadowTable`/`unk_25A10` actor data,
`unk_10E3E`, `unk_12168`, `unk_12B7C`/`unk_12BCC`, `unk_12D0A`, `unk_13A1A`, `Track_CurveBuffer`,
`Race_ram_TrackParam0`/`Race_ram_TrackParam2`/`Race_ram_TrackParam3`, `word_14742`, `Race_ram_PlayerProgress`/`Race_ram_BestProgress`/`Race_ram_ProgressSnapshotB`, `Race_ram_FrameDelay`/
`CurrentButtons`, `Race_StaticActorList`, `$FF2FAA`, `unk_14056` (race_anim_audio);
`RacePlayerB` is an address bound, not a live concurrent actor in sequential 2P.
combat handlers are in `race_combat.asm`.

## L5 spawn/lifecycle (E5)

Full lifecycle: `docs/analysis/race_spawn.md` (E5 results there).

- `sub_13BF4` owns the reserved opponent `ram_FF1F2A`: a rating gate
  (`Rating*(ActorDistanceScale-ram_FF1B34)`, `ram_FF1B36` latch) and the `Data5`
  special list (`ram_FFDBD4`). `sub_13CFE` applies the record page: graphics
  `$75 = LevelIndex+4`, type from `Race_ActorLevelBase[LevelIndex-1]`.
- `sub_138CE` runs the static pair: assigns a respawn timer from `unk_13A1A`, palette,
  side, `$74` profile and `Race_StaticActionTable` speed/offset; expiry calls
  `sub_13A26` (X = `PlayerProgress+$208000`). `Race_ClampActorY` deactivates past
  `$210000`. The earlier "static layout anomaly" was the inactive reset state.
- `$FF2FAA` (`$71=$12`) is gated by a `shape $186` track object:
  `ram_FF1B30` `$FFFF` -> deactivate; `>= $1C` -> init (X from progress+marker,
  Y `±(Rand&$7FF)`, Speed `$1770`); then updated by `Race_UpdateExtraStaticActor`.
- E5 confirmed expansion lists, forced special spawn, static assignment/respawn and
  extra init/update. Natural free-list traffic spawn was not exercised by the demo.

## Open questions

- L2 closed the input/lean/curve/speed contracts statically (`race_speed.md`);
  Experiment Pack E2 in `race_map.md` covers the residual dynamic checks.
- Visual roles of the static pair and `$FF2FAA` remain police/traffic/pacer
  hypotheses; their lifecycle is resolved (L5/E5).
- AI tables: `unk_12B7C`/`unk_12BCC` and `unk_13A1A` roles are described in
  `race_data_tables.md`; `Race_StaticActionTable` is decoded above; `unk_10E3E`,
  `unk_12168` (dead data, `U-0016` closed) and the on-foot vector table
  (`unk_7DCA8`) still need consumers.
- `unk_25812` is read in `Race_SetupActorSprite` but the value (`d2`) is never used;
  role unknown (dead read, not a behaviour dependency).
- Exact actor-action handler semantics (`0x12FE4`..`0x131BE`); dispatcher action2/3/4
  paths are dynamically confirmed, and E3 closed the profile-slot/budget/candidate
  checks; handler-internal semantics remain for L4/combat.
- Next: `src/race/race_combat.asm` (attack/action semantics) and
  `src/race/race_anim_audio.asm` (animations/random/audio).

## Rename proposals

Proposed only; no rename applied. See `identifiers.md` (R30 rows).
`sub_1131A` -> `Race_UpdateActorShadowFollow`; `sub_11A5E` ->
`Race_UpdateActorCurvePosition`; `sub_12B2A` -> `Race_GetAttackerReachAdjusted`;
`sub_133F0` -> `Race_SetActorCurveDirection`; `sub_135E8` ->
`Race_SetActorAccelerateFlag`; `sub_13704` -> `Race_UpdateActorDistanceRatio`;
`sub_13A5C` -> `Race_ResetActorFarBehind`; `sub_13D44` ->
`Race_UpdateTrackObjectSteering`; `unk_12168` -> `Race_ActorImpactHandlerTable`;
`unk_12B7C` -> `Race_CollisionExtentTable`; `unk_12BCC` ->
`Race_CloseAttackReachTable`; `unk_13A1A` -> `Race_LevelRespawnScale`.

## Natasha encounter counter (U-0004)

`Race_UpdateActorActions` (`0x12F60`) compares the current actor index `$71` with
`ram_FF1ADB` (Natasha's per-level actor index from `unk_D19A`). While the current-race
flag `ram_FF0520 == 3`, Natasha is routed through the alternate action-profile branch
(`profile+4`) instead of the default opponent handler. The flag is set when player A
attacks Natasha in `Race_UpdateActorPairImpact` and is persisted/decayed by
`Race_ComputeResults`.

Applied in R2: `Race_ActorProfileTable` (`unk_259C0`), `Race_ActorActionTable`
(`unk_12D16`), `Race_StaticActionTable` (`unk_25A44`), `Race_UpdateActorActions`
(`sub_12EA2`), `Race_DispatchActorAction` (`sub_16458`), `Race_ClampActorY`
(`sub_13130`), `Race_UpdateStaticActions` (`sub_13106`).

Applied in R6: `Race_InitExtraStaticActor`, `Race_UpdateExtraStaticActor`,
`Race_ClearActorOnFootFlags`, `Race_ApplyCrashImpact`,
`Race_ApplyCollisionImpact`, `Race_ExchangeCollisionSpeed`,
`Race_UpdateActorSpeedState`, `Race_FindTargetActor`,
`Race_ScanTargetDistance`.

Applied in R28: `Race_BuildTargetCandidates` (`sub_137E4`),
`Race_AddTargetCandidate` (`sub_13812`), `Race_SteerTowardTarget` (`sub_13892`).
Applied in R29: `RaceActor_PreviousCollisionOffset` (`$1C`),
`RaceActor_RespawnTimer` (`$56`).

Applied in R13: `Race_AdvanceActorProgress`, `Race_UpdateActorX`,
`Race_UpdateActorMovement`, `Race_UpdateActorFallMovement`,
`Race_UpdateActorChase`, `Race_ApplyActorSpeedCorrection`,
`Race_UpdateActorSpeedCurve`, `Race_ScaleActorSpeed`,
`Race_UpdateActorRoadSteering`.

Applied in R3c: action handlers `Race_ActorSteerRoadCenter`,
`Race_ActorSteerThrottle`, `Race_ActorCollideSteer`, `Race_ActorSteerCollide`,
`Race_ActorRandomCombatChoice`, `Race_ActorProximityReaction`,
`Race_ActorPursueAttack`, `Race_ActorAttackIfClose`, `Race_ActorEvadePlayer`,
`Race_ActorCombatResponse`, plus `Race_ActorStateCollision`,
`Race_ActorFollowPath`, `Race_ActorNormalUpdate`, `Race_ActorNormalVariant`,
`Race_ActorRecovery`, `Race_UpdateActorSpeedGear`. Remaining field/data names are
TODO.

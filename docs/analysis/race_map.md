# Race map: timeline, dataflow, field ownership and captures

- **Status:** v4 (L1 E1 + L2 static contract + L2 E2 dynamic results integrated)
- **Sources:** `docs/analysis/race.md`, `race_actors.md`, `race_ai.md`, `race_movement.md`,
  `race_speed.md`, `race_impact.md`, `race_spawn.md`, `road_render.md`, `docs/ram-map.md`,
  `tasks/race_understanding_program.md`
- **Scope:** the frame timeline, the simulation dataflow spine, the actor field ownership
  matrix, a capture matrix and the study order for the race workstream.
- **Tools:** `tools/race_dump.py`, `tools/ram_diff.py` (decode/diff the snapshots below).

## L0 frame timeline

The main loop alternates VDP/input (`Race_GameTick`) with simulation/render preparation
(`Race_Update`); the source order in `race_core.asm` is definitive. `Race_Init` performs
the setup and a few warm-up iterations before the race state starts.

| Phase | Function / buffer action | Output |
|---|---|---|
| Boot setup | `Race_Init` -> variables, bike data, frame buffers, HUD, track, assets, actors, actor lists/positions, track-data decode, VDP, opponents, audio | race ready |
| Warm-up | two `Race_Update`, two `Race_GameTick`/frame-ready waits, one more `Race_Update` | first frames primed |
| VDP/input | `Race_GameTick`: frame delay/state, `Race_UpdateTime`, VScroll apply, HInt flag, sprite/window/HScroll/palette DMA, `Race_SwapFrames`/`Race_ResetFrameTimers`, `Race_GetInput`/`Race_GetInputDemo` | inputs + DMA |
| Simulation | `Race_Update`: finish/damage gate, HUD speed, `Race_SpawnTick`, then (if `Race_ram_Started`) the player/actor/AI/collision chain, camera, render gate | updated actors/road state |
| Render prep | `Race_IntegrateTrackCurve`, interpolation, `Road_FillProfileTables`, `Race_BuildVScrollInfo`, object/visible-list build | road + object lists |
| Draw | road marking/HUD/edges, `RaceHud_Draw`, `Road_DrawObjects`, `RoadMarking_Draw`, rearview, HScroll, `Race_FinishFrame` | SAT/tiles/HUD |
| Buffer rotation | `Race_SwapFrames`/`Race_FinishFrame` rotate HScroll/SAT, HUD, sprite tiles, VScroll alpha buffers | next-frame buffers |

Per-frame actor/motion order (`Race_Update` step 4, from `race.md`): player animation ->
bike lean -> speed state -> `Race_UpdateActorAI` (active actors) -> static actors ->
`$FF2FAA` gate -> collision/action helpers -> nearest opponent -> action dispatch ->
nearest target. Camera runs after the actor chain.

## Dataflow spine

```
Pad (Race_GetInput)
  -> steering ($68 bits) + attack state ($69/$6B/$6C/$6D/$5A)
  -> lean/curve ($42, $3E/$40, Race_UpdateLeanCurve)
  -> speed/gear ($14/$18; Race_UpdateActorSpeedState/Gear)
  -> actor movement ($12,$26,$1E,$04; $36-$3C,$30,$00)
  -> AI target/action (bucket -> dispatcher -> handler)
  -> pair collision/impact (extents $4A-$56, speed exchange, damage $5C, fall $54)
  -> PlayerProgress/camera (Race_UpdateCamera)
  -> road profile/object list/visible list
  -> render (planes/HScroll/SAT/tiles) + HUD
  -> nearest opponent/place -> results/standings/money
```

## Actor field ownership matrix v4

v4 integrates the L2 dynamic checks (Experiment Pack E2) into v3. The new dynamic
evidence closes the residual L2 questions:

- `$18` is a word; E2-1 observed the 0->1->2->3 ladder, the `+E` upshift thresholds,
  the `+1A` downshift thresholds, the same-call up/down oscillation, and the max-gear
  `$14 = $FFFB` branch.
- `$42` and `$0C` keep the steering sign; `$0C = (FrameDistance>>8)*$42>>8` was checked
  for `±$600` forced steering.
- `$3E` is `(limit<<8)/(d0>>8)`; E2-3 confirmed it with a forced limit and observed
  the `$68` bit5 set. TP0 is the sampled on-road limit; TP2/TP3 selection remains
  `[static]` (bit tests at `0x13F96`/`0x13F78`).
- `$68` bit1 (B) and bit2 (A) were confirmed by pad injection; bit3 was forced for the
  E2-5 `$14 -= $14>>2` check.
- `U-0011` spawn `d4` is closed: normal mode reached `Race_SetupActor` six times over
  60 s, all with `d4 = 0`.

v3 adds the L2 control rows (`$12/$14/$16/$18/$3E/$40/$42/$46/$68/$69/$78`) and the
static contract in `race_speed.md`; E2 confirmed the residual dynamic points.
New in v3:

- `$18` Gear is a **word**. The earlier trace printed only its low byte, so it looked
  like `0`; the checked-in dump has `Gear = 5`. The demo bike record
  (`ActorBikeRecord_2`) has upshift thresholds `$125C..$2EE0`, all crossed.
- `$42` Lean feeds `sub_113CA` (`$0C = (FrameDistance>>8)*$42>>8`); `$3E`/`$40` come
  from `Race_UpdateBikeCurve` / `Race_UpdateLeanCurve`.
- `$68` bit1 = accelerate (B/AI), bit2 = brake (A/AI), bit3 = off-road, bit5 = curve
  active. bit0 = collision latch (L4), bit4 = fall/on-foot (L4), bit6 = AI-active
  marker (L3), bit7 = finish/progress latch (L1/L5).
- `$69` bit2 = steer/curve direction (set by road steering/`Race_SteerTowardTarget`),
  bit3 = direction sign; other bits are combat/fall (L4).
- `$78` is zeroed at actor creation and only decremented by `Race_UpdateBikeCurve`;
  no writer sets it non-zero, so the `word_14742` limit branch is dead `[static]`.
- `Race_LoadBikeData` ignores its `bikeId*16` index and always copies
  `unk_25AC4[0]`; blocks 1..7 are dead data `[static]`.

v2 integrates the Experiment Pack E1 dynamic checks (`analysis/capture_L1b_*`) into the
v1 static close. New in v2:

- `$00`/`$30`/`$36` confirmed dynamically: after the store at `0x10FE4`,
  `$30 == $00 - $36`; `$00` is the draw/screen Y and `$36` the road target.
- `$22` confirmed dynamically: `sub_113A4` computes `d0`, stores it in `$22` and adds
  it to `$00` (`0x113C4`); `sub_113CA` has the same add but was not exercised.
- `$34` confirmed dynamically: the shape selectors consume the signed bucket written by
  `Race_BuildActorObjectList`; negative values set H-flip `$8000`. Steering forced to
  `±$600` left `$34 == 0`, so it is not the lean/steer input.
- `$36-$3C`: `$36` is the road-target accumulator, `$38`/`$3A` change inside movement,
  `$3C` is a write-only copy of `sub_115C6`'s input `d1`.
- E1-5: `d4` was `0` on every AI-path `Race_SetupActorSprite` call in a full 60 s demo
  (4169 calls); the spawn path was not reached (`U-0011` stays open for spawn).

v1 changes from v0:

- `$00` vs `$30` ownership is resolved: `$00` is the absolute draw/screen Y after the
  road-band clamp; `$30` is the road-relative Y (`drawY - RoadYTarget`) used by
  movement/collision, and `$1A` is its previous value.
- `$08` is confirmed as the `Road_ShapeTable` index (`sub_12414` does
  `(Road_ShapeTable)[8(a0)]`); `$0A` carries shape flags (bit14 = horizontal flip).
- `$22` is an accumulated Y correction applied to `$00`; `$34` is a signed actor shape
  variant; `$58` is the animation frame token copied to the actor object's `+8`; `$76`
  is the animation flag byte consumed by `Race_BuildActorObjectList`.
- `$24`, `$44` are written but never read in the current source; `$48`, `$64`, `$7A`,
  `$7C`, `$7E` are **not actor fields** (the same offsets belong to the VScroll/rearview
  and object buffers); `$02` is also written by `sub_115C6`.
- Residual semantic questions are listed in the last column and in Experiment Pack E1.

Widths match the actual instruction sizes: `$04/$1E/$26` are longs, the
`$68-$78` block is byte-wise, everything else is a word. Offsets inside a long field
(`$06`, `$20`, `$28`) are aliases, not separate rows. A `-` in Readers/Writers means
"none found in `src/`"; it is not a guess.

| Offset | Width | Symbol | Writers | Readers | Evidence | Open question |
|---|---|---|---|---|---|---|
| `$00` | word | (unnamed) | road-band clamp in `Race_UpdateActorAI`/`Race_UpdateActorShadow`; Y-correction adders `sub_113A4`/`sub_113CA`/`Race_HandleInputOnFoot`; `Race_InitActorPositions`; `Race_SetupActor` | `Race_UpdateActorAI`/`Shadow` Y-delta math; `sub_113CA`/`Race_HandleInputOnFoot`; sprite projection | `[confirmed]` E1-1: `$30 = $00-$36` after `0x10FE4` | absolute draw/screen Y |
| `$02` | word | `RaceActor_PosZ` | `Race_CreateActors` (0); `sub_115C6` (base Z) | `sub_115C6`; collision/crash projection; main HInt/endlevel | `[static]` | exact projection term in `$2A` |
| `$04` | long | `RaceActor_X` | `Race_InitActorPositions`, movement/fall, spawn init | target selection, collision, camera | `[confirmed]` `$04=$1E+$26` | - |
| `$06` | word | `RaceActor_XLow` | same as `$04` | same as `$04` | `[confirmed]` low word of `$04` | no independent field |
| `$08` | word | (unnamed) | `Race_SetupActor` (curve sample); `Race_HandleInputOnFoot`/movement; crash/action handlers | `sub_12414` indexes `Road_ShapeTable`; pair collision | `[static]` | road-shape index (name candidate) |
| `$0A` | word | (unnamed) | `Race_SetupActor` (0); crash/action handlers | `sub_12414` (bit14 = flip) | `[static]` | full shape-flag bit map |
| `$0C` | word | (unnamed) | `sub_113CA` (steering); `Race_SetupActor` (curve sample) | pair collision, crash impact, `sub_11CC8` -> `RaceBike_ram_CurrentSteering` | `[confirmed]` E2-2: `$0C = (FrameDistance>>8)*$42>>8`, sign follows steering | current steering/curve sample |
| `$0E` | word | (unnamed) | `Race_UpdateActorFallMovement` | `sub_12414` (Y threshold) | `[static]` | fall-path Y threshold |
| `$10` | word | (unnamed) | `Race_UpdateActorFallMovement` | `sub_12414` (Y offset) | `[static]` | fall-path Y offset |
| `$12` | word | `RaceActor_Speed` | `Race_UpdateActorAI`, `Race_InitOpponent/TrafficActor`, impact | speed display, curve limit, AI | `[confirmed]` Player `$EE`, steering `$2D15` | - |
| `$14` | word | `RaceActor_Acceleration` | `Race_UpdateActorSpeedState`, `sub_13BD8` | `Race_UpdateActorAI`, shadow update | `[confirmed]` `$22` low speed, `$0E` at `$2D15`; E2-5 `$14 -= $14>>2` off-road | closed (E2-5) |
| `$16` | word | `RaceActor_Type` | `Race_CreateActors` | `Race_UpdateStaticActors`, speed state; indexes `unk_25A10` | `[confirmed]` 2/3/4; static anomaly | static `$16=0` after update |
| `$18` | word | `RaceActor_Gear` | `Race_UpdateActorSpeedState` | `Race_UpdateActorSpeedState` | `[confirmed]` word; demo dump `Gear=5`; E2-1 ladder, `+E`/`+1A` thresholds, same-call oscillation, max-gear `$FFFB` | - |
| `$1A` | word | (unnamed) | movement/fall start (`= $30`); `Race_SetupActor`; `Race_UpdateActorAI` restore | pair collision, `Race_ClampActorPairY`, `sub_12070` | `[static/dynamic]` `$31` vs `$30=$35` | previous road-relative Y (name candidate) |
| `$1C` | word | `RaceActor_PreviousCollisionOffset` | movement backup from `$32` | `Race_ApplyCollisionImpact` | `[static]` | - |
| `$1E` | long | `RaceActor_PreviousX` | `Race_UpdateActorX/Movement/FallMovement`, spawn setup | target scans, impact | `[confirmed]` `$04-$1E=$26` | - |
| `$22` | word | (unnamed) | road-band clamp overshoot; `Race_HandleInputOnFoot`; `sub_113A4`/`sub_113CA`; pair impact (adds `AttackOverlap`) | applied to `$00` by `sub_113A4`/`sub_113CA`; `Race_AdjustActorTrackPositions` | `[confirmed]` E1-2: `$22 == d0`, then `$00 += d0` at `0x113C4` | - |
| `$24` | word | (unnamed) | `Race_CreateActors` (0) | - | `[static]` write-only | unused/reserved |
| `$26` | long | `RaceActor_FrameDistance` | `Race_UpdateActorAI`, movement | movement, impact | `[confirmed]` `Speed*FrameDelay` | - |
| `$2A` | word | (unnamed) | `sub_115C6` | `sub_115C6`, impact/crash projection | `[static]`; `$1C39`, `$223` | exact projection term |
| `$2C` | word | (unnamed) | movement (max curve); `sub_115C6`; `Race_SaveActorShadow` (`>>1`); setup/advance (0) | `sub_115C6`, impact | `[static]` | curve/impact scale semantics |
| `$2E` | word | (unnamed) | `sub_115C6`; `Race_AdvanceActorProgress` (0) | `sub_115C6`; crash (`>=$2D`), `sub_12BD2` (`>=$1E`) | `[static]` | speed-loss accumulator |
| `$30` | word | `RaceActor_PosY` | road-band clamp (AI/shadow); `Race_InitActorPositions`; `Race_SetupActor`; AI restore from `$1A` | movement start (-> `$1A`); `Race_HandleInputOnFoot`; collision/sprite projection | `[confirmed]` E1-1: `$30 = $00-$36` at `0x10FE4`; `$1A` keeps the previous frame | road-relative Y (`drawY - RoadYTarget`) |
| `$32` | word | `RaceActor_CollisionOffset` | `sub_115C6` collision path | pair collision; copied to `$1C` | `[static]`; zero outside contact | - |
| `$34` | word | (unnamed) | `Race_BuildActorObjectList` | shape selectors, `Race_ApplyCrashImpact` (`>=3`) | `[confirmed]` E1-3: signed bucket drives the selector; negative sets H-flip `$8000`; not steering | signed shape variant |
| `$36` | word | `RaceActor_RoadYTarget` | movement (`+= curve_step`), fall (`-=`) | road-band clamp | `[confirmed]` E1-1/E1-4: accumulator; `$30 = $00-$36` | - |
| `$38` | word | `RaceActor_CurveDelta` | movement | `sub_115C6` | `[static/dynamic]` `$22B` | - |
| `$3A` | word | `RaceActor_CurveAccum` | movement | `sub_115C6` | `[static/dynamic]` `3` | - |
| `$3C` | word | `RaceActor_CurveStep` | `sub_115C6`; reset in `sub_13A26` | - | `[confirmed]` E1-4: write-only copy of `sub_115C6` input `d1` | - |
| `$3E` | word | `RaceActor_Curve` | `Race_UpdateBikeCurve` (zero/`(limit<<8)/(d0>>8)`); read by `Race_UpdateLeanCurve` | `Race_UpdateActorSpeedState`, `Race_UpdateLeanCurve` | `[confirmed]` E2-3 forced limit: `$3E = (limit<<8)/(d0>>8)`, bit5 set | - |
| `$40` | word | `RaceActor_LeanCurve` | `Race_UpdateBikeCurve` (zero), `Race_UpdateLeanCurve` | lean/curve math | `[static]` | `$40` not sampled in E2-2/E2-3 |
| `$42` | word | `RaceActor_Lean` | `Race_UpdateBikeLean` | `sub_113CA` -> `$0C` | `[confirmed]` E2-2: sign follows steering; formula `race_speed.md` | - |
| `$44` | word | (unnamed) | `sub_12BD2`, `sub_12C9A` | - | `[static]` write-only | unused/reserved |
| `$46` | word | `RaceActor_CurveDirection` | `Race_SteerTowardTarget`, `Race_UpdateActorRoadSteering`, `Race_ClampActorY` | movement/steer handlers | `[dynamic]` `-$03`; L2 formula in `race_speed.md` | reader mapping (L3) |
| `$48` | word | (unnamed) | - (VScroll `$48(a0)` only) | - | `[static]` not an actor field | unused for actors |
| `$4A` | word | `RaceActor_CollisionExtent` | collision path | `Race_UpdateCollision` | `[dynamic]` `$0D`/`$0E` | - |
| `$4C` | word | `RaceActor_CollisionExtentUpper` | `Race_GetCollisionExtent` | pair separation | `[static/dynamic]` | - |
| `$4E` | word | `RaceActor_CollisionExtentLower` | `Race_GetCollisionExtent` | pair separation | `[static/dynamic]` | - |
| `$50` | word | `RaceActor_AttackReach` | combat/attack | pair impact | `[dynamic]` `$28`/`$19` | - |
| `$52` | word | `RaceActor_AttackOverlap` | combat/attack | pair impact | `[dynamic]` `$42`/`$33` | - |
| `$54` | word | `RaceActor_FallState` | `Race_ApplyFallKnockdown` | crash/fall path | `[static]` `$11` | player-specific delay? |
| `$56` | word | `RaceActor_RespawnTimer` | `Race_CreateActors` (`$FFFF`), static updater | static update | `[static/dynamic]` | - |
| `$58` | word | (unnamed) | `Race_UpdateAnimation` (race_anim_audio) | `Race_BuildActorObjectList` copies to actor object `+8` | `[static]` | animation frame token |
| `$5A` | word | `RaceActor_AttackCooldown` | combat | dispatcher | `[static]` | - |
| `$5C` | word | `RaceActor_TileBase` | `Race_CreateActors`, `Race_SetupActor`, knockdown budget | animation/impact | `[confirmed]` Player `$A00 -> $507` | dual tile-base/health role |
| `$5E` | word | (unnamed) | `Race_CreateActors` | sprite setup | `[static]` graphics `+$A` | exact sprite field |
| `$60` | word | (unnamed) | `Race_CreateActors` | sprite setup | `[static]` graphics `+$C` | exact sprite field |
| `$62` | long | (unnamed) | movement/advance (`= Race_ram_ProgressSnapshotB`) | not documented | `[static]` | late-race progress snapshot |
| `$64` | word | (unnamed) | - (VScroll/object writers only) | - | `[static]` not an actor field | unused for actors |
| `$66` | word | `RaceActor_Rating` | `Race_CreateActors`, `Race_RecycleActor` | spawn/init speed | `[confirmed]` def byte5*100 | recycle distance reuse |
| `$68` | byte | `RaceActor_ControlFlags` | `Race_GetInput`, AI, impact, spawn | AI/movement/impact | `[confirmed]` bit0 collision, bit1 accel (E2-4 B), bit2 brake (E2-4 A), bit3 off-road (E2-5 forced), bit4 fall/on-foot, bit5 curve, bit6 AI-active, bit7 finish | L2 bits closed; bit0/4 L4, bit6 L3, bit7 L1/L5 |
| `$69` | byte | `RaceActor_StateFlags` | combat/AI | pair collision, dispatcher | `[confirmed]` bit2 steer/curve, bit3 direction; combat bits L4 | L2 owns bit2/3; bit0/1/4/5/6/7 L4 |
| `$6A` | byte | `RaceActor_WeaponAnimFlags` | animation | animation | `[static]` | role |
| `$6B` | byte | `RaceActor_AttackFlags` | `Race_CreateActors`, combat | combat | `[confirmed]` armed `$02` | - |
| `$6C` | byte | `RaceActor_AttackPhase` | combat | dispatcher/combat | `[confirmed]` | - |
| `$6D` | byte | `RaceActor_AttackTimer` | combat | combat | `[confirmed]` | - |
| `$6E` | byte | `RaceActor_AnimState` | `Race_SetupActor`, impact | AI/animation | `[dynamic]` `$FF` normal | state mapping |
| `$6F` | byte | `RaceActor_AnimFrame` | impact/animation | animation | `[dynamic]` | frame mapping |
| `$70` | byte | `RaceActor_AnimTimer` | animation | animation | `[static]`; zero active | cadence |
| `$71` | byte | `RaceActor_Index` | `Race_CreateActors` | target tables/standings | `[confirmed]` 0..15, static `$10/$11`, extra `$12` | - |
| `$72` | byte | `RaceActor_AnimIndex` | `Race_SetupActorSprite` | animation/candidate buckets | `[static/dynamic]` values 3/5 | - |
| `$73` | byte | `RaceActor_Palette` | `Race_CreateActors` | sprite attributes | `[confirmed]` | - |
| `$74` | byte | `RaceActor_ActionProfile` | `Race_CreateActors` | action/profile tables | `[confirmed]` profiles 0..19 | static profile assignment |
| `$75` | byte | `RaceActor_GraphicsIndex` | `Race_CreateActors` | curve limit / sprite setup | `[confirmed]` | - |
| `$76` | byte | (unnamed) | `Race_UpdateAnimation` (race_anim_audio) | `Race_BuildActorObjectList` (`btst #0`, `move.b`) | `[static]` | animation flag byte |
| `$77` | byte | (unnamed) | `Race_CreateActors` (def byte4) | not documented | `[static]` | meaning (class/tier?) |
| `$78` | byte | (unnamed) | `Race_CreateActors` (0); `Race_UpdateBikeCurve` (decrement only) | `Race_UpdateBikeCurve` | `[static]` never set non-zero; `word_14742` branch dead | rename candidate (`RaceActor_CurveTimer`) |
| `$7A` | word | (unnamed) | - (VScroll writer only) | - | `[static]` not an actor field | unused for actors |
| `$7C` | word | (unnamed) | - (rearview/VScroll buffer) | `Race_DrawRearviewMirror` (not an actor) | `[static]` not an actor field | unused for actors |
| `$7E` | word | (unnamed) | - (VScroll writer only) | - | `[static]` not an actor field | unused for actors |

## Experiment Pack E1 (residual L1 fields)

At most five checks; run in `race_L1_actor_core_b.md`. Breakpoints are bare hex PC.

```
E1-1  $00 vs $30 draw-Y split
Goal:        confirm $00 = absolute screen Y and $30 = drawY - RoadYTarget
Scenario:    demo race, steering frames
Breakpoint:  0x10FDE (after clamp, before neg d1)
Commands:    p/x $ff1eaa+$00 ; p/x $ff1eaa+$30 ; p/x $ff1eaa+$36
Report:      $00, $30, $36 and the instruction's d1
Decision:    if $00-$36 == $30 -> confirmed; otherwise keep the $00/$30 row open

E1-2  $22 Y-correction role
Goal:        confirm $22 is applied to $00 by sub_113A4/sub_113CA
Scenario:    pair contact / road-band overshoot
Breakpoint:  0x10FDE
Commands:    p/x $ff1eaa+$22 ; p/x $ff1eaa+$00
Report:      $22 before/after and the $00 delta
Decision:    if delta($00) == delta($22) -> confirmed

E1-3  $34 shape variant
Goal:        confirm $34 is the signed shape/lean selector consumed by the selectors
Scenario:    lean left/right and a crash frame
Breakpoint:  0x14486 (Race_ApplyCollisionImpact) and a Race_SelectActor*Shape entry
Commands:    p/x $ff1eaa+$34 ; p/x $ff1eaa+$08 ; p/x $ff1eaa+$0A
Report:      $34/$08/$0A and the selected shape pointer
Decision:    if the selector uses $34 as an index/sign -> confirmed

E1-4  $36-$3C accumulator roles
Goal:        confirm $36 is an accumulator and $3C is write-only
Scenario:    normal steering frames
Breakpoint:  sub_115C6 entry (0x115C6)
Commands:    p/x $ff1eaa+$36 ; p/x $ff1eaa+$38 ; p/x $ff1eaa+$3A ; p/x $ff1eaa+$3C
Report:      the four words before/after the call
Decision:    if only $38/$3A/$3C change and $36 changes elsewhere -> confirmed

E1-5  d4 at Race_SetupActorSprite (U-0011)
Goal:        find the value of d4 on the AI path and at spawn
Scenario:    one AI frame and one opponent spawn
Breakpoint:  0x13746 (Race_SetupActorSprite entry)
Commands:    p/x $d4 ; p/x $ff1eaa+$30 ; p/x $ff1eaa+$72
Report:      d4 and whether the extra candidate buckets are valid
Decision:    if d4 is stable per-path -> close U-0011 as ambient-but-deterministic
```


## Experiment E1 results (dynamic)

Runs: `analysis/capture_L1b_demo_survey.gdb`, `capture_L1b_fields.gdb`,
`capture_L1b_shapes.gdb`, `capture_L1b_shape_sign.gdb`, `capture_L1b_d4.gdb`; traces in
`analysis/notes/L1b_*`.

| Check | Breakpoint / window | Observed | Decision |
|---|---|---|---|
| E1-1 `$00/$30/$36` | `0x10FDE`/`0x10FE4`, demo PlayerA | `d1 = $36-$00`; stored `$30 = $00-$36` (e.g. `$00=$FF57`, `$36=$FFEC`, `$30=$FF6B`) | confirmed |
| E1-2 `$22` | `0x113C4`, demo PlayerA | `$22 == d0` before the add (`d0=$FFF6`); the next frame's `$00` moved by it | confirmed |
| E1-3 `$34` | `0x101E6`/`0x1022C`/`0x10254`, demo | `$34=+1` -> flip 0; `$34=-1/-2` -> flip `$8000`; forced steering `±$600` left `$34=0` | confirmed |
| E1-4 `$36-$3C` | `0x10F6C`/`0x115C6`, demo | `$36/$38/$3A` update inside movement; `$3C` receives `sub_115C6`'s `d1` and is never read | confirmed |
| E1-5 `d4` | `0x13746`, full demo | 4169 calls, all AI path (`ret=0x10FE8`), `d4=0`; no spawn (`ret=0x16E24`) calls | AI path closed; spawn open |

### Demo collision/crash survey

A full 60 s demo (`capture_L1b_demo_survey.gdb`) counted the contact/crash entry points:

- pair Y-overlap branch `0x127EA`: 9 hits, one involving `RacePlayerA`
  (`a1=$FF1EAA`, `a2=$FF242A`);
- object/static impact `0x14486`: 0 hits;
- crash impact `0x11B7A`: 0 hits — it is gated on `DemoMode == 0`
  (`race_ai.asm:227-236`), so the demo cannot enter the player crash path;
- `Race_ApplyFallKnockdown` `0x14C3C`: 6 pair entries, none with `RacePlayerA`.

Natural demo collisions therefore exist but are rare and never produce a player crash;
crash/fall experiments need a non-demo run.

## L2 static control contract (summary)

Full formulas: `race_speed.md`; table layouts: `race_data_tables.md`.

```
Pad (SACBRLDU)
  B bit4 -> $68 bit1 (accelerate)      A bit6 -> $68 bit2 (brake)
  Left bit2 / Right bit3 -> RaceBike_ram_CurrentSteering
       (Left subtracts, Right adds, +ReturnToStraightPower on reversal,
        clamp +-MaxSteering; Left has priority)
  neither -> steering decays by ReturnToStraightPower

$12 Speed, $14 Acceleration, $18 Gear (word)
  AI pre-step: if $68 bit3 off-road, $14 -= $14/4;
               Speed += $14*FrameDelay (clamp 0);
               $26 = Speed*FrameDelay
  SpeedState: bit1 -> gear via +E upshift / +1A downshift / +2 accel;
              max gear word0 -> $14 = -5;
              bit2 -$40, bit1-clear -5, bit5 -Curve*$60>>16,
              bit3 positive result -= Speed>>8

Race_UpdateBikeLean:  $42 = sign(steer)*|steer|*FF1AAA /
                            ((FF1AA6>>3)*(Speed*FF1AB4>>8))
sub_113CA:            $0C = (FrameDistance>>8)*$42>>8 ; $08 = $0C
Race_UpdateBikeCurve: d0 = |$08| (*$200>>8 for demo/non-player)
                      d0 = (d0*(Speed*FF1AB2>>8))>>3
                      limit = $78 ? word_14742 : TrackParam(0/2/3)
                      $3E = (limit<<8)/(d0>>8), $68 bit5
Race_UpdateLeanCurve: ram_FF3042 = (d0*$3E)>>16
                      $40 = (d0*((($10000/$3E)-1))*$140)>>8
GetCurveSpeedLimit:   ((bit3?TP2:TP0)<<3) /
                      ((|curve[((X>>16)+6)&$FF]| * unk_14056[$75])>>8)
```

Static quirks (documented, no unresolved behavior):

- `$18` is a word; the old trace misread the low byte. Demo gear reached 5.
- `$78` is never set non-zero -> `word_14742` limit is unreachable.
- `Race_LoadBikeData` ignores `bikeId*16` and always loads `unk_25AC4[0]`.
- `TrackParam1` is loaded but never read.
- Steering asymmetry at zero: Left adds `ReturnToStraightPower`, Right does not
  (first step `$48` vs `$30` with the loaded block 0).

## Experiment Pack E2 (L2 residual dynamic checks)

Run in `race_L2_control_b.md`. At most five checks; bare-hex PCs.

```
E2-1  word-width gear + upshift
Goal:        confirm $18 is a word and +E[gear] is the upshift threshold
Scenario:    demo race until Speed > $28A0 (or force Speed)
Breakpoint:  0x13AFE (read $E(a0,gear*2)) and 0x13B12 (store Gear)
Commands:    p/x $ff1eaa+$18 (word!) ; p/x $d1 ; p/x $ff1eaa+$12
Report:      gear word, d3 threshold, speed across the upshift
Decision:    if gear increments when Speed >= +E[gear] -> table layout confirmed;
             also confirm the max-gear -5 acceleration
             (a byte read here is the old artifact, not evidence)

E2-2  lean sign and $0C derivation
Goal:        confirm $42 sign and $0C = (FrameDistance>>8)*$42>>8
Scenario:    force RaceBike_ram_CurrentSteering = +$600 then -$600
Breakpoint:  0x13EA0 (entry) and 0x113CA
Commands:    p/x $ff38b0 ; p/x $ff1eaa+$42 ; p/x $ff1eaa+$0C
Report:      steering, $42, $0C for both signs
Decision:    if $42/$0C flip sign with steering -> confirmed

E2-3  curve-limit branch and selection
Goal:        confirm the limit source and (limit<<8)/(d0>>8)
Scenario:    normal + off-road frames; force $78 non-zero if reachable
Breakpoint:  0x13FC0 / 0x13FCE
Commands:    p/x $ff1eaa+$08 ; p/x $ff1eaa+$12 ; p/x $ff1eaa+$68
             p/x $ff302e ; p/x $ff3032 ; p/x $ff3034 ; p/x $14742
Report:      computed d0, selected limit, stored $3E/bit5
Decision:    if on-road uses TP0, off-road TP2, bit5+off-road TP3 ->
             confirmed; $78 lockout is a static no-writer exception

E2-4  input bit -> control flag mapping
Goal:        confirm B->$68 bit1, A->$68 bit2, Left/Right steering sign
Scenario:    inject pad frames (capture_natural_attack.gdb pattern) or play
Breakpoint:  0xBE56 after GetInputPlayerA, or read at 0x10E66
Commands:    p/x $ff1eaa+$68 ; p/x $ff38b0 ; p/x $ff1eaa+$12
Report:      $68 low bits and steering per held button
Decision:    if B sets bit1, A sets bit2, Left subtracts/Right adds -> confirmed

E2-5  off-road acceleration reduction
Goal:        confirm $14 -= $14/4 and the Speed>>8/downshift rule
Scenario:    enter off-road (Y clamp sets $68 bit3) or force bit3
Breakpoint:  0x10E8C / 0x10E9A and 0x13B6C
Commands:    p/x $ff1eaa+$14 (before/after) ; p/x $ff1eaa+$12
             p/x $ff1eaa+$68 ; p/x $ff1eaa+$18
Report:      acceleration before/after the 3/4 reduction; gear on downshift test
Decision:    if $14_after == $14_before - $14_before/4 -> confirmed
```

## Experiment E2 results (dynamic)

Runs: `analysis/capture_L2b_e2a.gdb`, `capture_L2b_e2a2.gdb`,
`capture_L2b_e2b.gdb`, `capture_L2b_e2b2.gdb`, `capture_L2b_spawn.gdb`; traces in
`analysis/notes/L2b_*`. Samples are PlayerA unless noted; forced values are recorded.

| Check | Breakpoint / window | Observed | Decision |
|---|---|---|---|
| E2-1 word gear/upshift | `0x13B12`, demo PlayerA | word gear 0->1->2->3; upshift `+E[0]=$125C`, `+E[1]=$1838`; downshift `+1A[1]=$1518`, `+1A[2]=$1BBC` | confirmed |
| E2-1 same-call oscillation | `0x13B12`/`0x13B24`, demo | at Speed `$1882`: 1->2 (`$1838`) then 2->1 (`$1BBC`) inside the same SpeedState call | confirmed (real hysteresis inversion) |
| E2-1 max gear | `0x13B68`/`0x13BB6`, forced Speed `$2F00` | gear 5 == max 5 -> `$14 = $FFFB` (-5) | confirmed |
| E2-2 lean/`$0C` | `0x13EA0` forced `±$600`, `0x113D8` | `+$600` -> `$42=+$DFB`, `$0C=+$B5`; `-$600` -> `$42=-$293`, `$0C=-$5B`; formula matches | confirmed |
| E2-3 curve limit | `0x13FB0`/`0x13FC0`/`0x13FCE` | on-road `d0=$5EC..$C2F` < TP0 `$E646` -> CLR; forced `d1=$100` -> `$3E = $10000/(d0>>8)` (`$2AAA`,`$3333`,`$4000`) and bit5 set | confirmed |
| E2-3 TP2/TP3 | `0x13F96`/`0x13F78` | TP2/TP3 selected by `$68` bit3/bit5; only TP0 sampled | static |
| E2-4 input flags | `0xBE6C` injection, `0xC00A` sample | Left `$04` -> steering `$FA00` (-`$600`); Right `$08` -> `+$390`; B `$10` -> `$68` bit1, Speed `$61C`; A `$40` -> `$68` bit2, Speed 0; release clears | confirmed |
| E2-5 off-road accel | `0x10E8C` forced bit3, `0x10E9C` | acc `$22` -> `$1A` (34 - (34>>2) = 26), bit3 set | confirmed |
| U-0011 spawn `d4` | `0x13746`, normal mode | 2175 calls; 6 from `ret=0x16E24`; `d4=0` on all; 0 non-zero `d4` | confirmed (spawn `d4=0`) |

Notes:

- The partial pre-run (`analysis/notes/L2b_demo_trace.txt`) froze before frame 300. Only
  its E2-1 word/pointer observations were reused; all results above come from fresh
  split runs with PlayerA-only breakpoints.
- The E2-1 oscillation follows from using `+E[old]` for the upshift and `+1A[new]` for
  the downshift in the same call. It holds the demo player at low gear until Speed
  exceeds the next downshift threshold.
- E2-3 forced `d1=$100` at `0x13FB0` only to reach the limit branch; the formula check
  does not depend on the forced value.
- U-0011 normal mode: `DemoMode` was forced to 0 after `Race_ram_Started` and B was
  injected at `0xBE6C`; the spawn path `Race_SetupActor` became reachable.

## Register-base and list warning

Raw `NN(aN)` greps are not evidence until the base register is known:

- `Race_BuildVScrollInfo` uses `a0 = Race_ram_CurrentVScrollInfo` and writes
  `$1E/$2A/$4A/$4E/$56/$66/$68/$6E/$70/$72` there. These are **VScroll buffer**
  fields, not actor fields.
- Road objects use `a0 = Road_ObjectArray` (`$FFD37C`, `$14`-byte records) with the
  field names in `docs/analysis/road_render.md`; their offsets repeat the low actor
  offsets by coincidence.
- HUD buffers (`Menu_ram_FrameBuffer`/`FrameBuffer2`) and sprite/tile arrays also reuse
  small offsets; only count an access after identifying the base.
- Actor pointers come from `ram_FF1A08` (AI loop; PlayerA + 7 opponents) and the
  active list `Race_ram_ActiveActorList = $FF1A0C`. The two overlap: `$FF1A0C` starts
  one pointer into the `$FF1A08` buffer, so the active list holds the 7 opponents
  while `Race_ram_ActiveActorCount` still includes PlayerA. `Race_InitActorLists`
  writes the `$FF1A08` buffer, and `Race_ActivateActor`/`Race_RemoveActiveActor`
  append/remove at `$FF1A0C` using the same sentinel. Use `race_dump.py` to inspect
  both lists instead of assuming they are identical.

## Capture matrix

Existing snapshots live in `analysis/dumps/`; the breakpoints below are the ones
already used for them. New checks follow the Experiment Pack format in
`tasks/race_understanding_program.md`.

| Question | Breakpoint / fields | Decision |
|---|---|---|
| Creation field sources | `0xB72A` (`Race_InitActorPositions` entry): `$16/$66/$71/$73/$74/$75/$77`, `$5C/$5E/$60` | definition byte -> actor field mapping (`[dynamic]` confirmed) |
| Position initialization | `0xA544` after `Race_InitActorPositions`: `$00/$04/$1A/$1E/$30` | initial Y/X layout; `$04/$1E` share the start X |
| Running actor state | `0x10E66` (`Race_UpdateActorAI`, PlayerA `$12>0`): count/list, `$12/$14/$26`, `$30/$68/$69` | active/free split and speed/frame distance |
| Steering and lean | `0x10E66` with `RaceBike_ram_CurrentSteering=±$600`: `$42/$3E/$40/$3C`, `$69` | `$42` sign = lean; `$3E/$40` only under curve limit |
| Speed/gear loop | `0x10E66` every 10th frame: `$12/$14/$18/$68/$69/$3A/$3C/$4C/$4E` | accel vs gear branch; `$4C/$4E` extent flips |
| Off-road transition | `0x10E66` after 300 forced-left frames: `$68` bit3, `$30/$36/$00` | hard curve vs off-road bit |
| Road objects | running/`road_objects` dump: `$FFDE72` count, `Road_ObjectArray`, `Road_VisibleObjectList` | object count is `ram_FFDE72` (22 in the demo), not `Race_ram_TrackObjectCount` |
| Pair impact | `0x14486` (`Race_ApplyCollisionImpact`): `$1C/$2A/$2C/$2E/$54/$5C` | impact/damage post-state; return breakpoint still TODO |
| E1-1/E1-4 actor fields | `0x10FDE`/`0x10FE4`/`0x10F6C`/`0x115C6`, demo PlayerA | `$30 = $00-$36`; `$36` accumulator; `$3C` write-only |
| E1-2 Y correction | `0x113C4`, demo PlayerA | `$22 = d0`, then `$00 += d0` |
| E1-3 shape variant | `0x101E6`/`0x1022C`/`0x10254`, demo | signed `$34` -> shape index + H-flip |
| E1-5 ambient `d4` | `0x13746`, full demo | 4169 AI-path calls, `d4=0`; no spawn |
| E2-1 gear word/upshift | `0x13B12`/`0x13B24`/`0x13B68`, demo + forced Speed | `$18` word; `+E`/`+1A`; same-call oscillation; max-gear `-5` confirmed |
| E2-2 lean sign/`$0C` | `0x13EA0`/`0x113D8`, forced steering `±$600` | `$42`/`$0C` sign and `(FrameDistance>>8)*$42>>8` confirmed |
| E2-3 curve limit | `0x13FB0`/`0x13FC0`/`0x13FCE`, forced `d1` | TP0 dynamic; formula and bit5 confirmed; TP2/TP3 static |
| E2-4 input flags | `0xBE6C` injected pad, `0xC00A` sample | B/A -> `$68` bit1/bit2, Left/Right steering sign confirmed |
| E2-5 off-road accel | `0x10E8C`/`0x10E9C`, forced bit3 | `$14 -= $14>>2` confirmed |
| U-0011 spawn `d4` | `0x13746`, normal mode | 6 spawn (`ret=0x16E24`) calls, `d4=0`; closed |
| Demo collision/crash | `0x127EA`/`0x14486`/`0x11B7A`/`0x14C3C`, full demo | 9 pair contacts (1 player), 0 crash/object, no player fall |
| Static/extra actors | running dump: static `$16/$30/$46/$56/$74`; `$FF2FAA` `$71` | static layout anomaly vs extra slot activation |

## Tooling and validation

Both tools decode the same layout from `src/core/ram_const.asm` through
`tools/ram_layout.py`.

```sh
python3 tools/race_dump.py analysis/dumps/actor_running_ram.bin
python3 tools/race_dump.py analysis/dumps/actor_running_ram.bin --actor 0xff1eaa
python3 tools/race_dump.py analysis/dumps/actor_running_ram.bin --json
python3 tools/ram_diff.py analysis/dumps/actor_post_create_ram.bin \
    analysis/dumps/actor_post_positions_ram.bin
python3 tools/ram_diff.py analysis/dumps/actor_steer_left_ram.bin \
    analysis/dumps/actor_steer_right_ram.bin
```

Observed on the checked-in dumps:

- `actor_running`: active count `8`; `$FF1A08` = PlayerA + `$FF232A..$FF262A`;
  `$FF1A0C` = the 7 opponents; opponent free list `7`, traffic free list `0`;
  object count `22`, visible list 22 entries terminated by `$FFFF`.
- `post_create` vs `post_positions`: PlayerA `$00/$04/$1A/$1E/$30` change from zero
  to `$A0`/`$80000`.
- `steer_left` vs `steer_right`: PlayerA `$42` changes `$FFB7 -> $0049`; the other
  changed bytes are outside the actor (RNG/audio state).

## Study order

| Layer | Scope | Gate |
|---|---|---|
| L0 | This timeline/buffers/lists | prerequisite for all snapshots |
| L1 | Actor struct, shadow/backup, creation/activation/recycle | close before L2-L5 |
| L2 | Input -> speed/gear/lean/curve | player motion |
| L3 | AI loop -> target buckets -> dispatcher -> handlers | opponent behavior |
| L4 | Pair collision, impact, damage, fall, club transfer | consequences |
| L5 | Spawn/traffic/static/police lifecycle | who is on the track |
| L6 | Camera -> road profile -> objects -> projection -> shapes -> render | may run in parallel after L1 |
| L7 | HUD, animation data, standings/results/money/highscore | last |

The L1 actor-core dynamic pass is complete (`tasks/race_L1_actor_core_b.md`): matrix v2
integrates E1. The L2 static pass (`tasks/race_L2_control_a.md`) and the L2 dynamic pass
(`tasks/race_L2_control_b.md`) are complete: matrix v4 integrates E2 and closes
`U-0011`. Next: run `tasks/race_R30_integration.md` (matrix v5, crash/fall contracts,
R30 handler tables, `U-0012`..`U-0016` triage), then L3/L4.

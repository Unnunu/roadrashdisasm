# Race map: timeline, dataflow, field ownership and captures

- **Status:** matrix v13 (v12 + closed `U-0017` stamina regen and `U-0018` VScroll
  compaction arithmetic)
- **Sources:** `docs/analysis/race.md`, `race_actors.md`, `race_ai.md`, `race_physics.md` (actor movement),
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

## Captures and experiments

Dynamic experiment packs, result transcripts and the capture matrix are in
`docs/analysis/race_captures.md`. This page keeps the timeline, dataflow spine, field
matrix and the durable addenda (contracts only).

## Actor field ownership matrix (live state: v13; v1-v13 deltas below)

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
- `$78` is zeroed at actor creation and decremented by `Race_UpdateBikeCurve`; R30
  added its two writers (`sub_14456`=`$78`, `sub_1446E`=`$1E`), so the `word_14742`
  limit branch is reachable during a fall `[static]` (v5 correction).
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
- Residual semantic questions are listed in the last column and in Experiment Pack E1
  (`race_captures.md`).

Widths match the actual instruction sizes: `$04/$1E/$26` are longs, the
`$68-$78` block is byte-wise, everything else is a word. Offsets inside a long field
(`$06`, `$20`, `$28`) are aliases, not separate rows. A `-` in Readers/Writers means
"none found in `src/`"; it is not a guess.

| Offset | Width | Symbol | Writers | Readers | Evidence | Open question |
|---|---|---|---|---|---|---|
| `$00` | word | (unnamed) | road-band clamp in `Race_UpdateActorAI`/`Race_UpdateActorShadow`; Y-correction adders `sub_113A4`/`sub_113CA`/`Race_HandleInputOnFoot`; `Race_InitActorPositions`; `Race_SetupActor` | `Race_UpdateActorAI`/`Shadow` Y-delta math; `sub_113CA`/`Race_HandleInputOnFoot`; sprite projection | `[confirmed]` E1-1: `$30 = $00-$36` after `0x10FE4` | none: absolute draw/screen Y |
| `$02` | word | `RaceActor_PosZ` | `Race_CreateActors` (0); `sub_115C6` (base Z) | `sub_115C6`; collision/crash projection; main HInt/endlevel | `[static]` | none: PosZ; the `$2A` derivation is in `race_physics.md` |
| `$04` | long | `RaceActor_X` | `Race_InitActorPositions`, movement/fall, spawn init | target selection, collision, camera | `[confirmed]` `$04=$1E+$26` | - |
| `$06` | word | `RaceActor_XLow` | same as `$04` | same as `$04` | `[confirmed]` low word of `$04` | no independent field |
| `$08` | word | (unnamed) | riding: `Race_SetupActor`/`sub_113CA`/`sub_113A4`/movement curve sample; on-foot/shadow: `Race_HandleInputOnFoot`/`sub_1131A` (signed Y velocity) | `sub_113A4`/`sub_113CA`/`sub_115C6`/`Race_UpdateBikeCurve`; pair collision | `[static]` `U-0012`: dual-use scratch (curve sample vs Y velocity). `sub_12414`'s `8(a0)` is an **object** shape index, not this field | none: dual-use by design (curve sample vs on-foot Y velocity) |
| `$0A` | word | (unnamed) | `Race_SetupActor` (0); crash/action handlers | `sub_12414` (bit14 = flip) | `[static]` | bit14 facing closed; other flag bits unexercised (waived in acceptance) |
| `$0C` | word | (unnamed) | `sub_113CA` (steering); `Race_SetupActor` (curve sample) | pair collision, crash impact, `sub_11CC8` -> `RaceBike_ram_CurrentSteering` | `[confirmed]` E2-2: `$0C = (FrameDistance>>8)*$42>>8`, sign follows steering | current steering/curve sample |
| `$0E` | word | (unnamed) | `Race_UpdateActorFallMovement`, `sub_11A5E` | - | `[static]` `U-0013`: write-only whole-track X advance. `sub_12414`'s `$E(a0)` is an **object** field | none |
| `$10` | word | (unnamed) | `Race_UpdateActorFallMovement`, `sub_11A5E` | - | `[static]` `U-0013`: write-only final curve-buffer index. `sub_12414`'s `$10(a0)` is an **object** field | none |
| `$12` | word | `RaceActor_Speed` | `Race_UpdateActorAI`, `Race_InitOpponent/TrafficActor`, impact | speed display, curve limit, AI | `[confirmed]` Player `$EE`, steering `$2D15` | - |
| `$14` | word | `RaceActor_Acceleration` | `Race_UpdateActorSpeedState`, `sub_13BD8` | `Race_UpdateActorAI`, shadow update | `[confirmed]` `$22` low speed, `$0E` at `$2D15`; E2-5 `$14 -= $14>>2` off-road | closed (E2-5) |
| `$16` | word | `RaceActor_Type` | `Race_CreateActors` | `Race_UpdateStaticActors`, speed state; indexes `unk_25A10` | `[confirmed]` 2/3/4; inactive static reset | none: static actors reset `$16=0` while inactive |
| `$18` | word | `RaceActor_Gear` | `Race_UpdateActorSpeedState` | `Race_UpdateActorSpeedState` | `[confirmed]` word; demo dump `Gear=5`; E2-1 ladder, `+E`/`+1A` thresholds, same-call oscillation, max-gear `$FFFB` | - |
| `$1A` | word | (unnamed) | movement/fall start (`= $30`); `Race_SetupActor`; `Race_UpdateActorAI` restore | pair collision, `Race_ClampActorPairY`, `sub_12070` | `[static/dynamic]` `$31` vs `$30=$35` | none: previous road-relative Y (name candidate only) |
| `$1C` | word | `RaceActor_PreviousCollisionOffset` | movement backup from `$32` | `Race_ApplyCollisionImpact` | `[static]` | - |
| `$1E` | long | `RaceActor_PreviousX` | `Race_UpdateActorX/Movement/FallMovement`, spawn setup | target scans, impact | `[confirmed]` `$04-$1E=$26` | - |
| `$22` | word | (unnamed) | road-band clamp overshoot; `Race_HandleInputOnFoot`/`sub_1131A`; `sub_113A4`/`sub_113CA`; pair impact (adds `AttackOverlap`) | applied to `$00` by `sub_113A4`/`sub_113CA`/`Race_HandleInputOnFoot`/`sub_1131A`; `Race_AdjustActorTrackPositions` | `[confirmed]` E1-2: `$22 == d0`, then `$00 += d0` at `0x113C4` | - |
| `$24` | word | (unnamed) | `Race_CreateActors` (0) | - | `[static]` write-only | unused/reserved |
| `$26` | long | `RaceActor_FrameDistance` | `Race_UpdateActorAI`, movement | movement, impact | `[confirmed]` `Speed*FrameDelay` | - |
| `$2A` | word | (unnamed) | `sub_115C6`, impact/crash reset | `sub_115C6`, impact/crash projection | `[static]`; `$1C39`, `$223` | none: curve/impact Y offset computed by `sub_115C6` |
| `$2C` | word | (unnamed) | movement (max curve); `sub_115C6`; `sub_1438E` (impact); `Race_SaveActorShadow` (`>>1`); setup/advance (0) | `sub_115C6`, `Race_ApplyImpactSpeedLoss` | `[static]` | dual-use: curve-scale accumulator while riding; impact magnitude decayed by `*$2000>>16` |
| `$2E` | word | (unnamed) | `sub_115C6`; `Race_AdvanceActorProgress` (0) | `sub_115C6`; crash (`>=$2D`), `sub_12BD2` (`>=$1E`) | `[static]` | none: speed-loss accumulator (crash thresholds) |
| `$30` | word | `RaceActor_PosY` | road-band clamp (AI/shadow); `Race_InitActorPositions`; `Race_SetupActor`; AI restore from `$1A` | movement start (-> `$1A`); `Race_HandleInputOnFoot`; collision/sprite projection | `[confirmed]` E1-1: `$30 = $00-$36` at `0x10FE4`; `$1A` keeps the previous frame | road-relative Y (`drawY - RoadYTarget`) |
| `$32` | word | `RaceActor_CollisionOffset` | `sub_115C6` collision path | pair collision; copied to `$1C` | `[static]`; zero outside contact | - |
| `$34` | word | (unnamed) | `Race_BuildActorObjectList` | shape selectors, `Race_ApplyCrashImpact` (`>=3`) | `[confirmed]` E1-3: signed bucket drives the selector; negative sets H-flip `$8000`; not steering | signed shape variant |
| `$36` | word | `RaceActor_RoadYTarget` | movement (`+= curve_step`), fall (`-=`) | road-band clamp | `[confirmed]` E1-1/E1-4: accumulator; `$30 = $00-$36` | - |
| `$38` | word | `RaceActor_CurveDelta` | movement | `sub_115C6` | `[static/dynamic]` `$22B` | - |
| `$3A` | word | `RaceActor_CurveAccum` | movement | `sub_115C6` | `[static/dynamic]` `3` | - |
| `$3C` | word | `RaceActor_CurveStep` | `sub_115C6`, `sub_11A5E`; zeroed by `Race_SetupActor`/`sub_13A26`/`sub_13A5C` | - | `[confirmed]` E1-4: write-only curve-step snapshot. Not a timer (R30 "timer" label was a misread; the timers are `$78` fall/curve, `$70` animation, `$56` respawn) | none |
| `$3E` | word | `RaceActor_Curve` | `Race_UpdateBikeCurve` (zero/`(limit<<8)/(d0>>8)`); read by `Race_UpdateLeanCurve` | `Race_UpdateActorSpeedState`, `Race_UpdateLeanCurve` | `[confirmed]` E2-3 forced limit: `$3E = (limit<<8)/(d0>>8)`, bit5 set | - |
| `$40` | word | `RaceActor_LeanCurve` | `Race_UpdateBikeCurve` (zero), `Race_UpdateLeanCurve` | lean/curve math | `[static]` | `$40` not sampled in E2-2/E2-3 |
| `$42` | word | `RaceActor_Lean` | `Race_UpdateBikeLean` | `sub_113CA` -> `$0C` | `[confirmed]` E2-2: sign follows steering; formula `race_speed.md` | - |
| `$44` | word | (unnamed) | `sub_12BD2`, `sub_12C9A` | - | `[static]` write-only | unused/reserved |
| `$46` | word | `RaceActor_CurveDirection` | `Race_SteerTowardTarget`, `Race_UpdateActorRoadSteering`, `Race_ClampActorY` | movement/steer handlers | `[dynamic]` `-$03`; L2 formula in `race_speed.md` | none: readers documented in `race_ai.md`/`race_speed.md` |
| `$48` | word | (unnamed) | - (VScroll `$48(a0)` only) | - | `[static]` not an actor field | unused for actors |
| `$4A` | word | `RaceActor_CollisionExtent` | collision path | `Race_UpdateCollision` | `[dynamic]` `$0D`/`$0E` | - |
| `$4C` | word | `RaceActor_CollisionExtentUpper` | `Race_GetCollisionExtent` | pair separation | `[static/dynamic]` | - |
| `$4E` | word | `RaceActor_CollisionExtentLower` | `Race_GetCollisionExtent` | pair separation | `[static/dynamic]` | - |
| `$50` | word | `RaceActor_AttackReach` | combat/attack | pair impact | `[dynamic]` `$28`/`$19` | - |
| `$52` | word | `RaceActor_AttackOverlap` | combat/attack | pair impact | `[dynamic]` `$42`/`$33` | - |
| `$54` | word | `RaceActor_FallState` | `Race_ApplyFallKnockdown`, random fall helpers `sub_15538`/`sub_1555C`/`sub_15580`, crash resets | `sub_15014` -> `unk_155D0[state]` animation sequence | `[static]` `$11` knockdown; `sub_15014` clamps `> $11` | none: FallState index into `unk_155D0` |
| `$56` | word | `RaceActor_RespawnTimer` | `Race_CreateActors` (`$FFFF`), static updater | static update | `[static/dynamic]` | - |
| `$58` | word | (unnamed) | `Race_UpdateAnimation` (race_anim_audio) | `Race_BuildActorObjectList` copies to actor object `+8` | `[static]` | none: animation frame token |
| `$5A` | word | `RaceActor_AttackCooldown` | combat | `Race_DispatchActorAction` (close-action branch), pursue/attack handlers | `[static]` | - |
| `$5C` | word | `RaceActor_TileBase` | `Race_CreateActors`/`Race_SetupActor`/`Race_SpawnTick` (init), `Race_UpdatePlayerAnimation`/`Race_UpdateActorActions` (regen), `Race_ApplyFallKnockdown` (consume) | `RaceHud_DrawStamina` (bar `>>5`), knockdown | `[confirmed]` E4-B + U-0017: **stamina/health**, not a tile base; regen adds `FrameDelay` below `ram_FF18A8=$500`, then snaps to graphics `+$E` (`$500/$640/$780/$8C0/$A00`); player cap `ram_FF18AA=$A00`; hit `PairImpact*ram_FF18AC` | rename-later `RaceActor_Stamina` |
| `$5E` | word | (unnamed) | `Race_CreateActors` | sprite setup | `[static]` graphics `+$A` | none: sprite graphics field `+$A` |
| `$60` | word | (unnamed) | `Race_CreateActors` | sprite setup | `[static]` graphics `+$C` | none: sprite graphics field `+$C` |
| `$62` | long | (unnamed) | movement/advance (`= Race_ram_ProgressSnapshotB`) | none found | `[static]` | write-only late-race progress snapshot |
| `$64` | word | (unnamed) | - (VScroll/object writers only) | - | `[static]` not an actor field | unused for actors |
| `$66` | word | `RaceActor_Rating` | `Race_CreateActors`, `Race_RecycleActor` | spawn/init speed | `[confirmed]` def byte5*100 | none: rating/skill; recycle reuses it as distance |
| `$68` | byte | `RaceActor_ControlFlags` | `Race_GetInput`, AI, pair test, impact, spawn; bit6 set in `Race_UpdateActorAI`/`Race_UpdateActorActions`, cleared by recycle | AI/movement/impact | `[confirmed]` bit0 impact/speed-loss latch (E4-F), bit1 accel (E2-4 B), bit2 brake (E2-4 A), bit3 off-road (E2-5), bit4 pair-contact/crash latch (E4-F), bit5 curve/fall timer, bit6 AI-active/action-eligible, bit7 finish | L4 bits closed (E4); bit7 L1/L5 |
| `$69` | byte | `RaceActor_StateFlags` | combat/AI, pair test | pair collision, dispatcher | `[confirmed]` bit0 pair X order (E4), bit1 pair Y side (E4-A), bit2 steer/curve, bit3 collision direction (E4-F copy), bit4 attack active, bit5 attack side, bit6 low, bit7 reach contact | none (bit0/1/7 static geometry; combat bits L4) |
| `$6A` | byte | `RaceActor_WeaponAnimFlags` | animation | animation (`bit7`) | `[static]`; zero in demo | animation/impact flag byte (visual residual only) |
| `$6B` | byte | `RaceActor_AttackFlags` | `Race_CreateActors`, combat | combat | `[confirmed]` armed `$02` | - |
| `$6C` | byte | `RaceActor_AttackPhase` | combat | dispatcher/combat | `[confirmed]` | - |
| `$6D` | byte | `RaceActor_AttackTimer` | combat | combat | `[confirmed]` | - |
| `$6E` | byte | `RaceActor_AnimState` | `Race_SetupActor`, impact | AI/animation | `[dynamic]` `$FF` normal | AnimState; crash state 3 scripts decoded in L7, other states visual-only |
| `$6F` | byte | `RaceActor_AnimFrame` | impact/animation | animation | `[dynamic]` | AnimFrame; scripts decoded in L7 |
| `$70` | byte | `RaceActor_AnimTimer` | animation | animation | `[static]`; zero active | animation timer cadence (static/visual residual) |
| `$71` | byte | `RaceActor_Index` | `Race_CreateActors` | target tables/standings | `[confirmed]` 0..15, static `$10/$11`, extra `$12` | - |
| `$72` | byte | `RaceActor_AnimIndex` | `Race_SetupActorSprite` (clamped `$30` band), `Race_BuildTargetCandidates` (0/3 for statics) | animation/candidate buckets, target scan start | `[static/dynamic]` values 3/5 | - |
| `$73` | byte | `RaceActor_Palette` | `Race_CreateActors` | sprite attributes | `[confirmed]` | - |
| `$74` | byte | `RaceActor_ActionProfile` | `Race_CreateActors` (player 0 / def byte1 1..18), `sub_138CE` (static respawn nibble 0..15) | `Race_ActorProfileTable`/`Race_StaticActionTable` | `[static]` profiles 0..18 assigned; 17/19 unassigned; per-level pages in `race_ai.md` | - |
| `$75` | byte | `RaceActor_GraphicsIndex` | `Race_CreateActors` | curve limit / sprite setup | `[confirmed]` | - |
| `$76` | byte | (unnamed) | `Race_UpdateAnimation` (race_anim_audio) | `Race_BuildActorObjectList` (`btst #0`, `move.b`) | `[static]` | none: animation flag byte (bit0) |
| `$77` | byte | (unnamed) | `Race_CreateActors` (def byte4) | none found | `[static]` | dead definition byte (class/tier); never read -> wontfix |
| `$78` | byte | (unnamed) | `Race_CreateActors` (0); `sub_14456` (`$78`); `sub_1446E` (`$1E`); `Race_UpdateBikeCurve` (decrement) | `Race_UpdateBikeCurve` (timer + limit select) | `[static]` R30 corrects v3: the fall handlers arm it, so the `word_14742` limit branch **is reachable** | none: fall/curve timer (rename candidate only) |
| `$7A` | word | (unnamed) | - (VScroll writer only) | - | `[static]` not an actor field | unused for actors |
| `$7C` | word | (unnamed) | - (rearview/VScroll buffer) | `Race_DrawRearviewMirror` (not an actor) | `[static]` not an actor field | unused for actors |
| `$7E` | word | (unnamed) | - (VScroll writer only) | - | `[static]` not an actor field | unused for actors |

## R30 integration (crash/fall contracts, handler tables, U triage)

Integrates the R30 gap disassembly (`race_ai.asm 0x1131A-0x13DDF`,
`race_anim_audio.asm 0x140BC-0x14486`). All contracts below are `[static]`; the L4 task
still owns dynamic confirmation of branch timing and damage.

### Crash/fall handler contracts

| Routine | Inputs / gates | Side effects |
|---|---|---|
| `sub_140EE` on-road crash | `a1` actor, `a0` track object; Speed `$FA0` gate | Speed < `$FA0`: `sub_142FE` + `$68` bit4. Else: `sub_140BC` (X from object), `sub_1438E` (speed-loss latch), SFX by `abs($34)` (`>=3` `sub_15538`; Speed < `$1770` `sub_15580`; else `sub_1555C`), `$6E=0`, `$6F=$FF`. If `ram_FF1768==0`: `sub_142D8`, `Race_SaveActorShadow`, `sub_1436E($C000)`; PlayerA -> `ram_FF1AD6=9`, `BikeDamage += scaled(Speed)/2`; else PlayerA -> `ram_FF1AD6=$F`. Sets `$68` bit4 |
| `sub_141AE` high-speed/off-road crash | `$69` bit3 or Speed < `$FA0` gate | Gate: `sub_142FE` only (no `$68` bit4). Else: `ram_FF18A6=Speed`, `Speed=min(Speed/4,$2710)`, X shifted `$6000` relative to object `$E`, `sub_1438E`, sets `$68` bit4 + `$69` bit3; SFX by `abs($34)`, else FallState `9` when `ram_FF18A6 >= $1F40`, else `5`; `$6E=0`, `$6F=$FF`; same shadow path; PlayerA `BikeDamage += scaled(Speed)` (no `/2`) |
| `sub_142B0` / `sub_142BE` / `sub_142CC` | wrappers around `sub_140EE` | `ram_FF1AD6=$F` / `$17` / set `$6B` bit1 first |
| `sub_142FE` road-Y clamp | `a1` actor; `ram_FF1B14`; `$69` bit1 | `PosY=$1A=ram_FF1B14 +/- (extent+4)`; delta added to `$00`; `FrameDistance==0` -> X/PrevX `-$4000` |
| `sub_1436E` shadow speed scale | `a1`, `d0` 16.16 | shadow(`$71`).Speed = Speed*`d0`>>16; `$C000` = 75% in both crash paths |
| `sub_14404` collision-impact fallback | `a1`; `ram_FF1768`; `$6E` | `sub_1438E`; no active crash -> `$6E=$FF` + clear `$68` bit4; else unless `$6E==3`: FallState 0, `$6E=0`, `$6F=$FF`, `ram_FF1AD6=$F`, and if Speed==0 `sub_140BC`; `$6E==3` -> clear `$68` bit4 |
| `sub_14456` / `sub_1446E` fall timers | `$6E < 3` | set `$68` bit5 and `$78=$78` / `$78=$1E` (arms the `word_14742` curve limit) |
| `sub_140BC` / `sub_142D8` / `sub_1438E` | helpers | X from object `$E`; weapon-anim speed flag; impact speed-loss latch |

Consequence for v3: `$78` is **not** dead. Its two writers are the fall timers above;
`Race_UpdateBikeCurve` decrements it and selects `word_14742` while it is non-zero.

### Handler tables and consumers

| Table | Content | Consumers |
|---|---|---|
| `unk_14744` | 8 action handlers: `sub_140EE`, `sub_14404`, `sub_141AE`, `sub_14456`, `sub_1446E`, `sub_142CC`, `sub_142B0`, `sub_142BE` | `sub_12070` (type-table `+4` index) and `sub_11CC8` (via `unk_147FC`) |
| `unk_147FC` | 128-byte handler index (0..7); `sub_12070` clamps `ram_FF1B0E-$186` to 0..127 | `sub_11CC8` dispatcher |
| `unk_12168` | 9 pointers: index 2 `sub_140EE`, others `sub_1438E` | none: dead data (no reader/address reference) |
| `unk_155D0` | 18 FallState (`0..$11`) -> animation-sequence pointers | `sub_15014`, `sub_151F0` |
| `Race_TrackObjectTypeTable` | 19 x 8 bytes: `+0` render flags, `+2` size 16.8, `+4` handler index, `+6` word (`+7` steerable) | `sub_12070`, `sub_13D44`, `sub_13DE0`, `race_ai_road.asm:1767` |

### Track-object records

A track-object record (4 bytes, the record cursor list) is `+0` long 16.16 X, `+2`
type byte (index into `Race_TrackObjectTypeTable`), `+3` lane byte (low nibble used).
The side test is `lane*$20-$100` XOR the actor `PosY` sign (`$30` for `sub_13DE0`).

### U-0012..U-0016 verdicts

| ID | Verdict | Evidence |
|---|---|---|
| `U-0012` | confirmed | `$8` signed Y velocity, `$22` = velocity*FrameDelay applied to `$00`, `$20` fixed shadow stand-off (same in `Race_HandleInputOnFoot`); `sub_1131A` has no caller |
| `U-0013` | confirmed | `$E` whole-track advance, `$10` final curve index; 256-entry buffer `$FFDC58-$FFDE57`; forward wrap `$FFDE58`, backward wrap `$FFDD56` (index 127) |
| `U-0014` | confirmed | record/type-table decode above; side test = lane vs PosY sign |
| `U-0015` | wontfix | `sub_14DEC` returns `d0=0` always (`$12(a1)` read twice, likely meant `a2`) and has no caller/pointer reference -> vestigial |
| `U-0016` | wontfix | `unk_12168` has no reader/address reference -> dead data |

## L3 static addendum (loop, targets, dispatch)

Full per-function contracts are in `race_ai.md`; this is the matrix/queue view.
No ROM bytes changed and no renames.

Frame order relevant to L3:

```
sub_1383E                ; clear candidate counts
Race_UpdateActorAI       ; move actors; SetupActorSprite adds candidates
Race_UpdateStaticActors  ; move static actors; BuildTargetCandidates adds them
sub_138CE                ; static respawn/profile assignment
... collision helpers (L4) ...
Race_UpdateActorActions  ; profile choice + action handler
Race_UpdateStaticActions ; static action handler
Race_UpdateNearestTarget
```

Target pipeline:

| Step | Contract |
|---|---|
| Register | `Race_SetupActorSprite` / `Race_BuildTargetCandidates` -> `Race_AddTargetCandidate` (`ram_FF178A` counts, `ram_FF1792` six 16-byte lists) |
| Find | `Race_FindTargetActor(d0)` -> `Race_ScanTargetDistance`: skip self, signed relative speed, candidate ahead, keep `min(dX/relSpeed)` in `ram_FF1B46` |
| Choose | `Race_UpdateActorSpeedCurve`: scan outward from `AnimIndex`; special target `$71=$10/$11` starts at bucket 2/5; two nearest ratios, smaller wins |
| Steer | `Race_SteerTowardTarget` / `Race_UpdateActorRoadSteering` -> `$46`, `$69` bit2 |

`$74` assignment/families:

| Source | Values |
|---|---|
| Player def byte1 | 0 |
| Opponent def byte1 | 1..18 |
| Static init | 0 |
| `sub_138CE` respawn | `(rand & $F0)>>4` = 0..15 |

- Profiles 17 and 19 are unassigned (definition pages stop at 18; static nibble at 15).
- Profile 1 is the leader family (`Recovery`/`EvadePlayer`); profiles 2-5 and 12-15
  are throttle families; 6-11 and 16-19 are road-center families. `+8` is
  `FollowPath` for 1-11 and `StateCollision` for 12-19. `+10` selects the four combat
  actions, or `RandomCombatChoice` (10) / `ProximityReaction` (11).
- The per-level `name=profile` pages are listed in `race_ai.md`.
- `Race_ActorNormalVariant` is the `+4` slot of profile 0; the player always takes
  the base slot and static actors use the static table, so that table slot is
  unreachable through `Race_UpdateActorActions`.

Budget and static dispatch:

- `ram_FF1A96 = unk_259B6[level-1] = [2,3,3,3,4]`; `ram_FF1A98` counts the
  actors that took the `+4` dispatcher slot this frame (every `+4` path increments).
- `Race_StaticActionTable`: 16 entries = `handler` (`Race_ClampActorY`) + speed +
  Y-offset. `sub_138CE` uses speed/Y-offset at respawn; `Race_UpdateStaticActions`
  uses only the handler.
- Dispatcher slot offsets are `+0` action0, `+4` action1 (dispatch), `+8` action2,
  `+C` action3, `+10` action4; `Race_DispatchActorAction` receives the action1
  pointer in `a4` and picks `4/8/C(a4)`.

Matrix rows touched by L3: `$5A` is read by `Race_DispatchActorAction` (cooldown
branch); `$68` bit6 is set/cleared in `Race_UpdateActorAI`/`Race_UpdateActorActions`;
`$74` is written only by `Race_CreateActors` (definition byte1 / 0) and `sub_138CE`
(random nibble). Experiment Pack E3 in `race_captures.md` is the residual dynamic pass.

## L4 addendum (pair collision, impact, fall)

Full contract: `docs/analysis/race_impact.md`. Matrix v7 delta:

- `$68` bit4 = pair-contact/crash latch (set at `0x127EA`, every crash handler);
  `$68` bit0 = impact/speed-loss latch (`Race_ApplyCollisionImpact`,
  `Race_ApplyImpactSpeedLoss`, `sub_1438E`).
- `$69` bit0 = pair X order, bit1 = pair Y side, bit3 = collision direction copied
  across the pair, bit7 = reach contact.
- `$5C` is **stamina/health** (HUD `RaceHud_DrawStamina`, regen toward
  `ram_FF18AA=$A00`/`ram_FF18A8=$500`, consumed by knockdown). Not a tile base.
- `ram_FF1768` = "current player is in a crash/fall animation"; `Race_ScaleImpactDamage`
  returns 0 while it is set, preventing repeated damage during one crash.
- New constants: `ram_FF3038` X window (`$6000`/`$3700`), `ram_FF303C` extent base
  (`$10`/`$37`/`$60`), `ram_FF303E` penetration threshold (`$40`), `ram_FF3040` side
  state, `ram_FF18AC` stamina hit scale (`$10`), `ram_FF18B6` track-position scale
  (`$1400`).

Pair/impact chain (detail in `race_impact.md`):

```
Race_UpdateActorPairCollision   ; order/side/extent/reach, ContactFlags bit4 latch
  -> Race_UpdateActorPairImpact ; gap >= ram_FF3038 -> exchange, else clamp+attack
     -> Race_ExchangeCollisionSpeed   ; ~0.1x speed delta, speeds equalize, X push $7000
     -> Race_ClampActorPairY          ; Y separation using $4C/$4E + $10
     -> Race_StealClub / Mirror       ; club transfer, $52 pair impact
     -> Race_ApplyFallKnockdown       ; $5C -= PairImpact*ram_FF18AC -> fall at underflow
  ; the coordinator calls the impact handler when ContactFlags bit4 is set:
  -> Race_ApplyCollisionImpact  ; deep (<$40): damage = ScaleImpactDamage(|dSpeed|),
                                ;   Speed = a2.Speed + dSpeed/4, $2C/$2A/$2E
                                ; shallow: $2C = Speed>>11, $32 = ram_FF3040, no damage
```

E4 results (traces in `analysis/notes/L4*`):

| Check | Observed | Verdict |
|---|---|---|
| E4-A demo survey (`capture_L4_a.gdb`) | 3600 frames: 9 pair impacts (1 player), 6 clamps, 3 exchanges, 0 knockdown stores, 0 `sub_140EE`/`sub_141AE`/`sub_14404`, 0 `0x14486` | pair/clamp/exchange natural; crashes are not |
| E4-B forced knockdown (`capture_L4_b.gdb`) | `delta = 1*$10 = $10`; `$100->$0F0`; `$08->0` with `$54=$11`, `$6E=0`, `$6F=$FF`, bit4, event `$0F`; a2 underflow reached the `$0D` store | confirmed |
| E4-C VBlank simulated impact call (`capture_L4_c.gdb`) | PSG fault in the artificial interrupt context | failed; superseded by E4-F |
| E4-D/E natural player exchange (`capture_L4_d/e.gdb`) | player exchange reached; speed delta `$3BD` -> `ScaleImpactDamage=0`, BikeDamage unchanged | confirmed (small deltas do no damage) |
| E4-F forced natural static impact (`capture_L4_f.gdb`) | deep: `Speed $2000/$1000 -> $1400`, `BikeDamage=2`, event `$0A`, `$2C=2`, `$2A=$02+$30`, bit0; shallow (`$1C=$80`): Speed unchanged, damage 0, event `$09`, `$2C=4`, `$32=$0002`, bit4 clear/bit0 set | confirmed both branches |

Residual: `sub_140EE`/`sub_141AE` timing stays `[static]` (the demo never crashes);
the next dynamic check is a normal-mode run into a track object. `$5C` regeneration
cap for opponents (`ram_FF18A8` vs graphics `+$E`) is `[static]`.

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
- `$78` is armed by `sub_14456`/`sub_1446E` (`$78`/`$1E`) -> `word_14742` is
  reachable during a fall (v5 correction; the v3 "unreachable" claim was wrong).
- `Race_LoadBikeData` ignores `bikeId*16` and always loads `unk_25AC4[0]`.
- `TrackParam1` is loaded but never read.
- Steering asymmetry at zero: Left adds `ReturnToStraightPower`, Right does not
  (first step `$48` vs `$30` with the loaded block 0).

## L5 spawn/lifecycle (E5)

Full contracts and the E5 table: `docs/analysis/race_spawn.md`.

Four populations share the `$80`-byte actor struct (`$71` = slot index):

| Population | Slots | `$71` | Activation | Recycle |
|---|---|---|---|---|
| Player | `RacePlayerA` | 0 | always | never |
| Loop opponents | `ram_FF1A08` `Struct_9..15` + opponent free list `Struct_2..8` | 2..15 | init / `Race_SpawnOpponent` | `Race_RecycleOpponent` |
| Reserved opponent | `ram_FF1F2A` (`Race_ActorList[1]`) | 1 | `sub_13BF4` rating gate or `Data5` special list | `Race_RecycleActor` special case |
| Static pair | `$FF2EAA`, `$FF2F2A` | `$10`, `$11` | `sub_138CE` timer -> `sub_13A26` | `Race_ClampActorY` (`$68` bit6) |
| Extra static | `$FF2FAA` | `$12` | `shape $186` marker, `ram_FF1B30 >= $1C` | `ram_FF1B30 < 0` clears bit6 |

Static cycle: `sub_138CE` sets timer `(Rand&$FFF)*unk_13A1A[level]>>16`, palette,
side, `$74` profile and `Race_StaticActionTable` Speed/offset; `sub_13A26` respawns at
`PlayerProgress+$208000`; `Race_ClampActorY` deactivates past `$210000`. Extra actor:
X = `(PlayerProgress_integer + ram_FF1B30 - 1)<<16`, Y = `±(Rand&$7FF)`,
Speed `$1770`, then steered by `Race_UpdateExtraStaticActor`.

`Data5` split: normal list `ram_FFD7D4` -> `Race_AddStagedObjects` (track objects);
special list `ram_FFDBD8` -> `sub_13BF4` (reserved opponent; byte 2 = colour/page from
`off_B98A`, mapped by `sub_13CFE` to graphics `page+4` and a definition page).

`[dynamic]` E5 (`capture_L5*.gdb`, `analysis/notes/L5*_trace.txt`):

| Check | Breakpoint / window | Observed | Decision |
|---|---|---|---|
| E5-1 expansion | `0xB970` | level-1 `d7=$CCCC`, `d6=1`; normal `00A70218,01A50118,...`; special `02D6022F,FFFFFFFF` | confirmed |
| E5-2 special spawn | forced X past `$02D60000`, `0x13CFE` | `ram_FF1F2A` X `$02D60000`, page 2, lane `$E0`, Speed `$050C`, cursor -> terminator | confirmed forced |
| E5-3 static assign | `0x1397E` | profiles `0E,01,07,0D,05`; timers `E2,17,474,7D6,415,257`; Speed/offset from table | confirmed |
| E5-4 static respawn | `0x13A26` | 3 natural respawns | confirmed |
| E5-5 extra actor | `0x10B2E`/`0x12972`/`0x12A86` | marker `$11`; init X `$02060000`, Y `$FEC8`, Speed `$1770`, `$68=$40`; 130 updates | confirmed |
| E5-6 natural traffic spawn | `0x16AF6`+ | 631 race ticks, 0 spawns/recycles, active count 8 | static only |

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

## L7 results/HUD addendum (matrix v9)

L7 consumes the simulation state only; it does not write actor fields. Contracts are
in `race_hud.md` (HUD), `race_results.md` (standings/results/money/high score) and
`race_ai_road.md` (`Race_ComputeStandings`).

- HUD cells: `offset = 2*(y*64+x)`, word = `$8000 | palette<<13 | tile`; digit tiles
  are `$1F4+digit`. Time is BCD from `Race_UpdateTime`; place is 1..9 or `$10..$16`
  for 10..16; stamina/bike-HP bars are 8 units per cell (10 cells) with
  green/yellow/red thresholds.
- Needle script: 32 one-sprite frames, 10 bytes each, at `$7DF30` (tilemap `$7E070`);
  speed frame `min(speed/453,31)`, RPM frame `((speed<<16)/divisor)/682` with
  `divisor = (curve[gear]<<2)&$FFFF`.
- Results: `Race_ComputeStandings` -> event keys -> `Race_SortResults` rewrites each
  entry as `value<<16 | actorIndex` (`value=(key>>8)/6`, `$FFFF` = DNF) ->
  best place, `unk_D1A0[place]*level` points to career score + money -> outcome ->
  `Race_BuildStandings` (4-row record) -> high-score table -> password.
- Alternate AnimState-3 crash scripts: `d3=$26>>8` vs `d4=|$22|` selects
  `unk_15CFC` when `d3<d4`; otherwise `unk_15CE0` when the actor is on the
  "behind" side of the player (bit3 clear + behind, or bit3 set + not behind);
  otherwise the default `unk_155D0[FallState]` AnimState-3 script (`$15CC4`).

E7 results (captures `analysis/capture_L7_*.gdb`, traces `analysis/notes/L7_*`):

| Check | Script | Result |
|---|---|---|
| E7-A HUD snapshot | `capture_L7_hud.gdb` | place `$15`, BCD time, stamina `$0500`, HP cell `$8430`, name timer/rank `$2A/$0E`; forced place changes bump the timer |
| E7-B script select | `capture_L7_anim3.gdb` | close -> `unk_15CFC`/`$B2`; behind -> `unk_15CE0`/`$B1`; ahead/mismatch -> `$15CC4`/`$B0` |
| E7-C results | `capture_L7_results.gdb`, `capture_L7_results2.gdb` | forced non-demo finish reaches `Race_ComputeStandings`/`ComputeResults`; place `$0F`, points `1`, money `100->101`, career `0->1`, outcome `$0F` |

## L6a camera/progress/VScroll/HScroll addendum (matrix v10)

L6a covers `Race_UpdateCamera`, `Race_IntegrateTrackCurve`,
`Race_BuildVScrollInfo` and `Race_BuildHScrollTable`; full contracts are in
`race_physics.md` and `race_ai_road.md`.

- Camera: `$68` bit4 clear -> `CameraOffset=0`; otherwise `$6E<2` adds
  `FrameDistance>>4` (negated on `$69` bit3) clamped at `-$7000`, `$6E>=2` decays
  `off -= off>>2`. `PlayerProgress = PlayerA.X - $8000 - CameraOffset`.
  `$1E60 = 3*PosY/4` (`$1E7A` has no writer); `$1E64 = ($32>>1)+$5D` (`$1E7E` has
  no writer). `$1E66` = low word of `$1E64`; `$1E6A` = low word of `PlayerProgress`.
- Curve walk: high-word delta over `Track_CurveBuffer`; `$1E54/$1E56` sums,
  `$1E58/$1E5A` scaled current/next bytes, `$1E50/$1E52 = $1E54/56 + $1E58/5A`;
  `$3274` is `$3236[31]`, the horizon line used by the VScroll.
- VScroll: 16-byte blocks `[cmd,HV,reg7,vsramA,vsramB,next,+C,+E]`. Block 0 is the
  VBlank entry; `$10..$80` are HInt bands, `$90` is the sentinel. A compaction pass
  uses `+E` (negative skip, `<=8` merge) and recomputes the `$8Axx` line gaps.
  E6 runtime chain: `$10 -> $20 -> $50 -> $60 -> $70 -> $80 -> $90` (the `$30/$40`
  bands are compacted away).
- HScroll: 4 bytes/line `[plane A fg, plane B bg]`; plane A three bands
  (`$30EA`, `HIntVScroll/2 + $30FA`, `HIntVScroll + $30F2`), plane B four bands
  (`$30EE`, zero gap, `HIntVScroll/4 + $30FE`, `3*HIntVScroll/4 + $30F6`).
  Lines `$98..$D7` are cleared, `$D8..$E7` get `-((PlayerA.X>>9)&$C0)`, the rest is
  untouched. `HIntVScroll` and the six accumulators are advanced at the end of the
  VScroll builder from `PlayerA $22 * {6000,3000,1800,1800,3000,4800}`.

E6 results (captures `analysis/capture_L6a*.gdb`, traces `analysis/notes/L6a*`):

| Check | Script | Result |
|---|---|---|
| E6-1 camera/progress | `capture_L6a.gdb` | `progress = X-$8000-cam`; `$1E60=$78` from PosY `$A0`; `$1E64=$5D`; `$1E6A` follows the progress low word |
| E6-2 forced camera | `capture_L6a_camforce.gdb` | `FD=$1FE0 -> cam=$1FE`; `AnimState>=2` decays `$1FE->$1AE->...->3` |
| E6-3 VScroll | `capture_L6a.gdb`, `capture_L6a_hint.gdb` | blocks `$10/$20/$50/$60/$70/$80` at lines `$03/$07/$25/$33/$47/$9C`; `$30/$40` compacted |
| E6-4 HScroll | `capture_L6a.gdb` | plane A top `$30EA>>16=$0027`, plane B top `$30EE>>16=$0013`; road line `$80=$017CFFAB` |

`U-0018` is closed: the four compaction phases and `$8A00+E(next2)-E(next)-1` gap
formula reproduce the E6 numbers. `U-0017` is closed too (see L4/`race_impact.md`).
Residual: engine-audio mapping, rearview/marking visuals and the final shape-art
crop stay `[static]`/optional-visual.

## L6b object/projection/visible-list addendum (matrix v11)

L6b covers the per-frame object-record assembly, the four projection helpers and the
visible-list sort. Full contract is in `docs/analysis/race_ai_road.md`; this is the
matrix delta.

- Assembly order: `ram_FFDE72 = 0` -> `Race_AddSpecialObject` ->
  `Race_AddTrackStartObject` -> `Race_BuildActorObjectList` (`ram_FF1B48` =
  actor count) -> `Race_BuildTrackObjects` (`ram_FF1B4A` = track count) ->
  `Race_AddStagedObjects` -> `$FFFFFFFF` distance terminator ->
  `Road_BuildVisibleList` -> `Road_DrawObjects`.
- `Road_ObjectArray` = `$FFD37C..$FFD77B`, 0x14-byte records, max 51; fields
  `+0 X, +2 Y, +4 scale, +6 limit, +8 shape, +$A flags, +$C X offset,
  +$E row/reserved, +$10 reserved, +$12 shape2`; `ram_FFDE72` count.
- Producers and extras: special (fixed `$FEA0/$41/$4000/$E0`), track-start gate,
  near/far actor objects, fall/impact/lean/weapon/shadow extras, track stream, and
  the staged RAM traffic list.
- Projection helpers: `Race_ProjectObject` (`+4 = $A00000/(d+$200)`,
  `+2/+0` from the `ram_FF310A` 4-word row, `+6 = ram_FFD77C[2r]`, returns
  `d0/d1/d2/d3`), `Race_ProjectActorObject` (near actor, `$A00000/$C00000` by
  `$71`), `Race_ProjectActorSprite` (far behind), `Race_ProjectTrackObject`
  (`ram_FF3236/FF31D2/D77C` row tables, lane offset from the type nibble).
- `Flags` low 5 bits carry the projected row `r`; `Road_DrawObject` reads the
  **high byte** `(Flags >> 8) & 7` as the sprite-chain pass count. `U-0019` is
  closed by E8 (row and pass count are different bit fields).
- Track stream: cursor `Race_ram_TrackObjectCursor` / accumulated
  `Race_ram_TrackObjectDistance`; word0 = `[rowCount][shape base]`, word2 =
  `[step-1][flags:3][lane]`; shape `$186` = extra-actor marker (`ram_FF1B30/$1B2E`),
  `$205` = gap, `$1BB..$1E9` = `(shape, shape+1)` pair, `$1EA+` remaps `+$2F`.
- Visible list: signed ascending long insertion sort of `ram_FF1B50` into
  `ram_FF1C50`, parallel word index list in `Road_VisibleObjectList` (`$FF1D50`);
  `Road_DrawObjects` draws in that order. Producers store `objectX - progress`
  (near actor / track / staged) while the far-actor sprite path stores
  `progress - actorX`; the mixed-sign visual result is left to E8.

## L6c shape/pixel/Data4 addendum (matrix v12)

L6c closes the world branch: the shape header / control-byte / offset-list /
tile-writer pixel map and the Data4 side/second-shape/pass-count bits. Full
contract is in `docs/analysis/road_render.md`, `road_shapes.md` and
`race_track_data.md`.

- Shape header (`P` = shape pointer; special/two-part when `RoadObject_Flags` bit15
  is set): normal `P+0/P+1` controls, `P+2/P+3` fill word, `P+4+` row data;
  special `P+0/P+1/P+2` projection/width, `P+2/P+3` controls, `P+4/P+5` fill word,
  `P+6+` row data. The fill word is ORed into the SAT tile word (`$2036` -> palette
  1, tile base `$36` for shape `$56`).
- Interpolators: left emits one source advance per output byte (`ram_FF0D2E`;
  1 = four contiguous bitplane bytes, 0 = duplicate, >1 = skip) and returns
  `ram_FF132E = columns-1`; right emits one advance per source row
  (`ram_FF102E`) and returns `ram_FF1330 = rows-1`. `ram_FF1332` is the
  half-width seed used by the right list; `ram_FF135E` is the clip budget.
- Writer: per row `r`, column `c`, plane `k` -> `base + 4*r + c*(gap+4) + k`.
  The 4 bytes are the 4bpp bitplanes of one 8-pixel scanline, so the destination
  is column-major. Full band gap `ram_FFDE6A=$7C` (stride `$80`, 4 tiles); every
  32 rows add `ram_FFDE68` and switch to `ram_FFDE66` (stride `$60`, 3 tiles) for
  the remainder band. `Road_ClearEdgeTiles` zeroes the unused edge bytes.
- Byte proof: shape `$56` (`base=$FF511C`, `src=$059952`, scale `$10000`,
  `132E=4`, `1330=$35`, `DE66/68/6A=$5C/$200/$7C`) replays 1080/1080 bytes
  identical to `analysis/golden/shape_writer_after.bin`.
- Data4 `+$00`: bits 0-6 shape selector (pair `$1BB..$1E9`, `+$2F` remap,
  `$205` skip), bits 8-12 run count-1, bit14 -> `Flags` bit15 facing, bit15 enables
  side parity, bit7 side seed. Data4 `+$02`: bits 12-15 spacing-1, bits 8-10
  SAT copy-pass count -> `Flags` bits 10-8, low byte -> record `+$10` (lane/scale).
- `Flags` ownership for track objects: low 5 = row, bit7 = second shape, bits 8-10
  = copy passes, bit12 = priority, bit14 = side, bit15 = facing.
- E8 (`analysis/capture_L8_a/b/c.gdb`, traces `analysis/notes/L8*`): live offset
  lists match the generators (`$56` scale `$10000`; `$1C3` scale `$145D0`);
  `$FFD430` (`flags=$1184`, pass=1) copied 6 entries once; `ram_FF1C50` is the
  ascending sorted key list and `ram_FF1D50` the draw order.

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
integrates E1. The L2 static and dynamic passes (`tasks/race_L2_control_a.md`,
`race_L2_control_b.md`) are complete: matrix v4 integrates E2 and closes `U-0011`.
R30 integration (`tasks/race_R30_integration.md`) is complete: matrix v5 adds the
crash/fall contracts and handler tables, corrects `$08/$0E/$10/$3C/$78`, and closes
`U-0012`..`U-0016`. L3 static contracts are in the addendum above, and E3
(`race_L3_ai_dynamic.md`) dynamically confirmed the candidate buckets, profile
slot/budget, dispatcher branches, per-level budget and static respawn indexing.
L4 (`tasks/race_L4_impact_contracts.md`) is now in matrix v7: pair collision,
damage/exchange, stamina `$5C`, knockdown and both `Race_ApplyCollisionImpact`
branches are confirmed; only the R30 crash-path timing remains static. L5
(`tasks/race_L5_spawn.md`) is complete (v8/E5): four populations, `Data5`
normal/special split, reserved opponent, static respawn cycle and extra slot. L7
(`tasks/race_L7_results_hud.md`) is complete (v9/E7): HUD/needle/odometer contracts,
the full results/standings/money pipeline and the `unk_15CE0`/`unk_15CFC` crash
scripts. L6a (`tasks/race_L6_world_a.md`) is complete (v10/E6): camera/progress,
VScroll raster chain and HScroll plane A/B bands. L6b
(`tasks/race_L6_world_b.md`) is complete (v11): object-record assembly, the four
projection helpers, the track-object stream and the visible-list sort/draw contract.
L6c (`tasks/race_L6_world_c.md`) is complete (v12/E8): shape header/control/list
generation, the byte-exact tile-writer pixel map and the Data4 flag/pair/pass-count
bits. The L6 branch is closed; remaining world items are optional visual checks
(shape-art crop, marking/rearview appearance) and the static `U-0017`/`U-0018`.

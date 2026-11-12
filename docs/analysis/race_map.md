# Race map: timeline, dataflow, field ownership and captures

- **Status:** v0 (built from existing analysis docs and RAM snapshots; no new behavior claims)
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

## Actor field ownership matrix v0

Widths match the actual instruction sizes: `$04/$1E/$26` are longs, the
`$68-$78` block is byte-wise, everything else is a word. Offsets inside a long field
(`$06`, `$20`, `$28`) are aliases, not separate rows. "Not documented" means the
existing docs do not identify a writer/reader yet; it is an open question, not a
guess.

| Offset | Width | Symbol | Writers | Readers | Evidence | Open question |
|---|---|---|---|---|---|---|
| `$00` | word | (unnamed) | `Race_InitActorPositions`, movement/static updater via `$36/$38`/`$30` | draw/HUD path | `[dynamic]` steering `$35`, hard-left `$FF89` | exact draw-Y ownership vs `$30` |
| `$02` | word | `RaceActor_PosZ` | not documented | main HInt / endlevel debug | `[static]` | writer/origin |
| `$04` | long | `RaceActor_X` | `Race_InitActorPositions`, `Race_UpdateActorX/Movement/FallMovement`, `Race_InitOpponent/TrafficActor` | target selection, collision, camera | `[confirmed]` `$04=$1E+$26` | - |
| `$06` | word | `RaceActor_XLow` | same as `$04` | same as `$04` | `[confirmed]` low word of `$04` | no independent field |
| `$08` | word | (unnamed) | `Race_SetupActor`, impact/crash paths | animation code | `[static]` | animation/impact register role |
| `$0A` | word | (unnamed) | `Race_SetupActor` | animation code | `[static]` | role |
| `$0C` | word | (unnamed) | `Race_SetupActor`, `Race_ApplyCollisionImpact` | animation code | `[static]` | role |
| `$0E` | word | (unnamed) | not documented | not documented | - | open |
| `$10` | word | (unnamed) | not documented | not documented | - | open |
| `$12` | word | `RaceActor_Speed` | `Race_UpdateActorAI`, `Race_InitOpponent/TrafficActor`, impact | speed display, curve limit, AI | `[confirmed]` Player `$EE`, steering `$2D15` | - |
| `$14` | word | `RaceActor_Acceleration` | `Race_UpdateActorSpeedState` | `Race_UpdateActorAI` | `[confirmed]` `$22` low speed, `$0E` at `$2D15` | gear-table branch coverage |
| `$16` | word | `RaceActor_Type` | `Race_CreateActors` | `Race_UpdateStaticActors`, speed state | `[confirmed]` 2/3/4; static anomaly | static `$16=0` after update |
| `$18` | word | `RaceActor_Gear` | `Race_UpdateActorSpeedState` | `Race_UpdateActorSpeedState` | `[static]`; demo kept `0` | upshift condition |
| `$1A` | word | (unnamed) | `Race_UpdateActorMovement/X`, `Race_SetupActor` | movement/curve math | `[dynamic]` `$31` vs `$30=$35` | exact previous-Y semantics |
| `$1C` | word | `RaceActor_PreviousCollisionOffset` | movement backup from `$32` | `Race_ApplyCollisionImpact` | `[static]` | - |
| `$1E` | long | `RaceActor_PreviousX` | `Race_UpdateActorX/Movement/FallMovement`, spawn setup | target scans, impact | `[confirmed]` `$04-$1E=$26` | - |
| `$22` | word | (unnamed) | `Race_UpdateActorPairImpact` (adds `AttackOverlap`) | not documented | `[static]` | X/Y screen delta role |
| `$24` | word | (unnamed) | not documented | not documented | `[dynamic]` zero under steering | open |
| `$26` | long | `RaceActor_FrameDistance` | `Race_UpdateActorAI`, movement | movement | `[confirmed]` `Speed*FrameDelay` | - |
| `$2A` | word | (unnamed) | `Race_ApplyCollisionImpact/Crash`, `sub_115C6` | impact/render | `[static/dynamic]` `$1C39`, `$223` | projection origin |
| `$2C` | word | (unnamed) | `Race_ApplyCollisionImpact`, `sub_115C6` | impact | `[static]` | impact scale vs curve state |
| `$2E` | word | (unnamed) | `Race_ApplyCollisionImpact`, `sub_115C6` | impact | `[static]` | speed-loss accumulator |
| `$30` | word | `RaceActor_PosY` | movement clamp, `Race_SetupActor` | HUD/HInt, movement | `[dynamic]` `$A0`, hard-left `$FFEA` | - |
| `$32` | word | `RaceActor_CollisionOffset` | collision path | pair collision | `[static]`; zero outside contact | - |
| `$34` | word | (unnamed) | not documented | `Race_ApplyCrashImpact` (`>=3` test) | `[static]` | role |
| `$36` | word | `RaceActor_RoadYTarget` | movement (`+= curve_step`) | Y clamp | `[static/dynamic]` `5` | target vs accumulator wording |
| `$38` | word | `RaceActor_CurveDelta` | movement | `sub_115C6` | `[static/dynamic]` `$22B` | - |
| `$3A` | word | `RaceActor_CurveAccum` | movement | `sub_115C6` | `[static/dynamic]` `3` | - |
| `$3C` | word | `RaceActor_CurveStep` | movement | `sub_115C6` | `[static/dynamic]` `0` | observed write-only |
| `$3E` | word | `RaceActor_Curve` | `Race_UpdateBikeCurve` | `Race_UpdateActorSpeedState` | `[static]` | limit branch coverage |
| `$40` | word | `RaceActor_LeanCurve` | `Race_UpdateBikeCurve` | lean/curve math | `[static]` | - |
| `$42` | word | `RaceActor_Lean` | `Race_UpdateBikeLean` | not documented | `[confirmed]` `±$49` | readers |
| `$44` | word | (unnamed) | not documented | not documented | - | open |
| `$46` | word | `RaceActor_CurveDirection` | `Race_SteerTowardTarget`, `Race_ClampActorY` | static action / clamp | `[dynamic]` `-$03` | sign convention |
| `$48` | word | (unnamed) | not documented | not documented | - | open |
| `$4A` | word | `RaceActor_CollisionExtent` | collision path | `Race_UpdateCollision` | `[dynamic]` `$0D`/`$0E` | - |
| `$4C` | word | `RaceActor_CollisionExtentUpper` | `Race_GetCollisionExtent` | pair separation | `[static/dynamic]` | - |
| `$4E` | word | `RaceActor_CollisionExtentLower` | `Race_GetCollisionExtent` | pair separation | `[static/dynamic]` | - |
| `$50` | word | `RaceActor_AttackReach` | combat/attack | pair impact | `[dynamic]` `$28`/`$19` | - |
| `$52` | word | `RaceActor_AttackOverlap` | combat/attack | pair impact | `[dynamic]` `$42`/`$33` | - |
| `$54` | word | `RaceActor_FallState` | `Race_ApplyFallKnockdown` | crash/fall path | `[static]` `$11` | player-specific delay? |
| `$56` | word | `RaceActor_RespawnTimer` | `Race_CreateActors` (`$FFFF`), static updater | static update | `[static/dynamic]` | - |
| `$58` | word | (unnamed) | not documented | not documented | - | open |
| `$5A` | word | `RaceActor_AttackCooldown` | combat | dispatcher | `[static]` | - |
| `$5C` | word | `RaceActor_TileBase` | `Race_CreateActors`, `Race_SetupActor`, knockdown budget | animation/impact | `[confirmed]` Player `$A00 -> $507` | dual tile-base/health role |
| `$5E` | word | (unnamed) | `Race_CreateActors` | sprite setup | `[static]` graphics `+$A` | exact sprite field |
| `$60` | word | (unnamed) | `Race_CreateActors` | sprite setup | `[static]` graphics `+$C` | exact sprite field |
| `$62` | word | (unnamed) | not documented | not documented | - | open |
| `$64` | word | (unnamed) | not documented | not documented | - | open |
| `$66` | word | `RaceActor_Rating` | `Race_CreateActors`, `Race_RecycleActor` | spawn/init speed | `[confirmed]` def byte5*100 | recycle distance reuse |
| `$68` | byte | `RaceActor_ControlFlags` | `Race_GetInput`, AI, impact, spawn | AI/movement/impact | `[confirmed]` bit6 active | bit0/4/5/7 split |
| `$69` | byte | `RaceActor_StateFlags` | combat/AI | pair collision, dispatcher | `[confirmed]` attack bits; `$04` steering | bit0/1/7 split |
| `$6A` | byte | `RaceActor_WeaponAnimFlags` | animation | animation | `[static]` | role |
| `$6B` | byte | `RaceActor_AttackFlags` | `Race_CreateActors`, combat | combat | `[confirmed]` armed `$02` | - |
| `$6C` | byte | `RaceActor_AttackPhase` | combat | dispatcher/combat | `[confirmed]` | - |
| `$6D` | byte | `RaceActor_AttackTimer` | combat | combat | `[confirmed]` | - |
| `$6E` | byte | `RaceActor_AnimState` | `Race_SetupActor`, impact | AI/animation | `[dynamic]` `$FF` normal | state mapping |
| `$6F` | byte | `RaceActor_AnimFrame` | impact/animation | animation | `[dynamic]` | frame mapping |
| `$70` | byte | `RaceActor_AnimTimer` | animation | animation | `[static]`; zero active | cadence |
| `$71` | byte | `RaceActor_Index` | `Race_CreateActors` | target tables/standings | `[confirmed]` 0..15, static `$10/$11`, extra `$12` | - |
| `$72` | byte | `RaceActor_AnimIndex` | `Race_SetupActorSprite` | animation | `[static/dynamic]` values 3/5 | - |
| `$73` | byte | `RaceActor_Palette` | `Race_CreateActors` | sprite attributes | `[confirmed]` | - |
| `$74` | byte | `RaceActor_ActionProfile` | `Race_CreateActors` | action/profile tables | `[confirmed]` profiles 0..19 | static profile assignment |
| `$75` | byte | `RaceActor_GraphicsIndex` | `Race_CreateActors` | curve limit / sprite setup | `[confirmed]` | - |
| `$76` | byte | (unnamed) | not documented | not documented | - | open (`$77` is byte) |
| `$77` | byte | (unnamed) | `Race_CreateActors` (def byte4) | not documented | `[static]` | meaning (class/tier?) |
| `$78` | byte | (unnamed) | `Race_ApplyCrashImpact` (`$1E` hold) | bike-curve timer use | `[static]` | timer vs state flag |
| `$7A` | word | (unnamed) | not documented | not documented | - | open |
| `$7C` | word | (unnamed) | not documented | not documented | - | open |
| `$7E` | word | (unnamed) | not documented | not documented | `[dynamic]` zero | open |

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

The next task after this map is `tasks/race_L1_actor_core_a.md` (field matrix v1 +
Experiment Pack E1), per `tasks/race_understanding_program.md`.

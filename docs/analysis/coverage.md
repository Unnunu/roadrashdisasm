# Coverage dashboard

- **Goal:** move from byte-exact ROM to complete semantic understanding.
- **Audio:** deferred to a separate workstream (68k interface already partly mapped).
- **Source of truth:** module cards, `docs/analysis/`, `docs/callgraph.md`,
  `tools/field_usage.py`.
- **Rule:** do not re-read documented code; close one unknown per durable artifact.

## Understanding levels

| Level | Meaning | Target |
|---|---|---|
| U0 | Byte-exact ROM | **done** |
| U1 | Structure: ranges, symbols, functions, data boundaries | all ROM |
| U2 | Behavior: contracts, algorithms, dataflow, formats | all non-audio systems |
| U3 | Dynamic/visual confirmation | player-visible systems |
| U4 | Design/why | where evidence exists |

## Area status

Legend: `[x]` done, `[~]` partial, `[ ]` not started.

| Area | Modules | U1 | U2 | U3 | U4 | Main gap |
|---|---|---|---|---|---|---|
| Boot/runtime/IRQ/input | `main`, `top_level`, `fade` | [x] | [~] | [~] | [~] | HInt/input helper semantics, state transitions |
| Logo/intro | `logoEA`, `intro` | [x] | [~] | [~] | [~] | exact title visuals/timing |
| Menus/screens | `menu_*`, `message`, `shop`, `highscore`, `endlevel`, `race_results`, `rider_intro` | [x] | [~] | [~] | [~] | non-demo captures; shop layout user-described |
| Race core/HUD/spawn | `race_core`, `race_hud*`, `race_spawn` | [x] | [~] | [~] | [~] | residual fields, dynamic HUD/spawn paths |
| Actor AI/movement/combat | `race_ai`, `race_combat`, `race_anim_audio` | [x] | [~] | [~] | [~] | AI/collision fields, helper contracts |
| Physics/collision/road marking | `race_physics`, `road_marking` | [x] | [~] | [~] | [~] | table offsets, visual confirmation |
| Road render/shapes | `road_render`, `road_shapes` | [x] | [~] | [~] | [~] | shape row bytes, interpolation/projection |
| Track/data formats | `track_data`, `race_track_data`, `race_*_tables`, `race_misc_data` | [x] | [~] | [~] | [~] | stream/channel/table field meanings |
| Decompression | `uncompress` | [x] | [x] | [~] | [~] | remaining edge cases |
| Audio (separate) | raw bridge, `z80_driver` | [~] | [~] | [ ] | [ ] | Z80 driver, sequencer, sound data |
| Asset tail | `rom_assets` | [x] | [~] | [ ] | [ ] | asset identification/bounds/consumers |
| Random/helpers | `Rand_NextWord`, `PiecewiseLinearInterpolation`, `Race_FormatDecimal` | [x] | [~] | [ ] | [~] | contracts mostly clear; callers |

## Current work queue

Generated from `docs/callgraph.md`, `tools/field_usage.py`, and current TODOs.
Priority is analytical impact, not address order.

| # | Target | Unknown / why | Next experiment | Artifact |
|---|---|---|---|---|
| 1 | `Race_UpdateActorPairCollision`, `sub_12070`, `sub_12414`, `sub_11CC8` | `$32/$4C/$4E/$56`, side-extent mapping | **done:** `$4C` upper / `$4E` lower by Y ordering (forced pair trace); `$32` offset; `$56` timer TODO | collision contract + field matrix |
| 2 | `Race_UpdateActorSpeedState`, `Race_UpdateActorSpeedGear` | gear/speed/curve branch semantics | **done:** demo trace + `race_speed.md`; gear=0 remains TODO | speed/gear contract |
| 3 | `Race_FindTargetActor`, `Race_SaveActorShadow` | **done:** candidate buckets, ratio scan, shadow role | target contract documented | `race_ai.md` |
| 4 | `Race_UpdateActorMovement/FallMovement`, `sub_115C6` | exact `$36–$3C` roles | normal/steer/off-road/fall snapshots | movement matrix update |
| 5 | `Race_GetCurveSpeedLimit`, `Race_UpdateBikeCurve`, `Race_UpdateLeanCurve` | **done:** curve/lean/gear contract; gear=0 edge TODO | high-speed steering trace | `race_speed.md` |
| 6 | Road render helpers: `Race_ProjectObject`, `Race_ProjectActorObject`, `Road_DrawStrip`, `Road_WriteTileColumns` | exact row/tile mapping | **progress:** shape record layout + row start confirmed; SAT/VSRAM next | render/shape doc |
| 7 | `Race_ApplyCollisionImpact`, `Race_ApplyCrashImpact`, impact chain | `$2A/$2C/$2E/$54/$5C` and damage timing | **progress:** contract + demo call hit; return-state trace next | `race_impact.md` |
| 8 | Track/shape data formats | **done:** Data2/3 decoder, Data4/5/6 formats; remaining Data4 side bits | compare staged/service consumers | format spec |
| 9 | Screens flow | non-demo inputs/visuals | **progress:** demo flow + menu entry; `screens_flow.md`; input injection next | screen state machines |
| 10 | Asset tail | labels/bounds/consumers | inventory length/pointers/visuals | asset catalogue |
| 11 | Audio (separate) | Z80 driver/sequencer/SFX | mailbox + music trace | audio spec |

## Phase checklist

- [x] Phase 0: coverage baseline and work queue.
- [ ] Phase 1: runtime, IRQ, input, RAM ownership.
- [~] Phase 2: race simulation semantics (targeting/speed/collision done; impact/movement residual).
- [~] Phase 3: road/render and data formats (Data4/5/6 mapped; row/tile mapping in progress).
- [~] Phase 4: screens and visual confirmation (flow mapped; non-demo/visual captures pending).
- [ ] Phase 5: audio/Z80, separate.
- [ ] Phase 6: asset tail catalogue.
- [ ] Phase 7: consolidation and acceptance.

## Acceptance criteria

- Every ROM range classified as code/data/asset/raw.
- Every player-visible function has L1/L2 contract and U3 evidence.
- No unexplained high-fan-in actor/RAM field.
- Every data blob has format, bounds, and consumers.
- Every screen has state machine, inputs, and dynamic evidence.
- Audio has its own acceptance spec; it does not block non-audio completion.
- `./build.sh` stays `Matched OK` after every batch.

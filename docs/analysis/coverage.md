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
| Race core/HUD/spawn | `race_core`, `race_hud*`, `race_spawn` | [x] | [~] | [~] | [~] | L1 actor core done (matrix v2, E1); L2 static control done (matrix v3); HUD/spawn dynamics pending |
| Actor AI/movement/combat | `race_ai`, `race_combat`, `race_anim_audio` | [x] | [~] | [~] | [~] | L2 input/lean/curve/speed static contract done; R30 gap set (`0x1131A`-`0x14486`) disassembled; E2 dynamic checks + `U-0012`..`U-0016` pending |
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
| 2 | `Race_UpdateActorSpeedState`, `Race_UpdateActorSpeedGear` | gear/speed/curve branch semantics | **done:** static L2 contract (`race_speed.md`); gear word = 5 in the dump (old byte read was an artifact); E2 in `race_L2_control_b.md` | speed/gear contract |
| 3 | `Race_FindTargetActor`, `Race_SaveActorShadow` | **done:** candidate buckets, ratio scan, shadow role; L1 matrix v2 closes the struct/list/shadow ownership (E1 integrated) | target contract documented | `race_ai.md`, `race_map.md` |
| 4 | `Race_UpdateActorMovement/FallMovement`, `sub_115C6` | **done:** E1 closed `$36` accumulator, `$38/$3A` movement updates, `$3C` write-only step | fall/movement edge coverage | movement matrix update |
| 5 | `Race_GetCurveSpeedLimit`, `Race_UpdateBikeCurve`, `Race_UpdateLeanCurve` | **done:** formulas + table decode (`race_speed.md`, `race_data_tables.md`); dead `$78`/`word_14742` branch noted | E2-2/E2-3 forced-steer trace | `race_speed.md` |
| 6 | Road render helpers: `Race_ProjectObject`, `Race_ProjectActorObject`, `Road_DrawStrip`, `Road_WriteTileColumns` | exact row/tile mapping | **progress:** shape record layout + row start confirmed; SAT/VSRAM next | render/shape doc |
| 7 | `Race_ApplyCollisionImpact`, `Race_ApplyCrashImpact`, `sub_140EE`/`sub_141AE`/`sub_14404`, `unk_14744`/`unk_147FC` | `$2A/$2C/$2E/$54/$5C`, damage timing, action-handler table | **progress:** impact/action handlers + tables decoded (R30); dynamic branch trace next | `race_impact.md`, `race_anim_audio.md` |
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

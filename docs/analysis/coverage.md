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
| Race core/HUD/spawn | `race_core`, `race_hud*`, `race_spawn` | [x] | [x] | [~] | [~] | Accepted (`analysis/acceptance.md`): L1/L2 (E1/E2), R30 (v5), L5 (E5), L7 (E7, v9), U-0017; four populations, `Data5` split, reserved opponent, static respawn, extra slot; stamina regen/baseline; HUD cells/needle/odometer, standings/results/money and crash-script selection confirmed |
| Actor AI/movement/combat | `race_ai`, `race_combat`, `race_anim_audio` | [x] | [x] | [~] | [~] | Accepted (`analysis/acceptance.md`): L2 (E2), R30 (v5), L3 (E3, v6), L4 (E4, v7); target/scan/dispatch, `$74` pages/families, budget, static action table, pair collision/extent/reach, damage/exchange, stamina/knockdown; crash-handler timing waived (R-06) |
| Physics/collision/road marking | `race_physics`, `road_marking` | [x] | [x] | [~] | [~] | Accepted (`analysis/acceptance.md`): L6a camera/VScroll/HScroll (E6, v10); U-0018 compaction closed (v13); L6b actor/object projection (v11); rearview/marking visuals remain out of scope |
| Road render/shapes | `road_render`, `road_shapes` | [x] | [x] | [~] | [~] | Accepted (`analysis/acceptance.md`): L6b object/visible-list + projection (v11); L6c shape/control/interpolator/tile-writer pixel map + Data4 bits (v12/E8); remaining: shape-art catalogue and visual crop (out of scope) |
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
| 2 | `Race_UpdateActorSpeedState`, `Race_UpdateActorSpeedGear` | **done:** static L2 contract + E2 dynamic (`$18` word, `+E`/`+1A` thresholds, same-call oscillation, max-gear `-5`, off-road `$14>>2`) | `race_speed.md` | speed/gear contract |
| 3 | `Race_FindTargetActor`, `Race_UpdateActorActions`, `Race_DispatchActorAction` | **done static+dynamic:** candidate bucket/scan, profile choice (`$74` pages/families), budget `ram_FF1A96/98`, dispatcher slots; E3 confirmed slot/budget/branches/levels/static respawn; L5/E5 closed the spawn/lifecycle layer; L7/E7 closed HUD/results | L6 world branch | `race_ai.md`, `race_spawn.md`, `race_map.md`, `race_hud.md`, `race_results.md` |
| 4 | `Race_UpdateActorMovement/FallMovement`, `sub_115C6`, `sub_11A5E` | **done:** E1 closed `$36` accumulator, `$38/$3A` movement updates; R30 closed `$3C` (write-only step, not a timer) and `$0E/$10` (write-only advance/index) | fall/movement edge coverage | movement matrix v5 |
| 5 | `Race_GetCurveSpeedLimit`, `Race_UpdateBikeCurve`, `Race_UpdateLeanCurve` | **done:** formulas + table decode + E2-2/E2-3 (`$42/$0C` sign, `$3E=(limit<<8)/(d0>>8)`; TP0 dynamic, TP2/TP3 static); R30 corrected `$78`: armed by the fall handlers, so `word_14742` is reachable | `race_speed.md` | speed/curve contract |
| 6 | `Race_UpdateCamera`/`IntegrateTrackCurve`/`BuildVScrollInfo`/`BuildHScrollTable` | L6a camera/progress and HInt tables | **done:** E6 (v10) camera branches, progress aliases, VScroll chain; U-0018 four-phase compaction/gap formula closed in v13; HScroll bands | `race_physics.md`, `race_ai_road.md` |
| 6b | Road render helpers: `Race_ProjectObject`, `Race_ProjectActorObject`, `Road_DrawStrip`, `Road_WriteTileColumns` | exact row/tile mapping | **done (L6b+L6c):** object producers/projection/visible list (v11); shape control -> offset lists -> byte-exact column-major tile map and Data4 flags (v12/E8) | `race_ai_road.md`, `road_render.md`, `race_map.md` (v12) |
| 7 | `Race_ApplyCollisionImpact`, `Race_ApplyCrashImpact`, `sub_140EE`/`sub_141AE`/`sub_14404`, `unk_14744`/`unk_147FC` | `$2A/$2C/$2E/$54/$5C`, damage timing, action-handler table | **done static+dynamic (L4/E4):** both `Race_ApplyCollisionImpact` branches, damage/exchange, `$5C` stamina and knockdown confirmed; R30 crash handlers static-only (demo never crashes) | `race_impact.md`, `race_map.md` |
| 8 | Track/shape data formats | **done:** Data2/3 decoder, Data4/5/6 formats, Data5 normal/special consumer split, Data4 side/second-shape/pass-count bits | compare staged/service consumers | format spec |
| 9 | Screens flow | non-demo inputs/visuals | **progress:** demo flow + menu entry; `screens_flow.md`; input injection next | screen state machines |
| 10 | Asset tail | labels/bounds/consumers | inventory length/pointers/visuals | asset catalogue |
| 11 | Audio (separate) | Z80 driver/sequencer/SFX | mailbox + music trace | audio spec |

## Phase checklist

- [x] Phase 0: coverage baseline and work queue.
- [ ] Phase 1: runtime, IRQ, input, RAM ownership.
- [x] Phase 2: race simulation semantics accepted (`analysis/acceptance.md`); residual dynamic samples waived.
- [x] Phase 3: road/render and data formats (Data2..6 mapped; L6a camera/HInt, L6b object/projection/visible-list and L6c shape/pixel/Data4 map done; only optional visual catalogues remain).
- [~] Phase 4: screens and visual confirmation (flow mapped; non-demo/visual captures pending).
- [ ] Phase 5: audio/Z80, separate.
- [ ] Phase 6: asset tail catalogue.
- [x] Phase 7: race-subsystem consolidation and acceptance (`analysis/acceptance.md`); non-race phases remain open.

## Acceptance criteria

- Every ROM range classified as code/data/asset/raw.
- Every player-visible function has L1/L2 contract and U3 evidence.
- No unexplained high-fan-in actor/RAM field.
- Every data blob has format, bounds, and consumers.
- Every screen has state machine, inputs, and dynamic evidence.
- Audio has its own acceptance spec; it does not block non-audio completion.
- `./build.sh` stays `Matched OK` after every batch.
- Race-subsystem acceptance: `analysis/acceptance.md` (A1-A7 pass; residuals waived).

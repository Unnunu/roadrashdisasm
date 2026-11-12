# Documentation index

Read this index first. Then open only the file needed for the current task.

For a build session, use the fast path: `STATE.md` + task file + target source + its
analysis/module card, then `line-by-line-checklist.md`. Large registries
(`callgraph.md`, `ram-map.md`, `analysis/identifiers.md`) are lookup tables: grep the
symbol/row and read only that slice.

## Top-level

| File | When to read |
|---|---|
| `architecture.md` | ROM layout, boot flow, screen/module map, high-level ownership. |
| `callgraph.md` | Find callers/callees or navigate the function graph (grep by symbol). |
| `coding-style.md` | Naming, comments, headers, RAM/overlay conventions. |
| `glossary.md` | Unknown project terminology. |
| `hardware.md` | VDP, DMA, controllers, Z80, interrupt/hardware behavior. |
| `line-by-line-checklist.md` | Compact build checklist for a line-by-line pass. |
| `line-by-line-analysis.md` | Full rules, markers, identifier audit, calibration. |
| `ram-map.md` | Resolve RAM ranges, owners, fields and aliases (grep by address/name). |
| `references.md` | External references and sources. |
| `reverse-engineering.md` | Evidence tags, BlastEm workflow, experiment format. |

## Analysis

| File | When to read |
|---|---|
| `analysis/animation.md` | Sprite animation state/data and related helpers. |
| `analysis/assets.md` | Asset split/render pipeline and preview status. |
| `analysis/asset_verification.md` | Verify extracted assets against ROM/runtime dumps. |
| `analysis/audio.md` | 68k audio API, Z80 driver, sound data (deferred). |
| `analysis/combat.md` | Attack states, club transfer, collision/impact combat path. |
| `analysis/coverage.md` | Decide the next analysis target; current coverage dashboard. |
| `analysis/endlevel.md` | Level-complete animation and level-up screen. |
| `analysis/highscore.md` | High-score screen behavior and layout. |
| `analysis/intro.md` | Intro/title/credits screen, text and H-scroll. |
| `analysis/identifiers.md` | Cross-file identifier quality map and rename verdicts. |
| `analysis/logoEA.md` | EA logo screen, decompression and plane trick. |
| `analysis/main.md` | Boot, interrupts, input, VDP/DMA and top-level helpers. |
| `analysis/menu_main.md` | Main menu, race selection, tooltips and menu input. |
| `analysis/menu_password.md` | Password entry/checksum and cursor behavior. |
| `analysis/message.md` | Shared message prompt/blink/text system. |
| `analysis/race_actors.md` | Actor struct fields, definitions, spawn snapshots. |
| `analysis/race_ai.md` | Actor AI, action dispatch, targeting, movement/speed. |
| `analysis/race_ai_road.md` | Road profile, object lists/standings/speed helpers. |
| `analysis/race_anim_audio.md` | Race animation, PRNG, impact and audio helper paths. |
| `analysis/race_data_tables.md` | Race data/table layouts and consumers. |
| `analysis/race_hud.md` | Race HUD drawing and data tables. |
| `analysis/race_hud_debug.md` | HUD digit/debug writers and callers. |
| `analysis/race_impact.md` | Pair impact, collision, crash and fall contracts. |
| `analysis/race_impact_map.md` | Prioritized race analysis targets by impact/fan-in. |
| `analysis/race_map.md` | Race frame timeline, dataflow spine, actor field ownership matrix, capture matrix and study order. |
| `analysis/race.md` | Race top-level init, frame loop, input and buffers. |
| `analysis/race_misc_data.md` | HUD/palette/results tables in the data gap. |
| `analysis/race_movement.md` | Actor movement/curve dataflow and Y clamping. |
| `analysis/race_physics.md` | Camera, projection, nearest target and actor rendering. |
| `analysis/race_results.md` | Post-race results panel and outcome dispatch. |
| `analysis/race_spawn.md` | Opponent/traffic spawn records, lists and setup. |
| `analysis/race_speed.md` | Speed, gear, curve limit and target-selection paths. |
| `analysis/race_track_data.md` | Track records and Data2..Data6 stream formats. |
| `analysis/rand.md` | Random-number helper and consumers. |
| `analysis/rider_intro.md` | Pre-race rider intro, portraits, quotes and layout. |
| `analysis/rider_sprites.md` | Rider/bike sprite-chain builder and strip table. |
| `analysis/road_marking.md` | Road markings and sprite placement. |
| `analysis/road_render.md` | Road/object strip renderer and projection helpers. |
| `analysis/road_shapes.md` | Road shape table/data layout, split and preview status. |
| `analysis/rom_tail.md` | Raw/labelled ROM tail, assets and boot checksum. |
| `analysis/screens_flow.md` | Screen state machine, VDP map and flow evidence. |
| `analysis/shape_writer_verify.md` | Runtime verification of shape writer/output. |
| `analysis/shop.md` | Bike shop screen, layout and input. |
| `analysis/track_data.md` | Track decoder and curve-buffer format. |
| `analysis/uncompress.md` | LZSS B/W/stream/VRAM decompression formats. |
| `analysis/unknowns.md` | Registry of live `@UNKNOWN` semantic gaps. |
| `analysis/z80_driver.md` | Z80 loader/entry/mailbox analysis. |
| `analysis/_template.md` | Template for a new detailed analysis document. |

## Module cards

| File | When to read |
|---|---|
| `modules/README.md` | Find the card for a source module. |
| `modules/animation.md` | Animation module contract/status. |
| `modules/audio.md` | Audio module contract/status. |
| `modules/combat.md` | Combat module contract/status. |
| `modules/endlevel.md` | Endlevel screen module. |
| `modules/fade.md` | Fade/palette transition module. |
| `modules/highscore.md` | High-score screen module. |
| `modules/intro.md` | Intro screen module. |
| `modules/logoEA.md` | EA logo module. |
| `modules/main.md` | Boot/main module. |
| `modules/menu_main.md` | Main-menu module. |
| `modules/menu_password.md` | Password module. |
| `modules/message.md` | Message system module. |
| `modules/race.md` | Race include/module overview. |
| `modules/race_ai.md` | Race AI module. |
| `modules/race_ai_road.md` | Race AI/road module. |
| `modules/race_anim_audio.md` | Race animation/audio helpers module. |
| `modules/race_core.md` | Race core/init/results module. |
| `modules/race_data_tables.md` | Race data tables. |
| `modules/race_hud.md` | Race HUD module. |
| `modules/race_hud_debug.md` | HUD digit/debug module. |
| `modules/race_misc_data.md` | Race misc data tables. |
| `modules/race_physics.md` | Race physics/DMA module. |
| `modules/race_results.md` | Results screen module. |
| `modules/race_spawn.md` | Spawn module. |
| `modules/race_track_data.md` | Track data module. |
| `modules/rand.md` | Random helper module. |
| `modules/rider_intro.md` | Rider-intro module. |
| `modules/rider_sprites.md` | Rider sprite builder module. |
| `modules/road_marking.md` | Road marking module. |
| `modules/road_render.md` | Road renderer module. |
| `modules/road_shapes.md` | Road shape data module. |
| `modules/rom_assets.md` | ROM asset/tail module. |
| `modules/shop.md` | Shop screen module. |
| `modules/top_level.md` | Top-level screen-flow module. |
| `modules/track_data.md` | Track decoder module. |
| `modules/uncompress.md` | Decompression module. |
| `modules/_template.md` | Template for a new module card. |

# Module card: `src/race/race.asm`

- **ROM range:** `0x00A4E2`–`0x016E6F`; include split (order below)
- **Status:** partially analyzed (top-level flow, init/assets, input/loop, buffer
  rotation, initial structure inventory; actor/physics/AI and sub-module internals
  TODO)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/race.md`

## Role / purpose
Main gameplay: level/asset setup, the per-frame simulation/render loop, player input and
steering, actor/opponent/physics updates, road interpolation and rendering, HUD/road
marking/animation, and the race outcome. `src/core/top_level.asm` calls `Race_Init`, installs
`Race_GameTick` as the frame update, and calls `Race_Update` each frame.

## Split modules
| File | ROM | Role | Card |
|---|---|---|---|
| `src/race/race_core.asm` | `$A4E2-$D277` | Top-level/init/results/actor data | [race_core.md](race_core.md) |
| `src/race/race_hud.asm` | `$D278-$D8F9` | Race HUD | [race_hud.md](race_hud.md) |
| `src/race/race_physics.asm` | `$D8FA-$E731` | DMA, camera, HInt scroll, rearview/marking, nearest opponent | [race_physics.md](race_physics.md) |
| `src/race/road_marking.asm` | `$E732-$EB33` | Road marking / sprite placement | [road_marking.md](road_marking.md) |
| `src/race/race_ai_road.asm` | `$EB34-$10DFF` | Road profile/objects/standings/speed | [race_ai_road.md](race_ai_road.md) |
| `src/race/race_ai.asm` | `$10E00-$14055` | Actor/input/AI/physics | [race_ai.md](race_ai.md) |
| `src/race/race_anim_audio.asm` | `$14056-$16119` | Animations, audio/impact helpers; includes `rand.asm` | [race_anim_audio.md](race_anim_audio.md) |
| `src/race/rand.asm` | `$15FA8-$160E1` | PRNG/LFSR helpers (included by `race_anim_audio.asm`) | [rand.md](rand.md) |
| `src/race/race_combat.asm` | `$1611A-$1685F` | Player fist, AI combat, nearest-target/collision | [combat.md](combat.md) |
| `src/race/animation.asm` | `$16860-$169AF` | Sprite animation | [animation.md](animation.md) |
| `src/race/race_spawn.asm` | `$169B0-$16E6F` | Track data + dynamic spawn | [race_spawn.md](race_spawn.md) |
| `src/data/race_actor_tables.asm` | `$25856-$259B5` | Actor pointer/graphics tables (ROM gap data) | - |
| `src/data/race_data_tables.asm` | `$19A12-$19F61` | Intro/results/level tables (ROM gap data) | [race_data_tables.md](race_data_tables.md) |
| `src/data/race_engine_tables.asm` | `$257D0-$25855` | Physics/engine/audio tables (ROM gap data) | [race_data_tables.md](race_data_tables.md) |
| `src/data/race_actor_extra_tables.asm` | `$259B6-$25EBF` | Actor/AI tables (ROM gap data) | [race_data_tables.md](race_data_tables.md) |
| `src/data/race_track_data.asm` | `$25EC0-$3BF19` | Per-track records/streams (ROM gap data) | [race_track_data.md](race_track_data.md) |
| `src/data/road_shapes.asm` | `$3BF1A-$7DCA7` | Road/object shape table/data (ROM gap) | [road_shapes.md](road_shapes.md) |
| `src/data/race_misc_data.asm` | `$7DCA8-$7E6A1` | HUD/palette/results tables (ROM gap) | [race_misc_data.md](race_misc_data.md) |
`src/race/race.asm` includes these in exactly that order; the code is split at the original
`race_hud`/`road_marking`/`racing audio/combat`/`animation` include boundaries.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Race_Init` | `0xA4E2` | `src/core/top_level.asm` `0x7E80C` | Full level/race setup + warm-up frames. |
| `Race_GameTick` | `0xBA76` | fade wrapper | VDP/input/pause/demo per-frame update. |
| `Race_Update` | `0xC00C` | `src/core/top_level.asm` `0x7E87A` | Simulation + render prep. |
| `Race_GetInput` | `0xBE56` | `Race_GameTick` | Steering/buttons/pause. |
| `Race_GetInputDemo` | `0xBE2C` | `Race_GameTick` (demo) | Any button ends the demo. |
| `Race_SwapFrames` | `0xBBFE` | `Race_GameTick` | Pre-switch the next buffers. |
| `Race_FinishFrame` | `0xBD24` | `Race_Update` | Publish the current frame, rotate buffers. |
| `Race_UpdateTime` | `0xBA02` | `Race_GameTick` | BCD race timer. |
Full list: the related analysis page.

## External calls / dependencies
- Callers: `src/core/top_level.asm`.
- Uses `UncompressW/B`, `UncompressToVRAM`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`,
  `DmaWriteVRAM`, `DmaWriteCRAM`, `PiecewiseLinearInterpolation`, `Road_DrawObjects`
  (`road_render`), `RaceHud_Draw`, `RoadMarking_Draw`, `UpdateAnimation(2)`, the audio
  functions, `GetInputPlayerA/B`, `Rand_NextWord`, `track_data` decoder, `Race_LoadActorPalette`,
  `Race_FormatDecimal`; spawn helpers `Race_SetupActorSprite`/`Race_GetCurveSpeedLimit` (physics TODO).

## Hacks / bugs / quirks
- The flat `STRUCT_OFFSET_*` symbols are IDA-derived and ambiguous:
  `$68(a1)` with `a1=$FF2FAA` is a different struct than `$FF1EAA+$68`.
- `STRUCT_OFFSET_66` in `dc.b` animation data was an IDA mistake; fixed to `$66`
  (value unchanged).
- The race HUD/scroll/SAT use a 2-3 buffer rotation; the VScroll info buffers
  `$FF3FDC/$411C/$425C` rotate via `Race_ram_Alpha1/2/3`.
- Demo mode ends after 3600 frames or any button.
- Start toggles `Race_ram_State` (pause); the HInt raster effect is disabled for
  negative state.
Full list: the related analysis page.

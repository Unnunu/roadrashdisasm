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
| `src/race/race_anim_audio.asm` | `$14056-$16119` | Animations, random, audio/impact helpers | [race_anim_audio.md](race_anim_audio.md) |
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
| `Race_ResetFrameTimers` | `0xB9AE` | `Race_GameTick` | Frame pacing. |
| `Race_InitTrack` | `0xB016` | `Race_Init` | Track record/streams/spawn. |
| `Race_CreateActors` | `0xCAD0` | `Race_Init` | Rider/opponent actor structs and tables. |
| `Race_InitActorLists`/`Positions` | `0xB6C4`/`0xB72A` | `Race_Init` | Actor pointer groups + screen spots. |
| `Race_ComputeResults` | `0xC3F8` | race end | Outcome/places/password/money. |
| `Race_UpdateSpeedDisplay` | `0xF108` | `Race_Update` | Speed -> `Race_ram_SpeedDisplay`. |
| `Race_FormatDecimal` | `0xF11C` | HUD/debug | Packed 5-digit decimal. |
| `Race_SpawnTick` | `0x16AF6` | `Race_Update` | Opponent/traffic spawning. |
| `Race_SpawnOpponent`/`Traffic` | `0x16BD6`/`0x16C1A` | spawn tick | Ahead/behind spawn paths. |

## Control flow / state machine

1. `Race_Init`: variables, bike data, buffers, HUD/fonts/track assets, road image,
   actors, track data decode, VDP, opponent spawn, track parameters, audio; two
   `Race_Update` warm-ups; two `Race_GameTick`/frame-ready waits; state 0.
2. Main loop: `Race_Update` simulates and prepares the next frame; `Race_GameTick`
   applies the VScroll info, DMA window/HScroll/SAT/palette, swaps frames, reads input,
   handles pause/demo/end. `Race_FinishFrame`/`Race_SwapFrames` rotate the 2-3 buffers.
3. End: `Race_ram_GameEnded`/`DemoGameEnded` -> stop audio, clear `ram_UpdateFunction`;
   the top level goes to results (non-demo) or the menu (demo).

## RAM / ROM & structures

- Player/bike A/B: `RacePlayerA/B` (`$FF1EAA`/`$FF26AA`), `$80` each; actor struct type.
  Known offsets: `+$02 PosZ`, `+$04 PosXHigh`, `+$06 PosXLow`, `+$12 Speed`,
  `+$18 Gear`, `+$30 PosY`, `+$66 Unk66` (word; copied from `+$56`),
  `+$68` flags (bit1 B, bit2 A, bit7 timer stop), `+$71 Index`.
- `$FF2FAA`: a further actor-like instance used by `Race_UpdateStaticActors` (`$68` bit6), not in
  the static list; role/layout TODO (`docs/analysis/race_actors.md`).
- Spawn lists: `ram_FF1A0C` active actors, `ram_FF1A06` count, `ram_FF1982` opponent
  free list, `ram_FF19C4` traffic free list; `Race_ram_PlayerProgress` progress, `Race_ram_ActorDistanceScale`
  distance scale, `Race_ram_SpawnTimer` spawn timer, `ram_FF1F2A` first opponent,
  `Race_ram_LevelIndex`/`ram_FF1B34`/`ram_FF1B36` level/recycle state; speed display `Race_ram_SpeedDisplay`.
  Details: `docs/analysis/race_spawn.md`.
- `$FFD37C`: 0x14-byte road/actor objects (`docs/analysis/road_render.md`).
- Actors: `Race_ActorList` `0x25856` (player A + 15 opponents, `$80` each),
  `Race_ActorDefinitionTable` `0xCCDA` (76 x 16-byte definitions; player def `$4B`),
  `Race_ActorGraphicsTable` `0x258EE`, `Race_StaticActorList` `0x2589A`;
  fields/tables in `docs/analysis/race_actors.md`.
- Track: `RaceTrack_Data1..6`, `unk_25EC0`, spawn data `RaceTrack_Data5`, per-level
  thresholds `word_B976/B980`, bike data `unk_25B50/25AC4`.
- Buffers: `Intro_TitleScrollTable`/`Intro_TitleScrollSpeed` (+$400 SAT),
  `Menu_ram_FrameBuffer/2`, `Race_ram_FrameReady/2`, `Race_ram_SpriteSize1/2`,
  `Intro_ram_ImageBuffer`/`Race_ram_ImageBuffer2`, VScroll info
  `ram_FF3FDC/$411C/$425C`, HUD/SAT/HScroll DMA.
- Subsystems: `src/race/race_hud.asm` (0xD278), `src/race/road_marking.asm` (0xE732),
  `src/race/animation.asm` (0x16860); road/object renderer `src/race/road_render.asm`; track decoder
  `src/race/track_data.asm`; LZSS `src/core/uncompress.asm`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Race_Init` | `0xA4E2` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_InitAudio` | `0xA674` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_InitVdp` | `0xA72A` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_InitTrack` | `0xB016` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_InitVariables` | `0xB0E8` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_LoadBikeData` | `0xB86A` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `Race_ResetFrameTimers` | `0xB9AE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_UpdateTime` | `0xBA02` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `Race_GameTick` | `0xBA76` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_SwapFrames` | `0xBBFE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_FinishFrame` | `0xBD24` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_GetInputDemo` | `0xBE2C` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_GetInput` | `0xBE56` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_Update` | `0xC00C` | [x] | [~] | [x] | [x] | [x] | [ ] | partial |
| `Race_ComputeResults` | `0xC3F8` | [x] | [~] | [x] | - | [x] | [ ] | partial |
| `Race_CreateActors` | `0xCAD0` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_SpawnTick` + spawn | `0x16AF6`+ | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| Actors/physics/AI | `0xD9DA`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| `src/race/race_hud.asm` | `0xD278` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `src/race/road_marking.asm` | `0xE732` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `src/race/animation.asm` | `0x16860` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |

Detailed top-level flow: `docs/analysis/race.md`; actors: `docs/analysis/race_actors.md`; spawn: `docs/analysis/race_spawn.md`; split cards above.

## External calls / dependencies

- Callers: `src/core/top_level.asm`.
- Uses `UncompressW/B`, `UncompressToVRAM`, `WriteToVRAM`, `WriteNametable(ToBuffer)`,
  `DmaWriteVRAM`, `DmaWriteCRAM`, `PiecewiseLinearInterpolation`, `Road_DrawObjects`
  (`road_render`), `RaceHud_Draw`, `RoadMarking_Draw`, `UpdateAnimation(2)`, the audio
  functions, `GetInputPlayerA/B`, `Rand_GetWord`, `track_data` decoder, `Race_LoadActorPalette`,
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
- The actor definitions have 5 pages of 15 opponents plus the all-zero "Player def"
  (id `$4B`); the player stats come from the bike/physics init. `[static]`
- The static actor group (`$FF2EAA/$FF2F2A`, type `$10`) is separate; role TODO.

## Verified facts

- `[static]` Top-level init order, warm-up frames, main loop, buffer rotation.
- `[static]` Input/steering/pause and the player `$68` bit1/bit2/bit7 meanings in the
  top-level. `[dynamic]` active opponents also show `$68=$42` (bit1+bit6), so the
  bit1 meaning must be reconciled before renaming it.
- `[static]` Track record/streams/spawn/bike data initialization.
- `[static]` Race outcome fields (`ram_FF0526/28`, `Race_EventBuffer`, `RaceResults_ram_Outcome`).
- `[static]` Actor tables: 76 definitions, 16-pointer rider list (player A + 15
  opponents), graphics/static tables (parsed from `baserom.md`).
- `[static]` Spawn flow: `Race_SpawnTick` -> opponent (ahead, x+$200000) or traffic
  (behind, x-$100000), active/free lists, distance checks, rating from the opponent
  definition; speed display `Race_ram_SpeedDisplay`.
- `[dynamic]` Actor list split: active count 8 = player A + 7 opponents
  (`$FF232A`..`$FF262A`); 7 opponent free slots; nearest target `$FF232A`.
- `[confirmed]` Actor fields: `$12` Speed, `$14` acceleration, `$26` =
  `Speed * Race_ram_FrameDelay` (FrameDelay 7), `$1E` previous X while `$04`
  advances (`$04-$1E=$26`), `$66` rating/lifecycle value, `$68` bit6
  active/update marker, `$6B` bit1 armed. See `docs/analysis/race_actors.md`.
- `[dynamic]` Forced `RaceBike_ram_CurrentSteering=±$600`: `$42=-$49/+$49`,
  `$69` bit2 set, `$00=current screen Y`, `$1A=previous $30`, `$30=current road Y`.
  A 300-frame forced left turn gives negative `$00/$30`, `$69=$07`,
  `$4A/$4C/$4E=$0E/$0C/$0F`; `$68` bit3 stays clear (hard-curve, not confirmed
  off-road).

## Hypotheses / next steps

- `[hypothesis]` `ram_FF2FAA` is a further actor-like instance (not in the static
  list); it is zero except `$71=$12` in the demo snapshots.
- TODO: static group `$FF2EAA/$FF2F2A` uses a phase-specific layout after
  `Race_UpdateStaticActors` (`$16` becomes 0, `$30=$8000`); analyze that updater.
- TODO: actor fields `$22/$24/$2A/$32/$36-$3C/$3E-$42/$46/$4A-$4E/$56/$68/$69`
  under steering/off-road/2P tests.
- TODO: player B (`$FF26AA`) is zero in the demo; verify in 2P mode.
- TODO: trace the `a1` bases and map the player/actor structures field by field.
- TODO: actor/physics/AI functions; `race_hud`/`road_marking`/`animation` data/scripts and dynamic checks.
- Only after the field layout is confirmed: AS `STRUCT`s, convert confirmed uses,
  build after each batch, remove the flat `STRUCT_OFFSET_*` aliases.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `+$16` actor field | `ActorType` | definition byte0 | high |
| `+$66` actor field | `ActorRating` | definition byte5*100 | medium |
| `+$75` actor field | `ActorGraphicsIndex` | definition byte2 low 7 bits | high |
| `$FF2FAA` struct | `RaceActor`/`RacePlayerVisual` | not in static list | low |

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Demo race renderer | GDB demo, `0x942A`/`0x8FB4` | object list/road strip | `road_render` card |
| Track decoder | GDB demo, `0x9FE4` | stream pointers/lengths | `track_data` card |
| Actor tables | parse `baserom.md` `0x25856/0xCCDA/0x258EE` | 16 pointers, 76 defs | `race_actors.md` |
| Spawn helpers | static code review `0x16AF6`..`0x16E6E` | active/free lists, ahead/behind | `race_spawn.md` |

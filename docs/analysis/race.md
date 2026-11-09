# Analysis: `src/race/race.asm` (main gameplay)

- **Module:** race/gameplay: init, assets, per-frame simulation/render loop, input,
  actors/physics/AI, road/HUD/animation pipeline, race outcome
- **ROM range:** `0x00A4E2`–`0x016E6F`; split modules: `src/race/race_core.asm`
  (`0xA4E2`-`0xD277`), `src/race/race_hud.asm` (`0xD278`-`0xD8F9`), `src/race/race_physics.asm`
  (`0xD8FA`-`0xE731`), `src/race/road_marking.asm` (`0xE732`-`0xEB33`), `src/race/race_ai_road.asm` (`0xEB34`-`0x10DFF`; road profile/objects/standings/speed; `docs/analysis/race_ai_road.md`), `src/race/race_ai.asm`
  (`0x10E00`-`0x14055`), `src/race/race_anim_audio.asm` (`0x14056`-`0x1685F`), `src/race/animation.asm` (`0x16860`-`0x169AF`), `src/race/race_spawn.asm`
  (`0x169B0`-`0x16E6F`); `src/race/race.asm` is the include list.
- **Status:** partially analyzed (top-level flow, init/assets, input/loop, buffer
  rotation, initial struct inventory; actor/physics/AI and sub-module internals TODO)
- **Related:** `docs/architecture.md`, `docs/ram-map.md`, `docs/hardware.md`,
  `docs/analysis/road_render.md`, `docs/analysis/track_data.md`, `docs/analysis/uncompress.md`

## Coverage matrix (top level)

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
| `Race_ComputeResults` (outcome) | `0xC3F8` | [x] | [~] | [x] | - | [x] | [ ] | partial |
| Actor/physics/AI | `0xD9DA`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| `src/race/race_hud.asm` | `0xD278` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `src/race/road_marking.asm` | `0xE732` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `src/race/animation.asm` | `0x16860` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |

## Role & entry points

The top level calls `Race_Init` (`src/core/top_level.asm` `0x7E80C`), sets
`ram_UpdateFunction = Race_GameTick` after the fade, and calls `Race_Update` each
frame (with the progress/standings/track-chunk logic around it). `Race_Init` runs two
warm-up updates and two `Race_GameTick`/frame-ready loops before returning; the main
loop then alternates `Race_GameTick` (VDP/input) and `Race_Update`
(simulation/render prep).

## `Race_Init` (`0xA4E2`)

1. `Race_InitVariables`, `Race_LoadBikeData`, `Race_ClearFrameBuffers`, `Race_ClearHudCorners`,
   `Race_LoadHUD`, `Race_InitTrack`, `Race_LoadFonts`, `Race_LoadMoreTrackGfx`,
   `Race_LoatTrackGfx`, `Race_DrawTopHud`, `Race_LoadRoadImage`, `Race_LoadBikePalette`,
   `Race_CreateActors`, `Race_InitActorLists`, `Race_InitActorPositions`, `TrackData_InitLevel` (track-data decode).
2. `Race_InitVdp`, `Race_SpawnOpponents` (opponent spawn), `Race_LoadTrackParams` (track params),
   `Race_InitAudio`; set the HInt state, frame delay, engine/skid defaults.
3. Two `Race_Update` warm-ups, then two `Race_GameTick`/frame-ready waits, another
   `Race_Update`; finally `Race_ram_State=0` and return.
4. It also fills the first VScroll info buffer (`ram_FF3FDC`/next) with the VDP
   registers/backdrop/VSRAM/scroll values.

## Main loop: `Race_GameTick` (`0xBA76`)

- Frame delay/state; in the running state (`Race_ram_State == 0`) increment
  `Race_ram_FrameCounter` and run `Race_UpdateTime`.
- Apply the VScroll info buffer: VDP control writes, VSRAM scroll, `ram_FF0406`
  (HInt scroll offset), the extra VDP register words.
- `ram_FF369E` = `-1` when `Race_ram_State < 0`, else 0 (HInt raster effect enable).
- If `Race_ram_NextFrameReady`: write sprite tiles first (`Race_WriteSpriteTiles`) when
  `Race_ram_NextSpriteSizePtr` is non-zero; otherwise DMA the window/HUD (`$3000`,
  `$740` words = 29 lines), the HScroll+Sprite tables (`$C000`, `$340` words), the
  palette (`$40` words) and call `Race_SwapFrames`/`Race_ResetFrameTimers`.
- If already drawn and the state is non-zero: DMA the HUD only (paused/debug refresh).
- Demo mode (`MainMenu_ram_DemoMode`): 3600-frame (60 s) limit -> `Race_ram_GameEnded`/
  `DemoGameEnded`; otherwise `Race_GetInputDemo`. Normal mode: `Race_GetInput`.
- On `Race_ram_DemoGameEnded`: stop the three engine audio channels, clear
  `ram_UpdateFunction`, disable the HInt effect.

## `Race_SwapFrames` / `Race_FinishFrame`

Two/three-buffer rotation for every streaming surface:

| Surface | Buffers |
|---|---|
| HScroll/SAT | `Intro_TitleScrollTable` (+$400 SAT) / `Intro_TitleScrollSpeed` |
| HUD | `Menu_ram_FrameBuffer` / `Menu_ram_FrameBuffer2` |
| Frame ready | `Race_ram_FrameReady` / `Race_ram_FrameReady2` |
| Sprite size | `Race_ram_SpriteSize1/2` |
| Sprite tiles | `Intro_ram_ImageBuffer` / `Race_ram_ImageBuffer2` |
| Sprite dest | `$8680` / `$C680` (`Animation_ram_BaseTile` $434/$634) |
| VScroll info | `ram_FF3FDC` / `ram_FF411C` / `ram_FF425C` (`Alpha1/2/3`) |

`Race_FinishFrame` sets the current frame-ready flag, switches the current buffers and
rotates the alpha/VScroll buffers; `Race_SwapFrames` pre-switches the next buffers.
This is the double/quad buffering that avoids tearing.

## `Race_GetInput` (`0xBE56`)

- Select the active controller (`Race_ram_ActiveController`), read SACBRLDU into
  `Race_ram_CurrentButtons`.
- Left/Right adjust `RaceBike_ram_CurrentSteering` using
  `RaceBike_ram_SteeringPower`, `ReturnToStraightPower`, `MaxSteering` (clamped).
- B sets/clears player `$68` bit1; A sets/clears player `$68` bit2; C returns.
- Start toggles `Race_ram_State` (pause/resume), sets `ram_FF3698/369A`, plays
  `AudioFunc18`/`Audio_StopMusic`, debounced by `ram_FF368E`.
- No buttons: return the steering to straight, clear the player `$68` bits1/2 and the
  debounce.
- `Race_GetInputDemo`: any pad button ends the demo (GameEnded/DemoGameEnded).

## `Race_Update` (`0xC00C`)

1. Bike damage `>= $20` -> set the race-end timers (`ram_FF3698=$171`,
   `ram_FF1B18=480`), eventually `Race_ram_GameEnded`.
2. Clear the per-frame player flags `ram_FF1AD6/D7/DD`.
3. `Race_UpdateSpeedDisplay` with the player Speed; `Race_SpawnTick`; if the race has started
   (`ram_FF1B20`): the player/opponent update chain (`Race_UpdatePlayerAnimation`, `Race_UpdateBikeLean`,
   `sub_1383E`, `sub_13A92`, `Race_UpdateActorAI`, `sub_13E94`, `sub_10DBE`, `sub_10DDA`,
   `sub_13BF4`, `Race_UpdateStaticActors`, `sub_128E0`, `sub_12974`, `sub_138CE`, `sub_1281E`,
   `sub_11C44`, `sub_11CC8`, `sub_1218C`, `sub_123A8`, `Race_UpdateNearestOpponent`, `sub_12EA2`,
   `sub_13106`), the player/opponent x difference `ram_FF3036`, `Race_UpdateNearestTarget`.
4. Render prep: `Race_UpdateCamera`; if the frame is not ready: `Race_IntegrateTrackCurve`, the
   `PiecewiseLinearInterpolation` calls for the road arrays (`Road_ram_XLeftArray`,
   `Road_ram_MarkingXArray`, `Road_ram_XRightArray`), `Road_FillProfileTables`,
   `Race_BuildVScrollInfo`, `sub_FD96`, `sub_FB1E`, `sub_F40C`, the visible-object list
   (`ram_FF1B50`/`1C50`/`1D50` via `sub_109B6`/`sub_FC0E`/`Road_BuildVisibleList`),
   `sub_14E38`, `Race_DrawRoadMarkingHud`, `Race_DrawRoadEdges`; reset the sprite chain indices;
   `RaceHud_Draw`, `Road_DrawObjects` (road/object renderer), `RoadMarking_Draw`; store the
   sprite count/tile count; `Race_DrawRearviewMirror`, `Race_BuildHScrollTable`; `Race_FinishFrame`.
5. The road/actor/physics chain is where the `RacePlayer` and actor structures are
   read/written; it is the next analysis target.

## Track data / actors / bikes

- `Race_InitTrack`: `CurrentTrackId*2` -> `unk_25EC0` -> the track record;
  `RaceTrack_Data1` = per-level word, `Data2/3` = the track-data decoder streams
  (`src/race/track_data.asm`), `Data4/5/6` = object/spawn/gfx data; initial time/position/state.
- `Race_InitActorLists`/`Race_InitActorPositions`: actor pointer groups and their
  initial screen fields (`ram_FF1A08`/`ram_FF1982`; exact 8+7 split TODO).
- `Race_InitPhysicsConstants`: bike physics/steering/engine constants.
- `Race_LoadTrackParams`: per-track parameters from `unk_1471A`.
- `Race_LoadBikeData`: bike id -> `unk_25B50` (0x13 words at `ram_FF1A70`) and
  `unk_25AC4` (steering/engine values).
- `Race_SpawnOpponents`: `RaceTrack_Data5` spawn records (4 bytes, `$FFFFFFFF` terminator),
  split by per-level thresholds `word_B976`/`word_B980` and the `off_B98A` color
  table into `ram_FFD7D4` and `ram_FFDBD8` (object lists).
- `Race_CreateActors` (`0xCAD0`): builds the rider/opponent **actor structs** from
  `Race_ActorList`, `Menu_ram_PlayerA/BOpponents`, `Race_ActorDefinitionTable` and
  `Race_ActorGraphicsTable`; the `0x14`-byte `Road_ObjectArray` is separate.
  Details: `docs/analysis/race_actors.md`.
- `Race_SpawnTick`/`Race_SpawnOpponent`/`Race_SpawnTraffic`: dynamic actor spawning,
  active/free lists and distance checks; `Race_UpdateSpeedDisplay`/`Race_FormatDecimal`
  produce `ram_FF3046`. Details: `docs/analysis/race_spawn.md`.

## RAM / structures (initial inventory)

Actors/player structures:

| Base | Size | Role |
|---|---|---|
| `RacePlayerA` (`$FF1EAA`) | `$80` | Player A actor (the actor/player struct type). |
| `RacePlayerB` (`$FF26AA`) | `$80` | Player B actor (inactive/2P; TODO). |
| `$FF1F2A`..`$FF262A` | `$80` | 15 opponent actors (`Race_ActorList`). |
| `$FF2EAA`/`$FF2F2A` | `$80` | static actors (type `$10`). |
| `$FF2FAA` | `$80`? | further actor-like instance (not in the static list); role TODO. |
| `$FFD37C` | `$14`/entry | Road/actor object array (fields in `docs/analysis/road_render.md`). |

`RacePlayer` offsets observed in the top-level (more in the physics/AI chain):

| Offset | Size | Name/status | Evidence |
|---|---|---|---|
| `+$02` | word | `PosZ` | 98C2/endlevel debug, main HInt |
| `+$04` | word | `PosXHigh` | `Race_Update`, 98C2 |
| `+$06` | word | `PosXLow` | 98C2 |
| `+$12` | word | `Speed` | `Race_Update` (`Race_UpdateSpeedDisplay`), main HInt |
| `+$16` | byte | `ActorType` | actor definition byte0 |
| `+$5C`/`+$5E`/`+$60` | word | actor graphics/sprite fields | `Race_ActorGraphicsTable` |
| `+$66` | word | `ActorRating`/speed (definition byte5*100; `Race_ApplyActorRating`) | `Race_CreateActors` |
| `+$73`/`+$74`/`+$75`/`+$77` | byte | actor definition bytes 3/1/2/4 | `Race_CreateActors` |
| `+$18` | word | `Gear` | 98C2, shop/gear |
| `+$30` | word | `PosY` | 98C2, main HInt |
| `+$66` | word | `Unk66` (TODO; copied from `+$56`, used as a divisor) | `STRUCT_OFFSET_66` code uses, `move.w $56(a0),$66(a0)` |
| `+$68` | byte | flags: bit1 = B held, bit2 = A held, bit7 = timer stop | `Race_GetInput`, `Race_UpdateTime` |
| `+$69`,`+$6B`,... | byte | unknown state/flags | physics chain (TODO) |
| `+$71` | byte | `Index` | current `STRUCT_OFFSET_INDEX` |

**Important:** the flat `STRUCT_OFFSET_*` symbols are IDA-derived and ambiguous:
- `STRUCT_OFFSET_66` in `dc.b` animation data was an IDA mistake; the 43 bytes are
  now literal `$66` (`race: drop ida offset symbol from animation data`).
- `$68(a1)` with `a1=ram_FF2FAA` (`Race_UpdateStaticActors`) is a further actor-like instance; its
  exact role is TODO, so a global flat offset symbol must not be assigned blindly.
- The `a1` bases in the physics chain must be traced before assigning fields; no AS
  struct definitions will be created from the flat names.

## Subsystem map

| Area | Functions/addresses |
|---|---|
| Init/assets | `Race_Init` `0xA4E2`, loaders `0xA79C`–`0xAFF2`, `WriteToVRAM` `0xAFF2` |
| VDP/interrupts | `Race_InitVdp` `0xA72A`, HInt via `src/main.asm`; VScroll/HInt buffers |
| Buffering | `Race_SwapFrames` `0xBBFE`, `Race_FinishFrame` `0xBD24` |
| Input | `Race_GetInput` `0xBE56`, `Race_GetInputDemo` `0xBE2C`, steering/pause |
| Time | `Race_UpdateTime` `0xBA02`, `Race_ResetFrameTimers` `0xB9AE` |
| Track/actors | `Race_InitTrack` `0xB016`, `Race_InitActorLists/Positions/PhysicsConstants/LoadTrackParams/SpawnOpponents`, `Race_CreateActors` `0xCAD0`; `Race_ActorList/DefinitionTable/GraphicsTable/StaticActorList` |
| Spawn/traffic | `Race_SpawnTick` `0x16AF6`, `Race_SpawnOpponent/Traffic`, active/free lists, `Race_UpdateSpeedDisplay`/`Race_FormatDecimal` |
| AI/physics | `sub_10E00`..`Race_GetCurveSpeedLimit`, `Race_HandleInputOnFoot` `0x110AE`/`Another` `0x111FA` (`src/race/race_ai.asm`) |
| Animations/audio | `Race_UpdateLeanCurve`..`Race_UpdateCollision`, `Rand_Init` `0x15FE8`/`Rand_GetWord` `0x16034`, `Audio_UpdateEngine0` `0x16520` (`src/race/race_anim_audio.asm`) |
| Camera/scroll/rearview | `Race_UpdateCamera`, `Race_BuildVScrollInfo`/`HScrollTable`, `Race_DrawRearviewMirror`, `Race_DrawRoadMarkingHud`, `Race_UpdateNearestOpponent` (`src/race/race_physics.asm`) |
| Physics/AI | `Race_UpdateSpeedDisplay`, `Race_SpawnTick`, `Race_UpdateBikeLean`..`sub_13106` (TODO) |
| Road/render | `PiecewiseLinearInterpolation`, `Road_FillProfileTables`, `sub_FD96/FB1E/F40C`, `sub_109B6/FC0E`, `Road_BuildVisibleList`, `Road_DrawObjects` (`road_render`), `RoadMarking_Draw` |
| HUD | `RaceHud_Draw` (`src/race/race_hud.asm`) |
| Animation | `UpdateAnimation(2)` (`src/race/animation.asm`), `RiderSprites_Build` |
| Outcome | `Race_ComputeResults` (`0xC3F8`), `Race_SortResults`, `Race_UpdateHighScoreTable`, password/highscore |
| Audio | `Race_InitAudio` `0xA674`, engine channels (`Audio_Engine1Start/8/9/11/12/14`) |

## Open questions / next steps

1. Trace the `a1` bases in the physics/AI chain and map the actor struct fields
   (see `docs/analysis/race_actors.md`; `RacePlayer`/`RaceActor`, `$FF2FAA`).
2. Analyze the actor/physics functions (`Race_UpdateSpeedDisplay`, `Race_SpawnTick`, `sub_13xxx`,
   `sub_Dxxx`, `sub_Exxx`) and the object list.
3. `src/race/race_hud.asm`, `src/race/road_marking.asm`, `src/race/animation.asm` data tables/scripts + dynamic checks.
4. The race outcome (`Race_ComputeResults`/`Race_SortResults`/`Race_UpdateHighScoreTable`) and the standings.
5. Only after the field layout is confirmed: define the AS `STRUCT`s, convert the
   confirmed uses, build after each batch, remove the flat `STRUCT_OFFSET_*` aliases.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `+$16` actor field | `ActorType` | definition byte0 | high |
| `+$66` actor field | `ActorRating` | definition byte5*100 | medium |
| `+$75` actor field | `ActorGraphicsIndex` | definition byte2 low 7 bits | high |
| `RacePlayer`/`RaceActor` | (same actor struct type) | player A/B + 15 opponents + static | medium |
| `$FF2FAA` struct | `RaceActor`/`RacePlayerVisual` | not in static list | low |


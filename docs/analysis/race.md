# Analysis: `race.asm` (main gameplay)

- **Module:** race/gameplay: init, assets, per-frame simulation/render loop, input,
  actors/physics/AI, road/HUD/animation pipeline, race outcome
- **ROM range:** `0x00A4E2`–`0x016E6F`; includes `race_hud.asm` (`0xD278`),
  `road_marking.asm` (`0xE732`), `animation.asm` (`0x16860`)
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
| `race_hud.asm` | `0xD278` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| `road_marking.asm` | `0xE732` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| `animation.asm` | `0x16860` | [~] | [~] | [x] | [x] | [x] | [ ] | partial |

## Role & entry points

The top level calls `Race_Init` (`top_level.asm` `0x7E80C`), sets
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
  `AudioFunc18`/`AudioFunc4`, debounced by `ram_FF368E`.
- No buttons: return the steering to straight, clear the player `$68` bits1/2 and the
  debounce.
- `Race_GetInputDemo`: any pad button ends the demo (GameEnded/DemoGameEnded).

## `Race_Update` (`0xC00C`)

1. Bike damage `>= $20` -> set the race-end timers (`ram_FF3698=$171`,
   `ram_FF1B18=480`), eventually `Race_ram_GameEnded`.
2. Clear the per-frame player flags `ram_FF1AD6/D7/DD`.
3. `sub_F108` with the player Speed; `sub_16AF6`; if the race has started
   (`ram_FF1B20`): the player/opponent update chain (`sub_160E2`, `sub_13EA0`,
   `sub_1383E`, `sub_13A92`, `sub_10E66`, `sub_13E94`, `sub_10DBE`, `sub_10DDA`,
   `sub_13BF4`, `sub_12868`, `sub_128E0`, `sub_12974`, `sub_138CE`, `sub_1281E`,
   `sub_11C44`, `sub_11CC8`, `sub_1218C`, `sub_123A8`, `sub_E5EE`, `sub_12EA2`,
   `sub_13106`), the player/opponent x difference `ram_FF3036`, `sub_1611A`.
4. Render prep: `sub_DE9E`; if the frame is not ready: `sub_EDD0`, the
   `PiecewiseLinearInterpolation` calls for the road arrays (`Road_ram_XLeftArray`,
   `Road_ram_MarkingXArray`, `Road_ram_XRightArray`), `Road_FillProfileTables`,
   `sub_E004`, `sub_FD96`, `sub_FB1E`, `sub_F40C`, the visible-object list
   (`ram_FF1B50`/`1C50`/`1D50` via `sub_109B6`/`sub_FC0E`/`Road_BuildVisibleList`),
   `sub_14E38`, `sub_DD84`, `sub_EC90`; reset the sprite chain indices;
   `RaceHud_Draw`, `Road_DrawObjects` (road/object renderer), `RoadMarking_Draw`; store the
   sprite count/tile count; `sub_D9DA`, `sub_E494`; `Race_FinishFrame`.
5. The road/actor/physics chain is where the `RacePlayer` and actor structures are
   read/written; it is the next analysis target.

## Track data / actors / bikes

- `Race_InitTrack`: `CurrentTrackId*2` -> `unk_25EC0` -> the track record;
  `RaceTrack_Data1` = per-level word, `Data2/3` = the track-data decoder streams
  (`track_data.asm`), `Data4/5/6` = object/spawn/gfx data; initial time/position/state.
- `Race_InitActorLists`/`Race_InitActorPositions`: object/actor pointer tables and their initial screen data.
- `Race_InitPhysicsConstants`: bike physics/steering/engine constants.
- `Race_LoadTrackParams`: per-track parameters from `unk_1471A`.
- `Race_LoadBikeData`: bike id -> `unk_25B50` (0x13 words at `ram_FF1A70`) and
  `unk_25AC4` (steering/engine values).
- `Race_SpawnOpponents`: `RaceTrack_Data5` spawn records (4 bytes, `$FFFFFFFF` terminator),
  split by per-level thresholds `word_B976`/`word_B980` and the `off_B98A` color
  table into `ram_FFD7D4` and `ram_FFDBD8` (object lists).
- `Race_CreateActors` (`0xCAD0`): builds the actor/object records (the `$14`-byte
  `Road_ObjectArray` array used by `road_render.asm`).

## RAM / structures (initial inventory)

Player/bike structures:

| Base | Size | Role |
|---|---|---|
| `$FF1EAA` | `$80` | Player A gameplay state (`RacePlayer` candidate). |
| `$FF26AA` | `$80` | Player B gameplay state (`$FF1EAA + $800`). |
| `$FF2FAA` | ? | Another actor/player-like struct used by `sub_12868` (`$68` bit6); **not** the same struct as `$FF1EAA`. |
| `$FFD37C` | `$14`/entry | Road/actor object array (fields in `docs/analysis/road_render.md`). |

`RacePlayer` offsets observed in the top-level (more in the physics/AI chain):

| Offset | Size | Name/status | Evidence |
|---|---|---|---|
| `+$02` | word | `PosZ` | 98C2/endlevel debug, main HInt |
| `+$04` | word | `PosXHigh` | `Race_Update`, 98C2 |
| `+$06` | word | `PosXLow` | 98C2 |
| `+$12` | word | `Speed` | `Race_Update` (`sub_F108`), main HInt |
| `+$18` | word | `Gear` | 98C2, shop/gear |
| `+$30` | word | `PosY` | 98C2, main HInt |
| `+$66` | word | `Unk66` (TODO; copied from `+$56`, used as a divisor) | `STRUCT_OFFSET_66` code uses, `move.w $56(a0),$66(a0)` |
| `+$68` | byte | flags: bit1 = B held, bit2 = A held, bit7 = timer stop | `Race_GetInput`, `Race_UpdateTime` |
| `+$69`,`+$6B`,... | byte | unknown state/flags | physics chain (TODO) |
| `+$71` | byte | `Index` | current `STRUCT_OFFSET_INDEX` |

**Important:** the flat `STRUCT_OFFSET_*` symbols are IDA-derived and ambiguous:
- `STRUCT_OFFSET_66` in `dc.b` animation data was an IDA mistake; the 43 bytes are
  now literal `$66` (`race: drop ida offset symbol from animation data`).
- `$68(a1)` with `a1=ram_FF2FAA` (`sub_12868`) is a **different structure** than
  `RacePlayerA+$68`; a global flat offset symbol hides this.
- The `a1` bases in the physics chain must be traced before assigning fields; no AS
  struct definitions will be created from the flat names.

## Subsystem map

| Area | Functions/addresses |
|---|---|
| Init/assets | `Race_Init` `0xA4E2`, loaders `0xA79C`–`0xAFF2`, `WriteToVRAM` `0xAFF2` |
| VDP/interrupts | `Race_InitVdp` `0xA72A`, HInt via `main.asm`; VScroll/HInt buffers |
| Buffering | `Race_SwapFrames` `0xBBFE`, `Race_FinishFrame` `0xBD24` |
| Input | `Race_GetInput` `0xBE56`, `Race_GetInputDemo` `0xBE2C`, steering/pause |
| Time | `Race_UpdateTime` `0xBA02`, `Race_ResetFrameTimers` `0xB9AE` |
| Track/actors | `Race_InitTrack` `0xB016`, `Race_InitActorLists/B72A/B770/B840/B8D0`, `Race_CreateActors` `0xCAD0` |
| Physics/AI | `sub_F108`, `sub_16AF6`, `sub_13EA0`..`sub_13106` (TODO) |
| Road/render | `PiecewiseLinearInterpolation`, `Road_FillProfileTables`, `sub_FD96/FB1E/F40C`, `sub_109B6/FC0E/10D46`, `Road_DrawObjects` (`8FB4`), `RoadMarking_Draw` |
| HUD | `RaceHud_Draw` (`race_hud.asm`) |
| Animation | `UpdateAnimation(2)` (`animation.asm`), `RiderSprites_Build` |
| Outcome | `Race_ComputeResults` (`0xC3F8`), `Race_SortResults`, `Race_UpdateHighScoreTable`, password/highscore |
| Audio | `Race_InitAudio` `0xA674`, engine channels (`AudioFunc6/8/9/11/12/14`) |

## Open questions / next steps

1. Trace the `a1` bases in the physics/AI chain and map the `RacePlayer` and
   `ram_FF2FAA` structs field by field (the struct inventory).
2. Analyze the actor/physics functions (`sub_F108`, `sub_16AF6`, `sub_13xxx`,
   `sub_Dxxx`, `sub_Exxx`) and the object list.
3. `race_hud.asm`, `road_marking.asm`, `animation.asm` cards + internals.
4. The race outcome (`Race_ComputeResults`/`Race_SortResults`/`Race_UpdateHighScoreTable`) and the standings.
5. Only after the field layout is confirmed: define the AS `STRUCT`s, convert the
   confirmed uses, build after each batch, remove the flat `STRUCT_OFFSET_*` aliases.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `RacePlayer` (candidate) | `RacePlayer` | two `$80` instances at `$FF1EAA`/`$FF26AA` | medium |
| `$FF2FAA` struct | `RaceActor`/`RacePlayerVisual` | separate `$68` bit6 struct | low |


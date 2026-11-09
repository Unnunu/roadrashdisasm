# Module card: `race.asm`

- **ROM range:** `0x00A4E2`–`0x016E6F`; includes `race_hud.asm` (`0xD278`),
  `road_marking.asm` (`0xE732`), `animation.asm` (`0x16860`)
- **Status:** partially analyzed (top-level flow, init/assets, input/loop, buffer
  rotation, initial structure inventory; actor/physics/AI and sub-module internals
  TODO)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/race.md`

## Role / purpose

Main gameplay: level/asset setup, the per-frame simulation/render loop, player input and
steering, actor/opponent/physics updates, road interpolation and rendering, HUD/road
marking/animation, and the race outcome. `top_level.asm` calls `Race_Init`, installs
`Race_GameTick` as the frame update, and calls `Race_Update` each frame.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Race_Init` | `0xA4E2` | `top_level.asm` `0x7E80C` | Full level/race setup + warm-up frames. |
| `Race_GameTick` | `0xBA76` | fade wrapper | VDP/input/pause/demo per-frame update. |
| `Race_Update` | `0xC00C` | `top_level.asm` `0x7E87A` | Simulation + render prep. |
| `Race_GetInput` | `0xBE56` | `Race_GameTick` | Steering/buttons/pause. |
| `Race_GetInputDemo` | `0xBE2C` | `Race_GameTick` (demo) | Any button ends the demo. |
| `Race_SwapFrames` | `0xBBFE` | `Race_GameTick` | Pre-switch the next buffers. |
| `Race_FinishFrame` | `0xBD24` | `Race_Update` | Publish the current frame, rotate buffers. |
| `Race_UpdateTime` | `0xBA02` | `Race_GameTick` | BCD race timer. |
| `Race_ResetFrameTimers` | `0xB9AE` | `Race_GameTick` | Frame pacing. |
| `Race_InitTrack` | `0xB016` | `Race_Init` | Track record/streams/spawn. |
| `Race_CreateActors` | `0xCAD0` | `Race_Init` | Object/actor records. |
| `sub_C3F8` | `0xC3F8` | race end | Outcome/places/password/money. |

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

- Player/bike A/B: `$FF1EAA`/`$FF26AA`, `$80` each; candidate `RacePlayer` structure.
  Known offsets: `+$02 PosZ`, `+$04 PosXHigh`, `+$06 PosXLow`, `+$12 Speed`,
  `+$18 Gear`, `+$30 PosY`, `+$66 Unk66` (word; copied from `+$56`),
  `+$68` flags (bit1 B, bit2 A, bit7 timer stop), `+$71 Index`.
- `$FF2FAA`: a **different** player/actor-like struct used by `sub_12868` (`$68` bit6);
  not the same layout as `$FF1EAA`.
- `$FFD37C`: 0x14-byte road/actor objects (`docs/analysis/road_render.md`).
- Track: `RaceTrack_Data1..6`, `unk_25EC0`, spawn data `RaceTrack_Data5`, per-level
  thresholds `word_B976/B980`, bike data `unk_25B50/25AC4`.
- Buffers: `Intro_TitleScrollTable`/`Intro_TitleScrollSpeed` (+$400 SAT),
  `Menu_ram_FrameBuffer/2`, `Race_ram_FrameReady/2`, `Race_ram_SpriteSize1/2`,
  `Intro_ram_ImageBuffer`/`Race_ram_ImageBuffer2`, VScroll info
  `ram_FF3FDC/$411C/$425C`, HUD/SAT/HScroll DMA.
- Subsystems: `race_hud.asm` (0xD278), `road_marking.asm` (0xE732),
  `animation.asm` (0x16860); road/object renderer `road_render.asm`; track decoder
  `track_data.asm`; LZSS `uncompress.asm`.

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
| `sub_C3F8` | `0xC3F8` | [x] | [~] | [x] | - | [x] | [ ] | partial |
| Actors/physics/AI | `0xD9DA`+ | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| `race_hud.asm` | `0xD278` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| `road_marking.asm` | `0xE732` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| `animation.asm` | `0x16860` | [~] | [~] | [x] | [x] | [x] | [ ] | partial |

Detailed top-level flow, subsystem map and initial struct inventory:
`docs/analysis/race.md`.

## External calls / dependencies

- Callers: `top_level.asm`.
- Uses `UncompressW/B`, `UncompressToVRAM`, `WriteToVRAM`, `WriteNametable(ToBuffer)`,
  `DmaWriteVRAM`, `DmaWriteCRAM`, `PiecewiseLinearInterpolation`, `sub_942A`
  (`8FB4`), `RaceHud_Draw`, `RoadMarking_Draw`, `UpdateAnimation(2)`, the audio
  functions, `GetInputPlayerA/B`, `Rand_GetWord`, `9FE4` track decoder.

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

## Verified facts

- `[static]` Top-level init order, warm-up frames, main loop, buffer rotation.
- `[static]` Input/steering/pause and the player `$68` bit1/bit2/bit7 meanings in the
  top-level.
- `[static]` Track record/streams/spawn/bike data initialization.
- `[static]` Race outcome fields (`ram_FF0526/28`, `ram_FF04C8`, `ram_FF0918`).

## Hypotheses / next steps

- `[hypothesis]` `ram_FF2FAA` is the player visual/actor state; trace `sub_12868`.
- TODO: trace the `a1` bases and map the player/actor structures field by field.
- TODO: actor/physics/AI functions; `race_hud`/`road_marking`/`animation` cards.
- Only after the field layout is confirmed: AS `STRUCT`s, convert confirmed uses,
  build after each batch, remove the flat `STRUCT_OFFSET_*` aliases.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `$FF1EAA`/`$FF26AA` | `RacePlayerA/B` (base equates) | two `$80` instances | medium |
| `$FF2FAA` struct | `RaceActor`/`RacePlayerVisual` | separate `$68` bit6 | low |
| `ram_FFD37C` | `Road_ObjectArray` | 0x14-byte objects | high |

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Demo race renderer | GDB demo, `0x942A`/`0x8FB4` | object list/road strip | `8FB4` card |
| Track decoder | GDB demo, `0x9FE4` | stream pointers/lengths | `9FE4` card |

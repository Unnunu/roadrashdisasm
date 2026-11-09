# Module card: `src/screens/endlevel.asm`

- **ROM range:** `0x008342`–`0x008FB3` (`src/race/road_render.asm` starts at `0x8FB4`)
- **Status:** analyzed (static; non-demo only)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/endlevel.md`

## Role / purpose

Level-complete sequence: plays the per-level victory animation, then shows a rider/
quote level-up screen, increments the player's level, rebuilds the level opponents and
regenerates the password, and returns to the main menu. Entered when all five courses
of a level are finished in 1st-4th (`ram_FF0918 == 4`).

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `EndLevel_Init` | `0x8342` | `src/core/top_level.asm` `0x7E9FA` | Build the animation stage. |
| `EndLevel_GameTick` | `0x8AEE` | fade wrapper | Animation timing/input/swap. |
| `EndLevel_UpdateAnimation` | `0x8B94` | top-level frame loop | Animation script update. |
| `EndLevel_InitVictoryCharacter` | `0x8682` | `GameTick` end stage | Level-up rider screen. |
| `EndLevel_GameTickVictoryCharacter` | `0x8A1A` | fade wrapper | Rider-screen update/input. |
| `EndLevel_AdvanceLevel` | `0x8946` | `InitCharacterScreen` | Advance level/opponents/password. |

## Control flow / state machine

1. `Init`: VDP (`$3000` window, `$1000` sprites, `$2000` H-scroll, `$4000` planes),
   background `$1280`, animation tiles `$5C00`, window image `$2020`, font; set the
   race-animation state to endlevel buffers.
2. `GameTick`/`UpdateAnimation`: play the level animation (`EndLevel_FrameCounts` frame counts,
   script `EndLevel_AnimationScript`, x/y `$80`); 5-frame DMA/swap; wait for Start release or 2 s;
   `EndLevel_ram_AnimFrame = -1` -> `InitCharacterScreen`.
3. `InitCharacterScreen`: panel `unk_7EA66`, rider from `EndLevel_LevelRiderTable` (level-1, two
   variants), name/quote/palette; `EndLevel_AdvanceLevel`; message group `0x180`.
4. `GameTickCharacterScreen`: DMA window `$3000`; Start held exits; 2 s message cycle.

## RAM / ROM & structures

- `EndLevel_ram_AnimFrame`; `ram_FF0D24` (5-frame swap delay);
  `Race_ram_*` animation state; `Animation_ram_BaseTile=$2E0`.
- `EndLevel_LevelRiderTable` (`0x19F12`): 5 levels x 2 `quote_ptr,image_ptr` records (rival + Natasha);
  index `(level-1)*$10 + (Rand & 8)`.
- `EndLevel_FrameCounts` frame counts (35,54,81,91,123); `EndLevel_AnimationScript` animation script;
  `EndLevel_AnimationTiles` tiles; `EndLevel_WindowImage` window image; `EndLevel_AnimationData` animation data.
- `EndLevel_AdvanceLevel`: clear outcome/places, level++, clamp 5, rebuild
  `Menu_ram_PlayerA/BOpponents` (`$4B` + 15 words `(level-1)*$F+0..14`), regenerate the
  password.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `EndLevel_Init` | `0x8342` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_GameTick` | `0x8AEE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_UpdateAnimation` | `0x8B94` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_InitVictoryCharacter` | `0x8682` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_GameTickVictoryCharacter` | `0x8A1A` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_AdvanceLevel` | `0x8946` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |

Detailed listing: `docs/analysis/endlevel.md`.

## External calls / dependencies

- Callers: `src/core/top_level.asm`.
- Uses `UncompressW/B`, `UncompressToVRAM`, `WriteToVRAM`, `WriteNametable(ToBuffer)`,
  `EncodeString`, `Menu_ShowMessage`, `DmaWriteVRAM`, `DmaWriteCRAM`,
  `UpdateAnimation2`, `Race_FinishFrame`, `Race_SwapFrames`, `GetInputPlayerA/B`,
  `MenuPassword_CreatePassword`, `Audio_Update/3/4`.

## Hacks / bugs / quirks

- Different VRAM layout from the menus (`$1000` sprites, `$2000` H-scroll, `$3000`
  window, `$1280` background). `[static]`
- The level-up rider is selected before the level is incremented. `[static]`
- Start release ends the victory animation; Start held ends the character screen.
- The level-up text at `$8C96`..`$8D8A` is unreferenced and duplicates the
  `src/screens/race_results.asm` tail. `[static]`

## Verified facts

- `[static]` EndLevel runs only for outcome 4; it advances the level and rebuilds the
  opponents/places/password.
- `[static]` Victory frame counts per level; level-up rider table `EndLevel_LevelRiderTable`.
- `[static]` Start release ends the animation, Start held ends the character screen.

## Hypotheses

- `[hypothesis]` The `EndLevel_LevelRiderTable` variants are the level rival and Natasha's advice; test:
  render the records.
- `[hypothesis]` The 5-frame DMA/swap creates the victory animation at 12 fps; test:
  capture the animation timing.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Capture the level-up | — (non-demo; needs a completed level) | — | static analysis only |

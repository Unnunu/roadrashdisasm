# Module card: `src/screens/endlevel.asm`

- **ROM range:** `0x008342`–`0x008FB3` (`src/race/road_render.asm` starts at `0x8FB4`)
- **Status:** line-by-line (static; non-demo only)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/endlevel.md`

## Role / purpose
Level-complete sequence: plays the per-level victory animation, then shows a rider/
quote level-up screen, increments the player's level, rebuilds the level opponents and
regenerates the password, and returns to the main menu. Entered when all five courses
of a level are finished in 1st-4th (`RaceResults_ram_Outcome == 4`).

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `EndLevel_Init` | `0x8342` | `src/core/top_level.asm` `0x7E9FA` | Build the animation stage. |
| `EndLevel_GameTick` | `0x8AEE` | fade wrapper | Animation timing/input/swap. |
| `EndLevel_UpdateAnimation` | `0x8B94` | top-level frame loop | Animation script update. |
| `EndLevel_InitVictoryCharacter` | `0x8682` | `GameTick` end stage | Level-up rider screen. |
| `EndLevel_GameTickVictoryCharacter` | `0x8A1A` | fade wrapper | Rider-screen update/input. |
| `EndLevel_AdvanceLevel` | `0x8946` | `InitCharacterScreen` | Advance level/opponents/password. |

## External calls / dependencies
- Callers: `src/core/top_level.asm`.
- Uses `UncompressW/B`, `UncompressToVRAM`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`,
  `EncodeString`, `Menu_ShowMessage`, `DmaWriteVRAM`, `DmaWriteCRAM`,
  `UpdateAnimation2`, `Race_FinishFrame`, `Race_SwapFrames`, `GetInputPlayerA/B`,
  `MenuPassword_CreatePassword`, `Audio_Update/3/4`.

## Hacks / bugs / quirks
- Different VRAM layout from the menus (`$1000` sprites, `$2000` H-scroll, `$3000`
  window, `$1280` background). `[static]`
- `EndLevel_Init` clears only the first H-scroll entry, two VSRAM words and four SAT
  entries. `[static]`
- The level-up rider is selected before the level is incremented. `[static]`
- Start release ends the victory animation; Start held ends the character screen.
- Level 5's limit `123` is one past the script's last valid frame `122`, so one no-op
  animation frame is consumed. `[static]`
Full list: the related analysis page.

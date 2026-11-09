# Analysis: `src/screens/endlevel.asm` (level-complete victory + level-up)

- **Module:** level-complete sequence: victory animation, then the level-up character
  screen (increments the player level and rebuilds the opponents)
- **ROM range:** `0x008342`–`0x008FB3` (`src/race/road_render.asm` starts at `0x8FB4`)
- **Status:** analyzed statically (non-demo only; no capture)
- **Source:** `src/screens/endlevel.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `EndLevel_Init` | `0x8342` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_GameTick` | `0x8AEE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_UpdateAnimation` | `0x8B94` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_InitVictoryCharacter` | `0x8682` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_GameTickVictoryCharacter` | `0x8A1A` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_AdvanceLevel` | `0x8946` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |

## Role & flow

The top level enters this module when the race outcome is 4 (`RaceResults_ram_Outcome == 4`): all
five courses finished in 1st-4th. The module plays the level's victory animation, then
shows a rider/quote level-up screen, increments the player's level, rebuilds the level
opponents and regenerates the password, and returns to the main menu.

1. `EndLevel_Init`: VDP + animation state + assets.
2. `EndLevel_GameTick`/`EndLevel_UpdateAnimation`: play the animation, wait for a
   Start release / 2 s, then `EndLevel_InitVictoryCharacter`.
3. `EndLevel_InitVictoryCharacter` + `EndLevel_AdvanceLevel`: level-up character/quote, increment the
   level, then `EndLevel_GameTickVictoryCharacter` waits for Start and exits.

## VDP / VRAM layout (differs from the menus)

| Register / area | Value |
|---|---|
| Planes A/B | `$4000` (128x32) |
| Window nametable | `$3000` (framebuffer DMA destination) |
| Sprite attribute table | `$1000` |
| H-scroll table | `$2000` |
| Background image | tiles at `$1280`, plane map base tile `$94` |
| Victory animation tiles | `EndLevel_AnimationTiles` -> `$5C00` (`Animation_ram_BaseTile=$2E0`) |
| Window image | `EndLevel_WindowImage` -> `$2020`, 40x14 at (0,4) |
| Font | `$0` |
| Character panel | `unk_7EA66` -> `$9000`, portrait `$C000` |

## Animation

- `EndLevel_Init` points the race animation state at endlevel buffers:
  `Intro_ram_ImageBuffer`, `Intro_TitleScrollTable` (+`$400` sprite table),
  `Race_ram_FrameReady`; base tile `$2E0`; script `EndLevel_AnimationData` decompressed to the
  image buffer.
- `EndLevel_UpdateAnimation`: per level frame counts `EndLevel_FrameCounts` = `35,54,81,91,123`
  (`Menu_ram_PlayerLevel-1`); calls `UpdateAnimation2` with the script `EndLevel_AnimationScript`
  (x=`$80`, y=`$80`), `Race_FinishFrame`; increments `EndLevel_ram_AnimFrame`.
- `EndLevel_GameTick`: every 5 frames (`EndLevel_ram_SpriteSwapDelay=5`) when the next frame is ready,
  DMA the next sprite table (`NextScrollTable+$400` -> `$1000`, `$140` words) and
  `Race_SwapFrames`; decrements the message timer; when `EndLevel_ram_AnimFrame < 0`
  it ends the animation stage.
- End of animation: waits for a Start **release** (changed Start bit and not pressed)
  or a 120-frame timer; sets `EndLevel_ram_AnimFrame = -1`; the next GameTick calls
  `EndLevel_InitVictoryCharacter` and switches `ram_UpdateFunction` to
  `EndLevel_GameTickVictoryCharacter`.

## Level-up character screen

- Same portrait layout as `src/screens/rider_intro.asm`: panel `unk_7EA66` at (2,5) 12x14, portrait
  at (3,6) 10x12, name at (3,19), quote at (16,y/2) with stride 128.
- Rider table `EndLevel_LevelRiderTable` (`0x19F12`): 5 levels x 2 variants (8-byte
  `quote_ptr,image_ptr` records, same asset format). Level 1-5 variants include the
  level rival (Biff/Slater/Ikira/Sergio/Helldog) and Natasha with a congratulation/
  advice quote. Index `(level-1)*$10 + (Rand & 8)`; the current level is read **before**
  `EndLevel_AdvanceLevel` increments it.
- Message id `0x180` (group 48: blank + Start prompt); 120-frame (2 s) cycle; Start
  **held** ends.

## `EndLevel_AdvanceLevel` (level advance)

- Player A/B: clear the outcome (`ram_FF0526/28`), clear the five places
  (`Menu_ram_PlayerA/BPlaces +0/2/4/6/8`), increment the level
  (`Menu_ram_PlayerA/BLevel`), clamp at 5, rebuild the opponent list
  (`Menu_ram_PlayerA/BOpponents` = `$4B` then 15 words `(level-1)*$F + 0..14`), and
  regenerate the password (`MenuPassword_CreatePassword`).

## Data / tables

| Address | Data |
|---|---|
| `$8C8C` | 5 per-level animation frame counts (35,54,81,91,123). |
| `$8DC2` | Victory animation script (fed to `UpdateAnimation2`). |
| `$19F12` | 5 levels x 2 level-up riders. |
| `$80000` | Victory animation tile set. |
| `$7F400` | Window image (40x14). |
| `$8BF12` | Animation data decompressed at init. |

The strings at `$8C96`, `$8D02`, `$8D16`, `$8D52`, `$8D8A` ("To go to the next level,
you need to earn ... more.", "Continue play at Current level", "The next level will be
level") are **not referenced** in the disassembled source; they duplicate the tail data
in `src/screens/race_results.asm` (`$6C94`..). Likely dead/legacy text. `[static]`

## RAM

- `EndLevel_ram_AnimFrame`; `EndLevel_ram_SpriteSwapDelay` (5-frame swap delay).
- Race animation state: `Animation_ram_BaseTile` (`$2E0`), `Animation_ram_SpriteIndex`,
  `Race_ram_FrameReady/FrameReady2`, `Race_ram_Current/NextSpriteAttributeTable`,
  `Race_ram_Current/NextScrollTable`, `Race_ram_Current/NextSpriteTileArray`,
  `Race_ram_SpriteDestination` (`$8680`), `Race_ram_SpriteSize1/2`,
  `Race_ram_Current/NextVScrollInfo`.
- `Menu_ram_Player`, `PlayerLevel`, `PlayerA/BLevel`, `PlayerA/BPlaces`,
  `PlayerA/BOpponents`, `Menu_ram_CurrentMessageId/NextMessageTimer`,
  `MainMenu_ram_Buttons/ChangedButtonsPlayerA/B`.

## Quirks / notes

- The window nametable is `$3000` and the H-scroll/sprite tables are at `$2000`/`$1000`,
  unlike the menu screens (`$7000`/`$6000`). `[static]`
- The victory animation reuses the race animation engine (`UpdateAnimation2`,
  `Race_FinishFrame`, `Race_SwapFrames`) with endlevel buffers and script. `[static]`
- The level is incremented **after** the level-up rider record is selected, so the
  portrait is for the completed level. `[static]`
- The unused level-up text duplicates the `src/screens/race_results.asm` tail. `[static]`

## Dynamic status

The demo skips the end-level branch; reach it by completing all five courses in 4th
place or better in the native console. The tables/flow above are static.


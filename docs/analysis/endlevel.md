# Analysis: `endlevel.asm` (level-complete victory + level-up)

- **Module:** level-complete sequence: victory animation, then the level-up character
  screen (increments the player level and rebuilds the opponents)
- **ROM range:** `0x008342`–`0x008FB3` (`8FB4.asm` starts at `0x8FB4`)
- **Status:** analyzed statically (non-demo only; no capture)
- **Source:** `endlevel.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `EndLevel_Init` | `0x8342` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_GameTick` | `0x8AEE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_UpdateAnimation` | `0x8B94` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_InitCharacterScreen` | `0x8682` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `EndLevel_GameTickCharacterScreen` | `0x8A1A` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `sub_8946` | `0x8946` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |

## Role & flow

The top level enters this module when the race outcome is 4 (`ram_FF0918 == 4`): all
five courses finished in 1st-4th. The module plays the level's victory animation, then
shows a rider/quote level-up screen, increments the player's level, rebuilds the level
opponents and regenerates the password, and returns to the main menu.

1. `EndLevel_Init`: VDP + animation state + assets.
2. `EndLevel_GameTick`/`EndLevel_UpdateAnimation`: play the animation, wait for a
   Start release / 2 s, then `EndLevel_InitCharacterScreen`.
3. `EndLevel_InitCharacterScreen` + `sub_8946`: level-up character/quote, increment the
   level, then `EndLevel_GameTickCharacterScreen` waits for Start and exits.

## VDP / VRAM layout (differs from the menus)

| Register / area | Value |
|---|---|
| Planes A/B | `$4000` (128x32) |
| Window nametable | `$3000` (framebuffer DMA destination) |
| Sprite attribute table | `$1000` |
| H-scroll table | `$2000` |
| Background image | tiles at `$1280`, plane map base tile `$94` |
| Victory animation tiles | `unk_80000` -> `$5C00` (`Animation_ram_BaseTile=$2E0`) |
| Window image | `unk_7F400` -> `$2020`, 40x14 at (0,4) |
| Font | `$0` |
| Character panel | `unk_7EA66` -> `$9000`, portrait `$C000` |

## Animation

- `EndLevel_Init` points the race animation state at endlevel buffers:
  `Intro_ram_ImageBuffer`, `Intro_TitleScrollTable` (+`$400` sprite table),
  `Race_ram_FrameReady`; base tile `$2E0`; script `unk_8BF12` decompressed to the
  image buffer.
- `EndLevel_UpdateAnimation`: per level frame counts `unk_8C8C` = `35,54,81,91,123`
  (`Menu_ram_PlayerLevel-1`); calls `UpdateAnimation2` with the script `unk_8DC2`
  (x=`$80`, y=`$80`), `Race_FinishFrame`; increments `EndLevel_ram_AnimFrame`.
- `EndLevel_GameTick`: every 5 frames (`ram_FF0D24=5`) when the next frame is ready,
  DMA the next sprite table (`NextScrollTable+$400` -> `$1000`, `$140` words) and
  `Race_SwapFrames`; decrements the message timer; when `EndLevel_ram_AnimFrame < 0`
  it ends the animation stage.
- End of animation: waits for a Start **release** (changed Start bit and not pressed)
  or a 120-frame timer; sets `EndLevel_ram_AnimFrame = -1`; the next GameTick calls
  `EndLevel_InitCharacterScreen` and switches `ram_UpdateFunction` to
  `EndLevel_GameTickCharacterScreen`.

## Level-up character screen

- Same portrait layout as `character.asm`: panel `unk_7EA66` at (2,5) 12x14, portrait
  at (3,6) 10x12, name at (3,19), quote at (16,y/2) with stride 128.
- Rider table `unk_19F12` (`0x19F12`): 5 levels x 2 variants (8-byte
  `quote_ptr,image_ptr` records, same asset format). Level 1-5 variants include the
  level rival (Biff/Slater/Ikira/Sergio/Helldog) and Natasha with a congratulation/
  advice quote. Index `(level-1)*$10 + (Rand & 8)`; the current level is read **before**
  `sub_8946` increments it.
- Message id `0x180` (group 48: blank + Start prompt); 120-frame (2 s) cycle; Start
  **held** ends.

## `sub_8946` (level advance)

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
in `race_results.asm` (`$6C94`..). Likely dead/legacy text. `[static]`

## RAM

- `EndLevel_ram_AnimFrame`; `ram_FF0D24` (5-frame swap delay).
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
- The unused level-up text duplicates the `race_results.asm` tail. `[static]`

## Dynamic status

The demo skips the end-level branch; reach it by completing all five courses in 4th
place or better in the native console. The tables/flow above are static.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `sub_8946` | `EndLevel_AdvanceLevel` | level/opponents/password update | high |
| `EndLevel_InitCharacterScreen` | `EndLevel_InitVictoryCharacter` | level-up rider screen | high |
| `EndLevel_GameTickCharacterScreen` | `EndLevel_GameTickVictoryCharacter` | same | high |
| `unk_19F12` | `EndLevel_LevelRiderTable` | 5 levels x 2 riders | high |
| `unk_8C8C` | `EndLevel_FrameCounts` | per-level frame counts | high |
| `unk_8DC2` | `EndLevel_AnimationScript` | animation data | high |
| `unk_80000` | `EndLevel_AnimationTiles` | tile set at `$5C00` | medium |
| `unk_7F400` | `EndLevel_WindowImage` | window image | medium |
| `unk_8BF12` | `EndLevel_AnimationData` | decompressed at init | medium |

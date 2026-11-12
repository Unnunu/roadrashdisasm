# Analysis: `src/screens/endlevel.asm` (level-complete victory + level-up)

- **Module:** level-complete sequence: victory animation, then the level-up character
  screen (increments the player level and rebuilds the opponents)
- **ROM range:** `0x008342`–`0x008FB3` (`src/race/road_render.asm` starts at `0x8FB4`)
- **Status:** line-by-line (static; non-demo only; no capture)
- **Source:** `src/screens/endlevel.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/animation.md`, `docs/analysis/rider_intro.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `EndLevel_Init` | `0x8342` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `EndLevel_GameTick` | `0x8AEE` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `EndLevel_UpdateAnimation` | `0x8B94` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `EndLevel_InitVictoryCharacter` | `0x8682` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `EndLevel_GameTickVictoryCharacter` | `0x8A1A` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `EndLevel_AdvanceLevel` | `0x8946` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |

## Role & flow

The top level enters this module when the race outcome is 4
(`RaceResults_ram_Outcome == 4`): all five courses finished in 1st-4th. The module
plays the level's victory animation, then shows a rider/quote level-up screen,
increments the player's level, rebuilds the level opponents and regenerates the
password, and returns to the main menu.

1. `EndLevel_Init`: VDP + animation state + assets.
2. `EndLevel_GameTick`/`EndLevel_UpdateAnimation`: play the animation, wait for a
   Start release / 2 s, then `EndLevel_InitVictoryCharacter`.
3. `EndLevel_InitVictoryCharacter` + `EndLevel_AdvanceLevel`: level-up character/quote,
   increment the level, then `EndLevel_GameTickVictoryCharacter` waits for Start and
   exits.

## VDP / VRAM layout (differs from the menus)

| Register / area | Value |
|---|---|
| Planes A/B | `$4000` (128x32) |
| Window nametable | `$3000` (framebuffer DMA destination; full-screen via WindowY=28) |
| Sprite attribute table | `$1000` |
| H-scroll table | `$2000` |
| Background image | tiles at `$1280`, plane map base tile `$94` (`+$4E8`) |
| Victory animation tiles | `EndLevel_AnimationTiles` -> `$5C00` (`Animation_ram_BaseTile=$2E0`) |
| Window image | `EndLevel_WindowImage` -> `$2020`, 40x14 at (0,4), map `+$368`, palette `+$2E4` |
| Font | `$0` |
| Character panel | `RiderIntro_PortraitPanel` -> `$9000`, map `+$168` |
| Gamepad | `img_Gamepad` -> `$A000`, map `+$B48` |
| Rider portrait | image header -> `$C000` |

## Animation

- `EndLevel_Init` points the race animation state at endlevel buffers:
  `Intro_ram_ImageBuffer`, `Intro_TitleScrollTable` (+`$400` sprite table),
  `Race_ram_FrameReady`; base tile `$2E0`; script `EndLevel_AnimationData` decompressed
  to the image buffer (`$5066` bytes).
- `EndLevel_UpdateAnimation`: `EndLevel_FrameCounts` holds the **inclusive last frame
  index** per level (`35,54,81,91,123`, selected by `Menu_ram_PlayerLevel-1`). It calls
  `UpdateAnimation2` with the shared script `EndLevel_AnimationScript` (x=`$80`,
  y=`$80`) whenever a frame buffer is free, then `Race_FinishFrame`; increments
  `EndLevel_ram_AnimFrame`.
- `EndLevel_GameTick`: `EndLevel_ram_SpriteSwapDelay=5` is decremented before the sign
  test, so a reload gives **six** GameTick calls per swap (five calls without a DMA,
  the sixth DMA). It DMAs `NextScrollTable+$400` -> `$1000` (`$140` words = 80 SAT
  entries) and calls `Race_SwapFrames`. The DMA period is therefore ~10 Hz at 60 Hz;
  how many generated script frames are visible depends on the buffer handoff (dynamic
  question).
- End of animation: waits until both frame buffers are free, then for a Start
  **release** (changed Start bit and not pressed) or a 120-frame timer; sets
  `EndLevel_ram_AnimFrame = -1`; the next GameTick calls
  `EndLevel_InitVictoryCharacter` and switches `ram_UpdateFunction` to
  `EndLevel_GameTickVictoryCharacter`.
- Level 5 uses limit `123`, one past the script's last valid frame `122`: the extra
  call makes `UpdateAnimation2` return without drawing, but `Race_FinishFrame` still
  runs, so one no-op frame is consumed.

## `EndLevel_AnimationScript` (`$8DC2`–`$8FB3`)

`UpdateAnimation2` script format: `.l tilemap_base`, `.w last frame index`, then
`frame_count+1` `.l` frame pointers. The source now mirrors `RaceHud_NeedleScript`.

| Field | Value |
|---|---|
| Size | `0x1F2` = 6 + 123*4 bytes; ends exactly at `$8FB4` |
| Tilemap base | `$00080000` = `EndLevel_AnimationTiles`; unused by `UpdateAnimation2` |
| Frame count | `122` (last index; 123 valid frames `0..122`) |
| Pointers | 123 absolute addresses; first `Intro_ram_ImageBuffer` (`$FF509C`) = `+$0000`, last `+$5024` |
| Decompressed data | `$5066` bytes at `Intro_ram_ImageBuffer` |
| Frame 0/1 | 0 sprites (empty lead-in) |
| Level boundaries | level 1: `0..35`; level 2 extends to `54`; level 3 to `81`; level 4 to `91`; level 5 valid to `122` |

## Level-up character screen

- Same portrait layout as `src/screens/rider_intro.asm`: panel `RiderIntro_PortraitPanel`
  at (2,5) 12x14, portrait at (3,6) 10x12, name at (3,19), quote at (16,y/2) with
  stride 128 -> rows 3,5,7,9 (the endlevel quotes have header `y=7`).
- Rider table `EndLevel_LevelRiderTable` (`0x19F12`): 5 levels x 2 variants (8-byte
  `quote_ptr,image_ptr` records, 16 bytes per level). Level 1-5 variants include the
  level rival (Biff/Slater/Ikira/Sergio/Helldog) and Natasha with a congratulation/
  advice quote. Index `(level-1)*$10 + (Rand & 8)`; the current level is read **before**
  `EndLevel_AdvanceLevel` increments it.
- The portrait pointer points after an 8-byte prefix; its odd bytes hold the pointer to
  a 10-byte header (`-6` image offset, `-4` nametable offset, `-2` palette offset). The
  name string pointer is at quote header `-10`, with a 6-byte descriptor before the
  10-character name.
- `$50000000` before the gamepad load is a VRAM write to `$1000`; it clears the first
  two SAT entries so the animation sprites disappear.
- Message id `0x180` (group 48: blank + Start prompt); the next-message timer reloads
  `$78` (120) and advances one 8-byte `Message_MsgArray` entry; Start **held** ends.
  The frame buffer is DMAed to `$3000` every call.

## `EndLevel_AdvanceLevel` (level advance)

- Player A/B: clear the outcome (`Race_ram_PlayerA/BOutcome`), clear the five places
  (`Menu_ram_PlayerA/BPlaces +0/2/4/6/8`), increment the level
  (`Menu_ram_PlayerA/BLevel`), clamp at 5, rebuild the opponent list
  (`Menu_ram_PlayerA/BOpponents` = `$4B` player id + 15 words
  `(level-1)*$F + 0..14` = 16 words), and regenerate the password
  (`MenuPassword_CreatePassword`).

## Data / tables

| Address | Data |
|---|---|
| `$8C8C` | 5 per-level last animation frame indices (35,54,81,91,123). |
| `$8C96` | Dead text: duplicate of `RaceResults_StrNextLevelShort`. |
| `$8D02` | Dead text: ASCII with bit 7 set ("You aren't ready for"); duplicate of `RaceResults_StrNotReadyEncoded`. |
| `$8D16` | Dead text: duplicate of `RaceResults_StrNotReadyTail`. |
| `$8D52` | Dead text: duplicate of `RaceResults_StrContinuePlay`. |
| `$8D8A` | Dead text: duplicate of `RaceResults_StrNextLevel`. |
| `$8DC2` | `EndLevel_AnimationScript` (see above). |
| `$19F12` | 5 levels x 2 level-up riders. |
| `$7F400` | Window image (40x14). |
| `$80000` | Victory animation tile set. |
| `$8BF12` | Animation data decompressed at init. |

The strings at `$8C96`, `$8D02`, `$8D16`, `$8D52`, `$8D8A` are **not referenced** in
the disassembled source; they duplicate the tail data in
`src/screens/race_results.asm` (`$6C94`..). Dead/legacy text. `[static]`

## RAM

- `EndLevel_ram_AnimFrame` (`$FF0D22`); `EndLevel_ram_SpriteSwapDelay` (`$FF0D24`,
  6-call DMA period).
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
- `EndLevel_Init` clears only the first H-scroll entry, the first two VSRAM words and
  four SAT entries; the remaining VDP state is left from the previous screen. `[static]`
- The victory animation reuses the race animation engine (`UpdateAnimation2`,
  `Race_FinishFrame`, `Race_SwapFrames`) with endlevel buffers and script. `[static]`
- The level is incremented **after** the level-up rider record is selected, so the
  portrait is for the completed level. `[static]`
- The unused level-up text duplicates the `src/screens/race_results.asm` tail. `[static]`

## Dynamic status

The demo skips the end-level branch; reach it by completing all five courses in 4th
place or better in the native console. The tables/flow above are static. Visual
verification is not required for the line-by-line pass; only the composed screen and
the generated-vs-displayed animation cadence remain optional dynamic checks.

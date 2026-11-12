# Analysis: `src/screens/race_results.asm` (post-race results / bust / repair)

- **Module:** post-race result screens: normal standings, caught-by-cops, bike repair
- **ROM range:** `0x005F28`–`0x006DBF` (`src/screens/highscore.asm` starts at `0x6DC0`)
- **Status:** analyzed statically; line-by-line pass done (demo skips the screen; rendering dynamic TODO)
- **Source:** `src/screens/race_results.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RaceResults_Init` | `0x5F28` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawStandings` (normal results) | `0x62CE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawBusted` (cops) | `0x647E` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawRepair` (repair) | `0x67AC` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_GameTick` | `0x6A90` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_HandleInput` | `0x6BD4` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `DrawString` | `0x6C5E` | [x] | [x] | - | - | - | - | unused helper |

## Role & flow

After a race the top-level flow (`src/core/top_level.asm` `0x7E8F4`) runs `Race_ComputeStandings` and
`Race_ComputeResults` (race outcome/fines), then loops through
`RaceResults_Init`/`RaceResults_GameTick`. The screen shows one of:

- **Normal results** (`Race_EventBuffer != $FFFF`): "race results" title, the track image,
  the top finishers, and the player's row highlighted.
- **Caught by cops** (`Race_EventBuffer == $FFFF`, `Race_CopIndex != 0`): a police-officer
  portrait/quote and the fine, or GAME OVER if the player cannot pay.
- **Bike repair** (`Race_EventBuffer == $FFFF`, `Race_CopIndex == 0`): a rider/mechanic
  portrait and the repair cost, or GAME OVER if the player cannot pay.

Start exits (top-level: outcome 4 -> EndLevel screen, otherwise back to the menu);
A opens the high-score table; C opens the bike shop; B shows the cash/password box.

## Outcome flags (computed by `Race_ComputeResults` in `src/race/race_core.asm`)

| Address | Meaning |
|---|---|
| `Race_ram_PlayerAOutcome`/`Race_ram_PlayerBOutcome` | Player A/B race outcome; copied to `RaceResults_ram_Outcome`. |
| `RaceResults_ram_Outcome` | 0 = a course not completed; >4 = a course worse than 4th; 4 = all five courses in 1st-4th (level complete). |
| `Race_EventBuffer` | 16-long race sort/event buffer; first word `$FFFF` = busted or bike destroyed. |
| `Race_CopIndex` | Cop/officer index (1..5) when busted; 0 = bike destroyed. |
| `RaceResults_ram_Amount` | Fine/repair amount: cop fine = `PlayerLevel * $14`; repair = 10% of the bike price (`Shop_dPrices`), deducted from money. |
| `ram_FF1414`/`FF1418`/`FF141A` | Standings string header/text, height, width (built by `src/race/race_core.asm`). |
| `Menu_ram_PlayerLevel` | Level (1..5) for the fine, repair and congratulations text. |

Message group by outcome: 0 -> index 21 (`Message_StrCompleteEveryCourse`: complete
every course); >4 -> index 28 (`Message_StrComplete4thPlace`: complete every course in
4th place or better); 4 -> index 35 (`Message_ram_DynamicRecord` = `Message_StrCongratulations`
congratulations with the level digit).

## Normal results (`RaceResults_DrawStandings`)

- Title `RaceResults_TitleTiles` -> VRAM `$9000`, 27x2 at (7,1), base tile `$480`.
- Track image `RaceResults_TrackImagePtrs[track]` -> `$B000`, 36x11 at (2,5), base `$580`;
  nametable `RaceResults_TrackNametableOffsets[track]+4`; palette `RaceResults_TrackPaletteOffsets[track]`; image offset
  `RaceResults_TrackImageOffsets[track]` (all zero).
- Standings `ram_FF1414`: encode, set palette 3 (`$6000`) on all cells; player's place
  from `Menu_ram_PlayerAPlaces/BPlaces[track]` (clamped to 4), clear bit `$2000`
  (palette 2) on that row; draw at the header position with stride 64.
- The player's row is the only visually distinct row; the top 4 finishers come from the
  race's standings string.

## Caught by cops (`RaceResults_DrawBusted`)

- Title `RaceResults_BustedTitleTiles` -> `$9000`, 0x15x2 at (0xA,1), base `$480`.
- Panel `RiderIntro_PortraitPanel` -> `$B000`, 12x14 at (2,5), base `$580`.
- Select the cop portrait from `RaceResults_CopTablePos` (money >= 0, 5x4 variants) or `RaceResults_CopTableNeg`
  (money < 0, 5x2), index `Race_CopIndex-1`. The positive table uses `andi #$18` (4 variants);
  the negative table uses `and.w ($8).w`, i.e. the high word of the bus-error vector at
  `$000008`, which is `$0000` in this ROM, so its variant is always 0.
- Same asset format as `src/screens/rider_intro.asm`: 8-byte interleaved size/header prefix; header
  gives name string, image/nametable/palette offsets. Draw 10x12 at (3,6), name at
  (3,19), quote at (16,y/2) with stride 128.
- Message: `Message_StrCaughtByCops` "Caught by the cops / Your fine -" with
  `RaceResults_ram_Amount` formatted by `Race_FormatNumber`, or
  `Message_StrCantAffordBail` "Can't afford bail / GAME OVER"; drawn at (16,18),
  stride 64.
- Cop names in the table: O'Leary, O'Rourke, Flynn, O'Shea, O'Connor.

## Bike repair (`RaceResults_DrawRepair`)

- Panel `RiderIntro_PortraitPanel` -> `$B000`, 12x14 at (2,5).
- Select the portrait from `RaceResults_LevelTablePos` (money >= 0, 5 levels x4 variants) or
  `RaceResults_LevelTableNeg` (money < 0, 5x2), index `Menu_ram_PlayerLevel-1`; the negative
  table's random variant is likewise forced to 0 by the `$000008` mask.
- Message: `Message_StrBikeNeedsRepairs` "Your bike needs repairs -" with
  `RaceResults_ram_Amount` formatted, or `Message_StrNoMoneyForRepairs`
  "No money for repairs / GAME OVER".
- Level-table names: Biff, Slater, Ikira, Sergio, Helldog.

## Status box, congratulations, audio

`RaceResults_Init` repurposes `MenuPassword_StrPasswordStatus` as a 5-row x 12-column box at
(14,22): player name (10 chars), "cash" + right-aligned money (`Race_FormatMoney` writes
backwards into the row), and the 24-char password (two rows). The record header is
overwritten with y=22, x=14, height=5, width=12. With negative money the code subtracts 2
from the height field at `MenuPassword_StrPasswordStatus+4`, so the box shrinks to 3 rows
and the password is hidden. It copies `Message_StrCongratulations` ("Congratulations! ... on
level 1") to `Message_ram_DynamicRecord` and patches the level digit. If not busted:
`Audio_StopMusic`, song 9, `Audio_StartMusic`; the bust path plays `Audio_StartMusic(10)`.

## Input & messages

- `GetInput` returns 1 = pressed. Start (bit 7) is tested **while held**, so a Start
  still held from the previous screen exits at once. A (bit 6) and C (bit 5) on a
  **new press** select high score/shop; B (bit 4) on a new press shows the cash/password
  group for 25 s (timer 1500, blink 0x1E).
- Message cycle: every 300 frames (5 s) advance by 8; on the `$FFFFFFFF` terminator
  reset to the group start (0xA8/0xE0/0x118) instead of exiting. The initial and B
  timers are 1500 frames.
- Button prompts (`Message_StrPressStartTrackSelection` Start,
  `Message_StrPressAHighScores` A, `Message_StrPressBRaceResults` B,
  `Message_StrPressCNewBikes` C) come from `Message_MsgArray`; `Menu_ShowMessage`
  draws them.

## VDP / assets

Same video configuration as the main menu: planes A/B `$4000`, window `$7000` (64x28,
WindowY 28), sprite/HScroll `$6000`, 128x32, display on, H-int off. Background
`img_MainMenu_Background` -> `$8000`, gamepad -> `$A000` (plane), font -> `$0`, panel
`RiderIntro_PortraitPanel` -> `$B000`, portrait -> `$C000`; frame buffer -> `$7000`.

Track-image tables (`src/data/race_misc_data.asm`):

| Address | Contents |
|---|---|
| `$7E670` | 5 long pointers to track images (index `trackId*2`). |
| `$7E684` | 5 words image offsets in the decompressed buffer (all 0). |
| `$7E68E` | 5 words nametable offsets. |
| `$7E698` | 5 words palette offsets. |

Result portrait tables (8-byte records `quote_ptr, image_ptr`):

| Address | Selection | Variants |
|---|---|---|
| `$19D32` | level, money >= 0 | 5 levels x 4 |
| `$19DD2` | level, money < 0 | 5 levels x 2 |
| `$19E22` | cop, money >= 0 | 5 x 4 |
| `$19EC2` | cop, money < 0 | 5 x 2 |

## Quirks / unused data

- `RaceResults_ram_DrawRoutine` is set to the active draw routine
  (`RaceResults_DrawStandings`/`RaceResults_DrawBusted`/`RaceResults_DrawRepair`) but is
  never read in the disassembled source. `[static]` (write-only; purpose TODO)
- `and.w ($8).w,d0` in the negative-money portrait paths ANDs the RNG result with the
  high word of the 68000 bus-error vector at `$000008` = `$0000`; both negative tables
  therefore always use their first record of each pair while still advancing the RNG.
- The status-box clears use 16-byte stores although the rows are 12 bytes wide; the extra
  4 bytes run into the next row and are overwritten by that row's own write. With negative
  money the height field is reduced from 5 to 3, hiding both password rows.
- The tail data is byte-identical to the unreferenced endlevel tail; `StrNotReadyEncoded`
  is ASCII with bit 7 set (XOR `$80` -> "You aren't ready for") and `EncodeString` maps
  such bytes to spaces, so the block is not a usable text record as-is.
- `DrawString` (`0x6C5E`) is not called by this module (the shop has its own
  `Shop_DrawString`); the source itself notes "not sure this function belongs to this
  file". `[static]`
- The tail data `RaceResults_StrNextLevelShort`, `RaceResults_StrNotReadyEncoded`,
  `RaceResults_StrNotReadyTail`, `RaceResults_StrContinuePlay`,
  `RaceResults_StrNextLevel` ("To go to the next level, you need to earn ... more.",
  "Continue play at Current level", "The next level will be level") is not referenced in
  the source and duplicates the unreferenced `endlevel.asm` tail; dead/legacy data.
  `[static]`
- The demo path skips this module (`src/core/top_level.asm` `0x7E8B4` -> menu), so a dynamic
  capture needs the non-demo race.

## Dynamic status

Not captured: the demo skips results and forcing the non-demo race needs input. Table
contents and the flag logic are parsed statically from `baserom.md` and `src/race/race_core.asm`.
To confirm visually: finish a non-demo race in the native console and inspect the
standings/police/repair screens.


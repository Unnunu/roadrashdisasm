# Analysis: `src/screens/message.asm` (tooltips / button prompts)

- **Module / routine:** message/tooltip system, blinking controller-button prompts, shared
  strings and data tables
- **ROM range:** `0x004226`–`0x00575F` (`src/screens/rider_sprites.asm` starts at `0x5760`)
- **Status:** analyzed (static; icon layout/cadence not verified in BlastEm)
- **Source:** `src/screens/message.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Message_ShowEmpty` | `0x4226` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_ShowNoop` | `0x4268` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_Clear` | `0x426A` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonA` | `0x42AA` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_DrawButtonA` | `0x42D0` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonB` | `0x4302` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_DrawButtonB` | `0x432A` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonsAB` | `0x4362` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonC` | `0x4392` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonStart` | `0x43F6` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkDirPadHorizontal` | `0x445E` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_DrawDirPadHorizontalIcon` | `0x4486` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkDirPadVertical` | `0x44D6` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_DrawDirPadVerticalIcon` | `0x44FE` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkDirectionalPad` | `0x454E` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_MsgArray` | `0x457E` | [x] | [x] | [x] | - | [x] | - | analyzed |

## Screen context

- The message field is the bottom `40x6` cells (x=0..39, y=22..27) of
  `Menu_ram_FrameBuffer` (the 64x28 window nametable, DMA'd to VRAM `$7000`; see
  `src/screens/menu_main.asm`).
- Text uses the font (`$0000`) via `EncodeString` + `WriteNametableToBuffer`.
- Button icons are tiles from the **gamepad image** at VRAM `$A000` (tile base `$500`,
  nametable base `$2500` = palette line 1): A = tile 4, B = tiles 5/6, C = 7/8,
  Start = 9/$A/$B, directional pad = 0/$2FF/$2/$3 and $C/$D/$E/$F/$2FF.
- `$2FF` is a relative blank word: `$2FF + $2500 = $27FF`, i.e. the default tile
  `$7FF` at VRAM `$FFE0` with palette line 1.
- **Signature note:** `WriteNametableToBuffer`/`Masked` take `d0 = width`,
  `d1 = height` (their source headers had `d0`/`d1` swapped; corrected in
  `src/screens/menu_main.asm`). The show functions below use `d0=width`, `d1=height`.
- Text records share one layout: `dc.w y,x,height,width` followed by
  `height*width` ASCII bytes. `EncodeString` converts the bytes through
  `dStringCodeTable` to font tile indices.

## Message array (`Message_MsgArray`, `0x457E`)

Entries are 8 bytes: `dc.l text_pointer,show_function`. The index is
`Menu_ram_CurrentMessageId / 8` (`Menu_ram_CurrentMessageId` is always a multiple of 8).
A show-function pointer of `$FFFFFFFF` is a group terminator; a text pointer of
`$FFFFFFFF` means "no text". `Menu_ShowMessage` (menu_main) draws the text after calling
the show function.

| Row/ID | Text pointer | Show function | Group |
|---|---|---|---|
| 0 | `StrOnePlayerModeSelected` | `Message_ShowEmpty` | main-menu status |
| 1 | `StrTwoPlayerModeSelected` | `Message_ShowEmpty` |  |
| 2 | `StrMusicOn` | `Message_ShowEmpty` |  |
| 3 | `StrMusicOff` | `Message_ShowEmpty` |  |
| 4 | `Menu_ram_TempString` | `Message_ShowEmpty` | race tooltip |
| 5 | `MenuPassword_StrPasswordStatus` | `Message_ShowEmpty` | password status |
| 6-10 | `Message_StrPressStartToRace`/`...APlayerSelection`/`...BMusicToggle`/`...CPassword`/`...DirPadSelectTrack` | Start/A/B/C/dpad blink | main-menu tooltips |
| 11 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 12-15 | `StrPressStartToExit`/`StrPressABToChangeLetter`/`StrPressCToSelectOtherPlayer`/`StrUseDirPadToMoveCursor` | Start/AB/C/dpad | password tooltips |
| 16 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 17 | `Message_StrBlank` | `Message_ShowEmpty` | rider intro (unreached blank) |
| 18 | `Message_StrBlank` | `Message_ShowEmpty` | rider intro first message |
| 19 | `StrPressStartToExit` | `Message_BlinkButtonStart` | rider intro |
| 20 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 21-26 | `MenuPassword_StrPasswordStatus`, `Message_StrCompleteEveryCourse`, Start/A/B/C | | race results: course incomplete |
| 27 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 28-33 | `MenuPassword_StrPasswordStatus`, `Message_StrComplete4thPlace`, Start/A/B/C | | race results: worse than 4th |
| 34 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 35-40 | `MenuPassword_StrPasswordStatus`, `ram_FF089A`, Start/A/B/C | | race results: level cleared |
| 41 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 42-46 | `Message_StrBlankCell` (no-op) + Start/A/B/C | | high-score screen |
| 47 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 48-49 | `Message_StrBlank`, `Message_StrPressStartTrackSelection` | Empty/Start | end-level / victory |
| 50 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 51-58 | `Message_StrBikeDescShuriken400` … `...Diablo1000` | `Message_ShowEmpty` | bike descriptions (shop) |
| 59-66 | `ram_FF089A`, `Message_StrTradeInCredit`, `ram_FF07C2`+`Message_BlinkDirPadHorizontal`, `ram_FF082E`+`Message_BlinkDirPadHorizontal`, `Shop_StrBuyNewBike`+C, Start/A/B | | shop tooltips |
| 67 | `$FFFFFFFF` | `$FFFFFFFF` | end |

`Menu_BuildRaceTooltip` writes the race distance into the fifth line of the selected
`Menu_StrRace*` record: it copies 108 bytes, then writes the fractional digit at
relative offset 97, `'.'` at 96, and the integer digits backwards from 95. The text
`miles` starts at offset 98, so shorter values leave the leading spaces of the 10-cell
field intact.

## Show / blink functions

Every blink function:

1. `Message_Clear` (fills the 40x6 field with `$7FF`, black/default).
2. `counter = (counter + 1) & ButtonBlinkPeriod`; `mask = ~(period >> 1)`;
   draw only when `(counter & mask) == 0` (the "on" half of the period).
3. Draw the icon tiles at fixed positions:
   - A: tile 4 at (10,25), 1x1, base `$2500`.
   - B: tiles 5/6 at (11,24), 1x2.
   - C: tiles 7/8 at (12,24), 1x2.
   - Start: tiles 9/$A/$B at (9,23), 3x1.
   - Directional pad: `Message_BlinkDirPadHorizontal` (left/right pair; tiles
     0/$2FF/$2FF/2/1/$2FF/$2FF/3 at 3,24, width 4, height 2) +
     `Message_BlinkDirPadVertical` (up/down pair; tiles $C/$D/$2FF/$2FF/$2FF/$2FF/$E/$F
     at 4,23, width 2, height 4). `Message_BlinkDirectionalPad` calls only the
     draw-only labels (`Message_DrawDirPadHorizontalIcon`/`...VerticalIcon`).
   - `Message_BlinkButtonsAB` = A + B.
4. The text (if any) is drawn by `Menu_ShowMessage` after the show function.

`Message_ShowEmpty` fills the field with font space tiles; `Message_Clear` fills it with
the default tile `$7FF`; `Message_ShowNoop` is a no-op show function (high-score row 42).
The C and Start draw paths call `Message_Clear` a second time; the first clear is
redundant `[static]`.

The blink period (`Message_ram_ButtonBlinkPeriod`, `$FF05E8`) is set by the screens
(e.g. `$3F` in the menus/intro; `$1E`/`30` in some screens); with `$3F` the icon is on
for 32 frames and off for 32 (≈1 s at 60 Hz). `Message_ram_ButtonBlinkCounter`
(`$FF05E6`) is shared and incremented per call.

## Shared strings / data tables

`src/screens/message.asm` also holds data used by other screens:

- Password prompts: `StrPressStartToExit` `0x479E`, `StrPressABToChangeLetter` `0x47BC`,
  `StrPressCToSelectOtherPlayer` `0x4800`, `StrUseDirPadToMoveCursor` `0x4844`.
- Main-menu confirmations: `StrOnePlayerModeSelected` `0x4888`,
  `StrTwoPlayerModeSelected` `0x48F4`, `StrMusicOn` `0x4960`, `StrMusicOff` `0x49A4`.
- `Menu_dRaceNameTable` `0x49E8`: five long pointers (track ids 0,2,4,6,8) to
  `Menu_StrRaceSierraNevada` `0x49FC`, `Menu_StrRacePacificCoast` `0x4A68`,
  `Menu_StrRaceRedwoodForest` `0x4AD4`, `Menu_StrRacePalmDesert` `0x4B40`,
  `Menu_StrRaceGrassValley` `0x4BAC`; used by `Menu_BuildRaceTooltip`.
- `DemoHighScoreTable` `0x4C18`: 7 rows x 20 characters (140 bytes); `Intro_Init` copies
  it into `HighScore_ram_Table` and replaces the player rows.
- Main-menu tooltips: `Message_StrPressStartToRace` `0x4CA4`,
  `Message_StrPressAPlayerSelection` `0x4CE8`, `Message_StrPressBMusicToggle` `0x4D2C`,
  `Message_StrPressCPassword` `0x4D70`, `Message_StrDirPadSelectTrack` `0x4DDC`.
- `MenuPassword_StrStatusTemplate` `0x4E20`: 5x16 "PASSWORD INVALID" template copied
  into `MenuPassword_StrPasswordStatus`.
- `Message_StrBlank` `0x4E78` (5x20 all spaces); `Message_StrBlankCell` `0x4EE4`
  (1x1; the second byte is alignment padding before the next record).
- `Menu_dPasswordLabels` `0x4EEE`: 7x12 "Name"/"Password" labels, drawn twice by
  `Menu_DrawPlayerInfo`.
- Prompt records: `Message_StrPressAHighScores` `0x4F4A`,
  `Message_StrPressCNewBikes` `0x4FB6`, `Message_StrPressStartTrackSelection` `0x4FFA`,
  `Message_StrPressBRaceResults` `0x503E`.
- Shop strings: `Message_StrPressCBuyNewBike` `0x50AA`,
  `Message_StrPressLeftDirPad` `0x5116`, `Message_StrPressRightDirPad` `0x516E`,
  `Message_StrAlreadyOwnBike` `0x51C6`, `Message_StrNeedMoreCredit` `0x520A`,
  `Message_StrTradeInCredit` `0x53A6`, and bike descriptions
  `Message_StrBikeDescShuriken400`…`...Diablo1000` `0x53FE`–`0x5668`.
- Race-results strings: `Message_StrCompleteEveryCourse` `0x5276`,
  `Message_StrComplete4thPlace` `0x52CE`, `Message_StrCongratulations` `0x533A`,
  `Message_StrCaughtByCops` `0x56AC`, `Message_StrCantAffordBail` `0x56D8`,
  `Message_StrBikeNeedsRepairs` `0x5704`, `Message_StrNoMoneyForRepairs` `0x5730`.
- `ram_FF089A`, `ram_FF07C2`, `ram_FF082E`, `Shop_StrBuyNewBike`,
  `Menu_ram_TempString` and `MenuPassword_StrPasswordStatus` are runtime text records
  with the same 8-byte header + character layout, built by the owning screens.

## Verified facts

- `[static]` The message field is 40x6 at (0,22) of the 64x28 window frame buffer.
- `[static]` The message array is 8-byte entries (text pointer + show function), indexed
  by `Menu_ram_CurrentMessageId / 8`.
- `[static]` The button icons are gamepad tiles at VRAM `$A000` (tile base `$500`,
  palette line 1); the blink period logic is `counter & ~(period>>1)`.
- `[static]` `WriteNametableToBuffer`/`Masked` take `d0 = width`, `d1 = height` (source
  headers had them swapped; corrected).
- `[static]` `$2FF + $2500 = $27FF` selects the default blank tile `$7FF`.
- `[static]` The array contains main-menu, rider-intro, password, race-results,
  high-score, end-level and shop groups, plus the race-name pointers and the demo
  high-score table.
- `[static]` Index 17 is never selected: the rider intro starts at 18.
- `[static]` Bike-description records are selected by `51 + bikeId`; their order matches
  `Shop_BikeDescriptions`.

## Hypotheses / open questions

- `U-0006`: `RaceResults_Init` adds the 1-based `Menu_ram_PlayerLevel` (clamped to 4)
  to the ASCII `'1'` in `Message_StrCongratulations` row 4, column 14. The resulting
  digit is therefore `'1' + min(level,4)`; whether the text is intended to show the
  completed level or the next level is not proven.
- `[ ]` Confirm the dpad icon layout and the blink cadence visually in BlastEm.
- `[ ]` Confirm the `$2FF` blank-tile appearance on the real VDP (palette line 1).
- `[ ]` Document the runtime record sizes/ownership with the shop and race-results
  modules.

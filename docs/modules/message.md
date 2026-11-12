# Module card: `src/screens/message.asm`

- **ROM range:** `0x004226`–`0x00575F`
- **Status:** analyzed (static; icon layout/cadence not verified in BlastEm)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/message.md`

## Role / purpose

Bottom-screen tooltip/message system: clears/fills the 40x6 message field, blinks
controller-button prompts (A/B/C/Start/directional pad), and supplies the message array
(text + show function) used by the main menu, password, rider-intro, race-results,
high-score, end-level and shop screens. It also holds shared strings/tables (race names,
demo high score, password labels/status, shop descriptions, busted/repair messages).

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Message_ShowEmpty` | `0x4226` | `Menu_ShowMessage` | Fill the message field with space tiles. |
| `Message_ShowNoop` | `0x4268` | `Message_MsgArray` | No-op show function (also the rts ending `Message_ShowEmpty`). |
| `Message_Clear` | `0x426A` | blink functions, `Menu_ShowMessage` | Fill the field with the default/black tile. |
| `Message_BlinkButtonA/B/AB/C/Start` | `0x42AA`… | `Menu_ShowMessage` | Blink and draw the corresponding gamepad button tiles. |
| `Message_DrawButtonA/B` | `0x42D0`/`0x432A` | blink functions | Draw-only icon entries. |
| `Message_BlinkDirPadHorizontal` / `Message_BlinkDirPadVertical` | `0x445E`/`0x44D6` | `Menu_ShowMessage` | Blink the horizontal (left/right) or vertical (up/down) dpad pair; ids 61/62 use the horizontal pair for the shop left/right prompts. |
| `Message_DrawDirPadHorizontalIcon` / `...VerticalIcon` | `0x4486`/`0x44FE` | `Message_BlinkDirectionalPad` | Draw-only dpad parts. |
| `Message_BlinkDirectionalPad` | `0x454E` | `Menu_ShowMessage` | Blink and draw the complete dpad icon. |
| `Message_MsgArray` | `0x457E` | `Menu_ShowMessage`, screens | 8-byte entries: text pointer + show function. |

## Message field / VDP context

- Bottom `40x6` cells (x=0..39, y=22..27) of `Menu_ram_FrameBuffer` (the 64x28 window
  nametable, DMA'd to VRAM `$7000`; see `src/screens/menu_main.asm`).
- Text: font tiles (`$0000`) via `EncodeString` + `WriteNametableToBuffer`.
- Icons: gamepad image at VRAM `$A000` (tile base `$500`, nametable base `$2500` =
  palette line 1). A=4, B=5/6, C=7/8, Start=9/$A/$B, dpad=0/$2FF/$2/$3 and
  $C/$D/$E/$F/$2FF. `$2FF + $2500 = $27FF` selects default tile `$7FF` (blank).
- `WriteNametableToBuffer`/`Masked` take `d0 = width`, `d1 = height` (source headers in
  `src/screens/menu_main.asm` had them swapped; corrected).
- Text records: `dc.w y,x,height,width` then `height*width` ASCII bytes.

## Message array

8-byte entries: `dc.l text_pointer,show_function`; index = `Menu_ram_CurrentMessageId / 8`
(multiple of 8). A `$FFFFFFFF,$FFFFFFFF` pair terminates a group. Groups:

- 0-5 main-menu status; 6-10 main-menu tooltips; 12-15 password tooltips;
- 17-19 rider intro (index 17 is unreached; the screen starts at 18);
- 21-26 race results, course incomplete; 28-33 worse than 4th; 35-40 level cleared;
- 42-46 high-score screen; 48-49 end-level/victory;
- 51-58 bike descriptions (`51 + bikeId`); 59-66 shop tooltips.

## Blink logic

`counter = (counter + 1) & ButtonBlinkPeriod`; the icon is drawn when
`(counter & ~(period >> 1)) == 0` (the on half). With period `$3F` the icon is on 32
frames / off 32. `Message_ram_ButtonBlinkCounter` (`$FF05E6`) and
`Message_ram_ButtonBlinkPeriod` (`$FF05E8`) are shared; the screens set the period.
The C and Start draw paths clear the field twice (the entry clear is redundant
`[static]`).

## Shared strings / data tables

- `StrPressStartToExit`, `StrPressABToChangeLetter`, `StrPressCToSelectOtherPlayer`,
  `StrUseDirPadToMoveCursor`, `StrOnePlayerModeSelected`, `StrTwoPlayerModeSelected`,
  `StrMusicOn`, `StrMusicOff` (`0x479E`–`0x49A4`).
- `Menu_dRaceNameTable` `0x49E8`: five pointers to `Menu_StrRaceSierraNevada`,
  `...PacificCoast`, `...RedwoodForest`, `...PalmDesert`, `...GrassValley`
  (`0x49FC`–`0x4BAC`), used by `Menu_BuildRaceTooltip`.
- `DemoHighScoreTable` `0x4C18`: 7x20 demo high-score table body (used by `Intro_Init`).
- Main-menu tooltips `Message_StrPressStartToRace`…`Message_StrDirPadSelectTrack`;
  `MenuPassword_StrStatusTemplate` (5x16); `Message_StrBlank` (5x20);
  `Message_StrBlankCell` (1x1 with alignment padding); `Menu_dPasswordLabels` (7x12).
- Prompt records `Message_StrPressAHighScores`, `...CNewBikes`, `...StartTrackSelection`,
  `...BRaceResults`, `...CBuyNewBike`, `...LeftDirPad`, `...RightDirPad`,
  `...AlreadyOwnBike`, `...NeedMoreCredit`.
- Race-results/shop texts `Message_StrCompleteEveryCourse`, `...Complete4thPlace`,
  `...Congratulations`, `...TradeInCredit`, `...BikeDescShuriken400`…`...Diablo1000`,
  `...CaughtByCops`, `...CantAffordBail`, `...BikeNeedsRepairs`,
  `...NoMoneyForRepairs`.
- Runtime text records (`ram_FF089A`, `ram_FF07C2`, `ram_FF082E`, `Shop_StrBuyNewBike`,
  `Menu_ram_TempString`, `MenuPassword_StrPasswordStatus`) use the same 8-byte header +
  character layout and are built by the owning screens.

## Verified facts

- `[static]` Message field 40x6 at (0,22); 8-byte message array; text/show-function
  entries; group terminators.
- `[static]` Button icons from gamepad tiles at `$A000`; blink logic as above.
- `[static]` `WriteNametableToBuffer`/`Masked` use `d0=width`, `d1=height`.
- `[static]` `$2FF` is a relative blank word that becomes default tile `$7FF`.
- `[static]` Bike descriptions are indexed by `51 + bikeId` in `Shop_BikeDescriptions`
  order.

## Hypotheses / open questions

- `[ ]` Confirm the dpad icon layout and blink cadence visually.
- `[ ]` Document the runtime record ownership with the shop/race-results/high-score
  modules.

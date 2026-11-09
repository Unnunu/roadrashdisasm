# Module card: `message.asm`

- **ROM range:** `0x004226`–`0x00575F`
- **Status:** analyzed (message system/strings; shared data tables partly TODO)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/message.md`

## Role / purpose

Bottom-screen tooltip/message system: clears/fills the 40x6 message field, blinks
controller-button prompts (A/B/C/Start/directional pad), and supplies the message array
(text + show function) used by the main menu, password, high-score and shop screens. It
also holds shared strings/tables (race names, demo high score, password labels, shop
descriptions).

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Message_ShowEmpty` | `0x4226` | `Menu_ShowMessage` | Fill the message field with spaces. |
| `Message_Clear` | `0x426A` | blink functions | Fill the field with the black/default tile. |
| `Message_BlinkButtonA/B/AB/C/Start` | `0x42AA`… | `Menu_ShowMessage` | Blink and draw the corresponding gamepad button tiles. |
| `Message_BlinkDirectionalPad` | `0x454E` | `Menu_ShowMessage` | Blink and draw the dpad icon (`Message_DrawDirPadVert`+`Message_DrawDirPadRight`). |
| `Message_MsgArray` | `0x457E` | `Menu_ShowMessage` | 8-byte entries: text pointer + show function. |

## Message field / VDP context

- Bottom `40x6` cells (x=0..39, y=22..27) of `Menu_ram_FrameBuffer` (the 64x28 window
  nametable, DMA'd to VRAM `$7000`; see `menu_main.asm`).
- Text: font tiles (`$0000`) via `EncodeString` + `WriteNametableToBuffer`.
- Icons: gamepad image at VRAM `$A000` (tile base `$500`, nametable base `$2500` =
  palette line 1). A=4, B=5/6, C=7/8, Start=9/$A/$B, dpad=0/$2FF/$2/$3 and
  $C/$D/$E/$F/$2FF; `$2FF` = blank/black.
- `WriteNametableToBuffer`/`Masked` take `d0 = width`, `d1 = height` (source headers in
  `menu_main.asm` had them swapped; corrected).

## Message array

8-byte entries: `dc.l text_pointer,show_function`; index = `Menu_ram_CurrentMessageId / 8`
(multiple of 8). Groups: main menu (0-10), end (11), password (12-19), shop/password
status (21-40), high score (42-49), bike descriptions (51-58), shop tooltips (59-66),
end (67). The text pointers are the `Str…` strings or strings from other screens
(`Menu_ram_TempString`, `MenuPassword_StrPasswordStatus`, `ram_FF…`). `$FFFFFFFF` pairs
terminate a group.

## Blink logic

`counter = (counter + 1) & ButtonBlinkPeriod`; the icon is drawn when
`(counter & ~(period >> 1)) == 0` (the on half). With period `$3F` the icon is on 32
frames / off 32. `Message_ram_ButtonBlinkCounter` ($FF05E6) and
`Message_ram_ButtonBlinkPeriod` ($FF05E8) are shared; the screens set the period.

## Shared strings / data tables

- `StrPressStartToExit` `0x479E`, `StrPressABToChangeLetter` `0x47BC`,
  `StrPressCToSelectOtherPlayer` `0x4800`, `StrUseDirPadToMoveCursor` `0x4844`,
  `StrOnePlayerModeSelected` `0x4888`, `StrTwoPlayerModeSelected` `0x48F4`,
  `StrMusicOn` `0x4960`, `StrMusicOff` `0x49A4`.
- `Menu_dRaceNameTable` race-name/tooltip pointers (used by `Menu_BuildRaceTooltip` in `menu_main`).
- `unk_4C18` demo high-score table (used by `intro.asm`).
- `unk_4CA4`…`unk_4DDC` main-menu tooltips, `unk_4E20` ".. password invalid ..",
  `unk_4E78`/`unk_4EE4`/`word_4EEE` password labels, `unk_4F4A`…`unk_5668`
  shop/password/high-score tooltips and bike descriptions.
- `ram_FF089A`, `ram_FF07C2`, `ram_FF082E` RAM strings used as message text pointers.

## Verified facts

- `[static]` Message field 40x6 at (0,22); 8-byte message array; text/show-function
  entries; group terminators.
- `[static]` Button icons from gamepad tiles at `$A000`; blink logic as above.
- `[static]` `WriteNametableToBuffer`/`Masked` use `d0=width`, `d1=height`.

## Hypotheses / open questions

- `[hypothesis]` `Menu_dRaceNameTable`/`unk_25EC0` form the race-name + distance/record tooltip.
- `[ ]` Confirm the dpad icon layout and blink cadence visually.
- `[ ]` Document the shop/high-score tables with those modules.
- `[ ]` Dynamic checks on password/shop screens.


# Analysis: `message.asm` (tooltips / button prompts)

- **Module / routine:** message/tooltip system, blinking controller-button prompts, shared
  strings and data tables
- **ROM range:** `0x004226`–`0x00575F` (`rider_sprites.asm` starts at `0x5760`)
- **Status:** analyzed (message system and strings; shared data tables partly TODO)
- **Source:** `message.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Message_ShowEmpty` | `0x4226` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_Clear` | `0x426A` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonA` | `0x42AA` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_DrawButtonA` | `0x42D0` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonB` | `0x4302` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_DrawButtonB` | `0x432A` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonsAB` | `0x4362` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonC` | `0x4392` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkButtonStart` | `0x43F6` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `sub_445E` | `0x445E` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `sub_44D6` | `0x44D6` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_BlinkDirectionalPad` | `0x454E` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Message_MsgArray` | `0x457E` | [x] | [x] | [x] | - | [x] | - | analyzed |

## Screen context

- The message field is the bottom `40×6` cells (x=0..39, y=22..27) of
  `Menu_ram_FrameBuffer` (the 64×28 window nametable, DMA'd to VRAM `$7000`; see
  `menu_main.asm`).
- Text uses the font (`$0000`) via `EncodeString` + `WriteNametableToBuffer`.
- Button icons are tiles from the **gamepad image** at VRAM `$A000` (tile base `$500`,
  nametable base `$2500` = palette line 1): A = tile 4, B = tiles 5/6, C = 7/8,
  Start = 9/$A/$B, directional pad = 0/$2FF/$2/$3 and $C/$D/$E/$F/$2FF; `$2FF` is the
  blank/black tile.
- **Signature note:** `WriteNametableToBuffer`/`Masked` actually take `d0 = width`,
  `d1 = height` (their source headers had `d0`/`d1` swapped; corrected in `menu_main.asm`).
  The show functions below use `d0=width`, `d1=height`.

## Message array (`Message_MsgArray`, `0x457E`)

Entries are 8 bytes: `dc.l text_pointer,show_function`. The index is
`Menu_ram_CurrentMessageId / 8` (`Menu_ram_CurrentMessageId` is always a multiple of 8).
`Menu_ShowMessage` (menu_main) draws the text after calling the show function.

| Row/ID | Text pointer | Show function | Group |
|---|---|---|---|
| 0 | `StrOnePlayerModeSelected` | `Message_ShowEmpty` | main menu messages |
| 1 | `StrTwoPlayerModeSelected` | `Message_ShowEmpty` |  |
| 2 | `StrMusicOn` | `Message_ShowEmpty` |  |
| 3 | `StrMusicOff` | `Message_ShowEmpty` |  |
| 4 | `Menu_ram_TempString` | `Message_ShowEmpty` | race tooltip |
| 5 | `MenuPassword_StrPasswordStatus` | `Message_ShowEmpty` | password status |
| 6-10 | `unk_4CA4/4CE8/4D2C/4D70/4DDC` | Start/A/B/C/dpad blink | main-menu tooltips |
| 11 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 12-15 | `StrPressStartToExit`/`StrPressABToChangeLetter`/`StrPressCToSelectOtherPlayer`/`StrUseDirPadToMoveCursor` | Start/AB/C/dpad | password tooltips |
| 16 | `$FFFFFFFF` | `$FFFFFFFF` | end |
| 17-19 | `unk_4E78`,`unk_4E78`,`StrPressStartToExit` | Empty/Empty/Start | password/shop |
| 20 | end | | |
| 21-26 | password status, `unk_5276`, Start/A/B/C (`unk_4FFA/4F4A/503E/4FB6`) | | shop/status |
| 27 | end | | |
| 28-33 | password status, `unk_52CE`, Start/A/B/C | | shop/status |
| 34 | end | | |
| 35-40 | password status, `ram_FF089A`, Start/A/B/C | | shop/status |
| 41 | end | | |
| 42-46 | `unk_4EE4` (no-op `sub_4268`), Start/A/B/C | | high-score tooltips |
| 47 | end | | |
| 48-49 | `unk_4E78` (empty), `StrPressStartToExit` (Start) | | high-score/exit |
| 50 | end | | |
| 51-58 | `unk_53FE`..`unk_5668` | `Message_ShowEmpty` | bike descriptions (shop) |
| 59-66 | `ram_FF089A`, `unk_53A6`, `ram_FF07C2`+`sub_445E`, `ram_FF082E`+`sub_445E`, `Shop_StrBuyNewBike`+C, Start/A/B | | shop tooltips |
| 67 | end | | |

The tooltip texts are `dc.w y,x,height,width` + character data (`Str…`); the array also
points to strings in other screens (`Menu_ram_TempString`, `MenuPassword_StrPasswordStatus`,
`ram_FF…` shop strings).

## Show / blink functions

Every blink function:

1. `Message_Clear` (fills the 40×6 field with `$7FF`, black).
2. `counter = (counter + 1) & ButtonBlinkPeriod`; `mask = ~(period >> 1)`;
   draw only when `(counter & mask) == 0` (the "on" half of the period).
3. Draw the icon tiles at fixed positions:
   - A: tile 4 at (10,25), 1×1, base `$2500`.
   - B: tiles 5/6 at (11,24), 1×2.
   - C: tiles 7/8 at (12,24), 1×2.
   - Start: tiles 9/$A/$B at (9,23), 3×1.
   - Directional pad: `sub_445E` (tiles 0/$2FF/$2FF/2/1/$2FF/$2FF/3 at 3,24, width 4,
     height 2) + `sub_44D6` (tiles $C/$D/$2FF/$2FF/$2FF/$2FF/$E/$F at 4,23, width 2,
     height 4), combined by `Message_BlinkDirectionalPad`.
   - `Message_BlinkButtonsAB` = A + B.
4. The text (if any) is drawn by `Menu_ShowMessage` after the show function.

`Message_ShowEmpty` fills the field with space tile codes; `Message_Clear` fills it with
the black/default tile; `sub_4268` is a no-op show function (high-score row 42).

The blink period (`Message_ram_ButtonBlinkPeriod`, `$FF05E8`) is set by the screens
(e.g. `$3F` in the menus/intro; `30` in some screens); with `$3F` the icon is on for
32 frames and off for 32 (≈1 s at 60 Hz). `Message_ram_ButtonBlinkCounter`
(`$FF05E6`) is shared and incremented per call.

## Shared strings / data tables

`message.asm` also holds data used by other screens:

- `StrPressStartToExit` `0x479E`, `StrPressABToChangeLetter` `0x47BC`,
  `StrPressCToSelectOtherPlayer` `0x4800`, `StrUseDirPadToMoveCursor` `0x4844`,
  `StrOnePlayerModeSelected` `0x4888`, `StrTwoPlayerModeSelected` `0x48F4`,
  `StrMusicOn` `0x4960`, `StrMusicOff` `0x49A4`.
- `unk_49E8` (5 race-name/tooltip pointers -> `unk_49FC`, `unk_4AE8` (at `0x4A68`),
  `unk_4AD4`, `unk_4B40`, `unk_4BAC`); used by `sub_3B56` for the race tooltip.
- `unk_4C18` demo high-score table (used by `Intro_Init`).
- `unk_4CA4`…`unk_4DDC` main-menu tooltip texts; `unk_4E20` ".. password invalid ..";
  `unk_4E78`, `unk_4EE4`, `word_4EEE` password labels/status; `unk_4F4A`…`unk_5668`
  shop/password/high-score tooltips and bike descriptions.
- `ram_FF089A`, `ram_FF07C2`, `ram_FF082E` are RAM strings in the shop/high-score state
  used as message text pointers.

Some of these tables belong to the shop/high-score/race modules; their detailed layout
will be documented with those modules. `unk_49E8`'s label `unk_4AE8` is a legacy name
(the string is at `0x4A68`).

## Verified facts

- `[static]` The message field is 40×6 at (0,22) of the 64×28 window frame buffer.
- `[static]` The message array is 8-byte entries (text pointer + show function), indexed
  by `Menu_ram_CurrentMessageId / 8`.
- `[static]` The button icons are gamepad tiles at VRAM `$A000` (tile base `$500`,
  palette line 1); the blink period logic is `counter & ~(period>>1)`.
- `[static]` `WriteNametableToBuffer`/`Masked` take `d0 = width`, `d1 = height` (source
  headers had them swapped; corrected).
- `[static]` The array contains main-menu, password, high-score and shop tooltip groups,
  the race-name pointers, and the demo high-score table.

## Hypotheses / open questions

- `[hypothesis]` The exact `unk_49E8` race-name strings and `unk_25EC0` value table feed
  the race distance/record tooltip (`sub_3B56`).
- `[ ]` Confirm the dpad icon layout and the blink cadence visually.
- `[ ]` Document the shop/high-score data tables with those modules.
- `[ ]` Verify the message rows/blink on the password and shop screens in BlastEm.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `sub_445E` | `Message_DrawDirPadVert` | vertical dpad tiles | medium |
| `sub_44D6` | `Message_DrawDirPadRight` | right dpad tiles | medium |
| `unk_49E8` | `Menu_dRaceNameTable` | 5 race-name pointers | high |

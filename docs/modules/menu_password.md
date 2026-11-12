# Module card: `src/screens/menu_password.asm`

- **ROM range:** `0x002446`–`0x0033FF`
- **Status:** analyzed line-by-line (password format/checksum reimplemented; visual
  cursor confirmation TODO)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/menu_password.md`

## Role / purpose

Password entry/edit screen. Shows player A/B names and passwords, lets the player edit
characters, switches players, validates the entered password, applies it to the game state
(level, money, bike, places, opponents), and returns to the main menu.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `MenuPassword_GameTick` | `0x24CC` | `ram_UpdateFunction` on this screen | Frame buffer DMA, input, cursor, status/tooltip, exit. |
| `MenuPassword_HandleInput` | `0x2710` | GameTick | A/B cycle chars, C switch player, directions move cursor. |
| `MenuPassword_UpdateStatus` | `0x2A1E` | GameTick/input | Status text, validate/apply password. |
| `MenuPassword_ValidatePassword` | `0x2C32` | status/exit | Checks the 24-char password checksum. |
| `MenuPassword_ParsePassword` | `0x2D1E` | status/exit | Applies a valid password to player A/B state. |
| `MenuPassword_CreatePassword` | `0x2F3A` | race/shop/endlevel | Generates a password from the current state. |
| `MenuPassword_SelectCurrentTrack` | `0x2B2E` | status/main menu | Picks the next track from the places array. |
| `MenuPassword_SwapPlayerBlocks` | `0x2BEE` | input | Moves the selection panel when switching player. |
| `MenuPassword_SetCursorPos` | `0x2B18` | GameTick | Writes one frame-buffer cell's palette byte. |
| `MenuPassword_DrawNamesAndPasswords` | `0x3306` | input/status | Draws the four strings into the frame buffer. |

## Control flow / state machine

- **GameTick:** DMA `Menu_ram_FrameBuffer + $200` (rows 4-27) to VRAM `$7200`; read pads
  A/B and edge-detect Start (exit on **release**); restore the previous cursor cell,
  handle newly pressed buttons and hold-repeat, draw the cursor, blink the status/tooltip;
  `Menu_ShowMessage`, `Audio_Update`.
- **Tooltips:** `Menu_ram_CurrentMessageId` is a byte offset into `Message_MsgArray`
  (8-byte entries). The screen starts at 96 (index 12) and cycles the four password
  tooltips; the `$FFFFFFFF` terminator wraps back to 96.
- **Start release -> endStage:** `MenuPassword_UpdateStatus` (validate/parse/status), draw
  player info and race selection, install `MainMenu_GameTick`.
- **Editing:** A = previous glyph, B = next glyph, C = switch player A/B,
  directions move the cursor. Hold-repeat after 30 frames, then every 8 frames (C and
  Start do not repeat). Alphabet = `dStringDecodeTable` (50 glyphs).
- **Cursor:** palette toggle in an existing cell. Screen column = 4 (A) / 24 (B) +
  `CursorX`. Name row (`Y=9`) uses `CursorX` 1..10, char index `CursorX-1`; password
  rows (`Y=15/16`) use `CursorX` 0..11 as the char index and skip separator columns
  5 and 6.

## Password format (24 chars, 2 rows of 12)

`w[i]` = character `i`, row-major.

| Words | Contents |
|---|---|
| 0-4 | places in the 5 races (low nibble; 0 = not played) |
| 5-6 | separator spaces |
| 7-10 | 20-bit career score (`Player_ram_CareerScoreA`/`Player_ram_CareerScoreB`, 5 bits each; `U-0005`) |
| 11-16 | 24-bit signed money (nibbles << 1; bit0 = checksum) |
| 17-18 | separator spaces |
| 19 | level (3 bits) |
| 20 | bike id (3 bits) + 2-bit Natasha encounter counter (`ram_FF0522`/`ram_FF0524`; `U-0004`) |
| 21-23 | checksum chars (sum of 7-11, sum of 12-16, XOR of those) |

Checksum: `sum = w0-4 + w7-10 + (w11-16 & ~1) + w19-20`; the mask is the low bits of
`w11..w16` packed with `w11` as bit0. Require `(sum & $3F) == mask`,
`(w21^w22^w23) & $1F == 0`, `w21 == sum(w7..w11) & $1F`,
`w22 == sum(w12..w16) & $1F`.

`MenuPassword_CreatePassword` reverses this. It first encodes the existing string so
the four separator words (`w5,w6,w17,w18`) keep their spaces, writes the data fields,
patches bit0 of the money chars from the low bits of `sum`, writes `w21..w23`, then
decodes the final characters.

`[static]` Python reimplementation: the default template
`01234  5678901234  56789` is invalid (sum&$3F=63, mask=21); the initial state
(places 0, 20-bit field 0, money 100, level 1, bike 0) produces the valid password
`00000  00001010D8  101MN` (validation sum 21, mask 21).

## Track selection

`MenuPassword_SelectCurrentTrack` returns the first race with place 0 (not yet played);
if all five races have a place, it returns the race with the largest place (worst
finish). The even id (0,2,4,6,8) doubles as the byte offset into the places array.

## VDP / screen context

- 64x24 window (rows 4-27) of `Menu_ram_FrameBuffer` (`$FFB62C`, 64x28, `$E00`), DMA'd to
  VRAM `$7200` (`$600` words).
- Text font base `$6000` (palette line 3), `WriteNametableToBuffer` with plane width 64.
- Cursor: `SetCursorPos` writes the high byte of `d0` to a frame-buffer cell; `$6000`
  restores palette 3, `0` draws/erases the cursor cell (palette 0).
- VDP registers are set by the main menu (`src/screens/menu_main.asm`): planes A/B `$4000`, window `$7000` (64x28 frame buffer, covers the screen); `$7200` is window row 4.

## RAM / ROM & structures

- `MenuPassword_ram_StrPlayerNamePtr` `$FF041A`, `StrPlayerPasswordPtr` `$FF041E`;
  `CursorY` `$FF0422`, `CursorX` `$FF0424`, `HoldTimer` `$FF0426`,
  `HeldButtons` `$FF0428`, `CurrentButtons` `$FF05C6`.
- Password strings `StrPlayerAPassword` `$FF042A` (size $20), `StrPlayerBPassword`
  `$FF044A`; names `StrPlayerAName` `$FF04A4`, `StrPlayerBName` `$FF04B6`.
- Status string `MenuPassword_StrPasswordStatus` `$FF067E`; template `MenuPassword_StrStatusTemplate`
  (`0x4E20`, 5x16).
- Menu/player state: `Menu_ram_Player` `$FF0508`, levels `$FF050C/$FF050E`, money
  `$FF0518/$FF051C`, 20-bit fields `$FF0510/$FF0514`, Natasha counter `$FF0522/$FF0524`,
  places `$FF052E/$FF0538`, opponents `$FF0546/$FF0566`, bike ids `$FF0542/$FF0544`.
- `Menu_ram_FrameBuffer` `$FFB62C` (size `$E00`).
- `Menu_DefaultPassword` `0x2446`, `Menu_DefaultName` `0x245E`, dead `unk_2468`
  `0x2468` (no pointer reference).

## External calls / dependencies

- `DmaWriteVRAM`, `EncodeString`/`DecodeString` (intro), `WriteNametableToBuffer`
  (menu_main), `Menu_ShowMessage`, `Menu_DrawPlayerInfo`, `Menu_DrawRaceSelection`,
  `GetInputPlayerA/B`, `Audio_Update`.

## Hacks / bugs / quirks

- Default password is an invalid template; the status message reports invalid until the
  player enters a valid password.
- Start exits on **release**, not press.
- The checksum bits are hidden in the low bits of the money characters.
- The last three chars are checksum, not data.
- The cursor is a palette/high-byte toggle, not a separate sprite.
- `CreatePassword` relies on the existing string to preserve the four separator spaces
  (`w5,w6,w17,w18`); they are never rewritten.
- Two redundant `move.w #$6000` reloads (in GameTick and HandleInput) are dead: both
  A and B branches load the same value.
- `ValidatePassword` has a dead `move.w #$FFFF,d0` at entry.
- `unk_2468` (5x20 "password accepted" text) has no static pointer reference.

## Coverage matrix

See `docs/analysis/menu_password.md` for the full matrix.

## Verified facts

- `[static]` The password layout and checksum are as above; the Python reimplementation
  validates the generated initial-state password `00000  00001010D8  101MN`.
- `[static]` A/B cycle characters through `dStringDecodeTable`; C switches player; Start
  release exits to `MainMenu_GameTick`.
- `[static]` The screen DMA's `FrameBuffer + $200` (rows 4-27) to VRAM `$7200`.
- `[static]` `SelectCurrentTrack` picks the first unplayed race, else the worst place.

## Hypotheses / open questions

- `U-0004` `[static]` resolved: the 2-bit `ram_FF0522/24` field is a per-player 3-race
  Natasha encounter counter (latch `3`, decay each race).
- `U-0005` `[static]` resolved: the 20-bit `Player_ram_CareerScoreA/B` field is the career
  score / high-score value (credited per race, never spent).
- `[ ]` Confirm the sample password in BlastEm.
- `[ ]` Confirm the cursor visual and the `SwapPlayerBlocks` panel swap.

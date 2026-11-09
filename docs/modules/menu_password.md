# Module card: `src/screens/menu_password.asm`

- **ROM range:** `0x002446`–`0x0033FF`
- **Status:** analyzed (password format/checksum reimplemented; visual cursor TODO)
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
| `MenuPassword_ValidatePassword` | `0x2C32` | status/exit | Checks the 24-char password checksum. |
| `MenuPassword_ParsePassword` | `0x2D1E` | status/exit | Applies a valid password to player A/B state. |
| `MenuPassword_CreatePassword` | `0x2F3A` | game | Generates a password from the current state. |
| `MenuPassword_DrawNamesAndPasswords` | `0x3306` | input/status | Draws the four strings into the frame buffer. |

## Control flow / state machine

- **GameTick:** DMA `Menu_ram_FrameBuffer + $200` (rows 4-27) to VRAM `$7200`; read pads
  A/B and edge-detect Start (exit on **release**); draw/restore the cursor; handle newly
  pressed buttons and hold-repeat; blink the status/tooltip; `Menu_ShowMessage`,
  `Audio_Update`.
- **Start release -> endStage:** `MenuPassword_UpdateStatus` (validate/parse/status), draw player info and
  race selection, install `MainMenu_GameTick`.
- **Editing:** A = previous character, B = next character, C = switch player A/B,
  directions move the cursor (special cases for the name row/password rows). Hold-repeat
  after 30 frames, then every 8 frames. Character alphabet = `dStringDecodeTable`.

## Password format (24 chars, 2 lines of 12)

| Words | Contents |
|---|---|
| 0-4 | places in the 5 races (low nibble) |
| 5-6 | separator spaces |
| 7-10 | 20-bit progress (`ram_FF0510`/`ram_FF0514`, 5 bits each) |
| 11-16 | 24-bit signed money (nibbles << 1; bit0 = checksum) |
| 17-18 | separator spaces |
| 19 | level (3 bits) |
| 20 | bike id (3 bits) + 2 extra bits (`ram_FF0522`/`ram_FF0524`) |
| 21-23 | checksum chars (sum of 7-11, sum of 12-16, XOR of those) |

Checksum: the low 6 bits of `sum = w0-4 + w7-10 + (w11-16 & ~1) + w19-20` must equal
the low-bit mask of `w11-16`; the three last chars must satisfy the sum/XOR relations.
`MenuPassword_CreatePassword` reverses this: it writes the state, patches the low bits of
the money chars from the sum, and sets the last three chars.

`[static]` Python reimplementation: the default template `01234  5678901234  56789` is
invalid; the initial state (places 0, progress 0, money 100, level 1, bike 0) produces
the valid password `00000  00001010D8  101MN` (validation sum 21, mask 21).

## VDP / screen context

- 64x24 window (rows 4-27) of `Menu_ram_FrameBuffer` (`$FFB62C`, 64x28, `$E00`), DMA'd to
  VRAM `$7200` (`$600` words).
- Text font base `$6000` (palette line 3), `WriteNametableToBuffer` with plane width 64.
- Cursor: `SetCursorPos` writes the high byte of `d0` to a frame-buffer cell; `$6000`
  restores the text palette, `0` draws/erases the cursor cell.
- VDP registers are set by the main menu (`src/screens/menu_main.asm`): planes A/B `$4000`, window `$7000` (64x28 frame buffer, covers the screen); `$7200` is window row 4.

## RAM / ROM & structures

- `MenuPassword_ram_StrPlayerNamePtr` `$FF041A`, `StrPlayerPasswordPtr` `$FF041E`;
  `CursorY` `$FF0422`, `CursorX` `$FF0424`, `HoldTimer` `$FF0426`,
  `HeldButtons` `$FF0428`, `CurrentButtons` `$FF05C6`.
- Password strings `StrPlayerAPassword` `$FF042A` (size $20), `StrPlayerBPassword`
  `$FF044A`; names `StrPlayerAName` `$FF04A4`, `StrPlayerBName` `$FF04B6`.
- Status string `MenuPassword_StrPasswordStatus` `$FF067E`.
- Menu/player state: `Menu_ram_Player` `$FF0508`, levels `$FF050C/$FF050E`, money
  `$FF0518/$FF051C`, progress `$FF0510/$FF0514`, extra bits `$FF0522/$FF0524`, places
  `$FF052E/$FF0538`, opponents `$FF0546/$FF0566`, bike ids `$FF0542/$FF0544`.
- `Menu_ram_FrameBuffer` `$FFB62C` (size `$E00`).

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

## Coverage matrix

See `docs/analysis/menu_password.md` for the full matrix.

## Verified facts

- `[static]` The password layout and checksum are as above; the Python reimplementation
  validates the generated initial-state password `00000  00001010D8  101MN`.
- `[static]` A/B cycle characters through `dStringDecodeTable`; C switches player; Start
  release exits to `MainMenu_GameTick`.
- `[static]` The screen DMA's `FrameBuffer + $200` (rows 4-27) to VRAM `$7200`.

## Hypotheses / open questions

- `[hypothesis]` `ram_FF0510`/`14` is a 20-bit progress/points value and `ram_FF0522/24`
  an extra bike/upgrade selector.
- `[ ]` Confirm the sample password in BlastEm.
- `[ ]` Confirm `MenuPassword_SelectCurrentTrack` selects the worst-place track and the `MenuPassword_SwapPlayerBlocks` block swap.
- `[ ]` Main-menu VDP setup (`src/screens/menu_main.asm`) remains TODO.


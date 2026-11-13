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
Full list: the related analysis page.

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
Full list: the related analysis page.

# Analysis: `src/screens/menu_password.asm` (password entry / game state)

- **Module / routine:** password entry screen, player name/password editing, password
  validation/parsing/generation
- **ROM range:** `0x002446`–`0x0033FF` (`src/screens/menu_main.asm` starts at `0x3400`)
- **Status:** analyzed (password format/checksum reimplemented; exact visual cursor TODO)
- **Source:** `src/screens/menu_password.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `MenuPassword_GameTick` | `0x24CC` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `MenuPassword_HandleInput` | `0x2710` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `MenuPassword_UpdateStatus` | `0x2A1E` | [x] | [x] | [x] | - | [x] | - | analyzed |
| `MenuPassword_SetCursorPos` | `0x2B18` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `MenuPassword_SelectCurrentTrack` | `0x2B2E` | [x] | [x] | [x] | - | [x] | - | analyzed |
| `MenuPassword_SwapPlayerBlocks` | `0x2BEE` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `MenuPassword_ValidatePassword` | `0x2C32` | [x] | [x] | [x] | - | [x] | [x] | analyzed (Python) |
| `MenuPassword_ParsePassword` | `0x2D1E` | [x] | [x] | [x] | - | [x] | - | analyzed |
| `MenuPassword_CreatePassword` | `0x2F3A` | [x] | [x] | [x] | - | [x] | [x] | analyzed (Python) |
| `MenuPassword_DrawNamesAndPasswords` | `0x3306` | [x] | [x] | [x] | [x] | [x] | - | analyzed |

## Screen / VDP context

- The password screen is drawn into `Menu_ram_FrameBuffer` (`$FFB62C`, 64x28 cells,
  size `$E00`); `MenuPassword_GameTick` DMAs `FrameBuffer + $200` (row 4) to VRAM
  `$7200`, `$600` words = 64x24 cells. Rows 0-3 of the frame buffer belong to the menu
  header; the password screen occupies rows 4-27.
- Text uses font tile base `$6000` (palette line 3) and `WriteNametableToBuffer`
  (plane width 64) after `EncodeString`.
- `MenuPassword_SetCursorPos` writes the **high byte** of `d0` into the frame buffer cell
  (`y*128 + x*2`); the game calls it with `$6000` to restore the text palette and `0`
  to draw/erase the cursor cell. The character (low byte) is unchanged.
- The VDP context is `Menu_Init` (`src/screens/menu_main.asm`): planes A/B share `$4000`, the window
  nametable at `$7000` holds the 64x28 frame buffer, and the window covers the screen
  (`WindowY=28`). The password DMA destination `$7200` is therefore window row 4; the
  64x24 password area occupies rows 4-27. The sprite and H-scroll tables overlap at
  `$6000` (unused by this screen).

## Input / editing

`MenuPassword_GameTick` (`0x24CC`):

- DMA the frame buffer to VRAM `$7200`.
- Read pads A/B; `ChangedButtons = old ^ new`.
- Start handling: if Start is currently pressed -> keep editing; if the **changed** Start
  bit is set (released) -> `.endStage`. The password screen exits on Start **release**.
- Draw/restore the cursor, handle newly pressed buttons, hold-repeat (30-frame delay,
  then every 8 frames), blink the message/tooltip, `Menu_ShowMessage`, `AudioFunc1`.
- `.endStage`: `MenuPassword_UpdateStatus` (validate/parse + status), `Menu_DrawPlayerInfo`, clear the
  `FrameBuffer + $280` region with `$67FF67FF`, `Menu_DrawRaceSelection`, redraw player
  info, install `MainMenu_GameTick`.

`MenuPassword_HandleInput` (`d0` = current SACBRLDU buttons):

| Button | Action |
|---|---|
| A (`$40`) | previous password character (tile index -1, wrap to 49) |
| B (`$10`) | next password character (+1, wrap to 0) |
| C (`$20`) | switch player A/B (swap display blocks, update pointers) |
| Right (`$08`) / Left (`$04`) | move cursor horizontally (special cases for the name row) |
| Down (`$02`) / Up (`$01`) | move cursor vertically between name/password rows |
| Start (`$80`) | exit on release (handled in GameTick) |

The character alphabet is `dStringDecodeTable` (`"0123456789A..Z ?!,.;:$()+-"'`); the
name row uses `MenuPassword_ram_StrPlayerAName/BName`, the two password rows use
`MenuPassword_ram_StrPlayerAPassword/BPassword`. The cursor X/Y and special-case limits
are at `HandleInput`; the name row is Y=9, the password rows Y=15/16.

## Password format (24 characters, 2 lines of 12)

The password characters are font tile indices (from `EncodeString`), not ASCII. The
default string `Menu_DefaultPassword` ("01234  5678901234  56789") is only a **template**
and is invalid (see below); the player edits/enters a real password.

| Word indices | Contents |
|---|---|
| 0-4 | places in the 5 races (low nibble each) |
| 5-6 | separator spaces (skipped by the checksum) |
| 7-10 | 20-bit progress value `ram_FF0510` (5 bits each) |
| 11-16 | 24-bit signed money (6 nibbles, each stored as value << 1; bit0 = checksum) |
| 17-18 | separator spaces |
| 19 | player level (3 bits) |
| 20 | bits 0-2 bike id, bits 3-4 `ram_FF0522` (2 bits) |
| 21-23 | checksum characters |

### Checksum (`MenuPassword_ValidatePassword`, `0x2C32`)

Let `w[0..23]` be the word array:

1. `sum = w[0]+w[1]+w[2]+w[3]+w[4] + w[7]+w[8]+w[9]+w[10]`
   `+ (w[11]&~1)+...+(w[16]&~1) + w[19]+w[20]`.
2. `mask` = the six low bits of `w[11]..w[16]` (LSB of each, in order), packed into a
   6-bit value.
3. Require `(sum & $3F) == mask`.
4. Require `(w[21] ^ w[22] ^ w[23]) & $1F == 0`.
5. Require `w[21] == (w[7]+w[8]+w[9]+w[10]+w[11]) & $1F`.
6. Require `w[22] == (w[12]+w[13]+w[14]+w[15]+w[16]) & $1F`.

`d0` = 0 on success (valid), non-zero on failure; `d1` = `sum`.

### Generation (`MenuPassword_CreatePassword`, `0x2F3A`)

The reverse: encode the current state into the 24 words, patch the low bits of
`w[11]..w[16]` from the low bits of `sum` (making check 3 pass), set
`w[21] = sum(w[7..11]) & $1F`, `w[22] = sum(w[12..16]) & $1F`,
`w[23] = w[21] ^ w[22]`, then `DecodeString` into the password string. Player A/B use
`Menu_ram_*PlayerA/B` state and `ram_FF0510`/`ram_FF0514`.

`[static]` A Python reimplementation of the validator/generator was run:

- default template `01234  5678901234  56789` -> **invalid** (sum=63, mask=21);
- initial state (places 0, progress 0, money 100, level 1, bike 0, extra 0) ->
  **valid password `00000  00001010D8  101MN`** (two lines `00000  00001` /
  `010D8  101MN`), validation sum=21, mask=21.

This is a static result; the game's `CreatePassword`/`ParsePassword` should accept it
(dynamic verification possible by entering it in the password menu).

## Parsing (`MenuPassword_ParsePassword`, `0x2D1E`)

For player A/B (selected by `d0`), a valid password is applied to:

- level `w[19] & 7` -> `Menu_ram_PlayerALevel/BLevel`; opponents =
  `$4B, (level-1)*15 + 0..14`;
- places `w[0..4] & $F` -> `Menu_ram_PlayerA/BPlaces`;
- 20-bit progress `w[7..10]` (5 bits each) -> `ram_FF0510`/`ram_FF0514`;
- 24-bit signed money `w[11..16]` -> `Menu_ram_MoneyPlayerA/B`;
- bike id `w[20] & 7`, extra 2 bits `(w[20] >> 3) & 3` -> `ram_FF0522`/`ram_FF0524`.

## Other functions

- `MenuPassword_UpdateStatus` (`0x2A1E`): builds the status string (`MenuPassword_StrPasswordStatus`
  `$FF067E`, template `unk_2468`/`unk_4E20`), calls `ValidatePassword`; if valid writes
  "NEW", calls `ParsePassword` and `MenuPassword_SelectCurrentTrack`; writes the level digit; on invalid, the
  template remains.
- `MenuPassword_SelectCurrentTrack` (`0x2B2E`): selects `Menu_ram_CurrentTrackId` from the player's 5 race
  places (iterates the places array, tracks the maximum/worst place; track ids 0,2,4,6,8).
- `MenuPassword_SwapPlayerBlocks` (`0x2BEE`): swaps the player A/B name/password display blocks in
  `FrameBuffer + $280` (14 rows x 8 longs) when switching players with C.
- `MenuPassword_DrawNamesAndPasswords` (`0x3306`): encodes and draws all four strings
  (A/B name and password) into the frame buffer with `WriteNametableToBuffer`.

## Verified facts

- `[static]` The password is 24 font-tile indices with the field layout above and a
  6-bit embedded checksum plus three checksum characters.
- `[static]` The default `Menu_DefaultPassword` is a template with an invalid checksum;
  a Python reimplementation of the generator produces a valid password for the initial
  state: `00000  00001010D8  101MN`.
- `[static]` The screen exits to the main menu on Start **release** and applies the
  password via `ParsePassword`.
- `[static]` The screen is a 64x24 window into `Menu_ram_FrameBuffer` DMA'd to VRAM
  `$7200`; VDP registers come from the main-menu setup.

## Hypotheses / open questions

- `[hypothesis]` `ram_FF0510`/`ram_FF0514` are a 20-bit progress/points value; the two
  `ram_FF0522/24` bits are an extra bike/upgrade selector. Names/meaning TODO.
- `[hypothesis]` `MenuPassword_SelectCurrentTrack` chooses the race with the worst recorded place (max place)
  as the current track; confirm with menu/race behavior.
- `[ ]` Confirm the sample password in BlastEm (enter it in the password menu).
- `[ ]` Confirm the exact cursor visual (high-byte palette toggle) and the `MenuPassword_SwapPlayerBlocks`
  block swap.
- `[x]` The main-menu VDP setup is now known: window `$7000`, password rows 4-27 at
  `$7200` (see `docs/analysis/menu_main.md`).

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `MenuPassword_ValidatePassword` | `MenuPassword_VerifyChecksum` | checksum checks | high |


# Analysis: `src/screens/menu_password.asm` (password entry / game state)

- **Module / routine:** password entry screen, player name/password editing, password
  validation/parsing/generation
- **ROM range:** `0x002446`–`0x0033FF` (`src/screens/menu_main.asm` starts at `0x3400`)
- **Status:** analyzed line-by-line (password format/checksum reimplemented); dynamic
  confirmation of the cursor visuals still TODO
- **Source:** `src/screens/menu_password.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/menu_main.md`, `docs/analysis/unknowns.md`

## Coverage matrix

`Line` = line-by-line comment pass. `Algorithm`/`Data`/`Hardware`/`Why` are covered in
the source comments and below.

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Line | Status |
|----------|---------|----------|-----------|------|----------|-----|------|--------|
| `MenuPassword_GameTick` | `0x24CC` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `MenuPassword_HandleInput` | `0x2710` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `MenuPassword_UpdateStatus` | `0x2A1E` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `MenuPassword_SetCursorPos` | `0x2B18` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `MenuPassword_SelectCurrentTrack` | `0x2B2E` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `MenuPassword_SwapPlayerBlocks` | `0x2BEE` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `MenuPassword_ValidatePassword` | `0x2C32` | [x] | [x] | [x] | - | [x] | [x] | analyzed (Python) |
| `MenuPassword_ParsePassword` | `0x2D1E` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `MenuPassword_CreatePassword` | `0x2F3A` | [x] | [x] | [x] | - | [x] | [x] | analyzed (Python) |
| `MenuPassword_DrawNamesAndPasswords` | `0x3306` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |

Data blocks in the file:

- `Menu_DefaultPassword` (`0x2446`): 24-char template, checksum invalid.
- `Menu_DefaultName` (`0x245E`): 10-char initial name `"Player A  "`.
- `unk_2468` (`0x2468`): unreferenced 5x20 text block, marked dead.

## Screen / VDP context

- The password screen is drawn into `Menu_ram_FrameBuffer` (`$FFB62C`, 64x28 cells,
  size `$E00`); `MenuPassword_GameTick` DMAs `FrameBuffer + $200` (row 4) to VRAM
  `$7200`, `$600` words = 64x24 cells. Rows 0-3 of the frame buffer belong to the menu
  header; the password screen occupies rows 4-27.
- Text uses font tile base `$6000` (palette line 3) and `WriteNametableToBuffer`
  (plane width 64) after `EncodeString`.
- `MenuPassword_SetCursorPos` writes the **high byte** of `d0` into the frame buffer cell
  (`offset = y*128 + x*2`); the game calls it with `$6000` to restore palette 3 and `0`
  to draw/erase the cursor cell (palette 0). The character (low byte) is unchanged.
- The VDP context is `Menu_Init` (`src/screens/menu_main.asm`): planes A/B share `$4000`, the window
  nametable at `$7000` holds the 64x28 frame buffer, and the window covers the screen
  (`WindowY=28`). The password DMA destination `$7200` is therefore window row 4; the
  64x24 password area occupies rows 4-27. The sprite and H-scroll tables overlap at
  `$6000` (unused by this screen).

## Text records and encoding

Name and password strings are text records consumed by `EncodeString`/`DecodeString`:

```text
+$00 y (word)  +$02 x (word)  +$04 height (word)  +$06 width (word)
+$08 .. height*width ASCII bytes
```

- Names are `1x10`; passwords are `2x12` (24 characters, row-major).
- `EncodeString` maps each ASCII byte through `dStringCodeTable` (128 words, indexed
  by `char*2`) to a font tile index. Unsupported bytes and controls map to space (36).
- `DecodeString` maps tile indices 0..49 back to ASCII through `dStringDecodeTable`.
- The alphabet is 50 entries: `0-9`, `A-Z`, space, and the punctuation in
  `dStringDecodeTable` (`? ! , . ; : $ ( ) + - " '`). The editor can therefore enter
  glyphs that the password fields do not use; the checksum masks them down.
- All checksum work is done on **tile indices**, not on ASCII bytes.

## Password data structure (24 characters, 2 rows of 12)

`w[i]` = character `i` in row-major order (row 0 = `w0..w11`, row 1 = `w12..w23`).

| Words | Field | Encoding |
|---|---|---|
| `w0..w4` | race places 0..4 | low nibble; 0 = no recorded place (`RACE_PLACE_NONE`) |
| `w5..w6` | separator spaces | not editable, skipped by the checksum |
| `w7..w10` | 20-bit career score (`U-0005`) | 5 bits each; `w7` = bits 19..15 … `w10` = bits 4..0 |
| `w11..w16` | 24-bit signed money | six nibbles, MSB first; stored as `(nibble << 1)` |
| `w17..w18` | separator spaces | not editable, skipped by the checksum |
| `w19` | level | 3 bits (`& 7`) |
| `w20` | bike id + Natasha counter | bits 0..2 = bike id; bits 3..4 = per-player Natasha encounter counter (`U-0004`) |
| `w21..w23` | checksum | see below |

### Why the money characters are even before checksum insertion

Each money character is a tile index equal to `nibble << 1` (`CreatePassword`). This
leaves bit0 free for one checksum bit. `ParsePassword` recovers a nibble with `>>1`;
the parser also accepts odd characters, because validation has already constrained
their low bits.

### Stored-state mapping

| Password field | Player A | Player B |
|---|---|---|
| level `w19 & 7` | `Menu_ram_PlayerALevel` | `Menu_ram_PlayerBLevel` |
| places `w0..w4 & $F` | `Menu_ram_PlayerAPlaces` | `Menu_ram_PlayerBPlaces` |
| 20-bit field `w7..w10` | `Player_ram_CareerScoreA` | `Player_ram_CareerScoreB` |
| money `w11..w16` | `Menu_ram_MoneyPlayerA` | `Menu_ram_MoneyPlayerB` |
| bike id `w20 & 7` | `Menu_ram_BikeIdPlayerA` | `Menu_ram_BikeIdPlayerB` |
| extra `(w20 >> 3) & 3` | `ram_FF0522` | `ram_FF0524` |

`ParsePassword` also rebuilds the 16-word opponent list as `$4B` (the player's own
definition id) followed by `(level-1)*15 + 0..14`.

## Checksum

`MenuPassword_ValidatePassword` first encodes the password string into 24 tile-index
words in `Intro_ram_ImageBuffer`, then:

```text
sum  = w0+w1+w2+w3+w4 + w7+w8+w9+w10 + (w11..w16 & ~1) + w19+w20
mask = (w11&1) | (w12&1)<<1 | (w13&1)<<2 | (w14&1)<<3 | (w15&1)<<4 | (w16&1)<<5

valid iff:
  (sum & $3F) == mask
  (w21 ^ w22 ^ w23) & $1F == 0
  w21 == (w7+w8+w9+w10+w11) & $1F
  w22 == (w12+w13+w14+w15+w16) & $1F
```

`w23` is therefore always `w21 ^ w22`. The `ROXR.B` sequence collects the low bit of
`w11..w16` MSB-first into `d2`; `LSR.W #2` then aligns them with `w11` in bit0. The
`move.w #$FFFF,d0` at function entry is dead (overwritten before use).

`d0` = 0 on success (valid), non-zero on failure; `d1` = `sum`.

### Generation (`MenuPassword_CreatePassword`)

1. `EncodeString` the existing password first. Only `w5,w6,w17,w18` are not overwritten
   below, so this preserves the four separator spaces (the editor never changes them).
2. Write `w0..w4`, `w7..w16`, `w19`, `w20`; zero `w21..w23`.
3. `DecodeString` to the password string, then `ValidatePassword` to obtain `sum` in
   `d1` (the same sum the validator computes).
4. OR the six low bits of `sum` into bit0 of `w11..w16`.
5. Set `w21 = sum(w7..w11) & $1F`, `w22 = sum(w12..w16) & $1F`,
   `w23 = w21 ^ w22`, then `DecodeString` the final text.

## Screen flow and input

`MenuPassword_GameTick` (`0x24CC`, ROM `$24CC-$270F`):

- DMA the frame buffer to VRAM `$7200`.
- Read pads A/B; `ChangedButtons = old XOR new` (press and release edges).
- Start handling: if Start is currently pressed -> keep editing; if the **changed**
  Start bit is set (release, because the press branch did not take it) -> `.endStage`.
  The password screen exits on Start **release**.
- Restore the previous cursor cell (`$6000`) at the stored `CursorX/CursorY`, handle
  newly pressed buttons, hold-repeat, then draw the cursor (`0`) at the (possibly new)
  `CursorX/CursorY`.
- `MessageBlinkTimer` (30 frames) toggles the tooltip text; `NextMessageTimer` (240
  frames) advances `Menu_ram_CurrentMessageId` by 8. The id is a **byte offset** into
  `Message_MsgArray` (8-byte entries). The password screen starts at 96 (index 12,
  first password tooltip) and cycles indices 12-15; the `$FFFFFFFF` group terminator
  wraps it back to 96. If the id ever falls below 96 it is snapped back to 96, but
  `d0` was read before the snap, so that first post-wrap terminator test uses the stale
  offset for one frame (the id itself is already repaired).
- `Menu_ShowMessage`, `Audio_Update`.
- `.endStage`: `MenuPassword_UpdateStatus`, `Menu_DrawPlayerInfo`, clear rows 5-21
  with `$67FF` (default tile `$7FF`, palette 3), `Menu_DrawRaceSelection`,
  `Menu_DrawPlayerInfo`, install `MainMenu_GameTick`.

### Cursor semantics

The cursor is a palette toggle in an existing character cell, not a sprite. The screen
column is `4` (A) or `24` (B) plus `CursorX`:

| Row | `CursorY` | `CursorX` range | Meaning |
|---|---|---|---|
| Name | 9 | 1..10 | character index `CursorX-1` (name record starts at x=5) |
| Password row 0 | 15 | 0..11 | character index `CursorX` (password record starts at x=4) |
| Password row 1 | 16 | 0..11 | character index `12 + CursorX` |

Password columns 5 and 6 are the two separator spaces: Right maps 5 -> 7, Left maps
6 -> 4, so they are never edit targets. Down/Up preserve the screen column, with
5 -> 4 / 6 -> 7 when entering the password rows and 0 -> 1 / >10 -> 10 when returning
to the name row.

`MenuPassword_HandleInput` (`d0` = current SACBRLDU buttons):

| Button | Action |
|---|---|
| A (`$40`) | previous glyph in the 50-entry alphabet (wrap 0 -> 49) |
| B (`$10`) | next glyph (wrap 49 -> 0) |
| C (`$20`) | validate/apply current player, then switch to the other player |
| Right (`$08`) / Left (`$04`) | move cursor horizontally (special cases above) |
| Down (`$02`) / Up (`$01`) | move cursor between name/password rows |
| Start (`$80`) | exit on release (handled in GameTick) |

Hold-repeat: a newly pressed single U/D/L/R/B/A sets `HoldTimer=30` and
`HeldButtons=mask`; after the delay it repeats every 8 frames while no edge occurs.
C and Start are not in the repeat mask, and simultaneous presses do not repeat. The
same handler is used for name and password strings; the address is
`8 + (Y-15)*width + index` (the name row is remapped to `Y=15`, `index-1`).

## Status message (`MenuPassword_UpdateStatus`, `0x2A1E`)

- Selects `Message_MsgArray` index 5 (offset 40, `MenuPassword_StrPasswordStatus`) and
  copies the 5x16 template `MenuPassword_StrStatusTemplate` (`"PASSWORD INVALID"`,
  `"OLD LEVEL IS: 0"`).
- Centers the 10-character player name on row 0: `text + (16-10)/2`.
- Calls `ValidatePassword`. On success it changes row 2 from `"PASSWORD INVALID"` to
  `"PASSWORD   VALID"` (three spaces overwrite `" IN"`) and row 4 from `"OLD"` to
  `"NEW"`, then calls `ParsePassword` and `MenuPassword_SelectCurrentTrack`.
- Whether valid or not, it writes `ASCII '0' + level` at row 4, column 14.

## Track selection (`MenuPassword_SelectCurrentTrack`, `0x2B2E`)

The places array is five words; the even track id (0,2,4,6,8) is also the byte offset
used by `race_core.asm`/`race_results.asm`.

- Return the first race whose place is 0 (not yet played).
- If all five races have a place, return the race with the largest place (worst
  finish). `CMP/BPL` skips on `>=`, so ties keep the earlier race.

## Player switching (`MenuPassword_SwapPlayerBlocks`, `0x2BEE`)

Swaps two 16-cell wide, 14-row panels (rows 5-18): left at `x=2`, right at `x=22`
(8 longs per row, then `+$60` to the same column of the next row). The destination
panel's top-left cell must be the blank space tile (`$6000 + space`), otherwise the
swap is skipped. Only the newly selected side carries the selection border, so the
visible effect is moving the border; `MenuPassword_DrawNamesAndPasswords` then redraws
both name/password fields at their fixed positions.

## Other functions

- `MenuPassword_DrawNamesAndPasswords` (`0x3306`): redraws all four records (A/B name
  and password) at the `y/x` stored in each header with palette 3 and plane width 64.
- `MenuPassword_SetCursorPos` (`0x2B18`): writes one cell's high byte (palette),
  leaving the tile index intact.

## Verified facts

- `[static]` The password is 24 font-tile indices with the field layout above and a
  6-bit embedded checksum plus three checksum characters.
- `[static]` The default `Menu_DefaultPassword` is a template with an invalid checksum:
  `sum & $3F = 63`, `mask = 21`.
- `[static]` A Python reimplementation validates both the template (invalid) and the
  initial-state password `00000  00001010D8  101MN` (valid, `sum=21`, `mask=21`). Its
  money nibbles decode to `0x000064 = 100`, level 1, bike 0.
- `[static]` The screen exits to the main menu on Start **release** and applies the
  password via `ParsePassword` only when `ValidatePassword` succeeds.
- `[static]` The screen is a 64x24 window into `Menu_ram_FrameBuffer` DMA'd to VRAM
  `$7200`; VDP registers come from the main-menu setup.
- `[static]` `MenuPassword_SelectCurrentTrack` selects the first unplayed race, or the
  worst-place race when all five are played.
- `[static]` `unk_2468` has no 32-bit pointer reference in the ROM and is dead data.

## Hypotheses / open questions

- `U-0004` `[static]` resolved: `ram_FF0522/24` is a per-player 3-race Natasha encounter
  counter. `unk_D19A` holds Natasha's actor index per level; attacking her sets
  `ram_FF0520=3`; `Race_ComputeResults` latches/decays the persisted value around
  `$C41A`/`$C45C`. A non-zero value forces the fourth intro variant and the face overlay.
- `U-0005` `[static]` resolved: `Player_ram_CareerScoreA/B` is the 20-bit career score / high-score
  value. `Race_ComputeResults` adds `unk_D1A0[place]*level` to it (together with money),
  `Race_UpdateHighScoreTable` uses it for the high-score entry, and nothing ever spends
  it.
- `[ ]` Confirm the sample password in BlastEm (enter it in the password menu).
- `[ ]` Confirm the exact cursor visual (high-byte palette toggle) and the
  `MenuPassword_SwapPlayerBlocks` panel swap.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `MenuPassword_ValidatePassword` | `MenuPassword_VerifyChecksum` | checksum checks only | high |
| `ram_FF0522`/`ram_FF0524` | `Player_ram_NatashaCounterA/B` | per-player encounter counter (`U-0004`) | medium |

`ram_FF0510/14` -> `Player_ram_CareerScoreA/B` was applied in the static-unknowns pass.

# Analysis: `character.asm` (pre-race rider/opponent intro)

- **Module:** rider/opponent introduction screen shown between the main menu and the race
- **ROM range:** `0x0059C4`–`0x005F27` (`Character_Init` `0x59C4`, `Character_GameTick` `0x5E66`)
- **Status:** analyzed statically; rendering not yet confirmed dynamically (demo skips it)
- **Source:** `character.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Character_Init` | `0x59C4` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Character_GameTick` | `0x5E66` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `unk_19A12` table | `0x19A12` | [x] | [x] | [x] | - | [x] | - | parsed |
| image asset header | - | [x] | [x] | [x] | - | [x] | - | parsed (100 records) |

## Role & flow

`top_level.asm` calls `Character_Init`/`Character_GameTick` at `0x7E78C`/`0x7E790` after
the main-menu fade, **only when `MainMenu_ram_DemoMode == 0`** (`0x7E782`); the demo
branch (`0x7E7CC`) goes to the high-score demo instead. The screen shows the rider you
will race next: portrait, name, a taunt/quote, and an optional extra overlay, then
returns to the race when the held button is released (or after the message timer expires).

## Opponent table (`unk_19A12`, `0x19A12`)

- 8-byte records: `dc.l quote_pointer, image_pointer`.
- Index: `base + variant + (level-1)*$A0 + trackId*$10`,
  `variant` in `{0,8,$10,$18}`, `level` 1..5, `trackId` in `{0,2,4,6,8}` (5 races/level).
- That is `[5 levels][5 tracks][4 variants]`: the variant is a random opponent pick.
- Selection (`0x5BC8`): `d0 = Rand_GetWord & $18`; repeat while `d0 == $18`; if
  `d0 == 0` and `ram_FF0520 > 0`, use `$18` instead. So variants 0/1/2 are random;
  variant 3 (Natasha) replaces variant 0 when the selected player's "extra" field is
  non-zero.
- `ram_FF0520` is copied from `ram_FF0522` (player A) or `ram_FF0524` (player B),
  selected by `Menu_ram_Player`. These are the 2-bit password "extra" field, **not** the
  bike id (`Menu_ram_BikeIdPlayerA/B` is `$FF0542/$FF0544`).
- Parsed opponents include Natasha, Biff, Slater, O'Leary, O'Rourke, Ikira, O'Connor,
  Sergio, Helldog, O'Shea; e.g. level 1 track 0 variants = Natasha, Biff, Slater,
  Natasha (variant 3); level 5 track 0 = O'Connor, Sergio, Helldog, O'Connor.

## Image asset format

The image pointer points **after** an 8-byte prefix at `image-8`. The prefix interleaves
two 32-bit values in its even and odd bytes (big-endian byte positions):

| Bytes | Value |
|---|---|
| even (`b0,b2,b4,b6`) | compressed size, e.g. `$07FE` |
| odd (`b1,b3,b5,b7`) | pointer to a 10-byte header, e.g. `$07FEDA` |

`Character_Init` rebuilds the header pointer from `-7,-5,-3,-1(a3)` (the odd bytes).
Header fields (relative to the pointer `p`):

| Offset | Field | Use |
|---|---|---|
| `-10(p)` | long string pointer | `+6` -> 10-char rider name. |
| `-6(p)` | word image offset | added to `Intro_ram_ImageBuffer`, written to VRAM `$C000`. |
| `-4(p)` | word nametable offset | `+4` -> source map for the 10x12 portrait. |
| `-2(p)` | word palette offset | source of 4x8 longs (64 colors) copied to `Global_ram_Palette`. |

The string pointer points at a 6-byte descriptor followed by the 10-char name (e.g.
`03 10 83 02 03 5B` then `Natasha   `); the descriptor is ignored by this code. The
quote is `8-byte header + width*height text`; the header words are
`y, x, height, width`. Examples: `Natasha`'s quote header `7,16,4,19` -> 19x4 text;
the name header is `19,3,1,10` -> 10x1 at (3,19). Some quotes have a missing space at a
line join in the original data (`jerkswould`, `toface`, `forhelp`, ...); this is raw
ROM text, not a transcription bug.

## Screen layout

| Layer | Content | Position / base |
|---|---|---|
| Planes A/B `$4000` | main-menu background image, 40x28 | `(0,0)`, base tile `$400`, plane width 128 |
| Planes A/B | gamepad image, 12x6 | `(2,22)`, base tile `$500` -> `$A000` |
| Window `$7000` | portrait panel `unk_7EA66`, 12x14 | `(2,5)`, base `$580` -> `$B000` (11 tiles + map) |
| Window | rider portrait, 10x12 | `(3,6)`, base `$600` -> `$C000` |
| Window | extra overlay, 6x7 | `(6,9)`, base `$680` -> `$D000` |
| Window | name, 10x1 | `(3,19)`, base `$6000` (font palette 3) |
| Window | quote, 19x4 | `(16,3)`, stride 128 -> rows 3,5,7,9 |
| Window | message field 40x6 | rows 22-27 (message system) |
| VRAM `$0` | font `img_Intro_Font` | used by name/quote/messages |

The VDP setup is the same as the main menu: planes A/B `$4000`, window `$7000`
(64x28), sprite/HScroll `$6000`, 128x32, display on, H-int off, V-int on.

## `Character_Init` (`0x59C4`)

1. Clear pad state/changed buttons; message blink timer `$FFFF`, button period `$3F`,
   next message timer 300, message id `8*18`.
2. Write the VDP registers; clear HScroll (16 bytes), VSRAM, the default tile `$FFE0`
   (32 bytes), planes `$4000` (0x700 longs), and the frame buffer (`$E00` bytes) to
   `$7FF`.
3. Load/draw the background, gamepad and portrait `unk_7EA66` (see table).
4. Pick the opponent record (above), then:
   - read the name from the image header string pointer;
   - `UncompressW` the portrait; write to VRAM `$C000`; draw 10x12 at `(3,6)`;
   - copy the 64-word palette; copy the 10-char name into a temporary string header
     `(19,3,1,10)`, encode and draw it at `(3,19)`;
   - encode the quote and draw it at `(16, y/2)` with destination stride 128
     (double-spaced rows).
5. If the image is `unk_AF902` (Natasha) and `ram_FF0520 > 0`, load `unk_B1506`
   (`UncompressB`) and draw a 6x7 overlay at `(6,9)` from `ImageBuffer+$548`.
6. Load the font at VRAM `$0`; `Menu_ShowMessage`; DMA the 64x28 frame buffer to
   `$7000`.

## `Character_GameTick` (`0x5E66`)

Per frame: DMA the frame buffer to `$7000`; read pad A, then pad B; on a **release
edge** (`~input & previous raw buttons`; `GetInput` returns 1 = pressed) set
`Race_ram_ActiveController` to 0/1 and end the screen. Otherwise decrement `Menu_ram_NextMessageTimer`; every 300
frames (5 s) advance `Menu_ram_CurrentMessageId` by 8; when the message array entry is
`$FFFFFFFF`, end. Then `Menu_ShowMessage` and `AudioFunc1`. End stage: `AudioFunc4`,
clear `ram_UpdateFunction`, `AudioFunc1`.

Message sequence: index 18 = blank `unk_4E78`, index 19 = `StrPressStartToExit` with
the blinking Start icon, index 20 = terminator. The screen therefore auto-exits after
~10 s if no button is pressed; any button on either pad exits earlier.

## Quirks

- **Background reuse:** `Menu_Init` writes the main-menu background tiles to VRAM
  `$8000`; `Character_Init` writes the same image to `$4000` (which the following
  `WriteNametable` overwrites) while the tile map still references base tile `$400`
  (`$8000`). The visible background relies on the tiles left by the main menu; entering
  this screen directly (debug) would show a wrong background. `[static]`
- The variant-3 record and the extra `unk_B1506` overlay are used only when the
  selected player's "extra" field is non-zero and the opponent image is `unk_AF902`.
  `[static]`
- The quote's destination Y is the header Y shifted right by one; with the 128-cell
  stride this gives double-spaced rows 3,5,7,9. `[static]`
- The portrait palette overwrites all 64 global palette words; the background/gamepad/
  font therefore use the rider palette on this screen. `[static]`

## Dynamic status

The demo path skips this screen (`top_level.asm` `0x7E782`), and the GDB forced-path
experiment (patched `0x7E788` branch) did not reach `Character_Init` within the test
budget. To confirm visually: press Start on the main menu in the native console (non-demo
path), then inspect VRAM `$7000`/the portrait palette. Rendering/positions above are
`[static]`; table contents are parsed deterministically from `baserom.md`.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `Character_Init` | `RiderIntro_Init` | pre-race opponent intro | high |
| `Character_GameTick` | `RiderIntro_GameTick` | same | high |
| `unk_19A12` | `RiderIntro_RecordTable` | [level][track][variant] records | high |
| `unk_AF902` | `RiderIntro_NatashaImage` | name parsed from header | medium |
| `unk_B1506` | `RiderIntro_NatashaBike` | overlay when extra != 0 | low |
| `ram_FF0520` | `Menu_ram_PlayerExtra` | password "extra" field | medium |

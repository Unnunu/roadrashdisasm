# Analysis: `src/screens/rider_intro.asm` (pre-race rider/opponent intro)

- **Module:** rider/opponent introduction screen shown between the main menu and the race
- **ROM range:** `0x0059C4`–`0x005F27` (`RiderIntro_Init` `0x59C4`, `RiderIntro_GameTick` `0x5E66`)
- **Status:** line-by-line analyzed statically; rendering not yet confirmed dynamically (demo skips it)
- **Source:** `src/screens/rider_intro.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RiderIntro_Init` | `0x59C4` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `RiderIntro_GameTick` | `0x5E66` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `RiderIntro_RecordTable` table | `0x19A12` | [x] | [x] | [x] | - | [x] | - | parsed |
| image asset header | - | [x] | [x] | [x] | - | [x] | - | parsed (100 records) |
| `RiderIntro_QuoteData` | `0x16E70` | [x] | [x] | [x] | - | [x] | - | source |

## Role & flow

`src/core/top_level.asm` calls `RiderIntro_Init`/`RiderIntro_GameTick` at `0x7E78C`/`0x7E790` after
the main-menu fade, **only when `MainMenu_ram_DemoMode == 0`** (`0x7E782`); the demo
branch (`0x7E7CC`) goes to the high-score demo instead. The screen shows the rider you
will race next: portrait, name, a taunt/quote, and an optional face overlay, then
returns to the race when the held button is released (or after the message timer expires).

## Opponent table (`RiderIntro_RecordTable`, `0x19A12`)

- 8-byte records: `dc.l quote_pointer, image_pointer`.
- Index: `base + variant + (level-1)*$A0 + trackId*$10`,
  `variant` in `{0,8,$10,$18}`, `level` 1..5, `trackId` in `{0,2,4,6,8}` (5 races/level).
- That is `[5 levels][5 tracks][4 variants]`: the variant is a random opponent pick.
- Selection (`0x5BC8`): `d0 = Rand_NextWord & $18`; repeat while `d0 == $18`; if
  `d0 == 0` and `ram_FF0520 > 0`, use `$18` instead. So variants 0/1/2 are random;
  variant 3 (Natasha) replaces variant 0 when the selected player's Natasha encounter
  counter is non-zero.
- `ram_FF0520` is copied from `ram_FF0522` (player A) or `ram_FF0524` (player B),
  selected by `Menu_ram_Player`. These are the per-player Natasha encounter counters,
  **not** the bike id (`Menu_ram_BikeIdPlayerA/B` is `$FF0542/$FF0544`).
- Parsed opponents include Natasha, Biff, Slater, O'Leary, O'Rourke, Ikira, O'Connor,
  Sergio, Helldog, O'Shea; e.g. level 1 track 0 variants = Natasha, Biff, Slater,
  Natasha (variant 3); level 5 track 0 = O'Connor, Sergio, Helldog, O'Connor.
- Portrait header names `[static]`: 0 Natasha, 1 O'Leary, 2 O'Rourke, 3 Flynn,
  4 O'Shea, 5 O'Connor, 6 Biff, 7 Slater, 8 Ikira, 9 Sergio, 10 Helldog. Each intro
  quote is paired with exactly one portrait/rider.

## Quote data (`src/screens/rider_intro_quotes.asm`, `0x16E70-$19A11`)

- Quote records are `8-byte header + height*width text`: header `(word y, word x,
  word height, word width)`, text is fixed-size and space-padded.
- `RiderIntro_Init` passes `(a0)=y` (shifted), `2(a0)=x`, `4(a0)=height`,
  `6(a0)=width` to `EncodeString`/`WriteNametableToBuffer`.
- `RiderIntro_RecordTable` references **85 unique** intro quote headers; the
  results/end-level tables add 70 more, giving **155 unique** referenced records in
  `0x16E70-$19A11`.
- The 85 intro-only records are named `RiderIntro_Quote_<Rider>_<NN>` (NN ordered by
  ROM address within the rider); the 70 results/end-level records keep
  `RaceQuote_<addr>`.
- The region is now a normal source file in `src/screens/rider_intro_quotes.asm`:
  each record has a decimal `dc.w y,x,height,width` header and one `dc.b` line per
  text row (`width` characters), matching the on-screen row layout.
- 40 one-byte gaps are handled by `align 2,0` after each record (they are just
  2-byte alignment).
- `RiderIntro_Quote_Natasha_16` is the exception: the header says `width=22`, but the text was
  authored as three lines of 23 characters. The source is split at 23 and the three
  extra spaces are folded into the last line; the renderer uses 22, so the game
  displays different line breaks than this source. The trailing `$00` is kept as
  `QuoteGap_1731D`. This is an original authoring bug, preserved byte-exactly.
- The 11 unique image pointers are `$AF902-$BE628` (ROM tail after the current
  `$7EA65` build coverage), so the portraits are not part of the current image yet.

## Image asset format

The image pointer points **after** an 8-byte prefix at `image-8`. The prefix interleaves
two 32-bit values in its even and odd bytes (big-endian byte positions):

| Bytes | Value |
|---|---|
| even (`b0,b2,b4,b6`) | compressed size, e.g. `$07FE` |
| odd (`b1,b3,b5,b7`) | pointer to a 10-byte header, e.g. `$07FEDA` |

`RiderIntro_Init` rebuilds the header pointer from `-7,-5,-3,-1(a3)` (the odd bytes).
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
| Window `$7000` | portrait panel `RiderIntro_PortraitPanel`, 12x14 | `(2,5)`, base `$580` -> `$B000` (11 tiles + map) |
| Window | rider portrait, 10x12 | `(3,6)`, base `$600` -> `$C000` |
| Window | face overlay, 6x7 | `(6,9)`, base `$680` -> `$D000` |
| Window | name, 10x1 | `(3,19)`, base `$6000` (font palette 3) |
| Window | quote, 19x4 | `(16,3)`, stride 128 -> rows 3,5,7,9 |
| Window | message field 40x6 | rows 22-27 (message system) |
| VRAM `$0` | font `img_Intro_Font` | used by name/quote/messages |

The VDP setup is the same as the main menu: planes A/B `$4000`, window `$7000`
(64x28), sprite/HScroll `$6000`, 128x32, display on, H-int off, V-int on.

## `RiderIntro_Init` (`0x59C4`)

1. Clear pad state/changed buttons; message blink timer `$FFFF`, button period `$3F`,
   next message timer 300, message id `8*18`.
2. Write the VDP registers; clear SAT/HScroll (16 bytes at `$6000`), VSRAM, the
   default tile `$FFE0` (32 bytes), the visible 128x28 cells at `$4000` (`$700`
   longs), and the frame buffer (`$E00` bytes) to `$7FF`.
3. Load/draw the background, gamepad and portrait `RiderIntro_PortraitPanel` (see table).
4. Pick the opponent record (above), then:
   - read the name from the image header string pointer;
   - `UncompressW` the portrait; write to VRAM `$C000`; draw 10x12 at `(3,6)`;
   - copy the 4x8-long (64-colour) palette; copy the 10-char name into a temporary
     string header `(19,3,1,10)`, center it by rotating trailing spaces to the
     front, encode and draw it at `(3,19)`;
   - encode the quote and draw it at `(16, y/2)` with destination stride 128
     (double-spaced rows).
5. If the image is `RiderIntro_Portrait_0` (Natasha) and `ram_FF0520 > 0`, load
   `RiderIntro_NatashaFaceOverlay` (`UncompressB`) and draw a 6x7 face overlay at
   `(6,9)` from `ImageBuffer+$548`.
6. Load the font at VRAM `$0`; `Menu_ShowMessage`; DMA the 64x28 frame buffer to
   `$7000`.

## `RiderIntro_GameTick` (`0x5E66`)

Per frame: DMA the frame buffer to `$7000`; read pad A, then pad B; on a **release
edge** (`old & ~new`; `GetInput` returns 1 = pressed) set
`Race_ram_ActiveController` to 0/1 and end the screen; pad A is checked first.
Otherwise decrement `Menu_ram_NextMessageTimer`; after 301 ticks (~5 s) advance the
byte-offset `Menu_ram_CurrentMessageId` by 8 (8 bytes per array entry); when the text
pointer is `$FFFFFFFF`, end. Then `Menu_ShowMessage` and `Audio_Update`. End stage:
`Audio_StopMusic`, clear `ram_UpdateFunction`, `Audio_Update`.

Message sequence: index 18 = blank `Message_StrBlank`, index 19 = `StrPressStartToExit` with
the blinking Start icon, index 20 = terminator. The screen therefore auto-exits after
~10 s if no button is pressed; any button on either pad exits earlier.

## Quirks

- **Background reuse:** `Menu_Init` writes the main-menu background tiles to VRAM
  `$8000`; `RiderIntro_Init` writes the same image to `$4000` (which the following
  `WriteNametable` overwrites) while the tile map still references base tile `$400`
  (`$8000`). The visible background relies on the tiles left by the main menu; entering
  this screen directly (debug) would show a wrong background. `[static]`
- The variant-3 record and the `RiderIntro_NatashaFaceOverlay` are used only when the
  selected player's encounter counter is non-zero and the opponent image is
  `RiderIntro_Portrait_0`. The asset preview shows a close-up face/expression layer,
  not a bike (`U-0008` resolved). `[static]`
- The 10-character name is centered by counting trailing minus leading spaces,
  halving the surplus and right-rotating the field that many times. `[static]`
- The quote's destination Y is the header Y shifted right by one; with the 128-cell
  stride this gives double-spaced rows 3,5,7,9. `[static]`
- The portrait palette overwrites all 64 global palette words; the background/gamepad/
  font therefore use the rider palette on this screen. `[static]`

## Dynamic status

The demo path skips this screen (`src/core/top_level.asm` `0x7E782`), and the GDB forced-path
experiment (patched `0x7E788` branch) did not reach `RiderIntro_Init` within the test
budget. To confirm visually: press Start on the main menu in the native console (non-demo
path), then inspect VRAM `$7000`/the portrait palette. Rendering/positions above are
`[static]`; table contents are parsed deterministically from `baserom.md`.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `ram_FF0520` | `Player_ram_NatashaCounter` | current-race encounter flag (`U-0004`) | medium |

The quote and asset labels were renamed during the line-by-line pass (see above); the
remaining RAM rename is a separate task.


# Analysis: `src/screens/highscore.asm` (high-score table screen)

- **Module:** high-score table, plus the attract/demo variant
- **ROM range:** `0x006DC0`–`0x0074A9` (`src/screens/shop.asm` starts at `0x74AA`)
- **Status:** analyzed line-by-line (static; the demo path can run it; no capture taken)
- **Source:** `src/screens/highscore.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `HighScore_Init` | `0x6DC0` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `HighScore_GameTick_Demo` | `0x72BA` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `HighScore_GameTick` | `0x732E` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `HighScore_HandleInput` | `0x7460` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |

## Role & flow

The top level enters this module in two ways:

- **Demo/attract** (`src/core/top_level.asm` `0x7E7CC`): `HighScore_Init` +
  `HighScore_GameTick_Demo`; after the intro timer expires the demo high score is
  shown, then the demo race.
- **Normal** (`src/core/top_level.asm` `0x7E924`, selected from the results screen A, the shop,
  or A on this screen): `HighScore_Init` + `HighScore_GameTick`.

The screen shows the title, five yellow badge slots with the top five entries, the
player A/B rows, the gamepad, and the high-score tooltips.

## Screen layout

| Layer | Content | Position / base |
|---|---|---|
| Planes A/B `$4000` | main-menu background, 40x28 | `(0,0)`, base `$400`, `$8000` |
| Planes A/B | "High Score" title, 20x2 | `(11,1)`, base `$480` -> `$9000` |
| Planes A/B | yellow badge, 22x3 | `(9,5)`, `(9,8)`, `(9,11)`, `(9,14)`, `(9,17)`, base `$580` -> `$B000` |
| Planes A/B | gamepad, 12x6 | `(2,22)`, base `$500` -> `$A000` |
| Window `$7000` | top-5 rows, 20x1 | `(10,6)`, `(10,9)`, `(10,12)`, `(10,15)`, `(10,18)`, table font `$40` -> `$800` |
| Window | player A/B rows, 20x1 | `(10,23)`, `(10,25)`, regular font `$0` |
| Window | message field 40x6 | rows 22-27 |

The VDP setup matches the other menu screens: planes A/B `$4000`, window `$7000`
(64x28, WindowY 28), sprite/HScroll `$6000`, 128x32, display on, H-int off. The SAT is
cleared with only two zero entries (entry 0, `link=0`, terminates the sprite list).
VRAM `$FFE0` (tile `$7FF`) is cleared to a blank pattern and used for the 22-row
frame-buffer fill. Four 16-colour palettes (64 colours) are copied from
`ImageBuffer+$4E4`; because the title blob was decompressed last, this is
`ImgHighScoreTitle`'s palette (asset spec `screen_palettes.highscore`), not the
background palette.

## High-score table (`HighScore_ram_Table`, `$FF05EA`)

- Header `y=22, x=16, height=7, width=20`, followed by 7 x 20-character entries
  (`$FF05F2` is the first entry). `EncodeString` consumes only `+4` (height) and `+6`
  (width); the screen draws rows at fixed coordinates, so header `y/x` (`+0/+2`, written
  by `Intro_Init`) are not read by this module.
- The initial table is built by `src/screens/intro.asm` from `DemoHighScoreTable` (src/screens/message.asm): Fang,
  Helldog, Lubster, Natasha, Sergio, Player A, Player B with their money.
- `HighScore_ram_PlayerATableOffset/B` (20*5 / 20*6 initially) point at the player rows;
  `Race_UpdateHighScoreTable` (in `src/race/race_core.asm`) and `Intro_InitPlayerA` in
  `src/screens/intro.asm` update/sort them.
- The screen encodes the table with `EncodeString`; the five top rows use the table font
  at `$800` and draw entries 0..4; the player rows use the regular font at `$0` and draw
  the entries at the player offsets. After sorting, a qualified player can appear both
  in the top five and in the bottom player row (the offsets are not pinned to 5/6).

## `HighScore_Init` (`0x6DC0`)

1. Timers: next message 600 (10 s), pad state cleared, message blink `$FFFF`, button
   period `$3F`, message id `8*42`, `RaceResults_ram_NextFunction = 0`.
2. VDP (reg0 `$04` = mode 5/H-int off/HV latch off; reg1 `$74` = display/V-int/DMA on,
   28 rows); clear two SAT entries (entry 0 `link=0` terminates the list), VSRAM and one
   tile at `$FFE0` (tile `$7FF`); background to `$8000`; title `ImgHighScoreTitle` to
   `$9000`; 4 palettes (64 colours) from `ImageBuffer+$4E4` (the title palette); gamepad
   to `$A000`.
3. Badge `ImgHighScoreBadge` to `$B000`, drawn five times at y = 5/8/11/14/17.
4. Fonts: `img_Intro_Font` -> `$0`, `FontHighScoreTable` -> `$800` (table font),
   `FontHighScoreDigits` -> `$1000` (10 digit glyphs; loaded but never drawn,
   `U-0009` resolved as vestigial).
5. Clear 22 frame-buffer rows (1408 words) to `$7FF`, six rows (384 words) to spaces;
   encode the table (`EncodeString` uses only height/width); draw the 5 top rows and the
   two player rows; DMA 1792 words to `$7000`.
6. `Audio_StopMusic`; if music enabled, `Audio_StartMusic(1)`.

## `HighScore_GameTick` (`0x732E`)

- DMA the frame buffer.
- **Release edge** on pad A or B (`~input & previous`; `GetInput` returns 1 = pressed)
  -> `RaceResults_ram_NextFunction = RaceResults_Init` (back to the results) and end the stage.
- New-press edges: A -> `HighScore_Init` (restart the page), B -> `RaceResults_Init`,
  C -> `Shop_Init`.
- Message cycle: every 300 frames, advance by 8 within group 42 (wrap at the
  `$FFFFFFFF` terminator); `Menu_ram_MessageBlinkTimer` is reset to 30 for
  `Menu_ShowMessage`. The lower-bound `cmpi.w #(8*42)` clamp after `addq` is unreachable
  (the id starts at the group base and only grows).
- End when `RaceResults_ram_NextFunction != 0`; `Audio_Update` per frame, `Audio_StopMusic` at the end.

## `HighScore_GameTick_Demo` (`0x72BA`)

- Waits for a **release edge** on pad A or B, or a 600-frame timer (`subq`/`bpl` runs
  601 times, ~10 s). `Menu_ram_NextMessageTimer` is reused as the countdown.
- On release: clear `MainMenu_ram_DemoMode`; then end the stage. The top level checks
  the flag (`0x7E7FA`): 0 -> main menu, 1 -> demo race.
- No message cycling; `Audio_Update` per frame, `Audio_StopMusic` at the end.

## `HighScore_HandleInput` (`0x7460`)

`d0` = current buttons (1 = pressed): A -> `HighScore_Init`; B -> `RaceResults_Init`;
C -> `Shop_Init`. The pointer is consumed by the top level.

## Quirks / notes

- The table font at `$800` is used for the top five rows; the player rows use the
  regular font at `$0`. `FontHighScoreDigits` (10 digit glyphs, `0`-`9`) is loaded at
  `$1000` but never drawn: all tile bases are `$400/$480/$500/$580` or `$40/$0`
  (`U-0009` resolved, wontfix). `[static]`
- The demo tick and the normal tick both use release edges; the normal A/B/C actions use
  new-press edges. `[static]`
- The player A/B rows can duplicate an entry that has moved into the top five after
  sorting (`Race_UpdateHighScoreTable` keeps the offset). `[static]`
- The palette copy uses `ImageBuffer+$4E4` *after* the title decompression overwrote the
  background, so it is `ImgHighScoreTitle`'s palette (asset spec
  `screen_palettes.highscore = highscore_title +0x4E4`, 64 colours), not the background
  palette. `[static]`
- The SAT clear writes only 16 bytes (two entries); the rest of `$6000` is not touched
  here (sprites are unused on this screen). `[static]`
- `HighScore_HandleInput` stores only the low byte of the word `HighScore_ram_CurrentButtons`;
  the high byte is left as-is. `[static]`

## Dynamic status

The demo path reaches this screen (after the intro); no capture was taken in this
session. To confirm: run the demo until the high-score screen, or open it from the
results screen (A) in the native console.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `HighScore_Init` | `HighScore_Init` | already meaningful | high |
| `HighScore_GameTick` | `HighScore_GameTick` | already meaningful | high |
| `HighScore_GameTick_Demo` | `HighScore_GameTick_Demo` | already meaningful | high |


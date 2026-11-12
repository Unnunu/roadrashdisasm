# Module card: `src/screens/highscore.asm`

- **ROM range:** `0x006DC0`–`0x0074A9` (`src/screens/shop.asm` starts at `0x74AA`)
- **Status:** analyzed line-by-line (static; demo path can reach it)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/highscore.md`

## Role / purpose

High-score table screen and its attract/demo variant. It draws the title, five yellow
badge slots with the top five entries, the player A/B rows, the gamepad and the
high-score tooltips. In the demo it ends on a button release or after 10 s; in normal
play A/B/C select high score/results/shop and a release returns to the results.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `HighScore_Init` | `0x6DC0` | `src/core/top_level.asm` `0x7E7CC`/`0x7E9?` | Build the screen. |
| `HighScore_GameTick_Demo` | `0x72BA` | demo fade wrapper | Attract update. |
| `HighScore_GameTick` | `0x732E` | normal fade wrapper | Normal update/input. |
| `HighScore_HandleInput` | `0x7460` | `GameTick` | A/B/C actions. |

## Control flow / state machine

- `Init`: timers, VDP, background/title/palette/gamepad/badge, fonts, encode and draw
  the 7x20 table (top five + player rows), DMA, audio.
- `GameTick_Demo`: release edge on A/B or 600-frame timeout; on release clear
  `MainMenu_ram_DemoMode`; end.
- `GameTick`: DMA; release edge -> `RaceResults_Init`; A -> `HighScore_Init`,
  B -> `RaceResults_Init`, C -> `Shop_Init`; cycle message group 42 every 300 frames;
  end when `RaceResults_ram_NextFunction != 0`.

## RAM / ROM & structures

- `HighScore_ram_Table` (`$FF05EA`): header `(22,16,7,20)` + 7 x 20-char entries; text
  starts at `$FF05F2`; built by `src/screens/intro.asm` from `DemoHighScoreTable`, updated/sorted by
  `Race_UpdateHighScoreTable` (src/race/race.asm) and `Intro_InitPlayerA` (src/screens/intro.asm).
- `HighScore_ram_PlayerATableOffset/B` (`$FF052A/$FF052C`): player row offsets (20*5,
  20*6 initially; can move after sorting).
- `HighScore_ram_CurrentButtons` (`$FF094E`); `MainMenu_ram_DemoMode` (`$FF3692`);
  `RaceResults_ram_NextFunction` next-screen pointer; `Menu_ram_CurrentMessageId/NextMessageTimer`.
- Assets: `ImgHighScoreTitle` title -> `$9000`, `ImgHighScoreBadge` badge -> `$B000`,
  `FontHighScoreTable` table font -> `$800`, `FontHighScoreDigits` -> `$1000`
  (10 digit glyphs, no tile base references them here: `U-0009`),
  `img_Intro_Font` -> `$0`, background -> `$8000`, gamepad -> `$A000`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `HighScore_Init` | `0x6DC0` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `HighScore_GameTick_Demo` | `0x72BA` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `HighScore_GameTick` | `0x732E` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `HighScore_HandleInput` | `0x7460` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |

Detailed listing/table: `docs/analysis/highscore.md`.

## External calls / dependencies

- Callers: `src/core/top_level.asm`; `src/screens/race_results.asm`/`src/screens/shop.asm` set `RaceResults_ram_NextFunction` to
  `HighScore_Init`.
- Uses `UncompressW/B`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `GetInputPlayerA/B`, `Audio_Update/3/4`.

## Hacks / bugs / quirks

- Top five rows use the table font at `$800`; player rows use the regular font `$0`;
  the `$1000` digit font (`FontHighScoreDigits`) is loaded but no tile base uses it
  here (`U-0009`). `[static]`
- Player rows can duplicate a top-five entry after sorting (`Race_UpdateHighScoreTable` keeps the offset).
- The demo and normal ticks both end on a release edge; A/B/C are new-press edges.
- The palette is copied from `ImageBuffer+$4E4` *after* the title decompression, i.e.
  from `ImgHighScoreTitle` (asset spec `screen_palettes.highscore`), not from the
  background. `[static]`
- The SAT clear writes only two zero entries (16 bytes); entry 0 (`link=0`) terminates
  the list. `[static]`
- The message-id lower-bound clamp (`cmpi.w #(8*42)`) is unreachable after `addq`. `[static]`
- The demo timer uses `Menu_ram_NextMessageTimer` and runs 601 decrements. `[static]`

## Verified facts

- `[static]` Demo: release or a 600-frame timer (601 ticks); on release `DemoMode=0`
  -> menu, else race.
- `[static]` Normal: release -> results; A -> high score, B -> results, C -> shop.
- `[static]` Table header `(22,16,7,20)`; 7 x 20 entries; player offsets 20*5/20*6.
- `[static]` Message group 42; 300-frame cycle; 600-frame initial timer.
- `[static]` Palette source is the title blob (`+$4E4`), 4 palettes / 64 colours.
- `[static]` SAT clear = two entries; tile `$7FF` blank pattern at VRAM `$FFE0`.
- `[static]` `FontHighScoreDigits` is a 10-glyph digit font (`0`-`9`), loaded at `$1000`
  and not referenced by any tile base on this screen (`U-0009`).

## Hypotheses

- `[hypothesis]` `FontHighScoreDigits` is vestigial on this screen (`U-0009`). Test:
  BlastEm breakpoint at `$72A0` after the frame DMA, then search VRAM `$7000`/`$4000`
  for tile words `$0080`-`$0089`; also `b 37AA` and check `d4` (never `$80`).
- `[hypothesis]` The duplicate player row is intentional (table font vs regular font).

## Rename proposals (apply only on request)

- Applied in the line-by-line pass: `unk_A2E68` -> `FontHighScoreDigits` (the blob is a
  10-glyph digit font `0`-`9`; preview at `assets/tilesets/highscore_extra/`).

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Capture the screen | — (not run this session) | — | static analysis only |
| Identify `$1000` font | asset split preview (`assets/tilesets/highscore_extra/`) | 10 glyphs `0`-`9` | `FontHighScoreDigits`; display use still open (`U-0009`) |

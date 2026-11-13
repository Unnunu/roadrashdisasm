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

## External calls / dependencies
- Callers: `src/core/top_level.asm`; `src/screens/race_results.asm`/`src/screens/shop.asm` set `RaceResults_ram_NextFunction` to
  `HighScore_Init`.
- Uses `UncompressW/B`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `GetInputPlayerA/B`, `Audio_Update/3/4`.

## Hacks / bugs / quirks
- Top five rows use the table font at `$800`; player rows use the regular font `$0`;
  the `$1000` digit font (`FontHighScoreDigits`) is loaded but never drawn; no draw
  uses tile base `$80` (`U-0009` resolved, wontfix). `[static]`
- Player rows can duplicate a top-five entry after sorting (`Race_UpdateHighScoreTable` keeps the offset).
- The demo and normal ticks both end on a release edge; A/B/C are new-press edges.
- The palette is copied from `ImageBuffer+$4E4` *after* the title decompression, i.e.
  from `ImgHighScoreTitle` (asset spec `screen_palettes.highscore`), not from the
  background. `[static]`
- The SAT clear writes only two zero entries (16 bytes); entry 0 (`link=0`) terminates
  the list. `[static]`
Full list: the related analysis page.

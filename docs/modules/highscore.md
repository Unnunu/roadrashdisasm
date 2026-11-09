# Module card: `highscore.asm`

- **ROM range:** `0x006DC0`–`0x0074A9` (`shop.asm` starts at `0x74AA`)
- **Status:** analyzed (static; demo path can reach it)
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
| `HighScore_Init` | `0x6DC0` | `top_level.asm` `0x7E7CC`/`0x7E9?` | Build the screen. |
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
  end when `ram_FF0910 != 0`.

## RAM / ROM & structures

- `HighScore_ram_Table` (`$FF05EA`): header `(22,16,7,20)` + 7 x 20-char entries; text
  starts at `$FF05F2`; built by `intro.asm` from `unk_4C18`, updated/sorted by
  `sub_C598` (race.asm) and `sub_1A2C` (intro.asm).
- `HighScore_ram_PlayerATableOffset/B` (`$FF052A/$FF052C`): player row offsets (20*5,
  20*6 initially; can move after sorting).
- `HighScore_ram_CurrentButtons` (`$FF094E`); `MainMenu_ram_DemoMode` (`$FF3692`);
  `ram_FF0910` next-screen pointer; `Menu_ram_CurrentMessageId/NextMessageTimer`.
- Assets: `unk_A2F5C` title -> `$9000`, `unk_7EB72` badge -> `$B000`,
  `unk_A2BAA` table font -> `$800`, `unk_A2E68` -> `$1000` (use TODO),
  `img_Intro_Font` -> `$0`, background -> `$8000`, gamepad -> `$A000`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `HighScore_Init` | `0x6DC0` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `HighScore_GameTick_Demo` | `0x72BA` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `HighScore_GameTick` | `0x732E` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `HighScore_HandleInput` | `0x7460` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |

Detailed listing/table: `docs/analysis/highscore.md`.

## External calls / dependencies

- Callers: `top_level.asm`; `race_results.asm`/`shop.asm` set `ram_FF0910` to
  `HighScore_Init`.
- Uses `UncompressW/B`, `WriteToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `GetInputPlayerA/B`, `AudioFunc1/3/4`.

## Hacks / bugs / quirks

- Top five rows use the table font at `$800`; player rows use the regular font `$0`;
  the `$1000` font is loaded but not visibly used. `[static]`
- Player rows can duplicate a top-five entry after sorting (`sub_C598` keeps the offset).
- The demo and normal ticks both end on a release edge; A/B/C are new-press edges.
- Background palette is copied from `ImageBuffer+$4E4` (the background palette).

## Verified facts

- `[static]` Demo: release or 600 frames; on release `DemoMode=0` -> menu, else race.
- `[static]` Normal: release -> results; A -> high score, B -> results, C -> shop.
- `[static]` Table header `(22,16,7,20)`; 7 x 20 entries; player offsets 20*5/20*6.
- `[static]` Message group 42; 300-frame cycle; 600-frame initial timer.

## Hypotheses

- `[hypothesis]` The `$1000` font is a leftover or used by the title; test: inspect VRAM
  during the screen.
- `[hypothesis]` The duplicate player row is intentional (table font vs regular font).

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `unk_A2F5C` | `ImgHighScoreTitle` | title image | medium |
| `unk_7EB72` | `ImgHighScoreBadge` | yellow badge | medium |
| `unk_A2BAA` | `FontHighScoreTable` | table font at `$800` | medium |
| `unk_A2E68` | `FontHighScoreExtra` | loaded at `$1000`, use TODO | low |

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Capture the screen | — (not run this session) | — | static analysis only |

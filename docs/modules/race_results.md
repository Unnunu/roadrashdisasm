# Module card: `src/screens/race_results.asm`

- **ROM range:** `0x005F28`–`0x006DBF` (`src/screens/highscore.asm` starts at `0x6DC0`)
- **Status:** analyzed (static; demo skips the screen, rendering dynamic TODO)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/race_results.md`

## Role / purpose

Post-race results screen. It selects one of three layouts: normal race standings,
caught-by-cops fine, or bike repair. It shows the player's cash/password box, the
outcome message, and lets the player continue (Start), open the high-score table (A),
open the shop (C), or inspect the cash/password (B).

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `RaceResults_Init` | `0x5F28` | `src/core/top_level.asm` `0x7E924` | Build the result screen. |
| `RaceResults_GameTick` | `0x6A90` | fade wrapper | Per-frame update/input/messages. |
| `RaceResults_HandleInput` | `0x6BD4` | `GameTick` | A/B/C actions. |
| `RaceResults_DrawStandings` | `0x62CE` | `Init` | Normal standings layout. |
| `RaceResults_DrawBusted` | `0x647E` | `Init` | Caught-by-cops layout. |
| `RaceResults_DrawRepair` | `0x67AC` | `Init` | Bike-repair layout. |
| `DrawString` | `0x6C5E` | — | Unused helper (shop has its own). |

## Control flow / state machine

1. `Init`: set timers; copy `ram_FF0526/28` -> `RaceResults_ram_Outcome`; choose message group
   21/28/35; VDP setup; background/gamepad/font; choose layout:
   `RaceResults_DrawStandings` if `Race_EventBuffer != $FFFF`, else cops (`Race_CopIndex != 0`) or repair.
   DMA; fill the cash/password box; patch the congratulations level; audio.
2. `GameTick`: DMA; Start held exits; A -> high score, C -> shop, B -> show
   cash/password for 25 s; advance the message every 300 frames and loop at the group
   terminator; end when a next-screen pointer is set.

## RAM / ROM & structures

- `ram_FF0526/28` per-player outcome -> `RaceResults_ram_Outcome`: 0 = course not completed, >4 =
  4th place not reached, 4 = level complete (EndLevel).
- `Race_EventBuffer` 16-long event/sort buffer; first word `$FFFF` = busted/destroyed.
- `Race_CopIndex` cop index (1..5) or 0 = bike destroyed; `RaceResults_ram_Amount` fine/repair.
- `ram_FF1414/18/1A` standings string header/text, height, width.
- `RaceResults_ram_NextFunction` next-screen pointer (HighScore/Shop/RaceResults); `RaceResults_ram_DrawRoutine` set but
  unread; `Menu_ram_PlayerLevel` for fine/repair/congratulations.
- Result portrait tables: `$19D32` (level, money>=0, 5x4), `$19DD2` (level, money<0,
  5x2), `$19E22` (cop, money>=0, 5x4), `$19EC2` (cop, money<0, 5x2); 8-byte records
  `quote_ptr, image_ptr` (same asset format as `src/screens/rider_intro.asm`).
- Track images: `$7E670` pointers, `$7E684` image offsets, `$7E68E` nametable offsets,
  `$7E698` palette offsets.
- Messages: groups 21 (`unk_5276`), 28 (`unk_52CE`), 35 (`ram_FF089A`/`unk_533A`) plus
  Start/A/B/C prompts; bust/repair strings `unk_56AC`/`unk_56D8`/`unk_5704`/`unk_5730`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RaceResults_Init` | `0x5F28` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawStandings` | `0x62CE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawBusted` | `0x647E` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawRepair` | `0x67AC` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_GameTick` | `0x6A90` | [x] | [x] | [x] | [x] | [ ] | [ ] | analyzed |
| `RaceResults_HandleInput` | `0x6BD4` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `DrawString` | `0x6C5E` | [x] | [x] | - | - | - | - | unused |

Detailed listing and table parse: `docs/analysis/race_results.md`.

## External calls / dependencies

- Callers: `src/core/top_level.asm` (and `src/screens/shop.asm`/`src/screens/highscore.asm` set `RaceResults_ram_NextFunction` back to
  `RaceResults_Init`).
- Uses `UncompressW/B`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `GetInputPlayerA/B`, `Rand_NextWord`, `Race_FormatMoney`,
  `Race_FormatNumber`, `Audio_Update/3/4`.
- Race outcome fields are computed by `Race_ComputeResults` in `src/race/race.asm`.

## Hacks / bugs / quirks

- `RaceResults_ram_DrawRoutine` is set to the active draw routine but never read. `[static]`
- `DrawString` (`0x6C5E`) is unused; the source notes it may not belong to this file.
- The tail data `unk_6C94`/`6D00`/`6D14`/`6D50`/`6D88` is unreferenced (dead/legacy).
- Start exits while **held**; A/C are new-press edges; B shows the cash box.

## Verified facts

- `[static]` Outcome mapping 0/>4/4 -> message groups 21/28/35; 4 -> EndLevel.
- `[static]` `RaceResults_ram_Amount` fine = `PlayerLevel*$14`; repair = 10% of the bike price;
  deducted from money by `Race_ComputeResults`.
- `[static]` The result portrait tables and names were parsed from `baserom.md`.
- `[static]` Buttons: Start exit, A high score, C shop, B cash/password.

## Hypotheses

- `[hypothesis]` The result screen's `RaceResults_DrawBusted`/`RaceResults_DrawRepair` portrait is the cop/mechanic
  tied to the bust index/level. Test: finish a non-demo race busted/broken and inspect.
- `[hypothesis]` The `$19D32`/`$19E22` names are the repair/cop characters; the images
  are shared with the pre-race intro. Test: render the records.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Capture results screen | — (demo skips it; non-demo needs input) | Not captured | static analysis only |

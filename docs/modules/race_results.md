# Module card: `src/screens/race_results.asm`

- **ROM range:** `0x005F28`–`0x006DBF` (`src/screens/highscore.asm` starts at `0x6DC0`)
- **Status:** analyzed; line-by-line pass done; results pipeline exercised by E7-C (forced non-demo finish); screen rendering still dynamic TODO
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

## External calls / dependencies
- Callers: `src/core/top_level.asm` (and `src/screens/shop.asm`/`src/screens/highscore.asm` set `RaceResults_ram_NextFunction` back to
  `RaceResults_Init`).
- Uses `UncompressW/B`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `GetInputPlayerA/B`, `Rand_NextWord`, `Race_FormatMoney`,
  `Race_FormatNumber`, `Audio_Update/3/4`.
- Race outcome fields are computed by `Race_ComputeResults` in `src/race/race_core.asm`.

## Hacks / bugs / quirks
- `RaceResults_ram_DrawRoutine` is set to the active draw routine but never read. `[static]`
- The negative-money portrait tables use `and.w ($8).w` (bus-error vector high word =
  `$0000`), so their reported random variant is always the first record; the RNG advances.
- `StrNotReadyEncoded` is ASCII with bit 7 set; `EncodeString` would render it as spaces.
- `DrawString` (`0x6C5E`) is unused; the source notes it may not belong to this file.
- The tail data `RaceResults_StrNextLevelShort`/`6D00`/`6D14`/`6D50`/`6D88` is unreferenced (dead/legacy).
Full list: the related analysis page.

# Module card: `src/screens/shop.asm`

- **ROM range:** `0x0074AA`–`0x008341` (`src/screens/endlevel.asm` starts at `0x8342`)
- **Status:** line-by-line (static; shop is non-demo; dynamic = user-described)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/shop.md`

## Role / purpose
Bike shop: browse eight bikes, read stats/descriptions, buy/trade in. It shows credits
(including the trade-in value), the selected price, the bike name/power/weight, a 10 s
description, the selection prompts and a horizontally scrolling bike band. Entered
from the results/high-score screens; Start returns to the results.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Shop_Init` | `0x74AA` | `src/core/top_level.asm` `0x7E9B2` | Build the shop. |
| `Shop_GameTick` | `0x79F8` | fade wrapper | Per-frame update/input. |
| `Shop_HandleInput` | `0x7B4C` | `GameTick` | A/B/C/D-pad actions. |
| `Shop_DrawCreditsAndPrice` | `0x7D5E` | `Init`/`HandleInput` | Credits + price. |
| `Shop_PrepareMessages` | `0x7F62` | `Init`/`HandleInput` | Bike-name prompts. |
| `Shop_DrawBikes` | `0x803C` | `Init`/`HandleInput` | Bike lineup + palettes. |
| `Shop_UpdateScroll` | `0x8178` | `GameTick` | H-scroll animation. |
| `Shop_ShowAlreadyOwned`/`Shop_ShowCannotAfford` | `0x7EA2`/`0x7F02` | `HandleInput` | Already-owned / can't-afford messages. |

## External calls / dependencies
- Callers: `src/core/top_level.asm`; results/high-score C; the shop sets `RaceResults_ram_NextFunction` to
  HighScore/RaceResults/Shop.
- Uses `UncompressW/B`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `DmaWriteCRAM`, `GetInputPlayerA/B`, `Race_FormatNumber`,
  `MenuPassword_CreatePassword`, `Audio_Update/3/4`.

## Hacks / bugs / quirks
- Cell-mode H-scroll table `$6400` with auto-increment `$20`; other screens use
  `$6000`/full scroll. `[static]`
- Palette copy skips source w4 and takes destination w4 from the next palette's w0;
  all records have w0 = `$0222`, so entry 4 is a fixed transparent colour
  (`U-0010` resolved); three base bike images are reused for eight bikes. `[static]`
- "(its yours)" is assembled from three immediate longs written backwards. `[static]`
- Left/Right redraw the new bike before the scroll animation finishes, so the first
  frames show a transient wrong model/palette (user-observed). `[static]`/`[dynamic]`

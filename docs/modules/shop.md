# Module card: `src/screens/shop.asm`

- **ROM range:** `0x0074AA`–`0x008341` (`src/screens/endlevel.asm` starts at `0x8342`)
- **Status:** analyzed (static; shop is non-demo, rendering dynamic TODO)
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

## Control flow / state machine

- `Init`: read the player's bike id; VDP/scroll tables; background/selection/gamepad/
  arrows; bike images/palettes; fonts; CREDITS/PRICE; name; description; prompts;
  credits/price; DMA; audio.
- `GameTick`: DMA; scroll animation; Start held -> results; A/B/C/D-pad edges.
- `HandleInput`: A high score, B results, C buy/trade-in, Right/Left select (only at
  `ScrollPos == $160`), then redraw name/description/prompts/credits.
- Bytes: `RaceResults_ram_NextFunction` selects the next screen; `ram_UpdateFunction=0` ends the stage.

## RAM / ROM & structures

- `Shop_CurrentBikeId` `$FF0950` (0..7); `Shop_ScrollPos` `$FF0954` (centre `$160`);
  `Shop_ImageBike1/2/3` `$FF0956/$FF0A9A/$FF0BDE` (18x9 RAM maps); `Shop_ram_CurrentButtons`
  current buttons (unnamed); `Shop_StrBuyNewBike` `$FF06EA`; dynamic messages
  `ram_FF089A`/`ram_FF07C2`/`ram_FF082E`.
- ROM: `Shop_BikeDescriptions` `$81D2` (8 pointers), `Shop_dPrices` `$8312`
  (400/500/700/800/1200/1400/2000/2500), `Shop_BikeImageTable` `$8322`
  `[3,3,3,1,1,2,1,2]`, `Shop_BikePalettes` `$7E370` (8 x 32 bytes).
- Player state: `Menu_ram_Player`, `Menu_ram_MoneyPlayerA/B`,
  `Menu_ram_BikeIdPlayerA/B`.
- VDP: cell H-scroll (`$8B02`), H-scroll table `$6400`, auto-increment `$20`;
  planes `$4000`, window `$7000` (64x28).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Shop_Init` | `0x74AA` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Shop_GameTick` | `0x79F8` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Shop_HandleInput` | `0x7B4C` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `Shop_DrawCreditsAndPrice` | `0x7D5E` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `Shop_PrepareMessages` | `0x7F62` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `Shop_DrawBikes` | `0x803C` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Shop_UpdateScroll` | `0x8178` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |

Detailed listing/table/purchase logic: `docs/analysis/shop.md`.

## External calls / dependencies

- Callers: `src/core/top_level.asm`; results/high-score C; the shop sets `RaceResults_ram_NextFunction` to
  HighScore/RaceResults/Shop.
- Uses `UncompressW/B`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `DmaWriteCRAM`, `GetInputPlayerA/B`, `Race_FormatNumber`,
  `MenuPassword_CreatePassword`, `Audio_Update/3/4`.

## Buying / trade-in

Credits = money + current bike price/2; price = selected bike price. Owned -> "You
already own a ..."; insufficient -> "You need more credit ..."; otherwise money -=
(price - current/2), set the bike id, redraw, regenerate the password. The credits box
uses palette 2 when insufficient, otherwise palette 3.

## Hacks / bugs / quirks

- Cell-mode H-scroll table `$6400` with auto-increment `$20`; other screens use
  `$6000`/full scroll. `[static]`
- Palette copy skips source entry 4 and maps entry 13 to destination entry 4; three
  base bike images are reused for eight bikes. `[static]`
- "(its yours)" is assembled from three immediate longs written backwards. `[static]`
- `Shop_ram_CurrentButtons` is unnamed in `src/core/ram_const.asm`.

## Verified facts

- `[static]` Purchase/trade-in math and password regeneration.
- `[static]` Eight bikes, stats/prices and the image/palette tables parsed.
- `[static]` Start -> results; A -> high score; B -> results; C -> buy; Left/Right select.
- `[static]` Description message (51+bike*8) for 10 s, then group 60 prompts.

## Hypotheses

- `[hypothesis]` The window has transparent cells exposing the scrolling plane bike band.
  Test: capture the shop VRAM/window in BlastEm.
- `[hypothesis]` The eight palette variants are the bike colours. Test: render them.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Capture the shop | — (non-demo, needs input) | — | static analysis only |

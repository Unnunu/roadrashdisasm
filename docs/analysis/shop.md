# Analysis: `src/screens/shop.asm` (bike shop)

- **Module:** bike shop: select a bike, buy/trade in, read stats/description
- **ROM range:** `0x0074AA`–`0x008341` (`src/screens/endlevel.asm` starts at `0x8342`)
- **Status:** analyzed statically (shop is non-demo; no capture taken)
- **Source:** `src/screens/shop.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

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
| `Shop_ShowAlreadyOwned`/`Shop_ShowCannotAfford` | `0x7EA2`/`0x7F02` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |

## Role & flow

The bike shop is entered from the results screen (C), the high-score screen (C), and
returns with Start (results), A (high score) or B (results). The player scrolls left/
right through 8 bikes; C buys/trades in the selected bike; the credits, selected price,
bike name/stats, a 10 s description, and the selection prompts are shown.

- `Shop_Init`: read the player's bike id; VDP; background/selection/gamepad/arrows;
  bike images and 8-entry palette table; fonts; "CREDITS"/"PRICE"; bike name;
  description; prompts; credits/price; DMA; audio.
- `Shop_GameTick`: DMA; animate the H-scroll; Start -> results; A/B/C/D-pad edges.
- `Shop_HandleInput`: A -> high score, B -> results, C -> buy, Right/Left -> select.

## VDP / scrolling

Same basic menu setup, except horizontal scroll uses **cell mode**
(`$8B02`: V-scroll full, H-scroll cell), H-scroll table `$6400`
(`$8D19`), auto-increment `$20`. The scroll table is written in three bands:
7 strips `0`, 9 strips `-Shop_ScrollPos`, 12 strips `0`; the centre 9-strip band
(rows 7-15, where the bikes are drawn) moves. `Shop_UpdateScroll` clamps the speed to
`-8..+8` and rewrites the 9 entries at `$64E2`; the position returns to `$160`.

| Layer | Content |
|---|---|
| Planes A/B `$4000` | gamepad `(2,22)`, arrows `(0,4)`/`(36,4)`, five bikes at `(3,29,55,81,107; y=7)`, 18x9 |
| Window `$7000` | background 40x28, selection background 40x14 at (0,4), bike name/stats, CREDITS/PRICE, messages |
| VRAM | background `$8000`, selection `$9000`, gamepad `$A000`, arrows `$B000/$B100`, bike tiles `$C000/$D000/$E000`, font `$0` |

The window is drawn from `Menu_ram_FrameBuffer`; the bike images/arrows are on the plane,
with the window's transparent cells exposing the scrolling bike band.

## Bikes (`Shop_BikeDescriptions`, `Shop_dPrices`)

| Id | Name | HP / lbs | Price |
|---|---|---|---|
| 0 | Shuriken 400 | 60 / 400 | 400 |
| 1 | Panda 600 | 90 / 450 | 500 |
| 2 | Banzai 750 | 100 / 465 | 700 |
| 3 | Kamikaze 750 | 105 / 475 | 800 |
| 4 | Shuriken 1000 | 135 / 510 | 1200 |
| 5 | Ferruci 850 | 110 / 470 | 1400 |
| 6 | Panda 750 | 120 / 450 | 2000 |
| 7 | Diablo 1000 | 150 / 450 | 2500 |

- Three base bike images (`Shop_ImageBike1/2/3`, 18x9 maps in RAM) are selected by
  `Shop_BikeImageTable` `[3,3,3,1,1,2,1,2]`; the 8 variants come from the palette table
  `Shop_BikePalettes` (`0x7E370`, 8 x 32 bytes).
- `Shop_DrawBikes`: palette line 2 = selected bike palette, line 3 = previous bike
  palette; the source palette copy skips source entry 4 and maps entry 13 to
  destination entry 4; draws the previous/current/next bikes at x=3/29/55/81/107,
  current with palette 2 (`$C000`), others palette 3 (`$E000`).

## Buying / trade-in

- Credits = money + half the current bike's price (`Shop_dPrices`).
- Selected price = `Shop_dPrices[Shop_CurrentBikeId]`.
- If the selected bike is the player's current bike: `Shop_ShowAlreadyOwned` -> "You already own a
  ..." message (id 59) for 5 s.
- If credits < selected price: `Shop_ShowCannotAfford` -> "You need more credit to buy a ..." (id 59).
- Otherwise: `money -= selectedPrice - currentPrice/2`, `BikeId = selected`, redraw the
  credits/price, regenerate the password (`MenuPassword_CreatePassword`).
- The credits/price text uses palette 2 when the credits are insufficient, otherwise
  palette 3; the price field shows "(its yours)" for the owned bike.

## Messages

- `Shop_ShowBikeDescription`: message id `8*51 + bikeId*8` (entries 51..58) for 600
  frames (10 s); after that the cycle starts at group 60.
- Group 60: trade-in credit (`unk_53A6`), left/right bike names (`ram_FF07C2`,
  `ram_FF082E`), "Press C to buy a new ..." (`Shop_StrBuyNewBike`), Start/A/B prompts,
  terminator; cycle 300 frames, reset to 0x1E0.
- `Shop_PrepareMessages` fills `unk_50AA` + current bike name, `unk_5116` + previous
  name, `unk_516E` + next name.
- `Shop_ShowAlreadyOwned`/`Shop_ShowCannotAfford` build the dynamic messages in `ram_FF089A` from `unk_51C6` /
  `unk_520A` + the current bike name (id 59, 5 s).

## Input

`GetInput` returns 1 = pressed; the shop uses new-press edges for A/B/C and the D-pad,
and Start **held** returns to the results (`ram_FF0910 = $5F28` = `RaceResults_Init`).
A -> `HighScore_Init`; B -> `RaceResults_Init`; C -> buy; Right -> next bike; Left ->
previous bike; the D-pad only acts when `Shop_ScrollPos == $160` (animation finished),
then shifts the scroll position by `-$D0`/`+$D0`.

## RAM / ROM

- `Shop_CurrentBikeId` `$FF0950` (0..7); `Shop_ram_CurrentButtons` current buttons (unnamed);
  `Shop_ScrollPos` `$FF0954` (centre `$160`); `Shop_ImageBike1/2/3`
  `$FF0956/$FF0A9A/$FF0BDE` (18x9 maps); `Shop_StrBuyNewBike` `$FF06EA`;
  `ram_FF089A`/`ram_FF07C2`/`ram_FF082E` dynamic messages.
- ROM: `Shop_BikeDescriptions` `$81D2` (8 pointers), `Shop_dPrices` `$8312` (8 words),
  `Shop_BikeImageTable` `$8322` (8 pointers), `Shop_BikePalettes` `$7E370`
  (8 x 32 bytes, referenced from `src/core/unknown.asm`).
- Player state: `Menu_ram_Player`, `Menu_ram_MoneyPlayerA/B`,
  `Menu_ram_BikeIdPlayerA/B`.

## Quirks / notes

- The H-scroll table is at `$6400` with cell mode and auto-increment `$20`; the other
  screens use `$6000`/full scroll. `[static]`
- The bike palettes skip source entry 4 and duplicate entry 13 into destination entry 4;
  the same three base image maps are reused for eight bikes. `[static]`
- The price string "(its yours)" is assembled from three immediate longs written
  backwards into the temporary string. `[static]`
- The shop's window/plane transparency and the visual scroll band are not yet captured
  dynamically. `[hypothesis]`
- `Shop_ram_CurrentButtons` is unnamed in `src/core/ram_const.asm`; a rename is proposed below.

## Dynamic status

The shop is not shown in the demo; reach it from the results screen (C) in the native
console. The static analysis covers the layout, tables and purchase logic; the visual
scroll/transparency is pending.


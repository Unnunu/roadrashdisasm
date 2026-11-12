# Analysis: `src/screens/shop.asm` (bike shop)

- **Module:** bike shop: select a bike, buy/trade in, read stats/description
- **ROM range:** `0x0074AA`–`0x008341` (`src/screens/endlevel.asm` starts at `0x8342`)
- **Status:** line-by-line complete (static; shop is non-demo; dynamic = user-described native-console observation)
- **Source:** `src/screens/shop.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Shop_Init` | `0x74AA` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `Shop_DrawBikeName` | `0x7996` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |
| `Shop_ShowBikeDescription` | `0x79DA` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |
| `Shop_GameTick` | `0x79F8` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `Shop_HandleInput` | `0x7B4C` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |
| `Shop_DrawCreditsAndPrice` | `0x7D5E` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |
| `Shop_DrawString` | `0x7E70` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |
| `Shop_ShowAlreadyOwned` | `0x7EA2` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |
| `Shop_ShowCannotAfford` | `0x7F02` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |
| `Shop_PrepareMessages` | `0x7F62` | [x] | [x] | [x] | - | [x] | [ ] | line-by-line |
| `Shop_DrawBikes` | `0x803C` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `Shop_UpdateScroll` | `0x8178` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |

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

Native-console observation `[dynamic]` (user-provided): one bike sits in the centre with
the edge of one bike visible on each side; all bikes slide one position per Left/Right.
The visible stack is the Road Rash title (window background), left/right arrows (plane,
high priority), the grey selection backdrop (window), the bike band over it (plane
through the transparent window cells), then credits/descriptions, the gamepad and the
info messages in the lower-right.

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
  palette. The copy skips source w4 and fills destination w4 from the **next** palette's
  w0 (`$16(a0)` with `a0 = base+10`); destination w5-w12 come from source w5-w12 and
  w13-w15 are left untouched. All eight records (and the neighbouring actor palette 0)
  have w0 = `$0222`, so destination entry 4 is a fixed transparent/background colour
  (`U-0010` resolved). Draws five 18x9 images at x=3/29/55/81/107;
  current with palette 2 (`$C000`), the others palette 3 (`$E000`).

## Buying / trade-in

- Credits = money + half the current bike's price (`Shop_dPrices`).
- Selected price = `Shop_dPrices[Shop_CurrentBikeId]`.
- If the selected bike is the player's current bike: `Shop_ShowAlreadyOwned` -> "You already own a
  ..." message (id 59) for 5 s.
- If credits < selected price: `Shop_ShowCannotAfford` -> "You need more credit to buy a ..." (id 59).
- Otherwise: `money -= selectedPrice - currentPrice/2`, `BikeId = selected`, redraw the
  credits/price, regenerate the password (`MenuPassword_CreatePassword`).
- The credits/price text uses palette 3 when the credits are insufficient (normal
  grey-blue text, user-confirmed `[dynamic]`) and palette 2 when the credits cover the
  price; the price field shows "(its yours)" for the owned bike.

## Messages

- `Shop_ShowBikeDescription`: message id `8*51 + bikeId*8` (entries 51..58) for 600
  frames (10 s); after that the cycle starts at group 60.
- Group 60: trade-in credit (`Message_StrTradeInCredit`), left/right bike names
  (`ram_FF07C2`, `ram_FF082E`), "Press C to buy a new ..." (`Shop_StrBuyNewBike`),
  Start/A/B prompts, terminator; cycle 300 frames, reset to 0x1E0.
- `Shop_PrepareMessages` fills `Message_StrPressCBuyNewBike` + current bike name,
  `Message_StrPressLeftDirPad` + previous name, `Message_StrPressRightDirPad` + next
  name.
- `Shop_ShowAlreadyOwned`/`Shop_ShowCannotAfford` build the dynamic messages in
  `Message_ram_DynamicRecord` from `Message_StrAlreadyOwnBike` / `Message_StrNeedMoreCredit` + the
  current bike name (id 59, 5 s).

## Input

`GetInput` returns 1 = pressed; the shop uses new-press edges for A/B/C and the D-pad,
and Start **held** returns to the results (`RaceResults_ram_NextFunction = $5F28` = `RaceResults_Init`).
A -> `HighScore_Init`; B -> `RaceResults_Init`; C -> buy; Right -> next bike; Left ->
previous bike; the D-pad only acts when `Shop_ScrollPos == $160` (animation finished),
then shifts the scroll position by `-$D0`/`+$D0`.

## RAM / ROM

- `Shop_CurrentBikeId` `$FF0950` (0..7); `Shop_ram_CurrentButtons` `$FF0952` (low
  byte of the pad state); `Shop_ScrollPos` `$FF0954` (centre `$160`); `Shop_ImageBike1/2/3`
  `$FF0956/$FF0A9A/$FF0BDE` (18x9 maps); `Shop_StrBuyNewBike` `$FF06EA`;
  `Message_ram_DynamicRecord`/`ram_FF07C2`/`ram_FF082E` dynamic messages.
- ROM: `Shop_BikeDescriptions` `$81D2` (8 pointers), `Shop_dPrices` `$8312` (8 words),
  `Shop_BikeImageTable` `$8322` (8 pointers), `Shop_BikePalettes` `$7E370`
  (8 x 32 bytes, defined in `src/data/race_misc_data.asm`).
- Player state: `Menu_ram_Player`, `Menu_ram_MoneyPlayerA/B`,
  `Menu_ram_BikeIdPlayerA/B`.

## Quirks / notes

- The H-scroll table is at `$6400` with cell mode and auto-increment `$20`; the other
  screens use `$6000`/full scroll. `[static]`
- The palette copy skips source w4 and takes destination w4 from the next palette's w0
  (`$0222` in all eight records, so it is a fixed transparent/background colour); the
  same three base image maps are reused for eight bikes (`U-0010` resolved). `[static]`
- The price string "(its yours)" is assembled from three immediate longs written
  backwards into the temporary string. `[static]`
- The window/plane transparency and the scroll band are confirmed by the user's
  native-console description (`[dynamic]`), not by a BlastEm capture.
- Left/Right redraws the new bike and switches the palette immediately while the band is
  still animating, so the first frames show a transient wrong model/palette combination
  (user-observed; explained statically by `Shop_HandleInput`). `[static]`/`[dynamic]`

## Dynamic status

The shop is not shown in the demo; reach it from the results screen (C) in the native
console. The static analysis covers the layout, tables and purchase logic. The user
described the native-console view (`[dynamic]`, no BlastEm capture): one centre bike plus
the edge of one bike on each side, a sliding band, and the layered title/arrows/grey
backdrop/bikes/texts/gamepad. The palette warning uses the normal grey-blue colour when
the credits are insufficient. Remaining dynamic check: the "affordable" palette-2 colour
(`U-0010` is resolved statically: destination entry 4 is always `$0222`).


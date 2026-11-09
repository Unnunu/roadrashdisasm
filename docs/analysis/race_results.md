# Analysis: `src/screens/race_results.asm` (post-race results / bust / repair)

- **Module:** post-race result screens: normal standings, caught-by-cops, bike repair
- **ROM range:** `0x005F28`–`0x006DBF` (`src/screens/highscore.asm` starts at `0x6DC0`)
- **Status:** analyzed statically (demo skips the screen; rendering dynamic TODO)
- **Source:** `src/screens/race_results.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RaceResults_Init` | `0x5F28` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawStandings` (normal results) | `0x62CE` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawBusted` (cops) | `0x647E` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_DrawRepair` (repair) | `0x67AC` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_GameTick` | `0x6A90` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_HandleInput` | `0x6BD4` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `DrawString` | `0x6C5E` | [x] | [x] | - | - | - | - | unused helper |

## Role & flow

After a race the top-level flow (`src/core/top_level.asm` `0x7E8F4`) runs `Race_ComputeStandings` and
`Race_ComputeResults` (race outcome/fines), then loops through
`RaceResults_Init`/`RaceResults_GameTick`. The screen shows one of:

- **Normal results** (`Race_EventBuffer != $FFFF`): "race results" title, the track image,
  the top finishers, and the player's row highlighted.
- **Caught by cops** (`Race_EventBuffer == $FFFF`, `Race_CopIndex != 0`): a police-officer
  portrait/quote and the fine, or GAME OVER if the player cannot pay.
- **Bike repair** (`Race_EventBuffer == $FFFF`, `Race_CopIndex == 0`): a rider/mechanic
  portrait and the repair cost, or GAME OVER if the player cannot pay.

Start exits (top-level: outcome 4 -> EndLevel screen, otherwise back to the menu);
A opens the high-score table; C opens the bike shop; B shows the cash/password box.

## Outcome flags (computed by `Race_ComputeResults` in `src/race/race.asm`)

| Address | Meaning |
|---|---|
| `ram_FF0526`/`ram_FF0528` | Player A/B race outcome; copied to `ram_FF0918`. |
| `ram_FF0918` | 0 = a course not completed; >4 = a course worse than 4th; 4 = all five courses in 1st-4th (level complete). |
| `Race_EventBuffer` | 16-long race sort/event buffer; first word `$FFFF` = busted or bike destroyed. |
| `Race_CopIndex` | Cop/officer index (1..5) when busted; 0 = bike destroyed. |
| `ram_FF091A` | Fine/repair amount: cop fine = `PlayerLevel * $14`; repair = 10% of the bike price (`Shop_dPrices`), deducted from money. |
| `ram_FF1414`/`FF1418`/`FF141A` | Standings string header/text, height, width (built by `src/race/race.asm`). |
| `Menu_ram_PlayerLevel` | Level (1..5) for the fine, repair and congratulations text. |

Message group by outcome: 0 -> index 21 (`unk_5276`: complete every course); >4 ->
index 28 (`unk_52CE`: complete every course in 4th place or better); 4 -> index 35
(`ram_FF089A` = `unk_533A` congratulations with the level digit).

## Normal results (`RaceResults_DrawStandings`)

- Title `unk_AF26C` -> VRAM `$9000`, 27x2 at (7,1), base tile `$480`.
- Track image `unk_7E670[track]` -> `$B000`, 36x11 at (2,5), base `$580`;
  nametable `unk_7E68E[track]+4`; palette `unk_7E698[track]`; image offset
  `unk_7E684[track]` (all zero).
- Standings `ram_FF1414`: encode, set palette 3 (`$6000`) on all cells; player's place
  from `Menu_ram_PlayerAPlaces/BPlaces[track]` (clamped to 4), clear bit `$2000`
  (palette 2) on that row; draw at the header position with stride 64.
- The player's row is the only visually distinct row; the top 4 finishers come from the
  race's standings string.

## Caught by cops (`RaceResults_DrawBusted`)

- Title `unk_7ED66` -> `$9000`, 0x15x2 at (0xA,1), base `$480`.
- Panel `unk_7EA66` -> `$B000`, 12x14 at (2,5), base `$580`.
- Select the cop portrait from `RaceResults_CopTablePos` (money >= 0, 5x4 variants) or `RaceResults_CopTableNeg`
  (money < 0, 5x2), index `Race_CopIndex-1`, random variant (`&$18` / `&8`).
- Same asset format as `src/screens/rider_intro.asm`: 8-byte interleaved size/header prefix; header
  gives name string, image/nametable/palette offsets. Draw 10x12 at (3,6), name at
  (3,19), quote at (16,y/2) with stride 128.
- Message: `unk_56AC` "Caught by the cops / Your fine -" with `ram_FF091A` formatted by
  `Race_FormatNumber`, or `unk_56D8` "Can't afford bail / GAME OVER"; drawn at (16,18), stride 64.
- Cop names in the table: O'Leary, O'Rourke, Flynn, O'Shea, O'Connor.

## Bike repair (`RaceResults_DrawRepair`)

- Panel `unk_7EA66` -> `$B000`, 12x14 at (2,5).
- Select the portrait from `RaceResults_LevelTablePos` (money >= 0, 5 levels x4 variants) or
  `RaceResults_LevelTableNeg` (money < 0, 5x2), index `Menu_ram_PlayerLevel-1`, random variant.
- Message: `unk_5704` "Your bike needs repairs -" with `ram_FF091A` formatted, or
  `unk_5730` "No money for repairs / GAME OVER".
- Level-table names: Biff, Slater, Ikira, Sergio, Helldog.

## Status box, congratulations, audio

`RaceResults_Init` repurposes `MenuPassword_StrPasswordStatus` as a 12x5 box at
(14,22): player name (10 chars), "cash" + money (`Race_FormatMoney`; negative money adjusts
`ram_FF0682`), and the 24-char password. It copies `unk_533A` ("Congratulations! ... on
level 1") to `ram_FF089A` and patches the level digit. If not busted: `AudioFunc4`,
song 9, `AudioFunc3`; the bust path plays `AudioFunc3(10)`.

## Input & messages

- `GetInput` returns 1 = pressed. Start (bit 7) **held** exits; A (bit 6) and C
  (bit 5) on a **new press** select high score/shop; B (bit 4) on a new press shows the
  cash/password group for 25 s (timer 1500, blink 0x1E).
- Message cycle: every 300 frames (5 s) advance by 8; on the `$FFFFFFFF` terminator
  reset to the group start (0xA8/0xE0/0x118) instead of exiting. The initial and B
  timers are 1500 frames.
- Button prompts (`unk_4FFA` Start, `unk_4F4A` A, `unk_503E` B, `unk_4FB6` C) come from
  `Message_MsgArray`; `Menu_ShowMessage` draws them.

## VDP / assets

Same video configuration as the main menu: planes A/B `$4000`, window `$7000` (64x28,
WindowY 28), sprite/HScroll `$6000`, 128x32, display on, H-int off. Background
`img_MainMenu_Background` -> `$8000`, gamepad -> `$A000` (plane), font -> `$0`, panel
`unk_7EA66` -> `$B000`, portrait -> `$C000`; frame buffer -> `$7000`.

Track-image tables (just before `src/core/top_level.asm`):

| Address | Contents |
|---|---|
| `$7E670` | 5 long pointers to track images (index `trackId*2`). |
| `$7E684` | 5 words image offsets in the decompressed buffer (all 0). |
| `$7E68E` | 5 words nametable offsets. |
| `$7E698` | 5 words palette offsets. |

Result portrait tables (8-byte records `quote_ptr, image_ptr`):

| Address | Selection | Variants |
|---|---|---|
| `$19D32` | level, money >= 0 | 5 levels x 4 |
| `$19DD2` | level, money < 0 | 5 levels x 2 |
| `$19E22` | cop, money >= 0 | 5 x 4 |
| `$19EC2` | cop, money < 0 | 5 x 2 |

## Quirks / unused data

- `ram_FF0914` is set to the active draw routine (`RaceResults_DrawStandings`/`RaceResults_DrawBusted`/`RaceResults_DrawRepair`) but
  is never read in the disassembled source. `[static]` (purpose TODO)
- `DrawString` (`0x6C5E`) is not called by this module (the shop has its own
  `Shop_DrawString`); the source itself notes "not sure this function belongs to this
  file". `[static]`
- The tail data `unk_6C94`, `unk_6D00`, `unk_6D14`, `unk_6D50`, `unk_6D88` ("To go to
  the next level, you need to earn ... more.", "Continue play at Current level",
  "The next level will be level") is not referenced in the source; likely dead/legacy
  data. `[static]`
- The demo path skips this module (`src/core/top_level.asm` `0x7E8B4` -> menu), so a dynamic
  capture needs the non-demo race.

## Dynamic status

Not captured: the demo skips results and forcing the non-demo race needs input. Table
contents and the flag logic are parsed statically from `baserom.md` and `src/race/race.asm`.
To confirm visually: finish a non-demo race in the native console and inspect the
standings/police/repair screens.


# Module card: `src/screens/rider_intro.asm`

- **ROM range:** `0x0059C4`–`0x005F27` (`RiderIntro_Init` `0x59C4`,
  `RiderIntro_GameTick` `0x5E66`)
- **Status:** line-by-line analyzed (static; rendering not yet dynamically confirmed)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/rider_intro.md`

## Role / purpose

Pre-race **rider/opponent introduction**. After the main menu (non-demo path only) the
screen shows the rider you will race next: portrait, name, taunt/quote, a background
and gamepad, and a timed message. A button press (or the message sequence ending) exits
to the race and records the controller in `Race_ram_ActiveController`.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `RiderIntro_Init` | `0x59C4` | `src/core/top_level.asm` `0x7E78C` | Build the screen. |
| `RiderIntro_GameTick` | `0x5E66` | `src/core/top_level.asm` `0x7E790` (fade wrapper) | Per-frame update/input. |

`src/core/top_level.asm` skips the screen when `MainMenu_ram_DemoMode != 0` (`0x7E782`).

## Control flow / state machine

1. `Init`: VDP setup (same as main menu), background/gamepad/portrait panel, select
   opponent record, decode name/quote/palette, optional overlay, font, message, DMA.
2. `GameTick`: DMA the frame buffer, detect a **release** edge on pad A then B
   (`GetInput` returns 1 = pressed; the code uses `~input & previous`), advance the
   message every 300 frames until the `$FFFFFFFF` terminator, redraw, audio tick.

## RAM / ROM & structures

- Opponent table `RiderIntro_RecordTable` (`0x19A12`): `[5 levels][5 tracks][4 variants]`, 8-byte
  records `quote_ptr, image_ptr`; index `base + variant + (level-1)*$A0 + track*$10`;
  variant in `{0,8,$10,$18}`, track in `{0,2,4,6,8}`.
- Image prefix at `image-8`: even bytes = compressed size, odd bytes = header pointer;
  header at `p`: `-10` string ptr (name at `+6`), `-6` image offset, `-4` nametable
  offset, `-2` palette offset.
- Quote: `8-byte header (y,x,height,width) + width*height text`; 155 referenced
  quote records (85 intro + results/end-level) are committed as normal source in
  `src/screens/rider_intro_quotes.asm`, with headers in decimal and one `dc.b`
  line per text row. `align 2,0` provides the normal 2-byte padding. The 85
  intro-only records are named `RiderIntro_Quote_<Rider>_<NN>`; the 70
  results/end-level records keep `RaceQuote_<addr>`.
  `RiderIntro_Quote_Natasha_16` has an authoring bug: header width 22 but text authored as
  3×23; it is split at 23 with a comment and a trailing `$00`, so the source and
  actual 22-column rendering differ; bytes are preserved.
- The 11 unique portrait images are at `$AF902-$BE628`, in the ROM tail after the
  current `$7EA65` build coverage.
- `ram_FF0520` = selected player's 2-bit "extra" field (`$FF0522`/`$FF0524`); variant 3
  and the `unk_B1506` overlay are used when it is non-zero and the image is `unk_AF902`.
- `Menu_ram_Player` selects A/B; `Menu_ram_PlayerALevel/BLevel` and
  `Menu_ram_CurrentTrackId` select the record.
- Frame buffer `Menu_ram_FrameBuffer` (`$FFB62C`, 64x28) DMA'd to VRAM `$7000`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RiderIntro_Init` | `0x59C4` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `RiderIntro_GameTick` | `0x5E66` | [x] | [x] | [x] | [x] | [x] | [ ] | line-by-line |
| `RiderIntro_RecordTable` | `0x19A12` | [x] | [x] | [x] | - | [x] | - | parsed |

Detailed listing, table parse and layout: `docs/analysis/rider_intro.md`.

## External calls / dependencies

- Callers: `src/core/top_level.asm`.
- Uses `UncompressW/B`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `Rand_NextWord`, `GetInputPlayerA/B`,
  `Audio_Update/4`.

## Hacks / bugs / quirks

- Background tiles are written to VRAM `$4000` but the map uses base tile `$400`
  (`$8000`); the visible background relies on the main menu's tiles at `$8000`. The
  `$4000` write is overwritten by the nametable. `[static]`
- Quote rows are double-spaced by using destination stride 128 (rows 3,5,7,9); the
  destination Y is the header Y shifted right by one. `[static]`
- Variant 3 is not chosen randomly; it replaces variant 0 only when the player's
  "extra" field is non-zero. `[static]`
- The 10-character name is centered by counting trailing minus leading spaces,
  halving the surplus and right-rotating the field. `[static]`
- The portrait palette overwrites all 64 global palette words. `[static]`

## Verified facts

- `[static]` Flow: main menu -> Character (non-demo) -> race; demo skips it.
- `[static]` Table/asset formats and 100 opponent records parsed from `baserom.md`.
- `[static]` Message cycle starts at index 18 (byte offset `8*18`), advances by 8
  after 301 ticks (~5 s), and ends at `$FFFFFFFF`; releasing a held button on pad A/B
  exits and sets the active controller (A is checked first).
- `[static]` Portrait header names: 0 Natasha, 1 O'Leary, 2 O'Rourke, 3 Flynn, 4 O'Shea,
  5 O'Connor, 6 Biff, 7 Slater, 8 Ikira, 9 Sergio, 10 Helldog.
- `[static]` The 85 intro-only quote records were renamed to
  `RiderIntro_Quote_<Rider>_<NN>`; the 70 results/end-level quotes remain
  `RaceQuote_<addr>`.

## Hypotheses

- `[hypothesis]` `unk_B1506` is Natasha's bike/overlay (`U-0008`); `ram_FF0520` is a
  bike/opponent class. Test: render `unk_B1506` and the portrait with the game palette.
- `[hypothesis]` The `$4000` background write is a leftover/bug (should be `$8000`).
  Test: enter the screen right after `RiderIntro_Init` without the main menu and inspect
  VRAM.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `unk_AF902` | `RiderIntro_NatashaImage` | parsed name | medium |
| `unk_B1506` | `RiderIntro_NatashaBike` | conditional overlay (`U-0008`) | low |

The intro quote labels were renamed during the line-by-line pass; this table lists the
remaining asset proposals, which need a separate task.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Reach the screen | GDB demo + force `DemoMode=0` at `0x7E782` | Not reached within budget (demo path/time) | visual confirmation pending |

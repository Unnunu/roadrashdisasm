# Module card: `src/screens/menu_main.asm`

- **ROM range:** `0x003400`–`0x004225`
- **Status:** analyzed (all functions line-by-line; exact card layout/demo visual TODO)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/menu_main.md`

## Role / purpose

Main menu: background/gamepad/race-selection graphics, player A/B/two-player selection,
race/track selection, music toggle, demo timer, tooltips, and the entry point to the
password screen (C) and to the race (Start release).

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Menu_Init` | `0x3400` | top-level flow | VDP setup, assets, frame buffer, initial draws, music; does not install the update (caller sets `MainMenu_GameTick`). |
| `MainMenu_GameTick` | `0x3802` | `ram_UpdateFunction` | Per-frame DMA of the previous buffer, input edges, Start release, demo timeout, tooltips/PRNG ticks. |
| `MainMenu_HandleInput` | `0x3BE2` | GameTick | Player mode/music/track/password selection. |
| `WriteNametableToBuffer` | `0x37AA` | this module | Copy a nametable rectangle into a RAM buffer with a caller-supplied stride. |
| `Menu_WriteNametableMasked` | `0x37D2` | race cards | Same, but only where the destination word equals the `d5` sentinel (equality, not a bitwise mask). |
| `Menu_DrawPlayerInfo` | `0x39AE` | init/input | Player A/B name + level + selection border. |
| `Menu_DrawRaceSelection` | `0x3F18` | init/input | Race badge + five race cards. |
| `Menu_DrawRaceCard` | `0x408E` | race selection | Card tilemap + place text, masked write. |
| `Menu_BuildRaceTooltip` | `0x3B56` | input | Race-name record + `*16/$210` value formatted before "miles" in `Menu_ram_TempString`. |
| `Menu_ShowMessage` | `0x417C` | init/tick | Tooltip text/image with blink. |

## VDP configuration (`Menu_Init`)

```
reg0  $04   H-int off
reg1  $74   display on, V-int on, DMA on, 28 rows
reg2  $10   plane A nametable $4000
reg3  $1C   window nametable $7000
reg4  $02   plane B nametable $4000 (same table as A)
reg5  $30   sprite table $6000
reg7  $0D   backdrop palette 0, colour 13
reg0A $FF   H-int counter 255 (H-int disabled by reg0)
reg0B $00   external interrupt off, V-scroll full, H-scroll full
reg0C $81   H40, no interlace, shadow/highlight off
reg0D $18   H-scroll table $6000 (overlaps sprites)
reg0F $02   auto-increment 2
reg90 $03   128x32 planes
reg91 $00   WindowX split 0 (unused: reg92 makes every visible line full-width window)
reg92 $1C   WindowY split at line 224 (DOWN=0) -> covers rows 0-27
```

- Planes A/B share `$4000` (background/race selection).
- Window `$7000` = `Menu_ram_FrameBuffer` (64x28 text/info overlay); DMA'd each frame.
  `WindowY=$1C` with `DOWN=0` puts the split at line 224, so every visible line is a
  full-width window line and the `WindowX=0` split is unused. The password screen
  writes rows 4-27 to `$7200` (`$7000 + $200`).
- Sprite table and H-scroll table overlap at `$6000`; the 16-byte clear zeroes both.
  HSCR is full-screen, so only H-scroll entry 0 matters; the menu uses no sprites.

## Control flow / state machine

- **Init:** reset menu state; reinit a player if money is negative; program VDP; clear
  SAT/H-scroll, VSRAM and the default tile; fill the visible 128x28 A/B cells; upload
  background, race-selection background, password border, gamepad, player border, race
  badges/cards and font; copy the palette from the race-cards blob; clear/draw the frame
  buffer; DMA to `$7000`; start music only if enabled. Does not install the update.
- **GameTick:** DMA the previous frame buffer; read pads A/B and build press/release
  edges; 1800 idle frames (30 s) set `DemoMode=1` and exit; Start exits on release from
  either pad; handle B then A input; tooltip cycle (~240 frames/8 ids); `Menu_ShowMessage`,
  `Audio_Update`, `Rand_StepLfsrAMod`/`Rand_StepLfsrB`, `Rand_NextWord`.
- **Input:** A cycles player mode 1/2/3; B toggles music; Up/Right and Down/Left move the
  current track by 2; C opens the password screen (installs `MenuPassword_GameTick`,
  via `Fade_ram_UpdateFunction` if a fade is running).

## Drawing

- `Menu_DrawPlayerInfo`: clears rows 17-20 except x=14-25 (race badge); 12x4
  selection border at x=1/27,y=17 (base tile `$580`, `$B000`); A/B name + level at
  x=2/28,y=18, 10x2 cells. `PlayerMode` bits 0/1 enable A/B; the highlighted
  player's text uses palette 2 (`$4000`), the other palette 3 (`$6000`). The level is
  added to the ASCII `0`, so only one digit fits.
- `Menu_DrawRaceSelection`: clears rows 6-16; race badge at (14,18); five-card
  carousel: current R at (14,10), R+2 at (21,8), R+4 at (25,6), R+8 (R-2) at (7,8),
  R+6 (R-4) at (3,6), all mod 10, using the active player's five-place array.
- `Menu_DrawRaceCard`: copies a 12x6 card nametable (144 bytes) from
  `Race_ram_ImageBuffer2+$120`, writes "1st/2nd/3rd/Nth" in row 5, columns 4-7 (or
  nothing for place 0; places 1-19 supported), then writes it with the `$7FF`
  sentinel (only default/black cells are replaced). The font tile words are reduced
  by `$680` so the masked writer's base restores them.
- `Menu_BuildRaceTooltip`: copies a 5x20 race-name record; inserts `level_word * 16 / $210`
  as a one-decimal value before "miles". Hard-codes the 5x20 layout and record offset 97;
  `d0` (track id) is preserved, `d1/a0/a1` clobbered.
- `Menu_ShowMessage`: `Message_MsgArray` text/show-function pointers, blink timer,
  `Message_Clear`/`Message_ShowEmpty`.

## RAM / ROM & structures

- `MainMenu_ram_DemoMode` `$FF3692`, `MainMenu_ram_FrameCounter` `$FF3694`,
  `MainMenu_ram_ButtonsPlayerA/B` `$FF05C8/$FF05CC`, `ChangedButtonsPlayerA/B`
  `$FF05CA/$FF05CE`, `MainMenu_ram_CurrentButtons` `$FF05DE`.
- `Menu_ram_PlayerMode` `$FF05DA` (1/2/3), `Menu_ram_Player` `$FF0508`,
  `Menu_ram_CurrentTrackId` `$FF05DC`, `Menu_ram_CurrentlyDrawnRaceCard` `$FF05E4`,
  `Menu_PlayerPlacesPtr` `$FF05E0`, `Menu_ram_TempString` `$FF0756`,
  `Menu_ram_StrPlayerName` `$FF046A`.
- `Menu_ram_FrameBuffer` `$FFB62C` (64x28, `$E00`), `Race_ram_ImageBuffer2` `$FF8364`.
- Assets: `img_MainMenu_Background`, `img_MainMenu_RaceSelectionBackground`,
  `img_PasswordMenu_PlayerSelection`, `img_Gamepad`, `img_mainMenu_PlayerSelection`,
  `img_MainMenu_RaceBadges`, `img_mainMenu_RaceCards`, `img_Intro_Font`.

## External calls / dependencies

- `UncompressW`/`UncompressB`, `WriteTilesetToVRAM`, `DmaWriteVRAM`,
  `EncodeString`/`WriteNametable`, `WriteNametableToBuffer`, `Menu_ShowMessage`,
  `Menu_DrawRaceSelection`, `Menu_DrawPlayerInfo`, `MenuPassword_SelectCurrentTrack`, `MenuPassword_GameTick`,
  `Fade_ram_UpdateFunction`, `Audio_Update/3/4`, `Rand_NextWord`, `Rand_StepLfsrAMod`/`Rand_StepLfsrB`.

## Hacks / bugs / quirks

- Planes A/B share `$4000`; the window `$7000` overlays the text; the password screen
  writes `$7200`.
- Sprite table and H-scroll table overlap at `$6000`; the 16-byte clear is used to
  zero both. Sprites are unused here.
- The race cards are masked writes (only black/default tiles replaced).
- Start exits on **release**; the demo timer is 30 s. `GetInputPlayerA/B` define only
  `d0.b`, but `DmaWriteVRAM` leaves `d0 < $100`, so the word stores/tests are safe.
- The tooltip timer uses `bpl`, so it advances after 241 decrements (~4.02 s), not exactly
  240; the `beq .end` after the index-6 wrap is redundant.
- The gamepad asset header is 12x9, but every call site copies only the top 12x6 rows;
  the lower 3 rows are unused.
- The menu palette comes from the race-cards blob at `+$26E4`; the copy must happen before
  the font decompression overwrites `Intro_ram_ImageBuffer`.
- The initial tooltip is index 6, **"Press Start to race"**; its positive blink timer
  clears/hides it for the first 30 frames.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Menu_Init` | `0x3400` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed (line-by-line) |
| `WriteNametableToBuffer` | `0x37AA` | [x] | [x] | [x] | - | [x] | - | analyzed (line-by-line) |
| `Menu_WriteNametableMasked` | `0x37D2` | [x] | [x] | [x] | - | [x] | - | analyzed (line-by-line) |
| `MainMenu_GameTick` | `0x3802` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed (line-by-line) |
| `Menu_DrawPlayerInfo` | `0x39AE` | [x] | [x] | [x] | [x] | [x] | - | analyzed (line-by-line) |
| `Menu_BuildRaceTooltip` | `0x3B56` | [x] | [x] | [x] | [x] | [x] | - | analyzed (line-by-line; `U-0001`) |
| `MainMenu_HandleInput` | `0x3BE2` | [x] | [x] | [x] | [x] | [x] | - | analyzed (line-by-line) |
| `Menu_DrawRaceSelection` | `0x3F18` | [x] | [x] | [x] | [x] | [x] | - | analyzed (line-by-line; `U-0003`) |
| `Menu_DrawRaceCard` | `0x408E` | [x] | [x] | [x] | [x] | [x] | - | analyzed (line-by-line; layout TODO) |
| `Menu_ShowMessage` | `0x417C` | [x] | [x] | [x] | - | [x] | - | analyzed (line-by-line) |

Detailed notes and the annotated algorithm live in `docs/analysis/menu_main.md`.

## Verified facts

- `[static]` VDP/window/frame-buffer configuration and the password screen's `$7200`
  (window row 4). The window is full-screen: `WindowY=$1C`/`DOWN=0` puts the split at
  line 224, so every visible line is a full-width window line and the `WindowX=0` split
  is unused.
- `[static]` `Menu_Init` does not install `MainMenu_GameTick`; `top_level` does.
- `[static]` The A/B fill covers 128x28 cells (`$E00` words); rows 28-31 are untouched.
- `[static]` The palette source is the race-cards blob `+$26E4` (128 bytes), copied before
  the font decompression.
- `[static]` Asset offsets/tile counts and the gamepad 12x9 -> top 12x6 discrepancy.
- `[static]` Player modes 1=A, 2=B, 3=two; A cycles, B toggles music, directions change
  the track by 2, C opens the password screen.
- `[static]` Race cards are 12x6 tilemaps (144 bytes each) with a masked write and
  place text in row 5, columns 4-7 (places 1-19).
- `[static]` The five-card carousel is: R at x=14, R+2 at x=21, R+4 at x=25, R+8
  (R-2) at x=7, R+6 (R-4) at x=3, all mod 10.
- `[static]` Demo after 1800 frames (30 s) without input; Start exits on release.

## Hypotheses / open questions

- `[hypothesis]` `U-0001`: the `Menu_BuildRaceTooltip` value is the race distance in
  miles; formatting and the "miles" text are static.
- `[hypothesis]` `U-0002`: the gamepad map header is 12x9 while all call sites copy only
  12x6; the lower 3 rows are probably unused padding.
- `[hypothesis]` `U-0003`: the `divu #10 / swap / andi #$FFFE` normalization is an
  identity even-mask for the documented ids; its origin is unclear.
- `[ ]` Confirm the card layout/stride and five positions visually.
- `[ ]` Confirm the demo path in BlastEm.
- `[ ]` `Menu_dRaceNameTable`/`unk_25EC0`/`word_4EEE` are labelled data modules;
  per-entry track-record semantics remain outside this pass.


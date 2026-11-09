# Module card: `menu_main.asm`

- **ROM range:** `0x003400`–`0x004225`
- **Status:** analyzed (VDP/window/menu structure understood; exact card layout/demo TODO)
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
| `Menu_Init` | `0x3400` | top-level flow | VDP setup, assets, frame buffer, initial draws, music. |
| `MainMenu_GameTick` | `0x3802` | `ram_UpdateFunction` | Per-frame DMA, input, start/demo handling, tooltips. |
| `MainMenu_HandleInput` | `0x3BE2` | GameTick | Player mode/music/track/password selection. |
| `WriteNametableToBuffer` | `0x37AA` | this module | Copy a nametable rectangle into a 64-wide buffer. |
| `Menu_WriteNametableMasked` | `0x37D2` | race cards | Same, but only where the destination equals the mask tile. |
| `Menu_DrawPlayerInfo` | `0x39AE` | init/input | Player A/B name + level + selection border. |
| `Menu_DrawRaceSelection` | `0x3F18` | init/input | Race badge + five race cards. |
| `Menu_DrawRaceCard` | `0x408E` | race selection | Card tilemap + place text, masked write. |
| `Menu_BuildRaceTooltip` | `0x3B56` | input | Race name/distance tooltip string (`Menu_ram_TempString`). |
| `Menu_ShowMessage` | `0x417C` | init/tick | Tooltip text/image with blink. |

## VDP configuration (`Menu_Init`)

```
reg0  $04   H-int off
reg1  $74   display on, V-int on, DMA on, 28 rows
reg2  $10   plane A nametable $4000
reg3  $1C   window nametable $7000
reg4  $02   plane B nametable $4000 (same table as A)
reg5  $30   sprite table $6000
reg7  $0D   backdrop $D
reg0A $FF   H-int counter (disabled)
reg0B $00   V-scroll full, H-scroll full
reg0C $81   H40
reg0D $18   H-scroll table $6000 (overlaps sprites)
reg0F $02   auto-increment 2
reg90 $03   128x32 planes
reg91 $00   WindowX 0
reg92 $1C   WindowY 28 cells (window covers the screen)
```

- Planes A/B share `$4000` (background/race selection).
- Window `$7000` = `Menu_ram_FrameBuffer` (64x28 text/info overlay); DMA'd each frame.
  The password screen writes rows 4-27 to `$7200` (`$7000 + $200`) — confirmed with
  `menu_password.asm`.
- Sprite table and H-scroll table overlap at `$6000`; the menu does not use sprites.

## Control flow / state machine

- **Init:** reset menu state; reinit a player if money is negative; program VDP; clear
  sprites/VSRAM/default tile/A/B nametable; decompress/upload background, race-selection
  background, password border, gamepad, player selection, race badges/cards and font;
  copy palettes; clear/draw the frame buffer; DMA to `$7000`; start music.
- **GameTick:** demo timer 1800 frames (30 s) -> demo mode and exit; DMA frame buffer;
  read pads A/B; Start exits on release; handle input; tooltip cycle (240 frames/8 ids);
  `Menu_ShowMessage`, `AudioFunc1`, `sub_160B0/CC`, `Rand_GetWord`.
- **Input:** A cycles player mode 1/2/3; B toggles music; Up/Right and Down/Left move the
  current track by 2; C opens the password screen (installs `MenuPassword_GameTick`,
  via `Fade_ram_UpdateFunction` if a fade is running).

## Drawing

- `Menu_DrawPlayerInfo`: clears rows 17-20; selection border at x=1/27,y=17; active
  player's name + "Level X" at x=2/28,y=18, palette 2/3.
- `Menu_DrawRaceSelection`: clears the race area; race badge at (14,18); five cards at
  (14,10), (21,8), (25,6), (7,8), (3,6), using the places array and track id 0,2,4,6,8.
- `Menu_DrawRaceCard`: copies a 12-wide x6-high card nametable from `Race_ram_ImageBuffer2+$120`,
  writes "1st/2nd/3rd/Nth" (or nothing for place 0), then writes it with the mask
  `$7FF` (only opaque/black tiles are replaced).
- `Menu_BuildRaceTooltip`: race name + decimal distance/record from `Menu_dRaceNameTable`/`unk_25EC0`.
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

- `UncompressW`/`UncompressB`, `WriteToVRAM`, `DmaWriteVRAM`,
  `EncodeString`/`WriteNametable`, `WriteNametableToBuffer`, `Menu_ShowMessage`,
  `Menu_DrawRaceSelection`, `Menu_DrawPlayerInfo`, `MenuPassword_SelectCurrentTrack`, `MenuPassword_GameTick`,
  `Fade_ram_UpdateFunction`, `AudioFunc1/3/4`, `Rand_GetWord`, `sub_160B0/CC`.

## Hacks / bugs / quirks

- Planes A/B share `$4000`; the window `$7000` overlays the text; the password screen
  writes `$7200`.
- Sprite table and H-scroll table overlap at `$6000`; sprites are unused here.
- The race cards are masked writes (only black/default tiles replaced).
- Start exits on **release**; the demo timer is 30 s.

## Coverage matrix

See `docs/analysis/menu_main.md` for the full matrix.

## Verified facts

- `[static]` VDP/window/frame-buffer configuration and the password screen's `$7200`
  (window row 4).
- `[static]` Player modes 1=A, 2=B, 3=two; A cycles, B toggles music, directions change
  the track by 2, C opens the password screen.
- `[static]` Race cards are 6x12 tilemaps with a masked write and place text.
- `[static]` Demo after 1800 frames (30 s) without input; Start exits on release.

## Hypotheses / open questions

- `[hypothesis]` `Menu_BuildRaceTooltip` builds the race name + distance/record tooltip.
- `[ ]` Confirm the card layout/stride and five positions visually.
- `[ ]` Confirm the full-screen window and the demo path in BlastEm.
- `[ ]` `Menu_dRaceNameTable`/`unk_25EC0`/`word_4EEE` live in the gap; data-map/disassemble later.


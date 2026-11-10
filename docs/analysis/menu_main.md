# Analysis: `src/screens/menu_main.asm` (main menu)

- **Module / routine:** main menu (VDP setup, background, race selection, player info,
  music toggle, demo timer, password-screen entry)
- **ROM range:** `0x003400`–`0x004225` (`src/screens/message.asm` starts at `0x4226`)
- **Status:** analyzed (VDP/window/menu structure; demo flow and forced Menu_Init entry confirmed; exact card layout TODO)
- **Source:** `src/screens/menu_main.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/screens_flow.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Menu_Init` | `0x3400` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `WriteNametableToBuffer` | `0x37AA` | [x] | [x] | [x] | - | [x] | - | analyzed |
| `Menu_WriteNametableMasked` | `0x37D2` | [x] | [x] | [x] | - | [x] | - | analyzed |
| `MainMenu_GameTick` | `0x3802` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Menu_DrawPlayerInfo` | `0x39AE` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Menu_BuildRaceTooltip` | `0x3B56` | [x] | [x] | [x] | - | [x] | - | analyzed (semantics hypothesis) |
| `MainMenu_HandleInput` | `0x3BE2` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Menu_DrawRaceSelection` | `0x3F18` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Menu_DrawRaceCard` | `0x408E` | [x] | [x] | [x] | [x] | [x] | - | analyzed (layout TODO) |
| `Menu_ShowMessage` | `0x417C` | [x] | [x] | [x] | - | [x] | - | analyzed |

## VDP configuration (`Menu_Init`)

```
reg0  $04   H-int off
reg1  $74   display on, V-int on, DMA on, 28 rows
reg2  $10   Scroll A nametable $4000
reg3  $1C   Window nametable $7000
reg4  $02   Scroll B nametable $4000   (same table as A)
reg5  $30   sprite table $6000
reg7  $0D   backdrop $D
reg0A $FF   H-int counter (disabled)
reg0B $00   V-scroll full, H-scroll full
reg0C $81   H40
reg0D $18   H-scroll table $6000      (overlaps the sprite table!)
reg0F $02   auto-increment 2
reg90 $03   128x32 planes
reg91 $00   WindowX = 0
reg92 $1C   WindowY = 28 cells (window covers the whole 28-row screen)
```

Layers:

- **Planes A and B share the nametable at `$4000`** (background/race-selection image).
- **Window at `$7000`** = the 64x28 `Menu_ram_FrameBuffer` text/info overlay. This is
  DMA'd every frame; the password screen writes rows 4-27 (`$7200`) into it.
- **Sprite table `$6000`** and **H-scroll table `$6000`** overlap. The menu does not use
  sprites (it clears the first 16 bytes); the H-scroll is full-screen and the table is
  unused/zero. The overlap is a quirk to keep in mind for screens that use sprites.

VRAM map:

| VRAM | Contents |
|---|---|
| `$0000` | font tiles (`img_Intro_Font`) |
| `$4000` | planes A/B nametable (background/race selection/gamepad) |
| `$6000` | sprite table / H-scroll table (overlap) |
| `$7000` | window nametable = `Menu_ram_FrameBuffer` (64x28) |
| `$8000` | main menu background tiles (`img_MainMenu_Background`) |
| `$9000` | race-selection background tiles |
| `$9400` | password player-selection border tiles |
| `$A000` | gamepad tiles |
| `$B000` | player-selection border tiles |
| `$C000` | race badge tiles |
| `$D000` | race card tiles |
| `$FFE0` | default (black) tile |

The frame buffer is cleared with the default tile `$7FF` (low priority, palette 0, tile
`$FFE0`). The password screen's destination `$7200` is therefore the window nametable
row 4 (`$7000 + $200`), matching `src/screens/menu_password.asm`.

## Init flow (`Menu_Init`, `0x3400`)

1. Reset menu state (demo/frame counter/buttons/messages); set the default tooltip
   (message `8*6`, "Press A to start race").
2. If the selected player's money is negative, reinitialize that player via
   `Intro_InitPlayerA`/`Intro_InitPlayerB`.
3. Program the VDP (above); clear sprites, VSRAM, the default tile; fill the A/B
   nametable with the black default tile.
4. Decompress/upload the background, race-selection background, password border, gamepad,
   player selection, race badges, race cards and font; build their nametables (background
   at rows 0-27, race selection rows 4-17, gamepad rows 22-27, race badges/cards in
   `Race_ram_ImageBuffer2`).
5. Copy the 4 palette lines from the background image into `Global_ram_Palette`.
6. Clear the frame buffer, `Menu_ShowMessage`, `MenuPassword_SelectCurrentTrack`, `Menu_DrawRaceSelection`,
   `Menu_DrawPlayerInfo`; DMA the frame buffer to `$7000`; start music (`Audio_StartMusic`).

## Per-frame flow (`MainMenu_GameTick`, `0x3802`)

- `MainMenu_ram_FrameCounter++`; after 1800 frames (30 s) without input,
  `MainMenu_ram_DemoMode = 1` and the stage ends (demo/attract path).
- DMA the frame buffer to `$7000`.
- Read pads A/B; `Changed = old ^ new`; any button resets the demo timer.
- Start edge: exits on **release** (current Start bit skips, changed Start bit ends the
  stage) -> `ram_UpdateFunction = 0`, top-level flow continues (race/demo).
- Handle newly pressed buttons for B/A (`MainMenu_HandleInput`); if the update function
  changed (password screen), skip the tooltip update.
- Tooltip cycle: every 240 frames (4 s) advance `Menu_ram_CurrentMessageId` by 8 (tooltip
  array `Message_MsgArray`); `Menu_ShowMessage`; `Audio_Update`, `sub_160B0/CC`,
  `Rand_GetWord`.

## Input (`MainMenu_HandleInput`, `0x3BE2`)

| Button | Action |
|---|---|
| A (`$40`) | cycle player mode 1 (A) -> 3 (two players) -> 2 (B) -> 1; redraw player info/race selection |
| B (`$10`) | toggle music (`Audio_StopMusic`, `ram_MusicEnabled`, `Audio_StartMusic`), tooltips 8*2/8*3 |
| Up/Right (`$01`/`$08`) | current track +2 (wrap 0..8) |
| Down/Left (`$02`/`$04`) | current track -2 (wrap 0..8) |
| C (`$20`) | open the password screen for the player who pressed C |

C (password entry):

- Sets `Menu_ram_CurrentButtonsPtr`/`ChangedButtonsPtr`, `MenuPassword_ram_StrPlayerNamePtr`
  and `StrPlayerPasswordPtr` for player A/B.
- Fills `FrameBuffer + $200` (row 4) with spaces, loads/draws the password
  player-selection border (`$9400`) and the labels (`word_4EEE`), draws the names/passwords.
- Installs `MenuPassword_GameTick` as `ram_UpdateFunction`; if a fade is in progress
  (`FadeWithFunction_GameTick`), it goes through `Fade_ram_UpdateFunction` so the fade
  completes first.

## Drawing (`Menu_DrawPlayerInfo`, `Menu_DrawRaceSelection`, `Menu_DrawRaceCard`, `Menu_BuildRaceTooltip`)

- Note: `WriteNametableToBuffer`/`Masked` take `d0 = width`, `d1 = height` (the source
  headers had them swapped; fixed).
- `Menu_DrawPlayerInfo`: clears rows 17-20, draws the player-selection border (x=1 or 27,
  y=17), then the active player's name + "Level X" at x=2/28, y=18, using palette 2
  (`$4000`) or 3 (`$6000`) depending on the active player. Mode bits 0/1 select A/B.
- `Menu_DrawRaceSelection`: clears the race area, draws the race badge at (14,18), then
  five race cards at (14,10), (21,8), (25,6), (7,8), (3,6) using the player's places
  array and the current track id (0,2,4,6,8).
- `Menu_DrawRaceCard`: copies a 12-wide x6-high card nametable from `Race_ram_ImageBuffer2+$120`,
  writes "1st/2nd/3rd/Nth" into the bottom middle, then writes it with
  `Menu_WriteNametableMasked` (mask `$7FF` = black) so only the card's opaque pixels
  replace the background.
- `Menu_BuildRaceTooltip`: copies the selected race name from `Menu_dRaceNameTable` into `Menu_ram_TempString`,
  then formats a value from `unk_25EC0` (per race/level) as a decimal with a `.` — likely
  the race distance/record tooltip (message `8*4`).
- `Menu_ShowMessage`: looks up the message text and show-function pointers in
  `Message_MsgArray` (8 bytes per id); if the blink timer is positive, clears/hides the
  text (`Message_Clear`/`Message_ShowEmpty`); otherwise calls the show function, encodes
  the tooltip text and writes it to the frame buffer.

## Verified facts

- `[static]` Planes A/B share `$4000`; the window at `$7000` holds the 64x28 frame
  buffer; the password screen's `$7200` is window row 4 (confirms the password module's
  DMA destination).
- `[static]` The sprite table and H-scroll table overlap at `$6000`; the menu does not
  use sprites.
- `[static]` The demo timer is 1800 frames (30 s); the menu exits on Start release.
- `[static]` Player mode 1=A, 2=B, 3=two players; C opens the password screen; A/B
  toggle player mode/music; directions change the current track by 2.
- `[static]` The race cards are written with a mask (`$7FF` default black), so only
  opaque pixels replace the background.

## Hypotheses / open questions

- `[hypothesis]` `Menu_BuildRaceTooltip` produces the selected race's name + distance/record tooltip
  (message 8*4); the `Menu_dRaceNameTable`/`unk_25EC0` tables are in the not-yet-disassembled gap.
- `[hypothesis]` The window is full-screen because WindowX=0/WindowY=28; the exact VDP
  window region should be confirmed with a VDP viewer.
- `[ ]` Confirm the exact race-card layout/stride and the five card positions visually.
- `[ ]` Confirm the demo path (30 s no input) in BlastEm.
- `[ ]` `Menu_dRaceNameTable`, `unk_25EC0`, `word_4EEE` are in the gap; disassemble/data-map later.

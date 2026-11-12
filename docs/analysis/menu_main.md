# Analysis: `src/screens/menu_main.asm` (main menu)

- **Module / routine:** main menu (VDP setup, background, race selection, player info,
  music toggle, demo timer, password-screen entry)
- **ROM range:** `0x003400`–`0x004225` (`src/screens/message.asm` starts at `0x4226`)
- **Status:** analyzed (all functions line-by-line; exact card layout/demo visual TODO)
- **Source:** `src/screens/menu_main.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/screens_flow.md`

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

## VDP configuration (`Menu_Init`)

```
reg0  $04   H-int off
reg1  $74   display on, V-int on, DMA on, 28 rows
reg2  $10   Scroll A nametable $4000
reg3  $1C   Window nametable $7000
reg4  $02   Scroll B nametable $4000   (same table as A)
reg5  $30   sprite table $6000
reg7  $0D   backdrop palette 0, colour 13
reg0A $FF   H-int counter 255 (H-int disabled by reg0)
reg0B $00   external interrupt off, V-scroll full, H-scroll full
reg0C $81   H40, no interlace, shadow/highlight off
reg0D $18   H-scroll table $6000      (overlaps the sprite table)
reg0F $02   auto-increment 2
reg90 $03   128x32 planes
reg91 $00   WindowX split 0 (unused: reg92 makes every visible line full-width window)
reg92 $1C   WindowY split at line 224 (DOWN=0) -> window covers rows 0-27
```

Layers:

- **Planes A and B share the nametable at `$4000`** (background/race-selection image).
- **Window at `$7000`** = the 64x28 `Menu_ram_FrameBuffer` text/info overlay. This is
  DMA'd every frame; the password screen writes rows 4-27 (`$7200`) into it.
  `WindowY=$1C` with `DOWN=0` puts the split at line 224, so every visible line
  (0-27) is a full-width window line; the `WindowX=0` split is therefore unused.
- **Sprite table `$6000`** and **H-scroll table `$6000`** overlap. The 16-byte clear at
  `$6000` zeroes SAT entries 0-1 and H-scroll entries 0-3; HSCR is full-screen, so only
  H-scroll entry 0 (planes A/B) matters. The menu uses no sprites.

VRAM map:

| VRAM | Contents |
|---|---|
| `$0000` | font tiles, 50 (`img_Intro_Font`) |
| `$4000` | planes A/B nametable (background/race selection/gamepad) |
| `$6000` | sprite table / H-scroll table (overlap) |
| `$7000` | window nametable = `Menu_ram_FrameBuffer` (64x28) |
| `$8000` | main-menu background tiles, 39 (`img_MainMenu_Background`) |
| `$9000` | race-selection background tiles, 23 |
| `$9400` | password player-selection border tiles, 6 |
| `$A000` | gamepad tiles, 90 |
| `$B000` | player-selection border tiles, 6 |
| `$C000` | race badge tiles, 108 |
| `$D000` | race card tiles, 311 |
| `$FFE0` | default tile `$7FF` (all zero) |

The frame buffer is cleared with the default tile `$7FF` (low priority, palette 0, tile
`$FFE0`). The password screen's destination `$7200` is therefore the window nametable
row 4 (`$7000 + $200`), matching `src/screens/menu_password.asm`.

## Init flow (`Menu_Init`, `0x3400`)

1. Reset menu state (`DemoMode=0`, frame counter, A/B buttons and changed buttons);
   set `NextMessageTimer=240` (4 s at 60 Hz), `MessageBlinkTimer=30`,
   `CurrentMessageId=8*6` (index 6, **"Press Start to race"**),
   `ButtonBlinkPeriod=$3F` (64-frame cycle, 32 on/32 off), password cursor `(9,1)`,
   and `Global_ram_PalettePtr = Global_ram_Palette`.
2. If the selected player's money is negative, reinitialize that player via
   `Intro_InitPlayerA`/`Intro_InitPlayerB`; otherwise keep the profile.
3. Program the VDP (above). Clear SAT/H-scroll first 16 bytes at `$6000`, VSRAM words
   0-1, the default tile `$7FF` at `$FFE0`, and fill the **visible 128x28 cells** of the
   shared A/B plane with `$7FF` (`$700` longs = `$E00` words); rows 28-31 stay untouched.
4. Decompress/upload assets in this order (all reuse `Intro_ram_ImageBuffer`, so each
   map is consumed before the next decompression):
   - background: 39 tiles -> `$8000`; 40x28 map at `+$4E4/+$4E8`, base tile `$400`.
   - race-selection background: 23 tiles -> `$9000`; 40x14 map at `+$2E4/+$2E8`
     drawn at y=4, base tile `$480`.
   - password selection border: 6 tiles -> `$9400`; no map is written here.
   - gamepad: 90 tiles -> `$A000`; source header is 12x9 at `+$B44`, but only the top
     12x6 rows of map `+$B48` are copied at (2,22), base tile `$500`; the lower 3 rows
     are unused here.
   - main-menu player selection border: 6 tiles -> `$B000`; its 12x4 map at `+$C8` is
     used later by `Menu_DrawPlayerInfo` with base tile `$580`.
5. Clear the 64x28 frame buffer; compose `Race_ram_ImageBuffer2`:
   - race badges: 108 tiles -> `$C000`; 12x12 map at `+$D84/+$D88` at (0,0).
   - race cards: 311 tiles -> `$D000`; 12x30 map at `+$2764/+$2768` at (0,12).
     The combined buffer is 12x42; each card is 12x6.
6. Copy 128 bytes (4 lines x 16 colours) from the race-cards blob at `+$26E4` into
   `Global_ram_Palette`. This must happen **before** the font decompression overwrites
   `Intro_ram_ImageBuffer`. Then upload the 50 font tiles to `$0000`.
7. Build the initial frame: `Menu_ShowMessage` (blink timer is still positive, so it
   clears/hides the tooltip; `MainMenu_GameTick` reveals it after 30 frames),
   `MenuPassword_SelectCurrentTrack` (first unplayed track, else worst-placed finished
   track), `Menu_DrawRaceSelection`, `Menu_DrawPlayerInfo`; DMA `$700` words to `$7000`;
   start music (`Audio_StartMusic`, `d0=1`) only if `ram_MusicEnabled`.
   `Menu_Init` does **not** install an update function; `top_level` sets
   `ram_UpdateFunction=FadeWithFunction_GameTick` with `MainMenu_GameTick` after the
   fade-in setup.

## Per-frame flow (`MainMenu_GameTick`, `0x3802`)

- `MainMenu_ram_FrameCounter++`; at 1800 frames (30 s) `MainMenu_ram_DemoMode = 1`,
  the counter is reset and the stage ends. Top-level then enters `HighScore_Init` and
  the demo path; `MainMenu_GameTick` itself does not call the high-score screen.
- DMA the *previous* frame buffer to `$7000` (64x28 words). Input/tooltip changes made
  later in the tick become visible on the next frame.
- Latch previous pad state, read A/B, store current buttons, then `Changed = old ^ new`.
  Any currently held button resets the 30 s demo timer.
- `GetInputPlayerA/B` define only `d0.b`; `DmaWriteVRAM` leaves `d0 < $100`, so the
  full-word stores/tests in this function are safe without masking.
- Start is edge-triggered per pad: while the current Start bit is held, the release test
  is skipped; when current Start is clear and the changed bit is set, the stage ends.
  `endStage` stops music and sets `ram_UpdateFunction = 0`.
- Newly pressed buttons are handled B first, then A; releases alone are ignored
  (`Changed & Buttons != 0`). If B opened the password screen, A input is skipped for
  that frame, but the common tail still runs.
- Tooltip timers decrement every tick. `NextMessageTimer` is checked with `bpl`, so it
  advances on the first negative value after 241 decrements (~4.02 s at 60 Hz).
  On advance: reset `MessageBlinkTimer=30`, `NextMessageTimer=240`, add 8 to
  `CurrentMessageId`, and clamp below `8*6` to index 6. If the `Message_MsgArray`
  text pointer is `-1`, wrap to index 6; otherwise draw the pointer this frame. The
  `beq .end` after the wrap is redundant: `move.w` leaves Z clear and `.end` is the
  next instruction.
- Common tail: `Menu_ShowMessage`, `Audio_Update`, advance the `Rand_ram_LfsrA` LFSR via
  `Rand_StepLfsrAMod` (`d2=1`, so its return remainder is 0), advance the `Rand_ram_LfsrB` LFSR via
  `Rand_StepLfsrB`, then advance the main lagged-sum PRNG via `Rand_NextWord`.

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
- `Menu_DrawPlayerInfo`: clears rows 17-20 at x=0-13 and x=26-39, preserving the
  x=14-25 race-badge area. It decompresses the 12x4 selection border and writes it at
  x=1 (A highlighted) or x=27 (B highlighted), y=17, with base tile word `$580`
  (tile data at `$B000`, palette 0). `Menu_ram_PlayerMode` bits 0/1 select A/B info
  (1=A, 2=B, 3=both); A text is at x=2, B text at x=28, y=18, each 10x2 cells.
  Names come from the password name records (`+8`, 10 bytes) followed by
  "Level  0" and two spaces, encoded as 20 chars. `add.w` targets the ASCII `0`, so
  only a single-digit level is represented. The highlighted player's text uses
  palette 2 (`$4000`); the other player uses palette 3 (`$6000`).
- `Menu_DrawRaceSelection`: clears the race area, draws the race badge at (14,18), then
  five cards in a carousel: for current id R, x=14 shows R, x=21 shows R+2, x=25
  shows R+4, x=7 shows R+8 (R-2) and x=3 shows R+6 (R-4), all mod 10, using the
  active player's places array. The ids are even byte offsets into the five-word
  places array.
- `Menu_DrawRaceCard`: copies a 12-wide x6-high card nametable from `Race_ram_ImageBuffer2+$120`
  (144 bytes per card; the even id times `$48` steps by one card), writes
  "1st/2nd/3rd/Nth" into row 5, columns 4-7 (supports places 1-19), then writes it
  with `Menu_WriteNametableMasked` (sentinel `$7FF` = default tile word) so only the
  card's opaque pixels replace the background. The four text words are reduced by
  `$680` before the masked write so the writer's base restores the font tile index at
  VRAM `$0000`.
- `Menu_BuildRaceTooltip`: indexes `Menu_dRaceNameTable` by `trackId*2` and copies the
  fixed 5x20 text record (8-byte header + 100 chars) into `Menu_ram_TempString`. It
  then indexes `unk_25EC0[trackId]`, dereferences the track record's `+$00` level-word
  table, and selects `level-1` (`PlayerALevel` or `PlayerBLevel` depending on
  `Menu_ram_Player`). Value = `level_word * 16 / $210` (tenths); dividing by 10 yields
  the integer part and one fractional digit. It writes the fractional digit at
  offset 97, `.` at 96, then the integer digits backwards (e.g. 94-95 for two
  digits), so the value ends immediately before "miles" at offset 98 in the
  record's last 20-char line. The 5x20 size and record offset 97 are hard-coded;
  the level index is not bounds-checked. The unit of the level word is `U-0001`.
  Output is message id `8*4`. Clobbers `d1/a0/a1`; `d0` is preserved.
- `Menu_ShowMessage`: looks up the message text and show-function pointers in
  `Message_MsgArray` (8 bytes per id); if the blink timer is non-negative, hides the
  text (`Message_ShowEmpty` for static prompts, `Message_Clear` for animated ones);
  otherwise calls the show function, encodes the tooltip text and writes it to the
  frame buffer.

## Nametable helpers (`WriteNametableToBuffer` / `Menu_WriteNametableMasked`)

| | `WriteNametable` (`intro.asm`) | `WriteNametableToBuffer` | `Menu_WriteNametableMasked` |
|---|---|---|---|
| Destination | VRAM plane via `VdpCtrl`/`VdpData` | RAM buffer via `a1` | RAM buffer via `a1` |
| Destination argument | `d5` = plane VRAM byte address | `a1` = buffer pointer | `a1` = buffer pointer |
| `d4` | Base tile word added to every source word | Same | Same, only on a match |
| `d6` | Plane width in cells | Plane width in cells (stride/2) | Plane width in cells (stride/2) |
| Row addressing | Builds a VDP command per row; adds `planeWidth*2` to the command | Adds `planeWidth*2` to `a1`; skips `(planeWidth-width)*2` after each row | Same as buffer |
| Mask | None | None | `d5` = destination word to match; equality test, not a bitwise mask |
| Writes | `width*height` words | `width*height` words | Only matching cells; non-matches keep old contents |
| Out | `a0` past source; `d5` advanced | `a0` past source; `a1` advanced to row `y+height`, column `x` | Same as buffer |
| Clobbers | `d0-d3/d6`, `d5`, `a0` | `d0-d3/d6`, `a0/a1`; `d4/d5` preserved | Same as buffer; `d5` preserved |
| VDP constraint | Requires auto-increment 2; address truncated to 16 bits | None (no VDP access) | None (no VDP access) |

Common contract:

- `d0 = width` (>= 1), `d1 = height` (>= 1), `d2 = x`, `d3 = y`,
  `d4 = base tile word` (tile number plus palette/priority bits),
  `d6 = plane width`, `a0 = packed width*height source words`.
- Destination word address is `base + y*planeWidth*2 + x*2`.
- Requires `1 <= width <= planeWidth` and enough source/destination space; no bounds checks.
- The buffer variants use `adda.w` for the `y*stride` and `x*2` offsets, so only their
  low 16 bits are used; callers keep them small.
- `Menu_WriteNametableMasked` consumes the full source rectangle and advances `a1` across
  non-matching cells; it does not skip source words.
- `Menu_DrawRaceCard` passes `$7FF` as the sentinel, i.e. the default/black tile word.

## Verified facts

- `[static]` Planes A/B share `$4000`; the window at `$7000` holds the 64x28 frame
  buffer; the password screen's `$7200` is window row 4 (confirms the password module's
  DMA destination).
- `[static]` The window is full-screen: `WindowY=$1C` with `DOWN=0` puts the split at
  line 224, so every visible line (0-27) is a full-width window line and the
  `WindowX=0` split is unused (`[hardware]` VDP register semantics).
- `[static]` The sprite table and H-scroll table overlap at `$6000`; the 16-byte clear
  zeroes SAT entries 0-1 and H-scroll entries 0-3. With HSCR full-screen, only H-scroll
  entry 0 matters, so the overlap is functional for this clear.
- `[static]` The A/B plane fill writes `$700` longs (`$E00` words = 128x28 cells), not
  the full 128x32 plane; rows 28-31 remain untouched.
- `[static]` The initial tooltip is index 6 (`8*6`), text **"Press Start to race"**;
  `MessageBlinkTimer=30` is positive, so `Menu_ShowMessage` clears/hides it and
  `MainMenu_GameTick` reveals the text after 30 frames.
- `[static]` `Menu_Init` does not install an update function; `top_level` sets
  `MainMenu_GameTick` as the fade-in callback.
- `[static]` `MenuPassword_SelectCurrentTrack` picks the first track with no place, or
  the worst-placed finished track when all five have places.
- `[static]` Asset layouts: background 39 tiles/40x28 map `+$4E4/+$4E8`; race selection
  23 tiles/40x14 map `+$2E4/+$2E8`; password border 6 tiles; gamepad 90 tiles, header
  12x9 `+$B44` but only top 12x6 map `+$B48` used; player border 6 tiles/12x4 map
  `+$C8`; badges 108 tiles/12x12 map `+$D84/+$D88`; cards 311 tiles/12x30 map
  `+$2764/+$2768`, palette `+$26E4`; font 50 tiles.
- `[static]` The menu palette is copied from the race-cards blob (`+$26E4`, 128 bytes),
  not from the background; the copy must precede the font decompression.
- `[static]` The demo timer is 1800 frames (30 s); the menu exits on Start release.
- `[static]` Player mode 1=A, 2=B, 3=two players; C opens the password screen; A/B
  toggle player mode/music; directions change the current track by 2.
- `[static]` The race cards are written with a mask (`$7FF` default black), so only
  opaque pixels replace the background.
- `[static]` The five-card carousel is: current R at x=14, R+2 at x=21, R+4 at x=25,
  R+8 (R-2) at x=7, R+6 (R-4) at x=3, all mod 10.
- `[static]` `Menu_DrawRaceCard` draws place text in row 5, columns 4-7 and handles
  1-19; it subtracts `$680` from the font tile words so the masked writer's base
  restores them.

## Identifier audit

Full rows are in `docs/analysis/identifiers.md`; this is the file-local summary.

| Identifier | Kind | Observed use | Name quality | Rename verdict | Unknown ID |
|---|---|---|---|---|---|
| `Intro_ram_ImageBuffer` | RAM | generic decompression/staging buffer for every asset | narrow | rename-later | `-` |
| `Race_ram_ImageBuffer2` | RAM | menu-only badge/card nametable staging | misleading | rename-later | `-` |
| `Intro_InitPlayerA/B` | routine | also called by `Menu_Init` to reset profiles | narrow | rename-later | `-` |
| `Menu_PlayerPlacesPtr` | RAM | active player's five-place array | narrow (missing `_ram_`) | rename-later | `-` |
| `Menu_ram_StrPlayerName` | RAM | single scratch record reused for A and B | narrow | rename-later | `-` |
| `Menu_ram_CurrentlyDrawnRaceCard` | RAM | selected id, then carousel scratch | narrow | rename-later | `U-0003` |
| `unk_25EC0` | data | five track-record pointers | placeholder | rename-later | `-` |
| `word_4EEE` | data | "Name"/"Password" label record | placeholder | rename-later | `-` |
| `img_Gamepad` | asset | 12x9 header, only 12x6 rows used | narrow | keep | `U-0002` |

Everything else used in this file is rated `good`/`keep` (routines, RAM names, assets,
`dStringCodeTable`, `VdpCtrl`/`VdpData`).

## Hypotheses / open questions

- `[hypothesis]` `U-0001`: the value inserted by `Menu_BuildRaceTooltip` is the race
  distance in miles; the record text already says "miles" and the formula is static.
  The tables are labelled in `src/screens/message.asm` and
  `src/data/race_track_data.asm`. Next: compare level words with in-game values.
- `[hypothesis]` `U-0002`: the gamepad map header is 12x9 while every call site copies
  only 12x6; the lower 3 rows are probably unused padding. Next: inspect the full
  decompressed map and other readers.
- `[hypothesis]` `U-0003`: the `divu #10 / swap / andi #$FFFE` normalization in
  `Menu_DrawRaceSelection` is an identity even-mask for the documented ids; its origin
  is unclear. Next: audit writers and test an odd id.
- `[ ]` Confirm the exact race-card layout/stride and the five card positions visually.
- `[ ]` Confirm the demo path (30 s no input) in BlastEm.
- `[ ]` `Menu_dRaceNameTable`, `unk_25EC0` and `word_4EEE` are labelled data modules;
  per-entry semantics of the track records remain outside this pass.

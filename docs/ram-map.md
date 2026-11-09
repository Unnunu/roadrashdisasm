# Work RAM map (phase-aware)

Work RAM is 64 KiB at `$FF0000`–`$FFFFFF`. The game **reuses** the same bytes in
different phases (overlays), so a flat map is misleading: this document is organised by
subsystem and phase. Source of truth for addresses remains `ram_const.asm`; this file adds
meaning, size, invariants and overlap notes.

Status tags: `[static]` from code; `[dynamic]` observed; `[confirmed]` both;
`[hypothesis]` unverified; `TODO` unknown.

## Conventions

- Address format: `$FFxxxx` (24-bit). Some modules (e.g. `logoEA.asm`) use the equivalent
  32-bit sign-extended form `$FFFFxxxx`; keep it where the ROM encodes it literally.
- Fields named `Subsystem_ram_Field`; unknown bytes stay `ram_XXXXXX`.
- Record size and alignment when known (`; size $N` comments already appear in
  `ram_const.asm`).
- Overlay regions must say which phases share them and which module owns them at each
  time.

## Global / cross-module

| Address | Name | Size | Meaning | Evidence |
|---|---|---|---|---|
| `$FF1A62` | `ram_UpdateFunction` | 4 | Per-frame update pointer called from `VerticalInterrupt`. 0 = idle. | `[confirmed]` |
| `$FF305A` | `Global_ram_PalettePtr` | 4 | Pointer to the active palette. | `[static]` |
| `$FF305E` | `Global_ram_Palette` | `$80` | Active palette (64 words). | `[static]` |

## Boot / sound

- `[static]` Boot clears the whole 64 KiB work RAM, so every later structure is
  initialized by its own screen/module.
- Audio is deferred, but the sound code seen at `$19FAA` uses a control block starting at
  `$FFFF0000` and later loads the Z80 driver from `$1DA12` into `$A00000`.

## Fade (`fade.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF0300` | `Fade_ram_Timer` | 2 | Reload 3; palette step every 4th frame. |
| `$FF0302` | `Fade_ram_UpdateFunction` | 4 | Callback used by `FadeWithFunction_GameTick`. |
| `$FF0306` | `Fade_ram_CurrentPalette` | `$80` | Current palette (64 words). |
| `$FF0386` | `Fade_ram_TargetPalette` | `$80` | Target palette (64 words). |

## Intro (`intro.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF040A` | `Intro_ram_PlayerAPressedStart` | 2 | Player A pressed Start. |
| `$FF040C` | `Intro_ram_PlayerBPressedStart` | 2 | Player B pressed Start. |
| `$FF040E` | `Intro_ram_TextTimer` | 2 | Intro text timer; `>= 0` at the end of the intro leads to the menu. |
| `$FF0410` | `Intro_ram_CurrentStringOffset` | 2 | Current intro string offset. |
| `$FF439C` | `Intro_TitleScrollTable` | `$400 + $280` | Per-line H-scroll values (fg/bg) for the title/credits. |
| `$FF4A1C` | `Intro_TitleScrollSpeed` | `$400 + $280` | Per-line scroll speeds (fixed-point). |
| `$FF509C` | `Intro_ram_ImageBuffer` | TODO | Decompressed background/title/font staging buffer. |

## Menu / password / main menu / character / results / high score / shop / end level

These subsystems share a large block and phase-specific buffers. Fill in as each module
is analyzed:

- `Menu_ram_*` — `CurrentButtonsPtr`, `ChangedButtonsPtr`, `MoneyPlayerA/B`,
  `BikeIdPlayerA/B`, `Player`, `PlayerMode`, `NextMessageTimer`,
  `MessageBlinkTimer`, `CurrentMessageId`, `TempString`, `FrameBuffer`,
  `FrameBuffer2` (`$FFC4AC`, size `$E00`), `DemoMode`.
### Password menu (`menu_password.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF041A` | `MenuPassword_ram_StrPlayerNamePtr` | 4 | Pointer to the active name string. |
| `$FF041E` | `MenuPassword_ram_StrPlayerPasswordPtr` | 4 | Pointer to the active password string. |
| `$FF0422` | `MenuPassword_ram_CursorY` | 2 | Cursor row (9 name, 15/16 password). |
| `$FF0424` | `MenuPassword_ram_CursorX` | 2 | Cursor column. |
| `$FF0426` | `MenuPassword_ram_HoldTimer` | 2 | Hold-repeat delay (30 then 8). |
| `$FF0428` | `MenuPassword_ram_HeldButtons` | 2 | Held button for repeat. |
| `$FF042A` | `MenuPassword_ram_StrPlayerAPassword` | `$20` | Player A password string (header + 24 chars). |
| `$FF044A` | `MenuPassword_ram_StrPlayerBPassword` | `$20` | Player B password string. |
| `$FF04A4` | `MenuPassword_ram_StrPlayerAName` | `$12` | Player A name string (header + 10 chars). |
| `$FF04B6` | `MenuPassword_ram_StrPlayerBName` | `$12` | Player B name string. |
| `$FF05C6` | `MenuPassword_ram_CurrentButtons` | 2 | Buttons being processed. |
| `$FF067E` | `MenuPassword_StrPasswordStatus` | TODO | Password status message string. |

The player state used by the password system: `Menu_ram_Player` `$FF0508`, levels
`$FF050C/$FF050E`, money `$FF0518/$FF051C`, progress `$FF0510/$FF0514`, extra field `$FF0522/$FF0524` (0..3, current
`$FF0520`), places `$FF052E/$FF0538`, opponents `$FF0546/$FF0566`, bike ids
`$FF0542/$FF0544`.

### Main menu (`menu_main.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF3692` | `MainMenu_ram_DemoMode` | 2 | Demo/attract flag (set after 30 s idle). |
| `$FF3694` | `MainMenu_ram_FrameCounter` | 2 | Idle frame counter (1800 frames = 30 s). |
| `$FF05C8`/`$FF05CA` | `MainMenu_ram_ButtonsPlayerA` / `ChangedButtonsPlayerA` | 2 each | Pad A state/edge. |
| `$FF05CC`/`$FF05CE` | `MainMenu_ram_ButtonsPlayerB` / `ChangedButtonsPlayerB` | 2 each | Pad B state/edge. |
| `$FF05DE` | `MainMenu_ram_CurrentButtons` | 2 | Buttons being handled. |
| `$FF05DA` | `Menu_ram_PlayerMode` | 2 | 1 = A, 2 = B, 3 = two players. |
| `$FF0508` | `Menu_ram_Player` | 2 | 0 = A, `$FFFF` = B. |
| `$FF05DC` | `Menu_ram_CurrentTrackId` | 2 | 0,2,4,6,8 (five races). |
| `$FF05E4` | `Menu_ram_CurrentlyDrawnRaceCard` | 2 | Currently drawn race id. |
| `$FF05E0` | `Menu_PlayerPlacesPtr` | 4 | Pointer to the active player's places. |
| `$FF0756` | `Menu_ram_TempString` | TODO | Race-name/distance tooltip string. |
| `$FF046A` | `Menu_ram_StrPlayerName` | `8+50` | Player name + level string. |
| `$FFB62C` | `Menu_ram_FrameBuffer` | `$E00` | 64x28 window/text frame buffer (DMA to `$7000`). |
| `$FF8364` | `Race_ram_ImageBuffer2` | TODO | Race badge/card nametable staging. |

### Character intro (`character.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF0520` | `ram_FF0520` | 2 | Current player's "extra" field (0..3), copied from `$FF0522`/`$FF0524`. |
| `$FF0522`/`$FF0524` | `ram_FF0522/24` | 2 each | Player A/B 2-bit password "extra" field (not the bike id). |
| `$FF1ADA` | `Race_ram_ActiveController` | 2 | 0/1: controller that exited the intro (used by the race). |
| `$FF0508` | `Menu_ram_Player` | 2 | 0 = A, `$FFFF` = B. |
| `$FF050C`/`$FF050E` | `Menu_ram_PlayerALevel/PlayerBLevel` | 2 each | Table level index (1..5). |
| `$FF05DC` | `Menu_ram_CurrentTrackId` | 2 | 0,2,4,6,8 (five tracks). |
| `$FFB62C` | `Menu_ram_FrameBuffer` | `$E00` | 64x28 window buffer DMA'd to `$7000`. |

ROM: `unk_19A12` = `[5 levels][5 tracks][4 variants]` 8-byte records
(`quote_ptr,image_ptr`), index `base+variant+(level-1)*$A0+track*$10`. Image assets
carry an 8-byte interleaved `size/header` prefix; the header gives the name string,
image/nametable/palette offsets (see `docs/analysis/character.md`).

### Messages (`message.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF05D0` | `Menu_ram_NextMessageTimer` | 2 | Next tooltip delay. |
| `$FF05D2` | `Menu_ram_MessageBlinkTimer` | 2 | Tooltip text blink phase. |
| `$FF05D4` | `Menu_ram_CurrentMessageId` | 2 | Message array index (multiple of 8). |
| `$FF05E6` | `Message_ram_ButtonBlinkCounter` | 2 | Button icon blink counter. |
| `$FF05E8` | `Message_ram_ButtonBlinkPeriod` | 2 | Button icon blink period. |

The message field is rows 22-27 (40x6) of `Menu_ram_FrameBuffer`.
- `RaceResults_ram_*`, `HighScore_ram_*`, `Shop_ram_*`, `EndLevel_ram_*` — TODO.

## Race (`race.asm`, `race_hud.asm`, `road_marking.asm`, `animation.asm`)

Known so far:

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF1E68` | `ram_FF1E68` | 2 | Race progress/timer value compared with `$FF1E82`. |
| `$FF1E82` | `ram_FF1E82` | 2 | Best/last progress value. |
| `$FF1E96`, `$FF1E9A`, `$FF1E9E` | `ram_FF1E96/9A/9E` | 4? | Race progress snapshots. |
| `$FF1B3E` | `ram_FF1B3E` | 2 | Cleared at the start of the top-level flow. |
| `$FF3692` | `MainMenu_ram_DemoMode` | 2 | Demo/attract flag (named in `ram_const.asm`). |
| `$FF3696` | `Race_ram_State` | 2 | Race state / demo selector. |
| `$FF3698`, `$FF369A` | `ram_FF3698/9A` | 2 | Race/demo flags. |
| `$FF0910` | `ram_FF0910` | 4 | Next-screen selector for the results dispatcher. |
| `$FF0918` | `ram_FF0918` | 2 | Compared with 4 to select the end-level screen. |
| `$FF3048` | `Race_ram_FrameCounter` | 2 | Race frame counter. |
| `$FF0406` | `ram_FF0406` | 2 | HInt scroll-table offset; reaching `$90` triggers the engine-audio update. |
| `$FF369E` | `ram_FF369E` | 2 | `$FFFF` disables the HInt raster effect; 0 enables it. |
| `$FF05D6` | `ram_MusicEnabled` | 2 | Music-enabled flag used by the HInt audio block. |
| `$FF1AA2`/`$FF1AA4` | `ram_FF1AA2/A4` | 2 | Divisors for the engine-speed scaling (`divu`). |
| `$FF1EAA`/`$FF26AA` | `ram_FF1EAA/26AA` | `$80` | Player/bike-like structures (`struct of size $80`). |
| `$FF1908` | `ram_FF1908` | 4 | Object pointer passed to `sub_1652`. |
| `$FF36B6`/`$FF36B8` | `ram_FF36B6/B8` | 2 | Target/current smoothed engine value (rate-limited to ±`$64`). |
| `$FF36BE`/`$FF36C0` | `ram_FF36BE/C0` | 2 | Second object's target/current smoothed value. |
| `$FF36C4` | `ram_FF36C4` | 2 | Base value added to the speed computation. |

Rider/bike sprite builder (`sub_5760.asm`):

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF38AC` | `Race_ram_CurrentSpriteAttributeTable` | 4 | SAT base pointer. |
| `$FFDE64` | `Animation_ram_SpriteIndex` | 2 | Sprite chain index / next link. |
| `$FFDE60` | `Animation_ram_TileIndex` | 2 | Tile cursor. |
| `$FFD34A` | `Animation_ram_BaseTile` | 2 | Base tile added to entries. |
| `$FFDE5E` | `ram_FFDE5E` | 2 | Base priority/tile bits. |
| `$FFDE62` | `ram_FFDE62` | 2 | Chain-end flag (`$FFFF`). |
| `$FFDE66` | `ram_FFDE66` | 2 | Current entry X base. |
| `$FFDE68` | `ram_FFDE68` | 2 | Y offset/limit (`$8000` sentinel first). |
| `$FFDE6A` | `ram_FFDE6A` | 2 | Base link/limit (`$7C`). |
| `$FFDE6E` | `ram_FFDE6E` | 2 | Base X (`+$80`). |
| `$FFDE70` | `ram_FFDE70` | 2 | Base Y (`+$80`). |
| `$FF0906` | `ram_FF0906` | 2 | Strip X base. |
| `$FF0908` | `ram_FF0908` | 2 | Row/tile stride. |
| `$FF090A`/`$FF090C` | `ram_FF090A/C` | 2 each | Column/row counts. |
| `$FF090E` | `ram_FF090E` | 2 | Starting tile index. |
| `$FF1336` | `ram_FF1336` | 2 | Shadow/overlay X offset. |
| `$FF133A` | `ram_FF133A` | 2 | Shadow/overlay flag. |
| `$FF1366` | `ram_FF1366` | 2 | Second chain-end flag. |
| `$5944` | `unk_5944` | `$80` | Per-strip SAT table (16 records x 8 bytes). |

Race structures (player/bike state, sprite tables, road arrays, HUD buffers) are **TODO**.

## logoEA overlay (phase-specific)

`logoEA.asm` keeps its own map at `$FFFF0000`/`$FFFFC000`… It is an **overlay** used during
the EA-logo phase and physically overlaps later menu buffers (e.g. `TilesSquare $FFC0E4`
overlaps `Menu_ram_FrameBuffer2 $FFC4AC`). Values are written 32-bit because the ROM
encodes them literally (e.g. `movea.l #LogoEA_ram_Base` → `207C FFFF 0000`). Do not
normalize to `$FFxxxx`.

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FFFFC000` | `TextTimer` | 2 | Text animation timer (starts `$E2` = 226). |
| `$FFFFC002` | `FigureAnimationFrame` | 2 | Figure animation frame (`0..$18`). |
| `$FFFFC004` | `NextUpdateTimer` | 2 | Update every 3 frames; 180 (3 s) after a figure. |
| `$FFFFC006` | `LineValue` | 4 | Current 8-pixel line colour. |
| `$FFFFC00A` | `CurrentFigure` | 2 | 0 square, 1 circle, 2 triangle. |
| `$FFFFC00C`/`$C030` | `SquareYArray`/`SquareDataArray` | 36 each | 9 strips × 2 sprites. |
| `$FFFFC054`/`$C078` | `TriangleYArray`/`TriangleDataArray` | 36 each | Same. |
| `$FFFFC09C`/`$C0C0` | `CircleYArray`/`CircleDataArray` | 36 each | Same. |
| `$FFFFC0E4` | `TilesSquare` | `$900` | 72 runtime square tiles. |
| `$FFFFC9E4` | `TilesTriangle` | `$900` | 72 runtime triangle tiles. |
| `$FFFFD2E4` | `TilesCircle` | `$900` | 72 runtime circle tiles. |
| `$FFFFDBE4` | `ImageEAUncompressed` | `$C00` | Decompressed text/palette/nametable. |
| `$FFFFE7E4` | `UncompressTempBuffer` | `$1000` | LZ ring buffer (spaces). |

## Unknown area

`ram_const.asm` still contains many `ram_XXXXXX` placeholders. Rename them only after
`[confirmed]` evidence, in a dedicated rename task.

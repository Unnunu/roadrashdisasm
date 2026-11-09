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
| `$FF509C` | `Intro_ram_ImageBuffer` | TODO | Nametable/image staging buffer. |

## Menu / password / main menu / character / results / high score / shop / end level

These subsystems share a large block and phase-specific buffers. Fill in as each module
is analyzed:

- `Menu_ram_*` — `CurrentButtonsPtr`, `ChangedButtonsPtr`, `MoneyPlayerA/B`,
  `BikeIdPlayerA/B`, `Player`, `PlayerMode`, `NextMessageTimer`,
  `MessageBlinkTimer`, `CurrentMessageId`, `TempString`, `FrameBuffer`,
  `FrameBuffer2` (`$FFC4AC`, size `$E00`), `DemoMode`.
- `MenuPassword_ram_*` — name/password string pointers and buffers (`$FF041A`…).
- `MainMenu_ram_*` — buttons/changed buttons per player, `DemoMode`.
- `Character_ram_*`, `RaceResults_ram_*`, `HighScore_ram_*`, `Shop_ram_*`,
  `EndLevel_ram_*` — TODO.

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

Race structures (player/bike state, sprite tables, road arrays, HUD buffers) are **TODO**.

## logoEA overlay (phase-specific)

`logoEA.asm` keeps its own map at `$FFFF0000`/`$FFFFC000`… It is an **overlay** used during
the EA-logo phase and physically overlaps later menu buffers (e.g. `TilesSquare $FFC0E4`
overlaps `Menu_ram_FrameBuffer2 $FFC4AC`). Values are written 32-bit because the ROM
encodes them literally (e.g. `movea.l #LogoEA_ram_Base` → `207C FFFF 0000`). Do not
normalize to `$FFxxxx`.

## Unknown area

`ram_const.asm` still contains many `ram_XXXXXX` placeholders. Rename them only after
`[confirmed]` evidence, in a dedicated rename task.

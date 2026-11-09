# Work RAM map (phase-aware)

Work RAM is 64 KiB at `$FF0000`–`$FFFFFF`. The game **reuses** the same bytes in
different phases (overlays), so a flat map is misleading: this document is organised by
subsystem and phase. Source of truth for addresses remains `src/core/ram_const.asm`; this file adds
meaning, size, invariants and overlap notes.

Status tags: `[static]` from code; `[dynamic]` observed; `[confirmed]` both;
`[hypothesis]` unverified; `TODO` unknown.

## Conventions

- Address format: `$FFxxxx` (24-bit). Some modules (e.g. `src/logoEA/logoEA.asm`) use the equivalent
  32-bit sign-extended form `$FFFFxxxx`; keep it where the ROM encodes it literally.
- Fields named `Subsystem_ram_Field`; unknown bytes stay `ram_XXXXXX`.
- Record size and alignment when known (`; size $N` comments already appear in
  `src/core/ram_const.asm`).
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
The 68k audio control block starts at `$FFFF0000`; see
`docs/analysis/audio.md` for the full map and function meanings.

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF0000` | audio active byte | 1 | `$FF` when the sound engine is active/resumed. |
| `$FF0006 + n*$48` | audio channel n | `$48` | Six 68k sequence channels (`n=0..5`). |
| `$FF01B6` | current song id | 4 | Written by `Audio_StartMusic`. |
| `$FF01BE` | command buffer | `$30` | Six 8-byte commands copied to Z80 `$A00256`. |
| `$FF01EE` | special command | 5 | Copied to Z80 `$A000BB..BF` when `$FF01F3` is set. |
| `$FF01F4` | resume flag | 1 | `1` prevents `AudioFunc18` from re-arming audio. |
| `$FF0202` | command-ready | 1 | Command block processed/ready flag. |
| `$FF0204/$0208/$0209` | engine ch.1 | 1/1/1 | Parameter / start-stop / volume. |
| `$FF020A/$020E/$020F` | engine ch.2 | 1/1/1 | Parameter / start-stop / volume. |
| `$FF0210/$0214/$0215` | engine ch.3 | 1/1/1 | Parameter / start-stop / volume. |
| `$FF021B` | engine parameter | 1 | Set by `AudioFunc16` (distance-derived). |
| `$A000BB..BF` | Z80 mailbox | 5 | Special command bytes. |
| `$A00256` | Z80 command block | `$30` | Six channel commands. |
| `$A00286` | Z80 command flag | 1 | Written after the command block. |

## Fade (`src/core/fade.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF0300` | `Fade_ram_Timer` | 2 | Reload 3; palette step every 4th frame. |
| `$FF0302` | `Fade_ram_UpdateFunction` | 4 | Callback used by `FadeWithFunction_GameTick`. |
| `$FF0306` | `Fade_ram_CurrentPalette` | `$80` | Current palette (64 words). |
| `$FF0386` | `Fade_ram_TargetPalette` | `$80` | Target palette (64 words). |

## Intro (`src/screens/intro.asm`)

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
### Password menu (`src/screens/menu_password.asm`)

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

### Main menu (`src/screens/menu_main.asm`)

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

### Character intro (`src/screens/rider_intro.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF0520` | `ram_FF0520` | 2 | Current player's "extra" field (0..3), copied from `$FF0522`/`$FF0524`. |
| `$FF0522`/`$FF0524` | `ram_FF0522/24` | 2 each | Player A/B 2-bit password "extra" field (not the bike id). |
| `$FF1ADA` | `Race_ram_ActiveController` | 2 | 0/1: controller that exited the intro (used by the race). |
| `$FF0508` | `Menu_ram_Player` | 2 | 0 = A, `$FFFF` = B. |
| `$FF050C`/`$FF050E` | `Menu_ram_PlayerALevel/PlayerBLevel` | 2 each | Table level index (1..5). |
| `$FF05DC` | `Menu_ram_CurrentTrackId` | 2 | 0,2,4,6,8 (five tracks). |
| `$FFB62C` | `Menu_ram_FrameBuffer` | `$E00` | 64x28 window buffer DMA'd to `$7000`. |

ROM: `RiderIntro_RecordTable` = `[5 levels][5 tracks][4 variants]` 8-byte records
(`quote_ptr,image_ptr`), index `base+variant+(level-1)*$A0+track*$10`. Image assets
carry an 8-byte interleaved `size/header` prefix; the header gives the name string,
image/nametable/palette offsets (see `docs/analysis/rider_intro.md`).

### Actors/player and race state (`src/race/race.asm`)

The top-level `src/race/race.asm` analysis is in `docs/analysis/race.md`; the actor tables and
definitions are in `docs/analysis/race_actors.md`. Initial field inventory:

| Offset | Size | Field | Evidence |
|---|---|---|---|
| `+$02` | word | `PosZ` | 98C2/endlevel debug, main HInt |
| `+$04` | word | `PosXHigh` | `Race_Update`, 98C2 |
| `+$06` | word | `PosXLow` | 98C2 |
| `+$12` | word | `Speed` | `Race_Update` (`Race_UpdateSpeedDisplay`), main HInt |
| `+$16` | byte | `ActorType` | actor definition byte0 |
| `+$5C`/`+$5E`/`+$60` | word | actor graphics/sprite fields | `Race_ActorGraphicsTable` |
| `+$66` | word | `ActorRating` (definition byte5*100) | `Race_CreateActors` |
| `+$18` | word | `Gear` | 98C2/gear |
| `+$30` | word | `PosY` | 98C2, main HInt |
| `+$66` | word | `Unk66` (copied from `+$56`; divisor use) | `STRUCT_OFFSET_66` code uses |
| `+$68` | byte | flags: bit1 = B, bit2 = A, bit7 = timer stop | `Race_GetInput`, `Race_UpdateTime` |
| `+$73`/`+$74`/`+$75`/`+$77` | byte | actor definition bytes 3/1/2/4 | `Race_CreateActors` |
| `+$71` | byte | `Index` | `STRUCT_OFFSET_INDEX` |

Actor instances (`$80` each): `RacePlayerA`/`RacePlayerB` (`$FF1EAA`/`$FF26AA`),
15 opponents `$FF1F2A`..`$FF262A` (`Race_ActorList`), static actors
`$FF2EAA`/`$FF2F2A` (type `$10`); `$FF2FAA` is a further actor-like instance used by
`Race_UpdateStaticActors` (`$68` bit6), role TODO. `Road_ObjectArray` (`$FFD37C`) is the separate
0x14-byte road object array (`src/race/road_render.asm`).

Actor tables: `Race_ActorList` `$25856` (16 actor pointers + sentinel),
`Race_ActorListMid` `$2585E`, `Race_StaticActorList` `$2589A`,
`Race_ActorGraphicsTable` `$258EE`, `Race_ActorDefinitionTable` `$CCDA`
(76 x 16-byte definitions; 5 levels x15 + player def `$4B`), `Race_ActorLevelBase`
`$CCD0` (0,15,30,45,60). Actor screen groups: `ram_FF1A08`/`ram_FF1982`
(`Race_InitActorLists`/`Race_InitActorPositions`).

Top-level state: `Race_ram_State` (0 running, non-zero paused/loading),
`Race_ram_TimeTicks/Seconds/Minutes` (BCD timer), `Race_ram_FrameCounter/Delay`,
`Race_ram_ActiveController`/`CurrentButtons`, `Race_ram_GameEnded`/`DemoGameEnded`,
`Race_ram_Started` (race started), `ram_FF1B18` (finish timer), `ram_FF3698/369A/368E`
(pause/demo), `Race_ram_ProgressSnapshotA` (frame count), interpolation arrays
`ram_FF1E50/52/54/56/58/5A`, `Race_ram_PlayerXDifference` (player x difference).

Buffers: `Intro_TitleScrollTable`/`Intro_TitleScrollSpeed` (+$400 SAT),
`Menu_ram_FrameBuffer/2`, `Race_ram_FrameReady/2`, `Race_ram_SpriteSize1/2`,
`Intro_ram_ImageBuffer`/`Race_ram_ImageBuffer2`, VScroll info
`ram_FF3FDC/$411C/$425C` with `Race_ram_Alpha1/2/3`, HUD/SAT/HScroll DMA targets.

### Spawn/traffic (`src/race/race.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF1A0C` | `ram_FF1A0C` | - | Active actor list (`FFFFFFFF`-terminated). |
| `$FF1A06` | `ram_FF1A06` | 2 | Active actor count (spawn threshold `< 6`). |
| `$FF1982` | `ram_FF1982` | - | Opponent free list (7 initial; push/pop). |
| `$FF19C4` | `ram_FF19C4` | - | Traffic free list (push/pop; initial count TODO). |
| `$FF1E68` | `Race_ram_PlayerProgress` | 4 | Player progress for ahead/behind checks. |
| `$FF1E9C` | `Race_ram_ActorDistanceScale` | 2 | Actor-distance scale (`+$66 * scale >> 16`). |
| `$FF1EA6` | `Race_ram_SpawnTimer` | 2 | Spawn timer (0..511 frames). |
| `$FF1F2A` | `ram_FF1F2A` | - | First opponent actor (special cases). |
| `$FF1B20` | `Race_ram_Started` | 2 | Race started flag. |
| `$FF1B38` | `Race_ram_LevelIndex` | 2 | Current level/cop index used by the recycler. |
| `$FF1B34`/`$FF1B36` | `ram_FF1B34/36` | 2 each | Reset on the first-opponent level transition. |
| `$FF3046` | `Race_ram_SpeedDisplay` | 2 | Speed display (`Race_UpdateSpeedDisplay`). |

`Race_SpawnTick` spawns ahead opponents (`x+$200000`) or behind traffic
(`x-$100000`), with active/free lists and distance checks; `Race_UpdateSpeedDisplay`
+ `Race_FormatDecimal` produce `Race_ram_SpeedDisplay`. See `docs/analysis/race_spawn.md`.

### PRNG/audio/animation (`src/race/race_anim_audio.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF18BE` | PRNG state | 64 | 32-word sum PRNG table. |
| `$FF18FE`/`$FF1900` | PRNG indexes | 2 each | Two 0..31 indexes. |
| `byte_15FA8` | PRNG seed | 64 | Seed table for `Rand_Init`. |
| `$FF1AD7` | engine-audio flag | 1 | Set to `$0E` for an active engine. |
| `$FF1904`/`$FF1906`/`$FF1908` | target/collision state | 2-4 | Nearest-target/collision helpers. |
| `$FF1AA4`/`$FF1786` | nearest-target distances | 2/4 | Nearest actor speed/distance. |
| `unk_257E2`/`unk_257E8`/`unk_257EE` | engine timings | - | Engine/gear timing tables. |
| `unk_14056` | curve limit | - | `Race_GetCurveSpeedLimit` data. |
| `unk_1471A` | track params | - | `Race_LoadTrackParams` data. |
| `word_14742` | curve speed | 2 | `Race_UpdateBikeCurve` speed. |

Actor fields: `$3E/$40/$42` lean, `$4A/$5A` collision/range, `$5C` tile base,
`$68/$69/$6B/$6C/$6D/$6E` engine/collision/animation flags. `Rand_Init` seeds the
32-word sum PRNG; `Rand_GetWord` returns `state[i1]+state[i2]`. See
`docs/analysis/race_anim_audio.md`.

### Actors/AI (`src/race/race_ai.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF1A08` | actor list | - | Player/opponent actor pointers (AI loop). |
| `$FF1982` | static actor list | - | Static/police actor pointers. |
| `$FF2FAA` | actor-like instance | `$80`? | Further actor instance (role TODO). |
| `$FF1E68`/`$FF1E82`/`$FF1E9A` | race progress | 2-4 | Player/AI progress/checkpoint. |
| `$FF302E`/`$FF3032`/`$FF3034` | curve speeds | 2 each | Speed limits by direction/condition. |
| `word_14742` | curve speed | 2 | Curve/lean speed value. |
| `$FF1AA6`/`$FF1AAA`/`$FF1AB2`/`$FF1AB4` | bike physics | 2 each | Steering/speed scaling. |
| `Race_ram_FrameDelay`/`CurrentButtons` | frame/input | 2 each | AI/input timing. |

Actor fields used by the AI: `$12` Speed, `$14`, `$16` type, `$22`/`$26`
movement, `$30`/`$36/$38` Y/road, `$3E/$40/$42` lean, `$56`, `$68`/`$69` flags,
`$6E`, `$71` index, `$73`, `$75`, `$78`. AI data: `unk_258AE`, `unk_25A10`,
`unk_10E3E`, `unk_12B7C`, `unk_12D0A`, `unk_13A1A`; curve limit `unk_14056`.
See `docs/analysis/race_ai.md`.

### Road profile/objects (`src/race/race_ai_road.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `Road_ram_XLeftArray`/`XRightArray`/`MarkingXArray` | road arrays | - | Per-line left/right/marking X. |
| `RoadMarking_ram_XArray`/`WidthArray` | marking arrays | - | Marking X/width per line. |
| `ram_FF310A`/`31D2`/`329A`/`3236`/`3362`/`3A9C` | profile arrays | - | Curve/height/marking values + indexes. |
| `Race_ram_PlayerProgress` / `ram_FF1E6A` / `ram_FF1E6C` | progress state | 2 each | Player progress/curve. |
| `ram_FF1B50`/`1C50`/`1D50` | object lists | - | Sorted/visible object lists. |
| `ram_FFD77C` | curve accumulator | - | Track curve integration. |
| `unk_EB34` | road-edge data | - | Edge graphics for `Race_DrawRoadEdges`. |
| `Interp_dDivisorMap` | interpolator table | - | Divisor map for `FillLinearInterpArray`. |

`Road_FillProfileTables` builds the per-line HScroll/marking tables; `Race_IntegrateTrackCurve`
fills the profile arrays; `Road_BuildVisibleList` builds `ram_FF1D50`; `Race_WriteSpriteTiles`
stages sprite tiles. Standings: `Race_ComputeStandings`/`Race_ScaleResultValue`. See
`docs/analysis/race_ai_road.md`.

### Camera/HInt/rearview (`src/race/race_physics.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `Race_ram_VdpDmaControl` | `Race_ram_VdpDmaControl` | 2 | VDP DMA control word. |
| `Race_ram_HIntVScroll` | `Race_ram_HIntVScroll` | 4 | HInt vertical scroll accumulator. |
| `Race_ram_NearestBehindDistance` / `Race_ram_NearestAheadDistance` | `Race_ram_NearestBehindDistance`/`Race_ram_NearestAheadDistance` | 4 each | Nearest behind/ahead actor distances. |
| `ram_FF30EA`/`EE`/`F2`/`F6`/`FA`/`FE` | HInt HScroll layers | 4 each | Sky/road/ground scroll values. |
| `ram_FF3274` | `ram_FF3274` | 2 | Horizon/VScroll base. |
| `Race_ram_CameraOffset` | `Race_ram_CameraOffset` | 4 | Camera offset subtracted from the player X. |
| `ram_FF1E54`/`56`/`60`/`64`/`68`/`76`/`7A`/`7E`/`86` | camera/road state | 2/4 each | Camera position, progress, curve accumulators. |
| `Race_ram_NearestBehindIndex` / `Race_ram_NearestAheadIndex` | nearest actor indices | 2 each | Ahead/behind actor index (or `$FFFF`). |
| `Race_ram_NearestBehindSpeed` / `Race_ram_NearestAheadSpeed` | engine-audio values | 2 each | Nearest-opponent audio speeds. |
| `$FF1B40` | `Race_ram_PlayerPlace` | 2 | Player place/rank. |
| `Race_ram_RearviewTileRows` | `Race_ram_RearviewTileRows` | - | Road tile rows for the rearview mirror. |
| `ram_FF3238` | `ram_FF3238` | - | Road marking widths; `RoadMarking_ram_WidthArray`/`ram_FF3A9C` X. |

`Race_BuildVScrollInfo`/`Race_BuildHScrollTable` produce the per-frame
`Race_ram_CurrentVScrollInfo`/`CurrentHScrollTable` data for the HInt in `src/main.asm`;
`Race_DrawRearviewMirror`/`Race_DrawRoadMarkingHud` draw the mirror/marking in the HUD;
`Race_UpdateNearestOpponent` produces the nearest-opponent/engine-audio values.
See `docs/analysis/race_physics.md`.

### Race results (`src/screens/race_results.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF0526`/`$FF0528` | `ram_FF0526/28` | 2 each | Player A/B outcome (0 = incomplete, >4 = worse than 4th, 4 = level complete). |
| `$FF0910` | `RaceResults_ram_NextFunction` | 4 | Next-screen function pointer (RaceResults/HighScore/Shop). |
| `$FF0914` | `RaceResults_ram_DrawRoutine` | 4 | Active draw routine pointer (set, not read). |
| `$FF0918` | `RaceResults_ram_Outcome` | 2 | Copied outcome; `4` selects the end-level screen. |
| `$FF091A` | `RaceResults_ram_Amount` | 2 | Fine/repair amount formatted into the bust/repair message. |
| `$FF04C8` | `Race_EventBuffer` | `$40` | 16-long race event/sort buffer; first word `$FFFF` = busted/destroyed. |
| `$FF1B1A` | `Race_CopIndex` | 2 | Cop/officer index (1..5); 0 = bike destroyed. |
| `$FF1414`/`FF1418`/`FF141A` | `ram_FF1414/18/1A` | - | Standings string header/text, height, width. |

ROM tables: `$19D32` (level, money>=0, 5x4), `$19DD2` (level, money<0, 5x2),
`$19E22` (cop, money>=0, 5x4), `$19EC2` (cop, money<0, 5x2), 8-byte
`quote_ptr,image_ptr` records. Track images: `$7E670` pointers, `$7E684` image
offsets, `$7E68E` nametable offsets, `$7E698` palette offsets.
See `docs/analysis/race_results.md`.

### High score (`src/screens/highscore.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF05EA` | `HighScore_ram_Table` | 8+140 | Header `(22,16,7,20)` + 7 x 20-char entries. |
| `$FF05F2` | table text | 140 | First entry; built by `src/screens/intro.asm`, sorted by `Race_UpdateHighScoreTable`. |
| `$FF052A`/`$FF052C` | `HighScore_ram_PlayerATableOffset/B` | 2 each | Player row offsets (20*5 / 20*6 initially). |
| `$FF094E` | `HighScore_ram_CurrentButtons` | 2 | Buttons handled by A/B/C. |
| `$FF3692` | `MainMenu_ram_DemoMode` | 2 | Cleared on a demo release -> menu; 1 -> demo race. |

The screen draws entries 0..4 (table font `$800`) and the player rows at the offsets
(regular font `$0`). Assets: title `$A2F5C`, badge `$7EB72`, fonts `$A2BAA`->`$800`,
`$A2E68`->`$1000`. See `docs/analysis/highscore.md`.

### Bike shop (`src/screens/shop.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF0950` | `Shop_CurrentBikeId` | 2 | Selected bike id (0..7). |
| `$FF0952` | `Shop_ram_CurrentButtons` | 2 | Current buttons being handled. |
| `$FF0954` | `Shop_ScrollPos` | 2 | H-scroll position (centre `$160`). |
| `$FF0956` | `Shop_ImageBike1` | `$144` | 18x9 bike map. |
| `$FF0A9A` | `Shop_ImageBike2` | `$144` | 18x9 bike map. |
| `$FF0BDE` | `Shop_ImageBike3` | `$144` | 18x9 bike map. |
| `$FF06EA` | `Shop_StrBuyNewBike` | TODO | "Press C to buy ..." + bike name. |
| `$FF089A`/`$FF07C2`/`$FF082E` | dynamic messages | TODO | Owned/can't-afford and left/right bike names. |

ROM: `Shop_BikeDescriptions` `$81D2`, `Shop_dPrices` `$8312`, `Shop_BikeImageTable`
`$8322`, `Shop_BikePalettes` `$7E370` (8 x 32 bytes). Purchase: credits = money +
current price/2; money -= price - current/2; regenerate the password. See
`docs/analysis/shop.md`.

### HUD digits/debug (`src/race/race_hud_debug.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF1AE0` | `RaceHud_ram_StandingsPtr` | - | Standings pointer list. |
| `$FF1AE4` | `RaceHud_ram_StandingsValue` | 2 | Standings value/timer (2 digits at `$1602`). |
| `$FF1AE6` | `RaceHud_ram_StandingsIndex` | 2 | Current standings index (palette 0 row). |
| `$FF1EAA` | player struct | `$80` | Debug readouts of `POSZ`, `POSX_HIGH/LOW`, `POSY`, `GEAR`, `+$68`. |

Digit HUD: `d1` packed row/column -> offset `row*128+column*2`; tile `$5C0+digit`, bit15
priority, `d2` palette/priority. Buffers `Race_ram_CurrentHudBuffer`/`NextHudBuffer`.
`Race_FormatDecimal` (`src/race/race.asm`) formats distance/POSZ values. No direct callers; likely debug/
alternate HUD. See `docs/analysis/race_hud_debug.md`.

### Race HUD (`src/race/race_hud.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF38C8` | `Race_ram_CurrentHudBuffer` | 4 | HUD nametable buffer. |
| `$FF38CC` | `Race_ram_NextHudBuffer` | 4 | Next HUD buffer/DMA source. |
| `$FF1EA4`/`$FF1EA5` | `Race_ram_TimeMinutes/TimeSeconds` | 1 each | BCD time. |
| `$FF1B26` | `Race_ram_BikeDamage` | 2 | Bike damage (HP bar = `$20-damage`). |
| `$FF1B40` | `Race_ram_PlayerPlace` | 2 | Player place. |
| `$FF14B8`/`$FF14BA`/`$FF14BC` | name/place state | 2 each | Timer / last place / rank. |
| `$FF14BE` | `RaceHud_ram_TextDescriptor` | - | Text descriptor for `WriteNametableToBuffer`. |
| `$FF352C` | odometer font | - | 4x2 digit tiles (8 longs each). |
| `$FF1A70` | gear curve | - | RPM-arrow divisor source. |
| `$FF1AA2` | RPM divisor | 2 | `speed/divisor/682`. |
| `$D58E` | `RaceHud_dRankStrings` | 64 | `" 1st"`..`"16th"`, 4 bytes each. |
| `$7DEAA` | `unk_7DEAA` | - | Speed/RPM needle animation script (gap). |

`RaceHud_Draw` -> time/place/stamina/HP/names/speed/RPM/odometer. HUD entry offset is
`2*(y*64+x)`; tile entries set bit 15 + palette. See `docs/analysis/race_hud.md`.

### Road marking (`src/race/road_marking.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF14E8` | `RoadMarking_ram_XArray` | `$98*2` | X_left per road line. |
| `$FF1618` | `RoadMarking_ram_WidthArray` | `$98*2` | Width per line (0 = done). |
| `$FF1748`..`$FF1756` | `RoadMarking_ram_X1..X4`, `Width1..4` | 2 each | Band min-X/width. |
| `$FF1758` | `RoadMarking_SpriteHorizontalSize` | 2 | Tiles wide. |
| `$FF175A` | `RoadMarking_SpriteVerticalSize` | 2 | 1 or 2 tiles high. |
| `$FF175C` | `RoadMarking_SpritePosX` | 2 | Sprite left edge. |
| `$FF175E` | `RoadMarking_ColumnSizeBytes` | 2 | Column stride. |
| `$FF1760` | `RoadMarking_TileOffset` | 2 | Tile byte offset. |
| `$E732` | `RoadMarking_dPatterns` | 44 | Width -> 32-bit pixel mask. |

`RoadMarking_Draw` groups up to four 8-line bands into one sprite, fills tiles from the
X/width arrays, and stops at `Animation_ram_SpriteIndex >= 80`. See
`docs/analysis/road_marking.md`.

### Animation (`src/race/animation.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF190C`/`$FF190E` | `Animation_ram_PosX/PosY` | 2 each | Base sprite position. |
| `$FFDE60` | `Animation_ram_TileIndex` | 2 | Tile cursor. |
| `$FFDE64` | `Animation_ram_SpriteIndex` | 2 | SAT chain index. |
| `$FFD34A` | `Animation_ram_BaseTile` | 2 | Base tile added to entries. |
| `$169A0` | `Animation_dTileCountMinus1` | 16 | `(VS+1)*(HS+1)-1` by size code. |

Script: `{tilemap, frame_count, frame_ptrs[]}`; frame: `count`, then
`(dy,size,palette/flip/tile,dx)` per sprite. `UpdateAnimation` copies tiles;
`UpdateAnimation2` assumes them in VRAM. See `docs/analysis/animation.md`.

### Road/object renderer (`src/race/road_render.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF1D50` | `Road_VisibleObjectList` | - | Visible-object index list (`$FFFF`-terminated). |
| `$FFD37C` | `Road_ObjectArray` | 0x14/entry | Object array: x,y,scale,horizon,shape,flags,x offset,second shape. |
| `$FF0D26`/`$FF0D2A`/`$FF0D2E`/`$FF102E` | road buffers | - | Tile cursor, strip data, left/right strip offsets. |
| `$FF132E`/`$FF1330`/`$FF1332`/`$FF1336` | road strip state | 2 each | Strip counts/height/x offset. |
| `$FF133A`/`$FF133C`/`$FF133E` | object flags | 2 each | Shadow, mirror, priority bits. |
| `$FF1340`/`$FF1342`/`$FF1344` | projection | 2 each | Acceleration, base x/y. |
| `$FF1348`/`$FF134C` | shape pointers | 4 each | Current/second shape data. |
| `$FF1350` | scale | 4 | Object scale (`record+4 << 2`). |
| `$FF1354`/`$FF1356`/`$FF1358` | special road | 2 each | Elevated/overpass offset. |
| `$FF135A`..`$FF1364` | shape state | 2 each | Second-shape/saved animation indices. |
| `$FF1366` | chain end | 2 | Sprite-chain overflow flag. |
| `$FF136A` | horizon | 2 | Road horizon/limit. |

SAT is double-buffered: `$FF479C`/`$FF4E1C`. Shape table `Road_ShapeTable` (`$3BF1A`,
564 entries) and shape data `$3C7EC-$7DCA7` are in `src/data/road_shapes.asm`. See `docs/analysis/road_render.md`; the exact projection math is TODO.

### End level (`src/screens/endlevel.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `-` | `EndLevel_ram_AnimFrame` | 2 | Victory animation frame; `-1` ends the animation stage. |
| `$FF0D24` | `EndLevel_ram_SpriteSwapDelay` | 2 | 5-frame sprite-table swap delay. |

The module reuses the race animation state (`Animation_ram_BaseTile=$2E0`,
`Race_ram_FrameReady/FrameReady2`, `Race_ram_*SpriteAttributeTable`,
`Race_ram_*ScrollTable`, `Race_ram_SpriteDestination=$8680`) with `Intro_TitleScrollTable`
buffers. Level-up rider table `$19F12` (5 levels x 2), frame counts `$8C8C`,
animation script `$8DC2`, tiles `$80000`, window image `$7F400`. `EndLevel_AdvanceLevel` advances the
level/opponents/password. See `docs/analysis/endlevel.md`.

### Track data decoder (`src/race/track_data.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF13B2` | `Uncompress_ram_Budget` | 2 | Remaining per-call sample budget. |
| `$FF13B8`..`$FF13E2` | channel 1 state | - | Accumulator, data byte, delta, control index, sign/width/run, bit position, pointers, caught-up flag. |
| `$FF13E4`..`$FF140E` | channel 2 state | - | Same for the second channel/output. |
| `$FFDC58` | `Track_CurveBuffer` | 0x200 | Decoded/scaled track data (4 x $80-byte chunks). |
| `$FF1A52`/`$FF1A56` | `RaceTrack_Data2/3` | 4 each | Compressed track streams. |
| `$FF1A6C` | `Race_ram_TrackScaleTable` | 4 | Per-track scaling table pointer. |

ROM: `off_16AB0` (src/race/race.asm) -> per-track tables; tables `$A054/$A08C/$A094/$A0CC`
(bit masks/shifts). Race callers scale channel 1 by `signed byte * factor / $10000`
(128 samples at level start, 64-sample chunks afterwards). See `docs/analysis/track_data.md`.

### Decompressor (`src/core/uncompress.asm`)

The LZSS ring is `Road_ram_XLeftArray` (0x1000 bytes, prefilled `$20`). Streaming
decoder state (`UncompressStreamStart`/`UncompressStreamContinue`):

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF136C`..`$FF1384` | `Uncompress_State` a-regs | 4 each | a0 (ring), a1 (output), a2 (ring ptr), a3 (source), a4-a6. |
| `$FF1388`..`$FF13A4` | `Uncompress_State` d-regs | 4 each | d0-d7 (d2 remaining, d3 bit count, d5 run, d6 flags, d7 ring index). |
| `$FF13A8` | mid-match flag | 2 | `$FFFF` while resuming inside a back-reference. |
| `$FF13AA` | VRAM assembly | 4 | `UncompressToVRAM` 4-byte buffer. |

`WriteToVRAM` (`src/race/race.asm`) takes the decompressed tile count from the first long's low
word (high word `$0808` marker). See `docs/analysis/uncompress.md`.

### Messages (`src/screens/message.asm`)

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF05D0` | `Menu_ram_NextMessageTimer` | 2 | Next tooltip delay. |
| `$FF05D2` | `Menu_ram_MessageBlinkTimer` | 2 | Tooltip text blink phase. |
| `$FF05D4` | `Menu_ram_CurrentMessageId` | 2 | Message array index (multiple of 8). |
| `$FF05E6` | `Message_ram_ButtonBlinkCounter` | 2 | Button icon blink counter. |
| `$FF05E8` | `Message_ram_ButtonBlinkPeriod` | 2 | Button icon blink period. |

The message field is rows 22-27 (40x6) of `Menu_ram_FrameBuffer`.
- `RaceResults_ram_*`, `HighScore_ram_*`, `Shop_ram_*`, `EndLevel_ram_*` — TODO.

## Race (`src/race/race.asm`, `src/race/race_hud.asm`, `src/race/road_marking.asm`, `src/race/animation.asm`)

Known so far:

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FF1E68` | `Race_ram_PlayerProgress` | 2 | Race progress/timer compared with `Race_ram_BestProgress`. |
| `$FF1E82` | `Race_ram_BestProgress` | 2 | Best/last progress value. |
| `$FF1E96`, `$FF1E9A`, `$FF1E9E` | `Race_ram_ProgressSnapshotA/B/C` | 4? | Race progress snapshots. |
| `$FF1B3E` | `ram_FF1B3E` | 2 | Cleared at the start of the top-level flow. |
| `$FF3692` | `MainMenu_ram_DemoMode` | 2 | Demo/attract flag (named in `src/core/ram_const.asm`). |
| `$FF3696` | `Race_ram_State` | 2 | Race state / demo selector. |
| `$FF3698`, `$FF369A` | `ram_FF3698/9A` | 2 | Race/demo flags. |
| `$FF0910` | `RaceResults_ram_NextFunction` | 4 | Next-screen selector for the results dispatcher. |
| `$FF0918` | `RaceResults_ram_Outcome` | 2 | Compared with 4 to select the end-level screen. |
| `$FF3048` | `Race_ram_FrameCounter` | 2 | Race frame counter. |
| `$FF0406` | `Race_ram_HIntScrollOffset` | 2 | HInt scroll-table offset; reaching `$90` triggers the engine-audio update. |
| `$FF369E` | `Race_ram_HIntRasterDisabled` | 2 | `$FFFF` disables the HInt raster effect; 0 enables it. |
| `$FF05D6` | `ram_MusicEnabled` | 2 | Music-enabled flag used by the HInt audio block. |
| `$FF1AA2`/`$FF1AA4` | `Race_ram_PlayerRpmDivisor`/`Race_ram_NearestRpmDivisor` | 2 | Divisors for the engine-speed scaling (`divu`). |
| `$FF1EAA`/`$FF26AA` | `RacePlayerA/26AA` | `$80` | Player A/B (`RacePlayer` candidate; see below). |
| `$FF1908` | `Race_ram_NearestActor` | 4 | Object pointer passed to `Audio_UpdateEngine`. |
| `$FF36B6`/`$FF36B8` | `Race_ram_Engine1Target`/`Race_ram_Engine1Current` | 2 | Target/current smoothed engine value (rate-limited to ±`$64`). |
| `$FF36BE`/`$FF36C0` | `Race_ram_Engine3Target`/`Race_ram_Engine3Current` | 2 | Second object's target/current smoothed value. |
| `$FF36C4` | `Race_ram_EngineSpeedBase` | 2 | Base value added to the speed computation. |

Rider/bike sprite builder (`src/screens/rider_sprites.asm`):

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
| `$5944` | `RiderSprites_StripTable` | `$80` | Per-strip SAT table (16 records x 8 bytes). |

Race structures (player/bike state, sprite tables, road arrays, HUD buffers) are **TODO**.

## logoEA overlay (phase-specific)

`src/logoEA/logoEA.asm` keeps its own map at `$FFFF0000`/`$FFFFC000`… It is an **overlay** used during
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

`src/core/ram_const.asm` still contains many `ram_XXXXXX` placeholders. Rename them only after
`[confirmed]` evidence, in a dedicated rename task.

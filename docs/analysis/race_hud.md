# Analysis: `src/race/race_hud.asm` (race HUD)

- **Module:** speed/RPM needles, odometer, place, time, stamina, bike HP, player
  name/place, opponent name, HUD digits/symbols
- **ROM range:** `0x00D278`–`0x00D8F9`
- **Status:** analyzed (static L7 contract + Experiment E7-A dynamic snapshot; needle
  script/odometer font decoded)
- **Source:** `src/race/race_hud.asm`
- **Related:** `docs/analysis/race.md`, `docs/analysis/animation.md`,
  `docs/modules/race_hud.md`, `docs/ram-map.md`, `docs/analysis/race_map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `RaceHud_Draw` | `0xD278` | Calls the HUD draw chain. |
| `RaceHud_DrawSpeedArrow` | `0xD29E` | Speed needle: `speed/453`, clamped to frame 31. |
| `RaceHud_DrawRPMArrow` | `0xD2DC` | RPM needle from the gear curve + `speed/divisor/682`. |
| `RaceHud_DrawOdometer` | `0xD334` | Distance odometer from `POSX_HIGH/330`. |
| `RaceHud_DrawPlace` | `0xD3F6` | Place number at `y=24,x=27`. |
| `RaceHud_DrawTime` | `0xD410` | Minutes + `:` + seconds at `y=26`. |
| `RaceHud_DrawStamina` | `0xD458` | Opponent + player stamina bars. |
| `Race_DrawBikeHPBar` | `0xD534` | Bike HP bar from `Race_ram_BikeDamage`. |
| `Race_DrawPlayerNameOrPlace` | `0xD5CE` | Timed name / "Nth PLACE" text. |
| `Race_DrawOpponentName` | `0xD73A` | Nearest opponent / finish rider name. |
| `RaceHud_DrawSymbol` | `0xD830` | One HUD tile entry. |
| `RaceHud_DrawNumber2Digits` | `0xD850` | Two BCD digits (`$1F4+digit`). |
| `RaceHud_DrawNumber4Digits` | `0xD890` | Four BCD digits (`$1F4+digit`). |

## L7 contract

`Race_Update` clears `Animation_ram_SpriteIndex/TileIndex`, calls `RaceHud_Draw`, and
the whole chain writes into `Race_ram_CurrentHudBuffer`; the two needles also append
SAT entries/tiles through `UpdateAnimation`. `Race_GameTick` then DMAs the window
buffer (`$3000`, 29 lines) and the SAT/HScroll to VRAM. HUD cells are 16-bit words in
the 64-word frame buffer:

```text
offset = 2 * (y * 64 + x)
word   = $8000 | (palette << 13) | tile      ; tile = $1F4 + digit for the digit writers
```

- **Time** (`RaceHud_DrawTime`): `Race_ram_TimeMinutes:TimeSeconds` are **BCD** bytes
  maintained by `Race_UpdateTime` (60 ticks per second; frozen once player `$68` bit7
  is set). Drawn at `y=26`: minutes `x=24`, `:` tile `$1FE` at `x=26`, seconds at
  `x=27`.
- **Place** (`RaceHud_DrawPlace`): `Race_ram_PlayerPlace` at `x=27,y=24`. The value is
  a 2-digit packed decimal: 1..9 stay as-is, 10..16 are stored as `$10..$16`
  (`Race_UpdateNearestOpponent`: `place -= 10; place |= $10`). `DrawNumber2Digits`
  shows the high nibble as the first digit, so `$15` is "15".
- **Stamina** (`RaceHud_DrawStamina`): player `$5C` at `+$984` (`x=2,y=19`), nearest
  actor `$5C` at `+$9B8` (`x=28,y=19`). `count = min($5C>>5, $50)`, 8 units per bar
  cell (up to 10 cells); colour by remaining count: `>=30` green `$E5FF`,
  `>=15` yellow `$A427`, else red `$842F`. Empty cells are `$8430`.
- **Bike HP** (`Race_DrawBikeHPBar`): `count = max(0, $20 - Race_ram_BikeDamage)` at
  `+$99C` (`x=14,y=19`), same 8-unit cells and colour thresholds `>=16`/`>=8`.
- **Needles**: both use `RaceHud_NeedleScript` (`0x7DEAA`) with `UpdateAnimation`.
  Speed frame = `min(speed/453, 31)` at `(x=$88,y=$80)`. RPM:
  `divisor = (RaceBike_ram_Parameters[gear].word << 2) & $FFFF` (stored in
  `Race_ram_PlayerRpmDivisor`); `q = (speed<<16)/divisor`; frame = `q/682` (only
  when `q != 0`); position `(x=$C4,y=$6C)`.
- **Odometer** (`RaceHud_DrawOdometer`): uses `RacePlayerA+POSX_HIGH` (distance in
  16-foot units). The top three digits come from `POSX_HIGH/330` (miles) and are
  written from `RaceHud_ram_OdometerFont` into `+$E00`; the font is loaded by
  `Race_LoadHUD` from the decompressed HUD image, header long = number of digit
  tiles, each tile 32 bytes (8 longs).
- **Name/place** (`Race_DrawPlayerNameOrPlace`): text descriptor at `x=20,y=2`, width 10.
  `RaceHud_ram_NameTimer` (`$FF14B8`) is capped at `$30`; while negative the player
  name is drawn and the timer is decremented, while non-negative the "Nth PLACE"
  text (`RaceHud_dRankStrings`, `NameFlags` bit1) or blank is drawn. On a place
  change `LastPlace` updates; if the timer is negative the rank is recomputed as
  `place-1` (minus 6 for the `$1x` two-digit values), and if the timer is below
  `$18` it is bumped by `$18`. A place change while the timer is still positive
  therefore only restarts the timer; `Rank` updates on the next negative phase.
- **Opponent name** (`Race_DrawOpponentName`): nearest actor `$71` -> player
  opponent list -> actor id -> `Race_ActorDefinitionTable+6` (16-byte records).
  The reserved opponent (`ram_FF1F2A`) and the finish case use
  `Race_ram_LevelIndex`/`Race_ActorLevelBase`; no opponent draws blanks.
- `RaceHud_DrawSymbol`/`Number2Digits`/`Number4Digits` compute the cell offset as
  `2*(y*64+x)` and set bit15 + palette + `$1F4+digit`.

## Needle script (`RaceHud_NeedleScript`)

`src/data/race_misc_data.asm`: tilemap base `$7E070`, last frame index `$1F`, then 32
frame pointers `$7DF30 + 10*i`. Each frame is 10 bytes with **one sprite**:

```text
loop_count (0 = one sprite; passed to dbf)
dy (signed), size, palette<<11 | tile, dx (signed)
```

Decoded table: `dy` 180..196, `dx` 99..115, tile cycles through
`$000/$004/$008/$00C/$00E/$010/$012/$014/$016`, palette cycles 1 -> 0 -> 2 -> 3 -> 1.
The needle is a single rotating sprite: frame 0 is `dy=196, dx=112, tile=$12,
palette 1`; frame 30 is `dy=192, dx=115, tile=$16, palette 1`.

## Dynamic E7-A (`analysis/capture_L7_hud.gdb`, `analysis/notes/L7_hud_trace.txt`)

- Early frames (pre-start): `place=0`, `time=00:00`, `NearestActor=$FFFFFFFF`,
  player stamina `$0A00`, cells `$E5FF/$E5FF/$8430` (green/empty).
- Race frames: place `$15` (15th), time BCD `00:0N`, `NearestActor=$FF232A`, player
  stamina `$0500`, HP cell `$8430`; the name timer/rank pair changed as the place
  changed (`nt=$2A, lp=$15, rk=$0E, nf=$2A`).
- Forced place changes (bumped at `RaceHud_Draw` entry) produced
  `lp=3, rk=$0E, nf=$2E, nt=$2E` and `lp=5, nf=$1A` while the natural place returned
  to `$15`; this is the "rank lags until the name phase" behaviour above.

## Data / RAM

- `RaceHud_dRankStrings` (`0xD58E`): `" 1st"`..`"16th"` (4 bytes each).
- `RaceHud_NeedleScript` + `RaceHud_NeedleData` (`$7DEAA`, `$7DF30`): 32 one-sprite
  frames; tilemap `$7E070`.
- `RaceBike_ram_Parameters`: gear curve (RPM divisor source);
  `Race_ram_PlayerRpmDivisor`: stored RPM divisor.
- `RaceHud_ram_OdometerFont`: odometer digit tile font (one 32-byte tile/digit).
- `Race_ram_PlayerPlace`; `Race_ram_NearestActor`; `Race_ram_BikeDamage $FF1B26`.
- `RaceHud_ram_NameTimer/LastPlace/Rank/NameFlags/TextDescriptor`;
  `Race_ram_CurrentHudBuffer $FF38C8`; `CurrentSpriteAttributeTable $FF38AC`;
  `CurrentSpriteTileArray $FF38D0`.

## Open questions

- `RaceBike_ram_Parameters` gear-curve values and the resulting RPM frame scaling.
- Odometer-font pixel art (tile contents) and the exact HUD palette entries.
- `RaceHud_DrawNumber4Digits` has no caller in the disassembled race path (used by
  the debug helpers only).
- Visual confirmation of needle rotation/cadence remains optional.

## Applied renames

- R16: `RaceHud_NeedleScript` (speed/RPM script), `RaceHud_ram_OdometerFont`.
- `unk_D58E` -> `RaceHud_dRankStrings`.

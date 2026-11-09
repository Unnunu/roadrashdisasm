# Analysis: `race_hud.asm` (race HUD)

- **Module:** speed/RPM needles, odometer, place, time, stamina, bike HP, player
  name/place, opponent name, HUD digits/symbols
- **ROM range:** `0x00D278`–`0x00D8F9`
- **Status:** analyzed (partial; data tables/dynamic TODO)
- **Source:** `race_hud.asm`
- **Related:** `docs/analysis/race.md`, `docs/analysis/animation.md`,
  `docs/modules/race_hud.md`, `docs/ram-map.md`

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

## Flow

`RaceHud_Draw` -> Time, Place, Stamina, BikeHP, PlayerNameOrPlace, OpponentName,
SpeedArrow, RPMArrow, Odometer. All write `Race_ram_CurrentHudBuffer` (or the sprite
table/tile array for the two needles via `UpdateAnimation`).

- Needles use `unk_7DEAA` (animation script at `0x7DEAA`, gap) with
  `UpdateAnimation`; speed `d0 = min(speed/453,31)` at `X=$88,Y=$80`; RPM divisor comes
  from the gear curve `ram_FF1A70[gear]` (`ram_FF1AA2`), frame = `(speed/divisor)/682`.
- Odometer reads `RacePlayerA+POSX_HIGH`, divides by 330 and draws three digits from
  the `ram_FF352C` font into `CurrentHudBuffer+$E00`.
- Stamina: opponent (`ram_FF1908` `$5C/5`) at `+$9B8` (`y=19,x=28`), player
  (`RacePlayerA+$5C/5`) at `+$984` (`y=19,x=2`); colors `$E5FF`/`$A427`/`$842F`.
- Bike HP: `$20 - Race_ram_BikeDamage` clamped, at `+$99C` (`y=19,x=14`).
- Place/time use `RaceHud_DrawNumber2Digits`; the `:` uses tile `$1FE`.
- Name/place: `ram_FF14B8` timer, `ram_FF14BA` last place, `ram_FF14BC` rank; copies
  `MenuPassword_ram_StrPlayerA/BName+8` or builds `"Nth PLACE"` from
  `RaceHud_dRankStrings`; `ram_FF14BE` is the text descriptor passed to
  `EncodeString`/`WriteNametableToBuffer`.
- Opponent name: `Menu_ram_PlayerA/B_Opponents` maps `$71` actor index -> actor id ->
  `Race_ActorDefinitionTable+6` name (16-byte records); finish rider from
  `ram_FF1B38`/`Race_ActorLevelBase`; draws via the same text descriptor.
- `RaceHud_DrawSymbol`/`Number2/4Digits` compute the buffer offset as
  `2*(y*64+x)` and set bit 15 (priority) + palette + tile.

## Data / RAM

- `RaceHud_dRankStrings` (`0xD58E`): `" 1st"`..`"16th"` (4 bytes each).
- `unk_7DEAA`: speed/RPM needle animation script (now `race_misc_data.asm`), frames/tilemap
  still TODO.
- `ram_FF1A70`: gear curve (divisor source); `ram_FF1AA2`: RPM divisor.
- `ram_FF352C`: odometer digit font (8 longs/digit).
- `ram_FF1B40`: place; `ram_FF1908`: nearest actor; `Race_ram_BikeDamage $FF1B26`.
- `ram_FF14B8/BA/BC`: name timer / last place / rank; `ram_FF14BE`: text descriptor.
- `Race_ram_CurrentHudBuffer $FF38C8`; `CurrentSpriteAttributeTable $FF38AC`;
  `CurrentSpriteTileArray $FF38D0`.

## Open questions

- `unk_7DEAA` script layout and the `ram_FF1A70` gear curve.
- `ram_FF352C` font layout and the exact HUD palette/colors.
- `RaceHud_DrawNumber4Digits` callers (possibly unused in race).
- Dynamic verification of the name/place timer and bar colors.

## Rename proposals

Applied: `unk_D58E` -> `RaceHud_dRankStrings`. Remaining data/fields are TODO.

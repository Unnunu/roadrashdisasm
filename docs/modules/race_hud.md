# Module card: `src/race/race_hud.asm`

- **ROM range:** `0x00D278`–`0x00D8F9` (`src/race/race_physics.asm` starts at `0xD8FA`)
- **Status:** analyzed (static L7 contract + E7-A dynamic; needle script decoded)
- **Related:** `docs/analysis/race_hud.md`, `docs/analysis/race.md`,
  `docs/analysis/animation.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose
Draws the race HUD: time, place, stamina, bike HP, player name/place, opponent name,
speed/RPM needles and odometer. Called from `Race_Update` via `RaceHud_Draw`; writes
`Race_ram_CurrentHudBuffer` and, for the needles, the SAT/tile arrays via
`UpdateAnimation`.

## API
| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RaceHud_Draw` | ``0xD278`` |
| `RaceHud_DrawSpeedArrow` | ``0xD29E`` |
| `RaceHud_DrawRPMArrow` | ``0xD2DC`` |
| `RaceHud_DrawOdometer` | ``0xD334`` |
| `RaceHud_DrawPlace` | ``0xD3F6`` |
| `RaceHud_DrawTime` | ``0xD410`` |
| `RaceHud_DrawStamina` | ``0xD458`` |

Full list: the related analysis page.

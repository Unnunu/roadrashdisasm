# Module card: `race_hud.asm`

- **ROM range:** `0x00D278`–`0x00D8F9` (`race_physics.asm` starts at `0xD8FA`)
- **Status:** analyzed (partial; needle/font data + dynamic TODO)
- **Related:** `docs/analysis/race_hud.md`, `docs/analysis/race.md`,
  `docs/analysis/animation.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Draws the race HUD: time, place, stamina, bike HP, player name/place, opponent name,
speed/RPM needles and odometer. Called from `Race_Update` via `RaceHud_Draw`; writes
`Race_ram_CurrentHudBuffer` and, for the needles, the SAT/tile arrays via
`UpdateAnimation`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RaceHud_Draw` | `0xD278` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_DrawSpeedArrow` | `0xD29E` | [x] | [~] | [~] | [x] | [x] | [ ] | partial |
| `RaceHud_DrawRPMArrow` | `0xD2DC` | [x] | [~] | [~] | [x] | [x] | [ ] | partial |
| `RaceHud_DrawOdometer` | `0xD334` | [x] | [x] | [~] | [x] | [x] | [ ] | partial |
| `RaceHud_DrawPlace` | `0xD3F6` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_DrawTime` | `0xD410` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_DrawStamina` | `0xD458` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_DrawBikeHPBar` | `0xD534` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Race_DrawPlayerNameOrPlace` | `0xD5CE` | [x] | [~] | [x] | [x] | [x] | [ ] | partial |
| `Race_DrawOpponentName` | `0xD73A` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_DrawSymbol` | `0xD830` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_DrawNumber2Digits` | `0xD850` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_DrawNumber4Digits` | `0xD890` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |

Detailed analysis: `docs/analysis/race_hud.md`.

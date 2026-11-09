# Module card: combat subsystem

- **Status:** static map; dynamic verification and naming pending
- **Files:** `src/race/race_ai.asm`, `src/race/race_anim_audio.asm`,
  `src/race/race_physics.asm`, `src/race/combat_const.asm`
- **Related:** `docs/analysis/combat.md`, `docs/analysis/race_ai.md`,
  `docs/analysis/race_anim_audio.md`, `docs/analysis/race_physics.md`,
  `docs/analysis/race_actors.md`, `docs/ram-map.md`

## Role / purpose

Player fist attack input and state, AI attack/collision actions, attack
phase/timer/SFX, armed-opponent flag, and the proximity rules that start a
fight. The player starts unarmed (`WEAPON_0`); opponents with definition byte2
bit7 are armed/special (`WEAPON_1` placeholder pending weapon identification).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|---|---|---|---|---|---|---|---|---|
| `sub_162B0` attack input | `0x162B0` | [x] | [~] | [x] | [x] | [x] | [ ] | static |
| `Race_UpdateNearestTarget` | `0x1611A` | [x] | [~] | [x] | [x] | [x] | [ ] | static |
| `sub_1634E` AI input | `0x1634E` | [~] | [~] | [~] | [x] | [~] | [ ] | unreferenced |
| `Race_UpdateCollision` | `0x16732` | [x] | [~] | [x] | [x] | [x] | [ ] | static |
| `sub_16458` dispatcher | `0x16458` | [x] | [~] | [x] | [x] | [x] | [ ] | static |
| action handlers | `0x165D0`–`0x16730` | [~] | [~] | [x] | [x] | [~] | [ ] | static |
| `Audio_UpdateEngine0/State` | `0x16520`/`0x16548` | [x] | [~] | [x] | [x] | [~] | [ ] | name TBD |

Detailed analysis: `docs/analysis/combat.md`.

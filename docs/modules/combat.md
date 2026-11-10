# Module card: `src/race/race_combat.asm`

- **ROM range:** `0x01611A`–`0x01685F` (`src/race/animation.asm` starts at `0x16860`)
- **Status:** club state/attack visuals dynamically confirmed; actual transfer static; AI/damage edge cases remain
- **Files:** `src/race/race_combat.asm`; action table in `src/race/race_ai.asm`
  (`Race_ActorActionTable`); temporary enum in `src/race/combat_const.asm`
- **Related:** `docs/analysis/combat.md`, `docs/analysis/race_ai.md`,
  `docs/analysis/race_anim_audio.md`, `docs/analysis/race_physics.md`,
  `docs/analysis/race_actors.md`, `docs/ram-map.md`

## Role / purpose

Player fist attack input and state, AI attack/collision actions, high/low/side
attack bits, attack phase/timer/SFX, armed-opponent flag, nearest-target
selection, and the proximity rules that start a fight. The player starts unarmed
(`WEAPON_NONE`); opponents with definition byte2 bit7 carry the only weapon,
the club (`WEAPON_CLUB`). It is visible only during the attack animation.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|---|---|---|---|---|---|---|---|---|
| `Race_UpdateNearestTarget` | `0x1611A` | [x] | [~] | [x] | [x] | [x] | [ ] | static |
| `Race_UpdatePlayerAttack` attack input | `0x162B0` | [x] | [~] | [x] | [x] | [x] | [~] | dynamic (input/height) |
| `Race_StealClub`/Mirror | `0x149C4`/`0x14B04` | [x] | [~] | [x] | [x] | [x] | [~] | static transfer + patched-ROM visual |
| `sub_1634E` AI input | `0x1634E` | [~] | [~] | [~] | [x] | [~] | [ ] | unreferenced |
| `Race_DispatchActorAction` dispatcher | `0x16458` | [x] | [~] | [x] | [x] | [x] | [~] | static + forced dispatch |
| `Race_TriggerArmedAttackSfx/State` | `0x16520`/`0x16548` | [x] | [~] | [x] | [x] | [~] | [ ] | name TBD |
| action handlers | `0x165D0`–`0x166F0` | [~] | [~] | [x] | [x] | [~] | [ ] | static |
| pair collision/knockback | `0x124E2`, `0x12A88`–`0x12B24` | [x] | [~] | [x] | [x] | [x] | [~] | static + forced armed/unarmed reach |
| `Race_UpdateCollision` | `0x16732` | [x] | [~] | [x] | [x] | [x] | [~] | static + forced low/high armed |

Detailed analysis: `docs/analysis/combat.md`.

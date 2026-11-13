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

## API
| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|---|---|---|---|---|---|---|---|---|
| `Race_UpdateNearestTarget` | ``0x1611A`` |
| `Race_UpdatePlayerAttack` attack input | ``0x162B0`` |
| `Race_StealClub`/Mirror | ``0x149C4`/`0x14B04`` |
| `sub_1634E` AI input | ``0x1634E`` |
| `Race_DispatchActorAction` dispatcher | ``0x16458`` |
| `Race_TriggerArmedAttackSfx/State` | ``0x16520`/`0x16548`` |
| impact/fall chain | ``0x1487C`/`0x145EC`/`0x14C3C`` |

Full list: the related analysis page.

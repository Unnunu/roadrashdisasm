# Analysis: combat subsystem (fist, armed AI, attack state)

- **Status:** static map; dynamic verification and naming pending
- **Scope:** player fist attack, AI attack/collision actions, high/low/side state,
  armed/special flag, attack timers/SFX
- **Source:** `src/race/race_ai.asm`, `src/race/race_anim_audio.asm`,
  `src/race/race_physics.asm`; temporary enum in `src/race/combat_const.asm`
- **Related:** `docs/modules/combat.md`, `docs/analysis/race_ai.md`,
  `docs/analysis/race_anim_audio.md`, `docs/analysis/race_physics.md`,
  `docs/analysis/race_actors.md`, `docs/ram-map.md`

## Player input / fist

`Race_GetInput` stores the pad state in `Race_ram_CurrentButtons` (`SACBRLDU`).
`sub_162B0` (`0x162B0`, temporary name) handles the attack input:

- `btst #5` (C) starts an attack.
- Up (`#0`) sets `$6B` bit0 (high attack).
- Down (`#1`) sets `$69` bit6 (low attack) and uses `ram_FF1ABC` timing.
- compares the player Y (`$30`) with `Race_ram_NearestActor` and sets `$69` bit5
  (attack side).
- sets `$69` bit4 (attack active), `ram_FF1B22`, `$6C=0`, `$6D` timing from
  `RaceBike_ram_PhysicsConstants` (or `ram_FF1AC2` when `$6B` bit1 is set).

The player definition (`$4B` "Player def") has definition byte2 = 0, so the player
is **unarmed**; `WEAPON_0` is the initial fist placeholder. `$6B` bit1 is copied
from the actor definition byte2 bit7 and marks armed/special opponents (`WEAPON_1`
placeholder until the visual/weapon mapping is confirmed).

## State fields

| Field | Meaning |
|---|---|
| `$69` bit4 | attack active |
| `$69` bit5 | attack side (target above/below) |
| `$69` bit6 | low attack |
| `$6B` bit0 | high attack |
| `$6B` bit1 | armed/special (definition byte2 bit7) |
| `$6C` | attack phase (0..3) |
| `$6D` | attack timing/countdown |
| `$5A` | attack/hit cooldown |
| `$4A` | attack/collision range |
| `ram_FF1B22` | player attack sequence active |
| `ram_FF1B24` | AI attack/steer input bits (writer unknown) |
| `ram_FF1A68` | current actor graphics/combat record pointer |
| `ram_FF1786` | distance to nearest target |
| `ram_FF1AD6`/`ram_FF1AD7` | SFX IDs passed to `Audio_PlaySfx` |
| `ram_FF1906` | attack phase-1 flag / engine-audio handoff |
| `Race_ram_BikeDamage` | bike damage from crashes/impacts (attack damage TBD) |

`Race_UpdateNearestTarget` (`0x1611A`) also drives the attack timer: while
`ram_FF1B22` is set it decrements `$6D`, advances `$6C`, calls
`Audio_UpdateEngine0` at phase 1, and clears the attack at phase 3.
`Audio_UpdateEngine0`/`Audio_UpdateEngineState` are probably **attack SFX/state**
despite the current names; rename only after dynamic confirmation.

## Combat/AI action handlers

`unk_12D16` (`0x12D16`) is a 99-entry action-handler table; `unk_259C0` selects
slots via the actor `$74` profile; `unk_25A44` is the 16-entry static-actor table.
The combat/action routines in `race_anim_audio.asm`:

| Function | Role (static hypothesis) |
|---|---|
| `sub_16458` | Dispatch: attack/cooldown, nearest-target action selection. |
| `sub_165D0` | Steer/road-center + collision/speed check (`sub_131BE`). |
| `sub_165E0` | Steering/brake state + movement/curve update. |
| `sub_16612` | Collision check + speed/steer correction. |
| `sub_16624` | Steering update followed by collision. |
| `sub_1662C` | Random choice: attack/collision vs pursuit. |
| `sub_16644` | React to player/nearest; close -> random attack/avoid. |
| `sub_1666A` | Target-distance rule: on-foot `$5A` timer or pursue/attack. |
| `sub_166B0` | Attack when target within graphics-record distance. |
| `sub_166DC` | Evade/steer toward player. |
| `sub_166F0` | Combat/collision response. |

`Race_UpdateCollision` (`0x16732`) initializes an attack/collision state when the
player/actor X/Y ranges overlap: it sets `$5A`, `$6C=0`, `$69` bit4/5/6 and the
`$6D` timing from `ram_FF1ABC`/`RaceBike_ram_PhysicsConstants`. The record pointed
to by `ram_FF1A68` supplies the distance/timer fields (`+0`, `+2`, `+8`).

`sub_1634E` (`0x1634E`) decodes `ram_FF1B24` into the same attack/steer fields,
but **no callers or writer were found** in the current source; it may be dead or
an unreferenced debug/alternate AI path. This needs dynamic confirmation.

## Actor profiles / weapons

`Race_ActorDefinitionTable` (76 x 16 bytes):

- byte1 -> `$74`: AI/action profile (`1..18`).
- byte2 low7 -> `$75`: graphics index.
- byte2 bit7 -> `$6B` bit1: armed/special flag (`WEAPON_1` placeholder).
- byte3 -> `$73`, byte4 -> `$77`, byte5 -> `$66` (rating *100).

Most opponents have byte2 bit7 set (Viper, Biff, Natasha, Helldog, ...);
the player definition has byte2=0. The exact club/chain type is not a separate
field in the definition: it is likely selected by the graphics index/animation
and attack timing tables (`ram_FF1AC2`, `ram_FF1ABC`, `unk_257E2/E8/EE`).
`Race_ActorGraphicsTable` records are also read for combat ranges/cooldowns.

## Damage

Crashes/collisions add to `Race_ram_BikeDamage` via `sub_11B7A`, `sub_14486`,
and `sub_14CEC`; `sub_1434A` computes the impact scale. Whether a punch directly
changes bike damage, or only speed/Y/knockdown, is an open dynamic question.
Attack SFX: `Audio_UpdateEngine0` sets `ram_FF1AD7=$0E` at attack phase 1;
`sub_14E38` passes `ram_FF1AD6/AD7` to `Audio_PlaySfx`.

## Dynamic test 1 (player attack, native console)

With C near an opponent, breakpoint `0x16320` (`sub_162B0` after state setup):

- `ram_FF1B22 = 1`
- player `$69 = $12` (bit4 attack active; bit1 also set)
- player `$6B = $01` (high flag)
- player `$6C = 0`, `$6D = 1`, `$5A = 0`
- nearest actor = `$FF232A`
- backtrace: `Race_Update` -> `Race_UpdateNearestTarget` -> `sub_162B0`

Follow-up trace: `a1 = $FF1EAA` (player A), `Race_ram_CurrentButtons = $30`
(B+C); at `0x16338` the player Y was below the target Y, so the branch was not
taken and `$69` bit5 was cleared. This confirms the side branch but the test must
be repeated with pure C / C+Up / C+Down.

This confirms the attack path and the `$6C/$6D` phase/timer fields. `$69` bit5
(attack side) is set/cleared after the Y comparison, so it must be captured after
stepping to `0x16346`. Up/Down comparisons and AI handlers are still pending.

## Open questions / next experiments

- Confirm attack phase semantics (`$6C` 0..3), high/low/side bits, `$5A`.
- Determine whether `sub_1634E`/`ram_FF1B24` is dead.
- Map `$74` profiles to action handlers and enemy aggression.
- Identify weapon visuals (club/chain) vs `WEAPON_1`; whether player can pick up.
- Determine if punches damage `BikeDamage` or only knock/steer; player hit response.
- Dynamic: race, press C/Up/Down near an opponent; breakpoints at `0x162B0`,
  `0x16732`, `0x16458`, `0x16612`, `0x1666A`, `0x16520`; inspect fields and
  opponent reaction. Test armed vs unarmed opponents.

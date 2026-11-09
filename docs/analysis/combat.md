# Analysis: combat subsystem (fist, armed AI, attack state)

- **Status:** static map; dynamic verification and naming pending
- **Scope:** player fist attack, AI attack/collision actions, high/low/side state,
  armed/special flag, attack timers/SFX
- **Source:** `src/race/race_combat.asm` (`0x1611A`–`0x1685F`), action dispatch in
  `src/race/race_ai.asm`, and `src/race/race_physics.asm`; temporary enum in
  `src/race/combat_const.asm`
- **Related:** `docs/modules/combat.md`, `docs/analysis/race_ai.md`,
  `docs/analysis/race_anim_audio.md`, `docs/analysis/race_physics.md`,
  `docs/analysis/race_actors.md`, `docs/ram-map.md`

## Player input / fist

`Race_GetInput` stores the pad state in `Race_ram_CurrentButtons` (`SACBRLDU`).
`Race_UpdatePlayerAttack` (`0x162B0`) handles the attack input:

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

`Race_ActorActionTable` (`0x12D16`) is a 99-entry action-handler table; `Race_ActorProfileTable` selects
slots via the actor `$74` profile; `Race_StaticActionTable` is the 16-entry static-actor table.
The combat/action routines in `race_combat.asm`:

| Function | Role (static hypothesis) |
|---|---|
| `Race_DispatchActorAction` | Dispatch: attack/cooldown, nearest-target action selection. |
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
player/actor X/Y ranges overlap:

- early return if `$69` bit4 is already set;
- `d1 = $4A(a1) + $4A(a2) + $10`, `d2 = d1 - 8`;
- `|X(player)-X(a1)|` is compared with `ram_FF1A68 + 2`;
- `|Y(player)-Y(a1)|` is compared with `d1`; side `$69` bit5 is set from the
  player/actor Y relation;
- if Y diff < `d2`, low `$69` bit6 and `ram_FF1ABC` timing; otherwise high bit6
  clear and `RaceBike_ram_PhysicsConstants` timing;
- `$5A = ram_FF1A68 + 8` (cooldown), `$6C=0`, attack-active `$69` bit4 set;
- `$6B` bit0 is cleared, then the low bit of `Race_ram_ActorDistanceScale` is ORed
  back in; if `$6B` bit1 is armed, the timer is forced to `$3C`.

The record pointed to by `ram_FF1A68` supplies the distance/timer fields
(`+0`, `+2`, `+8`). This is the **collision-start** path; it does not itself add
bike damage.

`sub_1634E` (`0x1634E`) decodes `ram_FF1B24` into the same attack/steer fields,
but **no callers or writer were found** in the current source; it may be dead or
an unreferenced debug/alternate AI path. This needs dynamic confirmation.

Applied in R3a: `Race_UpdatePlayerAttack` (`sub_162B0`) and
`Race_ScaleImpactDamage` (`sub_1434A`).

`[dynamic]` Forced dispatcher trace exercised the live handlers: profile `6`
entered `sub_16624`/`sub_165E0` (action4), profile `8`
`sub_13004`/`sub_16612`, and profile `9` `sub_166B0`/`sub_16612`.

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

`Race_ScaleImpactDamage` is the impact scale: if `ram_FF1768` is non-zero it returns 0;
otherwise `abs(d0) >> 11` and stores it in `ram_FF1B28`.

| Source | Added to `Race_ram_BikeDamage` | Notes |
|---|---|---|
| `sub_11B7A` | `Race_ScaleImpactDamage(Speed) >> 2` | player/actor crash/impact path; sets `$68` bit4 and recovery animation |
| `sub_14486` | `Race_ScaleImpactDamage(result)` | impact/avoid path, also copies `$69` bit3 from the other actor |
| `sub_14CEC` | `Race_ScaleImpactDamage(result)` | speed-exchange collision path |

`Race_UpdateCollision` starts the attack state but does not add damage itself.
Whether a player punch changes the opponent’s bike-damage/knockdown only through
these impact helpers is still a dynamic question.

Attack SFX: `Audio_UpdateEngine0` sets `ram_FF1AD7=$0E` at attack phase 1;
`sub_14E38` passes `ram_FF1AD6/AD7` to `Audio_PlaySfx`.

## Dynamic test 1 (player attack, native console)

With C near an opponent, breakpoint `0x16320` (`Race_UpdatePlayerAttack` after state setup):

- `ram_FF1B22 = 1`
- player `$69 = $12` (bit4 attack active; bit1 also set)
- player `$6B = $01` (high flag)
- player `$6C = 0`, `$6D = 1`, `$5A = 0`
- nearest actor = `$FF232A`
- backtrace: `Race_Update` -> `Race_UpdateNearestTarget` -> `Race_UpdatePlayerAttack`

Follow-up trace: `a1 = $FF1EAA` (player A), `Race_ram_CurrentButtons = $30`
(B+C); at `0x16338` the player Y was below the target Y, so the branch was not
taken and `$69` bit5 was cleared. This confirms the side branch but the test must
be repeated with pure C / C+Up / C+Down.

This confirms the attack path and the `$6C/$6D` phase/timer fields. `$69` bit5
(attack side) is set/cleared after the Y comparison, so it must be captured after
stepping to `0x16346`. Up/Down comparisons and AI handlers are still pending.

## Dynamic test 2 (height input)

Native console at `0x1634C` after the attack input:

| Buttons | `$69` | `$6B` | `$6C` | `$6D` | `$5A` | nearest |
|---|---|---|---|---|---|---|
| C alone (`$20`) | `$10` | `$00` | 0 | 1 | 0 | `$FF232A` |
| C+Up (`$21`) | `$10` | `$01` | 0 | 1 | 0 | `$FF232A` |
| C+Down (`$22`) | `$52` | `$00` | 0 | `$0A` | 0 | `$FFFFFFFF` |

Conclusions:

- `$69` bit4 (`$10`) = attack active.
- `$6B` bit0 (`$01`) = high attack; set only with Up.
- `$69` bit6 (`$40`) = low attack; set with Down, which also selects the
  `ram_FF1ABC` timing (`$6D = $0A`).
- `$69` bit1 (`$02`) in the C+Down trace is a state bit set elsewhere
  (`race_ai` writes `$69` bit1), not an attack-height bit. A forced-steering test
  sets bit2 (`$69=$04`), so bit1 is still unresolved; bit2 is steering-related.
- `$69` bit5 (side) is set/cleared after the nearest-Y comparison; a positive
  side test (player above target) is still pending.
- `$5A` remains 0 at the input frame; phase/timer progression still needs frame
  stepping.

## Dynamic test 3 (forced collision/attack, headless)

At `Race_UpdateCollision` (`0x16732`) the active opponent X/Y was forced to the
player position, and C was injected into `Race_ram_CurrentButtons` for the first
five `Race_UpdateNearestTarget` (`0x1611A`) hits. After 90 frames:

- player `$68=$42`, `$69=$26` (bits1/2/5), `$6B=0`;
- `$5A=0`, `$6C=2`, `$6D=7`;
- `Race_ram_BikeDamage=0`, nearest `$FF23AA`.

This confirms the attack-state/phase fields under forced proximity, but did not
produce bike damage in this snapshot.

## Dynamic test 4 (armed collision, headless)

For the active opponent `$FF232A`, X/Y were forced to the player position and
`$6B` bit1 (armed) was set before `Race_UpdateCollision`. Result at the function
exit:

- `$69 = $50` (attack active + low), `$6B = $02` (armed);
- `$5A = $B4` (cooldown from `ram_FF1A68 + 8`);
- `$6C = 0`, `$6D = $0A` (low-attack timing from `ram_FF1ABC`);
- `$30 = $A0`.

The low-attack branch returns before the armed `$6D=$3C` override; that override
only appears in the high-attack branch.

A second armed run used a Y offset of `+$24` to hit the high branch:
`$69=$30` (bit4/5), `$6B=$03` (armed + low distance bit), `$5A=$B4`,
`$6D=$3C`. This confirms the armed high-attack timer. Neither run showed direct
`BikeDamage` from the punch; that remains a dynamic question.

## Open questions / next experiments

- Confirm attack phase semantics (`$6C` 0..3), high/low/side bits, `$5A`.
- Determine whether `sub_1634E`/`ram_FF1B24` is dead.
- Map `$74` profiles to action handlers and enemy aggression.
- Identify weapon visuals (club/chain) vs `WEAPON_1`; whether player can pick up.
- Determine if punches damage `BikeDamage` or only knock/steer; player hit response.
  Forced proximity/attack reached `$6C=2` but left `BikeDamage=0`; try a longer/natural
  impact and an armed opponent.
- Dynamic: race, press C/Up/Down near an opponent; breakpoints at `0x162B0`,
  `0x16732`, `0x16458`, `0x16612`, `0x1666A`, `0x16520`; inspect fields and
  opponent reaction. Test armed vs unarmed opponents.

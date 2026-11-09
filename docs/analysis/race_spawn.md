# Analysis: `race.asm` spawn/traffic subsystem

- **Module:** dynamic opponent/traffic spawning, actor active/free lists, speed display
- **Source:** `race.asm` (`Race_SpawnTick` `0x16AF6`-area, `Race_SpawnOpponent`,
  `Race_SpawnTraffic`, list helpers, `Race_UpdateSpeedDisplay` `0xF108`,
  `Race_FormatDecimal` `0xF11C`)
- **Status:** analyzed statically; exact initial list counts/overlap and some fields
  TODO
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_actors.md`,
  `docs/ram-map.md`, `docs/modules/race.md`

## Call position

`Race_Update` calls `Race_UpdateSpeedDisplay` with the player Speed, then
`Race_SpawnTick`, then (if `ram_FF1B20` = race started) the actor/opponent physics
chain. The spawner adds/removes actors and the physics chain moves them.

## Lists

| Address | Contents |
|---|---|
| `ram_FF1A08` | 8 actor pointers from `Race_InitActorLists` (first actor + 7; `Race_InitActorPositions` sets their screen fields). |
| `ram_FF1A0C` | Active actor list (`FFFFFFFF`-terminated); `Race_ActivateActor` appends, `Race_RemoveActiveActor` removes. |
| `ram_FF1A06` | Active actor count; initial 8, spawn threshold `< 6`. |
| `ram_FF1982` | Opponent free list (7 entries from `Race_InitActorLists`); pop/push by `Race_PopFreeActor`/`Race_PushFreeActor`. |
| `ram_FF19C4` | Traffic free list; `Race_RecycleActor` pushes, `Race_SpawnTraffic` pops (initial count TODO). |
| `ram_FF1E68` | Player progress used by the ahead/behind checks. |
| `ram_FF1E9C` | Actor-distance scale. |
| `ram_FF1EA6` | Spawn timer (0..511 frames). |
| `ram_FF1F2A` | First opponent actor (special cases in the checks/recycle). |
| `ram_FF1B20` | Race started flag. |
| `ram_FF1B38` | Current level/cop index used by `Race_RecycleActor`. |

`ram_FF1A08`/`ram_FF1A0C` overlap (active list starts inside the actor screen list);
the exact 8+7 split and initial active count are TODO.

## `Race_SpawnTick` (`0x16AF6`)

1. If the player A `$68` bit7 is set (finished/disabled), return.
2. If `ram_FF1EA6` is non-zero, subtract the frame delay and return; at 0 clear it.
3. If `ram_FF1A06 >= 6`, return (enough active actors).
4. If player Speed `>= 6000`: `Race_SpawnOpponent`; if it returns `$FFFFFFFF`
   (no/too-far actor) fall back to `Race_SpawnTraffic`.
5. Otherwise `Race_SpawnTraffic`.
6. Set `ram_FF1EA6 = Rand_GetWord & $1FF` (0..511 frames).

## Spawn paths

`Race_SpawnOpponent` (`0x16BD6`):

1. `Race_PopFreeActor` from `ram_FF1982`; if `$FFFFFFFF` give up.
2. `Race_CheckOpponentAhead`: recycle the actor if its distance is too far ahead
   (`Race_GetActorDistance` vs `ram_FF1E68 + $20`; `RaceTrack_Data1`; the first
   opponent `ram_FF1F2A` + `$68` bit6 is special).
3. `Race_ActivateActor` (append to `ram_FF1A0C`, `ram_FF1A06++`).
4. `Race_InitOpponentActor`: x = player A x + `$200000`; `+$66` rating -> `+$12`
   Speed; `Race_SetupActor`; `sub_13FE6`; clamp Speed.

`Race_SpawnTraffic` (`0x16C1A`):

1. `Race_PopFreeActor` from `ram_FF19C4`; `$FFFFFFFF` -> give up.
2. `Race_CheckTrafficBehind` (`ram_FF1E68 - $10`; too far -> recycle).
3. `Race_ActivateActor`.
4. `Race_InitTrafficActor`: x = player A x - `$100000`; `+$1E` = x; `+$66` -> Speed;
   `Race_SetupActor`; clamp.
5. `Race_ApplyActorRating`: actor index `+$71` -> `Menu_ram_PlayerA/BOpponents`
   (word) -> `Race_ActorDefinitionTable` byte5 ×100 -> `+$66`.

## Actor setup/recycle

- `Race_SetupActor` (`0x16D9A`): `Track_CurveBuffer` at the actor position ->
  `+$8/+$C`; clear `$68` bits 4/0; `+$2C`, `+$5C = ram_FF18A8`, `+$6E = $FF`;
  zero `+0/$A/$2/$32/$36/$38/$3A/$3C`; `+$1A/+0` from `+$30`; call `sub_13746`.
- `Race_RecycleActor` (`0x16CAE`): the first opponent/level case resets
  `ram_FF1B38/34/36`; otherwise push to `ram_FF19C4`; remove from the active list;
  `+$66 = +$04 / ram_FF1E9C`.
- `Race_RecycleOpponent` (`0x16C9A`): push to `ram_FF1982`; remove from active.
- `Race_ActivateActor` (`0x16D0A`): append to `ram_FF1A0C`, count++.
- `Race_RemoveActiveActor` (`0x16E26`): shift the list, count--.
- `Race_PushFreeActor` (`0x16E48`) / `Race_PopFreeActor` (`0x16E54`): free-list
  push/pop, `$FFFFFFFF` when empty.

## Distance helpers

- `Race_GetActorDistance` (`0x16BC8`): `actor[+$66] * ram_FF1E9C >> 16`.
- `Race_CheckOpponentAhead` (`0x16B6A`): recycle if the distance is more than
  `ram_FF1E68 + $20`; skips the first opponent; `$FFFFFFFF` result.
- `Race_CheckTrafficBehind` (`0x16B9E`): recycle if the distance is behind
  `ram_FF1E68 - $10`; `$FFFFFFFF` result.

## Speed display

`Race_UpdateSpeedDisplay` (`0xF108`): `d0 = Speed >> 7`, `d1 = d0 >> 2`,
`d0 += d1`, `Race_FormatDecimal` -> packed decimal in `d1`; store
`ram_FF3046` (the 98C2 debug and HUD speed readout).

`Race_FormatDecimal` (`0xF11C`): converts a 16-bit value to a packed 5-digit decimal
(used by the debug readouts, speed and other HUD values).

## Open questions

- The exact initial `ram_FF1A0C`/`ram_FF19C4` counts and the `ram_FF1A08`/`ram_FF1A0C`
  overlap.
- `ram_FF1B34/B36/B38` semantics (level/cop).
- The `Race_SetupActor` fields and `sub_13746` (actor sprite/animation) need the
  physics chain (`sub_13xxx`).
- The traffic free list's initial population.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `ram_FF1E68` | `Race_PlayerProgress` | player progress | medium |
| `ram_FF1E9C` | `Race_ActorDistanceScale` | distance scale | medium |
| `ram_FF1A0C` | `Race_ActiveActorList` | active list | high |
| `ram_FF1982`/`ram_FF19C4` | `Race_OpponentFreeList`/`Race_TrafficFreeList` | free lists | high |

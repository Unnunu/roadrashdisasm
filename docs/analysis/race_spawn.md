# Analysis: `src/race/race.asm` spawn/traffic subsystem

- **Module:** dynamic opponent/traffic spawning, actor active/free lists, speed display
- **Source:** `src/race/race_spawn.asm` (`Race_SpawnTick` `0x16AF6`-area,
  `Race_SpawnOpponent/Traffic`, list helpers); speed helpers in `src/race/race_ai_road.asm`
  (`Race_UpdateSpeedDisplay` `0xF108`, `Race_FormatDecimal` `0xF11C`); actor tables in
  `src/race/race_core.asm`.
- **Status:** analyzed statically + dynamic list snapshot; some fields TODO
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_actors.md`,
  `docs/ram-map.md`, `docs/modules/race.md`

## Call position

`Race_Update` calls `Race_UpdateSpeedDisplay` with the player Speed, then
`Race_SpawnTick`, then (if `Race_ram_Started` = race started) the actor/opponent physics
chain. The spawner adds/removes actors and the physics chain moves them.

## Lists

| Address | Contents |
|---|---|
| `ram_FF1A08` | 8 actor pointers from `Race_InitActorLists` (first actor + 7; `Race_InitActorPositions` sets their screen fields). |
| `Race_ram_ActiveActorList` | Active actor list (`FFFFFFFF`-terminated); `Race_ActivateActor` appends, `Race_RemoveActiveActor` removes. |
| `Race_ram_ActiveActorCount` | Active actor count; initial 8, spawn threshold `< 6`. |
| `Race_ram_OpponentFreeList` | Opponent free list (7 entries from `Race_InitActorLists`); pop/push by `Race_PopFreeActor`/`Race_PushFreeActor`. |
| `Race_ram_TrafficFreeList` | Traffic free list; `Race_RecycleActor` pushes, `Race_SpawnTraffic` pops (initial count TODO). |
| `Race_ram_PlayerProgress` | Player progress used by the ahead/behind checks. |
| `Race_ram_ActorDistanceScale` | Actor-distance scale. |
| `Race_ram_SpawnTimer` | Spawn timer (0..511 frames). |
| `ram_FF1F2A` | First opponent actor (special cases in the checks/recycle). |
| `Race_ram_Started` | Race started flag. |
| `Race_ram_LevelIndex` | Current level/cop index used by `Race_RecycleActor`. |

`[dynamic]` Initial demo: active count 8 (PlayerA + 7 opponents), opponent free count 7, traffic free count 0; the active list starts with PlayerA and the first active opponent is `$FF232A`.

## `Race_SpawnTick` (`0x16AF6`)

1. If the player A `$68` bit7 is set (finished/disabled), return.
2. If `Race_ram_SpawnTimer` is non-zero, subtract the frame delay and return; at 0 clear it.
3. If `Race_ram_ActiveActorCount >= 6`, return (enough active actors).
4. If player Speed `>= 6000`: `Race_SpawnOpponent`; if it returns `$FFFFFFFF`
   (no/too-far actor) fall back to `Race_SpawnTraffic`.
5. Otherwise `Race_SpawnTraffic`.
6. Set `Race_ram_SpawnTimer = Rand_GetWord & $1FF` (0..511 frames).

## Spawn paths

`Race_SpawnOpponent` (`0x16BD6`):

1. `Race_PopFreeActor` from `Race_ram_OpponentFreeList`; if `$FFFFFFFF` give up.
2. `Race_CheckOpponentAhead`: recycle the actor if its distance is too far ahead
   (`Race_GetActorDistance` vs `Race_ram_PlayerProgress + $20`; `RaceTrack_Data1`; the first
   opponent `ram_FF1F2A` + `$68` bit6 is special).
3. `Race_ActivateActor` (append to `Race_ram_ActiveActorList`, `Race_ram_ActiveActorCount++`).
4. `Race_InitOpponentActor`: x = player A x + `$200000`; `+$66` rating -> `+$12`
   Speed; `Race_SetupActor`; `Race_GetCurveSpeedLimit`; clamp Speed.

`Race_SpawnTraffic` (`0x16C1A`):

1. `Race_PopFreeActor` from `Race_ram_TrafficFreeList`; `$FFFFFFFF` -> give up.
2. `Race_CheckTrafficBehind` (`Race_ram_PlayerProgress - $10`; too far -> recycle).
3. `Race_ActivateActor`.
4. `Race_InitTrafficActor`: x = player A x - `$100000`; `+$1E` = x; `+$66` -> Speed;
   `Race_SetupActor`; clamp.
5. `Race_ApplyActorRating`: actor index `+$71` -> `Menu_ram_PlayerA/BOpponents`
   (word) -> `Race_ActorDefinitionTable` byte5 ×100 -> `+$66`.

## Actor setup/recycle

- `Race_SetupActor` (`0x16D9A`): `Track_CurveBuffer` at the actor position ->
  `+$8/+$C`; clear `$68` bits 4/0; `+$2C`, `+$5C = ram_FF18A8`, `+$6E = $FF`;
  zero `+0/$A/$2/$32/$36/$38/$3A/$3C`; `+$1A/+0` from `+$30`; call `Race_SetupActorSprite`.
- `Race_RecycleActor` (`0x16CAE`): the first opponent/level case resets
  `Race_ram_LevelIndex`/`ram_FF1B34`/`ram_FF1B36`; otherwise push to `Race_ram_TrafficFreeList`; remove from the active list;
  `+$66 = +$04 / Race_ram_ActorDistanceScale`.
- `Race_RecycleOpponent` (`0x16C9A`): push to `Race_ram_OpponentFreeList`; remove from active.
- `Race_ActivateActor` (`0x16D0A`): append to `Race_ram_ActiveActorList`, count++.
- `Race_RemoveActiveActor` (`0x16E26`): shift the list, count--.
- `Race_PushFreeActor` (`0x16E48`) / `Race_PopFreeActor` (`0x16E54`): free-list
  push/pop, `$FFFFFFFF` when empty.

## Distance helpers

- `Race_GetActorDistance` (`0x16BC8`): `actor[+$66] * Race_ram_ActorDistanceScale >> 16`.
- `Race_CheckOpponentAhead` (`0x16B6A`): recycle if the distance is more than
  `Race_ram_PlayerProgress + $20`; skips the first opponent; `$FFFFFFFF` result.
- `Race_CheckTrafficBehind` (`0x16B9E`): recycle if the distance is behind
  `Race_ram_PlayerProgress - $10`; `$FFFFFFFF` result.

## Speed display

`Race_UpdateSpeedDisplay` (`0xF108`): `d0 = Speed >> 7`, `d1 = d0 >> 2`,
`d0 += d1`, `Race_FormatDecimal` -> packed decimal in `d1`; store
`Race_ram_SpeedDisplay` (the 98C2 debug and HUD speed readout).

`Race_FormatDecimal` (`0xF11C`): converts a 16-bit value to a packed 5-digit decimal
(used by the debug readouts, speed and other HUD values).

## Open questions

- `ram_FF1A08`/`Race_ram_ActiveActorList` overlap details; `ram_FF1B34/B36/B38` semantics.
- `ram_FF1B34/B36/B38` semantics (level/cop).
- The `Race_SetupActor` fields and `Race_SetupActorSprite` (actor sprite/animation) need the
  physics chain (`sub_13xxx`).
- The traffic free list's initial population.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `Race_ram_ActiveActorList` | `Race_ActiveActorList` | active list | high |
| `Race_ram_OpponentFreeList`/`Race_ram_TrafficFreeList` | `Race_OpponentFreeList`/`Race_TrafficFreeList` | free lists | high |

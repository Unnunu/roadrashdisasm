# Analysis: spawn/traffic/static lifecycle

- **Module:** opponent/traffic/static lifecycle, actor active/free lists, speed display
- **Source:** `src/race/race_spawn.asm` (`Race_SpawnTick` `0x16AF6`-area,
  `Race_SpawnOpponent/Traffic`, list helpers); `Race_SpawnOpponents`/`Race_CreateActors`
  in `src/race/race_core.asm`; `sub_13BF4`, `sub_138CE`, `Race_UpdateStaticActors`,
  `Race_InitExtraStaticActor`/`Race_UpdateExtraStaticActor` in `src/race/race_ai.asm`;
  speed helpers in `src/race/race_ai_road.asm` (`Race_UpdateSpeedDisplay` `0xF108`,
  `Race_FormatDecimal` `0xF11C`).
- **Status:** L5 complete (static contracts + E5 dynamic), see `tasks/race_L5_spawn.md`
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_actors.md`,
  `docs/analysis/race_ai.md`, `docs/analysis/race_track_data.md`, `docs/ram-map.md`,
  `docs/modules/race.md`

## Call position

`Race_Update` calls `Race_UpdateSpeedDisplay` with the player Speed, then
`Race_SpawnTick`, then (if `Race_ram_Started` = race started) the actor/opponent physics
chain. The spawner adds/removes actors and the physics chain moves them.

## Who is on the track (L5 lifecycle)

Four populations share the `$80`-byte actor struct. `$71` is the slot index: 0..15 are
`Race_ActorList` entries (player + 15 opponents), `$10`/`$11` the two static actors and
`$12` the extra static slot.

| Population | Slots | `$71` | Created by | Activated by | Removed by |
|---|---|---|---|---|---|
| Player | `RacePlayerA` | 0 | `Race_CreateActors` | always active | never |
| Loop opponents | `Race_ActorStruct_9..15` on `ram_FF1A08`, `Struct_2..8` on the opponent free list | 2..15 | `Race_CreateActors` | `Race_InitActorLists` (7 active) + `Race_SpawnOpponent` (free list) | `Race_RecycleOpponent` -> opponent free list |
| Reserved opponent | `ram_FF1F2A` (entry 1 of `Race_ActorList`) | 1 | `Race_CreateActors` | `sub_13BF4` (rating gate or `Data5` special list) | `Race_RecycleActor` special case; not pushed to a free list |
| Static pair | `$FF2EAA`, `$FF2F2A` (`Race_StaticActorList`) | `$10`, `$11` | `Race_CreateActors` | `sub_138CE` timer expiry -> `sub_13A26` | `Race_ClampActorY` clears `$68` bit6 |
| Extra static | `$FF2FAA` | `$12` | `Race_CreateActors` (`$71=$12`) | `Race_InitExtraStaticActor` when a `shape $186` track object is at `ram_FF1B30 >= $1C` and `ProgressSnapshotB >= $708` | `Race_Update` clears bit6 while `ram_FF1B30` is negative/absent |

`Race_Update` frame order around this subsystem:

```
sub_13BF4            ; reserved opponent
Race_UpdateStaticActors
ram_FF1B30 gate      ; $FF (marker absent) -> deactivate extra, else init/update
Race_InitExtraStaticActor / Race_UpdateExtraStaticActor
sub_138CE            ; static respawn/profile cycle
```

## Lists

| Address | Contents |
|---|---|
| `ram_FF1A08` | 8 actor pointers from `Race_InitActorLists` (PlayerA + `Struct_9..15`; `Race_InitActorPositions` sets their screen fields). |
| `Race_ram_ActiveActorList` | Active actor list (`FFFFFFFF`-terminated); `Race_ActivateActor` appends, `Race_RemoveActiveActor` removes. |
| `Race_ram_ActiveActorCount` | Active actor count; starts at 8 (player + 7 loop opponents), spawn threshold `>= 6` returns. |
| `Race_ram_OpponentFreeList` | Opponent free list (7 entries `Struct_2..8` from `Race_InitActorLists`); pop/push by `Race_PopFreeActor`/`Race_PushFreeActor`. |
| `Race_ram_TrafficFreeList` | Traffic free list; starts empty (`Race_InitActorLists` writes 0); `Race_RecycleActor` pushes and `Race_SpawnTraffic` pops. |
| `ram_FFDBD4` | Cursor into the `Data5` **special** list (`ram_FFDBD8`); consumed by `sub_13BF4`. |
| `Race_ram_TrackObjectRecordCursor` | Cursor into the `Data5` **normal** list (`ram_FFD7D4`); consumed by `Race_AddStagedObjects`. |
| `Race_ram_PlayerProgress` | Player progress used by the ahead/behind checks. |
| `Race_ram_ActorDistanceScale` | Actor-distance scale. |
| `Race_ram_SpawnTimer` | Spawn timer (0..511 frames). |
| `ram_FF1F2A` | Reserved opponent actor (special cases in the checks/recycle). |
| `Race_ram_Started` | Race started flag. |
| `Race_ram_LevelIndex` (`$FF1B38`) | Reserved-opponent page/colour index from the `Data5` special record; compared with `Menu_ram_PlayerLevel` on recycle. |
| `ram_FF1B32` | Reserved-opponent spawn delay timer. |
| `ram_FF1B34`/`ram_FF1B36` | Reserved-opponent rating-distance offset / "initial placement done" latch. |
| `ram_FF1B3A` | Last reserved-opponent rating distance (`Rating*scale`). |

`[dynamic]` Initial demo: active count 8 (PlayerA + 7 opponents), opponent free count 7,
traffic free count 0; the active list starts with PlayerA and the first active opponent
is `$FF232A`. `ram_FF1F2A` is **not** in the free or active list at init; it waits for
`sub_13BF4`.

## `Race_SpawnTick` (`0x16AF6`)

1. If the player A `$68` bit7 is set (finished/disabled), return.
2. If `Race_ram_SpawnTimer` is non-zero, subtract the frame delay and return; at 0 clear it.
3. If `Race_ram_ActiveActorCount >= 6`, return (enough active actors).
4. If player Speed `>= 6000`: `Race_SpawnOpponent`; if it returns `$FFFFFFFF`
   (no/too-far actor) fall back to `Race_SpawnTraffic`.
5. Otherwise `Race_SpawnTraffic`.
6. Set `Race_ram_SpawnTimer = Rand_NextWord & $1FF` (0..511 frames).

## Spawn paths

`Race_SpawnOpponent` (`0x16BD6`):

1. `Race_PopFreeActor` from `Race_ram_OpponentFreeList`; if `$FFFFFFFF` give up.
2. `Race_CheckOpponentAhead`: recycle the actor if its distance is too far ahead
   (`Race_GetActorDistance` vs `Race_ram_PlayerProgress + $20`; `RaceTrack_Data1`; the
   reserved opponent `ram_FF1F2A` + `$68` bit6 is exempt/special).
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

`sub_13BF4` (`0x13BF4`) — reserved opponent:

1. `ram_FF1B32` spawn-delay timer: if non-zero, subtract `FrameDelay` and return while
   positive.
2. If the actor is active (`$68` bit6 set), return. Otherwise first try the **rating
   gate**: `Rating * (ActorDistanceScale - ram_FF1B34)`; when it reaches
   `PlayerProgress - $100000` and `ram_FF1B36` is clear, set the latch, place the
   actor at `PlayerProgress - $100000`, Speed `$1F40`,
   `Race_ram_LevelIndex = Menu_ram_PlayerLevel`, and call `sub_13CFE`.
3. If the rating gate does not fire, walk `ram_FFDBD4`: take the next 4-byte special
   record once the player is within `$200000` of its X; place the actor at the record
   X, set `Race_ram_LevelIndex` from record `+2`, lane
   `$30 = (record low nibble)*$20 - $100`, Speed `min(player Speed,$2710)`, then
   `sub_13CFE`.
4. `sub_13CFE`: activate + `Race_SetupActor` + curve clamp; graphics index `$75 =
   LevelIndex + 4` (generic bike entries 5..9) and type byte from
   `Race_ActorDefinitionTable[Race_ActorLevelBase[LevelIndex-1]]`.

`Race_RecycleActor` (`0x16CAE`) handles `ram_FF1F2A` specially: when
`Menu_ram_PlayerLevel == Race_ram_LevelIndex` it clears `ram_FF1B34`/`ram_FF1B36`, then
clears `Race_ram_LevelIndex`; it is not pushed to a free list. Other actors go to
`Race_ram_TrafficFreeList`. In both cases `+$66 = +$04 / Race_ram_ActorDistanceScale`.

## Static actor cycle

`sub_138CE` (`0x138CE`) runs every frame for `Race_StaticActorList`
(`$FF2EAA`/`$FF2F2A`, type `$10`):

1. If the player is on foot (`$68` bit4), skip all.
2. For an inactive actor (`$68` bit6 clear) with `$56 == $FFFF`, draw a new respawn
   timer: `timer = ((Rand & $FFF) * unk_13A1A[Menu_ram_PlayerLevel]) >> 16`.
   - palette `$73` = 0 or 2 from timer bit0;
   - side: timer bit2 clear -> `$30 = $70` and `$69` bit3 clear; set -> `-$70` and
     bit3 set;
   - `$74 = (timer & $F0) >> 4` (profile 0..15);
   - Speed/curve offset `$12`/`$46` from `Race_StaticActionTable[profile]`.
3. For an active actor with `$56 != $FFFF` and `ProgressSnapshotB >= $708`, subtract
   `FrameDelay`; on expiry set `$56 = $FFFF` and call `sub_13A26`
   (X = `PlayerProgress + $208000`, `$68` bit6 set, motion fields cleared).
4. `Race_ClampActorY` later clears bit6 again if the actor drifts more than `$210000`
   from the player progress, so the pair cycles in/out of the visible band.

`unk_13A1A` = `FFFF, B333, 8000, 4CCC, 3333, 2222`, indexed directly by
`Menu_ram_PlayerLevel`; larger values mean longer waits. The `FFFF` word is the index-0
entry (not used by levels 1..5).

## Extra static actor (`$FF2FAA`, index `$12`)

- `Race_CreateActors` only sets `$71 = $12`; the slot is otherwise inactive.
- `Race_BuildTrackObjects` writes `ram_FF1B30 = $FFFF` each frame and, when the
  `shape $186` track object is inside the projected object window, replaces it with the
  object's slot position and `ram_FF1B2E` with the run length.
- `Race_Update`: `ram_FF1B30 < 0` (`$FFFF`) -> clear `$68` bit6; `>= $1C` and bit6
  clear -> `Race_InitExtraStaticActor`; then `Race_UpdateExtraStaticActor`.
- Init (only when `ProgressSnapshotB >= $708`): set bit6; palette 0/2 from Rand bit0;
  X = `(PlayerProgress_integer + ram_FF1B30 - 1) << 16`; Y = `±(Rand & $7FF)`
  (`$69` bit3 selects the sign); `$12 = $1770`; clear `$32`.
- Update: after `ProgressSnapshotB >= $708`, steer against the static pair and adjust
  `$14`/`$12`/`$30`; clamps Speed to `$1770`. It does not register target candidates.
- Role (police/traffic/pacer) is still `[hypothesis]`; only the lifecycle is confirmed.

## Actor setup/recycle

- `Race_SetupActor` (`0x16D9A`): `Track_CurveBuffer` at the actor position ->
  `+$8/+$C`; clear `$68` bits 4/0; `+$2C`, `+$5C = ram_FF18A8`, `+$6E = $FF`;
  zero `+0/$A/$2/$32/$36/$38/$3A/$3C`; `+$1A/+0` from `+$30`; call `Race_SetupActorSprite`.
- `Race_RecycleOpponent` (`0x16C9A`): push to `Race_ram_OpponentFreeList`; remove from active.
- `Race_ActivateActor` (`0x16D0A`): append to `Race_ram_ActiveActorList`, count++.
- `Race_RemoveActiveActor` (`0x16E26`): shift the list, count--.
- `Race_PushFreeActor` (`0x16E48`) / `Race_PopFreeActor` (`0x16E54`): free-list
  push/pop, `$FFFFFFFF` when empty.

## Distance helpers

- `Race_GetActorDistance` (`0x16BC8`): `actor[+$66] * Race_ram_ActorDistanceScale >> 16`.
- `Race_CheckOpponentAhead` (`0x16B6A`): recycle if the distance is more than
  `Race_ram_PlayerProgress + $20`; exempts the reserved opponent; `$FFFFFFFF` result.
- `Race_CheckTrafficBehind` (`0x16B9E`): recycle if the distance is behind
  `Race_ram_PlayerProgress - $10`; `$FFFFFFFF` result.

## Speed display

`Race_UpdateSpeedDisplay` (`0xF108`): `d0 = Speed >> 7`, `d1 = d0 >> 2`,
`d0 += d1`, `Race_FormatDecimal` -> packed decimal in `d1`; store
`Race_ram_SpeedDisplay` (the 98C2 debug and HUD speed readout).

`Race_FormatDecimal` (`0xF11C`): converts a 16-bit value to a packed 5-digit decimal
(used by the debug readouts, speed and other HUD values).

## Data5 spawn record format

`Race_SpawnOpponents` expands 4-byte records from `RaceTrack_Data5` into two lists and
terminates both with `$FFFFFFFF`:

- `ram_FFD7D4` **normal list** -> `Race_AddStagedObjects` (road/track objects; record
  byte 2 is the object type);
- `ram_FFDBD8` **special list** -> `sub_13BF4` (reserved opponent; record byte 2 is the
  per-level colour/page byte from `off_B98A`).

| Field | Meaning |
|---|---|
| high word | world X (16.16 high word) for the object/reserved spawn |
| bit4 | randomize the low nibble (`Rand & $F`) |
| bit5 | route to the special list and replace byte 2 with `off_B98A[Menu level][count]` |
| byte 2 | normal: object type; special: colour/page index (capped by `word_B980`) |
| bits 0-3 | lane/spawn offset (`*$20 - $100`) |
| other bits | preserved flags |

Per-level gates: `word_B976` = random-acceptance threshold
(`CCCC, B333, 9999, 8000, 6666`), `word_B980` = special-list cap (`1,2,3,4,4`),
`off_B98A` = five colour lists (`{2,0}`, `{1,3}`, `{1,2,4,0}`, `{1,2,3,5}`,
`{1,2,3,4}`); the normal list is additionally capped at `$FF` entries. See
`docs/analysis/race_track_data.md` for the stream bytes.

## E5 dynamic results

Runs: `analysis/capture_L5.gdb`, `capture_L5b.gdb`, `capture_L5c.gdb`; traces in
`analysis/notes/L5*.txt` (921-4200 frame demo windows).

| Check | Breakpoint / window | Observed | Decision |
|---|---|---|---|
| E5-1 `Data5` expansion | `0xB970`, demo level 1 | `d7=$CCCC`, `d6=1`; normal list starts `00A70218, 01A50118, ...`; special list starts `02D6022F, FFFFFFFF`; cursors `FFD824`/`FFDBDC` | confirmed |
| E5-2 special-list consumer | forced player X/progress past `$02D60000`, `0x13CFE` | `ram_FF1F2A` X=`$02D60000`, `Race_ram_LevelIndex=2` (record byte 2), lane `$30=$E0`, Speed `$050C`, cursor advanced to the terminator | confirmed forced |
| E5-3 static assignment | `0x1397E`, demo | actor `$FF2EAA`/`$FF2F2A`; profiles `0E,01,07,0D,05`; timers `$E2,$17,$474,$7D6,$415,$257`; palette/side/Y and `$12/$46` match `Race_StaticActionTable` | confirmed |
| E5-4 static respawn | `0x13A26`, demo | 3 natural respawns; `PlayerProgress` values increasing | confirmed (X recomputed inside; E3-5 already checked the formula) |
| E5-5 extra actor | `0x10B2E`/`0x12972`/`0x12A86`, demo | marker write `$11` at progress `$00078000`; later init at progress `$01E84C52`, X=`$02060000`, Y=`$FEC8`, Speed `$1770`, `$68=$40`, palette 0; 130 update calls | confirmed |
| E5-6 natural traffic spawn | `0x16AF6`/`0x16D2A`/`0x16D60`/`0x16CAE`, 631 race ticks | 0 opponent/traffic spawns and 0 recycles; active count stayed 8, so the free-list path is not exercised by the demo | `[static]` only |

Notes:

- The 631 race ticks in the 4200-frame window mean the demo spends most frames in
  non-race screens; the spawn gates (`ActiveActorCount >= 6`, `SpawnTimer`) never
  opened a natural spawn.
- E5-2 was forced by moving the player past the first special record; the consumed
  record, page index, lane and state all agree with `sub_13BF4`/`sub_13CFE`.
- The extra actor's role remains a hypothesis; the activation/deactivation and the
  `shape $186` marker dependency are confirmed.

## Open questions

- Reserved opponent role/page semantics: byte 2 selects generic bike graphics
  (index 5..9) and a definition page; whether it is a police/rival narrative actor is
  `[hypothesis]`.
- Extra actor role (`$FF2FAA`) is unknown beyond its lifecycle.
- Natural traffic/opponent respawn was not triggered by the demo (E5-6); a long
  non-demo run or a forced count drop is the remaining dynamic check.

## Applied renames

- R11: `Race_ram_ActiveActorList`, `Race_ram_ActiveActorCount`,
  `Race_ram_OpponentFreeList`, `Race_ram_TrafficFreeList`.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `Race_ram_ActiveActorList` | `Race_ActiveActorList` | active list | high |
| `Race_ram_OpponentFreeList`/`Race_ram_TrafficFreeList` | `Race_OpponentFreeList`/`Race_TrafficFreeList` | free lists | high |
| `ram_FF1F2A` | `Race_ReservedOpponent` | reserved `Race_ActorList[1]`, `sub_13BF4` lifecycle | medium |
| `ram_FFDBD4`/`ram_FFDBD8` | `Race_SpecialSpawnCursor`/`Race_SpecialSpawnList` | `Data5` special list | high |
| `unk_13A1A` | `Race_LevelRespawnScale` | per-level static respawn scale | medium |
| `ram_FF1B32`/`ram_FF1B34`/`ram_FF1B36`/`ram_FF1B3A` | `Race_ReservedSpawnTimer`/`Race_ReservedSpawnOffset`/`Race_ReservedSpawned`/`Race_ReservedLastDistance` | `sub_13BF4` | medium |

## L1 actor-core static pass (2026-11-12)

- **Init split:** `Race_InitActorLists` builds `ram_FF1A08` = PlayerA +
  `Race_ActorStruct_9..15` (8 entries) and `Race_ram_OpponentFreeList` =
  `Race_ActorStruct_2..8` (7 entries), matching `actor_post_create_ram.bin`.
  `Race_ram_ActiveActorList` (`$FF1A0C`) then aliases the last 7 entries of
  `ram_FF1A08`, so it holds the opponents while the count still includes PlayerA.
- **`Race_SpawnOpponent` special case:** if the pop returns `ram_FF1F2A` and its
  `ControlFlags` bit6 is already set, activation/init are skipped.
- **`Race_CheckOpponentAhead`:** the reserved opponent is exempt, and recycling only
  starts once `PlayerProgress + $20 >= RaceTrack_Data1` (track-end threshold) and the
  actor is ahead of that value.
- **`Race_SetupActor` detail:** samples `Track_CurveBuffer` at
  `((X & $FF) * 2 + $C) & $1FF` into `$08` and `$0C`; clears `ControlFlags` bits 4/0;
  sets `$5C = ram_FF18A8`, `AnimState = $FF`; zeroes
  `$00/$02/$0A/$2C/$32/$36/$38/$3A/$3C`; makes `$30` positive and copies it to
  `$1A` and `$00`; then calls `Race_SetupActorSprite` (which consumes ambient `d4`;
  E2 saw `d4=0` on every spawn call, closing `U-0011`).
- **Recycle:** `Race_RecycleActor` stores `X / Race_ram_ActorDistanceScale` (long high
  word) into `$66` for reuse as a distance; `Race_RecycleOpponent` only moves the
  pointer between lists.
- Field ownership is authoritative in `docs/analysis/race_map.md`.

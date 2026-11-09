# Analysis: `src/race/race.asm` actors (riders/opponents)

- **Module:** actor/rider initialization for the race
- **Source:** `src/race/race_core.asm` (`Race_CreateActors` `0xCAD0`, `Race_InitActorLists`
  `0xB6C4`-area, `Race_InitActorPositions`), `src/data/race_actor_tables.asm`
  (pointer/graphics tables from the ROM gap), `src/race/race_spawn.asm` (dynamic spawn).
- **Status:** static tables + dynamic init/running snapshots; field semantics partly
  confirmed, AI/physics fields still TODO
- **Related:** `docs/analysis/race.md`, `docs/analysis/combat.md`,
  `docs/analysis/race_ai.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Actor pointer lists

| Label | Address | Contents |
|---|---|---|
| `Race_ActorList` | `0x25856` | 16 long pointers + `$FFFFFFFF`: player A `$FF1EAA`, opponents `$FF1F2A`..`$FF262A` (0x80 apart); now assembled from `src/data/race_actor_tables.asm`. |
| `Race_ActorListMid` | `0x2585E` | Free-opponent sub-list used by `Race_InitActorLists`; 7 entries in the demo snapshot. |
| `Race_StaticActorList` | `0x2589A` | `$FF2EAA`, `$FF2F2A`, sentinel: static actors (type `$10`, indices `$10/$11`). |

- Actor struct size: `$80`; player A `$FF1EAA`, player B `$FF26AA`; the 15 opponents
  `$FF1F2A`..`$FF262A`; the static actors `$FF2EAA/$FF2F2A`; `$FF2FAA` is a further
  actor-like struct used by `Race_UpdateStaticActors` but **not** in the static list (TODO).
- `Race_InitActorLists` copies the actor pointers into `ram_FF1A08` / `ram_FF1982`
  (with the `Race_ActorListMid` sub-list); `Race_InitActorPositions` then sets the
  actor screen fields `+$1A/+$30` (alternating `$60±$40`, `$80000`, `$30000` steps).
- `[dynamic]` The demo snapshot confirms the split: active count is 8 =
  `RacePlayerA` + 7 opponents (`$FF232A`..`$FF262A`); the opponent free list has 7
  pointers (`$FF1FAA,$FF202A,$FF20AA,$FF212A,$FF21AA,$FF222A,$FF22AA`). `$FF1F2A`
  is outside both lists in this snapshot; its role is still TODO.

## Dynamic snapshots (2026-11-09)

Headless BlastEm/GDB captures in `analysis/dumps/`:

| Dump | Breakpoint | Contents |
|---|---|---|
| `actor_post_create_ram.bin` | `0xB72A` `Race_InitActorPositions` entry | after `Race_CreateActors`; definitions/init fields |
| `actor_post_positions_ram.bin` | `0xA544` after `jsr Race_InitActorPositions` | after `$00/$1A/$1E/$30` position initialization |
| `actor_running_ram.bin` | `0x10E66` `Race_UpdateActorAI`, PlayerA `$12` > 0 | demo race in motion |

Observed demo state: `Race_ram_Started=1`, active count `8`, active list =
`$FF1EAA,$FF232A,$FF23AA,$FF242A,$FF24AA,$FF252A,$FF25AA,$FF262A`; nearest target
`$FF232A`; PlayerA `Speed=$00EE`, `$14=$0022`, `$26=$00000682`; `FrameDelay=7`
(`Speed * 7 = $26`). Opponents have `Speed=$0111`/`$0118`, `$14=$27`/`$28`,
`$26=$777`/`$7A8`. `$FF26AA` (player B) and `$FF2FAA` remain zero except the latter's
`$71=$12`; the static actors `$FF2EAA/$FF2F2A` diverge from normal actors after the
update (`$16` becomes 0, `$30=$8000`, `$46=-$11/ +$10`, `$56=$E2/$17`, `$74=$0E/$01`).

## Actor definitions (`Race_ActorDefinitionTable`, `0xCCDA`)

`Race_ActorLevelBase` (`0xCCD0`) = the first opponent id per level: `0,15,30,45,60`.

76 entries of 16 bytes: five pages of 15 opponents (levels 1-5) followed by the
**player definition** id `0x4B` (`"Player def"`, all fields zero).

| Byte | Destination | Meaning |
|---|---|---|
| 0 | `+$16` | actor type/sprite (2..10). |
| 1 | `+$74` | unknown (1..18). |
| 2 | `+$75`, `+$6B` bit1 | low 7 bits = graphics index; bit7 = special flag. |
| 3 | `+$73` | 2 for all opponents (palette/team? TODO). |
| 4 | `+$77` | 3/5/10/7/1 per level (class/tier? TODO). |
| 5 | `+$66` | actor rating ×100 (70..120); player def = 0. |
| 6..15 | - | 10-char name (standings/tooltips; not copied into the actor). |

Examples: level 1 = O'Leary..Dread (ids 0-14); level 2 = O'Rourke..Dread (15-29);
level 3 = Flynn..Viper (30-44); level 4 = O'Shea..Spike (45-59); level 5 =
O'Connor..Butch (60-74); id 75 = `Player def`.

`Menu_ram_PlayerAOpponents`/`B` is built by `sub_8946`/the password as
`[$4B, level*15+0 .. level*15+14]`: the player definition followed by the level's 15
opponents. `Race_CreateActors` walks `Race_ActorList` and this id list in parallel.

## Actor struct fields written by `Race_CreateActors`

| Offset | Source / meaning |
|---|---|
| `+$71` | actor index (`0,1,2,...`; static group `$10+`). |
| `+$16` | definition byte 0 (type/sprite). |
| `+$74` | definition byte 1 (unknown). |
| `+$75` | definition byte 2 low 7 bits (graphics index). |
| `+$6B` bit1 | definition byte 2 bit 7 (special flag). |
| `+$5E`/`+$60`/`+$5C` | graphics entry `+$A/+$C/+$E` (sprite fields; player A overrides from `ram_FF18B2/B4/AA`). |
| `+$73`/`+$77` | definition bytes 3/4. |
| `+$66` | definition byte 5 ×100 (rating/skill). |
| `+$6E`/`+$6F` | `$FF` (initial animation/limit). |
| `+$56` | `$FFFF`. |
| `+$08/$0A/$0C/$14/$1C/$22/$24/$26/$2C/$32/$36/$38/$3A/$3C/$46/$68/$69/$6A/$72/$78` | zeroed. |
| `Speed` (`+$12`), `Gear` (`+$18`) | zeroed here; set by the physics/input. |
| `+$5C` player A | `ram_FF18AA` (tile base `$A00`); `+$5E/+$60` = `ram_FF18B2/B4` (`$400/$180`). |

The player definition (`$4B`) is all zero; the player's real stats come from
`Race_LoadBikeData`/`Race_InitPhysicsConstants` and the input/physics. The player B
struct `$FF26AA` is not in `Race_ActorList` (2P/inactive state; TODO).

## Actor field matrix (current evidence)

`[dynamic]` values below are from the demo snapshots; `[static]` from the source.
Widths follow the actual instructions. `$04` is read as a **long** in several
routines; `+$06` is its low word, not an independent X coordinate.

| Offset | Width | Role / status | Evidence |
|---|---|---|---|
| `+$00` | word | screen/draw Y copy; equals `+$1A/+$30` after init | `[dynamic]`; source uses `0(a1)` |
| `+$02` | word | `PosZ` (existing name) | `[static]` endlevel/HInt |
| `+$04` | long | current X position; `PosXHigh/Low` are one 32-bit value | `[dynamic]` changes `$80000 -> $80682` while `+$1E` stays `$80000`; `[static]` `move.l 4(a1)` |
| `+$06` | word | low word of `+$04`; no separate field | same |
| `+$08`/`+$0A`/`+$0C` | word | unknown animation/impact registers; zero in snapshots | `[dynamic]`; writes in `race_anim_audio` |
| `+$12` | word | `Speed` | `[confirmed]` PlayerA `$EE`, opponents `$111/$118` |
| `+$14` | word | acceleration per frame; added to Speed with FrameDelay | `[confirmed]` PlayerA `$22`, opponents `$27/$28`; `Race_UpdateActorAI` `$10E66` |
| `+$16` | word | `Type`/sprite from definition byte0 | `[confirmed]` 2/3/4; static actors anomaly below |
| `+$18` | word | `Gear` | `[static]`; zero in demo |
| `+$1A` | word | draw/screen Y; initialized equal to `+$00/+$30` | `[dynamic]`; exact distinction from `+$00` TODO |
| `+$1C` | word | unknown; zero in snapshots | `[dynamic]` |
| `+$1E` | long | spawn/start X; stays at spawn value while `+$04` advances | `[dynamic]` PlayerA `$80000`, Opp `$110000`; writes in `Race_InitActorPositions`/spawn |
| `+$22`/`+$24` | word | unknown movement/steering state; zero in no-steer demo | `[dynamic]` |
| `+$26` | long | frame distance = `Speed * Race_ram_FrameDelay` | `[confirmed]` Player `$EE*7=$682`, Opp `$111*7=$777`, `$118*7=$7A8` |
| `+$2A` | word | screen/road Y offset; source derives from `+$02`/road value | `[dynamic]` `-$08`; exact role TODO |
| `+$2C`/`+$2E` | word | impact/speed fraction pair; source writes from Speed | `[static]`; zero in demo |
| `+$30` | word | `PosY` | `[dynamic]` `$A0`/`$20`; `[static]` HUD/HInt |
| `+$32` | word | road/target Y candidate; zero in demo | `[dynamic]` |
| `+$36`/`+$38`/`+$3A`/`+$3C` | word | road/target/lean accumulators | `[static]` writes; zero in no-steer demo |
| `+$3E`/`+$40`/`+$42` | word | lean/curve state | `[static]` `Race_UpdateBikeCurve`; zero in demo |
| `+$46` | word | curve/direction sign; AI flips it | `[static]`; zero in demo |
| `+$4A` | word | collision/proximity extent | `[dynamic]` `$0D` active; `[static]` `Race_UpdateCollision` |
| `+$4C`/`+$4E` | word | left/right sprite/collision extents | `[dynamic]` `$0D/0` or `$0D/$0D`; exact role TODO |
| `+$56` | word | sentinel/timer; `$FFFF` normal actors | `[dynamic]` `$FFFF`; static `$E2/$17` |
| `+$5A` | word | attack/impact cooldown | `[static]/[dynamic]` combat; zero in demo |
| `+$5C` | word | tile/animation base | `[confirmed]` Player `$A00 -> $507`; graphics table |
| `+$5E`/`+$60` | word | sprite graphics fields | `[confirmed]` Player `$400/$180`; graphics table |
| `+$66` | word | rating/skill; lifecycle value | `[confirmed]` definition byte5*100; spawn uses as `Speed`, recycle as distance |
| `+$68` | byte | flags; bit6 = active/update marker (set for player + active opponents) | `[dynamic]` active `$42`, inactive `$00`; source `Race_UpdateActorAI` |
| `+$69` | byte | state/attack flags; bit4/5/6 attack, bit1 steering | `[confirmed]` combat + `[static]` AI writes |
| `+$6A` | byte | animation/impact flags; bit7 used in animation code | `[static]`; zero in demo |
| `+$6B` | byte | bit0 high attack, bit1 armed/special | `[confirmed]` Player `$00`, armed opponent `$02` |
| `+$6C`/`+$6D` | byte | attack phase/timer | `[confirmed]` combat |
| `+$6E`/`+$6F` | byte | animation state/frame; `$FF` normal, 0 static | `[dynamic]`; role hypothesis |
| `+$70` | byte | animation timer | `[static]` animation; zero active |
| `+$71` | byte | actor index | `[confirmed]` 0..15, static `$10/$11`, extra `$12` |
| `+$72` | byte | animation frame/index written by `Race_SetupActorSprite` | `[static]/[dynamic]` values 3/5 |
| `+$73`/`+$74`/`+$75`/`+$77` | byte | definition bytes 3/1/2/4; `+$74` AI profile, `+$75` graphics index | `[confirmed]` |
| `+$78` | byte | animation/state flag; zero in snapshots | `[dynamic]`; TODO |
| `+$7E` | word | unknown; zero in snapshots | `[dynamic]` |

**Structure-base warning:** raw offset greps are misleading. `Race_BuildVScrollInfo`
uses `a0 = Race_ram_CurrentVScrollInfo` and writes `$1E/$2A/$4A/$4E/$56/$66/$68/$6E/$70/$72`
there; these are **VScroll buffer fields**, not actor fields. Only count `a0` accesses
after verifying that `a0` is an actor pointer; `a1/a2` are actor pointers in the race
lists.

## Graphics table (`Race_ActorGraphicsTable`, `0x258EE`)

Words at `+$A/+$C/+$E` selected by the definition's graphics index:

| Idx | `+$A` | `+$C` | `+$E` |
|---|---|---|---|
| 0 | `$0100` | `$0080` | `$0500` |
| 1 | `$0180` | `$00A0` | `$0640` |
| 2 | `$0200` | `$00C0` | `$0780` |
| 3 | `$0280` | `$0100` | `$08C0` |
| 4 | `$0300` | `$0100` | `$0A00` |
| 5..9 | `0` | `0` | `$0A00` |

`+$E` looks like the tile base (`$500`..`$A00`); `+$A/+$C` are sprite-size/position-like
values. The exact semantics and the 1:1 mapping to rider graphics are TODO.

## Static actor group

`Race_StaticActorList` = `$FF2EAA`, `$FF2F2A`; `Race_CreateActors` sets `+$16=$10`,
`+$71` from `$10`, zeroes `+$74/+$75/+$68/+$69/+$6A`, `+$56=$FFFF`, then writes the
group's start values (`ram_FF2EAA/$2F2A/$2F2E/$2F9D/...`). It is likely the police /
special traffic actor; the exact role is TODO.

`[dynamic]` After the running update these two structs no longer look like normal
racers: `+$16` becomes `0`, `+$30=$8000`, `+$46=-$11`/`+$10`, `+$56=$E2`/`$17`,
`+$74=$0E`/`$01`, and `+$69` is `0`/`$08`. That suggests `Race_UpdateStaticActors`
reuses the `$80`-byte slots with a phase-specific field layout or a different
structure; do not apply normal actor names blindly to `$FF2EAA/$FF2F2A` until the
static updater is analyzed.

`[dynamic]` `$FF2FAA` is zero except `+$71=$12` in both demo snapshots; it is not in
the active/free/static lists. Its owner and purpose remain open.

## Actor lifecycle notes

- `Race_CreateActors` sets definition-derived fields and zeroes many motion fields.
- `Race_InitActorPositions` writes `+$00`, `+$1A`, `+$30` (same Y value) and
  `+$04`, `+$1E` (same X value) for the initial positions.
- Later `Race_Spawn`/`Race_InitOpponentActor`/`Race_InitTrafficActor` overwrite
  `+$1E` (spawn X), `+$12` (from `+$66`), and other state.
- `Race_RecycleActor` reuses `+$66` as a distance value before recycling; this is
  why a single name like `Rating` is too narrow for `+$66`.
- `Race_UpdateActorAI` then updates `+$12` from `+$14`, writes `+$26`, and the
  active/physics/AI fields.

## Open questions

- Exact roles of `+$00` vs `+$1A` vs `+$30`; `+$1E` (spawn/start X) needs a
  steering/acceleration snapshot to confirm it stays fixed.
- `+$22/+$24/+$32/+$36/$38/$3A/$3C/$3E/$40/$42/$46` under active steering/off-road.
- `+$2A` origin/role and `+$4A/$4C/$4E` collision/sprite extents.
- `+$56` sentinel/timer and `+$68` bit roles; especially bit1 vs bit6 on active actors.
- Static group `$FF2EAA/$FF2F2A` and `$FF2FAA`; player B (`$FF26AA`) is zero in demo.
- Which fields are copied/overwritten by `Race_SpawnOpponent`/`Race_RecycleActor`.
- Next dynamic tests: steer left/right, accelerate/brake, off-road, 2P/player B,
  static/police appearance. Use `docs/reverse-engineering.md` experiment format.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `+$04` | `ActorX` (long) | `move.l 4(a1)`; dynamic current X; `$06` is its low word | high |
| `+$06` | `ActorXLow` (word) | low half of `+$04`, not a separate coordinate | high |
| `+$14` | `ActorAcceleration` | added to Speed in `Race_UpdateActorAI`; dynamic `$22/$27/$28` | high |
| `+$1E` | `ActorSpawnX` (long) | set at init/spawn; stays fixed while `+$04` advances | medium |
| `+$26` | `ActorFrameDistance` | `Speed * Race_ram_FrameDelay`; dynamic exact | high |
| `+$66` | `ActorRating`/`ActorSkill` | definition byte5*100; also speed seed/distance at spawn/recycle | medium |
| `+$68` | `ActorFlags` | bit6 active/update marker; multiple AI bits | medium |
| `+$5C` | `ActorTileBase` | graphics +$E / `ram_FF18AA`; dynamic animation base | medium |
| `+$5E`/`+$60` | `ActorSpritePosX/Y` | graphics +$A/+$C | low |

Applied in Batch 3a: `+$02/+$04/+$06/+$12/+$16/+$18/+$30/+$71/+$75` ->
`RaceActor_PosZ/PosXHigh/PosXLow/Speed/Type/Gear/PosY/Index/GraphicsIndex`.

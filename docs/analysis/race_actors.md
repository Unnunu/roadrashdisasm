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
- `Race_InitActorLists` copies the actor pointers into `ram_FF1A08` / `Race_ram_OpponentFreeList`
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
| `actor_steer_left_ram.bin` | `0x10E66`, `RaceBike_ram_CurrentSteering=-$600` each frame | 90-frame forced left steering |
| `actor_steer_right_ram.bin` | same, `CurrentSteering=+$600` | 90-frame forced right steering |
| `actor_offroad_left_ram.bin` | same, 300 frames of forced left steering | hard-left/likely off-road state |

Observed demo state: `Race_ram_Started=1`, active count `8`, active list =
`$FF1EAA,$FF232A,$FF23AA,$FF242A,$FF24AA,$FF252A,$FF25AA,$FF262A`; nearest target
`$FF232A`; PlayerA `Speed=$00EE`, `$14=$0022`, `$26=$00000682`; `FrameDelay=7`
(`Speed * 7 = $26`). Opponents have `Speed=$0111`/`$0118`, `$14=$27`/`$28`,
`$26=$777`/`$7A8`. `$FF26AA` (`RacePlayerB`, a range marker in sequential 2P) and `$FF2FAA` remain zero except the latter's
`$71=$12`; the static actors `$FF2EAA/$FF2F2A` diverge from normal actors after the
update (`$16` becomes 0, `$30=$8000`, `$46=-$11/ +$10`, `$56=$E2/$17`, `$74=$0E/$01`).

Forced steering snapshots: PlayerA `Speed=$2D15`, `$14=$000E`, `$26=$00013B93`,
`$04=$004CD697`, `$1E=$004B9B04` (so `$04 = $1E + $26`), `$69=$04`, and
`$42=-$0049` (left) / `+$0049` (right). `$00=$35`, `$1A=$31`, `$30=$35`; `$22=$09`,
`$36=$05`, `$38=$022B`, `$3A=$03`, `$3C=$00`, `$46=-$03` in both directions. This
confirms `$04/$1E/$26` are current/previous X and per-frame distance, and `$42` is
the signed lean/curve value.

Long forced left (300 frames): PlayerA `Speed=$2CEE`, `$00=$FF89`, `$1A=$FFE4`,
`$30=$FFEA`, `$36=$FF9F`, `$38=$FFFC`, `$3A=$0A5F`, `$3C=$FFF9`, `$42=$FFB6`,
`$46=$FFFD`, `$4A=$0E`, `$4C=$0C`, `$4E=$0F`, `$68=$42`, `$69=$07`. `$68` bit3
remained clear, so this is a **hard-curve** snapshot; it does not yet prove off-road
detection. `$69` bits0/1/2 are all set in this state.

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
`Race_LoadBikeData`/`Race_InitPhysicsConstants` and the input/physics.

`[dynamic]` 2P is **sequential, not split-screen**: the same race code runs once for
player A, then for player B; only the HUD name changes. `Race_CreateActors` chooses
`Menu_ram_PlayerA/BOpponents` via `Menu_ram_Player`, `Race_GetInput` selects pad A/B
via `Race_ram_ActiveController`, and the HUD uses `Menu_ram_Player` for the name.
`RacePlayerB` (`$FF26AA`) is not in `Race_ActorList` and stays zero; it is not a
second live actor in this mode. The `cmpa.l #RacePlayerB` checks are pointer-range
bounds around the player/actor region, not a concurrent player-B actor.

## Actor field matrix (current evidence)

`[dynamic]` values below are from the demo snapshots; `[static]` from the source.
Widths follow the actual instructions. `$04` is read as a **long** in several
routines; `+$06` is its low word, not an independent X coordinate.

| Offset | Width | Role / status | Evidence |
|---|---|---|---|
| `+$00` | word | current screen/draw Y; source uses `0(a1)` | `[dynamic]` steering `$35`; hard-left `$FF89`; no-steer `$A0` |
| `+$02` | word | `PosZ` (existing name) | `[static]` endlevel/HInt |
| `+$04` | long | current X position; `RaceActor_X/XLow` are one 32-bit value | `[confirmed]` `$04 = $1E + $26` in all snapshots |
| `+$06` | word | low word of `+$04`; no separate field | same |
| `+$08`/`+$0A`/`+$0C` | word | unknown animation/impact registers; zero in snapshots | `[dynamic]`; writes in `race_anim_audio` |
| `+$12` | word | `Speed` | `[confirmed]` PlayerA `$EE`, opponents `$111/$118`; steering `$2D15` |
| `+$14` | word | acceleration per frame; added to Speed with FrameDelay | `[confirmed]` `$22` low speed, `$0E` at `$2D15`; `Race_UpdateActorAI` |
| `+$16` | word | `Type`/sprite from definition byte0 | `[confirmed]` 2/3/4; static actors anomaly below |
| `+$18` | word | `Gear` | `[static]`; zero in demo |
| `+$1A` | word | previous draw/road Y copied from `+$30` at `Race_UpdateActorX` entry | `[dynamic]` steering `$31` vs `$30=$35`; hard-left `$FFE4` |
| `+$1C` | word | unknown; zero in snapshots | `[dynamic]` |
| `+$1E` | long | previous X; `Race_UpdateActorX` copies current `+$04` here before adding `+$26` | `[confirmed]` `$04-$1E=$26`; initial spawn value before movement |
| `+$22`/`+$24` | word | X/Y screen delta/velocity; `$22` non-zero under steering | `[dynamic]` `$09/0` steering; zero no-steer |
| `+$26` | long | frame distance = `Speed * Race_ram_FrameDelay` | `[confirmed]` Player `$EE*7=$682`, Opp `$111*7=$777`; steering `$2D15*7=$13B93` |
| `+$2A` | word | screen/road Y offset; source derives from `+$02`/road value | `[dynamic]` `-$08` no-steer, `$223` steering; exact role TODO |
| `+$2C`/`+$2E` | word | impact/speed fraction pair; source writes from Speed | `[static]`; zero in snapshots |
| `+$30` | word | current road/target Y; `+$1A` keeps the previous value | `[dynamic]` steering `$35`; hard-left `$FFEA`; no-steer `$A0` |
| `+$32` | word | `RaceActor_CollisionOffset`; projected collision penetration; zero outside collisions | `[static/dynamic]`; R25 |
| `+$36`/`+$38`/`+$3A`/`+$3C` | word | `$36` road-Y target offset, `$38` curve delta, `$3A` curve accumulator, `$3C` curve step | `[static/dynamic]` steering `5/$22B/3/0`; see `race_movement.md`; names deferred |
| `+$3E`/`+$40`/`+$42` | word | curve/lean state; `$42` signed | `[confirmed]` `$42=-$49` left, `+$49` right; `$3E/$40` zero in test; R22/R23 names `Curve`/`LeanCurve` |
| `+$46` | word | curve/direction sign; AI flips it | `[dynamic]` `-$03` under forced steering |
| `+$4A` | word | collision/proximity extent | `[dynamic]` `$0D` active, `$0E` hard-left; `[static]` `Race_UpdateCollision` |
| `+$4C`/`+$4E` | word | collision extents toward smaller/larger Y: `CollisionExtentUpper`/`Lower` | `[static]` side index 0/1 + Y ordering; dynamic `$0C/$0F`; R27 |
| `+$50` | word | attack reach/knockback | `[dynamic]` armed `$28`, unarmed `$19`; `Race_GetAttackerReach` |
| `+$52` | word | overlap/penetration | `[dynamic]` `$42` armed / `$33` unarmed |
| `+$56` | word | sentinel/timer; `$FFFF` normal actors | `[dynamic]` `$FFFF`; static `$E2/$17` |
| `+$5A` | word | attack/impact cooldown | `[static]/[dynamic]` combat; zero in demo |
| `+$5C` | word | tile/animation base | `[confirmed]` Player `$A00 -> $507`; graphics table |
| `+$5E`/`+$60` | word | sprite graphics fields | `[confirmed]` Player `$400/$180`; graphics table |
| `+$66` | word | rating/skill; lifecycle value | `[confirmed]` definition byte5*100; spawn uses as `Speed`, recycle as distance |
| `+$68` | byte | flags; bit6 = active/update marker (set for player + active opponents) | `[dynamic]` active `$42`, inactive `$00`; source `Race_UpdateActorAI` |
| `+$69` | byte | state/attack flags; bit4/5/6 attack, bit2 set under steering | `[confirmed]` combat; `[dynamic]` steering `$04`, hard-left `$07` |
| `+$6A` | byte | animation/impact flags; bit7 used in animation code | `[static]`; zero in demo |
| `+$6B` | byte | bit0 high attack, bit1 armed/special | `[confirmed]` Player `$00`, armed opponent `$02` |
| `+$6C`/`+$6D` | byte | attack phase/timer | `[confirmed]` combat |
| `+$6E`/`+$6F` | byte | animation state/frame; `$FF` normal, 0 static | `[dynamic]`; role hypothesis |
| `+$70` | byte | animation timer | `[static]` animation; zero active |
| `+$71` | byte | actor index | `[confirmed]` 0..15, static `$10/$11`, extra `$12` |
| `+$72` | byte | animation frame/index written by `Race_SetupActorSprite` | `[static]/[dynamic]` values 3/5 |
| `+$73`/`+$74`/`+$75`/`+$77` | byte | definition bytes 3/1/2/4; `+$74` AI profile, `+$75` graphics index, `+$73` palette | `[confirmed]`; R23 |
| `+$78` | byte | animation/state flag; zero in snapshots | `[dynamic]`; TODO |
| `+$7E` | word | unknown; zero in snapshots | `[dynamic]` |

**Structure-base warning:** raw offset greps are misleading. `Race_BuildVScrollInfo`
uses `a0 = Race_ram_CurrentVScrollInfo` and writes `$1E/$2A/$4A/$4E/$56/$66/$68/$6E/$70/$72`
there; these are **VScroll buffer fields**, not actor fields. Only count `a0` accesses
after verifying that `a0` is an actor pointer; `a1/a2` are actor pointers in the race
lists.

### `$68/$69` flag map (static + dynamic)

| Byte | Bit | Current meaning | Evidence / confidence |
|---|---|---|---|
| `$68` | 0 | collision/impact lock; blocks normal steering | `[static]` `sub_1438E`/`Race_UpdateCollisionSpeedState`; medium |
| `$68` | 1 | throttle/B input; AI also sets it | `[static]` `Race_GetInput` B; active opponents `$42` |
| `$68` | 2 | brake/A input; reduces acceleration | `[static]` `Race_GetInput` A + `Race_UpdateActorSpeedState`; medium |
| `$68` | 3 | off-road/edge; reduces acceleration | `[static]` `Race_UpdateActorAI` edge tests |
| `$68` | 4 | on-foot/knockdown branch | `[static]` `Race_UpdateActorAI`; hypothesis |
| `$68` | 5 | lean/curve update enable | `[static]` `Race_UpdateLeanCurve` calls |
| `$68` | 6 | active/update marker | `[dynamic]` active `$42`, inactive `$00`; confirmed |
| `$68` | 7 | finish/timer stop | `[static]` race timer/finish paths; medium |
| `$69` | 0/1 | ahead/behind and above/below state | `[static]` `Race_UpdateActorPairCollision`; dynamic 0/2/3 |
| `$69` | 2 | steering active | `[dynamic]` forced steering `$04`/`$07` |
| `$69` | 3 | on-foot direction/stance | `[static]` `Race_HandleInputOnFoot`; medium |
| `$69` | 4/5/6 | attack active/side/low | `[confirmed]` combat tests |
| `$69` | 7 | contact/knockback flag | `[dynamic]` `$91` after pair contact; source pair collision |

`$FF2FAA` is aliased by `$FF2FAA+$71 = $FF301B`; `Race_CreateActors` writes
`$12` there, so it is the **third static-like actor slot** (indices `$10/$11` are the
static list). Its other fields remain zero in the demo. `Race_InitExtraStaticActor` initializes it
after `ProgressSnapshotB >= $708`; `Race_UpdateExtraStaticActor` updates it; collision paths also read
it. This is the best-supported **late-race police/static actor**, but the final role
is still a hypothesis.

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

`[dynamic]` Forced activation test (`ProgressSnapshotB=$800`,
`ram_FF1B30=$1C`) reached `Race_UpdateExtraStaticActor` with
`$FF2FAA`: index `$12`, type `0`, speed `$1770`, Y `$FEBC`, X `$00220000`,
`$68=$40` (active), `$69=0`. This confirms the late-race extra/static slot is
initialized and updated by that path; visual role remains police/static.

`[dynamic]` `$FF2FAA` is zero except `+$71=$12` in both demo snapshots; it is not in
the active/free/static lists. `Race_CreateActors` writes `$12` at `$FF2FAA+$71`, so
this is a third static-like slot; `Race_InitExtraStaticActor`/`Race_UpdateExtraStaticActor`/collision paths reference
it. `Race_InitExtraStaticActor` activates it when `Race_ram_ProgressSnapshotB >= $708`, sets `$68`
bit6, `$73` 0/2, `$30/$00/$1A`, `$69` bit3, `$12=$1770`, and a progress-derived X;
`Race_UpdateExtraStaticActor` then updates/moves it. This looks like a late-race **police/static**
actor, but the role is still a hypothesis.

`Race_UpdateStaticActors` only processes static actors with `$56==$FFFF` and `$68`
bit6. It uses `$16` as the `unk_25A10` type index, recomputes `$26`, calls
`sub_113A4`/`Race_UpdateActorMovement`/`Race_UpdateActorFallMovement`, then `$36+$38 -> $00`, `sub_137E4`,
`sub_12C9A`, `sub_13DE0`. The observed static `$16=0` after update is therefore an
open semantic question, not a reason to rename the field.

## Actor lifecycle notes

- `Race_CreateActors` sets definition-derived fields and zeroes many motion fields.
- `Race_InitActorPositions` writes `+$00`, `+$1A`, `+$30` (same Y value) and
  `+$04`, `+$1E` (same X value) for the initial positions.
- `Race_UpdateActorX` copies current X (`+$04`) to `+$1E`, then adds `+$26` to `+$04`;
  `+$1E` is therefore the previous/start-of-frame X during normal movement.
- Later `Race_Spawn`/`Race_InitOpponentActor`/`Race_InitTrafficActor` also initialize
  `+$1E`, `+$12` (from `+$66`), and other state.
- `Race_RecycleActor` reuses `+$66` as a distance value before recycling; this is
  why a single name like `Rating` is too narrow for `+$66`.
- `Race_UpdateActorAI` then updates `+$12` from `+$14`, writes `+$26`, and the
  active/physics/AI fields.

## Open questions

- Exact roles of `+$00` vs `+$1A` vs `+$30`; forced steering shows `$00=current
  screen Y`, `$1A=previous $30`, `$30=current road Y`.
- `+$22/+$24/+$32/+$36/+$38/+$3A/+$3C/+$3E/+$40/+$42/+$46` under off-road and
  other speeds.
- `+$2A` origin/role and `+$4A/$4C/$4E` collision/sprite extents.
- `+$56` sentinel/timer and `+$68` bit0/4/5/7 semantics; `$69` bit0/1/7 split.
- Static group `$FF2EAA/$FF2F2A` and `$FF2FAA` (index `$12`); 2P is
  sequential and uses `RacePlayerA` with the selected player data, while
  `$FF26AA` is a region bound/zero slot.
- Which fields are copied/overwritten by `Race_SpawnOpponent`/`Race_RecycleActor`.
- Next dynamic tests: brake/accelerate via native pad or after disabling demo mode,
  off-road, 2P/player B, static/police appearance. Steering/lean is covered by the
  left/right snapshots above.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|---|---|---|---|
| Initial field map | `0xB72A` before positions; `0xA544` after | definitions, zeroed fields, positions | creation/position lifecycle confirmed |
| Active/free split | GDB dump of `$FF1A08/$FF1982` | 8 active, 7 free; active starts `$FF232A` | 8+7 split confirmed |
| Speed/frame distance | `0x10E66`, Speed > 0 | `$EE/$111/$118`, `$26=$682/$777/$7A8`, FrameDelay 7 | `$26=Speed*FrameDelay` confirmed |
| Steering/lean | `CurrentSteering=±$600` each frame, 90 frames | `$42=∓$49`, `$69=$04`, `$04-$1E=$26` | `$42` signed lean; `$1E` previous X |
| Hard-left/off-road | 300 frames forced left | `$00=$FF89`, `$30=$FFEA`, `$69=$07`, `$4A/$4C/$4E=$0E/$0C/$0F` | hard-curve state; off-road bit3 not confirmed |
| Static/extra slots | running dump | static `$16=0`, `$30=$8000`; extra zero except `$71` | static layout/owner TODO |
| Brake/input injection | break at `0xBE6C` in demo | `Race_GetInputDemo` path, injected d0 ignored | use native pad or disable demo mode |

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `$1E` (literal) | `RaceActor_PreviousX` (long) | `Race_UpdateActorX` copies `+$04` here; `$04-$1E=$26` | high |
| `$68` | `RaceActor_Flags` | bit6 active/update marker; multiple AI bits | medium |
| `$5E`/`$60` | `ActorSpritePosX/Y` | graphics +$A/+$C | low |

Applied in R27: `RaceActor_CollisionExtentUpper` (`$4C`), `RaceActor_CollisionExtentLower` (`$4E`).

Applied in R25: `RaceActor_CollisionOffset` (`$32`).

Applied in R23: `RaceActor_LeanCurve` (`$40`), `RaceActor_Palette` (`$73`).

Applied in R22: `RaceActor_Curve` (`$3E`), `RaceActor_CurveDirection` (`$46`).

Applied in R21: `RaceActor_AnimState`, `RaceActor_AnimFrame`,
`RaceActor_AnimTimer`, `RaceActor_AnimIndex`.

Applied in R19: `RaceActor_PreviousX`, `RaceActor_CollisionExtent`,
`RaceActor_AttackReach`, `RaceActor_AttackOverlap`, `RaceActor_AttackCooldown`,
`RaceActor_ControlFlags`, `RaceActor_StateFlags`, `RaceActor_WeaponAnimFlags`,
`RaceActor_AttackFlags`, `RaceActor_AttackPhase`, `RaceActor_AttackTimer`,
`RaceActor_ActionProfile`. Added `ATTACK_PHASE_*` and static actor-index enums.

Applied in Batch 3a: `+$02/+$04/+$06/+$12/+$16/+$18/+$30/+$71/+$75` ->
`RaceActor_PosZ/X/XLow/Speed/Type/Gear/PosY/Index/GraphicsIndex`.

Applied in R1: `RaceActor_X` (`$04`), `RaceActor_XLow` (`$06`),
`RaceActor_Acceleration` (`$14`), `RaceActor_FrameDistance` (`$26`),
`RaceActor_Lean` (`$42`), `RaceActor_TileBase` (`$5C`),
`RaceActor_Rating` (`$66`).

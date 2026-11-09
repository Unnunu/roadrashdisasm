# Analysis: `race.asm` actors (riders/opponents)

- **Module:** actor/rider initialization for the race
- **Source:** `race.asm` (`Race_CreateActors` `0xCAD0`, `Race_InitActorLists`
  `0xB6C4`-area, `Race_InitActorPositions`)
- **Status:** analyzed statically (tables parsed from `baserom.md`); field semantics
  partly TODO
- **Related:** `docs/analysis/race.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Actor pointer lists

| Label | Address | Contents |
|---|---|---|
| `Race_ActorList` | `0x25856` | 16 long pointers + `$FFFFFFFF`: player A `$FF1EAA`, opponents `$FF1F2A`..`$FF262A` (0x80 apart). |
| `Race_ActorListMid` | `0x2585E` | Sub-list used by `Race_InitActorLists`; exact split TODO. |
| `Race_StaticActorList` | `0x2589A` | `$FF2EAA`, `$FF2F2A`, sentinel: static actors (type `$10`, indices `$10/$11`). |

- Actor struct size: `$80`; player A `$FF1EAA`, player B `$FF26AA`; the 15 opponents
  `$FF1F2A`..`$FF262A`; the static actors `$FF2EAA/$FF2F2A`; `$FF2FAA` is a further
  actor-like struct used by `sub_12868` but **not** in the static list (TODO).
- `Race_InitActorLists` copies the actor pointers into `ram_FF1A08` / `ram_FF1982`
  (with the `Race_ActorListMid` sub-list); `Race_InitActorPositions` then sets the
  actor screen fields `+$1A/+$30` (alternating `$60±$40`, `$80000`, `$30000` steps).
  The exact 8+7 split/grouping is TODO.

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

## Open questions

- Field meanings `+$73/+$74/+$77/+$66/+$5E/+$60/+$5C` need the physics/AI analysis.
- The 2P/player-B role, the `$FF2FAA` actor, and the `Race_ActorList` 8+7 split.
- The static group's purpose (police/traffic).
- Next: physics/AI (`Race_UpdateSpeedDisplay`, `Race_SpawnTick`, `sub_13xxx`), then the AS `RaceActor`
  struct (fields above + the existing `STRUCT_OFFSET_*`).

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `+$16` | `ActorType` | definition byte0 | high |
| `+$66` | `ActorRating` | definition byte5*100, divisor use | medium |
| `+$75` | `ActorGraphicsIndex` | definition byte2 low 7 bits | high |
| `+$5C` | `ActorTileBase` | graphics +$E / `ram_FF18AA` | medium |
| `+$5E`/`+$60` | `ActorSpritePosX/Y` | graphics +$A/+$C | low |

# Analysis: `src/race/race_ai_road.asm` (road profile, objects, visible list, standings)

- **Module:** road profile/height/curve, HScroll/marking tables, object/visible lists,
  sprite-tile staging, race standings/results, speed display
- **ROM range:** `0x00EB34`–`0x010DFF`
- **Status:** analyzed (L6a profile + L6b object/projection/visible-list contracts)
- **Source:** `src/race/race_ai_road.asm`
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_physics.md`,
  `docs/analysis/race_spawn.md`, `docs/modules/race_ai_road.md`, `docs/ram-map.md`

## Functions

Applied in R4: `Race_BuildActorObjectList`, `Race_AddSpecialObject`,
`Race_AddTrackStartObject`, `Race_AddStagedObjects`,
`Race_BuildTrackObjects`, `Race_ProjectTrackObject`,
`Race_ProjectObject`, `Race_ProjectActorObject`.

Applied in R20: `Race_ram_EventProgress`, `Race_ram_SpeedTier`.

Applied in R18: `Race_AddActorLeanObject`, `Race_AddActorImpactObject`,
`Race_AddActorFallObject`, `Race_AddActorWeaponObject`.

Applied in R15: `Race_SelectActorObjectShape`, `Race_SelectActorSpeedShape`,
`Race_SelectActorIdleShape`, `Race_SelectOpponentShape`,
`Race_SelectPlayerFinishShape`, `Race_SelectExtraActorShape`,
`Race_GetActorShapeVariant`.

Applied in R9: `Race_BuildTrackObjects` (was `Race_UpdateTrackObjectCursor`),
`Race_AddStagedObjects` (was `Race_AddTrackObjects`).

Applied in R5: `RoadObject_X/Y/Scale/Limit/Shape/Flags/XOffset/Shape2/Size`;
`Race_ram_TrackObjectCursor/Distance/Count/RecordCursor/WritePtr`;
`Race_TrackObjectTypeTable`.


| Function | Address | Role |
|---|---|---|
| `Race_DrawRoadEdges` | `0xEC90` | Road edges in the HUD; `unk_EB34` edge data. |
| `Road_FillProfileTables` | `0xECE0` | Per-line HScroll (fg/bg), marking X/width; road arrays. |
| `Race_IntegrateTrackCurve` | `0xEDD0` | Integrates `Track_CurveBuffer` into the road profile values/indexes. |
| `PiecewiseLinearInterpolation` | `0xF180` | Linear interpolation of the road arrays. |
| `FillLinearInterpArray` | `0xF1AE` | Per-row interpolation helper. |
| `Interp_dDivisorMap` | `0xF20C` | Divisor table for the interpolator. |
| `Race_ComputeStandings` | `0xEFA4` | Race standings/results (top-level after the race). |
| `Race_ScaleResultValue` | `0xF0E4` | Result/progress scaling with `RaceTrack_Data1`. |
| `Race_UpdateSpeedDisplay`/`Race_FormatDecimal` | `0xF108`/`0xF11C` | Speed/decimal HUD. |
| `Race_BuildActorObjectList`/`Race_Add*Object` | `0xF40C`+ | Object-record producers (L6b contract below). |
| `Race_WriteSpriteTiles` | `0x10972` | Sprite-tile staging to VRAM. |
| `Race_BuildTrackObjects`/`Race_ProjectTrackObject` | `0x109B6`/`0x10C4E` | Track-object stream -> object records (L6b). |
| `Road_BuildVisibleList` | `0x10D46` | Visible object list (`ram_FF1B50`/`1C50`/`1D50`). |
| `sub_10DBE`/`sub_10DDA` | `0x10DBE`/`0x10DDA` | Actor/visible-list helpers. |

## Key flow

- `Race_Update` calls `PiecewiseLinearInterpolation` for the left/marking/right road
  arrays (`Road_ram_XLeftArray`, `Road_ram_MarkingXArray`, `Road_ram_XRightArray`) from
  the `ram_FF329A`/`ram_FF31D2`/`ram_FF3362` values and `ram_FF3236` indexes, then
  `Road_FillProfileTables` to build the per-line HScroll/marking tables.
- `Race_IntegrateTrackCurve` reads `Track_CurveBuffer` at `Race_ram_PlayerProgress & $FF` and fills
  the profile value/index arrays (`ram_FF310A`/`31D2`/`329A`/`3236`/`3362`/`D77C`).
  `$1E6A` is the low word of `PlayerProgress` and doubles as the curve amplitude;
  `$1E6C` is the current signed curve byte; `$1E54/$1E56` accumulate the two curve
  bytes, `$1E58/$1E5A` are the scaled current/next bytes, and the `$3236` array is 32
  words whose last entry `$3274` is the horizon line. E6 confirmed these aliases and
  the 32-strip output.
- `Road_FillProfileTables` clamps the bg scroll to `[-192,192]` and fg to `[-192,160]`
  (+512), computes the marking width `(roadWidth*3/2)/64` (1..8), clamps marking X and
  zeroes the sky rows.
- After the race, `Race_ComputeStandings`/`Race_ScaleResultValue` produce the event
  keys consumed by `Race_ComputeResults` (contract below).
- `Road_BuildVisibleList` builds the visible object list from the sorted
  `ram_FF1B50`/`ram_FF1C50` lists into `ram_FF1D50`; `Race_WriteSpriteTiles` stages the
  sprite tiles for `Race_GameTick`.

## Frame object-assembly order (L6b)

`Race_Update` render-prep phase (`race_core.asm`):

```
ram_FFDE72 = 0
Race_AddSpecialObject        ; cop / special timer object
Race_AddTrackStartObject     ; start/finish gate when in range
Race_BuildActorObjectList    ; active + static + extra actor(s)
ram_FF1B48 = ram_FFDE72      ; actor-object count
Race_BuildTrackObjects       ; ROM track-object stream
ram_FF1B4A = ram_FFDE72 - ram_FF1B48   ; track-object count
Race_AddStagedObjects        ; staged RAM traffic list
ram_FF1B50[count] = $FFFFFFFF          ; terminate distance list
Road_BuildVisibleList        ; sort into ram_FF1C50 + index list $FF1D50
...
Road_DrawObjects             ; draw in visible-list order
```

`Road_ObjectArray` is `$FFD37C..$FFD77B`, 0x14-byte records, at most 51
(`$400/$14`); `ram_FFDE72` is the live count and the record word at index `count`
is the `$FFFF` terminator. The parallel distance list `ram_FF1B50` holds one 32-bit
key per record and is sorted into `ram_FF1C50`; `Road_VisibleObjectList`
(`$FF1D50`) holds the sorted record indices as words.

`Road_ObjectArray` fields (`RoadObject_*`): `+0` screen X, `+2` screen Y,
`+4` scale, `+6` limit/depth, `+8` shape, `+$A` flags, `+$C` X offset,
`+$E` reserved (projected row byte for track objects), `+$10` reserved,
`+$12` second shape. The distance key (`ram_FF1B50`) is stored separately, not in
the record.

## `Race_ComputeStandings` (`0xEFA4`, L7 contract)

Runs in `top_level.asm` (`0x7E8F4`) after the race and before `Race_ComputeResults`.

- Player state: `a1 = RacePlayerA`, `a2 = Race_EventBuffer`.
  - not finished (`$68` bit7 clear): `ProgressSnapshotC = ProgressSnapshotB`,
    `EventProgress = PlayerA+$4` high word, `EventBuffer[0] = $FFFFFFFF`;
  - finished: `ProgressSnapshotC = PlayerA+$62`, `EventProgress = RaceTrack_Data1`,
    `EventBuffer[0] = PlayerA+$62`.
- Active list (`ram_FF1A08`, count-2; the first entry is PlayerA and the last is the
  sentinel): skip `ram_FF1F2A` (reserved opponent). Running actors
  (`$68` bit7 clear) get `EventBuffer[$71] = ScaleResultValue(progress,
  $71)`; finished actors store `$62` directly.
- Opponent free list (walked backwards): `d2 = EventProgress + $20 +
  (Rand & $1F)`; each non-reserved actor gets
  `key = ScaleResultValue(d2, $71)` and is then replaced by
  `min(key, (RaceTrack_Data1<<16)/Rating[$71])`.
- Traffic free list (walked backwards): `d2 = EventProgress - $10 -
  (Rand & $1F)`; each entry is overwritten by `ScaleResultValue(d2, $71)`.
- `Race_ScaleResultValue(d0, d1, a2)`:
  `d2 = ProgressSnapshotC; d2 <<= 8; d2 /= d0; d2 *= RaceTrack_Data1;
  d2 >>= 8; write.l d2, a2[d1*4]`.
  For a finished actor `$62` is the 16.16 progress snapshot; for a running actor
  `d0` is the event progress, so the result key is proportional to distance covered.
  The reserved opponent is skipped in all three lists.

E7-C2 (`analysis/notes/L7_results2_trace.txt`) forced a non-demo finish at frame 305:
`ProgressSnapshotC=$00070000`, `EventProgress=$073F`, `EventBuffer` built normally,
then `Race_ComputeResults` produced the sorted keys
`00000009,0000000A,0000000B,0000000F,0000000D,0000000E` and a place `$0F`.

## `Road_FillProfileTables` (`0xECE0`, L6a contract)

`Race_ram_CurrentAlpha` selects the first road row: start at line `$98` and fill
backwards for `$97-alpha` lines. HScroll rows are 4 bytes
`[plane A (fg), plane B (bg)]`; this routine writes the road part, then
`Race_BuildHScrollTable` overwrites the sky/parallax part above alpha and clears the
unused lower lines (see `race_physics.md`).

For each row:

- `roadX_left` = `Road_ram_XLeftArray[i]`, `roadX_right` = `Road_ram_XRightArray[i]`;
- bg scroll: `clamp(right, -160, 192) - 192`;
- fg scroll: `clamp(left, -192, 160) + 512`;
- marking width: `(right-left)*1.5 >> 6`, forced into `1..8`;
- marking X: `MarkingXArray[i] + 512`; if it reaches `>=320`, insert a gap
  (`x=0,width=0`); if `x<0`, reduce width by `x`, clamp x/width to 0;
- write bg/fg into `Race_ram_CurrentHScrollTable`, and X/width into
  `RoadMarking_ram_XArray`/`WidthArray`.

After the road rows, the top `alpha` sky rows get zero scroll/X/width entries.

## Object-record producers (L6b)

All producers write the current `Road_ObjectArray` record at `ram_FFDE72` and append
one 32-bit key to `ram_FF1B50`, except the marker/gap paths and the dropped/clipped
records (which do not increment `ram_FFDE72`).

- `Race_AddSpecialObject` (`0xFD96`): when `Race_CopIndex != 0` uses shape `$170`
  (cop); otherwise it requires the negative `ram_FF3698` flag, resets `ram_FF369A`
  and returns. The appended record is fixed: X `$FEA0`, Y `$41`, scale `$4000`,
  limit `$E0`, key `0`, flags cleared; `ram_FF369A` is incremented.
- `Race_AddTrackStartObject` (`0xFB1E`): the start/finish gate. Before progress `$C`
  it uses X `$C0000`; otherwise `RaceTrack_Data1<<16`, and only when the gate is
  ahead by `< $1F0000`. Shape comes from `sub_15478`; the record is projected by
  `Race_ProjectObject(d0=gateX, d1=$180, d2=0)`; the mirror bit (`$B` bit7) is set.
- `Race_BuildActorObjectList` (`0xF40C`): walks three populations in order:
  `ram_FF1A08` (PlayerA + opponents), `Race_StaticActorList` (static pair, only
  actors whose `RespawnTimer == $FFFF`), then the single extra actor `$FF2FAA`
  (via `unk_258A6`; requires `ProgressSnapshotB >= $708` and `$68` bit6). It advances
  `ram_FF1AD9` (mod 4, lean shape) and `ram_FF1ADC` (mod 8, fall shape) once per
  frame, and clears `ram_FF3040` (population phase 0/1/2).
  - `ram_FF1B16` is the per-actor "custom animation" flag; bit4 of `ControlFlags`
    with a non-negative `AnimState` runs `sub_15014` to fetch the current tile.
  - Relative X `rel = actorX - PlayerProgress` (high word in `d0`): `rel < -$10` ->
    `Race_ProjectActorSprite` (far behind); `rel > $1E` -> skip; otherwise the
    near-actor record is built:
    `row = rel.high & $1F` stored in `Flags` low bits, `Y` from
    `ram_FF1E60 - actor.$30` divided by `(rel>>8)+$100`, plus `actor+8` and the lean
    curve (bit5), bucketed through `ram_FFD338` (4 entries) or `unk_25802` (3
    entries) into signed `actor.$34`; the shape is selected by
    `Race_SelectExtraActorShape` / `Race_SelectOpponentShape` /
    `Race_SelectPlayerFinishShape` / `Race_SelectActorObjectShape` (idle, speed,
    weapon, state variants); the key is `rel` (32-bit) and the record is projected
    by `Race_ProjectActorObject`. The palette is ORed into `Flags` bits 4-7.
  - The main record is kept only when its screen X is in `[-$23C, 0)`; otherwise the
    count is not advanced. If that actor is the player in a fall
    (`AnimState == 2 && ImpactScale >= 8`) a fall object is added; then an impact
    object (ControlFlags bit0) or lean object (bit5); a weapon object when
    `WeaponAnimFlags` bit7 and frame 0. `ram_FF1B16` actors also emit a shadow via
    `Race_ActorShadowTable[$71]`: shadow shape `$58`, projected object (or sprite
    when far behind), shadow bits from `$76` (`$A` bit7, bit3).
- Shape selectors: `Race_SelectActorObjectShape` handles idle/speed/weapon/state
  pages; `Race_SelectActorSpeedShape` (`$50..$55`), `Race_SelectActorIdleShape`
  (`$56..$58`), `Race_SelectOpponentShape` (`$7F..$86`), `Race_SelectPlayerFinishShape`
  (`$59..$5F`, second shape from `unk_102DE = 3,19,35`), `Race_SelectExtraActorShape`
  (extra actor), `Race_GetActorShapeVariant` (2-threshold bucket). Leaning/mirroring
  flips `$A` bit15 when `$34` is negative. `ram_FFD338 = 0x001F0044/0x009301BB`
  (4 entries) and `ram_FFD33E = 0x0004000D/0x00200224` (3 entries) are the
  speed/lean threshold tables copied in `Race_Init`.
- `Race_BuildTrackObjects` (`0x109B6`): the normal-play track-object stream (see
  below) writes records directly and uses `Race_ProjectTrackObject`.
- `Race_AddStagedObjects` (`0xFC0E`): consumes the staged 4-byte RAM list
  (`ram_FFD7D4`) that the spawn layer fills; shape = byte2 + `$173`, render flags
  from `Race_TrackObjectTypeTable[byte2]`, key = position - progress, type size
  from table `+2` (scale), lane offset from the low nibble (`(nibble<<5)-$100`),
  and `Race_ProjectObject` for the screen fields. Only entries within `$1E0000` ahead
  are emitted; the cursor is rewound while the previous high word is at/after the
  progress. `Race_ram_TrackObjectCount` counts the emitted staged objects.

### Projection helpers (L6b)

`Race_ProjectObject` (`0xFD96`, shared by the staged/start/extra helpers):

- `d0` = 16.16 object X, `d1` = Y offset, `d2` = extra Y offset, `a0` = record.
- If X is behind the player, leaves the record untouched and returns 0.
- Row `r = (X.high - PlayerProgress.high) & $1F`; `dist = (X-progress)>>8`.
- `scale = $A00000 / (dist + $200)`; writes `+4`.
- `Y = $4C + (profileWord(r, dist+$100)) / (dist+$100)` with the `+2` term folded in,
  clamped to `>= 1`; writes `+2`.
- `X = $4C ± (profileWordX(r, dist+$100)) / (dist+$100)`, then `-$160`; writes `+0`
  (min 1 on the negative branch).
- `limit = ram_FFD77C[2r]` -> `+6`.
- returns `d0 = scale`, `d1 = X`, `d2 = Y`, `d3 = r`; callers OR `d3` into
  `Flags` low bits. `prof` = the 4-word `ram_FF310A` strip record interpolated by
  the X fractional word (`ram_FF310A` rows are `+0/+2/+4/+6` and the `+2/+6` and
  `+0/+4` pairs are the depth/X edges).
- `Race_ProjectObject` updates the record only; the caller appends the distance key.
  The low-5-bit `Flags`/row and `Flags & 7` draw-pass overload is `U-0019`.

`Race_ProjectActorObject` (`0x1082A`): nearest-actor variant.

- `d4 = actor X fraction` (word at `+6`), `r = Flags & $1F`;
  `dist = (actorX-progress)>>8`.
- `scale = ($A00000 if $71 < $10 else $C00000) / (dist+$200)` -> `+4`.
- `Y = $4C + (profileEdge(r) - CollisionOffset) / (dist+$100)` -> `+2`.
- `limit = ram_FFD77C[2r]` -> `+6`; `X = (profileX(r) + actor.$30)/(dist+$100) -
  $160` -> `+0`; writes no flags. `d4` is the interpolation weight between the two
  profile rows.

`Race_ProjectActorSprite` (`0xDAE2`, `race_physics.asm`): far-behind actor
projection. It appends the key `progress - actorX`, computes screen Y from the
player `PosY ± $10`, `$28` steps and actor `$30`, screen X from
`$D8 - (rel>>12)/16`, scale `min($3FFF, $100000/((rel>>12)+$80))*3`, writes shape
`$154+variant`/`$159`/`$15A..$15C`, flags `$4100 | (palette<<4)` and accepts X in
`[-$20, $160)`.

`Race_ProjectTrackObject` (`0x10C4E`): track-stream variant.

- Inputs from `Race_BuildTrackObjects` (record already holds shape/second shape and
  type word `d6`).
- `r = Flags & $1F`; `+$E = (r<<8) - ((progress & $FF00)>>8)`.
- `scale = ((typeSize<<3)+$200)>>2 / ((r<<8) - progressByte + $100)` -> `+4`.
- lane offset from the type low nibble: `±(lane<<6)` on the `ram_FF310A` edge,
  converted by the same divide -> `+$C`; the sign follows `Flags` bit14.
- `+6 = ram_FFD77C[r*2]`, `+2 (Y) = ram_FF3236[r*2]`, `+0 (X) =
  -ram_FF31D2[r*2] ± X offset`; drops the record (`a0 -= $14`) when the X edge is
  out of the `$23C` window or the divide overflows.

### Track-object stream format (L6b)

`Race_BuildTrackObjects` reads 4-byte entries from the ROM stream at
`Race_ram_TrackObjectCursor` (`RaceTrack_Data4` terminator):

- word0 high byte = row count `(word0>>8)&$1F` (0..31), low 7 bits = shape base
  `(word0 & $7F) + $186`;
- word2 high nibble = per-row step minus 1 (`((word2>>4)&$F)+1`); bits 8-10
  (`$700`) = object flags; low byte = lane/type data;
- `word0` bit14 = alternate/second-part selector, bit15 = mirror;
- shape remap: `$205` = gap/skip; `< $1BB` = as-is; `$1BB..$1E9` -> emits the pair
  `(base, base+1)` (second shape at `+$12`, `$B` bit7 set); `>= $1EA` -> `+$2F`;
- shape `$186` is the extra-actor marker: stores `ram_FF1B30 = d0` (row slot) and
  `ram_FF1B2E = remaining rows+1`, emits no object;
- `Race_ram_TrackObjectDistance` accumulates `rowStep * (step)` per entry; the
  cursor rewinds while the previous entry's high word is at/after the player
  progress and advances when the entry passes; entries beyond `$20` rows stop the
  current entry and move to the next.

The record flags for a track object are `word2 & $700` | `$1000` | the low row
offset; `+$10 = word2 & $FF`; `+8/+$12` = shape pair; `+$E` and the projections come
from `Race_ProjectTrackObject`. Staged objects (`Race_AddStagedObjects`) use the
other 4-byte format already documented for the spawn layer: word0 = position key,
byte2 = type index, byte3 = lane/length.

## `Road_BuildVisibleList` (`0x10D46`, L6b)

`Road_BuildVisibleList` is an insertion sort of the 32-bit distance keys from
`ram_FF1B50` (source `a0`) into `ram_FF1C50` (destination `a1`), maintaining the
parallel word index list in `Road_VisibleObjectList` (`$FF1D50`, `a2`):

- copies the first key; `index[0]=0`;
- for each next key, scans the already-written destination forward comparing
  `cmp.l (a3)+,d4`; `BMI` (new key < existing, signed long) inserts before that
  position, shifting both keys and indices; otherwise appends;
- writes the `$FFFFFFFF` terminator and its `$FFFF` index into both lists.

The sort is **ascending signed long** distance, so the smallest key is drawn first.
`Road_DrawObjects` walks `ram_FF1D50` and calls `Road_DrawObject` for each record in
that order (back-to-front depth order). The sign convention of the stored keys
differs by producer: the near-actor and track/staged paths store
`objectX - progress`, while `Race_ProjectActorSprite` stores `progress - actorX`;
both end up in one sort, so E8 should confirm the visual back-to-front result on a
scene with objects in front of and behind the player.

## `Road_DrawObject` consumer (L6b)

`Road_DrawObject` (in `road_render.asm`) renders one 0x14-byte record:

- Flags bit15 is the horizontal-mirror/facing bit (same as byte `$B` bit7); bits
  `$3000` become the priority/`$133E` value; `Flags & 7` is the sprite-chain pass
  count; X offset is applied to the copied SAT entry.
- Shape `+8` selects a `Road_ShapeTable` entry; a non-zero second shape `+$12`
  (or the mirror path) runs `Road_ScaleShape` + `Road_ProjectShapeSpecial`, else
  `Road_ProjectShape`; `Road_DrawStrip` writes the tile columns and builds the
  sprite chain via `RiderSprites_Build`; the chain is copied to the SAT with X
  offset and the `$FFC0`/`$FE20` clip window.
- The 0x14-byte record layout and the SAT/tile writes are confirmed by the dynamic
  `Road_DrawObjects` snapshot.

### Dynamic object-list snapshot

At the first `Road_DrawObjects` (`0x942A`) hit in the demo race:

- `ram_FFDE72 = 22` object records, `PlayerProgress = $00078000`;
- `Road_ObjectArray` records decode as `x,y,scale,limit,shape,flags,c,e,f,shape2`;
  e.g. record 9: `x=-208,y=96,scale=$5174,shape=$01C3,flags=$1184,
  c=-170,e=$0380,f=$00AC,shape2=$01C4`;
- `ram_FF1D50` visible index list starts
  `1,2,3,4,9,0,$A,$B,5,6,$C,$D,$E,7,8,$F,$10,$11,$12,$13,...`.

This confirms the object-record field order and the visible-index list layout used
by `Road_DrawObjects`/`Road_DrawStrip`.

## RAM / data

- `Road_ram_XLeftArray`/`XRightArray`/`MarkingXArray`;
  `RoadMarking_ram_XArray`/`WidthArray`; `Race_ram_CurrentHScrollTable`/`Alpha`.
- `ram_FF310A`/`ram_FF31D2`/`ram_FF329A`/`ram_FF3236`/`ram_FF3362`/`ram_FF3A9C`/`ram_FFD77C`; `Race_ram_PlayerProgress`/`ram_FF1E6A`/`ram_FF1E6C`.
- `Road_ObjectArray` (`$FFD37C`, 0x14-byte records, max 51); `ram_FFDE72` count.
- `ram_FF1B48` actor-object count, `ram_FF1B4A` track-object count,
  `Race_ram_TrackObjectCount` staged-object count.
- `ram_FF1B50`/`1C50`/`1D50` visible lists; `Race_ram_CurrentHudBuffer`.
- `ram_FFD338`/`ram_FFD33E` shape threshold tables; `ram_FF1ACC` player-finish
  selector; `ram_FF1AC8` speed tier; `ram_FF1ACE` finish toggle; `ram_FF1AD9`
  lean-shape phase; `ram_FF1ADC` fall-shape phase; `ram_FF1B16` custom-animation
  flag; `ram_FF1B2E`/`ram_FF1B30` shape-`$186` marker run/slot.
- Sprite staging: `Race_ram_NextSpriteTileArray`, `Race_ram_SpriteDestination`,
  `Race_ram_CurrentSpriteTileArray`.
- ROM data: `unk_EB34` road edges, `Interp_dDivisorMap`, `unk_102DE`, `unk_10E3E`,
  `unk_FA80`, `unk_25802`/`unk_2580A` threshold tables, `Race_ActorShadowTable`.

## Open questions

- The `Flags` low-bit overload (projected row vs. `Road_DrawObject` pass count,
  `Flags & 7`) is `U-0019`; E8 should confirm the draw semantics.
- The exact visual back-to-front result of the mixed-sign distance keys (see the
  visible-list section); E8.
- Engine-audio mapping of `Race_ram_NearestBehindSpeed`/`Race_ram_NearestAheadSpeed`
  is in `race_physics.md`.
- Data4/5 shape row/pixel map is L6c.

## Rename proposals

The function renames above are applied. Remaining data/field names are proposals (TODO).

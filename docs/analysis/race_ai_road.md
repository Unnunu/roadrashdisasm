# Analysis: `src/race/race_ai_road.asm` (road profile, objects, visible list, standings)

- **Module:** road profile/height/curve, HScroll/marking tables, object/visible lists,
  sprite-tile staging, race standings/results, speed display
- **ROM range:** `0x00EB34`–`0x010DFF`
- **Status:** analyzed (roles/flow); some render/object internals and data layouts TODO
- **Source:** `src/race/race_ai_road.asm`
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_physics.md`,
  `docs/analysis/race_spawn.md`, `docs/modules/race_ai_road.md`, `docs/ram-map.md`

## Functions
Applied in R4: `Race_BuildActorObjectList`, `Race_AddSpecialObject`,
`Race_AddTrackStartObject`, `Race_AddTrackObjects`,
`Race_UpdateTrackObjectCursor`, `Race_ProjectTrackObject`,
`Race_ProjectObject`, `Race_ProjectActorObject`.

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
| `Race_BuildActorObjectList`/`Race_AddSpecialObject`/`Race_AddTrackStartObject`/`Race_AddTrackObjects` | `0xF40C`+ | Road/object render helpers (TODO). |
| `Race_WriteSpriteTiles` | `0x10972` | Sprite-tile staging to VRAM. |
| `Race_UpdateTrackObjectCursor`/`Race_ProjectTrackObject` | `0x109B6`/`0x10C4E` | Object/sprite tile copies (TODO). |
| `Road_BuildVisibleList` | `0x10D46` | Visible object list (`ram_FF1B50`/`1C50`/`1D50`). |
| `sub_10DBE`/`sub_10DDA` | `0x10DBE`/`0x10DDA` | Actor/visible-list helpers. |

## Key flow

- `Race_Update` calls `PiecewiseLinearInterpolation` for the left/marking/right road
  arrays (`Road_ram_XLeftArray`, `Road_ram_MarkingXArray`, `Road_ram_XRightArray`) from
  the `ram_FF329A`/`ram_FF31D2`/`ram_FF3362` values and `ram_FF3236` indexes, then
  `Road_FillProfileTables` to build the per-line HScroll/marking tables.
- `Race_IntegrateTrackCurve` reads `Track_CurveBuffer` at `Race_ram_PlayerProgress & $FF` and fills
  the profile value/index arrays (`ram_FF310A`/`31D2`/`329A`/`3236`/`3362`/`D77C`).
- `Road_FillProfileTables` clamps the bg scroll to `[-192,192]` and fg to `[-192,160]`
  (+512), computes the marking width `(roadWidth*3/2)/64` (1..8), clamps marking X and
  zeroes the sky rows.
- After the race, `Race_ComputeStandings`/`Race_ScaleResultValue` produce the standings
  and scaled result values (top-level flow), using `RaceTrack_Data1`.
- `Road_BuildVisibleList` builds the visible object list from the sorted
  `ram_FF1B50`/`ram_FF1C50` lists into `ram_FF1D50`; `Race_WriteSpriteTiles` stages the
  sprite tiles for `Race_GameTick`.

## `Road_FillProfileTables` (`0xECE0`)

`Race_ram_CurrentAlpha` selects the first road row: start at line `$98` and fill
backwards for `$97-alpha` lines.

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

## `Road_BuildVisibleList` (`0x10D46`)

`Road_BuildVisibleList` is an insertion sort of dword keys from the source list
`a0` into the destination list `a1`, while it maintains a parallel word index list
`a2`:

- copies the first key; `a2[0]=0`;
- for each next key, scans the already-written destination backwards comparing
  `cmp.l (a3)+,d4` (BCC loop / BMI insertion), shifts entries and their indices,
  then writes the key/index pair;
- writes the `$FFFFFFFF` terminator and its index into both lists.

Inputs are `ram_FF1B50`/`ram_FF1C50` from the object/sprite helpers; the sorted
keys + indices feed `ram_FF1D50` (`Road_VisibleObjectList`) for
`Road_DrawObjects`. The exact ascending/descending convention and key units are
still TODO.

## Object-list/render helpers

- `Race_BuildActorObjectList` (`0xF40C`) is the actor/static/extra object-list builder. It advances
  `ram_FF1AD9` (mod 4) and `ram_FF1ADC` (mod 8), walks `ram_FF1A08`,
  `Race_StaticActorList`, then `$FF2FAA`; projects each actor with
  `Race_ProjectActorSprite` or computes a projected X/Y from player progress; calls
  `sub_15014`/`sub_10256`/`sub_100D0`/`sub_10294`/`sub_108DA`/`Race_ProjectActorObject`; appends
  records to `Road_ObjectArray` and distances to `ram_FF1B50`.
- `Race_AddSpecialObject` (`0xFD96`) appends a special/cop/start object with fixed
  `$FEA0/$41/$4000` fields when `Race_CopIndex` or `ram_FF3698` requests it.
- `Race_AddTrackStartObject` (`0xFB1E`) appends the track-start object selected from
  `RaceTrack_Data1`/player progress, sets its record/flags, and projects it through
  `Race_ProjectObject`.
- `Race_AddTrackObjects` (`0xFC0E`) walks the track object stream cursor `Race_ram_TrackObjectRecordCursor`, appends
  visible objects with `Race_ProjectObject`, and stores the per-shape depth data from
  `ram_FFD77C`.
- `Race_UpdateTrackObjectCursor` (`0x109B6`) advances/rewinds the track-object stream cursor
  `Race_ram_TrackObjectCursor`/`Race_ram_TrackObjectDistance` against player progress; `Race_ProjectTrackObject` consumes the
  resulting object/shape data into the object records.

### Track-stream dynamic snapshot

At `Race_UpdateTrackObjectCursor` (`0x109C4`):

- `PlayerProgress=$00078000`, `Race_ram_TrackObjectCursor=$00027984`, `Race_ram_TrackObjectDistance=0`;
- ROM cursor bytes start `00 7F A0 00 80 39 01 AC 81 FA 00 15 ...`.

At `Race_AddTrackObjects` (`0xFC5A`):

- `Race_ram_TrackObjectRecordCursor=$00FFD7D4`, `ram_FFDE72=22`;
- RAM-staged entries start `00 A7 02 18`, `01 A5 01 18`, `02 BC 05 0F`,
  `02 BE 02 0E`.

This confirms that `Race_UpdateTrackObjectCursor` walks the ROM/pointer stream
(`Race_ram_TrackObjectCursor`), while `Race_AddTrackObjects` consumes the RAM-staged 4-byte records
at `Race_ram_TrackObjectRecordCursor`. In each staged word, the high word is the position key, `byte2`
is the shape/type selector, and `byte3` is the length/row selector (working model).

### `Race_UpdateTrackObjectCursor` field model

`Race_UpdateTrackObjectCursor` reads a 4-byte entry and builds `Road_ObjectArray`
records directly:

- word0 low 7 bits + `$186` selects the shape (with a range remap);
- word0 bits 7/8 contribute flags; high byte `(word0 >> 8) & $1F` is the row count;
- word2 high nibble `(word2 >> 4) & $F` is the length/step (+1); bits `$700`
  are object flags; low byte is object data;
- bit15/bit14 of word0 select mirror/alternate-object bits;
- the routine writes `$A` flags, second shape, shape IDs, and updates
  `Race_ram_TrackObjectCursor/Distance` and `ram_FFDE72`.

This is distinct from the RAM-staged list consumed by `Race_AddTrackObjects`
(4-byte entries: high word position, byte2 type, byte3 length).

### Track-object stream format (static hypothesis)

`Race_AddTrackObjects` reads 4-byte entries from the `Race_ram_TrackObjectRecordCursor` cursor (track stream in
`RaceTrack_Data4`-adjacent data):

- word at `+0`: position/progress key; compared with `Race_ram_PlayerProgress`;
- byte at `+2`: low nibble selects an object/shape entry; high nibble is a length
  multiplier used by the cursor/stream advance;
- `Race_ProjectObject` projects the object into the current `Road_ObjectArray` record; the
  shape index is `byte2_low + $173`, the per-shape depth comes from
  `ram_FFD77C`, and the type data comes from the 8-byte `Race_TrackObjectTypeTable` records;
- record flags carry the shadow/priority/mirror bits already documented for
  `Road_DrawObject`.

`Race_UpdateTrackObjectCursor` maintains the same stream cursor during normal play: it rewinds when
past entries are behind the player, advances when the next entry is visible, and
keeps `Race_ram_TrackObjectDistance` as the accumulated stream distance. The exact nibble units and
the `RaceTrack_Data4` terminator role are still TODO.

These helpers are called from `Race_Update` around the road-profile/visible-list
stage (`Race_AddSpecialObject`, `Race_AddTrackStartObject`, `Race_BuildActorObjectList`, `Race_UpdateTrackObjectCursor`, `Race_AddTrackObjects`).

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
- `ram_FF1B50`/`1C50`/`1D50` visible lists; `Race_ram_CurrentHudBuffer`.
- Sprite staging: `Race_ram_NextSpriteTileArray`, `Race_ram_SpriteDestination`,
  `Race_ram_CurrentSpriteTileArray`.
- ROM data: `unk_EB34` road edges, `Interp_dDivisorMap`, `Race_BuildActorObjectList` data, `unk_FA80`,
  `word_107EA`/`word_10802`.

## Open questions

- Exact object/road-render helpers `Race_BuildActorObjectList`..`Race_AddTrackObjects`, `Race_UpdateTrackObjectCursor`/`Race_ProjectTrackObject`.
- The visible-list sort/list layout and the `Ram_FF1D50` ordering.
- The standings/results data (`Race_ComputeStandings`/`Race_ScaleResultValue`).
- Track/curve tables in the gap (can be dumped into the build if needed).

## Rename proposals

The function renames above are applied. Remaining data/field names are proposals (TODO).

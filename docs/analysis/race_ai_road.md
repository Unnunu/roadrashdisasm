# Analysis: `src/race/race_ai_road.asm` (road profile, objects, visible list, standings)

- **Module:** road profile/height/curve, HScroll/marking tables, object/visible lists,
  sprite-tile staging, race standings/results, speed display
- **ROM range:** `0x00EB34`–`0x010DFF`
- **Status:** analyzed (roles/flow); some render/object internals and data layouts TODO
- **Source:** `src/race/race_ai_road.asm`
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_physics.md`,
  `docs/analysis/race_spawn.md`, `docs/modules/race_ai_road.md`, `docs/ram-map.md`

## Functions

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
| `sub_F40C`/`sub_FD96`/`sub_FB1E`/`sub_FC0E` | `0xF40C`+ | Road/object render helpers (TODO). |
| `Race_WriteSpriteTiles` | `0x10972` | Sprite-tile staging to VRAM. |
| `sub_109B6`/`sub_10C4E` | `0x109B6`/`0x10C4E` | Object/sprite tile copies (TODO). |
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

- `sub_F40C` (`0xF40C`) is the actor/static/extra object-list builder. It advances
  `ram_FF1AD9` (mod 4) and `ram_FF1ADC` (mod 8), walks `ram_FF1A08`,
  `Race_StaticActorList`, then `$FF2FAA`; projects each actor with
  `Race_ProjectActorSprite` or computes a projected X/Y from player progress; calls
  `sub_15014`/`sub_10256`/`sub_100D0`/`sub_10294`/`sub_108DA`/`sub_FF7E`; appends
  records to `Road_ObjectArray` and distances to `ram_FF1B50`.
- `sub_FD96` (`0xFD96`) appends a special/cop/start object with fixed
  `$FEA0/$41/$4000` fields when `Race_CopIndex` or `ram_FF3698` requests it.
- `sub_FB1E` (`0xFB1E`) appends the track-start object selected from
  `RaceTrack_Data1`/player progress, sets its record/flags, and projects it through
  `sub_FE3A`.
- `sub_FC0E` (`0xFC0E`) walks the track object stream cursor `ram_FFD7CC`, appends
  visible objects with `sub_FE3A`, and stores the per-shape depth data from
  `ram_FFD77C`.
- `sub_109B6` (`0x109B6`) advances/rewinds the track-object stream cursor
  `ram_FFD7C4`/`ram_FFD7C8` against player progress; `sub_10C4E` consumes the
  resulting object/shape data into the object records.

These helpers are called from `Race_Update` around the road-profile/visible-list
stage (`sub_FD96`, `sub_FB1E`, `sub_F40C`, `sub_109B6`, `sub_FC0E`).

## RAM / data

- `Road_ram_XLeftArray`/`XRightArray`/`MarkingXArray`;
  `RoadMarking_ram_XArray`/`WidthArray`; `Race_ram_CurrentHScrollTable`/`Alpha`.
- `ram_FF310A`/`ram_FF31D2`/`ram_FF329A`/`ram_FF3236`/`ram_FF3362`/`ram_FF3A9C`/`ram_FFD77C`; `Race_ram_PlayerProgress`/`ram_FF1E6A`/`ram_FF1E6C`.
- `ram_FF1B50`/`1C50`/`1D50` visible lists; `Race_ram_CurrentHudBuffer`.
- Sprite staging: `Race_ram_NextSpriteTileArray`, `Race_ram_SpriteDestination`,
  `Race_ram_CurrentSpriteTileArray`.
- ROM data: `unk_EB34` road edges, `Interp_dDivisorMap`, `sub_F40C` data, `unk_FA80`,
  `word_107EA`/`word_10802`.

## Open questions

- Exact object/road-render helpers `sub_F40C`..`sub_FC0E`, `sub_109B6`/`sub_10C4E`.
- The visible-list sort/list layout and the `Ram_FF1D50` ordering.
- The standings/results data (`Race_ComputeStandings`/`Race_ScaleResultValue`).
- Track/curve tables in the gap (can be dumped into the build if needed).

## Rename proposals

The function renames above are applied. Remaining data/field names are proposals (TODO).

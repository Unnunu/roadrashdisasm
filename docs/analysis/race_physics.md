# Analysis: `src/race/race_physics.asm` (camera, HInt scroll, rearview, nearest opponent)

- **Module:** VDP DMA helpers, rearview mirror/camera, HInt V/HScroll tables,
  road-marking HUD, actor-sprite projection, nearest-opponent/engine audio
- **ROM range:** `0x00D8FA`–`0x00E731`
- **Status:** analyzed (roles/flow); some table offsets and audio/audio fields TODO
- **Source:** `src/race/race_physics.asm`
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_spawn.md`,
  `docs/modules/race_physics.md`, `docs/ram-map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `DmaWriteVRAM` | `0xD8FA` | VDP DMA: length/source/dest + `Race_ram_VdpDmaControl` control. |
| `DmaWriteCRAM` | `0xD92C` | Same for CRAM (`$C000` control). |
| `Race_DrawRearviewMirror` | `0xD9DA` | Rearview mirror road; player X/Y, HUD row 25, `Race_ram_RearviewTileRows`. |
| `Race_DrawMirrorRoad` | `0xDA3E` | Mirror road rows; palette/priority `$8000800` XOR. |
| `Race_ProjectActorSprite` | `0xDAE2` | Actor position vs player progress -> sprite Y/X. |
| `Race_DrawRoadMarkingHud` | `0xDD84` | Road marking in the HUD/mirror; widths/data A/B. |
| `Race_UpdateCamera` | `0xDE9E` | Camera offset, road position/curve; `Track_CurveBuffer`. |
| `Race_BuildVScrollInfo` | `0xE004` | HInt VScroll/raster layers (sky/horizon/road). |
| `Race_BuildHScrollTable` | `0xE494` | HInt HScroll table from the VScroll/alpha state. |
| `Race_UpdateNearestOpponent` | `0xE5EE` | Nearest ahead/behind actor; engine audio values. |

Data: `Race_RoadMarkingDataA/B` (`0xDC84`/`0xDD44`), `Race_ram_RearviewTileRows` road rows,
`ram_FF3238`/`RoadMarking_ram_WidthArray`/`ram_FF3A9C`.

## Key flow

- `Race_Update` calls `Race_UpdateCamera` before the frame-ready check; after the road
  profile it calls `Race_BuildVScrollInfo`; after the visible list
  `Race_DrawRoadMarkingHud`; at the end `Race_DrawRearviewMirror` and
  `Race_BuildHScrollTable`. The player/actor chain calls `Race_UpdateNearestOpponent`.
- `Race_GameTick` uses `DmaWriteVRAM` for the HUD/HScroll/SAT and `DmaWriteCRAM` for the
  palette.
- `Race_BuildVScrollInfo`/`Race_BuildHScrollTable` fill the per-frame
  `Race_ram_CurrentVScrollInfo`/`CurrentHScrollTable` buffers consumed by the HInt
  (src/main.asm `HorizontalInterrupt`).

## `Race_UpdateCamera` (`0xDE9E`)

`[static]` camera/road update:

- If PlayerA `$68` bit4 is clear, `Race_ram_CameraOffset=0`.
- If it is set and the race is not paused:
  - `$6E < 2`: `CameraOffset += FrameDistance >> 4` with sign from `$69` bit3,
    clamped to `-$7000`;
  - `$6E >= 2`: `CameraOffset -= CameraOffset >> 2` (decay).
- `ram_FF1E60 = (PosY>>1) + (PosY>>2) + ram_FF1E7A`.
- `ram_FF1E64 = ($32>>1) + ram_FF1E7E + $5D`, with a `$5D` floor.
- `Race_ram_PlayerProgress = PlayerA X - ram_FF1E76 - CameraOffset`.
- The old/new progress difference walks `Track_CurveBuffer` and accumulates
  `ram_FF1E54/ram_FF1E56` (signed sums of the two curve bytes).

`[dynamic]` Running demo: `PlayerProgress=$00078682` from `X=$00080682`,
`ram_FF1E76=$8000`, `CameraOffset=0`; `ram_FF1E60=$78` from `PosY=$A0`.
Forced left turn: `1E50=$0002`, `1E52=$0003`, `1E54=0`, `1E56=2`,
`1E58=2`, `1E5A=1`. Hard-left/off-road-ish: `1E54=$017A`, `1E56=$20E4`,
`1E58=$FFFE`, `1E5A=$FFFD`, `1E60=$FFEF`.

## `Race_ProjectActorSprite` (`0xDAE2`)

Builds a `Road_ObjectArray` record for one actor at the current
`ram_FFDE72` index:

- relative X = `(actor.X - Race_ram_PlayerProgress)` (negated and stored in the
  distance list);
- Y uses `RacePlayerA.PosY ± $10`, `$28` steps and the actor `$30`;
- screen Y/X are scaled by `$E0`/`$100`-style factors, then clipped;
- scale = `min($3FFF, $100000 / (relativeX + $80))`, tripled for the record;
- flags = `(actor.$73 & 3) ror 4 + $4100`;
- actor index `1` -> shape `$159`; `$10..$12` -> `$15A/$15C` special shapes;
  other actors -> `Race_GetActorShapeVariant` + `$154`;
- visible objects (`x >= -$20`, right edge `< $160`) increment
  `ram_FFDE72` and the object pointer.

The record layout and clipping are confirmed by the dynamic `Road_DrawObjects`
snapshot.

## `Race_UpdateNearestOpponent` (`0xE5EE`)

- Returns immediately if PlayerA `$68` bit7 (finished).
- Resets `Race_ram_NearestAheadDistance=$7FFFFFFF`,
  `Race_ram_NearestBehindDistance=$80000000`.
- Walks the active list after PlayerA; for each actor:
  - `X = actor.X - PlayerA.X`;
  - `X >= 0`: smallest positive distance -> ahead index/speed;
  - `X < 0`: smallest negative distance -> behind index/speed;
  - increments the place counter for actors behind PlayerA, skipping the first
    opponent `$FF1F2A`.
- `Race_ram_PlayerPlace = count` if `< 10`, otherwise `(count-10)|$10`.
- Ahead speed = `distance / aheadActor.Speed`; behind speed =
  `-distance / PlayerA.Speed`; no target -> index `$FFFF`, speed 0.

## RAM / fields

- `Race_ram_VdpDmaControl` DMA control; `Race_ram_HIntVScroll`; `Race_ram_NearestBehindDistance`/`Race_ram_NearestAheadDistance` nearest distances.
- `ram_FF30EA/EE/F2/F6/FA/FE` HScroll layer values; `ram_FF3274` horizon/VScroll base.
- `Race_ram_CameraOffset` camera offset; `ram_FF1E54/56/60/64/68/76/7A/7E/86` camera/road state.
- `Race_ram_NearestBehindIndex`/`Race_ram_NearestAheadIndex` nearest actor indices;
  `Race_ram_NearestBehindSpeed`/`Race_ram_NearestAheadSpeed` engine-audio values;
  `Race_ram_PlayerPlace` player place.
- `Race_ram_RearviewTileRows` road tile rows; `ram_FF3238` marking widths; `ram_FF3A9C` marking X;
  `ram_FF1B50`/`ram_FFDE72` actor-sprite list/count.

## Open questions

- Exact HInt layer/table offsets and the sky/horizon/road splits.
- Engine-audio mapping of `Race_ram_NearestBehindSpeed`/`Race_ram_NearestAheadSpeed` into the audio routine.
- `Race_ProjectActorSprite` field semantics and the road-marking data layout.
- The `src/race/race_ai.asm` road profile/interpolation/object/AI chain (next).

## Rename proposals (apply only on request)

The function/data renames above are applied. Remaining field names are proposals:

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `ram_FF1E54`/`56`/`60`/`64`/`68`/`76`/`7A`/`7E`/`86` | camera/road fields | mixed | low |

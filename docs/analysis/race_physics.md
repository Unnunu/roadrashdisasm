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

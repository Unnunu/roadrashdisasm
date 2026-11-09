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
| `DmaWriteVRAM` | `0xD8FA` | VDP DMA: length/source/dest + `ram_FF14D8` control. |
| `DmaWriteCRAM` | `0xD92C` | Same for CRAM (`$C000` control). |
| `Race_DrawRearviewMirror` | `0xD9DA` | Rearview mirror road; player X/Y, HUD row 25, `ram_FF33CC`. |
| `Race_DrawMirrorRoad` | `0xDA3E` | Mirror road rows; palette/priority `$8000800` XOR. |
| `Race_ProjectActorSprite` | `0xDAE2` | Actor position vs player progress -> sprite Y/X. |
| `Race_DrawRoadMarkingHud` | `0xDD84` | Road marking in the HUD/mirror; widths/data A/B. |
| `Race_UpdateCamera` | `0xDE9E` | Camera offset, road position/curve; `Track_CurveBuffer`. |
| `Race_BuildVScrollInfo` | `0xE004` | HInt VScroll/raster layers (sky/horizon/road). |
| `Race_BuildHScrollTable` | `0xE494` | HInt HScroll table from the VScroll/alpha state. |
| `Race_UpdateNearestOpponent` | `0xE5EE` | Nearest ahead/behind actor; engine audio values. |

Data: `Race_RoadMarkingDataA/B` (`0xDC84`/`0xDD44`), `ram_FF33CC` road rows,
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

- `ram_FF14D8` DMA control; `ram_FF14DC/E0/E4` camera/nearest distances.
- `ram_FF30EA/EE/F2/F6/FA/FE` HScroll layer values; `ram_FF3274` horizon/VScroll base.
- `ram_FFD340` camera offset; `ram_FF1E54/56/60/64/68/76/7A/7E/86` camera/road state.
- `ram_FF36AE/B2` nearest actor indices; `ram_FF36B0/B4` engine-audio values;
  `ram_FF1B40` rank/count.
- `ram_FF33CC` road tile rows; `ram_FF3238` marking widths; `ram_FF3A9C` marking X;
  `ram_FF1B50`/`ram_FFDE72` actor-sprite list/count.

## Open questions

- Exact HInt layer/table offsets and the sky/horizon/road splits.
- Engine-audio mapping of `ram_FF36B0/B4` into the src/main.asm audio.
- `Race_ProjectActorSprite` field semantics and the road-marking data layout.
- The `src/race/race_ai.asm` road profile/interpolation/object/AI chain (next).

## Rename proposals (apply only on request)

The function/data renames above are applied. Remaining field names are proposals:

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `ram_FFD340` | `Race_CameraOffset` | camera subtraction in `Race_UpdateCamera` | medium |
| `ram_FF1B40` | `Race_NearestRank` | actor count/rank | medium |
| `ram_FF36B0`/`B4` | `Race_EngineAudio...` | nearest-opponent audio values | low |

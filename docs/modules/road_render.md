# Module card: `src/race/road_render.asm`

- **ROM range:** `0x008FB4`–`0x0098C1` (`src/race/race_hud_debug.asm` starts at `0x98C2`)
- **Status:** analyzed (object list/records, shape header/control/interpolator/tile-writer
  pixel map and Data4 flag path confirmed; L6c/E8)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/road_render.md`

## Role / purpose

Race object sprite-tile renderer. `src/race/race.asm` calls `Road_DrawObjects` after
the HUD updates; it walks the visible-object list and renders each object's 4bpp
sprite tiles and SAT chain (`RiderSprites_Build`). The `Road_*` names are historical:
the written tiles are object sprites, not the road surface.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Road_DrawObjects` | `0x942A` | `src/race/race.asm:1809` | Walk the visible-object list. |
| `Road_DrawObject` | `0x9484` | `Road_DrawObjects` | Render one 0x14-byte object record. |
| `Road_DrawStrip` | `0x8FB4` | `Road_DrawObject` | Road strip/tile + sprite chain. |
| `Road_InterpolateLeftEdge`/`Road_InterpolateRightEdge` | `0x9142`/`0x91F0` | `Road_DrawStrip` | Left/right edge interpolation. |
| `Road_WriteTileColumns`/`Road_ClearEdgeTiles` | `0x9306`/`0x93D2` | `Road_DrawStrip` | Road tile columns / clear edge tiles. |
| `Road_ScaleShape`/`Road_ProjectShapeSpecial`/`Road_ProjectShape` | - | `Road_DrawObject` | Shape/edge projection. |
| `Road_InterpolateRightEdgeAlt` | `0x9272` | — | Alternate/unused strip generator. |

## Control flow / state machine

`Road_DrawObjects`: for each index in `Road_VisibleObjectList` (0xFFFF-terminated), record =
`Road_ObjectArray + idx*$14`; save `Animation_ram_TileIndex/SpriteIndex` in
`ram_FF1362/1364`; call `Road_DrawObject`; restore on overflow.
`Road_DrawObject`: unmarshal the record, compute the shape(s) (`Road_ShapeTable`), project/clip,
call `Road_DrawStrip` (`Road_InterpolateLeftEdge/91F0` strips, `Road_WriteTileColumns/93D2` tiles, `RiderSprites_Build` sprites),
copy the chain into the SAT with the x offset/clipping, then the second shape.
`Road_DrawStrip`: build the two source-advance lists, write the object's sprite tiles
and build its SAT chain. The writer is column-major: per row/column it writes the four
4bpp bitplanes; `ram_FFDE6A` is the full-band gap, `ram_FFDE66` the remainder-band gap
and `ram_FFDE68` the 32-row band advance.

## RAM / ROM & structures

- Visible list `Road_VisibleObjectList` (`$FF1D50`); object array `Road_ObjectArray` (`$FFD37C`),
  0x14-byte records: x, y, scale, horizon, shape, flags, x offset, second shape.
- Record flags: bit15 mirror/facing (= bit7 of `$B`, selects the special mirrored path),
  bit14 side/lane (track objects), bits 10-8 SAT copy-pass count (read via the high
  byte), bits 12-13 priority, low 5 bits projected profile row.
- Road: `ram_FF0D26/0D28/0D2A/0D2E/102E`, `ram_FF132E/1330/1332/1336`,
  `ram_FF136A` (horizon), `ram_FF1366` (chain end).
- Projection: `Road_ram_MirrorFlag/133C/133E/1340/1342/1344/1348/134C/1350/1354/1356/1358/135A/135C/135E/1360/1362/1364`.
- Sprite state: `Animation_ram_SpriteIndex/TileIndex/BaseTile`, `ram_FFDE5E..70`,
  `Race_ram_CurrentSpriteAttributeTable` (double-buffered `$FF479C`/`$FF4E1C`),
  `Race_ram_CurrentSpriteTileArray`.
- `Road_ShapeTable` (`$3BF1A`): 564-entry shape pointer table + shape data `$3C7EC-$7DCA7`,
  now in `src/data/road_shapes.asm` (see `docs/analysis/road_shapes.md`); the dynamic
  sample `$05994E`, bytes `10 37 20 36 ...`).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Road_DrawObjects` | `0x942A` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_DrawObject` | `0x9484` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_DrawStrip` | `0x8FB4` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_InterpolateLeftEdge`/`Road_InterpolateRightEdge` | `0x9142`/`0x91F0` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_WriteTileColumns`/`Road_ClearEdgeTiles` | `0x9306`/`0x93D2` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_ScaleShape`/`Road_ProjectShapeSpecial`/`Road_ProjectShape` | - | [x] | [x] | [x] | - | [x] | [x] | analyzed |

Detailed listing and dynamic samples: `docs/analysis/road_render.md`.

## External calls / dependencies

- Caller: `src/race/race.asm` (`Road_DrawObjects`).
- Internal: `RiderSprites_Build` (rider sprite chain), `Animation_ram_*`/`Race_ram_*` state.
- `src/race/race.asm` also uses `Road_ShapeTable` (`0x10018`, `0x10352`).

## Hacks / bugs / quirks

- `Road_InterpolateRightEdgeAlt` has no direct caller; likely alternate/dead. `[static]`
- The module shares `Animation_ram_TileIndex`/`SpriteIndex` with the animation/sprite
  builders as a combined road/sprite cursor. `[static]`
- The SAT is double-buffered; the dynamic run showed `$FF479C`/`$FF4E1C`. `[dynamic]`

## Verified facts

- `[static]` `src/race/race.asm` -> `Road_DrawObjects` -> `Road_DrawObject` -> `Road_DrawStrip` -> `RiderSprites_Build`.
- `[static]` Object record layout and the 0x14-byte array/list.
- `[dynamic]` Demo list `1,2,3,4,9,0,A,B,5,6,C,D,E,7,8,F`; records/fields sampled;
  first `Road_DrawStrip` `d0=d1=$10000`, shape data `$05994E`.

## Hypotheses

- `[hypothesis]` The 16 demo objects are the player, opponents and road props; test:
  map object records to src/race/race.asm roles.
- `[hypothesis]` `Road_InterpolateRightEdgeAlt` is an unused early version of `Road_InterpolateRightEdge`.
- Resolved: exact shape-byte format, offset-list generation, writer strides and the
  Data4 side/second-shape/pass-count bits (L6c/E8).

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Object list/records | GDB demo race, `0x942A`/`0x9484` | 16-item list, 0x14 records | Layout confirmed |
| Road strip | GDB `0x8FB4` | d0=d1=$10000, shape `$05994E`, tile 4, sprite 2 | Strip builder confirmed |

# Analysis: `src/race/road_render.asm` (race road/object renderer)

- **Module:** race road-strip/tile renderer and visible-object sprite renderer
- **ROM range:** `0x008FB4`–`0x0098C1` (`src/race/race_hud_debug.asm` starts at `0x98C2`)
- **Status:** partially analyzed: object list/records, call graph and road-strip
  structure confirmed; the exact shape/projection math is TODO
- **Source:** `src/race/road_render.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/rider_sprites.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Road_DrawObjects` | `0x942A` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_DrawObject` | `0x9484` | [x] | [~] | [x] | [x] | [x] | [x] | partial |
| `Road_DrawStrip` | `0x8FB4` | [x] | [~] | [x] | [x] | [x] | [x] | partial |
| `Road_InterpolateLeftEdge` | `0x9142` | [x] | [~] | [x] | [x] | [x] | - | partial |
| `Road_InterpolateRightEdge` | `0x91F0` | [x] | [~] | [x] | [x] | [x] | - | partial |
| `Road_InterpolateRightEdgeAlt` | `0x9272` | [?] | [?] | [x] | - | - | - | unused/alternate? |
| `Road_WriteTileColumns` | `0x9306` | [x] | [~] | [x] | [x] | [x] | - | partial |
| `Road_ClearEdgeTiles` | `0x93D2` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `Road_ScaleShape` | `0x978C` | [x] | [~] | [x] | - | [x] | - | partial |
| `Road_ProjectShapeSpecial` | `0x97BC` | [x] | [~] | [x] | - | [x] | - | partial |
| `Road_ProjectShape` | `0x9836` | [x] | [~] | [x] | - | [x] | - | partial |

## Role & call graph

`src/race/race.asm` calls `Road_DrawObjects` (`0x1809`) after the HUD/road updates. The renderer walks the
visible-object list and, for each object, draws the road strip/tile and copies the
object's rider/vehicle sprite chain into the SAT:

```
src/race/race.asm (0x1809)
  Road_DrawObjects             ; walk Road_VisibleObjectList visible list
    Road_DrawObject           ; render one object (Road_ObjectArray record)
      Road_DrawStrip         ; road strip/tile + sprite chain for the object
        Road_InterpolateLeftEdge       ; left/road edge scanline interpolation
        Road_InterpolateRightEdge       ; right/road edge interpolation
        Road_WriteTileColumns       ; write road tile columns
        Road_ClearEdgeTiles       ; clear remaining edge tiles
        RiderSprites_Build       ; rider/bike SAT chain builder (docs/analysis/rider_sprites.md)
      Road_ScaleShape/97BC/9836 ; shape/edge projection helpers
```

`Road_InterpolateRightEdgeAlt` is a near-duplicate of `Road_InterpolateRightEdge` with fixed `$10000` scaling and no direct
caller in the disassembled source; likely an unused/alternate strip generator.

## Object list and records

- Visible list `Road_VisibleObjectList` (`$FF1D50`): CPU object indices, `$FFFF`-terminated. Built
  by `src/race/race.asm` (`Road_BuildVisibleList` from `ram_FF1B50`/`ram_FF1C50`).
- Object array `Road_ObjectArray` (`$FFD37C`), 0x14 bytes per record. Fields used by this
  module:

| Offset | Use |
|---|---|
| `+0` | signed x (road/object position). |
| `+2` | y / vertical position. |
| `+4` | scale (`<<2` -> `ram_FF1350`, movement per frame). |
| `+6` | horizon/limit (`ram_FF136A`). |
| `+8` | shape index into `Road_ShapeTable` -> `ram_FF1348`. |
| `+$A` | flags: bit15 = shadow/overlay (`ram_FF133A`); bits 12-13 -> `ram_FF133E` (`<<1`); bit7 of `$B` = special/two-part path; low 3 bits = sprite rows to copy. |
| `+$C` | sprite x offset. |
| `+$E`,`+$10` | not read by this module (race-side data). |
| `+$12` | second shape index (two-part object). |

`Road_DrawObjects` saves `Animation_ram_TileIndex/SpriteIndex` in `ram_FF1362/1364` before
rendering each object and restores them on overflow.

## `Road_DrawObject` (object renderer)

1. Reset `ram_FFDE62`, `ram_FF133A`; copy the record x/y to `ram_FFDE6E/70` and the
   adjusted copies to `ram_FF1342/44`; `ram_FF1350 = scale<<2`; `ram_FF136A = +6`.
2. Shadow: if `+$A` bit15 is set, `ram_FF133A=1`.
3. Priority bits: `(flags & $3000)<<1` -> `ram_FF133E`.
4. Shape: `Road_ShapeTable[+8]` -> `ram_FF1348`; second shape `Road_ShapeTable[+$12]` ->
   `ram_FF134C`.
5. Special path (bit7 of `+$B`): call `Road_ScaleShape`/`Road_ProjectShapeSpecial` to get the edge values,
   store `ram_FF1356/1358`, then continue with the second shape; otherwise `Road_ProjectShape`
   computes the edge clip and `ram_FF135E`.
6. Call `Road_DrawStrip` to build the road strip and sprite chain; if the chain end flag
   `ram_FF1366` is set, restore the saved animation indices and abort.
7. If the second shape is active, reposition and repeat `Road_DrawStrip`.
8. Copy the new sprite chain from the SAT into the free slots (`Animation_ram_SpriteIndex`),
   applying the `+$C` x offset and the `$FFC0/$FE20/$50` clipping; update the chain
   links and `Animation_ram_SpriteIndex`; when a sprite goes above the road, back up.

## `Road_DrawStrip` (road strip)

- Inputs: `d0`/`d1` road-edge geometry (the dynamic race used `$10000` for both),
  `a0` shape data.
- Initializes `ram_FF0D26` (tile index*32), the strip accumulators
  `ram_FF132E/1330/1336`, and two strip arrays `ram_FF0D2E`/`ram_FF102E`.
- `Road_InterpolateLeftEdge` (d0) and `Road_InterpolateRightEdge` (d1) interpolate the left/right edge into the strip
  arrays (`d6` = strip count; `$7FFF` horizon limit; the `ram_FF133C` mirror flag; the
  `ram_FF135E` edge offset; the `ram_FF1340` acceleration).
- `Road_WriteTileColumns` writes the road tile columns (0x1F wide) into the sprite tile array
  (`Race_ram_CurrentSpriteTileArray + ram_FF0D26`); `Road_ClearEdgeTiles` clears the remaining
  edge tiles.
- The special road section (`ram_FF1354/56/58`) handles the elevated/overpass edge
  offset.
- `RiderSprites_Build` builds the rider/bike chain; the object x/y/scale/shape are fed from the
  `ram_FFDE*` fields.

## Shape table / data

- `Road_ShapeTable` (`0x3BF1A`) is a table of 564 shape-data pointers (`src/race/race.asm` uses
  it at `0x10018`/`0x10352` too); `word_3C7EA` holds the shape count `$234`.
- Shape data (`$3C7EC-$7DCA7`) is now extracted in `src/data/road_shapes.asm` (table/count from
  source, bytes raw; format TODO).
- `Road_ScaleShape` reads shape bytes `(a2)`/`1(a2)` and uses `2(a2)` when the
  mirror bit (`$A` bit15) is set: `d5/d6 = byte * (scale>>2) <<2 >>16`, i.e. a
  fixed-point `byte * scale >> 16` pair.
- `Road_ProjectShapeSpecial` multiplies shape byte0 by `scale>>2`, subtracts the
  edge (`d5`), adds object X, `$C0`, applies the mirror bit and clips; it returns
  the projected edge and sets `ram_FFDE62` when outside `0..edge`.
- `Road_ProjectShape` is the non-special variant: it uses half the width, stores
  the clip in `ram_FF135E`, and also sets `ram_FFDE62` on overflow.
- `Road_DrawObject` calls the special path when `$B` bit7 is set (two-part object),
  storing `ram_FF1356/1358` (first edge) and `ram_FF135A/135C/135E/1360`
  (second shape). The exact shape-byte format and the `$C0/$200` constants are
  still under verification.

## RAM summary

- Object list/array: `Road_VisibleObjectList`, `Road_ObjectArray` (0x14 records).
- Road: `ram_FF0D26/0D28/0D2A/0D2E/102E`, `ram_FF132E/1330/1332/1336`,
  `ram_FF136A` (horizon), `ram_FF1366` (chain end).
- Object/projection: `ram_FF133A` (shadow), `ram_FF133C` (mirror), `ram_FF133E`
  (priority), `ram_FF1340/1342/1344/1348/134C/1350/1354/1356/1358/135A/135C/135E/1360/1362/1364`.
- Sprite state: `Animation_ram_SpriteIndex/TileIndex/BaseTile`, `ram_FFDE5E..70`,
  `Race_ram_CurrentSpriteAttributeTable` (double-buffered `$FF479C`/`$FF4E1C`),
  `Race_ram_CurrentSpriteTileArray`.

## Dynamic evidence (demo race)

- `Road_DrawObjects` visible list at `$FF1D50`:
  `1,2,3,4,9,0,A,B,5,6,C,D,E,7,8,F` (16 objects); the SAT alternates
  `$FF479C`/`$FF4E1C` (double buffer).
- `Road_DrawObject` records (x,y,scale,horizon,shape,flags,...):
  - `$FFD390`: `FEBA 008A 4000 008A 0056 8081 ...` (shadow flag set).
  - `$FFD3A4`: `FE66 008A 4000 008A 0057 2081 ...`.
  - `$FFD430`: `FF30 0060 5174 0060 01C3 1184 FF56 0380 00AC 01C4`.
- First `Road_DrawStrip`: `d0=d1=$10000`, shape data `$05994E` (`10 37 20 36 ...`);
  shape pointer `$05994C` is advanced by `+2` from the projection header,
  `Animation_ram_TileIndex=4`, `Animation_ram_SpriteIndex=2`.
- The object record layout and the list/SAT double-buffer are confirmed. The earlier `Road_DrawObject` breakpoint spam was a GDB `disable $bpnum` artifact, not a
  code issue.

## Quirks / open questions

- `Road_InterpolateRightEdgeAlt` has no direct caller; likely alternate/dead. `[static]`
- `Road_DrawStrip` uses `Animation_ram_TileIndex` as a road/sprite tile cursor, sharing the
  animation state with `RiderSprites_Build`/`src/race/animation.asm`. `[static]`
- The object `+$E`/`+$10` words are not read here; they belong to the race-side object
  logic. `[static]`
- TODO: exact shape-byte format, the `$C0/$200` constants and the interpolation;
  map the 16 demo objects to their race roles (player/opponents/props).


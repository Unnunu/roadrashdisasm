# Analysis: `src/race/road_render.asm` (race object sprite renderer)

- **Module:** race object sprite-tile renderer and visible-object sprite renderer
- **ROM range:** `0x008FB4`–`0x0098C1` (`src/race/race_hud_debug.asm` starts at `0x98C2`)
- **Status:** analyzed (object list/records, shape record/control/interpolator/writer
  pixel map and Data4 flag path confirmed statically + E8)
- **Source:** `src/race/road_render.asm`
- **Related:** `docs/analysis/road_shapes.md`, `docs/analysis/race_track_data.md`,
  `docs/analysis/shape_writer_verify.md`, `docs/analysis/rider_sprites.md`,
  `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Road_DrawObjects` | `0x942A` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_DrawObject` | `0x9484` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_DrawStrip` | `0x8FB4` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_InterpolateLeftEdge` | `0x9142` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_InterpolateRightEdge` | `0x91F0` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_InterpolateRightEdgeAlt` | `0x9272` | [x] | [x] | [x] | - | - | - | unused/alternate |
| `Road_WriteTileColumns` | `0x9306` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_ClearEdgeTiles` | `0x93D2` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `Road_ScaleShape` | `0x978C` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `Road_ProjectShapeSpecial` | `0x97BC` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `Road_ProjectShape` | `0x9836` | [x] | [x] | [x] | - | [x] | [x] | analyzed |

## Role & call graph

`src/race/race.asm` calls `Road_DrawObjects` after the HUD/road updates. The renderer
walks the visible-object list and, for each object, projects the shape, writes the
object's 4bpp sprite tiles into the sprite tile staging array and builds the SAT chain:

```
src/race/race.asm (0x1809)
  Road_DrawObjects             ; walk Road_VisibleObjectList visible list
    Road_DrawObject           ; render one object (Road_ObjectArray record)
      Road_ScaleShape/ProjectShape*  ; shape edge / mirror projection
      Road_DrawStrip         ; sprite tile columns + SAT chain for the object
        Road_InterpolateLeftEdge       ; left offset list (source advances)
        Road_InterpolateRightEdge      ; right offset list (per-row advance)
        RiderSprites_Build       ; rider/bike SAT chain builder
        Road_WriteTileColumns    ; source rows -> 4bpp sprite tiles
        Road_ClearEdgeTiles      ; zero the unused edge tiles
```

Despite the `Road_*` names, the destination is `Race_ram_CurrentSpriteTileArray`
(sprite staging), not the road surface. The road surface is the background plane /
HScroll path covered by L6a (`Race_BuildHScrollTable`). `[static]`

`Road_InterpolateRightEdgeAlt` has no direct caller; it is an alternate/dead variant
with a fixed `$10000` scale. `[static]`

## Object list and records

- Visible list `Road_VisibleObjectList` (`$FF1D50`): CPU object indices, `$FFFF`-terminated. Built
  by `Road_BuildVisibleList` from `ram_FF1B50` (unsorted producer keys) into
  `ram_FF1C50` (sorted keys) + `ram_FF1D50` (indices).
- Object array `Road_ObjectArray` (`$FFD37C`), 0x14 bytes per record. Fields used by this
  module:

| Offset | Symbol | Use |
|---|---|---|
| `+0` | `RoadObject_X` | signed x (road/object position). |
| `+2` | `RoadObject_Y` | y / vertical position. |
| `+4` | `RoadObject_Scale` | scale (`<<2` -> `ram_FF1350`, movement per frame). |
| `+6` | `RoadObject_Limit` | horizon/limit (`ram_FF136A`). |
| `+8` | `RoadObject_Shape` | shape index into `Road_ShapeTable` -> `ram_FF1348`. |
| `+$A` | `RoadObject_Flags` | bit15 = horizontal-mirror/facing; bit14 = side/lane direction (track objects); bits 10-8 = SAT copy-pass count (read via the high byte); bits 12-13 -> `ram_FF133E` priority; low 5 bits = projected profile row. |
| `+$C` | `RoadObject_XOffset` | sprite x offset. |
| `+$E`,`+$10` | `RoadObject_ReservedE/10` | not read by this module (race-side data). |
| `+$12` | `RoadObject_Shape2` | second shape index (two-part object). |

`Road_DrawObjects` saves `Animation_ram_TileIndex/SpriteIndex` in `ram_FF1362/1364` before
rendering each object and restores them on overflow.

## `Road_DrawObject` (object renderer)

1. Reset `ram_FFDE62`, `Road_ram_MirrorFlag`; copy the record x/y to `ram_FFDE6E/70` and the
   adjusted copies to `ram_FF1342/44`; `ram_FF1350 = scale<<2`; `ram_FF136A = +6`.
2. Mirror/facing: if `+$A` bit15 is set, `Road_ram_MirrorFlag=1`.
3. Priority bits: `(flags & $3000)<<1` -> `ram_FF133E`.
4. Shape: `Road_ShapeTable[+8]` -> `ram_FF1348`; second shape `Road_ShapeTable[+$12]` ->
   `ram_FF134C`.
5. Special path (byte `+$B` bit7 set = flags bit15): `Road_ScaleShape` +
   `Road_ProjectShapeSpecial`, then `Road_DrawStrip`; otherwise `Road_ProjectShape`
   computes the clip and `ram_FF135E`.
6. `Road_WriteTileColumns` / `RiderSprites_Build` via `Road_DrawStrip`; if the chain end
   flag `ram_FF1366` is set, restore the saved animation indices and abort.
7. If the second shape is active, reposition and repeat `Road_DrawStrip`.
8. Copy the new sprite chain from the SAT into the free slots (`Animation_ram_SpriteIndex`),
   applying the `+$C` x offset and the `$FFC0/$FE20/$50` clipping; update the chain
   links; when a sprite goes above the road, back up.

The SAT copy-pass count is `move.b RoadObject_Flags(a0),d7` (the **high** byte) then
`andi.w #7,d7`, i.e. `(Flags >> 8) & 7`. The copy loop runs that many passes over the
`SpriteIndex - savedIndex` new entries. `[confirmed]` E8-B: object `$FFD430`
(`flags=$1184`, pass=1, row=4) copied 6 entries once; pass=0 objects skipped the loop.

## Shape record and interpolator pipeline (L6c)

### Header layout

| Pointer | Normal path (`P`) | Special/two-part path (`P`, byte `+$B` bit7) |
|---|---|---|
| `P+0` | left control | first-shape edge byte (projection + mirror width delta) |
| `P+1` | right control | second projection byte |
| `P+2` | fill/tile word high | left control (= `P+2`) |
| `P+3` | fill/tile word low | right control |
| `P+4` | row data | fill/tile word high |
| `P+5` | row data | fill/tile word low |
| `P+6` | row data | row data |

The fill word becomes `ram_FFDE5E` and is ORed into each SAT tile/priority word by
`RiderSprites_Build`. For shape `$56` the word is `$2036` -> palette 1, tile base `$36`.
`[dynamic]`

### Controls and offset lists

`Road_DrawStrip` consumes two control bytes from `a0` (the shape pointer already
advanced to `P` or `P+2`):

- `Road_InterpolateLeftEdge(ctrl, scale, clip)` emits one 16-bit entry per output
  source byte. Each entry is the **source advance after that byte** (normally 1; 0
  duplicates the byte, >1 skips). It writes `ram_FF1332 = ceil(ctrl/2)+1` and
  `ram_FF1336 = raw entry count`, pads the list to a multiple of 4, and returns
  `d6 = ((padded+1) >> 2) - 1`. `Road_DrawStrip` stores that in `ram_FF132E`, so
  the writer emits `ram_FF132E + 1` 8-pixel columns per band.
- `Road_InterpolateRightEdge(ctrl, scale, clip)` emits one entry per source row.
  Each entry is the source advance after that row (normally 1 at scale `$10000`;
  larger when the scale is smaller; negative through the mirror path). It returns
  `d6 = rows`, and `Road_DrawStrip` stores `d6-1` in `ram_FF1330`, so the writer
  processes `ram_FF1330 + 1` source rows. `ram_FF0D28` is the padded
  right-count remainder used by `Road_ClearEdgeTiles`.
- `clip` is `ram_FF135E`: 0 = no horizontal clip, >0 limits the emitted entries
  from the left, <0 from the right (control-byte threshold + `$7FFF` horizon limit).

The generation algorithm (both routines):

```
acc = 0; run = 0
for each control step:
    run += 1
    acc += scale
    while acc >= $10000 and clip budget not exhausted:
        emit run (or the mirror-adjusted value)
        run = 0; acc -= $10000
```

`[confirmed]` E8-A: the generated lists match the live RAM lists for shape `$56`
(scale `$10000`: 16 x `1` + padding `0`; right: `1` every row), shape `$57`
(scale `$10000`), and shape `$1C3` (controls `$1e/$1c`, scale `$145D0`: left
`1,1,1,1,0,1,1,1,1,0,1,1,1,1,0,1,1,1,0,0`; right `1,1,1,1,18,1,1,1,...`).

### `Road_WriteTileColumns` destination map

Inputs: `ram_FF0D2A` (row-data pointer), `ram_FF0D26` (tile cursor*32),
`ram_FF132E` (columns-1), `ram_FF1330` (rows-1), `ram_FFDE68/6A/66` (strides),
plus the two offset lists.

For each source row `r` (`0 .. ram_FF1330`):

- `a4` starts at the band base and advances `+4` per row.
- For each column `c` (`0 .. ram_FF132E`), write the next 4 source bytes to
  `a4 + c*(gap+4) .. +3`; after each byte advance the source by the next left-list
  entry.
- The 4 bytes are the four 4bpp bitplanes of one 8-pixel scanline of that column, so
  the destination is **column-major**: one column = `gap+4` bytes = `tiles_y * 32`.
- After the row, advance the source by the next right-list entry.
- Every 32 rows (`d4` wraps from 0) add `ram_FFDE68` to `a4` and switch `gap` from
  `ram_FFDE6A` to `ram_FFDE66` for the remainder band.

Strides `[confirmed]` E8-A + golden replay:

- `ram_FFDE6A = $7C` -> full-band column stride `$80` (4 tiles tall).
- `ram_FFDE66 = $5C` -> remainder-band column stride `$60` (3 tiles tall).
- `ram_FFDE68 = $200` -> band advance after the 32-row/128-byte partial advance.
  `RiderSprites_Build` computes it from the first row's tile span; it is not a
  fixed constant.

**Byte-exact validation** `[confirmed]`: replaying the model on shape `$56`
(`base=$FF511C`, `src=$059952`, scale `$10000`, `132E=4`, `1330=$35`,
`DE66/68/6A=$5C/$200/$7C`) reproduces all 1080 bytes written by the live writer with
**0 mismatches**; the destination range `$FF511C..$FF5573` matches the golden
`shape_writer_after.bin`. Shape `$56` is 5 columns x 54 rows (40 x 54 px; a 32-row
4-tile band plus a 22-row remainder band).

`Road_ClearEdgeTiles` writes zero words to the unused edge strip bytes selected by
`ram_FF0D28` and `ram_FFDE66`; it does not touch the writer's data bytes.

## Shape table / data

- `Road_ShapeTable` (`0x3BF1A`) is a table of 564 shape-data pointers (`src/race/race.asm` uses
  it at `0x10018`/`0x10352` too); `word_3C7EA` holds the shape count `$234`.
- Shape data (`$3C7EC-$7DCA7`) is extracted in `src/data/road_shapes.asm` (table/count from
  source, bytes raw).
- `Road_ScaleShape` reads `P+0/P+1` and uses `P+2` when the mirror bit
  (`$A` bit15) is set: `d5/d6 = byte * (scale>>2) <<2 >>16`, i.e. a fixed-point
  `byte * scale >> 16` pair. The mirror width delta is `P+2 - P+0`.
- `Road_ProjectShapeSpecial` multiplies the shape byte by `scale>>2`, subtracts the
  edge (`d5`), adds object X and `$C0`, applies the mirror bit and clips; it returns
  the projected edge and sets `ram_FFDE62` when outside `0..edge`.
- `Road_ProjectShape` is the non-special variant: it uses half the width, stores the
  clip in `ram_FF135E`, and also sets `ram_FFDE62` on overflow.

## RAM summary

- Object list/array: `Road_VisibleObjectList`, `Road_ObjectArray` (0x14 records).
- Shape strip: `ram_FF0D26/0D28/0D2A/0D2E/102E`, `ram_FF132E/1330/1332/1336`,
  `ram_FF136A` (horizon), `ram_FF1366` (chain end).
- Object/projection: `Road_ram_MirrorFlag` (facing/mirror), `ram_FF133C` (strip mirror),
  `ram_FF133E` (priority), `ram_FF1340/1342/1344/1348/134C/1350/1354/1356/1358/135A/135C/135E/1360/1362/1364`.
- Sprite state: `Animation_ram_SpriteIndex/TileIndex/BaseTile`, `ram_FFDE5E..70`,
  `Race_ram_CurrentSpriteAttributeTable` (double-buffered `$FF479C`/`$FF4E1C`),
  `Race_ram_CurrentSpriteTileArray`.

## Dynamic evidence (demo race)

- `Road_DrawObjects` visible list at `$FF1D50`:
  `1,2,3,4,9,0,A,B,5,6,C,D,E,7,8,F` (16 objects); the SAT alternates
  `$FF479C`/`$FF4E1C` (double buffer).
- `Road_DrawObject` records (x,y,scale,horizon,shape,flags,...):
  - `$FFD390`: `FEBA 008A 4000 008A 0056 8081 ...` (mirror/facing bit set).
  - `$FFD3A4`: `FE66 008A 4000 008A 0057 2081 ...`.
  - `$FFD430`: `FF30 0060 5174 0060 01C3 1184 FF56 0380 00AC 01C4`.
- First `Road_DrawStrip`: `d0=d1=$10000`, shape entry `$05994E` (`10 37 20 36`);
  the special path advances the shape pointer by `+2`, so controls/fill/row data
  are read from the advanced pointer; `ram_FF0D2A` lands at shape+6.
- E8-C: at `Road_DrawObjects`, `ram_FFDE72=22`, `PlayerProgress=$00078000`;
  `ram_FF1B50` is the raw producer key list, `ram_FF1C50` is ascending
  (`$00008000,$00008000,$00038000,...`), and `ram_FF1D50` is the index order drawn.

## Quirks / open questions

- `Road_InterpolateRightEdgeAlt` has no direct caller; alternate/dead. `[static]`
- The `Road_*` names describe object sprite tiles, not the road surface. `[static]`
- The object `+$E`/`+$10` words are not read here; they belong to the race-side object
  logic. `[static]`
- `Flags` bit overload (`row` low 5 bits vs. pass count in bits 10-8) is resolved
  (former `U-0019`); see `docs/analysis/race_track_data.md` for the Data4 sources.
- Remaining optional visual check: compose the writer's tile output with the live SAT
  chain and crop it to the true sprite; `preview_sat_size_line0.png` is the current
  best candidate.

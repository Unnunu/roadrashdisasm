# Analysis: `src/screens/rider_sprites.asm` (animated rider/bike sprite builder)

- **Module / routine:** builds a linked rider/bike sprite chain in the race SAT
- **ROM range:** `0x005760`–`0x0059C3` (`src/screens/rider_intro.asm` starts at `0x59C4`)
- **Status:** analyzed statically; confirmed dynamically in the demo race
- **Source:** `src/screens/rider_sprites.asm`
- **Related:** `docs/analysis/road_render.md`, `docs/analysis/animation.md`,
  `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RiderSprites_Build` | `0x5760` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `RiderSprites_BuildAlt` | `0x593E` | [x] | [x] | - | - | [x] | - | analyzed (wrapper) |
| `RiderSprites_StripTable` | `0x5944` | [x] | [x] | [x] | [x] | [x] | - | analyzed (per-block table) |

## Role

Called from `Road_DrawStrip` (`src/race/road_render.asm:97`, `bsr.w RiderSprites_Build`)
to build the next chunk of the rider/bike sprite chain in the sprite attribute table
(`Race_ram_CurrentSpriteAttributeTable`, `$FF38AC`). It writes linked SAT entries
`Y, size/link, tile/priority, X`, advances the animation tile cursor and sprite index,
and can emit a horizontally mirrored copy.

## How it works (conceptual model)

The rider/bike bitmap is not stored as SAT-shaped rects: the graphics are tiled at
runtime into a rectangular grid of VDP sprites (max 4x4 cells each).

1. The caller packs the required tile extent into `d0` (horizontal) and `d1`
   (vertical) as `tiles * 8`. The low bits of the packed value are the *remainder*
   block size; `d>>5` is the number of full 4-tile blocks before it.
2. `RiderSprites_Build` splits both inputs into a block count and a 2-bit remainder
   code (`C` for `d0`, `R` for `d1`). The grid is therefore
   `d2` full 4-wide blocks + one `(C+1)`-wide remainder block, and
   `d3` full 4-high blocks + one `(R+1)`-high remainder block.
3. Each grid cell becomes one SAT entry. `RiderSprites_StripTable[4*R + C]` gives its
   geometry: Y step `8*(R+1)`, size code `(4*C+R)`, tile step `(R+1)*(C+1)` and X step
   `8*(C+1)`. Interior cells use the full 4x4 code (C=R=3); only the last row/column
   use the smaller remainder codes.
4. Entries are written sequentially from `Animation_ram_SpriteIndex` and chained by
   the low byte of the size/link word. `Animation_ram_TileIndex` is the shared tile
   cursor: it advances by the tile step of each cell and stops the chain at `$150`.
5. A second "mirror" pass is selected by `ram_FF133A`: it sets the H-flip bit `$800`
   on the tile word and walks X *left* instead of right (see `U-0007`).

## Caller contract (`Road_DrawStrip`)

- `d0 = (ram_FF132E + 1) << 3` (`ram_FF132E` = interpolated left-edge strip count).
- `d1` = `(ram_FF1330 + 1)` rounded up to a multiple of 8 (`ram_FF1330` = interpolated
  right-edge/height count). Both inputs are therefore `tiles*8`.
- Before the call the caller sets `ram_FFDE6E/70` (base X/Y) and, on a mirrored
  object, `ram_FF133A = 1` (`Road_DrawObject`, `RoadObject_Flags` bit15).
- After the call the caller checks `ram_FFDE62` (chain end/overflow) and
  `ram_FF1366` (tile-budget/list overflow) to abort or restore the animation cursors.

## Loop / algorithm (ROM order)

1. `ram_FFDE68 = $8000` (sentinel); `a0 = SAT + SpriteIndex*8`.
2. If `SpriteIndex == 0` skip linking. If `1..$4F`, OR the index into the previous
   entry's link byte (`or.w d2,-6(a0)`). If `>= $50` (80 SAT slots) set
   `ram_FF1366`/`ram_FFDE62 = $FFFF` and return.
3. Pack geometry from `d0/d1`:
   - `d2 = d0>>5`; `d0 &= $18`; if zero, `d2--`, `d0 = $20`; then `d0 -= 8` ->
     `ram_FF0906` (C offset `0..$18`).
   - `d3 = d1>>5`; `d1 &= $18`; if zero, `d3--`, `d1 = $20`; then `d1 -= 8`, `<<2` ->
     `ram_FF0908` (R offset `0..$60`).
   - Store counts in `ram_FF090A/C`; set the road-writer strides
     `ram_FFDE6A = $7C`, `ram_FFDE66 = ram_FF0908 + $1C`, and use the shorter
     `ram_FFDE66` for `ram_FFDE6A` when `d3 == 0`.
4. Outer loop (rows, `d3`), inner loop (columns, `d2`):
   - `Y = ram_FFDE70 + $80`; `X = ram_FFDE6E + $80`
     (+ `2*ram_FF1336` on the mirrored pass).
   - Select the record: full block (`C=3` -> `$18`, `R=3` -> `$60`) except on the last
     column/row, which use `ram_FF0906`/`ram_FF0908`.
   - Build `size/link = (size_code<<8) | link`, write `Y, size/link`.
   - Build `tile = tile_cursor | priority | ram_FFDE5E | Animation_ram_BaseTile`
     (`$8000` when `Y < $118`; `$800` H-flip plus `X -= 8*(C+1)` when mirrored),
     write `tile` and `X`.
   - Advance the link and the tile cursor by the record's tile step. When the tile
     cursor reaches `$150`, set both end flags, clear the previous link and return.
   - On the non-mirrored pass advance X by `8*(C+1)` after each column.
5. After each row: `Y += 8*(R+1)`; reload the column count; on the first row derive
   `ram_FFDE68 = (tiles_used_in_first_row - 4) << 5` (road-tile-array row stride).
6. After the last row: clear the last link, `SpriteIndex = last_link - 1`,
   `Animation_ram_TileIndex = tile cursor`; return.

## SAT entry format

| Word | Meaning |
|---|---|
| 0 | `Y` (screen coordinate - `$80`, applied by the SAT consumer). |
| 1 | `size_code << 8 | link_index` (low byte is the next-entry link). |
| 2 | tile/priority: bit15 priority (`$8000`), H-flip bit11 (`$800`), low bits tile index. |
| 3 | `X`. |

`$8000` (priority) is set for sprites with `Y < $118`. `$800` is the **H-flip** bit,
not priority: `UpdateAnimation` masks palette/flip with `$7800` and sets priority with
`$8000`, so `$800 = bit11 = horizontal flip`.

## `RiderSprites_StripTable` (`0x5944`, 128 bytes = 16 records x 8 bytes)

`record = RiderSprites_StripTable + (4*R + C)*8`, where `C` = horizontal remainder code
(from `d0`) and `R` = vertical remainder code (from `d1`). Each record describes a
`(C+1) x (R+1)` tile sprite:

| Offset | Word | Value | Use |
|---|---|---|---|
| `+0` | `word[table+0]` | `8*(R+1)` | Y advance (sprite height in pixels). |
| `+2` | `word[table+2]` | `(4*C+R) << 8` | VDP size code (low byte is the link). |
| `+4` | `word[table+4]` | `(R+1)*(C+1)` | Tile-index step (tiles per sprite). |
| `+6` | `word[table+6]` | `8*(C+1)` | X step (sprite width in pixels). |

The size code is consistent with `Animation_dTileCountMinus1` in `animation.asm`, whose
table maps a size nibble `v` to `((v>>2)+1)*((v&3)+1)` tiles, exactly matching
`(C+1)*(R+1)` with `v = 4*C+R`. The table is now a generated 4x4 matrix, so the byte
values are fully explained (no unverified per-record meanings remain).

## RAM state (touched by this file)

| Address | Name | Meaning |
|---|---|---|
| `$FF38AC` | `Race_ram_CurrentSpriteAttributeTable` | SAT base pointer. |
| `$FFDE60` | `Animation_ram_TileIndex` | Tile cursor (advanced per sprite). |
| `$FFDE64` | `Animation_ram_SpriteIndex` | Next free SAT slot / chain head index. |
| `$FFD34A` | `Animation_ram_BaseTile` | Base tile added to every entry. |
| `$FFDE5E` | `ram_FFDE5E` | Object palette/priority/base bits ORed into the tile word. |
| `$FFDE62` | `ram_FFDE62` | Chain-end/overflow flag (`$FFFF`). |
| `$FFDE66` | `ram_FFDE66` | Road-writer within-row stride (single-row case). |
| `$FFDE68` | `ram_FFDE68` | Road-writer row stride (`$8000` sentinel, then computed). |
| `$FFDE6A` | `ram_FFDE6A` | Road-writer within-row stride (`$7C` default). |
| `$FFDE6E` | `ram_FFDE6E` | Base X (SAT = value + `$80`). |
| `$FFDE70` | `ram_FFDE70` | Base Y (SAT = value + `$80`). |
| `$FF0906` | `ram_FF0906` | Horizontal remainder code `C` as a byte offset (`C*8`). |
| `$FF0908` | `ram_FF0908` | Vertical remainder code `R` as a byte offset (`R*$20`). |
| `$FF090A` | `ram_FF090A` | Horizontal block count. |
| `$FF090C` | `ram_FF090C` | Vertical block count. |
| `$FF090E` | `ram_FF090E` | Tile cursor at the start of the current row. |
| `$FF1336` | `ram_FF1336` | Mirror X offset (applied as `2*value` on the mirrored pass). |
| `$FF133A` | `ram_FF133A` | Mirror pass flag (from `RoadObject_Flags` bit15). |
| `$FF1366` | `ram_FF1366` | Second chain-end flag (tile-budget/SAT overflow). |

## `RiderSprites_BuildAlt`

Wrapper: `bsr.w RiderSprites_Build; rts`. No caller in the disassembled source.

## Dynamic confirmation (BlastEm, GDB remote)

The demo race reached `RiderSprites_Build`'s return (`$593C`). Observed state:

- `Animation_ram_SpriteIndex=6`, `Animation_ram_TileIndex=$27`, `Animation_ram_BaseTile=0`.
- `ram_FFDE5E..70 = 0000 0027 0000 0006 005C 0200 007C FEAA 0053`.
- `ram_FF0906..0E = 0000 0040 0001 0001 0018`;
  `ram_FF1336=0010`, `ram_FF133A=0001`, `ram_FF1366=0000`.
- SAT base `$FF479C`, entries:
  - `0144 0401 8800 00F8`
  - `0130 0402 8802 0134`
  - `00D3 0F03 8804 FF2A`
  - `00D3 0304 8814 FF22`

The entries confirm the `Y, size/link, tile/priority, X` layout and the effect of the
mirror pass (H-flip bit `$800`, negative X). The captured sizes (`$04/$0F/$03`) are the
chain as later copied into free SAT slots by `Road_DrawObject`, not the raw order this
routine writes, so they are not a 1:1 check of the table rows.

## Verified facts

- `[static]` `RiderSprites_Build` writes linked 4-word SAT entries and maintains the
  animation tile/sprite cursors.
- `[static]` The caller packs the tile extent as `tiles*8` and the routine decomposes it
  into 4-tile blocks plus a remainder block.
- `[static]` `RiderSprites_StripTable` is a 4x4 matrix keyed by `(R, C)` with derived
  values `8*(R+1)`, `(4*C+R)<<8`, `(R+1)*(C+1)`, `8*(C+1)`.
- `[hardware]` In the SAT tile word, `$8000` is priority and `$800` is H-flip (see
  `UpdateAnimation`'s `$7800`/`$8000` masks).
- `[dynamic]` The demo race calls `RiderSprites_Build`; the SAT chain and a mirrored
  (`ram_FF133A=1`) entry set were observed.

## Hypotheses / open questions

- `[hypothesis]` The `d0/d1` inputs are the animation direction/size derived by
  `Road_DrawStrip` (left/right edge strip counts -> tile extents).
- `[hypothesis]` `ram_FF133A` (object flags bit15) mirrors the whole object; whether the
  mirrored copy is a shadow/reflection or an opposite-facing object is `U-0007`.
- `[ ]` Confirm `ram_FFDE66/68/6A` byte semantics in `Road_WriteTileColumns`
  (road_render analysis TODO).

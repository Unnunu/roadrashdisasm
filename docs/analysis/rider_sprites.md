# Analysis: `src/screens/rider_sprites.asm` (animated rider/bike sprite builder)

- **Module / routine:** builds a linked rider/bike sprite chain in the race SAT
- **ROM range:** `0x005760`–`0x0059C3` (`src/screens/rider_intro.asm` starts at `0x59C4`)
- **Status:** analyzed statically; confirmed dynamically in the demo race
- **Source:** `src/screens/rider_sprites.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RiderSprites_Build` | `0x5760` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `RiderSprites_BuildAlt` | `0x593E` | [x] | [x] | - | - | [x] | - | analyzed (wrapper) |
| `RiderSprites_StripTable` | `0x5944` | [x] | [x] | [x] | [x] | [x] | - | analyzed (per-strip table) |

## Role

Called from `src/race/road_render.asm` (`bsr.w RiderSprites_Build`) to build the next chunk of the rider/bike
sprite chain in the **sprite attribute table** (`Race_ram_CurrentSpriteAttributeTable`,
`$FF38AC`). It writes linked SAT entries `Y, size/link, tile/priority, X`, advances the
animation tile cursor and sprite index, and handles a second ("shadow"/overlay) layer.

## RAM state

| Address | Name | Meaning |
|---|---|---|
| `$FF38AC` | `Race_ram_CurrentSpriteAttributeTable` | SAT base pointer. |
| `$FFDE60` | `Animation_ram_TileIndex` | Tile cursor (advanced per sprite). |
| `$FFDE64` | `Animation_ram_SpriteIndex` | Sprite chain index / next link. |
| `$FFD34A` | `Animation_ram_BaseTile` | Base tile added to entries. |
| `$FFDE5E` | `ram_FFDE5E` | Base priority/tile bits ORed into the tile word. |
| `$FFDE62` | `ram_FFDE62` | "Sprite chain end" flag (`$FFFF`). |
| `$FFDE66` | `ram_FFDE66` | Current entry X (base). |
| `$FFDE68` | `ram_FFDE68` | Y offset / limit (`$8000` sentinel, then computed). |
| `$FFDE6A` | `ram_FFDE6A` | Base link/limit (`$7C`). |
| `$FFDE6E` | `ram_FFDE6E` | Base X (`+$80`). |
| `$FFDE70` | `ram_FFDE70` | Base Y (`+$80`). |
| `$FF0906` | `ram_FF0906` | Strip X base (direction/column). |
| `$FF0908` | `ram_FF0908` | Row/tile stride. |
| `$FF090A` | `ram_FF090A` | Column count (`d2`). |
| `$FF090C` | `ram_FF090C` | Row count (`d3`). |
| `$FF090E` | `ram_FF090E` | Starting tile index of the chunk. |
| `$FF1336` | `ram_FF1336` | Shadow/overlay X offset. |
| `$FF133A` | `ram_FF133A` | Shadow/overlay layer flag. |
| `$FF1366` | `ram_FF1366` | Second "end" flag. |

## Algorithm

1. `ram_FFDE68 = $8000` (sentinel); `a0 = SAT + SpriteIndex*8`.
2. If `SpriteIndex` is 0, skip linking; if `< $50`, OR the index into the previous
   entry's link (`or.w d2,-6(a0)`); if `>= $50`, set `ram_FF1366`/`ram_FFDE62 = $FFFF`
   and return (chain full/overflow).
3. Derive the strip geometry from the inputs `d0/d1`:
   - `d2 = d0>>5`, `d0 &= $18` (direction/column bits); if zero, `d2--`, `d0=$20`;
     `d0 -= 8` -> `ram_FF0906`.
   - `d3 = d1>>5`, `d1 &= $18`; if zero, `d3--`, `d1=$20`; `d1 -= 8`, `d1 <<= 2` ->
     `ram_FF0908`.
   - Store counts in `ram_FF090A/C`; set `ram_FFDE6A=$7C`;
     `ram_FFDE66 = ram_FF0908 + $20 - 4`; when `d3 == 0`, `ram_FFDE6A = ram_FFDE66`.
4. Loop over `d3` rows and `d2` columns; for each sprite:
   - `Y = ram_FFDE70 + $80`; `X = ram_FFDE6E + $80` (+ `2*ram_FF1336` when the shadow
     layer is active);
   - pick the table record `a1 = (0x18 or ram_FF0906) + (0x60 or ram_FF0908)`;
   - OR `word[table+2]` into the size/link word; advance Y by `word[table+0]`; add
     `word[table+4]` to the tile index; subtract `word[table+6]` from X for the shadow;
   - set the high-priority bit `$8000` when `Y < $118`; OR `ram_FFDE5E` and
     `Animation_ram_BaseTile` into the tile word; for the shadow layer set `$800`;
   - write `Y, size/link, tile, X`; advance the tile cursor; if it reaches `$150`, set
     the end flags and clear the previous link.
5. After the loop: clear the last entry's link (`andi.w #$FF00,-6(a0)`), decrement the
   sprite index, store `Animation_ram_SpriteIndex`/`TileIndex`; when the first entry was
   written, derive `ram_FFDE68` from the tile cursor.

## `RiderSprites_StripTable` table (`0x5944`, 128 bytes = 16 records x 8 bytes)

Per-strip record fields (hypothesis supported by the code):

| Offset | Word | Use |
|---|---|---|
| `+0` | `word[table+0]` | Y advance per strip/column. |
| `+2` | `word[table+2]` | Size/link bits ORed into the size word. |
| `+4` | `word[table+4]` | Tile-index increment. |
| `+6` | `word[table+6]` | X adjustment for the shadow/overlay layer. |

The record is selected by the direction/column (`ram_FF0906`/`ram_FF0908` values and the
loop counters). The exact per-record meanings (sprite size codes, tile steps, shadow
offsets) are still to be confirmed against the rider/bike graphics.

`RiderSprites_BuildAlt` is a wrapper: `bsr.w RiderSprites_Build; rts` (an alternate entry point; no direct
caller in the disassembled source).

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

The entries confirm the format `Y, size/link, tile/priority, X`; the last two are the
shadow/overlay layer (negative X, priority bit `$800`). This confirms the routine builds
the linked rider/bike sprite chain and maintains the animation tile/sprite indices.

## Verified facts

- `[static]` `RiderSprites_Build` writes linked 4-word SAT entries and maintains the animation
  tile/sprite cursors.
- `[static]` The `RiderSprites_StripTable` table supplies per-strip Y/link/tile/X adjustments.
- `[dynamic]` The demo race calls `RiderSprites_Build`; the SAT chain and shadow layer were
  observed with sprite index 6, tile index `$27`, shadow offset `$10`.

## Hypotheses / open questions

- `[hypothesis]` The entries are the rider + bike sprites with a shadow/reflection layer;
  `ram_FF133A` selects the shadow/overlay.
- `[hypothesis]` The `d0/d1` inputs are the animation direction/size derived by
  `src/race/road_render.asm`.
- `[ ]` Map the `RiderSprites_StripTable` records to sprite sizes/tile steps with the graphics.
- `[ ]` Confirm the caller `src/race/road_render.asm` contract (next module).

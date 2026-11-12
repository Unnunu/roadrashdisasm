# Module card: `src/screens/rider_sprites.asm`

- **ROM range:** `0x005760`–`0x0059C3` (routines + table
  `RiderSprites_StripTable` at `0x005944`); `src/screens/rider_intro.asm` starts at
  `0x59C4`
- **Status:** analyzed (static + dynamic)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/rider_sprites.md`

## Role / purpose

Builds a linked **rider/bike sprite chain** in the race sprite attribute table (SAT).
It is called by `Road_DrawStrip` (`src/race/road_render.asm:97`, `bsr.w
RiderSprites_Build`) each time the animation needs a new chunk of sprites. The routine
decomposes the requested tile extent into a grid of 4x4 (and smaller remainder) VDP
sprites, writes `Y, size/link, tile/priority, X` entries, chains them through the
size/link link byte, advances the animation tile cursor / sprite index, and can emit a
horizontally mirrored copy.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `RiderSprites_Build` | `0x5760` | `src/race/road_render.asm:97` | Build sprite chain chunk. |
| `RiderSprites_BuildAlt` | `0x593E` | — (no direct caller in source) | Wrapper `bsr.w RiderSprites_Build; rts`. |

## Control flow / state machine

1. Link the new chunk to the previous SAT entry when `SpriteIndex` is `1..$4F`; on
   `>= $50` (80 SAT slots) set the end flags and return.
2. Split `d0`/`d1` (`tiles*8`) into a block count and a 2-bit remainder code; store
   counts (`ram_FF090A/C`) and offsets (`ram_FF0906/08`).
3. Loop rows x columns: build each SAT entry from the base coordinates
   (`ram_FFDE6E/70 + $80`) and the `RiderSprites_StripTable` record (Y step, size code,
   tile step, X step); add `Animation_ram_BaseTile`/`ram_FFDE5E` and the priority/H-flip
   bits, write the entry, advance the tile cursor.
4. If the tile cursor reaches `$150`, flag the chain end and clear the previous link.
5. After the first row, derive the road-tile-array row stride `ram_FFDE68`.
6. Clear the last link, store `Animation_ram_SpriteIndex`/`TileIndex`.

## RAM / ROM & structures

- `Race_ram_CurrentSpriteAttributeTable` (`$FF38AC`) — SAT base.
- `Animation_ram_SpriteIndex` (`$FFDE64`), `Animation_ram_TileIndex` (`$FFDE60`),
  `Animation_ram_BaseTile` (`$FFD34A`) — chain/animation cursors.
- Base fields `ram_FFDE5E..70`; scratch `ram_FF0906..0E`; mirror
  `ram_FF1336/133A`; end flags `ram_FF1366`, `ram_FFDE62`.
- SAT entry: `Y, size/link, tile/priority, X` (4 words; link = low byte of word 2).
  Tile word bits: `$8000` priority, `$800` H-flip.
- ROM table `RiderSprites_StripTable` (`0x5944`, 128 bytes = 16 records x 8 bytes),
  indexed by `4*R + C` (C = horizontal remainder code, R = vertical):

  | Offset | Value | Use |
  |---|---|---|
  | `+0` | `8*(R+1)` | Y step. |
  | `+2` | `(4*C+R) << 8` | VDP size code. |
  | `+4` | `(R+1)*(C+1)` | Tile step. |
  | `+6` | `8*(C+1)` | X step. |

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RiderSprites_Build` | `0x5760` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `RiderSprites_BuildAlt` | `0x593E` | [x] | [x] | - | - | [x] | - | analyzed |
| `RiderSprites_StripTable` | `0x5944` | [x] | [x] | [x] | [x] | [x] | - | analyzed |

Detailed listing and the grid model: `docs/analysis/rider_sprites.md`.

## External calls / dependencies

- Caller: `src/race/road_render.asm` (`Road_DrawStrip`, `Road_DrawObject`).
- Reads/writes the shared animation state used by `src/race/animation.asm`,
  `src/race/road_marking.asm`, `src/race/race_hud.asm`.

## Hacks / bugs / quirks

- The `$8000` sentinel in `ram_FFDE68` marks "row stride not computed"; it is replaced
  after the first row.
- Entries with `Y >= $118` do not get the priority bit `$8000`.
- The mirror pass (`Road_ram_MirrorFlag`, from `RoadObject_Flags` bit15) sets the H-flip bit
  `$800` and walks X left. `U-0007` resolved: this is the facing/mirror bit, not a shadow.

## Verified facts

- `[static]` Writes linked SAT entries and maintains the animation cursors.
- `[static]` The table is a derived 4x4 matrix: Y `8*(R+1)`, size `(4*C+R)<<8`,
  tile step `(R+1)*(C+1)`, X `8*(C+1)`.
- `[hardware]` `$8000` = priority, `$800` = H-flip in the SAT tile word.
- `[dynamic]` Demo race hits `RiderSprites_Build`; chain observed at `$FF479C` with
  sprite index 6, tile index `$27`, mirror offset `$10` (`Road_ram_MirrorFlag=1`).

## Hypotheses

- `[hypothesis]` `d0/d1` are the animation direction/size from `Road_DrawStrip`. Test:
  analyze `Road_DrawStrip` and break at `$5760` entry.
- `[static]` The mirrored pass is a per-object horizontal mirror/facing pass
  (`U-0007` resolved).

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Confirm SAT builder | GDB `break *0x593C` in demo race | SAT `$FF479C`, 4 entries, sprite index 6, tile `$27`, mirror flag 1 | Confirms sprite-chain builder |

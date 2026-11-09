# Analysis: `src/logoEA/logoEA.asm` (Electronic Arts logo)

- **Module / routine:** EA-logo screen (runtime figure generation, sprites, text, VDP trick)
- **ROM range:** `0x000366`–`0x00117F` (see `build/roadrash.lst`)
- **Status:** partially analyzed (VDP trick + text placement understood statically; dynamic
  VRAM confirmation pending)
- **Source:** `src/logoEA/logoEA.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `LogoEA_GameTick` | `0x0366` | [x] | [x] | - | - | [x] | [x] | analyzed |
| `LogoEA_AddSpritesVPos` | `0x036C` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_SetSpritesVerticalFlip` | `0x0382` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_SetSquareSpritesHPos` | `0x0394` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_SetTriangleSpritesHPos` | `0x03C0` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_ShowSprites` | `0x03E2` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_Update` | `0x0406` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed (effect observed) |
| `LogoEA_CreateSprite` | `0x07BC` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_CreateFigureSprites` | `0x07E0` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_GetSquareLineMemOffset` | `0x0804` | [x] | [x] | [x] | - | [x] | - | analyzed |
| `LogoEA_GetPointOffsets` | `0x080E` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_DrawLine` | `0x0824` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_ChangeTextColor` | `0x086C` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_DrawCircle` | `0x089A` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_Init` | `0x093E` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `LogoEA_SetupGfx` | `0x0A08` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_WriteNametablePair` | `0x0C32` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `LogoEA_DecompressLZ` | `0x0C3C` | [x] | [x] | [x] | - | [x] | - | analyzed |

## RAM map (overlay/scratch)

`src/logoEA/logoEA.asm` keeps its own map at `$FFFF0000`/`$FFFFCxxx`. It is an overlay used during
the logo phase and physically overlaps later menu buffers (e.g. `TilesSquare $FFC0E4`
overlaps `Menu_ram_FrameBuffer2 $FFC4AC`). Values are 32-bit because the ROM encodes them
literally (e.g. `movea.l #LogoEA_ram_Base` → `207C FFFF 0000`).

| Address | Name | Size | Meaning |
|---|---|---|---|
| `$FFFFC000` | `TextTimer` | 2 | Text animation timer (starts `$E2` = 226, decrements per frame). |
| `$FFFFC002` | `FigureAnimationFrame` | 2 | Figure animation frame (`0..$18`). |
| `$FFFFC004` | `NextUpdateTimer` | 2 | Update every 3 frames; 180 (3 s) after a figure completes. |
| `$FFFFC006` | `LineValue` | 4 | Current 8-pixel line colour. |
| `$FFFFC00A` | `CurrentFigure` | 2 | 0 = square, 1 = circle, 2 = triangle. |
| `$FFFFC00C`/`$FFFFC030` | `SquareYArray` / `SquareDataArray` | 36 each | Sprite VPos / sprite data arrays (9 strips × 2 sprites). |
| `$FFFFC054`/`$FFFFC078` | `TriangleYArray` / `TriangleDataArray` | 36 each | Same for the triangle. |
| `$FFFFC09C`/`$FFFFC0C0` | `CircleYArray` / `CircleDataArray` | 36 each | Same for the circle. |
| `$FFFFC0E4` | `TilesSquare` | `$900` | 72 generated square tiles (32 bytes each). |
| `$FFFFC9E4` | `TilesTriangle` | `$900` | 72 generated triangle tiles. |
| `$FFFFD2E4` | `TilesCircle` | `$900` | 72 generated circle tiles. |
| `$FFFFDBE4` | `ImageEAUncompressed` | `$C00` | Decompressed "Electronic Arts" image/palette/nametable. |
| `$FFFFE7E4` | `UncompressTempBuffer` | `$1000` | LZ ring buffer (initialized to `$20` = space). |

## VDP configuration (`LogoEA_Init`, `0x093E`)

```
reg0  = $8004 : H-int off, left column unblanked, HV counter normal (bit2 fixed 1)
reg1  = $8134 : display off, V-int on, DMA on, 28 rows
reg2  = $8228 : plane A nametable $A000
reg3  = $8330 : window nametable $C000
reg4  = $8405 : plane B nametable $A000   <-- same table as plane A!
reg5  = $856E : sprite table $DC00
reg7  = $8700 : backdrop 0 (black)
reg0B = $8B03 : E-int off, V-scroll full, H-scroll per line
reg0C = $8C81 : H40 (40 cells), no interlace, no shadow/highlight
reg90 = $9003 : plane size 128x32
reg8D = $8D08 : H-scroll table $2000
reg8F = $8F02 : auto-increment 2
reg91/92 = 0 : window disabled
reg8A = $8A01 : H-int counter 1 (unused because H-int is disabled)
```

The display is enabled later by `doStart` (`move.w #$8174,VdpCtrl`), not by
`LogoEA_Init`.

### Runtime confirmation (BlastEm `vr`)

`vr` during the logo confirms:

- `reg2=$28`, `reg4=$05` -> both planes at `$A000` (shared nametable);
- `reg0B=$03` (H-scroll per line), `reg90=$03` (128x32), `reg8D=$08` (`$2000`);
- `reg0A=$01` with `HINT Pending: true`, but `reg0=$04` disables H-int, so the counter
  is not serviced;
- `reg1=$74` (display enabled by `doStart`), `reg5=$6E` (`$DC00`), `reg0C=$81`;
- DMA group (`length 0`, source `$101FFFE`, `Copy`) is stale boot state; the logo does
  not use DMA.

The BlastEm **Plane debugger** shows several copies of the EA text (shared plane +
per-line scroll/wrap) and no figures: the three figures are **sprites** (SAT `$DC00`),
not plane tiles.

### VRAM map (percentages from the BlastEm viewer)

The user sees the yellow/green/blue stripes at ~25-40% of VRAM. Mapping the code's
addresses to a 64 KiB VRAM:

| VRAM | Percent | Contents |
|---|---|---|
| `$0020` | ~0.03% | Text image tiles (65 tiles). |
| `$2000` | 12.5% | H-scroll table (per-line values). |
| `$4020` | 25.1% | Square tile buffer (72 tiles). |
| `$4920` | 28.6% | Circle tile buffer (72 tiles). |
| `$5220` | 32.1% | Triangle tile buffer (72 tiles). |
| `$5B20` | 35.6% | End of the figure tile buffers (`$5B20`). |
| `$A000` | 62.5% | Shared plane A/B nametable (128x32). |
| `$B20C` | 69.7% | EA text nametable (via the command-latch trick). |
| `$DC00` | 86.0% | Sprite attribute table (640 bytes). |

So the yellow/green/blue stripes at 25-40% are the **runtime-generated figure tiles**,
exactly as the code says.

### The strange part: shared plane + VDP command-latch trick

1. **Planes A and B share the same nametable `$A000`.** The H-scroll table (written in
   `LogoEA_Update`) gives the foreground and background **different horizontal scroll**
   values (`fg = -TextTimer` / `TextTimer-1` alternating per line, `bg = $140`), so the
   same text is drawn twice with a scroll offset (a ghost/shadow layer) and a per-line
   zig-zag (wave) effect. The H-scroll-per-line mode (`reg0B=$03`) makes the VDP apply
   the table automatically; the H-int counter (`reg0A=1`) is a red herring because
   `reg0=$04` disables H-int.
2. **The text nametable is not actually written at `$8000`.** `LogoEA_SetupGfx` starts
   with `VDP_VRAM_WRITE $8000` (a full 32-bit command: first word `$4000`, second word
   `$0002`). Then it writes a **single control word `$720C` per text row**
   (`move.w #$720C,(VdpCtrl)`), which is only the **first word** of a VRAM-write
   command. The VDP retains the high address bits from the previous command (`$0002`),
   so the effective address is:
   `($720C & $3FFF) | ($0002 << 14) = $320C | $8000 = $B20C`, i.e. **inside the shared
   plane A/B nametable**. Each row adds `$100` (the 128-cell plane row size). The
   source comments `???` at these commands are the disassembler author's uncertainty.
3. The extra `$7044`, `$7144`, `$710C`, `$7136` commands place the "TM" and the small
   symbols at nearby plane rows. `LogoEA_WriteNametableEntry` writes two nametable words
   per call.
4. The initial `$8000` write is therefore only a way to load the high address bits; the
   `$8000` VRAM area is not the displayed text table. The text is at `$B20C` (plane row
   18, column 6) and `$B30C` (row 19).

`[hardware]`/`[hypothesis]` The VDP command-latch reuse (second word retained from the
previous command) is the key trick; the static address computation gives `$B20C`. This
should be confirmed with the VRAM/plane viewer in BlastEm. The source's `???` comments
mark the same uncertainty.

## Figure generation (runtime tiles)

The square, triangle and circle are generated as 4bpp tiles in RAM and uploaded to VRAM:

- **Square** (`LogoEA_SetupGfx`): 9 strips with thickness
  `LogoEA_dFigureStripThickness` = 1,1,2,2,3,3,4,4,6; each strip is 8 lines. The first
  line is light green (`$44444444`), the body green (`$66666666`), the last line/shadow
  dark green (`$55555555`). `LogoEA_GetSquareLineMemOffset` computes the tile/line
  offset; tiles are written at VRAM `$4020` (tile `$201`).
- **Triangle**: slope `$97B4 / $10000 ≈ 0.5925`; fixed-point 16.16 left/right edges
  (`d3`, `a1`), shadow widths from `LogoEA_dTriangleShadowWidth` = 0,0,0,2,7,10,10,7,0;
  tiles at VRAM `$5220`.
- **Circle**: profile `logoEA_dCircleProfile`, shadow `logoEA_dCircleShadowLength`;
  `LogoEA_DrawCircle` builds the circle line by line; tiles at VRAM `$4920`.
- Each figure becomes **9 strips × 2 sprites = 18 sprites** of size 4×1 tiles; the
  sprite arrays (`*YArray`/`*DataArray`) are filled by `LogoEA_CreateFigureSprites` and
  uploaded to `$DC00` in `LogoEA_Update`.

## Text (Electronic Arts) and LZ decompression

- `LogoEA_SetupGfx` reads the generated `assets/images/ea_logo/data.bin` asset
  (ROM `0xCFE`, size `0x3D6`):
  - first two bytes = little-endian size (`b1<<8 | b0`), then it skips 4 bytes and calls
    `LogoEA_DecompressLZ` with `a3` = data, `a1` = `ImageEAUncompressed`, `d2` = size.
- `LogoEA_DecompressLZ` is an **LZSS-style** decompressor:
  - 4 KiB ring buffer initialized to `$20` (space), 12-bit index `d7 = $FEE`.
  - control byte bitmask (8 bits, LSB first): 1 = literal byte, 0 = back-reference.
  - back-reference: two bytes → 12-bit offset `d4 = byte1 | ((byte2 & $F0) << 4)` and
    length `d5 = (byte2 & $0F) + 2` (2..17); copies from the ring buffer while updating
    the ring.
  - stops when `d2` (output size) reaches 0.
- The decompressed image starts with 3 words: tile count (65), height (2), width (29),
  then a 16-word palette and 65 tiles of data. The palette is written to CRAM `$0`, the
  tiles to VRAM `$20`, and the nametable via the `$720C` trick described above.
- The text timer (`$E2`) drives the wave: `LogoEA_Update` writes the H-scroll table every
  frame with `fg = -timer` / `timer-1` alternating and `bg = $140`; when the timer reaches
  zero and the figure animation completes, `LogoEA_ram_Finished` is set.

## Animation / update (`LogoEA_Update`)

- `TextTimer` decrements each frame (text appears/scrolls).
- `NextUpdateTimer` counts down; when it expires, the figures update every 3 frames:
  - cycle `CurrentFigure` 0→1→2→0;
  - animate the scale (`d1 = ±1`), vertical flip (`$1000`) at frame 7, unflip at 20,
    palette changes, shadow toggles;
  - upload the circle tiles, update sprite VPos/HPos/link/size, write CRAM palettes;
  - after 25 frames (`$18`) switch to the next figure; after all figures wait 3 s.
- When `TextTimer < 0` and the figure animation has finished, set
  `LogoEA_ram_Finished` (`$FF1A66`), which `doStart` polls to leave the logo.

## Verified facts

- `[static]` Plane A and B are both programmed to `$A000`; the H-scroll table applies
  different scrolls to the two planes.
- `[static]` The per-row text command `$720C` is a first-word-only VRAM write command;
  combined with the retained second word `$0002` it addresses `$B20C` inside the shared
  plane. The `$8000` address is overwritten.
- `[static]` The display is enabled by `doStart` (`$8174`), not by `LogoEA_Init`.
- `[static]` The LZ ring buffer is initialized to `$20` and the decompressor implements
  literal/back-reference tokens with a 8-bit control mask.
- `[dynamic]` The logo is driven by `LogoEA_GameTick` as `ram_UpdateFunction` (`0x366`),
  called from `VerticalInterrupt` during the logo phase.

## Hypotheses / open questions

- `[hypothesis]` The VDP command latch retains the address high bits (`$0002`) and the
  per-row single-word commands therefore write to `$B20C`/`$B0xx`. Confirm with a
  VRAM/plane viewer.
- `[hypothesis]` The shared plane + per-line alternating scroll is the intended
  ghost/wave effect for the EA text.
- `[ ]` Confirm the exact plane rows/columns and the `$7044/$7144/$710C/$7136` entries.
- `[ ]` Confirm the figure animation timing (frames 7/20/25) and the palette swaps.
- `[ ]` The 38-byte Z80 stub / logo interaction (the logo only uses sprites/planes).

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `LogoEA_dFigureStripThickness` | `LogoEA_dStripThickness` | used for all three figures | medium |
| `logoEA_dCircleProfile` | `LogoEA_dCircleProfile` | spelling | medium |


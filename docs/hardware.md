# Genesis / Mega Drive hardware reference (project view)

This is a working reference for the hardware used by Road Rash. It records the
*general* hardware rules and, as analysis progresses, the *specific* configurations this
game uses. Add `[hardware]`/`[dynamic]` evidence where the game's usage is confirmed.

See `docs/references.md` for source documents.

## 1. System overview

| Part | Role |
|---|---|
| Motorola 68000 @ ~7.67 MHz | Main CPU: game logic, VDP setup, DMA, controller I/O. |
| Z80 @ ~3.58 MHz | Sound CPU; the 68K loads/starts a driver blob at boot. |
| VDP (Sega 315-5313) | Video: planes A/B, window, sprites, palettes, scrolling, DMA. |
| YM2612 (FM) + SN76489 (PSG) | Audio. |
| Controller ports | Two DE-9 ports; TH-based multiplexing for 3/6-button pads. |

68000 address map (relevant parts):

| Address | Contents |
|---|---|
| `$000000`–`$3FFFFF` | Cartridge ROM (this project's ROM is 786432 bytes). |
| `$A00000`–`$A0FFFF` | Z80 address space (RAM, YM2612, PSG, bank registers). |
| `$A10000`–`$A1001F` | I/O: version, controller data/control ports. |
| `$A11100` | Z80 bus request. |
| `$A11200` | Z80 reset. |
| `$C00000` | VDP data port (16-bit). |
| `$C00004` | VDP control/status port (16-bit). |
| `$C00008` | VDP HV counter. |
| `$FF0000`–`$FFFFFF` | 64 KiB work RAM. |

## 2. VDP registers

VDP registers are 8 bits, written through the control port as `$8nxx` (`n` = register,
`xx` = value). The table records the fields this project cares about. Bits not listed
are unused/reserved or still to be verified.

| Reg | Name / fields |
|---|---|
| `$00` | Mode 1: bit4 H-int enable, bit3 HV-counter latch, bit2 palette select (bits 0,1,5-7 unused/TODO). |
| `$01` | Mode 2: bit6 display enable, bit5 V-int enable, bit4 DMA enable, bit3 30-row mode (0=28 rows), bit2 mode 5. |
| `$02` | Scroll A nametable base (bits 5-3 select a 2 KiB-aligned VRAM address). |
| `$03` | Window nametable base (same encoding). |
| `$04` | Scroll B nametable base (same encoding). |
| `$05` | Sprite attribute table base (bits 6-1 select a 512-byte-aligned VRAM address). |
| `$07` | Backdrop colour: bits 5-4 palette, bits 3-0 colour index. |
| `$0A` | H-int counter (line counter). |
| `$0B` | Mode 3: bit3 E-int enable, bit2 V-scroll mode (0=full, 1=column), bit1 H-scroll mode (0=full, 1=line), bit0 TODO. |
| `$0C` | Mode 4: bit7 40-cell mode (0=32 cells), bit3 shadow/highlight enable, bits 4-5 TODO (interlace). |
| `$0D` | H-scroll table base (bits 6-2, 1 KiB-aligned). |
| `$0F` | Auto-increment (VRAM/CRAM/VSRAM address step after data access). |
| `$10` | Plane size: bits 1-0 scroll A (00=32x32, 01=64x32, 11=32x64?), bits 5-4 scroll B (verify exact encoding). |
| `$11` | Window X position (in 2-cell units, bit7 = right side). |
| `$12` | Window Y position (in 1-cell units, bit7 = bottom side). |
| `$13`/`$14` | DMA length (low/high). |
| `$15`/`$16`/`$17` | DMA source address (low/mid/high) and source type (bits 7-6 of `$17`). |

Notes:

- The in-source comments sometimes describe the effect of a *pair* of register writes on
  one line (e.g. display enable lives in reg `$01` bit 6, not reg `$00`). Re-check each
  comment against the actual register during analysis; correct misleading comments (they
  do not affect the bytes).
- `VdpCtrl` = `$C00004`, `VdpData` = `$C00000`, `HvCounter` = `$C00008`.

## 3. VRAM / CRAM / VSRAM / SAT

| Memory | Size | Contents |
|---|---|---|
| VRAM | 64 KiB | Tiles, nametables, sprite attribute table, H-scroll table. |
| CRAM | 128 bytes (64 words) | Palettes: 4 lines × 16 colours; one word per colour (`$0BGR`, 9-bit RGB). |
| VSRAM | 80 bytes (40 words) | Vertical scroll per column. |
| SAT | 640 bytes (80 sprites × 8 bytes) | Sprite Y, size/link, pattern/flags, X. |

Common formats:

- Tile: 32 bytes, 4bpp, 8×8 pixels.
- Nametable entry: 2 bytes: priority/palette/vflip/hflip + tile index.
- Sprite entry: 8 bytes: Y, size+link, tile+flags, X (values are screen position minus 128;
  Y=0 hides a sprite).
- CRAM colour: `0000BBB0GGG0RRR0` (bits 3-1 blue, 7-5 green, 11-9 red).

## 4. DMA

The VDP can copy/fill memory without CPU involvement:

- 68K→VRAM/CRAM/VSRAM DMA: set length (`$13/$14`), source (`$15-$17`), destination via
  control-port command, then DMA runs after the next data-port write (or immediately for
  fill/copy).
- DMA fill: writes a word to VRAM repeatedly.
- DMA copy: VRAM→VRAM.

DMA is commonly scheduled during VBlank to stay within the display budget. The fade code
(`fade.asm`) uses DMA to upload the 64-word palette to CRAM (`DmaWriteCRAM`).

## 5. Interrupts and timing

- VBlank: IRQ level 6 (`VerticalInterrupt` at `$1164`); the main per-frame update pointer
  `ram_UpdateFunction` (`$FF1A62`) is called from here.
- HBlank: IRQ level 4 (`HorizontalInterrupt` at `$145A`), typically for raster effects
  (split-screen scrolling, palette changes).
- The VDP status/HV counter is at `$C00008`.
- The 68000's per-frame budget matters for DMA and HInt raster work; measure hot paths
  when it explains a design choice.

## 6. Controllers (TH protocol)

- Data ports: `$A10003` (port 1), `$A10005` (port 2).
- Control ports: `$A10009` (port 1), `$A1000B` (port 2).
- The TH line selects which button group is read: TH=0 reads up/down/left/right/B/C;
  TH=1 reads A/Start (and, with extra clocking, the 6-button extras X/Y/Z/Mode).
- `GetInputPlayerA/B` in `main.asm` implement the read sequence; details are documented in
  `docs/analysis/main.md`.

## 7. Z80 / audio (deferred deep dive)

- Z80 RAM and registers: `$A00000`–`$A0FFFF`.
- YM2612: `$A04000` (address), `$A04001` (data); PSG: `$C00011`.
- Boot code copies/starts the sound driver blob (`z80_start`…`z80_end`) and requests the
  Z80 bus via `$A11100`/`$A11200`.
- Deep analysis of the sound driver is deferred (see `docs/architecture.md`).

## 8. Game-specific configurations (fill during analysis)

Per screen, record the VDP register writes and the reason (resolution, plane layout,
sprite table, VRAM budget, scroll mode, etc.):

| Screen / routine | Registers written | Why |
|---|---|---|
| TODO | TODO | TODO |

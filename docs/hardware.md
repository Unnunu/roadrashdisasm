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
`xx` = value). This table follows the Genesis VDP register reference (see
`docs/references.md`); the game's boot configuration is in section 8.

| Reg | Fields |
|---|---|
| `$00` | bit5 LCB (blank leftmost column), bit4 IE1 (H-int enable), bit2 fixed 1, bit1 M3 (freeze HV counter). |
| `$01` | bit6 DISP (rendering), bit5 IE0 (V-int enable), bit4 M1 (DMA enable), bit3 M2 (0 = 28 rows, 1 = 30 rows), bit2 fixed 1. |
| `$02` | bits 5-3 SA15-13: plane A base = `(reg & 0x38) * 0x400`. |
| `$03` | bits 5-1 WD15-11: window base = `(reg & 0x3E) * 0x400`. |
| `$04` | bits 2-0 SB15-13: plane B base = `(reg & 0x07) * 0x2000` (plane B uses a different field than plane A). |
| `$05` | bits 7-1 AT15-9: sprite table base = `(reg & 0xFE) * 0x200`. |
| `$07` | bits 5-4 backdrop palette, bits 3-0 backdrop colour index. |
| `$0A` | H-int rate (lines between H-int). |
| `$0B` | bit3 IE2 (external int), bit2 VSCR (0 full, 1 two-tile), bits 1-0 H/LSCR (00 full, 01 8-line, 10 tile, 11 line). |
| `$0C` | bit7 RS0 / bit0 RS1 (00 H32, 11 H40), bit3 S/TE shadow/highlight, bits 2-1 LSM interlace. |
| `$0D` | bits 5-0 HS15-10: H-scroll table base = `(reg & 0x3F) * 0x400`. |
| `$0F` | auto-increment in bytes. |
| `$10` | bits 5-4 VSZ, bits 1-0 HSZ: 00=32x32, 01=64x32, 11=128x32, 01/00=32x64, 01/01=64x64, 11/00=32x128. |
| `$11` | bit7 RIGT (window side), bits 4-0 WHP5-1 (X split in 16px steps). |
| `$12` | bit7 DOWN (window side), bits 4-0 WVP4-0 (Y split in 8px steps). |
| `$13`/`$14` | DMA length (low/high). |
| `$15`/`$16`/`$17` | DMA source address; `$17` bits 7-6 DMD (0*=transfer, 10=fill, 11=copy), bits 5-0 source high. |

Notes:

- The in-source comments occasionally describe reg `$00` as palette select; palette
  selection for the backdrop is in reg `$07`, and reg `$00` bit2 is a fixed "1".
- `VdpCtrl` = `$C00004`, `VdpData` = `$C00000`, `HvCounter` = `$C00008`.
- A VRAM write command is a two-word control-port sequence. The EA logo writes only the
  first word per text row (`$720C`, ...) after a full `$8000` command, relying on the VDP
  retaining the previous second word (`$0002`); the effective address is `$B20C` inside
  the shared plane. See `docs/analysis/logoEA.md` (dynamic confirmation pending).

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

- **DMA to VRAM**: command `$40000080` (bit7 of the command's second word enables DMA).
  In transfer/copy mode the operation starts when the command is written; in **fill**
  mode you write the fill value to `VdpData` to start it.
- **DMA to CRAM**: `$C0000080`; **DMA to VSRAM**: `$40000090`.
- Source/length are set in regs `$13`–`$17`; DMD selects transfer/fill/copy.
- The boot code uses a fill of `$FFFF` words from VRAM address 0 with value 0, which
  wraps and clears all 64 KiB of VRAM.

DMA is commonly scheduled during VBlank to stay within the display budget. The fade
code (`fade.asm`) uses DMA to upload the 64-word palette to CRAM (`DmaWriteCRAM`).

## 5. Interrupts and timing

- **VBlank (IRQ 6, `VerticalInterrupt` `$1164`).** Saves all registers, loads
  `ram_UpdateFunction` (`$FF1A62`), returns if zero, otherwise `jsr (a0)`; restores and
  `rte`. The update function may clobber all registers.
- **HBlank (IRQ 4, `HorizontalInterrupt` `$145A`).** Raster effect:
  - re-arms the H-int counter with `$8AFF`;
  - returns immediately while `ram_FF369E == $FFFF` (effect disabled, e.g. logo);
  - indexes `Race_ram_NextVScrollInfo + ram_FF0406`, sets the VSRAM write address and
    waits on the HV counter for a precise scanline/horizontal position;
  - writes a longword to `VdpData`, then **36 NOPs** (VDP write-recovery delay), then
    writes the next command word to `VdpCtrl`;
  - when the next `ram_FF0406 == $90`, runs a once-per-frame engine-audio update
    (`AudioFunc1/8/11`, `sub_1652`).
- **HV counter** (`$C00008`): high byte = vertical counter, low byte = horizontal
  counter. The handler polls both to place writes at a specific raster position.
- **VDP status** read via `$C00004`; a control-port read resets the command latch. Where
  the V-int flag is acknowledged in this game is still an open question.
- **Budget:** the per-frame update runs inside VBlank; long updates can overrun into
  active display. DMA and HInt raster work share the same budget. Measure hot paths
  (race update, HInt handler) when it explains a design choice.

## 6. Controllers (TH protocol)

| Port | Player 1 | Player 2 |
|---|---|---|
| Data | `$A10003` | `$A10005` |
| Control | `$A10009` | `$A1000B` |

A standard **3-button** pad is read by toggling TH:

| Step | Write to data port | Bits 5-0 |
|---|---|---|
| 1 | `$40` (TH=1) | C, B, Right, Left, Down, Up |
| 2 | `$00` (TH=0) | Start, A, 0, 0, Down, Up |

Bits are active-low (1 = released). The game rearranges them into **SACBRLDU**
(bit7 Start … bit0 Up) and inverts so that **1 = pressed**.

The game's read sequence (`GetInputPlayerA/B`):

1. Write `$40` to the control port (TH as output).
2. Write `$00` to the data port, wait (`$A` for player A, `$14` for player B), read.
3. Write `$40` to the data port, wait the same, read.
4. Shift/mask/or/not into SACBRLDU; the low 8 bits of `d0` are the result (upper bits
   are left untouched).

Quirks (see `docs/analysis/main.md`):

- The wait count differs between player A and B; the reason is not documented.
- The routines do **not** pause the Z80 while touching the ports (hardware workaround
  for the Z80/68K bus conflict). Road Rash (1991) predates the 6-button pad (1993), so
  only the 3-button protocol is implemented; X/Y/Z/Mode are not read.
- After the first input read the control ports are `$40`; the boot code uses the
  nonzero `$A10008`/`$A1000C` value as a warm-reset indicator.

## 7. Z80 / audio (deferred deep dive)

- Z80 RAM and registers: `$A00000`–`$A0FFFF`; use **byte** accesses only.
- `$A11100` (Z80 bus): write `$0100` to request; poll bit0 until it reads 0 (bus
  granted); write `$0000` to release.
- `$A11200` (Z80 reset): `$0000` = assert reset, `$0100` = release reset.
- YM2612: `$A04000` (address), `$A04001` (data); PSG: `$C00011`.
- Boot loads a 38-byte Z80 stub and leaves the Z80 in reset; the sound code later
  (`$1D9C2`) loads the real driver from `$1DA12` (~3003 bytes) and releases reset.
- Deep analysis of the sound driver is deferred (see `docs/architecture.md`).

## 8. Game-specific configurations (fill during analysis)

Per screen, record the VDP register writes and the reason (resolution, plane layout,
sprite table, VRAM budget, scroll mode, etc.):

| Screen / routine | Registers written | Why |
|---|---|---|
| Boot (`RESET`) | reg0 `$04`, reg1 `$14`, reg2 `$30`, reg3 `$3C`, reg4 `$07`, reg5 `$6C`, reg7 `$00`, reg0A `$FF`, reg0B `$00`, reg0C `$81`, reg0D `$37`, reg0F `$01`, reg10 `$01`, reg11/12 `$00`, reg13/14 `$FF`, reg15-17 `$00/$00/$80` | Clears VRAM via DMA fill; sets plane A `$C000`, window `$F000`, plane B `$E000`, sprite table `$D800`, H-scroll `$DC00`; display/V-int off until the logo. |
| EA logo (`LogoEA_Init`) | reg0 `$04`, reg1 `$34`, reg2 `$28`, reg3 `$30`, reg4 `$05`, reg5 `$6E`, reg7 `$00`, reg0B `$03`, reg0C `$81`, reg8A `$01`, reg8D `$08`, reg8F `$02`, reg90 `$03`, reg91/92 `$00` | Plane A **and** plane B at `$A000` (shared nametable), window `$C000`, sprites `$DC00`, H-scroll table `$2000`, 128x32 planes, **H-scroll per line**. Display enabled later by `doStart`. |
| Intro (`Intro_Init`) | reg0 `$04`, reg1 `$74`, reg2 `$10`, reg4 `$01`, reg5 `$30`, reg7 `$01`, reg0A `$FF`, reg0B `$03`, reg0C `$81`, reg0D `$1C`, reg8F `$02`, reg90 `$03`, reg91/92 `$00` | Plane A `$4000` (title/text), plane B `$2000` (background), sprites `$6000`, H-scroll table `$7000`, 128x32 planes, **H-scroll per line** for the title/credits wave. |

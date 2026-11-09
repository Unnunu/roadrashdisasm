# Analysis: `main.asm` (boot flow)

- **Module / routine:** boot/init (RESET, defaults, Z80 stub, doStart)
- **ROM range:** `0x000200`–`0x0002FA` (boot code), `0x00028E`–`0x0002C3` (data)
- **Status:** boot flow analyzed; input/IRQ/helpers TODO
- **Source:** `main.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RESET` | `0x0200` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed (boot) |
| `start` | `0x028C` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `defaults` | `0x028E` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `z80_start`/`z80_end` | `0x02C4` | [x] | [x] | [x] | [x] | [ ] | [ ] | analyzed (stub) |
| `doStart` | `0x02FA` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `sub_7FF98` (ROM checksum) | `0x7FF98` | [x] | [x] | [x] | [ ] | [x] | [x] | analyzed |
| `GetInputPlayerA` | `0x10D4` | TODO | TODO | TODO | TODO | TODO | [ ] | TODO |
| `GetInputPlayerB` | `0x111C` | TODO | TODO | TODO | TODO | TODO | [ ] | TODO |
| `VerticalInterrupt` | `0x1164` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed (dispatcher) |
| `HorizontalInterrupt` | `0x145A` | TODO | TODO | TODO | TODO | TODO | [ ] | TODO |
| Exception handlers | `0x13C0`… | TODO | TODO | TODO | TODO | TODO | - | TODO |
| `sub_1652` | `0x1652` | TODO | TODO | TODO | TODO | TODO | [ ] | TODO |

## 1. Entry and warm-reset check (`RESET`, `0x0200`)

```asm
RESET:
    tst.l   ($A10008).l
    bne.s   .portA
    tst.w   ($A1000C).l
.portA:
    bne.s   start
```

`[static]` The code reads the controller **control** registers (`$A10008` covers
control ports 1/2; `$A1000C` covers the next control port) and skips all hardware init
if either is nonzero.

`[hypothesis]` This is a **soft-reset / warm-boot detector**: the input routines later
write `$40` (TH output) to the control ports, so a console reset finds them nonzero and
jumps to `start` -> `doStart`, which then skips the logo and restarts the top-level flow
without reinitializing VDP/Z80/RAM. Test: after boot and one input read, read
`$A10008`; press Reset (soft reset) and confirm the boot branches to `start`.

`[hardware]` TMSS: `move.b -$10FF(a1),d0` (`a1=$A11100`) reads `$A10001`; if the low
nibble is nonzero, TMSS is present and the code writes `'SEGA'` to `$A14000`
(`$2F00(a1)`) to unlock the VDP.

## 2. Packed initialisation table (`defaults`, `0x028E`)

`[static]` The table is walked with `a5` and contains, in order:

| Offset | Contents |
|---|---|
| `0x028E` | `d5=$8000`, `d6=$3FFF`, `d7=$0100` |
| `0x0294` | `a0=$A00000` (Z80 RAM), `a1=$A11100` (bus), `a2=$A11200` (reset), `a3=$C00000` (data), `a4=$C00004` (control) |
| `0x02A8` | 24 VDP register values (regs `$00`–`$17`) |
| `0x02C0` | `$40000080` — DMA-to-VRAM command (destination 0) |
| `0x02C4` | Z80 stub blob |
| `0x02EA` | `$81048F02`, `$C0000000`, `$40000010`, PSG mute bytes |

`[design]` Packing the init values, the Z80 stub and the post-init commands into one
table lets the boot code advance a single pointer (`a5`), keeping the init compact.

The VDP register loop uses two tricks:

- `d5` starts as `$8000`; `move.b (a5)+,d5` only replaces the low byte, producing the
  `$80xx` register-write word.
- `d7=$0100` is added after each write, incrementing the register number in the high
  byte. The loop writes registers `$00`–`$17`.

## 3. VDP configuration (`[hardware]`, decoded from the VDP register reference)

| Reg | Value | Effect / reason |
|---|---|---|
| `$00` | `$04` | H-int off, left column unblanked, HV counter normal; bit2 is the fixed "1" bit. |
| `$01` | `$14` | Display **off**, V-int **off**, DMA **on** (needed for the VRAM fill), 28 rows. |
| `$02` | `$30` | Plane A nametable at `$C000` (bits 5-3 × `$2000`). |
| `$03` | `$3C` | Window nametable at `$F000` (bits 5-1 × `$800`). |
| `$04` | `$07` | Plane B nametable at `$E000` (bits 2-0 × `$2000`; plane B uses a different field than plane A). |
| `$05` | `$6C` | Sprite table at `$D800` (bits 7-1 × `$200`). |
| `$07` | `$00` | Backdrop colour 0 (palette 0, colour 0) — black during init. |
| `$0A` | `$FF` | H-int counter 255 (H-int disabled). |
| `$0B` | `$00` | Full-screen vertical/horizontal scroll; external interrupt off. |
| `$0C` | `$81` | H40 (320 px), no interlace, no shadow/highlight. |
| `$0D` | `$37` | H-scroll table at `$DC00` (bits 5-0 × `$400`). |
| `$0F` | `$01` | Auto-increment 1 (byte) during init. |
| `$10` | `$01` | Plane size 64×32 (HSZ=01, VSZ=00). |
| `$11`/`$12` | `$00` | Window split at 0 → no window area. |
| `$13`/`$14` | `$FF`/`$FF` | DMA length `$FFFF` words. |
| `$15`–`$17` | `$00`/`$00`/`$80` | DMA source 0; DMD=`10` -> VRAM fill. |

`[hardware]` `$40000080` is the "DMA to VRAM" command (bit 7 of the command's second
word enables DMA). Writing 0 to `VdpData` (`move.w d0,(a3)`) starts the fill with value
0; length `$FFFF` words clears all 64 KiB of VRAM (it wraps around).

`[hardware]` The boot comment on reg `$00` ("palette select") was inaccurate: palette
selection for the backdrop is in reg `$07` bits 5-4; reg `$00` bit2 is a fixed "1".
The comment is corrected in `main.asm`.

## 4. Z80 load and reset sequence

`[static]` The code requests the Z80 bus (`$0100 -> $A11100`), releases reset
(`$0100 -> $A11200`), waits for the bus (`btst #0,$A11100` until clear), copies the
38-byte stub to `$A00000` with **byte** accesses, then writes:

```
$0000 -> $A11200   ; assert reset
$0000 -> $A11100   ; release bus
$0100 -> $A11200   ; release reset
... init continues ...
$0000 -> $A11200   ; assert reset again (line 163)
```

`[hardware]` Per the standard Z80 bus sequence: `$0000` = assert reset, `$0100` =
release reset; `$0100` = request bus, `$0000` = release bus. The in-source comments on
these lines were inverted; they are corrected in `main.asm` (comments only).

`[static]` The 38-byte stub (`z80_start`): clears the rest of Z80 RAM with an
overlapping `LDIR`, sets I/R, restores registers from zeroed stack slots, writes
`$E9` (`JP (HL)`) and jumps to `$0000` — effectively a small Z80 stop/placeholder stub.
The **real** Z80 driver is loaded later by the sound code at `$1D9C2` (it copies ~3003
bytes from `$1DA12` to `$A00000`, then performs the same reset/bus sequence). The boot
code intentionally leaves the Z80 in reset (line 163); the sound init releases it later.

## 5. RAM / CRAM / VSRAM / PSG init

- `[static]` `.clear_ram`: `a6` starts at 0; `move.l d0,-(a6)` writes zero while
  pre-decrementing, `d6=$3FFF` gives `0x4000 * 4 = 65536` bytes. After the loop `a6`
  has wrapped to `$FF0000`.
- `[static]` `movem.l (a6),d0-a6` then loads all registers from the zeroed RAM at
  `$FF0000`, zeroing `d0`–`d7`/`a0`–`a6` in one instruction. `[design]` It is a compact
  register-clear trick that relies on the wrap and the cleared RAM.
- `[static]` CRAM: command `$C0000000` (CRAM write from 0), then 32 longword writes =
  128 bytes = all 64 colours.
- `[static]` VSRAM: command `$40000010` (VSRAM write from 0), then 20 longword writes =
  80 bytes = all 40 words.
- `[static]` PSG mute: bytes `$9F,$BF,$DF,$FF` written to `$C00011` (`$11(a3)`) mute the
  four PSG channels.
- `[static]` After the init, `$8104` and `$8F02` set reg1 = display/V-int/DMA off,
  28 rows, and auto-increment = 2 for normal VRAM/CRAM access.

## 6. `doStart` and the ROM checksum

```asm
doStart:
    tst.w   (VdpCtrl).l
    jsr     (sub_7FF98).l
    ...
```

`[static]` `tst.w (VdpCtrl)` reads the VDP status; `[hardware]` a control-port read
resets the VDP command latch (the result is discarded).

`[static]` `sub_7FF98` is a **ROM integrity check**:

- Sums longwords from `0x000000` to `0x07FF97`, skipping the header checksum field at
  `0x018C`.
- Adds bytes at odd addresses from `0x080001` to `0x0BFFFF` (the routine itself and the
  checksum field are excluded).
- Compares the result with `$FE407B8A`.
- On mismatch it programs a few VDP registers and hangs in an infinite loop; on match
  it returns.

`[static]`/`[dynamic]` The computed value for `baserom.md` is exactly `$FE407B8A`, so the
check passes. `[design]` This is an anti-tamper/copy-protection measure: modified ROMs
stop at boot.

Then:

- `[static]` If the control ports are nonzero (`$A10008`/`$A1000C`), skip the logo and
  go straight to `.anyButtonPressed`.
- `[static]` Otherwise `LogoEA_Init`, enable display (`$8174`), set
  `ram_FF369E = $FFFF`, install `LogoEA_GameTick` as `ram_UpdateFunction`, and loop
  reading both controllers until a button is pressed or `LogoEA_ram_Finished` is set.
- `[static]` On exit: `ram_UpdateFunction = 0`; `jmp (loc_7E6A2)` (top-level flow).

## Verified facts

- `[static]` The ROM checksum routine computes `$FE407B8A` on `baserom.md` (verified with
  a Python reimplementation), so the anti-tamper check passes.
- `[static]` The Z80 reset polarity is `$0000` = assert, `$0100` = release; the sound
  code at `$1D9C2` uses the same sequence, confirming the boot comments are inverted.
- `[static]` `movem.l (a6),d0-a6` after the RAM clear zeroes all registers because `a6`
  wrapped to `$FF0000` and the RAM is zero.
- `[hardware]` The VDP register decode above follows the Genesis VDP register reference.

## Hypotheses

- `[hypothesis]` The `$A10008`/`$A1000C` check detects a soft reset by seeing the
  control-port state left by the input routines. Test: read `$A10008` at `RESET` on
  cold boot and after a soft reset.
- `[design]` The 38-byte Z80 stub is a placeholder/stop stub; the real driver is loaded
  later at `$1D9C2`. Test: break at `$1D9C2`, confirm the copy from `$1DA12`.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Verify the ROM checksum | Python reimplementation of `sub_7FF98` | `$FE407B8A` | `[confirmed]` the check passes. |
| Verify Z80 reset polarity | static: boot writes + sound code at `$1D9C2` | `$0000` assert, `$0100` release | `[confirmed]` comments at boot are inverted. |

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `sub_7FF98` | `RomChecksum_Verify` | routine sums the ROM and compares `$FE407B8A` | high |
| `start` | `softReset` | warm-reset branch target | medium |
| `defaults` | `bootDefaults` | packed init table | medium |

## Open questions

- [ ] Confirm the soft-reset behaviour dynamically (control ports + `ram_UpdateFunction`).
- [ ] Identify what the 38-byte Z80 stub is for (placeholder vs. a real init step).
- [ ] Analyze `GetInputPlayerA/B`, `VerticalInterrupt`, `HorizontalInterrupt`,
  `sub_1652`, and the exception handlers (next milestones).
- [ ] Confirm the VDP VRAM map after boot with `vr` / a VRAM viewer.

# Analysis: `src/main.asm` (boot flow)

- **Module / routine:** boot/init (RESET, defaults, Z80 stub, doStart)
- **ROM range:** `0x000200`–`0x0002FA` (boot code), `0x00028E`–`0x0002C3` (data)
- **Status:** boot flow analyzed; input/IRQ/helpers TODO
- **Source:** `src/main.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RESET` | `0x0200` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed (boot) |
| `start` | `0x028C` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `defaults` | `0x028E` | [x] | [x] | [x] | [x] | [x] | - | analyzed |
| `z80_start`/`z80_end` | `0x02C4` | [x] | [x] | [x] | [x] | [ ] | [ ] | analyzed (stub) |
| `doStart` | `0x02FA` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Boot_CheckRomChecksum` (ROM checksum) | `0x7FF98` | [x] | [x] | [x] | [ ] | [x] | [x] | analyzed |
| `GetInputPlayerA` | `0x10D4` | [x] | [x] | - | [x] | [x] | [x] | analyzed |
| `GetInputPlayerB` | `0x111C` | [x] | [x] | - | [x] | [x] | [x] | analyzed |
| `VerticalInterrupt` | `0x1164` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed (dispatcher) |
| `HorizontalInterrupt` | `0x145A` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed (audio semantics TODO) |
| Exception handlers | `0x13C0`… | [x] | [x] | [x] | [x] | [x] | - | analyzed (quirk) |
| `Audio_UpdateEngine` | `0x1652` | [x] | [x] | [x] | - | [x] | [x] | analyzed (field meanings hypothesis) |

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
The comment is corrected in `src/main.asm`.

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
these lines were inverted; they are corrected in `src/main.asm` (comments only).

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
    jsr     (Boot_CheckRomChecksum).l
    ...
```

`[static]` `tst.w (VdpCtrl)` reads the VDP status; `[hardware]` a control-port read
resets the VDP command latch (the result is discarded).

`[static]` `Boot_CheckRomChecksum` is a **ROM integrity check**:

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
  `Race_ram_HIntRasterDisabled = $FFFF`, install `LogoEA_GameTick` as `ram_UpdateFunction`, and loop
  reading both controllers until a button is pressed or `LogoEA_ram_Finished` is set.
- `[static]` On exit: `ram_UpdateFunction = 0`; `jmp (loc_7E6A2)` (top-level flow).

## 7. Controller input (`GetInputPlayerA/B`)

`[hardware]` A standard 3-button pad is read by toggling TH and reading the data port:

| Step | Write to data port | Bits 5-0 |
|---|---|---|
| 1 | `$40` (TH=1) | C, B, Right, Left, Down, Up |
| 2 | `$00` (TH=0) | Start, A, 0, 0, Down, Up |

The game performs the second step first, then the first step:

- `move.b #$40,$A10009` sets TH as an output on control port 1.
- `move.b #0,$A10003` clears TH; wait `d1=$A` (11 `dbf` iterations); read data;
  `asl.b #2` + `andi.b #$C0` moves the Start/A bits into bits 7-6.
- `move.b #$40,$A10003` sets TH; wait `d1=$A`; read data; `andi.b #$3F` keeps
  C/B/Right/Left/Down/Up.
- `or.b d1,d0` + `not.b d0` produce the `SACBRLDU` layout with **1 = pressed**:
  bit7 Start, bit6 A, bit5 C, bit4 B, bit3 Right, bit2 Left, bit1 Down, bit0 Up.

`[dynamic]` GDB-remote: the first call sees control ports `0` (not yet configured);
afterwards `ctrl1=ctrl2=$40`, `data1=data2=$7F` (no buttons). The returned `d0` has the
button byte in the **low 8 bits**; the upper bits are not cleared (observed
`d0=$0000FF00` with no buttons). Callers must use the low byte (`tst.b d0`,
`andi.w #$FF`).

Quirks:

- `GetInputPlayerB` waits `d1=$14` (21 iterations) instead of `$A` (11). The difference
  is not explained by the code; likely empirical timing for port 2 (`[design]`/`[unknown]`).
- The routines do **not** pause the Z80 while reading the ports, contrary to the
  hardware workaround for the Z80/68K bus conflict. `[design]` Road Rash predates the
  6-button pad (1991 vs 1993), so only the 3-button protocol is implemented; the code
  does not read X/Y/Z/Mode and may misbehave on 6-button pads.
- Because the input routines write `$40` to the control ports, the boot check of
  `$A10008`/`$A1000C` sees nonzero after the first input; this is the mechanism behind
  the warm-reset hypothesis (`[dynamic]` confirmed control-port state; `[hypothesis]`
  for the reset path).

## 8. `VerticalInterrupt` (`0x1164`)

```asm
VerticalInterrupt:
    movem.l d0-d7/a0-a6,-(sp)
    movea.l (ram_UpdateFunction).l,a0
    cmpa.l  #0,a0
    beq.w   .return
    jsr     (a0)
.return:
    movem.l (sp)+,d0-d7/a0-a6
    rte
```

`[static]` Contract: saves all registers, calls the pointer in `ram_UpdateFunction`
(`$FF1A62`) if nonzero, restores, returns. The update function may clobber any register.
`[confirmed]` the dispatcher runs every VBlank (observed return address `$117A` and the
fade experiment).

`[hardware]` The VDP V-int is acknowledged by reading the VDP status/control port. This
handler does not read it; the called update functions or screen code must do so (or the
interrupt source is cleared by the VDP's interrupt acknowledge). **Open question**:
verify where the V-int flag is cleared and whether a long update can overrun the VBlank
budget.

## 9. `HorizontalInterrupt` (`0x145A`)

`[static]` This is a raster-effect and engine-audio handler:

1. `move.w #$8AFF,VdpCtrl` re-arms the H-int counter for 255 lines.
2. If `Race_ram_HIntRasterDisabled == $FFFF`, return immediately (effect disabled; used during the
   logo/fade).
3. Save `d0-d2/a0-a2`.
4. Read the scroll-step offset `Race_ram_HIntScrollOffset`; if `<= 0`, skip to the end.
5. Index the VSRAM/scroll table at `Race_ram_NextVScrollInfo + offset`; it yields a
   VDP command word, a target HV value, a data word and a next offset:
   - write the command word to `VdpCtrl`;
   - load `d0` (target), `d1` (data word), `d2` (longword data), and the next
     `Race_ram_HIntScrollOffset`;
   - set VSRAM write address 0 (`VDP_VSRAM_WRITE`).
6. Busy-wait on the HV counter until the target scanline and horizontal position are
   reached (`.loc_14AA`, `.loc_14B2`, `.loc_14BC`); then write the longword `d2` to the
   VDP data port. This changes the scroll mid-frame (per-line/split scrolling).
7. Execute **36 NOPs**; `[hardware]`/`[design]` this is a VDP write-recovery delay
   (timing-critical; exact count probably tuned for the board/VDP).
8. Write `d1` to `VdpCtrl`.
9. If the next `Race_ram_HIntScrollOffset == $90`, run the once-per-frame engine-audio update:
   - reset `Race_ram_HIntScrollOffset = 0`;
   - if `ram_MusicEnabled != 0`, skip to `Audio_Update`;
   - if `Race_ram_State != 0`, call `Audio_Engine1Update`/`Audio_Engine2Update` and skip;
   - otherwise compute a speed/engine parameter from `RacePlayerA` (struct offset `$14`
     × `Race_ram_FrameCounter` + `STRUCT_OFFSET_SPEED`, scaled by `Race_ram_PlayerRpmDivisor` and
     `$3800`), smooth it into `Race_ram_Engine1Current` with a ±`$64` rate limit, derive `d1`
     (`>>5 + 2`, min 0), handle player B's struct `RacePlayerB` (distance to
     `Race_ram_PlayerProgress`), call `Audio_Engine1Update`, `Audio_UpdateEngine` (with `Race_ram_NearestActor`) and
     `Audio_Engine2Update`.
10. Set `Race_ram_HIntRasterDisabled = $FFFF`; if `Race_ram_HIntScrollOffset > 0`, set it back to 0 (re-enable the
    effect next time).

`[dynamic]` GDB-remote observed `Race_ram_HIntRasterDisabled = $FFFF` during the logo, then `0` once the
effect was enabled; `Race_ram_HIntScrollOffset = $10` and `ram_MusicEnabled = 1` in the observed
frames. `[static]` The audio calls are sound-driver entry points (`Audio_Update/8/11`);
their exact parameters are deferred with the audio deep dive.

## 10. `Audio_UpdateEngine` (`0x1652`)

`[static]` Contract: `a1` = object/struct pointer (`$FFFFFFFF` = invalid). Returns
`d0` = smoothed value, `d1` = distance parameter.

- Invalid pointer: `d1 = $1F`, `d0 = 0`.
- If bit 7 of `$6E(a1)` is set (engine active?), compute
  `$14(a1) * Race_ram_FrameCounter + $12(a1)`, clamp to 0, scale by
  `Race_ram_NearestRpmDivisor` and `$3800`.
- Add `$400`, clamp to `>= $400`, smooth toward `Race_ram_Engine3Current` with a ±`$64` rate limit,
  store back into `Race_ram_Engine3Current`.
- Compute `|Race_ram_PlayerProgress - 4(a1)| * 2`, take the high word, clamp to `<= $1F` -> `d1`.

`[hypothesis]` The routine computes engine-audio parameters for player B (or a second
object), mirroring the player-A math in `HorizontalInterrupt`; the struct fields
`$6E`/`$14`/`$12`/`4` are `STRUCT_OFFSET_*` fields but their exact game meaning is TODO.

## 11. Exception handlers

`[static]` Every exception handler is:

```asm
    lea     (vectorTable).w,a0
    move.l  #'TAG',(a0)
    stop    #$2700
```

The tags are `BUS `, `ADDR`, `ILEG`, `ZDIV`, `CHK `, `TRPV`, `PRIV`, `TRAC`, `LINA`,
`LINF`, `SPUR`.

`[static]` Quirk: `vectorTable` is at address 0, i.e. **cartridge ROM**; the write to
ROM is ignored by the cartridge, so the tag is not actually stored. The tag values are
still useful as an indicator when reading the handler code, and `stop #$2700` halts the
CPU permanently (interrupt mask 7). `[design]` This looks like a debug leftover; on an
exception the game freezes.

## Verified facts

- `[static]` The ROM checksum routine computes `$FE407B8A` on `baserom.md` (verified with
  a Python reimplementation), so the anti-tamper check passes.
- `[static]` The Z80 reset polarity is `$0000` = assert, `$0100` = release; the sound
  code at `$1D9C2` uses the same sequence, confirming the boot comments are inverted.
- `[static]` `movem.l (a6),d0-a6` after the RAM clear zeroes all registers because `a6`
  wrapped to `$FF0000` and the RAM is zero.
- `[hardware]` The VDP register decode above follows the Genesis VDP register reference.
- `[dynamic]` After the first input read, control ports 1/2 are `$40`; the long read at
  `$A10008` is therefore nonzero after the game starts. This confirms the state used by
  the warm-reset check.
- `[dynamic]` `GetInputPlayerA` returns the button byte in the low 8 bits and leaves the
  upper bits untouched (`d0=$0000FF00` with no buttons pressed).
- `[dynamic]` During the logo, `ram_UpdateFunction = 0x366` (`LogoEA_GameTick`) and
  `VerticalInterrupt` dispatches it every frame.
- `[dynamic]` `HorizontalInterrupt` fires during the logo with `Race_ram_HIntRasterDisabled = $FFFF`
  (effect disabled) and later with `Race_ram_HIntRasterDisabled = 0` (effect enabled);
  `Race_ram_HIntScrollOffset = $10`, `ram_MusicEnabled = 1` in the observed frames.
- `[static]` The exception handlers write their tags to address 0 (ROM), so the writes
  have no runtime effect; `stop #$2700` freezes the CPU.

## Hypotheses

- `[hypothesis]` The `$A10008`/`$A1000C` check detects a soft reset by seeing the
  control-port state left by the input routines. The control-port state is confirmed;
  the reset path itself still needs a Reset-button test.
- `[hypothesis]` The 36 NOPs after the VSRAM mid-frame write are a VDP write-recovery
  delay; the count is timing-tuned for the board. Test: vary/observe the effect in the
  emulator (not byte-exact, analysis only).
- `[hypothesis]` `Audio_UpdateEngine` computes engine-audio parameters for a second object/player.
- `[design]` The 38-byte Z80 stub is a placeholder/stop stub; the real driver is loaded
  later at `$1D9C2`. Test: break at `$1D9C2`, confirm the copy from `$1DA12`.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Verify the ROM checksum | Python reimplementation of `Boot_CheckRomChecksum` | `$FE407B8A` | `[confirmed]` the check passes. |
| Verify Z80 reset polarity | static: boot writes + sound code at `$1D9C2` | `$0000` assert, `$0100` release | `[confirmed]` comments at boot are inverted. |
| Input + interrupts | GDB remote: break `0x10D4`, `0x111A`, `0x1164`, `0x145A` | ctrl ports `$40`; `d0` low byte; VInt up=`0x366`; HInt `$FF369E` `$FFFF→0` | `[confirmed]` input/IRQ behaviour. |

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `start` | `softReset` | warm-reset branch target | medium |
| `defaults` | `bootDefaults` | packed init table | medium |

## Open questions

- [ ] Trigger a real soft reset and confirm the boot skips init/logo.
- [ ] Identify what the 38-byte Z80 stub is for (placeholder vs. a real init step).
- [ ] Where is the VDP V-int flag cleared (handler does not read the status)?
- [ ] HInt timing: confirm the 36-NOP delay and the HV-counter windows in BlastEm.
- [ ] Audio semantics of `Audio_Update/8/11` and `Audio_UpdateEngine` (deferred audio deep dive).
- [ ] 6-button pad behaviour (the code only implements the 3-button protocol).
- [ ] Confirm the VDP VRAM map after boot with `vr` / a VRAM viewer.

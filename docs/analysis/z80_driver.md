# Analysis: Z80 sound driver and sound data

- **Driver range:** `0x1DA12`–`0x1E5CC` (`0xBBB` bytes)
- **Sound data range:** `0x1E5CD`–`0x257CF` (`0x7203` bytes)
- **Assets:** `assets/audio/z80_driver/data.bin`, `assets/audio/sound_data/data.bin`
- **Status:** loader/mailbox and Z80 entry analyzed; full driver and sound-data format TODO

## Loader

`Audio_Init` calls `0x1D9C2`:

1. request Z80 bus (`$0100` -> `$A11100`);
2. copy `0xBBB` bytes from `$1DA12` to Z80 RAM `$A00000`;
3. assert/release Z80 reset;
4. wait `$1F4` dbf loops;
5. release the bus.

The 68k mailbox uses:

- `$A00256`: six 8-byte command slots copied from `$FF01BE`;
- `$A00286`: command-ready flag written after the block;
- `$A000BB..BF`: five special command bytes from `$FF01EE`;
- `$A00287`: byte read by the Z80 entry after reset.

## Z80 entry

Raw disassembly with radare2 (`-a z80 -b 16`):

```text
0000: c3 38 00       jp 0x0038
...
0038: f3             di
0039: 31 ff 1f       ld sp,0x1fff
003c: ed 46          im 0
003e: 3a 87 02       ld a,[0x0287]
0041: b7             or a
0042: 28 54          jr z,0x0054
0044: fa 68 00       jp m,0x0068
0047: 3e 2a          ld a,0x2a
0049: 32 00 40       ld [0x4000],a
```

So reset vectors through `0x38`, sets its own stack, uses IM 0, and consumes the
`$A00287` mailbox byte to select a command path. The command block at `$0256` and
special bytes at `$00BB..BF` are the next things to map.

## Sound data

The sound-data blob has no ASCII identifiers; it is sequence/instrument data, not
text. Its format and the Z80 sequence opcodes are TODO. The 68k engine already reads
one driver-relative table (`$1DA12 + $288 + (d0<<5)` for opcode `$80`), which is a
useful starting point.

## Open questions

- Full Z80 driver disassembly and IRQ/tick flow.
- Z80 command-block/special-command semantics.
- Sound-data sequence/instrument format.
- Mapping of 68k `Audio_PlaySfx` IDs to Z80 handlers.

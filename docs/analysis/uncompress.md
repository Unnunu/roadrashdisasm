# Analysis: `uncompress.asm` (LZSS decompressors)

- **Module:** LZSS decompression: byte format, word format, interruptible streaming,
  and direct-to-VRAM
- **ROM range:** `0x009B9E`–`0x009FE3` (`9FE4.asm` starts at `0x9FE4`)
- **Status:** analyzed; algorithm validated with a Python decoder against the assets
- **Source:** `uncompress.asm`
- **Related:** `docs/architecture.md`, `docs/ram-map.md`, `docs/analysis/8FB4.md`,
  `docs/coding-style.md` (asset formats), `race.asm` `WriteToVRAM`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `UncompressB` | `0x9B9E` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `UncompressW` | `0x9C26` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `sub_9CC6` | `0x9CC6` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `sub_9DC2` | `0x9DC2` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `UncompressToVRAM` | `0x9EF8` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |

## LZSS algorithm (all variants)

- Ring/window: 0x1000 bytes at `Road_ram_XLeftArray` (also used as road scratch),
  prefilled with `$20` (spaces); ring pointer starts at `0xFEE` (classic 18-byte
  lookahead).
- Stream: a flag byte, bits consumed LSB first (`lsr.b #1`):
  - `1` = literal: copy one byte (B) / the low byte of a word (W).
  - `0` = back-reference: two bytes give a 12-bit distance
    `index = b1 | ((b2 & $F0) << 4)` and a length `(b2 & $F) + 3` (3..18); copy from
    the ring, advancing the ring/window.
- Output stops when the 32-bit size counter reaches 0. Inputs: `a3` = compressed data,
  `a1` = output; the routines save/restore all registers (`movem`).
- Verified with a Python decoder: `unk_7EA66` 0x2B8, `img_Gamepad` 0xC20,
  `img_MainMenu_Background` 0xDA8, character image `0xAF902` 0x1058 bytes.

## `UncompressB` (byte format, `0x9B9E`)

- Size = the 32-bit long at `a3`; the byte stream starts after it.
- Literals are single bytes; the source stream is byte-aligned.
- Used for byte-format assets (backgrounds/gamepad/panel etc.).

## `UncompressW` (word format, `0x9C26`)

- Size = the 8-byte interleaved header: the code skips the even bytes and reads bytes
  1,3,5,7 as the big-endian size (the even bytes are ignored; e.g. character image
  `0xAF902` -> `0x1058`).
- The compressed stream is word-based: every flag/literal/back-reference byte is stored
  in the low byte of a 16-bit word (the high byte is skipped).
- Used for word-format assets (character portraits, titles, etc.).
- `UncompressToVRAM` uses the same word format.

## `UncompressToVRAM` (direct VRAM, `0x9EF8`)

- `a1` = VRAM destination (tile address), `a3` = compressed data.
- Builds the VDP control word from `a1` (`asl #2/lsr #2/ori #$4000/swap`), then
  decompresses the word format directly to `VdpData`, assembling 4 bytes in
  `ram_FF13AA` and writing a long every 4 bytes; flushes the trailing partial long.
- Used by the endlevel animation tiles (`unk_80000` -> `$5C00`).

## Streaming (interruptible) variants

`sub_9CC6` starts a byte-format decode and `sub_9DC2` resumes it, with a per-call
output budget in `d1` (in addition to the total remaining size in `d2`). The whole
decoder state is saved to `ram_FF136C`..`ram_FF13A4` and `ram_FF13A8`:

| Address | State |
|---|---|
| `$FF136C` | a0 (ring base). |
| `$FF1370` | a1 (output pointer). |
| `$FF1374` | a2 (ring pointer). |
| `$FF1378` | a3 (source pointer). |
| `$FF137C`..`$FF1384` | a4/a5/a6. |
| `$FF1388`..`$FF13A4` | d0/d1/d2(remaining)/d3(bit count)/d4/d5(run)/d6(flags)/d7(ring index). |
| `$FF13A8` | mid-back-reference flag (`$FFFF` while inside a match). |

`sub_9CC6` clears/initializes the ring; `sub_9DC2` restores most of the state but
**not** `a1`/`d1`: the caller must supply the output pointer (from `ram_FF1370`) and
the new budget. The ring persists across calls, so a stream can be decoded over several
frames.

## Interplay with other modules

- The ring buffer is `Road_ram_XLeftArray`, the road scratch array; the decompressors
  overwrite it (the ring is not preserved across separate `UncompressB/W` calls).
- `WriteToVRAM` (`race.asm`) expects the decompressed asset's first long to hold the
  tile count in its low word (the `asl.w` ignores the high word). The observed first
  longs are `$08080007` (panel, 7 tiles) and `$0808011A` (gamepad, low word `$011A`).
  The high word `$0808` appears to be a format marker; the exact header semantics and
  the gamepad's over-copy (the low word exceeds the tiles that fit in 0xC20 bytes) are
  TODO.
- `LogoEA_Uncompress` (logoEA.asm) is a separate decompressor with its own ring buffer.

## Quirks / notes

- The B/W routines clear the 0x1000 ring to spaces and start at `0xFEE`; the match
  length is nibble+3 because `dbf` runs d5+1 times. `[static]`
- `sub_9DC2` saves but does not restore `a1`/`d1`; the caller owns them. `[static]`
- The streaming state is saved on every chunk end and includes all registers. `[static]`
- The ring overwrites `Road_ram_XLeftArray`; do not call a decompressor while the road
  array is live. `[static]`

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `sub_9CC6` | `UncompressStreamStart` | saves state, starts decode | high |
| `sub_9DC2` | `UncompressStreamContinue` | restores state, resumes | high |
| `ram_FF136C`..`$FF13A8` | `Uncompress_State` | decoder state block | high |
| `Road_ram_XLeftArray` | (keep) | doubles as LZ ring | medium |

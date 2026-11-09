# Module card: `uncompress.asm`

- **ROM range:** `0x009B9E`–`0x009FE3` (`track_data.asm` starts at `0x9FE4`)
- **Status:** analyzed; algorithm validated with a Python decoder
- **Related:** `docs/architecture.md`, `docs/ram-map.md`, `docs/analysis/uncompress.md`

## Role / purpose

LZSS decompression for every compressed asset: byte format (`UncompressB`), word format
(`UncompressW`), an interruptible streaming byte decoder (`UncompressStreamStart`/`UncompressStreamContinue`) and a
direct-to-VRAM word decoder (`UncompressToVRAM`).

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `UncompressB` | `0x9B9E` | asset loaders | 32-bit size prefix + byte LZSS. |
| `UncompressW` | `0x9C26` | asset loaders | 8-byte interleaved size + word LZSS. |
| `UncompressStreamStart` | `0x9CC6` | streaming users | Start a byte decode with a per-call budget. |
| `UncompressStreamContinue` | `0x9DC2` | streaming users | Resume the decode. |
| `UncompressToVRAM` | `0x9EF8` | `endlevel.asm` | Word LZSS straight to the VDP. |

All use `a3` = source, `a1` = output (VRAM dest for `UncompressToVRAM`).

## LZSS algorithm

- 0x1000 ring at `Road_ram_XLeftArray`, prefilled with `$20`, pointer `0xFEE`.
- Flag bits LSB first: 1 = literal, 0 = match; match = 12-bit distance
  (`b1 | ((b2 & $F0) << 4)`) and length `(b2 & $F) + 3` (3..18).
- Stop at the 32-bit output size.
- B: size = 32-bit long at the source; byte-aligned stream.
- W: size = odd bytes of an 8-byte interleaved header; stream stored one byte per word
  (high byte skipped).
- `UncompressToVRAM`: W stream to `VdpData`, 4-byte assembly in `Uncompress_StateVram`, trailing
  partial flushed.

## Streaming state

`Uncompress_StateA0`..`Uncompress_StateD7` (a0-a6/d0-d7) and `Uncompress_StateMidMatch` (inside-match flag).
`UncompressStreamStart` initializes; `UncompressStreamContinue` restores most state but **not** `a1`/`d1` (the caller
supplies the output pointer and new budget); the ring persists across calls.

## RAM / ROM & structures

- `Road_ram_XLeftArray`: LZ ring (also road scratch, overwritten).
- `Uncompress_StateVram`: 4-byte VRAM assembly buffer.
- Asset header: the decompressed image begins with a `$0808` marker and the tile count
  in the low word (observed `$08080007` panel, `$0808011A` gamepad); `WriteToVRAM`
  (`race.asm`) uses the low word. Exact header semantics/TODO.
- Validated sizes: panel `0x2B8`, gamepad `0xC20`, background `0xDA8`, character
  `0x1058`.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `UncompressB` | `0x9B9E` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `UncompressW` | `0x9C26` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `UncompressStreamStart` | `0x9CC6` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `UncompressStreamContinue` | `0x9DC2` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `UncompressToVRAM` | `0x9EF8` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |

Detailed listing: `docs/analysis/uncompress.md`.

## External calls / dependencies

- Used by `logoEA.asm`? (no, LogoEA has its own), `intro.asm`, `menu_main.asm`,
  `rider_intro.asm`, `race_results.asm`, `highscore.asm`, `shop.asm`, `endlevel.asm`,
  `race.asm` (asset loaders).
- `WriteToVRAM` (`race.asm`) consumes the decompressed tile-count header.

## Hacks / bugs / quirks

- The ring buffer is the road scratch array; calling a decompressor while the road array
  is live would corrupt it. `[static]`
- `UncompressStreamContinue` saves but does not restore `a1`/`d1`; the caller owns them. `[static]`
- The match length is nibble+3 (DBF runs d5+1 times). `[static]`
- The decompressed image's first long is a `$0808` marker + tile-count low word; the
  gamepad count `$011A` exceeds the tiles that fit in 0xC20 bytes, so `WriteToVRAM`
  over-copies harmless/unused tiles. TODO/exact header semantics.

## Verified facts

- `[static]` LZSS parameters, ring, B/W formats and streaming state.
- `[dynamic]` Python decoder reproduces the exact asset sizes for panel/gamepad/
  background/character images.

## Hypotheses

- `[hypothesis]` The `$0808` high word is a format/“8x8 tile” marker; test: more assets.
- `[hypothesis]` Streaming is used for race/road data across frames; test: find
  `UncompressStreamStart/9DC2` callers in the gap.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Validate LZSS | Python decoder, `baserom.md` | sizes 0x2B8/0xC20/0xDA8/0x1058 match | algorithm confirmed |

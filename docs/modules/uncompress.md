# Module card: `src/core/uncompress.asm`

- **ROM range:** `0x009B9E`–`0x009FE3` (`src/race/track_data.asm` starts at `0x9FE4`)
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
| `UncompressToVRAM` | `0x9EF8` | `src/screens/endlevel.asm` | Word LZSS straight to the VDP. |
All use `a3` = source, `a1` = output (VRAM dest for `UncompressToVRAM`).

## External calls / dependencies
- Used by `src/logoEA/logoEA.asm`? (no, LogoEA has its own), `src/screens/intro.asm`, `src/screens/menu_main.asm`,
  `src/screens/rider_intro.asm`, `src/screens/race_results.asm`, `src/screens/highscore.asm`, `src/screens/shop.asm`, `src/screens/endlevel.asm`,
  `src/race/race.asm` (asset loaders).
- `WriteTilesetToVRAM` (`src/race/race.asm`) consumes the decompressed tile-count header.

## Hacks / bugs / quirks
- The ring buffer is the road scratch array; calling a decompressor while the road array
  is live would corrupt it. `[static]`
- `UncompressStreamContinue` saves but does not restore `a1`/`d1`; the caller owns them. `[static]`
- The match length is nibble+3 (DBF runs d5+1 times). `[static]`
- The decompressed image's first long is a `$0808` marker + tile-count low word; the
  gamepad count `$011A` exceeds the tiles that fit in 0xC20 bytes, so `WriteTilesetToVRAM`
  over-copies harmless/unused tiles. TODO/exact header semantics.

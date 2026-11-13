# Module card: `src/logoEA/logoEA.asm`

- **ROM range:** `0x000366`–`0x00117F`
- **Status:** partially analyzed (VDP trick understood statically; dynamic VRAM confirmation pending)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/logoEA.md`

## Role / purpose
Electronic Arts logo screen. Generates the square/triangle/circle figures as tiles at
runtime, animates them as sprites, decompresses the "Electronic Arts" text image, and
uses an unusual shared-plane/per-line-H-scroll VDP setup for the text effect. Runs before
the intro/menus; `doStart` polls `LogoEA_ram_Finished` to leave the logo.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `LogoEA_Init` | `0x093E` | `doStart` | Clears the logo RAM overlay, sets the VDP mode, clears VRAM, builds figures/text. |
| `LogoEA_GameTick` | `0x0366` | `ram_UpdateFunction` during the logo | Calls `LogoEA_Update`. |
| `LogoEA_Update` | `0x0406` | `LogoEA_GameTick` | Text H-scroll wave, figure animation, sprite updates. |
| `LogoEA_SetupGfx` | `0x0A08` | `LogoEA_Init` | Builds figure tiles, uploads sprites, decompresses text, writes text nametable. |
| `LogoEA_DecompressLZ` | `0x0C3C` | `LogoEA_SetupGfx` | LZSS-style decompressor (4 KiB ring buffer, 8-bit control mask). |

## External calls / dependencies
- `doStart` (enable display/poll finished), `VerticalInterrupt` (per-frame call).
- The compressed EA logo asset is generated as `assets/images/ea_logo/data.bin`
  (ROM `0xCFE`, size `0x3D6`) and included via `binclude`.
- No sound calls in this module.

## Hacks / bugs / quirks
- Shared plane A/B nametable (`$A000`) with per-line H-scroll for a ghost/wave effect.
- Per-row single-word VDP commands rely on the retained command latch (`$720C` →
  `$B20C`); the source has `???` comments at these spots.
- The display is off during `LogoEA_Init`; `doStart` enables it afterwards.
- The overlay writes use 32-bit `$FFFFxxxx` values because the ROM encodes them literally.

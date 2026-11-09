# Module card: `logoEA.asm`

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
| `LogoEA_Uncompress` | `0x0C3C` | `LogoEA_SetupGfx` | LZSS-style decompressor (4 KiB ring buffer, 8-bit control mask). |

## Control flow / state machine

- **Init:** clear the `$FFFFCxxx` overlay, save `sr` and mask interrupts, program VDP
  registers (see below), clear VRAM (64 KiB), clear VSRAM, call `SetupGfx`, set the
  H-scroll table address, restore `sr`. The display itself is enabled by `doStart`
  (`$8174`).
- **SetupGfx:** build the square (9 strips), triangle (slope `$97B4`), circle (profile
  tables); upload 72 tiles for each; create 18 sprites per figure at `$DC00`; decompress
  the EA text; write its palette/CRAM, tiles/VRAM and nametable.
- **Update (every frame, figures every 3 frames):** decrement `TextTimer`, write the
  per-line H-scroll table (fg wave, bg `$140`), animate figure scale/flip/palette, update
  sprite VPos/HPos/links/size, upload circle tiles, cycle figures; set
  `LogoEA_ram_Finished` when the text and figures are done.

## VDP configuration (the unusual part)

- `reg2=$8228` → plane A nametable `$A000`; `reg4=$8405` → plane B nametable `$A000`
  (**same table**).
- `reg0B=$8B03` → H-scroll **per line**; `reg90=$9003` → plane size 128x32;
  `reg8D=$8D08` → H-scroll table `$2000`.
- `reg8A=$8A01` → H-int counter 1, but `reg0=$8004` disables H-int (unused).
- The text is **not** written at `$8000`: `VDP_VRAM_WRITE $8000` loads the command's high
  address bits (`$0002`), then per row a single control word `$720C` is written; the VDP
  keeps the previous second word, so the effective address is `$B20C` **inside the shared
  plane**. Each row adds `$100` (128 cells). The `$7044/$7144/$710C/$7136` commands add
  the TM/symbol entries. The H-scroll table gives the two shared planes different scroll
  values, producing a ghosted/wavy text.

See `docs/analysis/logoEA.md` for the full address/effect analysis and the dynamic
confirmation TODO.

## RAM / ROM & structures

Overlay map (`$FFFFCxxx`): `TextTimer` (`$C000`), `FigureAnimationFrame` (`$C002`),
`NextUpdateTimer` (`$C004`), `LineValue` (`$C006`), `CurrentFigure` (`$C00A`),
`Square/Triangle/Circle` sprite arrays (`$C00C`…), tile buffers (`$C0E4`/`$C9E4`/`$D2E4`,
`$900` each), `ImageEAUncompressed` (`$DBE4`), `UncompressTempBuffer` (`$E7E4`, `$1000`).
The overlay overlaps later menu framebuffers (see `docs/ram-map.md`).

## External calls / dependencies

- `doStart` (enable display/poll finished), `VerticalInterrupt` (per-frame call).
- The compressed asset `LogoEA_Image_ElectronicArts.bin` (`binclude`).
- No sound calls in this module.

## Hacks / bugs / quirks

- Shared plane A/B nametable (`$A000`) with per-line H-scroll for a ghost/wave effect.
- Per-row single-word VDP commands rely on the retained command latch (`$720C` →
  `$B20C`); the source has `???` comments at these spots.
- The display is off during `LogoEA_Init`; `doStart` enables it afterwards.
- The overlay writes use 32-bit `$FFFFxxxx` values because the ROM encodes them literally.

## Coverage matrix

See `docs/analysis/logoEA.md` for the full matrix (all functions analyzed; the VDP latch
address and the exact wave visuals need dynamic confirmation).

## Verified facts

- `[static]` Plane A and B share `$A000`; the H-scroll table scrolls them differently.
- `[static]` The text rows are addressed via the `$720C` first-word command with the
  retained second word `$0002`, i.e. `$B20C` inside the plane, not `$8000`.
- `[static]` The LZ decompressor uses a 4 KiB ring buffer initialized to `$20` and an
  8-bit control mask (literal/back-reference).
- `[dynamic]` `LogoEA_GameTick` (`0x366`) is the update function during the logo (GDB
  experiment).

## Hypotheses

- `[hypothesis]` The VDP command latch retains the high address bits and the `$B20C`
  placement is the intended text position. Confirm with the VRAM/plane viewer.
- `[hypothesis]` The shared-plane + per-line alternating scroll is the intended ghost/wave
  text effect.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `LogoEA_Uncompress` | `LogoEA_DecompressLZ` | LZSS-style loop | high |
| `logoEA_WriteNametableEntry` | `LogoEA_WriteNametablePair` | writes two words | high |

## Open questions

- [ ] Confirm the `$B20C` address and the `$7044/...` entries in BlastEm's VRAM/plane
  viewer.
- [ ] Confirm the figure animation frames (7/20/25) and palette swaps.
- [ ] Confirm the exact H-scroll wave values and visual result.

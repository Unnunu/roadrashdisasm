# Module card: `src/core/fade.asm`

- **ROM range:** `0x001180`–`0x0013BF` (verify the exact end against `build/roadrash.lst`)
- **Status:** partially analyzed
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`

## Role / purpose
Palette fading during transitions. A fade is driven by the main update-function pointer
`ram_UpdateFunction` (`$FF1A62`): the fade tick is installed there and clears it when the
palette has finished changing.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Fade_InitFadeOut` | `0x1180` | `0x07E6BC` (boot/attract, outside current coverage) | Copies the global palette into the current buffer, strips intensity, clears the target to black. |
| `Fade_InitFadeIn` | `0x11C0` | `0x07E6F8` (boot/attract, outside current coverage) | Copies the global palette into the target buffer, clears the current buffer. |
| `Fade_GameTickWithInit` | `0x1200` | not referenced in disassembled sources | Sets up VDP scroll/backdrop state, then falls through to `Fade_GameTick`. |
| `Fade_GameTick` | `0x1242` | installed into `ram_UpdateFunction` (`$FF1A62`) by `0x07E6D6`, `0x07E6FC` | Steps the current palette toward the target; clears `ram_UpdateFunction` when done. |
| `FadeWithFunction_GameTick` | `0x12F8` | compares against `ram_UpdateFunction` in `src/screens/menu_main.asm` | Same stepping, then calls `Fade_ram_UpdateFunction` when the palette settles. |

## External calls / dependencies
- `DmaWriteCRAM` — palette DMA.
- VDP control/data writes in `Fade_GameTickWithInit`.
- Boot/attract sequence at `0x07E6A2` (now in `src/core/top_level.asm`) installs
  `Fade_GameTick` into `$FF1A62` and polls it until cleared.

## Hacks / bugs / quirks
- `Fade_InitFadeOut` / `Fade_InitFadeIn` looked unreferenced at first: their addresses
  do not occur as 4-byte values, because the callers use `jsr` with a 16-bit absolute
  operand (`4EB8 1180`, `4EB8 11C0`) in the top-level flow (`src/core/top_level.asm`, `0x07E6A2`).
- The 4-byte occurrences of `$00001242` around `$7E6xx` are `move.l #...,$FF1A62`
  immediates, not a data pointer table.

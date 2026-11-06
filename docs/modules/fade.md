# Module card: `fade.asm`

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
| `FadeWithFunction_GameTick` | `0x12F8` | compares against `ram_UpdateFunction` in `menu_main.asm` | Same stepping, then calls `Fade_ram_UpdateFunction` when the palette settles. |

## Control flow / state machine

`[static]` `Fade_GameTick`:

1. Decrements `Fade_ram_Timer` (`$FF0300`); when it goes negative it is reloaded with 3,
   so the palette is modified every 4th call (frame).
2. DMA-copies `Fade_ram_CurrentPalette` (`$FF0306`) to CRAM via `DmaWriteCRAM`.
3. For each of 64 palette words, compares target vs current in three channels and moves
   the current value by a small step: `±2` for the blue component / low nibble, `±$20`
   for the high nibble.
4. If nothing changed (`d1 == 0`), writes 0 to `ram_UpdateFunction` (fade finished).

`FadeWithFunction_GameTick` performs the same stepping and then invokes
`Fade_ram_UpdateFunction` (a per-use callback) while a fade is active.

## RAM / ROM & structures

- `Fade_ram_Timer` `$FF0300` — reload value 3, decremented per tick.
- `Fade_ram_UpdateFunction` `$FF0302` — per-fade callback pointer.
- `Fade_ram_CurrentPalette` `$FF0306` — 64 words (128 bytes).
- `Fade_ram_TargetPalette` `$FF0386` — 64 words (128 bytes).
- `ram_UpdateFunction` `$FF1A62` — main per-frame update pointer (cross-module; in
  `ram_const.asm`).

## External calls / dependencies

- `DmaWriteCRAM` — palette DMA.
- VDP control/data writes in `Fade_GameTickWithInit`.
- Boot/attract sequence at `0x07E6A2` (not yet in the disassembly) installs
  `Fade_GameTick` into `$FF1A62` and polls it until cleared.

## Hacks / bugs / quirks

- `Fade_InitFadeOut` / `Fade_InitFadeIn` looked unreferenced at first: their addresses
  do not occur as 4-byte values, because the callers use `jsr` with a 16-bit absolute
  operand (`4EB8 1180`, `4EB8 11C0`) in the not-yet-disassembled region at `0x07E6A2`.
- The 4-byte occurrences of `$00001242` around `$7E6xx` are `move.l #...,$FF1A62`
  immediates, not a data pointer table.

## Verified facts

- `[static]` `Fade_GameTick` reloads the timer with 3 and therefore steps the palette
  every 4th frame; it clears `ram_UpdateFunction` when no channel changed.
- `[static]` `Fade_InitFadeOut` copies `Global_ram_Palette` to the current palette,
  masks with `$EEE`, and zeroes the target palette.
- `[static]` `Fade_InitFadeIn` copies `Global_ram_Palette` to the target palette
  (masked `$EEE`) and zeroes the current palette.
- `[static]` Boot/attract at `0x07E6A2` calls `Fade_InitFadeOut`, then installs
  `Fade_GameTick` into `$FF1A62`, then calls `Intro_Init` (`0x1704`) and
  `Fade_InitFadeIn`.

## Hypotheses

- `[hypothesis]` The boot/attract sequence fades out the EA logo, runs the intro init,
  and fades back in. Test: run the breakpoint experiment below and watch `$FF1A62`,
  `$FF0300`, and `vr` across the logo→intro transition.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Confirm boot/attract fade sequence | pending: `b 7E6A2`, `b 1180`, `b 11C0`, `b 1242` | TODO | TODO |

## Open questions

- [ ] Exact scenes that use `FadeWithFunction_GameTick` and what callback is installed.
- [ ] Confirm the 4-frame cadence and the `±2` / `±$20` step constants in the emulator.
- [ ] Verify the exact end address of `fade.asm` in the ROM layout.

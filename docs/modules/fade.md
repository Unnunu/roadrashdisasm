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
  `src/core/ram_const.asm`).

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
- `[static]` `Fade_InitFadeOut` has 11 call sites and `Fade_InitFadeIn` has 9, all in
  the top-level flow (`src/core/top_level.asm`, `$7E6A2`–`$7EA65`).
- `[static]` The top-level flow pairs a fade-in (with `FadeWithFunction_GameTick`
  installed and a callback in `a0`) with a fade-out (with `Fade_GameTick` installed)
  around `Menu_Init` (`$3400`), `RiderIntro_Init` (`$59C4`), `HighScore_Init` (`$6DC0`),
  and `Race_Init` (`$A4E2`). See `docs/reverse-engineering.md` section 9.
- `[dynamic]` BlastEm native console: a breakpoint at `$1180` hit with the caller
  `$7E8D6` (`jsr $1180.w`, race-exit path), `pc = $1180`, `a0 = $00FF411C`,
  `d0 = $00FF0002`.
- `[static]` On that path the next update function is `Fade_GameTickWithInit` (`$1200`),
  which never reads `Fade_ram_UpdateFunction`; the observed `a0` is not used here.
- `[confirmed]` GDB remote, boot/attract: `Fade_GameTick` (`$1242`) runs with
  `$FF0300` = 3, 2, 1, 0 and then reloads to 3; `$FF1A62` = `$00001242` throughout.
  This confirms the 4-frame cadence.
- `[confirmed]` The VBlank handler `VerticalInterrupt` (`$1164`) loads `$FF1A62` into
  `a0` and executes `jsr (a0)` every frame (observed return address `$117A`).
- `[dynamic]` Boot fade-out: first `$1180` hit with `a0 = $FFFFC078`,
  `d0 = $0000FF00`, return address `$0007E6C0` (caller `jsr $1180.w` at `$7E6BC`).
- `[dynamic]` `$FF0302` (`Fade_ram_UpdateFunction`) = `$FFFFC078` during the first fade
  cycle, then `$00FF0586` after `Fade_InitFadeIn` (`$11C0`) runs.
- `[static]` In the menu/character/results/shop/endlevel paths, `Fade_InitFadeIn` runs
  with `a0` = the next update function (`MainMenu_GameTick`, `RiderIntro_GameTick`,
  `HighScore_GameTick_Demo`, `RaceResults_GameTick`, `HighScore_GameTick`,
  `Shop_GameTick`, `EndLevel_GameTick`) and `FadeWithFunction_GameTick` is installed.
  When the fade settles, that callback replaces `ram_UpdateFunction`.
- `[static]` In the intro path, `Fade_GameTick` (not `FadeWithFunction_GameTick`) is
  installed after `Fade_InitFadeIn`; the `a0` value is ignored there.
  `[refuted]` the hypothesis that `$00FF0586` (the observed `$FF0302`) is a callback:
  it is a leftover value from `Intro_Init`, not a function pointer.
- `[confirmed]` `$BA76` installed after `Race_Init` is `Race_GameTick`.

## Hypotheses

- `[hypothesis]` `$FF3692` is a top-level state/selection flag that decides whether the
  flow goes to Character/HighScore/Race or back to the menu. Test: read `$FF3692` at
  the branch points `$7E7C2`, `$7E802`, `$7E8CC`, `$7E8D2`.
- `[confirmed]` `$FF1A62` is set to `$BA76` (`Race_GameTick`) as the race per-frame
  tick after `Race_Init`.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Identify a real `Fade_InitFadeOut` caller | native `b 1180`, `bt` | caller `$7E8D6` (`jsr $1180.w`), `a0=$FF411C`, `d0=$00FF0002` | race-exit path calls the fade-out. |
| Confirm timer cadence and update pointer | GDB remote: `break *0x1180`, `break *0x1242`, RAM dump | timer 3,2,1,0,3,2,1,0; `$FF1A62=$1242`; callers `$7E6BC` / `$117A`; dump saved | `[confirmed]` static reading. |

## Open questions

- [ ] Meaning of `$FF3692`, `$FF3696`, `$FF369A` in the top-level flow.
- [ ] Meaning of the `FadeWithFunction_GameTick` callbacks' per-frame behavior
  (`MainMenu_GameTick`, `RiderIntro_GameTick`, ...): follow up in their own cards.
- [ ] Confirm that `$00FF0586` is really just leftover `a0` from `Intro_Init` (static
  reading; dynamic trace of `Intro_Init` would settle it).
- [ ] Verify the `±2` / `±$20` palette step constants with a CRAM/palette check.
- [ ] Verify the exact end address of `src/core/fade.asm` in the ROM layout.

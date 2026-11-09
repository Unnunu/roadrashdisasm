# Module card: `src/main.asm`

- **ROM range:** `0x000000`–`0x0016E6F` (entry `RESET` at `0x000200`; includes interleaved)
- **Status:** partially analyzed (boot flow done; input/IRQ/helpers TODO)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/main.md`

## Role / purpose

Entry point of the ROM: vector table, Sega header, boot/init (VDP, DMA, Z80, RAM,
CRAM/VSRAM, PSG), ROM integrity check, EA-logo loop, controller input, interrupt
dispatchers, exception handlers, and the include directives that lay out the rest of
the game.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `RESET` | `0x0200` | CPU reset vector | Cold/warm boot and hardware init. |
| `start` | `0x028C` | `RESET` warm-reset branch | Skips init, jumps to `doStart`. |
| `doStart` | `0x02FA` | `RESET`/`start` | ROM checksum, logo loop, then top-level flow. |
| `GetInputPlayerA` | `0x10D4` | screens/input code | Reads pad A (TH protocol). |
| `GetInputPlayerB` | `0x111C` | screens/input code | Reads pad B (TH protocol). |
| `VerticalInterrupt` | `0x1164` | VBlank IRQ | Calls `ram_UpdateFunction` (`$FF1A62`). |
| `HorizontalInterrupt` | `0x145A` | HBlank IRQ | TODO. |
| `Audio_UpdateEngine` | `0x1652` | `HorizontalInterrupt` | TODO. |

## Control flow / state machine

- **Boot:** warm-reset check on `$A10008`/`$A1000C` -> TMSS check -> VDP register init
  from the packed `defaults` table -> DMA VRAM fill -> Z80 stub load/reset sequence ->
  work RAM clear -> CRAM/VSRAM/PSG clear -> register zeroing -> `start`.
- **`doStart`:** VDP status read -> `Boot_CheckRomChecksum` ROM checksum -> if control ports are
  already set, skip the logo; otherwise `LogoEA_Init`, enable display, install
  `LogoEA_GameTick` as the update function, and wait for a button or logo completion ->
  `ram_UpdateFunction = 0`, `jmp (loc_7E6A2)` (top-level flow).
- **Per frame:** `VerticalInterrupt` loads `ram_UpdateFunction` and calls it
  (`jsr (a0)`).

See `docs/analysis/main.md` for the annotated boot flow and evidence.

## RAM / ROM & structures

- `ram_UpdateFunction` `$FF1A62` — per-frame update pointer.
- `LogoEA_ram_Finished` `$FF1A66` — logo completion flag.
- `ram_FF369E` — set to `$FFFF` while the logo runs.
- ROM checksum routine `Boot_CheckRomChecksum` (`0x7FF98`, outside this file's code range).

## External calls / dependencies

- `LogoEA_Init` / `LogoEA_GameTick` (logo).
- `Boot_CheckRomChecksum` (ROM checksum), `Boot_CheckRomChecksum` failure path.
- Z80 sound code (loader at `$1D9C2`; see `docs/analysis/audio.md`).
- All include modules via `include` directives.

## Hacks / bugs / quirks

- The packed `defaults` table drives init via `a5`; `d5`/`d7` encode VDP register writes.
- The work-RAM clear relies on `a6` wrapping from 0 to `$FF0000`; the following
  `movem.l (a6),d0-a6` zeroes all registers from the cleared RAM.
- The boot Z80 comments were inverted; corrected (comments only).
- `Boot_CheckRomChecksum` is an anti-tamper ROM checksum: mismatch hangs the game.

## Coverage matrix

See `docs/analysis/main.md` for the full matrix. Boot (`RESET`, `start`, `defaults`,
Z80 stub, `doStart`), input (`GetInputPlayerA/B`), `VerticalInterrupt`,
`HorizontalInterrupt`, `Audio_UpdateEngine`, and the exception handlers are analyzed; the audio
parameters inside `HorizontalInterrupt`/`Audio_UpdateEngine` are deferred with the audio deep dive.

## Verified facts

- `[static]` The ROM checksum computes `$FE407B8A` on `baserom.md` (Python
  reimplementation), so `Boot_CheckRomChecksum` passes.
- `[static]` Z80 reset polarity: `$0000` assert, `$0100` release (confirmed by the sound
  code at `$1D9C2`); boot comments corrected.
- `[static]` `movem.l (a6),d0-a6` zeroes registers from cleared RAM at `$FF0000`.
- `[confirmed]` `VerticalInterrupt` dispatches `ram_UpdateFunction` every frame
  (GDB-remote experiment, see `fade.md`).
- `[dynamic]` After the first input read, control ports 1/2 are `$40`; `GetInputPlayerA`
  returns the button byte in the low 8 bits (upper bits untouched).
- `[dynamic]` `HorizontalInterrupt` disables the raster effect while `ram_FF369E=$FFFF`
  (logo) and enables it later (`$FF369E=0`); `ram_FF0406` is the scroll-table offset.
- `[static]` Exception-handler tags are written to address 0 (ROM, ignored); `stop`
  freezes the CPU.

## Hypotheses

- `[hypothesis]` The `$A10008`/`$A1000C` check detects a soft reset. Test: read those
  ports on cold boot vs. after Reset.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| ROM checksum | Python reimplementation of `Boot_CheckRomChecksum` | `$FE407B8A` | `[confirmed]` check passes. |
| Z80 reset polarity | static boot + sound code | `$0000` assert / `$0100` release | `[confirmed]` |

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `start` | `softReset` | warm-reset entry | medium |
| `defaults` | `bootDefaults` | packed init table | medium |

## Open questions

- [ ] Trigger a real soft reset and confirm the boot skips init/logo.
- [ ] Confirm where the VDP V-int flag is cleared (the handler does not read status).
- [ ] Confirm the HInt timing/36-NOP delay and the 6-button-pad behaviour.
- [ ] Audio semantics of `AudioFunc1/8/11` and `Audio_UpdateEngine` (deferred).
- [ ] Identify the purpose of the 38-byte Z80 stub.

# Module card: `main.asm`

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
| `sub_1652` | `0x1652` | `HorizontalInterrupt` | TODO. |

## Control flow / state machine

- **Boot:** warm-reset check on `$A10008`/`$A1000C` -> TMSS check -> VDP register init
  from the packed `defaults` table -> DMA VRAM fill -> Z80 stub load/reset sequence ->
  work RAM clear -> CRAM/VSRAM/PSG clear -> register zeroing -> `start`.
- **`doStart`:** VDP status read -> `sub_7FF98` ROM checksum -> if control ports are
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
- ROM checksum routine `sub_7FF98` (`0x7FF98`, outside this file's code range).

## External calls / dependencies

- `LogoEA_Init` / `LogoEA_GameTick` (logo).
- `sub_7FF98` (ROM checksum), `sub_7FF98` failure path.
- Z80 sound code (later at `$1D9C2`, audio deferred).
- All include modules via `include` directives.

## Hacks / bugs / quirks

- The packed `defaults` table drives init via `a5`; `d5`/`d7` encode VDP register writes.
- The work-RAM clear relies on `a6` wrapping from 0 to `$FF0000`; the following
  `movem.l (a6),d0-a6` zeroes all registers from the cleared RAM.
- The boot Z80 comments were inverted; corrected (comments only).
- `sub_7FF98` is an anti-tamper ROM checksum: mismatch hangs the game.

## Coverage matrix

See `docs/analysis/main.md` for the full matrix. Summary: boot (`RESET`, `start`,
`defaults`, Z80 stub, `doStart`) analyzed; `GetInputPlayer*`, `HorizontalInterrupt`,
`sub_1652`, and exception handlers still TODO.

## Verified facts

- `[static]` The ROM checksum computes `$FE407B8A` on `baserom.md` (Python
  reimplementation), so `sub_7FF98` passes.
- `[static]` Z80 reset polarity: `$0000` assert, `$0100` release (confirmed by the sound
  code at `$1D9C2`); boot comments corrected.
- `[static]` `movem.l (a6),d0-a6` zeroes registers from cleared RAM at `$FF0000`.
- `[confirmed]` `VerticalInterrupt` dispatches `ram_UpdateFunction` every frame
  (GDB-remote experiment, see `fade.md`).

## Hypotheses

- `[hypothesis]` The `$A10008`/`$A1000C` check detects a soft reset. Test: read those
  ports on cold boot vs. after Reset.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| ROM checksum | Python reimplementation of `sub_7FF98` | `$FE407B8A` | `[confirmed]` check passes. |
| Z80 reset polarity | static boot + sound code | `$0000` assert / `$0100` release | `[confirmed]` |

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `sub_7FF98` | `RomChecksum_Verify` | ROM checksum routine | high |
| `start` | `softReset` | warm-reset entry | medium |
| `defaults` | `bootDefaults` | packed init table | medium |

## Open questions

- [ ] Analyze `GetInputPlayerA/B`, `VerticalInterrupt`, `HorizontalInterrupt`,
  `sub_1652`, and the exception handlers.
- [ ] Confirm the soft-reset behaviour dynamically.
- [ ] Identify the purpose of the 38-byte Z80 stub.

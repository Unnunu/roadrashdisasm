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

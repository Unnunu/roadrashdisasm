# Road Rash — Architecture (scaffold)

This document is the top-level map of the ROM and the source modules. It is a
**work in progress**: fill in details as modules are studied and ported.

Related:

- `AGENTS.md` — build rules, AS syntax requirements, IDA porting workflow.
- `docs/coding-style.md` — identifiers, comments, function headers, RAM/overlay policy.
- `docs/reverse-engineering.md` — evidence rules, BlastEm workflow, experiment format.
- `docs/modules/_template.md` — template for per-module cards.
- `docs/modules/README.md` — index of module cards.

## ROM facts

| Item | Value |
|---|---|
| Platform | Sega Genesis / Mega Drive (68000) |
| ROM size | 786432 bytes (`0xC0000`), declared ROM end `0xBFFFF` |
| md5 | `543b64ccb26c18edc6c98c12b1302dc0` |
| Header title | Road Rash |
| Region | US (`U  ` in header) |
| Entry | `RESET` at `0x000200` |
| Disassembly coverage | first 93808 bytes (`0x16E70`) |

`./build.sh` compares the built image against the same-length **prefix** of
`baserom.md`; it grows as more of the ROM is disassembled.

Generated map file: `build/roadrash.lst` (from `./build.sh`, git-ignored). Use it to
look up addresses and the exact bytes emitted for each source line.

## ROM layout (top level)

| Range | Contents |
|---|---|
| `0x000000`–`0x0000FF` | 68000 exception/interrupt vector table (`vectorTable`). |
| `0x000100`–`0x0001FF` | Sega ROM header (`header`). |
| `0x000200` | `RESET`: hardware init, VDP setup, Z80 load, then jumps into the game. |
| `0x0002C4`–`0x0002EA` | Z80 sound-driver blob (`z80_start` … `z80_end`). |
| `0x0002FA` | `doStart`: main menu / game entry. |
| `0x000366` | `logoEA.asm` include. |
| `0x001164` | `VerticalInterrupt` handler (main.asm, after logoEA include). |
| `0x00145A` | `HorizontalInterrupt` handler. |
| `0x001652` | `sub_1652`. |
| `0x001180` | `fade.asm` include. |
| … | Remaining includes, see module index below. |
| `0x0A4E2` | `race.asm` include (main gameplay). |

Note: `main.asm` is not a single contiguous block. Its code is interleaved with
`include` directives, so the include **order** directly determines the ROM layout.

### Boot / init flow (initial notes)

1. `RESET` (`0x200`) sets up the stack, disables interrupts, initializes VDP and reads
   controller ports.
2. Register defaults are loaded from the `defaults` table (`0x28E`): VDP data/control
   ports, Z80 bus/reset lines, etc.
3. Z80 program is copied/started (`z80_start` … `z80_end`).
4. Control passes to `doStart` (`0x2FA`), which drives the top-level flow
   (logo → intro → menus → race …). Exact flow: **TODO**.

### Interrupts

| Handler | Address | Notes |
|---|---|---|
| `VerticalInterrupt` | `0x1164` | VBlank (IRQ level 6). TODO: describe work done. |
| `HorizontalInterrupt` | `0x145A` | HBlank (IRQ level 4). TODO. |
| Exception handlers | see `main.asm` | Bus/address/illegal/etc.; most write a tag and `stop`. |

## Module index

Addresses are the first byte of each `include` in the assembled ROM. Roles are
tentative until the module card is filled in.

| Address | File | Role (tentative) | Card |
|---|---|---|---|
| `0x000366` | `logoEA.asm` | EA logo, decompression, drawing | TODO |
| `0x001180` | `fade.asm` | Palette fade in/out | TODO |
| `0x001704` | `intro.asm` | Intro sequence | TODO |
| `0x002446` | `menu_password.asm` | Password menu | TODO |
| `0x003400` | `menu_main.asm` | Main menu | TODO |
| `0x004226` | `message.asm` | On-screen messages / button prompts | TODO |
| `0x005760` | `sub_5760.asm` | Not yet identified | TODO |
| `0x0059C4` | `character.asm` | Character screen / rider rendering | TODO |
| `0x005F28` | `race_results.asm` | Post-race results screen | TODO |
| `0x006DC0` | `highscore.asm` | High-score screen | TODO |
| `0x0074AA` | `shop.asm` | Bike shop | TODO |
| `0x008342` | `endlevel.asm` | End-of-level menu | TODO |
| `0x008FB4` | `8FB4.asm` | Not yet identified | TODO |
| `0x0098C2` | `98C2.asm` | Not yet identified | TODO |
| `0x009B9E` | `uncompress.asm` | Decompression routines | TODO |
| `0x009FE4` | `9FE4.asm` | Not yet identified | TODO |
| `0x00A4E2` | `race.asm` | Main gameplay | TODO |
| `0x00D278` | `race_hud.asm` | Race HUD (included by `race.asm`) | TODO |
| `0x00E732` | `road_marking.asm` | Road marking / sprite placement (included by `race.asm`) | TODO |
| `0x016860` | `animation.asm` | Sprite animation (included by `race.asm`) | TODO |

Helpers without code in the image: `hw_const.asm` (constants/macros),
`unknown.asm` (address equates), `ram_const.asm` (RAM equates).

## RAM overview

RAM equates live in `ram_const.asm` (`$FF0000`–`$FFFFFF`). Names are grouped by
subsystem prefixes:

- `Fade_ram_*`, `Intro_ram_*`, `Menu_ram_*`, `MenuPassword_ram_*`,
  `Character_ram_*`, `Race_ram_*`, `RaceResults_ram_*`, `HighScore_ram_*`,
  `Shop_ram_*`, `EndLevel_ram_*`, `RoadMarking_ram_*`, `Animation_ram_*`.
- `ram_XXXXXX` entries are not yet renamed.

TODO: document major RAM structures (player state, race state, sprite tables,
VDP buffers, input state) with sizes and layouts.

## Data / asset notes

- `LogoEA_Image_ElectronicArts.bin` is included by `logoEA.asm` via `binclude`.
- `tools/extract.py` (Python 3 + Pillow) helps extract/decompress graphics from the
  ROM.

## TODO

- Fill in boot/start flow and top-level state machine (`doStart`).
- Describe interrupts (what each does per frame).
- Fill per-module cards, starting with `main.asm` and `race.asm`.
- Document RAM structures and cross-module contracts.

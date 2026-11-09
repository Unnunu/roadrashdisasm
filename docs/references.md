# References

External documentation used to ground `[hardware]` claims. Links are external and may
change; prefer the official/primary documents when in doubt.

## CPU

- **M68000 Programmer's Reference Manual (M68000PRM)** — instruction set, addressing
  modes, exception model, cycle timing.
  <https://www.nxp.com/docs/en/reference-manual/M68000PRM.pdf>

## Genesis / Mega Drive

- **Sega Genesis Software Manual** (Sega) — VDP, I/O, Z80, memory map. Primary source;
  search for the official PDF.
- **Genesis VDP registers** (plutiedev) — practical register/bitfield reference.
  <https://plutiedev.com/vdp-registers>
- **Genesis controllers** (plutiedev) — TH protocol and 3/6-button pads.
  <https://plutiedev.com/controllers>
- **Sega Genesis VDP documentation** (Charles MacDonald) — classic VDP reference;
  search for the document.
- **YM2612 Application Manual** (Yamaha) — FM chip registers/timers. Search for the PDF.

## Tools

- **BlastEm** — emulator with a debugger, GDB remote stub, VDP viewers.
  <https://www.retrodev.com/blastem/>
- **Capstone** — disassembly framework used by `tools/disasm.py`.
  <https://www.capstone-engine.org/>

## Project documents

- `docs/hardware.md` — project-specific hardware notes and game configurations.
- `docs/reverse-engineering.md` — evidence rules and experiment workflow.
- `docs/analysis/` — deep dives per module/routine.

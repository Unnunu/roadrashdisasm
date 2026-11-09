# Glossary

Project-specific and hardware terms used in the documentation.

| Term | Meaning |
|---|---|
| **VDP** | Video Display Processor (Sega 315-5313): planes, sprites, palettes, DMA. |
| **VRAM** | 64 KiB video RAM: tiles, nametables, sprite table, H-scroll table. |
| **CRAM** | 128-byte colour RAM: 4 palettes × 16 colours (`$0BGR`, 9-bit RGB). |
| **VSRAM** | 80-byte vertical-scroll RAM (per column). |
| **SAT** | Sprite Attribute Table in VRAM (80 sprites × 8 bytes). |
| **Plane A/B** | Background layers built from nametables/tiles. |
| **Window** | A third plane overlaying part of the screen. |
| **HInt / VInt** | Horizontal / vertical interrupts (IRQ 4 / 6). |
| **DMA** | VDP direct memory access: 68K→VRAM/CRAM/VSRAM, fill, copy. |
| **TH** | Controller select line used to multiplex button groups. |
| **YM2612** | Yamaha FM sound chip. |
| **PSG** | SN76489 programmable sound generator. |
| **Z80** | Sound CPU; runs the driver blob copied at boot. |
| **Update function** | Per-frame routine stored in `ram_UpdateFunction` (`$FF1A62`) and called from `VerticalInterrupt`. |
| **Fade** | Palette transition driven by `fade.asm` (fade-in/out). |
| **Overlay** | RAM reused by different phases (e.g. `logoEA` vs menu buffers). |
| **Coverage** | Which ROM ranges are real disassembly vs raw bridged bytes. |
| **Round-trip** | ROM → generated AS → assemble → compare bytes. |
| **Project mode** | `tools/disasm.py` output with symbols resolved for the repository. |
| **Round-trip mode** | `tools/disasm.py` output with raw external references, used for validation. |

# AGENTS.md

Guidance for AI agents working in this repository.

## Project

Matching disassembly of **Road Rash** (Sega Genesis, 1991, US region).

- Goal: the assembly sources must assemble **byte-for-byte** into the original ROM.
- Reference ROM: `baserom.md`, the **full ROM**, **786432 bytes** (`0xC0000`),
  md5 `543b64ccb26c18edc6c98c12b1302dc0`.
- The disassembly currently covers only the **first 93808 bytes** (`0x16E70`) of the
  ROM. The build emits that prefix, which must be byte-identical to the start of
  `baserom.md`. As more of the ROM is disassembled, the built image grows.
- `baserom.md` is local-only (git-ignored). Ask the user for it if missing.
- All documentation and source comments in this project are **English**.

## Golden rule

`./build.sh` must print `Matched OK: ...` after every change (currently
`Matched OK: 93808 bytes of 786432 bytes`). The built image must be byte-identical to
the matching prefix of `baserom.md`. A change that breaks byte-exactness is not done,
even if it assembles without errors.

## Build

There is a **single ROM file**: `baserom.md` (the full 786432-byte ROM).

```sh
# one-time: put the reference ROM in place
#   baserom.md = full Road Rash ROM (786432 bytes)

# build + verify
./build.sh
```

`build.sh` runs:

```sh
mkdir -p build
tools/asl -cpu 68000 -L -olist build/roadrash.lst -o build/roadrash.p main.asm
tools/p2bin build/roadrash.p build/roadrash.bin
cmp -n <built-size> build/roadrash.bin baserom.md
```

Because only a prefix of the ROM is reconstructed so far, the check compares the
built image against the same-length prefix of `baserom.md`. On success the temporary
`build/roadrash.bin` is removed; on mismatch it is kept and the first differing byte
is reported. `baserom.md` is the only ROM file and is git-ignored; `build/` and
`analysis/` are git-ignored working directories.

## Repository layout

| Path | Contents |
|------|----------|
| `main.asm` | Entry point: 68000 vector table, ROM header, `RESET`/`start`, register defaults, Z80 sound-driver blob, `doStart`, input routines, interrupt/exception handlers, then `include`s of all modules. |
| `hw_const.asm` | VDP/HV constants and VDP access macros. |
| `unknown.asm` | Equates for not-yet-identified addresses (ROM pointers, audio entries). |
| `ram_const.asm` | RAM address equates (`*_ram_*`, `ram_*`). |
| `logoEA.asm` | Electronic Arts logo / decompression / drawing. |
| `fade.asm` | Palette fade in/out. |
| `intro.asm` | Intro sequence. |
| `menu_password.asm` | Password menu. |
| `menu_main.asm` | Main menu. |
| `message.asm` | On-screen messages / button prompts. |
| `sub_5760.asm` | Not yet identified routine block. |
| `character.asm` | Character screen / rider rendering. |
| `race_results.asm` | Post-race results screen. |
| `highscore.asm` | High-score screen. |
| `shop.asm` | Bike shop. |
| `endlevel.asm` | End-of-level menu. |
| `8FB4.asm`, `98C2.asm`, `9FE4.asm` | Not yet identified routine blocks. |
| `uncompress.asm` | Decompression routines. |
| `race.asm` | Main gameplay (largest file); includes `race_hud.asm`, `road_marking.asm`, `animation.asm`. |
| `race_hud.asm` | Race HUD. |
| `road_marking.asm` | Road marking / sprite placement. |
| `animation.asm` | Sprite animation. |
| `tools/asl`, `tools/p2bin` | Assembler (Macro Assembler AS) and binary converter. Do not modify. |
| `tools/disasm.py` | Capstone-based ROM range -> project AS source generator. |
| `tools/roundtrip.py` | Round-trip verifier for `disasm.py` (ROM -> AS -> assemble -> compare). |
| `tools/extract.py` | Asset extraction helper (Python 3 + Pillow). |
| `docs/` | Reverse-engineering documentation (see below). |
| `build/` | Generated build artifacts (git-ignored). |
| `analysis/` | Local RE working data: RAM dumps, address logs, generated disassembly, notes (git-ignored). |

Include order matters: it determines code layout in the ROM. Do not reorder includes.

## Toolchain notes

- `tools/asl` is Macro Assembler AS (`AS V1.42 Beta`), **not** GNU `as` and **not**
  ASM68K/clownassembler. Its syntax and defaults differ from both.
- Target is plain **68000**; pass `-cpu 68000` (required).
- `tools/p2bin` converts the `.p` object to a raw binary.

## AS syntax rules (hard requirements for byte-exactness)

These rules were derived from making the original ASM68K sources assemble identically
under AS. Breaking them almost always changes the emitted bytes.

| Do NOT write | Write instead | Why |
|---|---|---|
| `@loop` | `.loop` | AS local labels use a leading dot; `@` is invalid. |
| `jsr Foo` | `jsr (Foo).l` | ASM68K encoded bare absolute refs as abs.long; AS picks abs.short when it fits. |
| `lea Foo,a0` | `lea (Foo).l,a0` | Same. |
| `move.w Foo,d0` | `move.w (Foo).l,d0` | Same for any absolute EA (move/movea/cmp/tst/add/sub/andi/...). |
| `beq Label` (no size) | `beq.w Label` | ASM68K used the 16-bit displacement form for bare branches; AS uses 8-bit. |
| `move.w d0,0(a0)` | `move.w d0,0.w(a0)` | AS collapses a zero displacement to `(a0)`, dropping the extension word. |
| `incbin "file"` | `binclude "file"` | AS spelling. |
| `macro` with `\1`, `\2` | named parameters, e.g. `addr,dest` | Positional macro arguments do not work in AS. Avoid underscores in parameter names. |
| comment ending in `\` | remove or reword the trailing backslash | AS treats a trailing backslash as line continuation and swallows the next line. |

Also:

- `supmode on` and `padding off` are set at the top of `main.asm`:
  - `padding off` stops AS from inserting alignment bytes before instructions/data at
    odd addresses (ASM68K never did this for 68000).
  - `supmode on` declares supervisor mode and silences privileged-instruction warnings.
- Numeric/absolute expressions may stay bare only when they are immediates (`#...`),
  registers, or already explicitly sized. Everything else that forms an absolute EA
  should be `(...).l`.
- AS is case-insensitive for symbols by default. Follow the existing spelling of each
  symbol; do not introduce case-only duplicates.

## ROM → AS source (`tools/disasm.py`)

New disassembly is produced by our own capstone-based tool; no external
disassembler is required.

```sh
# project-style source for a code range
python3 tools/disasm.py 0x1180 0x13c0

# self-contained round-trip source (raw external refs + org)
python3 tools/disasm.py 0x1180 0x13c0 --mode roundtrip --org -o /tmp/range.asm

# validate a range end-to-end (ROM -> AS -> assemble -> compare)
python3 tools/roundtrip.py 0x1180 0x13c0
```

The tool resolves known symbols from `build/roadrash.lst` and the equates in
`ram_const.asm` / `unknown.asm` / `hw_const.asm`, creates `sub_XXXX` / `loc_XXXX`
labels for internal branch/call targets, and preserves the original encoding sizes
(`.s`/`.w` branches, abs.w/abs.l, `0.w(aN)`, ...).

Workflow for adding a region:

1. **Find the boundaries.** Use `tools/disasm.py`/`objdump` and the build listing to
   separate code from data. Pass data ranges with `--data START-END`.
2. **Round-trip first.** Run `python3 tools/roundtrip.py START END` (plus `--data`).
   It must print `Round-trip OK` before the code is trusted.
3. **Place it correctly.** Append/insert into the right `.asm` file, preserving include
   order and address layout. Do not reorder existing code.
4. **Assemble and verify.** `./build.sh` must report `Matched OK`.
5. **Document** the module in `docs/modules/<file>.md` and update the module map.

Rules for generated code:

- Never invent or "improve" bytes. The target is the ROM, not clean-looking code.
- Keep every referenced label consistent; if a label moves, update all users.
- Do not reformat unrelated code or rename existing symbols as part of a port.
- `--symbolize-immediates` is opt-in and can mis-name constants that coincide with
  addresses; review its output before trusting it.
- The generated code still follows the AS syntax rules above.

## Naming policy

- Preserve auto-generated placeholders: `sub_XXXX`, `loc_XXXX`, `byte_XXXX`,
  `word_XXXX`, `off_XXXX`, `unk_XXXX`, etc.
- Renaming to meaningful names is a **separate, explicit task**. Only rename when the
  user asks for it (e.g. "study this file and then rename").
- When a rename is requested, do it as its own change and re-verify the build.

## In-code documentation

Read and follow `docs/coding-style.md` when editing sources. In short:

- Identifiers carry the meaning; comments explain *why*, not the mnemonic.
- Every function gets a `; *****` header with mandatory
  Purpose / In / Out / Clobbers / Notes fields, closed by `; End of function <Name>`.
- RAM equates normally live in `ram_const.asm`; module-local maps are allowed only for
  documented overlay/scratch regions (see the `logoEA.asm` exception in the guide).
- Do not introduce legacy cross-reference artifacts (`CODE XREF`, `DATA XREF`,
  `↑`/`↓` continuations); they were removed from the tree.
- Apply the guide incrementally when touching a file; do not mass-reformat.
- After any rename, re-run `./build.sh` and require `Matched OK`.

## Reverse engineering

Read and follow `docs/reverse-engineering.md` when analyzing code behavior.

- **No speculation.** Every claim must have evidence; tag it
  `[static]`, `[dynamic]`, `[confirmed]`, `[hypothesis]`, or `[refuted]`.
- Unverified behavior stays `TODO`; do not encode guesses in names or confident comments.
- Dynamic checks run in BlastEm: the user can use the native console, and the agent can
  drive the GDB remote stub headless (see `docs/reverse-engineering.md`). Prefer a
  small, targeted experiment over guessing.
- Use `analysis/` for RAM dumps (`analysis/dumps/`), generated disassembly
  (`analysis/disasm/`) and logs; it is git-ignored.
- Record verified facts, hypotheses, and experiments in the module card.

## Documentation

- `docs/architecture.md` — ROM map, boot/interrupt flow, module index, RAM overview.
- `docs/coding-style.md` — identifiers, comments, function headers, RAM/overlay policy.
- `docs/reverse-engineering.md` — evidence rules, BlastEm workflow, experiment format.
- `docs/modules/<file>.md` — one card per module, based on
  `docs/modules/_template.md`. Fields: role, control flow, RAM/ROM & structures,
  external calls/API, hacks/bugs, TODO.
- After integrating a newly disassembled region, update the matching module card.

## Known warnings (expected)

The build prints **36** `bit number will be truncated` warnings. They are expected:

- On the 68000, bit operations on memory are byte-sized and the CPU uses the bit number
  modulo 8. The original ROM really stores `0x0F` in the bit-number field for those
  instructions (e.g. `btst #$F,$A(a0)`).
- Changing `#$F` to `#$7` would remove the warning but change the emitted bytes and
  break the match. Do not do that.
- AS has no per-warning switch for this; a global `-w` would hide all warnings, which is
  intentionally not used.

The build must report `0 errors`. The only accepted warning class is the one above.

## Do not touch

- `baserom.md` (the single reference ROM; git-ignored).
- `build/` (generated artifacts) and `analysis/` (local RE working data).
- `tools/asl`, `tools/p2bin` (prebuilt toolchain).
- `LogoEA_Image_ElectronicArts.bin` (asset used by `binclude`).

## Git / commit policy

- Verify `./build.sh` → `Matched OK` before committing.
- Commit per meaningful milestone; keep generated/ignored files out of the index.
- Match the existing style: short, lowercase messages, e.g. `race WIP`,
  `matched logoEA`, `assemble with AS, byte-exact match`.
- Inspect `git status` / `git diff` before committing. Do not amend, force-push, or
  rewrite history unless the user explicitly asks.

## Agent checklist

- [ ] Change is limited to the requested scope.
- [ ] AS syntax rules above are respected.
- [ ] `./build.sh` reports `0 errors` and `Matched OK: 93808 bytes`.
- [ ] Module documentation updated when a module was studied/ported.
- [ ] No generated or ignored files staged.

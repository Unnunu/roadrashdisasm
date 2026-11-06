# Reverse Engineering Guide

How we determine what the code does and why. The guiding rule is simple:

> **No speculation.** Every claim must be backed by evidence. If something is not
> verified, it is marked `TODO` / `[hypothesis]` and never encoded in names or
> confident comments.

Related: `AGENTS.md`, `docs/coding-style.md`, `docs/architecture.md`,
`docs/modules/_template.md`.

## 1. Evidence tags

Every factual statement in analysis notes (and optionally in code comments) carries a
tag:

| Tag | Meaning |
|---|---|
| `[static]` | Follows from the code/data: control flow, constants, tables, call sites, ROM bytes. |
| `[dynamic]` | Observed in BlastEm: registers, RAM, VRAM/CRAM/VSRAM, sprite list, plane state. |
| `[confirmed]` | Static and dynamic evidence agree. |
| `[hypothesis]` | Plausible but unverified. Keep `; TODO: verify` in code; do not rename based on it. |
| `[refuted]` | Tested and disproved. Record it so it is not revisited. |

Only `[confirmed]` facts may drive identifier renames or definitive code comments.

## 2. Workflow

1. **Read the code.** Build a control-flow/data-flow picture for the region.
2. **Write explicit hypotheses.** State both "what it does" and "why".
3. **Design a minimal experiment** that distinguishes the hypotheses (see section 5).
4. **Ask the user to run it in BlastEm** and report the requested values.
5. **Record the result** with an evidence tag in the module card.
6. **Update code comments/names only for confirmed facts.**
7. Keep `docs/modules/<file>.md` in sync.

## 3. BlastEm console debugger

The ROM is the full `baserom.md`. The user runs it in BlastEm and reports back.

Currently available console commands (from BlastEm's `?` help):

- `b ADDRESS` — execution breakpoint; `d BREAKPOINT` — delete.
- `co BREAKPOINT` — run a list of debugger commands on every hit.
- `a ADDRESS`, `n`, `o`, `s` — advance / step over / step out-of-loop / step into.
- `se REG|ADDRESS VALUE` — set a register or memory value.
- `sr` — soft reset; `c` — continue; `q` — quit.
- `bt` — print a backtrace (callers).
- `p[/(x|X|d|c)] VALUE` — print a register or memory location.
- `di[/(x|X|d|c)] VALUE` — print a register/memory location on every breakpoint hit.
- `vs` — VDP sprite list; `vr` — VDP register info.
- `yc`, `yt` — YM-2612 channel/timer info; `zb`, `zp` — Z80 breakpoints/print.

**Important limitations of the console debugger:**

- There are **no RAM read/write watchpoints**, only execution breakpoints.
- There is **no memory dump-to-file** command.

Consequences:

- To find possible writers/readers of a RAM variable, enumerate references **statically**
  (grep the address/symbol in the sources and scan the ROM for pointer values), then use
  execution breakpoints on those PCs and `bt` to see the call path.
- To capture state at a hit, use `p` / `di` / `co` and have the user paste the output.
- BlastEm also has GUI viewers (VRAM/CRAM/plane/sprite views); use them for visual checks.

## 4. Static cross-reference technique

Because the full disassembly is in this repo, most references are discoverable without
the emulator:

- `grep -rn "ram_FF1A66" *.asm` — all source-level uses of a RAM address.
- `grep -rn "(Subsystem_ram_Field)" *.asm` — all uses of a named variable.
- Search the ROM for a 32-bit pointer value to spot data tables, e.g.:

  ```sh
  python3 - <<'PY'
  rom = open('baserom.md','rb').read()
  addr = 0x1242                      # e.g. Fade_GameTick
  pat = addr.to_bytes(4,'big')
  i = rom.find(pat)
  while i >= 0:
      print(hex(i)); i = rom.find(pat, i+1)
  PY
  ```

  Treat each hit as a lead, then verify the surrounding bytes are really a pointer
  table (disassemble around it), not coincidental data.

## 5. Experiment request format

Every emulator request should be small and unambiguous:

```
Goal:        what we are trying to confirm/refute
Setup:       ROM, scene/state, inputs, or savestate
Breakpoint:  address/label, type (exec; conditions if supported)
Capture:     PC, D0-D7, A0-A7, SR, stack words, RAM $FFxxxx-$FFyyyy,
             VRAM/CRAM/VSRAM/planes (only if needed)
Decision:    if X -> hypothesis A; if Y -> hypothesis B
```

Ask for the minimum needed to decide between hypotheses. Batch related checks in one run
when possible.

## 6. Working directories

`analysis/` is git-ignored and holds local RE data:

- `analysis/ida/` — IDA listing exports (text), one file per module/region when possible.
- `analysis/states/` — BlastEm savestates (`*.state`), named by scene/experiment.
- `analysis/notes/` — optional scratch notes (durable facts still go to module cards).

Tell the user exactly what to export/save and where to put it.

### IDA listings

When requesting an IDA listing, ask for a text export of a specific function or address
range with addresses, bytes, labels, operands, and data. The user places it under
`analysis/ida/`; the agent normalizes it into AS syntax (see the IDA→AS workflow in
`AGENTS.md`).

## 7. Recording evidence

In the module card (`docs/modules/<file>.md`):

- **Verified facts** — bullet list with tags and the evidence
  (e.g. `[confirmed] Fade_ram_Timer is reloaded with 3 every 4th frame
  (static: fade.asm; dynamic: BlastEm breakpoint at $1242)`).
- **Hypotheses** — untested ideas, each with the experiment that would settle it.
- **Experiments** — goal / setup / breakpoint / observed result.
- **Open questions** — what is still unknown.

Never let a hypothesis masquerade as a fact.

## 8. Naming and comments

- Rename identifiers only after `[confirmed]` evidence, and as a separate explicit task.
- Comments in code state confirmed behavior or explicitly say `TODO`.
- Hardware/magic numbers should be explained from documentation or observation, not guessed.

## 9. Calibration example: `fade.asm`

Current static evidence:

- Labels: `Fade_InitFadeOut $1180`, `Fade_InitFadeIn $11C0`,
  `Fade_GameTickWithInit $1200`, `Fade_GameTick $1242`,
  `FadeWithFunction_GameTick $12F8`.
- RAM: `Fade_ram_Timer $FF0300`, `Fade_ram_UpdateFunction $FF0302`,
  `Fade_ram_CurrentPalette $FF0306`, `Fade_ram_TargetPalette $FF0386`.
- `[static]` `Fade_InitFadeOut` and `Fade_InitFadeIn` have **no references** in the
  sources, and their addresses appear **0 times** as 4-byte values in `baserom.md`.
  Hypothesis: dead code (needs dynamic confirmation).
- `[static]` `Fade_GameTickWithInit`, `Fade_GameTick`, and `FadeWithFunction_GameTick`
  appear as 4-byte values around `$7E6xx`, likely an update-function pointer table
  (verify by disassembling that region).

Planned experiment (to be run by the user):

```
b 1200      ; Fade_GameTickWithInit
b 1242      ; Fade_GameTick
c
```

On a hit, report:

```
bt
p pc
p d0
p a0
p/(x) $FF0300   ; timer
p/(x) $FF0302   ; update-function pointer
vr
```

Goals: confirm the timer sequence 3→2→1→0 and its 4-frame cadence, confirm whether the
init functions ever run, and save a savestate at the first fade for repeatable tests.

## 10. Caveats

- Absence of a reference in the disassembly is evidence, not proof, of dead code
  (computed jumps/pointers may exist). Mark it `[hypothesis]` until tested.
- A coincidental value match in ROM is not a pointer until the surrounding data is
  verified.
- When BlastEm behavior and the static reading disagree, record both; do not paper over it.

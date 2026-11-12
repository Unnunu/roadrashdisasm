# Line-by-line analysis guide

How to perform a **line-by-line pass** over one assembly file: understand every
instruction, comment the non-obvious ones, record semantic gaps, and audit identifier
quality. This is a separate activity from general reverse engineering.

See also: `docs/coding-style.md` (in-code style), `docs/reverse-engineering.md`
(evidence tags, experiments), `docs/analysis/_template.md` (deep-dive structure),
`docs/modules/_template.md` (module cards), `docs/analysis/identifiers.md`,
`docs/analysis/unknowns.md`.

## 1. Scope: two different activities

| Activity | Question | Output |
|---|---|---|
| **General analysis** | Who calls this? Who reads/writes each variable? Signatures, sizes, ownership, data formats, cross-module wiring. | Module card, `docs/ram-map.md`, `docs/callgraph.md`, facts in `docs/analysis/<file>.md`. |
| **Line-by-line analysis** | Is every assembly line understood? Does every non-obvious line or logical group carry a correct comment? | Inline comments in the `.asm` (comment-only changes), a short pass report, identifier and unknown entries. |

A line-by-line pass is **not** a call-graph pass, not a rename pass, and not a
refactor. It changes comments (and analysis documents), never instruction bytes.

Identifier quality is audited as part of the pass because every use is visible; the
result is a durable registry that informs later rename decisions.

## 2. Preconditions

- `./build.sh` reports `Matched OK` before you start.
- The ROM range is known from `build/roadrash.lst`.
- The matching module card and `docs/analysis/<file>.md` have been read.
- RAM names are resolved through `src/core/ram_const.asm` (and `unknown.asm` /
  `hw_const.asm` for unresolved placeholders).
- The file is in a single, well-defined task (`tasks/<name>.md`); one file per session.

## 3. Inputs

- The `.asm` source under analysis.
- `build/roadrash.lst` — addresses and emitted bytes for every line.
- `docs/hardware.md` — VDP/DMA/controller/Z80 semantics.
- `docs/ram-map.md` — RAM regions and owners.
- `docs/callgraph.md` — callers/callees (for contracts, not for renaming).
- The matching `docs/analysis/<file>.md` and `docs/modules/<file>.md`.
- `src/core/ram_const.asm`, `src/core/unknown.asm`, `src/core/hw_const.asm`.

## 4. Pass order

Work one function at a time, top to bottom:

1. **File header** — verify ROM range, status, purpose, flow, API, data/assets, and
   the VRAM/memory map where relevant.
2. **Function banner** — Purpose / In / Out / Clobbers / Notes, closed by
   `; End of function <Name>`.
3. **Logical blocks** — a block comment before each chunk: intent, invariant, why.
4. **Individual instructions** — inline comments for magic numbers, hardware accesses,
   non-obvious data flow, and quirks.
5. **Data and tables** — a header before each table (element size, count, meaning),
   and per-entry annotations where the semantics are known.

Do not skip a function because it already has comments: verify that each comment still
matches the code and that no line is silently unexplained.

## 5. What must be commented

- **Every magic number**: VDP register writes, tile base/palette/priority bits, plane
  and table addresses, blob offsets, structure field offsets, fixed-point constants.
- **Control-flow quirks**: redundant branches, edge/level-triggered input, off-by-one
  loop arithmetic, sentinels, terminator values, fall-through dependencies.
- **Loop invariants and termination**: what stays true across iterations, what ends the
  loop, and whether the bound is inclusive (`dbf`) or exclusive.
- **Fixed-point and numeric conventions**: 16.16 format, fractional steps, rounding,
  clamping, signed/unsigned assumptions.
- **Data packages**: blob layout (header, counts, payload, palette, nametable) and
  which fields are consumed by which helper.
- **Persistent state**: RAM/VDP state that survives across frames or screens.
- **Dead code**: mark it `; dead: <evidence>` rather than deleting it (byte-exactness).
- **Unexplained behavior**: use `@UNKNOWN(<id>)` (section 7), never a confident guess.

Explain *why*, not *what*. Do not restate the mnemonic (`; add 1 to d0`).

## 6. What not to do

- Do not rename identifiers during a line-by-line pass (renames are a separate task;
  record verdicts in `docs/analysis/identifiers.md`).
- Do not change instruction bytes, encoding sizes, addressing modes, include order, or
  label names.
- Do not reformat or mass-edit unrelated lines.
- Do not invent behavior to fill a gap; use `@UNKNOWN` / `TODO`.
- Do not "fix" odd but intentional code (dead pointer loads, redundant branches) —
  document it.

## 7. Markers

Three distinct markers must not be mixed:

| Marker | Meaning | When to use |
|---|---|---|
| `TODO: <action>` | A **known action** (rename, verify, add test). | You know what to do next. |
| `@UNKNOWN(<id>): ...` | A **semantic gap** — what this is/does is not understood; the comment is provisional. | You must come back and improve the comment. |
| `[static]` / `[dynamic]` / `[hardware]` / `[design]` / `[confirmed]` / `[hypothesis]` / `[refuted]` | **Evidence tags** for a claim. | Rating confidence of a statement. |

### 7.1 `@UNKNOWN` syntax

Place it on the exact line or block, in code or in an analysis document:

```asm
                jsr     (sub_1234).l ; @UNKNOWN(U-0007): role of d0 on return | guess: button mask | next: breakpoint at $1234, log d0
```

- `U-0007` — global sequential ID, never reused.
- `<what>` — what exactly is unknown (required).
- `guess:` — current best guess (optional).
- `next:` — the minimal experiment or step that would close it (required).
- A function-level unknown lives in the banner `Notes:` field; a line-level one lives
  on the line.

### 7.2 Unknown registry

Every live marker has an entry in `docs/analysis/unknowns.md`:

| ID | Location | Symbol / line | What is unknown | Current best guess | Next step | Status | Evidence |
|---|---|---|---|---|---|---|---|
| `U-0007` | `src/screens/x.asm:342` | `sub_1234` return `d0` | role of `d0` | maybe a button mask | breakpoint `$1234`, log `d0` | open | `[hypothesis]` |

Status lifecycle: `open` → `hypothesis` → `confirmed` / `refuted` / `wontfix`.

When an unknown is resolved:

1. Replace the marker with the final comment.
2. Set the registry status and add the evidence tag.
3. Keep the entry as history (do not reuse the ID).

Find live gaps with `grep -rn "@UNKNOWN" src/`.

### 7.3 Legacy markers

Existing `; unknown:` / vague `; TODO` comments are migrated to `@UNKNOWN` only when the
file is touched. No mass edits.

## 8. Identifier audit

While walking the file, record every identifier in `docs/analysis/identifiers.md` and
rate how well the current name matches its observed use in this file and elsewhere.

Per-file output is a short summary in `docs/analysis/<file>.md`; the global registry is
the source of truth. Rating rubric:

| Quality | Meaning |
|---|---|
| `good` | The name matches all observed uses in all files. |
| `narrow` | Correct but narrower than the real role (safe, candidate for refinement). |
| `misleading` | The name implies semantics contradicted by some uses. |
| `placeholder` | `ram_XXXXXX`, `sub_`, `loc_`, `unk_`, `word_`, `byte_`, `off_`. |
| `wrong/unknown` | Contradicts the evidence or cannot be determined. |

Rename verdict column: `keep`, `rename-later`, or `blocked-unknown` (the last must
reference an `@UNKNOWN` ID).

Rules:

- Record cross-file conflicts explicitly: one name that means different things in
  different files is `misleading` until proven otherwise.
- Only `[confirmed]` evidence may justify a rename.
- Renaming remains a separate, explicit task; this pass only records verdicts.
- Canonical example: `Intro_InitPlayerA` is a valid name for its local role but is also
  called from `Menu_Init`, so its prefix is narrower than its real use (`narrow`).

## 9. Output and artifacts

- Comment-only edits in the `.asm`.
- Updated annotated listing / algorithm / data sections in `docs/analysis/<file>.md`.
- New or updated rows in `docs/analysis/identifiers.md` and
  `docs/analysis/unknowns.md`.
- Updated coverage matrix in the module card.
- `STATE.md` handoff: verified facts, open IDs, files touched, next step.

Do not touch unrelated lines or other modules.

## 10. Verification

1. `./build.sh` reports `Matched OK`.
2. `git diff` contains only comment and documentation changes (no instruction bytes).
3. Every touched function has a banner with all mandatory fields.
4. Every new unknown has an `@UNKNOWN` marker and a registry row.
5. Every identifier touched has an audit row.

## 11. Calibration example

`src/screens/intro.asm` + `docs/analysis/intro.md` show the expected quality:

- File header with ROM range, status, purpose, flow, API, assets, and a derived VRAM map.
- Function banners with Purpose/In/Out/Clobbers/Notes and `; End of function <Name>`.
- Blob package layout documented before decompression (`+$0000` marker, `+$0002` count,
  `+$0004` tiles, palette/nametable offsets).
- Magic numbers decoded (VDP register bits, tile base words, palette lines, fixed-point
  fractions such as `$2000` = 0.125).
- Dead code marked with evidence (`adda.w #(20*5),a0` reloaded before use).
- Table terminators and loop bounds explained (`$FFFFFFFF`, `dbf`, predecrement).
- Uncertain visual behavior left as an explicit TODO rather than a confident claim.

## 12. Anti-patterns

- Commenting every line with a mnemonic restatement.
- Turning a comment-only task into a rename/refactor.
- Writing confident behavior for unverified code.
- Leaving a semantic gap with no `@UNKNOWN` marker.
- Duplicating registry rows instead of updating the existing entry.
- Editing unrelated files "while here".

## 13. Definition of done / checklist

- [ ] `./build.sh` → `Matched OK`.
- [ ] Diff is comment/documentation only.
- [ ] Every function has a complete banner.
- [ ] Magic numbers, hardware accesses, and quirks are explained.
- [ ] Data/table layouts are documented.
- [ ] Dead code is marked with evidence.
- [ ] Every semantic gap has `@UNKNOWN(<id>)` and a row in `unknowns.md`.
- [ ] Every identifier has a row in `identifiers.md` with quality and verdict.
- [ ] No identifiers renamed.
- [ ] `docs/analysis/<file>.md`, module card coverage, and `STATE.md` updated.

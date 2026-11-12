# Line-by-line build checklist

Compact procedure for a **build** session that comments one assembly file (and, when the
task explicitly allows it, applies justified renames/formatting). Full rules, edge
cases, and calibration: `docs/line-by-line-analysis.md`.

## 0. Context and budget

- Read `STATE.md`, the task file, the target source, and its analysis/module card.
- Read large registries by lookup, not whole-file: `grep -n '<symbol>'` in
  `docs/analysis/identifiers.md`, `docs/callgraph.md`, `docs/ram-map.md`.
- Request budget: ~30 tool calls. Batch independent reads/greps/checks.
- Bulk edit plan: one script (or one `Write`) per phase; store maps in
  `/tmp/opencode/<task>.json` and do not reprint them.

## 1. Preconditions

- `./build.sh` reports `Matched OK` before starting.
- Confirm ROM range and function/table addresses from `build/roadrash.lst`.

## 2. Pass order

1. **File header** — ROM range, status, purpose, API, data/assets.
2. **Function banner** — Purpose / In / Out / Clobbers / Notes, then
   `; End of function <Name>`.
3. **Block comments** — intent and invariant before each logical chunk.
4. **Inline comments** — magic numbers, hardware bits, data flow, quirks.
5. **Data/tables** — element size, count, layout, terminator, consumer.

## 3. What must be commented

- Magic numbers: VDP bits, tile bases/palettes, plane/window addresses, offsets,
  fixed-point constants.
- Control flow: redundant branches, sentinels, inclusive/exclusive loop bounds,
  fall-through, dead code (mark `; dead: <evidence>`).
- Data: record layout, field offsets, entry count, terminators, consumers.
- Persistent state: RAM/VDP state that survives the routine or frame.

Do not restate the mnemonic. Explain *why* (intent, invariant, hardware effect).

## 4. Markers and registries

- Known next action: `; TODO: <action>`.
- Semantic gap: `; @UNKNOWN(U-xxxx): <what> | guess: <...> | next: <...>` and a row in
  `docs/analysis/unknowns.md`.
- Claims use evidence tags: `[static]`, `[dynamic]`, `[hardware]`, `[confirmed]`,
  `[hypothesis]`.
- Every touched identifier gets a row in `docs/analysis/identifiers.md`; only
  `[confirmed]` evidence justifies a rename. Renames require an explicit task.

## 5. Renames / bulk formatting (only if the task authorizes it)

- Keep a single old→new map; apply it once to all files.
- Verify with `./build.sh` and a comment-stripped instruction diff; for data-table
  reformatting, compare the emitted byte slice as well.
- Update cross-file references and the identifier registry.

## 6. Verification

- `./build.sh` → `Matched OK`.
- `python3 tools/assets.py check` when assets/tables are involved.
- `git diff --check` → clean.
- Source diff is comments/formatting/authorized renames only.
- `docs/analysis/<file>.md`, module card coverage, `STATE.md`, and the task file updated.

## 7. Close

- Fill the task `Result` and `Handoff`.
- Update `STATE.md` with verified facts, open IDs, files touched, next step.
- Do not commit unless the user explicitly asks.

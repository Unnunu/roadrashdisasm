# AGENTS.md

Project: byte-exact matching disassembly of the target Sega Genesis ROM.

## Communication

- Talk to the user in **Russian**.
- Keep code, comments, and documentation in **English** (project convention).

## Commands

```sh
./build.sh                       # assemble + compare; verdict = last line ("Matched OK")
python3 tools/assets.py check    # verify split asset slices against baserom.md
python3 tools/assets.py all      # split + render local previews (optional)
```

`./build.sh` prints the full two-pass assembler log. The build result is the exit code
and the final line (`Matched OK` or `No matching`); the warnings above it are expected.
To see only the verdict: `./build.sh 2>&1 | tail -n 3`.

## Tool / request efficiency

The API bills every assistant message, including tool-call arguments. Keep sessions
cheap:

- **Batch independent calls** (reads, greps, git/build checks) in one message.
- **Bulk edits:** one script + one mapping file (e.g. `/tmp/opencode/<task>.py` and
  `<task>.json`), run once. Never retype the mapping in later heredocs.
- **Pervasive changes:** prefer one `Write` of the final file content. For small edits,
  use `Edit` with minimal unique anchors, not whole functions.
- **Read once:** read a file once, then use `grep -n` / `sed -n` for later lookups.
- **Two builds per task:** one baseline and one final combined with
  `python3 tools/assets.py check` and `git diff --check`.
- **Request budget:** aim for ~30 tool calls per file pass. If exceeded, stop and
  re-plan in the task file instead of continuing with many small edits.
- **Repeated patterns:** explain once, then reference the first explanation.
- **Large registries** (`identifiers.md`, `callgraph.md`, `ram-map.md`): search the
  relevant row/section; do not read the whole file.
- For a line-by-line pass, use the compact `docs/line-by-line-checklist.md` by default;
  open `docs/line-by-line-analysis.md` only when a rule or edge case is unclear.

## Session workflow

- One session = one task.
- Fix the session type at the start: **plan** or **build**. Do not change it inside
  a long session.
- A **plan** session is read-only. Finish by writing the plan to `tasks/<name>.md`
  and closing the session.
- A **build** session starts by reading `STATE.md` and its `tasks/<name>.md`, then
  executes that task only.
- Do not switch agent/mode/model/working directory in the middle of a session after
  roughly 50k tokens. Start a new session instead.
- Put large dumps, logs, disassembly, and previews in files. In chat report only the
  path, size, hash, and a few first/last lines.
- Before closing a session, update `STATE.md` with verified facts, open questions,
  files touched, and the next step.
- Do not commit unless the user explicitly asks.

## Documentation routing

Before opening `docs/`, read `docs/INDEX.md` and open only the relevant file.

| Topic | File |
|---|---|
| ROM layout, boot flow, module index | `docs/architecture.md` |
| RAM regions, fields, ownership | `docs/ram-map.md` |
| VDP, DMA, controllers, Z80 | `docs/hardware.md` |
| Source identifiers, comments, headers | `docs/coding-style.md` |
| Compact line-by-line build checklist | `docs/line-by-line-checklist.md` |
| Full line-by-line rules, markers, calibration | `docs/line-by-line-analysis.md` |
| Identifier quality map and rename verdicts (grep rows) | `docs/analysis/identifiers.md` |
| Live semantic gaps (`@UNKNOWN`) | `docs/analysis/unknowns.md` |
| Evidence rules, BlastEm, experiments | `docs/reverse-engineering.md` |
| Function index and call graph | `docs/callgraph.md` |
| Module cards | `docs/modules/README.md` |
| Detailed per-module analysis | `docs/analysis/` |
| Current analysis priorities and status | `docs/analysis/coverage.md` |
| Asset extraction and verification | `docs/analysis/assets.md`, `docs/analysis/asset_verification.md` |
| Screen flow and VDP layouts | `docs/analysis/screens_flow.md` |
| Audio/Z80 (deferred) | `docs/analysis/audio.md` |
| Terms and external references | `docs/glossary.md`, `docs/references.md` |

## Code conventions

- Keep the source byte-exact. `./build.sh` must report `Matched OK` after changes.
- Preserve existing assembler syntax, encoding sizes, include order, and labels.
  Do not reformat or rename unrelated code as part of another task.
- Follow the project's existing English documentation/comments style.
- Keep generated files and local analysis data out of git unless explicitly requested.
- If a line's purpose is unknown, use `; @UNKNOWN(U-xxxx): ...` with the evidence tag,
  a guess, and the next experiment, and add a row to `docs/analysis/unknowns.md` rather
  than inventing behavior. See `docs/line-by-line-analysis.md` §7.

# AGENTS.md

Project: byte-exact matching disassembly of the target Sega Genesis ROM.

## Commands

```sh
./build.sh                       # assemble, compare with baserom.md, report Matched OK
python3 tools/assets.py check    # verify split asset slices against baserom.md
python3 tools/assets.py all      # split + render local previews (optional)
```

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
- If a line's purpose is unknown, mark it `TODO` with the evidence tag and next
  experiment rather than inventing behavior.

# Identifier map

Durable, cross-file assessment of how well each identifier's name matches its observed
uses. It exists so later analysis can decide whether a rename is worth doing.

- Rules and rubric: `docs/line-by-line-analysis.md` section 8.
- `Name quality`: `good` / `narrow` / `misleading` / `placeholder` / `wrong/unknown`.
- `Rename verdict`: `keep` / `rename-later` / `blocked-unknown`.
- `blocked-unknown` references an ID in `docs/analysis/unknowns.md`.
- Only `[confirmed]` evidence may justify a rename; renames are a separate task.
- The per-file summary lives in `docs/analysis/<file>.md`; this file is the source of
  truth.

| Identifier | Kind | Defined | Used in (file: role) | Name quality | Evidence | Rename verdict | Proposed | Confidence | Unknown ID |
|---|---|---|---|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO | - |

# Unknowns registry

Live semantic gaps: places where the code is not yet understood and the in-code comment
is provisional. Each entry has a matching `; @UNKNOWN(U-xxxx)` marker in the source (or
an analysis document).

- Rules and syntax: `docs/line-by-line-analysis.md` section 7.
- Find live markers: `grep -rn "@UNKNOWN" src/`.
- Status: `open` → `hypothesis` → `confirmed` / `refuted` / `wontfix`.
- When resolved: replace the marker with the final comment, update the status and
  evidence here, and keep the entry as history. Never reuse an ID.

| ID | Location | Symbol / line | What is unknown | Current best guess | Next step | Status | Evidence |
|---|---|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO | TODO | TODO |

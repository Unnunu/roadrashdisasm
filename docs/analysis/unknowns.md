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
| `U-0001` | `src/screens/menu_main.asm:710` | `Menu_BuildRaceTooltip` level word | physical meaning and unit of the `unk_25EC0` level-word entries | distance in tenths of a mile, displayed as one decimal | compare the five level words with the in-game tooltip distances; check `Track_LevelWords*` in `race_track_data.asm` | open | `[hypothesis]` |
| `U-0002` | `src/screens/menu_main.asm:170` | `img_Gamepad` map `+$B48` | why the asset header advertises 12x9 while `Menu_Init` copies only the top 12x6 rows | the lower 3 rows are unused padding | inspect the full decompressed map/preview and search for other readers of `+$B48` | open | `[hypothesis]` |
| `U-0003` | `src/screens/menu_main.asm:947` | `Menu_DrawRaceSelection` `divu #10 / swap / andi #$FFFE` | why the id is normalized through a divide when it is already even (identity for 0..8) | leftover from an odd-id or decimal encoding; the mask is the effective operation | audit every writer of `Menu_ram_CurrentlyDrawnRaceCard`; try an odd id in BlastEm | open | `[hypothesis]` |

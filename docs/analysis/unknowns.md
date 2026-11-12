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
| `U-0004` | `src/screens/menu_password.asm:949` | `ram_FF0522` / `ram_FF0524` (password word `w20` bits 3..4) | what the 2-bit "extra" password field represents and how the game uses it | bike/upgrade state or a small progress counter; `race_core.asm` adjusts it around `$C41A`/`$C45C` | audit all readers/writers (`race_core.asm`, `shop.asm`, `intro.asm`) and compare two profiles that differ only in this field | open | `[hypothesis]` |
| `U-0005` | `src/screens/menu_password.asm:907` | `ram_FF0510` / `ram_FF0514` (password words `w7..w10`) | physical meaning and unit of the 20-bit password field | a progress/points counter carried across races | audit readers/writers (`race_core.asm`, `shop.asm`, `menu_password.asm`; `highscore.asm` does not read it) and compare two profiles that differ only in this field | open | `[hypothesis]` |
| `U-0006` | `src/screens/message.asm:824` | `Message_StrCongratulations` row 4 digit | whether the patched digit shows the completed level or the next level (the code adds the 1-based `Menu_ram_PlayerLevel`, clamped to 4, to the template `'1'`) | displays the next level (or the template is a 0-based base) | compare the congratulations text with the current/next level in BlastEm at levels 1 and 5 | open | `[static]` |
| `U-0007` | `src/screens/rider_sprites.asm:123` | `ram_FF133A` mirror pass | high-level purpose of the mirrored sprite pass: shadow/reflection vs. an opposite-facing object | per-object mirror from `RoadObject_Flags` bit15 (also used by `Road_ScaleShape`); the code sets H-flip `$800` and walks X left | render an object with `RoadObject_Flags` bit15 set in BlastEm and identify the visual | open | `[static]` |
| `U-0008` | `src/screens/rider_intro.asm:331` | `unk_B1506` overlay | exact identity/purpose of the overlay drawn over Natasha's portrait when the extra field is non-zero | Natasha's bike/vehicle overlay | render VRAM `$D000` in BlastEm with the extra field != 0 | open | `[hypothesis]` |
| `U-0009` | `src/screens/highscore.asm:219` | `FontHighScoreDigits` (`$A2E68` -> VRAM `$1000`, tile base `$80`) | where, if anywhere, the 10-glyph digit font (`0`-`9`) is displayed; `HighScore_Init` loads it, but no `WriteNametableToBuffer` call in this screen uses base `$80` | vestigial/unused on this screen | BlastEm: break at `$72A0` after the frame DMA and search VRAM `$7000`/`$4000` for tile words `$0080`-`$0089`; also `b 37AA` and confirm `d4 != $80` | open | `[static]` |

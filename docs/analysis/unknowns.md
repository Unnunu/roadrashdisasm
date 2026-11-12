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
| `U-0001` | `src/screens/menu_main.asm:710` | `Menu_BuildRaceTooltip` level word | physical meaning and unit of the `unk_25EC0` level-word entries | resolved: track length in 16-foot units; tooltip displays `word/330` miles (`word*16/528` = tenths) | none | confirmed | `[static]` |
| `U-0002` | `src/screens/menu_main.asm:170` | `img_Gamepad` map `+$B48` | why the asset header advertises 12x9 while `Menu_Init` copies only the top 12x6 rows | resolved: every caller copies 12x6 from `+$B48`; the lower 3 rows/tiles are never referenced (authoring leftover) | none | wontfix | `[static]` |
| `U-0003` | `src/screens/menu_main.asm:947` | `Menu_DrawRaceSelection` `divu #10 / swap / andi #$FFFE` | why the id is normalized through a divide when it is already even (identity for 0..8) | resolved: all writers of `Menu_ram_CurrentlyDrawnRaceCard` store even ids; the divide is vestigial and the mask does the work | none | confirmed | `[static]` |
| `U-0004` | `src/screens/menu_password.asm:949` | `ram_FF0522` / `ram_FF0524` (password word `w20` bits 3..4) | what the 2-bit "extra" password field represents and how the game uses it | `unk_D19A` is the per-level actor slot of Natasha; hitting her sets `ram_FF0520=3`, the value decays `3→2→1→0` per race, and a non-zero value forces the Natasha intro variant/overlay | confirm the "Natasha rivalry" reading dynamically | hypothesis | `[static]` |
| `U-0005` | `src/screens/menu_password.asm:907` | `ram_FF0510` / `ram_FF0514` (password words `w7..w10`) | physical meaning and unit of the 20-bit password field | resolved: career score / high-score value, credited with `unk_D1A0[place]*level` together with money and never spent | none | confirmed | `[static]` |
| `U-0006` | `src/screens/message.asm:824` | `Message_StrCongratulations` row 4 digit | whether the patched digit shows the completed level or the next level (the code adds the 1-based `Menu_ram_PlayerLevel`, clamped to 4, to the template `'1'`) | resolved: `RaceResults_Init` runs before `EndLevel_AdvanceLevel`, so `'1'+level` shows the next level (2..5; level 5 clamps to 5) | none | confirmed | `[static]` |
| `U-0007` | `src/screens/rider_sprites.asm:123` | `ram_FF133A` mirror pass | high-level purpose of the mirrored sprite pass: shadow/reflection vs. an opposite-facing object | per-object mirror from `RoadObject_Flags` bit15 (also used by `Road_ScaleShape`); the code sets H-flip `$800` and walks X left | render an object with `RoadObject_Flags` bit15 set in BlastEm and identify the visual | open | `[static]` |
| `U-0008` | `src/screens/rider_intro.asm:331` | `unk_B1506` overlay | exact identity/purpose of the overlay drawn over Natasha's portrait when the extra field is non-zero | Natasha's bike/vehicle overlay; tied to the `U-0004` rivalry counter | render VRAM `$D000` in BlastEm with the extra field != 0 | hypothesis | `[static]` |
| `U-0009` | `src/screens/highscore.asm:219` | `FontHighScoreDigits` (`$A2E68` -> VRAM `$1000`, tile base `$80`) | where, if anywhere, the 10-glyph digit font (`0`-`9`) is displayed; `HighScore_Init` loads it, but no `WriteNametableToBuffer` call in this screen uses base `$80` | vestigial/unused on this screen | BlastEm: break at `$72A0` after the frame DMA and search VRAM `$7000`/`$4000` for tile words `$0080`-`$0089`; also `b 37AA` and confirm `d4 != $80` | open | `[static]` |
| `U-0010` | `src/screens/shop.asm:897` | `Shop_DrawBikes` palette copy | why destination palette entry 4 is taken from the next palette's w0 (`$16(a0)` with `a0 = base+10`) while source w13 is never copied | resolved: all eight bike palettes (and actor palette 0) have w0 `$0222`, so destination entry 4 is a fixed transparent/background colour | none | confirmed | `[static]` |

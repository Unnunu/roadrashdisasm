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
| `U-0004` | `src/screens/menu_password.asm:949` | `ram_FF0522` / `ram_FF0524` (password word `w20` bits 3..4) | what the 2-bit "extra" password field represents and how the game uses it | resolved: per-player 3-race Natasha encounter counter. `unk_D19A` is Natasha's actor index per level (player=0, then the level's opponents); attacking her sets `ram_FF0520=3`; `Race_ComputeResults` latches/decays the persisted field; a non-zero value forces the fourth intro variant plus the face overlay and enables her alternate race action profile | none (visual capture optional) | confirmed | `[static]` |
| `U-0005` | `src/screens/menu_password.asm:907` | `Player_ram_CareerScoreA` / `Player_ram_CareerScoreB` (password words `w7..w10`) | physical meaning and unit of the 20-bit password field | resolved: career score / high-score value, credited with `unk_D1A0[place]*level` together with money and never spent | none | confirmed | `[static]` |
| `U-0006` | `src/screens/message.asm:824` | `Message_StrCongratulations` row 4 digit | whether the patched digit shows the completed level or the next level (the code adds the 1-based `Menu_ram_PlayerLevel`, clamped to 4, to the template `'1'`) | resolved: `RaceResults_Init` runs before `EndLevel_AdvanceLevel`, so `'1'+level` shows the next level (2..5; level 5 clamps to 5) | none | confirmed | `[static]` |
| `U-0007` | `src/screens/rider_sprites.asm:123` | `Road_ram_MirrorFlag` mirror pass | high-level purpose of the mirrored sprite pass: shadow/reflection vs. an opposite-facing object | resolved: `RoadObject_Flags` bit15 is the horizontal-mirror/facing bit (the same bit as byte `+$B` bit7). It selects the mirrored shape projection and makes the sprite chain emit H-flip `$800` with X walked left; it is not a shadow/reflection layer | none | confirmed | `[static]` |
| `U-0008` | `src/screens/rider_intro.asm:331` | `RiderIntro_NatashaFaceOverlay` overlay | exact identity/purpose of the overlay drawn over Natasha's portrait when the encounter counter is non-zero | resolved identity: a close-up Natasha face/expression overlay (asset preview), not a bike. It is drawn only while the encounter counter is non-zero; the rivalry-reaction purpose is inferred from `U-0004` | none (visual capture optional) | confirmed | `[static]` |
| `U-0009` | `src/screens/highscore.asm:219` | `FontHighScoreDigits` (`$A2E68` -> VRAM `$1000`, tile base `$80`) | where, if anywhere, the 10-glyph digit font (`0`-`9`) is displayed; `HighScore_Init` loads it, but no `WriteNametableToBuffer` call in this screen uses base `$80` | resolved: vestigial/unused. Every draw on this screen uses `$400/$480/$500/$580` (`WriteNametable`) or `$40`/`$0` (`WriteNametableToBuffer`); no `$80` tile base exists | none | wontfix | `[static]` |
| `U-0010` | `src/screens/shop.asm:897` | `Shop_DrawBikes` palette copy | why destination palette entry 4 is taken from the next palette's w0 (`$16(a0)` with `a0 = base+10`) while source w13 is never copied | resolved: all eight bike palettes (and actor palette 0) have w0 `$0222`, so destination entry 4 is a fixed transparent/background colour | none | confirmed | `[static]` |
| `U-0011` | `src/race/race_ai.asm:4249` | `Race_SetupActorSprite` input `d4` | `d4` is used as a Y span (`Y±d4`) for extra target-candidate buckets but is never set inside this routine or by `Race_SetupActor`; where its value comes from on each path is not proven | ambient register: the AI path restores `d4` around movement, so it is whatever `Race_Update` left; at spawn it is uninitialized leftover. Only the extra candidate buckets change, not the base `AnimIndex` | E1 done: `d4=0` on every AI-path call in a full demo (4169 calls, `ret=0x10FE8`); no spawn path was reached. Next: a normal-mode traffic/recycle capture to observe spawn | open (spawn only) | `[static]/[dynamic]` |

L2 static pass added **no new U rows**. The open-looking items are statically
resolved quirks, not semantic gaps: `$18` is a word (the old trace read its low
byte), `$78` is never set non-zero so `word_14742` is unreachable,
`Race_LoadBikeData` ignores its `bikeId*16` index and always copies
`unk_25AC4[0]`, and `TrackParam1` is loaded but never read. See
`docs/analysis/race_speed.md` and `docs/analysis/race_data_tables.md`.

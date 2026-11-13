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
| `U-0004` | `src/screens/menu_password.asm:949` | `Player_ram_NatashaCounterA` / `Player_ram_NatashaCounterB` (password word `w20` bits 3..4) | what the 2-bit "extra" password field represents and how the game uses it | resolved: per-player 3-race Natasha encounter counter. `unk_D19A` is Natasha's actor index per level (player=0, then the level's opponents); attacking her sets `Player_ram_NatashaCounter=3`; `Race_ComputeResults` latches/decays the persisted field; a non-zero value forces the fourth intro variant plus the face overlay and enables her alternate race action profile | none (visual capture optional) | confirmed | `[static]` |
| `U-0005` | `src/screens/menu_password.asm:907` | `Player_ram_CareerScoreA` / `Player_ram_CareerScoreB` (password words `w7..w10`) | physical meaning and unit of the 20-bit password field | resolved: career score / high-score value, credited with `unk_D1A0[place]*level` together with money and never spent | none | confirmed | `[static]` |
| `U-0006` | `src/screens/message.asm:824` | `Message_StrCongratulations` row 4 digit | whether the patched digit shows the completed level or the next level (the code adds the 1-based `Menu_ram_PlayerLevel`, clamped to 4, to the template `'1'`) | resolved: `RaceResults_Init` runs before `EndLevel_AdvanceLevel`, so `'1'+level` shows the next level (2..5; level 5 clamps to 5) | none | confirmed | `[static]` |
| `U-0007` | `src/screens/rider_sprites.asm:123` | `Road_ram_MirrorFlag` mirror pass | high-level purpose of the mirrored sprite pass: shadow/reflection vs. an opposite-facing object | resolved: `RoadObject_Flags` bit15 is the horizontal-mirror/facing bit (the same bit as byte `+$B` bit7). It selects the mirrored shape projection and makes the sprite chain emit H-flip `$800` with X walked left; it is not a shadow/reflection layer | none | confirmed | `[static]` |
| `U-0008` | `src/screens/rider_intro.asm:331` | `RiderIntro_NatashaFaceOverlay` overlay | exact identity/purpose of the overlay drawn over Natasha's portrait when the encounter counter is non-zero | resolved identity: a close-up Natasha face/expression overlay (asset preview), not a bike. It is drawn only while the encounter counter is non-zero; the rivalry-reaction purpose is inferred from `U-0004` | none (visual capture optional) | confirmed | `[static]` |
| `U-0009` | `src/screens/highscore.asm:219` | `FontHighScoreDigits` (`$A2E68` -> VRAM `$1000`, tile base `$80`) | where, if anywhere, the 10-glyph digit font (`0`-`9`) is displayed; `HighScore_Init` loads it, but no `WriteNametableToBuffer` call in this screen uses base `$80` | resolved: vestigial/unused. Every draw on this screen uses `$400/$480/$500/$580` (`WriteNametable`) or `$40`/`$0` (`WriteNametableToBuffer`); no `$80` tile base exists | none | wontfix | `[static]` |
| `U-0010` | `src/screens/shop.asm:897` | `Shop_DrawBikes` palette copy | why destination palette entry 4 is taken from the next palette's w0 (`$16(a0)` with `a0 = base+10`) while source w13 is never copied | resolved: all eight bike palettes (and actor palette 0) have w0 `$0222`, so destination entry 4 is a fixed transparent/background colour | none | confirmed | `[static]` |
| `U-0011` | `src/race/race_ai.asm:4249` | `Race_SetupActorSprite` input `d4` | `d4` is used as a Y span (`Y±d4`) for extra target-candidate buckets but is never set inside this routine or by `Race_SetupActor`; where its value comes from on each path is not proven | resolved: no writer in either path; the ambient value is 0 on the AI and spawn paths, so the extra candidate buckets are not widened in normal play | none | confirmed | `[static]` no `d4` writer in `Race_SetupActorSprite`/`Race_SetupActor`/spawn init; `[dynamic]` E1 demo AI path 4169 calls `d4=0`; E2 normal mode 6 spawn calls (`ret=0x16E24`) `d4=0` (`analysis/notes/L2b_spawn_trace.txt`) |

| `U-0012` | `src/race/race_ai.asm:558` | `sub_1131A` shadow-follow | why the shadow/actor PosY gap is biased by `$20`, and what `STRUCT_OFFSET_8`/`STRUCT_OFFSET_22` drive | resolved: `$8` is the signed per-frame Y velocity for the on-foot/shadow-follow path, `$22 = velocity*FrameDelay` is added to `$00`, and `$20` is the fixed shadow/actor stand-off (same constant in `Race_HandleInputOnFoot`). `sub_1131A` itself has no static caller (dead twin of the on-foot path) | none | confirmed | `[static]`: live twin `race_ai.asm:304-399`, callgraph callers `-` |
| `U-0013` | `src/race/race_ai.asm:1321` | `sub_11A5E` `$E/$10` | meaning of `$E/$10` and the exact `Track_CurveBuffer` wrap rule | resolved: `$E` = whole-track X advance, `$10` = final curve-buffer index (both write-only). The buffer is 256 x 2 bytes at `$FFDC58-$FFDE57`; forward walks wrap at `$FFDE58`, backward walks wrap at `$FFDD56` (index 127) | none | confirmed | `[static]`: `race_spawn.asm` decode chunks, all `a4` bounds tests |
| `U-0014` | `src/race/race_ai.asm:4468` | `Race_TrackObjectTypeTable` | record fields beyond the type byte and the `+6` word; why the side test uses `$2` bits | resolved: track-object record = `+0` long 16.16 X, `+2` type byte, `+3` lane byte (low nibble). Type table = `+0` render flags, `+2` size 16.8, `+4` action-handler index, `+6` word (`+7` steerable flag). Side test = `lane*$20-$100` XOR `PosY` sign | none | confirmed | `[static]`: `sub_12070`, `sub_13D44`, `sub_13DE0`, `race_ai_road.asm:1767` |
| `U-0015` | `src/race/race_anim_audio.asm:1224` | `sub_14DEC` | why `d0` is always 0 (both signed Speed terms read `$12(a1)`) and who calls it | resolved: vestigial helper. Both Speed terms read `$12(a1)` (the second was likely meant to be `$12(a2)`), so `d0` is always 0; neither a call nor any pointer/address reference exists in the ROM | none | wontfix | `[static]`: full `src/` and `build/roadrash.lst` reference scan |
| `U-0016` | `src/race/race_ai.asm:1887` | `unk_12168` | consumer and dispatch semantics of the 9-pointer table (index 2 is `sub_140EE`) | resolved: dead data. No static reader and no pointer/address reference in the ROM; the live dispatch tables are `unk_147FC` -> `unk_14744` | none | wontfix | `[static]`: full `src/` and `build/roadrash.lst` reference scan |
| `U-0017` | `src/race/race_ai.asm:3017` | `Race_UpdateActorActions` stamina regen | why opponent stamina `$5C` regrows toward `ram_FF18A8=$500` but snaps to the graphics entry `+$E` once `$5C+FrameDelay >= $500`, instead of capping at a fixed max | resolved: `$5C` is stamina. The generic actor loop adds `FrameDelay` while `$5C+FrameDelay < ram_FF18A8 ($500)`; once the sum reaches `$500` it stores the actor's graphics record `+$E`. So `$500` is the shared minimum/baseline, not the per-actor cap; the graphics `+$E` is the per-page maximum restored at/above the baseline (pages 0..3: `$500/$640/$780/$8C0`, pages 4..9: `$A00`). The player is skipped by the action loop outside demo mode and regenerates in `Race_UpdatePlayerAnimation` toward `Race_ram_PlayerStaminaMax=$A00` (its spawn override) | none | confirmed | `[static]` `race_ai.asm:3017-3024`, `race_anim_audio.asm:4414-4432`, `race_core.asm:1256-1258/2794-2797`, `Race_ActorGraphicsTable`; `[confirmed]` `analysis/capture_L8_u17.gdb`: page-1 actor starts at `$640`, forced `$4F0 -> $4F7 -> $4FE -> $640` across the `$500` threshold (`analysis/notes/L8u17_trace.txt`) |
| `U-0018` | `src/race/race_physics.asm:1013` | `Race_BuildVScrollInfo` compaction pass | per-case arithmetic of the `+E`-driven block copy/merge and the recomputed `$8Axx` line-gap commands | resolved: `+E` is the band line reference (`HV=(E<<8)-$A0`). Phase 1: negative `+E` copies the referenced block into block 0 and follows its `+A` (elide). Phase 2: `+E<=8` merges into block `$10`, then `E10=max(E,4)`. Phase 3: merge into `$20` while `+E<=E10+8`, then `E20=max(E,E10+4)`. Phase 4 writes `cmd(d1)=$8A00+E(next(next(d1)))-E(next(d1))-1` while the block after next is below `$90`; block `$70` keeps `$8AFF`, block 0 is `$8A01`, tail writes `$C=$8210/$E=$8403`. E6 lines `$04/$08/$26/$34/$48/$9D` give `$8A1D/$8A0D/$8A13/$8A54/$8AFF` and the `$10->$20->$50->$60->$70->$80->$90` chain, matching the formula exactly | none | confirmed | `[static]` `.loc_E2AE..E3E0`; `[dynamic]` E6 `analysis/notes/L6a_hint_trace.txt` |
| `U-0019` | `src/race/race_ai_road.asm:1932` | `Race_ProjectObject` return `d3` / `RoadObject_Flags` bits | whether the projected profile row and the sprite-chain pass count share the same `Flags` bits | resolved: they are different fields. Low 5 bits = row; the high byte `(Flags>>8) & 7` (bits 10-8) = SAT copy-pass count. Data4 `+$02` bits 8-10 feed the pass count; the row comes from the projection. `Road_DrawObject` reads `move.b Flags(a0)` (high byte), not the low bits | none | confirmed | `[static]` `road_render.asm:96F4-96F8`, `race_ai_road.asm:10AFC`; `[confirmed]` E8-B: `$FFD430` `flags=$1184` pass=1 row=4, 6 entries copied once; pass=0 objects skip the loop (`analysis/notes/L8b_trace.txt`) |

L2 static pass added **no new U rows**. The open-looking items are statically
resolved quirks, not semantic gaps: `$18` is a word (the old trace read its low
byte), `Race_LoadBikeData` ignores its `bikeId*16` index and always copies
`unk_25AC4[0]`, and `TrackParam1` is loaded but never read. See
`docs/analysis/race_speed.md` and `docs/analysis/race_data_tables.md`.

R30 integration corrected the earlier `$78` claim: `sub_14456`/`sub_1446E` arm it
(`$78`/`$1E`) when `$6E < 3`, so the `word_14742` limit branch in
`Race_UpdateBikeCurve` is reachable during a fall/crash.

L2 dynamic pass (E2) closed `U-0011` and added no new rows. R30 integration closed
`U-0012`..`U-0016` statically; no L3/L4 experiment is required for them. Dynamic
confirmation of the crash/fall branch timing remains part of L4.

L4 dynamic pass (E4) closed the `$5C`/damage/knockdown questions: `$5C` is stamina,
`Race_ApplyFallKnockdown` subtracts `PairImpact*Race_ram_StaminaHitScale`, and both
`Race_ApplyCollisionImpact` branches are confirmed. It added `U-0017` for the
opponent stamina regen cap. The R30 crash handlers (`sub_140EE`/`sub_141AE`) remain
`[static]` because the 60 s demo never crashes.

Residual pass closed `U-0017` dynamically: `ram_FF18A8=$500` is the shared baseline;
below it the actor accumulates `FrameDelay`, at/above it the loop restores the
`Race_ActorGraphicsTable` page maximum `+$E` (`$500/$640/$780/$8C0/$A00`). The player
regenerates separately in `Race_UpdatePlayerAnimation` toward `Race_ram_PlayerStaminaMax=$A00`.

L6a added `U-0018` for the VScroll compaction arithmetic; the block layout, chain and
observed runtime bands were confirmed then. The residual pass enumerated the four
phases (negative elide, `+E<=8` merge, `+E<=E10+8` merge with line clamps, and the
gap loop `$8A00+E(next2)-E(next)-1`) and checked them against the E6 numbers.

L6c (E8) closed `U-0019`: `RoadObject_Flags` bits 10-8 are the SAT copy-pass count
(read through the high byte), while the low 5 bits are the projected row. The
Data4 `+$02` bits 8-10 source and the Data4 side/second-shape bits are decoded in
`docs/analysis/race_track_data.md`; the writer pixel map is in
`docs/analysis/road_render.md`. Remaining world unknowns are optional visual
checks; `U-0017` (opponent stamina regen) and `U-0018` (VScroll compaction
arithmetic) are now closed.

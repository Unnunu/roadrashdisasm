# State history (archive)

Chronological pass log moved out of `STATE.md` during the docs-hygiene task.
Current status lives in `STATE.md`; detailed facts live in `docs/analysis/`.

## Verified pass log

## Verified

- Repository contains `baserom.md`, `build.sh`, `src/`, `docs/`, `tools/`, and
  `AGENTS.md`.
- Real build/check commands are `./build.sh` and `python3 tools/assets.py check`.
- `docs/INDEX.md` and the session workflow files were created in a setup task.
- User ran `./build.sh` after the setup and reported success (`Matched OK`).
- No git commit was made for this setup task yet.
- Line-by-line methodology was added:
  - `docs/line-by-line-analysis.md` — scope (general analysis vs line-by-line),
    pass order, comment decision rules, markers, identifier audit, verification.
  - `docs/analysis/unknowns.md` — registry for `@UNKNOWN(U-xxxx)` semantic gaps.
  - `docs/analysis/identifiers.md` — cross-file identifier quality map + rename verdicts.
  - Templates, `docs/coding-style.md`, `docs/reverse-engineering.md`, `docs/INDEX.md`,
    and `AGENTS.md` were updated to reference the new artifacts.
  - `AGENTS.md` now states: communicate with the user in Russian; keep code, comments,
    and docs in English.
- `./build.sh` after the documentation changes: `Matched OK` (786432 bytes). Docs-only
  change, so byte output is unchanged.
- `src/screens/menu_main.asm` line-by-line pass completed (all 10 functions,
  comment-only). `./build.sh` -> `Matched OK`.
- `docs/analysis/identifiers.md` populated with 92 rows (every identifier referenced in
  `menu_main.asm`).
- `docs/analysis/unknowns.md` populated with `U-0001` (tooltip level-word unit),
  `U-0002` (gamepad 12x9 header vs 12x6 use), `U-0003` (`divu #10` even normalization).
- `docs/analysis/menu_main.md` and `docs/modules/menu_main.md` updated: full coverage
  matrix (all functions analyzed line-by-line), carousel mapping, card stride/place
  text, window semantics, identifier summary and open IDs.
- `tasks/menu_main_line_by_line.md` Result/Handoff filled in.
- `src/screens/menu_password.asm` line-by-line pass completed (all 10 functions,
  comment-only). `./build.sh` -> `Matched OK` (786432 bytes); stripping comments from the
  HEAD and working copies leaves 995 identical non-comment lines.
- Password structure/checksum documented in the `.asm` header and
  `docs/analysis/menu_password.md`. Python reimplementation: template
  `01234  5678901234  56789` is invalid (sum&$3F=63, mask=21); initial state yields
  `00000  00001010D8  101MN` (valid, sum=21, mask=21, money 100).
- `SelectCurrentTrack` rule confirmed statically: first race with place 0, else the race
  with the largest (worst) place; ties keep the earlier race.
- `docs/analysis/identifiers.md` extended with the menu_password functions/data/RAM;
  `docs/analysis/unknowns.md` extended with `U-0004` (2-bit `ram_FF0522/24`) and
  `U-0005` (20-bit `ram_FF0510/14`).
- `docs/analysis/menu_password.md`, `docs/modules/menu_password.md` and
  `tasks/menu_password_line_by_line.md` updated.
- `src/screens/message.asm` line-by-line pass completed (all 17 routines/labels,
  including draw-only entries and the `Message_ShowNoop` alias). `./build.sh` ->
  `Matched OK` (786432 bytes).
- Message array groups mapped: main menu 0-10, password 12-15, rider intro 17-19
  (index 17 unreached), race results 21-40, high score 42-46, end-level 48-49, shop
  51-66.
- Text-record layout, `Menu_dRaceNameTable` distance patch, `DemoHighScoreTable`
  (7x20), password status template (5x16), labels (7x12), bike descriptions and
  busted/repair strings documented. `$2FF + $2500 = $27FF` (default tile `$7FF`,
  palette 1) decoded; redundant second `Message_Clear` in the C/Start draw paths noted
  `[static]`.
- Renames applied in `message.asm` (cross-file references updated):
  `sub_4268`→`Message_ShowNoop`,
  `Message_DrawDirPadVert`→`Message_BlinkDirPadHorizontal`,
  `Message_DrawDirPadRight`→`Message_BlinkDirPadVertical`,
  `loc_4486`→`Message_DrawDirPadHorizontalIcon`,
  `loc_44FE`→`Message_DrawDirPadVerticalIcon`,
  `word_4EEE`→`Menu_dPasswordLabels`,
  `unk_4E20`→`MenuPassword_StrStatusTemplate`, plus the 39 placeholder
  string/table labels to `Message_Str*`/`Menu_StrRace*` names. The mis-addressed
  `unk_4AE8` (actually `$4A68`) became `Menu_StrRacePacificCoast`.
- `docs/analysis/message.md`, `docs/modules/message.md`,
  `docs/analysis/identifiers.md`, `docs/callgraph.md`, `tasks/message_line_by_line.md`
  and the related analysis/module docs were updated.
- The `message.asm` work was committed as
  `006cf26 message: line-by-line pass and justified renames` (18 files, src + docs).
- `src/screens/rider_sprites.asm` line-by-line pass completed (both routines + table,
  comment/formatting only). `./build.sh` -> `Matched OK` (786432 bytes); the emitted
  slice `$5944-$59C3` is identical to `baserom.md`.
- `RiderSprites_StripTable` reformatted to 16 `dc.w` records (4 words each) and fully
  decoded: indexed by `4*R + C` (C = horizontal remainder code from `d0`, R = vertical
  from `d1`); fields = Y step `8*(R+1)`, size code `(4*C+R)<<8`, tile step
  `(R+1)*(C+1)`, X step `8*(C+1)`. The tile step matches
  `Animation_dTileCountMinus1`, confirming the size/sprite geometry.
- Corrected the SAT tile-word semantics: `$8000` = priority, `$800` = H-flip (not
  priority), so `ram_FF133A` selects a horizontally mirrored pass (H-flip + X walked
  left); the old "shadow/overlay" wording is now hypothesis `U-0007`.
- `RiderSprites_Build` model documented: caller packs tile extent as `tiles*8`;
  the routine builds a grid of full 4x4 blocks plus a remainder row/column, one SAT
  entry per block, chained via the size/link low byte.
- `docs/analysis/rider_sprites.md`, `docs/modules/rider_sprites.md`,
  `docs/analysis/identifiers.md` (21 new rows) and `docs/analysis/unknowns.md`
  (`U-0007`) updated.
- `tasks/rider_sprites_line_by_line.md` Result/Handoff filled in.
- `src/screens/rider_intro.asm` line-by-line pass completed (both routines,
  comment-only). `./build.sh` -> `Matched OK` (786432 bytes).
- Quote analysis: 155 records; 85 are referenced only by `RiderIntro_RecordTable` and
  70 only by the results/end-level tables (no overlap). The 85 intro quotes were renamed
  to `RiderIntro_Quote_<Rider>_<NN>`; the 70 results/end-level quotes remain
  `RaceQuote_*`.
- Portrait header names `[static]`: 0 Natasha, 1 O'Leary, 2 O'Rourke, 3 Flynn,
  4 O'Shea, 5 O'Connor, 6 Biff, 7 Slater, 8 Ikira, 9 Sergio, 10 Helldog.
- `rider_intro.asm` verified: record index `(level-1)*$A0 + trackId*$10 + variant`;
  name centering by right-rotation; quote rows 3,5,7,9; message timer fires after 301
  ticks; pad A release edge has priority over B; new `U-0008`.
- `docs/analysis/rider_intro.md`, `docs/modules/rider_intro.md`,
  `docs/analysis/race_data_tables.md`, `docs/analysis/identifiers.md` (93 rows added),
  `docs/analysis/unknowns.md`, and `tasks/rider_intro_line_by_line.md` updated.
- `src/screens/highscore.asm` line-by-line pass completed (all 4 routines + local
  labels). `./build.sh` -> `Matched OK` (786432 bytes).
- Highscore corrections: the palette copy reads the **title** blob (`ImageBuffer+$4E4`
  after `ImgHighScoreTitle` decompression; asset spec `screen_palettes.highscore`), not
  the background; the SAT clear writes two entries (entry 0 `link=0` terminates); VRAM
  `$FFE0` is the blank pattern for tile `$7FF`; `EncodeString` uses only header
  `+4/+6`; the demo timer runs 601 decrements; the message-id lower-bound clamp is
  unreachable; `HandleInput` writes a byte.
- Rename applied: `unk_A2E68` -> `FontHighScoreDigits` (10 digit glyphs `0`-`9`; preview
  `assets/tilesets/highscore_extra/`).
- `docs/analysis/identifiers.md` extended with 11 highscore rows;
  `docs/analysis/unknowns.md` gained `U-0009` and `U-0005` was narrowed.
- `docs/analysis/highscore.md`, `docs/modules/highscore.md`, `docs/ram-map.md`,
  `docs/analysis/rom_tail.md`, `docs/analysis/assets.md`, `tools/asset_specs.json` and
  `tasks/highscore_line_by_line.md` updated.
- `src/screens/shop.asm` line-by-line pass completed (all 12 functions + data,
  comment-only). `./build.sh` -> `Matched OK` (786432 bytes); comment-stripped code is
  identical to HEAD.
- Shop corrections: VDP reg0/reg1 wording; palette pointers are `a0` = current and
  `a1` = previous (comments were swapped); palette source is the
  `shop_arrow_right+$C4` screen palette; credits/price use palette 3 when the credits
  are insufficient and palette 2 when affordable (the docs previously had this
  inverted); "(its yours)" is three longs written backwards.
- `Shop_DrawBikes` palette copy decoded: skip source w4, dst w4 = next palette w0,
  dst w5-w12 = source w5-w12, dst w13-w15 untouched (`U-0010`).
- Left/Right redraw the new bike immediately while the scroll band is still animating;
  the transient wrong model/palette seen on hardware is the expected result.
- User-described native-console layout (`[dynamic]`): one centre bike plus one edge
  sliver on each side, layered title/arrows/grey backdrop/bikes/texts/gamepad, all bikes
  slide one position per Left/Right.
- `docs/analysis/identifiers.md` extended with 36 shop rows; `docs/analysis/unknowns.md`
  gained `U-0010`; `docs/analysis/shop.md`, `docs/modules/shop.md`,
  `docs/analysis/coverage.md` and `tasks/shop_line_by_line.md` updated.
- `src/screens/endlevel.asm` line-by-line pass completed (all 6 functions, dead tail
  and animation script). `./build.sh` -> `Matched OK` (786432 bytes).
- `EndLevel_AnimationScript` (`$8DC2-$8FB3`, `0x1F2` bytes) decoded and reformatted
  byte-identically: tilemap base `$80000`, last frame index `122` (123 pointers),
  absolute pointers into the decompressed `EndLevel_AnimationData` buffer at
  `Intro_ram_ImageBuffer` (`+$0000..+$5024`, decompressed size `$5066`; frames 0/1 empty).
- Endlevel corrections: `EndLevel_FrameCounts` are inclusive last indices; level 5
  limit `123` is one past the last valid frame `122` (one no-op frame); the sprite
  swap rearm of `5` gives a 6-GameTick DMA period (not 5 frames/12 fps);
  `$50000000` is a VRAM write to `$1000` clearing two SAT entries; `EndLevel_Init`
  clears only one H-scroll entry, two VSRAM words and four SAT entries; the quote uses
  `y/2` with stride 128 (rows 3,5,7,9); the opponent list is `$4B` + 15 words = 16.
- `docs/analysis/endlevel.md`, `docs/modules/endlevel.md`, `docs/analysis/animation.md`,
  `docs/analysis/assets.md`, `docs/ram-map.md`, `docs/analysis/identifiers.md` and
  `tasks/endlevel_line_by_line.md` updated. No new `@UNKNOWN` rows were needed.
- Endlevel verification: `assets.py check` -> 62 slices OK; `git diff --check` clean;
  the pre-script code/data lines are identical to HEAD (only comments changed there).
- Static unknowns pass (comment/doc-only) closed six entries:
  - `U-0001` confirmed: `unk_25EC0` level word = track length in 16-foot units;
    `Menu_BuildRaceTooltip` shows `word/330` miles (track 0 L1 5.6 mi, L5 15.5 mi).
  - `U-0002` wontfix: all `img_Gamepad` callers copy 12x6 from `+$B48`; the lower 3
    map rows/tiles are never referenced (vestigial asset tail).
  - `U-0003` confirmed: every writer of `Menu_ram_CurrentlyDrawnRaceCard` stores an
    even id; `divu #10` is the identity and `andi #$FFFE` is the effective mask.
  - `U-0005` confirmed: `Player_ram_CareerScoreA/B` is the career score / high-score
    value (`unk_D1A0[place]*level` added with money; used by
    `Race_UpdateHighScoreTable`; never spent).
  - `U-0006` confirmed: `RaceResults_Init` runs before `EndLevel_AdvanceLevel`, so the
    congratulation digit shows the next level (2..5; level 5 clamps to 5).
  - `U-0010` confirmed: all eight `Shop_BikePalettes` have w0 `$0222` (actor palette 0
    too), so `Shop_DrawBikes` destination entry 4 is a fixed transparent/background
    colour.
- `U-0004` confirmed statically: `unk_D19A = [4,4,3,5,4]` is Natasha's per-level
  **actor index** (player 0 + opponent position). Player attacks on Natasha set
  `ram_FF0520=3` (`race_anim_audio.asm:1582-1588`); `Race_ComputeResults` decays the
  persisted `ram_FF0522/24` counter and latches the current race (`race_core.asm:2133`);
  non-zero selects intro variant `$18` + face overlay (`rider_intro.asm:141-155`) and
  enables Natasha's alternate race action profile (`race_ai.asm:3438`).
- `U-0007` confirmed statically: `RoadObject_Flags` bit15 is the horizontal-mirror/facing
  bit (`btst #7,+$B` is the same bit). It selects the special mirrored projection
  (`Road_ScaleShape`/`Road_ProjectShape*`) and makes `RiderSprites_Build` emit H-flip
  `$800` with X walked left; it is not a shadow/reflection layer.
- `U-0008` confirmed statically: the `$B1506` overlay preview
  (`assets/images/intro_natasha_overlay/preview.png`) is a close-up Natasha
  face/expression layer, not a bike. It is drawn only while the encounter counter is
  non-zero; the rivalry-reaction purpose is inferred from `U-0004`.
- `U-0009` resolved as wontfix: every high-score draw uses tile base
  `$400/$480/$500/$580` or `$40/$0`; `FontHighScoreDigits` at `$1000` is loaded but
  never drawn.
- Renames applied in this pass: `ram_FF0510/14` -> `Player_ram_CareerScoreA/B`,
  `ram_FF1414/18/1A` -> `RaceResults_ram_StandingsRecord/Height/Width`,
  `ram_FF133A` -> `Road_ram_MirrorFlag`, `unk_AF902` -> `RiderIntro_Portrait_0`,
  `unk_B1506` -> `RiderIntro_NatashaFaceOverlay`.
- Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` -> 62
  slices OK; `git diff --check` clean.
- The static-unknowns/rename batch was committed as
  `00ea034 analysis: close U-0004/7/8/9 and rename fields` (35 files).
- Race understanding program planned and written to
  `tasks/race_understanding_program.md` (not started). Confirmed decisions:
  simulation layers L1-L5/L7 first, road/render L6 as a separate branch;
  line-by-line only for semantic hubs; dynamic evidence = agent-run headless
  captures + user-described scenarios/manual breakpoints (`[user-report]`).
- First build task written: `tasks/race_map_and_tools.md` (phase A: create
  `docs/analysis/race_map.md`, `tools/race_dump.py`, `tools/ram_diff.py`, validate on
  existing `analysis/dumps/*.bin`; no `src/` changes).
- `tasks/race_map_and_tools.md` phase A completed:
  - `docs/analysis/race_map.md` created (L0 timeline, dataflow spine, actor field
    ownership matrix v0 for `$00-$7E`, register-base/list warning, capture matrix,
    tool usage, L1-L7 study order) and linked from `docs/INDEX.md`.
  - `tools/ram_layout.py` (shared `equ` parser, actor/object/list layout, bounds-
    checked dump reader), `tools/race_dump.py` (summary/`--actor`/`--json`) and
    `tools/ram_diff.py` (runs + actor/object/list annotation, `--region`, `--json`)
    created.
  - Validation on the checked-in dumps: `actor_running` -> count 8, `$FF1A08` =
    PlayerA + 7 opponents, `$FF1A0C` = 7 opponents, free lists 7/0, object count
    `$FFDE72`=22, visible list 22 entries; `post_create` vs `post_positions` shows
    PlayerA `$00/$04/$1A/$1E/$30`; `steer_left` vs `steer_right` shows `$42`
    `$FFB7 -> $0049`. Short-dump and out-of-range actor inputs fail cleanly.
  - `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` -> 62 slices OK;
    `git diff --check` clean; `py_compile` OK. No `src/` changes.
- Verified layout nuance: `ram_FF1A08` is the AI-loop list (PlayerA + 7 opponents);
  `Race_ram_ActiveActorList` (`$FF1A0C`) starts one pointer later and holds the 7
  opponents, while `Race_ram_ActiveActorCount` includes PlayerA. Object-array length
  is `ram_FFDE72`, not `Race_ram_TrackObjectCount` (staged-this-frame counter).
- L1 actor-core static pass (`tasks/race_L1_actor_core_a.md`) completed; `src/` changes
  are comment-only and the ROM stayed byte-identical.
  - `Race_InitActorLists`: `ram_FF1A08` = PlayerA + `Struct_9..15` (8);
    opponent free list = `Struct_2..8` (7). Old "+$24 from the second entry" and
    "object pointer tables" comments corrected.
  - `$00` = absolute draw/screen Y; `$30` = road-relative Y
    (`drawY - RoadYTarget`); `$1A` = previous `$30`; `$36` is an accumulator.
  - `$08` = `Road_ShapeTable` index (`sub_12414`); `$0A` bit14 = shape flip;
    `$34` = signed shape/lean variant; `$58` = animation frame token copied to
    actor object `+8`; `$76` = animation flag byte.
  - `$24`/`$44` write-only (no reader); `$48/$64/$7A/$7C/$7E` are not actor fields
    (VScroll/rearview/object buffers); `$02` is also written by `sub_115C6`.
  - `Race_ActorShadowTable` entries 2 and 9 are swapped slots (byte-exact data).
  - `Race_SetupActorSprite` consumes ambient `d4`; recorded as `U-0011`.
  - `docs/analysis/race_map.md` now has field matrix v1 and Experiment Pack E1
    (five checks); `race_actors.md`, `race_spawn.md`, `identifiers.md` (+29 rows),
    `unknowns.md`, and `coverage.md` updated.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean; comment-stripped diff vs HEAD identical.

- `tasks/race_L1_actor_core_b.md` completed: Experiment Pack E1 was run with
  `analysis/capture_L1b_*` (headless BlastEm/GDB) and integrated into field matrix v2 in
  `docs/analysis/race_map.md`. No ROM behavior change; `src/race/race_ai.asm` change is
  the `U-0011` comment only.
- E1 results (`[confirmed]`): `$30 = $00-$36` at `0x10FE4` (`$00` draw Y, `$36` road
  target, `$1A` previous); `$22 = d0` and `$00 += d0` in `sub_113A4`; `$34` is the signed
  shape bucket (`-1/-2` -> H-flip `$8000`, `+1` -> clear; forcing steering `±$600` left
  it `0`, so it is not the steer input); `$36` is the road-target accumulator, `$38/$3A`
  update in movement, `$3C` is a write-only copy of `sub_115C6`'s `d1`.
- E1-5: a full 60 s demo produced 4169 `Race_SetupActorSprite` calls, all AI path
  (`ret=0x10FE8`) with `d4=0`; no spawn path (`ret=0x16E24`). `U-0011` is now open only
  for the spawn value.
- Demo collision/crash survey (3600 frames): 9 pair Y-overlap contacts (`0x127EA`), one
  with `RacePlayerA`; 0 object/static impacts (`0x14486`); 0 crash entries (`0x11B7A`,
  gated on `DemoMode == 0`); 6 `Race_ApplyFallKnockdown` entries, none with the player.
  Natural demo collisions exist but are rare and never player crashes.
- Verification of this pass: `./build.sh` -> `Matched OK` (786432 bytes);
  `assets.py check` -> 62 slices OK; `git diff --check` clean; comment-stripped diff vs
  HEAD identical for all modified `src/` files.
- `docs/analysis/race_actors.md`, `coverage.md`, `identifiers.md`, `unknowns.md` and
  `tasks/race_L1_actor_core_b.md` updated with the dynamic evidence.

- L2 control static pass (`tasks/race_L2_control_a.md`) completed; `src/` changes are
  comment-only (`race_core.asm`, `race_ai.asm`) and the ROM stayed byte-identical.
  - Input contract: SACBRLDU bits; Left subtracts/Right adds; reversal and clamp;
    Left priority over Right; B -> `$68` bit1 (accelerate), A -> bit2 (brake); C only
    masks Start; Start toggles `Race_ram_State` behind `ram_FF368E`.
  - Lean chain: `$42` formula -> `sub_113CA` `$0C = (FrameDistance>>8)*$42>>8`;
    `Race_UpdateBikeCurve` `$3E = (limit<<8)/(d0>>8)`, `$68` bit5;
    `Race_UpdateLeanCurve` `ram_FF3042`/`$40`.
  - Speed/gear branch order and `$14` results documented; `$18` is a word and the
    checked-in dump has `Gear=5` (the old trace read its low byte and falsely showed
    0). Demo bike id 0 -> `ActorBikeRecord_2` (upshift `$125C..$2EE0`).
  - Tables decoded: `unk_25A10` (13 pointers by `$16`), `ActorBikeRecord_*` (19 words:
    max/6 accel/6 upshift/6 downshift), `unk_25AC4` (8 x 16 bytes; `Race_LoadBikeData`
    always loads block 0 because the `bikeId*16` index is computed but unused),
    `unk_25B50` (8 bikeId -> even records), `unk_1471A` (5 x 4 words: TP0 on-road,
    TP1 unused, TP2 off-road, TP3 off-road+curve).
  - Static quirks: `$78` is never set non-zero -> `word_14742` branch unreachable;
    `TrackParam1` loaded but never read.
  - `docs/analysis/race_map.md` is matrix v3 with the L2 `$68`/`$69` bit ownership and
    Experiment Pack E2. Updated: `race_speed.md`, `race_ai.md`, `race_movement.md`,
    `race_data_tables.md`, `identifiers.md` (25 rows), `unknowns.md` (no new U),
    `coverage.md`, `tasks/race_L2_control_a.md`.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean; comment-stripped diff identical to HEAD.
  - No renames and no commit.

- R30 gap pass (`tasks/race_ai_gap_functions.md`,
  `tasks/race_anim_audio_gap_functions.md`) completed; all remaining `dc.b` code in
  `race_ai.asm 0x1131A-0x13DDF` and `race_anim_audio.asm 0x140BC-0x14486` is real
  68k code, byte-exact.
  - `race_ai.asm`: `sub_1131A` shadow-follow, `sub_11A5E` curve-position integration,
    `sub_12B2A` adjusted attack reach, `sub_133F0` curve direction, `sub_135E8`
    accelerate flag, `sub_13704` distance ratio, `sub_13A5C` far respawn, `sub_13D44`
    track-object steering. Dead `11F54-11F58` and `139AC-13A17` kept and commented.
  - `race_anim_audio.asm`: `sub_140BC`, `sub_140EE`, `sub_141AE`, `sub_142B0/BE/CC`,
    `sub_142FE`, `sub_1436E`, `sub_14404/56/6E`, `sub_14DEC`, `sub_15580`. Dead
    `15458-15468` kept and commented.
  - Tables formalized: `unk_12168` (9 `dc.l`), `unk_12B7C` (80 extents) +
    `unk_12BCC` (6 reaches), `unk_13A1A` (6 words), `1471A` (5x4 words), `14744`
    (8 handlers), `Race_TrackObjectTypeTable` (19x8), `unk_147FC` (128 bytes),
    `unk_155A4` (ptr + sentinel, unread), `unk_155AC` (3-byte header + 8x4 + `$FF`),
    `unk_155D0` (18 ptrs), `unk_15618/1C/24` (4/8/8 bytes).
  - New `U-0012`..`U-0016`: shadow bias, `$E/$10` curve wrap, track-object record
    fields, `sub_14DEC` always `d0=0`/no caller, `unk_12168` consumer.
  - Removed `sub_13D44 equ` from `src/core/unknown.asm`; no renames.
  - Updated: `race_ai.md`, `race_anim_audio.md`, `race_data_tables.md`,
    `identifiers.md` (R30 rows), `unknowns.md`, `coverage.md`,
    `docs/modules/race_ai.md`, `docs/modules/race_anim_audio.md`, `docs/callgraph.md`.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean.

- `tasks/race_understanding_program.md` updated after R30: status is now in progress;
  added a completed-baseline section, marked rows 0-4 done, added
  `race_R30_integration.md`, retyped L3/L4 as contract/dynamic, narrowed L7, and
  updated the infrastructure table (`race_dump.py`, `ram_diff.py`, `race_map.md` now
  exist). Acceptance criteria now require R30 contracts and `U-0012`..`U-0016`
  closure/deferral.
- Next stage planned (plan session, docs only; no `src/` change):
  - `tasks/race_L2_control_b.md` revised: records the partial E2 pre-run
    (`analysis/notes/L2b_demo_trace.txt`, frozen before frame 300), three split runs,
    forced branch checks (bit3, forced curve limit, forced steering), pad injection via
    `0xBE6C`, and a normal-mode `U-0011` spawn run.
  - `tasks/race_R30_integration.md` created: matrix v4/v5 delta, `$3C` write-only vs
    timer conflict, crash/fall contracts, `unk_14744`/`unk_147FC`/`unk_12168`/
    `unk_155D0` consumers, `U-0012`..`U-0016` triage.
  - `tasks/race_understanding_program.md` status, partial-E2 section and queue rows
    5-6 updated.
- L2 dynamic pass (`tasks/race_L2_control_b.md`) completed with five fresh headless
  runs (`analysis/capture_L2b_e2a/e2a2/e2b/e2b2/spawn.gdb`; traces in
  `analysis/notes/L2b_*`). The crashed pre-run was not reused.
  - E2-1 `[confirmed]`: word `$18`; upshift `+E` / downshift `+1A` thresholds;
    same-call 1->2->1 oscillation at Speed `$1882`; forced Speed `$2F00` -> gear 5 ==
    max 5 -> `$14=$FFFB`.
  - E2-2 `[confirmed]`: steering sign drives `$42`/`$0C`;
    `$0C=(FrameDistance>>8)*$42>>8`.
  - E2-3 `[confirmed]`: on-road TP0 and the CLR branch; forced `d1=$100` ->
    `$3E=(limit<<8)/(d0>>8)` and `$68` bit5. TP2/TP3 selection remains `[static]`.
  - E2-4 `[confirmed]`: Left/Right steering sign; B -> `$68` bit1, A -> bit2.
  - E2-5 `[confirmed]`: off-road `$14 -= $14>>2` (`$22` -> `$1A`).
  - `U-0011` closed: normal-mode spawn path reached (6 calls), `d4=0` on all.
  - Docs: matrix v4 and E2 results/capture rows in `race_map.md`; `race_speed.md`,
    `race_ai.md`, `race_movement.md`, `identifiers.md`, `unknowns.md`, `coverage.md`
    updated; `tasks/race_L2_control_b.md` Result/Handoff filled.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` -> 62
    slices OK; `git diff --check` clean. No `src/` changes; no renames.

- R30 integration (`tasks/race_R30_integration.md`) completed; docs-only plus source
  comments. Matrix v5 in `docs/analysis/race_map.md` now has the crash/fall handler
  contracts, the four R30 handler tables with consumers, and the track-object
  record/type-table decode.
  - `$3C` conflict resolved: write-only curve-step snapshot, **not** a timer.
  - `$78` corrected: `sub_14456` (`$78`) and `sub_1446E` (`$1E`) arm it, so the
    `word_14742` limit branch in `Race_UpdateBikeCurve` **is reachable** during a fall
    (the earlier "unreachable" claim was wrong).
  - `$08` is dual-use (curve sample while riding, signed Y velocity on the on-foot /
    shadow-follow path); `$0E/$10` are actor-only write-only advance/index fields
    (the old rows had cited `sub_12414`'s **object** fields).
  - `U-0012` confirmed (`$8/$22` roles, `$20` fixed shadow stand-off; `sub_1131A` has
    no caller); `U-0013` confirmed (`$E/$10`; 256-entry buffer `$FFDC58-$FFDE57`,
    forward wrap `$FFDE58`, backward wrap `$FFDD56`); `U-0014` confirmed (record and
    type-table fields); `U-0015` wontfix (`sub_14DEC` vestigial, no caller);
    `U-0016` wontfix (`unk_12168` dead data).
  - Updated: `race_map.md`, `race_ai.md`, `race_anim_audio.md`, `race_speed.md`,
    `race_data_tables.md`, `identifiers.md`, `unknowns.md`, `coverage.md`, module
    cards, `tasks/race_understanding_program.md`, task Result/Handoff.
  - Source comment corrections only (`sub_1131A`, `sub_11A5E`, `sub_13D44`,
    `Race_UpdateBikeCurve`, `sub_14DEC`, `unk_12168`, `Race_TrackObjectTypeTable`);
    no renames.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean; comment-stripped `src/` diff identical.

- L3 static pass (`tasks/race_L3_ai_contracts.md`) completed; docs-only, no `src/`
  changes and no renames.
  - `race_ai.md` has the L3 frame order and per-function L0-L2 contracts for
    `Race_UpdateActorAI`, `Race_AdvanceActorProgress`, the target pipeline, steering,
    `Race_UpdateActorActions`, `Race_DispatchActorAction` and static dispatch.
  - Target buckets are Y bands: `bucket = clamp(($30>>6)+3,0,5)`, offsets
    `-$A0..$A0` step `$40` (`unk_12D0A`); counts cleared by `sub_1383E` before the AI
    loop, registered by `Race_SetupActorSprite` (normal) and
    `Race_BuildTargetCandidates` (static).
  - `$74` assignment: player 0; opponents from definition byte1 (1..18); static
    respawn nibble 0..15. Profiles 17/19 never assigned. Per-level `name=profile`
    pages and the five behavior families are in `race_ai.md`.
  - `ram_FF1A96` = `unk_259B6[level-1]` = `[2,3,3,3,4]` dispatch budget;
    `ram_FF1A98` counts the actors that took the `+4` slot per frame.
  - `Race_StaticActionTable` decoded: 16 `handler/speed/Y-offset` entries; all
    handlers `Race_ClampActorY`; `sub_138CE` uses the pair at respawn,
    `Race_UpdateStaticActions` only the handler.
  - Dispatcher slots corrected: `+0` action0, `+4` action1 (dispatch), `+8`
    action2, `+C` action3, `+10` action4; `a4` at dispatcher entry is slot+4.
  - `race_map.md` has the L3 addendum, updated `$5A/$68/$74` rows and Experiment
    Pack E3; `coverage.md`, `identifiers.md`, `callgraph.md`, `race_data_tables.md`,
    `modules/race_ai.md` and `race_understanding_program.md` updated; task
    Result/Handoff filled.
  - Residual: `unk_25812` read in `Race_SetupActorSprite` is dead (`d2` unused);
    `Race_ActorNormalVariant` is profile-0 action1 and unreachable (player always
    takes base); target `$71=$10/$11` fixed bucket 2/5 is static-only.
- Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
  62 slices OK; `git diff --check` clean; no `src/` changes.

- L3 dynamic pass (`tasks/race_L3_ai_dynamic.md`) completed; docs-only plus capture
  scripts/traces, no `src/` changes and no renames. Scripts:
  `analysis/capture_L3_a.gdb`, `capture_L3_a2.gdb`, `capture_L3_b.gdb`,
  `capture_L3_b2.gdb`, `capture_L3_c.gdb`, `capture_L3_level.gdb`; traces in
  `analysis/notes/L3*`.
  - E3-1 `[confirmed]`: `Race_AddTargetCandidate` appends `$71` at
    `ram_FF1792[bucket*16+count]` and increments `ram_FF178A[bucket]`; demo bucket
    3 (`$30=$0020`) and 5 (`$30=$00A0`) match `clamp(($30>>6)+3,0,5)`.
  - E3-2 `[confirmed]`: forced PlayerA Speed `$7FFF`; base vs `slot+4` follows the
    nearest/budget rules; `ram_FF1A98` increments on every `+4` (nearest included)
    and never exceeds `ram_FF1A96`; profiles 17/19 never appear.
  - E3-3 `[confirmed]`: natural demo had 262 action3 (nearest mismatch) and 174
    action4 (nearest + `$5A=0`); zero action2 because every target was PlayerA.
    Forced non-player `a2` -> action2 (12 hits); forced `d0 >= d6` -> distance
    action3 (6 hits).
  - E3-4 `[confirmed]`: forced levels 1..5 load budgets `2,3,3,3,4`; demo level 1
    budget 2.
  - E3-5 `[confirmed]`: `$74` indexes `Race_StaticActionTable`; `$12/$46` match the
    entry speed/Y-offset (`$01/$07/$0D/$0E` sampled); timer -> `sub_13A26`.
  - Docs: matrix v6 + E3 results in `race_map.md`; `race_ai.md`,
    `race_data_tables.md`, `coverage.md`, `identifiers.md`, `modules/race_ai.md`,
    `race_understanding_program.md` and task Result/Handoff updated.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean.

- L4 impact/fall static+dynamic pass (`tasks/race_L4_impact_contracts.md`) completed;
  docs-only, no `src/` change, no renames. Matrix v7 in `docs/analysis/race_map.md`;
  full contract in `docs/analysis/race_impact.md`.
  - Pair collision: order/side/extents/reach; extent index
    `6*clamp(|$8>>4|,0,3)+2*clamp(($C>>3)+2,0,4)+side`; static extents `$37`/`$60`;
    attacker reach `$28` armed / `$19` unarmed, defender `$1A`; `$68` bit4 is the
    pair-contact/crash latch (`0x127EA`), `$68` bit0 the impact/speed-loss latch.
  - `Race_ApplyCollisionImpact` both branches `[confirmed]` (E4-F): deep contact
    (`$1C<$40`) `Speed $2000/$1000 -> $1400`, `BikeDamage=2`, event `$0A`, `$2C=2`,
    `$2A=$02+$30`, bit0; shallow (`$1C=$80`) Speed unchanged, no damage, event `$09`,
    `$2C=4`, `$32=ram_FF3040`, bit4 clear/bit0 set.
  - `Race_ExchangeCollisionSpeed`: delta ~0.1x speed difference, speeds equalize, X
    push `$7000`; ordinary deltas add 0 BikeDamage (`ScaleImpactDamage=abs>>11`).
  - `ram_FF1768` is "current player in a crash/fall animation" (damage suppressed
    while set), not "riding".
  - `$5C` is **stamina**: HUD bar (`RaceHud_DrawStamina`), regen toward `ram_FF18AA=$A00`
    (player) / `ram_FF18A8=$500`, consumed by `Race_ApplyFallKnockdown`
    (`$5C -= PairImpact*ram_FF18AC`; underflow -> `$54=$11`). `RaceActor_TileBase`
    is a misnomer (rename proposed).
  - `Race_ApplyCrashImpact` (`0x11B7A`) documented as the separate lean-over crash
    (`DemoMode==0`, damage `ScaleImpactDamage(Speed)>>2`), distinct from `sub_140EE`.
  - E4-A demo survey (3600 frames): 9 pair impacts (1 player), 6 clamps, 3 exchanges,
    0 knockdown stores, 0 `sub_140EE`/`sub_141AE`/`sub_14404`, 0 `0x14486`. R30 crash
    timing remains `[static]`; the demo never crashes.
  - E4-B `[confirmed]`: `delta=1*$10=$10`; `$100->$0F0` (no fall); `$08->0` with
    `$54=$11`, `$6E=0`, `$6F=$FF`, bit4, event `$0F`; a2 underflow + `a1=PlayerA`
    reached the `$0D` store.
  - New `U-0017` (opponent stamina regen cap: `ram_FF18A8` vs graphics `+$E`).
  - Updated `race_impact.md`, `race_map.md` (v7 + E4), `combat.md`,
    `race_anim_audio.md`, `coverage.md`, `identifiers.md` (L4 + stamina/RAM rows),
    `unknowns.md`, `race_understanding_program.md`, task Result/Handoff.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean.

- L5 spawn/lifecycle pass (`tasks/race_L5_spawn.md`) completed; docs-only, no `src/`
  change, no renames. Matrix v8 + E5 in `docs/analysis/race_map.md`; full contracts in
  `docs/analysis/race_spawn.md`.
  - Four populations: player; 7 loop opponents + opponent free list; reserved
    `ram_FF1F2A` (index 1, `Race_ActorList[1]`); static pair `$FF2EAA/$FF2F2A`
    (indices `$10/$11`); extra `$FF2FAA` (index `$12`).
  - `Data5` corrected: normal list `ram_FFD7D4` -> `Race_AddStagedObjects` (track
    objects); special list `ram_FFDBD8` -> `sub_13BF4` (reserved opponent). Special
    byte 2 is the colour/page byte from `off_B98A`, not a traffic/level byte.
  - `sub_13BF4`: rating gate (`Rating*(scale-ram_FF1B34)`, `ram_FF1B36` latch) and
    special-list path; `sub_13CFE` sets graphics `$75 = LevelIndex+4` and type from
    `Race_ActorLevelBase[LevelIndex-1]`. `Race_RecycleActor` resets
    `ram_FF1B34/36` when `Menu level == Race_ram_LevelIndex`.
  - Static cycle: `sub_138CE` assigns `(Rand&$FFF)*unk_13A1A[level]>>16` timer,
    palette/side, `$74` profile and `Race_StaticActionTable` speed/offset; expiry ->
    `sub_13A26` at `PlayerProgress+$208000`; `Race_ClampActorY` clears bit6 past
    `$210000`. The old "static layout anomaly" was the inactive reset state.
  - Extra slot: `Race_BuildTrackObjects` writes `ram_FF1B30` for `shape $186`;
    `ram_FF1B30=$FFFF` deactivates, `>= $1C` and `ProgressSnapshotB >= $708` inits
    X `(progress_integer+marker-1)<<16`, Y `±(Rand&$7FF)`, Speed `$1770`, palette
    0/2, then `Race_UpdateExtraStaticActor` steers/clamps.
  - E5 (`analysis/capture_L5*.gdb`, `analysis/notes/L5*_trace.txt`): expansion lists
    (normal `00A70218...`, special `02D6022F,FFFFFFFF`); forced special spawn
    (`ram_FF1F2A` X `$02D60000`, page 2, lane `$E0`, Speed `$050C`); static profiles
    `0E,01,07,0D,05` and 3 respawns; extra init X `$02060000`, Y `$FEC8`, 130 updates.
    Natural traffic spawn was not exercised (631 race ticks, active count 8).
  - Updated `race_spawn.md`, `race_actors.md`, `race_ai.md`, `race_track_data.md`,
    `race_map.md`, `coverage.md`, `identifiers.md` (25 L5 rows), module card,
    `tasks/race_L5_spawn.md` and `tasks/race_understanding_program.md` (now L5 done,
    next L7).
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean.

- L7 results/HUD/animation pass (`tasks/race_L7_results_hud.md`) completed; docs-only,
  no `src/` change and no renames. Matrix v9 in `docs/analysis/race_map.md`.
  - HUD contract: cell `2*(y*64+x)`, word `$8000|palette<<13|tile`; BCD time,
    packed place (`1..9`, `$10..$16`), 8-unit stamina/HP cells with
    green/yellow/red thresholds; name/place timer quirk (`Rank` updates only in the
    negative/name phase).
  - `RaceHud_NeedleScript` decoded: 32 one-sprite frames at `$7DF30` (tilemap
    `$7E070`); speed `min(speed/453,31)`; RPM `((speed<<16)/divisor)/682`,
    `divisor=(curve[gear]<<2)&$FFFF`. Odometer font = 32-byte digit tiles loaded by
    `Race_LoadHUD`.
  - Results pipeline: `Race_ComputeStandings` event keys ->
    `Race_SortResults` (`value<<16|actorIndex`, `value=(key>>8)/6`, `$FFFF` DNF) ->
    best place/points (`unk_D1A0[place]*level`) to career+money -> outcome ->
    `Race_BuildStandings` (4 rows: place, points, time/DNF, name) ->
    `Race_UpdateHighScoreTable` -> `MenuPassword_CreatePassword`.
  - `unk_15CE0`/`unk_15CFC` are AnimState-3 crash scripts (tiles `$B9..$BE` /
    `$BF..$C4`): `d3=$26>>8` vs `d4=|$22|` picks `unk_15CFC` when `d3<d4`;
    otherwise `unk_15CE0` on the "behind" relative side (`$69` bit3 vs player
    progress), else the default `unk_155D0[FallState]` AnimState-3 script (`$15CC4`).
  - E7-A: HUD snapshot (place `$15`, BCD time, stamina `$0500`, HP `$8430`,
    name timer/rank `$2A/$0E`; forced place changes bump the timer).
  - E7-B: close -> `unk_15CFC`/`$B2`; behind -> `unk_15CE0`/`$B1`; ahead/mismatch ->
    `$15CC4`/`$B0`.
  - E7-C/C2: forced non-demo finish at frame 305 reached
    `Race_ComputeStandings`/`Race_ComputeResults`/`Race_BuildStandings`; place
    `$0F`, points 1, money `100->101`, career `0->1`, outcome `$0F`.
  - Updated: `race_hud.md`, `race_results.md`, `race_ai_road.md`,
    `race_anim_audio.md`, `animation.md`, `race_map.md` (v9), `coverage.md`,
    `identifiers.md` (+40 rows), module cards, program queue.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean.

- L6a world pass (`tasks/race_L6_world_a.md`) completed; `src/` changes are comments
  only and the ROM stayed byte-identical. Matrix v10 in `docs/analysis/race_map.md`.
  - Camera/progress: `$68` bit4 clear -> `CameraOffset=0`; otherwise `$6E<2` adds
    `FrameDistance>>4` (negated on `$69` bit3) clamped at `-$7000`, `$6E>=2` decays
    `off -= off>>2`. `PlayerProgress = PlayerA.X - $8000 - CameraOffset`;
    `$1E60 = 3*PosY/4` (`$1E7A` has no writer); `$1E64 = ($32>>1)+$5D` (`$1E7E` has
    no writer); `$1E66` = low word of `$1E64`, `$1E6A` = low word of `PlayerProgress`.
    The `$1E60` smoothing block through `$1E86` is dead (skipped).
  - VScroll: 16-byte blocks `[cmd,HV,reg7,vsramA,vsramB,next,+C,+E]`; block 0 is the
    VBlank entry, `$10..$80` the HInt bands and `$90` the sentinel. A compaction pass
    uses `+E` (negative skip, `<=8` merge) and recomputes the `$8Axx` line gaps.
    E6 runtime chain is `$10->$20->$50->$60->$70->$80->$90` (the `$30/$40` bands are
    compacted away). `ram_FF3274` is `ram_FF3236[31]`, the horizon line.
  - HScroll: 4 bytes/line `[plane A fg, plane B bg]`; plane A three bands
    (`$30EA`, `HIntVScroll/2+$30FA`, `HIntVScroll+$30F2`), plane B four bands
    (`$30EE`, zero gap, `HIntVScroll/4+$30FE`, `3*HIntVScroll/4+$30F6`). Lines
    `$98..$D7` cleared, `$D8..$E7` get `-((PlayerA.X>>9)&$C0)`, rest untouched.
  - `Race_IntegrateTrackCurve` emits 32 strips; `$1E54/$1E56` sums, `$1E58/$1E5A`
    scaled bytes, `$1E50/$1E52` combined values; `$1E6C` current curve byte.
  - New `U-0018` (exact VScroll compaction arithmetic); no renames.
  - Captures: `analysis/capture_L6a.gdb`, `capture_L6a_hint.gdb`,
    `capture_L6a_camforce.gdb`; traces `analysis/notes/L6a*`.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` -> 62
    slices OK; `git diff --check` clean; comment-stripped `src/` diff identical.

- L6b object/projection/visible-list static pass (`tasks/race_L6_world_b.md`)
  completed; docs-only, no `src/` change and no renames. Matrix v11 in
  `docs/analysis/race_map.md`.
  - Frame assembly: `ram_FFDE72=0` -> special -> track-start -> actor builder
    (`ram_FF1B48` actor count) -> track stream (`ram_FF1B4A` delta) -> staged list
    -> `$FFFFFFFF` terminator -> `Road_BuildVisibleList` -> `Road_DrawObjects`.
  - `Road_ObjectArray` (`$FFD37C`, 0x14-byte records, max 51) field writes are
    documented per producer; `ram_FFDE72` is the count.
  - Projection contracts: `Race_ProjectObject` (generic; returns
    `d0=scale,d1=X,d2=Y,d3=row`), `Race_ProjectActorObject` (near actor, fractional
    X interpolation), `Race_ProjectActorSprite` (far behind), `Race_ProjectTrackObject`
    (`ram_FF3236/FF31D2/D77C` row tables + lane offset). Clip windows recorded.
  - Track stream: word0 `[rowCount][shape base]`, word2
    `[step-1][flags:3][lane]`; shape `$186` marker (`ram_FF1B30/$1B2E`), `$205` gap,
    `$1BB..$1E9` -> `(shape,shape+1)` pair, `$1EA+` remaps `+$2F`.
  - `Road_BuildVisibleList` is a signed ascending long insertion sort of
    `ram_FF1B50` into `ram_FF1C50` with word indices in `Road_VisibleObjectList`
    (`$FF1D50`); `Road_DrawObjects` draws in that order. Producers store
    `objectX-progress` (near actor/track/staged) and `progress-actorX` (far sprite);
    the mixed-sign visual result is left to E8.
  - New `U-0019`: `RoadObject_Flags` low 5 bits carry the projected row; L6c/E8
    later showed the pass count is the high byte `(Flags >> 8) & 7` (closed).
  - Updated: `race_ai_road.md`, `race_physics.md`, `race_map.md` (v11),
    `coverage.md`, `identifiers.md` (+18 rows), `unknowns.md`, module card,
    `tasks/race_understanding_program.md`, task Result/Handoff.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean.

- L6c world pass (`tasks/race_L6_world_c.md`) completed; docs-only + captures, no
  `src/` change and the ROM stayed byte-identical.
  - Shape header: normal `P+0/P+1` controls, `P+2/P+3` fill, `P+4+` rows; special
    `P+0/P+1/P+2` projection/width, `P+2/P+3` controls, `P+4/P+5` fill, `P+6+` rows.
  - Left interpolator emits per-byte source advances (`ram_FF0D2E`) and
    `ram_FF132E = columns-1`; right emits per-row advances (`ram_FF102E`) and
    `ram_FF1330 = rows-1`; `ram_FF1332` is the half-width seed; `ram_FF135E` the clip.
  - Writer is column-major: `base + 4*r + c*(gap+4) + k`; 4 bytes = 4bpp bitplanes
    of one 8-pixel scanline. `DE6A=$7C` (full-band gap, stride `$80`), `DE66=$5C`
    (tail-band gap, stride `$60`), `DE68=$200` (32-row band advance).
  - Byte proof: shape `$56` (`base=$FF511C`, `src=$059952`, scale `$10000`,
    `132E=4`, `1330=$35`) replays 1080/1080 writer bytes identical to
    `analysis/golden/shape_writer_after.bin`; range `$FF511C..$FF5573`.
  - Data4 `+0`: bits 0-6 selector (`$186+`, pair `$1BB..$1E9`, `+$2F` remap, `$205`
    skip), bits 8-12 run-1, bit14 -> `Flags` bit15 facing, bit15 -> side parity,
    bit7 -> side seed. `+$02`: bits 12-15 spacing-1, bits 8-10 copy-pass count,
    low byte -> record `+$10`; bit11 unused.
  - `U-0019` closed: `Flags` low 5 = projected row; `(Flags>>8)&7` (bits 10-8) =
    SAT copy-pass count. E8-B `$FFD430` (`flags=$1184`, pass=1, row=4) copied 6
    entries once; pass=0 objects skip the copy loop.
  - E8-A live offset lists match the generators for `$56`, `$57`, `$1C3` (incl.
    scale `$145D0`); E8-C `ram_FF1C50` is ascending and `ram_FF1D50` is the draw order.
  - Artifacts: `analysis/capture_L8_a/b/c.gdb`, `analysis/notes/L8a/b/c_trace.txt`;
    `road_render.md`, `road_shapes.md`, `race_track_data.md`,
    `shape_writer_verify.md`, `race_map.md` (v12/E8), `identifiers.md` (25 rows),
    `unknowns.md`, `ram-map.md`, `coverage.md`, module cards and the program updated.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean.

- Residual unknown pass (`tasks/race_residual_unknowns.md`) completed; docs + source
  comments only, ROM byte-identical. Matrix v13 in `docs/analysis/race_map.md`.
  - `U-0017` closed: `ram_FF18A8=$500` is the shared stamina baseline, not the
    per-actor cap. The generic `Race_UpdateActorActions` loop adds `FrameDelay` while
    `$5C+FrameDelay < $500`, then restores the `Race_ActorGraphicsTable` page maximum
    `+$E` (`$500/$640/$780/$8C0/$A00` for pages 0..3/4..9). The player is skipped by
    that loop outside demo mode and regenerates in `Race_UpdatePlayerAnimation` toward
    `ram_FF18AA=$A00` (its spawn override).
  - `U-0017` dynamic evidence: `analysis/capture_L8_u17.gdb` forced a page-1 opponent
    `$640 -> $4F0`; it then regrew `$4F7 -> $4FE -> $640` exactly at the `$500`
    threshold (`analysis/notes/L8u17_trace.txt`).
  - `U-0018` closed: `+E` is the band line (`HV=(E<<8)-$A0`). Four phases: negative
    `+E` elides into block 0; `+E<=8` merges into `$10` (`E10=max(E,4)`); `+E<=E10+8`
    merges into `$20` (`E20=max(E,E10+4)`); the gap loop writes
    `$8A00+E(next2)-E(next)-1` while the block after next is below `$90`. The E6
    numbers (`$8A1D/$8A0D/$8A13/$8A54/$8AFF`, chain `$10->$20->$50->$60->$70->$80->$90`)
    match the formula exactly.
  - Updated: `unknowns.md`, `race_physics.md`, `race_impact.md`, `race_ai.md`,
    `race_map.md`, `identifiers.md`, `coverage.md`, the module card, the program file,
    and source comments in `race_ai.asm`/`race_anim_audio.asm`/`race_physics.asm`.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean; comment-stripped `src/` diff identical.

- Race acceptance (`tasks/race_acceptance.md`) completed; docs-only, no `src/` change
  and no renames. `docs/analysis/acceptance.md` created with scope, the A1-A7 checklist
  (all pass), registry/marker audit, function/table/formula coverage, residuals
  R-01..R-13 (all waived, non-blocking) and out-of-scope workstreams.
  - Audit: `callgraph.md` race range = 275 functions, 0 missing from the analysis
    docs; `U-0001`..`U-0019` all `confirmed`/`wontfix`; no `@UNKNOWN` in `src/`;
    every matrix open-question cell is now `none`, a documented dead/write-only field,
    or a waived residual.
  - Matrix v13 wording cleaned for the stale v1 open-question cells
    (`$02/$08/$0A/$16/$1A/$2A/$2C/$2E/$46/$54/$58/$5E/$60/$62/$66/$6A/$6E/$6F/$70/$76/$77/$78`);
    base table retitled.
  - Updated `docs/analysis/coverage.md` (race areas accepted, Phase 2/3/7 done,
    non-race phases open), `docs/INDEX.md`, `tasks/race_understanding_program.md`
    (status complete for race scope, queue row 16 done) and this file.
  - Verification: `./build.sh` -> `Matched OK` (786432 bytes); `assets.py check` ->
    62 slices OK; `git diff --check` clean; no `src/` changes.

## Historical open questions (snapshot)

## Unverified / open questions

- Race scope is accepted (`docs/analysis/acceptance.md`); R-01..R-13 are waived,
  non-blocking residuals. The items below remain optional visual/audio follow-ups or
  race residuals kept for orientation.
- L7 residuals (non-blocking): `RaceBike_ram_Parameters` gear-curve values/RPM
  scaling, odometer-font pixel art, and a native-console visual check of the results
  screen (`E7-C` exercised the computation but not the rendering).
- No static unknowns remain from the `U-0004`/`U-0007`/`U-0008`/`U-0009` block. Only
  optional dynamic/visual confirmation remains (see the visual TODOs below).
- `U-0012`..`U-0016` are closed (matrix v5). Residual: `Race_TrackObjectTypeTable`
  byte `+1` is unread (role unknown); `unk_155D0` animation scripts unlabeled.
  L4/E4 confirmed impact damage/knockdown; only the R30 crash-path timing
  (`sub_140EE`/`sub_141AE`) stays `[static]` because the demo never crashes.
  `U-0017` (opponent stamina regen) is closed by the residual pass. `U-0018` (VScroll
  compaction) is also closed (matrix v13). `U-0019` (object `Flags` row vs.
  copy-pass bits) is closed by L6c/E8: low 5 bits = row, bits 10-8 = SAT passes.
- L5 residual (non-blocking): visual roles of the reserved `ram_FF1F2A` opponent and
  the `$FF2FAA` extra actor remain hypotheses; a natural free-list traffic respawn was
  not exercised by the demo (E5-6).
- `U-0011` is closed (E2 normal-mode spawn, `d4=0`). Residual L2 `[static]` items:
  TP2/TP3 limit selection and `$40` LeanCurve.
- L3 residual: the action3 cooldown>0 variant and the `$69` bit4 attack-phase branch
  were not sampled; action2 is unused in the demo because every target was PlayerA.
  The E3-5 table index was verified from `$74` and the stored fields because `d0`
  was occasionally interrupt-clobbered at the `0x1397E` breakpoint.
- `src/screens/race_results.asm` line-by-line pass completed (all 6 functions +
  `DrawString` + the 5 unreferenced tail blocks, comment-only). `./build.sh` -> `Matched OK`
  (786432 bytes); `assets.py check` -> 62 slices OK.
- Confirmed and documented in `race_results`: `and.w ($8).w` in both negative-money
  portrait paths masks the RNG with the high word of the bus-error vector at `$000008`
  (`$0000` in this ROM), so the negative tables always use the first record of each pair
  while the RNG still advances.
- `MenuPassword_StrPasswordStatus+4` is the status-box height field. `RaceResults_Init`
  rewrites the header to y=22, x=14, height=5, width=12; negative money subtracts 2 from
  the height, hiding the two password rows. The 16-byte row clears overlap the 12-byte
  stride but are overwritten by the next row.
- Start in `RaceResults_GameTick` exits while held; A/B/C use the new-press edge.
  The results tail ($6C94-$6DBF) is a byte-identical copy of the unreferenced
  `endlevel.asm` tail; `unk_6D00` is ASCII with bit 7 set ("You aren't ready for").
- Authorized renames applied in this pass: `RaceResults_TitleTiles`,
  `RaceResults_BustedTitleTiles`, `RaceResults_TrackImagePtrs`,
  `RaceResults_TrackImageOffsets`, `RaceResults_TrackNametableOffsets`,
  `RaceResults_TrackPaletteOffsets`, `RaceResults_StrNextLevelShort`,
  `RaceResults_StrNotReadyEncoded`, `RaceResults_StrNotReadyTail`,
  `RaceResults_StrContinuePlay`, `RaceResults_StrNextLevel`,
  `RiderIntro_PortraitPanel`, `Message_ram_DynamicRecord`,
  `Race_ram_PlayerAOutcome`, `Race_ram_PlayerBOutcome`. `ram_FF0682` was removed by the
  user before the pass; the code now uses `MenuPassword_StrPasswordStatus+4`.
- `docs/analysis/identifiers.md` extended with 42 new race_results rows and two
  existing rows updated (functions, RAM, tables, dead strings, VDP macros).
- `docs/analysis/race_results.md`, `docs/modules/race_results.md`, `docs/ram-map.md`
  and `tasks/race_results_line_by_line.md` updated.

- Visual-only TODOs remain: exact race-card layout/stride and the 30 s demo path; password
  cursor palette toggle and panel swap; message dpad icon layout, `$2FF` blank-tile
  appearance and blink cadence; optional endlevel composed-screen and animation-cadence
  capture; final shape-art crop/catalogue (which `Road_ShapeTable` IDs are sprites vs.
  scenery) and the marking/rearview visuals.
- `ram_FF07C2`/`ram_FF082E`→`Shop_StrLeftBike`/`Shop_StrRightBike` are proposed in
  `identifiers.md` but not applied (they live in `ram_const.asm`; separate rename task).
  `Message_ram_DynamicRecord` and `RiderIntro_PortraitPanel` are now applied.
- Whether all docs/index descriptions are accurate: review when using each file.
- Existing analysis TODOs and open questions remain in the individual docs.


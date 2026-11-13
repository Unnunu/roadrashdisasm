# Program: complete race understanding

Status: in progress. L1 and L2 (static + dynamic), the R30 gap disassembly, the
R30 integration, and the L3 static + dynamic passes (E3) are complete. Next is L4
impact/fall (`race_L4_impact_contracts.md`). This file is the roadmap, not a build
task; the queue below lists what remains.

## Goal

Reach complete semantic understanding of the race subsystem (`src/race/*`,
`src/data/race_*.asm`) without speculative naming: every high-fan-in actor/RAM field
has a confirmed owner and meaning, every race function has an L0-L2 contract, and
semantic hubs have L3 detail plus dynamic evidence.

## Confirmed decisions

1. **Simulation first.** L1-L5 and L7 are the primary branch. Road/render/shapes (L6)
   is a separate branch that can run later or be interleaved, but it does not block
   gameplay semantics.
2. **Line-by-line only for semantic hubs.** Contract + dynamic snapshots + table
   decoders are enough elsewhere. Full line-by-line of all `src/race/*` is out of
   scope.
3. **Dynamic evidence model.** The agent runs headless BlastEm/GDB captures. The user
   can describe scenarios in words and, at most, set an execution breakpoint and read
   memory/registers. User observations are tagged `[dynamic]`/`[user-report]` and must
   agree with static evidence before driving a rename.

## Completed baseline (R30)

The remaining `dc.b` code in the race subsystem is now real instructions; no further
disassembly pass is planned for these ranges.

- `src/race/race_ai.asm` `0x1131A`-`0x13DDF`: `sub_1131A`, `sub_11A5E`, `sub_12B2A`,
  `sub_133F0`, `sub_135E8`, `sub_13704`, `sub_13A5C`, `sub_13D44`; dead blocks
  `$11F54`/`$139AC` kept byte-exact.
- `src/race/race_anim_audio.asm` `0x140BC`-`0x14486`: `sub_140BC`, `sub_140EE`,
  `sub_141AE`, `sub_142B0/BE/CC`, `sub_142FE`, `sub_1436E`, `sub_14404/56/6E`,
  `sub_14DEC`, `sub_15580`; dead `$15458` block kept byte-exact.
- Tables formalized: `unk_12168`, `unk_12B7C`/`unk_12BCC`, `unk_13A1A`, `unk_1471A`,
  `unk_14744`/`unk_147FC`, `Race_TrackObjectTypeTable`, `unk_155A4`, `unk_155AC`,
  `unk_155D0`, `unk_15618/1C/24`.
- R30 integration (`race_R30_integration.md`) resolved these statically: `U-0012`
  (shadow stand-off / `$8/$22` roles), `U-0013` (`$E/$10` + curve-buffer wrap),
  `U-0014` (track-object record/type-table fields), `U-0015` (`sub_14DEC` vestigial),
  `U-0016` (`unk_12168` dead data). See matrix v5 in `race_map.md`.
- Docs: `docs/analysis/race_ai.md`, `race_anim_audio.md`, `race_data_tables.md`,
  `identifiers.md` (R30 rows), `unknowns.md`, `coverage.md`, module cards, `callgraph.md`.

R30 does not replace the L3/L4/L7 contracts: it provides the disassembled bodies and
table layouts those layers still have to explain and corroborate.

## L2_b pre-run (partial, not a result)

`analysis/notes/L2b_demo_trace.txt` holds a partial E2 run from
`analysis/capture_L2b_demo.gdb`. It is `[dynamic]` partial evidence only:

- E2-1: word `$18` and the upshift sequence observed (1->2->3, thresholds `$1838`,
  `$1BBC`); the max-gear `$FFFB` branch and the downshift cutoff were not sampled. One
  actor toggled gear each frame at a speed between the two thresholds; the fresh run
  later confirmed this is real same-call hysteresis.
- E2-3: only the `CLR` branch was reached; the limit store at `0x13FC0` never ran.
- E2-5: `$68` bit3 was never set, so `$14 -= $14/4` was not exercised.
- E2-2 and E2-4 were not scripted.
- The run froze before frame 300 (`unmapped read from 825BB6`).

`race_L2_control_b.md` was revised accordingly: three short runs, forced branch checks
(bit3, forced curve limit, forced steering), pad injection, and a normal-mode spawn run
for `U-0011`.

## L2 dynamic results (E2, completed)

`race_L2_control_b.md` completed with fresh split runs; matrix v4 in `race_map.md`. The
crashed pre-run was not reused.

- E2-1 `[confirmed]`: word `$18`; `+E`/`+1A` thresholds; same-call 1->2->1 oscillation
  when Speed lies between the upshift and downshift thresholds; max gear -> `$14=$FFFB`.
- E2-2 `[confirmed]`: lean sign follows steering; `$0C=(FrameDistance>>8)*$42>>8`.
- E2-3 `[confirmed]`: on-road TP0 sampled; forced limit reaches
  `$3E=(limit<<8)/(d0>>8)` and sets `$68` bit5. TP2/TP3 selection stays `[static]`.
- E2-4 `[confirmed]`: Left/Right steering sign; B -> `$68` bit1, A -> bit2.
- E2-5 `[confirmed]`: off-road `$14 -= $14>>2`.
- `U-0011` closed: normal mode reached the spawn path; `d4=0` on all calls.

Residual L2 `[static]` items to carry into R30/L3: TP2/TP3 selection and `$40`
LeanCurve.

## L3 static results (contracts, E3 pack)

`race_L3_ai_contracts.md` completed as a docs-only pass; `race_map.md` has the L3
addendum and Experiment Pack E3.

- Frame order: `sub_1383E` clears candidate counts; `Race_UpdateActorAI` moves actors
  and registers candidates; `Race_UpdateStaticActors` registers static actors;
  `Race_UpdateActorActions`/`Race_UpdateStaticActions` dispatch afterwards.
- Target pipeline: `SetupActorSprite`/`BuildTargetCandidates` ->
  `AddTargetCandidate` -> `FindTargetActor`/`ScanTargetDistance` ->
  `UpdateActorSpeedCurve` -> `SteerTowardTarget`/`UpdateActorRoadSteering`.
  Buckets are Y bands (`unk_12D0A` = `-$A0..$A0` step `$40`), not actor types.
- `$74` assignment: player 0; opponents from definition byte1 (1..18); static
  respawn random nibble (0..15). Profiles 17/19 are never assigned. The five
  behaviour families are decoded (`+8` FollowPath vs StateCollision, `+C`
  Throttle vs RoadCenter, `+10` combat action).
- `ram_FF1A96` = `[2,3,3,3,4]` per-level dispatch budget; `ram_FF1A98` counts the
  actors that took the `+4` slot per frame.
- `Race_StaticActionTable` = 16 `handler/speed/Y-offset` entries; `sub_138CE` uses
  the pair at respawn, `Race_UpdateStaticActions` uses only the handler.
- Dispatcher slot offsets corrected: `+0` action0, `+4` action1 (dispatch),
  `+8` action2, `+C` action3, `+10` action4; `a4` at dispatcher entry is slot+4.
## L3 dynamic results (E3, completed)

`race_L3_ai_dynamic.md` completed; matrix v6 in `race_map.md` integrates the E3
captures.

- E3-1 `[confirmed]`: `Race_AddTargetCandidate` stores `$71` at
  `ram_FF1792[bucket*16+count]` and increments `ram_FF178A[bucket]`; demo buckets
  3/5 match `clamp(($30>>6)+3,0,5)`.
- E3-2 `[confirmed]`: with PlayerA Speed forced to `$7FFF`, nearest actors and
  actors while `ram_FF1A98 < ram_FF1A96` take `slot+4`; the counter increments on
  every `+4` (nearest included) and never exceeds the budget.
- E3-3 `[confirmed]`: natural demo = 262 action3 (nearest mismatch) and 174 action4
  (nearest + expired cooldown); forced non-player target = action2; forced
  `d0 >= d6` = distance-based action3. No natural non-player target occurred.
- E3-4 `[confirmed]`: levels 1..5 load budgets `2,3,3,3,4`.
- E3-5 `[confirmed]`: `$74` indexes `Race_StaticActionTable`; `$12/$46` match its
  speed/Y-offset; timer expiry reaches `sub_13A26`.

## Out of scope

- Audio/Z80 and the engine-audio mapping (separate workstream). Only the RAM fields
  consumed by audio are named.
- Asset re-splitting; the byte-exact build is already done.
- Cosmetic renames not backed by `[confirmed]` evidence.

## Evidence rules

Follow `docs/reverse-engineering.md` and `docs/line-by-line-analysis.md`.

- `[static]` code/data, `[dynamic]` emulator observation, `[user-report]` user-described
  scenario, `[confirmed]` static + dynamic agree, `[hypothesis]` untested.
- Only `[confirmed]` may drive a rename; renames are a separate build-verified batch.
- Unknown gaps get an `@UNKNOWN(U-xxxx)` row in `docs/analysis/unknowns.md`.
- Every session verifies `./build.sh` (`Matched OK`), `python3 tools/assets.py check`,
  and `git diff --check`.

## Dataflow spine (what affects what)

```
Pad (Race_GetInput)
  -> steering ($68 bits) + attack state ($69/$6B/$6C/$6D/$5A)
  -> lean/curve ($42, $3E/$40, Race_UpdateLeanCurve)
  -> speed/gear ($14/$18; Race_UpdateActorSpeedState/Gear)
  -> actor movement ($12,$26,$1E,$04; $36-$3C,$30,$00)
  -> AI target/action (bucket -> dispatcher -> handler)
  -> pair collision/impact (extents $4A-$56, speed exchange, damage $5C, fall $54)
  -> PlayerProgress/camera (Race_UpdateCamera)
  -> road profile/object list/visible list
  -> render (planes/HScroll/SAT/tiles) + HUD
  -> nearest opponent/place -> results/standings/money
```

## Layers and study order

| Layer | Scope | Why this order |
|---|---|---|
| L0 | Frame timeline: `Race_Init`/`Race_Update`/`Race_GameTick`/`Race_FinishFrame`, buffers, gates | Prerequisite for interpreting any snapshot |
| L1 | Actor struct, shadow/backup, creation/activation/recycle | 80% of fields and all AI/combat references |
| L2 | Input -> speed/gear/lean/curve | Defines player motion |
| L3 | AI loop -> target buckets -> dispatcher -> action handlers | Defines opponent behavior |
| L4 | Pair collision, impact, damage, fall, club transfer | Consequences of control/AI actions |
| L5 | Spawn/traffic/static/police lifecycle | Who is on the track |
| L6 | Camera -> road profile -> objects -> projection -> shapes -> render | World and picture; parallel branch |
| L7 | HUD, animation data, standings/results/money/highscore | Consumers of simulation state |

Rule: L1 must close before L2-L5; L6 may run in parallel; L7 last.

## Field ownership matrix

The central artifact is a table in `docs/analysis/race_map.md` with one row per actor
offset:

| Offset | Width | Current symbol | Writer(s) | Reader(s) | Evidence | Blocking question |
|---|---|---|---|---|---|---|

The matrix must distinguish actor fields from identically-numbered fields in buffers
(`Race_ram_CurrentVScrollInfo`, object records, HUD buffers). Raw `aN` offset greps
are not evidence until the base register is identified.

## Infrastructure

| Tool / file | Purpose | Status |
|---|---|---|
| `tools/race_dump.py` | Decode a 64 KiB work-RAM dump into actor/static/extra/object/visible-list tables with symbol names | exists |
| `tools/ram_diff.py` | Diff two dumps, group changes by known structure/region | exists |
| `tools/field_usage.py` | Fan-in and actor-offset survey | exists; ownership upgrade optional |
| `tools/address_refs.py`, `tools/disasm.py`, `tools/roundtrip.py` | Static xrefs and validated disassembly | exists |
| `tools/road_shapes.py` | Shape data split | exists; decoder extension in L6 |
| `analysis/*.gdb` | Existing capture scripts | exists; reuse, do not duplicate blindly |
| `docs/analysis/race_map.md` | Dataflow, timeline, field matrix, capture matrix, study order | exists (matrix v5 + L3 addendum) |

## Session organization

One session = one task file from `tasks/_template.md`.

- **Plan sessions** update this program and write the next task file.
- **Build sessions** read `STATE.md` + one task, do static work first, emit at most one
  batched Experiment Pack if needed, integrate evidence, verify, update Result/Handoff
  and `STATE.md`.
- If user evidence is required, close with status `WAITING`; the next session resumes
  the same task.
- Split a task when it needs more than one durable artifact or exceeds roughly 30 tool
  calls / 50k tokens.
- Do not mix phases and do not leave half-applied renames.
- Commit only on explicit request.

## Session queue (orientation, not fixed)

Rows 0-8 are complete and kept for orientation. R30 disassembled the L3/L4 handler
bodies and tables, so those tasks are now contract/dynamic work, not disassembly.

| # | Task file | Layer | Work type | Deliverable |
|---|---|---|---|---|
| 0 | `race_understanding_program.md` + `race_map_and_tools.md` | - | done | roadmap + first task |
| 1 | `race_map_and_tools.md` | A | done | `race_map.md`, `race_dump.py`, `ram_diff.py` |
| 2 | `race_L1_actor_core_a.md` | L1 | done | field matrix v1 + Experiment Pack E1 |
| 3 | `race_L1_actor_core_b.md` | L1 | done | field matrix v2; E1 integrated |
| 4 | `race_L2_control_a.md` | L2 | done | speed/lean/curve static contract; matrix v3 + E2 |
| 5 | `race_L2_control_b.md` | L2 | done | matrix v4; E2-1..E2-5 dynamic; `U-0011` closed |
| 6 | `race_R30_integration.md` | L1/L4/L7 | done | matrix v5: `$3C` conflict resolved (not a timer), crash/fall contracts, handler tables, `unk_155D0` consumers; `U-0012`..`U-0016` closed |
| 7 | `race_L3_ai_contracts.md` | L3 | done | loop/targets/dispatcher contract + `$74` pages/families + E3 pack |
| 8 | `race_L3_ai_dynamic.md` | L3 | done | matrix v6; candidate/slot/budget/branch/level/static-respawn E3 results |
| 9 | `race_L4_impact_contracts.md` | L4 | static + E4 | pair collision/extents/reach + R30 crash paths (`sub_140EE`/`sub_141AE`/`sub_14404`) |
| 10 | `race_L4_impact_dynamic.md` | L4 | integrate E4 | damage, `$5C`, fall/knockdown |
| 11 | `race_L5_spawn.md` | L5 | static + E5 | lifecycle/static/police closed |
| 12 | `race_L7_results_hud.md` | L7 | static + doc | results/standings/HUD; animation-script consumers `unk_15CE0`/`unk_15CFC` |
| 13 | `race_L6_world_a.md` | L6 | static + E6 | camera/progress/VScroll/HScroll |
| 14 | `race_L6_world_b.md` | L6 | static | object list/projection/visible list |
| 15 | `race_L6_world_c.md` | L6 | static + E7 | shape/pixel map, Data4/5 |
| 16 | `race_acceptance.md` | I | verify | acceptance criteria, `Matched OK` |

L6 may be reordered before/after L3-L5 once L1 is closed. L1-L5/L7 are the priority.

## Experiment Pack format

One pack per session, at most about five checks. BlastEm console syntax: bare hex for
`b`, `p/x $address` for memory.

```
Goal:        hypothesis A vs B
Scenario:    level/track/input/visible outcome
Breakpoint:  bare-hex PC (exec only; no watchpoints)
Commands:    p/x $ff1eaa   ; actor base
             p/x $ff1ebc   ; Speed
             p/x $ff1ec4.b ; flags
Report:      pc, a0/a1 and values, or a plain description of what is visible
Decision:    if X -> A; if Y -> B
```

If a scenario cannot be reproduced, record `[hypothesis]` and move on. Do not invent
behavior from an inconclusive run.

## Acceptance criteria

- No unexplained high-fan-in actor/RAM field: the ownership matrix has no `TODO` row
  for fields used by two or more functions.
- Every race function has an L0-L2 contract; L3 for semantic hubs.
- Every action handler has a confirmed behavior family and a `$74` profile mapping.
- Impact/damage, fall/knockdown, spawn/recycle, and results/standings formulas are
  documented and dynamically corroborated where possible.
- L6 has a documented row/tile/shape map; L7 has results and animation data.
- Every R30 function has an L0-L2 contract and its actor/RAM fields are in the
  ownership matrix; `U-0012`..`U-0016` are closed (matrix v5).
- `./build.sh` -> `Matched OK`; `assets.py check` -> all slices OK; `git diff --check`
  clean.

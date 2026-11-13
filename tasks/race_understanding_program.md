# Program: complete race understanding

Status: in progress. L1 (static + dynamic), L2 static, and the R30 gap disassembly are
complete. This file is the roadmap, not a build task; the queue below lists what
remains.

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
- Static roles are inferred but not dynamically confirmed: `U-0012` (shadow bias),
  `U-0013` (`$E/$10` curve wrap), `U-0014` (track-object record fields), `U-0015`
  (`sub_14DEC` `d0=0`, no caller), `U-0016` (`unk_12168` consumer).
- Docs: `docs/analysis/race_ai.md`, `race_anim_audio.md`, `race_data_tables.md`,
  `identifiers.md` (R30 rows), `unknowns.md`, `coverage.md`, module cards, `callgraph.md`.

R30 does not replace the L3/L4/L7 contracts: it provides the disassembled bodies and
table layouts those layers still have to explain and corroborate.

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
| `docs/analysis/race_map.md` | Dataflow, timeline, field matrix, capture matrix, study order | exists (matrix v3) |

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

Rows 0-4 are complete and kept for orientation. R30 disassembled the L3/L4 handler
bodies and tables, so those tasks are now contract/dynamic work, not disassembly.

| # | Task file | Layer | Work type | Deliverable |
|---|---|---|---|---|
| 0 | `race_understanding_program.md` + `race_map_and_tools.md` | - | done | roadmap + first task |
| 1 | `race_map_and_tools.md` | A | done | `race_map.md`, `race_dump.py`, `ram_diff.py` |
| 2 | `race_L1_actor_core_a.md` | L1 | done | field matrix v1 + Experiment Pack E1 |
| 3 | `race_L1_actor_core_b.md` | L1 | done | field matrix v2; E1 integrated |
| 4 | `race_L2_control_a.md` | L2 | done | speed/lean/curve static contract; matrix v3 + E2 |
| 5 | `race_L2_control_b.md` | L2 | integrate E2 | matrix v4; close `U-0011` via normal-mode spawn path |
| 6 | `race_R30_integration.md` | L1/L4/L7 | static + doc | fold R30 into matrix v4: `$3C/$66/$6A/$6B` timers, crash/fall branches, handler tables, `unk_155D0` |
| 7 | `race_L3_ai_contracts.md` | L3 | static + E3 | loop/targets/dispatcher contract + `$74` matrix; R30 gap handlers and `unk_12168` |
| 8 | `race_L3_ai_dynamic.md` | L3 | integrate E3 | handler behavior, `$5A/$6C/$6D/$69`; close `U-0012`/`U-0013`/`U-0016` |
| 9 | `race_L4_impact_contracts.md` | L4 | static + E4 | pair collision/extents/reach + R30 crash paths (`sub_140EE`/`sub_141AE`/`sub_14404`) |
| 10 | `race_L4_impact_dynamic.md` | L4 | integrate E4 | damage, `$5C`, fall/knockdown; close `U-0014`/`U-0015` |
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
  ownership matrix; `U-0012`..`U-0016` are closed or explicitly deferred with evidence.
- `./build.sh` -> `Matched OK`; `assets.py check` -> all slices OK; `git diff --check`
  clean.

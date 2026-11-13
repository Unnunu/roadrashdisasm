# Race subsystem acceptance

- **Status:** accepted for the race scope (`src/race/*`, `src/data/race_*.asm`).
- **Matrix:** v13 in `docs/analysis/race_map.md`.
- **Program:** `tasks/race_understanding_program.md`.
- **Evidence tags:** `[static]` (source/data), `[dynamic]` (emulator capture),
  `[user-report]`, `[confirmed]` (static + dynamic agree), `[hypothesis]` (untested).
- **Rule:** this audit changes no behavior, applies no renames, and waives only the
  documented residuals below.

## Scope

In scope: L0 frame timeline, L1 actor struct, L2 input/speed/lean/curve, L3 AI
targeting/dispatch, L4 collision/impact/fall, L5 spawn/lifecycle, L6 world/render and
L7 HUD/results/animation for the race subsystem, including their data tables.

Explicitly out of scope (own workstreams, do not block this acceptance):

- visual catalogues/crops: shape art, rearview/marking appearance, race-card layout;
- `rom_assets` asset-tail identification/bounds/consumers;
- audio/Z80 driver, sequencer and sound data;
- non-race screens (menus, shop, high-score, endlevel, rider intro, message);
- cosmetic renames that have no `[confirmed]` evidence change (separate batch).

## Verification

Run from the repository root:

| Command | Result |
|---|---|
| `./build.sh` | `Matched OK: 786432 bytes of 786432 bytes` |
| `python3 tools/assets.py check` | `asset check OK: 62 slices match baserom.md` |
| `git diff --check` | clean (exit 0) |
| `grep -rn "@UNKNOWN" src/` | no matches |
| `git status --short` | docs only (no `src/` change) |

## Acceptance criteria

Each program criterion is restated as a checklist row.

| # | Criterion | Evidence artifact | Verdict |
|---|---|---|---|
| A1 | No unexplained high-fan-in actor/RAM field; the ownership matrix has no unresolved `TODO` row for a field used by two or more functions. | `race_map.md` matrix v13 + addenda; all open-question cells are `none`, a documented dead/write-only field, or a waived residual below | pass |
| A2 | Every race function has an L0-L2 contract; L3 detail for the semantic hubs. | `docs/callgraph.md` race range (275 entries) cross-checked against `docs/analysis/race_*.md`, `road_*.md` and the module cards: 0 missing; L3 addendum and L3/E3 in `race_ai.md`/`race_map.md` | pass |
| A3 | Every action handler has a confirmed behavior family and a `$74` profile mapping. | `race_ai.md` profile pages/families; `Race_ActorProfileTable`, `Race_ActorActionTable`, `Race_StaticActionTable`; E3 in `race_map.md` | pass |
| A4 | Impact/damage, fall/knockdown, spawn/recycle and results/standings formulas are documented and dynamically corroborated where possible. | `race_impact.md`, `race_spawn.md`, `race_results.md`; E4/E5/E7; R30 crash timing waived (R-06) | pass (with R-06) |
| A5 | L6 has a documented row/tile/shape map; L7 has results and animation data. | `road_render.md`, `road_shapes.md`, `race_track_data.md`; `race_hud.md`, `race_results.md`, `animation.md`; matrix v9/v12 | pass |
| A6 | Every R30 function has an L0-L2 contract and its actor/RAM fields are in the matrix; `U-0012`..`U-0016` are closed. | `race_R30_integration.md`; `race_map.md` v5; `race_ai.md`, `race_anim_audio.md`, `race_data_tables.md` | pass |
| A7 | Build/asset/diff verification stays clean. | table above | pass |

## Registry and marker audit

- `docs/analysis/unknowns.md` contains `U-0001`..`U-0019`; every row is `confirmed` or
  `wontfix`. No ID is open.
- No `@UNKNOWN` marker remains in `src/`. The last marker batch (`U-0017`/`U-0018`)
  was closed by `race_residual_unknowns.md`.
- `identifiers.md` open rows are rename proposals only. Renames are a separate,
  build-verified batch; they are not semantic gaps.

## Function and table coverage

| Area | Contract evidence | Dynamic evidence |
|---|---|---|
| L0 loop/init/results gates | `race.md`, `race_map.md` timeline | E7-C forced finish |
| L1 actor struct/cloning/lists | `race_actors.md`, matrix v1-v2 | E1 (`capture_L1b_*`) |
| L2 input/speed/gear/lean/curve | `race_speed.md`, matrix v3-v4 | E2 (`capture_L2b_*`) |
| L3 targeting/dispatch/actions | `race_ai.md` L3 addendum | E3 (`capture_L3_*`) |
| L4 collision/impact/fall | `race_impact.md`; R30 tables | E4 (`capture_L4_*`) |
| L5 spawn/lifecycle | `race_spawn.md` | E5 (`capture_L5*`) |
| L6 camera/objects/projection/shapes | `race_physics.md`, `race_ai_road.md`, `road_render.md`, `road_shapes.md` | E6 (`capture_L6a_*`), E8 (`capture_L8_a/b/c`) |
| L7 HUD/needle/results/standings | `race_hud.md`, `race_results.md`, `animation.md` | E7 (`capture_L7_*`), E8 |

Handler/table coverage:

- `Race_ActorActionTable` profile groups and the five behavior families (`+8`, `+C`,
  `+10`) are decoded in `race_ai.md`; profiles 17/19 are unassigned and
  `Race_ActorNormalVariant` (profile-0 action1) is unreachable.
- `Race_StaticActionTable` (16 handler/speed/Y-offset entries), `unk_14744` and
  `unk_147FC` consumers are decoded in `race_ai.md`/`race_data_tables.md`.
- `Race_TrackObjectTypeTable` (19 x 8) and `unk_155D0` (18 FallState pointers) have
  documented fields and consumers in `race_data_tables.md`; residuals R-01/R-02.

## Formula set

| Formula | Where |
|---|---|
| `FrameDistance = Speed * FrameDelay`; `X += FrameDistance` | `race_physics.md` (actor movement section) |
| gear thresholds `+E`/`+1A`; off-road `$14 -= $14>>2` | `race_speed.md` |
| lean `$0C = (FrameDistance>>8)*$42>>8`; curve `$3E = (limit<<8)/(d0>>8)`; LeanCurve `$40` | `race_speed.md` |
| AI target buckets `clamp(($30>>6)+3,0,5)`; dispatch budget `Race_ram_ActionDispatchBudget` | `race_ai.md` |
| pair extent `6*clamp(\|$8>>4\|,0,3)+2*clamp(($C>>3)+2,0,4)+side` | `race_impact.md` |
| impact classes: deep `$1C<$40`, shallow `$1C=$80`; stamina `$5C -= PairImpact*$18AC` | `race_impact.md` |
| spawn timers `(Rand&$FFF)*unk_13A1A[level]>>16`; static respawn `PlayerProgress+$208000` | `race_spawn.md` |
| standings key `value=(key>>8)/6`, `$FFFF` DNF; points `unk_D1A0[place]*level` | `race_results.md` |
| HUD cell `2*(y*64+x)`, word `$8000\|palette<<13\|tile`; speed `min(speed/453,31)`; RPM `((speed<<16)/divisor)/682` | `race_hud.md` |
| VScroll/HScroll band arithmetic and shape writer `base + 4*r + c*(gap+4)` | `race_physics.md`, `road_render.md` |

## Waived residuals

None of these blocks race acceptance: each has documented consumers or a complete
static contract, and the missing part is dynamic sampling, data labeling or visual
art.

| ID | Residual | Evidence tag | Blocking? |
|---|---|---|---|
| R-01 | `Race_TrackObjectTypeTable` byte `+1` (values 0/1/2) is not read by any consumer; its role is unknown. | `[static]` `race_data_tables.md` | no: unused byte |
| R-02 | `unk_155D0` targets (`$1562C-$15918`) are decoded pointers but the animation scripts are not individually labeled. | `[static]` `race_data_tables.md`, `race_anim_audio.md` | no: consumers decoded; labels only |
| R-03 | L2 TP2/TP3 curve-limit selection (`0x13F96`/`0x13F78`) is static-only; E2 sampled TP0. | `[static]` `race_speed.md`, `race_map.md` E2-3 | no: branch conditions documented |
| R-04 | `$40` LeanCurve was not sampled in E2; its formula is static. | `[static]` `race_speed.md` | no |
| R-05 | L3 action3 with cooldown `>0` and the natural `$69` bit4 attack-phase branch were not sampled; forced traces reached action2/3/4 and `$69` bit4 -> action4. | `[static]`+`[dynamic]` `race_ai.md` | no |
| R-06 | R30 crash-path timing/damage (`sub_140EE`, `sub_141AE`) and `Race_ApplyCrashImpact` are static-only; the 60 s demo never crashes. | `[static]` `race_impact.md` | no: formulas static; crash path non-demo |
| R-07 | Reserved opponent `ram_FF1F2A` and extra actor `$FF2FAA` visual/narrative roles are hypotheses (police/traffic/pacer). | `[hypothesis]` `race_spawn.md` | no: lifecycle confirmed |
| R-08 | Natural free-list traffic/opponent respawn was not exercised (E5-6; 631 race ticks, active count 8). | `[static]` `race_spawn.md`, E5 | no: spawn path decoded |
| R-09 | `RaceBike_ram_Parameters` gear-curve values/RPM frame scaling, odometer-font pixel art and exact HUD palette entries. | `[static]` `race_hud.md` | no: formula + assets decoded; art only |
| R-10 | Results rendering was not visually checked (E7-C exercised the computation and reached the pipeline). | `[dynamic]` `race_results.md` | no: computation confirmed |
| R-11 | Dead/unreachable code/data: `Race_ActorNormalVariant` profile-0 slot, profiles 17/19 never assigned, `unk_25812` dead read, `unk_12168` dead, `unk_155A4` loaded-not-dereferenced. | `[static]` `race_ai.md`, `race_data_tables.md` | no: byte-exact, documented |
| R-12 | `$6E/$6F/$70` non-crash animation state/frame/timer visual mapping; `$0A` shape-flag bits other than bit14; `$2C` impact-magnitude nuance. | `[static]` `race_map.md`, `race_anim_audio.md` | no: field roles documented |
| R-13 | Remaining race-scope rename proposals (`identifiers.md`, `rename-later`) are not applied. | `[static]` `identifiers.md` | no: naming batch only |

## Documentation hygiene

- `race_map.md` (matrix v13) is the authoritative field matrix; older analysis pages
  cite it and no longer carry stale pre-L2 TODO wording (corrected in the
  docs-hygiene pass). Status is centralized in `coverage.md`; module cards are thin
  routers.
- `U-0017`/`U-0018` are closed in `race_residual_unknowns.md`; `U-0019` is closed by
  L6c/E8. `race_impact.md` no longer lists the stamina cap as needing a sample.
- Experiment/capture detail moved to `race_captures.md`; actor movement merged into
  `race_physics.md`; shape-writer verification merged into `road_render.md`.

## Acceptance statement

The race subsystem meets A1-A7 for its defined scope. Phase 7 is closed for the race
branch; the remaining open phases in `coverage.md` are non-race (runtime/IRQ, screens
visuals, audio, asset tail). Optional follow-ups are the visual catalogues, the audio
workstream and the rename batch.

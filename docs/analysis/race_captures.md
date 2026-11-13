# Race captures and experiment log

Dynamic evidence index for the race subsystem. Contract text lives in `race_map.md`
and the per-area analysis pages; this page keeps the experiment setups, results and
capture matrix so they can be pruned or replayed independently.

| Pack | Area | Result location |
|---|---|---|
| E1 | L1 actor fields (`$00/$30/$36`, `$22`, `$34`, `$3C`, collisions) | this page (§E1) |
| E2 | L2 input/speed/gear/lean/curve | this page (§E2) |
| E3 | L3 targeting/dispatch/budget/static respawn | this page (§E3) |
| E4 | L4 impact/fall | `race_map.md` L4 addendum; `race_impact.md` |
| E5 | L5 spawn/lifecycle | `race_map.md` L5 section; `race_spawn.md` |
| E6 | L6a camera/VScroll/HScroll | `race_map.md` L6a addendum; `race_physics.md` |
| E7 | L7 HUD/results | `race_map.md` L7 addendum; `race_hud.md` |
| E8 | L6c shape/SAT writer | `race_map.md` L6c addendum; `road_render.md` |

## Experiment Pack E1 (residual L1 fields)

At most five checks; run in `race_L1_actor_core_b.md`. Breakpoints are bare hex PC.

```
E1-1  $00 vs $30 draw-Y split
Goal:        confirm $00 = absolute screen Y and $30 = drawY - RoadYTarget
Scenario:    demo race, steering frames
Breakpoint:  0x10FDE (after clamp, before neg d1)
Commands:    p/x $ff1eaa+$00 ; p/x $ff1eaa+$30 ; p/x $ff1eaa+$36
Report:      $00, $30, $36 and the instruction's d1
Decision:    if $00-$36 == $30 -> confirmed; otherwise keep the $00/$30 row open

E1-2  $22 Y-correction role
Goal:        confirm $22 is applied to $00 by sub_113A4/sub_113CA
Scenario:    pair contact / road-band overshoot
Breakpoint:  0x10FDE
Commands:    p/x $ff1eaa+$22 ; p/x $ff1eaa+$00
Report:      $22 before/after and the $00 delta
Decision:    if delta($00) == delta($22) -> confirmed

E1-3  $34 shape variant
Goal:        confirm $34 is the signed shape/lean selector consumed by the selectors
Scenario:    lean left/right and a crash frame
Breakpoint:  0x14486 (Race_ApplyCollisionImpact) and a Race_SelectActor*Shape entry
Commands:    p/x $ff1eaa+$34 ; p/x $ff1eaa+$08 ; p/x $ff1eaa+$0A
Report:      $34/$08/$0A and the selected shape pointer
Decision:    if the selector uses $34 as an index/sign -> confirmed

E1-4  $36-$3C accumulator roles
Goal:        confirm $36 is an accumulator and $3C is write-only
Scenario:    normal steering frames
Breakpoint:  sub_115C6 entry (0x115C6)
Commands:    p/x $ff1eaa+$36 ; p/x $ff1eaa+$38 ; p/x $ff1eaa+$3A ; p/x $ff1eaa+$3C
Report:      the four words before/after the call
Decision:    if only $38/$3A/$3C change and $36 changes elsewhere -> confirmed

E1-5  d4 at Race_SetupActorSprite (U-0011)
Goal:        find the value of d4 on the AI path and at spawn
Scenario:    one AI frame and one opponent spawn
Breakpoint:  0x13746 (Race_SetupActorSprite entry)
Commands:    p/x $d4 ; p/x $ff1eaa+$30 ; p/x $ff1eaa+$72
Report:      d4 and whether the extra candidate buckets are valid
Decision:    if d4 is stable per-path -> close U-0011 as ambient-but-deterministic
```


## Experiment E1 results (dynamic)

Runs: `analysis/capture_L1b_demo_survey.gdb`, `capture_L1b_fields.gdb`,
`capture_L1b_shapes.gdb`, `capture_L1b_shape_sign.gdb`, `capture_L1b_d4.gdb`; traces in
`analysis/notes/L1b_*`.

| Check | Breakpoint / window | Observed | Decision |
|---|---|---|---|
| E1-1 `$00/$30/$36` | `0x10FDE`/`0x10FE4`, demo PlayerA | `d1 = $36-$00`; stored `$30 = $00-$36` (e.g. `$00=$FF57`, `$36=$FFEC`, `$30=$FF6B`) | confirmed |
| E1-2 `$22` | `0x113C4`, demo PlayerA | `$22 == d0` before the add (`d0=$FFF6`); the next frame's `$00` moved by it | confirmed |
| E1-3 `$34` | `0x101E6`/`0x1022C`/`0x10254`, demo | `$34=+1` -> flip 0; `$34=-1/-2` -> flip `$8000`; forced steering `±$600` left `$34=0` | confirmed |
| E1-4 `$36-$3C` | `0x10F6C`/`0x115C6`, demo | `$36/$38/$3A` update inside movement; `$3C` receives `sub_115C6`'s `d1` and is never read | confirmed |
| E1-5 `d4` | `0x13746`, full demo | 4169 calls, all AI path (`ret=0x10FE8`), `d4=0`; no spawn (`ret=0x16E24`) calls | AI path closed; spawn open |

### Demo collision/crash survey

A full 60 s demo (`capture_L1b_demo_survey.gdb`) counted the contact/crash entry points:

- pair Y-overlap branch `0x127EA`: 9 hits, one involving `RacePlayerA`
  (`a1=$FF1EAA`, `a2=$FF242A`);
- object/static impact `0x14486`: 0 hits;
- crash impact `0x11B7A`: 0 hits — it is gated on `DemoMode == 0`
  (`race_ai.asm:227-236`), so the demo cannot enter the player crash path;
- `Race_ApplyFallKnockdown` `0x14C3C`: 6 pair entries, none with `RacePlayerA`.

Natural demo collisions therefore exist but are rare and never produce a player crash;
crash/fall experiments need a non-demo run.


## Experiment Pack E2 (L2 residual dynamic checks)

Run in `race_L2_control_b.md`. At most five checks; bare-hex PCs.

```
E2-1  word-width gear + upshift
Goal:        confirm $18 is a word and +E[gear] is the upshift threshold
Scenario:    demo race until Speed > $28A0 (or force Speed)
Breakpoint:  0x13AFE (read $E(a0,gear*2)) and 0x13B12 (store Gear)
Commands:    p/x $ff1eaa+$18 (word!) ; p/x $d1 ; p/x $ff1eaa+$12
Report:      gear word, d3 threshold, speed across the upshift
Decision:    if gear increments when Speed >= +E[gear] -> table layout confirmed;
             also confirm the max-gear -5 acceleration
             (a byte read here is the old artifact, not evidence)

E2-2  lean sign and $0C derivation
Goal:        confirm $42 sign and $0C = (FrameDistance>>8)*$42>>8
Scenario:    force RaceBike_ram_CurrentSteering = +$600 then -$600
Breakpoint:  0x13EA0 (entry) and 0x113CA
Commands:    p/x $ff38b0 ; p/x $ff1eaa+$42 ; p/x $ff1eaa+$0C
Report:      steering, $42, $0C for both signs
Decision:    if $42/$0C flip sign with steering -> confirmed

E2-3  curve-limit branch and selection
Goal:        confirm the limit source and (limit<<8)/(d0>>8)
Scenario:    normal + off-road frames; force $78 non-zero if reachable
Breakpoint:  0x13FC0 / 0x13FCE
Commands:    p/x $ff1eaa+$08 ; p/x $ff1eaa+$12 ; p/x $ff1eaa+$68
             p/x $ff302e ; p/x $ff3032 ; p/x $ff3034 ; p/x $14742
Report:      computed d0, selected limit, stored $3E/bit5
Decision:    if on-road uses TP0, off-road TP2, bit5+off-road TP3 ->
             confirmed; $78 lockout is a static no-writer exception

E2-4  input bit -> control flag mapping
Goal:        confirm B->$68 bit1, A->$68 bit2, Left/Right steering sign
Scenario:    inject pad frames (capture_natural_attack.gdb pattern) or play
Breakpoint:  0xBE56 after GetInputPlayerA, or read at 0x10E66
Commands:    p/x $ff1eaa+$68 ; p/x $ff38b0 ; p/x $ff1eaa+$12
Report:      $68 low bits and steering per held button
Decision:    if B sets bit1, A sets bit2, Left subtracts/Right adds -> confirmed

E2-5  off-road acceleration reduction
Goal:        confirm $14 -= $14/4 and the Speed>>8/downshift rule
Scenario:    enter off-road (Y clamp sets $68 bit3) or force bit3
Breakpoint:  0x10E8C / 0x10E9A and 0x13B6C
Commands:    p/x $ff1eaa+$14 (before/after) ; p/x $ff1eaa+$12
             p/x $ff1eaa+$68 ; p/x $ff1eaa+$18
Report:      acceleration before/after the 3/4 reduction; gear on downshift test
Decision:    if $14_after == $14_before - $14_before/4 -> confirmed
```

## Experiment E2 results (dynamic)

Runs: `analysis/capture_L2b_e2a.gdb`, `capture_L2b_e2a2.gdb`,
`capture_L2b_e2b.gdb`, `capture_L2b_e2b2.gdb`, `capture_L2b_spawn.gdb`; traces in
`analysis/notes/L2b_*`. Samples are PlayerA unless noted; forced values are recorded.

| Check | Breakpoint / window | Observed | Decision |
|---|---|---|---|
| E2-1 word gear/upshift | `0x13B12`, demo PlayerA | word gear 0->1->2->3; upshift `+E[0]=$125C`, `+E[1]=$1838`; downshift `+1A[1]=$1518`, `+1A[2]=$1BBC` | confirmed |
| E2-1 same-call oscillation | `0x13B12`/`0x13B24`, demo | at Speed `$1882`: 1->2 (`$1838`) then 2->1 (`$1BBC`) inside the same SpeedState call | confirmed (real hysteresis inversion) |
| E2-1 max gear | `0x13B68`/`0x13BB6`, forced Speed `$2F00` | gear 5 == max 5 -> `$14 = $FFFB` (-5) | confirmed |
| E2-2 lean/`$0C` | `0x13EA0` forced `±$600`, `0x113D8` | `+$600` -> `$42=+$DFB`, `$0C=+$B5`; `-$600` -> `$42=-$293`, `$0C=-$5B`; formula matches | confirmed |
| E2-3 curve limit | `0x13FB0`/`0x13FC0`/`0x13FCE` | on-road `d0=$5EC..$C2F` < TP0 `$E646` -> CLR; forced `d1=$100` -> `$3E = $10000/(d0>>8)` (`$2AAA`,`$3333`,`$4000`) and bit5 set | confirmed |
| E2-3 TP2/TP3 | `0x13F96`/`0x13F78` | TP2/TP3 selected by `$68` bit3/bit5; only TP0 sampled | static |
| E2-4 input flags | `0xBE6C` injection, `0xC00A` sample | Left `$04` -> steering `$FA00` (-`$600`); Right `$08` -> `+$390`; B `$10` -> `$68` bit1, Speed `$61C`; A `$40` -> `$68` bit2, Speed 0; release clears | confirmed |
| E2-5 off-road accel | `0x10E8C` forced bit3, `0x10E9C` | acc `$22` -> `$1A` (34 - (34>>2) = 26), bit3 set | confirmed |
| U-0011 spawn `d4` | `0x13746`, normal mode | 2175 calls; 6 from `ret=0x16E24`; `d4=0` on all; 0 non-zero `d4` | confirmed (spawn `d4=0`) |

Notes:

- The partial pre-run (`analysis/notes/L2b_demo_trace.txt`) froze before frame 300. Only
  its E2-1 word/pointer observations were reused; all results above come from fresh
  split runs with PlayerA-only breakpoints.
- The E2-1 oscillation follows from using `+E[old]` for the upshift and `+1A[new]` for
  the downshift in the same call. It holds the demo player at low gear until Speed
  exceeds the next downshift threshold.
- E2-3 forced `d1=$100` at `0x13FB0` only to reach the limit branch; the formula check
  does not depend on the forced value.
- U-0011 normal mode: `DemoMode` was forced to 0 after `Race_ram_Started` and B was
  injected at `0xBE6C`; the spawn path `Race_SetupActor` became reachable.

## Experiment Pack E3 (L3 residual dynamic checks)

Run in `race_L3_ai_dynamic.md`; at most five checks, bare-hex PCs.

```
E3-1  candidate bucket registration
Goal:        confirm bucket = clamp(($30>>6)+3,0,5) and the list append
Scenario:    demo race, PlayerA + opponents, one full frame
Breakpoint:  0x13812 (Race_AddTargetCandidate entry)
Commands:    p/x $d0 ; p/x $a1+$30 ; p/x $a1+$71 ; p/x $ff178a ; p/x $ff1792
Report:      bucket d0, actor $30/$71, counts before/after
Decision:    if d0 matches the clamped AnimIndex and the actor $71 lands in
             ram_FF1792[d0*16+count] -> confirmed; else candidate model is wrong

E3-2  profile slot choice (action0 vs action1)
Goal:        confirm base/+4 conditions and the Race_ram_ActionDispatchCount budget
Scenario:    normal and forced: nearest actor, rating <= player Speed, budget full
Breakpoint:  0x12FCE (+4 path) and 0x12FD8 (call site)
Commands:    p/x $a1 ; p/x $a1+$71 ; p/x $a1+$74 ; p/x $a1+$66
             p/x $ff1eaa+$12 ; p/x $ff1a96 ; p/x $ff1a98
Report:      actor pointer/index/profile/rating, player Speed, budget/counter,
             and whether the chosen a4 is slot+0 or slot+4
Decision:    if +4 only for PlayerB/nearest/budget-and-rating and the counter
             increments on every `+4` path (nearest/PlayerB too) and stays flat
             on the base path -> confirmed

E3-3  dispatcher action2/action3/action4
Goal:        confirm the three branch PCs and their conditions
Scenario:    force a non-player target; force NearestActor=a1 and $5A>0;
             set $69 bit4
Breakpoint:  0x164A2 (action2), 0x16510 (action3), 0x16518 (action4)
Commands:    p/x $a1 ; p/x $a2 ; p/x $a1+$5A ; p/x $a1+$69
             p/x $ff1908 ; p/x $ff1a68
Report:      branch PC, target, cooldown, attack-active flag, distance/threshold
Decision:    if non-player -> action2, close+cooldown(nearest) -> action3, and
             PlayerB/attack-active/final -> action4 -> confirmed

E3-4  per-level budget
Goal:        confirm Race_ram_ActionDispatchBudget = [2,3,3,3,4] and the per-frame +4 count
Scenario:    one normal frame on each level (or set Menu_ram_PlayerLevel)
Breakpoint:  0x12FD8
Commands:    p/x $ff0522 ; p/x $ff1a96 ; p/x $ff1a98 ; p/x $a1+$71
Report:      level, budget, counter, profile and actor per hit
Decision:    if the budget matches the level table and no frame exceeds it ->
             confirmed; profile 17/19 never observed -> dead entries

E3-5  static respawn profile/speed/Y-offset
Goal:        confirm sub_138CE indexes Race_StaticActionTable with $74
Scenario:    force a static actor respawn timer to expire
Breakpoint:  0x13972 (after profile/speed/Y writes) and 0x13982 (timer path)
Commands:    p/x $a2 ; p/x $a2+$71 ; p/x $a2+$74 ; p/x $a2+$12
             p/x $a2+$46 ; p/x $d0
Report:      profile nibble, speed/Y-offset written, table index used
Decision:    if $74 selects table[$74] and $12/$46 equal its speed/Y-offset ->
             confirmed
```

## Experiment E3 results (dynamic)

Runs: `analysis/capture_L3_a.gdb`, `capture_L3_a2.gdb`, `capture_L3_b.gdb`,
`capture_L3_b2.gdb`, `capture_L3_c.gdb`, `capture_L3_level.gdb`; traces in
`analysis/notes/L3*`.

| Check | Breakpoint / window | Observed | Decision |
|---|---|---|---|
| E3-1 candidate bucket | `0x13832`, demo | bucket 3 at `$30=$0020`, bucket 5 at `$30=$00A0`; `$71` written at `ram_FF1792[bucket*16+count]`; `ram_FF178A[bucket]` advanced | confirmed |
| E3-2 profile slot | `0x12FD8`/`0x12FCE`, forced Speed `$7FFF` | PlayerA and over-budget non-nearest actors stayed on the base slot; `a4=slot+4` for nearest actors and while `Race_ram_ActionDispatchCount < Race_ram_ActionDispatchBudget`; the counter incremented on every `+4` (nearest included) and never exceeded the budget | confirmed |
| E3-3 action2 | `0x164A2`, forced non-player `a2` | 12 hits; branch condition is `a2 != -1 && a2 != RacePlayerA`. Natural demo: 0 hits (every target was PlayerA) | confirmed forced; unused naturally |
| E3-3 action3 distance | `0x164F6`, forced `d0 >= d6` | 6 hits; `8(a4)` selected when `distance >= threshold` | confirmed forced |
| E3-3 action3 nearest/cooldown | `0x16510`, natural | 262 hits; sampled `near=0`, `$5A=0` -> nearest-mismatch path. Cooldown variant remains `[static]` | confirmed (mismatch) |
| E3-3 action4 | `0x16518`, natural | 174 hits; sampled `near=1`, `$5A=0`, `isPB=0` -> nearest with expired cooldown | confirmed |
| E3-4 per-level budget | `Race_LoadBikePalette` `0xCAAC`, forced levels 1..5 | budgets `2,3,3,3,4`; demo level 1 budget `2`; `Race_ram_ActionDispatchCount` never exceeded `Race_ram_ActionDispatchBudget` | confirmed |
| E3-5 static respawn | `0x1397E`/`0x1399E`/`0x139A4`, forced timers | `$74` selects `Race_StaticActionTable[$74]`; `$12/$46` matched its speed/Y-offset (`$0E -> $1B58/$FFEF`, `$0D -> $1770/$FFF8`, `$01 -> $1B58/$0010`, `$07 -> $1964/$000C`); timer expiry reached `sub_13A26` | confirmed |

Notes:

- The demo never produced a non-player target, so action2 and the distance-based
  action3 were reached only by forcing `a2`/`d0`; both agree with the static branch
  conditions and the older forced dispatcher trace.
- Profiles 17/19 were never assigned; the AI loop used profiles 0/6/8/9 in the demo
  sample. `Race_ram_ActionDispatchCount` stayed `<= Race_ram_ActionDispatchBudget` on every sampled frame.
- Forcing a high PlayerA speed (`$7FFF`) was needed because the demo opponents'
  ratings (`$1B58`+) exceed the early player speed; this isolates the slot/budget
  logic without changing the branch under test.


## Capture matrix

Existing snapshots live in `analysis/dumps/`; the breakpoints below are the ones
already used for them. New checks follow the Experiment Pack format in
`tasks/race_understanding_program.md`.

| Question | Breakpoint / fields | Decision |
|---|---|---|
| Creation field sources | `0xB72A` (`Race_InitActorPositions` entry): `$16/$66/$71/$73/$74/$75/$77`, `$5C/$5E/$60` | definition byte -> actor field mapping (`[dynamic]` confirmed) |
| Position initialization | `0xA544` after `Race_InitActorPositions`: `$00/$04/$1A/$1E/$30` | initial Y/X layout; `$04/$1E` share the start X |
| Running actor state | `0x10E66` (`Race_UpdateActorAI`, PlayerA `$12>0`): count/list, `$12/$14/$26`, `$30/$68/$69` | active/free split and speed/frame distance |
| Steering and lean | `0x10E66` with `RaceBike_ram_CurrentSteering=±$600`: `$42/$3E/$40/$3C`, `$69` | `$42` sign = lean; `$3E/$40` only under curve limit |
| Speed/gear loop | `0x10E66` every 10th frame: `$12/$14/$18/$68/$69/$3A/$3C/$4C/$4E` | accel vs gear branch; `$4C/$4E` extent flips |
| Off-road transition | `0x10E66` after 300 forced-left frames: `$68` bit3, `$30/$36/$00` | hard curve vs off-road bit |
| Road objects | running/`road_objects` dump: `$FFDE72` count, `Road_ObjectArray`, `Road_VisibleObjectList` | object count is `Road_ram_ObjectCount` (22 in the demo), not `Race_ram_TrackObjectCount` |
| Pair impact | `0x14486` (`Race_ApplyCollisionImpact`): `$1C/$2A/$2C/$2E/$54/$5C` | E4-F confirms both branches, Speed, BikeDamage, `$2A/$2C/$2E/$32`, event |
| E1-1/E1-4 actor fields | `0x10FDE`/`0x10FE4`/`0x10F6C`/`0x115C6`, demo PlayerA | `$30 = $00-$36`; `$36` accumulator; `$3C` write-only |
| E1-2 Y correction | `0x113C4`, demo PlayerA | `$22 = d0`, then `$00 += d0` |
| E1-3 shape variant | `0x101E6`/`0x1022C`/`0x10254`, demo | signed `$34` -> shape index + H-flip |
| E1-5 ambient `d4` | `0x13746`, full demo | 4169 AI-path calls, `d4=0`; no spawn |
| E2-1 gear word/upshift | `0x13B12`/`0x13B24`/`0x13B68`, demo + forced Speed | `$18` word; `+E`/`+1A`; same-call oscillation; max-gear `-5` confirmed |
| E2-2 lean sign/`$0C` | `0x13EA0`/`0x113D8`, forced steering `±$600` | `$42`/`$0C` sign and `(FrameDistance>>8)*$42>>8` confirmed |
| E2-3 curve limit | `0x13FB0`/`0x13FC0`/`0x13FCE`, forced `d1` | TP0 dynamic; formula and bit5 confirmed; TP2/TP3 static |
| E2-4 input flags | `0xBE6C` injected pad, `0xC00A` sample | B/A -> `$68` bit1/bit2, Left/Right steering sign confirmed |
| E2-5 off-road accel | `0x10E8C`/`0x10E9C`, forced bit3 | `$14 -= $14>>2` confirmed |
| U-0011 spawn `d4` | `0x13746`, normal mode | 6 spawn (`ret=0x16E24`) calls, `d4=0`; closed |
| E3-1 candidate bucket | `0x13832` | `$71` appended at `ram_FF1792[bucket*16+count]`; bucket 3/5 match `clamp($30>>6+3)` |
| E3-2 profile slot | `0x12FCE`/`0x12FD8` | forced Speed `$7FFF`: base at/over budget, `+4` for nearest or `count<budget`; counter clamps |
| E3-3 dispatcher | `0x164A2`/`0x164F6`/`0x16510`/`0x16518` | forced non-player target -> action2; forced distance -> action3; natural nearest-mismatch -> action3; nearest+expired cooldown -> action4 |
| E3-4 level budget | `0xCAAC` (forced levels 1..5) | budgets `2,3,3,3,4`; level 1 demo budget 2 |
| E3-5 static respawn | `0x1397E`/`0x1399E`/`0x139A4` | `$74` -> `Race_StaticActionTable[$74]`; `$12/$46` match speed/Y-offset; timer -> `sub_13A26` |
| Demo collision/crash | `0x127EA`/`0x14486`/`0x11B7A`/`0x14C3C`, full demo | 9 pair contacts (1 player), 0 crash/object, no player fall |
| E4-A demo L4 survey | `0x1487C`/`0x1496C`/`0x14C3C`/`0x14CEC`/`0x140EE`/`0x141AE`/`0x14404`/`0x14486` | 9 pair / 6 clamp / 3 exchange / 0 knockdown / 0 crash |
| E4-B knockdown arithmetic | `0x14C3C`/`0x14C54`/`0x14C5C`/`0x14C8C`/`0x14CAC` | `delta=PairImpact*$18AC`; fall at underflow, `$54=$11`, bit4, `$0F`/`$0D` |
| E4-D/E player exchange | `0x14CEC`/`0x14CFA`/`0x14D50`/`0x14D82` | player path reached; small delta -> 0 BikeDamage |
| E4-F forced static impact | `0x11EC4`/`0x11ED0` | deep and shallow `Race_ApplyCollisionImpact` confirmed |
| Static/extra actors | running dump: static `$16/$30/$46/$56/$74`; `$FF2FAA` `$71` | static lifecycle confirmed (E5); roles open |
| E5-1 `Data5` expansion | `0xB970` | normal/special lists, thresholds, colour cap |
| E5-2 reserved spawn | forced X, `0x13CFE` | special record -> `ram_FF1F2A`, page/lane/Speed |
| E5-3/E5-4 static cycle | `0x1397E`/`0x13A26` | timer/profile/palette/side + respawn |
| E5-5 extra actor | `0x10B2E`/`0x12972`/`0x12A86` | marker gate, init fields, updates |
| E5-6 natural spawn | `0x16AF6`/`0x16D2A`/`0x16D60`/`0x16CAE` | not exercised (631 ticks, count 8) |



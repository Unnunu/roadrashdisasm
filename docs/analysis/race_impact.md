# Race impact / fall contract (L4)

Scope: pair collision and contact geometry, damage/speed-exchange, fall and
knockdown, and the R30 crash handlers. This is the L4 contract for the simulation
spine (`docs/analysis/race_map.md`, matrix v7). Static contracts are derived from
`race_ai.asm`, `race_anim_audio.asm` and `race_combat.asm`; Experiment Pack E4 adds
the dynamic evidence.

## Entry paths

```
sub_1383E                 ; clear target counts
Race_UpdateActorAI        ; move actors
Race_UpdateStaticActors   ; move static actors
sub_11CC8 / sub_1218C     ; collision coordinators (L4)
  Race_UpdateActorPairCollision  ; pair test, sets ControlFlags bit4 (contact)
    -> Race_ApplyCollisionImpact ; static object / extra static / deep contact
    -> Race_UpdateActorPairImpact
         -> Race_ExchangeCollisionSpeed   ; large previous-X gap
         -> Race_ClampActorPairY          ; close pair, Y separation
            Race_StealClub / Mirror       ; attack/club transfer
            Race_AdjustActorTrackPositions
            Race_ApplyFallKnockdown       ; stamina underflow -> fall
    -> sub_12070 -> unk_14744          ; track-object handler (crash paths)
```

`ControlFlags` (`$68`) bit4 is the per-frame **contact/crash latch**: the pair test
sets it on both actors at `0x127EA`, and every crash handler sets it. The callers
(`sub_11CC8`, `sub_1218C`) test it to choose the impact/crash handler.
`ControlFlags` bit0 is the **impact/speed-loss latch** set by
`Race_ApplyCollisionImpact`, `Race_ApplyImpactSpeedLoss` and `sub_1438E`.

Important: `ram_FF1768` is "the current player actor is in a crash/fall animation"
(`AnimState` 0..3), not "riding". Normal riding has `AnimState = $FF`. While
`ram_FF1768 != 0`, `Race_ScaleImpactDamage` returns 0 and the crash handlers take the
event-only path, so a crash in progress cannot add damage again.

## Pair collision: `Race_UpdateActorPairCollision` (`0x124E2`)

Inputs `a1` (acting/player actor) and `a2` (other/static actor). Resets
`ram_FF1766 = 0`, `ram_FF1B16 = 0`.

1. **Order (X).** Compares `PreviousX` (`$1E`) of the two actors.
   - `a1.PrevX >= a2.PrevX` -> set `StateFlags` (`$69`) bit0.
   - X window: with `a1` ahead, contact needs `a1.X - ram_FF3038 < a2.X`; with `a1`
     behind, `a1.X + $6000 >= a2.X`. Otherwise `$1280A` clears bit4/bit7.
   - `ram_FF3038` is the X window: `$6000` for racing pairs, `$3700` for the extra
     static list, `0` otherwise.
2. **Side (Y).** Compares `$1A`. `a1.$1A >= a2.$1A` -> set `$69` bit1 (above).
3. **Extents.** `Race_GetCollisionExtent` (`0x12A88`) picks the actor table or the
   static rule:
   - actor (`$71 < $10`): `Race_GetActorCollisionExtent` indexes `unk_12B7C` with
     `index = 6*clamp(|$8>>4|,0,3) + 2*clamp(($C>>3)+2,0,4) + side(0/1)`; the byte
     is the Y extent. `$4A` gets the current side extent; `$4C`/`$4E` get the
     above/below extents (`d3=0`/`1`).
   - static (`$71 >= $10`): `$37` when `$71 < $12`, else `$60`.
4. **Reach.** Only if `StateFlags` bit4 (attack active), `AttackPhase == 1`, and the
   side bit is compatible: attacker reach from `Race_GetAttackerReach` = `$28` armed
   (`$6B` bit1) else `$19`; defender reach `$1A`. Result -> `$50`.
   `sub_12B2A` has the close-attack 6-byte table `unk_12BCC` (`$1A` except one 0)
   and sets `ram_FF1766`; its use is static-only.
5. **Overlap.** `$52` = penetration after the reaches; `$69` bit7 marks contact.
   `ram_FF1B16` is non-zero if any Y overlap exists.
6. **Contact latch.** If `ram_FF1B16 != 0`, the X penetration test is
   `a1.$32 - ram_FF303E - a2.$32 < 0` (`$32` = collision offset,
   `ram_FF303E = $40`). On contact it sets `ControlFlags` bit4 on both actors
   (`0x127EA`); otherwise it clears bit4 and both bit7s (`0x1280A`).

E4-B/E4-F exercised this latch: the static-object caller only invokes the impact
handler when bit4 is set.

## Pair impact: `Race_UpdateActorPairImpact` (`0x1487C`)

Clears `PairSpeedDeltaA/B` (`$FF1A9A/9C`) and `PairImpactA/B` (`$FF18B8/BA`).

- `gap = a1.PrevX - a2.PrevX`. If `gap < -$6000` or `gap >= ram_FF3038` -> large
  previous-X separation -> `Race_ExchangeCollisionSpeed` (passing bump).
- Otherwise close pair: `Race_ClampActorPairY`, then per actor:
  - active attack with reach (`StateFlags` bit4, `$50 != 0`) -> club-transfer check
    and `ram_FF0520 = 3` when PlayerA attacks the Natasha actor;
  - otherwise add `$52` to `$22` (push apart) and clear `$52` and the pair impact.
- Finally `Race_AdjustActorTrackPositions` and `Race_ApplyFallKnockdown`.

`Race_ClampActorPairY` (`0x1496C`) separates the actors in `$30` using
`$4C/$4E + $10`, then shifts `$00` by the same delta (draw Y follows the clamp).

E4-A: the demo produced 9 pair-impact entries (1 with the player), 6 clamp paths and
3 speed exchanges; all `PairImpactA/B` were 0 because the demo never holds an attack.

## Speed exchange: `Race_ExchangeCollisionSpeed` (`0x14CEC`)

- Calls `Race_UpdateCollisionSpeedState` with threshold `$1F40`; the returned
  magnitude is stored in `ram_FF18A6`.
- `delta = (a2.Speed - a1.Speed) * $1999 >> 16` (~0.1x the speed difference).
- PlayerA -> `BikeDamage += Race_ScaleImpactDamage(delta)`. Because
  `ScaleImpactDamage = |x| >> 11`, ordinary racing deltas (< ~$800) add 0 damage;
  E4-D/E sampled a 0x3BD speed difference and `BikeDamage` stayed 0.
- Speed equalization: the faster actor slows and the slower speeds up by `delta`
  (`a1.Speed = a2.Speed + delta`, `a2.Speed = a1.Speed - delta`).
- `a2.X = a1.X + $7000` (signed by the speed order): the faster actor is pushed
  forward.
- Cross-copies `StateFlags` bit3, then `Race_AdjustActorTrackPositions`.

## Damage state: `Race_UpdateCollisionSpeedState` (`0x145EC`)

- `d0 = a1.Speed - a2.Speed` (normal case).
- Heavy (`AnimState = 1`, event `$09`): `|speed difference| < d1` (the two bikes are
  side-by-side / ramming). Light (`AnimState = 0`, event `$0A`): the difference is at
  least `d1` (one passes the other).
- Exception: static target (`a2.$71 >= $10`) with `a2.$69` bit3 set is treated as a
  head-on `|a1 + a2|` and always takes the light path.
- Always writes `AnimFrame = $FF`; plays `sub_15538` (random FallState 0..3) when the
  magnitude is below `2*d1`, else `sub_1555C`. Player event `$09`/`$0A`.
- `d1` = `$1000` from `Race_ApplyCollisionImpact`, `$1F40` from
  `Race_ExchangeCollisionSpeed`.

## `Race_ApplyCollisionImpact` (`0x14486`, E4-F)

`d0 = a1.$1C` (previous collision offset), compared with `ram_FF303E = $40`.

**Deep/penetrating contact (`d0 < $40`):**
- `Race_UpdateCollisionSpeedState($1000)` -> `ram_FF18A6`.
- PlayerA: `BikeDamage += Race_ScaleImpactDamage(ram_FF18A6)`; event =
  `damage/2 > 2 ? $16 : damage/2 + 9` (low byte).
- Cross-copy `StateFlags` bit3; `sub_142D8` (weapon-anim speed flag).
- Speed: if `$69` bit3 clear -> `a1.Speed = a2.Speed + ram_FF18A6/4`; if set ->
  `a1.Speed = a2.Speed/2`. If `ControlFlags` bit0 is already set, the speed store is
  skipped (no double impact); otherwise store and `sub_14688` pushes X by
  `ram_FF3038 + $3000 + $200` signed by `$69` bit0.
- `$8/$C` are set from `a2.$8`; if `AnimState >= 0` (the light branch sets it 0),
  `$8/$C = (a1.$30 - a2.$30)*4`, `$2C = |ram_FF18A6| >> 11`, `$2E = 0`,
  `$2A = $02 + $30`, and `ControlFlags` bit0 is set.

E4-F (Speed `$2000`/`$1000`): post `Speed=$1400`, `BikeDamage=2`, event `$0A`,
`$2C=2`, `$2A=$02+$30`, `$68` bit0 set, `$69` bit3 clear.

**Shallow/pass-by contact (`d0 >= $40`):**
- `$2C = Speed >> 11`, `$2E = 0`, `$2A = $02 + ram_FF303E`,
  `$32 = ram_FF3040`.
- Clears `ControlFlags` bit4 and sets bit0. Player event `$09`; if `AnimState < 0`
  the later store replaces it with `$16`. No BikeDamage and no speed change.

E4-F (`$1C=$80`, same speeds): post `Speed=$2000`, `BikeDamage=0`, event `$09`,
`$2C=4`, `$32=$0002`, `$68` bit4 clear/bit0 set.

## `Race_ApplyImpactSpeedLoss` (`0x146AC`)

Scales `$2C` by `$2000 >> 16` (about 1/8). If it becomes 0 -> clear bit0. Else, when
`ControlFlags` bit4 is set, reduce Speed by Speed/8, raise player event `$06`, set
`$2A = $02`, `$2E = 0`, bit0. Finally `AnimState == 0` becomes 1.

## Fall / knockdown: `Race_ApplyFallKnockdown` (`0x14C3C`, E4-B)

For each actor with `AnimState < 0` (normal riding `$FF`) and non-zero pair impact:

```
$5C -= PairImpact * ram_FF18AC          ; PairImpactA for a1, PairImpactB for a2
if no underflow: done
$5C = 0
ControlFlags bit4 set
FallState = $11
AnimState = 0
AnimFrame = $FF
a1 path: event $0F when a1 == PlayerA
a2 path: save the actor shadow; event $0D when the *other* actor (a1) == PlayerA
```

The a2 `$0D` test on `a1` is intentional: `a1` is the acting player and `a2` the
opponent that fell, so the check selects the player-specific sound. The `exg`/save
dance only preserves the shadow-save argument.

E4-B confirmed the arithmetic and stores: `PairImpact=1`, `ram_FF18AC=$10`,
`$5C=$100 -> $0F0` (no fall), `$5C=$08 -> 0` with `FallState=$11`, `AnimState=0`,
`AnimFrame=$FF`, `ControlFlags` bit4 and event `$0F`; the a2 underflow with
`a1=PlayerA` reached the `$0D` store.

## `$5C` is stamina, not a tile base

`$5C` is the actor **stamina/health** value:

- init: `Race_CreateActors` from the graphics entry `+$E`; `Race_SetupActor` and
  `Race_SpawnTick` use `ram_FF18A8 = $500`; the player is overridden to
  `ram_FF18AA = $A00`.
- regeneration: the generic `Race_UpdateActorActions` loop adds `FrameDelay` while
  `$5C+FrameDelay < ram_FF18A8 ($500)`, then stores the graphics entry `+$E`
  (page maxima `$500/$640/$780/$8C0/$A00`). `ram_FF18A8` is the shared baseline, not
  the per-actor cap; the graphics `+$E` is the restored page maximum. The player is
  skipped by that loop outside demo mode and regenerates in
  `Race_UpdatePlayerAnimation` toward `ram_FF18AA = $A00` (its spawn override).
  `[confirmed]` `analysis/capture_L8_u17.gdb`: page-1 actor `$640`, forced
  `$4F0 -> $4F7 -> $4FE -> $640` across the `$500` threshold.
- consumption: `Race_ApplyFallKnockdown` subtracts `PairImpact * ram_FF18AC`
  (`ram_FF18AC = $10`).
- display: `RaceHud_DrawStamina` draws the two stamina bars from `$5C >> 5`
  (clamped `$50`, colours at `$1E`/`$F`).

The older `RaceActor_TileBase` name is a misnomer; rename to `RaceActor_Stamina` is
proposed in `identifiers.md` (rename task later). `$5E/$60` are the neighbouring
sprite fields from graphics `+$A/+$C` and remain unchanged.

## R30 crash handlers (static)

These are reached from `sub_12070` via `unk_14744` when a track object contacts the
player; the 60 s demo does not produce one (E4-A: 0 calls to `sub_140EE`,
`sub_141AE`, `sub_14404`), so their timing stays `[static]`.

- `sub_140EE` (on-road crash): Speed `< $FA0` -> only `sub_142FE` (road-Y clamp) and
  bit4. Else damage path: `sub_140BC` (X from object `$E`), `sub_1438E`, SFX by
  `abs($34)`/Speed, `$6E=0`, `$6F=$FF`; if `ram_FF1768 == 0`: `sub_142D8`,
  `Race_SaveActorShadow`, `sub_1436E($C000)` (shadow Speed to 75%); PlayerA
  `BikeDamage += Race_ScaleImpactDamage(Speed)/2`, event `$09`; if crashing already,
  event `$0F`. Sets bit4.
- `sub_141AE` (off-road/high-speed): gate `$69` bit3 or Speed `< $FA0` -> only
  `sub_142FE`. Else `ram_FF18A6 = Speed`, Speed = `min(Speed*$4000>>16, $2710)`
  (25%, clamped 10000), X shifted `+/-$6000` relative to object `$E`,
  `sub_1438E`, bit4 + `$69` bit3; FallState `$9` when `ram_FF18A6 >= $1F40` else
  `$5`; PlayerA `BikeDamage += Race_ScaleImpactDamage(ram_FF18A6)` (no `/2`).
- `sub_14404` fallback: `sub_1438E`; `ram_FF1768 == 0` -> `AnimState=$FF`; else
  unless `AnimState==3`: FallState 0, `AnimState=0`, `AnimFrame=$FF`, event `$F`,
  and if Speed==0 `sub_140BC`; `AnimState==3` -> clear bit4.
- `sub_142FE` road-Y clamp: `PosY=$1A = ram_FF1B14 +/- (extent+4)` by `$69` bit1;
  the delta is added to `$00`; `FrameDistance==0` -> X/PrevX `-=$4000`.
- `sub_1436E` scales the shadow actor's Speed by `d0` (16.16); `$C000` = 75% in both
  crash paths. `sub_1438E` is the speed-loss latch: `$2C = Speed >> 11`, `$2A=$02+$30`,
  bit0; PlayerA event `$06`, or crash animation/event `$0F` at Speed `>= $3E8` while
  `ram_FF1768 != 0`.
- `sub_14456`/`sub_1446E`: if `AnimState < 3`, set `$68` bit5 and `$78 = $78`/`$1E`,
  arming the `word_14742` curve limit.

## Lean-over crash: `Race_ApplyCrashImpact` (`0x11B7A`)

Separate from the track-object crash handlers. Called from the player AI step
(`race_ai.asm:11010`) only when `DemoMode == 0`, so the demo never exercises it.

- Reads the curve byte at `Track_CurveBuffer[(X&$FF)*2+1]`; if `ControlFlags` bit0
  is set and `$2E >= $2D`, substitutes `$64`; stores `$A`.
- Skips while `ControlFlags` bit0 is set or `AnimState >= 0` (normal `$FF`).
- `d2 = LeanCurve + |$C|`, with `d2|$34` sign-flipped when `$C < 0`; if
  `|$34| < 3` or `d2 < ram_FFD33E`, no crash.
- Crash: `AnimState=0`, `AnimFrame=$FF`, `ControlFlags` bit4, random FallState
  (`sub_15538`), `Race_SaveActorShadow`, clear `WeaponAnimFlags` bit7,
  `BikeDamage += Race_ScaleImpactDamage(Speed) >> 2`.
This is the "fell over in a hard corner" path; the damage quarter-scale matches the
older combat note and is distinct from `sub_140EE` (half) and `sub_141AE` (full).

## Field summary (L4 additions)

| Field | Role | Evidence |
|---|---|---|
| `$5C` | stamina/health (HUD bar); regen +consumption | `[confirmed]` E4-B + U-0017 + HUD |
| `$68` bit0 | impact/speed-loss latch | `[confirmed]` E4-F |
| `$68` bit4 | pair contact / crash latch | `[confirmed]` E4-F |
| `$69` bit0 | pair X order (a1 ahead) | `[static]` |
| `$69` bit1 | pair Y side (a1 above) | `[static]` |
| `$69` bit3 | collision direction copied across the pair | `[confirmed]` E4-F |
| `$69` bit7 | attack reach contact | `[static]`/`[dynamic]` combat |
| `$4A` | current side Y extent | `[confirmed]` combat/E4 |
| `$4C/$4E` | above/below Y extents | `[confirmed]` E4-A clamp |
| `$50` | attack reach (`$28`/`$19`/`$1A`) | `[dynamic]` combat |
| `$52` | attack overlap/penetration | `[dynamic]` combat |
| `$1C` | previous collision offset (branch selector) | `[confirmed]` E4-F |
| `$2A/$2C/$2E` | projected Y offset / impact scale / accumulator | `[confirmed]` E4-F |
| `$54` | FallState (`$11` knockdown) | `[confirmed]` E4-B |
| `ram_FF18A6` | impact speed magnitude | `[confirmed]` E4-F |
| `ram_FF18A8/AA` | shared stamina baseline / player cap (`$500`/`$A00`) | `[confirmed]` U-0017 + HUD |
| `ram_FF18AC` | stamina damage per pair-impact unit (`$10`) | `[confirmed]` E4-B |
| `ram_FF18B6` | track-position adjustment scale (`$1400`) | `[static]` |
| `ram_FF1768` | current player in crash/fall animation | `[confirmed]` E4-F |
| `ram_FF3038/303E/3040` | X window / penetration threshold / side state | `[confirmed]` E4-F |
| `ram_FF1B16` | pair Y-overlap flag | `[static]` |
| `ram_FF1A9A/9C` | pair speed deltas | `[static]` |
| `ram_FF1B26` | BikeDamage (HUD inverse HP; `$20` threshold) | `[confirmed]` E4-F |

## E4 traces

| Check | Script | Trace | Verdict |
|---|---|---|---|
| E4-A demo L4 survey | `analysis/capture_L4_a.gdb` | `analysis/notes/L4a_trace.txt` | 9 pair impacts, 1 player, 6 clamps, 3 exchanges, 0 knockdown stores, 0 crash/object impacts |
| E4-B forced knockdown | `analysis/capture_L4_b.gdb` | `analysis/notes/L4b_trace.txt` | confirmed formula/stores/events |
| E4-C simulated VBlank impact call | `analysis/capture_L4_c.gdb` | `analysis/notes/L4c_trace.txt` | failed (PSG fault in the artificial context); superseded by E4-F |
| E4-D natural player exchange | `analysis/capture_L4_d.gdb` | `analysis/notes/L4d_trace.txt` | exchange reached, small delta -> 0 damage |
| E4-E exchange operand probe | `analysis/capture_L4_e.gdb` | `analysis/notes/L4e_trace.txt` | operands/signs sampled |
| E4-F forced natural static impact | `analysis/capture_L4_f.gdb` | `analysis/notes/L4f_trace.txt` | both `Race_ApplyCollisionImpact` branches confirmed |

## Residual

- R30 crash-path branch timing/damage (`sub_140EE`/`sub_141AE`) is static-only; the
  demo never crashes. A normal-mode run that drives into a track object is the next
  dynamic check. `Race_ApplyCrashImpact` (lean-over, `0x11B7A`) is also non-demo only.
- `Race_GetAttackerReach` close-attack table `unk_12BCC` use is static-only.
- `ram_FF18A8` cap semantics for opponents (regeneration cap vs graphics `+$E`) is
  `[static]` and needs an opponent-stamina sample.

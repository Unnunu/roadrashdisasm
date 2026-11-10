# Race impact / analysis map

Goal: understand the remaining race code with the fewest deep dives. Full-ROM source
is already byte-exact; this map prioritizes **semantic hubs**, not line count.

## Method

- Static: call graph fan-in + actor-offset usage in `src/race/*.asm`.
- Dynamic: one snapshot/breakpoint per unknown field rather than reading every
  instruction.
- Deep dive (line-by-line) only for arithmetic/timing/collision fields that cannot be
  explained by contract + dynamic values.

## Highest-value targets

| Priority | Target | Unknown fields | Why / next |
|---|---|---|---|
| 1 | `Race_UpdateActorMovement` / `Race_UpdateActorFallMovement` / `Race_SetupActor` | `$32`, `$36`, `$38`, `$3A`, `$3C` | Common movement/road state; 4–5 unknown offsets each. Dynamic snapshots while steering/off-road; then define field names. |
| 2 | `Race_UpdateActorPairCollision` / `sub_12070` / `sub_12414` / `sub_11CC8` | `$32`, `$4C`, `$4E`, `$56` | Collision-side extents and contact state; fan-in 9. Use forced pair tests and collision snapshots. |
| 3 | `Race_UpdateBikeCurve` / `Race_UpdateLeanCurve` | `$40`, `$78` | Curve/lean output; steering snapshots already exist. Resolve `$40` vs `$3E/$42`. |
| 4 | `Race_ProjectActorSprite` / `Race_AddActorImpactObject` | `$73` | Graphics/profile byte use in object records; compare SAT/object records. |
| 5 | `sub_11906` | none directly | Fan-in 11; target/recovery hub. Map callers/contract before rename. |
| 6 | `Race_UpdateActorSpeedState` / `Race_UpdateActorSpeedGear` | none directly | Fan-in 9 each; gear/speed hub. Validate formula against dynamic speed/gear. |
| 7 | `Race_UpdateStaticActors` / extra static | `$56`, `$73` | Static/police state; forced activation already captured. |

## Deliberately not prioritized

- UI/menu/HUD colors: visual-only; static tables already enough for build.
- Raw data tables/assets: already exact; analyze only through consumers.
- Audio/Z80: deferred.
- Exhaustive line-by-line of simple wrappers: use contracts instead.

## Next experiments

1. Actor movement: snapshot `$32/$36/$38/$3A/$3C` at normal/steer/off-road/hard-left;
   compare against `$00/$1A/$30`.
2. Pair collision: force Y/X separation and capture `$4C/$4E/$56`, contact bits.
3. Curve: capture `$3E/$40/$42/$46/$78` during high-speed steering.
4. Graphics: break at `Race_ProjectActorSprite` / `Race_AddActorImpactObject`; inspect
   `$73`, shape/base, and object record.
5. Hubs: log `sub_11906` callers/target choice and speed/gear transitions.

## Rename rule

After each experiment: update the field matrix, add rename proposals with evidence, and
apply a separate build-verified batch only for confirmed names.

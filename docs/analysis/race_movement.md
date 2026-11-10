# Race actor movement dataflow

Scope: `Race_UpdateActorX`, `Race_UpdateActorMovement`,
`Race_UpdateActorFallMovement`, `sub_115C6`, `Race_UpdateActorShadow`.

This is a targeted deep dive for `$32` and `$36–$3C`; it intentionally does not
rename fields that have more than one plausible meaning.

## Frame order

`Race_UpdateActorShadow` is the per-actor movement wrapper:

1. Back up the actor struct through `Race_ActorShadowTable` (`$71` selects the slot).
2. Add acceleration (`$14 * FrameDelay`) to `Speed` (`$12`), clamped at zero.
3. Compute `FrameDistance` (`$26 = Speed * FrameDelay`).
4. If `StateFlags` bit3 is clear: `Race_UpdateActorMovement`; else:
   `Race_UpdateActorFallMovement`.
5. Clamp draw Y from `$36`, then limit X correction to `$A0000`.

`Race_UpdateActorX` is the player/scripted variant: it also handles the start-line
threshold and the extra/static activation snapshot, then uses the same curve math.

## Forward movement: `Race_UpdateActorMovement` / `Race_UpdateActorX`

- `$1A = $30`: previous draw/road Y.
- `$1C = $32`: previous candidate Y.
- `$1E = $04`: previous X.
- `$04 += $26`: X advances by `Speed * FrameDelay`.
- The low X byte selects a pair of bytes in `Track_CurveBuffer`.
- The two curve bytes are accumulated into `d6` and `d7`; `$3A += d7`.
- For each step, `$2C` tracks the largest curve byte and `ram_FF1E92` records
  `$3A + d7` when that maximum is crossed.
- After the loop:
  - `$38 = curve_step` (the first byte scaled by low X),
  - `$36 += curve_step`,
  - `$3C = curve_step` for the next byte (`sub_115C6`).
- `sub_115C6` combines `$3A + $3C`, derives `$2A` (Y offset), `$2C` (curve/scale
  state), and `$2E` (speed reduction accumulator).

Meaning in one line: `$36` is the road-Y target offset, `$38` the last curve delta,
`$3A` the curve accumulator, and `$3C` the current curve step. The names stay
unapplied because `$36` is later treated as a target/clamp value rather than a pure
accumulator.

## Y clamp and off-road transition

After movement:

- `d1 = $36 - current draw Y`.
- Negative side: clamp to `$FCA0`; below `$FF20` sets `ControlFlags` bit3.
- Positive side: clamp to `$360`; above `$E0` sets `ControlFlags` bit3.
- `$30` is set from the clamped target, so it is the **road Y output**, not the
  source accumulator.

The same logic appears in `Race_UpdateActorShadow` for the zero-speed case.

## Fall/backward movement

`Race_UpdateActorFallMovement`:

- Player A is skipped while X < `$10000`.
- `$04 -= $26` instead of `+=`; X moves backward.
- The same `$1A/$1C/$1E` backup and curve sampling are used.
- `$36/$38/$3A/$3C` and `sub_115C6` are driven identically.

## Collision extents

`$4C/$4E` are not left/right in the generic actor sense. They are **pair collision
extents selected by side index**:

- `Race_UpdateActorPairCollision` calls `Race_GetCollisionExtent` with `d3 = 0` for
  one side and `d3 = 1` for the other.
- The result is stored in `$4C` or `$4E` according to which actor is above/below.
- The same values are used to separate actors in `sub_12414`/`sub_12070`.

Therefore the old left/right labels are too specific; keep `$4C/$4E` numeric until a
dynamic test maps the side index to screen direction.

## Open points

- `$32`: candidate Y copied to `$1C`; zero in normal snapshots. It is used as a
  threshold in the collision path. Role still TODO.
- `$3C`: observed write-only; confirm whether any rendering/audio reader uses it.
- `$4C/$4E`: need a forced pair test that logs `d3`, Y ordering, and screen direction.
- `$73`: now named `RaceActor_Palette`; its low 2 bits are shifted into the sprite
  attribute word.
- `$40`: now named `RaceActor_LeanCurve`; `Race_UpdateLeanCurve` writes it from the
  curve/steering product.

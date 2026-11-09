# Analysis: `src/race/race_anim_audio.asm` (PRNG, engine audio, animation/target/collision)

- **Module:** PRNG, engine audio/gear state, player animation, nearest-target,
  collision/proximity, and the track/animation data tables
- **ROM range:** `0x014056`–`0x01685F`
- **Status:** analyzed (roles/flow); some animation/collision/audio fields TODO
- **Source:** `src/race/race_anim_audio.asm`
- **Related:** `docs/analysis/combat.md` (attack input/state/actions), `docs/analysis/race.md`, `docs/analysis/race_ai.md`,
  `docs/analysis/race_physics.md`, `docs/modules/race_anim_audio.md`,
  `docs/ram-map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `Race_UpdateLeanCurve` | `0x1406A` | Lean/curve `$3E/$40` and `ram_FF3042`. |
| `Race_UpdatePlayerAnimation` | `0x160E2` | Player `$5C` animation/tile base clamp. |
| `Race_UpdateNearestTarget` | `0x1611A` | Nearest actor by squared distance -> `Race_ram_NearestActor`. |
| `Race_UpdateCollision` | `0x16732` | Player/actor proximity + engine/gear state. |
| `Audio_UpdateEngineState` | `0x16548` | Engine/gear state (`$6C/$6D`, timing tables). |
| `Audio_UpdateEngine0` | `0x16520` | Engine audio trigger/flag. |
| `Rand_Init` | `0x15FE8` | Seed the 32-word PRNG state. |
| `Rand_GetWord` | `0x16034` | Sum-of-two-words PRNG word. |
| `sub_141...`..`sub_155...` | `0x1406A`+ | Animation/track data helpers (TODO). |
| `sub_162B0`/`sub_1634E`/`sub_16458` | `0x162B0`+ | Combat input/dispatch/attack state (see `docs/analysis/combat.md`). |
| `sub_165D0`..`sub_166F0` | `0x165D0`+ | AI combat/action handlers; names/roles static (see combat.md). |

## PRNG

`byte_15FA8` is a 32-word seed table copied to `ram_FF18BE`; `Rand_Init` adds the seed
and sets the two indexes (`ram_FF18FE`/`ram_FF1900`, 0..31). `Rand_GetWord` returns
`state[i1] + state[i2]`, stores it and advances both indexes (lagged sum PRNG).

## Engine audio / animation / collision

- `Audio_UpdateEngine0` flags `ram_FF1AD7=$0E` for an active engine (`$6C==1`,
  `$6B` bit1, not `$69` bit6).
- `Audio_UpdateEngineState` advances `$6C`/`$6D`; the timing tables `unk_257E2`/
  `unk_257E8`/`unk_257EE` (by engine type/gear); clears `$69` bit4 at the end.
- `Race_UpdateCollision` compares the player/actor `$4A`/`$30` ranges (`ram_FF1A68`),
  sets `$5A`/`$6C`/`$6B`/`$69` bits and picks engine timings (`RaceBike_ram_PhysicsConstants/1ABC`).
- `Race_UpdateLeanCurve` computes the lean/curve from `$3E`/d0 into `$40`/`ram_FF3042`.
- `Race_UpdatePlayerAnimation` advances the player tile base `$5C` up to `ram_FF18AA`
  by `Race_ram_FrameDelay` (on-foot/`$6E` gated).
- `Race_UpdateNearestTarget` finds the nearest actor by squared X/Y distance and
  stores `Race_ram_NearestActor`, `Race_ram_NearestRpmDivisor`, `ram_FF1786`.

## Data / RAM

- `unk_14056` (curve speed limit; `Race_GetCurveSpeedLimit`), `unk_1471A` (track
  params; `Race_LoadTrackParams`), `word_14742` (curve speed), `unk_155A4`/
  `unk_15624`/`unk_15CE0`/`unk_15CFC`/`byte_15FA8` (animation/PRNG data).
- PRNG: `ram_FF18BE` (32 words), `ram_FF18FE`/`ram_FF1900` indexes.
- Audio/target: `ram_FF1904/1906/1908`, `ram_FF1AD7`, `Race_ram_NearestRpmDivisor`, `ram_FF1786`.
- Actor fields: `$3E/$40/$42` lean, `$4A/$5A` collision/range, `$5C` tile base,
  `$68/$69/$6B/$6C/$6D/$6E` engine/collision/animation flags.

## Open questions

- Exact animation table/scripts and `sub_141...`/`sub_155...` helpers.
- Engine-audio mapping of `$6B/$6C/$6D` and `ram_FF1AD7` into the sound driver.
- Collision/impact rules and the `ram_FF1A68` data.
- Next: `src/race/race_hud.asm`/`src/race/road_marking.asm`/`src/race/animation.asm` cards/internals.

## Rename proposals

The function renames above are applied. Remaining data/field names are TODO.

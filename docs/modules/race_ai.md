# Module card: `src/race/race_ai.asm`

- **ROM range:** `0x010E00`–`0x014055` (`src/race/race_anim_audio.asm` starts at `0x14056`)
- **Status:** actor/AI/action dispatch, movement/speed/curve fields and the R30 gap set analyzed; crash/fall contracts integrated (matrix v5); L3 static contracts and E3 dynamics done (candidate buckets, profile slot/budget, dispatcher branches, per-level budget, static respawn); L4 dynamics next
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_spawn.md`,
  `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Actor movement/AI/physics and input: `sub_10E00`..`Race_GetCurveSpeedLimit`, including
`Race_HandleInputOnFoot`/`Race_AnotherInputOnFoot` and the per-frame actor/opponent
update chain. Road/profile/objects/standings live in `src/race/race_ai_road.asm`; animations and
audio live in `src/race/race_anim_audio.asm`; PRNG/LFSR helpers are in
`src/race/rand.asm`; attack/action handlers live in `src/race/race_combat.asm`.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Race_DrawRoadEdges`..`Race_UpdateCollision` | `0xEC90`–`0x16732` | `Race_Update` | AI/physics/render chain. |
| `Race_BuildVisibleList` | `0x10D46` | `Race_Update` | Visible object list. |
| `Race_UpdateSpeedDisplay` | `0xF108` | `Race_Update` | Speed display. |
| `Race_FormatDecimal` | `0xF11C` | HUD/debug | Packed decimal. |

## Key functions

- `Race_UpdateActorAI` `0x10E66`: main player/opponent AI loop.
- `Race_HandleInputOnFoot` `0x110AE` / `Race_AnotherInputOnFoot` `0x111FA`: on-foot input.
- `Race_UpdateStaticActors` `0x12868`: static/police actor AI.
- `Race_UpdateActorActions` `0x12EA2`: profile action selection (`Race_ActorProfileTable[$74]`), recycle and `ram_FF1A96/98` budget.
- `Race_UpdateStaticActions`/`Race_ClampActorY` `0x13106`/`0x13130`: static action dispatch/shared Y clamp; `Race_StaticActionTable` speed/Y-offset pairs decode.
- `Race_DispatchActorAction` `0x16458`: action-1 dispatcher (target/cooldown).
- `Race_SetupActorSprite` `0x13746`: actor sprite/field setup.
- `Race_UpdateBikeLean` `0x13EA0` / `Race_UpdateBikeCurve` `0x13EFA`: lean/curve.
- `Race_GetCurveSpeedLimit` `0x13FE6`: curve speed limit (`Track_CurveBuffer`, `unk_14056`).
- Gap set (R30): `sub_1131A` shadow-follow (no caller, dead twin of the on-foot path),
  `sub_11A5E` curve-position integration (`$E/$10` write-only), `sub_12B2A` adjusted
  attack reach, `sub_133F0` curve direction, `sub_13704` distance ratio, `sub_13A5C`
  far respawn, `sub_13D44` track-object steering (record/type-table fields decoded).
- R30 integration: `$78` is armed by `sub_14456`/`sub_1446E`, so `word_14742` is
  reachable; `$3C` is a write-only curve-step snapshot, not a timer; `unk_12168` is
  dead data.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| actor/input/AI chain | `0x10E00`+ | [~] | [~] | [~] | [ ] | [~] | [~] | partial; `10E66` snapshot |
| actor action dispatch | `0x12D0A`-`0x131BE` | [x] | [x] | [x] | [x] | [x] | [x] | L3 static contracts + `$74` pages/families; E3 confirmed slots/budget/branches |
| bike lean/curve | `0x13EA0`/`0x13EFA` | [x] | [~] | [x] | [x] | [~] | [~] | static + steering snapshots |
| curve speed limit | `0x13FE6` | [x] | [~] | [x] | [x] | [~] | [ ] | static |
| gap functions | `0x1131A`-`0x13DDF` | [x] | [~] | [x] | [x] | [~] | [ ] | R30 integration: contracts/tables static; `U-0012`..`U-0016` closed |

Detailed flow: `docs/analysis/race.md`; spawn: `docs/analysis/race_spawn.md`.

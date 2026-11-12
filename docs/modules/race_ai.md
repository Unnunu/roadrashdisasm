# Module card: `src/race/race_ai.asm`

- **ROM range:** `0x010E00`–`0x014055` (`src/race/race_anim_audio.asm` starts at `0x14056`)
- **Status:** actor/AI/action dispatch, movement/speed helpers and collision fields analyzed; some behavior dynamic tests/TODO
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
- `Race_UpdateActorActions` `0x12EA2`: profile action selection (`Race_ActorProfileTable[$74]`).
- `Race_UpdateStaticActions`/`Race_ClampActorY` `0x13106`/`0x13130`: static action dispatch/shared Y clamp.
- `Race_DispatchActorAction` `0x16458`: action-1 dispatcher (target/cooldown).
- `Race_SetupActorSprite` `0x13746`: actor sprite/field setup.
- `Race_UpdateBikeLean` `0x13EA0` / `Race_UpdateBikeCurve` `0x13EFA`: lean/curve.
- `Race_GetCurveSpeedLimit` `0x13FE6`: curve speed limit (`Track_CurveBuffer`, `unk_14056`).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| actor/input/AI chain | `0x10E00`+ | [~] | [~] | [~] | [ ] | [~] | [~] | partial; `10E66` snapshot |
| actor action dispatch | `0x12D0A`-`0x131BE` | [x] | [x] | [x] | [x] | [x] | [~] | static table + demo trace |
| bike lean/curve | `0x13EA0`/`0x13EFA` | [x] | [~] | [x] | [x] | [~] | [~] | static + steering snapshots |
| curve speed limit | `0x13FE6` | [x] | [~] | [x] | [x] | [~] | [ ] | static |

Detailed flow: `docs/analysis/race.md`; spawn: `docs/analysis/race_spawn.md`.

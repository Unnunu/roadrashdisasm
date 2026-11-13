# Module card: `src/race/race_ai.asm`

- **ROM range:** `0x010E00`–`0x014055` (`src/race/race_anim_audio.asm` starts at `0x14056`)
- **Status:** actor/AI/action dispatch, movement/speed/curve fields and the R30 gap set analyzed; crash/fall contracts (matrix v7/E4); L3 contracts/E3, L4 impact and L5 spawn/static lifecycle (matrix v8/E5) done
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

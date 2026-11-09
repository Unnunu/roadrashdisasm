# Analysis: `src/race/race_ai.asm` (on-foot input, actor AI, bike lean/curve)

- **Module:** on-foot player/AI input, actor AI loop, static actor AI, bike lean/curve,
  curve speed limit, actor sprite setup, movement/collision helpers
- **ROM range:** `0x010E00`–`0x014055`
- **Status:** analyzed (roles/flow); exact AI/collision field semantics partly TODO
- **Source:** `src/race/race_ai.asm`
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_ai_road.md`,
  `docs/analysis/race_physics.md`, `docs/modules/race_ai.md`, `docs/ram-map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `sub_10E00`/`unk_10E3E`/`sub_10E66` | `0x10E00`+ | Actor setup + `Race_UpdateActorAI`. |
| `Race_UpdateActorAI` | `0x10E66` | Main actor AI loop (player/opponents). |
| `sub_1103A` | `0x1103A` | AI movement helper. |
| `Race_HandleInputOnFoot` | `0x110AE` | On-foot input/AI (player A). |
| `Race_AnotherInputOnFoot` | `0x111FA` | On-foot input/AI (other actor/pad). |
| `sub_11268`/`sub_112C8`/`sub_113A4`/`sub_113CA`/`sub_11448`/`sub_115C6`/`sub_116E2`/`sub_1180C`/`sub_11906`/`sub_11940`/`sub_11B7A` | `0x11268`+ | Turn/movement/lean helpers. |
| `sub_11C44`/`sub_11CC8`/`sub_12070`/`sub_1218C`/`sub_123A8`/`sub_12414`/`sub_124E2` | `0x11C44`+ | Opponent/AI logic. |
| `sub_1281E`/`Race_UpdateStaticActors`/`sub_128E0`/`sub_12974` | `0x1281E`+ | Static/police actor AI. |
| `sub_12...`/`sub_13...` | `0x12A88`+ | Road/actor movement, collision helpers. |
| `unk_12D0A`/`unk_12D16` | `0x12D0A`/`0x12D16` | 6-word offset table + 99-entry actor action code-pointer table. |
| `sub_12FE4`/`sub_13004`/`sub_1300E`/`sub_1307C`/`sub_130D2` | `0x12FE4`+ | Actor action handlers (state/curve/recovery). |
| `sub_13130` | `0x13130` | Y clamp + `$46` sign flip (shared `unk_25A44` handler). |
| `Race_SetupActorSprite` | `0x13746` | Actor sprite/field setup (spawn). |
| `Race_UpdateBikeLean` | `0x13EA0` | Steering/lean from Speed/Steering. |
| `Race_UpdateBikeCurve` | `0x13EFA` | Bike curve/lean `$3E/$40` from speed/steering. |
| `Race_GetCurveSpeedLimit` | `0x13FE6` | Curve speed limit from `Track_CurveBuffer`/`unk_14056`. |

## Flow

`Race_Update` runs `Race_UpdateActorAI`: it marks the player A `$68` bit6 and walks
`ram_FF1A08`. For the player A it handles the on-foot case
(`Race_HandleInputOnFoot` when `$68` bit4 and `$6E==3`), otherwise the normal input/AI
(`sub_113CA`/`sub_13EFA`, `sub_11448`, `sub_11940`). Opponents use
`Race_UpdateActorAI`/`sub_1103A`/`sub_113A4`/`sub_116E2`. Static/police actors are
walked from `Race_StaticActorList` by `Race_UpdateStaticActors`
(`unk_25A10`, `sub_113A4`/`sub_116E2`/`sub_11940`, `sub_137E4`/`sub_12C9A`/
`sub_13DE0`).

`Race_UpdateBikeLean` computes `$42` from Speed/Steering (`ram_FF1AA6/AAA/B4`,
`RaceBike_ram_CurrentSteering`). `Race_UpdateBikeCurve` derives `$3E/$40` from the
speed/curve (`ram_FF302E/3032/3034`, `word_14742`). `Race_GetCurveSpeedLimit` reads
`Track_CurveBuffer` and the `unk_14056` table to clamp the actor speed

## Actor action dispatch (`0x12D0A-0x131BE`)

- `unk_12D0A` is a 6-word offset table (`FF60,FFA0,FFE0,0020,0060,00A0` = -$A0..$A0).
- `unk_12D16` is a 99-entry dword table of actor action code pointers. `unk_259C0`
  indexes this table indirectly: each entry is a pointer to one of these slots, and
  the handler does `movea.l (a4),a6; jsr (a6)`.
- Handlers: `sub_12FE4` (state bits + collision/curve helpers), `sub_13004`
  (`sub_13422`+`sub_131BE`), `sub_1300E` (target/curve update),
  `sub_1307C` (variant path), `sub_130D2` (recovery timer `ram_FF1B32`, then
  `sub_1300E`).
- `sub_13130` is the shared handler of all 16 `unk_25A44` entries: it compares
  `|4(a1)-ram_FF1E68|` with `$210000`, otherwise computes a Y value from
  `$46*$12` + `$30`, clamps on-road to `$37..$A9` / off-road to `-$57..-$C9`, and
  flips `$46` when clamped.
- The table targets `sub_16458`, `sub_165D0`, `sub_165E0`, `sub_16612`, `sub_16624`,
  `sub_1662C`, `sub_16644`, `sub_1666A`, `sub_166B0`, `sub_166DC` in
  `src/race/race_anim_audio.asm`.
- Code at these entry points is now disassembled in `src/race/race_ai.asm`; exact AI/action
  semantics and dynamic behavior remain TODO.

## RAM / fields

Actor fields used here: `$12` Speed, `$14`, `$16` type, `$22`/`$26` movement,
`$30`/`$36/$38` Y/road, `$3E/$40/$42` lean, `$56`, `$68` bits, `$69` bits, `$6E`,
`$71` index, `$73`, `$75`, `$78`. Data: `unk_258AE`/`unk_25A10` actor data,
`unk_10E3E`, `unk_12B7C`, `unk_12D0A`, `unk_13A1A`, `Track_CurveBuffer`,
`ram_FF302E/3032/3034`, `word_14742`, `ram_FF1E68/82/9A`, `Race_ram_FrameDelay`/
`CurrentButtons`, `Race_StaticActorList`, `$FF2FAA`, `unk_14056` (race_anim_audio).

## Open questions

- Exact field semantics `$14/$36/$38/$3E/$40/$42` and the collision helpers.
- Static/police actor role and the `$FF2FAA` actor.
- AI tables (`unk_10E3E`/`unk_12B7C`/`unk_13A1A`) and the on-foot rules.
- Exact actor-action handler semantics (`0x12FE4`..`0x131BE`) and dynamic checks.
- Next: `src/race/race_anim_audio.asm` (animations/random/audio).

## Rename proposals

The function renames above are applied. Remaining field/data names are TODO.

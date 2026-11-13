# Module card: `src/race/race_ai_road.asm`

- **ROM range:** `0x00EB34`–`0x010DFF` (`src/race/race_ai.asm` starts at `0x10E00`)
- **Status:** analyzed (L6a profile + L6b object/projection/visible-list contracts)
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_spawn.md`,
  `docs/ram-map.md`, `docs/modules/race.md`, `docs/modules/race_ai.md`,
  `docs/modules/race_anim_audio.md`

## Role / purpose
L6a profile contract: `Race_IntegrateTrackCurve` emits 32 strips from
`Track_CurveBuffer` (curve amplitude = low word of `PlayerProgress`), and
`Road_FillProfileTables` writes the road rows of the 4-byte HScroll layout. See
`docs/analysis/race_ai_road.md` and `docs/analysis/race_physics.md`.
L6b object contract: the frame assembles `Road_ObjectArray` (0x14-byte records) from
`Race_AddSpecialObject`, `Race_AddTrackStartObject`, `Race_BuildActorObjectList`,
`Race_BuildTrackObjects` and `Race_AddStagedObjects`, then sorts the distance keys
into `Road_VisibleObjectList` for `Road_DrawObjects`. The four projection helpers
(`Race_ProjectObject`/`ActorObject`/`ActorSprite`/`TrackObject`) are documented in
`docs/analysis/race_ai_road.md`; `U-0019` is closed (low 5 bits = row, bits 10-8
= SAT copy-pass count).
R5 renamed the track-object cursor fields and road-object record offsets; see `docs/analysis/race_ai_road.md`.
Road profile/interpolation, visible object lists, sprite-tile staging, race
standings/results helpers and the speed display: `PiecewiseLinearInterpolation`,
`Road_FillProfileTables`, `Race_BuildActorObjectList`..`sub_10DDA`, `Road_BuildVisibleList`,
`Race_WriteSpriteTiles`, `Race_UpdateSpeedDisplay`, `Race_FormatDecimal`.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Road_FillProfileTables` | `0xECE0` | `Race_Update` | Road profile tables. |
| `PiecewiseLinearInterpolation` | `0xF180` | `Race_Update` | Road array interpolation. |
| `Road_BuildVisibleList` | `0x10D46` | `Race_Update` | Visible object list. |
| `Race_UpdateSpeedDisplay` | `0xF108` | `Race_Update` | Speed display. |
| `Race_FormatDecimal` | `0xF11C` | HUD/debug | Packed decimal. |
| `Race_WriteSpriteTiles` | `0x10972` | `Race_GameTick` | Sprite tile staging. |

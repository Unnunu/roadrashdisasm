# Identifier map

Durable, cross-file assessment of how well each identifier name matches its
observed uses. Policy and the actionable rename queue live here; the full
table is `docs/analysis/identifiers_inventory.md`.

## Verdict policy

- `Name quality`: `good` / `narrow` / `misleading` / `placeholder` / `wrong/unknown`.
- `Rename verdict`: `keep` / `rename-later` / `blocked-unknown`.
- `blocked-unknown` references an ID in `docs/analysis/unknowns.md`.
- Only `[confirmed]` evidence may justify a rename; renames are a separate,
  build-verified task. `rename-later` means the proposal is sound but not applied.
- `keep` includes intentional placeholders, dead code and retained aliases.
- The per-file summary lives in `docs/analysis/<file>.md`.
- **Usage:** grep the symbol in the inventory (or this queue) and read only the
  matching row. Append new rows at the end; do not reorder existing rows.

## Rename queue

Non-`keep` rows: 146 (`rename-later` 146, `blocked-unknown` 0).

| Identifier | Proposed | Verdict | Confidence | Evidence | Unknown ID |
|---|---|---|---|---|---|
| `Intro_InitPlayerA` | `Player_InitA` | rename-later | medium | `[static]` | - |
| `Intro_InitPlayerB` | `Player_InitB` | rename-later | medium | `[static]` | - |
| `unk_25EC0` | `RaceTrack_dRecords` | rename-later | medium | `[static]` | - |
| `Intro_ram_ImageBuffer` | `ram_ImageStagingBuffer` | rename-later | medium | `[static]` | - |
| `Race_ram_ImageBuffer2` | `MainMenu_ram_RaceCardBuffer` | rename-later | medium | `[static]` | - |
| `Menu_PlayerPlacesPtr` | `Menu_ram_PlayerPlacesPtr` | rename-later | high | `[static]` | - |
| `Menu_ram_CurrentlyDrawnRaceCard` | `Menu_ram_CarouselRaceId` | rename-later | medium | `[static]` | `U-0003` resolved |
| `Menu_ram_StrPlayerName` | `Menu_ram_PlayerInfoString` | rename-later | medium | `[static]` | - |
| `ram_FF0522` | `Player_ram_NatashaCounterA` | rename-later | medium | `[static]` | `U-0004` resolved |
| `ram_FF0524` | `Player_ram_NatashaCounterB` | rename-later | medium | `[static]` | `U-0004` resolved |
| `ram_FF07C2` | `Shop_StrLeftBike` | rename-later | medium | `[static]` | - |
| `ram_FF082E` | `Shop_StrRightBike` | rename-later | medium | `[static]` | - |
| `ram_FFDE5E` | `Road_ram_SpriteTileBits` | rename-later | medium | `[static]` | - |
| `ram_FFDE62` | `Road_ram_ChainEnd` | rename-later | medium | `[static]` | - |
| `ram_FFDE66` | `SpriteStrip_ram_TailColumnGap` | rename-later | high | `[static]`/E8-A | - |
| `ram_FFDE68` | `SpriteStrip_ram_BandAdvance` | rename-later | high | `[static]`/E8-A | - |
| `ram_FFDE6A` | `SpriteStrip_ram_ColumnGap` | rename-later | high | `[static]`/E8-A | - |
| `ram_FFDE6E` | `Road_ram_ObjectX` | rename-later | medium | `[static]` | - |
| `ram_FFDE70` | `Road_ram_ObjectY` | rename-later | medium | `[static]` | - |
| `ram_FF0906` | `Rider_ram_ColCode` | rename-later | medium | `[static]` | - |
| `ram_FF0908` | `Rider_ram_RowCode` | rename-later | medium | `[static]` | - |
| `ram_FF090A` | `Rider_ram_ColBlocks` | rename-later | medium | `[static]` | - |
| `ram_FF090C` | `Rider_ram_RowBlocks` | rename-later | medium | `[static]` | - |
| `ram_FF090E` | `Rider_ram_RowStartTile` | rename-later | medium | `[static]` | - |
| `ram_FF1336` | `Road_ram_MirrorXOffset` | rename-later | medium | `[static]` | - |
| `ram_FF1366` | `Road_ram_ChainEndAlt` | rename-later | medium | `[static]` | - |
| `ram_FF0520` | `Player_ram_NatashaCounter` | rename-later | medium | `[static]` | `U-0004` resolved |
| `RiderIntro_QuoteData` | `RiderIntro_FirstQuote` | rename-later | medium | `[static]` | - |
| `unk_8C96` | `EndLevel_StrNextLevelShort` | rename-later | medium | `[static]` | - |
| `unk_8D02` | `EndLevel_StrNotReadyEncoded` | rename-later | medium | `[static]` | - |
| `unk_8D16` | `EndLevel_StrNotReadyTail` | rename-later | medium | `[static]` | - |
| `unk_8D52` | `EndLevel_StrContinuePlay` | rename-later | medium | `[static]` | - |
| `unk_8D8A` | `EndLevel_StrNextLevel` | rename-later | medium | `[static]` | - |
| `ram_FF1A08` | `Race_ram_AiActorList` | rename-later | medium | `[static]` | - |
| `unk_25A10` | `Race_ActorBikeRecordTable` | rename-later | high | `[static]` | - |
| `unk_25AC4` | `Race_BikeSteeringTable` | rename-later | high | `[static]` | - |
| `unk_25B50` | `Race_PlayerBikeRecordTable` | rename-later | high | `[static]` | - |
| `unk_1471A` | `Race_TrackCurveParams` | rename-later | high | `[static]` | - |
| `word_14742` | `Race_CurveTimerLimit` | rename-later | high | `[static]` | - |
| `unk_14056` | `Race_CurveScaleTable` | rename-later | high | `[static]` | - |
| `ram_FF1AA6` | `RaceBike_ram_LeanSteeringDivisor` | rename-later | high | `[static]` | - |
| `ram_FF1AAA` | `RaceBike_ram_LeanMultiplier` | rename-later | high | `[static]` | - |
| `ram_FF1AB2` | `RaceBike_ram_CurveSpeedScale` | rename-later | high | `[static]` | - |
| `ram_FF1AB4` | `RaceBike_ram_LeanSpeedScale` | rename-later | high | `[static]` | - |
| `$78` (`STRUCT_OFFSET_78`) | `RaceActor_CurveTimer` | rename-later | medium | `[static]` | - |
| `sub_11A5E` | `Race_UpdateActorCurvePosition` | rename-later | medium | `[static]` | `U-0013` resolved |
| `sub_12B2A` | `Race_GetAttackerReachAdjusted` | rename-later | medium | `[static]` | - |
| `sub_133F0` | `Race_SetActorCurveDirection` | rename-later | medium | `[static]` | - |
| `sub_135E8` | `Race_SetActorAccelerateFlag` | rename-later | medium | `[static]` | - |
| `sub_13704` | `Race_UpdateActorDistanceRatio` | rename-later | medium | `[static]` | - |
| `sub_13A5C` | `Race_ResetActorFarBehind` | rename-later | medium | `[static]` | - |
| `sub_13D44` | `Race_UpdateTrackObjectSteering` | rename-later | medium | `[static]` | `U-0014` resolved |
| `sub_140BC` | `Race_UpdateActorXFromTrackObject` | rename-later | medium | `[static]` | - |
| `sub_140EE` | `Race_ApplyActorCrash` | rename-later | medium | `[static]` | - |
| `sub_141AE` | `Race_ApplyActorHighSpeedCrash` | rename-later | medium | `[static]` | - |
| `sub_142B0` | `Race_ApplyCrash0F` | rename-later | low | `[static]` | - |
| `sub_142BE` | `Race_ApplyCrash17` | rename-later | low | `[static]` | - |
| `sub_142CC` | `Race_ApplyCrashWithAttackFlag` | rename-later | low | `[static]` | - |
| `sub_142FE` | `Race_UpdateActorRoadY` | rename-later | medium | `[static]` | - |
| `sub_1436E` | `Race_ScaleActorShadowSpeed` | rename-later | medium | `[static]` | - |
| `sub_14404` | `Race_HandleActorCollisionImpact` | rename-later | medium | `[static]` | - |
| `sub_14456` | `Race_SetActorFallShort` | rename-later | low | `[static]` | - |
| `sub_1446E` | `Race_SetActorFallLong` | rename-later | low | `[static]` | - |
| `sub_15580` | `Race_SetRandomFallState` | rename-later | medium | `[static]` | - |
| `unk_12B7C` | `Race_CollisionExtentTable` | rename-later | medium | `[static]` | - |
| `unk_12BCC` | `Race_CloseAttackReachTable` | rename-later | medium | `[static]` | - |
| `unk_13A1A` | `Race_LevelRespawnScale` | rename-later | high | `[static]/[dynamic]` E5-3 | - |
| `unk_14744` | `Race_ActionHandlerTable` | rename-later | high | `[static]` | - |
| `Race_TrackObjectTypeTable` | `Race_TrackObjectRecordTable` | rename-later | medium | `[static]` | `U-0014` resolved |
| `unk_147FC` | `Race_ActionHandlerIndexTable` | rename-later | high | `[static]` | - |
| `unk_155A4` | `Race_UnusedAnimationPtrList` | rename-later | low | `[static]` | - |
| `unk_155AC` | `Race_AnimationSequenceTable` | rename-later | medium | `[static]` | - |
| `unk_155D0` | `Race_FallSequenceTable` | rename-later | high | `[static]` | - |
| `unk_15618` | `Race_FallStateRand4` | rename-later | medium | `[static]` | - |
| `unk_1561C` | `Race_FallStateRand8A` | rename-later | medium | `[static]` | - |
| `unk_15624` | `Race_FallStateRand8B` | rename-later | medium | `[static]` | - |
| `Race_StaticActionTable` | `Race_StaticActorProfileTable` | rename-later | high | `[static]/[dynamic]` E3 | - |
| `ram_FF1A96` | `Race_ram_ActionDispatchBudget` | rename-later | high | `[static]/[dynamic]` E3 | - |
| `ram_FF1A98` | `Race_ram_ActionDispatchCount` | rename-later | high | `[static]/[dynamic]` E3 | - |
| `sub_1438E` | `Race_ApplyImpactLatch` | rename-later | medium | `[static]` | - |
| `sub_142D8` | `Race_SetWeaponAnimSpeedFlag` | rename-later | low | `[static]` | - |
| `RaceActor_TileBase` | `RaceActor_Stamina` | rename-later | high | `[confirmed]` E4-B + HUD | - |
| `ram_FF18AC` | `Race_ram_StaminaHitScale` | rename-later | high | `[confirmed]` E4-B | - |
| `ram_FF18A8` | `Race_ram_StaminaBaseline` | rename-later | medium | `[confirmed]` U-0017 | - |
| `ram_FF18AA` | `Race_ram_PlayerStaminaMax` | rename-later | high | `[confirmed]` HUD | - |
| `ram_FF3038` | `Race_ram_PairXWindow` | rename-later | medium | `[confirmed]` E4-F | - |
| `ram_FF303E` | `Race_ram_ImpactPenetration` | rename-later | medium | `[confirmed]` E4-F | - |
| `ram_FF3040` | `Race_ram_CollisionSideState` | rename-later | medium | `[confirmed]` E4-F | - |
| `ram_FF1768` | `Race_ram_CrashAnimActive` | rename-later | high | `[confirmed]` E4-F | - |
| `sub_138CE` | `Race_UpdateStaticSpawnCycle` | rename-later | high | `[static]/[dynamic]` E5-3 | - |
| `sub_13A26` | `Race_RespawnStaticActor` | rename-later | high | `[static]/[dynamic]` E5-4 | - |
| `sub_13BF4` | `Race_UpdateReservedOpponentSpawn` | rename-later | high | `[static]/[dynamic]` E5-2 | - |
| `sub_13CFE` | `Race_InitReservedOpponent` | rename-later | high | `[static]/[dynamic]` E5-2 | - |
| `ram_FF1F2A` | `Race_ReservedOpponent` | rename-later | medium | `[static]/[dynamic]` E5-2 | - |
| `word_B976` | `RaceTrack_SpawnAcceptThreshold` | rename-later | high | `[static]` | - |
| `word_B980` | `RaceTrack_SpecialSpawnCap` | rename-later | high | `[static]` | - |
| `off_B98A` | `RaceTrack_SpecialSpawnPages` | rename-later | high | `[static]` | - |
| `ram_FFDBD4` | `Race_ram_SpecialSpawnCursor` | rename-later | high | `[static]/[dynamic]` E5-2 | - |
| `ram_FF1B2E` | `Race_ram_MarkerRunLength` | rename-later | medium | `[static]` | - |
| `ram_FF1B30` | `Race_ram_MarkerSlot` | rename-later | high | `[static]/[dynamic]` E5-5 | - |
| `ram_FF1B32` | `Race_ram_ReservedSpawnTimer` | rename-later | medium | `[static]` | - |
| `ram_FF1B34` | `Race_ram_ReservedSpawnOffset` | rename-later | medium | `[static]` | - |
| `ram_FF1B36` | `Race_ram_ReservedSpawned` | rename-later | medium | `[static]` | - |
| `ram_FF1B3A` | `Race_ram_ReservedLastDistance` | rename-later | low | `[static]` | - |
| `Race_ram_LevelIndex` | `Race_ram_ReservedPageIndex` | rename-later | medium | `[static]/[dynamic]` E5-2 | - |
| `unk_D1A0` | `Race_PointsByPlace` | rename-later | high | `[static]/[dynamic]` E7-C | - |
| `unk_D1C0` | `Race_StandingsTemplate` | rename-later | high | `[static]/[dynamic]` E7-C | - |
| `sub_15014` | `Race_UpdateActorFallAnimation` | rename-later | high | `[static]/[dynamic]` E7-B | - |
| `sub_154D2` | `Race_StepAnimationScript` | rename-later | high | `[static]` | - |
| `unk_15CE0` | `Race_FallScriptSideA` | rename-later | high | `[static]/[dynamic]` E7-B | - |
| `unk_15CFC` | `Race_FallScriptSideB` | rename-later | high | `[static]/[dynamic]` E7-B | - |
| `ram_FF1E50` / `ram_FF1E52` | `Race_ram_CurveScrollA/B` | rename-later | medium | `[confirmed]` E6 | - |
| `ram_FF1E54` / `ram_FF1E56` | `Race_ram_CurveSumA/B` | rename-later | medium | `[confirmed]` E6 | - |
| `ram_FF1E58` / `ram_FF1E5A` | `Race_ram_CurveScaledA/B` | rename-later | medium | `[confirmed]` E6 | - |
| `ram_FF1E60` | `Race_ram_CameraY` | rename-later | high | `[confirmed]` E6 | - |
| `ram_FF1E64` | `Race_ram_CameraCollision` | rename-later | medium | `[confirmed]` E6 | - |
| `ram_FF1E6C` | `Race_ram_CurveByte` | rename-later | medium | `[static]/[dynamic]` E6 | - |
| `ram_FF1E76` | `Race_ram_ProgressBias` | rename-later | high | `[confirmed]` E6 | - |
| `ram_FF1E7A` / `ram_FF1E7E` / `ram_FF1E86` | unused camera fields | rename-later | high | `[static]` | - |
| `ram_FF30EA`/`EE`/`F2`/`F6`/`FA`/`FE` | `Race_ram_HScrollLayerA/B..` | rename-later | medium | `[static]/[dynamic]` E6 | - |
| `ram_FF310A`/`31D2`/`3236`/`329A`/`3362`/`D77C` | `Race_ram_Profile*` | rename-later | medium | `[static]/[dynamic]` E6 | - |
| `ram_FFDE72` | `Road_ram_ObjectCount` | rename-later | high | `[static]` L6b | - |
| `ram_FF1B48` | `Road_ram_ActorObjectCount` | rename-later | medium | `[static]` L6b | - |
| `ram_FF1B4A` | `Road_ram_TrackObjectDelta` | rename-later | medium | `[static]` L6b | - |
| `ram_FF1B50` / `ram_FF1C50` / `ram_FF1D50` | `Road_ram_ObjectKeys*`/visible | rename-later | high | `[static]` L6b | - |
| `ram_FF1B16` | `Race_ram_CustomAnimFlag` | rename-later | medium | `[static]` L6b | - |
| `ram_FF1B2E` | `Race_ram_MarkerRunLength` | rename-later | medium | `[static]` L5/L6b | - |
| `ram_FF1B30` | `Race_ram_MarkerSlot` | rename-later | high | `[static]/[dynamic]` E5 | - |
| `ram_FF1ACC` / `ram_FF1AC8` / `ram_FF1ACE` | `Race_ram_*Shape*` | rename-later | medium | `[static]` L6b | - |
| `ram_FF1AD9` / `ram_FF1ADC` | `Race_ram_LeanPhase`/`FallPhase` | rename-later | medium | `[static]` L6b | - |
| `ram_FFD338` / `ram_FFD33E` | `Race_ram_ShapeThresholds*` | rename-later | medium | `[static]` L6b | - |
| `Road_DrawStrip` | `SpriteStrip_Draw` | rename-later | medium | `[static]` L6c | - |
| `Road_InterpolateRightEdgeAlt` | `Road_InterpolateRightEdgeUnused` | rename-later | medium | `[static]` | - |
| `Road_WriteTileColumns` | `SpriteStrip_WriteTiles` | rename-later | high | `[static]`/`[confirmed]` golden replay | - |
| `word_3C7EA` | `Road_ShapeCount` | rename-later | high | `[static]` | - |
| `ram_FF0D2A` | `SpriteStrip_ram_SourcePtr` | rename-later | high | `[static]`/E8-A | - |
| `ram_FF0D2E` | `SpriteStrip_ram_PlaneOffsets` | rename-later | high | `[static]`/`[dynamic]` E8-A | - |
| `ram_FF102E` | `SpriteStrip_ram_RowOffsets` | rename-later | high | `[static]`/`[dynamic]` E8-A | - |
| `ram_FF132E` | `SpriteStrip_ram_ColumnCount` | rename-later | high | `[static]`/E8-A | - |
| `ram_FF1330` | `SpriteStrip_ram_RowCount` | rename-later | high | `[static]`/E8-A | - |
| `ram_FF1332` | `SpriteStrip_ram_HalfWidth` | rename-later | high | `[static]`/E8-A | - |
| `ram_FF133C` | `SpriteStrip_ram_Mirror` | rename-later | medium | `[static]` | - |
| `ram_FF133E` | `SpriteStrip_ram_Priority` | rename-later | medium | `[static]`/E8-B | - |
| `ram_FF135E` | `SpriteStrip_ram_Clip` | rename-later | high | `[static]`/E8-A | - |
| `ram_FF136A` | `SpriteStrip_ram_Horizon` | rename-later | medium | `[static]`/E8 | - |
| `ram_FFDE5E` | `SpriteStrip_ram_FillWord` | rename-later | high | `[static]`/E8 | - |

## Audit notes

- Total identifier rows: 668.
- `keep`: 521; `rename-later`: 146; `blocked-unknown`: 0; other: 1.
- Other verdicts: `ram_FF3274` (retain alias).
- Every identifier referenced by the analyzed source files has a row; renamed
  identifiers record their old and new names.
- Closed unknown IDs are marked `resolved` in the Unknown ID column; open rows
  keep the `U-xxxx` reference.
- Do not read the whole inventory during a normal pass; grep the symbol.

## Links

- Full table: `docs/analysis/identifiers_inventory.md`
- Unknown registry: `docs/analysis/unknowns.md`
- Rename rules: `docs/line-by-line-analysis.md` section 8
- Status dashboard: `docs/analysis/coverage.md`

# Analysis: gap data tables (`src/data/race_data_tables.asm`, `src/data/race_engine_tables.asm`,
`src/data/race_actor_extra_tables.asm`)

- **Status:** extracted + assembled byte-exactly; L2 actor/bike/track tables decoded
- **Source:** the three files above; included from `src/main.asm` around `binclude` chunks
- **Related:** `docs/modules/race_data_tables.md`, `docs/analysis/race_actors.md`,
  `docs/analysis/race_speed.md`, `docs/ram-map.md`

## Rider intro / results / end level (`$19A12-$19F61`)

| Label | Address | Size | Layout |
|---|---|---|---|
| `RiderIntro_RecordTable` | `$19A12` | `$320` | 5 levels x 10 tracks x 2 variants x 8-byte `(quote_ptr,image_ptr)`. |
| `RaceResults_LevelTablePos` | `$19D32` | `$A0` | 5 levels x 4 variants x 8-byte records. |
| `RaceResults_LevelTableNeg` | `$19DD2` | `$50` | 5 levels x 2 variants (negative money). |
| `RaceResults_CopTablePos` | `$19E22` | `$A0` | 5 cops x 4 variants. |
| `RaceResults_CopTableNeg` | `$19EC2` | `$50` | 5 cops x 2 variants (negative money). |
| `EndLevel_LevelRiderTable` | `$19F12` | `$50` | 5 levels x 2 variants (rival + Natasha). |

Evidence [static]: the quote records are in `src/screens/rider_intro_quotes.asm`; `RiderIntro_GameTick` indexes `d0` (0/8/0x10/0x18) + `(level-1)*$A0`
+ `track*$10`; results use `(index-1)*$20`/$10 with `rand & $18`/$8; end level uses
`(level-1)*$10` with `rand & 8`. All records are `(quote_ptr,image_ptr)` consumed by
`UncompressW` + `WriteTilesetToVRAM/WriteNametableToBuffer`. The 85 quote records used
only by `RiderIntro_RecordTable` are named `RiderIntro_Quote_<Rider>_<NN>`; the 70
results/end-level quotes keep `RaceQuote_<addr>`.

The `AudioFunc1..18` stubs at `$19F62` (audio) and the bytes after remain in the raw
bridge.

## Physics / engine (`$257D0-$25855`)

| Label | Address | Size | Layout |
|---|---|---|---|
| `unk_257D0` | `$257D0` | `$12` | 9 words copied to `RaceBike_ram_PhysicsConstants` (physics constants). |
| `unk_257E2` | `$257E2` | 6 | 3 words (engine timing). |
| `unk_257E8` | `$257E8` | 6 | 3 words (engine timing). |
| `unk_257EE` | `$257EE` | `$14` | 10 words (engine timing). |
| `unk_25802` | `$25802` | 8 | 2 longs copied to `ram_FFD330`. |
| `unk_2580A` | `$2580A` | 8 | 2 longs copied to `ram_FFD338`. |
| `unk_25812` | `$25812` | `$44` | 34 words used by `src/race/race_ai.asm`. |

`Race_InitPhysicsConstants` copies `unk_257D0` (9 words) and the two long pairs;
`Race_UpdateAttackPhase` reads `unk_257E2/E8/EE`; `race_ai` uses `unk_25812`.

## Actor / AI / bike control (`$259B6-$25EBF`)

| Label | Address | Size | Layout |
|---|---|---|---|
| `unk_259B6` | `$259B6` | `$A` | 5 words (race_core). |
| `Race_ActorProfileTable` | `$259C0` | `$50` | 40 words (race_ai). |
| `unk_25A10` | `$25A10` | `$34` | 13 actor-record pointers; index = `RaceActor_Type($16)*4`. |
| `Race_StaticActionTable` | `$25A44` | `$80` | 64 bytes/32 words (race_ai). |
| `unk_25AC4` | `$25AC4` | `$8C` | 8 blocks x 16 bytes + 6 trailing words (see below). |
| `unk_25B50` | `$25B50` | `$20` | 8 player-bike record pointers; index = `bikeId*4`. |
| `unk_25B70` | `$25B70` | `$350` | 424 words (race_core). |

### `unk_25A10` (actor bike records)

13 pointers, selected by `RaceActor_Type` (`$16`):

| Index | Target | Note |
|---|---|---|
| 0 | `RaceBike_ram_Parameters` | player copy loaded by `Race_LoadBikeData` |
| 1 | `ActorBikeRecord_18` | |
| 2 | `ActorBikeRecord_0` | |
| 3 | `ActorBikeRecord_1` | |
| 4 | `ActorBikeRecord_3` | |
| 5 | `ActorBikeRecord_5` | |
| 6 | `ActorBikeRecord_7` | |
| 7 | `ActorBikeRecord_9` | |
| 8 | `ActorBikeRecord_11` | |
| 9 | `ActorBikeRecord_13` | |
| 10 | `ActorBikeRecord_15` | |
| 11 | `ActorBikeRecord_19` | |
| 12 | `ActorBikeRecord_17` | |

`Race_LoadBikeData` copies 19 words from one of these into
`RaceBike_ram_Parameters`; index 0 is that same player buffer.

### `ActorBikeRecord_*` (19 words / `$26` bytes)

Consumed by `Race_UpdateActorSpeedState` and `Race_UpdateActorSpeedGear`:

| Offset | Meaning | Consumer |
|---|---|---|
| `+$00` | max gear index (all records `5`) | `cmp.w 0(a0),d1` |
| `+$02..+$0C` | acceleration for gears 0..5 | `move.w 2(a0,gear*2),d1` |
| `+$0E..+$18` | upshift threshold for gear 0..5 (`+$18` unused at max gear) | `move.w $E(a0,gear*2),d3` |
| `+$1A..+$24` | downshift threshold for gear 0..5 (`+$1A` is 0) | `cmp.w $1A(a0,gear*2),d0` |

Player example (`ActorBikeRecord_2`, bike id 0):

`max=5`, accel `$22,$1A,$15,$12,$10,$0E`, upshift
`$125C,$1838,$1E78,$23F0,$28A0,$2EE0`, downshift
`$0,$1518,$1BBC,$20D0,$25E4,$2A30`.

### `unk_25AC4` (steering / engine block)

8 blocks of 8 words (16 bytes): seven loaded fields + pad.

| Word | Destination |
|---|---|
| `+0` | `ram_FF1AA6` (lean steering divisor) |
| `+2` | `ram_FF1AAA` (lean multiplier, `$8000` = half) |
| `+4` | `RaceBike_ram_ReturnToStraightPower` |
| `+6` | `RaceBike_ram_SteeringPower` |
| `+8` | `RaceBike_ram_MaxSteering` |
| `+A` | `ram_FF1AB2` (curve speed scale) |
| `+C` | `ram_FF1AB4` (lean speed scale) |
| `+E` | pad (`$0000`) |

Record 0 = `$01D0,$8000,$0018,$0030,$0600,$00C0,$0100,$0000`.

**Static quirk:** `Race_LoadBikeData` computes `bikeId*16` in `d0` but never adds it
to `a0`; it always loads block 0. Blocks 1..7 and the 6 trailing words
(`$0020,$0018,$0010,$000C,$000A,$0008`) are therefore unreachable from this routine.
The checked-in dump confirms the loaded values are block 0.

### `unk_25B50` (player-bike selector)

8 longs, indexed by `bikeId*4`:
`ActorBikeRecord_2/4/6/8/10/12/14/16`. These are the user-selectable bikes; the
odd-index records in the same region are AI records referenced by `unk_25A10`.

## Track curve parameters (`unk_1471A`)

5 track records x 4 words, loaded by `Race_LoadTrackParams` into
`Race_ram_TrackParam0..3`:

| Track | Param0 | Param1 | Param2 | Param3 |
|---|---|---|---|---|
| 0 | `$E646` | `$AB6D` | `$B31A` | `$6658` |
| 1 | `$E646` | `$AB6D` | `$B31A` | `$6658` |
| 2 | `$E646` | `$AB6D` | `$B31A` | `$6658` |
| 3 | `$E646` | `$AB6D` | `$9984` | `$4CC2` |
| 4 | `$E646` | `$AB6D` | `$B31A` | `$6658` |

Roles:

- Param0 = on-road base curve-speed limit.
- Param1 = loaded but never read (`src/` grep).
- Param2 = off-road curve-speed limit.
- Param3 = off-road limit while `$68` bit5 (curve already active) is set.

`word_14742` (`$4CC2`) is the `$78`-timer fallback limit in
`Race_UpdateBikeCurve`; because `$78` is never set non-zero it is unreachable.
`unk_14056` (race_anim_audio) is a 10-word curve scale table indexed by
`RaceActor_GraphicsIndex` (`$75`): `$0138,$0130,$0128,$0120,$0110,$0160,$0150,
$0140,$0130,$0120`.

## Open questions

- Exact engine-timing semantics of `unk_257E2/E8/EE` (audio deferred).
- Field meanings of `unk_25812`, `Race_ActorProfileTable`, `Race_StaticActionTable`,
  `unk_25B70`.
- Whether the missing `unk_25AC4` index add was an original bug or a deliberate fixed
  block (behavior is unambiguous; blocks 1..7 are dead).
- Dynamic checks for the intro/results selection and engine audio.

## Rename proposals

No renames were applied in this pass. Candidate names and verdicts live only in
`docs/analysis/identifiers.md` (L2 rows).

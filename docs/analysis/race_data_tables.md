# Analysis: gap data tables (`src/data/race_data_tables.asm`, `src/data/race_engine_tables.asm`,
`src/data/race_actor_extra_tables.asm`)

- **Status:** extracted + assembled byte-exactly; semantics partial
- **Source:** the three files above; included from `src/main.asm` around `binclude` chunks
- **Related:** `docs/modules/race_data_tables.md`, `docs/analysis/race_actors.md`,
  `docs/ram-map.md`

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
`UncompressW` + `WriteToVRAM/WriteNametableToBuffer`.

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
`Audio_UpdateEngineState` reads `unk_257E2/E8/EE`; `race_ai` uses `unk_25812`.

## Actor / AI (`$259B6-$25EBF`)

| Label | Address | Size | Layout |
|---|---|---|---|
| `unk_259B6` | `$259B6` | `$A` | 5 words (race_core). |
| `Race_ActorProfileTable` | `$259C0` | `$50` | 40 words (race_ai). |
| `unk_25A10` | `$25A10` | `$34` | 13 actor-data pointers. |
| `Race_StaticActionTable` | `$25A44` | `$80` | 64 bytes/32 words (race_ai). |
| `unk_25AC4` | `$25AC4` | `$8C` | 70 words (race_core). |
| `unk_25B50` | `$25B50` | `$20` | 16 words (race_core). |
| `unk_25B70` | `$25B70` | `$350` | 424 words (race_core). |

`unk_25A10` is dereferenced as `movea.l (a3,d0.w),a3` (13 pointers). The other tables are
read as words/bytes; exact field meanings are TODO. `unk_25EC0` and the per-track
records/streams are now in `src/data/race_track_data.asm` (see `docs/analysis/race_track_data.md`).

## Open questions

- Exact engine-timing semantics of `unk_257E2/E8/EE` (audio deferred).
- Field meanings of `unk_25812`, `Race_ActorProfileTable`, `Race_StaticActionTable`, `unk_25AC4`, `unk_25B50`,
  `unk_25B70`.
- Whether `unk_25A10` target tables contain actor definitions or graphics records.
- Dynamic checks for the intro/results selection and engine audio.

## Rename proposals

The table labels above preserve the existing names; internal fields are TODO.

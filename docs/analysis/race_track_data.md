# Analysis: `src/data/race_track_data.asm` (per-track records + streams)

- **ROM range:** `0x025EC0`–`0x03BF19` (`Road_ShapeTable`/shape data follows in `src/data/road_shapes.asm`)
- **Status:** records/level tables, Data2/3 decoder, Data4 object runs, Data5 spawn records and Data6 bundle header analyzed; exact Data4 side/second-shape bits partly TODO
- **Source:** `src/data/race_track_data.asm` (record/level tables from source, streams
  `binclude` from `baserom.md`)
- **Related:** `docs/analysis/track_data.md`, `docs/analysis/race.md`,
  `docs/analysis/race_data_tables.md`, `docs/modules/race_track_data.md`

## Record format

`unk_25EC0[Menu_ram_CurrentTrackId]` is a pointer to a `0x18`-byte record:

| Offset | Field |
|---|---|
| `+$00` | pointer to the 5-word level table (levels 1..5); loaded as `RaceTrack_Data1` |
| `+$04` | `RaceTrack_Data2` (track decoder stream) |
| `+$08` | `RaceTrack_Data3` (track decoder stream) |
| `+$0C` | `RaceTrack_Data4` |
| `+$10` | `RaceTrack_Data5` (spawn records) |
| `+$14` | `RaceTrack_Data6` (background graphics/palette) |

Evidence [static]: `Race_InitTrack` (`src/race/race_core.asm`) does `movea.l (a0,d0),a0`,
`movea.l (a0)+,a1`, indexes the level words, then copies `(a0)+` into
`RaceTrack_Data2..Data6`. `Menu_BuildRaceTooltip` reads the same record and scales the
level word by `*$10/$210`.

The 5-word level table immediately follows the record (`record+$18`). The streams are
stored in memory order `Data2,Data3,Data4,Data6,Data5`; each size below is the distance
to the next stream boundary (the last `Data5` ends at `Road_ShapeTable`).

## Track records

| Track | Record | Level words | Streams in memory order (address, Data, bytes) |
|---|---|---|---|
| 0 | `$025ED4` | `$025EEC` | `$025EF6` Data2 2818; `$0269F8` Data3 3980; `$027984` Data4 4282; `$028A3E` Data6 6998; `$02A594` Data5 476 |
| 1 | `$02A770` | `$02A788` | `$02A792` Data2 2268; `$02B06E` Data3 3988; `$02C002` Data4 3210; `$02CC8C` Data6 6216; `$02E4D4` Data5 540 |
| 2 | `$02E6F0` | `$02E708` | `$02E712` Data2 2534; `$02F0F8` Data3 3938; `$03005A` Data4 4446; `$0311B8` Data6 4556; `$032384` Data5 600 |
| 3 | `$0325DC` | `$0325F4` | `$0325FE` Data2 2962; `$033190` Data3 3810; `$034072` Data4 4354; `$035174` Data6 4786; `$036426` Data5 780 |
| 4 | `$036732` | `$03674A` | `$036754` Data2 2326; `$03706A` Data3 4076; `$038056` Data4 8842; `$03A2E0` Data6 6762; `$03BD4A` Data5 464 |

Level words:

| Track | L1 | L2 | L3 | L4 | L5 |
|---|---|---|---|---|---|
| 0 | `$073F` | `$0A0A` | `$0D5C` | `$104A` | `$13F6` |
| 1 | `$06F4` | `$0A1E` | `$0D48` | `$12AC` | `$13C4` |
| 2 | `$0712` | `$0A32` | `$0D52` | `$1090` | `$136A` |
| 3 | `$076C` | `$0A0A` | `$0D34` | `$104A` | `$1342` |
| 4 | `$06B3` | `$0A1E` | `$0D48` | `$107C` | `$1360` |

## Consumers

- `Race_InitTrack`: selects the record and copies `Data1..Data6`.
- `src/race/track_data.asm` decodes `Data2`/`Data3` into the road/profile buffers.
- Spawn/object code uses `Data5` (`Race_SpawnOpponents`) and `Data4`.
- `Race_DrawTrackBackground` (via `RaceTrack_Data6`) loads background graphics/palette.
- `Menu_BuildRaceTooltip`: level word -> `*$10/$210` -> decimal in the tooltip.

## Data4 object-run stream

`Race_BuildTrackObjects` walks 4-byte entries at `RaceTrack_Data4`; a word
`$FFFF` terminates the stream and wraps back to `Data4` start.

| Offset | Field | Evidence |
|---|---|---|
| `+$00` bits 0-6 | object/shape selector; mapped to `shape = value + $186` | `[static]` `10AA6` |
| `+$00` bits 8-12 | run count minus 1 (0..31) | `[static]` `10A1A`, `10A5E` |
| `+$00` bits 14-15 | side/mirror flags; bit7 also feeds the side flag | `[static]` `10A78`; exact pairing TODO |
| `+$02` high nibble | spacing divisor minus 1 (`d2 = nibble + 1`) | `[static]` `10A1A` |
| `+$02` bits 8-10 | flags ORed into `RoadObject_Flags` | `[static]` `10AFC-10B48` |
| `+$02` low byte | object parameter stored at record `+$10` | `[static]` `10B48` |
| `+$02` remaining bits | second-shape/parameter source | TODO |

The shape selector `$7F` maps to `$205`, which the builder treats as a special
control/skip entry. Other mapped shapes are written to `RoadObject_Shape` (`+8`).
Track 0 starts `007F A000, 8039 01AC, 81FA 0015, 81FC 0016, ...`; the stream ends with
`$FFFF` (the following word is also `$FFFF` padding), then the six-byte Data6 header
starts at `Data6-6`.

## Data5 spawn records

`Race_SpawnOpponents` expands 4-byte records into the normal list at
`ram_FFD7D4` and the special/traffic list at `ram_FFDBD8`; `$FFFFFFFF` terminates.

| Bits | Meaning | Evidence |
|---|---|---|
| high word | progress/distance threshold | `[static]` `sub_13BF4`, `Race_AddStagedObjects` |
| bit4 | randomize low nibble (0..15) | `[static]` `B934` |
| bit5 | special/traffic list; append colour byte | `[static]` `B94A` |
| bits 8-11 | level/type index | `[static]` `sub_13BF4`; staged object uses byte2 as type |
| bits 0-3 | lane/spawn offset (`*$20 - $100`) | `[static]` `sub_13BF4`, `Race_AddStagedObjects` |
| other bits | flag bits preserved in the record | TODO |

The per-level gates are `word_B976` (random acceptance threshold), `word_B980`
(max coloured entries), and `off_B98A` (colour lists). Normal records are used by
the level/opponent event path and the staged-object builder; the special list
records have byte 2 replaced by the colour byte.

`[dynamic]` Demo normal list starts `00A7 0218, 01A5 0118, 02BC 050F, ...`;
special list starts `02D6 022F` then `FFFFFFFF`. This matches progress-high /
lane-low / level-byte field mapping.

## Data6 background bundle

`RaceTrack_Data6` points at the `UncompressB` source stream; the six bytes
immediately before it are physically the tail of Data4 and form its header:

| Word | Meaning | Track 0 | Track 1 |
|---|---|---|---|
| `Data6-6` | tile-data offset (normally 0) | `$0000` | `$0000` |
| `Data6-4` | nametable offset in decompressed image | `$2024` | `$1F64` |
| `Data6-2` | palette offset in decompressed image | `$1FA4` | `$1EE4` |

`Race_LoatTrackGfx` decompresses Data6 into `Intro_ram_ImageBuffer`, then:
- tiles at `base + (Data6-6)` -> VRAM `$1000`;
- nametable at `base + (Data6-4) + 4` -> BG/FG planes;
- palette at `base + (Data6-2) + $22` -> `Global_ram_PalettePtr + $22`.

`Race_LoadMoreTrackGfx` loads additional per-track plane data; it is separate from
the Data6 bundle. Rendered previews are available as `assets/images/race_track_background_0..4`
(generated by `tools/assets.py all`; see `assets/review.html`). Visual review identifies
them as stacked far/near background strips; `race_image_0` is the cloud parallax layer.
`race_track_background_0` is runtime-verified by `tools/asset_verify.py`
(`docs/analysis/asset_verification.md`).

## Open questions

- Data4 side/mirror bit pairing, the `+$02` remaining bits and second-shape
  generation.
- Data5 other flag bits and the exact normal-vs-special consumer split.
- Meaning of the level word and the `*$10/$210` scaling.
- Dynamic verification of Data6 decompression offsets and palette rows.

## Rename proposals

No renames applied; the existing `unk_25EC0`/`Track_*` labels are kept.

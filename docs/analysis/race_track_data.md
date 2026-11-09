# Analysis: `src/data/race_track_data.asm` (per-track records + streams)

- **ROM range:** `0x025EC0`–`0x03BF19` (`Road_ShapeTable`/shape data follows in `src/data/road_shapes.asm`)
- **Status:** records/level tables and stream boundaries analyzed; stream formats TODO
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

## Open questions

- Formats of `Data2..Data6` (compressed streams, spawn records, graphics).
- Meaning of the level word and the `*$10/$210` scaling.
- Exact `Data4`/`Data6` consumers and the shape format in `src/data/road_shapes.asm`.
- Dynamic verification of track selection/loading.

## Rename proposals

No renames applied; the existing `unk_25EC0`/`Track_*` labels are kept.

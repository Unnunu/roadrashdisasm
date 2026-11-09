# Module card: `race_track_data.asm`

- **ROM range:** `0x025EC0`–`0x03BF19` (`Road_ShapeTable` starts at `0x3BF1A`)
- **Status:** records/labels + stream boundaries extracted; stream formats TODO
- **Related:** `docs/analysis/race_track_data.md`, `docs/analysis/track_data.md`,
  `docs/analysis/race.md`, `docs/analysis/race_data_tables.md`,
  `docs/ram-map.md`

## Role / purpose

Five per-track records selected by `Menu_ram_CurrentTrackId`; each record points at a
5-word level table and five data streams (`RaceTrack_Data2..Data6`) consumed by the
track decoder, spawn and background/graphics code. The stream bytes are opaque
compressed data included from `baserom.md`; the record/level tables are assembled from
source.

## Coverage matrix

| Function / data | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|-----------------|---------|----------|-----------|------|----------|-----|---------|--------|
| `unk_25EC0` (track pointers) | `0x25EC0` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `Track_Record0..4` | `0x25ED4`+ | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `Track_LevelWords0..4` | `0x25EEC`+ | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `Track_Data2..Data6_0..4` | stream ranges | [x] | - | [~] | - | [~] | [ ] | data-only |

Detailed analysis: `docs/analysis/race_track_data.md`.

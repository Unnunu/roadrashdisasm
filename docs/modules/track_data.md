# Module card: `src/race/track_data.asm`

- **ROM range:** `0x009FE4`–`0x00A4E1` (`src/race/race.asm` starts at `0xA4E2`)
- **Status:** analyzed (algorithm and dynamic stream start confirmed; channel semantics
  partly TODO)
- **Related:** `docs/architecture.md`, `docs/ram-map.md`,
  `docs/analysis/track_data.md`

## Role / purpose
Two-channel delta/bit-packed decoder for the track (road curve/height) data. The race
decodes the level data in chunks into `Track_CurveBuffer` and scales the first channel by the
track/level factor.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `TrackData_StartDecode` | `0x9FE4` | `src/race/race.asm` `TrackData_InitLevel` | Initialize the streams/output and decode the first chunk. |
| `TrackData_DecodeChunk` | `0xA04A` | `TrackData_StartDecode`, `src/race/race.asm` `TrackData_DecodeNextChunk` | Decode the next per-call chunk. |
| `TrackData_DecodeChannel1` | `0xA0D4` | `TrackData_DecodeChunk` | Channel 1 decoder. |
| `TrackData_DecodeChannel2` | `0xA2DA` | `TrackData_DecodeChunk` | Channel 2 decoder. |

## External calls / dependencies
- `src/race/race.asm` `TrackData_InitLevel`/`TrackData_DecodeNextChunk` (start and per-progress chunks).
- `src/core/top_level.asm` calls `TrackData_DecodeNextChunk` when the race progress crosses a chunk.

## Hacks / bugs / quirks
- The second channel is decoded but left unscaled by the race callers. `[static]`
- `$FF` shift-table entries implement the cross-byte bit extraction. `[static]`
- Output is a 2-byte-strided interleaved array. `[static]`

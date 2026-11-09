# Module card: `track_data.asm`

- **ROM range:** `0x009FE4`–`0x00A4E1` (`race.asm` starts at `0xA4E2`)
- **Status:** analyzed (algorithm and dynamic stream start confirmed; channel semantics
  partly TODO)
- **Related:** `docs/architecture.md`, `docs/ram-map.md`,
  `docs/analysis/track_data.md`

## Role / purpose

Two-channel delta/bit-packed decoder for the track (road curve/height) data. The race
decodes the level data in chunks into `ram_FFDC58` and scales the first channel by the
track/level factor.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `TrackData_StartDecode` | `0x9FE4` | `race.asm` `TrackData_InitLevel` | Initialize the streams/output and decode the first chunk. |
| `TrackData_DecodeChunk` | `0xA04A` | `TrackData_StartDecode`, `race.asm` `TrackData_DecodeNextChunk` | Decode the next per-call chunk. |
| `TrackData_DecodeChannel1` | `0xA0D4` | `TrackData_DecodeChunk` | Channel 1 decoder. |
| `TrackData_DecodeChannel2` | `0xA2DA` | `TrackData_DecodeChunk` | Channel 2 decoder. |

## Frame/stream format

- Each input stream: 16-bit control length, control bytes, then a bit-packed data
  stream.
- Control byte: high nibble = run length-1; bit3 = sign; low 3 bits = width-1.
- Per sample: extract the next `width` bits MSB-first, add/subtract the delta to the
  running accumulator, write the byte; 2-byte stride (channel 1 at `a1`, channel 2 at
  `a1+1`).
- Tables: `TrackData_BitMasks` (masks), `TrackData_ShiftCounts` (shift counts incl. `$FF` cross-byte),
  `TrackData_CrossByteMasks`/`TrackData_BoundaryShifts` (cross-byte masks).
- Budget `d1` samples per channel per call; the state is resumable.

## RAM / ROM & structures

- Sources `RaceTrack_Data2/3` (`$FF1A52/$FF1A56`); output `ram_FFDC58` (`$FFDC58`),
  4 x `$80`-byte chunks.
- Channel 1 state `ram_FF13B2/13B8..13E2`; channel 2 `ram_FF13E4..140E`.
- Scale: `Menu_ram_CurrentTrackId` -> `off_16AB0` -> `ram_FF1A6C` (per-track table);
  factor `[PlayerLevel-1]`; signed byte * factor / `$10000`.
- Race callers: `TrackData_InitLevel` (128 samples at level start), `TrackData_DecodeNextChunk` (64-sample chunks
  as the race progresses).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `TrackData_StartDecode` | `0x9FE4` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `TrackData_DecodeChunk` | `0xA04A` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `TrackData_DecodeChannel1` | `0xA0D4` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `TrackData_DecodeChannel2` | `0xA2DA` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |

Detailed listing: `docs/analysis/track_data.md`.

## External calls / dependencies

- `race.asm` `TrackData_InitLevel`/`TrackData_DecodeNextChunk` (start and per-progress chunks).
- `top_level.asm` calls `TrackData_DecodeNextChunk` when the race progress crosses a chunk.

## Hacks / bugs / quirks

- The second channel is decoded but left unscaled by the race callers. `[static]`
- `$FF` shift-table entries implement the cross-byte bit extraction. `[static]`
- Output is a 2-byte-strided interleaved array. `[static]`

## Verified facts

- `[static]` Control/bit-packed format, tables and resumable state.
- `[dynamic]` Demo level start: `a1=$FFDC58`, `a2=$25EF6`, `a3=$269F8`, `d1=$7F`;
  stream lengths `$771`/`$A62`.
- `[static]` Level scaling `signed byte * factor / $10000`.

## Hypotheses

- `[hypothesis]` Channel 1 is the road height/curve and channel 2 a second
  derivative/flag; test: decode a track and compare with the road renderer.
- TODO: exact meaning of the two channels and the 4-chunk buffer timing.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `TrackData_StartDecode` | `TrackData_StartDecode` | initializes streams/output | high |
| `TrackData_DecodeChunk` | `TrackData_DecodeChunk` | per-call budget | high |
| `TrackData_DecodeChannel1`/`TrackData_DecodeChannel2` | `TrackData_DecodeChannel1/2` | interleaved outputs | high |
| `ram_FFDC58` | `Track_CurveBuffer` | decoded/scaled track data | medium |

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Capture stream start | GDB demo, `0x9FE4` | a1=$FFDC58, a2=$25EF6, a3=$269F8, d1=$7F | start format confirmed |

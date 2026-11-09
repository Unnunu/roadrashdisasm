# Analysis: `src/race/track_data.asm` (track/road data decompressor)

- **Module:** two-channel delta/bit-packed decoder for the track (road curve/height)
  data, with a resumable per-call budget
- **ROM range:** `0x009FE4`–`0x00A4E1` (`src/race/race.asm` starts at `0xA4E2`)
- **Status:** analyzed (algorithm + dynamic start/streams confirmed; channel semantics
  partly TODO)
- **Source:** `src/race/track_data.asm`
- **Related:** `docs/architecture.md`, `docs/ram-map.md`, `docs/analysis/road_render.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `TrackData_StartDecode` | `0x9FE4` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `TrackData_DecodeChunk` | `0xA04A` | [x] | [x] | [x] | - | [x] | [x] | analyzed |
| `TrackData_DecodeChannel1` (channel 1) | `0xA0D4` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `TrackData_DecodeChannel2` (channel 2) | `0xA2DA` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |

## Role & callers

`src/race/race.asm` `TrackData_InitLevel` (level start) and `TrackData_DecodeNextChunk` (as the race progresses) call this
decoder to expand the level's track data into `Track_CurveBuffer` and scale it by the track/
level factor.

- `TrackData_InitLevel`:
  - `Menu_ram_CurrentTrackId*2` -> `off_16AB0` -> `ram_FF1A6C` (per-track factor table
    pointer).
  - `a2 = RaceTrack_Data2`, `a3 = RaceTrack_Data3`, `a1 = Track_CurveBuffer`, `d1 = $7F`
    (128 values) -> `TrackData_StartDecode`.
  - Then scale the first channel: factor `d2 = ram_FF1A6C[PlayerLevel-1]`; each signed
    byte `Track_CurveBuffer[2*i] * d2 / $10000` (mulu/swap with sign), 128 entries.
- `TrackData_DecodeNextChunk` (called from `src/core/top_level.asm` when the race progress crosses a chunk):
  chunk `(d0+1)&3`, destination `Track_CurveBuffer + chunk*$80`, `d1=$3F` (64 values) ->
  `TrackData_DecodeChunk`; scale the 64 first-channel entries the same way.

## Stream format

Each of the two input streams (`a2`, `a3`) starts with a 16-bit **control length**;
the control bytes follow, then a bit-packed data stream (the data pointer is
`stream + 2 + control_length`). `TrackData_StartDecode` sets the state, then `TrackData_DecodeChunk` runs both
channels; the output is interleaved: channel 1 at `a1, a1+2, ...`, channel 2 at
`a1+1, a1+3, ...` (2 bytes per entry).

Control byte:

| Bits | Meaning |
|---|---|
| `7..4` | run length - 1 (1..16 samples). |
| `3` | sign: 1 = subtract the delta, 0 = add. |
| `2..0` | bit width - 1 (1..8 bits per delta). |

Per sample the decoder extracts the next `width` bits (MSB-first) from the data
stream, adds/subtracts the delta to the running accumulator, and writes the byte.
The bit reader uses `TrackData_BitMasks` (current-byte masks), `TrackData_ShiftCounts` (shift counts; `$FF`
entries cross into the next byte), `TrackData_CrossByteMasks`/`TrackData_BoundaryShifts` (cross-byte masks). The tables
are the 8x8 mask/shift sets (values such as `$80,$C0,$E0,...` and `7,6,5,...,0`).

## State

Channel 1 (`TrackData_DecodeChannel1`):

- `ram_FF13B8` accumulator, `ram_FF13B9` current data byte, `ram_FF13BA` decoded delta.
- `ram_FF13BC` control index, `ram_FF13C2` sign, `ram_FF13C4` run remaining,
  `ram_FF13C6` width, `ram_FF13C8` sample counter.
- `ram_FF13CA`/`CC` table index/mask, `ram_FF13CE` bit position, `ram_FF13D0`/`D2`
  data-byte index, `ram_FF13D4` data pointer, `ram_FF13D8` output pointer,
  `ram_FF13DC` control length, `ram_FF13DE` control pointer, `ram_FF13E2` caught-up
  flag, `ram_FF13B2` remaining budget.

Channel 2 (`TrackData_DecodeChannel2`) is the same with `ram_FF13E4`..`ram_FF140E` and the output
pointer `ram_FF1404`.

`TrackData_StartDecode` initializes both channels, the output pointers, and the budget; `TrackData_DecodeChunk`
can be re-called for the next chunk (the state is fully resumable). The budget `d1` is
the number of samples per channel per call.

## Dynamic sample (demo race)

`TrackData_StartDecode` at the level start: `a1=$00FFDC58`, `a2=$00025EF6`, `a3=$000269F8`,
`d1=$007F`; stream lengths `$0771` (a2) and `$0A62` (a3); the control bytes follow the
lengths; the data streams are bit-packed in the ROM gap.

## Output buffer

`Track_CurveBuffer` (`$FFDC58`), 4 chunks of `$80` bytes (the initial call fills two chunks,
the per-progress calls fill the next 64-entry chunks). The first channel byte is
scaled by the track/level factor; the second channel byte is left unscaled by the race
caller. The exact meaning of the two channels (e.g. curve/height vs. a second
derivative/flag) is **TODO**; the first channel is the signed value scaled per level.

## Quirks / notes

- The tables contain `$FF` shift entries for the cross-byte extraction; the negative
  branch in the decoder handles those. `[static]`
- The second channel is decoded but not scaled by `TrackData_InitLevel`/`TrackData_DecodeNextChunk`. `[static]`
- The decoder writes with a 2-byte stride; the output is a 16-bit interleaved array.
  `[static]`
- The track data streams are in the not-yet-disassembled gap; the dynamic start
  pointers were captured above.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `RaceTrack_Data2/3` | `Track_DataStream1/2` | decoder sources | medium |


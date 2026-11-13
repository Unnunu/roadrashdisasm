# Analysis: `src/race/race_physics.asm` (camera, HInt scroll, rearview, nearest opponent)

- **Module:** VDP DMA helpers, rearview mirror/camera, HInt V/HScroll tables,
  road-marking HUD, actor-sprite projection, nearest-opponent/engine audio
- **ROM range:** `0x00D8FA`–`0x00E731`
- **Status:** L6a camera/VScroll/HScroll contract complete (matrix v10, E6); the
  compaction arithmetic is closed (`U-0018`, matrix v13); rearview mirror and
  engine-audio mapping remain `[static]`/TODO
- **Source:** `src/race/race_physics.asm`
- **Related:** `docs/analysis/race.md`, `docs/analysis/race_spawn.md`,
  `docs/analysis/race_ai_road.md`, `docs/modules/race_physics.md`, `docs/ram-map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `DmaWriteVRAM` | `0xD8FA` | VDP DMA: length/source/dest + `Race_ram_VdpDmaControl` control. |
| `DmaWriteCRAM` | `0xD92C` | Same for CRAM (`$C000` control). |
| `Race_DrawRearviewMirror` | `0xD9DA` | Rearview mirror road; player X/Y, HUD row 25, `Race_ram_RearviewTileRows`. |
| `Race_DrawMirrorRoad` | `0xDA3E` | Mirror road rows; palette/priority `$8000800` XOR. |
| `Race_ProjectActorSprite` | `0xDAE2` | Actor position vs player progress -> sprite Y/X. |
| `Race_DrawRoadMarkingHud` | `0xDD84` | Road marking in the HUD/mirror; widths/data A/B. |
| `Race_UpdateCamera` | `0xDE9E` | Camera offset, player progress and curve integration. |
| `Race_BuildVScrollInfo` | `0xE004` | HInt VScroll/raster layer table. |
| `Race_BuildHScrollTable` | `0xE494` | Per-line HInt HScroll (plane A/B) table. |
| `Race_UpdateNearestOpponent` | `0xE5EE` | Nearest ahead/behind actor; engine audio values. |

Data: `Race_RoadMarkingDataA/B` (`0xDC84`/`0xDD44`), `Race_ram_RearviewTileRows` road rows,
`ram_FF3238`/`RoadMarking_ram_WidthArray`/`ram_FF3A9C`.

## Key flow

- `Race_Update` calls `Race_UpdateCamera` before the frame-ready check; after the road
  profile it calls `Race_BuildVScrollInfo`; after the visible list
  `Race_DrawRoadMarkingHud`; at the end `Race_DrawRearviewMirror` and
  `Race_BuildHScrollTable`. The player/actor chain calls `Race_UpdateNearestOpponent`.
- `Race_GameTick` uses `DmaWriteVRAM` for the HUD/HScroll/SAT and `DmaWriteCRAM` for the
  palette. It also applies VScroll block 0 at VBlank and stores block 0's next offset
  in `Race_ram_HIntScrollOffset`.
- `Race_BuildVScrollInfo`/`Race_BuildHScrollTable` fill the per-frame
  `Race_ram_CurrentVScrollInfo`/`CurrentHScrollTable` buffers consumed by the HInt
  (`src/main.asm` `HorizontalInterrupt`).

## `Race_UpdateCamera` (`0xDE9E`, L6a contract)

`[static]` + E6 (`analysis/capture_L6a.gdb`, `capture_L6a_camforce.gdb`):

- Camera offset:
  - PlayerA `$68` bit4 clear -> `Race_ram_CameraOffset = 0` (the demo path).
  - bit4 set and `Race_ram_State == 0`: `$6E < 2` adds `FrameDistance >> 4` (negated
    when `$69` bit3 = off-road) and clamps at `-$7000`; `$6E >= 2` decays
    `offset -= offset >> 2`.
- Camera Y: `ram_FF1E60 = (PosY>>1) + (PosY>>2) + ram_FF1E7A`. `$1E7A` has no writer
  in `src/` (zeroed at init), so this is `3*PosY/4`. The block after `.loc_DF14` that
  would smooth `$1E60` through `$1E86` is skipped by `bra.w .loc_DF6E`; `$1E86` is dead.
- Camera collision: `ram_FF1E64 = ($32>>1) + ram_FF1E7E + $5D`, with a `$5D` floor.
  `$1E7E` also has no writer -> 0. `$1E66` is the low word of this long field.
- Progress: `Race_ram_PlayerProgress = PlayerA.X - ram_FF1E76 - CameraOffset`.
  `ram_FF1E76` is set to `$8000` by `Race_CreateActors`; `$1E6A` is the low word of
  32-bit `PlayerProgress` (`$1E68`).
- Curve walk: the high word of the old and new progress selects the byte-pair index
  in `Track_CurveBuffer` (`index = (progress>>16 & $FF)*2`). The absolute high-word
  delta is walked; the two signed curve bytes are accumulated into `ram_FF1E54`
  (first byte) and `ram_FF1E56` (second byte), with direction fixed by the sign of
  the delta. The low 16 bits are not part of the walk.

E6 observations:

| Check | Evidence |
|---|---|
| E6-1 normal demo | `PlayerProgress = X - $8000 - CameraOffset` (cam 0): `$00080000 -> $00078000`; `$1E60=$78` from PosY `$A0`; `$1E64=$5D`. |
| E6-2 curve walk | progress `$001CE1EF` -> `$0060F69F`: `$1E54=0/$1E56=2`, `$1E58/$1E5A` track the current/next scaled byte; `$1E6A` follows the progress low word. |
| E6-3 forced camera | force `$68` bit4 + `$6E=0`: `FD=$1FE0 -> CameraOffset=$1FE`; `AnimState=2/3` decays `$1FE -> $1AE -> ... -> 3`; progress tracks the offset. |

## `Race_BuildVScrollInfo` (`0xE004`, L6a contract)

`[static]` + E6 (`analysis/capture_L6a.gdb`, `capture_L6a_hint.gdb`):

The VScroll buffer is an array of 16-byte blocks. `HorizontalInterrupt` reads six
words from a block at `$A0+offset`:

| Block offset | Meaning |
|---|---|
| `+0` | VDP control word; upper byte `$8A` selects VDP reg `$A`, low byte = HInt line gap. |
| `+2` | HV counter target (high byte = line, low byte = H counter phase). |
| `+4` | VDP register write; `$873F`/`$873E` = backdrop colour `$3F`/`$3E`. |
| `+6` | VSRAM word A (vertical scroll). |
| `+8` | VSRAM word B. |
| `+A` | Next block offset (`$90` = sentinel / once-per-frame audio trigger). |
| `+C`,`+E` | Builder metadata used by the compaction pass, not read by the HInt. |

- Block 0 is the VBlank entry: `Race_GameTick` writes `+0`, `+4`, `+6/+8` directly and
  loads `Race_ram_HIntScrollOffset` from `+A` (= `$10`).
- Blocks `$10..$80` are built back to front; `$70` clamps alpha to `[$10,$98]`,
  `$60`/`$50` derive the horizon/road-top bands from `ram_FF3274`, and `$80` is the
  fixed bottom/sky block (`VSRAM -8,-8`, backdrop `$3F`, next `$90`).
- The compaction pass (`U-0018` closed) uses `+E` as the band line reference
  (`HV = (E<<8) - $A0`) and runs four phases:
  1. `.loc_E2AE` elide: while the candidate block (`d0 = +A`) has `+E < 0`, copy its
     `+2/+4/+6/+8/+A/+E` fields into block 0 and continue with the copied `+A`.
  2. `.loc_E2E4` first-band merge: while `+E <= 8`, copy the candidate into block
     `$10` and advance; then `E10 = max(E, 4)`, `HV10 = (E10<<8)-$A0`, block0.`+A=$10`.
  3. `.loc_E33E` second-band merge: with `d2 = E10+8`, while `+E <= d2`, copy the
     candidate into block `$20`; then `E20 = max(E, E10+4)`, `HV20 = (E20<<8)-$A0`,
     block`$10.+A=$20`, block0.`+0=$8A01`.
  4. `.loc_E3B6` gap loop: starting at `$10`, for `d1`, `d2=next(d1)`,
     `d3=next(d2)`, while `d3 < $90` write
     `block[d1].+0 = $8A00 + E(d3) - E(d2) - 1` and continue at `d2`. The last
     editable band retains its build-time `$8AFF`.
  A provisional `block$10.+0 = E(block$20.next)-9+$8A00` is written before the loop
  and is normally overwritten by its first iteration. Tail: `+C=$8210`, `+E=$8403`.
  E6 check: lines `$04/$08/$26/$34/$48/$9D` produce
  `$8A1D/$8A0D/$8A13/$8A54/$8AFF` and the chain
  `$10->$20->$50->$60->$70->$80->$90`; `$30/$40` disappear in phase 3. These values
  match `$8A00+E(d3)-E(d2)-1` exactly (`analysis/notes/L6a_hint_trace.txt`).
- `ram_FF3274` is the last index of the road-profile index array (`ram_FF3236[31]`),
  i.e. the horizon line; it is not a separate variable.
- The final part of the routine subtracts `PlayerA $22 * {6000,3000,1800,1800,3000,4800}`
  from `ram_FF30EA/EE/F2/F6/FA/FE` and increments `Race_ram_HIntVScroll` by `$10000`;
  these are the horizontal parallax accumulators consumed by the HScroll builder.

E6 observations (`L6a_hint_trace.txt`; runtime, one frame at demo tick 120):

| HInt offset | Line | Backdrop | VSRAM A/B | Next |
|---|---|---|---|---|
| `$80` (first, VBlank tail) | `$9C` | `$3F` | `-8,-8` | `$90` |
| `$10` | `$03` | `$3F` | `$12,$06` | `$20` |
| `$20` | `$07` | `$3F` | `$12,$06` | `$50` |
| `$50` | `$25` | `$3F` | `$9A,$06` | `$60` |
| `$60` | `$33` | `$3F` | `$9A,$9C` | `$70` |
| `$70` | `$47` | `$3E` | `$28,$28` | `$80` |
| `$80` | `$9C` | `$3F` | `-8,-8` | `$90` |

The stored chain has `$30/$40` between `$20` and `$50`; the compaction pass removes
them, so the runtime chain is `$10 -> $20 -> $50 -> $60 -> $70 -> $80 -> $90`.
This confirms the raster order: top bands (`$10/$20`), upper horizon bands (`$50/$60`),
the horizon line (`$70`), and the bottom band (`$80`); the road rows between the
`$70` and `$80` interrupts are the HScroll rows written by `Road_FillProfileTables`.

## `Race_BuildHScrollTable` (`0xE494`, L6a contract)

`[static]` + E6 (`analysis/capture_L6a.gdb`):

The HScroll table is 4 bytes per scanline: word 0 = plane A (foreground), word 1 =
plane B (background). `Road_FillProfileTables` writes the road rows; the builder
overwrites the sky/parallax rows above alpha and clears the unused lower rows.

Let `L50=$52>>8`, `L60=$62>>8`, `L70=$72>>8`, `H = Race_ram_HIntVScroll`, and
`alpha = *Race_ram_CurrentAlpha`.

Plane A bands (from line `alpha-1` downward):

| Lines | Value |
|---|---|
| `alpha-1 .. L50` | `$30EA >> 16` |
| next `min(L50,$17)+1` | `(H>>1 + $30FA) >> 16` |
| remaining to line 0 | `(H + $30F2) >> 16` |

Plane B bands:

| Lines | Value |
|---|---|
| `alpha-1 .. L60+1` (count `L70-L60-1`) | `$30EE >> 16` |
| `(L60-L50-$D)` lines | `0` (gap) |
| `min(L50+$C,$17)+1` lines | `(H>>2 + $30FE) >> 16` |
| `L50+$D-$18` lines | `(3H/4 + $30F6) >> 16` |

After the bands:

- lines `$98..$D7` (64 lines) are cleared to 0;
- lines `$D8..$E7` (16 lines) get `-((PlayerA.X >> 9) & $C0)`;
- lines `$E8..$FF` are not touched (offscreen; stale data is harmless).

E6 sample (`L6a_trace.txt`, alpha `$47`, `H=$00780000`): line `alpha-1` =
`$00270013`, line `alpha` = `$01F3FF40`, line `$18` = `$0059006D`, line `$60` =
`$01D5FF69`, line `$80` = `$017CFFAB`, line `$98` = 0. These match the band
formulas: plane A top = `$30EA>>16 = $0027`, plane B top = `$30EE>>16 = $0013`;
line `$18` is in the second plane-B band (`3H/4+$30F6 -> $006D`); line `$80` is a
road row written by `Road_FillProfileTables` (`fg=$017C`, `bg=$FFAB`).

## `Race_ProjectActorSprite` (`0xDAE2`, L6b contract)

Builds a `Road_ObjectArray` record for an actor that is far behind the player
(`rel.high < -$10`) at the current `ram_FFDE72` index. With `v = progress - actor.X`:

- key `v` is appended to `ram_FF1B50`;
- `base = $B00 + ((v>>10) * -$1B) / $10`; `Y1 = actor.$30 -
  ((PosY-$10)/$28)*$28`, `Y2 = actor.$30 - ((PosY+$10)/$28)*$28`;
  `t1 = (base*Y1)/$E0 >> 6`, `t2 = (base*Y2)/$E0 >> 6`;
- record `+0 = t1 + $20`, `+$C = t1 - t2`, `+2 = $D8 - (v>>12)/$10`;
- scale `+4 = 3 * min($3FFF, $100000/((v>>12)+$80))`; limit `+6 = $E0`;
- flags `+$A = $4100 | (palette & 3)<<4` (H-flip from actor `$C` bit15);
- shape: actor `$71 == 1` -> `$159`; `$71 in $10..$12` -> `$15A`/`$15A+2`
  (bit3 of `StateFlags`); otherwise `Race_GetActorShapeVariant` + `$154`;
- the record is kept (`ram_FFDE72++`, `a0 += $14`) only when `+0 >= -$20` and
  `+0 - +$C < $160`; an accepted X then gets `-$200`.

## `Race_UpdateNearestOpponent` (`0xE5EE`)

- Returns immediately if PlayerA `$68` bit7 (finished).
- Resets `Race_ram_NearestAheadDistance=$7FFFFFFF`,
  `Race_ram_NearestBehindDistance=$80000000`.
- Walks the active list after PlayerA; for each actor:
  - `X = actor.X - PlayerA.X`;
  - `X >= 0`: smallest positive distance -> ahead index/speed;
  - `X < 0`: smallest negative distance -> behind index/speed;
  - increments the place counter for actors behind PlayerA, skipping the first
    opponent `$FF1F2A`.
- `Race_ram_PlayerPlace = count` if `< 10`, otherwise `(count-10)|$10`.
- Ahead speed = `distance / aheadActor.Speed`; behind speed =
  `-distance / PlayerA.Speed`; no target -> index `$FFFF`, speed 0.

## RAM / fields

- `Race_ram_VdpDmaControl` DMA control; `Race_ram_HIntVScroll` (`$FF14DC`) vertical
  scroll accumulator; `Race_ram_NearestBehindDistance`/`Race_ram_NearestAheadDistance`.
- `ram_FF30EA/EE/F2/F6/FA/FE` HInt HScroll parallax accumulators; `ram_FF3274` =
  horizon line (`ram_FF3236[31]`).
- `Race_ram_CameraOffset`; `ram_FF1E54/56` curve sums; `ram_FF1E58/5A` scaled current/
  next curve bytes; `ram_FF1E50/52` combined scroll values; `ram_FF1E60` camera Y;
  `ram_FF1E64` camera collision (long, `$1E66` = low word); `ram_FF1E68`
  `PlayerProgress` (long, `$1E6A` = low word); `ram_FF1E6C` current curve byte;
  `ram_FF1E76` = `$8000` progress bias; `$1E7A/$1E7E/$1E86` have no writer.
- `Race_ram_NearestBehindIndex`/`Race_ram_NearestAheadIndex` nearest actor indices;
  `Race_ram_NearestBehindSpeed`/`Race_ram_NearestAheadSpeed` engine-audio values;
  `Race_ram_PlayerPlace` player place.
- `Race_ram_RearviewTileRows` road tile rows; `ram_FF3238` marking widths;
  `ram_FF3A9C` marking X; `ram_FF1B50`/`ram_FFDE72` actor-sprite list/count.

## Open questions

- `U-0018` is closed: the four phases and the `$8Axx` formula above reproduce the E6
  runtime chain and line gaps exactly.
- Engine-audio mapping of `Race_ram_NearestBehindSpeed`/`Race_ram_NearestAheadSpeed`
  into the audio routine.
- Rearview mirror pixel/row mapping (visual confirmation).

## Rename proposals (apply only on request)

The function/data renames above are applied. Remaining field names are proposals:

| Current | Proposed | Evidence | Confidence |
|---|---|---|---|
| `ram_FF1E54`/`56`/`60`/`64`/`68`/`6C`/`76` | camera/progress fields | `[confirmed]` E6 | medium |
| `ram_FF30EA/EE/F2/F6/FA/FE` | HScroll layer accumulators | `[static]` + E6 | medium |
| `ram_FF3274` | horizon line (alias of `ram_FF3236[31]`) | `[confirmed]` E6 | high |

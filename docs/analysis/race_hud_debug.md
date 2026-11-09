# Analysis: `race_hud_debug.asm` (race HUD digit helpers + debug/alternate HUD)

- **Module:** number/digit drawing into the race HUD buffers, race-position display,
  and debug readouts of the player struct/race state
- **ROM range:** `0x0098C2`–`0x009B9D` (`uncompress.asm` starts at `0x9B9E`)
- **Status:** analyzed (no direct callers in the disassembled source; likely
  debug/alternate HUD or called indirectly)
- **Source:** `race_hud_debug.asm`
- **Related:** `docs/architecture.md`, `docs/ram-map.md`, `docs/hardware.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RaceHud_DrawStandings` | `0x98C2` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceDebug_ShowDistanceTravelled` | `0x9936` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceDebug_ShowPosZ` | `0x995A` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceDebug_ShowFrameDelay` | `0x997E` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed (bug) |
| `sub_999E` | `0x999E` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceDebug_ShowState` | `0x99C2` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `sub_9A98` | `0x9A98` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_DrawGear` | `0x9AB4` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_WriteDigit1`/`RaceHud_WriteDigit2`/`RaceHud_WriteDigit4` | `0x9AD4`/`0x9AF4`/`0x9B34` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |

## Role

The module writes digit tiles into the race HUD buffers (`Race_ram_CurrentHudBuffer`,
`Race_ram_NextHudBuffer`). It contains:

- three digit writers (`RaceHud_WriteDigit1` one digit, `RaceHud_WriteDigit2` two, `RaceHud_WriteDigit4` four hex digits);
- `RaceHud_DrawStandings`, which draws a race value plus a racer/standings list with the current
  row highlighted;
- several debug readouts (`RaceDebug_ShowDistanceTravelled`, POSZ, frame delay,
  `ram_FF304C`, `ram_FF3046`, the gear, and a multi-value debug panel).

None of the labels are called by the disassembled modules (`race_hud.asm` has its own
drawing); they are likely debug/alternate HUD code or called indirectly from the
un-disassembled gap.

## Digit writers

`d1` is a packed HUD position: high byte = row, low byte = column. The buffer word
offset is `((d1 & $FF00) >> 1) + ((d1 & $FF) << 1)` = `row*128 + column*2`
(64-word-wide buffer). The tile word is `base + digit`, with bit 15 set (priority) and
`d2` ORed in (palette/priority); the digit font tiles are at `$5C0`.

| Function | Digits | Notes |
|---|---|---|
| `RaceHud_WriteDigit1` | 1 | caller supplies the final tile (gear uses `$5C1+gear`). |
| `RaceHud_WriteDigit2` | 2 | hex nibbles of `d0` (`>>4`, `&$F`). |
| `RaceHud_WriteDigit4` | 4 | hex nibbles (`>>12`, `>>8`, `>>4`, `&$F`). |

## `RaceHud_DrawStandings` (standings/timer)

- Draws `ram_FF1AE4` (2 digits) at `$1602` into `Race_ram_NextHudBuffer`.
- Walks the pointer list at `ram_FF1AE0` (`(a1)+` = count): for each entry, follows the
  pointer twice, reads the value, and draws it at `$1606`, `$160C`, ... (rows 6 apart)
  with palette 0 for the current entry (`ram_FF1AE6`) and palette 2 for the others.
- The list/current-index/timer are the race standings HUD state.

## Debug readouts

| Function | Value | HUD position |
|---|---|---|
| `RaceDebug_ShowDistanceTravelled` | player `POSX_HIGH` (formatted by `sub_F11C`) | `$1A13` |
| `RaceDebug_ShowPosZ` | player `POSZ` (formatted) | `$1508` |
| `RaceDebug_ShowFrameDelay` | `Race_ram_FrameDelay` | none (bug, see below) |
| `sub_999E` | `ram_FF304C` (formatted) | `$1914` |
| `RaceDebug_ShowState` | `ram_FF1786`, `NumSprites`, `ram_FF1B3E`, struct `+$68`, `POSY`, `POSZ`, `POSX_HIGH`, `POSX_LOW & $FF00` | `$1420/$140D/$150D/$1418/$1A08/$1A10/$1A17/$1A1C` |
| `sub_9A98` | `ram_FF3046` | `$180D` |
| `RaceHud_DrawGear` | player `GEAR` + `$5C1` | `$1716` |

`sub_F11C` (`race.asm` `0xF11C`) converts the value for the distance readouts. These
are internal race variables shown at fixed HUD cells, characteristic of a debug
overlay.

## Quirks / notes

- `RaceDebug_ShowFrameDelay` calls `sub_F11C`, moves the returned `d1` to `d0`, but never sets a HUD
  position before `RaceHud_WriteDigit4`; `d1` still holds the formatted value, so the digit
  position is wrong. Likely unfinished debug code. `[static]`
- No direct callers in the disassembled source; the normal race HUD lives in
  `race_hud.asm`. `[static]`
- HUD buffers are double-buffered (`CurrentHudBuffer`/`NextHudBuffer`); `RaceHud_DrawStandings`
  writes to the next buffer while the debug readouts use the current one. `[static]`

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `RaceHud_DrawStandings` | `RaceHud_DrawStandings` | racer list/current row | medium |
| `RaceHud_WriteDigit1`/`RaceHud_WriteDigit2`/`RaceHud_WriteDigit4` | `RaceHud_WriteDigit1/2/4` | HUD digit writers | high |
| `sub_9936` | `RaceDebug_ShowPosX` | POSX_HIGH readout (already named) | medium |
| `RaceDebug_ShowPosZ` | `RaceDebug_ShowPosZ` | POSZ readout | high |
| `RaceDebug_ShowState` | `RaceDebug_ShowState` | multi-value debug panel | high |
| `RaceHud_DrawGear` | `RaceHud_DrawGear` | gear indicator | medium |

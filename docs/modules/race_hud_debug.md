# Module card: `src/race/race_hud_debug.asm`

- **ROM range:** `0x0098C2`–`0x009B9D` (`src/core/uncompress.asm` starts at `0x9B9E`)
- **Status:** analyzed (no direct callers; likely debug/alternate HUD or indirect)
- **Related:** `docs/architecture.md`, `docs/ram-map.md`, `docs/hardware.md`,
  `docs/analysis/race_hud_debug.md`

## Role / purpose

Writes digit tiles into the race HUD buffers (`Race_ram_CurrentHudBuffer`,
`Race_ram_NextHudBuffer`), draws a race value plus a racer/standings list with the
current row highlighted, and contains several debug readouts of the player struct and
race state. None of the labels are called by the disassembled modules; the normal HUD
is in `src/race/race_hud.asm`.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `RaceHud_DrawStandings` | `0x98C2` | — (no direct caller) | Standings/timer display. |
| `RaceDebug_ShowDistanceTravelled` | `0x9936` | — | POSX_HIGH readout. |
| `RaceDebug_ShowPosZ` | `0x995A` | — | POSZ readout. |
| `RaceDebug_ShowFrameDelay` | `0x997E` | — | Frame-delay readout (buggy position). |
| `sub_999E` | `0x999E` | — | `ram_FF304C` readout. |
| `RaceDebug_ShowState` | `0x99C2` | — | Multi-value debug panel. |
| `sub_9A98` | `0x9A98` | — | `Race_ram_SpeedDisplay` readout. |
| `RaceHud_DrawGear` | `0x9AB4` | — | Gear indicator. |
| `RaceHud_WriteDigit1`/`RaceHud_WriteDigit2`/`RaceHud_WriteDigit4` | `0x9AD4`/`0x9AF4`/`0x9B34` | debug functions | 1/2/4-digit HUD writers. |

## Control flow / state machine

- Digit writers: `d1` = packed row/column, offset `row*128 + column*2`; tile word
  `$5C0 + digit`, bit 15 set, OR `d2` (palette/priority).
- `RaceHud_DrawStandings`: `ram_FF1AE4` (2 digits) at `$1602`; walk `ram_FF1AE0` list, draw each
  value at `$1606/$160C/...`; current row (`ram_FF1AE6`) palette 0, others palette 2.
- Debug functions: format the value (`Race_FormatDecimal` for distance/POSZ/frame delay/
  `ram_FF304C`) or write raw hex (`RaceHud_WriteDigit4`) at fixed HUD cells; the gear uses the
  tile base `$5C1+gear`.

## RAM / ROM & structures

- HUD buffers: `Race_ram_CurrentHudBuffer`, `Race_ram_NextHudBuffer`; digit font tile
  base `$5C0` (VRAM `$B800`), bit 15 priority.
- Standings: `ram_FF1AE0` pointer list, `ram_FF1AE4` value/timer, `ram_FF1AE6` current
  index.
- Debug values: `RacePlayerA + STRUCT_OFFSET_*` (`POSZ/POSX_HIGH/POSX_LOW/POSY/GEAR/
  +$68`), `Race_ram_NumSprites`, `ram_FF1B3E`, `Race_ram_SpeedDisplay`/`ram_FF304C`, `ram_FF1786`,
  `Race_ram_FrameDelay`.
- `Race_FormatDecimal` (`src/race/race.asm` `0xF11C`) number formatter.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RaceHud_DrawStandings` | `0x98C2` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceDebug_ShowDistanceTravelled` | `0x9936` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceDebug_ShowPosZ` | `0x995A` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceDebug_ShowFrameDelay` | `0x997E` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `sub_999E` | `0x999E` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceDebug_ShowState` | `0x99C2` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `sub_9A98` | `0x9A98` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_DrawGear` | `0x9AB4` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `RaceHud_WriteDigit1`/`RaceHud_WriteDigit2`/`RaceHud_WriteDigit4` | `0x9AD4`/`0x9AF4`/`0x9B34` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |

Detailed listing: `docs/analysis/race_hud_debug.md`.

## Hacks / bugs / quirks

- `RaceDebug_ShowFrameDelay` does not set a HUD position after `Race_FormatDecimal`; the position is the
  formatted value. Likely unfinished debug code. `[static]`
- No direct callers; the normal HUD is `src/race/race_hud.asm`. `[static]`
- HUD buffers are double-buffered; `RaceHud_DrawStandings` uses the next buffer, the debug readouts
  the current one. `[static]`

## Verified facts

- `[static]` Digit writers use `row*128 + column*2`, tile `$5C0+digit`, bit 15, `d2`.
- `[static]` Debug readouts show the player struct fields at fixed HUD cells.

## Hypotheses

- `[hypothesis]` These functions are a debug overlay or an alternate HUD not used in
  the release; test: search for indirect references in the gap.


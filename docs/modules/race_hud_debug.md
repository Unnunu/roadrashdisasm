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
Full list: the related analysis page.

## Hacks / bugs / quirks
- `RaceDebug_ShowFrameDelay` does not set a HUD position after `Race_FormatDecimal`; the position is the
  formatted value. Likely unfinished debug code. `[static]`
- No direct callers; the normal HUD is `src/race/race_hud.asm`. `[static]`
- HUD buffers are double-buffered; `RaceHud_DrawStandings` uses the next buffer, the debug readouts
  the current one. `[static]`

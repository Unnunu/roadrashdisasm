# Module card: `race_hud.asm`

- **ROM range:** `0x00D278`–`0x00D8F9` (`race_physics.asm` starts at `0xD8FA`)
- **Status:** TODO (region identified; HUD internals not analyzed)
- **Related:** `docs/analysis/race.md`, `docs/ram-map.md`, `docs/modules/race.md`

## Role / purpose

Race HUD drawing, called from `Race_Update` via `RaceHud_Draw`; writes the HUD buffers
(`Race_ram_CurrentHudBuffer`/`NextHudBuffer`).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RaceHud_Draw` | `0xD278` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

Detailed analysis: TODO.

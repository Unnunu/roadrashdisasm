# Module card: `src/data/race_misc_data.asm`

- **ROM range:** `0x07DCA8`–`0x07E6A1` (`src/core/top_level.asm` starts at `0x7E6A2`)
- **Status:** tables/scripts located; internal semantics partial TODO
- **Related:** `docs/analysis/race_misc_data.md`, `docs/analysis/race_hud.md`,
  `docs/analysis/shop.md`, `docs/analysis/race_results.md`,
  `docs/analysis/race_ai.md`, `docs/ram-map.md`

## Role / purpose

Final data block before the top-level flow: the 16-bit lookup used by race AI, the HUD
speed/RPM needle animation script, bike/actor palettes, and the results-screen track
image/nametable/palette pointer tables.

## Coverage matrix

| Data | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|------|---------|----------|-----------|------|----------|-----|---------|--------|
| `unk_7DCA8` | `0x7DCA8` | [x] | [~] | [x] | - | [~] | [ ] | partial |
| `RaceHud_NeedleScript` (needle script) | `0x7DEAA` | [x] | [~] | [x] | [x] | [x] | [ ] | partial |
| `Shop_BikePalettes` | `0x7E370` | [x] | - | [x] | [x] | [x] | [ ] | analyzed |
| `unk_7E470` (actor palettes) | `0x7E470` | [x] | - | [x] | [x] | [x] | [ ] | analyzed |
| `RaceResults_TrackImagePtrs/684/68E/698` | `0x7E670`+ | [x] | - | [x] | [x] | [x] | [ ] | analyzed |

Detailed analysis: `docs/analysis/race_misc_data.md`.

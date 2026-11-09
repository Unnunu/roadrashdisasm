# Module card: `rom_assets.asm`

- **ROM range:** `0x07EA66`–`0x0BFFFF`
- **Status:** labelled tail split at 53 known boundaries; bytes raw; internals TODO
- **Related:** `docs/analysis/rom_tail.md`, `docs/analysis/main.md`,
  `docs/analysis/rider_intro.md`, `docs/analysis/highscore.md`,
  `docs/analysis/shop.md`, `docs/analysis/endlevel.md`, `docs/architecture.md`

## Role / purpose

Replaces the single `RomTail` bridge with labelled `binclude` chunks for the known
asset/code boundaries: high-score/menu/intro/shop/end-level images, fonts, the results
track images, the 11 rider portraits, the Natasha overlay, and the ROM checksum routine.

## Coverage matrix

| Data | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RomTail`/`unk_7EA66` + 52 labels | `0x7EA66`+ | [x] | - | [~] | - | [~] | [ ] | labelled |
| `Boot_CheckRomChecksum` | `0x7FF98` | [x] | [x] | [x] | - | [x] | [ ] | raw code, labelled |
| Images/fonts (high score/menu/intro/shop/end level) | various | [x] | - | [~] | - | [~] | [ ] | raw |
| `RaceResults_TrackImage_0..4` | `0x8E4E6`+ | [x] | - | [~] | - | [~] | [ ] | labelled |
| `RiderIntro_Portrait_0..10` | `0xAF902`+ | [x] | - | [~] | - | [~] | [ ] | labelled |

Detailed analysis: `docs/analysis/rom_tail.md`.

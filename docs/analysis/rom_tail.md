# Analysis: ROM tail (`0x7EA66`–`0xBFFFF`, `RomTail`)

- **Status:** full ROM assembles byte-exactly; tail split at 53 labels; boot checksum disassembled
- **Source:** `rom_assets.asm` (asset chunks from `baserom.md`; `Boot_CheckRomChecksum` source)
- **Code:** `Boot_CheckRomChecksum` at `0x7FF98` is disassembled in `rom_assets.asm`
- **Related:** `docs/analysis/rider_intro.md`, `docs/analysis/highscore.md`,
  `docs/analysis/shop.md`, `docs/analysis/endlevel.md`,
  `docs/analysis/race_results.md`, `docs/architecture.md`

## Build

`./build.sh` prints `Matched OK: 786432 bytes of 786432 bytes` (full ROM). The tail
after `top_level.asm` (`0x7EA66`–`0xBFFFF`) is split into labelled `binclude` chunks by
`rom_assets.asm`; the audio range `0x19F62`–`0x257CF` remains the other raw bridge.

## Known assets (from `unknown.asm` / callers)

| Address | Symbol | Used by |
|---|---|---|
| `$7EA66` | `RomTail`/`unk_7EA66` | results / intro / end-level image data |
| `$7EB72` | `ImgHighScoreBadge` | high score |
| `$7ED66` | `unk_7ED66` | unknown |
| `$80000` | `EndLevel_AnimationTiles` | end-level |
| `$8BF12` | `EndLevel_AnimationData` | end-level |
| `$8E4E6`..`$98C1E` | results track images | `unk_7E670[5]` |
| `$9B2F0`/`$9B494`/`$9B7A6`/`$9B89E` | race images | `race_core` |
| `$9C82A`/`$9DA6A`/`$9DB68`/`$9DC4C`/`$9DDCC`/`$9E3A2` | race images | `race_core` |
| `$9E784`/`$9E874` | `ImgShopArrowLeft/Right` | shop |
| `$9EA1E`/`$9FDDE`/`$A122A` | `ImgShopBike1/2/3` | shop |
| `$A270C` | `img_mainMenu_PlayerSelection` | main menu |
| `$A27D4` | `img_Intro_Font` | intro |
| `$A2BAA` | `FontHighScoreTable` | high score |
| `$A2E68` | `unk_A2E68` | high score |
| `$A2F5C` | `ImgHighScoreTitle` | high score |
| `$A37AA` | `img_MainMenu_RaceBadges` | main menu |
| `$A4498` | `img_mainMenu_RaceCards` | main menu |
| `$A7722` | `img_PasswordMenu_PlayerSelection` | password menu |
| `$A7834` | `img_Intro_Background` | intro |
| `$ACA00` | `img_Intro_Title` | intro |
| `$AE8CE` | `img_MainMenu_Background` | main menu |
| `$AF26C` | `unk_AF26C` | results |
| `$AF902`..`$BE628` | 11 intro portraits | `RiderIntro_RecordTable` |
| `$B1506` | `unk_B1506` | Natasha bike overlay |

## Known code / asset boundaries

The 53 labels include `Boot_CheckRomChecksum` (`$7FF98`), `EndLevel_WindowImage`
(`$7F400`), `img_Gamepad` (`$7F834`), `EndLevel_AnimationTiles/Data`,
`RaceResults_TrackImage_0..4`, the 11 `RiderIntro_Portrait_*`, `unk_B1506`, and the
high-score/menu/intro/shop/end-level image/font labels. See `rom_assets.asm`.

## TODO

- Check for other code hidden between the labelled tail assets.
- Parse the image headers/sizes and the sound samples.
- Map the compressed image headers/sizes for each asset and the sound samples.
- Determine whether any code or tables hide between the assets.
- Dynamic verification (intro portraits, high-score/menu/shop/end-level images).

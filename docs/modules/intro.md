# Module card: `src/screens/intro.asm`

- **ROM range:** `0x001704`–`0x002445`
- **Status:** analyzed (static; visual confirmation of the title wipe TODO)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/intro.md`

## Role / purpose
Intro/title screen: background, title and font assets, 13 credit strings with timing,
a per-line H-scroll title/credits effect, Start-button detection, and the initial
player/menu/high-score state used by the rest of the game.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Intro_Init` | `0x1704` | top-level flow | Sets VDP, decompresses assets, builds planes, initializes player state. |
| `Intro_GameTick` | `0x1C64` | `ram_UpdateFunction` during the intro | H-scroll update, credit-string timing, Start detection. |
| `EncodeString` | `0x2288` | menus/intro | Encode text into font tile indices. |
| `DecodeString` | `0x22B2` | menus | Reverse of `EncodeString`. |
| `WriteNametable` | `0x2402` | menus/intro | Write a rectangular nametable region to VRAM. |
| `Intro_InitPlayerA` / `Intro_InitPlayerB` | `0x1A2C` / `0x1B48` | `Intro_Init` | Initialize player A/B menu/high-score state. |

## External calls / dependencies
- `UncompressW`, `WriteTilesetToVRAM`, `DmaWriteVRAM` (asset upload).
- `GetInputPlayerA/B`, `DmaWriteVRAM`, `Audio_Update/3/4`, `Rand_InitSum`, `Rand_SeedLfsrs`.
- `Menu_*`, `MenuPassword_*`, `HighScore_*` state (initial values).

## Hacks / bugs / quirks
- `reg0` comment in the source says "Display gen enabled"; display is actually `reg1`
  bit6 (`$8174`).
- The title nametable is written twice; the second write fills the off-screen right part
  of the 128-cell plane for the H-scroll.
- The H-scroll tables are larger than the 224-line VDP H-scroll table; the DMA transfers
  `$1C0` words (224 lines). `Intro_Init` writes lines 189..150 with a predecrement (the
  source comment "Y = 190" is the start of the downward block), then clears 190..223.
- GDB confirmed `Intro_GameTick` runs as `ram_UpdateFunction` (`0x1C64`), the timer starts
  at 180, and H-scroll line 150 decreases by 12.0 per frame.

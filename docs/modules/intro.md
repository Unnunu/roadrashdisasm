# Module card: `intro.asm`

- **ROM range:** `0x001704`–`0x002445`
- **Status:** partially analyzed (VDP/text/scroll structure and runtime confirmed; exact title visuals TODO)
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
| `sub_1A2C` / `sub_1B48` | `0x1A2C` / `0x1B48` | `Intro_Init` | Initialize player A/B menu/high-score state. |

## Control flow / state machine

- **Init:** set VDP (`reg2=$10` plane A `$4000`, `reg4=$01` plane B `$2000`,
  `reg5=$30` sprites `$6000`, `reg0D=$1C` H-scroll `$7000`, `reg0B=$03` H-scroll per
  line, `reg90=$03` 128x32), clear sprites/VSRAM, decompress background/title/font,
  build nametables with `WriteNametable`, initialize the H-scroll table/speed arrays,
  DMA the H-scroll table, set up audio/random/menu state.
- **GameTick:** DMA the H-scroll table to `$7000`; read pads A/B and edge-detect Start
  (press then release); decrement the text timer (180 frames = 3 s); advance through
  `Intro_dStringTable`; when the last `$FFFFFFFF` entry is reached or Start is pressed,
  clear `ram_UpdateFunction` and return. Otherwise update the title/credits scroll
  (acceleration/deceleration, recoil/out-of-screen logic).

The title nametable is written twice: 40x28 at (0,0) and 88x6 at (40,18), because the
plane is 128 cells wide and the per-line H-scroll reveals the off-screen right part.

## VDP configuration

```
reg0  $04   H-int off
reg1  $74   display on, V-int on, DMA on, 28 rows
reg2  $10   plane A $4000
reg4  $01   plane B $2000
reg5  $30   sprite table $6000
reg7  $01   backdrop 1
reg0A $FF   H-int counter (disabled)
reg0B $03   V-scroll full, H-scroll per line
reg0C $81   H40
reg0D $1C   H-scroll table $7000
reg0F $02   auto-increment 2
reg90 $03   128x32 planes
```

## RAM / ROM & structures

- `Intro_ram_PlayerAPressedStart/B`, `Intro_ram_TextTimer`, `Intro_ram_CurrentStringOffset`,
  `Intro_ram_ImageBuffer` (`$FF509C`).
- `Intro_TitleScrollTable` `$FF439C` and `Intro_TitleScrollSpeed` `$FF4A1C` (per-line
  H-scroll values/speeds, size `$400 + $280`).
- `Intro_dStringTable` (`0x1E0C`): 13 `dc.l` pointers + `$FFFFFFFF`; each string has
  `y,x,height,width` then characters.
- `dStringCodeTable`/`dStringDecodeTable`: font character mapping.
- Player/menu/high-score state initialized by `sub_1A2C`/`sub_1B48` (names, passwords,
  level 1, money 100, bike 0, places 0, opponents `$4B,0..$E`, high-score tables).

## External calls / dependencies

- `UncompressW`, `WriteToVRAM`, `DmaWriteVRAM` (asset upload).
- `GetInputPlayerA/B`, `DmaWriteVRAM`, `AudioFunc1/3/4`, `Rand_Init`, `sub_16088`.
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

## Coverage matrix

See `docs/analysis/intro.md` for the full matrix.

## Verified facts

- `[static]` The intro uses plane A `$4000` (title/text), plane B `$2000` (background),
  sprite table `$6000`, H-scroll table `$7000`, 128x32 planes, per-line H-scroll.
- `[static]` 13 credit strings, each shown for 180 frames; Start is edge-detected
  (press then release) to end the stage.
- `[static]` `EncodeString`/`DecodeString` use the font code tables; `WriteNametable`
  builds the VDP command from x/y/plane width/tile base.
- `[static]` `sub_1A2C`/`sub_1B48` initialize the player/menu/high-score state.
- `[dynamic]` `Intro_GameTick` (`0x1C64`) is the update function; the text timer starts
  at 180; H-scroll line 150 decreases by 12.0 per frame.

## Hypotheses / open questions

- `[hypothesis]` The per-line scroll arrays implement a wavy/accelerating title reveal.
- `[ ]` Confirm the visible scroll line ranges and exact wave in BlastEm.
- `[ ]` Confirm `Intro_GameTick` is installed as `ram_UpdateFunction` and the Start edge.
- `[ ]` Audio/`sub_16088` deferred.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `sub_1A2C` | `Intro_InitPlayerA` | player A state init | high |
| `sub_1B48` | `Intro_InitPlayerB` | player B state init | high |
| `Intro_dStringTable` | `Intro_dCreditStringTable` | credits | high |
| `Intro_TitleScrollTable` | `Intro_ram_HScrollTable` | per-line H-scroll | medium |

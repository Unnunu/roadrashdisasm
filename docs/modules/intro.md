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

## Control flow / state machine

- **Init:** set VDP (`reg2=$10` plane A `$4000`, `reg4=$01` plane B `$2000`,
  `reg5=$30` sprites `$6000`, `reg0D=$1C` H-scroll `$7000`, `reg0B=$03` H-scroll per
  line, `reg90=$03` 128x32), clear sprites/VSRAM, decompress background/title/font,
  build nametables with `WriteNametable`, initialize the H-scroll table/speed arrays,
  DMA the H-scroll table, set up audio/random/menu state.
- **GameTick:** DMA the H-scroll table to `$7000`; read pads A/B and edge-detect Start
  (press then release); decrement the text timer (180-tick setting, 181 frames per page
  because of the `bpl`) and advance through `Intro_dCreditStringTable` when it expires.
  At the table terminator (`$FFFFFFFF`) or on Start release, clear `ram_UpdateFunction`.
  Otherwise animate lines 150-189: 12 px/frame, reduced to 2 px steps within 16 px, then
  clamp or overshoot (damped recoil), plus a bottom-up edge wave. At offset `$2C` (12th
  page) start the diagonal wipe-off to the right; the last two pages keep showing.

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
- `Intro_dCreditStringTable` (`0x1E0C`): 13 `dc.l` pointers + `$FFFFFFFF`; each string has
  `y,x,height,width` then characters.
- `dStringCodeTable`/`dStringDecodeTable`: font character mapping.
- Player/menu/high-score state initialized by `Intro_InitPlayerA`/`Intro_InitPlayerB` (names, passwords,
  level 1, money 100, bike 0, places 0, opponents `$4B,0..$E`, high-score tables).

## External calls / dependencies

- `UncompressW`, `WriteTilesetToVRAM`, `DmaWriteVRAM` (asset upload).
- `GetInputPlayerA/B`, `DmaWriteVRAM`, `Audio_Update/3/4`, `Rand_Init`, `sub_16088`.
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
- `[static]` 13 credit strings, each page lasts 181 frames (180-tick timer + `bpl`);
  Start is edge-detected (press then release) to end the stage.
- `[static]` The title animation uses 32-bit 16.16 scroll/speed arrays for lines 150-189:
  12 px/frame, a 2 px/frame reduction within 16 px, then clamp or damped overshoot; a
  bottom-up wave enforces a 1 px/scanline edge. At offset `$2C` the band wipes right
  (sentinel -640); that loop also touches line 149 (off-by-one, blank row).
- `[static]` `EncodeString`/`DecodeString` use the 128-word/50-byte font tables;
  `WriteNametable` takes width/height/x/y in cells, a base tile **word** in d4
  (palette/priority included), the plane base address in d5 and the plane width in
  cells in d6, then builds the VDP VRAM-write command.
- `[static]` `Intro_InitPlayerA`/`Intro_InitPlayerB` initialize the player/menu/high-score state.
- `[dynamic]` `Intro_GameTick` (`0x1C64`) is the update function; the text timer starts
  at 180; H-scroll line 150 decreases by 12.0 per frame.

## Hypotheses / open questions

- `[ ]` Confirm the diagonal wipe and the exact wave visually in BlastEm.
- `[ ]` Confirm `Intro_GameTick` is installed as `ram_UpdateFunction` and the Start edge.
- `[ ]` Audio/`sub_16088` deferred.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `Intro_TitleScrollTable` | `Intro_ram_HScrollTable` | per-line H-scroll | medium |


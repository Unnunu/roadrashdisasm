# Analysis: `intro.asm` (intro / title / credits)

- **Module / routine:** intro screen, credit strings, title/bottom scroll effect, initial game state
- **ROM range:** `0x001704`–`0x002445` (`menu_password.asm` starts at `0x2446`)
- **Status:** partially analyzed (VDP/text/scroll structure understood; exact title visuals TODO)
- **Source:** `intro.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Intro_Init` | `0x1704` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `sub_1A2C` (player A init) | `0x1A2C` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `sub_1B48` (player B init) | `0x1B48` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `Intro_GameTick` | `0x1C64` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `EncodeString` | `0x2288` | [x] | [x] | [x] | - | [x] | - | analyzed |
| `DecodeString` | `0x22B2` | [x] | [x] | [x] | - | [x] | - | analyzed |
| `WriteNametable` | `0x2402` | [x] | [x] | [x] | [x] | [x] | - | analyzed |

## VDP configuration (`Intro_Init`, `0x1704`)

```
reg0  = $8004 : H-int off, left column unblanked, HV counter normal (bit2 fixed 1)
reg1  = $8174 : display on, V-int on, DMA on, 28 rows
reg2  = $8210 : plane A nametable $4000
reg4  = $8401 : plane B nametable $2000
reg5  = $8530 : sprite table $6000
reg7  = $8701 : backdrop colour 1
reg0A = $8AFF : H-int counter 255 (H-int disabled)
reg0B = $8B03 : E-int off, V-scroll full, H-scroll per line
reg0C = $8C81 : H40, no interlace, no shadow/highlight
reg0D = $8D1C : H-scroll table $7000
reg0F = $8F02 : auto-increment 2
reg90 = $9003 : 128x32 planes
reg91/92 = 0 : window disabled (window base from the previous screen is irrelevant)
```

The display is enabled here (`$8174`), unlike the logo which relies on `doStart`.
The source comment on `$8004` ("Display gen enabled") is again misleading; display is
`reg1` bit6.

## Assets and layout

- `img_Intro_Background` -> decompressed into `Intro_ram_ImageBuffer`, uploaded to
  VRAM `$8000`, nametable written to **Scroll B** (`$2000`) with tile base `$400` and
  plane width 128.
- `img_Intro_Title` -> VRAM `$E000`, nametable to **Scroll A** (`$4000`) with tile base
  `$700`, plane width 128.
- `img_Intro_Font` -> VRAM `$0000`; the text tiles use base `$6000` (palette line 3).
- A **title nametable is written twice**: first 40x28 at (0,0), then 88x6 at (40,18).
  The second write fills the **off-screen right part** of the 128-tile plane, which the
  per-line H-scroll reveals when the title scrolls. The source comment
  "draw title once again, but why?" is explained by the 128-wide plane + H-scroll.

## Text strings / timing

`Intro_dStringTable` (at `0x1E0C`) is an array of `dc.l` pointers, terminated by
`$FFFFFFFF`. Each string starts with four words `y, x, height, width`, followed by
`height*width` characters. The table contains:

1. "Copyright 1991 Electronic Arts"
2. "Licensed by Sega Enterprises LTD."
3. "Programming: Dan Geisler, Walter Stein"
4. "Art: Arthur Koch, Jeff Fennel"
5. "Art: Sheryl Knowles, Cynthia Hamilton"
6. "Art: Connie Braat, Paul Vernon"
7. "Art: Peggy Brennan"
8. "Sound and Music: Rob Hubbard, Mike Bartlow"
9. "Production: Randy Breen"
10. "Technical Direction: Carl Mey"
11. "Production Assistant: Michael Lubuguin"
12. blank
13. "Press the Start Button to Begin"

`Intro_GameTick` (`0x1C64`) decrements `Intro_ram_TextTimer` (180 frames = 3 s); on
expiry it advances `Intro_ram_CurrentStringOffset` by 4 and encodes/writes the next
string. The last `$FFFFFFFF` entry ends the stage. Start on pad A or B is detected with
the "pressed then released" edge (`Intro_ram_PlayerAPressedStart`/`B` set to `$80`, then
the next frame without Start ends the stage). `.endStage` clears `ram_UpdateFunction`
(the top-level flow then proceeds), calls `AudioFunc4` and returns.

## Title/credits scroll effect

- `Intro_TitleScrollTable` (`$FF439C`) and `Intro_TitleScrollSpeed` (`$FF4A1C`) are
  per-line arrays (4 bytes per line; `ram_const.asm` says `size $400 + $280`).
- `Intro_Init` clears lines 0-149, then starts at offset `+$2F8` (line 190) and uses a
  **predecrement** (`move.l d1,-(a2)`), so the generated ramp is actually written to
  lines **189..150**: the foreground scroll starts at 400 (`$1900000`, "completely out
  of screen") and the delta grows by `$2000` (1/8 px steps); the background scroll word
  is zeroed (`move.l d1,d3; clr.w d3`). `clearHScroll2` then clears lines 190..223 with
  a postincrement.
- `[dynamic]` GDB: line 150 starts at `$01EC0000` and decreases by `12.0` (`$C0000`)
  each frame; the timer starts at `$B4` (180) and decrements; `ram_UpdateFunction` is
  `0x1C64` (Intro_GameTick).
- `Intro_GameTick` updates lines 150-189 each frame from the speed array: the scroll
  value decreases toward it (or the speed is capped), with acceleration/deceleration and
  a minimum; after all developers are shown, the title is moved out (`$FD800000` =
  -640) and the recoil/out-of-screen logic runs.
- The whole table is DMA'd to VRAM `$7000` (`$1C0` words = 896 bytes = 224 H-scroll
  entries) every frame via `DmaWriteVRAM`. With `reg0B=$03` the VDP applies the scroll
  per line, creating the title/credits wave.
- Exact visual result and the line ranges are still TODO; the algorithm is a
  per-line scroll table with per-line speed and clamping.

## String encoding and nametable writing

- `EncodeString` (`a0` string, `a1` destination):
  - reads the header words at +4/+6 (height, width), computes `height*width` chars;
  - maps each byte through `dStringCodeTable` (a 256-entry word table, characters to
    font tile indices); bytes >= `$80` become space (`$20`);
  - writes one word (tile index) per character.
- `DecodeString` is the reverse using `dStringDecodeTable` (a 50-byte char table).
- `WriteNametable` computes the VDP VRAM write command from the destination base,
  x/y, plane width and tile base, then writes `height` rows of `width` words. The bit
  manipulation converts the linear VRAM address into the VDP command word format
  (`$40000000 | (address bits)`); the row stride is `planeWidth * 2` bytes.

## Initial game state (`sub_1A2C` / `sub_1B48`)

`Intro_Init` calls `sub_1A2C` (player A) and `sub_1B48` (player B), which initialize the
persistent player/menu/high-score state:

- choose `HighScore_ram_PlayerATableOffset`/`B` (20*5 or 20*6 depending on the other
  player);
- copy the default player name from `MenuPassword_ram_StrPlayerAName/BName` into the
  high-score table (`ram_FF05F2 + offset`), add spaces and `'$0'`;
- copy `Menu_DefaultPassword` into the password string;
- level 1, money 100, bike 0, five race places = 0, opponents list `$4B,0..$E`;
- the high-score table is initialized from `unk_4C18` (demo data, 34 longs);
- `Menu_ram_CurrentTrackId = 0`, `Menu_ram_PlayerMode = 1`, `Menu_ram_PlayerLevel = 1`,
  `Menu_ram_Player = 0`, music enabled, `Rand_Init`, `sub_16088`, `AudioFunc3`.

## Verified facts

- `[static]` The intro uses planes A `$4000` and B `$2000`, sprite table `$6000`,
  H-scroll table `$7000`, 128x32 planes and per-line H-scroll.
- `[static]` The title nametable is 128 cells wide; the second `WriteNametable` fills the
  off-screen right part used by the H-scroll.
- `[static]` The credit strings are 13 entries with 8-byte headers; each is shown for
  180 frames; Start is edge-detected (press then release) to end the stage.
- `[static]` `EncodeString`/`DecodeString` use the font code tables;
  `WriteNametable` builds the VDP command from x/y/plane-width/tile-base.
- `[static]` `sub_1A2C`/`sub_1B48` initialize player/menu/high-score state, including
  names, passwords, level, money, bike, places and opponents.
- `[dynamic]` `Intro_GameTick` is installed as `ram_UpdateFunction` (`0x1C64`); the text
  timer starts at 180 and the H-scroll line 150 value decreases by 12.0 per frame.

## Hypotheses / open questions

- `[hypothesis]` The H-scroll arrays implement a wavy/accelerating title reveal at the
  bottom of the screen; confirm visually and with the H-scroll values.
- `[hypothesis]` The second title nametable write is required because the plane is
  128 cells wide and the title scrolls horizontally; without it the right side is blank.
- `[x]` Visible title region: lines 150-189 (Init predecrement), lines 190-223 cleared.
  The exact wave is still best confirmed visually.
- `[ ]` Confirm the `$6000` text tile base / palette line 3 and the font layout.
- `[ ]` `sub_16088` and the audio calls are deferred (audio deep dive).
- `[ ]` Dynamic: confirm `Intro_GameTick` is called as `ram_UpdateFunction` (0x1C64) and
  the Start edge behaviour in BlastEm.

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `sub_1A2C` | `Intro_InitPlayerA` | initializes player A state | high |
| `sub_1B48` | `Intro_InitPlayerB` | initializes player B state | high |
| `Intro_dStringTable` | `Intro_dCreditStringTable` | credits/strings | high |
| `Intro_TitleScrollTable` | `Intro_ram_HScrollTable` | H-scroll per line | medium |

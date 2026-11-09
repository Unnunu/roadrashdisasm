# Module card: `src/screens/rider_sprites.asm`

- **ROM range:** `0x005760`–`0x0059C3` (routines) + `0x005944`–`0x0059C3` (table
  `RiderSprites_StripTable`); `src/screens/rider_intro.asm` starts at `0x59C4`
- **Status:** analyzed (static + dynamic)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/rider_sprites.md`

## Role / purpose

Builds a linked **rider/bike sprite chain** in the race sprite attribute table (SAT).
It is called by `src/race/road_render.asm` (`bsr.w RiderSprites_Build`) each time the animation needs a new chunk
of sprites, writes `Y, size/link, tile/priority, X` entries, advances the animation tile
cursor / sprite index, and additionally emits a shadow/overlay layer.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `RiderSprites_Build` | `0x5760` | `src/race/road_render.asm:82` | Build sprite chain chunk. |
| `RiderSprites_BuildAlt` | `0x593E` | — (no direct caller in source) | Wrapper `bsr.w RiderSprites_Build; rts`. |

## Control flow / state machine

1. Link the new chunk to the previous SAT entry when `SpriteIndex` is `1..$4F`; on
   `>= $50` set the end flags and return.
2. Derive strip counts (`ram_FF090A/C`) and base offsets (`ram_FF0906/08`) from `d0/d1`.
3. Loop rows x columns: build each sprite from the base coordinates
   (`ram_FFDE6E/70 + $80`), adjust with the `RiderSprites_StripTable` record (Y step, size/link bits,
   tile step, shadow X), add `Animation_ram_BaseTile`/`ram_FFDE5E` and priority bits,
   write the entry, advance the tile cursor.
4. If the tile cursor reaches `$150`, flag the chain end and clear the previous link.
5. Clear the last link, store `Animation_ram_SpriteIndex`/`TileIndex`.

## RAM / ROM & structures

- `Race_ram_CurrentSpriteAttributeTable` (`$FF38AC`) — SAT base.
- `Animation_ram_SpriteIndex` (`$FFDE64`), `Animation_ram_TileIndex` (`$FFDE60`),
  `Animation_ram_BaseTile` (`$FFD34A`) — chain/animation cursors.
- Base fields `ram_FFDE5E..70`; scratch `ram_FF0906..0E`; shadow/overlay
  `ram_FF1336/133A`; end flags `ram_FF1366`, `ram_FFDE62`.
- SAT entry: `Y, size/link, tile/priority, X` (4 words; link = low byte of word 2).
- ROM table `RiderSprites_StripTable` (`0x5944`, 128 bytes = 16 records x 8 bytes): `+0` Y step,
  `+2` size/link bits, `+4` tile step, `+6` shadow X adjustment.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `RiderSprites_Build` | `0x5760` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `RiderSprites_BuildAlt` | `0x593E` | [x] | [x] | - | - | [x] | - | analyzed |
| `RiderSprites_StripTable` | `0x5944` | [x] | [x] | [x] | [x] | [x] | - | analyzed |

Detailed listing and field hypotheses: `docs/analysis/rider_sprites.md`.

## External calls / dependencies

- Caller: `src/race/road_render.asm` (race object/animation update; analyzed later).
- Reads/writes the shared animation state used by `src/race/animation.asm`, `src/race/road_marking.asm`,
  `src/race/race_hud.asm`.

## Hacks / bugs / quirks

- The `$8000` sentinel in `ram_FFDE68` marks "first chunk"; it is replaced by the
  computed tile offset after the first entry.
- Entries with `Y >= $118` do not get the high-priority bit `$8000`.
- The shadow layer uses the high priority bit `$800` and subtracts the table X offset.

## Verified facts

- `[static]` Writes linked SAT entries and maintains the animation cursors.
- `[static]` `RiderSprites_StripTable` supplies per-strip Y/link/tile/X adjustments.
- `[dynamic]` Demo race hits `RiderSprites_Build`; SAT chain observed at `$FF479C` with sprite
  index 6, tile index `$27`, shadow offset `$10` (`ram_FF133A=1`).

## Hypotheses

- `[hypothesis]` Entries are rider + bike sprites with a shadow/reflection layer. Test:
  map the SAT entries to the graphics in BlastEm.
- `[hypothesis]` `d0/d1` inputs are the animation direction/size from `src/race/road_render.asm`. Test:
  analyze `src/race/road_render.asm` and break at `$5760` entry.

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Confirm SAT builder | GDB `break *0x593C` in demo race | SAT `$FF479C`, 4 entries, sprite index 6, tile `$27`, shadow flag 1 | Confirms sprite-chain builder |

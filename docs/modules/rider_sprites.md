# Module card: `src/screens/rider_sprites.asm`

- **ROM range:** `0x005760`–`0x0059C3` (routines + table
  `RiderSprites_StripTable` at `0x005944`); `src/screens/rider_intro.asm` starts at
  `0x59C4`
- **Status:** analyzed (static + dynamic)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/rider_sprites.md`

## Role / purpose
Builds a linked **rider/bike sprite chain** in the race sprite attribute table (SAT).
It is called by `Road_DrawStrip` (`src/race/road_render.asm:97`, `bsr.w
RiderSprites_Build`) each time the animation needs a new chunk of sprites. The routine
decomposes the requested tile extent into a grid of 4x4 (and smaller remainder) VDP
sprites, writes `Y, size/link, tile/priority, X` entries, chains them through the
size/link link byte, advances the animation tile cursor / sprite index, and can emit a
horizontally mirrored copy.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `RiderSprites_Build` | `0x5760` | `src/race/road_render.asm:97` | Build sprite chain chunk. |
| `RiderSprites_BuildAlt` | `0x593E` | — (no direct caller in source) | Wrapper `bsr.w RiderSprites_Build; rts`. |

## External calls / dependencies
- Caller: `src/race/road_render.asm` (`Road_DrawStrip`, `Road_DrawObject`).
- Reads/writes the shared animation state used by `src/race/animation.asm`,
  `src/race/road_marking.asm`, `src/race/race_hud.asm`.

## Hacks / bugs / quirks
- The `$8000` sentinel in `ram_FFDE68` marks "band advance not computed"; it is
  replaced after the first row. It is not a per-row stride (see L6c).
- Entries with `Y >= $118` do not get the priority bit `$8000`.
- The mirror pass (`Road_ram_MirrorFlag`, from `RoadObject_Flags` bit15) sets the H-flip bit
  `$800` and walks X left. `U-0007` resolved: this is the facing/mirror bit, not a shadow.

# Module card: `road_render.asm`

- **ROM range:** `0x008FB4`–`0x0098C1` (`race_hud_debug.asm` starts at `0x98C2`)
- **Status:** partially analyzed (object list/records, call graph and dynamic samples
  confirmed; shape/projection math TODO)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/road_render.md`

## Role / purpose

Race road/object renderer. `race.asm` calls `sub_942A` after the HUD updates; it walks
the visible-object list and renders each object's road strip/tile and rider/vehicle
sprite chain, using `sub_5760` for the sprite chain.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `sub_942A` | `0x942A` | `race.asm:1809` | Walk the visible-object list. |
| `sub_9484` | `0x9484` | `sub_942A` | Render one 0x14-byte object record. |
| `sub_8FB4` | `0x8FB4` | `sub_9484` | Road strip/tile + sprite chain. |
| `sub_9142`/`sub_91F0` | `0x9142`/`0x91F0` | `sub_8FB4` | Left/right edge interpolation. |
| `sub_9306`/`sub_93D2` | `0x9306`/`0x93D2` | `sub_8FB4` | Road tile columns / clear edge tiles. |
| `sub_978C`/`sub_97BC`/`sub_9836` | - | `sub_9484` | Shape/edge projection. |
| `sub_9272` | `0x9272` | — | Alternate/unused strip generator. |

## Control flow / state machine

`sub_942A`: for each index in `ram_FF1D50` (0xFFFF-terminated), record =
`ram_FFD37C + idx*$14`; save `Animation_ram_TileIndex/SpriteIndex` in
`ram_FF1362/1364`; call `sub_9484`; restore on overflow.
`sub_9484`: unmarshal the record, compute the shape(s) (`unk_3BF1A`), project/clip,
call `sub_8FB4` (`sub_9142/91F0` strips, `sub_9306/93D2` tiles, `sub_5760` sprites),
copy the chain into the SAT with the x offset/clipping, then the second shape.
`sub_8FB4`: build the road strip/tile for d0/d1 and the object's sprite chain.

## RAM / ROM & structures

- Visible list `ram_FF1D50` (`$FF1D50`); object array `ram_FFD37C` (`$FFD37C`),
  0x14-byte records: x, y, scale, horizon, shape, flags, x offset, second shape.
- Record flags: bit15 shadow, bits 12-13 priority, bit7 of `$B` special/two-part, low
  3 bits sprite rows.
- Road: `ram_FF0D26/0D28/0D2A/0D2E/102E`, `ram_FF132E/1330/1332/1336`,
  `ram_FF136A` (horizon), `ram_FF1366` (chain end).
- Projection: `ram_FF133A/133C/133E/1340/1342/1344/1348/134C/1350/1354/1356/1358/135A/135C/135E/1360/1362/1364`.
- Sprite state: `Animation_ram_SpriteIndex/TileIndex/BaseTile`, `ram_FFDE5E..70`,
  `Race_ram_CurrentSpriteAttributeTable` (double-buffered `$FF479C`/`$FF4E1C`),
  `Race_ram_CurrentSpriteTileArray`.
- `unk_3BF1A` (`$3BF1A`): shape pointer table; shape data lives in the gap (dynamic
  sample `$05994E`, bytes `10 37 20 36 ...`).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `sub_942A` | `0x942A` | [x] | [x] | [x] | [x] | [x] | [x] | analyzed |
| `sub_9484` | `0x9484` | [x] | [~] | [x] | [x] | [x] | [x] | partial |
| `sub_8FB4` | `0x8FB4` | [x] | [~] | [x] | [x] | [x] | [x] | partial |
| `sub_9142`/`sub_91F0` | `0x9142`/`0x91F0` | [x] | [~] | [x] | [x] | [x] | - | partial |
| `sub_9306`/`sub_93D2` | `0x9306`/`0x93D2` | [x] | [~] | [x] | [x] | [x] | - | partial |
| `sub_978C`/`sub_97BC`/`sub_9836` | - | [x] | [~] | [x] | - | [x] | - | partial |

Detailed listing and dynamic samples: `docs/analysis/road_render.md`.

## External calls / dependencies

- Caller: `race.asm` (`sub_942A`).
- Internal: `sub_5760` (rider sprite chain), `Animation_ram_*`/`Race_ram_*` state.
- `race.asm` also uses `unk_3BF1A` (`0x10018`, `0x10352`).

## Hacks / bugs / quirks

- `sub_9272` has no direct caller; likely alternate/dead. `[static]`
- The module shares `Animation_ram_TileIndex`/`SpriteIndex` with the animation/sprite
  builders as a combined road/sprite cursor. `[static]`
- The SAT is double-buffered; the dynamic run showed `$FF479C`/`$FF4E1C`. `[dynamic]`

## Verified facts

- `[static]` `race.asm` -> `sub_942A` -> `sub_9484` -> `sub_8FB4` -> `sub_5760`.
- `[static]` Object record layout and the 0x14-byte array/list.
- `[dynamic]` Demo list `1,2,3,4,9,0,A,B,5,6,C,D,E,7,8,F`; records/fields sampled;
  first `sub_8FB4` `d0=d1=$10000`, shape data `$05994E`.

## Hypotheses

- `[hypothesis]` The 16 demo objects are the player, opponents and road props; test:
  map object records to race.asm roles.
- `[hypothesis]` `sub_9272` is an unused early version of `sub_91F0`.
- TODO: exact shape-byte format and projection constants (`$C0/$200`).

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `sub_942A` | `Road_DrawObjects` | visible-list renderer | high |
| `sub_9484` | `Road_DrawObject` | one object record | high |
| `sub_8FB4` | `Road_DrawStrip` | road strip/tile + sprites | high |
| `sub_9306` | `Road_WriteTiles` | tile columns | high |
| `sub_93D2` | `Road_ClearEdgeTiles` | clears edge tiles | high |
| `ram_FF1D50` | `Road_VisibleObjectList` | object index list | medium |
| `ram_FFD37C` | `Road_ObjectArray` | 0x14-byte records | medium |
| `unk_3BF1A` | `Road_ShapeTable` | shape pointer table | medium |

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Object list/records | GDB demo race, `0x942A`/`0x9484` | 16-item list, 0x14 records | Layout confirmed |
| Road strip | GDB `0x8FB4` | d0=d1=$10000, shape `$05994E`, tile 4, sprite 2 | Strip builder confirmed |

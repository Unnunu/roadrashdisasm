# Analysis: `src/race/animation.asm` (sprite animation renderer)

- **Module:** animation script renderer; SAT entry builder; optional tile copy
- **ROM range:** `0x016860`–`0x0169AF`
- **Status:** analyzed (scripts/data TODO)
- **Source:** `src/race/animation.asm`
- **Related:** `docs/analysis/race_hud.md`, `docs/analysis/rider_sprites.md`,
  `docs/modules/animation.md`, `docs/ram-map.md`

## Functions

| Function | Address | Role |
|---|---|---|
| `UpdateAnimation` | `0x16860` | Build SAT sprites for a frame and copy the needed tiles. |
| `UpdateAnimation2` | `0x16926` | Same, but tiles are already in VRAM (no copy). |
| `Animation_dTileCountMinus1` | `0x169A0` | `(VS+1)*(HS+1)-1` lookup by size code. |

## Script / frame format

```text
script:  .l tilemap_base, .w frame_count, .l frame_ptr[frame_count+1]
frame:   .w sprite_count_minus_1, then per sprite:
         .w dy, .w size(1), .w palette|flip|tile, .w dx
```

The first word is loaded into `d0` and consumed by `dbf d0`; `0` therefore draws
one sprite, `n` draws `n+1` sprites.

`UpdateAnimation`:

1. Store `PosX`/`PosY`; `d7 = Animation_ram_SpriteIndex`;
   `d5/d6 = Animation_ram_TileIndex/TileIndex+BaseTile`.
2. If `frame > frame_count` -> return.
3. `a2 = frame_ptr[frame]`; `a4 = tilemap_base`.
4. For each sprite: write SAT entry (`posY+dy`, link/size, `$8000|palette|flip|tile`,
   `posX+dx`); look up `Animation_dTileCountMinus1[size>>8]`; copy `count+1` tiles
   (`$20` bytes each) from `tilemap_base+tile*$20` into the tile buffer; advance the
   tile index.
5. Terminate the link (`-5(a0)=0`); store `Animation_ram_TileIndex/SpriteIndex`.

`UpdateAnimation2` skips the tile copy and adds only `Animation_ram_BaseTile`; used
when the tiles are preloaded in VRAM (e.g. `EndLevel_UpdateAnimation`).

## Data / RAM

- `Animation_ram_PosX $FF190C`, `PosY $FF190E`,
  `TileIndex $FFDE60`, `SpriteIndex $FFDE64`, `BaseTile $FFD34A`.
- Destination: `Race_ram_CurrentSpriteAttributeTable $FF38AC`,
  `Race_ram_CurrentSpriteTileArray $FF38D0`.
- `Animation_dTileCountMinus1`: index 0..15 -> `0,1,2,3, 1,3,5,7, 2,5,8,11, 3,7,11,15`.

## Users

- Race HUD needles (`RaceHud_NeedleScript` script), `RiderSprites_Build`, `EndLevel_UpdateAnimation`,
  and raced actor/sprite code; `UpdateAnimation2` for preloaded VRAM.
- `RaceHud_NeedleScript` is fully decoded in `docs/analysis/race_hud.md`: 32
  one-sprite frames at `$7DF30` (10 bytes each), tilemap base `$7E070`.

## End-level script

`EndLevel_AnimationScript` (`$8DC2-$8FB3`, `0x1F2` bytes) is an `UpdateAnimation2` script:
`.l` tilemap base `$80000` (`EndLevel_AnimationTiles`, unused by `UpdateAnimation2`),
`.w` last frame index `122`, then 123 `.l` pointers. The pointers are absolute addresses
in the decompressed `EndLevel_AnimationData` buffer at `Intro_ram_ImageBuffer` (`$5066`
bytes); they run from `+$0000` to `+$5024` and are strictly increasing. Frames 0 and 1
are empty (0 sprites); level cut-offs use the inclusive indices in
`EndLevel_FrameCounts`.

## Open questions

- Individual animation frame data (end-level `EndLevel_AnimationData`, actor
  sprite scripts) and the per-frame sprite layout; the HUD needle script is decoded.
- The exact SAT link/priority semantics and maximum sprite counts.
- Dynamic verification of scripts and tile copies.

## Rename proposals

Applied: `unk_169A0` -> `Animation_dTileCountMinus1`. Individual scripts/frames remain
TODO.

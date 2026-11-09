# Analysis: asset splitting and preview pipeline

- **Status:** Phase A implemented for the ROM tail images/palettes; race
  tiles/maps and audio deferred
- **Tool:** `tools/assets.py` + `tools/asset_specs.json`
- **Generated:** `assets/` (git-ignored; never committed because the extracted
  artwork is copyrighted)
- **Build:** `build.sh` runs `tools/assets.py split`; `rom_assets.asm` and
  `race_misc_data.asm` `binclude` the generated `.bin` files (not `baserom.md`)

## Asset types found in the tail

| Type | Examples | Layout |
|---|---|---|
| Image with embedded palette + map | intro background, menu race cards, highscore title, endlevel window, result panel, race HUD, 5 track images, 11 portraits | header `$0808xxxx` → tiles → 128-byte palette → `(w,h)` → map |
| Image with external palette + map | gamepad, highscore badge, intro title, race-selection background, shop bikes, race badges, password selection | header → tiles → `(w,h)` → map; palette from the screen |
| Tileset / font | intro font, highscore font, shop arrow left, player selection, extra tiles | header → tiles; layout/atlas |
| Map only | `unk_9B2F0` 40×17, `unk_9B7A6` 3×17 | first long `(w,h)` → entries |
| Raw tiles/animation | `EndLevel_AnimationTiles`, `EndLevel_AnimationData` | raw bytes / animation stream |
| Standalone palettes | `Shop_BikePalettes` 8×16, `unk_7E470` 16×16 | 32 bytes/palette |
| Embedded palettes | in the image buffers above | 128 bytes, 64 colors |

Compression is LZSS B (byte stream) or W (word stream), per asset.

## Screen palette sources

| Group | Source asset | Offset | Colors |
|---|---|---|---|
| intro | `intro_background` | `+$34E4` | 64 |
| menu | `menu_race_cards` | `+$26E4` | 64 |
| highscore | `highscore_title` | `+$4E4` | 64 |
| shop | `shop_arrow_right` | `+$C4` | 64 |
| endlevel | `endlevel_window` | `+$2E4` | 64 |

`img_MainMenu_Background` and `img_Gamepad` are used with both the menu and
endlevel palettes, so they get `preview_menu.png` and `preview_endlevel.png`.
Shop bike images use the shop palette plus `Shop_BikePalettes[0..7]` overrides
on lines 2/3 (`preview_bike0.png`..`preview_bike7.png`).

## Layout and build

```
assets/
  images/<id>/data.bin      # exact ROM slice; binclude in rom_assets.asm
  tilesets/<id>/data.bin
  maps/<id>/data.bin
  palettes/<id>/data.bin
  raw/<id>/data.bin
  .../meta.json             # address, size, compression, layout, palette refs
  .../preview*.png          # generated previews
  .../atlas_line*.png       # tileset/font atlases
  .../palette*.png/json
```

Previews are RGB (`preview.png`) plus indexed PNG (`preview_indexed.png`) where
supported. Sprites/tilesets use transparency for pixel value 0; backgrounds do
not. Palette variants are named by source group / bike index.

## Tool commands

```sh
python3 tools/assets.py split    # regenerate exact .bin slices from baserom.md
python3 tools/assets.py render   # decode + PNG previews (Pillow)
python3 tools/assets.py check    # verify every .bin against baserom.md
python3 tools/assets.py all
```

`build.sh` only needs `split`; previews are optional/local. The manifest
(`tools/asset_specs.json`) is our metadata and is committed; `assets/` is not.

## Deferred

- Race tiles/maps (`unk_9B2F0`, `unk_9B494`, `unk_9B7A6`, `unk_9B89E`,
  `unk_9DA6A`/`9DB68`/`9DC4C`/`9DDCC`/`9E3A2`): palette associations need
  confirmation; previews are disabled.
- `results_busted`, `results_image_extra`: palette TODO.
- `EndLevel_AnimationData`, road/sprite/object streams, audio: raw `.bin` with
  metadata; previews later.

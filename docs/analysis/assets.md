# Analysis: asset splitting and preview pipeline

- **Status:** Phase A (tail images/palettes) + confirmed race HUD/track palettes;
  `race_map_0` tileset and audio remain deferred
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

Race palettes were confirmed statically:

- `Race_LoatTrackGfx` decompresses `RaceTrack_Data6` (LZSS B) and copies 17 words
  from the track palette (`-2(Data6)` offset) to `Global_ram_Palette + $22`
  (palette line 1); the background map entries use line 1.
- `Race_LoadHUD` copies the line-3 colors from the `unk_9C82A` HUD image palette
  to `Global_ram_Palette + $62`; maps using line 3 (`race_map_1`,
  `race_tiles_0`, `race_image_0`) are rendered with that HUD base.
- Per-track race palettes are written to `assets/palettes/race_track0..4`.

Enabled race previews: `race_tiles_0` (3×17 edge strip), `race_map_1` (3×17),
`race_image_0` (128×14 scenery strip), and HUD-palette atlases for
`race_tiles_1..4`. `race_map_0` is **not** rendered: its map uses a tile base at
VRAM `$3000` whose source tileset has not been identified; the data is still
split.

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

- `race_map_0` (`unk_9B2F0`, 40×17): base tile `$4180` points at VRAM `$3000`;
  the tile source/layout is still unknown, so the preview is disabled.
- `race_road` (`unk_9DDCC`): the `(8,24)` block at `+$724` is a road-tile table,
  not a normal nametable; preview deferred.
- `results_busted`, `results_image_extra`: palette TODO.
- `EndLevel_AnimationData`, road/sprite/object streams, audio: raw `.bin` with
  metadata; previews later.

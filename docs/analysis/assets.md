# Analysis: asset splitting and preview pipeline

- **Status:** Phase A (tail images/palettes) + race HUD/track palettes; visual IDs for
  track backgrounds/clouds/overlay recorded; `race_map_0` tileset and audio remain deferred
- **Tool:** `tools/assets.py` + `tools/asset_specs.json`
- **Generated:** `assets/` (git-ignored; never committed because the extracted
  artwork is copyrighted)
- **Build:** `build.sh` runs `tools/assets.py split`; `src/data/rom_assets.asm` and
  `src/data/race_misc_data.asm` `binclude` the generated `.bin` files (not `baserom.md`)

## Asset types found in the tail

| Type | Examples | Layout |
|---|---|---|
| Image with embedded palette + map | intro background, menu race cards, highscore title, endlevel window, result panel, race HUD, 5 track images, 11 portraits | header `$0808xxxx` → tiles → 128-byte palette → `(w,h)` → map |
| Image with external palette + map | gamepad, highscore badge, intro title, race-selection background, shop bikes, race badges, password selection | header → tiles → `(w,h)` → map; palette from the screen |
| Tileset / font | intro font, highscore table font, high-score digit font (`FontHighScoreDigits`, 10 glyphs `0`-`9`), shop arrow left, player selection, extra tiles | header → tiles; layout/atlas |
| Map only | `unk_9B2F0` 40×17, `unk_9B7A6` 3×17 | first long `(w,h)` → entries |
| Raw tiles/animation | `EndLevel_AnimationTiles`, `EndLevel_AnimationData` | raw tiles; script frame stream |
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
  images/<id>/data.bin      # exact ROM slice; binclude in src/data/rom_assets.asm
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

## EA logo

`LogoEA_Image_ElectronicArts` is a ROM slice at `0xCFE` (size `0x3D6`) and is now
generated as `assets/images/ea_logo/data.bin`; the previously tracked root
`LogoEA_Image_ElectronicArts.bin` was removed. It uses the custom
`LogoEA_DecompressLZ` format, so PNG preview is deferred.

## Audio binary assets

`tools/asset_specs.json` also generates `assets/audio/z80_driver/data.bin`
(`0x1DA12`, `0xBBB`) and `assets/audio/sound_data/data.bin`
(`0x1E5CD`, `0x7203`). They are raw binaries; Z80 disassembly and sound-data
parsing are tracked in `docs/analysis/audio.md`.

## Verification status

`race_track_background_0` is the first verified reference asset:

```sh
python3 tools/asset_verify.py --asset race_track_background_0
```

Raw slice, LZSS-B output, Data6 header offsets, parsed layout and the runtime
`Intro_ram_ImageBuffer` dump all match. Details: `docs/analysis/asset_verification.md`.
Shape previews remain candidate until `Road_WriteTileColumns` is captured the same way.

## Stage B visual review

Generated from the current ROM:

```sh
python3 tools/assets.py all
```

### Visual identifications

Reviewed from the generated previews (`[dynamic]`, user visual review):

| Asset | Identification |
|---|---|
| `race_track_background_0..4` | One stacked strip split into upper/lower halves: upper = distant background (sky/mountains/forest), lower = nearer background. The game parallax-scrolls both layers. |
| `race_image_0` | Cloud layer; scrolls horizontally as the track turns. |
| `intro_natasha_overlay` | Natasha face overlay; previously rendered with the wrong intro palette, now uses the Natasha portrait palette (`portrait0`). |
| `race_road` | Road-tile/side strip; previews rendered for all five track palettes. |
| `results_busted` | Result/busted panel strip; preview generated with the result-panel palette. |
| `results_image_extra` | Result-screen extra tiles; preview generated with the result-panel palette. |
| `endlevel_animation_tiles` | End-level animation tile atlas; see `atlas_line0.png`. |

`race_map_0`/`race_map_1` are nametable maps, not standalone images; their
tileset/palette mapping is still unknown, so misleading previews were removed.
`race_road` is a road-tile table, not a normal image map; its preview is disabled.
Raw slices remain under `assets/maps/` and `assets/tilesets/` for later mapping.

Newly rendered track backgrounds:

| Asset ID | Source | Size | Preview |
|---|---|---:|---|
| `race_track_background_0` | `0x28A3E` `Track_Data6_0` | `0x1B56` | `assets/images/race_track_background_0/preview.png` |
| `race_track_background_1` | `0x2CC8C` `Track_Data6_1` | `0x1848` | `assets/images/race_track_background_1/preview.png` |
| `race_track_background_2` | `0x311B8` `Track_Data6_2` | `0x11CC` | `assets/images/race_track_background_2/preview.png` |
| `race_track_background_3` | `0x35174` `Track_Data6_3` | `0x12B2` | `assets/images/race_track_background_3/preview.png` |
| `race_track_background_4` | `0x3A2E0` `Track_Data6_4` | `0x1A6A` | `assets/images/race_track_background_4/preview.png` |

All previews are indexed in the generated `assets/review.html` (local-only).
The track backgrounds use the embedded image layout: tiles -> 128-byte palette ->
`(w,h)` -> nametable; the `Data6-4/-2` header offsets point at the same nametable
and palette regions.

## Deferred

- `race_map_0` (`unk_9B2F0`, 40×17): base tile `$4180` points at VRAM `$3000`;
  the tile source/layout is still unknown. Candidate previews exist, but the
  correct tileset is not confirmed.
- `endlevel_animation_data` (`0x8BF12`): compressed frame stream; decompresses to
  `$5066` bytes at runtime. `EndLevel_AnimationScript` (`$8DC2`) holds the 123 frame
  pointers into that buffer; per-frame sprite layout remains TODO.

Shape IDs are not asset files. They are indices into `Road_ShapeTable`
(`0x3BF1A`, 564 entries) in `src/data/road_shapes.asm`; the shape data is
`0x3C7EC..0x7DBA7`. Use `python3 tools/road_shapes.py split` to generate
`assets/shapes/<id>/data.bin` plus `assets/shapes/index.csv`; the sample visual
page is `assets/shapes/review.html`. See `docs/analysis/road_shapes.md`.
- `EndLevel_AnimationData`, road/sprite/object streams, audio: raw `.bin` with
  metadata; previews later.

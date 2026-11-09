# Analysis: `road_shapes.asm` (road/object shape table + data)

- **ROM range:** `0x03BF1A`–`0x07DCA7`
- **Status:** table/count/data layout analyzed; shape record format TODO
- **Source:** `road_shapes.asm` (table/count from source, data `binclude` from `baserom.md`)
- **Related:** `docs/analysis/road_render.md`, `docs/analysis/race_track_data.md`,
  `docs/modules/road_shapes.md`, `docs/ram-map.md`

## Layout

| Label | Address | Size | Meaning |
|---|---|---|---|
| `Road_ShapeTable` | `0x3BF1A` | `0x8D0` | 564 dword shape-data pointers. |
| `word_3C7EA` | `0x3C7EA` | 2 | Shape count `$0234` (564). |
| `Road_ShapeData` | `0x3C7EC` | `0x414BC` | Shape bytes (opaque). |

Evidence [static]:
- `Road_DrawObject` (`road_render.asm`) indexes with `object+8` / `object+$12`
  (`asl.w #2` -> `Road_ShapeTable`), and `race_ai.asm` does the same for object scaling.
- `race_anim_audio.asm` `sub_154D2` compares a computed shape index to `word_3C7EA`,
  which is exactly the number of table entries (`$3C7EA-$3BF1A = 0x8D0 = 564*4`).
- The first table pointer is `0x3C7EC` (immediately after the count); the maximum is
  `0x7DBA8`, and the next named data (`unk_7DCA8`) starts at `$7DCA8`, i.e. the last
  shape extends to the end of `Road_ShapeData`.

The table has 500 nonzero entries and 366 unique pointers (zeros = no shape; repeated
pointers = symmetric/mirrored shapes). The ordered first pointers are
`$3C7EC,$3CC4C,$3D0BE,$3D55C,$3DA0E,$3DF28,...`.

## Consumers

- `Road_DrawObject`/`Road_ScaleShape`/`Road_ProjectShape*` (`road_render.asm`).
- `race_ai.asm` object AI (`sub_12070`, shape index/scaling paths).
- `race_anim_audio.asm` `sub_154D2` (shape-index limit).

## Shape data

The shape bytes are read as `(a2)`, `1(a2)`, `2(a2)` by `Road_ScaleShape`; the exact
record layout, edge/width encoding and projection constants are still TODO (they need
the shape data plus the race-side record writers). The bytes are included raw from
`baserom.md` to preserve byte-exactness.

## Open questions

- Shape record format: header/edges/width and the `scale>>2` fields.
- Which table entries are road pieces vs object/background shapes.
- Why some pointers repeat (mirroring/aliasing) and how flags select them.
- `unk_7DCA8`, `unk_7DEAA` (HUD needle script), `Shop_BikePalettes` and the remaining
  bytes before `top_level.asm` (`0x7DCA8-$7E6A1`) are now in `race_misc_data.asm`.

## Rename proposals

No renames applied; `Road_ShapeTable`/`word_3C7EA` are kept.

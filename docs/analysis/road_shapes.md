# Analysis: `src/data/road_shapes.asm` (road/object shape table + data)

- **ROM range:** `0x03BF1A`–`0x07DCA7`
- **Status:** table/count/data layout analyzed; shape record header/edges partly confirmed; row data TODO
- **Source:** `src/data/road_shapes.asm` (table/count from source, data `binclude` from `baserom.md`)
- **Related:** `docs/analysis/road_render.md`, `docs/analysis/race_track_data.md`,
  `docs/modules/road_shapes.md`, `docs/ram-map.md`

## Layout

| Label | Address | Size | Meaning |
|---|---|---|---|
| `Road_ShapeTable` | `0x3BF1A` | `0x8D0` | 564 dword shape-data pointers. |
| `word_3C7EA` | `0x3C7EA` | 2 | Shape count `$0234` (564). |
| `Road_ShapeData` | `0x3C7EC` | `0x414BC` | Shape bytes (opaque). |

Evidence [static]:
- `Road_DrawObject` (`src/race/road_render.asm`) indexes with `object+8` / `object+$12`
  (`asl.w #2` -> `Road_ShapeTable`), and `src/race/race_ai.asm` does the same for object scaling.
- `src/race/race_anim_audio.asm` `sub_154D2` compares a computed shape index to `word_3C7EA`,
  which is exactly the number of table entries (`$3C7EA-$3BF1A = 0x8D0 = 564*4`).
- The first table pointer is `0x3C7EC` (immediately after the count); the maximum is
  `0x7DBA8`, and the next named data (`unk_7DCA8`) starts at `$7DCA8`, i.e. the last
  shape extends to the end of `Road_ShapeData`.

The table has 500 nonzero entries and 366 unique pointers (zeros = no shape; repeated
pointers = symmetric/mirrored shapes). The ordered first pointers are
`$3C7EC,$3CC4C,$3D0BE,$3D55C,$3DA0E,$3DF28,...`.

### Dynamic shape samples

`Road_ScaleShape`/`Road_ProjectShape` were traced with the live object list:

| Shape | Pointer | Header bytes | First DrawStrip word |
|---|---:|---|---:|
| `$56` | `$05994C` | `10 37 20 36` | `$2036` |
| `$57` | `$059CE8` | `0E 36 1E 36` | `$3636` (second shape path) |
| `$1C3` | `$078B0E` | `0F 1C 1E 1C` | `$1C1C` |
| `$1C4` | `$078CD4` | `09 46 13 2A` | `$2A13` |
| `$15E` | `$069924` | `0A 47 1A 47` | `$471A` |

Working model (static + dynamic, exact row encoding still TODO):

- `P[0]` is the primary edge/width used by `Road_ProjectShape`;
- `P[1]` is the secondary edge/height;
- `P[2]/P[3]` form the word read by `Road_DrawStrip` (tile/fill), and `P[2]`
  is also the mirror-side edge used by `Road_ScaleShape`;
- `P+4` onward is the per-row strip data consumed by
  `Road_InterpolateLeftEdge`/`Road_InterpolateRightEdge`.

`[dynamic]` For `$56`, `Road_ScaleShape` sees `P=$05994C` and reads
`10/37/20`; `Road_DrawStrip` then receives `a0=$05994E` (P+2), whose first word is
`$2036`. This confirms the P+2 handoff for the special/two-part path.

## Consumers

- `Road_DrawObject`/`Road_ScaleShape`/`Road_ProjectShape*` (`src/race/road_render.asm`).
- `src/race/race_ai.asm` object AI (`sub_12070`, shape index/scaling paths).
- `src/race/race_anim_audio.asm` `sub_154D2` (shape-index limit).

## Shape data

The shape bytes are read as `(a2)`, `1(a2)`, `2(a2)` by `Road_ScaleShape`;
`Road_ProjectShape`/`Road_ProjectShapeSpecial` use byte0 for the projected edge and
the object X plus `$C0/$200`. `Road_DrawStrip` starts at **shape pointer + 2**:
the word at `+2` becomes `ram_FFDE5E` (tile/fill base), and `+4` onward is the
per-row strip data copied/interpolated into `ram_FF0D2E`/`ram_FF102E`.

`[dynamic]` First demo `Road_DrawStrip`: shape id `$56`, pointer `$05994C`,
bytes `10 37 20 36 00...`; `Road_ScaleShape` reads `10/37/20`, then
`Road_DrawStrip` receives `a0=$05994E` and its first word is `$2036`. This confirms
the `+2` handoff; exact row encoding is still TODO.

## Open questions

- Shape record format: header/edges/width and the `scale>>2` fields.
- Which table entries are road pieces vs object/background shapes.
- Why some pointers repeat (mirroring/aliasing) and how flags select them.
- `unk_7DCA8`, `unk_7DEAA` (HUD needle script), `Shop_BikePalettes` and the remaining
  bytes before `src/core/top_level.asm` (`0x7DCA8-$7E6A1`) are now in `src/data/race_misc_data.asm`.

## Rename proposals

No renames applied; `Road_ShapeTable`/`word_3C7EA` are kept.

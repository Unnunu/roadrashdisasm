# Analysis: `src/data/road_shapes.asm` (road/object shape table + data)

- **ROM range:** `0x03BF1A`–`0x07DCA7`
- **Status:** table/count/data layout analyzed; shape header/control/fill model confirmed; row-byte semantics partly TODO
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

| Shape | Pointer | Header bytes | Entry word |
|---|---:|---|---:|
| `$56` | `$05994C` | `10 37 20 36` | `$2036` |
| `$57` | `$059CE8` | `0E 36 1E 36` | `$3636` (second shape path) |
| `$1C3` | `$078B0E` | `0F 1C 1E 1C` | `$1C1C` |
| `$1C4` | `$078CD4` | `09 46 13 2A` | `$2A13` |
| `$15E` | `$069924` | `0A 47 1A 47` | `$471A` |

Confirmed record layout (static + dynamic; exact row pixel mapping still TODO):

| Pointer | Non-special path | Special/two-part path (`$B` bit7) |
|---|---|---|
| `P+0` | left strip control | first-shape projection control |
| `P+1` | right strip control | first-shape projection control |
| `P+2` | fill/tile word high | left strip control |
| `P+3` | fill/tile word low | right strip control |
| `P+4` | row/tile data | fill/tile word high |
| `P+5` | row/tile data | fill/tile word low |
| `P+6` | row/tile data | row/tile data |

- `Road_InterpolateLeftEdge` consumes `P+0` (or `P+2` in the special path).
- `Road_InterpolateRightEdge` consumes `P+1` (or `P+3`).
- `Road_DrawStrip` then reads the fill/tile word: `P+2/P+3` or `P+4/P+5`.
- `Road_WriteTileColumns` starts at the next byte and consumes row/tile bytes;
  the interpolators produce per-strip byte offsets in `ram_FF0D2E`/`ram_FF102E`.
- `Road_ScaleShape` reads `P+0/P+1/P+2`; `Road_ProjectShape` reads `P+0`;
  the mirror bit uses the `P+2` width delta.

- `[dynamic]` At `Road_WriteTileColumns` the first two objects had
`ram_FF0D2A=$059952`/`$059CEE` (shape pointer + 6; special/mirror offset), strip counts
`ram_FF132E=4`/`3`, `ram_FF1330=$35`. Row bytes at `$059952`:
`00 00 00 00 00 00 00 00 33 33 00 00 ...`; at `$059CEE`:
`00 00 00 00 00 00 00 00 33 33 30 00 ... 32`. Tile data is therefore a byte
sequence consumed with the interpolated per-strip offsets; exact tile/row mapping
is still TODO.

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
bytes `10 37 20 36 00...`; `Road_ScaleShape` reads `10/37/20`, then the special path
passes `a0=$05994E` (P+2): left control `$20`, right control `$36`, fill word
`$2036` at P+4/P+5, and row data starts at `$059952` (P+6). This confirms the
special-path table above; exact tile/row pixel mapping is still TODO from
`Road_WriteTileColumns`.

## Shape ID lookup

Shape IDs are **not** in `assets/`; they are indices into `Road_ShapeTable` at
`0x3BF1A` (`src/data/road_shapes.asm`), with data at `0x3C7EC..0x7DBA7`.
The generated local lookup `assets/road_shapes.csv` lists ID, pointer and the first
16 bytes. Sampled IDs are `$56`, `$57`, `$1C3`, `$1C4`, `$15E`.

## Open questions

- Exact row/tile byte mapping and the `Road_WriteTileColumns` 4-byte strip layout.
- Which table entries are road pieces vs object/background shapes.
- Why some pointers repeat (mirroring/aliasing) and how flags select them.
- `unk_7DCA8`, `RaceHud_NeedleScript` (HUD needle script), `Shop_BikePalettes` and the remaining
  bytes before `src/core/top_level.asm` (`0x7DCA8-$7E6A1`) are now in `src/data/race_misc_data.asm`.

## Rename proposals

No renames applied; `Road_ShapeTable`/`word_3C7EA` are kept.

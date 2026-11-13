# Analysis: `src/data/road_shapes.asm` (road/object shape table + data)

- **ROM range:** `0x03BF1A`–`0x07DCA7`
- **Status:** analyzed. Table/count/data layout, shape header/control/fill model and
  the source-byte -> 4bpp sprite-tile mapping are confirmed (L6c/E8)
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

Confirmed record layout (static + dynamic + byte-exact writer replay):

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
  the interpolators produce per-strip byte offsets in `SpriteStrip_ram_PlaneOffsets`/`SpriteStrip_ram_RowOffsets`.
- `Road_ScaleShape` reads `P+0/P+1/P+2`; `Road_ProjectShape` reads `P+0`;
  the mirror bit uses the `P+2` width delta.

- `[dynamic]` At `Road_WriteTileColumns` the first two objects had
`SpriteStrip_ram_SourcePtr=$059952`/`$059CEE` (shape pointer + 6; special/mirror offset), strip counts
`SpriteStrip_ram_ColumnCount=4`/`3`, `SpriteStrip_ram_RowCount=$35`. Row bytes at `$059952`:
`00 00 00 00 00 00 00 00 33 33 00 00 ...`; at `$059CEE`:
`00 00 00 00 00 00 00 00 33 33 30 00 ... 32`.

### Row data and pixel map (L6c)

The row data is a stream of **4bpp bitplane bytes**, consumed through the two
interpolator lists:

- `SpriteStrip_ram_PlaneOffsets` (left list): one 16-bit source advance after every output byte.
  Normally 1, so four consecutive source bytes form the four bitplanes of one
  8-pixel scanline; 0 repeats a byte and >1 skips bytes.
- `SpriteStrip_ram_RowOffsets` (right list): one 16-bit source advance after every source row.
  The next row starts at `previous start + sum(left) + right`. For shape `$56`
  at scale `$10000` that is `16 + 1 = 17` bytes; the trailing zero offsets in the
  left list repeat the last new byte for the short fifth column. At smaller scales
  the advances are larger and the rows are sampled sparsely.

`Road_WriteTileColumns` transposes the stream into column-major 4-tile strips:
for row `r` and column `c` it writes the 4 plane bytes to
`base + 4*r + c*(gap+4)` (modulo the 32-row band wrap). Full-band `gap` is
`SpriteStrip_ram_ColumnGap=$7C` (stride `$80` = 4 tiles), the remainder band uses
`SpriteStrip_ram_TailColumnGap=$5C` (stride `$60` = 3 tiles), and `SpriteStrip_ram_BandAdvance` advances the band
base after 32 rows.

Byte-exact check: shape `$56` (`base=$FF511C`, `src=$059952`, scale `$10000`,
`132E=4`, `1330=$35`) yields 1080 writer bytes, all identical to the golden
`analysis/golden/shape_writer_after.bin`, and the written range is
`$FF511C..$FF5573`. Shape `$56` therefore renders as 5 columns x 54 rows
(40 x 54 px; 4-tile band + 22-row remainder). The fill word `$2036` selects
palette 1 and tile base `$36` for the SAT entries.

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
the word at `+2` becomes `SpriteStrip_ram_FillWord` (tile/fill base), and `+4` onward is the
per-row strip data copied/interpolated into `SpriteStrip_ram_PlaneOffsets`/`SpriteStrip_ram_RowOffsets`.

`[dynamic]` First demo `Road_DrawStrip`: shape id `$56`, pointer `$05994C`,
bytes `10 37 20 36 00...`; `Road_ScaleShape` reads `10/37/20`, then the special path
passes `a0=$05994E` (P+2): left control `$20`, right control `$36`, fill word
`$2036` at P+4/P+5, and row data starts at `$059952` (P+6). This confirms the
special-path table above.

`[confirmed]` E8-A captured the live offset lists for shapes `$56`, `$57` and
`$1C3`; they match the static list generators exactly, including the fractional
scale case (`$1C3`, scale `$145D0`, controls `$1e/$1c`). The writer replay then
reproduces every written byte of shape `$56` (see the row-data section above).

## Shape ID lookup / split

Shape IDs are **not** in `assets/`; they are indices into `Road_ShapeTable` at
`0x3BF1A` (`src/data/road_shapes.asm`), with data at `0x3C7EC..0x7DBA7`.
The generated local lookup `assets/road_shapes.csv` lists ID, pointer and the first
16 bytes. Sampled IDs are `$56`, `$57`, `$1C3`, `$1C4`, `$15E`.

Per-ID split:

```sh
python3 tools/road_shapes.py split
```

This writes `assets/shapes/<id>/data.bin` and `meta.json`; `assets/shapes/index.csv`
has ID/pointer/size/header/aliases. Repeated pointers are retained as aliases.

Candidate visual previews:

```sh
python3 tools/road_shapes.py render --ids 56,57,1C3,1C4,15E
```

`preview_p4_line3.png` starts at `P+4` (non-special),
`preview_p6_line3.png` at `P+6` (special/two-part), using HUD palette line 3 with
the magenta/transparent key shown dark gray. These are **candidate 4bpp tile decodes**, not yet confirmed
row/tile rendering; use them only to identify shapes. The sample page is
`assets/shapes/review.html`.

## Open questions

- Which table entries are object sprites vs. static scenery/background pieces; the
  renderer/staging path is identical, so this needs a visual catalogue, not code.
- Why some pointers repeat (mirroring/aliasing) and how the flags select them; the
  table has 366 unique pointers for 500 nonzero IDs.
- `unk_7DCA8`, `RaceHud_NeedleScript` (HUD needle script), `Shop_BikePalettes` and the remaining
  bytes before `src/core/top_level.asm` (`0x7DCA8-$7E6A1`) are now in `src/data/race_misc_data.asm`.

## Rename proposals

No renames applied; `Road_ShapeTable`/`word_3C7EA` are kept.

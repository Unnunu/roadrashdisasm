# Analysis: `race_misc_data.asm` (final data before top-level)

- **ROM range:** `0x07DCA8`–`0x07E6A1`
- **Status:** layout/consumers analyzed; some internals TODO
- **Source:** `race_misc_data.asm` (raw `binclude` chunks with labels)
- **Related:** `docs/analysis/race_hud.md`, `docs/analysis/shop.md`,
  `docs/analysis/race_results.md`, `docs/analysis/race_ai.md`,
  `docs/analysis/road_shapes.md`, `docs/modules/race_misc_data.md`

## Layout

| Label | Address | Size | Meaning |
|---|---|---|---|
| `unk_7DCA8` | `0x7DCA8` | `0x202` | 257-word 16-bit lookup (sine-like), used by `race_ai sub_112C8`. |
| `unk_7DEAA` | `0x7DEAA` | `0x4C6` | HUD speed/RPM needle animation script (tilemap + frames). |
| `Shop_BikePalettes` | `0x7E370` | `0x100` | 8 bike palettes x 32 bytes. |
| `unk_7E470` | `0x7E470` | `0x200` | 16 actor palettes x 32 bytes (`Race_LoadActorPalette`). |
| `unk_7E670` | `0x7E670` | `0x14` | 5 track-image pointers + terminator (results). |
| `unk_7E684` | `0x7E684` | `0xA` | 5 per-track image offsets (results). |
| `unk_7E68E` | `0x7E68E` | `0xA` | 5 per-track nametable offsets (results). |
| `unk_7E698` | `0x7E698` | `0xA` | 5 per-track palette offsets (results). |

## Consumers

- `race_ai.asm sub_112C8`: indexes `unk_7DCA8` with `d1*2`/`d2*2` (16-bit values).
  Values start `$0000,$0192,$0324,$04B6,...`; the exact sine/scale mapping is TODO.
- `RaceHud_DrawSpeedArrow`/`DrawRPMArrow`: `unk_7DEAA` is the animation script passed to
  `UpdateAnimation`; its first dword points to the tilemap (`$7E070`), the next word is
  the frame count (`$1F`), followed by frame pointers (e.g. `$7DF30,$7DF3A,...`).
- `Shop_*`: `Shop_BikePalettes` (`8*32`) for the bike selection.
- `Race_LoadActorPalette`: `unk_7E470 + index*32`, copies 8 longs (32 bytes) to the
  global palette.
- `race_results.asm`: `unk_7E670[track]` -> compressed track image; `unk_7E684/68E/698`
  are added to the current track id and dereferenced as image/nametable/palette offsets
  (5 entries each).

## Open questions

- `unk_7DCA8` formula/table type (sine? reciprocal?) and whether the 257th word is a
  guard value.
- `unk_7DEAA` frame table/tilemap exact layout (script renderer is documented in
  `docs/analysis/animation.md`).
- `unk_7E670` entry count (5 tracks) and the pointer to the 5th/terminator semantics.
- Dynamic verification of the results track images/palettes.

## Rename proposals

No renames applied; existing labels are kept.

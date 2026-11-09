# Code Style & In-Code Documentation

This guide defines how we write identifiers and comments **inside the assembly
sources**. The goal is a readable, faithful disassembly: the names and comments are
the documentation. Byte-exactness is non-negotiable.

See also:

- `AGENTS.md` — build, toolchain, AS syntax, ROM disassembly workflow.
- `docs/architecture.md` — ROM map and module index.
- `docs/modules/_template.md` — per-module cards (architecture level).

## 1. Principles

- **Byte-exact first.** Comments and renames must not change emitted bytes. Run
  `./build.sh` after any rename (symbols are referenced from many places).
- **Identifiers carry the meaning.** A good name replaces a comment.
- **Comments explain *why*, not *what*.** Do not restate the mnemonic
  (`; add 1 to d0`). Explain intent, hardware effects, and non-obvious constraints.
- **Honest uncertainty.** Use `TODO`/`unknown` instead of guessing. Wrong docs are
  worse than no docs.
- **English only.**
- **Incremental.** Apply this guide when you touch/study a file; do not mass-reformat.

## 2. Identifiers

### 2.1 Routines

- `Subsystem_VerbNoun`, PascalCase with a subsystem prefix:
  `Fade_InitFadeOut`, `Shop_Init`, `LogoEA_Update`, `Race_Update`.
- Common verbs: `Init`, `Update`, `GameTick`, `Draw`, `Load`, `Setup`, `Handle`,
  `Get`, `Set`, `Find`, `Clear`, `Show`.
- Per-frame callbacks: `Subsystem_GameTick`.
- Interrupts: `VerticalInterrupt`, `HorizontalInterrupt`.
- Not yet understood code keeps `sub_XXXX`.

### 2.2 RAM variables

Format: `Subsystem_ram_Field` (e.g. `Fade_ram_Timer`, `Menu_ram_CurrentButtonsPtr`).

Suffix conventions:

| Kind | Suffix / form |
|---|---|
| Pointer | `...Ptr` |
| Array / buffer | `...Array`, `...Buffer` |
| Index / id | `...Index`, `...Id` |
| Timer / delay | `...Timer`, `...Delay` |
| Coordinates | `...PosX`, `...PosY`, `...HPos`, `...VPos` |
| Flags | `...Flag`, `...Enabled`, `...Active` |
| State | `...State` |
| Count | `...Count` |

Not yet identified RAM keeps `ram_XXXXXX` (address-based placeholder).
Cross-module variables always live in `ram_const.asm` (see section 6).

### 2.3 ROM data, tables, constants

- Data tables: `Subsystem_dName` (e.g. `dCircleProfile`, `dStringCodeTable`).
- Graphics/assets: `img_*` (e.g. `img_Intro_Title`).
- Structure field offsets: `STRUCT_OFFSET_<FIELD>` (e.g. `STRUCT_OFFSET_SPEED`).
- Numeric constants: `SCREAMING_SNAKE_CASE` (e.g. `VDP_VRAM_WRITE`).
  Hardware names keep their established spelling (`VdpCtrl`, `VdpData`).
- Not yet identified ROM symbols keep `unk_XXXX`, `off_XXXX`, `word_XXXX`, `byte_XXXX`.

### 2.4 Local labels

- Prefer meaningful names: `.loop`, `.done`, `.return`, `.next`, `.skip`, `.draw`,
  `.check`, `.greaterByte`.
- `.loc_XXXX` / `.locret_XXXX` are placeholders for not-yet-understood targets and may
  stay until a dedicated analysis pass.

### 2.5 Renames

Renaming identifiers is a **separate, explicit task** (e.g. "study this file, then
rename"). Do not rename as a side effect of adding comments. After a rename, update all
references and re-verify the build.

## 3. Comments

### 3.1 File header

Put a short block at the top of each module (values may be `TODO`):

```asm
; *************************************************
; shop.asm - bike shop screen (selection, prices, palette)
; ROM range: $0074AA-$008341
; Status:    partial
; API:       Shop_Init, Shop_GameTick
; *************************************************
```

Status values: `unknown`, `partial`, `analyzed`.

### 3.2 Function header

Keep the existing `; *****` banner style. Fields are **mandatory**; use `-` for none
and `TODO` if not yet known.

```asm
; *************************************************
; Function Fade_InitFadeOut
; Starts a palette fade-out from the current global palette.
; In:       a0 - update function installed for the fade
; Out:      -
; Clobbers: d0/a0-a2
; Notes:    clears the target palette to black; one step every 4 frames
; *************************************************

Fade_InitFadeOut:
    ...
; End of function Fade_InitFadeOut
```

Rules:

- Purpose is a single line, imperative.
- `In` documents registers/stack inputs (`a0 - ...`, `d0 - ...`).
- `Out` documents results (registers, flags, memory).
- `Clobbers` lists registers modified.
- `Notes` covers quirks, side effects, callers if useful.
- Close with `; End of function <Name>`.

### 3.3 Block comments

Before a logical chunk, describe intent in imperative mood, at low indentation:

```asm
; copy the active palette into the current buffer, strip intensity, clear target
```

### 3.4 Inline comments

- One space before `;`, e.g. `move.w #$8F02,(a0) ; auto-increment = 2`.
- Decode magic numbers: VDP registers, structure offsets, hardware ports.
- Keep them short; long explanations belong in a block comment or the module card.

### 3.5 Hardware and magic numbers

Always decode VDP register writes, controller-port tricks, Z80 bus handshakes, and
structure offsets. This is some of the most valuable documentation in the ROM.

## 4. Data tables and structures

- Put a header before a table: element type/size, count, meaning.
- Annotate individual entries when the semantics are known.
- Explicitly mark raw/unidentified data (`; raw data - not identified`).
- For reused/overlay memory, say so (see section 6).

## 5. Legacy artifacts and placeholders

- Legacy external-disassembler cross-reference comments (`CODE XREF`, `DATA XREF`,
  `↑`/`↓` continuations) were removed from the tree; do not reintroduce them.
- Placeholder identifiers (`sub_`, `loc_`, `ram_`, `unk_`, `off_`, `byte_`, `word_`) are
  produced by `tools/disasm.py` for not-yet-understood code and may stay until a
  dedicated rename pass.

## 6. RAM equates and overlays

- Default: all RAM equates live in `ram_const.asm`.
- Cross-module variables always live in `ram_const.asm`.
- A module may keep a **local RAM map** only when it documents a phase-specific
  overlay/scratch area that physically overlaps other allocations. Such a map must:
  - use module-prefixed names (`LogoEA_ram_*`);
  - have an explicit `overlay`/`scratch` note listing the overlapping regions;
  - not duplicate names in `ram_const.asm`.

### logoEA exception

`logoEA.asm` keeps its RAM map locally:

- Addresses are written 32-bit (`$FFFF0000`, `$FFFFC000…$FFFFE7E4`). This is required
  for byte-exactness: `movea.l #LogoEA_ram_Base,a0` emits the literal `207C FFFF 0000`,
  so normalizing to `$FF0000` would change the ROM.
- The area is an overlay: e.g. `LogoEA_ram_TilesSquare`/`TilesTriangle`/`TilesCircle`
  overlap `Menu_ram_FrameBuffer2 ($FFC4AC, size $E00)` and parts of
  `Menu_ram_FrameBuffer`.
- The single cross-module variable `LogoEA_ram_Finished` stays in `ram_const.asm`.

## 7. Markers

- `; TODO: <action>` for pending work.
- `; unknown: <what>` or `TODO` in header fields for unverified facts.
- Do not leave misleading confident comments in unanalyzed code.

## 8. Code comments vs. analysis docs

- **In code:** function contracts, hardware details, local invariants, quirks. Comments
  explain *why*; they are not a line-by-line narration.
- **`docs/modules/<file>.md`:** architecture, control flow, data structures, external
  API, hacks/bugs, coverage matrix, open questions.
- **`docs/analysis/<file>.md`:** deep dives for non-trivial routines — annotated listing,
  algorithm, hardware interactions, "why" with evidence tags.
- **`docs/hardware.md` / `docs/ram-map.md`:** hardware facts and phase-aware RAM.
- **`docs/architecture.md`:** ROM map, boot/interrupt flow, module index.

Avoid duplicating long prose; link instead. Rename proposals live in a table
(Current | Proposed | Evidence | Confidence) and are applied only on request.

## 9. Incremental adoption & verification

- When you touch a module, bring the touched functions up to this standard.
- Do not mass-reformat unrelated code.
- After any rename (or if unsure), run `./build.sh` and require `Matched OK`.

## 10. Canonical example

```asm
; *************************************************
; Function Fade_InitFadeOut
; Starts a palette fade-out from the current global palette.
; In:       a0 - update function installed for the fade
; Out:      -
; Clobbers: d0/a0-a2
; Notes:    target palette is cleared to black; step every 4 frames
; *************************************************

Fade_InitFadeOut:
                move.l  a0,(Fade_ram_UpdateFunction).l
                move.w  #3,(Fade_ram_Timer).l          ; one fade step every 4 frames
                move.l  #Global_ram_Palette,(Global_ram_PalettePtr).l
                movea.l (Global_ram_PalettePtr).l,a0
                lea     (Fade_ram_TargetPalette).l,a1
                lea     (Fade_ram_CurrentPalette).l,a2
; copy the active palette into the current buffer, strip intensity, clear target
                move.w  #$3F,d0                        ; 64 palette entries
.loop:
                move.w  (a0)+,(a2)+                    ; copy to current palette
                andi.w  #$EEE,-2(a2)                   ; clear lowest bit of each channel
                move.w  #0,(a1)+                       ; target = black
                dbf     d0,.loop
                rts
; End of function Fade_InitFadeOut
```

## 11. Checklist

- [ ] Function/identifier names follow the conventions (or are honest placeholders).
- [ ] Every touched function has Purpose/In/Out/Clobbers/Notes.
- [ ] Magic numbers and hardware accesses are explained.
- [ ] Raw/unknown data is marked.
- [ ] No legacy `CODE XREF` / `DATA XREF` / `↑↓` artifacts remain.
- [ ] RAM equates are in the right place; overlays are documented.
- [ ] `./build.sh` reports `Matched OK`.

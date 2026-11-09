# Module card: `<file>.asm`

> Copy this file to `docs/modules/<file>.md` and fill in what is known. Keep it in
> English. Everything not yet verified should stay marked `TODO` — do not guess.

- **ROM range:** `0x??????`–`0x??????` (see `build/roadrash.lst`)
- **Status:** unknown / partially analyzed / analyzed
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/<file>.md`

This card documents the module at the architecture level. Per-function contracts
(Purpose / In / Out / Clobbers / Notes) live in the source itself — see
`docs/coding-style.md`.

## Role / purpose

What this module does in the game. Which screen/phase it belongs to and how it is
entered.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `TODO` | `0x????` | `TODO`  | `TODO`      |

## Control flow / state machine

Describe the main routine(s), states, per-frame update, and key branches. A short
pseudo-code or state diagram is welcome.

## RAM / ROM & structures

- RAM variables used (names from `src/core/ram_const.asm`, addresses, sizes).
- Tables/data in ROM (addresses, element layout).
- Structures and field offsets.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `TODO` | `0x????` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

For non-trivial routines, the annotated listing and detailed "why" live in
`docs/analysis/<file>.md`; link it here.

## External calls / dependencies

Other modules/routines called, and known callers from other modules.

## Hacks / bugs / quirks

Original-game oddities, dead code, workarounds, and ROM-encoding quirks that must be
preserved for byte-exactness (e.g. bit numbers `> 7` on memory operands).

## Verified facts

Confirmed behavior with evidence tags (see `docs/reverse-engineering.md`).

- `[static]` `TODO`
- `[dynamic]` `TODO`
- `[hardware]` `TODO`
- `[confirmed]` `TODO`

## Hypotheses

Unverified ideas. State the experiment that would confirm or refute each one.

- `[hypothesis]` `TODO` — test: `TODO`

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `TODO` | `TODO` | `TODO` | TODO |

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| `TODO` | `TODO` | `TODO` | `TODO` |

## Open questions

- [ ] `TODO`

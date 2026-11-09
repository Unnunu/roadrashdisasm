# Analysis: `<module>` / `<routine>`

> Deep-dive template. Copy to `docs/analysis/<name>.md`. Keep it in English.
> Only `[confirmed]` facts may drive renames; everything else is tagged.
> See `docs/reverse-engineering.md` for tags and `docs/coding-style.md` for source style.

- **Module / routine:** `TODO`
- **ROM range:** `0x??????`–`0x??????`
- **Status:** unknown / partial / analyzed
- **Source:** `TODO.asm`
- **Related:** `docs/architecture.md`, `docs/hardware.md`, `docs/ram-map.md`

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `TODO` | `0x????` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

## Function contract

- **Purpose:** `TODO`
- **In:** `TODO`
- **Out:** `TODO`
- **Clobbers:** `TODO`
- **Notes / side effects:** `TODO`

## Annotated listing

Use for complex/non-obvious routines. One row per instruction or logical group:

| Address | Bytes | Instruction | Explanation | Evidence |
|---------|-------|-------------|-------------|----------|
| `0x????` | `????` | `TODO` | `TODO` | `[static]` |

## Algorithm

Step-by-step description. Include loop invariants, termination, edge cases, and why the
chosen structure works (not just what it does).

## Data structures

- RAM/ROM structures touched, fields, sizes, invariants (link to `docs/ram-map.md`).
- Tables and their element layout.
- Overlay/sharing constraints.

## Hardware interactions

- VDP registers/DMA/CRAM/VSRAM/planes/sprites.
- Controller I/O.
- Z80/YM2612 if relevant.
- Timing/cycle budget for hot paths.

## Why (with evidence)

Explain the reason behind non-obvious choices:

- `[hardware]` required by the hardware (cite the register/field/format).
- `[static]` required by the surrounding data-flow/algorithm.
- `[dynamic]` observed behaviour (describe the experiment).
- `[design]` likely author intent; always a hypothesis unless proven.
- `[unknown]` no evidence; record the open question.

## Experiments

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| `TODO` | `TODO` | `TODO` | `TODO` |

## Rename proposals (apply only on request)

| Current | Proposed | Evidence | Confidence |
|---------|----------|----------|------------|
| `TODO` | `TODO` | `TODO` | TODO |

## Open questions

- [ ] `TODO`

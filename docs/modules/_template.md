# Module card: `<file>.asm`

> Copy this file to `docs/modules/<file>.md` and fill in what is known. Keep it in
> English. Everything not yet verified should stay marked `TODO` — do not guess.

- **ROM range:** `0x??????`–`0x??????` (see `roadrash.lst`)
- **Status:** unknown / partially analyzed / analyzed
- **Related:** `docs/architecture.md`

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

- RAM variables used (names from `ram_const.asm`, addresses, sizes).
- Tables/data in ROM (addresses, element layout).
- Structures and field offsets.

## External calls / dependencies

Other modules/routines called, and known callers from other modules.

## Hacks / bugs / quirks

Original-game oddities, dead code, workarounds, and ROM-encoding quirks that must be
preserved for byte-exactness (e.g. bit numbers `> 7` on memory operands).

## TODO / open questions

- [ ] `TODO`

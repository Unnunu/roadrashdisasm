# Module card: `src/race/rand.asm`

- **ROM range:** `0x015FA8`–`0x0160E1`
- **Status:** analyzed statically; LFSR consumer/dynamic checks TODO
- **Included from:** `src/race/race_anim_audio.asm` at the original block location
- **Related:** `docs/analysis/rand.md`, `docs/analysis/race_anim_audio.md`,
  `docs/modules/race_anim_audio.md`, `docs/ram-map.md`

## Role / purpose

PRNG support split out of `race_anim_audio.asm`: the 32-word initial state table,
the lagged-sum PRNG used by gameplay/screens, a byte wrapper, and two 16-bit LFSR
state helpers. The file is included inside `race_anim_audio.asm` so the contents keep
their original ROM addresses.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Rand_InitSum` | `0x015FE8` | `Intro_Init` | Copy the 32-word table, add the seed, set indexes |
| `Rand_NextWord` | `0x016034` | many race/screen routines | Lagged-sum PRNG word |
| `Rand_GetByte` | `0x01607C` | none | High byte of `Rand_NextWord`; dead |
| `Rand_SeedLfsrs` | `0x016088` | `Intro_Init` | Seed both LFSR states with `$563A` |
| `Rand_StepLfsrA` | `0x01609A` | none | LFSR A step; dead |
| `Rand_StepLfsrAMod` | `0x0160B0` | `MainMenu_GameTick` | LFSR A step + division remainder |
| `Rand_StepLfsrB` | `0x0160CC` | `MainMenu_GameTick` | LFSR B step |

## Control flow / state

- `Rand_InitSum` copies `Rand_InitTable` to `Rand_ram_State`, adds `d0.w` to every word, then
  sets the indexes. Because of `(seed << 7) & $1F`, the indexes are always 0 and 15.
- `Rand_NextWord` returns `state[i1] + state[i2]`, writes the result back to `state[i1]`,
  and advances both indexes modulo 32. Only `d0` is clobbered.
- `Rand_StepLfsrA`, `Rand_StepLfsrAMod`, and `Rand_StepLfsrB` advance a right-shift
  Galois LFSR with mask `$B400`.
  `Rand_StepLfsrAMod` also divides the new state by `d2`; its only caller uses `d2=1` and
  ignores the result.

## RAM / ROM & structures

- ROM: `Rand_InitTable` (`$015FA8`), 64 bytes = 32 initial state words.
- `Rand_ram_State` (`$FF18BE`), 64 bytes: PRNG state.
- `Rand_ram_Index1`/`Rand_ram_Index2` (`$FF18FE`/`$FF1900`), 2 bytes each: indexes; initialized
  to 0 and 15.
- `Rand_ram_LfsrA`/`Rand_ram_LfsrB` (`$FF1B42`/`$FF1B44`), 2 bytes each: LFSR A/B state.
  Static evidence says they are currently write-only.

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|----------|---------|----------|-----------|------|----------|-----|---------|--------|
| `Rand_InitSum` | `0x015FE8` | [x] | [x] | [x] | - | [x] | [ ] | analyzed (index bug) |
| `Rand_NextWord` | `0x016034` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `Rand_GetByte` | `0x01607C` | [x] | [x] | [x] | - | [x] | [ ] | analyzed, unreferenced |
| `Rand_SeedLfsrs` | `0x016088` | [x] | [x] | [x] | - | [x] | [ ] | analyzed |
| `Rand_StepLfsrA` | `0x01609A` | [x] | [x] | [x] | - | [x] | [ ] | analyzed, unreferenced |
| `Rand_StepLfsrAMod` | `0x0160B0` | [x] | [x] | [x] | - | [~] | [ ] | analyzed; result ignored |
| `Rand_StepLfsrB` | `0x0160CC` | [x] | [x] | [x] | - | [~] | [ ] | analyzed; result ignored |

## External calls / dependencies

- `Rand_InitSum` is called by `Intro_Init`; `Rand_NextWord` is called throughout race and
  screen code.
- `Rand_StepLfsrAMod/Rand_StepLfsrB` are called by `MainMenu_GameTick`.
- No calls out of this module.

## Hacks / bugs / quirks

- `Rand_InitSum` index calculation is dead: `(seed << 7) & $1F` is always 0; indexes are
  fixed at 0/15.
- `Rand_GetByte` and `Rand_StepLfsrA` have no callers in the current sources or 32-bit ROM
  references.
- `$FF1B42/$FF1B44` are not read outside the LFSR helpers; the menu advances them but
  discards the results.
- `Rand_StepLfsrAMod` uses `divs.w` with an unvalidated divisor; `d2=0` traps and large
  states can overflow the signed quotient. The only caller ignores the result.

## Verified facts

- `[static]` `Rand_InitTable` is 32 unique words copied to `Rand_ram_State`.
- `[static]` `Rand_InitSum` always sets `Rand_ram_Index1=0`, `Rand_ram_Index2=15`.
- `[static]` `Rand_NextWord` clobbers only `d0`; `d1/d2/a0` are restored.
- `[static]` LFSR state words are write-only in the current build.

## Hypotheses

- `[hypothesis]` The LFSR helpers are vestigial or intended for an unfinished noise
  consumer. Test: BlastEm read watchpoints on `$FF1B42/$FF1B44`; no reads would support
  this.

## Applied renames

| Old | Current | Evidence | Confidence |
|---|---|---|---|
| `byte_15FA8` | `Rand_InitTable` | 32-word initial state table | high |
| `Rand_Init` | `Rand_InitSum` | Lagged-sum state initialization | medium |
| `Rand_GetWord` | `Rand_NextWord` | Advances the state, returns one word | high |
| `sub_1607C` | `Rand_GetByte` | High byte of `Rand_NextWord` | high |
| `sub_16088` | `Rand_SeedLfsrs` | Seeds two LFSR states | high |
| `sub_1609A` | `Rand_StepLfsrA` | LFSR A step | high |
| `sub_160B0` | `Rand_StepLfsrAMod` | LFSR A step + remainder | medium |
| `sub_160CC` | `Rand_StepLfsrB` | LFSR B step | high |
| `ram_FF18BE` | `Rand_ram_State` | 32-word PRNG state | high |
| `ram_FF18FE` | `Rand_ram_Index1` | First tap index | high |
| `ram_FF1900` | `Rand_ram_Index2` | Second tap index | high |
| `ram_FF1B42` | `Rand_ram_LfsrA` | LFSR A state | high |
| `ram_FF1B44` | `Rand_ram_LfsrB` | LFSR B state | high |

## Experiments performed

| Goal | Setup / breakpoint | Observed | Conclusion |
|------|--------------------|----------|------------|
| Static call search | `rg` sources + 32-bit ROM references | no calls to `Rand_GetByte/Rand_StepLfsrA`; LFSR states unread | dead/unreferenced by current code |

## Open questions

- [ ] Dynamically confirm LFSR states have no readers.
- [ ] Explain the intended `Rand_InitSum` index formula; `lsl.w #7` makes it constant.

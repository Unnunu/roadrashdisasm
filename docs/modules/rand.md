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

# Analysis: `src/race/rand.asm` (PRNG and LFSR helpers)

- **Module:** 32-word lagged-sum PRNG, byte wrapper, two 16-bit LFSR helpers
- **ROM range:** `0x015FA8`–`0x0160E1`
- **Status:** analyzed statically; dynamic confirmation of the write-only LFSR state TODO
- **Source:** `src/race/rand.asm`
- **Included from:** `src/race/race_anim_audio.asm` at the original `0x015FA8`
  location, so the ROM stays byte-exact
- **Related:** `docs/analysis/race_anim_audio.md`,
  `docs/modules/rand.md`, `docs/modules/race_anim_audio.md`,
  `docs/ram-map.md`

## Address map

| Address | Symbol | Role |
|---|---|---|
| `0x015FA8`–`0x015FE7` | `Rand_InitTable` | 32-word (64-byte) initial state table for the lagged-sum PRNG |
| `0x015FE8`–`0x016033` | `Rand_InitSum` | Copy table, add seed, set the two indexes |
| `0x016034`–`0x01607B` | `Rand_NextWord` | Lagged-sum word: `state[i1] + state[i2]` |
| `0x01607C`–`0x016087` | `Rand_GetByte` | High byte of `Rand_NextWord` |
| `0x016088`–`0x016099` | `Rand_SeedLfsrs` | Seed both LFSR states with `$563A` |
| `0x01609A`–`0x0160AF` | `Rand_StepLfsrA` | LFSR A step |
| `0x0160B0`–`0x0160CB` | `Rand_StepLfsrAMod` | LFSR A step + division remainder |
| `0x0160CC`–`0x0160E1` | `Rand_StepLfsrB` | LFSR B step |

## Lagged-sum PRNG

`[static]` `Rand_InitSum` copies `Rand_InitTable` to `Rand_ram_State` and adds the
16-bit seed to every word (`add.w`, modulo 65536). The table has 32 words,
all distinct.

`[static]` The index initialization is degenerate:

```
d1 = seed
d1 = (d1 << 7) & $1F   ; always 0: the shift clears the low 7 bits
Rand_ram_Index1 = d1   ; always 0
d1 = (d1 + 15) & $1F
Rand_ram_Index2 = d1   ; always 15
```

So the seed changes the state words but never the indexes. `Rand_InitSum` is
called once from `Intro_Init` (`src/screens/intro.asm:312`) with `d0 = $FFFF`
left by the preceding `dbf` copy loop; that seed subtracts 1 from every
state word.

`[static]` `Rand_NextWord` reads two word indexes, computes
`state[i1] + state[i2]` with 16-bit wrap, stores the result at `state[i1]`,
then increments both indexes modulo 32. The default 0/15 pair means the two
taps stay 15 positions apart. The routine saves/restores `d1/d2/a0`; only
`d0.w` is clobbered. The high word of `d0` is not cleared.

`[static]` `Rand_GetByte` calls `Rand_NextWord`, takes the high byte, and clears
the upper 24 bits (`d0.l = 0..255`). It has no callers in the current sources
or 32-bit ROM references.

## LFSR helpers

`[static]` `Rand_SeedLfsrs` writes `$563A` to `Rand_ram_LfsrA` and `Rand_ram_LfsrB`.
It is called once from `Intro_Init` (`src/screens/intro.asm:313`) and has no
register side effects beyond condition codes.

`[static]` `Rand_StepLfsrA`, `Rand_StepLfsrAMod`, and `Rand_StepLfsrB` implement the same
right-shift Galois step:

```
new = state >> 1
if (state & 1) new ^= $B400
state = new
```

`Rand_StepLfsrA` returns the new state in `d0.w` and has no callers.
`Rand_StepLfsrB` does the same for the second state; its only caller is
`MainMenu_GameTick` (`src/screens/menu_main.asm:502`), which ignores `d0`.

`[static]` `Rand_StepLfsrAMod` zero-extends LFSR A into `d0`, steps it, stores the
state, then executes `divs.w d2,d0` and `swap d0`. The returned low word is
the signed-division remainder when no overflow occurs; the high word is the
quotient. The only caller, `MainMenu_GameTick`
(`src/screens/menu_main.asm:500-501`), passes `d2 = 1` and ignores `d0`, so the
division has no observable effect. `d2 = 1` makes the mathematical remainder
zero, but a state above `$7FFF` can overflow the signed quotient. `d2 = 0`
would raise a divide-by-zero exception.

`[static]` A model of the step gives period 65535 for every nonzero state;
zero is a fixed point. This is a property of the `$B400` mask, not a separate
game routine.

## Callers and observable use

| Function | Callers | Notes |
|---|---|---|
| `Rand_InitSum` | `Intro_Init` | Only one call; seed `$FFFF` |
| `Rand_NextWord` | race/AI/screens (many) | Main PRNG used by gameplay and screen effects |
| `Rand_GetByte` | none | Dead in the current sources/ROM |
| `Rand_SeedLfsrs` | `Intro_Init` | Seeds LFSRs; states are not read elsewhere |
| `Rand_StepLfsrA` | none | Dead in the current sources/ROM |
| `Rand_StepLfsrAMod` | `MainMenu_GameTick` | Result ignored; advances LFSR A |
| `Rand_StepLfsrB` | `MainMenu_GameTick` | Result ignored; advances LFSR B |

`[static]` `race_core.asm:998-999` clears both LFSR state words, but no code
reads `$FF1B42/$FF1B44` outside `Rand_StepLfsrA`, `Rand_StepLfsrAMod`, and
`Rand_StepLfsrB`. Static
evidence therefore says the LFSR path is write-only in this build. This does
not prove author intent; it may be vestigial or intended for an unfinished
consumer.

## Contracts

| Function | In | Out | Clobbers |
|---|---|---|---|
| `Rand_InitSum` | `d0.w` seed | `Rand_ram_State`, `Rand_ram_Index1`, `Rand_ram_Index2` | none (all saved/restored) |
| `Rand_NextWord` | PRNG state/indexes | `d0.w` word; high word unchanged | `d0` |
| `Rand_GetByte` | PRNG state/indexes | `d0.l` byte | `d0` |
| `Rand_SeedLfsrs` | none | two LFSR state words | none |
| `Rand_StepLfsrA` | `Rand_ram_LfsrA` | `d0.w` new state | `d0` |
| `Rand_StepLfsrAMod` | `Rand_ram_LfsrA`, `d2.w` divisor | `d0.l` remainder/quotient; state updated | `d0` |
| `Rand_StepLfsrB` | `Rand_ram_LfsrB` | `d0.w` new state | `d0` |

## Applied renames

| Old | Current | Evidence | Confidence |
|---|---|---|---|
| `byte_15FA8` | `Rand_InitTable` | 32-word initial state table | high |
| `Rand_Init` | `Rand_InitSum` | Lagged-sum state initialization | medium |
| `Rand_GetWord` | `Rand_NextWord` | Advances the state, returns one word | high |
| `sub_1607C` | `Rand_GetByte` | High byte of `Rand_NextWord`; dead | high |
| `sub_16088` | `Rand_SeedLfsrs` | Seeds two LFSR states | high |
| `sub_1609A` | `Rand_StepLfsrA` | One LFSR A step; dead | high |
| `sub_160B0` | `Rand_StepLfsrAMod` | Step A + remainder from `d2` | medium |
| `sub_160CC` | `Rand_StepLfsrB` | One LFSR B step | high |
| `ram_FF18BE` | `Rand_ram_State` | 32-word PRNG state | high |
| `ram_FF18FE` | `Rand_ram_Index1` | First tap index | high |
| `ram_FF1900` | `Rand_ram_Index2` | Second tap index | high |
| `ram_FF1B42` | `Rand_ram_LfsrA` | LFSR A state | high |
| `ram_FF1B44` | `Rand_ram_LfsrB` | LFSR B state | high |

## Open questions

- [ ] Confirm in BlastEm that `$FF1B42/$FF1B44` are never read after the menu
  tick; set read/write watchpoints and run intro → menu.
- [ ] Confirm the intended index formula in `Rand_InitSum`; the current `lsl.w #7`
  makes the shift dead. Possible original intent is unknown.
- [ ] Identify whether `Rand_GetByte`/`Rand_StepLfsrA` were called by cut content or are
  unreachable leftovers.

# Road Rash — Architecture (scaffold)

This document is the top-level map of the ROM and the source modules. It is a
**work in progress**: fill in details as modules are studied and ported.

Related:

- `AGENTS.md` — build rules, AS syntax requirements, ROM disassembly workflow.
- `docs/coding-style.md` — identifiers, comments, function headers, RAM/overlay policy.
- `docs/reverse-engineering.md` — evidence rules, BlastEm workflow, experiment format.
- `docs/hardware.md` — VDP/DMA/controller/Z80 reference and game configurations.
- `docs/ram-map.md` — phase-aware work-RAM map.
- `docs/analysis/` — deep dives (annotated listings, why, experiments).
- `docs/callgraph.md` — generated function index and call graph.
- `docs/references.md`, `docs/glossary.md` — sources and terms.
- `docs/modules/_template.md` — template for per-module cards.
- `docs/modules/README.md` — index of module cards.

## ROM facts

| Item | Value |
|---|---|
| Platform | Sega Genesis / Mega Drive (68000) |
| ROM size | 786432 bytes (`0xC0000`), declared ROM end `0xBFFFF` |
| md5 | `543b64ccb26c18edc6c98c12b1302dc0` |
| Header title | Road Rash |
| Region | US (`U  ` in header) |
| Entry | `RESET` at `0x000200` |
| Disassembly coverage | full ROM `0x000000`–`0x0BFFFF`; source/data `0x000000`–`0x019F61`, `0x0257D0`–`0x07EA65`; raw bridge `0x019F62`–`0x0257CF` (audio); tail `0x07EA66`–`0x0BFFFF` labelled in `src/data/rom_assets.asm` |

`./build.sh` compares the built image against the same-length **prefix** of
`baserom.md`; it grows as more of the ROM is disassembled.

Generated map file: `build/roadrash.lst` (from `./build.sh`, git-ignored). Use it to
look up addresses and the exact bytes emitted for each source line.

## ROM layout (top level)

| Range | Contents |
|---|---|
| `0x000000`–`0x0000FF` | 68000 exception/interrupt vector table (`vectorTable`). |
| `0x000100`–`0x0001FF` | Sega ROM header (`header`). |
| `0x000200` | `RESET`: hardware init, VDP setup, Z80 load, then jumps into the game. |
| `0x0002C4`–`0x0002EA` | Z80 sound-driver blob (`z80_start` … `z80_end`). |
| `0x0002FA` | `doStart`: main menu / game entry. |
| `0x000366` | `src/logoEA/logoEA.asm` include. |
| `0x001164` | `VerticalInterrupt` handler (src/main.asm, after logoEA include). |
| `0x00145A` | `HorizontalInterrupt` handler. |
| `0x001652` | `Audio_UpdateEngine`. |
| `0x001180` | `src/core/fade.asm` include. |
| … | Remaining includes, see module index below. |
| `0x0A4E2` | `src/race/race.asm` include (main gameplay). |

Note: `src/main.asm` is not a single contiguous block. Its code is interleaved with
`include` directives, so the include **order** directly determines the ROM layout.

### Boot / init flow (initial notes)

1. `RESET` (`0x200`) sets up the stack, disables interrupts, initializes VDP and reads
   controller ports.
2. Register defaults are loaded from the `defaults` table (`0x28E`): VDP data/control
   ports, Z80 bus/reset lines, etc.
3. Z80 program is copied/started (`z80_start` … `z80_end`).
4. Control passes to `doStart` (`0x2FA`), which drives the top-level flow
   (logo → intro → menus → race …). See below.

### Top-level flow (`src/core/top_level.asm`, `0x07E6A2`–`0x07EA65`)

`src/main.asm` ends `doStart` with `jmp (loc_7E6A2).l`. At `0x07E6A2` starts the
screen-flow state machine. It uses `ram_UpdateFunction` (`$FF1A62`) as the per-frame
update pointer and `Fade_*` for transitions. The source is `src/core/top_level.asm`, generated from `baserom.md` with
`python3 tools/disasm.py 0x7E6A2 0x7EA66 --mode project --symbolize-immediates --entry-name TopLevel_Init`.
The not-yet-disassembled gap is bridged with raw ROM bytes in `src/main.asm`, split around
the data tables assembled by `src/data/race_data_tables.asm`, `src/data/race_engine_tables.asm`,
`src/data/race_actor_tables.asm`, `src/screens/rider_intro_quotes.asm`, `src/data/race_actor_extra_tables.asm`, `src/data/race_track_data.asm`,
`src/data/road_shapes.asm` and `src/data/race_misc_data.asm`; only the audio range remains raw.

Entry / intro (`$7E6A2`):

- clear `ram_FF1B3E`, `sr=$2500`, write VDP register `$8174`; wait for
  `ram_UpdateFunction == 0`.
- `Fade_InitFadeOut`, copy target palette -> current palette, install
  `Fade_GameTick`, wait.
- `Race_InitPhysicsConstants`, `Audio_Init`, `Intro_Init`, `Fade_InitFadeIn`, install `Fade_GameTick`,
  wait; install `Intro_GameTick`, wait; `Fade_InitFadeOut`, install `Fade_GameTick`,
  wait.
- If `Intro_ram_TextTimer >= 0` -> menu (`$7E74C`); otherwise set
  `MainMenu_ram_DemoMode = -1` and enter the demo high-score path (`$7E7CC`).

Menu loop (`$7E74C`):

- `Menu_Init`, `a0 = MainMenu_GameTick`, `Fade_InitFadeIn`, install
  `FadeWithFunction_GameTick`, wait; fade out with `Fade_GameTick`, wait.
- If `MainMenu_ram_DemoMode != 0` -> high score (`$7E7CC`).
- Otherwise `RiderIntro_Init`, `a0 = RiderIntro_GameTick`, same fade-in/out pair.
- If `MainMenu_ram_DemoMode == 0` -> race (`$7E80C`); otherwise high score.

High score (`$7E7CC`):

- `HighScore_Init`, `a0 = HighScore_GameTick_Demo`, same fade-in/out pair.
- If `MainMenu_ram_DemoMode == 0` -> menu; otherwise race.

Race (`$7E80C`):

- `Race_Init`, `Fade_InitFadeIn`, `sr=$2300`, install `Fade_GameTickWithInit`, wait;
  install `Race_GameTick` (`$BA76`).
- Frame loop (`$7E836`): optional demo reset; call `Race_Update`; track
  `ram_FF1E68`/`ram_FF1E82`; on `Race_ram_GameEnded` either return to the menu (demo)
  or go to the results dispatcher (`$7E924`).

Results dispatcher (`$7E924`) uses `ram_FF0910` as the next-screen selector:

- `RaceResults_Init` -> `RaceResults_GameTick`
- `HighScore_Init` -> `HighScore_GameTick`
- `Shop_Init` -> `Shop_GameTick`
- `EndLevel_Init` (when `ram_FF0918 == 4`) -> `EndLevel_GameTick`

Each screen runs the same fade-in (with `FadeWithFunction_GameTick`) / fade-out (with
`Fade_GameTick`) pair and loops back to the dispatcher. After the dispatcher,
`Menu_ram_PlayerMode == 3` toggles `Menu_ram_Player` with `eori.w #3`, then jumps back
to the menu.

Exact meanings of `ram_FF0918`, `$FF3692`, `$FF3696`, `$FF369A`: **TODO**. The region
is assembled from `src/core/top_level.asm` and verified byte-for-byte by `./build.sh`.

### Interrupts

| Handler | Address | Notes |
|---|---|---|
| `VerticalInterrupt` | `0x1164` | VBlank (IRQ level 6). Saves registers, loads `ram_UpdateFunction` (`$FF1A62`) into `a0`, returns if zero, otherwise `jsr (a0)`. This is the per-frame update dispatcher. `[static]`+`[dynamic]`. |
| `HorizontalInterrupt` | `0x145A` | HBlank (IRQ level 4). TODO. |
| Exception handlers | see `src/main.asm` | Bus/address/illegal/etc.; most write a tag and `stop`. |

## Module index

Addresses are the first byte of each `include` in the assembled ROM. Roles are
tentative until the module card is filled in.

| Address | File | Role (tentative) | Card |
|---|---|---|---|
| `0x000366` | `src/logoEA/logoEA.asm` | EA logo, decompression, drawing | [logoEA.md](modules/logoEA.md) |
| `0x001180` | `src/core/fade.asm` | Palette fade in/out | [fade.md](modules/fade.md) |
| `0x001704` | `src/screens/intro.asm` | Intro sequence | [intro.md](modules/intro.md) |
| `0x002446` | `src/screens/menu_password.asm` | Password menu | [menu_password.md](modules/menu_password.md) |
| `0x003400` | `src/screens/menu_main.asm` | Main menu | [menu_main.md](modules/menu_main.md) |
| `0x004226` | `src/screens/message.asm` | On-screen messages / button prompts | [message.md](modules/message.md) |
| `0x005760` | `src/screens/rider_sprites.asm` | Rider/bike sprite chain builder | [rider_sprites.md](modules/rider_sprites.md) |
| `0x0059C4` | `src/screens/rider_intro.asm` | Pre-race rider/opponent intro | [rider_intro.md](modules/rider_intro.md) |
| `0x005F28` | `src/screens/race_results.asm` | Post-race results / bust / repair | [race_results.md](modules/race_results.md) |
| `0x006DC0` | `src/screens/highscore.asm` | High-score screen | [highscore.md](modules/highscore.md) |
| `0x0074AA` | `src/screens/shop.asm` | Bike shop | [shop.md](modules/shop.md) |
| `0x008342` | `src/screens/endlevel.asm` | Level-complete animation / level-up | [endlevel.md](modules/endlevel.md) |
| `0x008FB4` | `src/race/road_render.asm` | Road/object renderer (partial) | [road_render.md](modules/road_render.md) |
| `0x0098C2` | `src/race/race_hud_debug.asm` | HUD digit writers / debug overlay | [race_hud_debug.md](modules/race_hud_debug.md) |
| `0x009B9E` | `src/core/uncompress.asm` | LZSS decompressors (B/W/stream/VRAM) | [uncompress.md](modules/uncompress.md) |
| `0x009FE4` | `src/race/track_data.asm` | Track/road data decompressor | [track_data.md](modules/track_data.md) |
| `0x00A4E2` | `src/race/race.asm` | Include list (split main gameplay) | [race.md](modules/race.md) |
| `0x00A4E2` | `src/race/race_core.asm` | Race top-level/init/results/actor data | [race_core.md](modules/race_core.md) |
| `0x00D278` | `src/race/race_hud.asm` | Race HUD | [race_hud.md](modules/race_hud.md) |
| `0x00D8FA` | `src/race/race_physics.asm` | DmaWriteVRAM + actor/physics/AI | [race_physics.md](modules/race_physics.md) |
| `0x00E732` | `src/race/road_marking.asm` | Road marking / sprite placement | [road_marking.md](modules/road_marking.md) |
| `0x00EB34` | `src/race/race_ai_road.asm` | Road profile/objects/standings/speed | [race_ai_road.md](modules/race_ai_road.md) |
| `0x010E00` | `src/race/race_ai.asm` | Actor/input/AI/physics | [race_ai.md](modules/race_ai.md) |
| `0x014056` | `src/race/race_anim_audio.asm` | Animations, random, engine audio | [race_anim_audio.md](modules/race_anim_audio.md) |
| `0x016860` | `src/race/animation.asm` | Sprite animation | [animation.md](modules/animation.md) |
| `0x0169B0` | `src/race/race_spawn.asm` | Track data + dynamic spawn | [race_spawn.md](modules/race_spawn.md) |
| `0x016E70` | `src/screens/rider_intro_quotes.asm` | Rider-intro quote records (ROM gap) | [rider_intro.md](modules/rider_intro.md) |
| `0x019A12` | `src/data/race_data_tables.asm` | Intro/results/level tables (ROM gap) | [race_data_tables.md](modules/race_data_tables.md) |
| `0x0257D0` | `src/data/race_engine_tables.asm` | Physics/engine/audio tables (ROM gap) | [race_data_tables.md](modules/race_data_tables.md) |
| `0x019F62` | raw bridge | 68k audio interface / Z80 driver / sound data | [audio.md](modules/audio.md) |
| `0x0259B6` | `src/data/race_actor_extra_tables.asm` | Actor/AI tables (ROM gap) | [race_data_tables.md](modules/race_data_tables.md) |
| `0x025EC0` | `src/data/race_track_data.asm` | Per-track records/streams (ROM gap) | [race_track_data.md](modules/race_track_data.md) |
| `0x03BF1A` | `src/data/road_shapes.asm` | Road/object shape table/data (ROM gap) | [road_shapes.md](modules/road_shapes.md) |
| `0x07DCA8` | `src/data/race_misc_data.asm` | HUD/palette/results tables (ROM gap) | [race_misc_data.md](modules/race_misc_data.md) |
| `0x07E6A2` | `src/core/top_level.asm` | Top-level screen flow (intro/menu/race/results) | [top_level.md](modules/top_level.md) |
| `0x07EA66` | `src/data/rom_assets.asm` | Labelled ROM asset/code tail | [rom_assets.md](modules/rom_assets.md) |

Helpers/data without code in the image: `src/core/hw_const.asm` (constants/macros),
`src/core/unknown.asm` (address equates), `src/core/ram_const.asm` (RAM equates),
`src/data/race_actor_tables.asm`, `src/data/race_data_tables.asm`, `src/data/race_engine_tables.asm`,
`src/screens/rider_intro_quotes.asm`, `src/data/race_actor_extra_tables.asm`, `src/data/race_track_data.asm`,
`src/data/road_shapes.asm`, `src/data/race_misc_data.asm`, `src/data/rom_assets.asm`.

## RAM overview

RAM equates live in `src/core/ram_const.asm` (`$FF0000`–`$FFFFFF`). Names are grouped by
subsystem prefixes:

- `Fade_ram_*`, `Intro_ram_*`, `Menu_ram_*`, `MenuPassword_ram_*`,
  `Character_ram_*`, `Race_ram_*`, `RaceResults_ram_*`, `HighScore_ram_*`,
  `Shop_ram_*`, `EndLevel_ram_*`, `RoadMarking_ram_*`, `Animation_ram_*`.
- `ram_XXXXXX` entries are not yet renamed.

TODO: document major RAM structures (player state, race state, sprite tables,
VDP buffers, input state) with sizes and layouts.

## Data / asset notes

- The EA logo is generated as `assets/images/ea_logo/data.bin` (ROM `0xCFE`, `0x3D6`)
  by `tools/assets.py`; `src/logoEA/logoEA.asm` includes it via `binclude`.
- `tools/extract.py` (Python 3 + Pillow) helps extract/decompress graphics from the
  ROM.

## TODO

- Fill in boot/start flow and top-level state machine (`doStart`).
- Describe interrupts (what each does per frame).
- Fill per-module cards, starting with `src/main.asm` and `src/race/race.asm`.
- Document RAM structures and cross-module contracts.

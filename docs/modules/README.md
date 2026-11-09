# Module cards

One card per source module, based on [`_template.md`](_template.md).
See [`../architecture.md`](../architecture.md) for the ROM map and include order.

To add a card: copy `_template.md` to `<file>.md`, fill in what is verified, and add a
row to the table below.

| File | Address | Role (tentative) | Card |
|------|---------|------------------|------|
| `src/main.asm` | `0x000000` (entry `RESET` `0x000200`) | Vectors, header, boot, interrupts | [main.md](main.md) |
| `src/logoEA/logoEA.asm` | `0x000366` | EA logo, decompression, drawing | [logoEA.md](logoEA.md) |
| `src/core/fade.asm` | `0x001180` | Palette fade in/out | [fade.md](fade.md) |
| `src/screens/intro.asm` | `0x001704` | Intro sequence | [intro.md](intro.md) |
| `src/screens/menu_password.asm` | `0x002446` | Password menu | [menu_password.md](menu_password.md) |
| `src/screens/menu_main.asm` | `0x003400` | Main menu | [menu_main.md](menu_main.md) |
| `src/screens/message.asm` | `0x004226` | On-screen messages / button prompts | [message.md](message.md) |
| `src/screens/rider_sprites.asm` | `0x005760` | Rider/bike sprite chain builder | [rider_sprites.md](rider_sprites.md) |
| `src/screens/rider_intro.asm` | `0x0059C4` | Pre-race rider/opponent intro | [rider_intro.md](rider_intro.md) |
| `src/screens/race_results.asm` | `0x005F28` | Post-race results / bust / repair | [race_results.md](race_results.md) |
| `src/screens/rider_intro_quotes.asm` | `0x016E70` | Rider-intro quote records (ROM gap) | [rider_intro.md](rider_intro.md) |
| `src/screens/highscore.asm` | `0x006DC0` | High-score screen | [highscore.md](highscore.md) |
| `src/screens/shop.asm` | `0x0074AA` | Bike shop | [shop.md](shop.md) |
| `src/screens/endlevel.asm` | `0x008342` | Level-complete animation / level-up | [endlevel.md](endlevel.md) |
| `src/race/road_render.asm` | `0x008FB4` | Road/object renderer (partial) | [road_render.md](road_render.md) |
| `src/race/race_hud_debug.asm` | `0x0098C2` | HUD digit writers / debug overlay | [race_hud_debug.md](race_hud_debug.md) |
| `src/core/uncompress.asm` | `0x009B9E` | LZSS decompressors (B/W/stream/VRAM) | [uncompress.md](uncompress.md) |
| `src/race/track_data.asm` | `0x009FE4` | Track/road data decompressor | [track_data.md](track_data.md) |
| `src/race/race.asm` | `0x00A4E2` | Include list (split main gameplay) | [race.md](race.md) |
| `src/race/race_core.asm` | `0x00A4E2` | Race top-level/init/results/actor data | [race_core.md](race_core.md) |
| `src/race/race_hud.asm` | `0x00D278` | Race HUD | [race_hud.md](race_hud.md) |
| `src/race/race_physics.asm` | `0x00D8FA` | DmaWriteVRAM + actor/physics/AI | [race_physics.md](race_physics.md) |
| `src/race/road_marking.asm` | `0x00E732` | Road marking / sprite placement | [road_marking.md](road_marking.md) |
| `src/race/race_ai_road.asm` | `0x00EB34` | Road profile/objects/standings/speed | [race_ai_road.md](race_ai_road.md) |
| `src/race/race_ai.asm` | `0x010E00` | Actor/input/AI/physics | [race_ai.md](race_ai.md) |
| combat subsystem | `0x0161...` | Fist/AI attack/collision state | [combat.md](combat.md) |
| `src/race/race_anim_audio.asm` | `0x014056` | Animations, random, engine audio | [race_anim_audio.md](race_anim_audio.md) |
| `src/race/animation.asm` | `0x016860` | Sprite animation | [animation.md](animation.md) |
| `src/race/race_spawn.asm` | `0x0169B0` | Track data + dynamic spawn | [race_spawn.md](race_spawn.md) |
| `src/data/race_data_tables.asm` | `0x019A12` | Intro/results/level tables (ROM gap) | [race_data_tables.md](race_data_tables.md) |
| `src/data/race_engine_tables.asm` | `0x0257D0` | Physics/engine/audio tables (ROM gap) | [race_data_tables.md](race_data_tables.md) |
| `src/data/race_actor_extra_tables.asm` | `0x0259B6` | Actor/AI tables (ROM gap) | [race_data_tables.md](race_data_tables.md) |
| `src/data/race_track_data.asm` | `0x025EC0` | Per-track records/streams (ROM gap) | [race_track_data.md](race_track_data.md) |
| `src/data/road_shapes.asm` | `0x03BF1A` | Road/object shape table/data (ROM gap) | [road_shapes.md](road_shapes.md) |
| `src/data/race_misc_data.asm` | `0x07DCA8` | HUD/palette/results tables (ROM gap) | [race_misc_data.md](race_misc_data.md) |
| `src/data/rom_assets.asm` | `0x07EA66` | Labelled asset/code tail | [rom_assets.md](rom_assets.md) |
| `src/core/top_level.asm` | `0x07E6A2` | Top-level screen flow (intro/menu/race/results) | [top_level.md](top_level.md) |
| audio raw bridge | `0x019F62` | 68k audio interface / Z80 driver / sound data | [audio.md](audio.md) |

Helper/data files without code: `src/core/hw_const.asm`, `src/core/unknown.asm`, `src/core/ram_const.asm`,
`src/data/race_actor_tables.asm`, `src/screens/rider_intro_quotes.asm`, `src/data/race_data_tables.asm`,
`src/data/race_engine_tables.asm`, `src/data/race_actor_extra_tables.asm`, `src/data/race_track_data.asm`,
`src/data/road_shapes.asm`, `src/data/race_misc_data.asm`, `src/data/rom_assets.asm`.

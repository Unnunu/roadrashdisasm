# Module cards

One card per source module, based on [`_template.md`](_template.md).
See [`../architecture.md`](../architecture.md) for the ROM map and include order.

To add a card: copy `_template.md` to `<file>.md`, fill in what is verified, and add a
row to the table below.

| File | Address | Role (tentative) | Card |
|------|---------|------------------|------|
| `main.asm` | `0x000000` (entry `RESET` `0x000200`) | Vectors, header, boot, interrupts | [main.md](main.md) |
| `logoEA.asm` | `0x000366` | EA logo, decompression, drawing | [logoEA.md](logoEA.md) |
| `fade.asm` | `0x001180` | Palette fade in/out | [fade.md](fade.md) |
| `intro.asm` | `0x001704` | Intro sequence | [intro.md](intro.md) |
| `menu_password.asm` | `0x002446` | Password menu | [menu_password.md](menu_password.md) |
| `menu_main.asm` | `0x003400` | Main menu | [menu_main.md](menu_main.md) |
| `message.asm` | `0x004226` | On-screen messages / button prompts | [message.md](message.md) |
| `rider_sprites.asm` | `0x005760` | Rider/bike sprite chain builder | [rider_sprites.md](rider_sprites.md) |
| `rider_intro.asm` | `0x0059C4` | Pre-race rider/opponent intro | [rider_intro.md](rider_intro.md) |
| `race_results.asm` | `0x005F28` | Post-race results / bust / repair | [race_results.md](race_results.md) |
| `highscore.asm` | `0x006DC0` | High-score screen | [highscore.md](highscore.md) |
| `shop.asm` | `0x0074AA` | Bike shop | [shop.md](shop.md) |
| `endlevel.asm` | `0x008342` | Level-complete animation / level-up | [endlevel.md](endlevel.md) |
| `road_render.asm` | `0x008FB4` | Road/object renderer (partial) | [road_render.md](road_render.md) |
| `race_hud_debug.asm` | `0x0098C2` | HUD digit writers / debug overlay | [race_hud_debug.md](race_hud_debug.md) |
| `uncompress.asm` | `0x009B9E` | LZSS decompressors (B/W/stream/VRAM) | [uncompress.md](uncompress.md) |
| `track_data.asm` | `0x009FE4` | Track/road data decompressor | [track_data.md](track_data.md) |
| `race.asm` | `0x00A4E2` | Include list (split main gameplay) | [race.md](race.md) |
| `race_core.asm` | `0x00A4E2` | Race top-level/init/results/actor data | [race_core.md](race_core.md) |
| `race_hud.asm` | `0x00D278` | Race HUD | [race_hud.md](race_hud.md) |
| `race_physics.asm` | `0x00D8FA` | DmaWriteVRAM + actor/physics/AI | [race_physics.md](race_physics.md) |
| `road_marking.asm` | `0x00E732` | Road marking / sprite placement | [road_marking.md](road_marking.md) |
| `race_ai_road.asm` | `0x00EB34` | Road profile/objects/standings/speed | [race_ai_road.md](race_ai_road.md) |
| `race_ai.asm` | `0x010E00` | Actor/input/AI/physics | [race_ai.md](race_ai.md) |
| `race_anim_audio.asm` | `0x014056` | Animations, random, engine audio | [race_anim_audio.md](race_anim_audio.md) |
| `animation.asm` | `0x016860` | Sprite animation | [animation.md](animation.md) |
| `race_spawn.asm` | `0x0169B0` | Track data + dynamic spawn | [race_spawn.md](race_spawn.md) |
| `race_data_tables.asm` | `0x019A12` | Intro/results/level tables (ROM gap) | [race_data_tables.md](race_data_tables.md) |
| `race_engine_tables.asm` | `0x0257D0` | Physics/engine/audio tables (ROM gap) | [race_data_tables.md](race_data_tables.md) |
| `race_actor_extra_tables.asm` | `0x0259B6` | Actor/AI tables (ROM gap) | [race_data_tables.md](race_data_tables.md) |
| `race_track_data.asm` | `0x025EC0` | Per-track records/streams (ROM gap) | [race_track_data.md](race_track_data.md) |
| `top_level.asm` | `0x07E6A2` | Top-level screen flow (intro/menu/race/results) | [top_level.md](top_level.md) |

Helper/data files without code: `hw_const.asm`, `unknown.asm`, `ram_const.asm`,
`race_actor_tables.asm`, `race_data_tables.asm`, `race_engine_tables.asm`,
`race_actor_extra_tables.asm`, `race_track_data.asm`.

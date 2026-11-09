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
| `sub_5760.asm` | `0x005760` | Rider/bike sprite chain builder | [sub_5760.md](sub_5760.md) |
| `character.asm` | `0x0059C4` | Pre-race rider/opponent intro | [character.md](character.md) |
| `race_results.asm` | `0x005F28` | Post-race results / bust / repair | [race_results.md](race_results.md) |
| `highscore.asm` | `0x006DC0` | High-score screen | [highscore.md](highscore.md) |
| `shop.asm` | `0x0074AA` | Bike shop | [shop.md](shop.md) |
| `endlevel.asm` | `0x008342` | Level-complete animation / level-up | [endlevel.md](endlevel.md) |
| `8FB4.asm` | `0x008FB4` | Road/object renderer (partial) | [8FB4.md](8FB4.md) |
| `98C2.asm` | `0x0098C2` | Not yet identified | TODO |
| `uncompress.asm` | `0x009B9E` | Decompression routines | TODO |
| `9FE4.asm` | `0x009FE4` | Not yet identified | TODO |
| `race.asm` | `0x00A4E2` | Main gameplay | TODO |
| `race_hud.asm` | `0x00D278` | Race HUD (included by `race.asm`) | TODO |
| `road_marking.asm` | `0x00E732` | Road marking / sprite placement (included by `race.asm`) | TODO |
| `animation.asm` | `0x016860` | Sprite animation (included by `race.asm`) | TODO |
| `top_level.asm` | `0x07E6A2` | Top-level screen flow (intro/menu/race/results) | [top_level.md](top_level.md) |

Helper files without code in the image: `hw_const.asm`, `unknown.asm`, `ram_const.asm`.

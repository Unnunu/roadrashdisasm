# Module card: `src/screens/menu_main.asm`

- **ROM range:** `0x003400`–`0x004225`
- **Status:** analyzed (all functions line-by-line; exact card layout/demo visual TODO)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/menu_main.md`

## Role / purpose
Main menu: background/gamepad/race-selection graphics, player A/B/two-player selection,
race/track selection, music toggle, demo timer, tooltips, and the entry point to the
password screen (C) and to the race (Start release).

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Menu_Init` | `0x3400` | top-level flow | VDP setup, assets, frame buffer, initial draws, music; does not install the update (caller sets `MainMenu_GameTick`). |
| `MainMenu_GameTick` | `0x3802` | `ram_UpdateFunction` | Per-frame DMA of the previous buffer, input edges, Start release, demo timeout, tooltips/PRNG ticks. |
| `MainMenu_HandleInput` | `0x3BE2` | GameTick | Player mode/music/track/password selection. |
| `WriteNametableToBuffer` | `0x37AA` | this module | Copy a nametable rectangle into a RAM buffer with a caller-supplied stride. |
| `Menu_WriteNametableMasked` | `0x37D2` | race cards | Same, but only where the destination word equals the `d5` sentinel (equality, not a bitwise mask). |
| `Menu_DrawPlayerInfo` | `0x39AE` | init/input | Player A/B name + level + selection border. |
| `Menu_DrawRaceSelection` | `0x3F18` | init/input | Race badge + five race cards. |
| `Menu_DrawRaceCard` | `0x408E` | race selection | Card tilemap + place text, masked write. |
Full list: the related analysis page.

## External calls / dependencies
- `UncompressW`/`UncompressB`, `WriteTilesetToVRAM`, `DmaWriteVRAM`,
  `EncodeString`/`WriteNametable`, `WriteNametableToBuffer`, `Menu_ShowMessage`,
  `Menu_DrawRaceSelection`, `Menu_DrawPlayerInfo`, `MenuPassword_SelectCurrentTrack`, `MenuPassword_GameTick`,
  `Fade_ram_UpdateFunction`, `Audio_Update/3/4`, `Rand_NextWord`, `Rand_StepLfsrAMod`/`Rand_StepLfsrB`.

## Hacks / bugs / quirks
- Planes A/B share `$4000`; the window `$7000` overlays the text; the password screen
  writes `$7200`.
- Sprite table and H-scroll table overlap at `$6000`; the 16-byte clear is used to
  zero both. Sprites are unused here.
- The race cards are masked writes (only black/default tiles replaced).
- Start exits on **release**; the demo timer is 30 s. `GetInputPlayerA/B` define only
  `d0.b`, but `DmaWriteVRAM` leaves `d0 < $100`, so the word stores/tests are safe.
- The tooltip timer uses `bpl`, so it advances after 241 decrements (~4.02 s), not exactly
  240; the `beq .end` after the index-6 wrap is redundant.
Full list: the related analysis page.

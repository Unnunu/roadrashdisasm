# Module card: `src/screens/rider_intro.asm`

- **ROM range:** `0x0059C4`–`0x005F27` (`RiderIntro_Init` `0x59C4`,
  `RiderIntro_GameTick` `0x5E66`)
- **Status:** line-by-line analyzed (static; rendering not yet dynamically confirmed)
- **Related:** `docs/architecture.md`, `docs/reverse-engineering.md`,
  `docs/hardware.md`, `docs/ram-map.md`, `docs/analysis/rider_intro.md`

## Role / purpose
Pre-race **rider/opponent introduction**. After the main menu (non-demo path only) the
screen shows the rider you will race next: portrait, name, taunt/quote, a background
and gamepad, and a timed message. A button press (or the message sequence ending) exits
to the race and records the controller in `Race_ram_ActiveController`.

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `RiderIntro_Init` | `0x59C4` | `src/core/top_level.asm` `0x7E78C` | Build the screen. |
| `RiderIntro_GameTick` | `0x5E66` | `src/core/top_level.asm` `0x7E790` (fade wrapper) | Per-frame update/input. |
`src/core/top_level.asm` skips the screen when `MainMenu_ram_DemoMode != 0` (`0x7E782`).

## External calls / dependencies
- Callers: `src/core/top_level.asm`.
- Uses `UncompressW/B`, `WriteTilesetToVRAM`, `WriteNametable(ToBuffer)`, `EncodeString`,
  `Menu_ShowMessage`, `DmaWriteVRAM`, `Rand_NextWord`, `GetInputPlayerA/B`,
  `Audio_Update/4`.

## Hacks / bugs / quirks
- Background tiles are written to VRAM `$4000` but the map uses base tile `$400`
  (`$8000`); the visible background relies on the main menu's tiles at `$8000`. The
  `$4000` write is overwritten by the nametable. `[static]`
- Quote rows are double-spaced by using destination stride 128 (rows 3,5,7,9); the
  destination Y is the header Y shifted right by one. `[static]`
- Variant 3 is not chosen randomly; it replaces variant 0 only when the player's
  Natasha encounter counter is non-zero. `[static]`
- The 10-character name is centered by counting trailing minus leading spaces,
  halving the surplus and right-rotating the field. `[static]`
- The portrait palette overwrites all 64 global palette words. `[static]`

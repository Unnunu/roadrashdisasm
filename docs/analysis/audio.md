# Analysis: audio subsystem (68k interface, Z80 driver, sound data)

- **ROM range:** `0x019F62`–`0x0257CF` (currently a raw bridge in `src/main.asm`)
- **Status:** `AudioFunc1..14` renamed/analyzed; `AudioFunc15..18` retained (partial);
  Z80 driver/sound-data formats pending
- **Related:** `docs/modules/audio.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/main.md`, `docs/analysis/race_anim_audio.md`

## ROM map

| Range | Contents |
|---|---|
| `$19F62-$19FA9` | 18 `bra.w` stubs: `Audio_Update`..`AudioFunc18`. |
| `$19FAA-$1A6C3` | 68k audio engine/interface (`Audio_Init`, `Audio_StartMusic`, `Audio_StopMusic`, helpers). |
| `$1A6C4-$1B159` | `Audio_PlaySfx` SFX dispatcher + jump table + supporting code. |
| `$1B15A-$1B2A9` | 12-entry song table (stride `$1C`), pointers relative to `Audio_Update`. |
| `$1B2AA-$1D9C1` | Song sequence data; SFX handlers (`$1B1C4-$1B3E2`) are interleaved code. |
| `$1D9C2-$1DA11` | Z80 loader: copies `$BBB` bytes from `$1DA12` to `$A00000`. |
| `$1DA12-$1E5CC` | Z80 sound driver (`$BBB` bytes). |
| `$1E5CD-$257CF` | Sound data (`$7203` bytes; format TODO). |
| `$257D0` | Engine/audio timing tables (`src/data/race_engine_tables.asm`). |

`AudioFunc1..18` targets (renamed where confirmed):

| Function | Stub | Target | Role |
|---|---|---|---|
| `Audio_Update` | `$19F62` | `$1A5AA` | Per-frame tick: flush command buffer, Z80 mailbox handshake. |
| `Audio_Init` | `$19F66` | `$19FAA` | Audio init: clear `$FF0000-$FF021E`, reset/load Z80 driver. |
| `Audio_StartMusic` | `$19F6A` | `$1A122` | Start song (`d0` = song id 0..11). |
| `Audio_StopMusic` | `$19F6E` | `$1A1FA` | Request stop/pause; processed by `Audio_Update`. |
| `Audio_PlaySfx` | `$19F72` | `$1A6C4` | SFX dispatcher: `d0` 0..18 -> jump table `$1A6D6`. |
| `Audio_Engine1Start` | `$19F76` | `$19FD2` | Engine channel 1 start: `$FF0208 = 1` (or 3 when inactive). |
| `Audio_Engine1Stop` | `$19F7A` | `$19FE6` | Engine channel 1 stop: `$FF0208 = 3`. |
| `Audio_Engine1Update` | `$19F7E` | `$19FF0` | Engine channel 1 update: `d0 -> $FF0204`, `d1 -> $FF0209`. |
| `Audio_Engine2Start` | `$19F82` | `$1A036` | Engine channel 2 start: `$FF020E = 1/3`. |
| `Audio_Engine2Stop` | `$19F86` | `$1A04A` | Engine channel 2 stop: `$FF020E = 3`. |
| `Audio_Engine2Update` | `$19F8A` | `$1A054` | Engine channel 2 update: `$FF020A/$FF020F`. |
| `Audio_Engine3Start` | `$19F8E` | `$1A09A` | Engine channel 3 start: `$FF0214 = 1/3`. |
| `Audio_Engine3Stop` | `$19F92` | `$1A0AE` | Engine channel 3 stop: `$FF0214 = 3`. |
| `Audio_Engine3Update` | `$19F96` | `$1A0B8` | Engine channel 3 update: `$FF0210/$FF0215`. |
| `AudioFunc15` | `$19F9A` | `$1A0FE` | Stop music channel state `$FF011C = 3`. |
| `AudioFunc16` | `$19F9E` | `$1A108` | Set `$FF021B = d1` (distance-derived parameter). |
| `AudioFunc17` | `$19FA2` | `$1A110` | Stop music channel state `$FF0164 = 3`; clear `$FF021D`. |
| `AudioFunc18` | `$19FA6` | `$1A1E6` | Resume/continue audio unless `$FF01F4 == 1`; sets `$FF0000 = $FF`. |

Evidence `[static]` from the 68k disassembly and call sites in `src/main.asm`,
`src/race/race_core.asm`, `src/race/race_anim_audio.asm`, and the UI screens.
`Audio_StopMusic` is evidenced by the stop-before-start call sites; `AudioFunc15..18`
stay numeric because their exact roles are partly `[hypothesis]` pending dynamic checks.

## 68k audio state (`$FF0000`)

`Audio_Init` clears `$21F` bytes at `$FFFF0000`. The engine treats it as:

| Range | Meaning |
|---|---|
| `$FF0000` | Audio active/enable byte (`$FF` after init/resume). |
| `$FF0006 + n*$48` | Six channel slots (`n=0..5`), each `$48` bytes. |
| `+$00/+$02/+$04` | Sequence/current-note state. |
| `+$08/+$0C` | Sequence read/current pointers. |
| `+$10` | Delay/counter. |
| `+$18` | Second pointer (engine). |
| `+$24/+$26` | Current note/duration. |
| `+$28/+$2C` | Callback/loop pointers. |
| `+$3C/$3D/$3E` | Channel state (stop modes use `3`). |
| `+$41` | Initial/volume byte (`$FF`). |
| `+$44` | Pointer/parameter field. |
| `$FF01B6` | Current song id (written by `Audio_StartMusic`). |
| `$FF01BE` | Six 8-byte command slots copied to Z80 `$A00256`. |
| `$FF01EE` | Five special bytes copied to Z80 `$A000BB..BF`. |
| `$FF01F0/$1F3/$1F4/$1F8` | Special-command/tick/resume flags. |
| `$FF01FC/$1FD/$1FE` | Stop/resume/start requests processed by `Audio_Update`. |
| `$FF0202` | Command-ready/processed flag. |
| `$FF0204/$0208/$0209` | Engine ch.1 parameter/command/volume. |
| `$FF020A/$020E/$020F` | Engine ch.2 parameter/command/volume. |
| `$FF0210/$0214/$0215` | Engine ch.3 parameter/command/volume. |
| `$FF021B/$021D` | Distance-derived parameter / special channel stop. |

## Z80 mailbox / loader

- `Audio_Init` resets the Z80 and calls `$1D9C2`.
- `$1D9C2` requests bus (`$0100 -> $A11100`), copies `$BBB` bytes from `$1DA12`
  to `$A00000`, releases reset, waits `$1F4` dbf loops, then releases bus.
- `Audio_Update` requests bus, copies the `0x30`-byte command block to `$A00256`
  (unless the ready byte is `1`), copies five bytes to `$A000BB..BF` when
  `$FF01F3` is set, writes `$A00286`, and releases bus.
- The 68k sequence engine also reads tables inside the Z80 driver binary:
  opcode `$80` uses `$1DA12 + $288 + (d0<<5)` (instrument/channel data).

## Songs / SFX

`Audio_StartMusic` uses a 12-entry table at `$1B15A`, stride `$1C`; the dword at `+4`
is a sequence pointer relative to `Audio_Update` (`$1A5AA`):

| Song | Pointer | First bytes |
|---|---|---|
| 0 | `$1B8D6` | `05 07 06 00` |
| 1 | `$1C8FA` | `05 06 05 00` |
| 2 | `$1C9F4` | `02 06 05 00` |
| 3 | `$1CB74` | `02 07 06 00` |
| 4 | `$1C51C` | `02 06 05 00` |
| 5 | `$1C4A6` | `02 06 05 00` |
| 6 | `$1BE12` | `02 05 04 00` |
| 7 | `$1BCE0` | `02 05 04 00` |
| 8 | `$1BA66` | `01 05 04 00` |
| 9 | `$1BA98` | `04 05 04 00` |
| 10 | `$1B8DC` | `05 07 06 00` |
| 11 | `$1CBE5` | `26 3B 13 8A` (first bytes look more like sequence data; verify) |

Used IDs: `1` (intro/menu/shop/highscore), `9` (results/endlevel), `10` (busted),
race tracks `2,3,7,5,4` (`Race_dTrackSongs`). The first table bytes are likely
channel counts/tempo; exact field meaning is TODO.

`Audio_PlaySfx` jump table at `$1A6D6` has 19 entries (IDs 0..18) with targets:

`0->$1B370, 1->$1B37E, 2->$1B3C6, 3->$1B38C, 4->$1B39A, 5->$1B3A8,
6->$1B3D4, 7->$1B3E2, 8->$1B362, 9->$1B1EE, 10->$1B1FC, 11->$1B20A,
12->$1B39A, 13->$1B22A, 14->$1B1E0, 15/16->$1B21A, 17->$1B24A, 18->$1B1C4`.

Callers use IDs `1`, `2`, `5` for engine/skid/near-player state; exact ID names
remain TODO.

## Open questions

- Z80 driver disassembly (needs a Z80 disassembler) and command/IRQ protocol.
- Sound-data format and song/instrument extraction (`$1E5CD-$257CF`).
- Exact `Audio_StopMusic/15/16/17/18` semantics; dynamic checks with BlastEm.
- Code/data split inside `$1A6C4-$1D9C1` (SFX handlers are interleaved with data).

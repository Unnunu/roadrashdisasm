# Module card: audio subsystem

- **ROM range:** `0x019F62`–`0x0257CF` (raw bridge in `src/main.asm`)
- **Status:** `AudioFunc1..14` renamed/analyzed; `AudioFunc15..18` partial;
  Z80 driver/sound-data extraction next
- **Related:** `docs/analysis/audio.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/main.md`, `docs/analysis/race_anim_audio.md`

## Role / purpose

The 68k side of the sound engine: per-frame command flush, song start/stop, SFX
dispatching, three engine-sound channels, and the Z80 mailbox handshake. The actual
FM/PSG playback runs in the Z80 driver loaded from `$1DA12` (`$BBB` bytes).

## Coverage matrix

| Function | Address | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|---|---|---|---|---|---|---|---|---|
| `Audio_Update` | `0x19F62`/`0x1A5AA` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Audio_Init` | `0x19F66`/`0x19FAA` | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `Audio_StartMusic` | `0x19F6A`/`0x1A122` | [x] | [~] | [x] | [x] | [x] | [ ] | partial |
| `Audio_StopMusic` | `0x19F6E`/`0x1A1FA` | [x] | [~] | [x] | [x] | [x] | [ ] | partial |
| `Audio_PlaySfx` | `0x19F72`/`0x1A6C4` | [x] | [x] | [x] | [x] | [x] | [ ] | partial |
| `Audio_Engine1Start..Audio_Engine3Update` | `0x19F76`+ | [x] | [x] | [x] | [x] | [x] | [ ] | analyzed |
| `AudioFunc15..18` | `0x19F9A`+ | [x] | [~] | [x] | [x] | [~] | [ ] | partial |
| Z80 driver | `0x1DA12` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |
| Sound data | `0x1E5CD` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | TODO |

Detailed analysis: `docs/analysis/audio.md`.

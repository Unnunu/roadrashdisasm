# Module card: `src/screens/message.asm`

- **ROM range:** `0x004226`–`0x00575F`
- **Status:** analyzed (static; icon layout/cadence not verified in BlastEm)
- **Related:** `docs/architecture.md`, `docs/coding-style.md`,
  `docs/reverse-engineering.md`, `docs/hardware.md`, `docs/ram-map.md`,
  `docs/analysis/message.md`

## Role / purpose
Bottom-screen tooltip/message system: clears/fills the 40x6 message field, blinks
controller-button prompts (A/B/C/Start/directional pad), and supplies the message array
(text + show function) used by the main menu, password, rider-intro, race-results,
high-score, end-level and shop screens. It also holds shared strings/tables (race names,
demo high score, password labels/status, shop descriptions, busted/repair messages).

## Entry points & API
| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `Message_ShowEmpty` | `0x4226` | `Menu_ShowMessage` | Fill the message field with space tiles. |
| `Message_ShowNoop` | `0x4268` | `Message_MsgArray` | No-op show function (also the rts ending `Message_ShowEmpty`). |
| `Message_Clear` | `0x426A` | blink functions, `Menu_ShowMessage` | Fill the field with the default/black tile. |
| `Message_BlinkButtonA/B/AB/C/Start` | `0x42AA`… | `Menu_ShowMessage` | Blink and draw the corresponding gamepad button tiles. |
| `Message_DrawButtonA/B` | `0x42D0`/`0x432A` | blink functions | Draw-only icon entries. |
| `Message_BlinkDirPadHorizontal` / `Message_BlinkDirPadVertical` | `0x445E`/`0x44D6` | `Menu_ShowMessage` | Blink the horizontal (left/right) or vertical (up/down) dpad pair; ids 61/62 use the horizontal pair for the shop left/right prompts. |
| `Message_DrawDirPadHorizontalIcon` / `...VerticalIcon` | `0x4486`/`0x44FE` | `Message_BlinkDirectionalPad` | Draw-only dpad parts. |
| `Message_BlinkDirectionalPad` | `0x454E` | `Menu_ShowMessage` | Blink and draw the complete dpad icon. |
Full list: the related analysis page.

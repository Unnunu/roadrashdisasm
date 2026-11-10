# Screen flow and visual-state map

Scope: boot -> logo -> intro -> menu -> rider intro -> race -> results/shop/endlevel/
highscore. Audio is excluded (separate workstream).

## Top-level state machine

`src/core/top_level.asm` drives screens through `ram_UpdateFunction` and `Fade_*`:

```
RESET/doStart
  -> TopLevel_Init
  -> Intro_Init -> Fade_InitFadeIn -> Intro_GameTick -> Fade_InitFadeOut
       Intro_ram_TextTimer >= 0 -> Menu_Init
       Intro_ram_TextTimer <  0 -> demo: MainMenu_ram_DemoMode=$FFFF -> HighScore
  -> Menu_Init -> MainMenu_GameTick -> Fade_InitFadeOut
       MainMenu_ram_DemoMode != 0 -> HighScore
       MainMenu_ram_DemoMode == 0 -> RiderIntro_Init
  -> RiderIntro_Init -> RiderIntro_GameTick -> Fade_InitFadeOut
       MainMenu_ram_DemoMode == 0 -> Race_Init
       MainMenu_ram_DemoMode != 0 -> HighScore
  -> HighScore_Init -> HighScore_GameTick_Demo -> Fade_InitFadeOut
       MainMenu_ram_DemoMode == 0 -> Menu
       MainMenu_ram_DemoMode != 0 -> Race
  -> Race_Init -> Race_GameTick
       GameEnded + demo -> fade -> Menu
       GameEnded + normal -> RaceResults dispatcher
  -> RaceResults/HighScore/Shop/EndLevel selected by RaceResults_ram_NextFunction
```

`Menu_ram_PlayerMode` is toggled with `eori.w #3` after the results dispatcher, then
the flow returns to the menu. Fade transitions always install `Fade_GameTick` or
`FadeWithFunction_GameTick` and wait for `ram_UpdateFunction == 0` before continuing.

## Screen inventory

| Screen | Init / tick | VDP / assets | Inputs / exit | Dynamic evidence |
|---|---|---|---|---|
| Logo | `LogoEA_Init`/`LogoEA_GameTick` | planes A/B `$A000`, shared nametable, H-scroll trick, sprite shapes | automatic; jumps to intro | previous BlastEm `vr`/plane inspection in `logoEA.md` |
| Intro | `Intro_Init` `$1704` / `Intro_GameTick` `$1C64` | plane A `$4000`, B `$2000`, sprites `$6000`, H-scroll `$7000`; background/title/font | credits timer 180; Start press+release; exits to menu or demo highscore | `[dynamic]` timer/H-scroll already captured; demo flow |
| Main menu | `Menu_Init` `$3400` / `MainMenu_GameTick` `$3802` | planes A/B `$4000`, window `$7000`, sprites/H-scroll `$6000`; background, cards, gamepad, font | A player mode; B music; directions track; C password; Start exits; 1800-frame demo timeout | `[dynamic]` `Menu_Init` reached by forcing intro timer; static path |
| Password | `MenuPassword_*` | row 4+ of window at `$7200`; 64x24 frame buffer | D-pad/letter selection, A/B/C, exit on Start/B | static; sample password TODO |
| Message overlay | `Menu_ShowMessage` | window/frame buffer; gamepad tiles `$A000` | blink/timer driven | static; visual blink TODO |
| Rider intro | `RiderIntro_Init` `$59C4` / `$5E66` | menu background, portrait VRAM `$C000`, quote text | timed progression / Start | static; normal path needs input |
| Race | `Race_Init` `$A4E2` / `Race_GameTick` `$BA76` | race VDP/HUD/road configuration | pad + Start pause; end by progress/damage | `[dynamic]` demo flow and race snapshots |
| Results | `RaceResults_Init` `$5F28` / `$6A90` | menu VDP, title/panel/gamepad | A/B/C choices; outcome dispatch | static; non-demo only |
| Shop | `Shop_Init` `$74AA` / `$79F8` | menu VDP, bike tiles/planes/window | left/right/A/B; buy/exit | static; non-demo only |
| End level | `EndLevel_Init` `$8342` / `$8AEE` | own VDP config; background at `$1280` | outcome 4 path | static; non-demo only |
| High score | `HighScore_Init` `$6DC0` / `$72BA`/`$732E` | menu VDP, title/badge/gamepad | demo/normal variants | `[dynamic]` demo flow reaches `HighScore_Init` |

## Dynamic flow traces

- Demo boot: `TopLevel_Init -> Intro_Init -> HighScore_Init -> Race_Init`.
  Observed `MainMenu_ram_DemoMode=$FFFF`, player mode `1`; menu/rider intro are
  skipped by design.
- Forced normal entry: setting `Intro_ram_TextTimer=0` at the post-intro branch
  reaches `Menu_Init` (`DemoMode=0`). The menu then timed out into `DemoMode=1` and
  went to race; reaching `RiderIntro_Init` requires an actual Start release or a
  more precise input injection.
- Intro timer/scroll and race state were captured through GDB in the existing notes.

## VDP/visual invariants

- Menu-family screens share the main-menu plane/background; only window buffer and
  tile uploads differ.
- Logo and intro use unusual plane/H-scroll layouts; see `logoEA.md` and `intro.md`.
- Password and message screens are window overlays, not separate plane maps.
- Results/shop/endlevel are normal-path screens and have no demo capture yet.

## Gaps / next experiments

- Capture `RiderIntro_Init`, `RaceResults_Init`, `Shop_Init`, `EndLevel_Init` with
  injected normal-path inputs or RAM state.
- Confirm password sample, message blink, shop scroll band, endlevel layout and
  results panel with visual captures.
- Confirm logo plane rows `$7044/$7144/$710C/$7136`.
- Record VDP register/VRAM snapshots at each screen for regression comparison.
- Re-run `analysis/capture_screen_flow*.gdb` traces after screen changes.

## Evidence status

`[static]`: top-level flow, screen init/tick contracts, VDP setup and assets.
`[dynamic]`: demo boot flow, menu entry after forced intro timer, high score/race
entries, intro/race snapshots. Visual/non-demo captures remain TODO.

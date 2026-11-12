# Identifier map

Durable, cross-file assessment of how well each identifier's name matches its observed
uses. It exists so later analysis can decide whether a rename is worth doing.

- Rules and rubric: `docs/line-by-line-analysis.md` section 8.
- `Name quality`: `good` / `narrow` / `misleading` / `placeholder` / `wrong/unknown`.
- `Rename verdict`: `keep` / `rename-later` / `blocked-unknown`.
- `blocked-unknown` references an ID in `docs/analysis/unknowns.md`.
- Only `[confirmed]` evidence may justify a rename; renames are a separate task.
- The per-file summary lives in `docs/analysis/<file>.md`; this file is the source of
  truth.
- **Usage:** do not read the whole table during a normal pass. `grep -n '<identifier>'`
  here (or read the per-file summary) and read only the matching rows. Append new rows
  at the end; do not reorder existing rows.

| Identifier | Kind | Defined | Used in (file: role) | Name quality | Evidence | Rename verdict | Proposed | Confidence | Unknown ID |
|---|---|---|---|---|---|---|---|---|---|
| `Menu_Init` | routine | `menu_main.asm:47` (`$3400`) | menu_main: VDP/asset/frame-buffer init | good | `[static]` | keep | - | high | - |
| `WriteNametableToBuffer` | routine | `menu_main.asm:326` (`$37AA`) | menu_main: RAM nametable blit; shared by many screens | good | `[static]` | keep | - | high | - |
| `Menu_WriteNametableMasked` | routine | `menu_main.asm:374` (`$37D2`) | menu_main: sentinel-masked card blit | good | `[static]` | keep | - | high | - |
| `MainMenu_GameTick` | routine | `menu_main.asm:417` (`$3802`) | menu_main: per-frame callback via `ram_UpdateFunction` | good | `[static]` | keep | - | high | - |
| `Menu_DrawPlayerInfo` | routine | `menu_main.asm:536` (`$39AE`) | menu_main; menu_password: A/B border, name, level | good | `[static]` | keep | - | high | - |
| `Menu_BuildRaceTooltip` | routine | `menu_main.asm:682` (`$3B56`) | menu_main: race-name + distance tooltip (level word = 16-ft units) | good | `[static]` | keep | - | high | `U-0001` resolved |
| `MainMenu_HandleInput` | routine | `menu_main.asm:747` (`$3BE2`) | menu_main: newly pressed button actions | good | `[static]` | keep | - | high | - |
| `Menu_DrawRaceSelection` | routine | `menu_main.asm:932` (`$3F18`) | menu_main; menu_password: badge + five-card carousel (even-id divide is vestigial) | good | `[static]` | keep | - | high | `U-0003` resolved |
| `Menu_DrawRaceCard` | routine | `menu_main.asm:1051` (`$408E`) | menu_main: one card + place text | good | `[static]` | keep | - | high | - |
| `Menu_ShowMessage` | routine | `menu_main.asm:1127` (`$417C`) | menu_main and other screens: blinking tooltip | good | `[static]` | keep | - | high | - |
| `Audio_StartMusic` | routine | `core/audio` (`$19F6A`) | menu_main: start menu music | good | `[static]` | keep | - | high | - |
| `Audio_StopMusic` | routine | `core/audio` (`$19F6E`) | menu_main: stop music on toggle/exit | good | `[static]` | keep | - | high | - |
| `Audio_Update` | routine | `core/audio` (`$19F62`) | menu_main: flush command mailbox each tick | good | `[static]` | keep | - | high | - |
| `DmaWriteVRAM` | routine | `core/dma` (`$0D8FA`) | menu_main: frame buffer -> window `$7000` | good | `[static]` | keep | - | high | - |
| `EncodeString` | routine | `intro.asm` (`$2288`) | menu_main: text record -> font tile indices | good | `[static]` | keep | - | high | - |
| `GetInputPlayerA` | routine | `core/input` (`$10D4`) | menu_main: pad A state (low `d0.b`) | good | `[static]` | keep | - | high | - |
| `GetInputPlayerB` | routine | `core/input` (`$111C`) | menu_main: pad B state (low `d0.b`) | good | `[static]` | keep | - | high | - |
| `Intro_InitPlayerA` | routine | `intro.asm` (`$1A2C`) | menu_main: reset A profile when money < 0 | narrow | `[static]` | rename-later | `Player_InitA` | medium | - |
| `Intro_InitPlayerB` | routine | `intro.asm` (`$1B48`) | menu_main: reset B profile when money < 0 | narrow | `[static]` | rename-later | `Player_InitB` | medium | - |
| `MenuPassword_SelectCurrentTrack` | routine | `menu_password.asm` (`$2B2E`) | menu_main: pick first unplayed/worst finished track | good | `[static]` | keep | - | high | - |
| `MenuPassword_DrawNamesAndPasswords` | routine | `menu_password.asm` (`$3306`) | menu_main: draw name/password fields | good | `[static]` | keep | - | high | - |
| `MenuPassword_GameTick` | routine | `menu_password.asm` (`$24CC`) | menu_main: installed when C opens the password screen | good | `[static]` | keep | - | high | - |
| `FadeWithFunction_GameTick` | routine | `core/fade.asm` | menu_main: detect an in-progress fade | good | `[static]` | keep | - | high | - |
| `Message_Clear` | routine | `message.asm` (`$426A`) | menu_main: black-out an animated tooltip | good | `[static]` | keep | - | high | - |
| `Message_ShowEmpty` | routine | `message.asm` (`$4226`) | menu_main: blank the static message field | good | `[static]` | keep | - | high | - |
| `Rand_NextWord` | routine | `core/rand` (`$16034`) | menu_main: advance the main PRNG each tick | good | `[static]` | keep | - | high | - |
| `Rand_StepLfsrAMod` | routine | `core/rand` (`$160B0`) | menu_main: advance LFSR A (`d2=1`) | good | `[static]` | keep | - | high | - |
| `Rand_StepLfsrB` | routine | `core/rand` (`$160CC`) | menu_main: advance LFSR B | good | `[static]` | keep | - | high | - |
| `UncompressB` | routine | `core/uncompress` (`$09B9E`) | menu_main: byte-planar image blobs | good | `[static]` | keep | - | high | - |
| `UncompressW` | routine | `core/uncompress` (`$09C26`) | menu_main: word-planar image blobs | good | `[static]` | keep | - | high | - |
| `WriteNametable` | routine | `intro.asm` (`$2402`) | menu_main: VRAM nametable rectangles | good | `[static]` | keep | - | high | - |
| `WriteTilesetToVRAM` | routine | `core/vdp` (`$0AFF2`) | menu_main: upload decompressed tiles | good | `[static]` | keep | - | high | - |
| `Message_MsgArray` | data | `message.asm:468` | menu_main/menu_password/shop/highscore/race_results/endlevel: 8-byte text/show-function entries | good | `[static]` | keep | - | high | - |
| `Menu_dRaceNameTable` | data | `message.asm:607` | menu_main: five race-name text pointers | good | `[static]` | keep | - | high | - |
| `unk_25EC0` | data | `race_track_data.asm:17` | menu_main: five track-record pointers (level-word table at +$00) | placeholder | `[static]` | rename-later | `RaceTrack_dRecords` | medium | - |
| `Menu_dPasswordLabels` | data | `message.asm:726` | menu_main: "Name"/"Password" label record (7x12) | good | `[static]` | keep (renamed from `word_4EEE`) | - | high | - |
| `dStringCodeTable` | data | `intro.asm:793` | menu_main: ASCII -> font tile index table | good | `[static]` | keep | - | high | - |
| `img_MainMenu_Background` | asset | `rom_assets.asm` | menu_main: 39 tiles + 40x28 map (`+$4E4/+$4E8`) | good | `[static]` | keep | - | high | - |
| `img_MainMenu_RaceSelectionBackground` | asset | `rom_assets.asm` | menu_main: 23 tiles + 40x14 map (`+$2E4/+$2E8`) | good | `[static]` | keep | - | high | - |
| `img_PasswordMenu_PlayerSelection` | asset | `rom_assets.asm` | menu_main: 6-tile password border, map at `+$C8` | good | `[static]` | keep | - | high | - |
| `img_Gamepad` | asset | `rom_assets.asm` | menu_main: 90 tiles, header 12x9 at `+$B44`, map `+$B48`; all callers use 12x6, lower 3 rows unused | narrow | `[static]` | keep | - | medium | `U-0002` resolved |
| `img_mainMenu_PlayerSelection` | asset | `rom_assets.asm` | menu_main: 6-tile player border, map at `+$C8` | good | `[static]` | keep | - | high | - |
| `img_MainMenu_RaceBadges` | asset | `rom_assets.asm` | menu_main: 108 tiles + 12x12 map (`+$D84/+$D88`) | good | `[static]` | keep | - | high | - |
| `img_mainMenu_RaceCards` | asset | `rom_assets.asm` | menu_main: 311 tiles + 12x30 map (`+$2764/+$2768`), palette `+$26E4` | good | `[static]` | keep | - | high | - |
| `img_Intro_Font` | asset | `rom_assets.asm` | menu_main: 50 font tiles at VRAM `$0000` | good | `[static]` | keep | - | high | - |
| `VdpCtrl` | hardware | `core/hw_const.asm` | menu_main: VDP control/status port `$C00004` | good | `[hardware]` | keep | - | high | - |
| `VdpData` | hardware | `core/hw_const.asm` | menu_main: VDP data port `$C00000` | good | `[hardware]` | keep | - | high | - |
| `Global_ram_PalettePtr` | RAM | `ram_const.asm` (`$FF305A`) | menu_main: active palette pointer | good | `[static]` | keep | - | high | - |
| `Global_ram_Palette` | RAM | `ram_const.asm` (`$FF305E`) | menu_main: palette shadow (64 words) | good | `[static]` | keep | - | high | - |
| `Intro_ram_ImageBuffer` | RAM | `ram_const.asm` (`$FF509C`) | menu_main/message: shared decompression/staging buffer for every asset | narrow | `[static]` | rename-later | `ram_ImageStagingBuffer` | medium | - |
| `Race_ram_ImageBuffer2` | RAM | `ram_const.asm` (`$FF8364`) | menu_main only: badge/card nametable staging (12x42) | misleading | `[static]` | rename-later | `MainMenu_ram_RaceCardBuffer` | medium | - |
| `Menu_ram_FrameBuffer` | RAM | `ram_const.asm` (`$FFB62C`) | menu_main/message: 64x28 window overlay | good | `[static]` | keep | - | high | - |
| `Menu_ram_Player` | RAM | `ram_const.asm` (`$FF0508`) | menu_main: 0=A, `$FFFF`=B | good | `[static]` | keep | - | high | - |
| `Menu_ram_PlayerMode` | RAM | `ram_const.asm` (`$FF05DA`) | menu_main: 1=A, 2=B, 3=two players | good | `[static]` | keep | - | high | - |
| `Menu_ram_PlayerALevel` | RAM | `ram_const.asm` (`$FF050C`) | menu_main: level index for the distance tooltip | good | `[static]` | keep | - | high | - |
| `Menu_ram_PlayerBLevel` | RAM | `ram_const.asm` (`$FF050E`) | menu_main: level index for the distance tooltip | good | `[static]` | keep | - | high | - |
| `Menu_ram_MoneyPlayerA` | RAM | `ram_const.asm` (`$FF0518`) | menu_main: negative = uninitialized profile | good | `[static]` | keep | - | high | - |
| `Menu_ram_MoneyPlayerB` | RAM | `ram_const.asm` (`$FF051C`) | menu_main: negative = uninitialized profile | good | `[static]` | keep | - | high | - |
| `Menu_ram_PlayerAPlaces` | RAM | `ram_const.asm` (`$FF052E`) | menu_main: five place words (race ids 0,2,4,6,8) | good | `[static]` | keep | - | high | - |
| `Menu_ram_PlayerBPlaces` | RAM | `ram_const.asm` (`$FF0538`) | menu_main: five place words | good | `[static]` | keep | - | high | - |
| `Menu_PlayerPlacesPtr` | RAM | `ram_const.asm` (`$FF05E0`) | menu_main: points at the active player's places | narrow | `[static]` | rename-later | `Menu_ram_PlayerPlacesPtr` | high | - |
| `Menu_ram_CurrentTrackId` | RAM | `ram_const.asm` (`$FF05DC`) | menu_main: current even track id 0..8 | good | `[static]` | keep | - | high | - |
| `Menu_ram_CurrentlyDrawnRaceCard` | RAM | `ram_const.asm` (`$FF05E4`) | menu_main: selected id, then carousel scratch (always even) | narrow | `[static]` | rename-later | `Menu_ram_CarouselRaceId` | medium | `U-0003` resolved |
| `Menu_ram_NextMessageTimer` | RAM | `ram_const.asm` (`$FF05D0`) | menu_main: tooltip advance delay | good | `[static]` | keep | - | high | - |
| `Menu_ram_MessageBlinkTimer` | RAM | `ram_const.asm` (`$FF05D2`) | menu_main: tooltip text blink phase | good | `[static]` | keep | - | high | - |
| `Menu_ram_CurrentMessageId` | RAM | `ram_const.asm` (`$FF05D4`) | menu_main/menu_password/shop/highscore/race_results/endlevel: `Message_MsgArray` byte index (multiple of 8) | good | `[static]` | keep | - | high | - |
| `Menu_ram_CurrentButtonsPtr` | RAM | `ram_const.asm` (`$FF0412`) | menu_main: current pad-state pointer for input handlers | good | `[static]` | keep | - | high | - |
| `Menu_ram_ChangedButtonsPtr` | RAM | `ram_const.asm` (`$FF0416`) | menu_main: edge-mask pointer for input handlers | good | `[static]` | keep | - | high | - |
| `Menu_ram_StrPlayerName` | RAM | `ram_const.asm` (`$FF046A`) | menu_main: scratch text record (name + level), reused for A and B | narrow | `[static]` | rename-later | `Menu_ram_PlayerInfoString` | medium | - |
| `Menu_ram_TempString` | RAM | `ram_const.asm` (`$FF0756`) | menu_main/message: race-name/distance tooltip record | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_DemoMode` | RAM | `ram_const.asm` (`$FF3692`) | menu_main: set after 30 s idle | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_FrameCounter` | RAM | `ram_const.asm` (`$FF3694`) | menu_main: idle/demo frame counter | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_ButtonsPlayerA` | RAM | `ram_const.asm` (`$FF05C8`) | menu_main: pad A current state | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_ChangedButtonsPlayerA` | RAM | `ram_const.asm` (`$FF05CA`) | menu_main: pad A old XOR new | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_ButtonsPlayerB` | RAM | `ram_const.asm` (`$FF05CC`) | menu_main: pad B current state | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_ChangedButtonsPlayerB` | RAM | `ram_const.asm` (`$FF05CE`) | menu_main: pad B old XOR new | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_CurrentButtons` | RAM | `ram_const.asm` (`$FF05DE`) | menu_main: newly pressed mask being handled | good | `[static]` | keep | - | high | - |
| `Message_ram_ButtonBlinkPeriod` | RAM | `ram_const.asm` (`$FF05E8`) | menu_main/message/other screens: button-icon blink period | good | `[static]` | keep | - | high | - |
| `ram_MusicEnabled` | RAM | `ram_const.asm` (`$FF05D6`) | menu_main: B toggles music | good | `[static]` | keep | - | high | - |
| `ram_CurrentSong` | RAM | `ram_const.asm` (`$FF05D8`) | menu_main: current song id (0/1) | good | `[static]` | keep | - | high | - |
| `ram_UpdateFunction` | RAM | `ram_const.asm` (`$FF1A62`) | menu_main: stage callback install/clear | good | `[static]` | keep | - | high | - |
| `Fade_ram_UpdateFunction` | RAM | `ram_const.asm` (`$FF0302`) | menu_main: queue the password screen behind an in-progress fade | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_CursorX` | RAM | `ram_const.asm` (`$FF0424`) | menu_main: password cursor column (reset to 1) | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_CursorY` | RAM | `ram_const.asm` (`$FF0422`) | menu_main: password cursor row (reset to 9) | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_HoldTimer` | RAM | `ram_const.asm` (`$FF0426`) | menu_main: `$FFFF` suppresses hold-repeat | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_HeldButtons` | RAM | `ram_const.asm` (`$FF0428`) | menu_main: cleared when the password screen opens | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_StrPlayerNamePtr` | RAM | `ram_const.asm` (`$FF041A`) | menu_main: active name record for the password screen | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_StrPlayerPasswordPtr` | RAM | `ram_const.asm` (`$FF041E`) | menu_main: active password record | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_StrPlayerAName` | RAM | `ram_const.asm` (`$FF04A4`) | menu_main: A name record (header + 10 chars) | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_StrPlayerAPassword` | RAM | `ram_const.asm` (`$FF042A`) | menu_main: A password record (header + 24 chars) | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_StrPlayerBName` | RAM | `ram_const.asm` (`$FF04B6`) | menu_main: B name record | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_StrPlayerBPassword` | RAM | `ram_const.asm` (`$FF044A`) | menu_main: B password record | good | `[static]` | keep | - | high | - |
| `MenuPassword_HandleInput` | routine | `menu_password.asm:269` (`$2710`) | menu_password: apply presses to name/password, move cursor | good | `[static]` | keep | - | high | - |
| `MenuPassword_UpdateStatus` | routine | `menu_password.asm:490` (`$2A1E`) | menu_password: status text, validate/parse password | good | `[static]` | keep | - | high | - |
| `MenuPassword_SetCursorPos` | routine | `menu_password.asm:587` (`$2B18`) | menu_password: write one cell's palette/high byte | good | `[static]` | keep | - | high | - |
| `MenuPassword_SwapPlayerBlocks` | routine | `menu_password.asm:683` (`$2BEE`) | menu_password: move the 16x14 selection panel | good | `[static]` | keep | - | high | - |
| `MenuPassword_ValidatePassword` | routine | `menu_password.asm:735` (`$2C32`) | menu_password: checksum verification | good | `[static]` | keep | - | high | - |
| `MenuPassword_ParsePassword` | routine | `menu_password.asm:857` (`$2D1E`) | menu_password: password words -> player state | good | `[static]` | keep | - | high | - |
| `MenuPassword_CreatePassword` | routine | `menu_password.asm:1063` (`$2F3A`) | menu_password; race_core/shop/endlevel: state -> password | good | `[static]` | keep | - | high | - |
| `Menu_DefaultPassword` | data | `menu_password.asm:47` | menu_password/intro: 24-char template (invalid checksum) | good | `[static]` | keep | - | high | - |
| `Menu_DefaultName` | data | `menu_password.asm:53` | intro: initial "Player A  " name | good | `[static]` | keep | - | high | - |
| `unk_2468` | data | `menu_password.asm:58` | unreferenced 5x20 status text (dead data) | placeholder | `[static]` | keep | - | medium | - |
| `MenuPassword_StrPasswordStatus` | RAM | `ram_const.asm` (`$FF067E`) | menu_password/message/race_results: 5x16 status record | good | `[static]` | keep | - | high | - |
| `MenuPassword_StrStatusTemplate` | data | `message.asm:699` | menu_password: 5x16 "PASSWORD INVALID" status template | good | `[static]` | keep (renamed from `unk_4E20`) | - | high | - |
| `dStringDecodeTable` | data | `intro.asm:806` (`$23D0`) | menu_password: font tile index -> ASCII | good | `[static]` | keep | - | high | - |
| `DecodeString` | routine | `intro.asm:777` (`$22B2`) | menu_password: password words -> string | good | `[static]` | keep | - | high | - |
| `MenuPassword_ram_CurrentButtons` | RAM | `ram_const.asm` (`$FF05C6`) | menu_password: input byte latched for the edit handlers | good | `[static]` | keep | - | high | - |
| `Menu_ram_PlayerAOpponents` | RAM | `ram_const.asm` (`$FF0546`) | menu_password: 16-word A opponent definition list | good | `[static]` | keep | - | high | - |
| `Menu_ram_PlayerBOpponents` | RAM | `ram_const.asm` (`$FF0566`) | menu_password: 16-word B opponent definition list | good | `[static]` | keep | - | high | - |
| `Menu_ram_BikeIdPlayerA` | RAM | `ram_const.asm` (`$FF0542`) | menu_password: A bike id (`w20` bits 0..2) | good | `[static]` | keep | - | high | - |
| `Menu_ram_BikeIdPlayerB` | RAM | `ram_const.asm` (`$FF0544`) | menu_password: B bike id | good | `[static]` | keep | - | high | - |
| `Player_ram_CareerScoreA` | RAM | `ram_const.asm` (`$FF0510`) | menu_password/race_core: A 20-bit career score / high-score value (`w7..w10`) | narrow | `[static]` | keep (renamed from `ram_FF0510`) | - | medium | `U-0005` resolved |
| `Player_ram_CareerScoreB` | RAM | `ram_const.asm` (`$FF0514`) | menu_password/race_core: B 20-bit career score / high-score value | narrow | `[static]` | keep (renamed from `ram_FF0514`) | - | medium | `U-0005` resolved |
| `ram_FF0522` | RAM | `ram_const.asm` (`$FF0522`) | menu_password/intro/race: A persisted Natasha encounter counter (0..3) | narrow | `[static]` | rename-later | `Player_ram_NatashaCounterA` | medium | `U-0004` resolved |
| `ram_FF0524` | RAM | `ram_const.asm` (`$FF0524`) | menu_password/intro/race: B persisted Natasha encounter counter (0..3) | narrow | `[static]` | rename-later | `Player_ram_NatashaCounterB` | medium | `U-0004` resolved |
| `Message_ShowNoop` | routine | `message.asm:56` (`$4268`) | message: no-op show function; also the rts ending `Message_ShowEmpty` | good | `[static]` | keep (renamed from `sub_4268`) | - | high | - |
| `Message_BlinkButtonA` | routine | `message.asm:103` (`$42AA`) | message/Menu_ShowMessage: blink A-button icon | good | `[static]` | keep | - | high | - |
| `Message_DrawButtonA` | routine | `message.asm:128` (`$42D0`) | message: draw-only A-button entry | good | `[static]` | keep | - | high | - |
| `Message_BlinkButtonB` | routine | `message.asm:153` (`$4302`) | message/Menu_ShowMessage: blink B-button icon | good | `[static]` | keep | - | high | - |
| `Message_DrawButtonB` | routine | `message.asm:178` (`$432A`) | message: draw-only B-button entry | good | `[static]` | keep | - | high | - |
| `Message_BlinkButtonsAB` | routine | `message.asm:205` (`$4362`) | message/Menu_ShowMessage: blink A+B icons | good | `[static]` | keep | - | high | - |
| `Message_BlinkButtonC` | routine | `message.asm:235` (`$4392`) | message/Menu_ShowMessage: blink C-button icon | good | `[static]` | keep | - | high | - |
| `Message_BlinkButtonStart` | routine | `message.asm:275` (`$43F6`) | message/Menu_ShowMessage: blink Start-button icon | good | `[static]` | keep | - | high | - |
| `Message_BlinkDirPadHorizontal` | routine | `message.asm:319` (`$445E`) | message/shop: blink the horizontal dpad pair (left/right prompts) | good | `[static]` | keep (renamed from `Message_DrawDirPadVert`) | - | high | - |
| `Message_DrawDirPadHorizontalIcon` | routine | `message.asm:345` (`$4486`) | message: draw-only horizontal dpad pair | good | `[static]` | keep (renamed from `loc_4486`) | - | high | - |
| `Message_BlinkDirPadVertical` | routine | `message.asm:381` (`$44D6`) | message: blink the vertical dpad pair (up/down) | good | `[static]` | keep (renamed from `Message_DrawDirPadRight`) | - | high | - |
| `Message_DrawDirPadVerticalIcon` | routine | `message.asm:406` (`$44FE`) | message: draw-only vertical dpad pair | good | `[static]` | keep (renamed from `loc_44FE`) | - | high | - |
| `Message_BlinkDirectionalPad` | routine | `message.asm:440` (`$454E`) | message/Menu_ShowMessage: blink the complete dpad | good | `[static]` | keep | - | high | - |
| `StrPressStartToExit` | data | `message.asm:561` (`$479E`) | message: 1x22 exit prompt (rider intro/end level) | good | `[static]` | keep | - | high | - |
| `StrPressABToChangeLetter` | data | `message.asm:564` (`$47BC`) | message: 3x20 password edit prompt | good | `[static]` | keep | - | high | - |
| `StrPressCToSelectOtherPlayer` | data | `message.asm:569` (`$4800`) | message: 3x20 password player-switch prompt | good | `[static]` | keep | - | high | - |
| `StrUseDirPadToMoveCursor` | data | `message.asm:574` (`$4844`) | message: 3x20 password cursor prompt | good | `[static]` | keep | - | high | - |
| `StrOnePlayerModeSelected` | data | `message.asm:579` (`$4888`) | message: 5x20 main-menu confirmation | good | `[static]` | keep | - | high | - |
| `StrTwoPlayerModeSelected` | data | `message.asm:586` (`$48F4`) | message: 5x20 main-menu confirmation | good | `[static]` | keep | - | high | - |
| `StrMusicOn` | data | `message.asm:593` (`$4960`) | message: 3x20 main-menu confirmation | good | `[static]` | keep | - | high | - |
| `StrMusicOff` | data | `message.asm:598` (`$49A4`) | message: 3x20 main-menu confirmation | good | `[static]` | keep | - | high | - |
| `Menu_StrRaceSierraNevada` | data | `message.asm:614` (`$49FC`) | message/menu_main: 5x20 race-name record | good | `[static]` | keep (renamed from `unk_49FC`) | - | high | - |
| `Menu_StrRacePacificCoast` | data | `message.asm:621` (`$4A68`) | message/menu_main: 5x20 race-name record | good | `[static]` | keep (renamed from `unk_4AE8`) | - | high | - |
| `Menu_StrRaceRedwoodForest` | data | `message.asm:628` (`$4AD4`) | message/menu_main: 5x20 race-name record | good | `[static]` | keep (renamed from `unk_4AD4`) | - | high | - |
| `Menu_StrRacePalmDesert` | data | `message.asm:635` (`$4B40`) | message/menu_main: 5x20 race-name record | good | `[static]` | keep (renamed from `unk_4B40`) | - | high | - |
| `Menu_StrRaceGrassValley` | data | `message.asm:642` (`$4BAC`) | message/menu_main: 5x20 race-name record | good | `[static]` | keep (renamed from `unk_4BAC`) | - | high | - |
| `DemoHighScoreTable` | data | `message.asm:653` (`$4C18`) | intro: 7x20 demo high-score table body | good | `[static]` | keep | - | high | - |
| `Message_StrPressStartToRace` | data | `message.asm:663` (`$4CA4`) | message: 3x20 main-menu tooltip | good | `[static]` | keep (renamed from `unk_4CA4`) | - | high | - |
| `Message_StrPressAPlayerSelection` | data | `message.asm:669` (`$4CE8`) | message: 3x20 main-menu tooltip | good | `[static]` | keep (renamed from `unk_4CE8`) | - | high | - |
| `Message_StrPressBMusicToggle` | data | `message.asm:675` (`$4D2C`) | message: 3x20 main-menu tooltip | good | `[static]` | keep (renamed from `unk_4D2C`) | - | high | - |
| `Message_StrPressCPassword` | data | `message.asm:681` (`$4D70`) | message: 5x20 main-menu tooltip | good | `[static]` | keep (renamed from `unk_4D70`) | - | high | - |
| `Message_StrDirPadSelectTrack` | data | `message.asm:689` (`$4DDC`) | message: 3x20 main-menu tooltip | good | `[static]` | keep (renamed from `unk_4DDC`) | - | high | - |
| `Message_StrBlank` | data | `message.asm:709` (`$4E78`) | message: 5x20 all-space record | good | `[static]` | keep (renamed from `unk_4E78`) | - | high | - |
| `Message_StrBlankCell` | data | `message.asm:720` (`$4EE4`) | message: 1x1 blank record (second byte is alignment padding) | good | `[static]` | keep (renamed from `unk_4EE4`) | - | high | - |
| `Message_StrPressAHighScores` | data | `message.asm:738` (`$4F4A`) | message: 5x20 "Press A ... High Scores" prompt | good | `[static]` | keep (renamed from `unk_4F4A`) | - | high | - |
| `Message_StrPressCNewBikes` | data | `message.asm:746` (`$4FB6`) | message: 3x20 "Press C ... new bikes" prompt | good | `[static]` | keep (renamed from `unk_4FB6`) | - | high | - |
| `Message_StrPressStartTrackSelection` | data | `message.asm:752` (`$4FFA`) | message: 3x20 "Press Start ... Track Selection" prompt | good | `[static]` | keep (renamed from `unk_4FFA`) | - | high | - |
| `Message_StrPressBRaceResults` | data | `message.asm:758` (`$503E`) | message: 5x20 "Press B ... Race Results" prompt | good | `[static]` | keep (renamed from `unk_503E`) | - | high | - |
| `Message_StrPressCBuyNewBike` | data | `message.asm:766` (`$50AA`) | message/shop: 5x20 "Press C ... buy a new" prefix | good | `[static]` | keep (renamed from `unk_50AA`) | - | high | - |
| `Message_StrPressLeftDirPad` | data | `message.asm:774` (`$5116`) | message/shop: 4x20 left-bike prompt prefix | good | `[static]` | keep (renamed from `unk_5116`) | - | high | - |
| `Message_StrPressRightDirPad` | data | `message.asm:781` (`$516E`) | message/shop: 4x20 right-bike prompt prefix | good | `[static]` | keep (renamed from `unk_516E`) | - | high | - |
| `Message_StrAlreadyOwnBike` | data | `message.asm:791` (`$51C6`) | message/shop: 3x20 "You already own a" prefix | good | `[static]` | keep (renamed from `unk_51C6`) | - | high | - |
| `Message_StrNeedMoreCredit` | data | `message.asm:797` (`$520A`) | message/shop: 5x20 "You need more credit" prefix | good | `[static]` | keep (renamed from `unk_520A`) | - | high | - |
| `Message_StrCompleteEveryCourse` | data | `message.asm:807` (`$5276`) | message/race_results: 4x20 incomplete-course text | good | `[static]` | keep (renamed from `unk_5276`) | - | high | - |
| `Message_StrComplete4thPlace` | data | `message.asm:814` (`$52CE`) | message/race_results: 5x20 worse-than-4th text | good | `[static]` | keep (renamed from `unk_52CE`) | - | high | - |
| `Message_StrCongratulations` | data | `message.asm:827` (`$533A`) | message/race_results: 5x20 level-clear text (level digit patched) | good | `[static]` | keep (renamed from `unk_533A`) | - | high | - |
| `Message_StrTradeInCredit` | data | `message.asm:837` (`$53A6`) | message/shop: 4x20 trade-in credit note | good | `[static]` | keep (renamed from `unk_53A6`) | - | high | - |
| `Message_StrBikeDescShuriken400` | data | `message.asm:848` (`$53FE`) | message/shop: bike id 0 prose description | good | `[static]` | keep (renamed from `unk_53FE`) | - | high | - |
| `Message_StrBikeDescPanda600` | data | `message.asm:854` (`$5466`) | message/shop: bike id 1 prose description | good | `[static]` | keep (renamed from `unk_5466`) | - | high | - |
| `Message_StrBikeDescBanzai750` | data | `message.asm:860` (`$54C2`) | message/shop: bike id 2 prose description | good | `[static]` | keep (renamed from `unk_54C2`) | - | high | - |
| `Message_StrBikeDescKamikaze750` | data | `message.asm:866` (`$5524`) | message/shop: bike id 3 prose description | good | `[static]` | keep (renamed from `unk_5524`) | - | high | - |
| `Message_StrBikeDescShuriken1000` | data | `message.asm:871` (`$556C`) | message/shop: bike id 4 prose description | good | `[static]` | keep (renamed from `unk_556C`) | - | high | - |
| `Message_StrBikeDescFerruci850` | data | `message.asm:877` (`$55C8`) | message/shop: bike id 5 prose description | good | `[static]` | keep (renamed from `unk_55C8`) | - | high | - |
| `Message_StrBikeDescPanda750` | data | `message.asm:883` (`$5624`) | message/shop: bike id 6 prose description | good | `[static]` | keep (renamed from `unk_5624`) | - | high | - |
| `Message_StrBikeDescDiablo1000` | data | `message.asm:888` (`$5668`) | message/shop: bike id 7 prose description | good | `[static]` | keep (renamed from `unk_5668`) | - | high | - |
| `Message_StrCaughtByCops` | data | `message.asm:896` (`$56AC`) | message/race_results: 2x18 busted-screen text | good | `[static]` | keep (renamed from `unk_56AC`) | - | high | - |
| `Message_StrCantAffordBail` | data | `message.asm:901` (`$56D8`) | message/race_results: 2x18 GAME OVER busted text | good | `[static]` | keep (renamed from `unk_56D8`) | - | high | - |
| `Message_StrBikeNeedsRepairs` | data | `message.asm:908` (`$5704`) | message/race_results: 2x18 repair-screen text | good | `[static]` | keep (renamed from `unk_5704`) | - | high | - |
| `Message_StrNoMoneyForRepairs` | data | `message.asm:913` (`$5730`) | message/race_results: 2x20 GAME OVER repair text | good | `[static]` | keep (renamed from `unk_5730`) | - | high | - |
| `Message_ram_ButtonBlinkCounter` | RAM | `ram_const.asm` (`$FF05E6`) | message: shared blink phase counter (advanced per show call) | good | `[static]` | keep | - | high | - |
| `Shop_StrBuyNewBike` | RAM | `ram_const.asm` (`$FF06EA`) | shop/message: runtime 5x20 "Press C to buy ..." record | good | `[static]` | keep | - | high | - |
| `ram_FF07C2` | RAM | `ram_const.asm` (`$FF07C2`) | shop/message: runtime 5x20 left-bike prompt record | placeholder | `[static]` | rename-later | `Shop_StrLeftBike` | medium | - |
| `ram_FF082E` | RAM | `ram_const.asm` (`$FF082E`) | shop/message: runtime 5x20 right-bike prompt record | placeholder | `[static]` | rename-later | `Shop_StrRightBike` | medium | - |
| `Message_ram_DynamicRecord` | RAM | `ram_const.asm:72` (`$FF089A`) | shop/race_results/message: runtime 5x20 dynamic message record | good | `[static]` | keep (renamed from `ram_FF089A`) | - | high | - |
| `RiderSprites_Build` | routine | `rider_sprites.asm:48` (`$5760`) | rider_sprites: build linked rider/bike SAT chain | good | `[static]` | keep | - | high | - |
| `RiderSprites_BuildAlt` | routine | `rider_sprites.asm:224` (`$593E`) | rider_sprites: unused wrapper | good | `[static]` | keep | - | high | - |
| `RiderSprites_StripTable` | data | `rider_sprites.asm:248` (`$5944`) | rider_sprites: 16 x 8-byte per-block SAT layout table | good | `[static]` | keep | - | high | - |
| `Race_ram_CurrentSpriteAttributeTable` | RAM | `ram_const.asm:567` (`$FF38AC`) | race/rider_sprites: SAT base pointer | good | `[static]` | keep | - | high | - |
| `Animation_ram_TileIndex` | RAM | `ram_const.asm:642` (`$FFDE60`) | animation/rider_sprites: tile cursor | good | `[static]` | keep | - | high | - |
| `Animation_ram_SpriteIndex` | RAM | `ram_const.asm:644` (`$FFDE64`) | animation/rider_sprites: next free SAT slot | good | `[static]` | keep | - | high | - |
| `Animation_ram_BaseTile` | RAM | `ram_const.asm:603` (`$FFD34A`) | animation/rider_sprites: base tile added to entries | good | `[static]` | keep | - | high | - |
| `ram_FFDE5E` | RAM | `ram_const.asm:641` (`$FFDE5E`) | road_render/rider_sprites: object palette/priority/base bits | placeholder | `[static]` | rename-later | `Road_ram_SpriteTileBits` | medium | - |
| `ram_FFDE62` | RAM | `ram_const.asm:643` (`$FFDE62`) | road_render/rider_sprites: chain-end/overflow flag | placeholder | `[static]` | rename-later | `Road_ram_ChainEnd` | medium | - |
| `ram_FFDE66` | RAM | `ram_const.asm:645` (`$FFDE66`) | road_render/rider_sprites: road-writer within-row stride | placeholder | `[static]` | rename-later | `Road_ram_TileRowStrideAlt` | medium | - |
| `ram_FFDE68` | RAM | `ram_const.asm:646` (`$FFDE68`) | road_render/rider_sprites: road-writer row stride | placeholder | `[static]` | rename-later | `Road_ram_TileRowStride` | medium | - |
| `ram_FFDE6A` | RAM | `ram_const.asm:647` (`$FFDE6A`) | road_render/rider_sprites: road-writer within-row stride | placeholder | `[static]` | rename-later | `Road_ram_TileColStride` | medium | - |
| `ram_FFDE6E` | RAM | `ram_const.asm:649` (`$FFDE6E`) | road_render/rider_sprites: object base X | placeholder | `[static]` | rename-later | `Road_ram_ObjectX` | medium | - |
| `ram_FFDE70` | RAM | `ram_const.asm:650` (`$FFDE70`) | road_render/rider_sprites: object base Y | placeholder | `[static]` | rename-later | `Road_ram_ObjectY` | medium | - |
| `ram_FF0906` | RAM | `ram_const.asm:74` (`$FF0906`) | rider_sprites: horizontal remainder code C as byte offset | placeholder | `[static]` | rename-later | `Rider_ram_ColCode` | medium | - |
| `ram_FF0908` | RAM | `ram_const.asm:75` (`$FF0908`) | rider_sprites: vertical remainder code R as byte offset | placeholder | `[static]` | rename-later | `Rider_ram_RowCode` | medium | - |
| `ram_FF090A` | RAM | `ram_const.asm:76` (`$FF090A`) | rider_sprites: horizontal block count | placeholder | `[static]` | rename-later | `Rider_ram_ColBlocks` | medium | - |
| `ram_FF090C` | RAM | `ram_const.asm:77` (`$FF090C`) | rider_sprites: vertical block count | placeholder | `[static]` | rename-later | `Rider_ram_RowBlocks` | medium | - |
| `ram_FF090E` | RAM | `ram_const.asm:78` (`$FF090E`) | rider_sprites: tile cursor at row start | placeholder | `[static]` | rename-later | `Rider_ram_RowStartTile` | medium | - |
| `ram_FF1336` | RAM | `ram_const.asm:101` (`$FF1336`) | road_render/rider_sprites: mirror X offset | placeholder | `[static]` | rename-later | `Road_ram_MirrorXOffset` | medium | - |
| `Road_ram_MirrorFlag` | RAM | `ram_const.asm:102` (`$FF133A`) | road_render/rider_sprites: mirror pass flag (object flags bit15) | good | `[static]` | keep (renamed from `ram_FF133A`) | - | high | `U-0007` resolved |
| `ram_FF1366` | RAM | `ram_const.asm:120` (`$FF1366`) | road_render/rider_sprites: tile-budget/SAT chain-end flag | placeholder | `[static]` | rename-later | `Road_ram_ChainEndAlt` | medium | - |
| `RiderIntro_Init` | routine | `rider_intro.asm:20` (`$59C4`) | rider_intro: build the intro screen (VDP, assets, opponent record, name/quote, DMA) | good | `[static]` | keep | - | high | - |
| `RiderIntro_GameTick` | routine | `rider_intro.asm:393` (`$5E66`) | rider_intro: per-frame DMA, pad release edge, timed message | good | `[static]` | keep | - | high | - |
| `RiderIntro_RecordTable` | data | `race_data_tables.asm:8` (`$19A12`) | rider_intro: 5 levels x 5 tracks x 4 variants, 8-byte (quote,image) records | good | `[static]` | keep | - | high | - |
| `Race_ram_ActiveController` | RAM | `ram_const.asm:287` (`$FF1ADA`) | rider_intro/race: 0/1 controller that exited the intro | good | `[static]` | keep | - | high | - |
| `ram_FF0520` | RAM | `ram_const.asm:34` (`$FF0520`) | rider_intro/race: current-race Natasha encounter flag (0/3); selects variant 3/overlay | narrow | `[static]` | rename-later | `Player_ram_NatashaCounter` | medium | `U-0004` resolved |
| `RiderIntro_PortraitPanel` | data | `rom_assets.asm:7` (`$7EA66`) | rider_intro/endlevel/results: portrait panel image (11 tiles + 12x14 map) | good | `[static]` | keep (renamed from `unk_7EA66`) | - | high | - |
| `RiderIntro_Portrait_0` | data | `rom_assets.asm:176` (`$AF902`) | rider_intro: Natasha portrait image (header name parsed) | good | `[static]` | keep (renamed from `unk_AF902`) | - | high | - |
| `RiderIntro_NatashaFaceOverlay` | data | `rom_assets.asm:180` (`$B1506`) | rider_intro: close-up Natasha face/expression overlay drawn during the encounter counter | good | `[static]` | keep (renamed from `unk_B1506`) | - | high | `U-0008` resolved |
| `RiderIntro_Quote_Natasha_01` | data | `rider_intro_quotes.asm:14` (`$16E70`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_16E70`) | - | high | - |
| `RiderIntro_Quote_Natasha_02` | data | `rider_intro_quotes.asm:22` (`$16EC4`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_16EC4`) | - | high | - |
| `RiderIntro_Quote_Natasha_03` | data | `rider_intro_quotes.asm:29` (`$16F08`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_16F08`) | - | high | - |
| `RiderIntro_Quote_Natasha_04` | data | `rider_intro_quotes.asm:36` (`$16F52`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_16F52`) | - | high | - |
| `RiderIntro_Quote_Natasha_05` | data | `rider_intro_quotes.asm:43` (`$16F9A`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_16F9A`) | - | high | - |
| `RiderIntro_Quote_Natasha_06` | data | `rider_intro_quotes.asm:51` (`$16FF2`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_16FF2`) | - | high | - |
| `RiderIntro_Quote_Natasha_07` | data | `rider_intro_quotes.asm:59` (`$1704E`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1704E`) | - | high | - |
| `RiderIntro_Quote_Natasha_08` | data | `rider_intro_quotes.asm:66` (`$17098`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17098`) | - | high | - |
| `RiderIntro_Quote_Natasha_09` | data | `rider_intro_quotes.asm:73` (`$170DA`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_170DA`) | - | high | - |
| `RiderIntro_Quote_Natasha_10` | data | `rider_intro_quotes.asm:80` (`$17118`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17118`) | - | high | - |
| `RiderIntro_Quote_Natasha_11` | data | `rider_intro_quotes.asm:87` (`$17154`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17154`) | - | high | - |
| `RiderIntro_Quote_Natasha_12` | data | `rider_intro_quotes.asm:94` (`$17198`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17198`) | - | high | - |
| `RiderIntro_Quote_Natasha_13` | data | `rider_intro_quotes.asm:103` (`$171FA`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_171FA`) | - | high | - |
| `RiderIntro_Quote_Natasha_14` | data | `rider_intro_quotes.asm:111` (`$1724E`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1724E`) | - | high | - |
| `RiderIntro_Quote_Natasha_15` | data | `rider_intro_quotes.asm:118` (`$17292`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17292`) | - | high | - |
| `RiderIntro_Quote_Natasha_16` | data | `rider_intro_quotes.asm:125` (`$172D0`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_172D0`) | - | high | - |
| `RiderIntro_Quote_Natasha_17` | data | `rider_intro_quotes.asm:137` (`$1731E`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1731E`) | - | high | - |
| `RiderIntro_Quote_Natasha_18` | data | `rider_intro_quotes.asm:145` (`$1737E`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1737E`) | - | high | - |
| `RiderIntro_Quote_Natasha_19` | data | `rider_intro_quotes.asm:152` (`$173C2`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_173C2`) | - | high | - |
| `RiderIntro_Quote_Natasha_20` | data | `rider_intro_quotes.asm:160` (`$1741E`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1741E`) | - | high | - |
| `RiderIntro_Quote_Natasha_21` | data | `rider_intro_quotes.asm:166` (`$1744C`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1744C`) | - | high | - |
| `RiderIntro_Quote_Natasha_22` | data | `rider_intro_quotes.asm:173` (`$17494`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17494`) | - | high | - |
| `RiderIntro_Quote_Natasha_23` | data | `rider_intro_quotes.asm:180` (`$174D2`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_174D2`) | - | high | - |
| `RiderIntro_Quote_Natasha_24` | data | `rider_intro_quotes.asm:187` (`$17516`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17516`) | - | high | - |
| `RiderIntro_Quote_Natasha_25` | data | `rider_intro_quotes.asm:195` (`$1756E`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1756E`) | - | high | - |
| `RiderIntro_Quote_Natasha_26` | data | `rider_intro_quotes.asm:202` (`$175B2`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_175B2`) | - | high | - |
| `RiderIntro_Quote_Natasha_27` | data | `rider_intro_quotes.asm:211` (`$1761E`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1761E`) | - | high | - |
| `RiderIntro_Quote_Natasha_28` | data | `rider_intro_quotes.asm:217` (`$17648`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17648`) | - | high | - |
| `RiderIntro_Quote_Natasha_29` | data | `rider_intro_quotes.asm:224` (`$1768A`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1768A`) | - | high | - |
| `RiderIntro_Quote_Natasha_30` | data | `rider_intro_quotes.asm:232` (`$176DE`) | rider_intro: intro quote for Natasha (portrait 0); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_176DE`) | - | high | - |
| `RiderIntro_Quote_Biff_01` | data | `rider_intro_quotes.asm:602` (`$18548`) | rider_intro: intro quote for Biff (portrait 6); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18548`) | - | high | - |
| `RiderIntro_Quote_Biff_02` | data | `rider_intro_quotes.asm:610` (`$1859C`) | rider_intro: intro quote for Biff (portrait 6); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1859C`) | - | high | - |
| `RiderIntro_Quote_Biff_03` | data | `rider_intro_quotes.asm:617` (`$185DE`) | rider_intro: intro quote for Biff (portrait 6); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_185DE`) | - | high | - |
| `RiderIntro_Quote_Biff_04` | data | `rider_intro_quotes.asm:625` (`$1862A`) | rider_intro: intro quote for Biff (portrait 6); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1862A`) | - | high | - |
| `RiderIntro_Quote_Biff_05` | data | `rider_intro_quotes.asm:632` (`$18674`) | rider_intro: intro quote for Biff (portrait 6); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18674`) | - | high | - |
| `RiderIntro_Quote_Biff_06` | data | `rider_intro_quotes.asm:639` (`$186B8`) | rider_intro: intro quote for Biff (portrait 6); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_186B8`) | - | high | - |
| `RiderIntro_Quote_Slater_01` | data | `rider_intro_quotes.asm:691` (`$188B0`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_188B0`) | - | high | - |
| `RiderIntro_Quote_Slater_02` | data | `rider_intro_quotes.asm:698` (`$188FA`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_188FA`) | - | high | - |
| `RiderIntro_Quote_Slater_03` | data | `rider_intro_quotes.asm:705` (`$1893E`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1893E`) | - | high | - |
| `RiderIntro_Quote_Slater_04` | data | `rider_intro_quotes.asm:712` (`$18982`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18982`) | - | high | - |
| `RiderIntro_Quote_Slater_05` | data | `rider_intro_quotes.asm:720` (`$189DE`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_189DE`) | - | high | - |
| `RiderIntro_Quote_Slater_06` | data | `rider_intro_quotes.asm:727` (`$18A26`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18A26`) | - | high | - |
| `RiderIntro_Quote_Slater_07` | data | `rider_intro_quotes.asm:735` (`$18A7E`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18A7E`) | - | high | - |
| `RiderIntro_Quote_Slater_08` | data | `rider_intro_quotes.asm:742` (`$18AC6`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18AC6`) | - | high | - |
| `RiderIntro_Quote_Slater_09` | data | `rider_intro_quotes.asm:749` (`$18B0A`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18B0A`) | - | high | - |
| `RiderIntro_Quote_Slater_10` | data | `rider_intro_quotes.asm:757` (`$18B62`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18B62`) | - | high | - |
| `RiderIntro_Quote_Slater_11` | data | `rider_intro_quotes.asm:765` (`$18BAE`) | rider_intro: intro quote for Slater (portrait 7); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18BAE`) | - | high | - |
| `RiderIntro_Quote_OLeary_01` | data | `rider_intro_quotes.asm:276` (`$178A4`) | rider_intro: intro quote for O'Leary (portrait 1); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_178A4`) | - | high | - |
| `RiderIntro_Quote_OLeary_02` | data | `rider_intro_quotes.asm:283` (`$178E8`) | rider_intro: intro quote for O'Leary (portrait 1); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_178E8`) | - | high | - |
| `RiderIntro_Quote_OLeary_03` | data | `rider_intro_quotes.asm:291` (`$17940`) | rider_intro: intro quote for O'Leary (portrait 1); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17940`) | - | high | - |
| `RiderIntro_Quote_ORourke_01` | data | `rider_intro_quotes.asm:342` (`$17B32`) | rider_intro: intro quote for O'Rourke (portrait 2); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17B32`) | - | high | - |
| `RiderIntro_Quote_ORourke_02` | data | `rider_intro_quotes.asm:350` (`$17B8A`) | rider_intro: intro quote for O'Rourke (portrait 2); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17B8A`) | - | high | - |
| `RiderIntro_Quote_ORourke_03` | data | `rider_intro_quotes.asm:358` (`$17BEA`) | rider_intro: intro quote for O'Rourke (portrait 2); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17BEA`) | - | high | - |
| `RiderIntro_Quote_ORourke_04` | data | `rider_intro_quotes.asm:365` (`$17C34`) | rider_intro: intro quote for O'Rourke (portrait 2); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17C34`) | - | high | - |
| `RiderIntro_Quote_Ikira_01` | data | `rider_intro_quotes.asm:825` (`$18DC8`) | rider_intro: intro quote for Ikira (portrait 8); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18DC8`) | - | high | - |
| `RiderIntro_Quote_Ikira_02` | data | `rider_intro_quotes.asm:833` (`$18E20`) | rider_intro: intro quote for Ikira (portrait 8); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18E20`) | - | high | - |
| `RiderIntro_Quote_Ikira_03` | data | `rider_intro_quotes.asm:840` (`$18E5E`) | rider_intro: intro quote for Ikira (portrait 8); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18E5E`) | - | high | - |
| `RiderIntro_Quote_Ikira_04` | data | `rider_intro_quotes.asm:847` (`$18EA0`) | rider_intro: intro quote for Ikira (portrait 8); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18EA0`) | - | high | - |
| `RiderIntro_Quote_Ikira_05` | data | `rider_intro_quotes.asm:855` (`$18EF8`) | rider_intro: intro quote for Ikira (portrait 8); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18EF8`) | - | high | - |
| `RiderIntro_Quote_Ikira_06` | data | `rider_intro_quotes.asm:862` (`$18F42`) | rider_intro: intro quote for Ikira (portrait 8); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18F42`) | - | high | - |
| `RiderIntro_Quote_Ikira_07` | data | `rider_intro_quotes.asm:869` (`$18F80`) | rider_intro: intro quote for Ikira (portrait 8); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18F80`) | - | high | - |
| `RiderIntro_Quote_Sergio_01` | data | `rider_intro_quotes.asm:924` (`$19178`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_19178`) | - | high | - |
| `RiderIntro_Quote_Sergio_02` | data | `rider_intro_quotes.asm:931` (`$191C0`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_191C0`) | - | high | - |
| `RiderIntro_Quote_Sergio_03` | data | `rider_intro_quotes.asm:938` (`$191FC`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_191FC`) | - | high | - |
| `RiderIntro_Quote_Sergio_04` | data | `rider_intro_quotes.asm:945` (`$1923E`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1923E`) | - | high | - |
| `RiderIntro_Quote_Sergio_05` | data | `rider_intro_quotes.asm:952` (`$1927C`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1927C`) | - | high | - |
| `RiderIntro_Quote_Sergio_06` | data | `rider_intro_quotes.asm:959` (`$192BA`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_192BA`) | - | high | - |
| `RiderIntro_Quote_Sergio_07` | data | `rider_intro_quotes.asm:967` (`$1930E`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1930E`) | - | high | - |
| `RiderIntro_Quote_Sergio_08` | data | `rider_intro_quotes.asm:975` (`$1936A`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1936A`) | - | high | - |
| `RiderIntro_Quote_Sergio_09` | data | `rider_intro_quotes.asm:983` (`$193B2`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_193B2`) | - | high | - |
| `RiderIntro_Quote_Sergio_10` | data | `rider_intro_quotes.asm:990` (`$193FA`) | rider_intro: intro quote for Sergio (portrait 9); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_193FA`) | - | high | - |
| `RiderIntro_Quote_Flynn_01` | data | `rider_intro_quotes.asm:414` (`$17E02`) | rider_intro: intro quote for Flynn (portrait 3); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17E02`) | - | high | - |
| `RiderIntro_Quote_Flynn_02` | data | `rider_intro_quotes.asm:421` (`$17E46`) | rider_intro: intro quote for Flynn (portrait 3); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17E46`) | - | high | - |
| `RiderIntro_Quote_Flynn_03` | data | `rider_intro_quotes.asm:428` (`$17E88`) | rider_intro: intro quote for Flynn (portrait 3); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_17E88`) | - | high | - |
| `RiderIntro_Quote_OShea_01` | data | `rider_intro_quotes.asm:482` (`$180AE`) | rider_intro: intro quote for O'Shea (portrait 4); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_180AE`) | - | high | - |
| `RiderIntro_Quote_OShea_02` | data | `rider_intro_quotes.asm:490` (`$1810E`) | rider_intro: intro quote for O'Shea (portrait 4); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1810E`) | - | high | - |
| `RiderIntro_Quote_OShea_03` | data | `rider_intro_quotes.asm:498` (`$1816A`) | rider_intro: intro quote for O'Shea (portrait 4); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1816A`) | - | high | - |
| `RiderIntro_Quote_Helldog_01` | data | `rider_intro_quotes.asm:1055` (`$1968A`) | rider_intro: intro quote for Helldog (portrait 10); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_1968A`) | - | high | - |
| `RiderIntro_Quote_Helldog_02` | data | `rider_intro_quotes.asm:1063` (`$196DE`) | rider_intro: intro quote for Helldog (portrait 10); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_196DE`) | - | high | - |
| `RiderIntro_Quote_Helldog_03` | data | `rider_intro_quotes.asm:1070` (`$19720`) | rider_intro: intro quote for Helldog (portrait 10); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_19720`) | - | high | - |
| `RiderIntro_Quote_Helldog_04` | data | `rider_intro_quotes.asm:1077` (`$19768`) | rider_intro: intro quote for Helldog (portrait 10); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_19768`) | - | high | - |
| `RiderIntro_Quote_Helldog_05` | data | `rider_intro_quotes.asm:1084` (`$197AC`) | rider_intro: intro quote for Helldog (portrait 10); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_197AC`) | - | high | - |
| `RiderIntro_Quote_Helldog_06` | data | `rider_intro_quotes.asm:1092` (`$19804`) | rider_intro: intro quote for Helldog (portrait 10); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_19804`) | - | high | - |
| `RiderIntro_Quote_OConnor_01` | data | `rider_intro_quotes.asm:545` (`$18302`) | rider_intro: intro quote for O'Connor (portrait 5); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18302`) | - | high | - |
| `RiderIntro_Quote_OConnor_02` | data | `rider_intro_quotes.asm:552` (`$18346`) | rider_intro: intro quote for O'Connor (portrait 5); only `RiderIntro_RecordTable` | good | `[static]` | keep (renamed from `RaceQuote_18346`) | - | high | - |
| `RiderIntro_QuoteData` | data alias | `rider_intro_quotes.asm:1143` (`$16E70`) | rider_intro: aliases the first intro quote; no current reader | narrow | `[static]` | rename-later | `RiderIntro_FirstQuote` | medium | - |
| `RaceResults_Init` | routine | `race_results.asm ($5F28)` | race_results: outcome copy, VDP setup, layout dispatch, status box, audio | good | `[static]` | keep | - | high | - |
| `RaceResults_DrawStandings` | routine | `race_results.asm ($62CE)` | race_results: title, track image/palette, standings, player row | good | `[static]` | keep | - | high | - |
| `RaceResults_DrawBusted` | routine | `race_results.asm ($647E)` | race_results: busted title/panel, cop portrait/quote, fine or GAME OVER | good | `[static]` | keep | - | high | - |
| `RaceResults_DrawRepair` | routine | `race_results.asm ($67AC)` | race_results: repair panel, level portrait/quote, cost or GAME OVER | good | `[static]` | keep | - | high | - |
| `RaceResults_GameTick` | routine | `race_results.asm ($6A90)` | race_results: per-frame DMA, input, message cycle, exit | good | `[static]` | keep | - | high | - |
| `RaceResults_HandleInput` | routine | `race_results.asm ($6BD4)` | race_results: A high score, B status box, C shop | good | `[static]` | keep | - | high | - |
| `DrawString` | routine | `race_results.asm ($6C5E)` | race_results: unused text draw helper (dead: no callers) | good | `[static]` | keep | - | high | - |
| `Race_ram_PlayerAOutcome` | RAM | `ram_const.asm:37 ($FF0526)` | race_core/intro/endlevel/race_results: player A race outcome (0/>4/4) | good | `[static]` | keep (renamed) | - | high | - |
| `Race_ram_PlayerBOutcome` | RAM | `ram_const.asm:38 ($FF0528)` | race_core/intro/endlevel/race_results: player B race outcome (0/>4/4) | good | `[static]` | keep (renamed) | - | high | - |
| `RaceResults_ram_NextFunction` | RAM | `ram_const.asm:78 ($FF0910)` | race_results/highscore/shop: next-screen pointer | good | `[static]` | keep | - | high | - |
| `RaceResults_ram_DrawRoutine` | RAM | `ram_const.asm:79 ($FF0914)` | race_results: active draw routine pointer (written, never read) | good | `[static]` | keep | - | high | - |
| `RaceResults_ram_Outcome` | RAM | `ram_const.asm:80 ($FF0918)` | race_results: copied outcome; 4 selects the end-level screen | good | `[static]` | keep | - | high | - |
| `RaceResults_ram_Amount` | RAM | `ram_const.asm:81 ($FF091A)` | race_results: fine/repair amount for the bust/repair message | good | `[static]` | keep | - | high | - |
| `RaceResults_ram_CurrentButtons` | RAM | `ram_const.asm:82 ($FF091C)` | race_results: current pad byte passed to HandleInput | good | `[static]` | keep | - | high | - |
| `Menu_ram_PlayerLevel` | RAM | `ram_const.asm:27 ($FF050A)` | race_results/rider_intro/shop/endlevel: 1-based player level | good | `[static]` | keep | - | high | - |
| `RaceResults_ram_StandingsRecord` | RAM | `ram_const.asm:176 ($FF1414)` | race_results/race_core: standings text record (header + chars) | good | `[static]` | keep (renamed from `ram_FF1414`) | - | high | - |
| `RaceResults_ram_StandingsHeight` | RAM | `ram_const.asm:177 ($FF1418)` | race_results/race_core: standings text height | good | `[static]` | keep (renamed from `ram_FF1418`) | - | high | - |
| `RaceResults_ram_StandingsWidth` | RAM | `ram_const.asm:178 ($FF141A)` | race_results/race_core: standings text width | good | `[static]` | keep (renamed from `ram_FF141A`) | - | high | - |
| `Race_EventBuffer` | RAM | `ram_const.asm:25 ($FF04C8)` | race_results/race_core: 16-long event buffer; first word $FFFF = busted/destroyed | good | `[static]` | keep | - | high | - |
| `Race_CopIndex` | RAM | `ram_const.asm:313 ($FF1B1A)` | race_results/race_core: cop index 1..5; 0 = bike destroyed | good | `[static]` | keep | - | high | - |
| `Race_ComputeResults` | routine | `race_core.asm ($C3F8)` | race_results: computes outcome, fine/repair, places, password | good | `[static]` | keep | - | high | - |
| `Race_FormatMoney` | routine | `race_core.asm ($C6C4)` | race_results: backwards right-aligned cash formatter | good | `[static]` | keep | - | high | - |
| `Race_FormatNumber` | routine | `race_core.asm ($C79A)` | race_results/shop/race: backwards number formatter for fines/costs | good | `[static]` | keep | - | high | - |
| `HighScore_Init` | routine | `highscore.asm ($6DC0)` | race_results: A opens the high-score screen | good | `[static]` | keep | - | high | - |
| `Shop_Init` | routine | `shop.asm:17 ($74AA)` | race_results/shop: C opens the shop; builds the whole screen | good | `[static]` | keep | - | high | - |
| `RaceResults_TitleTiles` | data | `rom_assets.asm ($AF26C)` | race_results: results title tiles (27x2 map) | good | `[static]` | keep (renamed from `unk_AF26C`) | - | high | - |
| `RaceResults_BustedTitleTiles` | data | `rom_assets.asm ($7ED66)` | race_results: busted title tiles ($15x2 map) | good | `[static]` | keep (renamed from `unk_7ED66`) | - | high | - |
| `RaceResults_TrackImagePtrs` | data | `race_misc_data.asm ($7E670)` | race_results: five long pointers to per-track images | good | `[static]` | keep (renamed from `unk_7E670`) | - | high | - |
| `RaceResults_TrackImageOffsets` | data | `race_misc_data.asm ($7E684)` | race_results: five word image offsets in the staging buffer | good | `[static]` | keep (renamed from `unk_7E684`) | - | high | - |
| `RaceResults_TrackNametableOffsets` | data | `race_misc_data.asm ($7E68E)` | race_results: five word nametable offsets | good | `[static]` | keep (renamed from `unk_7E68E`) | - | high | - |
| `RaceResults_TrackPaletteOffsets` | data | `race_misc_data.asm ($7E698)` | race_results: five word palette offsets | good | `[static]` | keep (renamed from `unk_7E698`) | - | high | - |
| `RaceResults_CopTablePos` | data | `race_data_tables.asm ($19E22)` | race_results: cop portraits, money>=0, 5x4 8-byte records | good | `[static]` | keep | - | high | - |
| `RaceResults_CopTableNeg` | data | `race_data_tables.asm ($19EC2)` | race_results: cop portraits, money<0, 5x2 8-byte records | good | `[static]` | keep | - | high | - |
| `RaceResults_LevelTablePos` | data | `race_data_tables.asm ($19D32)` | race_results: level portraits, money>=0, 5x4 8-byte records | good | `[static]` | keep | - | high | - |
| `RaceResults_LevelTableNeg` | data | `race_data_tables.asm ($19DD2)` | race_results: level portraits, money<0, 5x2 8-byte records | good | `[static]` | keep | - | high | - |
| `RaceResults_StrNextLevelShort` | data | `race_results.asm ($6C94)` | race_results: dead 5x20 'next level' text (duplicate of endlevel $8C96) | good | `[static]` | keep (renamed from `unk_6C94`) | - | high | - |
| `RaceResults_StrNotReadyEncoded` | data | `race_results.asm ($6D00)` | race_results: dead 20-byte ASCII with bit 7 set 'You aren't ready for' (duplicate $8D02) | good | `[static]` | keep (renamed from `unk_6D00`) | - | high | - |
| `RaceResults_StrNotReadyTail` | data | `race_results.asm ($6D14)` | race_results: dead continuation text (duplicate of endlevel $8D16) | good | `[static]` | keep (renamed from `unk_6D14`) | - | high | - |
| `RaceResults_StrContinuePlay` | data | `race_results.asm ($6D50)` | race_results: dead 3x16 'Continue play at' text (duplicate $8D52) | good | `[static]` | keep (renamed from `unk_6D50`) | - | high | - |
| `RaceResults_StrNextLevel` | data | `race_results.asm ($6D88)` | race_results: dead 3x16 'The next level' text (duplicate $8D8A) | good | `[static]` | keep (renamed from `unk_6D88`) | - | high | - |
| `VDP_VRAM_WRITE` | macro | `hw_const.asm:9` | race_results and other screens: staged VRAM write helper | good | `[static]` | keep | - | high | - |
| `VDP_VSRAM_WRITE` | macro | `hw_const.asm:25` | race_results and other screens: staged VSRAM write helper | good | `[static]` | keep | - | high | - |
| `HighScore_GameTick` | routine | `highscore.asm:406` (`$732E`) | highscore: normal tick (frame DMA, release/new-press, message cycle) | good | `[static]` | keep | - | high | - |
| `HighScore_GameTick_Demo` | routine | `highscore.asm:364` (`$72BA`) | highscore: attract tick (release edge or 600-frame timer) | good | `[static]` | keep | - | high | - |
| `HighScore_HandleInput` | routine | `highscore.asm:484` (`$7460`) | highscore: A/B/C -> restart/results/shop | good | `[static]` | keep | - | high | - |
| `HighScore_ram_Table` | RAM | `ram_const.asm:66` (`$FF05EA`) | highscore/intro/race_core: header + 7x20 high-score table | good | `[static]` | keep | - | high | - |
| `HighScore_ram_PlayerATableOffset` | RAM | `ram_const.asm:39` (`$FF052A`) | highscore/intro/race_core: player A row byte offset | good | `[static]` | keep | - | high | - |
| `HighScore_ram_PlayerBTableOffset` | RAM | `ram_const.asm:40` (`$FF052C`) | highscore/intro/race_core: player B row byte offset | good | `[static]` | keep | - | high | - |
| `HighScore_ram_CurrentButtons` | RAM | `ram_const.asm:83` (`$FF094E`) | highscore: low byte of the pad state handled by A/B/C | narrow | `[static]` | keep | - | medium | - |
| `ImgHighScoreTitle` | asset | `rom_assets.asm:152` (`$A2F5C`) | highscore: 20x2 title to `$9000`; its palette (+$4E4) is loaded to 4 palettes | good | `[static]` | keep | - | high | - |
| `ImgHighScoreBadge` | asset | `rom_assets.asm:10` (`$7EB72`) | highscore: yellow badge to `$B000`, drawn five times | good | `[static]` | keep | - | high | - |
| `FontHighScoreTable` | asset | `rom_assets.asm:146` (`$A2BAA`) | highscore: 20-wide table font to `$800` | good | `[static]` | keep | - | high | - |
| `FontHighScoreDigits` | asset | `rom_assets.asm:149` (`$A2E68`) | highscore: 10 digit glyphs (0-9) to `$1000`; loaded but never drawn | good | `[static]` | keep (renamed from `unk_A2E68`) | - | high | `U-0009` wontfix |
| `Shop_DrawBikeName` | routine | `shop.asm:339 ($7996)` | shop: encode/draw the selected bike name+stats at (13,18) | good | `[static]` | keep | - | high | - |
| `Shop_ShowBikeDescription` | routine | `shop.asm:367 ($79DA)` | shop: select description message 51..58 for 600 frames | good | `[static]` | keep | - | high | - |
| `Shop_GameTick` | routine | `shop.asm:385 ($79F8)` | shop: frame DMA, H-scroll, Start->results, pad edges, message cycle | good | `[static]` | keep | - | high | - |
| `Shop_HandleInput` | routine | `shop.asm:469 ($7B4C)` | shop: A high score, B results, C buy/trade-in, Left/Right select | good | `[static]` | keep | - | high | - |
| `Shop_DrawCreditsAndPrice` | routine | `shop.asm:604 ($7D5E)` | shop: credits + price; palette 2 when affordable, palette 3 when not | good | `[static]` | keep | - | high | - |
| `Shop_DrawString` | routine | `shop.asm:684 ($7E70)` | shop: encode/draw a string with the caller palette word | good | `[static]` | keep | - | high | - |
| `Shop_ShowAlreadyOwned` | routine | `shop.asm:708 ($7EA2)` | shop: dynamic "You already own a ..." message 59 | good | `[static]` | keep | - | high | - |
| `Shop_ShowCannotAfford` | routine | `shop.asm:748 ($7F02)` | shop: dynamic "You need more credit ..." message 59 | good | `[static]` | keep | - | high | - |
| `Shop_PrepareMessages` | routine | `shop.asm:789 ($7F62)` | shop: build the buy/left/right prompt records | good | `[static]` | keep | - | high | - |
| `Shop_DrawBikes` | routine | `shop.asm:885 ($803C)` | shop: palette lines 2/3 + five bike images on the plane | good | `[static]` | keep | - | high | - |
| `Shop_UpdateScroll` | routine | `shop.asm:996 ($8178)` | shop: clamp +/-8 and animate the H-scroll band back to $160 | good | `[static]` | keep | - | high | - |
| `Shop_BikeDescriptions` | data | `shop.asm:1029 ($81D2)` | shop: eight pointers to name/power/weight records | good | `[static]` | keep | - | high | - |
| `Shop_StrShuriken400` | data | `shop.asm:1039 ($81F2)` | shop: bike id 0 name/power/weight record | good | `[static]` | keep | - | high | - |
| `Shop_StrPanda600` | data | `shop.asm:1043 ($8216)` | shop: bike id 1 name/power/weight record | good | `[static]` | keep | - | high | - |
| `Shop_StrBanzai750` | data | `shop.asm:1047 ($823A)` | shop: bike id 2 name/power/weight record | good | `[static]` | keep | - | high | - |
| `Shop_StrKamikaze750` | data | `shop.asm:1051 ($825E)` | shop: bike id 3 name/power/weight record | good | `[static]` | keep | - | high | - |
| `Shop_StrShuriken1000` | data | `shop.asm:1055 ($8282)` | shop: bike id 4 name/power/weight record | good | `[static]` | keep | - | high | - |
| `Shop_StrFerruci850` | data | `shop.asm:1059 ($82A6)` | shop: bike id 5 name/power/weight record | good | `[static]` | keep | - | high | - |
| `Shop_StrPanda750` | data | `shop.asm:1063 ($82CA)` | shop: bike id 6 name/power/weight record | good | `[static]` | keep | - | high | - |
| `Shop_StrDiablo1000` | data | `shop.asm:1067 ($82EE)` | shop: bike id 7 name/power/weight record | good | `[static]` | keep | - | high | - |
| `Shop_dPrices` | data | `shop.asm:1073 ($8312)` | shop: eight bike prices; half the current price is trade-in credit | good | `[static]` | keep | - | high | - |
| `Shop_BikeImageTable` | data | `shop.asm:1084 ($8322)` | shop: eight ids -> one of three 18x9 RAM maps [3,3,3,1,1,2,1,2] | good | `[static]` | keep | - | high | - |
| `Shop_BikePalettes` | data | `race_misc_data.asm:86 ($7E370)` | shop/race_core: eight 32-byte 16-colour bike palettes | good | `[static]` | keep | - | high | - |
| `Shop_CurrentBikeId` | RAM | `ram_const.asm:84 ($FF0950)` | shop: selected bike id 0..7 | good | `[static]` | keep | - | high | - |
| `Shop_ram_CurrentButtons` | RAM | `ram_const.asm:85 ($FF0952)` | shop: low byte of the pad state being handled (upper byte stale) | narrow | `[static]` | keep | - | medium | - |
| `Shop_ScrollPos` | RAM | `ram_const.asm:86 ($FF0954)` | shop: H-scroll band position (centre $160) | good | `[static]` | keep | - | high | - |
| `Shop_ImageBike1` | RAM | `ram_const.asm:87 ($FF0956)` | shop: 18x9 nametable map for bike model 1 | good | `[static]` | keep | - | high | - |
| `Shop_ImageBike2` | RAM | `ram_const.asm:88 ($FF0A9A)` | shop: 18x9 nametable map for bike model 2 | good | `[static]` | keep | - | high | - |
| `Shop_ImageBike3` | RAM | `ram_const.asm:89 ($FF0BDE)` | shop: 18x9 nametable map for bike model 3 | good | `[static]` | keep | - | high | - |
| `ImgShopArrowLeft` | asset | `rom_assets.asm:125 ($9E784)` | shop: 4x2 left arrow tiles to $B000 | good | `[static]` | keep | - | high | - |
| `ImgShopArrowRight` | asset | `rom_assets.asm:128 ($9E874)` | shop: 4x2 right arrow tiles to $B100; its palette (+$C4) becomes the screen palette | good | `[static]` | keep | - | high | - |
| `ImgShopBike1` | asset | `rom_assets.asm:131 ($9EA1E)` | shop: bike model 1 tiles to $C000; 18x9 map to Shop_ImageBike1 | good | `[static]` | keep | - | high | - |
| `ImgShopBike2` | asset | `rom_assets.asm:134 ($9FDDE)` | shop: bike model 2 tiles to $D000; 18x9 map to Shop_ImageBike2 | good | `[static]` | keep | - | high | - |
| `ImgShopBike3` | asset | `rom_assets.asm:137 ($A122A)` | shop: bike model 3 tiles to $E000; 18x9 map to Shop_ImageBike3 | good | `[static]` | keep | - | high | - |
| `DmaWriteCRAM` | routine | `race_physics.asm:49 ($0D96A)` | shop/race: upload Global_ram_PalettePtr to CRAM while the shop scroll moves | good | `[static]` | keep | - | high | - |
| `EndLevel_Init` | routine | `endlevel.asm:29 ($8342)` | endlevel: VDP, background/window/tiles/font, race-animation state | good | `[static]` | keep | - | high | - |
| `EndLevel_InitVictoryCharacter` | routine | `endlevel.asm:220 ($8682)` | endlevel: panel, rider portrait/name/quote/palette, AdvanceLevel | good | `[static]` | keep | - | high | - |
| `EndLevel_AdvanceLevel` | routine | `endlevel.asm:422 ($8946)` | endlevel: level++ (clamp 5), places/outcome clear, opponents, password | good | `[static]` | keep | - | high | - |
| `EndLevel_GameTickVictoryCharacter` | routine | `endlevel.asm:494 ($8A1A)` | endlevel: window DMA, Start-held exit, message group $180 | good | `[static]` | keep | - | high | - |
| `EndLevel_GameTick` | routine | `endlevel.asm:558 ($8AEE)` | endlevel: swap-delay DMA/SAT and end-stage switch | good | `[static]` | keep | - | high | - |
| `EndLevel_UpdateAnimation` | routine | `endlevel.asm:615 ($8B94)` | endlevel: per-level frame limit, UpdateAnimation2, end input | good | `[static]` | keep | - | high | - |
| `EndLevel_FrameCounts` | data | `endlevel.asm:685 ($8C8C)` | endlevel: five inclusive last frame indices (35,54,81,91,123) | good | `[static]` | keep | - | high | - |
| `unk_8C96` | data | `endlevel.asm:690 ($8C96)` | endlevel: dead 5x20 text; duplicate of `RaceResults_StrNextLevelShort` | placeholder | `[static]` | rename-later | `EndLevel_StrNextLevelShort` | medium | - |
| `unk_8D02` | data | `endlevel.asm:700 ($8D02)` | endlevel: dead bit-7 ASCII ("You aren't ready for"); duplicate of `RaceResults_StrNotReadyEncoded` | placeholder | `[static]` | rename-later | `EndLevel_StrNotReadyEncoded` | medium | - |
| `unk_8D16` | data | `endlevel.asm:706 ($8D16)` | endlevel: dead text; duplicate of `RaceResults_StrNotReadyTail` | placeholder | `[static]` | rename-later | `EndLevel_StrNotReadyTail` | medium | - |
| `unk_8D52` | data | `endlevel.asm:710 ($8D52)` | endlevel: dead text; duplicate of `RaceResults_StrContinuePlay` | placeholder | `[static]` | rename-later | `EndLevel_StrContinuePlay` | medium | - |
| `unk_8D8A` | data | `endlevel.asm:717 ($8D8A)` | endlevel: dead text; duplicate of `RaceResults_StrNextLevel` | placeholder | `[static]` | rename-later | `EndLevel_StrNextLevel` | medium | - |
| `EndLevel_AnimationScript` | data | `endlevel.asm:727 ($8DC2)` | endlevel: `UpdateAnimation2` script; 123 pointers into the decompressed animation buffer | good | `[static]` | keep | - | high | - |
| `EndLevel_LevelRiderTable` | data | `race_data_tables.asm:101 ($19F12)` | endlevel: 5 levels x 2 quote/portrait records | good | `[static]` | keep | - | high | - |
| `EndLevel_AnimationTiles` | asset | `rom_assets.asm:74 ($80000)` | endlevel: compressed tile set -> VRAM `$5C00` | good | `[static]` | keep | - | high | - |
| `EndLevel_AnimationData` | asset | `rom_assets.asm:77 ($8BF12)` | endlevel: compressed frame stream -> `$5066` bytes in `Intro_ram_ImageBuffer` | good | `[static]` | keep | - | high | - |
| `EndLevel_WindowImage` | asset | `rom_assets.asm:19 ($7F400)` | endlevel: 40x14 window image -> VRAM `$2020`, palette `+$2E4` | good | `[static]` | keep | - | high | - |
| `Intro_TitleScrollTable` | RAM | `ram_const.asm:585 ($FF439C)` | endlevel/rider_intro: H-scroll table `$400` + SAT half `$280` | good | `[static]` | keep | - | high | - |
| `UpdateAnimation2` | routine | `animation.asm:101 ($16926)` | endlevel: build SAT entries without copying tiles | good | `[static]` | keep | - | high | - |
| `Race_SwapFrames` | routine | `race_core.asm:1586 ($BBFE)` | endlevel/race: flip the next HScroll/SAT/HUD/sprite buffers | good | `[static]` | keep | - | high | - |
| `Race_FinishFrame` | routine | `race_core.asm:1644 ($BD24)` | endlevel/race: publish the current frame and flip current buffers | good | `[static]` | keep | - | high | - |
| `Race_ram_NextScrollTable` | RAM | `ram_const.asm:564 ($FF38A4)` | endlevel/race: next H-scroll/SAT base pointer | good | `[static]` | keep | - | high | - |
| `Race_ram_SpriteSize1` | RAM | `ram_const.asm:592 ($FFD32C)` | endlevel/race: sprite-size buffer 1 | good | `[static]` | keep | - | high | - |
| `Race_ram_SpriteSize2` | RAM | `ram_const.asm:593 ($FFD32E)` | endlevel/race: sprite-size buffer 2 | good | `[static]` | keep | - | high | - |
| `Race_ram_SpriteDestination` | RAM | `ram_const.asm:639 ($FFDE5C)` | endlevel/race: sprite destination tile base (`$8680`/`$C680` parity) | narrow | `[static]` | keep | - | medium | - |
| `EndLevel_ram_AnimFrame` | RAM | `ram_const.asm:90 ($FF0D22)` | endlevel: animation frame; `-1` ends the stage | good | `[static]` | keep | - | high | - |
| `EndLevel_ram_SpriteSwapDelay` | RAM | `ram_const.asm:91 ($FF0D24)` | endlevel: swap countdown; reload 5 gives a 6-GameTick DMA period | good | `[static]` | keep | - | high | - |

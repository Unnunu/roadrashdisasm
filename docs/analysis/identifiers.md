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
| `Menu_BuildRaceTooltip` | routine | `menu_main.asm:682` (`$3B56`) | menu_main: race-name + distance tooltip | good | `[static]` | keep | - | high | `U-0001` |
| `MainMenu_HandleInput` | routine | `menu_main.asm:747` (`$3BE2`) | menu_main: newly pressed button actions | good | `[static]` | keep | - | high | - |
| `Menu_DrawRaceSelection` | routine | `menu_main.asm:932` (`$3F18`) | menu_main; menu_password: badge + five-card carousel | good | `[static]` | keep | - | high | `U-0003` |
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
| `img_Gamepad` | asset | `rom_assets.asm` | menu_main: 90 tiles, header 12x9 at `+$B44`, map `+$B48` | narrow | `[static]` | keep | - | medium | `U-0002` |
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
| `Menu_ram_CurrentlyDrawnRaceCard` | RAM | `ram_const.asm` (`$FF05E4`) | menu_main: selected id, then carousel scratch | narrow | `[static]` | rename-later | `Menu_ram_CarouselRaceId` | medium | `U-0003` |
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
| `ram_FF0510` | RAM | `ram_const.asm` (`$FF0510`) | menu_password: A 20-bit password field (`w7..w10`) | placeholder | `[static]` | blocked-unknown | `Player_ram_Field20A` | low | `U-0005` |
| `ram_FF0514` | RAM | `ram_const.asm` (`$FF0514`) | menu_password: B 20-bit password field | placeholder | `[static]` | blocked-unknown | `Player_ram_Field20B` | low | `U-0005` |
| `ram_FF0522` | RAM | `ram_const.asm` (`$FF0522`) | menu_password/intro/race: A 2-bit extra field | placeholder | `[static]` | blocked-unknown | `Player_ram_ExtraA` | low | `U-0004` |
| `ram_FF0524` | RAM | `ram_const.asm` (`$FF0524`) | menu_password/intro/race: B 2-bit extra field | placeholder | `[static]` | blocked-unknown | `Player_ram_ExtraB` | low | `U-0004` |
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
| `ram_FF089A` | RAM | `ram_const.asm` (`$FF089A`) | shop/race_results/message: runtime 5x20 dynamic message record | placeholder | `[static]` | rename-later | `Message_ram_DynamicRecord` | medium | - |
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
| `ram_FF133A` | RAM | `ram_const.asm:102` (`$FF133A`) | road_render/rider_sprites: mirror pass flag (object flags bit15) | placeholder | `[static]` | rename-later | `Road_ram_MirrorFlag` | medium | `U-0007` |
| `ram_FF1366` | RAM | `ram_const.asm:120` (`$FF1366`) | road_render/rider_sprites: tile-budget/SAT chain-end flag | placeholder | `[static]` | rename-later | `Road_ram_ChainEndAlt` | medium | - |

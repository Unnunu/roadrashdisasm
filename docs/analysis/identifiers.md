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
| `Message_MsgArray` | data | `message.asm:334` | menu_main: 8-byte text/show-function entries | good | `[static]` | keep | - | high | - |
| `Menu_dRaceNameTable` | data | `message.asm:460` | menu_main: five race-name text pointers | good | `[static]` | keep | - | high | - |
| `unk_25EC0` | data | `race_track_data.asm:17` | menu_main: five track-record pointers (level-word table at +$00) | placeholder | `[static]` | rename-later | `RaceTrack_dRecords` | medium | - |
| `word_4EEE` | data | `message.asm:560` | menu_main: "Name"/"Password" label record (7x12) | placeholder | `[static]` | rename-later | `Menu_dPasswordLabels` | medium | - |
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
| `Intro_ram_ImageBuffer` | RAM | `ram_const.asm` (`$FF509C`) | menu_main: shared decompression/staging buffer for every asset | narrow | `[static]` | rename-later | `ram_ImageStagingBuffer` | medium | - |
| `Race_ram_ImageBuffer2` | RAM | `ram_const.asm` (`$FF8364`) | menu_main only: badge/card nametable staging (12x42) | misleading | `[static]` | rename-later | `MainMenu_ram_RaceCardBuffer` | medium | - |
| `Menu_ram_FrameBuffer` | RAM | `ram_const.asm` (`$FFB62C`) | menu_main: 64x28 window overlay | good | `[static]` | keep | - | high | - |
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
| `Menu_ram_CurrentMessageId` | RAM | `ram_const.asm` (`$FF05D4`) | menu_main: `Message_MsgArray` byte index (multiple of 8) | good | `[static]` | keep | - | high | - |
| `Menu_ram_CurrentButtonsPtr` | RAM | `ram_const.asm` (`$FF0412`) | menu_main: current pad-state pointer for input handlers | good | `[static]` | keep | - | high | - |
| `Menu_ram_ChangedButtonsPtr` | RAM | `ram_const.asm` (`$FF0416`) | menu_main: edge-mask pointer for input handlers | good | `[static]` | keep | - | high | - |
| `Menu_ram_StrPlayerName` | RAM | `ram_const.asm` (`$FF046A`) | menu_main: scratch text record (name + level), reused for A and B | narrow | `[static]` | rename-later | `Menu_ram_PlayerInfoString` | medium | - |
| `Menu_ram_TempString` | RAM | `ram_const.asm` (`$FF0756`) | menu_main: race-name/distance tooltip record | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_DemoMode` | RAM | `ram_const.asm` (`$FF3692`) | menu_main: set after 30 s idle | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_FrameCounter` | RAM | `ram_const.asm` (`$FF3694`) | menu_main: idle/demo frame counter | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_ButtonsPlayerA` | RAM | `ram_const.asm` (`$FF05C8`) | menu_main: pad A current state | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_ChangedButtonsPlayerA` | RAM | `ram_const.asm` (`$FF05CA`) | menu_main: pad A old XOR new | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_ButtonsPlayerB` | RAM | `ram_const.asm` (`$FF05CC`) | menu_main: pad B current state | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_ChangedButtonsPlayerB` | RAM | `ram_const.asm` (`$FF05CE`) | menu_main: pad B old XOR new | good | `[static]` | keep | - | high | - |
| `MainMenu_ram_CurrentButtons` | RAM | `ram_const.asm` (`$FF05DE`) | menu_main: newly pressed mask being handled | good | `[static]` | keep | - | high | - |
| `Message_ram_ButtonBlinkPeriod` | RAM | `ram_const.asm` (`$FF05E8`) | menu_main: 64-frame button-icon blink period | good | `[static]` | keep | - | high | - |
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
| `MenuPassword_StrPasswordStatus` | RAM | `ram_const.asm` (`$FF067E`) | menu_password: 5x16 status record | good | `[static]` | keep | - | high | - |
| `unk_4E20` | data | `message.asm:540` | menu_password: "PASSWORD INVALID" status template | placeholder | `[static]` | rename-later | `MenuPassword_StrStatusTemplate` | medium | - |
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

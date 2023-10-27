Fade_ram_Timer equ $FF0300
Fade_ram_UpdateFunction equ $FF0302
Fade_ram_CurrentPalette equ $FF0306
Fade_ram_TargetPalette equ $FF0386
ram_FF0406 equ $FF0406
Intro_ram_PlayerAPressedStart equ $FF040A
Intro_ram_PlayerBPressedStart equ $FF040C
Intro_ram_TextTimer equ $FF040E
Intro_ram_CurrentStringOffset equ $FF0410
Menu_ram_CurrentButtonsPtr equ $FF0412
Menu_ram_ChangedButtonsPtr equ $FF0416
MenuPassword_ram_StrPlayerNamePtr equ $FF041A
MenuPassword_ram_StrPlayerPasswordPtr equ $FF041E
MenuPassword_ram_CursorY equ $FF0422
MenuPassword_ram_CursorX equ $FF0424
MenuPassword_ram_HoldTimer equ $FF0426
MenuPassword_ram_HeldButtons equ $FF0428
MenuPassword_ram_StrPlayerAPassword equ $FF042A
MenuPassword_ram_StrPlayerBPassword equ $FF044A
Menu_ram_StringPlayerName equ $FF046A
MenuPassword_ram_StrPlayerAName equ $FF04A4
ram_FF04AA equ $FF04AA
Menu_ram_PlayerAName equ $FF04AC ; size $A
MenuPassword_ram_StrPlayerBName equ $FF04B6
ram_FF04BC equ $FF04BC
Menu_ram_PlayerBName equ $FF04BE
ram_FF04C8 equ $FF04C8
Menu_ram_Player equ $FF0508 ; 0 if Player A else 0xFFFF
ram_FF050A equ $FF050A
Menu_ram_PlayerALevel equ $FF050C
Menu_ram_PlayerBLevel equ $FF050E
ram_FF0510 equ $FF0510
ram_FF0514 equ $FF0514
Menu_ram_MoneyPlayerA equ $FF0518
Menu_ram_MoneyPlayerB equ $FF051C
ram_FF0520 equ $FF0520
ram_FF0522 equ $FF0522
ram_FF0524 equ $FF0524
ram_FF0526 equ $FF0526
ram_FF0528 equ $FF0528
HighScore_ram_PlayerATableOffset equ $FF052A
HighScore_ram_PlayerBTableOffset equ $FF052C
Menu_ram_PlayerAPlaces equ $FF052E ; size $A
Menu_ram_PlayerBPlaces equ $FF0538 ; size $A
Menu_ram_BikeIdPlayerA equ $FF0542
Menu_ram_BikeIdPlayerB equ $FF0544
ram_FF0546 equ $FF0546
ram_FF0566 equ $FF0566
MenuPassword_ram_CurrentButtons equ $FF05C6
MainMenu_ram_ButtonsPlayerA equ $FF05C8
MainMenu_ram_ChangedButtonsPlayerA equ $FF05CA
MainMenu_ram_ButtonsPlayerB equ $FF05CC
MainMenu_ram_ChangedButtonsPlayerB equ $FF05CE
Menu_ram_NextMessageTimer equ $FF05D0
Menu_ram_MessageBlinkTimer equ $FF05D2
Menu_ram_CurrentMessageId equ $FF05D4 ; multiple of 8
ram_MusicEnabled equ $FF05D6
ram_CurrentSong equ $FF05D8
Menu_ram_PlayerMode equ $FF05DA ; 1 - playerA, 2 - playerB, 3 - two players
Menu_ram_CurrentRaceId equ $FF05DC ; multiple of 2
MainMenu_ram_CurrentButtons equ $FF05DE
Menu_PlayerPlacesPtr equ $FF05E0
Menu_ram_CurrentlyDrawnRaceCard equ $FF05E4
Message_ram_ButtonBlinkCounter equ $FF05E6
Message_ram_ButtonBlinkPeriod equ $FF05E8
HighScore_ram_Table equ $FF05EA
ram_FF05F2 equ $FF05F2
MenuPassword_StrPasswordStatus equ $FF067E
ram_FF0682 equ $FF0682
Shop_StrBuyNewBike equ $FF06EA
Menu_ram_TempString equ $FF0756
ram_FF07C2 equ $FF07C2
ram_FF082E equ $FF082E
ram_FF089A equ $FF089A
ram_FF0910 equ $FF0910
ram_FF0914 equ $FF0914
ram_FF0918 equ $FF0918
ram_FF091A equ $FF091A
RaceResults_ram_CurrentButtons equ $FF091C
HighScore_ram_CurrentButtons equ $FF094E
Shop_CurrentBikeId equ $FF0950
ram_FF0952 equ $FF0952
Shop_ScrollPos equ $FF0954
Shop_ImageBike1 equ $FF0956
Shop_ImageBike2 equ $FF0A9A
Shop_ImageBike3 equ $FF0BDE
ram_FF0D22 equ $FF0D22
ram_FF0D24 equ $FF0D24

ram_FF1414 equ $FF1414
ram_FF1418 equ $FF1418
ram_FF141A equ $FF141A

ram_FF1908 equ $FF1908

ram_UpdateFunction equ $FF1A62 ; .l
LogoEA_ram_Finished equ $FF1A66 ; .b or .w ?
ram_FF1AA2 equ $FF1AA2
ram_FF1AA4 equ $FF1AA4
ram_FF1ADA equ $FF1ADA
ram_FF1B1A equ $FF1B1A

ram_FF1E68 equ $FF1E68
ram_FF1EAA equ $FF1EAA
ram_FF26AA equ $FF26AA

ram_FF3048 equ $FF3048
Global_ram_PalettePtr equ $FF305A
Global_ram_Palette equ $FF305E ; size $80

MainMenu_ram_DemoMode equ $FF3692
MainMenu_ram_FrameCounter equ $FF3694
ram_FF3696 equ $FF3696
ram_FF369E equ $FF369E ; .w
ram_FF36B6 equ $FF36B6
ram_FF36B8 equ $FF36B8
ram_FF36BE equ $FF36BE
ram_FF36C0 equ $FF36C0
ram_FF36C4 equ $FF36C4
ram_FF36C6 equ $FF36C6
ram_FF36C8 equ $FF36C8
ram_FF3898 equ $FF3898
ram_FF389C equ $FF389C
ram_FF38A0 equ $FF38A0
ram_FF38A4 equ $FF38A4
ram_FF38A8 equ $FF38A8
ram_FF38AC equ $FF38AC
ram_FF38B4 equ $FF38B4
ram_FF38B8 equ $FF38B8
ram_FF38D0 equ $FF38D0
ram_FF38D4 equ $FF38D4
ram_FF38D8 equ $FF38D8
ram_FF3FDC equ $FF3FDC
ram_FF425C equ $FF425C

Intro_TitleScrollTable equ $FF439C ; size $$380
ram_FF479C equ $FF479C
Intro_TitleScrollSpeed equ $FF4A1C ; size $$380
Intro_ram_ImageBuffer equ $FF509C

ram_FF8364 equ $FF8364

Menu_ram_FrameBuffer equ $FFB62C ; size $E00

ram_FFD32C equ $FFD32C
ram_FFD32E equ $FFD32E
ram_FFD34A equ $FFD34A
ram_FFDE58 equ $FFDE58
ram_FFDE5C equ $FFDE5C
ram_FFDE64 equ $FFDE64


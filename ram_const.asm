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
ram_FF0426 equ $FF0426
ram_FF0428 equ $FF0428
MenuPassword_ram_StrPlayerAPassword equ $FF042A
MenuPassword_ram_StrPlayerBPassword equ $FF044A
Menu_ram_StringPlayerName equ $FF046A
MenuPassword_ram_StrPlayerAName equ $FF04A4
ram_FF04AA equ $FF04AA
Menu_ram_PlayerAName equ $FF04AC ; size $A
MenuPassword_ram_StrPlayerBName equ $FF04B6
ram_FF04BC equ $FF04BC
Menu_ram_PlayerBName equ $FF04BE
Menu_ram_Player equ $FF0508 ; 0 if Player A else 0xFFFF
ram_FF050A equ $FF050A
Menu_ram_PlayerALevel equ $FF050C
Menu_ram_PlayerBLevel equ $FF050E
ram_FF0510 equ $FF0510
ram_FF0514 equ $FF0514
ram_FF0518 equ $FF0518
ram_FF051C equ $FF051C
ram_FF0520 equ $FF0520
ram_FF0522 equ $FF0522
ram_FF0524 equ $FF0524
ram_FF0526 equ $FF0526
ram_FF0528 equ $FF0528
ram_FF052A equ $FF052A
ram_FF052C equ $FF052C
Menu_ram_PlayerAPlaces equ $FF052E ; size $A
Menu_ram_PlayerBPlaces equ $FF0538 ; size $A
ram_FF0542 equ $FF0542
ram_FF0544 equ $FF0544
ram_FF0546 equ $FF0546
ram_FF0566 equ $FF0566
MenuPassword_ram_CurrentButtons equ $FF05C6
MainMenu_ram_ButtonsPlayerA equ $FF05C8
MainMenu_ram_ChangedButtonsPlayerA equ $FF05CA
MainMenu_ram_ButtonsPlayerB equ $FF05CC
MainMenu_ram_ChangedButtonsPlayerB equ $FF05CE
Menu_ram_NextMessageTimer equ $FF05D0
Menu_ram_MessageBlinkTimer equ $FF05D2
Menu_ram_CurrentMessageOffset equ $FF05D4
ram_FF05D6 equ $FF05D6
Menu_MusicEnabled equ $FF05D8
Menu_ram_PlayerMode equ $FF05DA ; 1 - playerA, 2 - playerB, 3 - two players
Menu_ram_CurrentRaceOffset equ $FF05DC
MainMenu_ram_CurrentButtons equ $FF05DE
Menu_PlayerPlacesPtr equ $FF05E0
Menu_ram_CurrentlyDrawnRaceCard equ $FF05E4
ram_FF05E6 equ $FF05E6
ram_FF05E8 equ $FF05E8
ram_FF05EA equ $FF05EA
ram_FF05F2 equ $FF05F2
MenuPassword_StrPasswordStatus equ $FF067E
ram_FF06EA equ $FF06EA
ram_FF0756 equ $FF0756
ram_FF07C2 equ $FF07C2
ram_FF082E equ $FF082E
ram_FF089A equ $FF089A

ram_FF1908 equ $FF1908

ram_UpdateFunction equ $FF1A62 ; .l
LogoEA_ram_Finished equ $FF1A66 ; .b or .w ?
ram_FF1AA2 equ $FF1AA2
ram_FF1AA4 equ $FF1AA4

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
ram_FF389C equ $FF389C

Intro_TitleScrollTable equ $FF439C ; real size $$380, reserved $680
Intro_TitleScrollSpeed equ $FF4A1C ; real size $$380, reserved $680
Intro_ram_ImageBuffer equ $FF509C

ram_FF8364 equ $FF8364

Menu_ram_FrameBuffer equ $FFB62C ; size $E00

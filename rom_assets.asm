; *************************************************
; rom_assets.asm - labelled ROM asset tail ($7EA66-$BFFFF)
; Split at known asset starts; bytes are raw from baserom.md.
; *************************************************

RomTail: ; $7EA66
unk_7EA66 equ RomTail
    binclude "baserom.md",$7EA66,$0010C

ImgHighScoreBadge: ; $7EB72
    binclude "baserom.md",$7EB72,$001F4

unk_7ED66: ; $7ED66
    binclude "baserom.md",$7ED66,$002C6

img_MainMenu_RaceSelectionBackground: ; $7F02C
    binclude "baserom.md",$7F02C,$003D4

EndLevel_WindowImage: ; $7F400
    binclude "baserom.md",$7F400,$00434

img_Gamepad: ; $7F834
    binclude "baserom.md",$7F834,$00764

Boot_CheckRomChecksum: ; $7FF98
    binclude "baserom.md",$7FF98,$00068

EndLevel_AnimationTiles: ; $80000
    binclude "baserom.md",$80000,$0BF12

EndLevel_AnimationData: ; $8BF12
    binclude "baserom.md",$8BF12,$025D4

RaceResults_TrackImage_0: ; $8E4E6
    binclude "baserom.md",$8E4E6,$02EB0

RaceResults_TrackImage_1: ; $91396
    binclude "baserom.md",$91396,$02C5C

RaceResults_TrackImage_2: ; $93FF2
    binclude "baserom.md",$93FF2,$03198

RaceResults_TrackImage_3: ; $9718A
    binclude "baserom.md",$9718A,$01A94

RaceResults_TrackImage_4: ; $98C1E
    binclude "baserom.md",$98C1E,$026D2

unk_9B2F0: ; $9B2F0
    binclude "baserom.md",$9B2F0,$001A4

unk_9B494: ; $9B494
    binclude "baserom.md",$9B494,$00312

unk_9B7A6: ; $9B7A6
    binclude "baserom.md",$9B7A6,$000F8

unk_9B89E: ; $9B89E
    binclude "baserom.md",$9B89E,$00F8C

unk_9C82A: ; $9C82A
    binclude "baserom.md",$9C82A,$01240

unk_9DA6A: ; $9DA6A
    binclude "baserom.md",$9DA6A,$000FE

unk_9DB68: ; $9DB68
    binclude "baserom.md",$9DB68,$000E4

unk_9DC4C: ; $9DC4C
    binclude "baserom.md",$9DC4C,$00180

unk_9DDCC: ; $9DDCC
    binclude "baserom.md",$9DDCC,$005D6

unk_9E3A2: ; $9E3A2
    binclude "baserom.md",$9E3A2,$003E2

ImgShopArrowLeft: ; $9E784
    binclude "baserom.md",$9E784,$000F0

ImgShopArrowRight: ; $9E874
    binclude "baserom.md",$9E874,$001AA

ImgShopBike1: ; $9EA1E
    binclude "baserom.md",$9EA1E,$013C0

ImgShopBike2: ; $9FDDE
    binclude "baserom.md",$9FDDE,$0144C

ImgShopBike3: ; $A122A
    binclude "baserom.md",$A122A,$014E2

img_mainMenu_PlayerSelection: ; $A270C
    binclude "baserom.md",$A270C,$000C8

img_Intro_Font: ; $A27D4
    binclude "baserom.md",$A27D4,$003D6

FontHighScoreTable: ; $A2BAA
    binclude "baserom.md",$A2BAA,$002BE

unk_A2E68: ; $A2E68
    binclude "baserom.md",$A2E68,$000F4

ImgHighScoreTitle: ; $A2F5C
    binclude "baserom.md",$A2F5C,$0084E

img_MainMenu_RaceBadges: ; $A37AA
    binclude "baserom.md",$A37AA,$00CEE

img_mainMenu_RaceCards: ; $A4498
    binclude "baserom.md",$A4498,$0328A

img_PasswordMenu_PlayerSelection: ; $A7722
    binclude "baserom.md",$A7722,$00112

img_Intro_Background: ; $A7834
    binclude "baserom.md",$A7834,$051CC

img_Intro_Title: ; $ACA00
    binclude "baserom.md",$ACA00,$01ECE

img_MainMenu_Background: ; $AE8CE
    binclude "baserom.md",$AE8CE,$0099E

unk_AF26C: ; $AF26C
    binclude "baserom.md",$AF26C,$00696

unk_AF902: ; $AF902
RiderIntro_Portrait_0 equ unk_AF902
    binclude "baserom.md",$AF902,$01C04

unk_B1506: ; $B1506
    binclude "baserom.md",$B1506,$009DC

RiderIntro_Portrait_1: ; $B1EE2
    binclude "baserom.md",$B1EE2,$01664

RiderIntro_Portrait_2: ; $B3546
    binclude "baserom.md",$B3546,$01386

RiderIntro_Portrait_3: ; $B48CC
    binclude "baserom.md",$B48CC,$0178A

RiderIntro_Portrait_4: ; $B6056
    binclude "baserom.md",$B6056,$01366

RiderIntro_Portrait_5: ; $B73BC
    binclude "baserom.md",$B73BC,$0147E

RiderIntro_Portrait_6: ; $B883A
    binclude "baserom.md",$B883A,$01732

RiderIntro_Portrait_7: ; $B9F6C
    binclude "baserom.md",$B9F6C,$01880

RiderIntro_Portrait_8: ; $BB7EC
    binclude "baserom.md",$BB7EC,$01878

RiderIntro_Portrait_9: ; $BD064
    binclude "baserom.md",$BD064,$015C4

RiderIntro_Portrait_10: ; $BE628
    binclude "baserom.md",$BE628,$019D8


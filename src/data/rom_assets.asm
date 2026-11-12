; *************************************************
; rom_assets.asm - labelled ROM asset tail ($7EA66-$BFFFF)
; Split at known asset starts; bytes are raw from baserom.md.
; *************************************************

RomTail: ; $7EA66
RiderIntro_PortraitPanel equ RomTail
    binclude "assets/images/result_panel/data.bin"

ImgHighScoreBadge: ; $7EB72
    binclude "assets/images/highscore_badge/data.bin"

RaceResults_BustedTitleTiles: ; $7ED66
    binclude "assets/images/results_busted/data.bin"

img_MainMenu_RaceSelectionBackground: ; $7F02C
    binclude "assets/images/menu_race_selection_background/data.bin"

EndLevel_WindowImage: ; $7F400
    binclude "assets/images/endlevel_window/data.bin"

img_Gamepad: ; $7F834
    binclude "assets/images/gamepad/data.bin"

; *****
; Function Boot_CheckRomChecksum
; Sums the ROM bytes (skipping the checksum long at $18C), compares $FE407B8A;
; on mismatch programs the VDP for a solid screen and loops forever.
; In:  -
; Out: returns on match, hangs on mismatch
; Clobbers: d0/d1/d2/a0/a4
; *****

Boot_CheckRomChecksum: ; $7FF98
                moveq       #$0,d0
                suba.l      a0,a0
                move.l      #$1FFE6,d1
loc_7FFA2:
                cmpa.w      #$18C,a0
                bne.s       loc_7FFAC
                addq.w      #$4,a0
                bra.s       loc_7FFAE
loc_7FFAC:
                add.l       (a0)+,d0
loc_7FFAE:
                subq.l      #$1,d1
                bgt.s       loc_7FFA2
                movea.l     #$80001,a0
                move.l      #$20000,d1
                moveq       #$0,d2
loc_7FFC0:
                move.b      (a0),d2
                add.l       d2,d0
                addq.w      #$2,a0
                subq.l      #$1,d1
                bgt.s       loc_7FFC0
                cmp.l       #$FE407B8A,d0
                bne.s       loc_7FFD4
                rts
loc_7FFD4:
                movea.l     #$C00004,a4
                move.w      #$8F02,(a4)
                move.w      #$8004,(a4)
                move.w      #$8700,(a4)
                move.w      #$8144,(a4)
                move.w      #$C000,(a4)
                move.w      #$3F,d1
loc_7FFF2:
                move.w      #$E,(VdpData).l
                dbf         d1,loc_7FFF2
loc_7FFFE:
                bra.s       loc_7FFFE

EndLevel_AnimationTiles: ; $80000
    binclude "assets/tilesets/endlevel_animation_tiles/data.bin"

EndLevel_AnimationData: ; $8BF12
    binclude "assets/raw/endlevel_animation_data/data.bin"

RaceResults_TrackImage_0: ; $8E4E6
    binclude "assets/images/results_track_0/data.bin"

RaceResults_TrackImage_1: ; $91396
    binclude "assets/images/results_track_1/data.bin"

RaceResults_TrackImage_2: ; $93FF2
    binclude "assets/images/results_track_2/data.bin"

RaceResults_TrackImage_3: ; $9718A
    binclude "assets/images/results_track_3/data.bin"

RaceResults_TrackImage_4: ; $98C1E
    binclude "assets/images/results_track_4/data.bin"

unk_9B2F0: ; $9B2F0
    binclude "assets/maps/race_map_0/data.bin"

unk_9B494: ; $9B494
    binclude "assets/tilesets/race_tiles_0/data.bin"

unk_9B7A6: ; $9B7A6
    binclude "assets/maps/race_map_1/data.bin"

unk_9B89E: ; $9B89E
    binclude "assets/images/race_image_0/data.bin"

unk_9C82A: ; $9C82A
    binclude "assets/images/race_hud/data.bin"

unk_9DA6A: ; $9DA6A
    binclude "assets/tilesets/race_tiles_1/data.bin"

unk_9DB68: ; $9DB68
    binclude "assets/tilesets/race_tiles_2/data.bin"

unk_9DC4C: ; $9DC4C
    binclude "assets/tilesets/race_tiles_3/data.bin"

unk_9DDCC: ; $9DDCC
    binclude "assets/tilesets/race_road/data.bin"

unk_9E3A2: ; $9E3A2
    binclude "assets/tilesets/race_tiles_4/data.bin"

ImgShopArrowLeft: ; $9E784
    binclude "assets/images/shop_arrow_left/data.bin"

ImgShopArrowRight: ; $9E874
    binclude "assets/images/shop_arrow_right/data.bin"

ImgShopBike1: ; $9EA1E
    binclude "assets/images/shop_bike_1/data.bin"

ImgShopBike2: ; $9FDDE
    binclude "assets/images/shop_bike_2/data.bin"

ImgShopBike3: ; $A122A
    binclude "assets/images/shop_bike_3/data.bin"

img_mainMenu_PlayerSelection: ; $A270C
    binclude "assets/images/menu_player_selection/data.bin"

img_Intro_Font: ; $A27D4
    binclude "assets/tilesets/intro_font/data.bin"

FontHighScoreTable: ; $A2BAA
    binclude "assets/tilesets/highscore_font/data.bin"

unk_A2E68: ; $A2E68
    binclude "assets/tilesets/highscore_extra/data.bin"

ImgHighScoreTitle: ; $A2F5C
    binclude "assets/images/highscore_title/data.bin"

img_MainMenu_RaceBadges: ; $A37AA
    binclude "assets/images/menu_race_badges/data.bin"

img_mainMenu_RaceCards: ; $A4498
    binclude "assets/images/menu_race_cards/data.bin"

img_PasswordMenu_PlayerSelection: ; $A7722
    binclude "assets/images/password_player_selection/data.bin"

img_Intro_Background: ; $A7834
    binclude "assets/images/intro_background/data.bin"

img_Intro_Title: ; $ACA00
    binclude "assets/images/intro_title/data.bin"

img_MainMenu_Background: ; $AE8CE
    binclude "assets/images/menu_background/data.bin"

RaceResults_TitleTiles: ; $AF26C
    binclude "assets/tilesets/results_image_extra/data.bin"

unk_AF902: ; $AF902
RiderIntro_Portrait_0 equ unk_AF902
    binclude "assets/images/portrait_0/data.bin"

unk_B1506: ; $B1506
    binclude "assets/images/intro_natasha_overlay/data.bin"

RiderIntro_Portrait_1: ; $B1EE2
    binclude "assets/images/portrait_1/data.bin"

RiderIntro_Portrait_2: ; $B3546
    binclude "assets/images/portrait_2/data.bin"

RiderIntro_Portrait_3: ; $B48CC
    binclude "assets/images/portrait_3/data.bin"

RiderIntro_Portrait_4: ; $B6056
    binclude "assets/images/portrait_4/data.bin"

RiderIntro_Portrait_5: ; $B73BC
    binclude "assets/images/portrait_5/data.bin"

RiderIntro_Portrait_6: ; $B883A
    binclude "assets/images/portrait_6/data.bin"

RiderIntro_Portrait_7: ; $B9F6C
    binclude "assets/images/portrait_7/data.bin"

RiderIntro_Portrait_8: ; $BB7EC
    binclude "assets/images/portrait_8/data.bin"

RiderIntro_Portrait_9: ; $BD064
    binclude "assets/images/portrait_9/data.bin"

RiderIntro_Portrait_10: ; $BE628
    binclude "assets/images/portrait_10/data.bin"


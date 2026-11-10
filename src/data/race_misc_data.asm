; *************************************************
; race_misc_data.asm - tables/scripts between the road shapes and top_level
; ROM range: $7DCA8-$7E6A1; included from main.asm.
; *************************************************

; unk_7DCA8: 16-bit lookup table (sine-like) used by race_ai sub_112C8.
unk_7DCA8:
    binclude "baserom.md",$7DCA8,$0202

; RaceHud_NeedleScript: HUD speed/RPM needle animation script (tilemap + frame table).
; HUD speed/RPM needle animation script (32 frame pointers, max index $1F).
RaceHud_NeedleTilemap equ $7E070
RaceHud_NeedleFrame_0 equ $7DF30
RaceHud_NeedleFrame_1 equ $7DF3A
RaceHud_NeedleFrame_2 equ $7DF44
RaceHud_NeedleFrame_3 equ $7DF4E
RaceHud_NeedleFrame_4 equ $7DF58
RaceHud_NeedleFrame_5 equ $7DF62
RaceHud_NeedleFrame_6 equ $7DF6C
RaceHud_NeedleFrame_7 equ $7DF76
RaceHud_NeedleFrame_8 equ $7DF80
RaceHud_NeedleFrame_9 equ $7DF8A
RaceHud_NeedleFrame_10 equ $7DF94
RaceHud_NeedleFrame_11 equ $7DF9E
RaceHud_NeedleFrame_12 equ $7DFA8
RaceHud_NeedleFrame_13 equ $7DFB2
RaceHud_NeedleFrame_14 equ $7DFBC
RaceHud_NeedleFrame_15 equ $7DFC6
RaceHud_NeedleFrame_16 equ $7DFD0
RaceHud_NeedleFrame_17 equ $7DFDA
RaceHud_NeedleFrame_18 equ $7DFE4
RaceHud_NeedleFrame_19 equ $7DFEE
RaceHud_NeedleFrame_20 equ $7DFF8
RaceHud_NeedleFrame_21 equ $7E002
RaceHud_NeedleFrame_22 equ $7E00C
RaceHud_NeedleFrame_23 equ $7E016
RaceHud_NeedleFrame_24 equ $7E020
RaceHud_NeedleFrame_25 equ $7E02A
RaceHud_NeedleFrame_26 equ $7E034
RaceHud_NeedleFrame_27 equ $7E03E
RaceHud_NeedleFrame_28 equ $7E048
RaceHud_NeedleFrame_29 equ $7E052
RaceHud_NeedleFrame_30 equ $7E05C
RaceHud_NeedleFrame_31 equ $7E066
RaceHud_NeedleScript:
    dc.l    RaceHud_NeedleTilemap
    dc.w    $001F
    dc.l    RaceHud_NeedleFrame_0
    dc.l    RaceHud_NeedleFrame_1
    dc.l    RaceHud_NeedleFrame_2
    dc.l    RaceHud_NeedleFrame_3
    dc.l    RaceHud_NeedleFrame_4
    dc.l    RaceHud_NeedleFrame_5
    dc.l    RaceHud_NeedleFrame_6
    dc.l    RaceHud_NeedleFrame_7
    dc.l    RaceHud_NeedleFrame_8
    dc.l    RaceHud_NeedleFrame_9
    dc.l    RaceHud_NeedleFrame_10
    dc.l    RaceHud_NeedleFrame_11
    dc.l    RaceHud_NeedleFrame_12
    dc.l    RaceHud_NeedleFrame_13
    dc.l    RaceHud_NeedleFrame_14
    dc.l    RaceHud_NeedleFrame_15
    dc.l    RaceHud_NeedleFrame_16
    dc.l    RaceHud_NeedleFrame_17
    dc.l    RaceHud_NeedleFrame_18
    dc.l    RaceHud_NeedleFrame_19
    dc.l    RaceHud_NeedleFrame_20
    dc.l    RaceHud_NeedleFrame_21
    dc.l    RaceHud_NeedleFrame_22
    dc.l    RaceHud_NeedleFrame_23
    dc.l    RaceHud_NeedleFrame_24
    dc.l    RaceHud_NeedleFrame_25
    dc.l    RaceHud_NeedleFrame_26
    dc.l    RaceHud_NeedleFrame_27
    dc.l    RaceHud_NeedleFrame_28
    dc.l    RaceHud_NeedleFrame_29
    dc.l    RaceHud_NeedleFrame_30
    dc.l    RaceHud_NeedleFrame_31

; frame/tilemap data ($7DF30-$7E36F)
RaceHud_NeedleData:
    binclude "baserom.md",$7DF30,$0440

; Shop_BikePalettes: 8 bike palettes x 32 bytes.
Shop_BikePalettes:
    binclude "assets/palettes/shop_bike_palettes/data.bin"

; unk_7E470: actor palettes, 16 x 32 bytes (Race_LoadActorPalette).
unk_7E470:
    binclude "assets/palettes/actor_palettes/data.bin"

; unk_7E670: 5 track-image pointers used by race_results.
unk_7E670:
    dc.l    RaceResults_TrackImage_0
    dc.l    RaceResults_TrackImage_1
    dc.l    RaceResults_TrackImage_2
    dc.l    RaceResults_TrackImage_3
    dc.l    RaceResults_TrackImage_4

; unk_7E684/68E/698: per-track 5-word image/nametable/palette offsets (race_results).
unk_7E684:
    binclude "baserom.md",$7E684,$000A
unk_7E68E:
    binclude "baserom.md",$7E68E,$000A
unk_7E698:
    binclude "baserom.md",$7E698,$000A

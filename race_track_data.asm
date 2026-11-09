; *************************************************
; race_track_data.asm - per-track records and data streams from the ROM gap
; ROM range: $25EC0-$3BF19; included from main.asm.
;
; unk_25EC0[5] -> track record (0x18):
;   +$00 level word table ptr (5 words: levels 1..5)
;   +$04 RaceTrack_Data2 (track decoder stream)
;   +$08 RaceTrack_Data3 (track decoder stream)
;   +$0C RaceTrack_Data4
;   +$10 RaceTrack_Data5 (spawn data)
;   +$14 RaceTrack_Data6
; The level table (5 words) immediately follows the record; the streams are
; stored in memory order Data2,Data3,Data4,Data6,Data5 (sizes from the next
; boundary). Stream contents are opaque/compressed and included from baserom.md.
; *************************************************

unk_25EC0:
    dc.l    $00025ED4 ; track 0 record
    dc.l    $0002A770 ; track 1 record
    dc.l    $0002E6F0 ; track 2 record
    dc.l    $000325DC ; track 3 record
    dc.l    $00036732 ; track 4 record

; track 0: record @$025ED4, level words @$025EEC
Track_Record0:
    dc.l    $00025EEC
    dc.l    $00025EF6
    dc.l    $000269F8
    dc.l    $00027984
    dc.l    $0002A594
    dc.l    $00028A3E
Track_LevelWords0:
    dc.w    $073F,$0A0A,$0D5C,$104A,$13F6
Track_Data2_0: ; $025EF6-$0269F8 (2818 bytes)
    binclude "baserom.md",$025EF6,$000B02
Track_Data3_0: ; $0269F8-$027984 (3980 bytes)
    binclude "baserom.md",$0269F8,$000F8C
Track_Data4_0: ; $027984-$028A3E (4282 bytes)
    binclude "baserom.md",$027984,$0010BA
Track_Data6_0: ; $028A3E-$02A594 (6998 bytes)
    binclude "baserom.md",$028A3E,$001B56
Track_Data5_0: ; $02A594-$02A770 (476 bytes)
    binclude "baserom.md",$02A594,$0001DC

; track 1: record @$02A770, level words @$02A788
Track_Record1:
    dc.l    $0002A788
    dc.l    $0002A792
    dc.l    $0002B06E
    dc.l    $0002C002
    dc.l    $0002E4D4
    dc.l    $0002CC8C
Track_LevelWords1:
    dc.w    $06F4,$0A1E,$0D48,$12AC,$13C4
Track_Data2_1: ; $02A792-$02B06E (2268 bytes)
    binclude "baserom.md",$02A792,$0008DC
Track_Data3_1: ; $02B06E-$02C002 (3988 bytes)
    binclude "baserom.md",$02B06E,$000F94
Track_Data4_1: ; $02C002-$02CC8C (3210 bytes)
    binclude "baserom.md",$02C002,$000C8A
Track_Data6_1: ; $02CC8C-$02E4D4 (6216 bytes)
    binclude "baserom.md",$02CC8C,$001848
Track_Data5_1: ; $02E4D4-$02E6F0 (540 bytes)
    binclude "baserom.md",$02E4D4,$00021C

; track 2: record @$02E6F0, level words @$02E708
Track_Record2:
    dc.l    $0002E708
    dc.l    $0002E712
    dc.l    $0002F0F8
    dc.l    $0003005A
    dc.l    $00032384
    dc.l    $000311B8
Track_LevelWords2:
    dc.w    $0712,$0A32,$0D52,$1090,$136A
Track_Data2_2: ; $02E712-$02F0F8 (2534 bytes)
    binclude "baserom.md",$02E712,$0009E6
Track_Data3_2: ; $02F0F8-$03005A (3938 bytes)
    binclude "baserom.md",$02F0F8,$000F62
Track_Data4_2: ; $03005A-$0311B8 (4446 bytes)
    binclude "baserom.md",$03005A,$00115E
Track_Data6_2: ; $0311B8-$032384 (4556 bytes)
    binclude "baserom.md",$0311B8,$0011CC
Track_Data5_2: ; $032384-$0325DC (600 bytes)
    binclude "baserom.md",$032384,$000258

; track 3: record @$0325DC, level words @$0325F4
Track_Record3:
    dc.l    $000325F4
    dc.l    $000325FE
    dc.l    $00033190
    dc.l    $00034072
    dc.l    $00036426
    dc.l    $00035174
Track_LevelWords3:
    dc.w    $076C,$0A0A,$0D34,$104A,$1342
Track_Data2_3: ; $0325FE-$033190 (2962 bytes)
    binclude "baserom.md",$0325FE,$000B92
Track_Data3_3: ; $033190-$034072 (3810 bytes)
    binclude "baserom.md",$033190,$000EE2
Track_Data4_3: ; $034072-$035174 (4354 bytes)
    binclude "baserom.md",$034072,$001102
Track_Data6_3: ; $035174-$036426 (4786 bytes)
    binclude "baserom.md",$035174,$0012B2
Track_Data5_3: ; $036426-$036732 (780 bytes)
    binclude "baserom.md",$036426,$00030C

; track 4: record @$036732, level words @$03674A
Track_Record4:
    dc.l    $0003674A
    dc.l    $00036754
    dc.l    $0003706A
    dc.l    $00038056
    dc.l    $0003BD4A
    dc.l    $0003A2E0
Track_LevelWords4:
    dc.w    $06B3,$0A1E,$0D48,$107C,$1360
Track_Data2_4: ; $036754-$03706A (2326 bytes)
    binclude "baserom.md",$036754,$000916
Track_Data3_4: ; $03706A-$038056 (4076 bytes)
    binclude "baserom.md",$03706A,$000FEC
Track_Data4_4: ; $038056-$03A2E0 (8842 bytes)
    binclude "baserom.md",$038056,$00228A
Track_Data6_4: ; $03A2E0-$03BD4A (6762 bytes)
    binclude "baserom.md",$03A2E0,$001A6A
Track_Data5_4: ; $03BD4A-$03BF1A (464 bytes)
    binclude "baserom.md",$03BD4A,$0001D0

; *************************************************
; Function Intro_Init
; *************************************************

Intro_Init:
                move.w  #0,(Intro_ram_PlayerAPressedStart).l
                move.w  #0,(Intro_ram_PlayerBPressedStart).l
                move.w  #180,(Intro_ram_TextTimer).l ; 3 seconds
                move.w  #0,(Intro_ram_CurrentStringOffset).l
                lea     (VdpCtrl).l,a0
                move.w  #$8004,(a0) ; H-ints off, left column unblanked, HV counter normal (display enabled by $8174 below)
                move.w  #$8174,(a0) ; Display enabled, V-ints enabled, Height: 28, Mode 5, 64K VRAM
                move.w  #$8210,(a0) ; Scroll A Name Table:    $4000
                move.w  #$8401,(a0) ; Scroll B Name Table:    $2000
                move.w  #$8530,(a0) ; Sprite Attribute Table: $6000
                move.w  #$8701,(a0) ; Backdrop Color: $1
                move.w  #$8AFF,(a0) ; H-Int Counter: 255
                move.w  #$8B03,(a0) ; E-ints disabled, V-Scroll: full, H-Scroll: line
                move.w  #$8C81,(a0) ; Width: 40, Shadow/Highlight: disabled
                move.w  #$8D1C,(a0) ; HScroll Data Table:     $7000
                move.w  #$8F02,(a0) ; Auto-increment: $2
                move.w  #$9003,(a0) ; Scroll A/B Size: 128x32
                move.w  #$9100,(a0) ; Window X: 0
                move.w  #$9200,(a0) ; Window Y: 0
                VDP_VRAM_WRITE $6000,(a0) ; write to sprite table
                move.l  #0,(VdpData).l ;  clear sprites
                VDP_VSRAM_WRITE $0,(a0) ; write to vsram 0
                move.l  #0,(VdpData).l ; clear vscroll
                move.l  #Global_ram_Palette,(Global_ram_PalettePtr).l
; load background image into ram
                lea     (img_Intro_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write background image into VRAM address $8000
                move.l  #$8000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; create nametable for title
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; first tile index, address = $8000
                move.w  #$2000,d5 ; VRAM address = Scroll B
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer + $3568).l,a0 ; source
                jsr     (WriteNametable).l
; copy title palette
                lea     (Intro_ram_ImageBuffer + $34E4).l,a0
                movea.l (Global_ram_PalettePtr).l,a1
                move.w  #$1F,d0
.loc_17E8:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_17E8
; load title image into ram
                lea     (img_Intro_Title).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write title image into VRAM address $E000
                move.l  #$E000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; draw title ?
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$700,d4 ; first tile index, address = $E000
                move.w  #$4000,d5 ; VRAM address = Scroll A
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer + $11A8).l,a0
                jsr     (WriteNametable).l
; fill the off-screen right part of the 128-cell plane (needed by the per-line H-scroll)
                move.w  #88,d0 ; width
                move.w  #6,d1 ; height
                move.w  #40,d2 ; x
                move.w  #18,d3 ; y
                move.w  #$700,d4 ; first tile index, address = $E000
                move.w  #$4000,d5 ; VRAM address = Scroll A
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer + $11A8).l,a0
                jsr     (WriteNametable).l
; load font image into ram
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write font image into VRAM address $0
                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; load first string
                movea.l (Intro_dStringTable).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).l
; print string
                movea.l (Intro_dStringTable).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; first tile index, address = $6000
                move.w  #$4000,d5 ; VRAM address = Scroll A
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteNametable).l
; clear first 150 lines in hscroll
                lea     (Intro_TitleScrollTable).l,a2
                lea     (Intro_TitleScrollSpeed).l,a3
                move.w  #149,d0
.clearHScroll:
                move.l  #0,(a2)+
                move.l  #0,(a3)+
                dbf     d0,.clearHScroll

                lea     (Intro_TitleScrollTable + $2F8).l,a2 ; Y = 190
                lea     (Intro_TitleScrollSpeed + $2F8).l,a3
                move.w  #39,d0 ; repeat for 40 lines
                move.l  #$1900000,d1 ; scroll value on line 189 : 400 (completely out of screen)
                moveq   #0,d2 ; delta between consecutive lines
.loopTitleScroll:
                move.l  d1,d3 ; copy scroll value
                clr.w   d3 ; clear lower word so bg scroll is zero
                move.l  d3,-(a2) ; set scroll value
                move.l  #$C0000,-(a3) ; set speed 12
                add.l   d2,d1 ; add to scroll value
                addi.l  #$2000,d2 ; increment delta by 1/8 of pixel
                dbf     d0,.loopTitleScroll
; clear lines from 190 to 224 in hscroll
                lea     (Intro_TitleScrollTable + $2F8).l,a2 ; line 190
                lea     (Intro_TitleScrollSpeed + $2F8).l,a3
                move.w  #33,d0
.clearHScroll2:
                move.l  #0,(a2)+
                move.l  #0,(a3)+
                dbf     d0,.clearHScroll2
; write HScroll table to VRAM
                move.l  #Intro_TitleScrollTable,d0
                move.w  #$7000,d1 ; write HScroll table
                move.w  #$1C0,d2 ; size in words
                jsr     (DmaWriteVRAM).l

                moveq   #1,d0
                move.w  d0,(ram_CurrentSong).l
                jsr     (AudioFunc3).l
; create String "Player A  " on the left
                lea     (Menu_DefaultName).l,a0
                lea     (MenuPassword_ram_StrPlayerAName).l,a1
                move.w  #9,(a1)+ ; y
                move.w  #5,(a1)+ ; x
                move.w  #1,(a1)+ ; height
                move.w  #10,(a1)+ ; width
                move.w  #4,d0
.loc_1972:
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_1972
; create String "Player A  " on the right
                lea     (Menu_DefaultName).l,a0
                lea     (MenuPassword_ram_StrPlayerBName).l,a1
                move.w  #9,(a1)+ ; y
                move.w  #25,(a1)+ ; x
                move.w  #1,(a1)+ ; height
                move.w  #10,(a1)+ ; width
                move.w  #4,d0
.loc_1998:
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_1998

                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a0
                addq.b  #1,7(a0)
                move.w  #(20*5),(HighScore_ram_PlayerATableOffset).l
                move.w  #(20*6),(HighScore_ram_PlayerBTableOffset).l
; create text of demo highscore table
                lea     (unk_4C18).l,a0
                lea     (HighScore_ram_Table).l,a1
                move.w  #22,(a1)+ ; y
                move.w  #16,(a1)+ ; x
                move.w  #7,(a1)+ ; height
                move.w  #20,(a1)+ ; width
                move.w  #34,d0
.loc_19D8:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_19D8

                move.w  #0,(Menu_ram_CurrentTrackId).l
                move.w  #1,(Menu_ram_PlayerMode).l ; player mode : player A
                move.w  #1,(Menu_ram_PlayerLevel).l
                move.w  #0,(ram_FF0520).l
                move.w  #0,(Menu_ram_Player).l
                bsr.w   sub_1A2C
                bsr.w   sub_1B48
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l
                jsr     (Rand_Init).l
                jsr     (sub_16088).l
                move.w  #1,(ram_MusicEnabled).l
                rts
; End of function Intro_Init

; *************************************************
; Function sub_1A2C
; *************************************************

sub_1A2C:
                move.w  #(20*5),(HighScore_ram_PlayerATableOffset).l
                cmpi.w  #(20*5),(HighScore_ram_PlayerBTableOffset).l
                bne.w   .loc_1A48
                move.w  #(20*6),(HighScore_ram_PlayerATableOffset).l
.loc_1A48:
                lea     (unk_4C18 + 8).l,a0
                adda.w  #(20*5),a0
                lea     (ram_FF05F2).l,a1
                adda.w  (HighScore_ram_PlayerATableOffset).l,a1
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a0
                move.w  #4,d0
.loc_1A68:
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_1A68
                move.l  #'    ',(a1)+
                move.l  #'    ',(a1)+
                move.w  #'$0',(a1)+

                lea     (Menu_DefaultPassword).l,a0
                lea     (MenuPassword_ram_StrPlayerAPassword).l,a1
                move.w  #15,(a1)+
                move.w  #4,(a1)+
                move.w  #2,(a1)+
                move.w  #12,(a1)+
                move.w  #5,d0
.loc_1A9E:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_1A9E

                move.w  #1,(Menu_ram_PlayerALevel).l
                move.w  #0,(ram_FF0526).l
                move.w  #0,(ram_FF0522).l
                move.l  #0,(ram_FF0510).l
                move.l  #100,(Menu_ram_MoneyPlayerA).l
                move.w  #0,(Menu_ram_BikeIdPlayerA).l
                move.w  #0,(Menu_ram_PlayerAPlaces + 0).l
                move.w  #0,(Menu_ram_PlayerAPlaces + 2).l
                move.w  #0,(Menu_ram_PlayerAPlaces + 4).l
                move.w  #0,(Menu_ram_PlayerAPlaces + 6).l
                move.w  #0,(Menu_ram_PlayerAPlaces + 8).l
                lea     (Menu_ram_PlayerAOpponents).l,a0
                move.w  #$4B,(a0)+
                move.w  #0,(a0)+
                move.w  #1,(a0)+
                move.w  #2,(a0)+
                move.w  #3,(a0)+
                move.w  #4,(a0)+
                move.w  #5,(a0)+
                move.w  #6,(a0)+
                move.w  #7,(a0)+
                move.w  #8,(a0)+
                move.w  #9,(a0)+
                move.w  #$A,(a0)+
                move.w  #$B,(a0)+
                move.w  #$C,(a0)+
                move.w  #$D,(a0)+
                move.w  #$E,(a0)+
                rts
; End of function sub_1A2C

; *************************************************
; Function sub_1B48
; *************************************************

sub_1B48:
                move.w  #(20*5),(HighScore_ram_PlayerBTableOffset).l
                cmpi.w  #(20*5),(HighScore_ram_PlayerATableOffset).l
                bne.w   .loc_1B64
                move.w  #(20*6),(HighScore_ram_PlayerBTableOffset).l
.loc_1B64:
                lea     (unk_4C18 + 8).l,a0
                adda.w  #(20*5),a0
                lea     (ram_FF05F2).l,a1
                adda.w  (HighScore_ram_PlayerBTableOffset).l,a1
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a0
                move.w  #4,d0

.loc_1B84:
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_1B84
                move.l  #'    ',(a1)+
                move.l  #'    ',(a1)+
                move.w  #'$0',(a1)+
                lea     (Menu_DefaultPassword).l,a0
                lea     (MenuPassword_ram_StrPlayerBPassword).l,a1

                move.w  #15,(a1)+
                move.w  #24,(a1)+
                move.w  #2,(a1)+
                move.w  #12,(a1)+
                move.w  #5,d0
.loc_1BBA:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_1BBA

                move.w  #1,(Menu_ram_PlayerBLevel).l
                move.w  #0,(ram_FF0528).l
                move.w  #0,(ram_FF0524).l
                move.l  #0,(ram_FF0514).l
                move.l  #100,(Menu_ram_MoneyPlayerB).l
                move.w  #0,(Menu_ram_BikeIdPlayerB).l
                move.w  #0,(Menu_ram_PlayerBPlaces + 0).l
                move.w  #0,(Menu_ram_PlayerBPlaces + 2).l
                move.w  #0,(Menu_ram_PlayerBPlaces + 4).l
                move.w  #0,(Menu_ram_PlayerBPlaces + 6).l
                move.w  #0,(Menu_ram_PlayerBPlaces + 8).l
                lea     (Menu_ram_PlayerBOpponents).l,a0
                move.w  #$4B,(a0)+
                move.w  #0,(a0)+
                move.w  #1,(a0)+
                move.w  #2,(a0)+
                move.w  #3,(a0)+
                move.w  #4,(a0)+
                move.w  #5,(a0)+
                move.w  #6,(a0)+
                move.w  #7,(a0)+
                move.w  #8,(a0)+
                move.w  #9,(a0)+
                move.w  #$A,(a0)+
                move.w  #$B,(a0)+
                move.w  #$C,(a0)+
                move.w  #$D,(a0)+
                move.w  #$E,(a0)+
                rts
; End of function sub_1B48

; *************************************************
; Function Intro_GameTick
; *************************************************

Intro_GameTick:
; write HScroll table
                move.l  #Intro_TitleScrollTable,d0
                move.w  #$7000,d1
                move.w  #$1C0,d2 ; size in words
                jsr     (DmaWriteVRAM).l
; check if player A pressed start
                jsr     (GetInputPlayerA).w
                andi.w  #$80,d0 ; get 'Start' bit
                bne.w   .playerAPressedStart
                tst.w   (Intro_ram_PlayerAPressedStart).l
                bne.w   .endStage ; player A presed start then released
                bra.w   .checkPlayerBStart
.playerAPressedStart:
                move.w  d0,(Intro_ram_PlayerAPressedStart).l
; check if player B pressed start
.checkPlayerBStart:
                jsr     (GetInputPlayerB).w
                andi.w  #$80,d0 ; get 'Start' bit
                bne.w   .playerBPressedStart
                tst.w   (Intro_ram_PlayerBPressedStart).l
                bne.w   .endStage ; player B presed start then released
                bra.w   .showIntro
.playerBPressedStart:
                move.w  d0,(Intro_ram_PlayerBPressedStart).l

.showIntro:
                subq.w  #1,(Intro_ram_TextTimer).l
                bpl.w   .updateScroll ; jump if text doesn't change
                addq.w  #4,(Intro_ram_CurrentStringOffset).l
                move.w  (Intro_ram_CurrentStringOffset).l,d0
                lea     (Intro_dStringTable).l,a0
                movea.l (a0,d0.w),a0 ; get String
                cmpa.l  #$FFFFFFFF,a0 ; last entry is reached
                beq.w   .endStage
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).l
; write next text
                move.w  (Intro_ram_CurrentStringOffset).l,d0
                lea     (Intro_dStringTable).l,a0
                movea.l (a0,d0.w),a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; first tile index = 0, palette line = 3
                move.w  #$4000,d5 ; VRAM address = Scroll A
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteNametable).l

                move.w  #180,(Intro_ram_TextTimer).l ; wait 3 seconds
.updateScroll:
                lea     (Intro_TitleScrollTable + $258).l,a0 ; y = 150
                lea     (Intro_TitleScrollSpeed + $258).l,a1 ; y = 150
                move.w  #39,d0 ; repeat for 40 lines
.loopSetScroll:
                move.l  (a1),d2
                cmpi.w  #$2C,(Intro_ram_CurrentStringOffset).l
                bpl.w   .setScroll ; jump if all developers were shown
                cmpi.l  #$100000,(a0)
                bgt.w   .setScroll ; jump if scroll value > 16
                subi.l  #$20000,d2 ; decrease scroll speed by 2
                move.l  (a0),d1
                sub.l   d2,d1
                bmi.w   .setScroll ; jump if scroll value < scroll speed
                move.l  (a0),d2 ; if speed > value then speed = value
.setScroll:
                move.l  d2,(a1)+ ; update speed
                sub.l   d2,(a0)+ ; decrease scroll value
                dbf     d0,.loopSetScroll

                cmpi.w  #$2C,(Intro_ram_CurrentStringOffset).l ; move title out of screen when all developers were shown
                bpl.w   .moveOutOfScreen
                lea     (Intro_TitleScrollTable + $2F8).l,a0 ; y = 190
                move.w  #39,d0
.loopRecoil:
                move.l  (a0),d2 ; get scroll value
                sub.l   -(a0),d2 ; calculate delta with previous line
                subi.l  #$10000,d2 ; decrease by 1
                bmi.w   .loc_1D9A
                move.l  4(a0),(a0)
                subi.l  #$10000,(a0)
.loc_1D9A:
                dbf     d0,.loopRecoil
                bra.w   .end
.moveOutOfScreen:
                move.l  #$C0000,(Intro_TitleScrollSpeed + $2F4).l ; Y = 189, speed = 12
                move.l  #$FD800000,(Intro_TitleScrollTable + $2F8).l ; Y = 190, scroll value = -640
                lea     (Intro_TitleScrollTable + $2F8).l,a0 ; Y = 190
                move.w  #39,d0
                move.l  (a0),d2
                sub.l   -(a0),d2
                bmi.w   .loc_1DD2
                move.l  #0,(Intro_TitleScrollSpeed + $2F4).l ; Y = 189
.loc_1DD2:
                move.l  (a0),d2
                sub.l   -(a0),d2
                addi.l  #$10000,d2
                bpl.w   .loc_1DEA
                move.l  4(a0),(a0)
                addi.l  #$10000,(a0)
.loc_1DEA:
                dbf     d0,.loc_1DD2

                bra.w   .end
.end:
                jsr     (AudioFunc1).l
                rts
.endStage:
                jsr     (AudioFunc4).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .end
; End of function Intro_GameTick

Intro_dStringTable:
                dc.l Intro_String1
                dc.l Intro_String2
                dc.l Intro_String3
                dc.l Intro_String4
                dc.l Intro_String5
                dc.l Intro_String6
                dc.l Intro_String7
                dc.l Intro_String8
                dc.l Intro_String9
                dc.l Intro_String10
                dc.l Intro_String11
                dc.l Intro_String12
                dc.l Intro_String13
                dc.l $FFFFFFFF
Intro_String1:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "    Copyright 1991 Electronic Arts    "
    dc.b "                                      "
Intro_String2:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "   Licensed by Sega Enterprises LTD.  "
    dc.b "                                      "
Intro_String3:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "             Programming:             "
    dc.b "       Dan Geisler, Walter Stein      "
Intro_String4:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                 Art:                 "
    dc.b "       Arthur Koch, Jeff Fennel       "
Intro_String5:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                 Art:                 "
    dc.b "   Sheryl Knowles, Cynthia Hamilton   "
Intro_String6:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                 Art:                 "
    dc.b "       Connie Braat, Paul Vernon      "
Intro_String7:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                 Art:                 "
    dc.b "            Peggy Brennan             "
Intro_String8:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "           Sound and Music:           "
    dc.b "      Rob Hubbard, Mike Bartlow       "
Intro_String9:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "              Production:             "
    dc.b "              Randy Breen             "
Intro_String10:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "         Technical Direction:         "
    dc.b "               Carl Mey               "
Intro_String11:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "         Production Assistant:        "
    dc.b "           Michael Lubuguin           "
Intro_String12:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                                      "
    dc.b "                                      "
Intro_String13:
    dc.w 24,1,2,38 ; y, x, height, width
    dc.b "   Press the Start Button to Begin    "
    dc.b "                                      "

; *************************************************
; Function EncodeString
; a0 - String
; a1 - destination buffer
; *************************************************

EncodeString:
                lea     (dStringCodeTable).l,a2 ; get char codetable
                lea     4(a0),a0
                move.w  (a0)+,d0 ; get height
                move.w  (a0)+,d1 ; get width
                mulu.w  d0,d1 ; get number of chars
                subq.w  #1,d1
                clr.l   d0
.loop:
                move.b  (a0)+,d0 ; get char
                bpl.w   .skipInvalidChar
                move.b  #$20,d0 ; if char >= 0x80 then print ' '
.skipInvalidChar:
                asl.b   #1,d0
                move.w  (a2,d0.w),(a1)+ ; get char code and write to a1
                dbf     d1,.loop
                rts
; End of function EncodeString

; *************************************************
; Function DecodeString
; *************************************************

DecodeString:
                lea     (dStringDecodeTable).l,a2
                lea     4(a0),a0
                move.w  (a0)+,d0
                move.w  (a0)+,d1
                mulu.w  d0,d1
                subq.w  #1,d1
.loop:
                move.w  (a1)+,d0
                move.b  (a2,d0.w),(a0)+
                dbf     d1,.loop
                rts
; End of function DecodeString

dStringCodeTable:
    dc.w 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36 ; '                '
    dc.w 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36 ; '                '
    dc.w 36, 38, 48, 36, 43, 36, 36, 49, 44, 45, 36, 46, 39, 47, 40, 36 ; ' !"#$%&'()*+,-./'
    dc.w  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 42, 41, 36, 36, 36, 37 ; '0123456789:;<=>?'
    dc.w 36, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 ; '@ABCDEFGHIJKLMNO'
    dc.w 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 36, 36, 36, 36 ; 'PQRSTUVWXYZ[\]^_'
    dc.w 36, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 ; '`abcdefghijklmno'
    dc.w 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 36, 36, 36, 36 ; 'pqrstuvwxyz{|}~ '

dStringDecodeTable:
    dc.b "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ ?!,.", $3B, ":$()+-", $22, $27

; *************************************************
; Function WriteNametable
; a0 - source buffer
; d0 - width in cells
; d1 - height in cells
; d2 - topLeftX
; d3 - topLeftY
; d4 - base tile index
; d5 - destination VRAM address
; d6 - plane width
; *************************************************

WriteNametable:
                asl.w   #1,d6 ; d6 = planeWidth * 2
                mulu.w  d6,d3 ; d3 = d3 * d6 * 2
                add.w   d3,d5 ; d5 = d5 + d3 * d6 * 2
                asl.w   #1,d2 ; d2 = d2 * 2
                add.w   d2,d5 ; d5 = d5 + d3 * d6 * 2 + d2 * 2
                andi.l  #$FFFF,d5 ; value = (d5 + d3 * d6 * 2 + d2 * 2) & $FFFF
                asl.l   #2,d5
                lsr.w   #2,d5
                swap    d5 ; now higher 2 bits of value are in lower word and the rest bits are in higher word
                ori.l   #$40000000,d5
                swap    d6
                clr.w   d6
                subq.w  #1,d1
                subq.w  #1,d0
                move.w  d0,d2

.loc_2428:
                move.l  d5,(VdpCtrl).l
                move.w  d2,d0

.loc_2430:
                move.w  (a0)+,d3
                add.w   d4,d3
                move.w  d3,(VdpData).l
                dbf     d0,.loc_2430

                add.l   d6,d5
                dbf     d1,.loc_2428

                rts
; End of function WriteNametable

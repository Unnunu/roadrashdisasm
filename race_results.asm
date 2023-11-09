; *************************************************
; Function RaceResults_Init
; *************************************************

RaceResults_Init:
                move.w  #0,Menu_ram_NextMessageTimer
                move.w  #0,MainMenu_ram_ButtonsPlayerA
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerA
                move.w  #0,MainMenu_ram_ButtonsPlayerB
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerB
                move.w  #$FFFF,Menu_ram_MessageBlinkTimer
                move.w  #$3F,Message_ram_ButtonBlinkPeriod
                move.w  #1500,Menu_ram_NextMessageTimer
                move.l  #0,ram_FF0910
                move.w  ram_FF0526,ram_FF0918 ; player A
                tst.w   Menu_ram_Player
                beq.w   @loc_5F90
                move.w  ram_FF0528,ram_FF0918 ; player B
@loc_5F90:
                tst.w   ram_FF0918
                beq.w   @loc_5FBE
                cmpi.w  #4,ram_FF0918
                bne.w   @loc_5FB2
                move.w  #(8*35),Menu_ram_CurrentMessageId
                bra.w   @loc_5FCA
@loc_5FB2:
                move.w  #(8*28),Menu_ram_CurrentMessageId
                bra.w   @loc_5FCA
@loc_5FBE:
                move.w  #(8*21),Menu_ram_CurrentMessageId
                bra.w   @loc_5FCA
@loc_5FCA:
                lea     VdpCtrl,a0
                move.w  #$8004,(a0) ; H-ints disabled, Pal Select 1, HVC latch disabled, Display gen enabled
                move.w  #$8174,(a0) ; Display enabled, V-ints enabled, Height: 28, Mode 5, 64K VRAM
                move.w  #$8210,(a0) ; Scroll A Name Table:    $4000
                move.w  #$831C,(a0) ; Window Name Table:      $7000
                move.w  #$8402,(a0) ; Scroll B Name Table:    $4000
                move.w  #$8530,(a0) ; Sprite Attribute Table: $6000
                move.w  #$870D,(a0) ; Backdrop Color: $D
                move.w  #$8AFF,(a0) ; H-Int Counter: 255
                move.w  #$8B00,(a0) ; E-ints disabled, V-Scroll: full, H-Scroll: full
                move.w  #$8C81,(a0) ; Width: 40, Shadow/Highlight: disabled
                move.w  #$8D18,(a0) ; HScroll Data Table:     $6000
                move.w  #$8F02,(a0) ; Auto-increment: $2
                move.w  #$9003,(a0) ; Scroll A/B Size: 128x32
                move.w  #$9100,(a0) ; WindowX: 0
                move.w  #$921C,(a0) ; WindowY: 28
                VDP_VRAM_WRITE $6000,(a0) ; write sprite table
                move.l  #0,VdpData ; clear 4 sprite entries
                move.l  #0,VdpData
                move.l  #0,VdpData
                move.l  #0,VdpData
                move.l  #0,VdpData
                move.l  #0,VdpData
                move.l  #0,VdpData
                move.l  #0,VdpData
                VDP_VSRAM_WRITE $0,(a0) ; clear vertical scroll
                move.l  #0,VdpData
                movea.l #VdpData,a0
; create default tile
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
@loopClearDefault:
                move.l  #0,(a0)
                dbf     d0,@loopClearDefault
; load background image
                lea     img_MainMenu_Background,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write to VRAM address $8000
                move.l  #$8000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; base tile index, address = $8000
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $4E8,a0
                jsr     (WriteNametable).w
; load gamepad image
                lea     img_Gamepad,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
; write to VRAM address $A000
                move.l  #$A000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it
                move.w  #12,d0 ; width
                move.w  #6,d1 ; height
                move.w  #2,d2 ; x
                move.w  #22,d3 ; y
                move.w  #$500,d4 ; base tile index, address = $A000
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $B48,a0
                jsr     (WriteNametable).w
; clear frame buffer
                lea     Menu_ram_FrameBuffer,a0
                move.l  #$7FF07FF,d1
                move.w  #$37F,d0
@clearFB:
                move.l  d1,(a0)+
                dbf     d0,@clearFB
; load font
                lea     img_Intro_Font,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write to VRAM address $0
                moveq   #0,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM

                cmpi.w  #$FFFF,ram_FF04C8
                beq.w   @loc_616E
                bsr.w   sub_62CE
                bra.w   @loc_6190
@loc_616E:
                move.l  #10,d0
                jsr     AudioFunc3
                tst.w   ram_FF1B1A
                beq.w   @loc_618C
                bsr.w   sub_647E
                bra.w   @loc_6190
@loc_618C:
                bsr.w   sub_67AC
@loc_6190:
; write window nametable
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     DmaWriteVRAM

                lea     MenuPassword_StrPasswordStatus,a0
                move.w  #22,(a0)+ ; y
                move.w  #14,(a0)+ ; x
                move.w  #5,(a0)+ ; height
                move.w  #12,(a0)+ ; width
                lea     MenuPassword_ram_StrPlayerAName + 8,a1
                lea     MenuPassword_ram_StrPlayerAPassword + $8,a2
                lea     Menu_ram_MoneyPlayerA,a3
                tst.w   Menu_ram_Player
                beq.w   @loc_61E8
                lea     MenuPassword_ram_StrPlayerBName + 8,a1
                lea     MenuPassword_ram_StrPlayerBPassword + $8,a2
                lea     Menu_ram_MoneyPlayerB,a3
@loc_61E8:
; clear 16 chars
                move.l  #'    ',(a0)
                move.l  #'    ',4(a0)
                move.l  #'    ',8(a0)
                move.l  #'    ',12(a0)
; write player name on the first line
                move.l  (a1)+,(a0)
                move.l  (a1)+,4(a0)
                move.w  (a1)+,8(a0)
                adda.w  #12,a0 ; go to second line
; write amount of money on the second line
                move.l  #'cash',(a0)
                move.l  #'    ',4(a0)
                move.l  #'    ',8(a0)
                move.l  #'    ',12(a0)
                adda.w  #12,a0 ; go to third line
                move.l  a0,-(sp)
                move.l  (a3),d0
                bpl.w   @loc_6244
                subq.w  #2,ram_FF0682
@loc_6244:
                jsr     sub_C6C4
                movea.l (sp)+,a0
                move.l  #'    ',(a0)
                move.l  #'    ',4(a0)
                move.l  #'    ',8(a0)
                move.l  #'    ',$C(a0)
                adda.w  #12,a0
; write password
                move.w  #23,d0
@loopWritePassword:
                move.b  (a2)+,(a0)+
                dbf     d0,@loopWritePassword
; congratulations message
                lea     (unk_533A).w,a0
                lea     ram_FF089A,a1
                move.w  4(a0),d0
                mulu.w  6(a0),d0
                addq.w  #7,d0
@loc_628C:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_628C
                move.w  Menu_ram_PlayerLevel,d0
                cmp.w   #5,d0
                bmi.w   @loc_62A4
                move.w  #4,d0
@loc_62A4:
                subq.w  #6,a1
                add.b   d0,(a1)
                cmpi.w  #$FFFF,ram_FF04C8
                beq.w   @return
                jsr     AudioFunc4
                move.l  #9,d0
                move.w  d0,ram_CurrentSong
                jsr     AudioFunc3
@return:
                rts
; End of function RaceResults_Init

; *************************************************
; Function sub_62CE
; *************************************************

sub_62CE:
                move.l  #sub_62CE,ram_FF0914
; load "race results" title image
                lea     unk_AF26C,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write to VRAM address $9000
                move.l  #$9000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it
                move.w  #27,d0 ; width
                move.w  #2,d1 ; height
                move.w  #7,d2 ; x
                move.w  #1,d3 ; y
                move.w  #$480,d4 ; base tile index, address = $9000
                move.w  #$4000,d5 ; destination VRAM = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $588,a0
                jsr     (WriteNametable).w
; load end race image for current map
                lea     unk_7E670,a3
                move.w  Menu_ram_CurrentTrackId,d0
                asl.w   #1,d0
                movea.l (a3,d0.w),a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $B000
                lea     unk_7E684,a0
                adda.w  Menu_ram_CurrentTrackId,a0
                movea.w (a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                move.l  #$B000,d0
                jsr     WriteToVRAM
; and draw it
                move.w  #36,d0 ; width
                move.w  #11,d1 ; height
                move.w  #2,d2 ; x
                move.w  #5,d3 ; y
                move.w  #$580,d4 ; base tile index, address = $B000
                move.w  #$4000,d5 ; VRAM address = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     unk_7E68E,a0
                adda.w  Menu_ram_CurrentTrackId,a0
                movea.w (a0),a0
                adda.l  #Intro_ram_ImageBuffer + 4,a0
                jsr     (WriteNametable).w
; load palette
                lea     unk_7E698,a0
                adda.w  Menu_ram_CurrentTrackId,a0
                movea.w (a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l Global_ram_PalettePtr,a1
; copy 4 palette lines
                move.w  #7,d0
@copyPal0:
                move.l  (a0)+,(a1)+
                dbf     d0,@copyPal0

                move.w  #7,d0
@copyPal1:
                move.l  (a0)+,(a1)+
                dbf     d0,@copyPal1

                move.w  #7,d0
@copyPal2:
                move.l  (a0)+,(a1)+
                dbf     d0,@copyPal2

                move.w  #7,d0
@copyPal3:
                move.l  (a0)+,(a1)+
                dbf     d0,@copyPal3
; draw top 3 players in current race
                lea     ram_FF1414,a0
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString

                lea     Intro_ram_ImageBuffer,a0
                move.w  ram_FF141A,d0
                mulu.w  ram_FF1418,d0
                subq.w  #1,d0
@loc_63FA:
                ori.w   #$6000,(a0)+ ; set palette 3
                dbf     d0,@loc_63FA

                move.w  Menu_ram_CurrentTrackId,d0
                lea     Menu_ram_PlayerAPlaces,a0
                tst.w   Menu_ram_Player
                beq.w   @loc_641E
                lea     Menu_ram_PlayerBPlaces,a0 ; player B
@loc_641E:
                move.w  (a0,d0.w),d0 ; get player place in current race
                cmp.w   #4,d0
                ble.w   @loc_642E
                move.w  #4,d0
@loc_642E:
                subq.w  #1,d0
                mulu.w  ram_FF141A,d0
                asl.w   #1,d0
                lea     Intro_ram_ImageBuffer,a0
                adda.w  d0,a0
                move.w  ram_FF141A,d0
                subq.w  #1,d0
@loc_6448:
                andi.w  #$DFFF,(a0)+
                dbf     d0,@loc_6448

                lea     ram_FF1414,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #0,d4 ; base tile index = 0, text
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                bsr.w   WriteNametableToBuffer
                rts
; End of function sub_62CE

; *************************************************
; Function sub_62CE
; *************************************************

sub_647E:
                move.l  #sub_647E,ram_FF0914
                lea     unk_7ED66,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
                move.l  #$9000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
                move.w  #$15,d0
                move.w  #2,d1
                move.w  #$A,d2
                move.w  #1,d3
                move.w  #$480,d4
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     Intro_ram_ImageBuffer + $448,a0
                jsr     (WriteNametable).w
                lea     unk_7EA66,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
                move.l  #$B000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
                move.w  #$C,d0
                move.w  #$E,d1
                move.w  #2,d2
                move.w  #5,d3
                move.w  #$580,d4
                move.w  #$40,d6
                lea     Menu_ram_FrameBuffer,a1
                lea     Intro_ram_ImageBuffer + $168,a0
                jsr     (WriteNametableToBuffer).w
                move.l  Menu_ram_MoneyPlayerA,d1
                tst.w   Menu_ram_Player
                beq.w   @loc_6534
                move.l  Menu_ram_MoneyPlayerB,d1
@loc_6534:
                tst.l   d1
                bpl.w   @loc_6560
                lea     unk_19EC2,a0
                move.l  a0,-(sp)
                jsr     Rand_GetWord
                and.w   ($8).w,d0
                adda.w  d0,a0
                move.w  ram_FF1B1A,d0
                subq.w  #1,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
                bra.w   @loc_6582
@loc_6560:
                lea     unk_19E22,a0
                move.l  a0,-(sp)
                jsr     Rand_GetWord
                andi.w  #$18,d0
                adda.w  d0,a0
                move.w  ram_FF1B1A,d0
                subq.w  #1,d0
                mulu.w  #$20,d0
                adda.w  d0,a0
@loc_6582:
                move.l  (a0),-(sp)
                movea.l 4(a0),a3
                move.b  -7(a3),d0
                lsl.l   #8,d0
                move.b  -5(a3),d0
                lsl.l   #8,d0
                move.b  -3(a3),d0
                lsl.l   #8,d0
                move.b  -1(a3),d0
                move.l  d0,-(sp)
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
                move.l  #$C000,d0
                movea.l (sp),a0
                movea.w -6(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
                move.w  #$A,d0
                move.w  #$C,d1
                move.w  #3,d2
                move.w  #6,d3
                move.w  #$600,d4
                move.w  #$40,d6
                movea.l (sp),a0
                movea.w -4(a0),a0
                adda.l  #Intro_ram_ImageBuffer + $4,a0
                lea     Menu_ram_FrameBuffer,a1
                jsr     (WriteNametableToBuffer).w
                movea.l (sp),a0
                movea.w -2(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l Global_ram_PalettePtr,a1
                move.w  #7,d0
@loc_6608:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_6608
                move.w  #7,d0
@loc_6612:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_6612
                move.w  #7,d0
@loc_661C:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_661C
                move.w  #7,d0
@loc_6626:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_6626
                movea.l (sp)+,a0
                movea.l -$A(a0),a0
                addq.w  #6,a0
                lea     Menu_ram_TempString,a1
                move.w  #$13,(a1)+
                move.w  #3,(a1)+
                move.w  #1,(a1)+
                move.w  #$A,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                clr.w   d0
                movea.l a1,a0
@loc_6654:
                cmpi.b  #$20,-(a0)
                bne.w   @loc_6660
                addq.w  #1,d0
                bra.s   @loc_6654
@loc_6660:
                lea     -$A(a1),a0
@loc_6664:
                cmpi.b  #$20,(a0)+
                bne.w   @loc_6670
                subq.w  #1,d0
                bra.s   @loc_6664
@loc_6670:
                asr.w   #1,d0
                ble.w   @loc_66BA
                subq.w  #1,d0
                lea     -$A(a1),a0
@loc_667C:
                move.b  9(a0),d1
                move.b  8(a0),9(a0)
                move.b  7(a0),8(a0)
                move.b  6(a0),7(a0)
                move.b  5(a0),6(a0)
                move.b  4(a0),5(a0)
                move.b  3(a0),4(a0)
                move.b  2(a0),3(a0)
                move.b  1(a0),2(a0)
                move.b  (a0),1(a0)
                move.b  d1,(a0)
                dbf     d0,@loc_667C
@loc_66BA:
                lea     Menu_ram_TempString,a0
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString
                lea     Menu_ram_TempString,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                movea.l (sp),a0
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString
                movea.l (sp)+,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                asr.w   #1,d3
                move.w  #$6000,d4
                move.w  #$80,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                lea     (unk_56D8).w,a0
                movea.l (sp)+,a1
                cmpa.l  #unk_19EC2,a1
                beq.w   @loc_6776
                lea     (unk_56AC).w,a0
                lea     Menu_ram_TempString,a1
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  -2(a0),d0
                mulu.w  -4(a0),d0
                subq.w  #1,d0
@loc_6758:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_6758
                clr.l   d0
                move.w  ram_FF091A,d0
                lea     -2(a1),a0
                jsr     sub_C79A
                lea     Menu_ram_TempString,a0
@loc_6776:
                move.l  a0,-(sp)
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString
                movea.l (sp)+,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function sub_647E

; *************************************************
; Function sub_62CE
; *************************************************

sub_67AC:
                move.l  #sub_67AC,ram_FF0914
                lea     unk_7EA66,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
                move.l  #$B000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
                move.w  #$C,d0
                move.w  #$E,d1
                move.w  #2,d2
                move.w  #5,d3
                move.w  #$580,d4
                move.w  #$40,d6
                lea     Menu_ram_FrameBuffer,a1
                lea     Intro_ram_ImageBuffer + $168,a0
                jsr     (WriteNametableToBuffer).w
                move.l  Menu_ram_MoneyPlayerA,d1
                tst.w   Menu_ram_Player
                beq.w   @loc_6818
                move.l  Menu_ram_MoneyPlayerB,d1
@loc_6818:
                tst.l   d1
                bpl.w   @loc_6844
                lea     unk_19DD2,a0
                move.l  a0,-(sp)
                jsr     Rand_GetWord
                and.w   ($8).w,d0
                adda.w  d0,a0
                move.w  Menu_ram_PlayerLevel,d0
                subq.w  #1,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
                bra.w   @loc_6866
@loc_6844:
                lea     off_19D32,a0
                move.l  a0,-(sp)
                jsr     Rand_GetWord
                andi.w  #$18,d0
                adda.w  d0,a0
                move.w  Menu_ram_PlayerLevel,d0
                subq.w  #1,d0
                mulu.w  #$20,d0
                adda.w  d0,a0
@loc_6866:
                move.l  (a0),-(sp)
                movea.l 4(a0),a3
                move.b  -7(a3),d0
                lsl.l   #8,d0
                move.b  -5(a3),d0
                lsl.l   #8,d0
                move.b  -3(a3),d0
                lsl.l   #8,d0
                move.b  -1(a3),d0
                move.l  d0,-(sp)
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
                move.l  #$C000,d0
                movea.l (sp),a0
                movea.w -6(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
                move.w  #$A,d0
                move.w  #$C,d1
                move.w  #3,d2
                move.w  #6,d3
                move.w  #$600,d4
                move.w  #$40,d6
                movea.l (sp),a0
                movea.w -4(a0),a0
                adda.l  #Intro_ram_ImageBuffer + $4,a0
                lea     Menu_ram_FrameBuffer,a1
                jsr     (WriteNametableToBuffer).w
                movea.l (sp),a0
                movea.w -2(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l Global_ram_PalettePtr,a1
                move.w  #7,d0
@loc_68EC:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_68EC
                move.w  #7,d0
@loc_68F6:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_68F6
                move.w  #7,d0
@loc_6900:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_6900
                move.w  #7,d0
@loc_690A:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_690A
                movea.l (sp)+,a0
                movea.l -$A(a0),a0
                addq.w  #6,a0
                lea     Menu_ram_TempString,a1
                move.w  #$13,(a1)+
                move.w  #3,(a1)+
                move.w  #1,(a1)+
                move.w  #$A,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                clr.w   d0
                movea.l a1,a0
@loc_6938:
                cmpi.b  #$20,-(a0)
                bne.w   @loc_6944
                addq.w  #1,d0
                bra.s   @loc_6938
@loc_6944:
                lea     -$A(a1),a0
@loc_6948:
                cmpi.b  #$20,(a0)+
                bne.w   @loc_6954
                subq.w  #1,d0
                bra.s   @loc_6948
@loc_6954:
                asr.w   #1,d0
                ble.w   @loc_699E
                subq.w  #1,d0
                lea     -$A(a1),a0
@loc_6960:
                move.b  9(a0),d1
                move.b  8(a0),9(a0)
                move.b  7(a0),8(a0)
                move.b  6(a0),7(a0)
                move.b  5(a0),6(a0)
                move.b  4(a0),5(a0)
                move.b  3(a0),4(a0)
                move.b  2(a0),3(a0)
                move.b  1(a0),2(a0)
                move.b  (a0),1(a0)
                move.b  d1,(a0)
                dbf     d0,@loc_6960
@loc_699E:
                lea     Menu_ram_TempString,a0
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString
                lea     Menu_ram_TempString,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6 ; '@'
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                movea.l (sp),a0
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString
                movea.l (sp)+,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                asr.w   #1,d3
                move.w  #$6000,d4
                move.w  #$80,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                lea     (unk_5730).w,a0
                movea.l (sp)+,a1
                cmpa.l  #unk_19DD2,a1
                beq.w   @loc_6A5A
                lea     (unk_5704).w,a0
                lea     Menu_ram_TempString,a1
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  -2(a0),d0
                mulu.w  -4(a0),d0
                subq.w  #1,d0
@loc_6A3C:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_6A3C
                clr.l   d0
                move.w  ram_FF091A,d0
                lea     -2(a1),a0
                jsr     sub_C79A
                lea     Menu_ram_TempString,a0
@loc_6A5A:
                move.l  a0,-(sp)
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString
                movea.l (sp)+,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function sub_67AC

; *************************************************
; Function RaceResults_GameTick
; *************************************************

RaceResults_GameTick:
; draw framebuffer
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     DmaWriteVRAM

                move.w  MainMenu_ram_ButtonsPlayerA,MainMenu_ram_ChangedButtonsPlayerA
                jsr     (GetInputPlayerA).w
                move.w  d0,MainMenu_ram_ButtonsPlayerA
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerA
                andi.w  #$80,d0
                bne.w   @endStage ; if start pressed
                move.w  MainMenu_ram_ButtonsPlayerB,MainMenu_ram_ChangedButtonsPlayerB
                jsr     (GetInputPlayerB).w
                move.w  d0,MainMenu_ram_ButtonsPlayerB
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerB
                andi.w  #$80,d0
                bne.w   @endStage ; if start pressed
                move.w  MainMenu_ram_ChangedButtonsPlayerB,d0
                beq.w   @loc_6B0C
                and.w   MainMenu_ram_ButtonsPlayerB,d0
                beq.w   @loc_6B0C
                move.l  #MainMenu_ram_ButtonsPlayerB,Menu_ram_CurrentButtonsPtr
                jsr     RaceResults_HandleInput
@loc_6B0C:
                move.w  MainMenu_ram_ChangedButtonsPlayerA,d0
                beq.w   @showMessage
                and.w   MainMenu_ram_ButtonsPlayerA,d0
                beq.w   @showMessage
                move.l  #MainMenu_ram_ButtonsPlayerA,Menu_ram_CurrentButtonsPtr
                jsr     RaceResults_HandleInput
@showMessage:
                subq.w  #1,Menu_ram_MessageBlinkTimer
                subq.w  #1,Menu_ram_NextMessageTimer
                bpl.w   @loc_6BA8
                move.w  #30,Menu_ram_MessageBlinkTimer
                move.w  #300,Menu_ram_NextMessageTimer ; 5 seconds
                addq.w  #8,Menu_ram_CurrentMessageId
                move.w  Menu_ram_CurrentMessageId,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                bne.w   @loc_6BA8
                tst.w   ram_FF0918
                beq.w   @loc_6B9C
                cmpi.w  #4,ram_FF0918
                bne.w   @loc_6B90
                move.w  #$118,Menu_ram_CurrentMessageId
                bra.w   @loc_6BA8
@loc_6B90:
                move.w  #$E0,Menu_ram_CurrentMessageId
                bra.w   @loc_6BA8
@loc_6B9C:
                move.w  #$A8,Menu_ram_CurrentMessageId
                bra.w   @loc_6BA8
@loc_6BA8:
                bsr.w   Menu_ShowMessage
                cmpi.l  #0,ram_FF0910
                bne.w   @endStage
@loc_6BBA:
                jsr     AudioFunc1
                rts
@endStage:
                jsr     AudioFunc4
                move.l  #0,ram_UpdateFunction
                bra.s   @loc_6BBA
; End of function RaceResults_GameTick

; *************************************************
; Function RaceResults_HandleInput
; d0 - current buttons state (SACBRLDU)
; *************************************************

RaceResults_HandleInput:
                move.b  d0,RaceResults_ram_CurrentButtons
                btst    #6,RaceResults_ram_CurrentButtons
                beq.w   @checkB
                move.l  #HighScore_Init,ram_FF0910 ; A pressed -> go to high score table
@checkB:
                btst    #4,RaceResults_ram_CurrentButtons
                beq.w   @loc_6C46
                move.w  #$1E,Menu_ram_MessageBlinkTimer ; B pressed -> show cash and password
                move.w  #1500,Menu_ram_NextMessageTimer ; for 25 seconds
                tst.w   ram_FF0918
                beq.w   @loc_6C3A
                cmpi.w  #4,ram_FF0918
                bne.w   @loc_6C2E
                move.w  #(8*35),Menu_ram_CurrentMessageId
                bra.w   @loc_6C46
@loc_6C2E:
                move.w  #(8*28),Menu_ram_CurrentMessageId
                bra.w   @loc_6C46
@loc_6C3A:
                move.w  #(8*21),Menu_ram_CurrentMessageId
                bra.w   @loc_6C46
@loc_6C46:
                btst    #5,RaceResults_ram_CurrentButtons
                beq.w   @return
                move.l  #Shop_Init,ram_FF0910 ; C pressed -> go to bike shop
@return:
                rts
; End of function RaceResults_HandleInput

; not sure this function belongs to this file

; *************************************************
; Function DrawString
; a0 - string
; *************************************************

DrawString:
                move.l  a0,-(sp)
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString

                movea.l (sp)+,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; base tile index = 0, palette line = 3
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                bsr.w   WriteNametableToBuffer
                rts
; End of function DrawString

unk_6C94:
    dc.w 22,16,5,20
    dc.b " To go to the next  "
    dc.b "                    "
    dc.b " level, you need to "
    dc.b "                    "
    dc.b "  earn        more. "

unk_6D00:
    dc.b $D9, $EF, $F5, $A0, $E1, $F2, $E5, $EE
    dc.b $A7, $F4, $A0, $F2, $E5, $E1, $E4, $F9
    dc.b $A0, $E6, $EF, $F2

unk_6D14:
    dc.b "the next level yet.   You need to earn      $12345 more.    "

unk_6D50:
    dc.w 23,12,3,16
    dc.b "Continue play at"
    dc.b "                "
    dc.b " Current level 0"

unk_6D88:
    dc.w 23,12,3,16
    dc.b " The next level "
    dc.b "                "
    dc.b " will be level 0"
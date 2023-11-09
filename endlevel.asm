; *************************************************
; Function EndLevel_Init
; *************************************************

EndLevel_Init:
                move.w  #$7FFF,Menu_ram_NextMessageTimer
                move.w  #0,MainMenu_ram_ButtonsPlayerA
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerA
                move.w  #0,MainMenu_ram_ButtonsPlayerB
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerB
                move.w  #$FFFF,Menu_ram_MessageBlinkTimer
                move.w  #$3F,Message_ram_ButtonBlinkPeriod
                move.w  #$180,Menu_ram_CurrentMessageId
                move.l  #0,ram_FF0910
                move.w  #0,EndLevel_ram_AnimFrame
                move.w  #5,ram_FF0D24
                move.w  #0,Race_ram_FrameReady
                move.w  #0,Race_ram_FrameReady2
                move.l  #Intro_ram_ImageBuffer,Race_ram_NextSpriteTileArray
                move.w  #$8680,Race_ram_SpriteDestination
                move.w  #$2E0,Animation_ram_BaseTile ; base tile index, address = $5C00
                move.w  #0,Race_ram_SpriteSize1
                move.w  #0,Race_ram_SpriteSize2
                move.l  #ram_FF3FDC,Race_ram_CurrentVScrollInfo
                move.l  #ram_FF425C,Race_ram_NextVScrollInfo
                move.l  #Intro_TitleScrollTable,Race_ram_CurrentHScrollTable
                move.l  #Intro_TitleScrollTable,Race_ram_NextScrollTable
                move.l  #Intro_TitleScrollTable + $400,Race_ram_NextSpriteAttributeTable
                move.l  #Intro_TitleScrollTable + $400,Race_ram_CurrentSpriteAttributeTable
                move.l  #Race_ram_FrameReady,Race_ram_CurrentFrameReady
                move.l  #Race_ram_FrameReady,Race_ram_NextFrameReady
                move.l  #Intro_ram_ImageBuffer,Race_ram_CurrentSpriteTileArray
                move.l  #Race_ram_SpriteSize1,Race_ram_CurrentSpriteSizePtr
                move.l  #Race_ram_SpriteSize1,Race_ram_NextSpriteSizePtr

                lea     VdpCtrl,a0
                move.w  #$8004,(a0) ; H-ints disabled, Pal Select 1, HVC latch disabled, Display gen enabled
                move.w  #$8174,(a0) ; Display enabled, V-ints enabled, Height: 28, Mode 5, 64K VRAM
                move.w  #$8210,(a0) ; Scroll A Name Table:    $4000
                move.w  #$830C,(a0) ; Window Name Table:      $3000
                move.w  #$8402,(a0) ; Scroll B Name Table:    $4000
                move.w  #$8508,(a0) ; Sprite Attribute Table: $1000
                move.w  #$870D,(a0) ; Backdrop Color: $D
                move.w  #$8AFF,(a0) ; H-Int Counter: 255
                move.w  #$8B00,(a0) ; E-ints disabled, V-Scroll: full, H-Scroll: full
                move.w  #$8C81,(a0) ; Width: 40, Shadow/Highlight: disabled
                move.w  #$8D08,(a0) ; HScroll Data Table:     $2000
                move.w  #$8F02,(a0) ; Auto-increment: $2
                move.w  #$9003,(a0) ; Scroll A/B Size: 128x32
                move.w  #$9100,(a0) ; WindowX: 0
                move.w  #$921C,(a0) ; WindowY: 28
                VDP_VRAM_WRITE $2000,(a0) ; write HScroll
                move.l  #0,VdpData ; clear HScroll
                VDP_VRAM_WRITE $1000,(a0) ; write sprite table
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
; clear default tile
                movea.l #VdpData,a0
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
@loopDefaultTile:
                move.l  #0,(a0)
                dbf     d0,@loopDefaultTile
; load background image
                lea     img_MainMenu_Background,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $1280
                move.l  #$1280,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$94,d4 ; base tile index, address = $1280
                move.w  #$4000,d5 ; destination = scroll A/B
                move.w  #128,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $4E8,a0
                jsr     (WriteNametable).w
; load tiles for animation
                lea     unk_80000,a3
                movea.l #$5C00,a1
                jsr     UncompressToVRAM
; clear first 22 lines in frame buffer
                lea     Menu_ram_FrameBuffer,a0
                move.l  #$7FF07FF,d1
                move.w  #$2BF,d0
@loopClearFB:
                move.l  d1,(a0)+
                dbf     d0,@loopClearFB
; fill last 6 lines with zeroes
                move.w  #$BF,d0
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                swap    d1
                move.w  (dStringCodeTable + 2 * ' ').w,d1
@loc_859A:
                move.l  d1,(a0)+
                dbf     d0,@loc_859A

                lea     (unk_7F400).l,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB

                move.l  #$2020,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM

                move.w  #40,d0 ; width
                move.w  #14,d1 ; height
                move.w  #0,d2 ; x
                move.w  #4,d3 ; y
                move.w  #$101,d4 ; base tile index, address = $2020
                move.w  #64,d6 ; plane width
                lea     Menu_ram_FrameBuffer,a1 ; destination
                lea     Intro_ram_ImageBuffer + $368,a0 ; source
                jsr     (WriteNametableToBuffer).w
; load palette
                lea     Intro_ram_ImageBuffer + $2E4,a0
                movea.l Global_ram_PalettePtr,a1

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
; load font image
                lea     img_Intro_Font,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $0
                moveq   #0,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; draw image from frame buffer
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$3000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM
; load animation script
                lea     unk_8BF12,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW

                jsr     AudioFunc4
                tst.w   ram_MusicEnabled
                beq.w   @return
                move.l  #9,d0
                jsr     AudioFunc3
@return:
                rts
; End of function EndLevel_Init

; *************************************************
; Function EndLevel_InitCharacterScreen
; *************************************************

EndLevel_InitCharacterScreen:
                move.l  #$50000000,VdpCtrl
                move.l  #0,VdpData
                move.l  #0,VdpData
                lea     (img_Gamepad).l,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
                move.l  #$A000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
                move.w  #$C,d0
                move.w  #6,d1
                move.w  #2,d2
                move.w  #$16,d3
                move.w  #$500,d4
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     Intro_ram_ImageBuffer + $B48,a0
                jsr     (WriteNametable).w
                lea     Menu_ram_FrameBuffer,a0
                move.l  #$7FF07FF,d1
                move.w  #$2BF,d0
@loc_86FA:
                move.l  d1,(a0)+
                dbf     d0,@loc_86FA
                move.w  #$BF,d0
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                swap    d1
                move.w  (dStringCodeTable + 2 * ' ').w,d1
@loc_870E:
                move.l  d1,(a0)+
                dbf     d0,@loc_870E
                lea     (unk_7EA66).l,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
                move.l  #$9000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
                move.w  #$C,d0
                move.w  #$E,d1
                move.w  #2,d2
                move.w  #5,d3
                move.w  #$480,d4
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer + $168,a0
                lea     Menu_ram_FrameBuffer,a1
                jsr     (WriteNametableToBuffer).w
                lea     (unk_19F12).l,a0
                jsr     Rand_GetWord
                andi.w  #8,d0
                adda.w  d0,a0
                move.w  Menu_ram_PlayerLevel,d0
                subq.w  #1,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
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
                adda.l  #Intro_ram_ImageBuffer + 4,a0
                lea     Menu_ram_FrameBuffer,a1
                jsr     (WriteNametableToBuffer).w
                movea.l (sp),a0
                movea.w -2(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l Global_ram_PalettePtr,a1
                move.w  #7,d0
@loc_8806:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_8806
                move.w  #7,d0
@loc_8810:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_8810
                move.w  #7,d0
@loc_881A:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_881A
                move.w  #7,d0
@loc_8824:
                move.l  (a0)+,(a1)+
                dbf     d0,@loc_8824
                move.l  Global_ram_PalettePtr,d0
                move.w  #0,d1
                move.w  #$40,d2
                jsr     DmaWriteCRAM
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
@loc_8866:
                cmpi.b  #$20,-(a0)
                bne.w   @loc_8872
                addq.w  #1,d0
                bra.s   @loc_8866
@loc_8872:
                lea     -$A(a1),a0
@loc_8876:
                cmpi.b  #$20,(a0)+
                bne.w   @loc_8882
                subq.w  #1,d0
                bra.s   @loc_8876
@loc_8882:
                asr.w   #1,d0
                ble.w   @loc_88CC
                subq.w  #1,d0
                lea     -$A(a1),a0
@loc_888E:
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
                dbf     d0,@loc_888E
@loc_88CC:
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
                jsr     sub_8946
                rts
; End of function EndLevel_InitCharacterScreen

; *************************************************
; Function sub_8946
; *************************************************

sub_8946:
                tst.w   Menu_ram_Player
                bne.w   @loc_89B4
                clr.w   ram_FF0526
                clr.w   Menu_ram_PlayerAPlaces + 0
                clr.w   Menu_ram_PlayerAPlaces + 2
                clr.w   Menu_ram_PlayerAPlaces + 4
                clr.w   Menu_ram_PlayerAPlaces + 6
                clr.w   Menu_ram_PlayerAPlaces + 8
                addq.w  #1,Menu_ram_PlayerALevel
                cmpi.w  #5,Menu_ram_PlayerALevel
                ble.w   @loc_898E
                move.w  #5,Menu_ram_PlayerALevel
@loc_898E:
                lea     Menu_ram_PlayerAOpponents,a0
                move.w  #$4B,(a0)+
                move.w  Menu_ram_PlayerALevel,d0
                subq.w  #1,d0
                mulu.w  #$F,d0
                move.w  #$E,d1
@loc_89A8:
                move.w  d0,(a0)+
                addq.w  #1,d0
                dbf     d1,@loc_89A8
                bra.w   @loc_8A14
@loc_89B4:
                clr.w   ram_FF0528
                clr.w   Menu_ram_PlayerBPlaces + 0
                clr.w   Menu_ram_PlayerBPlaces + 2
                clr.w   Menu_ram_PlayerBPlaces + 4
                clr.w   Menu_ram_PlayerBPlaces + 6
                clr.w   Menu_ram_PlayerBPlaces + 8
                addq.w  #1,Menu_ram_PlayerBLevel
                cmpi.w  #5,Menu_ram_PlayerBLevel
                ble.w   @loc_89F2
                move.w  #5,Menu_ram_PlayerBLevel
@loc_89F2:
                lea     Menu_ram_PlayerBOpponents,a0
                move.w  #$4B,(a0)+
                move.w  Menu_ram_PlayerBLevel,d0
                subq.w  #1,d0
                mulu.w  #$F,d0
                move.w  #$E,d1
@loc_8A0C:
                move.w  d0,(a0)+
                addq.w  #1,d0
                dbf     d1,@loc_8A0C
@loc_8A14:
                jsr     (MenuPassword_CreatePassword).w
                rts
; End of function sub_8946

; *************************************************
; Function EndLevel_GameTickCharacterScreen
; *************************************************

EndLevel_GameTickCharacterScreen:
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$3000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM
                move.w  MainMenu_ram_ButtonsPlayerA,MainMenu_ram_ChangedButtonsPlayerA
                jsr     (GetInputPlayerA).w
                move.w  d0,MainMenu_ram_ButtonsPlayerA
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerA
                andi.w  #$80,d0
                bne.w   @loc_8ADC
                move.w  MainMenu_ram_ButtonsPlayerB,MainMenu_ram_ChangedButtonsPlayerB
                jsr     (GetInputPlayerB).w
                move.w  d0,MainMenu_ram_ButtonsPlayerB
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerB
                andi.w  #$80,d0
                bne.w   @loc_8ADC
                subq.w  #1,Menu_ram_MessageBlinkTimer
                subq.w  #1,Menu_ram_NextMessageTimer
                bpl.w   @loc_8AC2
                move.w  #$1E,Menu_ram_MessageBlinkTimer
                move.w  #$78,Menu_ram_NextMessageTimer
                addq.w  #8,Menu_ram_CurrentMessageId
                cmpi.w  #$180,Menu_ram_CurrentMessageId
                bpl.w   @loc_8AAA
                move.w  #$180,Menu_ram_CurrentMessageId
@loc_8AAA:
                move.w  Menu_ram_CurrentMessageId,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                beq.w   @loc_8ADC
@loc_8AC2:
                bsr.w   Menu_ShowMessage
                cmpi.l  #0,ram_FF0910
                bne.w   @loc_8ADC
@loc_8AD4:
                jsr     AudioFunc1
                rts
@loc_8ADC:
                jsr     AudioFunc4
                move.l  #0,ram_UpdateFunction
                bra.s   @loc_8AD4
; End of function EndLevel_GameTickCharacterScreen

; *************************************************
; Function EndLevel_GameTick
; *************************************************

EndLevel_GameTick:
; get player A input
                move.w  MainMenu_ram_ButtonsPlayerA,MainMenu_ram_ChangedButtonsPlayerA
                jsr     (GetInputPlayerA).w
                move.w  d0,MainMenu_ram_ButtonsPlayerA
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerA
; get player B input
                move.w  MainMenu_ram_ButtonsPlayerB,MainMenu_ram_ChangedButtonsPlayerB
                jsr     (GetInputPlayerB).w
                move.w  d0,MainMenu_ram_ButtonsPlayerB
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerB

                subq.w  #1,Menu_ram_NextMessageTimer
                tst.w   EndLevel_ram_AnimFrame
                bmi.w   @endStage

                subq.w  #1,ram_FF0D24
                bpl.w   @end
                lea     VdpCtrl,a0
                lea     VdpData,a1
                movea.l Race_ram_NextFrameReady,a2
                tst.w   (a2)
                beq.w   @end
                move.w  #5,ram_FF0D24
; set sprite table
                move.l  Race_ram_NextScrollTable,d0
                addi.w  #$400,d0
                move.w  #$1000,d1
                move.w  #$140,d2
                jsr     DmaWriteVRAM
                
                jsr     Race_SwapFrames
@end:
                jsr     AudioFunc1
                rts
@endStage:
                jsr     EndLevel_InitCharacterScreen
                move.l  #EndLevel_GameTickCharacterScreen,ram_UpdateFunction
                bra.s   @end
; End of function EndLevel_GameTick

; *************************************************
; Function EndLevel_UpdateAnimation
; *************************************************

EndLevel_UpdateAnimation:
                tst.w   EndLevel_ram_AnimFrame
                bmi.w   @return

                lea     unk_8C8C,a0
                move.w  Menu_ram_PlayerLevel,d0
                subq.w  #1,d0
                adda.w  d0,a0
                adda.w  d0,a0
                move.w  (a0),d0
                cmp.w   EndLevel_ram_AnimFrame,d0
                bcs.w   @endAnimation
                movea.l Race_ram_CurrentFrameReady,a0
                tst.w   (a0)
                bne.w   @return

                clr.w   Animation_ram_SpriteIndex
                move.w  #$2E0,Animation_ram_BaseTile
                move.w  EndLevel_ram_AnimFrame,d0 ; frame index
                movea.l Race_ram_CurrentSpriteAttributeTable,a0 ; destination
                movea.l Race_ram_CurrentSpriteTileArray,a1 ; tile array, not used
                lea     unk_8DC2,a4 ; animation script
                move.w  #$80,d1 ; x
                move.w  #$80,d2 ; y
                jsr     UpdateAnimation2
                addq.w  #1,EndLevel_ram_AnimFrame
                jsr     Race_FinishFrame
@return:
                rts
@endAnimation:
                tst.w   Race_ram_FrameReady
                bne.w   @loc_8C80
                tst.w   Race_ram_FrameReady2
                bne.w   @loc_8C80

                move.w  MainMenu_ram_ChangedButtonsPlayerA,d0
                andi.w  #$80,d0
                beq.w   @loc_8C42
                move.w  MainMenu_ram_ButtonsPlayerA,d0
                andi.w  #$80,d0
                bne.w   @loc_8C42
                move.w  #-1,Menu_ram_NextMessageTimer
@loc_8C42:
                move.w  MainMenu_ram_ChangedButtonsPlayerB,d0
                andi.w  #$80,d0
                beq.w   @loc_8C66
                move.w  MainMenu_ram_ButtonsPlayerB,d0
                andi.w  #$80,d0
                bne.w   @loc_8C66
                move.w  #-1,Menu_ram_NextMessageTimer
@loc_8C66:
                tst.w   Menu_ram_NextMessageTimer
                bpl.s   @return
                move.w  #-1,EndLevel_ram_AnimFrame
                move.w  #120,Menu_ram_NextMessageTimer ; 2 seconds
                bra.s   @return
@loc_8C80:
                move.w  #120,Menu_ram_NextMessageTimer ; 2 seconds
                bra.w   @return
; End of function EndLevel_UpdateAnimation

unk_8C8C:
    dc.w 35,54,81,91,123

unk_8C96:
    dc.w 22,16,5,20
    dc.b " To go to the next  "
    dc.b "                    "
    dc.b " level, you need to "
    dc.b "                    "
    dc.b "  earn        more. "

unk_8D02:
    dc.b $D9, $EF, $F5, $A0, $E1, $F2, $E5, $EE
    dc.b $A7, $F4, $A0, $F2, $E5, $E1, $E4, $F9
    dc.b $A0, $E6, $EF, $F2

unk_8D16:
    dc.b "the next level yet.   You need to earn      $12345 more.    "

unk_8D52:
    dc.w 23,12,3,16
    dc.b "Continue play at"
    dc.b "                "
    dc.b " Current level 0"

unk_8D8A:
    dc.w 23,12,3,16
    dc.b " The next level "
    dc.b "                "
    dc.b " will be level 0"

unk_8DC2:       dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $7A ; z
                dc.b   0
                dc.b $FF
                dc.b $50 ; P
                dc.b $9C
                dc.b   0
                dc.b $FF
                dc.b $50 ; P
                dc.b $A6
                dc.b   0
                dc.b $FF
                dc.b $50 ; P
                dc.b $B0
                dc.b   0
                dc.b $FF
                dc.b $50 ; P
                dc.b $C2
                dc.b   0
                dc.b $FF
                dc.b $50 ; P
                dc.b $F4
                dc.b   0
                dc.b $FF
                dc.b $51 ; Q
                dc.b $96
                dc.b   0
                dc.b $FF
                dc.b $52 ; R
                dc.b $38 ; 8
                dc.b   0
                dc.b $FF
                dc.b $52 ; R
                dc.b $DA
                dc.b   0
                dc.b $FF
                dc.b $53 ; S
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b $54 ; T
                dc.b $1E
                dc.b   0
                dc.b $FF
                dc.b $54 ; T
                dc.b $C0
                dc.b   0
                dc.b $FF
                dc.b $55 ; U
                dc.b $62 ; b
                dc.b   0
                dc.b $FF
                dc.b $56 ; V
                dc.b   4
                dc.b   0
                dc.b $FF
                dc.b $56 ; V
                dc.b $96
                dc.b   0
                dc.b $FF
                dc.b $57 ; W
                dc.b $30 ; 0
                dc.b   0
                dc.b $FF
                dc.b $57 ; W
                dc.b $CA
                dc.b   0
                dc.b $FF
                dc.b $58 ; X
                dc.b $54 ; T
                dc.b   0
                dc.b $FF
                dc.b $58 ; X
                dc.b $DE
                dc.b   0
                dc.b $FF
                dc.b $59 ; Y
                dc.b $70 ; p
                dc.b   0
                dc.b $FF
                dc.b $5A ; Z
                dc.b  $A
                dc.b   0
                dc.b $FF
                dc.b $5A ; Z
                dc.b $A4
                dc.b   0
                dc.b $FF
                dc.b $5B ; [
                dc.b $3E ; >
                dc.b   0
                dc.b $FF
                dc.b $5B ; [
                dc.b $D8
                dc.b   0
                dc.b $FF
                dc.b $5C ; \
                dc.b $72 ; r
                dc.b   0
                dc.b $FF
                dc.b $5D ; ]
                dc.b $24 ; $
                dc.b   0
                dc.b $FF
                dc.b $5D ; ]
                dc.b $D6
                dc.b   0
                dc.b $FF
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b $FF
                dc.b $5F ; _
                dc.b $42 ; B
                dc.b   0
                dc.b $FF
                dc.b $5F ; _
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $60 ; `
                dc.b $B6
                dc.b   0
                dc.b $FF
                dc.b $61 ; a
                dc.b $70 ; p
                dc.b   0
                dc.b $FF
                dc.b $62 ; b
                dc.b $72 ; r
                dc.b   0
                dc.b $FF
                dc.b $63 ; c
                dc.b $74 ; t
                dc.b   0
                dc.b $FF
                dc.b $64 ; d
                dc.b $76 ; v
                dc.b   0
                dc.b $FF
                dc.b $65 ; e
                dc.b $30 ; 0
                dc.b   0
                dc.b $FF
                dc.b $65 ; e
                dc.b $EA
                dc.b   0
                dc.b $FF
                dc.b $66 ; f
                dc.b $A4
                dc.b   0
                dc.b $FF
                dc.b $67 ; g
                dc.b $5E ; ^
                dc.b   0
                dc.b $FF
                dc.b $68 ; h
                dc.b $10
                dc.b   0
                dc.b $FF
                dc.b $68 ; h
                dc.b $C2
                dc.b   0
                dc.b $FF
                dc.b $69 ; i
                dc.b $74 ; t
                dc.b   0
                dc.b $FF
                dc.b $6A ; j
                dc.b $26 ; &
                dc.b   0
                dc.b $FF
                dc.b $6A ; j
                dc.b $E0
                dc.b   0
                dc.b $FF
                dc.b $6B ; k
                dc.b $9A
                dc.b   0
                dc.b $FF
                dc.b $6C ; l
                dc.b $54 ; T
                dc.b   0
                dc.b $FF
                dc.b $6C ; l
                dc.b $F6
                dc.b   0
                dc.b $FF
                dc.b $6D ; m
                dc.b $98
                dc.b   0
                dc.b $FF
                dc.b $6E ; n
                dc.b $3A ; :
                dc.b   0
                dc.b $FF
                dc.b $6E ; n
                dc.b $F4
                dc.b   0
                dc.b $FF
                dc.b $6F ; o
                dc.b $AE
                dc.b   0
                dc.b $FF
                dc.b $70 ; p
                dc.b $68 ; h
                dc.b   0
                dc.b $FF
                dc.b $71 ; q
                dc.b $22 ; "
                dc.b   0
                dc.b $FF
                dc.b $71 ; q
                dc.b $C4
                dc.b   0
                dc.b $FF
                dc.b $72 ; r
                dc.b $66 ; f
                dc.b   0
                dc.b $FF
                dc.b $73 ; s
                dc.b   8
                dc.b   0
                dc.b $FF
                dc.b $73 ; s
                dc.b $AA
                dc.b   0
                dc.b $FF
                dc.b $74 ; t
                dc.b $4C ; L
                dc.b   0
                dc.b $FF
                dc.b $75 ; u
                dc.b   6
                dc.b   0
                dc.b $FF
                dc.b $75 ; u
                dc.b $C0
                dc.b   0
                dc.b $FF
                dc.b $76 ; v
                dc.b $7A ; z
                dc.b   0
                dc.b $FF
                dc.b $77 ; w
                dc.b $34 ; 4
                dc.b   0
                dc.b $FF
                dc.b $77 ; w
                dc.b $EE
                dc.b   0
                dc.b $FF
                dc.b $78 ; x
                dc.b $A8
                dc.b   0
                dc.b $FF
                dc.b $79 ; y
                dc.b $5A ; Z
                dc.b   0
                dc.b $FF
                dc.b $7A ; z
                dc.b  $C
                dc.b   0
                dc.b $FF
                dc.b $7A ; z
                dc.b $BE
                dc.b   0
                dc.b $FF
                dc.b $7B ; {
                dc.b $70 ; p
                dc.b   0
                dc.b $FF
                dc.b $7C ; |
                dc.b $22 ; "
                dc.b   0
                dc.b $FF
                dc.b $7C ; |
                dc.b $D4
                dc.b   0
                dc.b $FF
                dc.b $7D ; }
                dc.b $6E ; n
                dc.b   0
                dc.b $FF
                dc.b $7E ; ~
                dc.b   8
                dc.b   0
                dc.b $FF
                dc.b $7E ; ~
                dc.b $A2
                dc.b   0
                dc.b $FF
                dc.b $7F ; 
                dc.b $4C ; L
                dc.b   0
                dc.b $FF
                dc.b $7F ; 
                dc.b $F6
                dc.b   0
                dc.b $FF
                dc.b $80
                dc.b $A0
                dc.b   0
                dc.b $FF
                dc.b $81
                dc.b $4A ; J
                dc.b   0
                dc.b $FF
                dc.b $81
                dc.b $E4
                dc.b   0
                dc.b $FF
                dc.b $82
                dc.b $7E ; ~
                dc.b   0
                dc.b $FF
                dc.b $83
                dc.b $18
                dc.b   0
                dc.b $FF
                dc.b $83
                dc.b $B2
                dc.b   0
                dc.b $FF
                dc.b $84
                dc.b $4C ; L
                dc.b   0
                dc.b $FF
                dc.b $84
                dc.b $E6
                dc.b   0
                dc.b $FF
                dc.b $85
                dc.b $80
                dc.b   0
                dc.b $FF
                dc.b $86
                dc.b $1A
                dc.b   0
                dc.b $FF
                dc.b $86
                dc.b $B4
                dc.b   0
                dc.b $FF
                dc.b $87
                dc.b $56 ; V
                dc.b   0
                dc.b $FF
                dc.b $88
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b $88
                dc.b $CA
                dc.b   0
                dc.b $FF
                dc.b $89
                dc.b $94
                dc.b   0
                dc.b $FF
                dc.b $8A
                dc.b $5E ; ^
                dc.b   0
                dc.b $FF
                dc.b $8B
                dc.b $28 ; (
                dc.b   0
                dc.b $FF
                dc.b $8B
                dc.b $F2
                dc.b   0
                dc.b $FF
                dc.b $8C
                dc.b $8C
                dc.b   0
                dc.b $FF
                dc.b $8D
                dc.b $26 ; &
                dc.b   0
                dc.b $FF
                dc.b $8D
                dc.b $D0
                dc.b   0
                dc.b $FF
                dc.b $8E
                dc.b $7A ; z
                dc.b   0
                dc.b $FF
                dc.b $8F
                dc.b $24 ; $
                dc.b   0
                dc.b $FF
                dc.b $8F
                dc.b $CE
                dc.b   0
                dc.b $FF
                dc.b $90
                dc.b $78 ; x
                dc.b   0
                dc.b $FF
                dc.b $91
                dc.b $2A ; *
                dc.b   0
                dc.b $FF
                dc.b $91
                dc.b $D4
                dc.b   0
                dc.b $FF
                dc.b $92
                dc.b $7E ; ~
                dc.b   0
                dc.b $FF
                dc.b $93
                dc.b $18
                dc.b   0
                dc.b $FF
                dc.b $93
                dc.b $B2
                dc.b   0
                dc.b $FF
                dc.b $94
                dc.b $4C ; L
                dc.b   0
                dc.b $FF
                dc.b $94
                dc.b $E6
                dc.b   0
                dc.b $FF
                dc.b $95
                dc.b $80
                dc.b   0
                dc.b $FF
                dc.b $96
                dc.b $1A
                dc.b   0
                dc.b $FF
                dc.b $96
                dc.b $C4
                dc.b   0
                dc.b $FF
                dc.b $97
                dc.b $6E ; n
                dc.b   0
                dc.b $FF
                dc.b $98
                dc.b $18
                dc.b   0
                dc.b $FF
                dc.b $98
                dc.b $DA
                dc.b   0
                dc.b $FF
                dc.b $99
                dc.b $BC
                dc.b   0
                dc.b $FF
                dc.b $9A
                dc.b $9E
                dc.b   0
                dc.b $FF
                dc.b $9B
                dc.b $68 ; h
                dc.b   0
                dc.b $FF
                dc.b $9C
                dc.b $42 ; B
                dc.b   0
                dc.b $FF
                dc.b $9D
                dc.b $14
                dc.b   0
                dc.b $FF
                dc.b $9D
                dc.b $EE
                dc.b   0
                dc.b $FF
                dc.b $9E
                dc.b $B8
                dc.b   0
                dc.b $FF
                dc.b $9F
                dc.b $7A ; z
                dc.b   0
                dc.b $FF
                dc.b $A0
                dc.b $3C ; <
                dc.b   0
                dc.b $FF
                dc.b $A0
                dc.b $7E ; ~
                dc.b   0
                dc.b $FF
                dc.b $A0
                dc.b $C0
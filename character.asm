; *************************************************
; Function Character_Init
; *************************************************

Character_Init:
                move.w  #0,MainMenu_ram_ButtonsPlayerA
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerA
                move.w  #0,MainMenu_ram_ButtonsPlayerB
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerB
                move.w  #$FFFF,Menu_ram_MessageBlinkTimer
                move.w  #$3F,Message_ram_ButtonBlinkPeriod
                move.w  #300,Menu_ram_NextMessageTimer ; 5 seconds
                move.w  #(8*18),Menu_ram_CurrentMessageId ; empty message
                move.l  #Global_ram_Palette,Global_ram_PalettePtr
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
                move.w  #$921C,(a0) ; WindowY: 28 cells
; clear HScroll
                VDP_VRAM_WRITE $6000, (a0) ; HScroll 
                move.w  #3,d0
@loopClearHScroll:
                move.l  #0,VdpData
                dbf     d0,@loopClearHScroll
                VDP_VSRAM_WRITE $0, (a0)
                move.l  #0,VdpData
; clear default tile
                movea.l #VdpData,a0
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
@loopDefaultTile:
                move.l  #0,(a0)
                dbf     d0,@loopDefaultTile
; clear scroll A/B
                VDP_VRAM_WRITE $4000,VdpCtrl
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1
                move.w  #$6FF,d0 ; $E00 words
@loopClearAB:
                move.l  d1,(a0)
                dbf     d0,@loopClearAB
; load background image
                lea     img_MainMenu_Background,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     sub_9C26
; write to VRAM, why $4000 ??
                move.l  #$4000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     sub_AFF2
; and draw it
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; base tile index, address = $8000
                move.w  #$4000,d5 ; destination VRAM address = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $4E8,a0
                jsr     (WriteNametable).w
; load gamepad image
                lea     img_Gamepad,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     sub_9B9E
; write to VRAM address $A000
                move.l  #$A000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     sub_AFF2
; and draw it
                move.w  #12,d0 ; width
                move.w  #6,d1 ; height
                move.w  #2,d2 ; x
                move.w  #22,d3 ; y
                move.w  #$500,d4 ; base tile index, address = $A000
                move.w  #$4000,d5 ; destination VRAM address = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $B48,a0
                jsr     (WriteNametable).w
; clear framebuffer
                lea     Menu_ram_FrameBuffer,a0
                move.l  #$7FF07FF,d1
                move.w  #$37F,d0
@loopClearFB:
                move.l  d1,(a0)+
                dbf     d0,@loopClearFB

                lea     unk_7EA66,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     sub_9B9E

                move.l  #$B000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     sub_AFF2

                move.w  #12,d0 ; width
                move.w  #14,d1 ; height
                move.w  #2,d2 ; x
                move.w  #5,d3 ; y
                move.w  #$580,d4 ; base tile index, address = $B000
                move.w  #64,d6 ; plane width
                lea     Menu_ram_FrameBuffer,a1 ; destination
                lea     Intro_ram_ImageBuffer + $168,a0 ; source
                jsr     (WriteNametableToBuffer).w

@loc_5BAA:
                move.w  ram_FF0522,ram_FF0520
                tst.w   Menu_ram_Player
                beq.w   @loc_5BC8
                move.w  ram_FF0524,ram_FF0520 ; player B
@loc_5BC8:
                jsr     Rand_GetWord
                andi.w  #$18,d0
                cmp.w   #$18,d0
                beq.s   @loc_5BAA

                tst.w   d0
                bne.w   @loc_5BEC
                tst.w   ram_FF0520
                ble.w   @loc_5BEC
                move.w  #$18,d0
@loc_5BEC:
                lea     unk_19A12,a0
                adda.w  d0,a0
                move.w  Menu_ram_PlayerALevel,d0
                tst.w   Menu_ram_Player
                beq.w   @loc_5C0A
                move.w  Menu_ram_PlayerBLevel,d0 ; player B
@loc_5C0A:
                subq.w  #1,d0
                mulu.w  #$A0,d0
                adda.w  d0,a0
                move.w  Menu_ram_CurrentRaceId,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
                movea.l 4(a0),a3 ; get character image
                move.l  a3,-(sp)
                move.l  (a0),-(sp) ; get character quote
                move.b  -7(a3),d0
                lsl.l   #8,d0
                move.b  -5(a3),d0
                lsl.l   #8,d0
                move.b  -3(a3),d0
                lsl.l   #8,d0
                move.b  -1(a3),d0
                move.l  d0,-(sp) ; character name
; decompress image
                lea     Intro_ram_ImageBuffer,a1 ; destination
                jsr     sub_9C26

                move.l  #$C000,d0 ; chararcter image VRAM address
                movea.l (sp),a0
                movea.w -6(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     sub_AFF2
; write image to fb
                move.w  #10,d0 ; width
                move.w  #12,d1 ; height
                move.w  #3,d2 ; x
                move.w  #6,d3 ; y
                move.w  #$600,d4 ; base tile index, address = $C000
                move.w  #64,d6 ; plane width
                movea.l (sp),a0
                movea.w -4(a0),a0
                adda.l  #Intro_ram_ImageBuffer + 4,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                jsr     (WriteNametableToBuffer).w
; copy palette
                movea.l (sp),a0
                movea.w -2(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l Global_ram_PalettePtr,a1

                move.w  #7,d0
@loopCopyPalette0:
                move.l  (a0)+,(a1)+
                dbf     d0,@loopCopyPalette0

                move.w  #7,d0
@loopCopyPalette1:
                move.l  (a0)+,(a1)+
                dbf     d0,@loopCopyPalette1

                move.w  #7,d0
@loopCopyPalette2:
                move.l  (a0)+,(a1)+
                dbf     d0,@loopCopyPalette2

                move.w  #7,d0
@loopCopyPalette3:
                move.l  (a0)+,(a1)+
                dbf     d0,@loopCopyPalette3

                movea.l (sp)+,a0
                movea.l -10(a0),a0
                addq.w  #6,a0
                lea     Menu_ram_TempString,a1
                move.w  #19,(a1)+
                move.w  #3,(a1)+
                move.w  #1,(a1)+
                move.w  #10,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+

                clr.w   d0
                movea.l a1,a0
@loc_5CF2:
                cmpi.b  #$20,-(a0)
                bne.w   @loc_5CFE
                addq.w  #1,d0
                bra.s   @loc_5CF2

@loc_5CFE:
                lea     -$A(a1),a0

@loc_5D02:
                cmpi.b  #$20,(a0)+
                bne.w   @loc_5D0E
                subq.w  #1,d0
                bra.s   @loc_5D02

@loc_5D0E:
                asr.w   #1,d0
                ble.w   @loc_5D58
                subq.w  #1,d0
                lea     -$A(a1),a0

@loc_5D1A:
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
                dbf     d0,@loc_5D1A

@loc_5D58:
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

                move.l  (sp)+,d0
                cmp.l   #unk_AF902,d0
                bne.w   @loc_5E2C
                tst.w   ram_FF0520
                ble.w   @loc_5E2C

                lea     unk_B1506,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     sub_9C26

                move.l  #$D000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     sub_AFF2

                move.w  #6,d0
                move.w  #7,d1
                move.w  #6,d2
                move.w  #9,d3
                move.w  #$680,d4
                move.w  #$40,d6
                lea     Menu_ram_FrameBuffer,a1
                lea     Intro_ram_ImageBuffer + $548,a0
                jsr     (WriteNametableToBuffer).w
@loc_5E2C:
                lea     img_Intro_Font,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     sub_9C26

                moveq   #0,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     sub_AFF2

                bsr.w   Menu_ShowMessage

                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     DmaWriteVRAM
                rts
; End of function Character_Init

; *************************************************
; Function Character_GameTick
; *************************************************

Character_GameTick:
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     DmaWriteVRAM

                move.w  MainMenu_ram_ButtonsPlayerA,MainMenu_ram_ChangedButtonsPlayerA
                jsr     (GetInputPlayerA).w
                move.w  d0,MainMenu_ram_ButtonsPlayerA
                eori.w  #$FFFF,d0
                move.w  MainMenu_ram_ChangedButtonsPlayerA,d1
                and.w   d1,d0
                beq.w   @loc_5EAA
                move.b  #0,ram_FF1ADA
                bra.w   @endStage
@loc_5EAA:
                move.w  MainMenu_ram_ButtonsPlayerB,MainMenu_ram_ChangedButtonsPlayerB
                jsr     (GetInputPlayerB).w
                move.w  d0,MainMenu_ram_ButtonsPlayerB
                eori.w  #$FFFF,d0
                move.w  MainMenu_ram_ChangedButtonsPlayerB,d1
                and.w   d1,d0
                beq.w   @loc_5EDA
                move.b  #1,ram_FF1ADA
                bra.w   @endStage

@loc_5EDA:
                subq.w  #1,Menu_ram_NextMessageTimer
                bpl.w   @loc_5F0A
                move.w  #300,Menu_ram_NextMessageTimer
                addq.w  #8,Menu_ram_CurrentMessageId
                move.w  Menu_ram_CurrentMessageId,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                beq.w   @endStage

@loc_5F0A:
                bsr.w   Menu_ShowMessage

@loc_5F0E:
                jsr     AudioFunc1
                rts
@endStage:
                jsr     AudioFunc4
                move.l  #0,ram_UpdateFunction
                bra.s   @loc_5F0E
; End of function Character_GameTick
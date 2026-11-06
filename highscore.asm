; *************************************************
; Function HighScore_Init
; *************************************************

HighScore_Init:
                move.w  #600,(Menu_ram_NextMessageTimer).l ; 10 seconds
                move.w  #0,(MainMenu_ram_ButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerB).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerB).l
                move.w  #$FFFF,(Menu_ram_MessageBlinkTimer).l
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l
                move.w  #(8*42),(Menu_ram_CurrentMessageId).l
                move.l  #0,(ram_FF0910).l
                lea     (VdpCtrl).l,a0
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
                move.w  #3,d0
.loc_6E56:
                move.l  #0,(VdpData).l
                dbf     d0,.loc_6E56

                VDP_VSRAM_WRITE $0,(a0) ; clear vertical scroll
                move.l  #0,(VdpData).l
                movea.l #VdpData,a0
; create default tile
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
.loopClearDefault:
                move.l  #0,(a0)
                dbf     d0,.loopClearDefault
; load background image
                lea     (img_MainMenu_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $8000
                move.l  #$8000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; and draw it
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; base tile index, address = $8000
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $4E8).l,a0 ; source
                jsr     (WriteNametable).w
; load "High Score" title image
                lea     (unk_A2F5C).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $9000
                move.l  #$9000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; and draw it
                move.w  #20,d0 ; width
                move.w  #2,d1 ; height
                move.w  #11,d2 ; x
                move.w  #1,d3 ; y
                move.w  #$480,d4 ; base tile index, address = $9000
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $568).l,a0 ; source
                jsr     (WriteNametable).w
; set palette
                lea     (Intro_ram_ImageBuffer + $4E4).l,a0
                movea.l (Global_ram_PalettePtr).l,a1

                move.w  #7,d0
.copyPal0:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPal0

                move.w  #7,d0
.copyPal1:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPal1

                move.w  #7,d0
.copyPal2:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPal2

                move.w  #7,d0
.copyPal3:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPal3
; load gamepad image
                lea     (img_Gamepad).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
; write to VRAM address $A000
                move.l  #$A000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; and draw it
                move.w  #12,d0 ; width
                move.w  #6,d1 ; height
                move.w  #2,d2 ; x
                move.w  #22,d3 ; y
                move.w  #$500,d4 ; base tile index, address = $A000
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $B48).l,a0
                jsr     (WriteNametable).w
; load yellow badge image
                lea     (unk_7EB72).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
; write to VRAM address $B000
                move.l  #$B000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; and draw it 5 times
                move.w  #22,d0
                move.w  #3,d1
                move.w  #9,d2
                move.w  #5,d3
                move.w  #$580,d4
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer + $528).l,a0
                jsr     (WriteNametable).w

                move.w  #22,d0
                move.w  #3,d1
                move.w  #9,d2
                move.w  #8,d3
                move.w  #$580,d4
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer + $528).l,a0
                jsr     (WriteNametable).w

                move.w  #22,d0
                move.w  #3,d1
                move.w  #9,d2
                move.w  #11,d3
                move.w  #$580,d4
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer + $528).l,a0
                jsr     (WriteNametable).w

                move.w  #22,d0
                move.w  #3,d1
                move.w  #9,d2
                move.w  #14,d3
                move.w  #$580,d4
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer + $528).l,a0
                jsr     (WriteNametable).w

                move.w  #22,d0
                move.w  #3,d1
                move.w  #9,d2
                move.w  #17,d3
                move.w  #$580,d4
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer + $528).l,a0
                jsr     (WriteNametable).w
; load font
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $0
                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; load table font
                lea     (unk_A2BAA).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $800
                move.l  #$800,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                lea     (unk_A2E68).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$1000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; clear 22 lines in frame buffer
                lea     (Menu_ram_FrameBuffer).l,a0
                move.l  #$7FF07FF,d1
                move.w  #$2BF,d0
.loopClearFB:
                move.l  d1,(a0)+
                dbf     d0,.loopClearFB
; fill last 6 lines with spaces
                move.w  #$BF,d0
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                swap    d1
                move.w  (dStringCodeTable + 2 * ' ').w,d1
.loopDrawSpace:
                move.l  d1,(a0)+
                dbf     d0,.loopDrawSpace

                lea     (HighScore_ram_Table).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString
; draw 1st row
                lea     (HighScore_ram_Table).l,a0
                move.w  6(a0),d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #6,d3 ; y
                move.w  #$40,d4 ; base tile index, address = $800
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
; draw 2nd row
                lea     (HighScore_ram_Table).l,a0
                move.w  6(a0),d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #9,d3 ; y
                move.w  #$40,d4 ; base tile index, address = $800
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                adda.w  #40,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
; draw 3rd row
                lea     (HighScore_ram_Table).l,a0
                move.w  6(a0),d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #12,d3 ; y
                move.w  #$40,d4 ; base tile index, address = $800
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                adda.w  #80,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
; draw 4th row
                lea     (HighScore_ram_Table).l,a0
                move.w  6(a0),d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #15,d3 ; y
                move.w  #$40,d4 ; base tile index, address = $800
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                adda.w  #120,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
; draw 5th row
                lea     (HighScore_ram_Table).l,a0
                move.w  6(a0),d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #18,d3 ; y
                move.w  #$40,d4 ; base tile index, address = $800
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                adda.w  #160,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
; draw player A row
                lea     (HighScore_ram_Table).l,a0
                move.w  6(a0),d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #23,d3 ; y
                move.w  #0,d4 ; base tile index, address = $0
                move.w  #$40,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  (HighScore_ram_PlayerATableOffset).l,d5
                asl.w   #1,d5
                adda.w  d5,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
; draw player B row
                lea     (HighScore_ram_Table).l,a0
                move.w  6(a0),d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #25,d3 ; y
                move.w  #0,d4 ; base tile index, address = $0
                move.w  #$40,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  (HighScore_ram_PlayerBTableOffset).l,d5
                asl.w   #1,d5
                adda.w  d5,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
; draw frame buffer
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM

                jsr     (AudioFunc4).l
                tst.w   (ram_MusicEnabled).l
                beq.w   .return
                moveq   #1,d0
                jsr     (AudioFunc3).l
.return:
                rts
; End of function HighScore_Init

; *************************************************
; Function HighScore_GameTick_Demo
; *************************************************

HighScore_GameTick_Demo:
; check if player A pressed then released any button
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l
                eori.w  #$FFFF,d0 ; invert buttons
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d1
                and.w   d1,d0 ; get released buttons
                bne.w   .buttonReleased
; check if player B pressed then released any button
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                eori.w  #$FFFF,d0
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d1
                and.w   d1,d0
                bne.w   .buttonReleased

                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .end
                bra.w   .endStage
.buttonReleased:
                clr.w   (MainMenu_ram_DemoMode).l
.endStage:
                jsr     (AudioFunc4).l
                move.l  #0,(ram_UpdateFunction).l
.end:
                jsr     (AudioFunc1).l
                rts
; End of function HighScore_GameTick_Demo

; *************************************************
; Function HighScore_GameTick
; *************************************************

HighScore_GameTick:
; draw frame buffer
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM
; check if player A pressed then released any button
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l
                eori.w  #$FFFF,d0
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d1
                and.w   d1,d0
                bne.w   .buttonReleased
; check if player B pressed then released any button
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                eori.w  #$FFFF,d0
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d1
                and.w   d1,d0
                bne.w   .buttonReleased

                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d0
                beq.w   .loc_73AC
                and.w   (MainMenu_ram_ButtonsPlayerB).l,d0
                beq.w   .loc_73AC
                move.l  #MainMenu_ram_ButtonsPlayerB,(Menu_ram_CurrentButtonsPtr).l
                jsr     (HighScore_HandleInput).l
.loc_73AC:
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d0
                beq.w   .loc_73D0
                and.w   (MainMenu_ram_ButtonsPlayerA).l,d0
                beq.w   .loc_73D0
                move.l  #MainMenu_ram_ButtonsPlayerA,(Menu_ram_CurrentButtonsPtr).l
                jsr     (HighScore_HandleInput).l
.loc_73D0:
                subq.w  #1,(Menu_ram_MessageBlinkTimer).l
                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .loc_742A
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #300,(Menu_ram_NextMessageTimer).l
                addq.w  #8,(Menu_ram_CurrentMessageId).l
                cmpi.w  #(8*42),(Menu_ram_CurrentMessageId).l
                bpl.w   .loc_740A
                move.w  #(8*42),(Menu_ram_CurrentMessageId).l
.loc_740A:
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                bne.w   .loc_742A
                move.w  #(8*42),(Menu_ram_CurrentMessageId).l
.loc_742A:
                bsr.w   Menu_ShowMessage
                cmpi.l  #0,(ram_FF0910).l
                bne.w   .endStage
.loc_743C:
                jsr     (AudioFunc1).l
                rts
.buttonReleased:
                move.l  #RaceResults_Init,(ram_FF0910).l ; restart this menu
.endStage:
                jsr     (AudioFunc4).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .loc_743C
; End of function HighScore_GameTick

; *************************************************
; Function HighScore_HandleInput
; d0 - current buttons state (SACBRLDU)
; *************************************************

HighScore_HandleInput:
                move.b  d0,(HighScore_ram_CurrentButtons).l
                btst    #6,(HighScore_ram_CurrentButtons).l
                beq.w   .checkB
                move.l  #HighScore_Init,(ram_FF0910).l ; pressed A -> restart this page
.checkB:
                btst    #4,(HighScore_ram_CurrentButtons).l
                beq.w   .checkC
                move.l  #RaceResults_Init,(ram_FF0910).l ; pressed B -> go back to race results
.checkC:
                btst    #5,(HighScore_ram_CurrentButtons).l
                beq.w   .return
                move.l  #Shop_Init,(ram_FF0910).l ; pressed C -> go to shop
.return:
                rts
; End of function HighScore_HandleInput
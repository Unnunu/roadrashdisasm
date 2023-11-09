; *************************************************
; Function Shop_Init
; *************************************************

Shop_Init:
                move.w  #0,Menu_ram_NextMessageTimer
                move.w  #0,MainMenu_ram_ButtonsPlayerA
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerA
                move.w  #0,MainMenu_ram_ButtonsPlayerB
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerB
                move.w  #$FFFF,Menu_ram_MessageBlinkTimer
                move.w  #$3F,Message_ram_ButtonBlinkPeriod
                move.w  #$12C,Menu_ram_NextMessageTimer
                move.w  #$1E0,Menu_ram_CurrentMessageId
                move.l  #0,ram_FF0910
                move.w  Menu_ram_BikeIdPlayerA,Shop_CurrentBikeId
                tst.w   Menu_ram_Player
                beq.w   @loc_751A
                move.w  Menu_ram_BikeIdPlayerB,Shop_CurrentBikeId
@loc_751A:
                lea     VdpCtrl,a0
                lea     VdpData,a1
                move.w  #$8004,(a0) ; H-ints disabled, Pal Select 1, HVC latch disabled, Display gen enabled
                move.w  #$8174,(a0) ; Display enabled, V-ints enabled, Height: 28, Mode 5, 64K VRAM
                move.w  #$8210,(a0) ; Scroll A Name Table:    $4000
                move.w  #$831C,(a0) ; Window Name Table:      $7000
                move.w  #$8402,(a0) ; Scroll B Name Table:    $4000
                move.w  #$8530,(a0) ; Sprite Attribute Table: $6000
                move.w  #$870D,(a0) ; Backdrop Color: $D
                move.w  #$8AFF,(a0) ; H-Int Counter: 255
                move.w  #$8B02,(a0) ; E-ints disabled, V-Scroll: full, H-Scroll: cell
                move.w  #$8C81,(a0) ; Width: 40, Shadow/Highlight: disabled
                move.w  #$8D19,(a0) ; HScroll Data Table:     $6400
                move.w  #$8F02,(a0) ; Auto-increment: $2
                move.w  #$9003,(a0) ; Scroll A/B Size: 128x32
                move.w  #$9100,(a0) ; WindowX: 0
                move.w  #$921C,(a0) ; WindowY: 28
                VDP_VRAM_WRITE $6000,(a0) ; write sprite table
                move.l  #0,VdpData ; clear first entry
                move.l  #0,VdpData
; write scroll table for background
                move.w  #$8F20,(a0) ; Auto-increment: $20
                VDP_VRAM_WRITE $6402,(a0)
                move.w  #$160,Shop_ScrollPos
; 7 strips: scroll = 0
                move.w  #6,d0
                move.w  #0,d1
@setScrollTable1:
                move.w  d1,(a1)
                dbf     d0,@setScrollTable1
; 9 strips: scroll = -Shop_ScrollPos
                move.w  #8,d0
                move.w  Shop_ScrollPos,d1
                neg.w   d1
@setScrollTable2:
                move.w  d1,(a1)
                dbf     d0,@setScrollTable2
; 12 strips: scroll = 0
                move.w  #11,d0
                move.w  #0,d1
@setScrollTable3:
                move.w  d1,(a1)
                dbf     d0,@setScrollTable3

                move.w  #$8F02,(a0) ; Auto-increment: $2
                VDP_VSRAM_WRITE $0,(a0) ; clear vertical scroll data
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
                move.w  #$6FF,d0
@loopClearAB:
                move.l  d1,(a0)
                dbf     d0,@loopClearAB
; load background image
                lea     img_MainMenu_Background,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $8000
                move.l  #$8000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it in frame buffer
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; base tile index, address = $8000
                move.w  #64,d6 ; plane width
                lea     Menu_ram_FrameBuffer,a1 ; destination
                lea     Intro_ram_ImageBuffer + $4E8,a0 ; source
                bsr.w   WriteNametableToBuffer
; load bike selection background
                lea     img_MainMenu_RaceSelectionBackground,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
; write it to VRAM address $9000
                move.l  #$9000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it in frame buffer
                move.w  #40,d0 ; width
                move.w  #14,d1 ; height
                move.w  #0,d2 ; x
                move.w  #4,d3 ; y
                move.w  #$480,d4 ; base tile index, address = $9000
                move.w  #64,d6 ; plane width
                lea     Menu_ram_FrameBuffer,a1 ; destination
                lea     Intro_ram_ImageBuffer + $2E8,a0 ; source
                bsr.w   WriteNametableToBuffer
; load gamepad image
                lea     img_Gamepad,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
; write it to VRAM address $A000
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
                bsr.w   WriteNametable
; load left arrows image
                lea     unk_9E784,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $B000
                move.l  #$B000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it
                move.w  #4,d0 ; width
                move.w  #2,d1 ; height
                move.w  #0,d2 ; x
                move.w  #4,d3 ; y
                move.w  #$8580,d4 ; base tile index, address = $B000, high priority
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $C8,a0
                jsr     (WriteNametable).w
; load right arrows image
                lea     unk_9E874,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $B100
                move.l  #$B100,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it
                move.w  #4,d0 ; width
                move.w  #2,d1 ; height
                move.w  #36,d2 ; x
                move.w  #4,d3 ; y
                move.w  #$8588,d4 ; base tile index, address = $B100, high priority
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $148,a0
                jsr     (WriteNametable).w
; load palette
                lea     Intro_ram_ImageBuffer + $C4,a0
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
; load bike 1 image
                lea     unk_9EA1E,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $C000
                move.l  #$C000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it to Shop_ImageBike1
                move.w  #18,d0 ; width
                move.w  #9,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$600,d4 ; base tile index, address = $C000
                move.w  #18,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $E28,a0 ; source
                lea     Shop_ImageBike1,a1 ; destination
                bsr.w   WriteNametableToBuffer
; load bike 2 image
                lea     unk_9FDDE,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $D000
                move.l  #$D000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it to Shop_ImageBike2
                move.w  #18,d0 ; width
                move.w  #9,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$680,d4 ; base tile index, address = $D000
                move.w  #18,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $EA8,a0 ; source
                lea     Shop_ImageBike2,a1 ; destination
                bsr.w   WriteNametableToBuffer
; load bike 3 image
                lea     unk_A122A,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM address $E000
                move.l  #$E000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and draw it to Shop_ImageBike3
                move.w  #18,d0 ; width
                move.w  #9,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$700,d4 ; base tile index, address = $E000
                move.w  #18,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $E48,a0
                lea     Shop_ImageBike3,a1
                bsr.w   WriteNametableToBuffer
; draw bikes
                lea     Shop_dBikePalettes,a0
                move.w  Shop_CurrentBikeId,d0
                asl.w   #5,d0
                adda.w  d0,a0
                lea     Shop_dBikePalettes,a1 ; current bike palette
                move.w  Shop_CurrentBikeId,d0
                subq.w  #1,d0
                andi.w  #7,d0
                asl.w   #5,d0
                adda.w  d0,a1
                move.w  Shop_CurrentBikeId,d0 ; previous bike palette, used for all other bikes
                bsr.w   Shop_DrawBikes
; draw text 'CREDITS'
                lea     Menu_ram_FrameBuffer + 2*(18*64 + 3),a0 ; get offset to cell x = 3, y = 18
                move.w  (dStringCodeTable + 2 * 'C').w,(a0)
                addi.w  #$6000,(a0)+ ; palette 3
                move.w  (dStringCodeTable + 2 * 'R').w,(a0)
                addi.w  #$6000,(a0)+
                move.w  (dStringCodeTable + 2 * 'E').w,(a0)
                addi.w  #$6000,(a0)+
                move.w  (dStringCodeTable + 2 * 'D').w,(a0)
                addi.w  #$6000,(a0)+
                move.w  (dStringCodeTable + 2 * 'I').w,(a0)
                addi.w  #$6000,(a0)+
                move.w  (dStringCodeTable + 2 * 'T').w,(a0)
                addi.w  #$6000,(a0)+
; draw text 'PRICE'
                lea     Menu_ram_FrameBuffer + 2*(18*64 + 31),a0 ; get offset to cell x = 31, y = 18
                move.w  (dStringCodeTable + 2 * 'P').w,(a0)
                addi.w  #$6000,(a0)+
                move.w  (dStringCodeTable + 2 * 'R').w,(a0)
                addi.w  #$6000,(a0)+
                move.w  (dStringCodeTable + 2 * 'I').w,(a0)
                addi.w  #$6000,(a0)+
                move.w  (dStringCodeTable + 2 * 'C').w,(a0)
                addi.w  #$6000,(a0)+
                move.w  (dStringCodeTable + 2 * 'E').w,(a0)
                addi.w  #$6000,(a0)+
; load font image
                lea     img_Intro_Font,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to address $0
                moveq   #0,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; draw bike name, power and weight
                move.w  Shop_CurrentBikeId,d0
                bsr.w   Shop_DrawBikeName
; show message with bike description
                move.w  Shop_CurrentBikeId,d0
                bsr.w   Shop_ShowBikeDescription

                bsr.w   Shop_PrepareMessages
                bsr.w   Shop_DrawCreditsAndPrice

                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM

                jsr     AudioFunc4
                tst.w   ram_MusicEnabled
                beq.w   @return
                moveq   #1,d0
                jsr     AudioFunc3
@return:
                rts
; End of function Shop_Init

; *************************************************
; Function Shop_DrawBikeName
; d0 - bike id
; *************************************************

Shop_DrawBikeName:
                lea     Shop_BikeDescriptions,a0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0 ; get bike description
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString

                movea.l Shop_BikeDescriptions,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; base tile index, address = $0, palette line = 3
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; deastination
                bsr.w   WriteNametableToBuffer
                rts
; End of function Shop_DrawBikeName

; *************************************************
; Function Shop_ShowBikeDescription
; d0 - bike id
; *************************************************

Shop_ShowBikeDescription:
                asl.w   #3,d0
                addi.w  #(8*51),d0
                move.w  d0,Menu_ram_CurrentMessageId
                move.w  #30,Menu_ram_MessageBlinkTimer
                move.w  #600,Menu_ram_NextMessageTimer ; 10 seconds
                rts
; End of function Shop_ShowBikeDescription

; *************************************************
; Function Shop_GameTick
; *************************************************

Shop_GameTick:
; draw frame buffer
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM

                bsr.w   Shop_UpdateScroll
                move.w  Shop_ScrollPos,d0
                subi.w  #$160,d0
                beq.w   @loc_7A30
                move.l  Global_ram_PalettePtr,d0
                move.w  #0,d1
                move.w  #$40,d2
                jsr     DmaWriteCRAM
@loc_7A30:
                move.w  MainMenu_ram_ButtonsPlayerA,MainMenu_ram_ChangedButtonsPlayerA
                jsr     (GetInputPlayerA).w
                move.w  d0,MainMenu_ram_ButtonsPlayerA
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerA
                andi.w  #$80,d0
                bne.w   @loc_7B30
                move.w  MainMenu_ram_ButtonsPlayerB,MainMenu_ram_ChangedButtonsPlayerB
                jsr     (GetInputPlayerB).w
                move.w  d0,MainMenu_ram_ButtonsPlayerB
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerB
                andi.w  #$80,d0
                bne.w   @loc_7B30
                move.w  MainMenu_ram_ChangedButtonsPlayerB,d0
                beq.w   @loc_7A98
                and.w   MainMenu_ram_ButtonsPlayerB,d0
                beq.w   @loc_7A98
                move.l  #MainMenu_ram_ButtonsPlayerB,Menu_ram_CurrentButtonsPtr
                jsr     Shop_HandleInput
@loc_7A98:
                move.w  MainMenu_ram_ChangedButtonsPlayerA,d0
                beq.w   @loc_7ABC
                and.w   MainMenu_ram_ButtonsPlayerA,d0
                beq.w   @loc_7ABC
                move.l  #MainMenu_ram_ButtonsPlayerA,Menu_ram_CurrentButtonsPtr
                jsr     Shop_HandleInput
@loc_7ABC:
                subq.w  #1,Menu_ram_MessageBlinkTimer
                subq.w  #1,Menu_ram_NextMessageTimer
                bpl.w   @loc_7B16
                move.w  #$1E,Menu_ram_MessageBlinkTimer
                move.w  #$12C,Menu_ram_NextMessageTimer
                addq.w  #8,Menu_ram_CurrentMessageId
                cmpi.w  #$1E0,Menu_ram_CurrentMessageId
                bpl.w   @loc_7AF6
                move.w  #$1E0,Menu_ram_CurrentMessageId
@loc_7AF6:
                move.w  Menu_ram_CurrentMessageId,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                bne.w   @loc_7B16
                move.w  #$1E0,Menu_ram_CurrentMessageId
@loc_7B16:
                bsr.w   Menu_ShowMessage
                cmpi.l  #0,ram_FF0910
                bne.w   @loc_7B3A
@loc_7B28:
                jsr     AudioFunc1
                rts
@loc_7B30:
                move.l  #$5F28,ram_FF0910
@loc_7B3A:
                jsr     AudioFunc4
                move.l  #0,ram_UpdateFunction
                bra.s   @loc_7B28
; End of function Shop_GameTick

; *************************************************
; Function Shop_HandleInput
; *************************************************

Shop_HandleInput:
                move.b  d0,ram_FF0952
                btst    #6,ram_FF0952
                beq.w   @loc_7B68
                move.l  #HighScore_Init,ram_FF0910
@loc_7B68:
                btst    #4,ram_FF0952
                beq.w   @loc_7B7E
                move.l  #RaceResults_Init,ram_FF0910
@loc_7B7E:
                btst    #5,ram_FF0952
                beq.w   @loc_7C64
                tst.w   Menu_ram_Player
                bne.w   @loc_7BF8
                move.w  Shop_CurrentBikeId,d0
                cmp.w   Menu_ram_BikeIdPlayerA,d0
                bne.w   @loc_7BAC
                bsr.w   sub_7EA2
                bra.w   @loc_7C64
@loc_7BAC:
                lea     Shop_dPrices,a0
                move.w  Menu_ram_BikeIdPlayerA,d0
                asl.w   #1,d0
                move.w  (a0,d0.w),d0
                asr.w   #1,d0
                neg.w   d0
                adda.w  Shop_CurrentBikeId,a0
                adda.w  Shop_CurrentBikeId,a0
                add.w   (a0),d0
                ext.l   d0
                cmp.l   Menu_ram_MoneyPlayerA,d0
                ble.w   @loc_7BE4
                bsr.w   sub_7F02
                bra.w   @loc_7C64
@loc_7BE4:
                sub.l   d0,Menu_ram_MoneyPlayerA
                move.w  Shop_CurrentBikeId,Menu_ram_BikeIdPlayerA
                bra.w   @loc_7C5C
@loc_7BF8:
                move.w  Shop_CurrentBikeId,d0
                cmp.w   Menu_ram_BikeIdPlayerB,d0
                bne.w   @loc_7C10
                bsr.w   sub_7EA2
                bra.w   @loc_7C64
@loc_7C10:
                lea     Shop_dPrices,a0
                move.w  Menu_ram_BikeIdPlayerB,d0
                asl.w   #1,d0
                move.w  (a0,d0.w),d0
                asr.w   #1,d0
                neg.w   d0
                adda.w  Shop_CurrentBikeId,a0
                adda.w  Shop_CurrentBikeId,a0
                add.w   (a0),d0
                ext.l   d0
                cmp.l   Menu_ram_MoneyPlayerB,d0
                ble.w   @loc_7C48
                bsr.w   sub_7F02
                bra.w   @loc_7C64
@loc_7C48:
                sub.l   d0,Menu_ram_MoneyPlayerB
                move.w  Shop_CurrentBikeId,Menu_ram_BikeIdPlayerB
                bra.w   @loc_7C5C
@loc_7C5C:
                bsr.w   Shop_DrawCreditsAndPrice
                jsr     (MenuPassword_CreatePassword).w
@loc_7C64:
                btst    #3,ram_FF0952
                beq.w   @loc_7CE0
                move.w  Shop_ScrollPos,d0
                cmp.w   #$160,d0
                bne.w   @loc_7CE0
                lea     Shop_dBikePalettes,a1
                move.w  Shop_CurrentBikeId,d0
                asl.w   #5,d0
                adda.w  d0,a1
                addq.w  #1,Shop_CurrentBikeId
                andi.w  #7,Shop_CurrentBikeId
                move.w  Shop_CurrentBikeId,d0
                lea     Shop_dBikePalettes,a0
                move.w  Shop_CurrentBikeId,d0
                asl.w   #5,d0
                adda.w  d0,a0
                move.w  Shop_CurrentBikeId,d0
                bsr.w   Shop_DrawBikes
                move.w  Shop_CurrentBikeId,d0
                bsr.w   Shop_DrawBikeName
                move.w  Shop_CurrentBikeId,d0
                bsr.w   Shop_ShowBikeDescription
                bsr.w   Shop_PrepareMessages
                bsr.w   Shop_DrawCreditsAndPrice
                subi.w  #$D0,Shop_ScrollPos
@loc_7CE0:
                btst    #2,ram_FF0952
                beq.w   @locret_7D5C
                move.w  Shop_ScrollPos,d0
                cmp.w   #$160,d0
                bne.w   @locret_7D5C
                lea     Shop_dBikePalettes,a1
                move.w  Shop_CurrentBikeId,d0
                asl.w   #5,d0
                adda.w  d0,a1
                subq.w  #1,Shop_CurrentBikeId
                andi.w  #7,Shop_CurrentBikeId
                move.w  Shop_CurrentBikeId,d0
                lea     Shop_dBikePalettes,a0
                move.w  Shop_CurrentBikeId,d0
                asl.w   #5,d0
                adda.w  d0,a0
                move.w  Shop_CurrentBikeId,d0
                bsr.w   Shop_DrawBikes
                move.w  Shop_CurrentBikeId,d0
                bsr.w   Shop_DrawBikeName
                move.w  Shop_CurrentBikeId,d0
                bsr.w   Shop_ShowBikeDescription
                bsr.w   Shop_PrepareMessages
                bsr.w   Shop_DrawCreditsAndPrice
                addi.w  #$D0,Shop_ScrollPos
@locret_7D5C:
                rts
; End of function Shop_HandleInput

; *************************************************
; Function Shop_DrawCreditsAndPrice
; *************************************************

Shop_DrawCreditsAndPrice:
; draw credit amount string
                move.w  #$6000,d4
                lea     Menu_ram_TempString,a0
                move.w  #19,(a0)+ ; y
                move.w  #0,(a0)+ ; x
                move.w  #1,(a0)+ ; height
                move.w  #12,(a0)+ ; width
                move.l  #'    ',(a0)+
                move.l  #'    ',(a0)+
                move.l  #'    ',(a0)+

                move.l  Menu_ram_MoneyPlayerA,d2
                move.w  Menu_ram_BikeIdPlayerA,d3
                tst.w   Menu_ram_Player
                beq.w   @loc_7DAC
                move.l  Menu_ram_MoneyPlayerB,d2
                move.w  Menu_ram_BikeIdPlayerB,d3
@loc_7DAC:
                lea     Shop_dPrices,a1
                asl.w   #1,d3
                move.w  (a1,d3.w),d3 ; get your bike price in units of 10$
                lsr.w   #1,d3
                ext.l   d3
                add.l   d3,d2 ; add half price to your money as trade in value
                move.w  Shop_CurrentBikeId,d1
                asl.w   #1,d1
                clr.l   d0
                move.w  (a1,d1.w),d0 ; get current bike price
                cmp.l   d0,d2
                bmi.w   @loc_7DD6
                move.w  #$4000,d4 ; not enough money : palette line 2
@loc_7DD6:
                subq.w  #3,a0
                move.l  d2,d0
                bsr.w   sub_C79A
                lea     Menu_ram_TempString,a0
                bsr.w   Shop_DrawString ; draw money amount (including trade in price)
; draw bike price string
                lea     Menu_ram_TempString,a0
                move.w  #19,(a0)+
                move.w  #28,(a0)+
                move.w  #1,(a0)+
                move.w  #12,(a0)+
                move.l  #'    ',(a0)+
                move.l  #'    ',(a0)+
                move.l  #'    ',(a0)+
                move.w  Menu_ram_BikeIdPlayerA,d0
                tst.w   Menu_ram_Player
                beq.w   @loc_7E26
                move.w  Menu_ram_BikeIdPlayerB,d0
@loc_7E26:
                cmp.w   Shop_CurrentBikeId,d0
                beq.w   @alreadyOwned
                lea     Shop_dPrices,a1
                move.w  Shop_CurrentBikeId,d0
                asl.w   #1,d0
                andi.l  #$FFFF,d0
                move.w  (a1,d0.w),d0
                subq.w  #4,a0
                bsr.w   sub_C79A
                bra.w   @loc_7E64
@alreadyOwned:
                move.l  #$72732920,-(a0) ; text '(its yours)'
                move.l  #$20796F75,-(a0)
                move.l  #$28697473,-(a0)
@loc_7E64:
                lea     Menu_ram_TempString,a0
                bsr.w   Shop_DrawString
                rts
; End of function Shop_DrawCreditsAndPrice

; *************************************************
; Function Shop_DrawString
; *************************************************

Shop_DrawString:
                move.l  a0,-(sp)
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString
                movea.l (sp)+,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Shop_DrawString

; *************************************************
; Function sub_7EA2
; *************************************************

sub_7EA2:
                move.w  #$1D8,Menu_ram_CurrentMessageId
                move.w  #$1E,Menu_ram_MessageBlinkTimer
                move.w  #$12C,Menu_ram_NextMessageTimer
                lea     (unk_51C6).w,a0
                lea     ram_FF089A,a1
                move.l  (a0)+,(a1)+
                move.w  (a0),d0
                move.w  2(a0),d1
                move.l  (a0)+,(a1)+
                mulu.w  d1,d0
                subq.w  #1,d0
@loc_7ED2:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_7ED2
                lea     Shop_BikeDescriptions,a0
                move.w  Shop_CurrentBikeId,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0
                addq.w  #8,a0
                move.w  -2(a0),d0
                suba.w  d0,a1
                sub.w   d0,d1
                asr.w   #1,d1
                suba.w  d1,a1
                subq.w  #1,d0
@loc_7EFA:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_7EFA
                rts
; End of function sub_7EA2

; *************************************************
; Function sub_7F02
; *************************************************

sub_7F02:
                move.w  #$1D8,Menu_ram_CurrentMessageId
                move.w  #$1E,Menu_ram_MessageBlinkTimer
                move.w  #$12C,Menu_ram_NextMessageTimer
                lea     (unk_520A).w,a0
                lea     ram_FF089A,a1
                move.l  (a0)+,(a1)+
                move.w  (a0),d0
                move.w  2(a0),d1
                move.l  (a0)+,(a1)+
                mulu.w  d1,d0
                subq.w  #1,d0
@loc_7F32:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_7F32
                lea     Shop_BikeDescriptions,a0
                move.w  Shop_CurrentBikeId,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0
                addq.w  #8,a0
                move.w  -2(a0),d0
                suba.w  d0,a1
                sub.w   d0,d1
                asr.w   #1,d1
                suba.w  d1,a1
                subq.w  #1,d0
@loc_7F5A:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_7F5A
                rts
; End of function sub_7F02

; *************************************************
; Function Shop_PrepareMessages
; *************************************************

Shop_PrepareMessages:
; copy text "Press C to buy a new bike"
                lea     (unk_50AA).w,a0
                lea     Shop_StrBuyNewBike,a1
                move.l  (a0)+,(a1)+
                move.w  (a0),d0 ; height
                move.w  2(a0),d1 ; width
                move.l  (a0)+,(a1)+
                mulu.w  d1,d0
                subq.w  #1,d0
@loc_7F7A:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_7F7A

                lea     Shop_BikeDescriptions,a0
                move.w  Shop_CurrentBikeId,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0
                addq.w  #6,a0
                move.w  (a0)+,d0
                suba.w  d0,a1
                sub.w   d0,d1
                asr.w   #1,d1
                suba.w  d1,a1
                subq.w  #1,d0
@loc_7FA0:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_7FA0

                lea     (unk_5116).w,a0
                lea     ram_FF07C2,a1
                move.l  (a0)+,(a1)+
                move.w  (a0),d0
                move.w  2(a0),d1
                move.l  (a0)+,(a1)+
                mulu.w  d1,d0
                subq.w  #1,d0
@loc_7FBE:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_7FBE

                lea     Shop_BikeDescriptions,a0
                move.w  Shop_CurrentBikeId,d0
                subq.w  #1,d0
                andi.w  #7,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0
                addq.w  #6,a0
                move.w  (a0)+,d0
                suba.w  d0,a1
                sub.w   d0,d1
                asr.w   #1,d1
                suba.w  d1,a1
                subq.w  #1,d0
@loc_7FEA:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_7FEA
                lea     (unk_516E).w,a0
                lea     ram_FF082E,a1
                move.l  (a0)+,(a1)+
                move.w  (a0),d0
                move.w  2(a0),d1
                move.l  (a0)+,(a1)+
                mulu.w  d1,d0
                subq.w  #1,d0
@loc_8008:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_8008
                lea     Shop_BikeDescriptions,a0
                move.w  Shop_CurrentBikeId,d0
                addq.w  #1,d0
                andi.w  #7,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0
                addq.w  #6,a0
                move.w  (a0)+,d0
                suba.w  d0,a1
                sub.w   d0,d1
                asr.w   #1,d1
                suba.w  d1,a1
                subq.w  #1,d0
@loc_8034:
                move.b  (a0)+,(a1)+
                dbf     d0,@loc_8034
                rts
; End of function Shop_PrepareMessages

; *************************************************
; Function Shop_DrawBikes
; d0 - current bike index
; a0 - current bike def
; a1 - other bikes def
; *************************************************

Shop_DrawBikes:
                move.w  d0,-(sp) ; save d0
; write palette line 2, for bike in center
                movea.l Global_ram_PalettePtr,a2
                adda.w  #$40,a2 ; get palette 2 offset
                move.l  (a0)+,(a2)+ ; copy entries 0-3 -> 0-3
                move.l  (a0)+,(a2)+
                addq.w  #2,a0 ; skip entry 4 in source
                move.w  $16(a0),(a2)+ ; copy entry 13 -> 4
                move.l  (a0)+,(a2)+ ; copy entries 5-12 -> 5-12
                move.l  (a0)+,(a2)+
                move.l  (a0)+,(a2)+
                move.l  (a0)+,(a2)+
; write palette line 3, for bikes right and left
                movea.l Global_ram_PalettePtr,a2
                adda.w  #$60,a2
                move.l  (a1)+,(a2)+
                move.l  (a1)+,(a2)+
                addq.w  #2,a1
                move.w  $16(a1),(a2)+
                move.l  (a1)+,(a2)+
                move.l  (a1)+,(a2)+
                move.l  (a1)+,(a2)+
                move.l  (a1)+,(a2)+
; the bike before the previous one
                lea     Shop_BikeImageTable,a0
                move.w  (sp),d0
                subq.w  #2,d0
                andi.w  #7,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0 ; get bike image source
                move.w  #18,d0 ; width
                move.w  #9,d1 ; height
                move.w  #3,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$E000,d4 ; base tile index = $0, palette line = 3, high priority
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                jsr     (WriteNametable).w
; previous bike
                lea     Shop_BikeImageTable,a0
                move.w  (sp),d0
                subq.w  #1,d0
                andi.w  #7,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0 ; get bike image source
                move.w  #18,d0 ; width
                move.w  #9,d1 ; height
                move.w  #29,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$E000,d4 ; base tile index = $0, palette line = 3, high priority
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                jsr     (WriteNametable).w
; current bike
                lea     Shop_BikeImageTable,a0
                move.w  (sp),d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0 ; get bike image source
                move.w  #18,d0 ; width
                move.w  #9,d1 ; height
                move.w  #55,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$C000,d4 ; base tile index = $0, palette line = 2, high priority
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                jsr     (WriteNametable).w
; next bike
                lea     Shop_BikeImageTable,a0
                move.w  (sp),d0
                addq.w  #1,d0
                andi.w  #7,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0 ; get bike image source
                move.w  #18,d0 ; width
                move.w  #9,d1 ; height
                move.w  #81,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$E000,d4 ; base tile index = $0, palette line = 3, high priority
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                jsr     (WriteNametable).w
; the bike after the next one
                lea     Shop_BikeImageTable,a0
                move.w  (sp),d0
                addq.w  #2,d0
                andi.w  #7,d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0 ; get bike image source
                move.w  #18,d0 ; width
                move.w  #9,d1 ; height
                move.w  #107,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$E000,d4 ; base tile index = $0, palette line = 3, high priority
                move.w  #$4000,d5 ; destination = Scroll A/B
                move.w  #128,d6 ; plane width
                jsr     (WriteNametable).w

                move.w  (sp)+,d0
                rts
; End of function Shop_DrawBikes

; *************************************************
; Function Shop_UpdateScroll
; *************************************************

Shop_UpdateScroll:
                move.w  Shop_ScrollPos,d0
                subi.w  #$160,d0 ; scroll speed = Shop_ScrollPos - $160
                beq.w   @return ; if ScrollPos == $160 then return
; adjust speed so it's absolute values doesn't exceed 8
                cmp.w   #8,d0
                ble.w   @loc_8192
                move.w  #8,d0
@loc_8192:
                cmp.w   #$FFF8,d0
                bpl.w   @loc_819E
                move.w  #$FFF8,d0
@loc_819E:
; fill scroll table
                sub.w   d0,Shop_ScrollPos
                lea     VdpCtrl,a0
                lea     VdpData,a1
                move.w  #$8F20,(a0) ; Auto-increment: $20
                VDP_VRAM_WRITE $64E2,(a0)
; fill scroll table
                move.w  #8,d0
                move.w  Shop_ScrollPos,d1
                neg.w   d1
@loc_81C6:
                move.w  d1,(a1)
                dbf     d0,@loc_81C6

                move.w  #$8F02,(a0) ; Auto-increment: $2
@return:
                rts
; End of function Shop_UpdateScroll

Shop_BikeDescriptions:
    dc.l Shop_StrShuriken400
    dc.l Shop_StrPanda600
    dc.l Shop_StrBanzai750
    dc.l Shop_StrKamikaze750
    dc.l Shop_StrShuriken1000
    dc.l Shop_StrFerruci850
    dc.l Shop_StrPanda750
    dc.l Shop_StrDiablo1000

Shop_StrShuriken400:
    dc.w 18,13,2,14
    dc.b " Shuriken 400 "
    dc.b " 60 HP 400 lbs"
Shop_StrPanda600:
    dc.w 18,14,2,14
    dc.b "   Panda 600  "
    dc.b " 90 HP 450 lbs"
Shop_StrBanzai750:
    dc.w 18,14,2,14
    dc.b "  Banzai 750  "
    dc.b "100 HP 465 lbs"
Shop_StrKamikaze750:
    dc.w 18,14,2,14
    dc.b " Kamikaze 750 "
    dc.b "105 HP 475 lbs"
Shop_StrShuriken1000:
    dc.w 18,14,2,14
    dc.b " Shuriken 1000"
    dc.b "135 HP 510 lbs"
Shop_StrFerruci850:
    dc.w 18,14,2,14
    dc.b "  Ferruci 850 "
    dc.b "110 HP 470 lbs"
Shop_StrPanda750:
    dc.w 18,14,2,14
    dc.b "   Panda 750  "
    dc.b "120 HP 450 lbs"
Shop_StrDiablo1000:
    dc.w 18,14,2,14
    dc.b "  Diablo 1000 "
    dc.b "150 HP 450 lbs"

Shop_dPrices:
    dc.w 400
    dc.w 500
    dc.w 700
    dc.w 800
    dc.w 1200
    dc.w 1400
    dc.w 2000
    dc.w 2500

Shop_BikeImageTable:
    dc.l Shop_ImageBike3
    dc.l Shop_ImageBike3
    dc.l Shop_ImageBike3
    dc.l Shop_ImageBike1
    dc.l Shop_ImageBike1
    dc.l Shop_ImageBike2
    dc.l Shop_ImageBike1
    dc.l Shop_ImageBike2
; *************************************************
; character.asm - pre-race rider/opponent introduction
; ROM range: $59C4-$5F27
; Status:    analyzed (static; rendering dynamically TODO)
; API:       Character_Init, Character_GameTick
; *************************************************

; *************************************************
; Function Character_Init
; Builds the rider/opponent intro: VDP setup, background/gamepad/portrait, opponent
; record (unk_19A12), name/quote/palette, optional bike overlay, font, message, DMA.
; In:  Menu_ram_Player, PlayerA/BLevel, CurrentTrackId, ram_FF0520 (extra field)
; Out: Menu_ram_FrameBuffer -> VRAM $7000; VRAM $A000-$D000 assets; palette
; Clobbers: d0-d7, a0-a3
; Notes: only reached on the non-demo path (top_level.asm $7E782).
; *************************************************

Character_Init:
                move.w  #0,(MainMenu_ram_ButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerB).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerB).l
                move.w  #$FFFF,(Menu_ram_MessageBlinkTimer).l
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l
                move.w  #300,(Menu_ram_NextMessageTimer).l ; 5 seconds
                move.w  #(8*18),(Menu_ram_CurrentMessageId).l ; empty message
                move.l  #Global_ram_Palette,(Global_ram_PalettePtr).l
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
                move.w  #$921C,(a0) ; WindowY: 28 cells
; clear HScroll
                VDP_VRAM_WRITE $6000, (a0) ; HScroll 
                move.w  #3,d0
.loopClearHScroll:
                move.l  #0,(VdpData).l
                dbf     d0,.loopClearHScroll
                VDP_VSRAM_WRITE $0, (a0)
                move.l  #0,(VdpData).l
; clear default tile
                movea.l #VdpData,a0
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
.loopDefaultTile:
                move.l  #0,(a0)
                dbf     d0,.loopDefaultTile
; clear scroll A/B
                VDP_VRAM_WRITE $4000,VdpCtrl
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1
                move.w  #$6FF,d0 ; $E00 words
.loopClearAB:
                move.l  d1,(a0)
                dbf     d0,.loopClearAB
; load the main-menu background (the visible tiles stay at $8000 from the menu;
; this write targets $4000 and is later overwritten by the nametable)
                lea     (img_MainMenu_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM, why $4000 ??
                move.l  #$4000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; and draw it
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; base tile index, address = $8000
                move.w  #$4000,d5 ; destination VRAM address = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $4E8).l,a0
                jsr     (WriteNametable).w
; load the gamepad diagram (also supplies the button-icon tiles at $A000)
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
                move.w  #$4000,d5 ; destination VRAM address = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $B48).l,a0
                jsr     (WriteNametable).w
; clear the 64x28 window frame buffer to the default tile
                lea     (Menu_ram_FrameBuffer).l,a0
                move.l  #$7FF07FF,d1
                move.w  #$37F,d0
.loopClearFB:
                move.l  d1,(a0)+
                dbf     d0,.loopClearFB

; load the portrait panel (11 tiles + 12x14 nametable) to VRAM $B000
                lea     (unk_7EA66).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l

                move.l  #$B000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                move.w  #12,d0 ; width
                move.w  #14,d1 ; height
                move.w  #2,d2 ; x
                move.w  #5,d3 ; y
                move.w  #$580,d4 ; base tile index, address = $B000
                move.w  #64,d6 ; plane width
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                lea     (Intro_ram_ImageBuffer + $168).l,a0 ; source
                jsr     (WriteNametableToBuffer).w

.loc_5BAA:
; select the opponent record: copy the player's 2-bit "extra" field, then pick a
; random variant (0/8/$10; $18 is used instead of 0 when extra != 0)
                move.w  (ram_FF0522).l,(ram_FF0520).l
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_5BC8
                move.w  (ram_FF0524).l,(ram_FF0520).l ; player B
.loc_5BC8:
                jsr     (Rand_GetWord).l
                andi.w  #$18,d0
                cmp.w   #$18,d0
                beq.s   .loc_5BAA

                tst.w   d0
                bne.w   .loc_5BEC
                tst.w   (ram_FF0520).l
                ble.w   .loc_5BEC
                move.w  #$18,d0
.loc_5BEC:
; unk_19A12 = [level][track][variant] records of (quote_ptr, image_ptr)
                lea     (unk_19A12).l,a0
                adda.w  d0,a0
                move.w  (Menu_ram_PlayerALevel).l,d0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_5C0A
                move.w  (Menu_ram_PlayerBLevel).l,d0 ; player B
.loc_5C0A:
                subq.w  #1,d0
                mulu.w  #$A0,d0
                adda.w  d0,a0
                move.w  (Menu_ram_CurrentTrackId).l,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
; record: (a0)=quote, 4(a0)=image. The image is preceded by an 8-byte prefix
; whose odd bytes form the image-header pointer.
                movea.l 4(a0),a3 ; get character image
                move.l  a3,-(sp)
                move.l  (a0),-(sp) ; get character quote
; rebuild the header pointer from the four odd bytes of the prefix
                move.b  -7(a3),d0
                lsl.l   #8,d0
                move.b  -5(a3),d0
                lsl.l   #8,d0
                move.b  -3(a3),d0
                lsl.l   #8,d0
                move.b  -1(a3),d0
                move.l  d0,-(sp) ; character name
; decompress image
                lea     (Intro_ram_ImageBuffer).l,a1 ; destination
                jsr     (UncompressW).l

; write the portrait tiles: header -6 = image offset in the decompressed buffer
                move.l  #$C000,d0 ; chararcter image VRAM address
                movea.l (sp),a0
                movea.w -6(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     (WriteToVRAM).l
; draw the 10x12 portrait at (3,6); header -4 = nametable offset (+4 skips header)
                move.w  #10,d0 ; width
                move.w  #12,d1 ; height
                move.w  #3,d2 ; x
                move.w  #6,d3 ; y
                move.w  #$600,d4 ; base tile index, address = $C000
                move.w  #64,d6 ; plane width
                movea.l (sp),a0
                movea.w -4(a0),a0
                adda.l  #Intro_ram_ImageBuffer + 4,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w
; header -2 = palette offset; copy 4x8 longs (64 colours) to the global palette
                movea.l (sp),a0
                movea.w -2(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l (Global_ram_PalettePtr).l,a1

                move.w  #7,d0
.loopCopyPalette0:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopCopyPalette0

                move.w  #7,d0
.loopCopyPalette1:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopCopyPalette1

                move.w  #7,d0
.loopCopyPalette2:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopCopyPalette2

                move.w  #7,d0
.loopCopyPalette3:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopCopyPalette3

; header -10 = name string pointer; +6 skips the 6-byte name descriptor
                movea.l (sp)+,a0
                movea.l -10(a0),a0
                addq.w  #6,a0
                lea     (Menu_ram_TempString).l,a1
                move.w  #19,(a1)+
                move.w  #3,(a1)+
                move.w  #1,(a1)+
                move.w  #10,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+

                clr.w   d0
                movea.l a1,a0
.loc_5CF2:
                cmpi.b  #$20,-(a0)
                bne.w   .loc_5CFE
                addq.w  #1,d0
                bra.s   .loc_5CF2

.loc_5CFE:
                lea     -$A(a1),a0

.loc_5D02:
                cmpi.b  #$20,(a0)+
                bne.w   .loc_5D0E
                subq.w  #1,d0
                bra.s   .loc_5D02

.loc_5D0E:
                asr.w   #1,d0
                ble.w   .loc_5D58
                subq.w  #1,d0
                lea     -$A(a1),a0

.loc_5D1A:
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
                dbf     d0,.loc_5D1A

.loc_5D58:
                lea     (Menu_ram_TempString).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString

                lea     (Menu_ram_TempString).l,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6 ; '@'
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer

                movea.l (sp),a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString

                movea.l (sp)+,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                asr.w   #1,d3
                move.w  #$6000,d4
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer

                move.l  (sp)+,d0
; Natasha's default image with a non-zero extra field also shows the overlaid bike
                cmp.l   #unk_AF902,d0
                bne.w   .loc_5E2C
                tst.w   (ram_FF0520).l
                ble.w   .loc_5E2C

                lea     (unk_B1506).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$D000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                move.w  #6,d0
                move.w  #7,d1
                move.w  #6,d2
                move.w  #9,d3
                move.w  #$680,d4
                move.w  #$40,d6
                lea     (Menu_ram_FrameBuffer).l,a1
                lea     (Intro_ram_ImageBuffer + $548).l,a0
                jsr     (WriteNametableToBuffer).w
.loc_5E2C:
; load the font used by the name, quote and message text
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                bsr.w   Menu_ShowMessage

; push the 64x28 window buffer to VRAM $7000
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     (DmaWriteVRAM).l
                rts
; End of function Character_Init

; *************************************************
; Function Character_GameTick
; Per-frame update: push the frame buffer, edge-detect pad A/B, advance the timed
; message, and exit to the race on a newly pressed button or the message terminator.
; In:  pad input; Menu_ram_CurrentMessageId/NextMessageTimer
; Out: Race_ram_ActiveController (0/1) on exit; ram_UpdateFunction=0 at end stage
; Clobbers: d0-d2/a0
; *************************************************

Character_GameTick:
; push the window buffer every frame
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     (DmaWriteVRAM).l

; pad A: ~input & previous raw buttons detects a newly pressed button
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l
                eori.w  #$FFFF,d0
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d1
                and.w   d1,d0
                beq.w   .loc_5EAA
                move.b  #0,(Race_ram_ActiveController).l
                bra.w   .endStage
.loc_5EAA:
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                eori.w  #$FFFF,d0
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d1
                and.w   d1,d0
                beq.w   .loc_5EDA
                move.b  #1,(Race_ram_ActiveController).l
                bra.w   .endStage

.loc_5EDA:
; every 300 frames (5 s) advance to the next message; $FFFFFFFF ends the screen
                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .loc_5F0A
                move.w  #300,(Menu_ram_NextMessageTimer).l
                addq.w  #8,(Menu_ram_CurrentMessageId).l
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                beq.w   .endStage

.loc_5F0A:
                bsr.w   Menu_ShowMessage

.loc_5F0E:
                jsr     (AudioFunc1).l
                rts
; exit stage: stop the screen and play the transition sound
.endStage:
                jsr     (AudioFunc4).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .loc_5F0E
; End of function Character_GameTick
; *************************************************
; Function Menu_Init
; *************************************************

Menu_Init:
                move.w  #0,(MainMenu_ram_DemoMode).l
                move.w  #0,(MainMenu_ram_FrameCounter).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerB).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerB).l
                move.w  #240,(Menu_ram_NextMessageTimer).l ; 4 seconds
                move.w  #30,(Menu_ram_MessageBlinkTimer).l ; 0.5 second
                move.w  #(8*6),(Menu_ram_CurrentMessageId).l ; default message "Press A to start race"
                move.l  #Global_ram_Palette,(Global_ram_PalettePtr).l
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l
                move.w  #9,(MenuPassword_ram_CursorY).l
                move.w  #1,(MenuPassword_ram_CursorX).l
                tst.w   (Menu_ram_Player).l
                bne.w   .playerB ; jump if player B selected
                tst.l   (Menu_ram_MoneyPlayerA).l
                bpl.w   .loc_3494
                jsr     (sub_1A2C).w
                bra.w   .loc_3494
.playerB:
                tst.l   (Menu_ram_MoneyPlayerB).l
                bpl.w   .loc_3494
                jsr     (sub_1B48).w

.loc_3494:
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
                move.w  #$9100,(a0) ; WindowX = 0
                move.w  #$921C,(a0) ; WindowY = 28 cells
; clear sprites
                VDP_VRAM_WRITE $6000,(a0) ; write to sprite table
                move.w  #3,d0
.loopClearSprites:
                move.l  #0,(VdpData).l
                dbf     d0,.loopClearSprites

                VDP_VSRAM_WRITE $0,(a0)
                move.l  #0,(VdpData).l ; set zero vscroll
; clear default tile
                movea.l #VdpData,a0
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
.loopClearDefaultTile:
                move.l  #0,(a0)
                dbf     d0,.loopClearDefaultTile
; fill with default tiles
                VDP_VRAM_WRITE $4000,VdpCtrl ;write to A/B nametable
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1 ; d1 = $07FF07FF, low priority, pal 0, no flip, tile address $FFE0
                move.w  #$6FF,d0 ; $700 * 2 = $E00 tiles
.loopFillBlack:
                move.l  d1,(a0)
                dbf     d0,.loopFillBlack
; load menu background image
                lea     (img_MainMenu_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write background image to VRAM
                move.l  #$8000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; write background nametable
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; first tile index, address = $8000
                move.w  #$4000,d5 ; VRAM address = Scroll A/B
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer + $4E8).l,a0
                jsr     (WriteNametable).w ; source
; load race selection background image
                lea     (img_MainMenu_RaceSelectionBackground).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
; write it to VRAM
                move.l  #$9000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; write race selection background nametable
                move.w  #40,d0 ; width
                move.w  #14,d1 ; height
                move.w  #0,d2 ; x
                move.w  #4,d3 ; y
                move.w  #$480,d4 ; first tile index, address = $9000
                move.w  #$4000,d5 ; VRAM address = Scroll A/B
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer + $2E8).l,a0
                jsr     (WriteNametable).w
; load paler selection border image
                lea     (img_PasswordMenu_PlayerSelection).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write it to VRAM, but it's initially hidden
                move.l  #$9400,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; load gamepad image
                lea     (img_Gamepad).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
; write it to VRAM
                move.l  #$A000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; write gamepad image nametable
                move.w  #12,d0 ; width
                move.w  #6,d1 ; height
                move.w  #2,d2 ; x
                move.w  #22,d3 ; y
                move.w  #$500,d4 ; first tile index, address = $A000
                move.w  #$4000,d5 ; VRAM address = Scroll A/B
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer + $B48).l,a0
                jsr     (WriteNametable).w

                lea     (img_mainMenu_PlayerSelection).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$B000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; clear Menu_ram_FrameBuffer
                lea     (Menu_ram_FrameBuffer).l,a0
                move.l  #$7FF07FF,d1 ; default tile
                move.w  #$37F,d0 ; buffer size $380 * 4 = $E00, $700 tiles
.loc_3670:
                move.l  d1,(a0)+
                dbf     d0,.loc_3670
; load race names image
                lea     (img_MainMenu_RaceBadges).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write it to VRAM
                move.l  #$C000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; create nametable in Race_ram_ImageBuffer2
                move.w  #12,d0 ; height
                move.w  #12,d1 ; width
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #12,d6 ; plane width
                lea     (Race_ram_ImageBuffer2).l,a1 ; destination
                lea     (Intro_ram_ImageBuffer + $D88).l,a0 ; source
                jsr     (WriteNametableToBuffer).l
; load race cards
                lea     (img_mainMenu_RaceCards).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write it to VRAM
                move.l  #$D000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; and append nametable in Race_ram_ImageBuffer2, just below names images
                move.w  #12,d0 ; height
                move.w  #30,d1 ; width
                move.w  #0,d2 ; x
                move.w  #12,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #12,d6 ; plane width
                lea     (Race_ram_ImageBuffer2).l,a1
                lea     (Intro_ram_ImageBuffer + $2768).l,a0
                jsr     (WriteNametableToBuffer).l
; load palette for all menu images
                lea     (Intro_ram_ImageBuffer + $26E4).l,a0
                movea.l (Global_ram_PalettePtr).l,a1
; copy palette line 0
                move.w  #7,d0
.loopPalette0:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopPalette0
; copy palette line 1
                move.w  #7,d0
.loopPalette1:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopPalette1
; copy palette line 2
                move.w  #7,d0
.loopPalette2:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopPalette2
; copy palette line 3
                move.w  #7,d0
.loopPalette3:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopPalette3
; load font
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write font to VRAM
                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                jsr     (Menu_ShowMessage).l
                jsr     (sub_2B2E).w
                move.w  (Menu_ram_CurrentTrackId).l,d0
                jsr     (Menu_DrawRaceSelection).l
                jsr     (Menu_DrawPlayerInfo).l
; write framebuffer to VRAM
                move.l  #Menu_ram_FrameBuffer,d0 ; source
                move.w  #$7000,d1 ; destination : window Nametable
                move.w  #$700,d2 ; size in words 64 x 28
                jsr     (DmaWriteVRAM).l

                tst.w   (ram_MusicEnabled).l
                beq.w   .return
                moveq   #1,d0
                jsr     (AudioFunc3).l

.return:
                rts
; End of function Menu_Init

; *************************************************
; Function WriteNametableToBuffer
; d0 - height in cells
; d1 - width in cells
; d2 - topLeftX
; d3 - topLeftY
; d4 - base tile index
; d6 - plane width
; a0 - source buffer
; a1 - destination buffer
; *************************************************

WriteNametableToBuffer:
                asl.w   #1,d6
                mulu.w  d6,d3
                sub.w   d0,d6
                sub.w   d0,d6
                adda.w  d3,a1
                asl.w   #1,d2
                adda.w  d2,a1
                subq.w  #1,d1
                subq.w  #1,d0
                move.w  d0,d2

.loc_37BE:
                move.w  d2,d0

.loc_37C0:
                move.w  (a0)+,d3
                add.w   d4,d3
                move.w  d3,(a1)+
                dbf     d0,.loc_37C0
                adda.w  d6,a1
                dbf     d1,.loc_37BE
                rts
; End of function WriteNametableToBuffer

; *************************************************
; Function WriteNametableToBufferMasked
; d0 - height in cells
; d1 - width in cells
; d2 - topLeftX
; d3 - topLeftY
; d4 - base tile index
; d5 - mask tile index
; d6 - plane width
; a0 - source buffer
; a1 - destination buffer
; *************************************************

WriteNametableToBufferMasked:
                asl.w   #1,d6
                mulu.w  d6,d3
                sub.w   d0,d6
                sub.w   d0,d6
                adda.w  d3,a1
                asl.w   #1,d2
                adda.w  d2,a1
                subq.w  #1,d1
                subq.w  #1,d0
                move.w  d0,d2
.loc_37E6:
                move.w  d2,d0
.loc_37E8:
                move.w  (a0)+,d3
                cmp.w   (a1)+,d5
                bne.w   .loc_37F6
                add.w   d4,d3
                move.w  d3,-2(a1)
.loc_37F6:
                dbf     d0,.loc_37E8
                adda.w  d6,a1
                dbf     d1,.loc_37E6
                rts
; End of function WriteNametableToBufferMasked

; *************************************************
; Function MainMenu_GameTick
; *************************************************

MainMenu_GameTick:
                addi.w  #1,(MainMenu_ram_FrameCounter).l
                cmpi.w  #1800,(MainMenu_ram_FrameCounter).l
                bcs.w   .inputPlayerA
; 30 seconds without pressing any buttons -> show highscore
                move.w  #1,(MainMenu_ram_DemoMode).l
                move.w  #0,(MainMenu_ram_FrameCounter).l
                bra.w   .endStage

.inputPlayerA:
; write framebuffer to VRAM
                move.l  #Menu_ram_FrameBuffer,d0 ; source
                move.w  #$7000,d1 ; destination : window Nametable
                move.w  #$700,d2 ; size in words 64 x 28
                jsr     (DmaWriteVRAM).l
; get player A input
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l
                beq.w   .loc_385E
                move.w  #0,(MainMenu_ram_FrameCounter).l ; something is pressed -> reset timer
.loc_385E:
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerA).l
; get player B input
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                beq.w   .loc_3884
                move.w  #0,(MainMenu_ram_FrameCounter).l ; something is pressed -> reset timer
.loc_3884:
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerB).l
; check if player A pressed then released 'Start'
                move.w  (MainMenu_ram_ButtonsPlayerA).l,d0
                andi.w  #$80,d0
                bne.w   .checkPlayerBPressedStart ; jump if player A pressed 'start'
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d0
                andi.w  #$80,d0
                bne.w   .endStage ; close menu when player A released 'start'
.checkPlayerBPressedStart:
                move.w  (MainMenu_ram_ButtonsPlayerB).l,d0
                andi.w  #$80,d0
                bne.w   .handleInputPlayerB ; jump if player B pressed 'start'
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d0
                andi.w  #$80,d0
                bne.w   .endStage ; close menu when player B released 'start'

.handleInputPlayerB:
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d0 ; jump if no buttons were pressed or released
                beq.w   .handleInputPlayerA
                and.w   (MainMenu_ram_ButtonsPlayerB).l,d0 ; jump if no new buttons were pressed
                beq.w   .handleInputPlayerA
                move.l  #MainMenu_ram_ButtonsPlayerB,(Menu_ram_CurrentButtonsPtr).l ; set current buttons ptr
                jsr     (MainMenu_HandleInput).l
                cmpi.l  #MainMenu_GameTick,(ram_UpdateFunction).l
                bne.w   .updateMessage

.handleInputPlayerA:
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d0
                beq.w   .updateMessage
                and.w   (MainMenu_ram_ButtonsPlayerA).l,d0
                beq.w   .updateMessage
                move.l  #MainMenu_ram_ButtonsPlayerA,(Menu_ram_CurrentButtonsPtr).l
                jsr     (MainMenu_HandleInput).l

.updateMessage:
                subq.w  #1,(Menu_ram_MessageBlinkTimer).l
                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .end
                move.w  #30,(Menu_ram_MessageBlinkTimer).l ; hide for 0.5 seconds
                move.w  #240,(Menu_ram_NextMessageTimer).l ; change after 4 seconds
                addq.w  #8,(Menu_ram_CurrentMessageId).l ; show next tooltip
                cmpi.w  #(8*6),(Menu_ram_CurrentMessageId).l
                bpl.w   .changeMessage
                move.w  #(8*6),(Menu_ram_CurrentMessageId).l ; index = 6
.changeMessage:
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).l,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                bne.w   .end
                move.w  #(8*6),(Menu_ram_CurrentMessageId).l
                beq.w   .end
.end:
                jsr     (Menu_ShowMessage).l
                jsr     (AudioFunc1).l
                move.w  #1,d2
                jsr     (sub_160B0).l
                jsr     (sub_160CC).l
                jsr     (Rand_GetWord).l
                rts
.endStage:
                jsr     (AudioFunc4).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .end
; End of function MainMenu_GameTick

; *************************************************
; Function Menu_DrawPlayerInfo
; *************************************************

Menu_DrawPlayerInfo:
                lea     (Menu_ram_FrameBuffer + $880).l,a0 ; get cells with y = 17
                move.l  #$7FF07FF,d0
                move.w  #3,d1 ;repeat for 4 lines from y = 17 to y = 20
.loopClear:
; clear 14 cells from x = 0 to x = 13
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                adda.w  #(12*2),a0
; clear 14 cells from x = 19 to x = 39
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                adda.w  #(2*24),a0 ; jump to next cell line
                dbf     d1,.loopClear
; load player selection border image
                lea     (img_mainMenu_PlayerSelection).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write border to framebuffer
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  #12,d0 ; width
                move.w  #4,d1 ; height
                move.w  #1,d2 ; x for player A
                tst.w   (Menu_ram_Player).l
                beq.w   .playerA
                move.w  #27,d2 ; x for player B
.playerA:
                move.w  #17,d3 ; y
                move.w  #$580,d4 ; base tile index, address = $B000
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $C8).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w

                btst    #0,(Menu_ram_PlayerMode + 1).l
                beq.w   .drawPlayerBInfo
; draw player A info
                lea     (Menu_ram_StrPlayerName).l,a1
                move.w  #18,(a1)+ ; y
                move.w  #2,(a1)+ ; x
                move.w  #2,(a1)+ ; height
                move.w  #10,(a1)+ ; width
; copy player name - 10 bytes
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; write 'Level X'
                move.l  #'Leve',(a1)+
                move.l  #'l  0',d0
                add.w   (Menu_ram_PlayerALevel).l,d0
                move.l  d0,(a1)+
                move.w  #'  ',(a1)+
; encode string with player name and level
                lea     (Menu_ram_StrPlayerName).l,a0 ; string
                lea     (Intro_ram_ImageBuffer).l,a1 ; destination
                jsr     (EncodeString).w
; draw it to the framebuffer
                lea     (Menu_ram_StrPlayerName).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$4000,d4 ; base tile index for player A, address = 0, palette line = 2
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_3AB0
                move.w  #$6000,d4 ; base tile index for player B, address = 0, palette line = 3
.loc_3AB0:
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w

.drawPlayerBInfo:
                btst    #1,(Menu_ram_PlayerMode + 1).l
                beq.w   .return
; draw player B info
                lea     (Menu_ram_StrPlayerName).l,a1
                move.w  #18,(a1)+ ; y
                move.w  #28,(a1)+ ; x
                move.w  #2,(a1)+ ; height
                move.w  #10,(a1)+ ; width
; copy player name - 10 bytes
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; write 'Level X'
                move.l  #'Leve',(a1)+
                move.l  #'l  0',d0
                add.w   (Menu_ram_PlayerBLevel).l,d0
                move.l  d0,(a1)+
                move.w  #'  ',(a1)+
; encode string with player name and level
                lea     (Menu_ram_StrPlayerName).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
; draw it to the framebuffer
                lea     (Menu_ram_StrPlayerName).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$4000,d4 ; base tile index for player A, address = 0, palette line = 2
                tst.w   (Menu_ram_Player).l
                bne.w   .loc_3B40
                move.w  #$6000,d4 ; base tile index for player B, address = 0, palette line = 3

.loc_3B40:
                move.w  #$40,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w
.return:
                rts
; End of function Menu_DrawPlayerInfo

; *************************************************
; Function sub_3B56
; *************************************************

sub_3B56:
                move.w  d0,d1
                asl.w   #1,d1
                lea     (unk_49E8).l,a0
                movea.l (a0,d1.w),a0
                lea     (Menu_ram_TempString).l,a1
                move.w  4(a0),d1
                mulu.w  6(a0),d1
                addq.w  #7,d1

.loc_3B74:
                move.b  (a0)+,(a1)+
                dbf     d1,.loc_3B74
                suba.w  #$B,a1
                lea     (unk_25EC0).l,a0
                move.w  d0,d1
                asl.w   #1,d1
                movea.l (a0,d1.w),a0
                movea.l (a0),a0
                move.w  (Menu_ram_PlayerALevel).l,d1
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_3BA4
                move.w  (Menu_ram_PlayerBLevel).l,d1

.loc_3BA4:
                subq.w  #1,d1
                asl.w   #1,d1
                adda.w  d1,a0
                move.w  (a0),d1
                mulu.w  #$10,d1
                divu.w  #$210,d1
                andi.l  #$FFFF,d1
                divu.w  #$A,d1
                swap    d1
                addi.w  #$30,d1 ; '0'
                move.b  d1,-(a1)
                move.b  #$2E,-(a1) ; '.'
                clr.w   d1
                swap    d1

.loc_3BCE:
                divu.w  #$A,d1
                swap    d1
                addi.w  #$30,d1 ; '0'
                move.b  d1,-(a1)
                clr.w   d1
                swap    d1
                bne.s   .loc_3BCE
                rts
; End of function sub_3B56

; *************************************************
; Function MainMenu_HandleInput
; d0 - current buttons state (SACBRLDU)
; *************************************************

MainMenu_HandleInput:
                move.b  d0,(MainMenu_ram_CurrentButtons).l
                btst    #6,(MainMenu_ram_CurrentButtons).l
                beq.w   .checkB
; A pressed
                cmpi.w  #1,(Menu_ram_PlayerMode).l ; if player A mode
                bne.w   .checkPlayerBMode
                move.w  #3,(Menu_ram_PlayerMode).l ; set two player mode
                move.w  #(8*1),(Menu_ram_CurrentMessageId).l ; two player mode selected
                bra.w   .loc_3C74
.checkPlayerBMode:
                cmpi.w  #2,(Menu_ram_PlayerMode).l ; if player B mode
                bne.w   .setPlayerBMode
                move.w  #1,(Menu_ram_PlayerMode).l ; set player A mode
                move.w  #(8*0),(Menu_ram_CurrentMessageId).l ; one player mode selected
                move.w  #0,(Menu_ram_Player).l
                jsr     (sub_2B2E).w
                move.w  (Menu_ram_CurrentTrackId).l,d0
                jsr     (Menu_DrawRaceSelection).l
                bra.w   .loc_3C74
.setPlayerBMode:
                move.w  #2,(Menu_ram_PlayerMode).l ; set player B mode
                move.w  #(8*0),(Menu_ram_CurrentMessageId).l ; one player mode selected
                move.w  #$FFFF,(Menu_ram_Player).l
                jsr     (sub_2B2E).w
                move.w  (Menu_ram_CurrentTrackId).l,d0
                jsr     (Menu_DrawRaceSelection).l
.loc_3C74:
                jsr     (Menu_DrawPlayerInfo).w
                move.w  #240,(Menu_ram_NextMessageTimer).l
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
.checkB:
                btst    #4,(MainMenu_ram_CurrentButtons).l
                beq.w   .checkUpRight
; handle B
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                move.w  #(8*3),(Menu_ram_CurrentMessageId).l ; music is off
                jsr     (AudioFunc4).l
                move.w  #0,(ram_CurrentSong).l
                eori.w  #1,(ram_MusicEnabled).l ; enable or disable music
                beq.w   .checkUpRight
                move.w  #(8*2),(Menu_ram_CurrentMessageId).l ; music is on
                moveq   #1,d0
                move.w  d0,(ram_CurrentSong).l
                jsr     (AudioFunc3).l
.checkUpRight:
                btst    #0,(MainMenu_ram_CurrentButtons).l
                bne.w   .handleUpRight
                btst    #3,(MainMenu_ram_CurrentButtons).l
                beq.w   .checkLeftDown
.handleUpRight:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                addq.w  #2,d0
                cmp.w   #8,d0
                ble.w   .loc_3D08
                move.w  #0,d0
.loc_3D08:
                move.w  d0,(Menu_ram_CurrentTrackId).l
                jsr     (Menu_DrawRaceSelection).l
                move.w  (Menu_ram_CurrentTrackId).l,d0
                bsr.w   sub_3B56
                move.w  #(8*4),(Menu_ram_CurrentMessageId).l
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                jsr     (Menu_DrawPlayerInfo).w
.checkLeftDown:
                btst    #1,(MainMenu_ram_CurrentButtons).l
                bne.w   .handleLeftDown
                btst    #2,(MainMenu_ram_CurrentButtons).l
                beq.w   .checkC
.handleLeftDown:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                subq.w  #2,d0
                bpl.w   .loc_3D62
                move.w  #8,d0
.loc_3D62:
                move.w  d0,(Menu_ram_CurrentTrackId).l
                jsr     (Menu_DrawRaceSelection).l
                move.w  (Menu_ram_CurrentTrackId).l,d0
                bsr.w   sub_3B56
                move.w  #(8*4),(Menu_ram_CurrentMessageId).l
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                jsr     (Menu_DrawPlayerInfo).w
.checkC:
                btst    #5,(MainMenu_ram_CurrentButtons).l
                beq.w   .return
; init password menu
                move.w  #(8*12),(Menu_ram_CurrentMessageId).l ; Press 'start' to exit
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                move.w  #$FFFF,(MenuPassword_ram_HoldTimer).l
                move.w  #0,(MenuPassword_ram_HeldButtons).l
                move.l  #MainMenu_ram_ChangedButtonsPlayerA,(Menu_ram_ChangedButtonsPtr).l
                move.l  #MenuPassword_ram_StrPlayerAName,(MenuPassword_ram_StrPlayerNamePtr).l
                move.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                cmpi.l  #MainMenu_ram_ButtonsPlayerA,(Menu_ram_CurrentButtonsPtr).l
                beq.w   .loc_3E12
; player B
                move.l  #MainMenu_ram_ChangedButtonsPlayerB,(Menu_ram_ChangedButtonsPtr).l
                move.l  #MenuPassword_ram_StrPlayerBName,(MenuPassword_ram_StrPlayerNamePtr).l
                move.l  #MenuPassword_ram_StrPlayerBPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
.loc_3E12:
                move.w  (dStringCodeTable + 2 * ' ').w,d0
                addi.w  #$6000,d0 ; palette line 3
                swap    d0
                move.w  (dStringCodeTable + 2 * ' ').w,d0
                addi.w  #$6000,d0
                lea     (Menu_ram_FrameBuffer + $200).l,a0 ; y = 4
; fill 17 lines with spaces
                move.w  #$21F,d1
.loopClear:
                move.l  d0,(a0)+
                dbf     d1,.loopClear
; load player selection border image
                lea     (img_PasswordMenu_PlayerSelection).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.w  #16,d0 ; width
                move.w  #14,d1 ; height
                move.w  #2,d2 ; x for player A
                cmpi.l  #MenuPassword_ram_StrPlayerBName,(MenuPassword_ram_StrPlayerNamePtr).l
                bne.w   .loc_3E64
                move.w  #22,d2 ; x for player B
.loc_3E64:
                move.w  #5,d3 ; y
                move.w  #$4A0,d4 ; base tile index, address = $9400
                move.w  #64,d6 ; plane width
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                lea     (Intro_ram_ImageBuffer + $C8).l,a0 ; source
                jsr     (WriteNametableToBuffer).w
; encode Name and password text
                lea     (word_4EEE).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
; write border for player B to frame buffer
                lea     (word_4EEE).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  #24,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette line 3
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w
; write border for player A to frame buffer
                lea     (word_4EEE).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  #4,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette line 3
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w

                jsr     (MenuPassword_DrawNamesAndPasswords).w
                cmpi.l  #FadeWithFunction_GameTick,(ram_UpdateFunction).l
                bne.w   .loc_3F0C
                move.l  #MenuPassword_GameTick,(Fade_ram_UpdateFunction).l
                bra.w   .return
.loc_3F0C:
                move.l  #MenuPassword_GameTick,(ram_UpdateFunction).l
.return:
                rts
; End of function MainMenu_HandleInput

; *************************************************
; Function Menu_DrawRaceSelection
; d0 - current race offset
; *************************************************

Menu_DrawRaceSelection:
                move.w  d0,(Menu_ram_CurrentlyDrawnRaceCard).l
                lea     (Menu_ram_FrameBuffer + $300).l,a0 ; start from y = 6
; clear 11 cell lines
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1
                move.w  #$15F,d0
.loopClear:
                move.l  d1,(a0)+
                dbf     d0,.loopClear

                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d0
                andi.l  #$FFFF,d0
                divu.w  #10,d0
                swap    d0
                andi.w  #$FFFE,d0
; draw race badge
                lea     (Race_ram_ImageBuffer2).l,a0 ; get race badges
                mulu.w  #$18,d0
                adda.w  d0,a0
                move.w  #12,d0 ; width
                move.w  #2,d1 ; height
                move.w  #14,d2 ; x
                move.w  #18,d3 ; y
                move.w  #$600,d4 ; base tile index, address = $C000
                move.w  #64,d6 ; plane width
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w
; draw current race card
                lea     (Menu_ram_PlayerAPlaces).l,a0 ; player A
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_3F92
                lea     (Menu_ram_PlayerBPlaces).l,a0 ; player B
.loc_3F92:
                move.l  a0,(Menu_PlayerPlacesPtr).l
                move.w  #0,d0
                move.w  #14,d2 ; x
                move.w  #10,d3 ; y
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1
                andi.l  #$FFFF,d1
                divu.w  #$A,d1
                swap    d1
                andi.w  #$FFFE,d1
                move.w  d1,(Menu_ram_CurrentlyDrawnRaceCard).l ; race id
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l
; draw card to the left
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1
                addq.w  #2,d1 ; race id
                cmp.w   #10,d1
                bmi.w   .loc_3FDE
                move.w  #0,d1
.loc_3FDE:
                move.w  d1,(Menu_ram_CurrentlyDrawnRaceCard).l
                move.w  #21,d2 ; x
                move.w  #8,d3 ; y
                movea.l (Menu_PlayerPlacesPtr).l,a0
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l
; draw most left card
.loc_3FFC:
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1
                addq.w  #2,d1 ; race id
                cmp.w   #10,d1
                bmi.w   .loc_4010
                move.w  #0,d1
.loc_4010:
                move.w  d1,(Menu_ram_CurrentlyDrawnRaceCard).l
                move.w  #25,d2 ; x
                move.w  #6,d3 ; y
                movea.l (Menu_PlayerPlacesPtr).l,a0
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l
; draw card to the right
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1
                addq.w  #2,d1 ; race id
                cmp.w   #$A,d1
                bmi.w   .loc_4042
                move.w  #0,d1
.loc_4042:
                move.w  d1,(Menu_ram_CurrentlyDrawnRaceCard).l
                addq.w  #2,d1 ; race id
                cmp.w   #$A,d1
                bmi.w   .loc_4056
                move.w  #0,d1
.loc_4056:
                move.w  #7,d2 ; x
                move.w  #8,d3 ; y
                movea.l (Menu_PlayerPlacesPtr).l,a0
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l
; draw most right card
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1 ; race id
                move.w  #3,d2 ; x
                move.w  #6,d3 ; y
                movea.l (Menu_PlayerPlacesPtr).l,a0
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l

                rts
; End of function Menu_DrawRaceSelection

; *************************************************
; Function Menu_DrawRaceCard
; d0 - player place in this race
; d1 - race id
; d2 - topLeftX
; d3 - topLeftY
; *************************************************

Menu_DrawRaceCard:
                lea     (Race_ram_ImageBuffer2 + $120).l,a0 ; get race cards nametable
                mulu.w  #$48,d1
                adda.w  d1,a0
; copy card to Intro_ram_ImageBuffer
                lea     (Intro_ram_ImageBuffer).l,a1
                move.w  #35,d1 ; copy 72 table entries, $90 bytes, size of one card 12x6
.loopCopy:
                move.l  (a0)+,(a1)+
                dbf     d1,.loopCopy

                tst.w   d0
                beq.w   .draw ; jump if place = 0
                lea     (Intro_ram_ImageBuffer + $80).l,a0 ; get bottom mid tile entry
                move.w  #0,-8(a0)
                move.w  #0,-6(a0)
                move.w  #0,-4(a0)
                move.w  #0,-2(a0)
                move.w  #0,8(a0)
                move.w  #0,$A(a0)
                move.w  #0,$C(a0)
                move.w  #0,$E(a0)
                move.w  (dStringCodeTable + 2 * ' ').w,(a0) ; ' Xth'
                move.w  (dStringCodeTable + 2 * 't').w,4(a0)
                move.w  (dStringCodeTable + 2 * 'h').w,6(a0)
                cmp.w   #4,d0
                bpl.w   .drawTens
                move.w  (dStringCodeTable + 2 * 'r').w,4(a0) ; ' 3rd'
                move.w  (dStringCodeTable + 2 * 'd').w,6(a0)
                cmp.w   #3,d0
                bpl.w   .drawTens
                move.w  (dStringCodeTable + 2 * 'n').w,4(a0) ; ' 2nd'
                cmp.w   #2,d0
                bpl.w   .drawTens
                move.w  (dStringCodeTable + 2 * 's').w,4(a0) ; ' 1st'
                move.w  (dStringCodeTable + 2 * 't').w,6(a0)
.drawTens:
                cmp.w   #10,d0
                bmi.w   .drawOnes
                move.w  (dStringCodeTable + 2 * '1').w,(a0) ; '1Xth'
                subi.w  #10,d0
.drawOnes:
                move.w  (dStringCodeTable + 2 * '0').w,2(a0)
                add.w   d0,2(a0)
                subi.w  #$680,(a0)+ ; shift to font tiles, which start from index 0
                subi.w  #$680,(a0)+
                subi.w  #$680,(a0)+
                subi.w  #$680,(a0)+
.draw:
                move.w  #12,d0 ; height
                move.w  #6,d1 ; width
                move.w  #$680,d4 ; base tile index, address $D000
                move.w  #$7FF,d5 ; mask tile - default black tile
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBufferMasked).w ; write these tiles only on black tiles
                rts
; End of function Menu_DrawRaceCard

; *************************************************
; Function Menu_ShowMessage
; *************************************************

Menu_ShowMessage:
                tst.w   (Menu_ram_MessageBlinkTimer).l
                bmi.w   .showText
                move.w  (Menu_ram_CurrentMessageId).l,d0 ;l only image is shown
                lea     (Message_MsgArray).l,a0
                movea.l 4(a0,d0.w),a0 ; get ShowMessage function
                cmpa.l  #Message_ShowEmpty,a0
                beq.w   .Message_ShowEmpty
                jsr     (Message_Clear).l
                bra.w   .return
.Message_ShowEmpty:
                jsr     (Message_ShowEmpty).l
                bra.w   .return
.showText:
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).l,a0
                movea.l 4(a0,d0.w),a0 ; get ShowMessage function
                bmi.w   .return ; return if value is -1
                jsr     (a0) ; call ShowMessage function
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).l,a0
                movea.l (a0,d0.w),a0 ; get message text
                cmpa.l  #0,a0 ; return if value is -1
                bmi.w   .return
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString ; write to Intro_ram_ImageBuffer
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).l,a0
                movea.l (a0,d0.w),a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer ; write text to framebuffer
.return:
                rts
; End of function Menu_ShowMessage
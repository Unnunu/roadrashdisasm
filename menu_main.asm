; *************************************************
; Function Menu_Init
; *************************************************

Menu_Init:
                move.w  #0,MainMenu_ram_DemoMode
                move.w  #0,MainMenu_ram_FrameCounter
                move.w  #0,MainMenu_ram_ButtonsPlayerA
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerA
                move.w  #0,MainMenu_ram_ButtonsPlayerB
                move.w  #0,MainMenu_ram_ChangedButtonsPlayerB
                move.w  #240,Menu_ram_NextMessageTimer ; 4 seconds
                move.w  #30,Menu_ram_MessageBlinkTimer ; 0.5 second
                move.w  #(8*6),Menu_ram_CurrentMessageId ; default message "Press A to start race"
                move.l  #Global_ram_Palette,Global_ram_PalettePtr
                move.w  #$3F,Message_ram_ButtonBlinkPeriod
                move.w  #9,MenuPassword_ram_CursorY
                move.w  #1,MenuPassword_ram_CursorX
                tst.w   Menu_ram_Player
                bne.w   @playerB ; jump if player B selected
                tst.l   Menu_ram_MoneyPlayerA
                bpl.w   @loc_3494
                jsr     (sub_1A2C).w
                bra.w   @loc_3494
@playerB:
                tst.l   Menu_ram_MoneyPlayerB
                bpl.w   @loc_3494
                jsr     (sub_1B48).w

@loc_3494:
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
                move.w  #$9100,(a0) ; WindowX = 0
                move.w  #$921C,(a0) ; WindowY = 28 cells
; clear sprites
                VDP_VRAM_WRITE $6000,(a0) ; write to sprite table
                move.w  #3,d0
@loopClearSprites:
                move.l  #0,VdpData
                dbf     d0,@loopClearSprites

                VDP_VSRAM_WRITE $0,(a0)
                move.l  #0,VdpData ; set zero vscroll
; clear default tile
                movea.l #VdpData,a0
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
@loopClearDefaultTile:
                move.l  #0,(a0)
                dbf     d0,@loopClearDefaultTile
; fill with default tiles
                VDP_VRAM_WRITE $4000,VdpCtrl ;write to A/B nametable
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1 ; d1 = $07FF07FF, low priority, pal 0, no flip, tile address $FFE0
                move.w  #$6FF,d0 ; $700 * 2 = $E00 tiles
@loopFillBlack:
                move.l  d1,(a0)
                dbf     d0,@loopFillBlack
; load menu background image
                lea     img_MainMenu_Background,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write background image to VRAM
                move.l  #$8000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; write background nametable
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; first tile index, address = $8000
                move.w  #$4000,d5 ; VRAM address = Scroll A/B
                move.w  #$80,d6 ; plane width = 128
                lea     Intro_ram_ImageBuffer + $4E8,a0
                jsr     (WriteNametable).w ; source
; load race selection background image
                lea     img_MainMenu_RaceSelectionBackground,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
; write it to VRAM
                move.l  #$9000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; write race selection background nametable
                move.w  #40,d0 ; width
                move.w  #14,d1 ; height
                move.w  #0,d2 ; x
                move.w  #4,d3 ; y
                move.w  #$480,d4 ; first tile index, address = $9000
                move.w  #$4000,d5 ; VRAM address = Scroll A/B
                move.w  #$80,d6 ; plane width = 128
                lea     Intro_ram_ImageBuffer + $2E8,a0
                jsr     (WriteNametable).w
; load paler selection border image
                lea     img_PasswordMenu_PlayerSelection,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM, but it's initially hidden
                move.l  #$9400,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; load gamepad image
                lea     img_Gamepad,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressB
; write it to VRAM
                move.l  #$A000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; write gamepad image nametable
                move.w  #12,d0 ; width
                move.w  #6,d1 ; height
                move.w  #2,d2 ; x
                move.w  #22,d3 ; y
                move.w  #$500,d4 ; first tile index, address = $A000
                move.w  #$4000,d5 ; VRAM address = Scroll A/B
                move.w  #$80,d6 ; plane width = 128
                lea     Intro_ram_ImageBuffer + $B48,a0
                jsr     (WriteNametable).w

                lea     img_mainMenu_PlayerSelection,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW

                move.l  #$B000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; clear Menu_ram_FrameBuffer
                lea     Menu_ram_FrameBuffer,a0
                move.l  #$7FF07FF,d1 ; default tile
                move.w  #$37F,d0 ; buffer size $380 * 4 = $E00, $700 tiles
@loc_3670:
                move.l  d1,(a0)+
                dbf     d0,@loc_3670
; load race names image
                lea     img_MainMenu_RaceBadges,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM
                move.l  #$C000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; create nametable in Race_ram_ImageBuffer2
                move.w  #12,d0 ; height
                move.w  #12,d1 ; width
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #12,d6 ; plane width
                lea     Race_ram_ImageBuffer2,a1 ; destination
                lea     Intro_ram_ImageBuffer + $D88,a0 ; source
                jsr     WriteNametableToBuffer
; load race cards
                lea     img_mainMenu_RaceCards,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write it to VRAM
                move.l  #$D000,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM
; and append nametable in Race_ram_ImageBuffer2, just below names images
                move.w  #12,d0 ; height
                move.w  #30,d1 ; width
                move.w  #0,d2 ; x
                move.w  #12,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #12,d6 ; plane width
                lea     Race_ram_ImageBuffer2,a1
                lea     Intro_ram_ImageBuffer + $2768,a0
                jsr     WriteNametableToBuffer
; load palette for all menu images
                lea     Intro_ram_ImageBuffer + $26E4,a0
                movea.l Global_ram_PalettePtr,a1
; copy palette line 0
                move.w  #7,d0
@loopPalette0:
                move.l  (a0)+,(a1)+
                dbf     d0,@loopPalette0
; copy palette line 1
                move.w  #7,d0
@loopPalette1:
                move.l  (a0)+,(a1)+
                dbf     d0,@loopPalette1
; copy palette line 2
                move.w  #7,d0
@loopPalette2:
                move.l  (a0)+,(a1)+
                dbf     d0,@loopPalette2
; copy palette line 3
                move.w  #7,d0
@loopPalette3:
                move.l  (a0)+,(a1)+
                dbf     d0,@loopPalette3
; load font
                lea     img_Intro_Font,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write font to VRAM
                moveq   #0,d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     WriteToVRAM

                jsr     Menu_ShowMessage
                jsr     (sub_2B2E).w
                move.w  Menu_ram_CurrentTrackId,d0
                jsr     Menu_DrawRaceSelection
                jsr     Menu_DrawPlayerInfo
; write framebuffer to VRAM
                move.l  #Menu_ram_FrameBuffer,d0 ; source
                move.w  #$7000,d1 ; destination : window Nametable
                move.w  #$700,d2 ; size in words 64 x 28
                jsr     DmaWriteVRAM

                tst.w   ram_MusicEnabled
                beq.w   @return
                moveq   #1,d0
                jsr     AudioFunc3

@return:
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

@loc_37BE:
                move.w  d2,d0

@loc_37C0:
                move.w  (a0)+,d3
                add.w   d4,d3
                move.w  d3,(a1)+
                dbf     d0,@loc_37C0
                adda.w  d6,a1
                dbf     d1,@loc_37BE
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
@loc_37E6:
                move.w  d2,d0
@loc_37E8:
                move.w  (a0)+,d3
                cmp.w   (a1)+,d5
                bne.w   @loc_37F6
                add.w   d4,d3
                move.w  d3,-2(a1)
@loc_37F6:
                dbf     d0,@loc_37E8
                adda.w  d6,a1
                dbf     d1,@loc_37E6
                rts
; End of function WriteNametableToBufferMasked

; *************************************************
; Function MainMenu_GameTick
; *************************************************

MainMenu_GameTick:
                addi.w  #1,MainMenu_ram_FrameCounter
                cmpi.w  #1800,MainMenu_ram_FrameCounter
                bcs.w   @inputPlayerA
; 30 seconds without pressing any buttons -> show highscore
                move.w  #1,MainMenu_ram_DemoMode
                move.w  #0,MainMenu_ram_FrameCounter
                bra.w   @endStage

@inputPlayerA:
; write framebuffer to VRAM
                move.l  #Menu_ram_FrameBuffer,d0 ; source
                move.w  #$7000,d1 ; destination : window Nametable
                move.w  #$700,d2 ; size in words 64 x 28
                jsr     DmaWriteVRAM
; get player A input
                move.w  MainMenu_ram_ButtonsPlayerA,MainMenu_ram_ChangedButtonsPlayerA
                jsr     (GetInputPlayerA).w
                move.w  d0,MainMenu_ram_ButtonsPlayerA
                beq.w   @loc_385E
                move.w  #0,MainMenu_ram_FrameCounter ; something is pressed -> reset timer
@loc_385E:
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerA
; get player B input
                move.w  MainMenu_ram_ButtonsPlayerB,MainMenu_ram_ChangedButtonsPlayerB
                jsr     (GetInputPlayerB).w
                move.w  d0,MainMenu_ram_ButtonsPlayerB
                beq.w   @loc_3884
                move.w  #0,MainMenu_ram_FrameCounter ; something is pressed -> reset timer
@loc_3884:
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerB
; check if player A pressed then released 'Start'
                move.w  MainMenu_ram_ButtonsPlayerA,d0
                andi.w  #$80,d0
                bne.w   @checkPlayerBPressedStart ; jump if player A pressed 'start'
                move.w  MainMenu_ram_ChangedButtonsPlayerA,d0
                andi.w  #$80,d0
                bne.w   @endStage ; close menu when player A released 'start'
@checkPlayerBPressedStart:
                move.w  MainMenu_ram_ButtonsPlayerB,d0
                andi.w  #$80,d0
                bne.w   @handleInputPlayerB ; jump if player B pressed 'start'
                move.w  MainMenu_ram_ChangedButtonsPlayerB,d0
                andi.w  #$80,d0
                bne.w   @endStage ; close menu when player B released 'start'

@handleInputPlayerB:
                move.w  MainMenu_ram_ChangedButtonsPlayerB,d0 ; jump if no buttons were pressed or released
                beq.w   @handleInputPlayerA
                and.w   MainMenu_ram_ButtonsPlayerB,d0 ; jump if no new buttons were pressed
                beq.w   @handleInputPlayerA
                move.l  #MainMenu_ram_ButtonsPlayerB,Menu_ram_CurrentButtonsPtr ; set current buttons ptr
                jsr     MainMenu_HandleInput
                cmpi.l  #MainMenu_GameTick,ram_UpdateFunction
                bne.w   @updateMessage

@handleInputPlayerA:
                move.w  MainMenu_ram_ChangedButtonsPlayerA,d0
                beq.w   @updateMessage
                and.w   MainMenu_ram_ButtonsPlayerA,d0
                beq.w   @updateMessage
                move.l  #MainMenu_ram_ButtonsPlayerA,Menu_ram_CurrentButtonsPtr
                jsr     MainMenu_HandleInput

@updateMessage:
                subq.w  #1,Menu_ram_MessageBlinkTimer
                subq.w  #1,Menu_ram_NextMessageTimer
                bpl.w   @end
                move.w  #30,Menu_ram_MessageBlinkTimer ; hide for 0.5 seconds
                move.w  #240,Menu_ram_NextMessageTimer ; change after 4 seconds
                addq.w  #8,Menu_ram_CurrentMessageId ; show next tooltip
                cmpi.w  #(8*6),Menu_ram_CurrentMessageId
                bpl.w   @changeMessage
                move.w  #(8*6),Menu_ram_CurrentMessageId ; index = 6
@changeMessage:
                move.w  Menu_ram_CurrentMessageId,d0
                lea     Message_MsgArray,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                bne.w   @end
                move.w  #(8*6),Menu_ram_CurrentMessageId
                beq.w   @end
@end:
                jsr     Menu_ShowMessage
                jsr     AudioFunc1
                move.w  #1,d2
                jsr     sub_160B0
                jsr     sub_160CC
                jsr     Rand_GetWord
                rts
@endStage:
                jsr     AudioFunc4
                move.l  #0,ram_UpdateFunction
                bra.s   @end
; End of function MainMenu_GameTick

; *************************************************
; Function Menu_DrawPlayerInfo
; *************************************************

Menu_DrawPlayerInfo:
                lea     Menu_ram_FrameBuffer + $880,a0 ; get cells with y = 17
                move.l  #$7FF07FF,d0
                move.w  #3,d1 ;repeat for 4 lines from y = 17 to y = 20
@loopClear:
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
                dbf     d1,@loopClear
; load player selection border image
                lea     img_mainMenu_PlayerSelection,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW
; write border to framebuffer
                lea     Intro_ram_ImageBuffer,a0
                move.w  #12,d0 ; width
                move.w  #4,d1 ; height
                move.w  #1,d2 ; x for player A
                tst.w   Menu_ram_Player
                beq.w   @playerA
                move.w  #27,d2 ; x for player B
@playerA:
                move.w  #17,d3 ; y
                move.w  #$580,d4 ; base tile index, address = $B000
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer + $C8,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                jsr     (WriteNametableToBuffer).w

                btst    #0,(Menu_ram_PlayerMode + 1)
                beq.w   @drawPlayerBInfo
; draw player A info
                lea     Menu_ram_StrPlayerName,a1
                move.w  #18,(a1)+ ; y
                move.w  #2,(a1)+ ; x
                move.w  #2,(a1)+ ; height
                move.w  #10,(a1)+ ; width
; copy player name - 10 bytes
                lea     MenuPassword_ram_StrPlayerAName + 8,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; write 'Level X'
                move.l  #'Leve',(a1)+
                move.l  #'l  0',d0
                add.w   Menu_ram_PlayerALevel,d0
                move.l  d0,(a1)+
                move.w  #'  ',(a1)+
; encode string with player name and level
                lea     Menu_ram_StrPlayerName,a0 ; string
                lea     Intro_ram_ImageBuffer,a1 ; destination
                jsr     (EncodeString).w
; draw it to the framebuffer
                lea     Menu_ram_StrPlayerName,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$4000,d4 ; base tile index for player A, address = 0, palette line = 2
                tst.w   Menu_ram_Player
                beq.w   @loc_3AB0
                move.w  #$6000,d4 ; base tile index for player B, address = 0, palette line = 3
@loc_3AB0:
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                jsr     (WriteNametableToBuffer).w

@drawPlayerBInfo:
                btst    #1,(Menu_ram_PlayerMode + 1)
                beq.w   @return
; draw player B info
                lea     Menu_ram_StrPlayerName,a1
                move.w  #18,(a1)+ ; y
                move.w  #28,(a1)+ ; x
                move.w  #2,(a1)+ ; height
                move.w  #10,(a1)+ ; width
; copy player name - 10 bytes
                lea     MenuPassword_ram_StrPlayerBName + 8,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; write 'Level X'
                move.l  #'Leve',(a1)+
                move.l  #'l  0',d0
                add.w   Menu_ram_PlayerBLevel,d0
                move.l  d0,(a1)+
                move.w  #'  ',(a1)+
; encode string with player name and level
                lea     Menu_ram_StrPlayerName,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
; draw it to the framebuffer
                lea     Menu_ram_StrPlayerName,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$4000,d4 ; base tile index for player A, address = 0, palette line = 2
                tst.w   Menu_ram_Player
                bne.w   @loc_3B40
                move.w  #$6000,d4 ; base tile index for player B, address = 0, palette line = 3

@loc_3B40:
                move.w  #$40,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                jsr     (WriteNametableToBuffer).w
@return:
                rts
; End of function Menu_DrawPlayerInfo

; *************************************************
; Function sub_3B56
; *************************************************

sub_3B56:
                move.w  d0,d1
                asl.w   #1,d1
                lea     unk_49E8,a0
                movea.l (a0,d1.w),a0
                lea     Menu_ram_TempString,a1
                move.w  4(a0),d1
                mulu.w  6(a0),d1
                addq.w  #7,d1

@loc_3B74:
                move.b  (a0)+,(a1)+
                dbf     d1,@loc_3B74
                suba.w  #$B,a1
                lea     unk_25EC0,a0
                move.w  d0,d1
                asl.w   #1,d1
                movea.l (a0,d1.w),a0
                movea.l (a0),a0
                move.w  Menu_ram_PlayerALevel,d1
                tst.w   Menu_ram_Player
                beq.w   @loc_3BA4
                move.w  Menu_ram_PlayerBLevel,d1

@loc_3BA4:
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

@loc_3BCE:
                divu.w  #$A,d1
                swap    d1
                addi.w  #$30,d1 ; '0'
                move.b  d1,-(a1)
                clr.w   d1
                swap    d1
                bne.s   @loc_3BCE
                rts
; End of function sub_3B56

; *************************************************
; Function MainMenu_HandleInput
; d0 - current buttons state (SACBRLDU)
; *************************************************

MainMenu_HandleInput:
                move.b  d0,MainMenu_ram_CurrentButtons
                btst    #6,MainMenu_ram_CurrentButtons
                beq.w   @checkB
; A pressed
                cmpi.w  #1,Menu_ram_PlayerMode ; if player A mode
                bne.w   @checkPlayerBMode
                move.w  #3,Menu_ram_PlayerMode ; set two player mode
                move.w  #(8*1),Menu_ram_CurrentMessageId ; two player mode selected
                bra.w   @loc_3C74
@checkPlayerBMode:
                cmpi.w  #2,Menu_ram_PlayerMode ; if player B mode
                bne.w   @setPlayerBMode
                move.w  #1,Menu_ram_PlayerMode ; set player A mode
                move.w  #(8*0),Menu_ram_CurrentMessageId ; one player mode selected
                move.w  #0,Menu_ram_Player
                jsr     (sub_2B2E).w
                move.w  Menu_ram_CurrentTrackId,d0
                jsr     Menu_DrawRaceSelection
                bra.w   @loc_3C74
@setPlayerBMode:
                move.w  #2,Menu_ram_PlayerMode ; set player B mode
                move.w  #(8*0),Menu_ram_CurrentMessageId ; one player mode selected
                move.w  #$FFFF,Menu_ram_Player
                jsr     (sub_2B2E).w
                move.w  Menu_ram_CurrentTrackId,d0
                jsr     Menu_DrawRaceSelection
@loc_3C74:
                jsr     (Menu_DrawPlayerInfo).w
                move.w  #240,Menu_ram_NextMessageTimer
                move.w  #30,Menu_ram_MessageBlinkTimer
@checkB:
                btst    #4,MainMenu_ram_CurrentButtons
                beq.w   @checkUpRight
; handle B
                move.w  #30,Menu_ram_MessageBlinkTimer
                move.w  #240,Menu_ram_NextMessageTimer
                move.w  #(8*3),Menu_ram_CurrentMessageId ; music is off
                jsr     AudioFunc4
                move.w  #0,ram_CurrentSong
                eori.w  #1,ram_MusicEnabled ; enable or disable music
                beq.w   @checkUpRight
                move.w  #(8*2),Menu_ram_CurrentMessageId ; music is on
                moveq   #1,d0
                move.w  d0,ram_CurrentSong
                jsr     AudioFunc3
@checkUpRight:
                btst    #0,MainMenu_ram_CurrentButtons
                bne.w   @handleUpRight
                btst    #3,MainMenu_ram_CurrentButtons
                beq.w   @checkLeftDown
@handleUpRight:
                move.w  Menu_ram_CurrentTrackId,d0
                addq.w  #2,d0
                cmp.w   #8,d0
                ble.w   @loc_3D08
                move.w  #0,d0
@loc_3D08:
                move.w  d0,Menu_ram_CurrentTrackId
                jsr     Menu_DrawRaceSelection
                move.w  Menu_ram_CurrentTrackId,d0
                bsr.w   sub_3B56
                move.w  #(8*4),Menu_ram_CurrentMessageId
                move.w  #30,Menu_ram_MessageBlinkTimer
                move.w  #240,Menu_ram_NextMessageTimer
                jsr     (Menu_DrawPlayerInfo).w
@checkLeftDown:
                btst    #1,MainMenu_ram_CurrentButtons
                bne.w   @handleLeftDown
                btst    #2,MainMenu_ram_CurrentButtons
                beq.w   @checkC
@handleLeftDown:
                move.w  Menu_ram_CurrentTrackId,d0
                subq.w  #2,d0
                bpl.w   @loc_3D62
                move.w  #8,d0
@loc_3D62:
                move.w  d0,Menu_ram_CurrentTrackId
                jsr     Menu_DrawRaceSelection
                move.w  Menu_ram_CurrentTrackId,d0
                bsr.w   sub_3B56
                move.w  #(8*4),Menu_ram_CurrentMessageId
                move.w  #30,Menu_ram_MessageBlinkTimer
                move.w  #240,Menu_ram_NextMessageTimer
                jsr     (Menu_DrawPlayerInfo).w
@checkC:
                btst    #5,MainMenu_ram_CurrentButtons
                beq.w   @return
; init password menu
                move.w  #(8*12),Menu_ram_CurrentMessageId ; Press 'start' to exit
                move.w  #30,Menu_ram_MessageBlinkTimer
                move.w  #240,Menu_ram_NextMessageTimer
                move.w  #$FFFF,MenuPassword_ram_HoldTimer
                move.w  #0,MenuPassword_ram_HeldButtons
                move.l  #MainMenu_ram_ChangedButtonsPlayerA,Menu_ram_ChangedButtonsPtr
                move.l  #MenuPassword_ram_StrPlayerAName,MenuPassword_ram_StrPlayerNamePtr
                move.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                cmpi.l  #MainMenu_ram_ButtonsPlayerA,Menu_ram_CurrentButtonsPtr
                beq.w   @loc_3E12
; player B
                move.l  #MainMenu_ram_ChangedButtonsPlayerB,Menu_ram_ChangedButtonsPtr
                move.l  #MenuPassword_ram_StrPlayerBName,MenuPassword_ram_StrPlayerNamePtr
                move.l  #MenuPassword_ram_StrPlayerBPassword,MenuPassword_ram_StrPlayerPasswordPtr
@loc_3E12:
                move.w  (dStringCodeTable + 2 * ' ').w,d0
                addi.w  #$6000,d0 ; palette line 3
                swap    d0
                move.w  (dStringCodeTable + 2 * ' ').w,d0
                addi.w  #$6000,d0
                lea     (Menu_ram_FrameBuffer + $200),a0 ; y = 4
; fill 17 lines with spaces
                move.w  #$21F,d1
@loopClear:
                move.l  d0,(a0)+
                dbf     d1,@loopClear
; load player selection border image
                lea     img_PasswordMenu_PlayerSelection,a3
                lea     Intro_ram_ImageBuffer,a1
                jsr     UncompressW

                move.w  #16,d0 ; width
                move.w  #14,d1 ; height
                move.w  #2,d2 ; x for player A
                cmpi.l  #MenuPassword_ram_StrPlayerBName,MenuPassword_ram_StrPlayerNamePtr
                bne.w   @loc_3E64
                move.w  #22,d2 ; x for player B
@loc_3E64:
                move.w  #5,d3 ; y
                move.w  #$4A0,d4 ; base tile index, address = $9400
                move.w  #64,d6 ; plane width
                lea     Menu_ram_FrameBuffer,a1 ; destination
                lea     Intro_ram_ImageBuffer + $C8,a0 ; source
                jsr     (WriteNametableToBuffer).w
; encode Name and password text
                lea     word_4EEE,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
; write border for player B to frame buffer
                lea     word_4EEE,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  #24,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette line 3
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                jsr     (WriteNametableToBuffer).w
; write border for player A to frame buffer
                lea     word_4EEE,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  #4,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette line 3
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                jsr     (WriteNametableToBuffer).w

                jsr     (MenuPassword_DrawNamesAndPasswords).w
                cmpi.l  #FadeWithFunction_GameTick,ram_UpdateFunction
                bne.w   @loc_3F0C
                move.l  #MenuPassword_GameTick,Fade_ram_UpdateFunction
                bra.w   @return
@loc_3F0C:
                move.l  #MenuPassword_GameTick,ram_UpdateFunction
@return:
                rts
; End of function MainMenu_HandleInput

; *************************************************
; Function Menu_DrawRaceSelection
; d0 - current race offset
; *************************************************

Menu_DrawRaceSelection:
                move.w  d0,Menu_ram_CurrentlyDrawnRaceCard
                lea     Menu_ram_FrameBuffer + $300,a0 ; start from y = 6
; clear 11 cell lines
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1
                move.w  #$15F,d0
@loopClear:
                move.l  d1,(a0)+
                dbf     d0,@loopClear

                move.w  Menu_ram_CurrentlyDrawnRaceCard,d0
                andi.l  #$FFFF,d0
                divu.w  #10,d0
                swap    d0
                andi.w  #$FFFE,d0
; draw race badge
                lea     Race_ram_ImageBuffer2,a0 ; get race badges
                mulu.w  #$18,d0
                adda.w  d0,a0
                move.w  #12,d0 ; width
                move.w  #2,d1 ; height
                move.w  #14,d2 ; x
                move.w  #18,d3 ; y
                move.w  #$600,d4 ; base tile index, address = $C000
                move.w  #64,d6 ; plane width
                lea     Menu_ram_FrameBuffer,a1
                jsr     (WriteNametableToBuffer).w
; draw current race card
                lea     Menu_ram_PlayerAPlaces,a0 ; player A
                tst.w   Menu_ram_Player
                beq.w   @loc_3F92
                lea     Menu_ram_PlayerBPlaces,a0 ; player B
@loc_3F92:
                move.l  a0,Menu_PlayerPlacesPtr
                move.w  #0,d0
                move.w  #14,d2 ; x
                move.w  #10,d3 ; y
                move.w  Menu_ram_CurrentlyDrawnRaceCard,d1
                andi.l  #$FFFF,d1
                divu.w  #$A,d1
                swap    d1
                andi.w  #$FFFE,d1
                move.w  d1,Menu_ram_CurrentlyDrawnRaceCard ; race id
                move.w  (a0,d1.w),d0
                jsr     Menu_DrawRaceCard
; draw card to the left
                move.w  Menu_ram_CurrentlyDrawnRaceCard,d1
                addq.w  #2,d1 ; race id
                cmp.w   #10,d1
                bmi.w   @loc_3FDE
                move.w  #0,d1
@loc_3FDE:
                move.w  d1,Menu_ram_CurrentlyDrawnRaceCard
                move.w  #21,d2 ; x
                move.w  #8,d3 ; y
                movea.l Menu_PlayerPlacesPtr,a0
                move.w  (a0,d1.w),d0
                jsr     Menu_DrawRaceCard
; draw most left card
@loc_3FFC:
                move.w  Menu_ram_CurrentlyDrawnRaceCard,d1
                addq.w  #2,d1 ; race id
                cmp.w   #10,d1
                bmi.w   @loc_4010
                move.w  #0,d1
@loc_4010:
                move.w  d1,Menu_ram_CurrentlyDrawnRaceCard
                move.w  #25,d2 ; x
                move.w  #6,d3 ; y
                movea.l Menu_PlayerPlacesPtr,a0
                move.w  (a0,d1.w),d0
                jsr     Menu_DrawRaceCard
; draw card to the right
                move.w  Menu_ram_CurrentlyDrawnRaceCard,d1
                addq.w  #2,d1 ; race id
                cmp.w   #$A,d1
                bmi.w   @loc_4042
                move.w  #0,d1
@loc_4042:
                move.w  d1,Menu_ram_CurrentlyDrawnRaceCard
                addq.w  #2,d1 ; race id
                cmp.w   #$A,d1
                bmi.w   @loc_4056
                move.w  #0,d1
@loc_4056:
                move.w  #7,d2 ; x
                move.w  #8,d3 ; y
                movea.l Menu_PlayerPlacesPtr,a0
                move.w  (a0,d1.w),d0
                jsr     Menu_DrawRaceCard
; draw most right card
                move.w  Menu_ram_CurrentlyDrawnRaceCard,d1 ; race id
                move.w  #3,d2 ; x
                move.w  #6,d3 ; y
                movea.l Menu_PlayerPlacesPtr,a0
                move.w  (a0,d1.w),d0
                jsr     Menu_DrawRaceCard

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
                lea     Race_ram_ImageBuffer2 + $120,a0 ; get race cards nametable
                mulu.w  #$48,d1
                adda.w  d1,a0
; copy card to Intro_ram_ImageBuffer
                lea     Intro_ram_ImageBuffer,a1
                move.w  #35,d1 ; copy 72 table entries, $90 bytes, size of one card 12x6
@loopCopy:
                move.l  (a0)+,(a1)+
                dbf     d1,@loopCopy

                tst.w   d0
                beq.w   @draw ; jump if place = 0
                lea     Intro_ram_ImageBuffer + $80,a0 ; get bottom mid tile entry
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
                bpl.w   @drawTens
                move.w  (dStringCodeTable + 2 * 'r').w,4(a0) ; ' 3rd'
                move.w  (dStringCodeTable + 2 * 'd').w,6(a0)
                cmp.w   #3,d0
                bpl.w   @drawTens
                move.w  (dStringCodeTable + 2 * 'n').w,4(a0) ; ' 2nd'
                cmp.w   #2,d0
                bpl.w   @drawTens
                move.w  (dStringCodeTable + 2 * 's').w,4(a0) ; ' 1st'
                move.w  (dStringCodeTable + 2 * 't').w,6(a0)
@drawTens:
                cmp.w   #10,d0
                bmi.w   @drawOnes
                move.w  (dStringCodeTable + 2 * '1').w,(a0) ; '1Xth'
                subi.w  #10,d0
@drawOnes:
                move.w  (dStringCodeTable + 2 * '0').w,2(a0)
                add.w   d0,2(a0)
                subi.w  #$680,(a0)+ ; shift to font tiles, which start from index 0
                subi.w  #$680,(a0)+
                subi.w  #$680,(a0)+
                subi.w  #$680,(a0)+
@draw:
                move.w  #12,d0 ; height
                move.w  #6,d1 ; width
                move.w  #$680,d4 ; base tile index, address $D000
                move.w  #$7FF,d5 ; mask tile - default black tile
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                jsr     (WriteNametableToBufferMasked).w ; write these tiles only on black tiles
                rts
; End of function Menu_DrawRaceCard

; *************************************************
; Function Menu_ShowMessage
; *************************************************

Menu_ShowMessage:
                tst.w   Menu_ram_MessageBlinkTimer
                bmi.w   @showText
                move.w  Menu_ram_CurrentMessageId,d0 ;l only image is shown
                lea     Message_MsgArray,a0
                movea.l 4(a0,d0.w),a0 ; get ShowMessage function
                cmpa.l  #Message_ShowEmpty,a0
                beq.w   @Message_ShowEmpty
                jsr     Message_Clear
                bra.w   @return
@Message_ShowEmpty:
                jsr     Message_ShowEmpty
                bra.w   @return
@showText:
                move.w  Menu_ram_CurrentMessageId,d0
                lea     Message_MsgArray,a0
                movea.l 4(a0,d0.w),a0 ; get ShowMessage function
                bmi.w   @return ; return if value is -1
                jsr     (a0) ; call ShowMessage function
                move.w  Menu_ram_CurrentMessageId,d0
                lea     Message_MsgArray,a0
                movea.l (a0,d0.w),a0 ; get message text
                cmpa.l  #0,a0 ; return if value is -1
                bmi.w   @return
                lea     Intro_ram_ImageBuffer,a1
                bsr.w   EncodeString ; write to Intro_ram_ImageBuffer
                move.w  Menu_ram_CurrentMessageId,d0
                lea     Message_MsgArray,a0
                movea.l (a0,d0.w),a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer ; write text to framebuffer
@return:
                rts
; End of function Menu_ShowMessage
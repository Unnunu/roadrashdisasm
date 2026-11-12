; *************************************************
; highscore.asm - high-score table and attract/demo variant
; ROM range: $6DC0-$74A9
; Status:    line-by-line analyzed (static; demo path)
; API:       HighScore_Init, HighScore_GameTick(_Demo), HighScore_HandleInput
; Assets:    img_MainMenu_Background, ImgHighScoreTitle, ImgHighScoreBadge,
;            img_Gamepad, img_Intro_Font, FontHighScoreTable, FontHighScoreDigits
; *************************************************

; *************************************************
; Function HighScore_Init
; Builds the high-score screen: VDP, background/title/badges/gamepad, fonts, the
; 7x20 score table, player rows, message, DMA and audio.
; In:  HighScore_ram_Table, HighScore_ram_PlayerATableOffset/B
; Out: Menu_ram_FrameBuffer -> VRAM $7000; VRAM $0/$800/$1000/$8000-$B000; the
;      palette is staged in Global_ram_Palette (pointer at Global_ram_PalettePtr)
; Clobbers: d0-d7, a0-a3
; *************************************************

HighScore_Init:
; reset timers and pad state; negative blink timer = text visible now
                move.w  #600,(Menu_ram_NextMessageTimer).l ; initial message timer (10 s)
                move.w  #0,(MainMenu_ram_ButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerB).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerB).l
                move.w  #$FFFF,(Menu_ram_MessageBlinkTimer).l
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l
                move.w  #(8*42),(Menu_ram_CurrentMessageId).l ; group 42 * 8-byte entry
                move.l  #0,(RaceResults_ram_NextFunction).l ; no exit request yet
                lea     (VdpCtrl).l,a0
                move.w  #$8004,(a0) ; Mode 5; H-int off; HV latch off
                move.w  #$8174,(a0) ; Display on, V-int on, DMA on, 28-row (224-line) mode
                move.w  #$8210,(a0) ; Scroll A Name Table:    $4000
                move.w  #$831C,(a0) ; Window Name Table:      $7000
                move.w  #$8402,(a0) ; Scroll B Name Table:    $4000
                move.w  #$8530,(a0) ; Sprite Attribute Table: $6000
                move.w  #$870D,(a0) ; Backdrop Color: $D
                move.w  #$8AFF,(a0) ; H-Int Counter: 255
                move.w  #$8B00,(a0) ; E-ints disabled, V-Scroll: full, H-Scroll: full
                move.w  #$8C81,(a0) ; H40, no interlace, Shadow/Highlight disabled
                move.w  #$8D18,(a0) ; HScroll Data Table:     $6000
                move.w  #$8F02,(a0) ; Auto-increment: $2
                move.w  #$9003,(a0) ; Scroll A/B Size: 128x32
                move.w  #$9100,(a0) ; WindowX: 0
                move.w  #$921C,(a0) ; WindowY: 28 cells (split at line 224; window covers all rows)
                VDP_VRAM_WRITE $6000,(a0) ; sprite attribute table (H-scroll data shares $6000)
; four longs = 16 bytes = two 8-byte SAT entries; entry 0 (link=0) terminates the list
                move.w  #3,d0
.loc_6E56:
                move.l  #0,(VdpData).l
                dbf     d0,.loc_6E56

                VDP_VSRAM_WRITE $0,(a0) ; clear vertical scroll
                move.l  #0,(VdpData).l
                movea.l #VdpData,a0
; clear one 4bpp tile (8 longs = 32 bytes) at VRAM $FFE0 = pattern of tile $7FF,
; which the frame-buffer fill below uses as the blank/background tile
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
.loopClearDefault:
                move.l  #0,(a0)
                dbf     d0,.loopClearDefault
; background to VRAM $8000 (same asset as the main menu)
                lea     (img_MainMenu_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $8000
                move.l  #$8000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
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
; "High Score" title image to VRAM $9000
                lea     (ImgHighScoreTitle).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $9000
                move.l  #$9000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
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
; copy the high-score palette: four 16-colour palettes (64 colours) from the title
; blob at +$4E4. The decompression above overwrote the background in ImageBuffer,
; so this is the title's palette, not the background's (asset_specs screen_palettes).
                lea     (Intro_ram_ImageBuffer + $4E4).l,a0
                movea.l (Global_ram_PalettePtr).l,a1

                move.w  #7,d0 ; 8 longs = one 16-colour palette each
.copyPal0:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPal0

                move.w  #7,d0 ; palette 1
.copyPal1:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPal1

                move.w  #7,d0 ; palette 2
.copyPal2:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPal2

                move.w  #7,d0 ; palette 3
.copyPal3:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPal3
; gamepad diagram on the plane at (2,22); only the top 12x6 map is drawn (U-0002)
                lea     (img_Gamepad).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
; write to VRAM address $A000
                move.l  #$A000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
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
; yellow badge image; drawn in the five top-score slots
                lea     (ImgHighScoreBadge).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
; write to VRAM address $B000
                move.l  #$B000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; and draw it 5 times at y=5,8,11,14,17 (each slot is 3 rows tall)
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
; fonts: regular at $0, table font at $800, digit font at $1000 (loaded but not
; referenced by any tile base on this screen: U-0009)
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $0
                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; table font at VRAM $800
                lea     (FontHighScoreTable).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $800
                move.l  #$800,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; digit font to VRAM $1000 (tile base $80); no tile base $80 is used below (U-0009)
                lea     (FontHighScoreDigits).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$1000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; clear 22 rows (22*64 = 1408 words) to the blank tile $7FF: each long holds two
; $07FF words (priority 0, palette 0, tile $7FF)
                lea     (Menu_ram_FrameBuffer).l,a0
                move.l  #$7FF07FF,d1
                move.w  #$2BF,d0
.loopClearFB:
                move.l  d1,(a0)+
                dbf     d0,.loopClearFB
; fill the last 6 rows (6*64 = 384 words) with the space tile; duplicate the tile
; word into both halves of each long
                move.w  #$BF,d0
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                swap    d1
                move.w  (dStringCodeTable + 2 * ' ').w,d1
.loopDrawSpace:
                move.l  d1,(a0)+
                dbf     d0,.loopDrawSpace

; encode the 7x20 table; EncodeString reads only +4 (height) and +6 (width), so the
; header's y/x (+0/+2, written by Intro_Init) are not used by this screen's draws
                lea     (HighScore_ram_Table).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString
; top five rows use the table font at $800; rows are 40 bytes apart
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
; player rows use the regular font at $0; the offsets are byte offsets into the text
; (20*5 / 20*6 initially, moved by Race_UpdateHighScoreTable), doubled for word blits
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
; DMA the 64x28 window frame buffer (1792 words = $700) to VRAM $7000
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM

                jsr     (Audio_StopMusic).l
                tst.w   (ram_MusicEnabled).l
                beq.w   .return
                moveq   #1,d0
                jsr     (Audio_StartMusic).l
.return:
                rts
; End of function HighScore_Init

; *************************************************
; Function HighScore_GameTick_Demo
; Attract variant: wait for a button release or a 600-frame timer (601 decrements,
; ~10 s); on release clear DemoMode so the top level returns to the menu instead of
; starting the demo race.
; In:  pad input; Menu_ram_NextMessageTimer (reused as the countdown)
; Out: MainMenu_ram_DemoMode (cleared on release); ram_UpdateFunction=0 at end
; Clobbers: d0/d1
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

; countdown: subq/bpl runs 601 times (600 -> -1); time-out keeps DemoMode so the
; demo continues to the race
                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .end
                bra.w   .endStage
.buttonReleased:
                clr.w   (MainMenu_ram_DemoMode).l
.endStage:
                jsr     (Audio_StopMusic).l
                move.l  #0,(ram_UpdateFunction).l
.end:
                jsr     (Audio_Update).l
                rts
; End of function HighScore_GameTick_Demo

; *************************************************
; Function HighScore_GameTick
; Normal variant: DMA, release exits to the results, A restarts, B returns to the
; results, C opens the shop; cycle message group 42.
; In:  pad input; Menu_ram_CurrentMessageId/NextMessageTimer
; Out: RaceResults_ram_NextFunction (next screen); ram_UpdateFunction=0 at end stage
; Clobbers: d0/d1/a0
; *************************************************

HighScore_GameTick:
; DMA the 64x28 window frame buffer (1792 words = $700) to VRAM $7000
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
; message group 42: advance every 300 frames; the blink timer is reset to 30 for
; Menu_ShowMessage, the id walks by 8 and wraps at the $FFFFFFFF terminator
                subq.w  #1,(Menu_ram_MessageBlinkTimer).l
                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .loc_742A
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #300,(Menu_ram_NextMessageTimer).l
                addq.w  #8,(Menu_ram_CurrentMessageId).l
                cmpi.w  #(8*42),(Menu_ram_CurrentMessageId).l
                bpl.w   .loc_740A ; always taken: the id starts at the group base and only grows
                move.w  #(8*42),(Menu_ram_CurrentMessageId).l ; unreachable clamp (defensive)
.loc_740A:
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                bne.w   .loc_742A
                move.w  #(8*42),(Menu_ram_CurrentMessageId).l
.loc_742A:
                bsr.w   Menu_ShowMessage
                cmpi.l  #0,(RaceResults_ram_NextFunction).l
                bne.w   .endStage
.loc_743C:
                jsr     (Audio_Update).l
                rts
.buttonReleased:
                move.l  #RaceResults_Init,(RaceResults_ram_NextFunction).l ; restart this menu
.endStage:
                jsr     (Audio_StopMusic).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .loc_743C
; End of function HighScore_GameTick

; *************************************************
; Function HighScore_HandleInput
; A restarts the page, B returns to the results, C opens the shop.
; In:  d0 - current buttons (SACBRLDU; 1 = pressed; bit6=A, bit5=C, bit4=B)
; Out: RaceResults_ram_NextFunction next-screen pointer
; Clobbers: -
; *************************************************

HighScore_HandleInput:
                move.b  d0,(HighScore_ram_CurrentButtons).l ; low byte only; high byte untouched
                btst    #6,(HighScore_ram_CurrentButtons).l
                beq.w   .checkB
                move.l  #HighScore_Init,(RaceResults_ram_NextFunction).l ; pressed A -> restart this page
.checkB:
                btst    #4,(HighScore_ram_CurrentButtons).l
                beq.w   .checkC
                move.l  #RaceResults_Init,(RaceResults_ram_NextFunction).l ; pressed B -> go back to race results
.checkC:
                btst    #5,(HighScore_ram_CurrentButtons).l
                beq.w   .return
                move.l  #Shop_Init,(RaceResults_ram_NextFunction).l ; pressed C -> go to shop
.return:
                rts
; End of function HighScore_HandleInput
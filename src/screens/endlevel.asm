; *************************************************
; endlevel.asm - level-complete victory animation + level-up screen
; ROM range: $8342-$8FB3
; Status:    line-by-line (static; non-demo only)
; API:       EndLevel_Init, EndLevel_GameTick, EndLevel_UpdateAnimation,
;            EndLevel_InitVictoryCharacter, EndLevel_GameTickVictoryCharacter,
;            EndLevel_AdvanceLevel
; Flow:      outcome 4 -> Init -> victory animation -> level-up character ->
;            AdvanceLevel -> back to the menu
; Data:      EndLevel_FrameCounts, EndLevel_AnimationScript, EndLevel_LevelRiderTable;
;            the tail $8C96-$8DC1 duplicates the race_results dead text
; Assets:    img_MainMenu_Background, EndLevel_AnimationTiles/Data,
;            EndLevel_WindowImage, img_Gamepad, RiderIntro_PortraitPanel,
;            portraits, img_Intro_Font
; *************************************************

; *************************************************
; Function EndLevel_Init
; Builds the victory-animation stage: VDP, background/window/tiles/font, race
; animation state pointed at endlevel buffers, animation data decompressed.
; In:  - (Menu_ram_PlayerLevel is used later by UpdateAnimation)
; Out: VRAM $0/$1000/$2000/$3000/$5C00, plane $4000, palette; race animation state
; Clobbers: d0-d7, a0-a3
; Notes: window $3000 (full-screen via WindowY=28), sprite table $1000 and H-scroll
;        $2000 (unlike the menus); background tiles $1280, window tiles $2020,
;        animation tiles $5C00.
; *************************************************

EndLevel_Init:
; reset menu/message state and the shared race-animation buffers for a fresh stage
                move.w  #$7FFF,(Menu_ram_NextMessageTimer).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerB).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerB).l
                move.w  #$FFFF,(Menu_ram_MessageBlinkTimer).l
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l
                move.w  #$180,(Menu_ram_CurrentMessageId).l
                move.l  #0,(RaceResults_ram_NextFunction).l
                move.w  #0,(EndLevel_ram_AnimFrame).l
                move.w  #5,(EndLevel_ram_SpriteSwapDelay).l
                move.w  #0,(Race_ram_FrameReady).l
                move.w  #0,(Race_ram_FrameReady2).l
; point the shared race-animation state at endlevel's buffers; Intro_TitleScrollTable
; holds $400 bytes of H-scroll followed by $280 bytes of sprite attributes
                move.l  #Intro_ram_ImageBuffer,(Race_ram_NextSpriteTileArray).l
                move.w  #$8680,(Race_ram_SpriteDestination).l
                move.w  #$2E0,(Animation_ram_BaseTile).l ; base tile index, address = $5C00
                move.w  #0,(Race_ram_SpriteSize1).l
                move.w  #0,(Race_ram_SpriteSize2).l
                move.l  #ram_FF3FDC,(Race_ram_CurrentVScrollInfo).l
                move.l  #ram_FF425C,(Race_ram_NextVScrollInfo).l
                move.l  #Intro_TitleScrollTable,(Race_ram_CurrentHScrollTable).l
                move.l  #Intro_TitleScrollTable,(Race_ram_NextScrollTable).l
                move.l  #Intro_TitleScrollTable + $400,(Race_ram_NextSpriteAttributeTable).l
                move.l  #Intro_TitleScrollTable + $400,(Race_ram_CurrentSpriteAttributeTable).l
                move.l  #Race_ram_FrameReady,(Race_ram_CurrentFrameReady).l
                move.l  #Race_ram_FrameReady,(Race_ram_NextFrameReady).l
                move.l  #Intro_ram_ImageBuffer,(Race_ram_CurrentSpriteTileArray).l
                move.l  #Race_ram_SpriteSize1,(Race_ram_CurrentSpriteSizePtr).l
                move.l  #Race_ram_SpriteSize1,(Race_ram_NextSpriteSizePtr).l

                lea     (VdpCtrl).l,a0
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
                move.w  #$9100,(a0) ; WindowX: 0 (unused: Y split makes every line full-width window)
                move.w  #$921C,(a0) ; WindowY: 28 cells (split line 224, DOWN=0 -> window covers all visible rows)
                VDP_VRAM_WRITE $2000,(a0) ; write HScroll
                move.l  #0,(VdpData).l ; clear only the first H-scroll entry
                VDP_VRAM_WRITE $1000,(a0) ; write sprite table
                move.l  #0,(VdpData).l ; clear 4 SAT entries (8 longs)
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                VDP_VSRAM_WRITE $0,(a0) ; clear vertical scroll
                move.l  #0,(VdpData).l ; clear only the first two VSRAM words
; clear the blank tile $7FF (VRAM $FFE0, 32 bytes)
                movea.l #VdpData,a0
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
.loopDefaultTile:
                move.l  #0,(a0)
                dbf     d0,.loopDefaultTile
; background blob: tiles -> VRAM $1280 (base tile $94 = $94*$20), map at +$4E8
                lea     (img_MainMenu_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write it to VRAM address $1280
                move.l  #$1280,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; and draw it
                move.w  #40,d0 ; width
                move.w  #28,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$94,d4 ; base tile index; VRAM address = $94*$20 = $1280
                move.w  #$4000,d5 ; destination = scroll A/B
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $4E8).l,a0
                jsr     (WriteNametable).w
; victory animation tile set decompressed directly to VRAM $5C00 (base tile
; $2E0 = $2E0*$20); UpdateAnimation2 only adds this base to the script words
                lea     (EndLevel_AnimationTiles).l,a3
                movea.l #$5C00,a1
                jsr     (UncompressToVRAM).l
; clear the first 22 of the 28 frame-buffer rows (64 cells per row) to tile $7FF
                lea     (Menu_ram_FrameBuffer).l,a0
                move.l  #$7FF07FF,d1 ; two blank tile-words per long
                move.w  #$2BF,d0 ; 704 longs = 22*64 cells
.loopClearFB:
                move.l  d1,(a0)+
                dbf     d0,.loopClearFB
; fill the last 6 rows with the font's space glyph
                move.w  #$BF,d0 ; 192 longs = 6*64 cells
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                swap    d1
                move.w  (dStringCodeTable + 2 * ' ').w,d1 ; duplicate the space tile
.loc_859A:
                move.l  d1,(a0)+
                dbf     d0,.loc_859A

; window blob: tiles -> VRAM $2020 (base tile $101), map at +$368, palette at +$2E4;
; draw the 40x14 image at (0,4) into the 64-cell-wide window frame buffer
                lea     (EndLevel_WindowImage).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l

                move.l  #$2020,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l

                move.w  #40,d0 ; width
                move.w  #14,d1 ; height
                move.w  #0,d2 ; x
                move.w  #4,d3 ; y
                move.w  #$101,d4 ; base tile index; VRAM address = $101*$20 = $2020
                move.w  #64,d6 ; plane width
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                lea     (Intro_ram_ImageBuffer + $368).l,a0 ; packed map after the tiles
                jsr     (WriteNametableToBuffer).w
; copy the 64-colour window palette (4 lines x 8 longs) from blob +$2E4
                lea     (Intro_ram_ImageBuffer + $2E4).l,a0
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
; load the font tiles at VRAM $0 (used by the name, quote and message text)
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write it to VRAM address $0
                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; DMA the whole 64x28 frame buffer ($700 words) to the window nametable $3000
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$3000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM
; decompress the animation frames to Intro_ram_ImageBuffer (size $5066); the
; script below points at the individual frames in that buffer
                lea     (EndLevel_AnimationData).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                jsr     (Audio_StopMusic).l
                tst.w   (ram_MusicEnabled).l
                beq.w   .return
                move.l  #9,d0 ; level-complete music track
                jsr     (Audio_StartMusic).l
.return:
                rts
; End of function EndLevel_Init

; *************************************************
; Function EndLevel_InitVictoryCharacter
; Level-up screen: panel, level-up rider from EndLevel_LevelRiderTable (level-1, two
; variants), name/quote/palette, then EndLevel_AdvanceLevel advances the level and
; rebuilds the opponents.
; In:  Menu_ram_PlayerLevel (before increment), Menu_ram_Player
; Out: Menu_ram_FrameBuffer -> VRAM $3000; VRAM $9000/$C000; CRAM; password
; Clobbers: d0-d7, a0-a3
; Notes: called from GameTick's end stage; the rider is selected for the completed
;        level before AdvanceLevel increments it.
; *************************************************

EndLevel_InitVictoryCharacter:
; $50000000 = VRAM write $1000; clear the first two SAT entries (8 bytes) so the
; victory-animation sprites disappear
                move.l  #$50000000,(VdpCtrl).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
; gamepad blob: tiles -> VRAM $A000 (base tile $500), map at +$B48
                lea     (img_Gamepad).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
                move.l  #$A000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
                move.w  #$C,d0
                move.w  #6,d1
                move.w  #2,d2
                move.w  #$16,d3
                move.w  #$500,d4 ; base tile index; VRAM address = $500*$20 = $A000
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer + $B48).l,a0 ; packed map after the tiles
                jsr     (WriteNametable).w
; same 64x28 frame-buffer clear as Init: 22 rows of tile $7FF, then 6 space rows
                lea     (Menu_ram_FrameBuffer).l,a0
                move.l  #$7FF07FF,d1
                move.w  #$2BF,d0
.loc_86FA:
                move.l  d1,(a0)+
                dbf     d0,.loc_86FA
                move.w  #$BF,d0
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                swap    d1
                move.w  (dStringCodeTable + 2 * ' ').w,d1
.loc_870E:
                move.l  d1,(a0)+
                dbf     d0,.loc_870E
; portrait panel blob: tiles -> VRAM $9000 (base tile $480), map at +$168
                lea     (RiderIntro_PortraitPanel).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
                move.l  #$9000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
                move.w  #$C,d0
                move.w  #$E,d1
                move.w  #2,d2
                move.w  #5,d3
                move.w  #$480,d4 ; base tile index; VRAM address = $480*$20 = $9000
                move.w  #$40,d6 ; window plane width 64 cells
                lea     (Intro_ram_ImageBuffer + $168).l,a0 ; packed map after the tiles
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w
; level-up rider table: 5 levels x 2 variants (rival + Natasha), 16 bytes per level;
; Rand bit 3 selects the second 8-byte record, (level-1)*$10 selects the level
                lea     (EndLevel_LevelRiderTable).l,a0
                jsr     (Rand_NextWord).l
                andi.w  #8,d0
                adda.w  d0,a0
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
                move.l  (a0),-(sp) ; save quote pointer
                movea.l 4(a0),a3 ; portrait image pointer
; the image pointer follows an 8-byte prefix; its odd bytes hold the pointer to
; the 10-byte header (image/nametable/palette offsets); rebuild that pointer
                move.b  -7(a3),d0
                lsl.l   #8,d0
                move.b  -5(a3),d0
                lsl.l   #8,d0
                move.b  -3(a3),d0
                lsl.l   #8,d0
                move.b  -1(a3),d0
                move.l  d0,-(sp) ; save the reconstructed header pointer
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
                move.l  #$C000,d0 ; portrait tiles -> VRAM $C000
                movea.l (sp),a0
                movea.w -6(a0),a0 ; header -6 = tile offset from the image buffer
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     (WriteTilesetToVRAM).l
                move.w  #$A,d0 ; width
                move.w  #$C,d1 ; height
                move.w  #3,d2 ; x
                move.w  #6,d3 ; y
                move.w  #$600,d4 ; base tile index; VRAM address = $600*$20 = $C000
                move.w  #$40,d6 ; window plane width 64 cells
                movea.l (sp),a0
                movea.w -4(a0),a0 ; header -4 = nametable offset
                adda.l  #Intro_ram_ImageBuffer + 4,a0 ; +4 skips the (w,h) pair
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w
                movea.l (sp),a0
                movea.w -2(a0),a0 ; header -2 = palette offset
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l (Global_ram_PalettePtr).l,a1
                move.w  #7,d0
.loc_8806:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_8806
                move.w  #7,d0
.loc_8810:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_8810
                move.w  #7,d0
.loc_881A:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_881A
                move.w  #7,d0
.loc_8824:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_8824
                move.l  (Global_ram_PalettePtr).l,d0 ; source: 4x8 longs = 64 colours
                move.w  #0,d1 ; CRAM start
                move.w  #$40,d2 ; 64 words
                jsr     (DmaWriteCRAM).l
                movea.l (sp)+,a0 ; quote pointer
                movea.l -$A(a0),a0 ; quote header -10 = long name-string pointer
                addq.w  #6,a0 ; +6 skips the 6-byte string descriptor
                lea     (Menu_ram_TempString).l,a1
                move.w  #$13,(a1)+ ; y = 19
                move.w  #3,(a1)+ ; x = 3
                move.w  #1,(a1)+ ; height = 1
                move.w  #$A,(a1)+ ; width = 10
                move.l  (a0)+,(a1)+ ; copy the 10-character name
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                clr.w   d0 ; d0 = trailing spaces - leading spaces
                movea.l a1,a0
.loc_8866:
                cmpi.b  #$20,-(a0)
                bne.w   .loc_8872
                addq.w  #1,d0
                bra.s   .loc_8866
.loc_8872:
                lea     -$A(a1),a0
.loc_8876:
                cmpi.b  #$20,(a0)+
                bne.w   .loc_8882
                subq.w  #1,d0
                bra.s   .loc_8876
.loc_8882:
                asr.w   #1,d0 ; half the imbalance
                ble.w   .loc_88CC
                subq.w  #1,d0
                lea     -$A(a1),a0
.loc_888E: ; rotate the 10-char name right by one cell per iteration
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
                dbf     d0,.loc_888E
.loc_88CC:
                lea     (Menu_ram_TempString).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString
                lea     (Menu_ram_TempString).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; palette 3, font tile base 0
                move.w  #$40,d6 ; window plane width 64 cells
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
                movea.l (sp),a0 ; quote pointer
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString
                movea.l (sp)+,a0 ; quote pointer
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                asr.w   #1,d3 ; destination row = y/2; stride 128 -> rows 3,5,7,9
                move.w  #$6000,d4 ; palette 3, font tile base 0
                move.w  #$80,d6 ; stride 128 -> double-spaced rows
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
; advance the level only after the portrait/quote are selected
                jsr     (EndLevel_AdvanceLevel).l
                rts
; End of function EndLevel_InitVictoryCharacter

; *************************************************
; Function EndLevel_AdvanceLevel
; Advances the selected player's level (clamp 5): clears the outcome and the five
; places, rebuilds the 16-word opponent list (id $4B + 15 values), regenerates the
; password.
; In:  Menu_ram_Player, PlayerA/BLevel
; Out: PlayerA/BLevel/Places/Opponents; password
; Clobbers: d0/d1/a0
; *************************************************

EndLevel_AdvanceLevel:
                tst.w   (Menu_ram_Player).l
                bne.w   .loc_89B4
; player A: clear the outcome and the five course places
                clr.w   (Race_ram_PlayerAOutcome).l
                clr.w   (Menu_ram_PlayerAPlaces + 0).l
                clr.w   (Menu_ram_PlayerAPlaces + 2).l
                clr.w   (Menu_ram_PlayerAPlaces + 4).l
                clr.w   (Menu_ram_PlayerAPlaces + 6).l
                clr.w   (Menu_ram_PlayerAPlaces + 8).l
; level up, clamp at 5
                addq.w  #1,(Menu_ram_PlayerALevel).l
                cmpi.w  #5,(Menu_ram_PlayerALevel).l
                ble.w   .loc_898E
                move.w  #5,(Menu_ram_PlayerALevel).l
.loc_898E:
; opponent definition list: player id $4B followed by 15 entries starting at
; (level-1)*15
                lea     (Menu_ram_PlayerAOpponents).l,a0
                move.w  #$4B,(a0)+ ; player's own definition id
                move.w  (Menu_ram_PlayerALevel).l,d0
                subq.w  #1,d0
                mulu.w  #$F,d0
                move.w  #$E,d1 ; 15 words (dbf)
.loc_89A8:
                move.w  d0,(a0)+
                addq.w  #1,d0
                dbf     d1,.loc_89A8
                bra.w   .loc_8A14
.loc_89B4:
; player B: same reset and level advance
                clr.w   (Race_ram_PlayerBOutcome).l
                clr.w   (Menu_ram_PlayerBPlaces + 0).l
                clr.w   (Menu_ram_PlayerBPlaces + 2).l
                clr.w   (Menu_ram_PlayerBPlaces + 4).l
                clr.w   (Menu_ram_PlayerBPlaces + 6).l
                clr.w   (Menu_ram_PlayerBPlaces + 8).l
; level up, clamp at 5
                addq.w  #1,(Menu_ram_PlayerBLevel).l
                cmpi.w  #5,(Menu_ram_PlayerBLevel).l
                ble.w   .loc_89F2
                move.w  #5,(Menu_ram_PlayerBLevel).l
.loc_89F2:
; opponent definition list: player id $4B followed by 15 entries starting at
; (level-1)*15
                lea     (Menu_ram_PlayerBOpponents).l,a0
                move.w  #$4B,(a0)+ ; player's own definition id
                move.w  (Menu_ram_PlayerBLevel).l,d0
                subq.w  #1,d0
                mulu.w  #$F,d0
                move.w  #$E,d1 ; 15 words (dbf)
.loc_8A0C:
                move.w  d0,(a0)+
                addq.w  #1,d0
                dbf     d1,.loc_8A0C
.loc_8A14:
; regenerate the password after the level/opponents change
                jsr     (MenuPassword_CreatePassword).w
                rts
; End of function EndLevel_AdvanceLevel

; *************************************************
; Function EndLevel_GameTickVictoryCharacter
; Level-up rider screen: DMA the frame buffer to $3000, Start held exits, and the
; message group $180 cycles on the 120/30-frame timers.
; In:  pad input; message timers
; Out: ram_UpdateFunction=0 at end
; Clobbers: d0/d1/a0
; Notes: Start is checked on the new pad state, so holding it exits; the frame
;        buffer is re-DMAed every call.
; *************************************************

EndLevel_GameTickVictoryCharacter:
; DMA the whole 64x28 frame buffer ($700 words) to the window nametable $3000
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$3000,d1
                move.w  #$700,d2
                bsr.w   DmaWriteVRAM
; latch the previous pad state, read the new state, and keep changed bits in RAM;
; d0 remains the new state, so Start held ($80) exits
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerA).l
                andi.w  #$80,d0
                bne.w   .loc_8ADC
; same check for player B
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerB).l
                andi.w  #$80,d0
                bne.w   .loc_8ADC
; decrement both timers; when the next-message timer goes negative, reload it and
; advance one 8-byte Message_MsgArray entry (group $180..)
                subq.w  #1,(Menu_ram_MessageBlinkTimer).l
                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .loc_8AC2
                move.w  #$1E,(Menu_ram_MessageBlinkTimer).l ; blink period 30
                move.w  #$78,(Menu_ram_NextMessageTimer).l ; 120-frame next-message delay
                addq.w  #8,(Menu_ram_CurrentMessageId).l
                cmpi.w  #$180,(Menu_ram_CurrentMessageId).l
                bpl.w   .loc_8AAA
                move.w  #$180,(Menu_ram_CurrentMessageId).l ; clamp to group start
.loc_8AAA:
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0 ; 8-byte entry -> text/show-function pointer
                cmpa.l  #$FFFFFFFF,a0 ; $FFFFFFFF terminates the message group
                beq.w   .loc_8ADC
.loc_8AC2:
                bsr.w   Menu_ShowMessage
                cmpi.l  #0,(RaceResults_ram_NextFunction).l
                bne.w   .loc_8ADC ; non-zero NextFunction also exits (Init clears it)
.loc_8AD4:
                jsr     (Audio_Update).l
                rts
.loc_8ADC:
; exit: stop the music, clear the per-frame callback, then still update audio
                jsr     (Audio_StopMusic).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .loc_8AD4
; End of function EndLevel_GameTickVictoryCharacter

; *************************************************
; Function EndLevel_GameTick
; Victory-animation timing: read pads, DMA the next sprite table and swap frames on
; the swap-delay period; when the animation ends switch to the level-up character
; screen.
; In:  Race_ram_NextFrameReady/NextScrollTable, EndLevel_ram_AnimFrame
; Out: VRAM sprite table $1000; ram_UpdateFunction at the end stage
; Clobbers: d0-d2/a0-a2
; Notes: the delay is decremented before the sign test, so a reload of 5 gives six
;        GameTick calls per swap (five calls without a DMA).
; *************************************************

EndLevel_GameTick:
; get player A input
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerA).l
; get player B input
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerB).l

                subq.w  #1,(Menu_ram_NextMessageTimer).l
; a negative frame marks the end of the victory animation
                tst.w   (EndLevel_ram_AnimFrame).l
                bmi.w   .endStage

; 5 -> 4..0 without a swap, then -1 triggers the swap: period = 6 calls
                subq.w  #1,(EndLevel_ram_SpriteSwapDelay).l
                bpl.w   .end
                lea     (VdpCtrl).l,a0
                lea     (VdpData).l,a1
                movea.l (Race_ram_NextFrameReady).l,a2
                tst.w   (a2)
                beq.w   .end
                move.w  #5,(EndLevel_ram_SpriteSwapDelay).l
; sprite table: NextScrollTable+$400 is the SAT half of the pair; 320 words
; ($140) covers the 80 SAT entries
                move.l  (Race_ram_NextScrollTable).l,d0
                addi.w  #$400,d0
                move.w  #$1000,d1
                move.w  #$140,d2
                jsr     (DmaWriteVRAM).l

                jsr     (Race_SwapFrames).l
.end:
                jsr     (Audio_Update).l
                rts
.endStage:
; animation done: build the level-up rider screen and install its tick as the
; per-frame callback
                jsr     (EndLevel_InitVictoryCharacter).l
                move.l  #EndLevel_GameTickVictoryCharacter,(ram_UpdateFunction).l
                bra.s   .end
; End of function EndLevel_GameTick

; *************************************************
; Function EndLevel_UpdateAnimation
; Plays the per-level victory animation: EndLevel_FrameCounts holds the inclusive
; last frame index per level; the shared EndLevel_AnimationScript is consumed via
; UpdateAnimation2 at x/y $80. At the end it waits for a Start release or 2 s.
; In:  EndLevel_ram_AnimFrame, Menu_ram_PlayerLevel, pad state
; Out: endlevel sprite table; EndLevel_ram_AnimFrame; NextMessageTimer
; Clobbers: d0-d2/a0/a1/a4
; Notes: a negative EndLevel_ram_AnimFrame means the animation stage is over.
; *************************************************

EndLevel_UpdateAnimation:
                tst.w   (EndLevel_ram_AnimFrame).l
                bmi.w   .return

; per-level last frame index (35,54,81,91,123); the comparison is inclusive
                lea     (EndLevel_FrameCounts).l,a0
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                adda.w  d0,a0
                adda.w  d0,a0
                move.w  (a0),d0
                cmp.w   (EndLevel_ram_AnimFrame).l,d0
                bcs.w   .endAnimation
; wait until the previous animation frame has been consumed
                movea.l (Race_ram_CurrentFrameReady).l,a0
                tst.w   (a0)
                bne.w   .return

                clr.w   (Animation_ram_SpriteIndex).l
                move.w  #$2E0,(Animation_ram_BaseTile).l ; tiles are already at VRAM $5C00
                move.w  (EndLevel_ram_AnimFrame).l,d0 ; frame index
                movea.l (Race_ram_CurrentSpriteAttributeTable).l,a0 ; SAT destination
                movea.l (Race_ram_CurrentSpriteTileArray).l,a1 ; unused by UpdateAnimation2
                lea     (EndLevel_AnimationScript).l,a4 ; script
                move.w  #$80,d1 ; screen x
                move.w  #$80,d2 ; screen y
                jsr     (UpdateAnimation2).l
                addq.w  #1,(EndLevel_ram_AnimFrame).l
                jsr     (Race_FinishFrame).l
.return:
                rts
.endAnimation:
; wait until both frame buffers have been consumed before accepting input
                tst.w   (Race_ram_FrameReady).l
                bne.w   .loc_8C80
                tst.w   (Race_ram_FrameReady2).l
                bne.w   .loc_8C80

; Start release (changed bit set, current bit clear) ends the stage early
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d0
                andi.w  #$80,d0
                beq.w   .loc_8C42
                move.w  (MainMenu_ram_ButtonsPlayerA).l,d0
                andi.w  #$80,d0
                bne.w   .loc_8C42
                move.w  #-1,(Menu_ram_NextMessageTimer).l
.loc_8C42:
; same Start-release check for player B
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d0
                andi.w  #$80,d0
                beq.w   .loc_8C66
                move.w  (MainMenu_ram_ButtonsPlayerB).l,d0
                andi.w  #$80,d0
                bne.w   .loc_8C66
                move.w  #-1,(Menu_ram_NextMessageTimer).l
.loc_8C66:
                tst.w   (Menu_ram_NextMessageTimer).l
                bpl.s   .return
; input/timer expired: mark the animation done; the next GameTick switches stages
                move.w  #-1,(EndLevel_ram_AnimFrame).l
                move.w  #120,(Menu_ram_NextMessageTimer).l ; 2 seconds
                bra.s   .return
.loc_8C80:
; frames still pending: restart the 2 s input window and keep waiting
                move.w  #120,(Menu_ram_NextMessageTimer).l ; 2 seconds
                bra.w   .return
; End of function EndLevel_UpdateAnimation

; per-level last frame index; level 5=123 is one past the script's last valid
; frame 122, so it plays one extra no-op frame
EndLevel_FrameCounts:
    dc.w 35,54,81,91,123

; dead: unreferenced [static]; duplicates RaceResults_StrNextLevelShort in
; race_results.asm; kept for byte-exactness
unk_8C96:
    dc.w 22,16,5,20
    dc.b " To go to the next  "
    dc.b "                    "
    dc.b " level, you need to "
    dc.b "                    "
    dc.b "  earn        more. "

; dead: unreferenced [static]; duplicate of RaceResults_StrNotReadyEncoded. The 20
; bytes are ASCII with bit 7 set ("You aren't ready for")
unk_8D02:
    dc.b $D9, $EF, $F5, $A0, $E1, $F2, $E5, $EE
    dc.b $A7, $F4, $A0, $F2, $E5, $E1, $E4, $F9
    dc.b $A0, $E6, $EF, $F2

; dead: unreferenced [static]; duplicate of RaceResults_StrNotReadyTail
unk_8D16:
    dc.b "the next level yet.   You need to earn      $12345 more.    "

; dead: unreferenced [static]; duplicate of RaceResults_StrContinuePlay
unk_8D52:
    dc.w 23,12,3,16
    dc.b "Continue play at"
    dc.b "                "
    dc.b " Current level 0"

; dead: unreferenced [static]; duplicate of RaceResults_StrNextLevel
unk_8D8A:
    dc.w 23,12,3,16
    dc.b " The next level "
    dc.b "                "
    dc.b " will be level 0"

; Victory animation script consumed by UpdateAnimation2 (see race.asm).
; Format: .l tilemap base, .w last frame index, .l frame pointer[frame_count+1].
; Pointers are absolute addresses in the decompressed EndLevel_AnimationData
; buffer at Intro_ram_ImageBuffer; frame N is pointed to by entry N.
EndLevel_AnimationScript:
    dc.l    EndLevel_AnimationTiles ; tilemap base; unused by UpdateAnimation2
    dc.w    122                     ; last frame index (123 frames, 0..122)
; level 1: frames 0-35
    dc.l    Intro_ram_ImageBuffer+$0000 ; frame 0: 0 sprites
    dc.l    Intro_ram_ImageBuffer+$000A ; frame 1: 0 sprites
    dc.l    Intro_ram_ImageBuffer+$0014 ; frame 2: 1 sprites
    dc.l    Intro_ram_ImageBuffer+$0026 ; frame 3: 5 sprites
    dc.l    Intro_ram_ImageBuffer+$0058 ; frame 4: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$00FA ; frame 5: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$019C ; frame 6: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$023E ; frame 7: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$02E0 ; frame 8: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$0382 ; frame 9: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$0424 ; frame 10: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$04C6 ; frame 11: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$0568 ; frame 12: 17 sprites
    dc.l    Intro_ram_ImageBuffer+$05FA ; frame 13: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$0694 ; frame 14: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$072E ; frame 15: 16 sprites
    dc.l    Intro_ram_ImageBuffer+$07B8 ; frame 16: 16 sprites
    dc.l    Intro_ram_ImageBuffer+$0842 ; frame 17: 17 sprites
    dc.l    Intro_ram_ImageBuffer+$08D4 ; frame 18: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$096E ; frame 19: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$0A08 ; frame 20: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$0AA2 ; frame 21: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$0B3C ; frame 22: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$0BD6 ; frame 23: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$0C88 ; frame 24: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$0D3A ; frame 25: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$0DEC ; frame 26: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$0EA6 ; frame 27: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$0F60 ; frame 28: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$101A ; frame 29: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$10D4 ; frame 30: 31 sprites
    dc.l    Intro_ram_ImageBuffer+$11D6 ; frame 31: 31 sprites
    dc.l    Intro_ram_ImageBuffer+$12D8 ; frame 32: 31 sprites
    dc.l    Intro_ram_ImageBuffer+$13DA ; frame 33: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$1494 ; frame 34: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$154E ; frame 35: 22 sprites
; level 2: frames 36-54
    dc.l    Intro_ram_ImageBuffer+$1608 ; frame 36: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$16C2 ; frame 37: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$1774 ; frame 38: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$1826 ; frame 39: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$18D8 ; frame 40: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$198A ; frame 41: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$1A44 ; frame 42: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$1AFE ; frame 43: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$1BB8 ; frame 44: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$1C5A ; frame 45: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$1CFC ; frame 46: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$1D9E ; frame 47: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$1E58 ; frame 48: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$1F12 ; frame 49: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$1FCC ; frame 50: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$2086 ; frame 51: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$2128 ; frame 52: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$21CA ; frame 53: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$226C ; frame 54: 19 sprites
; level 3: frames 55-81
    dc.l    Intro_ram_ImageBuffer+$230E ; frame 55: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$23B0 ; frame 56: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$246A ; frame 57: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$2524 ; frame 58: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$25DE ; frame 59: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$2698 ; frame 60: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$2752 ; frame 61: 22 sprites
    dc.l    Intro_ram_ImageBuffer+$280C ; frame 62: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$28BE ; frame 63: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$2970 ; frame 64: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$2A22 ; frame 65: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$2AD4 ; frame 66: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$2B86 ; frame 67: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$2C38 ; frame 68: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$2CD2 ; frame 69: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$2D6C ; frame 70: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$2E06 ; frame 71: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$2EB0 ; frame 72: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$2F5A ; frame 73: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$3004 ; frame 74: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$30AE ; frame 75: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$3148 ; frame 76: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$31E2 ; frame 77: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$327C ; frame 78: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$3316 ; frame 79: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$33B0 ; frame 80: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$344A ; frame 81: 18 sprites
; level 4: frames 82-91
    dc.l    Intro_ram_ImageBuffer+$34E4 ; frame 82: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$357E ; frame 83: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$3618 ; frame 84: 19 sprites
    dc.l    Intro_ram_ImageBuffer+$36BA ; frame 85: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$3764 ; frame 86: 24 sprites
    dc.l    Intro_ram_ImageBuffer+$382E ; frame 87: 24 sprites
    dc.l    Intro_ram_ImageBuffer+$38F8 ; frame 88: 24 sprites
    dc.l    Intro_ram_ImageBuffer+$39C2 ; frame 89: 24 sprites
    dc.l    Intro_ram_ImageBuffer+$3A8C ; frame 90: 24 sprites
    dc.l    Intro_ram_ImageBuffer+$3B56 ; frame 91: 18 sprites
; level 5: frames 92-122 (limit 123 adds one no-op frame)
    dc.l    Intro_ram_ImageBuffer+$3BF0 ; frame 92: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$3C8A ; frame 93: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$3D34 ; frame 94: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$3DDE ; frame 95: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$3E88 ; frame 96: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$3F32 ; frame 97: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$3FDC ; frame 98: 21 sprites
    dc.l    Intro_ram_ImageBuffer+$408E ; frame 99: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$4138 ; frame 100: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$41E2 ; frame 101: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$427C ; frame 102: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$4316 ; frame 103: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$43B0 ; frame 104: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$444A ; frame 105: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$44E4 ; frame 106: 18 sprites
    dc.l    Intro_ram_ImageBuffer+$457E ; frame 107: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$4628 ; frame 108: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$46D2 ; frame 109: 20 sprites
    dc.l    Intro_ram_ImageBuffer+$477C ; frame 110: 23 sprites
    dc.l    Intro_ram_ImageBuffer+$483E ; frame 111: 27 sprites
    dc.l    Intro_ram_ImageBuffer+$4920 ; frame 112: 27 sprites
    dc.l    Intro_ram_ImageBuffer+$4A02 ; frame 113: 24 sprites
    dc.l    Intro_ram_ImageBuffer+$4ACC ; frame 114: 26 sprites
    dc.l    Intro_ram_ImageBuffer+$4BA6 ; frame 115: 25 sprites
    dc.l    Intro_ram_ImageBuffer+$4C78 ; frame 116: 26 sprites
    dc.l    Intro_ram_ImageBuffer+$4D52 ; frame 117: 24 sprites
    dc.l    Intro_ram_ImageBuffer+$4E1C ; frame 118: 23 sprites
    dc.l    Intro_ram_ImageBuffer+$4EDE ; frame 119: 23 sprites
    dc.l    Intro_ram_ImageBuffer+$4FA0 ; frame 120: 7 sprites
    dc.l    Intro_ram_ImageBuffer+$4FE2 ; frame 121: 7 sprites
    dc.l    Intro_ram_ImageBuffer+$5024 ; frame 122: 7 sprites

; *************************************************
; race_results.asm - post-race results / bust / repair screens
; ROM range: $5F28-$6DBF
; Status:    analyzed (static; demo skips the screen); line-by-line pass done
; API:       RaceResults_Init, RaceResults_GameTick, RaceResults_HandleInput
; VRAM:      $0000 font; $6000 sprite table / H-scroll table;
;            $7000 64x28 window frame buffer; $8000 menu background;
;            $9000 results/busted title; $A000 gamepad; $B000 track image or
;            portrait panel; $C000 portrait tiles; $FFE0 blank tile $7FF
; Data:      $6C94-$6DBF is unreferenced text duplicated from endlevel.asm
; *************************************************

; *************************************************
; Function RaceResults_Init
; Builds the post-race screen: outcome flags, VDP setup, one of the normal/busted/
; repair layouts, cash/password box, congratulations text, audio.
; In:  Race_ram_PlayerAOutcome/BOutcome (outcome), Race_EventBuffer (event buffer),
;      Race_CopIndex (cop index), RaceResults_ram_Amount (fine/repair),
;      Menu_ram_Money / Menu_ram_PlayerLevel
; Out: Menu_ram_FrameBuffer -> VRAM $7000; VRAM $0/$8000/$9000/$A000/$B000/$C000
; Clobbers: d0-d7, a0-a3
; Notes: message group 21 = course incomplete, 28 = worse than 4th, 35 = level clear.
; *************************************************

RaceResults_Init:
; clear the pad latches so the first GameTick sees a clean previous state
                move.w  #0,(Menu_ram_NextMessageTimer).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerB).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerB).l
; a negative blink timer means "text visible now" in Menu_ShowMessage
                move.w  #$FFFF,(Menu_ram_MessageBlinkTimer).l
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l
; hold the first message for 25 s (1500 frames) before the 300-frame cycle
                move.w  #1500,(Menu_ram_NextMessageTimer).l
                move.l  #0,(RaceResults_ram_NextFunction).l
; outcome (computed by Race_ComputeResults): 0 = incomplete, >4 = worse than 4th,
; 4 = level complete; Menu_ram_Player selects which player's copy is used
                move.w  (Race_ram_PlayerAOutcome).l,(RaceResults_ram_Outcome).l ; player A
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_5F90
                move.w  (Race_ram_PlayerBOutcome).l,(RaceResults_ram_Outcome).l ; player B
.loc_5F90:
; pick the message group for this outcome
                tst.w   (RaceResults_ram_Outcome).l
                beq.w   .loc_5FBE
                cmpi.w  #4,(RaceResults_ram_Outcome).l
                bne.w   .loc_5FB2
                move.w  #(8*35),(Menu_ram_CurrentMessageId).l ; level clear group
                bra.w   .loc_5FCA
.loc_5FB2:
                move.w  #(8*28),(Menu_ram_CurrentMessageId).l ; worse-than-4th group
                bra.w   .loc_5FCA
.loc_5FBE:
                move.w  #(8*21),(Menu_ram_CurrentMessageId).l ; incomplete group
                bra.w   .loc_5FCA
.loc_5FCA:
                lea     (VdpCtrl).l,a0
                move.w  #$8004,(a0) ; reg0: H-int off, left column unblanked, HV counter normal (bit2 fixed 1)
                move.w  #$8174,(a0) ; reg1: display on, V-int on, DMA on, 28-row mode (M2=0)
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
                VDP_VRAM_WRITE $6000,(a0) ; point at the sprite attribute table
; eight longs = 32 bytes = four 8-byte SAT entries (all zero = disabled)
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                move.l  #0,(VdpData).l
                VDP_VSRAM_WRITE $0,(a0) ; VSRAM address 0
                move.l  #0,(VdpData).l ; two longs clear VSRAM $0-$7
                movea.l #VdpData,a0
; create the blank tile: 32 bytes at VRAM $FFE0 = tile $7FF, all zero
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
                lea     (Intro_ram_ImageBuffer + $4E8).l,a0 ; packed map offset
                jsr     (WriteNametable).w
; gamepad diagram on the plane at (2,22); the button icons are in this tile set
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
                lea     (Intro_ram_ImageBuffer + $B48).l,a0 ; packed map offset
                jsr     (WriteNametable).w
; clear the 64x28 frame buffer to blank tile $7FF: $380 longs = $700 words
                lea     (Menu_ram_FrameBuffer).l,a0
                move.l  #$7FF07FF,d1 ; two blank cells per long
                move.w  #$37F,d0
.clearFB:
                move.l  d1,(a0)+
                dbf     d0,.clearFB
; font at VRAM $0 (name/cash/password and messages)
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $0
                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l

; $FFFF in the event buffer means busted/bike destroyed; otherwise normal standings
                cmpi.w  #$FFFF,(Race_EventBuffer).l
                beq.w   .loc_616E
                bsr.w   RaceResults_DrawStandings
                bra.w   .loc_6190
.loc_616E:
                move.l  #10,d0
                jsr     (Audio_StartMusic).l
; cop index != 0 -> caught by the cops; 0 -> bike destroyed/repair
                tst.w   (Race_CopIndex).l
                beq.w   .loc_618C
                bsr.w   RaceResults_DrawBusted
                bra.w   .loc_6190
.loc_618C:
                bsr.w   RaceResults_DrawRepair
.loc_6190:
; DMA the 64x28 frame buffer to the window nametable at $7000 ($700 words)
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     (DmaWriteVRAM).l

; reuse the password-screen status record as a 5x12 cash/password box at
; (14,22); the text area starts at +8, after the (y,x,height,width) header
                lea     (MenuPassword_StrPasswordStatus).l,a0
                move.w  #22,(a0)+ ; y
                move.w  #14,(a0)+ ; x
                move.w  #5,(a0)+ ; height
                move.w  #12,(a0)+ ; width
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a1 ; skip header
                lea     (MenuPassword_ram_StrPlayerAPassword + $8).l,a2 ; skip header
                lea     (Menu_ram_MoneyPlayerA).l,a3
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_61E8
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a1 ; skip header
                lea     (MenuPassword_ram_StrPlayerBPassword + $8).l,a2 ; skip header
                lea     (Menu_ram_MoneyPlayerB).l,a3
.loc_61E8:
; rows are 12 chars wide, but 16 blank bytes are cleared; the extra 4 bytes
; run into the next row and are overwritten by that row's own write
                move.l  #'    ',(a0)
                move.l  #'    ',4(a0)
                move.l  #'    ',8(a0)
                move.l  #'    ',12(a0)
; player name: 10 chars copied into the first 12-char row
                move.l  (a1)+,(a0)
                move.l  (a1)+,4(a0)
                move.w  (a1)+,8(a0)
                adda.w  #12,a0 ; go to second line
; second row: "cash" label, then the right-aligned amount
                move.l  #'cash',(a0)
                move.l  #'    ',4(a0)
                move.l  #'    ',8(a0)
                move.l  #'    ',12(a0)
                adda.w  #12,a0 ; go to third line
; save the row pointer: Race_FormatMoney writes backwards from a0, so the
; number ends at the saved pointer and the "cash" label stays left-aligned
                move.l  a0,-(sp)
                move.l  (a3),d0
                bpl.w   .loc_6244
; field +4 is the record height: 5 -> 3 hides the two password rows when the
; player is broke and the screen shows GAME OVER
                subq.w  #2,(MenuPassword_StrPasswordStatus + 4).l
.loc_6244:
; format the money into the right end of the cash row (backwards formatter)
                jsr     (Race_FormatMoney).l
                movea.l (sp)+,a0
                move.l  #'    ',(a0)
                move.l  #'    ',4(a0)
                move.l  #'    ',8(a0)
                move.l  #'    ',$C(a0)
                adda.w  #12,a0
; password: 24 chars = two 12-char rows following the blank third row
                move.w  #23,d0
.loopWritePassword:
                move.b  (a2)+,(a0)+
                dbf     d0,.loopWritePassword
; copy the congratulations record (8-byte header + height*width chars) to the
; runtime record, then patch the level digit at row 4; dbf loops d0+1 times, so
; height*width+7 copies the header plus the whole text
                lea     (Message_StrCongratulations).w,a0
                lea     (Message_ram_DynamicRecord).l,a1
                move.w  4(a0),d0
                mulu.w  6(a0),d0
                addq.w  #7,d0
.loc_628C:
                move.b  (a0)+,(a1)+
                dbf     d0,.loc_628C
; clamp the 1-based level to 4 and add it to the template '1' at row 4,
; column 14 (a1 points past the copied record; -6 lands on that digit)
; The screen runs before EndLevel_AdvanceLevel, so PlayerLevel is the level just
; completed; '1'+level shows 2..5, i.e. the next level (clamped to 5) (U-0006).
                move.w  (Menu_ram_PlayerLevel).l,d0
                cmp.w   #5,d0
                bmi.w   .loc_62A4
                move.w  #4,d0
.loc_62A4:
                subq.w  #6,a1
                add.b   d0,(a1)
                cmpi.w  #$FFFF,(Race_EventBuffer).l
                beq.w   .return
                jsr     (Audio_StopMusic).l
                move.l  #9,d0
                move.w  d0,(ram_CurrentSong).l
                jsr     (Audio_StartMusic).l
.return:
                rts
; End of function RaceResults_Init

; *************************************************
; Function RaceResults_DrawStandings
; Normal race results: title, track image/palette, top finishers, player row highlight.
; In:  RaceResults_ram_StandingsRecord/Height/Width standings record, Menu_ram_PlayerAPlaces/BPlaces,
;      Menu_ram_CurrentTrackId
; Out: Menu_ram_FrameBuffer standings, VRAM $9000/$B000, global palette
; Clobbers: d0-d6, a0-a3
; *************************************************

RaceResults_DrawStandings:
                move.l  #RaceResults_DrawStandings,(RaceResults_ram_DrawRoutine).l
; title tiles -> VRAM $9000, drawn 27x2 at (7,1) with base tile $480
                lea     (RaceResults_TitleTiles).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write to VRAM address $9000
                move.l  #$9000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; and draw it
                move.w  #27,d0 ; width
                move.w  #2,d1 ; height
                move.w  #7,d2 ; x
                move.w  #1,d3 ; y
                move.w  #$480,d4 ; base tile index, address = $9000
                move.w  #$4000,d5 ; destination VRAM = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $588).l,a0 ; packed map offset
                jsr     (WriteNametable).w
; per-track image/nametable/palette tables live just before top_level;
; CurrentTrackId is even (0,2,4,6,8), so *2 indexes the 5-long pointer table
                lea     (RaceResults_TrackImagePtrs).l,a3
                move.w  (Menu_ram_CurrentTrackId).l,d0
                asl.w   #1,d0
                movea.l (a3,d0.w),a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write it to VRAM address $B000
; the offset tables hold words indexed directly by the even track id
                lea     (RaceResults_TrackImageOffsets).l,a0
                adda.w  (Menu_ram_CurrentTrackId).l,a0
                movea.w (a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                move.l  #$B000,d0
                jsr     (WriteTilesetToVRAM).l
; and draw it
                move.w  #36,d0 ; width
                move.w  #11,d1 ; height
                move.w  #2,d2 ; x
                move.w  #5,d3 ; y
                move.w  #$580,d4 ; base tile index, address = $B000
                move.w  #$4000,d5 ; VRAM address = Scroll A/B
                move.w  #128,d6 ; plane width
                lea     (RaceResults_TrackNametableOffsets).l,a0
                adda.w  (Menu_ram_CurrentTrackId).l,a0
                movea.w (a0),a0
                adda.l  #Intro_ram_ImageBuffer + 4,a0 ; +4 skips the width/height pair
                jsr     (WriteNametable).w
; load palette
                lea     (RaceResults_TrackPaletteOffsets).l,a0
                adda.w  (Menu_ram_CurrentTrackId).l,a0
                movea.w (a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l (Global_ram_PalettePtr).l,a1
; copy 4 palette lines: 4 * 32 bytes = 128 bytes = 64 colours
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
; draw the finishers; the player's row uses palette 2, the others palette 3
                lea     (RaceResults_ram_StandingsRecord).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString

                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  (RaceResults_ram_StandingsWidth).l,d0
                mulu.w  (RaceResults_ram_StandingsHeight).l,d0
                subq.w  #1,d0
.loc_63FA:
                ori.w   #$6000,(a0)+ ; palette bits 14-13 = 3
                dbf     d0,.loc_63FA

                move.w  (Menu_ram_CurrentTrackId).l,d0
                lea     (Menu_ram_PlayerAPlaces).l,a0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_641E
                lea     (Menu_ram_PlayerBPlaces).l,a0 ; player B
.loc_641E:
                move.w  (a0,d0.w),d0 ; get player place in current race
                cmp.w   #4,d0
                ble.w   .loc_642E
                move.w  #4,d0
.loc_642E:
; player row = (clamped place - 1); * width * 2 gives a word offset
                subq.w  #1,d0
                mulu.w  (RaceResults_ram_StandingsWidth).l,d0
                asl.w   #1,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                adda.w  d0,a0
                move.w  (RaceResults_ram_StandingsWidth).l,d0
                subq.w  #1,d0
.loc_6448:
                andi.w  #$DFFF,(a0)+ ; clear bit 13: palette 3 -> palette 2
                dbf     d0,.loc_6448

                lea     (RaceResults_ram_StandingsRecord).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #0,d4 ; base tile index = 0, text
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
                rts
; End of function RaceResults_DrawStandings

; *************************************************
; Function RaceResults_DrawBusted
; Caught-by-cops layout: title, panel, cop portrait/quote by Race_CopIndex, fine or GAME OVER.
; In:  Race_CopIndex (cop index), Menu_ram_MoneyPlayerA/B, RaceResults_ram_Amount (fine)
; Notes: the table base is pushed on the stack and popped at the end to choose
;        between the fine text and the "can't afford bail" text.
; Out: Menu_ram_FrameBuffer portrait/name/quote/message; VRAM $9000/$B000/$C000
; Clobbers: d0-d7, a0-a3
; *************************************************

RaceResults_DrawBusted:
; record the active draw routine (write-only in this disassembly)
                move.l  #RaceResults_DrawBusted,(RaceResults_ram_DrawRoutine).l
; busted title tiles -> VRAM $9000, drawn $15x2 at ($A,1), base tile $480
                lea     (RaceResults_BustedTitleTiles).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
                move.l  #$9000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
                move.w  #$15,d0
                move.w  #2,d1
                move.w  #$A,d2
                move.w  #1,d3
                move.w  #$480,d4
                move.w  #$4000,d5
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer + $448).l,a0 ; packed map offset
                jsr     (WriteNametable).w
; shared portrait panel tiles -> VRAM $B000, drawn 12x14 at (2,5), base $580
                lea     (RiderIntro_PortraitPanel).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
                move.l  #$B000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
                move.w  #$C,d0
                move.w  #$E,d1
                move.w  #2,d2
                move.w  #5,d3
                move.w  #$580,d4
                move.w  #$40,d6
                lea     (Menu_ram_FrameBuffer).l,a1
                lea     (Intro_ram_ImageBuffer + $168).l,a0 ; packed map offset
                jsr     (WriteNametableToBuffer).w
; negative money selects the shorter "GAME OVER" table
                move.l  (Menu_ram_MoneyPlayerA).l,d1
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_6534
                move.l  (Menu_ram_MoneyPlayerB).l,d1
.loc_6534:
                tst.l   d1
                bpl.w   .loc_6560
; cop portraits: money<0 table (5 cops x 2), else money>=0 table (5 cops x 4)
                lea     (RaceResults_CopTableNeg).l,a0
                move.l  a0,-(sp)
                jsr     (Rand_NextWord).l
; AND with the word at $000008: on 68000 that is the high half of the bus-error
; vector, which is $0000 in this ROM, so the random variant is always 0 (the
; second record of each negative-money pair is unreachable); the RNG still advances
                and.w   ($8).w,d0
                adda.w  d0,a0
; cop index is 1-based; *$10 = two 8-byte records per cop
                move.w  (Race_CopIndex).l,d0
                subq.w  #1,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
                bra.w   .loc_6582
.loc_6560:
                lea     (RaceResults_CopTablePos).l,a0
                move.l  a0,-(sp)
                jsr     (Rand_NextWord).l
                andi.w  #$18,d0 ; one of 4 variants (8-byte records)
                adda.w  d0,a0
; *$20 = four 8-byte records per cop
                move.w  (Race_CopIndex).l,d0
                subq.w  #1,d0
                mulu.w  #$20,d0
                adda.w  d0,a0
.loc_6582:
                move.l  (a0),-(sp)
; record layout: (a0)=quote pointer, 4(a0)=portrait pointer. The portrait is
; preceded by an 8-byte prefix: even bytes = compressed size, odd bytes = the
; pointer to its descriptor (rebuild big-endian below)
                movea.l 4(a0),a3
                move.b  -7(a3),d0
                lsl.l   #8,d0
                move.b  -5(a3),d0
                lsl.l   #8,d0
                move.b  -3(a3),d0
                lsl.l   #8,d0
                move.b  -1(a3),d0
; push the descriptor pointer so the three offsets can be read later
                move.l  d0,-(sp)
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
                move.l  #$C000,d0
                movea.l (sp),a0
; descriptor -6 = signed word offset of the tile data in the staging buffer
                movea.w -6(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     (WriteTilesetToVRAM).l
                move.w  #$A,d0
                move.w  #$C,d1
                move.w  #3,d2
                move.w  #6,d3
                move.w  #$600,d4
                move.w  #$40,d6
; descriptor -4 = nametable offset; +4 skips the width/height pair
                movea.l (sp),a0
                movea.w -4(a0),a0
                adda.l  #Intro_ram_ImageBuffer + $4,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w
; descriptor -2 = palette offset
                movea.l (sp),a0
                movea.w -2(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l (Global_ram_PalettePtr).l,a1
                move.w  #7,d0
.loc_6608:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_6608
                move.w  #7,d0
.loc_6612:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_6612
                move.w  #7,d0
.loc_661C:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_661C
                move.w  #7,d0
.loc_6626:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_6626
; descriptor -10 = pointer to the name descriptor; +6 skips its header,
; leaving the 10-char space-padded rider name
                movea.l (sp)+,a0
                movea.l -$A(a0),a0
                addq.w  #6,a0
                lea     (Menu_ram_TempString).l,a1
                move.w  #$13,(a1)+
                move.w  #3,(a1)+
                move.w  #1,(a1)+
                move.w  #$A,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; center the 10-char name: count trailing spaces, subtract leading spaces,
; halve the surplus and right-rotate that many bytes (same as rider_intro)
                clr.w   d0
                movea.l a1,a0
.loc_6654:
                cmpi.b  #$20,-(a0)
                bne.w   .loc_6660
                addq.w  #1,d0
                bra.s   .loc_6654
.loc_6660:
                lea     -$A(a1),a0
.loc_6664:
                cmpi.b  #$20,(a0)+
                bne.w   .loc_6670
                subq.w  #1,d0
                bra.s   .loc_6664
.loc_6670:
                asr.w   #1,d0
                ble.w   .loc_66BA
                subq.w  #1,d0
                lea     -$A(a1),a0
.loc_667C:
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
                dbf     d0,.loc_667C
.loc_66BA:
                lea     (Menu_ram_TempString).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString
                lea     (Menu_ram_TempString).l,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
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
; quote y is halved and the stride doubled, giving rows 3,5,7,9
                move.w  (a0),d3
                asr.w   #1,d3
                move.w  #$6000,d4
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
; message: fine text or "Can't afford bail / GAME OVER"
                lea     (Message_StrCantAffordBail).w,a0
                movea.l (sp)+,a1 ; recover the table base pushed at selection
                cmpa.l  #RaceResults_CopTableNeg,a1
                beq.w   .loc_6776 ; negative-money path -> GAME OVER text
                lea     (Message_StrCaughtByCops).w,a0
                lea     (Menu_ram_TempString).l,a1
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; append the whole message record: -4 = width, -2 = height, dbf count - 1
                move.w  -2(a0),d0
                mulu.w  -4(a0),d0
                subq.w  #1,d0
.loc_6758:
                move.b  (a0)+,(a1)+
                dbf     d0,.loc_6758
                clr.l   d0
                move.w  (RaceResults_ram_Amount).l,d0
                lea     -2(a1),a0
                jsr     (Race_FormatNumber).l
                lea     (Menu_ram_TempString).l,a0
.loc_6776:
                move.l  a0,-(sp)
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString
                movea.l (sp)+,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function RaceResults_DrawBusted

; *************************************************
; Function RaceResults_DrawRepair
; Bike-repair layout: panel, portrait/quote by player level, repair cost or GAME OVER.
; In:  Menu_ram_PlayerLevel, Menu_ram_MoneyPlayerA/B, RaceResults_ram_Amount (repair cost)
; Notes: same portrait path as DrawBusted, but without a title and indexed by
;        the player level instead of the cop index.
; Out: Menu_ram_FrameBuffer portrait/name/quote/message; VRAM $B000/$C000
; Clobbers: d0-d7, a0-a3
; *************************************************

RaceResults_DrawRepair:
; record the active draw routine (write-only in this disassembly)
                move.l  #RaceResults_DrawRepair,(RaceResults_ram_DrawRoutine).l
; shared portrait panel tiles -> VRAM $B000, drawn 12x14 at (2,5), base $580
                lea     (RiderIntro_PortraitPanel).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
                move.l  #$B000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
                move.w  #$C,d0
                move.w  #$E,d1
                move.w  #2,d2
                move.w  #5,d3
                move.w  #$580,d4
                move.w  #$40,d6
                lea     (Menu_ram_FrameBuffer).l,a1
                lea     (Intro_ram_ImageBuffer + $168).l,a0 ; packed map offset
                jsr     (WriteNametableToBuffer).w
; negative money selects the shorter "GAME OVER" table
                move.l  (Menu_ram_MoneyPlayerA).l,d1
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_6818
                move.l  (Menu_ram_MoneyPlayerB).l,d1
.loc_6818:
                tst.l   d1
                bpl.w   .loc_6844
; level portraits: money<0 table (5x2), else money>=0 table (5x4)
                lea     (RaceResults_LevelTableNeg).l,a0
                move.l  a0,-(sp)
                jsr     (Rand_NextWord).l
; AND with the word at $000008 (bus-error vector high half) = 0 in this ROM:
; the random variant is forced to 0, so only the first record of each level pair
; is used; the RNG call is kept for its side effect
                and.w   ($8).w,d0
                adda.w  d0,a0
; level is 1-based; *$10 = two 8-byte records per level
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
                bra.w   .loc_6866
.loc_6844:
                lea     (RaceResults_LevelTablePos).l,a0
                move.l  a0,-(sp)
                jsr     (Rand_NextWord).l
                andi.w  #$18,d0 ; one of 4 variants (8-byte records)
                adda.w  d0,a0
; *$20 = four 8-byte records per level
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                mulu.w  #$20,d0
                adda.w  d0,a0
.loc_6866:
                move.l  (a0),-(sp)
; record layout: (a0)=quote pointer, 4(a0)=portrait pointer. The portrait is
; preceded by an 8-byte prefix: even bytes = compressed size, odd bytes = the
; pointer to its descriptor (rebuild big-endian below)
                movea.l 4(a0),a3
                move.b  -7(a3),d0
                lsl.l   #8,d0
                move.b  -5(a3),d0
                lsl.l   #8,d0
                move.b  -3(a3),d0
                lsl.l   #8,d0
                move.b  -1(a3),d0
; push the descriptor pointer so the three offsets can be read later
                move.l  d0,-(sp)
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
                move.l  #$C000,d0
                movea.l (sp),a0
; descriptor -6 = signed word offset of the tile data in the staging buffer
                movea.w -6(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     (WriteTilesetToVRAM).l
                move.w  #$A,d0
                move.w  #$C,d1
                move.w  #3,d2
                move.w  #6,d3
                move.w  #$600,d4
                move.w  #$40,d6
; descriptor -4 = nametable offset; +4 skips the width/height pair
                movea.l (sp),a0
                movea.w -4(a0),a0
                adda.l  #Intro_ram_ImageBuffer + $4,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w
; descriptor -2 = palette offset
                movea.l (sp),a0
                movea.w -2(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l (Global_ram_PalettePtr).l,a1
                move.w  #7,d0
.loc_68EC:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_68EC
                move.w  #7,d0
.loc_68F6:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_68F6
                move.w  #7,d0
.loc_6900:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_6900
                move.w  #7,d0
.loc_690A:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_690A
; descriptor -10 = pointer to the name descriptor; +6 skips its header,
; leaving the 10-char space-padded rider name
                movea.l (sp)+,a0
                movea.l -$A(a0),a0
                addq.w  #6,a0
                lea     (Menu_ram_TempString).l,a1
                move.w  #$13,(a1)+
                move.w  #3,(a1)+
                move.w  #1,(a1)+
                move.w  #$A,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; center the 10-char name: count trailing spaces, subtract leading spaces,
; halve the surplus and right-rotate that many bytes (same as rider_intro)
                clr.w   d0
                movea.l a1,a0
.loc_6938:
                cmpi.b  #$20,-(a0)
                bne.w   .loc_6944
                addq.w  #1,d0
                bra.s   .loc_6938
.loc_6944:
                lea     -$A(a1),a0
.loc_6948:
                cmpi.b  #$20,(a0)+
                bne.w   .loc_6954
                subq.w  #1,d0
                bra.s   .loc_6948
.loc_6954:
                asr.w   #1,d0
                ble.w   .loc_699E
                subq.w  #1,d0
                lea     -$A(a1),a0
.loc_6960:
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
                dbf     d0,.loc_6960
.loc_699E:
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
; quote y is halved and the stride doubled, giving rows 3,5,7,9
                move.w  (a0),d3
                asr.w   #1,d3
                move.w  #$6000,d4
                move.w  #$80,d6
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
; message: repair text or "No money for repairs / GAME OVER"
                lea     (Message_StrNoMoneyForRepairs).w,a0
                movea.l (sp)+,a1 ; recover the table base pushed at selection
                cmpa.l  #RaceResults_LevelTableNeg,a1
                beq.w   .loc_6A5A ; negative-money path -> GAME OVER text
                lea     (Message_StrBikeNeedsRepairs).w,a0
                lea     (Menu_ram_TempString).l,a1
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; append the whole message record: -4 = width, -2 = height, dbf count - 1
                move.w  -2(a0),d0
                mulu.w  -4(a0),d0
                subq.w  #1,d0
.loc_6A3C:
                move.b  (a0)+,(a1)+
                dbf     d0,.loc_6A3C
                clr.l   d0
                move.w  (RaceResults_ram_Amount).l,d0
                lea     -2(a1),a0
                jsr     (Race_FormatNumber).l
                lea     (Menu_ram_TempString).l,a0
.loc_6A5A:
                move.l  a0,-(sp)
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString
                movea.l (sp)+,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function RaceResults_DrawRepair

; *************************************************
; Function RaceResults_GameTick
; Per-frame update: DMA, Start exits, A -> high score, C -> shop, B -> cash box;
; cycle the outcome messages; end when a next-screen pointer is set.
; Notes: Start is tested while held (GetInput returns 1 = pressed), so a Start
;        still held from the previous screen exits at once. A/B/C use the
;        new-press edge (previous xor current) & current.
; In:  pad input, RaceResults_ram_Outcome, Menu_ram_CurrentMessageId/NextMessageTimer
; Out: RaceResults_ram_NextFunction (next screen), ram_UpdateFunction=0 at end stage
; Clobbers: d0/d1/a0
; *************************************************

RaceResults_GameTick:
; push the window frame buffer every frame
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     (DmaWriteVRAM).l

; pad A: save the old state, store the new one, and compute changed = old xor
; new for A/B/C; d0 still holds the current input, so bit 7 tests Start held
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerA).l
                andi.w  #$80,d0
                bne.w   .endStage ; Start held on pad A
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerB).l
                andi.w  #$80,d0
                bne.w   .endStage ; Start held on pad B
; A/B/C on pad B: (previous xor current) & current = new-press edge; the
; handler reads the pointer left in Menu_ram_CurrentButtonsPtr
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d0
                beq.w   .loc_6B0C
                and.w   (MainMenu_ram_ButtonsPlayerB).l,d0
                beq.w   .loc_6B0C
                move.l  #MainMenu_ram_ButtonsPlayerB,(Menu_ram_CurrentButtonsPtr).l
                jsr     (RaceResults_HandleInput).l
.loc_6B0C:
; pad A is checked after pad B; if both fire, both handlers run (C wins the
; next-screen pointer because HandleInput writes it last)
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d0
                beq.w   .showMessage
                and.w   (MainMenu_ram_ButtonsPlayerA).l,d0
                beq.w   .showMessage
                move.l  #MainMenu_ram_ButtonsPlayerA,(Menu_ram_CurrentButtonsPtr).l
                jsr     (RaceResults_HandleInput).l
.showMessage:
; advance the message every 300 frames (5 s); a positive blink timer hides the
; text for the first 30 frames of each new message. CurrentMessageId is a byte
; offset into Message_MsgArray (8 bytes per entry)
                subq.w  #1,(Menu_ram_MessageBlinkTimer).l
                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .loc_6BA8
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #300,(Menu_ram_NextMessageTimer).l ; 5 seconds
                addq.w  #8,(Menu_ram_CurrentMessageId).l
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0
; $FFFFFFFF text pointer marks the group terminator: loop back to the group
; start instead of advancing; the starts are byte offsets 8*21, 8*28, 8*35
                cmpa.l  #$FFFFFFFF,a0
                bne.w   .loc_6BA8
                tst.w   (RaceResults_ram_Outcome).l
                beq.w   .loc_6B9C
                cmpi.w  #4,(RaceResults_ram_Outcome).l
                bne.w   .loc_6B90
                move.w  #$118,(Menu_ram_CurrentMessageId).l ; 8*35 (level clear)
                bra.w   .loc_6BA8
.loc_6B90:
                move.w  #$E0,(Menu_ram_CurrentMessageId).l ; 8*28 (worse than 4th)
                bra.w   .loc_6BA8
.loc_6B9C:
                move.w  #$A8,(Menu_ram_CurrentMessageId).l ; 8*21 (incomplete)
                bra.w   .loc_6BA8
.loc_6BA8:
                bsr.w   Menu_ShowMessage
; leaving the screen: a next-screen pointer was installed by HandleInput
                cmpi.l  #0,(RaceResults_ram_NextFunction).l
                bne.w   .endStage
.loc_6BBA:
                jsr     (Audio_Update).l
                rts
.endStage:
                jsr     (Audio_StopMusic).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .loc_6BBA ; still run Audio_Update once on the exit frame
; End of function RaceResults_GameTick

; *************************************************
; Function RaceResults_HandleInput
; Handles A (high score), B (show cash/password for 25 s) and C (shop).
; In:  d0 - current buttons (SACBRLDU; 1 = pressed)
; Out: RaceResults_ram_NextFunction and the message timers/IDs on action
; Clobbers: -
; Notes: only the low byte is stored. A sets the high-score pointer, B selects
;        the status message group, C sets the shop pointer last, so C wins if
;        several buttons arrive in the same frame.
; *************************************************

RaceResults_HandleInput:
                move.b  d0,(RaceResults_ram_CurrentButtons).l ; keep the pad byte
                btst    #6,(RaceResults_ram_CurrentButtons).l ; bit 6 = A
                beq.w   .checkB
                move.l  #HighScore_Init,(RaceResults_ram_NextFunction).l ; A -> high scores
.checkB:
                btst    #4,(RaceResults_ram_CurrentButtons).l ; bit 4 = B
                beq.w   .loc_6C46
                move.w  #$1E,(Menu_ram_MessageBlinkTimer).l ; hide text for 30 frames
                move.w  #1500,(Menu_ram_NextMessageTimer).l ; status shown for 25 s
                tst.w   (RaceResults_ram_Outcome).l
                beq.w   .loc_6C3A
                cmpi.w  #4,(RaceResults_ram_Outcome).l
                bne.w   .loc_6C2E
                move.w  #(8*35),(Menu_ram_CurrentMessageId).l ; level clear group
                bra.w   .loc_6C46
.loc_6C2E:
                move.w  #(8*28),(Menu_ram_CurrentMessageId).l ; worse-than-4th group
                bra.w   .loc_6C46
.loc_6C3A:
                move.w  #(8*21),(Menu_ram_CurrentMessageId).l ; incomplete group
                bra.w   .loc_6C46
.loc_6C46:
                btst    #5,(RaceResults_ram_CurrentButtons).l ; bit 5 = C
                beq.w   .return
                move.l  #Shop_Init,(RaceResults_ram_NextFunction).l ; C -> bike shop
.return:
                rts
; End of function RaceResults_HandleInput

; dead: no callers [static]; the shop has its own Shop_DrawString. Kept for
; the byte-exact layout. Arguments match the other draw helpers: a0 = record.
; *************************************************
; Function DrawString
; Encodes and draws a string into the 64-wide frame buffer, palette 3.
; In:  a0 - string header + text
; Out: Menu_ram_FrameBuffer
; Clobbers: d0-d4/d6/a0/a1
; *************************************************

DrawString:
                move.l  a0,-(sp)
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString

                movea.l (sp)+,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; base tile index = 0, palette line = 3
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
                rts
; End of function DrawString

; dead: unreferenced [static]; byte-identical to endlevel.asm $8C96. Record
; layout is the usual (y,x,height,width) header plus 5x20 text; the amount is
; left blank, so this looks like an older 'not enough money' message.
RaceResults_StrNextLevelShort:
    dc.w 22,16,5,20
    dc.b " To go to the next  "
    dc.b "                    "
    dc.b " level, you need to "
    dc.b "                    "
    dc.b "  earn        more. "

; dead: unreferenced [static]; duplicate of endlevel.asm $8D02. The 20 bytes
; are ASCII with bit 7 set: XOR $80 -> "You aren't ready for". EncodeString maps
; bytes >= $80 to spaces, so this is not usable as a plain text record.
RaceResults_StrNotReadyEncoded:
    dc.b $D9, $EF, $F5, $A0, $E1, $F2, $E5, $EE
    dc.b $A7, $F4, $A0, $F2, $E5, $E1, $E4, $F9
    dc.b $A0, $E6, $EF, $F2

; dead: unreferenced [static]; plain-text continuation of the previous block,
; duplicate of endlevel.asm $8D16
RaceResults_StrNotReadyTail:
    dc.b "the next level yet.   You need to earn      $12345 more.    "

; dead: unreferenced [static]; 3x16 record with a level digit placeholder,
; duplicate of endlevel.asm $8D52
RaceResults_StrContinuePlay:
    dc.w 23,12,3,16
    dc.b "Continue play at"
    dc.b "                "
    dc.b " Current level 0"

; dead: unreferenced [static]; 3x16 record with a level digit placeholder,
; duplicate of endlevel.asm $8D8A
RaceResults_StrNextLevel:
    dc.w 23,12,3,16
    dc.b " The next level "
    dc.b "                "
    dc.b " will be level 0"
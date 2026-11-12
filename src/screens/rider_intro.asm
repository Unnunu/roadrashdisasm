; *************************************************
; rider_intro.asm - pre-race rider/opponent introduction
; ROM range: $59C4-$5F27
; Status:    line-by-line analyzed (static; rendering dynamically TODO)
; API:       RiderIntro_Init, RiderIntro_GameTick
; *************************************************

; *************************************************
; Function RiderIntro_Init
; Builds the rider/opponent intro: VDP setup, background/gamepad/portrait, opponent
; record (RiderIntro_RecordTable), name/quote/palette, optional bike overlay, font, message, DMA.
; In:  Menu_ram_Player, PlayerA/BLevel, CurrentTrackId, ram_FF0520 (extra field)
; Out: Menu_ram_FrameBuffer -> VRAM $7000; VRAM $A000-$D000 assets; palette
; Clobbers: d0-d7, a0-a3
; Notes: ROM $0059C4-$005E65. Only reached on the non-demo path
;        (top_level.asm $7E782). Three opponent-record pointers (name header,
;        quote, image) are kept on the stack while the portrait is decoded.
; *************************************************

RiderIntro_Init:
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
; SAT and H-scroll share $6000; 4 longs (16 bytes) clear sprite entries 0-1
; (link 0 terminates the list) and H-scroll entries 0-3. H-scroll is in
; full-screen mode, so entry 0 is the only one that matters.
                VDP_VRAM_WRITE $6000, (a0) ; HScroll
                move.w  #3,d0
.loopClearHScroll:
                move.l  #0,(VdpData).l
                dbf     d0,.loopClearHScroll
                VDP_VSRAM_WRITE $0, (a0)
                move.l  #0,(VdpData).l
; clear tile $7FF at $FFE0: 8 longs = 32 bytes = one 4bpp 8x8 tile
                movea.l #VdpData,a0
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
.loopDefaultTile:
                move.l  #0,(a0)
                dbf     d0,.loopDefaultTile
; fill the visible 28 rows of the shared 128x32 plane with tile $7FF
; (palette 0, low priority, no flips); $700 longs = $E00 words = 128*28 cells
                VDP_VRAM_WRITE $4000,VdpCtrl
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1 ; $07FF07FF = two cells per long
                move.w  #$6FF,d0 ; inclusive count -> $700 longs
.loopClearAB:
                move.l  d1,(a0)
                dbf     d0,.loopClearAB
; load the main-menu background image into the staging buffer
                lea     (img_MainMenu_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; Decompress the tiles to VRAM $4000. Quirk: the nametable below uses base tile
; $400 ($8000), so the visible tiles are the ones Menu_Init left at $8000; this
; $4000 copy is immediately overwritten by the following WriteNametable.
                move.l  #$4000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
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
                jsr     (WriteTilesetToVRAM).l
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
; clear the 64x28 window frame buffer: $380 longs = $E00 bytes, tile $7FF
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
                jsr     (WriteTilesetToVRAM).l

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
                jsr     (Rand_NextWord).l
                andi.w  #$18,d0
                cmp.w   #$18,d0
                beq.s   .loc_5BAA

                tst.w   d0
                bne.w   .loc_5BEC
                tst.w   (ram_FF0520).l
                ble.w   .loc_5BEC
                move.w  #$18,d0
.loc_5BEC:
; RiderIntro_RecordTable = [5 levels][5 tracks][4 variants] of 8-byte
; (quote_ptr, image_ptr) records; d0 already selects the variant (0/8/$10/$18)
                lea     (RiderIntro_RecordTable).l,a0
                adda.w  d0,a0
; level is 1-based -> (level-1) * 5 tracks * 4 variants * 8 bytes = (level-1)*$A0
                move.w  (Menu_ram_PlayerALevel).l,d0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_5C0A
                move.w  (Menu_ram_PlayerBLevel).l,d0 ; player B
.loc_5C0A:
                subq.w  #1,d0
                mulu.w  #$A0,d0
                adda.w  d0,a0
; CurrentTrackId is even (0,2,4,6,8); *$10 gives $20 (4 variants) per real track
                move.w  (Menu_ram_CurrentTrackId).l,d0
                mulu.w  #$10,d0
                adda.w  d0,a0
; record: (a0)=quote, 4(a0)=image. The image is preceded by an 8-byte prefix:
; even bytes = compressed size, odd bytes = pointer to the 10-byte image header.
; Push image, quote, then header pointer so later stages can pop them in order.
                movea.l 4(a0),a3 ; get character image
                move.l  a3,-(sp)
                move.l  (a0),-(sp) ; get character quote
; rebuild the big-endian header pointer from the four odd prefix bytes
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

; write the portrait tiles: header -6 = signed word offset of the image data in
; the decompressed staging buffer; destination $C000 (base tile $600)
                move.l  #$C000,d0 ; character image VRAM address
                movea.l (sp),a0
                movea.w -6(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     (WriteTilesetToVRAM).l
; draw the 10x12 portrait at (3,6); header -4 points at the (width,height) pair,
; +4 skips it to the packed nametable
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
; header -2 = signed word offset of the palette. Copy 4 palette lines,
; 4 * 8 longs = 128 bytes = 64 colours, to the global palette.
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

; header -10 = long pointer to the name descriptor; +6 skips the descriptor
; (the following 10 bytes are the space-padded rider name)
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

; center the name in its fixed 10-character field: d0 = trailing spaces, then
; subtract leading spaces, halve the surplus and move that many spaces from the
; end to the front (one right-rotation per iteration); <= 0 -> no shift.
                clr.w   d0
                movea.l a1,a0
.loc_5CF2:                       ; count trailing spaces backwards from the end
                cmpi.b  #$20,-(a0)
                bne.w   .loc_5CFE
                addq.w  #1,d0
                bra.s   .loc_5CF2

.loc_5CFE:
                lea     -$A(a1),a0

.loc_5D02:                       ; cancel the leading spaces against that count
                cmpi.b  #$20,(a0)+
                bne.w   .loc_5D0E
                subq.w  #1,d0
                bra.s   .loc_5D02

.loc_5D0E:
                asr.w   #1,d0 ; half of (trailing - leading)
                ble.w   .loc_5D58
                subq.w  #1,d0
                lea     -$A(a1),a0

.loc_5D1A:                       ; right-rotate the 10 bytes by one (last -> first)
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
; encode the centered name and draw it from the temporary record header
; (y=19, x=3, height=1, width=10) into the window frame buffer
                lea     (Menu_ram_TempString).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString

                lea     (Menu_ram_TempString).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3  ; y
                move.w  #$6000,d4 ; palette 3, font tile base 0
                move.w  #$40,d6 ; window plane width 64 cells
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer

; encode the quote (still on the stack), then pop its pointer and draw it from
; the quote header (y, x, height, width)
                movea.l (sp),a0
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString

                movea.l (sp)+,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3  ; y
                asr.w   #1,d3 ; destination row = header y / 2 ...
                move.w  #$6000,d4 ; palette 3, font tile base 0
                move.w  #$80,d6 ; ... with stride 128, giving double-spaced rows 3,5,7,9
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer

                move.l  (sp)+,d0 ; image pointer saved before the portrait decode
; @UNKNOWN(U-0008): exact identity of the overlay loaded below (Natasha's bike
; vs. another face/vehicle layer) | guess: Natasha's bike | next: render $D000
; in BlastEm with the extra field != 0.
; Natasha's default image with a non-zero extra field also shows the overlay
                cmp.l   #unk_AF902,d0
                bne.w   .loc_5E2C
                tst.w   (ram_FF0520).l
                ble.w   .loc_5E2C

                lea     (unk_B1506).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$D000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l

; draw the 6x7 overlay at (6,9), base tile $680 ($D000), window stride 64;
; the packed map starts at staging-buffer offset $548
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
; load the font used by the name, quote and message text; tile base 0 means
; the font tiles start at VRAM $0000
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l

; draw the initial blank message (Message_MsgArray index 18)
                bsr.w   Menu_ShowMessage

; push the 64x28 window buffer ($E00 bytes = $700 words) to VRAM $7000
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     (DmaWriteVRAM).l
                rts
; End of function RiderIntro_Init

; *************************************************
; Function RiderIntro_GameTick
; Per-frame update: push the frame buffer, detect a button release on pad A/B,
; advance the timed message, and exit to the race on the release or the message
; terminator.
; In:  pad input; Menu_ram_CurrentMessageId/NextMessageTimer
; Out: Race_ram_ActiveController (0/1) on exit; ram_UpdateFunction=0 at end stage
; Clobbers: d0-d2/a0
; Notes: ROM $005E66-$005F27. GetInput returns 1 = pressed, so a release edge is
;        previous raw & ~current raw.
; *************************************************

RiderIntro_GameTick:
; push the window buffer every frame
                move.l  #Menu_ram_FrameBuffer,d0
                move.w  #$7000,d1
                move.w  #$700,d2
                jsr     (DmaWriteVRAM).l

; Pad A: exit on a release edge (old & ~new) so the Start press that opened this
; screen, still held from the menu, is ignored. Save the old raw state first.
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
; Pad B is checked only when A had no release edge; A has priority.
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
; Reload 300 and fire when the down-counter goes negative, i.e. after 301 frames
; (~5 s at 60 Hz). CurrentMessageId is a byte offset: 8 bytes per Message_MsgArray
; entry (text pointer, show function). Start at 8*18 (blank), then +8 to index 19
; (press-start prompt) and index 20 (terminator, text pointer $FFFFFFFF).
                subq.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .loc_5F0A
                move.w  #300,(Menu_ram_NextMessageTimer).l
                addq.w  #8,(Menu_ram_CurrentMessageId).l
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).w,a0
                movea.l (a0,d0.w),a0 ; text pointer for this message entry
                cmpa.l  #$FFFFFFFF,a0 ; $FFFFFFFF text pointer = group terminator
                beq.w   .endStage

.loc_5F0A:
                bsr.w   Menu_ShowMessage

.loc_5F0E:
                jsr     (Audio_Update).l
                rts
; exit stage: stop the music, clear the per-frame stage callback installed by
; top_level, then fall through to Audio_Update for this frame
.endStage:
                jsr     (Audio_StopMusic).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .loc_5F0E
; End of function RiderIntro_GameTick
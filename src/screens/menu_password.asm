; *************************************************
; menu_password.asm - password entry/edit screen and password checksum
; ROM range: $2446-$33FF
; Status:    analyzed (password format/checksum reimplemented)
; API:       MenuPassword_GameTick, ValidatePassword, ParsePassword, CreatePassword
; *************************************************
;
; Password data format (24 characters arranged as 2 rows of 12)
;
; The player name/password strings are text records with the same header used by
; EncodeString/DecodeString:
;   +$00 y, +$02 x, +$04 height, +$06 width, +$08.. height*width ASCII bytes.
; Names are 1x10, passwords are 2x12. EncodeString maps every ASCII byte through
; dStringCodeTable to a font tile index (0..49); the checksum and the parser work
; on those tile indices, not on the ASCII bytes. Below, w[i] is character i of the
; 24-character password in row-major order (row 0 = w0..w11, row 1 = w12..w23).
;
;   w0..w4   race places 0..4             low nibble; 0 = no recorded place
;   w5..w6   separator spaces             not editable, not in the checksum
;   w7..w10  20-bit value, unknown unit   5 bits each, w7 holds bits 19..15
;                                         (@UNKNOWN(U-0005))
;   w11..w16 24-bit signed money          six nibbles, MSB first; each nibble is
;                                         stored as (nibble << 1) so bit0 is free
;                                         for a hidden checksum bit
;   w17..w18 separator spaces             not editable, not in the checksum
;   w19      level (3 bits)
;   w20      bits 0..2 bike id, bits 3..4 extra (ram_FF0522/ram_FF0524;
;            meaning @UNKNOWN(U-0004))
;   w21..w23 checksum characters
;
; Checksum (MenuPassword_ValidatePassword, tile indices, not raw values):
;   sum  = w0+w1+w2+w3+w4 + w7+w8+w9+w10 + (w11..w16 & ~1) + w19+w20
;   mask = (w11&1) | (w12&1)<<1 | (w13&1)<<2 | (w14&1)<<3 | (w15&1)<<4 | (w16&1)<<5
;   valid when (sum & $3F) == mask
;         and (w21 ^ w22 ^ w23) & $1F == 0
;         and w21 == (w7+w8+w9+w10+w11) & $1F
;         and w22 == (w12+w13+w14+w15+w16) & $1F
; w23 is therefore always w21 ^ w22. CreatePassword reverses the whole scheme:
; it writes the data fields, patches bit0 of w11..w16 from the six low bits of
; sum, writes w21..w23 and decodes the words back to characters.
;
; Coordinate note: EncodeString/DecodeString take the count from the record
; header, so a corrupt width/height would overrun; callers always pass the
; 1x10 name and 2x12 password records.
; *************************************************

Menu_DefaultPassword:
; 24-character template ("01234  56789" / "01234  56789"). It does not pass
; the checksum: sum & $3F = 63, mask = 21. It is only the initial
; on-screen text and is replaced by CreatePassword or by a valid entered code.
    dc.b "01234  5678901234  56789"

Menu_DefaultName:
; 10-character initial player name; Intro_InitPlayerA/B copy it into both name
; records and change the 'A' to 'B' for player B.
    dc.b "Player A  "

unk_2468:
; Dead data: a 5x20 text block (" password accepted ... Players: ... Level: ...")
; with no static pointer reference in the ROM (no 32-bit address points here).
; It looks like an older password-accepted/status template; retained because
; the build must stay byte-exact.
    dc.b " password accepted                      Players: 0          Level: 0                                "

; *************************************************
; Function MenuPassword_GameTick
; Password screen per-frame update: DMA the frame buffer, read pads, edit, exit.
; In:  Menu_ram_FrameBuffer - 64x28 nametable buffer
;      Menu_ram_CurrentButtonsPtr/ChangedButtonsPtr - active pad state/edge mask
; Out: -
; Clobbers: d0-d3/a0-a1 (the update callback may clobber all registers)
; Notes: ROM $0024CC-$00270F. Exits on Start release and installs
;        MainMenu_GameTick. The cursor cell is restored with palette 3 ($6000)
;        at the old CursorX/CursorY and then drawn with palette 0 at the new
;        position, so the same cell coordinates drive both passes.
;        Hold-repeat: any button change resets HoldTimer; a newly pressed
;        U/D/L/R/B/A starts a 30-frame delay, then HandleInput runs every 8
;        frames while the button stays down. C and Start never repeat.
;        Menu_ram_CurrentMessageId is a byte offset into Message_MsgArray (8
;        bytes/entry). The password screen starts at 96 (index 12, the first
;        password tooltip); every 240 frames it advances by 8 and wraps to 96
;        when the $FFFFFFFF group terminator is reached.
; *************************************************

MenuPassword_GameTick:
; copy framebuffer to VRAM: +$200 skips the 4 header rows, $600 words = 64x24.
; VRAM $7200 is window row 4 (window base $7000 + 4*64*2).
                move.l  #(Menu_ram_FrameBuffer + $200),d0
                move.w  #$7200,d1
                move.w  #$600,d2 ; size in words 64 x 24
                jsr     (DmaWriteVRAM).l
; get Player A buttons: Changed = old XOR new (both press and release edges)
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l ; save previous button state
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l ; get button state
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerA).l ; get changed buttons
; get Player B buttons
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerB).l
; Start is edge-sensitive on release: while Start is held, keep editing; when
; the changed mask has the Start bit (it cannot still be held here) leave.
                movea.l (Menu_ram_CurrentButtonsPtr).l,a0
                movea.l (Menu_ram_ChangedButtonsPtr).l,a1
                move.w  (a0),d0
                andi.w  #$80,d0 ; get pressed 'Start' bit
                bne.w   .drawCursor
                move.w  (a1),d0 ; get changed 'Start' bit
                andi.w  #$80,d0
                bne.w   .endStage ; jump if 'Start' was released
.drawCursor:
; Restore the previous cursor cell to palette 3 ($6000 = high byte $60). The
; value is identical for A and B, so the "player B" reload below is dead.
                move.w  #$6000,d0 ; tile index 0, palette 3
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_254A
                move.w  #$6000,d0 ; dead: same value as the player A branch
.loc_254A:
; Screen column = 4 (A) or 24 (B) + CursorX. For the name row CursorX is
; 1-based over the record, for password rows it is the 0-based char index.
                move.w  #4,d2
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_2560
                move.w  #24,d2 ; player B

.loc_2560:
                add.w   (MenuPassword_ram_CursorX).l,d2 ; x
                move.w  (MenuPassword_ram_CursorY).l,d3 ; y
                jsr     (MenuPassword_SetCursorPos).l

; Act on newly pressed buttons once per edge: current AND changed keeps only
; bits that are down now, i.e. press edges (release edges have current=0).
                movea.l (Menu_ram_CurrentButtonsPtr).l,a0
                movea.l (Menu_ram_ChangedButtonsPtr).l,a1
                move.w  (a1),d0
                beq.w   .loc_2590 ; jump if no buttons were pressed or released
                and.w   (a0),d0
                beq.w   .loc_2590 ; jump if no buttons were pressed in this frame
                jsr     (MenuPassword_HandleInput).l ; handle newly pressed buttons
.loc_2590:
; Hold-repeat state machine. Changed != 0 means an edge happened this frame:
; restart the delay and let the next frame decide whether to arm a repeat.
                movea.l (Menu_ram_CurrentButtonsPtr).l,a0
                movea.l (Menu_ram_ChangedButtonsPtr).l,a1
                tst.w   (a1)
                beq.w   .loc_25AA
                move.w  #0,(MenuPassword_ram_HoldTimer).l ; some button changed its state, reset hold timer
.loc_25AA:
                subq.w  #1,(MenuPassword_ram_HoldTimer).l
                bpl.w   .updateCursor ; still inside the delay
; Timer expired. If there were no edges this frame and a repeat is armed,
; re-run the action and reload the 8-frame repeat interval.
                move.w  #$FFFF,(MenuPassword_ram_HoldTimer).l
                tst.w   (a1)
                bne.w   .loc_25E4
                tst.w   (MenuPassword_ram_HeldButtons).l
                beq.w   .updateCursor
                move.w  #8,(MenuPassword_ram_HoldTimer).l
                move.w  (MenuPassword_ram_HeldButtons).l,d0
                jsr     (MenuPassword_HandleInput).l ; handle held buttons
                bra.w   .updateCursor
.loc_25E4:
; An edge happened: clear the armed repeat, then arm only a single newly
; pressed U/D/L/R/B/A ($01/$02/$04/$08/$10/$40). C ($20) and Start ($80) are
; intentionally absent, and a multi-button press does not repeat.
                clr.w   (MenuPassword_ram_HeldButtons).l
                move.w  (a0),d0
                and.w   (a1),d0
                beq.w   .updateCursor
                cmp.w   #1,d0
                beq.w   .loc_2626
                cmp.w   #2,d0
                beq.w   .loc_2626
                cmp.w   #4,d0
                beq.w   .loc_2626
                cmp.w   #8,d0
                beq.w   .loc_2626
                cmp.w   #$10,d0
                beq.w   .loc_2626
                cmp.w   #$40,d0
                beq.w   .loc_2626
                bra.w   .updateCursor

.loc_2626:
                move.w  #30,(MenuPassword_ram_HoldTimer).l
                move.w  d0,(MenuPassword_ram_HeldButtons).l

.updateCursor:
; Draw the cursor on the new position: high byte 0 selects palette 0 while the
; character tile (low byte) is left untouched. This runs after HandleInput, so
; the cell is already the new one (the top of the tick restored the old cell).
                move.w  #0,d0
                move.w  #4,d2
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_264E
                move.w  #24,d2 ; player B
.loc_264E:
                add.w   (MenuPassword_ram_CursorX).l,d2
                move.w  (MenuPassword_ram_CursorY).l,d3
                jsr     (MenuPassword_SetCursorPos).l

; Tooltip blink/advance: blink phase 30 frames, advance the tooltip every 240.
                subi.w  #1,(Menu_ram_MessageBlinkTimer).l
                subi.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .end
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
; CurrentMessageId is a byte offset (8 bytes per entry). If it ever falls below
; the password group (96 = index 12) snap it back; otherwise just advance.
                addi.w  #8,(Menu_ram_CurrentMessageId).l
                move.w  (Menu_ram_CurrentMessageId).l,d0
                cmpi.w  #(8*12),(Menu_ram_CurrentMessageId).l
                bpl.w   .loc_26A6
                move.w  #(8*12),(Menu_ram_CurrentMessageId).l
.loc_26A6:
; The text pointer at the current offset identifies the padding terminator
; ($FFFFFFFF): wrap back to the first password tooltip instead of advancing
; into the next screen's group. d0 was read before the sub-96 clamp above, so
; after a wrap it tests the stale entry for one frame (the id is already fixed).
                lea     (Message_MsgArray).l,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                bne.w   .end
                move.w  #(8*12),(Menu_ram_CurrentMessageId).l
.end:
                jsr     (Menu_ShowMessage).l
                jsr     (Audio_Update).l
                rts
.endStage:
; Start released: validate/apply the password, then rebuild the main menu.
                jsr     (MenuPassword_UpdateStatus).l
                jsr     (Menu_DrawPlayerInfo).l
; Clear rows 5..21 of the 64x28 frame buffer (17 rows = $220 longs) with the
; default tile $7FF in palette 3 ($67FF). This erases the password editing area.
                move.l  #$67FF67FF,d0
                lea     (Menu_ram_FrameBuffer + $280).l,a0
                move.w  #$21F,d1
.loc_26EC:
                move.l  d0,(a0)+
                dbf     d1,.loc_26EC

                move.w  (Menu_ram_CurrentTrackId).l,d0
                jsr     (Menu_DrawRaceSelection).l
                jsr     (Menu_DrawPlayerInfo).l
                move.l  #MainMenu_GameTick,(ram_UpdateFunction).l ; get to main menu
                bra.s   .end
; End of function MenuPassword_GameTick

; *************************************************
; Function MenuPassword_HandleInput
; Applies newly pressed/held buttons to the active name/password string.
; In:  d0 - current SACBRLDU buttons (low byte)
;      MenuPassword_ram_StrPlayerNamePtr/StrPlayerPasswordPtr - active strings
; Out: -
; Clobbers: d0-d2/a0-a1
; Notes: ROM $002710-$002A1D. A = previous glyph, B = next glyph in the
;        50-entry dStringDecodeTable alphabet, C = switch player, directions
;        move the cursor. The string records store ASCII bytes, so the edit
;        path decodes ASCII -> tile index (dStringCodeTable), steps the index,
;        then encodes tile index -> ASCII (dStringDecodeTable).
;        Cursor coordinates are screen offsets: column = 4 (A) / 24 (B) +
;        CursorX. The name row (Y=9) uses CursorX 1..10 and char index
;        CursorX-1 (its record starts at x=5); password rows (Y=15/16) use
;        CursorX 0..11 as the char index (record starts at x=4) and skip the
;        two separator columns 5 and 6.
; *************************************************

MenuPassword_HandleInput:
                move.b  d0,(MenuPassword_ram_CurrentButtons).l
                btst    #6,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkB
; A pressed: select the target string and compute char offset:
;   offset = 8 + (Y-15)*width + index   (name row is mapped to Y=15, index-1)
                movea.l (MenuPassword_ram_StrPlayerPasswordPtr).l,a0
                move.w  (MenuPassword_ram_CursorX).l,d1
                move.w  (MenuPassword_ram_CursorY).l,d2
                cmp.w   #9,d2
                bne.w   .loc_2748
                move.w  #15,d2
                subq.w  #1,d1
                movea.l (MenuPassword_ram_StrPlayerNamePtr).l,a0
.loc_2748:
                subi.w  #15,d2
                mulu.w  6(a0),d2 ; row * width
                add.w   d1,d2
                addq.w  #8,d2 ; skip y/x/height/width
                lea     (a0,d2.w),a0
; ASCII -> tile index, then previous glyph (index-1, wrap 0 -> 49)
                clr.w   d2
                move.b  (a0),d2
                lea     (dStringCodeTable).w,a1
                asl.w   #1,d2 ; table is indexed by char*2
                move.w  (a1,d2.w),d2
                subq.b  #1,d2
                bpl.w   .loc_2770
                move.b  #$31,d2 ; 49 = last alphabet entry

.loc_2770:
; tile index -> ASCII, store back, redraw all four fields
                lea     (dStringDecodeTable).w,a1
                move.b  (a1,d2.w),(a0)
                jsr     (MenuPassword_DrawNamesAndPasswords).l

.checkB:
                btst    #4,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkC
; B pressed: same address calculation as A
                movea.l (MenuPassword_ram_StrPlayerPasswordPtr).l,a0
                move.w  (MenuPassword_ram_CursorX).l,d1
                move.w  (MenuPassword_ram_CursorY).l,d2
                cmp.w   #9,d2
                bne.w   .loc_27B0
                move.w  #$F,d2
                subq.w  #1,d1
                movea.l (MenuPassword_ram_StrPlayerNamePtr).l,a0

.loc_27B0:
                subi.w  #$F,d2
                mulu.w  6(a0),d2
                add.w   d1,d2
                addq.w  #8,d2
                adda.w  d2,a0
; ASCII -> tile index, then next glyph (index+1, wrap 49 -> 0)
                clr.w   d2
                move.b  (a0),d2
                lea     (dStringCodeTable).w,a1
                asl.w   #1,d2
                move.w  (a1,d2.w),d2
                addq.b  #1,d2
                cmp.b   #$31,d2
                ble.w   .loc_27DA
                move.b  #0,d2

.loc_27DA:
                lea     (dStringDecodeTable).w,a1
                move.b  (a1,d2.w),(a0)
                jsr     (MenuPassword_DrawNamesAndPasswords).l

.checkC:
                btst    #5,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkRight
; C pressed: first validate/apply what is currently on screen, then switch the
; active pointers and move the selection panel to the other player.
                jsr     (MenuPassword_UpdateStatus).l
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                bne.w   .loc_2830
; currently A -> select B; SwapPlayerBlocks(nonzero) targets the right block
                move.l  #MenuPassword_ram_StrPlayerBName,(MenuPassword_ram_StrPlayerNamePtr).l
                move.l  #MenuPassword_ram_StrPlayerBPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                move.w  #$FFFF,d0
                jsr     (MenuPassword_SwapPlayerBlocks).l
                jsr     (MenuPassword_DrawNamesAndPasswords).l
                bra.w   .checkRight
.loc_2830:
; currently B -> select A; SwapPlayerBlocks(0) targets the left block
                move.l  #MenuPassword_ram_StrPlayerAName,(MenuPassword_ram_StrPlayerNamePtr).l
                move.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                move.w  #0,d0
                jsr     (MenuPassword_SwapPlayerBlocks).l
                jsr     (MenuPassword_DrawNamesAndPasswords).l

.checkRight:
                btst    #3,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkLeft
; Right: name row wraps 10 -> 1; password row 4 -> 7 skips the two spaces and
; 11 -> 0 wraps. (5 and 6 are never reached, so they stay uneditable.)
                addq.w  #1,(MenuPassword_ram_CursorX).l
                cmpi.w  #9,(MenuPassword_ram_CursorY).l
                bne.w   .loc_288A
                cmpi.w  #$A,(MenuPassword_ram_CursorX).l
                ble.w   .checkLeft
                move.w  #1,(MenuPassword_ram_CursorX).l
                bra.w   .checkLeft

.loc_288A:
                cmpi.w  #5,(MenuPassword_ram_CursorX).l
                bne.w   .loc_28A2
                move.w  #7,(MenuPassword_ram_CursorX).l
                bra.w   .checkLeft

.loc_28A2:
                cmpi.w  #$C,(MenuPassword_ram_CursorX).l
                bmi.w   .checkLeft
                move.w  #0,(MenuPassword_ram_CursorX).l

.checkLeft:
                btst    #2,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkDown
; Left: name row wraps 1 -> 10; password row 0 -> 11 and 7 -> 4 skips back
; over the separator columns.
                cmpi.w  #9,(MenuPassword_ram_CursorY).l
                bne.w   .loc_28E4
                subq.w  #1,(MenuPassword_ram_CursorX).l
                bgt.w   .checkDown
                move.w  #10,(MenuPassword_ram_CursorX).l
                bra.w   .checkDown
.loc_28E4:
                subq.w  #1,(MenuPassword_ram_CursorX).l
                bpl.w   .loc_28FA
                move.w  #$B,(MenuPassword_ram_CursorX).l
                bra.w   .checkDown
.loc_28FA:
                cmpi.w  #6,(MenuPassword_ram_CursorX).l
                bne.w   .checkDown
                move.w  #4,(MenuPassword_ram_CursorX).l
.checkDown:
                btst    #1,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkUp
; Down: 9 -> 15 (enter password row 0), 15 -> 16; 16 is the last row.
; Column 5/6 would land on a password separator, so map 5 -> 4 and 6 -> 7.
                cmpi.w  #$10,(MenuPassword_ram_CursorY).l
                beq.w   .checkUp
                addq.w  #1,(MenuPassword_ram_CursorY).l
                cmpi.w  #$A,(MenuPassword_ram_CursorY).l
                bne.w   .checkUp
                move.w  #$F,(MenuPassword_ram_CursorY).l
                cmpi.w  #5,(MenuPassword_ram_CursorX).l
                bne.w   .loc_2958
                move.w  #4,(MenuPassword_ram_CursorX).l
                bra.w   .checkUp

.loc_2958:
                cmpi.w  #6,(MenuPassword_ram_CursorX).l
                bne.w   .checkUp
                move.w  #7,(MenuPassword_ram_CursorX).l
                bra.w   .checkUp

.checkUp:
                btst    #0,(MenuPassword_ram_CurrentButtons).l
                beq.w   .updatePasswordText
; Up: 15 -> 9 (back to the name row), 16 -> 15; 9 is the top row.
; Keep the same screen column: password X=0 -> name 1, X>10 -> 10.
                cmpi.w  #9,(MenuPassword_ram_CursorY).l
                beq.w   .updatePasswordText
                subq.w  #1,(MenuPassword_ram_CursorY).l
                cmpi.w  #$E,(MenuPassword_ram_CursorY).l
                bne.w   .updatePasswordText
                move.w  #9,(MenuPassword_ram_CursorY).l
                cmpi.w  #0,(MenuPassword_ram_CursorX).l
                bne.w   .loc_29BA
                move.w  #1,(MenuPassword_ram_CursorX).l
                bra.w   .updatePasswordText

.loc_29BA:
                cmpi.w  #$A,(MenuPassword_ram_CursorX).l
                ble.s   .checkUp
                move.w  #$A,(MenuPassword_ram_CursorX).l

.updatePasswordText:
; Redraw the active password after any direction press (the character was
; already redrawn by the A/B handlers, but the cursor may now reveal a cell).
                movea.l (MenuPassword_ram_StrPlayerPasswordPtr).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
                movea.l (MenuPassword_ram_StrPlayerPasswordPtr).l,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_2A06
                move.w  #$6000,d4 ; dead: same value as the player A branch
.loc_2A06:
                move.w  #$40,d6
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).l
                rts
; End of function MenuPassword_HandleInput

; *************************************************
; Function MenuPassword_UpdateStatus
; Updates the password status message, validates and applies the password.
; In:  active player name/password strings (pointers)
; Out: MenuPassword_StrPasswordStatus text, level display, CurrentMessageId
; Clobbers: d0-d2/a0-a2
; Notes: ROM $002A1E-$002B17. Selects Message_MsgArray index 5 (offset 40) and
;        fills the 5x16 status record from the MenuPassword_StrStatusTemplate record, then centers
;        the 10-character player name on its first row.
;        On a valid password ValidatePassword returns d0=0: the third row is
;        changed from "PASSWORD INVALID" to "PASSWORD   VALID" (three spaces
;        overwrite " IN") and row 4 from "OLD LEVEL IS: 0" to "NEW LEVEL IS: 0".
;        Only then is ParsePassword applied and the track re-selected.
;        The level digit is always refreshed from Menu_ram_PlayerA/BLevel as
;        ASCII '0'+level at row 4, column 14.
; *************************************************

MenuPassword_UpdateStatus:
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                move.w  #(8*5),(Menu_ram_CurrentMessageId).l ; show password status message (valid / invalid)
; Copy the full template record: header (y,x,height,width = 22,12,5,16) then
; its 5*16 = 80 characters.
                lea     (MenuPassword_StrPasswordStatus).l,a0
                lea     (MenuPassword_StrStatusTemplate).l,a1 ; string ".. password invalid .."
                lea     (MenuPassword_ram_StrPlayerAName + 6).l,a2 ; ptr to player A name width
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_2A5C
                lea     (MenuPassword_ram_StrPlayerBName + 6).l,a2 ; ptr to player B name width
.loc_2A5C:
                move.l  (a1)+,(a0)+ ; copy y & x
                move.l  (a1)+,(a0)+ ; copy height & width
                move.w  -4(a0),d0
                mulu.w  -2(a0),d0 ; get width * height

                subq.w  #1,d0
.loc_2A6A:
                move.b  (a1)+,(a0)+ ; copy chars
                dbf     d0,.loc_2A6A

; Center the name: text start + (status_width - name_width)/2. a2 points at the
; name width field; (a2)+ then walks the source name text.
                lea     (MenuPassword_StrPasswordStatus + 6).l,a0 ; ptr to width
                move.w  (a0)+,d0 ; get message width
                sub.w   (a2),d0
                asr.w   #1,d0
                adda.w  d0,a0
                move.w  (a2)+,d0
                subq.w  #1,d0
.loc_2A82:
                move.b  (a2)+,(a0)+
                dbf     d0,.loc_2A82

; Validate the active password. d1 = checksum sum (unused here).
                movea.l (MenuPassword_ram_StrPlayerPasswordPtr).l,a0
                jsr     (MenuPassword_ValidatePassword).l
                tst.w   d0
                bne.w   .loc_2AEC
; Valid: replace row 4's "OLD" with "NEW" at text+4*width.
                lea     (MenuPassword_StrPasswordStatus + 4).l,a0
                move.w  (a0)+,d0
                subq.w  #1,d0
                mulu.w  (a0)+,d0
                adda.w  d0,a0
                move.b  #'N',(a0)+
                move.b  #'E',(a0)+
                move.b  #'W',(a0)+
; Replace " IN" in row 2's "PASSWORD INVALID" with three spaces, leaving
; "PASSWORD   VALID" (text+width*2+8, i.e. the middle of the 16-wide row).
                lea     (MenuPassword_StrPasswordStatus + 4).l,a0
                move.w  (a0)+,d0
                mulu.w  (a0)+,d0
                asr.w   #1,d0
                adda.w  d0,a0
                move.b  #' ',(a0)+
                move.b  #' ',(a0)+
                move.b  #' ',(a0)+
; ParsePassword expects d0=0 for A, nonzero for B. SNE writes $00/$FF into the
; low byte; the high byte is already 0, so tst.w works.
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                sne     d0
                lea     (Intro_ram_ImageBuffer).l,a0 ; word array from ValidatePassword
                jsr     (MenuPassword_ParsePassword).l
                jsr     (MenuPassword_SelectCurrentTrack).l

.loc_2AEC:
; Always refresh the level display, valid or not ("OLD LEVEL" / "NEW LEVEL").
; offset = height*width - 2 = row 4, column 14, the '0' in "OLD LEVEL IS: 0 ".
                move.w  (Menu_ram_PlayerALevel).l,d1
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_2B06
                move.w  (Menu_ram_PlayerBLevel).l,d1

.loc_2B06:
                lea     (MenuPassword_StrPasswordStatus + 4).l,a0
                move.w  (a0)+,d0
                mulu.w  (a0)+,d0
                subq.w  #2,d0
                add.b   d1,(a0,d0.w)
                rts
; End of function MenuPassword_UpdateStatus

; *************************************************
; Function MenuPassword_SetCursorPos
; Draws/restores the cursor cell in the frame buffer.
; In:  d0 - high byte value ($6000 restores text palette 3, 0 draws cursor)
;      d2 - x, d3 - y
; Out: -
; Clobbers: d0/d2/d3/a0
; Notes: cell offset = y*128 + x*2 (64x28 frame buffer, 2 bytes/cell). Writes
;        only the high byte (palette/priority), so the character tile survives;
;        $6000 -> $60 (palette 3), 0 -> palette 0.
; *************************************************

MenuPassword_SetCursorPos:
                lea     (Menu_ram_FrameBuffer).l,a0
                mulu.w  #128,d3 ; bytes per row
                asl.w   #1,d2 ; bytes per cell in x
                add.w   d2,d3
                asr.w   #8,d0 ; keep the high byte (palette/priority)
                move.b  d0,(a0,d3.w)
                rts
; End of function MenuPassword_SetCursorPos

; *************************************************
; Function MenuPassword_SelectCurrentTrack
; Selects the current track from the player's race places.
; In:  Menu_ram_Player (0=A, nonzero=B), Menu_ram_PlayerA/BPlaces
; Out: d0 - Menu_ram_CurrentTrackId (0,2,4,6,8)
; Clobbers: d0/d1/a0
; Notes: ROM $002B2E-$002BED. The places array is 5 words; the even id is also
;        the byte offset into it (race_results/race_core use it that way).
;        The loop returns the first race whose place is 0 (not yet played);
;        if all five have a place it returns the race with the largest place
;        (worst finish). CMP/BPL skips on >=, so ties keep the earlier race.
;        d0 tracks the current maximum place, d1 its track id.
; *************************************************

MenuPassword_SelectCurrentTrack:
                lea     (Menu_ram_PlayerAPlaces).l,a0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_2B44
                lea     (Menu_ram_PlayerBPlaces).l,a0

.loc_2B44:
; Default candidate: race 1 (id 0). A zero place returns immediately.
                move.w  #0,(Menu_ram_CurrentTrackId).l
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  (a0),d0 ; get place in race 1
                beq.w   .loc_2BE6
                move.w  #2,(Menu_ram_CurrentTrackId).l
                tst.w   2(a0)
                beq.w   .loc_2BE6 ; race 2 unplayed -> select it
                cmp.w   2(a0),d0
                bpl.w   .loc_2B7A ; keep d0 when place1 >= place2
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  2(a0),d0

.loc_2B7A:
                move.w  #4,(Menu_ram_CurrentTrackId).l
                tst.w   4(a0)
                beq.w   .loc_2BE6 ; race 3 unplayed -> select it
                cmp.w   4(a0),d0
                bpl.w   .loc_2B9C
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  4(a0),d0

.loc_2B9C:
                move.w  #6,(Menu_ram_CurrentTrackId).l
                tst.w   6(a0)
                beq.w   .loc_2BE6 ; race 4 unplayed -> select it
                cmp.w   6(a0),d0
                bpl.w   .loc_2BBE
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  6(a0),d0

.loc_2BBE:
                move.w  #8,(Menu_ram_CurrentTrackId).l
                tst.w   8(a0)
                beq.w   .loc_2BE6 ; race 5 unplayed -> select it
                cmp.w   8(a0),d0
                bpl.w   .loc_2BE0
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  8(a0),d0

.loc_2BE0:
; All races played: d1 is the id of the worst (largest) place.
                move.w  d1,(Menu_ram_CurrentTrackId).l

.loc_2BE6:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                rts
; End of function MenuPassword_SelectCurrentTrack

; *************************************************
; Function MenuPassword_SwapPlayerBlocks
; Moves the active player's selection panel to the other side when switching.
; In:  d0 - 0 = switch to player A, non-zero = switch to player B
; Out: -
; Clobbers: d0-d2/a0-a1
; Notes: ROM $002BEE-$002C31. Swaps two 16-cell wide, 14-row panels (rows
;        5..18): left = FrameBuffer+$284 (x=2), right = FrameBuffer+$2AC (x=22);
;        8 longs per row, then +$60 to reach the same x on the next row.
;        The destination panel's top-left cell must be the blank space tile
;        ($6000 + space) or the whole swap is skipped. Only the newly selected
;        side carries the border, so this moves the border; the following
;        DrawNamesAndPasswords redraws both name/password fields at their fixed
;        positions.
; *************************************************

MenuPassword_SwapPlayerBlocks:
                lea     (Menu_ram_FrameBuffer + $280).l,a0 ; row 5
                movea.l a0,a1
                adda.w  #$2C,a0 ; x = 2 + 44/2 = 22 (right panel)
                addq.w  #4,a1 ; x = 2 (left panel)
                tst.w   d0
                beq.w   .loc_2C04 ; switch to A: check/swap the left panel
                exg     a0,a1 ; switch to B: a1 = right (destination) panel

.loc_2C04:
; Guard: only swap when the destination's first cell is blank (no border yet).
                move.w  (dStringCodeTable + 2 * ' ').w,d0
                ori.w   #$6000,d0 ; space tile, palette 3
                cmp.w   (a1),d0
                bne.w   .locret_2C30
                move.w  #$D,d1 ; 14 rows

.loc_2C16:
                move.w  #7,d0 ; 8 longs = 16 cells

.loc_2C1A:
                move.l  (a0),d2
                move.l  (a1),(a0)+
                move.l  d2,(a1)+
                dbf     d0,.loc_2C1A
                adda.w  #$60,a0 ; 32 bytes written + $60 = one 128-byte row
                adda.w  #$60,a1
                dbf     d1,.loc_2C16

.locret_2C30:
                rts
; End of function MenuPassword_SwapPlayerBlocks

; *************************************************
; Function MenuPassword_ValidatePassword
; Verifies the 24-character password checksum.
; In:  a0 - password string record (header + 24 chars)
; Out: d0 - 0 = valid, non-zero = invalid; d1 - checksum sum
; Clobbers: d0-d3/a0-a1
; Notes: ROM $002C32-$002D1D. Encodes the string into 24 tile-index words in
;        Intro_ram_ImageBuffer (w[0..23], see the file header for the layout)
;        and applies the four checks described there:
;          (sum & $3F) == mask, mask = bit0 of w11..w16 packed w11 as bit0;
;          (w21 ^ w22 ^ w23) & $1F == 0;
;          w21 == (w7+w8+w9+w10+w11) & $1F;
;          w22 == (w12+w13+w14+w15+w16) & $1F.
;        The ROXR.B trick collects the LSBs: after six rotations bit7..bit2 hold
;        w11..w16, and LSR.W #2 moves them to bits 5..0 with w11 in bit0.
;        The `move.w #$FFFF,d0` below is dead: d0 is overwritten by the
;        `move.w d1,d0` before its first use.
; *************************************************

MenuPassword_ValidatePassword:
; convert string to word array
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w

                lea     (Intro_ram_ImageBuffer).l,a0 ; 24 chars, two lines of 12 chars
                move.w  #$FFFF,d0 ; dead: d0 is overwritten by "move.w d1,d0"
                move.w  #0,d1 ; sum
                move.w  #0,d2 ; packed low-bit mask
; sum w0..w4 (race places)
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
; skip w5,w6 (separator spaces)
                addq.w  #4,a0
; add w7..w10 (progress)
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
; Money w11..w16: add (char & ~1) to the sum and accumulate bit0 into d2.
; ASR shifts the LSB into X; ROXR.B rotates it into d2 from the top.
                move.w  (a0)+,d3
                asr.w   #1,d3
                roxr.b  #1,d2
                lsl.w   #1,d3 ; d3 = w11 & ~1
                add.w   d3,d1
; repeat this for the other 5 money chars (w12..w16)
                move.w  (a0)+,d3
                asr.w   #1,d3
                roxr.b  #1,d2
                lsl.w   #1,d3
                add.w   d3,d1

                move.w  (a0)+,d3
                asr.w   #1,d3
                roxr.b  #1,d2
                lsl.w   #1,d3
                add.w   d3,d1

                move.w  (a0)+,d3
                asr.w   #1,d3
                roxr.b  #1,d2
                lsl.w   #1,d3
                add.w   d3,d1

                move.w  (a0)+,d3
                asr.w   #1,d3
                roxr.b  #1,d2
                lsl.w   #1,d3
                add.w   d3,d1

                move.w  (a0)+,d3
                asr.w   #1,d3
                roxr.b  #1,d2
                lsl.w   #1,d3
                add.w   d3,d1
; skip w17,w18 (separator spaces)
                addq.w  #4,a0
; add w19 (level) and w20 (bike/extra)
                add.w   (a0)+,d1
                add.w   (a0)+,d1
; align the six collected bits into bits 5..0 (w11 = bit0)
                lsr.w   #2,d2
                move.w  d1,d0
                andi.w  #$3F,d0
                sub.w   d2,d0 ; if (mask != sum % 64) then password is invalid
                bne.w   .return
; check the three checksum characters w21,w22,w23
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  42(a0),d0 ; w21
                move.w  44(a0),d2 ; w22
                eor.w   d2,d0
                move.w  46(a0),d2 ; w23
                eor.w   d2,d0 ; xor 3 last chars
                andi.w  #$1F,d0 ; must be zero modulo 32, otherwise password is invalid
                bne.w   .return
; w21 == sum(w7..w11) modulo 32
                move.w  14(a0),d0 ; w7
                add.w   16(a0),d0 ; w8
                add.w   18(a0),d0 ; w9
                add.w   20(a0),d0 ; w10
                add.w   22(a0),d0 ; w11
                andi.w  #$1F,d0
                move.w  42(a0),d2 ; w21
                andi.w  #$1F,d2
                sub.w   d2,d0
; w22 == sum(w12..w16) modulo 32
                bne.w   .return
                move.w  24(a0),d0 ; w12
                add.w   26(a0),d0 ; w13
                add.w   28(a0),d0 ; w14
                add.w   30(a0),d0 ; w15
                add.w   32(a0),d0 ; w16
                andi.w  #$1F,d0
                move.w  44(a0),d2 ; w22
                andi.w  #$1F,d2
                sub.w   d2,d0
                bne.w   .return
.return:
                rts
; End of function MenuPassword_ValidatePassword

; *************************************************
; Function MenuPassword_ParsePassword
; Applies a valid password to player A/B state.
; In:  a0 - password word array (24 words)
;      d0 - 0 = player A, non-zero = player B
; Out: level/places/progress/money/bike fields updated
; Clobbers: d0-d2/a0-a1
; Notes: ROM $002D1E-$002F39. Level = w19 & 7. The opponent list is $4B (the
;        player's own definition id) followed by (level-1)*15 + 0..14.
;        Places = w0..w4 & $F. The 20-bit progress is reassembled MSB-first
;        from 5-bit pieces of w7..w10 into ram_FF0510/ram_FF0514. Money is six
;        nibbles w11..w16 (nibble = char >> 1), MSB first, sign-extended from
;        24 bits. w20 supplies the 3-bit bike id and the 2-bit extra field.
;        The inline "char #N" labels in the older comments counted 1-based
;        over the 20 non-space data characters; word indices are used below.
; *************************************************

MenuPassword_ParsePassword:
                tst.w   d0
                bne.w   .playerB
; Player A ---------------------------------------------------------------
                move.w  38(a0),d0 ; w19: level (3 bits)
                andi.w  #7,d0
                move.w  d0,(Menu_ram_PlayerALevel).l
                lea     (Menu_ram_PlayerAOpponents).l,a1
                move.w  #$4B,(a1)+ ; player's own definition id
                subq.w  #1,d0 ; level-1
                mulu.w  #15,d0 ; (level-1)*15
                move.w  #14,d1
.loc_2D46:
                move.w  d0,(a1)+ ; 15 opponent ids: base+0 .. base+14
                addq.w  #1,d0
                dbf     d1,.loc_2D46
                lea     (Menu_ram_PlayerAPlaces).l,a1
; w0..w4: finishing place in each of the five races (low nibble)
                move.w  (a0),(a1)
                andi.w  #$F,(a1)+
                move.w  2(a0),(a1)
                andi.w  #$F,(a1)+
                move.w  4(a0),(a1)
                andi.w  #$F,(a1)+
                move.w  6(a0),(a1)
                andi.w  #$F,(a1)+
                move.w  8(a0),(a1)
                andi.w  #$F,(a1)+
; 20-bit progress: w7 = bits 19..15
                move.w  14(a0),d0
                lsl.l   #8,d0
                lsl.l   #7,d0 ; << 15
                andi.l  #$F8000,d0
                move.l  d0,d1
; w8 = bits 14..10
                move.w  16(a0),d0
                lsl.w   #8,d0
                lsl.w   #2,d0 ; << 10
                andi.w  #$7C00,d0
                or.w    d0,d1
; w9 = bits 9..5
                move.w  18(a0),d0
                lsl.w   #5,d0
                andi.w  #$3E0,d0
                or.w    d0,d1
; w10 = bits 4..0
                move.w  20(a0),d0
                andi.w  #$1F,d0
                or.w    d0,d1
; combine them all into 20 bit integer to ram_FF0510
                move.l  d1,(ram_FF0510).l ; @UNKNOWN(U-0005): physical meaning/unit of this 20-bit field | guess: progress/points | next: audit readers in race_core/shop/highscore and compare two profiles
; w11: money nibble 5 (bits 23..20); bit0 is the embedded checksum
                move.w  22(a0),d0
                lsl.w   #3,d0
                swap    d0
                andi.l  #$F00000,d0
; w12: money nibble 4 (bits 19..16)
                move.w  24(a0),d1
                lsr.w   #1,d1 ; drop checksum bit
                swap    d1
                andi.l  #$F0000,d1
                or.l    d1,d0
; w13: money nibble 3 (bits 15..12)
                move.w  26(a0),d1
                lsl.w   #8,d1
                lsl.w   #3,d1 ; << 11
                andi.w  #$F000,d1
                or.w    d1,d0
; w14: money nibble 2 (bits 11..8)
                move.w  28(a0),d1
                lsl.w   #7,d1
                andi.w  #$F00,d1
                or.w    d1,d0
; w15: money nibble 1 (bits 7..4)
                move.w  30(a0),d1
                lsl.w   #3,d1
                andi.w  #$F0,d1
                or.w    d1,d0
; w16: money nibble 0 (bits 3..0)
                move.w  $20(a0),d1
                lsr.w   #1,d1
                andi.w  #$F,d1
                or.w    d1,d0
; combine them into 24 bit signed integer
                asl.l   #8,d0
                asr.l   #8,d0
; and write to Menu_ram_MoneyPlayerA
                move.l  d0,(Menu_ram_MoneyPlayerA).l
; w20: bits 3..4 -> ram_FF0522
                move.w  40(a0),d0
                asr.w   #3,d0
                andi.w  #3,d0
                move.w  d0,(ram_FF0522).l ; @UNKNOWN(U-0004): meaning of this 2-bit field | guess: bike/upgrade state | next: audit readers in race_core.asm and shop.asm
; w20: bits 0..2 -> bike id (0..7)
                move.w  40(a0),d0
                andi.w  #7,d0
                move.w  d0,(Menu_ram_BikeIdPlayerA).l

                bra.w   .locret_2F38
.playerB:
; Player B ---------------------------------------------------------------
                move.w  38(a0),d0 ; w19: level (3 bits)
                andi.w  #7,d0
                move.w  d0,(Menu_ram_PlayerBLevel).l
                lea     (Menu_ram_PlayerBOpponents).l,a1
                move.w  #$4B,(a1)+ ; player's own definition id
                subq.w  #1,d0
                mulu.w  #$F,d0
                move.w  #$E,d1

.loc_2E52:
                move.w  d0,(a1)+ ; 15 opponent ids: base+0 .. base+14
                addq.w  #1,d0
                dbf     d1,.loc_2E52
                lea     (Menu_ram_PlayerBPlaces).l,a1
; w0..w4: finishing place in each of the five races (low nibble)
                move.w  (a0),(a1)
                andi.w  #$F,(a1)+
                move.w  2(a0),(a1)
                andi.w  #$F,(a1)+
                move.w  4(a0),(a1)
                andi.w  #$F,(a1)+
                move.w  6(a0),(a1)
                andi.w  #$F,(a1)+
                move.w  8(a0),(a1)
                andi.w  #$F,(a1)+
; 20-bit progress: w7..w10 -> ram_FF0514 (same packing as player A)
                move.w  $E(a0),d0
                lsl.l   #8,d0
                lsl.l   #7,d0
                andi.l  #$F8000,d0
                move.l  d0,d1
                move.w  $10(a0),d0
                lsl.w   #8,d0
                lsl.w   #2,d0
                andi.w  #$7C00,d0
                or.w    d0,d1
                move.w  $12(a0),d0
                lsl.w   #5,d0
                andi.w  #$3E0,d0
                or.w    d0,d1
                move.w  $14(a0),d0
                andi.w  #$1F,d0
                or.w    d0,d1
                move.l  d1,(ram_FF0514).l
; w11..w16 -> 24-bit signed money (same packing as player A)
                move.w  $16(a0),d0
                lsl.w   #3,d0
                swap    d0
                andi.l  #$F00000,d0
                move.w  $18(a0),d1
                lsr.w   #1,d1
                swap    d1
                andi.l  #$F0000,d1
                or.l    d1,d0
                move.w  $1A(a0),d1
                lsl.w   #8,d1
                lsl.w   #3,d1
                andi.w  #$F000,d1
                or.w    d1,d0
                move.w  $1C(a0),d1
                lsl.w   #7,d1
                andi.w  #$F00,d1
                or.w    d1,d0
                move.w  $1E(a0),d1
                lsl.w   #3,d1
                andi.w  #$F0,d1
                or.w    d1,d0
                move.w  $20(a0),d1
                lsr.w   #1,d1
                andi.w  #$F,d1
                or.w    d1,d0
                asl.l   #8,d0
                asr.l   #8,d0
                move.l  d0,(Menu_ram_MoneyPlayerB).l
; w20: bits 3..4 -> ram_FF0524 (same field as U-0004); bits 0..2 -> bike id
                move.w  $28(a0),d0
                asr.w   #3,d0
                andi.w  #3,d0
                move.w  d0,(ram_FF0524).l
                move.w  $28(a0),d0
                andi.w  #7,d0
                move.w  d0,(Menu_ram_BikeIdPlayerB).l
.locret_2F38:
                rts
; End of function MenuPassword_ParsePassword

; *************************************************
; Function MenuPassword_CreatePassword
; Generates a password from the current player state.
; In:  Menu_ram_Player, player level/money/bike/places/progress fields
; Out: MenuPassword_ram_StrPlayerA/BPassword updated
; Clobbers: d0-d2/a0-a1
; Notes: ROM $002F3A-$003305. Inverse of ParsePassword + the checksum.
;        1) EncodeString first: the four separator words (w5,w6,w17,w18) are
;           not rewritten below, so this preserves the spaces already stored in
;           the password string (the editor never lets them change).
;        2) Overwrite w0..w4, w7..w16, w19, w20 and zero w21..w23; money
;           nibbles are stored as (nibble << 1) to leave bit0 free.
;        3) DecodeString -> string, ValidatePassword -> d1 = sum over the data
;           words (the same sum the validator computes).
;        4) OR the six low bits of d1 into bit0 of w11..w16, compute
;           w21 = sum(w7..w11) & $1F, w22 = sum(w12..w16) & $1F,
;           w23 = w21 ^ w22, then DecodeString the final characters.
; *************************************************

MenuPassword_CreatePassword:
                tst.w   (Menu_ram_Player).l
                bne.w   .loc_3126
; Player A ---------------------------------------------------------------
; Keep w5,w6,w17,w18 from the existing string; everything else is rewritten.
                lea     (MenuPassword_ram_StrPlayerAPassword).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_PlayerAPlaces).l,a1
                move.w  (a1)+,(a0)
                andi.w  #$F,(a0)
                move.w  (a1)+,2(a0)
                andi.w  #$F,2(a0)
                move.w  (a1)+,4(a0)
                andi.w  #$F,4(a0)
                move.w  (a1)+,6(a0)
                andi.w  #$F,6(a0)
                move.w  (a1)+,8(a0)
                andi.w  #$F,8(a0)
; w7..w10 = 5-bit pieces of the 20-bit progress (MSB first)
                move.l  (ram_FF0510).l,d0
                andi.l  #$F8000,d0
                lsr.l   #8,d0
                lsr.l   #7,d0
                move.w  d0,$E(a0)
                move.l  (ram_FF0510).l,d0
                andi.l  #$7C00,d0
                lsr.l   #8,d0
                lsr.l   #2,d0
                move.w  d0,$10(a0)
                move.l  (ram_FF0510).l,d0
                andi.l  #$3E0,d0
                lsr.l   #5,d0
                move.w  d0,$12(a0)
                move.l  (ram_FF0510).l,d0
                andi.l  #$1F,d0
                move.w  d0,$14(a0)
; w11..w16 = six money nibbles, MSB first, each stored as (nibble << 1)
                move.l  (Menu_ram_MoneyPlayerA).l,d0
                move.l  d0,d1
                swap    d1
                andi.w  #$F0,d1
                lsr.w   #3,d1
                move.w  d1,$16(a0)
                move.l  d0,d1
                swap    d1
                andi.w  #$F,d1
                lsl.w   #1,d1
                move.w  d1,$18(a0)
                move.w  d0,d1
                andi.w  #$F000,d1
                lsr.w   #8,d1
                lsr.w   #3,d1
                move.w  d1,$1A(a0)
                move.w  d0,d1
                andi.w  #$F00,d1
                lsr.w   #7,d1
                move.w  d1,$1C(a0)
                move.w  d0,d1
                andi.w  #$F0,d1
                lsr.w   #3,d1
                move.w  d1,$1E(a0)
                andi.w  #$F,d0
                lsl.w   #1,d0
                move.w  d0,$20(a0)
                move.w  (Menu_ram_PlayerALevel).l,d0
                andi.w  #7,d0
                move.w  d0,$26(a0)
                move.w  (ram_FF0522).l,d0
                lsl.w   #3,d0
                andi.w  #$18,d0
                move.w  d0,$28(a0)
                move.w  (Menu_ram_BikeIdPlayerA).l,d0
                andi.w  #7,d0
                or.w    d0,$28(a0)
                move.w  #0,$2A(a0) ; clear the three checksum chars
                move.w  #0,$2C(a0)
                move.w  #0,$2E(a0)
; Round-trip the data words through the string so ValidatePassword sees the
; same tile indices the player would enter. w21..w23 = 0 become '0' characters
; and re-encode as 0; the even money chars are unchanged by the round-trip.
                lea     (MenuPassword_ram_StrPlayerAPassword).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (DecodeString).w ; data words -> password characters
                lea     (MenuPassword_ram_StrPlayerAPassword).l,a0
                jsr     (MenuPassword_ValidatePassword).w ; d1 = checksum sum
                lea     (Intro_ram_ImageBuffer).l,a0 ; embed sum low bits into money chars
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$16(a0)
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$18(a0)
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$1A(a0)
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$1C(a0)
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$1E(a0)
                lsr.w   #1,d1
                andi.w  #1,d1
                or.w    d1,$20(a0)
                ; last 3 chars: sum(words 7-11), sum(words 12-16), XOR of the two
                move.w  $E(a0),d0
                add.w   $10(a0),d0
                add.w   $12(a0),d0
                add.w   $14(a0),d0
                add.w   $16(a0),d0
                andi.w  #$1F,d0
                move.w  d0,$2A(a0)
                move.w  $18(a0),d0
                add.w   $1A(a0),d0
                add.w   $1C(a0),d0
                add.w   $1E(a0),d0
                add.w   $20(a0),d0
                andi.w  #$1F,d0
                move.w  d0,$2C(a0)
                move.w  $2A(a0),d0
                move.w  $2C(a0),d2
                eor.w   d2,d0
                move.w  d0,$2E(a0) ; third checksum char = XOR of the first two
                lea     (MenuPassword_ram_StrPlayerAPassword).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (DecodeString).w ; final password characters
                bra.w   .locret_3304
.loc_3126:
; Player B ---------------------------------------------------------------
; Same sequence with B state: ram_FF0514/0524, MoneyPlayerB, BikeIdPlayerB.
                lea     (MenuPassword_ram_StrPlayerBPassword).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_PlayerBPlaces).l,a1
                move.w  (a1)+,(a0)
                andi.w  #$F,(a0)
                move.w  (a1)+,2(a0)
                andi.w  #$F,2(a0)
                move.w  (a1)+,4(a0)
                andi.w  #$F,4(a0)
                move.w  (a1)+,6(a0)
                andi.w  #$F,6(a0)
                move.w  (a1)+,8(a0)
                andi.w  #$F,8(a0)
                move.l  (ram_FF0514).l,d0
                andi.l  #$F8000,d0
                lsr.l   #8,d0
                lsr.l   #7,d0
                move.w  d0,$E(a0)
                move.l  (ram_FF0514).l,d0
                andi.l  #$7C00,d0
                lsr.l   #8,d0
                lsr.l   #2,d0
                move.w  d0,$10(a0)
                move.l  (ram_FF0514).l,d0
                andi.l  #$3E0,d0
                lsr.l   #5,d0
                move.w  d0,$12(a0)
                move.l  (ram_FF0514).l,d0
                andi.l  #$1F,d0
                move.w  d0,$14(a0)
                move.l  (Menu_ram_MoneyPlayerB).l,d0
                move.l  d0,d1
                swap    d1
                andi.w  #$F0,d1
                lsr.w   #3,d1
                move.w  d1,$16(a0)
                move.l  d0,d1
                swap    d1
                andi.w  #$F,d1
                lsl.w   #1,d1
                move.w  d1,$18(a0)
                move.w  d0,d1
                andi.w  #$F000,d1
                lsr.w   #8,d1
                lsr.w   #3,d1
                move.w  d1,$1A(a0)
                move.w  d0,d1
                andi.w  #$F00,d1
                lsr.w   #7,d1
                move.w  d1,$1C(a0)
                move.w  d0,d1
                andi.w  #$F0,d1
                lsr.w   #3,d1
                move.w  d1,$1E(a0)
                andi.w  #$F,d0
                lsl.w   #1,d0
                move.w  d0,$20(a0)
                move.w  (Menu_ram_PlayerBLevel).l,d0
                andi.w  #7,d0
                move.w  d0,$26(a0)
                move.w  (ram_FF0524).l,d0
                lsl.w   #3,d0
                andi.w  #$18,d0
                move.w  d0,$28(a0)
                move.w  (Menu_ram_BikeIdPlayerB).l,d0
                andi.w  #7,d0
                or.w    d0,$28(a0)
                move.w  #0,$2A(a0) ; clear the three checksum chars
                move.w  #0,$2C(a0)
                move.w  #0,$2E(a0)
; Same encode/decode/validate round-trip as player A.
                lea     (MenuPassword_ram_StrPlayerBPassword).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (DecodeString).w
                lea     (MenuPassword_ram_StrPlayerBPassword).l,a0
                jsr     (MenuPassword_ValidatePassword).w
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$16(a0)
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$18(a0)
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$1A(a0)
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$1C(a0)
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #1,d0
                or.w    d0,$1E(a0)
                lsr.w   #1,d1
                andi.w  #1,d1
                or.w    d1,$20(a0)
                ; last 3 chars: sum(words 7-11), sum(words 12-16), XOR of the two
                move.w  $E(a0),d0
                add.w   $10(a0),d0
                add.w   $12(a0),d0
                add.w   $14(a0),d0
                add.w   $16(a0),d0
                andi.w  #$1F,d0
                move.w  d0,$2A(a0)
                move.w  $18(a0),d0
                add.w   $1A(a0),d0
                add.w   $1C(a0),d0
                add.w   $1E(a0),d0
                add.w   $20(a0),d0
                andi.w  #$1F,d0
                move.w  d0,$2C(a0)
                move.w  $2A(a0),d0
                move.w  $2C(a0),d2
                eor.w   d2,d0
                move.w  d0,$2E(a0)
                lea     (MenuPassword_ram_StrPlayerBPassword).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (DecodeString).w

.locret_3304:
                rts
; End of function MenuPassword_CreatePassword

; *************************************************
; Function MenuPassword_DrawNamesAndPasswords
; Draws the A/B name and password strings into the frame buffer.
; In:  MenuPassword_ram_StrPlayerA/BName and StrPlayerA/BPassword records
; Out: Menu_ram_FrameBuffer updated
; Clobbers: d0-d6/a0-a1
; Notes: ROM $003306-$0033FF. Always redraws all four records, each at the
;        y/x stored in its own header (A: name y9/x5, password y15/x4; B:
;        name y9/x25, password y15/x24), using font base $6000 (palette 3) and
;        plane width 64. EncodeString re-encodes the text into
;        Intro_ram_ImageBuffer, then WriteNametableToBuffer blits it.
; *************************************************

MenuPassword_DrawNamesAndPasswords:
; encode player A name
                lea     (MenuPassword_ram_StrPlayerAName).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
; draw player A name
                lea     (MenuPassword_ram_StrPlayerAName).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette 3
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).l
; encode player A password
                lea     (MenuPassword_ram_StrPlayerAPassword).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
; draw player A password
                lea     (MenuPassword_ram_StrPlayerAPassword).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette 3
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).l
; encode player B name
                lea     (MenuPassword_ram_StrPlayerBName).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
; draw player B name
                lea     (MenuPassword_ram_StrPlayerBName).l,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).l
; encode player B password
                lea     (MenuPassword_ram_StrPlayerBPassword).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
; draw player B password
                lea     (MenuPassword_ram_StrPlayerBPassword).l,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).l
                rts
; End of function MenuPassword_DrawNamesAndPasswords
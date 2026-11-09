; *************************************************
; menu_password.asm - password entry/edit screen and password checksum
; ROM range: $2446-$33FF
; Status:    analyzed (password format/checksum reimplemented)
; API:       MenuPassword_GameTick, ValidatePassword, ParsePassword, CreatePassword
; *************************************************

Menu_DefaultPassword:
    dc.b "01234  5678901234  56789"

Menu_DefaultName:
    dc.b "Player A  "

unk_2468:
    dc.b " password accepted                      Players: 0          Level: 0                                "

; *************************************************
; Function MenuPassword_GameTick
; Password screen per-frame update: DMA the frame buffer, read pads, edit, exit.
; In:  Menu_ram_FrameBuffer - 64x28 nametable buffer
; Out: -
; Clobbers: d0-d3/a0-a1 (the update callback may clobber all registers)
; Notes: exits on Start release and installs MainMenu_GameTick.
; *************************************************

MenuPassword_GameTick:
; copy framebuffer to VRAM
                move.l  #(Menu_ram_FrameBuffer + $200),d0
                move.w  #$7200,d1
                move.w  #$600,d2 ; size in words 64 x 24
                jsr     (DmaWriteVRAM).l
; get Player A buttons
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l ; save previos button state
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l ; get button state
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerA).l ; get changed buttons
; get Player B buttons
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerB).l
; if START pressed
                movea.l (Menu_ram_CurrentButtonsPtr).l,a0
                movea.l (Menu_ram_ChangedButtonsPtr).l,a1
                move.w  (a0),d0
                andi.w  #$80,d0 ; get pressed 'Start' bit
                bne.w   .drawCursor
                move.w  (a1),d0 ; get changed 'Start' bit
                andi.w  #$80,d0
                bne.w   .endStage ; jump if 'Start' was released
.drawCursor:
                move.w  #$6000,d0 ; tile index 0, palette 3
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_254A
                move.w  #$6000,d0 ; player B
.loc_254A:
                move.w  #4,d2
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_2560
                move.w  #24,d2 ; player B

.loc_2560:
                add.w   (MenuPassword_ram_CursorX).l,d2 ; x
                move.w  (MenuPassword_ram_CursorY).l,d3 ; y
                jsr     (MenuPassword_SetCursorPos).l

                movea.l (Menu_ram_CurrentButtonsPtr).l,a0
                movea.l (Menu_ram_ChangedButtonsPtr).l,a1
                move.w  (a1),d0
                beq.w   .loc_2590 ; jump if no buttons were pressed or released
                and.w   (a0),d0
                beq.w   .loc_2590; jump if no buttons were pressed in this frame
                jsr     (MenuPassword_HandleInput).l ; handle newly pressed buttons
.loc_2590:
                movea.l (Menu_ram_CurrentButtonsPtr).l,a0
                movea.l (Menu_ram_ChangedButtonsPtr).l,a1
                tst.w   (a1)
                beq.w   .loc_25AA
                move.w  #0,(MenuPassword_ram_HoldTimer).l ; some button changed its state, reset hold timer
.loc_25AA:
                subq.w  #1,(MenuPassword_ram_HoldTimer).l
                bpl.w   .updateCursor
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
                move.w  #0,d0
                move.w  #4,d2
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_264E
                move.w  #24,d2 ; player B
.loc_264E:
                add.w   (MenuPassword_ram_CursorX).l,d2
                move.w  (MenuPassword_ram_CursorY).l,d3
                jsr     (MenuPassword_SetCursorPos).l

                subi.w  #1,(Menu_ram_MessageBlinkTimer).l
                subi.w  #1,(Menu_ram_NextMessageTimer).l
                bpl.w   .end
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                addi.w  #8,(Menu_ram_CurrentMessageId).l
                move.w  (Menu_ram_CurrentMessageId).l,d0
                cmpi.w  #(8*12),(Menu_ram_CurrentMessageId).l
                bpl.w   .loc_26A6
                move.w  #(8*12),(Menu_ram_CurrentMessageId).l
.loc_26A6:
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
                jsr     (MenuPassword_UpdateStatus).l
                jsr     (Menu_DrawPlayerInfo).l
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
; In:  d0 - current SACBRLDU buttons
;      MenuPassword_ram_StrPlayerNamePtr/StrPlayerPasswordPtr - active strings
; Out: -
; Clobbers: d0-d2/a0-a1
; Notes: A/B cycle characters, C switches player, directions move the cursor.
; *************************************************

MenuPassword_HandleInput:
                move.b  d0,(MenuPassword_ram_CurrentButtons).l
                btst    #6,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkB
; A pressed
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
                mulu.w  6(a0),d2
                add.w   d1,d2
                addq.w  #8,d2
                lea     (a0,d2.w),a0
                clr.w   d2
                move.b  (a0),d2
                lea     (dStringCodeTable).w,a1
                asl.w   #1,d2
                move.w  (a1,d2.w),d2
                subq.b  #1,d2
                bpl.w   .loc_2770
                move.b  #$31,d2

.loc_2770:
                lea     (dStringDecodeTable).w,a1
                move.b  (a1,d2.w),(a0)
                jsr     (MenuPassword_DrawNamesAndPasswords).l

.checkB:
                btst    #4,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkC
; B pressed
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
; C pressed
                jsr     (MenuPassword_UpdateStatus).l
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                bne.w   .loc_2830
                move.l  #MenuPassword_ram_StrPlayerBName,(MenuPassword_ram_StrPlayerNamePtr).l
                move.l  #MenuPassword_ram_StrPlayerBPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                move.w  #$FFFF,d0
                jsr     (MenuPassword_SwapPlayerBlocks).l
                jsr     (MenuPassword_DrawNamesAndPasswords).l
                bra.w   .checkRight
.loc_2830:
                move.l  #MenuPassword_ram_StrPlayerAName,(MenuPassword_ram_StrPlayerNamePtr).l
                move.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                move.w  #0,d0
                jsr     (MenuPassword_SwapPlayerBlocks).l
                jsr     (MenuPassword_DrawNamesAndPasswords).l

.checkRight:
                btst    #3,(MenuPassword_ram_CurrentButtons).l
                beq.w   .checkLeft
; Right pressed
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
; Left pressed
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
                move.w  #$6000,d4
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
; In:  active player name/password strings
; Out: status string/level/message
; Clobbers: d0-d2/a0-a2
; Notes: calls ValidatePassword, ParsePassword and MenuPassword_SelectCurrentTrack on success.
; *************************************************

MenuPassword_UpdateStatus:
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                move.w  #(8*5),(Menu_ram_CurrentMessageId).l ; show password status message (valid / invalid)
                lea     (MenuPassword_StrPasswordStatus).l,a0
                lea     (unk_4E20).l,a1 ; string ".. password invalid .."
                lea     (MenuPassword_ram_StrPlayerAName + 6).l,a2 ; ptr to player A name width
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                beq.w   .loc_2A5C
                lea     (MenuPassword_ram_StrPlayerBName + 6).l,a2 ; ptr to player B name width
.loc_2A5C:
                move.l  (a1)+,(a0)+ ; copy width & height
                move.l  (a1)+,(a0)+ ; copy x & y
                move.w  -4(a0),d0
                mulu.w  -2(a0),d0 ; get width * height

                subq.w  #1,d0
.loc_2A6A:
                move.b  (a1)+,(a0)+ ; copy chars
                dbf     d0,.loc_2A6A

                lea     (MenuPassword_StrPasswordStatus + 6).l,a0 ; ptr to x
                move.w  (a0)+,d0 ; get message x
                sub.w   (a2),d0
                asr.w   #1,d0
                adda.w  d0,a0
                move.w  (a2)+,d0
                subq.w  #1,d0
.loc_2A82:
                move.b  (a2)+,(a0)+
                dbf     d0,.loc_2A82

                movea.l (MenuPassword_ram_StrPlayerPasswordPtr).l,a0
                jsr     (MenuPassword_ValidatePassword).l
                tst.w   d0
                bne.w   .loc_2AEC
                lea     (MenuPassword_StrPasswordStatus + 4).l,a0
                move.w  (a0)+,d0
                subq.w  #1,d0
                mulu.w  (a0)+,d0
                adda.w  d0,a0
                move.b  #'N',(a0)+
                move.b  #'E',(a0)+
                move.b  #'W',(a0)+
                lea     (MenuPassword_StrPasswordStatus + 4).l,a0
                move.w  (a0)+,d0
                mulu.w  (a0)+,d0
                asr.w   #1,d0
                adda.w  d0,a0
                move.b  #' ',(a0)+
                move.b  #' ',(a0)+
                move.b  #' ',(a0)+
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                sne     d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (MenuPassword_ParsePassword).l
                jsr     (MenuPassword_SelectCurrentTrack).l

.loc_2AEC:
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
; In:  d0 - high byte value ($6000 restores text, 0 draws the cursor)
;      d2 - x, d3 - y
; Out: -
; Clobbers: a0
; Notes: writes only the high byte; the character tile stays unchanged.
; *************************************************

MenuPassword_SetCursorPos:
                lea     (Menu_ram_FrameBuffer).l,a0
                mulu.w  #128,d3
                asl.w   #1,d2
                add.w   d2,d3
                asr.w   #8,d0
                move.b  d0,(a0,d3.w)
                rts
; End of function MenuPassword_SetCursorPos

; *************************************************
; Function MenuPassword_SelectCurrentTrack
; Selects the current track from the player's race places.
; In:  Menu_ram_Player (A/B), Menu_ram_PlayerA/BPlaces
; Out: d0 - Menu_ram_CurrentTrackId (0,2,4,6,8)
; Clobbers: d0/d1/a0
; Notes: iterates the 5 places; the exact max-place rule is a hypothesis.
; *************************************************

MenuPassword_SelectCurrentTrack:
                lea     (Menu_ram_PlayerAPlaces).l,a0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_2B44
                lea     (Menu_ram_PlayerBPlaces).l,a0

.loc_2B44:
                move.w  #0,(Menu_ram_CurrentTrackId).l
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  (a0),d0 ; get place in race 1
                beq.w   .loc_2BE6
                move.w  #2,(Menu_ram_CurrentTrackId).l
                tst.w   2(a0)
                beq.w   .loc_2BE6
                cmp.w   2(a0),d0
                bpl.w   .loc_2B7A
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  2(a0),d0

.loc_2B7A:
                move.w  #4,(Menu_ram_CurrentTrackId).l
                tst.w   4(a0)
                beq.w   .loc_2BE6
                cmp.w   4(a0),d0
                bpl.w   .loc_2B9C
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  4(a0),d0

.loc_2B9C:
                move.w  #6,(Menu_ram_CurrentTrackId).l
                tst.w   6(a0)
                beq.w   .loc_2BE6
                cmp.w   6(a0),d0
                bpl.w   .loc_2BBE
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  6(a0),d0

.loc_2BBE:
                move.w  #8,(Menu_ram_CurrentTrackId).l
                tst.w   8(a0)
                beq.w   .loc_2BE6
                cmp.w   8(a0),d0
                bpl.w   .loc_2BE0
                move.w  (Menu_ram_CurrentTrackId).l,d1
                move.w  8(a0),d0

.loc_2BE0:
                move.w  d1,(Menu_ram_CurrentTrackId).l

.loc_2BE6:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                rts
; End of function MenuPassword_SelectCurrentTrack

; *************************************************
; Function MenuPassword_SwapPlayerBlocks
; Swaps the player A/B name/password display blocks in the frame buffer.
; In:  d0 - 0 = player A, non-zero = player B
; Out: -
; Clobbers: d0-d2/a0-a1
; Notes: swaps 14 rows x 8 longs at FrameBuffer+$280.
; *************************************************

MenuPassword_SwapPlayerBlocks:
                lea     (Menu_ram_FrameBuffer + $280).l,a0
                movea.l a0,a1
                adda.w  #$2C,a0
                addq.w  #4,a1
                tst.w   d0
                beq.w   .loc_2C04
                exg     a0,a1

.loc_2C04:
                move.w  (dStringCodeTable + 2 * ' ').w,d0
                ori.w   #$6000,d0
                cmp.w   (a1),d0
                bne.w   .locret_2C30
                move.w  #$D,d1

.loc_2C16:
                move.w  #7,d0

.loc_2C1A:
                move.l  (a0),d2
                move.l  (a1),(a0)+
                move.l  d2,(a1)+
                dbf     d0,.loc_2C1A
                adda.w  #$60,a0
                adda.w  #$60,a1
                dbf     d1,.loc_2C16

.locret_2C30:
                rts
; End of function MenuPassword_SwapPlayerBlocks

; *************************************************
; Function MenuPassword_ValidatePassword
; Verifies the 24-character password checksum.
; In:  a0 - password string (header + 24 chars)
; Out: d0 - 0 = valid, non-zero = invalid; d1 - checksum sum
; Clobbers: d0-d3/a0-a1
; Notes: password format: places 0-4, spaces 5-6, progress 7-10, money 11-16
;        (nibble<<1; bit0 = checksum), spaces 17-18, level 19, bike/extra 20,
;        checksum 21-23.
; *************************************************

MenuPassword_ValidatePassword:
; convert string to word array
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w

                lea     (Intro_ram_ImageBuffer).l,a0 ; 24 chars, two lines of 12 chars
                move.w  #$FFFF,d0
                move.w  #0,d1
                move.w  #0,d2
; sum first 5 chars
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
; skip two spaces
                addq.w  #4,a0
; add 4 more chars
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
                add.w   (a0)+,d1
; add event part of the char to the sum and make d2 of lower bits of each char
                move.w  (a0)+,d3
                asr.w   #1,d3
                roxr.b  #1,d2
                lsl.w   #1,d3
                add.w   d3,d1
; repeat this for 6 chars
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
; skip two spaces
                addq.w  #4,a0
; add two chars
                add.w   (a0)+,d1
                add.w   (a0)+,d1
; get rid of two lower bytes, so the mask is in lower 6 bytes
                lsr.w   #2,d2
                move.w  d1,d0
                andi.w  #$3F,d0
                sub.w   d2,d0 ; if (mask != sum % 64) then password is invalid
                bne.w   .return
; check 3 last chars
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  42(a0),d0
                move.w  44(a0),d2
                eor.w   d2,d0
                move.w  46(a0),d2
                eor.w   d2,d0 ; xor 3 last chars
                andi.w  #$1F,d0 ; must be zero modulo 32, otherwise password is invalid
                bne.w   .return
; third char from the end is equal to sum of chars from 6 to 10 modulo 32
                move.w  14(a0),d0
                add.w   16(a0),d0
                add.w   18(a0),d0
                add.w   20(a0),d0
                add.w   22(a0),d0
                andi.w  #$1F,d0
                move.w  42(a0),d2
                andi.w  #$1F,d2
                sub.w   d2,d0
; second char from the end is equal to sum of chars from 11 to 15 modulo 32
                bne.w   .return
                move.w  24(a0),d0
                add.w   26(a0),d0
                add.w   28(a0),d0
                add.w   30(a0),d0
                add.w   32(a0),d0
                andi.w  #$1F,d0
                move.w  44(a0),d2
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
; Notes: opponents = $4B, (level-1)*15 + 0..14; money is sign-extended 24-bit.
; *************************************************

MenuPassword_ParsePassword:
                tst.w   d0
                bne.w   .playerB
                move.w  38(a0),d0 ; char #16 is player level
                andi.w  #7,d0
                move.w  d0,(Menu_ram_PlayerALevel).l
                lea     (Menu_ram_PlayerAOpponents).l,a1
                move.w  #$4B,(a1)+
                subq.w  #1,d0
                mulu.w  #15,d0
                move.w  #14,d1
.loc_2D46:
                move.w  d0,(a1)+
                addq.w  #1,d0
                dbf     d1,.loc_2D46
                lea     (Menu_ram_PlayerAPlaces).l,a1
; first 5 characters are player places in each of 5 races
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
; get 5 bits of char #6
                move.w  14(a0),d0
                lsl.l   #8,d0
                lsl.l   #7,d0
                andi.l  #$F8000,d0
                move.l  d0,d1
; and 5 bits of char #7
                move.w  16(a0),d0
                lsl.w   #8,d0
                lsl.w   #2,d0
                andi.w  #$7C00,d0
                or.w    d0,d1
; and 5 bits of char #8
                move.w  18(a0),d0
                lsl.w   #5,d0
                andi.w  #$3E0,d0
                or.w    d0,d1
; and 5 bits of char #9
                move.w  20(a0),d0
                andi.w  #$1F,d0
                or.w    d0,d1
; combine them all into 20 bit integer to ram_FF0510
                move.l  d1,(ram_FF0510).l
; get 4 bits of char #10 (except lowest one)
                move.w  22(a0),d0
                lsl.w   #3,d0
                swap    d0
                andi.l  #$F00000,d0
; and 4 bits of char #11
                move.w  24(a0),d1
                lsr.w   #1,d1
                swap    d1
                andi.l  #$F0000,d1
                or.l    d1,d0
; and 4 bits of char #12
                move.w  26(a0),d1
                lsl.w   #8,d1
                lsl.w   #3,d1
                andi.w  #$F000,d1
                or.w    d1,d0
; and 4 bits of char #13
                move.w  28(a0),d1
                lsl.w   #7,d1
                andi.w  #$F00,d1
                or.w    d1,d0
; and 4 bits of char #14
                move.w  30(a0),d1
                lsl.w   #3,d1
                andi.w  #$F0,d1
                or.w    d1,d0
; and 4 bits of char #15
                move.w  $20(a0),d1
                lsr.w   #1,d1
                andi.w  #$F,d1
                or.w    d1,d0
; combine them into 24 bit signed integer
                asl.l   #8,d0
                asr.l   #8,d0
; and write to Menu_ram_MoneyPlayerA
                move.l  d0,(Menu_ram_MoneyPlayerA).l
; char #17
                move.w  40(a0),d0
; bits 3-4
                asr.w   #3,d0
                andi.w  #3,d0
                move.w  d0,(ram_FF0522).l
; bits 0-2 : bike id (0 - 7)
                move.w  40(a0),d0
                andi.w  #7,d0
                move.w  d0,(Menu_ram_BikeIdPlayerA).l

                bra.w   .locret_2F38
.playerB:
                move.w  38(a0),d0
                andi.w  #7,d0
                move.w  d0,(Menu_ram_PlayerBLevel).l
                lea     (Menu_ram_PlayerBOpponents).l,a1
                move.w  #$4B,(a1)+
                subq.w  #1,d0
                mulu.w  #$F,d0
                move.w  #$E,d1

.loc_2E52:
                move.w  d0,(a1)+
                addq.w  #1,d0
                dbf     d1,.loc_2E52
                lea     (Menu_ram_PlayerBPlaces).l,a1
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
; Notes: writes the data words, embeds the checksum bits in the money chars,
;        computes the three checksum chars, then DecodeString.
; *************************************************

MenuPassword_CreatePassword:
                tst.w   (Menu_ram_Player).l
                bne.w   .loc_3126
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
                move.w  #0,$2A(a0)
                move.w  #0,$2C(a0)
                move.w  #0,$2E(a0)
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
; In:  player name/password strings
; Out: Menu_ram_FrameBuffer updated
; Clobbers: d0-d6/a0-a1
; Notes: uses EncodeString + WriteNametableToBuffer (plane width 64).
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
Menu_DefaultPassword:
    dc.b "01234  5678901234  56789"

Menu_DefaultName:
    dc.b "Player A  "

unk_2468:
    dc.b " password accepted                      Players: 0          Level: 0                                "

; *************************************************
; Function MenuPassword_GameTick
; *************************************************

MenuPassword_GameTick:
; copy framebuffer to VRAM
                move.l  #(Menu_ram_FrameBuffer + $200),d0
                move.w  #$7200,d1
                move.w  #$600,d2 ; size in words 64 x 24
                jsr     DmaWriteVRAM
; get Player A buttons
                move.w  MainMenu_ram_ButtonsPlayerA,MainMenu_ram_ChangedButtonsPlayerA ; save previos button state
                jsr     (GetInputPlayerA).w
                move.w  d0,MainMenu_ram_ButtonsPlayerA ; get button state
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerA ; get changed buttons
; get Player B buttons
                move.w  MainMenu_ram_ButtonsPlayerB,MainMenu_ram_ChangedButtonsPlayerB
                jsr     (GetInputPlayerB).w
                move.w  d0,MainMenu_ram_ButtonsPlayerB
                eor.w   d0,MainMenu_ram_ChangedButtonsPlayerB
; if START pressed
                movea.l Menu_ram_CurrentButtonsPtr,a0
                movea.l Menu_ram_ChangedButtonsPtr,a1
                move.w  (a0),d0
                andi.w  #$80,d0 ; get pressed 'Start' bit
                bne.w   @drawCursor
                move.w  (a1),d0 ; get changed 'Start' bit
                andi.w  #$80,d0
                bne.w   @endStage ; jump if 'Start' was released
@drawCursor:
                move.w  #$6000,d0 ; tile index 0, palette 3
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                beq.w   @loc_254A
                move.w  #$6000,d0 ; player B
@loc_254A:
                move.w  #4,d2
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                beq.w   @loc_2560
                move.w  #24,d2 ; player B

@loc_2560:
                add.w   MenuPassword_ram_CursorX,d2 ; x
                move.w  MenuPassword_ram_CursorY,d3 ; y
                jsr     MenuPassword_SetCursorPos

                movea.l Menu_ram_CurrentButtonsPtr,a0
                movea.l Menu_ram_ChangedButtonsPtr,a1
                move.w  (a1),d0
                beq.w   @loc_2590 ; jump if no buttons were pressed or released
                and.w   (a0),d0
                beq.w   @loc_2590; jump if no buttons were pressed in this frame
                jsr     MenuPassword_HandleInput ; handle newly pressed buttons
@loc_2590:
                movea.l Menu_ram_CurrentButtonsPtr,a0
                movea.l Menu_ram_ChangedButtonsPtr,a1
                tst.w   (a1)
                beq.w   @loc_25AA
                move.w  #0,MenuPassword_ram_HoldTimer ; some button changed its state, reset hold timer
@loc_25AA:
                subq.w  #1,MenuPassword_ram_HoldTimer
                bpl.w   @updateCursor
                move.w  #$FFFF,MenuPassword_ram_HoldTimer
                tst.w   (a1)
                bne.w   @loc_25E4
                tst.w   MenuPassword_ram_HeldButtons
                beq.w   @updateCursor
                move.w  #8,MenuPassword_ram_HoldTimer
                move.w  MenuPassword_ram_HeldButtons,d0
                jsr     MenuPassword_HandleInput ; handle held buttons
                bra.w   @updateCursor
@loc_25E4:
                clr.w   MenuPassword_ram_HeldButtons
                move.w  (a0),d0
                and.w   (a1),d0
                beq.w   @updateCursor
                cmp.w   #1,d0
                beq.w   @loc_2626
                cmp.w   #2,d0
                beq.w   @loc_2626
                cmp.w   #4,d0
                beq.w   @loc_2626
                cmp.w   #8,d0
                beq.w   @loc_2626
                cmp.w   #$10,d0
                beq.w   @loc_2626
                cmp.w   #$40,d0
                beq.w   @loc_2626
                bra.w   @updateCursor

@loc_2626:
                move.w  #30,MenuPassword_ram_HoldTimer
                move.w  d0,MenuPassword_ram_HeldButtons

@updateCursor:
                move.w  #0,d0
                move.w  #4,d2
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                beq.w   @loc_264E
                move.w  #24,d2 ; player B
@loc_264E:
                add.w   MenuPassword_ram_CursorX,d2
                move.w  MenuPassword_ram_CursorY,d3
                jsr     MenuPassword_SetCursorPos

                subi.w  #1,Menu_ram_MessageBlinkTimer
                subi.w  #1,Menu_ram_NextMessageTimer
                bpl.w   @end
                move.w  #30,Menu_ram_MessageBlinkTimer
                move.w  #240,Menu_ram_NextMessageTimer
                addi.w  #8,Menu_ram_CurrentMessageId
                move.w  Menu_ram_CurrentMessageId,d0
                cmpi.w  #(8*12),Menu_ram_CurrentMessageId
                bpl.w   @loc_26A6
                move.w  #(8*12),Menu_ram_CurrentMessageId
@loc_26A6:
                lea     Message_MsgArray,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0
                bne.w   @end
                move.w  #(8*12),Menu_ram_CurrentMessageId
@end:
                jsr     Menu_ShowMessage
                jsr     AudioFunc1
                rts
@endStage:
                jsr     sub_2A1E
                jsr     Menu_DrawPlayerInfo
                move.l  #$67FF67FF,d0
                lea     Menu_ram_FrameBuffer + $280,a0
                move.w  #$21F,d1
@loc_26EC:
                move.l  d0,(a0)+
                dbf     d1,@loc_26EC

                move.w  Menu_ram_CurrentTrackId,d0
                jsr     Menu_DrawRaceSelection
                jsr     Menu_DrawPlayerInfo
                move.l  #MainMenu_GameTick,ram_UpdateFunction ; get to main menu
                bra.s   @end
; End of function NamePassword_GameTick

; *************************************************
; Function MenuPassword_HandleInput
; d0 - current buttons state (SACBRLDU)
; *************************************************

MenuPassword_HandleInput:
                move.b  d0,MenuPassword_ram_CurrentButtons
                btst    #6,MenuPassword_ram_CurrentButtons
                beq.w   @checkB
; A pressed
                movea.l MenuPassword_ram_StrPlayerPasswordPtr,a0
                move.w  MenuPassword_ram_CursorX,d1
                move.w  MenuPassword_ram_CursorY,d2
                cmp.w   #9,d2
                bne.w   @loc_2748
                move.w  #15,d2
                subq.w  #1,d1
                movea.l MenuPassword_ram_StrPlayerNamePtr,a0
@loc_2748:
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
                bpl.w   @loc_2770
                move.b  #$31,d2

@loc_2770:
                lea     (dStringDecodeTable).w,a1
                move.b  (a1,d2.w),(a0)
                jsr     MenuPassword_DrawNamesAndPasswords

@checkB:
                btst    #4,MenuPassword_ram_CurrentButtons
                beq.w   @checkC
; B pressed
                movea.l MenuPassword_ram_StrPlayerPasswordPtr,a0
                move.w  MenuPassword_ram_CursorX,d1
                move.w  MenuPassword_ram_CursorY,d2
                cmp.w   #9,d2
                bne.w   @loc_27B0
                move.w  #$F,d2
                subq.w  #1,d1
                movea.l MenuPassword_ram_StrPlayerNamePtr,a0

@loc_27B0:
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
                ble.w   @loc_27DA
                move.b  #0,d2

@loc_27DA:
                lea     (dStringDecodeTable).w,a1
                move.b  (a1,d2.w),(a0)
                jsr     MenuPassword_DrawNamesAndPasswords

@checkC:
                btst    #5,MenuPassword_ram_CurrentButtons
                beq.w   @checkRight
; C pressed
                jsr     sub_2A1E
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                bne.w   @loc_2830
                move.l  #MenuPassword_ram_StrPlayerBName,MenuPassword_ram_StrPlayerNamePtr
                move.l  #MenuPassword_ram_StrPlayerBPassword,MenuPassword_ram_StrPlayerPasswordPtr
                move.w  #$FFFF,d0
                jsr     sub_2BEE
                jsr     MenuPassword_DrawNamesAndPasswords
                bra.w   @checkRight
@loc_2830:
                move.l  #MenuPassword_ram_StrPlayerAName,MenuPassword_ram_StrPlayerNamePtr
                move.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                move.w  #0,d0
                jsr     sub_2BEE
                jsr     MenuPassword_DrawNamesAndPasswords

@checkRight:
                btst    #3,MenuPassword_ram_CurrentButtons
                beq.w   @checkLeft
; Right pressed
                addq.w  #1,MenuPassword_ram_CursorX
                cmpi.w  #9,MenuPassword_ram_CursorY
                bne.w   @loc_288A
                cmpi.w  #$A,MenuPassword_ram_CursorX
                ble.w   @checkLeft
                move.w  #1,MenuPassword_ram_CursorX
                bra.w   @checkLeft

@loc_288A:
                cmpi.w  #5,MenuPassword_ram_CursorX
                bne.w   @loc_28A2
                move.w  #7,MenuPassword_ram_CursorX
                bra.w   @checkLeft

@loc_28A2:
                cmpi.w  #$C,MenuPassword_ram_CursorX
                bmi.w   @checkLeft
                move.w  #0,MenuPassword_ram_CursorX

@checkLeft:
                btst    #2,MenuPassword_ram_CurrentButtons
                beq.w   @checkDown
; Left pressed
                cmpi.w  #9,MenuPassword_ram_CursorY
                bne.w   @loc_28E4
                subq.w  #1,MenuPassword_ram_CursorX
                bgt.w   @checkDown
                move.w  #10,MenuPassword_ram_CursorX
                bra.w   @checkDown
@loc_28E4:
                subq.w  #1,MenuPassword_ram_CursorX
                bpl.w   @loc_28FA
                move.w  #$B,MenuPassword_ram_CursorX
                bra.w   @checkDown
@loc_28FA:
                cmpi.w  #6,MenuPassword_ram_CursorX
                bne.w   @checkDown
                move.w  #4,MenuPassword_ram_CursorX
@checkDown:
                btst    #1,MenuPassword_ram_CurrentButtons
                beq.w   @checkUp
                cmpi.w  #$10,MenuPassword_ram_CursorY
                beq.w   @checkUp
                addq.w  #1,MenuPassword_ram_CursorY
                cmpi.w  #$A,MenuPassword_ram_CursorY
                bne.w   @checkUp
                move.w  #$F,MenuPassword_ram_CursorY
                cmpi.w  #5,MenuPassword_ram_CursorX
                bne.w   @loc_2958
                move.w  #4,MenuPassword_ram_CursorX
                bra.w   @checkUp

@loc_2958:
                cmpi.w  #6,MenuPassword_ram_CursorX
                bne.w   @checkUp
                move.w  #7,MenuPassword_ram_CursorX
                bra.w   @checkUp

@checkUp:
                btst    #0,MenuPassword_ram_CurrentButtons
                beq.w   @updatePasswordText
                cmpi.w  #9,MenuPassword_ram_CursorY
                beq.w   @updatePasswordText
                subq.w  #1,MenuPassword_ram_CursorY
                cmpi.w  #$E,MenuPassword_ram_CursorY
                bne.w   @updatePasswordText
                move.w  #9,MenuPassword_ram_CursorY
                cmpi.w  #0,MenuPassword_ram_CursorX
                bne.w   @loc_29BA
                move.w  #1,MenuPassword_ram_CursorX
                bra.w   @updatePasswordText

@loc_29BA:
                cmpi.w  #$A,MenuPassword_ram_CursorX
                ble.s   @checkUp
                move.w  #$A,MenuPassword_ram_CursorX

@updatePasswordText:
                movea.l MenuPassword_ram_StrPlayerPasswordPtr,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
                movea.l MenuPassword_ram_StrPlayerPasswordPtr,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                beq.w   @loc_2A06
                move.w  #$6000,d4
@loc_2A06:
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                jsr     WriteNametableToBuffer
                rts
; End of function MenuPassword_HandleInput

; *************************************************
; Function sub_2A1E
; *************************************************

sub_2A1E:
                move.w  #30,Menu_ram_MessageBlinkTimer
                move.w  #240,Menu_ram_NextMessageTimer
                move.w  #(8*5),Menu_ram_CurrentMessageId ; show password status message (valid / invalid)
                lea     MenuPassword_StrPasswordStatus,a0
                lea     unk_4E20,a1 ; string ".. password invalid .."
                lea     MenuPassword_ram_StrPlayerAName + 6,a2 ; ptr to player A name width
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                beq.w   @loc_2A5C
                lea     MenuPassword_ram_StrPlayerBName + 6,a2 ; ptr to player B name width
@loc_2A5C:
                move.l  (a1)+,(a0)+ ; copy width & height
                move.l  (a1)+,(a0)+ ; copy x & y
                move.w  -4(a0),d0
                mulu.w  -2(a0),d0 ; get width * height

                subq.w  #1,d0
@loc_2A6A:
                move.b  (a1)+,(a0)+ ; copy chars
                dbf     d0,@loc_2A6A

                lea     MenuPassword_StrPasswordStatus + 6,a0 ; ptr to x
                move.w  (a0)+,d0 ; get message x
                sub.w   (a2),d0
                asr.w   #1,d0
                adda.w  d0,a0
                move.w  (a2)+,d0
                subq.w  #1,d0
@loc_2A82:
                move.b  (a2)+,(a0)+
                dbf     d0,@loc_2A82
                
                movea.l MenuPassword_ram_StrPlayerPasswordPtr,a0
                jsr     MenuPassword_ValidatePassword
                tst.w   d0
                bne.w   @loc_2AEC
                lea     MenuPassword_StrPasswordStatus + 4,a0
                move.w  (a0)+,d0
                subq.w  #1,d0
                mulu.w  (a0)+,d0
                adda.w  d0,a0
                move.b  #'N',(a0)+
                move.b  #'E',(a0)+
                move.b  #'W',(a0)+
                lea     MenuPassword_StrPasswordStatus + 4,a0
                move.w  (a0)+,d0
                mulu.w  (a0)+,d0
                asr.w   #1,d0
                adda.w  d0,a0
                move.b  #' ',(a0)+
                move.b  #' ',(a0)+
                move.b  #' ',(a0)+
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                sne     d0
                lea     Intro_ram_ImageBuffer,a0
                jsr     MenuPassword_ParsePassword
                jsr     sub_2B2E

@loc_2AEC:
                move.w  Menu_ram_PlayerALevel,d1
                cmpi.l  #MenuPassword_ram_StrPlayerAPassword,MenuPassword_ram_StrPlayerPasswordPtr
                beq.w   @loc_2B06
                move.w  Menu_ram_PlayerBLevel,d1

@loc_2B06:
                lea     MenuPassword_StrPasswordStatus + 4,a0
                move.w  (a0)+,d0
                mulu.w  (a0)+,d0
                subq.w  #2,d0
                add.b   d1,(a0,d0.w)
                rts
; End of function sub_2A1E

; *************************************************
; Function MenuPassword_SetCursorPos
; *************************************************

MenuPassword_SetCursorPos:
                lea     Menu_ram_FrameBuffer,a0
                mulu.w  #128,d3
                asl.w   #1,d2
                add.w   d2,d3
                asr.w   #8,d0
                move.b  d0,(a0,d3.w)
                rts
; End of function MenuPassword_SetCursorPos

; *************************************************
; Function sub_2B2E
; *************************************************

sub_2B2E:
                lea     Menu_ram_PlayerAPlaces,a0
                tst.w   Menu_ram_Player
                beq.w   @loc_2B44
                lea     Menu_ram_PlayerBPlaces,a0

@loc_2B44:
                move.w  #0,Menu_ram_CurrentTrackId
                move.w  Menu_ram_CurrentTrackId,d1
                move.w  (a0),d0 ; get place in race 1
                beq.w   @loc_2BE6
                move.w  #2,Menu_ram_CurrentTrackId
                tst.w   2(a0)
                beq.w   @loc_2BE6
                cmp.w   2(a0),d0
                bpl.w   @loc_2B7A
                move.w  Menu_ram_CurrentTrackId,d1
                move.w  2(a0),d0

@loc_2B7A:
                move.w  #4,Menu_ram_CurrentTrackId
                tst.w   4(a0)
                beq.w   @loc_2BE6
                cmp.w   4(a0),d0
                bpl.w   @loc_2B9C
                move.w  Menu_ram_CurrentTrackId,d1
                move.w  4(a0),d0

@loc_2B9C:
                move.w  #6,Menu_ram_CurrentTrackId
                tst.w   6(a0)
                beq.w   @loc_2BE6
                cmp.w   6(a0),d0
                bpl.w   @loc_2BBE
                move.w  Menu_ram_CurrentTrackId,d1
                move.w  6(a0),d0

@loc_2BBE:
                move.w  #8,Menu_ram_CurrentTrackId
                tst.w   8(a0)
                beq.w   @loc_2BE6
                cmp.w   8(a0),d0
                bpl.w   @loc_2BE0
                move.w  Menu_ram_CurrentTrackId,d1
                move.w  8(a0),d0

@loc_2BE0:
                move.w  d1,Menu_ram_CurrentTrackId

@loc_2BE6:
                move.w  Menu_ram_CurrentTrackId,d0
                rts
; End of function sub_2B2E

; *************************************************
; Function sub_2BEE
; *************************************************

sub_2BEE:
                lea     Menu_ram_FrameBuffer + $280,a0
                movea.l a0,a1
                adda.w  #$2C,a0
                addq.w  #4,a1
                tst.w   d0
                beq.w   @loc_2C04
                exg     a0,a1

@loc_2C04:
                move.w  (dStringCodeTable + 2 * ' ').w,d0
                ori.w   #$6000,d0
                cmp.w   (a1),d0
                bne.w   @locret_2C30
                move.w  #$D,d1

@loc_2C16:
                move.w  #7,d0

@loc_2C1A:
                move.l  (a0),d2
                move.l  (a1),(a0)+
                move.l  d2,(a1)+
                dbf     d0,@loc_2C1A
                adda.w  #$60,a0
                adda.w  #$60,a1
                dbf     d1,@loc_2C16

@locret_2C30:
                rts
; End of function sub_2BEE

; *************************************************
; Function MenuPassword_ValidatePassword
; a0 - password string
; d0 - result (out)
; *************************************************

MenuPassword_ValidatePassword:
; convert string to word array
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w

                lea     Intro_ram_ImageBuffer,a0 ; 24 chars, two lines of 12 chars
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
                bne.w   @return
; check 3 last chars
                lea     Intro_ram_ImageBuffer,a0
                move.w  42(a0),d0
                move.w  44(a0),d2
                eor.w   d2,d0
                move.w  46(a0),d2
                eor.w   d2,d0 ; xor 3 last chars
                andi.w  #$1F,d0 ; must be zero modulo 32, otherwise password is invalid
                bne.w   @return
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
                bne.w   @return
                move.w  24(a0),d0
                add.w   26(a0),d0
                add.w   28(a0),d0
                add.w   30(a0),d0
                add.w   32(a0),d0
                andi.w  #$1F,d0
                move.w  44(a0),d2
                andi.w  #$1F,d2
                sub.w   d2,d0
                bne.w   @return
@return:
                rts
; End of function MenuPassword_ValidatePassword

; *************************************************
; Function MenuPassword_ParsePassword
; a0 - password word array (size 24)
; d0 player index
; *************************************************

MenuPassword_ParsePassword:
                tst.w   d0
                bne.w   @playerB
                move.w  38(a0),d0 ; char #16 is player level
                andi.w  #7,d0
                move.w  d0,Menu_ram_PlayerALevel
                lea     Menu_ram_PlayerAOpponents,a1
                move.w  #$4B,(a1)+
                subq.w  #1,d0
                mulu.w  #15,d0
                move.w  #14,d1
@loc_2D46:
                move.w  d0,(a1)+
                addq.w  #1,d0
                dbf     d1,@loc_2D46
                lea     Menu_ram_PlayerAPlaces,a1
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
                move.l  d1,ram_FF0510
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
                move.l  d0,Menu_ram_MoneyPlayerA
; char #17
                move.w  40(a0),d0
; bits 3-4
                asr.w   #3,d0
                andi.w  #3,d0
                move.w  d0,ram_FF0522
; bits 0-2 : bike id (0 - 7)
                move.w  40(a0),d0
                andi.w  #7,d0
                move.w  d0,Menu_ram_BikeIdPlayerA

                bra.w   @locret_2F38
@playerB:
                move.w  38(a0),d0
                andi.w  #7,d0
                move.w  d0,Menu_ram_PlayerBLevel
                lea     Menu_ram_PlayerBOpponents,a1
                move.w  #$4B,(a1)+
                subq.w  #1,d0
                mulu.w  #$F,d0
                move.w  #$E,d1

@loc_2E52:
                move.w  d0,(a1)+
                addq.w  #1,d0
                dbf     d1,@loc_2E52
                lea     Menu_ram_PlayerBPlaces,a1
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
                move.l  d1,ram_FF0514
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
                move.l  d0,Menu_ram_MoneyPlayerB
                move.w  $28(a0),d0
                asr.w   #3,d0
                andi.w  #3,d0
                move.w  d0,ram_FF0524
                move.w  $28(a0),d0
                andi.w  #7,d0
                move.w  d0,Menu_ram_BikeIdPlayerB
@locret_2F38:
                rts
; End of function MenuPassword_ParsePassword

; *************************************************
; Function MenuPassword_CreatePassword
; *************************************************

MenuPassword_CreatePassword:
                tst.w   Menu_ram_Player
                bne.w   @loc_3126
                lea     MenuPassword_ram_StrPlayerAPassword,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_PlayerAPlaces,a1
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
                move.l  ram_FF0510,d0
                andi.l  #$F8000,d0
                lsr.l   #8,d0
                lsr.l   #7,d0
                move.w  d0,$E(a0)
                move.l  ram_FF0510,d0
                andi.l  #$7C00,d0
                lsr.l   #8,d0
                lsr.l   #2,d0
                move.w  d0,$10(a0)
                move.l  ram_FF0510,d0
                andi.l  #$3E0,d0
                lsr.l   #5,d0
                move.w  d0,$12(a0)
                move.l  ram_FF0510,d0
                andi.l  #$1F,d0
                move.w  d0,$14(a0)
                move.l  Menu_ram_MoneyPlayerA,d0
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
                move.w  Menu_ram_PlayerALevel,d0
                andi.w  #7,d0
                move.w  d0,$26(a0)
                move.w  ram_FF0522,d0
                lsl.w   #3,d0
                andi.w  #$18,d0
                move.w  d0,$28(a0)
                move.w  Menu_ram_BikeIdPlayerA,d0
                andi.w  #7,d0
                or.w    d0,$28(a0)
                move.w  #0,$2A(a0)
                move.w  #0,$2C(a0)
                move.w  #0,$2E(a0)
                lea     MenuPassword_ram_StrPlayerAPassword,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (DecodeString).w
                lea     MenuPassword_ram_StrPlayerAPassword,a0
                jsr     (MenuPassword_ValidatePassword).w
                lea     Intro_ram_ImageBuffer,a0
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
                lea     MenuPassword_ram_StrPlayerAPassword,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (DecodeString).w
                bra.w   @locret_3304
@loc_3126:
                lea     MenuPassword_ram_StrPlayerBPassword,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_PlayerBPlaces,a1
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
                move.l  ram_FF0514,d0
                andi.l  #$F8000,d0
                lsr.l   #8,d0
                lsr.l   #7,d0
                move.w  d0,$E(a0)
                move.l  ram_FF0514,d0
                andi.l  #$7C00,d0
                lsr.l   #8,d0
                lsr.l   #2,d0
                move.w  d0,$10(a0)
                move.l  ram_FF0514,d0
                andi.l  #$3E0,d0
                lsr.l   #5,d0
                move.w  d0,$12(a0)
                move.l  ram_FF0514,d0
                andi.l  #$1F,d0
                move.w  d0,$14(a0)
                move.l  Menu_ram_MoneyPlayerB,d0
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
                move.w  Menu_ram_PlayerBLevel,d0
                andi.w  #7,d0
                move.w  d0,$26(a0)
                move.w  ram_FF0524,d0
                lsl.w   #3,d0
                andi.w  #$18,d0
                move.w  d0,$28(a0)
                move.w  Menu_ram_BikeIdPlayerB,d0
                andi.w  #7,d0
                or.w    d0,$28(a0)
                move.w  #0,$2A(a0)
                move.w  #0,$2C(a0)
                move.w  #0,$2E(a0)
                lea     MenuPassword_ram_StrPlayerBPassword,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (DecodeString).w
                lea     MenuPassword_ram_StrPlayerBPassword,a0
                jsr     (MenuPassword_ValidatePassword).w
                lea     Intro_ram_ImageBuffer,a0
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
                lea     MenuPassword_ram_StrPlayerBPassword,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (DecodeString).w

@locret_3304:
                rts
; End of function MenuPassword_CreatePassword

; *************************************************
; Function MenuPassword_DrawNamesAndPasswords
; *************************************************

MenuPassword_DrawNamesAndPasswords:
; encode player A name
                lea     MenuPassword_ram_StrPlayerAName,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
; draw player A name
                lea     MenuPassword_ram_StrPlayerAName,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette 3
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                jsr     WriteNametableToBuffer
; encode player A password
                lea     MenuPassword_ram_StrPlayerAPassword,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
; draw player A password
                lea     MenuPassword_ram_StrPlayerAPassword,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette 3
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                jsr     WriteNametableToBuffer
; encode player B name
                lea     MenuPassword_ram_StrPlayerBName,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
; draw player B name
                lea     MenuPassword_ram_StrPlayerBName,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                jsr     WriteNametableToBuffer
; encode player B password
                lea     MenuPassword_ram_StrPlayerBPassword,a0
                lea     Intro_ram_ImageBuffer,a1
                jsr     (EncodeString).w
; draw player B password
                lea     MenuPassword_ram_StrPlayerBPassword,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$6000,d4
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                jsr     WriteNametableToBuffer
                rts
; End of function MenuPassword_DrawNamesAndPasswords
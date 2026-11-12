; *************************************************
; message.asm - bottom-screen tooltips, button prompts, shared strings/tables
; ROM range: $4226-$575F
; Status:    analyzed (static; icon layout/cadence not verified in BlastEm)
; API:       Message_ShowEmpty/Clear/ShowNoop, Message_Blink*, Message_MsgArray
; Data:      Str* text records, Menu_dRaceNameTable, DemoHighScoreTable,
;            Menu_dPasswordLabels, MenuPassword_StrStatusTemplate
; *************************************************

; *************************************************
; Function Message_ShowEmpty
; Clears the bottom 40x6 message field to the font space tile.
; In:       -
; Out:      Menu_ram_FrameBuffer rows 22-27 (x=0..39)
; Clobbers: d0-d3/d6, a0/a1
; Notes:    ROM $004226-$004269. Stages 120 longs (240 words = 40x6) in
;           Intro_ram_ImageBuffer and blits them at (0,22) through
;           WriteNametableToBuffer. Falls through into Message_ShowNoop, the
;           no-op show function used by the static-message entries.
; *************************************************

Message_ShowEmpty:
; 120 longs = 40x6 tile words
                move.w  #119,d0
; build one long holding two copies of the font space tile (code 36)
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                swap    d1
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                lea     (Intro_ram_ImageBuffer).l,a0
.loopFill:
                move.l  d1,(a0)+
                dbf     d0,.loopFill

; blit the staged 40x6 space field into the window frame buffer
                move.w  #40,d0 ; width in cells
                move.w  #6,d1 ; height in cells
                move.w  #0,d2 ; x
                move.w  #22,d3 ; y (bottom six rows of the 28-row window)
                move.w  #0,d4 ; base tile word: font tile 0, palette 0
                move.w  #64,d6 ; frame-buffer width in cells
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
; End of function Message_ShowEmpty

; *************************************************
; Function Message_ShowNoop
; No-op show function: returns immediately without drawing anything.
; In:       -
; Out:      -
; Clobbers: -
; Notes:    ROM $004268. This is the rts that ends Message_ShowEmpty; it is
;           also referenced directly as a show function (high-score index 42).
; *************************************************

Message_ShowNoop:
                rts ; no-op show function (static messages with no icon)
; End of function Message_ShowNoop

; *************************************************
; Function Message_Clear
; Clears the bottom 40x6 message field to the default/black tile.
; In:       -
; Out:      Menu_ram_FrameBuffer rows 22-27 (x=0..39)
; Clobbers: d0-d3/d6, a0/a1
; Notes:    ROM $00426A-$0042A9. Fills Intro_ram_ImageBuffer with 240 copies
;           of the tile word $07FF (default tile at VRAM $FFE0, index $7FF).
; *************************************************

Message_Clear:
; 120 longs = 40x6 tile words; $07FF is the black/default tile
                move.w  #119,d0
                move.l  #$7FF07FF,d1
                lea     (Intro_ram_ImageBuffer).l,a0
.loopClear:
                move.l  d1,(a0)+
                dbf     d0,.loopClear
; blit the staged 40x6 black field into the window frame buffer
                move.w  #40,d0 ; width in cells
                move.w  #6,d1 ; height in cells
                move.w  #0,d2 ; x
                move.w  #22,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_Clear

; *************************************************
; Function Message_BlinkButtonA
; Blinks the blue A-button icon in the message field.
; In:       Message_ram_ButtonBlinkCounter, Message_ram_ButtonBlinkPeriod
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $0042AA-$004301. Clears the field on every call, advances the
;           shared blink counter, and draws gamepad tile 4 at (10,25) while the
;           counter is in the low half of the period. Message_DrawButtonA is
;           the draw-only entry.
; *************************************************

Message_BlinkButtonA:
                bsr.s   Message_Clear ; start from the black field
; counter = (counter + 1) & period; callers use a (2^n)-1 period
                move.w  (Message_ram_ButtonBlinkCounter).l,d0
                move.w  (Message_ram_ButtonBlinkPeriod).l,d1
                addq.w  #1,d0
                and.w   d1,d0 ; wrap within the period
                move.w  d0,(Message_ram_ButtonBlinkCounter).l
                lsr.w   #1,d1 ; period/2 = number of "on" frames
                eori.w  #$FFFF,d1 ; mask = ~(period/2)
                and.w   d1,d0 ; nonzero in the off half
                beq.w   Message_DrawButtonA ; low half -> draw the icon
                rts
; End of function Message_BlinkButtonA

; *************************************************
; Function Message_DrawButtonA
; Draws the blue A-button tile at (10,25) without touching the blink phase.
; In:       -
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $0042D0-$004301. Draw-only entry used by Message_BlinkButtonA
;           and Message_BlinkButtonsAB.
; *************************************************

Message_DrawButtonA:
; draw blue "A" button
                move.w  #4,(Intro_ram_ImageBuffer).l ; gamepad tile 4
                move.w  #1,d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #25,d3 ; y
                move.w  #$2500,d4 ; tile $500 (VRAM $A000), palette line 1
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_DrawButtonA

; *************************************************
; Function Message_BlinkButtonB
; Blinks the B-button icon (two tiles at 11,24).
; In:       Message_ram_ButtonBlinkCounter, Message_ram_ButtonBlinkPeriod
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $004302-$004361. Same counter/phase arithmetic as
;           Message_BlinkButtonA; the B icon is tiles 5 (top) and 6 (bottom).
; *************************************************

Message_BlinkButtonB:
                bsr.w   Message_Clear
; same counter/phase arithmetic as Message_BlinkButtonA
                move.w  (Message_ram_ButtonBlinkCounter).l,d0
                move.w  (Message_ram_ButtonBlinkPeriod).l,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,(Message_ram_ButtonBlinkCounter).l
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   Message_DrawButtonB ; low half -> draw the icon
                rts
; End of function Message_BlinkButtonB

; *************************************************
; Function Message_DrawButtonB
; Draws the two-tile B-button icon at (11,24) without touching the blink phase.
; In:       -
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $00432A-$004361. Draw-only entry used by Message_BlinkButtonB
;           and Message_BlinkButtonsAB.
; *************************************************

Message_DrawButtonB:
; stage tile 5 over tile 6 (1x2 icon)
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  #5,(a0)+ ; top tile
                move.w  #6,(a0)+ ; bottom tile
                move.w  #1,d0 ; width
                move.w  #2,d1 ; height
                move.w  #11,d2 ; x
                move.w  #24,d3 ; y
                move.w  #$2500,d4 ; tile $500 (VRAM $A000), palette line 1
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_DrawButtonB

; *************************************************
; Function Message_BlinkButtonsAB
; Blinks the A and B button icons together.
; In:       Message_ram_ButtonBlinkCounter, Message_ram_ButtonBlinkPeriod
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $004362-$004391. Clears once, then draws A and B back-to-back
;           during the low half of the shared blink period.
; *************************************************

Message_BlinkButtonsAB:
                bsr.w   Message_Clear
; same counter/phase arithmetic as Message_BlinkButtonA
                move.w  (Message_ram_ButtonBlinkCounter).l,d0
                move.w  (Message_ram_ButtonBlinkPeriod).l,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,(Message_ram_ButtonBlinkCounter).l
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   .draw ; low half -> draw both icons
                rts
.draw:
                bsr.w   Message_DrawButtonA ; A at (10,25)
                bsr.s   Message_DrawButtonB ; B at (11,24)
                rts
; End of function Message_BlinkButtonsAB

; *************************************************
; Function Message_BlinkButtonC
; Blinks the C-button icon (two tiles at 12,24).
; In:       Message_ram_ButtonBlinkCounter, Message_ram_ButtonBlinkPeriod
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $004392-$0043F5. [static] The .draw path clears the field a
;           second time; the clear at entry is redundant. Tiles 7 (top) and 8
;           (bottom).
; *************************************************

Message_BlinkButtonC:
                bsr.w   Message_Clear
; same counter/phase arithmetic as Message_BlinkButtonA
                move.w  (Message_ram_ButtonBlinkCounter).l,d0
                move.w  (Message_ram_ButtonBlinkPeriod).l,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,(Message_ram_ButtonBlinkCounter).l
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   .draw ; low half -> draw the icon
                rts
.draw:
                bsr.w   Message_Clear ; redundant: already cleared at entry
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  #7,(a0)+ ; top tile
                move.w  #8,(a0)+ ; bottom tile
                move.w  #1,d0 ; width
                move.w  #2,d1 ; height
                move.w  #$C,d2 ; x = 12
                move.w  #$18,d3 ; y = 24
                move.w  #$2500,d4 ; tile $500 (VRAM $A000), palette line 1
                move.w  #$40,d6 ; plane width 64
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_BlinkButtonC

; *************************************************
; Function Message_BlinkButtonStart
; Blinks the Start-button icon (three tiles at 9,23).
; In:       Message_ram_ButtonBlinkCounter, Message_ram_ButtonBlinkPeriod
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $0043F6-$00445D. [static] The .draw path clears the field a
;           second time; the clear at entry is redundant. Tiles 9/$A/$B.
; *************************************************

Message_BlinkButtonStart:
                bsr.w   Message_Clear
; same counter/phase arithmetic as Message_BlinkButtonA
                move.w  (Message_ram_ButtonBlinkCounter).l,d0
                move.w  (Message_ram_ButtonBlinkPeriod).l,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,(Message_ram_ButtonBlinkCounter).l
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   .draw ; low half -> draw the icon
                rts
.draw:
                bsr.w   Message_Clear ; redundant: already cleared at entry
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  #9,(a0)+ ; gamepad tile 9
                move.w  #$A,(a0)+ ; tile $A
                move.w  #$B,(a0)+ ; tile $B
                move.w  #3,d0 ; width
                move.w  #1,d1 ; height
                move.w  #9,d2 ; x
                move.w  #23,d3 ; y
                move.w  #$2500,d4 ; tile $500 (VRAM $A000), palette line 1
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_BlinkButtonStart



; *************************************************
; Function Message_BlinkDirPadHorizontal
; Blinks the horizontal (left/right) part of the directional-pad icon (4x2 at 3,24).
; In:       Message_ram_ButtonBlinkCounter, Message_ram_ButtonBlinkPeriod
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $00445E-$0044D5. Message_MsgArray ids 61/62 use this function
;           directly for the shop left/right prompts, so it must remain a full
;           show function. Message_DrawDirPadHorizontalIcon is the draw-only entry.
; *************************************************

Message_BlinkDirPadHorizontal:
                bsr.w   Message_Clear
; same counter/phase arithmetic as Message_BlinkButtonA
                move.w  (Message_ram_ButtonBlinkCounter).l,d0
                move.w  (Message_ram_ButtonBlinkPeriod).l,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,(Message_ram_ButtonBlinkCounter).l
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   Message_DrawDirPadHorizontalIcon ; low half -> draw the icon
                rts
; End of function Message_BlinkDirPadHorizontal

; *************************************************
; Function Message_DrawDirPadHorizontalIcon
; Draws the horizontal (left/right) part of the directional-pad icon (4x2 at 3,24).
; In:       -
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $004486-$0044D5. Draw-only entry: it skips the clear and blink
;           test of Message_BlinkDirPadHorizontal and is called by
;           Message_BlinkDirectionalPad.
; *************************************************

Message_DrawDirPadHorizontalIcon:
; 4x2 row-major left/right pair:
; row 0 = 0, blank, blank, 2; row 1 = 1, blank, blank, 3
; ($2FF + base $2500 = $27FF -> default blank tile $7FF, palette 1)
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  #0,(a0)+
                move.w  #$2FF,(a0)+ ; blank
                move.w  #$2FF,(a0)+ ; blank
                move.w  #2,(a0)+
                move.w  #1,(a0)+
                move.w  #$2FF,(a0)+ ; blank
                move.w  #$2FF,(a0)+ ; blank
                move.w  #3,(a0)+
                move.w  #4,d0 ; width
                move.w  #2,d1 ; height
                move.w  #3,d2 ; x
                move.w  #$18,d3 ; y = 24
                move.w  #$2500,d4 ; tile $500 (VRAM $A000), palette line 1
                move.w  #$40,d6 ; plane width 64
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_DrawDirPadHorizontalIcon


; *************************************************
; Function Message_BlinkDirPadVertical
; Blinks the vertical (up/down) part of the directional-pad icon (2x4 at 4,23).
; In:       Message_ram_ButtonBlinkCounter, Message_ram_ButtonBlinkPeriod
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $0044D6-$00454D. Message_DrawDirPadVerticalIcon is the draw-only
;           entry used by Message_BlinkDirectionalPad.
; *************************************************

Message_BlinkDirPadVertical:
                bsr.w   Message_Clear
; same counter/phase arithmetic as Message_BlinkButtonA
                move.w  (Message_ram_ButtonBlinkCounter).l,d0
                move.w  (Message_ram_ButtonBlinkPeriod).l,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,(Message_ram_ButtonBlinkCounter).l
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   Message_DrawDirPadVerticalIcon ; low half -> draw the icon
                rts
; End of function Message_BlinkDirPadVertical

; *************************************************
; Function Message_DrawDirPadVerticalIcon
; Draws the vertical (up/down) part of the directional-pad icon (2x4 at 4,23).
; In:       -
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $0044FE-$00454D. Draw-only entry called by
;           Message_BlinkDirectionalPad.
; *************************************************

Message_DrawDirPadVerticalIcon:
; 2x4 row-major up/down pair: row 0 = $C,$D; rows 1/2 = blanks; row 3 = $E,$F
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  #$C,(a0)+
                move.w  #$D,(a0)+
                move.w  #$2FF,(a0)+ ; blank
                move.w  #$2FF,(a0)+ ; blank
                move.w  #$2FF,(a0)+ ; blank
                move.w  #$2FF,(a0)+ ; blank
                move.w  #$E,(a0)+
                move.w  #$F,(a0)+
                move.w  #2,d0 ; width
                move.w  #4,d1 ; height
                move.w  #4,d2 ; x
                move.w  #$17,d3 ; y = 23
                move.w  #$2500,d4 ; tile $500 (VRAM $A000), palette line 1
                move.w  #$40,d6 ; plane width 64
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_DrawDirPadVerticalIcon

; *************************************************
; Function Message_BlinkDirectionalPad
; Blinks the complete directional-pad icon.
; In:       Message_ram_ButtonBlinkCounter, Message_ram_ButtonBlinkPeriod
; Out:      Menu_ram_FrameBuffer message field
; Clobbers: d0-d4/d6, a0/a1
; Notes:    ROM $00454E-$00457D. Clears once, then calls the draw-only entries
;           of the horizontal and vertical parts; they do not re-clear or
;           re-check the blink phase.
; *************************************************

Message_BlinkDirectionalPad:
                bsr.w   Message_Clear
; same counter/phase arithmetic as Message_BlinkButtonA
                move.w  (Message_ram_ButtonBlinkCounter).l,d0
                move.w  (Message_ram_ButtonBlinkPeriod).l,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,(Message_ram_ButtonBlinkCounter).l
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   .draw ; low half -> draw both halves
                rts
.draw:
                bsr.w   Message_DrawDirPadHorizontalIcon ; 4x2 at (3,24)
                bsr.s   Message_DrawDirPadVerticalIcon ; 2x4 at (4,23)
                rts
; End of function Message_BlinkDirectionalPad

; *************************************************
; Message_MsgArray
; 8-byte entries: dc.l text_record,show_function.
; Menu_ram_CurrentMessageId is a byte offset (always a multiple of 8), so the
; entry index is id/8. A show function of $FFFFFFFF is a group terminator; a
; text pointer of $FFFFFFFF means "no text". A $FFFFFFFF,$FFFFFFFF pair ends
; each group. The text records below use the shared y,x,height,width header.
; *************************************************

Message_MsgArray:
; Main-menu status messages (0-5): result of a player-mode/music/password action
    dc.l StrOnePlayerModeSelected,Message_ShowEmpty
    dc.l StrTwoPlayerModeSelected,Message_ShowEmpty
    dc.l StrMusicOn,Message_ShowEmpty
    dc.l StrMusicOff,Message_ShowEmpty
    dc.l Menu_ram_TempString,Message_ShowEmpty ; race-name/distance tooltip
    dc.l MenuPassword_StrPasswordStatus,Message_ShowEmpty
; Main-menu tooltips (6-10): text + blinking controller icon
    dc.l Message_StrPressStartToRace,Message_BlinkButtonStart ; index 6
    dc.l Message_StrPressAPlayerSelection,Message_BlinkButtonA
    dc.l Message_StrPressBMusicToggle,Message_BlinkButtonB
    dc.l Message_StrPressCPassword,Message_BlinkButtonC
    dc.l Message_StrDirPadSelectTrack,Message_BlinkDirectionalPad
    dc.l $FFFFFFFF,$FFFFFFFF
; Password-screen tooltips (12-15)
    dc.l StrPressStartToExit,Message_BlinkButtonStart ; index 12
    dc.l StrPressABToChangeLetter,Message_BlinkButtonsAB
    dc.l StrPressCToSelectOtherPlayer,Message_BlinkButtonC
    dc.l StrUseDirPadToMoveCursor,Message_BlinkDirectionalPad
    dc.l $FFFFFFFF,$FFFFFFFF

; Rider-intro messages (17-19). The screen starts at index 18, so index 17 is
; an unreached blank entry; index 19 is the Start-to-exit prompt.
    dc.l Message_StrBlank,Message_ShowEmpty ; index 17 (unused)
    dc.l Message_StrBlank,Message_ShowEmpty
    dc.l StrPressStartToExit,Message_BlinkButtonStart
    dc.l $FFFFFFFF,$FFFFFFFF

; Race results, course incomplete (21-26)
    dc.l MenuPassword_StrPasswordStatus,Message_ShowEmpty ; index 21
    dc.l Message_StrCompleteEveryCourse,Message_ShowEmpty
    dc.l Message_StrPressStartTrackSelection,Message_BlinkButtonStart
    dc.l Message_StrPressAHighScores,Message_BlinkButtonA
    dc.l Message_StrPressBRaceResults,Message_BlinkButtonB
    dc.l Message_StrPressCNewBikes,Message_BlinkButtonC
    dc.l $FFFFFFFF,$FFFFFFFF

; Race results, worse than 4th place (28-33)
    dc.l MenuPassword_StrPasswordStatus,Message_ShowEmpty ; index 28
    dc.l Message_StrComplete4thPlace,Message_ShowEmpty
    dc.l Message_StrPressStartTrackSelection,Message_BlinkButtonStart
    dc.l Message_StrPressAHighScores,Message_BlinkButtonA
    dc.l Message_StrPressBRaceResults,Message_BlinkButtonB
    dc.l Message_StrPressCNewBikes,Message_BlinkButtonC
    dc.l $FFFFFFFF,$FFFFFFFF

; Race results, level cleared (35-40); ram_FF089A is the live congratulations text
    dc.l MenuPassword_StrPasswordStatus,Message_ShowEmpty ; index 35
    dc.l ram_FF089A,Message_ShowEmpty
    dc.l Message_StrPressStartTrackSelection,Message_BlinkButtonStart
    dc.l Message_StrPressAHighScores,Message_BlinkButtonA
    dc.l Message_StrPressBRaceResults,Message_BlinkButtonB
    dc.l Message_StrPressCNewBikes,Message_BlinkButtonC
    dc.l $FFFFFFFF,$FFFFFFFF

; High-score screen (42-46): one blank cell plus the standard prompts
    dc.l Message_StrBlankCell,Message_ShowNoop ; index 42
    dc.l Message_StrPressStartTrackSelection,Message_BlinkButtonStart
    dc.l Message_StrPressAHighScores,Message_BlinkButtonA
    dc.l Message_StrPressBRaceResults,Message_BlinkButtonB
    dc.l Message_StrPressCNewBikes,Message_BlinkButtonC
    dc.l $FFFFFFFF,$FFFFFFFF

; End-level / victory screen (48-49)
    dc.l Message_StrBlank,Message_ShowEmpty ; index 48
    dc.l Message_StrPressStartTrackSelection,Message_BlinkButtonStart
    dc.l $FFFFFFFF,$FFFFFFFF
; Shop bike descriptions (51-58), selected by index 51+bikeId
    dc.l Message_StrBikeDescShuriken400,Message_ShowEmpty ; index 51
    dc.l Message_StrBikeDescPanda600,Message_ShowEmpty
    dc.l Message_StrBikeDescBanzai750,Message_ShowEmpty
    dc.l Message_StrBikeDescKamikaze750,Message_ShowEmpty
    dc.l Message_StrBikeDescShuriken1000,Message_ShowEmpty
    dc.l Message_StrBikeDescFerruci850,Message_ShowEmpty
    dc.l Message_StrBikeDescPanda750,Message_ShowEmpty
    dc.l Message_StrBikeDescDiablo1000,Message_ShowEmpty

; Shop tooltips (59-66): dynamic owned/cannot-afford string (index 59),
; trade-in note, left/right bike prompts, and the standard Start/A/B/C prompts.
; Shop_GameTick cycles 60-66; index 59 is selected by the two dynamic builders.
    dc.l ram_FF089A,Message_ShowEmpty ; index 59
    dc.l Message_StrTradeInCredit,Message_ShowEmpty
    dc.l ram_FF07C2,Message_BlinkDirPadHorizontal
    dc.l ram_FF082E,Message_BlinkDirPadHorizontal
    dc.l Shop_StrBuyNewBike,Message_BlinkButtonC
    dc.l Message_StrPressStartTrackSelection,Message_BlinkButtonStart
    dc.l Message_StrPressAHighScores,Message_BlinkButtonA
    dc.l Message_StrPressBRaceResults,Message_BlinkButtonB
    dc.l $FFFFFFFF,$FFFFFFFF

; Fixed text records. Layout: dc.w y,x,height,width then height*width ASCII
; bytes. EncodeString maps the bytes through dStringCodeTable to font tiles.
StrPressStartToExit: ; 1x22, rider-intro/end-level exit prompt
    dc.w 24,16,1,22
    dc.b "Press ",$22,"Start",$22," to exit "
StrPressABToChangeLetter: ; 3x20 password edit prompt
    dc.w 23,16,3,20
    dc.b " Press ",$22,"A",$22," or ",$22,"B",$22," to  "
    dc.b "                    "
    dc.b " change a letter  "
StrPressCToSelectOtherPlayer: ; 3x20 password player-switch prompt
    dc.w 23,16,3,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b " select other player"
StrUseDirPadToMoveCursor: ; 3x20 password cursor prompt
    dc.w 23,16,3,20
    dc.b " Use Directional pad"
    dc.b "                    "
    dc.b "   to move cursor   "
StrOnePlayerModeSelected: ; 5x20 main-menu confirmation
    dc.w 22,10,5,20
    dc.b "         1          "
    dc.b "                    "
    dc.b "    Player Mode     "
    dc.b "                    "
    dc.b "     Selected       "
StrTwoPlayerModeSelected: ; 5x20 main-menu confirmation
    dc.w 22,10,5,20
    dc.b "         2          "
    dc.b "                    "
    dc.b "    Player Mode     "
    dc.b "                    "
    dc.b "     Selected       "
StrMusicOn: ; 3x20 main-menu confirmation
    dc.w 23,10,3,20
    dc.b "    Music is now    "
    dc.b "                    "
    dc.b "        ON          "
StrMusicOff: ; 3x20 main-menu confirmation
    dc.w 23,10,3,20
    dc.b "    Music is now    "
    dc.b "                    "
    dc.b "        OFF         "

; Five long pointers to the race-name records below. Track ids are even
; (0,2,4,6,8), so Menu_BuildRaceTooltip uses byte offset id*2 and lands on
; entries 0..4.
Menu_dRaceNameTable:
    dc.l Menu_StrRaceSierraNevada,Menu_StrRacePacificCoast,Menu_StrRaceRedwoodForest,Menu_StrRacePalmDesert,Menu_StrRaceGrassValley

; The fifth line of each record is "          miles". Menu_BuildRaceTooltip
; writes a one-decimal distance backwards from the character just before
; "miles" (offset 97): fractional digit, '.', then the integer digits. Shorter
; values leave the leading spaces of the 10-cell field intact.
Menu_StrRaceSierraNevada:
    dc.w 22,10,5,20
    dc.b "   The next race    "
    dc.b "   will be in the   "
    dc.b "                    "
    dc.b "    Sierra Nevada   "
    dc.b "          miles     "
Menu_StrRacePacificCoast:
    dc.w 22,10,5,20
    dc.b "   The next race    "
    dc.b "   will be on the   "
    dc.b "                    "
    dc.b "    Pacific Coast   "
    dc.b "          miles     "
Menu_StrRaceRedwoodForest:
    dc.w 22,10,5,20
    dc.b "   The next race    "
    dc.b "   will be in the   "
    dc.b "                    "
    dc.b "   Redwood Forest   "
    dc.b "          miles     "
Menu_StrRacePalmDesert:
    dc.w 22,10,5,20
    dc.b "    The next race   "
    dc.b "   will be in the   "
    dc.b "                    "
    dc.b "     Palm Desert    "
    dc.b "          miles     "
Menu_StrRaceGrassValley:
    dc.w 22,10,5,20
    dc.b "    The next race   "
    dc.b "     will be in     "
    dc.b "                    "
    dc.b "    Grass Valley    "
    dc.b "          miles     "

; 7 rows x 20 characters (140 bytes = the full 7x20 high-score table body).
; Intro_Init copies it into HighScore_ram_Table after writing the 8-byte text
; header and then replaces the Player A/B rows from the profile names.
DemoHighScoreTable:
    dc.b "Fang         $51,320"
    dc.b "Helldog      $44,790"
    dc.b "Lubster      $34,260"
    dc.b "Natasha      $29,990"
    dc.b "Sergio       $23,440"
    dc.b "Player A          $0"
    dc.b "Player B          $0"

; Main-menu tooltip records (Message_MsgArray indices 6-10).
Message_StrPressStartToRace:
    dc.w 23,16,3,20
    dc.b "   Press ",$22,"Start",$22,"    "
    dc.b "                    "
    dc.b "      to race       "

Message_StrPressAPlayerSelection:
    dc.w 23,16,3,20
    dc.b "   Press ",$22,"A",$22," for    "
    dc.b "                    "
    dc.b "  Player Selection  "

Message_StrPressBMusicToggle:
    dc.w 23,16,3,20
    dc.b "  Press ",$22,"B",$22," to turn "
    dc.b "                    "
    dc.b "   Music ON or OFF  "

Message_StrPressCPassword:
    dc.w 22,16,5,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b "  Enter a password  "
    dc.b "                    "
    dc.b "  or a player name  "

Message_StrDirPadSelectTrack:
    dc.w 23,16,3,20
    dc.b " Use Directional pad"
    dc.b "                    "
    dc.b " select a new track "

; 5x16 status template copied into MenuPassword_StrPasswordStatus by
; MenuPassword_UpdateStatus. Row 0 receives the centred player name, row 2 is
; changed to "PASSWORD   VALID" when the checksum passes, and row 4's level
; digit is refreshed from the active player's level.
MenuPassword_StrStatusTemplate:
    dc.w 22,12,5,16
    dc.b "   PLAYERNAME   "
    dc.b "                "
    dc.b "PASSWORD INVALID"
    dc.b "                "
    dc.b "OLD LEVEL IS: 0 "

; 5x20 all-space record used when a group needs a blank field but not the
; black clearing of Message_Clear.
Message_StrBlank:
    dc.w 22,16,5,20
    dc.b "                    "
    dc.b "                    "
    dc.b "                    "
    dc.b "                    "
    dc.b "                    "

; 1x1 blank cell for the high-score group. The header makes EncodeString
; consume one character; the second space at $4EEC+1 is alignment padding
; before Menu_dPasswordLabels.
Message_StrBlankCell:
    dc.w 27,1,1,1
    dc.b "  "

; 7x12 "Name"/"Password" label record. Menu_DrawPlayerInfo encodes it once and
; blits it at x=4 and x=24 with palette 3 (base word $6000).
Menu_dPasswordLabels:
    dc.w 8,4,7,12
    dc.b "    Name    "
    dc.b "            "
    dc.b "            "
    dc.b "            "
    dc.b "            "
    dc.b "            "
    dc.b "  Password  "

; Standard Start/A/B/C prompt records reused by the race-results (23-26),
; high-score (43-46), end-level (49) and shop (64-66) message groups.
Message_StrPressAHighScores:
    dc.w 22,16,5,20
    dc.b "      Press ",$22,"A",$22,"     "
    dc.b "                    "
    dc.b "    to check out    "
    dc.b "                    "
    dc.b "     High Scores    "

Message_StrPressCNewBikes:
    dc.w 23,16,3,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b "check out new bikes "

Message_StrPressStartTrackSelection:
    dc.w 23,16,3,20
    dc.b "Press ",$22,"Start",$22," to go "
    dc.b "                    "
    dc.b " to Track Selection "

Message_StrPressBRaceResults:
    dc.w 22,16,5,20
    dc.b " Press ",$22,"B",$22," to check "
    dc.b "                    "
    dc.b "  out Race Results, "
    dc.b "                    "
    dc.b " cash, and password."

Message_StrPressCBuyNewBike:
    dc.w 22,16,5,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b "      buy a new     "
    dc.b "                    "
    dc.b "                    "

Message_StrPressLeftDirPad:
    dc.w 22,16,4,20
    dc.b "   Press Left on    "
    dc.b "  Directional Pad   "
    dc.b "  to check out the  "
    dc.b "                    "

Message_StrPressRightDirPad:
    dc.w 22,16,4,20
    dc.b "   Press Right on   "
    dc.b "  Directional Pad   "
    dc.b "  to check out the  "
    dc.b "                    "

; Shop dynamic-message prefixes. Shop_ShowAlreadyOwned/ShowCannotAfford copy
; these records into ram_FF089A and append the current bike name on the
; two rows that end in "a".
Message_StrAlreadyOwnBike:
    dc.w 23,10,3,20
    dc.b " You already own a  "
    dc.b "                    "
    dc.b "                    "

Message_StrNeedMoreCredit:
    dc.w 22,10,5,20
    dc.b "   You need more    "
    dc.b "                    "
    dc.b "  credit to buy a   "
    dc.b "                    "
    dc.b "                    "

; Race-results outcome texts: group 21 (course incomplete), group 28 (worse
; than 4th place), group 35 (level cleared; the trailing '1' is patched).
Message_StrCompleteEveryCourse:
    dc.w 22,10,4,20
    dc.b " You must complete  "
    dc.b "    every course    "
    dc.b " before you can go  "
    dc.b " to the next level  "

Message_StrComplete4thPlace:
    dc.w 22,10,5,20
    dc.b " You must complete  "
    dc.b "  every course in   "
    dc.b "4th place or better "
    dc.b " before you can go  "
    dc.b " to the next level  "

; RaceResults_Init copies this record to ram_FF089A and adds the current
; Menu_ram_PlayerLevel (clamped to 4) to the ASCII '1' at row 4, column 14.
; @UNKNOWN(U-0006): intended displayed level | guess: the text shows the next
; level because the level is 1-based elsewhere | next: compare this text with
; the current/next level in BlastEm at levels 1 and 5
Message_StrCongratulations:
    dc.w 22,10,5,20
    dc.b "  Congratulations!  "
    dc.b "   you have raced   "
    dc.b "   well, try some   "
    dc.b " harder competition "
    dc.b "     on level 1     "

; Shop group 60: explains that the purchase credit includes the trade-in value
; of the player's current bike.
Message_StrTradeInCredit:
    dc.w 22,10,4,20
    dc.b "Your credit for bike"
    dc.b " purchase includes  "
    dc.b " the trade in value "
    dc.b "  of your old bike. "

; One prose record per bike id 0..7; Shop_ShowBikeDescription selects
; index 51+bikeId in Message_MsgArray. The order matches Shop_BikeDescriptions
; (Shuriken 400, Panda 600, Banzai 750, Kamikaze 750, Shuriken 1000,
; Ferruci 850, Panda 750, Diablo 1000).
Message_StrBikeDescShuriken400:
    dc.w 23,4,3,32
    dc.b "Big on Handling, short on power."
    dc.b "It's important to maintain speed"
    dc.b "through the corners on this one."

Message_StrBikeDescPanda600:
    dc.w 23,6,3,28
    dc.b "Good all-around sport bike. "
    dc.b "Light steering but lacks    "
    dc.b "mid-range performance.      "

Message_StrBikeDescBanzai750:
    dc.w 23,5,3,30
    dc.b "Crisp handling with good power"
    dc.b "at high RPM but no mid-range. "
    dc.b "Try and keep the revs high.   "

Message_StrBikeDescKamikaze750:
    dc.w 23,4,2,32
    dc.b "Slower steering, but bigger     "
    dc.b "mid-range power than the Banzai."

Message_StrBikeDescShuriken1000:
    dc.w 23,6,3,28
    dc.b "Extreme speed but its size  "
    dc.b "makes for slower turning and"
    dc.b "stopping. Plan your turns.  "

Message_StrBikeDescFerruci850:
    dc.w 23,6,3,28
    dc.b "V-twin torque and razor     "
    dc.b "sharp handling. Reliability "
    dc.b "could be a problem.         "

Message_StrBikeDescPanda750:
    dc.w 23,5,2,30
    dc.b "Big V4 mid-range power and    "
    dc.b "magic handling at a big price."

Message_StrBikeDescDiablo1000:
    dc.w 23,5,2,30
    dc.b "Fuel injected horse power and "
    dc.b "awesome Italian handling.     "

; Busted-screen messages: RaceResults_DrawBusted copies the "Caught by the
; cops" record and formats the fine, or draws the GAME OVER variant when the
; player cannot pay bail.
Message_StrCaughtByCops:
    dc.w 18,16,2,18
    dc.b "Caught by the cops"
    dc.b " Your fine -      "

Message_StrCantAffordBail:
    dc.w 18,16,2,18
    dc.b "Can't afford bail "
    dc.b "    GAME OVER     "

; Repair-screen messages: RaceResults_DrawRepair copies the repair record and
; formats the amount, or draws the GAME OVER variant when money is negative.
Message_StrBikeNeedsRepairs:
    dc.w 18,16,2,18
    dc.b " Your bike needs  "
    dc.b " repairs  -       "

Message_StrNoMoneyForRepairs:
    dc.w 18,16,2,20
    dc.b "No money for repairs"
    dc.b "     GAME OVER      "
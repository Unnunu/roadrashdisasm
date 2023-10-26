; *************************************************
; Function Message_ShowEmpty
; *************************************************

Message_ShowEmpty:
; fill message field with spaces
                move.w  #119,d0
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                swap    d1
                move.w  (dStringCodeTable + 2 * ' ').w,d1
                lea     Intro_ram_ImageBuffer,a0
@loopFill:
                move.l  d1,(a0)+
                dbf     d0,@loopFill

                move.w  #40,d0 ; width
                move.w  #6,d1 ; height
                move.w  #0,d2 ; x
                move.w  #22,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
sub_4268:
                rts
; End of function Message_ShowEmpty

; *************************************************
; Function Message_Clear
; *************************************************

Message_Clear:
; clear message field
                move.w  #119,d0
                move.l  #$7FF07FF,d1
                lea     Intro_ram_ImageBuffer,a0
@loopClear:
                move.l  d1,(a0)+
                dbf     d0,@loopClear
; write it to framebuffer
                move.w  #40,d0 ; width
                move.w  #6,d1 ; height
                move.w  #0,d2 ; x
                move.w  #22,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_Clear

; *************************************************
; Function Message_BlinkButtonA
; *************************************************

Message_BlinkButtonA:
                bsr.s   Message_Clear
                move.w  Message_ram_ButtonBlinkCounter,d0
                move.w  Message_ram_ButtonBlinkPeriod,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,Message_ram_ButtonBlinkCounter
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   Message_DrawButtonA
                rts
Message_DrawButtonA:
; draw blue "A" button
                move.w  #4,Intro_ram_ImageBuffer ; tile #4
                move.w  #1,d0 ; width
                move.w  #1,d1 ; height
                move.w  #10,d2 ; x
                move.w  #25,d3 ; y
                move.w  #$2500,d4 ; base tile index = $500, address = $A000, palette line = 1
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0 ; source
                lea     Menu_ram_FrameBuffer,a1 ; destination
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_BlinkButtonA

; *************************************************
; Function Message_BlinkButtonB
; *************************************************

Message_BlinkButtonB:
                bsr.w   Message_Clear
                move.w  Message_ram_ButtonBlinkCounter,d0
                move.w  Message_ram_ButtonBlinkPeriod,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,Message_ram_ButtonBlinkCounter
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   Message_DrawButtonB
                rts
Message_DrawButtonB:
                lea     Intro_ram_ImageBuffer,a0
                move.w  #5,(a0)+ ; tile #5
                move.w  #6,(a0)+ ; and tile #6
                move.w  #1,d0 ; width
                move.w  #2,d1 ; height
                move.w  #11,d2 ; x
                move.w  #24,d3 ; y
                move.w  #$2500,d4 ; base tile index = $500, address = $A000, palette line = 1
                move.w  #64,d6 ; plane width
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_BlinkButtonB

; *************************************************
; Function Message_BlinkButtonsAB
; *************************************************

Message_BlinkButtonsAB:
                bsr.w   Message_Clear
                move.w  Message_ram_ButtonBlinkCounter,d0
                move.w  Message_ram_ButtonBlinkPeriod,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,Message_ram_ButtonBlinkCounter
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   @draw
                rts
@draw:
                bsr.w   Message_DrawButtonA
                bsr.s   Message_DrawButtonB
                rts
; End of function Message_BlinkButtonsAB

; *************************************************
; Function Message_BlinkButtonC
; *************************************************

Message_BlinkButtonC:
                bsr.w   Message_Clear
                move.w  Message_ram_ButtonBlinkCounter,d0
                move.w  Message_ram_ButtonBlinkPeriod,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,Message_ram_ButtonBlinkCounter
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   @draw
                rts
@draw:
                bsr.w   Message_Clear
                lea     Intro_ram_ImageBuffer,a0
                move.w  #7,(a0)+
                move.w  #8,(a0)+
                move.w  #1,d0
                move.w  #2,d1
                move.w  #$C,d2
                move.w  #$18,d3
                move.w  #$2500,d4
                move.w  #$40,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_BlinkButtonC

; *************************************************
; Function Message_BlinkButtonStart
; *************************************************

Message_BlinkButtonStart:
                bsr.w   Message_Clear
                move.w  Message_ram_ButtonBlinkCounter,d0
                move.w  Message_ram_ButtonBlinkPeriod,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,Message_ram_ButtonBlinkCounter
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   @draw
                rts
@draw:
                bsr.w   Message_Clear
                lea     Intro_ram_ImageBuffer,a0
                move.w  #9,(a0)+
                move.w  #$A,(a0)+
                move.w  #$B,(a0)+
                move.w  #3,d0
                move.w  #1,d1
                move.w  #9,d2
                move.w  #23,d3
                move.w  #$2500,d4
                move.w  #64,d6
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function Message_BlinkButtonStart



sub_445E:
                bsr.w   Message_Clear
                move.w  Message_ram_ButtonBlinkCounter,d0
                move.w  Message_ram_ButtonBlinkPeriod,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,Message_ram_ButtonBlinkCounter
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   loc_4486
                rts
loc_4486:
                lea     Intro_ram_ImageBuffer,a0
                move.w  #0,(a0)+
                move.w  #$2FF,(a0)+
                move.w  #$2FF,(a0)+
                move.w  #2,(a0)+
                move.w  #1,(a0)+
                move.w  #$2FF,(a0)+
                move.w  #$2FF,(a0)+
                move.w  #3,(a0)+
                move.w  #4,d0
                move.w  #2,d1
                move.w  #3,d2
                move.w  #$18,d3
                move.w  #$2500,d4
                move.w  #$40,d6 ; '@'
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function sub_445E


; =============== S U B R O U T I N E =======================================


sub_44D6:
                bsr.w   Message_Clear
                move.w  Message_ram_ButtonBlinkCounter,d0
                move.w  Message_ram_ButtonBlinkPeriod,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,Message_ram_ButtonBlinkCounter
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   loc_44FE
                rts
loc_44FE:
                lea     Intro_ram_ImageBuffer,a0
                move.w  #$C,(a0)+
                move.w  #$D,(a0)+
                move.w  #$2FF,(a0)+
                move.w  #$2FF,(a0)+
                move.w  #$2FF,(a0)+
                move.w  #$2FF,(a0)+
                move.w  #$E,(a0)+
                move.w  #$F,(a0)+
                move.w  #2,d0
                move.w  #4,d1
                move.w  #4,d2
                move.w  #$17,d3
                move.w  #$2500,d4
                move.w  #$40,d6 ; '@'
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function sub_44D6

; *************************************************
; Function Message_BlinkDirectionalPad
; *************************************************

Message_BlinkDirectionalPad:
                bsr.w   Message_Clear
                move.w  Message_ram_ButtonBlinkCounter,d0
                move.w  Message_ram_ButtonBlinkPeriod,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,Message_ram_ButtonBlinkCounter
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   @draw
                rts
@draw:
                bsr.w   loc_4486
                bsr.s   loc_44FE
                rts
; End of function Message_BlinkDirectionalPad

Message_MsgArray:
; Main menu
    dc.l StrOnePlayerModeSelected,Message_ShowEmpty
    dc.l StrTwoPlayerModeSelected,Message_ShowEmpty
    dc.l StrMusicOn,Message_ShowEmpty
    dc.l StrMusicOff,Message_ShowEmpty
    dc.l Menu_ram_TempString,Message_ShowEmpty
    dc.l MenuPassword_StrPasswordStatus,Message_ShowEmpty
; Main menu tooltips 
    dc.l unk_4CA4,Message_BlinkButtonStart ; index 6
    dc.l unk_4CE8,Message_BlinkButtonA
    dc.l unk_4D2C,Message_BlinkButtonB
    dc.l unk_4D70,Message_BlinkButtonC
    dc.l unk_4DDC,Message_BlinkDirectionalPad
    dc.l $FFFFFFFF,$FFFFFFFF
; Password menu tooltips
    dc.l StrPressStartToExit,Message_BlinkButtonStart ; index 12
    dc.l StrPressABToChangeLetter,Message_BlinkButtonsAB
    dc.l StrPressCToSelectOtherPlayer,Message_BlinkButtonC
    dc.l StrUseDirPadToMoveCursor,Message_BlinkDirectionalPad
    dc.l $FFFFFFFF,$FFFFFFFF

    dc.l unk_4E78,Message_ShowEmpty ; index 17
    dc.l unk_4E78,Message_ShowEmpty
    dc.l StrPressStartToExit,Message_BlinkButtonStart
    dc.l $FFFFFFFF,$FFFFFFFF

    dc.l MenuPassword_StrPasswordStatus,Message_ShowEmpty ; index 21
    dc.l unk_5276,Message_ShowEmpty
    dc.l unk_4FFA,Message_BlinkButtonStart
    dc.l unk_4F4A,Message_BlinkButtonA
    dc.l unk_503E,Message_BlinkButtonB
    dc.l unk_4FB6,Message_BlinkButtonC
    dc.l $FFFFFFFF,$FFFFFFFF

    dc.l MenuPassword_StrPasswordStatus,Message_ShowEmpty ; index 28
    dc.l unk_52CE,Message_ShowEmpty
    dc.l unk_4FFA,Message_BlinkButtonStart
    dc.l unk_4F4A,Message_BlinkButtonA
    dc.l unk_503E,Message_BlinkButtonB
    dc.l unk_4FB6,Message_BlinkButtonC
    dc.l $FFFFFFFF,$FFFFFFFF

    dc.l MenuPassword_StrPasswordStatus,Message_ShowEmpty ; index 35
    dc.l ram_FF089A,Message_ShowEmpty
    dc.l unk_4FFA,Message_BlinkButtonStart
    dc.l unk_4F4A,Message_BlinkButtonA
    dc.l unk_503E,Message_BlinkButtonB
    dc.l unk_4FB6,Message_BlinkButtonC
    dc.l $FFFFFFFF,$FFFFFFFF
; High score menu tooltips
    dc.l unk_4EE4,sub_4268 ; index 42
    dc.l unk_4FFA,Message_BlinkButtonStart
    dc.l unk_4F4A,Message_BlinkButtonA
    dc.l unk_503E,Message_BlinkButtonB
    dc.l unk_4FB6,Message_BlinkButtonC
    dc.l $FFFFFFFF,$FFFFFFFF

    dc.l unk_4E78,Message_ShowEmpty ; index 48
    dc.l unk_4FFA,Message_BlinkButtonStart
    dc.l $FFFFFFFF,$FFFFFFFF
; bike descriptions in shop
    dc.l unk_53FE,Message_ShowEmpty ; index 51
    dc.l unk_5466,Message_ShowEmpty
    dc.l unk_54C2,Message_ShowEmpty
    dc.l unk_5524,Message_ShowEmpty
    dc.l unk_556C,Message_ShowEmpty
    dc.l unk_55C8,Message_ShowEmpty
    dc.l unk_5624,Message_ShowEmpty
    dc.l unk_5668,Message_ShowEmpty

    dc.l ram_FF089A,Message_ShowEmpty ; index 59
    dc.l unk_53A6,Message_ShowEmpty
    dc.l ram_FF07C2,sub_445E
    dc.l ram_FF082E,sub_445E
    dc.l Shop_StrBuyNewBike,Message_BlinkButtonC
    dc.l unk_4FFA,Message_BlinkButtonStart
    dc.l unk_4F4A,Message_BlinkButtonA
    dc.l unk_503E,Message_BlinkButtonB
    dc.l $FFFFFFFF,$FFFFFFFF

StrPressStartToExit:
    dc.w 24,16,1,22
    dc.b "Press ",$22,"Start",$22," to exit "
StrPressABToChangeLetter:
    dc.w 23,16,3,20
    dc.b " Press ",$22,"A",$22," or ",$22,"B",$22," to  "
    dc.b "                    "
    dc.b " change a letter  "
StrPressCToSelectOtherPlayer:
    dc.w 23,16,3,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b " select other player"
StrUseDirPadToMoveCursor:
    dc.w 23,16,3,20
    dc.b " Use Directional pad"
    dc.b "                    "
    dc.b "   to move cursor   "
StrOnePlayerModeSelected:
    dc.w 22,10,5,20
    dc.b "         1          "
    dc.b "                    "
    dc.b "    Player Mode     "
    dc.b "                    "
    dc.b "     Selected       "
StrTwoPlayerModeSelected:
    dc.w 22,10,5,20
    dc.b "         2          "
    dc.b "                    "
    dc.b "    Player Mode     "
    dc.b "                    "
    dc.b "     Selected       "
StrMusicOn:
    dc.w 23,10,3,20
    dc.b "    Music is now    "
    dc.b "                    "
    dc.b "        ON          "
StrMusicOff:
    dc.w 23,10,3,20
    dc.b "    Music is now    "
    dc.b "                    "
    dc.b "        OFF         "

unk_49E8:
    dc.l unk_49FC,unk_4AE8,unk_4AD4,unk_4B40,unk_4BAC

unk_49FC:
    dc.w 22,10,5,20
    dc.b "   The next race    "
    dc.b "   will be in the   "
    dc.b "                    "
    dc.b "    Sierra Nevada   "
    dc.b "          miles     "
unk_4AE8:
    dc.w 22,10,5,20
    dc.b "   The next race    "
    dc.b "   will be on the   "
    dc.b "                    "
    dc.b "    Pacific Coast   "
    dc.b "          miles     "
unk_4AD4:
    dc.w 22,10,5,20
    dc.b "   The next race    "
    dc.b "   will be in the   "
    dc.b "                    "
    dc.b "   Redwood Forest   "
    dc.b "          miles     "
unk_4B40:
    dc.w 22,10,5,20
    dc.b "    The next race   "
    dc.b "   will be in the   "
    dc.b "                    "
    dc.b "     Palm Desert    "
    dc.b "          miles     "
unk_4BAC:
    dc.w 22,10,5,20
    dc.b "    The next race   "
    dc.b "     will be in     "
    dc.b "                    "
    dc.b "    Grass Valley    "
    dc.b "          miles     "

unk_4C18:
    dc.b "Fang         $51,320"
    dc.b "Helldog      $44,790"
    dc.b "Lubster      $34,260"
    dc.b "Natasha      $29,990"
    dc.b "Sergio       $23,440"
    dc.b "Player A          $0"
    dc.b "Player B          $0"

unk_4CA4:
    dc.w 23,16,3,20
    dc.b "   Press ",$22,"Start",$22,"    "
    dc.b "                    "
    dc.b "      to race       "

unk_4CE8:
    dc.w 23,16,3,20
    dc.b "   Press ",$22,"A",$22," for    "
    dc.b "                    "
    dc.b "  Player Selection  "

unk_4D2C:
    dc.w 23,16,3,20
    dc.b "  Press ",$22,"B",$22," to turn "
    dc.b "                    "
    dc.b "   Music ON or OFF  "

unk_4D70:
    dc.w 22,16,5,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b "  Enter a password  "
    dc.b "                    "
    dc.b "  or a player name  "

unk_4DDC:
    dc.w 23,16,3,20
    dc.b " Use Directional pad"
    dc.b "                    "
    dc.b " select a new track "

unk_4E20:
    dc.w 22,12,5,16
    dc.b "   PLAYERNAME   "
    dc.b "                "
    dc.b "PASSWORD INVALID"
    dc.b "                "
    dc.b "OLD LEVEL IS: 0 "

unk_4E78:
    dc.w 22,16,5,20
    dc.b "                    "
    dc.b "                    "
    dc.b "                    "
    dc.b "                    "
    dc.b "                    "

unk_4EE4:
    dc.w 27,1,1,1
    dc.b "  "

word_4EEE:
    dc.w 8,4,7,12
    dc.b "    Name    "
    dc.b "            "
    dc.b "            "
    dc.b "            "
    dc.b "            "
    dc.b "            "
    dc.b "  Password  "

unk_4F4A:
    dc.w 22,16,5,20
    dc.b "      Press ",$22,"A",$22,"     "
    dc.b "                    "
    dc.b "    to check out    "
    dc.b "                    "
    dc.b "     High Scores    "

unk_4FB6:
    dc.w 23,16,3,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b "check out new bikes "

unk_4FFA:
    dc.w 23,16,3,20
    dc.b "Press ",$22,"Start",$22," to go "
    dc.b "                    "
    dc.b " to Track Selection "

unk_503E:
    dc.w 22,16,5,20
    dc.b " Press ",$22,"B",$22," to check "
    dc.b "                    "
    dc.b "  out Race Results, "
    dc.b "                    "
    dc.b " cash, and password."

unk_50AA:
    dc.w 22,16,5,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b "      buy a new     "
    dc.b "                    "
    dc.b "                    "

unk_5116:
    dc.w 22,16,4,20
    dc.b "   Press Left on    "
    dc.b "  Directional Pad   "
    dc.b "  to check out the  "
    dc.b "                    "

unk_516E:
    dc.w 22,16,4,20
    dc.b "   Press Right on   "
    dc.b "  Directional Pad   "
    dc.b "  to check out the  "
    dc.b "                    "

unk_51C6:
    dc.w 23,10,3,20
    dc.b " You already own a  "
    dc.b "                    "
    dc.b "                    "

unk_520A:
    dc.w 22,10,5,20
    dc.b "   You need more    "
    dc.b "                    "
    dc.b "  credit to buy a   "
    dc.b "                    "
    dc.b "                    "

unk_5276:
    dc.w 22,10,4,20
    dc.b " You must complete  "
    dc.b "    every course    "
    dc.b " before you can go  "
    dc.b " to the next level  "

unk_52CE:
    dc.w 22,10,5,20
    dc.b " You must complete  "
    dc.b "  every course in   "
    dc.b "4th place or better "
    dc.b " before you can go  "
    dc.b " to the next level  "

unk_533A:
    dc.w 22,10,5,20
    dc.b "  Congratulations!  "
    dc.b "   you have raced   "
    dc.b "   well, try some   "
    dc.b " harder competition "
    dc.b "     on level 1     "

unk_53A6:
    dc.w 22,10,4,20
    dc.b "Your credit for bike"
    dc.b " purchase includes  "
    dc.b " the trade in value "
    dc.b "  of your old bike. "

unk_53FE:
    dc.w 23,4,3,32
    dc.b "Big on Handling, short on power."
    dc.b "It's important to maintain speed"
    dc.b "through the corners on this one."

unk_5466:
    dc.w 23,6,3,28
    dc.b "Good all-around sport bike. "
    dc.b "Light steering but lacks    "
    dc.b "mid-range performance.      "

unk_54C2:
    dc.w 23,5,3,30
    dc.b "Crisp handling with good power"
    dc.b "at high RPM but no mid-range. "
    dc.b "Try and keep the revs high.   "

unk_5524:
    dc.w 23,4,2,32
    dc.b "Slower steering, but bigger     "
    dc.b "mid-range power than the Banzai."

unk_556C:
    dc.w 23,6,3,28
    dc.b "Extreme speed but its size  "
    dc.b "makes for slower turning and"
    dc.b "stopping. Plan your turns.  "

unk_55C8:
    dc.w 23,6,3,28
    dc.b "V-twin torque and razor     "
    dc.b "sharp handling. Reliability "
    dc.b "could be a problem.         "

unk_5624:
    dc.w 23,5,2,30
    dc.b "Big V4 mid-range power and    "
    dc.b "magic handling at a big price."

unk_5668:
    dc.w 23,5,2,30
    dc.b "Fuel injected horse power and "
    dc.b "awesome Italian handling.     "

unk_56AC:
    dc.w 18,16,2,18
    dc.b "Caught by the cops"
    dc.b " Your fine -      "

unk_56D8:
    dc.w 18,16,2,18
    dc.b "Can't afford bail "
    dc.b "    GAME OVER     "

unk_5704:
    dc.w 18,16,2,18
    dc.b " Your bike needs  "
    dc.b " repairs  -       "

unk_5730:
    dc.w 18,16,2,20
    dc.b "No money for repairs"
    dc.b "     GAME OVER      "
; =============== S U B R O U T I N E =======================================

ShowEmptyMessage:
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
; End of function ShowEmptyMessage


; =============== S U B R O U T I N E =======================================


ClearMessage:
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
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function ClearMessage


; =============== S U B R O U T I N E =======================================


sub_42AA:                               ; DATA XREF: ROM:000045BA↓o
                                        ; ROM:00004642↓o
                bsr.s   ClearMessage
                move.w  ram_FF05E6,d0
                move.w  ram_FF05E8,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,ram_FF05E6
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   sub_42D0
                rts
; End of function sub_42AA


; =============== S U B R O U T I N E =======================================


sub_42D0:                               ; CODE XREF: sub_42AA+20↑j
                                        ; sub_4362:@loc_438A↓p
                move.w  #4,Intro_ram_ImageBuffer
                move.w  #1,d0
                move.w  #1,d1
                move.w  #$A,d2
                move.w  #$19,d3
                move.w  #$2500,d4
                move.w  #$40,d6 ; '@'
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function sub_42D0


; =============== S U B R O U T I N E =======================================


sub_4302:                               ; DATA XREF: ROM:000045C2↓o
                                        ; ROM:0000464A↓o
                bsr.w   ClearMessage
                move.w  ram_FF05E6,d0
                move.w  ram_FF05E8,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,ram_FF05E6
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   sub_432A
                rts
; End of function sub_4302


; =============== S U B R O U T I N E =======================================


sub_432A:                               ; CODE XREF: sub_4302+22↑j
                                        ; sub_4362+2C↓p
                lea     Intro_ram_ImageBuffer,a0
                move.w  #5,(a0)+
                move.w  #6,(a0)+
                move.w  #1,d0
                move.w  #2,d1
                move.w  #$B,d2
                move.w  #$18,d3
                move.w  #$2500,d4
                move.w  #$40,d6 ; '@'
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function sub_432A


; =============== S U B R O U T I N E =======================================


sub_4362:                               ; DATA XREF: ROM:000045EA↓o
                bsr.w   ClearMessage
                move.w  ram_FF05E6,d0
                move.w  ram_FF05E8,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,ram_FF05E6
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   @loc_438A
                rts
; ---------------------------------------------------------------------------

@loc_438A:                               ; CODE XREF: sub_4362+22↑j
                bsr.w   sub_42D0
                bsr.s   sub_432A
                rts
; End of function sub_4362


; =============== S U B R O U T I N E =======================================


sub_4392:                               ; DATA XREF: ROM:000045CA↓o
                                        ; ROM:000045F2↓o ...
                bsr.w   ClearMessage
                move.w  ram_FF05E6,d0
                move.w  ram_FF05E8,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,ram_FF05E6
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   @loc_43BA
                rts
; ---------------------------------------------------------------------------

@loc_43BA:                               ; CODE XREF: sub_4392+22↑j
                bsr.w   ClearMessage
                lea     Intro_ram_ImageBuffer,a0
                move.w  #7,(a0)+
                move.w  #8,(a0)+
                move.w  #1,d0
                move.w  #2,d1
                move.w  #$C,d2
                move.w  #$18,d3
                move.w  #$2500,d4
                move.w  #$40,d6 ; '@'
                lea     Intro_ram_ImageBuffer,a0
                lea     Menu_ram_FrameBuffer,a1
                bsr.w   WriteNametableToBuffer
                rts
; End of function sub_4392


; =============== S U B R O U T I N E =======================================


sub_43F6:
                bsr.w   ClearMessage
                move.w  ram_FF05E6,d0
                move.w  ram_FF05E8,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,ram_FF05E6
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   @loc_441E
                rts
@loc_441E:
                bsr.w   ClearMessage
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
; End of function sub_43F6

sub_445E:
                bsr.w   ClearMessage
                move.w  ram_FF05E6,d0
                move.w  ram_FF05E8,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,ram_FF05E6
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
                bsr.w   ClearMessage
                move.w  ram_FF05E6,d0
                move.w  ram_FF05E8,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,ram_FF05E6
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


; =============== S U B R O U T I N E =======================================


sub_454E:
                bsr.w   ClearMessage
                move.w  ram_FF05E6,d0
                move.w  ram_FF05E8,d1
                addq.w  #1,d0
                and.w   d1,d0
                move.w  d0,ram_FF05E6
                lsr.w   #1,d1
                eori.w  #$FFFF,d1
                and.w   d1,d0
                beq.w   @loc_4576
                rts
; ---------------------------------------------------------------------------

@loc_4576:                               ; CODE XREF: sub_454E+22↑j
                bsr.w   loc_4486
                bsr.s   loc_44FE
                rts
; End of function sub_454E

off_457E:
; Main menu
    dc.l unk_4888,ShowEmptyMessage
    dc.l unk_48F4,ShowEmptyMessage
    dc.l unk_4960,ShowEmptyMessage
    dc.l unk_49A4,ShowEmptyMessage
    dc.l ram_FF0756,ShowEmptyMessage
    dc.l MenuPassword_StrPasswordStatus,ShowEmptyMessage
; Main menu tooltips 
    dc.l unk_4CA4,sub_43F6
    dc.l unk_4CE8,sub_42AA
    dc.l unk_4D2C,sub_4302
    dc.l unk_4D70,sub_4392
    dc.l unk_4DDC,sub_454E
    dc.l $FFFFFFFF,$FFFFFFFF
; Password menu tooltips
    dc.l word_479E,sub_43F6
    dc.l word_47BC,sub_4362
    dc.l unk_4800,sub_4392
    dc.l unk_4844,sub_454E
    dc.l $FFFFFFFF,$FFFFFFFF

    dc.l unk_4E78,ShowEmptyMessage
    dc.l unk_4E78,ShowEmptyMessage
    dc.l word_479E,sub_43F6
    dc.l $FFFFFFFF,$FFFFFFFF
    dc.l MenuPassword_StrPasswordStatus,ShowEmptyMessage
    dc.l unk_5276,ShowEmptyMessage
    dc.l unk_4FFA,sub_43F6
    dc.l unk_4F4A,sub_42AA
    dc.l unk_503E,sub_4302
    dc.l unk_4FB6,sub_4392
    dc.l $FFFFFFFF,$FFFFFFFF
    dc.l MenuPassword_StrPasswordStatus,ShowEmptyMessage
    dc.l unk_52CE,ShowEmptyMessage
    dc.l unk_4FFA,sub_43F6
    dc.l unk_4F4A,sub_42AA
    dc.l unk_503E,sub_4302
    dc.l unk_4FB6,sub_4392
    dc.l $FFFFFFFF,$FFFFFFFF
    dc.l MenuPassword_StrPasswordStatus,ShowEmptyMessage
    dc.l ram_FF089A,ShowEmptyMessage
    dc.l unk_4FFA,sub_43F6
    dc.l unk_4F4A,sub_42AA
    dc.l unk_503E,sub_4302
    dc.l unk_4FB6,sub_4392
    dc.l $FFFFFFFF,$FFFFFFFF
    dc.l unk_4EE4,sub_4268
    dc.l unk_4FFA,sub_43F6
    dc.l unk_4F4A,sub_42AA
    dc.l unk_503E,sub_4302
    dc.l unk_4FB6,sub_4392
    dc.l $FFFFFFFF,$FFFFFFFF
    dc.l unk_4E78,ShowEmptyMessage
    dc.l unk_4FFA,sub_43F6
    dc.l $FFFFFFFF,$FFFFFFFF
    dc.l unk_53FE,ShowEmptyMessage
    dc.l unk_5466,ShowEmptyMessage
    dc.l unk_54C2,ShowEmptyMessage
    dc.l unk_5524,ShowEmptyMessage
    dc.l unk_556C,ShowEmptyMessage
    dc.l unk_55C8,ShowEmptyMessage
    dc.l unk_5624,ShowEmptyMessage
    dc.l unk_5668,ShowEmptyMessage
    dc.l ram_FF089A,ShowEmptyMessage
    dc.l unk_53A6,ShowEmptyMessage
    dc.l ram_FF07C2,sub_445E
    dc.l ram_FF082E,sub_445E
    dc.l ram_FF06EA,sub_4392
    dc.l unk_4FFA,sub_43F6
    dc.l unk_4F4A,sub_42AA
    dc.l unk_503E,sub_4302
    dc.l $FFFFFFFF,$FFFFFFFF

word_479E:
    dc.w 24,16,1,22
    dc.b "Press ",$22,"Start",$22," to exit "
word_47BC:
    dc.w 23,16,3,20
    dc.b " Press ",$22,"A",$22," or ",$22,"B",$22," to  "
    dc.b "                    "
    dc.b " change a letter  "
unk_4800:
    dc.w 23,16,3,20
    dc.b "    Press ",$22,"C",$22," to    "
    dc.b "                    "
    dc.b " select other player"
unk_4844:
    dc.w 23,16,3,20
    dc.b " Use Directional pad"
    dc.b "                    "
    dc.b "   to move cursor   "
unk_4888:
    dc.w 22,10,5,20
    dc.b "         1          "
    dc.b "                    "
    dc.b "    Player Mode     "
    dc.b "                    "
    dc.b "     Selected       "
unk_48F4:
    dc.w 22,10,5,20
    dc.b "         2          "
    dc.b "                    "
    dc.b "    Player Mode     "
    dc.b "                    "
    dc.b "     Selected       "
unk_4960:
    dc.w 23,10,3,20
    dc.b "    Music is now    "
    dc.b "                    "
    dc.b "        ON          "
unk_49A4:
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
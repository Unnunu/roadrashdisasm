; =============== S U B R O U T I N E =======================================


RaceHud_Draw:
                bsr.w   RaceHud_DrawTime
                bsr.w   RaceHud_DrawPlace
                bsr.w   RaceHud_DrawStamina
                bsr.w   Race_DrawBikeHPBar
                bsr.w   Race_DrawPlayerNameOrPlace
                bsr.w   Race_DrawOpponentName
                bsr.w   RaceHud_DrawSpeedArrow
                bsr.w   RaceHud_DrawRPMArrow
                bsr.w   RaceHud_DrawOdometer
                rts
; End of function RaceHud_Draw


; =============== S U B R O U T I N E =======================================


RaceHud_DrawSpeedArrow:
                move.w  ram_FF1EAA + STRUCT_OFFSET_SPEED,d0
                cmp.w   #14500,d0
                bcs.w   @loc_D2B4
                move.w  #31,d0
                bra.w   @loc_D2BA
@loc_D2B4:
                ext.l   d0
                divu.w  #453,d0
@loc_D2BA:
                movea.l Race_ram_CurrentSpriteAttributeTable,a0; sprite attribute table
                movea.l Race_ram_CurrentSpriteTileArray,a1 ; sprite tile array
                lea     unk_7DEAA,a4 ; animation script
                move.w  #$88,d1 ; X = 8 + $80
                move.w  #$80,d2 ; Y = 0 + $80
                jsr     UpdateAnimation
                rts
; End of function RaceHud_DrawSpeedArrow


; =============== S U B R O U T I N E =======================================


RaceHud_DrawRPMArrow:
                lea     ram_FF1A70,a0
                move.w  ram_FF1EAA + STRUCT_OFFSET_GEAR,d1
                asl.w   #1,d1
                move.w  $E(a0,d1.w),d1
                ext.l   d1
                swap    d1
                lsr.l   #8,d1
                lsr.l   #6,d1
                move.w  d1,ram_FF1AA2
                move.w  ram_FF1EAA + STRUCT_OFFSET_SPEED,d0
                ext.l   d0
                swap    d0
                divu.w  d1,d0
                beq.w   @loc_D312
                ext.l   d0
                divu.w  #682,d0
@loc_D312:
                move.w  #$C4,d1 ; X = 68 + $80
                move.w  #$6C,d2 ; Y = -14 + $80
                movea.l Race_ram_CurrentSpriteAttributeTable,a0
                movea.l Race_ram_CurrentSpriteTileArray,a1
                lea     unk_7DEAA,a4
                jsr     UpdateAnimation
                rts
; End of function RaceHud_DrawRPMArrow


; =============== S U B R O U T I N E =======================================


RaceHud_DrawOdometer:
                movea.l Race_ram_CurrentHudBuffer,a1
                adda.w  #$E00,a1
                move.l  ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH,d1
                move.l  d1,d0
                clr.w   d0
                swap    d0
                divu.w  #330,d0
                swap    d0
                move.l  d0,d1
                mulu.w  #62,d0 ; '>'
                asl.l   #8,d0
                swap    d0
                neg.w   d0
                addi.w  #$50,d0 ; 'P'
                asl.w   #2,d0
                move.w  d0,d2
                lea     ram_FF352C,a0
                adda.w  d0,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  d1,d0
                clr.w   d0
                swap    d0
                divu.w  #10,d0
                swap    d0
                move.l  d0,d1
                asl.w   #3,d0
                neg.w   d0
                addi.w  #$50,d0 ; 'P'
                asl.w   #2,d0
                subi.w  #$20,d2 ; ' '
                bpl.w   @loc_D39E
                add.w   d2,d0
@loc_D39E:
                move.w  d0,d2
                lea     ram_FF352C,a0
                adda.w  d0,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  d1,d0
                clr.w   d0
                swap    d0
                divu.w  #10,d0
                swap    d0
                move.l  d0,d1
                asl.w   #3,d0
                neg.w   d0
                addi.w  #$50,d0 ; 'P'
                asl.w   #2,d0
                subi.w  #$20,d2 ; ' '
                bpl.w   @loc_D3DA
                add.w   d2,d0
@loc_D3DA:
                move.w  d0,d2
                lea     ram_FF352C,a0
                adda.w  d0,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                rts
; End of function RaceHud_DrawOdometer


; =============== S U B R O U T I N E =======================================


RaceHud_DrawPlace:
                move.w  ram_FF1B40,d0
                move.w  #$181B,d1 ; x = 27, y = 24
                move.w  #3,d2
                movea.l Race_ram_CurrentHudBuffer,a0
                bsr.w   RaceHud_DrawNumber2Digits
                rts
; End of function RaceHud_DrawPlace


; =============== S U B R O U T I N E =======================================


RaceHud_DrawTime:
; draw minutes
                move.b  Race_ram_TimeMinutes,d0
                move.w  #$1A18,d1 ; x = 24, y = 26
                move.w  #3,d2
                movea.l Race_ram_CurrentHudBuffer,a0
                bsr.w   RaceHud_DrawNumber2Digits
; draw ':'
                move.w  #$1FE,d0 ; base tile index, address = $3E80 + $A * $20
                move.w  #$1A1A,d1 ; x = 26, y = 26
                move.w  #3,d2 ; palette line
                movea.l Race_ram_CurrentHudBuffer,a0
                bsr.w   RaceHud_DrawSymbol
; draw seconds
                move.b  Race_ram_TimeSeconds,d0
                move.w  #$1A1B,d1 ; x = 27, y = 26
                move.w  #3,d2
                movea.l Race_ram_CurrentHudBuffer,a0
                bsr.w   RaceHud_DrawNumber2Digits
                rts
; End of function RaceHud_DrawTime


; =============== S U B R O U T I N E =======================================


RaceHud_DrawStamina:
                movea.l Race_ram_CurrentHudBuffer,a0
                adda.w  #$9B8,a0 ; x = 28, y = 19
                move.l  #$84308430,d0
                move.l  d0,(a0)
                move.l  d0,4(a0)
                move.l  d0,8(a0)
                move.l  d0,$C(a0)
                move.l  d0,$10(a0)
                movea.l ram_FF1908,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   @loc_D4CC
                move.w  $5C(a1),d1
                lsr.w   #5,d1
                cmp.w   #$51,d1 ; 'Q'
                bcs.w   @loc_D49C
                move.w  #$50,d1 ; 'P'
@loc_D49C:
                move.w  #$E5FF,d0
                cmp.w   #$1E,d1
                bpl.w   @loc_D4B8
                move.w  #$A427,d0
                cmp.w   #$F,d1
                bpl.w   @loc_D4B8
                move.w  #$842F,d0
@loc_D4B8:
                subq.w  #8,d1
                bmi.w   @loc_D4C2
                move.w  d0,(a0)+
                bra.s   @loc_D4B8
@loc_D4C2:
                add.w   d1,d0
                addq.w  #8,d1
                beq.w   @loc_D4CC
                move.w  d0,(a0)+
@loc_D4CC:
                movea.l Race_ram_CurrentHudBuffer,a0
                adda.w  #$984,a0 ; x = 2, y = 19
                move.l  #$84308430,d0
                move.l  d0,(a0)
                move.l  d0,4(a0)
                move.l  d0,8(a0)
                move.l  d0,$C(a0)
                move.l  d0,$10(a0)
                move.w  ram_FF1EAA + STRUCT_OFFSET_5C,d1
                lsr.w   #5,d1
                cmp.w   #$51,d1 ; 'Q'
                bcs.w   @loc_D502
                move.w  #$50,d1 ; 'P'
@loc_D502:
                move.w  #$E5FF,d0
                cmp.w   #$1E,d1
                bpl.w   @loc_D51E
                move.w  #$A427,d0
                cmp.w   #$F,d1
                bpl.w   @loc_D51E
                move.w  #$842F,d0
@loc_D51E:
                subq.w  #8,d1
                bmi.w   @loc_D528
                move.w  d0,(a0)+
                bra.s   @loc_D51E
@loc_D528:
                add.w   d1,d0
                addq.w  #8,d1
                beq.w   @locret_D532
                move.w  d0,(a0)+
@locret_D532:
                rts
; End of function RaceHud_DrawStamina


; =============== S U B R O U T I N E =======================================


Race_DrawBikeHPBar:
                movea.l Race_ram_CurrentHudBuffer,a0
                adda.w  #$99C,a0 ; x = 14, y = 19
                move.l  #$84308430,d0
                move.l  d0,(a0)
                move.l  d0,4(a0)
                move.w  #$20,d1
                sub.w   Race_ram_BikeDamage,d1
                bpl.w   @loc_D55C
                move.w  #0,d1
@loc_D55C:
                move.w  #$E5FF,d0
                cmp.w   #$10,d1
                bpl.w   @loc_D578
                move.w  #$A427,d0
                cmp.w   #8,d1
                bpl.w   @loc_D578
                move.w  #$842F,d0
@loc_D578:
                subq.w  #8,d1
                bmi.w   @loc_D582
                move.w  d0,(a0)+
                bra.s   @loc_D578
@loc_D582:
                add.w   d1,d0
                addq.w  #8,d1
                beq.w   @return
                move.w  d0,(a0)+
@return:
                rts
; End of function Race_DrawBikeHPBar


unk_D58E:
    dc.b ' 1st'
    dc.b ' 2nd'
    dc.b ' 3rd'
    dc.b ' 4th'
    dc.b ' 5th'
    dc.b ' 6th'
    dc.b ' 7th'
    dc.b ' 8th'
    dc.b ' 9th'
    dc.b '10th'
    dc.b '11th'
    dc.b '12th'
    dc.b '13th'
    dc.b '14th'
    dc.b '15th'
    dc.b '16th'

; =============== S U B R O U T I N E =======================================


Race_DrawPlayerNameOrPlace:
                cmpi.w  #$30,ram_FF14B8
                ble.w   @loc_D5E2
                move.w  #$30,ram_FF14B8
@loc_D5E2:
                move.w  ram_FF1B40,d0
                cmp.w   ram_FF14BA,d0
                beq.w   @loc_D628
                move.w  d0,ram_FF14BA
                tst.w   ram_FF14B8
                bpl.w   @loc_D614
                btst    #4,d0
                beq.w   @loc_D60C
                subq.w  #6,d0
@loc_D60C:
                subq.w  #1,d0
                move.w  d0,ram_FF14BC

@loc_D614:                               ; CODE XREF: Race_DrawPlayerNameOrPlace+30↑j
                cmpi.w  #$18,ram_FF14B8
                bpl.w   @loc_D628
                addi.w  #$18,ram_FF14B8

@loc_D628:                               ; CODE XREF: Race_DrawPlayerNameOrPlace+20↑j
                                        ; Race_DrawPlayerNameOrPlace+4E↑j
                lea     ram_FF14BE,a0
                move.w  #$A,6(a0)
                move.w  #1,4(a0)
                move.w  #2,2(a0)
                move.w  #$14,(a0)
                tst.w   ram_FF14B8
                bpl.w   @loc_D684

@loc_D64E:                               ; CODE XREF: Race_DrawPlayerNameOrPlace+C0↓j
                tst.w   ram_FF14B8
                bmi.w   @loc_D65E
                subq.w  #1,ram_FF14B8

@loc_D65E:                               ; CODE XREF: Race_DrawPlayerNameOrPlace+86↑j
                lea     MenuPassword_ram_StrPlayerAName + 8,a1
                tst.w   Menu_ram_Player
                beq.w   @loc_D674
                lea     MenuPassword_ram_StrPlayerBName + 8,a1

@loc_D674:                               ; CODE XREF: Race_DrawPlayerNameOrPlace+9C↑j
                move.l  (a1)+,8(a0)
                move.l  (a1)+,$C(a0)
                move.w  (a1)+,$10(a0)
                bra.w   @loc_D702


@loc_D684:                               ; CODE XREF: Race_DrawPlayerNameOrPlace+7C↑j
                move.w  ram_FF14BC,d0
                cmp.w   #$10,d0
                bcc.s   @loc_D64E
                btst    #1,ram_FF14B9
                beq.w   @loc_D6CE
                subq.w  #1,ram_FF14B8
                lea     unk_D58E,a1
                asl.w   #2,d0
                adda.w  d0,a1
                move.b  (a1)+,8(a0)
                move.b  (a1)+,9(a0)
                move.b  (a1)+,$A(a0)
                move.b  (a1)+,$B(a0)
                move.l  #' PLA',$C(a0)
                move.w  #'CE',$10(a0)
                bra.w   @loc_D702
@loc_D6CE:                               ; CODE XREF: Race_DrawPlayerNameOrPlace+CA↑j
                move.l  #'    ',8(a0)
                move.l  #'    ',$C(a0)
                move.w  #'  ',$10(a0)
                subq.w  #1,ram_FF14B8
                move.w  ram_FF14BA,d0
                btst    #4,d0
                beq.w   @loc_D6FA
                subq.w  #6,d0
@loc_D6FA:
                subq.w  #1,d0
                move.w  d0,ram_FF14BC
@loc_D702:
                movea.l Race_ram_CurrentSpriteTileArray,a1
                jsr     (EncodeString).w
                lea     ram_FF14BE,a0
                move.w  6(a0),d0
                move.w  4(a0),d1
                move.w  2(a0),d2
                move.w  (a0),d3
                move.w  #$85C0,d4
                move.w  #$40,d6 ; '@'
                movea.l Race_ram_CurrentSpriteTileArray,a0
                movea.l Race_ram_CurrentHudBuffer,a1
                jsr     (WriteNametableToBuffer).w
                rts
; End of function Race_DrawPlayerNameOrPlace


; =============== S U B R O U T I N E =======================================


Race_DrawOpponentName:
                lea     Menu_ram_PlayerAOpponents,a0
                tst.w   Menu_ram_Player
                beq.w   @loc_D750
                lea     Menu_ram_PlayerBOpponents,a0
@loc_D750:
                lea     unk_CCDA,a1
                movea.l ram_FF1908,a2
                cmpa.l  #-1,a2
                beq.w   @noOpponentAround
                cmpa.l  #ram_FF1F2A,a2
                bne.w   @loc_D788
                move.w  ram_FF1B38,d1
                subq.w  #1,d1
                lea     unk_CCD0,a4
                asl.w   #1,d1
                move.w  (a4,d1.w),d1
                bra.w   @loc_D794
@loc_D788:
                clr.w   d1
                move.b  $71(a2),d1 ; get actor index
                asl.w   #1,d1
                move.w  (a0,d1.w),d1 ; get actor id
@loc_D794:
                asl.w   #4,d1
                lea     6(a1,d1.w),a1 ; get name
                lea     ram_FF14BE,a0
                move.w  #10,6(a0) ; width
                move.w  #1,4(a0) ; height
                move.w  #28,2(a0) ; x
                move.w  #20,(a0) ; y
                move.l  (a1)+,8(a0) ; copy name
                move.l  (a1)+,$C(a0)
                move.w  (a1)+,$10(a0)
                bra.w   @draw
@noOpponentAround:
                lea     ram_FF14BE,a0
                move.w  #10,6(a0) ; width
                move.w  #1,4(a0) ; height
                move.w  #28,2(a0) ; x
                move.w  #20,(a0) ; y
                move.l  #'    ',8(a0) ; draw empty string
                move.l  #'    ',$C(a0)
                move.w  #'  ',$10(a0)
@draw:
                movea.l Race_ram_CurrentSpriteTileArray,a1
                jsr     (EncodeString).w
                lea     ram_FF14BE,a0
; draw opponent's name
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$85C0,d4 ; base tile index, address = $B800, high priority
                move.w  #64,d6 ; plane width
                movea.l Race_ram_CurrentSpriteTileArray,a0 ; source
                movea.l Race_ram_CurrentHudBuffer,a1 ; destination
                jsr     (WriteNametableToBuffer).w
                rts
; End of function Race_DrawOpponentName

; *************************************************
; Function sub_D8530
; d0 - tile index
; d1 - position
; d2 - palette line
; a0 - frame buffer
; *************************************************

RaceHud_DrawSymbol:
                ror.w   #3,d2
                move.w  d1,d3
                andi.w  #$FF00,d3
                lsr.w   #1,d3
                andi.w  #$FF,d1
                asl.w   #1,d1
                add.w   d1,d3
                move.w  d0,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,(a0,d3.w)
                rts
; End of function RaceHud_DrawSymbol

; *************************************************
; Function RaceHud_DrawNumber2Digits
; d0 - 
; d1 - 
; d2 - 
; a0 - frame buffer
; *************************************************

RaceHud_DrawNumber2Digits:
                ror.w   #3,d2
                move.w  d1,d3
                andi.w  #$FF00,d3
                lsr.w   #1,d3
                andi.w  #$FF,d1
                asl.w   #1,d1
                add.w   d1,d3
                clr.w   d1
                move.w  d0,d1
                lsr.w   #4,d1
                andi.w  #$F,d1
                addi.w  #$1F4,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,(a0,d3.w)

                move.w  d0,d1
                andi.w  #$F,d1
                addi.w  #$1F4,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,2(a0,d3.w)
                rts
; End of function RaceHud_DrawNumber2Digits


; =============== S U B R O U T I N E =======================================


RaceHud_DrawNumber4Digits:
                ror.w   #3,d2
                move.w  d1,d3
                andi.w  #$FF00,d3
                lsr.w   #1,d3
                andi.w  #$FF,d1
                asl.w   #1,d1
                add.w   d1,d3
                move.w  d0,d1
                rol.w   #4,d1
                andi.w  #$F,d1
                addi.w  #$1F4,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,(a0,d3.w)
                move.w  d0,d1
                lsr.w   #8,d1
                andi.w  #$F,d1
                addi.w  #$1F4,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,2(a0,d3.w)
                move.w  d0,d1
                lsr.w   #4,d1
                andi.w  #$F,d1
                addi.w  #$1F4,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,4(a0,d3.w)
                move.w  d0,d1
                andi.w  #$F,d1
                addi.w  #$1F4,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,6(a0,d3.w)
                rts
; End of function RaceHud_DrawNumber4Digits
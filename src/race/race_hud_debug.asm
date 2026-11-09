; *************************************************
; race_hud_debug.asm - race HUD digit writers, standings and debug readouts
; ROM range: $98C2-$9B9D
; Status:    analyzed (no direct callers in the disassembled source)
; API:       RaceHud_DrawStandings, RaceDebug_ShowDistanceTravelled, RaceDebug_ShowPosZ/997E/999E/99C2,
;            sub_9A98/9AB4, RaceHud_WriteDigit1/9AF4/9B34
; *************************************************

; *************************************************
; Function RaceHud_DrawStandings
; Draws RaceHud_ram_StandingsValue (2 digits) and the racer list at RaceHud_ram_StandingsPtr; the current row
; (RaceHud_ram_StandingsIndex) uses palette 0, the others palette 2.
; In:  RaceHud_ram_StandingsPtr/1AE4/1AE6
; Out: Race_ram_NextHudBuffer
; Clobbers: d0-d4, a0/a1
; *************************************************

RaceHud_DrawStandings:
                move.w  (RaceHud_ram_StandingsValue).l,d0
                move.w  #$1602,d1
                move.w  d1,-(sp)
                move.w  #0,d2
                movea.l (Race_ram_NextHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit2).l
                move.w  (sp)+,d1
                addq.w  #4,d1
                movea.l (RaceHud_ram_StandingsPtr).l,a1
                move.w  (a1)+,d2
                move.w  (RaceHud_ram_StandingsIndex).l,d3
                move.w  #1,d4
.loc_98F4:
; each list entry points to a pointer to the displayed value
                movea.l (a1)+,a0
                movea.l (a0),a0
                move.w  (a0),d0
                movem.l d1-d4,-(sp)
                cmp.w   d4,d3
                bne.w   .loc_9918
                move.w  #0,d2
                movea.l (Race_ram_NextHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l
                bra.w   .loc_9928
.loc_9918:
                move.w  #2,d2
                movea.l (Race_ram_NextHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l
.loc_9928:
                movem.l (sp)+,d1-d4
                addq.w  #6,d1
                addq.w  #1,d4
                cmp.w   d2,d4
                ble.s   .loc_98F4
                rts
; End of function RaceHud_DrawStandings


; *************************************************
; Function RaceDebug_ShowDistanceTravelled
; Shows the player's POSX_HIGH (formatted by Race_FormatDecimal) at HUD cell $1A13.
; In:  player struct RacePlayerA
; Out: Race_ram_CurrentHudBuffer
; Clobbers: d0/d1/d2/a0
; *************************************************

RaceDebug_ShowDistanceTravelled:
                move.w  (RacePlayerA + RaceActor_PosXHigh).l,d0
                jsr     (Race_FormatDecimal).l
                move.w  d1,d0
                move.w  #$1A13,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l
                rts
; End of function RaceDebug_ShowDistanceTravelled


; *************************************************
; Function RaceDebug_ShowPosZ
; Debug: shows the player POSZ (formatted) at HUD cell $1508.
; In:  player struct RacePlayerA
; Out: Race_ram_CurrentHudBuffer
; Clobbers: d0/d1/d2/a0
; *************************************************

RaceDebug_ShowPosZ:
                move.w  (RacePlayerA + RaceActor_PosZ).l,d0
                jsr     (Race_FormatDecimal).l
                move.w  d1,d0
                move.w  #$1508,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l
                rts
; End of function RaceDebug_ShowPosZ


; *************************************************
; Function RaceDebug_ShowFrameDelay
; Debug: shows Race_ram_FrameDelay. Quirk: no HUD position is set before RaceHud_WriteDigit4,
; so d1 still holds the formatted value (likely unfinished).
; In:  Race_ram_FrameDelay
; Out: Race_ram_CurrentHudBuffer (wrong cell)
; Clobbers: d0/d1/d2/a0
; *************************************************

RaceDebug_ShowFrameDelay:
                move.w  (Race_ram_FrameDelay).l,d0
                jsr     (Race_FormatDecimal).l
                move.w  d1,d0
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l
                rts
; End of function RaceDebug_ShowFrameDelay


; *************************************************
; Function sub_999E
; Debug: shows ram_FF304C (formatted) at HUD cell $1914.
; In:  ram_FF304C
; Out: Race_ram_CurrentHudBuffer
; Clobbers: d0/d1/d2/a0
; *************************************************

sub_999E:
                move.w  (ram_FF304C).l,d0
                jsr     (Race_FormatDecimal).l
                move.w  d1,d0
                move.w  #$1914,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit2).l
                rts
; End of function sub_999E


; *************************************************
; Function RaceDebug_ShowState
; Debug panel: shows ram_FF1786, NumSprites, ram_FF1B3E, player +$68, POSY, POSZ,
; POSX_HIGH and POSX_LOW&$FF00 at fixed HUD cells.
; In:  player struct RacePlayerA, race state
; Out: Race_ram_CurrentHudBuffer
; Clobbers: d0/d1/d2/a0
; *************************************************

RaceDebug_ShowState:
                move.w  (ram_FF1786).l,d0
                move.w  #$1420,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l

                move.w  (Race_ram_NumSprites).l,d0
                move.w  #$140D,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l

                move.w  (ram_FF1B3E).l,d0
                move.w  #$150D,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l

                move.w  (RacePlayerA + STRUCT_OFFSET_68).l,d0
                move.w  #$1418,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l

                move.w  (RacePlayerA + RaceActor_PosY).l,d0
                move.w  #$1A08,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l

                move.w  (RacePlayerA + RaceActor_PosZ).l,d0
                move.w  #$1A10,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l

                move.w  (RacePlayerA + RaceActor_PosXHigh).l,d0
                move.w  #$1A17,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l

                move.w (RacePlayerA + RaceActor_PosXLow).l,d0
                andi.w  #$FF00,d0
                move.w  #$1A1C,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l
                rts
; End of function RaceDebug_ShowState


; *************************************************
; Function sub_9A98
; Debug: shows Race_ram_SpeedDisplay at HUD cell $180D.
; In:  Race_ram_SpeedDisplay
; Out: Race_ram_CurrentHudBuffer
; Clobbers: d0/d1/d2/a0
; *************************************************

sub_9A98:
                move.w  (Race_ram_SpeedDisplay).l,d0
                move.w  #$180D,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit4).l
                rts
; End of function sub_9A98


; *************************************************
; Function RaceHud_DrawGear
; Gear indicator: writes player GEAR + $5C1 at HUD cell $1716.
; In:  player struct RacePlayerA
; Out: Race_ram_CurrentHudBuffer
; Clobbers: d0/d1/d2/a0
; *************************************************

RaceHud_DrawGear:
                move.w  (RacePlayerA + RaceActor_Gear).l,d0
                addi.w  #$5C1,d0
                move.w  #$1716,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (RaceHud_WriteDigit1).l
                rts
; End of function RaceHud_DrawGear


; *************************************************
; Function RaceHud_WriteDigit1
; Writes one digit (d0 = final tile word) at packed position d1.
; In:  d0 - tile, d1 - packed row/column, d2 - palette/priority
; Out: (a0,d3) HUD word
; Clobbers: d1/d3
; *************************************************

RaceHud_WriteDigit1:
; packed position d1: high byte = row, low byte = column; offset = row*128 + col*2
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
; End of function RaceHud_WriteDigit1


; *************************************************
; Function RaceHud_WriteDigit2
; Writes two hex digits of d0 at packed position d1 (tiles $5C0+digit).
; In:  d0 - value, d1 - packed row/column, d2 - palette/priority, a0 - buffer
; Out: (a0,d3) two HUD words
; Clobbers: d1/d3
; *************************************************

RaceHud_WriteDigit2:
; packed position d1: high byte = row, low byte = column; offset = row*128 + col*2
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
                addi.w  #$5C0,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,(a0,d3.w)
                move.w  d0,d1
                andi.w  #$F,d1
                addi.w  #$5C0,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,2(a0,d3.w)
                rts
; End of function RaceHud_WriteDigit2


; *************************************************
; Function RaceHud_WriteDigit4
; Writes four hex digits of d0 at packed position d1 (tiles $5C0+digit).
; In:  d0 - value, d1 - packed row/column, d2 - palette/priority, a0 - buffer
; Out: (a0,d3) four HUD words
; Clobbers: d1/d3
; *************************************************

RaceHud_WriteDigit4:
; packed position d1: high byte = row, low byte = column; offset = row*128 + col*2
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
                addi.w  #$5C0,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,(a0,d3.w)
                move.w  d0,d1
                lsr.w   #8,d1
                andi.w  #$F,d1
                addi.w  #$5C0,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,2(a0,d3.w)
                move.w  d0,d1
                lsr.w   #4,d1
                andi.w  #$F,d1
                addi.w  #$5C0,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,4(a0,d3.w)
                move.w  d0,d1
                andi.w  #$F,d1
                addi.w  #$5C0,d1
                bset    #$F,d1
                or.w    d2,d1
                move.w  d1,6(a0,d3.w)
                rts
; End of function RaceHud_WriteDigit4
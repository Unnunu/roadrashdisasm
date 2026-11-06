; =============== S U B R O U T I N E =======================================


sub_98C2:
                move.w  (ram_FF1AE4).l,d0
                move.w  #$1602,d1
                move.w  d1,-(sp)
                move.w  #0,d2
                movea.l (Race_ram_NextHudBuffer).l,a0
                jsr     (sub_9AF4).l
                move.w  (sp)+,d1
                addq.w  #4,d1
                movea.l (ram_FF1AE0).l,a1
                move.w  (a1)+,d2
                move.w  (ram_FF1AE6).l,d3
                move.w  #1,d4
.loc_98F4:
                movea.l (a1)+,a0
                movea.l (a0),a0
                move.w  (a0),d0
                movem.l d1-d4,-(sp)
                cmp.w   d4,d3
                bne.w   .loc_9918
                move.w  #0,d2
                movea.l (Race_ram_NextHudBuffer).l,a0
                jsr     (sub_9B34).l
                bra.w   .loc_9928
.loc_9918:
                move.w  #2,d2
                movea.l (Race_ram_NextHudBuffer).l,a0
                jsr     (sub_9B34).l
.loc_9928:
                movem.l (sp)+,d1-d4
                addq.w  #6,d1
                addq.w  #1,d4
                cmp.w   d2,d4
                ble.s   .loc_98F4
                rts
; End of function sub_98C2


; =============== S U B R O U T I N E =======================================


RaceDebug_ShowDistanceTravelled:
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                jsr     (sub_F11C).l
                move.w  d1,d0
                move.w  #$1A13,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l
                rts
; End of function RaceDebug_ShowDistanceTravelled


; =============== S U B R O U T I N E =======================================

; another coordinate ???
sub_995A:
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSZ).l,d0
                jsr     (sub_F11C).l
                move.w  d1,d0
                move.w  #$1508,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l
                rts
; End of function sub_995A


; =============== S U B R O U T I N E =======================================


sub_997E:
                move.w  (Race_ram_FrameDelay).l,d0
                jsr     (sub_F11C).l
                move.w  d1,d0
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l
                rts
; End of function sub_997E


; =============== S U B R O U T I N E =======================================


sub_999E:
                move.w  (ram_FF304C).l,d0
                jsr     (sub_F11C).l
                move.w  d1,d0
                move.w  #$1914,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9AF4).l
                rts
; End of function sub_999E


; =============== S U B R O U T I N E =======================================


sub_99C2:
                move.w  (ram_FF1786).l,d0
                move.w  #$1420,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l

                move.w  (Race_ram_NumSprites).l,d0
                move.w  #$140D,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l

                move.w  (ram_FF1B3E).l,d0
                move.w  #$150D,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l

                move.w  (ram_FF1EAA + STRUCT_OFFSET_68).l,d0
                move.w  #$1418,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l

                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSY).l,d0
                move.w  #$1A08,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l

                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSZ).l,d0
                move.w  #$1A10,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l

                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                move.w  #$1A17,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l

                move.w (ram_FF1EAA + STRUCT_OFFSET_POSX_LOW).l,d0
                andi.w  #$FF00,d0
                move.w  #$1A1C,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l
                rts
; End of function sub_99C2


; =============== S U B R O U T I N E =======================================


sub_9A98:
                move.w  (ram_FF3046).l,d0
                move.w  #$180D,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9B34).l
                rts
; End of function sub_9A98


; =============== S U B R O U T I N E =======================================


sub_9AB4:
                move.w  (ram_FF1EAA + STRUCT_OFFSET_GEAR).l,d0
                addi.w  #$5C1,d0
                move.w  #$1716,d1
                move.w  #0,d2
                movea.l (Race_ram_CurrentHudBuffer).l,a0
                jsr     (sub_9AD4).l
                rts
; End of function sub_9AB4


; =============== S U B R O U T I N E =======================================


sub_9AD4:
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
; End of function sub_9AD4


; =============== S U B R O U T I N E =======================================


sub_9AF4:
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
; End of function sub_9AF4


; =============== S U B R O U T I N E =======================================


sub_9B34:
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
; End of function sub_9B34
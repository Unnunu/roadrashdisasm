; =============== S U B R O U T I N E =======================================


UncompressB:
                movem.l d0-d7/a0-a6,-(sp)
                move.l  (a3)+,d2
                lea     Road_ram_XLeftArray,a2
                movea.l a2,a0
                move.l  #$20202020,d3
                move.w  #$3FF,d0
@loc_9BB6:
                move.l  d3,(a0)+
                dbf     d0,@loc_9BB6
                move.w  #$FEE,d7
                moveq   #0,d3
                moveq   #0,d6
@loc_9BC4:
                dbf     d3,@loc_9BCC
                move.b  (a3)+,d6
                moveq   #7,d3
@loc_9BCC:
                lsr.b   #1,d6
                bcc.w   @loc_9BE8
                move.b  (a3)+,d0
                move.b  d0,(a1)+
                subq.l  #1,d2
                beq.w   @loc_9C20
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   @loc_9BC4
@loc_9BE8:
                moveq   #0,d4
                move.b  (a3)+,d4
                move.b  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
@loc_9BFE:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a1)+
                subq.l  #1,d2
                beq.w   @loc_9C20
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,@loc_9BFE
                bra.s   @loc_9BC4
@loc_9C20:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function UncompressB


; =============== S U B R O U T I N E =======================================


UncompressW:
                movem.l d0-d7/a0-a6,-(sp)
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
                addq.w  #1,a3
                move.b  (a3)+,d2
                lea     Road_ram_XLeftArray,a2
                movea.l a2,a0
                move.l  #$20202020,d3
                move.w  #$3FF,d0
@loc_9C52:
                move.l  d3,(a0)+
                dbf     d0,@loc_9C52
                move.w  #$FEE,d7
                moveq   #0,d3
                moveq   #0,d6
@loc_9C60:
                dbf     d3,@loc_9C68
                move.w  (a3)+,d6
                moveq   #7,d3
@loc_9C68:
                lsr.b   #1,d6
                bcc.w   @loc_9C84
                move.w  (a3)+,d0
                move.b  d0,(a1)+
                subq.l  #1,d2
                beq.w   @loc_9CC0
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   @loc_9C60
@loc_9C84:
                moveq   #0,d4
                move.w  (a3)+,d4
                andi.w  #$FF,d4
                move.w  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
@loc_9C9E:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a1)+
                subq.l  #1,d2
                beq.w   @loc_9CC0
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,@loc_9C9E
                bra.s   @loc_9C60
@loc_9CC0:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function UncompressW


; =============== S U B R O U T I N E =======================================


sub_9CC6:
                movem.l d0-d7/a0-a6,-(sp)
                move.l  (a3)+,d2
                lea     Road_ram_XLeftArray,a2
                movea.l a2,a0
                move.l  #$20202020,d3
                move.w  #$3FF,d0
@loc_9CDE:
                move.l  d3,(a0)+
                dbf     d0,@loc_9CDE
                move.w  #$FEE,d7
                moveq   #0,d3
                moveq   #0,d6
@loc_9CEC:
                dbf     d3,@loc_9CF4
                move.b  (a3)+,d6
                moveq   #7,d3
@loc_9CF4:
                lsr.b   #1,d6
                bcc.w   @loc_9D1C
                move.b  (a3)+,d0
                move.b  d0,(a1)+
                clr.w   ram_FF13A8
                subq.l  #1,d2
                beq.w   @loc_9D62
                subq.l  #1,d1
                beq.w   @loc_9D62
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   @loc_9CEC
@loc_9D1C:
                moveq   #0,d4
                move.b  (a3)+,d4
                move.b  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
@loc_9D32:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a1)+
                move.w  #$FFFF,ram_FF13A8
                subq.l  #1,d2
                beq.w   @loc_9D62
                subq.l  #1,d1
                beq.w   @loc_9D62
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,@loc_9D32
                bra.s   @loc_9CEC
@loc_9D62:
                move.l  a0,ram_FF136C
                move.l  a1,ram_FF1370
                move.l  a2,ram_FF1374
                move.l  a3,ram_FF1378
                move.l  a4,ram_FF137C
                move.l  a5,ram_FF1380
                move.l  a6,ram_FF1384
                move.l  d0,ram_FF1388
                move.l  d1,ram_FF138C
                move.l  d2,ram_FF1390
                move.l  d3,ram_FF1394
                move.l  d4,ram_FF1398
                move.l  d5,ram_FF139C
                move.l  d6,ram_FF13A0
                move.l  d7,ram_FF13A4
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_9CC6


; =============== S U B R O U T I N E =======================================


sub_9DC2:
                movem.l d0-d7/a0-a6,-(sp)
                movea.l ram_FF136C,a0
                movea.l ram_FF1374,a2
                movea.l ram_FF1378,a3
                movea.l ram_FF137C,a4
                movea.l ram_FF1380,a5
                movea.l ram_FF1384,a6
                move.l  ram_FF1388,d0
                move.l  ram_FF1390,d2
                move.l  ram_FF1394,d3
                move.l  ram_FF1398,d4
                move.l  ram_FF139C,d5
                move.l  ram_FF13A0,d6
                move.l  ram_FF13A4,d7
                tst.w   ram_FF13A8
                beq.w   @loc_9E46
                bra.w   @loc_9E88
@loc_9E22:
                dbf     d3,@loc_9E2A
                move.b  (a3)+,d6
                moveq   #7,d3
@loc_9E2A:
                lsr.b   #1,d6
                bcc.w   @loc_9E52
                move.b  (a3)+,d0
                move.b  d0,(a1)+
                clr.w   ram_FF13A8
                subq.l  #1,d2
                beq.w   @loc_9E98
                subq.l  #1,d1
                beq.w   @loc_9E98
@loc_9E46:
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   @loc_9E22
@loc_9E52:
                moveq   #0,d4
                move.b  (a3)+,d4
                move.b  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
@loc_9E68:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a1)+
                move.w  #$FFFF,ram_FF13A8
                subq.l  #1,d2
                beq.w   @loc_9E98
                subq.l  #1,d1
                beq.w   @loc_9E98
@loc_9E88:
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,@loc_9E68
                bra.s   @loc_9E22
@loc_9E98:
                move.l  a0,ram_FF136C
                move.l  a1,ram_FF1370
                move.l  a2,ram_FF1374
                move.l  a3,ram_FF1378
                move.l  a4,ram_FF137C
                move.l  a5,ram_FF1380
                move.l  a6,ram_FF1384
                move.l  d0,ram_FF1388
                move.l  d1,ram_FF138C
                move.l  d2,ram_FF1390
                move.l  d3,ram_FF1394
                move.l  d4,ram_FF1398
                move.l  d5,ram_FF139C
                move.l  d6,ram_FF13A0
                move.l  d7,ram_FF13A4
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_9DC2


; =============== S U B R O U T I N E =======================================


UncompressToVRAM:
                movem.l d0-d7/a0-a6,-(sp)
                move.w  a1,d0
                andi.l  #$FFFF,d0
                asl.l   #2,d0
                lsr.w   #2,d0
                ori.w   #$4000,d0
                swap    d0
                move.l  d0,VdpCtrl
                lea     VdpData,a1
                lea     ram_FF13AA,a4
                move.w  #0,d1
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
                addq.w  #1,a3
                move.b  (a3)+,d2
                lea     Road_ram_XLeftArray,a2
                movea.l a2,a0
                move.l  #$20202020,d3
                move.w  #$3FF,d0
@loc_9F4C:
                move.l  d3,(a0)+
                dbf     d0,@loc_9F4C
                move.w  #$FEE,d7
                moveq   #0,d3
                moveq   #0,d6
@loc_9F5A:
                dbf     d3,@loc_9F62
                move.w  (a3)+,d6
                moveq   #7,d3
@loc_9F62:
                lsr.b   #1,d6
                bcc.w   @loc_9F8C
                move.w  (a3)+,d0
                move.b  d0,(a4,d1.w)
                addq.w  #1,d1
                andi.w  #3,d1
                bne.w   @loc_9F7A
                move.l  (a4),(a1)
@loc_9F7A:
                subq.l  #1,d2
                beq.w   @loc_9FD6
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   @loc_9F5A
@loc_9F8C:
                moveq   #0,d4
                move.w  (a3)+,d4
                andi.w  #$FF,d4
                move.w  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
@loc_9FA6:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a4,d1.w)
                addq.w  #1,d1
                andi.w  #3,d1
                bne.w   @loc_9FC0
                move.l  (a4),(a1)
@loc_9FC0:
                subq.l  #1,d2
                beq.w   @loc_9FD6
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,@loc_9FA6
                bra.s   @loc_9F5A
@loc_9FD6:
                tst.w   d1
                beq.w   @loc_9FDE
                move.l  (a4),(a1)
@loc_9FDE:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function UncompressToVRAM
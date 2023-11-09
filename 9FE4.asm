; =============== S U B R O U T I N E =======================================


sub_9FE4:
                movem.l d0-d7/a0-a6,-(sp)
                clr.w   ram_FF13E2
                move.w  d1,ram_FF13B2
                clr.l   d2
                move.w  (a2)+,d2
                move.w  d2,ram_FF13DC
                move.l  a2,ram_FF13DE
                adda.l  d2,a2
                move.l  a2,ram_FF13D4
                move.l  a1,ram_FF13D8
                clr.w   ram_FF140E
                clr.l   d2
                move.w  (a3)+,d2
                move.w  d2,ram_FF1408
                move.l  a3,ram_FF140A
                adda.l  d2,a3
                move.l  a3,ram_FF1400
                addq.l  #1,a1
                move.l  a1,ram_FF1404
                andi.l  #$FFFF,d1
                movem.l (sp)+,d0-d7/a0-a6
                jsr     sub_A04A
                rts
; End of function sub_9FE4


; =============== S U B R O U T I N E =======================================


sub_A04A:
                bsr.w   sub_A0D4
                bsr.w   sub_A2DA
                rts
; End of function sub_A04A


unk_A054:       dc.b $80
                dc.b $40
                dc.b $20
                dc.b $10
                dc.b   8
                dc.b   4
                dc.b   2
                dc.b   1
                dc.b $C0
                dc.b $60
                dc.b $30
                dc.b $18
                dc.b  $C
                dc.b   6
                dc.b   3
                dc.b   1
                dc.b $E0
                dc.b $70
                dc.b $38
                dc.b $1C
                dc.b  $E
                dc.b   7
                dc.b   3
                dc.b   1
                dc.b $F0
                dc.b $78
                dc.b $3C
                dc.b $1E
                dc.b  $F
                dc.b   7
                dc.b   3
                dc.b   1
                dc.b $F8
                dc.b $7C
                dc.b $3E
                dc.b $1F
                dc.b  $F
                dc.b   7
                dc.b   3
                dc.b   1
                dc.b $FC
                dc.b $7E
                dc.b $3F
                dc.b $1F
                dc.b  $F
                dc.b   7
                dc.b   3
                dc.b   1
                dc.b $FE
                dc.b $7F
                dc.b $3F
                dc.b $1F
                dc.b  $F
                dc.b   7
                dc.b   3
                dc.b   1

unk_A08C:       dc.b $80
                dc.b $C0
                dc.b $E0
                dc.b $F0
                dc.b $F8
                dc.b $FC
                dc.b $FE
                dc.b   0
unk_A094:       dc.b   7
                dc.b   6
                dc.b   5
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b   6
                dc.b   5
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b   5
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b $FD
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b $FD
                dc.b $FC
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b $FD
                dc.b $FC
                dc.b $FB
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b $FD
                dc.b $FC
                dc.b $FB
                dc.b $FA
unk_A0CC:       dc.b   7
                dc.b   6
                dc.b   5
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0

; =============== S U B R O U T I N E =======================================


sub_A0D4:
                movem.l d0-d7/a0-a6,-(sp)
                tst.w   ram_FF13E2
                bne.w   @loc_A106
                clr.w   ram_FF13BC
                clr.b   ram_FF13B8
                clr.w   ram_FF13CE
                clr.w   ram_FF13D0
                clr.w   ram_FF13D2
                clr.w   ram_FF13C8
@loc_A106:
                movea.l ram_FF13D4,a0
                movea.l ram_FF13DE,a2
                move.w  d1,ram_FF13B2
                tst.w   ram_FF13E2
                bne.w   @loc_A29C
                move.b  (a0)+,ram_FF13B9
@loc_A128:
                move.w  ram_FF13BC,d0
                cmp.w   ram_FF13DC,d0
                bgt.w   @loc_A2B6
                move.w  ram_FF13BC,d7
                move.b  (a2,d7.w),ram_FF13C6
                andi.b  #7,ram_FF13C6
                clr.l   d0
                move.b  (a2,d7.w),d0
                andi.w  #$F0,d0
                lsr.w   #4,d0
                addq.w  #1,d0
                move.w  d0,ram_FF13C4
                move.b  (a2,d7.w),ram_FF13C2
                andi.b  #8,ram_FF13C2
@loc_A172:
                tst.w   ram_FF13C4
                beq.w   @loc_A2AC
                move.w  ram_FF13CE,d0
                andi.w  #7,d0
                clr.w   d1
                move.b  ram_FF13C6,d1
                asl.b   #3,d1
                add.w   d1,d0
                move.w  d0,ram_FF13CA
                lea     unk_A054,a5
                clr.w   d1
                move.b  ram_FF13B9,d1
                and.b   (a5,d0.w),d1
                move.w  d1,ram_FF13CC
                lea     unk_A094,a5
                clr.l   d1
                move.b  (a5,d0.w),d1
                move.w  ram_FF13CC,d2
                cmp.w   #7,d1
                ble.w   @loc_A1D4
                ext.w   d1
                neg.w   d1
                asl.w   d1,d2
                bra.w   @loc_A1D6
@loc_A1D4:
                lsr.w   d1,d2
@loc_A1D6:
                move.w  d2,ram_FF13CC
                move.b  d2,ram_FF13BA
                clr.w   d0
                move.b  ram_FF13C6,d0
                addq.w  #1,d0
                add.w   d0,ram_FF13CE
                move.w  ram_FF13CE,d0
                lsr.w   #3,d0
                move.w  d0,ram_FF13D0
                cmp.w   ram_FF13D2,d0
                beq.w   @loc_A262
                move.b  (a0)+,ram_FF13B9
                move.w  ram_FF13CE,d0
                andi.w  #7,d0
                beq.w   @loc_A256
                move.w  ram_FF13CE,d0
                subq.w  #1,d0
                andi.w  #7,d0
                move.w  d0,ram_FF13CA
                lea     unk_A0CC,a5
                clr.w   d1
                move.b  (a5,d0.w),d1
                lea     unk_A08C,a5
                clr.w   d2
                move.b  ram_FF13B9,d2
                and.b   (a5,d0.w),d2
                lsr.w   d1,d2
                or.b    d2,ram_FF13BA
@loc_A256:
                move.w  ram_FF13D0,d0
                move.w  d0,ram_FF13D2
@loc_A262:
                move.b  ram_FF13B8,d0
                tst.b   ram_FF13C2
                bne.w   @loc_A27C
                add.b   ram_FF13BA,d0
                bra.w   @loc_A282
@loc_A27C:
                sub.b   ram_FF13BA,d0
@loc_A282:
                move.b  d0,ram_FF13B8
                move.b  d0,(a1)
                addq.l  #2,a1
                subq.w  #1,ram_FF13B2
                tst.w   ram_FF13B2
                bmi.w   @loc_A2C0
@loc_A29C:
                addq.w  #1,ram_FF13C8
                subq.w  #1,ram_FF13C4
                bra.w   @loc_A172
@loc_A2AC:
                addq.w  #1,ram_FF13BC
                bra.w   @loc_A128
@loc_A2B6:
                subq.w  #1,ram_FF13BC
                bra.w   @loc_A2C8
@loc_A2C0:
                move.w  #1,ram_FF13E2
@loc_A2C8:
                move.l  a1,ram_FF13D8
                move.l  a0,ram_FF13D4
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_A0D4


; =============== S U B R O U T I N E =======================================


sub_A2DA:
                movem.l d0-d7/a0-a6,-(sp)
                tst.w   ram_FF140E
                bne.w   @loc_A30C
                clr.w   ram_FF13E8
                clr.b   ram_FF13E4
                clr.w   ram_FF13FA
                clr.w   ram_FF13FC
                clr.w   ram_FF13FE
                clr.w   ram_FF13F4
@loc_A30C:
                movea.l ram_FF1400,a0
                addq.l  #1,a1
                movea.l ram_FF140A,a2
                move.w  d1,ram_FF13B2
                tst.w   ram_FF140E
                bne.w   @loc_A4A4
                move.b  (a0)+,ram_FF13E5
@loc_A330:
                move.w  ram_FF13E8,d0
                cmp.w   ram_FF1408,d0
                bgt.w   @loc_A4BE
                move.w  ram_FF13E8,d7
                move.b  (a2,d7.w),ram_FF13F2
                andi.b  #7,ram_FF13F2
                clr.l   d0
                move.b  (a2,d7.w),d0
                andi.w  #$F0,d0
                lsr.w   #4,d0
                addq.w  #1,d0
                move.w  d0,ram_FF13F0
                move.b  (a2,d7.w),ram_FF13EE
                andi.b  #8,ram_FF13EE
@loc_A37A:
                tst.w   ram_FF13F0
                beq.w   @loc_A4B4
                move.w  ram_FF13FA,d0
                andi.w  #7,d0
                clr.w   d1
                move.b  ram_FF13F2,d1
                asl.b   #3,d1
                add.w   d1,d0
                move.w  d0,ram_FF13F6
                lea     unk_A054,a5
                clr.w   d1
                move.b  ram_FF13E5,d1
                and.b   (a5,d0.w),d1
                move.w  d1,ram_FF13F8
                lea     unk_A094,a5
                clr.l   d1
                move.b  (a5,d0.w),d1
                move.w  ram_FF13F8,d2
                cmp.w   #7,d1
                ble.w   @loc_A3DC
                ext.w   d1
                neg.w   d1
                asl.w   d1,d2
                bra.w   @loc_A3DE
@loc_A3DC:
                lsr.w   d1,d2
@loc_A3DE:
                move.w  d2,ram_FF13F8
                move.b  d2,ram_FF13E6
                clr.w   d0
                move.b  ram_FF13F2,d0
                addq.w  #1,d0
                add.w   d0,ram_FF13FA
                move.w  ram_FF13FA,d0
                lsr.w   #3,d0
                move.w  d0,ram_FF13FC
                cmp.w   ram_FF13FE,d0
                beq.w   @loc_A46A
                move.b  (a0)+,ram_FF13E5
                move.w  ram_FF13FA,d0
                andi.w  #7,d0
                beq.w   @loc_A45E
                move.w  ram_FF13FA,d0
                subq.w  #1,d0
                andi.w  #7,d0
                move.w  d0,ram_FF13F6
                lea     unk_A0CC,a5
                clr.w   d1
                move.b  (a5,d0.w),d1
                lea     unk_A08C,a5
                clr.w   d2
                move.b  ram_FF13E5,d2
                and.b   (a5,d0.w),d2
                lsr.w   d1,d2
                or.b    d2,ram_FF13E6
@loc_A45E:
                move.w  ram_FF13FC,d0
                move.w  d0,ram_FF13FE
@loc_A46A:
                move.b  ram_FF13E4,d0
                tst.b   ram_FF13EE
                bne.w   @loc_A484
                add.b   ram_FF13E6,d0
                bra.w   @loc_A48A
@loc_A484:
                sub.b   ram_FF13E6,d0
@loc_A48A:
                move.b  d0,ram_FF13E4
                move.b  d0,(a1)
                addq.l  #2,a1
                subq.w  #1,ram_FF13B2
                tst.w   ram_FF13B2
                bmi.w   @loc_A4C8
@loc_A4A4:
                addq.w  #1,ram_FF13F4
                subq.w  #1,ram_FF13F0
                bra.w   @loc_A37A
@loc_A4B4:
                addq.w  #1,ram_FF13E8
                bra.w   @loc_A330
@loc_A4BE:
                subq.w  #1,ram_FF13E8
                bra.w   @loc_A4D0
@loc_A4C8:
                move.w  #1,ram_FF140E
@loc_A4D0:
                move.l  a1,ram_FF1404
                move.l  a0,ram_FF1400
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_A2DA
sub_5760:                               ; CODE XREF: sub_8FB4+150↓p
                move.w  #$8000,($FFDE68).l
                movea.l ($FF38AC).l,a0
                move.w  ($FFDE64).l,d2
                asl.w   #3,d2
                adda.w  d2,a0
                move.w  ($FFDE64).l,d2
                beq.w   @loc_57A2
                cmp.w   #$50,d2 ; 'P'
                blt.w   @loc_579E
                move.w  #$FFFF,($FF1366).l
                move.w  #$FFFF,($FFDE62).l
                bra.w   @locret_593C
; ---------------------------------------------------------------------------

@loc_579E:                               ; CODE XREF: sub_5760+26↑j
                or.w    d2,-6(a0)

@loc_57A2:                               ; CODE XREF: sub_5760+1E↑j
                move.w  d0,d2
                lsr.w   #5,d2
                andi.w  #$18,d0
                bne.w   @loc_57B4
                subq.w  #1,d2
                move.w  #$20,d0 ; ' '

@loc_57B4:                               ; CODE XREF: sub_5760+4A↑j
                subq.w  #8,d0
                move.w  d0,($FF0906).l
                move.w  d1,d3
                lsr.w   #5,d3
                andi.w  #$18,d1
                bne.w   @loc_57CE
                subq.w  #1,d3
                move.w  #$20,d1 ; ' '

@loc_57CE:                               ; CODE XREF: sub_5760+64↑j
                subq.w  #8,d1
                asl.w   #2,d1
                move.w  d1,($FF0908).l
                move.w  d2,($FF090A).l
                move.w  d3,($FF090C).l
                move.w  #$7C,($FFDE6A).l ; '|'
                move.w  ($FF0908).l,d4
                addi.w  #$20,d4 ; ' '
                subq.w  #4,d4
                move.w  d4,($FFDE66).l
                cmp.w   #0,d3
                bne.w   @loc_580C
                move.w  d4,($FFDE6A).l

@loc_580C:                               ; CODE XREF: sub_5760+A2↑j
                move.w  ($FFDE70).l,d4
                addi.w  #$80,d4
                move.w  ($FFDE64).l,d5
                addq.w  #1,d5
                move.w  ($FFDE60).l,d6

@loc_5824:                               ; CODE XREF: sub_5760:@loc_5924↓j
                move.w  d6,($FF090E).l
                move.w  ($FFDE6E).l,d7
                addi.w  #$80,d7
                tst.w   ($FF133A).l
                beq.w   @loc_584A
                add.w   ($FF1336).l,d7
                add.w   ($FF1336).l,d7

@loc_584A:                               ; CODE XREF: sub_5760+DA↑j
                move.w  #$60,d0 ; '`'
                cmp.w   #0,d3
                bne.w   @loc_585C
                move.w  ($FF0908).l,d0

@loc_585C:                               ; CODE XREF: sub_5760+F2↑j
                                        ; sub_5760:@loc_58F8↓j
                movea.w #$18,a1
                cmp.w   #0,d2
                bne.w   @loc_586E
                movea.w ($FF0906).l,a1

@loc_586E:                               ; CODE XREF: sub_5760+104↑j
                adda.w  d0,a1
                or.w    $5946(a1),d5
                move.w  d4,(a0)+
                move.w  d5,(a0)+
                move.w  d6,-(sp)
                cmp.w   #$118,d4
                bpl.w   @loc_5886
                ori.w   #$8000,d6

@loc_5886:                               ; CODE XREF: sub_5760+11E↑j
                or.w    ($FFDE5E).l,d6
                add.w   ($FFD34A).l,d6
                tst.w   ($FF133A).l
                beq.w   @loc_58A4
                ori.w   #$800,d6
                sub.w   $594A(a1),d7

@loc_58A4:                               ; CODE XREF: sub_5760+138↑j
                move.w  d6,(a0)+
                move.w  (sp)+,d6
                move.w  d7,(a0)+
                andi.w  #$FF,d5
                addq.w  #1,d5
                add.w   $5948(a1),d6
                cmp.w   #$150,d6
                bmi.w   @loc_58EA
                movea.l ($FF38AC).l,a0
                move.w  #$FFFF,($FF1366).l
                move.w  #$FFFF,($FFDE62).l
                move.w  ($FFDE64).l,d2
                beq.w   @locret_593C
                asl.w   #3,d2
                adda.w  d2,a0
                andi.w  #$FF00,-6(a0)
                bra.w   @locret_593C
; ---------------------------------------------------------------------------

@loc_58EA:                               ; CODE XREF: sub_5760+158↑j
                tst.w   ($FF133A).l
                bne.w   @loc_58F8
                add.w   $594A(a1),d7

@loc_58F8:                               ; CODE XREF: sub_5760+190↑j
                dbf     d2,@loc_585C
                add.w   unk_5944(a1),d4
                move.w  ($FF090A).l,d2
                cmpi.w  #$8000,($FFDE68).l
                bne.w   @loc_5924
                move.w  d6,d0
                sub.w   ($FF090E).l,d0
                subq.w  #4,d0
                asl.w   #5,d0
                move.w  d0,($FFDE68).l

@loc_5924:                               ; CODE XREF: sub_5760+1AE↑j
                dbf     d3,@loc_5824
                andi.w  #$FF00,-6(a0)
                subq.w  #1,d5
                move.w  d5,($FFDE64).l
                move.w  d6,($FFDE60).l

@locret_593C:                            ; CODE XREF: sub_5760+3A↑j
                                        ; sub_5760+178↑j ...
                rts
; End of function sub_5760

sub_593E:
                bsr.w   sub_5760
                rts

unk_5944:
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   8
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b   8
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b   8
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $10
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $10
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $10
                dc.b   9
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b $10
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $18
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $18
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $18
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b $18
                dc.b  $E
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $20
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $20
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $20
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b $20
                dc.b  $F
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $20
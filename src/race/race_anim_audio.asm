; *************************************************
; race_anim_audio.asm - animations, random, engine audio (split from race_ai)
; ROM range: $14056-$1685F (animation.asm starts at $16860)
; *************************************************

unk_14056:      dc.b   1
                dc.b $38 ; 8
                dc.b   1
                dc.b $30 ; 0
                dc.b   1
                dc.b $28 ; (
                dc.b   1
                dc.b $20
                dc.b   1
                dc.b $10
                dc.b   1
                dc.b $60 ; `
                dc.b   1
                dc.b $50 ; P
                dc.b   1
                dc.b $40 ; @
                dc.b   1
                dc.b $30 ; 0
                dc.b   1
                dc.b $20




 ; *************************************************
; Function Race_UpdateLeanCurve
; Computes the lean/curve ($3E/$40) and ram_FF3042 from the current lean/speed.
; In:  d0 - value; a1 - actor ($3E)
; Out: actor $40; ram_FF3042
; Clobbers: d0-d2
; *************************************************

Race_UpdateLeanCurve:
                move.w  d0,d1
                move.w  RaceActor_Curve(a1),d3
                beq.w   .locret_140BA
                ext.l   d1
                bpl.w   .loc_14086
                neg.w   d1
                mulu.w  d3,d1
                swap    d1
                neg.w   d1
                bra.w   .loc_1408A


.loc_14086:
                mulu.w  d3,d1
                swap    d1

.loc_1408A:
                move.w  d1,(ram_FF3042).l
                move.l  #$10000,d2
                divu.w  d3,d2
                subq.w  #1,d2
                muls.w  d0,d2
                bpl.w   .loc_140AE
                neg.w   d2
                mulu.w  #$140,d2
                lsr.l   #8,d2
                neg.w   d2
                bra.w   .loc_140B4


.loc_140AE:
                mulu.w  #$140,d2
                lsr.l   #8,d2

.loc_140B4:
                move.w  d2,RaceActor_LeanCurve(a1)
                move.w  d1,d0

.locret_140BA:
                rts
; End of function Race_UpdateLeanCurve


                dc.b $42 ; B
                dc.b $80
                dc.b $30 ; 0
                dc.b $28 ; (
                dc.b   0
                dc.b  $E
                dc.b $E1
                dc.b $80
                dc.b $D0
                dc.b $B9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $68 ; h
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   4
                dc.b $80
                dc.b   0
                dc.b   0
                dc.b $A0
                dc.b   0
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   6
                dc.b $80
                dc.b   0
                dc.b   0
                dc.b $40 ; @
                dc.b   0
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b   4
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b $1E
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b  $C
                dc.b $69 ; i
                dc.b  $F
                dc.b $A0
                dc.b   0
                dc.b $12
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $61 ; a
                dc.b   0
                dc.b   2
                dc.b   4
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $A8
                dc.b $61 ; a
                dc.b $BA
                dc.b $61 ; a
                dc.b   0
                dc.b   2
                dc.b $8A
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $34 ; 4
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $40 ; @
                dc.b $B0
                dc.b $7C ; |
                dc.b   0
                dc.b   3
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $38 ; 8
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $24 ; $
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $33 ; 3
                dc.b $C0
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $B0
                dc.b $7C ; |
                dc.b $17
                dc.b $70 ; p
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $80
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $5C ; 
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $6E ; n
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $6F ; o
                dc.b $4A ; J
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $17
                dc.b $68 ; h
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $3C ; <
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $D8
                dc.b $61 ; a
                dc.b   0
                dc.b $D7
                dc.b $A4
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b $C0
                dc.b   0
                dc.b $61 ; a
                dc.b   0
                dc.b   2
                dc.b   4
                dc.b $B3
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AA
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $32 ; 2
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $30 ; 0
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $61 ; a
                dc.b   0
                dc.b   1
                dc.b $C4
                dc.b $E2
                dc.b $48 ; H
                dc.b $D1
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $26 ; &
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $14
                dc.b $B3
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AA
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $B0
                dc.b $7C ; |
                dc.b  $F
                dc.b $A0
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $61 ; a
                dc.b   0
                dc.b   1
                dc.b $38 ; 8
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $E4
                dc.b $33 ; 3
                dc.b $C0
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $C0
                dc.b $FC
                dc.b $40 ; @
                dc.b   0
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $B0
                dc.b $7C ; |
                dc.b $27 ; '
                dc.b $10
                dc.b $6D ; m
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b $27 ; '
                dc.b $10
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $12
                dc.b $20
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $60 ; `
                dc.b   0
                dc.b $92
                dc.b $68 ; h
                dc.b   0
                dc.b  $E
                dc.b $48 ; H
                dc.b $C1
                dc.b $E1
                dc.b $81
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $80
                dc.b $D0
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b $90
                dc.b $81
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b   4
                dc.b $61 ; a
                dc.b   0
                dc.b   1
                dc.b $86
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $68 ; h
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $34 ; 4
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $40 ; @
                dc.b $B0
                dc.b $7C ; |
                dc.b   0
                dc.b   3
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $38 ; 8
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b  $C
                dc.b $79 ; y
                dc.b $1F
                dc.b $40 ; @
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b $54 ; T
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $54 ; T
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $6E ; n
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $6F ; o
                dc.b $4A ; J
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $17
                dc.b $68 ; h
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $3A ; :
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $D8
                dc.b $61 ; a
                dc.b   0
                dc.b $D6
                dc.b $9A
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b $C0
                dc.b   0
                dc.b $61 ; a
                dc.b   0
                dc.b   0
                dc.b $FA
                dc.b $B3
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AA
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $30 ; 0
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $30 ; 0
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $61 ; a
                dc.b   0
                dc.b   0
                dc.b $BA
                dc.b $D1
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $26 ; &
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $14
                dc.b $B3
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AA
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b $61 ; a
                dc.b   0
                dc.b $FE
                dc.b $3C ; <
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b $61 ; a
                dc.b   0
                dc.b $FE
                dc.b $2E ; .
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b $17
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $6B ; k
                dc.b $4E ; N
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $40 ; @
                dc.b $EE




sub_142D8:
                bclr    #7,RaceActor_WeaponAnimFlags(a1)
                move.w  d0,-(sp)
                move.w  (ram_FF18A6).l,d0
                bpl.w   .loc_142EC
                neg.w   d0

.loc_142EC:
                cmp.w   #$1770,d0
                bcs.w   .loc_142FA
                bset    #7,RaceActor_WeaponAnimFlags(a1)

.loc_142FA:
                move.w  (sp)+,d0
                rts
; End of function sub_142D8


                dc.b $30 ; 0
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $14
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $69 ; i
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $90
                dc.b $69 ; i
                dc.b   0
                dc.b $4E ; N
                dc.b $59 ; Y
                dc.b $40 ; @
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $D0
                dc.b $69 ; i
                dc.b   0
                dc.b $4C ; L
                dc.b $58 ; X
                dc.b $40 ; @
                dc.b $32 ; 2
                dc.b   0
                dc.b $92
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b $D3
                dc.b $69 ; i
                dc.b   0
                dc.b   0
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $30 ; 0
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $1A
                dc.b $4A ; J
                dc.b $A9
                dc.b   0
                dc.b $26 ; &
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b   4
                dc.b $A9
                dc.b   0
                dc.b   0
                dc.b $40 ; @
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   4
                dc.b $A9
                dc.b   0
                dc.b   0
                dc.b $40 ; @
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b $4E ; N
                dc.b $75 ; u




Race_ScaleImpactDamage:
                tst.w   (ram_FF1768).l
                beq.w   .loc_1435A
                clr.w   d0
                bra.w   .locret_1436C


.loc_1435A:
                tst.w   d0
                bpl.w   .loc_14362
                neg.w   d0

.loc_14362:
                lsr.w   #8,d0
                lsr.w   #3,d0
                move.w  d0,(Race_ram_ImpactScale).l

.locret_1436C:
                rts
; End of function Race_ScaleImpactDamage


                dc.b $49 ; I
                dc.b $F9
                dc.b   0
                dc.b   2
                dc.b $58 ; X
                dc.b $AE
                dc.b $14
                dc.b $29 ; )
                dc.b   0
                dc.b $71 ; q
                dc.b $48 ; H
                dc.b $82
                dc.b $E5
                dc.b $42 ; B
                dc.b $28 ; (
                dc.b $74 ; t
                dc.b $20
                dc.b   0
                dc.b $34 ; 4
                dc.b $2C ; ,
                dc.b   0
                dc.b $12
                dc.b $C4
                dc.b $C0
                dc.b $48 ; H
                dc.b $42 ; B
                dc.b $39 ; 9
                dc.b $42 ; B
                dc.b   0
                dc.b $12
                dc.b $4E ; N
                dc.b $75 ; u




sub_1438E:
                move.w  $12(a1),d0
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_143D4
                cmp.w   #$3E8,d0
                bmi.w   .loc_143D4
                tst.w   (ram_FF1768).l
                bne.w   .loc_143BA
                move.b  #6,(ram_FF1AD6).l
                bra.w   .loc_143D4


.loc_143BA:
                move.b  #1,RaceActor_AnimState(a1)
                move.b  #0,RaceActor_AnimFrame(a1)
                move.b  #$FF,RaceActor_AnimTimer(a1)
                move.b  #$F,(ram_FF1AD6).l

.loc_143D4:
                lsr.w   #8,d0
                lsr.w   #3,d0
                beq.w   .locret_14402
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .locret_14402
                move.w  d0,$2C(a1)
                move.w  #0,$2E(a1)
                move.w  2(a1),d0
                addi.w  #$30,d0 ; '0'
                move.w  d0,$2A(a1)
                bset    #0,RaceActor_ControlFlags(a1)

.locret_14402:
                rts
; End of function sub_1438E


                dc.b $61 ; a
                dc.b $88
                dc.b $4A ; J
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $17
                dc.b $68 ; h
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $6E ; n
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $36 ; 6
                dc.b  $C
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $6E ; n
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $2C ; ,
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $54 ; T
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $6E ; n
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $6F ; o
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $4A ; J
                dc.b $69 ; i
                dc.b   0
                dc.b $12
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b $61 ; a
                dc.b   0
                dc.b $FC
                dc.b $74 ; t
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b  $C
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $6E ; n
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $68 ; h
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $78 ; x
                dc.b   0
                dc.b $78 ; x
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b  $C
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $6E ; n
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $68 ; h
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $78 ; x
                dc.b $4E ; N
                dc.b $75 ; u




Race_ApplyCollisionImpact:
                move.w  RaceActor_PreviousCollisionOffset(a1),d0
                cmp.w   (ram_FF303E).l,d0
                bpl.w   .loc_14594
                move.w  #$1000,d1
                bsr.w   Race_UpdateCollisionSpeedState
                move.w  d0,(ram_FF18A6).l
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_144D4
                jsr     (Race_ScaleImpactDamage).l
                add.w   d0,(Race_ram_BikeDamage).l
                lsr.w   #1,d0
                cmp.w   #2,d0
                ble.w   .loc_144CA
                move.w  #$16,d0
                bra.w   .loc_144CE


.loc_144CA:
                addi.w  #9,d0

.loc_144CE:
                move.b  d0,(ram_FF1AD6).l

.loc_144D4:
                move.b  RaceActor_StateFlags(a2),d0
                andi.b  #8,d0
                or.b    d0,RaceActor_StateFlags(a1)
                jsr     (sub_142D8).l
                move.w  $12(a2),d1
                move.w  (ram_FF18A6).l,d0
                bne.w   .loc_144F8
                move.w  #$400,d0

.loc_144F8:
                btst    #3,RaceActor_StateFlags(a1)
                bne.w   .loc_1451C
                asr.w   #1,d0
                add.w   d0,d1
                asr.w   #1,d0
                sub.w   d0,d1
                beq.w   .loc_14530
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_14538
                bra.w   .loc_14530


.loc_1451C:
                move.w  $12(a2),d1
                lsr.w   #1,d1
                beq.w   .loc_14530
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_14538

.loc_14530:
                move.w  d1,$12(a1)
                bsr.w   sub_14688

.loc_14538:
                move.w  8(a1),d0
                sub.w   8(a2),d0
                sub.w   d0,8(a1)
                move.w  8(a1),$C(a1)
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .locret_145EA
                move.w  $30(a1),d0
                sub.w   $30(a2),d0
                asl.w   #2,d0
                move.w  d0,8(a1)
                move.w  d0,$C(a1)
                move.w  (ram_FF18A6).l,d0
                bpl.w   .loc_14570
                neg.w   d0

.loc_14570:
                lsr.w   #8,d0
                lsr.w   #3,d0
                move.w  d0,$2C(a1)
                move.w  #0,$2E(a1)
                move.w  2(a1),d0
                addi.w  #$30,d0 ; '0'
                move.w  d0,$2A(a1)
                bset    #0,RaceActor_ControlFlags(a1)
                bra.w   .locret_145EA


.loc_14594:
                move.w  $12(a1),d0
                lsr.w   #8,d0
                lsr.w   #3,d0
                move.w  d0,$2C(a1)
                move.w  #0,$2E(a1)
                move.w  2(a1),d0
                add.w   (ram_FF303E).l,d0
                move.w  d0,$2A(a1)
                move.w  (ram_FF3040).l,RaceActor_CollisionOffset(a1)
                bclr    #4,RaceActor_ControlFlags(a1)
                bset    #0,RaceActor_ControlFlags(a1)
                cmpa.l  #RacePlayerA,a1
                bne.w   .locret_145EA
                move.b  #9,(ram_FF1AD6).l
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .locret_145EA
                move.b  #$16,(ram_FF1AD6).l

.locret_145EA:
                rts
; End of function Race_ApplyCollisionImpact





Race_UpdateCollisionSpeedState:
                move.w  $12(a1),d0
                move.w  $12(a2),d4
                cmpi.b  #$10,$71(a2)
                bmi.w   .loc_14616
                btst    #3,RaceActor_StateFlags(a2)
                beq.w   .loc_14616
                neg.w   d4
                sub.w   d4,d0
                bpl.w   .loc_14612
                neg.w   d0

.loc_14612:
                bra.w   .loc_14652


.loc_14616:
                sub.w   d4,d0
                bcc.w   .loc_14628
                neg.w   d1
                cmp.w   d1,d0
                bcs.w   .loc_14652
                bra.w   .loc_1462E


.loc_14628:
                cmp.w   d1,d0
                bcc.w   .loc_14652

.loc_1462E:
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .locret_14686
                move.b  #1,RaceActor_AnimState(a1)
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_1464E
                move.b  #9,(ram_FF1AD6).l

.loc_1464E:
                bra.w   .loc_1466A


.loc_14652:
                move.b  #0,RaceActor_AnimState(a1)
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_1466A
                move.b  #$A,(ram_FF1AD6).l

.loc_1466A:
                move.b  #$FF,RaceActor_AnimFrame(a1)
                asl.w   #1,d1
                cmp.w   d1,d0
                bcc.w   .loc_14682
                jsr     (sub_15538).l
                bra.w   .locret_14686


.loc_14682:
                bsr.w   sub_1555C

.locret_14686:
                rts
; End of function Race_UpdateCollisionSpeedState





sub_14688:
                move.l  (ram_FF3038).l,d0
                addi.l  #$3000,d0
                addi.l  #$200,d0
                btst    #0,RaceActor_StateFlags(a1)
                bne.w   .loc_146A6
                neg.l   d0

.loc_146A6:
                add.l   d0,4(a1)
                rts
; End of function sub_14688





Race_ApplyImpactSpeedLoss:
                move.w  $2C(a1),d1
                mulu.w  #$2000,d1
                swap    d1
                move.w  d1,$2C(a1)
                beq.w   .loc_14702
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_146EC
                move.w  $12(a1),d0
                move.w  d0,d1
                lsr.w   #3,d1
                beq.w   .loc_14702
                sub.w   d1,d0
                move.w  d0,$12(a1)
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_146EC
                move.w  #6,(ram_FF1AD6).l

.loc_146EC:
                move.w  2(a1),$2A(a1)
                move.w  #0,$2E(a1)
                bset    #0,RaceActor_ControlFlags(a1)
                bra.w   .loc_14708


.loc_14702:
                bclr    #0,RaceActor_ControlFlags(a1)

.loc_14708:
                cmpi.b  #0,RaceActor_AnimState(a1)
                bne.w   .locret_14718
                move.b  #1,RaceActor_AnimState(a1)

.locret_14718:
                rts
; End of function Race_ApplyImpactSpeedLoss


unk_1471A:      dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $B3
                dc.b $1A
                dc.b $66 ; f
                dc.b $58 ; X
                dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $B3
                dc.b $1A
                dc.b $66 ; f
                dc.b $58 ; X
                dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $B3
                dc.b $1A
                dc.b $66 ; f
                dc.b $58 ; X
                dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $99
                dc.b $84
                dc.b $4C ; L
                dc.b $C2
                dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $B3
                dc.b $1A
                dc.b $66 ; f
                dc.b $58 ; X
word_14742:     dc.w $4CC2
unk_14744:      dc.b   0
                dc.b   1
                dc.b $40 ; @
                dc.b $EE
                dc.b   0
                dc.b   1
                dc.b $44 ; D
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $41 ; A
                dc.b $AE
                dc.b   0
                dc.b   1
                dc.b $44 ; D
                dc.b $56 ; V
                dc.b   0
                dc.b   1
                dc.b $44 ; D
                dc.b $6E ; n
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $CC
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $B0
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $BE
Race_TrackObjectTypeTable:      dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   2
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
unk_147FC:      dc.b   0
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   1
                dc.b   7
                dc.b   7
                dc.b   7
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   6
                dc.b   6
                dc.b   6
                dc.b   6
                dc.b   6
                dc.b   0




Race_UpdateActorPairImpact:
                clr.w   (Race_ram_PairSpeedDeltaA).l
                clr.w   (Race_ram_PairSpeedDeltaB).l
                clr.w   (Race_ram_PairImpactA).l
                clr.w   (Race_ram_PairImpactB).l
                move.l  RaceActor_PreviousX(a1),d0
                sub.l   RaceActor_PreviousX(a2),d0
                bpl.w   .loc_148AE
                cmp.l   #$FFFFA000,d0
                bpl.w   .loc_148C0
                bra.w   .loc_148B8


.loc_148AE:
                cmp.l   (ram_FF3038).l,d0
                bmi.w   .loc_148C0

.loc_148B8:
                bsr.w   Race_ExchangeCollisionSpeed
                bra.w   .locret_1496A


.loc_148C0:
                bsr.w   Race_ClampActorPairY
                btst    #4,RaceActor_StateFlags(a1)
                beq.w   .loc_148D6
                tst.w   RaceActor_AttackReach(a1)
                bne.w   .loc_148F0

.loc_148D6:
                move.w  RaceActor_AttackOverlap(a1),d1
                add.w   d1,$22(a1)
                move.w  #0,RaceActor_AttackOverlap(a1)
                move.w  #0,(Race_ram_PairImpactB).l
                bra.w   .loc_1491E


.loc_148F0:
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_14910
                move.b  (ram_FF1ADB).l,d2
                cmp.b   $71(a2),d2
                bne.w   .loc_14910
                move.w  #3,(ram_FF0520).l

.loc_14910:
                cmpi.b  #1,RaceActor_AttackPhase(a1)
                bne.w   .loc_1491E
                bsr.w   Race_StealClub

.loc_1491E:
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_1493A
                btst    #4,RaceActor_StateFlags(a2)
                beq.w   .loc_1493A
                tst.w   RaceActor_AttackReach(a2)
                bne.w   .loc_14954

.loc_1493A:
                move.w  RaceActor_AttackOverlap(a2),d1
                add.w   d1,$22(a2)
                move.w  #0,RaceActor_AttackOverlap(a2)
                move.w  #0,(Race_ram_PairImpactA).l
                bra.w   .loc_14962


.loc_14954:
                cmpi.b  #1,RaceActor_AttackPhase(a2)
                bne.w   .loc_14962
                bsr.w   Race_StealClubMirror

.loc_14962:
                bsr.w   Race_AdjustActorTrackPositions
                bsr.w   Race_ApplyFallKnockdown

.locret_1496A:
                rts
; End of function Race_UpdateActorPairImpact





Race_ClampActorPairY:
                movem.l d0-d3,-(sp)
                move.w  $1A(a1),d0
                move.w  $1A(a2),d1
                move.w  $30(a1),d2
                move.w  $30(a2),d3
                cmp.w   d1,d0
                bpl.w   .loc_149A0
                add.w   RaceActor_CollisionExtentLower(a1),d2
                add.w   RaceActor_CollisionExtentUpper(a2),d2
                addi.w  #$10,d2
                cmp.w   d3,d2
                bmi.w   .loc_149B6
                move.w  d2,$30(a2)
                bra.w   .loc_149B6


.loc_149A0:
                sub.w   RaceActor_CollisionExtentUpper(a1),d2
                sub.w   RaceActor_CollisionExtentLower(a2),d2
                subi.w  #$10,d2
                cmp.w   d3,d2
                bpl.w   .loc_149B6
                move.w  d2,$30(a2)

.loc_149B6:
                sub.w   $30(a2),d3
                sub.w   d3,0.w(a2)
                movem.l (sp)+,d0-d3
                rts
; End of function Race_ClampActorPairY





Race_StealClub:
                move.w  RaceActor_AttackOverlap(a1),d1
                btst    #6,RaceActor_StateFlags(a1)
                beq.w   .loc_14A04
                move.w  $60(a1),d0
                muls.w  d0,d1
                asr.l   #8,d1
                move.w  d1,RaceActor_AttackOverlap(a1)
                cmpa.l  #RacePlayerA,a1
                bne.w   .locret_14B02
                move.w  d1,(Race_ram_PairSpeedDeltaA).l
                tst.w   (ram_FF1904).l
                beq.w   .locret_14B02
                move.b  #$14,(ram_FF1AD6).l
                bra.w   .locret_14B02


.loc_14A04:
                move.w  $5E(a1),d0
                muls.w  d0,d1
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_14A26
                tst.w   (ram_FF1904).l
                beq.w   .loc_14A26
                move.b  #$11,(ram_FF1AD6).l

.loc_14A26:
                asr.l   #8,d1
                move.w  d1,RaceActor_AttackOverlap(a1)
                bpl.w   .loc_14A32
                neg.w   d1

.loc_14A32:
                tst.b   RaceActor_AttackFlags(a1)
                bne.w   .loc_14A62
                move.w  $1A(a1),d0
                sub.w   $1A(a2),d0
                bpl.w   .loc_14A48
                neg.w   d0

.loc_14A48:
                sub.w   RaceActor_CollisionExtent(a1),d0
                sub.w   RaceActor_CollisionExtent(a2),d0
                cmp.w   #$A,d0
                bpl.w   .loc_14A62
                move.b  #$14,RaceActor_AttackTimer(a1)
                bra.w   .loc_14A72


.loc_14A62:
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .locret_14B02
                move.w  d1,(Race_ram_PairImpactB).l

.loc_14A72:
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .locret_14B02
                btst    #6,RaceActor_StateFlags(a2)
                bne.w   .loc_14AE4
                btst    #1,RaceActor_AttackFlags(a1)
                bne.w   .loc_14AE4
                btst    #1,RaceActor_AttackFlags(a2)
                beq.w   .loc_14AE4
                btst    #4,RaceActor_StateFlags(a2)
                beq.w   .loc_14AE4
                cmpi.b  #0,RaceActor_AttackPhase(a2)
                bne.w   .loc_14AE4
                bchg    #1,RaceActor_AttackFlags(a1)
                move.b  #2,RaceActor_AttackPhase(a1)
                move.b  #2,RaceActor_AttackPhase(a2)
                move.b  #$3C,RaceActor_AttackTimer(a1) ; '<'
                clr.b   RaceActor_AttackFlags(a2)
                move.b  #$3C,RaceActor_AttackTimer(a2) ; '<'
                move.b  #$15,(ram_FF1AD6).l
                move.w  #$1E,(Race_ram_EventTimer).l
                bra.w   .locret_14B02


.loc_14AE4:
                move.b  RaceActor_AttackFlags(a1),d2
                andi.w  #3,d2
                andi.b  #$FC,RaceActor_WeaponAnimFlags(a2)
                or.b    d2,RaceActor_WeaponAnimFlags(a2)
                bset    #2,RaceActor_WeaponAnimFlags(a2)
                move.b  #$1E,RaceActor_AnimTimer(a2)

.locret_14B02:
                rts
; End of function Race_StealClub





Race_StealClubMirror:
                move.w  RaceActor_AttackOverlap(a2),d1
                btst    #6,RaceActor_StateFlags(a2)
                beq.w   .loc_14B44
                move.w  $60(a2),d0
                muls.w  d0,d1
                asr.l   #8,d1
                move.w  d1,RaceActor_AttackOverlap(a2)
                move.w  d1,(Race_ram_PairSpeedDeltaB).l
                cmpa.l  (Race_ram_NearestActor).l,a2
                bne.w   .locret_14C3A
                tst.w   (ram_FF1906).l
                beq.w   .locret_14C3A
                move.b  #$14,(ram_FF1AD6).l
                bra.w   .locret_14C3A


.loc_14B44:
                move.w  $5E(a2),d0
                muls.w  d0,d1
                cmpa.l  (Race_ram_NearestActor).l,a2
                bne.w   .loc_14B66
                tst.w   (ram_FF1906).l
                beq.w   .loc_14B66
                move.b  #$11,(ram_FF1AD6).l

.loc_14B66:
                asr.l   #8,d1
                move.w  d1,RaceActor_AttackOverlap(a2)
                bpl.w   .loc_14B72
                neg.w   d1

.loc_14B72:
                tst.b   RaceActor_AttackFlags(a2)
                bne.w   .loc_14BA2
                move.w  $1A(a1),d0
                sub.w   $1A(a2),d0
                bpl.w   .loc_14B88
                neg.w   d0

.loc_14B88:
                sub.w   RaceActor_CollisionExtent(a1),d0
                sub.w   RaceActor_CollisionExtent(a2),d0
                cmp.w   #$A,d0
                bpl.w   .loc_14BA2
                move.b  #$14,RaceActor_AttackTimer(a2)
                bra.w   .loc_14BB4


.loc_14BA2:
                cmp.w   #$50,d1 ; 'P'
                ble.w   .loc_14BAE
                move.w  #$50,d1 ; 'P'

.loc_14BAE:
                move.w  d1,(Race_ram_PairImpactA).l

.loc_14BB4:
                btst    #6,RaceActor_StateFlags(a2)
                bne.w   .loc_14C1C
                btst    #1,RaceActor_AttackFlags(a2)
                bne.w   .loc_14C1C
                btst    #1,RaceActor_AttackFlags(a1)
                beq.w   .loc_14C1C
                btst    #4,RaceActor_StateFlags(a1)
                beq.w   .loc_14C1C
                cmpi.b  #0,RaceActor_AttackPhase(a1)
                bne.w   .loc_14C1C
                bchg    #1,RaceActor_AttackFlags(a2)
                bchg    #1,RaceActor_AttackFlags(a1)
                clr.b   RaceActor_AttackFlags(a1)
                move.b  #$3C,RaceActor_AttackTimer(a1) ; '<'
                move.b  #2,RaceActor_AttackPhase(a2)
                move.b  #$3C,RaceActor_AttackTimer(a2) ; '<'
                move.b  #$15,(ram_FF1AD6).l
                move.w  #$1E,(Race_ram_EventTimer).l
                bra.w   .locret_14C3A


.loc_14C1C:
                move.b  RaceActor_AttackFlags(a2),d2
                andi.w  #3,d2
                andi.b  #$FC,RaceActor_WeaponAnimFlags(a1)
                or.b    d2,RaceActor_WeaponAnimFlags(a1)
                bset    #2,RaceActor_WeaponAnimFlags(a1)
                move.b  #$1E,RaceActor_AnimTimer(a1)

.locret_14C3A:
                rts
; End of function Race_StealClubMirror





Race_ApplyFallKnockdown:
                tst.b   RaceActor_AnimState(a1)
                bpl.w   .loc_14C8C
                move.w  (Race_ram_PairImpactA).l,d0
                beq.w   .loc_14C8C
                mulu.w  (ram_FF18AC).l,d0
                sub.w   d0,$5C(a1)
                bcc.w   .loc_14C8C
                move.w  #0,$5C(a1)
                bset    #4,RaceActor_ControlFlags(a1)
                move.w  #$11,RaceActor_FallState(a1)
                move.b  #0,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_14C8C
                move.b  #$F,(ram_FF1AD6).l

.loc_14C8C:
                tst.b   RaceActor_AnimState(a2)
                bpl.w   .locret_14CEA
                move.w  (Race_ram_PairImpactB).l,d0
                beq.w   .locret_14CEA
                mulu.w  (ram_FF18AC).l,d0
                sub.w   d0,$5C(a2)
                bcc.w   .locret_14CEA
                move.w  #0,$5C(a2)
                bset    #4,RaceActor_ControlFlags(a2)
                move.w  #$11,RaceActor_FallState(a2)
                move.b  #0,RaceActor_AnimState(a2)
                move.b  #$FF,RaceActor_AnimFrame(a2)
                exg     a1,a2
                move.l  a2,-(sp)
                jsr     (Race_SaveActorShadow).l
                movea.l a1,a2
                movea.l (sp)+,a1
                cmpa.l  #RacePlayerA,a1
                bne.w   .locret_14CEA
                move.b  #$D,(ram_FF1AD6).l

.locret_14CEA:
                rts
; End of function Race_ApplyFallKnockdown





Race_ExchangeCollisionSpeed:
                move.w  #$1F40,d1
                bsr.w   Race_UpdateCollisionSpeedState
                move.w  d0,(ram_FF18A6).l
                move.w  $12(a2),d0
                sub.w   $12(a1),d0
                bpl.w   .loc_14D14
                neg.w   d0
                mulu.w  #$1999,d0
                swap    d0
                neg.w   d0
                bra.w   .loc_14D1A


.loc_14D14:
                mulu.w  #$1999,d0
                swap    d0

.loc_14D1A:
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_14D34
                move.w  d0,-(sp)
                jsr     (Race_ScaleImpactDamage).l
                add.w   d0,(Race_ram_BikeDamage).l
                move.w  (sp)+,d0

.loc_14D34:
                move.w  $12(a1),d1
                move.w  $12(a2),d2
                move.l  #$7000,d3
                cmp.w   d2,d1
                bpl.w   .loc_14D4A
                neg.l   d3

.loc_14D4A:
                btst    #0,RaceActor_StateFlags(a1)
                add.w   d0,d2
                sub.w   d0,d1
                move.l  4(a1),d0
                add.l   d3,d0
                move.l  d0,4(a2)
                move.w  d2,$12(a1)
                move.w  d1,$12(a2)
                move.b  RaceActor_StateFlags(a1),d0
                andi.w  #8,d0
                or.b    d0,RaceActor_StateFlags(a2)
                move.b  RaceActor_StateFlags(a2),d0
                andi.w  #8,d0
                or.b    d0,RaceActor_StateFlags(a1)
                bsr.w   Race_AdjustActorTrackPositions
                rts
; End of function Race_ExchangeCollisionSpeed





Race_AdjustActorTrackPositions:
                move.w  $22(a2),d0
                sub.w   $22(a1),d0
                ext.l   d0
                divs.w  (Race_ram_FrameDelay).l,d0
                bpl.w   .loc_14DA8
                neg.w   d0
                mulu.w  (ram_FF18B6).l,d0
                swap    d0
                neg.w   d0
                bra.w   .loc_14DB0


.loc_14DA8:
                mulu.w  (ram_FF18B6).l,d0
                swap    d0

.loc_14DB0:
                move.w  $C(a1),d1
                add.w   (Race_ram_PairSpeedDeltaA).l,d1
                move.w  $C(a2),d2
                add.w   (Race_ram_PairSpeedDeltaB).l,d2
                btst    #1,RaceActor_StateFlags(a1)
                beq.w   .loc_14DD6
                add.w   d0,d2
                sub.w   d0,d1
                bra.w   .loc_14DDA


.loc_14DD6:
                sub.w   d0,d2
                add.w   d0,d1

.loc_14DDA:
                move.w  d2,$C(a1)
                move.w  d2,8(a1)
                move.w  d1,$C(a2)
                move.w  d1,8(a2)
                rts
; End of function Race_AdjustActorTrackPositions


                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $68 ; h
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $40 ; @
                dc.b $32 ; 2
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $68 ; h
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $41 ; A
                dc.b $90
                dc.b $41 ; A
                dc.b $E0
                dc.b $40 ; @
                dc.b $34 ; 4
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $30 ; 0
                dc.b $4A ; J
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $16
                dc.b $32 ; 2
                dc.b $29 ; )
                dc.b   0
                dc.b $22 ; "
                dc.b $92
                dc.b $6A ; j
                dc.b   0
                dc.b $22 ; "
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $48 ; H
                dc.b $C1
                dc.b $83
                dc.b $C2
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $32 ; 2
                dc.b $3C ; <
                dc.b   0
                dc.b   1
                dc.b $4E ; N
                dc.b $75 ; u




sub_14E38:
                tst.w   (Race_ram_GameEnded).l
                beq.w   .loc_14E58
                jsr     (Audio_Engine1Stop).l
                jsr     (Audio_Engine2Stop).l
                jsr     (Audio_Engine3Stop).l
                bra.w   .loc_14E62


.loc_14E58:
                tst.w   (Race_ram_State).l
                beq.w   .loc_14E7A

.loc_14E62:
                jsr     (Audio_StopMusicChannel3).l
                jsr     (Audio_StopMusicChannel4).l
                move.b  #0,(ram_FF1AD5).l
                bra.w   .loc_14FA2


.loc_14E7A:
                clr.l   d0
                btst    #5,(RacePlayerA + RaceActor_ControlFlags).l
                beq.w   .loc_14E9A
                btst    #3,(RacePlayerA + RaceActor_ControlFlags).l
                bne.w   .loc_14EB2
                moveq   #1,d0
                bra.w   .loc_14EB4


.loc_14E9A:
                cmpi.b  #1,(RacePlayerA + RaceActor_AnimState).l
                bne.w   .loc_14ECE
                btst    #0,(RacePlayerA + RaceActor_ControlFlags).l
                bne.w   .loc_14ECE

.loc_14EB2:
                moveq   #2,d0

.loc_14EB4:
                cmp.b   (ram_FF1AD4).l,d0
                beq.w   .loc_14EE6
                move.b  d0,(ram_FF1AD4).l
                jsr     (Audio_PlaySfx).l
                bra.w   .loc_14EE6


.loc_14ECE:
                tst.w   (ram_FF1AD4).l
                beq.w   .loc_14EE6
                move.b  #0,(ram_FF1AD4).l
                jsr     (Audio_StopMusicChannel3).l

.loc_14EE6:
                tst.w   (Race_ram_EventTimer).l
                beq.w   .loc_14F1E
                move.w  (Race_ram_EventTimer).l,d0
                sub.w   (Race_ram_FrameDelay).l,d0
                ble.w   .loc_14F16
                move.w  d0,(Race_ram_EventTimer).l
                cmpi.b  #$15,(ram_FF1AD6).l
                beq.w   .loc_14F1E
                bra.w   .loc_14F58


.loc_14F16:
                move.w  #0,(Race_ram_EventTimer).l

.loc_14F1E:
                clr.l   d0
                move.b  (ram_FF1AD6).l,d0
                beq.w   .loc_14F34
                jsr     (Audio_PlaySfx).l
                bra.w   .loc_14F58


.loc_14F34:
                clr.l   d0
                move.b  (ram_FF1AD7).l,d0
                beq.w   .loc_14F58
                cmp.b   #$E,d0
                bne.w   .loc_14F52
                tst.b   (ram_FF1ADD).l
                beq.w   .loc_14F58

.loc_14F52:
                jsr     (Audio_PlaySfx).l

.loc_14F58:
                tst.w   (ram_FF1B32).l
                bne.w   .loc_14FA2
                move.w  (ram_FF1F2E).l,d0
                sub.w   (RacePlayerA + RaceActor_X).l,d0
                bpl.w   .loc_14F74
                neg.w   d0

.loc_14F74:
                cmp.w   #$18,d0
                bpl.w   .loc_14FA2
                move.w  d0,d1
                asl.w   #1,d0
                add.w   d0,d1
                addq.w  #6,d1
                jsr     (Audio_SetEngineDistance).l
                moveq   #5,d0
                cmp.b   (ram_FF1AD5).l,d0
                beq.w   .loc_14FA2
                move.b  d0,(ram_FF1AD5).l
                jsr     (Audio_PlaySfx).l

.loc_14FA2:
                move.b  #0,(ram_FF1AD6).l
                move.b  #0,(ram_FF1AD7).l
                rts
; End of function sub_14E38





sub_14FB4:
                move.w  d0,-(sp)
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,(ram_FF1AD0).l
                bcc.w   .loc_15010
                move.w  #$12,(ram_FF1AD0).l
                addi.w  #1,(ram_FF1ACE).l
                move.w  (ram_FF1ACE).l,d0
                btst    #0,d0
                beq.w   .loc_15000
                tst.b   RaceActor_AnimState(a1)
                bpl.w   .loc_15000
                cmpi.w  #5,(Race_ram_PlayerPlace).l
                bpl.w   .loc_15000
                move.b  #$15,(ram_FF1AD6).l

.loc_15000:
                cmp.w   #$A,d0
                bmi.w   .loc_15010
                move.w  #1,(Race_ram_GameEnded).l

.loc_15010:
                move.w  (sp)+,d0
                rts
; End of function sub_14FB4





sub_15014:
                movem.l d1-d7/a0-a2,-(sp)
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (Race_ActorShadowTable).l,a0
                movea.l (a0,d0.w),a2
                move.l  a2,(ram_FF1AF6).l
                bsr.w   sub_1533E
                move.w  RaceActor_FallState(a1),d0
                cmp.w   #$11,d0
                ble.w   .loc_15048
                move.w  #$11,d0
                move.w  d0,RaceActor_FallState(a1)

.loc_15048:
                asl.w   #2,d0
                lea     (unk_155D0).l,a0
                movea.l (a0,d0.w),a0

.loc_15054:
                move.b  RaceActor_AnimTimer(a1),d2
                move.b  RaceActor_AnimFrame(a1),d1
                bpl.w   *+4

.loc_15060:
                move.b  RaceActor_AnimState(a1),d0
                ext.w   d0
                asl.w   #3,d0
                movea.l (a0,d0.w),a3
                cmpa.l  #$FFFFFFFF,a3
                beq.w   .loc_151DE
                movea.l 4(a0,d0.w),a5
                movea.l a3,a4
                cmpi.b  #3,RaceActor_AnimState(a1)
                bne.w   .loc_150EE
                move.w  #$B0,(ram_FF18BC).l
                move.l  $26(a1),d3
                lsr.l   #8,d3
                move.w  $22(a1),d4
                bpl.w   .loc_1509E
                neg.w   d4

.loc_1509E:
                cmp.w   d4,d3
                bmi.w   .loc_150E0
                btst    #3,RaceActor_StateFlags(a1)
                bne.w   .loc_150C0
                move.w  4(a1),d7
                cmp.w   (Race_ram_PlayerProgress).l,d7
                bpl.w   .loc_150EE
                bra.w   .loc_150CE


.loc_150C0:
                move.w  4(a1),d7
                cmp.w   (Race_ram_PlayerProgress).l,d7
                bmi.w   .loc_150EE

.loc_150CE:
                lea     (unk_15CE0).l,a4
                move.w  #$B1,(ram_FF18BC).l
                bra.w   .loc_150EE


.loc_150E0:
                lea     (unk_15CFC).l,a4
                move.w  #$B2,(ram_FF18BC).l

.loc_150EE:
                bsr.w   sub_154D2
                tst.w   d0
                bpl.w   .loc_1510A
                bsr.w   sub_151F0
                cmpi.b  #$FF,RaceActor_AnimState(a1)
                beq.w   .loc_151DE
                bra.w   .loc_15054


.loc_1510A:
                move.w  d0,$58(a1)
                move.b  d1,RaceActor_AnimFrame(a1)
                move.b  d2,RaceActor_AnimTimer(a1)
                cmpi.b  #3,RaceActor_AnimState(a1)
                bne.w   .loc_15148
                move.l  $26(a1),d0
                or.w    $22(a1),d0
                bne.w   .loc_15138
                move.w  (ram_FF18BC).l,$58(a1)
                bra.w   .loc_1514C


.loc_15138:
                tst.w   $22(a1)
                beq.w   .loc_1514C
                bpl.w   .loc_15148
                bset    #0,d3

.loc_15148:
                move.b  d3,$76(a1)

.loc_1514C:
                move.w  RaceActor_FallState(a2),d0
                cmp.w   #$11,d0
                ble.w   .loc_15160
                move.w  #$11,d0
                move.w  d0,RaceActor_FallState(a1)

.loc_15160:
                asl.w   #2,d0
                lea     (unk_155D0).l,a0
                movea.l (a0,d0.w),a0

.loc_1516C:
                move.b  RaceActor_AnimTimer(a2),d2
                move.b  RaceActor_AnimFrame(a2),d1
                move.b  RaceActor_AnimState(a2),d0
                tst.w   $12(a2)
                bne.w   .loc_15198
                cmp.b   #4,d0
                beq.w   .loc_15198
                move.b  #3,d0
                move.b  d0,RaceActor_AnimState(a2)
                move.b  #$FF,d1
                move.b  #0,d2

.loc_15198:
                ext.w   d0
                asl.w   #3,d0
                movea.l 4(a0,d0.w),a4
                cmpa.l  #$FFFFFFFF,a4
                bne.w   .loc_151B4
                move.b  #$FF,RaceActor_AnimState(a2)
                bra.w   .loc_151EA


.loc_151B4:
                bsr.w   sub_154D2
                tst.w   d0
                bpl.w   .loc_151CA
                bsr.w   sub_15446
                move.b  #0,RaceActor_AnimTimer(a2)
                bra.s   .loc_1516C


.loc_151CA:
                move.w  d0,$58(a2)
                move.b  d1,RaceActor_AnimFrame(a2)
                move.b  d2,RaceActor_AnimTimer(a2)
                move.b  d3,$76(a2)
                bra.w   .loc_151EA


.loc_151DE:
                move.b  #$FF,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimState(a2)

.loc_151EA:
                movem.l (sp)+,d1-d7/a0-a2
                rts
; End of function sub_15014





sub_151F0:
                movem.l d0-d1,-(sp)
                cmpi.b  #1,RaceActor_AnimState(a1)
                bmi.w   .loc_1521C
                bne.w   .loc_1522C
                cmpi.w  #0,$12(a1)
                bne.w   .loc_1521C
                move.b  #2,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                bra.w   .loc_15338


.loc_1521C:
                move.b  #1,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                bra.w   .loc_15338


.loc_1522C:
                cmpi.b  #3,RaceActor_AnimState(a1)
                blt.w   .loc_152AA
                beq.w   .loc_1524A
                move.b  #$FF,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                bra.w   .loc_15338


.loc_1524A:
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   .loc_1526C
                move.l  4(a1),d0
                sub.l   4(a2),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_152AA
                bra.w   .loc_1527E


.loc_1526C:
                move.l  4(a2),d0
                sub.l   4(a1),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_152AA

.loc_1527E:
                move.w  $1A(a2),d0
                sub.w   $1A(a1),d0
                bpl.w   .loc_1529A
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                bmi.w   .loc_152AA
                bra.w   .loc_152D6


.loc_1529A:
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                cmp.w   #$40,d0 ; '@'
                ble.w   .loc_152D6

.loc_152AA:
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_152C6
                tst.w   (Race_CopIndex).l
                beq.w   .loc_152C6
                move.w  #1,(Race_ram_GameEnded).l

.loc_152C6:
                move.b  #3,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                bra.w   .loc_15338


.loc_152D6:
                bclr    #3,RaceActor_StateFlags(a1)
                move.w  #0,8(a1)
                move.w  #0,$C(a1)
                move.w  #0,$12(a1)
                move.w  #0,$12(a2)
                move.l  4(a1),d0
                subi.l  #$2000,d0
                move.l  d0,4(a2)
                move.w  #$20,d1 ; ' '
                move.w  $30(a1),d0
                bmi.w   .loc_15310
                lsr.w   #1,d1

.loc_15310:
                add.w   d1,d0
                move.w  d0,$30(a2)
                move.w  0.w(a1),d0
                add.w   d1,d0
                move.w  d0,0.w(a2)
                move.b  #4,RaceActor_AnimState(a1)
                move.b  #4,RaceActor_AnimState(a2)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                move.b  #$FF,RaceActor_AnimFrame(a2)

.loc_15338:
                movem.l (sp)+,d0-d1
                rts
; End of function sub_151F0





sub_1533E:
                movem.l d0-d1,-(sp)
                cmpi.b  #1,RaceActor_AnimState(a1)
                bmi.w   .loc_15440
                bne.w   .loc_1536A
                cmpi.w  #0,$12(a1)
                bne.w   .loc_15440
                move.b  #2,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                bra.w   .loc_15440


.loc_1536A:
                cmpi.b  #4,RaceActor_AnimState(a1)
                beq.w   .loc_153FC
                cmpi.b  #3,RaceActor_AnimState(a1)
                bne.w   .loc_15440
                move.l  RaceActor_PreviousX(a2),d0
                sub.l   RaceActor_PreviousX(a1),d0
                bpl.w   .loc_153A0
                move.l  4(a1),d0
                sub.l   4(a2),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_15440
                bra.w   .loc_153B2


.loc_153A0:
                move.l  4(a2),d0
                sub.l   4(a1),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_15440

.loc_153B2:
                move.w  $1A(a2),d0
                sub.w   $1A(a1),d0
                bpl.w   .loc_153CE
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                blt.w   .loc_15440
                bra.w   .loc_153DE


.loc_153CE:
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                cmp.w   #$40,d0 ; '@'
                bgt.w   .loc_15440

.loc_153DE:
                bclr    #3,RaceActor_StateFlags(a1)
                move.b  #4,RaceActor_AnimState(a1)
                move.b  #4,RaceActor_AnimState(a2)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                move.b  #$FF,RaceActor_AnimFrame(a2)

.loc_153FC:
                move.w  #0,8(a1)
                move.w  #0,$C(a1)
                move.w  #0,$12(a1)
                move.w  #0,$12(a2)
                move.l  4(a1),d0
                subi.l  #$2000,d0
                move.l  d0,4(a2)
                move.w  #$20,d1 ; ' '
                move.w  $30(a1),d0
                bmi.w   .loc_15430
                lsr.w   #1,d1

.loc_15430:
                add.w   d1,d0
                move.w  d0,$30(a2)
                move.w  0.w(a1),d0
                add.w   d1,d0
                move.w  d0,0.w(a2)

.loc_15440:
                movem.l (sp)+,d0-d1
                rts
; End of function sub_1533E





sub_15446:
                move.w  d0,-(sp)
                move.b  RaceActor_AnimState(a2),d0
                cmp.b   #3,d0
                bne.w   .loc_15468
                bra.w   .loc_1546E

                dc.b $4A ; J
                dc.b $6A ; j
                dc.b   0
                dc.b $12
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $10
                dc.b $3C ; <
                dc.b   0
                dc.b   2


.loc_15468:
                addq.b  #1,d0
                move.b  d0,RaceActor_AnimState(a2)

.loc_1546E:
                move.b  #$FF,RaceActor_AnimFrame(a2)
                move.w  (sp)+,d0
                rts
; End of function sub_15446





sub_15478:
                movem.l d1-d7/a0-a2,-(sp)
                lea     (unk_155A4).l,a0

.loc_15482:
                move.b  (ram_FF302B).l,d2
                move.b  (ram_FF302A).l,d1
                move.w  #0,d0
                move.w  #0,d0
                lea     (unk_155AC).l,a4
                bsr.w   sub_154D2
                tst.w   d0
                bpl.w   .loc_154C0
                move.w  #1,(Race_ram_Started).l
                move.b  #0,(ram_FF302A).l
                move.b  #0,(ram_FF302B).l
                bra.s   .loc_15482


.loc_154C0:
                move.b  d1,(ram_FF302A).l
                move.b  d2,(ram_FF302B).l
                movem.l (sp)+,d1-d7/a0-a2
                rts
; End of function sub_15478





sub_154D2:
                tst.b   d1
                bmi.w   .loc_15506
                sub.b   (ram_FF304B).l,d2
                bpl.w   .loc_1550C
                add.b   2(a4),d2
                bpl.w   .loc_1550A

.loc_154EA:
                addq.b  #1,d1
                move.b  d1,d4
                ext.w   d4
                asl.w   #2,d4
                move.b  3(a4,d4.w),d0
                ext.w   d0
                bmi.w   .loc_1552A
                add.b   2(a4),d2
                bmi.s   .loc_154EA
                bra.w   .loc_15516


.loc_15506:
                move.b  2(a4),d2

.loc_1550A:
                addq.b  #1,d1

.loc_1550C:
                move.b  d1,d4
                ext.w   d4
                asl.w   #2,d4
                move.b  3(a4,d4.w),d0

.loc_15516:
                move.b  4(a4,d4.w),d3
                move.b  5(a4,d4.w),d5
                move.b  6(a4,d4.w),d6
                ext.w   d0
                bmi.w   .loc_1552A
                add.w   (a4),d0

.loc_1552A:
                cmp.w   (word_3C7EA).l,d0
                bmi.w   .locret_15536
                nop

.locret_15536:
                rts
; End of function sub_154D2





sub_15538:
                movem.l d0/a4,-(sp)
                jsr     (Rand_GetWord).l
                andi.w  #3,d0
                lea     (unk_15618).l,a4
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,RaceActor_FallState(a1)
                movem.l (sp)+,d0/a4
                rts
; End of function sub_15538





sub_1555C:
                movem.l d0/a4,-(sp)
                jsr     (Rand_GetWord).l
                andi.w  #7,d0
                lea     (unk_15624).l,a4
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,RaceActor_FallState(a1)
                movem.l (sp)+,d0/a4
                rts
; End of function sub_1555C


                dc.b $48 ; H
                dc.b $E7
                dc.b $80
                dc.b   8
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $60 ; `
                dc.b $34 ; 4
                dc.b   2
                dc.b $40 ; @
                dc.b   0
                dc.b   7
                dc.b $49 ; I
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $1C
                dc.b $10
                dc.b $34 ; 4
                dc.b   0
                dc.b   0
                dc.b $48 ; H
                dc.b $80
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $54 ; T
                dc.b $4C ; L
                dc.b $DF
                dc.b $10
                dc.b   1
                dc.b $4E ; N
                dc.b $75 ; u
unk_155A4:      dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $AC
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
unk_155AC:      dc.b   1
                dc.b $5E ; ^
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
unk_155D0:      dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $60 ; `
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $8C
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $B8
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $10
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $3C ; <
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $68 ; h
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $C0
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $EC
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $2C ; ,
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $B0
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $DC
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b   8
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $18
unk_15618:      dc.b   6
                dc.b  $A
                dc.b  $B
                dc.b  $C
                dc.b   7
                dc.b  $A
                dc.b   2
                dc.b   3
                dc.b  $D
                dc.b  $B
                dc.b  $E
                dc.b   7
unk_15624:      dc.b   0
                dc.b   3
                dc.b  $E
                dc.b  $F
                dc.b $10
                dc.b  $C
                dc.b   7
                dc.b   8
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $F8
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $28 ; (
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $44 ; D
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $90
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b  $C
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $90
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $48 ; H
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $30 ; 0
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $50 ; P
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $B8
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $90
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $20
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $D4
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $F0
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $D4
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $D4
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $A4
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b $10
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b $10
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b $10
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $B3
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
unk_15CE0:      dc.b   0
                dc.b $B3
                dc.b   4
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
unk_15CFC:      dc.b   0
                dc.b $B3
                dc.b   4
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $11
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $C5
                dc.b   8
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b $1C
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b  $A
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   9
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b  $C
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b  $C
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   4
                dc.b   1
                dc.b   0
                dc.b $13
                dc.b   4
                dc.b   2
                dc.b   0
                dc.b $17
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b $15
                dc.b   3
                dc.b   2
                dc.b   0
                dc.b $12
                dc.b   3
                dc.b $FF
byte_15FA8:     dc.b $3D
                dc.b $52 ; R
                dc.b $7F ; 
                dc.b $31 ; 1
                dc.b $80
                dc.b $A2
                dc.b $ED
                dc.b $16
                dc.b $42 ; B
                dc.b $BF
                dc.b $5C ; 
                dc.b $41 ; A
                dc.b  $C
                dc.b $5E ; ^
                dc.b $92
                dc.b $26 ; &
                dc.b $A5
                dc.b $8B
                dc.b $48 ; H
                dc.b $2D ; -
                dc.b $64 ; d
                dc.b $D9
                dc.b $82
                dc.b $AD
                dc.b $E1
                dc.b $79 ; y
                dc.b $21 ; !
                dc.b $4B ; K
                dc.b $81
                dc.b $4C ; L
                dc.b $D7
                dc.b $36 ; 6
                dc.b $97
                dc.b $CF
                dc.b $AE
                dc.b $B1
                dc.b $F7
                dc.b $CB
                dc.b $6A ; j
                dc.b $9B
                dc.b  $C
                dc.b $59 ; Y
                dc.b $85
                dc.b $34 ; 4
                dc.b $71 ; q
                dc.b $89
                dc.b $15
                dc.b $93
                dc.b $6B ; k
                dc.b $C5
                dc.b   7
                dc.b $AC
                dc.b $3C ; <
                dc.b $7F ; 
                dc.b $A4
                dc.b $3E ; >
                dc.b $DA
                dc.b $69 ; i
                dc.b $18
                dc.b $1E
                dc.b $9B
                dc.b $D1
                dc.b $D5
                dc.b $7F ; 




 ; *************************************************
; Function Rand_Init
; Seeds/copies the 32-word sum PRNG state and sets the indexes.
; In:  d0 - seed
; Out: ram_FF18BE (32 words), ram_FF18FE/ram_FF1900
; Clobbers: d0/d1/a0/a1
; *************************************************

Rand_Init:
                movem.l d0-d1/a0-a1,-(sp)
                move.w  d0,d1

                lea     (byte_15FA8).l,a0
                lea     (ram_FF18BE).l,a1
                move.w  #$20,d0
.loc_15FFE:
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_15FFE

                lea     (ram_FF18BE).l,a0
                move.w  #$20,d0
.loc_1600E:
                add.w   d1,(a0)+
                dbf     d0,.loc_1600E

                lsl.w   #7,d1
                andi.w  #$1F,d1
                move.w  d1,(ram_FF18FE).l

                addi.w  #$F,d1
                andi.w  #$1F,d1
                move.w  d1,(ram_FF1900).l

                movem.l (sp)+,d0-d1/a0-a1
                rts
; End of function Rand_Init





 ; *************************************************
; Function Rand_GetWord
; Returns state[i1]+state[i2] and advances both indexes (lagged sum PRNG).
; In:  ram_FF18BE/18FE/1900
; Out: d0 - word
; Clobbers: d0-d2/a0
; *************************************************

Rand_GetWord:
                movem.l d1-d2/a0,-(sp)
                move.w  (ram_FF18FE).l,d1
                lsl.w   #1,d1
                move.w  (ram_FF1900).l,d2
                lsl.w   #1,d2
                lea     (ram_FF18BE).l,a0
                move.w  (a0,d1.w),d0
                add.w   (a0,d2.w),d0
                move.w  d0,(a0,d1.w)
                addq.w  #1,(ram_FF18FE).l
                andi.w  #$1F,(ram_FF18FE).l
                addq.w  #1,(ram_FF1900).l
                andi.w  #$1F,(ram_FF1900).l
                movem.l (sp)+,d1-d2/a0
                rts
; End of function Rand_GetWord





sub_1607C:
                bsr.s   Rand_GetWord
                lsr.w   #8,d0
                andi.l  #$FF,d0
                rts
; End of function sub_1607C





sub_16088:
                move.w  #$563A,(ram_FF1B42).l
                move.w  #$563A,(ram_FF1B44).l
                rts
; End of function sub_16088





sub_1609A:
                move.w  (ram_FF1B42).l,d0
                lsr.w   #1,d0
                bcc.s   .loc_160A8
                eori.w  #$B400,d0

.loc_160A8:
                move.w  d0,(ram_FF1B42).l
                rts
; End of function sub_1609A





sub_160B0:
                moveq   #0,d0
                move.w  (ram_FF1B42).l,d0
                lsr.w   #1,d0
                bcc.s   .loc_160C0
                eori.w  #$B400,d0

.loc_160C0:
                move.w  d0,(ram_FF1B42).l
                divs.w  d2,d0
                swap    d0
                rts
; End of function sub_160B0





sub_160CC:
                move.w  (ram_FF1B44).l,d0
                lsr.w   #1,d0
                bcc.s   .loc_160DA
                eori.w  #$B400,d0

.loc_160DA:
                move.w  d0,(ram_FF1B44).l
                rts
; End of function sub_160CC





 ; *************************************************
; Function Race_UpdatePlayerAnimation
; Advances the player tile base $5C toward ram_FF18AA by the frame delay.
; In:  RacePlayerA $5C/$6E/$68; Race_ram_FrameDelay
; Out: player $5C
; Clobbers: d0
; *************************************************

Race_UpdatePlayerAnimation:
                lea     (RacePlayerA).l,a1
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_160FA
                tst.b   RaceActor_AnimState(a1)
                bpl.w   .locret_16118

.loc_160FA:
                move.w  $5C(a1),d0
                add.w   (Race_ram_FrameDelay).l,d0
                cmp.w   (ram_FF18AA).l,d0
                bcs.w   .loc_16114
                move.w  (ram_FF18AA).l,d0

.loc_16114:
                move.w  d0,$5C(a1)

.locret_16118:
                rts
; End of function Race_UpdatePlayerAnimation

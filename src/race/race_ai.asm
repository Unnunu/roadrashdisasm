; *************************************************
; race_ai.asm - actor/input/AI/physics
; ROM range: $10E00-$14055 (race_anim_audio starts at $14056)
; *************************************************

sub_10E00:
                move.w  $12(a1),d0
                beq.w   .loc_10E12
                cmpi.b  #3,RaceActor_AnimState(a1)
                bne.w   .loc_10E18

.loc_10E12:
                clr.l   d0
                bra.w   .loc_10E3A


.loc_10E18:
                move.w  (Race_ram_FrameDelay).l,d1
                sub.w   d1,(a2)
                bgt.w   .locret_10E3C
                lsr.w   #8,d0
                subi.w  #$10,d0
                neg.w   d0
                bpl.w   .loc_10E32
                clr.w   d0

.loc_10E32:
                move.w  d0,(a2)+
                move.l  (a2),d0
                swap    d0
                move.l  d0,(a2)

.loc_10E3A:
                move.l  d0,(a0)

.locret_10E3C:
                rts
; End of function sub_10E00


unk_10E3E:      dc.b $18
                dc.b $10
                dc.b   6
                dc.b   1
                dc.b $FA
                dc.b $F0
                dc.b $E8
                dc.b   0
                dc.b $11
                dc.b   8
                dc.b   1
                dc.b $FC
                dc.b $F7
                dc.b $F2
                dc.b $EC
                dc.b   0
                dc.b  $B
                dc.b   3
                dc.b $F7
                dc.b $F7
                dc.b $F7
                dc.b $F2
                dc.b $E8
                dc.b   0
                dc.b $FA
                dc.b $F6
                dc.b $F1
                dc.b $F1
                dc.b $F1
                dc.b $EE
                dc.b $E6
                dc.b   0
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b   0

; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_UpdateActorAI
; Main actor AI loop: walks the actor list, applies speed/lean/movement and handles
; the player's on-foot/normal input branches.
; In:  ram_FF1A08 actor list; Race_ram_FrameDelay/CurrentButtons
; Out: actor fields; Race_ram_ActiveActorList/1D50-related movement state
; Clobbers: all
; *************************************************

Race_UpdateActorAI:
                bset    #6,(RacePlayerA + RaceActor_ControlFlags).l
                lea     (ram_FF1A08).l,a2

.loc_10E74:
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .locret_11038
                btst    #7,RaceActor_ControlFlags(a1)
                move.w  $14(a1),d1
                beq.w   .loc_10EB8
                btst    #3,RaceActor_ControlFlags(a1)
                beq.w   .loc_10E9C
                move.w  d1,d0
                asr.w   #2,d0
                sub.w   d0,d1

.loc_10E9C:
                move.w  (Race_ram_FrameDelay).l,d2
                muls.w  d2,d1
                move.w  $12(a1),d0
                add.w   d1,d0
                move.w  d0,$12(a1)
                bpl.w   .loc_10EB8
                move.w  #0,$12(a1)

.loc_10EB8:
                move.w  $12(a1),d0
                move.w  (Race_ram_FrameDelay).l,d2
                mulu.w  d2,d0
                move.l  d0,$26(a1)
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_10F2A
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_10F2A
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_10EF8
                cmpi.b  #3,RaceActor_AnimState(a1)
                bne.w   .loc_10EF8
                bsr.w   Race_HandleInputOnFoot
                bra.w   .loc_10F6C


.loc_10EF8:
                bsr.w   sub_113CA
                bsr.w   Race_UpdateBikeCurve
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_10F14
                btst    #3,RaceActor_StateFlags(a1)
                bne.w   .loc_10F22

.loc_10F14:
                bclr    #3,RaceActor_ControlFlags(a1)
                bsr.w   Race_UpdateActorX
                bra.w   .loc_10F6C


.loc_10F22:
                bsr.w   Race_UpdateActorFallMovement
                bra.w   .loc_10F6C


.loc_10F2A:
                btst    #6,RaceActor_ControlFlags(a1)
                bne.w   .loc_10F3C
                bsr.w   Race_AdvanceActorProgress
                bra.w   .loc_11034


.loc_10F3C:
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_10F58
                cmpi.b  #3,RaceActor_AnimState(a1)
                bne.w   .loc_10F58
                bsr.w   Race_HandleInputOnFoot
                bra.w   .loc_10F6C


.loc_10F58:
                tst.w   $12(a1)
                beq.w   .loc_10F6C
                bsr.w   sub_113A4
                bsr.w   Race_UpdateBikeCurve
                bsr.w   Race_UpdateActorMovement

.loc_10F6C:
                move.w  $36(a1),d1
                move.w  d1,d3
                sub.w   0.w(a1),d1
                bpl.w   .loc_10FAC
                cmp.w   #$FCA0,d1
                bpl.w   .loc_10F9A
                neg.w   d1
                subi.w  #$360,d1
                sub.w   d1,$22(a1)
                move.w  #$FCA0,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)
                bra.w   .loc_10FAC


.loc_10F9A:
                cmp.w   #$FF20,d1
                bpl.w   .loc_10FD8
                bset    #3,RaceActor_ControlFlags(a1)
                bra.w   .loc_10FDE


.loc_10FAC:
                cmp.w   #$360,d1
                bmi.w   .loc_10FC6
                subi.w  #$360,d1
                add.w   d1,$22(a1)
                move.w  #$360,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)

.loc_10FC6:
                cmp.w   #$E0,d1
                bmi.w   .loc_10FD8
                bset    #3,RaceActor_ControlFlags(a1)
                bra.w   .loc_10FDE


.loc_10FD8:
                bclr    #3,RaceActor_ControlFlags(a1)

.loc_10FDE:
                neg.w   d1
                move.w  d1,$30(a1)
                bsr.w   Race_SetupActorSprite
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_11018
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_11018
                tst.w   (ram_FF1ACC).l
                beq.w   .loc_11010
                move.w  $1A(a1),$30(a1)
                bra.w   .loc_1101C


.loc_11010:
                bsr.w   Race_ApplyCrashImpact
                bra.w   .loc_1101C


.loc_11018:
                bsr.w   sub_12BD2

.loc_1101C:
                cmpi.b  #$10,$71(a1)
                bpl.w   .loc_11034
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_11034
                bsr.w   sub_1180C

.loc_11034:
                bra.w   .loc_10E74


.locret_11038:
                rts
; End of function Race_UpdateActorAI


; =============== S U B R O U T I N E =======================================


Race_AdvanceActorProgress:
                move.l  d0,-(sp)
                move.w  $30(a1),$1A(a1)
                move.w  $32(a1),$1C(a1)
                move.l  $26(a1),d0
                move.l  4(a1),d4
                move.l  d4,RaceActor_PreviousX(a1)
                add.l   d4,d0
                move.l  d0,4(a1)
                swap    d4
                cmp.w   (RaceTrack_Data1).l,d4
                bmi.w   .loc_1107E
                btst    #7,RaceActor_ControlFlags(a1)
                bne.w   .loc_1107E
                bset    #7,RaceActor_ControlFlags(a1)
                move.l  (Race_ram_ProgressSnapshotB).l,$62(a1)

.loc_1107E:
                move.w  d1,2(a1)
                bclr    #4,RaceActor_ControlFlags(a1)
                move.b  #$FF,RaceActor_AnimState(a1)
                move.w  #0,$32(a1)
                move.w  #0,$2E(a1)
                bclr    #0,RaceActor_ControlFlags(a1)
                move.w  #0,$2C(a1)
                bsr.w   sub_12BD2
                move.l  (sp)+,d0
                rts
; End of function Race_AdvanceActorProgress


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_HandleInputOnFoot
; On-foot input/AI for player A: reads the pad and updates turn/speed/lean fields.
; In:  a1 - actor; Race_ram_CurrentButtons/FrameDelay; unk_258AE
; Out: actor fields 8/$12/$22/$26/$69
; Clobbers: d0-d3/a0
; *************************************************

Race_HandleInputOnFoot:
                movem.l d0-d2/a0,-(sp)
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_258AE).l,a0
                movea.l (a0,d0.w),a0
                clr.w   d3
                move.w  $30(a0),d1
                sub.w   $30(a1),d1
                subi.w  #$20,d1 ; ' '
                move.l  4(a0),d2
                sub.l   4(a1),d2
                addi.l  #$2000,d2
                asr.l   #8,d2
                beq.w   .loc_11182
                tst.w   d1
                beq.w   .loc_1115C
                move.w  #$7D0,d0
                lsr.w   #8,d0
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_1112C
                move.b  (Race_ram_CurrentButtons).l,d3
                andi.w  #$4F,d3
                beq.w   .loc_1112C
                btst    #6,d3
                beq.w   .loc_11124
                move.l  #0,$26(a1)
                move.w  #0,$22(a1)
                bra.w   .loc_111F4
.loc_11124:
                bsr.w   Race_AnotherInputOnFoot
                bra.w   .loc_1119E
.loc_1112C:
                bsr.w   sub_11268
                move.w  d1,8(a1)
                tst.w   d2
                bmi.w   .loc_1114A
                bclr    #3,RaceActor_StateFlags(a1)
                asl.w   #8,d2
                move.w  d2,$12(a1)
                bra.w   .loc_1119E
.loc_1114A:
                bset    #3,RaceActor_StateFlags(a1)
                neg.w   d2
                asl.w   #8,d2
                move.w  d2,$12(a1)
                bra.w   .loc_1119E
.loc_1115C:
                bclr    #3,RaceActor_StateFlags(a1)
                tst.w   d2
                bpl.w   .loc_1116E
                bset    #3,RaceActor_StateFlags(a1)
.loc_1116E:
                move.w  #0,d1
                move.w  d1,8(a1)
                move.w  #$7D0,d2
                move.w  d2,$12(a1)
                bra.w   .loc_1119E
.loc_11182:
                move.w  #$7D0,d2
                lsr.w   #8,d2
                tst.w   d1
                bpl.w   .loc_11190
                neg.w   d2
.loc_11190:
                move.w  d2,8(a1)
                move.w  d2,d1
                move.w  #0,d2
                move.w  d2,$12(a1)
.loc_1119E:
                muls.w  (Race_ram_FrameDelay).l,d1
                move.w  d1,$22(a1)
                add.w   d1,0.w(a1)
                mulu.w  (Race_ram_FrameDelay).l,d2
                move.l  d2,$26(a1)
                move.l  d2,d0
                btst    #3,RaceActor_StateFlags(a1)
                bne.w   .loc_111DC
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_111D4
                bsr.w   Race_UpdateActorX
                bra.w   .loc_111F4
.loc_111D4:
                bsr.w   Race_UpdateActorMovement
                bra.w   .loc_111F4
.loc_111DC:
                move.w  (Race_ram_BestProgress).l,d7
                sub.w   (Race_ram_PlayerProgress).l,d7
                cmp.w   #$40,d7
                bpl.w   .loc_111F4
                bsr.w   Race_UpdateActorFallMovement
.loc_111F4:
                movem.l (sp)+,d0-d2/a0
                rts
; End of function Race_HandleInputOnFoot


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_AnotherInputOnFoot
; On-foot input/AI for the other actor/pad: turn/speed/lean update.
; In:  a1 - actor; Race_ram_CurrentButtons
; Out: actor fields 8/$12/$22/$26/$69
; Clobbers: d0-d4/a0
; *************************************************

Race_AnotherInputOnFoot:
                move.b  (Race_ram_CurrentButtons).l,d3
                move.w  d3,-(sp)
                move.b  d3,d4
                andi.b  #$C,d3
                beq.w   .loc_11214
                move.w  #$80,d1
                bra.w   .loc_11220
.loc_11214:
                move.w  #0,d1
                move.w  #$100,d2
                bra.w   .loc_11234
.loc_11220:
                andi.b  #3,d4
                beq.w   .loc_11230
                move.w  #$100,d2
                bra.w   .loc_11234
.loc_11230:
                move.w  #0,d2
.loc_11234:
                bsr.w   sub_11268
                move.w  (sp)+,d3
                btst    #2,d3
                beq.w   .loc_11244
                neg.w   d1
.loc_11244:
                move.w  d1,8(a1)
                btst    #1,d3
                beq.w   .loc_1125A
                bset    #3,RaceActor_StateFlags(a1)
                bra.w   .loc_11260
.loc_1125A:
                bclr    #3,RaceActor_StateFlags(a1)
.loc_11260:
                asl.w   #8,d2
                move.w  d2,$12(a1)
                rts
; End of function Race_AnotherInputOnFoot


; =============== S U B R O U T I N E =======================================


sub_11268:
                tst.w   d1
                bmi.w   .loc_11298
                tst.w   d2
                bmi.w   .loc_11284
                bsr.w   sub_112C8
                mulu.w  d0,d1
                swap    d1
                mulu.w  d0,d2
                swap    d2
                bra.w   .locret_112C6
.loc_11284:
                neg.w   d2
                bsr.w   sub_112C8
                mulu.w  d0,d1
                swap    d1
                mulu.w  d0,d2
                swap    d2
                neg.w   d2
                bra.w   .locret_112C6
.loc_11298:
                tst.w   d2
                bpl.w   .loc_112B6
                neg.w   d1
                neg.w   d2
                bsr.w   sub_112C8
                mulu.w  d0,d1
                swap    d1
                neg.w   d1
                mulu.w  d0,d2
                swap    d2
                neg.w   d2
                bra.w   .locret_112C6
.loc_112B6:
                neg.w   d1
                bsr.w   sub_112C8
                mulu.w  d0,d1
                swap    d1
                neg.w   d1
                mulu.w  d0,d2
                swap    d2
.locret_112C6:
                rts
; End of function sub_11268


; =============== S U B R O U T I N E =======================================


sub_112C8:
                move.l  a0,-(sp)
                cmp.w   d2,d1
                bne.w   .loc_112DC
                move.w  #$80,d1
                move.w  #$80,d2
                bra.w   .loc_11304


.loc_112DC:
                bmi.w   .loc_112F4
                ext.l   d2
                swap    d2
                divu.w  d1,d2
                lsr.w   #8,d2
                clr.w   d1
                move.b  #$FF,d1
                sub.b   d2,d1
                bra.w   .loc_11304


.loc_112F4:
                ext.l   d1
                swap    d1
                divu.w  d2,d1
                lsr.w   #8,d1
                clr.w   d2
                move.b  #$FF,d2
                sub.b   d1,d2

.loc_11304:
                lea     (unk_7DCA8).l,a0
                asl.w   #1,d1
                move.w  (a0,d1.w),d1
                asl.w   #1,d2
                move.w  (a0,d2.w),d2
                movea.l (sp)+,a0
                rts
; End of function sub_112C8


                dc.b $48 ; H
                dc.b $E7
                dc.b $F0
                dc.b $80
                dc.b $10
                dc.b $29 ; )
                dc.b   0
                dc.b $71 ; q
                dc.b $48 ; H
                dc.b $80
                dc.b $E5
                dc.b $40 ; @
                dc.b $41 ; A
                dc.b $F9
                dc.b   0
                dc.b   2
                dc.b $58 ; X
                dc.b $AE
                dc.b $20
                dc.b $70 ; p
                dc.b   0
                dc.b   0
                dc.b $30 ; 0
                dc.b $28 ; (
                dc.b   0
                dc.b $30 ; 0
                dc.b $90
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b   4
                dc.b $40 ; @
                dc.b   0
                dc.b $20
                dc.b $48 ; H
                dc.b $C0
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $36 ; 6
                dc.b $36 ; 6
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $56 ; V
                dc.b $24 ; $
                dc.b $29 ; )
                dc.b   0
                dc.b   4
                dc.b $94
                dc.b $A8
                dc.b   0
                dc.b   4
                dc.b   6
                dc.b $82
                dc.b   0
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b $44 ; D
                dc.b $82
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $84
                dc.b $C3
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $81
                dc.b $C2
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b   8
                dc.b $C1
                dc.b $F9
                dc.b   0
                dc.b $FF
                dc.b $30 ; 0
                dc.b $4A ; J
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $22 ; "
                dc.b $D1
                dc.b $69 ; i
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $61 ; a
                dc.b   0
                dc.b   0
                dc.b $B4
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $61 ; a
                dc.b   0
                dc.b   5
                dc.b $A4
                dc.b $4C ; L
                dc.b $DF
                dc.b   1
                dc.b  $F
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_113A4:
                move.l  $26(a1),d0
                lsr.l   #8,d0
                move.w  8(a1),d1
                muls.w  d1,d0
                asr.l   #8,d0
                btst    #5,RaceActor_ControlFlags(a1)
                beq.w   .loc_113C0
                bsr.w   Race_UpdateLeanCurve

.loc_113C0:
                move.w  d0,$22(a1)
                add.w   d0,0.w(a1)
                rts
; End of function sub_113A4


; =============== S U B R O U T I N E =======================================


sub_113CA:
                move.l  $26(a1),d0
                lsr.l   #8,d0
                move.l  d0,d1
                muls.w  $42(a1),d0
                asr.l   #8,d0
                move.w  d0,$C(a1)
                btst    #0,RaceActor_ControlFlags(a1)
                beq.w   .loc_113F2
                clr.l   d0
                bclr    #5,RaceActor_ControlFlags(a1)
                bra.w   .loc_1143E


.loc_113F2:
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .loc_11402
                move.w  8(a1),d0
                bra.w   .loc_11406


.loc_11402:
                move.w  d0,8(a1)

.loc_11406:
                add.l   d0,(ram_FF1E5C).l
                sub.l   $36(a1),d0
                exg     d0,d1
                muls.w  d1,d0
                asr.l   #8,d0
                btst    #5,RaceActor_ControlFlags(a1)
                beq.w   .loc_11424
                bsr.w   Race_UpdateLeanCurve

.loc_11424:
                tst.w   d0
                bpl.w   .loc_11438
                neg.w   d0
                mulu.w  #$D000,d0
                swap    d0
                neg.w   d0
                bra.w   .loc_1143E


.loc_11438:
                mulu.w  #$D000,d0
                swap    d0

.loc_1143E:
                move.w  d0,$22(a1)
                add.w   d0,0.w(a1)
                rts
; End of function sub_113CA


; =============== S U B R O U T I N E =======================================


Race_UpdateActorX:
                movem.l d0-d7/a0-a6,-(sp)
                move.w  $30(a1),$1A(a1)
                move.w  $32(a1),$1C(a1)
                move.l  $26(a1),d0
                move.l  4(a1),d4
                move.l  d4,RaceActor_PreviousX(a1)
                add.l   d4,d0
                move.l  d0,4(a1)
                swap    d0
                swap    d4
                move.w  d4,d2
                sub.w   d4,d0
                swap    d4
                neg.w   d4
                lsr.w   #8,d4
                movea.w d4,a6
                move.w  #0,(ram_FF1E92).l
                move.w  #0,d6
                move.w  #0,d7
                lea     (Track_CurveBuffer).l,a4
                move.w  d2,d3
                sub.w   (Race_ram_PlayerProgress).l,d3
                bpl.w   .loc_1149E
                neg.w   d3

.loc_1149E:
                cmp.w   #$40,d3 ; '@'
                bpl.w   .loc_115C0
                cmp.w   (RaceTrack_Data1).l,d2
                bmi.w   .loc_114F8
                move.w  #0,(ram_FF369A).l
                move.w  #$16F,(ram_FF3698).l
                tst.w   (ram_FF1ACC).l
                bne.w   .loc_114F8
                bset    #7,RaceActor_ControlFlags(a1)
                move.l  (Race_ram_ProgressSnapshotB).l,$62(a1)
                move.w  #1,(ram_FF1ACC).l
                move.w  #0,(ram_FF1ACE).l
                move.w  #$12,(ram_FF1AD0).l
                move.w  #0,(ram_FF1AD2).l

.loc_114F8:
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4
                subq.w  #1,d0
                bmi.w   .loc_11552

.loc_11506:
                move.b  (a4)+,d3
                ext.w   d3
                add.w   d3,d6
                move.b  (a4)+,d5
                cmpa.l  #Race_ram_NextSpriteTileArray,a4
                bmi.w   .loc_1151E
                lea     (Track_CurveBuffer).l,a4

.loc_1151E:
                ext.w   d5
                add.w   d5,d7
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_11548
                cmp.w   $2C(a1),d5
                bmi.w   .loc_11548
                movea.w d4,a6
                move.w  d5,$2C(a1)
                move.w  d7,-(sp)
                add.w   $3A(a1),d7
                move.w  d7,(ram_FF1E92).l
                move.w  (sp)+,d7

.loc_11548:
                addi.w  #$100,d4
                addq.w  #1,d2
                dbf     d0,.loc_11506

.loc_11552:
                add.w   d7,$3A(a1)
                move.w  6(a1),d0
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_1156C
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_1156E


.loc_1156C:
                mulu.w  d0,d1

.loc_1156E:
                swap    d1
                add.w   d1,d6
                beq.w   .loc_11578
                nop

.loc_11578:
                sub.w   $38(a1),d6
                beq.w   .loc_11582
                nop

.loc_11582:
                move.w  d1,$38(a1)
                move.l  $26(a1),d1
                lsr.l   #8,d1
                muls.w  d6,d1
                beq.w   .loc_11594
                nop

.loc_11594:
                asr.l   #8,d1
                muls.w  #$300,d1
                asr.l   #8,d1
                beq.w   .loc_115A2
                nop

.loc_115A2:
                add.w   d1,$36(a1)
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_115B8
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_115BA


.loc_115B8:
                mulu.w  d0,d1

.loc_115BA:
                swap    d1
                bsr.w   sub_115C6

.loc_115C0:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function Race_UpdateActorX


; =============== S U B R O U T I N E =======================================


sub_115C6:
                move.w  d1,$3C(a1)
                add.w   $3A(a1),d1
                cmpa.l  #ram_FF2EAA,a1
                bcc.w   .loc_116AA
                move.w  (Race_ram_FrameDelay).l,d4
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_11652
                move.w  #0,$2E(a1)
                tst.w   $12(a1)
                beq.w   .loc_116AA
                tst.w   d1
                bpl.w   .loc_11610
                move.w  #$4000,d0
                add.w   d0,d1
                add.w   d0,$2A(a1)
                move.w  d1,(ram_FF1E92).l
                move.w  d1,$3A(a1)

.loc_11610:
                move.w  (ram_FF1E92).l,d0
                subq.w  #8,d0
                move.w  d0,$2A(a1)
                move.l  $26(a1),d4
                clr.l   d2
                move.w  a6,d2
                asl.l   #8,d2
                sub.l   d2,d4
                bmi.w   .loc_116AA
                move.w  $12(a1),d3
                move.w  $2C(a1),d0
                bpl.w   .loc_11640
                move.w  #0,d0
                bra.w   .loc_11644


.loc_11640:
                mulu.w  d3,d0
                swap    d0

.loc_11644:
                move.w  d0,$2C(a1)
                divu.w  d3,d4
                bne.w   .loc_11652
                move.w  #1,d4

.loc_11652:
                add.w   d4,$2E(a1)
                move.w  $2C(a1),d2
                andi.w  #$1F,d2
                move.w  $2E(a1),d3
                mulu.w  d3,d2
                move.w  d3,d4
                mulu.w  d4,d3
                cmp.l   #$10000,d3
                blt.w   .loc_11676
                move.w  #$FFFF,d3

.loc_11676:
                move.w  (ram_FF1A9E).l,d4
                lsr.w   #1,d4
                mulu.w  d4,d3
                swap    d3
                sub.w   d3,d2
                add.w   $2A(a1),d2
                cmp.w   d2,d1
                bpl.w   .loc_116AA
                move.w  d2,2(a1)
                bset    #0,RaceActor_ControlFlags(a1)
                sub.w   d1,d2
                mulu.w  (ram_FF1AA0).l,d2
                lsr.l   #8,d2
                move.w  d2,$32(a1)
                bra.w   .locret_116E0


.loc_116AA:
                move.w  d1,2(a1)
                move.w  #0,$32(a1)
                btst    #0,RaceActor_ControlFlags(a1)
                beq.w   .loc_116D4
                tst.w   $2C(a1)
                beq.w   .loc_116CE
                bsr.w   Race_ApplyImpactSpeedLoss
                bra.w   .locret_116E0


.loc_116CE:
                bclr    #0,RaceActor_ControlFlags(a1)

.loc_116D4:
                move.w  #0,$2E(a1)
                move.w  #0,$2C(a1)

.locret_116E0:
                rts
; End of function sub_115C6


; =============== S U B R O U T I N E =======================================


Race_UpdateActorMovement:
                movem.l d0-d7/a0-a6,-(sp)
                move.w  $30(a1),$1A(a1)
                move.w  $32(a1),$1C(a1)
                move.l  $26(a1),d0
                move.l  4(a1),d4
                move.l  d4,RaceActor_PreviousX(a1)
                add.l   d4,d0
                move.l  d0,4(a1)
                swap    d0
                swap    d4
                move.w  d4,d2
                sub.w   d4,d0
                swap    d4
                neg.w   d4
                lsr.w   #8,d4
                movea.w d4,a6
                move.w  #0,(ram_FF1E92).l
                move.w  #0,d6
                move.w  #0,d7
                lea     (Track_CurveBuffer).l,a4
                move.w  d2,d3
                sub.w   (Race_ram_PlayerProgress).l,d3
                bpl.w   .loc_11738
                neg.w   d3

.loc_11738:
                cmp.w   #$40,d3 ; '@'
                bpl.w   .loc_11806
                cmp.w   (RaceTrack_Data1).l,d2
                bmi.w   .loc_11762
                btst    #7,RaceActor_ControlFlags(a1)
                bne.w   .loc_11762
                bset    #7,RaceActor_ControlFlags(a1)
                move.l  (Race_ram_ProgressSnapshotB).l,$62(a1)

.loc_11762:
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4

.loc_1176A:
                tst.w   d0
                ble.w   .loc_117C0
                move.b  (a4)+,d3
                ext.w   d3
                add.w   d3,d6
                move.b  (a4)+,d5
                cmpa.l  #Race_ram_NextSpriteTileArray,a4
                bmi.w   .loc_11788
                lea     (Track_CurveBuffer).l,a4

.loc_11788:
                ext.w   d5
                add.w   d5,d7
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_117B6
                cmp.w   $2C(a1),d5
                ble.w   .loc_117B6
                movea.w d4,a6
                move.w  d5,$2C(a1)
                move.w  d7,-(sp)
                add.w   $3A(a1),d7
                move.w  d7,(ram_FF1E92).l
                move.w  (sp)+,d7
                bra.w   *+4


.loc_117B6:
                addi.w  #$100,d4
                subq.w  #1,d0
                addq.w  #1,d2
                bra.s   .loc_1176A


.loc_117C0:
                add.w   d7,$3A(a1)
                move.w  6(a1),d0
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_117DA
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_117DC


.loc_117DA:
                mulu.w  d0,d1

.loc_117DC:
                swap    d1
                add.w   d1,d6
                sub.w   $38(a1),d6
                move.w  d1,$38(a1)
                add.w   d1,$36(a1)
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_117FE
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_11800


.loc_117FE:
                mulu.w  d0,d1

.loc_11800:
                swap    d1
                bsr.w   sub_115C6

.loc_11806:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function Race_UpdateActorMovement


; =============== S U B R O U T I N E =======================================


sub_1180C:
                movem.l d0-d7/a0-a6,-(sp)
                move.l  4(a1),-(sp)
                lea     (unk_258AE).l,a2
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                movea.l (a2,d0.w),a2
                exg     a1,a2
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .loc_118C6
                bsr.w   sub_13BD8
                move.w  $14(a1),d1
                beq.w   .loc_11858
                move.w  (Race_ram_FrameDelay).l,d2
                muls.w  d2,d1
                move.w  $12(a1),d0
                add.w   d1,d0
                move.w  d0,$12(a1)
                bpl.w   .loc_11858
                move.w  #0,$12(a1)

.loc_11858:
                move.w  $12(a1),d0
                beq.w   .loc_1188A
                move.w  (Race_ram_FrameDelay).l,d2
                mulu.w  d2,d0
                move.l  d0,$26(a1)
                move.l  a2,-(sp)
                btst    #3,RaceActor_StateFlags(a1)
                bne.w   .loc_11880
                bsr.w   Race_UpdateActorMovement
                bra.w   .loc_11884


.loc_11880:
                bsr.w   Race_UpdateActorFallMovement

.loc_11884:
                movea.l (sp)+,a2
                bra.w   *+4


.loc_1188A:
                move.w  $36(a1),d1
                move.w  d1,d3
                sub.w   0.w(a1),d1
                bpl.w   .loc_118AE
                cmp.w   #$FD20,d1
                bpl.w   .loc_118C0
                move.w  #$FCE0,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)
                bra.w   .loc_118C0


.loc_118AE:
                cmp.w   #$360,d1
                bmi.w   .loc_118C0
                move.w  #$360,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)

.loc_118C0:
                neg.w   d1
                move.w  d1,$30(a1)

.loc_118C6:
                move.l  (sp)+,d1
                move.l  4(a1),d0
                sub.l   d1,d0
                bpl.w   .loc_118E8
                neg.l   d0
                cmp.l   #$A0000,d0
                bmi.w   .loc_11900
                subi.l  #$A0000,d1
                bra.w   .loc_118F8


.loc_118E8:
                cmp.l   #$A0000,d0
                bmi.w   .loc_11900
                addi.l  #$A0000,d1

.loc_118F8:
                move.l  d1,4(a1)
                move.l  d1,RaceActor_PreviousX(a1)

.loc_11900:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_1180C


; =============== S U B R O U T I N E =======================================


sub_11906:
                movem.l d0/a0-a1,-(sp)
                lea     (unk_258AE).l,a0
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0
                move.w  #$1F,d0
                movem.l a0-a1,-(sp)

.loc_11924:
                move.l  (a1)+,(a0)+
                dbf     d0,.loc_11924
                movem.l (sp)+,a0-a1
                lsr     $2C(a0)
                move.w  #1,(ram_FF176A).l
                movem.l (sp)+,d0/a0-a1
                rts
; End of function sub_11906


; =============== S U B R O U T I N E =======================================


Race_UpdateActorFallMovement:
                movem.l d0-d7/a0-a6,-(sp)
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_1195A
                cmpi.l  #$10000,4(a1)
                blt.w   .loc_11A58

.loc_1195A:
                move.w  $30(a1),$1A(a1)
                move.w  $32(a1),$1C(a1)
                move.l  $26(a1),d4
                move.l  4(a1),d0
                move.l  d0,RaceActor_PreviousX(a1)
                move.l  d0,d1
                sub.l   d4,d0
                move.l  d0,4(a1)
                move.w  d0,d4
                ext.l   d4
                swap    d0
                swap    d1
                move.w  d1,d2
                sub.w   d0,d1
                move.w  d1,d0
                lsr.w   #8,d4
                movea.w d4,a6
                move.w  #0,(ram_FF1E92).l
                move.w  #0,d6
                move.w  #0,d7
                lea     (Track_CurveBuffer).l,a4
                move.w  d2,d3
                sub.w   (Race_ram_PlayerProgress).l,d3
                bpl.w   .loc_119B0
                neg.w   d3

.loc_119B0:
                cmp.w   #$40,d3 ; '@'
                bpl.w   .loc_11A58
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4

.loc_119C0:
                cmp.w   (RaceTrack_Data1).l,d2
                bmi.w   .loc_119D4
                ext.l   d2
                divu.w  (RaceTrack_Data1).l,d2
                swap    d2

.loc_119D4:
                tst.w   d0
                ble.w   .loc_11A0E
                move.b  (a4),d3
                ext.w   d3
                add.w   d3,d6
                move.b  1(a4),d5
                subq.w  #2,a4
                cmpa.l  #Track_CurveBuffer,a4
                bpl.w   .loc_119F6
                movea.l #ram_FFDD56,a4

.loc_119F6:
                ext.w   d5
                add.w   d5,d7
                addi.w  #$100,d4
                subq.w  #1,d0
                subq.w  #1,d2
                bpl.w   .loc_11A0C
                move.w  (RaceTrack_Data1).l,d2

.loc_11A0C:
                bra.s   .loc_119C0


.loc_11A0E:
                move.w  d1,$E(a1)
                move.w  d2,$10(a1)
                sub.w   d6,$36(a1)
                sub.w   d7,$3A(a1)
                move.w  6(a1),d0
                move.b  (a4),d1
                ext.w   d1
                bpl.w   .loc_11A34
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_11A36


.loc_11A34:
                mulu.w  d0,d1

.loc_11A36:
                swap    d1
                move.w  d1,$38(a1)
                move.b  1(a4),d1
                ext.w   d1
                bpl.w   .loc_11A50
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_11A52


.loc_11A50:
                mulu.w  d0,d1

.loc_11A52:
                swap    d1
                bsr.w   sub_115C6

.loc_11A58:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function Race_UpdateActorFallMovement


                dc.b $48 ; H
                dc.b $E7
                dc.b $FF
                dc.b $FE
                dc.b $33 ; 3
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b   0
                dc.b $1A
                dc.b $33 ; 3
                dc.b $69 ; i
                dc.b   0
                dc.b $32 ; 2
                dc.b   0
                dc.b $1C
                dc.b $28 ; (
                dc.b $29 ; )
                dc.b   0
                dc.b $26 ; &
                dc.b $20
                dc.b $29 ; )
                dc.b   0
                dc.b   4
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b $1E
                dc.b $22 ; "
                dc.b   0
                dc.b $90
                dc.b $84
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b   4
                dc.b $38 ; 8
                dc.b   0
                dc.b $48 ; H
                dc.b $C4
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $48 ; H
                dc.b $41 ; A
                dc.b $34 ; 4
                dc.b   1
                dc.b $92
                dc.b $40 ; @
                dc.b $30 ; 0
                dc.b   1
                dc.b $E0
                dc.b $4C ; L
                dc.b $3C ; <
                dc.b $44 ; D
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $92
                dc.b $3C ; <
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $3E ; >
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $49 ; I
                dc.b $F9
                dc.b   0
                dc.b $FF
                dc.b $DC
                dc.b $58 ; X
                dc.b $36 ; 6
                dc.b   2
                dc.b $96
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $68 ; h
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $43 ; C
                dc.b $B6
                dc.b $7C ; |
                dc.b   0
                dc.b $40 ; @
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b $B6
                dc.b   2
                dc.b $42 ; B
                dc.b   0
                dc.b $FF
                dc.b $E3
                dc.b $42 ; B
                dc.b $D8
                dc.b $C2
                dc.b $B4
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $4C ; L
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $48 ; H
                dc.b $C2
                dc.b $84
                dc.b $F9
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $4C ; L
                dc.b $48 ; H
                dc.b $42 ; B
                dc.b $4A ; J
                dc.b $40 ; @
                dc.b $6F ; o
                dc.b   0
                dc.b   0
                dc.b $36 ; 6
                dc.b $16
                dc.b $14
                dc.b $48 ; H
                dc.b $83
                dc.b $DC
                dc.b $43 ; C
                dc.b $1A
                dc.b $2C ; ,
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $4C ; L
                dc.b $B9
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $DC
                dc.b $58 ; X
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $28 ; (
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b $DD
                dc.b $56 ; V
                dc.b $48 ; H
                dc.b $85
                dc.b $DE
                dc.b $45 ; E
                dc.b   6
                dc.b $44 ; D
                dc.b   1
                dc.b   0
                dc.b $53 ; S
                dc.b $40 ; @
                dc.b $53 ; S
                dc.b $42 ; B
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $34 ; 4
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $4C ; L
                dc.b $60 ; `
                dc.b $B2
                dc.b $33 ; 3
                dc.b $41 ; A
                dc.b   0
                dc.b  $E
                dc.b $33 ; 3
                dc.b $42 ; B
                dc.b   0
                dc.b $10
                dc.b $9D
                dc.b $69 ; i
                dc.b   0
                dc.b $36 ; 6
                dc.b $9F
                dc.b $69 ; i
                dc.b   0
                dc.b $3A ; :
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b   6
                dc.b $12
                dc.b $14
                dc.b $48 ; H
                dc.b $81
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $44 ; D
                dc.b $41 ; A
                dc.b $C2
                dc.b $C0
                dc.b $44 ; D
                dc.b $81
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $C2
                dc.b $C0
                dc.b $48 ; H
                dc.b $41 ; A
                dc.b $33 ; 3
                dc.b $41 ; A
                dc.b   0
                dc.b $38 ; 8
                dc.b $12
                dc.b $2C ; ,
                dc.b   0
                dc.b   1
                dc.b $48 ; H
                dc.b $81
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $44 ; D
                dc.b $41 ; A
                dc.b $C2
                dc.b $C0
                dc.b $44 ; D
                dc.b $81
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $C2
                dc.b $C0
                dc.b $48 ; H
                dc.b $41 ; A
                dc.b $33 ; 3
                dc.b $41 ; A
                dc.b   0
                dc.b $3C ; <
                dc.b $D2
                dc.b $69 ; i
                dc.b   0
                dc.b $3A ; :
                dc.b $33 ; 3
                dc.b $41 ; A
                dc.b   0
                dc.b   2
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $68 ; h
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $32 ; 2
                dc.b $4C ; L
                dc.b $DF
                dc.b $7F ; 
                dc.b $FF
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


Race_ApplyCrashImpact:
                move.w  4(a1),d0
                lea     (Track_CurveBuffer).l,a4
                andi.w  #$FF,d0
                asl.w   #1,d0
                adda.w  d0,a4
                move.b  1(a4),d0
                btst    #0,RaceActor_ControlFlags(a1)
                beq.w   .loc_11BA8
                cmpi.w  #$2D,$2E(a1) ; '-'
                bmi.w   .loc_11BAE
                move.b  #$64,d0 ; 'd'

.loc_11BA8:
                ext.w   d0
                move.w  d0,$A(a1)

.loc_11BAE:
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .locret_11C42
                tst.b   RaceActor_AnimState(a1)
                bpl.w   .locret_11C42
                move.w  $C(a1),d0
                move.w  d0,8(a1)
                move.w  RaceActor_LeanCurve(a1),d2
                move.w  $34(a1),d3
                move.w  d0,d1
                bpl.w   .loc_11BDC
                neg.w   d1
                neg.w   d2
                neg.w   d3

.loc_11BDC:
                cmp.w   #3,d3
                bmi.w   .locret_11C42
                add.w   d1,d2
                cmp.w   (ram_FFD33E).l,d2
                bmi.w   .locret_11C42
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .locret_11C42
                move.b  #0,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                bset    #4,RaceActor_ControlFlags(a1)
                tst.w   d0
                bpl.w   .loc_11C20
                jsr     (sub_15538).l
                bsr.w   sub_11906
                bra.w   .loc_11C2A


.loc_11C20:
                jsr     (sub_15538).l
                bsr.w   sub_11906

.loc_11C2A:
                bclr    #7,RaceActor_WeaponAnimFlags(a1)
                move.w  $12(a1),d0
                jsr     (Race_ScaleImpactDamage).l
                lsr.w   #2,d0
                add.w   d0,(Race_ram_BikeDamage).l

.locret_11C42:
                rts
; End of function Race_ApplyCrashImpact


; =============== S U B R O U T I N E =======================================


sub_11C44:
                tst.w   (ram_FF1B18).l
                beq.w   .loc_11C6A
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,(ram_FF1B18).l
                bgt.w   .locret_11CC6
                move.w  #1,(Race_ram_GameEnded).l
                bra.w   .locret_11CC6


.loc_11C6A:
                lea     (ram_FF1A08).l,a0

.loc_11C70:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .locret_11CC6
                cmpa.l  #ram_FF1F2A,a2
                bne.s   .loc_11C70
                lea     (RacePlayerA).l,a1
                move.l  4(a2),d0
                move.l  4(a1),d1
                sub.l   d1,d0
                bpl.w   .loc_11CA2
                neg.l   d0
                cmp.l   ($4000).w,d0 ; WOW
                bpl.w   .locret_11CC6

.loc_11CA2:
                cmp.l   #$60000,d0
                bpl.w   .locret_11CC6
                tst.w   $12(a1)
                bne.w   .locret_11CC6
                move.w  #$12C,(ram_FF1B18).l
                move.w  (Race_ram_LevelIndex).l,(Race_CopIndex).l

.locret_11CC6:
                rts
; End of function sub_11C44


; =============== S U B R O U T I N E =======================================


sub_11CC8:
                move.w  #0,(ram_FF176A).l
                move.l  #$6000,(ram_FF3038).l
                move.w  #$10,(ram_FF303C).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (ram_FF1A08).l,a0
                movea.l (a0)+,a1
                move.w  #0,RaceActor_AttackReach(a1)
                move.w  8(a1),d1
                move.w  $C(a1),d2
                move.w  #0,d3
                bsr.w   Race_GetActorCollisionExtent
                move.w  d0,$4C(a1)
                move.w  #1,d3
                bsr.w   Race_GetActorCollisionExtent
                move.w  d0,$4E(a1)
                bclr    #4,RaceActor_ControlFlags(a1)
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .loc_11D3C
                cmpi.b  #4,RaceActor_AnimState(a1)
                bpl.w   .loc_11D3C
                move.w  #1,(ram_FF1768).l
                bra.w   .loc_11D44


.loc_11D3C:
                move.w  #0,(ram_FF1768).l

.loc_11D44:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_11E8C
                btst    #6,RaceActor_ControlFlags(a2)
                beq.s   .loc_11D44
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .loc_11D92
                cmpa.l  #ram_FF1F2A,a2
                beq.s   .loc_11D44
                tst.b   RaceActor_AnimState(a2)
                bmi.s   .loc_11D44
                move.b  $71(a2),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_258AE).l,a3
                movea.l (a3,d0.w),a2
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                beq.s   .loc_11D44

.loc_11D92:
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_11DFE
                tst.w   (ram_FF1768).l
                bne.w   .loc_11DB0
                cmpa.l  #RacePlayerB,a2
                bcs.w   .loc_11DC2

.loc_11DB0:
                cmpi.b  #1,RaceActor_AnimState(a2)
                bcs.w   .loc_1202E
                bsr.w   sub_1438E
                bra.w   .loc_1202E


.loc_11DC2:
                move.b  RaceActor_AnimState(a2),d0
                bmi.w   .loc_11DFE
                cmp.b   #1,d0
                bcs.w   .loc_1202E
                bsr.w   sub_1438E
                move.b  #1,RaceActor_AnimState(a2)
                move.b  #0,RaceActor_AnimFrame(a2)
                move.b  #$FF,RaceActor_AnimTimer(a2)
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_1202E
                move.b  #$D,(ram_FF1AD6).l
                bra.w   .loc_1202E


.loc_11DFE:
                bsr.w   Race_UpdateActorPairImpact
                tst.b   (ram_FF1AD6).l
                bne.w   .loc_11E14
                move.b  #9,(ram_FF1AD6).l

.loc_11E14:
                move.w  $C(a1),d0
                muls.w  #$40,d0
                move.w  d0,(RaceBike_ram_CurrentSteering).l
                move.w  d0,$42(a1)
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_11E6A
                tst.w   (ram_FF1768).l
                bne.w   .loc_11E4A
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .loc_1202E
                bsr.w   sub_11906
                bra.w   .loc_1202E


.loc_11E4A:
                cmpi.b  #3,RaceActor_AnimState(a1)
                bmi.w   .loc_11E5A
                move.w  #0,$12(a1)

.loc_11E5A:
                move.b  #0,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                bra.w   .loc_1202E


.loc_11E6A:
                tst.w   (Race_CopIndex).l
                bne.w   .loc_11E88
                move.b  #$FF,RaceActor_AnimState(a2)
                tst.w   (ram_FF1768).l
                bne.w   .loc_11E88
                bsr.w   sub_11906

.loc_11E88:
                bra.w   .loc_1202E


.loc_11E8C:
                lea     (Race_StaticActorList).l,a0
                move.l  #$6000,(ram_FF3038).l
                move.w  #$37,(ram_FF303C).l ; '7'
                move.w  #$40,(ram_FF303E).l ; '@'

.loc_11EAC:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_11EF4
                cmpi.w  #$FFFF,$56(a2)
                bne.s   .loc_11EAC
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                beq.s   .loc_11EAC
                bsr.w   Race_ApplyCollisionImpact
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_11EF4
                move.w  $C(a1),(RaceBike_ram_CurrentSteering).l
                tst.w   (ram_FF1768).l
                bne.w   .loc_1202E
                bsr.w   sub_11906
                bra.w   .loc_1202E


.loc_11EF4:
                move.w  #$60,(ram_FF303C).l ; '`'
                move.l  #$3700,(ram_FF3038).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (ram_FF2FAA).l,a2
                btst    #6,RaceActor_ControlFlags(a2)
                beq.w   .loc_11F58
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_11F58
                bsr.w   Race_ApplyCollisionImpact
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_1202E
                move.w  $C(a1),(RaceBike_ram_CurrentSteering).l
                tst.w   (ram_FF1768).l
                bne.w   .loc_1202E
                bsr.w   sub_11906
                bra.w   .loc_1202E

                dc.b $60
                dc.b   0
                dc.b   0
                dc.b $D8


.loc_11F58:
                bsr.w   sub_12070
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .loc_1202E
                move.l  #$6000,(ram_FF3038).l
                move.w  #$10,(ram_FF303C).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (Road_ObjectArray).l,a0
                move.w  (ram_FF1B48).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                move.l  RaceActor_PreviousX(a1),d0
                sub.l   (Race_ram_PlayerProgress).l,d0
                lsr.l   #8,d0
                move.l  4(a1),d1
                addi.l  #$6000,d1
                sub.l   (Race_ram_PlayerProgress).l,d1
                lsr.l   #8,d1
                move.w  (ram_FF1B4A).l,d7
                subq.w  #1,d7

.loc_11FB8:
                cmpi.w  #$FFFF,(a0)
                beq.w   .loc_1202E
                move.w  d7,-(sp)
                bsr.w   sub_12414
                adda.l  #$14,a0
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .loc_11FE0
                move.w  (sp)+,d7
                dbf     d7,.loc_11FB8
                bra.w   .loc_1202E


.loc_11FE0:
                move.w  (sp)+,d7
                suba.l  #$14,a0
                move.w  (ram_FF1B0E).l,d0
                cmp.w   #$1BB,d0
                bmi.w   .loc_12010
                cmp.w   #$219,d0
                bmi.w   .loc_12006
                subi.w  #$2F,d0 ; '/'
                bra.w   .loc_12010


.loc_12006:
                subi.w  #$1BB,d0
                lsr.w   #1,d0
                addi.w  #$1BB,d0

.loc_12010:
                subi.w  #$186,d0
                lea     (unk_147FC).l,a4
                move.b  (a4,d0.w),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_14744).l,a4
                movea.l (a4,d0.w),a4
                jsr     (a4)

.loc_1202E:
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .loc_12068
                bset    #4,RaceActor_ControlFlags(a1)
                tst.w   (ram_FF176A).l
                bne.w   .locret_12066
                move.w  #1,(ram_FF176A).l
                move.w  #1,(ram_FF1768).l
                lea     (RacePlayerB).l,a1
                bclr    #4,RaceActor_ControlFlags(a1)
                bra.w   .loc_11E8C


.locret_12066:
                rts


.loc_12068:
                bclr    #4,RaceActor_ControlFlags(a1)
                rts
; End of function sub_11CC8


; =============== S U B R O U T I N E =======================================


sub_12070:
                movem.l d0-d7/a0-a7,-(sp)
                movea.l (Race_ram_TrackObjectWritePtr).l,a0
                suba.w  #$14,a0
                movea.l (Race_ram_TrackObjectRecordCursor).l,a2
                move.l  4(a1),d0
                addi.l  #$6000,d0
                move.l  RaceActor_PreviousX(a1),d1
                addi.l  #$6000,d1
                lea     (Road_ShapeTable).l,a6
                lea     (Race_TrackObjectTypeTable).l,a5

.loc_120A4:
                adda.w  #$14,a0
                move.l  (a2)+,d2
                cmp.l   #$FFFFFFFF,d2
                beq.w   .loc_12162
                move.w  d2,d3
                clr.w   d2
                cmp.l   d2,d0
                bpl.w   .loc_120C8
                cmp.l   d2,d1
                bpl.w   .loc_120CE
                bra.w   .loc_12162


.loc_120C8:
                cmp.l   d2,d1
                bpl.w   .loc_12162

.loc_120CE:
                move.w  d3,d2
                andi.w  #$F,d2
                asl.w   #5,d2
                subi.w  #$100,d2
                lsr.w   #8,d3
                move.w  d3,d4
                ext.w   d4
                asl.w   #3,d4
                addi.w  #$173,d3
                asl.w   #2,d3
                movea.l (a6,d3.w),a4
                clr.w   d3
                move.b  (a4),d3
                clr.w   d5
                move.b  1(a4),d5
                move.w  2(a5,d4.w),d7
                addi.w  #$80,d7
                mulu.w  d7,d3
                lsr.l   #8,d3
                lsr.w   #1,d3
                move.w  d3,(ram_FF1B10).l
                mulu.w  d7,d5
                lsr.l   #8,d5
                move.w  d5,(ram_FF1B12).l
                cmp.w   $1A(a1),d2
                bpl.w   .loc_12134
                add.w   d3,d2
                move.w  d2,(ram_FF1B14).l
                add.w   $4C(a1),d2
                cmp.w   $30(a1),d2
                bmi.w   .loc_120A4
                bra.w   .loc_12148


.loc_12134:
                sub.w   d3,d2
                move.w  d2,(ram_FF1B14).l
                sub.w   $4E(a1),d2
                cmp.w   $30(a1),d2
                bpl.w   .loc_120A4

.loc_12148:
                cmp.w   $32(a1),d5
                bmi.w   .loc_120A4
                move.w  4(a5,d4.w),d4
                asl.w   #2,d4
                lea     (unk_14744).l,a4
                movea.l (a4,d4.w),a4
                jsr     (a4)

.loc_12162:
                movem.l (sp)+,d0-d7/a0-a7
                rts
; End of function sub_12070


                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $40 ; @
                dc.b $EE
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E

; =============== S U B R O U T I N E =======================================


sub_1218C:
                lea     (Race_ram_ActiveActorList).l,a0

.loc_12192:
                movea.l (a0)+,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_123A6
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_121B4
                tst.b   RaceActor_AnimState(a1)
                bmi.s   .loc_12192
                bclr    #4,RaceActor_ControlFlags(a1)

.loc_121B4:
                btst    #6,RaceActor_ControlFlags(a1)
                beq.s   .loc_12192
                move.w  #0,(ram_FF1768).l
                move.l  a0,-(sp)
                tst.b   (RacePlayerA + RaceActor_AnimState).l
                bmi.w   .loc_121DA
                movea.l #RacePlayerB,a2
                bra.w   .loc_121E6


.loc_121DA:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_12288

.loc_121E6:
                btst    #6,RaceActor_ControlFlags(a2)
                beq.s   .loc_121DA
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .loc_121FE
                move.w  #1,(ram_FF1768).l

.loc_121FE:
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .loc_12234
                tst.b   RaceActor_AnimState(a2)
                bmi.s   .loc_121DA
                lea     (unk_258AE).l,a3
                cmpa.l  a3,a2
                beq.s   .loc_121DA
                move.b  $71(a2),d0
                ext.w   d0
                asl.w   #2,d0
                movea.l (a3,d0.w),a2
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                beq.s   .loc_121DA

.loc_12234:
                tst.w   (ram_FF1768).l
                beq.w   .loc_1224E
                move.w  $12(a2),d0
                add.w   $12(a1),d0
                cmp.w   #$FA0,d0
                ble.w   .loc_1226A

.loc_1224E:
                cmpi.w  #$7D0,$12(a2)
                bgt.w   .loc_12272
                cmpa.l  #RacePlayerB,a2
                bcc.w   .loc_1226A
                tst.b   RaceActor_AnimState(a2)
                bmi.w   .loc_12272

.loc_1226A:
                bsr.w   sub_1438E
                bra.w   .loc_12388


.loc_12272:
                bsr.w   Race_UpdateActorPairImpact
                tst.w   (ram_FF1768).l
                bne.w   .loc_12284
                bsr.w   sub_11906

.loc_12284:
                bra.w   .loc_12388


.loc_12288:
                move.w  #$60,(ram_FF303C).l ; '`'
                move.l  #$3700,(ram_FF3038).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (ram_FF2FAA).l,a2
                btst    #6,RaceActor_ControlFlags(a2)
                beq.w   .loc_122FA
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_122FA
                move.w  4(a2),d0
                sub.w   (Race_ram_PlayerProgress).l,d0
                cmp.w   #$10,d0
                bmi.w   .loc_122DC
                bclr    #4,RaceActor_ControlFlags(a1)
                bra.w   .loc_12388


.loc_122DC:
                bsr.w   Race_ApplyCollisionImpact
                move.b  #0,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                tst.w   (ram_FF1768).l
                bne.w   .loc_122FA
                bsr.w   sub_11906

.loc_122FA:
                lea     (Race_StaticActorList).l,a0
                move.l  #$6000,(ram_FF3038).l
                move.w  #$37,(ram_FF303C).l ; '7'
                move.w  #$40,(ram_FF303E).l ; '@'

.loc_1231A:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_12384
                cmpi.w  #$FFFF,$56(a2)
                bne.s   .loc_1231A
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                beq.s   .loc_1231A
                move.w  4(a2),d0
                sub.w   (Race_ram_PlayerProgress).l,d0
                cmp.w   #$10,d0
                bmi.w   .loc_12356
                bclr    #4,RaceActor_ControlFlags(a1)
                bra.w   .loc_12388


.loc_12356:
                bsr.w   Race_ApplyCollisionImpact
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_12384
                move.w  #0,$54(a1)
                move.b  #0,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                tst.w   (ram_FF1768).l
                bne.w   .loc_12388
                bsr.w   sub_11906

.loc_12384:
                bsr.w   sub_12070

.loc_12388:
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .loc_123A0
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .loc_123A0
                bset    #4,RaceActor_ControlFlags(a1)

.loc_123A0:
                movea.l (sp)+,a0
                bra.w   .loc_12192


.locret_123A6:
                rts
; End of function sub_1218C


; =============== S U B R O U T I N E =======================================


sub_123A8:
                lea     (ram_FF2EAA).l,a1
                lea     (ram_FF2F2A).l,a2
                btst    #6,RaceActor_ControlFlags(a1)
                beq.w   .locret_12412
                btst    #6,RaceActor_ControlFlags(a2)
                beq.w   .locret_12412
                move.l  #$6000,(ram_FF3038).l
                move.w  #$37,(ram_FF303C).l ; '7'
                move.w  #$40,(ram_FF303E).l ; '@'
                bsr.w   Race_UpdateActorPairCollision
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .locret_12412
                move.l  4(a1),d0
                move.l  #$C014,d1
                btst    #0,RaceActor_StateFlags(a1)
                beq.w   .loc_12406
                neg.l   d1

.loc_12406:
                add.l   d1,d0
                move.l  d0,4(a2)
                move.w  $12(a1),$12(a2)

.locret_12412:
                rts
; End of function sub_123A8


; =============== S U B R O U T I N E =======================================


sub_12414:
                cmp.w   $E(a0),d1
                bcs.w   .loc_124DA
                cmp.w   $E(a0),d0
                bcs.w   .loc_12428
                bra.w   .loc_124DA


.loc_12428:
                move.w  $10(a0),d2
                andi.w  #$F,d2
                asl.w   #6,d2
                btst    #$E,$A(a0)
                beq.w   .loc_1243E
                neg.w   d2

.loc_1243E:
                lea     (Road_ShapeTable).l,a2
                move.w  8(a0),d0
                move.w  d0,(ram_FF1B0E).l
                asl.w   #2,d0
                movea.l (a2,d0.w),a2
                clr.w   d5
                move.b  1(a2),d5
                move.w  d5,(ram_FF1B12).l
                move.b  (a2),d0
                andi.w  #$FF,d0
                lsr.w   #1,d0
                clr.l   d7
                move.w  4(a0),d7
                addi.l  #$2000,d7
                cmp.l   #$4000,d7
                bmi.w   .loc_12484
                mulu.w  d7,d0
                asl.l   #2,d0
                swap    d0

.loc_12484:
                move.w  d0,(ram_FF1B10).l
                move.w  $30(a1),d3
                move.w  $1A(a1),d4
                cmp.w   d4,d2
                bpl.w   .loc_124AE
                add.w   d0,d2
                sub.w   $4C(a1),d3
                bset    #1,RaceActor_StateFlags(a1)
                cmp.w   d3,d2
                bpl.w   .loc_124C4
                bra.w   .loc_124DA


.loc_124AE:
                sub.w   d0,d2
                add.w   $4E(a1),d3
                bclr    #1,RaceActor_StateFlags(a1)
                cmp.w   d3,d2
                bmi.w   .loc_124C4
                bra.w   .loc_124DA


.loc_124C4:
                cmp.w   $32(a1),d5
                bmi.w   .loc_124DA
                move.w  d2,(ram_FF1B14).l
                bset    #4,RaceActor_ControlFlags(a1)
                rts


.loc_124DA:
                bclr    #4,RaceActor_ControlFlags(a1)
                rts
; End of function sub_12414


; =============== S U B R O U T I N E =======================================


Race_UpdateActorPairCollision:
                move.w  #0,(ram_FF1766).l
                move.w  #0,(ram_FF1B16).l
                move.l  RaceActor_PreviousX(a1),d0
                cmp.l   RaceActor_PreviousX(a2),d0
                bcs.w   .loc_1251A
                bset    #0,RaceActor_StateFlags(a1)
                move.l  4(a1),d0
                sub.l   (ram_FF3038).l,d0
                cmp.l   4(a2),d0
                bcs.w   .loc_12536
                bra.w   .loc_1280A


.loc_1251A:
                bclr    #0,RaceActor_StateFlags(a1)
                move.l  4(a1),d0
                addi.l  #$6000,d0
                cmp.l   4(a2),d0
                bcc.w   .loc_12536
                bra.w   .loc_1280A


.loc_12536:
                move.w  $1A(a1),d0
                cmp.w   $1A(a2),d0
                bmi.w   .loc_12698
                bset    #1,RaceActor_StateFlags(a1)
                move.w  8(a1),d1
                move.w  $C(a1),d2
                move.w  #0,d3
                move.b  $71(a1),d4
                move.w  #0,RaceActor_AttackReach(a1)
                bsr.w   Race_GetCollisionExtent
                move.w  d0,RaceActor_CollisionExtent(a1)
                move.w  d0,$4C(a1)
                cmpa.l  #RacePlayerB,a2
                bcc.w   .loc_125B0
                btst    #4,RaceActor_StateFlags(a1)
                beq.w   .loc_125B0
                cmpi.b  #1,RaceActor_AttackPhase(a1)
                bne.w   .loc_125B0
                btst    #5,RaceActor_StateFlags(a1)
                beq.w   .loc_125B0
                btst    #6,RaceActor_StateFlags(a1)
                bne.w   .loc_125A8
                bsr.w   Race_GetAttackerReach
                move.w  d0,RaceActor_AttackReach(a1)
                bra.w   .loc_125B0


.loc_125A8:
                bsr.w   Race_GetDefenderReach
                move.w  d0,RaceActor_AttackReach(a1)

.loc_125B0:
                move.w  8(a2),d1
                move.w  $C(a2),d2
                move.w  #1,d3
                move.b  $71(a2),d4
                move.w  #0,RaceActor_AttackReach(a2)
                bsr.w   Race_GetCollisionExtent
                move.w  d0,RaceActor_CollisionExtent(a2)
                move.w  d0,$4E(a2)
                btst    #4,RaceActor_StateFlags(a2)
                beq.w   .loc_1260E
                cmpi.b  #1,RaceActor_AttackPhase(a2)
                bne.w   .loc_1260E
                btst    #5,RaceActor_StateFlags(a2)
                bne.w   .loc_1260E
                btst    #6,RaceActor_StateFlags(a2)
                bne.w   .loc_12606
                bsr.w   Race_GetAttackerReach
                move.w  d0,RaceActor_AttackReach(a2)
                bra.w   .loc_1260E


.loc_12606:
                bsr.w   Race_GetDefenderReach
                move.w  d0,RaceActor_AttackReach(a2)

.loc_1260E:
                move.w  $30(a1),d0
                sub.w   RaceActor_CollisionExtent(a1),d0
                sub.w   RaceActor_CollisionExtent(a2),d0
                sub.w   $30(a2),d0
                move.w  d0,d1
                sub.w   RaceActor_AttackReach(a1),d0
                bmi.w   .loc_1263A
                move.w  #0,d0
                move.w  d0,RaceActor_AttackOverlap(a1)
                bclr    #7,RaceActor_StateFlags(a1)
                bra.w   .loc_12654


.loc_1263A:
                move.w  #1,(ram_FF1B16).l
                move.w  d0,RaceActor_AttackOverlap(a1)
                tst.w   RaceActor_AttackReach(a1)
                beq.w   .loc_12654
                bset    #7,RaceActor_StateFlags(a1)

.loc_12654:
                sub.w   RaceActor_AttackReach(a2),d1
                bmi.w   .loc_1266E
                move.w  #0,d1
                move.w  d1,RaceActor_AttackOverlap(a2)
                bclr    #7,RaceActor_StateFlags(a2)
                bra.w   .loc_1268A


.loc_1266E:
                move.w  #1,(ram_FF1B16).l
                neg.w   d1
                move.w  d1,RaceActor_AttackOverlap(a2)
                tst.w   RaceActor_AttackReach(a2)
                beq.w   .loc_1268A
                bset    #7,RaceActor_StateFlags(a2)

.loc_1268A:
                tst.w   (ram_FF1B16).l
                beq.w   .loc_1280A
                bra.w   .loc_127EA


.loc_12698:
                bclr    #1,RaceActor_StateFlags(a1)
                move.w  8(a1),d1
                move.w  $C(a1),d2
                move.w  #1,d3
                move.b  $71(a1),d4
                move.w  #0,RaceActor_AttackReach(a1)
                bsr.w   Race_GetCollisionExtent
                move.w  d0,RaceActor_CollisionExtent(a1)
                move.w  d0,$4E(a1)
                cmpa.l  #RacePlayerB,a2
                bcc.w   .loc_12706
                btst    #4,RaceActor_StateFlags(a1)
                beq.w   .loc_12706
                cmpi.b  #1,RaceActor_AttackPhase(a1)
                bne.w   .loc_12706
                btst    #5,RaceActor_StateFlags(a1)
                bne.w   .loc_12706
                btst    #6,RaceActor_StateFlags(a1)
                bne.w   .loc_126FE
                bsr.w   Race_GetAttackerReach
                move.w  d0,RaceActor_AttackReach(a1)
                bra.w   .loc_12706


.loc_126FE:
                bsr.w   Race_GetDefenderReach
                move.w  d0,RaceActor_AttackReach(a1)

.loc_12706:
                move.w  8(a2),d1
                move.w  $C(a2),d2
                move.w  #0,d3
                move.b  $71(a2),d4
                move.w  #0,RaceActor_AttackReach(a2)
                bsr.w   Race_GetCollisionExtent
                move.w  d0,RaceActor_CollisionExtent(a2)
                move.w  d0,$4C(a2)
                btst    #4,RaceActor_StateFlags(a2)
                beq.w   .loc_12764
                cmpi.b  #1,RaceActor_AttackPhase(a2)
                bne.w   .loc_12764
                btst    #5,RaceActor_StateFlags(a2)
                beq.w   .loc_12764
                btst    #6,RaceActor_StateFlags(a2)
                bne.w   .loc_1275C
                bsr.w   Race_GetAttackerReach
                move.w  d0,RaceActor_AttackReach(a2)
                bra.w   .loc_12764


.loc_1275C:
                bsr.w   Race_GetDefenderReach
                move.w  d0,RaceActor_AttackReach(a2)

.loc_12764:
                move.w  $30(a1),d0
                add.w   RaceActor_CollisionExtent(a1),d0
                add.w   RaceActor_CollisionExtent(a2),d0
                sub.w   $30(a2),d0
                move.w  d0,d1
                add.w   RaceActor_AttackReach(a1),d0
                bpl.w   .loc_12790
                move.w  #0,d0
                move.w  d0,RaceActor_AttackOverlap(a1)
                bclr    #7,RaceActor_StateFlags(a1)
                bra.w   .loc_127AA


.loc_12790:
                move.w  #1,(ram_FF1B16).l
                move.w  d0,RaceActor_AttackOverlap(a1)
                tst.w   RaceActor_AttackReach(a1)
                beq.w   .loc_127AA
                bset    #7,RaceActor_StateFlags(a1)

.loc_127AA:
                add.w   RaceActor_AttackReach(a2),d1
                bpl.w   .loc_127C4
                move.w  #0,d1
                move.w  d1,RaceActor_AttackOverlap(a2)
                bclr    #7,RaceActor_StateFlags(a2)
                bra.w   .loc_127E0


.loc_127C4:
                move.w  #1,(ram_FF1B16).l
                neg.w   d1
                move.w  d1,RaceActor_AttackOverlap(a2)
                tst.w   RaceActor_AttackReach(a2)
                beq.w   .loc_127E0
                bset    #7,RaceActor_StateFlags(a2)

.loc_127E0:
                tst.w   (ram_FF1B16).l
                beq.w   .loc_1280A

.loc_127EA:
                move.w  $32(a1),d0
                sub.w   (ram_FF303E).l,d0
                sub.w   $32(a2),d0
                bpl.w   .loc_1280A
                bset    #4,RaceActor_ControlFlags(a1)
                bset    #4,RaceActor_ControlFlags(a2)
                rts


.loc_1280A:
                bclr    #4,RaceActor_ControlFlags(a1)
                bclr    #7,RaceActor_StateFlags(a1)
                bclr    #7,RaceActor_StateFlags(a2)
                rts
; End of function Race_UpdateActorPairCollision


; =============== S U B R O U T I N E =======================================


Race_ClearActorOnFootFlags:
                lea     (Race_ram_ActiveActorList).l,a0

.loc_12824:
                movea.l (a0)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .loc_1283E
                cmpi.b  #$FF,RaceActor_AnimState(a1)
                bne.s   .loc_12824
                bclr    #4,RaceActor_ControlFlags(a1)
                bra.s   .loc_12824


.loc_1283E:
                lea     (Race_StaticActorList).l,a0

.loc_12844:
                movea.l (a0)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .loc_1285E
                cmpi.b  #$FF,RaceActor_AnimState(a1)
                bne.s   .loc_12844
                bclr    #4,RaceActor_ControlFlags(a1)
                bra.s   .loc_12844


.loc_1285E:
                bclr    #4,(ram_FF3012).l
                rts
; End of function Race_ClearActorOnFootFlags


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_UpdateStaticActors
; Static/police actor AI: walks Race_StaticActorList and updates movement/collision.
; In:  Race_StaticActorList; unk_25A10 actor data
; Out: static actor fields; collision helpers
; Clobbers: all
; *************************************************

Race_UpdateStaticActors:
                lea     (Race_StaticActorList).l,a2

.loc_1286E:
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .locret_128DE
                cmpi.w  #$FFFF,$56(a1)
                bne.s   .loc_1286E
                btst    #6,RaceActor_ControlFlags(a1)
                beq.s   .loc_1286E
                move.w  $16(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a0
                movea.l (a0,d0.w),a0
                move.w  $12(a1),d0
                move.w  (Race_ram_FrameDelay).l,d1
                mulu.w  d1,d0
                move.l  d0,$26(a1)
                bsr.w   sub_113A4
                btst    #3,RaceActor_StateFlags(a1)
                bne.w   .loc_128BE
                bsr.w   Race_UpdateActorMovement
                bra.w   .loc_128C2


.loc_128BE:
                bsr.w   Race_UpdateActorFallMovement

.loc_128C2:
                move.w  $36(a1),d1
                add.w   $38(a1),d1
                move.w  d1,0.w(a1)
                bsr.w   sub_137E4
                bsr.w   sub_12C9A
                jsr     (sub_13DE0).l
                bra.s   .loc_1286E


.locret_128DE:
                rts
; End of function Race_UpdateStaticActors


; =============== S U B R O U T I N E =======================================


Race_InitExtraStaticActor:
                cmpi.l  #$708,(Race_ram_ProgressSnapshotB).l
                bcs.w   .locret_12972
                bset    #6,RaceActor_ControlFlags(a1)
                jsr     (Rand_GetWord).l
                move.w  (Race_ram_PlayerProgress).l,d1
                add.w   (ram_FF1B30).l,d1
                subq.w  #1,d1
                btst    #0,d0
                bne.w   .loc_1291A
                move.b  #0,RaceActor_Palette(a1)
                bra.w   .loc_12920


.loc_1291A:
                move.b  #2,RaceActor_Palette(a1)

.loc_12920:
                tst.w   d0
                bmi.w   .loc_12942
                addq.w  #1,d1
                andi.w  #$7FF,d0
                move.w  d0,$30(a1)
                bset    #3,RaceActor_StateFlags(a1)
                move.w  d0,0.w(a1)
                move.w  d0,$1A(a1)
                bra.w   .loc_1295A


.loc_12942:
                bclr    #3,RaceActor_StateFlags(a1)
                andi.w  #$7FF,d0
                neg.w   d0
                move.w  d0,$30(a1)
                move.w  d0,0.w(a1)
                move.w  d0,$1A(a1)

.loc_1295A:
                move.w  #0,$32(a1)
                move.w  #$1770,$12(a1)
                swap    d1
                clr.w   d1
                move.l  d1,4(a1)
                move.l  d1,RaceActor_PreviousX(a1)

.locret_12972:
                rts
; End of function Race_InitExtraStaticActor


; =============== S U B R O U T I N E =======================================


Race_UpdateExtraStaticActor:
                lea     (ram_FF2FAA).l,a1
                cmpi.l  #$708,(Race_ram_ProgressSnapshotB).l
                bcc.w   .loc_12992
                bclr    #6,RaceActor_ControlFlags(a1)
                bra.w   .locret_12A86


.loc_12992:
                btst    #6,RaceActor_ControlFlags(a1)
                beq.w   .locret_12A86
                move.w  $30(a1),d0
                btst    #3,RaceActor_StateFlags(a1)
                beq.w   .loc_129AC
                neg.w   d0

.loc_129AC:
                tst.w   d0
                bpl.w   .loc_12A32
                lea     (Race_StaticActorList).l,a0

.loc_129B8:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_12A32
                move.l  4(a2),d1
                sub.l   4(a1),d1
                bpl.w   .loc_129E4
                btst    #3,RaceActor_StateFlags(a2)
                bne.s   .loc_129B8
                cmp.l   #$FFF00000,d1
                bmi.s   .loc_129B8
                bra.w   .loc_129F4


.loc_129E4:
                btst    #3,RaceActor_StateFlags(a2)
                beq.s   .loc_129B8
                cmp.l   #$100000,d1
                bpl.s   .loc_129B8

.loc_129F4:
                neg.w   d0
                subi.w  #$100,d0
                bmi.w   .loc_12A32
                subi.w  #$100,d0
                bpl.w   .loc_12A16
                move.w  #0,$12(a1)
                move.w  #0,$14(a1)
                bra.w   .loc_12A38


.loc_12A16:
                ext.l   d0
                asl.l   #8,d0
                move.w  $12(a1),d1
                mulu.w  #8,d1
                cmp.l   d1,d0
                blt.w   .loc_12A32
                move.w  #$FFF8,$14(a1)
                bra.w   .loc_12A38


.loc_12A32:
                move.w  #$20,$14(a1) ; ' '

.loc_12A38:
                move.w  $12(a1),d0
                move.w  (Race_ram_FrameDelay).l,d2
                move.w  $14(a1),d1
                mulu.w  d2,d1
                add.w   d1,d0
                bcc.w   .loc_12A5C
                move.w  #0,d0
                move.w  #0,$12(a1)
                bra.w   .loc_12A7C


.loc_12A5C:
                cmp.w   #$1770,d0
                ble.w   .loc_12A68
                move.w  #$1770,d0

.loc_12A68:
                move.w  d0,$12(a1)
                mulu.w  d2,d0
                lsr.l   #8,d0
                btst    #3,RaceActor_StateFlags(a1)
                beq.w   .loc_12A7C
                neg.w   d0

.loc_12A7C:
                move.w  $30(a1),$1A(a1)
                add.w   d0,$30(a1)

.locret_12A86:
                rts
; End of function Race_UpdateExtraStaticActor


; =============== S U B R O U T I N E =======================================


Race_GetCollisionExtent:
                cmp.b   #$10,d4
                bpl.w   .loc_12A96
                bsr.w   Race_GetActorCollisionExtent
                rts


.loc_12A96:
                bsr.w   Race_GetStaticCollisionExtent
                rts
; End of function Race_GetCollisionExtent


; =============== S U B R O U T I N E =======================================


Race_GetActorCollisionExtent:
                movem.l d1-d3,-(sp)
                lea     (unk_12B7C).l,a6
                asr.w   #3,d2
                addq.w  #2,d2
                cmp.w   #2,d2
                bpl.w   .loc_12AC0
                tst.w   d2
                bpl.w   .loc_12ACC
                move.w  #0,d2
                bra.w   .loc_12ACC


.loc_12AC0:
                cmp.w   #4,d2
                ble.w   .loc_12ACC
                move.w  #4,d2

.loc_12ACC:
                asl.w   #1,d2
                add.w   d2,d3
                asr.w   #4,d1
                bpl.w   .loc_12AD8
                neg.w   d1

.loc_12AD8:
                cmp.w   #3,d1
                ble.w   .loc_12AE4
                move.w  #3,d1

.loc_12AE4:
                asl.w   #1,d1
                add.w   d1,d3
                asl.w   #2,d1
                add.w   d1,d3
                move.b  (a6,d3.w),d0
                ext.w   d0
                movem.l (sp)+,d1-d3
                rts
; End of function Race_GetActorCollisionExtent


; =============== S U B R O U T I N E =======================================


Race_GetStaticCollisionExtent:
                cmp.b   #$12,d4
                bpl.w   .loc_12B06
                move.w  #$37,d0 ; '7'
                rts


.loc_12B06:
                move.w  #$60,d0 ; '`'
                rts
; End of function Race_GetStaticCollisionExtent


; =============== S U B R O U T I N E =======================================


Race_GetAttackerReach:
                btst    #1,RaceActor_AttackFlags(a1)
                beq.w   .loc_12B1E
                move.w  #$28,d0 ; '('
                bra.w   .locret_12B22


.loc_12B1E:
                move.w  #$19,d0

.locret_12B22:
                rts
; End of function Race_GetAttackerReach


; =============== S U B R O U T I N E =======================================


Race_GetDefenderReach:
                move.w  #$1A,d0
                rts
; End of function Race_GetDefenderReach


                dc.b $48 ; H
                dc.b $E7
                dc.b $70 ; p
                dc.b   0
                dc.b $38 ; 8
                dc.b   2
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $44 ; D
                dc.b $E6
                dc.b $4C ; L
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $3A ; :
                dc.b $38 ; 8
                dc.b   1
                dc.b $4A ; J
                dc.b $44 ; D
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $44 ; D
                dc.b $44 ; D
                dc.b $44 ; D
                dc.b $43 ; C
                dc.b $E8
                dc.b $4C ; L
                dc.b $B8
                dc.b $7C ; |
                dc.b   0
                dc.b   2
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b $24 ; $
                dc.b $E3
                dc.b $44 ; D
                dc.b $D8
                dc.b $43 ; C
                dc.b $4D ; M
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $2B ; +
                dc.b $CC
                dc.b $10
                dc.b $36 ; 6
                dc.b $40 ; @
                dc.b   0
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $17
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b $48 ; H
                dc.b $80
                dc.b $4C ; L
                dc.b $DF
                dc.b   0
                dc.b  $E
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b $4C ; L
                dc.b $DF
                dc.b   0
                dc.b  $E
                dc.b $61 ; a
                dc.b $92
                dc.b $4E ; N
                dc.b $75 ; u
unk_12B7C:      dc.b $10
                dc.b $19
                dc.b  $C
                dc.b $13
                dc.b  $D
                dc.b  $D
                dc.b $13
                dc.b  $C
                dc.b $19
                dc.b $10
                dc.b  $E
                dc.b $16
                dc.b  $C
                dc.b  $F
                dc.b  $D
                dc.b  $D
                dc.b  $E
                dc.b $14
                dc.b $13
                dc.b $18
                dc.b $15
                dc.b  $F
                dc.b  $A
                dc.b  $C
                dc.b  $D
                dc.b  $D
                dc.b  $F
                dc.b $10
                dc.b $18
                dc.b $13
                dc.b $12
                dc.b $13
                dc.b  $D
                dc.b $12
                dc.b  $D
                dc.b  $D
                dc.b  $D
                dc.b $10
                dc.b $11
                dc.b $12
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $1E
                dc.b $1E
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $1E
                dc.b $1E
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1E
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
                dc.b $1A
                dc.b $1A
                dc.b $1A
                dc.b $1A
                dc.b   0
                dc.b $1A

; =============== S U B R O U T I N E =======================================


sub_12BD2:
                move.w  4(a1),d0
                lea     (Track_CurveBuffer).l,a4
                move.w  d0,d1
                sub.w   (Race_ram_PlayerProgress).l,d1
                bpl.w   .loc_12BEA
                neg.w   d1

.loc_12BEA:
                cmp.w   #$40,d1 ; '@'
                bpl.w   .locret_12C98
                andi.w  #$FF,d0
                asl.w   #1,d0
                move.b  1(a4,d0.w),d1
                btst    #0,RaceActor_ControlFlags(a1)
                beq.w   .loc_12C16
                cmpi.w  #$1E,$2E(a1)
                bmi.w   .loc_12C1C
                move.b  (ram_FF1AC8).l,d1

.loc_12C16:
                ext.w   d1
                move.w  d1,$A(a1)

.loc_12C1C:
                addi.w  #$C,d0
                andi.w  #$1FF,d0
                move.b  2(a4,d0.w),d0
                ext.w   d0
                move.w  d0,$44(a1)
                btst    #2,RaceActor_StateFlags(a1)
                beq.w   .loc_12C3C
                add.w   RaceActor_CurveDirection(a1),d0

.loc_12C3C:
                bsr.w   sub_12CCE
                move.w  $C(a1),8(a1)
                move.w  8(a1),d1
                bpl.w   .loc_12C50
                neg.w   d1

.loc_12C50:
                cmp.w   #$7F,d1
                bmi.w   .locret_12C98
                cmpi.b  #$FF,RaceActor_AnimState(a1)
                bne.w   .locret_12C98
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .loc_12C76
                jsr     (sub_15538).l
                bra.w   .loc_12C7C


.loc_12C76:
                jsr     (sub_1555C).l

.loc_12C7C:
                move.b  #0,RaceActor_AnimState(a1)
                move.b  #$FF,RaceActor_AnimFrame(a1)
                bset    #4,RaceActor_ControlFlags(a1)
                bsr.w   sub_11906
                bclr    #7,RaceActor_WeaponAnimFlags(a1)

.locret_12C98:
                rts
; End of function sub_12BD2


; =============== S U B R O U T I N E =======================================


sub_12C9A:
                move.w  4(a1),d0
                lea     (Track_CurveBuffer).l,a4
                andi.w  #$FF,d0
                asl.w   #1,d0
                move.b  1(a4,d0.w),d1
                ext.w   d1
                move.w  d1,$A(a1)
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,$44(a1)
                add.w   RaceActor_CurveDirection(a1),d0
                move.w  d0,8(a1)
                move.w  #0,$C(a1)
                rts
; End of function sub_12C9A


; =============== S U B R O U T I N E =======================================


sub_12CCE:
                move.w  (Race_ram_FrameDelay).l,d1
                asl.w   #1,d1
                move.w  d0,d2
                move.w  $C(a1),d3
                cmp.w   d3,d2
                bpl.w   .loc_12CF4
                neg.w   d1
                sub.w   d3,d2
                cmp.w   d1,d2
                bpl.w   .loc_12D04
                add.w   d1,$C(a1)
                bra.w   .locret_12D08


.loc_12CF4:
                sub.w   d3,d2
                cmp.w   d1,d2
                bmi.w   .loc_12D04
                add.w   d1,$C(a1)
                bra.w   .locret_12D08


.loc_12D04:
                move.w  d0,$C(a1)

.locret_12D08:
                rts
; End of function sub_12CCE


unk_12D0A:
    dc.w    $FF60,$FFA0,$FFE0,$0020,$0060,$00A0

; inner dispatch table: 99 code pointers (ActorActionSlot_* index into it)
Race_ActorActionTable:
    dc.l    Race_ActorRecovery,Race_DispatchActorAction,Race_ActorFollowPath,Race_ActorSteerRoadCenter
    dc.l    Race_ActorEvadePlayer,Race_ActorNormalUpdate,Race_ActorNormalVariant,Race_ActorNormalUpdate
    dc.l    Race_ActorNormalUpdate,Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorFollowPath
    dc.l    Race_ActorSteerThrottle,Race_ActorSteerCollide,Race_ActorNormalUpdate,Race_DispatchActorAction
    dc.l    Race_ActorFollowPath,Race_ActorSteerThrottle,Race_ActorPursueAttack,Race_ActorNormalUpdate
    dc.l    Race_DispatchActorAction,Race_ActorFollowPath,Race_ActorSteerThrottle,Race_ActorCollideSteer
    dc.l    Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorFollowPath,Race_ActorSteerThrottle
    dc.l    Race_ActorAttackIfClose,Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorFollowPath
    dc.l    Race_ActorSteerRoadCenter,Race_ActorSteerCollide,Race_ActorNormalUpdate,Race_DispatchActorAction
    dc.l    Race_ActorFollowPath,Race_ActorSteerRoadCenter,Race_ActorPursueAttack,Race_ActorNormalUpdate
    dc.l    Race_DispatchActorAction,Race_ActorFollowPath,Race_ActorSteerRoadCenter,Race_ActorCollideSteer
    dc.l    Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorFollowPath,Race_ActorSteerRoadCenter
    dc.l    Race_ActorAttackIfClose,Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorFollowPath
    dc.l    Race_ActorSteerRoadCenter,Race_ActorRandomCombatChoice,Race_ActorNormalUpdate,Race_DispatchActorAction
    dc.l    Race_ActorFollowPath,Race_ActorSteerRoadCenter,Race_ActorProximityReaction,Race_ActorNormalUpdate
    dc.l    Race_DispatchActorAction,Race_ActorStateCollision,Race_ActorSteerThrottle,Race_ActorSteerCollide
    dc.l    Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorStateCollision,Race_ActorSteerThrottle
    dc.l    Race_ActorPursueAttack,Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorStateCollision
    dc.l    Race_ActorSteerThrottle,Race_ActorCollideSteer,Race_ActorNormalUpdate,Race_DispatchActorAction
    dc.l    Race_ActorStateCollision,Race_ActorSteerThrottle,Race_ActorAttackIfClose,Race_ActorNormalUpdate
    dc.l    Race_DispatchActorAction,Race_ActorStateCollision,Race_ActorSteerRoadCenter,Race_ActorSteerCollide
    dc.l    Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorStateCollision,Race_ActorSteerRoadCenter
    dc.l    Race_ActorPursueAttack,Race_ActorNormalUpdate,Race_DispatchActorAction,Race_ActorStateCollision
    dc.l    Race_ActorSteerRoadCenter,Race_ActorCollideSteer,Race_ActorNormalUpdate,Race_DispatchActorAction
    dc.l    Race_ActorStateCollision,Race_ActorSteerRoadCenter,Race_ActorAttackIfClose

Race_UpdateActorActions:
                move.w  #0,(ram_FF1A98).l
                lea     (ram_FF1A08).l,a0
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_12EBC
                addq.w  #4,a0

.loc_12EBC:
                movea.l (a0)+,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_12FE2
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_12EE4
                tst.b   RaceActor_AnimState(a1)
                bmi.w   .loc_12EE4
                move.l  a0,-(sp)
                bsr.w   Race_UpdateActorSpeedState
                movea.l (sp)+,a0
                bra.s   .loc_12EBC


.loc_12EE4:
                move.b  $75(a1),d2
                ext.w   d2
                asl.w   #2,d2
                lea     (Race_ActorGraphicsTable).l,a4
                movea.l (a4,d2.w),a4
                move.l  a4,(ram_FF1A68).l
                move.w  $5C(a1),d0
                add.w   (Race_ram_FrameDelay).l,d0
                cmp.w   (ram_FF18A8).l,d0
                bcs.w   .loc_12F14
                move.w  $E(a4),d0

.loc_12F14:
                move.w  d0,$5C(a1)
                move.l  a0,-(sp)
                btst    #7,(RacePlayerA + RaceActor_ControlFlags).l
                bne.w   .loc_12F60
                move.w  4(a1),d0
                sub.w   (RacePlayerA + RaceActor_X).l,d0
                bpl.w   .loc_12F4A
                cmp.w   #$FFEE,d0
                bpl.w   .loc_12F60
                bclr    #6,RaceActor_ControlFlags(a1)
                bsr.w   Race_RecycleActor
                bra.w   .loc_12FDC


.loc_12F4A:
                cmp.w   #$22,d0 ; '"'
                bmi.w   .loc_12F60
                bclr    #6,RaceActor_ControlFlags(a1)
                bsr.w   Race_RecycleOpponent
                bra.w   .loc_12FDC


.loc_12F60:
                bset    #6,RaceActor_ControlFlags(a1)
                move.b  RaceActor_ActionProfile(a1),d2
                ext.w   d2
                asl.w   #2,d2
                lea     (Race_ActorProfileTable).l,a4
                movea.l (a4,d2.w),a4
                cmpa.l  #RacePlayerA,a1
                beq.w   .loc_12FD8
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_12FCE
                move.b  (ram_FF1ADB).l,d0
                cmp.b   $71(a1),d0
                bne.w   .loc_12FA6
                cmpi.w  #3,(ram_FF0520).l
                bne.w   .loc_12FD8

.loc_12FA6:
                move.w  RaceActor_Rating(a1),d0
                cmp.w   (RacePlayerA + RaceActor_Speed).l,d0
                bgt.w   .loc_12FD8
                cmpa.l  (Race_ram_NearestActor).l,a1
                beq.w   .loc_12FCE
                move.w  (ram_FF1A98).l,d0
                cmp.w   (ram_FF1A96).l,d0
                bpl.w   .loc_12FD8

.loc_12FCE:
                addi.w  #1,(ram_FF1A98).l
                addq.w  #4,a4

.loc_12FD8:
                movea.l (a4),a6
                jsr     (a6)

.loc_12FDC:
                movea.l (sp)+,a0
                bra.w   .loc_12EBC


.locret_12FE2:
                rts
; End of function Race_UpdateActorActions
 ; *****
; Function Race_ActorStateCollision
; Actor action handler: updates $68 state bits and calls Race_UpdateActorSpeedCurve/Race_UpdateActorSpeedState.
; In:  a1 - actor
; Out: actor $68 bits
; Clobbers: see callees
; *****

Race_ActorStateCollision:
                bsr.w       Race_UpdateActorSpeedCurve
                btst.b      #$5,RaceActor_ControlFlags(a1)
                beq.w       loc_12FFE
                bset.b      #$2,RaceActor_ControlFlags(a1)
                bclr.b      #$1,RaceActor_ControlFlags(a1)
loc_12FFE:
                bsr.w       Race_UpdateActorSpeedState
                rts
Race_ActorFollowPath:
                bsr.w       Race_UpdateActorSpeedCurve
                bsr.w       Race_UpdateActorSpeedGear
                rts
Race_ActorNormalUpdate:
                bclr.b      #$4,RaceActor_StateFlags(a1)
                bclr.b      #$2,RaceActor_StateFlags(a1)
                move.b      RaceActor_AnimIndex(a1),d0
                ext.w       d0
                bsr.w       Race_FindTargetActor
                cmpa.l      #$FFFFFFFF,a2
                beq.w       loc_13036
                bsr.w       Race_UpdateActorSpeedCurve
                bra.w       loc_13054
loc_13036:
                bsr.w       sub_13D44
                tst.w       (ram_FF18A4).l
                bne.w       loc_13054
                bset.b      #$1,RaceActor_ControlFlags(a1)
                bclr.b      #$2,RaceActor_ControlFlags(a1)
                bsr.w       Race_UpdateActorRoadSteering
loc_13054:
                btst.b      #$5,RaceActor_ControlFlags(a1)
                bne.w       loc_1306A
                bsr.w       Race_GetCurveSpeedLimit
                cmp.w       $12(a1),d0
                bpl.w       loc_13076
loc_1306A:
                bset.b      #$2,RaceActor_ControlFlags(a1)
                bclr.b      #$1,RaceActor_ControlFlags(a1)
loc_13076:
                bsr.w       Race_UpdateActorSpeedState
                rts
Race_ActorNormalVariant:
                bclr.b      #$4,RaceActor_StateFlags(a1)
                bclr.b      #$2,RaceActor_StateFlags(a1)
                move.b      RaceActor_AnimIndex(a1),d0
                ext.w       d0
                bsr.w       Race_FindTargetActor
                cmpa.l      #$FFFFFFFF,a2
                bne.w       loc_130B2
                bsr.w       sub_13D44
                tst.w       (ram_FF18A4).l
                bne.w       loc_130BA
                bsr.w       Race_UpdateActorRoadSteering
                bra.w       loc_130B6
loc_130B2:
                bsr.w       Race_UpdateActorSpeedCurve
loc_130B6:
                bsr.w       Race_UpdateActorSpeedGear
loc_130BA:
                btst.b      #$5,RaceActor_ControlFlags(a1)
                beq.w       loc_130D0
                bset.b      #$2,RaceActor_ControlFlags(a1)
                bclr.b      #$1,RaceActor_ControlFlags(a1)
loc_130D0:
                rts
Race_ActorRecovery:
                move.w      (ram_FF1B32).l,d0
                beq.w       loc_13100
                move.w      #$0,$14(a1)
                move.w      #$0,$12(a1)
                sub.w       (Race_ram_FrameDelay).l,d0
                move.w      d0,(ram_FF1B32).l
                bgt.w       loc_13104
                move.w      #$0,(ram_FF1B32).l
loc_13100:
                bsr.w       Race_ActorNormalUpdate
loc_13104:
                rts

; =============== S U B R O U T I N E =======================================


Race_UpdateStaticActions:
                lea     (Race_StaticActorList).l,a0

.loc_1310C:
                movea.l (a0)+,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_1312E
                move.b  RaceActor_ActionProfile(a1),d0
                ext.w   d0
                asl.w   #3,d0
                lea     (Race_StaticActionTable).l,a2
                movea.l (a2,d0.w),a3
                jsr     (a3)
                bra.s   .loc_1310C


.locret_1312E:
                rts
; End of function Race_UpdateStaticActions
Race_ClampActorY:
                move.l      $4(a1),d0
                sub.l       (Race_ram_PlayerProgress).l,d0
                bpl.w       loc_13140
                neg.l       d0
loc_13140:
                cmp.l       #$210000,d0
                blt.w       loc_13154
                bclr.b      #$6,RaceActor_ControlFlags(a1)
                bra.w       loc_131B8
loc_13154:
                move.w      RaceActor_CurveDirection(a1),d0
                muls.w      $12(a1),d0
                swap        d0
                mulu.w      (Race_ram_FrameDelay).l,d0
                move.w      $30(a1),d2
                add.w       d2,d0
                btst.b      #$3,RaceActor_StateFlags(a1)
                bne.w       loc_13194
                cmp.w       #$A9,d0
                bpl.w       loc_1318C
                cmp.w       #$37,d0
                bpl.w       loc_131B8
                move.w      #$37,d0
                bra.w       loc_131B4
loc_1318C:
                move.w      #$A9,d0
                bra.w       loc_131B4
loc_13194:
                cmp.w       #$FF57,d0
                bmi.w       loc_131AC
                cmp.w       #$FFC9,d0
                bmi.w       loc_131B8
                move.w      #$FFC9,d0
                bra.w       loc_131B4
loc_131AC:
                move.w      #$FF57,d0
                bra.w       loc_131B4
loc_131B4:
                neg.w       RaceActor_CurveDirection(a1)
loc_131B8:
                move.w      d0,$30(a1)
                rts

; =============== S U B R O U T I N E =======================================


Race_UpdateActorSpeedGear:
                lea     (RacePlayerA).l,a2
                move.w  $12(a1),d6
                movea.l (ram_FF1A68).l,a4
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_131E0
                cmp.w   RaceActor_Rating(a1),d6
                bmi.w   .loc_1325E

.loc_131E0:
                sub.w   $12(a2),d6
                move.l  4(a1),d7
                sub.l   4(a2),d7
                bmi.w   .loc_13248
                btst    #4,RaceActor_ControlFlags(a2)
                beq.w   .loc_13202
                tst.b   RaceActor_AnimState(a2)
                bpl.w   .loc_1325E

.loc_13202:
                tst.w   d6
                bpl.w   .loc_13280
                neg.w   d6
                divu.w  d6,d7
                move.w  $16(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a3
                movea.l (a3,d0.w),a3
                move.w  $18(a1),d0
                asl.w   #1,d0
                move.w  2(a3,d0.w),d5
                mulu.w  d7,d5
                move.w  $14(a2),d0
                muls.w  d7,d0
                ext.l   d6
                add.l   d0,d6
                cmp.l   d6,d5
                blt.w   .loc_1325E
                bclr    #1,RaceActor_ControlFlags(a1)
                bclr    #1,RaceActor_ControlFlags(a1)
                bra.w   .loc_1328C


.loc_13248:
                tst.w   d6
                ble.w   .loc_1325E
                neg.l   d7
                divu.w  d6,d7
                mulu.w  #$40,d7 ; '@'
                ext.l   d6
                cmp.l   d6,d7
                bmi.w   .loc_13280

.loc_1325E:
                bset    #1,RaceActor_ControlFlags(a1)
                bclr    #2,RaceActor_ControlFlags(a1)
                btst    #5,RaceActor_ControlFlags(a1)
                bne.w   .loc_13280
                bsr.w   Race_GetCurveSpeedLimit
                cmp.w   $12(a1),d0
                bpl.w   .loc_1328C

.loc_13280:
                bset    #2,RaceActor_ControlFlags(a1)
                bclr    #1,RaceActor_ControlFlags(a1)

.loc_1328C:
                bsr.w   Race_UpdateActorSpeedState
                rts
; End of function Race_UpdateActorSpeedGear


; =============== S U B R O U T I N E =======================================


Race_UpdateActorChase:
                lea     (RacePlayerA).l,a2
                move.w  $12(a1),d6
                movea.l (ram_FF1A68).l,a4
                sub.w   $12(a2),d6
                move.l  4(a2),d7
                addi.l  #$8000,d7
                sub.l   4(a1),d7
                bpl.w   .loc_132F4
                tst.w   d6
                bpl.w   .loc_1332A
                neg.w   d6
                neg.l   d7
                divu.w  d6,d7
                move.w  $16(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a3
                movea.l (a3,d0.w),a3
                move.w  $18(a1),d0
                asl.w   #1,d0
                move.w  2(a3,d0.w),d5
                mulu.w  d7,d5
                move.w  $14(a2),d0
                muls.w  d7,d0
                ext.l   d6
                add.l   d0,d6
                cmp.l   d6,d5
                bpl.w   .loc_1332A
                bra.w   .loc_13308


.loc_132F4:
                tst.w   d6
                ble.w   .loc_13308
                divu.w  d6,d7
                mulu.w  #$40,d7 ; '@'
                ext.l   d6
                cmp.l   d6,d7
                bmi.w   .loc_1332A

.loc_13308:
                bset    #1,RaceActor_ControlFlags(a1)
                bclr    #2,RaceActor_ControlFlags(a1)
                btst    #5,RaceActor_ControlFlags(a1)
                bne.w   .loc_1332A
                bsr.w   Race_GetCurveSpeedLimit
                cmp.w   $12(a1),d0
                bpl.w   .loc_13336

.loc_1332A:
                bset    #2,RaceActor_ControlFlags(a1)
                bclr    #1,RaceActor_ControlFlags(a1)

.loc_13336:
                bsr.w   Race_UpdateActorSpeedState
                rts
; End of function Race_UpdateActorChase


; =============== S U B R O U T I N E =======================================


Race_ApplyActorSpeedCorrection:
                move.w  $30(a2),d0
                move.w  $30(a1),d2
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_13370
                tst.w   d0
                bpl.w   .loc_13364
                cmp.w   #$FF3C,d0
                bpl.w   .loc_13370
                move.w  #$FF3C,d0
                bra.w   .loc_13370


.loc_13364:
                cmp.w   #$C4,d0
                ble.w   .loc_13370
                move.w  #$C4,d0

.loc_13370:
                sub.w   d2,d0
                bmi.w   .loc_13378
                neg.w   d1

.loc_13378:
                add.w   d1,d0
                move.w  $12(a1),d1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_1338A
                lsr.w   #1,d1

.loc_1338A:
                lsr.w   #8,d1
                beq.w   .locret_133EE
                movem.l d0-d1,-(sp)
                bsr.w   Race_ScaleActorSpeed
                move.w  d0,d2
                movem.l (sp)+,d0-d1
                tst.w   d2
                beq.w   .loc_133C0
                mulu.w  d2,d1
                cmp.l   #$10000,d1
                bcs.w   .loc_133B8
                move.w  #0,d0
                bra.w   .loc_133E4


.loc_133B8:
                ext.l   d0
                swap    d0
                divs.w  d1,d0
                asr.w   #8,d0

.loc_133C0:
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d1
                tst.w   d0
                bpl.w   .loc_133DC
                neg.w   d1
                cmp.w   d1,d0
                bpl.w   .loc_133E4
                bra.w   .loc_133E2


.loc_133DC:
                cmp.w   d1,d0
                ble.w   .loc_133E4

.loc_133E2:
                move.w  d1,d0

.loc_133E4:
                move.w  d0,RaceActor_CurveDirection(a1)
                bset    #2,RaceActor_StateFlags(a1)

.locret_133EE:
                rts
; End of function Race_ApplyActorSpeedCorrection


                dc.b $90
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b $48 ; H
                dc.b $C0
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $32 ; 2
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $E0
                dc.b $49 ; I
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $1C
                dc.b $34 ; 4
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $46 ; F
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $C2
                dc.b $C2
                dc.b $81
                dc.b $C1
                dc.b $E0
                dc.b $40 ; @
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $46 ; F
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $69 ; i
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


Race_UpdateActorSpeedCurve:
                move.w  (ram_FF1B46).l,(ram_FF1896).l
                move.l  a2,-(sp)
                move.w  (ram_FF1B46).l,-(sp)
                move.w  d0,-(sp)
                move.w  #0,(ram_FF1898).l
                move.w  #0,(ram_FF18A0).l
                cmpi.b  #$10,$71(a2)
                bmi.w   .loc_13472
                cmpi.b  #$12,$71(a2)
                bpl.w   .loc_13472
                tst.w   $30(a1)
                bmi.w   .loc_1346A
                move.w  #2,d0
                bra.w   .loc_13480


.loc_1346A:
                move.w  #5,d0
                bra.w   .loc_134BC


.loc_13472:
                tst.w   $30(a1)
                bmi.w   .loc_134F0

.loc_1347A:
                subq.w  #1,d0
                ble.w   .loc_134B0

.loc_13480:
                bsr.w   Race_FindTargetActor
                move.l  a2,(ram_FF1892).l
                move.w  (ram_FF1B46).l,(ram_FF1898).l
                move.w  d0,(ram_FF189A).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_1347A

.loc_134B0:
                move.w  (sp),d0

.loc_134B2:
                addq.w  #1,d0
                cmp.w   #7,d0
                bpl.w   .loc_13562

.loc_134BC:
                bsr.w   Race_FindTargetActor
                move.l  a2,(ram_FF189C).l
                move.w  (ram_FF1B46).l,(ram_FF18A0).l
                move.w  d0,(ram_FF18A2).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_134B2
                bra.w   .loc_13562


.loc_134F0:
                addq.w  #1,d0
                cmp.w   #7,d0
                bpl.w   .loc_1352A
                bsr.w   Race_FindTargetActor
                move.l  a2,(ram_FF1892).l
                move.w  (ram_FF1B46).l,(ram_FF1898).l
                move.w  d0,(ram_FF189A).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_134F0

.loc_1352A:
                move.w  (sp),d0

.loc_1352C:
                subq.w  #1,d0
                bmi.w   .loc_13562
                bsr.w   Race_FindTargetActor
                move.l  a2,(ram_FF189C).l
                move.w  (ram_FF1B46).l,(ram_FF18A0).l
                move.w  d0,(ram_FF18A2).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_1352C

.loc_13562:
                addq.w  #2,sp
                move.w  (sp)+,(ram_FF1B46).l
                movea.l (sp)+,a2
                move.w  (ram_FF1898).l,d1
                cmp.w   (ram_FF18A0).l,d1
                bpl.w   .loc_135A2
                move.w  (ram_FF18A0).l,d1
                cmp.w   (ram_FF1B46).l,d1
                bmi.w   .loc_135C2
                move.w  d1,(ram_FF1B46).l
                movea.l (ram_FF189C).l,a2
                move.w  (ram_FF18A2).l,d0
                bra.w   .loc_135D6


.loc_135A2:
                cmp.w   (ram_FF1B46).l,d1
                bmi.w   .loc_135C2
                move.w  d1,(ram_FF1B46).l
                movea.l (ram_FF1892).l,a2
                move.w  (ram_FF189A).l,d0
                bra.w   .loc_135D6


.loc_135C2:
                bclr    #1,RaceActor_ControlFlags(a1)
                bset    #2,RaceActor_ControlFlags(a1)
                bra.w   .locret_135E6


.loc_135D2:
                addq.w  #4,sp
                movea.l (sp)+,a2

.loc_135D6:
                bsr.w   sub_13892
                bset    #1,RaceActor_ControlFlags(a1)
                bclr    #2,RaceActor_ControlFlags(a1)

.locret_135E6:
                rts
; End of function Race_UpdateActorSpeedCurve


                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $68 ; h
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


Race_FindTargetActor:
                lea     (ram_FF178A).l,a6
                move.b  (a6,d0.w),d1
                ext.w   d1
                beq.w   .loc_1361E
                move.w  #$F0,(ram_FF1B46).l
                bsr.w   Race_ScanTargetDistance
                cmpi.w  #$F0,(ram_FF1B46).l
                blt.w   .locret_13624

.loc_1361E:
                movea.l #$FFFFFFFF,a2

.locret_13624:
                rts
; End of function Race_FindTargetActor


; =============== S U B R O U T I N E =======================================


Race_ScanTargetDistance:
                move.b  $71(a1),d7
                subq.w  #1,d1
                lea     (ram_FF1792).l,a6
                move.w  d0,d2
                asl.w   #4,d2
                adda.w  d2,a6

.loc_13638:
                move.b  (a6)+,d2
                cmp.b   d7,d2
                beq.w   .loc_136B0
                cmp.b   #$10,d2
                bpl.w   .loc_13656
                lea     (Race_ActorList).l,a0
                move.w  #0,d6
                bra.w   .loc_13664


.loc_13656:
                lea     (Race_StaticActorList).l,a0
                move.w  #$FFFF,d6
                subi.w  #$10,d2

.loc_13664:
                ext.w   d2
                asl.w   #2,d2
                movea.l (a0,d2.w),a2
                move.w  $12(a1),d2
                btst    #3,RaceActor_StateFlags(a1)
                beq.w   .loc_1367C
                neg.w   d2

.loc_1367C:
                move.w  $12(a2),d4
                btst    #3,RaceActor_StateFlags(a2)
                beq.w   .loc_1368C
                neg.w   d4

.loc_1368C:
                sub.w   d4,d2
                ble.w   .loc_136B0
                move.l  4(a2),d3
                sub.l   4(a1),d3
                ble.w   .loc_136B0
                divu.w  d2,d3
                cmp.w   (ram_FF1B46).l,d3
                bpl.w   .loc_136B0
                move.w  d3,(ram_FF1B46).l

.loc_136B0:
                dbf     d1,.loc_13638
                rts
; End of function Race_ScanTargetDistance


; =============== S U B R O U T I N E =======================================


Race_ScaleActorSpeed:
                move.w  $12(a1),d1
                btst    #3,RaceActor_StateFlags(a1)
                beq.w   .loc_136C6
                neg.w   d1

.loc_136C6:
                move.w  $12(a2),d2
                btst    #3,RaceActor_StateFlags(a2)
                beq.w   .loc_136D6
                neg.w   d2

.loc_136D6:
                sub.w   d1,d2
                beq.w   .loc_13700
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   .loc_136F4
                tst.w   d2
                bmi.w   .loc_13700
                neg.l   d0
                bra.w   .loc_136FC


.loc_136F4:
                tst.w   d2
                bpl.w   .loc_13700
                neg.w   d2

.loc_136FC:
                divu.w  d2,d0
                rts


.loc_13700:
                clr.w   d0
                rts
; End of function Race_ScaleActorSpeed


                dc.b $38 ; 8
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $BC
                dc.b $34 ; 4
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $44 ; D
                dc.b $94
                dc.b $44 ; D
                dc.b $6E ; n
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $36 ; 6
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $18
                dc.b $26 ; &
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AE
                dc.b $96
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $83
                dc.b $86
                dc.b $C2
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b $33 ; 3
                dc.b $C3
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $46 ; F
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_SetupActorSprite
; Sets up an actor sprite/position after spawn/recycle.
; In:  a1 - actor; Track_CurveBuffer
; Out: actor fields
; Clobbers: all
; *************************************************

Race_SetupActorSprite:
                movem.l d0-d1/a0,-(sp)
                move.w  $30(a1),d0
                move.w  d0,d1
                asr.w   #6,d0
                addq.b  #3,d0
                bpl.w   .loc_13760
                move.w  #0,d0
                bra.w   .loc_1376C


.loc_13760:
                cmp.b   #6,d0
                bmi.w   .loc_1376C
                move.w  #5,d0

.loc_1376C:
                move.b  d0,RaceActor_AnimIndex(a1)
                bsr.w   sub_13812
                move.w  $16(a1),d2
                lea     (unk_25812).l,a0
                asl.w   #2,d2
                move.w  (a0,d2.w),d2
                lsr.w   #1,d2
                move.w  d1,d0
                add.w   d4,d0
                asr.w   #6,d0
                addq.b  #3,d0
                bpl.w   .loc_1379A
                move.w  #0,d0
                bra.w   .loc_137A6


.loc_1379A:
                cmp.b   #6,d0
                bmi.w   .loc_137A6
                move.w  #5,d0

.loc_137A6:
                cmp.b   RaceActor_AnimIndex(a1),d0
                beq.w   .loc_137B2
                bsr.w   sub_13812

.loc_137B2:
                move.w  d1,d0
                sub.w   d4,d0
                asr.w   #6,d0
                addq.b  #3,d0
                bpl.w   .loc_137C6
                move.w  #0,d0
                bra.w   .loc_137D2


.loc_137C6:
                cmp.b   #6,d0
                bmi.w   .loc_137D2
                move.w  #5,d0

.loc_137D2:
                cmp.b   RaceActor_AnimIndex(a1),d0
                beq.w   .loc_137DE
                bsr.w   sub_13812

.loc_137DE:
                movem.l (sp)+,d0-d1/a0
                rts
; End of function Race_SetupActorSprite


; =============== S U B R O U T I N E =======================================


sub_137E4:
                movem.l d0-d1/a0,-(sp)
                clr.w   d0
                tst.w   $30(a1)
                bmi.w   .loc_137F6
                move.w  #3,d0

.loc_137F6:
                move.w  #2,d1
                move.b  d0,RaceActor_AnimIndex(a1)

.loc_137FE:
                move.w  d1,-(sp)
                bsr.w   sub_13812
                move.w  (sp)+,d1
                addq.w  #1,d0
                dbf     d1,.loc_137FE
                movem.l (sp)+,d0-d1/a0
                rts
; End of function sub_137E4


; =============== S U B R O U T I N E =======================================


sub_13812:
                movem.l d0-d1/a0,-(sp)
                ext.w   d0
                lea     (ram_FF178A).l,a0
                move.b  (a0,d0.w),d1
                addq.b  #1,(a0,d0.w)
                ext.w   d1
                lea     (ram_FF1792).l,a0
                asl.w   #4,d0
                adda.w  d0,a0
                move.b  $71(a1),(a0,d1.w)
                movem.l (sp)+,d0-d1/a0
                rts
; End of function sub_13812


; =============== S U B R O U T I N E =======================================


sub_1383E:
                clr.l   (ram_FF178A).l
                clr.l   (ram_FF178E).l
                rts
; End of function sub_1383E


; =============== S U B R O U T I N E =======================================


Race_UpdateActorRoadSteering:
                asl.w   #1,d0
                lea     (unk_12D0A).l,a6
                move.w  (a6,d0.w),d0
                sub.w   RaceActor_PosY(a1),d0
                beq.w   .return
                move.w  d0,d1
                bpl.w   .loc_13868
                neg.w   d1
.loc_13868:
                mulu.w  #$280,d1
                move.w  RaceActor_Speed(a1),d2
                mulu.w  d1,d2
                swap    d2
                tst.w   d2
                beq.w   .return
                ext.l   d0
                beq.w   .return
                swap    d0
                divs.w  d2,d0
                asr.w   #8,d0
                move.w  d0,RaceActor_CurveDirection(a1)
                bset    #2,RaceActor_StateFlags(a1)
.return:
                rts
; End of function Race_UpdateActorRoadSteering


; =============== S U B R O U T I N E =======================================


sub_13892:
                asl.w   #1,d0
                lea     (unk_12D0A).l,a6
                move.w  (a6,d0.w),d0
                sub.w   RaceActor_PosY(a1),d0
                ext.l   d0
                swap    d0
                move.w  RaceActor_Speed(a1),d1
                lsr.w   #8,d1
                beq.w   .return
                move.w  (ram_FF1B46).l,d2
                lsr.w   #1,d2
                beq.w   .loc_138BE
                mulu.w  d2,d1
.loc_138BE:
                divs.w  d1,d0
                asr.w   #8,d0
                move.w  d0,RaceActor_CurveDirection(a1)
                bset    #2,RaceActor_StateFlags(a1)
.return:
                rts
; End of function sub_13892


; =============== S U B R O U T I N E =======================================


sub_138CE:
                lea     (RacePlayerA).l,a1
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .return
                lea     (Race_StaticActorList).l,a0

.loc_138E4:
                movea.l (a0)+,a2
                cmpa.w  #$FFFF,a2
                beq.w   .return
                btst    #6,RaceActor_ControlFlags(a2)
                bne.s   .loc_138E4
                cmpi.w  #$FFFF,$56(a2)
                bne.w   .loc_13982
                bclr    #4,RaceActor_ControlFlags(a2)
                bsr.w   Rand_GetWord
                andi.w  #$FFF,d0
                lea     (unk_13A1A).l,a4
                move.w  (Menu_ram_PlayerLevel).l,d1
                asl.w   #1,d1
                move.w  (a4,d1.w),d1
                mulu.w  d1,d0
                swap    d0
                move.w  d0,$56(a2)
                move.w  d0,d1
                andi.b  #1,d1
                beq.w   .loc_13936
                move.w  #2,d1

.loc_13936:
                move.b  d1,RaceActor_Palette(a2)
                btst    #2,d0
                bne.w   .loc_13952
                bclr    #3,RaceActor_StateFlags(a2)
                move.w  #$70,$30(a2) ; 'p'
                bra.w   .loc_1395E


.loc_13952:
                bset    #3,RaceActor_StateFlags(a2)
                move.w  #$FF90,$30(a2)

.loc_1395E:
                andi.w  #$F0,d0
                lsr.w   #4,d0
                move.b  d0,RaceActor_ActionProfile(a2)
                ext.w   d0
                lea     (Race_StaticActionTable).l,a3
                asl.w   #3,d0
                move.w  4(a3,d0.w),$12(a2)
                move.w  6(a3,d0.w),RaceActor_CurveDirection(a2)
                bra.w   .loc_138E4


.loc_13982:
                cmpi.l  #$708,(Race_ram_ProgressSnapshotB).l
                bcs.w   .loc_138E4
                move.w  (Race_ram_FrameDelay).l,d2
                sub.w   d2,$56(a2)
                bgt.w   .loc_138E4
                move.w  #$FFFF,$56(a2)
                bsr.w   sub_13A26
                bra.w   .loc_138E4

                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $44 ; D
                dc.b $40 ; @
                dc.b $B0
                dc.b $7C ; |
                dc.b   0
                dc.b $21 ; !
                dc.b $6B ; k
                dc.b   0
                dc.b $FF
                dc.b $2E ; .
                dc.b  $C
                dc.b $6A ; j
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b $56 ; V
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $2E ; .
                dc.b   8
                dc.b $AA
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $68 ; h
                dc.b $61 ; a
                dc.b   0
                dc.b $26 ; &
                dc.b $6A ; j
                dc.b   2
                dc.b $40 ; @
                dc.b  $F
                dc.b $FF
                dc.b $49 ; I
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $3A ; :
                dc.b $1A
                dc.b $32 ; 2
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b   5
                dc.b  $A
                dc.b $E3
                dc.b $41 ; A
                dc.b $32 ; 2
                dc.b $34 ; 4
                dc.b $10
                dc.b   0
                dc.b $C0
                dc.b $C1
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b $56 ; V
                dc.b $60 ; `
                dc.b   0
                dc.b $FE
                dc.b $F8
                dc.b  $C
                dc.b $B9
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   8
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $9A
                dc.b $65 ; e
                dc.b   0
                dc.b $FE
                dc.b $EA
                dc.b $34 ; 4
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $30 ; 0
                dc.b $4A ; J
                dc.b $95
                dc.b $6A ; j
                dc.b   0
                dc.b $56 ; V
                dc.b $6E ; n
                dc.b   0
                dc.b $FE
                dc.b $DC
                dc.b $35 ; 5
                dc.b $7C ; |
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b $56 ; V
                dc.b $61 ; a
                dc.b   0
                dc.b   0
                dc.b $4A ; J
                dc.b $60 ; `
                dc.b   0
                dc.b $FE
                dc.b $CE


.return:
                rts
; End of function sub_138CE


unk_13A1A:      dc.b $FF
                dc.b $FF
                dc.b $B3
                dc.b $33 ; 3
                dc.b $80
                dc.b   0
                dc.b $4C ; L
                dc.b $CC
                dc.b $33 ; 3
                dc.b $33 ; 3
                dc.b $22 ; "
                dc.b $22 ; "

; =============== S U B R O U T I N E =======================================


sub_13A26:
                bclr    #0,RaceActor_ControlFlags(a2)
                move.w  #0,d0
                move.w  d0,2(a2)
                move.w  d0,$3C(a2)
                move.w  d0,$3A(a2)
                move.w  d0,$32(a2)
                move.l  (Race_ram_PlayerProgress).l,d0
                addi.l  #$208000,d0
                move.l  d0,4(a2)
                move.l  d0,RaceActor_PreviousX(a2)
                bset    #6,RaceActor_ControlFlags(a2)
                rts
; End of function sub_13A26


                dc.b   8
                dc.b $AA
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $68 ; h
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b   2
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b $3C ; <
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b $3A ; :
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b $32 ; 2
                dc.b $20
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $68 ; h
                dc.b   4
                dc.b $80
                dc.b   0
                dc.b $1F
                dc.b $80
                dc.b   0
                dc.b $25 ; %
                dc.b $40 ; @
                dc.b   0
                dc.b   4
                dc.b $25 ; %
                dc.b $40 ; @
                dc.b   0
                dc.b $1E
                dc.b   8
                dc.b $EA
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u

; *************************************************
; Function Race_UpdateActorSpeedState
; a1 - actor
; *************************************************

Race_UpdateActorSpeedState:
                btst    #7,RaceActor_ControlFlags(a1)
                beq.w   .loc_13AA6
                move.w  #$FFEC,RaceActor_Acceleration(a1)
                bra.w   .locret_13BBA
.loc_13AA6:
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_13AC2
                cmpi.b  #3,RaceActor_AnimState(a1)
                beq.w   .locret_13BBA
                bsr.w   sub_13BBC
                bra.w   .locret_13BBA
.loc_13AC2:
                clr.w   d1
                move.w  RaceActor_Type(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a0
                movea.l (a0,d0.w),a0
                move.w  RaceActor_Speed(a1),d0
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_13B68
                btst    #4,RaceActor_ControlFlags(a1)
                bne.w   .loc_13B3A
                btst    #1,RaceActor_ControlFlags(a1)
                beq.w   .loc_13B30
                move.w  RaceActor_Gear(a1),d1
                move.w  d1,d2
                asl.w   #1,d2
                move.w  $E(a0,d2.w),d3
                cmp.w   d3,d0
                bcs.w   .loc_13B1A
                cmp.w   0.w(a0),d1
                bpl.w   .loc_13B68
                addq.w  #1,d1
                move.w  d1,RaceActor_Gear(a1)
                move.w  d1,d2
                asl.w   #1,d2
.loc_13B1A:
                cmp.w   $1A(a0,d2.w),d0
                bcc.w   .loc_13B2C
                subq.w  #1,d1
                move.w  d1,RaceActor_Gear(a1)
                move.w  d1,d2
                asl.w   #1,d2
.loc_13B2C:
                move.w  2(a0,d2.w),d1
.loc_13B30:
                btst    #2,RaceActor_ControlFlags(a1)
                beq.w   .loc_13B3E
.loc_13B3A: 
                addi.w  #-$40,d1
.loc_13B3E:
                btst    #1,RaceActor_ControlFlags(a1)
                bne.w   .loc_13B4C
                addi.w  #-5,d1
.loc_13B4C:
                btst    #5,RaceActor_ControlFlags(a1)
                beq.w   .loc_13B6C
                move.w  RaceActor_Curve(a1),d0
                neg.w   d0
                mulu.w  #$60,d0
                swap    d0
                sub.w   d0,d1
                bra.w   .loc_13B6C
.loc_13B68:
                move.w  #$FFFB,d1
.loc_13B6C:
                btst    #3,RaceActor_ControlFlags(a1)
                beq.w   .loc_13B84
                tst.w   d1
                bmi.w   .loc_13B8A
                move.w  RaceActor_Speed(a1),d2
                lsr.w   #8,d2
                sub.w   d2,d1
.loc_13B84:
                tst.w   d1
                bpl.w   .loc_13BB6
.loc_13B8A:
                move.w  RaceActor_Type(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a0
                movea.l (a0,d0.w),a0
                move.w  RaceActor_Speed(a1),d0
                move.w  RaceActor_Gear(a1),d2
                beq.w   .loc_13BB6
                asl.w   #1,d2
                cmp.w   $1A(a0,d2.w),d0
                bcc.w   .loc_13BB6
                subi.w  #1,RaceActor_Gear(a1)
.loc_13BB6:
                move.w  d1,RaceActor_Acceleration(a1)
.locret_13BBA:
                rts
; End of function Race_UpdateActorSpeedState

; *************************************************
; Function sub_13BBC
; a1 - actor
; *************************************************

sub_13BBC:
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_13BCE
                move.w  #-64,d1
                bra.w   .loc_13BD2
.loc_13BCE:
                move.w  #-5,d1
.loc_13BD2:
                move.w  d1,RaceActor_Acceleration(a1)
                rts
; End of function sub_13BBC


; =============== S U B R O U T I N E =======================================


sub_13BD8:
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_13BEA
                move.w  #$FFD0,d1
                bra.w   .loc_13BEE


.loc_13BEA:
                move.w  #$FFFB,d1

.loc_13BEE:
                move.w  d1,$14(a1)
                rts
; End of function sub_13BD8


; =============== S U B R O U T I N E =======================================


sub_13BF4:
                lea     (ram_FF1F2A).l,a1
                move.w  (ram_FF1B32).l,d0
                beq.w   .loc_13C1C
                sub.w   (Race_ram_FrameDelay).l,d0
                move.w  d0,(ram_FF1B32).l
                bgt.w   .loc_13C88
                move.w  #0,(ram_FF1B32).l

.loc_13C1C:
                btst    #6,RaceActor_ControlFlags(a1)
                bne.w   .locret_13CFC
                move.w  RaceActor_Rating(a1),d0
                move.w  (Race_ram_ActorDistanceScale).l,d1
                sub.w   (ram_FF1B34).l,d1
                bmi.w   .loc_13C88
                mulu.w  d1,d0
                move.l  d0,(ram_FF1B3A).l
                move.l  (Race_ram_PlayerProgress).l,d1
                subi.l  #$100000,d1
                bpl.w   .loc_13C54
                moveq   #0,d1

.loc_13C54:
                cmp.l   d1,d0
                bmi.w   .loc_13C88
                tst.w   (ram_FF1B36).l
                bne.w   .loc_13C88
                move.w  #1,(ram_FF1B36).l
                move.l  d1,4(a1)
                move.w  #$1F40,$12(a1)
                move.w  (Menu_ram_PlayerLevel).l,(Race_ram_LevelIndex).l
                bsr.w   sub_13CFE
                bra.w   .locret_13CFC


.loc_13C88:
                movea.l (ram_FFDBD4).l,a2
                move.l  (a2),d0
                cmp.l   #$FFFFFFFF,d0
                beq.w   .locret_13CFC
                move.l  d0,d1
                clr.w   d0
                sub.l   (RacePlayerA + RaceActor_X).l,d0
                cmp.l   #$200000,d0
                bpl.w   .locret_13CFC
                addi.l  #4,(ram_FFDBD4).l
                btst    #6,RaceActor_ControlFlags(a1)
                bne.w   .locret_13CFC
                move.w  d1,d2
                lsr.w   #8,d2
                move.w  d2,(Race_ram_LevelIndex).l
                move.l  d1,d0
                clr.w   d0
                move.l  d0,4(a1)
                andi.w  #$F,d1
                asl.w   #5,d1
                subi.w  #$100,d1
                move.w  d1,$30(a1)
                move.w  (RacePlayerA + RaceActor_Speed).l,d0
                cmp.w   #$2710,d0
                bmi.w   .loc_13CF4
                move.w  #$2710,d0

.loc_13CF4:
                move.w  d0,$12(a1)
                bsr.w   sub_13CFE

.locret_13CFC:
                rts
; End of function sub_13BF4


; =============== S U B R O U T I N E =======================================


sub_13CFE:
                bsr.w   Race_ActivateActor
                bsr.w   Race_SetupActor
                bsr.w   Race_GetCurveSpeedLimit
                cmp.w   $12(a1),d0
                bpl.w   .loc_13D16
                move.w  d0,$12(a1)

.loc_13D16:
                move.w  (Race_ram_LevelIndex).l,d0
                addq.w  #4,d0
                move.b  d0,$75(a1)
                lea     (Race_ActorLevelBase).l,a2
                subq.w  #5,d0
                asl.w   #1,d0
                move.w  (a2,d0.w),d0
                lea     (Race_ActorDefinitionTable).l,a2
                asl.w   #4,d0
                move.b  (a2,d0.w),d0
                ext.w   d0
                move.w  d0,$16(a1)
                rts
; End of function sub_13CFE


                dc.b $48 ; H
                dc.b $E7
                dc.b $E0
                dc.b $E0
                dc.b $20
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $D7
                dc.b $CC
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A4
                dc.b $22 ; "
                dc.b $10
                dc.b $B2
                dc.b $BC
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $7A ; z
                dc.b $42 ; B
                dc.b $41 ; A
                dc.b $24 ; $
                dc.b   1
                dc.b $94
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b $6E ; n
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $58 ; X
                dc.b $88
                dc.b $B4
                dc.b $BC
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b   0
                dc.b $64 ; d
                dc.b   0
                dc.b   0
                dc.b $62 ; b
                dc.b $42 ; B
                dc.b $40 ; @
                dc.b $10
                dc.b $28 ; (
                dc.b   0
                dc.b   2
                dc.b $45 ; E
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $47 ; G
                dc.b $64 ; d
                dc.b $E7
                dc.b $40 ; @
                dc.b $D4
                dc.b $C0
                dc.b $4A ; J
                dc.b $6A ; j
                dc.b   0
                dc.b   6
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $1A
                dc.b $32 ; 2
                dc.b $28 ; (
                dc.b   0
                dc.b   2
                dc.b   2
                dc.b $41 ; A
                dc.b   0
                dc.b  $F
                dc.b $EB
                dc.b $41 ; A
                dc.b   4
                dc.b $41 ; A
                dc.b   1
                dc.b   0
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $30 ; 0
                dc.b $B1
                dc.b $41 ; A
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $58 ; X
                dc.b $48 ; H
                dc.b $60 ; `
                dc.b $A8
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $26 ; &
                dc.b $84
                dc.b $C0
                dc.b $33 ; 3
                dc.b $C2
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $46 ; F
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b   0
                dc.b   2
                dc.b $4A ; J
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $54 ; T
                dc.b $40 ; @
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $38 ; 8
                dc.b $92
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A4
                dc.b $4C ; L
                dc.b $DF
                dc.b   7
                dc.b   7
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_13DE0:
                movem.l d0-d2/a0-a2,-(sp)
                movea.l (Race_ram_TrackObjectRecordCursor).l,a0
                move.w  #0,(ram_FF18A4).l

.loc_13DF2:
                move.l  (a0),d1
                cmp.l   #$FFFFFFFF,d1
                beq.w   .loc_13E8E
                clr.w   d1
                move.l  d1,d2
                sub.l   4(a1),d2
                btst    #3,RaceActor_StateFlags(a1)
                beq.w   .loc_13E12
                neg.l   d2

.loc_13E12:
                tst.l   d2
                bgt.w   .loc_13E1A
                addq.l  #4,a0

.loc_13E1A:
                cmp.l   #$1E0000,d2
                bcc.w   .loc_13E8E
                subi.l  #$10000,d2
                clr.w   d0
                move.b  2(a0),d0
                lea     (Race_TrackObjectTypeTable).l,a2
                asl.w   #3,d0
                adda.w  d0,a2
                tst.w   6(a2)
                beq.w   .loc_13E5A
                move.w  2(a0),d1
                andi.w  #$F,d1
                asl.w   #5,d1
                subi.w  #$100,d1
                move.w  $30(a1),d0
                eor.w   d0,d1
                bpl.w   .loc_13E5E

.loc_13E5A:
                addq.w  #4,a0
                bra.s   .loc_13DF2


.loc_13E5E:
                clr.l   d0
                move.w  $12(a1),d0
                beq.w   .loc_13E8E
                tst.w   d2
                bmi.w   .loc_13E88
                divu.w  d0,d2
                bvs.w   .loc_13E8E
                beq.w   .loc_13E88
                divu.w  d2,d0
                mulu.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,$12(a1)
                bra.w   .loc_13E8E


.loc_13E88:
                move.w  #0,$12(a1)

.loc_13E8E:
                movem.l (sp)+,d0-d2/a0-a2
                rts
; End of function sub_13DE0


; =============== S U B R O U T I N E =======================================


sub_13E94:
                lea     (RacePlayerA).l,a1
                bsr.w   Race_GetCurveSpeedLimit
                rts
; End of function sub_13E94

; *************************************************
; Function Race_UpdateBikeLean
; a1 - actor
; *************************************************
 ; *************************************************
; Function Race_UpdateBikeLean
; Computes the bike lean ($42) from Speed/Steering physics values.
; In:  a1 - actor; RaceBike_ram_CurrentSteering; ram_FF1AA6/AAA/B4
; Out: actor $42
; Clobbers: d0-d3
; *************************************************

Race_UpdateBikeLean:
                tst.b   RaceActor_AnimState(a1)
                bpl.w   .return
                move.w  RaceActor_Speed(a1),d2
                beq.w   .loc_13EF2
                mulu.w  (ram_FF1AB4).l,d2
                lsr.l   #8,d2
                move.w  (ram_FF1AA6).l,d1
                lsr.w   #3,d1
                move.w  (RaceBike_ram_CurrentSteering).l,d3
                move.w  d3,d0
                bpl.w   .loc_13ECE
                neg.w   d0
.loc_13ECE:
                ext.l   d0
                divu.w  d1,d0
                beq.w   .loc_13EF2
                swap    d0
                divu.w  d2,d0
                mulu.w  (ram_FF1AAA).l,d0
                swap    d0
                tst.w   d3
                bpl.w   .loc_13EEA
                neg.w   d0
.loc_13EEA:
                move.w  d0,RaceActor_Lean(a1)
                bra.w   .return
.loc_13EF2:
                move.w  #0,RaceActor_Lean(a1)
.return:
                rts
; End of function Race_UpdateBikeLean


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_UpdateBikeCurve
; Derives the bike curve/lean flags and $3E/$40 from speed/curve values.
; In:  a1 - actor; Race_ram_TrackParam0/3032/3034/word_14742
; Out: actor $3E/$40/$68 bits
; Clobbers: d0-d2
; *************************************************

Race_UpdateBikeCurve:
                movem.l d0-d1,-(sp)
                btst    #0,RaceActor_ControlFlags(a1)
                bne.w   .loc_13FE0
                move.w  $12(a1),d1
                beq.w   .loc_13FCE
                mulu.w  (ram_FF1AB2).l,d1
                lsr.l   #8,d1
                move.w  8(a1),d0
                beq.w   .loc_13FCE
                bpl.w   .loc_13F26
                neg.w   d0

.loc_13F26:
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_13F3A
                cmpa.l  #RacePlayerA,a1
                beq.w   .loc_13F40

.loc_13F3A:
                mulu.w  #$200,d0
                lsr.l   #8,d0

.loc_13F40:
                mulu.w  d1,d0
                lsr.l   #3,d0
                clr.l   d1
                move.b  $78(a1),d2
                beq.w   .loc_13F6E
                andi.w  #$FF,d2
                sub.w   (Race_ram_FrameDelay).l,d2
                bcc.w   .loc_13F60
                move.w  #0,d2

.loc_13F60:
                move.b  d2,$78(a1)
                move.w  (word_14742).l,d1
                bra.w   .loc_13FB0


.loc_13F6E:
                btst    #5,RaceActor_ControlFlags(a1)
                beq.w   .loc_13F96
                btst    #3,RaceActor_ControlFlags(a1)
                beq.w   .loc_13F8C
                move.w  (Race_ram_TrackParam3).l,d1
                bra.w   .loc_13FB0


.loc_13F8C:
                move.w  (Race_ram_TrackParam0).l,d1
                bra.w   .loc_13FB0


.loc_13F96:
                btst    #3,RaceActor_ControlFlags(a1)
                beq.w   .loc_13FAA
                move.w  (Race_ram_TrackParam2).l,d1
                bra.w   .loc_13FB0


.loc_13FAA:
                move.w  (Race_ram_TrackParam0).l,d1

.loc_13FB0:
                cmp.l   d1,d0
                bcs.w   .loc_13FCE
                lsr.l   #8,d0
                beq.w   .loc_13FC0
                asl.l   #8,d1
                divu.w  d0,d1

.loc_13FC0:
                move.w  d1,RaceActor_Curve(a1)
                bset    #5,RaceActor_ControlFlags(a1)
                bra.w   .loc_13FE0


.loc_13FCE:
                bclr    #5,RaceActor_ControlFlags(a1)
                move.w  #0,RaceActor_LeanCurve(a1)
                move.w  #0,RaceActor_Curve(a1)

.loc_13FE0:
                movem.l (sp)+,d0-d1
                rts
; End of function Race_UpdateBikeCurve


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_GetCurveSpeedLimit
; Returns the curve speed limit from Track_CurveBuffer and the actor graphics data.
; In:  a1 - actor; Track_CurveBuffer; unk_14056
; Out: d0 - speed limit ($7FFF = none)
; Clobbers: d0-d2/a0/a2
; *************************************************

Race_GetCurveSpeedLimit:
                movem.l d1-d2/a0-a2,-(sp)
                clr.l   d0
                btst    #3,RaceActor_ControlFlags(a1)
                beq.w   .loc_14000
                move.w  (Race_ram_TrackParam2).l,d0
                bra.w   .loc_14006


.loc_14000:
                move.w  (Race_ram_TrackParam0).l,d0

.loc_14006:
                asl.l   #3,d0
                lea     (Track_CurveBuffer).l,a0
                move.w  4(a1),d1
                addq.w  #6,d1
                andi.w  #$FF,d1
                asl.w   #1,d1
                move.w  (a0,d1.w),d1
                ext.w   d1
                bpl.w   .loc_14026
                neg.w   d1

.loc_14026:
                tst.w   d1
                beq.w   .loc_1404C
                lea     (unk_14056).l,a2
                move.b  $75(a1),d2
                ext.w   d2
                asl.w   #1,d2
                move.w  (a2,d2.w),d2
                mulu.w  d2,d1
                lsr.l   #8,d1
                divu.w  d1,d0
                bvs.w   .loc_1404C
                bpl.w   .loc_14050

.loc_1404C:
                move.w  #$7FFF,d0

.loc_14050:
                movem.l (sp)+,d1-d2/a0-a2
                rts
; End of function Race_GetCurveSpeedLimit



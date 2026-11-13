; *************************************************
; race_anim_audio.asm - animations, engine audio, impact helpers
; ROM range: $14056-$1685F (animation.asm starts at $16860)
; PRNG/LFSR helpers are in rand.asm, included at their original ROM location.
; *************************************************

; 10-word multiplier table indexed by RaceActor_GraphicsIndex*2 in
; Race_GetCurveSpeedLimit (race_ai.asm).
unk_14056:
                dc.w    $0138, $0130, $0128, $0120, $0110, $0160, $0150, $0140
                dc.w    $0130, $0120





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


; *************************************************
; Function sub_140BC (proposed: Race_UpdateActorXFromTrackObject)
; Sets X/PreviousX from ($E(a0)<<8)+PlayerProgress, subtracting $A000 when
; StateFlags bit3 is set, otherwise adding $4000.
; In:  a0 - track object/actor; a1 - actor; Out: X, PreviousX; Clobbers: d0
; *************************************************

sub_140BC:
                clr.l d0
                move.w $E(a0),d0
                asl.l #$8,d0
                add.l (Race_ram_PlayerProgress).l,d0
                btst.b #$3,RaceActor_StateFlags(a1)
                beq.w .loc_140DE
                subi.l #$A000,d0
                bra.w .loc_140E4
.loc_140DE:
                addi.l #$4000,d0
.loc_140E4:
                move.l d0,RaceActor_X(a1)
                move.l d0,RaceActor_PreviousX(a1)
                rts
; End of function sub_140BC

; *************************************************
; Function sub_140EE (proposed: Race_ApplyActorCrash)
; Main crash handler for on-road actors: at Speed < $FA0 it only calls
; sub_142FE (road-Y clamp); otherwise it updates X from the track object,
; scales the actor shadow speed, selects a fall SFX from $34/steering, sets
; AnimState/AnimFrame and applies BikeDamage (player) or ram_FF1AD6=$F (opponent).
; In:  a1 - actor; a0 - track object/actor; Out: ControlFlags bit4, $6E/$6F, X, damage
; *************************************************

sub_140EE:
                cmpi.w #$FA0,RaceActor_Speed(a1)
                bpl.w .loc_14100
                bsr.w sub_142FE
                bra.w .loc_141A6
.loc_14100:
                bsr.s sub_140BC
                bsr.w sub_1438E
                move.w $34(a1),d0
                bpl.w .loc_14110
                neg.w d0
.loc_14110:
                cmp.w #$3,d0
                bmi.w .loc_14122
                jsr (sub_15538).l
                bra.w .loc_14144
.loc_14122:
                move.w RaceActor_Speed(a1),d0
                move.w d0,(ram_FF18A6).l
                cmp.w #$1770,d0
                bpl.w .loc_1413E
                jsr (sub_15580).l
                bra.w .loc_14144
.loc_1413E:
                jsr (sub_1555C).l
.loc_14144:
                move.b #$0,RaceActor_AnimState(a1)
                move.b #$FF,RaceActor_AnimFrame(a1)
                tst.w (Race_ram_CrashAnimActive).l
                bne.w .loc_14194
                jsr (sub_142D8).l
                bsr.w Race_SaveActorShadow
                move.w #$C000,d0
                bsr.w sub_1436E
                cmpa.l #$FF1EAA,a1
                bne.w .loc_141A6
                move.b #$9,(ram_FF1AD6).l
                move.w (ram_FF18A6).l,d0
                bsr.w Race_ScaleImpactDamage
                lsr.w #$1,d0
                add.w d0,(Race_ram_BikeDamage).l
                bra.w .loc_141A6
.loc_14194:
                cmpa.l #$FF1EAA,a1
                bne.w .loc_141A6
                move.b #$F,(ram_FF1AD6).l
.loc_141A6:
                bset.b #$4,RaceActor_ControlFlags(a1)
                rts
; End of function sub_140EE

; *************************************************
; Function sub_141AE (proposed: Race_ApplyActorHighSpeedCrash)
; High-speed/off-road crash: falls back to sub_142FE when StateFlags bit3 is
; set or Speed < $FA0; otherwise clamps Speed to $2710, shifts X by $6000
; relative to the track object, sets ControlFlags bit4/StateFlags bit3,
; selects FallState $9/$5 and applies the same damage/SFX path as sub_140EE.
; *************************************************

sub_141AE:
                btst.b #$3,RaceActor_StateFlags(a1)
                bne.w .loc_141C4
                move.w RaceActor_Speed(a1),d0
                cmp.w #$FA0,d0
                bpl.w .loc_141CC
.loc_141C4:
                bsr.w sub_142FE
                bra.w .loc_142AE
.loc_141CC:
                move.w d0,(ram_FF18A6).l
                mulu.w #$4000,d0
                swap d0
                cmp.w #$2710,d0
                blt.w .loc_141E4
                move.w #$2710,d0
.loc_141E4:
                move.w d0,RaceActor_Speed(a1)
                move.l #$6000,d0
                sub.w $E(a0),d1
                ext.l d1
                asl.l #$8,d1
                bmi.w .loc_141FC
                neg.l d0
.loc_141FC:
                add.l RaceActor_X(a1),d0
                sub.l d1,d0
                move.l d0,RaceActor_X(a1)
                bsr.w sub_1438E
                bset.b #$4,RaceActor_ControlFlags(a1)
                bset.b #$3,RaceActor_StateFlags(a1)
                move.w $34(a1),d0
                bpl.w .loc_14220
                neg.w d0
.loc_14220:
                cmp.w #$3,d0
                bmi.w .loc_14232
                jsr (sub_15538).l
                bra.w .loc_1424E
.loc_14232:
                cmpi.w #$1F40,(ram_FF18A6).l
                bmi.w .loc_14248
                move.w #$9,RaceActor_FallState(a1)
                bra.w .loc_1424E
.loc_14248:
                move.w #$5,RaceActor_FallState(a1)
.loc_1424E:
                move.b #$0,RaceActor_AnimState(a1)
                move.b #$FF,RaceActor_AnimFrame(a1)
                tst.w (Race_ram_CrashAnimActive).l
                bne.w .loc_1429C
                jsr (sub_142D8).l
                bsr.w Race_SaveActorShadow
                move.w #$C000,d0
                bsr.w sub_1436E
                cmpa.l #$FF1EAA,a1
                bne.w .loc_142AE
                move.b #$9,(ram_FF1AD6).l
                move.w (ram_FF18A6).l,d0
                bsr.w Race_ScaleImpactDamage
                add.w d0,(Race_ram_BikeDamage).l
                bra.w .loc_142AE
.loc_1429C:
                cmpa.l #$FF1EAA,a1
                bne.w .loc_142AE
                move.b #$F,(ram_FF1AD6).l
.loc_142AE:
                rts
; End of function sub_141AE

; *************************************************
; Function sub_142B0 (proposed: Race_ApplyCrash0F)
; Calls sub_140EE and sets ram_FF1AD6=$F.
; *************************************************

sub_142B0:
                bsr.w sub_140EE
                move.b #$F,(ram_FF1AD6).l
                rts
; End of function sub_142B0

; *************************************************
; Function sub_142BE (proposed: Race_ApplyCrash17)
; Calls sub_140EE and sets ram_FF1AD6=$17.
; *************************************************

sub_142BE:
                bsr.w sub_140EE
                move.b #$17,(ram_FF1AD6).l
                rts
; End of function sub_142BE

; *************************************************
; Function sub_142CC (proposed: Race_ApplyCrashWithAttackFlag)
; Sets AttackFlags bit1, then jumps to sub_140EE.
; *************************************************

sub_142CC:
                bset.b #$1,RaceActor_AttackFlags(a1)
                jmp (sub_140EE).l
; End of function sub_142CC





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


; *************************************************
; Function sub_142FE (proposed: Race_UpdateActorRoadY)
; Sets PosY/$1A to ram_FF1B14 adjusted by CollisionExtentUpper/Lower (+/-4),
; applies the PosY delta to word $0, and when FrameDistance is zero shifts
; X/PreviousX back by $4000.
; In:  a1 - actor; Out: PosY/$1A, X/PreviousX, word $0; Clobbers: d0/d1
; *************************************************

sub_142FE:
                move.w (ram_FF1B14).l,d0
                btst.b #$1,RaceActor_StateFlags(a1)
                bne.w .loc_14318
                sub.w RaceActor_CollisionExtentLower(a1),d0
                subq.w #$4,d0
                bra.w .loc_1431E
.loc_14318:
                add.w RaceActor_CollisionExtentUpper(a1),d0
                addq.w #$4,d0
.loc_1431E:
                move.w d0,d1
                sub.w RaceActor_PosY(a1),d1
                add.w d1,0.w(a1)
                move.w d0,RaceActor_PosY(a1)
                move.w d0,$1A(a1)
                tst.l RaceActor_FrameDistance(a1)
                bne.w .loc_14348
                subi.l #$4000,RaceActor_X(a1)
                subi.l #$4000,RaceActor_PreviousX(a1)
.loc_14348:
                rts
; End of function sub_142FE





Race_ScaleImpactDamage:
                tst.w   (Race_ram_CrashAnimActive).l
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


; *************************************************
; Function sub_1436E (proposed: Race_ScaleActorShadowSpeed)
; Multiplies the shadow actor Speed by d0 (unsigned 16.16; d0=$C000 from the
; crash handlers) and stores the result.
; In:  a1 - actor; d0 - scale; Out: shadow Speed; Clobbers: d2/a4
; *************************************************

sub_1436E:
                lea (Race_ActorShadowTable).l,a4
                move.b RaceActor_Index(a1),d2
                ext.w d2
                asl.w #$2,d2
                movea.l (a4,d2.w),a4
                move.w RaceActor_Speed(a4),d2
                mulu.w d0,d2
                swap d2
                move.w d2,RaceActor_Speed(a4)
                rts
; End of function sub_1436E





sub_1438E:
                move.w  $12(a1),d0
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_143D4
                cmp.w   #$3E8,d0
                bmi.w   .loc_143D4
                tst.w   (Race_ram_CrashAnimActive).l
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


; *************************************************
; Function sub_14404 (proposed: Race_HandleActorCollisionImpact)
; Calls sub_1438E. When Race_ram_CrashAnimActive is clear, clears AnimFrame. Otherwise, unless
; AnimState is 3, resets FallState/AnimState/AnimFrame, sets ram_FF1AD6=$F and,
; when Speed is zero, calls sub_140BC. Clears ControlFlags bit4 on the other path.
; In:  a1 - actor; Out: as above; Clobbers: d0
; *************************************************

sub_14404:
                bsr.s sub_1438E
                tst.w (Race_ram_CrashAnimActive).l
                bne.w .loc_1441A
                move.b #$FF,RaceActor_AnimState(a1)
                bra.w .loc_1444E
.loc_1441A:
                cmpi.b #$3,RaceActor_AnimState(a1)
                beq.w .loc_1444E
                move.w #$0,RaceActor_FallState(a1)
                move.b #$0,RaceActor_AnimState(a1)
                move.b #$FF,RaceActor_AnimFrame(a1)
                move.b #$F,(ram_FF1AD6).l
                tst.w RaceActor_Speed(a1)
                bne.w .loc_14454
                bsr.w sub_140BC
                bra.w .loc_14454
.loc_1444E:
                bclr.b #$4,RaceActor_ControlFlags(a1)
.loc_14454:
                rts
; End of function sub_14404

; *************************************************
; Function sub_14456 (proposed: Race_SetActorFallShort)
; If AnimState < 3, sets ControlFlags bit5 and AnimTimer=$78.
; *************************************************

sub_14456:
                cmpi.b #$3,RaceActor_AnimState(a1)
                bpl.w .loc_1446C
                bset.b #$5,RaceActor_ControlFlags(a1)
                move.b #$78,STRUCT_OFFSET_78(a1)
.loc_1446C:
                rts
; End of function sub_14456

; *************************************************
; Function sub_1446E (proposed: Race_SetActorFallLong)
; If AnimState < 3, sets ControlFlags bit5 and AnimTimer=$1E.
; *************************************************

sub_1446E:
                cmpi.b #$3,RaceActor_AnimState(a1)
                bpl.w .loc_14484
                bset.b #$5,RaceActor_ControlFlags(a1)
                move.b #$1E,STRUCT_OFFSET_78(a1)
.loc_14484:
                rts
; End of function sub_1446E





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


; 5 tracks x 4 words, loaded by Race_LoadTrackParams into
; Race_ram_TrackParam0..3. Track 3 has different Param2/3 values.
unk_1471A:
                dc.w    $E646, $AB6D, $B31A, $6658 ; track 0: TrackParam0..3
                dc.w    $E646, $AB6D, $B31A, $6658 ; track 1: TrackParam0..3
                dc.w    $E646, $AB6D, $B31A, $6658 ; track 2: TrackParam0..3
                dc.w    $E646, $AB6D, $9984, $4CC2 ; track 3: TrackParam0..3
                dc.w    $E646, $AB6D, $B31A, $6658 ; track 4: TrackParam0..3

word_14742:     dc.w $4CC2
; 8 action handlers indexed by unk_147FC[]; sub_12070 dispatches to them.
unk_14744:
                dc.l    sub_140EE
                dc.l    sub_14404
                dc.l    sub_141AE
                dc.l    sub_14456
                dc.l    sub_1446E
                dc.l    sub_142CC
                dc.l    sub_142B0
                dc.l    sub_142BE

; 19 records x 8 bytes: +0 render flags, +1 unused, +2 size 16.8, +4 action-handler
; index, +6 word (+7 = steerable flag). sub_13D44/sub_13DE0/sub_12070 consume it.
Race_TrackObjectTypeTable:
                dc.b    0, 0, $01, 0, 0, $03, 0, 0
                dc.b    0, $01, $01, 0, 0, $04, 0, 0
                dc.b    0, $01, $01, 0, 0, $04, 0, 0
                dc.b    0, 0, $01, $80, 0, 0, 0, $01
                dc.b    0, $01, $02, 0, 0, 0, 0, $01
                dc.b    0, $01, $02, 0, 0, 0, 0, 0
                dc.b    0, 0, $01, $80, 0, $02, 0, $01
                dc.b    0, $02, $01, $80, 0, $02, 0, $01
                dc.b    0, $01, $01, 0, 0, $01, 0, 0
                dc.b    0, $01, $02, 0, 0, $01, 0, 0
                dc.b    0, $01, $01, $80, 0, $07, 0, $01
                dc.b    0, $01, $01, $80, 0, $01, 0, $01
                dc.b    0, $01, $01, $80, 0, $07, 0, $01
                dc.b    0, $01, $01, $80, 0, $07, 0, $01
                dc.b    0, $01, $01, $80, 0, $07, 0, $01
                dc.b    0, $01, $02, 0, 0, $01, 0, 0
                dc.b    0, $01, $01, 0, 0, $04, 0, 0
                dc.b    0, $01, $01, 0, 0, $01, 0, 0
                dc.b    0, $01, $01, 0, 0, $01, 0, 0

; 128-byte action-handler index table; each byte indexes unk_14744.
; sub_12070 clamps the derived value to 0..127 before reading it.
unk_147FC:
                dc.b    0, $02, $02, $02, $02, 0, 0, 0, 0, $02, $02, $02, $02, $02, $02, $02
                dc.b    0, 0, 0, 0, 0, $02, $02, $02, $01, $07, $07, $07, $01, $01, $01, $01
                dc.b    $01, 0, $01, $01, $01, $01, 0, 0, 0, 0, $01, $01, $01, $01, 0, 0
                dc.b    $01, $01, $01, $01, 0, 0, 0, 0, $02, $02, $02, $02, $02, $02, $02, $02
                dc.b    $02, $02, $02, $02, $02, $02, 0, $02, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                dc.b    0, 0, 0, 0, 0, 0, 0, 0, 0, $06, $06, $06, $06, $06, $06, 0





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
; U-0004: player A attacked Natasha (actor index match) -> latch the encounter flag
                move.w  #3,(Player_ram_NatashaCounter).l

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
                mulu.w  (Race_ram_StaminaHitScale).l,d0
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
                mulu.w  (Race_ram_StaminaHitScale).l,d0
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


; *************************************************
; Function sub_14DEC (proposed: Race_GetActorFrameDistanceDelta)
; Returns d0=0 (both signed Speed terms read $12(a1), so their difference is
; always zero) and d1=(FrameDistance(a1)-FrameDistance(a2))/FrameDelay.
; In:  a1/a2 - actors; Out: d0=0, d1; Clobbers: d0-d2
; d0 is always 0 (both terms read $12(a1); the second was likely meant to be a2)
; and there is no caller/pointer reference in the ROM, so this is vestigial [static].
; *************************************************

sub_14DEC:
                move.w RaceActor_Speed(a1),d0
                btst.b #$3,RaceActor_ControlFlags(a1)
                beq.w .loc_14DFC
                neg.w d0
.loc_14DFC:
                move.w RaceActor_Speed(a1),d1
                btst.b #$3,RaceActor_ControlFlags(a1)
                beq.w .loc_14E0C
                neg.w d1
.loc_14E0C:
                sub.w d1,d0
                asr.w #$8,d0
                move.w (Race_ram_FrameDelay).l,d2
                beq.w .loc_14E2E
                move.w STRUCT_OFFSET_22(a1),d1
                sub.w STRUCT_OFFSET_22(a2),d1
                beq.w .loc_14E2A
                ext.l d1
                divs.w d2,d1
.loc_14E2A:
                bra.w .loc_14E36
.loc_14E2E:
                move.w #$0,d0
                move.w #$1,d1
.loc_14E36:
                rts
; End of function sub_14DEC





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

; Dead code inside sub_15446: the preceding bra.w .loc_1546E skips this block
; and no branch targets $15458 (static). Kept byte-exact.
                tst.w RaceActor_Speed(a2)
                bne.w .loc_1546E
                bne.w .loc_1546E
                move.b #$2,d0



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
                jsr     (Rand_NextWord).l
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
                jsr     (Rand_NextWord).l
                andi.w  #7,d0
                lea     (unk_15624).l,a4
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,RaceActor_FallState(a1)
                movem.l (sp)+,d0/a4
                rts
; End of function sub_1555C


; *************************************************
; Function sub_15580 (proposed: Race_SetRandomFallState)
; Picks FallState from the 8-entry unk_1561C table using Rand_NextWord & 7.
; In:  a1 - actor; Out: FallState; Clobbers: d0/a4
; *************************************************

sub_15580:
                movem.l d0/a4,-(sp)
                jsr (Rand_NextWord).l
                andi.w #$7,d0
                lea (unk_1561C).l,a4
                move.b (a4,d0.w),d0
                ext.w d0
                move.w d0,RaceActor_FallState(a1)
                movem.l (sp)+,d0/a4
                rts
; End of function sub_15580

; Pointer list used by sub_15478; the target unk_155AC is loaded into a0 but
; a0 is not read before the loop (vestigial) [static].
unk_155A4:
                dc.l    unk_155AC
                dc.l    $FFFFFFFF

; sub_154D2 reads a 3-byte header, then 8 records of 4 bytes (stride 4 from
; +3) plus an $FF sentinel: field +3 is added to d0, +4/+5/+6 go to d3/d5/d6.
unk_155AC:
                dc.b    $01, $5E, $08 ; header
                dc.b    0, 0, 0, 0 ; record 0
                dc.b    $01, 0, 0, 0 ; record 1
                dc.b    $02, 0, 0, 0 ; record 2
                dc.b    $03, 0, 0, 0 ; record 3
                dc.b    $04, 0, 0, 0 ; record 4
                dc.b    $05, 0, 0, 0 ; record 5
                dc.b    $06, 0, 0, 0 ; record 6
                dc.b    $07, 0, 0, 0 ; record 7
                dc.b    $FF ; sentinel

; 18 animation-sequence pointers for FallState 0..$11 (clamped in sub_151F0).
unk_155D0:
                dc.l    $00015760 ; FallState 0
                dc.l    $0001578C ; FallState 1
                dc.l    $000157B8 ; FallState 2
                dc.l    $000157E4 ; FallState 3
                dc.l    $00015810 ; FallState 4
                dc.l    $0001583C ; FallState 5
                dc.l    $00015868 ; FallState 6
                dc.l    $00015894 ; FallState 7
                dc.l    $000158C0 ; FallState 8
                dc.l    $000158EC ; FallState 9
                dc.l    $0001562C ; FallState 10
                dc.l    $00015658 ; FallState 11
                dc.l    $00015684 ; FallState 12
                dc.l    $000156B0 ; FallState 13
                dc.l    $000156DC ; FallState 14
                dc.l    $00015708 ; FallState 15
                dc.l    $00015734 ; FallState 16
                dc.l    $00015918 ; FallState 17

; Random FallState tables: unk_15618 (4 entries), unk_1561C (8), unk_15624 (8).
unk_15618:
                dc.b    $06, $0A, $0B, $0C ; sub_15538: rand & 3

unk_1561C:
                dc.b    $07, $0A, $02, $03, $0D, $0B, $0E, $07 ; sub_15580: rand & 7

unk_15624:
                dc.b    0, $03, $0E, $0F, $10, $0C, $07, $08 ; sub_1555C: rand & 7

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
    include "rand.asm"





 ; *************************************************
; Function Race_UpdatePlayerAnimation
; Advances player stamina $5C toward Race_ram_PlayerStaminaMax by the frame delay.
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
                cmp.w   (Race_ram_PlayerStaminaMax).l,d0
                bcs.w   .loc_16114
                move.w  (Race_ram_PlayerStaminaMax).l,d0

.loc_16114:
                move.w  d0,$5C(a1)

.locret_16118:
                rts
; End of function Race_UpdatePlayerAnimation

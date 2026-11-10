; *************************************************
; race_combat.asm - player fist attack, AI combat actions and collision state
; ROM range: $1611A-$1685F; included from race.asm after race_anim_audio.asm.
; *************************************************

; *************************************************
; Function Race_UpdateNearestTarget
; Finds the nearest actor by squared X/Y distance and stores the target state.
; In:  ram_FF1A08 actor list; player A
; Out: ram_FF1904/1908/1AA4/1786; attack state $69/$6B/$6C/$6D/ram_FF1B22
; Clobbers: d0-d5/a0-a3
; *************************************************

Race_UpdateNearestTarget:
                move.w  #0,(ram_FF1904).l
                lea     (ram_FF1A08).l,a0
                movea.l (a0)+,a1
                move.l  4(a1),d0
                move.w  $30(a1),d2
                move.l  (a0),-(sp)
                move.l  #$7FFFFFFF,d4

.loc_1613A:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_16176
                move.l  d0,d1
                sub.l   4(a2),d1
                bpl.w   .loc_16152
                neg.l   d1
.loc_16152:
                lsr.l   #8,d1
                move.l  d1,d3
                mulu.w  d3,d1
                clr.l   d3
                move.w  d2,d3
                sub.w   $30(a2),d3
                bpl.w   .loc_16166
                neg.w   d3
.loc_16166:
                move.w  d3,d5
                mulu.w  d5,d3
                add.l   d3,d1
                cmp.l   d4,d1
                bcc.s   .loc_1613A
                move.l  d1,d4
                move.l  a2,(sp)
                bra.s   .loc_1613A


.loc_16176:
                movea.l (sp)+,a2
                move.l  a2,(Race_ram_NearestActor).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_161BE
                move.w  $16(a2),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a3
                movea.l (a3,d0.w),a3
                move.w  $18(a2),d1
                asl.w   #1,d1
                move.w  $E(a3,d1.w),d1
                ext.l   d1
                swap    d1
                lsr.l   #8,d1
                lsr.l   #6,d1
                move.w  d1,(Race_ram_NearestRpmDivisor).l
                move.l  4(a2),d0
                sub.l   4(a1),d0
                move.l  d0,(ram_FF1786).l

.loc_161BE:
                tst.w   (ram_FF1ACC).l
                beq.w   .loc_161D2
                jsr     (sub_14FB4).l
                bra.w   .locret_162AE


.loc_161D2:
                tst.b   (ram_FF1B22).l
                beq.w   .loc_162AA
                btst    #5,(Race_ram_CurrentButtons).l
                beq.w   .loc_1621E
                btst    #6,$69(a1)
                bne.w   .loc_161FC
                btst    #0,$6B(a1)
                beq.w   .loc_1621E

.loc_161FC:
                move.w  (Race_ram_FrameDelay).l,d0
                sub.b   d0,$6D(a1)
                bgt.w   .locret_162AE
                cmpi.b  #0,$6C(a1)
                bne.w   .loc_1622C
                move.b  #0,$6D(a1)
                bra.w   .locret_162AE


.loc_1621E:
                move.w  (Race_ram_FrameDelay).l,d0
                sub.b   d0,$6D(a1)
                bgt.w   .locret_162AE

.loc_1622C:
                addi.b  #1,$6C(a1)
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_16248
                move.w  #1,(ram_FF1904).l
                bsr.w   Audio_UpdateEngine0

.loc_16248:
                cmpi.b  #3,$6C(a1)
                bpl.w   .loc_16298
                btst    #6,$69(a1)
                bne.w   .loc_16282
                lea     (RaceBike_ram_PhysicsConstants).l,a4
                btst    #1,$6B(a1)
                beq.w   .loc_16272
                lea     (ram_FF1AC2).l,a4

.loc_16272:
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_162AE


.loc_16282:
                lea     (ram_FF1ABC).l,a4
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_162AE


.loc_16298:
                move.b  #0,(ram_FF1B22).l
                bclr    #4,$69(a1)
                bra.w   .locret_162AE


.loc_162AA:
                bsr.w   Race_UpdatePlayerAttack

.locret_162AE:
                rts
; End of function Race_UpdateNearestTarget


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_UpdatePlayerAttack
; Player attack input: C button starts an attack; Up/Down selects high/low;
; the nearest actor's Y selects the attack side.
; In:  a1 - actor; Race_ram_CurrentButtons; Race_ram_NearestActor
; Out: actor $69 bit4/5/6, $6B bit0; ram_FF1B22; $6C/$6D
; Clobbers: d0-d1/a0
; Notes: weapon/armed flag $6B bit1 comes from the actor definition byte2 bit7.
; *************************************************

Race_UpdatePlayerAttack:
                move.b  (Race_ram_CurrentButtons).l,d0
                btst    #5,d0
                beq.w   .locret_1634C
                bset    #4,$69(a1)
                bset    #0,(ram_FF1B22).l
                move.b  #0,$6C(a1)
                move.b  (RaceBike_ram_PhysicsConstants).l,$6D(a1)
                btst    #1,$6B(a1)
                beq.w   .loc_162EC
                move.b  (ram_FF1AC2).l,$6D(a1)

.loc_162EC:
                bclr    #0,$6B(a1)
                bclr    #6,$69(a1)
                btst    #0,d0
                beq.w   .loc_1630A
                bset    #0,$6B(a1)
                bra.w   .loc_16320


.loc_1630A:
                btst    #1,d0
                beq.w   .loc_16320
                bset    #6,$69(a1)
                move.b  (ram_FF1ABC).l,$6D(a1)

.loc_16320:
                movea.l (Race_ram_NearestActor).l,a0
                cmpa.l  #$FFFFFFFF,a0
                beq.w   .locret_1634C
                move.w  $30(a1),d1
                cmp.w   $30(a0),d1
                bpl.w   .loc_16346
                bclr    #5,$69(a1)
                bra.w   .locret_1634C


.loc_16346:
                bset    #5,$69(a1)

.locret_1634C:
                rts
; End of function Race_UpdatePlayerAttack


 ; *************************************************
; Function sub_1634E (temporary name)
; AI attack/steer input decoder: reads ram_FF1B24 and maps bits to the same
; $69/$68/$46 fields used by the player attack path.
; In:  a1 - actor; ram_FF1B24
; Out: actor $69/$68/$46
; Clobbers: d0-d2
; Notes: no callers were found in the current source; ram_FF1B24 has no writer
; found yet, so this may be dead/unreferenced code.
; *************************************************

sub_1634E:
                lea     (RacePlayerA).l,a2
                move.l  4(a1),d0
                sub.l   4(a2),d0
                bmi.w   loc_1636E
                cmp.l   #$40000,d0
                bmi.w   loc_1637E
                bra.w   locret_16456
; ---------------------------------------------------------------------------

loc_1636E:
                neg.l   d0
                cmp.l   #$10000,d0
                bmi.w   loc_1637E
                bra.w   locret_16456
; ---------------------------------------------------------------------------

loc_1637E:
                clr.w   d0
                move.b  (ram_FF1B24).l,d0
                beq.w   locret_16456
                btst    #0,d0
                beq.w   loc_163CC
                bset    #4,$69(a1)
                move.w  $30(a1),d2
                cmp.w   $30(a2),d2
                bmi.w   loc_163AE
                bset    #5,$69(a1)
                bra.w   loc_163B4
; ---------------------------------------------------------------------------

loc_163AE:
                bclr    #5,$69(a1)

loc_163B4:
                btst    #1,d0
                bne.w   loc_163C6
                bclr    #6,$69(a1)
                bra.w   loc_163CC
; ---------------------------------------------------------------------------

loc_163C6:
                bset    #6,$69(a1)

loc_163CC:
                bra.w   loc_16428
; ---------------------------------------------------------------------------
                btst    #2,d0
                beq.w   loc_163FE
                move.l  4(a1),d2
                sub.l   4(a2),d2
                cmp.l   #$20000,d0
                bpl.w   loc_16428
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                bsr.w   Race_UpdateActorSpeedState
                bra.w   loc_16428
; ---------------------------------------------------------------------------

loc_163FE:
                btst    #3,d0
                beq.w   loc_16428
                move.l  4(a2),d2
                sub.l   4(a1),d2
                cmp.l   #$8000,d0
                bpl.w   loc_16428
                bclr    #1,$68(a1)
                bset    #2,$68(a1)
                bsr.w   Race_UpdateActorSpeedState

loc_16428:
                btst    #4,d0
                beq.w   loc_16440
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d2
                neg.w   d2
                bra.w   loc_16452
; ---------------------------------------------------------------------------

loc_16440:
                btst    #5,d0
                beq.w   locret_16456
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d2

loc_16452:
                move.w  d2,$46(a1)

locret_16456:
                rts
; End of function sub_1634E


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_DispatchActorAction
; Combat/action dispatcher: advances the attack/cooldown timer, selects an
; action handler from the actor graphics record, and applies the nearest-target
; distance/action rules.
; In:  a1 - actor; ram_FF1A68; Race_ram_NearestActor
; Out: actor $69/$5A; calls selected action
; Clobbers: d0/a4/a6
; *************************************************

Race_DispatchActorAction:
                move.l  a4,-(sp)
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,$5A(a1)
                bgt.w   loc_1646E
                move.w  #0,$5A(a1)

loc_1646E:
                btst    #4,$69(a1)
                beq.w   loc_1647C
                bsr.w   Audio_UpdateEngineState

loc_1647C:
                bclr    #2,$69(a1)
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   Race_FindTargetActor
                movea.l (sp)+,a4
                cmpa.l  #$FFFFFFFF,a2
                beq.w   loc_164AA
                cmpa.l  (RacePlayerA).l,a2
                beq.w   loc_164C0
                movea.l 4(a4),a6
                bra.w   loc_1651C
; ---------------------------------------------------------------------------

loc_164AA:
                jsr     (sub_13D44).l
                tst.w   (ram_FF18A4).l
                bne.w   locret_1651E
                lea     (RacePlayerA).l,a2

loc_164C0:
                cmpa.l  #ram_FF1F2A,a1
                beq.w   loc_16518
                btst    #4,$69(a1)
                bne.w   loc_16518
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   loc_164E2
                neg.l   d0

loc_164E2:
                movea.l (ram_FF1A68).l,a5
                move.w  0.w(a5),d6
                ext.l   d6
                swap    d6
                cmp.l   d6,d0
                bmi.w   loc_164FE
                movea.l 8(a4),a6
                bra.w   loc_1651C
; ---------------------------------------------------------------------------
loc_164FE:
                cmpa.l  (Race_ram_NearestActor).l,a1
                bne.w   loc_16510
                tst.w   $5A(a1)
                ble.w   loc_16518
loc_16510:
                movea.l 8(a4),a6
                bra.w   loc_1651C
; ---------------------------------------------------------------------------
loc_16518:
                movea.l $C(a4),a6
loc_1651C:
                jsr     (a6)
locret_1651E:
                rts
; End of function Race_DispatchActorAction

; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Audio_UpdateEngine0 (name TBD; likely attack SFX)
; Sets the attack SFX/state flag when attack phase 1 is active.
; In:  a1 - actor $6C/$6B/$69
; Out: ram_FF1AD7=$0E
; Clobbers: d0
; *************************************************

Audio_UpdateEngine0:
                cmpi.b  #1,$6C(a1)
                bne.w   .locret_16546
                btst    #1,$6B(a1)
                beq.w   .locret_16546
                btst    #6,$69(a1)
                bne.w   .locret_16546
                move.b  #$E,(ram_FF1AD7).l

.locret_16546:
                rts
; End of function Audio_UpdateEngine0


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Audio_UpdateEngineState (name TBD; likely attack state timer)
; Advances the attack phase/timer using unk_257E2/E8/EE timing tables.
; In:  a1 - actor $6B/$69/$6C/$6D; Race_ram_FrameDelay
; Out: actor $6C/$6D; ram_FF1906; ram_FF1AD7
; Clobbers: d0/a4
; *************************************************

Audio_UpdateEngineState:
                move.w  #0,(ram_FF1906).l
                move.w  (Race_ram_FrameDelay).l,d0
                sub.b   d0,$6D(a1)
                bgt.w   .locret_165CE
                addi.b  #1,$6C(a1)
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_16578
                move.w  #1,(ram_FF1906).l
                bsr.s   Audio_UpdateEngine0

.loc_16578:
                cmpi.b  #3,$6C(a1)
                bpl.w   .loc_165C8
                btst    #6,$69(a1)
                bne.w   .loc_165B2
                lea     (unk_257E8).l,a4
                btst    #1,$6B(a1)
                beq.w   .loc_165A2
                lea     (unk_257E2).l,a4

.loc_165A2:
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_165CE


.loc_165B2:
                lea     (unk_257EE).l,a4
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_165CE


.loc_165C8:
                bclr    #4,$69(a1)

.locret_165CE:
                rts
; End of function Audio_UpdateEngineState


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorSteerRoadCenter
; AI action: steer toward the lane/road center and apply the speed/collision
; check via Race_UpdateActorSpeedGear.
; In:  a1 - actor
; Out: actor $46/$30 and movement
; Clobbers: d0/d1/a6
; *************************************************

Race_ActorSteerRoadCenter:
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   sub_1384C
                bsr.w   Race_UpdateActorSpeedGear
                rts
; End of function Race_ActorSteerRoadCenter


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorSteerThrottle
; AI action: steering/brake state plus movement update.
; In:  a1 - actor; $68 bit5
; Out: actor $68/$46/$69
; Clobbers: d0-d1/a6
; *************************************************

Race_ActorSteerThrottle:
                move.b  $72(a1),d0
                ext.w   d0
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                bsr.w   sub_1384C
                btst    #5,$68(a1)
                beq.w   .loc_1660C
                bset    #2,$68(a1)
                bclr    #1,$68(a1)

.loc_1660C:
                bsr.w   Race_UpdateActorSpeedState
                rts
; End of function Race_ActorSteerThrottle


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorCollideSteer
; AI action: run the player/actor collision check, then apply the speed/steer
; correction (Race_UpdateActorSpeedGear + sub_1333C).
; In:  a1 - actor; RacePlayerA
; Out: actor collision/speed fields
; Clobbers: d0-d1/a2
; *************************************************

Race_ActorCollideSteer:
                bsr.w   Race_UpdateCollision
                move.w  d1,-(sp)
                bsr.w   Race_UpdateActorSpeedGear
                move.w  (sp)+,d1
                bsr.w   sub_1333C
                rts
; End of function Race_ActorCollideSteer


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorSteerCollide
; AI action: steering update followed by a collision check.
; In:  a1 - actor
; Out: actor fields
; Clobbers: see callees
; *************************************************

Race_ActorSteerCollide:
                bsr.s   Race_ActorSteerThrottle
                bsr.w   Race_UpdateCollision
                rts
; End of function Race_ActorSteerCollide


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorRandomCombatChoice
; AI action: random choice between collision/attack (Race_ActorCollideSteer) and pursuit
; (Race_ActorPursueAttack).
; In:  a1 - actor; Rand_GetWord
; Out: actor fields
; Clobbers: d0
; *************************************************

Race_ActorRandomCombatChoice:
                jsr     (Rand_GetWord).l
                btst    #0,d0
                bne.w   .loc_1663E
                bsr.s   Race_ActorCollideSteer
                rts


.loc_1663E:
                bsr.w   Race_ActorPursueAttack
                rts
; End of function Race_ActorRandomCombatChoice


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorProximityReaction
; AI action: reacts to the player/nearest actor position; close -> random
; attack/avoid (Race_ActorRandomCombatChoice), otherwise speed correction.
; In:  a1 - actor; $FF1EAE
; Out: actor speed/steer
; Clobbers: d0/d1
; *************************************************

Race_ActorProximityReaction:
                move.l  4(a1),d0
                sub.l   (RacePlayerA + RaceActor_X).l,d0
                cmp.l   #$C000,d0
                bpl.w   .loc_1665C
                bsr.s   Race_ActorRandomCombatChoice
                rts

.loc_1665C:
                move.w  #$FFC0,d1
                bsr.w   sub_1333C
                bsr.w   Race_UpdateActorSpeedGear
                rts
; End of function Race_ActorProximityReaction


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorPursueAttack
; AI action: check ram_FF1786/target thresholds; on-foot uses the $5A timer,
; otherwise pursue/steer or apply a speed correction.
; In:  a1 - actor; ram_FF1786; ram_FF1A68
; Out: actor $5A/$46/speed
; Clobbers: d0/d1/a4
; *************************************************

Race_ActorPursueAttack:
                bsr.w   Race_UpdateActorSpeedGear
                move.l  (ram_FF1786).l,d0
                movea.l (ram_FF1A68).l,a4
                btst    #4,$68(a1)
                beq.w   .loc_1668E
                move.w  8(a4),$5A(a1)
                bra.w   .loc_1669A


.loc_1668E:
                move.w  2(a4),d7
                ext.l   d7
                cmp.l   d7,d0
                bmi.w   .loc_166A6

.loc_1669A:
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   sub_1384C
                rts


.loc_166A6:
                move.w  #0,d1
                bsr.w   sub_1333C
                rts
; End of function Race_ActorPursueAttack


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorAttackIfClose
; AI action: if the nearest target is within the graphics-record distance,
; run the collision/attack action; otherwise steer/speed-correct.
; In:  a1 - actor; ram_FF1786; ram_FF1A68
; Out: actor fields
; Clobbers: d0/d1/a4
; *************************************************

Race_ActorAttackIfClose:
                move.l  (ram_FF1786).l,d0
                movea.l (ram_FF1A68).l,a4
                move.w  2(a4),d7
                ext.l   d7
                cmp.l   d7,d0
                bpl.w   .loc_166CE
                bsr.w   Race_ActorCollideSteer
                rts


.loc_166CE:
                move.w  #0,d1
                bsr.w   sub_1333C
                bsr.w   Race_UpdateActorSpeedGear
                rts
; End of function Race_ActorAttackIfClose


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorEvadePlayer
; AI action: evade/steer toward the player using sub_1333C/sub_13292.
; In:  a1 - actor; RacePlayerA
; Out: actor movement
; Clobbers: d0-d2
; *************************************************

Race_ActorEvadePlayer:
                lea     (RacePlayerA).l,a2
                move.w  #0,d1
                bsr.w   sub_1333C
                bsr.w   sub_13292
                rts
; End of function Race_ActorEvadePlayer


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_ActorCombatResponse
; Combat/collision response: resolves the target and runs Race_UpdateCollision
; or the speed/steer correction.
; In:  a1 - actor; RacePlayerA; ram_FF1A68
; Out: actor collision/speed fields
; Clobbers: d0-d3/a2
; *************************************************

Race_ActorCombatResponse:
                bclr    #2,$69(a1)
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   Race_FindTargetActor
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_16720
                cmpa.l  #RacePlayerA,a2
                beq.w   .loc_16720
                bsr.w   sub_13422
                bsr.w   Race_UpdateActorSpeedGear
                bra.w   .locret_16730


.loc_16720:
                bsr.w   Race_UpdateCollision
                move.w  d1,-(sp)
                bsr.w   Race_UpdateActorSpeedGear
                move.w  (sp)+,d1
                bsr.w   sub_1333C

.locret_16730:
                rts
; End of function Race_ActorCombatResponse


; =============== S U B R O U T I N E =======================================


 ; *************************************************
; Function Race_UpdateCollision
; Player/actor proximity/attack setup: uses $4A/$30 and graphics-record ranges
; to start the attack/collision state and cooldown.
; In:  a1 - actor; RacePlayerA; ram_FF1A68; RaceBike_ram_PhysicsConstants/1ABC
; Out: actor $5A/$69/$6B/$6C/$6D
; Clobbers: d0-d3/a2/a4
; *************************************************

Race_UpdateCollision:
                btst    #4,$69(a1)
                bne.w   .locret_1685E
                lea     (RacePlayerA).l,a2
                move.w  $4A(a1),d1
                add.w   $4A(a2),d1
                move.w  d1,d2
                addi.w  #$10,d1
                addq.w  #8,d2
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   .loc_16760
                neg.l   d0

.loc_16760:
                movea.l (ram_FF1A68).l,a4
                move.w  2(a4),d7
                ext.l   d7
                cmp.l   d7,d0
                bpl.w   .loc_16858
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                bpl.w   .loc_167EC
                neg.w   d0
                cmp.w   d1,d0
                bpl.w   .loc_16858
                move.w  8(a4),$5A(a1)
                move.b  #0,$6C(a1)
                bclr    #0,$6B(a1)
                bset    #4,$69(a1)
                bset    #5,$69(a1)
                cmp.w   d2,d0
                bpl.w   .loc_167BC
                bset    #6,$69(a1)
                move.b  (ram_FF1ABC).l,$6D(a1)
                bra.w   .locret_1685E


.loc_167BC:
                bclr    #6,$69(a1)
                move.b  (RaceBike_ram_PhysicsConstants).l,$6D(a1)
                move.w  (Race_ram_ActorDistanceScale).l,d0
                andi.b  #1,d0
                or.b    d0,$6B(a1)
                btst    #1,$6B(a1)
                beq.w   .locret_1685E
                move.b  #$3C,$6D(a1) ; '<'
                bra.w   .locret_1685E


.loc_167EC:
                cmp.w   d1,d0
                bpl.w   .loc_16858
                move.w  8(a4),$5A(a1)
                move.b  #0,$6C(a1)
                bclr    #0,$6B(a1)
                bset    #4,$69(a1)
                bclr    #5,$69(a1)
                cmp.w   d2,d0
                bpl.w   .loc_16828
                bset    #6,$69(a1)
                move.b  (ram_FF1ABC).l,$6D(a1)
                bra.w   .locret_1685E


.loc_16828:
                bclr    #6,$69(a1)
                move.b  (RaceBike_ram_PhysicsConstants).l,$6D(a1)
                move.w  (Race_ram_ActorDistanceScale).l,d0
                andi.b  #1,d0
                or.b    d0,$6B(a1)
                btst    #1,$6B(a1)
                beq.w   .locret_1685E
                move.b  #$3C,$6D(a1) ; '<'
                bra.w   .locret_1685E


.loc_16858:
                bclr    #4,$69(a1)

.locret_1685E:
                rts
; End of function Race_UpdateCollision


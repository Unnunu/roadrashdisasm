; *************************************************
; race_spawn.asm - track data + dynamic spawn after animation
; ROM range: $169B0-$16E6F
; *************************************************


; =============== S U B R O U T I N E =======================================


TrackData_InitLevel:
                movem.l d0/a0,-(sp)
                move.w  (Menu_ram_CurrentTrackId).l,d0
                asl.w   #1,d0
                lea     (off_16AB0).l,a0
                move.l  (a0,d0.w),(Race_ram_TrackScaleTable).l
                movem.l (sp)+,d0/a0
                movea.l (RaceTrack_Data2).l,a2
                movea.l (RaceTrack_Data3).l,a3
                lea     (Track_CurveBuffer).l,a1
                move.w  #$7F,d1
                jsr     (TrackData_StartDecode).l
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                asl.w   #1,d0
                movea.l (Race_ram_TrackScaleTable).l,a0
                move.w  (a0,d0.w),d2
                lea     (Track_CurveBuffer).l,a1
                move.w  #$7F,d0

.loc_16A08:
                move.b  (a1),d1
                ext.w   d1
                bpl.w   .loc_16A24
                neg.w   d1
                mulu.w  d2,d1
                swap    d1
                neg.w   d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A08
                bra.w   .locret_16A30


.loc_16A24:
                mulu.w  d2,d1
                swap    d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A08

.locret_16A30:
                rts
; End of function TrackData_InitLevel


; =============== S U B R O U T I N E =======================================


TrackData_DecodeNextChunk:
                addq.w  #1,d0
                cmp.w   #3,d0
                ble.w   .loc_16A44
                move.w  #0,d0
                bra.w   .loc_16A46


.loc_16A44:
                asl.w   #7,d0

.loc_16A46:
                lea     (Track_CurveBuffer).l,a1
                adda.w  d0,a1
                move.l  a1,-(sp)
                move.l  #$80,d0
                movea.l (RaceTrack_Data2).l,a2
                movea.l (RaceTrack_Data3).l,a3
                move.w  #$3F,d1 ; '?'
                jsr     (TrackData_DecodeChunk).l
                movea.l (sp)+,a1
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                asl.w   #1,d0
                movea.l (Race_ram_TrackScaleTable).l,a0
                move.w  (a0,d0.w),d2
                move.w  #$3F,d0 ; '?'

.loc_16A86:
                move.b  (a1),d1
                ext.w   d1
                bpl.w   .loc_16AA2
                neg.w   d1
                mulu.w  d2,d1
                swap    d1
                neg.w   d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A86
                bra.w   .locret_16AAE


.loc_16AA2:
                mulu.w  d2,d1
                swap    d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A86

.locret_16AAE:
                rts
; End of function TrackData_DecodeNextChunk



off_16AB0:      dc.l word_16AC4
                dc.l word_16ACE
                dc.l word_16AD8
                dc.l word_16AE2
                dc.l word_16AEC
word_16AC4:     dc.w $B333
                dc.w $CCCC
                dc.w $D999
                dc.w $D999
word_16ACC:     dc.w $D999
word_16ACE:     dc.w $B333
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
                dc.w $E666
word_16AD8:     dc.w $B333
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
word_16AE0:     dc.w $E666
word_16AE2:     dc.w $A666
                dc.w $B333
                dc.w $C000
                dc.w $C000
                dc.w $C000
word_16AEC:     dc.w $B333
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
                dc.w $E666



; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_SpawnTick
; Opponent/traffic spawn ticker: timer, active-count and speed gates.
; In:  player A $68/Speed, Race_ram_SpawnTimer timer, Race_ram_ActiveActorCount active count
; Out: active/free lists; spawned actor; Race_ram_SpawnTimer next timer
; Clobbers: d0/a1
; *************************************************

Race_SpawnTick:
                btst    #7,(RacePlayerA + STRUCT_OFFSET_68).l
                bne.w   .return
                tst.w   (Race_ram_SpawnTimer).l
                beq.w   .loc_16B2E
                move.w  (Race_ram_SpawnTimer).l,d0
                sub.w   (Race_ram_FrameDelay).l,d0
                ble.w   .loc_16B26
                move.w  d0,(Race_ram_SpawnTimer).l
                bra.w   .return


.loc_16B26:
                move.w  #0,(Race_ram_SpawnTimer).l

.loc_16B2E:
                cmpi.w  #6,(Race_ram_ActiveActorCount).l
                bpl.w   .return
                cmpi.w  #6000,(RacePlayerA + RaceActor_Speed).l
                bmi.w   .loc_16B54
                bsr.w   Race_SpawnOpponent
                cmpa.l  #$FFFFFFFF,a1
                bne.w   .loc_16B58

.loc_16B54:
                bsr.w   Race_SpawnTraffic

.loc_16B58:
                jsr     (Rand_GetWord).l
                andi.w  #$1FF,d0
                move.w  d0,(Race_ram_SpawnTimer).l

.return:
                rts
; End of function Race_SpawnTick


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_CheckOpponentAhead
; Recycles an actor that is too far ahead of the player progress.
; In:  a1 - actor, a2 - free list
; Out: a1 - still valid or $FFFFFFFF; free list
; Clobbers: d0/d1/a1
; *************************************************

Race_CheckOpponentAhead:
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .locret_16B9C
                bsr.w   Race_GetActorDistance
                move.w  (Race_ram_PlayerProgress).l,d1
                addi.w  #$20,d1
                cmp.w   d1,d0
                ble.w   .locret_16B9C
                cmp.w   (RaceTrack_Data1).l,d1
                blt.w   .locret_16B9C
                bsr.w   Race_PushFreeActor
                movea.l #$FFFFFFFF,a1
.locret_16B9C:
                rts
; End of function Race_CheckOpponentAhead


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_CheckTrafficBehind
; Recycles a traffic actor that is too far behind the player progress.
; In:  a1 - actor, a2 - free list
; Out: a1 - still valid or $FFFFFFFF; free list
; Clobbers: d0/d1/a1
; *************************************************

Race_CheckTrafficBehind:
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .locret_16BC6
                bsr.w   Race_GetActorDistance
                move.w  (Race_ram_PlayerProgress).l,d1
                subi.w  #$10,d1
                cmp.w   d1,d0
                bgt.w   .locret_16BC6
                bsr.w   Race_PushFreeActor
                movea.l #$FFFFFFFF,a1
.locret_16BC6:
                rts
; End of function Race_CheckTrafficBehind


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_GetActorDistance
; Scales the actor rating (+$66) by Race_ram_ActorDistanceScale.
; In:  a1 - actor
; Out: d0 - distance value
; Clobbers: d0
; *************************************************

Race_GetActorDistance:
                move.w  RaceActor_Rating(a1),d0
                mulu.w  (Race_ram_ActorDistanceScale).l,d0
                swap    d0
                rts
; End of function Race_GetActorDistance


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_SpawnOpponent
; Pops a free opponent, checks it is not too far ahead, activates it and places it
; ahead of the player.
; In:  Race_ram_OpponentFreeList free list, player A x
; Out: actor fields/active list; a1
; Clobbers: d0/a1/a2
; *************************************************

Race_SpawnOpponent:
                move.l  a2,-(sp)
                lea     (Race_ram_OpponentFreeList).l,a2
                bsr.w   Race_PopFreeActor
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_16C16
                bsr.w   Race_CheckOpponentAhead
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_16C16
                cmpa.l  #ram_FF1F2A,a1
                bne.w   .loc_16C0E
                btst    #6,$68(a1)
                bne.w   .loc_16C16
.loc_16C0E:
                bsr.w   Race_ActivateActor
                bsr.w   Race_InitOpponentActor
.loc_16C16:
                movea.l (sp)+,a2
                rts
; End of function Race_SpawnOpponent


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_SpawnTraffic
; Pops a free traffic actor, checks it is not too far behind, activates/sets it up.
; In:  Race_ram_TrafficFreeList free list, player A x
; Out: actor fields/active list; a1
; Clobbers: d0/a1/a2
; *************************************************

Race_SpawnTraffic:
                move.l  a2,-(sp)
                lea     (Race_ram_TrafficFreeList).l,a2
                bsr.w   Race_PopFreeActor
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_16C4A
                bsr.w   Race_CheckTrafficBehind
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_16C4A
                bsr.w   Race_ActivateActor
                bsr.w   Race_InitTrafficActor
                bsr.w   Race_ApplyActorRating

.loc_16C4A:
                movea.l (sp)+,a2
                rts
; End of function Race_SpawnTraffic


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_ApplyActorRating
; Looks up the actor's opponent definition and writes rating*100 into +$66.
; In:  a1 - actor; Menu_ram_PlayerA/BOpponents
; Out: actor +$66
; Clobbers: d0/a2
; *************************************************

Race_ApplyActorRating:
                movem.l d0-d1/a2,-(sp)
                lea     (Race_ActorList).l,a0
                lea     (Menu_ram_PlayerAOpponents).l,a2
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_16C6E
                lea     (Menu_ram_PlayerBOpponents).l,a2

.loc_16C6E:
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #1,d0
                move.w  (a2,d0.w),d0
                lea     (Race_ActorDefinitionTable).l,a2
                asl.w   #4,d0
                lea     (a2,d0.w),a2
                clr.w   d0
                move.b  5(a2),d0
                mulu.w  #$64,d0 ; 'd'
                move.w  d0,RaceActor_Rating(a1)
                movem.l (sp)+,d0-d1/a2
                rts
; End of function Race_ApplyActorRating


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_RecycleOpponent
; Pushes the actor to the opponent free list and removes it from the active list.
; In:  a1 - actor
; Out: Race_ram_OpponentFreeList/Race_ram_ActiveActorList/Race_ram_ActiveActorCount
; Clobbers: a1/a2
; *************************************************

Race_RecycleOpponent:
                move.l  a2,-(sp)
                lea     (Race_ram_OpponentFreeList).l,a2
                bsr.w   Race_PushFreeActor
                bsr.w   Race_RemoveActiveActor
                movea.l (sp)+,a2
                rts
; End of function Race_RecycleOpponent


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_RecycleActor
; Removes an actor from the race, pushes traffic actors to Race_ram_TrafficFreeList and handles
; the first-opponent level transition.
; In:  a1 - actor
; Out: free/active lists; Race_ram_LevelIndex/34/36
; Clobbers: d0/a1/a2
; *************************************************

Race_RecycleActor:
                movem.l d0-d1/a2,-(sp)
                cmpa.l  #ram_FF1F2A,a1
                bne.w   .loc_16CE8
                move.w  (Menu_ram_PlayerLevel).l,d0
                cmp.w   (Race_ram_LevelIndex).l,d0
                bne.w   .loc_16CDC
                move.w  #0,(ram_FF1B36).l
                move.w  #0,(ram_FF1B34).l

.loc_16CDC:
                move.w  #0,(Race_ram_LevelIndex).l
                bra.w   .loc_16CF2


.loc_16CE8:
                lea     (Race_ram_TrafficFreeList).l,a2
                bsr.w   Race_PushFreeActor

.loc_16CF2:
                bsr.w   Race_RemoveActiveActor
                move.l  4(a1),d0
                divu.w  (Race_ram_ActorDistanceScale).l,d0
                move.w  d0,RaceActor_Rating(a1)
                movem.l (sp)+,d0-d1/a2
                rts
; End of function Race_RecycleActor


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_ActivateActor
; Appends the actor to the active list and increments the count.
; In:  a1 - actor
; Out: Race_ram_ActiveActorList/Race_ram_ActiveActorCount
; Clobbers: a2
; *************************************************

Race_ActivateActor:
                move.l  a2,-(sp)
                lea     (Race_ram_ActiveActorList).l,a2
.loc_16D12:
                tst.l   (a2)+
                bpl.s   .loc_16D12
                move.l  a1,-4(a2)
                move.l  #$FFFFFFFF,(a2)
                addq.w  #1,(Race_ram_ActiveActorCount).l
                movea.l (sp)+,a2
                rts
; End of function Race_ActivateActor


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_InitOpponentActor
; Places a new opponent $200000 ahead, sets Speed from +$66 and runs the setup.
; In:  a1 - actor; player A
; Out: actor fields
; Clobbers: d0/a1/a2
; *************************************************

Race_InitOpponentActor:
                move.l  a2,-(sp)
                lea     (RacePlayerA).l,a2
                move.l  4(a2),d0
                addi.l  #$200000,d0
                move.l  d0,4(a1)
                move.w  RaceActor_Rating(a1),d0
                move.w  d0,$12(a1)
                bsr.w   Race_SetupActor
                bsr.w   Race_GetCurveSpeedLimit
                cmp.w   $12(a1),d0
                bpl.w   .loc_16D5C
                move.w  d0,$12(a1)
.loc_16D5C:
                movea.l (sp)+,a2
                rts
; End of function Race_InitOpponentActor


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_InitTrafficActor
; Places new traffic $100000 behind, sets Speed from +$66 and runs the setup.
; In:  a1 - actor; player A
; Out: actor fields
; Clobbers: d0/a1/a2
; *************************************************

Race_InitTrafficActor:
                move.l  a2,-(sp)
                lea     (RacePlayerA).l,a2
                move.l  RaceActor_X(a2),d0
                subi.l  #$100000,d0
                move.l  d0,4(a1)
                move.l  d0,$1E(a1)
                move.w  RaceActor_Rating(a1),d0
                move.w  d0,$12(a1)
                bsr.w   Race_SetupActor
                bsr.w   Race_GetCurveSpeedLimit
                cmp.w   $12(a1),d0
                bpl.w   .loc_16D96
                move.w  d0,$12(a1)

.loc_16D96:
                movea.l (sp)+,a2
                rts
; End of function Race_InitTrafficActor


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_SetupActor
; Common actor setup: curve at the actor position, flags, sprite/tile base.
; In:  a1 - actor
; Out: actor fields
; Clobbers: d0/a4; calls Race_SetupActorSprite
; *************************************************

Race_SetupActor:
                lea     (Track_CurveBuffer).l,a4
                move.l  4(a1),d0
                move.l  d0,$1E(a1)
                andi.w  #$FF,d0
                asl.w   #1,d0
                addi.w  #$C,d0
                andi.w  #$1FF,d0
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,$C(a1)
                move.w  d0,8(a1)
                bclr    #4,$68(a1)
                bclr    #0,$68(a1)
                move.w  #0,$2C(a1)
                move.w  (ram_FF18A8).l,$5C(a1)
                move.b  #$FF,$6E(a1)
                move.w  #0,d0
                move.w  d0,$A(a1)
                move.w  d0,$36(a1)
                move.w  d0,$38(a1)
                move.w  d0,$3A(a1)
                move.w  d0,$3C(a1)
                move.w  d0,$2C(a1)
                move.w  d0,2(a1)
                move.w  d0,$32(a1)
                move.w  $30(a1),d0
                bpl.w   .loc_16E16
                neg.w   d0
                move.w  d0,$30(a1)

.loc_16E16:
                move.w  d0,$1A(a1)
                move.w  d0,0.w(a1)
                jsr     (Race_SetupActorSprite).l
                rts
; End of function Race_SetupActor


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_RemoveActiveActor
; Removes the actor from the active list and decrements the count.
; In:  a1 - actor
; Out: Race_ram_ActiveActorList/Race_ram_ActiveActorCount
; Clobbers: a2/a3
; *************************************************

Race_RemoveActiveActor:
                movem.l a2-a3,-(sp)
                lea     (Race_ram_ActiveActorList).l,a2

.loc_16E30:
                cmpa.l  (a2)+,a1
                bne.s   .loc_16E30
                movea.l a2,a3
                subq.l  #4,a3

.loc_16E38:
                move.l  (a2)+,(a3)+
                bpl.s   .loc_16E38
                subq.w  #1,(Race_ram_ActiveActorCount).l
                movem.l (sp)+,a2-a3
                rts
; End of function Race_RemoveActiveActor


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_PushFreeActor
; Pushes a1 onto the free list at a2.
; In:  a1 - actor; a2 - free list
; Out: list
; Clobbers: d0
; *************************************************

Race_PushFreeActor:
                move.w  (a2),d0
                addq.w  #1,(a2)
                asl.w   #2,d0
                move.l  a1,2(a2,d0.w)
                rts
; End of function Race_PushFreeActor


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_PopFreeActor
; Pops an actor from the free list at a2; $FFFFFFFF when empty.
; In:  a2 - free list
; Out: a1 - actor or $FFFFFFFF
; Clobbers: d0/a1
; *************************************************

Race_PopFreeActor:
                move.w  (a2),d0
                bne.w   .loc_16E64
                movea.l #$FFFFFFFF,a1
                bra.w   .locret_16E6E
.loc_16E64:
                subq.w  #1,d0
                move.w  d0,(a2)
                asl.w   #2,d0
                movea.l 2(a2,d0.w),a1
.locret_16E6E:
                rts
; End of function Race_PopFreeActor
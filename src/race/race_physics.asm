; *************************************************
; race_physics.asm - DmaWriteVRAM + actor/physics/AI functions
; ROM range: $D8FA-$E731 (road_marking starts at $E732)
; *************************************************


; =============== S U B R O U T I N E =======================================


DmaWriteVRAM:
                move.w  #$9300,d3
                move.b  d2,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9400,d3
                lsr.w   #8,d2
                move.b  d2,d3
                move.w  d3,(VdpCtrl).l
                asr.l   #1,d0
                move.w  #$9500,d3
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9600,d3
                asr.l   #8,d0
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9700,d3
                asr.l   #8,d0
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  d1,d0
                rol.w   #2,d0
                andi.w  #3,d0
                ori.b   #$80,d0
                move.w  d0,(Race_ram_VdpDmaControl).l
                andi.w  #$3FFF,d1
                addi.w  #$4000,d1
                move.w  d1,(VdpCtrl).l
                move.w  (Race_ram_VdpDmaControl).l,(VdpCtrl).l
                rts
; End of function DmaWriteVRAM


; =============== S U B R O U T I N E =======================================

; d2 - DMA length
; d0 - DMA source
; d1 - DMA destination

DmaWriteCRAM:
                move.w  #$9300,d3
                move.b  d2,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9400,d3
                lsr.w   #8,d2
                move.b  d2,d3
                move.w  d3,(VdpCtrl).l
                asr.l   #1,d0
                move.w  #$9500,d3
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9600,d3
                asr.l   #8,d0
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9700,d3
                asr.l   #8,d0
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  d1,d0
                rol.w   #2,d0
                andi.w  #3,d0
                ori.b   #$80,d0
                move.w  d0,(Race_ram_VdpDmaControl).l
                andi.w  #$3FFF,d1
                addi.w  #-$4000,d1
                move.w  d1,(VdpCtrl).l
                move.w  (Race_ram_VdpDmaControl).l,(VdpCtrl).l
                rts
; End of function DmaWriteCRAM


; =============== S U B R O U T I N E =======================================
; draw road in rearview mirrors

; *************************************************
; Function Race_DrawRearviewMirror
; Draws the road in the rearview mirror (HUD row 25) from the player position.
; In:  player A PosX/PosY; Race_ram_RearviewTileRows road rows
; Out: Race_ram_CurrentHudBuffer mirror rows
; Clobbers: d0-d2/a0-a2
; *************************************************

Race_DrawRearviewMirror:
                movea.l (Global_ram_PalettePtr).l,a2
                move.l  $78(a2),d1
                move.w  $7C(a2),d1
                move.w  (RacePlayerA + RaceActor_X).l,d0
                btst    #0,d0
                bne.w   .loc_D9F8
                swap    d1
.loc_D9F8:
                move.l  d1,$70(a2)
                move.w  (RacePlayerA + RaceActor_PosY).l,d0
                subi.w  #$10,d0
                ext.l   d0
                divs.w  #$28,d0 ; '('
                move.w  d0,d1
                bge.w   .loc_DA14
                subq.w  #1,d1
.loc_DA14:
                move.w  #0,d0
                bsr.w   Race_DrawMirrorRoad
                move.w  (RacePlayerA + RaceActor_PosY).l,d0
                addi.w  #$10,d0
                ext.l   d0
                divs.w  #$28,d0 ; '('
                move.w  d0,d1
                bpl.w   .loc_DA34
                subq.w  #1,d1
.loc_DA34:
                move.w  #$20,d0 ; ' '
                bsr.w   Race_DrawMirrorRoad
                rts
; End of function Race_DrawRearviewMirror


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_DrawMirrorRoad
; Copies one mirror road strip with palette/priority correction.
; In:  d0 - HUD x offset; d1 - road row offset; a1 - HUD buffer
; Out: HUD mirror rows
; Clobbers: d0-d2/a0/a1
; *************************************************

Race_DrawMirrorRoad:
                movea.l (Race_ram_CurrentHudBuffer).l,a1
                adda.l  #$C80,a1 ; x = 0, y = 25
                asl.w   #1,d0
                lea     (a1,d0.w),a1
                tst.w   d1
                bmi.w   .loc_DAA8
                lea     $10(a1),a1
                move.l  #$8000800,d2
                cmp.w   #$B,d1
                bmi.w   .loc_DA6C
                move.w  #$A,d1
.loc_DA6C:
                movea.l #Race_ram_RearviewTileRows,a0
                asl.w   #5,d1
                lea     (a0,d1.w),a0
                move.w  #1,d0
.loc_DA7C:
                move.l  (a0)+,d1
                swap    d1
                eor.l   d2,d1
                move.l  d1,-(a1)
                move.l  (a0)+,d1
                swap    d1
                eor.l   d2,d1
                move.l  d1,-(a1)
                move.l  (a0)+,d1
                swap    d1
                eor.l   d2,d1
                move.l  d1,-(a1)
                move.l  (a0)+,d1
                swap    d1
                eor.l   d2,d1
                move.l  d1,-(a1)
                adda.l  #$90,a1
                dbf     d0,.loc_DA7C
                rts
.loc_DAA8:
                neg.w   d1
                andi.w  #$7FFF,d1
                cmp.w   #$B,d1
                bmi.w   .loc_DABA
                move.w  #$A,d1
.loc_DABA:
                movea.l #Race_ram_RearviewTileRows,a0
                move.w  #5,d0
                asl.w   d0,d1
                lea     (a0,d1.w),a0
                move.w  #1,d0
.loc_DACE:
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                adda.l  #$70,a1 ; 'p'
                dbf     d0,.loc_DACE
                rts
; End of function Race_DrawMirrorRoad


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_ProjectActorSprite
; Projects an actor position vs the player progress into sprite Y/X fields.
; In:  a1 - actor; Race_ram_PlayerProgress progress
; Out: actor/sprite fields; ram_FF1B50 list
; Clobbers: d0-d2/a0/a3
; *************************************************

Race_ProjectActorSprite:
                move.l  4(a1),d2
                sub.l   (Race_ram_PlayerProgress).l,d2
                neg.l   d2
                lea     (ram_FF1B50).l,a3
                move.w  (ram_FFDE72).l,d0
                asl.w   #2,d0
                move.l  d2,(a3,d0.w)
                swap    d2
                move.l  d2,d0
                swap    d0
                move.w  #$A,d1
                asr.l   d1,d0
                muls.w  #$FFE5,d0
                divs.w  #$10,d0
                addi.w  #$B00,d0
                move.w  d0,-(sp)
                move.w  (RacePlayerA + RaceActor_PosY).l,d1
                subi.w  #$10,d1
                ext.l   d1
                divs.w  #$28,d1 ; '('
                muls.w  #$28,d1 ; '('
                neg.w   d1
                add.w   $30(a1),d1
                muls.w  d1,d0
                divs.w  #$E0,d0
                asr.w   #6,d0
                move.w  d0,$C(a0)
                addi.w  #$20,d0 ; ' '
                move.w  d0,0.w(a0)
                move.w  (RacePlayerA + RaceActor_PosY).l,d1
                addi.w  #$10,d1
                ext.l   d1
                divs.w  #$28,d1 ; '('
                muls.w  #$28,d1 ; '('
                neg.w   d1
                add.w   $30(a1),d1
                move.w  (sp)+,d0
                muls.w  d1,d0
                divs.w  #$E0,d0
                asr.w   #6,d0
                addi.w  #$100,d0
                sub.w   d0,$C(a0)
                move.l  d2,d0
                swap    d0
                move.w  #$C,d1
                asr.l   d1,d0
                divs.w  #$10,d0
                neg.w   d0
                addi.w  #$D8,d0
                move.w  d0,2(a0)
                move.l  d2,d1
                swap    d1
                move.w  #$C,d0
                asr.l   d0,d1
                addi.l  #$80,d1
                move.l  #$100000,d0
                divu.w  d1,d0
                cmp.w   #$3FFF,d0
                bmi.w   .loc_DBB0
                move.w  #$3FFF,d0

.loc_DBB0:
                move.w  d0,d1
                lsl.w   #1,d0
                add.w   d1,d0
                move.w  d0,4(a0)
                move.w  #$E0,6(a0)
                move.b  $73(a1),d0
                andi.w  #3,d0
                ror.w   #4,d0
                addi.w  #$4100,d0
                move.w  d0,$A(a0)
                move.b  $71(a1),d0
                cmp.b   #1,d0
                beq.w   .loc_DC34
                cmp.b   #$10,d0
                blt.w   .loc_DBF2
                cmp.b   #$12,d0
                ble.w   .loc_DC40
                bra.w   .locret_DC7E


.loc_DBF2:
                move.w  $C(a1),d0
                move.w  d0,d1
                andi.w  #$8000,d1
                or.w    d1,$A(a0)
                btst    #4,RaceActor_ControlFlags(a1)
                beq.w   .loc_DC20
                tst.b   $6E(a1)
                bmi.w   .loc_DC20
                move.w  4(a0),d0
                lsr.w   #1,d0
                move.w  d0,4(a0)
                bra.w   .loc_DC58


.loc_DC20:
                jsr     (Race_GetActorShapeVariant).l
                move.w  d1,d0
                addi.w  #$154,d0
                move.w  d0,8(a0)
                bra.w   .loc_DC58


.loc_DC34:
                move.w  #$159,d0
                move.w  d0,8(a0)
                bra.w   .loc_DC58


.loc_DC40:
                move.w  #$15A,d0
                btst    #3,RaceActor_StateFlags(a1)
                beq.w   .loc_DC50
                addq.w  #2,d0

.loc_DC50:
                move.w  d0,8(a0)
                bra.w   *+4


.loc_DC58:
                move.w  (a0),d0
                cmp.w   #$FFE0,d0
                bmi.w   .locret_DC7E
                sub.w   $C(a0),d0
                cmp.w   #$160,d0
                bpl.w   .locret_DC7E
                subi.w  #$200,(a0)
                addi.w  #1,(ram_FFDE72).l
                adda.w  #$14,a0

.locret_DC7E:
                rts
; End of function Race_ProjectActorSprite


                dc.b   8
                dc.b   8
                dc.b   0
                dc.b   6
Race_RoadMarkingDataA:
    dc.l $BBBBBBAB
    dc.l $BABBBABB
    dc.l $BBABBBBA
    dc.l $BBBBBABB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $AB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $AB
                dc.b $AB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
Race_RoadMarkingDataB:       dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB

; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_DrawRoadMarkingHud
; Draws road markings/mirror from the width/position arrays and marking data A/B.
; In:  ram_FF3238 widths, player progress, ram_FF1B30/2E
; Out: HUD marking rows/arrays
; Clobbers: d0-d7/a0-a5
; *************************************************

Race_DrawRoadMarkingHud:
                move.w  #$98,d0
                move.w  (ram_FF1B30).l,d4
                move.w  (Race_ram_PlayerProgress).l,d6
                move.w  #$FFFF,d7
                lea     (ram_FF3238).l,a0
                movea.l (Race_ram_CurrentHudBuffer).l,a1
                adda.w  #$260,a1
                movea.l (Race_ram_CurrentAlpha).l,a2
                lea     (RoadMarking_ram_WidthArray).l,a3
                adda.w  #$130,a3
                lea     (ram_FF3A9C).l,a5
                adda.w  #$130,a5
.loc_DDC2:
                subq.w  #1,d4
                bne.w   .loc_DDCE
                move.w  (ram_FF1B2E).l,d7
.loc_DDCE:
                move.w  (a0)+,d5
                cmp.w   d5,d0
                ble.w   .loc_DE22
                lea     (Race_RoadMarkingDataA).l,a4
                btst    #0,d6
                beq.w   .loc_DDEA
                lea     (Race_RoadMarkingDataB).l,a4
.loc_DDEA:
                tst.w   d7
                bgt.w   .loc_DE36
                move.w  d6,d1
                asr.w   #1,d1
                sub.w   d5,d1
                add.w   d0,d1
                asl.w   #2,d1
.loc_DDFA:
                subq.l  #4,d1
                andi.w  #$3C,d1
                move.l  (a4,d1.w),-(a1)
                subq.w  #2,a3
                subq.w  #2,a5
                cmpa.l  #Race_RoadMarkingDataA,a4
                beq.w   .loc_DE16
                move.w  #0,(a3)
.loc_DE16:
                subq.w  #1,d0
                cmp.w   (a2),d0
                beq.w   .locret_DE34
                cmp.w   d5,d0
                bgt.s   .loc_DDFA
.loc_DE22:
                tst.w   d4
                bgt.w   .loc_DE2A
                subq.w  #1,d7
.loc_DE2A:
                addq.w  #1,d6
                cmpa.l  #ram_FF3276,a0
                bmi.s   .loc_DDC2
.locret_DE34:
                rts
.loc_DE36:
                move.w  d0,d3
                sub.w   d5,d3
                subq.w  #2,d3
                bmi.w   .loc_DE78
                movea.l #$CCCCCCCC,a4
                move.w  d5,d3
                cmp.w   #3,d7
                beq.w   .loc_DE78
                movea.l #$DDDDDDDD,a4
                move.w  d0,d3
                sub.w   d5,d3
                asr.w   #2,d3
                add.w   d5,d3
                cmp.w   #1,d7
                beq.w   .loc_DE78
                sub.w   d5,d3
                neg.w   d3
                add.w   d0,d3
                cmp.w   #4,d7
                beq.w   .loc_DE78
                move.w  #0,d3
.loc_DE78:
                move.l  #$EEEEEEEE,-(a1)
                subq.w  #1,d0
                cmp.w   d0,d3
                bne.w   .loc_DE88
                move.l  a4,(a1)
.loc_DE88:
                subq.w  #2,a3
                subq.w  #2,a5
                move.w  #0,(a3)
                move.w  #0,(a5)
                cmp.w   (a2),d0
                beq.s   .locret_DE34
                cmp.w   d5,d0
                bgt.s   .loc_DE78
                bra.s   .loc_DE22
; End of function Race_DrawRoadMarkingHud


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_UpdateCamera
; Updates the camera offset/road position and integrates the track curve over the
; player X movement.
; In:  player A $68/6E/PosX/PosY/32; Track_CurveBuffer
; Out: Race_ram_CameraOffset/ram_FF1E54/56/60/64/68/76/7A/7E/86
; Clobbers: d0-d4/a0
; *************************************************

Race_UpdateCamera:
                btst    #4,(RacePlayerA + RaceActor_ControlFlags).l
                beq.w   .loc_DF0A
                tst.w   (Race_ram_State).l
                bne.w   .loc_DF14
                cmpi.b  #2,(RacePlayerA + STRUCT_OFFSET_6E).l
                bmi.w   .loc_DED2
                move.l  (Race_ram_CameraOffset).l,d0
                asr.l   #2,d0
                sub.l   d0,(Race_ram_CameraOffset).l
                bra.w   .loc_DF14
.loc_DED2:
                move.l  (RacePlayerA + RaceActor_FrameDistance).l,d0
                lsr.l   #4,d0
                btst    #3,(RacePlayerA + RaceActor_StateFlags).l
                beq.w   .loc_DEE8
                neg.l   d0
.loc_DEE8:
                add.l   d0,(Race_ram_CameraOffset).l
                cmpi.l  #$FFFF9000,(Race_ram_CameraOffset).l
                bpl.w   .loc_DF14
                move.l  #$FFFF9000,(Race_ram_CameraOffset).l
                bra.w   .loc_DF14
.loc_DF0A:
                move.l  #0,(Race_ram_CameraOffset).l
.loc_DF14:
                move.w  (RacePlayerA + RaceActor_PosY).l,d0
                asr.w   #1,d0
                move.w  d0,d1
                asr.w   #1,d1
                add.w   d1,d0
                add.w   (ram_FF1E7A).l,d0
                move.w  d0,(ram_FF1E60).l
                bra.w   .loc_DF6E

                move.w  (RacePlayerA + RaceActor_PosY).l,d1
                add.w   (ram_FF1E7A).l,d1
                beq.w   .loc_DF6E
                clr.w   (ram_FF1E86).l
                sub.w   (ram_FF1E60).l,d1
                beq.s   .loc_DF6E
                ext.l   d1
                swap    d1
                asr.l   #1,d1
                add.l   d1,(ram_FF1E86).l
                move.w  (ram_FF1E86).l,d1
                add.w   (ram_FF1E60).l,d1
                move.w  d1,(ram_FF1E60).l
.loc_DF6E:
                move.w  (RacePlayerA + STRUCT_OFFSET_32).l,d0
                ext.l   d0
                asr.l   #1,d0
                add.l   (ram_FF1E7E).l,d0
                addi.l  #$5D,d0
                cmp.l   #$5D,d0
                bpl.w   .loc_DF90
                moveq   #$5D,d0
.loc_DF90:
                move.l  d0,(ram_FF1E64).l
                move.w  (Race_ram_PlayerProgress).l,d1
                move.l  (RacePlayerA + RaceActor_X).l,d0
                sub.l   (ram_FF1E76).l,d0
                sub.l   (Race_ram_CameraOffset).l,d0
                move.l  d0,(Race_ram_PlayerProgress).l
                swap    d0
                move.w  d0,d2
                lea     (Track_CurveBuffer).l,a0
                andi.w  #$FF,d2
                asl.w   #1,d2
                clr.w   d3
                clr.w   d4
                clr.w   d7
                sub.w   d1,d0
                beq.w   .locret_E002
                bpl.w   .loc_DFDA
                neg.w   d0
                move.w  #$FFFF,d7
.loc_DFDA:
                move.b  (a0)+,d1
                ext.w   d1
                add.w   d1,d3
                move.b  (a0)+,d1
                ext.w   d1
                add.w   d1,d4
                addq.w  #1,d2
                dbf     d0,.loc_DFDA
                tst.w   d7
                bpl.w   .loc_DFF6
                neg.w   d3
                neg.w   d4
.loc_DFF6:
                add.w   d3,(ram_FF1E54).l
                add.w   d4,(ram_FF1E56).l
.locret_E002:
                rts
; End of function Race_UpdateCamera


; =============== S U B R O U T I N E =======================================
; black screen if commented out

; *************************************************
; Function Race_BuildVScrollInfo
; Builds the HInt VScroll/raster layer info (sky/horizon/road) for the current frame.
; In:  Race_ram_CurrentVScrollInfo/Alpha, ram_FF3274
; Out: VScroll info buffer
; Clobbers: d0/d1/a0/a1
; *************************************************

Race_BuildVScrollInfo:
                movea.l (Race_ram_CurrentVScrollInfo).l,a0

                move.w  #$8AFF,$80(a0) ; H-Int counter : 255
                move.w  #$9C,d0
                asl.w   #8,d0
                addi.w  #$60,d0
                move.w  d0,$82(a0) ; HvCounter
                move.w  #$873F,$84(a0) ; Backdrop Color: $3F
                move.w  #-8,$86(a0) ; VScroll value : -8
                move.w  #-8,$88(a0) ; VScroll value : -8
                move.w  #$90,$8A(a0) ; next cmd = $90 (end)

                move.w  #$8AFF,$70(a0) ; H-Int counter : 255
                movea.l (Race_ram_CurrentAlpha).l,a1
                move.w  (a1),d0
                cmp.w   #16,d0
                bpl.w   .loc_E050
                move.w  #16,d0
.loc_E050:
                cmp.w   #152,d0
                ble.w   .loc_E05C
                move.w  #152,d0
.loc_E05C:
                move.w  d0,$7E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$72(a0) ; HvCounter
                move.w  #$873E,$74(a0) ; Backdrop Color: $3E
                move.w  #40,$76(a0) ; VScroll value : 40
                move.w  #40,$78(a0) ; VScroll value : 40
                move.w  #$80,$7A(a0) ; next cmd = $80

                move.w  #$8AFF,$60(a0)
                move.w  (ram_FF3274).l,d0
                move.w  d0,d1
                asr.w   #2,d1
                sub.w   d1,d0
                asr.w   #1,d1
                sub.w   d1,d0
                addi.w  #$37,d0
                move.w  d0,d1
                subi.w  #$30,d0
                move.w  d0,$6E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$62(a0)
                move.w  #$873F,$64(a0) ; Backdrop Color: $3F
                neg.w   d1
                addi.w  #$100,d1
                move.w  d1,$68(a0)
                move.w  #$70,$6A(a0) ; next cmd = $70

                move.w  $62(a0),d0
                addi.w  #$400,d0
                sub.w   $72(a0),d0
                bls.w   .loc_E0E4
                sub.w   d0,$62(a0)
                lsr.w   #8,d0
                add.w   d0,$68(a0)
                sub.w   d0,$6E(a0)
.loc_E0E4:
                move.w  #$8AFF,$50(a0)
                move.w  (ram_FF3274).l,d0
                move.w  d0,d1
                asr.w   #2,d1
                sub.w   d1,d0
                addi.w  #$30,d0 ; '0'
                move.w  d0,d1
                neg.w   d1
                subi.w  #$40,d0 ; '@'
                move.w  d0,$5E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$52(a0)
                move.w  #$873F,$54(a0)
                addi.w  #$100,d1
                move.w  d1,$56(a0)
                move.w  $56(a0),$66(a0)
                move.w  #$60,$5A(a0)
                move.w  $5E(a0),d0
                subi.w  #$58,d0
                ble.w   .loc_E14A
                add.w   d0,$56(a0)
                move.w  $56(a0),$66(a0)
                sub.w   d0,$5E(a0)
                asl.w   #8,d0
                sub.w   d0,$52(a0)
.loc_E14A:
                move.w  $7E(a0),d0
                sub.w   $5E(a0),d0
                subi.w  #$40,d0
                ble.w   .loc_E16E
                sub.w   d0,$56(a0)
                move.w  $56(a0),$66(a0)
                add.w   d0,$5E(a0)
                asl.w   #8,d0
                add.w   d0,$52(a0)
.loc_E16E:
                move.w  $52(a0),d0
                addi.w  #$C00,d0
                sub.w   $62(a0),d0
                bls.w   .loc_E192
                sub.w   d0,$52(a0)
                lsr.w   #8,d0
                add.w   d0,$56(a0)
                move.w  $56(a0),$66(a0)
                sub.w   d0,$5E(a0)
.loc_E192:

                move.w  #$8AFF,$40(a0)
                move.w  $5E(a0),d0
                addi.w  #$C,d0
                subi.w  #$38,d0
                move.w  d0,$4E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$42(a0)
                move.w  #$873F,$44(a0)
                move.w  $4E(a0),d0
                neg.w   d0
                move.w  d0,$48(a0)
                move.w  d0,$58(a0)
                move.w  #$50,$4A(a0)

                move.w  #$8AFF,$30(a0)
                move.w  $5E(a0),d0
                subi.w  #$38,d0
                move.w  d0,$3E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$32(a0)
                move.w  #$873F,$34(a0)
                move.w  $3E(a0),d0
                neg.w   d0
                move.w  d0,$36(a0)
                move.w  d0,$46(a0)
                move.w  #$40,$3A(a0)

                move.w  #$8AFF,$20(a0)
                move.w  $4E(a0),d0
                subi.w  #$20,d0
                move.w  d0,$2E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$22(a0)
                move.w  #$873F,$24(a0)
                move.w  $2E(a0),d0
                neg.w   d0
                move.w  d0,$28(a0)
                move.w  d0,$38(a0)
                move.w  #$30,$2A(a0)

                move.w  #$8AFF,$10(a0)
                move.w  $3E(a0),d0
                subi.w  #$20,d0
                move.w  d0,$1E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$12(a0)
                move.w  #$873F,$14(a0)
                move.w  $1E(a0),d0
                neg.w   d0
                move.w  d0,$16(a0)
                move.w  d0,$26(a0)
                move.w  $28(a0),$18(a0)
                move.w  #$20,$1A(a0)

                move.w  #$8A03,(a0) ; H-Int counter : 3
                move.w  $2E(a0),d0
                subi.w  #$20,d0
                move.w  d0,$E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,2(a0)
                move.w  #$873F,4(a0)
                move.w  $E(a0),d0
                neg.w   d0
                move.w  d0,8(a0)
                move.w  d0,8(a0)
                move.w  $16(a0),6(a0)
                move.w  #$10,$A(a0)

.loc_E2AE:
                move.w  $A(a0),d0
                move.w  $E(a0,d0.w),d1
                cmp.w   #0,d1
                bpl.w   .loc_E2E4
                move.w  2(a0,d0.w),2(a0)
                move.w  4(a0,d0.w),4(a0)
                move.w  6(a0,d0.w),6(a0)
                move.w  8(a0,d0.w),8(a0)
                move.w  $A(a0,d0.w),$A(a0)
                move.w  $E(a0,d0.w),$E(a0)
                bra.s   .loc_E2AE

.loc_E2E4:
                move.w  $1A(a0),d0
                move.w  $E(a0,d0.w),d1
                cmp.w   #8,d1
                bgt.w   .loc_E31A
                move.w  2(a0,d0.w),$12(a0)
                move.w  4(a0,d0.w),$14(a0)
                move.w  6(a0,d0.w),$16(a0)
                move.w  8(a0,d0.w),$18(a0)
                move.w  $A(a0,d0.w),$1A(a0)
                move.w  $E(a0,d0.w),$1E(a0)
                bra.s   .loc_E2E4
.loc_E31A:
                move.w  $1E(a0),d1
                cmp.w   #4,d1
                bpl.w   .loc_E32A
                move.w  #4,d1
.loc_E32A:
                move.w  d1,$1E(a0)
                asl.w   #8,d1
                addi.w  #-$A0,d1
                move.w  d1,$12(a0)
                move.w  #$10,$A(a0)
.loc_E33E:
                move.w  $2A(a0),d0
                move.w  $E(a0,d0.w),d1
                move.w  $1E(a0),d2
                addq.w  #8,d2
                cmp.w   d2,d1
                bgt.w   .loc_E378
                move.w  2(a0,d0.w),$22(a0)
                move.w  4(a0,d0.w),$24(a0)
                move.w  6(a0,d0.w),$26(a0)
                move.w  8(a0,d0.w),$28(a0)
                move.w  $A(a0,d0.w),$2A(a0)
                move.w  $E(a0,d0.w),$2E(a0)
                bra.s   .loc_E33E
.loc_E378:
                move.w  $2E(a0),d1
                subq.w  #4,d2
                cmp.w   d2,d1
                bpl.w   .loc_E386
                move.w  d2,d1
.loc_E386:
                move.w  d1,$2E(a0)
                asl.w   #8,d1
                addi.w  #-$A0,d1
                move.w  d1,$22(a0)
                move.w  #$20,$1A(a0)
                move.w  #$8A01,(a0)
                move.w  $2A(a0),d1
                move.w  $E(a0,d1.w),d0
                subq.w  #8,d0
                subq.w  #1,d0
                addi.w  #$8A00,d0
                move.w  d0,$10(a0)
                move.w  $1A(a0),d1
.loc_E3B6:
                move.w  $A(a0,d1.w),d2
                move.w  $A(a0,d2.w),d3
                cmp.w   #$90,d3
                bpl.w   .loc_E3E0
                move.w  2(a0,d3.w),d0
                sub.w   2(a0,d2.w),d0
                lsr.w   #8,d0
                subq.w  #1,d0
                addi.w  #$8A00,d0
                move.w  d0,(a0,d1.w)
                move.w  $A(a0,d1.w),d1
                bra.s   .loc_E3B6
.loc_E3E0:
                move.w  #$8210,$C(a0)
                move.w  #$8403,$E(a0)
                move.w  (RacePlayerA + STRUCT_OFFSET_22).l,d1
                move.w  d1,d2
                move.w  d1,d3
                move.w  d1,d4
                move.w  d1,d5
                move.w  d1,d6
                bpl.w   .loc_E440
                neg.w   d1
                neg.w   d2
                neg.w   d3
                neg.w   d4
                neg.w   d5
                neg.w   d6
                mulu.w  (ram_FF1AE8).l,d1
                mulu.w  (ram_FF1AEA).l,d2
                mulu.w  (ram_FF1AEE).l,d3
                mulu.w  (ram_FF1AF0).l,d4
                mulu.w  (ram_FF1AF2).l,d5
                mulu.w  (ram_FF1AF4).l,d6
                neg.l   d1
                neg.l   d2
                neg.l   d3
                neg.l   d4
                neg.l   d5
                neg.l   d6
                bra.w   .loc_E464


.loc_E440:
                mulu.w  (ram_FF1AE8).l,d1
                mulu.w  (ram_FF1AEA).l,d2
                mulu.w  (ram_FF1AEE).l,d3
                mulu.w  (ram_FF1AF0).l,d4
                mulu.w  (ram_FF1AF2).l,d5
                mulu.w  (ram_FF1AF4).l,d6

.loc_E464:
                sub.l   d1,(ram_FF30EA).l
                sub.l   d2,(ram_FF30EE).l
                sub.l   d3,(ram_FF30F2).l
                sub.l   d4,(ram_FF30F6).l
                sub.l   d5,(ram_FF30FA).l
                sub.l   d6,(ram_FF30FE).l
                addi.l  #$10000,(Race_ram_HIntVScroll).l
                rts
; End of function Race_BuildVScrollInfo


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_BuildHScrollTable
; Builds the HInt HScroll table from the VScroll/alpha state.
; In:  Race_ram_CurrentVScrollInfo/CurrentHScrollTable/Alpha
; Out: HScroll table; ram_FF30EA/EE/F2/F6/FA/FE
; Clobbers: d0/d1/a0-a3
; *************************************************

Race_BuildHScrollTable:
                movea.l (Race_ram_CurrentVScrollInfo).l,a0
                movea.l (Race_ram_CurrentHScrollTable).l,a1
                movea.l (Race_ram_CurrentAlpha).l,a2
                movea.l a1,a3
                move.w  (a2),d0
                asl.w   #2,d0
                adda.w  d0,a3
                subq.w  #4,a3
                move.w  $72(a0),d0
                sub.w   $52(a0),d0
                lsr.w   #8,d0
                subq.w  #1,d0
                move.w  (ram_FF30EA).l,d1
.loc_E4C2:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E4C2
                move.w  $52(a0),d0
                lsr.w   #8,d0
                cmp.w   #$18,d0
                bmi.w   .loc_E4DC
                move.w  #$17,d0
.loc_E4DC:
                move.l  (Race_ram_HIntVScroll).l,d1
                asr.l   #1,d1
                add.l   (ram_FF30FA).l,d1
                swap    d1
.loc_E4EC:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E4EC
                move.w  $52(a0),d0
                lsr.w   #8,d0
                addq.w  #1,d0
                subi.w  #$18,d0
                bmi.w   .loc_E51A
                move.l  (Race_ram_HIntVScroll).l,d1
                add.l   (ram_FF30F2).l,d1
                swap    d1
.loc_E512:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E512
.loc_E51A:
                movea.l a1,a3
                move.w  (a2),d0
                asl.w   #2,d0
                adda.w  d0,a3
                subq.w  #2,a3
                move.w  $72(a0),d0
                sub.w   $62(a0),d0
                lsr.w   #8,d0
                subq.w  #1,d0
                move.w  (ram_FF30EE).l,d1
.loc_E536:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E536
                move.w  $62(a0),d0
                sub.w   $52(a0),d0
                lsr.w   #8,d0
                subi.w  #$D,d0
                bmi.w   .loc_E55C
                move.w  #0,d1
.loc_E554:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E554
.loc_E55C:
                move.w  $52(a0),d0
                lsr.w   #8,d0
                addi.w  #$C,d0
                cmp.w   #$18,d0
                bmi.w   .loc_E572
                move.w  #$17,d0
.loc_E572:
                move.l  (Race_ram_HIntVScroll).l,d1
                asr.l   #2,d1
                add.l   (ram_FF30FE).l,d1
                swap    d1
.loc_E582:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E582
                move.w  $52(a0),d0
                lsr.w   #8,d0
                addi.w  #$D,d0
                subi.w  #$18,d0
                bmi.w   .loc_E5BC
                move.l  (Race_ram_HIntVScroll).l,d1
                asr.l   #1,d1
                add.l   (Race_ram_HIntVScroll).l,d1
                asr.l   #1,d1
                add.l   (ram_FF30F6).l,d1
                swap    d1
.loc_E5B4:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E5B4
.loc_E5BC:
                movea.l a1,a3
                adda.w  #$260,a3
                move.w  #$2F,d0
.loc_E5C6:
                move.l  #0,(a3)+
                dbf     d0,.loc_E5C6
                move.l  (RacePlayerA + RaceActor_X).l,d1
                asr.l   #8,d1
                asr.l   #1,d1
                andi.l  #$C0,d1
                neg.w   d1
                move.w  #$F,d0
.loc_E5E6:
                move.l  d1,(a3)+
                dbf     d0,.loc_E5E6
                rts
; End of function Race_BuildHScrollTable


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_UpdateNearestOpponent
; Finds the nearest ahead/behind actor and derives the engine-audio values.
; In:  ram_FF1A08 actor list; player/actor positions
; Out: Race_ram_NearestBehindDistance/E4, Race_ram_NearestBehindIndex/B2/B0/B4, Race_ram_PlayerPlace
; Clobbers: d0-d4/a0-a4
; *************************************************

Race_UpdateNearestOpponent:
                movem.l d0-d3/a0-a4,-(sp)
                btst    #7,(RacePlayerA + RaceActor_ControlFlags).l
                bne.w   .loc_E72C
                move.l  #$7FFFFFFF,(Race_ram_NearestAheadDistance).l
                move.l  #$80000000,(Race_ram_NearestBehindDistance).l
                lea     (ram_FF1A08).l,a0
                movea.l (a0)+,a1
                move.l  4(a1),d0
                lea     (Race_ram_OpponentFreeList).l,a2
                move.w  (a2)+,d1
                move.w  d1,d2
                beq.w   .loc_E642
                subq.w  #1,d2

.loc_E62E:
                cmpi.l  #ram_FF1F2A,(a2)+
                bne.w   .loc_E63A
                subq.w  #1,d1

.loc_E63A:
                dbf     d2,.loc_E62E
                bra.w   *+4


.loc_E642:
                addq.w  #1,d1
                move.w  #1,d4

.loc_E648:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_E6A8
                move.l  d0,d2
                move.l  4(a2),d3
                sub.l   d3,d2
                bcc.w   .loc_E68A
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_E66C
                addq.w  #1,d1

.loc_E66C:
                cmp.l   (Race_ram_NearestBehindDistance).l,d2
                bmi.s   .loc_E648
                move.l  d2,(Race_ram_NearestBehindDistance).l
                move.b  $71(a2),d3
                ext.w   d3
                move.w  d3,(Race_ram_NearestBehindIndex).l
                movea.l a2,a3
                bra.s   .loc_E648


.loc_E68A:
                cmp.l   (Race_ram_NearestAheadDistance).l,d2
                bpl.s   .loc_E648
                move.l  d2,(Race_ram_NearestAheadDistance).l
                move.b  $71(a2),d3
                ext.w   d3
                move.w  d3,(Race_ram_NearestAheadIndex).l
                movea.l a2,a4
                bra.s   .loc_E648


.loc_E6A8:
                cmp.w   #$A,d1
                bcs.w   .loc_E6B8
                subi.w  #$A,d1
                ori.w   #$10,d1

.loc_E6B8:
                move.w  d1,(Race_ram_PlayerPlace).l
                move.l  (Race_ram_NearestAheadDistance).l,d1
                cmp.l   #$7FFFFFFF,d1
                bne.w   .loc_E6E2
                move.w  #$FFFF,(Race_ram_NearestAheadIndex).l
                move.w  #0,(Race_ram_NearestAheadSpeed).l
                bra.w   .loc_E6F4


.loc_E6E2:
                move.w  $12(a4),d0
                beq.w   .loc_E6EE
                divu.w  d0,d1
                move.w  d1,d0

.loc_E6EE:
                move.w  d0,(Race_ram_NearestAheadSpeed).l

.loc_E6F4:
                move.l  (Race_ram_NearestBehindDistance).l,d1
                cmp.l   #$80000000,d1
                bne.w   .loc_E718
                move.w  #$FFFF,(Race_ram_NearestBehindIndex).l
                move.w  #0,(Race_ram_NearestBehindSpeed).l
                bra.w   .loc_E72C


.loc_E718:
                neg.l   d1
                move.w  $12(a1),d0
                beq.w   .loc_E726
                divu.w  d0,d1
                move.w  d1,d0

.loc_E726:
                move.w  d0,(Race_ram_NearestBehindSpeed).l

.loc_E72C:
                movem.l (sp)+,d0-d3/a0-a4
                rts
; End of function Race_UpdateNearestOpponent


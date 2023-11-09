sub_8FB4:
                cmp.l   #0,d0
                bne.w   @loc_8FCC
                cmp.l   #0,d1
                bne.w   @loc_8FCC
                bra.w   @locret_9140
@loc_8FCC:
                move.w  Animation_ram_TileIndex,d2
                asl.w   #5,d2
                move.w  d2,ram_FF0D26
                clr.w   ram_FF1336
                clr.w   ram_FF132E
                clr.w   ram_FF1330
                lea     ram_FF0D2E,a2
                move.l  d0,d3
                bsr.w   sub_9142
                tst.w   d6
                bpl.w   @loc_900A
                move.w  #1,ram_FFDE62
                bra.w   @locret_9140
@loc_900A:
                move.w  d6,ram_FF132E
                lea     ram_FF102E,a2
                move.l  d1,d3
                bsr.w   sub_91F0
                subq.w  #1,d6
                bgt.w   @loc_902E
                move.w  #1,ram_FFDE62
                bra.w   @locret_9140
@loc_902E:
                move.w  d6,ram_FF1330
                move.w  (a0)+,ram_FFDE5E
                tst.w   ram_FF133E
                bmi.w   @loc_904E
                move.w  ram_FF133E,ram_FFDE5E
@loc_904E:
                move.l  a0,ram_FF0D2A
                tst.w   ram_FF133C
                beq.w   @loc_9074
                clr.w   d1
                move.w  ram_FF1332,d0
                move.b  -3(a0),d1
                subq.w  #1,d1
                mulu.w  d1,d0
                add.l   d0,ram_FF0D2A
@loc_9074:
                tst.w   ram_FF1354
                beq.w   @loc_909A
                move.w  ram_FF1356,d1
                sub.w   d1,ram_FFDE6E
                move.w  ram_FF1358,d0
                sub.w   d0,ram_FFDE70
                bra.w   @loc_90B2
@loc_909A:
                move.w  ram_FF1336,d1
                sub.w   d1,ram_FFDE6E
                move.w  ram_FF1330,d0
                sub.w   d0,ram_FFDE70
@loc_90B2:
                move.w  ram_FFDE70,d1
                cmp.w   ram_FF136A,d1
                bpl.w   @locret_9140
                move.w  ram_FF1330,d0
                addq.w  #1,d0
                move.w  d0,d1
                add.w   ram_FFDE70,d1
                cmp.w   ram_FF136A,d1
                bmi.w   @loc_90EA
                sub.w   ram_FF136A,d1
                sub.w   d1,ram_FF1330
                sub.w   d1,d0
@loc_90EA:
                move.w  d0,d1
                andi.w  #$FFF8,d1
                andi.w  #7,d0
                beq.w   @loc_90FA
                addq.w  #8,d1
@loc_90FA:
                move.w  ram_FF132E,d0
                addq.w  #1,d0
                asl.w   #3,d0
                bsr.w   sub_5760
                cmpi.w  #$FFFF,ram_FFDE62
                beq.w   @locret_9140
                bsr.w   sub_9306
                move.w  ram_FF1330,d2
                addq.w  #1,d2
                andi.w  #7,d2
                move.w  #7,d3
                sub.w   d2,d3
                move.w  d3,ram_FF0D28
                cmpi.w  #7,ram_FF0D28
                beq.w   @locret_9140
                bsr.w   sub_93D2
@locret_9140:
                rts
; End of function sub_8FB4

; =============== S U B R O U T I N E =======================================


sub_9142:
                clr.w   d2
                clr.l   d4
                clr.w   d5
                clr.w   d6
                move.w  ram_FF135E,d0
                beq.w   @loc_9164
                bmi.w   @loc_9162
                move.w  d0,d7
                move.w  #0,d0
                bra.w   @loc_9168
@loc_9162:
                neg.w   d0
@loc_9164:
                move.w  #$7FFF,d7
@loc_9168:
                move.b  (a0)+,d2
                lsr.w   #1,d2
                bcc.w   @loc_9172
                addq.w  #1,d2
@loc_9172:
                addq.w  #1,d2
                move.w  d2,ram_FF1332
                subq.w  #2,d2
@loc_917C:
                addq.w  #1,d5
                add.l   d3,d4
                cmp.l   #$10000,d4
                blt.w   @loc_91B0
@loc_918A:
                subq.w  #1,d0
                bpl.w   @loc_91A2
                move.w  d5,(a2)+
                clr.w   d5
                addq.w  #1,d6
                subq.w  #1,d7
                bpl.w   @loc_91A2
                move.w  d2,d5
                bra.w   @loc_91B4
@loc_91A2:
                subi.l  #$10000,d4
                cmp.l   #$10000,d4
                bge.s   @loc_918A
@loc_91B0:
                dbf     d2,@loc_917C
@loc_91B4:
                move.w  d6,ram_FF1336
                move.w  d5,(a2)+
                move.w  d6,d2
                andi.w  #3,d2
                cmp.w   #3,d2
                beq.w   @loc_91DC
                move.w  #3,d3
                sub.w   d2,d3
                subq.w  #1,d3
                clr.w   d5
@loc_91D4:
                move.w  d5,(a2)+
                addq.w  #1,d6
                dbf     d3,@loc_91D4
@loc_91DC:
                tst.w   d6
                bne.w   @loc_91E8
                move.w  #$FFFF,d6
                rts
@loc_91E8:
                addq.w  #1,d6
                lsr.w   #2,d6
                subq.w  #1,d6
                rts
; End of function sub_9142



; =============== S U B R O U T I N E =======================================


sub_91F0:
                move.l  #$10000,d0
                clr.w   d2
                clr.l   d4
                move.w  ram_FF1332,d7
                move.w  ram_FF1340,d1
                move.w  #1,d5
                clr.w   d6
                move.b  (a0)+,d2
                subq.w  #1,d2
@loc_9210:
                tst.w   d1
                ble.w   @loc_921C
                subq.w  #1,d1
                bra.w   @loc_9248
@loc_921C:
                add.l   d3,d4
                cmp.l   d0,d4
                blt.w   @loc_9248
@loc_9224:
                move.w  d5,(a2)+
                move.w  #1,d5
                tst.w   ram_FF133C
                beq.w   @loc_9238
                sub.w   d7,d5
                sub.w   d7,d5
@loc_9238:
                addq.w  #1,d6
                sub.l   d0,d4
                cmp.l   d0,d4
                blt.w   @loc_925A
                sub.w   d7,-2(a2)
                bra.s   @loc_9224
@loc_9248:
                tst.w   ram_FF133C
                beq.w   @loc_9258
                sub.w   d7,d5
                bra.w   @loc_925A
@loc_9258:
                add.w   d7,d5
@loc_925A:
                dbf     d2,@loc_9210
                move.w  d6,d2
                andi.w  #7,d2
                move.w  #7,d3
                sub.w   d2,d3
                move.w  d3,ram_FF0D28
                rts
; End of function sub_91F0

; =============== S U B R O U T I N E =======================================


sub_9272:
                clr.w   d2
                clr.l   d4
                move.w  ram_FF1340,d1
                move.w  #1,d5
                clr.w   d6
                move.b  (a0)+,d2
                subq.w  #1,d2
@loc_9286:
                tst.w   d1
                ble.w   @loc_9292
                subq.w  #1,d1
                bra.w   @loc_92D4
@loc_9292:
                add.l   d3,d4
                cmp.l   #$10000,d4
                blt.w   @loc_92D4
@loc_929E:
                move.w  d5,(a2)+
                move.w  #1,d5
                tst.w   ram_FF133C
                beq.w   @loc_92BA
                sub.w   ram_FF1332,d5
                sub.w   ram_FF1332,d5
@loc_92BA:
                addq.w  #1,d6
                subi.l  #$10000,d4
                cmp.l   #$10000,d4
                blt.w   @loc_92EE
                sub.w   ram_FF1332,d5
                bra.s   @loc_929E
@loc_92D4:
                tst.w   ram_FF133C
                beq.w   @loc_92E8
                sub.w   ram_FF1332,d5
                bra.w   @loc_92EE
@loc_92E8:
                add.w   ram_FF1332,d5
@loc_92EE:
                dbf     d2,@loc_9286
                move.w  d6,d2
                andi.w  #7,d2
                move.w  #7,d3
                sub.w   d2,d3
                move.w  d3,ram_FF0D28
                rts
; End of function sub_9272



; =============== S U B R O U T I N E =======================================


sub_9306:
                movea.l ram_FF0D2A,a0
                movea.l Race_ram_CurrentSpriteTileArray,a4
                adda.w  ram_FF0D26,a4
                move.w  #$1F,d4
                lea     ram_FF102E,a3
                move.w  ram_FF1330,d1
                cmp.w   #$F,d1
                move.w  ram_FFDE6A,d3
                move.w  ram_FFDE68,d5
@loc_9338:
                movea.l a4,a1
                lea     ram_FF0D2E,a2
                move.w  ram_FF132E,d2
@loc_9346:
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                dbf     d2,@loc_935E
                bra.w   @loc_93B0
@loc_935E:
                adda.w  d3,a1
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                dbf     d2,@loc_9378
                bra.w   @loc_93B0
@loc_9378:
                adda.w  d3,a1
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                dbf     d2,@loc_9392
                bra.w   @loc_93B0
@loc_9392:
                adda.w  d3,a1
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                dbf     d2,@loc_93AC
                bra.w   @loc_93B0
@loc_93AC:
                adda.w  d3,a1
                bra.s   @loc_9346
@loc_93B0:
                addq.w  #4,a4
                dbf     d4,@loc_93CA
                cmp.w   #$1F,d1
                bcc.w   @loc_93C4
                move.w  ram_FFDE66,d3
@loc_93C4:
                move.w  #$1F,d4
                adda.w  d5,a4
@loc_93CA:
                adda.w  (a3)+,a0
                dbf     d1,@loc_9338
                rts
; End of function sub_9306



; =============== S U B R O U T I N E =======================================


sub_93D2:
                clr.w   d0
                move.w  ram_FF0D28,d1
                move.w  ram_FFDE66,d3
@loc_93E0:
                movea.l a4,a1
                move.w  ram_FF132E,d2
@loc_93E8:
                move.w  d0,(a1)+
                move.w  d0,(a1)+
                dbf     d2,@loc_93F4
                bra.w   @loc_9422
@loc_93F4:
                adda.w  d3,a1
                move.w  d0,(a1)+
                move.w  d0,(a1)+
                dbf     d2,@loc_9402
                bra.w   @loc_9422
@loc_9402:
                adda.w  d3,a1
                move.w  d0,(a1)+
                move.w  d0,(a1)+
                dbf     d2,@loc_9410
                bra.w   @loc_9422
@loc_9410:
                adda.w  d3,a1
                move.w  d0,(a1)+
                move.w  d0,(a1)+
                dbf     d2,@loc_941E
                bra.w   @loc_9422
@loc_941E:
                adda.w  d3,a1
                bra.s   @loc_93E8
@loc_9422:
                addq.w  #4,a4
                dbf     d1,@loc_93E0
                rts
; End of function sub_93D2

; =============== S U B R O U T I N E =======================================
; called from race code

sub_942A:
                movea.l Race_ram_CurrentSpriteAttributeTable,a0
                lea     ram_FFD37C,a0
                lea     ram_FF1D50,a1
                move.w  #0,ram_FFDE62
@loop:
                move.w  (a1)+,d0
                cmp.w   #$FFFF,d0
                beq.w   @return
                
                mulu.w  #$14,d0
                lea     ram_FFD37C,a0
                adda.w  d0,a0
                movem.l a0-a1,-(sp)
                move.w  Animation_ram_TileIndex,ram_FF1362
                move.w  Animation_ram_SpriteIndex,ram_FF1364
                bsr.w   sub_9484
                movem.l (sp)+,a0-a1
                adda.l  #$14,a0
                bra.s   @loop
@return:
                rts
; End of function sub_942A



; =============== S U B R O U T I N E =======================================


sub_9484:
                move.w  #0,ram_FFDE62
                move.w  #0,ram_FF133A
                clr.l   d0
                move.w  (a0),ram_FFDE6E
                move.w  ram_FFDE6E,ram_FF1342
                move.w  2(a0),ram_FFDE70
                move.w  ram_FFDE70,ram_FF1344
                move.w  4(a0),d0
                asl.l   #2,d0
                move.l  d0,ram_FF1350
                move.w  6(a0),ram_FF136A
                move.w  $A(a0),d1
                bpl.w   @loc_94DC
                move.w  #1,ram_FF133A
@loc_94DC:
                move.w  #0,ram_FF133C
                move.w  d1,d7
                andi.w  #$3000,d7
                asl.w   #1,d7
                move.w  d7,ram_FF133E
                move.w  8(a0),d2
                move.w  $12(a0),d3
                move.l  a0,-(sp)
                lea     unk_3BF1A,a1
                asl.w   #2,d2
                movea.l (a1,d2.w),a2
                move.l  a2,ram_FF1348
                move.w  #0,ram_FF1354
                btst    #7,$B(a0)
                beq.w   @loc_962C
@loc_9520:
                move.w  #0,ram_FF135E
                move.w  #1,ram_FF1354
                bsr.w   sub_978C
                addq.l  #2,ram_FF1348
                move.w  d6,ram_FF1358
                move.w  d3,-(sp)
                bsr.w   sub_97BC
                move.w  d5,ram_FF1356
                move.w  d1,ram_FF135E
                move.w  (sp)+,d3
                tst.w   ram_FFDE62
                beq.w   @loc_958E
                move.w  #0,ram_FFDE62
                tst.w   d3
                bne.w   @loc_9572
                addq.w  #4,sp
                bra.w   @locret_978A
@loc_9572:
                asl.w   #2,d3
                movea.l (a1,d3.w),a2
                move.l  a2,ram_FF1348
                move.w  #0,d3
                move.l  #0,ram_FF134C
                bra.s   @loc_9520
@loc_958E:
                tst.w   d3
                beq.w   @loc_9640
                asl.w   #2,d3
                movea.l (a1,d3.w),a2
                move.l  a2,ram_FF134C
                bsr.w   sub_978C
                addq.l  #2,ram_FF134C
                movea.l ram_FF134C,a2
                subq.w  #1,d6
                move.w  d6,ram_FF135C
                bsr.w   sub_97BC
                move.w  d5,ram_FF135A
                move.w  d1,ram_FF1360
                tst.w   ram_FFDE62
                beq.w   @loc_95E4
                move.w  #0,ram_FFDE62
                move.l  #0,ram_FF134C
@loc_95E4:
                movea.l ram_FF1348,a0
                move.b  -1(a0),d5
                move.b  -1(a2),d6
                sub.b   1(a2),d6
                addq.w  #1,d6
                sub.b   d6,d5
                ext.w   d5
                bpl.w   @loc_960E
                move.w  #0,d5
                move.w  d5,ram_FF1340
                bra.w   @loc_9652
@loc_960E:
                move.w  d5,ram_FF1340
                move.l  ram_FF1350,d2
                lsr.l   #2,d2
                mulu.w  d2,d5
                asl.l   #2,d5
                swap    d5
                sub.w   d5,ram_FF1358
                bra.w   @loc_9652
@loc_962C:
                bsr.w   sub_9836
                tst.w   ram_FFDE62
                beq.w   @loc_9640
                addq.w  #4,sp
                bra.w   @locret_978A
@loc_9640:
                move.w  #0,ram_FF1340
                move.l  #0,ram_FF134C
@loc_9652:
                movea.l ram_FF1348,a0
                move.l  d0,d1
                move.w  Animation_ram_SpriteIndex,-(sp)
@loc_9660:
                move.w  #0,ram_FF1366
                bsr.w   sub_8FB4
                tst.w   ram_FF1366
                beq.w   @loc_9690
                move.w  ram_FF1362,Animation_ram_TileIndex
                move.w  ram_FF1364,Animation_ram_SpriteIndex
                addq.w  #6,sp
                bra.w   @locret_978A
@loc_9690:
                tst.l   ram_FF134C
                beq.w   @loc_96F0
                movea.l ram_FF134C,a0
                move.l  ram_FF1350,d0
                move.w  d0,d1
                move.w  ram_FF1344,ram_FFDE70
                move.w  ram_FF1342,ram_FFDE6E
                move.w  ram_FF135A,ram_FF1356
                move.w  ram_FF135C,ram_FF1358
                move.w  ram_FF1360,ram_FF135E
                move.w  #0,ram_FF1340
                move.l  #0,ram_FF134C
                bra.w   @loc_9660
@loc_96F0:
                move.w  (sp)+,d1
                movea.l (sp)+,a0
                move.b  $A(a0),d7
                andi.w  #7,d7
                beq.w   @locret_978A
                tst.w   ram_FF135E
                bne.w   @locret_978A
                movea.l Race_ram_CurrentSpriteAttributeTable,a1
                move.w  d1,d2
                asl.w   #3,d2
                adda.w  d2,a1
                move.w  Animation_ram_SpriteIndex,d3
                move.w  d3,d2
                move.w  d3,d0
                sub.w   d1,d0
                beq.w   @locret_978A
                move.w  d3,d1
                movea.l Race_ram_CurrentSpriteAttributeTable,a2
                asl.w   #3,d2
                adda.w  d2,a2
                move.w  $C(a0),d3
                move.w  d0,d2
                subq.w  #1,d0
                subq.w  #1,d7
@loc_973C:
                move.b  d1,-5(a2)
                move.w  (a1)+,(a2)+
                move.w  (a1)+,(a2)+
                move.w  (a1)+,(a2)+
                move.w  (a1)+,(a2)+
                sub.w   d3,-2(a2)
                cmpi.w  #$FFC0,-2(a2)
                bpl.w   @loc_9760
                cmpi.w  #$FE20,-2(a2)
                bpl.w   @loc_9768
@loc_9760:
                subq.w  #8,a1
                subq.w  #8,a2
                bra.w   @loc_9772
@loc_9768:
                addq.w  #1,d1
                cmp.w   #$50,d1
                bpl.w   @loc_9784
@loc_9772:
                dbf     d0,@loc_973C
                move.w  d1,Animation_ram_SpriteIndex
                move.w  d2,d0
                subq.w  #1,d0
                dbf     d7,@loc_973C
@loc_9784:
                move.b  #0,-5(a2)
@locret_978A:
                rts
; End of function sub_9484



; =============== S U B R O U T I N E =======================================


sub_978C:
                move.b  (a2),d5
                ext.w   d5
                move.b  1(a2),d6
                ext.w   d6
                move.l  d0,d2
                lsr.l   #2,d2
                btst    #$F,$A(a0)
                beq.w   @loc_97AE
                move.w  d5,d7
                move.b  2(a2),d5
                ext.w   d5
                sub.w   d7,d5
@loc_97AE:
                mulu.w  d2,d5
                asl.l   #2,d5
                swap    d5
                mulu.w  d2,d6
                asl.l   #2,d6
                swap    d6
                rts
; End of function sub_978C



; =============== S U B R O U T I N E =======================================


sub_97BC:
                move.b  (a2),d1
                ext.w   d1
                move.l  d0,d3
                lsr.l   #2,d3
                mulu.w  d3,d1
                asl.l   #2,d1
                swap    d1
                move.w  (a0),d2
                move.w  d1,d3
                sub.w   d5,d1
                add.w   d2,d1
                addi.w  #$C0,d1
                bmi.w   @loc_97F8
                cmp.w   d3,d1
                bpl.w   @loc_982C
                btst    #$F,$A(a0)
                beq.w   @loc_97F0
                neg.w   d1
                bra.w   @loc_9828
@loc_97F0:
                sub.w   d1,d3
                exg     d1,d3
                bra.w   @loc_9828
@loc_97F8:
                exg     d1,d2
                sub.w   d5,d1
                addi.w  #$200,d1
                bpl.w   @loc_9820
                move.w  d3,d2
                neg.w   d2
                cmp.w   d2,d1
                ble.w   @loc_982C
                add.w   d1,d5
                btst    #$F,$A(a0)
                beq.w   @loc_9828
                add.w   d3,d1
                bra.w   @loc_9828
@loc_9820:
                move.w  #0,d1
                bra.w   @locret_982A
@loc_9828:
                asr.w   #1,d1
@locret_982A:
                rts
@loc_982C:
                move.w  #1,ram_FFDE62
                rts
; End of function sub_97BC



; =============== S U B R O U T I N E =======================================


sub_9836:
                move.b  (a2),d1
                ext.w   d1
                move.l  d0,d2
                lsr.l   #2,d2
                mulu.w  d2,d1
                asl.l   #2,d1
                swap    d1
                move.w  (a0),d2
                move.w  d1,d3
                lsr.w   #1,d1
                add.w   d2,d1
                addi.w  #$C0,d1
                bmi.w   @loc_9872
                cmp.w   d3,d1
                bpl.w   @loc_98B8
                btst    #$F,$A(a0)
                beq.w   @loc_986A
                neg.w   d1
                bra.w   @loc_98AE
@loc_986A:
                sub.w   d1,d3
                exg     d1,d3
                bra.w   @loc_98AE
@loc_9872:
                move.w  d3,d1
                exg     d1,d2
                lsr.w   #1,d2
                sub.w   d2,d1
                addi.w  #$200,d1
                bpl.w   @loc_98A6
                move.w  d3,d2
                neg.w   d2
                cmp.w   d2,d1
                ble.w   @loc_98B8
                move.w  d1,d2
                asr.w   #1,d2
                sub.w   d2,ram_FFDE6E
                btst    #$F,$A(a0)
                beq.w   @loc_98AE
                add.w   d3,d1
                bra.w   @loc_98AE
@loc_98A6:
                move.w  #0,d1
                bra.w   @loc_98B0
@loc_98AE:
                asr.w   #1,d1
@loc_98B0:
                move.w  d1,ram_FF135E
                rts
@loc_98B8:
                move.w  #1,ram_FFDE62
                rts
; End of function sub_9836
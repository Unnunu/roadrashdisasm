; *************************************************
; road_render.asm - race road/object renderer
; ROM range: $8FB4-$98C1
; Status:    partially analyzed (object list/records confirmed; shape math TODO)
; API:       Road_DrawObjects (called from race.asm), Road_DrawObject, Road_DrawStrip, helpers
; *************************************************

; *************************************************
; Function Road_DrawStrip
; Builds the road strip/tile columns for the object and the rider/vehicle sprite chain.
; In:  d0, d1 - road-edge geometry; a0 - shape data
; Out: road tiles in Race_ram_CurrentSpriteTileArray; SAT chain via RiderSprites_Build
; Clobbers: d0-d7, a0-a4
; *************************************************

Road_DrawStrip:
                cmp.l   #0,d0
                bne.w   .loc_8FCC
                cmp.l   #0,d1
                bne.w   .loc_8FCC
                bra.w   .locret_9140
.loc_8FCC:
                move.w  (Animation_ram_TileIndex).l,d2
                asl.w   #5,d2
                move.w  d2,(ram_FF0D26).l
                clr.w   (ram_FF1336).l
                clr.w   (ram_FF132E).l
                clr.w   (ram_FF1330).l
                lea     (ram_FF0D2E).l,a2
                move.l  d0,d3
                bsr.w   Road_InterpolateLeftEdge
                tst.w   d6
                bpl.w   .loc_900A
                move.w  #1,(ram_FFDE62).l
                bra.w   .locret_9140
.loc_900A:
                move.w  d6,(ram_FF132E).l
                lea     (ram_FF102E).l,a2
                move.l  d1,d3
                bsr.w   Road_InterpolateRightEdge
                subq.w  #1,d6
                bgt.w   .loc_902E
                move.w  #1,(ram_FFDE62).l
                bra.w   .locret_9140
.loc_902E:
                move.w  d6,(ram_FF1330).l
                move.w  (a0)+,(ram_FFDE5E).l
                tst.w   (ram_FF133E).l
                bmi.w   .loc_904E
                move.w  (ram_FF133E).l,(ram_FFDE5E).l
.loc_904E:
                move.l  a0,(ram_FF0D2A).l
                tst.w   (ram_FF133C).l
                beq.w   .loc_9074
                clr.w   d1
                move.w  (ram_FF1332).l,d0
                move.b  -3(a0),d1
                subq.w  #1,d1
                mulu.w  d1,d0
                add.l   d0,(ram_FF0D2A).l
.loc_9074:
                tst.w   (ram_FF1354).l
                beq.w   .loc_909A
                move.w  (ram_FF1356).l,d1
                sub.w   d1,(ram_FFDE6E).l
                move.w  (ram_FF1358).l,d0
                sub.w   d0,(ram_FFDE70).l
                bra.w   .loc_90B2
.loc_909A:
                move.w  (ram_FF1336).l,d1
                sub.w   d1,(ram_FFDE6E).l
                move.w  (ram_FF1330).l,d0
                sub.w   d0,(ram_FFDE70).l
.loc_90B2:
                move.w  (ram_FFDE70).l,d1
                cmp.w   (ram_FF136A).l,d1
                bpl.w   .locret_9140
                move.w  (ram_FF1330).l,d0
                addq.w  #1,d0
                move.w  d0,d1
                add.w   (ram_FFDE70).l,d1
                cmp.w   (ram_FF136A).l,d1
                bmi.w   .loc_90EA
                sub.w   (ram_FF136A).l,d1
                sub.w   d1,(ram_FF1330).l
                sub.w   d1,d0
.loc_90EA:
                move.w  d0,d1
                andi.w  #$FFF8,d1
                andi.w  #7,d0
                beq.w   .loc_90FA
                addq.w  #8,d1
.loc_90FA:
                move.w  (ram_FF132E).l,d0
                addq.w  #1,d0
                asl.w   #3,d0
                bsr.w   RiderSprites_Build
                cmpi.w  #$FFFF,(ram_FFDE62).l
                beq.w   .locret_9140
                bsr.w   Road_WriteTileColumns
                move.w  (ram_FF1330).l,d2
                addq.w  #1,d2
                andi.w  #7,d2
                move.w  #7,d3
                sub.w   d2,d3
                move.w  d3,(ram_FF0D28).l
                cmpi.w  #7,(ram_FF0D28).l
                beq.w   .locret_9140
                bsr.w   Road_ClearEdgeTiles
.locret_9140:
                rts
; End of function Road_DrawStrip

; *************************************************
; Function Road_InterpolateLeftEdge
; Interpolates the left road edge into the ram_FF0D2E strip array.
; In:  a0 - shape data; d3 - scale; ram_FF135E edge offset
; Out: ram_FF0D2E strips, ram_FF1332/1336; d6 - strip count
; Clobbers: d0/d2/d4-d7, a2
; *************************************************

Road_InterpolateLeftEdge:
                clr.w   d2
                clr.l   d4
                clr.w   d5
                clr.w   d6
                move.w  (ram_FF135E).l,d0
                beq.w   .loc_9164
                bmi.w   .loc_9162
                move.w  d0,d7
                move.w  #0,d0
                bra.w   .loc_9168
.loc_9162:
                neg.w   d0
.loc_9164:
                move.w  #$7FFF,d7
.loc_9168:
                move.b  (a0)+,d2
                lsr.w   #1,d2
                bcc.w   .loc_9172
                addq.w  #1,d2
.loc_9172:
                addq.w  #1,d2
                move.w  d2,(ram_FF1332).l
                subq.w  #2,d2
.loc_917C:
                addq.w  #1,d5
                add.l   d3,d4
                cmp.l   #$10000,d4
                blt.w   .loc_91B0
.loc_918A:
                subq.w  #1,d0
                bpl.w   .loc_91A2
                move.w  d5,(a2)+
                clr.w   d5
                addq.w  #1,d6
                subq.w  #1,d7
                bpl.w   .loc_91A2
                move.w  d2,d5
                bra.w   .loc_91B4
.loc_91A2:
                subi.l  #$10000,d4
                cmp.l   #$10000,d4
                bge.s   .loc_918A
.loc_91B0:
                dbf     d2,.loc_917C
.loc_91B4:
                move.w  d6,(ram_FF1336).l
                move.w  d5,(a2)+
                move.w  d6,d2
                andi.w  #3,d2
                cmp.w   #3,d2
                beq.w   .loc_91DC
                move.w  #3,d3
                sub.w   d2,d3
                subq.w  #1,d3
                clr.w   d5
.loc_91D4:
                move.w  d5,(a2)+
                addq.w  #1,d6
                dbf     d3,.loc_91D4
.loc_91DC:
                tst.w   d6
                bne.w   .loc_91E8
                move.w  #$FFFF,d6
                rts
.loc_91E8:
                addq.w  #1,d6
                lsr.w   #2,d6
                subq.w  #1,d6
                rts
; End of function Road_InterpolateLeftEdge



; *************************************************
; Function Road_InterpolateRightEdge
; Interpolates the right road edge into the ram_FF102E strip array.
; In:  a0 - shape data; d3 - scale; ram_FF1332/1340
; Out: ram_FF102E strips, ram_FF0D28; d6 - strip count
; Clobbers: d0-d7, a2
; *************************************************

Road_InterpolateRightEdge:
                move.l  #$10000,d0
                clr.w   d2
                clr.l   d4
                move.w  (ram_FF1332).l,d7
                move.w  (ram_FF1340).l,d1
                move.w  #1,d5
                clr.w   d6
                move.b  (a0)+,d2
                subq.w  #1,d2
.loc_9210:
                tst.w   d1
                ble.w   .loc_921C
                subq.w  #1,d1
                bra.w   .loc_9248
.loc_921C:
                add.l   d3,d4
                cmp.l   d0,d4
                blt.w   .loc_9248
.loc_9224:
                move.w  d5,(a2)+
                move.w  #1,d5
                tst.w   (ram_FF133C).l
                beq.w   .loc_9238
                sub.w   d7,d5
                sub.w   d7,d5
.loc_9238:
                addq.w  #1,d6
                sub.l   d0,d4
                cmp.l   d0,d4
                blt.w   .loc_925A
                sub.w   d7,-2(a2)
                bra.s   .loc_9224
.loc_9248:
                tst.w   (ram_FF133C).l
                beq.w   .loc_9258
                sub.w   d7,d5
                bra.w   .loc_925A
.loc_9258:
                add.w   d7,d5
.loc_925A:
                dbf     d2,.loc_9210
                move.w  d6,d2
                andi.w  #7,d2
                move.w  #7,d3
                sub.w   d2,d3
                move.w  d3,(ram_FF0D28).l
                rts
; End of function Road_InterpolateRightEdge

; *************************************************
; Function Road_InterpolateRightEdgeAlt
; Alternate right-edge interpolation with fixed $10000 scaling; no direct caller.
; In:  a0 - shape data; d3 - scale
; Out: ram_FF102E strips, ram_FF0D28
; Clobbers: d1/d2/d4-d6, a2
; *************************************************

Road_InterpolateRightEdgeAlt:
                clr.w   d2
                clr.l   d4
                move.w  (ram_FF1340).l,d1
                move.w  #1,d5
                clr.w   d6
                move.b  (a0)+,d2
                subq.w  #1,d2
.loc_9286:
                tst.w   d1
                ble.w   .loc_9292
                subq.w  #1,d1
                bra.w   .loc_92D4
.loc_9292:
                add.l   d3,d4
                cmp.l   #$10000,d4
                blt.w   .loc_92D4
.loc_929E:
                move.w  d5,(a2)+
                move.w  #1,d5
                tst.w   (ram_FF133C).l
                beq.w   .loc_92BA
                sub.w   (ram_FF1332).l,d5
                sub.w   (ram_FF1332).l,d5
.loc_92BA:
                addq.w  #1,d6
                subi.l  #$10000,d4
                cmp.l   #$10000,d4
                blt.w   .loc_92EE
                sub.w   (ram_FF1332).l,d5
                bra.s   .loc_929E
.loc_92D4:
                tst.w   (ram_FF133C).l
                beq.w   .loc_92E8
                sub.w   (ram_FF1332).l,d5
                bra.w   .loc_92EE
.loc_92E8:
                add.w   (ram_FF1332).l,d5
.loc_92EE:
                dbf     d2,.loc_9286
                move.w  d6,d2
                andi.w  #7,d2
                move.w  #7,d3
                sub.w   d2,d3
                move.w  d3,(ram_FF0D28).l
                rts
; End of function Road_InterpolateRightEdgeAlt



; *************************************************
; Function Road_WriteTileColumns
; Writes the road tile columns (0x1F wide) into the sprite tile array.
; In:  ram_FF0D2A/0D2E/102E strip data, ram_FF132E/1330, ram_FFDE68/6A/66
; Out: Race_ram_CurrentSpriteTileArray + ram_FF0D26
; Clobbers: d1-d5, a0-a4
; *************************************************

Road_WriteTileColumns:
                movea.l (ram_FF0D2A).l,a0
                movea.l (Race_ram_CurrentSpriteTileArray).l,a4
                adda.w  (ram_FF0D26).l,a4
                move.w  #$1F,d4
                lea     (ram_FF102E).l,a3
                move.w  (ram_FF1330).l,d1
                cmp.w   #$F,d1
                move.w  (ram_FFDE6A).l,d3
                move.w  (ram_FFDE68).l,d5
.loc_9338:
                movea.l a4,a1
                lea     (ram_FF0D2E).l,a2
                move.w  (ram_FF132E).l,d2
.loc_9346:
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                dbf     d2,.loc_935E
                bra.w   .loc_93B0
.loc_935E:
                adda.w  d3,a1
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                dbf     d2,.loc_9378
                bra.w   .loc_93B0
.loc_9378:
                adda.w  d3,a1
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                dbf     d2,.loc_9392
                bra.w   .loc_93B0
.loc_9392:
                adda.w  d3,a1
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                move.b  (a0),(a1)+
                adda.w  (a2)+,a0
                dbf     d2,.loc_93AC
                bra.w   .loc_93B0
.loc_93AC:
                adda.w  d3,a1
                bra.s   .loc_9346
.loc_93B0:
                addq.w  #4,a4
                dbf     d4,.loc_93CA
                cmp.w   #$1F,d1
                bcc.w   .loc_93C4
                move.w  (ram_FFDE66).l,d3
.loc_93C4:
                move.w  #$1F,d4
                adda.w  d5,a4
.loc_93CA:
                adda.w  (a3)+,a0
                dbf     d1,.loc_9338
                rts
; End of function Road_WriteTileColumns



; *************************************************
; Function Road_ClearEdgeTiles
; Clears the remaining road edge tiles (writes 0) for ram_FF0D28 strips.
; In:  ram_FF0D28, ram_FFDE66
; Out: sprite tile array (zeroed edge rows)
; Clobbers: d0-d3, a1/a4
; *************************************************

Road_ClearEdgeTiles:
                clr.w   d0
                move.w  (ram_FF0D28).l,d1
                move.w  (ram_FFDE66).l,d3
.loc_93E0:
                movea.l a4,a1
                move.w  (ram_FF132E).l,d2
.loc_93E8:
                move.w  d0,(a1)+
                move.w  d0,(a1)+
                dbf     d2,.loc_93F4
                bra.w   .loc_9422
.loc_93F4:
                adda.w  d3,a1
                move.w  d0,(a1)+
                move.w  d0,(a1)+
                dbf     d2,.loc_9402
                bra.w   .loc_9422
.loc_9402:
                adda.w  d3,a1
                move.w  d0,(a1)+
                move.w  d0,(a1)+
                dbf     d2,.loc_9410
                bra.w   .loc_9422
.loc_9410:
                adda.w  d3,a1
                move.w  d0,(a1)+
                move.w  d0,(a1)+
                dbf     d2,.loc_941E
                bra.w   .loc_9422
.loc_941E:
                adda.w  d3,a1
                bra.s   .loc_93E8
.loc_9422:
                addq.w  #4,a4
                dbf     d1,.loc_93E0
                rts
; End of function Road_ClearEdgeTiles

; *************************************************
; Function Road_DrawObjects
; Public entry (race.asm 0x1809): walks the visible-object list and renders each
; object record via Road_DrawObject. Saves/restores the animation tile/sprite indices.
; In:  Road_VisibleObjectList visible list, Road_ObjectArray records
; Out: SAT/tile arrays; Animation_ram_SpriteIndex/TileIndex
; Clobbers: d0/a0/a1
; *************************************************

Road_DrawObjects:
                movea.l (Race_ram_CurrentSpriteAttributeTable).l,a0
                lea     (Road_ObjectArray).l,a0
                lea     (Road_VisibleObjectList).l,a1
                move.w  #0,(ram_FFDE62).l
.loop:
                move.w  (a1)+,d0
                cmp.w   #$FFFF,d0
                beq.w   .return

                mulu.w  #RoadObject_Size,d0
                lea     (Road_ObjectArray).l,a0
                adda.w  d0,a0
                movem.l a0-a1,-(sp)
                move.w  (Animation_ram_TileIndex).l,(ram_FF1362).l
                move.w  (Animation_ram_SpriteIndex).l,(ram_FF1364).l
                bsr.w   Road_DrawObject
                movem.l (sp)+,a0-a1
                adda.l  #RoadObject_Size,a0
                bra.s   .loop
.return:
                rts
; End of function Road_DrawObjects



; *************************************************
; Function Road_DrawObject
; Renders one 0x14-byte object record: projection/shape(s), road strip, sprite chain
; copy into the SAT with clipping. Record fields: +0 x, +2 y, +4 scale, +6 horizon,
; +8 shape, +$A flags, +$C x offset, +$12 second shape. Flags bit15 is the
; horizontal-mirror/facing bit (same bit as byte +$B bit7), not a shadow flag.
; In:  a0 - object record; current animation indices
; Out: SAT chain; ram_FF1366 end flag; Animation_ram_SpriteIndex
; Clobbers: d0-d7, a0-a2
; *************************************************

Road_DrawObject:
                move.w  #0,(ram_FFDE62).l
                move.w  #0,(Road_ram_MirrorFlag).l
                clr.l   d0
                move.w  RoadObject_X(a0),(ram_FFDE6E).l
                move.w  (ram_FFDE6E).l,(ram_FF1342).l
                move.w  RoadObject_Y(a0),(ram_FFDE70).l
                move.w  (ram_FFDE70).l,(ram_FF1344).l
                move.w  RoadObject_Scale(a0),d0
                asl.l   #2,d0
                move.l  d0,(ram_FF1350).l
                move.w  RoadObject_Limit(a0),(ram_FF136A).l
                move.w  RoadObject_Flags(a0),d1
                bpl.w   .loc_94DC
                move.w  #1,(Road_ram_MirrorFlag).l
.loc_94DC:
                move.w  #0,(ram_FF133C).l
                move.w  d1,d7
                andi.w  #$3000,d7
                asl.w   #1,d7
                move.w  d7,(ram_FF133E).l
                move.w  RoadObject_Shape(a0),d2
                move.w  RoadObject_Shape2(a0),d3
                move.l  a0,-(sp)
; shape pointer table (shared with race.asm)
                lea     (Road_ShapeTable).l,a1
                asl.w   #2,d2
                movea.l (a1,d2.w),a2
                move.l  a2,(ram_FF1348).l
                move.w  #0,(ram_FF1354).l
                btst    #7,RoadObject_Flags+1(a0)
                beq.w   .loc_962C
.loc_9520:
                move.w  #0,(ram_FF135E).l
                move.w  #1,(ram_FF1354).l
                bsr.w   Road_ScaleShape
                addq.l  #2,(ram_FF1348).l
                move.w  d6,(ram_FF1358).l
                move.w  d3,-(sp)
                bsr.w   Road_ProjectShapeSpecial
                move.w  d5,(ram_FF1356).l
                move.w  d1,(ram_FF135E).l
                move.w  (sp)+,d3
                tst.w   (ram_FFDE62).l
                beq.w   .loc_958E
                move.w  #0,(ram_FFDE62).l
                tst.w   d3
                bne.w   .loc_9572
                addq.w  #4,sp
                bra.w   .locret_978A
.loc_9572:
                asl.w   #2,d3
                movea.l (a1,d3.w),a2
                move.l  a2,(ram_FF1348).l
                move.w  #0,d3
                move.l  #0,(ram_FF134C).l
                bra.s   .loc_9520
.loc_958E:
                tst.w   d3
                beq.w   .loc_9640
                asl.w   #2,d3
                movea.l (a1,d3.w),a2
                move.l  a2,(ram_FF134C).l
                bsr.w   Road_ScaleShape
                addq.l  #2,(ram_FF134C).l
                movea.l (ram_FF134C).l,a2
                subq.w  #1,d6
                move.w  d6,(ram_FF135C).l
                bsr.w   Road_ProjectShapeSpecial
                move.w  d5,(ram_FF135A).l
                move.w  d1,(ram_FF1360).l
                tst.w   (ram_FFDE62).l
                beq.w   .loc_95E4
                move.w  #0,(ram_FFDE62).l
                move.l  #0,(ram_FF134C).l
.loc_95E4:
                movea.l (ram_FF1348).l,a0
                move.b  -1(a0),d5
                move.b  -1(a2),d6
                sub.b   1(a2),d6
                addq.w  #1,d6
                sub.b   d6,d5
                ext.w   d5
                bpl.w   .loc_960E
                move.w  #0,d5
                move.w  d5,(ram_FF1340).l
                bra.w   .loc_9652
.loc_960E:
                move.w  d5,(ram_FF1340).l
                move.l  (ram_FF1350).l,d2
                lsr.l   #2,d2
                mulu.w  d2,d5
                asl.l   #2,d5
                swap    d5
                sub.w   d5,(ram_FF1358).l
                bra.w   .loc_9652
.loc_962C:
                bsr.w   Road_ProjectShape
                tst.w   (ram_FFDE62).l
                beq.w   .loc_9640
                addq.w  #4,sp
                bra.w   .locret_978A
.loc_9640:
                move.w  #0,(ram_FF1340).l
                move.l  #0,(ram_FF134C).l
.loc_9652:
                movea.l (ram_FF1348).l,a0
                move.l  d0,d1
                move.w  (Animation_ram_SpriteIndex).l,-(sp)
.loc_9660:
                move.w  #0,(ram_FF1366).l
                bsr.w   Road_DrawStrip
                tst.w   (ram_FF1366).l
                beq.w   .loc_9690
                move.w  (ram_FF1362).l,(Animation_ram_TileIndex).l
                move.w  (ram_FF1364).l,(Animation_ram_SpriteIndex).l
                addq.w  #6,sp
                bra.w   .locret_978A
.loc_9690:
                tst.l   (ram_FF134C).l
                beq.w   .loc_96F0
                movea.l (ram_FF134C).l,a0
                move.l  (ram_FF1350).l,d0
                move.w  d0,d1
                move.w  (ram_FF1344).l,(ram_FFDE70).l
                move.w  (ram_FF1342).l,(ram_FFDE6E).l
                move.w  (ram_FF135A).l,(ram_FF1356).l
                move.w  (ram_FF135C).l,(ram_FF1358).l
                move.w  (ram_FF1360).l,(ram_FF135E).l
                move.w  #0,(ram_FF1340).l
                move.l  #0,(ram_FF134C).l
                bra.w   .loc_9660
.loc_96F0:
                move.w  (sp)+,d1
                movea.l (sp)+,a0
                move.b  RoadObject_Flags(a0),d7
                andi.w  #7,d7
                beq.w   .locret_978A
                tst.w   (ram_FF135E).l
                bne.w   .locret_978A
; copy the built sprite chain into the SAT slots with the object x offset/clipping
                movea.l (Race_ram_CurrentSpriteAttributeTable).l,a1
                move.w  d1,d2
                asl.w   #3,d2
                adda.w  d2,a1
                move.w  (Animation_ram_SpriteIndex).l,d3
                move.w  d3,d2
                move.w  d3,d0
                sub.w   d1,d0
                beq.w   .locret_978A
                move.w  d3,d1
                movea.l (Race_ram_CurrentSpriteAttributeTable).l,a2
                asl.w   #3,d2
                adda.w  d2,a2
                move.w  RoadObject_XOffset(a0),d3
                move.w  d0,d2
                subq.w  #1,d0
                subq.w  #1,d7
.loc_973C:
                move.b  d1,-5(a2)
                move.w  (a1)+,(a2)+
                move.w  (a1)+,(a2)+
                move.w  (a1)+,(a2)+
                move.w  (a1)+,(a2)+
                sub.w   d3,-2(a2)
                cmpi.w  #$FFC0,-2(a2)
                bpl.w   .loc_9760
                cmpi.w  #$FE20,-2(a2)
                bpl.w   .loc_9768
.loc_9760:
                subq.w  #8,a1
                subq.w  #8,a2
                bra.w   .loc_9772
.loc_9768:
                addq.w  #1,d1
                cmp.w   #$50,d1
                bpl.w   .loc_9784
.loc_9772:
                dbf     d0,.loc_973C
                move.w  d1,(Animation_ram_SpriteIndex).l
                move.w  d2,d0
                subq.w  #1,d0
                dbf     d7,.loc_973C
.loc_9784:
                move.b  #0,-5(a2)
.locret_978A:
                rts
; End of function Road_DrawObject



; *************************************************
; Function Road_ScaleShape
; Reads three shape bytes at (a2) and scales them by scale>>2.
; In:  a0 - object; a2 - shape; d0 - scale
; Out: d5/d6 - scaled shape values
; Clobbers: d2/d5/d6/d7
; *************************************************

Road_ScaleShape:
                move.b  (a2),d5
                ext.w   d5
                move.b  1(a2),d6
                ext.w   d6
                move.l  d0,d2
                lsr.l   #2,d2
                btst    #$F,$A(a0)
                beq.w   .loc_97AE
                move.w  d5,d7
                move.b  2(a2),d5
                ext.w   d5
                sub.w   d7,d5
.loc_97AE:
                mulu.w  d2,d5
                asl.l   #2,d5
                swap    d5
                mulu.w  d2,d6
                asl.l   #2,d6
                swap    d6
                rts
; End of function Road_ScaleShape



; *************************************************
; Function Road_ProjectShapeSpecial
; Projects the shape edge: adds the object x, applies the mirror bit and the
; $C0/$200 constants; sets ram_FFDE62 when out of range.
; In:  a0 - object; a2 - shape; d0 - scale; d5 - edge
; Out: d1 - projected value; ram_FFDE62
; Clobbers: d1-d3/d5
; *************************************************

Road_ProjectShapeSpecial:
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
                bmi.w   .loc_97F8
                cmp.w   d3,d1
                bpl.w   .loc_982C
                btst    #$F,$A(a0)
                beq.w   .loc_97F0
                neg.w   d1
                bra.w   .loc_9828
.loc_97F0:
                sub.w   d1,d3
                exg     d1,d3
                bra.w   .loc_9828
.loc_97F8:
                exg     d1,d2
                sub.w   d5,d1
                addi.w  #$200,d1
                bpl.w   .loc_9820
                move.w  d3,d2
                neg.w   d2
                cmp.w   d2,d1
                ble.w   .loc_982C
                add.w   d1,d5
                btst    #$F,$A(a0)
                beq.w   .loc_9828
                add.w   d3,d1
                bra.w   .loc_9828
.loc_9820:
                move.w  #0,d1
                bra.w   .locret_982A
.loc_9828:
                asr.w   #1,d1
.locret_982A:
                rts
.loc_982C:
                move.w  #1,(ram_FFDE62).l
                rts
; End of function Road_ProjectShapeSpecial



; *************************************************
; Function Road_ProjectShape
; Like Road_ProjectShapeSpecial for the non-special path; stores the clip in ram_FF135E.
; In:  a0 - object; a2 - shape; d0 - scale
; Out: ram_FF135E; ram_FFDE62 on overflow
; Clobbers: d1-d3
; *************************************************

Road_ProjectShape:
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
                bmi.w   .loc_9872
                cmp.w   d3,d1
                bpl.w   .loc_98B8
                btst    #$F,$A(a0)
                beq.w   .loc_986A
                neg.w   d1
                bra.w   .loc_98AE
.loc_986A:
                sub.w   d1,d3
                exg     d1,d3
                bra.w   .loc_98AE
.loc_9872:
                move.w  d3,d1
                exg     d1,d2
                lsr.w   #1,d2
                sub.w   d2,d1
                addi.w  #$200,d1
                bpl.w   .loc_98A6
                move.w  d3,d2
                neg.w   d2
                cmp.w   d2,d1
                ble.w   .loc_98B8
                move.w  d1,d2
                asr.w   #1,d2
                sub.w   d2,(ram_FFDE6E).l
                btst    #$F,$A(a0)
                beq.w   .loc_98AE
                add.w   d3,d1
                bra.w   .loc_98AE
.loc_98A6:
                move.w  #0,d1
                bra.w   .loc_98B0
.loc_98AE:
                asr.w   #1,d1
.loc_98B0:
                move.w  d1,(ram_FF135E).l
                rts
.loc_98B8:
                move.w  #1,(ram_FFDE62).l
                rts
; End of function Road_ProjectShape
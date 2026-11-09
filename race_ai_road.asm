; *************************************************
; race_ai_road.asm - road profile/objects/standings/speed (split from race_ai)
; ROM range: $EB34-$10DFF (race_ai starts at $10E00)
; *************************************************

; *************************************************
; race_ai.asm - main gameplay/AI/physics after road_marking
; ROM range: $EB34-$1685F (animation starts at $16860)
; *************************************************


unk_EB34:       dc.b   0
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
                dc.b $D0
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
                dc.b  $D
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
                dc.b $D0
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
                dc.b $DD
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
                dc.b  $D
                dc.b $D0
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
                dc.b $DD
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
                dc.b $DD
                dc.b $D0
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
                dc.b  $D
                dc.b $DD
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
                dc.b $DD
                dc.b $D0
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
                dc.b $DD
                dc.b $DD
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
                dc.b  $D
                dc.b $DD
                dc.b $D0
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
                dc.b $DD
                dc.b $DD
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
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $DD
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
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD

; =============== S U B R O U T I N E =======================================
; draw edges of the road ???

sub_EC90:
                lea     (ram_FF3A9C).l,a0
                adda.w  #$130,a0
                lea     (Road_ram_XLeftArray).l,a4
                adda.w  #$130,a4
                movea.l (Race_ram_CurrentHudBuffer).l,a1
                adda.l  #$4C0,a1
                lea     (unk_EB34).l,a2
                move.w  #$97,d0
                movea.l (Race_ram_CurrentAlpha).l,a3
                sub.w   (a3),d0
.loc_ECC2:
                move.w  -(a0),d1
                asl.w   #2,d1
                move.w  d1,d2
                add.w   d1,d2
                add.w   d1,d2
                lea     (a2,d2.w),a3
                move.l  (a3)+,-(a1)
                move.l  (a3)+,$260(a1)
                move.l  (a3)+,$4C0(a1)
                dbf     d0,.loc_ECC2

                rts
; End of function sub_EC90

; *************************************************
; Function Road_FillProfileTables
; *************************************************

Road_FillProfileTables:
                movea.l (Race_ram_CurrentAlpha).l,a0
                move.w  #$97,d0
                sub.w   (a0),d0
; go to line $98 and fill all arrays from bottom to top
                move.w  #$98,d1
                asl.w   #1,d1
                lea     (Road_ram_XLeftArray).l,a0
                adda.w  d1,a0
                lea     (Road_ram_XRightArray).l,a1
                adda.w  d1,a1
                movea.l (Race_ram_CurrentHScrollTable).l,a2
                adda.w  d1,a2
                adda.w  d1,a2
                lea     (Road_ram_MarkingXArray).l,a3
                adda.w  d1,a3
                lea     (RoadMarking_ram_XArray).l,a4
                adda.w  d1,a4
                lea     (RoadMarking_ram_WidthArray).l,a5
                adda.w  d1,a5
; grass is drawn on fg and bg planes in the middle of them and has width of 320 pixels
; so the coordinates are 512-160=352 and 512+160=682
; we scroll the planes so bg make grass to the right of the road and fg make grass to the left of the road
.mainLoop:
; these coordinates are relative to the center of the screen
                move.w  -(a0),d1 ; roadX_left
                move.w  -(a1),d2 ; roadX_right
; bg scroll
                move.w  d2,d3
                cmp.w   #192,d3
                bmi.w   .loc_ED36
                move.w  #192,d3
.loc_ED36:
                cmp.w   #-160,d3
                bpl.w   .loc_ED42
                move.w  #-160,d3
.loc_ED42:
                addi.w  #-192,d3
                move.w  d3,-(a2)
; fg scroll
                move.w  d1,d3
                cmp.w   #160,d3
                bmi.w   .loc_ED56
                move.w  #160,d3
.loc_ED56:
                cmp.w   #-192,d3
                bpl.w   .loc_ED62
                move.w  #-192,d3
.loc_ED62:
                addi.w  #512,d3
                move.w  d3,-(a2)
; calculate marking width
                sub.w   d1,d2 ; get road width
                move.w  d2,d3
                asr.w   #1,d3 ; half width
                add.w   d3,d1
                add.w   d3,d2 ; width * 1.5
                lsr.w   #6,d2 ; (road width * 1.5 / 64)
; width must be between 1 and 8
                bne.w   .setMarkingWidth
                addq.w  #1,d2
                cmp.w   #8,d2
                ble.w   .setMarkingWidth
                move.w  #8,d2
.setMarkingWidth:
                move.w  d2,-(a5) ; set marking width

                move.w  -(a3),d1
                addi.w  #512,d1
                cmp.w   #320,d1
                bmi.w   .loc_ED9C
; gap in marking
                move.w  #0,d1 ; x = 0
                clr.w   (a5) ; width = 0
.loc_ED9C:
                tst.w   d1
                bpl.w   .setMarkingX
                add.w   d1,(a5) ; if x <= 0 then decrease width
                clr.w   d1 ; and set x = 0
                tst.w   (a5)
                bpl.w   .setMarkingX
                clr.w   (a5) ; width can't be negative
.setMarkingX:
                move.w  d1,-(a4) ; set marking X
                dbf     d0,.mainLoop

                movea.l (Race_ram_CurrentAlpha).l,a6
                move.w  (a6),d0
                subq.w  #1,d0
                move.w  #0,d1
.fillSkyPart:
                move.w  d1,-(a2) ; scroll table fg
                move.w  d1,-(a2) ; scroll table bg
                move.w  d1,-(a4) ; X table
                move.w  d1,-(a5) ; width table
                dbf     d0,.fillSkyPart
                rts
; End of function Road_FillProfileTables


; =============== S U B R O U T I N E =======================================


sub_EDD0:
                lea     (ram_FF310A).l,a0
                lea     (Track_CurveBuffer).l,a1
                lea     (ram_FF31D2).l,a2
                lea     (ram_FF329A).l,a3
                lea     (ram_FF3236).l,a4
                lea     (ram_FF3362).l,a5
                lea     (ram_FFD77C).l,a6
                move.w  (ram_FF1E68).l,d0
                andi.w  #$FF,d0
                asl.w   #1,d0
                adda.w  d0,a1
                move.w  (ram_FF1E6A).l,d5
                move.b  (a1)+,d4
                ext.w   d4
                move.w  d4,d0
                move.w  d4,(ram_FF1E6C).l
                beq.w   .loc_EE3E
                bmi.w   .loc_EE30
                mulu.w  d5,d4
                swap    d4
                bpl.w   .loc_EE3E
                addq.w  #1,d4
                bra.w   .loc_EE3E


.loc_EE30:
                neg.w   d4
                mulu.w  d5,d4
                swap    d4
                bpl.w   .loc_EE3C
                addq.w  #1,d4

.loc_EE3C:
                neg.w   d4

.loc_EE3E:
                move.w  d4,(ram_FF1E58).l
                sub.w   d4,d0
                move.w  d0,(ram_FF3108).l
                move.w  d4,d3
                move.w  (ram_FF1E60).l,d4
                neg.w   d4
                move.b  (a1)+,d3
                cmpa.l  #Race_ram_NextSpriteTileArray,a1
                bmi.w   .loc_EE68
                lea     (Track_CurveBuffer).l,a1

.loc_EE68:
                ext.w   d3
                beq.w   .loc_EE82
                bmi.w   .loc_EE7A
                mulu.w  d5,d3
                swap    d3
                bra.w   .loc_EE82


.loc_EE7A:
                neg.w   d3
                mulu.w  d5,d3
                swap    d3
                neg.w   d3

.loc_EE82:
                move.w  d3,(ram_FF1E5A).l
                neg.w   d3
                lsr.w   #8,d5
                neg.w   d5
                move.w  #$1F,d0
                move.w  d0,d1
                asl.w   #1,d1
                move.w  d1,(ram_FF30E0).l
                move.w  #$98,d7

.loc_EEA0:
                move.w  d4,(a0)+
                move.w  #$100,d6
                add.w   d5,d6
                move.w  (ram_FF1E66).l,d1
                sub.w   d3,d1
                move.w  d1,(a0)+
                bpl.w   .loc_EED0
                neg.w   d1
                ext.l   d1
                asl.l   #8,d1
                divu.w  d6,d1
                neg.w   d1
                addi.w  #$4C,d1 ; 'L'
                bpl.w   .loc_EEDA
                move.w  #1,d1
                bra.w   .loc_EEDA


.loc_EED0:
                ext.l   d1
                asl.l   #8,d1
                divu.w  d6,d1
                addi.w  #$4C,d1 ; 'L'

.loc_EEDA:
                move.w  d1,(a4)+
                cmp.w   d7,d1
                bcc.w   .loc_EEEC
                cmp.w   #$100,d6
                blt.w   .loc_EEEC
                move.w  d1,d7

.loc_EEEC:
                move.w  d7,(a6)+
                clr.l   d2
                move.w  d4,d2
                bpl.w   .loc_EF02
                neg.w   d2
                asl.l   #8,d2
                divu.w  d6,d2
                neg.w   d2
                bra.w   .loc_EF0A


.loc_EF02:
                beq.w   .loc_EF0A
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF0A:
                subi.w  #$160,d2
                move.w  d2,(a2)+
                move.l  #$1C00,d2
                divu.w  d6,d2
                move.w  d2,$64(a3)
                clr.l   d2
                move.w  d4,d2
                subi.w  #$E0,d2
                bpl.w   .loc_EF34
                neg.w   d2
                asl.l   #8,d2
                divu.w  d6,d2
                neg.w   d2
                bra.w   .loc_EF3C


.loc_EF34:
                beq.w   .loc_EF3C
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF3C:
                move.w  d2,(a3)+
                clr.l   d2
                move.w  d4,d2
                addi.w  #$E0,d2
                bpl.w   .loc_EF56
                neg.w   d2
                asl.l   #8,d2
                divu.w  d6,d2
                neg.w   d2
                bra.w   .loc_EF5E


.loc_EF56:
                beq.w   .loc_EF5E
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF5E:
                move.w  d2,(a5)+
                addi.w  #$100,d5
                move.b  (a1)+,d2
                ext.w   d2
                add.w   (ram_FF3108).l,d4
                add.w   d2,(ram_FF3108).l
                move.b  (a1)+,d2
                cmpa.l  #Race_ram_NextSpriteTileArray,a1
                bmi.w   .loc_EF86
                lea     (Track_CurveBuffer).l,a1

.loc_EF86:
                ext.w   d2
                add.w   d2,d3
                dbf     d0,.loc_EEA0
                movea.l (Race_ram_CurrentAlpha).l,a1
                cmp.w   #$98,d7
                bmi.w   .loc_EFA0
                move.w  #$98,d7

.loc_EFA0:
                move.w  d7,(a1)
                rts
; End of function sub_EDD0


; =============== S U B R O U T I N E =======================================


sub_EFA4:
                lea     (RacePlayerA).l,a1
                lea     (Race_EventBuffer).l,a2
                btst    #7,$68(a1)
                bne.w   .loc_EFD6
                move.l  (ram_FF1E9A).l,(ram_FF1E9E).l
                move.w  4(a1),(ram_FF1762).l
                move.l  #$FFFFFFFF,(a2)
                bra.w   .loc_EFEE


.loc_EFD6:
                move.l  $62(a1),(ram_FF1E9E).l
                move.w  (RaceTrack_Data1).l,(ram_FF1762).l
                move.l  $62(a1),d0
                move.l  d0,(a2)

.loc_EFEE:
                lea     (ram_FF1A0C).l,a0
                move.w  (ram_FF1A06).l,d7
                subq.w  #2,d7
                bmi.w   .loc_F036

.loc_F000:
                movea.l (a0)+,a1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F032
                move.w  4(a1),d0
                move.b  $71(a1),d1
                ext.w   d1
                btst    #7,$68(a1)
                bne.w   .loc_F028
                bsr.w   sub_F0E4
                bra.w   .loc_F032


.loc_F028:
                move.l  $62(a1),d0
                asl.w   #2,d1
                move.l  d0,(a2,d1.w)

.loc_F032:
                dbf     d7,.loc_F000

.loc_F036:
                lea     (ram_FF1982).l,a0
                move.w  (a0)+,d7
                move.w  d7,d6
                asl.w   #2,d6
                adda.w  d6,a0
                subq.w  #1,d7
                bmi.w   .loc_F09E
                move.w  (ram_FF1762).l,d2
                addi.w  #$20,d2 ; ' '

.loc_F054:
                jsr     (Rand_GetWord).l
                andi.w  #$1F,d0
                add.w   d0,d2
                move.w  d2,d0
                movea.l -(a0),a1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F09A
                move.b  $71(a1),d1
                bsr.w   sub_F0E4
                clr.l   d3
                move.w  (RaceTrack_Data1).l,d3
                swap    d3
                divu.w  STRUCT_OFFSET_66(a1),d3
                andi.l  #$FFFF,d3
                ext.w   d1
                asl.w   #2,d1
                cmp.l   (a2,d1.w),d3
                bpl.w   .loc_F09A
                move.l  d3,(a2,d1.w)

.loc_F09A:
                dbf     d7,.loc_F054

.loc_F09E:
                lea     (ram_FF19C4).l,a0
                move.w  (a0)+,d7
                move.w  d7,d6
                asl.w   #2,d6
                adda.w  d6,a0
                subq.w  #1,d7
                bmi.w   .locret_F0E2
                move.w  (ram_FF1762).l,d2
                subi.w  #$10,d2

.loc_F0BC:
                jsr     (Rand_GetWord).l
                andi.w  #$1F,d0
                sub.w   d0,d2
                move.w  d2,d0
                movea.l -(a0),a1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F0DE
                move.b  $71(a1),d1
                bsr.w   sub_F0E4

.loc_F0DE:
                dbf     d7,.loc_F0BC

.locret_F0E2:
                rts
; End of function sub_EFA4


; =============== S U B R O U T I N E =======================================


sub_F0E4:
                movem.l d0-d2,-(sp)
                move.l  (ram_FF1E9E).l,d2
                asl.l   #8,d2
                divu.w  d0,d2
                mulu.w  (RaceTrack_Data1).l,d2
                lsr.l   #8,d2
                ext.w   d1
                asl.w   #2,d1
                move.l  d2,(a2,d1.w)
                movem.l (sp)+,d0-d2
                rts
; End of function sub_F0E4

; *************************************************
; Function Race_UpdateSpeedDisplay
; *************************************************

; *************************************************
; Function Race_UpdateSpeedDisplay
; Converts the player Speed to a packed decimal and stores the HUD speed value.
; In:  d0 - player Speed
; Out: ram_FF3046
; Clobbers: d0/d1
; *************************************************

Race_UpdateSpeedDisplay:
                lsr.w   #7,d0
                move.w  d0,d1
                lsr.w   #2,d1
                add.w   d1,d0
                bsr.w   Race_FormatDecimal
                move.w  d1,(ram_FF3046).l
                rts
; End of function Race_UpdateSpeedDisplay


; =============== S U B R O U T I N E =======================================


; *************************************************
; Function Race_FormatDecimal
; Packs a 16-bit value into five decimal digits (BCD nibbles).
; In:  d0 - value
; Out: d1 - packed decimal
; Clobbers: d0/d1
; *************************************************

Race_FormatDecimal:
                movem.l d0,-(sp)

                clr.l   d1
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                swap    d0
                move.w  d0,d1
                swap    d0
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                swap    d0
                asl.w   #4,d0
                or.w    d0,d1
                swap    d0
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                swap    d0
                asl.w   #8,d0
                or.w    d0,d1
                swap    d0
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                swap    d0
                ror.w   #4,d0
                or.w    d0,d1
                swap    d0
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                andi.l  #$F0000,d0
                or.l    d0,d1
.return:
                movem.l (sp)+,d0
                rts
; End of function Race_FormatDecimal

; *************************************************
; Function PiecewiseLinearInterpolation
; a0 - target array
; a1 - values array
; a2 - index array
; *************************************************

PiecewiseLinearInterpolation:
                move.w  #31,d5 ; 32 points
                subq.w  #1,d5
                lea     (ram_FFD77C).l,a3
.loop:
                move.w  (a1)+,d3 ; value2
                move.w  (a1),d1 ; value1
                move.w  (a2)+,d4 ; index2
                move.w  (a2),d2 ; index1
                move.w  (a3)+,d7 ; index3
                sub.w   d2,d7 ; count = index3 - index1
                ble.w   .continue

                movem.l a0-a1,-(sp)
                bsr.w   FillLinearInterpArray
                movem.l (sp)+,a0-a1
.continue:
                dbf     d5,.loop

                rts
; End of function PiecewiseLinearInterpolation

; *************************************************
; Function FillLinearInterpArray
; d1 - value1
; d2 - index1
; d3 - value2
; d4 - index2
; d7 - count (not necessary equal to index2 - index1)
; a0 - array of values
; *************************************************

FillLinearInterpArray:
                lea     (Interp_dDivisorMap).l,a1
                sub.w   d1,d3 ; d3 = d3 - d1
                sub.w   d2,d4 ; d4 = d4 - d2
                cmp.w   #1,d4
                bgt.w   .loc_F1C8
; d4 <= 1
                swap    d3
                clr.w   d3
                bra.w   .loc_F1F4
.loc_F1C8:
                cmp.w   #2,d4
                bne.w   .loc_F1DA
; d4 = 2
                swap    d3
                clr.w   d3
                asr.l   #1,d3
                bra.w   .loc_F1F4
; d4 > 2
.loc_F1DA:
                clr.w   d0
.loc_F1DC:
                cmp.w   #256,d4
                bmi.w   .loc_F1EA
                lsr.w   #1,d4
                addq.w  #1,d0
                bra.s   .loc_F1DC
.loc_F1EA:
                asl.w   #1,d4
                move.w  (a1,d4.w),d4 ; get 65535 / d4
                lsr.w   d0,d4
                muls.w  d4,d3 ; d3 = d3 * (65535 / d4)

.loc_F1F4:
                asl.w   #1,d2
                adda.w  d2,a0 ; pointer to a0[d2]
                swap    d1 ; d1 *= 65536
                clr.w   d1

                subq.w  #1,d7 ; counter
.loopWrite:
                swap    d1
                move.w  d1,(a0)+ ; write higher word to s0
                swap    d1
                add.l   d3,d1
                dbf     d7,.loopWrite

                rts
; End of function FillLinearInterpArray


Interp_dDivisorMap:
    dc.w    65535, 65535, 32768, 21845, 16384, 13107, 10922,  9362
    dc.w     8192,  7281,  6553,  5957,  5461,  5041,  4681,  4369
    dc.w     4096,  3855,  3640,  3449,  3276,  3120,  2978,  2849
    dc.w     2730,  2621,  2520,  2427,  2340,  2259,  2184,  2114
    dc.w     2048,  1985,  1927,  1872,  1820,  1771,  1724,  1680
    dc.w     1638,  1598,  1560,  1524,  1489,  1456,  1424,  1394
    dc.w     1365,  1337,  1310,  1285,  1260,  1236,  1213,  1191
    dc.w     1170,  1149,  1129,  1110,  1092,  1074,  1057,  1040
    dc.w     1024,  1008,   992,   978,   963,   949,   936,   923
    dc.w      910,   897,   885,   873,   862,   851,   840,   829
    dc.w      819,   809,   799,   789,   780,   771,   762,   753
    dc.w      744,   736,   728,   720,   712,   704,   697,   689
    dc.w      682,   675,   668,   661,   655,   648,   642,   636
    dc.w      630,   624,   618,   612,   606,   601,   595,   590
    dc.w      585,   579,   574,   569,   564,   560,   555,   550
    dc.w      546,   541,   537,   532,   528,   524,   520,   516
    dc.w      512,   508,   504,   500,   496,   492,   489,   485
    dc.w      481,   478,   474,   471,   468,   464,   461,   458
    dc.w      455,   451,   448,   445,   442,   439,   436,   434
    dc.w      431,   428,   425,   422,   420,   417,   414,   412
    dc.w      409,   407,   404,   402,   399,   397,   394,   392
    dc.w      390,   387,   385,   383,   381,   378,   376,   374
    dc.w      372,   370,   368,   366,   364,   362,   360,   358
    dc.w      356,   354,   352,   350,   348,   346,   344,   343
    dc.w      341,   339,   337,   336,   334,   332,   330,   329
    dc.w      327,   326,   324,   322,   321,   319,   318,   316
    dc.w      315,   313,   312,   310,   309,   307,   306,   304
    dc.w      303,   302,   300,   299,   297,   296,   295,   293
    dc.w      292,   291,   289,   288,   287,   286,   284,   283
    dc.w      282,   281,   280,   278,   277,   276,   275,   274
    dc.w      273,   271,   270,   269,   268,   267,   266,   265
    dc.w      264,   263,   262,   261,   260,   259,   258,   257

; =============== S U B R O U T I N E =======================================


sub_F40C:
                addi.b  #1,(ram_FF1AD9).l
                andi.b  #3,(ram_FF1AD9).l
                addi.b  #1,(ram_FF1ADC).l
                andi.b  #7,(ram_FF1ADC).l
                lea     (Road_ObjectArray).l,a0
                move.w  (ram_FFDE72).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                lea     (ram_FF1A08).l,a2
                move.w  #0,(ram_FF3040).l

.loc_F44C:
                move.w  #0,(ram_FF1B16).l
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                bne.w   .loc_F4CA
                tst.w   (ram_FF3040).l
                bne.w   .loc_F480
                move.w  #1,(ram_FF3040).l
                lea     (Race_StaticActorList).l,a2
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                bne.w   .loc_F4CA

.loc_F480:
                cmpi.w  #2,(ram_FF3040).l
                beq.w   .loc_F83C
                cmpi.l  #$708,(ram_FF1E9A).l
                bcs.w   .loc_F83C
                move.w  #2,(ram_FF3040).l
                lea     (unk_258A6).l,a2
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .loc_F83C
                btst    #6,$68(a1)
                beq.w   .loc_F83C
                move.l  4(a1),d0
                sub.l   (ram_FF1E68).l,d0
                bmi.w   .loc_F83C

.loc_F4CA:
                cmpi.w  #1,(ram_FF3040).l
                bne.w   .loc_F4E0
                cmpi.w  #$FFFF,$56(a1)
                bne.w   .loc_F44C

.loc_F4E0:
                move.w  #0,$12(a0)
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F52E
                tst.w   (ram_FF3040).l
                bne.w   .loc_F52E
                btst    #4,$68(a1)
                beq.w   .loc_F534
                tst.b   $6E(a1)
                bmi.w   .loc_F534
                move.w  #0,$12(a0)
                bsr.w   sub_15014
                tst.b   $6E(a1)
                bmi.w   .loc_F52E
                move.w  d0,(ram_FF1B16).l
                move.w  $58(a1),8(a0)
                bra.w   .loc_F534


.loc_F52E:
                bclr    #4,$68(a1)

.loc_F534:
                move.l  4(a1),d0
                move.l  d0,d2
                swap    d0
                sub.w   (ram_FF1E68).l,d0
                bpl.w   .loc_F556
                cmp.w   #$FFF0,d0
                bmi.w   .loc_F69C
                bsr.w   Race_ProjectActorSprite
                bra.w   .loc_F69C


.loc_F556:
                cmp.w   #$1E,d0
                bgt.w   .loc_F838
                sub.l   (ram_FF1E68).l,d2
                lsr.l   #8,d2
                addi.w  #$100,d2
                clr.l   d1
                move.w  (ram_FF1E60).l,d1
                sub.w   $30(a1),d1
                bmi.w   .loc_F588
                tst.w   d2
                beq.w   .loc_F584
                asl.l   #8,d1
                divu.w  d2,d1

.loc_F584:
                bra.w   .loc_F596


.loc_F588:
                neg.w   d1
                asl.l   #8,d1
                tst.w   d2
                beq.w   .loc_F594
                divu.w  d2,d1

.loc_F594:
                neg.w   d1

.loc_F596:
                lea     (ram_FFD338).l,a4
                move.w  #4,d2
                tst.w   (ram_FF3040).l
                beq.w   .loc_F5B4
                lea     (unk_25802).l,a4
                move.w  #3,d2

.loc_F5B4:
                add.w   8(a1),d1
                btst    #5,$68(a1)
                beq.w   .loc_F5C6
                add.w   $40(a1),d1

.loc_F5C6:
                tst.w   d1
                bmi.w   .loc_F5DE

.loc_F5CC:
                cmp.w   -(a4),d1
                bcc.w   .loc_F5F4
                dbf     d2,.loc_F5CC
                move.w  #0,d2
                bra.w   .loc_F5F4


.loc_F5DE:
                neg.w   d1

.loc_F5E0:
                cmp.w   -(a4),d1
                bcc.w   .loc_F5F2
                dbf     d2,.loc_F5E0
                move.w  #0,d2
                bra.w   .loc_F5F4


.loc_F5F2:
                neg.w   d2

.loc_F5F4:
                move.w  d2,$34(a1)
                move.w  d0,$A(a0)
                tst.w   (ram_FF3040).l
                beq.w   .loc_F60E
                bsr.w   sub_108DA
                bra.w   .loc_F64A


.loc_F60E:
                tst.w   (ram_FF1B16).l
                bne.w   .loc_F64E
                cmpa.l  #ram_FF1F2A,a1
                bne.w   .loc_F62A
                bsr.w   sub_10256
                bra.w   .loc_F64A


.loc_F62A:
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_F646
                tst.w   (ram_FF1ACC).l
                beq.w   .loc_F646
                bsr.w   sub_10294
                bra.w   .loc_F64A


.loc_F646:
                bsr.w   sub_100D0

.loc_F64A:
                move.w  d0,8(a0)

.loc_F64E:
                move.l  4(a1),d0
                sub.l   (ram_FF1E68).l,d0
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  d0,(a6,d7.w)
                bsr.w   sub_FF7E
                btst    #3,$68(a1)
                beq.w   .loc_F684
                move.w  $12(a1),d0
                andi.w  #3,d0
                or.w    d0,2(a0)

.loc_F684:
                move.b  $73(a1),d0
                asl.b   #4,d0
                or.b    d0,$A(a0)
                move.w  (a0),d0
                bpl.w   .loc_F69C
                cmp.w   #$FDC4,d0
                bpl.w   .loc_F6AA

.loc_F69C:
                tst.w   (ram_FF1B16).l
                beq.w   .loc_F838
                bra.w   .loc_F71E


.loc_F6AA:
                addi.w  #1,(ram_FFDE72).l
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_F6D6
                cmpi.b  #2,$6E(a1)
                bne.w   .loc_F6D6
                cmpi.w  #8,(ram_FF1B28).l
                bmi.w   .loc_F6D6
                bsr.w   sub_F9C4

.loc_F6D6:
                tst.w   (ram_FF1B16).l
                bne.w   .loc_F704
                btst    #0,$68(a1)
                beq.w   .loc_F6F2
                bsr.w   sub_F90E
                bra.w   .loc_F834


.loc_F6F2:
                btst    #5,$68(a1)
                beq.w   .loc_F834
                bsr.w   sub_F842
                bra.w   .loc_F834
.loc_F704:
                bclr    #7,$A(a0)
                btst    #0,$76(a1)
                beq.w   .loc_F71A
                bset    #7,$A(a0)
.loc_F71A:
                adda.w  #$14,a0
.loc_F71E:
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_258AE).l,a1
                movea.l (a1,d0.w),a1
                move.w  $58(a1),8(a0)
                move.l  4(a1),d0
                move.l  d0,d2
                swap    d0
                sub.w   (ram_FF1E68).l,d0
                bpl.w   .loc_F758
                cmp.w   #$FFF0,d0
                bmi.w   .loc_F838
                bsr.w   Race_ProjectActorSprite
                bra.w   .loc_F838
.loc_F758:
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                move.b  $73(a1),d0
                asl.b   #4,d0
                move.b  d0,$A(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                cmpi.b  #4,$6E(a1)
                bne.w   .loc_F79A
                addi.l  #$3000,d0

.loc_F79A:
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                move.b  $76(a1),d0
                btst    #0,d0
                bne.w   .loc_F7C2
                bclr    #7,$A(a0)
                bra.w   .loc_F7C8


.loc_F7C2:
                bset    #7,$A(a0)

.loc_F7C8:
                btst    #1,d0
                bne.w   .loc_F7DA
                bclr    #3,$A(a0)
                bra.w   .loc_F7E0


.loc_F7DA:
                bset    #3,$A(a0)

.loc_F7E0:
                move.l  4(a1),d0
                move.w  $30(a1),d1
                move.w  $32(a1),d2
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_F802
                subi.w  #1,(ram_FFDE72).l
                bra.w   .loc_F838


.loc_F802:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)
                btst    #7,$6A(a1)
                beq.w   .loc_F834
                tst.b   $6E(a1)
                bne.w   .loc_F834
                tst.b   $6F(a1)
                bne.w   .loc_F834
                bsr.w   sub_FA98
                bclr    #7,$6A(a1)

.loc_F834:
                adda.w  #$14,a0

.loc_F838:
                bra.w   .loc_F44C


.loc_F83C:
                move.w  #$FFFF,(a0)
                rts
; End of function sub_F40C


; =============== S U B R O U T I N E =======================================


sub_F842:
                adda.w  #$14,a0
                move.b  (ram_FF1AD9).l,d0
                ext.w   d0
                addi.w  #$166,d0
                move.w  d0,8(a0)
                clr.l   d0
                move.w  d0,$A(a0)
                move.l  d0,$C(a0)
                move.l  d0,$10(a0)
                btst    #3,$68(a1)
                beq.w   .loc_F872
                move.b  #$10,d0

.loc_F872:
                move.b  d0,$A(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                subi.l  #$3000,d0
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #3,$A(a0)
                lea     (unk_10E3E).l,a4
                bclr    #7,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_F8BC
                neg.w   d0

.loc_F8BC:
                asl.w   #3,d0
                add.w   (ram_FF1764).l,d0
                move.b  (a4,d0.w),d1
                ext.w   d1
                btst    #7,-$A(a0)
                beq.w   .loc_F8DC
                neg.w   d1
                bset    #7,$A(a0)

.loc_F8DC:
                add.w   $30(a1),d1
                move.w  $32(a1),d2
                move.l  4(a1),d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_F8FE
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_F90C


.loc_F8FE:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_F90C:
                rts
; End of function sub_F842


; =============== S U B R O U T I N E =======================================


sub_F90E:
                adda.w  #$14,a0
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                move.b  $73(a1),d0
                asl.b   #4,d0
                move.b  d0,$A(a0)
                bclr    #7,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_F948
                neg.w   d0
                bset    #7,$A(a0)

.loc_F948:
                cmp.w   #4,d0
                bmi.w   .loc_F954
                move.w  #3,d0

.loc_F954:
                addi.w  #$16A,d0
                move.w  d0,8(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                addi.l  #EndLevel_AnimationTiles,d0
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #3,$A(a0)
                move.w  $30(a1),d1
                move.w  #0,d2
                move.l  4(a1),d0
                subi.l  #$3000,d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_F9B4
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_F9C2


.loc_F9B4:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_F9C2:
                rts
; End of function sub_F90E


; =============== S U B R O U T I N E =======================================


sub_F9C4:
                adda.w  #$14,a0
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                bclr    #7,$A(a0)
                clr.w   d0
                move.b  (ram_FF1ADC).l,d0
                lsr.b   #1,d0
                addi.w  #$AC,d0
                move.w  d0,8(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                subi.l  #$100,d0
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #3,$A(a0)
                move.w  $30(a1),d1
                move.w  #0,d2
                lea     (unk_FA80).l,a6
                move.b  $6F(a1),d7
                ext.w   d7
                cmp.w   #6,d7
                bcs.w   .loc_FA46
                move.w  #5,d7

.loc_FA46:
                asl.w   #2,d7
                adda.w  d7,a6
                add.w   (a6),d1
                add.w   2(a6),d2
                move.l  4(a1),d0
                subi.l  #$3000,d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FA70
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_FA7E


.loc_FA70:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_FA7E:
                rts
; End of function sub_F9C4


unk_FA80:
    dc.w    -16, 28
    dc.w    -16, 32
    dc.w    -16, 41
    dc.w    -16, 45
    dc.w    -16, 56
    dc.w    -16, 40

; =============== S U B R O U T I N E =======================================


sub_FA98:
                adda.w  #$14,a0
                bclr    #7,$A(a0)
                move.w  #$172,8(a0)
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                addi.l  #$3000,d0
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #3,$A(a0)
                move.w  $30(a1),d1
                move.w  #0,d2
                move.l  4(a1),d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FB10
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_FB1C


.loc_FB10:
                asl.w   #1,d0
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)

.locret_FB1C:
                rts
; End of function sub_FA98


; =============== S U B R O U T I N E =======================================


sub_FB1E:
                lea     (Road_ObjectArray).l,a0
                cmpi.w  #$C,(ram_FF1E68).l
                bpl.w   .loc_FB42
                move.l  #$C0000,d0
                move.l  d0,d1
                sub.l   (ram_FF1E68).l,d1
                bra.w   .loc_FB62


.loc_FB42:
                clr.l   d0
                move.w  (RaceTrack_Data1).l,d0
                swap    d0
                move.l  d0,d1
                sub.l   (ram_FF1E68).l,d1
                bcs.w   .locret_FC0C
                cmp.l   #$1F0000,d1
                bcc.w   .locret_FC0C

.loc_FB62:
                move.l  d0,-(sp)
                move.l  d1,-(sp)
                move.w  (ram_FFDE72).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                bsr.w   sub_15478
                move.w  d0,8(a0)
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                move.b  #0,d0
                asl.b   #4,d0
                move.b  d0,$A(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  (sp)+,(a6,d7.w)
                move.l  (sp)+,d0
                addi.w  #1,(ram_FFDE72).l
                bclr    #7,$A(a0)
                bra.w   .loc_FBC6

                bset    #7,$A(a0)
.loc_FBC6:
                bclr    #3,$A(a0)
                bra.w   .loc_FBD6

                bset    #3,$A(a0)
.loc_FBD6:
                move.w  #$180,d1
                move.w  #0,d2
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FBF4
                subi.w  #1,(ram_FFDE72).l
                bra.w   .loc_FC08


.loc_FBF4:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                bset    #7,$B(a0)
                adda.w  #$14,a0

.loc_FC08:
                move.w  #$FFFF,(a0)

.locret_FC0C:
                rts
; End of function sub_FB1E


; =============== S U B R O U T I N E =======================================


sub_FC0E:
                move.w  #0,(ram_FFD7CA).l
                lea     (Road_ObjectArray).l,a0
                move.w  (ram_FFDE72).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                move.l  a0,(ram_FFD7D0).l
                move.l  (ram_FF1E68).l,d0
                movea.l (ram_FFD7CC).l,a1

.loc_FC3A:
                cmpa.l  #ram_FFD7D4,a1
                beq.w   .loc_FC5A
                move.l  -4(a1),d1
                clr.w   d1
                cmp.l   d0,d1
                bcs.w   .loc_FC5A
                subq.l  #4,a1
                move.l  a1,(ram_FFD7CC).l
                bra.s   .loc_FC3A


.loc_FC5A:
                move.l  (a1),d1
                cmp.l   #$FFFFFFFF,d1
                beq.w   .locret_FD6C
                clr.w   d1
                move.l  d1,d2
                sub.l   (ram_FF1E68).l,d2
                bcc.w   .loc_FC82
                addi.l  #4,(ram_FFD7CC).l
                bra.w   .loc_FD62


.loc_FC82:
                cmp.l   #$1E0000,d2
                bcc.w   .loc_FD68
                clr.w   d0
                move.b  2(a1),d0
                move.w  d0,d7
                addi.w  #$173,d0
                move.w  d0,8(a0)
                lea     (unk_14764).l,a4
                asl.w   #3,d7
                adda.w  d7,a4
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                move.w  (a4),d0
                asl.b   #4,d0
                move.b  d0,$A(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  d2,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                lsr.l   #8,d2
                move.w  d2,$E(a0)
                bclr    #7,$A(a0)
                bra.w   .loc_FCF4

                bset    #7,$A(a0)


.loc_FCF4:
                bclr    #3,$A(a0)
                bra.w   .loc_FD04

                bset    #3,$A(a0)


.loc_FD04:
                move.l  d1,d0
                move.w  2(a1),d1
                andi.w  #$F,d1
                asl.w   #5,d1
                subi.w  #$100,d1
                move.w  #0,d2
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FD2E
                subi.w  #1,(ram_FFDE72).l
                bra.w   .loc_FD62


.loc_FD2E:
                mulu.w  2(a4),d0
                lsr.l   #8,d0
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)
                lea     (ram_FFD77C).l,a2
                asl.w   #1,d3
                move.w  (a2,d3.w),6(a0)
                bclr    #7,$B(a0)
                adda.w  #$14,a0
                addi.w  #1,(ram_FFD7CA).l

.loc_FD62:
                addq.w  #4,a1
                bra.w   .loc_FC5A


.loc_FD68:
                move.w  #$FFFF,(a0)

.locret_FD6C:
                rts
; End of function sub_FC0E


                dc.b   0
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b   1
                dc.b   0
                dc.b   3
                dc.b  $B
                dc.b   2
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b  $B
                dc.b   3
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b   4
                dc.b   0
                dc.b   3
                dc.b  $B
                dc.b   4
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b   5
                dc.b   0
                dc.b   3
                dc.b  $B
                dc.b   5
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF

; =============== S U B R O U T I N E =======================================


sub_FD96:
                tst.w   (Race_CopIndex).l
                beq.w   .loc_FDA8
                move.w  #$170,d0
                bra.w   .loc_FDBE
.loc_FDA8:
                move.w  (ram_FF3698).l,d0
                bpl.w   .loc_FDBE
                move.w  #0,(ram_FF369A).l
                bra.w   .return
.loc_FDBE:
                lea     (Road_ObjectArray).l,a0
                move.w  (ram_FFDE72).l,d1
                mulu.w  #$14,d1
                adda.w  d1,a0
                move.w  d0,8(a0)
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                moveq   #0,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #7,$A(a0)
                bclr    #3,$A(a0)
                move.w  #$FEA0,(a0)
                move.w  #$41,2(a0)
                move.w  #$4000,4(a0)
                move.w  #$E0,6(a0)
                adda.w  #$14,a0
                move.w  #$FFFF,(a0)
                addi.w  #1,(ram_FF369A).l
.return:
                rts
; End of function sub_FD96


; =============== S U B R O U T I N E =======================================


sub_FE3A:
                movem.l d4-d7/a0-a6,-(sp)
                move.w  d0,d4
                move.l  d0,d3
                move.l  (ram_FF1E68).l,d5
                sub.l   d5,d0
                bpl.w   .loc_FE56
                move.w  #0,d0
                bra.w   .loc_FF78


.loc_FE56:
                swap    d3
                swap    d5
                sub.w   d5,d3
                andi.w  #$1F,d3
                move.w  d3,-(sp)
                asl.l   #8,d0
                swap    d0
                move.w  d0,d6
                addi.w  #$200,d6
                addi.w  #$100,d0
                move.l  #$2000000,d7
                addi.l  #$800000,d7
                lsr.l   #2,d7
                divu.w  d6,d7
                move.w  d7,-(sp)
                asl.w   #1,d3
                move.w  d3,d5
                asl.w   #1,d5
                lea     (ram_FF310A).l,a2
                move.w  2(a2,d5.w),d6
                move.w  d6,d7
                sub.w   6(a2,d5.w),d7
                bpl.w   .loc_FEB2
                neg.w   d7
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FEAC
                addq.w  #1,d7

.loc_FEAC:
                neg.w   d7
                bra.w   .loc_FEC0


.loc_FEB2:
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FEC0
                addq.w  #1,d7

.loc_FEC0:
                andi.l  #$FFFF,d7
                sub.w   d7,d6
                sub.w   d2,d6
                move.w  d6,d2
                btst    #$F,d2
                beq.w   .loc_FEE6
                neg.w   d2
                ext.l   d2
                asl.l   #8,d2
                divu.w  d0,d2
                neg.w   d2
                addi.w  #$4C,d2 ; 'L'
                bra.w   .loc_FEF0


.loc_FEE6:
                ext.l   d2
                asl.l   #8,d2
                divu.w  d0,d2
                addi.w  #$4C,d2 ; 'L'

.loc_FEF0:
                bpl.w   .loc_FEF8
                move.w  #1,d2

.loc_FEF8:
                lea     (ram_FFD77C).l,a2
                move.w  (a2,d3.w),6(a0)
                lea     (ram_FF310A).l,a2
                move.w  (a2,d5.w),d6
                move.w  d6,d7
                sub.w   4(a2,d5.w),d7
                bpl.w   .loc_FF2E
                neg.w   d7
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FF28
                addq.w  #1,d7

.loc_FF28:
                neg.w   d7
                bra.w   .loc_FF3C


.loc_FF2E:
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FF3C
                addq.w  #1,d7

.loc_FF3C:
                sub.w   d7,d6
                add.w   d6,d1
                bpl.w   .loc_FF56
                neg.w   d1
                swap    d1
                divu.w  d0,d1
                bvs.w   .loc_FF68
                lsr.w   #8,d1
                neg.w   d1
                bra.w   .loc_FF70


.loc_FF56:
                beq.w   .loc_FF70
                swap    d1
                divu.w  d0,d1
                bvs.w   .loc_FF68
                lsr.w   #8,d1
                bra.w   .loc_FF70


.loc_FF68:
                move.w  #0,(sp)
                bra.w   .loc_FF74


.loc_FF70:
                subi.w  #$160,d1

.loc_FF74:
                move.w  (sp)+,d0
                move.w  (sp)+,d3

.loc_FF78:
                movem.l (sp)+,d4-d7/a0-a6
                rts
; End of function sub_FE3A


; =============== S U B R O U T I N E =======================================


sub_FF7E:
                movem.l d0-d7/a0-a6,-(sp)
                move.w  6(a1),d4
                move.w  $A(a0),d2
                andi.w  #$1F,d2
                asl.l   #8,d0
                swap    d0
                move.w  d0,d1
                addi.w  #$200,d1
                addi.w  #$100,d0
                bne.w   .loc_FFA4
                move.w  #1,d0

.loc_FFA4:
                move.l  #$2000000,d3
                cmpi.b  #$10,$71(a1)
                bpl.w   .loc_FFBE
                addi.l  #$800000,d3
                bra.w   .loc_FFC4


.loc_FFBE:
                addi.l  #$1000000,d3

.loc_FFC4:
                lsr.l   #2,d3
                divu.w  d1,d3
                move.w  d3,4(a0)
                asl.w   #1,d2
                move.w  d2,d3
                asl.w   #1,d3
                lea     (ram_FF310A).l,a2
                move.w  2(a2,d3.w),d5
                move.w  d5,d1
                sub.w   6(a2,d3.w),d1
                bpl.w   .loc_FFFC
                neg.w   d1
                mulu.w  d4,d1
                swap    d1
                btst    #$1F,d1
                beq.w   .loc_FFF6
                addq.w  #1,d1

.loc_FFF6:
                neg.w   d1
                bra.w   .loc_1000A


.loc_FFFC:
                mulu.w  d4,d1
                swap    d1

.loc_10000:
                btst    #$1F,d1
                beq.w   .loc_1000A
                addq.w  #1,d1

.loc_1000A:
                andi.l  #$FFFF,d1
                sub.w   d1,d5
                sub.w   $32(a1),d5
                move.w  d5,d1
                btst    #$F,d1
                beq.w   .loc_10030
                neg.w   d1
                asl.l   #8,d1
                divu.w  d0,d1
                neg.w   d1
                addi.w  #$4C,d1 ; 'L'
                bra.w   .loc_10038


.loc_10030:
                asl.l   #8,d1
                divu.w  d0,d1
                addi.w  #$4C,d1 ; 'L'

.loc_10038:
                bpl.w   .loc_10040
                move.w  #1,d1

.loc_10040:
                lea     (ram_FFD77C).l,a2
                move.w  (a2,d2.w),6(a0)
                move.w  d1,2(a0)
                move.w  d2,d3
                asl.w   #1,d3
                lea     (ram_FF310A).l,a2
                clr.l   d5
                move.w  (a2,d3.w),d5
                move.w  d5,d1
                sub.w   4(a2,d3.w),d1
                bpl.w   .loc_10080
                neg.w   d1
                mulu.w  d4,d1
                swap    d1
                btst    #$1F,d1
                beq.w   .loc_1007A
                addq.w  #1,d1

.loc_1007A:
                neg.w   d1
                bra.w   .loc_1008E


.loc_10080:
                mulu.w  d4,d1
                swap    d1
                btst    #$1F,d1
                beq.w   .loc_1008E
                addq.w  #1,d1

.loc_1008E:
                sub.w   d1,d5
                add.w   $30(a1),d5
                bpl.w   .loc_100AA
                neg.w   d5
                swap    d5
                divu.w  d0,d5
                bvs.w   .loc_100BC
                lsr.w   #8,d5
                neg.w   d5
                bra.w   .loc_100C4


.loc_100AA:
                beq.w   .loc_100C4
                swap    d5
                divu.w  d0,d5
                bvs.w   .loc_100BC
                lsr.w   #8,d5
                bra.w   .loc_100C4


.loc_100BC:
                move.w  #0,d5
                bra.w   .loc_100C8


.loc_100C4:
                subi.w  #$160,d5

.loc_100C8:
                move.w  d5,(a0)
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_FF7E


; =============== S U B R O U T I N E =======================================


sub_100D0:
                move.w  d3,-(sp)
                bset    #7,$B(a0)
                move.w  #0,$12(a0)
                tst.w   $12(a1)
                bne.w   .loc_100EE
                bsr.w   sub_1022E
                bra.w   .loc_101E6


.loc_100EE:
                btst    #2,$6A(a1)
                beq.w   .loc_10110
                move.b  #3,d0
                and.b   $6A(a1),d0
                cmp.b   #2,d0
                bpl.w   .loc_10110
                bsr.w   sub_1081A
                bra.w   .loc_101E6


.loc_10110:
                btst    #4,$69(a1)
                beq.w   .loc_10122
                bsr.w   sub_1030A
                bra.w   .loc_101E6


.loc_10122:
                tst.w   $18(a1)
                bne.w   .loc_1014E
                tst.w   $12(a1)
                beq.w   .loc_1014E
                btst    #1,$68(a1)
                beq.w   .loc_1014E
                btst    #2,$68(a1)
                bne.w   .loc_1014E
                bsr.w   sub_101EA
                bra.w   .loc_101E6


.loc_1014E:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bmi.w   .loc_10168
                bne.w   .loc_10170
                tst.w   $C(a1)
                bmi.w   .loc_10170

.loc_10168:
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10170:
                asl.w   #4,d0
                move.w  $A(a1),d1
                move.w  (ram_FF1AC8).l,d3
                cmp.w   d3,d1
                bgt.w   .loc_1018A
                move.w  #0,d1
                bra.w   .loc_1018E


.loc_1018A:
                move.w  #1,d1

.loc_1018E:
                asl.w   #3,d1
                add.w   d1,d0
                move.w  $C(a1),d1
                cmpa.l  #RacePlayerA,a1
                beq.w   .loc_101A2
                asl.w   #1,d1

.loc_101A2:
                lea     (ram_FFD33E).l,a4
                move.w  #3,d2
                tst.w   d1
                bmi.w   .loc_101C0

.loc_101B2:
                cmp.w   -(a4),d1
                bcc.w   .loc_101CE
                subq.w  #1,d2
                bne.s   .loc_101B2
                bra.w   .loc_101CE


.loc_101C0:
                neg.w   d1

.loc_101C2:
                cmp.w   -(a4),d1
                bcc.w   .loc_101CC
                subq.w  #1,d2
                bne.s   .loc_101C2

.loc_101CC:
                neg.w   d2

.loc_101CE:
                move.w  d2,d1
                btst    #$F,$A(a0)
                beq.w   .loc_101DC
                neg.w   d1

.loc_101DC:
                addq.w  #3,d1
                move.w  d1,(ram_FF1764).l
                add.w   d1,d0

.loc_101E6:
                move.w  (sp)+,d3
                rts
; End of function sub_100D0


; =============== S U B R O U T I N E =======================================


sub_101EA:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10200
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10200:
                cmp.w   #2,d0
                bmi.w   .loc_1020C
                move.w  #2,d0

.loc_1020C:
                move.w  $12(a1),d1
                cmp.w   #$DAC,d1
                bpl.w   .loc_10228
                cmp.w   #$1F4,d1
                bmi.w   .loc_10228
                addi.w  #$53,d0 ; 'S'
                bra.w   .locret_1022C


.loc_10228:
                addi.w  #$50,d0 ; 'P'

.locret_1022C:
                rts
; End of function sub_101EA


; =============== S U B R O U T I N E =======================================


sub_1022E:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bgt.w   .loc_10244
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10244:
                cmp.w   #2,d0
                bmi.w   .loc_10250
                move.w  #2,d0

.loc_10250:
                addi.w  #$56,d0 ; 'V'
                rts
; End of function sub_1022E


; =============== S U B R O U T I N E =======================================


sub_10256:
                bclr    #7,$B(a0)
                move.w  #0,$12(a0)
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10278
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10278:
                andi.w  #3,d0
                asl.w   #1,d0
                move.w  $A(a1),d1
                cmp.w   (ram_FF1AC8).l,d1
                blt.w   .loc_1028E
                addq.w  #1,d0

.loc_1028E:
                addi.w  #$7F,d0
                rts
; End of function sub_10256


; =============== S U B R O U T I N E =======================================


sub_10294:
                bset    #7,$B(a0)
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_102B0
                neg.w   d0
                bset    #$F,$A(a0)

.loc_102B0:
                cmp.w   #3,d0
                bmi.w   .loc_102BC
                move.w  #2,d0

.loc_102BC:
                asl.w   #1,d0
                move.w  (ram_FF1ACE).l,d1
                andi.w  #1,d1
                add.w   d0,d1
                addi.w  #$59,d1 ; 'Y'
                move.w  d1,$12(a0)
                lea     (unk_102DE).l,a4
                move.w  (a4,d0.w),d0
                rts
; End of function sub_10294


unk_102DE:  dc.w 3, 19, 35

; =============== S U B R O U T I N E =======================================


sub_102E4:
                movem.l d0/a4,-(sp)
                move.w  #2,d1
                lea     (ram_FFD33E).l,a4
                tst.w   d0
                bpl.w   .loc_102FA
                neg.w   d0

.loc_102FA:
                cmp.w   -(a4),d0
                bcc.w   .loc_10304
                subq.w  #1,d1
                bne.s   .loc_102FA

.loc_10304:
                movem.l (sp)+,d0/a4
                rts
; End of function sub_102E4


; =============== S U B R O U T I N E =======================================


sub_1030A:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10320
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10320:
                move.w  $C(a1),d1
                lea     (ram_FFD33E).l,a4
                move.w  #2,d2
                tst.w   d1
                bmi.w   .loc_10342

.loc_10334:
                cmp.w   -(a4),d1
                bcc.w   .loc_10350
                subq.w  #1,d2
                bne.s   .loc_10334
                bra.w   .loc_10350


.loc_10342:
                neg.w   d1

.loc_10344:
                cmp.w   -(a4),d1
                bcc.w   .loc_1034E
                subq.w  #1,d2
                bne.s   .loc_10344

.loc_1034E:
                neg.w   d2

.loc_10350:
                move.w  d2,d1
                addq.w  #2,d1
                move.w  d1,(ram_FF1764).l
                btst    #6,$69(a1)
                beq.w   .loc_10370
                move.w  #2,d1
                bsr.w   sub_10762
                bra.w   .locret_10382


.loc_10370:
                bsr.w   sub_10384
                bra.w   .locret_10382

                bclr    #4,$69(a1)
                bsr.w   sub_100D0

.locret_10382:
                rts
; End of function sub_1030A


; =============== S U B R O U T I N E =======================================


sub_10384:
                cmp.w   #2,d0
                ble.w   .loc_10390
                move.w  #2,d0

.loc_10390:
                bne.w   .loc_103CA
                btst    #$F,$A(a0)
                beq.w   .loc_103B4
                btst    #5,$69(a1)
                beq.w   .loc_104DA
                subq.w  #2,d1
                bpl.w   .loc_103B0
                neg.w   d1

.loc_103B0:
                bra.w   .loc_10402


.loc_103B4:
                btst    #5,$69(a1)
                bne.w   .loc_104DA
                subq.w  #2,d1
                bpl.w   .loc_103C6
                neg.w   d1

.loc_103C6:
                bra.w   .loc_10402


.loc_103CA:
                btst    #5,$69(a1)
                beq.w   .loc_103EE
                subq.w  #2,d1
                neg.w   d1
                bpl.w   .loc_103E0
                move.w  #0,d1

.loc_103E0:
                btst    #$F,$A(a0)
                bne.w   .loc_10402
                bra.w   .loc_10450


.loc_103EE:
                subq.w  #2,d1
                bpl.w   .loc_103F8
                move.w  #0,d1

.loc_103F8:
                btst    #$F,$A(a0)
                bne.w   .loc_10450

.loc_10402:
                move.l  a2,-(sp)
                tst.w   d0
                bne.w   .loc_10410
                bset    #$F,$A(a0)

.loc_10410:
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_10446
                bmi.w   .loc_10428
                btst    #1,$6B(a1)
                beq.w   .loc_1043C

.loc_10428:
                btst    #0,$6B(a1)
                beq.w   .loc_1043C
                lea     (unk_106A2).l,a2
                bra.w   .loc_1049A


.loc_1043C:
                lea     (unk_105E2).l,a2
                bra.w   .loc_1049A


.loc_10446:
                lea     (unk_10522).l,a2
                bra.w   .loc_1049A


.loc_10450:
                move.l  a2,-(sp)
                tst.w   d0
                bne.w   .loc_1045E
                bclr    #$F,$A(a0)

.loc_1045E:
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_10494
                bmi.w   .loc_10476
                btst    #1,$6B(a1)
                beq.w   .loc_1048A

.loc_10476:
                btst    #0,$6B(a1)
                beq.w   .loc_1048A
                lea     (unk_10702).l,a2
                bra.w   .loc_1049A


.loc_1048A:
                lea     (unk_10642).l,a2
                bra.w   .loc_1049A


.loc_10494:
                lea     (unk_10582).l,a2

.loc_1049A:
                asl.w   #5,d0
                adda.w  d0,a2
                bsr.w   sub_104E6
                asl.w   #4,d0
                adda.w  d0,a2
                asl.w   #2,d1
                move.w  (a2,d1.w),d0
                move.w  2(a2,d1.w),d1
                btst    #1,$6B(a1)
                beq.w   .loc_104CA
                addi.w  #$102,d1
                move.b  #1,(ram_FF1ADD).l
                bra.w   .loc_104CE


.loc_104CA:
                addi.w  #$D8,d1

.loc_104CE:
                move.w  d1,$12(a0)
                movem.l (sp)+,a2
                bra.w   .locret_104E4


.loc_104DA:
                bclr    #4,$69(a1)
                bsr.w   sub_100D0

.locret_104E4:
                rts
; End of function sub_10384


; =============== S U B R O U T I N E =======================================


sub_104E6:
                move.w  d3,-(sp)
                tst.w   $18(a1)
                bne.w   .loc_10502
                tst.w   $12(a1)
                beq.w   .loc_10502
                btst    #1,$68(a1)
                bne.w   .loc_1051A

.loc_10502:
                move.w  $A(a1),d0
                move.w  (ram_FF1AC8).l,d3
                cmp.w   d3,d0
                bgt.w   .loc_1051A
                move.w  #0,d0
                bra.w   .loc_1051E


.loc_1051A:
                move.w  #1,d0

.loc_1051E:
                move.w  (sp)+,d3
                rts
; End of function sub_104E6


unk_10522:      dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b $15
                dc.b   0
                dc.b $17
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $1D
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_10582:      dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $11
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $19
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_105E2:      dc.b   0
                dc.b   3
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $14
                dc.b   0
                dc.b $15
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1F
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1F
                dc.b   0
                dc.b $1C
                dc.b   0
                dc.b $21 ; !
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_10642:      dc.b   0
                dc.b   3
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1C
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1C
                dc.b   0
                dc.b $1A
                dc.b   0
                dc.b $19
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_106A2:      dc.b   0
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $14
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $14
                dc.b   0
                dc.b $14
                dc.b   0
                dc.b $16
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $1C
                dc.b   0
                dc.b $22 ; "
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_10702:      dc.b   0
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $11
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $11
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b  $E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1D
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1D
                dc.b   0
                dc.b $1A
                dc.b   0
                dc.b $1A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0

; =============== S U B R O U T I N E =======================================


sub_10762:
                btst    #5,$69(a1)
                beq.w   .loc_1077A
                btst    #$F,$A(a0)
                beq.w   .loc_1079C
                bra.w   .loc_10784


.loc_1077A:
                btst    #$F,$A(a0)
                bne.w   .loc_1079C

.loc_10784:
                cmp.w   #2,d0
                ble.w   .loc_10790
                move.w  #2,d0

.loc_10790:
                move.l  a2,-(sp)
                lea     (word_107EA).l,a2
                bra.w   .loc_107BC


.loc_1079C:
                cmp.w   #1,d0
                ble.w   .loc_107A8
                move.w  #1,d0

.loc_107A8:
                move.l  a2,-(sp)
                lea     (word_10802).l,a2
                tst.w   d0
                bne.w   .loc_107BC
                bset    #$F,$A(a0)

.loc_107BC:
                asl.w   #3,d0
                move.w  $A(a1),d2
                cmp.w   (ram_FF1AC8).l,d2
                ble.w   .loc_107CE
                addq.w  #4,d0

.loc_107CE:
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_107DA
                addq.w  #2,d0

.loc_107DA:
                move.w  (a2,d0.w),d0
                movea.l (sp)+,a2
                bra.w   .locret_107E8

                dc.b $61 ; a
                dc.b   0
                dc.b $FB
                dc.b $9E


.locret_107E8:
                rts
; End of function sub_10762

word_107EA:     dc.w $12C
                dc.w $12D
                dc.w $12E
                dc.w $12F
                dc.w $132
                dc.w $133
                dc.w $136
                dc.w $137
                dc.w $138
                dc.w $139
                dc.w $13A
                dc.w $13B
word_10802:     dc.w $12C
                dc.w $12D
                dc.w $12E
                dc.w $12F
                dc.w $130
                dc.w $131
                dc.w $134
                dc.w $135
                dc.w $138
                dc.w $139
                dc.w $13A
                dc.w $13B


; =============== S U B R O U T I N E =======================================


sub_1081A:
                move.w  (Race_ram_FrameDelay).l,d2
                sub.b   d2,$70(a1)
                bgt.w   .loc_10834
                move.b  #0,$70(a1)
                bclr    #2,$6A(a1)

.loc_10834:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_1084A
                neg.w   d0
                bset    #$F,$A(a0)

.loc_1084A:
                cmp.w   #2,d0
                ble.w   .loc_10856
                move.w  #2,d0

.loc_10856:
                asl.w   #2,d0
                move.w  $A(a1),d2
                cmp.w   (ram_FF1AC8).l,d2
                ble.w   .loc_10868
                addq.w  #2,d0

.loc_10868:
                move.w  $C(a1),d1
                tst.w   d1
                bpl.w   .loc_10874
                neg.w   d1

.loc_10874:
                cmp.w   (ram_FFD33A).l,d1
                bcc.w   .loc_10880
                addq.w  #1,d0

.loc_10880:
                move.w  d0,d1
                btst    #0,$6A(a1)
                beq.w   .loc_10894
                addi.w  #$148,d1
                bra.w   .loc_10898


.loc_10894:
                addi.w  #$13C,d1

.loc_10898:
                move.w  d1,$12(a0)
                lea     (unk_108C2).l,a4
                asl.w   #1,d0
                move.w  (a4,d0.w),d0
                tst.w   $34(a1)
                bne.w   .locret_108C0
                btst    #1,$68(a1)
                bne.w   .locret_108C0
                bset    #$F,$A(a0)

.locret_108C0:
                rts
; End of function sub_1081A


unk_108C2:      dc.b   0
                dc.b   2
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $1A
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $2B ; +

; =============== S U B R O U T I N E =======================================


sub_108DA:
                move.w  #0,$12(a0)
                cmpa.l  #ram_FF2FAA,a1
                bne.w   .loc_1090C
                move.w  #$87,d0
                btst    #3,$69(a1)
                bne.w   .loc_10902
                bclr    #$F,$A(a0)
                bra.w   .locret_10970


.loc_10902:
                bset    #$F,$A(a0)
                bra.w   .locret_10970


.loc_1090C:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10922
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10922:
                asl.w   #2,d0
                move.w  $A(a1),d1
                bpl.w   .loc_10944
                cmp.w   #$FFD0,d1
                blt.w   .loc_1093C
                move.w  #0,d1

.loc_10938:
                bra.w   .loc_10958


.loc_1093C:
                move.w  #$FFFF,d1
                bra.w   .loc_10958


.loc_10944:
                cmp.w   #$20,d1 ; ' '
                bgt.w   .loc_10954
                move.w  #0,d1

.loc_10950:
                bra.w   .loc_10958


.loc_10954:
                move.w  #1,d1

.loc_10958:
                addq.w  #1,d1
                add.w   d1,d0
                btst    #3,$69(a1)
                bne.w   .loc_1096C
                addi.w  #$5F,d0 ; '_'
                rts


.loc_1096C:
                addi.w  #$6F,d0 ; 'o'

.locret_10970:
                rts
; End of function sub_108DA


; =============== S U B R O U T I N E =======================================


Race_WriteSpriteTiles:
                movea.l (Race_ram_NextFrameReady).l,a2
                move.w  #-1,(a2)
                movea.l (Race_ram_NextSpriteSizePtr).l,a3
                move.w  (a3),d2
                cmpi.w  #$BB8,(a3)
                ble.w   .loc_10990
                move.w  #$BB8,d2 ; not more than $1770 bytes at once
.loc_10990:
                sub.w   d2,(a3)
                move.l  (Race_ram_NextSpriteTileArray).l,d0
                move.w  (Race_ram_SpriteDestination).l,d1
                bsr.w   DmaWriteVRAM
                addi.l  #$1770,(Race_ram_NextSpriteTileArray).l
                addi.w  #$1770,(Race_ram_SpriteDestination).l
                rts
; End of function Race_WriteSpriteTiles


; =============== S U B R O U T I N E =======================================


sub_109B6:
                move.w  #$FFFF,(ram_FF1B30).l
                movea.l (ram_FFD7C4).l,a1
                move.w  (a1),d0
                move.w  (ram_FF1E68).l,d1
                sub.w   (ram_FFD7C8).l,d1
                bpl.w   .loc_10A1A
                cmpa.l  (RaceTrack_Data4).l,a1
                beq.w   .loc_10A1A
                subq.w  #4,a1
                move.l  a1,(ram_FFD7C4).l
                move.w  (a1),d0
                move.w  2(a1),d2
                rol.w   #4,d2
                andi.w  #$F,d2
                addq.w  #1,d2
                move.w  d0,d3
                lsr.w   #8,d3
                andi.w  #$1F,d3
                move.w  d3,d1
                addq.w  #1,d1
                mulu.w  d2,d1
                sub.w   d1,(ram_FFD7C8).l
                move.w  (ram_FF1E68).l,d1
                sub.w   (ram_FFD7C8).l,d1
                bra.w   .loc_10A2E


.loc_10A1A:
                move.w  2(a1),d2
                rol.w   #4,d2
                andi.w  #$F,d2
                addq.w  #1,d2
                move.w  d0,d3
                lsr.w   #8,d3
                andi.w  #$1F,d3

.loc_10A2E:
                move.w  d1,d4
                addq.w  #1,d4
                ext.l   d4
                divu.w  d2,d4
                cmp.w   d3,d4
                ble.w   .loc_10A78
                addi.l  #4,(ram_FFD7C4).l
                addq.w  #4,a1
                move.w  (a1),d0
                cmp.w   #$FFFF,d0
                bne.w   .loc_10A5E
                movea.l (RaceTrack_Data4).l,a1
                move.l  a1,(ram_FFD7C4).l

.loc_10A5E:
                addq.w  #1,d3
                mulu.w  d3,d2
                add.w   d2,(ram_FFD7C8).l
                move.w  (a1),d0
                move.w  (ram_FF1E68).l,d1
                sub.w   (ram_FFD7C8).l,d1
                bra.s   .loc_10A1A


.loc_10A78:
                sub.w   d4,d3
                swap    d4
                move.w  d4,d1
                neg.w   d1
                move.b  d0,d5
                rol.b   #1,d5
                btst    #$F,d0
                beq.w   .loc_10A94
                swap    d4
                andi.w  #1,d4
                eor.w   d4,d5

.loc_10A94:
                andi.w  #1,d5
                ror.w   #2,d5
                btst    #$E,d0
                beq.w   .loc_10AA6
                bset    #$F,d5

.loc_10AA6:
                move.w  2(a1),d6
                lea     (Road_ObjectArray).l,a0
                move.w  (ram_FFDE72).l,d7
                mulu.w  #$14,d7
                adda.w  d7,a0
                move.w  d0,d4
                andi.l  #$7F,d4
                addi.w  #$186,d4
                cmp.w   #$205,d4
                beq.w   .loc_10AFC
                cmp.w   #$1BB,d4
                bmi.w   .loc_10AFC
                cmp.w   #$1EA,d4
                bmi.w   .loc_10AE8
                addi.w  #$2F,d4 ; '/'
                bra.w   .loc_10AFC


.loc_10AE8:
                move.w  d4,d7
                subi.w  #$1BB,d7
                asl.w   #1,d7
                addi.w  #$1BB,d7
                move.w  d7,d4
                addq.w  #1,d4
                swap    d4
                move.w  d7,d4

.loc_10AFC:
                exg     d0,d1
                move.w  d6,d7
                andi.w  #$700,d7
                andi.w  #$FF,d6

.loc_10B08:
                add.w   d2,d0
                cmp.w   #$20,d0 ; ' '
                bcc.w   .loc_10C48
                cmp.w   #$205,d4
                beq.w   .loc_10BB2
                move.w  d4,8(a0)
                swap    d4
                move.w  d4,$12(a0)
                swap    d4
                cmp.w   #$186,d4
                bne.w   .loc_10B48
                move.w  d0,(ram_FF1B30).l
                move.w  d3,(ram_FF1B2E).l
                addi.w  #1,(ram_FF1B2E).l
                add.w   d3,d0
                bra.w   .loc_10BB6


.loc_10B48:
                move.w  d0,$A(a0)
                or.w    d5,$A(a0)
                or.w    d7,$A(a0)
                ori.w   #$1000,$A(a0)
                move.w  d6,$10(a0)
                tst.w   $12(a0)
                beq.w   .loc_10B6C
                bset    #7,$B(a0)

.loc_10B6C:
                movem.l d6-d7,-(sp)
                lea     (ram_FF1B50).l,a6
                move.w  d0,d6
                ext.l   d6
                swap    d6
                clr.l   d7
                move.w  (ram_FF1E6A).l,d7
                sub.l   d7,d6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  d6,(a6,d7.w)
                movem.l (sp)+,d6-d7
                movem.l d0-d7/a1,-(sp)
                bsr.w   sub_10C4E
                movem.l (sp)+,d0-d7/a1
                adda.w  #$14,a0
                btst    #$F,d1
                beq.w   .loc_10BB2
                bchg    #$E,d5

.loc_10BB2:
                dbf     d3,.loc_10B08

.loc_10BB6:
                addq.w  #4,a1
                move.w  (a1),d1
                cmp.w   #$FFFF,d1
                bne.w   .loc_10BCA
                movea.l (RaceTrack_Data4).l,a1
                move.w  (a1),d1

.loc_10BCA:
                move.w  2(a1),d2
                rol.w   #4,d2
                andi.w  #$F,d2
                addq.w  #1,d2
                move.w  d1,d3
                lsr.w   #8,d3
                andi.w  #$1F,d3
                move.w  d1,d4
                andi.l  #$7F,d4
                addi.w  #$186,d4
                cmp.w   #$205,d4
                beq.w   .loc_10C1E
                cmp.w   #$1BB,d4
                bmi.w   .loc_10C1E
                cmp.w   #$1EA,d4
                bmi.w   .loc_10C0A
                addi.w  #$2F,d4 ; '/'
                bra.w   .loc_10C1E


.loc_10C0A:
                move.w  d4,d7
                subi.w  #$1BB,d7
                asl.w   #1,d7
                addi.w  #$1BB,d7
                move.w  d7,d4
                addq.w  #1,d4
                swap    d4
                move.w  d7,d4

.loc_10C1E:
                clr.w   d5
                move.b  d1,d5
                rol.b   #1,d5
                andi.w  #1,d5
                ror.w   #2,d5
                btst    #$E,d1
                beq.w   .loc_10C36
                bset    #$F,d5

.loc_10C36:
                move.w  2(a1),d6
                move.w  d6,d7
                andi.w  #$700,d7
                andi.w  #$FF,d6
                bra.w   .loc_10B08


.loc_10C48:
                move.w  #$FFFF,(a0)
                rts
; End of function sub_109B6


; =============== S U B R O U T I N E =======================================


sub_10C4E:
                move.w  $A(a0),d0
                andi.w  #$1F,d0
                move.w  d0,-(sp)
                asl.w   #2,d0
                lea     (ram_FF310A).l,a2
                move.w  (a2,d0.w),d7
                move.w  (sp)+,d0
                move.w  d0,d2
                move.w  (ram_FF1E6A).l,d1
                andi.w  #$FF00,d1
                lsr.w   #8,d1
                neg.w   d1
                asl.w   #8,d0
                add.w   d1,d0
                move.w  d0,$E(a0)
                move.w  d0,d1
                addi.w  #$100,d0
                clr.l   d3
                move.w  d6,d3
                andi.w  #$F0,d3
                asl.w   #3,d3
                cmp.w   d3,d1
                addi.w  #$200,d1
                addi.w  #$200,d3
                swap    d3
                lsr.l   #2,d3
                divu.w  d1,d3
                move.w  d3,4(a0)
                andi.w  #$F,d6
                move.w  d6,d5
                swap    d6
                clr.w   d6
                lsr.l   #2,d6
                ext.l   d7
                ext.l   d5
                asl.l   #6,d5
                btst    #$E,$A(a0)
                beq.w   .loc_10CCA
                sub.l   d5,d7
                bpl.w   .loc_10CD2
                neg.l   d7
                bra.w   .loc_10CD2


.loc_10CCA:
                add.l   d5,d7
                bpl.w   .loc_10CD2
                neg.l   d7

.loc_10CD2:
                ext.l   d0
                addi.l  #$100,d7
                cmp.l   d0,d7
                bpl.w   .loc_10D32
                divu.w  d0,d6
                bvs.w   .loc_10D32
                asl.w   #1,d2
                lea     (ram_FF3236).l,a2
                move.w  (a2,d2.w),d0
                move.w  d0,d3
                lea     (ram_FFD77C).l,a2
                cmp.w   (a2,d2.w),d0
                move.w  (a2,d2.w),6(a0)
                move.w  d0,2(a0)
                lea     (ram_FF31D2).l,a2
                move.w  (a2,d2.w),d0
                neg.w   d0
                btst    #$E,$A(a0)
                bne.w   .loc_10D20
                neg.w   d6

.loc_10D20:
                move.w  d6,$C(a0)
                add.w   d6,d0
                bmi.w   .loc_10D32
                cmp.w   #$23C,d0
                bmi.w   .loc_10D38

.loc_10D32:
                suba.w  #$14,a0
                rts


.loc_10D38:
                neg.w   d0
                move.w  d0,(a0)
                addi.w  #1,(ram_FFDE72).l
                rts
; End of function sub_10C4E


; =============== S U B R O U T I N E =======================================


Road_BuildVisibleList:
                movem.l d0-d7/a0-a7,-(sp)
                move.l  (a0)+,(a1)
                move.w  #0,(a2)
                cmpi.w  #$FFFF,(a1)
                beq.w   .loc_10DAC
                move.w  #1,d0
.loc_10D5C:
                move.w  d0,d1
                subq.w  #1,d1
                movea.l a1,a3
                movea.l a2,a4
                move.l  (a0)+,d4
                cmp.w   #$FFFF,d4
                beq.w   .loc_10DAC
.loc_10D6E:
                cmp.l   (a3)+,d4
                bmi.w   .loc_10D86
                dbf     d1,.loc_10D6E
                move.l  d4,(a3)
                move.w  d0,d6
                asl.w   #1,d6
                move.w  d0,(a4,d6.w)
                bra.w   .loc_10DA8
.loc_10D86:
                move.w  d0,d6
                sub.w   d1,d6
                subq.w  #1,d6
                asl.w   #1,d6
                adda.w  d6,a4
                move.w  d0,d6
                subq.l  #4,a3
.loc_10D94:
                move.l  (a3),d5
                move.l  d4,(a3)+
                move.l  d5,d4
                move.w  (a4),d7
                move.w  d6,(a4)+
                move.w  d7,d6
                dbf     d1,.loc_10D94
                move.l  d4,(a3)
                move.w  d6,(a4)
.loc_10DA8:
                addq.w  #1,d0
                bra.s   .loc_10D5C
.loc_10DAC:
                asl.w   #1,d0
                move.w  d4,(a2,d0.w)
                asl.w   #1,d0
                move.l  d4,(a1,d0.w)
                movem.l (sp)+,d0-d7/a0-a7
                rts
; End of function Road_BuildVisibleList


; =============== S U B R O U T I N E =======================================


sub_10DBE:
                movea.l (Global_ram_PalettePtr).l,a0
                adda.w  #$1A,a0
                lea     (RacePlayerA).l,a1
                lea     (ram_FF1AFA).l,a2
                bsr.w   sub_10E00
                rts
; End of function sub_10DBE


; =============== S U B R O U T I N E =======================================


sub_10DDA:
                movea.l (Global_ram_PalettePtr).l,a0
                adda.w  #$5A,a0 ; 'Z'
                movea.l (ram_FF1908).l,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_10DFE
                lea     (ram_FF1B04).l,a2
                bsr.w   sub_10E00

.locret_10DFE:
                rts
; End of function sub_10DDA


; =============== S U B R O U T I N E =======================================



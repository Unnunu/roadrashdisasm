RoadMarking_dPatterns:
    dc.l $00000000
    dc.l $C0000000
    dc.l $CC000000
    dc.l $CCC00000
    dc.l $CCCC0000
    dc.l $CCCCC000
    dc.l $CCCCCC00
    dc.l $CCCCCCC0
    dc.l $CCCCCCCC
    dc.l $CCCCCCCC
    dc.l $CCCCCCCC

; *************************************************
; Function RoadMarking_Draw
; *************************************************

RoadMarking_Draw:
; clear 16 words in RoadMarking_ram_WidthArray
                lea     RoadMarking_ram_WidthArray,a0
                move.w  #$F,d0
@loopClear:
                move.w  #0,(a0)+
                dbf     d0,@loopClear

@loopDraw:
                move.w  Animation_ram_TileIndex,d2
                asl.w   #5,d2
                move.w  d2,RoadMarking_TileOffset
                bsr.w   RoadMarking_FindUnprocessedLine
                tst.w   d0
                bmi.w   @return

                movem.l d0/a0-a1,-(sp) ; save arguments for RoadMarking_CreateSprite
                bsr.w   RoadMarking_GetMarkingsSizes
                bsr.w   RoadMarking_SetSpriteGeometry
                bsr.w   RoadMarking_ClearSpriteTiles
                movem.l (sp)+,d0/a0-a1 ; restore arguments for RoadMarking_CreateSprite
                bsr.w   RoadMarking_CreateSprite
                cmpi.w  #80,Animation_ram_SpriteIndex ; don't create more than 128 sprites
                bpl.w   @return
                bra.s   @loopDraw

@return:
                rts
; End of function RoadMarking_Draw

; *************************************************
; Function RoadMarking_FindUnprocessedLine
; d0 - (out) PosY of the line
; a0 - (out) pointer in x array
; a1 - (out) pointer in width array
; *************************************************

RoadMarking_FindUnprocessedLine:
                lea     RoadMarking_ram_XArray,a0
                lea     RoadMarking_ram_WidthArray + $98 * 2,a1

                move.w  #$98 - 1,d0
@loc_E7C0:
                tst.w   -(a1)
                dbne    d0,@loc_E7C0

                tst.w   d0
                bmi.w   @return

                move.l  a1,d0
                subi.l  #RoadMarking_ram_WidthArray,d0
                adda.l  d0,a0
                asr.w   #1,d0
@return:
                rts
; End of function RoadMarking_FindUnprocessedLine

; *************************************************
; Function RoadMarking_GetMarkingsSizes
; d0 - PosY of the bottom edge of the road
; a0 - end of x array
; a1 - end of width array
; *************************************************

RoadMarking_GetMarkingsSizes:
                lea     2(a0),a0 ; increment x array pointer
                lea     2(a1),a1 ; increment width array pointer

                move.w  #0,RoadMarking_ram_X1
                move.w  #0,RoadMarking_ram_Width1
                move.w  #0,RoadMarking_ram_X2
                move.w  #0,RoadMarking_ram_Width2

                move.w  #0,RoadMarking_ram_X3
                move.w  #0,RoadMarking_ram_Width3
                move.w  #0,RoadMarking_ram_X4
                move.w  #0,RoadMarking_ram_Width4

                subq.w  #8,d0
                bmi.w   @return
; find min and max X in last cell
                move.w  #1000,d2 ; minimal X_left value
                move.w  #0,d3 ; maximal X_right value
                move.w  #7,d1 ; counter
@loc_E834:
                move.w  -(a0),d4 ; get X_left
                tst.w   -(a1) ; get width
                beq.w   @continue
                cmp.w   d4,d2
                ble.w   @checkXright
                move.w  d4,d2
@checkXright:
                add.w   (a1),d4
                cmp.w   d4,d3
                bpl.w   @continue
                move.w  d4,d3
@continue:
                dbf     d1,@loc_E834

                tst.w   d3
                beq.w   @loc_E866
                move.w  d2,RoadMarking_ram_X1
                sub.w   d2,d3
                move.w  d3,RoadMarking_ram_Width1
@loc_E866:
                subq.w  #8,d0
                bmi.w   @return
; find min and max X in previous cell
                move.w  #1000,d2
                move.w  #0,d3
                move.w  #7,d1
@loc_E878:
                move.w  -(a0),d4
                tst.w   -(a1)
                beq.w   @loc_E892
                cmp.w   d4,d2
                ble.w   @loc_E888
                move.w  d4,d2
@loc_E888:
                add.w   (a1),d4
                cmp.w   d4,d3
                bpl.w   @loc_E892
                move.w  d4,d3
@loc_E892:
                dbf     d1,@loc_E878
                tst.w   d3
                beq.w   @loc_E8AA
                move.w  d2,RoadMarking_ram_X2
                sub.w   d2,d3
                move.w  d3,RoadMarking_ram_Width2
@loc_E8AA:
                subq.w  #8,d0
                bmi.w   @return
; find min and max X in cell before previous
                move.w  #1000,d2
                move.w  #0,d3
                move.w  #7,d1
@loc_E8BC:
                move.w  -(a0),d4
                tst.w   -(a1)
                beq.w   @loc_E8D6
                cmp.w   d4,d2
                ble.w   @loc_E8CC
                move.w  d4,d2
@loc_E8CC:
                add.w   (a1),d4
                cmp.w   d4,d3
                bpl.w   @loc_E8D6
                move.w  d4,d3
@loc_E8D6:
                dbf     d1,@loc_E8BC
                tst.w   d3
                beq.w   @loc_E8EE
                move.w  d2,RoadMarking_ram_X3
                sub.w   d2,d3
                move.w  d3,RoadMarking_ram_Width3
@loc_E8EE:
                subq.w  #8,d0
                bmi.w   @return

                move.w  #1000,d2
                move.w  #0,d3
                move.w  #7,d1
@loc_E900:
                move.w  -(a0),d4
                tst.w   -(a1)
                beq.w   @loc_E91A
                cmp.w   d4,d2
                ble.w   @loc_E910
                move.w  d4,d2
@loc_E910:
                add.w   (a1),d4
                cmp.w   d4,d3
                bpl.w   @loc_E91A
                move.w  d4,d3
@loc_E91A:
                dbf     d1,@loc_E900
                tst.w   d3
                beq.w   @return
                move.w  d2,RoadMarking_ram_X4
                sub.w   d2,d3
                move.w  d3,RoadMarking_ram_Width4
@return:
                rts
; End of function RoadMarking_GetMarkingsSizes

; *************************************************
; Function RoadMarking_SetSpriteGeometry
; *************************************************

RoadMarking_SetSpriteGeometry:
                move.w  #1,RoadMarking_SpriteVerticalSize

                move.w  RoadMarking_ram_X1,d0
                move.w  d0,d1
                move.w  RoadMarking_ram_Width1,d2
                add.w   d2,d1
                move.w  RoadMarking_ram_X2,d3
                move.w  d3,d4
                move.w  RoadMarking_ram_Width2,d5

                ble.w   @setPosX

                add.w   d5,d4
                move.w  d3,d6
                sub.w   d0,d6
                cmp.w   #$20,d6
                bpl.w   @setPosX
                add.w   d5,d6
                cmp.w   #$FFE0,d6
                ble.w   @setPosX
                move.w  d0,d6
                sub.w   d3,d6
                ble.w   @tallSprite

                move.w  #$20,d7
                sub.w   d2,d7
                cmp.w   d7,d6
                ble.w   @loc_E98C
                move.w  d7,d6
@loc_E98C:
                sub.w   d6,d0
                add.w   d6,d2
@tallSprite:
                move.w  #2,RoadMarking_SpriteVerticalSize
                move.w  d4,d6
                sub.w   d0,d6
                cmp.w   #$20,d6
                bmi.w   @loc_E9A8
                move.w  #$20,d6
@loc_E9A8:
                cmp.w   d6,d2
                bpl.w   @setPosX

                move.w  d6,d2
                move.w  d0,d1
                add.w   d2,d1
@setPosX:
                move.w  d0,RoadMarking_SpritePosX
                cmp.w   #$20,d2 ; d2 is width in pixels, can't be greater than 32
                bmi.w   @loc_E9C6
                move.w  #$1F,d2
@loc_E9C6:
                asr.w   #3,d2
                addq.w  #1,d2
                move.w  d2,RoadMarking_SpriteHorizontalSize
                rts
; End of function RoadMarking_SetSpriteGeometry

; *************************************************
; Function RoadMarking_ClearSpriteTiles
; *************************************************
RoadMarking_ClearSpriteTiles:
                movea.l Race_ram_CurrentSpriteTileArray,a0
                adda.w  RoadMarking_TileOffset,a0
                moveq   #0,d1
                move.w  RoadMarking_SpriteHorizontalSize,d0
                mulu.w  RoadMarking_SpriteVerticalSize,d0
                asl.w   #3,d0
                subq.w  #1,d0
@loopClear:
                move.l  d1,(a0)+
                dbf     d0,@loopClear
                rts
; End of function RoadMarking_ClearSpriteTiles

; *************************************************
; Function RoadMarking_CreateSprite
; d0 - PosY of the bottom edge of the sprite
; a0 - x array, pointing to the last value
; a1 - width array, pointing to the last value
; *************************************************

RoadMarking_CreateSprite:
                movea.l Race_ram_CurrentSpriteTileArray,a2
                adda.w  RoadMarking_TileOffset,a2 ; get tile array pointer
                movea.l Race_ram_CurrentSpriteAttributeTable,a3
                move.w  Animation_ram_SpriteIndex,d1
                asl.w   #3,d1
                adda.w  d1,a3 ; get sprite table pointer
                move.b  (Animation_ram_SpriteIndex + 1),-5(a3) ; set previous sprite link, use only lower byte of sprite index
; word 0
                move.w  RoadMarking_SpriteVerticalSize,d1
                asl.w   #3,d1 ; sprite height in pixels
                subq.w  #1,d1
                neg.w   d1
                add.w   d0,d1
                move.w  d1,(a3) ; posY
                addi.w  #$80,(a3)+ ; add $80 to posY
; word 1
                move.w  RoadMarking_SpriteVerticalSize,d1
                subq.w  #1,d1
                asl.w   #8,d1 ; VS bits
                move.w  RoadMarking_SpriteHorizontalSize,d2
                subq.w  #1,d2
                ror.w   #6,d2 ; HS bits
                or.w    d2,d1
                move.w  d1,(a3)+ ; next link = 0
; word 2
                move.w  #$6000,d1 ; priority = 0, palette = 3
                add.w   Animation_ram_BaseTile,d1
                add.w   Animation_ram_TileIndex,d1 ; get current tile index
                move.w  d1,(a3)+
; word 3
                move.w  RoadMarking_SpritePosX,(a3) ; posX
                addi.w  #$80,(a3)+ ; add $80 to posX
; increment indexes
                addi.w  #1,Animation_ram_SpriteIndex
                move.w  RoadMarking_SpriteHorizontalSize,d1
                mulu.w  RoadMarking_SpriteVerticalSize,d1
                add.w   d1,Animation_ram_TileIndex

                move.w  RoadMarking_SpriteVerticalSize,d1
                asl.w   #3,d1 ; height in pixels
                subq.w  #1,d1 ; height - 1
                asl.w   #2,d1 ; (height - 1) * 4
                adda.w  d1,a2 ;  offset of the last line
                move.w  RoadMarking_SpriteVerticalSize,d1
                asl.w   #5,d1 ;  height * 4
                move.w  d1,RoadMarking_ColumnSizeBytes
                move.w  RoadMarking_SpriteVerticalSize,d1
                asl.w   #3,d1
                subq.w  #1,d1 ; height - 1
; create tiles line by line
@loop:
                move.w  (a1),d2 ; width
                beq.w   @continue
                move.w  (a0),d3 ; x_left
                sub.w   RoadMarking_SpritePosX,d3 ; get X_left relative to left edge of the sprite
                bpl.w   @loc_EAC4 ; jump if X_left > 0

                add.w   d3,d2 ; X_right = X_left + width
                bmi.w   @continue ; if X_right < 0, it can't be drawn
                move.w  #0,d3 ; X_left = 0
                bra.w   @loc_EAE0
@loc_EAC4:
                cmp.w   #$20,d3
                bpl.w   @continue ; if X_left > 4 * 8, it can't be drawn inside this sprite
                move.w  d3,d4
                add.w   d2,d4
                cmp.w   #$20,d4
                bmi.w   @loc_EAE0
 ; if X_right >= 4 * 8, we can't draw part which is to the right of this sprite
                subi.w  #$20,d4 ; d4 = X_right - 32
                sub.w   d4,d2 ; width -= (X_right - 32)
                add.w   d2,(a0) ; write new value of X_left to the table
@loc_EAE0:
                sub.w   d2,(a1) ; decrease the value of width in the table
                lea     RoadMarking_dPatterns,a3
                asl.w   #2,d2
                move.l  (a3,d2.w),d2 ; get pattern of width d2
                movea.l a2,a3

@loopFindColumn:
                cmp.w   #8,d3
                bmi.w   @loc_EB02
                subq.w  #8,d3
                adda.w  RoadMarking_ColumnSizeBytes,a3
                bra.s   @loopFindColumn

@loc_EB02:
                clr.l   d4
                asl.w   #2,d3
                beq.w   @drawLine
                subq.w  #1,d3
; shift 4-word value in d2:d4 by d3 bits
@loopShift:
                lsr.l   #1,d2
                roxr.l  #1,d4
                dbf     d3,@loopShift

@drawLine:
; d2 - value of line in first column, d4 - value of line in second column
                move.l  d2,(a3)
                tst.l   d4
                beq.w   @continue
                move.w  RoadMarking_SpriteVerticalSize,d2
                asl.w   #5,d2
                move.l  d4,(a3,d2.w)
@continue:
                subq.w  #2,a0 ; previous x
                subq.w  #2,a1 ; previous width
                subq.w  #4,a2 ; previous line
                dbf     d1,@loop

                rts
; End of function RoadMarking_CreateSprite
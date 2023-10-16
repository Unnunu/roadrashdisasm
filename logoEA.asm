; RAM memory map
LogoEA_ram_TextTimer                equ     $FFFFC000
LogoEA_ram_FigureAnimationFrame      equ     $FFFFC002
LogoEA_ram_NextUpdateTimer          equ     $FFFFC004
LogoEA_ram_LineValue                equ     $FFFFC006
LogoEA_ram_CurrentFigure            equ     $FFFFC00A
LogoEA_ram_SquareYArray             equ     $FFFFC00C
LogoEA_ram_SquareDataArray          equ     $FFFFC030
LogoEA_ram_TriangleYArray           equ     $FFFFC054
LogoEA_ram_TriangleDataArray        equ     $FFFFC078
LogoEA_ram_CircleYArray             equ     $FFFFC09C
LogoEA_ram_CircleDataArray          equ     $FFFFC0C0
LogoEA_ram_TilesSquare              equ     $FFFFC0E4
LogoEA_ram_TilesTriangle            equ     $FFFFC9E4
LogoEA_ram_TilesCircle              equ     $FFFFD2E4
LogoEA_ram_ImageEAUncompressed      equ     $FFFFDBE4
LogoEA_ram_UncompressTempBuffer     equ     $FFFFE7E4

; *************************************************
; Function LogoEA_GameTick
; *************************************************

LogoEA_GameTick:
    bsr.w   LogoEA_Update
    rts

; end of function LogoEA_GameTick

; *************************************************
; Function LogoEA_AddSpritesVPos
; a0 - sprite vartical position array
; a5 - VdpData
; d1 - deltaY
; *************************************************

LogoEA_AddSpritesVPos:
    moveq   #$FFFFFFFC,d2   ; -4
    muls.w  d1,d2           ; -first strip gets displaced by -4*deltaY, second by -3*deltaY an so on
                            ; 9th strip gets displaced by 4*deltaY
    moveq   #8,d0           ; repeat for 9 strips
@loop:
    add.w   d2,(a0)         ; add VPos for left sprite
    move.w  (a0)+,(a5)      ; write to VdpData
    add.w   d2,(a0)         ; add VPos for right sprite
    move.w  (a0)+,(a5)      ; write to VdpData
    add.w   d1,d2           ; increment displacement
    dbf     d0,@loop
    rts
; End of function LogoEA_AddSpritesVPos

; *************************************************
; Function LogoEA_SetSpritesVerticalFlip
; a0 - sprite Data Array
; a5 - VdpData
; d1 - vertical flip value ($1000 or $0)
; *************************************************

LogoEA_SetSpritesVerticalFlip:
    moveq   #$11,d0     ; loop through 18 sprites
@loop:
    move.w  (a0)+,d2    ; read sprite data value
    andi.w  #$EFFF,d2   ; clear old vflip flag
    or.w    d1,d2       ; set vflip value
    move.w  d2,(a5)     ; write to VdpData
    dbf     d0,@loop
    rts
; End of function LogoEA_SetSpritesVerticalFlip

; *************************************************
; Function LogoEA_SetSquareSpritesHPos
; d1 - distance between left edges of sprites
; d3 - left sprite HPos
; a5 - VdpData
; *************************************************

LogoEA_SetSquareSpritesHPos:
    movem.w d0-d7,-(sp)
    move.w  d3,d4   ; save left sprite HPos to d4
    addi.w  #$20,d3 ; right sprite Hpos + 32px
    moveq   #$20,d5
    sub.w   d1,d5
    asr.w   #1,d5   ; d5 = (32 - d1) / 2
    add.w   d5,d4
    sub.w   d5,d3

    addi.w  #$80,d4 ; HPos of left sprite
    addi.w  #$80,d3 ; HPos of right sprite

    moveq   #8,d0   ; repeat for 9 strips
@loop:
    move.w  d4,(a5) ; set left sprite HPos
    move.w  d3,(a5) ; set right sprite HPos
    dbf     d0,@loop

    movem.w (sp)+,d0-d7
    rts
; End of function LogoEA_SetSquareSpritesHPos

; *************************************************
; Function LogoEA_SetTriangleSpritesHPos
; d3 - left sprite HPos
; a5 - VdpData
; *************************************************

LogoEA_SetTriangleSpritesHPos:
    movem.w d0-d7,-(sp)
    move.w  d3,d4   ; save left sprite HPos to d4
    addi.w  #$20,d3 ; right sprite Hpos + 32px
    addi.w  #$80,d4 ; HPos of left sprite
    addi.w  #$80,d3 ; HPos of right sprite

    moveq   #8,d0   ; repeat for 9 strips
@loop:
    move.w  d4,(a5) ; set left sprite HPos
    move.w  d3,(a5) ; set right sprite HPos
    dbf     d0,@loop

    movem.w (sp)+,d0-d7
    rts
; End of function LogoEA_SetTriangleSpritesHPos

; *************************************************
; Function LogoEA_ShowSprites
; d1 - number of strips
; d2 - first link
; d3 - last link
; a5 - VdpData
; *************************************************

LogoEA_ShowSprites:
                movem.w d1-d3,-(sp)
                ori.w   #$C00,d2    ; set size 4x1 tiles
                ori.w   #$C00,d3    ; set size 4x1 tiles
                bra.s   @continue

@loop:
                move.w  d2,(a5)     ; set link for left sprite
                addq.w  #1,d2       ; increment link
                move.w  d2,(a5)     ; set link for right sprite
                addq.w  #1,d2       ; increment link
@continue:
                dbf     d1,@loop    ; repeat d1 times

                move.w  d2,(a5)     ; write links for last strip
                move.w  d3,(a5)
                movem.w (sp)+,d1-d3
                rts
; End of function LogoEA_ShowSprites

; *************************************************
; Function LogoEA_Update
; *************************************************

LogoEA_Update:
                movea.l #VdpCtrl,a4
                movea.l #VdpData,a5
                tst.w   (LogoEA_ram_TextTimer).w
                blt.w   @checkFinish    ; jump if text 'Electronic Arts' fully shown
                move.w  (LogoEA_ram_TextTimer).w,d0
                subq.w  #1,(LogoEA_ram_TextTimer).w
                move.w  d0,d1
                neg.w   d0
                VDP_VRAM_WRITE $2000 ; write HScroll Data Table
                moveq   #$6F,d2
; update 'Electronic Arts' text position
@loopWriteScrollTable:
                move.w  d0,(a5)     ; fg
                move.w  #$140,(a5)  ; bg
                move.w  d1,(a5)     ; fg
                move.w  #$140,(a5)  ; bg
                dbf     d2,@loopWriteScrollTable

@checkFinish:
                subq.w  #1,(LogoEA_ram_NextUpdateTimer).w
                bge.w   @end
                move.w  #2,(LogoEA_ram_NextUpdateTimer).w ; update every 3 frames
                tst.w   (LogoEA_ram_FigureAnimationFrame).w ; figures have appeared completely
                bne.s   @doUpdate
                tst.w   (LogoEA_ram_TextTimer).w ; text has appeared completely
                bge.s   @doUpdate
                st      LogoEA_ram_Finished ; set finished flag
                rts
@doUpdate:
                addq.w  #1,(LogoEA_ram_FigureAnimationFrame).w
                move.w  (LogoEA_ram_FigureAnimationFrame).w,d7
; write circle tiles to VRAM
                lea     (LogoEA_ram_TilesCircle).w,a3
                move.w  #$23F,d0
                VDP_VRAM_WRITE $4920
@loopWriteCircleToVRAM:
                move.l  (a3)+,(a5)
                dbf     d0,@loopWriteCircleToVRAM

                cmp.w   #$18,d7
                ble.s   @doUpdate2
; do this check on 25th frame of animation
                clr.w   (LogoEA_ram_FigureAnimationFrame).w
                addq.w  #1,(LogoEA_ram_CurrentFigure).w ; next figure
                cmpi.w  #2,(LogoEA_ram_CurrentFigure).w
                ble.w   @end
                clr.w   (LogoEA_ram_CurrentFigure).w
                move.w  #180,(LogoEA_ram_NextUpdateTimer).w ; wait 3 seconds
                bra.w   @end

@doUpdate2:
                VDP_VRAM_WRITE $C000 ; Window name table
                move.w  #$8F08,VdpCtrl ; set auto increment = 8
                cmp.w   #$D,d7
                bge.w   @checkUnflip ; jump when animFrame >= 13
                cmp.w   #7,d7
                bne.w   @decreaseScale; jump when animFrame != 7
; animFrame is 7, flip sprites and make them darker
; set square palette
                move.w  #$1000,d1 ; enable vertical flip
                cmpi.w  #0,(LogoEA_ram_CurrentFigure).w
                bne.s   @setCirclePalette
                VDP_CRAM_WRITE $C
                move.w  #$A0,VdpData ; color #6 : (0, A, 0), dark green
                VDP_CRAM_WRITE $8
                move.w  #$A0,VdpData ; color #4 : (0, A, 0), dark green
                VDP_CRAM_WRITE $A
                move.w  #$4E4,VdpData ; color #5 : (4, E, 4), green
                lea     (LogoEA_ram_SquareDataArray).w,a0
                move.w  #$5C04,VdpCtrl ; square sprite table + 4
                bra.w   @flipSprites

@setCirclePalette:
                cmpi.w  #1,(LogoEA_ram_CurrentFigure).w
                bne.s   @setTrianglePalette
                VDP_CRAM_WRITE $14 ; color #A : (2, 4, A), dark blue
                move.w  #$A42,VdpData
                VDP_CRAM_WRITE $1A ; color #D : (2, 4, A), dark blue
                move.w  #$A42,VdpData
                VDP_CRAM_WRITE $6 ; color #3 : (6, 8, E), blue
                move.w  #$E86,VdpData
                lea     (LogoEA_ram_CircleDataArray).w,a0
                move.w  #$5C94,VdpCtrl ; circle sprite table + 4
                bra.s   @flipSprites

@setTrianglePalette:
                VDP_CRAM_WRITE $16
                move.w  #$8A,VdpData ; color #B : (A, 8, 0), yellow
                VDP_CRAM_WRITE $1C
                move.w  #$8A,VdpData ; color #E : (A, 8, 0), yellow
                VDP_CRAM_WRITE $4
                move.w  #$CE,VdpData ; color #2 : (E, C, 0), light yellow
                lea     (LogoEA_ram_TriangleDataArray).w,a0
                move.w  #$5D24,VdpCtrl ; triangle sprite table + 4

@flipSprites:
                bsr.w   LogoEA_SetSpritesVerticalFlip

@decreaseScale:
                moveq   #$FFFFFFFF,d1 ; animFrame < 13, shrink figures
                bra.w   @checkSquareSetPos

@checkUnflip:
                cmp.w   #$14,d7
                bne.w   @increaseScale
; animFrame = 20, unflip sprites and restore shadows
                moveq   #0,d1
                cmpi.w  #0,(LogoEA_ram_CurrentFigure).w
                bne.s   @checkUnflipCircle
; reset square palette
                VDP_CRAM_WRITE $C
                move.w  #$4E4,VdpData ; color #6 : (4, E, 4), green
                VDP_CRAM_WRITE $8
                move.w  #$8E8,VdpData ; color #4 : (8, E, 8), light green
                VDP_CRAM_WRITE $A
                move.w  #$A0,VdpData  ; color #5 : (0, A, 0), dark green
                lea     (LogoEA_ram_SquareDataArray).w,a0
                move.w  #$5C04,VdpCtrl  ; square sprite table + 4
                bra.w   @disableVFlip

@checkUnflipCircle:
                cmpi.w  #1,(LogoEA_ram_CurrentFigure).w
                bne.s   @checkUnflipTriangle
; reset circle palette    
                VDP_CRAM_WRITE $14
                move.w  #$E86,VdpData ; color #A : (6, 8, E), blue
                VDP_CRAM_WRITE $1A
                move.w  #$ECA,VdpData ; color #D : (A, C, E), light blue
                VDP_CRAM_WRITE $6
                move.w  #$A42,VdpData ; color #3 : (2, 4, A), dark blue
                lea     (LogoEA_ram_CircleDataArray).w,a0
                move.w  #$5C94,VdpCtrl ; circle sprite table + 4
                bra.s   @disableVFlip

@checkUnflipTriangle:
                VDP_CRAM_WRITE $16
                move.w  #$CE,VdpData ; color #B : (E, C, 0), yellow
                VDP_CRAM_WRITE $1C
                move.w  #$8EE,VdpData ; color #E : (E, E, 8), light yellow
                VDP_CRAM_WRITE $4
                move.w  #$8A,VdpData ; color #2 : (A, 8, 0), dark yellow
                lea     (LogoEA_ram_TriangleDataArray).w,a0
                move.w  #$5D24,VdpCtrl ; triangle sprite table + 4

@disableVFlip:
                bsr.w   LogoEA_SetSpritesVerticalFlip

@increaseScale:
                moveq   #1,d1

@checkSquareSetPos:
                cmpi.w  #0,(LogoEA_ram_CurrentFigure).w ; is square
                bne.s   @checkCircleSetPos
                move.w  #$5C00,VdpCtrl ; square sprite table
                lea     (LogoEA_ram_SquareYArray).w,a0

@checkCircleSetPos:
                cmpi.w  #1,(LogoEA_ram_CurrentFigure).w ; is circle
                bne.s   @checkTriangleSetPos
                move.w  #$5C90,VdpCtrl ; circle sprite table
                lea     (LogoEA_ram_CircleYArray).w,a0

@checkTriangleSetPos:
                cmpi.w  #2,(LogoEA_ram_CurrentFigure).w ; is triangle
                bne.s   @setFigurePosY
                move.w  #$5D20,VdpCtrl ; triangle sprite table
                lea     (LogoEA_ram_TriangleYArray).w,a0

@setFigurePosY:
                bsr.w   LogoEA_AddSpritesVPos

                move.w  d7,d1
                ext.l   d1
                divu.w  #3,d1 ; d1 = animFrame / 3, number of strips shown
                cmpi.w  #0,(LogoEA_ram_CurrentFigure).w
                bne.s   @checkTriangleSetPosX
; update square HPos
                move.w  d1,-(sp)
                asl.w   #2,d1 ; d1 = animFrame / 3 * 4
                move.w  #$68,d3
                sub.w   d7,d3 ; posX = 104 - animFrame
                move.w  #$5C06,VdpCtrl ; square sprite table + 6
                bsr.w   LogoEA_SetSquareSpritesHPos
                move.w  (sp)+,d1
; show square                
                moveq   #1,d2 ; first sprite link
                moveq   #$12,d3 ; last sprite link
                moveq   #0,d3 ; override last link, show only square
                move.w  #$5C02,VdpCtrl ; square sprite table + 2
                bsr.w   LogoEA_ShowSprites
                move.w  #$4E4,d0 ; color (4,E,4) - green
                bsr.w   LogoEA_ChangeTextColor
                bra.s   @endUpdateSquareOrTriangle

@checkTriangleSetPosX:
                cmpi.w  #2,(LogoEA_ram_CurrentFigure).w
                bne.s   @updateCircle
; update triangle X
                move.w  d1,-(sp)
                asl.w   #2,d1 ; d1 = animFrame / 3 * 4
                move.w  #$98,d3
                add.w   d7,d3 ; posX = 152 - animFrame
                move.w  #$5D26,VdpCtrl ; triangle sprite table + 6
                bsr.w   LogoEA_SetTriangleSpritesHPos
                move.w  (sp)+,d1
                move.w  #$5D1A,VdpCtrl; last sprite of circle + 2
                move.w  #$C24,(a5) ; size 4x1, link = $24 = 36, advance to triangle sprite table + 2
                moveq   #$25,d2 ; first sprite link
                moveq   #0,d3 ; last sprite link
                bsr.w   LogoEA_ShowSprites
                move.w  #$CE,d0 ; color (E,C,0) - yellow
                bsr.w   LogoEA_ChangeTextColor

@endUpdateSquareOrTriangle:
                bra.s   @end
@updateCircle:
                move.w  #$5C8A,VdpCtrl ; last sprite of square + 2
                move.w  #$C12,(a5) ; link = $12 = 18, advance to circle sprite table + 2
                moveq   #$13,d2 ; first sprite link
                moveq   #0,d3 ; last sprite link
                bsr.w   LogoEA_ShowSprites
                move.w  #$E86,d0 ; color (6,8,E) - blue
                bsr.w   LogoEA_ChangeTextColor
                lea     (LogoEA_ram_TilesCircle).w,a3
; clear circle image
                moveq   #0,d2
                move.w  #$23F,d0
@loopClearCircleImage:
                move.l  d2,(a3)+
                dbf     d0,@loopClearCircleImage

                add.w   d1,d1
                addq.w  #4,d1 ; d1 = 2 * animFrame + 4

                cmp.w   #$10,d1
                ble.s   @drawCircle
                moveq   #$10,d1
@drawCircle:
                moveq   #$20,d3
                movea.w d3,a1
                subq.w  #1,a1
                move.w  #$10,d0
                sub.w   d1,d0
                add.w   d0,d3
                suba.w  d0,a1
                bsr.w   LogoEA_DrawCircle

@end:
                move.w  #$8F02,VdpCtrl ; Auto increment : $2
                moveq   #0,d0
                rts
; End of function LogoEA_Update

; *************************************************
; Function LogoEA_CreateSprite
; a0 - sprite Vpos array address
; a1 - sprite data array address
; a5 - VdpData
; d1 - sprite index
; d2 - HPos
; d3 - VPos
; d4 - tile index
; *************************************************

LogoEA_CreateSprite:
                move.w  #$80,(a0)   ; add $80 to sprite Hpos
                add.w   d3,(a0)
                move.w  (a0)+,(a5)
                move.w  #$C00,d0    ; size 4x1 tiles
                or.w    d1,d0       ; set link to next sprite
                addq.w  #1,d1
                move.w  d0,(a5)
                move.w  #$8201,(a1) ; high priority, palette line 0, no flip, VRAM tile number $201 + d4
                add.w   d4,(a1)
                addq.w  #4,d4
                move.w  (a1)+,(a5)
                move.w  #$80,d0   ; add $80 to sprite Hpos
                add.w   d2,d0
                rts
; End of function LogoEA_CreateSprite

; *************************************************
; Function LogoEA_CreateFigureSprites
; a0 - sprite Vpos array address
; a1 - sprite data array address
; a5 - VdpData
; d1 - first sprite link
; d2 - HPos
; d3 - VPos
; d4 - tile index
; d5 - last sprite link
; *************************************************

LogoEA_CreateFigureSprites:
                moveq   #7,d7

@loop:
                bsr.s   LogoEA_CreateSprite
                move.w  d0,(a5)
                bsr.s   LogoEA_CreateSprite
                addi.w  #$20,d0
                move.w  d0,(a5)
                addq.w  #6,d3
                dbf     d7,@loop

                bsr.s   LogoEA_CreateSprite
                move.w  d0,(a5)
                move.w  d5,d1
                bsr.s   LogoEA_CreateSprite
                addi.w  #$20,d0
                move.w  d0,(a5)
                rts
; End of function LogoEA_CreateFigureSprites

; *************************************************
; Function LogoEA_GetSquareLineMemOffset
; d4 - line index
; d5 - memory offset of first tile in strip
; d6 - (out) memory offset of first pixel in this line 
; *************************************************

LogoEA_GetSquareLineMemOffset:
                move.w  d5,d6
                move.w  d4,d7
                asl.w   #2,d7
                add.w   d7,d6
                rts
; End of function LogoEA_GetSquareLineMemOffset

; *************************************************
; Function LogoEA_GetPointOffsets
; d0 - point coordinate (fixed point 16.16)
; d3 - (out) value of 8 pixels in line
; d4.w - (out) memory offset of tile
; d5.w - (out) memory offset within tile in bits
; *************************************************

LogoEA_GetPointOffsets:
                move.l  (LogoEA_ram_LineValue).w,d3
                move.l  d0,d5
                swap    d5  ; get integer part of Xpos
                move.w  d5,d4
                andi.w  #7,d5 
                asl.w   #2,d5 ; memory offset within line in tile
                asr.w   #3,d4
                asl.w   #5,d4 ; memory offset of tile
                rts
; End of function LogoEA_GetPointOffsets

; *************************************************
; Function LogoEA_DrawLine
; a6 - memory address
; d1 - X coordinate of left point (fixed point 16.16)
; d2 - X coordinate of right point (fixed point 16.16)
; *************************************************

LogoEA_DrawLine:
                movem.l d0-d7,-(sp)
                cmp.l   d1,d2 ; check points order
                blt.s   @return

                move.l  d2,d0
                bsr.s   LogoEA_GetPointOffsets
                move.l  d3,d6   ; save line value to d6
                move.w  d4,d7   ; d7 is offset of this line in last tile
                subi.w  #$1C,d5
                neg.w   d5
                asl.l   d5,d6   ; d6 is 8px line in last tile
                move.l  d1,d0
                bsr.s   LogoEA_GetPointOffsets
                lsr.l   d5,d3   ; d3 is 8px line in first tile
                cmp.w   d7,d4   ; d4 is offset of this line in first tile
                bne.s   @firstTile
; only one tile
                and.l   d3,d6
                move.l  d6,(a6,d4.w)
                bra.s   @return

@firstTile:
                move.l  d3,(a6,d4.w)

@loopWriteLine:
                addi.w  #$20,d4 ; go to next tile
                cmp.w   d4,d7   ; if not last tile
                beq.s   @lastTile
                move.l  (LogoEA_ram_LineValue).w,(a6,d4.w) ; write 8px line in this tile
                bra.s   @loopWriteLine

@lastTile:
                move.l  d6,(a6,d7.w)

@return:
                movem.l (sp)+,d0-d7
                rts
; End of function LogoEA_DrawLine

; *************************************************
; Function LogoEA_ChangeTextColor
; d7 - animation frame
; d0 - color
; a5 - VdpData
; *************************************************

LogoEA_ChangeTextColor:
                cmp.w   #$18,d7 ; change color on last animation frame
                bne.s   @return
                VDP_CRAM_WRITE $12 ; set color #9
                move.w  d0,(a5)

                VDP_CRAM_WRITE $2 ; set color #2
                cmp.w   #$E86,d0 ; (6,8,E) - blue
                bne.s   @setColor
                move.w  #$E22,d0 ; (2,2,E) - another blue
@setColor:
                andi.w  #$666,d0 ; make it darker
                move.w  d0,(a5)

@return:
                rts
; End of function LogoEA_ChangeTextColor

; *************************************************
; Function LogoEA_DrawCircle
; d3 - circle center HPos - delta
; a1 - circle center HPos + delta
; *************************************************

LogoEA_DrawCircle:
                lea     LogoEA_dFigureStripThickness,a0
                lea     (LogoEA_ram_TilesCircle).w,a6
                lea     logoEA_dCircleShadowLength,a2
                lea     logoEA_dCircleProfile,a3
                moveq   #0,d6
                moveq   #8,d4
@loopStrip:
                move.b  (a0)+,d5 ; get strip thickness
                ext.w   d5

                moveq   #5,d0 ; repeat for 6 lines
@loopLine:
                move.l  #$AAAAAAAA,(LogoEA_ram_LineValue).w ; general color - blue
                cmp.w   #$1B,d6 ; if lineNo == 27 it's diameter
                beq.s   @calculateCoordinates
                bgt.s   @lowerHalf
                move.b  (a3)+,d7
                bra.s   @calculateCoordinates
@lowerHalf:
                move.b  -(a3),d7
                neg.b   d7
@calculateCoordinates:
                ext.w   d7
                sub.w   d7,d3 ; line left pos
                adda.w  d7,a1 ; line right pos
                addq.w  #1,d6 ; increment line number
                tst.w   d5
                ble.s   @drawShadow
                cmp.w   #1,d5
                bne.s   @notLastLine
                move.l  #$33333333,(LogoEA_ram_LineValue).w ; last line in strip : dark blue color
@notLastLine:
                move.l  d3,d1
                move.l  a1,d2
                cmp.w   #5,d0
                bne.s   @drawLine    
                move.l  #$DDDDDDDD,(LogoEA_ram_LineValue).w ; first line : light blue
                cmp.w   #8,d1
                bge.s   @drawLine
                moveq   #8,d1 ; first line PosX can't be lower than 8.. but why?

@drawLine:
                swap    d1 ; left PosX
                swap    d2 ; right PosX
                bsr.w   LogoEA_DrawLine
                bra.s   @continue

@drawShadow:
                blt.s   @continue ; if line is under the shadow then draw nothing
                move.l  #$33333333,(LogoEA_ram_LineValue).w ; shadow color : dark blue
                move.l  d3,d1
                move.b  (a2)+,d2 ; get shadow length
                ext.w   d2
                add.w   d1,d2
                swap    d1 ; shadow left pos
                swap    d2 ; shadow right pos
                bsr.w   LogoEA_DrawLine

@continue:
                addq.l  #4,a6 ; shift offset to next line
                subq.w  #1,d5 ; decrement strip height counter
                dbf     d0,@loopLine

                adda.l  #$E8,a6 ; shift offset to 3rd line of next strip ($E8 = 2 * 8 * $20 + 8)
                dbf     d4,@loopStrip

                rts
; End of function LogoEA_DrawCircle

; *************************************************
; Function LogoEA_Init
; *************************************************

LogoEA_Init:
                clr.w   LogoEA_ram_Finished
                movea.l #VdpCtrl,a4
                movea.l #VdpData,a5
; clear ram
                move.w  #$3FF6,d0
                moveq   #0,d1
                movea.l #$FFFF0000,a0
@loopClearRAM:
                move.l  d1,(a0)+
                dbf     d0,@loopClearRAM

                move    sr,-(sp)
                ori     #$700,sr
                movea.l #VdpCtrl,a4
                movea.l #VdpData,a5
                move.w  #$8004,(a4)     ; H-ints disabled, Pal Select 1, HVC latch disabled, Display gen enabled
                move.w  #$8134,VdpCtrl  ; Display disabled, V-ints enabled, Height: 28, Mode 5, 64K VRAM
                move.w  #$8228,VdpCtrl  ; Scroll A Name Table:    $A000
                move.w  #$8330,VdpCtrl  ; Window Name Table:      $C000
                move.w  #$8405,VdpCtrl  ; Scroll B Name Table:    $A000
                move.w  #$856E,VdpCtrl  ; Sprite Attribute Table: $DC00
                move.w  #$8700,(a4)     ; Backdrop Color: $0
                move.w  #$8B03,(a4)     ; E-ints disabled, V-Scroll: full, H-Scroll: line
                move.w  #$9003,(a4)     ; Scroll A/B Size: 128x32 (1024x256 pixels)
                move.w  #$8C81,(a4)     ; Width: 40, Shadow/Highlight: disabled
                move.w  #$8D08,VdpCtrl  ; HScroll Data Table:     $2000
                move.w  #$8F02,VdpCtrl  ; Auto-increment: $2
                move.w  #$9100,VdpCtrl  ; WindowX: 0
                move.w  #$9200,VdpCtrl  ; WindowY: 0
                move.w  #$8A01,(a4)     ; H-Int Counter: 1
; clear VRAM
                VDP_VRAM_WRITE $0
                move.w  #$3FFF,d1
                moveq   #0,d0
@loopClearVRAM:
                move.l  d0,(a5)
                dbf     d1,@loopClearVRAM

                moveq   #0,d1
                VDP_VSRAM_WRITE $0
                bsr.s   LogoEA_SetupGfx
                VDP_VRAM_WRITE $2000 ; write HScroll Data Table
                neg.w   d1
                move    (sp)+,sr
                rts
; End of function LogoEA_Init

; *************************************************
; Function LogoEA_SetupGfx
;   a4 : VdpCtrl
;   a5 : VdpData
;   d1 : vertical scroll value
; *************************************************

LogoEA_SetupGfx:
                move.w  d1,(a5) ; write bg vscroll value
                move.w  d1,(a5) ; write fg vscroll value
; create square image in runtime
                lea     (LogoEA_ram_TilesSquare).w,a3
                moveq   #$20,d1 ; tile size
                moveq   #8,d0   ; square consists of 9 strips
                lea     LogoEA_dFigureStripThickness,a0
                moveq   #0,d5

@loopSquareStrip:
                moveq   #0,d4 ; d4 is line index in strip
                moveq   #0,d2
                move.b  (a0)+,d2 ; read strip thickness
                bra.s   @continueLine ; jump to 'continueLine' so we don't need to decrement d2 before this loop
; write pixels of one line
@loopSquareLine:
                bsr.w   LogoEA_GetSquareLineMemOffset ; now d6 is memory offset of first pixel in this line
                movea.l #$66666666,a1 ; all lines except first have green color
                tst.w   d4 ; if not first line
                bne.s   @createLine ; then color isn't changed
                movea.l #$44444444,a1 ; first line in strip has light green color
                
@createLine:
                moveq   #7,d7 ; iterate all 8 tiles which contain this line
@loopNextTile:
                tst.w   d2 ; in the last line of the strip
                bne.s   @write8Pixels 
                cmpa.l  #$44444444,a1 ; change green color
                beq.s   @write8Pixels
                movea.l #$55555555,a1 ; to dark green to make 'shadow'

@write8Pixels:
                move.l  a1,(a3,d6.w) ; write 8 pixels
                add.w   d1,d6 ; jump to next tile
                dbf     d7,@loopNextTile

                addq.w  #1,d4 ; increment line index
@continueLine:
                dbf     d2,@loopSquareLine

                tst.w   d0
                beq.s   @writeSquareToVRAM ; last strip is created                            
                bsr.w   LogoEA_GetSquareLineMemOffset ; now d6 is memory offset of first pixel in this line
                movea.l #$55555555,a1 ; in the line after the last one first 16 pixels are dark green
                move.l  a1,(a3,d6.w) ; write line in first tile
                add.w   d1,d6
                move.l  a1,(a3,d6.w) ; write line in second tile
                addi.w  #$100,d5 ; add memory offset of first tile in strip
                dbf     d0, @loopSquareStrip ;  go to next strip
; load square tiles to VRAM
@writeSquareToVRAM:
                lea     (LogoEA_ram_TilesSquare).w,a3
                move.w  #$23F,d0    ; Write 8 * 9 = 72 tiles of square figure
                VDP_VRAM_WRITE $4020 ; Starting from index $201
@loopWriteSquareTiles:
                move.l  (a3)+,(a5)
                dbf     d0,@loopWriteSquareTiles
    
; create triangle image in runtime
                move.l  #$97B4,d6 ; trinagle edge slope = ($97B4 / $10000) = 0.5925
                move.l  a4,-(sp)
                movea.l d6,a3
                lsr.w   #1,d6
                lea     LogoEA_dFigureStripThickness,a0
                lea     (LogoEA_ram_TilesTriangle + 8).w,a6 ; leave first two lines in tiles blank
                lea     LogoEA_dTriangleShadowWidth,a4
                moveq   #$20,d3
                swap    d3 ; d3 = $200000, it's coordinate of triangle vertex (fixed point 16.16)
                movea.l d3,a2
                movea.l d3,a1 ; right end of the line
                moveq   #8,d4 ; strip counter, draw 9 strips

@loopTriangleStrip:
                move.b  (a0)+,d5 ; get strip thickness
                ext.w   d5
                moveq   #5,d0 ; draw at max 6 lines in strip

@loopTriangleLine:
                move.l  #$BBBBBBBB,(LogoEA_ram_LineValue).w    ; yellow
                tst.w   d5
                ble.s   @drawTriangleShadow
                cmp.w   #1,d5
                bne.s   @checkFirstLine
                move.l  #$22222222,(LogoEA_ram_LineValue).w ; last line in strip is dark yellow

@checkFirstLine:
                cmp.w   #5,d0
                bne.s   @drawTriangleLine
                move.l  #$EEEEEEEE,(LogoEA_ram_LineValue).w ; first line is light yellow

@drawTriangleLine:
                move.l  d3,d1 ; left edge coordinate
                move.l  a1,d2 ; right edge coordinate
                bsr.w   LogoEA_DrawLine

@drawTriangleShadow:
                tst.w   d5
                bne.s   @triangleLineFinished
; draw shadow below the strip
                move.l  #$22222222,(LogoEA_ram_LineValue).w ; dark yellow
                moveq   #0,d2
                move.b  (a4)+,d2 ; get shadow size in pixels
                beq.s   @drawShadowRightPart

                swap    d2 ; convert to 16.16
                add.l   d3,d2 ; add to X of left edge
                move.l  d3,d1 ; from left edge of triangle
                bsr.w   LogoEA_DrawLine ; draw left part of the shadow

@drawShadowRightPart:
                move.l  a2,d1 ; size of right part is always 1/4 of the length of this line
                move.l  a1,d2
                bsr.w   LogoEA_DrawLine ; draw right part of the shadow

@triangleLineFinished:
                addq.l  #4,a6 ; shift offset to next line
                subq.w  #1,d5 ; decrement strip height counter
                sub.l   a3,d3 ; decrement left edge coordinate
                adda.l  a3,a1 ; increment right edge coordinate
                adda.l  d6,a2 ; increment right shadow part coordinate
                dbf     d0,@loopTriangleLine

                adda.l  #$E8,a6 ; shift offset to 3rd line of next strip ($E8 = 2 * 8 * $20 + 8)
                dbf     d4,@loopTriangleStrip

                movea.l (sp)+,a4 ; restore a4
; load triangle tiles to VRAM
                lea     (LogoEA_ram_TilesTriangle).w,a3
                move.w  #$23F,d0   ; Write 8 * 9 = 72 tiles of triangle figure
                VDP_VRAM_WRITE $5220
@loopWriteTriangleTiles:
                move.l  (a3)+,(a5)
                dbf     d0,@loopWriteTriangleTiles

                VDP_VRAM_WRITE $DC00 ; set sprite attr table
                lea     (LogoEA_ram_SquareYArray).w,a0
                lea     (LogoEA_ram_SquareDataArray).w,a1
                moveq   #1,d1   ; first sprite link 1
                moveq   #$50,d2 ; PosX 80
                move.w  #$48,d3 ; PosY 72
                moveq   #0,d4   ; first tile index
                moveq   #$12,d5 ; last sprite link 18
                bsr.w   LogoEA_CreateFigureSprites ; create square sprites
                lea     (LogoEA_ram_CircleYArray).w,a0
                lea     (LogoEA_ram_CircleDataArray).w,a1
                move.w  #$88,d2 ; PosX 136
                move.w  #$48,d3 ; PosY 72
                move.w  #$48,d4 ; first tile index 72
                moveq   #$24,d5 ; last sprite link 36
                bsr.w   LogoEA_CreateFigureSprites ; create circle sprites
                lea     (LogoEA_ram_TriangleYArray).w,a0
                lea     (LogoEA_ram_TriangleDataArray).w,a1
                move.w  #$B0,d2 ; PosX 176
                move.w  #$46,d3 ; PosY 70
                move.w  #$90,d4 ; first tile index 144
                moveq   #0,d5   ; last sprite link 0
                bsr.w   LogoEA_CreateFigureSprites ; create triangle sprites

; create text 'Electronic Arts'
                lea     (LogoEA_ram_ImageEAUncompressed).w,a1
                lea     LogoEA_Image_ElectronicArts,a3
                moveq   #0,d2
                move.b  1(a3),d2
                asl.w   #8,d2
                move.b  (a3),d2
                addq.w  #4,a3
                bsr.w   LogoEA_Uncompress
                lea     (LogoEA_ram_ImageEAUncompressed).w,a1
                move.w  (a1)+,d0 ; number of tiles = 65, 7 extra tiles for 'TM' and something else
                move.w  (a1)+,d1 ; height in tiles = 2
                move.w  (a1)+,d2 ; width in tiles = 29
; load "Electronic Arts" palette to VRAM
                moveq   #$F,d3
                VDP_CRAM_WRITE $0
@loopWritePalette:
                move.w  (a1)+,(a5)
                dbf     d3,@loopWritePalette
; load "Electronic Arts" image to VRAM
                asl.w   #3,d0
                subq.w  #1,d0
                VDP_VRAM_WRITE $20
@loopWriteTextImage:
                move.l  (a1)+,(a5)
                dbf     d0,@loopWriteTextImage

; write 'Electronic Arts' text nametable
                VDP_VRAM_WRITE $8000
                move.w  #$720C,d6 ; ???
                subq.w  #1,d1
                subq.w  #1,d2
                move.w  d2,d0
                move.w  #$8001,d4 ; nametable value : high priority, pal 0, no flip, tile 1

@loopHeight:
                move.w  d6,(a4)
                addi.w  #$100,d6
                move.w  d2,d0
@loopWidth:
                move.w  d4,(a5) ; write nametable entry
                addq.w  #1,d4 ; increment tile index
                dbf     d0,@loopWidth
                dbf     d1,@loopHeight

                move.w  #$7044,(a4) ; ???
                bsr.s   logoEA_WriteNametableEntry
                move.w  #$7144,(a4) ; ???
                bsr.s   logoEA_WriteNametableEntry
                move.w  #$710C,(a4) ; ???
                bsr.s   logoEA_WriteNametableEntry
                move.w  #$7136,(a4) ; ???
                move.w  d4,(a5)
                move.w  #$E2,(LogoEA_ram_TextTimer).w
                rts
; End of function LogoEA_SetupGfx

; *************************************************
; Function logoEA_WriteNametableEntry
; *************************************************

logoEA_WriteNametableEntry:
                move.w  d4,(a5)
                addq.w  #1,d4
                move.w  d4,(a5)
                addq.w  #1,d4
                rts
; End of function logoEA_WriteNametableEntry

; *************************************************
; Function LogoEA_Uncompress
; a1 - destination buffer
; a3 - source buffer
; d2 - size
; *************************************************

LogoEA_Uncompress:
                movem.l d0-d7/a0-a6,-(sp)
                lea     (LogoEA_ram_UncompressTempBuffer).w,a2 ; buffer of size $1000 for decoded data
; fill temp buffer with $20
                movea.l a2,a0
                move.l  #$20202020,d3
                move.w  #$3FF,d0
@loopFillBuffer:
                move.l  d3,(a0)
                addq.l  #4,a0
                dbf     d0,@loopFillBuffer

                move.w  #$FEE,d7 ; temp buffer starting index
                move.w  #0,d3 ; bytes in block counter
                moveq   #0,d6 ; read block bitmask

@nextByte:
                dbf     d3,@readByte ; jump if d3 != 0
; start next block
                move.b  (a3)+,d0
                move.b  d0,d6
                move.w  #7,d3
@readByte:
                move.b  (a3)+,d0
                lsr.b   #1,d6 ; get bit from mask
                bcc.w   @maskBitZero ; branch if lower bit is not set
; mask bit 1
                move.b  d0,(a1)+ ; write byte to destination buffer without change
                subq.l  #1,d2 ; decrement size left
                beq   @end

                move.b  d0,(a2,d7.w) ; save byte to temp buffer
                addq.w  #1,d7
                andi.w  #$FFF,d7

                bra.s   @nextByte
@maskBitZero:
                moveq   #0,d4
                move.b  d0,d4 ; move byte to d4
                move.b  (a3)+,d0
                move.b  d0,d5 ; read second byte to d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5

@copyChunk:
                move.b  (a2,d4.w),d0 ; read byte from temp buffer
                addq.w  #1,d4
                andi.w  #$FFF,d4

                move.b  d0,(a1)+ ; write this byte to destination buffer
                subq.l  #1,d2
                beq   @end

                move.b  d0,(a2,d7.w) ; and append this byte to temp buffer
                addq.w  #1,d7
                andi.w  #$FFF,d7

                dbf     d5,@copyChunk

                bra.s   @nextByte

@end:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function LogoEA_Uncompress

LogoEA_dFigureStripThickness:
    dc.b    1,1,2,2,3,3,4,4,6

logoEA_dCircleProfile:
    dc.b    6,4,3,2,2,2,1,2,1,1,1,1,1,0,1,1,0,1,0,1,0,0,0,1,0,0,0

LogoEA_dTriangleShadowWidth:
    dc.b    0,0,0,2,7,10,10,7,0

logoEA_dCircleShadowLength:
    dc.b    4,8,11,14,21,28,37,30,0

LogoEA_Image_ElectronicArts:        
    incbin "LogoEA_Image_ElectronicArts.bin"
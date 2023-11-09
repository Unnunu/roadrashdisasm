; *************************************************
; Function UpdateAnimation
; d0 - animation frame index
; d1 - X
; d2 - Y
; a0 - destination sprite attribute table
; a1 - destination tile buffer (we copy only tiles needed for current frame, we don't need all tiles used in animation)
; a4 - animation script
; *************************************************

UpdateAnimation:
                move.w  d1,Animation_ram_PosX
                move.w  d2,Animation_ram_PosY
                move.w  Animation_ram_SpriteIndex,d7
                move.w  d7,d1
                asl.w   #3,d1
                adda.w  d1,a0 ; get sprite table offset
                move.w  Animation_ram_TileIndex,d5
                move.w  d5,d6
                add.w   Animation_ram_BaseTile,d6 ; get current tile index
                move.w  d5,d1
                asl.l   #5,d1
                adda.w  d1,a1 ; calculate destination address, offset = Animation_ram_TileIndex
                cmp.w   4(a4),d0 ; get total frame count 
                bls.w   @drawFrame
                bra.w   @return
@drawFrame:
                asl.w   #2,d0
                movea.l 6(a4,d0.w),a2 ; get memory address of next frame
                movea.l (a4),a4 ; get source tilemap
                move.w  (a2)+,d0 ; get number of sprites
                tst.w   d7
                beq.w   @loopDrawSprite
                move.b  d7,-5(a0) ; set link for previous sprite
@loopDrawSprite:
                move.w  (a2)+,d1 ; vertical position
                add.w   Animation_ram_PosY,d1
                move.w  d1,(a0)+

                addq.w  #1,d7 ; increment link
                move.w  d7,d2

                move.w  (a2)+,d4 ; size, same format as in sprite table
                andi.w  #$F00,d4
                or.w    d4,d2
                move.w  d2,(a0)+ ; size and link

                lea     unk_169A0,a5
                lsr.w   #8,d4 ; get sprite size in tiles
                move.b  (a5,d4.w),d2 ; get number of tiles to copy - 1
                ext.w   d2

                move.w  (a2)+,d4 ; palette, flip state and tile index
                move.w  d4,d3 ; save original value
                andi.w  #$7800,d4 ; leave only palette and flip state
                ori.w   #$8000,d4 ; set high priority
                or.w    d6,d4 ; add current tile index
                move.w  d4,(a0)+

                move.w  (a2)+,d1 ; horizontal position
                add.w   Animation_ram_PosX,d1
                move.w  d1,(a0)+

                movea.l a4,a5 ; base address of tiles
                andi.w  #$7FF,d3 ; get tile number
                asl.w   #5,d3
                adda.w  d3,a5 ; find tile address
@loopCopyTile:
                move.l  (a5)+,(a1)+ ; copy tile : 32 bytes
                move.l  (a5)+,(a1)+
                move.l  (a5)+,(a1)+
                move.l  (a5)+,(a1)+
                move.l  (a5)+,(a1)+
                move.l  (a5)+,(a1)+
                move.l  (a5)+,(a1)+
                move.l  (a5)+,(a1)+
                addq.w  #1,d6 ; increment current tile index
                addq.w  #1,d5 ; increment offset in tile map
                dbf     d2,@loopCopyTile

                dbf     d0,@loopDrawSprite

                move.b  #0,-5(a0) ; set last link = 0
                move.w  d5,Animation_ram_TileIndex
                move.w  d7,Animation_ram_SpriteIndex
@return:
                rts
; End of function UpdateAnimation

; *************************************************
; Function UpdateAnimation2
; tiles must be already loaded to VRAM
; d0 - animation frame index
; d1 - X
; d2 - Y
; a0 - destination sprite table
; a1 - destination address of tiles, not used
; a4 - animation script
; *************************************************

UpdateAnimation2:
                move.w  d1,Animation_ram_PosX
                move.w  d2,Animation_ram_PosY
                move.w  Animation_ram_SpriteIndex,d7
                move.w  d7,d1
                asl.w   #3,d1
                adda.w  d1,a0 ; get source entry for current frame
                move.w  Animation_ram_BaseTile,d6 ; get base tile index
                cmp.w   4(a4),d0 ; get total frame count 
                bls.w   @drawFrame
                bra.w   @return ; all frames were shown
@drawFrame:
                asl.w   #2,d0
                movea.l 6(a4,d0.w),a2 ; get memory address of next frame
                move.w  (a2)+,d0 ; read number of sprites
                tst.w   d7
                beq.w   @loop
                move.b  d7,-5(a0) ; set link for previous sprite
@loop:
                move.w  (a2)+,d1
                add.w   Animation_ram_PosY,d1 ; vertical position
                move.w  d1,(a0)+
                addq.w  #1,d7 ; next link
                move.w  d7,d2

                move.w  (a2)+,d4 ; size, same format as in sprite table
                andi.w  #$F00,d4
                or.w    d4,d2
                move.w  d2,(a0)+ ; size and link

                move.w  (a2)+,d4 ; palette, flip state and tile index
                ori.w   #$8000,d4 ; set high priority
                add.w   d6,d4 ; add base tile index
                move.w  d4,(a0)+

                move.w  (a2)+,d1 ; horizontal position
                add.w   Animation_ram_PosX,d1
                move.w  d1,(a0)+
                dbf     d0,@loop
                
                move.b  #0,-5(a0) ; set last link = 0
                move.w  d7,Animation_ram_SpriteIndex
@return:
                rts
; End of function UpdateAnimation2


unk_169A0:
    dc.b   0,  1,  2,  3
    dc.b   1,  3,  5,  7
    dc.b   2,  5,  8, 11
    dc.b   3,  7, 11, 15
; *************************************************
; sub_5760.asm - rider/bike sprite chain builder
; ROM range: $5760-$59C3
; Status:    analyzed (static + demo dynamic)
; API:       sub_5760 (called by 8FB4.asm), sub_593E wrapper
; *************************************************

; *************************************************
; Function sub_5760
; Builds a linked chunk of rider/bike SAT entries and advances the animation cursors.
; In:  d0, d1 - strip/direction geometry from the caller (8FB4.asm)
; Out: SAT entries at Race_ram_CurrentSpriteAttributeTable;
;      Animation_ram_SpriteIndex / Animation_ram_TileIndex
; Clobbers: d0-d7, a0, a1
; Notes: unk_5944 supplies per-strip Y/link/tile/X offsets. A shadow/overlay layer is
;        emitted when ram_FF133A != 0. Chain ends at tile index $150 or index $50.
; *************************************************

sub_5760:
; mark first chunk (sentinel replaced by the computed tile offset below)
                move.w  #$8000,(ram_FFDE68).l
                movea.l (Race_ram_CurrentSpriteAttributeTable).l,a0
                move.w  (Animation_ram_SpriteIndex).l,d2
                asl.w   #3,d2
                adda.w  d2,a0
                move.w  (Animation_ram_SpriteIndex).l,d2
                beq.w   .loc_57A2
                cmp.w   #$50,d2 ; 'P'
                blt.w   .loc_579E
; $50 is the SAT capacity: abort when the chain is full
                move.w  #$FFFF,(ram_FF1366).l
                move.w  #$FFFF,(ram_FFDE62).l
                bra.w   .locret_593C
; ---------------------------------------------------------------------------

.loc_579E:
; link the new chunk into the previous entry (low byte of size/link)
                or.w    d2,-6(a0)

.loc_57A2:
; derive column/row counts (d2/d3) and strip bases from d0/d1
                move.w  d0,d2
                lsr.w   #5,d2
                andi.w  #$18,d0
                bne.w   .loc_57B4
                subq.w  #1,d2
                move.w  #$20,d0 ; ' '

.loc_57B4:
                subq.w  #8,d0
                move.w  d0,(ram_FF0906).l
                move.w  d1,d3
                lsr.w   #5,d3
                andi.w  #$18,d1
                bne.w   .loc_57CE
                subq.w  #1,d3
                move.w  #$20,d1 ; ' '

.loc_57CE:
                subq.w  #8,d1
                asl.w   #2,d1
                move.w  d1,(ram_FF0908).l
                move.w  d2,(ram_FF090A).l
                move.w  d3,(ram_FF090C).l
                move.w  #$7C,(ram_FFDE6A).l ; '|'
                move.w  (ram_FF0908).l,d4
                addi.w  #$20,d4 ; ' '
                subq.w  #4,d4
                move.w  d4,(ram_FFDE66).l
                cmp.w   #0,d3
                bne.w   .loc_580C
                move.w  d4,(ram_FFDE6A).l

.loc_580C:
; per-strip entry base: Y = base + $80, X = base + $80
                move.w  (ram_FFDE70).l,d4
                addi.w  #$80,d4
                move.w  (Animation_ram_SpriteIndex).l,d5
                addq.w  #1,d5
                move.w  (Animation_ram_TileIndex).l,d6

.loc_5824:
                move.w  d6,(ram_FF090E).l
                move.w  (ram_FFDE6E).l,d7
                addi.w  #$80,d7
                tst.w   (ram_FF133A).l
                beq.w   .loc_584A
                add.w   (ram_FF1336).l,d7
                add.w   (ram_FF1336).l,d7

.loc_584A:
                move.w  #$60,d0 ; '`'
                cmp.w   #0,d3
                bne.w   .loc_585C
                move.w  (ram_FF0908).l,d0

.loc_585C:
; select the unk_5944 strip record from the direction/column bases
                movea.w #$18,a1
                cmp.w   #0,d2
                bne.w   .loc_586E
                movea.w (ram_FF0906).l,a1

.loc_586E:
                adda.w  d0,a1
; word[table+2] = size/link bits for this strip
                or.w    $5946(a1),d5
                move.w  d4,(a0)+
                move.w  d5,(a0)+
                move.w  d6,-(sp)
                cmp.w   #$118,d4
                bpl.w   .loc_5886
                ori.w   #$8000,d6

.loc_5886:
                or.w    (ram_FFDE5E).l,d6
                add.w   (Animation_ram_BaseTile).l,d6
                tst.w   (ram_FF133A).l
                beq.w   .loc_58A4
                ori.w   #$800,d6
                sub.w   $594A(a1),d7

.loc_58A4:
                move.w  d6,(a0)+
                move.w  (sp)+,d6
                move.w  d7,(a0)+
                andi.w  #$FF,d5
                addq.w  #1,d5
                add.w   $5948(a1),d6
                cmp.w   #$150,d6
                bmi.w   .loc_58EA
; tile cursor reached the end of the frame: flag the chain end
                movea.l (Race_ram_CurrentSpriteAttributeTable).l,a0
                move.w  #$FFFF,(ram_FF1366).l
                move.w  #$FFFF,(ram_FFDE62).l
                move.w  (Animation_ram_SpriteIndex).l,d2
                beq.w   .locret_593C
                asl.w   #3,d2
                adda.w  d2,a0
                andi.w  #$FF00,-6(a0)
                bra.w   .locret_593C
; ---------------------------------------------------------------------------

.loc_58EA:
                tst.w   (ram_FF133A).l
                bne.w   .loc_58F8
                add.w   $594A(a1),d7

.loc_58F8:
                dbf     d2,.loc_585C
                add.w   unk_5944(a1),d4
                move.w  (ram_FF090A).l,d2
                cmpi.w  #$8000,(ram_FFDE68).l
                bne.w   .loc_5924
                move.w  d6,d0
                sub.w   (ram_FF090E).l,d0
                subq.w  #4,d0
                asl.w   #5,d0
                move.w  d0,(ram_FFDE68).l

.loc_5924:
                dbf     d3,.loc_5824
; clear the last link and store the animation cursors
                andi.w  #$FF00,-6(a0)
                subq.w  #1,d5
                move.w  d5,(Animation_ram_SpriteIndex).l
                move.w  d6,(Animation_ram_TileIndex).l

.locret_593C:
                rts
; End of function sub_5760

; *************************************************
; Function sub_593E
; Alternate entry point: builds a sprite chunk via sub_5760.
; In/Out/Clobbers: same as sub_5760.
; *************************************************

sub_593E:
                bsr.w   sub_5760
                rts
; End of function sub_593E

; *************************************************
; unk_5944 - per-strip SAT layout table (16 records x 8 bytes)
; +0: Y advance, +2: size/link bits, +4: tile step, +6: shadow X adjust.
; *************************************************

unk_5944:
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   8
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b   8
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b   8
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $10
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $10
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $10
                dc.b   9
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b $10
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $18
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $18
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $18
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b $18
                dc.b  $E
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $20
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $20
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $20
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b $20
                dc.b  $F
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $20
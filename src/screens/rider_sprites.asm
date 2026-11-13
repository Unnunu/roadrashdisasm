; *************************************************
; rider_sprites.asm - rider/bike sprite chain builder
; ROM range: $5760-$59C3
; Status:    analyzed (static + demo dynamic)
; API:       RiderSprites_Build (called by Road_DrawStrip in road_render.asm)
;            RiderSprites_BuildAlt (unused wrapper entry)
; *************************************************

; *************************************************
; Overview: how the rider/bike sprite chain is built
;
; The rider/bike bitmap is emitted as a rectangular grid of VDP sprites. The
; caller packs the required tile extent into d0 (horizontal) and d1 (vertical)
; as (tiles * 8). The low bits are the "remainder" block size; d>>5 is the number
; of full 4-tile blocks that precede it. The grid is therefore:
;
;   horizontal: d2 full 4-wide blocks + one (C+1)-wide remainder block
;   vertical:   d3 full 4-high blocks + one (R+1)-high remainder block
;
; where C = d0 remainder code (0..3) and R = d1 remainder code (0..3). Each grid
; cell is one SAT entry; RiderSprites_StripTable[4*R+C] supplies its geometry
; (Y step, size code, tile step, X step). Interior cells use the full 4x4 code 3
; and only the last row/column use the smaller remainder codes.
;
; SAT entry layout (4 words): Y, size/link, tile/priority, X.
;   size/link = (size_code << 8) | link_index
;   tile      = priority | SpriteStrip_ram_FillWord | Animation_ram_BaseTile | tile_index
; priority ($8000) is set for sprites above Y=$118. When Road_ram_MirrorFlag is set the
; pass is horizontally mirrored: tiles get the H-flip bit $800 and X is stepped
; left instead of right. Entries are chained through the low byte of the
; size/link word, starting at Animation_ram_SpriteIndex.
;
; Limits: $50 (80) is the SAT slot count; $150 is the end of the rider graphics
; tile range and terminates the chain early.
; *************************************************

; *************************************************
; Function RiderSprites_Build
; Builds a linked chunk of rider/bike SAT entries and advances the animation cursors.
; In:  d0 - horizontal tile extent (tiles*8); d1 - vertical tile extent (tiles*8)
; Out: SAT entries at Race_ram_CurrentSpriteAttributeTable;
;      Animation_ram_SpriteIndex / Animation_ram_TileIndex
; Clobbers: d0-d7, a0, a1
; Notes: See the overview above. A mirrored pass is emitted when Road_ram_MirrorFlag != 0.
;        The chain ends at tile index $150 or when the SAT index reaches $50.
; *************************************************

RiderSprites_Build:
; sentinel = "row stride not computed yet" (see the end of the first row)
                move.w  #$8000,(SpriteStrip_ram_BandAdvance).l
; a0 = SAT + SpriteIndex*8, the next free SAT slot
                movea.l (Race_ram_CurrentSpriteAttributeTable).l,a0
                move.w  (Animation_ram_SpriteIndex).l,d2
                asl.w   #3,d2
                adda.w  d2,a0
; index 0 means this is the first sprite of the frame: nothing to link to
                move.w  (Animation_ram_SpriteIndex).l,d2
                beq.w   .loc_57A2
; $50 is the SAT capacity; abort when the next free slot is out of range
                cmp.w   #$50,d2
                blt.w   .loc_579E
                move.w  #$FFFF,(ram_FF1366).l
                move.w  #$FFFF,(ram_FFDE62).l
                bra.w   .locret_593C
; ---------------------------------------------------------------------------

.loc_579E:
; point the previous entry's link byte at the new chunk
                or.w    d2,-6(a0)

.loc_57A2:
; split d0 into horizontal block count (d2 = d0>>5) and a 2-bit remainder code.
; A zero remainder means the last block is full (4 tiles): use code 3 and one
; fewer full block.
                move.w  d0,d2
                lsr.w   #5,d2
                andi.w  #$18,d0
                bne.w   .loc_57B4
                subq.w  #1,d2
                move.w  #$20,d0

.loc_57B4:
                subq.w  #8,d0           ; remainder code 0..3 -> C byte offset (code*8)
                move.w  d0,(ram_FF0906).l
; the same split for d1 gives the vertical block count (d3) and R remainder code
                move.w  d1,d3
                lsr.w   #5,d3
                andi.w  #$18,d1
                bne.w   .loc_57CE
                subq.w  #1,d3
                move.w  #$20,d1

.loc_57CE:
                subq.w  #8,d1           ; remainder code 0..3
                asl.w   #2,d1           ; -> R byte offset (code*$20)
                move.w  d1,(ram_FF0908).l
                move.w  d2,(ram_FF090A).l   ; horizontal block count
                move.w  d3,(ram_FF090C).l   ; vertical block count
; column/row strides for the road tile-array writer (Road_WriteTileColumns).
; $7C is the default within-row stride; a single-row sprite uses the shorter one.
                move.w  #$7C,(SpriteStrip_ram_ColumnGap).l
                move.w  (ram_FF0908).l,d4
                addi.w  #$20,d4
                subq.w  #4,d4
                move.w  d4,(SpriteStrip_ram_TailColumnGap).l
                cmp.w   #0,d3
                bne.w   .loc_580C
                move.w  d4,(SpriteStrip_ram_ColumnGap).l

.loc_580C:
; Y base (the SAT consumer subtracts $80 to get screen coordinates)
                move.w  (ram_FFDE70).l,d4
                addi.w  #$80,d4
; the first entry links to the next slot; the first tile is the tile cursor
                move.w  (Animation_ram_SpriteIndex).l,d5
                addq.w  #1,d5
                move.w  (Animation_ram_TileIndex).l,d6

.loc_5824:                              ; outer loop: one row of blocks
                move.w  d6,(ram_FF090E).l   ; tile cursor at the start of the row
                move.w  (ram_FFDE6E).l,d7
                addi.w  #$80,d7             ; X base
; U-0007: RoadObject_Flags bit15 is a horizontal-mirror/facing flag. It is the
;  same bit tested by Road_ScaleShape/Road_ProjectShape*, so the mirrored pass
;  draws the left-facing variant; it is not a separate shadow/reflection layer.
                tst.w   (Road_ram_MirrorFlag).l
                beq.w   .loc_584A
                add.w   (ram_FF1336).l,d7   ; mirrored pass: shift start by 2*FF1336
                add.w   (ram_FF1336).l,d7

.loc_584A:
; the last row uses the remainder height (ram_FF0908); other rows use the full
; 4-tile block, i.e. R=3 -> table offset $60
                move.w  #$60,d0
                cmp.w   #0,d3
                bne.w   .loc_585C
                move.w  (ram_FF0908).l,d0

.loc_585C:                              ; inner loop: one sprite block per column
; the last column uses the remainder width (ram_FF0906); other columns use the
; full 4-tile block, i.e. C=3 -> table offset $18
                movea.w #$18,a1
                cmp.w   #0,d2
                bne.w   .loc_586E
                movea.w (ram_FF0906).l,a1

.loc_586E:
                adda.w  d0,a1               ; a1 = C*8 + R*$20 = record byte offset
; word1 = size code (high byte) | link index (low byte)
                or.w    $5946(a1),d5
                move.w  d4,(a0)+            ; Y
                move.w  d5,(a0)+            ; size/link
; save the tile cursor, then build this entry's tile/priority word
                move.w  d6,-(sp)
                cmp.w   #$118,d4
                bpl.w   .loc_5886
                ori.w   #$8000,d6           ; sprites above Y=$118 draw in front
.loc_5886:
                or.w    (SpriteStrip_ram_FillWord).l,d6   ; object palette/priority/base bits
                add.w   (Animation_ram_BaseTile).l,d6
                tst.w   (Road_ram_MirrorFlag).l
                beq.w   .loc_58A4
                ori.w   #$800,d6            ; mirrored pass: horizontal flip
                sub.w   $594A(a1),d7        ; and step X left by the sprite width

.loc_58A4:
                move.w  d6,(a0)+            ; tile/priority
                move.w  (sp)+,d6            ; restore tile cursor
                move.w  d7,(a0)+            ; X
                andi.w  #$FF,d5
                addq.w  #1,d5               ; next link index
                add.w   $5948(a1),d6        ; advance by the block's tile count
                cmp.w   #$150,d6
                bmi.w   .loc_58EA
; tile budget exhausted ($150 = end of the rider graphics): end the chain here
                movea.l (Race_ram_CurrentSpriteAttributeTable).l,a0
                move.w  #$FFFF,(ram_FF1366).l
                move.w  #$FFFF,(ram_FFDE62).l
                move.w  (Animation_ram_SpriteIndex).l,d2
                beq.w   .locret_593C        ; no previous entry to unlink
                asl.w   #3,d2
                adda.w  d2,a0
                andi.w  #$FF00,-6(a0)       ; clear the previous entry's link byte
                bra.w   .locret_593C
; ---------------------------------------------------------------------------

.loc_58EA:
                tst.w   (Road_ram_MirrorFlag).l
                bne.w   .loc_58F8
                add.w   $594A(a1),d7        ; normal pass: step X right by the width
.loc_58F8:
                dbf     d2,.loc_585C
; row done: advance Y by the block height and reload the column count
                add.w   RiderSprites_StripTable(a1),d4
                move.w  (ram_FF090A).l,d2
; derive the road tile-array row stride once, from the first row's tile span.
; (tiles -> bytes: 32 bytes per tile)
                cmpi.w  #$8000,(SpriteStrip_ram_BandAdvance).l
                bne.w   .loc_5924
                move.w  d6,d0
                sub.w   (ram_FF090E).l,d0
                subq.w  #4,d0
                asl.w   #5,d0
                move.w  d0,(SpriteStrip_ram_BandAdvance).l

.loc_5924:
                dbf     d3,.loc_5824
; chain complete: terminate the last link and publish the animation cursors
                andi.w  #$FF00,-6(a0)
                subq.w  #1,d5
                move.w  d5,(Animation_ram_SpriteIndex).l
                move.w  d6,(Animation_ram_TileIndex).l

.locret_593C:
                rts
; End of function RiderSprites_Build

; *************************************************
; Function RiderSprites_BuildAlt
; Alternate entry point: builds a sprite chunk via RiderSprites_Build.
; In/Out/Clobbers: same as RiderSprites_Build.
; *************************************************

RiderSprites_BuildAlt:
                bsr.w   RiderSprites_Build
                rts
; End of function RiderSprites_BuildAlt

; *************************************************
; RiderSprites_StripTable - per-block SAT layout table (16 records x 8 bytes)
;
; Indexed by (row remainder R, column remainder C):
;   record = RiderSprites_StripTable + (4*R + C)*8
; where C is the horizontal block code and R the vertical block code from d0/d1.
; Interior blocks use C=3/R=3 (full 4x4); only the last row/column use C/R < 3.
;
; Fields (big-endian words):
;   +0  Y step    = 8*(R+1)            sprite height in pixels
;   +2  size/link = ((4*C + R) << 8)   VDP size field; low byte is the link
;   +4  tile step = (R+1)*(C+1)        tiles consumed by one sprite
;   +6  X step    = 8*(C+1)            sprite width in pixels (subtracted when
;                                      Road_ram_MirrorFlag mirroring is active)
;
; A record therefore describes a (C+1) x (R+1) tile sprite; the size nibble is
; consistent with Animation_dTileCountMinus1 (tile count = (R+1)*(C+1)).
; *************************************************

RiderSprites_StripTable:
;          Ystep   size/link   tstep  Xstep    sprite WxH
        dc.w $0008, $0000,     $0001, $0008  ; R0 C0: 1x1
        dc.w $0008, $0400,     $0002, $0010  ; R0 C1: 2x1
        dc.w $0008, $0800,     $0003, $0018  ; R0 C2: 3x1
        dc.w $0008, $0C00,     $0004, $0020  ; R0 C3: 4x1
        dc.w $0010, $0100,     $0002, $0008  ; R1 C0: 1x2
        dc.w $0010, $0500,     $0004, $0010  ; R1 C1: 2x2
        dc.w $0010, $0900,     $0006, $0018  ; R1 C2: 3x2
        dc.w $0010, $0D00,     $0008, $0020  ; R1 C3: 4x2
        dc.w $0018, $0200,     $0003, $0008  ; R2 C0: 1x3
        dc.w $0018, $0600,     $0006, $0010  ; R2 C1: 2x3
        dc.w $0018, $0A00,     $0009, $0018  ; R2 C2: 3x3
        dc.w $0018, $0E00,     $000C, $0020  ; R2 C3: 4x3
        dc.w $0020, $0300,     $0004, $0008  ; R3 C0: 1x4
        dc.w $0020, $0700,     $0008, $0010  ; R3 C1: 2x4
        dc.w $0020, $0B00,     $000C, $0018  ; R3 C2: 3x4
        dc.w $0020, $0F00,     $0010, $0020  ; R3 C3: 4x4

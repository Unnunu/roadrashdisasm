; *************************************************
; uncompress.asm - LZSS decompressors (byte/word/streaming/VRAM)
; ROM range: $9B9E-$9FE3
; Status:    analyzed (algorithm validated with a Python decoder)
; API:       UncompressB, UncompressW, sub_9CC6, sub_9DC2, UncompressToVRAM
; *************************************************

; *************************************************
; Function UncompressB
; Byte-format LZSS: 32-bit output size, 0x1000 ring at Road_ram_XLeftArray, ring
; pointer $FEE; flags LSB-first, 1 = literal, 0 = 12-bit distance + length nibble+3.
; In:  a3 - compressed data (32-bit size first), a1 - output
; Out: decompressed bytes at a1
; Clobbers: all (saved/restored)
; *************************************************

UncompressB:
                movem.l d0-d7/a0-a6,-(sp)
                move.l  (a3)+,d2
                lea     (Road_ram_XLeftArray).l,a2
                movea.l a2,a0
; ring buffer prefilled with spaces; the window starts at $FEE
                move.l  #$20202020,d3
                move.w  #$3FF,d0
.loc_9BB6:
                move.l  d3,(a0)+
                dbf     d0,.loc_9BB6
                move.w  #$FEE,d7
                moveq   #0,d3
                moveq   #0,d6
.loc_9BC4:
                dbf     d3,.loc_9BCC
                move.b  (a3)+,d6
                moveq   #7,d3
.loc_9BCC:
                lsr.b   #1,d6
                bcc.w   .loc_9BE8
                move.b  (a3)+,d0
                move.b  d0,(a1)+
                subq.l  #1,d2
                beq.w   .loc_9C20
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   .loc_9BC4
.loc_9BE8:
                moveq   #0,d4
                move.b  (a3)+,d4
                move.b  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
.loc_9BFE:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a1)+
                subq.l  #1,d2
                beq.w   .loc_9C20
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,.loc_9BFE
                bra.s   .loc_9BC4
.loc_9C20:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function UncompressB


; *************************************************
; Function UncompressW
; Word-format LZSS: the 8-byte header stores the size in its odd bytes; the stream
; stores every flag/literal/match byte in the low byte of a 16-bit word (high byte
; skipped). Same ring/match rules as UncompressB.
; In:  a3 - compressed data (8-byte size header), a1 - output
; Out: decompressed bytes at a1
; Clobbers: all (saved/restored)
; *************************************************

UncompressW:
                movem.l d0-d7/a0-a6,-(sp)
; size = bytes 1,3,5,7 of the 8-byte interleaved header
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
; size = bytes 1,3,5,7 of the 8-byte interleaved header
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
; size = bytes 1,3,5,7 of the 8-byte interleaved header
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
                addq.w  #1,a3
                move.b  (a3)+,d2
                lea     (Road_ram_XLeftArray).l,a2
                movea.l a2,a0
                move.l  #$20202020,d3
                move.w  #$3FF,d0
.loc_9C52:
                move.l  d3,(a0)+
                dbf     d0,.loc_9C52
                move.w  #$FEE,d7
                moveq   #0,d3
                moveq   #0,d6
.loc_9C60:
                dbf     d3,.loc_9C68
                move.w  (a3)+,d6
                moveq   #7,d3
.loc_9C68:
                lsr.b   #1,d6
                bcc.w   .loc_9C84
                move.w  (a3)+,d0
                move.b  d0,(a1)+
                subq.l  #1,d2
                beq.w   .loc_9CC0
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   .loc_9C60
.loc_9C84:
                moveq   #0,d4
                move.w  (a3)+,d4
                andi.w  #$FF,d4
                move.w  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
.loc_9C9E:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a1)+
                subq.l  #1,d2
                beq.w   .loc_9CC0
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,.loc_9C9E
                bra.s   .loc_9C60
.loc_9CC0:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function UncompressW


; *************************************************
; Function sub_9CC6
; Starts an interruptible byte-format LZSS decode: total size from the source,
; per-call output budget in d1, state saved at ram_FF136C..13A8.
; In:  a3 - source; a1 - output; d1 - max bytes this call
; Out: decoded bytes; state block; rings persist
; Clobbers: all (saved/restored)
; *************************************************

sub_9CC6:
                movem.l d0-d7/a0-a6,-(sp)
                move.l  (a3)+,d2
                lea     (Road_ram_XLeftArray).l,a2
                movea.l a2,a0
                move.l  #$20202020,d3
                move.w  #$3FF,d0
.loc_9CDE:
                move.l  d3,(a0)+
                dbf     d0,.loc_9CDE
                move.w  #$FEE,d7
                moveq   #0,d3
                moveq   #0,d6
.loc_9CEC:
                dbf     d3,.loc_9CF4
                move.b  (a3)+,d6
                moveq   #7,d3
.loc_9CF4:
                lsr.b   #1,d6
                bcc.w   .loc_9D1C
                move.b  (a3)+,d0
                move.b  d0,(a1)+
                clr.w   (ram_FF13A8).l
                subq.l  #1,d2
                beq.w   .loc_9D62
                subq.l  #1,d1
                beq.w   .loc_9D62
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   .loc_9CEC
.loc_9D1C:
                moveq   #0,d4
                move.b  (a3)+,d4
                move.b  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
.loc_9D32:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a1)+
                move.w  #$FFFF,(ram_FF13A8).l
                subq.l  #1,d2
                beq.w   .loc_9D62
                subq.l  #1,d1
                beq.w   .loc_9D62
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,.loc_9D32
                bra.s   .loc_9CEC
.loc_9D62:
; save the full decoder state for the next chunk
                move.l  a0,(ram_FF136C).l
                move.l  a1,(ram_FF1370).l
                move.l  a2,(ram_FF1374).l
                move.l  a3,(ram_FF1378).l
                move.l  a4,(ram_FF137C).l
                move.l  a5,(ram_FF1380).l
                move.l  a6,(ram_FF1384).l
                move.l  d0,(ram_FF1388).l
                move.l  d1,(ram_FF138C).l
                move.l  d2,(ram_FF1390).l
                move.l  d3,(ram_FF1394).l
                move.l  d4,(ram_FF1398).l
                move.l  d5,(ram_FF139C).l
                move.l  d6,(ram_FF13A0).l
                move.l  d7,(ram_FF13A4).l
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_9CC6


; *************************************************
; Function sub_9DC2
; Resumes the interruptible byte decode. Restores the ring/source/decoder state, but
; a1 (output) and d1 (new budget) are supplied by the caller.
; In:  a1 - output; d1 - budget; ram_FF136C..13A8 state
; Out: decoded bytes; updated state
; Clobbers: all (saved/restored)
; *************************************************

sub_9DC2:
                movem.l d0-d7/a0-a6,-(sp)
                movea.l (ram_FF136C).l,a0
                movea.l (ram_FF1374).l,a2
                movea.l (ram_FF1378).l,a3
                movea.l (ram_FF137C).l,a4
                movea.l (ram_FF1380).l,a5
                movea.l (ram_FF1384).l,a6
                move.l  (ram_FF1388).l,d0
                move.l  (ram_FF1390).l,d2
                move.l  (ram_FF1394).l,d3
                move.l  (ram_FF1398).l,d4
                move.l  (ram_FF139C).l,d5
                move.l  (ram_FF13A0).l,d6
                move.l  (ram_FF13A4).l,d7
; resume inside a back-reference if the previous chunk stopped mid-match
                tst.w   (ram_FF13A8).l
                beq.w   .loc_9E46
                bra.w   .loc_9E88
.loc_9E22:
                dbf     d3,.loc_9E2A
                move.b  (a3)+,d6
                moveq   #7,d3
.loc_9E2A:
                lsr.b   #1,d6
                bcc.w   .loc_9E52
                move.b  (a3)+,d0
                move.b  d0,(a1)+
                clr.w   (ram_FF13A8).l
                subq.l  #1,d2
                beq.w   .loc_9E98
                subq.l  #1,d1
                beq.w   .loc_9E98
.loc_9E46:
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   .loc_9E22
.loc_9E52:
                moveq   #0,d4
                move.b  (a3)+,d4
                move.b  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
.loc_9E68:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a1)+
                move.w  #$FFFF,(ram_FF13A8).l
                subq.l  #1,d2
                beq.w   .loc_9E98
                subq.l  #1,d1
                beq.w   .loc_9E98
.loc_9E88:
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,.loc_9E68
                bra.s   .loc_9E22
.loc_9E98:
                move.l  a0,(ram_FF136C).l
                move.l  a1,(ram_FF1370).l
                move.l  a2,(ram_FF1374).l
                move.l  a3,(ram_FF1378).l
                move.l  a4,(ram_FF137C).l
                move.l  a5,(ram_FF1380).l
                move.l  a6,(ram_FF1384).l
                move.l  d0,(ram_FF1388).l
                move.l  d1,(ram_FF138C).l
                move.l  d2,(ram_FF1390).l
                move.l  d3,(ram_FF1394).l
                move.l  d4,(ram_FF1398).l
                move.l  d5,(ram_FF139C).l
                move.l  d6,(ram_FF13A0).l
                move.l  d7,(ram_FF13A4).l
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_9DC2


; *************************************************
; Function UncompressToVRAM
; Word-format LZSS straight to the VDP: a1 = VRAM tile address; the output is
; assembled 4 bytes at a time in ram_FF13AA and written to VdpData.
; In:  a3 - compressed data (word format), a1 - VRAM destination
; Out: VRAM
; Clobbers: all (saved/restored)
; *************************************************

UncompressToVRAM:
                movem.l d0-d7/a0-a6,-(sp)
                move.w  a1,d0
                andi.l  #$FFFF,d0
                asl.l   #2,d0
                lsr.w   #2,d0
                ori.w   #$4000,d0
                swap    d0
                move.l  d0,(VdpCtrl).l
                lea     (VdpData).l,a1
; 4-byte VRAM assembly buffer
                lea     (ram_FF13AA).l,a4
                move.w  #0,d1
; size = bytes 1,3,5,7 of the 8-byte interleaved header
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
; size = bytes 1,3,5,7 of the 8-byte interleaved header
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
; size = bytes 1,3,5,7 of the 8-byte interleaved header
                addq.w  #1,a3
                move.b  (a3)+,d2
                asl.l   #8,d2
                addq.w  #1,a3
                move.b  (a3)+,d2
                lea     (Road_ram_XLeftArray).l,a2
                movea.l a2,a0
                move.l  #$20202020,d3
                move.w  #$3FF,d0
.loc_9F4C:
                move.l  d3,(a0)+
                dbf     d0,.loc_9F4C
                move.w  #$FEE,d7
                moveq   #0,d3
                moveq   #0,d6
.loc_9F5A:
                dbf     d3,.loc_9F62
                move.w  (a3)+,d6
                moveq   #7,d3
.loc_9F62:
                lsr.b   #1,d6
                bcc.w   .loc_9F8C
                move.w  (a3)+,d0
                move.b  d0,(a4,d1.w)
                addq.w  #1,d1
                andi.w  #3,d1
                bne.w   .loc_9F7A
                move.l  (a4),(a1)
.loc_9F7A:
                subq.l  #1,d2
                beq.w   .loc_9FD6
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                bra.s   .loc_9F5A
.loc_9F8C:
                moveq   #0,d4
                move.w  (a3)+,d4
                andi.w  #$FF,d4
                move.w  (a3)+,d0
                move.b  d0,d5
                andi.w  #$F0,d0
                asl.w   #4,d0
                or.w    d0,d4
                andi.w  #$F,d5
                addq.w  #2,d5
.loc_9FA6:
                move.b  (a2,d4.w),d0
                addq.w  #1,d4
                andi.w  #$FFF,d4
                move.b  d0,(a4,d1.w)
                addq.w  #1,d1
                andi.w  #3,d1
                bne.w   .loc_9FC0
                move.l  (a4),(a1)
.loc_9FC0:
                subq.l  #1,d2
                beq.w   .loc_9FD6
                move.b  d0,(a2,d7.w)
                addq.w  #1,d7
                andi.w  #$FFF,d7
                dbf     d5,.loc_9FA6
                bra.s   .loc_9F5A
.loc_9FD6:
                tst.w   d1
                beq.w   .loc_9FDE
                move.l  (a4),(a1)
.loc_9FDE:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function UncompressToVRAM
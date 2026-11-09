; *************************************************
; track_data.asm - track/road data decompressor (two-channel delta/bit-packed)
; ROM range: $9FE4-$A4E1
; Status:    analyzed (stream start captured dynamically; channel semantics TODO)
; API:       sub_9FE4 (start), sub_A04A (per-call chunk), sub_A0D4/A2DA (channels)
; *************************************************

; *************************************************
; Function sub_9FE4
; Initializes two track data streams and the interleaved output, then decodes the
; first d1 samples per channel.
; In:  a2/a3 - two stream pointers (16-bit control length, controls, bit data)
;      a1 - output (2-byte stride); d1 - samples per channel
; Out: ram_FF13xx/14xx state; decoded bytes at a1
; Clobbers: all (saved/restored)
; *************************************************

sub_9FE4:
                movem.l d0-d7/a0-a6,-(sp)
                clr.w   (ram_FF13E2).l
                move.w  d1,(ram_FF13B2).l
                clr.l   d2
                move.w  (a2)+,d2
                move.w  d2,(ram_FF13DC).l
                move.l  a2,(ram_FF13DE).l
                adda.l  d2,a2
                move.l  a2,(ram_FF13D4).l
                move.l  a1,(ram_FF13D8).l
                clr.w   (ram_FF140E).l
                clr.l   d2
                move.w  (a3)+,d2
                move.w  d2,(ram_FF1408).l
                move.l  a3,(ram_FF140A).l
                adda.l  d2,a3
                move.l  a3,(ram_FF1400).l
                addq.l  #1,a1
                move.l  a1,(ram_FF1404).l
                andi.l  #$FFFF,d1
                movem.l (sp)+,d0-d7/a0-a6
                jsr     (sub_A04A).l
                rts
; End of function sub_9FE4


; *************************************************
; Function sub_A04A
; Decodes the next per-call chunk on both channels (resumable state).
; In:  d1 - samples per channel this call; ram_FF13xx/14xx state
; Out: decoded bytes; updated state
; Clobbers: all (saved/restored)
; *************************************************

sub_A04A:
                bsr.w   sub_A0D4
                bsr.w   sub_A2DA
                rts
; End of function sub_A04A


; bit masks for the current data byte (8 widths x 8 bit positions)
unk_A054:       dc.b $80
                dc.b $40
                dc.b $20
                dc.b $10
                dc.b   8
                dc.b   4
                dc.b   2
                dc.b   1
                dc.b $C0
                dc.b $60
                dc.b $30
                dc.b $18
                dc.b  $C
                dc.b   6
                dc.b   3
                dc.b   1
                dc.b $E0
                dc.b $70
                dc.b $38
                dc.b $1C
                dc.b  $E
                dc.b   7
                dc.b   3
                dc.b   1
                dc.b $F0
                dc.b $78
                dc.b $3C
                dc.b $1E
                dc.b  $F
                dc.b   7
                dc.b   3
                dc.b   1
                dc.b $F8
                dc.b $7C
                dc.b $3E
                dc.b $1F
                dc.b  $F
                dc.b   7
                dc.b   3
                dc.b   1
                dc.b $FC
                dc.b $7E
                dc.b $3F
                dc.b $1F
                dc.b  $F
                dc.b   7
                dc.b   3
                dc.b   1
                dc.b $FE
                dc.b $7F
                dc.b $3F
                dc.b $1F
                dc.b  $F
                dc.b   7
                dc.b   3
                dc.b   1

; cross-byte masks (high bits of the next data byte)
unk_A08C:       dc.b $80
                dc.b $C0
                dc.b $E0
                dc.b $F0
                dc.b $F8
                dc.b $FC
                dc.b $FE
                dc.b   0
; right-shift counts; $FF entries request the cross-byte path
unk_A094:       dc.b   7
                dc.b   6
                dc.b   5
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b   6
                dc.b   5
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b   5
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b $FD
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b $FD
                dc.b $FC
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b $FD
                dc.b $FC
                dc.b $FB
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $FE
                dc.b $FD
                dc.b $FC
                dc.b $FB
                dc.b $FA
; boundary shift counts 7..0
unk_A0CC:       dc.b   7
                dc.b   6
                dc.b   5
                dc.b   4
                dc.b   3
                dc.b   2
                dc.b   1
                dc.b   0

; *************************************************
; Function sub_A0D4
; Channel 1 decoder: control byte = run-1 (high nibble), sign (bit3), width-1
; (low 3 bits); per sample read a delta from the bit stream, update the accumulator
; and write a byte at a1, a1+2, ...
; In:  state at ram_FF13xx; budget ram_FF13B2
; Out: output at ram_FF13D8; state
; Clobbers: all (saved/restored)
; *************************************************

sub_A0D4:
                movem.l d0-d7/a0-a6,-(sp)
; first call: clear the channel state; later calls resume
                tst.w   (ram_FF13E2).l
                bne.w   .loc_A106
                clr.w   (ram_FF13BC).l
                clr.b   (ram_FF13B8).l
                clr.w   (ram_FF13CE).l
                clr.w   (ram_FF13D0).l
                clr.w   (ram_FF13D2).l
                clr.w   (ram_FF13C8).l
.loc_A106:
                movea.l (ram_FF13D4).l,a0
                movea.l (ram_FF13DE).l,a2
                move.w  d1,(ram_FF13B2).l
                tst.w   (ram_FF13E2).l
                bne.w   .loc_A29C
                move.b  (a0)+,(ram_FF13B9).l
.loc_A128:
                move.w  (ram_FF13BC).l,d0
                cmp.w   (ram_FF13DC).l,d0
                bgt.w   .loc_A2B6
                move.w  (ram_FF13BC).l,d7
                move.b  (a2,d7.w),(ram_FF13C6).l
                andi.b  #7,(ram_FF13C6).l
                clr.l   d0
                move.b  (a2,d7.w),d0
                andi.w  #$F0,d0
                lsr.w   #4,d0
                addq.w  #1,d0
                move.w  d0,(ram_FF13C4).l
                move.b  (a2,d7.w),(ram_FF13C2).l
                andi.b  #8,(ram_FF13C2).l
.loc_A172:
                tst.w   (ram_FF13C4).l
                beq.w   .loc_A2AC
                move.w  (ram_FF13CE).l,d0
                andi.w  #7,d0
                clr.w   d1
                move.b  (ram_FF13C6).l,d1
                asl.b   #3,d1
                add.w   d1,d0
                move.w  d0,(ram_FF13CA).l
                lea     (unk_A054).l,a5
                clr.w   d1
                move.b  (ram_FF13B9).l,d1
                and.b   (a5,d0.w),d1
                move.w  d1,(ram_FF13CC).l
                lea     (unk_A094).l,a5
                clr.l   d1
                move.b  (a5,d0.w),d1
                move.w  (ram_FF13CC).l,d2
                cmp.w   #7,d1
                ble.w   .loc_A1D4
                ext.w   d1
                neg.w   d1
                asl.w   d1,d2
                bra.w   .loc_A1D6
.loc_A1D4:
                lsr.w   d1,d2
.loc_A1D6:
                move.w  d2,(ram_FF13CC).l
                move.b  d2,(ram_FF13BA).l
                clr.w   d0
                move.b  (ram_FF13C6).l,d0
                addq.w  #1,d0
                add.w   d0,(ram_FF13CE).l
                move.w  (ram_FF13CE).l,d0
                lsr.w   #3,d0
                move.w  d0,(ram_FF13D0).l
                cmp.w   (ram_FF13D2).l,d0
                beq.w   .loc_A262
                move.b  (a0)+,(ram_FF13B9).l
                move.w  (ram_FF13CE).l,d0
                andi.w  #7,d0
                beq.w   .loc_A256
                move.w  (ram_FF13CE).l,d0
                subq.w  #1,d0
                andi.w  #7,d0
                move.w  d0,(ram_FF13CA).l
                lea     (unk_A0CC).l,a5
                clr.w   d1
                move.b  (a5,d0.w),d1
                lea     (unk_A08C).l,a5
                clr.w   d2
                move.b  (ram_FF13B9).l,d2
                and.b   (a5,d0.w),d2
                lsr.w   d1,d2
                or.b    d2,(ram_FF13BA).l
.loc_A256:
                move.w  (ram_FF13D0).l,d0
                move.w  d0,(ram_FF13D2).l
.loc_A262:
                move.b  (ram_FF13B8).l,d0
                tst.b   (ram_FF13C2).l
                bne.w   .loc_A27C
                add.b   (ram_FF13BA).l,d0
                bra.w   .loc_A282
.loc_A27C:
                sub.b   (ram_FF13BA).l,d0
.loc_A282:
                move.b  d0,(ram_FF13B8).l
                move.b  d0,(a1)
                addq.l  #2,a1
                subq.w  #1,(ram_FF13B2).l
                tst.w   (ram_FF13B2).l
                bmi.w   .loc_A2C0
.loc_A29C:
                addq.w  #1,(ram_FF13C8).l
                subq.w  #1,(ram_FF13C4).l
                bra.w   .loc_A172
.loc_A2AC:
                addq.w  #1,(ram_FF13BC).l
                bra.w   .loc_A128
.loc_A2B6:
                subq.w  #1,(ram_FF13BC).l
                bra.w   .loc_A2C8
.loc_A2C0:
                move.w  #1,(ram_FF13E2).l
.loc_A2C8:
                move.l  a1,(ram_FF13D8).l
                move.l  a0,(ram_FF13D4).l
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_A0D4


; *************************************************
; Function sub_A2DA
; Channel 2 decoder: same format as channel 1, writing a1+1, a1+3, ...
; In:  state at ram_FF13E4..140E; budget d1
; Out: output at ram_FF1404; state
; Clobbers: all (saved/restored)
; *************************************************

sub_A2DA:
                movem.l d0-d7/a0-a6,-(sp)
                tst.w   (ram_FF140E).l
                bne.w   .loc_A30C
                clr.w   (ram_FF13E8).l
                clr.b   (ram_FF13E4).l
                clr.w   (ram_FF13FA).l
                clr.w   (ram_FF13FC).l
                clr.w   (ram_FF13FE).l
                clr.w   (ram_FF13F4).l
.loc_A30C:
                movea.l (ram_FF1400).l,a0
; channel 2 starts one byte after channel 1's output
                addq.l  #1,a1
                movea.l (ram_FF140A).l,a2
                move.w  d1,(ram_FF13B2).l
                tst.w   (ram_FF140E).l
                bne.w   .loc_A4A4
                move.b  (a0)+,(ram_FF13E5).l
.loc_A330:
                move.w  (ram_FF13E8).l,d0
                cmp.w   (ram_FF1408).l,d0
                bgt.w   .loc_A4BE
                move.w  (ram_FF13E8).l,d7
                move.b  (a2,d7.w),(ram_FF13F2).l
                andi.b  #7,(ram_FF13F2).l
                clr.l   d0
                move.b  (a2,d7.w),d0
                andi.w  #$F0,d0
                lsr.w   #4,d0
                addq.w  #1,d0
                move.w  d0,(ram_FF13F0).l
                move.b  (a2,d7.w),(ram_FF13EE).l
                andi.b  #8,(ram_FF13EE).l
.loc_A37A:
                tst.w   (ram_FF13F0).l
                beq.w   .loc_A4B4
                move.w  (ram_FF13FA).l,d0
                andi.w  #7,d0
                clr.w   d1
                move.b  (ram_FF13F2).l,d1
                asl.b   #3,d1
                add.w   d1,d0
                move.w  d0,(ram_FF13F6).l
                lea     (unk_A054).l,a5
                clr.w   d1
                move.b  (ram_FF13E5).l,d1
                and.b   (a5,d0.w),d1
                move.w  d1,(ram_FF13F8).l
                lea     (unk_A094).l,a5
                clr.l   d1
                move.b  (a5,d0.w),d1
                move.w  (ram_FF13F8).l,d2
                cmp.w   #7,d1
                ble.w   .loc_A3DC
                ext.w   d1
                neg.w   d1
                asl.w   d1,d2
                bra.w   .loc_A3DE
.loc_A3DC:
                lsr.w   d1,d2
.loc_A3DE:
                move.w  d2,(ram_FF13F8).l
                move.b  d2,(ram_FF13E6).l
                clr.w   d0
                move.b  (ram_FF13F2).l,d0
                addq.w  #1,d0
                add.w   d0,(ram_FF13FA).l
                move.w  (ram_FF13FA).l,d0
                lsr.w   #3,d0
                move.w  d0,(ram_FF13FC).l
                cmp.w   (ram_FF13FE).l,d0
                beq.w   .loc_A46A
                move.b  (a0)+,(ram_FF13E5).l
                move.w  (ram_FF13FA).l,d0
                andi.w  #7,d0
                beq.w   .loc_A45E
                move.w  (ram_FF13FA).l,d0
                subq.w  #1,d0
                andi.w  #7,d0
                move.w  d0,(ram_FF13F6).l
                lea     (unk_A0CC).l,a5
                clr.w   d1
                move.b  (a5,d0.w),d1
                lea     (unk_A08C).l,a5
                clr.w   d2
                move.b  (ram_FF13E5).l,d2
                and.b   (a5,d0.w),d2
                lsr.w   d1,d2
                or.b    d2,(ram_FF13E6).l
.loc_A45E:
                move.w  (ram_FF13FC).l,d0
                move.w  d0,(ram_FF13FE).l
.loc_A46A:
                move.b  (ram_FF13E4).l,d0
                tst.b   (ram_FF13EE).l
                bne.w   .loc_A484
                add.b   (ram_FF13E6).l,d0
                bra.w   .loc_A48A
.loc_A484:
                sub.b   (ram_FF13E6).l,d0
.loc_A48A:
                move.b  d0,(ram_FF13E4).l
                move.b  d0,(a1)
                addq.l  #2,a1
                subq.w  #1,(ram_FF13B2).l
                tst.w   (ram_FF13B2).l
                bmi.w   .loc_A4C8
.loc_A4A4:
                addq.w  #1,(ram_FF13F4).l
                subq.w  #1,(ram_FF13F0).l
                bra.w   .loc_A37A
.loc_A4B4:
                addq.w  #1,(ram_FF13E8).l
                bra.w   .loc_A330
.loc_A4BE:
                subq.w  #1,(ram_FF13E8).l
                bra.w   .loc_A4D0
.loc_A4C8:
                move.w  #1,(ram_FF140E).l
.loc_A4D0:
                move.l  a1,(ram_FF1404).l
                move.l  a0,(ram_FF1400).l
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_A2DA
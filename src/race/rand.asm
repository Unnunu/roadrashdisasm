; *************************************************
; rand.asm - PRNG and LFSR helpers
; ROM range: $015FA8-$0160E1.
; Included by race_anim_audio.asm at the original block location so the ROM
; layout stays byte-exact. Do not include this file from race.asm directly.
; *************************************************

; 32-word initial state table for the lagged-sum PRNG.
Rand_InitTable: dc.b $3D
                dc.b $52 ; R
                dc.b $7F ; 
                dc.b $31 ; 1
                dc.b $80
                dc.b $A2
                dc.b $ED
                dc.b $16
                dc.b $42 ; B
                dc.b $BF
                dc.b $5C ;
                dc.b $41 ; A
                dc.b  $C
                dc.b $5E ; ^
                dc.b $92
                dc.b $26 ; &
                dc.b $A5
                dc.b $8B
                dc.b $48 ; H
                dc.b $2D ; -
                dc.b $64 ; d
                dc.b $D9
                dc.b $82
                dc.b $AD
                dc.b $E1
                dc.b $79 ; y
                dc.b $21 ; !
                dc.b $4B ; K
                dc.b $81
                dc.b $4C ; L
                dc.b $D7
                dc.b $36 ; 6
                dc.b $97
                dc.b $CF
                dc.b $AE
                dc.b $B1
                dc.b $F7
                dc.b $CB
                dc.b $6A ; j
                dc.b $9B
                dc.b  $C
                dc.b $59 ; Y
                dc.b $85
                dc.b $34 ; 4
                dc.b $71 ; q
                dc.b $89
                dc.b $15
                dc.b $93
                dc.b $6B ; k
                dc.b $C5
                dc.b   7
                dc.b $AC
                dc.b $3C ; <
                dc.b $7F ; 
                dc.b $A4
                dc.b $3E ; >
                dc.b $DA
                dc.b $69 ; i
                dc.b $18
                dc.b $1E
                dc.b $9B
                dc.b $D1
                dc.b $D5
                dc.b $7F ; 




; *************************************************
; Function Rand_InitSum
; Copies the 32-word initial state and adds the seed to every word.
; In:       d0.w - seed added to each state word
; Out:      Rand_ram_State = Rand_InitTable + seed; Rand_ram_Index1 = 0;
;           Rand_ram_Index2 = 15
; Clobbers: none (d0/d1/a0/a1 saved and restored)
; Notes:    ROM $015FE8-$016033. The index calculation collapses:
;           (seed << 7) & $1F is always zero, so index 1 is always 0 and
;           index 2 is always 15 regardless of the seed. Only the state
;           words depend on d0.
; *************************************************

Rand_InitSum:
                movem.l d0-d1/a0-a1,-(sp)
                move.w  d0,d1

                lea     (Rand_InitTable).l,a0
                lea     (Rand_ram_State).l,a1
                move.w  #$20,d0
.copyLoop:
                move.w  (a0)+,(a1)+
                dbf     d0,.copyLoop

                lea     (Rand_ram_State).l,a0
                move.w  #$20,d0
.addSeedLoop:
                add.w   d1,(a0)+
                dbf     d0,.addSeedLoop

                lsl.w   #7,d1
                andi.w  #$1F,d1
                move.w  d1,(Rand_ram_Index1).l

                addi.w  #$F,d1
                andi.w  #$1F,d1
                move.w  d1,(Rand_ram_Index2).l

                movem.l (sp)+,d0-d1/a0-a1
                rts
; End of function Rand_InitSum




; *************************************************
; Function Rand_NextWord
; Returns a lagged-sum PRNG word and advances both indexes.
; In:       Rand_ram_State - 32-word state; Rand_ram_Index1/Rand_ram_Index2 - indexes
; Out:      d0.w - state[i1] + state[i2]; d0 high word unchanged;
;           state[i1] = result; both indexes increment modulo 32
; Clobbers: d0 only (d1/d2/a0 saved and restored)
; Notes:    ROM $016034-$01607B. Additive lagged-sum generator; no bounds
;           checks on the indexes. With Rand_InitSum's fixed 0/15 indexes the
;           lag between the two taps stays 15.
; *************************************************

Rand_NextWord:
                movem.l d1-d2/a0,-(sp)
                move.w  (Rand_ram_Index1).l,d1
                lsl.w   #1,d1
                move.w  (Rand_ram_Index2).l,d2
                lsl.w   #1,d2
                lea     (Rand_ram_State).l,a0
                move.w  (a0,d1.w),d0
                add.w   (a0,d2.w),d0
                move.w  d0,(a0,d1.w)
                addq.w  #1,(Rand_ram_Index1).l
                andi.w  #$1F,(Rand_ram_Index1).l
                addq.w  #1,(Rand_ram_Index2).l
                andi.w  #$1F,(Rand_ram_Index2).l
                movem.l (sp)+,d1-d2/a0
                rts
; End of function Rand_NextWord




; *************************************************
; Function Rand_GetByte
; Returns the high byte of the next Rand_NextWord value.
; In:       PRNG state as for Rand_NextWord
; Out:      d0.l - 0..255 (high word cleared)
; Clobbers: d0
; Notes:    ROM $01607C-$016087. Unreferenced by the current sources/ROM;
;           a byte-sized wrapper around Rand_NextWord.
; *************************************************

Rand_GetByte:
                bsr.s   Rand_NextWord
                lsr.w   #8,d0
                andi.l  #$FF,d0
                rts
; End of function Rand_GetByte




; *************************************************
; Function Rand_SeedLfsrs
; Seeds both 16-bit LFSR states with $563A.
; In:       none
; Out:      Rand_ram_LfsrA = $563A; Rand_ram_LfsrB = $563A
; Clobbers: none
; Notes:    ROM $016088-$016099. Called only from Intro_Init; no other code
;           reads these state words in the current sources/ROM.
; *************************************************

Rand_SeedLfsrs:
                move.w  #$563A,(Rand_ram_LfsrA).l
                move.w  #$563A,(Rand_ram_LfsrB).l
                rts
; End of function Rand_SeedLfsrs




; *************************************************
; Function Rand_StepLfsrA
; Advances LFSR A one step and returns the new state.
; In:       Rand_ram_LfsrA - 16-bit LFSR state
; Out:      d0.w - new state; d0 high word unchanged; Rand_ram_LfsrA updated
; Clobbers: d0
; Notes:    ROM $01609A-$0160AF. Right-shift Galois LFSR with feedback mask
;           $B400. Unreferenced by the current sources/ROM.
; *************************************************

Rand_StepLfsrA:
                move.w  (Rand_ram_LfsrA).l,d0
                lsr.w   #1,d0
                bcc.s   .noFeedbackA
                eori.w  #$B400,d0

.noFeedbackA:
                move.w  d0,(Rand_ram_LfsrA).l
                rts
; End of function Rand_StepLfsrA




; *************************************************
; Function Rand_StepLfsrAMod
; Advances LFSR A and returns the signed-division remainder.
; In:       Rand_ram_LfsrA - 16-bit LFSR state; d2.w - nonzero divisor
; Out:      d0.l low word = division remainder when no overflow;
;           d0.l high word = quotient; Rand_ram_LfsrA = new state
; Clobbers: d0
; Notes:    ROM $0160B0-$0160CB. The state is zero-extended into d0, then
;           divs.w is used; d2 = 0 raises a divide-by-zero exception. Large
;           states can make the signed quotient overflow. The only caller
;           passes d2 = 1 and ignores d0.
; *************************************************

Rand_StepLfsrAMod:
                moveq   #0,d0
                move.w  (Rand_ram_LfsrA).l,d0
                lsr.w   #1,d0
                bcc.s   .noFeedbackB
                eori.w  #$B400,d0

.noFeedbackB:
                move.w  d0,(Rand_ram_LfsrA).l
                divs.w  d2,d0
                swap    d0
                rts
; End of function Rand_StepLfsrAMod




; *************************************************
; Function Rand_StepLfsrB
; Advances LFSR B one step and returns the new state.
; In:       Rand_ram_LfsrB - 16-bit LFSR state
; Out:      d0.w - new state; d0 high word unchanged; Rand_ram_LfsrB updated
; Clobbers: d0
; Notes:    ROM $0160CC-$0160E1. Same right-shift Galois LFSR/mask as
;           Rand_StepLfsrA, with a second state word. The only caller ignores d0.
; *************************************************

Rand_StepLfsrB:
                move.w  (Rand_ram_LfsrB).l,d0
                lsr.w   #1,d0
                bcc.s   .noFeedbackB2
                eori.w  #$B400,d0

.noFeedbackB2:
                move.w  d0,(Rand_ram_LfsrB).l
                rts
; End of function Rand_StepLfsrB

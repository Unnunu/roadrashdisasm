; *************************************************
; Function Fade_InitFadeOut
; a0 - target update function
; *************************************************

Fade_InitFadeOut:
                move.l  a0,Fade_ram_UpdateFunction
                move.w  #3,Fade_ram_Timer
                move.l  #Global_ram_Palette,Global_ram_PalettePtr
                movea.l Global_ram_PalettePtr,a0
                lea     Fade_ram_TargetPalette,a1
                lea     Fade_ram_CurrentPalette,a2
; load palette
                move.w  #$3F,d0
@loop:
                move.w  (a0)+,(a2)+ ; copy to current palette
                andi.w  #$EEE,-2(a2)
                move.w  #0,(a1)+ ; set target palette blank
                dbf     d0,@loop
                rts
; End of function Fade_InitFadeOut

; *************************************************
; Function Fade_InitFadeIn
; a0 - target update function
; *************************************************

Fade_InitFadeIn:
                move.l  a0,Fade_ram_UpdateFunction
                move.w  #3,Fade_ram_Timer
                move.l  #Global_ram_Palette,Global_ram_PalettePtr
                movea.l Global_ram_PalettePtr,a0
                lea     Fade_ram_TargetPalette,a1
                lea     Fade_ram_CurrentPalette,a2

                move.w  #$3F,d0
@loop:
                move.w  (a0)+,(a1)+ ; copy to target palette
                andi.w  #$EEE,-2(a1)
                move.w  #0,(a2)+ ; set current palette blank
                dbf     d0,@loop
                rts
; End of function Fade_InitFadeIn

; *************************************************
; Function Fade_GameTickWithInit and Fade_GameTick
; *************************************************

Fade_GameTickWithInit:
                lea     VdpCtrl,a0
                lea     VdpData,a1
                move.w  #$8210,(a0) ; Scroll A Name Table:    $4000
                move.w  #$8402,(a0) ; Scroll B Name Table:    $4000
                move.w  #$873F,(a0) ; Backdrop Color: $3F, palette 3, color $F
                movea.l ram_FF389C,a2
                move.w  (a2),(a0)
                move.w  4(a2),(a0)
                move.l  #$40000010,(a0) ; VSRAM from offset 0
                move.l  6(a2),(a1)
                move.w  $A(a2),ram_FF0406
                move.l  $C(a2),(a0)
                move.w  #0,ram_FF369E
Fade_GameTick:
                subq.w  #1,Fade_ram_Timer
                bpl.w   @end
                move.w  #3,Fade_ram_Timer ; do this every 4th frame
; write current palette
                move.l  #Fade_ram_CurrentPalette,d0 ; DMA source
                move.w  #0,d1 ; DMA destination
                move.w  #$40,d2 ; DMA size / 2, load $80 bytes
                jsr     DmaWriteCRAM

                lea     Fade_ram_TargetPalette,a0
                lea     Fade_ram_CurrentPalette,a1
                move.w  #$3F,d0 ; check $40 words
                clr.w   d1
@loopCompare:
; compare bytes
                move.b  (a0)+,d2 ; get target 'blue' value
                sub.b   (a1)+,d2
                beq.w   @loc_1296
                bpl.w   @greaterByte
; if target < current
                or.w    d2,d1
                subq.b  #2,-1(a1) ; decrease current value by 2 (least possible change)
                bra.w   @loc_1296
@greaterByte:   ; target > current
                or.w    d2,d1
                addq.b  #2,-1(a1)
@loc_1296:
; compare higher nibble
                move.b  (a0),d2
                andi.w  #$F0,d2
                move.b  (a1),d3
                andi.w  #$F0,d3
                sub.b   d3,d2
                beq.w   @loc_12BC
                bpl.w   @greaterNibble
                or.w    d2,d1
                subi.b  #$20,(a1)
                bra.w   @loc_12BC
@greaterNibble:
                or.w    d2,d1
                addi.b  #$20,(a1)
@loc_12BC:
; compare lower nibble
                move.b  (a0)+,d2
                andi.w  #$F,d2
                move.b  (a1)+,d3
                andi.w  #$F,d3
                sub.b   d3,d2
                beq.w   @loc_12E2
                bpl.w   @loc_12DC
                or.w    d2,d1
                subq.b  #2,-1(a1)
                bra.w   @loc_12E2
@loc_12DC:
                or.w    d2,d1
                addq.b  #2,-1(a1)
@loc_12E2:
                dbf     d0,@loopCompare

                tst.w   d1
                bne.w   @end
                move.l  #0,ram_UpdateFunction ; disable GameTick function, move to next game stage
@end:
                rts
; End of function Fade_GameTickWithInit and Fade_GameTick

; *************************************************
; Function FadeWithFunction_GameTick
; *************************************************

FadeWithFunction_GameTick:
                subq.w  #1,Fade_ram_Timer
                bpl.w   @end
                move.w  #3,Fade_ram_Timer

                move.l  #Fade_ram_CurrentPalette,d0
                move.w  #0,d1
                move.w  #$40,d2
                jsr     DmaWriteCRAM

                lea     Fade_ram_TargetPalette,a0
                lea     Fade_ram_CurrentPalette,a1
                move.w  #$3F,d0
                clr.w   d1
@loc_1330:
                move.b  (a0)+,d2
                sub.b   (a1)+,d2
                beq.w   @loc_134C
                bpl.w   @loc_1346
                or.w    d2,d1
                subq.b  #2,-1(a1)
                bra.w   @loc_134C
@loc_1346:
                or.w    d2,d1
                addq.b  #2,-1(a1)
@loc_134C:
                move.b  (a0),d2
                andi.w  #$F0,d2
                move.b  (a1),d3
                andi.w  #$F0,d3
                sub.b   d3,d2
                beq.w   @loc_1372
                bpl.w   @loc_136C
                or.w    d2,d1
                subi.b  #$20,(a1)
                bra.w   @loc_1372
@loc_136C:
                or.w    d2,d1
                addi.b  #$20,(a1)
@loc_1372:
                move.b  (a0)+,d2
                andi.w  #$F,d2
                move.b  (a1)+,d3
                andi.w  #$F,d3
                sub.b   d3,d2
                beq.w   @loc_1398
                bpl.w   @loc_1392
                or.w    d2,d1
                subq.b  #2,-1(a1)
                bra.w   @loc_1398
@loc_1392:
                or.w    d2,d1
                addq.b  #2,-1(a1)
@loc_1398:
                dbf     d0,@loc_1330
                tst.w   d1
                bne.w   @loc_13AC
                move.l  Fade_ram_UpdateFunction,ram_UpdateFunction
@loc_13AC:
                movea.l Fade_ram_UpdateFunction,a0
                cmpa.l  #0,a0
                beq.w   @end
                jmp     (a0)
@end:
                rts
; End of function FadeWithFunction_GameTick
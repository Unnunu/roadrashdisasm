    include "hw_const.asm"
    include "unknown.asm"
    include "ram_const.asm"

vectorTable:
    dc.l    $FFFFF6 ; Initial stack address
    dc.l    RESET    ; Start of program Code 
    dc.l    $13C0   ; Bus error
    dc.l    $13CE   ; Address error
    dc.l    $13DC   ; Illegal instruction
    dc.l    $13EA   ; Division by zero
    dc.l    $13F8   ; CHK exception
    dc.l    $1406   ; TRAPV exception
    dc.l    $1414   ; Privilege violation
    dc.l    $1422   ; TRACE exception
    dc.l    $1430   ; Line-A emulator
    dc.l    $143E   ; Line-F emulator
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Co-processor protocol violation
    dc.l    $144C   ; Format error
    dc.l    $144C   ; Uninitialized Interrupt
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Spurious Interrupt
    dc.l    $144C   ; IRQ Level 1
    dc.l    $144C   ; IRQ Level 2 (EXT Interrupt)
    dc.l    $144C   ; IRQ Level 3
    dc.l    $145A   ; IRQ Level 4 (VDP Horizontal Interrupt)
    dc.l    $144C   ; IRQ Level 5
    dc.l    VerticalInterrupt   ; IRQ Level 6 (VDP Vertical Interrupt)
    dc.l    $144C   ; IRQ Level 7
    dc.l    $144C   ; TRAP #00 Exception
    dc.l    $144C   ; TRAP #01 Exception
    dc.l    $144C   ; TRAP #02 Exception
    dc.l    $144C   ; TRAP #03 Exception
    dc.l    $144C   ; TRAP #04 Exception
    dc.l    $144C   ; TRAP #05 Exception
    dc.l    $144C   ; TRAP #06 Exception
    dc.l    $144C   ; TRAP #07 Exception
    dc.l    $144C   ; TRAP #08 Exception
    dc.l    $144C   ; TRAP #09 Exception
    dc.l    $144C   ; TRAP #10 Exception
    dc.l    $144C   ; TRAP #11 Exception
    dc.l    $144C   ; TRAP #12 Exception
    dc.l    $144C   ; TRAP #13 Exception
    dc.l    $144C   ; TRAP #14 Exception
    dc.l    $144C   ; TRAP #15 Exception
    dc.l    $144C   ; (FP) Branch or Set on Unordered Condition
    dc.l    $144C   ; (FP) Inexact Result
    dc.l    $144C   ; (FP) Divide by Zero
    dc.l    $144C   ; (FP) Underflow
    dc.l    $144C   ; (FP) Operand Error
    dc.l    $144C   ; (FP) Overflow
    dc.l    $144C   ; (FP) Signaling NAN
    dc.l    $144C   ; (FP) Unimplemented Data Type
    dc.l    $144C   ; MMU Configuration Error
    dc.l    $144C   ; MMU Illegal Operation Error
    dc.l    $144C   ; MMU Access Violation Error
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)
    dc.l    $144C   ; Reserved (NOT USED)

header:
    dc.b    "SEGA GENESIS    "                                  ; System type
    dc.b    "(C)T-50 1991.SEP"                                  ; Copyright and release date
    dc.b    "Road Rash                                       "  ; Game title (domestic)
    dc.b    "Road Rash                                       "  ; Game title (overseas)
    dc.b    "GM T-50116 -00"                                    ; Serial number
    dc.w    $1EF5                                               ; ROM checksum
    dc.b    "J               "                                  ; Device support
    dc.l    $0                                                  ; ROM address start
    dc.l    $BFFFF                                              ; ROM address end
    dc.l    $FF0000                                             ; RAM address start
    dc.l    $FFFFFF                                             ; RAM address end
    dc.b    "            "                                      ; Extra memory
    dc.b    "            "                                      ; Modem support
    dc.b    "                                        "          ; Reserved
    dc.b    "U  "                                               ; Region support
    dc.b    "             "                                     ; Reserved

RESET:
    tst.l   $A10008
    bne.s   @portA
    tst.w   $A1000C

@portA:
    bne.s   start
    lea     defaults(pc),a5
    movem.w (a5)+,d5-d7
    movem.l (a5)+,a0-a4
    move.b  -$10FF(a1),d0 ; read from A10001
    andi.b  #$F,d0
    beq.s   @noTMSS
    move.l  #'SEGA',$2F00(a1) ; A14000 disable TMSS

@noTMSS:
    move.w  (a4),d0
    moveq   #0,d0
    movea.l d0,a6
    move.l  a6,usp

    moveq   #$17,d1 ; set regs from 0 to $17

@vdp_registers:
    move.b  (a5)+,d5
    move.w  d5,(a4)
    add.w   d7,d5
    dbf     d1,@vdp_registers

    move.l  (a5)+,(a4) ; set VRAM FILL destination
    move.w  d0,(a3) ; trigger FILL
    move.w  d7,(a1) ; $100 -> A11100 z80 BUS request
    move.w  d7,(a2) ; $100 -> A11200 z80 RESET

@z80_bus_req:
    btst    d0,(a1)
    bne.s   @z80_bus_req

    moveq   #(z80_end-z80_start) - 1,d2

@z80_load:
    move.b  (a5)+,(a0)+
    dbf     d2,@z80_load
    move.w  d0,(a2) ; $100 -> A11200 z80 RESET off
    move.w  d0,(a1) ; $000 -> A11100 z80 BUS release
    move.w  d7,(a2) ; $100 -> A11200 z80 RESET

@clear_ram:
    move.l  d0,-(a6) ; clear M68k RAM
    dbf     d6,@clear_ram

    move.l  (a5)+,(a4)
    move.l  (a5)+,(a4) ; CRAM write
    moveq   #$1F,d3

@clear_cram:
    move.l  d0,(a3)
    dbf     d3,@clear_cram

    move.l  (a5)+,(a4) ; VSRAM write
    moveq   #$13,d4

@clear_vsram:
    move.l  d0,(a3)
    dbf     d4,@clear_vsram

    moveq   #3,d5

@mute_psg:
    move.b  (a5)+,$11(a3)
    dbf     d5,@mute_psg

    move.w  d0,(a2)
    movem.l (a6),d0-a6
    move    #$2700,sr

start:
    bra.s   doStart

defaults:
    dc.w $8000   ; d5
    dc.w $3FFF   ; d6 M68k ram size for zero memset
    dc.w $100    ; d7
    dc.l $A00000 ; a0 Where Z80 RAM starts
    dc.l $A11100 ; a1 Z80 bus request line
    dc.l $A11200 ; a2 Z80 reset line
    dc.l $C00000 ; a3
    dc.l $C00004 ; a4
    ; VDP regs
    dc.b 4   ; 0 palette select
    dc.b $14 ; 1 Display off, DMA on, GENESIS
    dc.b $30 ; 2 Plane A C000
    dc.b $3C ; 3 Window F000
    dc.b 7   ; 4 Plane B E000
    dc.b $6C ; 5 Sprite table at D800
    dc.b 0   ; 6 Unused
    dc.b 0   ; 7 Backdrop color = 0
    dc.b 0,0 ; 8,9 Unused
    dc.b $FF ; A HBlank counter
    dc.b 0   ; B Full screen scroll
    dc.b $81 ; C Display width 320, No interlace
    dc.b $37 ; D HSCROLL table at DC00
    dc.b 0   ; E Unused
    dc.b 1   ; F Autoincrement 1
    dc.b 1   ; 10 Planes size 64x32
    dc.b 0   ; 11 Window x pos = disabled
    dc.b 0   ; 12 Window y pos = disabled
    dc.b $FF ; 13 DMA len low
    dc.b $FF ; 14 DMA len high
    dc.b 0   ; 15 DMA source low
    dc.b 0   ; 16 DMA source mid
    dc.b $80 ; 17 DMA source high -> FILL
    dc.l $40000080 ; DMA -> VRAM offset 0
    ; z80 A00000-A00026
z80_start:
    dc.l $AF01D91F, $11270021, $2600F977, $EDB0DDE1
    dc.l $FDE1ED47, $ED4FD1E1, $F108D9C1, $D1E1F1F9
    dc.w $F3ED, $5636, $E9E9
z80_end:
    dc.l $81048F02 ; display, vblank, dma OFF, rows 28, autoincrement 2
    dc.l $C0000000 ; CRAM from offset 0
    dc.l $40000010 ; VSRAM from offset 0
    dc.b $9F,$BF,$DF,$FF ; PSG mute

doStart:
    tst.w   VdpCtrl
    jsr     sub_7FF98
    move    #$2700,sr
    tst.l   $A10008
    bne.s   @anyButtonPressed
    tst.w   $A1000C
    bne.s   @anyButtonPressed
    bsr.w   LogoEA_Init
    move.w  #$8174,VdpCtrl  ; Enable display
    move.w  #$FFFF,ram_FF369E
    move.l  #LogoEA_GameTick,ram_FF1A62
    move    #$2500,sr

@loopCheckFinished:
    jsr     GetFirstControllerInput
    move.w  d0,d1
    bsr.w   GetSecondControllerInput
    or.w    d1,d0
    tst.b   d0
    bne.s   @anyButtonPressed
    tst.b   LogoEA_ram_Finished
    beq.s   @loopCheckFinished

@anyButtonPressed:
    move.l  #0,ram_FF1A62
    jmp     loc_7E6A2

; end of function RESET

    include "logoEA.asm"

; *************************************************
; Function GetFirstControllerInput
; d0 - (out) button state (SACBRLDU)
; *************************************************

GetFirstControllerInput:
                move.l  d1,-(sp)
                move.b  #$40,($A10009).l	; TH pin to write, others to read
                move.b  #0,($A10003).l      ; clear TH
; wait 10 ticks
                move.w  #$A,d1
@wait:
                dbf     d1,@wait

                move.b  ($A10003).l,d0      ; read inputs
                asl.b   #2,d0
                andi.b  #$C0,d0             ; shift bits so A is bit 6 and START is bit 7

                move.b  #$40,($A10003).l    ; set TH
; wait 10 ticks
                move.w  #$A,d1
@wait2:
                dbf     d1,@wait2

                move.b  ($A10003).l,d1      ; read inputs
                andi.b  #$3F,d1             ; get state of 6 buttons
                or.b    d1,d0               ; move everything to d0
                not.b   d0                  ; invert bits
                move.l  (sp)+,d1
                rts
; End of function GetFirstControllerInput

; *************************************************
; Function GetSecondControllerInput
; d0 - (out) button state (SACBRLDU)
; *************************************************

GetSecondControllerInput:
                move.l  d1,-(sp)
                move.b  #$40,($A1000B).l
                move.b  #0,($A10005).l

                move.w  #$14,d1
@wait:
                dbf     d1,@wait

                move.b  ($A10005).l,d0
                asl.b   #2,d0
                andi.b  #$C0,d0
                move.b  #$40,($A10005).l

                move.w  #$14,d1
@wait2:
                dbf     d1,@wait2

                move.b  ($A10005).l,d1
                andi.b  #$3F,d1
                or.b    d1,d0
                not.b   d0
                move.l  (sp)+,d1
                rts
; End of function GetSecondControllerInput

; *************************************************
; Interrupt Handler VerticalInterrupt
; *************************************************

VerticalInterrupt:
                movem.l d0-d7/a0-a6,-(sp)
                movea.l ram_FF1A62,a0
                cmpa.l  #0,a0
                beq.w   @return
                jsr     (a0)
@return:
                movem.l (sp)+,d0-d7/a0-a6
                rte
; End of Interrupt Handler VerticalInterrupt
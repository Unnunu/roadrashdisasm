    include "hw_const.asm"
    include "unknown.asm"
    include "ram_const.asm"

vectorTable:
    dc.l    $FFFFF6 ; Initial stack address
    dc.l    RESET    ; Start of program Code 
    dc.l    BusError   ; Bus error
    dc.l    AddressError   ; Address error
    dc.l    IllegalInstructionError   ; Illegal instruction
    dc.l    ZeroDivisionError   ; Division by zero
    dc.l    CheckException   ; CHK exception
    dc.l    TrapVException   ; TRAPV exception
    dc.l    PrivilegeViolation   ; Privilege violation
    dc.l    TraceException   ; TRACE exception
    dc.l    LineAEmulator   ; Line-A emulator
    dc.l    LineFEmulator   ; Line-F emulator
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Co-processor protocol violation
    dc.l    SpuriousInterrupt   ; Format error
    dc.l    SpuriousInterrupt   ; Uninitialized Interrupt
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Spurious Interrupt
    dc.l    SpuriousInterrupt   ; IRQ Level 1
    dc.l    SpuriousInterrupt   ; IRQ Level 2 (EXT Interrupt)
    dc.l    SpuriousInterrupt   ; IRQ Level 3
    dc.l    HorizontalInterrupt   ; IRQ Level 4 (VDP Horizontal Interrupt)
    dc.l    SpuriousInterrupt   ; IRQ Level 5
    dc.l    VerticalInterrupt   ; IRQ Level 6 (VDP Vertical Interrupt)
    dc.l    SpuriousInterrupt   ; IRQ Level 7
    dc.l    SpuriousInterrupt   ; TRAP #00 Exception
    dc.l    SpuriousInterrupt   ; TRAP #01 Exception
    dc.l    SpuriousInterrupt   ; TRAP #02 Exception
    dc.l    SpuriousInterrupt   ; TRAP #03 Exception
    dc.l    SpuriousInterrupt   ; TRAP #04 Exception
    dc.l    SpuriousInterrupt   ; TRAP #05 Exception
    dc.l    SpuriousInterrupt   ; TRAP #06 Exception
    dc.l    SpuriousInterrupt   ; TRAP #07 Exception
    dc.l    SpuriousInterrupt   ; TRAP #08 Exception
    dc.l    SpuriousInterrupt   ; TRAP #09 Exception
    dc.l    SpuriousInterrupt   ; TRAP #10 Exception
    dc.l    SpuriousInterrupt   ; TRAP #11 Exception
    dc.l    SpuriousInterrupt   ; TRAP #12 Exception
    dc.l    SpuriousInterrupt   ; TRAP #13 Exception
    dc.l    SpuriousInterrupt   ; TRAP #14 Exception
    dc.l    SpuriousInterrupt   ; TRAP #15 Exception
    dc.l    SpuriousInterrupt   ; (FP) Branch or Set on Unordered Condition
    dc.l    SpuriousInterrupt   ; (FP) Inexact Result
    dc.l    SpuriousInterrupt   ; (FP) Divide by Zero
    dc.l    SpuriousInterrupt   ; (FP) Underflow
    dc.l    SpuriousInterrupt   ; (FP) Operand Error
    dc.l    SpuriousInterrupt   ; (FP) Overflow
    dc.l    SpuriousInterrupt   ; (FP) Signaling NAN
    dc.l    SpuriousInterrupt   ; (FP) Unimplemented Data Type
    dc.l    SpuriousInterrupt   ; MMU Configuration Error
    dc.l    SpuriousInterrupt   ; MMU Illegal Operation Error
    dc.l    SpuriousInterrupt   ; MMU Access Violation Error
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)
    dc.l    SpuriousInterrupt   ; Reserved (NOT USED)

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
    move.l  #LogoEA_GameTick,ram_UpdateFunction
    move    #$2500,sr

@loopCheckFinished:
    jsr     GetInputPlayerA
    move.w  d0,d1
    bsr.w   GetInputPlayerB
    or.w    d1,d0
    tst.b   d0
    bne.s   @anyButtonPressed
    tst.b   LogoEA_ram_Finished
    beq.s   @loopCheckFinished

@anyButtonPressed:
    move.l  #0,ram_UpdateFunction
    jmp     loc_7E6A2

; end of function RESET

    include "logoEA.asm"

; *************************************************
; Function GetInputPlayerA
; d0 - (out) button state (SACBRLDU)
; *************************************************

GetInputPlayerA:
                move.l  d1,-(sp)
                move.b  #$40,$A10009	; TH pin to write, others to read
                move.b  #0,$A10003     ; clear TH
; wait 10 ticks
                move.w  #$A,d1
@wait:
                dbf     d1,@wait

                move.b  $A10003,d0      ; read inputs
                asl.b   #2,d0
                andi.b  #$C0,d0             ; shift bits so A is bit 6 and START is bit 7

                move.b  #$40,$A10003    ; set TH
; wait 10 ticks
                move.w  #$A,d1
@wait2:
                dbf     d1,@wait2

                move.b  $A10003,d1      ; read inputs
                andi.b  #$3F,d1             ; get state of 6 buttons
                or.b    d1,d0               ; move everything to d0
                not.b   d0                  ; invert bits
                move.l  (sp)+,d1
                rts
; End of function GetInputPlayerA

; *************************************************
; Function GetInputPlayerB
; d0 - (out) button state (SACBRLDU)
; *************************************************

GetInputPlayerB:
                move.l  d1,-(sp)
                move.b  #$40,$A1000B
                move.b  #0,$A10005

                move.w  #$14,d1
@wait:
                dbf     d1,@wait

                move.b  $A10005,d0
                asl.b   #2,d0
                andi.b  #$C0,d0
                move.b  #$40,$A10005

                move.w  #$14,d1
@wait2:
                dbf     d1,@wait2

                move.b  $A10005,d1
                andi.b  #$3F,d1
                or.b    d1,d0
                not.b   d0
                move.l  (sp)+,d1
                rts
; End of function GetInputPlayerB

; *************************************************
; Interrupt Handler VerticalInterrupt
; *************************************************

VerticalInterrupt:
                movem.l d0-d7/a0-a6,-(sp)
                movea.l ram_UpdateFunction,a0
                cmpa.l  #0,a0
                beq   @return
                jsr     (a0)
@return:
                movem.l (sp)+,d0-d7/a0-a6
                rte
; End of Interrupt Handler VerticalInterrupt

    include "fade.asm"

; *************************************************
; Interrupt Handler BusError
; *************************************************

BusError:
                lea     (vectorTable).w,a0
                move.l  #'BUS ',(a0)
                stop    #$2700
; End of Interrupt Handler BusError

; *************************************************
; Interrupt Handler AddressError
; *************************************************

AddressError:
                lea     (vectorTable).w,a0
                move.l  #'ADDR',(a0)
                stop    #$2700
; End of Interrupt Handler AddressError

; *************************************************
; Interrupt Handler IllegalInstructionError
; *************************************************

IllegalInstructionError:
                lea     (vectorTable).w,a0
                move.l  #'ILEG',(a0)
                stop    #$2700
; End of Interrupt Handler IllegalInstructionError

; *************************************************
; Interrupt Handler ZeroDivisionError
; *************************************************

ZeroDivisionError:
                lea     (vectorTable).w,a0
                move.l  #'ZDIV',(a0)
                stop    #$2700
; End of Interrupt Handler ZeroDivisionError

; *************************************************
; Interrupt Handler CheckException
; *************************************************

CheckException:
                lea     (vectorTable).w,a0
                move.l  #'CHK ',(a0)
                stop    #$2700
; End of Interrupt Handler CheckException

; *************************************************
; Interrupt Handler TrapVException
; *************************************************

TrapVException:
                lea     (vectorTable).w,a0
                move.l  #'TRPV',(a0)
                stop    #$2700
; End of Interrupt Handler TrapVException

; *************************************************
; Interrupt Handler PrivilegeViolation
; *************************************************

PrivilegeViolation:
                lea     (vectorTable).w,a0
                move.l  #'PRIV',(a0)
                stop    #$2700
; End of Interrupt Handler PrivilegeViolation

; *************************************************
; Interrupt Handler TraceException
; *************************************************

TraceException:
                lea     (vectorTable).w,a0
                move.l  #'TRAC',(a0)
                stop    #$2700
; End of Interrupt Handler TraceException

; *************************************************
; Interrupt Handler LineAEmulator
; *************************************************

LineAEmulator:
                lea     (vectorTable).w,a0
                move.l  #'LINA',(a0)
                stop    #$2700
; End of Interrupt Handler LineAEmulator

; *************************************************
; Interrupt Handler LineFEmulator
; *************************************************

LineFEmulator:
                lea     (vectorTable).w,a0
                move.l  #'LINF',(a0)
                stop    #$2700
; End of Interrupt Handler LineFEmulator

; *************************************************
; Interrupt Handler SpuriousInterrupt
; *************************************************

SpuriousInterrupt:
                lea     (vectorTable).w,a0
                move.l  #'SPUR',(a0)
                stop    #$2700
; End of Interrupt Handler SpuriousInterrupt

; *************************************************
; Interrupt Handler HorizontalInterrupt
; *************************************************

HorizontalInterrupt:
                move.w  #$8AFF,VdpCtrl ; next Hint after 255 scanlines
                cmpi.w  #$FFFF,ram_FF369E
                beq.w   @return
                movem.l d0-d2/a0-a2,-(sp)
                lea     VdpCtrl,a1
                lea     VdpData,a2
                move.w  ram_FF0406,d0
                ble.w   @loc_1632
                movea.l Race_ram_NextVScrollInfo,a0
                adda.w  d0,a0
                move.w  (a0)+,(a1)
                move.w  (a0)+,d0
                move.w  (a0)+,d1
                move.l  (a0)+,d2
                move.w  (a0)+,ram_FF0406
                VDP_VSRAM_WRITE $0,(a1) ; VSRAM from offset 0
                movea.w d0,a0
                andi.w  #$FF00,d0
@loc_14AA:
                cmp.w   HvCounter,d0
                bcc.s   @loc_14AA ; wait until VCounter > d0
@loc_14B2:
                move.b  HvCounter + 1,d0
                bmi.s   @loc_14B2 ; wait until HCounter > 0
                move.w  a0,d0
@loc_14BC:
                cmp.w   HvCounter,d0
                bcc.s   @loc_14BC ; wait until HVCounter > a0

                move.l  d2,(a2)
; 36 nops
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                move.w  d1,(a1)
                cmpi.w  #$90,ram_FF0406
                bne.w   @loc_164C
; run this only if ram_FF0406 == $90
                move.w  #0,ram_FF0406
                tst.w   ram_MusicEnabled
                bne.w   @loc_162C
                tst.w   Race_ram_State
                beq.w   @loc_154E
                clr.l   d0
                move.w  #$1F,d1
                jsr     AudioFunc8
                jsr     AudioFunc11
                bra.w   @loc_162C
@loc_154E:
                lea     ram_FF1EAA,a1
                move.w  #0,d0
                tst.b   STRUCT_OFFSET_6E(a1)
                bpl.w   @loc_1590
                move.w  STRUCT_OFFSET_14(a1),d0
                muls.w  Race_ram_FrameCounter,d0
                add.w   STRUCT_OFFSET_SPEED(a1),d0
                bpl.w   @loc_1576
                move.w  #0,d0
@loc_1576:
                andi.l  #$FFFF,d0
                move.w  ram_FF1AA2,d1
                ext.l   d0
                swap    d0
                divu.w  d1,d0
                mulu.w  #$3800,d0
                clr.w   d0
                swap    d0
@loc_1590:
                add.w   ram_FF36C4,d0
                move.w  d0,ram_FF36B6
                lea     ram_FF1EAA,a1
                move.w  ram_FF36B6,d0
                sub.w   ram_FF36B8,d0
                move.w  d0,d1
                bpl.w   @loc_15B6
                neg.w   d1
@loc_15B6:
                cmp.w   #$64,d0
                ble.w   @loc_15C2
                move.w  #$64,d0
@loc_15C2:
                cmp.w   #$FF9C,d0
                bpl.w   @loc_15CE
                move.w  #$FF9C,d0
@loc_15CE:
                add.w   ram_FF36B8,d0
                move.w  d0,ram_FF36B8
                asr.w   #5,d1
                addi.w  #2,d1
                bpl.w   @loc_15E8
                move.w  #0,d1
@loc_15E8:
                tst.b   STRUCT_OFFSET_6E(a1)
                bmi.w   @loc_1616
                lea     ram_FF26AA,a1
                move.l  ram_FF1E68,d1
                sub.l   4(a1),d1
                bpl.w   @loc_1606
                neg.l   d1
@loc_1606:
                asl.l   #1,d1
                swap    d1
                cmp.w   #$1F,d1
                bmi.w   @loc_1616
                move.w  #$1F,d1
@loc_1616:
                jsr     AudioFunc8
                movea.l ram_FF1908,a1
                bsr.w   sub_1652
                jsr     AudioFunc11
@loc_162C:
                jsr     AudioFunc1
@loc_1632:
                move.w  #$FFFF,ram_FF369E
                tst.w   ram_FF0406
                ble.w   @loc_164C
                move.w  #0,ram_FF369E
@loc_164C:
                movem.l (sp)+,d0-d2/a0-a2
@return:
                rte
; End of function HorizontalInterrupt

; *************************************************
; Function sub_1652
; *************************************************

sub_1652:
                cmpa.l  #$FFFFFFFF,a1
                bne.w   @loc_1664
                moveq   #$1F,d1
                moveq   #0,d0
                bra.w   @return
@loc_1664:
                clr.w   d0
                tst.b   $6E(a1)
                bpl.w   @loc_169C
                move.w  $14(a1),d0
                muls.w  Race_ram_FrameCounter,d0
                add.w   $12(a1),d0
                bpl.w   @loc_1682
                clr.w   d0

@loc_1682:
                andi.l  #$FFFF,d0
                move.w  ram_FF1AA4,d1
                ext.l   d0
                swap    d0
                divu.w  d1,d0
                mulu.w  #$3800,d0
                clr.w   d0
                swap    d0

@loc_169C:
                addi.w  #$400,d0
                move.w  d0,ram_FF36BE
                move.w  ram_FF36BE,d0
                cmp.w   #$400,d0
                bpl.w   @loc_16B8
                move.w  #$400,d0

@loc_16B8:
                sub.w   ram_FF36C0,d0
                cmp.w   #$64,d0
                ble.w   @loc_16CA
                move.w  #$64,d0

@loc_16CA:
                cmp.w   #$FF9C,d0
                bpl.w   @loc_16D6
                move.w  #$FF9C,d0

@loc_16D6:
                add.w   ram_FF36C0,d0
                move.w  d0,ram_FF36C0
                move.l  ram_FF1E68,d1
                sub.l   4(a1),d1
                bpl.w   @loc_16F2
                neg.l   d1
@loc_16F2:
                asl.l   #1,d1
                swap    d1
                cmp.w   #$1F,d1
                bmi.w   @return
                move.w  #$1F,d1
@return:
                rts
; End of function sub_1652

    include "intro.asm"
    include "menu_password.asm"
    include "menu_main.asm"
    include "message.asm"
    include "sub_5760.asm"
    include "character.asm"
    include "race_results.asm"
    include "highscore.asm"
    include "shop.asm"
    include "endlevel.asm"
    include "8FB4.asm"
    include "98C2.asm"
    include "uncompress.asm"
    include "9FE4.asm"
    include "race.asm"
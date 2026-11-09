VdpCtrl     equ $C00004  ; VDP control port
VdpData     equ $C00000  ; VDP data port
HvCounter   equ $C00008  ; H/V counter

VDP_VRAM_READ macro addr,dest
    move.l #$00000000+((addr & $3FFF)<<16)+((addr & $C000)>>14),dest
    endm

VDP_VRAM_WRITE macro addr,dest
    move.l #$40000000+((addr & $3FFF)<<16)+((addr & $C000)>>14),dest
    endm

VDP_CRAM_READ macro ram,dest
    move.l #$00000020+(ram<<16),dest
    endm

VDP_CRAM_WRITE macro ram,dest
    move.l #$C0000000+(ram<<16),dest
    endm

VDP_VSRAM_READ macro ram,dest
    move.l #$00000010+(ram<<16),dest
    endm

VDP_VSRAM_WRITE macro ram,dest
    move.l #$40000010+(ram<<16),dest
    endm

VdpCtrl     equ $C00004  ; VDP control port
VdpData     equ $C00000  ; VDP data port
HvCounter   equ $C00008  ; H/V counter

VDP_VRAM_READ macro
    move.l #$00000000+((\1 & $3FFF)<<16)+((\1 & $C000)>>14),\2
    endm

VDP_VRAM_WRITE macro
    move.l #$40000000+((\1 & $3FFF)<<16)+((\1 & $C000)>>14),\2
    endm

VDP_CRAM_READ macro
    move.l #$00000020+(\1<<16),\2
    endm

VDP_CRAM_WRITE macro
    move.l #$C0000000+(\1<<16),\2
    endm

VDP_VSRAM_READ macro
    move.l #$00000010+(\1<<16),\2
    endm

VDP_VSRAM_WRITE macro
    move.l #$40000010+(\1<<16),\2
    endm
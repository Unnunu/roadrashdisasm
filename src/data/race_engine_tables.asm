; *************************************************
; race_engine_tables.asm - physics/engine tables from the ROM gap
; ROM range: $257D0-$25855 (audio timing tables included as data); included from main.asm.
; *************************************************

; unk_257D0: 9 words copied to ram_FF1AB6 by Race_InitPhysicsConstants.
unk_257D0:
    dc.w    $0100,$0600,$0E00,$0A00,$1100,$0A00,$0A00,$1000
    dc.w    $1000

; unk_257E2/E8/EE: engine timing tables used by Audio_UpdateEngineState.
unk_257E2:
    dc.w    $1E00,$1500,$1500

unk_257E8:
    dc.w    $1E00,$0C00,$0E00

unk_257EE:
    dc.w    $1E00,$1100,$0A00,$0020,$0080,$0100,$0300,$000F,$0044,$0100

; unk_25802/2580A: 2 longs each copied to ram_FFD330/ram_FFD338.
unk_25802:
    dc.l    $001F0044,$009301BB

unk_2580A:
    dc.l    $0004000D,$00200224

unk_25812:
    dc.w    $0020,$6000,$0020,$6000,$0020,$6000,$0020,$6000
    dc.w    $0020,$6000,$0020,$6000,$0020,$6000,$0020,$6000
    dc.w    $0020,$6000,$0020,$6000,$0020,$6000,$0020,$6000
    dc.w    $0020,$6000,$0020,$6000,$0020,$6000,$0020,$6000
    dc.w    $0060,$0080

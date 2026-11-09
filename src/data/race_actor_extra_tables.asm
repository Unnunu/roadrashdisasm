; *************************************************
; race_actor_extra_tables.asm - actor/AI tables from the ROM gap
; ROM range: $259B6-$25EBF; included from main.asm after race_actor_tables.asm.
; *************************************************

; Target labels for the actor action dispatch table (code/data).
ActorActionSlot_12D16 equ $12D16
ActorActionSlot_12D2A equ $12D2A
ActorActionSlot_12D3A equ $12D3A
ActorActionSlot_12D4E equ $12D4E
ActorActionSlot_12D62 equ $12D62
ActorActionSlot_12D76 equ $12D76
ActorActionSlot_12D8A equ $12D8A
ActorActionSlot_12D9E equ $12D9E
ActorActionSlot_12DB2 equ $12DB2
ActorActionSlot_12DC6 equ $12DC6
ActorActionSlot_12DDA equ $12DDA
ActorActionSlot_12DEE equ $12DEE
ActorActionSlot_12E02 equ $12E02
ActorActionSlot_12E16 equ $12E16
ActorActionSlot_12E2A equ $12E2A
ActorActionSlot_12E3E equ $12E3E
ActorActionSlot_12E52 equ $12E52
ActorActionSlot_12E66 equ $12E66
ActorActionSlot_12E7A equ $12E7A
ActorActionSlot_12E8E equ $12E8E
; Common handler called by unk_25A44 entries (undiscovered code).
ActorAI_Handler_13130 equ $13130

; unk_259B6: $A bytes used by race_core.asm.
unk_259B6:
    dc.w    $0002,$0003,$0003,$0003,$0004

unk_259C0:
    dc.l    ActorActionSlot_12D2A
    dc.l    ActorActionSlot_12D16
    dc.l    ActorActionSlot_12D3A
    dc.l    ActorActionSlot_12D4E
    dc.l    ActorActionSlot_12D62
    dc.l    ActorActionSlot_12D76
    dc.l    ActorActionSlot_12D8A
    dc.l    ActorActionSlot_12D9E
    dc.l    ActorActionSlot_12DB2
    dc.l    ActorActionSlot_12DC6
    dc.l    ActorActionSlot_12DDA
    dc.l    ActorActionSlot_12DEE
    dc.l    ActorActionSlot_12E02
    dc.l    ActorActionSlot_12E16
    dc.l    ActorActionSlot_12E2A
    dc.l    ActorActionSlot_12E3E
    dc.l    ActorActionSlot_12E52
    dc.l    ActorActionSlot_12E66
    dc.l    ActorActionSlot_12E7A
    dc.l    ActorActionSlot_12E8E

; unk_25A10: 13-pointer actor-data table (Race_UpdateNearestTarget and AI).
unk_25A10:
    dc.l    ram_FF1A70
    dc.l    ActorBikeRecord_18
    dc.l    ActorBikeRecord_0
    dc.l    ActorBikeRecord_1
    dc.l    ActorBikeRecord_3
    dc.l    ActorBikeRecord_5
    dc.l    ActorBikeRecord_7
    dc.l    ActorBikeRecord_9
    dc.l    ActorBikeRecord_11
    dc.l    ActorBikeRecord_13
    dc.l    ActorBikeRecord_15
    dc.l    ActorBikeRecord_19
    dc.l    ActorBikeRecord_17

unk_25A44:
    dc.l    ActorAI_Handler_13130
    dc.w    $1770,$0008
    dc.l    ActorAI_Handler_13130
    dc.w    $1B58,$0010
    dc.l    ActorAI_Handler_13130
    dc.w    $1964,$000C
    dc.l    ActorAI_Handler_13130
    dc.w    $1770,$FFF8
    dc.l    ActorAI_Handler_13130
    dc.w    $1B58,$FFEF
    dc.l    ActorAI_Handler_13130
    dc.w    $1770,$0008
    dc.l    ActorAI_Handler_13130
    dc.w    $1B58,$0010
    dc.l    ActorAI_Handler_13130
    dc.w    $1964,$000C
    dc.l    ActorAI_Handler_13130
    dc.w    $1770,$FFF8
    dc.l    ActorAI_Handler_13130
    dc.w    $1964,$FFEF
    dc.l    ActorAI_Handler_13130
    dc.w    $1770,$0008
    dc.l    ActorAI_Handler_13130
    dc.w    $1B58,$0010
    dc.l    ActorAI_Handler_13130
    dc.w    $1964,$000C
    dc.l    ActorAI_Handler_13130
    dc.w    $1770,$FFF8
    dc.l    ActorAI_Handler_13130
    dc.w    $1B58,$FFEF
    dc.l    ActorAI_Handler_13130
    dc.w    $1770,$FFEF

unk_25AC4:
    dc.w    $01D0,$8000,$0018,$0030,$0600,$00C0,$0100,$0000
    dc.w    $01F0,$8000,$0013,$002A,$0800,$00D0,$0100,$0000
    dc.w    $0200,$8000,$0013,$002A,$0A00,$00D0,$0100,$0000
    dc.w    $0220,$8000,$000C,$0022,$0C00,$00F0,$0100,$0000
    dc.w    $0240,$8000,$0009,$0018,$0C00,$0100,$0100,$0000
    dc.w    $0200,$8000,$0013,$002B,$0A00,$00E0,$0100,$0000
    dc.w    $01F0,$8000,$0013,$002B,$0A00,$00E0,$0100,$0000
    dc.w    $01E0,$8000,$0016,$0030,$0A00,$00D0,$0100,$0000
    dc.w    $0020,$0018,$0010,$000C,$000A,$0008

unk_25B50:
    dc.l    ActorBikeRecord_2
    dc.l    ActorBikeRecord_4
    dc.l    ActorBikeRecord_6
    dc.l    ActorBikeRecord_8
    dc.l    ActorBikeRecord_10
    dc.l    ActorBikeRecord_12
    dc.l    ActorBikeRecord_14
    dc.l    ActorBikeRecord_16

unk_25B70: ; 8 bike palette/limit words
    dc.w    $0400,$0380,$0300,$0300,$0200,$0280,$0300,$0200

; actor/bike record 0 ($26 bytes)
ActorBikeRecord_0: ; $025B80
    dc.w    $0005,$0027,$001F,$001A,$0016,$0014,$0014,$0BB8
    dc.w    $1388,$1770,$1B58,$251C,$2C88,$0000,$0FA0,$157C
    dc.w    $1964,$1F40,$2710

; actor/bike record 1 ($26 bytes)
ActorBikeRecord_1: ; $025BA6
    dc.w    $0005,$0028,$0023,$001E,$0019,$0014,$0014,$125C
    dc.w    $1838,$1E78,$23F0,$28A0,$2DB4,$0000,$1518,$1BBC
    dc.w    $20D0,$25E4,$2A30

; actor/bike record 2 ($26 bytes)
ActorBikeRecord_2: ; $025BCC
    dc.w    $0005,$0022,$001A,$0015,$0012,$0010,$000E,$125C
    dc.w    $1838,$1E78,$23F0,$28A0,$2EE0,$0000,$1518,$1BBC
    dc.w    $20D0,$25E4,$2A30

; actor/bike record 3 ($26 bytes)
ActorBikeRecord_3: ; $025BF2
    dc.w    $0005,$0023,$001B,$0016,$0013,$0014,$0014,$13EC
    dc.w    $1A90,$2134,$2710,$2C24,$300C,$0000,$170C,$1E14
    dc.w    $238C,$2904,$2AF8

; actor/bike record 4 ($26 bytes)
ActorBikeRecord_4: ; $025C18
    dc.w    $0005,$0023,$001B,$0016,$0013,$0011,$000F,$13EC
    dc.w    $1A90,$2134,$2710,$2C24,$319C,$0000,$170C,$1E14
    dc.w    $238C,$2904,$2DB4

; actor/bike record 5 ($26 bytes)
ActorBikeRecord_5: ; $025C3E
    dc.w    $0005,$0024,$001C,$0017,$0014,$0014,$0014,$157C
    dc.w    $1C84,$238C,$2710,$2CEC,$3264,$0000,$189C,$206C
    dc.w    $251C,$2AF8,$2EE0

; actor/bike record 6 ($26 bytes)
ActorBikeRecord_6: ; $025C64
    dc.w    $0005,$0024,$001C,$0017,$0014,$0012,$0010,$157C
    dc.w    $1C84,$238C,$2A30,$2FA8,$332C,$0000,$189C,$206C
    dc.w    $2648,$2C24,$3138

; actor/bike record 7 ($26 bytes)
ActorBikeRecord_7: ; $025C8A
    dc.w    $0005,$0025,$001D,$0018,$0015,$0014,$0019,$157C
    dc.w    $1C84,$238C,$2A30,$2FA8,$33F4,$0000,$189C,$206C
    dc.w    $2648,$2C24,$3138

; actor/bike record 8 ($26 bytes)
ActorBikeRecord_8: ; $025CB0
    dc.w    $0005,$0025,$001D,$0018,$0015,$0013,$0011,$157C
    dc.w    $1C84,$238C,$2A30,$2FA8,$34BC,$0000,$189C,$206C
    dc.w    $2648,$2C24,$3138

; actor/bike record 9 ($26 bytes)
ActorBikeRecord_9: ; $025CD6
    dc.w    $0005,$0026,$001E,$0019,$0016,$0019,$0019,$16A8
    dc.w    $1E78,$2648,$2CEC,$332C,$37DC,$0000,$1A90,$2260
    dc.w    $2904,$2FA8,$34BC

; actor/bike record 10 ($26 bytes)
ActorBikeRecord_10: ; $025CFC
    dc.w    $0005,$0026,$001E,$0019,$0016,$0014,$0012,$16A8
    dc.w    $1E78,$2648,$2CEC,$332C,$38A4,$0000,$1A90,$2260
    dc.w    $2904,$2FA8,$34BC

; actor/bike record 11 ($26 bytes)
ActorBikeRecord_11: ; $025D22
    dc.w    $0005,$0027,$001F,$001A,$0017,$0016,$0019,$157C
    dc.w    $1C84,$238C,$2A30,$2FA8,$35E8,$0000,$189C,$206C
    dc.w    $2648,$2C24,$32C8

; actor/bike record 12 ($26 bytes)
ActorBikeRecord_12: ; $025D48
    dc.w    $0005,$0027,$001F,$001A,$0017,$0015,$0013,$157C
    dc.w    $1C84,$238C,$2A30,$2FA8,$36B0,$0000,$189C,$206C
    dc.w    $2648,$2C24,$3138

; actor/bike record 13 ($26 bytes)
ActorBikeRecord_13: ; $025D6E
    dc.w    $0005,$0028,$0020,$001B,$0018,$0014,$0019,$1644
    dc.w    $1D4C,$24B8,$2BC0,$32C8,$3778,$0000,$1964,$2198
    dc.w    $2774,$2EE0,$34BC

; actor/bike record 14 ($26 bytes)
ActorBikeRecord_14: ; $025D94
    dc.w    $0005,$0028,$0020,$001B,$0018,$0016,$0014,$1644
    dc.w    $1D4C,$24B8,$2BC0,$3138,$38A4,$0000,$1964,$2198
    dc.w    $2774,$2DB4,$332C

; actor/bike record 15 ($26 bytes)
ActorBikeRecord_15: ; $025DBA
    dc.w    $0005,$0029,$0021,$001C,$0019,$0014,$0019,$16A8
    dc.w    $1E78,$2648,$2CEC,$332C,$39D0,$0000,$1A90,$2260
    dc.w    $2904,$2FA8,$34BC

; actor/bike record 16 ($26 bytes)
ActorBikeRecord_16: ; $025DE0
    dc.w    $0005,$0029,$0021,$001C,$0019,$0017,$0015,$16A8
    dc.w    $1E78,$2648,$2CEC,$332C,$3A98,$0000,$1A90,$2260
    dc.w    $2904,$2FA8,$35E8

; actor/bike record 17 ($26 bytes)
ActorBikeRecord_17: ; $025E06
    dc.w    $0005,$0025,$001D,$0018,$0015,$0014,$0011,$1A90
    dc.w    $2260,$2A30,$30D4,$3714,$3D54,$0000,$161D,$1B58
    dc.w    $2676,$2B44,$3013

; actor/bike record 18 ($26 bytes)
ActorBikeRecord_18: ; $025E2C
    dc.w    $0005,$0020,$0018,$0013,$0010,$000E,$000C,$0BB8
    dc.w    $0FA0,$1388,$1B58,$1F40,$2328,$0000,$0DAC,$1194
    dc.w    $1964,$1D4C,$2134

; actor/bike record 19 ($26 bytes)
ActorBikeRecord_19: ; $025E52
    dc.w    $0005,$0025,$001D,$0018,$0015,$0014,$0011,$1A90
    dc.w    $2260,$2A30,$30D4,$3714,$3D54,$0000,$1E78,$2648
    dc.w    $2CEC,$332C,$396C

unk_25E78: ; $025E78
    dc.w    $0001,$0002,$0003,$0004,$0002,$0004,$0006,$0008
    dc.w    $0003,$0006,$0009,$000C,$0004,$0008,$000C,$0010
    dc.w    $0042,$00CE,$0064,$00CE,$0086,$00CE,$00A8,$00CE
    dc.w    $00CA,$00CE,$0242,$0000,$0464,$0000,$0486,$0000
    dc.w    $04A8,$0000,$04CA,$0000

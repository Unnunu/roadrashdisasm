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
    dc.l    $00FF1A70,$00025E2C,$00025B80,$00025BA6
    dc.l    $00025BF2,$00025C3E,$00025C8A,$00025CD6
    dc.l    $00025D22,$00025D6E,$00025DBA,$00025E52
    dc.l    $00025E06

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
    dc.w    $0002,$5BCC,$0002,$5C18,$0002,$5C64,$0002,$5CB0
    dc.w    $0002,$5CFC,$0002,$5D48,$0002,$5D94,$0002,$5DE0

unk_25B70:
    dc.w    $0400,$0380,$0300,$0300,$0200,$0280,$0300,$0200
    dc.w    $0005,$0027,$001F,$001A,$0016,$0014,$0014,$0BB8
    dc.w    $1388,$1770,$1B58,$251C,$2C88,$0000,$0FA0,$157C
    dc.w    $1964,$1F40,$2710,$0005,$0028,$0023,$001E,$0019
    dc.w    $0014,$0014,$125C,$1838,$1E78,$23F0,$28A0,$2DB4
    dc.w    $0000,$1518,$1BBC,$20D0,$25E4,$2A30,$0005,$0022
    dc.w    $001A,$0015,$0012,$0010,$000E,$125C,$1838,$1E78
    dc.w    $23F0,$28A0,$2EE0,$0000,$1518,$1BBC,$20D0,$25E4
    dc.w    $2A30,$0005,$0023,$001B,$0016,$0013,$0014,$0014
    dc.w    $13EC,$1A90,$2134,$2710,$2C24,$300C,$0000,$170C
    dc.w    $1E14,$238C,$2904,$2AF8,$0005,$0023,$001B,$0016
    dc.w    $0013,$0011,$000F,$13EC,$1A90,$2134,$2710,$2C24
    dc.w    $319C,$0000,$170C,$1E14,$238C,$2904,$2DB4,$0005
    dc.w    $0024,$001C,$0017,$0014,$0014,$0014,$157C,$1C84
    dc.w    $238C,$2710,$2CEC,$3264,$0000,$189C,$206C,$251C
    dc.w    $2AF8,$2EE0,$0005,$0024,$001C,$0017,$0014,$0012
    dc.w    $0010,$157C,$1C84,$238C,$2A30,$2FA8,$332C,$0000
    dc.w    $189C,$206C,$2648,$2C24,$3138,$0005,$0025,$001D
    dc.w    $0018,$0015,$0014,$0019,$157C,$1C84,$238C,$2A30
    dc.w    $2FA8,$33F4,$0000,$189C,$206C,$2648,$2C24,$3138
    dc.w    $0005,$0025,$001D,$0018,$0015,$0013,$0011,$157C
    dc.w    $1C84,$238C,$2A30,$2FA8,$34BC,$0000,$189C,$206C
    dc.w    $2648,$2C24,$3138,$0005,$0026,$001E,$0019,$0016
    dc.w    $0019,$0019,$16A8,$1E78,$2648,$2CEC,$332C,$37DC
    dc.w    $0000,$1A90,$2260,$2904,$2FA8,$34BC,$0005,$0026
    dc.w    $001E,$0019,$0016,$0014,$0012,$16A8,$1E78,$2648
    dc.w    $2CEC,$332C,$38A4,$0000,$1A90,$2260,$2904,$2FA8
    dc.w    $34BC,$0005,$0027,$001F,$001A,$0017,$0016,$0019
    dc.w    $157C,$1C84,$238C,$2A30,$2FA8,$35E8,$0000,$189C
    dc.w    $206C,$2648,$2C24,$32C8,$0005,$0027,$001F,$001A
    dc.w    $0017,$0015,$0013,$157C,$1C84,$238C,$2A30,$2FA8
    dc.w    $36B0,$0000,$189C,$206C,$2648,$2C24,$3138,$0005
    dc.w    $0028,$0020,$001B,$0018,$0014,$0019,$1644,$1D4C
    dc.w    $24B8,$2BC0,$32C8,$3778,$0000,$1964,$2198,$2774
    dc.w    $2EE0,$34BC,$0005,$0028,$0020,$001B,$0018,$0016
    dc.w    $0014,$1644,$1D4C,$24B8,$2BC0,$3138,$38A4,$0000
    dc.w    $1964,$2198,$2774,$2DB4,$332C,$0005,$0029,$0021
    dc.w    $001C,$0019,$0014,$0019,$16A8,$1E78,$2648,$2CEC
    dc.w    $332C,$39D0,$0000,$1A90,$2260,$2904,$2FA8,$34BC
    dc.w    $0005,$0029,$0021,$001C,$0019,$0017,$0015,$16A8
    dc.w    $1E78,$2648,$2CEC,$332C,$3A98,$0000,$1A90,$2260
    dc.w    $2904,$2FA8,$35E8,$0005,$0025,$001D,$0018,$0015
    dc.w    $0014,$0011,$1A90,$2260,$2A30,$30D4,$3714,$3D54
    dc.w    $0000,$161D,$1B58,$2676,$2B44,$3013,$0005,$0020
    dc.w    $0018,$0013,$0010,$000E,$000C,$0BB8,$0FA0,$1388
    dc.w    $1B58,$1F40,$2328,$0000,$0DAC,$1194,$1964,$1D4C
    dc.w    $2134,$0005,$0025,$001D,$0018,$0015,$0014,$0011
    dc.w    $1A90,$2260,$2A30,$30D4,$3714,$3D54,$0000,$1E78
    dc.w    $2648,$2CEC,$332C,$396C,$0001,$0002,$0003,$0004
    dc.w    $0002,$0004,$0006,$0008,$0003,$0006,$0009,$000C
    dc.w    $0004,$0008,$000C,$0010,$0042,$00CE,$0064,$00CE
    dc.w    $0086,$00CE,$00A8,$00CE,$00CA,$00CE,$0242,$0000
    dc.w    $0464,$0000,$0486,$0000,$04A8,$0000,$04CA,$0000

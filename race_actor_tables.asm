; *************************************************
; race_actor_tables.asm - actor pointer/graphics tables from the ROM gap
; ROM range: $25856-$259B5; included from main.asm
; *************************************************

; Race_ActorList: player A + 15 opponents (actor structs $80 each)
Race_ActorList:
    dc.l    $00FF1EAA
    dc.l    $00FF1F2A
Race_ActorListMid: ; $2585E (sub-list used by Race_InitActorLists)
    dc.l    $00FF1FAA
    dc.l    $00FF202A
    dc.l    $00FF20AA
    dc.l    $00FF212A
    dc.l    $00FF21AA
    dc.l    $00FF222A
    dc.l    $00FF22AA
    dc.l    $00FF232A
    dc.l    $00FF23AA
    dc.l    $00FF242A
    dc.l    $00FF24AA
    dc.l    $00FF252A
    dc.l    $00FF25AA
    dc.l    $00FF262A
    dc.l    $FFFFFFFF

; Race_StaticActorList: $FF2EAA/$FF2F2A (type $10)
Race_StaticActorList:
    dc.l    $00FF2EAA
    dc.l    $00FF2F2A
    dc.l    $FFFFFFFF

; unknown gap data between the static list and the graphics table
unk_258A6:
    dc.b    $00,$FF,$2F,$AA,$FF,$FF,$FF,$FF
unk_258AE:
    dc.b    $00,$FF,$26,$AA,$00,$FF,$27,$2A,$00,$FF,$2B,$2A,$00,$FF,$28,$2A
    dc.b    $00,$FF,$28,$AA,$00,$FF,$29,$2A,$00,$FF,$29,$AA,$00,$FF,$2A,$2A
    dc.b    $00,$FF,$2A,$AA,$00,$FF,$27,$AA,$00,$FF,$2B,$AA,$00,$FF,$2C,$2A
    dc.b    $00,$FF,$2C,$AA,$00,$FF,$2D,$2A,$00,$FF,$2D,$AA,$00,$FF,$2E,$2A

; Race_ActorGraphicsTable: 10 pointers to the 16-byte graphics records
Race_ActorGraphicsTable:
    dc.l    $00025916
    dc.l    $00025926
    dc.l    $00025936
    dc.l    $00025946
    dc.l    $00025956
    dc.l    $00025966
    dc.l    $00025976
    dc.l    $00025986
    dc.l    $00025996
    dc.l    $000259A6

; graphics records (16 bytes each; +$A/+$C/+$E are copied into the actor)
Race_ActorGraphics_0:
    dc.b    $00,$0C,$40,$00,$1B,$58,$00,$04,$00,$C8,$01,$00,$00,$80,$05,$00
Race_ActorGraphics_1:
    dc.b    $00,$0A,$40,$00,$1D,$4C,$00,$05,$00,$B4,$01,$80,$00,$A0,$06,$40
Race_ActorGraphics_2:
    dc.b    $00,$08,$40,$00,$1F,$40,$00,$06,$00,$78,$02,$00,$00,$C0,$07,$80
Race_ActorGraphics_3:
    dc.b    $00,$06,$40,$00,$21,$34,$00,$08,$00,$5A,$02,$80,$01,$00,$08,$C0
Race_ActorGraphics_4:
    dc.b    $00,$04,$40,$00,$23,$28,$00,$0A,$00,$3C,$03,$00,$01,$00,$0A,$00
Race_ActorGraphics_5:
    dc.b    $00,$20,$78,$00,$00,$00,$00,$10,$00,$00,$00,$00,$00,$00,$0A,$00
Race_ActorGraphics_6:
    dc.b    $00,$20,$78,$00,$00,$00,$00,$18,$00,$00,$00,$00,$00,$00,$0A,$00
Race_ActorGraphics_7:
    dc.b    $00,$20,$78,$00,$00,$00,$00,$20,$00,$00,$00,$00,$00,$00,$0A,$00
Race_ActorGraphics_8:
    dc.b    $00,$20,$78,$00,$00,$00,$00,$30,$00,$00,$00,$00,$00,$00,$0A,$00
Race_ActorGraphics_9:
    dc.b    $00,$20,$78,$00,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$0A,$00

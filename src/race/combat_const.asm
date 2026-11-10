; *************************************************
; combat_const.asm - combat/weapon state values and confirmed bit masks
; WEAPON_NONE is the unarmed fist/kick state; WEAPON_CLUB is the armed
; club state selected by actor definition byte2 bit7 (`$6B` bit1).
; *************************************************

WEAPON_NONE equ 0
WEAPON_CLUB equ 1

; actor $69 attack/state bits
ATTACK_ACTIVE equ $10
ATTACK_SIDE equ $20
ATTACK_LOW equ $40
ATTACK_CONTACT equ $80

; actor $6B attack bits
ATTACK_HIGH equ $01
ATTACK_ARMED equ $02

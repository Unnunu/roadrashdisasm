; *************************************************
; race_misc_data.asm - tables/scripts between the road shapes and top_level
; ROM range: $7DCA8-$7E6A1; included from main.asm.
; *************************************************

; unk_7DCA8: 16-bit lookup table (sine-like) used by race_ai sub_112C8.
unk_7DCA8:
    binclude "baserom.md",$7DCA8,$0202

; unk_7DEAA: HUD speed/RPM needle animation script (tilemap + frame table).
unk_7DEAA:
    binclude "baserom.md",$7DEAA,$04C6

; Shop_BikePalettes: 8 bike palettes x 32 bytes.
Shop_BikePalettes:
    binclude "baserom.md",$7E370,$0100

; unk_7E470: actor palettes, 16 x 32 bytes (Race_LoadActorPalette).
unk_7E470:
    binclude "baserom.md",$7E470,$0200

; unk_7E670: 5 track-image pointers used by race_results.
unk_7E670:
    binclude "baserom.md",$7E670,$0014

; unk_7E684/68E/698: per-track 5-word image/nametable/palette offsets (race_results).
unk_7E684:
    binclude "baserom.md",$7E684,$000A
unk_7E68E:
    binclude "baserom.md",$7E68E,$000A
unk_7E698:
    binclude "baserom.md",$7E698,$000A

; *************************************************
; rider_intro_quotes.asm - rider intro quote records from the ROM gap
; ROM range: $16E70-$19A11; included from main.asm before race_data_tables.asm.
;
; Each quote record: y (word), x, height, width, then height*width text bytes
; (fixed-size, space-padded), consumed by EncodeString + WriteNametableToBuffer.
; RiderIntro_RecordTable references 85 unique quote headers; the 8-byte header
; fields are passed as (a0)=y, 2(a0)=x, 4(a0)=height, 6(a0)=width. The tail
; bytes after the last referenced quote are kept raw.
; *************************************************

RiderIntro_QuoteData:
    binclude "baserom.md",$16E70,$2BA2

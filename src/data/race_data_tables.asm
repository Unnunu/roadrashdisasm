; *************************************************
; race_data_tables.asm - race/intro/results tables from the ROM gap
; ROM range: $19A12-$19F61 (non-audio data); included from main.asm.
; *************************************************

; RiderIntro_RecordTable: [level][track][variant] records of (quote_ptr, image_ptr)
; 5 levels x 10 tracks x 2 variants x 8 bytes = $320.
RiderIntro_RecordTable:
    dc.l    RaceQuote_16E70,RiderIntro_Portrait_0,RaceQuote_18548,RiderIntro_Portrait_6
    dc.l    RaceQuote_188B0,RiderIntro_Portrait_7,RaceQuote_1744C,RiderIntro_Portrait_0
    dc.l    RaceQuote_16EC4,RiderIntro_Portrait_0,RaceQuote_178A4,RiderIntro_Portrait_1
    dc.l    RaceQuote_1859C,RiderIntro_Portrait_6,RaceQuote_17494,RiderIntro_Portrait_0
    dc.l    RaceQuote_16F08,RiderIntro_Portrait_0,RaceQuote_185DE,RiderIntro_Portrait_6
    dc.l    RaceQuote_188FA,RiderIntro_Portrait_7,RaceQuote_1744C,RiderIntro_Portrait_0
    dc.l    RaceQuote_16F52,RiderIntro_Portrait_0,RaceQuote_178E8,RiderIntro_Portrait_1
    dc.l    RaceQuote_1893E,RiderIntro_Portrait_7,RaceQuote_17494,RiderIntro_Portrait_0
    dc.l    RaceQuote_17B32,RiderIntro_Portrait_2,RaceQuote_1862A,RiderIntro_Portrait_6
    dc.l    RaceQuote_18982,RiderIntro_Portrait_7,RaceQuote_17B32,RiderIntro_Portrait_2
    dc.l    RaceQuote_16F9A,RiderIntro_Portrait_0,RaceQuote_17B8A,RiderIntro_Portrait_2
    dc.l    RaceQuote_18DC8,RiderIntro_Portrait_8,RaceQuote_174D2,RiderIntro_Portrait_0
    dc.l    RaceQuote_17940,RiderIntro_Portrait_1,RaceQuote_18674,RiderIntro_Portrait_6
    dc.l    RaceQuote_189DE,RiderIntro_Portrait_7,RaceQuote_17940,RiderIntro_Portrait_1
    dc.l    RaceQuote_16FF2,RiderIntro_Portrait_0,RaceQuote_17BEA,RiderIntro_Portrait_2
    dc.l    RaceQuote_18A26,RiderIntro_Portrait_7,RaceQuote_174D2,RiderIntro_Portrait_0
    dc.l    RaceQuote_1704E,RiderIntro_Portrait_0,RaceQuote_18A7E,RiderIntro_Portrait_7
    dc.l    RaceQuote_18E20,RiderIntro_Portrait_8,RaceQuote_17516,RiderIntro_Portrait_0
    dc.l    RaceQuote_17098,RiderIntro_Portrait_0,RaceQuote_186B8,RiderIntro_Portrait_6
    dc.l    RaceQuote_18AC6,RiderIntro_Portrait_7,RaceQuote_17516,RiderIntro_Portrait_0
    dc.l    RaceQuote_170DA,RiderIntro_Portrait_0,RaceQuote_18B0A,RiderIntro_Portrait_7
    dc.l    RaceQuote_18E5E,RiderIntro_Portrait_8,RaceQuote_1756E,RiderIntro_Portrait_0
    dc.l    RaceQuote_17118,RiderIntro_Portrait_0,RaceQuote_18B62,RiderIntro_Portrait_7
    dc.l    RaceQuote_19178,RiderIntro_Portrait_9,RaceQuote_175B2,RiderIntro_Portrait_0
    dc.l    RaceQuote_17C34,RiderIntro_Portrait_2,RaceQuote_18EA0,RiderIntro_Portrait_8
    dc.l    RaceQuote_191C0,RiderIntro_Portrait_9,RaceQuote_17C34,RiderIntro_Portrait_2
    dc.l    RaceQuote_17154,RiderIntro_Portrait_0,RaceQuote_17E02,RiderIntro_Portrait_3
    dc.l    RaceQuote_18BAE,RiderIntro_Portrait_7,RaceQuote_175B2,RiderIntro_Portrait_0
    dc.l    RaceQuote_17198,RiderIntro_Portrait_0,RaceQuote_17E46,RiderIntro_Portrait_3
    dc.l    RaceQuote_18EF8,RiderIntro_Portrait_8,RaceQuote_1756E,RiderIntro_Portrait_0
    dc.l    RaceQuote_171FA,RiderIntro_Portrait_0,RaceQuote_180AE,RiderIntro_Portrait_4
    dc.l    RaceQuote_191FC,RiderIntro_Portrait_9,RaceQuote_1761E,RiderIntro_Portrait_0
    dc.l    RaceQuote_1724E,RiderIntro_Portrait_0,RaceQuote_18F42,RiderIntro_Portrait_8
    dc.l    RaceQuote_1923E,RiderIntro_Portrait_9,RaceQuote_17648,RiderIntro_Portrait_0
    dc.l    RaceQuote_17292,RiderIntro_Portrait_0,RaceQuote_1810E,RiderIntro_Portrait_4
    dc.l    RaceQuote_1927C,RiderIntro_Portrait_9,RaceQuote_1761E,RiderIntro_Portrait_0
    dc.l    RaceQuote_17E88,RiderIntro_Portrait_3,RaceQuote_18F80,RiderIntro_Portrait_8
    dc.l    RaceQuote_1968A,RiderIntro_Portrait_10,RaceQuote_17E88,RiderIntro_Portrait_3
    dc.l    RaceQuote_172D0,RiderIntro_Portrait_0,RaceQuote_192BA,RiderIntro_Portrait_9
    dc.l    RaceQuote_196DE,RiderIntro_Portrait_10,RaceQuote_1761E,RiderIntro_Portrait_0
    dc.l    RaceQuote_18302,RiderIntro_Portrait_5,RaceQuote_1930E,RiderIntro_Portrait_9
    dc.l    RaceQuote_19720,RiderIntro_Portrait_10,RaceQuote_18302,RiderIntro_Portrait_5
    dc.l    RaceQuote_1731E,RiderIntro_Portrait_0,RaceQuote_1816A,RiderIntro_Portrait_4
    dc.l    RaceQuote_1936A,RiderIntro_Portrait_9,RaceQuote_176DE,RiderIntro_Portrait_0
    dc.l    RaceQuote_1737E,RiderIntro_Portrait_0,RaceQuote_193B2,RiderIntro_Portrait_9
    dc.l    RaceQuote_19768,RiderIntro_Portrait_10,RaceQuote_1768A,RiderIntro_Portrait_0
    dc.l    RaceQuote_173C2,RiderIntro_Portrait_0,RaceQuote_193FA,RiderIntro_Portrait_9
    dc.l    RaceQuote_197AC,RiderIntro_Portrait_10,RaceQuote_176DE,RiderIntro_Portrait_0
    dc.l    RaceQuote_1741E,RiderIntro_Portrait_0,RaceQuote_18346,RiderIntro_Portrait_5
    dc.l    RaceQuote_19804,RiderIntro_Portrait_10,RaceQuote_1768A,RiderIntro_Portrait_0

; RaceResults_LevelTablePos: 5 levels x 4 variants; 8-byte records (negative money: 5x2)
RaceResults_LevelTablePos:
    dc.l    RaceQuote_18710,RiderIntro_Portrait_6,RaceQuote_18754,RiderIntro_Portrait_6
    dc.l    RaceQuote_18BDC,RiderIntro_Portrait_7,RaceQuote_18C24,RiderIntro_Portrait_7
    dc.l    RaceQuote_1879C,RiderIntro_Portrait_6,RaceQuote_18C66,RiderIntro_Portrait_7
    dc.l    RaceQuote_18C96,RiderIntro_Portrait_7,RaceQuote_18FD8,RiderIntro_Portrait_8
    dc.l    RaceQuote_18CDE,RiderIntro_Portrait_7,RaceQuote_19020,RiderIntro_Portrait_8
    dc.l    RaceQuote_19452,RiderIntro_Portrait_9,RaceQuote_19496,RiderIntro_Portrait_9
    dc.l    RaceQuote_19064,RiderIntro_Portrait_8,RaceQuote_1908E,RiderIntro_Portrait_8
    dc.l    RaceQuote_194F2,RiderIntro_Portrait_9,RaceQuote_19864,RiderIntro_Portrait_10
    dc.l    RaceQuote_1953A,RiderIntro_Portrait_9,RaceQuote_1957E,RiderIntro_Portrait_9
    dc.l    RaceQuote_198B8,RiderIntro_Portrait_10,RaceQuote_19902,RiderIntro_Portrait_10

RaceResults_LevelTableNeg:
    dc.l    RaceQuote_187DE,RiderIntro_Portrait_6,RaceQuote_18D10,RiderIntro_Portrait_7
    dc.l    RaceQuote_18814,RiderIntro_Portrait_6,RaceQuote_18D46,RiderIntro_Portrait_7
    dc.l    RaceQuote_190CC,RiderIntro_Portrait_8,RaceQuote_195C0,RiderIntro_Portrait_9
    dc.l    RaceQuote_19100,RiderIntro_Portrait_8,RaceQuote_1960A,RiderIntro_Portrait_9
    dc.l    RaceQuote_1993E,RiderIntro_Portrait_10,RaceQuote_19980,RiderIntro_Portrait_10

; RaceResults_CopTablePos: 5 cops x 4 variants (negative money: 5x2)
RaceResults_CopTablePos:
    dc.l    RaceQuote_17990,RiderIntro_Portrait_1,RaceQuote_179D4,RiderIntro_Portrait_1
    dc.l    RaceQuote_17A2C,RiderIntro_Portrait_1,RaceQuote_17A80,RiderIntro_Portrait_1
    dc.l    RaceQuote_17C78,RiderIntro_Portrait_2,RaceQuote_17CBA,RiderIntro_Portrait_2
    dc.l    RaceQuote_17D04,RiderIntro_Portrait_2,RaceQuote_17D4E,RiderIntro_Portrait_2
    dc.l    RaceQuote_17ED0,RiderIntro_Portrait_3,RaceQuote_17F24,RiderIntro_Portrait_3
    dc.l    RaceQuote_17F66,RiderIntro_Portrait_3,RaceQuote_17FC8,RiderIntro_Portrait_3
    dc.l    RaceQuote_181B6,RiderIntro_Portrait_4,RaceQuote_181FE,RiderIntro_Portrait_4
    dc.l    RaceQuote_18228,RiderIntro_Portrait_4,RaceQuote_18266,RiderIntro_Portrait_4
    dc.l    RaceQuote_1838A,RiderIntro_Portrait_5,RaceQuote_183E6,RiderIntro_Portrait_5
    dc.l    RaceQuote_18418,RiderIntro_Portrait_5,RaceQuote_18460,RiderIntro_Portrait_5

RaceResults_CopTableNeg:
    dc.l    RaceQuote_17ABE,RiderIntro_Portrait_1,RaceQuote_17B00,RiderIntro_Portrait_1
    dc.l    RaceQuote_17D86,RiderIntro_Portrait_2,RaceQuote_17DC4,RiderIntro_Portrait_2
    dc.l    RaceQuote_18012,RiderIntro_Portrait_3,RaceQuote_18062,RiderIntro_Portrait_3
    dc.l    RaceQuote_18298,RiderIntro_Portrait_4,RaceQuote_182D4,RiderIntro_Portrait_4
    dc.l    RaceQuote_1849E,RiderIntro_Portrait_5,RaceQuote_184FE,RiderIntro_Portrait_5

; EndLevel_LevelRiderTable: 5 levels x 2 variants (rival + Natasha)
EndLevel_LevelRiderTable:
    dc.l    RaceQuote_1886C,RiderIntro_Portrait_6,RaceQuote_17720,RiderIntro_Portrait_0
    dc.l    RaceQuote_18D84,RiderIntro_Portrait_7,RaceQuote_1778C,RiderIntro_Portrait_0
    dc.l    RaceQuote_19136,RiderIntro_Portrait_8,RaceQuote_177D4,RiderIntro_Portrait_0
    dc.l    RaceQuote_1964C,RiderIntro_Portrait_9,RaceQuote_17818,RiderIntro_Portrait_0
    dc.l    RaceQuote_199C8,RiderIntro_Portrait_10,RaceQuote_17848,RiderIntro_Portrait_0

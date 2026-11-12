; *************************************************
; race_data_tables.asm - race/intro/results tables from the ROM gap
; ROM range: $19A12-$19F61 (non-audio data); included from main.asm.
; *************************************************

; RiderIntro_RecordTable: [level][track][variant] records of (quote_ptr, image_ptr)
; 5 levels x 10 tracks x 2 variants x 8 bytes = $320.
RiderIntro_RecordTable:
    dc.l    RiderIntro_Quote_Natasha_01,RiderIntro_Portrait_0,RiderIntro_Quote_Biff_01,RiderIntro_Portrait_6
    dc.l    RiderIntro_Quote_Slater_01,RiderIntro_Portrait_7,RiderIntro_Quote_Natasha_21,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_02,RiderIntro_Portrait_0,RiderIntro_Quote_OLeary_01,RiderIntro_Portrait_1
    dc.l    RiderIntro_Quote_Biff_02,RiderIntro_Portrait_6,RiderIntro_Quote_Natasha_22,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_03,RiderIntro_Portrait_0,RiderIntro_Quote_Biff_03,RiderIntro_Portrait_6
    dc.l    RiderIntro_Quote_Slater_02,RiderIntro_Portrait_7,RiderIntro_Quote_Natasha_21,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_04,RiderIntro_Portrait_0,RiderIntro_Quote_OLeary_02,RiderIntro_Portrait_1
    dc.l    RiderIntro_Quote_Slater_03,RiderIntro_Portrait_7,RiderIntro_Quote_Natasha_22,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_ORourke_01,RiderIntro_Portrait_2,RiderIntro_Quote_Biff_04,RiderIntro_Portrait_6
    dc.l    RiderIntro_Quote_Slater_04,RiderIntro_Portrait_7,RiderIntro_Quote_ORourke_01,RiderIntro_Portrait_2
    dc.l    RiderIntro_Quote_Natasha_05,RiderIntro_Portrait_0,RiderIntro_Quote_ORourke_02,RiderIntro_Portrait_2
    dc.l    RiderIntro_Quote_Ikira_01,RiderIntro_Portrait_8,RiderIntro_Quote_Natasha_23,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_OLeary_03,RiderIntro_Portrait_1,RiderIntro_Quote_Biff_05,RiderIntro_Portrait_6
    dc.l    RiderIntro_Quote_Slater_05,RiderIntro_Portrait_7,RiderIntro_Quote_OLeary_03,RiderIntro_Portrait_1
    dc.l    RiderIntro_Quote_Natasha_06,RiderIntro_Portrait_0,RiderIntro_Quote_ORourke_03,RiderIntro_Portrait_2
    dc.l    RiderIntro_Quote_Slater_06,RiderIntro_Portrait_7,RiderIntro_Quote_Natasha_23,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_07,RiderIntro_Portrait_0,RiderIntro_Quote_Slater_07,RiderIntro_Portrait_7
    dc.l    RiderIntro_Quote_Ikira_02,RiderIntro_Portrait_8,RiderIntro_Quote_Natasha_24,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_08,RiderIntro_Portrait_0,RiderIntro_Quote_Biff_06,RiderIntro_Portrait_6
    dc.l    RiderIntro_Quote_Slater_08,RiderIntro_Portrait_7,RiderIntro_Quote_Natasha_24,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_09,RiderIntro_Portrait_0,RiderIntro_Quote_Slater_09,RiderIntro_Portrait_7
    dc.l    RiderIntro_Quote_Ikira_03,RiderIntro_Portrait_8,RiderIntro_Quote_Natasha_25,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_10,RiderIntro_Portrait_0,RiderIntro_Quote_Slater_10,RiderIntro_Portrait_7
    dc.l    RiderIntro_Quote_Sergio_01,RiderIntro_Portrait_9,RiderIntro_Quote_Natasha_26,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_ORourke_04,RiderIntro_Portrait_2,RiderIntro_Quote_Ikira_04,RiderIntro_Portrait_8
    dc.l    RiderIntro_Quote_Sergio_02,RiderIntro_Portrait_9,RiderIntro_Quote_ORourke_04,RiderIntro_Portrait_2
    dc.l    RiderIntro_Quote_Natasha_11,RiderIntro_Portrait_0,RiderIntro_Quote_Flynn_01,RiderIntro_Portrait_3
    dc.l    RiderIntro_Quote_Slater_11,RiderIntro_Portrait_7,RiderIntro_Quote_Natasha_26,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_12,RiderIntro_Portrait_0,RiderIntro_Quote_Flynn_02,RiderIntro_Portrait_3
    dc.l    RiderIntro_Quote_Ikira_05,RiderIntro_Portrait_8,RiderIntro_Quote_Natasha_25,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_13,RiderIntro_Portrait_0,RiderIntro_Quote_OShea_01,RiderIntro_Portrait_4
    dc.l    RiderIntro_Quote_Sergio_03,RiderIntro_Portrait_9,RiderIntro_Quote_Natasha_27,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_14,RiderIntro_Portrait_0,RiderIntro_Quote_Ikira_06,RiderIntro_Portrait_8
    dc.l    RiderIntro_Quote_Sergio_04,RiderIntro_Portrait_9,RiderIntro_Quote_Natasha_28,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_15,RiderIntro_Portrait_0,RiderIntro_Quote_OShea_02,RiderIntro_Portrait_4
    dc.l    RiderIntro_Quote_Sergio_05,RiderIntro_Portrait_9,RiderIntro_Quote_Natasha_27,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Flynn_03,RiderIntro_Portrait_3,RiderIntro_Quote_Ikira_07,RiderIntro_Portrait_8
    dc.l    RiderIntro_Quote_Helldog_01,RiderIntro_Portrait_10,RiderIntro_Quote_Flynn_03,RiderIntro_Portrait_3
    dc.l    RiderIntro_Quote_Natasha_16,RiderIntro_Portrait_0,RiderIntro_Quote_Sergio_06,RiderIntro_Portrait_9
    dc.l    RiderIntro_Quote_Helldog_02,RiderIntro_Portrait_10,RiderIntro_Quote_Natasha_27,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_OConnor_01,RiderIntro_Portrait_5,RiderIntro_Quote_Sergio_07,RiderIntro_Portrait_9
    dc.l    RiderIntro_Quote_Helldog_03,RiderIntro_Portrait_10,RiderIntro_Quote_OConnor_01,RiderIntro_Portrait_5
    dc.l    RiderIntro_Quote_Natasha_17,RiderIntro_Portrait_0,RiderIntro_Quote_OShea_03,RiderIntro_Portrait_4
    dc.l    RiderIntro_Quote_Sergio_08,RiderIntro_Portrait_9,RiderIntro_Quote_Natasha_30,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_18,RiderIntro_Portrait_0,RiderIntro_Quote_Sergio_09,RiderIntro_Portrait_9
    dc.l    RiderIntro_Quote_Helldog_04,RiderIntro_Portrait_10,RiderIntro_Quote_Natasha_29,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_19,RiderIntro_Portrait_0,RiderIntro_Quote_Sergio_10,RiderIntro_Portrait_9
    dc.l    RiderIntro_Quote_Helldog_05,RiderIntro_Portrait_10,RiderIntro_Quote_Natasha_30,RiderIntro_Portrait_0
    dc.l    RiderIntro_Quote_Natasha_20,RiderIntro_Portrait_0,RiderIntro_Quote_OConnor_02,RiderIntro_Portrait_5
    dc.l    RiderIntro_Quote_Helldog_06,RiderIntro_Portrait_10,RiderIntro_Quote_Natasha_29,RiderIntro_Portrait_0

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

; *************************************************
; road_shapes.asm - road/object shape pointer table and shape data (ROM gap)
; ROM range: $3BF1A-$7DCA7; included from main.asm.
;
; Road_ShapeTable[564] = dword pointers to shape data; index from object
; record +8 / +$12 (Road_DrawObject, race.asm) and race_ai. word_3C7EA holds the
; shape count ($234 = 564). Shape data starts at the first pointer ($3C7EC) and is
; byte-oriented/opaque; the exact record format is documented as TODO.
; *************************************************

Road_ShapeTable:
    dc.l    Road_ShapeData+$13E02, Road_ShapeData+$141B8, Road_ShapeData+$1452E, Road_ShapeData+$14844
    dc.l    Road_ShapeData+$1452E, Road_ShapeData+$141B8, Road_ShapeData+$13E02, 0
    dc.l    Road_ShapeData+$14B6A, Road_ShapeData+$14F90, Road_ShapeData+$15386, Road_ShapeData+$15712
    dc.l    Road_ShapeData+$15386, Road_ShapeData+$14F90, Road_ShapeData+$14B6A, 0
    dc.l    Road_ShapeData+$15A88, Road_ShapeData+$15DD6, Road_ShapeData+$160DA, Road_ShapeData+$163C0
    dc.l    Road_ShapeData+$166E6, Road_ShapeData+$16A4C, Road_ShapeData+$16DC2, 0
    dc.l    Road_ShapeData+$170FC, Road_ShapeData+$170FC, Road_ShapeData+$17444, Road_ShapeData+$1779A
    dc.l    Road_ShapeData+$17B10, Road_ShapeData+$17F06, Road_ShapeData+$182FC, 0
    dc.l    Road_ShapeData+$186F6, Road_ShapeData+$18A6C, Road_ShapeData+$18A6C, Road_ShapeData+$18DCA
    dc.l    Road_ShapeData+$19186, Road_ShapeData+$19186, Road_ShapeData+$1956A, 0
    dc.l    Road_ShapeData+$19940, Road_ShapeData+$19940, Road_ShapeData+$19940, Road_ShapeData+$19CEA
    dc.l    Road_ShapeData+$1A106, Road_ShapeData+$1A106, Road_ShapeData+$1A5A4, 0
    dc.l    Road_ShapeData+$1AA34, Road_ShapeData+$1AE9A, Road_ShapeData+$1AE9A, Road_ShapeData+$1B306
    dc.l    Road_ShapeData+$1B7BC, Road_ShapeData+$1B7BC, Road_ShapeData+$1BC82, 0
    dc.l    Road_ShapeData+$1AA34, Road_ShapeData+$1AE9A, Road_ShapeData+$1AE9A, Road_ShapeData+$1B306
    dc.l    Road_ShapeData+$1B7BC, Road_ShapeData+$1B7BC, Road_ShapeData+$1BC82, 0
    dc.l    Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA
    dc.l    Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA, 0
    dc.l    Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA
    dc.l    Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA, Road_ShapeData+$1C0BA, 0
    dc.l    Road_ShapeData+$15712, Road_ShapeData+$1779A, Road_ShapeData+$19CEA, Road_ShapeData+$1C586
    dc.l    Road_ShapeData+$1C966, Road_ShapeData+$1CD0C, Road_ShapeData+$1D160, Road_ShapeData+$1D4FC
    dc.l    Road_ShapeData+$1D8E0, Road_ShapeData+$1DF98, Road_ShapeData+$1DCE8, Road_ShapeData+$1E3A8
    dc.l    Road_ShapeData+$1E136, Road_ShapeData+$1E802, Road_ShapeData+$1E570, Road_ShapeData+$2F6CE
    dc.l    Road_ShapeData+$2F6CE, Road_ShapeData+$2FB28, 0, Road_ShapeData+$2FFDC
    dc.l    Road_ShapeData+$2FFDC, Road_ShapeData+$30480, 0, Road_ShapeData+$30984
    dc.l    Road_ShapeData+$30984, Road_ShapeData+$30EE2, 0, Road_ShapeData+$3323E
    dc.l    Road_ShapeData+$3323E, Road_ShapeData+$3323E, 0, Road_ShapeData+$32D8A
    dc.l    Road_ShapeData+$32930, Road_ShapeData+$32930, 0, Road_ShapeData+$32454
    dc.l    Road_ShapeData+$31FB0, Road_ShapeData+$31FB0, 0, Road_ShapeData+$31A0C
    dc.l    Road_ShapeData+$314AE, Road_ShapeData+$314AE, 0, Road_ShapeData+$343B6
    dc.l    Road_ShapeData+$343B6, Road_ShapeData+$343B6, 0, Road_ShapeData
    dc.l    Road_ShapeData+$460, Road_ShapeData+$8D2, Road_ShapeData+$D70, Road_ShapeData+$1222
    dc.l    Road_ShapeData+$173C, Road_ShapeData+$1CAA, Road_ShapeData+$22BC, Road_ShapeData+$33B14
    dc.l    Road_ShapeData+$21BC2, Road_ShapeData+$21DE8, Road_ShapeData+$2200C, Road_ShapeData+$2235E
    dc.l    Road_ShapeData+$2263E, Road_ShapeData+$2281E, Road_ShapeData+$22B12, Road_ShapeData+$22E22
    dc.l    Road_ShapeData+$230C6, Road_ShapeData+$233AA, Road_ShapeData+$2371A, Road_ShapeData+$23A70
    dc.l    Road_ShapeData+$23D34, Road_ShapeData+$23FAC, Road_ShapeData+$24290, Road_ShapeData+$24534
    dc.l    Road_ShapeData+$24700, Road_ShapeData+$2495C, Road_ShapeData+$24B02, Road_ShapeData+$24CDA
    dc.l    Road_ShapeData+$24F72, Road_ShapeData+$25236, Road_ShapeData+$2549C, Road_ShapeData+$25748
    dc.l    Road_ShapeData+$25A44, Road_ShapeData+$2281E, Road_ShapeData+$2ADD0, Road_ShapeData+$2B08E
    dc.l    Road_ShapeData+$2B2E4, Road_ShapeData+$22E22, Road_ShapeData+$2371A, Road_ShapeData+$23A70
    dc.l    Road_ShapeData+$23D34, Road_ShapeData+$21BC2, Road_ShapeData+$21DE8, Road_ShapeData+$2263E
    dc.l    Road_ShapeData+$25D06, Road_ShapeData+$25EC0, Road_ShapeData+$2602A, Road_ShapeData+$26198
    dc.l    Road_ShapeData+$2636A, Road_ShapeData+$2667E, Road_ShapeData+$269AC, Road_ShapeData+$26C50
    dc.l    Road_ShapeData+$26F00, Road_ShapeData+$27162, Road_ShapeData+$274C6, Road_ShapeData+$277F4
    dc.l    Road_ShapeData+$27B04, Road_ShapeData+$27E50, Road_ShapeData+$28112, Road_ShapeData+$28368
    dc.l    Road_ShapeData+$286DC, Road_ShapeData+$28A0A, Road_ShapeData+$28D6E, Road_ShapeData+$290AC
    dc.l    Road_ShapeData+$294D8, Road_ShapeData+$29896, Road_ShapeData+$29DE0, Road_ShapeData+$2A1B0
    dc.l    Road_ShapeData+$2A504, Road_ShapeData+$2AA68, Road_ShapeData+$2ADD0, Road_ShapeData+$2B08E
    dc.l    Road_ShapeData+$2B2E4, Road_ShapeData+$2B58C, Road_ShapeData+$1E9E4, Road_ShapeData+$1EC66
    dc.l    Road_ShapeData+$1F006, Road_ShapeData+$1F2BA, Road_ShapeData+$1F2BA, Road_ShapeData+$1F698
    dc.l    Road_ShapeData+$1FADC, Road_ShapeData+$1FDA0, Road_ShapeData+$201C8, Road_ShapeData+$2052C
    dc.l    Road_ShapeData+$20B20, Road_ShapeData+$20FA4, Road_ShapeData+$21344, Road_ShapeData+$217FC
    dc.l    Road_ShapeData+$2F9A, Road_ShapeData+$31E0, Road_ShapeData+$3346, Road_ShapeData+$34CC
    dc.l    Road_ShapeData+$3688, Road_ShapeData+$37DE, Road_ShapeData+$3914, Road_ShapeData+$3BA4
    dc.l    Road_ShapeData+$3D64, Road_ShapeData+$3F02, Road_ShapeData+$4130, Road_ShapeData+$42C6
    dc.l    Road_ShapeData+$444C, Road_ShapeData+$4662, Road_ShapeData+$4818, Road_ShapeData+$4978
    dc.l    Road_ShapeData+$4B20, Road_ShapeData+$4C86, Road_ShapeData+$4DD6, Road_ShapeData+$4F7A
    dc.l    Road_ShapeData+$50BC, Road_ShapeData+$5202, Road_ShapeData+$5394, Road_ShapeData+$54EA
    dc.l    Road_ShapeData+$56FE, Road_ShapeData+$5916, Road_ShapeData+$5AE4, Road_ShapeData+$5C7A
    dc.l    Road_ShapeData+$5E90, Road_ShapeData+$6046, Road_ShapeData+$61DC, Road_ShapeData+$63F2
    dc.l    Road_ShapeData+$657E, Road_ShapeData+$6704, Road_ShapeData+$68B4, Road_ShapeData+$6A52
    dc.l    Road_ShapeData+$6CCA, Road_ShapeData+$6E60, Road_ShapeData+$6FE6, Road_ShapeData+$7166
    dc.l    Road_ShapeData+$733A, Road_ShapeData+$74E0, Road_ShapeData+$76A8, Road_ShapeData+$79A2
    dc.l    Road_ShapeData+$7B48, Road_ShapeData+$7D92, Road_ShapeData+$8024, Road_ShapeData+$823E
    dc.l    Road_ShapeData+$8484, Road_ShapeData+$876A, Road_ShapeData+$895E, Road_ShapeData+$8BBC
    dc.l    Road_ShapeData+$8E22, Road_ShapeData+$9062, Road_ShapeData+$9290, Road_ShapeData+$95D2
    dc.l    Road_ShapeData+$9798, Road_ShapeData+$99D8, Road_ShapeData+$9CB4, Road_ShapeData+$9E9A
    dc.l    Road_ShapeData+$A0BC, Road_ShapeData+$A324, Road_ShapeData+$A564, Road_ShapeData+$A790
    dc.l    Road_ShapeData+$A984, Road_ShapeData+$ABEA, Road_ShapeData+$AF1E, Road_ShapeData+$B24A
    dc.l    Road_ShapeData+$B420, Road_ShapeData+$B64E, Road_ShapeData+$B8B4, Road_ShapeData+$BA8E
    dc.l    Road_ShapeData+$BCA4, Road_ShapeData+$BEE4, Road_ShapeData+$C0D8, Road_ShapeData+$C306
    dc.l    Road_ShapeData+$C4FA, Road_ShapeData+$C7C0, Road_ShapeData+$CAC8, Road_ShapeData+$CD78
    dc.l    Road_ShapeData+$CFEA, Road_ShapeData+$D2C6, Road_ShapeData+$D510, Road_ShapeData+$D76E
    dc.l    Road_ShapeData+$D9CC, Road_ShapeData+$DE60, Road_ShapeData+$E1B6, Road_ShapeData+$E6B8
    dc.l    Road_ShapeData+$EA4E, Road_ShapeData+$EEAE, Road_ShapeData+$F204, Road_ShapeData+$F63A
    dc.l    Road_ShapeData+$F980, Road_ShapeData+$FE98, Road_ShapeData+$1024E, Road_ShapeData+$106EC
    dc.l    Road_ShapeData+$10A82, Road_ShapeData+$10F68, Road_ShapeData+$1135E, Road_ShapeData+$118A4
    dc.l    Road_ShapeData+$11CE6, Road_ShapeData+$11FC6, Road_ShapeData+$12202, Road_ShapeData+$125D4
    dc.l    Road_ShapeData+$128C6, Road_ShapeData+$12BDC, Road_ShapeData+$12ECC, Road_ShapeData+$132F4
    dc.l    Road_ShapeData+$13686, Road_ShapeData+$13686, Road_ShapeData+$139EE, Road_ShapeData+$139EE
    dc.l    Road_ShapeData+$11E7C, Road_ShapeData+$120EC, Road_ShapeData+$12416, Road_ShapeData+$12756
    dc.l    Road_ShapeData+$12A6E, Road_ShapeData+$12D72, Road_ShapeData+$130E0, Road_ShapeData+$134E8
    dc.l    Road_ShapeData+$13858, Road_ShapeData+$13858, Road_ShapeData+$13C04, Road_ShapeData+$13C04
    dc.l    Road_ShapeData+$40EEC, Road_ShapeData+$40FA8, Road_ShapeData+$41064, Road_ShapeData+$4112E
    dc.l    Road_ShapeData+$4112E, Road_ShapeData+$411F8, Road_ShapeData+$412BC, Road_ShapeData+$412BC
    dc.l    Road_ShapeData+$413BC, Road_ShapeData+$413BC, Road_ShapeData+$2D138, Road_ShapeData+$2D520
    dc.l    Road_ShapeData+$2D8BA, Road_ShapeData+$2DCA2, Road_ShapeData+$2E260, Road_ShapeData+$2E730
    dc.l    Road_ShapeData+$2EC30, Road_ShapeData+$2F130, Road_ShapeData+$2C826, Road_ShapeData+$2C892
    dc.l    Road_ShapeData+$2C8F6, Road_ShapeData+$2C94E, Road_ShapeData+$2C9A0, Road_ShapeData+$2CA76
    dc.l    Road_ShapeData+$2CB6A, Road_ShapeData+$2CC94, Road_ShapeData+$2B95C, Road_ShapeData+$2BC94
    dc.l    Road_ShapeData+$2C00A, Road_ShapeData+$2C328, Road_ShapeData+$2CDC4, Road_ShapeData+$2CC94
    dc.l    Road_ShapeData+$2CC94, Road_ShapeData+$3AD88, Road_ShapeData+$28E8, Road_ShapeData+$40CB8
    dc.l    Road_ShapeData+$40E00, Road_ShapeData+$343B6, Road_ShapeData+$343B6, Road_ShapeData+$39FA8
    dc.l    Road_ShapeData+$3870E, Road_ShapeData+$37B6A, Road_ShapeData+$37DBA, Road_ShapeData+$37F1E
    dc.l    Road_ShapeData+$38248, Road_ShapeData+$3843A, Road_ShapeData+$3870E, Road_ShapeData+$3AD88
    dc.l    Road_ShapeData+$39E52, Road_ShapeData+$39EBC, 0, Road_ShapeData+$34D5A
    dc.l    Road_ShapeData+$34D5A, Road_ShapeData+$34D5A, Road_ShapeData+$34D5A, Road_ShapeData+$34CDE
    dc.l    Road_ShapeData+$34CDE, Road_ShapeData+$34CDE, Road_ShapeData+$3503E, Road_ShapeData+$351AE
    dc.l    Road_ShapeData+$3548A, Road_ShapeData+$355F6, Road_ShapeData+$35A0E, Road_ShapeData+$35EDA
    dc.l    Road_ShapeData+$364EA, Road_ShapeData+$36FC0, Road_ShapeData+$37A26, Road_ShapeData+$39AE8
    dc.l    Road_ShapeData+$36DF4, Road_ShapeData+$374A4, Road_ShapeData+$3870E, Road_ShapeData+$3755E
    dc.l    Road_ShapeData+$36FC0, Road_ShapeData+$37A26, Road_ShapeData+$39E16, Road_ShapeData+$37B6A
    dc.l    Road_ShapeData+$37DBA, Road_ShapeData+$37F1E, Road_ShapeData+$3870E, Road_ShapeData+$3870E
    dc.l    Road_ShapeData+$38772, Road_ShapeData+$38772, Road_ShapeData+$38772, Road_ShapeData+$389A6
    dc.l    Road_ShapeData+$39010, Road_ShapeData+$38D4C, Road_ShapeData+$38D4C, Road_ShapeData+$39010
    dc.l    Road_ShapeData+$3950C, Road_ShapeData+$3950C, Road_ShapeData+$39818, Road_ShapeData+$39B82
    dc.l    Road_ShapeData+$39FA8, Road_ShapeData+$39FA8, Road_ShapeData+$39E16, Road_ShapeData+$39E16
    dc.l    Road_ShapeData+$3950C, Road_ShapeData+$39E16, Road_ShapeData+$39E52, Road_ShapeData+$39EBC
    dc.l    Road_ShapeData+$39EBC, Road_ShapeData+$39FA8, Road_ShapeData+$39FA8, Road_ShapeData+$3AE64
    dc.l    Road_ShapeData+$3AEE8, Road_ShapeData+$3AE64, Road_ShapeData+$3AEE8, Road_ShapeData+$3B164
    dc.l    Road_ShapeData+$3B2C8, Road_ShapeData+$3B9B2, Road_ShapeData+$3BA40, Road_ShapeData+$3C322
    dc.l    Road_ShapeData+$3C4E8, Road_ShapeData+$3C6BC, Road_ShapeData+$3C88E, Road_ShapeData+$3D058
    dc.l    Road_ShapeData+$3D086, Road_ShapeData+$3CA4C, Road_ShapeData+$3CAA0, Road_ShapeData+$3D058
    dc.l    Road_ShapeData+$3D086, Road_ShapeData+$3D058, Road_ShapeData+$3D086, Road_ShapeData+$3D058
    dc.l    Road_ShapeData+$3D086, Road_ShapeData+$3E338, Road_ShapeData+$3E424, Road_ShapeData+$3D950
    dc.l    Road_ShapeData+$3DA3C, Road_ShapeData+$3E338, Road_ShapeData+$3E424, Road_ShapeData+$3E64A
    dc.l    Road_ShapeData+$3E728, Road_ShapeData+$3EAB2, Road_ShapeData+$3EC80, Road_ShapeData+$3F17E
    dc.l    Road_ShapeData+$3F1E4, Road_ShapeData+$3FC02, Road_ShapeData+$3FD4C, Road_ShapeData+$3FE48
    dc.l    Road_ShapeData+$3FFC6, Road_ShapeData+$401B0, Road_ShapeData+$401F6, Road_ShapeData+$401B0
    dc.l    Road_ShapeData+$4035A, Road_ShapeData+$401B0, Road_ShapeData+$4035A, Road_ShapeData+$401B0
    dc.l    Road_ShapeData+$406DA, Road_ShapeData+$401B0, Road_ShapeData+$404BE, Road_ShapeData+$401B0
    dc.l    Road_ShapeData+$404BE, Road_ShapeData+$401B0, Road_ShapeData+$404BE, Road_ShapeData+$401B0
    dc.l    Road_ShapeData+$404BE, Road_ShapeData+$401B0, Road_ShapeData+$405CC, Road_ShapeData+$401B0
    dc.l    Road_ShapeData+$405CC, Road_ShapeData+$401B0, Road_ShapeData+$4083E, Road_ShapeData+$401B0
    dc.l    Road_ShapeData+$408E6, Road_ShapeData+$401B0, Road_ShapeData+$4098E, Road_ShapeData+$401B0
    dc.l    Road_ShapeData+$40A36, Road_ShapeData+$401B0, Road_ShapeData+$40ADE, Road_ShapeData+$401B0
    dc.l    Road_ShapeData+$40B86, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, 0, 0
    dc.l    0, 0, Road_ShapeData+$3A01A, Road_ShapeData+$3A58E
    dc.l    Road_ShapeData+$3A8D4, Road_ShapeData+$3A01A, Road_ShapeData+$3A58E, Road_ShapeData+$3A8D4

; shape count = $234 (564); used as the shape-index limit in race_anim_audio
word_3C7EA:
    dc.w    $0234

; Shape data: $3C7EC-$7DCA7 (0x414BC bytes), raw from the reference ROM.
Road_ShapeData:
    binclude "baserom.md",$3C7EC,$414BC

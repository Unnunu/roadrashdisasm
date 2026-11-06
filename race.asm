; =============== S U B R O U T I N E =======================================


Race_Init:
                jsr     (Race_InitVariables).l
                jsr     (Race_LoadBikeData).l
                jsr     (Race_ClearFrameBuffers).l
                jsr     (sub_AB78).l
                jsr     (Race_LoadHUD).l
                jsr     (Race_InitTrack).l
                jsr     (Race_LoadFonts).l
                jsr     (Race_LoadMoreTrackGfx).l
                jsr     (Race_LoatTrackGfx).l
                jsr     (sub_A79C).l
                jsr     (Race_LoadRoadImage).l
                jsr     (sub_CA50).l
                jsr     (Race_CreateActors).l
                move.w  #0,(ram_FF1EAA + STRUCT_OFFSET_16).l
                jsr     (sub_B6C4).l
                jsr     (sub_B72A).l
                jsr     (sub_169B0).l
                jsr     (Race_InitVdp).l
                jsr     (sub_B8D0).l
                jsr     (sub_B840).l
                move.w  #$FFFF,(ram_FF369E).l
                move.w  #0,(ram_FF33C8).l
                move.w  #0,(ram_FF304C).l
                jsr     (Race_InitAudio).l
                move.w  #8,(ram_FF2EF0).l
                bclr    #3,(ram_FF2F13).l
                move.w  #0,(ram_FF2EC0).l
                move.w  #$FFE8,(ram_FF2F70).l
                bset    #3,(ram_FF2F93).l
                move.w  #0,(ram_FF2F40).l
                move.w  #1,(Race_ram_FrameDelay).l
                jsr     (Race_Update).l
                jsr     (Race_Update).l

                movea.l (Race_ram_NextVScrollInfo).l,a0
                move.w  #$8AFF,(a0) ; HCounter = 255
                move.w  #$873F,4(a0) ; backdrop color = $3F
                move.w  #0,6(a0) ; VScrollA = 0
                move.w  #0,8(a0) ; VScrollB = 0
                move.w  #$FFFF,$A(a0) ; next offset is -1
                move.w  #$8210,$C(a0) ; 
                move.w  #$8403,$E(a0)

.loc_A5EC:
                move.w  #-1,(Race_ram_State).l
                jsr     (Race_GameTick).l
                move.w  #1,(Race_ram_State).l
                lea     (Race_ram_FrameReady).l,a0
                tst.w   (a0)
                bne.s   .loc_A5EC

                jsr     (Race_Update).l
.loc_A612:
                move.w  #-1,(Race_ram_State).l
                jsr     (Race_GameTick).l
                move.w  #1,(Race_ram_State).l
                lea     (Race_ram_FrameReady).l,a0
                tst.w   (a0)
                bne.s   .loc_A612

                jsr     (Race_Update).l
                move.w  #0,(Race_ram_State).l
                rts
; End of function Race_Init


; =============== S U B R O U T I N E =======================================


ClearRAM:
                move.w  #$77FF,d0
                moveq   #0,d1
                movea.l #$FF0000,a0
.loc_A64E:
                move.w  d1,(a0)+
                dbf     d0,.loc_A64E
                rts
; End of function ClearRAM


; =============== S U B R O U T I N E =======================================


ClearVRAM:
                lea     (VdpData).l,a0
                moveq   #0,d2
                move.l  #$40000000,(VdpCtrl).l
                move.w  #$3FFF,d0
.loc_A66C:
                move.l  d2,(a0)
                dbf     d0,.loc_A66C
                rts
; End of function ClearVRAM


; =============== S U B R O U T I N E =======================================


Race_InitAudio:
                move.b  #0,(ram_FF1AD5).l
                move.w  #2000,(ram_FF36B6).l
                move.w  #2000,(ram_FF36B8).l
                move.w  #1000,(ram_FF36BA).l
                move.w  #1000,(ram_FF36BC).l
                move.w  #$7D0,(ram_FF36BE).l
                move.w  #$7D0,(ram_FF36C0).l
                move.w  #60,(ram_FF36C2).l
                jsr     (AudioFunc6).l
                move.w  (ram_FF36B8).l,d0
                move.w  #$1F,d1
                jsr     (AudioFunc8).l
                jsr     (AudioFunc9).l
                move.w  (ram_FF36BC).l,d0
                move.w  #$1F,d1
                jsr     (AudioFunc11).l
                jsr     (AudioFunc12).l
                move.w  (ram_FF36BE).l,d0
                move.w  #$1F,d1
                jsr     (AudioFunc14).l
                tst.w   (ram_MusicEnabled).l
                beq.w   .return

                lea     (Race_dTrackSongs).l,a0
                move.w  (Menu_ram_CurrentTrackId).l,d0
                move.w  (a0,d0.w),d0
                ext.l   d0
                move.w  d0,(ram_CurrentSong).l
                jsr     (AudioFunc3).l
.return:
                rts
; End of function Race_InitAudio


Race_dTrackSongs:      
    dc.w   2,3,7,5,4

; *************************************************
; Function Race_InitVdp
; *************************************************

Race_InitVdp:
                lea     (VdpCtrl).l,a0
                lea     (VdpData).l,a1
                move.w  #$8014,(a0) ; H-ints enabled, Pal Select 1, HVC latch disabled, Display gen enabled
                move.w  #$8210,(a0) ; Scroll A Name Table:    $4000
                move.w  #$8402,(a0) ; Scroll B Name Table:    $4000
                move.w  #$830C,(a0) ; Window Name Table:      $3000
                move.w  #$8562,(a0) ; Sprite Attribute Table: $C400
                move.w  #$873F,(a0) ; Backdrop Color: $3F
                move.w  #$8AFF,(a0) ; H-Int Counter: 255
                move.w  #$8B03,(a0) ; E-ints disabled, V-Scroll: full, H-Scroll: line
                move.w  #$8C81,(a0) ; Width: 40, Shadow/Highlight: disabled
                move.w  #$8D30,(a0) ; HScroll Data Table:     $C000
                move.w  #$8F02,(a0) ; Auto-increment: $2
                move.w  #$9003,(a0) ; Scroll A/B Size: 128x32
                move.w  #$9100,(a0) ; WindowX: 0 cells
                move.w  #$9293,(a0) ; WindowY: 19 cells, draw from VP to bottom edge
                VDP_VRAM_WRITE $C400,(a0) ; clear first sprite entry
                move.l  #0,(VdpData).l
                rts
; End of function Race_InitVdp


; =============== S U B R O U T I N E =======================================


Race_ClearSprites:
                movea.l #Intro_TitleScrollTable + $400,a0
                movea.l #Intro_TitleScrollSpeed + $400,a1
                move.w  #$B3,d0
                moveq   #0,d1
.loc_A792:
                move.l  d1,(a0)+
                move.l  d1,(a1)+
                dbf     d0,.loc_A792
                rts
; End of function Race_ClearSprites


; =============== S U B R O U T I N E =======================================


sub_A79C:
                VDP_VRAM_WRITE $4700,VdpCtrl
                movea.l #VdpData,a0
                move.l  #$E1D7E1D7,d1
                move.w  #$43F,d0
.loc_A7B6:
                move.l  d1,(a0)
                dbf     d0,.loc_A7B6

                VDP_VRAM_WRITE $6700,VdpCtrl
                movea.l #VdpData,a0
                move.l  #$E1D7E1D7,d1
                move.w  #$43F,d0
.loc_A7D6:
                move.l  d1,(a0)
                dbf     d0,.loc_A7D6

                lea     (unk_9B2F0).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.w  #40,d0 ; width
                move.w  #17,d1 ; height
                move.w  #44,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$4180,d4 ; base tile index, address = $3000, palette line 2
                move.w  #$4000,d5 ; destination VRAM address = foreground plane
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + 4).l,a0
                jsr     (WriteNametable).w

                move.w  #40,d0 ; width
                move.w  #17,d1 ; height
                move.w  #44,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$4180,d4 ; base tile index, address = $3000, palette line 2
                move.w  #$6000,d5; destination VRAM address = background plane
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + 4).l,a0
                jsr     (WriteNametable).w

                lea     (unk_9B494).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$3260,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                move.w  #3,d0 ; width
                move.w  #17,d1 ; height
                move.w  #84,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$193,d4 ; base tile index, address = $3260
                move.w  #$4000,d5 ; destination VRAM address = foreground plane
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $728).l,a0
                jsr     (WriteNametable).w

                move.w  #3,d0 ; width
                move.w  #17,d1 ; height
                move.w  #84,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$193,d4 ; base tile index, address = $3260
                move.w  #$6000,d5 ; destination VRAM address = background plane
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $728).l,a0
                jsr     (WriteNametable).w

                lea     (unk_9B7A6).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.w  #3,d0 ; width
                move.w  #17,d1 ; height
                move.w  #41,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$193,d4 ; base tile index, address = $3260
                move.w  #$4000,d5 ; destination VRAM address = background plane
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + 4).l,a0
                jsr     (WriteNametable).w

                move.w  #3,d0 ; width
                move.w  #17,d1 ; height
                move.w  #41,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$193,d4 ; base tile index, address = $3260
                move.w  #$6000,d5 ; destination VRAM address = foreground plane
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + 4).l,a0
                jsr     (WriteNametable).w
                rts
; End of function sub_A79C


; =============== S U B R O U T I N E =======================================


Race_LoatTrackGfx:
                movea.l (RaceTrack_Data6).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l

                move.l  #$1000,d0
                movea.l (RaceTrack_Data6).l,a0
                movea.w -6(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                jsr     (WriteToVRAM).l

                move.w  #128,d0 ; width
                move.w  #14,d1 ; height
                move.w  #0,d2 ; x
                move.w  #18,d3 ; y
                move.w  #$8080,d4 ; base tile index, address = $1000, high priority
                move.w  #$6000,d5 ; destination VRAM address = background plane
                move.w  #$80,d6
                movea.l (RaceTrack_Data6).l,a0
                movea.w -4(a0),a0
                adda.l  #Intro_ram_ImageBuffer + 4,a0
                jsr     (WriteNametable).w

                move.w  #128,d0 ; width
                move.w  #8,d1 ; height
                move.w  #0,d2 ; x
                move.w  #24,d3 ; y
                move.w  #$80,d4 ; base tile index, address = $1000
                move.w  #$4000,d5 ; destination VRAM address = foreground plane
                move.w  #128,d6 ; plane width
                movea.l (RaceTrack_Data6).l,a0
                movea.w -4(a0),a0
                adda.l  #Intro_ram_ImageBuffer + 4,a0
                jsr     (WriteNametable).w

                movea.l (RaceTrack_Data6).l,a0
                movea.w -2(a0),a0
                adda.l  #Intro_ram_ImageBuffer,a0
                movea.l (Global_ram_PalettePtr).l,a1
                adda.w  #$22,a0
                adda.w  #$22,a1
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                adda.w  #$28,a0
                adda.w  #$28,a1
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                addq.w  #4,a0
                addq.l  #4,a1
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                rts
; End of function Race_LoatTrackGfx


; =============== S U B R O U T I N E =======================================


Race_LoadMoreTrackGfx:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                cmp.w   #0,d0
                beq.w   .loc_AA10
                cmp.w   #2,d0
                beq.w   .loc_AA10
                cmp.w   #4,d0
                beq.w   .loc_AA10
                cmp.w   #6,d0
                beq.w   .loc_AA84
                cmp.w   #8,d0
                beq.w   .loc_AA84
                bra.w   .loc_AA84
.loc_AA10:
                lea     (unk_9B89E).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$8000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                move.w  #128,d0 ; width
                move.w  #7,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; base tile index, address = $8000
                move.w  #$4000,d5 ; destination VRAM address = foreground plane
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $408).l,a0
                jsr     (WriteNametable).w

                move.w  #128,d0 ; width
                move.w  #14,d1 ; height
                move.w  #0,d2 ; x
                move.w  #25,d3 ; y
                move.w  #$400,d4 ; base tile index, address = $8000
                move.w  #$4000,d5 ; destination VRAM address = foreground plane
                move.w  #128,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $408).l,a0
                jsr     (WriteNametable).w

                bra.w   .loc_AA84
.loc_AA84:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                cmp.w   #0,d0
                beq.w   .loc_AB16
                cmp.w   #2,d0
                beq.w   .return
                cmp.w   #4,d0
                beq.w   .return
                cmp.w   #6,d0
                beq.w   .loc_AAB6
                cmp.w   #8,d0
                beq.w   .loc_AAB6
                bra.w   .return
.loc_AAB6:
                VDP_VRAM_WRITE $6400,VdpCtrl
                movea.l #VdpData,a0
                move.l  #$E1D7E1D7,d1
                move.w  #$BF,d0
.loc_AAD0:
                move.l  d1,(a0)
                dbf     d0,.loc_AAD0

                VDP_VRAM_WRITE $4400,VdpCtrl
                movea.l #VdpData,a0
                move.l  #$E1D7E1D7,d1
                move.w  #$BF,d0
.loc_AAF0:
                move.l  d1,(a0)
                dbf     d0,.loc_AAF0

                VDP_VRAM_WRITE $6000,VdpCtrl
                movea.l #VdpData,a0
                move.l  #$E1D7E1D7,d1
                move.w  #$FF,d0
.loc_AB10:
                move.l  d1,(a0)
                dbf     d0,.loc_AB10
.loc_AB16:
                VDP_VRAM_WRITE $4000,VdpCtrl
                movea.l #VdpData,a0
                move.l  #$E1D7E1D7,d1
                move.w  #$FF,d0
.loc_AB30:
                move.l  d1,(a0)
                dbf     d0,.loc_AB30
.return:
                rts
; End of function Race_LoadMoreTrackGfx


; =============== S U B R O U T I N E =======================================


Race_ClearFrameBuffers:
                VDP_VRAM_WRITE $3000,VdpCtrl
                lea     (VdpData).l,a0
                move.w  #0,d1
                bset    #15,d1 ; high priority
                ori.w   #$6000,d1 ; palette line 3
                move.w  #$7FF,d0 ; clear $800 = $40 * $20 cells
.loc_AB58:
                move.w  d1,(a0)
                dbf     d0,.loc_AB58

                movea.l #Menu_ram_FrameBuffer,a0
                jsr     (sub_AB9A).l
                movea.l #Menu_ram_FrameBuffer2,a0
                jsr     (sub_AB9A).l
                rts
; End of function Race_ClearFrameBuffers


; =============== S U B R O U T I N E =======================================


sub_AB78:
                movea.l #Menu_ram_FrameBuffer + $AE0,a0 ; x = 48, y = 21
                movea.l #Menu_ram_FrameBuffer2 + $AE0,a1
                move.w  #7,d0
.loc_AB88:
                move.l  #0,(a0)+
                move.l  #0,(a1)+
                dbf     d0,.loc_AB88
                rts
; End of function sub_AB78


; =============== S U B R O U T I N E =======================================


sub_AB9A:
                move.l  #$E1D7E1D7,d0 ; high priority, palette line 3, tile address $3AE0
                move.w  #$12,d2
.loc_ABA4:
                move.w  #$13,d1
.loc_ABA8:
                move.l  d0,(a0)+
                dbf     d1,.loc_ABA8

                adda.l  #$30,a0
                dbf     d2,.loc_ABA4
                rts
; End of function sub_AB9A


; =============== S U B R O U T I N E =======================================


Race_LoadHUD:
                lea     (unk_9C82A).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                move.w  #40,d0 ; width
                move.w  #9,d1 ; height
                move.w  #0,d2 ; x
                move.w  #19,d3 ; y
                move.w  #0,d4 ; base tile index, address = $0
                move.w  #$3000,d5 ; destination VRAM address = window plane
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $1048).l,a0
                jsr     (WriteNametable).w

                move.w  #40,d0 ; width
                move.w  #9,d1 ; height
                move.w  #0,d2 ; x
                move.w  #19,d3 ; y
                move.w  #0,d4 ; base tile index, address = $0
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $1048).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w

                move.w  #40,d0 ; width
                move.w  #9,d1 ; height
                move.w  #0,d2 ; x
                move.w  #19,d3 ; y
                move.w  #0,d4 ; base tile index, address = $0
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $1048).l,a0
                lea     (Menu_ram_FrameBuffer2).l,a1
                jsr     (WriteNametableToBuffer).w

                lea     (Intro_ram_ImageBuffer + $FC4).l,a0
                movea.l (Global_ram_PalettePtr).l,a1
                adda.l  #$20,a0
                adda.l  #$20,a1
                adda.l  #$20,a0
                adda.l  #$20,a1
                adda.l  #$20,a0
                adda.l  #$20,a1
                addq.l  #2,a0
                addq.l  #2,a1
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+

                lea     (MenuPassword_ram_StrPlayerAName).l,a0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_AC9E
                lea     (MenuPassword_ram_StrPlayerBName).l,a0
.loc_AC9E:
                move.l  a0,-(sp)
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
                movea.l (sp),a0

                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  #2,d2 ; x
                move.w  #20,d3 ; y
                move.w  #$85C0,d4 ; base tile index, address = $B800, high priority
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w

                movea.l (sp)+,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  #2,d2 ; x
                move.w  #20,d3 ; y
                move.w  #$85C0,d4 ; base tile index, address = $B800, high priority
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer2).l,a1
                jsr     (WriteNametableToBuffer).w
                lea     (Intro_ram_ImageBuffer).l,a0

                move.w  (dStringCodeTable + 2 * 'B').w,(a0)
                move.w  (dStringCodeTable + 2 * 'I').w,2(a0)
                move.w  (dStringCodeTable + 2 * 'K').w,4(a0)
                move.w  (dStringCodeTable + 2 * 'E').w,6(a0)
                move.w  #4,d0 ; width
                move.w  #1,d1 ; height
                move.w  #14,d2 ; x
                move.w  #20,d3 ; y
                move.w  #$85C0,d4 ; base tile index, address = $B800, high priority
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w

                move.w  #4,d0 ; width
                move.w  #1,d1 ; height
                move.w  #14,d2 ; x
                move.w  #20,d3 ; y
                move.w  #$85C0,d4 ; base tile index, address = $B800, high priority
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer2).l,a1
                jsr     (WriteNametableToBuffer).w

                lea     (unk_9DA6A).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                lea     (Intro_ram_ImageBuffer).l,a0
                move.l  (a0)+,d0
                asl.w   #3,d0
                subq.w  #1,d0
                lea     (ram_FF352C).l,a1
.loc_AD8E:
                move.l  (a0)+,(a1)+                
                dbf     d0,.loc_AD8E

                lea     (Intro_ram_ImageBuffer).l,a1
                move.w  #2,(a1)
                move.w  #1,2(a1)
                move.w  #0,4(a1)

                move.w  #3,d0 ; width
                move.w  #1,d1 ; height
                move.w  #14,d2 ; x
                move.w  #25,d3 ; y
                move.w  #$1F0,d4 ; base tile index, address = $3E00
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w

                move.w  #3,d0 ; width
                move.w  #1,d1 ; height
                move.w  #14,d2 ; x
                move.w  #25,d3 ; y
                move.w  #$1F0,d4 ; base tile index, address = $3E00
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer2).l,a1
                jsr     (WriteNametableToBuffer).w
                rts
; End of function Race_LoadHUD


; =============== S U B R O U T I N E =======================================


Race_LoadRoadImage:
                lea     (unk_9DDCC).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$F880,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                lea     (Intro_ram_ImageBuffer + $728).l,a0
                movea.l #ram_FF33CC,a1
                move.w  #$57,d0 ; $B0 tiles in total
.loc_AE30:
                move.l  (a0)+,d1
                addi.l  #$7C407C4,d1
                move.l  d1,(a1)+
                dbf     d0,.loc_AE30

                lea     (VdpData).l,a0
                VDP_VRAM_WRITE $7800,VdpCtrl
                move.l  #$67CA67CA,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C867C8,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C667C6,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C467C4,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67CA67CA,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C867C8,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C667C6,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C467C4,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                VDP_VRAM_WRITE $7900,VdpCtrl
                move.l  #$67CB67CB,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C967C9,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C767C7,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C567C5,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67CB67CB,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C967C9,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C767C7,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  #$67C567C5,d1
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                move.l  d1,(a0)
                jsr     (sub_D9DA).l
                rts
; End of function Race_LoadRoadImage


; =============== S U B R O U T I N E =======================================


Race_LoadFonts:
; load font
                lea     (unk_9E3A2).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$B800,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
; load digit font
                lea     (unk_9DB68).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$3E80,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                lea     (unk_9DC4C).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$BF00,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l

                move.l  #$8300,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteToVRAM).l
                rts
; End of function Race_LoadFonts


; =============== S U B R O U T I N E =======================================


sub_AFC0:
                addi.w  #$4000,d0
                move.w  d0,(VdpCtrl).l
                addi.w  #0,d1
                move.w  d1,(VdpCtrl).l
                lea     (VdpData).l,a0
                move.w  (Intro_ram_ImageBuffer).l,d0
                asl.w   #3,d0
                subq.w  #1,d0
                lea     (Intro_ram_ImageBuffer + 4).l,a1
.loc_AFEA:
                move.l  (a1)+,(a0)
                dbf     d0,.loc_AFEA
                rts
; End of function sub_AFC0

; *************************************************
; Function WriteToVRAM
; d0 - VRAM address
; a0 - data, first long is number of tiles, the rest is tile data
; *************************************************

WriteToVRAM:
                asl.l   #2,d0
                lsr.w   #2,d0
                ori.w   #$4000,d0
                swap    d0
                move.l  d0,(VdpCtrl).l
                lea     (VdpData).l,a1
                move.l  (a0)+,d0
                asl.w   #3,d0
                subq.w  #1,d0
.loopWrite:
                move.l  (a0)+,(a1)
                dbf     d0,.loopWrite
                rts
; End of function WriteToVRAM


; =============== S U B R O U T I N E =======================================


Race_InitTrack:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                lea     (unk_25EC0).l,a0
                asl.w   #1,d0
                movea.l (a0,d0.w),a0
                movea.l (a0)+,a1
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                asl.w   #1,d0
                move.w  (a1,d0.w),(RaceTrack_Data1).l
                move.l  (a0)+,(RaceTrack_Data2).l
                move.l  (a0)+,(RaceTrack_Data3).l
                move.l  (a0)+,(RaceTrack_Data4).l
                move.l  (a0)+,(RaceTrack_Data5).l
                move.l  (a0)+,(RaceTrack_Data6).l
                move.l  (RaceTrack_Data4).l,(ram_FFD7C4).l
                move.w  #0,(ram_FFD7C8).l
                move.w  #$FFFF,(ram_FFD37C).l
                move.w  #1,(Race_ram_State).l
                move.w  #0,(Race_ram_TimeMinutes).l
                move.w  #0,(Race_ram_TimeTicks).l
                move.w  #0,(ram_FF1E56).l
                move.w  #$70,(ram_FF36AC).l
                move.w  #0,(ram_FF30E8).l
                move.l  #$5D,(ram_FF1E64).l
                move.l  #$100,(ram_FF1E68).l
                move.w  #1,(ram_FF1E6E).l
                move.w  #$3E,(ram_FF30DE).l
                move.w  #$3E,(ram_FF30E0).l
                move.w  #$1C0,(ram_FF30E6).l
                moveq   #0,d0
                move.w  d0,(ram_FF1E54).l
                move.w  d0,(ram_FF1E56).l
                rts
; End of function Race_InitTrack


; =============== S U B R O U T I N E =======================================


Race_InitVariables:
                move.l  #0,(ram_FF1E5C).l
                move.w  #0,(ram_FF0406).l
                move.w  #-1,(ram_FF3698).l
                move.w  #0,(ram_FF369A).l
                move.w  #0,(ram_FF1ACC).l
                move.l  #$FFFFFFFF,(ram_FF1908).l
                move.w  #0,(Race_ram_BikeDamage).l
                move.w  #$E10,(ram_FF1B32).l
                move.w  #$E10,(ram_FF1B34).l
                move.w  #0,(ram_FF1B36).l
                move.w  #0,(ram_FF1B38).l
                move.l  #0,(ram_FF1B3A).l
                move.w  #0,(ram_FF1AFA).l
                move.l  #$333,(ram_FF1AFC).l
                move.l  #0,(ram_FF1B00).l
                move.w  #0,(ram_FF1B04).l
                move.l  #$333,(ram_FF1B06).l
                move.l  #0,(ram_FF1B0A).l
                move.b  #$FF,(ram_FF302B).l
                move.b  #$FF,(ram_FF302A).l
                move.l  #1,(ram_FF1E9A).l
                move.l  #1,(ram_FF1E96).l
                move.w  #1,(Race_ram_FrameDelay).l
                move.w  #0,(ram_FF1B20).l
                move.w  #0,(Race_ram_GameEnded).l
                move.w  #0,(Race_ram_DemoGameEnded).l
                move.w  #0,(ram_FF1B22).l
                move.w  #0,(ram_FF1B2E).l
                move.w  #0,(ram_FF1B30).l
                move.w  #0,(ram_FF1B3E).l
                move.w  #0,(ram_FF1B40).l
                move.w  #0,(ram_FF1B42).l
                move.w  #0,(ram_FF1B44).l
                move.w  #0,(ram_FF1B46).l
                move.w  #0,(ram_FF1B48).l
                move.w  #0,(ram_FF1B4C).l
                move.w  #0,(ram_FF1B4E).l
                move.w  #0,(ram_FF1E50).l
                move.w  #0,(ram_FF1E52).l
                move.w  #0,(ram_FF1E54).l
                move.w  #0,(ram_FF1E56).l
                move.w  #0,(ram_FF1E58).l
                move.w  #0,(ram_FF1E5A).l
                move.l  #0,(ram_FF1E60).l
                move.l  #$5D,(ram_FF1E64).l
                move.l  #$100,(ram_FF1E68).l
                move.w  #0,(ram_FF1E82).l
                move.w  #0,(ram_FF1E6C).l
                move.w  #1,(ram_FF1E6E).l
                move.w  #0,(ram_FF1E70).l
                move.l  #0,(ram_FF1E76).l
                move.l  #0,(ram_FF1E7A).l
                move.l  #0,(ram_FF1E7E).l
                move.l  #0,(ram_FF1E86).l
                move.l  #0,(ram_FF1E8A).l
                move.l  #0,(ram_FF1E8E).l
                move.w  #0,(ram_FF1E92).l
                move.w  #0,(ram_FF1E94).l
                move.w  #0,(Race_ram_TimeTicks).l
                move.w  #0,(Race_ram_TimeMinutes).l
                move.w  #0,(ram_FF1B1A).l
                move.w  #0,(ram_FF1B18).l
                move.w  #0,(ram_FF3036).l
                move.l  #0,(ram_FF3038).l
                move.w  #0,(ram_FF303C).l
                move.w  #0,(ram_FF303E).l
                move.w  #0,(ram_FF3040).l
                move.w  #0,(ram_FF3042).l
                move.w  #0,(ram_FF3044).l
                move.w  #0,(ram_FF3046).l
                move.w  #0,(Race_ram_FrameCounter).l
                move.w  #0,(Race_ram_FrameDelay).l
                move.w  #0,(ram_FF304C).l
                move.w  #0,(ram_FF3054).l
                move.l  #0,(ram_FF3056).l
                move.l  #Global_ram_Palette,(Global_ram_PalettePtr).l
                move.w  #$3E,(ram_FF30DE).l
                move.w  #$3E,(ram_FF30E0).l
                move.w  #0,(ram_FF30E2).l
                move.w  #0,(ram_FF30E4).l
                move.w  #$1C0,(ram_FF30E6).l
                move.w  #0,(ram_FF30E8).l
                move.l  #0,(ram_FF30EA).l
                move.l  #0,(ram_FF30EE).l
                move.l  #0,(ram_FF30F2).l
                move.l  #0,(ram_FF30F6).l
                move.l  #0,(ram_FF30FA).l
                move.l  #0,(ram_FF30FE).l
                move.l  #0,(ram_FF3102).l
                move.w  #0,(ram_FF3106).l
                move.w  #0,(ram_FF3108).l
                move.w  #0,(ram_FF33C8).l
                move.w  #0,(Race_ram_NumSpriteTiles).l
                move.w  #0,(ram_FF368C).l
                move.w  #0,(ram_FF368E).l
                move.w  #0,(ram_FF3690).l
                move.w  #0,(ram_FF369C).l
                move.w  #0,(ram_FF369E).l
                move.w  #0,(ram_FF36AA).l
                move.w  #$70,(ram_FF36AC).l
                move.w  #0,(ram_FF36AE).l
                move.w  #$FFFF,(ram_FF36B0).l
                move.w  #0,(ram_FF36B2).l
                move.w  #$FFFF,(ram_FF36B4).l
                move.w  #0,(Race_ram_FrameReady).l
                move.w  #0,(Race_ram_FrameReady2).l
                move.w  #0,(Race_ram_Alpha1).l
                move.w  #$FFFF,(ram_FF36CC).l
                move.w  #0,(Race_ram_Alpha2).l
                move.w  #$FFFF,(ram_FF36D0).l
                move.w  #0,(Race_ram_Alpha3).l
                move.w  #$FFFF,(ram_FF36D4).l
                move.w  #0,(ram_FF36D6).l
                move.l  #Intro_ram_ImageBuffer,(Race_ram_NextSpriteTileArray).l
                move.w  #$8680,(Race_ram_SpriteDestination).l
                move.w  #$634,(Animation_ram_BaseTile).l
                move.w  #0,(Race_ram_SpriteSize1).l
                move.w  #0,(Race_ram_SpriteSize2).l
                move.l  #ram_FF3FDC,(Race_ram_CurrentVScrollInfo).l
                move.l  #ram_FF425C,(Race_ram_NextVScrollInfo).l
                move.l  #Intro_TitleScrollTable,(Race_ram_CurrentHScrollTable).l
                move.l  #Intro_TitleScrollTable,(Race_ram_NextScrollTable).l
                move.l  #Intro_TitleScrollTable + $400,(Race_ram_NextSpriteAttributeTable).l
                move.l  #Intro_TitleScrollTable + $400,(Race_ram_CurrentSpriteAttributeTable).l
                move.l  #0,(RaceBike_ram_CurrentSteering).l
                move.l  #Race_ram_FrameReady,(Race_ram_CurrentFrameReady).l
                move.l  #Race_ram_FrameReady,(Race_ram_NextFrameReady).l
                move.l  #Race_ram_Alpha1,(Race_ram_CurrentAlpha).l
                move.l  #Race_ram_Alpha1,(Race_ram_NextAlpha).l
                move.l  #Race_ram_Alpha3,(Race_ram_NextNextAlpha).l
                move.l  #Menu_ram_FrameBuffer,(Race_ram_CurrentHudBuffer).l
                move.l  #Menu_ram_FrameBuffer,(Race_ram_NextHudBuffer).l
                move.l  #Intro_ram_ImageBuffer,(Race_ram_CurrentSpriteTileArray).l
                move.l  #Race_ram_SpriteSize1,(Race_ram_CurrentSpriteSizePtr).l
                move.l  #Race_ram_SpriteSize1,(Race_ram_NextSpriteSizePtr).l
                move.l  #0,(ram_FFD340).l
                move.w  #0,(ram_FFD344).l
                move.w  #0,(ram_FFD346).l
                move.w  #0,(Race_ram_NumSprites).l
                move.w  #0,(Animation_ram_BaseTile).l
                move.w  #0,(ram_FFD34C).l
                move.w  #0,(ram_FFD34E).l
                move.w  #0,(ram_FFD350).l
                move.w  #0,(ram_FFD352).l
                move.w  #0,(ram_FFD354).l
                move.w  #0,(ram_FFD356).l
                move.w  #0,(ram_FFD358).l
                move.w  #0,(ram_FFD35A).l
                move.w  #$FFFF,(ram_FFD37C).l
                move.w  #0,(ram_FFD7C0).l
                move.w  #0,(ram_FFD7C2).l
                move.w  #0,(ram_FFD7C8).l
                move.w  #0,(ram_FFDE5E).l
                move.w  #0,(Animation_ram_TileIndex).l
                move.w  #0,(ram_FFDE62).l
                move.w  #0,(Animation_ram_SpriteIndex).l
                move.w  #0,(ram_FFDE66).l
                move.w  #0,(ram_FFDE68).l
                move.w  #0,(ram_FFDE6A).l
                move.w  #0,(ram_FFDE6C).l
                move.w  #0,(ram_FFDE6E).l
                move.w  #0,(ram_FFDE70).l
                move.w  #0,(ram_FFDE72).l
                move.w  #0,(ram_FFDE74).l
                move.w  #0,(ram_FFDE76).l
                move.w  #0,(ram_FFDE78).l
                move.w  #0,(ram_FFDE7A).l
                move.w  #0,(ram_FFDE7C).l
                move.w  #0,(ram_FF0520).l
                move.w  (Menu_ram_PlayerALevel).l,(Menu_ram_PlayerLevel).l
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_B6AC
                move.w  (Menu_ram_PlayerBLevel).l,(Menu_ram_PlayerLevel).l
.loc_B6AC:
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                lea     (unk_D19A).l,a4
                move.b  (a4,d0.w),(ram_FF1ADB).l
                rts
; End of function Race_InitVariables


; =============== S U B R O U T I N E =======================================


sub_B6C4:
                move.w  #0,(ram_FF1EA6).l
                move.w  #0,(ram_FF19C4).l
                move.w  #1,(ram_FF1A06).l
                lea     (unk_25856).l,a1
                lea     (ram_FF1A08).l,a2
                move.l  (a1),(a2)+

                adda.w  #$24,a1
                move.w  #6,d0
.loc_B6F2:
                addi.w  #1,(ram_FF1A06).l
                move.l  (a1)+,(a2)+
                dbf     d0,.loc_B6F2

                move.l  #$FFFFFFFF,(a2)
                lea     (ram_FF1982).l,a2
                move.w  #0,(a2)+
                lea     (unk_2585E).l,a1
                move.w  #6,d0
.loc_B71A:
                addi.w  #1,(ram_FF1982).l
                move.l  (a1)+,(a2)+
                dbf     d0,.loc_B71A
                rts
; End of function sub_B6C4


; =============== S U B R O U T I N E =======================================


sub_B72A:
                move.w  #7,d0
                lea     (ram_FF1A08).l,a0
                move.w  #$40,d1
                move.l  #$80000,d2
.loc_B73E:
                movea.l (a0)+,a1
                move.w  #$60,d3
                add.w   d1,d3
                move.w  d3,0.w(a1)
                move.w  d3,$1A(a1)
                move.w  d3,$30(a1)
                move.l  d2,4(a1)
                move.l  d2,$1E(a1)
                neg.w   d1
                btst    #0,d0
                bne.w   .loc_B76A
                addi.l  #$30000,d2
.loc_B76A:
                dbf     d0,.loc_B73E
                rts
; End of function sub_B72A


; =============== S U B R O U T I N E =======================================


sub_B770:
                move.w  #$20,(ram_FF1AC8).l
                move.w  #$20,(ram_FF1ACA).l
                move.w  #8,d0
                lea     (unk_257D0).l,a0
                lea     (ram_FF1AB6).l,a1
.loc_B790:
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_B790
                lea     (unk_25802).l,a0
                lea     (ram_FFD330).l,a1
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                lea     (unk_2580A).l,a0
                lea     (ram_FFD338).l,a1
                move.l  (a0)+,(a1)+
                move.l  (a0),(a1)
                move.w  #$6000,(ram_FF1AE8).l
                move.w  #$3000,(ram_FF1AEA).l
                move.w  #$1800,(ram_FF1AEC).l
                move.w  #$1800,(ram_FF1AEE).l
                move.w  #$3000,(ram_FF1AF0).l
                move.w  #$4800,(ram_FF1AF2).l
                move.w  #$6000,(ram_FF1AF4).l
                move.w  #$1400,(ram_FF18B6).l
                move.w  #$10,(ram_FF18AC).l
                move.w  #$200,(ram_FF18AE).l
                move.w  #$500,(ram_FF18A8).l
                move.w  #$A00,(ram_FF18AA).l
                move.w  #$80,(ram_FF18B0).l
                move.w  #$400,(ram_FF18B2).l
                move.w  #$180,(ram_FF18B4).l
                move.w  #$48D0,(ram_FF1A9E).l
                move.w  #$80,(ram_FF1AA0).l
                rts
; End of function sub_B770


; =============== S U B R O U T I N E =======================================


sub_B840:
                lea     (unk_1471A).l,a0
                move.w  (Menu_ram_CurrentTrackId).l,d0
                asl.w   #2,d0
                adda.w  d0,a0
                move.w  (a0)+,(ram_FF302E).l
                move.w  (a0)+,(ram_FF3030).l
                move.w  (a0)+,(ram_FF3032).l
                move.w  (a0),(ram_FF3034).l
                rts
; End of function sub_B840


; =============== S U B R O U T I N E =======================================


Race_LoadBikeData:
                move.w  (Menu_ram_BikeIdPlayerA).l,d0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_B880
                move.w  (Menu_ram_BikeIdPlayerB).l,d0
.loc_B880:
                asl.w   #2,d0
                lea     (unk_25B50).l,a0
                movea.l (a0,d0.w),a0

                lea     (ram_FF1A70).l,a1
                move.w  #$12,d1
.loc_B896:
                move.w  (a0)+,(a1)+
                dbf     d1,.loc_B896

                asl.w   #2,d0
                lea     (unk_25AC4).l,a0
                move.w  (a0)+,(ram_FF1AA6).l
                move.w  (a0)+,(ram_FF1AAA).l
                move.w  (a0)+,(RaceBike_ram_ReturnToStraightPower).l
                move.w  (a0)+,(RaceBike_ram_SteeringPower).l
                move.w  (a0)+,(RaceBike_ram_MaxSteering).l
                move.w  (a0)+,(ram_FF1AB2).l
                move.w  (a0)+,(ram_FF1AB4).l
                rts
; End of function Race_LoadBikeData


; =============== S U B R O U T I N E =======================================


sub_B8D0:
                lea     (ram_FFD7D4).l,a1
                move.l  a1,(ram_FFD7CC).l
                lea     (ram_FFDBD8).l,a2
                move.l  a2,(ram_FFDBD4).l
                movea.l (RaceTrack_Data5).l,a0
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                asl.w   #1,d0
                lea     (word_B976).l,a3
                move.w  (a3,d0.w),d7
                lea     (word_B980).l,a3
                move.w  (a3,d0.w),d6
                lea     (off_B98A).l,a3
                asl.w   #1,d0
                movea.l (a3,d0.w),a3
                clr.w   d2
                clr.w   d3
.loc_B91C:
                move.l  (a0)+,d1
                cmp.l   #$FFFFFFFF,d1
                beq.w   .loc_B970
                jsr     (Rand_GetWord).l
                cmp.w   d7,d0
                bcs.s   .loc_B91C
                btst    #4,d1
                beq.w   .loc_B94A
                jsr     (Rand_GetWord).l
                andi.w  #$F,d0
                andi.w  #$FFF0,d1
                or.w    d0,d1
.loc_B94A:
                btst    #5,d1
                beq.w   .loc_B964
                move.b  (a3,d3.w),d4
                addq.w  #1,d3
                cmp.w   d6,d3
                bgt.s   .loc_B91C
                move.l  d1,(a2)+
                move.b  d4,-2(a2)
                bra.s   .loc_B91C
.loc_B964:
                addq.w  #1,d2
                cmp.w   #$FF,d2
                bgt.s   .loc_B91C
                move.l  d1,(a1)+
                bra.s   .loc_B91C
.loc_B970:
                move.l  d1,(a1)
                move.l  d1,(a2)
                rts
; End of function sub_B8D0


word_B976:
    dc.w $CCCC, $B333, $9999, $8000, $6666
word_B980:
    dc.w 1, 2, 3, 4, 4
off_B98A:      
    dc.l byte_B99E, byte_B9A0, byte_B9A2, byte_B9A6, byte_B9AA
byte_B99E:
    dc.b 2, 0      
byte_B9A0:
    dc.b 1, 3      
byte_B9A2:
    dc.b 1, 2, 4, 0
byte_B9A6:
    dc.b 1, 2, 3, 5
byte_B9AA:
    dc.b 1, 2, 3, 4

; =============== S U B R O U T I N E =======================================


Race_ResetFrameTimers:
                move.w  (Race_ram_FrameCounter).l,d1
                beq.w   .return
; rendering frame took more than 1 tick
                move.w  d1,(Race_ram_FrameDelay).l
                moveq   #60,d0
                divu.w  d1,d0
                move.w  d0,(ram_FF304C).l
                move.w  #0,(Race_ram_FrameCounter).l
                addi.w  #1,(ram_FF304E).l
                add.w   d1,(ram_FF3050).l
                cmp.w   #60,d1
                bmi.w   .return

                move.w  (ram_FF304E).l,(ram_FF304C).l
                move.w  #0,(ram_FF304E).l
                move.w  #0,(ram_FF3050).l
.return:
                rts
; End of function Race_ResetFrameTimers


; =============== S U B R O U T I N E =======================================


Race_UpdateTime:
                addi.l  #1,(ram_FF1E96).l
                btst    #7,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .return

                addi.w  #1,(Race_ram_TimeTicks).l
                cmpi.w  #60,(Race_ram_TimeTicks).l
                bmi.w   .return
                move.w  #0,(Race_ram_TimeTicks).l

                move.b  (Race_ram_TimeSeconds).l,d1
                move.w  #1,d0
                abcd    d0,d1
                move.b  d1,(Race_ram_TimeSeconds).l
                cmp.b   #$60,d1
                bmi.w   .return
                move.b  #0,(Race_ram_TimeSeconds).l

                move.b  (Race_ram_TimeMinutes).l,d1
                abcd    d0,d1
                move.b  d1,(Race_ram_TimeMinutes).l
                cmp.b   #$60,d1
                bmi.w   .return
                move.b  #0,(Race_ram_TimeMinutes).l
.return:
                rts
; End of function Race_UpdateTime


; =============== S U B R O U T I N E =======================================


Race_GameTick:
                tst.w   (Race_ram_FrameDelay).l
                bne.w   .loc_BA88
                move.w  #1,(Race_ram_FrameDelay).l
.loc_BA88:
                tst.w   (Race_ram_State).l
                bne.w   .loc_BA9E
; running state
                addi.w  #1,(Race_ram_FrameCounter).l
                bsr.w   Race_UpdateTime
.loc_BA9E:
                lea     (VdpCtrl).l,a0
                lea     (VdpData).l,a1
                movea.l (Race_ram_NextVScrollInfo).l,a2
                move.w  (a2),(a0)
                move.w  4(a2),(a0)
                VDP_VSRAM_WRITE $0,(a0)
                move.l  6(a2),(a1)
                move.w  $A(a2),(ram_FF0406).l
                move.l  $C(a2),(a0)

                move.w  #-1,(ram_FF369E).l
                tst.w   (Race_ram_State).l
                bmi.w   .loc_BAE6
                move.w  #0,(ram_FF369E).l
.loc_BAE6:
                movea.l (Race_ram_NextFrameReady).l,a2
                tst.w   (a2)
                beq.w   .frameDrawn
; render next frame
                movea.l (Race_ram_NextSpriteSizePtr).l,a3
                cmpi.w  #0,(a3)
                beq.w   .loc_BB0A
; first write sprites, then everything else
                jsr     (Race_WriteSpriteTiles).l
                bra.w   .endDrawing
.loc_BB0A:
; write window plane with extra line (29 lines in total)
                move.l  (Race_ram_NextHudBuffer).l,d0
                move.w  #$3000,d1
                move.w  #$740,d2
                jsr     (DmaWriteVRAM).l
; write horizontal scroll table and sprite attribute table
                move.l  (Race_ram_NextScrollTable).l,d0
                move.w  #$C000,d1
                move.w  #$340,d2
                jsr     (DmaWriteVRAM).l

                tst.w   (Race_ram_State).l
                bmi.w   .loc_BB50
; write palette
                move.l  (Global_ram_PalettePtr).l,d0
                move.w  #0,d1
                move.w  #$40,d2
                jsr     (DmaWriteCRAM).l
.loc_BB50:
                jsr     (Race_SwapFrames).l
                jsr     (Race_ResetFrameTimers).l
                bra.w   .endDrawing
.frameDrawn:
                tst.w   (Race_ram_State).l
                beq.w   .endDrawing
; refresh hud in paused state, maybe just debug info?
                move.l  (Race_ram_NextHudBuffer).l,d0
                move.w  #$3000,d1
                move.w  #$700,d2
                jsr     (DmaWriteVRAM).l
.endDrawing:
                clr.l   d0
                move.w  (ram_FF36A2).l,d0
                add.l   d0,(ram_FF36A4).l
                tst.w   (MainMenu_ram_DemoMode).l
                beq.w   .loc_BBC8
; demo mode
                addi.w  #1,(MainMenu_ram_FrameCounter).l
                cmpi.w  #3600,(MainMenu_ram_FrameCounter).l
                bmi.w   .loc_BBBE
                move.w  #1,(Race_ram_DemoGameEnded).l
                move.w  #1,(Race_ram_GameEnded).l
                bra.w   .loc_BBCE
.loc_BBBE:
                jsr     (Race_GetInputDemo).l
                bra.w   .loc_BBCE
.loc_BBC8:
                jsr     (Race_GetInput).l
.loc_BBCE:
                tst.w   (Race_ram_DemoGameEnded).l
                beq.w   .return
                jsr     (AudioFunc7).l
                jsr     (AudioFunc10).l
                jsr     (AudioFunc13).l
                move.l  #0,(ram_UpdateFunction).l
                move.w  #-1,(ram_FF369E).l
.return:
                rts
; End of function Race_GameTick


; =============== S U B R O U T I N E =======================================


Race_SwapFrames:
                movea.l (Race_ram_NextFrameReady).l,a2
                move.w  #0,(a2)
                cmpa.l  #Race_ram_FrameReady,a2
                bne.w   .evenFrame
                move.l  #Intro_TitleScrollSpeed,d0
                move.l  d0,(Race_ram_NextScrollTable).l
                addi.l  #$400,d0
                move.l  d0,(Race_ram_NextSpriteAttributeTable).l
                move.l  #Menu_ram_FrameBuffer2,(Race_ram_NextHudBuffer).l
                move.l  #Race_ram_FrameReady2,(Race_ram_NextFrameReady).l
                move.l  #Race_ram_SpriteSize2,(Race_ram_NextSpriteSizePtr).l
                move.l  #Race_ram_ImageBuffer2,(Race_ram_NextSpriteTileArray).l
                move.w  #$C680,(Race_ram_SpriteDestination).l
                bra.w   .loc_BCA6
.evenFrame:
                move.l  #Intro_TitleScrollTable,d0
                move.l  d0,(Race_ram_NextScrollTable).l
                addi.l  #$400,d0
                move.l  d0,(Race_ram_NextSpriteAttributeTable).l
                move.l  #Menu_ram_FrameBuffer,(Race_ram_NextHudBuffer).l
                move.l  #Race_ram_FrameReady,(Race_ram_NextFrameReady).l
                move.l  #Race_ram_SpriteSize1,(Race_ram_NextSpriteSizePtr).l
                move.l  #Intro_ram_ImageBuffer,(Race_ram_NextSpriteTileArray).l
                move.w  #$8680,(Race_ram_SpriteDestination).l
.loc_BCA6:
                movea.l (Race_ram_NextNextAlpha).l,a2
                cmpa.l  #Race_ram_Alpha3,a2
                beq.w   .loc_BD04
                cmpa.l  #Race_ram_Alpha2,a2
                beq.w   .loc_BCE2
                move.l  #Race_ram_Alpha3,(Race_ram_NextAlpha).l
                move.l  #Race_ram_Alpha2,(Race_ram_NextNextAlpha).l
                move.l  #ram_FF411C,(Race_ram_NextVScrollInfo).l
                bra.w   .locret_BD22
.loc_BCE2:
                move.l  #Race_ram_Alpha1,(Race_ram_NextAlpha).l
                move.l  #Race_ram_Alpha3,(Race_ram_NextNextAlpha).l
                move.l  #ram_FF425C,(Race_ram_NextVScrollInfo).l
                bra.w   .locret_BD22
.loc_BD04:
                move.l  #Race_ram_Alpha2,(Race_ram_NextAlpha).l
                move.l  #Race_ram_Alpha1,(Race_ram_NextNextAlpha).l
                move.l  #ram_FF3FDC,(Race_ram_NextVScrollInfo).l
.locret_BD22:
                rts
; End of function Race_SwapFrames


; =============== S U B R O U T I N E =======================================


Race_FinishFrame:
                movea.l (Race_ram_CurrentFrameReady).l,a2
                move.w  #1,(a2)
                cmpa.l  #Race_ram_FrameReady,a2
                bne.w   .loc_BD84
                move.l  #Intro_TitleScrollSpeed,d0
                move.l  d0,(Race_ram_CurrentHScrollTable).l
                addi.l  #$400,d0
                move.l  d0,(Race_ram_CurrentSpriteAttributeTable).l
                move.l  #Menu_ram_FrameBuffer2,(Race_ram_CurrentHudBuffer).l
                move.l  #Race_ram_FrameReady2,(Race_ram_CurrentFrameReady).l
                move.l  #Race_ram_ImageBuffer2,(Race_ram_CurrentSpriteTileArray).l
                move.l  #Race_ram_SpriteSize2,(Race_ram_CurrentSpriteSizePtr).l
                move.w  #$634,(Animation_ram_BaseTile).l ; address $C680
                bra.w   .loc_BDCC
.loc_BD84:
                move.l  #Intro_TitleScrollTable,d0
                move.l  d0,(Race_ram_CurrentHScrollTable).l
                addi.l  #$400,d0
                move.l  d0,(Race_ram_CurrentSpriteAttributeTable).l
                move.l  #Menu_ram_FrameBuffer,(Race_ram_CurrentHudBuffer).l
                move.l  #Race_ram_FrameReady,(Race_ram_CurrentFrameReady).l
                move.l  #Intro_ram_ImageBuffer,(Race_ram_CurrentSpriteTileArray).l
                move.l  #Race_ram_SpriteSize1,(Race_ram_CurrentSpriteSizePtr).l
                move.w  #$434,(Animation_ram_BaseTile).l ; address $8680
.loc_BDCC:
                movea.l (Race_ram_CurrentAlpha).l,a2
                cmpa.l  #Race_ram_Alpha3,a2
                beq.w   .loc_BE16
                cmpa.l  #Race_ram_Alpha2,a2
                beq.w   .loc_BDFE
                move.l  #Race_ram_Alpha2,(Race_ram_CurrentAlpha).l
                move.l  #ram_FF411C,(Race_ram_CurrentVScrollInfo).l
                bra.w   .return
.loc_BDFE:
                move.l  #Race_ram_Alpha3,(Race_ram_CurrentAlpha).l
                move.l  #ram_FF425C,(Race_ram_CurrentVScrollInfo).l
                bra.w   .return
.loc_BE16:
                move.l  #Race_ram_Alpha1,(Race_ram_CurrentAlpha).l
                move.l  #ram_FF3FDC,(Race_ram_CurrentVScrollInfo).l
.return:
                rts
; End of function Race_FinishFrame

; *************************************************
; Function Race_GetInputDemo
; *************************************************

Race_GetInputDemo:
                jsr     (GetInputPlayerA).w
                cmp.b   #0,d0
                bne.w   .anyButtonPressed
                jsr     (GetInputPlayerB).w
                cmp.b   #0,d0
                beq.w   .return
.anyButtonPressed:
                move.w  #1,(Race_ram_GameEnded).l
                move.w  #1,(Race_ram_DemoGameEnded).l
.return:
                rts
; End of function Race_GetInputDemo

; *************************************************
; Function Race_GetInput
; *************************************************

Race_GetInput:
                tst.b   (Race_ram_ActiveController).l
                bne.w   .loc_BE68
                jsr     (GetInputPlayerA).w
                bra.w   .loc_BE6C
.loc_BE68:
                jsr     (GetInputPlayerB).w
.loc_BE6C:
                move.b  d0,(Race_ram_CurrentButtons).l ; button state (SACBRLDU)
                cmp.b   #0,d0
                beq.w   .nothingPressed
                btst    #0,d0 ; check Up
                beq.w   .loc_BE82
.loc_BE82:
                btst    #1,d0 ; check Down
                beq.w   .loc_BE8A
.loc_BE8A:
                btst    #2,d0 ; check Left
                beq.w   .loc_BECA
; Left pressed
                move.w  (RaceBike_ram_SteeringPower).l,d1
                tst.w   (RaceBike_ram_CurrentSteering).l
                bmi.w   .loc_BEA8
                add.w   (RaceBike_ram_ReturnToStraightPower).l,d1
.loc_BEA8:
                sub.w   d1,(RaceBike_ram_CurrentSteering).l
                move.w  (RaceBike_ram_MaxSteering).l,d1
                neg.w   d1
                cmp.w   (RaceBike_ram_CurrentSteering).l,d1
                bmi.w   .loc_BF24
                move.w  d1,(RaceBike_ram_CurrentSteering).l
                bra.w   .loc_BF24
.loc_BECA:
                btst    #3,d0 ; check Right
                beq.w   .loc_BF08
; Right pressed
                move.w  (RaceBike_ram_SteeringPower).l,d1
                tst.w   (RaceBike_ram_CurrentSteering).l
                bpl.w   .loc_BEE8
                add.w   (RaceBike_ram_ReturnToStraightPower).l,d1
.loc_BEE8:
                add.w   d1,(RaceBike_ram_CurrentSteering).l
                move.w  (RaceBike_ram_MaxSteering).l,d1
                cmp.w   (RaceBike_ram_CurrentSteering).l,d1
                bpl.w   .loc_BF24
                move.w  d1,(RaceBike_ram_CurrentSteering).l
                bra.w   .loc_BF24
.loc_BF08:
                move.w  (RaceBike_ram_ReturnToStraightPower).l,d1
                tst.w   (RaceBike_ram_CurrentSteering).l
                beq.w   .loc_BF24
                bmi.w   .loc_BF1E
                neg.w   d1
.loc_BF1E:
                add.w   d1,(RaceBike_ram_CurrentSteering).l
.loc_BF24:
                btst    #4,d0 ; check B
                beq.w   .loc_BF38
                bset    #1,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bra.w   .loc_BF40
.loc_BF38:
                bclr    #1,(ram_FF1EAA + STRUCT_OFFSET_68).l
.loc_BF40:
                btst    #6,d0 ; check A
                beq.w   .loc_BF54
                bset    #2,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bra.w   .loc_BF5C
.loc_BF54:
                bclr    #2,(ram_FF1EAA + STRUCT_OFFSET_68).l
.loc_BF5C:
                btst    #5,d0 ; check C
                bne.w   .loc_BF68
                bra.w   .loc_BF6C
.loc_BF68:
                bra.w   .return
.loc_BF6C:
                btst    #7,d0 ; check Start
                beq.w   .return
                tst.w   (ram_FF368E).l
                bne.w   .return
                eori.w  #1,(Race_ram_State).l
                bne.w   .loc_BFA6
                move.w  #-1,(ram_FF3698).l
                tst.w   (ram_MusicEnabled).l
                beq.w   .loc_BFC6
                jsr     (AudioFunc18).l
                bra.w   .loc_BFC6
.loc_BFA6:
                move.w  #$16E,(ram_FF3698).l
                move.w  #0,(ram_FF369A).l
                tst.w   (ram_MusicEnabled).l
                beq.w   .loc_BFC6
                jsr     (AudioFunc4).l
.loc_BFC6:
                move.w  #1,(ram_FF368E).l
                bra.w   .return
.nothingPressed:
                move.w  (RaceBike_ram_ReturnToStraightPower).l,d1
                tst.w   (RaceBike_ram_CurrentSteering).l
                beq.w   .loc_BFF2
                bmi.w   .loc_BF1E
                neg.w   d1
                add.w   d1,(RaceBike_ram_CurrentSteering).l
                bcc.w   .loc_BFF2
.loc_BFF2:
                bclr    #1,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bclr    #2,(ram_FF1EAA + STRUCT_OFFSET_68).l
                move.w  #0,(ram_FF368E).l
.return:
                rts
; End of function Race_GetInput


; =============== S U B R O U T I N E =======================================


Race_Update:
                cmpi.w  #$20,(Race_ram_BikeDamage).l
                bmi.w   .loc_C056
                move.w  #0,(ram_FF369A).l
                move.w  #$171,(ram_FF3698).l
                tst.w   (ram_FF1B18).l
                beq.w   .loc_C04E
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,(ram_FF1B18).l
                bgt.w   .loc_C056
                move.w  #1,(Race_ram_GameEnded).l
                bra.w   .loc_C056
.loc_C04E:
                move.w  #480,(ram_FF1B18).l
.loc_C056:
                move.b  #0,(ram_FF1AD7).l
                move.b  #0,(ram_FF1AD6).l
                move.b  #0,(ram_FF1ADD).l
                move.w  (ram_FF1EAA + STRUCT_OFFSET_SPEED).l,d0
                jsr     (sub_F108).l
                jsr     (sub_16AF6).l
                tst.w   (ram_FF1B20).l
                beq.w   .loc_C15A
; race started ??
                jsr     (sub_160E2).l
                lea     (ram_FF1EAA).l,a1
                jsr     (sub_13EA0).l
                jsr     (sub_1383E).l
                lea     (ram_FF1EAA).l,a1
                jsr     (sub_13A92).l
                jsr     (sub_10E66).l
                jsr     (sub_13E94).l
                jsr     (sub_10DBE).l
                jsr     (sub_10DDA).l
                jsr     (sub_13BF4).l
                jsr     (sub_12868).l
                lea     (ram_FF2FAA).l,a1
                move.w  (ram_FF1B30).l,d0
                cmp.w   #$1C,d0
                bpl.w   .loc_C0F6
                tst.w   d0
                bpl.w   .loc_C106
                bclr    #6,$68(a1)
                bra.w   .loc_C10C
.loc_C0F6:
                btst    #6,$68(a1)
                bne.w   .loc_C106
                jsr     (sub_128E0).l
.loc_C106:
                jsr     (sub_12974).l
.loc_C10C:
                jsr     (sub_138CE).l
                jsr     (sub_1281E).l
                jsr     (sub_11C44).l
                jsr     (sub_11CC8).l
                jsr     (sub_1218C).l
                jsr     (sub_123A8).l
                jsr     (sub_E5EE).l
                jsr     (sub_12EA2).l
                jsr     (sub_13106).l
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                sub.w   (ram_FF1F2E).l,d0
                move.w  d0,(ram_FF3036).l
                jsr     (sub_1611A).l
.loc_C15A:
                jsr     (sub_DE9E).l
                movea.l (Race_ram_CurrentFrameReady).l,a0
                tst.w   (a0)
                bne.w   .return

                jsr     (sub_EDD0).l
                move.w  (ram_FF1E54).l,d1
                add.w   (ram_FF1E58).l,d1
                move.w  d1,(ram_FF1E50).l
                move.w  (ram_FF1E56).l,d1
                add.w   (ram_FF1E5A).l,d1
                move.w  d1,(ram_FF1E52).l

                lea     (ram_FF3A9C).l,a0
                lea     (ram_FF32FE).l,a1
                lea     (ram_FF3236).l,a2
                jsr     (PiecewiseLinearInterpolation).l

                lea     (Road_ram_XLeftArray).l,a0 ; target
                lea     (ram_FF329A).l,a1 ; values
                lea     (ram_FF3236).l,a2 ; indexes
                jsr     (PiecewiseLinearInterpolation).l

                lea     (Road_ram_MarkingXArray).l,a0 ; target
                lea     (ram_FF31D2).l,a1 ; values
                lea     (ram_FF3236).l,a2 ; indexes
                jsr     (PiecewiseLinearInterpolation).l

                lea     (Road_ram_XRightArray).l,a0 ; target
                lea     (ram_FF3362).l,a1 ; values
                lea     (ram_FF3236).l,a2 ; indexes
                jsr     (PiecewiseLinearInterpolation).l

                jsr     (Road_FillProfileTables).l
                jsr     (sub_E004).l
                move.w  #0,(ram_FFDE72).l
                jsr     (sub_FD96).l
                jsr     (sub_FB1E).l
                jsr     (sub_F40C).l
                move.w  (ram_FFDE72).l,(ram_FF1B48).l
                jsr     (sub_109B6).l
                move.w  (ram_FFDE72).l,d0
                sub.w   (ram_FF1B48).l,d0
                move.w  d0,(ram_FF1B4A).l
                jsr     (sub_FC0E).l
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  #$FFFFFFFF,(a6,d7.w)

                lea     (ram_FF1B50).l,a0
                lea     (ram_FF1C50).l,a1
                lea     (ram_FF1D50).l,a2
                jsr     (sub_10D46).l

                jsr     (sub_14E38).l
                jsr     (sub_DD84).l
                jsr     (sub_EC90).l

                clr.w   (Animation_ram_SpriteIndex).l
                clr.w   (Animation_ram_TileIndex).l
                jsr     (RaceHud_Draw).l

                jsr     (sub_942A).l
                jsr     (RoadMarking_Draw).l
                move.w  (Animation_ram_SpriteIndex).l,(Race_ram_NumSprites).l
                move.w  (Animation_ram_TileIndex).l,d0
                cmp.w   (Race_ram_NumSpriteTiles).l,d0
                bcs.w   .loc_C2C2
                move.w  d0,(Race_ram_NumSpriteTiles).l
.loc_C2C2:
                asl.w   #4,d0
                cmp.w   #$1900,d0
                bcs.w   .loc_C2D0
                move.w  #$1900,d0
.loc_C2D0:
                cmp.w   (ram_FF1B3E).l,d0
                bcs.w   .loc_C2E0
                move.w  d0,(ram_FF1B3E).l
.loc_C2E0:
                movea.l (Race_ram_CurrentSpriteSizePtr).l,a0
                move.w  d0,(a0)
                jsr     (sub_D9DA).l
                jsr     (sub_E494).l
                jsr     (Race_FinishFrame).l
.return:
                rts
; End of function Race_Update


; =============== S U B R O U T I N E =======================================


sub_C2FC:
                move.w  #$F,d0
                lea     (ram_FF0586).l,a1

.loc_C306:                               ; CODE XREF: sub_C2FC+10↓j
                move.l  #$7000FFFF,(a1)+
                dbf     d0,.loc_C306
                move.w  #0,d0

.loc_C314:                               ; CODE XREF: sub_C2FC+50↓j
                move.w  (a0)+,d1
                swap    d1
                move.w  d0,d1
                lea     (ram_FF0586).l,a1
                move.w  #$F,d2

.loc_C324:                               ; CODE XREF: sub_C2FC:@loc_C334↓j
                cmp.l   (a1)+,d1
                bpl.w   .loc_C334
                move.l  -4(a1),d3
                move.l  d1,-4(a1)
                move.l  d3,d1

.loc_C334:                               ; CODE XREF: sub_C2FC+2A↑j
                dbf     d2,.loc_C324
                addq.w  #1,d0
                cmp.w   #1,d0
                bne.w   .loc_C348
                addq.w  #1,d0
                lea     2(a0),a0

.loc_C348:                               ; CODE XREF: sub_C2FC+42↑j
                cmp.w   #$10,d0
                bmi.s   .loc_C314
                rts
; End of function sub_C2FC


; =============== S U B R O U T I N E =======================================


sub_C350:
                movem.l d0-d1/a1,-(sp)
                lea     (ram_FF0586).l,a1
                move.w  #$F,d0

.loc_C35E:                               ; CODE XREF: sub_C350+1E↓j
                move.l  (a1),d1
                tst.w   d1
                bmi.w   .loc_C372
                asl.w   #1,d1
                move.w  (a0,d1.w),d1
                move.l  d1,(a1)+
                dbf     d0,.loc_C35E

.loc_C372:                               ; CODE XREF: sub_C350+12↑j
                movem.l (sp)+,d0-d1/a1
                rts
; End of function sub_C350


; =============== S U B R O U T I N E =======================================


sub_C378:                               ; CODE XREF: sub_C3F8↓p
                move.w  #$F,d0
                lea     (ram_FF0586).l,a0

.loc_C382:                               ; CODE XREF: sub_C378+10↓j
                move.l  #$FFFFFFFF,(a0)+
                dbf     d0,.loc_C382
                lea     (ram_FF04C8).l,a0
                move.w  #0,d0

.loc_C396:                               ; CODE XREF: sub_C378+56↓j
                move.l  (a0)+,d1
                asl.l   #8,d1
                move.b  d0,d1
                lea     (ram_FF0586).l,a1
                move.w  #$F,d2

.loc_C3A6:                               ; CODE XREF: sub_C378:@loc_C3B6↓j
                cmp.l   (a1)+,d1
                bcc.w   .loc_C3B6
                move.l  -4(a1),d3
                move.l  d1,-4(a1)
                move.l  d3,d1

.loc_C3B6:                               ; CODE XREF: sub_C378+30↑j
                dbf     d2,.loc_C3A6
                addq.w  #1,d0
                cmp.w   #1,d0
                bne.w   .loc_C3CA
                addq.w  #1,d0
                lea     4(a0),a0

.loc_C3CA:                               ; CODE XREF: sub_C378+48↑j
                cmp.w   #$10,d0
                bmi.s   .loc_C396
                lea     (ram_FF0586).l,a0
                move.w  #$F,d0
                clr.w   d2

.loc_C3DC:                               ; CODE XREF: sub_C378+78↓j
                move.l  (a0),d1
                move.b  d1,d2
                asr.l   #8,d1
                bmi.w   .loc_C3EC
                divu.w  #6,d1
                swap    d1

.loc_C3EC:                               ; CODE XREF: sub_C378+6A↑j
                move.w  d2,d1
                move.l  d1,(a0)+
                dbf     d0,.loc_C3DC
                rts
; End of function sub_C378


; =============== S U B R O U T I N E =======================================

sub_C3F6:
                rts
; End of function sub_C3F6


; =============== S U B R O U T I N E =======================================


sub_C3F8:
                bsr.w   sub_C378
                lea     (ram_FF0586).l,a0
                tst.w   (Menu_ram_Player).l
                bne.w   .loc_C44E
                move.w  (ram_FF0522).l,d0
                subq.w  #1,d0
                bpl.w   .loc_C41A
                clr.w   d0
.loc_C41A:
                or.w    (ram_FF0520).l,d0
                move.w  d0,(ram_FF0522).l
                move.w  (Menu_ram_BikeIdPlayerA).l,d0
                lea     (Menu_ram_PlayerAPlaces).l,a1
                lea     (ram_FF0510).l,a2
                lea     (Menu_ram_MoneyPlayerA).l,a3
                lea     (ram_FF0526).l,a4
                lea     (Menu_ram_PlayerALevel).l,a6
                bra.w   .loc_C48C
.loc_C44E:
                move.w  (ram_FF0524).l,d0
                subq.w  #1,d0
                bpl.w   .loc_C45C
                clr.w   d0
.loc_C45C:
                or.w    (ram_FF0520).l,d0
                move.w  d0,(ram_FF0524).l
                move.w  (Menu_ram_BikeIdPlayerB).l,d0
                lea     (Menu_ram_PlayerBPlaces).l,a1
                lea     (ram_FF0514).l,a2
                lea     (Menu_ram_MoneyPlayerB).l,a3
                lea     (ram_FF0528).l,a4
                lea     (Menu_ram_PlayerBLevel).l,a6
.loc_C48C:
                move.w  #0,(ram_FF091A).l
                cmpi.w  #$FFFF,(ram_FF04C8).l
                bne.w   .loc_C4E2
                tst.w   (ram_FF1B1A).l
                beq.w   .loc_C4C0
                move.w  (Menu_ram_PlayerLevel).l,d0
                mulu.w  #$14,d0
                move.w  d0,(ram_FF091A).l
                sub.l   d0,(a3)
                bra.w   .loc_C4E2
.loc_C4C0:
                move.l  a3,-(sp)
                lea     (Shop_dPrices).l,a3
                asl.w   #1,d0
                move.w  (a3,d0.w),d0
                mulu.w  #$A,d0
                divu.w  #$64,d0
                ext.l   d0
                move.w  d0,(ram_FF091A).l
                movea.l (sp)+,a3
                sub.l   d0,(a3)
.loc_C4E2:
                move.w  #$FFFF,d0
                move.w  (Menu_ram_CurrentTrackId).l,d1
.loc_C4EC:
                addq.w  #1,d0
                move.l  (a0)+,d2
                tst.w   d2
                bne.s   .loc_C4EC
                move.w  d0,d2
                addq.w  #1,d2
                cmpi.w  #$FFFF,(ram_FF04C8).l
                bne.w   .loc_C506
                clr.w   d2
.loc_C506:
                move.l  d2,(ram_FF0592).l
                move.w  (a1,d1.w),d3
                tst.w   d3
                beq.w   .loc_C522
                tst.w   d2
                beq.w   .loc_C526
                cmp.w   d3,d2
                bpl.w   .loc_C526
.loc_C522:
                move.w  d2,(a1,d1.w)
.loc_C526:
                asl.w   #1,d2
                lea     (unk_D1A0).l,a0
                move.w  (a0,d2.w),d4
                mulu.w  (a6),d4
                add.l   d4,(a2)
                add.l   d4,(a3)
                move.w  (a1),(a4)
                beq.w   .loc_C58A
                cmpi.w  #4,(a4)
                bgt.w   .loc_C58A
                move.w  2(a1),(a4)
                beq.w   .loc_C58A
                cmpi.w  #4,(a4)
                bgt.w   .loc_C58A
                move.w  4(a1),(a4)
                beq.w   .loc_C58A
                cmpi.w  #4,(a4)
                bgt.w   .loc_C58A
                move.w  6(a1),(a4)
                beq.w   .loc_C58A
                cmpi.w  #4,(a4)
                bgt.w   .loc_C58A
                move.w  8(a1),(a4)
                beq.w   .loc_C58A
                cmpi.w  #4,(a4)
                bgt.w   .loc_C58A
                move.w  #4,(a4)
.loc_C58A:
                bsr.w   sub_C868
                bsr.w   sub_C598
                jsr     (MenuPassword_CreatePassword).w
                rts
; End of function sub_C3F8


; =============== S U B R O U T I N E =======================================


sub_C598:
                lea     (ram_FF05F2).l,a0
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a1
                lea     (HighScore_ram_PlayerATableOffset).l,a2
                move.w  (a2),d1
                adda.w  d1,a0
                move.l  (a1)+,(a0)
                move.l  (a1)+,4(a0)
                move.w  (a1)+,8(a0)
                lea     (ram_FF05F2).l,a0
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a1
                lea     (HighScore_ram_PlayerBTableOffset).l,a2
                move.w  (a2),d1
                adda.w  d1,a0
                move.l  (a1)+,(a0)
                move.l  (a1)+,4(a0)
                move.w  (a1)+,8(a0)
                lea     (ram_FF05F2).l,a0
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a1
                lea     (HighScore_ram_PlayerATableOffset).l,a2
                move.l  (ram_FF0510).l,d0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_C60C
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a1
                lea     (HighScore_ram_PlayerBTableOffset).l,a2
                move.l  (ram_FF0514).l,d0
.loc_C60C:
                move.w  (a2),d1
                adda.w  d1,a0
                move.l  (a1)+,(a0)
                move.l  (a1)+,4(a0)
                move.w  (a1)+,8(a0)
                move.l  #'    ',$A(a0)
                move.l  #'    ',$E(a0)
                movem.l d1/a0,-(sp)
                adda.w  #$14,a0
                jsr     (sub_C6C4).l
                movem.l (sp)+,d1/a0
                lea     (HighScore_ram_PlayerATableOffset).l,a0
                cmpa.l  a2,a0
                bne.w   .loc_C64E
                lea     (HighScore_ram_PlayerBTableOffset).l,a0
.loc_C64E:
                subi.w  #$14,d1
                bmi.w   .locret_C6C2
                lea     (ram_FF05F2).l,a1
                lea     $A(a1,d1.w),a1
                move.w  #9,d0
.loc_C664:
                move.b  $14(a1),d2
                cmp.b   (a1)+,d2
                bmi.w   .locret_C6C2
                bgt.w   .loc_C67A
                dbf     d0,.loc_C664
                bra.w   .locret_C6C2
.loc_C67A:
                cmp.w   (a0),d1
                bne.w   .loc_C682
                move.w  (a2),(a0)
.loc_C682:
                move.w  d1,(a2)
                lea     (ram_FF05F2).l,a1
                lea     (a1,d1.w),a1
                move.l  $14(a1),d2
                move.l  (a1),$14(a1)
                move.l  d2,(a1)+
                move.l  $14(a1),d2
                move.l  (a1),$14(a1)
                move.l  d2,(a1)+
                move.l  $14(a1),d2
                move.l  (a1),$14(a1)
                move.l  d2,(a1)+
                move.l  $14(a1),d2
                move.l  (a1),$14(a1)
                move.l  d2,(a1)+
                move.l  $14(a1),d2
                move.l  (a1),$14(a1)
                move.l  d2,(a1)+
                bra.s   .loc_C64E
.locret_C6C2:
                rts
; End of function sub_C598


; =============== S U B R O U T I N E =======================================


sub_C6C4:
                move.l  d0,-(sp)
                bpl.w   .loc_C6CC
                neg.l   d0
.loc_C6CC:
                move.w  d0,d1
                swap    d0
                mulu.w  #$A,d0
                swap    d0
                mulu.w  #$A,d1
                add.l   d1,d0
                divu.w  #$3E8,d0
                move.l  d0,d1
                clr.w   d1
                swap    d1
                andi.l  #$FFFF,d0
                move.b  #$30,-(a0)
                divu.w  #$A,d1
                swap    d1
                add.b   d1,(a0)
                clr.w   d1
                swap    d1
                bne.w   .loc_C706
                tst.l   d0
                beq.w   .loc_C78A
.loc_C706:
                move.b  #$30,-(a0)
                divu.w  #$A,d1
                swap    d1
                add.b   d1,(a0)
                clr.w   d1
                swap    d1
                bne.w   .loc_C720
                tst.l   d0
                beq.w   .loc_C78A
.loc_C720:
                move.b  #$30,-(a0)
                add.b   d1,(a0)
                tst.l   d0
                beq.w   .loc_C78A
                move.b  #$2C,-(a0)
                move.b  #$30,-(a0)
                divu.w  #$A,d0
                swap    d0
                add.b   d0,(a0)
                clr.w   d0
                swap    d0
                beq.w   .loc_C78A
                move.b  #$30,-(a0)
                divu.w  #$A,d0
                swap    d0
                add.b   d0,(a0)
                clr.w   d0
                swap    d0
                beq.w   .loc_C78A
                move.b  #$30,-(a0)
                divu.w  #$A,d0
                swap    d0
                add.b   d0,(a0)
                clr.w   d0
                swap    d0
                beq.w   .loc_C78A
                move.b  #$2C,-(a0)
                move.b  #$30,-(a0)
                divu.w  #$A,d0
                swap    d0
                add.b   d0,(a0)
                clr.w   d0
                swap    d0
                beq.w   .loc_C78A
                move.b  #$30,-(a0)
                add.b   d0,(a0)
.loc_C78A:
                move.b  #$24,-(a0)
                move.l  (sp)+,d0
                bpl.w   .locret_C798
                move.b  #$2D,-(a0)
.locret_C798:
                rts
; End of function sub_C6C4


; =============== S U B R O U T I N E =======================================


sub_C79A:
                move.l  d0,-(sp)
                bpl.w   .loc_C7A2
                neg.l   d0
.loc_C7A2:
                move.w  d0,d1
                swap    d0
                mulu.w  #$A,d0
                swap    d0
                mulu.w  #$A,d1
                add.l   d1,d0
                divu.w  #$3E8,d0
                move.l  d0,d1
                clr.w   d1
                swap    d1
                andi.l  #$FFFF,d0
                move.b  #$30,-(a0)
                divu.w  #$A,d1
                swap    d1
                add.b   d1,(a0)
                clr.w   d1
                swap    d1
                bne.w   .loc_C7DC
                tst.l   d0
                beq.w   .loc_C858
.loc_C7DC:
                move.b  #$30,-(a0)
                divu.w  #$A,d1
                swap    d1
                add.b   d1,(a0)
                clr.w   d1
                swap    d1
                bne.w   .loc_C7F6
                tst.l   d0
                beq.w   .loc_C858
.loc_C7F6:
                move.b  #$30,-(a0)
                add.b   d1,(a0)
                tst.l   d0
                beq.w   .loc_C858
                move.b  #$30,-(a0)
                divu.w  #$A,d0
                swap    d0
                add.b   d0,(a0)
                clr.w   d0
                swap    d0
                beq.w   .loc_C858
                move.b  #$30,-(a0)
                divu.w  #$A,d0
                swap    d0
                add.b   d0,(a0)
                clr.w   d0
                swap    d0
                beq.w   .loc_C858
                move.b  #$30,-(a0)
                divu.w  #$A,d0
                swap    d0
                add.b   d0,(a0)
                clr.w   d0
                swap    d0
                beq.w   .loc_C858
                move.b  #$30,-(a0)
                divu.w  #$A,d0
                swap    d0
                add.b   d0,(a0)
                clr.w   d0
                swap    d0
                beq.w   .loc_C858
                move.b  #$30,-(a0)
                add.b   d0,(a0)
.loc_C858:
                move.b  #$24,-(a0)
                move.l  (sp)+,d0
                bpl.w   .locret_C866
                move.b  #$2D,-(a0)
.locret_C866:
                rts
; End of function sub_C79A


; =============== S U B R O U T I N E =======================================


sub_C868:
                move.w (unk_D1C0 + 4).l,d0
                addq.w  #1,d0
                move.w (unk_D1C0 + 6).l,d1
                mulu.w  d1,d0
                addq.w  #7,d0
                lea     (unk_D1C0).l,a0
                lea     (ram_FF1414).l,a1
.loc_C886:
                move.b  (a0)+,(a1)+
                dbf     d0,.loc_C886
                lea     (ram_FF0586).l,a0
                lea     (ram_FF141C).l,a1
                move.w  $E(a0),d0
                beq.w   .loc_C8A8
                cmp.w   #3,d0
                ble.w   .loc_C8B0
.loc_C8A8:
                addi.w  #1,(ram_FF1418).l
.loc_C8B0:
                move.w  #0,$E(a0)
                move.w  (ram_FF141A).l,d1
                move.w  d1,d2
                asl.w   #1,d2
                add.w   d2,d1
                tst.w   d0
                beq.w   .loc_C8E2
                cmp.w   #$A,d0
                bmi.w   .loc_C8DA
                subi.w  #$A,d0
                move.b  #$31,(a1,d1.w)
.loc_C8DA:
                add.b   d0,1(a1,d1.w)
                bra.w   .loc_C8EE
.loc_C8E2:
                move.b  (dStringCodeTable + 2 * ' ').w,1(a1,d1.w)
                move.b  (dStringCodeTable + 2 * ' ').w,2(a1,d1.w)
.loc_C8EE:
                lea     (Menu_ram_PlayerAOpponents).l,a3
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_C904
                lea     (Menu_ram_PlayerBOpponents).l,a3
.loc_C904:
                lea     (unk_CCDA).l,a4
                move.w  #3,d3

.loc_C90E:                               ; CODE XREF: sub_C868+166↓j
                move.l  a0,-(sp)
                move.w  (a1),d0
                andi.w  #$FF,d0
                cmp.w   #$20,d0 ; ' '
                bne.w   .loc_C926
                move.w  #0,d0
                bra.w   .loc_C948


.loc_C926:                               ; CODE XREF: sub_C868+B2↑j
                subi.w  #$30,d0 ; '0'
                cmpi.b  #$31,(a1) ; '1'
                bne.w   .loc_C936
                addi.w  #$A,d0

.loc_C936:                               ; CODE XREF: sub_C868+C6↑j
                asl.w   #1,d0
                lea     (unk_D1A0).l,a0
                move.w  (a0,d0.w),d0
                mulu.w  (Menu_ram_PlayerLevel).l,d0

.loc_C948:                               ; CODE XREF: sub_C868+BA↑j
                movea.l a1,a0
                adda.w  (ram_FF141A).l,a0
                subq.w  #1,a0
                move.l  #'    ',-3(a0)
                move.l  #'    ',-7(a0)
                jsr     (sub_C79A).l
                movea.l (sp)+,a0
                clr.l   d0
                move.w  (a0)+,d0
                move.w  (a0)+,d1
                cmp.w   #$FFFF,d0
                bne.w   .loc_C98C
                move.l  #'   D',$E(a1)
                move.l  #'NF  ',$12(a1)
                bra.w   .loc_C990


.loc_C98C:                               ; CODE XREF: sub_C868+10C↑j
                bsr.w   sub_C9D4

.loc_C990:                               ; CODE XREF: sub_C868+120↑j
                tst.w   d1
                bne.w   .loc_C9B0
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a2
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_C9BC
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a2
                bra.w   .loc_C9BC


.loc_C9B0:                               ; CODE XREF: sub_C868+12A↑j
                asl.w   #1,d1
                move.w  (a3,d1.w),d1
                asl.w   #4,d1
                lea     6(a4,d1.w),a2

.loc_C9BC:                               ; CODE XREF: sub_C868+13A↑j
; sub_C868+144↑j
                move.l  (a2)+,4(a1)
                move.l  (a2)+,8(a1)
                move.w  (a2)+,$C(a1)
                adda.w  (ram_FF141A).l,a1
                dbf     d3,.loc_C90E
                rts
; End of function sub_C868


; =============== S U B R O U T I N E =======================================


sub_C9D4:                               ; CODE XREF: sub_C868:@loc_C98C↑p
                clr.l   d2
                move.w  d0,d2
                move.b  #$30,$15(a1) ; '0'
                divu.w  #$A,d2
                swap    d2
                add.b   d2,$15(a1)
                move.b  #$2E,$14(a1) ; '.'
                clr.w   d2
                swap    d2
                beq.w   .locret_CA4E
                divu.w  #$A,d2
                swap    d2
                move.b  #$30,$13(a1) ; '0'
                add.b   d2,$13(a1)
                clr.w   d2
                swap    d2
                beq.w   .locret_CA4E
                divu.w  #6,d2
                swap    d2
                move.b  #$30,$12(a1) ; '0'
                add.b   d2,$12(a1)
                clr.w   d2
                swap    d2
                beq.w   .locret_CA4E
                move.b  #$3A,$11(a1) ; ':'
                divu.w  #$A,d2
                swap    d2
                move.b  #$30,$10(a1) ; '0'
                add.b   d2,$10(a1)
                clr.w   d2
                swap    d2
                beq.w   .locret_CA4E
                move.b  #$30,$F(a1) ; '0'
                add.b   d2,$F(a1)

.locret_CA4E:                            ; CODE XREF: sub_C9D4+1E↑j
; sub_C9D4+36↑j ...
                rts
; End of function sub_C9D4


; =============== S U B R O U T I N E =======================================


sub_CA50:
                move.w  (Menu_ram_BikeIdPlayerA).l,d0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_CA66
                move.w  (Menu_ram_BikeIdPlayerB).l,d0
.loc_CA66:
                lea     (unk_25B70).l,a0
                asl.w   #1,d0
                move.w  (a0,d0.w),(ram_FF36C4).l
                asl.w   #4,d0
                lea     (Shop_dBikePalettes).l,a0
                lea     (a0,d0.w),a0
                movea.l (Global_ram_PalettePtr).l,a1
                move.w  #7,d0
.loc_CA8C:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_CA8C
                move.w  (Menu_ram_PlayerALevel).l,d0
                subq.w  #1,d0
                lea     (unk_259B6).l,a4
                asl.w   #1,d0
                move.w  (a4,d0.w),d0
                move.w  d0,(ram_FF1A96).l
                rts
; End of function sub_CA50


; =============== S U B R O U T I N E =======================================


sub_CAAE:
                asl.w   #5,d0
                lea     (unk_7E470).l,a0
                adda.w  d0,a0
                movea.l (Global_ram_PalettePtr).l,a1
                adda.l  #$40,a1
                move.w  #7,d0
.loc_CAC8:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_CAC8
                rts
; End of function sub_CAAE


; =============== S U B R O U T I N E =======================================


Race_CreateActors:
                clr.l   d0
                move.l  #$8000,(ram_FF1E76).l
                move.w  #0,(ram_FF1E94).l
                lea     (unk_25856).l,a0 ; get actor list
                lea     (Menu_ram_PlayerAOpponents).l,a3
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_CB00
                lea     (Menu_ram_PlayerBOpponents).l,a3
.loc_CB00:
                lea     (unk_258EE).l,a4
                move.w  #0,d0
                move.w  #0,d1
.loopCreateActor:
                movea.l (a0)+,a1 ; get actor memory pointer
                cmpa.l  #$FFFFFFFF,a1 ; we reached the end of the list
                beq.w   .break

                move.b  d0,STRUCT_OFFSET_INDEX(a1) ; set actor index
                addq.w  #1,d0 ; increment index
                move.w  (a3)+,d2 ; get actor id
                lea     (unk_CCDA).l,a2
                asl.w   #4,d2
                lea     (a2,d2.w),a2 ; load actor definition
                clr.w   d2
                move.b  (a2)+,d2
                move.w  d2,STRUCT_OFFSET_16(a1)
                move.b  (a2)+,STRUCT_OFFSET_74(a1)
                bclr    #1,STRUCT_OFFSET_6B(a1)
                move.b  (a2)+,d2
                bpl.w   .loc_CB50
                andi.b  #$7F,d2
                bset    #1,STRUCT_OFFSET_6B(a1)
.loc_CB50:
                move.b  d2,STRUCT_OFFSET_75(a1)
                ext.w   d2
                asl.w   #2,d2
                movea.l (a4,d2.w),a5
                move.w  $A(a5),STRUCT_OFFSET_5E(a1)
                move.w  $C(a5),STRUCT_OFFSET_60(a1)
                move.w  $E(a5),STRUCT_OFFSET_5C(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_CB80
                move.w  (ram_FF18AA).l,STRUCT_OFFSET_5C(a1)
.loc_CB80:
                move.b  (a2)+,STRUCT_OFFSET_73(a1)
                move.b  (a2)+,STRUCT_OFFSET_77(a1)
                move.b  (a2)+,d1
                ext.w   d1
                mulu.w  #100,d1
                move.w  d1,STRUCT_OFFSET_66(a1)
                move.b  #$FF,STRUCT_OFFSET_6E(a1)
                clr.l   d1
                move.w  d1,STRUCT_OFFSET_POSX_LOW(a1)
                move.w  d1,STRUCT_OFFSET_POSZ(a1)
                move.w  d1,STRUCT_OFFSET_1C(a1)
                move.w  d1,STRUCT_OFFSET_32(a1)
                move.w  d1,STRUCT_OFFSET_8(a1)
                move.w  d1,STRUCT_OFFSET_A(a1)
                move.w  d1,STRUCT_OFFSET_C(a1)
                move.w  d1,STRUCT_OFFSET_46(a1)
                move.w  d1,STRUCT_OFFSET_2C(a1)
                move.w  d1,STRUCT_OFFSET_22(a1)
                move.w  d1,STRUCT_OFFSET_24(a1)
                move.l  d1,STRUCT_OFFSET_26(a1)
                move.w  d1,STRUCT_OFFSET_36(a1)
                move.w  d1,STRUCT_OFFSET_3A(a1)
                move.w  d1,STRUCT_OFFSET_38(a1)
                move.w  d1,STRUCT_OFFSET_3C(a1)
                move.w  d1,STRUCT_OFFSET_SPEED(a1)
                move.w  d1,STRUCT_OFFSET_14(a1)
                move.w  d1,STRUCT_OFFSET_GEAR(a1)
                move.b  d1,STRUCT_OFFSET_68(a1)
                move.b  d1,STRUCT_OFFSET_69(a1)
                move.b  d1,STRUCT_OFFSET_6A(a1)
                move.b  d1,STRUCT_OFFSET_72(a1)
                move.b  #$FF,STRUCT_OFFSET_6F(a1)
                move.b  d1,STRUCT_OFFSET_78(a1)
                move.w  #$FFFF,STRUCT_OFFSET_56(a1)
                bra.w   .loopCreateActor
.break:
                clr.w   d0
                move.b  (ram_FF2421).l,d0
                jsr     (sub_CAAE).l
                move.w  (ram_FF18B2).l,(ram_FF1EAA + STRUCT_OFFSET_5E).l
                move.w  (ram_FF18B4).l,(ram_FF1EAA + STRUCT_OFFSET_60).l
                move.w  #$F060,(ram_FF2EAE).l
                move.w  #$FA0,(ram_FF2F2E).l
                move.w  #$1700,(ram_FF2EBC).l
                move.w  #$70,(ram_FF2EAA).l
                move.w  #$70,(ram_FF2EDA).l
                move.b  #2,(ram_FF2F1D).l
                move.w  #$1B00,(ram_FF2F3C).l
                move.w  #$FF90,(ram_FF2F2A).l
                move.w  #$FF90,(ram_FF2F5A).l
                move.b  #0,(ram_FF2F9D).l
                lea     (unk_2589A).l,a0
                move.b  #$10,d0
.loc_CC88:
                movea.l (a0)+,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_CCC6
                move.b  d0,$71(a1)
                move.w  #$10,$16(a1)
                move.b  #0,$74(a1)
                move.b  #0,$75(a1)
                move.b  #0,$68(a1)
                move.b  #0,$69(a1)
                move.b  #0,$6A(a1)
                move.w  #$FFFF,$56(a1)
                addq.w  #1,d0
                bra.s   .loc_CC88
.loc_CCC6:
                move.b  #$12,(ram_FF301B).l
                rts
; End of function Race_CreateActors


unk_CCD0:
    dc.w 0, 15, 30, 45, 60
unk_CCDA:
    dc.b    2,  1,   5, 0,  3, 100, "O'Leary   "
    dc.b    4, 11, 130, 2,  3,  93, "Viper     "
    dc.b    4,  7,   1, 2,  3,  92, "Shiva     "
    dc.b    3, 16, 131, 2,  3,  91, "Natasha   "
    dc.b    3,  9,   1, 2,  3,  90, "Slater    "
    dc.b    3, 18, 130, 2,  3,  88, "Biff      "
    dc.b    3,  6,   1, 2,  3,  78, "Rex       "
    dc.b    3, 11,   1, 2,  3,  77, "Lester    "
    dc.b    2,  6,   1, 2,  3,  70, "Rude Boy  "
    dc.b    2,  8,   0, 2,  3,  71, "Grubb     "
    dc.b    2,  6,   0, 2,  3,  72, "Gunther   "
    dc.b    3,  6,   0, 2,  3,  73, "Sid       "
    dc.b    3,  9,   0, 2,  3,  74, "Axle      "
    dc.b    3,  8, 128, 2,  3,  75, "Hammer    "
    dc.b    3,  8,   1, 2,  3,  76, "Dread     "

    dc.b    2,  1,   5, 0,  5, 100, "O'Rourke  "
    dc.b    5,  4, 130, 2,  5, 100, "Hoghide   "
    dc.b    5,  2,   3, 2,  5,  99, "Ikira     "
    dc.b    4, 16, 131, 2,  5,  98, "Natasha   "
    dc.b    4,  3,   2, 2,  5,  97, "Butch     "
    dc.b    4, 14,   1, 2,  5,  95, "Angel     "
    dc.b    4, 18, 130, 2,  5,  93, "Biff      "
    dc.b    4, 11, 129, 2,  5,  91, "Viper     "
    dc.b    3,  7, 128, 2,  5,  80, "BroomHelga"
    dc.b    3,  9,   0, 2,  5,  81, "Axle      "
    dc.b    4,  6,   1, 2,  5,  82, "Rex       "
    dc.b    3, 11,   1, 2,  5,  83, "Lester    "
    dc.b    4,  7,   2, 2,  5,  84, "Shiva     "
    dc.b    4,  9,   1, 2,  5,  85, "Slater    "
    dc.b    4,  8, 129, 2,  5,  86, "Dread     "

    dc.b    5,  1,   5, 0, 10, 100, "Flynn     "
    dc.b    5,  2,   2, 2, 10, 105, "Chip      "
    dc.b    6,  6, 131, 2, 10, 104, "Natasha   "
    dc.b    8,  5,   1, 2, 10, 103, "Sergio    "
    dc.b    5,  2,   3, 2, 10, 102, "Ikira     "
    dc.b    5, 10,   2, 2, 10, 101, "Spike     "
    dc.b    6,  4, 129, 2, 10, 100, "Zippy     "
    dc.b    6,  2,   1, 2, 10,  99, "Butch     "
    dc.b    4,  8, 129, 2, 10,  90, "Dread     "
    dc.b    4,  9,   1, 2, 10,  91, "Slater    "
    dc.b    4, 14, 130, 2, 10,  92, "Hoghide   "
    dc.b    5, 14,   2, 2, 10,  93, "Angel     "
    dc.b    5, 10, 130, 2, 10,  94, "Otis      "
    dc.b    6,  8, 130, 2, 10,  95, "Biff      "
    dc.b    5, 11, 130, 2, 10,  96, "Viper     "

    dc.b    7,  1,   5, 0,  7, 110, "O'Shea    "
    dc.b    9, 14, 132, 2,  7, 113, "Helldog   "
    dc.b    9, 15,   3, 2,  7, 111, "Sergio    "
    dc.b    9,  2, 131, 2,  7, 109, "Chip      "
    dc.b    7, 16, 131, 2,  7, 107, "Natasha   "
    dc.b    8, 13,   3, 2,  7, 105, "Butch     "
    dc.b    8,  2,   3, 2,  7, 103, "Ikira     "
    dc.b    8,  6,   3, 2,  7, 101, "Bob       "
    dc.b    6, 10, 130, 2,  7,  88, "Otis      "
    dc.b    6, 18, 130, 2,  7,  90, "Biff      "
    dc.b    8, 11, 131, 2,  7,  92, "Viper     "
    dc.b    8,  4, 130, 2,  7,  93, "Zippy     "
    dc.b    8,  4, 131, 2,  7,  95, "Hoghide   "
    dc.b    6, 14, 131, 2,  7,  97, "Luna      "
    dc.b    6,  6,   2, 2,  7,  99, "Spike     "

    dc.b    9,  1,   5, 0,  1, 120, "O'Connor  "
    dc.b   10,  2, 131, 2,  1, 115, "Chip      "
    dc.b   10, 14, 132, 2,  1, 113, "Helldog   "
    dc.b    9, 16, 132, 2,  1, 111, "Natasha   "
    dc.b    9, 15,   4, 2,  1, 109, "Sergio    "
    dc.b    9, 14, 131, 2,  1, 107, "Killjoy   "
    dc.b    7,  2,   4, 2,  1, 105, "Ikira     "
    dc.b    7,  6, 131, 2,  1, 103, "Bob       "
    dc.b    8, 11, 131, 2,  1,  90, "Viper     "
    dc.b    8,  4, 131, 2,  1,  91, "Zippy     "
    dc.b    8,  4, 131, 2,  1,  93, "Ollie     "
    dc.b    8, 14, 132, 2,  1,  95, "Luna      "
    dc.b    9,  4, 132, 2,  1,  97, "Hoghide   "
    dc.b    8, 16,   4, 2,  1,  99, "Spike     "
    dc.b    7,  6,   4, 2,  1, 101, "Butch     "

    dc.b    0,  0,   0, 0,  0,   0, "Player def"

unk_D19A:
    dc.b    4, 4, 3, 5, 4, 0

unk_D1A0:
    dc.w    0, 75, 50, 30, 20, 18, 16, 14, 12, 10, 8, 6, 4, 3, 2, 1

unk_D1C0:
    dc.w    17, 5, 3, 30
    dc.b    " 1. 1234567890                "
    dc.b    " 2. 1234567890                "
    dc.b    " 3. 1234567890                "
    dc.b    " 0. 1234567890                "
; ???    
    dc.b    " 1. 1234567890"
    dc.b    " 2. 1234567890"
    dc.b    " 3. 1234567890"
    dc.b    " 0. 1234567890"

    include "race_hud.asm"

; =============== S U B R O U T I N E =======================================


DmaWriteVRAM:
                move.w  #$9300,d3
                move.b  d2,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9400,d3
                lsr.w   #8,d2
                move.b  d2,d3
                move.w  d3,(VdpCtrl).l
                asr.l   #1,d0
                move.w  #$9500,d3
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9600,d3
                asr.l   #8,d0
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9700,d3
                asr.l   #8,d0
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  d1,d0
                rol.w   #2,d0
                andi.w  #3,d0
                ori.b   #$80,d0
                move.w  d0,(ram_FF14D8).l
                andi.w  #$3FFF,d1
                addi.w  #$4000,d1
                move.w  d1,(VdpCtrl).l
                move.w  (ram_FF14D8).l,(VdpCtrl).l
                rts
; End of function DmaWriteVRAM


; =============== S U B R O U T I N E =======================================

; d2 - DMA length
; d0 - DMA source
; d1 - DMA destination

DmaWriteCRAM:                           ; CODE XREF: Fade_GameTickWithInit+62↑p
; FadeWithFunction_GameTick+20↑p ...
                move.w  #$9300,d3
                move.b  d2,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9400,d3
                lsr.w   #8,d2
                move.b  d2,d3
                move.w  d3,(VdpCtrl).l
                asr.l   #1,d0
                move.w  #$9500,d3
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9600,d3
                asr.l   #8,d0
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  #$9700,d3
                asr.l   #8,d0
                move.b  d0,d3
                move.w  d3,(VdpCtrl).l
                move.w  d1,d0
                rol.w   #2,d0
                andi.w  #3,d0
                ori.b   #$80,d0
                move.w  d0,(ram_FF14D8).l
                andi.w  #$3FFF,d1
                addi.w  #-$4000,d1
                move.w  d1,(VdpCtrl).l
                move.w  (ram_FF14D8).l,(VdpCtrl).l
                rts
; End of function DmaWriteCRAM


; =============== S U B R O U T I N E =======================================
; draw road in rearview mirrors

sub_D9DA:
                movea.l (Global_ram_PalettePtr).l,a2
                move.l  $78(a2),d1
                move.w  $7C(a2),d1
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                btst    #0,d0
                bne.w   .loc_D9F8
                swap    d1
.loc_D9F8:
                move.l  d1,$70(a2)
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSY).l,d0
                subi.w  #$10,d0
                ext.l   d0
                divs.w  #$28,d0 ; '('
                move.w  d0,d1
                bge.w   .loc_DA14
                subq.w  #1,d1
.loc_DA14:
                move.w  #0,d0
                bsr.w   sub_DA3E
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSY).l,d0
                addi.w  #$10,d0
                ext.l   d0
                divs.w  #$28,d0 ; '('
                move.w  d0,d1
                bpl.w   .loc_DA34
                subq.w  #1,d1
.loc_DA34:
                move.w  #$20,d0 ; ' '
                bsr.w   sub_DA3E
                rts
; End of function sub_D9DA


; =============== S U B R O U T I N E =======================================


sub_DA3E:
                movea.l (Race_ram_CurrentHudBuffer).l,a1
                adda.l  #$C80,a1 ; x = 0, y = 25
                asl.w   #1,d0
                lea     (a1,d0.w),a1
                tst.w   d1
                bmi.w   .loc_DAA8
                lea     $10(a1),a1
                move.l  #$8000800,d2
                cmp.w   #$B,d1
                bmi.w   .loc_DA6C
                move.w  #$A,d1
.loc_DA6C:
                movea.l #ram_FF33CC,a0
                asl.w   #5,d1
                lea     (a0,d1.w),a0
                move.w  #1,d0
.loc_DA7C:
                move.l  (a0)+,d1
                swap    d1
                eor.l   d2,d1
                move.l  d1,-(a1)
                move.l  (a0)+,d1
                swap    d1
                eor.l   d2,d1
                move.l  d1,-(a1)
                move.l  (a0)+,d1
                swap    d1
                eor.l   d2,d1
                move.l  d1,-(a1)
                move.l  (a0)+,d1
                swap    d1
                eor.l   d2,d1
                move.l  d1,-(a1)
                adda.l  #$90,a1
                dbf     d0,.loc_DA7C
                rts
.loc_DAA8:
                neg.w   d1
                andi.w  #$7FFF,d1
                cmp.w   #$B,d1
                bmi.w   .loc_DABA
                move.w  #$A,d1
.loc_DABA:
                movea.l #ram_FF33CC,a0
                move.w  #5,d0
                asl.w   d0,d1
                lea     (a0,d1.w),a0
                move.w  #1,d0
.loc_DACE:
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                adda.l  #$70,a1 ; 'p'
                dbf     d0,.loc_DACE
                rts
; End of function sub_DA3E


; =============== S U B R O U T I N E =======================================


sub_DAE2:                               ; CODE XREF: sub_F40C+142↓p
; sub_F40C+344↓p
                move.l  4(a1),d2
                sub.l   (ram_FF1E68).l,d2
                neg.l   d2
                lea     (ram_FF1B50).l,a3
                move.w  (ram_FFDE72).l,d0
                asl.w   #2,d0
                move.l  d2,(a3,d0.w)
                swap    d2
                move.l  d2,d0
                swap    d0
                move.w  #$A,d1
                asr.l   d1,d0
                muls.w  #$FFE5,d0
                divs.w  #$10,d0
                addi.w  #$B00,d0
                move.w  d0,-(sp)
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSY).l,d1
                subi.w  #$10,d1
                ext.l   d1
                divs.w  #$28,d1 ; '('
                muls.w  #$28,d1 ; '('
                neg.w   d1
                add.w   $30(a1),d1
                muls.w  d1,d0
                divs.w  #$E0,d0
                asr.w   #6,d0
                move.w  d0,$C(a0)
                addi.w  #$20,d0 ; ' '
                move.w  d0,0.w(a0)
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSY).l,d1
                addi.w  #$10,d1
                ext.l   d1
                divs.w  #$28,d1 ; '('
                muls.w  #$28,d1 ; '('
                neg.w   d1
                add.w   $30(a1),d1
                move.w  (sp)+,d0
                muls.w  d1,d0
                divs.w  #$E0,d0
                asr.w   #6,d0
                addi.w  #$100,d0
                sub.w   d0,$C(a0)
                move.l  d2,d0
                swap    d0
                move.w  #$C,d1
                asr.l   d1,d0
                divs.w  #$10,d0
                neg.w   d0
                addi.w  #$D8,d0
                move.w  d0,2(a0)
                move.l  d2,d1
                swap    d1
                move.w  #$C,d0
                asr.l   d0,d1
                addi.l  #$80,d1
                move.l  #$100000,d0
                divu.w  d1,d0
                cmp.w   #$3FFF,d0
                bmi.w   .loc_DBB0
                move.w  #$3FFF,d0

.loc_DBB0:                               ; CODE XREF: sub_DAE2+C6↑j
                move.w  d0,d1
                lsl.w   #1,d0
                add.w   d1,d0
                move.w  d0,4(a0)
                move.w  #$E0,6(a0)
                move.b  $73(a1),d0
                andi.w  #3,d0
                ror.w   #4,d0
                addi.w  #$4100,d0
                move.w  d0,$A(a0)
                move.b  $71(a1),d0
                cmp.b   #1,d0
                beq.w   .loc_DC34
                cmp.b   #$10,d0
                blt.w   .loc_DBF2
                cmp.b   #$12,d0
                ble.w   .loc_DC40
                bra.w   .locret_DC7E


.loc_DBF2:                               ; CODE XREF: sub_DAE2+100↑j
                move.w  $C(a1),d0
                move.w  d0,d1
                andi.w  #$8000,d1
                or.w    d1,$A(a0)
                btst    #4,$68(a1)
                beq.w   .loc_DC20
                tst.b   $6E(a1)
                bmi.w   .loc_DC20
                move.w  4(a0),d0
                lsr.w   #1,d0
                move.w  d0,4(a0)
                bra.w   .loc_DC58


.loc_DC20:                               ; CODE XREF: sub_DAE2+124↑j
; sub_DAE2+12C↑j
                jsr     (sub_102E4).l
                move.w  d1,d0
                addi.w  #$154,d0
                move.w  d0,8(a0)
                bra.w   .loc_DC58


.loc_DC34:                               ; CODE XREF: sub_DAE2+F8↑j
                move.w  #$159,d0
                move.w  d0,8(a0)
                bra.w   .loc_DC58


.loc_DC40:                               ; CODE XREF: sub_DAE2+108↑j
                move.w  #$15A,d0
                btst    #3,$69(a1)
                beq.w   .loc_DC50
                addq.w  #2,d0

.loc_DC50:                               ; CODE XREF: sub_DAE2+168↑j
                move.w  d0,8(a0)
                bra.w   *+4


.loc_DC58:                               ; CODE XREF: sub_DAE2+13A↑j
; sub_DAE2+14E↑j ...
                move.w  (a0),d0
                cmp.w   #$FFE0,d0
                bmi.w   .locret_DC7E
                sub.w   $C(a0),d0
                cmp.w   #$160,d0
                bpl.w   .locret_DC7E
                subi.w  #$200,(a0)
                addi.w  #1,(ram_FFDE72).l
                adda.w  #$14,a0

.locret_DC7E:                            ; CODE XREF: sub_DAE2+10C↑j
; sub_DAE2+17C↑j ...
                rts
; End of function sub_DAE2


                dc.b   8
                dc.b   8
                dc.b   0
                dc.b   6
unk_DC84:
    dc.l $BBBBBBAB
    dc.l $BABBBABB
    dc.l $BBABBBBA
    dc.l $BBBBBABB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $AB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $AB
                dc.b $AB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BA
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $AB
                dc.b $BB
                dc.b $BB
unk_DD44:       dc.b $BB                ; DATA XREF: sub_DD84+60↓o
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB
                dc.b $BB

; =============== S U B R O U T I N E =======================================


sub_DD84:
                move.w  #$98,d0
                move.w  (ram_FF1B30).l,d4
                move.w  (ram_FF1E68).l,d6
                move.w  #$FFFF,d7
                lea     (ram_FF3238).l,a0
                movea.l (Race_ram_CurrentHudBuffer).l,a1
                adda.w  #$260,a1
                movea.l (Race_ram_CurrentAlpha).l,a2
                lea     (RoadMarking_ram_WidthArray).l,a3
                adda.w  #$130,a3
                lea     (ram_FF3A9C).l,a5
                adda.w  #$130,a5
.loc_DDC2:
                subq.w  #1,d4
                bne.w   .loc_DDCE
                move.w  (ram_FF1B2E).l,d7
.loc_DDCE:
                move.w  (a0)+,d5
                cmp.w   d5,d0
                ble.w   .loc_DE22
                lea     (unk_DC84).l,a4
                btst    #0,d6
                beq.w   .loc_DDEA
                lea     (unk_DD44).l,a4
.loc_DDEA:
                tst.w   d7
                bgt.w   .loc_DE36
                move.w  d6,d1
                asr.w   #1,d1
                sub.w   d5,d1
                add.w   d0,d1
                asl.w   #2,d1
.loc_DDFA:
                subq.l  #4,d1
                andi.w  #$3C,d1
                move.l  (a4,d1.w),-(a1)
                subq.w  #2,a3
                subq.w  #2,a5
                cmpa.l  #unk_DC84,a4
                beq.w   .loc_DE16
                move.w  #0,(a3)
.loc_DE16:
                subq.w  #1,d0
                cmp.w   (a2),d0
                beq.w   .locret_DE34
                cmp.w   d5,d0
                bgt.s   .loc_DDFA
.loc_DE22:
                tst.w   d4
                bgt.w   .loc_DE2A
                subq.w  #1,d7
.loc_DE2A:
                addq.w  #1,d6
                cmpa.l  #ram_FF3276,a0
                bmi.s   .loc_DDC2
.locret_DE34:
                rts
.loc_DE36:
                move.w  d0,d3
                sub.w   d5,d3
                subq.w  #2,d3
                bmi.w   .loc_DE78
                movea.l #$CCCCCCCC,a4
                move.w  d5,d3
                cmp.w   #3,d7
                beq.w   .loc_DE78
                movea.l #$DDDDDDDD,a4
                move.w  d0,d3
                sub.w   d5,d3
                asr.w   #2,d3
                add.w   d5,d3
                cmp.w   #1,d7
                beq.w   .loc_DE78
                sub.w   d5,d3
                neg.w   d3
                add.w   d0,d3
                cmp.w   #4,d7
                beq.w   .loc_DE78
                move.w  #0,d3
.loc_DE78:
                move.l  #$EEEEEEEE,-(a1)
                subq.w  #1,d0
                cmp.w   d0,d3
                bne.w   .loc_DE88
                move.l  a4,(a1)
.loc_DE88:
                subq.w  #2,a3
                subq.w  #2,a5
                move.w  #0,(a3)
                move.w  #0,(a5)
                cmp.w   (a2),d0
                beq.s   .locret_DE34
                cmp.w   d5,d0
                bgt.s   .loc_DE78
                bra.s   .loc_DE22
; End of function sub_DD84


; =============== S U B R O U T I N E =======================================


sub_DE9E:
                btst    #4,(ram_FF1EAA + STRUCT_OFFSET_68).l
                beq.w   .loc_DF0A
                tst.w   (Race_ram_State).l
                bne.w   .loc_DF14
                cmpi.b  #2,(ram_FF1EAA + STRUCT_OFFSET_6E).l
                bmi.w   .loc_DED2
                move.l  (ram_FFD340).l,d0
                asr.l   #2,d0
                sub.l   d0,(ram_FFD340).l
                bra.w   .loc_DF14
.loc_DED2:
                move.l  (ram_FF1EAA + STRUCT_OFFSET_26).l,d0
                lsr.l   #4,d0
                btst    #3,(ram_FF1EAA + STRUCT_OFFSET_69).l
                beq.w   .loc_DEE8
                neg.l   d0
.loc_DEE8:
                add.l   d0,(ram_FFD340).l
                cmpi.l  #$FFFF9000,(ram_FFD340).l
                bpl.w   .loc_DF14
                move.l  #$FFFF9000,(ram_FFD340).l
                bra.w   .loc_DF14
.loc_DF0A:
                move.l  #0,(ram_FFD340).l
.loc_DF14:
                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSY).l,d0
                asr.w   #1,d0
                move.w  d0,d1
                asr.w   #1,d1
                add.w   d1,d0
                add.w   (ram_FF1E7A).l,d0
                move.w  d0,(ram_FF1E60).l
                bra.w   .loc_DF6E

                move.w  (ram_FF1EAA + STRUCT_OFFSET_POSY).l,d1
                add.w   (ram_FF1E7A).l,d1
                beq.w   .loc_DF6E
                clr.w   (ram_FF1E86).l
                sub.w   (ram_FF1E60).l,d1
                beq.s   .loc_DF6E
                ext.l   d1
                swap    d1
                asr.l   #1,d1
                add.l   d1,(ram_FF1E86).l
                move.w  (ram_FF1E86).l,d1
                add.w   (ram_FF1E60).l,d1
                move.w  d1,(ram_FF1E60).l
.loc_DF6E:
                move.w  (ram_FF1EAA + STRUCT_OFFSET_32).l,d0
                ext.l   d0
                asr.l   #1,d0
                add.l   (ram_FF1E7E).l,d0
                addi.l  #$5D,d0
                cmp.l   #$5D,d0
                bpl.w   .loc_DF90
                moveq   #$5D,d0
.loc_DF90:
                move.l  d0,(ram_FF1E64).l
                move.w  (ram_FF1E68).l,d1
                move.l  (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                sub.l   (ram_FF1E76).l,d0
                sub.l   (ram_FFD340).l,d0
                move.l  d0,(ram_FF1E68).l
                swap    d0
                move.w  d0,d2
                lea     (ram_FFDC58).l,a0
                andi.w  #$FF,d2
                asl.w   #1,d2
                clr.w   d3
                clr.w   d4
                clr.w   d7
                sub.w   d1,d0
                beq.w   .locret_E002
                bpl.w   .loc_DFDA
                neg.w   d0
                move.w  #$FFFF,d7
.loc_DFDA:
                move.b  (a0)+,d1
                ext.w   d1
                add.w   d1,d3
                move.b  (a0)+,d1
                ext.w   d1
                add.w   d1,d4
                addq.w  #1,d2
                dbf     d0,.loc_DFDA
                tst.w   d7
                bpl.w   .loc_DFF6
                neg.w   d3
                neg.w   d4
.loc_DFF6:
                add.w   d3,(ram_FF1E54).l
                add.w   d4,(ram_FF1E56).l
.locret_E002:
                rts
; End of function sub_DE9E


; =============== S U B R O U T I N E =======================================
; black screen if commented out

sub_E004:
                movea.l (Race_ram_CurrentVScrollInfo).l,a0

                move.w  #$8AFF,$80(a0) ; H-Int counter : 255
                move.w  #$9C,d0
                asl.w   #8,d0
                addi.w  #$60,d0
                move.w  d0,$82(a0) ; HvCounter
                move.w  #$873F,$84(a0) ; Backdrop Color: $3F
                move.w  #-8,$86(a0) ; VScroll value : -8
                move.w  #-8,$88(a0) ; VScroll value : -8
                move.w  #$90,$8A(a0) ; next cmd = $90 (end)

                move.w  #$8AFF,$70(a0) ; H-Int counter : 255
                movea.l (Race_ram_CurrentAlpha).l,a1
                move.w  (a1),d0
                cmp.w   #16,d0
                bpl.w   .loc_E050
                move.w  #16,d0
.loc_E050:
                cmp.w   #152,d0
                ble.w   .loc_E05C
                move.w  #152,d0
.loc_E05C:
                move.w  d0,$7E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$72(a0) ; HvCounter
                move.w  #$873E,$74(a0) ; Backdrop Color: $3E
                move.w  #40,$76(a0) ; VScroll value : 40
                move.w  #40,$78(a0) ; VScroll value : 40
                move.w  #$80,$7A(a0) ; next cmd = $80

                move.w  #$8AFF,$60(a0)
                move.w  (ram_FF3274).l,d0
                move.w  d0,d1
                asr.w   #2,d1
                sub.w   d1,d0
                asr.w   #1,d1
                sub.w   d1,d0
                addi.w  #$37,d0
                move.w  d0,d1
                subi.w  #$30,d0
                move.w  d0,$6E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$62(a0)
                move.w  #$873F,$64(a0) ; Backdrop Color: $3F
                neg.w   d1
                addi.w  #$100,d1
                move.w  d1,$68(a0)
                move.w  #$70,$6A(a0) ; next cmd = $70

                move.w  $62(a0),d0
                addi.w  #$400,d0
                sub.w   $72(a0),d0
                bls.w   .loc_E0E4
                sub.w   d0,$62(a0)
                lsr.w   #8,d0
                add.w   d0,$68(a0)
                sub.w   d0,$6E(a0)
.loc_E0E4:
                move.w  #$8AFF,$50(a0)
                move.w  (ram_FF3274).l,d0
                move.w  d0,d1
                asr.w   #2,d1
                sub.w   d1,d0
                addi.w  #$30,d0 ; '0'
                move.w  d0,d1
                neg.w   d1
                subi.w  #$40,d0 ; '@'
                move.w  d0,$5E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$52(a0)
                move.w  #$873F,$54(a0)
                addi.w  #$100,d1
                move.w  d1,$56(a0)
                move.w  $56(a0),$66(a0)
                move.w  #$60,$5A(a0)
                move.w  $5E(a0),d0
                subi.w  #$58,d0
                ble.w   .loc_E14A
                add.w   d0,$56(a0)
                move.w  $56(a0),$66(a0)
                sub.w   d0,$5E(a0)
                asl.w   #8,d0
                sub.w   d0,$52(a0)
.loc_E14A:
                move.w  $7E(a0),d0
                sub.w   $5E(a0),d0
                subi.w  #$40,d0
                ble.w   .loc_E16E
                sub.w   d0,$56(a0)
                move.w  $56(a0),$66(a0)
                add.w   d0,$5E(a0)
                asl.w   #8,d0
                add.w   d0,$52(a0)
.loc_E16E:
                move.w  $52(a0),d0
                addi.w  #$C00,d0
                sub.w   $62(a0),d0
                bls.w   .loc_E192
                sub.w   d0,$52(a0)
                lsr.w   #8,d0
                add.w   d0,$56(a0)
                move.w  $56(a0),$66(a0)
                sub.w   d0,$5E(a0)
.loc_E192:

                move.w  #$8AFF,$40(a0)
                move.w  $5E(a0),d0
                addi.w  #$C,d0
                subi.w  #$38,d0
                move.w  d0,$4E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$42(a0)
                move.w  #$873F,$44(a0)
                move.w  $4E(a0),d0
                neg.w   d0
                move.w  d0,$48(a0)
                move.w  d0,$58(a0)
                move.w  #$50,$4A(a0)

                move.w  #$8AFF,$30(a0)
                move.w  $5E(a0),d0
                subi.w  #$38,d0
                move.w  d0,$3E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$32(a0)
                move.w  #$873F,$34(a0)
                move.w  $3E(a0),d0
                neg.w   d0
                move.w  d0,$36(a0)
                move.w  d0,$46(a0)
                move.w  #$40,$3A(a0)

                move.w  #$8AFF,$20(a0)
                move.w  $4E(a0),d0
                subi.w  #$20,d0
                move.w  d0,$2E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$22(a0)
                move.w  #$873F,$24(a0)
                move.w  $2E(a0),d0
                neg.w   d0
                move.w  d0,$28(a0)
                move.w  d0,$38(a0)
                move.w  #$30,$2A(a0)

                move.w  #$8AFF,$10(a0)
                move.w  $3E(a0),d0
                subi.w  #$20,d0
                move.w  d0,$1E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,$12(a0)
                move.w  #$873F,$14(a0)
                move.w  $1E(a0),d0
                neg.w   d0
                move.w  d0,$16(a0)
                move.w  d0,$26(a0)
                move.w  $28(a0),$18(a0)
                move.w  #$20,$1A(a0)

                move.w  #$8A03,(a0) ; H-Int counter : 3
                move.w  $2E(a0),d0
                subi.w  #$20,d0
                move.w  d0,$E(a0)
                asl.w   #8,d0
                addi.w  #-$A0,d0
                move.w  d0,2(a0)
                move.w  #$873F,4(a0)
                move.w  $E(a0),d0
                neg.w   d0
                move.w  d0,8(a0)
                move.w  d0,8(a0)
                move.w  $16(a0),6(a0)
                move.w  #$10,$A(a0)

.loc_E2AE:
                move.w  $A(a0),d0
                move.w  $E(a0,d0.w),d1
                cmp.w   #0,d1
                bpl.w   .loc_E2E4
                move.w  2(a0,d0.w),2(a0)
                move.w  4(a0,d0.w),4(a0)
                move.w  6(a0,d0.w),6(a0)
                move.w  8(a0,d0.w),8(a0)
                move.w  $A(a0,d0.w),$A(a0)
                move.w  $E(a0,d0.w),$E(a0)
                bra.s   .loc_E2AE

.loc_E2E4:
                move.w  $1A(a0),d0
                move.w  $E(a0,d0.w),d1
                cmp.w   #8,d1
                bgt.w   .loc_E31A
                move.w  2(a0,d0.w),$12(a0)
                move.w  4(a0,d0.w),$14(a0)
                move.w  6(a0,d0.w),$16(a0)
                move.w  8(a0,d0.w),$18(a0)
                move.w  $A(a0,d0.w),$1A(a0)
                move.w  $E(a0,d0.w),$1E(a0)
                bra.s   .loc_E2E4
.loc_E31A:
                move.w  $1E(a0),d1
                cmp.w   #4,d1
                bpl.w   .loc_E32A
                move.w  #4,d1
.loc_E32A:
                move.w  d1,$1E(a0)
                asl.w   #8,d1
                addi.w  #-$A0,d1
                move.w  d1,$12(a0)
                move.w  #$10,$A(a0)
.loc_E33E:
                move.w  $2A(a0),d0
                move.w  $E(a0,d0.w),d1
                move.w  $1E(a0),d2
                addq.w  #8,d2
                cmp.w   d2,d1
                bgt.w   .loc_E378
                move.w  2(a0,d0.w),$22(a0)
                move.w  4(a0,d0.w),$24(a0)
                move.w  6(a0,d0.w),$26(a0)
                move.w  8(a0,d0.w),$28(a0)
                move.w  $A(a0,d0.w),$2A(a0)
                move.w  $E(a0,d0.w),$2E(a0)
                bra.s   .loc_E33E
.loc_E378:
                move.w  $2E(a0),d1
                subq.w  #4,d2
                cmp.w   d2,d1
                bpl.w   .loc_E386
                move.w  d2,d1
.loc_E386:
                move.w  d1,$2E(a0)
                asl.w   #8,d1
                addi.w  #-$A0,d1
                move.w  d1,$22(a0)
                move.w  #$20,$1A(a0)
                move.w  #$8A01,(a0)
                move.w  $2A(a0),d1
                move.w  $E(a0,d1.w),d0
                subq.w  #8,d0
                subq.w  #1,d0
                addi.w  #$8A00,d0
                move.w  d0,$10(a0)
                move.w  $1A(a0),d1
.loc_E3B6:
                move.w  $A(a0,d1.w),d2
                move.w  $A(a0,d2.w),d3
                cmp.w   #$90,d3
                bpl.w   .loc_E3E0
                move.w  2(a0,d3.w),d0
                sub.w   2(a0,d2.w),d0
                lsr.w   #8,d0
                subq.w  #1,d0
                addi.w  #$8A00,d0
                move.w  d0,(a0,d1.w)
                move.w  $A(a0,d1.w),d1
                bra.s   .loc_E3B6
.loc_E3E0:
                move.w  #$8210,$C(a0)
                move.w  #$8403,$E(a0)
                move.w  (ram_FF1EAA + STRUCT_OFFSET_22).l,d1
                move.w  d1,d2
                move.w  d1,d3
                move.w  d1,d4
                move.w  d1,d5
                move.w  d1,d6
                bpl.w   .loc_E440
                neg.w   d1
                neg.w   d2
                neg.w   d3
                neg.w   d4
                neg.w   d5
                neg.w   d6
                mulu.w  (ram_FF1AE8).l,d1
                mulu.w  (ram_FF1AEA).l,d2
                mulu.w  (ram_FF1AEE).l,d3
                mulu.w  (ram_FF1AF0).l,d4
                mulu.w  (ram_FF1AF2).l,d5
                mulu.w  (ram_FF1AF4).l,d6
                neg.l   d1
                neg.l   d2
                neg.l   d3
                neg.l   d4
                neg.l   d5
                neg.l   d6
                bra.w   .loc_E464


.loc_E440:                               ; CODE XREF: sub_E004+3F8↑j
                mulu.w  (ram_FF1AE8).l,d1
                mulu.w  (ram_FF1AEA).l,d2
                mulu.w  (ram_FF1AEE).l,d3
                mulu.w  (ram_FF1AF0).l,d4
                mulu.w  (ram_FF1AF2).l,d5
                mulu.w  (ram_FF1AF4).l,d6

.loc_E464:                               ; CODE XREF: sub_E004+438↑j
                sub.l   d1,(ram_FF30EA).l
                sub.l   d2,(ram_FF30EE).l
                sub.l   d3,(ram_FF30F2).l
                sub.l   d4,(ram_FF30F6).l
                sub.l   d5,(ram_FF30FA).l
                sub.l   d6,(ram_FF30FE).l
                addi.l  #$10000,(ram_FF14DC).l
                rts
; End of function sub_E004


; =============== S U B R O U T I N E =======================================


sub_E494:
                movea.l (Race_ram_CurrentVScrollInfo).l,a0
                movea.l (Race_ram_CurrentHScrollTable).l,a1
                movea.l (Race_ram_CurrentAlpha).l,a2
                movea.l a1,a3
                move.w  (a2),d0
                asl.w   #2,d0
                adda.w  d0,a3
                subq.w  #4,a3
                move.w  $72(a0),d0
                sub.w   $52(a0),d0
                lsr.w   #8,d0
                subq.w  #1,d0
                move.w  (ram_FF30EA).l,d1
.loc_E4C2:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E4C2
                move.w  $52(a0),d0
                lsr.w   #8,d0
                cmp.w   #$18,d0
                bmi.w   .loc_E4DC
                move.w  #$17,d0
.loc_E4DC:
                move.l  (ram_FF14DC).l,d1
                asr.l   #1,d1
                add.l   (ram_FF30FA).l,d1
                swap    d1
.loc_E4EC:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E4EC
                move.w  $52(a0),d0
                lsr.w   #8,d0
                addq.w  #1,d0
                subi.w  #$18,d0
                bmi.w   .loc_E51A
                move.l  (ram_FF14DC).l,d1
                add.l   (ram_FF30F2).l,d1
                swap    d1
.loc_E512:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E512
.loc_E51A:
                movea.l a1,a3
                move.w  (a2),d0
                asl.w   #2,d0
                adda.w  d0,a3
                subq.w  #2,a3
                move.w  $72(a0),d0
                sub.w   $62(a0),d0
                lsr.w   #8,d0
                subq.w  #1,d0
                move.w  (ram_FF30EE).l,d1
.loc_E536:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E536
                move.w  $62(a0),d0
                sub.w   $52(a0),d0
                lsr.w   #8,d0
                subi.w  #$D,d0
                bmi.w   .loc_E55C
                move.w  #0,d1
.loc_E554:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E554
.loc_E55C:
                move.w  $52(a0),d0
                lsr.w   #8,d0
                addi.w  #$C,d0
                cmp.w   #$18,d0
                bmi.w   .loc_E572
                move.w  #$17,d0
.loc_E572:
                move.l  (ram_FF14DC).l,d1
                asr.l   #2,d1
                add.l   (ram_FF30FE).l,d1
                swap    d1
.loc_E582:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E582
                move.w  $52(a0),d0
                lsr.w   #8,d0
                addi.w  #$D,d0
                subi.w  #$18,d0
                bmi.w   .loc_E5BC
                move.l  (ram_FF14DC).l,d1
                asr.l   #1,d1
                add.l   (ram_FF14DC).l,d1
                asr.l   #1,d1
                add.l   (ram_FF30F6).l,d1
                swap    d1
.loc_E5B4:
                move.w  d1,(a3)
                subq.w  #4,a3
                dbf     d0,.loc_E5B4
.loc_E5BC:
                movea.l a1,a3
                adda.w  #$260,a3
                move.w  #$2F,d0
.loc_E5C6:
                move.l  #0,(a3)+
                dbf     d0,.loc_E5C6
                move.l  (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d1
                asr.l   #8,d1
                asr.l   #1,d1
                andi.l  #$C0,d1
                neg.w   d1
                move.w  #$F,d0
.loc_E5E6:
                move.l  d1,(a3)+
                dbf     d0,.loc_E5E6
                rts
; End of function sub_E494


; =============== S U B R O U T I N E =======================================


sub_E5EE:                               ; CODE XREF: Race_Update+124↑p
                movem.l d0-d3/a0-a4,-(sp)
                btst    #7,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .loc_E72C
                move.l  #$7FFFFFFF,(ram_FF14E4).l
                move.l  #$80000000,(ram_FF14E0).l
                lea     (ram_FF1A08).l,a0
                movea.l (a0)+,a1
                move.l  4(a1),d0
                lea     (ram_FF1982).l,a2
                move.w  (a2)+,d1
                move.w  d1,d2
                beq.w   .loc_E642
                subq.w  #1,d2

.loc_E62E:                               ; CODE XREF: sub_E5EE:@loc_E63A↓j
                cmpi.l  #ram_FF1F2A,(a2)+
                bne.w   .loc_E63A
                subq.w  #1,d1

.loc_E63A:                               ; CODE XREF: sub_E5EE+46↑j
                dbf     d2,.loc_E62E
                bra.w   *+4


.loc_E642:                               ; CODE XREF: sub_E5EE+3A↑j
; sub_E5EE+50↑j
                addq.w  #1,d1
                move.w  #1,d4

.loc_E648:                               ; CODE XREF: sub_E5EE+84↓j
; sub_E5EE+9A↓j ...
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_E6A8
                move.l  d0,d2
                move.l  4(a2),d3
                sub.l   d3,d2
                bcc.w   .loc_E68A
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_E66C
                addq.w  #1,d1

.loc_E66C:                               ; CODE XREF: sub_E5EE+78↑j
                cmp.l   (ram_FF14E0).l,d2
                bmi.s   .loc_E648
                move.l  d2,(ram_FF14E0).l
                move.b  $71(a2),d3
                ext.w   d3
                move.w  d3,(ram_FF36AE).l
                movea.l a2,a3
                bra.s   .loc_E648


.loc_E68A:                               ; CODE XREF: sub_E5EE+6E↑j
                cmp.l   (ram_FF14E4).l,d2
                bpl.s   .loc_E648
                move.l  d2,(ram_FF14E4).l
                move.b  $71(a2),d3
                ext.w   d3
                move.w  d3,(ram_FF36B2).l
                movea.l a2,a4
                bra.s   .loc_E648


.loc_E6A8:                               ; CODE XREF: sub_E5EE+62↑j
                cmp.w   #$A,d1
                bcs.w   .loc_E6B8
                subi.w  #$A,d1
                ori.w   #$10,d1

.loc_E6B8:                               ; CODE XREF: sub_E5EE+BE↑j
                move.w  d1,(ram_FF1B40).l
                move.l  (ram_FF14E4).l,d1
                cmp.l   #$7FFFFFFF,d1
                bne.w   .loc_E6E2
                move.w  #$FFFF,(ram_FF36B2).l
                move.w  #0,(ram_FF36B4).l
                bra.w   .loc_E6F4


.loc_E6E2:                               ; CODE XREF: sub_E5EE+DC↑j
                move.w  $12(a4),d0
                beq.w   .loc_E6EE
                divu.w  d0,d1
                move.w  d1,d0

.loc_E6EE:                               ; CODE XREF: sub_E5EE+F8↑j
                move.w  d0,(ram_FF36B4).l

.loc_E6F4:                               ; CODE XREF: sub_E5EE+F0↑j
                move.l  (ram_FF14E0).l,d1
                cmp.l   #$80000000,d1
                bne.w   .loc_E718
                move.w  #$FFFF,(ram_FF36AE).l
                move.w  #0,(ram_FF36B0).l
                bra.w   .loc_E72C


.loc_E718:                               ; CODE XREF: sub_E5EE+112↑j
                neg.l   d1
                move.w  $12(a1),d0
                beq.w   .loc_E726
                divu.w  d0,d1
                move.w  d1,d0

.loc_E726:                               ; CODE XREF: sub_E5EE+130↑j
                move.w  d0,(ram_FF36B0).l

.loc_E72C:                               ; CODE XREF: sub_E5EE+C↑j
; sub_E5EE+126↑j
                movem.l (sp)+,d0-d3/a0-a4
                rts
; End of function sub_E5EE

    include "road_marking.asm"

unk_EB34:       dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $D0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $DD
                dc.b $DD
                dc.b $DD
                dc.b $DD

; =============== S U B R O U T I N E =======================================
; draw edges of the road ???

sub_EC90:
                lea     (ram_FF3A9C).l,a0
                adda.w  #$130,a0
                lea     (Road_ram_XLeftArray).l,a4
                adda.w  #$130,a4
                movea.l (Race_ram_CurrentHudBuffer).l,a1
                adda.l  #$4C0,a1
                lea     (unk_EB34).l,a2
                move.w  #$97,d0
                movea.l (Race_ram_CurrentAlpha).l,a3
                sub.w   (a3),d0
.loc_ECC2:
                move.w  -(a0),d1
                asl.w   #2,d1
                move.w  d1,d2
                add.w   d1,d2
                add.w   d1,d2
                lea     (a2,d2.w),a3
                move.l  (a3)+,-(a1)
                move.l  (a3)+,$260(a1)
                move.l  (a3)+,$4C0(a1)
                dbf     d0,.loc_ECC2

                rts
; End of function sub_EC90

; *************************************************
; Function Road_FillProfileTables
; *************************************************

Road_FillProfileTables:
                movea.l (Race_ram_CurrentAlpha).l,a0
                move.w  #$97,d0
                sub.w   (a0),d0
; go to line $98 and fill all arrays from bottom to top
                move.w  #$98,d1
                asl.w   #1,d1
                lea     (Road_ram_XLeftArray).l,a0
                adda.w  d1,a0
                lea     (Road_ram_XRightArray).l,a1
                adda.w  d1,a1
                movea.l (Race_ram_CurrentHScrollTable).l,a2
                adda.w  d1,a2
                adda.w  d1,a2
                lea     (Road_ram_MarkingXArray).l,a3
                adda.w  d1,a3
                lea     (RoadMarking_ram_XArray).l,a4
                adda.w  d1,a4
                lea     (RoadMarking_ram_WidthArray).l,a5
                adda.w  d1,a5
; grass is drawn on fg and bg planes in the middle of them and has width of 320 pixels
; so the coordinates are 512-160=352 and 512+160=682
; we scroll the planes so bg make grass to the right of the road and fg make grass to the left of the road
.mainLoop:
; these coordinates are relative to the center of the screen
                move.w  -(a0),d1 ; roadX_left
                move.w  -(a1),d2 ; roadX_right
; bg scroll
                move.w  d2,d3
                cmp.w   #192,d3
                bmi.w   .loc_ED36
                move.w  #192,d3
.loc_ED36:
                cmp.w   #-160,d3
                bpl.w   .loc_ED42
                move.w  #-160,d3
.loc_ED42:
                addi.w  #-192,d3
                move.w  d3,-(a2)
; fg scroll
                move.w  d1,d3
                cmp.w   #160,d3
                bmi.w   .loc_ED56
                move.w  #160,d3
.loc_ED56:
                cmp.w   #-192,d3
                bpl.w   .loc_ED62
                move.w  #-192,d3
.loc_ED62:
                addi.w  #512,d3
                move.w  d3,-(a2)
; calculate marking width
                sub.w   d1,d2 ; get road width
                move.w  d2,d3
                asr.w   #1,d3 ; half width
                add.w   d3,d1
                add.w   d3,d2 ; width * 1.5
                lsr.w   #6,d2 ; (road width * 1.5 / 64)
; width must be between 1 and 8
                bne.w   .setMarkingWidth
                addq.w  #1,d2
                cmp.w   #8,d2
                ble.w   .setMarkingWidth
                move.w  #8,d2
.setMarkingWidth:
                move.w  d2,-(a5) ; set marking width

                move.w  -(a3),d1
                addi.w  #512,d1
                cmp.w   #320,d1
                bmi.w   .loc_ED9C
; gap in marking
                move.w  #0,d1 ; x = 0
                clr.w   (a5) ; width = 0
.loc_ED9C:
                tst.w   d1
                bpl.w   .setMarkingX
                add.w   d1,(a5) ; if x <= 0 then decrease width
                clr.w   d1 ; and set x = 0
                tst.w   (a5)
                bpl.w   .setMarkingX
                clr.w   (a5) ; width can't be negative
.setMarkingX:
                move.w  d1,-(a4) ; set marking X
                dbf     d0,.mainLoop

                movea.l (Race_ram_CurrentAlpha).l,a6
                move.w  (a6),d0
                subq.w  #1,d0
                move.w  #0,d1
.fillSkyPart:
                move.w  d1,-(a2) ; scroll table fg
                move.w  d1,-(a2) ; scroll table bg
                move.w  d1,-(a4) ; X table
                move.w  d1,-(a5) ; width table
                dbf     d0,.fillSkyPart
                rts
; End of function Road_FillProfileTables


; =============== S U B R O U T I N E =======================================


sub_EDD0:                               ; CODE XREF: Race_Update+160↑p
                lea     (ram_FF310A).l,a0
                lea     (ram_FFDC58).l,a1
                lea     (ram_FF31D2).l,a2
                lea     (ram_FF329A).l,a3
                lea     (ram_FF3236).l,a4
                lea     (ram_FF3362).l,a5
                lea     (ram_FFD77C).l,a6
                move.w  (ram_FF1E68).l,d0
                andi.w  #$FF,d0
                asl.w   #1,d0
                adda.w  d0,a1
                move.w  (ram_FF1E6A).l,d5
                move.b  (a1)+,d4
                ext.w   d4
                move.w  d4,d0
                move.w  d4,(ram_FF1E6C).l
                beq.w   .loc_EE3E
                bmi.w   .loc_EE30
                mulu.w  d5,d4
                swap    d4
                bpl.w   .loc_EE3E
                addq.w  #1,d4
                bra.w   .loc_EE3E


.loc_EE30:                               ; CODE XREF: sub_EDD0+4E↑j
                neg.w   d4
                mulu.w  d5,d4
                swap    d4
                bpl.w   .loc_EE3C
                addq.w  #1,d4

.loc_EE3C:                               ; CODE XREF: sub_EDD0+66↑j
                neg.w   d4

.loc_EE3E:                               ; CODE XREF: sub_EDD0+4A↑j
; sub_EDD0+56↑j ...
                move.w  d4,(ram_FF1E58).l
                sub.w   d4,d0
                move.w  d0,(ram_FF3108).l
                move.w  d4,d3
                move.w  (ram_FF1E60).l,d4
                neg.w   d4
                move.b  (a1)+,d3
                cmpa.l  #Race_ram_NextSpriteTileArray,a1
                bmi.w   .loc_EE68
                lea     (ram_FFDC58).l,a1

.loc_EE68:                               ; CODE XREF: sub_EDD0+8E↑j
                ext.w   d3
                beq.w   .loc_EE82
                bmi.w   .loc_EE7A
                mulu.w  d5,d3
                swap    d3
                bra.w   .loc_EE82


.loc_EE7A:                               ; CODE XREF: sub_EDD0+9E↑j
                neg.w   d3
                mulu.w  d5,d3
                swap    d3
                neg.w   d3

.loc_EE82:                               ; CODE XREF: sub_EDD0+9A↑j
; sub_EDD0+A6↑j
                move.w  d3,(ram_FF1E5A).l
                neg.w   d3
                lsr.w   #8,d5
                neg.w   d5
                move.w  #$1F,d0
                move.w  d0,d1
                asl.w   #1,d1
                move.w  d1,(ram_FF30E0).l
                move.w  #$98,d7

.loc_EEA0:                               ; CODE XREF: sub_EDD0+1BA↓j
                move.w  d4,(a0)+
                move.w  #$100,d6
                add.w   d5,d6
                move.w  (ram_FF1E66).l,d1
                sub.w   d3,d1
                move.w  d1,(a0)+
                bpl.w   .loc_EED0
                neg.w   d1
                ext.l   d1
                asl.l   #8,d1
                divu.w  d6,d1
                neg.w   d1
                addi.w  #$4C,d1 ; 'L'
                bpl.w   .loc_EEDA
                move.w  #1,d1
                bra.w   .loc_EEDA


.loc_EED0:                               ; CODE XREF: sub_EDD0+E2↑j
                ext.l   d1
                asl.l   #8,d1
                divu.w  d6,d1
                addi.w  #$4C,d1 ; 'L'

.loc_EEDA:                               ; CODE XREF: sub_EDD0+F4↑j
; sub_EDD0+FC↑j
                move.w  d1,(a4)+
                cmp.w   d7,d1
                bcc.w   .loc_EEEC
                cmp.w   #$100,d6
                blt.w   .loc_EEEC
                move.w  d1,d7

.loc_EEEC:                               ; CODE XREF: sub_EDD0+10E↑j
; sub_EDD0+116↑j
                move.w  d7,(a6)+
                clr.l   d2
                move.w  d4,d2
                bpl.w   .loc_EF02
                neg.w   d2
                asl.l   #8,d2
                divu.w  d6,d2
                neg.w   d2
                bra.w   .loc_EF0A


.loc_EF02:                               ; CODE XREF: sub_EDD0+122↑j
                beq.w   .loc_EF0A
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF0A:                               ; CODE XREF: sub_EDD0+12E↑j
; sub_EDD0:@loc_EF02↑j
                subi.w  #$160,d2
                move.w  d2,(a2)+
                move.l  #$1C00,d2
                divu.w  d6,d2
                move.w  d2,$64(a3)
                clr.l   d2
                move.w  d4,d2
                subi.w  #$E0,d2
                bpl.w   .loc_EF34
                neg.w   d2
                asl.l   #8,d2
                divu.w  d6,d2
                neg.w   d2
                bra.w   .loc_EF3C


.loc_EF34:                               ; CODE XREF: sub_EDD0+154↑j
                beq.w   .loc_EF3C
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF3C:                               ; CODE XREF: sub_EDD0+160↑j
; sub_EDD0:@loc_EF34↑j
                move.w  d2,(a3)+
                clr.l   d2
                move.w  d4,d2
                addi.w  #$E0,d2
                bpl.w   .loc_EF56
                neg.w   d2
                asl.l   #8,d2
                divu.w  d6,d2
                neg.w   d2
                bra.w   .loc_EF5E


.loc_EF56:                               ; CODE XREF: sub_EDD0+176↑j
                beq.w   .loc_EF5E
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF5E:                               ; CODE XREF: sub_EDD0+182↑j
; sub_EDD0:@loc_EF56↑j
                move.w  d2,(a5)+
                addi.w  #$100,d5
                move.b  (a1)+,d2
                ext.w   d2
                add.w   (ram_FF3108).l,d4
                add.w   d2,(ram_FF3108).l
                move.b  (a1)+,d2
                cmpa.l  #Race_ram_NextSpriteTileArray,a1
                bmi.w   .loc_EF86
                lea     (ram_FFDC58).l,a1

.loc_EF86:                               ; CODE XREF: sub_EDD0+1AC↑j
                ext.w   d2
                add.w   d2,d3
                dbf     d0,.loc_EEA0
                movea.l (Race_ram_CurrentAlpha).l,a1
                cmp.w   #$98,d7
                bmi.w   .loc_EFA0
                move.w  #$98,d7

.loc_EFA0:                               ; CODE XREF: sub_EDD0+1C8↑j
                move.w  d7,(a1)
                rts
; End of function sub_EDD0


; =============== S U B R O U T I N E =======================================


sub_EFA4:                               ; CODE XREF: RESET+7E702↓p
                lea     (ram_FF1EAA).l,a1
                lea     (ram_FF04C8).l,a2
                btst    #7,$68(a1)
                bne.w   .loc_EFD6
                move.l  (ram_FF1E9A).l,(ram_FF1E9E).l
                move.w  4(a1),(ram_FF1762).l
                move.l  #$FFFFFFFF,(a2)
                bra.w   .loc_EFEE


.loc_EFD6:                               ; CODE XREF: sub_EFA4+12↑j
                move.l  $62(a1),(ram_FF1E9E).l
                move.w  (RaceTrack_Data1).l,(ram_FF1762).l
                move.l  $62(a1),d0
                move.l  d0,(a2)

.loc_EFEE:                               ; CODE XREF: sub_EFA4+2E↑j
                lea     (ram_FF1A0C).l,a0
                move.w  (ram_FF1A06).l,d7
                subq.w  #2,d7
                bmi.w   .loc_F036

.loc_F000:                               ; CODE XREF: sub_EFA4:@loc_F032↓j
                movea.l (a0)+,a1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F032
                move.w  4(a1),d0
                move.b  $71(a1),d1
                ext.w   d1
                btst    #7,$68(a1)
                bne.w   .loc_F028
                bsr.w   sub_F0E4
                bra.w   .loc_F032


.loc_F028:                               ; CODE XREF: sub_EFA4+78↑j
                move.l  $62(a1),d0
                asl.w   #2,d1
                move.l  d0,(a2,d1.w)

.loc_F032:                               ; CODE XREF: sub_EFA4+64↑j
; sub_EFA4+80↑j
                dbf     d7,.loc_F000

.loc_F036:                               ; CODE XREF: sub_EFA4+58↑j
                lea     (ram_FF1982).l,a0
                move.w  (a0)+,d7
                move.w  d7,d6
                asl.w   #2,d6
                adda.w  d6,a0
                subq.w  #1,d7
                bmi.w   .loc_F09E
                move.w  (ram_FF1762).l,d2
                addi.w  #$20,d2 ; ' '

.loc_F054:                               ; CODE XREF: sub_EFA4:@loc_F09A↓j
                jsr     (Rand_GetWord).l
                andi.w  #$1F,d0
                add.w   d0,d2
                move.w  d2,d0
                movea.l -(a0),a1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F09A
                move.b  $71(a1),d1
                bsr.w   sub_F0E4
                clr.l   d3
                move.w  (RaceTrack_Data1).l,d3
                swap    d3
                divu.w  STRUCT_OFFSET_66(a1),d3
                andi.l  #$FFFF,d3
                ext.w   d1
                asl.w   #2,d1
                cmp.l   (a2,d1.w),d3
                bpl.w   .loc_F09A
                move.l  d3,(a2,d1.w)

.loc_F09A:                               ; CODE XREF: sub_EFA4+C6↑j
; sub_EFA4+EE↑j
                dbf     d7,.loc_F054

.loc_F09E:                               ; CODE XREF: sub_EFA4+A2↑j
                lea     (ram_FF19C4).l,a0
                move.w  (a0)+,d7
                move.w  d7,d6
                asl.w   #2,d6
                adda.w  d6,a0
                subq.w  #1,d7
                bmi.w   .locret_F0E2
                move.w  (ram_FF1762).l,d2
                subi.w  #$10,d2

.loc_F0BC:                               ; CODE XREF: sub_EFA4:@loc_F0DE↓j
                jsr     (Rand_GetWord).l
                andi.w  #$1F,d0
                sub.w   d0,d2
                move.w  d2,d0
                movea.l -(a0),a1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F0DE
                move.b  $71(a1),d1
                bsr.w   sub_F0E4

.loc_F0DE:                               ; CODE XREF: sub_EFA4+12E↑j
                dbf     d7,.loc_F0BC

.locret_F0E2:                            ; CODE XREF: sub_EFA4+10A↑j
                rts
; End of function sub_EFA4


; =============== S U B R O U T I N E =======================================


sub_F0E4:                               ; CODE XREF: sub_EFA4+7C↑p
; sub_EFA4+CE↑p ...
                movem.l d0-d2,-(sp)
                move.l  (ram_FF1E9E).l,d2
                asl.l   #8,d2
                divu.w  d0,d2
                mulu.w  (RaceTrack_Data1).l,d2
                lsr.l   #8,d2
                ext.w   d1
                asl.w   #2,d1
                move.l  d2,(a2,d1.w)
                movem.l (sp)+,d0-d2
                rts
; End of function sub_F0E4

; *************************************************
; Function sub_F108
; *************************************************

sub_F108:
                lsr.w   #7,d0
                move.w  d0,d1
                lsr.w   #2,d1
                add.w   d1,d0
                bsr.w   sub_F11C
                move.w  d1,(ram_FF3046).l
                rts
; End of function sub_F108


; =============== S U B R O U T I N E =======================================


sub_F11C:
                movem.l d0,-(sp)

                clr.l   d1
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                swap    d0
                move.w  d0,d1
                swap    d0
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                swap    d0
                asl.w   #4,d0
                or.w    d0,d1
                swap    d0
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                swap    d0
                asl.w   #8,d0
                or.w    d0,d1
                swap    d0
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                swap    d0
                ror.w   #4,d0
                or.w    d0,d1
                swap    d0
                ext.l   d0
                beq.w   .return

                divu.w  #10,d0
                andi.l  #$F0000,d0
                or.l    d0,d1
.return:
                movem.l (sp)+,d0
                rts
; End of function sub_F11C

; *************************************************
; Function PiecewiseLinearInterpolation
; a0 - target array
; a1 - values array
; a2 - index array
; *************************************************

PiecewiseLinearInterpolation:
                move.w  #31,d5 ; 32 points
                subq.w  #1,d5
                lea     (ram_FFD77C).l,a3
.loop:
                move.w  (a1)+,d3 ; value2
                move.w  (a1),d1 ; value1
                move.w  (a2)+,d4 ; index2
                move.w  (a2),d2 ; index1
                move.w  (a3)+,d7 ; index3
                sub.w   d2,d7 ; count = index3 - index1
                ble.w   .continue

                movem.l a0-a1,-(sp)
                bsr.w   FillLinearInterpArray
                movem.l (sp)+,a0-a1
.continue:
                dbf     d5,.loop

                rts
; End of function PiecewiseLinearInterpolation

; *************************************************
; Function FillLinearInterpArray
; d1 - value1
; d2 - index1
; d3 - value2
; d4 - index2
; d7 - count (not necessary equal to index2 - index1)
; a0 - array of values
; *************************************************

FillLinearInterpArray:
                lea     (Interp_dDivisorMap).l,a1
                sub.w   d1,d3 ; d3 = d3 - d1
                sub.w   d2,d4 ; d4 = d4 - d2
                cmp.w   #1,d4
                bgt.w   .loc_F1C8
; d4 <= 1
                swap    d3
                clr.w   d3
                bra.w   .loc_F1F4
.loc_F1C8:
                cmp.w   #2,d4
                bne.w   .loc_F1DA
; d4 = 2
                swap    d3
                clr.w   d3
                asr.l   #1,d3
                bra.w   .loc_F1F4
; d4 > 2
.loc_F1DA:
                clr.w   d0
.loc_F1DC:
                cmp.w   #256,d4
                bmi.w   .loc_F1EA
                lsr.w   #1,d4
                addq.w  #1,d0
                bra.s   .loc_F1DC
.loc_F1EA:
                asl.w   #1,d4
                move.w  (a1,d4.w),d4 ; get 65535 / d4
                lsr.w   d0,d4
                muls.w  d4,d3 ; d3 = d3 * (65535 / d4)

.loc_F1F4:
                asl.w   #1,d2
                adda.w  d2,a0 ; pointer to a0[d2]
                swap    d1 ; d1 *= 65536
                clr.w   d1

                subq.w  #1,d7 ; counter
.loopWrite:
                swap    d1
                move.w  d1,(a0)+ ; write higher word to s0
                swap    d1
                add.l   d3,d1
                dbf     d7,.loopWrite

                rts
; End of function FillLinearInterpArray


Interp_dDivisorMap:
    dc.w    65535, 65535, 32768, 21845, 16384, 13107, 10922,  9362
    dc.w     8192,  7281,  6553,  5957,  5461,  5041,  4681,  4369
    dc.w     4096,  3855,  3640,  3449,  3276,  3120,  2978,  2849
    dc.w     2730,  2621,  2520,  2427,  2340,  2259,  2184,  2114
    dc.w     2048,  1985,  1927,  1872,  1820,  1771,  1724,  1680
    dc.w     1638,  1598,  1560,  1524,  1489,  1456,  1424,  1394
    dc.w     1365,  1337,  1310,  1285,  1260,  1236,  1213,  1191
    dc.w     1170,  1149,  1129,  1110,  1092,  1074,  1057,  1040
    dc.w     1024,  1008,   992,   978,   963,   949,   936,   923
    dc.w      910,   897,   885,   873,   862,   851,   840,   829
    dc.w      819,   809,   799,   789,   780,   771,   762,   753
    dc.w      744,   736,   728,   720,   712,   704,   697,   689
    dc.w      682,   675,   668,   661,   655,   648,   642,   636
    dc.w      630,   624,   618,   612,   606,   601,   595,   590
    dc.w      585,   579,   574,   569,   564,   560,   555,   550
    dc.w      546,   541,   537,   532,   528,   524,   520,   516
    dc.w      512,   508,   504,   500,   496,   492,   489,   485
    dc.w      481,   478,   474,   471,   468,   464,   461,   458
    dc.w      455,   451,   448,   445,   442,   439,   436,   434
    dc.w      431,   428,   425,   422,   420,   417,   414,   412
    dc.w      409,   407,   404,   402,   399,   397,   394,   392
    dc.w      390,   387,   385,   383,   381,   378,   376,   374
    dc.w      372,   370,   368,   366,   364,   362,   360,   358
    dc.w      356,   354,   352,   350,   348,   346,   344,   343
    dc.w      341,   339,   337,   336,   334,   332,   330,   329
    dc.w      327,   326,   324,   322,   321,   319,   318,   316
    dc.w      315,   313,   312,   310,   309,   307,   306,   304
    dc.w      303,   302,   300,   299,   297,   296,   295,   293
    dc.w      292,   291,   289,   288,   287,   286,   284,   283
    dc.w      282,   281,   280,   278,   277,   276,   275,   274
    dc.w      273,   271,   270,   269,   268,   267,   266,   265
    dc.w      264,   263,   262,   261,   260,   259,   258,   257

; =============== S U B R O U T I N E =======================================


sub_F40C:                               ; CODE XREF: Race_Update+20A↑p
                addi.b  #1,(ram_FF1AD9).l
                andi.b  #3,(ram_FF1AD9).l
                addi.b  #1,(ram_FF1ADC).l
                andi.b  #7,(ram_FF1ADC).l
                lea     (ram_FFD37C).l,a0
                move.w  (ram_FFDE72).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                lea     (ram_FF1A08).l,a2
                move.w  #0,(ram_FF3040).l

.loc_F44C:                               ; CODE XREF: sub_F40C+D0↓j
; sub_F40C:@loc_F838↓j
                move.w  #0,(ram_FF1B16).l
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                bne.w   .loc_F4CA
                tst.w   (ram_FF3040).l
                bne.w   .loc_F480
                move.w  #1,(ram_FF3040).l
                lea     (unk_2589A).l,a2
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                bne.w   .loc_F4CA

.loc_F480:                               ; CODE XREF: sub_F40C+58↑j
                cmpi.w  #2,(ram_FF3040).l
                beq.w   .loc_F83C
                cmpi.l  #$708,(ram_FF1E9A).l
                bcs.w   .loc_F83C
                move.w  #2,(ram_FF3040).l
                lea     (unk_258A6).l,a2
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .loc_F83C
                btst    #6,$68(a1)
                beq.w   .loc_F83C
                move.l  4(a1),d0
                sub.l   (ram_FF1E68).l,d0
                bmi.w   .loc_F83C

.loc_F4CA:                               ; CODE XREF: sub_F40C+4E↑j
; sub_F40C+70↑j
                cmpi.w  #1,(ram_FF3040).l
                bne.w   .loc_F4E0
                cmpi.w  #$FFFF,$56(a1)
                bne.w   .loc_F44C

.loc_F4E0:                               ; CODE XREF: sub_F40C+C6↑j
                move.w  #0,$12(a0)
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F52E
                tst.w   (ram_FF3040).l
                bne.w   .loc_F52E
                btst    #4,$68(a1)
                beq.w   .loc_F534
                tst.b   $6E(a1)
                bmi.w   .loc_F534
                move.w  #0,$12(a0)
                bsr.w   sub_15014
                tst.b   $6E(a1)
                bmi.w   .loc_F52E
                move.w  d0,(ram_FF1B16).l
                move.w  $58(a1),8(a0)
                bra.w   .loc_F534


.loc_F52E:                               ; CODE XREF: sub_F40C+E0↑j
; sub_F40C+EA↑j ...
                bclr    #4,$68(a1)

.loc_F534:                               ; CODE XREF: sub_F40C+F4↑j
; sub_F40C+FC↑j ...
                move.l  4(a1),d0
                move.l  d0,d2
                swap    d0
                sub.w   (ram_FF1E68).l,d0
                bpl.w   .loc_F556
                cmp.w   #$FFF0,d0
                bmi.w   .loc_F69C
                bsr.w   sub_DAE2
                bra.w   .loc_F69C


.loc_F556:                               ; CODE XREF: sub_F40C+136↑j
                cmp.w   #$1E,d0
                bgt.w   .loc_F838
                sub.l   (ram_FF1E68).l,d2
                lsr.l   #8,d2
                addi.w  #$100,d2
                clr.l   d1
                move.w  (ram_FF1E60).l,d1
                sub.w   $30(a1),d1
                bmi.w   .loc_F588
                tst.w   d2
                beq.w   .loc_F584
                asl.l   #8,d1
                divu.w  d2,d1

.loc_F584:                               ; CODE XREF: sub_F40C+170↑j
                bra.w   .loc_F596


.loc_F588:                               ; CODE XREF: sub_F40C+16A↑j
                neg.w   d1
                asl.l   #8,d1
                tst.w   d2
                beq.w   .loc_F594
                divu.w  d2,d1

.loc_F594:                               ; CODE XREF: sub_F40C+182↑j
                neg.w   d1

.loc_F596:                               ; CODE XREF: sub_F40C:@loc_F584↑j
                lea     (ram_FFD338).l,a4
                move.w  #4,d2
                tst.w   (ram_FF3040).l
                beq.w   .loc_F5B4
                lea     (unk_25802).l,a4
                move.w  #3,d2

.loc_F5B4:                               ; CODE XREF: sub_F40C+19A↑j
                add.w   8(a1),d1
                btst    #5,$68(a1)
                beq.w   .loc_F5C6
                add.w   $40(a1),d1

.loc_F5C6:                               ; CODE XREF: sub_F40C+1B2↑j
                tst.w   d1
                bmi.w   .loc_F5DE

.loc_F5CC:                               ; CODE XREF: sub_F40C+1C6↓j
                cmp.w   -(a4),d1
                bcc.w   .loc_F5F4
                dbf     d2,.loc_F5CC
                move.w  #0,d2
                bra.w   .loc_F5F4


.loc_F5DE:                               ; CODE XREF: sub_F40C+1BC↑j
                neg.w   d1

.loc_F5E0:                               ; CODE XREF: sub_F40C+1DA↓j
                cmp.w   -(a4),d1
                bcc.w   .loc_F5F2
                dbf     d2,.loc_F5E0
                move.w  #0,d2
                bra.w   .loc_F5F4


.loc_F5F2:                               ; CODE XREF: sub_F40C+1D6↑j
                neg.w   d2

.loc_F5F4:                               ; CODE XREF: sub_F40C+1C2↑j
; sub_F40C+1CE↑j ...
                move.w  d2,$34(a1)
                move.w  d0,$A(a0)
                tst.w   (ram_FF3040).l
                beq.w   .loc_F60E
                bsr.w   sub_108DA
                bra.w   .loc_F64A


.loc_F60E:                               ; CODE XREF: sub_F40C+1F6↑j
                tst.w   (ram_FF1B16).l
                bne.w   .loc_F64E
                cmpa.l  #ram_FF1F2A,a1
                bne.w   .loc_F62A
                bsr.w   sub_10256
                bra.w   .loc_F64A


.loc_F62A:                               ; CODE XREF: sub_F40C+212↑j
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_F646
                tst.w   (ram_FF1ACC).l
                beq.w   .loc_F646
                bsr.w   sub_10294
                bra.w   .loc_F64A


.loc_F646:                               ; CODE XREF: sub_F40C+224↑j
; sub_F40C+22E↑j
                bsr.w   sub_100D0

.loc_F64A:                               ; CODE XREF: sub_F40C+1FE↑j
; sub_F40C+21A↑j ...
                move.w  d0,8(a0)

.loc_F64E:                               ; CODE XREF: sub_F40C+208↑j
                move.l  4(a1),d0
                sub.l   (ram_FF1E68).l,d0
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  d0,(a6,d7.w)
                bsr.w   sub_FF7E
                btst    #3,$68(a1)
                beq.w   .loc_F684
                move.w  $12(a1),d0
                andi.w  #3,d0
                or.w    d0,2(a0)

.loc_F684:                               ; CODE XREF: sub_F40C+268↑j
                move.b  $73(a1),d0
                asl.b   #4,d0
                or.b    d0,$A(a0)
                move.w  (a0),d0
                bpl.w   .loc_F69C
                cmp.w   #$FDC4,d0
                bpl.w   .loc_F6AA

.loc_F69C:                               ; CODE XREF: sub_F40C+13E↑j
; sub_F40C+146↑j ...
                tst.w   (ram_FF1B16).l
                beq.w   .loc_F838
                bra.w   .loc_F71E


.loc_F6AA:                               ; CODE XREF: sub_F40C+28C↑j
                addi.w  #1,(ram_FFDE72).l
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_F6D6
                cmpi.b  #2,$6E(a1)
                bne.w   .loc_F6D6
                cmpi.w  #8,(ram_FF1B28).l
                bmi.w   .loc_F6D6
                bsr.w   sub_F9C4

.loc_F6D6:                               ; CODE XREF: sub_F40C+2AC↑j
; sub_F40C+2B6↑j ...
                tst.w   (ram_FF1B16).l
                bne.w   .loc_F704
                btst    #0,$68(a1)
                beq.w   .loc_F6F2
                bsr.w   sub_F90E
                bra.w   .loc_F834


.loc_F6F2:                               ; CODE XREF: sub_F40C+2DA↑j
                btst    #5,$68(a1)
                beq.w   .loc_F834
                bsr.w   sub_F842
                bra.w   .loc_F834
.loc_F704:
                bclr    #7,$A(a0)
                btst    #0,$76(a1)
                beq.w   .loc_F71A
                bset    #7,$A(a0)
.loc_F71A:
                adda.w  #$14,a0
.loc_F71E:
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_258AE).l,a1
                movea.l (a1,d0.w),a1
                move.w  $58(a1),8(a0)
                move.l  4(a1),d0
                move.l  d0,d2
                swap    d0
                sub.w   (ram_FF1E68).l,d0
                bpl.w   .loc_F758
                cmp.w   #$FFF0,d0
                bmi.w   .loc_F838
                bsr.w   sub_DAE2
                bra.w   .loc_F838
.loc_F758:
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                move.b  $73(a1),d0
                asl.b   #4,d0
                move.b  d0,$A(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                cmpi.b  #4,$6E(a1)
                bne.w   .loc_F79A
                addi.l  #$3000,d0

.loc_F79A:                               ; CODE XREF: sub_F40C+384↑j
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                move.b  $76(a1),d0
                btst    #0,d0
                bne.w   .loc_F7C2
                bclr    #7,$A(a0)
                bra.w   .loc_F7C8


.loc_F7C2:                               ; CODE XREF: sub_F40C+3A8↑j
                bset    #7,$A(a0)

.loc_F7C8:                               ; CODE XREF: sub_F40C+3B2↑j
                btst    #1,d0
                bne.w   .loc_F7DA
                bclr    #3,$A(a0)
                bra.w   .loc_F7E0


.loc_F7DA:                               ; CODE XREF: sub_F40C+3C0↑j
                bset    #3,$A(a0)

.loc_F7E0:                               ; CODE XREF: sub_F40C+3CA↑j
                move.l  4(a1),d0
                move.w  $30(a1),d1
                move.w  $32(a1),d2
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_F802
                subi.w  #1,(ram_FFDE72).l
                bra.w   .loc_F838


.loc_F802:                               ; CODE XREF: sub_F40C+3E6↑j
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)
                btst    #7,$6A(a1)
                beq.w   .loc_F834
                tst.b   $6E(a1)
                bne.w   .loc_F834
                tst.b   $6F(a1)
                bne.w   .loc_F834
                bsr.w   sub_FA98
                bclr    #7,$6A(a1)

.loc_F834:                               ; CODE XREF: sub_F40C+2E2↑j
; sub_F40C+2EC↑j ...
                adda.w  #$14,a0

.loc_F838:                               ; CODE XREF: sub_F40C+14E↑j
; sub_F40C+296↑j ...
                bra.w   .loc_F44C


.loc_F83C:                               ; CODE XREF: sub_F40C+7C↑j
; sub_F40C+8A↑j ...
                move.w  #$FFFF,(a0)
                rts
; End of function sub_F40C


; =============== S U B R O U T I N E =======================================


sub_F842:                               ; CODE XREF: sub_F40C+2F0↑p
                adda.w  #$14,a0
                move.b  (ram_FF1AD9).l,d0
                ext.w   d0
                addi.w  #$166,d0
                move.w  d0,8(a0)
                clr.l   d0
                move.w  d0,$A(a0)
                move.l  d0,$C(a0)
                move.l  d0,$10(a0)
                btst    #3,$68(a1)
                beq.w   .loc_F872
                move.b  #$10,d0

.loc_F872:                               ; CODE XREF: sub_F842+28↑j
                move.b  d0,$A(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                subi.l  #$3000,d0
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #3,$A(a0)
                lea     (unk_10E3E).l,a4
                bclr    #7,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_F8BC
                neg.w   d0

.loc_F8BC:                               ; CODE XREF: sub_F842+74↑j
                asl.w   #3,d0
                add.w   (ram_FF1764).l,d0
                move.b  (a4,d0.w),d1
                ext.w   d1
                btst    #7,-$A(a0)
                beq.w   .loc_F8DC
                neg.w   d1
                bset    #7,$A(a0)

.loc_F8DC:                               ; CODE XREF: sub_F842+8E↑j
                add.w   $30(a1),d1
                move.w  $32(a1),d2
                move.l  4(a1),d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_F8FE
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_F90C


.loc_F8FE:                               ; CODE XREF: sub_F842+AC↑j
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_F90C:                            ; CODE XREF: sub_F842+B8↑j
                rts
; End of function sub_F842


; =============== S U B R O U T I N E =======================================


sub_F90E:                               ; CODE XREF: sub_F40C+2DE↑p
                adda.w  #$14,a0
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                move.b  $73(a1),d0
                asl.b   #4,d0
                move.b  d0,$A(a0)
                bclr    #7,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_F948
                neg.w   d0
                bset    #7,$A(a0)

.loc_F948:                               ; CODE XREF: sub_F90E+2E↑j
                cmp.w   #4,d0
                bmi.w   .loc_F954
                move.w  #3,d0

.loc_F954:                               ; CODE XREF: sub_F90E+3E↑j
                addi.w  #$16A,d0
                move.w  d0,8(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                addi.l  #unk_80000,d0
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #3,$A(a0)
                move.w  $30(a1),d1
                move.w  #0,d2
                move.l  4(a1),d0
                subi.l  #$3000,d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_F9B4
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_F9C2


.loc_F9B4:                               ; CODE XREF: sub_F90E+96↑j
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_F9C2:                            ; CODE XREF: sub_F90E+A2↑j
                rts
; End of function sub_F90E


; =============== S U B R O U T I N E =======================================


sub_F9C4:                               ; CODE XREF: sub_F40C+2C6↑p
                adda.w  #$14,a0
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                bclr    #7,$A(a0)
                clr.w   d0
                move.b  (ram_FF1ADC).l,d0
                lsr.b   #1,d0
                addi.w  #$AC,d0
                move.w  d0,8(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                subi.l  #$100,d0
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #3,$A(a0)
                move.w  $30(a1),d1
                move.w  #0,d2
                lea     (unk_FA80).l,a6
                move.b  $6F(a1),d7
                ext.w   d7
                cmp.w   #6,d7
                bcs.w   .loc_FA46
                move.w  #5,d7

.loc_FA46:                               ; CODE XREF: sub_F9C4+7A↑j
                asl.w   #2,d7
                adda.w  d7,a6
                add.w   (a6),d1
                add.w   2(a6),d2
                move.l  4(a1),d0
                subi.l  #$3000,d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FA70
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_FA7E


.loc_FA70:                               ; CODE XREF: sub_F9C4+9C↑j
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_FA7E:                            ; CODE XREF: sub_F9C4+A8↑j
                rts
; End of function sub_F9C4


unk_FA80:
    dc.w    -16, 28
    dc.w    -16, 32
    dc.w    -16, 41
    dc.w    -16, 45
    dc.w    -16, 56
    dc.w    -16, 40

; =============== S U B R O U T I N E =======================================


sub_FA98:                               ; CODE XREF: sub_F40C+41E↑p
                adda.w  #$14,a0
                bclr    #7,$A(a0)
                move.w  #$172,8(a0)
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  4(a1),d0
                addi.l  #$3000,d0
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #3,$A(a0)
                move.w  $30(a1),d1
                move.w  #0,d2
                move.l  4(a1),d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FB10
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_FB1C


.loc_FB10:                               ; CODE XREF: sub_FA98+68↑j
                asl.w   #1,d0
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)

.locret_FB1C:                            ; CODE XREF: sub_FA98+74↑j
                rts
; End of function sub_FA98


; =============== S U B R O U T I N E =======================================


sub_FB1E:                               ; CODE XREF: Race_Update+204↑p
                lea     (ram_FFD37C).l,a0
                cmpi.w  #$C,(ram_FF1E68).l
                bpl.w   .loc_FB42
                move.l  #$C0000,d0
                move.l  d0,d1
                sub.l   (ram_FF1E68).l,d1
                bra.w   .loc_FB62


.loc_FB42:                               ; CODE XREF: sub_FB1E+E↑j
                clr.l   d0
                move.w  (RaceTrack_Data1).l,d0
                swap    d0
                move.l  d0,d1
                sub.l   (ram_FF1E68).l,d1
                bcs.w   .locret_FC0C
                cmp.l   #$1F0000,d1
                bcc.w   .locret_FC0C

.loc_FB62:                               ; CODE XREF: sub_FB1E+20↑j
                move.l  d0,-(sp)
                move.l  d1,-(sp)
                move.w  (ram_FFDE72).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                bsr.w   sub_15478
                move.w  d0,8(a0)
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                move.b  #0,d0
                asl.b   #4,d0
                move.b  d0,$A(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  (sp)+,(a6,d7.w)
                move.l  (sp)+,d0
                addi.w  #1,(ram_FFDE72).l
                bclr    #7,$A(a0)
                bra.w   .loc_FBC6

                bset    #7,$A(a0)
.loc_FBC6:                               ; CODE XREF: sub_FB1E+9E↑j
                bclr    #3,$A(a0)
                bra.w   .loc_FBD6

                bset    #3,$A(a0)
.loc_FBD6:                               ; CODE XREF: sub_FB1E+AE↑j
                move.w  #$180,d1
                move.w  #0,d2
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FBF4
                subi.w  #1,(ram_FFDE72).l
                bra.w   .loc_FC08


.loc_FBF4:                               ; CODE XREF: sub_FB1E+C6↑j
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                bset    #7,$B(a0)
                adda.w  #$14,a0

.loc_FC08:                               ; CODE XREF: sub_FB1E+D2↑j
                move.w  #$FFFF,(a0)

.locret_FC0C:                            ; CODE XREF: sub_FB1E+36↑j
; sub_FB1E+40↑j
                rts
; End of function sub_FB1E


; =============== S U B R O U T I N E =======================================


sub_FC0E:                               ; CODE XREF: Race_Update+232↑p
                move.w  #0,(ram_FFD7CA).l
                lea     (ram_FFD37C).l,a0
                move.w  (ram_FFDE72).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                move.l  a0,(ram_FFD7D0).l
                move.l  (ram_FF1E68).l,d0
                movea.l (ram_FFD7CC).l,a1

.loc_FC3A:                               ; CODE XREF: sub_FC0E+4A↓j
                cmpa.l  #ram_FFD7D4,a1
                beq.w   .loc_FC5A
                move.l  -4(a1),d1
                clr.w   d1
                cmp.l   d0,d1
                bcs.w   .loc_FC5A
                subq.l  #4,a1
                move.l  a1,(ram_FFD7CC).l
                bra.s   .loc_FC3A


.loc_FC5A:                               ; CODE XREF: sub_FC0E+32↑j
; sub_FC0E+3E↑j ...
                move.l  (a1),d1
                cmp.l   #$FFFFFFFF,d1
                beq.w   .locret_FD6C
                clr.w   d1
                move.l  d1,d2
                sub.l   (ram_FF1E68).l,d2
                bcc.w   .loc_FC82
                addi.l  #4,(ram_FFD7CC).l
                bra.w   .loc_FD62


.loc_FC82:                               ; CODE XREF: sub_FC0E+62↑j
                cmp.l   #$1E0000,d2
                bcc.w   .loc_FD68
                clr.w   d0
                move.b  2(a1),d0
                move.w  d0,d7
                addi.w  #$173,d0
                move.w  d0,8(a0)
                lea     (unk_14764).l,a4
                asl.w   #3,d7
                adda.w  d7,a4
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                move.w  (a4),d0
                asl.b   #4,d0
                move.b  d0,$A(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  d2,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                lsr.l   #8,d2
                move.w  d2,$E(a0)
                bclr    #7,$A(a0)
                bra.w   .loc_FCF4

                bset    #7,$A(a0)


.loc_FCF4:                               ; CODE XREF: sub_FC0E+DC↑j
                bclr    #3,$A(a0)
                bra.w   .loc_FD04

                bset    #3,$A(a0)


.loc_FD04:                               ; CODE XREF: sub_FC0E+EC↑j
                move.l  d1,d0
                move.w  2(a1),d1
                andi.w  #$F,d1
                asl.w   #5,d1
                subi.w  #$100,d1
                move.w  #0,d2
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FD2E
                subi.w  #1,(ram_FFDE72).l
                bra.w   .loc_FD62


.loc_FD2E:                               ; CODE XREF: sub_FC0E+110↑j
                mulu.w  2(a4),d0
                lsr.l   #8,d0
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)
                lea     (ram_FFD77C).l,a2
                asl.w   #1,d3
                move.w  (a2,d3.w),6(a0)
                bclr    #7,$B(a0)
                adda.w  #$14,a0
                addi.w  #1,(ram_FFD7CA).l

.loc_FD62:                               ; CODE XREF: sub_FC0E+70↑j
; sub_FC0E+11C↑j
                addq.w  #4,a1
                bra.w   .loc_FC5A


.loc_FD68:                               ; CODE XREF: sub_FC0E+7A↑j
                move.w  #$FFFF,(a0)

.locret_FD6C:                            ; CODE XREF: sub_FC0E+54↑j
                rts
; End of function sub_FC0E


                dc.b   0
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b   1
                dc.b   0
                dc.b   3
                dc.b  $B
                dc.b   2
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b  $B
                dc.b   3
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b   4
                dc.b   0
                dc.b   3
                dc.b  $B
                dc.b   4
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b   5
                dc.b   0
                dc.b   3
                dc.b  $B
                dc.b   5
                dc.b $80
                dc.b   3
                dc.b   4
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF

; =============== S U B R O U T I N E =======================================


sub_FD96:
                tst.w   (ram_FF1B1A).l
                beq.w   .loc_FDA8
                move.w  #$170,d0
                bra.w   .loc_FDBE
.loc_FDA8:
                move.w  (ram_FF3698).l,d0
                bpl.w   .loc_FDBE
                move.w  #0,(ram_FF369A).l
                bra.w   .return
.loc_FDBE:
                lea     (ram_FFD37C).l,a0
                move.w  (ram_FFDE72).l,d1
                mulu.w  #$14,d1
                adda.w  d1,a0
                move.w  d0,8(a0)
                move.w  #0,$A(a0)
                move.l  #0,$C(a0)
                move.l  #0,$10(a0)
                lea     (ram_FF1B50).l,a6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                moveq   #0,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                bclr    #7,$A(a0)
                bclr    #3,$A(a0)
                move.w  #$FEA0,(a0)
                move.w  #$41,2(a0)
                move.w  #$4000,4(a0)
                move.w  #$E0,6(a0)
                adda.w  #$14,a0
                move.w  #$FFFF,(a0)
                addi.w  #1,(ram_FF369A).l
.return:
                rts
; End of function sub_FD96


; =============== S U B R O U T I N E =======================================


sub_FE3A:                               ; CODE XREF: sub_F40C+3E0↑p
; sub_F842+A6↑p ...
                movem.l d4-d7/a0-a6,-(sp)
                move.w  d0,d4
                move.l  d0,d3
                move.l  (ram_FF1E68).l,d5
                sub.l   d5,d0
                bpl.w   .loc_FE56
                move.w  #0,d0
                bra.w   .loc_FF78


.loc_FE56:                               ; CODE XREF: sub_FE3A+10↑j
                swap    d3
                swap    d5
                sub.w   d5,d3
                andi.w  #$1F,d3
                move.w  d3,-(sp)
                asl.l   #8,d0
                swap    d0
                move.w  d0,d6
                addi.w  #$200,d6
                addi.w  #$100,d0
                move.l  #$2000000,d7
                addi.l  #$800000,d7
                lsr.l   #2,d7
                divu.w  d6,d7
                move.w  d7,-(sp)
                asl.w   #1,d3
                move.w  d3,d5
                asl.w   #1,d5
                lea     (ram_FF310A).l,a2
                move.w  2(a2,d5.w),d6
                move.w  d6,d7
                sub.w   6(a2,d5.w),d7
                bpl.w   .loc_FEB2
                neg.w   d7
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FEAC
                addq.w  #1,d7

.loc_FEAC:                               ; CODE XREF: sub_FE3A+6C↑j
                neg.w   d7
                bra.w   .loc_FEC0


.loc_FEB2:                               ; CODE XREF: sub_FE3A+5E↑j
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FEC0
                addq.w  #1,d7

.loc_FEC0:                               ; CODE XREF: sub_FE3A+74↑j
; sub_FE3A+80↑j
                andi.l  #$FFFF,d7
                sub.w   d7,d6
                sub.w   d2,d6
                move.w  d6,d2
                btst    #$F,d2
                beq.w   .loc_FEE6
                neg.w   d2
                ext.l   d2
                asl.l   #8,d2
                divu.w  d0,d2
                neg.w   d2
                addi.w  #$4C,d2 ; 'L'
                bra.w   .loc_FEF0


.loc_FEE6:                               ; CODE XREF: sub_FE3A+96↑j
                ext.l   d2
                asl.l   #8,d2
                divu.w  d0,d2
                addi.w  #$4C,d2 ; 'L'

.loc_FEF0:                               ; CODE XREF: sub_FE3A+A8↑j
                bpl.w   .loc_FEF8
                move.w  #1,d2

.loc_FEF8:                               ; CODE XREF: sub_FE3A:@loc_FEF0↑j
                lea     (ram_FFD77C).l,a2
                move.w  (a2,d3.w),6(a0)
                lea     (ram_FF310A).l,a2
                move.w  (a2,d5.w),d6
                move.w  d6,d7
                sub.w   4(a2,d5.w),d7
                bpl.w   .loc_FF2E
                neg.w   d7
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FF28
                addq.w  #1,d7

.loc_FF28:                               ; CODE XREF: sub_FE3A+E8↑j
                neg.w   d7
                bra.w   .loc_FF3C


.loc_FF2E:                               ; CODE XREF: sub_FE3A+DA↑j
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FF3C
                addq.w  #1,d7

.loc_FF3C:                               ; CODE XREF: sub_FE3A+F0↑j
; sub_FE3A+FC↑j
                sub.w   d7,d6
                add.w   d6,d1
                bpl.w   .loc_FF56
                neg.w   d1
                swap    d1
                divu.w  d0,d1
                bvs.w   .loc_FF68
                lsr.w   #8,d1
                neg.w   d1
                bra.w   .loc_FF70


.loc_FF56:                               ; CODE XREF: sub_FE3A+106↑j
                beq.w   .loc_FF70
                swap    d1
                divu.w  d0,d1
                bvs.w   .loc_FF68
                lsr.w   #8,d1
                bra.w   .loc_FF70


.loc_FF68:                               ; CODE XREF: sub_FE3A+110↑j
; sub_FE3A+124↑j
                move.w  #0,(sp)
                bra.w   .loc_FF74


.loc_FF70:                               ; CODE XREF: sub_FE3A+118↑j
; sub_FE3A:@loc_FF56↑j ...
                subi.w  #$160,d1

.loc_FF74:                               ; CODE XREF: sub_FE3A+132↑j
                move.w  (sp)+,d0
                move.w  (sp)+,d3

.loc_FF78:                               ; CODE XREF: sub_FE3A+18↑j
                movem.l (sp)+,d4-d7/a0-a6
                rts
; End of function sub_FE3A


; =============== S U B R O U T I N E =======================================


sub_FF7E:                               ; CODE XREF: sub_F40C+25E↑p
                movem.l d0-d7/a0-a6,-(sp)
                move.w  6(a1),d4
                move.w  $A(a0),d2
                andi.w  #$1F,d2
                asl.l   #8,d0
                swap    d0
                move.w  d0,d1
                addi.w  #$200,d1
                addi.w  #$100,d0
                bne.w   .loc_FFA4
                move.w  #1,d0

.loc_FFA4:                               ; CODE XREF: sub_FF7E+1E↑j
                move.l  #$2000000,d3
                cmpi.b  #$10,$71(a1)
                bpl.w   .loc_FFBE
                addi.l  #$800000,d3
                bra.w   .loc_FFC4


.loc_FFBE:                               ; CODE XREF: sub_FF7E+32↑j
                addi.l  #$1000000,d3

.loc_FFC4:                               ; CODE XREF: sub_FF7E+3C↑j
                lsr.l   #2,d3
                divu.w  d1,d3
                move.w  d3,4(a0)
                asl.w   #1,d2
                move.w  d2,d3
                asl.w   #1,d3
                lea     (ram_FF310A).l,a2
                move.w  2(a2,d3.w),d5
                move.w  d5,d1
                sub.w   6(a2,d3.w),d1
                bpl.w   .loc_FFFC
                neg.w   d1
                mulu.w  d4,d1
                swap    d1
                btst    #$1F,d1
                beq.w   .loc_FFF6
                addq.w  #1,d1

.loc_FFF6:                               ; CODE XREF: sub_FF7E+72↑j
                neg.w   d1
                bra.w   .loc_1000A


.loc_FFFC:                               ; CODE XREF: sub_FF7E+64↑j
                mulu.w  d4,d1
                swap    d1

.loc_10000:                              ; DATA XREF: Intro_GameTick+122↑o
; Intro_GameTick+130↑o ...
                btst    #$1F,d1
                beq.w   .loc_1000A
                addq.w  #1,d1

.loc_1000A:                              ; CODE XREF: sub_FF7E+7A↑j
; sub_FF7E+86↑j
                andi.l  #$FFFF,d1
                sub.w   d1,d5
                sub.w   $32(a1),d5
                move.w  d5,d1
                btst    #$F,d1
                beq.w   .loc_10030
                neg.w   d1
                asl.l   #8,d1
                divu.w  d0,d1
                neg.w   d1
                addi.w  #$4C,d1 ; 'L'
                bra.w   .loc_10038


.loc_10030:                              ; CODE XREF: sub_FF7E+9E↑j
                asl.l   #8,d1
                divu.w  d0,d1
                addi.w  #$4C,d1 ; 'L'

.loc_10038:                              ; CODE XREF: sub_FF7E+AE↑j
                bpl.w   .loc_10040
                move.w  #1,d1

.loc_10040:                              ; CODE XREF: sub_FF7E:@loc_10038↑j
                lea     (ram_FFD77C).l,a2
                move.w  (a2,d2.w),6(a0)
                move.w  d1,2(a0)
                move.w  d2,d3
                asl.w   #1,d3
                lea     (ram_FF310A).l,a2
                clr.l   d5
                move.w  (a2,d3.w),d5
                move.w  d5,d1
                sub.w   4(a2,d3.w),d1
                bpl.w   .loc_10080
                neg.w   d1
                mulu.w  d4,d1
                swap    d1
                btst    #$1F,d1
                beq.w   .loc_1007A
                addq.w  #1,d1

.loc_1007A:                              ; CODE XREF: sub_FF7E+F6↑j
                neg.w   d1
                bra.w   .loc_1008E


.loc_10080:                              ; CODE XREF: sub_FF7E+E8↑j
                mulu.w  d4,d1
                swap    d1
                btst    #$1F,d1
                beq.w   .loc_1008E
                addq.w  #1,d1

.loc_1008E:                              ; CODE XREF: sub_FF7E+FE↑j
; sub_FF7E+10A↑j
                sub.w   d1,d5
                add.w   $30(a1),d5
                bpl.w   .loc_100AA
                neg.w   d5
                swap    d5
                divu.w  d0,d5
                bvs.w   .loc_100BC
                lsr.w   #8,d5
                neg.w   d5
                bra.w   .loc_100C4


.loc_100AA:                              ; CODE XREF: sub_FF7E+116↑j
                beq.w   .loc_100C4
                swap    d5
                divu.w  d0,d5
                bvs.w   .loc_100BC
                lsr.w   #8,d5
                bra.w   .loc_100C4


.loc_100BC:                              ; CODE XREF: sub_FF7E+120↑j
; sub_FF7E+134↑j
                move.w  #0,d5
                bra.w   .loc_100C8


.loc_100C4:                              ; CODE XREF: sub_FF7E+128↑j
; sub_FF7E:@loc_100AA↑j ...
                subi.w  #$160,d5

.loc_100C8:                              ; CODE XREF: sub_FF7E+142↑j
                move.w  d5,(a0)
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_FF7E


; =============== S U B R O U T I N E =======================================


sub_100D0:                              ; CODE XREF: sub_F40C:@loc_F646↑p
; sub_10384+15C↓p
                move.w  d3,-(sp)
                bset    #7,$B(a0)
                move.w  #0,$12(a0)
                tst.w   $12(a1)
                bne.w   .loc_100EE
                bsr.w   sub_1022E
                bra.w   .loc_101E6


.loc_100EE:                              ; CODE XREF: sub_100D0+12↑j
                btst    #2,$6A(a1)
                beq.w   .loc_10110
                move.b  #3,d0
                and.b   $6A(a1),d0
                cmp.b   #2,d0
                bpl.w   .loc_10110
                bsr.w   sub_1081A
                bra.w   .loc_101E6


.loc_10110:                              ; CODE XREF: sub_100D0+24↑j
; sub_100D0+34↑j
                btst    #4,$69(a1)
                beq.w   .loc_10122
                bsr.w   sub_1030A
                bra.w   .loc_101E6


.loc_10122:                              ; CODE XREF: sub_100D0+46↑j
                tst.w   $18(a1)
                bne.w   .loc_1014E
                tst.w   $12(a1)
                beq.w   .loc_1014E
                btst    #1,$68(a1)
                beq.w   .loc_1014E
                btst    #2,$68(a1)
                bne.w   .loc_1014E
                bsr.w   sub_101EA
                bra.w   .loc_101E6


.loc_1014E:                              ; CODE XREF: sub_100D0+56↑j
; sub_100D0+5E↑j ...
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bmi.w   .loc_10168
                bne.w   .loc_10170
                tst.w   $C(a1)
                bmi.w   .loc_10170

.loc_10168:                              ; CODE XREF: sub_100D0+88↑j
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10170:                              ; CODE XREF: sub_100D0+8C↑j
; sub_100D0+94↑j
                asl.w   #4,d0
                move.w  $A(a1),d1
                move.w  (ram_FF1AC8).l,d3
                cmp.w   d3,d1
                bgt.w   .loc_1018A
                move.w  #0,d1
                bra.w   .loc_1018E


.loc_1018A:                              ; CODE XREF: sub_100D0+AE↑j
                move.w  #1,d1

.loc_1018E:                              ; CODE XREF: sub_100D0+B6↑j
                asl.w   #3,d1
                add.w   d1,d0
                move.w  $C(a1),d1
                cmpa.l  #ram_FF1EAA,a1
                beq.w   .loc_101A2
                asl.w   #1,d1

.loc_101A2:                              ; CODE XREF: sub_100D0+CC↑j
                lea     (ram_FFD33E).l,a4
                move.w  #3,d2
                tst.w   d1
                bmi.w   .loc_101C0

.loc_101B2:                              ; CODE XREF: sub_100D0+EA↓j
                cmp.w   -(a4),d1
                bcc.w   .loc_101CE
                subq.w  #1,d2
                bne.s   .loc_101B2
                bra.w   .loc_101CE


.loc_101C0:                              ; CODE XREF: sub_100D0+DE↑j
                neg.w   d1

.loc_101C2:                              ; CODE XREF: sub_100D0+FA↓j
                cmp.w   -(a4),d1
                bcc.w   .loc_101CC
                subq.w  #1,d2
                bne.s   .loc_101C2

.loc_101CC:                              ; CODE XREF: sub_100D0+F4↑j
                neg.w   d2

.loc_101CE:                              ; CODE XREF: sub_100D0+E4↑j
; sub_100D0+EC↑j
                move.w  d2,d1
                btst    #$F,$A(a0)
                beq.w   .loc_101DC
                neg.w   d1

.loc_101DC:                              ; CODE XREF: sub_100D0+106↑j
                addq.w  #3,d1
                move.w  d1,(ram_FF1764).l
                add.w   d1,d0

.loc_101E6:                              ; CODE XREF: sub_100D0+1A↑j
; sub_100D0+3C↑j ...
                move.w  (sp)+,d3
                rts
; End of function sub_100D0


; =============== S U B R O U T I N E =======================================


sub_101EA:                              ; CODE XREF: sub_100D0+76↑p
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10200
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10200:                              ; CODE XREF: sub_101EA+A↑j
                cmp.w   #2,d0
                bmi.w   .loc_1020C
                move.w  #2,d0

.loc_1020C:                              ; CODE XREF: sub_101EA+1A↑j
                move.w  $12(a1),d1
                cmp.w   #$DAC,d1
                bpl.w   .loc_10228
                cmp.w   #$1F4,d1
                bmi.w   .loc_10228
                addi.w  #$53,d0 ; 'S'
                bra.w   .locret_1022C


.loc_10228:                              ; CODE XREF: sub_101EA+2A↑j
; sub_101EA+32↑j
                addi.w  #$50,d0 ; 'P'

.locret_1022C:                           ; CODE XREF: sub_101EA+3A↑j
                rts
; End of function sub_101EA


; =============== S U B R O U T I N E =======================================


sub_1022E:                              ; CODE XREF: sub_100D0+16↑p
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bgt.w   .loc_10244
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10244:                              ; CODE XREF: sub_1022E+A↑j
                cmp.w   #2,d0
                bmi.w   .loc_10250
                move.w  #2,d0

.loc_10250:                              ; CODE XREF: sub_1022E+1A↑j
                addi.w  #$56,d0 ; 'V'
                rts
; End of function sub_1022E


; =============== S U B R O U T I N E =======================================


sub_10256:                              ; CODE XREF: sub_F40C+216↑p
                bclr    #7,$B(a0)
                move.w  #0,$12(a0)
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10278
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10278:                              ; CODE XREF: sub_10256+16↑j
                andi.w  #3,d0
                asl.w   #1,d0
                move.w  $A(a1),d1
                cmp.w   (ram_FF1AC8).l,d1
                blt.w   .loc_1028E
                addq.w  #1,d0

.loc_1028E:                              ; CODE XREF: sub_10256+32↑j
                addi.w  #$7F,d0
                rts
; End of function sub_10256


; =============== S U B R O U T I N E =======================================


sub_10294:                              ; CODE XREF: sub_F40C+232↑p
                bset    #7,$B(a0)
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_102B0
                neg.w   d0
                bset    #$F,$A(a0)

.loc_102B0:                              ; CODE XREF: sub_10294+10↑j
                cmp.w   #3,d0
                bmi.w   .loc_102BC
                move.w  #2,d0

.loc_102BC:                              ; CODE XREF: sub_10294+20↑j
                asl.w   #1,d0
                move.w  (ram_FF1ACE).l,d1
                andi.w  #1,d1
                add.w   d0,d1
                addi.w  #$59,d1 ; 'Y'
                move.w  d1,$12(a0)
                lea     (unk_102DE).l,a4
                move.w  (a4,d0.w),d0
                rts
; End of function sub_10294


unk_102DE:  dc.w 3, 19, 35

; =============== S U B R O U T I N E =======================================


sub_102E4:                              ; CODE XREF: sub_DAE2:@loc_DC20↑p
                movem.l d0/a4,-(sp)
                move.w  #2,d1
                lea     (ram_FFD33E).l,a4
                tst.w   d0
                bpl.w   .loc_102FA
                neg.w   d0

.loc_102FA:                              ; CODE XREF: sub_102E4+10↑j
; sub_102E4+1E↓j
                cmp.w   -(a4),d0
                bcc.w   .loc_10304
                subq.w  #1,d1
                bne.s   .loc_102FA

.loc_10304:                              ; CODE XREF: sub_102E4+18↑j
                movem.l (sp)+,d0/a4
                rts
; End of function sub_102E4


; =============== S U B R O U T I N E =======================================


sub_1030A:                              ; CODE XREF: sub_100D0+4A↑p
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10320
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10320:                              ; CODE XREF: sub_1030A+A↑j
                move.w  $C(a1),d1
                lea     (ram_FFD33E).l,a4
                move.w  #2,d2
                tst.w   d1
                bmi.w   .loc_10342

.loc_10334:                              ; CODE XREF: sub_1030A+32↓j
                cmp.w   -(a4),d1
                bcc.w   .loc_10350
                subq.w  #1,d2
                bne.s   .loc_10334
                bra.w   .loc_10350


.loc_10342:                              ; CODE XREF: sub_1030A+26↑j
                neg.w   d1

.loc_10344:                              ; CODE XREF: sub_1030A+42↓j
                cmp.w   -(a4),d1
                bcc.w   .loc_1034E
                subq.w  #1,d2
                bne.s   .loc_10344

.loc_1034E:                              ; CODE XREF: sub_1030A+3C↑j
                neg.w   d2

.loc_10350:                              ; CODE XREF: sub_1030A+2C↑j
; sub_1030A+34↑j
                move.w  d2,d1
                addq.w  #2,d1
                move.w  d1,(ram_FF1764).l
                btst    #6,$69(a1)
                beq.w   .loc_10370
                move.w  #2,d1
                bsr.w   sub_10762
                bra.w   .locret_10382


.loc_10370:                              ; CODE XREF: sub_1030A+56↑j
                bsr.w   sub_10384
                bra.w   .locret_10382

                bclr    #4,$69(a1)
                bsr.w   sub_100D0

.locret_10382:                           ; CODE XREF: sub_1030A+62↑j
; sub_1030A+6A↑j
                rts
; End of function sub_1030A


; =============== S U B R O U T I N E =======================================


sub_10384:                              ; CODE XREF: sub_1030A:@loc_10370↑p
                cmp.w   #2,d0
                ble.w   .loc_10390
                move.w  #2,d0

.loc_10390:                              ; CODE XREF: sub_10384+4↑j
                bne.w   .loc_103CA
                btst    #$F,$A(a0)
                beq.w   .loc_103B4
                btst    #5,$69(a1)
                beq.w   .loc_104DA
                subq.w  #2,d1
                bpl.w   .loc_103B0
                neg.w   d1

.loc_103B0:                              ; CODE XREF: sub_10384+26↑j
                bra.w   .loc_10402


.loc_103B4:                              ; CODE XREF: sub_10384+16↑j
                btst    #5,$69(a1)
                bne.w   .loc_104DA
                subq.w  #2,d1
                bpl.w   .loc_103C6
                neg.w   d1

.loc_103C6:                              ; CODE XREF: sub_10384+3C↑j
                bra.w   .loc_10402


.loc_103CA:                              ; CODE XREF: sub_10384:@loc_10390↑j
                btst    #5,$69(a1)
                beq.w   .loc_103EE
                subq.w  #2,d1
                neg.w   d1
                bpl.w   .loc_103E0
                move.w  #0,d1

.loc_103E0:                              ; CODE XREF: sub_10384+54↑j
                btst    #$F,$A(a0)
                bne.w   .loc_10402
                bra.w   .loc_10450


.loc_103EE:                              ; CODE XREF: sub_10384+4C↑j
                subq.w  #2,d1
                bpl.w   .loc_103F8
                move.w  #0,d1

.loc_103F8:                              ; CODE XREF: sub_10384+6C↑j
                btst    #$F,$A(a0)
                bne.w   .loc_10450

.loc_10402:                              ; CODE XREF: sub_10384:@loc_103B0↑j
; sub_10384:@loc_103C6↑j ...
                move.l  a2,-(sp)
                tst.w   d0
                bne.w   .loc_10410
                bset    #$F,$A(a0)

.loc_10410:                              ; CODE XREF: sub_10384+82↑j
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_10446
                bmi.w   .loc_10428
                btst    #1,$6B(a1)
                beq.w   .loc_1043C

.loc_10428:                              ; CODE XREF: sub_10384+96↑j
                btst    #0,$6B(a1)
                beq.w   .loc_1043C
                lea     (unk_106A2).l,a2
                bra.w   .loc_1049A


.loc_1043C:                              ; CODE XREF: sub_10384+A0↑j
; sub_10384+AA↑j
                lea     (unk_105E2).l,a2
                bra.w   .loc_1049A


.loc_10446:                              ; CODE XREF: sub_10384+92↑j
                lea     (unk_10522).l,a2
                bra.w   .loc_1049A


.loc_10450:                              ; CODE XREF: sub_10384+66↑j
; sub_10384+7A↑j
                move.l  a2,-(sp)
                tst.w   d0
                bne.w   .loc_1045E
                bclr    #$F,$A(a0)

.loc_1045E:                              ; CODE XREF: sub_10384+D0↑j
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_10494
                bmi.w   .loc_10476
                btst    #1,$6B(a1)
                beq.w   .loc_1048A

.loc_10476:                              ; CODE XREF: sub_10384+E4↑j
                btst    #0,$6B(a1)
                beq.w   .loc_1048A
                lea     (unk_10702).l,a2
                bra.w   .loc_1049A


.loc_1048A:                              ; CODE XREF: sub_10384+EE↑j
; sub_10384+F8↑j
                lea     (unk_10642).l,a2
                bra.w   .loc_1049A


.loc_10494:                              ; CODE XREF: sub_10384+E0↑j
                lea     (unk_10582).l,a2

.loc_1049A:                              ; CODE XREF: sub_10384+B4↑j
; sub_10384+BE↑j ...
                asl.w   #5,d0
                adda.w  d0,a2
                bsr.w   sub_104E6
                asl.w   #4,d0
                adda.w  d0,a2
                asl.w   #2,d1
                move.w  (a2,d1.w),d0
                move.w  2(a2,d1.w),d1
                btst    #1,$6B(a1)
                beq.w   .loc_104CA
                addi.w  #$102,d1
                move.b  #1,(ram_FF1ADD).l
                bra.w   .loc_104CE


.loc_104CA:                              ; CODE XREF: sub_10384+132↑j
                addi.w  #$D8,d1

.loc_104CE:                              ; CODE XREF: sub_10384+142↑j
                move.w  d1,$12(a0)
                movem.l (sp)+,a2
                bra.w   .locret_104E4


.loc_104DA:                              ; CODE XREF: sub_10384+20↑j
; sub_10384+36↑j
                bclr    #4,$69(a1)
                bsr.w   sub_100D0

.locret_104E4:                           ; CODE XREF: sub_10384+152↑j
                rts
; End of function sub_10384


; =============== S U B R O U T I N E =======================================


sub_104E6:                              ; CODE XREF: sub_10384+11A↑p
                move.w  d3,-(sp)
                tst.w   $18(a1)
                bne.w   .loc_10502
                tst.w   $12(a1)
                beq.w   .loc_10502
                btst    #1,$68(a1)
                bne.w   .loc_1051A

.loc_10502:                              ; CODE XREF: sub_104E6+6↑j
; sub_104E6+E↑j
                move.w  $A(a1),d0
                move.w  (ram_FF1AC8).l,d3
                cmp.w   d3,d0
                bgt.w   .loc_1051A
                move.w  #0,d0
                bra.w   .loc_1051E


.loc_1051A:                              ; CODE XREF: sub_104E6+18↑j
; sub_104E6+28↑j
                move.w  #1,d0

.loc_1051E:                              ; CODE XREF: sub_104E6+30↑j
                move.w  (sp)+,d3
                rts
; End of function sub_104E6


unk_10522:      dc.b   0                ; DATA XREF: sub_10384:@loc_10446↑o
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b $15
                dc.b   0
                dc.b $17
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $1D
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_10582:      dc.b   0                ; DATA XREF: sub_10384:@loc_10494↑o
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $11
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $19
                dc.b   0
                dc.b $18
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $24 ; $
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $27 ; '
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_105E2:      dc.b   0                ; DATA XREF: sub_10384:@loc_1043C↑o
                dc.b   3
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $14
                dc.b   0
                dc.b $15
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1F
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1F
                dc.b   0
                dc.b $1C
                dc.b   0
                dc.b $21 ; !
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_10642:      dc.b   0                ; DATA XREF: sub_10384:@loc_1048A↑o
                dc.b   3
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1C
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1C
                dc.b   0
                dc.b $1A
                dc.b   0
                dc.b $19
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $25 ; %
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $28 ; (
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_106A2:      dc.b   0                ; DATA XREF: sub_10384+AE↑o
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $14
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $14
                dc.b   0
                dc.b $14
                dc.b   0
                dc.b $16
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $1C
                dc.b   0
                dc.b $22 ; "
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
unk_10702:      dc.b   0                ; DATA XREF: sub_10384+FC↑o
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $11
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $11
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b  $E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1D
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $1D
                dc.b   0
                dc.b $1A
                dc.b   0
                dc.b $1A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $26 ; &
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $29 ; )
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0

; =============== S U B R O U T I N E =======================================


sub_10762:                              ; CODE XREF: sub_1030A+5E↑p
                btst    #5,$69(a1)
                beq.w   .loc_1077A
                btst    #$F,$A(a0)
                beq.w   .loc_1079C
                bra.w   .loc_10784


.loc_1077A:                              ; CODE XREF: sub_10762+6↑j
                btst    #$F,$A(a0)
                bne.w   .loc_1079C

.loc_10784:                              ; CODE XREF: sub_10762+14↑j
                cmp.w   #2,d0
                ble.w   .loc_10790
                move.w  #2,d0

.loc_10790:                              ; CODE XREF: sub_10762+26↑j
                move.l  a2,-(sp)
                lea     (word_107EA).l,a2
                bra.w   .loc_107BC


.loc_1079C:                              ; CODE XREF: sub_10762+10↑j
; sub_10762+1E↑j
                cmp.w   #1,d0
                ble.w   .loc_107A8
                move.w  #1,d0

.loc_107A8:                              ; CODE XREF: sub_10762+3E↑j
                move.l  a2,-(sp)
                lea     (word_10802).l,a2
                tst.w   d0
                bne.w   .loc_107BC
                bset    #$F,$A(a0)

.loc_107BC:                              ; CODE XREF: sub_10762+36↑j
; sub_10762+50↑j
                asl.w   #3,d0
                move.w  $A(a1),d2
                cmp.w   (ram_FF1AC8).l,d2
                ble.w   .loc_107CE
                addq.w  #4,d0

.loc_107CE:                              ; CODE XREF: sub_10762+66↑j
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_107DA
                addq.w  #2,d0

.loc_107DA:                              ; CODE XREF: sub_10762+72↑j
                move.w  (a2,d0.w),d0
                movea.l (sp)+,a2
                bra.w   .locret_107E8

                dc.b $61 ; a
                dc.b   0
                dc.b $FB
                dc.b $9E


.locret_107E8:                           ; CODE XREF: sub_10762+7E↑j
                rts
; End of function sub_10762

word_107EA:     dc.w $12C               ; DATA XREF: sub_10762+30↑o
                dc.w $12D
                dc.w $12E
                dc.w $12F
                dc.w $132
                dc.w $133
                dc.w $136
                dc.w $137
                dc.w $138
                dc.w $139
                dc.w $13A
                dc.w $13B
word_10802:     dc.w $12C               ; DATA XREF: sub_10762+48↑o
                dc.w $12D
                dc.w $12E
                dc.w $12F
                dc.w $130
                dc.w $131
                dc.w $134
                dc.w $135
                dc.w $138
                dc.w $139
                dc.w $13A
                dc.w $13B


; =============== S U B R O U T I N E =======================================


sub_1081A:                              ; CODE XREF: sub_100D0+38↑p
                move.w  (Race_ram_FrameDelay).l,d2
                sub.b   d2,$70(a1)
                bgt.w   .loc_10834
                move.b  #0,$70(a1)
                bclr    #2,$6A(a1)

.loc_10834:                              ; CODE XREF: sub_1081A+A↑j
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_1084A
                neg.w   d0
                bset    #$F,$A(a0)

.loc_1084A:                              ; CODE XREF: sub_1081A+24↑j
                cmp.w   #2,d0
                ble.w   .loc_10856
                move.w  #2,d0

.loc_10856:                              ; CODE XREF: sub_1081A+34↑j
                asl.w   #2,d0
                move.w  $A(a1),d2
                cmp.w   (ram_FF1AC8).l,d2
                ble.w   .loc_10868
                addq.w  #2,d0

.loc_10868:                              ; CODE XREF: sub_1081A+48↑j
                move.w  $C(a1),d1
                tst.w   d1
                bpl.w   .loc_10874
                neg.w   d1

.loc_10874:                              ; CODE XREF: sub_1081A+54↑j
                cmp.w   (ram_FFD33A).l,d1
                bcc.w   .loc_10880
                addq.w  #1,d0

.loc_10880:                              ; CODE XREF: sub_1081A+60↑j
                move.w  d0,d1
                btst    #0,$6A(a1)
                beq.w   .loc_10894
                addi.w  #$148,d1
                bra.w   .loc_10898


.loc_10894:                              ; CODE XREF: sub_1081A+6E↑j
                addi.w  #$13C,d1

.loc_10898:                              ; CODE XREF: sub_1081A+76↑j
                move.w  d1,$12(a0)
                lea     (unk_108C2).l,a4
                asl.w   #1,d0
                move.w  (a4,d0.w),d0
                tst.w   $34(a1)
                bne.w   .locret_108C0
                btst    #1,$68(a1)
                bne.w   .locret_108C0
                bset    #$F,$A(a0)

.locret_108C0:                           ; CODE XREF: sub_1081A+92↑j
; sub_1081A+9C↑j
                rts
; End of function sub_1081A


unk_108C2:      dc.b   0                ; DATA XREF: sub_1081A+82↑o
                dc.b   2
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b $12
                dc.b   0
                dc.b $13
                dc.b   0
                dc.b $1A
                dc.b   0
                dc.b $1B
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $23 ; #
                dc.b   0
                dc.b $2B ; +
                dc.b   0
                dc.b $2B ; +

; =============== S U B R O U T I N E =======================================


sub_108DA:                              ; CODE XREF: sub_F40C+1FA↑p
                move.w  #0,$12(a0)
                cmpa.l  #ram_FF2FAA,a1
                bne.w   .loc_1090C
                move.w  #$87,d0
                btst    #3,$69(a1)
                bne.w   .loc_10902
                bclr    #$F,$A(a0)
                bra.w   .locret_10970


.loc_10902:                              ; CODE XREF: sub_108DA+1A↑j
                bset    #$F,$A(a0)
                bra.w   .locret_10970


.loc_1090C:                              ; CODE XREF: sub_108DA+C↑j
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10922
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10922:                              ; CODE XREF: sub_108DA+3C↑j
                asl.w   #2,d0
                move.w  $A(a1),d1
                bpl.w   .loc_10944
                cmp.w   #$FFD0,d1
                blt.w   .loc_1093C
                move.w  #0,d1

.loc_10938:                              ; DATA XREF: sub_107EA+14↑r
                bra.w   .loc_10958


.loc_1093C:                              ; CODE XREF: sub_108DA+56↑j
                move.w  #$FFFF,d1
                bra.w   .loc_10958


.loc_10944:                              ; CODE XREF: sub_108DA+4E↑j
                cmp.w   #$20,d1 ; ' '
                bgt.w   .loc_10954
                move.w  #0,d1

.loc_10950:                              ; DATA XREF: sub_107EA+2C↑r
                bra.w   .loc_10958


.loc_10954:                              ; CODE XREF: sub_108DA+6E↑j
                move.w  #1,d1

.loc_10958:                              ; CODE XREF: sub_108DA:@loc_10938↑j
; sub_108DA+66↑j ...
                addq.w  #1,d1
                add.w   d1,d0
                btst    #3,$69(a1)
                bne.w   .loc_1096C
                addi.w  #$5F,d0 ; '_'
                rts


.loc_1096C:                              ; CODE XREF: sub_108DA+88↑j
                addi.w  #$6F,d0 ; 'o'

.locret_10970:                           ; CODE XREF: sub_108DA+24↑j
; sub_108DA+2E↑j
                rts
; End of function sub_108DA


; =============== S U B R O U T I N E =======================================


Race_WriteSpriteTiles:
                movea.l (Race_ram_NextFrameReady).l,a2
                move.w  #-1,(a2)
                movea.l (Race_ram_NextSpriteSizePtr).l,a3
                move.w  (a3),d2
                cmpi.w  #$BB8,(a3)
                ble.w   .loc_10990
                move.w  #$BB8,d2 ; not more than $1770 bytes at once
.loc_10990:
                sub.w   d2,(a3)
                move.l  (Race_ram_NextSpriteTileArray).l,d0
                move.w  (Race_ram_SpriteDestination).l,d1
                bsr.w   DmaWriteVRAM
                addi.l  #$1770,(Race_ram_NextSpriteTileArray).l
                addi.w  #$1770,(Race_ram_SpriteDestination).l
                rts
; End of function Race_WriteSpriteTiles


; =============== S U B R O U T I N E =======================================


sub_109B6:                              ; CODE XREF: Race_Update+21A↑p
                move.w  #$FFFF,(ram_FF1B30).l
                movea.l (ram_FFD7C4).l,a1
                move.w  (a1),d0
                move.w  (ram_FF1E68).l,d1
                sub.w   (ram_FFD7C8).l,d1
                bpl.w   .loc_10A1A
                cmpa.l  (RaceTrack_Data4).l,a1
                beq.w   .loc_10A1A
                subq.w  #4,a1
                move.l  a1,(ram_FFD7C4).l
                move.w  (a1),d0
                move.w  2(a1),d2
                rol.w   #4,d2
                andi.w  #$F,d2
                addq.w  #1,d2
                move.w  d0,d3
                lsr.w   #8,d3
                andi.w  #$1F,d3
                move.w  d3,d1
                addq.w  #1,d1
                mulu.w  d2,d1
                sub.w   d1,(ram_FFD7C8).l
                move.w  (ram_FF1E68).l,d1
                sub.w   (ram_FFD7C8).l,d1
                bra.w   .loc_10A2E


.loc_10A1A:                              ; CODE XREF: sub_109B6+1C↑j
; sub_109B6+26↑j ...
                move.w  2(a1),d2
                rol.w   #4,d2
                andi.w  #$F,d2
                addq.w  #1,d2
                move.w  d0,d3
                lsr.w   #8,d3
                andi.w  #$1F,d3

.loc_10A2E:                              ; CODE XREF: sub_109B6+60↑j
                move.w  d1,d4
                addq.w  #1,d4
                ext.l   d4
                divu.w  d2,d4
                cmp.w   d3,d4
                ble.w   .loc_10A78
                addi.l  #4,(ram_FFD7C4).l
                addq.w  #4,a1
                move.w  (a1),d0
                cmp.w   #$FFFF,d0
                bne.w   .loc_10A5E
                movea.l (RaceTrack_Data4).l,a1
                move.l  a1,(ram_FFD7C4).l

.loc_10A5E:                              ; CODE XREF: sub_109B6+98↑j
                addq.w  #1,d3
                mulu.w  d3,d2
                add.w   d2,(ram_FFD7C8).l
                move.w  (a1),d0
                move.w  (ram_FF1E68).l,d1
                sub.w   (ram_FFD7C8).l,d1
                bra.s   .loc_10A1A


.loc_10A78:                              ; CODE XREF: sub_109B6+82↑j
                sub.w   d4,d3
                swap    d4
                move.w  d4,d1
                neg.w   d1
                move.b  d0,d5
                rol.b   #1,d5
                btst    #$F,d0
                beq.w   .loc_10A94
                swap    d4
                andi.w  #1,d4
                eor.w   d4,d5

.loc_10A94:                              ; CODE XREF: sub_109B6+D2↑j
                andi.w  #1,d5
                ror.w   #2,d5
                btst    #$E,d0
                beq.w   .loc_10AA6
                bset    #$F,d5

.loc_10AA6:                              ; CODE XREF: sub_109B6+E8↑j
                move.w  2(a1),d6
                lea     (ram_FFD37C).l,a0
                move.w  (ram_FFDE72).l,d7
                mulu.w  #$14,d7
                adda.w  d7,a0
                move.w  d0,d4
                andi.l  #$7F,d4
                addi.w  #$186,d4
                cmp.w   #$205,d4
                beq.w   .loc_10AFC
                cmp.w   #$1BB,d4
                bmi.w   .loc_10AFC
                cmp.w   #$1EA,d4
                bmi.w   .loc_10AE8
                addi.w  #$2F,d4 ; '/'
                bra.w   .loc_10AFC


.loc_10AE8:                              ; CODE XREF: sub_109B6+126↑j
                move.w  d4,d7
                subi.w  #$1BB,d7
                asl.w   #1,d7
                addi.w  #$1BB,d7
                move.w  d7,d4
                addq.w  #1,d4
                swap    d4
                move.w  d7,d4

.loc_10AFC:                              ; CODE XREF: sub_109B6+116↑j
; sub_109B6+11E↑j ...
                exg     d0,d1
                move.w  d6,d7
                andi.w  #$700,d7
                andi.w  #$FF,d6

.loc_10B08:                              ; CODE XREF: sub_109B6:@loc_10BB2↓j
; sub_109B6+28E↓j
                add.w   d2,d0
                cmp.w   #$20,d0 ; ' '
                bcc.w   .loc_10C48
                cmp.w   #$205,d4
                beq.w   .loc_10BB2
                move.w  d4,8(a0)
                swap    d4
                move.w  d4,$12(a0)
                swap    d4
                cmp.w   #$186,d4
                bne.w   .loc_10B48
                move.w  d0,(ram_FF1B30).l
                move.w  d3,(ram_FF1B2E).l
                addi.w  #1,(ram_FF1B2E).l
                add.w   d3,d0
                bra.w   .loc_10BB6


.loc_10B48:                              ; CODE XREF: sub_109B6+174↑j
                move.w  d0,$A(a0)
                or.w    d5,$A(a0)
                or.w    d7,$A(a0)
                ori.w   #$1000,$A(a0)
                move.w  d6,$10(a0)
                tst.w   $12(a0)
                beq.w   .loc_10B6C
                bset    #7,$B(a0)

.loc_10B6C:                              ; CODE XREF: sub_109B6+1AC↑j
                movem.l d6-d7,-(sp)
                lea     (ram_FF1B50).l,a6
                move.w  d0,d6
                ext.l   d6
                swap    d6
                clr.l   d7
                move.w  (ram_FF1E6A).l,d7
                sub.l   d7,d6
                move.w  (ram_FFDE72).l,d7
                asl.w   #2,d7
                move.l  d6,(a6,d7.w)
                movem.l (sp)+,d6-d7
                movem.l d0-d7/a1,-(sp)
                bsr.w   sub_10C4E
                movem.l (sp)+,d0-d7/a1
                adda.w  #$14,a0
                btst    #$F,d1
                beq.w   .loc_10BB2
                bchg    #$E,d5

.loc_10BB2:                              ; CODE XREF: sub_109B6+160↑j
; sub_109B6+1F4↑j
                dbf     d3,.loc_10B08

.loc_10BB6:                              ; CODE XREF: sub_109B6+18E↑j
                addq.w  #4,a1
                move.w  (a1),d1
                cmp.w   #$FFFF,d1
                bne.w   .loc_10BCA
                movea.l (RaceTrack_Data4).l,a1
                move.w  (a1),d1

.loc_10BCA:                              ; CODE XREF: sub_109B6+208↑j
                move.w  2(a1),d2
                rol.w   #4,d2
                andi.w  #$F,d2
                addq.w  #1,d2
                move.w  d1,d3
                lsr.w   #8,d3
                andi.w  #$1F,d3
                move.w  d1,d4
                andi.l  #$7F,d4
                addi.w  #$186,d4
                cmp.w   #$205,d4
                beq.w   .loc_10C1E
                cmp.w   #$1BB,d4
                bmi.w   .loc_10C1E
                cmp.w   #$1EA,d4
                bmi.w   .loc_10C0A
                addi.w  #$2F,d4 ; '/'
                bra.w   .loc_10C1E


.loc_10C0A:                              ; CODE XREF: sub_109B6+248↑j
                move.w  d4,d7
                subi.w  #$1BB,d7
                asl.w   #1,d7
                addi.w  #$1BB,d7
                move.w  d7,d4
                addq.w  #1,d4
                swap    d4
                move.w  d7,d4

.loc_10C1E:                              ; CODE XREF: sub_109B6+238↑j
; sub_109B6+240↑j ...
                clr.w   d5
                move.b  d1,d5
                rol.b   #1,d5
                andi.w  #1,d5
                ror.w   #2,d5
                btst    #$E,d1
                beq.w   .loc_10C36
                bset    #$F,d5

.loc_10C36:                              ; CODE XREF: sub_109B6+278↑j
                move.w  2(a1),d6
                move.w  d6,d7
                andi.w  #$700,d7
                andi.w  #$FF,d6
                bra.w   .loc_10B08


.loc_10C48:                              ; CODE XREF: sub_109B6+158↑j
                move.w  #$FFFF,(a0)
                rts
; End of function sub_109B6


; =============== S U B R O U T I N E =======================================


sub_10C4E:                              ; CODE XREF: sub_109B6+1E4↑p
                move.w  $A(a0),d0
                andi.w  #$1F,d0
                move.w  d0,-(sp)
                asl.w   #2,d0
                lea     (ram_FF310A).l,a2
                move.w  (a2,d0.w),d7
                move.w  (sp)+,d0
                move.w  d0,d2
                move.w  (ram_FF1E6A).l,d1
                andi.w  #$FF00,d1
                lsr.w   #8,d1
                neg.w   d1
                asl.w   #8,d0
                add.w   d1,d0
                move.w  d0,$E(a0)
                move.w  d0,d1
                addi.w  #$100,d0
                clr.l   d3
                move.w  d6,d3
                andi.w  #$F0,d3
                asl.w   #3,d3
                cmp.w   d3,d1
                addi.w  #$200,d1
                addi.w  #$200,d3
                swap    d3
                lsr.l   #2,d3
                divu.w  d1,d3
                move.w  d3,4(a0)
                andi.w  #$F,d6
                move.w  d6,d5
                swap    d6
                clr.w   d6
                lsr.l   #2,d6
                ext.l   d7
                ext.l   d5
                asl.l   #6,d5
                btst    #$E,$A(a0)
                beq.w   .loc_10CCA
                sub.l   d5,d7
                bpl.w   .loc_10CD2
                neg.l   d7
                bra.w   .loc_10CD2


.loc_10CCA:                              ; CODE XREF: sub_10C4E+6C↑j
                add.l   d5,d7
                bpl.w   .loc_10CD2
                neg.l   d7

.loc_10CD2:                              ; CODE XREF: sub_10C4E+72↑j
; sub_10C4E+78↑j ...
                ext.l   d0
                addi.l  #$100,d7
                cmp.l   d0,d7
                bpl.w   .loc_10D32
                divu.w  d0,d6
                bvs.w   .loc_10D32
                asl.w   #1,d2
                lea     (ram_FF3236).l,a2
                move.w  (a2,d2.w),d0
                move.w  d0,d3
                lea     (ram_FFD77C).l,a2
                cmp.w   (a2,d2.w),d0
                move.w  (a2,d2.w),6(a0)
                move.w  d0,2(a0)
                lea     (ram_FF31D2).l,a2
                move.w  (a2,d2.w),d0
                neg.w   d0
                btst    #$E,$A(a0)
                bne.w   .loc_10D20
                neg.w   d6

.loc_10D20:                              ; CODE XREF: sub_10C4E+CC↑j
                move.w  d6,$C(a0)
                add.w   d6,d0
                bmi.w   .loc_10D32
                cmp.w   #$23C,d0
                bmi.w   .loc_10D38

.loc_10D32:                              ; CODE XREF: sub_10C4E+8E↑j
; sub_10C4E+94↑j ...
                suba.w  #$14,a0
                rts


.loc_10D38:                              ; CODE XREF: sub_10C4E+E0↑j
                neg.w   d0
                move.w  d0,(a0)
                addi.w  #1,(ram_FFDE72).l
                rts
; End of function sub_10C4E


; =============== S U B R O U T I N E =======================================


sub_10D46:                              ; CODE XREF: Race_Update+260↑p
                movem.l d0-d7/a0-a7,-(sp)
                move.l  (a0)+,(a1)
                move.w  #0,(a2)
                cmpi.w  #$FFFF,(a1)
                beq.w   .loc_10DAC
                move.w  #1,d0
.loc_10D5C:
                move.w  d0,d1
                subq.w  #1,d1
                movea.l a1,a3
                movea.l a2,a4
                move.l  (a0)+,d4
                cmp.w   #$FFFF,d4
                beq.w   .loc_10DAC
.loc_10D6E:
                cmp.l   (a3)+,d4
                bmi.w   .loc_10D86
                dbf     d1,.loc_10D6E
                move.l  d4,(a3)
                move.w  d0,d6
                asl.w   #1,d6
                move.w  d0,(a4,d6.w)
                bra.w   .loc_10DA8
.loc_10D86:
                move.w  d0,d6
                sub.w   d1,d6
                subq.w  #1,d6
                asl.w   #1,d6
                adda.w  d6,a4
                move.w  d0,d6
                subq.l  #4,a3
.loc_10D94:
                move.l  (a3),d5
                move.l  d4,(a3)+
                move.l  d5,d4
                move.w  (a4),d7
                move.w  d6,(a4)+
                move.w  d7,d6
                dbf     d1,.loc_10D94
                move.l  d4,(a3)
                move.w  d6,(a4)
.loc_10DA8:
                addq.w  #1,d0
                bra.s   .loc_10D5C
.loc_10DAC:
                asl.w   #1,d0
                move.w  d4,(a2,d0.w)
                asl.w   #1,d0
                move.l  d4,(a1,d0.w)
                movem.l (sp)+,d0-d7/a0-a7
                rts
; End of function sub_10D46


; =============== S U B R O U T I N E =======================================


sub_10DBE:                              ; CODE XREF: Race_Update+AE↑p
                movea.l (Global_ram_PalettePtr).l,a0
                adda.w  #$1A,a0
                lea     (ram_FF1EAA).l,a1
                lea     (ram_FF1AFA).l,a2
                bsr.w   sub_10E00
                rts
; End of function sub_10DBE


; =============== S U B R O U T I N E =======================================


sub_10DDA:                              ; CODE XREF: Race_Update+B4↑p
                movea.l (Global_ram_PalettePtr).l,a0
                adda.w  #$5A,a0 ; 'Z'
                movea.l (ram_FF1908).l,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_10DFE
                lea     (ram_FF1B04).l,a2
                bsr.w   sub_10E00

.locret_10DFE:                           ; CODE XREF: sub_10DDA+16↑j
                rts
; End of function sub_10DDA


; =============== S U B R O U T I N E =======================================


sub_10E00:                              ; CODE XREF: sub_10DBE+16↑p
; sub_10DDA+20↑p
                move.w  $12(a1),d0
                beq.w   .loc_10E12
                cmpi.b  #3,$6E(a1)
                bne.w   .loc_10E18

.loc_10E12:                              ; CODE XREF: sub_10E00+4↑j
                clr.l   d0
                bra.w   .loc_10E3A


.loc_10E18:                              ; CODE XREF: sub_10E00+E↑j
                move.w  (Race_ram_FrameDelay).l,d1
                sub.w   d1,(a2)
                bgt.w   .locret_10E3C
                lsr.w   #8,d0
                subi.w  #$10,d0
                neg.w   d0
                bpl.w   .loc_10E32
                clr.w   d0

.loc_10E32:                              ; CODE XREF: sub_10E00+2C↑j
                move.w  d0,(a2)+
                move.l  (a2),d0
                swap    d0
                move.l  d0,(a2)

.loc_10E3A:                              ; CODE XREF: sub_10E00+14↑j
                move.l  d0,(a0)

.locret_10E3C:                           ; CODE XREF: sub_10E00+20↑j
                rts
; End of function sub_10E00


unk_10E3E:      dc.b $18                ; DATA XREF: sub_F842+64↑o
                dc.b $10
                dc.b   6
                dc.b   1
                dc.b $FA
                dc.b $F0
                dc.b $E8
                dc.b   0
                dc.b $11
                dc.b   8
                dc.b   1
                dc.b $FC
                dc.b $F7
                dc.b $F2
                dc.b $EC
                dc.b   0
                dc.b  $B
                dc.b   3
                dc.b $F7
                dc.b $F7
                dc.b $F7
                dc.b $F2
                dc.b $E8
                dc.b   0
                dc.b $FA
                dc.b $F6
                dc.b $F1
                dc.b $F1
                dc.b $F1
                dc.b $EE
                dc.b $E6
                dc.b   0
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b $E5
                dc.b   0

; =============== S U B R O U T I N E =======================================


sub_10E66:                              ; CODE XREF: Race_Update+A2↑p
                bset    #6,(ram_FF1EAA + STRUCT_OFFSET_68).l
                lea     (ram_FF1A08).l,a2

.loc_10E74:                              ; CODE XREF: sub_10E66:@loc_11034↓j
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .locret_11038
                btst    #7,$68(a1)
                move.w  $14(a1),d1
                beq.w   .loc_10EB8
                btst    #3,$68(a1)
                beq.w   .loc_10E9C
                move.w  d1,d0
                asr.w   #2,d0
                sub.w   d0,d1

.loc_10E9C:                              ; CODE XREF: sub_10E66+2C↑j
                move.w  (Race_ram_FrameDelay).l,d2
                muls.w  d2,d1
                move.w  $12(a1),d0
                add.w   d1,d0
                move.w  d0,$12(a1)
                bpl.w   .loc_10EB8
                move.w  #0,$12(a1)

.loc_10EB8:                              ; CODE XREF: sub_10E66+22↑j
; sub_10E66+48↑j
                move.w  $12(a1),d0
                move.w  (Race_ram_FrameDelay).l,d2
                mulu.w  d2,d0
                move.l  d0,$26(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_10F2A
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_10F2A
                btst    #4,$68(a1)
                beq.w   .loc_10EF8
                cmpi.b  #3,$6E(a1)
                bne.w   .loc_10EF8
                bsr.w   Race_HandleInputOnFoot
                bra.w   .loc_10F6C


.loc_10EF8:                              ; CODE XREF: sub_10E66+7C↑j
; sub_10E66+86↑j
                bsr.w   sub_113CA
                bsr.w   sub_13EFA
                btst    #4,$68(a1)
                beq.w   .loc_10F14
                btst    #3,$69(a1)
                bne.w   .loc_10F22

.loc_10F14:                              ; CODE XREF: sub_10E66+A0↑j
                bclr    #3,$68(a1)
                bsr.w   sub_11448
                bra.w   .loc_10F6C


.loc_10F22:                              ; CODE XREF: sub_10E66+AA↑j
                bsr.w   sub_11940
                bra.w   .loc_10F6C


.loc_10F2A:                              ; CODE XREF: sub_10E66+68↑j
; sub_10E66+72↑j
                btst    #6,$68(a1)
                bne.w   .loc_10F3C
                bsr.w   sub_1103A
                bra.w   .loc_11034


.loc_10F3C:                              ; CODE XREF: sub_10E66+CA↑j
                btst    #4,$68(a1)
                beq.w   .loc_10F58
                cmpi.b  #3,$6E(a1)
                bne.w   .loc_10F58
                bsr.w   Race_HandleInputOnFoot
                bra.w   .loc_10F6C


.loc_10F58:                              ; CODE XREF: sub_10E66+DC↑j
; sub_10E66+E6↑j
                tst.w   $12(a1)
                beq.w   .loc_10F6C
                bsr.w   sub_113A4
                bsr.w   sub_13EFA
                bsr.w   sub_116E2

.loc_10F6C:                              ; CODE XREF: sub_10E66+8E↑j
; sub_10E66+B8↑j ...
                move.w  $36(a1),d1
                move.w  d1,d3
                sub.w   0.w(a1),d1
                bpl.w   .loc_10FAC
                cmp.w   #$FCA0,d1
                bpl.w   .loc_10F9A
                neg.w   d1
                subi.w  #$360,d1
                sub.w   d1,$22(a1)
                move.w  #$FCA0,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)
                bra.w   .loc_10FAC


.loc_10F9A:                              ; CODE XREF: sub_10E66+118↑j
                cmp.w   #$FF20,d1
                bpl.w   .loc_10FD8
                bset    #3,$68(a1)
                bra.w   .loc_10FDE


.loc_10FAC:                              ; CODE XREF: sub_10E66+110↑j
; sub_10E66+130↑j
                cmp.w   #$360,d1
                bmi.w   .loc_10FC6
                subi.w  #$360,d1
                add.w   d1,$22(a1)
                move.w  #$360,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)

.loc_10FC6:                              ; CODE XREF: sub_10E66+14A↑j
                cmp.w   #$E0,d1
                bmi.w   .loc_10FD8
                bset    #3,$68(a1)
                bra.w   .loc_10FDE


.loc_10FD8:                              ; CODE XREF: sub_10E66+138↑j
; sub_10E66+164↑j
                bclr    #3,$68(a1)

.loc_10FDE:                              ; CODE XREF: sub_10E66+142↑j
; sub_10E66+16E↑j
                neg.w   d1
                move.w  d1,$30(a1)
                bsr.w   sub_13746
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_11018
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_11018
                tst.w   (ram_FF1ACC).l
                beq.w   .loc_11010
                move.w  $1A(a1),$30(a1)
                bra.w   .loc_1101C


.loc_11010:                              ; CODE XREF: sub_10E66+19C↑j
                bsr.w   sub_11B7A
                bra.w   .loc_1101C


.loc_11018:                              ; CODE XREF: sub_10E66+188↑j
; sub_10E66+192↑j
                bsr.w   sub_12BD2

.loc_1101C:                              ; CODE XREF: sub_10E66+1A6↑j
; sub_10E66+1AE↑j
                cmpi.b  #$10,$71(a1)
                bpl.w   .loc_11034
                btst    #4,$68(a1)
                beq.w   .loc_11034
                bsr.w   sub_1180C

.loc_11034:                              ; CODE XREF: sub_10E66+D2↑j
; sub_10E66+1BC↑j ...
                bra.w   .loc_10E74


.locret_11038:                           ; CODE XREF: sub_10E66+14↑j
                rts
; End of function sub_10E66


; =============== S U B R O U T I N E =======================================


sub_1103A:                              ; CODE XREF: sub_10E66+CE↑p
                move.l  d0,-(sp)
                move.w  $30(a1),$1A(a1)
                move.w  $32(a1),$1C(a1)
                move.l  $26(a1),d0
                move.l  4(a1),d4
                move.l  d4,$1E(a1)
                add.l   d4,d0
                move.l  d0,4(a1)
                swap    d4
                cmp.w   (RaceTrack_Data1).l,d4
                bmi.w   .loc_1107E
                btst    #7,$68(a1)
                bne.w   .loc_1107E
                bset    #7,$68(a1)
                move.l  (ram_FF1E9A).l,$62(a1)

.loc_1107E:                              ; CODE XREF: sub_1103A+28↑j
; sub_1103A+32↑j
                move.w  d1,2(a1)
                bclr    #4,$68(a1)
                move.b  #$FF,$6E(a1)
                move.w  #0,$32(a1)
                move.w  #0,$2E(a1)
                bclr    #0,$68(a1)
                move.w  #0,$2C(a1)
                bsr.w   sub_12BD2
                move.l  (sp)+,d0
                rts
; End of function sub_1103A


; =============== S U B R O U T I N E =======================================


Race_HandleInputOnFoot:
                movem.l d0-d2/a0,-(sp)
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_258AE).l,a0
                movea.l (a0,d0.w),a0
                clr.w   d3
                move.w  $30(a0),d1
                sub.w   $30(a1),d1
                subi.w  #$20,d1 ; ' '
                move.l  4(a0),d2
                sub.l   4(a1),d2
                addi.l  #$2000,d2
                asr.l   #8,d2
                beq.w   .loc_11182
                tst.w   d1
                beq.w   .loc_1115C
                move.w  #$7D0,d0
                lsr.w   #8,d0
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_1112C
                move.b  (Race_ram_CurrentButtons).l,d3
                andi.w  #$4F,d3
                beq.w   .loc_1112C
                btst    #6,d3
                beq.w   .loc_11124
                move.l  #0,$26(a1)
                move.w  #0,$22(a1)
                bra.w   .loc_111F4
.loc_11124:
                bsr.w   Race_AnotherInputOnFoot
                bra.w   .loc_1119E
.loc_1112C:
                bsr.w   sub_11268
                move.w  d1,8(a1)
                tst.w   d2
                bmi.w   .loc_1114A
                bclr    #3,$69(a1)
                asl.w   #8,d2
                move.w  d2,$12(a1)
                bra.w   .loc_1119E
.loc_1114A:
                bset    #3,$69(a1)
                neg.w   d2
                asl.w   #8,d2
                move.w  d2,$12(a1)
                bra.w   .loc_1119E
.loc_1115C:
                bclr    #3,$69(a1)
                tst.w   d2
                bpl.w   .loc_1116E
                bset    #3,$69(a1)
.loc_1116E:
                move.w  #0,d1
                move.w  d1,8(a1)
                move.w  #$7D0,d2
                move.w  d2,$12(a1)
                bra.w   .loc_1119E
.loc_11182:
                move.w  #$7D0,d2
                lsr.w   #8,d2
                tst.w   d1
                bpl.w   .loc_11190
                neg.w   d2
.loc_11190:
                move.w  d2,8(a1)
                move.w  d2,d1
                move.w  #0,d2
                move.w  d2,$12(a1)
.loc_1119E:
                muls.w  (Race_ram_FrameDelay).l,d1
                move.w  d1,$22(a1)
                add.w   d1,0.w(a1)
                mulu.w  (Race_ram_FrameDelay).l,d2
                move.l  d2,$26(a1)
                move.l  d2,d0
                btst    #3,$69(a1)
                bne.w   .loc_111DC
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_111D4
                bsr.w   sub_11448
                bra.w   .loc_111F4
.loc_111D4:
                bsr.w   sub_116E2
                bra.w   .loc_111F4
.loc_111DC:
                move.w  (ram_FF1E82).l,d7
                sub.w   (ram_FF1E68).l,d7
                cmp.w   #$40,d7
                bpl.w   .loc_111F4
                bsr.w   sub_11940
.loc_111F4:
                movem.l (sp)+,d0-d2/a0
                rts
; End of function Race_HandleInputOnFoot


; =============== S U B R O U T I N E =======================================


Race_AnotherInputOnFoot:
                move.b  (Race_ram_CurrentButtons).l,d3
                move.w  d3,-(sp)
                move.b  d3,d4
                andi.b  #$C,d3
                beq.w   .loc_11214
                move.w  #$80,d1
                bra.w   .loc_11220
.loc_11214:
                move.w  #0,d1
                move.w  #$100,d2
                bra.w   .loc_11234
.loc_11220:
                andi.b  #3,d4
                beq.w   .loc_11230
                move.w  #$100,d2
                bra.w   .loc_11234
.loc_11230:
                move.w  #0,d2
.loc_11234:
                bsr.w   sub_11268
                move.w  (sp)+,d3
                btst    #2,d3
                beq.w   .loc_11244
                neg.w   d1
.loc_11244:
                move.w  d1,8(a1)
                btst    #1,d3
                beq.w   .loc_1125A
                bset    #3,$69(a1)
                bra.w   .loc_11260
.loc_1125A:
                bclr    #3,$69(a1)
.loc_11260:
                asl.w   #8,d2
                move.w  d2,$12(a1)
                rts
; End of function Race_AnotherInputOnFoot


; =============== S U B R O U T I N E =======================================


sub_11268:
                tst.w   d1
                bmi.w   .loc_11298
                tst.w   d2
                bmi.w   .loc_11284
                bsr.w   sub_112C8
                mulu.w  d0,d1
                swap    d1
                mulu.w  d0,d2
                swap    d2
                bra.w   .locret_112C6
.loc_11284:
                neg.w   d2
                bsr.w   sub_112C8
                mulu.w  d0,d1
                swap    d1
                mulu.w  d0,d2
                swap    d2
                neg.w   d2
                bra.w   .locret_112C6
.loc_11298:
                tst.w   d2
                bpl.w   .loc_112B6
                neg.w   d1
                neg.w   d2
                bsr.w   sub_112C8
                mulu.w  d0,d1
                swap    d1
                neg.w   d1
                mulu.w  d0,d2
                swap    d2
                neg.w   d2
                bra.w   .locret_112C6
.loc_112B6:
                neg.w   d1
                bsr.w   sub_112C8
                mulu.w  d0,d1
                swap    d1
                neg.w   d1
                mulu.w  d0,d2
                swap    d2
.locret_112C6:
                rts
; End of function sub_11268


; =============== S U B R O U T I N E =======================================


sub_112C8:                              ; CODE XREF: sub_11268+C↑p
; sub_11268+1E↑p ...
                move.l  a0,-(sp)
                cmp.w   d2,d1
                bne.w   .loc_112DC
                move.w  #$80,d1
                move.w  #$80,d2
                bra.w   .loc_11304


.loc_112DC:                              ; CODE XREF: sub_112C8+4↑j
                bmi.w   .loc_112F4
                ext.l   d2
                swap    d2
                divu.w  d1,d2
                lsr.w   #8,d2
                clr.w   d1
                move.b  #$FF,d1
                sub.b   d2,d1
                bra.w   .loc_11304


.loc_112F4:                              ; CODE XREF: sub_112C8:@loc_112DC↑j
                ext.l   d1
                swap    d1
                divu.w  d2,d1
                lsr.w   #8,d1
                clr.w   d2
                move.b  #$FF,d2
                sub.b   d1,d2

.loc_11304:                              ; CODE XREF: sub_112C8+10↑j
; sub_112C8+28↑j
                lea     (unk_7DCA8).l,a0
                asl.w   #1,d1
                move.w  (a0,d1.w),d1
                asl.w   #1,d2
                move.w  (a0,d2.w),d2
                movea.l (sp)+,a0
                rts
; End of function sub_112C8


                dc.b $48 ; H
                dc.b $E7
                dc.b $F0
                dc.b $80
                dc.b $10
                dc.b $29 ; )
                dc.b   0
                dc.b $71 ; q
                dc.b $48 ; H
                dc.b $80
                dc.b $E5
                dc.b $40 ; @
                dc.b $41 ; A
                dc.b $F9
                dc.b   0
                dc.b   2
                dc.b $58 ; X
                dc.b $AE
                dc.b $20
                dc.b $70 ; p
                dc.b   0
                dc.b   0
                dc.b $30 ; 0
                dc.b $28 ; (
                dc.b   0
                dc.b $30 ; 0
                dc.b $90
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b   4
                dc.b $40 ; @
                dc.b   0
                dc.b $20
                dc.b $48 ; H
                dc.b $C0
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $36 ; 6
                dc.b $36 ; 6
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $56 ; V
                dc.b $24 ; $
                dc.b $29 ; )
                dc.b   0
                dc.b   4
                dc.b $94
                dc.b $A8
                dc.b   0
                dc.b   4
                dc.b   6
                dc.b $82
                dc.b   0
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b $44 ; D
                dc.b $82
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $84
                dc.b $C3
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $81
                dc.b $C2
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b   8
                dc.b $C1
                dc.b $F9
                dc.b   0
                dc.b $FF
                dc.b $30 ; 0
                dc.b $4A ; J
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $22 ; "
                dc.b $D1
                dc.b $69 ; i
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $61 ; a
                dc.b   0
                dc.b   0
                dc.b $B4
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $61 ; a
                dc.b   0
                dc.b   5
                dc.b $A4
                dc.b $4C ; L
                dc.b $DF
                dc.b   1
                dc.b  $F
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_113A4:                              ; CODE XREF: sub_10E66+FA↑p
; sub_12868+40↓p
                move.l  $26(a1),d0
                lsr.l   #8,d0
                move.w  8(a1),d1
                muls.w  d1,d0
                asr.l   #8,d0
                btst    #5,$68(a1)
                beq.w   .loc_113C0
                bsr.w   sub_1406A

.loc_113C0:                              ; CODE XREF: sub_113A4+14↑j
                move.w  d0,$22(a1)
                add.w   d0,0.w(a1)
                rts
; End of function sub_113A4


; =============== S U B R O U T I N E =======================================


sub_113CA:                              ; CODE XREF: sub_10E66:@loc_10EF8↑p
                move.l  $26(a1),d0
                lsr.l   #8,d0
                move.l  d0,d1
                muls.w  $42(a1),d0
                asr.l   #8,d0
                move.w  d0,$C(a1)
                btst    #0,$68(a1)
                beq.w   .loc_113F2
                clr.l   d0
                bclr    #5,$68(a1)
                bra.w   .loc_1143E


.loc_113F2:                              ; CODE XREF: sub_113CA+18↑j
                tst.b   $6E(a1)
                bmi.w   .loc_11402
                move.w  8(a1),d0
                bra.w   .loc_11406


.loc_11402:                              ; CODE XREF: sub_113CA+2C↑j
                move.w  d0,8(a1)

.loc_11406:                              ; CODE XREF: sub_113CA+34↑j
                add.l   d0,(ram_FF1E5C).l
                sub.l   $36(a1),d0
                exg     d0,d1
                muls.w  d1,d0
                asr.l   #8,d0
                btst    #5,$68(a1)
                beq.w   .loc_11424
                bsr.w   sub_1406A

.loc_11424:                              ; CODE XREF: sub_113CA+52↑j
                tst.w   d0
                bpl.w   .loc_11438
                neg.w   d0
                mulu.w  #$D000,d0
                swap    d0
                neg.w   d0
                bra.w   .loc_1143E


.loc_11438:                              ; CODE XREF: sub_113CA+5C↑j
                mulu.w  #$D000,d0
                swap    d0

.loc_1143E:                              ; CODE XREF: sub_113CA+24↑j
; sub_113CA+6A↑j
                move.w  d0,$22(a1)
                add.w   d0,0.w(a1)
                rts
; End of function sub_113CA


; =============== S U B R O U T I N E =======================================


sub_11448:                              ; CODE XREF: sub_10E66+B4↑p
; Race_HandleInputOnFoot+11E↑p
                movem.l d0-d7/a0-a6,-(sp)
                move.w  $30(a1),$1A(a1)
                move.w  $32(a1),$1C(a1)
                move.l  $26(a1),d0
                move.l  4(a1),d4
                move.l  d4,$1E(a1)
                add.l   d4,d0
                move.l  d0,4(a1)
                swap    d0
                swap    d4
                move.w  d4,d2
                sub.w   d4,d0
                swap    d4
                neg.w   d4
                lsr.w   #8,d4
                movea.w d4,a6
                move.w  #0,(ram_FF1E92).l
                move.w  #0,d6
                move.w  #0,d7
                lea     (ram_FFDC58).l,a4
                move.w  d2,d3
                sub.w   (ram_FF1E68).l,d3
                bpl.w   .loc_1149E
                neg.w   d3

.loc_1149E:                              ; CODE XREF: sub_11448+50↑j
                cmp.w   #$40,d3 ; '@'
                bpl.w   .loc_115C0
                cmp.w   (RaceTrack_Data1).l,d2
                bmi.w   .loc_114F8
                move.w  #0,(ram_FF369A).l
                move.w  #$16F,(ram_FF3698).l
                tst.w   (ram_FF1ACC).l
                bne.w   .loc_114F8
                bset    #7,$68(a1)
                move.l  (ram_FF1E9A).l,$62(a1)
                move.w  #1,(ram_FF1ACC).l
                move.w  #0,(ram_FF1ACE).l
                move.w  #$12,(ram_FF1AD0).l
                move.w  #0,(ram_FF1AD2).l

.loc_114F8:                              ; CODE XREF: sub_11448+64↑j
; sub_11448+7E↑j
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4
                subq.w  #1,d0
                bmi.w   .loc_11552

.loc_11506:                              ; CODE XREF: sub_11448+106↓j
                move.b  (a4)+,d3
                ext.w   d3
                add.w   d3,d6
                move.b  (a4)+,d5
                cmpa.l  #Race_ram_NextSpriteTileArray,a4
                bmi.w   .loc_1151E
                lea     (ram_FFDC58).l,a4

.loc_1151E:                              ; CODE XREF: sub_11448+CC↑j
                ext.w   d5
                add.w   d5,d7
                btst    #0,$68(a1)
                bne.w   .loc_11548
                cmp.w   $2C(a1),d5
                bmi.w   .loc_11548
                movea.w d4,a6
                move.w  d5,$2C(a1)
                move.w  d7,-(sp)
                add.w   $3A(a1),d7
                move.w  d7,(ram_FF1E92).l
                move.w  (sp)+,d7

.loc_11548:                              ; CODE XREF: sub_11448+E0↑j
; sub_11448+E8↑j
                addi.w  #$100,d4
                addq.w  #1,d2
                dbf     d0,.loc_11506

.loc_11552:                              ; CODE XREF: sub_11448+BA↑j
                add.w   d7,$3A(a1)
                move.w  6(a1),d0
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_1156C
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_1156E


.loc_1156C:                              ; CODE XREF: sub_11448+116↑j
                mulu.w  d0,d1

.loc_1156E:                              ; CODE XREF: sub_11448+120↑j
                swap    d1
                add.w   d1,d6
                beq.w   .loc_11578
                nop

.loc_11578:                              ; CODE XREF: sub_11448+12A↑j
                sub.w   $38(a1),d6
                beq.w   .loc_11582
                nop

.loc_11582:                              ; CODE XREF: sub_11448+134↑j
                move.w  d1,$38(a1)
                move.l  $26(a1),d1
                lsr.l   #8,d1
                muls.w  d6,d1
                beq.w   .loc_11594
                nop

.loc_11594:                              ; CODE XREF: sub_11448+146↑j
                asr.l   #8,d1
                muls.w  #$300,d1
                asr.l   #8,d1
                beq.w   .loc_115A2
                nop

.loc_115A2:                              ; CODE XREF: sub_11448+154↑j
                add.w   d1,$36(a1)
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_115B8
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_115BA


.loc_115B8:                              ; CODE XREF: sub_11448+162↑j
                mulu.w  d0,d1

.loc_115BA:                              ; CODE XREF: sub_11448+16C↑j
                swap    d1
                bsr.w   sub_115C6

.loc_115C0:                              ; CODE XREF: sub_11448+5A↑j
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_11448


; =============== S U B R O U T I N E =======================================


sub_115C6:                              ; CODE XREF: sub_11448+174↑p
; sub_116E2+120↓p ...
                move.w  d1,$3C(a1)
                add.w   $3A(a1),d1
                cmpa.l  #ram_FF2EAA,a1
                bcc.w   .loc_116AA
                move.w  (Race_ram_FrameDelay).l,d4
                btst    #0,$68(a1)
                bne.w   .loc_11652
                move.w  #0,$2E(a1)
                tst.w   $12(a1)
                beq.w   .loc_116AA
                tst.w   d1
                bpl.w   .loc_11610
                move.w  #$4000,d0
                add.w   d0,d1
                add.w   d0,$2A(a1)
                move.w  d1,(ram_FF1E92).l
                move.w  d1,$3A(a1)

.loc_11610:                              ; CODE XREF: sub_115C6+32↑j
                move.w  (ram_FF1E92).l,d0
                subq.w  #8,d0
                move.w  d0,$2A(a1)
                move.l  $26(a1),d4
                clr.l   d2
                move.w  a6,d2
                asl.l   #8,d2
                sub.l   d2,d4
                bmi.w   .loc_116AA
                move.w  $12(a1),d3
                move.w  $2C(a1),d0
                bpl.w   .loc_11640
                move.w  #0,d0
                bra.w   .loc_11644


.loc_11640:                              ; CODE XREF: sub_115C6+6E↑j
                mulu.w  d3,d0
                swap    d0

.loc_11644:                              ; CODE XREF: sub_115C6+76↑j
                move.w  d0,$2C(a1)
                divu.w  d3,d4
                bne.w   .loc_11652
                move.w  #1,d4

.loc_11652:                              ; CODE XREF: sub_115C6+1E↑j
; sub_115C6+84↑j
                add.w   d4,$2E(a1)
                move.w  $2C(a1),d2
                andi.w  #$1F,d2
                move.w  $2E(a1),d3
                mulu.w  d3,d2
                move.w  d3,d4
                mulu.w  d4,d3
                cmp.l   #$10000,d3
                blt.w   .loc_11676
                move.w  #$FFFF,d3

.loc_11676:                              ; CODE XREF: sub_115C6+A8↑j
                move.w  (ram_FF1A9E).l,d4
                lsr.w   #1,d4
                mulu.w  d4,d3
                swap    d3
                sub.w   d3,d2
                add.w   $2A(a1),d2
                cmp.w   d2,d1
                bpl.w   .loc_116AA
                move.w  d2,2(a1)
                bset    #0,$68(a1)
                sub.w   d1,d2
                mulu.w  (ram_FF1AA0).l,d2
                lsr.l   #8,d2
                move.w  d2,$32(a1)
                bra.w   .locret_116E0


.loc_116AA:                              ; CODE XREF: sub_115C6+E↑j
; sub_115C6+2C↑j ...
                move.w  d1,2(a1)
                move.w  #0,$32(a1)
                btst    #0,$68(a1)
                beq.w   .loc_116D4
                tst.w   $2C(a1)
                beq.w   .loc_116CE
                bsr.w   sub_146AC
                bra.w   .locret_116E0


.loc_116CE:                              ; CODE XREF: sub_115C6+FC↑j
                bclr    #0,$68(a1)

.loc_116D4:                              ; CODE XREF: sub_115C6+F4↑j
                move.w  #0,$2E(a1)
                move.w  #0,$2C(a1)

.locret_116E0:                           ; CODE XREF: sub_115C6+E0↑j
; sub_115C6+104↑j
                rts
; End of function sub_115C6


; =============== S U B R O U T I N E =======================================


sub_116E2:                              ; CODE XREF: sub_10E66+102↑p
; Race_HandleInputOnFoot:@loc_111D4↑p ...
                movem.l d0-d7/a0-a6,-(sp)
                move.w  $30(a1),$1A(a1)
                move.w  $32(a1),$1C(a1)
                move.l  $26(a1),d0
                move.l  4(a1),d4
                move.l  d4,$1E(a1)
                add.l   d4,d0
                move.l  d0,4(a1)
                swap    d0
                swap    d4
                move.w  d4,d2
                sub.w   d4,d0
                swap    d4
                neg.w   d4
                lsr.w   #8,d4
                movea.w d4,a6
                move.w  #0,(ram_FF1E92).l
                move.w  #0,d6
                move.w  #0,d7
                lea     (ram_FFDC58).l,a4
                move.w  d2,d3
                sub.w   (ram_FF1E68).l,d3
                bpl.w   .loc_11738
                neg.w   d3

.loc_11738:                              ; CODE XREF: sub_116E2+50↑j
                cmp.w   #$40,d3 ; '@'
                bpl.w   .loc_11806
                cmp.w   (RaceTrack_Data1).l,d2
                bmi.w   .loc_11762
                btst    #7,$68(a1)
                bne.w   .loc_11762
                bset    #7,$68(a1)
                move.l  (ram_FF1E9A).l,$62(a1)

.loc_11762:                              ; CODE XREF: sub_116E2+64↑j
; sub_116E2+6E↑j
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4

.loc_1176A:                              ; CODE XREF: sub_116E2+DC↓j
                tst.w   d0
                ble.w   .loc_117C0
                move.b  (a4)+,d3
                ext.w   d3
                add.w   d3,d6
                move.b  (a4)+,d5
                cmpa.l  #Race_ram_NextSpriteTileArray,a4
                bmi.w   .loc_11788
                lea     (ram_FFDC58).l,a4

.loc_11788:                              ; CODE XREF: sub_116E2+9C↑j
                ext.w   d5
                add.w   d5,d7
                btst    #0,$68(a1)
                bne.w   .loc_117B6
                cmp.w   $2C(a1),d5
                ble.w   .loc_117B6
                movea.w d4,a6
                move.w  d5,$2C(a1)
                move.w  d7,-(sp)
                add.w   $3A(a1),d7
                move.w  d7,(ram_FF1E92).l
                move.w  (sp)+,d7
                bra.w   *+4


.loc_117B6:                              ; CODE XREF: sub_116E2+B0↑j
; sub_116E2+B8↑j ...
                addi.w  #$100,d4
                subq.w  #1,d0
                addq.w  #1,d2
                bra.s   .loc_1176A


.loc_117C0:                              ; CODE XREF: sub_116E2+8A↑j
                add.w   d7,$3A(a1)
                move.w  6(a1),d0
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_117DA
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_117DC


.loc_117DA:                              ; CODE XREF: sub_116E2+EA↑j
                mulu.w  d0,d1

.loc_117DC:                              ; CODE XREF: sub_116E2+F4↑j
                swap    d1
                add.w   d1,d6
                sub.w   $38(a1),d6
                move.w  d1,$38(a1)
                add.w   d1,$36(a1)
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_117FE
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_11800


.loc_117FE:                              ; CODE XREF: sub_116E2+10E↑j
                mulu.w  d0,d1

.loc_11800:                              ; CODE XREF: sub_116E2+118↑j
                swap    d1
                bsr.w   sub_115C6

.loc_11806:                              ; CODE XREF: sub_116E2+5A↑j
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_116E2


; =============== S U B R O U T I N E =======================================


sub_1180C:                              ; CODE XREF: sub_10E66+1CA↑p
                movem.l d0-d7/a0-a6,-(sp)
                move.l  4(a1),-(sp)
                lea     (unk_258AE).l,a2
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                movea.l (a2,d0.w),a2
                exg     a1,a2
                tst.b   $6E(a1)
                bmi.w   .loc_118C6
                bsr.w   sub_13BD8
                move.w  $14(a1),d1
                beq.w   .loc_11858
                move.w  (Race_ram_FrameDelay).l,d2
                muls.w  d2,d1
                move.w  $12(a1),d0
                add.w   d1,d0
                move.w  d0,$12(a1)
                bpl.w   .loc_11858
                move.w  #0,$12(a1)

.loc_11858:                              ; CODE XREF: sub_1180C+2C↑j
; sub_1180C+42↑j
                move.w  $12(a1),d0
                beq.w   .loc_1188A
                move.w  (Race_ram_FrameDelay).l,d2
                mulu.w  d2,d0
                move.l  d0,$26(a1)
                move.l  a2,-(sp)
                btst    #3,$69(a1)
                bne.w   .loc_11880
                bsr.w   sub_116E2
                bra.w   .loc_11884


.loc_11880:                              ; CODE XREF: sub_1180C+68↑j
                bsr.w   sub_11940

.loc_11884:                              ; CODE XREF: sub_1180C+70↑j
                movea.l (sp)+,a2
                bra.w   *+4


.loc_1188A:                              ; CODE XREF: sub_1180C+50↑j
; sub_1180C+7A↑j
                move.w  $36(a1),d1
                move.w  d1,d3
                sub.w   0.w(a1),d1
                bpl.w   .loc_118AE
                cmp.w   #$FD20,d1
                bpl.w   .loc_118C0
                move.w  #$FCE0,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)
                bra.w   .loc_118C0


.loc_118AE:                              ; CODE XREF: sub_1180C+88↑j
                cmp.w   #$360,d1
                bmi.w   .loc_118C0
                move.w  #$360,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)

.loc_118C0:                              ; CODE XREF: sub_1180C+90↑j
; sub_1180C+9E↑j ...
                neg.w   d1
                move.w  d1,$30(a1)

.loc_118C6:                              ; CODE XREF: sub_1180C+20↑j
                move.l  (sp)+,d1
                move.l  4(a1),d0
                sub.l   d1,d0
                bpl.w   .loc_118E8
                neg.l   d0
                cmp.l   #$A0000,d0
                bmi.w   .loc_11900
                subi.l  #$A0000,d1
                bra.w   .loc_118F8


.loc_118E8:                              ; CODE XREF: sub_1180C+C2↑j
                cmp.l   #$A0000,d0
                bmi.w   .loc_11900
                addi.l  #$A0000,d1

.loc_118F8:                              ; CODE XREF: sub_1180C+D8↑j
                move.l  d1,4(a1)
                move.l  d1,$1E(a1)

.loc_11900:                              ; CODE XREF: sub_1180C+CE↑j
; sub_1180C+E2↑j
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_1180C


; =============== S U B R O U T I N E =======================================


sub_11906:                              ; CODE XREF: sub_11B7A+9E↓p
; sub_11B7A+AC↓p ...
                movem.l d0/a0-a1,-(sp)
                lea     (unk_258AE).l,a0
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0
                move.w  #$1F,d0
                movem.l a0-a1,-(sp)

.loc_11924:                              ; CODE XREF: sub_11906+20↓j
                move.l  (a1)+,(a0)+
                dbf     d0,.loc_11924
                movem.l (sp)+,a0-a1
                lsr     $2C(a0)
                move.w  #1,(ram_FF176A).l
                movem.l (sp)+,d0/a0-a1
                rts
; End of function sub_11906


; =============== S U B R O U T I N E =======================================


sub_11940:                              ; CODE XREF: sub_10E66:@loc_10F22↑p
; Race_HandleInputOnFoot+142↑p ...
                movem.l d0-d7/a0-a6,-(sp)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_1195A
                cmpi.l  #$10000,4(a1)
                blt.w   .loc_11A58

.loc_1195A:                              ; CODE XREF: sub_11940+A↑j
                move.w  $30(a1),$1A(a1)
                move.w  $32(a1),$1C(a1)
                move.l  $26(a1),d4
                move.l  4(a1),d0
                move.l  d0,$1E(a1)
                move.l  d0,d1
                sub.l   d4,d0
                move.l  d0,4(a1)
                move.w  d0,d4
                ext.l   d4
                swap    d0
                swap    d1
                move.w  d1,d2
                sub.w   d0,d1
                move.w  d1,d0
                lsr.w   #8,d4
                movea.w d4,a6
                move.w  #0,(ram_FF1E92).l
                move.w  #0,d6
                move.w  #0,d7
                lea     (ram_FFDC58).l,a4
                move.w  d2,d3
                sub.w   (ram_FF1E68).l,d3
                bpl.w   .loc_119B0
                neg.w   d3

.loc_119B0:                              ; CODE XREF: sub_11940+6A↑j
                cmp.w   #$40,d3 ; '@'
                bpl.w   .loc_11A58
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4

.loc_119C0:                              ; CODE XREF: sub_11940:@loc_11A0C↓j
                cmp.w   (RaceTrack_Data1).l,d2
                bmi.w   .loc_119D4
                ext.l   d2
                divu.w  (RaceTrack_Data1).l,d2
                swap    d2

.loc_119D4:                              ; CODE XREF: sub_11940+86↑j
                tst.w   d0
                ble.w   .loc_11A0E
                move.b  (a4),d3
                ext.w   d3
                add.w   d3,d6
                move.b  1(a4),d5
                subq.w  #2,a4
                cmpa.l  #ram_FFDC58,a4
                bpl.w   .loc_119F6
                movea.l #ram_FFDD56,a4

.loc_119F6:                              ; CODE XREF: sub_11940+AC↑j
                ext.w   d5
                add.w   d5,d7
                addi.w  #$100,d4
                subq.w  #1,d0
                subq.w  #1,d2
                bpl.w   .loc_11A0C
                move.w  (RaceTrack_Data1).l,d2

.loc_11A0C:                              ; CODE XREF: sub_11940+C2↑j
                bra.s   .loc_119C0


.loc_11A0E:                              ; CODE XREF: sub_11940+96↑j
                move.w  d1,$E(a1)
                move.w  d2,$10(a1)
                sub.w   d6,$36(a1)
                sub.w   d7,$3A(a1)
                move.w  6(a1),d0
                move.b  (a4),d1
                ext.w   d1
                bpl.w   .loc_11A34
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_11A36


.loc_11A34:                              ; CODE XREF: sub_11940+E6↑j
                mulu.w  d0,d1

.loc_11A36:                              ; CODE XREF: sub_11940+F0↑j
                swap    d1
                move.w  d1,$38(a1)
                move.b  1(a4),d1
                ext.w   d1
                bpl.w   .loc_11A50
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_11A52


.loc_11A50:                              ; CODE XREF: sub_11940+102↑j
                mulu.w  d0,d1

.loc_11A52:                              ; CODE XREF: sub_11940+10C↑j
                swap    d1
                bsr.w   sub_115C6

.loc_11A58:                              ; CODE XREF: sub_11940+16↑j
; sub_11940+74↑j
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_11940


                dc.b $48 ; H
                dc.b $E7
                dc.b $FF
                dc.b $FE
                dc.b $33 ; 3
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b   0
                dc.b $1A
                dc.b $33 ; 3
                dc.b $69 ; i
                dc.b   0
                dc.b $32 ; 2
                dc.b   0
                dc.b $1C
                dc.b $28 ; (
                dc.b $29 ; )
                dc.b   0
                dc.b $26 ; &
                dc.b $20
                dc.b $29 ; )
                dc.b   0
                dc.b   4
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b $1E
                dc.b $22 ; "
                dc.b   0
                dc.b $90
                dc.b $84
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b   4
                dc.b $38 ; 8
                dc.b   0
                dc.b $48 ; H
                dc.b $C4
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $48 ; H
                dc.b $41 ; A
                dc.b $34 ; 4
                dc.b   1
                dc.b $92
                dc.b $40 ; @
                dc.b $30 ; 0
                dc.b   1
                dc.b $E0
                dc.b $4C ; L
                dc.b $3C ; <
                dc.b $44 ; D
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $92
                dc.b $3C ; <
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $3E ; >
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $49 ; I
                dc.b $F9
                dc.b   0
                dc.b $FF
                dc.b $DC
                dc.b $58 ; X
                dc.b $36 ; 6
                dc.b   2
                dc.b $96
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $68 ; h
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $43 ; C
                dc.b $B6
                dc.b $7C ; |
                dc.b   0
                dc.b $40 ; @
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b $B6
                dc.b   2
                dc.b $42 ; B
                dc.b   0
                dc.b $FF
                dc.b $E3
                dc.b $42 ; B
                dc.b $D8
                dc.b $C2
                dc.b $B4
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $4C ; L
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $48 ; H
                dc.b $C2
                dc.b $84
                dc.b $F9
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $4C ; L
                dc.b $48 ; H
                dc.b $42 ; B
                dc.b $4A ; J
                dc.b $40 ; @
                dc.b $6F ; o
                dc.b   0
                dc.b   0
                dc.b $36 ; 6
                dc.b $16
                dc.b $14
                dc.b $48 ; H
                dc.b $83
                dc.b $DC
                dc.b $43 ; C
                dc.b $1A
                dc.b $2C ; ,
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $4C ; L
                dc.b $B9
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $DC
                dc.b $58 ; X
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $28 ; (
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b $DD
                dc.b $56 ; V
                dc.b $48 ; H
                dc.b $85
                dc.b $DE
                dc.b $45 ; E
                dc.b   6
                dc.b $44 ; D
                dc.b   1
                dc.b   0
                dc.b $53 ; S
                dc.b $40 ; @
                dc.b $53 ; S
                dc.b $42 ; B
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $34 ; 4
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $4C ; L
                dc.b $60 ; `
                dc.b $B2
                dc.b $33 ; 3
                dc.b $41 ; A
                dc.b   0
                dc.b  $E
                dc.b $33 ; 3
                dc.b $42 ; B
                dc.b   0
                dc.b $10
                dc.b $9D
                dc.b $69 ; i
                dc.b   0
                dc.b $36 ; 6
                dc.b $9F
                dc.b $69 ; i
                dc.b   0
                dc.b $3A ; :
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b   6
                dc.b $12
                dc.b $14
                dc.b $48 ; H
                dc.b $81
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $44 ; D
                dc.b $41 ; A
                dc.b $C2
                dc.b $C0
                dc.b $44 ; D
                dc.b $81
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $C2
                dc.b $C0
                dc.b $48 ; H
                dc.b $41 ; A
                dc.b $33 ; 3
                dc.b $41 ; A
                dc.b   0
                dc.b $38 ; 8
                dc.b $12
                dc.b $2C ; ,
                dc.b   0
                dc.b   1
                dc.b $48 ; H
                dc.b $81
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $44 ; D
                dc.b $41 ; A
                dc.b $C2
                dc.b $C0
                dc.b $44 ; D
                dc.b $81
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $C2
                dc.b $C0
                dc.b $48 ; H
                dc.b $41 ; A
                dc.b $33 ; 3
                dc.b $41 ; A
                dc.b   0
                dc.b $3C ; <
                dc.b $D2
                dc.b $69 ; i
                dc.b   0
                dc.b $3A ; :
                dc.b $33 ; 3
                dc.b $41 ; A
                dc.b   0
                dc.b   2
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $68 ; h
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $32 ; 2
                dc.b $4C ; L
                dc.b $DF
                dc.b $7F ; 
                dc.b $FF
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_11B7A:                              ; CODE XREF: sub_10E66:@loc_11010↑p
                move.w  4(a1),d0
                lea     (ram_FFDC58).l,a4
                andi.w  #$FF,d0
                asl.w   #1,d0
                adda.w  d0,a4
                move.b  1(a4),d0
                btst    #0,$68(a1)
                beq.w   .loc_11BA8
                cmpi.w  #$2D,$2E(a1) ; '-'
                bmi.w   .loc_11BAE
                move.b  #$64,d0 ; 'd'

.loc_11BA8:                              ; CODE XREF: sub_11B7A+1C↑j
                ext.w   d0
                move.w  d0,$A(a1)

.loc_11BAE:                              ; CODE XREF: sub_11B7A+26↑j
                btst    #0,$68(a1)
                bne.w   .locret_11C42
                tst.b   $6E(a1)
                bpl.w   .locret_11C42
                move.w  $C(a1),d0
                move.w  d0,8(a1)
                move.w  $40(a1),d2
                move.w  $34(a1),d3
                move.w  d0,d1
                bpl.w   .loc_11BDC
                neg.w   d1
                neg.w   d2
                neg.w   d3

.loc_11BDC:                              ; CODE XREF: sub_11B7A+58↑j
                cmp.w   #3,d3
                bmi.w   .locret_11C42
                add.w   d1,d2
                cmp.w   (ram_FFD33E).l,d2
                bmi.w   .locret_11C42
                btst    #4,$68(a1)
                bne.w   .locret_11C42
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                bset    #4,$68(a1)
                tst.w   d0
                bpl.w   .loc_11C20
                jsr     (sub_15538).l
                bsr.w   sub_11906
                bra.w   .loc_11C2A


.loc_11C20:                              ; CODE XREF: sub_11B7A+94↑j
                jsr     (sub_15538).l
                bsr.w   sub_11906

.loc_11C2A:                              ; CODE XREF: sub_11B7A+A2↑j
                bclr    #7,$6A(a1)
                move.w  $12(a1),d0
                jsr     (sub_1434A).l
                lsr.w   #2,d0
                add.w   d0,(Race_ram_BikeDamage).l

.locret_11C42:                           ; CODE XREF: sub_11B7A+3A↑j
; sub_11B7A+42↑j ...
                rts
; End of function sub_11B7A


; =============== S U B R O U T I N E =======================================


sub_11C44:                              ; CODE XREF: Race_Update+10C↑p
                tst.w   (ram_FF1B18).l
                beq.w   .loc_11C6A
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,(ram_FF1B18).l
                bgt.w   .locret_11CC6
                move.w  #1,(Race_ram_GameEnded).l
                bra.w   .locret_11CC6


.loc_11C6A:                              ; CODE XREF: sub_11C44+6↑j
                lea     (ram_FF1A08).l,a0

.loc_11C70:                              ; CODE XREF: sub_11C44+3E↓j
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .locret_11CC6
                cmpa.l  #ram_FF1F2A,a2
                bne.s   .loc_11C70
                lea     (ram_FF1EAA).l,a1
                move.l  4(a2),d0
                move.l  4(a1),d1
                sub.l   d1,d0
                bpl.w   .loc_11CA2
                neg.l   d0
                cmp.l   ($4000).w,d0 ; WOW
                bpl.w   .locret_11CC6

.loc_11CA2:                              ; CODE XREF: sub_11C44+50↑j
                cmp.l   #$60000,d0
                bpl.w   .locret_11CC6
                tst.w   $12(a1)
                bne.w   .locret_11CC6
                move.w  #$12C,(ram_FF1B18).l
                move.w  (ram_FF1B38).l,(ram_FF1B1A).l

.locret_11CC6:                           ; CODE XREF: sub_11C44+16↑j
; sub_11C44+22↑j ...
                rts
; End of function sub_11C44


; =============== S U B R O U T I N E =======================================


sub_11CC8:                              ; CODE XREF: Race_Update+112↑p
                move.w  #0,(ram_FF176A).l
                move.l  #$6000,(ram_FF3038).l
                move.w  #$10,(ram_FF303C).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (ram_FF1A08).l,a0
                movea.l (a0)+,a1
                move.w  #0,$50(a1)
                move.w  8(a1),d1
                move.w  $C(a1),d2
                move.w  #0,d3
                bsr.w   sub_12A9C
                move.w  d0,$4C(a1)
                move.w  #1,d3
                bsr.w   sub_12A9C
                move.w  d0,$4E(a1)
                bclr    #4,$68(a1)
                tst.b   $6E(a1)
                bmi.w   .loc_11D3C
                cmpi.b  #4,$6E(a1)
                bpl.w   .loc_11D3C
                move.w  #1,(ram_FF1768).l
                bra.w   .loc_11D44


.loc_11D3C:                              ; CODE XREF: sub_11CC8+5A↑j
; sub_11CC8+64↑j
                move.w  #0,(ram_FF1768).l

.loc_11D44:                              ; CODE XREF: sub_11CC8+70↑j
; sub_11CC8+8E↓j ...
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_11E8C
                btst    #6,$68(a2)
                beq.s   .loc_11D44
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                bne.w   .loc_11D92
                cmpa.l  #ram_FF1F2A,a2
                beq.s   .loc_11D44
                tst.b   $6E(a2)
                bmi.s   .loc_11D44
                move.b  $71(a2),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_258AE).l,a3
                movea.l (a3,d0.w),a2
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                beq.s   .loc_11D44

.loc_11D92:                              ; CODE XREF: sub_11CC8+9A↑j
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_11DFE
                tst.w   (ram_FF1768).l
                bne.w   .loc_11DB0
                cmpa.l  #ram_FF26AA,a2
                bcs.w   .loc_11DC2

.loc_11DB0:                              ; CODE XREF: sub_11CC8+DA↑j
                cmpi.b  #1,$6E(a2)
                bcs.w   .loc_1202E
                bsr.w   sub_1438E
                bra.w   .loc_1202E


.loc_11DC2:                              ; CODE XREF: sub_11CC8+E4↑j
                move.b  $6E(a2),d0
                bmi.w   .loc_11DFE
                cmp.b   #1,d0
                bcs.w   .loc_1202E
                bsr.w   sub_1438E
                move.b  #1,$6E(a2)
                move.b  #0,$6F(a2)
                move.b  #$FF,$70(a2)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_1202E
                move.b  #$D,(ram_FF1AD6).l
                bra.w   .loc_1202E


.loc_11DFE:                              ; CODE XREF: sub_11CC8+D0↑j
; sub_11CC8+FE↑j
                bsr.w   sub_1487C
                tst.b   (ram_FF1AD6).l
                bne.w   .loc_11E14
                move.b  #9,(ram_FF1AD6).l

.loc_11E14:                              ; CODE XREF: sub_11CC8+140↑j
                move.w  $C(a1),d0
                muls.w  #$40,d0
                move.w  d0,(RaceBike_ram_CurrentSteering).l
                move.w  d0,$42(a1)
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_11E6A
                tst.w   (ram_FF1768).l
                bne.w   .loc_11E4A
                tst.b   $6E(a1)
                bmi.w   .loc_1202E
                bsr.w   sub_11906
                bra.w   .loc_1202E


.loc_11E4A:                              ; CODE XREF: sub_11CC8+16E↑j
                cmpi.b  #3,$6E(a1)
                bmi.w   .loc_11E5A
                move.w  #0,$12(a1)

.loc_11E5A:                              ; CODE XREF: sub_11CC8+188↑j
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_1202E


.loc_11E6A:                              ; CODE XREF: sub_11CC8+164↑j
                tst.w   (ram_FF1B1A).l
                bne.w   .loc_11E88
                move.b  #$FF,$6E(a2)
                tst.w   (ram_FF1768).l
                bne.w   .loc_11E88
                bsr.w   sub_11906

.loc_11E88:                              ; CODE XREF: sub_11CC8+1A8↑j
; sub_11CC8+1B8↑j
                bra.w   .loc_1202E


.loc_11E8C:                              ; CODE XREF: sub_11CC8+84↑j
; sub_11CC8+39A↓j
                lea     (unk_2589A).l,a0
                move.l  #$6000,(ram_FF3038).l
                move.w  #$37,(ram_FF303C).l ; '7'
                move.w  #$40,(ram_FF303E).l ; '@'

.loc_11EAC:                              ; CODE XREF: sub_11CC8+1F6↓j
; sub_11CC8+202↓j
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_11EF4
                cmpi.w  #$FFFF,$56(a2)
                bne.s   .loc_11EAC
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                beq.s   .loc_11EAC
                bsr.w   sub_14486
                btst    #4,$68(a1)
                beq.w   .loc_11EF4
                move.w  $C(a1),(RaceBike_ram_CurrentSteering).l
                tst.w   (ram_FF1768).l
                bne.w   .loc_1202E
                bsr.w   sub_11906
                bra.w   .loc_1202E


.loc_11EF4:                              ; CODE XREF: sub_11CC8+1EC↑j
; sub_11CC8+20E↑j
                move.w  #$60,(ram_FF303C).l ; '`'
                move.l  #$3700,(ram_FF3038).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (ram_FF2FAA).l,a2
                btst    #6,$68(a2)
                beq.w   .loc_11F58
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                beq.w   .loc_11F58
                bsr.w   sub_14486
                btst    #4,$68(a1)
                beq.w   .loc_1202E
                move.w  $C(a1),(RaceBike_ram_CurrentSteering).l
                tst.w   (ram_FF1768).l
                bne.w   .loc_1202E
                bsr.w   sub_11906
                bra.w   .loc_1202E

                dc.b $60
                dc.b   0
                dc.b   0
                dc.b $D8


.loc_11F58:                              ; CODE XREF: sub_11CC8+252↑j
; sub_11CC8+260↑j
                bsr.w   sub_12070
                btst    #4,$68(a1)
                bne.w   .loc_1202E
                move.l  #$6000,(ram_FF3038).l
                move.w  #$10,(ram_FF303C).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (ram_FFD37C).l,a0
                move.w  (ram_FF1B48).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                move.l  $1E(a1),d0
                sub.l   (ram_FF1E68).l,d0
                lsr.l   #8,d0
                move.l  4(a1),d1
                addi.l  #$6000,d1
                sub.l   (ram_FF1E68).l,d1
                lsr.l   #8,d1
                move.w  (ram_FF1B4A).l,d7
                subq.w  #1,d7

.loc_11FB8:                              ; CODE XREF: sub_11CC8+310↓j
                cmpi.w  #$FFFF,(a0)
                beq.w   .loc_1202E
                move.w  d7,-(sp)
                bsr.w   sub_12414
                adda.l  #$14,a0
                btst    #4,$68(a1)
                bne.w   .loc_11FE0
                move.w  (sp)+,d7
                dbf     d7,.loc_11FB8
                bra.w   .loc_1202E


.loc_11FE0:                              ; CODE XREF: sub_11CC8+30A↑j
                move.w  (sp)+,d7
                suba.l  #$14,a0
                move.w  (ram_FF1B0E).l,d0
                cmp.w   #$1BB,d0
                bmi.w   .loc_12010
                cmp.w   #$219,d0
                bmi.w   .loc_12006
                subi.w  #$2F,d0 ; '/'
                bra.w   .loc_12010


.loc_12006:                              ; CODE XREF: sub_11CC8+332↑j
                subi.w  #$1BB,d0
                lsr.w   #1,d0
                addi.w  #$1BB,d0

.loc_12010:                              ; CODE XREF: sub_11CC8+32A↑j
; sub_11CC8+33A↑j
                subi.w  #$186,d0
                lea     (unk_147FC).l,a4
                move.b  (a4,d0.w),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_14744).l,a4
                movea.l (a4,d0.w),a4
                jsr     (a4)

.loc_1202E:                              ; CODE XREF: sub_11CC8+EE↑j
; sub_11CC8+F6↑j ...
                tst.b   $6E(a1)
                bmi.w   .loc_12068
                bset    #4,$68(a1)
                tst.w   (ram_FF176A).l
                bne.w   .locret_12066
                move.w  #1,(ram_FF176A).l
                move.w  #1,(ram_FF1768).l
                lea     (ram_FF26AA).l,a1
                bclr    #4,$68(a1)
                bra.w   .loc_11E8C


.locret_12066:                           ; CODE XREF: sub_11CC8+37A↑j
                rts


.loc_12068:                              ; CODE XREF: sub_11CC8+36A↑j
                bclr    #4,$68(a1)
                rts
; End of function sub_11CC8


; =============== S U B R O U T I N E =======================================


sub_12070:                              ; CODE XREF: sub_11CC8:@loc_11F58↑p
; sub_1218C:@loc_12384↓p
                movem.l d0-d7/a0-a7,-(sp)
                movea.l (ram_FFD7D0).l,a0
                suba.w  #$14,a0
                movea.l (ram_FFD7CC).l,a2
                move.l  4(a1),d0
                addi.l  #$6000,d0
                move.l  $1E(a1),d1
                addi.l  #$6000,d1
                lea     (unk_3BF1A).l,a6
                lea     (unk_14764).l,a5

.loc_120A4:                              ; CODE XREF: sub_12070+BC↓j
; sub_12070+D4↓j ...
                adda.w  #$14,a0
                move.l  (a2)+,d2
                cmp.l   #$FFFFFFFF,d2
                beq.w   .loc_12162
                move.w  d2,d3
                clr.w   d2
                cmp.l   d2,d0
                bpl.w   .loc_120C8
                cmp.l   d2,d1
                bpl.w   .loc_120CE
                bra.w   .loc_12162


.loc_120C8:                              ; CODE XREF: sub_12070+4A↑j
                cmp.l   d2,d1
                bpl.w   .loc_12162

.loc_120CE:                              ; CODE XREF: sub_12070+50↑j
                move.w  d3,d2
                andi.w  #$F,d2
                asl.w   #5,d2
                subi.w  #$100,d2
                lsr.w   #8,d3
                move.w  d3,d4
                ext.w   d4
                asl.w   #3,d4
                addi.w  #$173,d3
                asl.w   #2,d3
                movea.l (a6,d3.w),a4
                clr.w   d3
                move.b  (a4),d3
                clr.w   d5
                move.b  1(a4),d5
                move.w  2(a5,d4.w),d7
                addi.w  #$80,d7
                mulu.w  d7,d3
                lsr.l   #8,d3
                lsr.w   #1,d3
                move.w  d3,(ram_FF1B10).l
                mulu.w  d7,d5
                lsr.l   #8,d5
                move.w  d5,(ram_FF1B12).l
                cmp.w   $1A(a1),d2
                bpl.w   .loc_12134
                add.w   d3,d2
                move.w  d2,(ram_FF1B14).l
                add.w   $4C(a1),d2
                cmp.w   $30(a1),d2
                bmi.w   .loc_120A4
                bra.w   .loc_12148


.loc_12134:                              ; CODE XREF: sub_12070+A8↑j
                sub.w   d3,d2
                move.w  d2,(ram_FF1B14).l
                sub.w   $4E(a1),d2
                cmp.w   $30(a1),d2
                bpl.w   .loc_120A4

.loc_12148:                              ; CODE XREF: sub_12070+C0↑j
                cmp.w   $32(a1),d5
                bmi.w   .loc_120A4
                move.w  4(a5,d4.w),d4
                asl.w   #2,d4
                lea     (unk_14744).l,a4
                movea.l (a4,d4.w),a4
                jsr     (a4)

.loc_12162:                              ; CODE XREF: sub_12070+40↑j
; sub_12070+54↑j ...
                movem.l (sp)+,d0-d7/a0-a7
                rts
; End of function sub_12070


                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $40 ; @
                dc.b $EE
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E
                dc.b   0
                dc.b   1
                dc.b $43 ; C
                dc.b $8E

; =============== S U B R O U T I N E =======================================


sub_1218C:                              ; CODE XREF: Race_Update+118↑p
                lea     (ram_FF1A0C).l,a0

.loc_12192:                              ; CODE XREF: sub_1218C+20↓j
; sub_1218C+2E↓j ...
                movea.l (a0)+,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_123A6
                btst    #4,$68(a1)
                beq.w   .loc_121B4
                tst.b   $6E(a1)
                bmi.s   .loc_12192
                bclr    #4,$68(a1)

.loc_121B4:                              ; CODE XREF: sub_1218C+18↑j
                btst    #6,$68(a1)
                beq.s   .loc_12192
                move.w  #0,(ram_FF1768).l
                move.l  a0,-(sp)
                tst.b   (ram_FF1EAA + STRUCT_OFFSET_6E).l
                bmi.w   .loc_121DA
                movea.l #ram_FF26AA,a2
                bra.w   .loc_121E6


.loc_121DA:                              ; CODE XREF: sub_1218C+40↑j
; sub_1218C+60↓j ...
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_12288

.loc_121E6:                              ; CODE XREF: sub_1218C+4A↑j
                btst    #6,$68(a2)
                beq.s   .loc_121DA
                tst.b   $6E(a1)
                bmi.w   .loc_121FE
                move.w  #1,(ram_FF1768).l

.loc_121FE:                              ; CODE XREF: sub_1218C+66↑j
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                bne.w   .loc_12234
                tst.b   $6E(a2)
                bmi.s   .loc_121DA
                lea     (unk_258AE).l,a3
                cmpa.l  a3,a2
                beq.s   .loc_121DA
                move.b  $71(a2),d0
                ext.w   d0
                asl.w   #2,d0
                movea.l (a3,d0.w),a2
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                beq.s   .loc_121DA

.loc_12234:                              ; CODE XREF: sub_1218C+7C↑j
                tst.w   (ram_FF1768).l
                beq.w   .loc_1224E
                move.w  $12(a2),d0
                add.w   $12(a1),d0
                cmp.w   #$FA0,d0
                ble.w   .loc_1226A

.loc_1224E:                              ; CODE XREF: sub_1218C+AE↑j
                cmpi.w  #$7D0,$12(a2)
                bgt.w   .loc_12272
                cmpa.l  #ram_FF26AA,a2
                bcc.w   .loc_1226A
                tst.b   $6E(a2)
                bmi.w   .loc_12272

.loc_1226A:                              ; CODE XREF: sub_1218C+BE↑j
; sub_1218C+D2↑j
                bsr.w   sub_1438E
                bra.w   .loc_12388


.loc_12272:                              ; CODE XREF: sub_1218C+C8↑j
; sub_1218C+DA↑j
                bsr.w   sub_1487C
                tst.w   (ram_FF1768).l
                bne.w   .loc_12284
                bsr.w   sub_11906

.loc_12284:                              ; CODE XREF: sub_1218C+F0↑j
                bra.w   .loc_12388


.loc_12288:                              ; CODE XREF: sub_1218C+56↑j
                move.w  #$60,(ram_FF303C).l ; '`'
                move.l  #$3700,(ram_FF3038).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (ram_FF2FAA).l,a2
                btst    #6,$68(a2)
                beq.w   .loc_122FA
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                beq.w   .loc_122FA
                move.w  4(a2),d0
                sub.w   (ram_FF1E68).l,d0
                cmp.w   #$10,d0
                bmi.w   .loc_122DC
                bclr    #4,$68(a1)
                bra.w   .loc_12388


.loc_122DC:                              ; CODE XREF: sub_1218C+142↑j
                bsr.w   sub_14486
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                tst.w   (ram_FF1768).l
                bne.w   .loc_122FA
                bsr.w   sub_11906

.loc_122FA:                              ; CODE XREF: sub_1218C+122↑j
; sub_1218C+130↑j ...
                lea     (unk_2589A).l,a0
                move.l  #$6000,(ram_FF3038).l
                move.w  #$37,(ram_FF303C).l ; '7'
                move.w  #$40,(ram_FF303E).l ; '@'

.loc_1231A:                              ; CODE XREF: sub_1218C+1A0↓j
; sub_1218C+1AC↓j
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_12384
                cmpi.w  #$FFFF,$56(a2)
                bne.s   .loc_1231A
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                beq.s   .loc_1231A
                move.w  4(a2),d0
                sub.w   (ram_FF1E68).l,d0
                cmp.w   #$10,d0
                bmi.w   .loc_12356
                bclr    #4,$68(a1)
                bra.w   .loc_12388


.loc_12356:                              ; CODE XREF: sub_1218C+1BC↑j
                bsr.w   sub_14486
                btst    #4,$68(a1)
                beq.w   .loc_12384
                move.w  #0,$54(a1)
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                tst.w   (ram_FF1768).l
                bne.w   .loc_12388
                bsr.w   sub_11906

.loc_12384:                              ; CODE XREF: sub_1218C+196↑j
; sub_1218C+1D4↑j
                bsr.w   sub_12070

.loc_12388:                              ; CODE XREF: sub_1218C+E2↑j
; sub_1218C:@loc_12284↑j ...
                btst    #4,$68(a1)
                bne.w   .loc_123A0
                tst.b   $6E(a1)
                bmi.w   .loc_123A0
                bset    #4,$68(a1)

.loc_123A0:                              ; CODE XREF: sub_1218C+202↑j
; sub_1218C+20A↑j
                movea.l (sp)+,a0
                bra.w   .loc_12192


.locret_123A6:                           ; CODE XREF: sub_1218C+E↑j
                rts
; End of function sub_1218C


; =============== S U B R O U T I N E =======================================


sub_123A8:                              ; CODE XREF: Race_Update+11E↑p
                lea     (ram_FF2EAA).l,a1
                lea     (ram_FF2F2A).l,a2
                btst    #6,$68(a1)
                beq.w   .locret_12412
                btst    #6,$68(a2)
                beq.w   .locret_12412
                move.l  #$6000,(ram_FF3038).l
                move.w  #$37,(ram_FF303C).l ; '7'
                move.w  #$40,(ram_FF303E).l ; '@'
                bsr.w   sub_124E2
                btst    #4,$68(a1)
                beq.w   .locret_12412
                move.l  4(a1),d0
                move.l  #$C014,d1
                btst    #0,$69(a1)
                beq.w   .loc_12406
                neg.l   d1

.loc_12406:                              ; CODE XREF: sub_123A8+58↑j
                add.l   d1,d0
                move.l  d0,4(a2)
                move.w  $12(a1),$12(a2)

.locret_12412:                           ; CODE XREF: sub_123A8+12↑j
; sub_123A8+1C↑j ...
                rts
; End of function sub_123A8


; =============== S U B R O U T I N E =======================================


sub_12414:                              ; CODE XREF: sub_11CC8+2FA↑p
                cmp.w   $E(a0),d1
                bcs.w   .loc_124DA
                cmp.w   $E(a0),d0
                bcs.w   .loc_12428
                bra.w   .loc_124DA


.loc_12428:                              ; CODE XREF: sub_12414+C↑j
                move.w  $10(a0),d2
                andi.w  #$F,d2
                asl.w   #6,d2
                btst    #$E,$A(a0)
                beq.w   .loc_1243E
                neg.w   d2

.loc_1243E:                              ; CODE XREF: sub_12414+24↑j
                lea     (unk_3BF1A).l,a2
                move.w  8(a0),d0
                move.w  d0,(ram_FF1B0E).l
                asl.w   #2,d0
                movea.l (a2,d0.w),a2
                clr.w   d5
                move.b  1(a2),d5
                move.w  d5,(ram_FF1B12).l
                move.b  (a2),d0
                andi.w  #$FF,d0
                lsr.w   #1,d0
                clr.l   d7
                move.w  4(a0),d7
                addi.l  #$2000,d7
                cmp.l   #$4000,d7
                bmi.w   .loc_12484
                mulu.w  d7,d0
                asl.l   #2,d0
                swap    d0

.loc_12484:                              ; CODE XREF: sub_12414+66↑j
                move.w  d0,(ram_FF1B10).l
                move.w  $30(a1),d3
                move.w  $1A(a1),d4
                cmp.w   d4,d2
                bpl.w   .loc_124AE
                add.w   d0,d2
                sub.w   $4C(a1),d3
                bset    #1,$69(a1)
                cmp.w   d3,d2
                bpl.w   .loc_124C4
                bra.w   .loc_124DA


.loc_124AE:                              ; CODE XREF: sub_12414+80↑j
                sub.w   d0,d2
                add.w   $4E(a1),d3
                bclr    #1,$69(a1)
                cmp.w   d3,d2
                bmi.w   .loc_124C4
                bra.w   .loc_124DA


.loc_124C4:                              ; CODE XREF: sub_12414+92↑j
; sub_12414+A8↑j
                cmp.w   $32(a1),d5
                bmi.w   .loc_124DA
                move.w  d2,(ram_FF1B14).l
                bset    #4,$68(a1)
                rts


.loc_124DA:                              ; CODE XREF: sub_12414+4↑j
; sub_12414+10↑j ...
                bclr    #4,$68(a1)
                rts
; End of function sub_12414


; =============== S U B R O U T I N E =======================================


sub_124E2:                              ; CODE XREF: sub_11CC8+90↑p
; sub_11CC8+BE↑p ...
                move.w  #0,(ram_FF1766).l
                move.w  #0,(ram_FF1B16).l
                move.l  $1E(a1),d0
                cmp.l   $1E(a2),d0
                bcs.w   .loc_1251A
                bset    #0,$69(a1)
                move.l  4(a1),d0
                sub.l   (ram_FF3038).l,d0
                cmp.l   4(a2),d0
                bcs.w   .loc_12536
                bra.w   .loc_1280A


.loc_1251A:                              ; CODE XREF: sub_124E2+18↑j
                bclr    #0,$69(a1)
                move.l  4(a1),d0
                addi.l  #$6000,d0
                cmp.l   4(a2),d0
                bcc.w   .loc_12536
                bra.w   .loc_1280A


.loc_12536:                              ; CODE XREF: sub_124E2+30↑j
; sub_124E2+4C↑j
                move.w  $1A(a1),d0
                cmp.w   $1A(a2),d0
                bmi.w   .loc_12698
                bset    #1,$69(a1)
                move.w  8(a1),d1
                move.w  $C(a1),d2
                move.w  #0,d3
                move.b  $71(a1),d4
                move.w  #0,$50(a1)
                bsr.w   sub_12A88
                move.w  d0,$4A(a1)
                move.w  d0,$4C(a1)
                cmpa.l  #ram_FF26AA,a2
                bcc.w   .loc_125B0
                btst    #4,$69(a1)
                beq.w   .loc_125B0
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_125B0
                btst    #5,$69(a1)
                beq.w   .loc_125B0
                btst    #6,$69(a1)
                bne.w   .loc_125A8
                bsr.w   sub_12B0C
                move.w  d0,$50(a1)
                bra.w   .loc_125B0


.loc_125A8:                              ; CODE XREF: sub_124E2+B6↑j
                bsr.w   sub_12B24
                move.w  d0,$50(a1)

.loc_125B0:                              ; CODE XREF: sub_124E2+8E↑j
; sub_124E2+98↑j ...
                move.w  8(a2),d1
                move.w  $C(a2),d2
                move.w  #1,d3
                move.b  $71(a2),d4
                move.w  #0,$50(a2)
                bsr.w   sub_12A88
                move.w  d0,$4A(a2)
                move.w  d0,$4E(a2)
                btst    #4,$69(a2)
                beq.w   .loc_1260E
                cmpi.b  #1,$6C(a2)
                bne.w   .loc_1260E
                btst    #5,$69(a2)
                bne.w   .loc_1260E
                btst    #6,$69(a2)
                bne.w   .loc_12606
                bsr.w   sub_12B0C
                move.w  d0,$50(a2)
                bra.w   .loc_1260E


.loc_12606:                              ; CODE XREF: sub_124E2+114↑j
                bsr.w   sub_12B24
                move.w  d0,$50(a2)

.loc_1260E:                              ; CODE XREF: sub_124E2+F6↑j
; sub_124E2+100↑j ...
                move.w  $30(a1),d0
                sub.w   $4A(a1),d0
                sub.w   $4A(a2),d0
                sub.w   $30(a2),d0
                move.w  d0,d1
                sub.w   $50(a1),d0
                bmi.w   .loc_1263A
                move.w  #0,d0
                move.w  d0,$52(a1)
                bclr    #7,$69(a1)
                bra.w   .loc_12654


.loc_1263A:                              ; CODE XREF: sub_124E2+142↑j
                move.w  #1,(ram_FF1B16).l
                move.w  d0,$52(a1)
                tst.w   $50(a1)
                beq.w   .loc_12654
                bset    #7,$69(a1)

.loc_12654:                              ; CODE XREF: sub_124E2+154↑j
; sub_124E2+168↑j
                sub.w   $50(a2),d1
                bmi.w   .loc_1266E
                move.w  #0,d1
                move.w  d1,$52(a2)
                bclr    #7,$69(a2)
                bra.w   .loc_1268A


.loc_1266E:                              ; CODE XREF: sub_124E2+176↑j
                move.w  #1,(ram_FF1B16).l
                neg.w   d1
                move.w  d1,$52(a2)
                tst.w   $50(a2)
                beq.w   .loc_1268A
                bset    #7,$69(a2)

.loc_1268A:                              ; CODE XREF: sub_124E2+188↑j
; sub_124E2+19E↑j
                tst.w   (ram_FF1B16).l
                beq.w   .loc_1280A
                bra.w   .loc_127EA


.loc_12698:                              ; CODE XREF: sub_124E2+5C↑j
                bclr    #1,$69(a1)
                move.w  8(a1),d1
                move.w  $C(a1),d2
                move.w  #1,d3
                move.b  $71(a1),d4
                move.w  #0,$50(a1)
                bsr.w   sub_12A88
                move.w  d0,$4A(a1)
                move.w  d0,$4E(a1)
                cmpa.l  #ram_FF26AA,a2
                bcc.w   .loc_12706
                btst    #4,$69(a1)
                beq.w   .loc_12706
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_12706
                btst    #5,$69(a1)
                bne.w   .loc_12706
                btst    #6,$69(a1)
                bne.w   .loc_126FE
                bsr.w   sub_12B0C
                move.w  d0,$50(a1)
                bra.w   .loc_12706


.loc_126FE:                              ; CODE XREF: sub_124E2+20C↑j
                bsr.w   sub_12B24
                move.w  d0,$50(a1)

.loc_12706:                              ; CODE XREF: sub_124E2+1E4↑j
; sub_124E2+1EE↑j ...
                move.w  8(a2),d1
                move.w  $C(a2),d2
                move.w  #0,d3
                move.b  $71(a2),d4
                move.w  #0,$50(a2)
                bsr.w   sub_12A88
                move.w  d0,$4A(a2)
                move.w  d0,$4C(a2)
                btst    #4,$69(a2)
                beq.w   .loc_12764
                cmpi.b  #1,$6C(a2)
                bne.w   .loc_12764
                btst    #5,$69(a2)
                beq.w   .loc_12764
                btst    #6,$69(a2)
                bne.w   .loc_1275C
                bsr.w   sub_12B0C
                move.w  d0,$50(a2)
                bra.w   .loc_12764


.loc_1275C:                              ; CODE XREF: sub_124E2+26A↑j
                bsr.w   sub_12B24
                move.w  d0,$50(a2)

.loc_12764:                              ; CODE XREF: sub_124E2+24C↑j
; sub_124E2+256↑j ...
                move.w  $30(a1),d0
                add.w   $4A(a1),d0
                add.w   $4A(a2),d0
                sub.w   $30(a2),d0
                move.w  d0,d1
                add.w   $50(a1),d0
                bpl.w   .loc_12790
                move.w  #0,d0
                move.w  d0,$52(a1)
                bclr    #7,$69(a1)
                bra.w   .loc_127AA


.loc_12790:                              ; CODE XREF: sub_124E2+298↑j
                move.w  #1,(ram_FF1B16).l
                move.w  d0,$52(a1)
                tst.w   $50(a1)
                beq.w   .loc_127AA
                bset    #7,$69(a1)

.loc_127AA:                              ; CODE XREF: sub_124E2+2AA↑j
; sub_124E2+2BE↑j
                add.w   $50(a2),d1
                bpl.w   .loc_127C4
                move.w  #0,d1
                move.w  d1,$52(a2)
                bclr    #7,$69(a2)
                bra.w   .loc_127E0


.loc_127C4:                              ; CODE XREF: sub_124E2+2CC↑j
                move.w  #1,(ram_FF1B16).l
                neg.w   d1
                move.w  d1,$52(a2)
                tst.w   $50(a2)
                beq.w   .loc_127E0
                bset    #7,$69(a2)

.loc_127E0:                              ; CODE XREF: sub_124E2+2DE↑j
; sub_124E2+2F4↑j
                tst.w   (ram_FF1B16).l
                beq.w   .loc_1280A

.loc_127EA:                              ; CODE XREF: sub_124E2+1B2↑j
                move.w  $32(a1),d0
                sub.w   (ram_FF303E).l,d0
                sub.w   $32(a2),d0
                bpl.w   .loc_1280A
                bset    #4,$68(a1)
                bset    #4,$68(a2)
                rts


.loc_1280A:                              ; CODE XREF: sub_124E2+34↑j
; sub_124E2+50↑j ...
                bclr    #4,$68(a1)
                bclr    #7,$69(a1)
                bclr    #7,$69(a2)
                rts
; End of function sub_124E2


; =============== S U B R O U T I N E =======================================


sub_1281E:                              ; CODE XREF: Race_Update+106↑p
                lea     (ram_FF1A0C).l,a0

.loc_12824:                              ; CODE XREF: sub_1281E+16↓j
; sub_1281E+1E↓j
                movea.l (a0)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .loc_1283E
                cmpi.b  #$FF,$6E(a1)
                bne.s   .loc_12824
                bclr    #4,$68(a1)
                bra.s   .loc_12824


.loc_1283E:                              ; CODE XREF: sub_1281E+C↑j
                lea     (unk_2589A).l,a0

.loc_12844:                              ; CODE XREF: sub_1281E+36↓j
; sub_1281E+3E↓j
                movea.l (a0)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .loc_1285E
                cmpi.b  #$FF,$6E(a1)
                bne.s   .loc_12844
                bclr    #4,$68(a1)
                bra.s   .loc_12844


.loc_1285E:                              ; CODE XREF: sub_1281E+2C↑j
                bclr    #4,(ram_FF3012).l
                rts
; End of function sub_1281E


; =============== S U B R O U T I N E =======================================


sub_12868:                              ; CODE XREF: Race_Update+C0↑p
                lea     (unk_2589A).l,a2

.loc_1286E:                              ; CODE XREF: sub_12868+16↓j
; sub_12868+1E↓j ...
                movea.l (a2)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .locret_128DE
                cmpi.w  #$FFFF,$56(a1)
                bne.s   .loc_1286E
                btst    #6,$68(a1)
                beq.s   .loc_1286E
                move.w  $16(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a0
                movea.l (a0,d0.w),a0
                move.w  $12(a1),d0
                move.w  (Race_ram_FrameDelay).l,d1
                mulu.w  d1,d0
                move.l  d0,$26(a1)
                bsr.w   sub_113A4
                btst    #3,$69(a1)
                bne.w   .loc_128BE
                bsr.w   sub_116E2
                bra.w   .loc_128C2


.loc_128BE:                              ; CODE XREF: sub_12868+4A↑j
                bsr.w   sub_11940

.loc_128C2:                              ; CODE XREF: sub_12868+52↑j
                move.w  $36(a1),d1
                add.w   $38(a1),d1
                move.w  d1,0.w(a1)
                bsr.w   sub_137E4
                bsr.w   sub_12C9A
                jsr     (sub_13DE0).l
                bra.s   .loc_1286E


.locret_128DE:                           ; CODE XREF: sub_12868+C↑j
                rts
; End of function sub_12868


; =============== S U B R O U T I N E =======================================


sub_128E0:                              ; CODE XREF: Race_Update+F4↑p
                cmpi.l  #$708,(ram_FF1E9A).l
                bcs.w   .locret_12972
                bset    #6,$68(a1)
                jsr     (Rand_GetWord).l
                move.w  (ram_FF1E68).l,d1
                add.w   (ram_FF1B30).l,d1
                subq.w  #1,d1
                btst    #0,d0
                bne.w   .loc_1291A
                move.b  #0,$73(a1)
                bra.w   .loc_12920


.loc_1291A:                              ; CODE XREF: sub_128E0+2C↑j
                move.b  #2,$73(a1)

.loc_12920:                              ; CODE XREF: sub_128E0+36↑j
                tst.w   d0
                bmi.w   .loc_12942
                addq.w  #1,d1
                andi.w  #$7FF,d0
                move.w  d0,$30(a1)
                bset    #3,$69(a1)
                move.w  d0,0.w(a1)
                move.w  d0,$1A(a1)
                bra.w   .loc_1295A


.loc_12942:                              ; CODE XREF: sub_128E0+42↑j
                bclr    #3,$69(a1)
                andi.w  #$7FF,d0
                neg.w   d0
                move.w  d0,$30(a1)
                move.w  d0,0.w(a1)
                move.w  d0,$1A(a1)

.loc_1295A:                              ; CODE XREF: sub_128E0+5E↑j
                move.w  #0,$32(a1)
                move.w  #$1770,$12(a1)
                swap    d1
                clr.w   d1
                move.l  d1,4(a1)
                move.l  d1,$1E(a1)

.locret_12972:                           ; CODE XREF: sub_128E0+A↑j
                rts
; End of function sub_128E0


; =============== S U B R O U T I N E =======================================


sub_12974:                              ; CODE XREF: Race_Update:@loc_C106↑p
                lea     (ram_FF2FAA).l,a1
                cmpi.l  #$708,(ram_FF1E9A).l
                bcc.w   .loc_12992
                bclr    #6,$68(a1)
                bra.w   .locret_12A86


.loc_12992:                              ; CODE XREF: sub_12974+10↑j
                btst    #6,$68(a1)
                beq.w   .locret_12A86
                move.w  $30(a1),d0
                btst    #3,$69(a1)
                beq.w   .loc_129AC
                neg.w   d0

.loc_129AC:                              ; CODE XREF: sub_12974+32↑j
                tst.w   d0
                bpl.w   .loc_12A32
                lea     (unk_2589A).l,a0

.loc_129B8:                              ; CODE XREF: sub_12974+62↓j
; sub_12974+6A↓j ...
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_12A32
                move.l  4(a2),d1
                sub.l   4(a1),d1
                bpl.w   .loc_129E4
                btst    #3,$69(a2)
                bne.s   .loc_129B8
                cmp.l   #$FFF00000,d1
                bmi.s   .loc_129B8
                bra.w   .loc_129F4


.loc_129E4:                              ; CODE XREF: sub_12974+58↑j
                btst    #3,$69(a2)
                beq.s   .loc_129B8
                cmp.l   #$100000,d1
                bpl.s   .loc_129B8

.loc_129F4:                              ; CODE XREF: sub_12974+6C↑j
                neg.w   d0
                subi.w  #$100,d0
                bmi.w   .loc_12A32
                subi.w  #$100,d0
                bpl.w   .loc_12A16
                move.w  #0,$12(a1)
                move.w  #0,$14(a1)
                bra.w   .loc_12A38


.loc_12A16:                              ; CODE XREF: sub_12974+8E↑j
                ext.l   d0
                asl.l   #8,d0
                move.w  $12(a1),d1
                mulu.w  #8,d1
                cmp.l   d1,d0
                blt.w   .loc_12A32
                move.w  #$FFF8,$14(a1)
                bra.w   .loc_12A38


.loc_12A32:                              ; CODE XREF: sub_12974+3A↑j
; sub_12974+4C↑j ...
                move.w  #$20,$14(a1) ; ' '

.loc_12A38:                              ; CODE XREF: sub_12974+9E↑j
; sub_12974+BA↑j
                move.w  $12(a1),d0
                move.w  (Race_ram_FrameDelay).l,d2
                move.w  $14(a1),d1
                mulu.w  d2,d1
                add.w   d1,d0
                bcc.w   .loc_12A5C
                move.w  #0,d0
                move.w  #0,$12(a1)
                bra.w   .loc_12A7C


.loc_12A5C:                              ; CODE XREF: sub_12974+D6↑j
                cmp.w   #$1770,d0
                ble.w   .loc_12A68
                move.w  #$1770,d0

.loc_12A68:                              ; CODE XREF: sub_12974+EC↑j
                move.w  d0,$12(a1)
                mulu.w  d2,d0
                lsr.l   #8,d0
                btst    #3,$69(a1)
                beq.w   .loc_12A7C
                neg.w   d0

.loc_12A7C:                              ; CODE XREF: sub_12974+E4↑j
; sub_12974+102↑j
                move.w  $30(a1),$1A(a1)
                add.w   d0,$30(a1)

.locret_12A86:                           ; CODE XREF: sub_12974+1A↑j
; sub_12974+24↑j
                rts
; End of function sub_12974


; =============== S U B R O U T I N E =======================================


sub_12A88:                              ; CODE XREF: sub_124E2+7C↑p
; sub_124E2+E4↑p ...
                cmp.b   #$10,d4
                bpl.w   .loc_12A96
                bsr.w   sub_12A9C
                rts


.loc_12A96:                              ; CODE XREF: sub_12A88+4↑j
                bsr.w   sub_12AF8
                rts
; End of function sub_12A88


; =============== S U B R O U T I N E =======================================


sub_12A9C:                              ; CODE XREF: sub_11CC8+3C↑p
; sub_11CC8+48↑p ...
                movem.l d1-d3,-(sp)
                lea     (unk_12B7C).l,a6
                asr.w   #3,d2
                addq.w  #2,d2
                cmp.w   #2,d2
                bpl.w   .loc_12AC0
                tst.w   d2
                bpl.w   .loc_12ACC
                move.w  #0,d2
                bra.w   .loc_12ACC


.loc_12AC0:                              ; CODE XREF: sub_12A9C+12↑j
                cmp.w   #4,d2
                ble.w   .loc_12ACC
                move.w  #4,d2

.loc_12ACC:                              ; CODE XREF: sub_12A9C+18↑j
; sub_12A9C+20↑j ...
                asl.w   #1,d2
                add.w   d2,d3
                asr.w   #4,d1
                bpl.w   .loc_12AD8
                neg.w   d1

.loc_12AD8:                              ; CODE XREF: sub_12A9C+36↑j
                cmp.w   #3,d1
                ble.w   .loc_12AE4
                move.w  #3,d1

.loc_12AE4:                              ; CODE XREF: sub_12A9C+40↑j
                asl.w   #1,d1
                add.w   d1,d3
                asl.w   #2,d1
                add.w   d1,d3
                move.b  (a6,d3.w),d0
                ext.w   d0
                movem.l (sp)+,d1-d3
                rts
; End of function sub_12A9C


; =============== S U B R O U T I N E =======================================


sub_12AF8:                              ; CODE XREF: sub_12A88:@loc_12A96↑p
                cmp.b   #$12,d4
                bpl.w   .loc_12B06
                move.w  #$37,d0 ; '7'
                rts


.loc_12B06:                              ; CODE XREF: sub_12AF8+4↑j
                move.w  #$60,d0 ; '`'
                rts
; End of function sub_12AF8


; =============== S U B R O U T I N E =======================================


sub_12B0C:                              ; CODE XREF: sub_124E2+BA↑p
; sub_124E2+118↑p ...
                btst    #1,$6B(a1)
                beq.w   .loc_12B1E
                move.w  #$28,d0 ; '('
                bra.w   .locret_12B22


.loc_12B1E:                              ; CODE XREF: sub_12B0C+6↑j
                move.w  #$19,d0

.locret_12B22:                           ; CODE XREF: sub_12B0C+E↑j
                rts
; End of function sub_12B0C


; =============== S U B R O U T I N E =======================================


sub_12B24:                              ; CODE XREF: sub_124E2:@loc_125A8↑p
; sub_124E2:@loc_12606↑p ...
                move.w  #$1A,d0
                rts
; End of function sub_12B24


                dc.b $48 ; H
                dc.b $E7
                dc.b $70 ; p
                dc.b   0
                dc.b $38 ; 8
                dc.b   2
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $44 ; D
                dc.b $E6
                dc.b $4C ; L
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $3A ; :
                dc.b $38 ; 8
                dc.b   1
                dc.b $4A ; J
                dc.b $44 ; D
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $44 ; D
                dc.b $44 ; D
                dc.b $44 ; D
                dc.b $43 ; C
                dc.b $E8
                dc.b $4C ; L
                dc.b $B8
                dc.b $7C ; |
                dc.b   0
                dc.b   2
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b $24 ; $
                dc.b $E3
                dc.b $44 ; D
                dc.b $D8
                dc.b $43 ; C
                dc.b $4D ; M
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $2B ; +
                dc.b $CC
                dc.b $10
                dc.b $36 ; 6
                dc.b $40 ; @
                dc.b   0
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $17
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $48 ; H
                dc.b $80
                dc.b $4C ; L
                dc.b $DF
                dc.b   0
                dc.b  $E
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b $4C ; L
                dc.b $DF
                dc.b   0
                dc.b  $E
                dc.b $61 ; a
                dc.b $92
                dc.b $4E ; N
                dc.b $75 ; u
unk_12B7C:      dc.b $10                ; DATA XREF: sub_12A9C+4↑o
                dc.b $19
                dc.b  $C
                dc.b $13
                dc.b  $D
                dc.b  $D
                dc.b $13
                dc.b  $C
                dc.b $19
                dc.b $10
                dc.b  $E
                dc.b $16
                dc.b  $C
                dc.b  $F
                dc.b  $D
                dc.b  $D
                dc.b  $E
                dc.b $14
                dc.b $13
                dc.b $18
                dc.b $15
                dc.b  $F
                dc.b  $A
                dc.b  $C
                dc.b  $D
                dc.b  $D
                dc.b  $F
                dc.b $10
                dc.b $18
                dc.b $13
                dc.b $12
                dc.b $13
                dc.b  $D
                dc.b $12
                dc.b  $D
                dc.b  $D
                dc.b  $D
                dc.b $10
                dc.b $11
                dc.b $12
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $1E
                dc.b $1E
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $1E
                dc.b $1E
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $1A
                dc.b $1A
                dc.b $1A
                dc.b $1A
                dc.b   0
                dc.b $1A

; =============== S U B R O U T I N E =======================================


sub_12BD2:                              ; CODE XREF: sub_10E66:@loc_11018↑p
; sub_1103A+6C↑p
                move.w  4(a1),d0
                lea     (ram_FFDC58).l,a4
                move.w  d0,d1
                sub.w   (ram_FF1E68).l,d1
                bpl.w   .loc_12BEA
                neg.w   d1

.loc_12BEA:                              ; CODE XREF: sub_12BD2+12↑j
                cmp.w   #$40,d1 ; '@'
                bpl.w   .locret_12C98
                andi.w  #$FF,d0
                asl.w   #1,d0
                move.b  1(a4,d0.w),d1
                btst    #0,$68(a1)
                beq.w   .loc_12C16
                cmpi.w  #$1E,$2E(a1)
                bmi.w   .loc_12C1C
                move.b  (ram_FF1AC8).l,d1

.loc_12C16:                              ; CODE XREF: sub_12BD2+30↑j
                ext.w   d1
                move.w  d1,$A(a1)

.loc_12C1C:                              ; CODE XREF: sub_12BD2+3A↑j
                addi.w  #$C,d0
                andi.w  #$1FF,d0
                move.b  2(a4,d0.w),d0
                ext.w   d0
                move.w  d0,$44(a1)
                btst    #2,$69(a1)
                beq.w   .loc_12C3C
                add.w   $46(a1),d0

.loc_12C3C:                              ; CODE XREF: sub_12BD2+62↑j
                bsr.w   sub_12CCE
                move.w  $C(a1),8(a1)
                move.w  8(a1),d1
                bpl.w   .loc_12C50
                neg.w   d1

.loc_12C50:                              ; CODE XREF: sub_12BD2+78↑j
                cmp.w   #$7F,d1
                bmi.w   .locret_12C98
                cmpi.b  #$FF,$6E(a1)
                bne.w   .locret_12C98
                btst    #4,$68(a1)
                bne.w   .loc_12C76
                jsr     (sub_15538).l
                bra.w   .loc_12C7C


.loc_12C76:                              ; CODE XREF: sub_12BD2+96↑j
                jsr     (sub_1555C).l

.loc_12C7C:                              ; CODE XREF: sub_12BD2+A0↑j
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                bset    #4,$68(a1)
                bsr.w   sub_11906
                bclr    #7,$6A(a1)

.locret_12C98:                           ; CODE XREF: sub_12BD2+1C↑j
; sub_12BD2+82↑j ...
                rts
; End of function sub_12BD2


; =============== S U B R O U T I N E =======================================


sub_12C9A:                              ; CODE XREF: sub_12868+6A↑p
                move.w  4(a1),d0
                lea     (ram_FFDC58).l,a4
                andi.w  #$FF,d0
                asl.w   #1,d0
                move.b  1(a4,d0.w),d1
                ext.w   d1
                move.w  d1,$A(a1)
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,$44(a1)
                add.w   $46(a1),d0
                move.w  d0,8(a1)
                move.w  #0,$C(a1)
                rts
; End of function sub_12C9A


; =============== S U B R O U T I N E =======================================


sub_12CCE:                              ; CODE XREF: sub_12BD2:@loc_12C3C↑p
                move.w  (Race_ram_FrameDelay).l,d1
                asl.w   #1,d1
                move.w  d0,d2
                move.w  $C(a1),d3
                cmp.w   d3,d2
                bpl.w   .loc_12CF4
                neg.w   d1
                sub.w   d3,d2
                cmp.w   d1,d2
                bpl.w   .loc_12D04
                add.w   d1,$C(a1)
                bra.w   .locret_12D08


.loc_12CF4:                              ; CODE XREF: sub_12CCE+10↑j
                sub.w   d3,d2
                cmp.w   d1,d2
                bmi.w   .loc_12D04
                add.w   d1,$C(a1)
                bra.w   .locret_12D08


.loc_12D04:                              ; CODE XREF: sub_12CCE+1A↑j
; sub_12CCE+2A↑j
                move.w  d0,$C(a1)

.locret_12D08:                           ; CODE XREF: sub_12CCE+22↑j
; sub_12CCE+32↑j
                rts
; End of function sub_12CCE


unk_12D0A:      dc.b $FF                ; DATA XREF: sub_1384C+2↓o
; sub_13892+2↓o
                dc.b $60 ; `
                dc.b $FF
                dc.b $A0
                dc.b $FF
                dc.b $E0
                dc.b   0
                dc.b $20
                dc.b   0
                dc.b $60 ; `
                dc.b   0
                dc.b $A0
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b $D2
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $DC
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b $7C ; |
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $E0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $24 ; $
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $E0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $6A ; j
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $E0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $12
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $E0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $B0
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $24 ; $
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $6A ; j
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $12
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $B0
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $2C ; ,
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $44 ; D
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $2F ; /
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $E0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $24 ; $
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $2F ; /
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $E0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $6A ; j
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $2F ; /
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $E0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $12
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $2F ; /
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $E0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $B0
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $2F ; /
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $24 ; $
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $2F ; /
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $6A ; j
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $2F ; /
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $12
                dc.b   0
                dc.b   1
                dc.b $30 ; 0
                dc.b  $E
                dc.b   0
                dc.b   1
                dc.b $64 ; d
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $2F ; /
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $65 ; e
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $B0

; =============== S U B R O U T I N E =======================================


sub_12EA2:                              ; CODE XREF: Race_Update+12A↑p
                move.w  #0,(ram_FF1A98).l
                lea     (ram_FF1A08).l,a0
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_12EBC
                addq.w  #4,a0

.loc_12EBC:                              ; CODE XREF: sub_12EA2+14↑j
; sub_12EA2+40↓j ...
                movea.l (a0)+,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_12FE2
                btst    #4,$68(a1)
                beq.w   .loc_12EE4
                tst.b   $6E(a1)
                bmi.w   .loc_12EE4
                move.l  a0,-(sp)
                bsr.w   sub_13A92
                movea.l (sp)+,a0
                bra.s   .loc_12EBC


.loc_12EE4:                              ; CODE XREF: sub_12EA2+2C↑j
; sub_12EA2+34↑j
                move.b  $75(a1),d2
                ext.w   d2
                asl.w   #2,d2
                lea     (unk_258EE).l,a4
                movea.l (a4,d2.w),a4
                move.l  a4,(ram_FF1A68).l
                move.w  $5C(a1),d0
                add.w   (Race_ram_FrameDelay).l,d0
                cmp.w   (ram_FF18A8).l,d0
                bcs.w   .loc_12F14
                move.w  $E(a4),d0

.loc_12F14:                              ; CODE XREF: sub_12EA2+6A↑j
                move.w  d0,$5C(a1)
                move.l  a0,-(sp)
                btst    #7,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .loc_12F60
                move.w  4(a1),d0
                sub.w   (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                bpl.w   .loc_12F4A
                cmp.w   #$FFEE,d0
                bpl.w   .loc_12F60
                bclr    #6,$68(a1)
                bsr.w   sub_16CAE
                bra.w   .loc_12FDC


.loc_12F4A:                              ; CODE XREF: sub_12EA2+8E↑j
                cmp.w   #$22,d0 ; '"'
                bmi.w   .loc_12F60
                bclr    #6,$68(a1)
                bsr.w   sub_16C9A
                bra.w   .loc_12FDC


.loc_12F60:                              ; CODE XREF: sub_12EA2+80↑j
; sub_12EA2+96↑j ...
                bset    #6,$68(a1)
                move.b  $74(a1),d2
                ext.w   d2
                asl.w   #2,d2
                lea     (unk_259C0).l,a4
                movea.l (a4,d2.w),a4
                cmpa.l  #ram_FF1EAA,a1
                beq.w   .loc_12FD8
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_12FCE
                move.b  (ram_FF1ADB).l,d0
                cmp.b   $71(a1),d0
                bne.w   .loc_12FA6
                cmpi.w  #3,(ram_FF0520).l
                bne.w   .loc_12FD8

.loc_12FA6:                              ; CODE XREF: sub_12EA2+F4↑j
                move.w  STRUCT_OFFSET_66(a1),d0
                cmp.w   (ram_FF1EAA + STRUCT_OFFSET_SPEED).l,d0
                bgt.w   .loc_12FD8
                cmpa.l  (ram_FF1908).l,a1
                beq.w   .loc_12FCE
                move.w  (ram_FF1A98).l,d0
                cmp.w   (ram_FF1A96).l,d0
                bpl.w   .loc_12FD8

.loc_12FCE:                              ; CODE XREF: sub_12EA2+E6↑j
; sub_12EA2+118↑j
                addi.w  #1,(ram_FF1A98).l
                addq.w  #4,a4

.loc_12FD8:                              ; CODE XREF: sub_12EA2+DC↑j
; sub_12EA2+100↑j ...
                movea.l (a4),a6
                jsr     (a6)

.loc_12FDC:                              ; CODE XREF: sub_12EA2+A4↑j
; sub_12EA2+BA↑j
                movea.l (sp)+,a0
                bra.w   .loc_12EBC


.locret_12FE2:                           ; CODE XREF: sub_12EA2+22↑j
                rts
; End of function sub_12EA2


                dc.b $61 ; a
                dc.b   0
                dc.b   4
                dc.b $3C ; <
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $68 ; h
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $68 ; h
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $68 ; h
                dc.b $61 ; a
                dc.b   0
                dc.b  $A
                dc.b $92
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b $61 ; a
                dc.b   0
                dc.b   4
                dc.b $1C
                dc.b $61 ; a
                dc.b   0
                dc.b   1
                dc.b $B4
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $69 ; i
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $69 ; i
                dc.b $10
                dc.b $29 ; )
                dc.b   0
                dc.b $72 ; r
                dc.b $48 ; H
                dc.b $80
                dc.b $61 ; a
                dc.b   0
                dc.b   5
                dc.b $D4
                dc.b $B5
                dc.b $FC
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $61 ; a
                dc.b   0
                dc.b   3
                dc.b $F2
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $20
                dc.b $61 ; a
                dc.b   0
                dc.b  $D
                dc.b  $C
                dc.b $4A ; J
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A4
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $68 ; h
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $68 ; h
                dc.b $61 ; a
                dc.b   0
                dc.b   7
                dc.b $FA
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $68 ; h
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b $61 ; a
                dc.b   0
                dc.b  $F
                dc.b $86
                dc.b $B0
                dc.b $69 ; i
                dc.b   0
                dc.b $12
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $68 ; h
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $68 ; h
                dc.b $61 ; a
                dc.b   0
                dc.b  $A
                dc.b $1A
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $69 ; i
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $69 ; i
                dc.b $10
                dc.b $29 ; )
                dc.b   0
                dc.b $72 ; r
                dc.b $48 ; H
                dc.b $80
                dc.b $61 ; a
                dc.b   0
                dc.b   5
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $B5
                dc.b $FC
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $18
                dc.b $61 ; a
                dc.b   0
                dc.b  $C
                dc.b $A6
                dc.b $4A ; J
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A4
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b $61 ; a
                dc.b   0
                dc.b   7
                dc.b $A0
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $61 ; a
                dc.b   0
                dc.b   3
                dc.b $6E ; n
                dc.b $61 ; a
                dc.b   0
                dc.b   1
                dc.b   6
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $68 ; h
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $68 ; h
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b $30 ; 0
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $32 ; 2
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $26 ; &
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $14
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b $90
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $30 ; 0
                dc.b $4A ; J
                dc.b $33 ; 3
                dc.b $C0
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $32 ; 2
                dc.b $6E ; n
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $32 ; 2
                dc.b $61 ; a
                dc.b   0
                dc.b $FF
                dc.b  $C
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_13106:                              ; CODE XREF: Race_Update+130↑p
                lea     (unk_2589A).l,a0

.loc_1310C:                              ; CODE XREF: sub_13106+26↓j
                movea.l (a0)+,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_1312E
                move.b  $74(a1),d0
                ext.w   d0
                asl.w   #3,d0
                lea     (unk_25A44).l,a2
                movea.l (a2,d0.w),a3
                jsr     (a3)
                bra.s   .loc_1310C


.locret_1312E:                           ; CODE XREF: sub_13106+E↑j
                rts
; End of function sub_13106


                dc.b $20
                dc.b $29 ; )
                dc.b   0
                dc.b   4
                dc.b $90
                dc.b $B9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $68 ; h
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $80
                dc.b $B0
                dc.b $BC
                dc.b   0
                dc.b $21 ; !
                dc.b   0
                dc.b   0
                dc.b $6D ; m
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b $68 ; h
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b STRUCT_OFFSET_66 ; f
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $46 ; F
                dc.b $C1
                dc.b $E9
                dc.b   0
                dc.b $12
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $C0
                dc.b $F9
                dc.b   0
                dc.b $FF
                dc.b $30 ; 0
                dc.b $4A ; J
                dc.b $34 ; 4
                dc.b $29 ; )
                dc.b   0
                dc.b $30 ; 0
                dc.b $D0
                dc.b $42 ; B
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $22 ; "
                dc.b $B0
                dc.b $7C ; |
                dc.b   0
                dc.b $A9
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b $B0
                dc.b $7C ; |
                dc.b   0
                dc.b $37 ; 7
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b $36 ; 6
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b   0
                dc.b $37 ; 7
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $2A ; *
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b   0
                dc.b $A9
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $22 ; "
                dc.b $B0
                dc.b $7C ; |
                dc.b $FF
                dc.b $57 ; W
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b $B0
                dc.b $7C ; |
                dc.b $FF
                dc.b $C9
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b $16
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b $FF
                dc.b $C9
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b $FF
                dc.b $57 ; W
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b $44 ; D
                dc.b $69 ; i
                dc.b   0
                dc.b $46 ; F
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $30 ; 0
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_131BE:                              ; CODE XREF: sub_165D0+A↓p
; sub_16612+6↓p ...
                lea     (ram_FF1EAA).l,a2
                move.w  $12(a1),d6
                movea.l (ram_FF1A68).l,a4
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_131E0
                cmp.w   STRUCT_OFFSET_66(a1),d6
                bmi.w   .loc_1325E

.loc_131E0:                              ; CODE XREF: sub_131BE+16↑j
                sub.w   $12(a2),d6
                move.l  4(a1),d7
                sub.l   4(a2),d7
                bmi.w   .loc_13248
                btst    #4,$68(a2)
                beq.w   .loc_13202
                tst.b   $6E(a2)
                bpl.w   .loc_1325E

.loc_13202:                              ; CODE XREF: sub_131BE+38↑j
                tst.w   d6
                bpl.w   .loc_13280
                neg.w   d6
                divu.w  d6,d7
                move.w  $16(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a3
                movea.l (a3,d0.w),a3
                move.w  $18(a1),d0
                asl.w   #1,d0
                move.w  2(a3,d0.w),d5
                mulu.w  d7,d5
                move.w  $14(a2),d0
                muls.w  d7,d0
                ext.l   d6
                add.l   d0,d6
                cmp.l   d6,d5
                blt.w   .loc_1325E
                bclr    #1,$68(a1)
                bclr    #1,$68(a1)
                bra.w   .loc_1328C


.loc_13248:                              ; CODE XREF: sub_131BE+2E↑j
                tst.w   d6
                ble.w   .loc_1325E
                neg.l   d7
                divu.w  d6,d7
                mulu.w  #$40,d7 ; '@'
                ext.l   d6
                cmp.l   d6,d7
                bmi.w   .loc_13280

.loc_1325E:                              ; CODE XREF: sub_131BE+1E↑j
; sub_131BE+40↑j ...
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                btst    #5,$68(a1)
                bne.w   .loc_13280
                bsr.w   sub_13FE6
                cmp.w   $12(a1),d0
                bpl.w   .loc_1328C

.loc_13280:                              ; CODE XREF: sub_131BE+46↑j
; sub_131BE+9C↑j ...
                bset    #2,$68(a1)
                bclr    #1,$68(a1)

.loc_1328C:                              ; CODE XREF: sub_131BE+86↑j
; sub_131BE+BE↑j
                bsr.w   sub_13A92
                rts
; End of function sub_131BE


; =============== S U B R O U T I N E =======================================


sub_13292:                              ; CODE XREF: sub_166DC+E↓p
                lea     (ram_FF1EAA).l,a2
                move.w  $12(a1),d6
                movea.l (ram_FF1A68).l,a4
                sub.w   $12(a2),d6
                move.l  4(a2),d7
                addi.l  #$8000,d7
                sub.l   4(a1),d7
                bpl.w   .loc_132F4
                tst.w   d6
                bpl.w   .loc_1332A
                neg.w   d6
                neg.l   d7
                divu.w  d6,d7
                move.w  $16(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a3
                movea.l (a3,d0.w),a3
                move.w  $18(a1),d0
                asl.w   #1,d0
                move.w  2(a3,d0.w),d5
                mulu.w  d7,d5
                move.w  $14(a2),d0
                muls.w  d7,d0
                ext.l   d6
                add.l   d0,d6
                cmp.l   d6,d5
                bpl.w   .loc_1332A
                bra.w   .loc_13308


.loc_132F4:                              ; CODE XREF: sub_13292+22↑j
                tst.w   d6
                ble.w   .loc_13308
                divu.w  d6,d7
                mulu.w  #$40,d7 ; '@'
                ext.l   d6
                cmp.l   d6,d7
                bmi.w   .loc_1332A

.loc_13308:                              ; CODE XREF: sub_13292+5E↑j
; sub_13292+64↑j
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                btst    #5,$68(a1)
                bne.w   .loc_1332A
                bsr.w   sub_13FE6
                cmp.w   $12(a1),d0
                bpl.w   .loc_13336

.loc_1332A:                              ; CODE XREF: sub_13292+28↑j
; sub_13292+5A↑j ...
                bset    #2,$68(a1)
                bclr    #1,$68(a1)

.loc_13336:                              ; CODE XREF: sub_13292+94↑j
                bsr.w   sub_13A92
                rts
; End of function sub_13292


; =============== S U B R O U T I N E =======================================


sub_1333C:                              ; CODE XREF: sub_16612+C↓p
; sub_16644+1C↓p ...
                move.w  $30(a2),d0
                move.w  $30(a1),d2
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_13370
                tst.w   d0
                bpl.w   .loc_13364
                cmp.w   #$FF3C,d0
                bpl.w   .loc_13370
                move.w  #$FF3C,d0
                bra.w   .loc_13370


.loc_13364:                              ; CODE XREF: sub_1333C+14↑j
                cmp.w   #$C4,d0
                ble.w   .loc_13370
                move.w  #$C4,d0

.loc_13370:                              ; CODE XREF: sub_1333C+E↑j
; sub_1333C+1C↑j ...
                sub.w   d2,d0
                bmi.w   .loc_13378
                neg.w   d1

.loc_13378:                              ; CODE XREF: sub_1333C+36↑j
                add.w   d1,d0
                move.w  $12(a1),d1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_1338A
                lsr.w   #1,d1

.loc_1338A:                              ; CODE XREF: sub_1333C+48↑j
                lsr.w   #8,d1
                beq.w   .locret_133EE
                movem.l d0-d1,-(sp)
                bsr.w   sub_136B6
                move.w  d0,d2
                movem.l (sp)+,d0-d1
                tst.w   d2
                beq.w   .loc_133C0
                mulu.w  d2,d1
                cmp.l   #$10000,d1
                bcs.w   .loc_133B8
                move.w  #0,d0
                bra.w   .loc_133E4


.loc_133B8:                              ; CODE XREF: sub_1333C+70↑j
                ext.l   d0
                swap    d0
                divs.w  d1,d0
                asr.w   #8,d0

.loc_133C0:                              ; CODE XREF: sub_1333C+64↑j
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d1
                tst.w   d0
                bpl.w   .loc_133DC
                neg.w   d1
                cmp.w   d1,d0
                bpl.w   .loc_133E4
                bra.w   .loc_133E2


.loc_133DC:                              ; CODE XREF: sub_1333C+90↑j
                cmp.w   d1,d0
                ble.w   .loc_133E4

.loc_133E2:                              ; CODE XREF: sub_1333C+9C↑j
                move.w  d1,d0

.loc_133E4:                              ; CODE XREF: sub_1333C+78↑j
; sub_1333C+98↑j ...
                move.w  d0,$46(a1)
                bset    #2,$69(a1)

.locret_133EE:                           ; CODE XREF: sub_1333C+50↑j
                rts
; End of function sub_1333C


                dc.b $90
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b $48 ; H
                dc.b $C0
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $32 ; 2
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $E0
                dc.b $49 ; I
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $1C
                dc.b $34 ; 4
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $46 ; F
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $C2
                dc.b $C2
                dc.b $81
                dc.b $C1
                dc.b $E0
                dc.b $40 ; @
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $46 ; F
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $69 ; i
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_13422:                              ; CODE XREF: sub_166F0+24↓p
                move.w  (ram_FF1B46).l,(ram_FF1896).l
                move.l  a2,-(sp)
                move.w  (ram_FF1B46).l,-(sp)
                move.w  d0,-(sp)
                move.w  #0,(ram_FF1898).l
                move.w  #0,(ram_FF18A0).l
                cmpi.b  #$10,$71(a2)
                bmi.w   .loc_13472
                cmpi.b  #$12,$71(a2)
                bpl.w   .loc_13472
                tst.w   $30(a1)
                bmi.w   .loc_1346A
                move.w  #2,d0
                bra.w   .loc_13480


.loc_1346A:                              ; CODE XREF: sub_13422+3C↑j
                move.w  #5,d0
                bra.w   .loc_134BC


.loc_13472:                              ; CODE XREF: sub_13422+2A↑j
; sub_13422+34↑j
                tst.w   $30(a1)
                bmi.w   .loc_134F0

.loc_1347A:                              ; CODE XREF: sub_13422+8C↓j
                subq.w  #1,d0
                ble.w   .loc_134B0

.loc_13480:                              ; CODE XREF: sub_13422+44↑j
                bsr.w   sub_135F6
                move.l  a2,(ram_FF1892).l
                move.w  (ram_FF1B46).l,(ram_FF1898).l
                move.w  d0,(ram_FF189A).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_1347A

.loc_134B0:                              ; CODE XREF: sub_13422+5A↑j
                move.w  (sp),d0

.loc_134B2:                              ; CODE XREF: sub_13422+C8↓j
                addq.w  #1,d0
                cmp.w   #7,d0
                bpl.w   .loc_13562

.loc_134BC:                              ; CODE XREF: sub_13422+4C↑j
                bsr.w   sub_135F6
                move.l  a2,(ram_FF189C).l
                move.w  (ram_FF1B46).l,(ram_FF18A0).l
                move.w  d0,(ram_FF18A2).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_134B2
                bra.w   .loc_13562


.loc_134F0:                              ; CODE XREF: sub_13422+54↑j
; sub_13422+106↓j
                addq.w  #1,d0
                cmp.w   #7,d0
                bpl.w   .loc_1352A
                bsr.w   sub_135F6
                move.l  a2,(ram_FF1892).l
                move.w  (ram_FF1B46).l,(ram_FF1898).l
                move.w  d0,(ram_FF189A).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_134F0

.loc_1352A:                              ; CODE XREF: sub_13422+D4↑j
                move.w  (sp),d0

.loc_1352C:                              ; CODE XREF: sub_13422+13E↓j
                subq.w  #1,d0
                bmi.w   .loc_13562
                bsr.w   sub_135F6
                move.l  a2,(ram_FF189C).l
                move.w  (ram_FF1B46).l,(ram_FF18A0).l
                move.w  d0,(ram_FF18A2).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_1352C

.loc_13562:                              ; CODE XREF: sub_13422+96↑j
; sub_13422+CA↑j ...
                addq.w  #2,sp
                move.w  (sp)+,(ram_FF1B46).l
                movea.l (sp)+,a2
                move.w  (ram_FF1898).l,d1
                cmp.w   (ram_FF18A0).l,d1
                bpl.w   .loc_135A2
                move.w  (ram_FF18A0).l,d1
                cmp.w   (ram_FF1B46).l,d1
                bmi.w   .loc_135C2
                move.w  d1,(ram_FF1B46).l
                movea.l (ram_FF189C).l,a2
                move.w  (ram_FF18A2).l,d0
                bra.w   .loc_135D6


.loc_135A2:                              ; CODE XREF: sub_13422+156↑j
                cmp.w   (ram_FF1B46).l,d1
                bmi.w   .loc_135C2
                move.w  d1,(ram_FF1B46).l
                movea.l (ram_FF1892).l,a2
                move.w  (ram_FF189A).l,d0
                bra.w   .loc_135D6


.loc_135C2:                              ; CODE XREF: sub_13422+166↑j
; sub_13422+186↑j
                bclr    #1,$68(a1)
                bset    #2,$68(a1)
                bra.w   .locret_135E6


.loc_135D2:                              ; CODE XREF: sub_13422+7E↑j
; sub_13422+BA↑j ...
                addq.w  #4,sp
                movea.l (sp)+,a2

.loc_135D6:                              ; CODE XREF: sub_13422+17C↑j
; sub_13422+19C↑j
                bsr.w   sub_13892
                bset    #1,$68(a1)
                bclr    #2,$68(a1)

.locret_135E6:                           ; CODE XREF: sub_13422+1AC↑j
                rts
; End of function sub_13422


                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $68 ; h
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_135F6:                              ; CODE XREF: sub_13422:@loc_13480↑p
; sub_13422:@loc_134BC↑p ...
                lea     (ram_FF178A).l,a6
                move.b  (a6,d0.w),d1
                ext.w   d1
                beq.w   .loc_1361E
                move.w  #$F0,(ram_FF1B46).l
                bsr.w   sub_13626
                cmpi.w  #$F0,(ram_FF1B46).l
                blt.w   .locret_13624

.loc_1361E:                              ; CODE XREF: sub_135F6+C↑j
                movea.l #$FFFFFFFF,a2

.locret_13624:                           ; CODE XREF: sub_135F6+24↑j
                rts
; End of function sub_135F6


; =============== S U B R O U T I N E =======================================


sub_13626:                              ; CODE XREF: sub_135F6+18↑p
                move.b  $71(a1),d7
                subq.w  #1,d1
                lea     (ram_FF1792).l,a6
                move.w  d0,d2
                asl.w   #4,d2
                adda.w  d2,a6

.loc_13638:                              ; CODE XREF: sub_13626:@loc_136B0↓j
                move.b  (a6)+,d2
                cmp.b   d7,d2
                beq.w   .loc_136B0
                cmp.b   #$10,d2
                bpl.w   .loc_13656
                lea     (unk_25856).l,a0
                move.w  #0,d6
                bra.w   .loc_13664


.loc_13656:                              ; CODE XREF: sub_13626+1E↑j
                lea     (unk_2589A).l,a0
                move.w  #$FFFF,d6
                subi.w  #$10,d2

.loc_13664:                              ; CODE XREF: sub_13626+2C↑j
                ext.w   d2
                asl.w   #2,d2
                movea.l (a0,d2.w),a2
                move.w  $12(a1),d2
                btst    #3,$69(a1)
                beq.w   .loc_1367C
                neg.w   d2

.loc_1367C:                              ; CODE XREF: sub_13626+50↑j
                move.w  $12(a2),d4
                btst    #3,$69(a2)
                beq.w   .loc_1368C
                neg.w   d4

.loc_1368C:                              ; CODE XREF: sub_13626+60↑j
                sub.w   d4,d2
                ble.w   .loc_136B0
                move.l  4(a2),d3
                sub.l   4(a1),d3
                ble.w   .loc_136B0
                divu.w  d2,d3
                cmp.w   (ram_FF1B46).l,d3
                bpl.w   .loc_136B0
                move.w  d3,(ram_FF1B46).l

.loc_136B0:                              ; CODE XREF: sub_13626+16↑j
; sub_13626+68↑j ...
                dbf     d1,.loc_13638
                rts
; End of function sub_13626


; =============== S U B R O U T I N E =======================================


sub_136B6:                              ; CODE XREF: sub_1333C+58↑p
                move.w  $12(a1),d1
                btst    #3,$69(a1)
                beq.w   .loc_136C6
                neg.w   d1

.loc_136C6:                              ; CODE XREF: sub_136B6+A↑j
                move.w  $12(a2),d2
                btst    #3,$69(a2)
                beq.w   .loc_136D6
                neg.w   d2

.loc_136D6:                              ; CODE XREF: sub_136B6+1A↑j
                sub.w   d1,d2
                beq.w   .loc_13700
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   .loc_136F4
                tst.w   d2
                bmi.w   .loc_13700
                neg.l   d0
                bra.w   .loc_136FC


.loc_136F4:                              ; CODE XREF: sub_136B6+2E↑j
                tst.w   d2
                bpl.w   .loc_13700
                neg.w   d2

.loc_136FC:                              ; CODE XREF: sub_136B6+3A↑j
                divu.w  d2,d0
                rts


.loc_13700:                              ; CODE XREF: sub_136B6+22↑j
; sub_136B6+34↑j ...
                clr.w   d0
                rts
; End of function sub_136B6


                dc.b $38 ; 8
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $BC
                dc.b $34 ; 4
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $44 ; D
                dc.b $94
                dc.b $44 ; D
                dc.b $6E ; n
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $36 ; 6
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $18
                dc.b $26 ; &
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AE
                dc.b $96
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $83
                dc.b $86
                dc.b $C2
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b $33 ; 3
                dc.b $C3
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $46 ; F
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_13746:                              ; CODE XREF: sub_10E66+17E↑p
; sub_16D9A+84↓p
                movem.l d0-d1/a0,-(sp)
                move.w  $30(a1),d0
                move.w  d0,d1
                asr.w   #6,d0
                addq.b  #3,d0
                bpl.w   .loc_13760
                move.w  #0,d0
                bra.w   .loc_1376C


.loc_13760:                              ; CODE XREF: sub_13746+E↑j
                cmp.b   #6,d0
                bmi.w   .loc_1376C
                move.w  #5,d0

.loc_1376C:                              ; CODE XREF: sub_13746+16↑j
; sub_13746+1E↑j
                move.b  d0,$72(a1)
                bsr.w   sub_13812
                move.w  $16(a1),d2
                lea     (unk_25812).l,a0
                asl.w   #2,d2
                move.w  (a0,d2.w),d2
                lsr.w   #1,d2
                move.w  d1,d0
                add.w   d4,d0
                asr.w   #6,d0
                addq.b  #3,d0
                bpl.w   .loc_1379A
                move.w  #0,d0
                bra.w   .loc_137A6


.loc_1379A:                              ; CODE XREF: sub_13746+48↑j
                cmp.b   #6,d0
                bmi.w   .loc_137A6
                move.w  #5,d0

.loc_137A6:                              ; CODE XREF: sub_13746+50↑j
; sub_13746+58↑j
                cmp.b   $72(a1),d0
                beq.w   .loc_137B2
                bsr.w   sub_13812

.loc_137B2:                              ; CODE XREF: sub_13746+64↑j
                move.w  d1,d0
                sub.w   d4,d0
                asr.w   #6,d0
                addq.b  #3,d0
                bpl.w   .loc_137C6
                move.w  #0,d0
                bra.w   .loc_137D2


.loc_137C6:                              ; CODE XREF: sub_13746+74↑j
                cmp.b   #6,d0
                bmi.w   .loc_137D2
                move.w  #5,d0

.loc_137D2:                              ; CODE XREF: sub_13746+7C↑j
; sub_13746+84↑j
                cmp.b   $72(a1),d0
                beq.w   .loc_137DE
                bsr.w   sub_13812

.loc_137DE:                              ; CODE XREF: sub_13746+90↑j
                movem.l (sp)+,d0-d1/a0
                rts
; End of function sub_13746


; =============== S U B R O U T I N E =======================================


sub_137E4:                              ; CODE XREF: sub_12868+66↑p
                movem.l d0-d1/a0,-(sp)
                clr.w   d0
                tst.w   $30(a1)
                bmi.w   .loc_137F6
                move.w  #3,d0

.loc_137F6:                              ; CODE XREF: sub_137E4+A↑j
                move.w  #2,d1
                move.b  d0,$72(a1)

.loc_137FE:                              ; CODE XREF: sub_137E4+24↓j
                move.w  d1,-(sp)
                bsr.w   sub_13812
                move.w  (sp)+,d1
                addq.w  #1,d0
                dbf     d1,.loc_137FE
                movem.l (sp)+,d0-d1/a0
                rts
; End of function sub_137E4


; =============== S U B R O U T I N E =======================================


sub_13812:                              ; CODE XREF: sub_13746+2A↑p
; sub_13746+68↑p ...
                movem.l d0-d1/a0,-(sp)
                ext.w   d0
                lea     (ram_FF178A).l,a0
                move.b  (a0,d0.w),d1
                addq.b  #1,(a0,d0.w)
                ext.w   d1
                lea     (ram_FF1792).l,a0
                asl.w   #4,d0
                adda.w  d0,a0
                move.b  $71(a1),(a0,d1.w)
                movem.l (sp)+,d0-d1/a0
                rts
; End of function sub_13812


; =============== S U B R O U T I N E =======================================


sub_1383E:
                clr.l   (ram_FF178A).l
                clr.l   (ram_FF178E).l
                rts
; End of function sub_1383E


; =============== S U B R O U T I N E =======================================


sub_1384C:
                asl.w   #1,d0
                lea     (unk_12D0A).l,a6
                move.w  (a6,d0.w),d0
                sub.w   STRUCT_OFFSET_POSY(a1),d0
                beq.w   .return
                move.w  d0,d1
                bpl.w   .loc_13868
                neg.w   d1
.loc_13868:
                mulu.w  #$280,d1
                move.w  STRUCT_OFFSET_SPEED(a1),d2
                mulu.w  d1,d2
                swap    d2
                tst.w   d2
                beq.w   .return
                ext.l   d0
                beq.w   .return
                swap    d0
                divs.w  d2,d0
                asr.w   #8,d0
                move.w  d0,STRUCT_OFFSET_46(a1)
                bset    #2,STRUCT_OFFSET_69(a1)
.return:
                rts
; End of function sub_1384C


; =============== S U B R O U T I N E =======================================


sub_13892:
                asl.w   #1,d0
                lea     (unk_12D0A).l,a6
                move.w  (a6,d0.w),d0
                sub.w   STRUCT_OFFSET_POSY(a1),d0
                ext.l   d0
                swap    d0
                move.w  STRUCT_OFFSET_SPEED(a1),d1
                lsr.w   #8,d1
                beq.w   .return
                move.w  (ram_FF1B46).l,d2
                lsr.w   #1,d2
                beq.w   .loc_138BE
                mulu.w  d2,d1
.loc_138BE:
                divs.w  d1,d0
                asr.w   #8,d0
                move.w  d0,STRUCT_OFFSET_46(a1)
                bset    #2,STRUCT_OFFSET_69(a1)
.return:
                rts
; End of function sub_13892


; =============== S U B R O U T I N E =======================================


sub_138CE:                              ; CODE XREF: Race_Update:@loc_C10C↑p
                lea     (ram_FF1EAA).l,a1
                btst    #4,$68(a1)
                bne.w   .return
                lea     (unk_2589A).l,a0

.loc_138E4:                              ; CODE XREF: sub_138CE+26↓j
; sub_138CE+B0↓j ...
                movea.l (a0)+,a2
                cmpa.w  #$FFFF,a2
                beq.w   .return
                btst    #6,$68(a2)
                bne.s   .loc_138E4
                cmpi.w  #$FFFF,$56(a2)
                bne.w   .loc_13982
                bclr    #4,$68(a2)
                bsr.w   Rand_GetWord
                andi.w  #$FFF,d0
                lea     (unk_13A1A).l,a4
                move.w  (Menu_ram_PlayerLevel).l,d1
                asl.w   #1,d1
                move.w  (a4,d1.w),d1
                mulu.w  d1,d0
                swap    d0
                move.w  d0,$56(a2)
                move.w  d0,d1
                andi.b  #1,d1
                beq.w   .loc_13936
                move.w  #2,d1

.loc_13936:                              ; CODE XREF: sub_138CE+60↑j
                move.b  d1,$73(a2)
                btst    #2,d0
                bne.w   .loc_13952
                bclr    #3,$69(a2)
                move.w  #$70,$30(a2) ; 'p'
                bra.w   .loc_1395E


.loc_13952:                              ; CODE XREF: sub_138CE+70↑j
                bset    #3,$69(a2)
                move.w  #$FF90,$30(a2)

.loc_1395E:                              ; CODE XREF: sub_138CE+80↑j
                andi.w  #$F0,d0
                lsr.w   #4,d0
                move.b  d0,$74(a2)
                ext.w   d0
                lea     (unk_25A44).l,a3
                asl.w   #3,d0
                move.w  4(a3,d0.w),$12(a2)
                move.w  6(a3,d0.w),$46(a2)
                bra.w   .loc_138E4


.loc_13982:                              ; CODE XREF: sub_138CE+2E↑j
                cmpi.l  #$708,(ram_FF1E9A).l
                bcs.w   .loc_138E4
                move.w  (Race_ram_FrameDelay).l,d2
                sub.w   d2,$56(a2)
                bgt.w   .loc_138E4
                move.w  #$FFFF,$56(a2)
                bsr.w   sub_13A26
                bra.w   .loc_138E4

                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $44 ; D
                dc.b $40 ; @
                dc.b $B0
                dc.b $7C ; |
                dc.b   0
                dc.b $21 ; !
                dc.b $6B ; k
                dc.b   0
                dc.b $FF
                dc.b $2E ; .
                dc.b  $C
                dc.b $6A ; j
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b $56 ; V
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $2E ; .
                dc.b   8
                dc.b $AA
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $68 ; h
                dc.b $61 ; a
                dc.b   0
                dc.b $26 ; &
                dc.b $6A ; j
                dc.b   2
                dc.b $40 ; @
                dc.b  $F
                dc.b $FF
                dc.b $49 ; I
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $3A ; :
                dc.b $1A
                dc.b $32 ; 2
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b   5
                dc.b  $A
                dc.b $E3
                dc.b $41 ; A
                dc.b $32 ; 2
                dc.b $34 ; 4
                dc.b $10
                dc.b   0
                dc.b $C0
                dc.b $C1
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b $56 ; V
                dc.b $60 ; `
                dc.b   0
                dc.b $FE
                dc.b $F8
                dc.b  $C
                dc.b $B9
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   8
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $9A
                dc.b $65 ; e
                dc.b   0
                dc.b $FE
                dc.b $EA
                dc.b $34 ; 4
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $30 ; 0
                dc.b $4A ; J
                dc.b $95
                dc.b $6A ; j
                dc.b   0
                dc.b $56 ; V
                dc.b $6E ; n
                dc.b   0
                dc.b $FE
                dc.b $DC
                dc.b $35 ; 5
                dc.b $7C ; |
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b $56 ; V
                dc.b $61 ; a
                dc.b   0
                dc.b   0
                dc.b $4A ; J
                dc.b $60 ; `
                dc.b   0
                dc.b $FE
                dc.b $CE


.return:                           ; CODE XREF: sub_138CE+C↑j
; sub_138CE+1C↑j
                rts
; End of function sub_138CE


unk_13A1A:      dc.b $FF                ; DATA XREF: sub_138CE+40↑o
                dc.b $FF
                dc.b $B3
                dc.b $33 ; 3
                dc.b $80
                dc.b   0
                dc.b $4C ; L
                dc.b $CC
                dc.b $33 ; 3
                dc.b $33 ; 3
                dc.b $22 ; "
                dc.b $22 ; "

; =============== S U B R O U T I N E =======================================


sub_13A26:                              ; CODE XREF: sub_138CE+D6↑p
                bclr    #0,$68(a2)
                move.w  #0,d0
                move.w  d0,2(a2)
                move.w  d0,$3C(a2)
                move.w  d0,$3A(a2)
                move.w  d0,$32(a2)
                move.l  (ram_FF1E68).l,d0
                addi.l  #$208000,d0
                move.l  d0,4(a2)
                move.l  d0,$1E(a2)
                bset    #6,$68(a2)
                rts
; End of function sub_13A26


                dc.b   8
                dc.b $AA
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $68 ; h
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b   2
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b $3C ; <
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b $3A ; :
                dc.b $35 ; 5
                dc.b $40 ; @
                dc.b   0
                dc.b $32 ; 2
                dc.b $20
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $68 ; h
                dc.b   4
                dc.b $80
                dc.b   0
                dc.b $1F
                dc.b $80
                dc.b   0
                dc.b $25 ; %
                dc.b $40 ; @
                dc.b   0
                dc.b   4
                dc.b $25 ; %
                dc.b $40 ; @
                dc.b   0
                dc.b $1E
                dc.b   8
                dc.b $EA
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u

; *************************************************
; Function sub_13A92
; a1 - actor
; *************************************************

sub_13A92:
                btst    #7,STRUCT_OFFSET_68(a1)
                beq.w   .loc_13AA6
                move.w  #$FFEC,STRUCT_OFFSET_14(a1)
                bra.w   .locret_13BBA
.loc_13AA6:
                btst    #4,STRUCT_OFFSET_68(a1)
                beq.w   .loc_13AC2
                cmpi.b  #3,STRUCT_OFFSET_6E(a1)
                beq.w   .locret_13BBA
                bsr.w   sub_13BBC
                bra.w   .locret_13BBA
.loc_13AC2:
                clr.w   d1
                move.w  STRUCT_OFFSET_16(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a0
                movea.l (a0,d0.w),a0
                move.w  STRUCT_OFFSET_SPEED(a1),d0
                btst    #0,STRUCT_OFFSET_68(a1)
                bne.w   .loc_13B68
                btst    #4,STRUCT_OFFSET_68(a1)
                bne.w   .loc_13B3A
                btst    #1,STRUCT_OFFSET_68(a1)
                beq.w   .loc_13B30
                move.w  STRUCT_OFFSET_GEAR(a1),d1
                move.w  d1,d2
                asl.w   #1,d2
                move.w  $E(a0,d2.w),d3
                cmp.w   d3,d0
                bcs.w   .loc_13B1A
                cmp.w   0.w(a0),d1
                bpl.w   .loc_13B68
                addq.w  #1,d1
                move.w  d1,STRUCT_OFFSET_GEAR(a1)
                move.w  d1,d2
                asl.w   #1,d2
.loc_13B1A:
                cmp.w   $1A(a0,d2.w),d0
                bcc.w   .loc_13B2C
                subq.w  #1,d1
                move.w  d1,STRUCT_OFFSET_GEAR(a1)
                move.w  d1,d2
                asl.w   #1,d2
.loc_13B2C:
                move.w  2(a0,d2.w),d1
.loc_13B30:
                btst    #2,STRUCT_OFFSET_68(a1)
                beq.w   .loc_13B3E
.loc_13B3A: 
                addi.w  #-$40,d1
.loc_13B3E:
                btst    #1,STRUCT_OFFSET_68(a1)
                bne.w   .loc_13B4C
                addi.w  #-5,d1
.loc_13B4C:
                btst    #5,STRUCT_OFFSET_68(a1)
                beq.w   .loc_13B6C
                move.w  STRUCT_OFFSET_3E(a1),d0
                neg.w   d0
                mulu.w  #$60,d0
                swap    d0
                sub.w   d0,d1
                bra.w   .loc_13B6C
.loc_13B68:
                move.w  #$FFFB,d1
.loc_13B6C:
                btst    #3,STRUCT_OFFSET_68(a1)
                beq.w   .loc_13B84
                tst.w   d1
                bmi.w   .loc_13B8A
                move.w  STRUCT_OFFSET_SPEED(a1),d2
                lsr.w   #8,d2
                sub.w   d2,d1
.loc_13B84:
                tst.w   d1
                bpl.w   .loc_13BB6
.loc_13B8A:
                move.w  STRUCT_OFFSET_16(a1),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a0
                movea.l (a0,d0.w),a0
                move.w  STRUCT_OFFSET_SPEED(a1),d0
                move.w  STRUCT_OFFSET_GEAR(a1),d2
                beq.w   .loc_13BB6
                asl.w   #1,d2
                cmp.w   $1A(a0,d2.w),d0
                bcc.w   .loc_13BB6
                subi.w  #1,STRUCT_OFFSET_GEAR(a1)
.loc_13BB6:
                move.w  d1,STRUCT_OFFSET_14(a1)
.locret_13BBA:
                rts
; End of function sub_13A92

; *************************************************
; Function sub_13BBC
; a1 - actor
; *************************************************

sub_13BBC:
                btst    #0,STRUCT_OFFSET_68(a1)
                bne.w   .loc_13BCE
                move.w  #-64,d1
                bra.w   .loc_13BD2
.loc_13BCE:
                move.w  #-5,d1
.loc_13BD2:
                move.w  d1,STRUCT_OFFSET_14(a1)
                rts
; End of function sub_13BBC


; =============== S U B R O U T I N E =======================================


sub_13BD8:                              ; CODE XREF: sub_1180C+24↑p
                btst    #0,$68(a1)
                bne.w   .loc_13BEA
                move.w  #$FFD0,d1
                bra.w   .loc_13BEE


.loc_13BEA:                              ; CODE XREF: sub_13BD8+6↑j
                move.w  #$FFFB,d1

.loc_13BEE:                              ; CODE XREF: sub_13BD8+E↑j
                move.w  d1,$14(a1)
                rts
; End of function sub_13BD8


; =============== S U B R O U T I N E =======================================


sub_13BF4:                              ; CODE XREF: Race_Update+BA↑p
                lea     (ram_FF1F2A).l,a1
                move.w  (ram_FF1B32).l,d0
                beq.w   .loc_13C1C
                sub.w   (Race_ram_FrameDelay).l,d0
                move.w  d0,(ram_FF1B32).l
                bgt.w   .loc_13C88
                move.w  #0,(ram_FF1B32).l

.loc_13C1C:                              ; CODE XREF: sub_13BF4+C↑j
                btst    #6,$68(a1)
                bne.w   .locret_13CFC
                move.w  STRUCT_OFFSET_66(a1),d0
                move.w  (ram_FF1E9C).l,d1
                sub.w   (ram_FF1B34).l,d1
                bmi.w   .loc_13C88
                mulu.w  d1,d0
                move.l  d0,(ram_FF1B3A).l
                move.l  (ram_FF1E68).l,d1
                subi.l  #$100000,d1
                bpl.w   .loc_13C54
                moveq   #0,d1

.loc_13C54:                              ; CODE XREF: sub_13BF4+5A↑j
                cmp.l   d1,d0
                bmi.w   .loc_13C88
                tst.w   (ram_FF1B36).l
                bne.w   .loc_13C88
                move.w  #1,(ram_FF1B36).l
                move.l  d1,4(a1)
                move.w  #$1F40,$12(a1)
                move.w  (Menu_ram_PlayerLevel).l,(ram_FF1B38).l
                bsr.w   sub_13CFE
                bra.w   .locret_13CFC


.loc_13C88:                              ; CODE XREF: sub_13BF4+1C↑j
; sub_13BF4+42↑j ...
                movea.l (ram_FFDBD4).l,a2
                move.l  (a2),d0
                cmp.l   #$FFFFFFFF,d0
                beq.w   .locret_13CFC
                move.l  d0,d1
                clr.w   d0
                sub.l   (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                cmp.l   #$200000,d0
                bpl.w   .locret_13CFC
                addi.l  #4,(ram_FFDBD4).l
                btst    #6,$68(a1)
                bne.w   .locret_13CFC
                move.w  d1,d2
                lsr.w   #8,d2
                move.w  d2,(ram_FF1B38).l
                move.l  d1,d0
                clr.w   d0
                move.l  d0,4(a1)
                andi.w  #$F,d1
                asl.w   #5,d1
                subi.w  #$100,d1
                move.w  d1,$30(a1)
                move.w  (ram_FF1EAA + STRUCT_OFFSET_SPEED).l,d0
                cmp.w   #$2710,d0
                bmi.w   .loc_13CF4
                move.w  #$2710,d0

.loc_13CF4:                              ; CODE XREF: sub_13BF4+F8↑j
                move.w  d0,$12(a1)
                bsr.w   sub_13CFE

.locret_13CFC:                           ; CODE XREF: sub_13BF4+2E↑j
; sub_13BF4+90↑j ...
                rts
; End of function sub_13BF4


; =============== S U B R O U T I N E =======================================


sub_13CFE:                              ; CODE XREF: sub_13BF4+8C↑p
; sub_13BF4+104↑p
                bsr.w   sub_16D0A
                bsr.w   sub_16D9A
                bsr.w   sub_13FE6
                cmp.w   $12(a1),d0
                bpl.w   .loc_13D16
                move.w  d0,$12(a1)

.loc_13D16:                              ; CODE XREF: sub_13CFE+10↑j
                move.w  (ram_FF1B38).l,d0
                addq.w  #4,d0
                move.b  d0,$75(a1)
                lea     (unk_CCD0).l,a2
                subq.w  #5,d0
                asl.w   #1,d0
                move.w  (a2,d0.w),d0
                lea     (unk_CCDA).l,a2
                asl.w   #4,d0
                move.b  (a2,d0.w),d0
                ext.w   d0
                move.w  d0,$16(a1)
                rts
; End of function sub_13CFE


                dc.b $48 ; H
                dc.b $E7
                dc.b $E0
                dc.b $E0
                dc.b $20
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $D7
                dc.b $CC
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A4
                dc.b $22 ; "
                dc.b $10
                dc.b $B2
                dc.b $BC
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $7A ; z
                dc.b $42 ; B
                dc.b $41 ; A
                dc.b $24 ; $
                dc.b   1
                dc.b $94
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b $6E ; n
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $58 ; X
                dc.b $88
                dc.b $B4
                dc.b $BC
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b   0
                dc.b $64 ; d
                dc.b   0
                dc.b   0
                dc.b $62 ; b
                dc.b $42 ; B
                dc.b $40 ; @
                dc.b $10
                dc.b $28 ; (
                dc.b   0
                dc.b   2
                dc.b $45 ; E
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $47 ; G
                dc.b $64 ; d
                dc.b $E7
                dc.b $40 ; @
                dc.b $D4
                dc.b $C0
                dc.b $4A ; J
                dc.b $6A ; j
                dc.b   0
                dc.b   6
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $1A
                dc.b $32 ; 2
                dc.b $28 ; (
                dc.b   0
                dc.b   2
                dc.b   2
                dc.b $41 ; A
                dc.b   0
                dc.b  $F
                dc.b $EB
                dc.b $41 ; A
                dc.b   4
                dc.b $41 ; A
                dc.b   1
                dc.b   0
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $30 ; 0
                dc.b $B1
                dc.b $41 ; A
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $58 ; X
                dc.b $48 ; H
                dc.b $60 ; `
                dc.b $A8
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $26 ; &
                dc.b $84
                dc.b $C0
                dc.b $33 ; 3
                dc.b $C2
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $46 ; F
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b   0
                dc.b   2
                dc.b $4A ; J
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $54 ; T
                dc.b $40 ; @
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $38 ; 8
                dc.b $92
                dc.b $33 ; 3
                dc.b $FC
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A4
                dc.b $4C ; L
                dc.b $DF
                dc.b   7
                dc.b   7
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_13DE0:                              ; CODE XREF: sub_12868+6E↑p
                movem.l d0-d2/a0-a2,-(sp)
                movea.l (ram_FFD7CC).l,a0
                move.w  #0,(ram_FF18A4).l

.loc_13DF2:                              ; CODE XREF: sub_13DE0+7C↓j
                move.l  (a0),d1
                cmp.l   #$FFFFFFFF,d1
                beq.w   .loc_13E8E
                clr.w   d1
                move.l  d1,d2
                sub.l   4(a1),d2
                btst    #3,$69(a1)
                beq.w   .loc_13E12
                neg.l   d2

.loc_13E12:                              ; CODE XREF: sub_13DE0+2C↑j
                tst.l   d2
                bgt.w   .loc_13E1A
                addq.l  #4,a0

.loc_13E1A:                              ; CODE XREF: sub_13DE0+34↑j
                cmp.l   #$1E0000,d2
                bcc.w   .loc_13E8E
                subi.l  #$10000,d2
                clr.w   d0
                move.b  2(a0),d0
                lea     (unk_14764).l,a2
                asl.w   #3,d0
                adda.w  d0,a2
                tst.w   6(a2)
                beq.w   .loc_13E5A
                move.w  2(a0),d1
                andi.w  #$F,d1
                asl.w   #5,d1
                subi.w  #$100,d1
                move.w  $30(a1),d0
                eor.w   d0,d1
                bpl.w   .loc_13E5E

.loc_13E5A:                              ; CODE XREF: sub_13DE0+5E↑j
                addq.w  #4,a0
                bra.s   .loc_13DF2


.loc_13E5E:                              ; CODE XREF: sub_13DE0+76↑j
                clr.l   d0
                move.w  $12(a1),d0
                beq.w   .loc_13E8E
                tst.w   d2
                bmi.w   .loc_13E88
                divu.w  d0,d2
                bvs.w   .loc_13E8E
                beq.w   .loc_13E88
                divu.w  d2,d0
                mulu.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,$12(a1)
                bra.w   .loc_13E8E


.loc_13E88:                              ; CODE XREF: sub_13DE0+8A↑j
; sub_13DE0+94↑j
                move.w  #0,$12(a1)

.loc_13E8E:                              ; CODE XREF: sub_13DE0+1A↑j
; sub_13DE0+40↑j ...
                movem.l (sp)+,d0-d2/a0-a2
                rts
; End of function sub_13DE0


; =============== S U B R O U T I N E =======================================


sub_13E94:                              ; CODE XREF: Race_Update+A8↑p
                lea     (ram_FF1EAA).l,a1
                bsr.w   sub_13FE6
                rts
; End of function sub_13E94

; *************************************************
; Function sub_13EA0
; a1 - actor
; *************************************************
sub_13EA0:
                tst.b   STRUCT_OFFSET_6E(a1)
                bpl.w   .return
                move.w  STRUCT_OFFSET_SPEED(a1),d2
                beq.w   .loc_13EF2
                mulu.w  (ram_FF1AB4).l,d2
                lsr.l   #8,d2
                move.w  (ram_FF1AA6).l,d1
                lsr.w   #3,d1
                move.w  (RaceBike_ram_CurrentSteering).l,d3
                move.w  d3,d0
                bpl.w   .loc_13ECE
                neg.w   d0
.loc_13ECE:
                ext.l   d0
                divu.w  d1,d0
                beq.w   .loc_13EF2
                swap    d0
                divu.w  d2,d0
                mulu.w  (ram_FF1AAA).l,d0
                swap    d0
                tst.w   d3
                bpl.w   .loc_13EEA
                neg.w   d0
.loc_13EEA:
                move.w  d0,STRUCT_OFFSET_42(a1)
                bra.w   .return
.loc_13EF2:
                move.w  #0,STRUCT_OFFSET_42(a1)
.return:
                rts
; End of function sub_13EA0


; =============== S U B R O U T I N E =======================================


sub_13EFA:                              ; CODE XREF: sub_10E66+96↑p
; sub_10E66+FE↑p
                movem.l d0-d1,-(sp)
                btst    #0,$68(a1)
                bne.w   .loc_13FE0
                move.w  $12(a1),d1
                beq.w   .loc_13FCE
                mulu.w  (ram_FF1AB2).l,d1
                lsr.l   #8,d1
                move.w  8(a1),d0
                beq.w   .loc_13FCE
                bpl.w   .loc_13F26
                neg.w   d0

.loc_13F26:                              ; CODE XREF: sub_13EFA+26↑j
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_13F3A
                cmpa.l  #ram_FF1EAA,a1
                beq.w   .loc_13F40

.loc_13F3A:                              ; CODE XREF: sub_13EFA+32↑j
                mulu.w  #$200,d0
                lsr.l   #8,d0

.loc_13F40:                              ; CODE XREF: sub_13EFA+3C↑j
                mulu.w  d1,d0
                lsr.l   #3,d0
                clr.l   d1
                move.b  $78(a1),d2
                beq.w   .loc_13F6E
                andi.w  #$FF,d2
                sub.w   (Race_ram_FrameDelay).l,d2
                bcc.w   .loc_13F60
                move.w  #0,d2

.loc_13F60:                              ; CODE XREF: sub_13EFA+5E↑j
                move.b  d2,$78(a1)
                move.w  (word_14742).l,d1
                bra.w   .loc_13FB0


.loc_13F6E:                              ; CODE XREF: sub_13EFA+50↑j
                btst    #5,$68(a1)
                beq.w   .loc_13F96
                btst    #3,$68(a1)
                beq.w   .loc_13F8C
                move.w  (ram_FF3034).l,d1
                bra.w   .loc_13FB0


.loc_13F8C:                              ; CODE XREF: sub_13EFA+84↑j
                move.w  (ram_FF302E).l,d1
                bra.w   .loc_13FB0


.loc_13F96:                              ; CODE XREF: sub_13EFA+7A↑j
                btst    #3,$68(a1)
                beq.w   .loc_13FAA
                move.w  (ram_FF3032).l,d1
                bra.w   .loc_13FB0


.loc_13FAA:                              ; CODE XREF: sub_13EFA+A2↑j
                move.w  (ram_FF302E).l,d1

.loc_13FB0:                              ; CODE XREF: sub_13EFA+70↑j
; sub_13EFA+8E↑j ...
                cmp.l   d1,d0
                bcs.w   .loc_13FCE
                lsr.l   #8,d0
                beq.w   .loc_13FC0
                asl.l   #8,d1
                divu.w  d0,d1

.loc_13FC0:                              ; CODE XREF: sub_13EFA+BE↑j
                move.w  d1,$3E(a1)
                bset    #5,$68(a1)
                bra.w   .loc_13FE0


.loc_13FCE:                              ; CODE XREF: sub_13EFA+12↑j
; sub_13EFA+22↑j ...
                bclr    #5,$68(a1)
                move.w  #0,$40(a1)
                move.w  #0,$3E(a1)

.loc_13FE0:                              ; CODE XREF: sub_13EFA+A↑j
; sub_13EFA+D0↑j
                movem.l (sp)+,d0-d1
                rts
; End of function sub_13EFA


; =============== S U B R O U T I N E =======================================


sub_13FE6:                              ; CODE XREF: sub_131BE+B6↑p
; sub_13292+8C↑p ...
                movem.l d1-d2/a0-a2,-(sp)
                clr.l   d0
                btst    #3,$68(a1)
                beq.w   .loc_14000
                move.w  (ram_FF3032).l,d0
                bra.w   .loc_14006


.loc_14000:                              ; CODE XREF: sub_13FE6+C↑j
                move.w  (ram_FF302E).l,d0

.loc_14006:                              ; CODE XREF: sub_13FE6+16↑j
                asl.l   #3,d0
                lea     (ram_FFDC58).l,a0
                move.w  4(a1),d1
                addq.w  #6,d1
                andi.w  #$FF,d1
                asl.w   #1,d1
                move.w  (a0,d1.w),d1
                ext.w   d1
                bpl.w   .loc_14026
                neg.w   d1

.loc_14026:                              ; CODE XREF: sub_13FE6+3A↑j
                tst.w   d1
                beq.w   .loc_1404C
                lea     (unk_14056).l,a2
                move.b  $75(a1),d2
                ext.w   d2
                asl.w   #1,d2
                move.w  (a2,d2.w),d2
                mulu.w  d2,d1
                lsr.l   #8,d1
                divu.w  d1,d0
                bvs.w   .loc_1404C
                bpl.w   .loc_14050

.loc_1404C:                              ; CODE XREF: sub_13FE6+42↑j
; sub_13FE6+5E↑j
                move.w  #$7FFF,d0

.loc_14050:                              ; CODE XREF: sub_13FE6+62↑j
                movem.l (sp)+,d1-d2/a0-a2
                rts
; End of function sub_13FE6


unk_14056:      dc.b   1                ; DATA XREF: sub_13FE6+46↑o
                dc.b $38 ; 8
                dc.b   1
                dc.b $30 ; 0
                dc.b   1
                dc.b $28 ; (
                dc.b   1
                dc.b $20
                dc.b   1
                dc.b $10
                dc.b   1
                dc.b $60 ; `
                dc.b   1
                dc.b $50 ; P
                dc.b   1
                dc.b $40 ; @
                dc.b   1
                dc.b $30 ; 0
                dc.b   1
                dc.b $20

; =============== S U B R O U T I N E =======================================


sub_1406A:                              ; CODE XREF: sub_113A4+18↑p
; sub_113CA+56↑p
                move.w  d0,d1
                move.w  $3E(a1),d3
                beq.w   .locret_140BA
                ext.l   d1
                bpl.w   .loc_14086
                neg.w   d1
                mulu.w  d3,d1
                swap    d1
                neg.w   d1
                bra.w   .loc_1408A


.loc_14086:                              ; CODE XREF: sub_1406A+C↑j
                mulu.w  d3,d1
                swap    d1

.loc_1408A:                              ; CODE XREF: sub_1406A+18↑j
                move.w  d1,(ram_FF3042).l
                move.l  #$10000,d2
                divu.w  d3,d2
                subq.w  #1,d2
                muls.w  d0,d2
                bpl.w   .loc_140AE
                neg.w   d2
                mulu.w  #$140,d2
                lsr.l   #8,d2
                neg.w   d2
                bra.w   .loc_140B4


.loc_140AE:                              ; CODE XREF: sub_1406A+32↑j
                mulu.w  #$140,d2
                lsr.l   #8,d2

.loc_140B4:                              ; CODE XREF: sub_1406A+40↑j
                move.w  d2,$40(a1)
                move.w  d1,d0

.locret_140BA:                           ; CODE XREF: sub_1406A+6↑j
                rts
; End of function sub_1406A


                dc.b $42 ; B
                dc.b $80
                dc.b $30 ; 0
                dc.b $28 ; (
                dc.b   0
                dc.b  $E
                dc.b $E1
                dc.b $80
                dc.b $D0
                dc.b $B9
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $68 ; h
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   4
                dc.b $80
                dc.b   0
                dc.b   0
                dc.b $A0
                dc.b   0
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   6
                dc.b $80
                dc.b   0
                dc.b   0
                dc.b $40 ; @
                dc.b   0
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b   4
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b $1E
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b  $C
                dc.b $69 ; i
                dc.b  $F
                dc.b $A0
                dc.b   0
                dc.b $12
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $61 ; a
                dc.b   0
                dc.b   2
                dc.b   4
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $A8
                dc.b $61 ; a
                dc.b $BA
                dc.b $61 ; a
                dc.b   0
                dc.b   2
                dc.b $8A
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $34 ; 4
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $40 ; @
                dc.b $B0
                dc.b $7C ; |
                dc.b   0
                dc.b   3
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $38 ; 8
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $24 ; $
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $33 ; 3
                dc.b $C0
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $B0
                dc.b $7C ; |
                dc.b $17
                dc.b $70 ; p
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $80
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $5C ; 
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $6E ; n
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $6F ; o
                dc.b $4A ; J
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $17
                dc.b $68 ; h
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $3C ; <
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $D8
                dc.b $61 ; a
                dc.b   0
                dc.b $D7
                dc.b $A4
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b $C0
                dc.b   0
                dc.b $61 ; a
                dc.b   0
                dc.b   2
                dc.b   4
                dc.b $B3
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AA
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $32 ; 2
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $30 ; 0
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $61 ; a
                dc.b   0
                dc.b   1
                dc.b $C4
                dc.b $E2
                dc.b $48 ; H
                dc.b $D1
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $26 ; &
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $14
                dc.b $B3
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AA
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b $B0
                dc.b $7C ; |
                dc.b  $F
                dc.b $A0
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $61 ; a
                dc.b   0
                dc.b   1
                dc.b $38 ; 8
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $E4
                dc.b $33 ; 3
                dc.b $C0
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $C0
                dc.b $FC
                dc.b $40 ; @
                dc.b   0
                dc.b $48 ; H
                dc.b $40 ; @
                dc.b $B0
                dc.b $7C ; |
                dc.b $27 ; '
                dc.b $10
                dc.b $6D ; m
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b $27 ; '
                dc.b $10
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $12
                dc.b $20
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $60 ; `
                dc.b   0
                dc.b $92
                dc.b $68 ; h
                dc.b   0
                dc.b  $E
                dc.b $48 ; H
                dc.b $C1
                dc.b $E1
                dc.b $81
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $80
                dc.b $D0
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b $90
                dc.b $81
                dc.b $23 ; #
                dc.b $40 ; @
                dc.b   0
                dc.b   4
                dc.b $61 ; a
                dc.b   0
                dc.b   1
                dc.b $86
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $68 ; h
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $69 ; i
                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $34 ; 4
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $40 ; @
                dc.b $B0
                dc.b $7C ; |
                dc.b   0
                dc.b   3
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $38 ; 8
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b  $C
                dc.b $79 ; y
                dc.b $1F
                dc.b $40 ; @
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $6B ; k
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b $54 ; T
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $54 ; T
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $6E ; n
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $6F ; o
                dc.b $4A ; J
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $17
                dc.b $68 ; h
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $3A ; :
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $D8
                dc.b $61 ; a
                dc.b   0
                dc.b $D6
                dc.b $9A
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b $C0
                dc.b   0
                dc.b $61 ; a
                dc.b   0
                dc.b   0
                dc.b $FA
                dc.b $B3
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AA
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $30 ; 0
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $30 ; 0
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $18
                dc.b $A6
                dc.b $61 ; a
                dc.b   0
                dc.b   0
                dc.b $BA
                dc.b $D1
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $26 ; &
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $14
                dc.b $B3
                dc.b $FC
                dc.b   0
                dc.b $FF
                dc.b $1E
                dc.b $AA
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b $61 ; a
                dc.b   0
                dc.b $FE
                dc.b $3C ; <
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b $61 ; a
                dc.b   0
                dc.b $FE
                dc.b $2E ; .
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b $17
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $6B ; k
                dc.b $4E ; N
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $40 ; @
                dc.b $EE

; =============== S U B R O U T I N E =======================================


sub_142D8:                              ; CODE XREF: sub_14486+5A↓p
                bclr    #7,$6A(a1)
                move.w  d0,-(sp)
                move.w  (ram_FF18A6).l,d0
                bpl.w   .loc_142EC
                neg.w   d0

.loc_142EC:                              ; CODE XREF: sub_142D8+E↑j
                cmp.w   #$1770,d0
                bcs.w   .loc_142FA
                bset    #7,$6A(a1)

.loc_142FA:                              ; CODE XREF: sub_142D8+18↑j
                move.w  (sp)+,d0
                rts
; End of function sub_142D8


                dc.b $30 ; 0
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $1B
                dc.b $14
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b $69 ; i
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $90
                dc.b $69 ; i
                dc.b   0
                dc.b $4E ; N
                dc.b $59 ; Y
                dc.b $40 ; @
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b $D0
                dc.b $69 ; i
                dc.b   0
                dc.b $4C ; L
                dc.b $58 ; X
                dc.b $40 ; @
                dc.b $32 ; 2
                dc.b   0
                dc.b $92
                dc.b $69 ; i
                dc.b   0
                dc.b $30 ; 0
                dc.b $D3
                dc.b $69 ; i
                dc.b   0
                dc.b   0
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $30 ; 0
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $1A
                dc.b $4A ; J
                dc.b $A9
                dc.b   0
                dc.b $26 ; &
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $12
                dc.b   4
                dc.b $A9
                dc.b   0
                dc.b   0
                dc.b $40 ; @
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   4
                dc.b $A9
                dc.b   0
                dc.b   0
                dc.b $40 ; @
                dc.b   0
                dc.b   0
                dc.b $1E
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_1434A:                              ; CODE XREF: sub_11B7A+BA↑p
; sub_14486+26↓p ...
                tst.w   (ram_FF1768).l
                beq.w   .loc_1435A
                clr.w   d0
                bra.w   .locret_1436C


.loc_1435A:                              ; CODE XREF: sub_1434A+6↑j
                tst.w   d0
                bpl.w   .loc_14362
                neg.w   d0

.loc_14362:                              ; CODE XREF: sub_1434A+12↑j
                lsr.w   #8,d0
                lsr.w   #3,d0
                move.w  d0,(ram_FF1B28).l

.locret_1436C:                           ; CODE XREF: sub_1434A+C↑j
                rts
; End of function sub_1434A


                dc.b $49 ; I
                dc.b $F9
                dc.b   0
                dc.b   2
                dc.b $58 ; X
                dc.b $AE
                dc.b $14
                dc.b $29 ; )
                dc.b   0
                dc.b $71 ; q
                dc.b $48 ; H
                dc.b $82
                dc.b $E5
                dc.b $42 ; B
                dc.b $28 ; (
                dc.b $74 ; t
                dc.b $20
                dc.b   0
                dc.b $34 ; 4
                dc.b $2C ; ,
                dc.b   0
                dc.b $12
                dc.b $C4
                dc.b $C0
                dc.b $48 ; H
                dc.b $42 ; B
                dc.b $39 ; 9
                dc.b $42 ; B
                dc.b   0
                dc.b $12
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_1438E:                              ; CODE XREF: sub_11CC8+F2↑p
; sub_11CC8+10A↑p ...
                move.w  $12(a1),d0
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_143D4
                cmp.w   #$3E8,d0
                bmi.w   .loc_143D4
                tst.w   (ram_FF1768).l
                bne.w   .loc_143BA
                move.b  #6,(ram_FF1AD6).l
                bra.w   .loc_143D4


.loc_143BA:                              ; CODE XREF: sub_1438E+1C↑j
                move.b  #1,$6E(a1)
                move.b  #0,$6F(a1)
                move.b  #$FF,$70(a1)
                move.b  #$F,(ram_FF1AD6).l

.loc_143D4:                              ; CODE XREF: sub_1438E+A↑j
; sub_1438E+12↑j ...
                lsr.w   #8,d0
                lsr.w   #3,d0
                beq.w   .locret_14402
                btst    #0,$68(a1)
                bne.w   .locret_14402
                move.w  d0,$2C(a1)
                move.w  #0,$2E(a1)
                move.w  2(a1),d0
                addi.w  #$30,d0 ; '0'
                move.w  d0,$2A(a1)
                bset    #0,$68(a1)

.locret_14402:                           ; CODE XREF: sub_1438E+4A↑j
; sub_1438E+54↑j
                rts
; End of function sub_1438E


                dc.b $61 ; a
                dc.b $88
                dc.b $4A ; J
                dc.b $79 ; y
                dc.b   0
                dc.b $FF
                dc.b $17
                dc.b $68 ; h
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $6E ; n
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b $36 ; 6
                dc.b  $C
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $6E ; n
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $2C ; ,
                dc.b $33 ; 3
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $54 ; T
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $6E ; n
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $6F ; o
                dc.b $13
                dc.b $FC
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b $FF
                dc.b $1A
                dc.b $D6
                dc.b $4A ; J
                dc.b $69 ; i
                dc.b   0
                dc.b $12
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b $61 ; a
                dc.b   0
                dc.b $FC
                dc.b $74 ; t
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   8
                dc.b $A9
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b $68 ; h
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b  $C
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $6E ; n
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $68 ; h
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $78 ; x
                dc.b   0
                dc.b $78 ; x
                dc.b $4E ; N
                dc.b $75 ; u
                dc.b  $C
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $6E ; n
                dc.b $6A ; j
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   8
                dc.b $E9
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b $68 ; h
                dc.b $13
                dc.b $7C ; |
                dc.b   0
                dc.b $1E
                dc.b   0
                dc.b $78 ; x
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_14486:                              ; CODE XREF: sub_11CC8+204↑p
; sub_11CC8+264↑p ...
                move.w  $1C(a1),d0
                cmp.w   (ram_FF303E).l,d0
                bpl.w   .loc_14594
                move.w  #$1000,d1
                bsr.w   sub_145EC
                move.w  d0,(ram_FF18A6).l
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_144D4
                jsr     (sub_1434A).l
                add.w   d0,(Race_ram_BikeDamage).l
                lsr.w   #1,d0
                cmp.w   #2,d0
                ble.w   .loc_144CA
                move.w  #$16,d0
                bra.w   .loc_144CE


.loc_144CA:                              ; CODE XREF: sub_14486+38↑j
                addi.w  #9,d0

.loc_144CE:                              ; CODE XREF: sub_14486+40↑j
                move.b  d0,(ram_FF1AD6).l

.loc_144D4:                              ; CODE XREF: sub_14486+22↑j
                move.b  $69(a2),d0
                andi.b  #8,d0
                or.b    d0,$69(a1)
                jsr     (sub_142D8).l
                move.w  $12(a2),d1
                move.w  (ram_FF18A6).l,d0
                bne.w   .loc_144F8
                move.w  #$400,d0

.loc_144F8:                              ; CODE XREF: sub_14486+6A↑j
                btst    #3,$69(a1)
                bne.w   .loc_1451C
                asr.w   #1,d0
                add.w   d0,d1
                asr.w   #1,d0
                sub.w   d0,d1
                beq.w   .loc_14530
                btst    #0,$68(a1)
                bne.w   .loc_14538
                bra.w   .loc_14530


.loc_1451C:                              ; CODE XREF: sub_14486+78↑j
                move.w  $12(a2),d1
                lsr.w   #1,d1
                beq.w   .loc_14530
                btst    #0,$68(a1)
                bne.w   .loc_14538

.loc_14530:                              ; CODE XREF: sub_14486+84↑j
; sub_14486+92↑j ...
                move.w  d1,$12(a1)
                bsr.w   sub_14688

.loc_14538:                              ; CODE XREF: sub_14486+8E↑j
; sub_14486+A6↑j
                move.w  8(a1),d0
                sub.w   8(a2),d0
                sub.w   d0,8(a1)
                move.w  8(a1),$C(a1)
                tst.b   $6E(a1)
                bmi.w   .locret_145EA
                move.w  $30(a1),d0
                sub.w   $30(a2),d0
                asl.w   #2,d0
                move.w  d0,8(a1)
                move.w  d0,$C(a1)
                move.w  (ram_FF18A6).l,d0
                bpl.w   .loc_14570
                neg.w   d0

.loc_14570:                              ; CODE XREF: sub_14486+E4↑j
                lsr.w   #8,d0
                lsr.w   #3,d0
                move.w  d0,$2C(a1)
                move.w  #0,$2E(a1)
                move.w  2(a1),d0
                addi.w  #$30,d0 ; '0'
                move.w  d0,$2A(a1)
                bset    #0,$68(a1)
                bra.w   .locret_145EA


.loc_14594:                              ; CODE XREF: sub_14486+A↑j
                move.w  $12(a1),d0
                lsr.w   #8,d0
                lsr.w   #3,d0
                move.w  d0,$2C(a1)
                move.w  #0,$2E(a1)
                move.w  2(a1),d0
                add.w   (ram_FF303E).l,d0
                move.w  d0,$2A(a1)
                move.w  (ram_FF3040).l,$32(a1)
                bclr    #4,$68(a1)
                bset    #0,$68(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .locret_145EA
                move.b  #9,(ram_FF1AD6).l
                tst.b   $6E(a1)
                bmi.w   .locret_145EA
                move.b  #$16,(ram_FF1AD6).l

.locret_145EA:                           ; CODE XREF: sub_14486+C8↑j
; sub_14486+10A↑j ...
                rts
; End of function sub_14486


; =============== S U B R O U T I N E =======================================


sub_145EC:                              ; CODE XREF: sub_14486+12↑p
; sub_14CEC+4↓p
                move.w  $12(a1),d0
                move.w  $12(a2),d4
                cmpi.b  #$10,$71(a2)
                bmi.w   .loc_14616
                btst    #3,$69(a2)
                beq.w   .loc_14616
                neg.w   d4
                sub.w   d4,d0
                bpl.w   .loc_14612
                neg.w   d0

.loc_14612:                              ; CODE XREF: sub_145EC+20↑j
                bra.w   .loc_14652


.loc_14616:                              ; CODE XREF: sub_145EC+E↑j
; sub_145EC+18↑j
                sub.w   d4,d0
                bcc.w   .loc_14628
                neg.w   d1
                cmp.w   d1,d0
                bcs.w   .loc_14652
                bra.w   .loc_1462E


.loc_14628:                              ; CODE XREF: sub_145EC+2C↑j
                cmp.w   d1,d0
                bcc.w   .loc_14652

.loc_1462E:                              ; CODE XREF: sub_145EC+38↑j
                tst.b   $6E(a1)
                bmi.w   .locret_14686
                move.b  #1,$6E(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_1464E
                move.b  #9,(ram_FF1AD6).l

.loc_1464E:                              ; CODE XREF: sub_145EC+56↑j
                bra.w   .loc_1466A


.loc_14652:                              ; CODE XREF: sub_145EC:@loc_14612↑j
; sub_145EC+34↑j ...
                move.b  #0,$6E(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_1466A
                move.b  #$A,(ram_FF1AD6).l

.loc_1466A:                              ; CODE XREF: sub_145EC:@loc_1464E↑j
; sub_145EC+72↑j
                move.b  #$FF,$6F(a1)
                asl.w   #1,d1
                cmp.w   d1,d0
                bcc.w   .loc_14682
                jsr     (sub_15538).l
                bra.w   .locret_14686


.loc_14682:                              ; CODE XREF: sub_145EC+88↑j
                bsr.w   sub_1555C

.locret_14686:                           ; CODE XREF: sub_145EC+46↑j
; sub_145EC+92↑j
                rts
; End of function sub_145EC


; =============== S U B R O U T I N E =======================================


sub_14688:                              ; CODE XREF: sub_14486+AE↑p
                move.l  (ram_FF3038).l,d0
                addi.l  #$3000,d0
                addi.l  #$200,d0
                btst    #0,$69(a1)
                bne.w   .loc_146A6
                neg.l   d0

.loc_146A6:                              ; CODE XREF: sub_14688+18↑j
                add.l   d0,4(a1)
                rts
; End of function sub_14688


; =============== S U B R O U T I N E =======================================


sub_146AC:                              ; CODE XREF: sub_115C6+100↑p
                move.w  $2C(a1),d1
                mulu.w  #$2000,d1
                swap    d1
                move.w  d1,$2C(a1)
                beq.w   .loc_14702
                btst    #4,$68(a1)
                beq.w   .loc_146EC
                move.w  $12(a1),d0
                move.w  d0,d1
                lsr.w   #3,d1
                beq.w   .loc_14702
                sub.w   d1,d0
                move.w  d0,$12(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_146EC
                move.w  #6,(ram_FF1AD6).l

.loc_146EC:                              ; CODE XREF: sub_146AC+18↑j
; sub_146AC+34↑j
                move.w  2(a1),$2A(a1)
                move.w  #0,$2E(a1)
                bset    #0,$68(a1)
                bra.w   .loc_14708


.loc_14702:                              ; CODE XREF: sub_146AC+E↑j
; sub_146AC+24↑j
                bclr    #0,$68(a1)

.loc_14708:                              ; CODE XREF: sub_146AC+52↑j
                cmpi.b  #0,$6E(a1)
                bne.w   .locret_14718
                move.b  #1,$6E(a1)

.locret_14718:                           ; CODE XREF: sub_146AC+62↑j
                rts
; End of function sub_146AC


unk_1471A:      dc.b $E6                ; DATA XREF: sub_B840↑o
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $B3
                dc.b $1A
                dc.b $66 ; f
                dc.b $58 ; X
                dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $B3
                dc.b $1A
                dc.b $66 ; f
                dc.b $58 ; X
                dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $B3
                dc.b $1A
                dc.b $66 ; f
                dc.b $58 ; X
                dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $99
                dc.b $84
                dc.b $4C ; L
                dc.b $C2
                dc.b $E6
                dc.b $46 ; F
                dc.b $AB
                dc.b $6D ; m
                dc.b $B3
                dc.b $1A
                dc.b $66 ; f
                dc.b $58 ; X
word_14742:     dc.w $4CC2              ; DATA XREF: sub_13EFA+6A↑r
unk_14744:      dc.b   0                ; DATA XREF: sub_11CC8+35A↑o
; sub_12070+E6↑o
                dc.b   1
                dc.b $40 ; @
                dc.b $EE
                dc.b   0
                dc.b   1
                dc.b $44 ; D
                dc.b   4
                dc.b   0
                dc.b   1
                dc.b $41 ; A
                dc.b $AE
                dc.b   0
                dc.b   1
                dc.b $44 ; D
                dc.b $56 ; V
                dc.b   0
                dc.b   1
                dc.b $44 ; D
                dc.b $6E ; n
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $CC
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $B0
                dc.b   0
                dc.b   1
                dc.b $42 ; B
                dc.b $BE
unk_14764:      dc.b   0                ; DATA XREF: sub_FC0E+8E↑o
; sub_12070+2E↑o ...
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   2
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b $80
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
unk_147FC:      dc.b   0                ; DATA XREF: sub_11CC8+34C↑o
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   1
                dc.b   7
                dc.b   7
                dc.b   7
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   2
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   6
                dc.b   6
                dc.b   6
                dc.b   6
                dc.b   6
                dc.b   0

; =============== S U B R O U T I N E =======================================


sub_1487C:                              ; CODE XREF: sub_11CC8:@loc_11DFE↑p
; sub_1218C:@loc_12272↑p
                clr.w   (ram_FF1A9A).l
                clr.w   (ram_FF1A9C).l
                clr.w   (ram_FF18B8).l
                clr.w   (ram_FF18BA).l
                move.l  $1E(a1),d0
                sub.l   $1E(a2),d0
                bpl.w   .loc_148AE
                cmp.l   #$FFFFA000,d0
                bpl.w   .loc_148C0
                bra.w   .loc_148B8


.loc_148AE:                              ; CODE XREF: sub_1487C+20↑j
                cmp.l   (ram_FF3038).l,d0
                bmi.w   .loc_148C0

.loc_148B8:                              ; CODE XREF: sub_1487C+2E↑j
                bsr.w   sub_14CEC
                bra.w   .locret_1496A


.loc_148C0:                              ; CODE XREF: sub_1487C+2A↑j
; sub_1487C+38↑j
                bsr.w   sub_1496C
                btst    #4,$69(a1)
                beq.w   .loc_148D6
                tst.w   $50(a1)
                bne.w   .loc_148F0

.loc_148D6:                              ; CODE XREF: sub_1487C+4E↑j
                move.w  $52(a1),d1
                add.w   d1,$22(a1)
                move.w  #0,$52(a1)
                move.w  #0,(ram_FF18BA).l
                bra.w   .loc_1491E


.loc_148F0:                              ; CODE XREF: sub_1487C+56↑j
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_14910
                move.b  (ram_FF1ADB).l,d2
                cmp.b   $71(a2),d2
                bne.w   .loc_14910
                move.w  #3,(ram_FF0520).l

.loc_14910:                              ; CODE XREF: sub_1487C+7A↑j
; sub_1487C+88↑j
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_1491E
                bsr.w   sub_149C4

.loc_1491E:                              ; CODE XREF: sub_1487C+70↑j
; sub_1487C+9A↑j
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_1493A
                btst    #4,$69(a2)
                beq.w   .loc_1493A
                tst.w   $50(a2)
                bne.w   .loc_14954

.loc_1493A:                              ; CODE XREF: sub_1487C+A8↑j
; sub_1487C+B2↑j
                move.w  $52(a2),d1
                add.w   d1,$22(a2)
                move.w  #0,$52(a2)
                move.w  #0,(ram_FF18B8).l
                bra.w   .loc_14962


.loc_14954:                              ; CODE XREF: sub_1487C+BA↑j
                cmpi.b  #1,$6C(a2)
                bne.w   .loc_14962
                bsr.w   sub_14B04

.loc_14962:                              ; CODE XREF: sub_1487C+D4↑j
; sub_1487C+DE↑j
                bsr.w   sub_14D84
                bsr.w   sub_14C3C

.locret_1496A:                           ; CODE XREF: sub_1487C+40↑j
                rts
; End of function sub_1487C


; =============== S U B R O U T I N E =======================================


sub_1496C:                              ; CODE XREF: sub_1487C:@loc_148C0↑p
                movem.l d0-d3,-(sp)
                move.w  $1A(a1),d0
                move.w  $1A(a2),d1
                move.w  $30(a1),d2
                move.w  $30(a2),d3
                cmp.w   d1,d0
                bpl.w   .loc_149A0
                add.w   $4E(a1),d2
                add.w   $4C(a2),d2
                addi.w  #$10,d2
                cmp.w   d3,d2
                bmi.w   .loc_149B6
                move.w  d2,$30(a2)
                bra.w   .loc_149B6


.loc_149A0:                              ; CODE XREF: sub_1496C+16↑j
                sub.w   $4C(a1),d2
                sub.w   $4E(a2),d2
                subi.w  #$10,d2
                cmp.w   d3,d2
                bpl.w   .loc_149B6
                move.w  d2,$30(a2)

.loc_149B6:                              ; CODE XREF: sub_1496C+28↑j
; sub_1496C+30↑j ...
                sub.w   $30(a2),d3
                sub.w   d3,0.w(a2)
                movem.l (sp)+,d0-d3
                rts
; End of function sub_1496C


; =============== S U B R O U T I N E =======================================


sub_149C4:                              ; CODE XREF: sub_1487C+9E↑p
                move.w  $52(a1),d1
                btst    #6,$69(a1)
                beq.w   .loc_14A04
                move.w  $60(a1),d0
                muls.w  d0,d1
                asr.l   #8,d1
                move.w  d1,$52(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .locret_14B02
                move.w  d1,(ram_FF1A9A).l
                tst.w   (ram_FF1904).l
                beq.w   .locret_14B02
                move.b  #$14,(ram_FF1AD6).l
                bra.w   .locret_14B02


.loc_14A04:                              ; CODE XREF: sub_149C4+A↑j
                move.w  $5E(a1),d0
                muls.w  d0,d1
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_14A26
                tst.w   (ram_FF1904).l
                beq.w   .loc_14A26
                move.b  #$11,(ram_FF1AD6).l

.loc_14A26:                              ; CODE XREF: sub_149C4+4C↑j
; sub_149C4+56↑j
                asr.l   #8,d1
                move.w  d1,$52(a1)
                bpl.w   .loc_14A32
                neg.w   d1

.loc_14A32:                              ; CODE XREF: sub_149C4+68↑j
                tst.b   $6B(a1)
                bne.w   .loc_14A62
                move.w  $1A(a1),d0
                sub.w   $1A(a2),d0
                bpl.w   .loc_14A48
                neg.w   d0

.loc_14A48:                              ; CODE XREF: sub_149C4+7E↑j
                sub.w   $4A(a1),d0
                sub.w   $4A(a2),d0
                cmp.w   #$A,d0
                bpl.w   .loc_14A62
                move.b  #$14,$6D(a1)
                bra.w   .loc_14A72


.loc_14A62:                              ; CODE XREF: sub_149C4+72↑j
; sub_149C4+90↑j
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .locret_14B02
                move.w  d1,(ram_FF18BA).l

.loc_14A72:                              ; CODE XREF: sub_149C4+9A↑j
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .locret_14B02
                btst    #6,$69(a2)
                bne.w   .loc_14AE4
                btst    #1,$6B(a1)
                bne.w   .loc_14AE4
                btst    #1,$6B(a2)
                beq.w   .loc_14AE4
                btst    #4,$69(a2)
                beq.w   .loc_14AE4
                cmpi.b  #0,$6C(a2)
                bne.w   .loc_14AE4
                bchg    #1,$6B(a1)
                move.b  #2,$6C(a1)
                move.b  #2,$6C(a2)
                move.b  #$3C,$6D(a1) ; '<'
                clr.b   $6B(a2)
                move.b  #$3C,$6D(a2) ; '<'
                move.b  #$15,(ram_FF1AD6).l
                move.w  #$1E,(ram_FF1EA8).l
                bra.w   .locret_14B02


.loc_14AE4:                              ; CODE XREF: sub_149C4+BE↑j
; sub_149C4+C8↑j ...
                move.b  $6B(a1),d2
                andi.w  #3,d2
                andi.b  #$FC,$6A(a2)
                or.b    d2,$6A(a2)
                bset    #2,$6A(a2)
                move.b  #$1E,$70(a2)

.locret_14B02:                           ; CODE XREF: sub_149C4+20↑j
; sub_149C4+30↑j ...
                rts
; End of function sub_149C4


; =============== S U B R O U T I N E =======================================


sub_14B04:                              ; CODE XREF: sub_1487C+E2↑p
                move.w  $52(a2),d1
                btst    #6,$69(a2)
                beq.w   .loc_14B44
                move.w  $60(a2),d0
                muls.w  d0,d1
                asr.l   #8,d1
                move.w  d1,$52(a2)
                move.w  d1,(ram_FF1A9C).l
                cmpa.l  (ram_FF1908).l,a2
                bne.w   .locret_14C3A
                tst.w   (ram_FF1906).l
                beq.w   .locret_14C3A
                move.b  #$14,(ram_FF1AD6).l
                bra.w   .locret_14C3A


.loc_14B44:                              ; CODE XREF: sub_14B04+A↑j
                move.w  $5E(a2),d0
                muls.w  d0,d1
                cmpa.l  (ram_FF1908).l,a2
                bne.w   .loc_14B66
                tst.w   (ram_FF1906).l
                beq.w   .loc_14B66
                move.b  #$11,(ram_FF1AD6).l

.loc_14B66:                              ; CODE XREF: sub_14B04+4C↑j
; sub_14B04+56↑j
                asr.l   #8,d1
                move.w  d1,$52(a2)
                bpl.w   .loc_14B72
                neg.w   d1

.loc_14B72:                              ; CODE XREF: sub_14B04+68↑j
                tst.b   $6B(a2)
                bne.w   .loc_14BA2
                move.w  $1A(a1),d0
                sub.w   $1A(a2),d0
                bpl.w   .loc_14B88
                neg.w   d0

.loc_14B88:                              ; CODE XREF: sub_14B04+7E↑j
                sub.w   $4A(a1),d0
                sub.w   $4A(a2),d0
                cmp.w   #$A,d0
                bpl.w   .loc_14BA2
                move.b  #$14,$6D(a2)
                bra.w   .loc_14BB4


.loc_14BA2:                              ; CODE XREF: sub_14B04+72↑j
; sub_14B04+90↑j
                cmp.w   #$50,d1 ; 'P'
                ble.w   .loc_14BAE
                move.w  #$50,d1 ; 'P'

.loc_14BAE:                              ; CODE XREF: sub_14B04+A2↑j
                move.w  d1,(ram_FF18B8).l

.loc_14BB4:                              ; CODE XREF: sub_14B04+9A↑j
                btst    #6,$69(a2)
                bne.w   .loc_14C1C
                btst    #1,$6B(a2)
                bne.w   .loc_14C1C
                btst    #1,$6B(a1)
                beq.w   .loc_14C1C
                btst    #4,$69(a1)
                beq.w   .loc_14C1C
                cmpi.b  #0,$6C(a1)
                bne.w   .loc_14C1C
                bchg    #1,$6B(a2)
                bchg    #1,$6B(a1)
                clr.b   $6B(a1)
                move.b  #$3C,$6D(a1) ; '<'
                move.b  #2,$6C(a2)
                move.b  #$3C,$6D(a2) ; '<'
                move.b  #$15,(ram_FF1AD6).l
                move.w  #$1E,(ram_FF1EA8).l
                bra.w   .locret_14C3A


.loc_14C1C:                              ; CODE XREF: sub_14B04+B6↑j
; sub_14B04+C0↑j ...
                move.b  $6B(a2),d2
                andi.w  #3,d2
                andi.b  #$FC,$6A(a1)
                or.b    d2,$6A(a1)
                bset    #2,$6A(a1)
                move.b  #$1E,$70(a1)

.locret_14C3A:                           ; CODE XREF: sub_14B04+26↑j
; sub_14B04+30↑j ...
                rts
; End of function sub_14B04


; =============== S U B R O U T I N E =======================================


sub_14C3C:                              ; CODE XREF: sub_1487C+EA↑p
                tst.b   $6E(a1)
                bpl.w   .loc_14C8C
                move.w  (ram_FF18B8).l,d0
                beq.w   .loc_14C8C
                mulu.w  (ram_FF18AC).l,d0
                sub.w   d0,$5C(a1)
                bcc.w   .loc_14C8C
                move.w  #0,$5C(a1)
                bset    #4,$68(a1)
                move.w  #$11,$54(a1)
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_14C8C
                move.b  #$F,(ram_FF1AD6).l

.loc_14C8C:                              ; CODE XREF: sub_14C3C+4↑j
; sub_14C3C+E↑j ...
                tst.b   $6E(a2)
                bpl.w   .locret_14CEA
                move.w  (ram_FF18BA).l,d0
                beq.w   .locret_14CEA
                mulu.w  (ram_FF18AC).l,d0
                sub.w   d0,$5C(a2)
                bcc.w   .locret_14CEA
                move.w  #0,$5C(a2)
                bset    #4,$68(a2)
                move.w  #$11,$54(a2)
                move.b  #0,$6E(a2)
                move.b  #$FF,$6F(a2)
                exg     a1,a2
                move.l  a2,-(sp)
                jsr     (sub_11906).l
                movea.l a1,a2
                movea.l (sp)+,a1
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .locret_14CEA
                move.b  #$D,(ram_FF1AD6).l

.locret_14CEA:                           ; CODE XREF: sub_14C3C+54↑j
; sub_14C3C+5E↑j ...
                rts
; End of function sub_14C3C


; =============== S U B R O U T I N E =======================================


sub_14CEC:                              ; CODE XREF: sub_1487C:@loc_148B8↑p
                move.w  #$1F40,d1
                bsr.w   sub_145EC
                move.w  d0,(ram_FF18A6).l
                move.w  $12(a2),d0
                sub.w   $12(a1),d0
                bpl.w   .loc_14D14
                neg.w   d0
                mulu.w  #$1999,d0
                swap    d0
                neg.w   d0
                bra.w   .loc_14D1A


.loc_14D14:                              ; CODE XREF: sub_14CEC+16↑j
                mulu.w  #$1999,d0
                swap    d0

.loc_14D1A:                              ; CODE XREF: sub_14CEC+24↑j
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_14D34
                move.w  d0,-(sp)
                jsr     (sub_1434A).l
                add.w   d0,(Race_ram_BikeDamage).l
                move.w  (sp)+,d0

.loc_14D34:                              ; CODE XREF: sub_14CEC+34↑j
                move.w  $12(a1),d1
                move.w  $12(a2),d2
                move.l  #$7000,d3
                cmp.w   d2,d1
                bpl.w   .loc_14D4A
                neg.l   d3

.loc_14D4A:                              ; CODE XREF: sub_14CEC+58↑j
                btst    #0,$69(a1)
                add.w   d0,d2
                sub.w   d0,d1
                move.l  4(a1),d0
                add.l   d3,d0
                move.l  d0,4(a2)
                move.w  d2,$12(a1)
                move.w  d1,$12(a2)
                move.b  $69(a1),d0
                andi.w  #8,d0
                or.b    d0,$69(a2)
                move.b  $69(a2),d0
                andi.w  #8,d0
                or.b    d0,$69(a1)
                bsr.w   sub_14D84
                rts
; End of function sub_14CEC


; =============== S U B R O U T I N E =======================================


sub_14D84:                              ; CODE XREF: sub_1487C:@loc_14962↑p
; sub_14CEC+92↑p
                move.w  $22(a2),d0
                sub.w   $22(a1),d0
                ext.l   d0
                divs.w  (Race_ram_FrameDelay).l,d0
                bpl.w   .loc_14DA8
                neg.w   d0
                mulu.w  (ram_FF18B6).l,d0
                swap    d0
                neg.w   d0
                bra.w   .loc_14DB0


.loc_14DA8:                              ; CODE XREF: sub_14D84+10↑j
                mulu.w  (ram_FF18B6).l,d0
                swap    d0

.loc_14DB0:                              ; CODE XREF: sub_14D84+20↑j
                move.w  $C(a1),d1
                add.w   (ram_FF1A9A).l,d1
                move.w  $C(a2),d2
                add.w   (ram_FF1A9C).l,d2
                btst    #1,$69(a1)
                beq.w   .loc_14DD6
                add.w   d0,d2
                sub.w   d0,d1
                bra.w   .loc_14DDA


.loc_14DD6:                              ; CODE XREF: sub_14D84+46↑j
                sub.w   d0,d2
                add.w   d0,d1

.loc_14DDA:                              ; CODE XREF: sub_14D84+4E↑j
                move.w  d2,$C(a1)
                move.w  d2,8(a1)
                move.w  d1,$C(a2)
                move.w  d1,8(a2)
                rts
; End of function sub_14D84


                dc.b $30 ; 0
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $68 ; h
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $40 ; @
                dc.b $32 ; 2
                dc.b $29 ; )
                dc.b   0
                dc.b $12
                dc.b   8
                dc.b $29 ; )
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b $68 ; h
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b $44 ; D
                dc.b $41 ; A
                dc.b $90
                dc.b $41 ; A
                dc.b $E0
                dc.b $40 ; @
                dc.b $34 ; 4
                dc.b $39 ; 9
                dc.b   0
                dc.b $FF
                dc.b $30 ; 0
                dc.b $4A ; J
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b $16
                dc.b $32 ; 2
                dc.b $29 ; )
                dc.b   0
                dc.b $22 ; "
                dc.b $92
                dc.b $6A ; j
                dc.b   0
                dc.b $22 ; "
                dc.b $67 ; g
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b $48 ; H
                dc.b $C1
                dc.b $83
                dc.b $C2
                dc.b $60 ; `
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b $30 ; 0
                dc.b $3C ; <
                dc.b   0
                dc.b   0
                dc.b $32 ; 2
                dc.b $3C ; <
                dc.b   0
                dc.b   1
                dc.b $4E ; N
                dc.b $75 ; u

; =============== S U B R O U T I N E =======================================


sub_14E38:                              ; CODE XREF: Race_Update+266↑p
                tst.w   (Race_ram_GameEnded).l
                beq.w   .loc_14E58
                jsr     (AudioFunc7).l
                jsr     (AudioFunc10).l
                jsr     (AudioFunc13).l
                bra.w   .loc_14E62


.loc_14E58:                              ; CODE XREF: sub_14E38+6↑j
                tst.w   (Race_ram_State).l
                beq.w   .loc_14E7A

.loc_14E62:                              ; CODE XREF: sub_14E38+1C↑j
                jsr     (AudioFunc15).l
                jsr     (AudioFunc17).l
                move.b  #0,(ram_FF1AD5).l
                bra.w   .loc_14FA2


.loc_14E7A:                              ; CODE XREF: sub_14E38+26↑j
                clr.l   d0
                btst    #5,(ram_FF1EAA + STRUCT_OFFSET_68).l
                beq.w   .loc_14E9A
                btst    #3,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .loc_14EB2
                moveq   #1,d0
                bra.w   .loc_14EB4


.loc_14E9A:                              ; CODE XREF: sub_14E38+4C↑j
                cmpi.b  #1,(ram_FF1EAA + STRUCT_OFFSET_6E).l
                bne.w   .loc_14ECE
                btst    #0,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .loc_14ECE

.loc_14EB2:                              ; CODE XREF: sub_14E38+58↑j
                moveq   #2,d0

.loc_14EB4:                              ; CODE XREF: sub_14E38+5E↑j
                cmp.b   (ram_FF1AD4).l,d0
                beq.w   .loc_14EE6
                move.b  d0,(ram_FF1AD4).l
                jsr     (AudioFunc5).l
                bra.w   .loc_14EE6


.loc_14ECE:                              ; CODE XREF: sub_14E38+6A↑j
; sub_14E38+76↑j
                tst.w   (ram_FF1AD4).l
                beq.w   .loc_14EE6
                move.b  #0,(ram_FF1AD4).l
                jsr     (AudioFunc15).l

.loc_14EE6:                              ; CODE XREF: sub_14E38+82↑j
; sub_14E38+92↑j ...
                tst.w   (ram_FF1EA8).l
                beq.w   .loc_14F1E
                move.w  (ram_FF1EA8).l,d0
                sub.w   (Race_ram_FrameDelay).l,d0
                ble.w   .loc_14F16
                move.w  d0,(ram_FF1EA8).l
                cmpi.b  #$15,(ram_FF1AD6).l
                beq.w   .loc_14F1E
                bra.w   .loc_14F58


.loc_14F16:                              ; CODE XREF: sub_14E38+C4↑j
                move.w  #0,(ram_FF1EA8).l

.loc_14F1E:                              ; CODE XREF: sub_14E38+B4↑j
; sub_14E38+D6↑j
                clr.l   d0
                move.b  (ram_FF1AD6).l,d0
                beq.w   .loc_14F34
                jsr     (AudioFunc5).l
                bra.w   .loc_14F58


.loc_14F34:                              ; CODE XREF: sub_14E38+EE↑j
                clr.l   d0
                move.b  (ram_FF1AD7).l,d0
                beq.w   .loc_14F58
                cmp.b   #$E,d0
                bne.w   .loc_14F52
                tst.b   (ram_FF1ADD).l
                beq.w   .loc_14F58

.loc_14F52:                              ; CODE XREF: sub_14E38+10C↑j
                jsr     (AudioFunc5).l

.loc_14F58:                              ; CODE XREF: sub_14E38+DA↑j
; sub_14E38+F8↑j ...
                tst.w   (ram_FF1B32).l
                bne.w   .loc_14FA2
                move.w  (ram_FF1F2E).l,d0
                sub.w   (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                bpl.w   .loc_14F74
                neg.w   d0

.loc_14F74:                              ; CODE XREF: sub_14E38+136↑j
                cmp.w   #$18,d0
                bpl.w   .loc_14FA2
                move.w  d0,d1
                asl.w   #1,d0
                add.w   d0,d1
                addq.w  #6,d1
                jsr     (AudioFunc16).l
                moveq   #5,d0
                cmp.b   (ram_FF1AD5).l,d0
                beq.w   .loc_14FA2
                move.b  d0,(ram_FF1AD5).l
                jsr     (AudioFunc5).l

.loc_14FA2:                              ; CODE XREF: sub_14E38+3E↑j
; sub_14E38+126↑j ...
                move.b  #0,(ram_FF1AD6).l
                move.b  #0,(ram_FF1AD7).l
                rts
; End of function sub_14E38


; =============== S U B R O U T I N E =======================================


sub_14FB4:                              ; CODE XREF: sub_1611A+AE↓p
                move.w  d0,-(sp)
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,(ram_FF1AD0).l
                bcc.w   .loc_15010
                move.w  #$12,(ram_FF1AD0).l
                addi.w  #1,(ram_FF1ACE).l
                move.w  (ram_FF1ACE).l,d0
                btst    #0,d0
                beq.w   .loc_15000
                tst.b   $6E(a1)
                bpl.w   .loc_15000
                cmpi.w  #5,(ram_FF1B40).l
                bpl.w   .loc_15000
                move.b  #$15,(ram_FF1AD6).l

.loc_15000:                              ; CODE XREF: sub_14FB4+2C↑j
; sub_14FB4+34↑j ...
                cmp.w   #$A,d0
                bmi.w   .loc_15010
                move.w  #1,(Race_ram_GameEnded).l

.loc_15010:                              ; CODE XREF: sub_14FB4+E↑j
; sub_14FB4+50↑j
                move.w  (sp)+,d0
                rts
; End of function sub_14FB4


; =============== S U B R O U T I N E =======================================


sub_15014:                              ; CODE XREF: sub_F40C+106↑p
                movem.l d1-d7/a0-a2,-(sp)
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_258AE).l,a0
                movea.l (a0,d0.w),a2
                move.l  a2,(ram_FF1AF6).l
                bsr.w   sub_1533E
                move.w  $54(a1),d0
                cmp.w   #$11,d0
                ble.w   .loc_15048
                move.w  #$11,d0
                move.w  d0,$54(a1)

.loc_15048:                              ; CODE XREF: sub_15014+28↑j
                asl.w   #2,d0
                lea     (unk_155D0).l,a0
                movea.l (a0,d0.w),a0

.loc_15054:                              ; CODE XREF: sub_15014+F2↓j
                move.b  $70(a1),d2
                move.b  $6F(a1),d1
                bpl.w   *+4

.loc_15060:                              ; CODE XREF: sub_15014+48↑j
                move.b  $6E(a1),d0
                ext.w   d0
                asl.w   #3,d0
                movea.l (a0,d0.w),a3
                cmpa.l  #$FFFFFFFF,a3
                beq.w   .loc_151DE
                movea.l 4(a0,d0.w),a5
                movea.l a3,a4
                cmpi.b  #3,$6E(a1)
                bne.w   .loc_150EE
                move.w  #$B0,(ram_FF18BC).l
                move.l  $26(a1),d3
                lsr.l   #8,d3
                move.w  $22(a1),d4
                bpl.w   .loc_1509E
                neg.w   d4

.loc_1509E:                              ; CODE XREF: sub_15014+84↑j
                cmp.w   d4,d3
                bmi.w   .loc_150E0
                btst    #3,$69(a1)
                bne.w   .loc_150C0
                move.w  4(a1),d7
                cmp.w   (ram_FF1E68).l,d7
                bpl.w   .loc_150EE
                bra.w   .loc_150CE


.loc_150C0:                              ; CODE XREF: sub_15014+96↑j
                move.w  4(a1),d7
                cmp.w   (ram_FF1E68).l,d7
                bmi.w   .loc_150EE

.loc_150CE:                              ; CODE XREF: sub_15014+A8↑j
                lea     (unk_15CE0).l,a4
                move.w  #$B1,(ram_FF18BC).l
                bra.w   .loc_150EE


.loc_150E0:                              ; CODE XREF: sub_15014+8C↑j
                lea     (unk_15CFC).l,a4
                move.w  #$B2,(ram_FF18BC).l

.loc_150EE:                              ; CODE XREF: sub_15014+6E↑j
; sub_15014+A4↑j ...
                bsr.w   sub_154D2
                tst.w   d0
                bpl.w   .loc_1510A
                bsr.w   sub_151F0
                cmpi.b  #$FF,$6E(a1)
                beq.w   .loc_151DE
                bra.w   .loc_15054


.loc_1510A:                              ; CODE XREF: sub_15014+E0↑j
                move.w  d0,$58(a1)
                move.b  d1,$6F(a1)
                move.b  d2,$70(a1)
                cmpi.b  #3,$6E(a1)
                bne.w   .loc_15148
                move.l  $26(a1),d0
                or.w    $22(a1),d0
                bne.w   .loc_15138
                move.w  (ram_FF18BC).l,$58(a1)
                bra.w   .loc_1514C


.loc_15138:                              ; CODE XREF: sub_15014+114↑j
                tst.w   $22(a1)
                beq.w   .loc_1514C
                bpl.w   .loc_15148
                bset    #0,d3

.loc_15148:                              ; CODE XREF: sub_15014+108↑j
; sub_15014+12C↑j
                move.b  d3,$76(a1)

.loc_1514C:                              ; CODE XREF: sub_15014+120↑j
; sub_15014+128↑j
                move.w  $54(a2),d0
                cmp.w   #$11,d0
                ble.w   .loc_15160
                move.w  #$11,d0
                move.w  d0,$54(a1)

.loc_15160:                              ; CODE XREF: sub_15014+140↑j
                asl.w   #2,d0
                lea     (unk_155D0).l,a0
                movea.l (a0,d0.w),a0

.loc_1516C:                              ; CODE XREF: sub_15014+1B4↓j
                move.b  $70(a2),d2
                move.b  $6F(a2),d1
                move.b  $6E(a2),d0
                tst.w   $12(a2)
                bne.w   .loc_15198
                cmp.b   #4,d0
                beq.w   .loc_15198
                move.b  #3,d0
                move.b  d0,$6E(a2)
                move.b  #$FF,d1
                move.b  #0,d2

.loc_15198:                              ; CODE XREF: sub_15014+168↑j
; sub_15014+170↑j
                ext.w   d0
                asl.w   #3,d0
                movea.l 4(a0,d0.w),a4
                cmpa.l  #$FFFFFFFF,a4
                bne.w   .loc_151B4
                move.b  #$FF,$6E(a2)
                bra.w   .loc_151EA


.loc_151B4:                              ; CODE XREF: sub_15014+192↑j
                bsr.w   sub_154D2
                tst.w   d0
                bpl.w   .loc_151CA
                bsr.w   sub_15446
                move.b  #0,$70(a2)
                bra.s   .loc_1516C


.loc_151CA:                              ; CODE XREF: sub_15014+1A6↑j
                move.w  d0,$58(a2)
                move.b  d1,$6F(a2)
                move.b  d2,$70(a2)
                move.b  d3,$76(a2)
                bra.w   .loc_151EA


.loc_151DE:                              ; CODE XREF: sub_15014+5E↑j
; sub_15014+EE↑j
                move.b  #$FF,$6E(a1)
                move.b  #$FF,$6E(a2)

.loc_151EA:                              ; CODE XREF: sub_15014+19C↑j
; sub_15014+1C6↑j
                movem.l (sp)+,d1-d7/a0-a2
                rts
; End of function sub_15014


; =============== S U B R O U T I N E =======================================


sub_151F0:                              ; CODE XREF: sub_15014+E4↑p
                movem.l d0-d1,-(sp)
                cmpi.b  #1,$6E(a1)
                bmi.w   .loc_1521C
                bne.w   .loc_1522C
                cmpi.w  #0,$12(a1)
                bne.w   .loc_1521C
                move.b  #2,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15338


.loc_1521C:                              ; CODE XREF: sub_151F0+A↑j
; sub_151F0+18↑j
                move.b  #1,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15338


.loc_1522C:                              ; CODE XREF: sub_151F0+E↑j
                cmpi.b  #3,$6E(a1)
                blt.w   .loc_152AA
                beq.w   .loc_1524A
                move.b  #$FF,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15338


.loc_1524A:                              ; CODE XREF: sub_151F0+46↑j
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   .loc_1526C
                move.l  4(a1),d0
                sub.l   4(a2),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_152AA
                bra.w   .loc_1527E


.loc_1526C:                              ; CODE XREF: sub_151F0+62↑j
                move.l  4(a2),d0
                sub.l   4(a1),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_152AA

.loc_1527E:                              ; CODE XREF: sub_151F0+78↑j
                move.w  $1A(a2),d0
                sub.w   $1A(a1),d0
                bpl.w   .loc_1529A
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                bmi.w   .loc_152AA
                bra.w   .loc_152D6


.loc_1529A:                              ; CODE XREF: sub_151F0+96↑j
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                cmp.w   #$40,d0 ; '@'
                ble.w   .loc_152D6

.loc_152AA:                              ; CODE XREF: sub_151F0+42↑j
; sub_151F0+74↑j ...
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_152C6
                tst.w   (ram_FF1B1A).l
                beq.w   .loc_152C6
                move.w  #1,(Race_ram_GameEnded).l

.loc_152C6:                              ; CODE XREF: sub_151F0+C0↑j
; sub_151F0+CA↑j
                move.b  #3,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15338


.loc_152D6:                              ; CODE XREF: sub_151F0+A6↑j
; sub_151F0+B6↑j
                bclr    #3,$69(a1)
                move.w  #0,8(a1)
                move.w  #0,$C(a1)
                move.w  #0,$12(a1)
                move.w  #0,$12(a2)
                move.l  4(a1),d0
                subi.l  #$2000,d0
                move.l  d0,4(a2)
                move.w  #$20,d1 ; ' '
                move.w  $30(a1),d0
                bmi.w   .loc_15310
                lsr.w   #1,d1

.loc_15310:                              ; CODE XREF: sub_151F0+11A↑j
                add.w   d1,d0
                move.w  d0,$30(a2)
                move.w  0.w(a1),d0
                add.w   d1,d0
                move.w  d0,0.w(a2)
                move.b  #4,$6E(a1)
                move.b  #4,$6E(a2)
                move.b  #$FF,$6F(a1)
                move.b  #$FF,$6F(a2)

.loc_15338:                              ; CODE XREF: sub_151F0+28↑j
; sub_151F0+38↑j ...
                movem.l (sp)+,d0-d1
                rts
; End of function sub_151F0


; =============== S U B R O U T I N E =======================================


sub_1533E:                              ; CODE XREF: sub_15014+1C↑p
                movem.l d0-d1,-(sp)
                cmpi.b  #1,$6E(a1)
                bmi.w   .loc_15440
                bne.w   .loc_1536A
                cmpi.w  #0,$12(a1)
                bne.w   .loc_15440
                move.b  #2,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15440


.loc_1536A:                              ; CODE XREF: sub_1533E+E↑j
                cmpi.b  #4,$6E(a1)
                beq.w   .loc_153FC
                cmpi.b  #3,$6E(a1)
                bne.w   .loc_15440
                move.l  $1E(a2),d0
                sub.l   $1E(a1),d0
                bpl.w   .loc_153A0
                move.l  4(a1),d0
                sub.l   4(a2),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_15440
                bra.w   .loc_153B2


.loc_153A0:                              ; CODE XREF: sub_1533E+48↑j
                move.l  4(a2),d0
                sub.l   4(a1),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_15440

.loc_153B2:                              ; CODE XREF: sub_1533E+5E↑j
                move.w  $1A(a2),d0
                sub.w   $1A(a1),d0
                bpl.w   .loc_153CE
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                blt.w   .loc_15440
                bra.w   .loc_153DE


.loc_153CE:                              ; CODE XREF: sub_1533E+7C↑j
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                cmp.w   #$40,d0 ; '@'
                bgt.w   .loc_15440

.loc_153DE:                              ; CODE XREF: sub_1533E+8C↑j
                bclr    #3,$69(a1)
                move.b  #4,$6E(a1)
                move.b  #4,$6E(a2)
                move.b  #$FF,$6F(a1)
                move.b  #$FF,$6F(a2)

.loc_153FC:                              ; CODE XREF: sub_1533E+32↑j
                move.w  #0,8(a1)
                move.w  #0,$C(a1)
                move.w  #0,$12(a1)
                move.w  #0,$12(a2)
                move.l  4(a1),d0
                subi.l  #$2000,d0
                move.l  d0,4(a2)
                move.w  #$20,d1 ; ' '
                move.w  $30(a1),d0
                bmi.w   .loc_15430
                lsr.w   #1,d1

.loc_15430:                              ; CODE XREF: sub_1533E+EC↑j
                add.w   d1,d0
                move.w  d0,$30(a2)
                move.w  0.w(a1),d0
                add.w   d1,d0
                move.w  d0,0.w(a2)

.loc_15440:                              ; CODE XREF: sub_1533E+A↑j
; sub_1533E+18↑j ...
                movem.l (sp)+,d0-d1
                rts
; End of function sub_1533E


; =============== S U B R O U T I N E =======================================


sub_15446:                              ; CODE XREF: sub_15014+1AA↑p
                move.w  d0,-(sp)
                move.b  $6E(a2),d0
                cmp.b   #3,d0
                bne.w   .loc_15468
                bra.w   .loc_1546E

                dc.b $4A ; J
                dc.b $6A ; j
                dc.b   0
                dc.b $12
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b STRUCT_OFFSET_66 ; f
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $10
                dc.b $3C ; <
                dc.b   0
                dc.b   2


.loc_15468:                              ; CODE XREF: sub_15446+A↑j
                addq.b  #1,d0
                move.b  d0,$6E(a2)

.loc_1546E:                              ; CODE XREF: sub_15446+E↑j
                move.b  #$FF,$6F(a2)
                move.w  (sp)+,d0
                rts
; End of function sub_15446


; =============== S U B R O U T I N E =======================================


sub_15478:                              ; CODE XREF: sub_FB1E+54↑p
                movem.l d1-d7/a0-a2,-(sp)
                lea     (unk_155A4).l,a0

.loc_15482:                              ; CODE XREF: sub_15478+46↓j
                move.b  (ram_FF302B).l,d2
                move.b  (ram_FF302A).l,d1
                move.w  #0,d0
                move.w  #0,d0
                lea     (unk_155AC).l,a4
                bsr.w   sub_154D2
                tst.w   d0
                bpl.w   .loc_154C0
                move.w  #1,(ram_FF1B20).l
                move.b  #0,(ram_FF302A).l
                move.b  #0,(ram_FF302B).l
                bra.s   .loc_15482


.loc_154C0:                              ; CODE XREF: sub_15478+2A↑j
                move.b  d1,(ram_FF302A).l
                move.b  d2,(ram_FF302B).l
                movem.l (sp)+,d1-d7/a0-a2
                rts
; End of function sub_15478


; =============== S U B R O U T I N E =======================================


sub_154D2:                              ; CODE XREF: sub_15014:@loc_150EE↑p
; sub_15014:@loc_151B4↑p ...
                tst.b   d1
                bmi.w   .loc_15506
                sub.b   (ram_FF304B).l,d2
                bpl.w   .loc_1550C
                add.b   2(a4),d2
                bpl.w   .loc_1550A

.loc_154EA:                              ; CODE XREF: sub_154D2+2E↓j
                addq.b  #1,d1
                move.b  d1,d4
                ext.w   d4
                asl.w   #2,d4
                move.b  3(a4,d4.w),d0
                ext.w   d0
                bmi.w   .loc_1552A
                add.b   2(a4),d2
                bmi.s   .loc_154EA
                bra.w   .loc_15516


.loc_15506:                              ; CODE XREF: sub_154D2+2↑j
                move.b  2(a4),d2

.loc_1550A:                              ; CODE XREF: sub_154D2+14↑j
                addq.b  #1,d1

.loc_1550C:                              ; CODE XREF: sub_154D2+C↑j
                move.b  d1,d4
                ext.w   d4
                asl.w   #2,d4
                move.b  3(a4,d4.w),d0

.loc_15516:                              ; CODE XREF: sub_154D2+30↑j
                move.b  4(a4,d4.w),d3
                move.b  5(a4,d4.w),d5
                move.b  6(a4,d4.w),d6
                ext.w   d0
                bmi.w   .loc_1552A
                add.w   (a4),d0

.loc_1552A:                              ; CODE XREF: sub_154D2+26↑j
; sub_154D2+52↑j
                cmp.w   (word_3C7EA).l,d0
                bmi.w   .locret_15536
                nop

.locret_15536:                           ; CODE XREF: sub_154D2+5E↑j
                rts
; End of function sub_154D2


; =============== S U B R O U T I N E =======================================


sub_15538:                              ; CODE XREF: sub_11B7A+98↑p
; sub_11B7A:@loc_11C20↑p ...
                movem.l d0/a4,-(sp)
                jsr     (Rand_GetWord).l
                andi.w  #3,d0
                lea     (unk_15618).l,a4
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,$54(a1)
                movem.l (sp)+,d0/a4
                rts
; End of function sub_15538


; =============== S U B R O U T I N E =======================================


sub_1555C:                              ; CODE XREF: sub_12BD2:@loc_12C76↑p
; sub_145EC:@loc_14682↑p
                movem.l d0/a4,-(sp)
                jsr     (Rand_GetWord).l
                andi.w  #7,d0
                lea     (unk_15624).l,a4
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,$54(a1)
                movem.l (sp)+,d0/a4
                rts
; End of function sub_1555C


                dc.b $48 ; H
                dc.b $E7
                dc.b $80
                dc.b   8
                dc.b $4E ; N
                dc.b $B9
                dc.b   0
                dc.b   1
                dc.b $60 ; `
                dc.b $34 ; 4
                dc.b   2
                dc.b $40 ; @
                dc.b   0
                dc.b   7
                dc.b $49 ; I
                dc.b $F9
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $1C
                dc.b $10
                dc.b $34 ; 4
                dc.b   0
                dc.b   0
                dc.b $48 ; H
                dc.b $80
                dc.b $33 ; 3
                dc.b $40 ; @
                dc.b   0
                dc.b $54 ; T
                dc.b $4C ; L
                dc.b $DF
                dc.b $10
                dc.b   1
                dc.b $4E ; N
                dc.b $75 ; u
unk_155A4:      dc.b   0                ; DATA XREF: sub_15478+4↑o
                dc.b   1
                dc.b $55 ; U
                dc.b $AC
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
unk_155AC:      dc.b   1                ; DATA XREF: sub_15478+1E↑o
                dc.b $5E ; ^
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
unk_155D0:      dc.b   0                ; DATA XREF: sub_15014+36↑o
; sub_15014+14E↑o
                dc.b   1
                dc.b $57 ; W
                dc.b $60 ; `
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $8C
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $B8
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $E4
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $10
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $3C ; <
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $68 ; h
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $C0
                dc.b   0
                dc.b   1
                dc.b $58 ; X
                dc.b $EC
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $2C ; ,
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $B0
                dc.b   0
                dc.b   1
                dc.b $56 ; V
                dc.b $DC
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b   8
                dc.b   0
                dc.b   1
                dc.b $57 ; W
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $18
unk_15618:      dc.b   6                ; DATA XREF: sub_15538+E↑o
                dc.b  $A
                dc.b  $B
                dc.b  $C
                dc.b   7
                dc.b  $A
                dc.b   2
                dc.b   3
                dc.b  $D
                dc.b  $B
                dc.b  $E
                dc.b   7
unk_15624:      dc.b   0                ; DATA XREF: sub_1555C+E↑o
                dc.b   3
                dc.b  $E
                dc.b  $F
                dc.b $10
                dc.b  $C
                dc.b   7
                dc.b   8
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $F8
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $D0
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $28 ; (
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $44 ; D
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $90
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b  $C
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $90
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $48 ; H
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $30 ; 0
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $50 ; P
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $B8
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $90
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $20
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $D4
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $88
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $34 ; 4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $58 ; X
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $74 ; t
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $F0
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $70 ; p
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $D4
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $E8
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $94
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $9C
                dc.b   0
                dc.b   1
                dc.b $59 ; Y
                dc.b $D4
                dc.b   0
                dc.b   1
                dc.b $5E ; ^
                dc.b $A4
                dc.b   0
                dc.b   1
                dc.b $5A ; Z
                dc.b $4C ; L
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5C ; 
                dc.b $C4
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $84
                dc.b   0
                dc.b   1
                dc.b $5D ; ]
                dc.b $18
                dc.b   0
                dc.b   1
                dc.b $5F ; _
                dc.b $8C
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b $10
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $88
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b $10
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b $10
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $B3
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
unk_15CE0:      dc.b   0                ; DATA XREF: sub_15014:@loc_150CE↑o
                dc.b $B3
                dc.b   4
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
unk_15CFC:      dc.b   0                ; DATA XREF: sub_15014:@loc_150E0↑o
                dc.b $B3
                dc.b   4
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $E
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $F
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $11
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $C5
                dc.b   8
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   8
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $8E
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   9
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $9B
                dc.b $1C
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b  $A
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   9
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   1
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b   8
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b  $C
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   3
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   5
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   6
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   7
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   2
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b  $C
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $B
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $D
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b  $A
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b   0
                dc.b $FF
                dc.b   0
                dc.b $CA
                dc.b  $C
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   4
                dc.b   0
                dc.b   0
                dc.b $13
                dc.b   4
                dc.b   1
                dc.b   0
                dc.b $13
                dc.b   4
                dc.b   2
                dc.b   0
                dc.b $17
                dc.b   1
                dc.b   2
                dc.b   0
                dc.b $15
                dc.b   3
                dc.b   2
                dc.b   0
                dc.b $12
                dc.b   3
                dc.b $FF
byte_15FA8:     dc.b $3D                ; DATA XREF: Rand_Init+6↓o
                dc.b $52 ; R
                dc.b $7F ; 
                dc.b $31 ; 1
                dc.b $80
                dc.b $A2
                dc.b $ED
                dc.b $16
                dc.b $42 ; B
                dc.b $BF
                dc.b $5C ; 
                dc.b $41 ; A
                dc.b  $C
                dc.b $5E ; ^
                dc.b $92
                dc.b $26 ; &
                dc.b $A5
                dc.b $8B
                dc.b $48 ; H
                dc.b $2D ; -
                dc.b $64 ; d
                dc.b $D9
                dc.b $82
                dc.b $AD
                dc.b $E1
                dc.b $79 ; y
                dc.b $21 ; !
                dc.b $4B ; K
                dc.b $81
                dc.b $4C ; L
                dc.b $D7
                dc.b $36 ; 6
                dc.b $97
                dc.b $CF
                dc.b $AE
                dc.b $B1
                dc.b $F7
                dc.b $CB
                dc.b $6A ; j
                dc.b $9B
                dc.b  $C
                dc.b $59 ; Y
                dc.b $85
                dc.b $34 ; 4
                dc.b $71 ; q
                dc.b $89
                dc.b $15
                dc.b $93
                dc.b $6B ; k
                dc.b $C5
                dc.b   7
                dc.b $AC
                dc.b $3C ; <
                dc.b $7F ; 
                dc.b $A4
                dc.b $3E ; >
                dc.b $DA
                dc.b $69 ; i
                dc.b $18
                dc.b $1E
                dc.b $9B
                dc.b $D1
                dc.b $D5
                dc.b $7F ; 

; =============== S U B R O U T I N E =======================================


Rand_Init:                              ; CODE XREF: Intro_Init+312↑p
                movem.l d0-d1/a0-a1,-(sp)
                move.w  d0,d1

                lea     (byte_15FA8).l,a0
                lea     (ram_FF18BE).l,a1
                move.w  #$20,d0
.loc_15FFE:                              ; CODE XREF: Rand_Init+18↓j
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_15FFE

                lea     (ram_FF18BE).l,a0
                move.w  #$20,d0
.loc_1600E:                              ; CODE XREF: Rand_Init+28↓j
                add.w   d1,(a0)+
                dbf     d0,.loc_1600E

                lsl.w   #7,d1
                andi.w  #$1F,d1
                move.w  d1,(ram_FF18FE).l

                addi.w  #$F,d1
                andi.w  #$1F,d1
                move.w  d1,(ram_FF1900).l

                movem.l (sp)+,d0-d1/a0-a1
                rts
; End of function Rand_Init


; =============== S U B R O U T I N E =======================================


Rand_GetWord:
                movem.l d1-d2/a0,-(sp)
                move.w  (ram_FF18FE).l,d1
                lsl.w   #1,d1
                move.w  (ram_FF1900).l,d2
                lsl.w   #1,d2
                lea     (ram_FF18BE).l,a0
                move.w  (a0,d1.w),d0
                add.w   (a0,d2.w),d0
                move.w  d0,(a0,d1.w)
                addq.w  #1,(ram_FF18FE).l
                andi.w  #$1F,(ram_FF18FE).l
                addq.w  #1,(ram_FF1900).l
                andi.w  #$1F,(ram_FF1900).l
                movem.l (sp)+,d1-d2/a0
                rts
; End of function Rand_GetWord


; =============== S U B R O U T I N E =======================================


sub_1607C:
                bsr.s   Rand_GetWord
                lsr.w   #8,d0
                andi.l  #$FF,d0
                rts
; End of function sub_1607C


; =============== S U B R O U T I N E =======================================


sub_16088:                              ; CODE XREF: Intro_Init+318↑p
                move.w  #$563A,(ram_FF1B42).l
                move.w  #$563A,(ram_FF1B44).l
                rts
; End of function sub_16088


; =============== S U B R O U T I N E =======================================


sub_1609A:
                move.w  (ram_FF1B42).l,d0
                lsr.w   #1,d0
                bcc.s   .loc_160A8
                eori.w  #$B400,d0

.loc_160A8:                              ; CODE XREF: sub_1609A+8↑j
                move.w  d0,(ram_FF1B42).l
                rts
; End of function sub_1609A


; =============== S U B R O U T I N E =======================================


sub_160B0:                              ; CODE XREF: MainMenu_GameTick+186↑p
                moveq   #0,d0
                move.w  (ram_FF1B42).l,d0
                lsr.w   #1,d0
                bcc.s   .loc_160C0
                eori.w  #$B400,d0

.loc_160C0:                              ; CODE XREF: sub_160B0+A↑j
                move.w  d0,(ram_FF1B42).l
                divs.w  d2,d0
                swap    d0
                rts
; End of function sub_160B0


; =============== S U B R O U T I N E =======================================


sub_160CC:                              ; CODE XREF: MainMenu_GameTick+18C↑p
                move.w  (ram_FF1B44).l,d0
                lsr.w   #1,d0
                bcc.s   .loc_160DA
                eori.w  #$B400,d0

.loc_160DA:                              ; CODE XREF: sub_160CC+8↑j
                move.w  d0,(ram_FF1B44).l
                rts
; End of function sub_160CC


; =============== S U B R O U T I N E =======================================


sub_160E2:                              ; CODE XREF: Race_Update+7E↑p
                lea     (ram_FF1EAA).l,a1
                btst    #4,$68(a1)
                beq.w   .loc_160FA
                tst.b   $6E(a1)
                bpl.w   .locret_16118

.loc_160FA:                              ; CODE XREF: sub_160E2+C↑j
                move.w  $5C(a1),d0
                add.w   (Race_ram_FrameDelay).l,d0
                cmp.w   (ram_FF18AA).l,d0
                bcs.w   .loc_16114
                move.w  (ram_FF18AA).l,d0

.loc_16114:                              ; CODE XREF: sub_160E2+28↑j
                move.w  d0,$5C(a1)

.locret_16118:                           ; CODE XREF: sub_160E2+14↑j
                rts
; End of function sub_160E2


; =============== S U B R O U T I N E =======================================


sub_1611A:                              ; CODE XREF: Race_Update+148↑p
                move.w  #0,(ram_FF1904).l
                lea     (ram_FF1A08).l,a0
                movea.l (a0)+,a1
                move.l  4(a1),d0
                move.w  $30(a1),d2
                move.l  (a0),-(sp)
                move.l  #$7FFFFFFF,d4

.loc_1613A:                              ; CODE XREF: sub_1611A+54↓j
; sub_1611A+5A↓j
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_16176
                move.l  d0,d1
                sub.l   4(a2),d1
                bpl.w   .loc_16152
                neg.l   d1
.loc_16152:                              ; CODE XREF: sub_1611A+32↑j
                lsr.l   #8,d1
                move.l  d1,d3
                mulu.w  d3,d1
                clr.l   d3
                move.w  d2,d3
                sub.w   $30(a2),d3
                bpl.w   .loc_16166
                neg.w   d3
.loc_16166:                              ; CODE XREF: sub_1611A+46↑j
                move.w  d3,d5
                mulu.w  d5,d3
                add.l   d3,d1
                cmp.l   d4,d1
                bcc.s   .loc_1613A
                move.l  d1,d4
                move.l  a2,(sp)
                bra.s   .loc_1613A


.loc_16176:                              ; CODE XREF: sub_1611A+28↑j
                movea.l (sp)+,a2
                move.l  a2,(ram_FF1908).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_161BE
                move.w  $16(a2),d0
                asl.w   #2,d0
                lea     (unk_25A10).l,a3
                movea.l (a3,d0.w),a3
                move.w  $18(a2),d1
                asl.w   #1,d1
                move.w  $E(a3,d1.w),d1
                ext.l   d1
                swap    d1
                lsr.l   #8,d1
                lsr.l   #6,d1
                move.w  d1,(ram_FF1AA4).l
                move.l  4(a2),d0
                sub.l   4(a1),d0
                move.l  d0,(ram_FF1786).l

.loc_161BE:                              ; CODE XREF: sub_1611A+6A↑j
                tst.w   (ram_FF1ACC).l
                beq.w   .loc_161D2
                jsr     (sub_14FB4).l
                bra.w   .locret_162AE


.loc_161D2:                              ; CODE XREF: sub_1611A+AA↑j
                tst.b   (ram_FF1B22).l
                beq.w   .loc_162AA
                btst    #5,(Race_ram_CurrentButtons).l
                beq.w   .loc_1621E
                btst    #6,$69(a1)
                bne.w   .loc_161FC
                btst    #0,$6B(a1)
                beq.w   .loc_1621E

.loc_161FC:                              ; CODE XREF: sub_1611A+D4↑j
                move.w  (Race_ram_FrameDelay).l,d0
                sub.b   d0,$6D(a1)
                bgt.w   .locret_162AE
                cmpi.b  #0,$6C(a1)
                bne.w   .loc_1622C
                move.b  #0,$6D(a1)
                bra.w   .locret_162AE


.loc_1621E:                              ; CODE XREF: sub_1611A+CA↑j
; sub_1611A+DE↑j
                move.w  (Race_ram_FrameDelay).l,d0
                sub.b   d0,$6D(a1)
                bgt.w   .locret_162AE

.loc_1622C:                              ; CODE XREF: sub_1611A+F6↑j
                addi.b  #1,$6C(a1)
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_16248
                move.w  #1,(ram_FF1904).l
                bsr.w   sub_16520

.loc_16248:                              ; CODE XREF: sub_1611A+11E↑j
                cmpi.b  #3,$6C(a1)
                bpl.w   .loc_16298
                btst    #6,$69(a1)
                bne.w   .loc_16282
                lea     (ram_FF1AB6).l,a4
                btst    #1,$6B(a1)
                beq.w   .loc_16272
                lea     (ram_FF1AC2).l,a4

.loc_16272:                              ; CODE XREF: sub_1611A+14E↑j
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_162AE


.loc_16282:                              ; CODE XREF: sub_1611A+13E↑j
                lea     (ram_FF1ABC).l,a4
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_162AE


.loc_16298:                              ; CODE XREF: sub_1611A+134↑j
                move.b  #0,(ram_FF1B22).l
                bclr    #4,$69(a1)
                bra.w   .locret_162AE


.loc_162AA:                              ; CODE XREF: sub_1611A+BE↑j
                bsr.w   sub_162B0

.locret_162AE:                           ; CODE XREF: sub_1611A+B4↑j
; sub_1611A+EC↑j ...
                rts
; End of function sub_1611A


; =============== S U B R O U T I N E =======================================


sub_162B0:                              ; CODE XREF: sub_1611A:@loc_162AA↑p
                move.b  (Race_ram_CurrentButtons).l,d0
                btst    #5,d0
                beq.w   .locret_1634C
                bset    #4,$69(a1)
                bset    #0,(ram_FF1B22).l
                move.b  #0,$6C(a1)
                move.b  (ram_FF1AB6).l,$6D(a1)
                btst    #1,$6B(a1)
                beq.w   .loc_162EC
                move.b  (ram_FF1AC2).l,$6D(a1)

.loc_162EC:                              ; CODE XREF: sub_162B0+30↑j
                bclr    #0,$6B(a1)
                bclr    #6,$69(a1)
                btst    #0,d0
                beq.w   .loc_1630A
                bset    #0,$6B(a1)
                bra.w   .loc_16320


.loc_1630A:                              ; CODE XREF: sub_162B0+4C↑j
                btst    #1,d0
                beq.w   .loc_16320
                bset    #6,$69(a1)
                move.b  (ram_FF1ABC).l,$6D(a1)

.loc_16320:                              ; CODE XREF: sub_162B0+56↑j
; sub_162B0+5E↑j
                movea.l (ram_FF1908).l,a0
                cmpa.l  #$FFFFFFFF,a0
                beq.w   .locret_1634C
                move.w  $30(a1),d1
                cmp.w   $30(a0),d1
                bpl.w   .loc_16346
                bclr    #5,$69(a1)
                bra.w   .locret_1634C


.loc_16346:                              ; CODE XREF: sub_162B0+88↑j
                bset    #5,$69(a1)

.locret_1634C:                           ; CODE XREF: sub_162B0+A↑j
; sub_162B0+7C↑j ...
                rts
; End of function sub_162B0


sub_1634E:
                lea     (ram_FF1EAA).l,a2
                move.l  4(a1),d0
                sub.l   4(a2),d0
                bmi.w   loc_1636E
                cmp.l   #$40000,d0
                bmi.w   loc_1637E
                bra.w   locret_16456
; ---------------------------------------------------------------------------

loc_1636E:                              ; CODE XREF: sub_1634E+E↑j
                neg.l   d0
                cmp.l   #$10000,d0
                bmi.w   loc_1637E
                bra.w   locret_16456
; ---------------------------------------------------------------------------

loc_1637E:                              ; CODE XREF: sub_1634E+18↑j
; sub_1634E+28↑j
                clr.w   d0
                move.b  (ram_FF1B24).l,d0
                beq.w   locret_16456
                btst    #0,d0
                beq.w   loc_163CC
                bset    #4,$69(a1)
                move.w  $30(a1),d2
                cmp.w   $30(a2),d2
                bmi.w   loc_163AE
                bset    #5,$69(a1)
                bra.w   loc_163B4
; ---------------------------------------------------------------------------

loc_163AE:                              ; CODE XREF: sub_1634E+52↑j
                bclr    #5,$69(a1)

loc_163B4:                              ; CODE XREF: sub_1634E+5C↑j
                btst    #1,d0
                bne.w   loc_163C6
                bclr    #6,$69(a1)
                bra.w   loc_163CC
; ---------------------------------------------------------------------------

loc_163C6:                              ; CODE XREF: sub_1634E+6A↑j
                bset    #6,$69(a1)

loc_163CC:                              ; CODE XREF: sub_1634E+40↑j
; sub_1634E+74↑j
                bra.w   loc_16428
; ---------------------------------------------------------------------------
                btst    #2,d0
                beq.w   loc_163FE
                move.l  4(a1),d2
                sub.l   4(a2),d2
                cmp.l   #$20000,d0
                bpl.w   loc_16428
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                bsr.w   sub_13A92
                bra.w   loc_16428
; ---------------------------------------------------------------------------

loc_163FE:                              ; CODE XREF: sub_1634E+86↑j
                btst    #3,d0
                beq.w   loc_16428
                move.l  4(a2),d2
                sub.l   4(a1),d2
                cmp.l   #$8000,d0
                bpl.w   loc_16428
                bclr    #1,$68(a1)
                bset    #2,$68(a1)
                bsr.w   sub_13A92

loc_16428:                              ; CODE XREF: sub_1634E:loc_163CC↑j
; sub_1634E+98↑j ...
                btst    #4,d0
                beq.w   loc_16440
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d2
                neg.w   d2
                bra.w   loc_16452
; ---------------------------------------------------------------------------

loc_16440:                              ; CODE XREF: sub_1634E+DE↑j
                btst    #5,d0
                beq.w   locret_16456
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d2

loc_16452:                              ; CODE XREF: sub_1634E+EE↑j
                move.w  d2,$46(a1)

locret_16456:                           ; CODE XREF: sub_1634E+1C↑j
; sub_1634E+2C↑j ...
                rts
; End of function sub_1634E


; =============== S U B R O U T I N E =======================================


sub_16458:
                move.l  a4,-(sp)
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,$5A(a1)
                bgt.w   loc_1646E
                move.w  #0,$5A(a1)

loc_1646E:                              ; CODE XREF: sub_16458+C↑j
                btst    #4,$69(a1)
                beq.w   loc_1647C
                bsr.w   sub_16548

loc_1647C:                              ; CODE XREF: sub_16458+1C↑j
                bclr    #2,$69(a1)
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   sub_135F6
                movea.l (sp)+,a4
                cmpa.l  #$FFFFFFFF,a2
                beq.w   loc_164AA
                cmpa.l  (ram_FF1EAA).l,a2
                beq.w   loc_164C0
                movea.l 4(a4),a6
                bra.w   loc_1651C
; ---------------------------------------------------------------------------

loc_164AA:                              ; CODE XREF: sub_16458+3C↑j
                jsr     (sub_13D44).l
                tst.w   (ram_FF18A4).l
                bne.w   locret_1651E
                lea     (ram_FF1EAA).l,a2

loc_164C0:                              ; CODE XREF: sub_16458+46↑j
                cmpa.l  #ram_FF1F2A,a1
                beq.w   loc_16518
                btst    #4,$69(a1)
                bne.w   loc_16518
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   loc_164E2
                neg.l   d0

loc_164E2:                              ; CODE XREF: sub_16458+84↑j
                movea.l (ram_FF1A68).l,a5
                move.w  0.w(a5),d6
                ext.l   d6
                swap    d6
                cmp.l   d6,d0
                bmi.w   loc_164FE
                movea.l 8(a4),a6
                bra.w   loc_1651C
; ---------------------------------------------------------------------------
loc_164FE:                              ; CODE XREF: sub_16458+9A↑j
                cmpa.l  (ram_FF1908).l,a1
                bne.w   loc_16510
                tst.w   $5A(a1)
                ble.w   loc_16518
loc_16510:                              ; CODE XREF: sub_16458+AC↑j
                movea.l 8(a4),a6
                bra.w   loc_1651C
; ---------------------------------------------------------------------------
loc_16518:                              ; CODE XREF: sub_16458+6E↑j
; sub_16458+78↑j ...
                movea.l $C(a4),a6
loc_1651C:                              ; CODE XREF: sub_16458+4E↑j
; sub_16458+A2↑j ...
                jsr     (a6)
locret_1651E:                           ; CODE XREF: sub_16458+5E↑j
                rts
; End of function sub_16458

; =============== S U B R O U T I N E =======================================


sub_16520:                              ; CODE XREF: sub_1611A+12A↑p
; sub_16548+2E↓p
                cmpi.b  #1,$6C(a1)
                bne.w   .locret_16546
                btst    #1,$6B(a1)
                beq.w   .locret_16546
                btst    #6,$69(a1)
                bne.w   .locret_16546
                move.b  #$E,(ram_FF1AD7).l

.locret_16546:                           ; CODE XREF: sub_16520+6↑j
; sub_16520+10↑j ...
                rts
; End of function sub_16520


; =============== S U B R O U T I N E =======================================


sub_16548:
                move.w  #0,(ram_FF1906).l
                move.w  (Race_ram_FrameDelay).l,d0
                sub.b   d0,$6D(a1)
                bgt.w   .locret_165CE
                addi.b  #1,$6C(a1)
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_16578
                move.w  #1,(ram_FF1906).l
                bsr.s   sub_16520

.loc_16578:                              ; CODE XREF: sub_16548+22↑j
                cmpi.b  #3,$6C(a1)
                bpl.w   .loc_165C8
                btst    #6,$69(a1)
                bne.w   .loc_165B2
                lea     (unk_257E8).l,a4
                btst    #1,$6B(a1)
                beq.w   .loc_165A2
                lea     (unk_257E2).l,a4

.loc_165A2:                              ; CODE XREF: sub_16548+50↑j
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_165CE


.loc_165B2:                              ; CODE XREF: sub_16548+40↑j
                lea     (unk_257EE).l,a4
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_165CE


.loc_165C8:                              ; CODE XREF: sub_16548+36↑j
                bclr    #4,$69(a1)

.locret_165CE:                           ; CODE XREF: sub_16548+12↑j
; sub_16548+66↑j ...
                rts
; End of function sub_16548


; =============== S U B R O U T I N E =======================================


sub_165D0:
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   sub_1384C
                bsr.w   sub_131BE
                rts
; End of function sub_165D0


; =============== S U B R O U T I N E =======================================


sub_165E0:                              ; CODE XREF: sub_16624↓p
                move.b  $72(a1),d0
                ext.w   d0
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                bsr.w   sub_1384C
                btst    #5,$68(a1)
                beq.w   .loc_1660C
                bset    #2,$68(a1)
                bclr    #1,$68(a1)

.loc_1660C:                              ; CODE XREF: sub_165E0+1C↑j
                bsr.w   sub_13A92
                rts
; End of function sub_165E0


; =============== S U B R O U T I N E =======================================


sub_16612:                              ; CODE XREF: sub_1662C+E↓p
; sub_166B0+18↓p
                bsr.w   sub_16732
                move.w  d1,-(sp)
                bsr.w   sub_131BE
                move.w  (sp)+,d1
                bsr.w   sub_1333C
                rts
; End of function sub_16612


; =============== S U B R O U T I N E =======================================


sub_16624:
                bsr.s   sub_165E0
                bsr.w   sub_16732
                rts
; End of function sub_16624


; =============== S U B R O U T I N E =======================================


sub_1662C:                              ; CODE XREF: sub_16644+14↓p
                jsr     (Rand_GetWord).l
                btst    #0,d0
                bne.w   .loc_1663E
                bsr.s   sub_16612
                rts


.loc_1663E:                              ; CODE XREF: sub_1662C+A↑j
                bsr.w   sub_1666A
                rts
; End of function sub_1662C


; =============== S U B R O U T I N E =======================================


sub_16644:
                move.l  4(a1),d0
                sub.l   (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                cmp.l   #$C000,d0
                bpl.w   .loc_1665C
                bsr.s   sub_1662C
                rts

.loc_1665C:                              ; CODE XREF: sub_16644+10↑j
                move.w  #$FFC0,d1
                bsr.w   sub_1333C
                bsr.w   sub_131BE
                rts
; End of function sub_16644


; =============== S U B R O U T I N E =======================================


sub_1666A:                              ; CODE XREF: sub_1662C:@loc_1663E↑p
                bsr.w   sub_131BE
                move.l  (ram_FF1786).l,d0
                movea.l (ram_FF1A68).l,a4
                btst    #4,$68(a1)
                beq.w   .loc_1668E
                move.w  8(a4),$5A(a1)
                bra.w   .loc_1669A


.loc_1668E:                              ; CODE XREF: sub_1666A+16↑j
                move.w  2(a4),d7
                ext.l   d7
                cmp.l   d7,d0
                bmi.w   .loc_166A6

.loc_1669A:                              ; CODE XREF: sub_1666A+20↑j
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   sub_1384C
                rts


.loc_166A6:                              ; CODE XREF: sub_1666A+2C↑j
                move.w  #0,d1
                bsr.w   sub_1333C
                rts
; End of function sub_1666A


; =============== S U B R O U T I N E =======================================


sub_166B0:
                move.l  (ram_FF1786).l,d0
                movea.l (ram_FF1A68).l,a4
                move.w  2(a4),d7
                ext.l   d7
                cmp.l   d7,d0
                bpl.w   .loc_166CE
                bsr.w   sub_16612
                rts


.loc_166CE:                              ; CODE XREF: sub_166B0+14↑j
                move.w  #0,d1
                bsr.w   sub_1333C
                bsr.w   sub_131BE
                rts
; End of function sub_166B0


; =============== S U B R O U T I N E =======================================


sub_166DC:
                lea     (ram_FF1EAA).l,a2
                move.w  #0,d1
                bsr.w   sub_1333C
                bsr.w   sub_13292
                rts
; End of function sub_166DC


; =============== S U B R O U T I N E =======================================


sub_166F0:
                bclr    #2,$69(a1)
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   sub_135F6
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_16720
                cmpa.l  #ram_FF1EAA,a2
                beq.w   .loc_16720
                bsr.w   sub_13422
                bsr.w   sub_131BE
                bra.w   .locret_16730


.loc_16720:                              ; CODE XREF: sub_166F0+16↑j
; sub_166F0+20↑j
                bsr.w   sub_16732
                move.w  d1,-(sp)
                bsr.w   sub_131BE
                move.w  (sp)+,d1
                bsr.w   sub_1333C

.locret_16730:                           ; CODE XREF: sub_166F0+2C↑j
                rts
; End of function sub_166F0


; =============== S U B R O U T I N E =======================================


sub_16732:                              ; CODE XREF: sub_16612↑p
; sub_16624+2↑p ...
                btst    #4,$69(a1)
                bne.w   .locret_1685E
                lea     (ram_FF1EAA).l,a2
                move.w  $4A(a1),d1
                add.w   $4A(a2),d1
                move.w  d1,d2
                addi.w  #$10,d1
                addq.w  #8,d2
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   .loc_16760
                neg.l   d0

.loc_16760:                              ; CODE XREF: sub_16732+28↑j
                movea.l (ram_FF1A68).l,a4
                move.w  2(a4),d7
                ext.l   d7
                cmp.l   d7,d0
                bpl.w   .loc_16858
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                bpl.w   .loc_167EC
                neg.w   d0
                cmp.w   d1,d0
                bpl.w   .loc_16858
                move.w  8(a4),$5A(a1)
                move.b  #0,$6C(a1)
                bclr    #0,$6B(a1)
                bset    #4,$69(a1)
                bset    #5,$69(a1)
                cmp.w   d2,d0
                bpl.w   .loc_167BC
                bset    #6,$69(a1)
                move.b  (ram_FF1ABC).l,$6D(a1)
                bra.w   .locret_1685E


.loc_167BC:                              ; CODE XREF: sub_16732+74↑j
                bclr    #6,$69(a1)
                move.b  (ram_FF1AB6).l,$6D(a1)
                move.w  (ram_FF1E9C).l,d0
                andi.b  #1,d0
                or.b    d0,$6B(a1)
                btst    #1,$6B(a1)
                beq.w   .locret_1685E
                move.b  #$3C,$6D(a1) ; '<'
                bra.w   .locret_1685E


.loc_167EC:                              ; CODE XREF: sub_16732+48↑j
                cmp.w   d1,d0
                bpl.w   .loc_16858
                move.w  8(a4),$5A(a1)
                move.b  #0,$6C(a1)
                bclr    #0,$6B(a1)
                bset    #4,$69(a1)
                bclr    #5,$69(a1)
                cmp.w   d2,d0
                bpl.w   .loc_16828
                bset    #6,$69(a1)
                move.b  (ram_FF1ABC).l,$6D(a1)
                bra.w   .locret_1685E


.loc_16828:                              ; CODE XREF: sub_16732+E0↑j
                bclr    #6,$69(a1)
                move.b  (ram_FF1AB6).l,$6D(a1)
                move.w  (ram_FF1E9C).l,d0
                andi.b  #1,d0
                or.b    d0,$6B(a1)
                btst    #1,$6B(a1)
                beq.w   .locret_1685E
                move.b  #$3C,$6D(a1) ; '<'
                bra.w   .locret_1685E


.loc_16858:                              ; CODE XREF: sub_16732+3C↑j
; sub_16732+50↑j ...
                bclr    #4,$69(a1)

.locret_1685E:                           ; CODE XREF: sub_16732+6↑j
; sub_16732+86↑j ...
                rts
; End of function sub_16732

    include "animation.asm"

; =============== S U B R O U T I N E =======================================


sub_169B0:                              ; CODE XREF: Race_Init+62↑p
                movem.l d0/a0,-(sp)
                move.w  (Menu_ram_CurrentTrackId).l,d0
                asl.w   #1,d0
                lea     (off_16AB0).l,a0
                move.l  (a0,d0.w),(ram_FF1A6C).l
                movem.l (sp)+,d0/a0
                movea.l (RaceTrack_Data2).l,a2
                movea.l (RaceTrack_Data3).l,a3
                lea     (ram_FFDC58).l,a1
                move.w  #$7F,d1
                jsr     (sub_9FE4).l
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                asl.w   #1,d0
                movea.l (ram_FF1A6C).l,a0
                move.w  (a0,d0.w),d2
                lea     (ram_FFDC58).l,a1
                move.w  #$7F,d0

.loc_16A08:                              ; CODE XREF: sub_169B0+6C↓j
; sub_169B0+7C↓j
                move.b  (a1),d1
                ext.w   d1
                bpl.w   .loc_16A24
                neg.w   d1
                mulu.w  d2,d1
                swap    d1
                neg.w   d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A08
                bra.w   .locret_16A30


.loc_16A24:                              ; CODE XREF: sub_169B0+5C↑j
                mulu.w  d2,d1
                swap    d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A08

.locret_16A30:                           ; CODE XREF: sub_169B0+70↑j
                rts
; End of function sub_169B0


; =============== S U B R O U T I N E =======================================


sub_16A32:                              ; CODE XREF: RESET+7E6AE↓p
                addq.w  #1,d0
                cmp.w   #3,d0
                ble.w   .loc_16A44
                move.w  #0,d0
                bra.w   .loc_16A46


.loc_16A44:                              ; CODE XREF: sub_16A32+6↑j
                asl.w   #7,d0

.loc_16A46:                              ; CODE XREF: sub_16A32+E↑j
                lea     (ram_FFDC58).l,a1
                adda.w  d0,a1
                move.l  a1,-(sp)
                move.l  #$80,d0
                movea.l (RaceTrack_Data2).l,a2
                movea.l (RaceTrack_Data3).l,a3
                move.w  #$3F,d1 ; '?'
                jsr     (sub_A04A).l
                movea.l (sp)+,a1
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                asl.w   #1,d0
                movea.l (ram_FF1A6C).l,a0
                move.w  (a0,d0.w),d2
                move.w  #$3F,d0 ; '?'

.loc_16A86:                              ; CODE XREF: sub_16A32+68↓j
; sub_16A32+78↓j
                move.b  (a1),d1
                ext.w   d1
                bpl.w   .loc_16AA2
                neg.w   d1
                mulu.w  d2,d1
                swap    d1
                neg.w   d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A86
                bra.w   .locret_16AAE


.loc_16AA2:                              ; CODE XREF: sub_16A32+58↑j
                mulu.w  d2,d1
                swap    d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A86

.locret_16AAE:                           ; CODE XREF: sub_16A32+6C↑j
                rts
; End of function sub_16A32



off_16AB0:      dc.l word_16AC4         ; DATA XREF: sub_169B0+C↑o
                dc.l word_16ACE
                dc.l word_16AD8
                dc.l word_16AE2
                dc.l word_16AEC
word_16AC4:     dc.w $B333              ; DATA XREF: ROM:off_16AB0↑o
                dc.w $CCCC
                dc.w $D999
                dc.w $D999
word_16ACC:     dc.w $D999
word_16ACE:     dc.w $B333              ; DATA XREF: ROM:00016AB4↑o
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
                dc.w $E666
word_16AD8:     dc.w $B333              ; DATA XREF: ROM:00016AB8↑o
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
word_16AE0:     dc.w $E666
word_16AE2:     dc.w $A666              ; DATA XREF: ROM:00016ABC↑o
                dc.w $B333
                dc.w $C000
                dc.w $C000
                dc.w $C000
word_16AEC:     dc.w $B333              ; DATA XREF: ROM:00016AC0↑o
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
                dc.w $E666



; =============== S U B R O U T I N E =======================================


sub_16AF6:                              ; CODE XREF: Race_Update+6E↑p
                btst    #7,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .return
                tst.w   (ram_FF1EA6).l
                beq.w   .loc_16B2E
                move.w  (ram_FF1EA6).l,d0
                sub.w   (Race_ram_FrameDelay).l,d0
                ble.w   .loc_16B26
                move.w  d0,(ram_FF1EA6).l
                bra.w   .return


.loc_16B26:                              ; CODE XREF: sub_16AF6+22↑j
                move.w  #0,(ram_FF1EA6).l

.loc_16B2E:                              ; CODE XREF: sub_16AF6+12↑j
                cmpi.w  #6,(ram_FF1A06).l
                bpl.w   .return
                cmpi.w  #6000,(ram_FF1EAA + STRUCT_OFFSET_SPEED).l
                bmi.w   .loc_16B54
                bsr.w   sub_16BD6
                cmpa.l  #$FFFFFFFF,a1
                bne.w   .loc_16B58

.loc_16B54:                              ; CODE XREF: sub_16AF6+4C↑j
                bsr.w   sub_16C1A

.loc_16B58:                              ; CODE XREF: sub_16AF6+5A↑j
                jsr     (Rand_GetWord).l
                andi.w  #$1FF,d0
                move.w  d0,(ram_FF1EA6).l

.return:                           ; CODE XREF: sub_16AF6+8↑j
; sub_16AF6+2C↑j ...
                rts
; End of function sub_16AF6


; =============== S U B R O U T I N E =======================================


sub_16B6A:                              ; CODE XREF: sub_16BD6+16↓p
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .locret_16B9C
                bsr.w   sub_16BC8
                move.w  (ram_FF1E68).l,d1
                addi.w  #$20,d1
                cmp.w   d1,d0
                ble.w   .locret_16B9C
                cmp.w   (RaceTrack_Data1).l,d1
                blt.w   .locret_16B9C
                bsr.w   sub_16E48
                movea.l #$FFFFFFFF,a1
.locret_16B9C:
                rts
; End of function sub_16B6A


; =============== S U B R O U T I N E =======================================


sub_16B9E:
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .locret_16BC6
                bsr.w   sub_16BC8
                move.w  (ram_FF1E68).l,d1
                subi.w  #$10,d1
                cmp.w   d1,d0
                bgt.w   .locret_16BC6
                bsr.w   sub_16E48
                movea.l #$FFFFFFFF,a1
.locret_16BC6:
                rts
; End of function sub_16B9E


; =============== S U B R O U T I N E =======================================


sub_16BC8:
                move.w  STRUCT_OFFSET_66(a1),d0
                mulu.w  (ram_FF1E9C).l,d0
                swap    d0
                rts
; End of function sub_16BC8


; =============== S U B R O U T I N E =======================================


sub_16BD6:
                move.l  a2,-(sp)
                lea     (ram_FF1982).l,a2
                bsr.w   sub_16E54
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_16C16
                bsr.w   sub_16B6A
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_16C16
                cmpa.l  #ram_FF1F2A,a1
                bne.w   .loc_16C0E
                btst    #6,$68(a1)
                bne.w   .loc_16C16
.loc_16C0E:
                bsr.w   sub_16D0A
                bsr.w   sub_16D2A
.loc_16C16:
                movea.l (sp)+,a2
                rts
; End of function sub_16BD6


; =============== S U B R O U T I N E =======================================


sub_16C1A:                              ; CODE XREF: sub_16AF6:@loc_16B54↑p
                move.l  a2,-(sp)
                lea     (ram_FF19C4).l,a2
                bsr.w   sub_16E54
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_16C4A
                bsr.w   sub_16B9E
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .loc_16C4A
                bsr.w   sub_16D0A
                bsr.w   sub_16D60
                bsr.w   sub_16C4E

.loc_16C4A:                              ; CODE XREF: sub_16C1A+12↑j
; sub_16C1A+20↑j
                movea.l (sp)+,a2
                rts
; End of function sub_16C1A


; =============== S U B R O U T I N E =======================================


sub_16C4E:                              ; CODE XREF: sub_16C1A+2C↑p
                movem.l d0-d1/a2,-(sp)
                lea     (unk_25856).l,a0
                lea     (Menu_ram_PlayerAOpponents).l,a2
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_16C6E
                lea     (Menu_ram_PlayerBOpponents).l,a2

.loc_16C6E:                              ; CODE XREF: sub_16C4E+16↑j
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #1,d0
                move.w  (a2,d0.w),d0
                lea     (unk_CCDA).l,a2
                asl.w   #4,d0
                lea     (a2,d0.w),a2
                clr.w   d0
                move.b  5(a2),d0
                mulu.w  #$64,d0 ; 'd'
                move.w  d0,STRUCT_OFFSET_66(a1)
                movem.l (sp)+,d0-d1/a2
                rts
; End of function sub_16C4E


; =============== S U B R O U T I N E =======================================


sub_16C9A:                              ; CODE XREF: sub_12EA2+B6↑p
                move.l  a2,-(sp)
                lea     (ram_FF1982).l,a2
                bsr.w   sub_16E48
                bsr.w   sub_16E26
                movea.l (sp)+,a2
                rts
; End of function sub_16C9A


; =============== S U B R O U T I N E =======================================


sub_16CAE:                              ; CODE XREF: sub_12EA2+A0↑p
                movem.l d0-d1/a2,-(sp)
                cmpa.l  #ram_FF1F2A,a1
                bne.w   .loc_16CE8
                move.w  (Menu_ram_PlayerLevel).l,d0
                cmp.w   (ram_FF1B38).l,d0
                bne.w   .loc_16CDC
                move.w  #0,(ram_FF1B36).l
                move.w  #0,(ram_FF1B34).l

.loc_16CDC:                              ; CODE XREF: sub_16CAE+1A↑j
                move.w  #0,(ram_FF1B38).l
                bra.w   .loc_16CF2


.loc_16CE8:                              ; CODE XREF: sub_16CAE+A↑j
                lea     (ram_FF19C4).l,a2
                bsr.w   sub_16E48

.loc_16CF2:                              ; CODE XREF: sub_16CAE+36↑j
                bsr.w   sub_16E26
                move.l  4(a1),d0
                divu.w  (ram_FF1E9C).l,d0
                move.w  d0,STRUCT_OFFSET_66(a1)
                movem.l (sp)+,d0-d1/a2
                rts
; End of function sub_16CAE


; =============== S U B R O U T I N E =======================================


sub_16D0A:
                move.l  a2,-(sp)
                lea     (ram_FF1A0C).l,a2
.loc_16D12:
                tst.l   (a2)+
                bpl.s   .loc_16D12
                move.l  a1,-4(a2)
                move.l  #$FFFFFFFF,(a2)
                addq.w  #1,(ram_FF1A06).l
                movea.l (sp)+,a2
                rts
; End of function sub_16D0A


; =============== S U B R O U T I N E =======================================


sub_16D2A:
                move.l  a2,-(sp)
                lea     (ram_FF1EAA).l,a2
                move.l  4(a2),d0
                addi.l  #$200000,d0
                move.l  d0,4(a1)
                move.w  STRUCT_OFFSET_66(a1),d0
                move.w  d0,$12(a1)
                bsr.w   sub_16D9A
                bsr.w   sub_13FE6
                cmp.w   $12(a1),d0
                bpl.w   .loc_16D5C
                move.w  d0,$12(a1)
.loc_16D5C:
                movea.l (sp)+,a2
                rts
; End of function sub_16D2A


; =============== S U B R O U T I N E =======================================


sub_16D60:                              ; CODE XREF: sub_16C1A+28↑p
                move.l  a2,-(sp)
                lea     (ram_FF1EAA).l,a2
                move.l  STRUCT_OFFSET_POSX_HIGH(a2),d0
                subi.l  #$100000,d0
                move.l  d0,4(a1)
                move.l  d0,$1E(a1)
                move.w  STRUCT_OFFSET_66(a1),d0
                move.w  d0,$12(a1)
                bsr.w   sub_16D9A
                bsr.w   sub_13FE6
                cmp.w   $12(a1),d0
                bpl.w   .loc_16D96
                move.w  d0,$12(a1)

.loc_16D96:                              ; CODE XREF: sub_16D60+2E↑j
                movea.l (sp)+,a2
                rts
; End of function sub_16D60


; =============== S U B R O U T I N E =======================================


sub_16D9A:                              ; CODE XREF: sub_13CFE+4↑p
; sub_16D2A+1E↑p ...
                lea     (ram_FFDC58).l,a4
                move.l  4(a1),d0
                move.l  d0,$1E(a1)
                andi.w  #$FF,d0
                asl.w   #1,d0
                addi.w  #$C,d0
                andi.w  #$1FF,d0
                move.b  (a4,d0.w),d0
                ext.w   d0
                move.w  d0,$C(a1)
                move.w  d0,8(a1)
                bclr    #4,$68(a1)
                bclr    #0,$68(a1)
                move.w  #0,$2C(a1)
                move.w  (ram_FF18A8).l,$5C(a1)
                move.b  #$FF,$6E(a1)
                move.w  #0,d0
                move.w  d0,$A(a1)
                move.w  d0,$36(a1)
                move.w  d0,$38(a1)
                move.w  d0,$3A(a1)
                move.w  d0,$3C(a1)
                move.w  d0,$2C(a1)
                move.w  d0,2(a1)
                move.w  d0,$32(a1)
                move.w  $30(a1),d0
                bpl.w   .loc_16E16
                neg.w   d0
                move.w  d0,$30(a1)

.loc_16E16:                              ; CODE XREF: sub_16D9A+72↑j
                move.w  d0,$1A(a1)
                move.w  d0,0.w(a1)
                jsr     (sub_13746).l
                rts
; End of function sub_16D9A


; =============== S U B R O U T I N E =======================================


sub_16E26:                              ; CODE XREF: sub_16C9A+C↑p
; sub_16CAE:@loc_16CF2↑p
                movem.l a2-a3,-(sp)
                lea     (ram_FF1A0C).l,a2

.loc_16E30:                              ; CODE XREF: sub_16E26+C↓j
                cmpa.l  (a2)+,a1
                bne.s   .loc_16E30
                movea.l a2,a3
                subq.l  #4,a3

.loc_16E38:                              ; CODE XREF: sub_16E26+14↓j
                move.l  (a2)+,(a3)+
                bpl.s   .loc_16E38
                subq.w  #1,(ram_FF1A06).l
                movem.l (sp)+,a2-a3
                rts
; End of function sub_16E26


; =============== S U B R O U T I N E =======================================


sub_16E48:                              ; CODE XREF: sub_16B6A+28↑p
; sub_16B9E+1E↑p ...
                move.w  (a2),d0
                addq.w  #1,(a2)
                asl.w   #2,d0
                move.l  a1,2(a2,d0.w)
                rts
; End of function sub_16E48


; =============== S U B R O U T I N E =======================================


sub_16E54:
                move.w  (a2),d0
                bne.w   .loc_16E64
                movea.l #$FFFFFFFF,a1
                bra.w   .locret_16E6E
.loc_16E64:
                subq.w  #1,d0
                move.w  d0,(a2)
                asl.w   #2,d0
                movea.l 2(a2,d0.w),a1
.locret_16E6E:
                rts
; End of function sub_16E54
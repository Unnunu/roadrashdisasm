; *************************************************
; race.asm - main gameplay (top-level)
; ROM range: $A4E2-$16E6F; includes race_hud ($D278), road_marking ($E732),
; animation ($16860)
; Status:    partial (top-level flow/init/loop/input; actors/physics/AI TODO)
; API:       Race_Init, Race_GameTick, Race_Update, Race_GetInput, Race_SwapFrames,
;            Race_FinishFrame, Race_UpdateTime, Race_ResetFrameTimers
; *************************************************

; *************************************************
; Function Race_Init
; Full race setup: variables/bike/buffers/HUD/fonts/track assets, road image, actors,
; track data decode, VDP, opponent spawn, track parameters, audio; warm-up frames.
; In:  Menu_ram_Player/CurrentTrackId/PlayerLevel, Menu_ram_BikeIdPlayerA/B
; Out: race state and assets; Race_ram_State=0
; Clobbers: all
; Notes: warm-up runs Race_Update twice and waits two GameTick/frame-ready cycles.
; *************************************************

Race_Init:
                jsr     (Race_InitVariables).l
                jsr     (Race_LoadBikeData).l
                jsr     (Race_ClearFrameBuffers).l
                jsr     (Race_ClearHudCorners).l
                jsr     (Race_LoadHUD).l
                jsr     (Race_InitTrack).l
                jsr     (Race_LoadFonts).l
                jsr     (Race_LoadMoreTrackGfx).l
                jsr     (Race_LoatTrackGfx).l
                jsr     (Race_DrawTopHud).l
                jsr     (Race_LoadRoadImage).l
                jsr     (Race_LoadBikePalette).l
                jsr     (Race_CreateActors).l
                move.w  #0,(ram_FF1EAA + STRUCT_OFFSET_16).l
                jsr     (Race_InitActorLists).l
                jsr     (Race_InitActorPositions).l
                jsr     (TrackData_InitLevel).l
                jsr     (Race_InitVdp).l
                jsr     (Race_SpawnOpponents).l
                jsr     (Race_LoadTrackParams).l
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


; *************************************************
; Function Race_InitAudio
; Initializes the engine/skid audio channels and starts the track song.
; In:  Menu_ram_CurrentTrackId, ram_MusicEnabled
; Out: ram_FF36B6..C2, audio channels; ram_CurrentSong
; Clobbers: d0/d1/a0
; *************************************************

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
; Race VDP setup: H-int on, line scroll, window $3000 (Y=19), SAT $C400,
; H-scroll table $C000.
; In:  -
; Out: VDP registers; first sprite entry cleared
; Clobbers: a0/a1
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


; *************************************************
; Function Race_ClearSprites
; Clears the scroll/sprite work tables (0xB4 entries).
; In:  -
; Out: Intro_TitleScrollTable+$400 / Intro_TitleScrollSpeed+$400
; Clobbers: d0/d1/a0/a1
; *************************************************

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


; *************************************************
; Function Race_DrawTopHud
; Draws the top HUD/border tiles on both planes and palette rows.
; In:  -
; Out: VRAM $4700/$6700, planes $4000/$6000; palette
; Clobbers: d0-d6/a0/a1/a3
; *************************************************

Race_DrawTopHud:
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
; End of function Race_DrawTopHud


; *************************************************
; Function Race_LoatTrackGfx
; Loads the current track's background graphics/palette (RaceTrack_Data6).
; In:  RaceTrack_Data6
; Out: VRAM $1000, planes; palette rows
; Clobbers: d0-d6/a0/a1/a3
; *************************************************

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


; *************************************************
; Function Race_LoadMoreTrackGfx
; Loads additional per-track plane graphics and clears the plane/HScroll regions.
; In:  Menu_ram_CurrentTrackId
; Out: VRAM $8000/$6400/$4400/$6000/$4000; planes
; Clobbers: d0-d6/a0/a1/a3
; *************************************************

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


; *************************************************
; Function Race_ClearFrameBuffers
; Clears the window plane and both HUD frame buffers.
; In:  -
; Out: VRAM $3000; Menu_ram_FrameBuffer/2
; Clobbers: d0/d1/a0
; *************************************************

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
                jsr     (Race_FillHudTile).l
                movea.l #Menu_ram_FrameBuffer2,a0
                jsr     (Race_FillHudTile).l
                rts
; End of function Race_ClearFrameBuffers


; =============== S U B R O U T I N E =======================================


Race_ClearHudCorners:
                movea.l #Menu_ram_FrameBuffer + $AE0,a0 ; x = 48, y = 21
                movea.l #Menu_ram_FrameBuffer2 + $AE0,a1
                move.w  #7,d0
.loc_AB88:
                move.l  #0,(a0)+
                move.l  #0,(a1)+
                dbf     d0,.loc_AB88
                rts
; End of function Race_ClearHudCorners


; =============== S U B R O U T I N E =======================================


Race_FillHudTile:
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
; End of function Race_FillHudTile


; *************************************************
; Function Race_LoadHUD
; Loads/draws the race HUD and player name into both HUD buffers.
; In:  Menu_ram_Player, MenuPassword_ram_StrPlayerA/BName
; Out: VRAM $0/$3E00/$B800; Menu_ram_FrameBuffer/2
; Clobbers: d0-d6/a0/a1/a3
; *************************************************

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


; *************************************************
; Function Race_LoadRoadImage
; Loads the road image, builds the pre-scaled road tile rows and calls sub_D9DA.
; In:  unk_9DDCC
; Out: VRAM $F880/$7800/$7900; ram_FF33CC tiles
; Clobbers: d0-d6/a0/a1/a3
; *************************************************

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


; *************************************************
; Function Race_LoadFonts
; Loads the HUD/digit fonts to VRAM.
; In:  unk_9E3A2/unk_9DB68/unk_9DC4C
; Out: VRAM $B800/$3E80/$BF00/$8300
; Clobbers: d0/a0/a1/a3
; *************************************************

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


Race_WriteVRAMTiles:
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
; End of function Race_WriteVRAMTiles

; *************************************************
; Function WriteToVRAM
; Copies decompressed tile data to VRAM; the first long is the tile count.
; In:  d0 - VRAM address; a0 - [tile count][tile data]
; Out: VRAM
; Clobbers: d0/d1/a0/a1
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


; *************************************************
; Function Race_InitTrack
; Selects the current track record, its per-level word and data streams, and sets the
; initial race state/time/position parameters.
; In:  Menu_ram_CurrentTrackId, Menu_ram_PlayerLevel
; Out: RaceTrack_Data1..6, Race_ram_State/Time*, position/state fields
; Clobbers: d0/a0/a1
; *************************************************

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
                move.w  #$FFFF,(Road_ObjectArray).l
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


; *************************************************
; Function Race_InitVariables
; Clears/sets the race state, timers, sprite/HUD/scroll buffers and player pointers;
; selects the player level and the per-level curve factor.
; In:  Menu_ram_Player, Menu_ram_PlayerA/BLevel
; Out: race RAM state; buffers; ram_FF1ADB
; Clobbers: all
; *************************************************

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
                move.w  #$FFFF,(Road_ObjectArray).l
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


; *************************************************
; Function Race_InitActorLists
; Builds the actor/object pointer tables and counts from unk_25856/unk_2585E.
; In:  -
; Out: ram_FF1A08/ram_FF1982 lists; ram_FF1A06; sentinels
; Clobbers: d0/a1/a2
; *************************************************

Race_InitActorLists:
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
; End of function Race_InitActorLists


; *************************************************
; Function Race_InitActorPositions
; Initializes the actor screen positions/scales (0x1A/0x30 fields) in the list.
; In:  ram_FF1A08 list
; Out: actor structs
; Clobbers: d0-d3/a0/a1
; *************************************************

Race_InitActorPositions:
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
; End of function Race_InitActorPositions


; *************************************************
; Function Race_InitPhysicsConstants
; Initializes the bike/engine/steering physics constants and HUD/scroll defaults.
; In:  -
; Out: ram_FF1AB6/D330/D338, ram_FF1AE8..F4, ram_FF18A8..B6, ram_FF1A9E/A0
; Clobbers: d0/a0/a1
; *************************************************

Race_InitPhysicsConstants:
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
; End of function Race_InitPhysicsConstants


; *************************************************
; Function Race_LoadTrackParams
; Loads per-track parameters from unk_1471A into ram_FF302E..3034.
; In:  Menu_ram_CurrentTrackId
; Out: ram_FF302E/3030/3032/3034
; Clobbers: d0/a0
; *************************************************

Race_LoadTrackParams:
                lea     (unk_1471A).l,a0
                move.w  (Menu_ram_CurrentTrackId).l,d0
                asl.w   #2,d0
                adda.w  d0,a0
                move.w  (a0)+,(ram_FF302E).l
                move.w  (a0)+,(ram_FF3030).l
                move.w  (a0)+,(ram_FF3032).l
                move.w  (a0),(ram_FF3034).l
                rts
; End of function Race_LoadTrackParams


; *************************************************
; Function Race_LoadBikeData
; Loads the selected bike's parameter block and steering/engine values.
; In:  Menu_ram_Player, Menu_ram_BikeIdPlayerA/B
; Out: ram_FF1A70 (0x13 words); ram_FF1AA6/AAA; RaceBike_ram_*; ram_FF1AB2/B4
; Clobbers: d0/d1/a0/a1
; *************************************************

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


; *************************************************
; Function Race_SpawnOpponents
; Expands the track spawn records (RaceTrack_Data5) into the object lists, using the
; per-level thresholds word_B976/word_B980 and the color table off_B98A.
; In:  RaceTrack_Data5, Menu_ram_PlayerLevel
; Out: ram_FFD7D4/ram_FFDBD8 lists; pointers/counts
; Clobbers: d0-d7/a0-a3
; *************************************************

Race_SpawnOpponents:
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
; End of function Race_SpawnOpponents


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

; *************************************************
; Function Race_ResetFrameTimers
; Measures the rendering frame ticks (60 ticks/s) and updates the frame delay.
; In:  Race_ram_FrameCounter
; Out: Race_ram_FrameDelay, ram_FF304C/304E/3050
; Clobbers: d0/d1
; *************************************************

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


; *************************************************
; Function Race_UpdateTime
; Advances the BCD race timer while the player is not finished (player $68 bit7).
; In:  player struct $68; Race_ram_TimeTicks/Seconds/Minutes
; Out: timer fields; ram_FF1E96 frame count
; Clobbers: d0/d1
; *************************************************

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


; *************************************************
; Function Race_GameTick
; Per-frame VDP/input update: VScroll info, H-int state, sprite/HUD/scroll/palette DMA,
; frame swap, pause/demo/end handling.
; In:  Race_ram_State, NextFrameReady/Next* buffers, pad input
; Out: VDP/VRAM; Race_ram_* buffers; ram_UpdateFunction=0 at the end
; Clobbers: all
; *************************************************

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


; *************************************************
; Function Race_SwapFrames
; Switches the next HScroll/SAT/HUD/sprite/VScroll buffers to the other parity.
; In:  Race_ram_NextFrameReady/NextScrollTable/NextHudBuffer/...
; Out: Next* buffers/pointers; Animation_ram_BaseTile/SpriteDestination
; Clobbers: d0/a2
; *************************************************

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


; *************************************************
; Function Race_FinishFrame
; Publishes the current frame, switches the current buffers and rotates the
; alpha/VScroll buffers.
; In:  Race_ram_CurrentFrameReady/Current* buffers
; Out: Current* pointers; Animation_ram_BaseTile; VScroll info
; Clobbers: d0/a2
; *************************************************

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
; Demo input: any button on either pad ends the demo.
; In:  pad input
; Out: Race_ram_GameEnded/DemoGameEnded
; Clobbers: d0
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
; Reads the active pad; updates steering, B/A input bits, pause/start and debounce.
; In:  Race_ram_ActiveController, RaceBike_ram_*; player struct $68
; Out: Race_ram_CurrentButtons; RaceBike_ram_CurrentSteering; player $68 bits
; Clobbers: d0/d1
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


; *************************************************
; Function Race_Update
; Main simulation/render prep: bike damage/end, player/opponent update chain, road
; interpolation, object lists, HUD/road/actor/sprite rendering, finish frame.
; In:  player/actor state, track data, input flags
; Out: next frame buffers; Race_ram_GameEnded; race state fields
; Clobbers: all
; *************************************************

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
                lea     (Road_VisibleObjectList).l,a2
                jsr     (Road_BuildVisibleList).l

                jsr     (sub_14E38).l
                jsr     (sub_DD84).l
                jsr     (sub_EC90).l

                clr.w   (Animation_ram_SpriteIndex).l
                clr.w   (Animation_ram_TileIndex).l
                jsr     (RaceHud_Draw).l

                jsr     (Road_DrawObjects).l
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

.loc_C306:
                move.l  #$7000FFFF,(a1)+
                dbf     d0,.loc_C306
                move.w  #0,d0

.loc_C314:
                move.w  (a0)+,d1
                swap    d1
                move.w  d0,d1
                lea     (ram_FF0586).l,a1
                move.w  #$F,d2

.loc_C324:
                cmp.l   (a1)+,d1
                bpl.w   .loc_C334
                move.l  -4(a1),d3
                move.l  d1,-4(a1)
                move.l  d3,d1

.loc_C334:
                dbf     d2,.loc_C324
                addq.w  #1,d0
                cmp.w   #1,d0
                bne.w   .loc_C348
                addq.w  #1,d0
                lea     2(a0),a0

.loc_C348:
                cmp.w   #$10,d0
                bmi.s   .loc_C314
                rts
; End of function sub_C2FC


; =============== S U B R O U T I N E =======================================


sub_C350:
                movem.l d0-d1/a1,-(sp)
                lea     (ram_FF0586).l,a1
                move.w  #$F,d0

.loc_C35E:
                move.l  (a1),d1
                tst.w   d1
                bmi.w   .loc_C372
                asl.w   #1,d1
                move.w  (a0,d1.w),d1
                move.l  d1,(a1)+
                dbf     d0,.loc_C35E

.loc_C372:
                movem.l (sp)+,d0-d1/a1
                rts
; End of function sub_C350


; =============== S U B R O U T I N E =======================================


Race_SortResults:
                move.w  #$F,d0
                lea     (ram_FF0586).l,a0

.loc_C382:
                move.l  #$FFFFFFFF,(a0)+
                dbf     d0,.loc_C382
                lea     (ram_FF04C8).l,a0
                move.w  #0,d0

.loc_C396:
                move.l  (a0)+,d1
                asl.l   #8,d1
                move.b  d0,d1
                lea     (ram_FF0586).l,a1
                move.w  #$F,d2

.loc_C3A6:
                cmp.l   (a1)+,d1
                bcc.w   .loc_C3B6
                move.l  -4(a1),d3
                move.l  d1,-4(a1)
                move.l  d3,d1

.loc_C3B6:
                dbf     d2,.loc_C3A6
                addq.w  #1,d0
                cmp.w   #1,d0
                bne.w   .loc_C3CA
                addq.w  #1,d0
                lea     4(a0),a0

.loc_C3CA:
                cmp.w   #$10,d0
                bmi.s   .loc_C396
                lea     (ram_FF0586).l,a0
                move.w  #$F,d0
                clr.w   d2

.loc_C3DC:
                move.l  (a0),d1
                move.b  d1,d2
                asr.l   #8,d1
                bmi.w   .loc_C3EC
                divu.w  #6,d1
                swap    d1

.loc_C3EC:
                move.w  d2,d1
                move.l  d1,(a0)+
                dbf     d0,.loc_C3DC
                rts
; End of function Race_SortResults


; =============== S U B R O U T I N E =======================================

sub_C3F6:
                rts
; End of function sub_C3F6


; =============== S U B R O U T I N E =======================================


Race_ComputeResults:
                bsr.w   Race_SortResults
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
                bsr.w   Race_BuildStandings
                bsr.w   Race_UpdateHighScoreTable
                jsr     (MenuPassword_CreatePassword).w
                rts
; End of function Race_ComputeResults


; =============== S U B R O U T I N E =======================================


Race_UpdateHighScoreTable:
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
                jsr     (Race_FormatMoney).l
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
; End of function Race_UpdateHighScoreTable


; =============== S U B R O U T I N E =======================================


Race_FormatMoney:
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
; End of function Race_FormatMoney


; =============== S U B R O U T I N E =======================================


Race_FormatNumber:
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
; End of function Race_FormatNumber


; =============== S U B R O U T I N E =======================================


Race_BuildStandings:
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

.loc_C90E:
                move.l  a0,-(sp)
                move.w  (a1),d0
                andi.w  #$FF,d0
                cmp.w   #$20,d0 ; ' '
                bne.w   .loc_C926
                move.w  #0,d0
                bra.w   .loc_C948


.loc_C926:
                subi.w  #$30,d0 ; '0'
                cmpi.b  #$31,(a1) ; '1'
                bne.w   .loc_C936
                addi.w  #$A,d0

.loc_C936:
                asl.w   #1,d0
                lea     (unk_D1A0).l,a0
                move.w  (a0,d0.w),d0
                mulu.w  (Menu_ram_PlayerLevel).l,d0

.loc_C948:
                movea.l a1,a0
                adda.w  (ram_FF141A).l,a0
                subq.w  #1,a0
                move.l  #'    ',-3(a0)
                move.l  #'    ',-7(a0)
                jsr     (Race_FormatNumber).l
                movea.l (sp)+,a0
                clr.l   d0
                move.w  (a0)+,d0
                move.w  (a0)+,d1
                cmp.w   #$FFFF,d0
                bne.w   .loc_C98C
                move.l  #'   D',$E(a1)
                move.l  #'NF  ',$12(a1)
                bra.w   .loc_C990


.loc_C98C:
                bsr.w   Race_FormatTime

.loc_C990:
                tst.w   d1
                bne.w   .loc_C9B0
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a2
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_C9BC
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a2
                bra.w   .loc_C9BC


.loc_C9B0:
                asl.w   #1,d1
                move.w  (a3,d1.w),d1
                asl.w   #4,d1
                lea     6(a4,d1.w),a2

.loc_C9BC:
                move.l  (a2)+,4(a1)
                move.l  (a2)+,8(a1)
                move.w  (a2)+,$C(a1)
                adda.w  (ram_FF141A).l,a1
                dbf     d3,.loc_C90E
                rts
; End of function Race_BuildStandings


; =============== S U B R O U T I N E =======================================


Race_FormatTime:
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

.locret_CA4E:
                rts
; End of function Race_FormatTime


; =============== S U B R O U T I N E =======================================


Race_LoadBikePalette:
                move.w  (Menu_ram_BikeIdPlayerA).l,d0
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_CA66
                move.w  (Menu_ram_BikeIdPlayerB).l,d0
.loc_CA66:
                lea     (unk_25B70).l,a0
                asl.w   #1,d0
                move.w  (a0,d0.w),(ram_FF36C4).l
                asl.w   #4,d0
                lea     (Shop_BikePalettes).l,a0
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
; End of function Race_LoadBikePalette


; =============== S U B R O U T I N E =======================================


Race_LoadActorPalette:
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
; End of function Race_LoadActorPalette


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
                jsr     (Race_LoadActorPalette).l
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

DmaWriteCRAM:
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


sub_DAE2:
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

.loc_DBB0:
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


.loc_DBF2:
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


.loc_DC20:
                jsr     (sub_102E4).l
                move.w  d1,d0
                addi.w  #$154,d0
                move.w  d0,8(a0)
                bra.w   .loc_DC58


.loc_DC34:
                move.w  #$159,d0
                move.w  d0,8(a0)
                bra.w   .loc_DC58


.loc_DC40:
                move.w  #$15A,d0
                btst    #3,$69(a1)
                beq.w   .loc_DC50
                addq.w  #2,d0

.loc_DC50:
                move.w  d0,8(a0)
                bra.w   *+4


.loc_DC58:
                move.w  (a0),d0
                cmp.w   #$FFE0,d0
                bmi.w   .locret_DC7E
                sub.w   $C(a0),d0
                cmp.w   #$160,d0
                bpl.w   .locret_DC7E
                subi.w  #$200,(a0)
                addi.w  #1,(ram_FFDE72).l
                adda.w  #$14,a0

.locret_DC7E:
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
unk_DD44:       dc.b $BB
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


.loc_E440:
                mulu.w  (ram_FF1AE8).l,d1
                mulu.w  (ram_FF1AEA).l,d2
                mulu.w  (ram_FF1AEE).l,d3
                mulu.w  (ram_FF1AF0).l,d4
                mulu.w  (ram_FF1AF2).l,d5
                mulu.w  (ram_FF1AF4).l,d6

.loc_E464:
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


sub_E5EE:
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

.loc_E62E:
                cmpi.l  #ram_FF1F2A,(a2)+
                bne.w   .loc_E63A
                subq.w  #1,d1

.loc_E63A:
                dbf     d2,.loc_E62E
                bra.w   *+4


.loc_E642:
                addq.w  #1,d1
                move.w  #1,d4

.loc_E648:
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

.loc_E66C:
                cmp.l   (ram_FF14E0).l,d2
                bmi.s   .loc_E648
                move.l  d2,(ram_FF14E0).l
                move.b  $71(a2),d3
                ext.w   d3
                move.w  d3,(ram_FF36AE).l
                movea.l a2,a3
                bra.s   .loc_E648


.loc_E68A:
                cmp.l   (ram_FF14E4).l,d2
                bpl.s   .loc_E648
                move.l  d2,(ram_FF14E4).l
                move.b  $71(a2),d3
                ext.w   d3
                move.w  d3,(ram_FF36B2).l
                movea.l a2,a4
                bra.s   .loc_E648


.loc_E6A8:
                cmp.w   #$A,d1
                bcs.w   .loc_E6B8
                subi.w  #$A,d1
                ori.w   #$10,d1

.loc_E6B8:
                move.w  d1,(ram_FF1B40).l
                move.l  (ram_FF14E4).l,d1
                cmp.l   #$7FFFFFFF,d1
                bne.w   .loc_E6E2
                move.w  #$FFFF,(ram_FF36B2).l
                move.w  #0,(ram_FF36B4).l
                bra.w   .loc_E6F4


.loc_E6E2:
                move.w  $12(a4),d0
                beq.w   .loc_E6EE
                divu.w  d0,d1
                move.w  d1,d0

.loc_E6EE:
                move.w  d0,(ram_FF36B4).l

.loc_E6F4:
                move.l  (ram_FF14E0).l,d1
                cmp.l   #$80000000,d1
                bne.w   .loc_E718
                move.w  #$FFFF,(ram_FF36AE).l
                move.w  #0,(ram_FF36B0).l
                bra.w   .loc_E72C


.loc_E718:
                neg.l   d1
                move.w  $12(a1),d0
                beq.w   .loc_E726
                divu.w  d0,d1
                move.w  d1,d0

.loc_E726:
                move.w  d0,(ram_FF36B0).l

.loc_E72C:
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


sub_EDD0:
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


.loc_EE30:
                neg.w   d4
                mulu.w  d5,d4
                swap    d4
                bpl.w   .loc_EE3C
                addq.w  #1,d4

.loc_EE3C:
                neg.w   d4

.loc_EE3E:
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

.loc_EE68:
                ext.w   d3
                beq.w   .loc_EE82
                bmi.w   .loc_EE7A
                mulu.w  d5,d3
                swap    d3
                bra.w   .loc_EE82


.loc_EE7A:
                neg.w   d3
                mulu.w  d5,d3
                swap    d3
                neg.w   d3

.loc_EE82:
                move.w  d3,(ram_FF1E5A).l
                neg.w   d3
                lsr.w   #8,d5
                neg.w   d5
                move.w  #$1F,d0
                move.w  d0,d1
                asl.w   #1,d1
                move.w  d1,(ram_FF30E0).l
                move.w  #$98,d7

.loc_EEA0:
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


.loc_EED0:
                ext.l   d1
                asl.l   #8,d1
                divu.w  d6,d1
                addi.w  #$4C,d1 ; 'L'

.loc_EEDA:
                move.w  d1,(a4)+
                cmp.w   d7,d1
                bcc.w   .loc_EEEC
                cmp.w   #$100,d6
                blt.w   .loc_EEEC
                move.w  d1,d7

.loc_EEEC:
                move.w  d7,(a6)+
                clr.l   d2
                move.w  d4,d2
                bpl.w   .loc_EF02
                neg.w   d2
                asl.l   #8,d2
                divu.w  d6,d2
                neg.w   d2
                bra.w   .loc_EF0A


.loc_EF02:
                beq.w   .loc_EF0A
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF0A:
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


.loc_EF34:
                beq.w   .loc_EF3C
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF3C:
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


.loc_EF56:
                beq.w   .loc_EF5E
                asl.l   #8,d2
                divu.w  d6,d2

.loc_EF5E:
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

.loc_EF86:
                ext.w   d2
                add.w   d2,d3
                dbf     d0,.loc_EEA0
                movea.l (Race_ram_CurrentAlpha).l,a1
                cmp.w   #$98,d7
                bmi.w   .loc_EFA0
                move.w  #$98,d7

.loc_EFA0:
                move.w  d7,(a1)
                rts
; End of function sub_EDD0


; =============== S U B R O U T I N E =======================================


sub_EFA4:
                lea     (ram_FF1EAA).l,a1
                lea     (ram_FF04C8).l,a2
                btst    #7,$68(a1)
                bne.w   .loc_EFD6
                move.l  (ram_FF1E9A).l,(ram_FF1E9E).l
                move.w  4(a1),(ram_FF1762).l
                move.l  #$FFFFFFFF,(a2)
                bra.w   .loc_EFEE


.loc_EFD6:
                move.l  $62(a1),(ram_FF1E9E).l
                move.w  (RaceTrack_Data1).l,(ram_FF1762).l
                move.l  $62(a1),d0
                move.l  d0,(a2)

.loc_EFEE:
                lea     (ram_FF1A0C).l,a0
                move.w  (ram_FF1A06).l,d7
                subq.w  #2,d7
                bmi.w   .loc_F036

.loc_F000:
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


.loc_F028:
                move.l  $62(a1),d0
                asl.w   #2,d1
                move.l  d0,(a2,d1.w)

.loc_F032:
                dbf     d7,.loc_F000

.loc_F036:
                lea     (ram_FF1982).l,a0
                move.w  (a0)+,d7
                move.w  d7,d6
                asl.w   #2,d6
                adda.w  d6,a0
                subq.w  #1,d7
                bmi.w   .loc_F09E
                move.w  (ram_FF1762).l,d2
                addi.w  #$20,d2 ; ' '

.loc_F054:
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

.loc_F09A:
                dbf     d7,.loc_F054

.loc_F09E:
                lea     (ram_FF19C4).l,a0
                move.w  (a0)+,d7
                move.w  d7,d6
                asl.w   #2,d6
                adda.w  d6,a0
                subq.w  #1,d7
                bmi.w   .locret_F0E2
                move.w  (ram_FF1762).l,d2
                subi.w  #$10,d2

.loc_F0BC:
                jsr     (Rand_GetWord).l
                andi.w  #$1F,d0
                sub.w   d0,d2
                move.w  d2,d0
                movea.l -(a0),a1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_F0DE
                move.b  $71(a1),d1
                bsr.w   sub_F0E4

.loc_F0DE:
                dbf     d7,.loc_F0BC

.locret_F0E2:
                rts
; End of function sub_EFA4


; =============== S U B R O U T I N E =======================================


sub_F0E4:
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


sub_F40C:
                addi.b  #1,(ram_FF1AD9).l
                andi.b  #3,(ram_FF1AD9).l
                addi.b  #1,(ram_FF1ADC).l
                andi.b  #7,(ram_FF1ADC).l
                lea     (Road_ObjectArray).l,a0
                move.w  (ram_FFDE72).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                lea     (ram_FF1A08).l,a2
                move.w  #0,(ram_FF3040).l

.loc_F44C:
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

.loc_F480:
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

.loc_F4CA:
                cmpi.w  #1,(ram_FF3040).l
                bne.w   .loc_F4E0
                cmpi.w  #$FFFF,$56(a1)
                bne.w   .loc_F44C

.loc_F4E0:
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


.loc_F52E:
                bclr    #4,$68(a1)

.loc_F534:
                move.l  4(a1),d0
                move.l  d0,d2
                swap    d0
                sub.w   (ram_FF1E68).l,d0
                bpl.w   .loc_F556
                cmp.w   #$FFF0,d0
                bmi.w   .loc_F69C
                bsr.w   sub_DAE2
                bra.w   .loc_F69C


.loc_F556:
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

.loc_F584:
                bra.w   .loc_F596


.loc_F588:
                neg.w   d1
                asl.l   #8,d1
                tst.w   d2
                beq.w   .loc_F594
                divu.w  d2,d1

.loc_F594:
                neg.w   d1

.loc_F596:
                lea     (ram_FFD338).l,a4
                move.w  #4,d2
                tst.w   (ram_FF3040).l
                beq.w   .loc_F5B4
                lea     (unk_25802).l,a4
                move.w  #3,d2

.loc_F5B4:
                add.w   8(a1),d1
                btst    #5,$68(a1)
                beq.w   .loc_F5C6
                add.w   $40(a1),d1

.loc_F5C6:
                tst.w   d1
                bmi.w   .loc_F5DE

.loc_F5CC:
                cmp.w   -(a4),d1
                bcc.w   .loc_F5F4
                dbf     d2,.loc_F5CC
                move.w  #0,d2
                bra.w   .loc_F5F4


.loc_F5DE:
                neg.w   d1

.loc_F5E0:
                cmp.w   -(a4),d1
                bcc.w   .loc_F5F2
                dbf     d2,.loc_F5E0
                move.w  #0,d2
                bra.w   .loc_F5F4


.loc_F5F2:
                neg.w   d2

.loc_F5F4:
                move.w  d2,$34(a1)
                move.w  d0,$A(a0)
                tst.w   (ram_FF3040).l
                beq.w   .loc_F60E
                bsr.w   sub_108DA
                bra.w   .loc_F64A


.loc_F60E:
                tst.w   (ram_FF1B16).l
                bne.w   .loc_F64E
                cmpa.l  #ram_FF1F2A,a1
                bne.w   .loc_F62A
                bsr.w   sub_10256
                bra.w   .loc_F64A


.loc_F62A:
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_F646
                tst.w   (ram_FF1ACC).l
                beq.w   .loc_F646
                bsr.w   sub_10294
                bra.w   .loc_F64A


.loc_F646:
                bsr.w   sub_100D0

.loc_F64A:
                move.w  d0,8(a0)

.loc_F64E:
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

.loc_F684:
                move.b  $73(a1),d0
                asl.b   #4,d0
                or.b    d0,$A(a0)
                move.w  (a0),d0
                bpl.w   .loc_F69C
                cmp.w   #$FDC4,d0
                bpl.w   .loc_F6AA

.loc_F69C:
                tst.w   (ram_FF1B16).l
                beq.w   .loc_F838
                bra.w   .loc_F71E


.loc_F6AA:
                addi.w  #1,(ram_FFDE72).l
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_F6D6
                cmpi.b  #2,$6E(a1)
                bne.w   .loc_F6D6
                cmpi.w  #8,(ram_FF1B28).l
                bmi.w   .loc_F6D6
                bsr.w   sub_F9C4

.loc_F6D6:
                tst.w   (ram_FF1B16).l
                bne.w   .loc_F704
                btst    #0,$68(a1)
                beq.w   .loc_F6F2
                bsr.w   sub_F90E
                bra.w   .loc_F834


.loc_F6F2:
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

.loc_F79A:
                sub.l   (ram_FF1E68).l,d0
                move.l  d0,(a6,d7.w)
                addi.w  #1,(ram_FFDE72).l
                move.b  $76(a1),d0
                btst    #0,d0
                bne.w   .loc_F7C2
                bclr    #7,$A(a0)
                bra.w   .loc_F7C8


.loc_F7C2:
                bset    #7,$A(a0)

.loc_F7C8:
                btst    #1,d0
                bne.w   .loc_F7DA
                bclr    #3,$A(a0)
                bra.w   .loc_F7E0


.loc_F7DA:
                bset    #3,$A(a0)

.loc_F7E0:
                move.l  4(a1),d0
                move.w  $30(a1),d1
                move.w  $32(a1),d2
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_F802
                subi.w  #1,(ram_FFDE72).l
                bra.w   .loc_F838


.loc_F802:
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

.loc_F834:
                adda.w  #$14,a0

.loc_F838:
                bra.w   .loc_F44C


.loc_F83C:
                move.w  #$FFFF,(a0)
                rts
; End of function sub_F40C


; =============== S U B R O U T I N E =======================================


sub_F842:
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

.loc_F872:
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

.loc_F8BC:
                asl.w   #3,d0
                add.w   (ram_FF1764).l,d0
                move.b  (a4,d0.w),d1
                ext.w   d1
                btst    #7,-$A(a0)
                beq.w   .loc_F8DC
                neg.w   d1
                bset    #7,$A(a0)

.loc_F8DC:
                add.w   $30(a1),d1
                move.w  $32(a1),d2
                move.l  4(a1),d0
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_F8FE
                subi.w  #1,(ram_FFDE72).l
                bra.w   .locret_F90C


.loc_F8FE:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_F90C:
                rts
; End of function sub_F842


; =============== S U B R O U T I N E =======================================


sub_F90E:
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

.loc_F948:
                cmp.w   #4,d0
                bmi.w   .loc_F954
                move.w  #3,d0

.loc_F954:
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


.loc_F9B4:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_F9C2:
                rts
; End of function sub_F90E


; =============== S U B R O U T I N E =======================================


sub_F9C4:
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

.loc_FA46:
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


.loc_FA70:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                or.w    d3,$A(a0)

.locret_FA7E:
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


sub_FA98:
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


.loc_FB10:
                asl.w   #1,d0
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)

.locret_FB1C:
                rts
; End of function sub_FA98


; =============== S U B R O U T I N E =======================================


sub_FB1E:
                lea     (Road_ObjectArray).l,a0
                cmpi.w  #$C,(ram_FF1E68).l
                bpl.w   .loc_FB42
                move.l  #$C0000,d0
                move.l  d0,d1
                sub.l   (ram_FF1E68).l,d1
                bra.w   .loc_FB62


.loc_FB42:
                clr.l   d0
                move.w  (RaceTrack_Data1).l,d0
                swap    d0
                move.l  d0,d1
                sub.l   (ram_FF1E68).l,d1
                bcs.w   .locret_FC0C
                cmp.l   #$1F0000,d1
                bcc.w   .locret_FC0C

.loc_FB62:
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
.loc_FBC6:
                bclr    #3,$A(a0)
                bra.w   .loc_FBD6

                bset    #3,$A(a0)
.loc_FBD6:
                move.w  #$180,d1
                move.w  #0,d2
                bsr.w   sub_FE3A
                tst.w   d0
                bne.w   .loc_FBF4
                subi.w  #1,(ram_FFDE72).l
                bra.w   .loc_FC08


.loc_FBF4:
                move.w  d0,4(a0)
                move.w  d1,(a0)
                move.w  d2,2(a0)
                bset    #7,$B(a0)
                adda.w  #$14,a0

.loc_FC08:
                move.w  #$FFFF,(a0)

.locret_FC0C:
                rts
; End of function sub_FB1E


; =============== S U B R O U T I N E =======================================


sub_FC0E:
                move.w  #0,(ram_FFD7CA).l
                lea     (Road_ObjectArray).l,a0
                move.w  (ram_FFDE72).l,d0
                mulu.w  #$14,d0
                adda.w  d0,a0
                move.l  a0,(ram_FFD7D0).l
                move.l  (ram_FF1E68).l,d0
                movea.l (ram_FFD7CC).l,a1

.loc_FC3A:
                cmpa.l  #ram_FFD7D4,a1
                beq.w   .loc_FC5A
                move.l  -4(a1),d1
                clr.w   d1
                cmp.l   d0,d1
                bcs.w   .loc_FC5A
                subq.l  #4,a1
                move.l  a1,(ram_FFD7CC).l
                bra.s   .loc_FC3A


.loc_FC5A:
                move.l  (a1),d1
                cmp.l   #$FFFFFFFF,d1
                beq.w   .locret_FD6C
                clr.w   d1
                move.l  d1,d2
                sub.l   (ram_FF1E68).l,d2
                bcc.w   .loc_FC82
                addi.l  #4,(ram_FFD7CC).l
                bra.w   .loc_FD62


.loc_FC82:
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


.loc_FCF4:
                bclr    #3,$A(a0)
                bra.w   .loc_FD04

                bset    #3,$A(a0)


.loc_FD04:
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


.loc_FD2E:
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

.loc_FD62:
                addq.w  #4,a1
                bra.w   .loc_FC5A


.loc_FD68:
                move.w  #$FFFF,(a0)

.locret_FD6C:
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
                lea     (Road_ObjectArray).l,a0
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


sub_FE3A:
                movem.l d4-d7/a0-a6,-(sp)
                move.w  d0,d4
                move.l  d0,d3
                move.l  (ram_FF1E68).l,d5
                sub.l   d5,d0
                bpl.w   .loc_FE56
                move.w  #0,d0
                bra.w   .loc_FF78


.loc_FE56:
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

.loc_FEAC:
                neg.w   d7
                bra.w   .loc_FEC0


.loc_FEB2:
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FEC0
                addq.w  #1,d7

.loc_FEC0:
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


.loc_FEE6:
                ext.l   d2
                asl.l   #8,d2
                divu.w  d0,d2
                addi.w  #$4C,d2 ; 'L'

.loc_FEF0:
                bpl.w   .loc_FEF8
                move.w  #1,d2

.loc_FEF8:
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

.loc_FF28:
                neg.w   d7
                bra.w   .loc_FF3C


.loc_FF2E:
                mulu.w  d4,d7
                swap    d7
                btst    #$1F,d7
                beq.w   .loc_FF3C
                addq.w  #1,d7

.loc_FF3C:
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


.loc_FF56:
                beq.w   .loc_FF70
                swap    d1
                divu.w  d0,d1
                bvs.w   .loc_FF68
                lsr.w   #8,d1
                bra.w   .loc_FF70


.loc_FF68:
                move.w  #0,(sp)
                bra.w   .loc_FF74


.loc_FF70:
                subi.w  #$160,d1

.loc_FF74:
                move.w  (sp)+,d0
                move.w  (sp)+,d3

.loc_FF78:
                movem.l (sp)+,d4-d7/a0-a6
                rts
; End of function sub_FE3A


; =============== S U B R O U T I N E =======================================


sub_FF7E:
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

.loc_FFA4:
                move.l  #$2000000,d3
                cmpi.b  #$10,$71(a1)
                bpl.w   .loc_FFBE
                addi.l  #$800000,d3
                bra.w   .loc_FFC4


.loc_FFBE:
                addi.l  #$1000000,d3

.loc_FFC4:
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

.loc_FFF6:
                neg.w   d1
                bra.w   .loc_1000A


.loc_FFFC:
                mulu.w  d4,d1
                swap    d1

.loc_10000:
                btst    #$1F,d1
                beq.w   .loc_1000A
                addq.w  #1,d1

.loc_1000A:
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


.loc_10030:
                asl.l   #8,d1
                divu.w  d0,d1
                addi.w  #$4C,d1 ; 'L'

.loc_10038:
                bpl.w   .loc_10040
                move.w  #1,d1

.loc_10040:
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

.loc_1007A:
                neg.w   d1
                bra.w   .loc_1008E


.loc_10080:
                mulu.w  d4,d1
                swap    d1
                btst    #$1F,d1
                beq.w   .loc_1008E
                addq.w  #1,d1

.loc_1008E:
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


.loc_100AA:
                beq.w   .loc_100C4
                swap    d5
                divu.w  d0,d5
                bvs.w   .loc_100BC
                lsr.w   #8,d5
                bra.w   .loc_100C4


.loc_100BC:
                move.w  #0,d5
                bra.w   .loc_100C8


.loc_100C4:
                subi.w  #$160,d5

.loc_100C8:
                move.w  d5,(a0)
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_FF7E


; =============== S U B R O U T I N E =======================================


sub_100D0:
                move.w  d3,-(sp)
                bset    #7,$B(a0)
                move.w  #0,$12(a0)
                tst.w   $12(a1)
                bne.w   .loc_100EE
                bsr.w   sub_1022E
                bra.w   .loc_101E6


.loc_100EE:
                btst    #2,$6A(a1)
                beq.w   .loc_10110
                move.b  #3,d0
                and.b   $6A(a1),d0
                cmp.b   #2,d0
                bpl.w   .loc_10110
                bsr.w   sub_1081A
                bra.w   .loc_101E6


.loc_10110:
                btst    #4,$69(a1)
                beq.w   .loc_10122
                bsr.w   sub_1030A
                bra.w   .loc_101E6


.loc_10122:
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


.loc_1014E:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bmi.w   .loc_10168
                bne.w   .loc_10170
                tst.w   $C(a1)
                bmi.w   .loc_10170

.loc_10168:
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10170:
                asl.w   #4,d0
                move.w  $A(a1),d1
                move.w  (ram_FF1AC8).l,d3
                cmp.w   d3,d1
                bgt.w   .loc_1018A
                move.w  #0,d1
                bra.w   .loc_1018E


.loc_1018A:
                move.w  #1,d1

.loc_1018E:
                asl.w   #3,d1
                add.w   d1,d0
                move.w  $C(a1),d1
                cmpa.l  #ram_FF1EAA,a1
                beq.w   .loc_101A2
                asl.w   #1,d1

.loc_101A2:
                lea     (ram_FFD33E).l,a4
                move.w  #3,d2
                tst.w   d1
                bmi.w   .loc_101C0

.loc_101B2:
                cmp.w   -(a4),d1
                bcc.w   .loc_101CE
                subq.w  #1,d2
                bne.s   .loc_101B2
                bra.w   .loc_101CE


.loc_101C0:
                neg.w   d1

.loc_101C2:
                cmp.w   -(a4),d1
                bcc.w   .loc_101CC
                subq.w  #1,d2
                bne.s   .loc_101C2

.loc_101CC:
                neg.w   d2

.loc_101CE:
                move.w  d2,d1
                btst    #$F,$A(a0)
                beq.w   .loc_101DC
                neg.w   d1

.loc_101DC:
                addq.w  #3,d1
                move.w  d1,(ram_FF1764).l
                add.w   d1,d0

.loc_101E6:
                move.w  (sp)+,d3
                rts
; End of function sub_100D0


; =============== S U B R O U T I N E =======================================


sub_101EA:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10200
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10200:
                cmp.w   #2,d0
                bmi.w   .loc_1020C
                move.w  #2,d0

.loc_1020C:
                move.w  $12(a1),d1
                cmp.w   #$DAC,d1
                bpl.w   .loc_10228
                cmp.w   #$1F4,d1
                bmi.w   .loc_10228
                addi.w  #$53,d0 ; 'S'
                bra.w   .locret_1022C


.loc_10228:
                addi.w  #$50,d0 ; 'P'

.locret_1022C:
                rts
; End of function sub_101EA


; =============== S U B R O U T I N E =======================================


sub_1022E:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bgt.w   .loc_10244
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10244:
                cmp.w   #2,d0
                bmi.w   .loc_10250
                move.w  #2,d0

.loc_10250:
                addi.w  #$56,d0 ; 'V'
                rts
; End of function sub_1022E


; =============== S U B R O U T I N E =======================================


sub_10256:
                bclr    #7,$B(a0)
                move.w  #0,$12(a0)
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10278
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10278:
                andi.w  #3,d0
                asl.w   #1,d0
                move.w  $A(a1),d1
                cmp.w   (ram_FF1AC8).l,d1
                blt.w   .loc_1028E
                addq.w  #1,d0

.loc_1028E:
                addi.w  #$7F,d0
                rts
; End of function sub_10256


; =============== S U B R O U T I N E =======================================


sub_10294:
                bset    #7,$B(a0)
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_102B0
                neg.w   d0
                bset    #$F,$A(a0)

.loc_102B0:
                cmp.w   #3,d0
                bmi.w   .loc_102BC
                move.w  #2,d0

.loc_102BC:
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


sub_102E4:
                movem.l d0/a4,-(sp)
                move.w  #2,d1
                lea     (ram_FFD33E).l,a4
                tst.w   d0
                bpl.w   .loc_102FA
                neg.w   d0

.loc_102FA:
                cmp.w   -(a4),d0
                bcc.w   .loc_10304
                subq.w  #1,d1
                bne.s   .loc_102FA

.loc_10304:
                movem.l (sp)+,d0/a4
                rts
; End of function sub_102E4


; =============== S U B R O U T I N E =======================================


sub_1030A:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10320
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10320:
                move.w  $C(a1),d1
                lea     (ram_FFD33E).l,a4
                move.w  #2,d2
                tst.w   d1
                bmi.w   .loc_10342

.loc_10334:
                cmp.w   -(a4),d1
                bcc.w   .loc_10350
                subq.w  #1,d2
                bne.s   .loc_10334
                bra.w   .loc_10350


.loc_10342:
                neg.w   d1

.loc_10344:
                cmp.w   -(a4),d1
                bcc.w   .loc_1034E
                subq.w  #1,d2
                bne.s   .loc_10344

.loc_1034E:
                neg.w   d2

.loc_10350:
                move.w  d2,d1
                addq.w  #2,d1
                move.w  d1,(ram_FF1764).l
                btst    #6,$69(a1)
                beq.w   .loc_10370
                move.w  #2,d1
                bsr.w   sub_10762
                bra.w   .locret_10382


.loc_10370:
                bsr.w   sub_10384
                bra.w   .locret_10382

                bclr    #4,$69(a1)
                bsr.w   sub_100D0

.locret_10382:
                rts
; End of function sub_1030A


; =============== S U B R O U T I N E =======================================


sub_10384:
                cmp.w   #2,d0
                ble.w   .loc_10390
                move.w  #2,d0

.loc_10390:
                bne.w   .loc_103CA
                btst    #$F,$A(a0)
                beq.w   .loc_103B4
                btst    #5,$69(a1)
                beq.w   .loc_104DA
                subq.w  #2,d1
                bpl.w   .loc_103B0
                neg.w   d1

.loc_103B0:
                bra.w   .loc_10402


.loc_103B4:
                btst    #5,$69(a1)
                bne.w   .loc_104DA
                subq.w  #2,d1
                bpl.w   .loc_103C6
                neg.w   d1

.loc_103C6:
                bra.w   .loc_10402


.loc_103CA:
                btst    #5,$69(a1)
                beq.w   .loc_103EE
                subq.w  #2,d1
                neg.w   d1
                bpl.w   .loc_103E0
                move.w  #0,d1

.loc_103E0:
                btst    #$F,$A(a0)
                bne.w   .loc_10402
                bra.w   .loc_10450


.loc_103EE:
                subq.w  #2,d1
                bpl.w   .loc_103F8
                move.w  #0,d1

.loc_103F8:
                btst    #$F,$A(a0)
                bne.w   .loc_10450

.loc_10402:
                move.l  a2,-(sp)
                tst.w   d0
                bne.w   .loc_10410
                bset    #$F,$A(a0)

.loc_10410:
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_10446
                bmi.w   .loc_10428
                btst    #1,$6B(a1)
                beq.w   .loc_1043C

.loc_10428:
                btst    #0,$6B(a1)
                beq.w   .loc_1043C
                lea     (unk_106A2).l,a2
                bra.w   .loc_1049A


.loc_1043C:
                lea     (unk_105E2).l,a2
                bra.w   .loc_1049A


.loc_10446:
                lea     (unk_10522).l,a2
                bra.w   .loc_1049A


.loc_10450:
                move.l  a2,-(sp)
                tst.w   d0
                bne.w   .loc_1045E
                bclr    #$F,$A(a0)

.loc_1045E:
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_10494
                bmi.w   .loc_10476
                btst    #1,$6B(a1)
                beq.w   .loc_1048A

.loc_10476:
                btst    #0,$6B(a1)
                beq.w   .loc_1048A
                lea     (unk_10702).l,a2
                bra.w   .loc_1049A


.loc_1048A:
                lea     (unk_10642).l,a2
                bra.w   .loc_1049A


.loc_10494:
                lea     (unk_10582).l,a2

.loc_1049A:
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


.loc_104CA:
                addi.w  #$D8,d1

.loc_104CE:
                move.w  d1,$12(a0)
                movem.l (sp)+,a2
                bra.w   .locret_104E4


.loc_104DA:
                bclr    #4,$69(a1)
                bsr.w   sub_100D0

.locret_104E4:
                rts
; End of function sub_10384


; =============== S U B R O U T I N E =======================================


sub_104E6:
                move.w  d3,-(sp)
                tst.w   $18(a1)
                bne.w   .loc_10502
                tst.w   $12(a1)
                beq.w   .loc_10502
                btst    #1,$68(a1)
                bne.w   .loc_1051A

.loc_10502:
                move.w  $A(a1),d0
                move.w  (ram_FF1AC8).l,d3
                cmp.w   d3,d0
                bgt.w   .loc_1051A
                move.w  #0,d0
                bra.w   .loc_1051E


.loc_1051A:
                move.w  #1,d0

.loc_1051E:
                move.w  (sp)+,d3
                rts
; End of function sub_104E6


unk_10522:      dc.b   0
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
unk_10582:      dc.b   0
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
unk_105E2:      dc.b   0
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
unk_10642:      dc.b   0
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
unk_106A2:      dc.b   0
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
unk_10702:      dc.b   0
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


sub_10762:
                btst    #5,$69(a1)
                beq.w   .loc_1077A
                btst    #$F,$A(a0)
                beq.w   .loc_1079C
                bra.w   .loc_10784


.loc_1077A:
                btst    #$F,$A(a0)
                bne.w   .loc_1079C

.loc_10784:
                cmp.w   #2,d0
                ble.w   .loc_10790
                move.w  #2,d0

.loc_10790:
                move.l  a2,-(sp)
                lea     (word_107EA).l,a2
                bra.w   .loc_107BC


.loc_1079C:
                cmp.w   #1,d0
                ble.w   .loc_107A8
                move.w  #1,d0

.loc_107A8:
                move.l  a2,-(sp)
                lea     (word_10802).l,a2
                tst.w   d0
                bne.w   .loc_107BC
                bset    #$F,$A(a0)

.loc_107BC:
                asl.w   #3,d0
                move.w  $A(a1),d2
                cmp.w   (ram_FF1AC8).l,d2
                ble.w   .loc_107CE
                addq.w  #4,d0

.loc_107CE:
                cmpi.b  #1,$6C(a1)
                beq.w   .loc_107DA
                addq.w  #2,d0

.loc_107DA:
                move.w  (a2,d0.w),d0
                movea.l (sp)+,a2
                bra.w   .locret_107E8

                dc.b $61 ; a
                dc.b   0
                dc.b $FB
                dc.b $9E


.locret_107E8:
                rts
; End of function sub_10762

word_107EA:     dc.w $12C
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
word_10802:     dc.w $12C
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


sub_1081A:
                move.w  (Race_ram_FrameDelay).l,d2
                sub.b   d2,$70(a1)
                bgt.w   .loc_10834
                move.b  #0,$70(a1)
                bclr    #2,$6A(a1)

.loc_10834:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_1084A
                neg.w   d0
                bset    #$F,$A(a0)

.loc_1084A:
                cmp.w   #2,d0
                ble.w   .loc_10856
                move.w  #2,d0

.loc_10856:
                asl.w   #2,d0
                move.w  $A(a1),d2
                cmp.w   (ram_FF1AC8).l,d2
                ble.w   .loc_10868
                addq.w  #2,d0

.loc_10868:
                move.w  $C(a1),d1
                tst.w   d1
                bpl.w   .loc_10874
                neg.w   d1

.loc_10874:
                cmp.w   (ram_FFD33A).l,d1
                bcc.w   .loc_10880
                addq.w  #1,d0

.loc_10880:
                move.w  d0,d1
                btst    #0,$6A(a1)
                beq.w   .loc_10894
                addi.w  #$148,d1
                bra.w   .loc_10898


.loc_10894:
                addi.w  #$13C,d1

.loc_10898:
                move.w  d1,$12(a0)
                lea     (unk_108C2).l,a4
                asl.w   #1,d0
                move.w  (a4,d0.w),d0
                tst.w   $34(a1)
                bne.w   .locret_108C0
                btst    #1,$68(a1)
                bne.w   .locret_108C0
                bset    #$F,$A(a0)

.locret_108C0:
                rts
; End of function sub_1081A


unk_108C2:      dc.b   0
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


sub_108DA:
                move.w  #0,$12(a0)
                cmpa.l  #ram_FF2FAA,a1
                bne.w   .loc_1090C
                move.w  #$87,d0
                btst    #3,$69(a1)
                bne.w   .loc_10902
                bclr    #$F,$A(a0)
                bra.w   .locret_10970


.loc_10902:
                bset    #$F,$A(a0)
                bra.w   .locret_10970


.loc_1090C:
                bclr    #$F,$A(a0)
                move.w  $34(a1),d0
                bpl.w   .loc_10922
                neg.w   d0
                bset    #$F,$A(a0)

.loc_10922:
                asl.w   #2,d0
                move.w  $A(a1),d1
                bpl.w   .loc_10944
                cmp.w   #$FFD0,d1
                blt.w   .loc_1093C
                move.w  #0,d1

.loc_10938:
                bra.w   .loc_10958


.loc_1093C:
                move.w  #$FFFF,d1
                bra.w   .loc_10958


.loc_10944:
                cmp.w   #$20,d1 ; ' '
                bgt.w   .loc_10954
                move.w  #0,d1

.loc_10950:
                bra.w   .loc_10958


.loc_10954:
                move.w  #1,d1

.loc_10958:
                addq.w  #1,d1
                add.w   d1,d0
                btst    #3,$69(a1)
                bne.w   .loc_1096C
                addi.w  #$5F,d0 ; '_'
                rts


.loc_1096C:
                addi.w  #$6F,d0 ; 'o'

.locret_10970:
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


sub_109B6:
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


.loc_10A1A:
                move.w  2(a1),d2
                rol.w   #4,d2
                andi.w  #$F,d2
                addq.w  #1,d2
                move.w  d0,d3
                lsr.w   #8,d3
                andi.w  #$1F,d3

.loc_10A2E:
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

.loc_10A5E:
                addq.w  #1,d3
                mulu.w  d3,d2
                add.w   d2,(ram_FFD7C8).l
                move.w  (a1),d0
                move.w  (ram_FF1E68).l,d1
                sub.w   (ram_FFD7C8).l,d1
                bra.s   .loc_10A1A


.loc_10A78:
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

.loc_10A94:
                andi.w  #1,d5
                ror.w   #2,d5
                btst    #$E,d0
                beq.w   .loc_10AA6
                bset    #$F,d5

.loc_10AA6:
                move.w  2(a1),d6
                lea     (Road_ObjectArray).l,a0
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


.loc_10AE8:
                move.w  d4,d7
                subi.w  #$1BB,d7
                asl.w   #1,d7
                addi.w  #$1BB,d7
                move.w  d7,d4
                addq.w  #1,d4
                swap    d4
                move.w  d7,d4

.loc_10AFC:
                exg     d0,d1
                move.w  d6,d7
                andi.w  #$700,d7
                andi.w  #$FF,d6

.loc_10B08:
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


.loc_10B48:
                move.w  d0,$A(a0)
                or.w    d5,$A(a0)
                or.w    d7,$A(a0)
                ori.w   #$1000,$A(a0)
                move.w  d6,$10(a0)
                tst.w   $12(a0)
                beq.w   .loc_10B6C
                bset    #7,$B(a0)

.loc_10B6C:
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

.loc_10BB2:
                dbf     d3,.loc_10B08

.loc_10BB6:
                addq.w  #4,a1
                move.w  (a1),d1
                cmp.w   #$FFFF,d1
                bne.w   .loc_10BCA
                movea.l (RaceTrack_Data4).l,a1
                move.w  (a1),d1

.loc_10BCA:
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


.loc_10C0A:
                move.w  d4,d7
                subi.w  #$1BB,d7
                asl.w   #1,d7
                addi.w  #$1BB,d7
                move.w  d7,d4
                addq.w  #1,d4
                swap    d4
                move.w  d7,d4

.loc_10C1E:
                clr.w   d5
                move.b  d1,d5
                rol.b   #1,d5
                andi.w  #1,d5
                ror.w   #2,d5
                btst    #$E,d1
                beq.w   .loc_10C36
                bset    #$F,d5

.loc_10C36:
                move.w  2(a1),d6
                move.w  d6,d7
                andi.w  #$700,d7
                andi.w  #$FF,d6
                bra.w   .loc_10B08


.loc_10C48:
                move.w  #$FFFF,(a0)
                rts
; End of function sub_109B6


; =============== S U B R O U T I N E =======================================


sub_10C4E:
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


.loc_10CCA:
                add.l   d5,d7
                bpl.w   .loc_10CD2
                neg.l   d7

.loc_10CD2:
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

.loc_10D20:
                move.w  d6,$C(a0)
                add.w   d6,d0
                bmi.w   .loc_10D32
                cmp.w   #$23C,d0
                bmi.w   .loc_10D38

.loc_10D32:
                suba.w  #$14,a0
                rts


.loc_10D38:
                neg.w   d0
                move.w  d0,(a0)
                addi.w  #1,(ram_FFDE72).l
                rts
; End of function sub_10C4E


; =============== S U B R O U T I N E =======================================


Road_BuildVisibleList:
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
; End of function Road_BuildVisibleList


; =============== S U B R O U T I N E =======================================


sub_10DBE:
                movea.l (Global_ram_PalettePtr).l,a0
                adda.w  #$1A,a0
                lea     (ram_FF1EAA).l,a1
                lea     (ram_FF1AFA).l,a2
                bsr.w   sub_10E00
                rts
; End of function sub_10DBE


; =============== S U B R O U T I N E =======================================


sub_10DDA:
                movea.l (Global_ram_PalettePtr).l,a0
                adda.w  #$5A,a0 ; 'Z'
                movea.l (ram_FF1908).l,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_10DFE
                lea     (ram_FF1B04).l,a2
                bsr.w   sub_10E00

.locret_10DFE:
                rts
; End of function sub_10DDA


; =============== S U B R O U T I N E =======================================


sub_10E00:
                move.w  $12(a1),d0
                beq.w   .loc_10E12
                cmpi.b  #3,$6E(a1)
                bne.w   .loc_10E18

.loc_10E12:
                clr.l   d0
                bra.w   .loc_10E3A


.loc_10E18:
                move.w  (Race_ram_FrameDelay).l,d1
                sub.w   d1,(a2)
                bgt.w   .locret_10E3C
                lsr.w   #8,d0
                subi.w  #$10,d0
                neg.w   d0
                bpl.w   .loc_10E32
                clr.w   d0

.loc_10E32:
                move.w  d0,(a2)+
                move.l  (a2),d0
                swap    d0
                move.l  d0,(a2)

.loc_10E3A:
                move.l  d0,(a0)

.locret_10E3C:
                rts
; End of function sub_10E00


unk_10E3E:      dc.b $18
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


sub_10E66:
                bset    #6,(ram_FF1EAA + STRUCT_OFFSET_68).l
                lea     (ram_FF1A08).l,a2

.loc_10E74:
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

.loc_10E9C:
                move.w  (Race_ram_FrameDelay).l,d2
                muls.w  d2,d1
                move.w  $12(a1),d0
                add.w   d1,d0
                move.w  d0,$12(a1)
                bpl.w   .loc_10EB8
                move.w  #0,$12(a1)

.loc_10EB8:
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


.loc_10EF8:
                bsr.w   sub_113CA
                bsr.w   sub_13EFA
                btst    #4,$68(a1)
                beq.w   .loc_10F14
                btst    #3,$69(a1)
                bne.w   .loc_10F22

.loc_10F14:
                bclr    #3,$68(a1)
                bsr.w   sub_11448
                bra.w   .loc_10F6C


.loc_10F22:
                bsr.w   sub_11940
                bra.w   .loc_10F6C


.loc_10F2A:
                btst    #6,$68(a1)
                bne.w   .loc_10F3C
                bsr.w   sub_1103A
                bra.w   .loc_11034


.loc_10F3C:
                btst    #4,$68(a1)
                beq.w   .loc_10F58
                cmpi.b  #3,$6E(a1)
                bne.w   .loc_10F58
                bsr.w   Race_HandleInputOnFoot
                bra.w   .loc_10F6C


.loc_10F58:
                tst.w   $12(a1)
                beq.w   .loc_10F6C
                bsr.w   sub_113A4
                bsr.w   sub_13EFA
                bsr.w   sub_116E2

.loc_10F6C:
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


.loc_10F9A:
                cmp.w   #$FF20,d1
                bpl.w   .loc_10FD8
                bset    #3,$68(a1)
                bra.w   .loc_10FDE


.loc_10FAC:
                cmp.w   #$360,d1
                bmi.w   .loc_10FC6
                subi.w  #$360,d1
                add.w   d1,$22(a1)
                move.w  #$360,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)

.loc_10FC6:
                cmp.w   #$E0,d1
                bmi.w   .loc_10FD8
                bset    #3,$68(a1)
                bra.w   .loc_10FDE


.loc_10FD8:
                bclr    #3,$68(a1)

.loc_10FDE:
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


.loc_11010:
                bsr.w   sub_11B7A
                bra.w   .loc_1101C


.loc_11018:
                bsr.w   sub_12BD2

.loc_1101C:
                cmpi.b  #$10,$71(a1)
                bpl.w   .loc_11034
                btst    #4,$68(a1)
                beq.w   .loc_11034
                bsr.w   sub_1180C

.loc_11034:
                bra.w   .loc_10E74


.locret_11038:
                rts
; End of function sub_10E66


; =============== S U B R O U T I N E =======================================


sub_1103A:
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

.loc_1107E:
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


sub_112C8:
                move.l  a0,-(sp)
                cmp.w   d2,d1
                bne.w   .loc_112DC
                move.w  #$80,d1
                move.w  #$80,d2
                bra.w   .loc_11304


.loc_112DC:
                bmi.w   .loc_112F4
                ext.l   d2
                swap    d2
                divu.w  d1,d2
                lsr.w   #8,d2
                clr.w   d1
                move.b  #$FF,d1
                sub.b   d2,d1
                bra.w   .loc_11304


.loc_112F4:
                ext.l   d1
                swap    d1
                divu.w  d2,d1
                lsr.w   #8,d1
                clr.w   d2
                move.b  #$FF,d2
                sub.b   d1,d2

.loc_11304:
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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


sub_113A4:
                move.l  $26(a1),d0
                lsr.l   #8,d0
                move.w  8(a1),d1
                muls.w  d1,d0
                asr.l   #8,d0
                btst    #5,$68(a1)
                beq.w   .loc_113C0
                bsr.w   sub_1406A

.loc_113C0:
                move.w  d0,$22(a1)
                add.w   d0,0.w(a1)
                rts
; End of function sub_113A4


; =============== S U B R O U T I N E =======================================


sub_113CA:
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


.loc_113F2:
                tst.b   $6E(a1)
                bmi.w   .loc_11402
                move.w  8(a1),d0
                bra.w   .loc_11406


.loc_11402:
                move.w  d0,8(a1)

.loc_11406:
                add.l   d0,(ram_FF1E5C).l
                sub.l   $36(a1),d0
                exg     d0,d1
                muls.w  d1,d0
                asr.l   #8,d0
                btst    #5,$68(a1)
                beq.w   .loc_11424
                bsr.w   sub_1406A

.loc_11424:
                tst.w   d0
                bpl.w   .loc_11438
                neg.w   d0
                mulu.w  #$D000,d0
                swap    d0
                neg.w   d0
                bra.w   .loc_1143E


.loc_11438:
                mulu.w  #$D000,d0
                swap    d0

.loc_1143E:
                move.w  d0,$22(a1)
                add.w   d0,0.w(a1)
                rts
; End of function sub_113CA


; =============== S U B R O U T I N E =======================================


sub_11448:
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

.loc_1149E:
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

.loc_114F8:
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4
                subq.w  #1,d0
                bmi.w   .loc_11552

.loc_11506:
                move.b  (a4)+,d3
                ext.w   d3
                add.w   d3,d6
                move.b  (a4)+,d5
                cmpa.l  #Race_ram_NextSpriteTileArray,a4
                bmi.w   .loc_1151E
                lea     (ram_FFDC58).l,a4

.loc_1151E:
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

.loc_11548:
                addi.w  #$100,d4
                addq.w  #1,d2
                dbf     d0,.loc_11506

.loc_11552:
                add.w   d7,$3A(a1)
                move.w  6(a1),d0
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_1156C
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_1156E


.loc_1156C:
                mulu.w  d0,d1

.loc_1156E:
                swap    d1
                add.w   d1,d6
                beq.w   .loc_11578
                nop

.loc_11578:
                sub.w   $38(a1),d6
                beq.w   .loc_11582
                nop

.loc_11582:
                move.w  d1,$38(a1)
                move.l  $26(a1),d1
                lsr.l   #8,d1
                muls.w  d6,d1
                beq.w   .loc_11594
                nop

.loc_11594:
                asr.l   #8,d1
                muls.w  #$300,d1
                asr.l   #8,d1
                beq.w   .loc_115A2
                nop

.loc_115A2:
                add.w   d1,$36(a1)
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_115B8
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_115BA


.loc_115B8:
                mulu.w  d0,d1

.loc_115BA:
                swap    d1
                bsr.w   sub_115C6

.loc_115C0:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_11448


; =============== S U B R O U T I N E =======================================


sub_115C6:
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

.loc_11610:
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


.loc_11640:
                mulu.w  d3,d0
                swap    d0

.loc_11644:
                move.w  d0,$2C(a1)
                divu.w  d3,d4
                bne.w   .loc_11652
                move.w  #1,d4

.loc_11652:
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

.loc_11676:
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


.loc_116AA:
                move.w  d1,2(a1)
                move.w  #0,$32(a1)
                btst    #0,$68(a1)
                beq.w   .loc_116D4
                tst.w   $2C(a1)
                beq.w   .loc_116CE
                bsr.w   sub_146AC
                bra.w   .locret_116E0


.loc_116CE:
                bclr    #0,$68(a1)

.loc_116D4:
                move.w  #0,$2E(a1)
                move.w  #0,$2C(a1)

.locret_116E0:
                rts
; End of function sub_115C6


; =============== S U B R O U T I N E =======================================


sub_116E2:
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

.loc_11738:
                cmp.w   #$40,d3 ; '@'
                bpl.w   .loc_11806
                cmp.w   (RaceTrack_Data1).l,d2
                bmi.w   .loc_11762
                btst    #7,$68(a1)
                bne.w   .loc_11762
                bset    #7,$68(a1)
                move.l  (ram_FF1E9A).l,$62(a1)

.loc_11762:
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4

.loc_1176A:
                tst.w   d0
                ble.w   .loc_117C0
                move.b  (a4)+,d3
                ext.w   d3
                add.w   d3,d6
                move.b  (a4)+,d5
                cmpa.l  #Race_ram_NextSpriteTileArray,a4
                bmi.w   .loc_11788
                lea     (ram_FFDC58).l,a4

.loc_11788:
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


.loc_117B6:
                addi.w  #$100,d4
                subq.w  #1,d0
                addq.w  #1,d2
                bra.s   .loc_1176A


.loc_117C0:
                add.w   d7,$3A(a1)
                move.w  6(a1),d0
                move.b  (a4)+,d1
                ext.w   d1
                bpl.w   .loc_117DA
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_117DC


.loc_117DA:
                mulu.w  d0,d1

.loc_117DC:
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


.loc_117FE:
                mulu.w  d0,d1

.loc_11800:
                swap    d1
                bsr.w   sub_115C6

.loc_11806:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_116E2


; =============== S U B R O U T I N E =======================================


sub_1180C:
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

.loc_11858:
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


.loc_11880:
                bsr.w   sub_11940

.loc_11884:
                movea.l (sp)+,a2
                bra.w   *+4


.loc_1188A:
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


.loc_118AE:
                cmp.w   #$360,d1
                bmi.w   .loc_118C0
                move.w  #$360,d1
                sub.w   d1,d3
                move.w  d3,0.w(a1)

.loc_118C0:
                neg.w   d1
                move.w  d1,$30(a1)

.loc_118C6:
                move.l  (sp)+,d1
                move.l  4(a1),d0
                sub.l   d1,d0
                bpl.w   .loc_118E8
                neg.l   d0
                cmp.l   #$A0000,d0
                bmi.w   .loc_11900
                subi.l  #$A0000,d1
                bra.w   .loc_118F8


.loc_118E8:
                cmp.l   #$A0000,d0
                bmi.w   .loc_11900
                addi.l  #$A0000,d1

.loc_118F8:
                move.l  d1,4(a1)
                move.l  d1,$1E(a1)

.loc_11900:
                movem.l (sp)+,d0-d7/a0-a6
                rts
; End of function sub_1180C


; =============== S U B R O U T I N E =======================================


sub_11906:
                movem.l d0/a0-a1,-(sp)
                lea     (unk_258AE).l,a0
                move.b  $71(a1),d0
                ext.w   d0
                asl.w   #2,d0
                movea.l (a0,d0.w),a0
                move.w  #$1F,d0
                movem.l a0-a1,-(sp)

.loc_11924:
                move.l  (a1)+,(a0)+
                dbf     d0,.loc_11924
                movem.l (sp)+,a0-a1
                lsr     $2C(a0)
                move.w  #1,(ram_FF176A).l
                movem.l (sp)+,d0/a0-a1
                rts
; End of function sub_11906


; =============== S U B R O U T I N E =======================================


sub_11940:
                movem.l d0-d7/a0-a6,-(sp)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_1195A
                cmpi.l  #$10000,4(a1)
                blt.w   .loc_11A58

.loc_1195A:
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

.loc_119B0:
                cmp.w   #$40,d3 ; '@'
                bpl.w   .loc_11A58
                andi.w  #$FF,d2
                asl.w   #1,d2
                adda.w  d2,a4

.loc_119C0:
                cmp.w   (RaceTrack_Data1).l,d2
                bmi.w   .loc_119D4
                ext.l   d2
                divu.w  (RaceTrack_Data1).l,d2
                swap    d2

.loc_119D4:
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

.loc_119F6:
                ext.w   d5
                add.w   d5,d7
                addi.w  #$100,d4
                subq.w  #1,d0
                subq.w  #1,d2
                bpl.w   .loc_11A0C
                move.w  (RaceTrack_Data1).l,d2

.loc_11A0C:
                bra.s   .loc_119C0


.loc_11A0E:
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


.loc_11A34:
                mulu.w  d0,d1

.loc_11A36:
                swap    d1
                move.w  d1,$38(a1)
                move.b  1(a4),d1
                ext.w   d1
                bpl.w   .loc_11A50
                neg.w   d1
                mulu.w  d0,d1
                neg.l   d1
                bra.w   .loc_11A52


.loc_11A50:
                mulu.w  d0,d1

.loc_11A52:
                swap    d1
                bsr.w   sub_115C6

.loc_11A58:
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


sub_11B7A:
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

.loc_11BA8:
                ext.w   d0
                move.w  d0,$A(a1)

.loc_11BAE:
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

.loc_11BDC:
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


.loc_11C20:
                jsr     (sub_15538).l
                bsr.w   sub_11906

.loc_11C2A:
                bclr    #7,$6A(a1)
                move.w  $12(a1),d0
                jsr     (sub_1434A).l
                lsr.w   #2,d0
                add.w   d0,(Race_ram_BikeDamage).l

.locret_11C42:
                rts
; End of function sub_11B7A


; =============== S U B R O U T I N E =======================================


sub_11C44:
                tst.w   (ram_FF1B18).l
                beq.w   .loc_11C6A
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,(ram_FF1B18).l
                bgt.w   .locret_11CC6
                move.w  #1,(Race_ram_GameEnded).l
                bra.w   .locret_11CC6


.loc_11C6A:
                lea     (ram_FF1A08).l,a0

.loc_11C70:
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

.loc_11CA2:
                cmp.l   #$60000,d0
                bpl.w   .locret_11CC6
                tst.w   $12(a1)
                bne.w   .locret_11CC6
                move.w  #$12C,(ram_FF1B18).l
                move.w  (ram_FF1B38).l,(ram_FF1B1A).l

.locret_11CC6:
                rts
; End of function sub_11C44


; =============== S U B R O U T I N E =======================================


sub_11CC8:
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


.loc_11D3C:
                move.w  #0,(ram_FF1768).l

.loc_11D44:
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

.loc_11D92:
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_11DFE
                tst.w   (ram_FF1768).l
                bne.w   .loc_11DB0
                cmpa.l  #ram_FF26AA,a2
                bcs.w   .loc_11DC2

.loc_11DB0:
                cmpi.b  #1,$6E(a2)
                bcs.w   .loc_1202E
                bsr.w   sub_1438E
                bra.w   .loc_1202E


.loc_11DC2:
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


.loc_11DFE:
                bsr.w   sub_1487C
                tst.b   (ram_FF1AD6).l
                bne.w   .loc_11E14
                move.b  #9,(ram_FF1AD6).l

.loc_11E14:
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


.loc_11E4A:
                cmpi.b  #3,$6E(a1)
                bmi.w   .loc_11E5A
                move.w  #0,$12(a1)

.loc_11E5A:
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_1202E


.loc_11E6A:
                tst.w   (ram_FF1B1A).l
                bne.w   .loc_11E88
                move.b  #$FF,$6E(a2)
                tst.w   (ram_FF1768).l
                bne.w   .loc_11E88
                bsr.w   sub_11906

.loc_11E88:
                bra.w   .loc_1202E


.loc_11E8C:
                lea     (unk_2589A).l,a0
                move.l  #$6000,(ram_FF3038).l
                move.w  #$37,(ram_FF303C).l ; '7'
                move.w  #$40,(ram_FF303E).l ; '@'

.loc_11EAC:
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


.loc_11EF4:
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


.loc_11F58:
                bsr.w   sub_12070
                btst    #4,$68(a1)
                bne.w   .loc_1202E
                move.l  #$6000,(ram_FF3038).l
                move.w  #$10,(ram_FF303C).l
                move.w  #$40,(ram_FF303E).l ; '@'
                lea     (Road_ObjectArray).l,a0
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

.loc_11FB8:
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


.loc_11FE0:
                move.w  (sp)+,d7
                suba.l  #$14,a0
                move.w  (ram_FF1B0E).l,d0
                cmp.w   #$1BB,d0
                bmi.w   .loc_12010
                cmp.w   #$219,d0
                bmi.w   .loc_12006
                subi.w  #$2F,d0 ; '/'
                bra.w   .loc_12010


.loc_12006:
                subi.w  #$1BB,d0
                lsr.w   #1,d0
                addi.w  #$1BB,d0

.loc_12010:
                subi.w  #$186,d0
                lea     (unk_147FC).l,a4
                move.b  (a4,d0.w),d0
                ext.w   d0
                asl.w   #2,d0
                lea     (unk_14744).l,a4
                movea.l (a4,d0.w),a4
                jsr     (a4)

.loc_1202E:
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


.locret_12066:
                rts


.loc_12068:
                bclr    #4,$68(a1)
                rts
; End of function sub_11CC8


; =============== S U B R O U T I N E =======================================


sub_12070:
                movem.l d0-d7/a0-a7,-(sp)
                movea.l (ram_FFD7D0).l,a0
                suba.w  #$14,a0
                movea.l (ram_FFD7CC).l,a2
                move.l  4(a1),d0
                addi.l  #$6000,d0
                move.l  $1E(a1),d1
                addi.l  #$6000,d1
                lea     (Road_ShapeTable).l,a6
                lea     (unk_14764).l,a5

.loc_120A4:
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


.loc_120C8:
                cmp.l   d2,d1
                bpl.w   .loc_12162

.loc_120CE:
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


.loc_12134:
                sub.w   d3,d2
                move.w  d2,(ram_FF1B14).l
                sub.w   $4E(a1),d2
                cmp.w   $30(a1),d2
                bpl.w   .loc_120A4

.loc_12148:
                cmp.w   $32(a1),d5
                bmi.w   .loc_120A4
                move.w  4(a5,d4.w),d4
                asl.w   #2,d4
                lea     (unk_14744).l,a4
                movea.l (a4,d4.w),a4
                jsr     (a4)

.loc_12162:
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


sub_1218C:
                lea     (ram_FF1A0C).l,a0

.loc_12192:
                movea.l (a0)+,a1
                cmpa.l  #$FFFFFFFF,a1
                beq.w   .locret_123A6
                btst    #4,$68(a1)
                beq.w   .loc_121B4
                tst.b   $6E(a1)
                bmi.s   .loc_12192
                bclr    #4,$68(a1)

.loc_121B4:
                btst    #6,$68(a1)
                beq.s   .loc_12192
                move.w  #0,(ram_FF1768).l
                move.l  a0,-(sp)
                tst.b   (ram_FF1EAA + STRUCT_OFFSET_6E).l
                bmi.w   .loc_121DA
                movea.l #ram_FF26AA,a2
                bra.w   .loc_121E6


.loc_121DA:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_12288

.loc_121E6:
                btst    #6,$68(a2)
                beq.s   .loc_121DA
                tst.b   $6E(a1)
                bmi.w   .loc_121FE
                move.w  #1,(ram_FF1768).l

.loc_121FE:
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

.loc_12234:
                tst.w   (ram_FF1768).l
                beq.w   .loc_1224E
                move.w  $12(a2),d0
                add.w   $12(a1),d0
                cmp.w   #$FA0,d0
                ble.w   .loc_1226A

.loc_1224E:
                cmpi.w  #$7D0,$12(a2)
                bgt.w   .loc_12272
                cmpa.l  #ram_FF26AA,a2
                bcc.w   .loc_1226A
                tst.b   $6E(a2)
                bmi.w   .loc_12272

.loc_1226A:
                bsr.w   sub_1438E
                bra.w   .loc_12388


.loc_12272:
                bsr.w   sub_1487C
                tst.w   (ram_FF1768).l
                bne.w   .loc_12284
                bsr.w   sub_11906

.loc_12284:
                bra.w   .loc_12388


.loc_12288:
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


.loc_122DC:
                bsr.w   sub_14486
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                tst.w   (ram_FF1768).l
                bne.w   .loc_122FA
                bsr.w   sub_11906

.loc_122FA:
                lea     (unk_2589A).l,a0
                move.l  #$6000,(ram_FF3038).l
                move.w  #$37,(ram_FF303C).l ; '7'
                move.w  #$40,(ram_FF303E).l ; '@'

.loc_1231A:
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


.loc_12356:
                bsr.w   sub_14486
                btst    #4,$68(a1)
                beq.w   .loc_12384
                move.w  #0,$54(a1)
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                tst.w   (ram_FF1768).l
                bne.w   .loc_12388
                bsr.w   sub_11906

.loc_12384:
                bsr.w   sub_12070

.loc_12388:
                btst    #4,$68(a1)
                bne.w   .loc_123A0
                tst.b   $6E(a1)
                bmi.w   .loc_123A0
                bset    #4,$68(a1)

.loc_123A0:
                movea.l (sp)+,a0
                bra.w   .loc_12192


.locret_123A6:
                rts
; End of function sub_1218C


; =============== S U B R O U T I N E =======================================


sub_123A8:
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

.loc_12406:
                add.l   d1,d0
                move.l  d0,4(a2)
                move.w  $12(a1),$12(a2)

.locret_12412:
                rts
; End of function sub_123A8


; =============== S U B R O U T I N E =======================================


sub_12414:
                cmp.w   $E(a0),d1
                bcs.w   .loc_124DA
                cmp.w   $E(a0),d0
                bcs.w   .loc_12428
                bra.w   .loc_124DA


.loc_12428:
                move.w  $10(a0),d2
                andi.w  #$F,d2
                asl.w   #6,d2
                btst    #$E,$A(a0)
                beq.w   .loc_1243E
                neg.w   d2

.loc_1243E:
                lea     (Road_ShapeTable).l,a2
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

.loc_12484:
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


.loc_124AE:
                sub.w   d0,d2
                add.w   $4E(a1),d3
                bclr    #1,$69(a1)
                cmp.w   d3,d2
                bmi.w   .loc_124C4
                bra.w   .loc_124DA


.loc_124C4:
                cmp.w   $32(a1),d5
                bmi.w   .loc_124DA
                move.w  d2,(ram_FF1B14).l
                bset    #4,$68(a1)
                rts


.loc_124DA:
                bclr    #4,$68(a1)
                rts
; End of function sub_12414


; =============== S U B R O U T I N E =======================================


sub_124E2:
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


.loc_1251A:
                bclr    #0,$69(a1)
                move.l  4(a1),d0
                addi.l  #$6000,d0
                cmp.l   4(a2),d0
                bcc.w   .loc_12536
                bra.w   .loc_1280A


.loc_12536:
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


.loc_125A8:
                bsr.w   sub_12B24
                move.w  d0,$50(a1)

.loc_125B0:
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


.loc_12606:
                bsr.w   sub_12B24
                move.w  d0,$50(a2)

.loc_1260E:
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


.loc_1263A:
                move.w  #1,(ram_FF1B16).l
                move.w  d0,$52(a1)
                tst.w   $50(a1)
                beq.w   .loc_12654
                bset    #7,$69(a1)

.loc_12654:
                sub.w   $50(a2),d1
                bmi.w   .loc_1266E
                move.w  #0,d1
                move.w  d1,$52(a2)
                bclr    #7,$69(a2)
                bra.w   .loc_1268A


.loc_1266E:
                move.w  #1,(ram_FF1B16).l
                neg.w   d1
                move.w  d1,$52(a2)
                tst.w   $50(a2)
                beq.w   .loc_1268A
                bset    #7,$69(a2)

.loc_1268A:
                tst.w   (ram_FF1B16).l
                beq.w   .loc_1280A
                bra.w   .loc_127EA


.loc_12698:
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


.loc_126FE:
                bsr.w   sub_12B24
                move.w  d0,$50(a1)

.loc_12706:
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


.loc_1275C:
                bsr.w   sub_12B24
                move.w  d0,$50(a2)

.loc_12764:
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


.loc_12790:
                move.w  #1,(ram_FF1B16).l
                move.w  d0,$52(a1)
                tst.w   $50(a1)
                beq.w   .loc_127AA
                bset    #7,$69(a1)

.loc_127AA:
                add.w   $50(a2),d1
                bpl.w   .loc_127C4
                move.w  #0,d1
                move.w  d1,$52(a2)
                bclr    #7,$69(a2)
                bra.w   .loc_127E0


.loc_127C4:
                move.w  #1,(ram_FF1B16).l
                neg.w   d1
                move.w  d1,$52(a2)
                tst.w   $50(a2)
                beq.w   .loc_127E0
                bset    #7,$69(a2)

.loc_127E0:
                tst.w   (ram_FF1B16).l
                beq.w   .loc_1280A

.loc_127EA:
                move.w  $32(a1),d0
                sub.w   (ram_FF303E).l,d0
                sub.w   $32(a2),d0
                bpl.w   .loc_1280A
                bset    #4,$68(a1)
                bset    #4,$68(a2)
                rts


.loc_1280A:
                bclr    #4,$68(a1)
                bclr    #7,$69(a1)
                bclr    #7,$69(a2)
                rts
; End of function sub_124E2


; =============== S U B R O U T I N E =======================================


sub_1281E:
                lea     (ram_FF1A0C).l,a0

.loc_12824:
                movea.l (a0)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .loc_1283E
                cmpi.b  #$FF,$6E(a1)
                bne.s   .loc_12824
                bclr    #4,$68(a1)
                bra.s   .loc_12824


.loc_1283E:
                lea     (unk_2589A).l,a0

.loc_12844:
                movea.l (a0)+,a1
                cmpa.w  #$FFFF,a1
                beq.w   .loc_1285E
                cmpi.b  #$FF,$6E(a1)
                bne.s   .loc_12844
                bclr    #4,$68(a1)
                bra.s   .loc_12844


.loc_1285E:
                bclr    #4,(ram_FF3012).l
                rts
; End of function sub_1281E


; =============== S U B R O U T I N E =======================================


sub_12868:
                lea     (unk_2589A).l,a2

.loc_1286E:
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


.loc_128BE:
                bsr.w   sub_11940

.loc_128C2:
                move.w  $36(a1),d1
                add.w   $38(a1),d1
                move.w  d1,0.w(a1)
                bsr.w   sub_137E4
                bsr.w   sub_12C9A
                jsr     (sub_13DE0).l
                bra.s   .loc_1286E


.locret_128DE:
                rts
; End of function sub_12868


; =============== S U B R O U T I N E =======================================


sub_128E0:
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


.loc_1291A:
                move.b  #2,$73(a1)

.loc_12920:
                tst.w   d0
                bmi.w   .loc_12942
                addq.w  #1,d1
                andi.w  #$7FF,d0
                move.w  d0,$30(a1)
                bset    #3,$69(a1)
                move.w  d0,0.w(a1)
                move.w  d0,$1A(a1)
                bra.w   .loc_1295A


.loc_12942:
                bclr    #3,$69(a1)
                andi.w  #$7FF,d0
                neg.w   d0
                move.w  d0,$30(a1)
                move.w  d0,0.w(a1)
                move.w  d0,$1A(a1)

.loc_1295A:
                move.w  #0,$32(a1)
                move.w  #$1770,$12(a1)
                swap    d1
                clr.w   d1
                move.l  d1,4(a1)
                move.l  d1,$1E(a1)

.locret_12972:
                rts
; End of function sub_128E0


; =============== S U B R O U T I N E =======================================


sub_12974:
                lea     (ram_FF2FAA).l,a1
                cmpi.l  #$708,(ram_FF1E9A).l
                bcc.w   .loc_12992
                bclr    #6,$68(a1)
                bra.w   .locret_12A86


.loc_12992:
                btst    #6,$68(a1)
                beq.w   .locret_12A86
                move.w  $30(a1),d0
                btst    #3,$69(a1)
                beq.w   .loc_129AC
                neg.w   d0

.loc_129AC:
                tst.w   d0
                bpl.w   .loc_12A32
                lea     (unk_2589A).l,a0

.loc_129B8:
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


.loc_129E4:
                btst    #3,$69(a2)
                beq.s   .loc_129B8
                cmp.l   #$100000,d1
                bpl.s   .loc_129B8

.loc_129F4:
                neg.w   d0
                subi.w  #$100,d0
                bmi.w   .loc_12A32
                subi.w  #$100,d0
                bpl.w   .loc_12A16
                move.w  #0,$12(a1)
                move.w  #0,$14(a1)
                bra.w   .loc_12A38


.loc_12A16:
                ext.l   d0
                asl.l   #8,d0
                move.w  $12(a1),d1
                mulu.w  #8,d1
                cmp.l   d1,d0
                blt.w   .loc_12A32
                move.w  #$FFF8,$14(a1)
                bra.w   .loc_12A38


.loc_12A32:
                move.w  #$20,$14(a1) ; ' '

.loc_12A38:
                move.w  $12(a1),d0
                move.w  (Race_ram_FrameDelay).l,d2
                move.w  $14(a1),d1
                mulu.w  d2,d1
                add.w   d1,d0
                bcc.w   .loc_12A5C
                move.w  #0,d0
                move.w  #0,$12(a1)
                bra.w   .loc_12A7C


.loc_12A5C:
                cmp.w   #$1770,d0
                ble.w   .loc_12A68
                move.w  #$1770,d0

.loc_12A68:
                move.w  d0,$12(a1)
                mulu.w  d2,d0
                lsr.l   #8,d0
                btst    #3,$69(a1)
                beq.w   .loc_12A7C
                neg.w   d0

.loc_12A7C:
                move.w  $30(a1),$1A(a1)
                add.w   d0,$30(a1)

.locret_12A86:
                rts
; End of function sub_12974


; =============== S U B R O U T I N E =======================================


sub_12A88:
                cmp.b   #$10,d4
                bpl.w   .loc_12A96
                bsr.w   sub_12A9C
                rts


.loc_12A96:
                bsr.w   sub_12AF8
                rts
; End of function sub_12A88


; =============== S U B R O U T I N E =======================================


sub_12A9C:
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


.loc_12AC0:
                cmp.w   #4,d2
                ble.w   .loc_12ACC
                move.w  #4,d2

.loc_12ACC:
                asl.w   #1,d2
                add.w   d2,d3
                asr.w   #4,d1
                bpl.w   .loc_12AD8
                neg.w   d1

.loc_12AD8:
                cmp.w   #3,d1
                ble.w   .loc_12AE4
                move.w  #3,d1

.loc_12AE4:
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


sub_12AF8:
                cmp.b   #$12,d4
                bpl.w   .loc_12B06
                move.w  #$37,d0 ; '7'
                rts


.loc_12B06:
                move.w  #$60,d0 ; '`'
                rts
; End of function sub_12AF8


; =============== S U B R O U T I N E =======================================


sub_12B0C:
                btst    #1,$6B(a1)
                beq.w   .loc_12B1E
                move.w  #$28,d0 ; '('
                bra.w   .locret_12B22


.loc_12B1E:
                move.w  #$19,d0

.locret_12B22:
                rts
; End of function sub_12B0C


; =============== S U B R O U T I N E =======================================


sub_12B24:
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
unk_12B7C:      dc.b $10
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


sub_12BD2:
                move.w  4(a1),d0
                lea     (ram_FFDC58).l,a4
                move.w  d0,d1
                sub.w   (ram_FF1E68).l,d1
                bpl.w   .loc_12BEA
                neg.w   d1

.loc_12BEA:
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

.loc_12C16:
                ext.w   d1
                move.w  d1,$A(a1)

.loc_12C1C:
                addi.w  #$C,d0
                andi.w  #$1FF,d0
                move.b  2(a4,d0.w),d0
                ext.w   d0
                move.w  d0,$44(a1)
                btst    #2,$69(a1)
                beq.w   .loc_12C3C
                add.w   $46(a1),d0

.loc_12C3C:
                bsr.w   sub_12CCE
                move.w  $C(a1),8(a1)
                move.w  8(a1),d1
                bpl.w   .loc_12C50
                neg.w   d1

.loc_12C50:
                cmp.w   #$7F,d1
                bmi.w   .locret_12C98
                cmpi.b  #$FF,$6E(a1)
                bne.w   .locret_12C98
                btst    #4,$68(a1)
                bne.w   .loc_12C76
                jsr     (sub_15538).l
                bra.w   .loc_12C7C


.loc_12C76:
                jsr     (sub_1555C).l

.loc_12C7C:
                move.b  #0,$6E(a1)
                move.b  #$FF,$6F(a1)
                bset    #4,$68(a1)
                bsr.w   sub_11906
                bclr    #7,$6A(a1)

.locret_12C98:
                rts
; End of function sub_12BD2


; =============== S U B R O U T I N E =======================================


sub_12C9A:
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


sub_12CCE:
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


.loc_12CF4:
                sub.w   d3,d2
                cmp.w   d1,d2
                bmi.w   .loc_12D04
                add.w   d1,$C(a1)
                bra.w   .locret_12D08


.loc_12D04:
                move.w  d0,$C(a1)

.locret_12D08:
                rts
; End of function sub_12CCE


unk_12D0A:      dc.b $FF
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b $B0

; =============== S U B R O U T I N E =======================================


sub_12EA2:
                move.w  #0,(ram_FF1A98).l
                lea     (ram_FF1A08).l,a0
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_12EBC
                addq.w  #4,a0

.loc_12EBC:
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


.loc_12EE4:
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

.loc_12F14:
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


.loc_12F4A:
                cmp.w   #$22,d0 ; '"'
                bmi.w   .loc_12F60
                bclr    #6,$68(a1)
                bsr.w   sub_16C9A
                bra.w   .loc_12FDC


.loc_12F60:
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

.loc_12FA6:
                move.w  STRUCT_OFFSET_66(a1),d0
                cmp.w   (ram_FF1EAA + STRUCT_OFFSET_SPEED).l,d0
                bgt.w   .loc_12FD8
                cmpa.l  (ram_FF1908).l,a1
                beq.w   .loc_12FCE
                move.w  (ram_FF1A98).l,d0
                cmp.w   (ram_FF1A96).l,d0
                bpl.w   .loc_12FD8

.loc_12FCE:
                addi.w  #1,(ram_FF1A98).l
                addq.w  #4,a4

.loc_12FD8:
                movea.l (a4),a6
                jsr     (a6)

.loc_12FDC:
                movea.l (sp)+,a0
                bra.w   .loc_12EBC


.locret_12FE2:
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b $B5
                dc.b $FC
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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


sub_13106:
                lea     (unk_2589A).l,a0

.loc_1310C:
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


.locret_1312E:
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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


sub_131BE:
                lea     (ram_FF1EAA).l,a2
                move.w  $12(a1),d6
                movea.l (ram_FF1A68).l,a4
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_131E0
                cmp.w   STRUCT_OFFSET_66(a1),d6
                bmi.w   .loc_1325E

.loc_131E0:
                sub.w   $12(a2),d6
                move.l  4(a1),d7
                sub.l   4(a2),d7
                bmi.w   .loc_13248
                btst    #4,$68(a2)
                beq.w   .loc_13202
                tst.b   $6E(a2)
                bpl.w   .loc_1325E

.loc_13202:
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


.loc_13248:
                tst.w   d6
                ble.w   .loc_1325E
                neg.l   d7
                divu.w  d6,d7
                mulu.w  #$40,d7 ; '@'
                ext.l   d6
                cmp.l   d6,d7
                bmi.w   .loc_13280

.loc_1325E:
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                btst    #5,$68(a1)
                bne.w   .loc_13280
                bsr.w   sub_13FE6
                cmp.w   $12(a1),d0
                bpl.w   .loc_1328C

.loc_13280:
                bset    #2,$68(a1)
                bclr    #1,$68(a1)

.loc_1328C:
                bsr.w   sub_13A92
                rts
; End of function sub_131BE


; =============== S U B R O U T I N E =======================================


sub_13292:
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


.loc_132F4:
                tst.w   d6
                ble.w   .loc_13308
                divu.w  d6,d7
                mulu.w  #$40,d7 ; '@'
                ext.l   d6
                cmp.l   d6,d7
                bmi.w   .loc_1332A

.loc_13308:
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                btst    #5,$68(a1)
                bne.w   .loc_1332A
                bsr.w   sub_13FE6
                cmp.w   $12(a1),d0
                bpl.w   .loc_13336

.loc_1332A:
                bset    #2,$68(a1)
                bclr    #1,$68(a1)

.loc_13336:
                bsr.w   sub_13A92
                rts
; End of function sub_13292


; =============== S U B R O U T I N E =======================================


sub_1333C:
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


.loc_13364:
                cmp.w   #$C4,d0
                ble.w   .loc_13370
                move.w  #$C4,d0

.loc_13370:
                sub.w   d2,d0
                bmi.w   .loc_13378
                neg.w   d1

.loc_13378:
                add.w   d1,d0
                move.w  $12(a1),d1
                cmpa.l  #ram_FF1F2A,a1
                beq.w   .loc_1338A
                lsr.w   #1,d1

.loc_1338A:
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


.loc_133B8:
                ext.l   d0
                swap    d0
                divs.w  d1,d0
                asr.w   #8,d0

.loc_133C0:
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d1
                tst.w   d0
                bpl.w   .loc_133DC
                neg.w   d1
                cmp.w   d1,d0
                bpl.w   .loc_133E4
                bra.w   .loc_133E2


.loc_133DC:
                cmp.w   d1,d0
                ble.w   .loc_133E4

.loc_133E2:
                move.w  d1,d0

.loc_133E4:
                move.w  d0,$46(a1)
                bset    #2,$69(a1)

.locret_133EE:
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


sub_13422:
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


.loc_1346A:
                move.w  #5,d0
                bra.w   .loc_134BC


.loc_13472:
                tst.w   $30(a1)
                bmi.w   .loc_134F0

.loc_1347A:
                subq.w  #1,d0
                ble.w   .loc_134B0

.loc_13480:
                bsr.w   sub_135F6
                move.l  a2,(ram_FF1892).l
                move.w  (ram_FF1B46).l,(ram_FF1898).l
                move.w  d0,(ram_FF189A).l
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_135D2
                move.w  2(sp),d1
                cmp.w   (ram_FF1B46).l,d1
                beq.s   .loc_1347A

.loc_134B0:
                move.w  (sp),d0

.loc_134B2:
                addq.w  #1,d0
                cmp.w   #7,d0
                bpl.w   .loc_13562

.loc_134BC:
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


.loc_134F0:
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

.loc_1352A:
                move.w  (sp),d0

.loc_1352C:
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

.loc_13562:
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


.loc_135A2:
                cmp.w   (ram_FF1B46).l,d1
                bmi.w   .loc_135C2
                move.w  d1,(ram_FF1B46).l
                movea.l (ram_FF1892).l,a2
                move.w  (ram_FF189A).l,d0
                bra.w   .loc_135D6


.loc_135C2:
                bclr    #1,$68(a1)
                bset    #2,$68(a1)
                bra.w   .locret_135E6


.loc_135D2:
                addq.w  #4,sp
                movea.l (sp)+,a2

.loc_135D6:
                bsr.w   sub_13892
                bset    #1,$68(a1)
                bclr    #2,$68(a1)

.locret_135E6:
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


sub_135F6:
                lea     (ram_FF178A).l,a6
                move.b  (a6,d0.w),d1
                ext.w   d1
                beq.w   .loc_1361E
                move.w  #$F0,(ram_FF1B46).l
                bsr.w   sub_13626
                cmpi.w  #$F0,(ram_FF1B46).l
                blt.w   .locret_13624

.loc_1361E:
                movea.l #$FFFFFFFF,a2

.locret_13624:
                rts
; End of function sub_135F6


; =============== S U B R O U T I N E =======================================


sub_13626:
                move.b  $71(a1),d7
                subq.w  #1,d1
                lea     (ram_FF1792).l,a6
                move.w  d0,d2
                asl.w   #4,d2
                adda.w  d2,a6

.loc_13638:
                move.b  (a6)+,d2
                cmp.b   d7,d2
                beq.w   .loc_136B0
                cmp.b   #$10,d2
                bpl.w   .loc_13656
                lea     (unk_25856).l,a0
                move.w  #0,d6
                bra.w   .loc_13664


.loc_13656:
                lea     (unk_2589A).l,a0
                move.w  #$FFFF,d6
                subi.w  #$10,d2

.loc_13664:
                ext.w   d2
                asl.w   #2,d2
                movea.l (a0,d2.w),a2
                move.w  $12(a1),d2
                btst    #3,$69(a1)
                beq.w   .loc_1367C
                neg.w   d2

.loc_1367C:
                move.w  $12(a2),d4
                btst    #3,$69(a2)
                beq.w   .loc_1368C
                neg.w   d4

.loc_1368C:
                sub.w   d4,d2
                ble.w   .loc_136B0
                move.l  4(a2),d3
                sub.l   4(a1),d3
                ble.w   .loc_136B0
                divu.w  d2,d3
                cmp.w   (ram_FF1B46).l,d3
                bpl.w   .loc_136B0
                move.w  d3,(ram_FF1B46).l

.loc_136B0:
                dbf     d1,.loc_13638
                rts
; End of function sub_13626


; =============== S U B R O U T I N E =======================================


sub_136B6:
                move.w  $12(a1),d1
                btst    #3,$69(a1)
                beq.w   .loc_136C6
                neg.w   d1

.loc_136C6:
                move.w  $12(a2),d2
                btst    #3,$69(a2)
                beq.w   .loc_136D6
                neg.w   d2

.loc_136D6:
                sub.w   d1,d2
                beq.w   .loc_13700
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   .loc_136F4
                tst.w   d2
                bmi.w   .loc_13700
                neg.l   d0
                bra.w   .loc_136FC


.loc_136F4:
                tst.w   d2
                bpl.w   .loc_13700
                neg.w   d2

.loc_136FC:
                divu.w  d2,d0
                rts


.loc_13700:
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


sub_13746:
                movem.l d0-d1/a0,-(sp)
                move.w  $30(a1),d0
                move.w  d0,d1
                asr.w   #6,d0
                addq.b  #3,d0
                bpl.w   .loc_13760
                move.w  #0,d0
                bra.w   .loc_1376C


.loc_13760:
                cmp.b   #6,d0
                bmi.w   .loc_1376C
                move.w  #5,d0

.loc_1376C:
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


.loc_1379A:
                cmp.b   #6,d0
                bmi.w   .loc_137A6
                move.w  #5,d0

.loc_137A6:
                cmp.b   $72(a1),d0
                beq.w   .loc_137B2
                bsr.w   sub_13812

.loc_137B2:
                move.w  d1,d0
                sub.w   d4,d0
                asr.w   #6,d0
                addq.b  #3,d0
                bpl.w   .loc_137C6
                move.w  #0,d0
                bra.w   .loc_137D2


.loc_137C6:
                cmp.b   #6,d0
                bmi.w   .loc_137D2
                move.w  #5,d0

.loc_137D2:
                cmp.b   $72(a1),d0
                beq.w   .loc_137DE
                bsr.w   sub_13812

.loc_137DE:
                movem.l (sp)+,d0-d1/a0
                rts
; End of function sub_13746


; =============== S U B R O U T I N E =======================================


sub_137E4:
                movem.l d0-d1/a0,-(sp)
                clr.w   d0
                tst.w   $30(a1)
                bmi.w   .loc_137F6
                move.w  #3,d0

.loc_137F6:
                move.w  #2,d1
                move.b  d0,$72(a1)

.loc_137FE:
                move.w  d1,-(sp)
                bsr.w   sub_13812
                move.w  (sp)+,d1
                addq.w  #1,d0
                dbf     d1,.loc_137FE
                movem.l (sp)+,d0-d1/a0
                rts
; End of function sub_137E4


; =============== S U B R O U T I N E =======================================


sub_13812:
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


sub_138CE:
                lea     (ram_FF1EAA).l,a1
                btst    #4,$68(a1)
                bne.w   .return
                lea     (unk_2589A).l,a0

.loc_138E4:
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

.loc_13936:
                move.b  d1,$73(a2)
                btst    #2,d0
                bne.w   .loc_13952
                bclr    #3,$69(a2)
                move.w  #$70,$30(a2) ; 'p'
                bra.w   .loc_1395E


.loc_13952:
                bset    #3,$69(a2)
                move.w  #$FF90,$30(a2)

.loc_1395E:
                andi.w  #$F0,d0
                lsr.w   #4,d0
                move.b  d0,$74(a2)
                ext.w   d0
                lea     (unk_25A44).l,a3
                asl.w   #3,d0
                move.w  4(a3,d0.w),$12(a2)
                move.w  6(a3,d0.w),$46(a2)
                bra.w   .loc_138E4


.loc_13982:
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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


.return:
                rts
; End of function sub_138CE


unk_13A1A:      dc.b $FF
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


sub_13A26:
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


sub_13BD8:
                btst    #0,$68(a1)
                bne.w   .loc_13BEA
                move.w  #$FFD0,d1
                bra.w   .loc_13BEE


.loc_13BEA:
                move.w  #$FFFB,d1

.loc_13BEE:
                move.w  d1,$14(a1)
                rts
; End of function sub_13BD8


; =============== S U B R O U T I N E =======================================


sub_13BF4:
                lea     (ram_FF1F2A).l,a1
                move.w  (ram_FF1B32).l,d0
                beq.w   .loc_13C1C
                sub.w   (Race_ram_FrameDelay).l,d0
                move.w  d0,(ram_FF1B32).l
                bgt.w   .loc_13C88
                move.w  #0,(ram_FF1B32).l

.loc_13C1C:
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

.loc_13C54:
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


.loc_13C88:
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

.loc_13CF4:
                move.w  d0,$12(a1)
                bsr.w   sub_13CFE

.locret_13CFC:
                rts
; End of function sub_13BF4


; =============== S U B R O U T I N E =======================================


sub_13CFE:
                bsr.w   sub_16D0A
                bsr.w   sub_16D9A
                bsr.w   sub_13FE6
                cmp.w   $12(a1),d0
                bpl.w   .loc_13D16
                move.w  d0,$12(a1)

.loc_13D16:
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


sub_13DE0:
                movem.l d0-d2/a0-a2,-(sp)
                movea.l (ram_FFD7CC).l,a0
                move.w  #0,(ram_FF18A4).l

.loc_13DF2:
                move.l  (a0),d1
                cmp.l   #$FFFFFFFF,d1
                beq.w   .loc_13E8E
                clr.w   d1
                move.l  d1,d2
                sub.l   4(a1),d2
                btst    #3,$69(a1)
                beq.w   .loc_13E12
                neg.l   d2

.loc_13E12:
                tst.l   d2
                bgt.w   .loc_13E1A
                addq.l  #4,a0

.loc_13E1A:
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

.loc_13E5A:
                addq.w  #4,a0
                bra.s   .loc_13DF2


.loc_13E5E:
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


.loc_13E88:
                move.w  #0,$12(a1)

.loc_13E8E:
                movem.l (sp)+,d0-d2/a0-a2
                rts
; End of function sub_13DE0


; =============== S U B R O U T I N E =======================================


sub_13E94:
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


sub_13EFA:
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

.loc_13F26:
                tst.w   (MainMenu_ram_DemoMode).l
                bne.w   .loc_13F3A
                cmpa.l  #ram_FF1EAA,a1
                beq.w   .loc_13F40

.loc_13F3A:
                mulu.w  #$200,d0
                lsr.l   #8,d0

.loc_13F40:
                mulu.w  d1,d0
                lsr.l   #3,d0
                clr.l   d1
                move.b  $78(a1),d2
                beq.w   .loc_13F6E
                andi.w  #$FF,d2
                sub.w   (Race_ram_FrameDelay).l,d2
                bcc.w   .loc_13F60
                move.w  #0,d2

.loc_13F60:
                move.b  d2,$78(a1)
                move.w  (word_14742).l,d1
                bra.w   .loc_13FB0


.loc_13F6E:
                btst    #5,$68(a1)
                beq.w   .loc_13F96
                btst    #3,$68(a1)
                beq.w   .loc_13F8C
                move.w  (ram_FF3034).l,d1
                bra.w   .loc_13FB0


.loc_13F8C:
                move.w  (ram_FF302E).l,d1
                bra.w   .loc_13FB0


.loc_13F96:
                btst    #3,$68(a1)
                beq.w   .loc_13FAA
                move.w  (ram_FF3032).l,d1
                bra.w   .loc_13FB0


.loc_13FAA:
                move.w  (ram_FF302E).l,d1

.loc_13FB0:
                cmp.l   d1,d0
                bcs.w   .loc_13FCE
                lsr.l   #8,d0
                beq.w   .loc_13FC0
                asl.l   #8,d1
                divu.w  d0,d1

.loc_13FC0:
                move.w  d1,$3E(a1)
                bset    #5,$68(a1)
                bra.w   .loc_13FE0


.loc_13FCE:
                bclr    #5,$68(a1)
                move.w  #0,$40(a1)
                move.w  #0,$3E(a1)

.loc_13FE0:
                movem.l (sp)+,d0-d1
                rts
; End of function sub_13EFA


; =============== S U B R O U T I N E =======================================


sub_13FE6:
                movem.l d1-d2/a0-a2,-(sp)
                clr.l   d0
                btst    #3,$68(a1)
                beq.w   .loc_14000
                move.w  (ram_FF3032).l,d0
                bra.w   .loc_14006


.loc_14000:
                move.w  (ram_FF302E).l,d0

.loc_14006:
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

.loc_14026:
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

.loc_1404C:
                move.w  #$7FFF,d0

.loc_14050:
                movem.l (sp)+,d1-d2/a0-a2
                rts
; End of function sub_13FE6


unk_14056:      dc.b   1
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


sub_1406A:
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


.loc_14086:
                mulu.w  d3,d1
                swap    d1

.loc_1408A:
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


.loc_140AE:
                mulu.w  #$140,d2
                lsr.l   #8,d2

.loc_140B4:
                move.w  d2,$40(a1)
                move.w  d1,d0

.locret_140BA:
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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


sub_142D8:
                bclr    #7,$6A(a1)
                move.w  d0,-(sp)
                move.w  (ram_FF18A6).l,d0
                bpl.w   .loc_142EC
                neg.w   d0

.loc_142EC:
                cmp.w   #$1770,d0
                bcs.w   .loc_142FA
                bset    #7,$6A(a1)

.loc_142FA:
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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


sub_1434A:
                tst.w   (ram_FF1768).l
                beq.w   .loc_1435A
                clr.w   d0
                bra.w   .locret_1436C


.loc_1435A:
                tst.w   d0
                bpl.w   .loc_14362
                neg.w   d0

.loc_14362:
                lsr.w   #8,d0
                lsr.w   #3,d0
                move.w  d0,(ram_FF1B28).l

.locret_1436C:
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


sub_1438E:
                move.w  $12(a1),d0
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_143D4
                cmp.w   #$3E8,d0
                bmi.w   .loc_143D4
                tst.w   (ram_FF1768).l
                bne.w   .loc_143BA
                move.b  #6,(ram_FF1AD6).l
                bra.w   .loc_143D4


.loc_143BA:
                move.b  #1,$6E(a1)
                move.b  #0,$6F(a1)
                move.b  #$FF,$70(a1)
                move.b  #$F,(ram_FF1AD6).l

.loc_143D4:
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

.locret_14402:
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
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


sub_14486:
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


.loc_144CA:
                addi.w  #9,d0

.loc_144CE:
                move.b  d0,(ram_FF1AD6).l

.loc_144D4:
                move.b  $69(a2),d0
                andi.b  #8,d0
                or.b    d0,$69(a1)
                jsr     (sub_142D8).l
                move.w  $12(a2),d1
                move.w  (ram_FF18A6).l,d0
                bne.w   .loc_144F8
                move.w  #$400,d0

.loc_144F8:
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


.loc_1451C:
                move.w  $12(a2),d1
                lsr.w   #1,d1
                beq.w   .loc_14530
                btst    #0,$68(a1)
                bne.w   .loc_14538

.loc_14530:
                move.w  d1,$12(a1)
                bsr.w   sub_14688

.loc_14538:
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

.loc_14570:
                lsr.w   #8,d0
                lsr.w   #3,d0
                move.w  d0,$2C(a1)
                move.w  #0,$2E(a1)
                move.w  2(a1),d0
                addi.w  #$30,d0 ; '0'
                move.w  d0,$2A(a1)
                bset    #0,$68(a1)
                bra.w   .locret_145EA


.loc_14594:
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

.locret_145EA:
                rts
; End of function sub_14486


; =============== S U B R O U T I N E =======================================


sub_145EC:
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

.loc_14612:
                bra.w   .loc_14652


.loc_14616:
                sub.w   d4,d0
                bcc.w   .loc_14628
                neg.w   d1
                cmp.w   d1,d0
                bcs.w   .loc_14652
                bra.w   .loc_1462E


.loc_14628:
                cmp.w   d1,d0
                bcc.w   .loc_14652

.loc_1462E:
                tst.b   $6E(a1)
                bmi.w   .locret_14686
                move.b  #1,$6E(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_1464E
                move.b  #9,(ram_FF1AD6).l

.loc_1464E:
                bra.w   .loc_1466A


.loc_14652:
                move.b  #0,$6E(a1)
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_1466A
                move.b  #$A,(ram_FF1AD6).l

.loc_1466A:
                move.b  #$FF,$6F(a1)
                asl.w   #1,d1
                cmp.w   d1,d0
                bcc.w   .loc_14682
                jsr     (sub_15538).l
                bra.w   .locret_14686


.loc_14682:
                bsr.w   sub_1555C

.locret_14686:
                rts
; End of function sub_145EC


; =============== S U B R O U T I N E =======================================


sub_14688:
                move.l  (ram_FF3038).l,d0
                addi.l  #$3000,d0
                addi.l  #$200,d0
                btst    #0,$69(a1)
                bne.w   .loc_146A6
                neg.l   d0

.loc_146A6:
                add.l   d0,4(a1)
                rts
; End of function sub_14688


; =============== S U B R O U T I N E =======================================


sub_146AC:
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

.loc_146EC:
                move.w  2(a1),$2A(a1)
                move.w  #0,$2E(a1)
                bset    #0,$68(a1)
                bra.w   .loc_14708


.loc_14702:
                bclr    #0,$68(a1)

.loc_14708:
                cmpi.b  #0,$6E(a1)
                bne.w   .locret_14718
                move.b  #1,$6E(a1)

.locret_14718:
                rts
; End of function sub_146AC


unk_1471A:      dc.b $E6
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
word_14742:     dc.w $4CC2
unk_14744:      dc.b   0
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
unk_14764:      dc.b   0
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
unk_147FC:      dc.b   0
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


sub_1487C:
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


.loc_148AE:
                cmp.l   (ram_FF3038).l,d0
                bmi.w   .loc_148C0

.loc_148B8:
                bsr.w   sub_14CEC
                bra.w   .locret_1496A


.loc_148C0:
                bsr.w   sub_1496C
                btst    #4,$69(a1)
                beq.w   .loc_148D6
                tst.w   $50(a1)
                bne.w   .loc_148F0

.loc_148D6:
                move.w  $52(a1),d1
                add.w   d1,$22(a1)
                move.w  #0,$52(a1)
                move.w  #0,(ram_FF18BA).l
                bra.w   .loc_1491E


.loc_148F0:
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_14910
                move.b  (ram_FF1ADB).l,d2
                cmp.b   $71(a2),d2
                bne.w   .loc_14910
                move.w  #3,(ram_FF0520).l

.loc_14910:
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_1491E
                bsr.w   sub_149C4

.loc_1491E:
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .loc_1493A
                btst    #4,$69(a2)
                beq.w   .loc_1493A
                tst.w   $50(a2)
                bne.w   .loc_14954

.loc_1493A:
                move.w  $52(a2),d1
                add.w   d1,$22(a2)
                move.w  #0,$52(a2)
                move.w  #0,(ram_FF18B8).l
                bra.w   .loc_14962


.loc_14954:
                cmpi.b  #1,$6C(a2)
                bne.w   .loc_14962
                bsr.w   sub_14B04

.loc_14962:
                bsr.w   sub_14D84
                bsr.w   sub_14C3C

.locret_1496A:
                rts
; End of function sub_1487C


; =============== S U B R O U T I N E =======================================


sub_1496C:
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


.loc_149A0:
                sub.w   $4C(a1),d2
                sub.w   $4E(a2),d2
                subi.w  #$10,d2
                cmp.w   d3,d2
                bpl.w   .loc_149B6
                move.w  d2,$30(a2)

.loc_149B6:
                sub.w   $30(a2),d3
                sub.w   d3,0.w(a2)
                movem.l (sp)+,d0-d3
                rts
; End of function sub_1496C


; =============== S U B R O U T I N E =======================================


sub_149C4:
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


.loc_14A04:
                move.w  $5E(a1),d0
                muls.w  d0,d1
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_14A26
                tst.w   (ram_FF1904).l
                beq.w   .loc_14A26
                move.b  #$11,(ram_FF1AD6).l

.loc_14A26:
                asr.l   #8,d1
                move.w  d1,$52(a1)
                bpl.w   .loc_14A32
                neg.w   d1

.loc_14A32:
                tst.b   $6B(a1)
                bne.w   .loc_14A62
                move.w  $1A(a1),d0
                sub.w   $1A(a2),d0
                bpl.w   .loc_14A48
                neg.w   d0

.loc_14A48:
                sub.w   $4A(a1),d0
                sub.w   $4A(a2),d0
                cmp.w   #$A,d0
                bpl.w   .loc_14A62
                move.b  #$14,$6D(a1)
                bra.w   .loc_14A72


.loc_14A62:
                cmpa.l  #ram_FF1F2A,a2
                beq.w   .locret_14B02
                move.w  d1,(ram_FF18BA).l

.loc_14A72:
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


.loc_14AE4:
                move.b  $6B(a1),d2
                andi.w  #3,d2
                andi.b  #$FC,$6A(a2)
                or.b    d2,$6A(a2)
                bset    #2,$6A(a2)
                move.b  #$1E,$70(a2)

.locret_14B02:
                rts
; End of function sub_149C4


; =============== S U B R O U T I N E =======================================


sub_14B04:
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


.loc_14B44:
                move.w  $5E(a2),d0
                muls.w  d0,d1
                cmpa.l  (ram_FF1908).l,a2
                bne.w   .loc_14B66
                tst.w   (ram_FF1906).l
                beq.w   .loc_14B66
                move.b  #$11,(ram_FF1AD6).l

.loc_14B66:
                asr.l   #8,d1
                move.w  d1,$52(a2)
                bpl.w   .loc_14B72
                neg.w   d1

.loc_14B72:
                tst.b   $6B(a2)
                bne.w   .loc_14BA2
                move.w  $1A(a1),d0
                sub.w   $1A(a2),d0
                bpl.w   .loc_14B88
                neg.w   d0

.loc_14B88:
                sub.w   $4A(a1),d0
                sub.w   $4A(a2),d0
                cmp.w   #$A,d0
                bpl.w   .loc_14BA2
                move.b  #$14,$6D(a2)
                bra.w   .loc_14BB4


.loc_14BA2:
                cmp.w   #$50,d1 ; 'P'
                ble.w   .loc_14BAE
                move.w  #$50,d1 ; 'P'

.loc_14BAE:
                move.w  d1,(ram_FF18B8).l

.loc_14BB4:
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


.loc_14C1C:
                move.b  $6B(a2),d2
                andi.w  #3,d2
                andi.b  #$FC,$6A(a1)
                or.b    d2,$6A(a1)
                bset    #2,$6A(a1)
                move.b  #$1E,$70(a1)

.locret_14C3A:
                rts
; End of function sub_14B04


; =============== S U B R O U T I N E =======================================


sub_14C3C:
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

.loc_14C8C:
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

.locret_14CEA:
                rts
; End of function sub_14C3C


; =============== S U B R O U T I N E =======================================


sub_14CEC:
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


.loc_14D14:
                mulu.w  #$1999,d0
                swap    d0

.loc_14D1A:
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_14D34
                move.w  d0,-(sp)
                jsr     (sub_1434A).l
                add.w   d0,(Race_ram_BikeDamage).l
                move.w  (sp)+,d0

.loc_14D34:
                move.w  $12(a1),d1
                move.w  $12(a2),d2
                move.l  #$7000,d3
                cmp.w   d2,d1
                bpl.w   .loc_14D4A
                neg.l   d3

.loc_14D4A:
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


sub_14D84:
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


.loc_14DA8:
                mulu.w  (ram_FF18B6).l,d0
                swap    d0

.loc_14DB0:
                move.w  $C(a1),d1
                add.w   (ram_FF1A9A).l,d1
                move.w  $C(a2),d2
                add.w   (ram_FF1A9C).l,d2
                btst    #1,$69(a1)
                beq.w   .loc_14DD6
                add.w   d0,d2
                sub.w   d0,d1
                bra.w   .loc_14DDA


.loc_14DD6:
                sub.w   d0,d2
                add.w   d0,d1

.loc_14DDA:
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


sub_14E38:
                tst.w   (Race_ram_GameEnded).l
                beq.w   .loc_14E58
                jsr     (AudioFunc7).l
                jsr     (AudioFunc10).l
                jsr     (AudioFunc13).l
                bra.w   .loc_14E62


.loc_14E58:
                tst.w   (Race_ram_State).l
                beq.w   .loc_14E7A

.loc_14E62:
                jsr     (AudioFunc15).l
                jsr     (AudioFunc17).l
                move.b  #0,(ram_FF1AD5).l
                bra.w   .loc_14FA2


.loc_14E7A:
                clr.l   d0
                btst    #5,(ram_FF1EAA + STRUCT_OFFSET_68).l
                beq.w   .loc_14E9A
                btst    #3,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .loc_14EB2
                moveq   #1,d0
                bra.w   .loc_14EB4


.loc_14E9A:
                cmpi.b  #1,(ram_FF1EAA + STRUCT_OFFSET_6E).l
                bne.w   .loc_14ECE
                btst    #0,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .loc_14ECE

.loc_14EB2:
                moveq   #2,d0

.loc_14EB4:
                cmp.b   (ram_FF1AD4).l,d0
                beq.w   .loc_14EE6
                move.b  d0,(ram_FF1AD4).l
                jsr     (AudioFunc5).l
                bra.w   .loc_14EE6


.loc_14ECE:
                tst.w   (ram_FF1AD4).l
                beq.w   .loc_14EE6
                move.b  #0,(ram_FF1AD4).l
                jsr     (AudioFunc15).l

.loc_14EE6:
                tst.w   (ram_FF1EA8).l
                beq.w   .loc_14F1E
                move.w  (ram_FF1EA8).l,d0
                sub.w   (Race_ram_FrameDelay).l,d0
                ble.w   .loc_14F16
                move.w  d0,(ram_FF1EA8).l
                cmpi.b  #$15,(ram_FF1AD6).l
                beq.w   .loc_14F1E
                bra.w   .loc_14F58


.loc_14F16:
                move.w  #0,(ram_FF1EA8).l

.loc_14F1E:
                clr.l   d0
                move.b  (ram_FF1AD6).l,d0
                beq.w   .loc_14F34
                jsr     (AudioFunc5).l
                bra.w   .loc_14F58


.loc_14F34:
                clr.l   d0
                move.b  (ram_FF1AD7).l,d0
                beq.w   .loc_14F58
                cmp.b   #$E,d0
                bne.w   .loc_14F52
                tst.b   (ram_FF1ADD).l
                beq.w   .loc_14F58

.loc_14F52:
                jsr     (AudioFunc5).l

.loc_14F58:
                tst.w   (ram_FF1B32).l
                bne.w   .loc_14FA2
                move.w  (ram_FF1F2E).l,d0
                sub.w   (ram_FF1EAA + STRUCT_OFFSET_POSX_HIGH).l,d0
                bpl.w   .loc_14F74
                neg.w   d0

.loc_14F74:
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

.loc_14FA2:
                move.b  #0,(ram_FF1AD6).l
                move.b  #0,(ram_FF1AD7).l
                rts
; End of function sub_14E38


; =============== S U B R O U T I N E =======================================


sub_14FB4:
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

.loc_15000:
                cmp.w   #$A,d0
                bmi.w   .loc_15010
                move.w  #1,(Race_ram_GameEnded).l

.loc_15010:
                move.w  (sp)+,d0
                rts
; End of function sub_14FB4


; =============== S U B R O U T I N E =======================================


sub_15014:
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

.loc_15048:
                asl.w   #2,d0
                lea     (unk_155D0).l,a0
                movea.l (a0,d0.w),a0

.loc_15054:
                move.b  $70(a1),d2
                move.b  $6F(a1),d1
                bpl.w   *+4

.loc_15060:
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

.loc_1509E:
                cmp.w   d4,d3
                bmi.w   .loc_150E0
                btst    #3,$69(a1)
                bne.w   .loc_150C0
                move.w  4(a1),d7
                cmp.w   (ram_FF1E68).l,d7
                bpl.w   .loc_150EE
                bra.w   .loc_150CE


.loc_150C0:
                move.w  4(a1),d7
                cmp.w   (ram_FF1E68).l,d7
                bmi.w   .loc_150EE

.loc_150CE:
                lea     (unk_15CE0).l,a4
                move.w  #$B1,(ram_FF18BC).l
                bra.w   .loc_150EE


.loc_150E0:
                lea     (unk_15CFC).l,a4
                move.w  #$B2,(ram_FF18BC).l

.loc_150EE:
                bsr.w   sub_154D2
                tst.w   d0
                bpl.w   .loc_1510A
                bsr.w   sub_151F0
                cmpi.b  #$FF,$6E(a1)
                beq.w   .loc_151DE
                bra.w   .loc_15054


.loc_1510A:
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


.loc_15138:
                tst.w   $22(a1)
                beq.w   .loc_1514C
                bpl.w   .loc_15148
                bset    #0,d3

.loc_15148:
                move.b  d3,$76(a1)

.loc_1514C:
                move.w  $54(a2),d0
                cmp.w   #$11,d0
                ble.w   .loc_15160
                move.w  #$11,d0
                move.w  d0,$54(a1)

.loc_15160:
                asl.w   #2,d0
                lea     (unk_155D0).l,a0
                movea.l (a0,d0.w),a0

.loc_1516C:
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

.loc_15198:
                ext.w   d0
                asl.w   #3,d0
                movea.l 4(a0,d0.w),a4
                cmpa.l  #$FFFFFFFF,a4
                bne.w   .loc_151B4
                move.b  #$FF,$6E(a2)
                bra.w   .loc_151EA


.loc_151B4:
                bsr.w   sub_154D2
                tst.w   d0
                bpl.w   .loc_151CA
                bsr.w   sub_15446
                move.b  #0,$70(a2)
                bra.s   .loc_1516C


.loc_151CA:
                move.w  d0,$58(a2)
                move.b  d1,$6F(a2)
                move.b  d2,$70(a2)
                move.b  d3,$76(a2)
                bra.w   .loc_151EA


.loc_151DE:
                move.b  #$FF,$6E(a1)
                move.b  #$FF,$6E(a2)

.loc_151EA:
                movem.l (sp)+,d1-d7/a0-a2
                rts
; End of function sub_15014


; =============== S U B R O U T I N E =======================================


sub_151F0:
                movem.l d0-d1,-(sp)
                cmpi.b  #1,$6E(a1)
                bmi.w   .loc_1521C
                bne.w   .loc_1522C
                cmpi.w  #0,$12(a1)
                bne.w   .loc_1521C
                move.b  #2,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15338


.loc_1521C:
                move.b  #1,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15338


.loc_1522C:
                cmpi.b  #3,$6E(a1)
                blt.w   .loc_152AA
                beq.w   .loc_1524A
                move.b  #$FF,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15338


.loc_1524A:
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   .loc_1526C
                move.l  4(a1),d0
                sub.l   4(a2),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_152AA
                bra.w   .loc_1527E


.loc_1526C:
                move.l  4(a2),d0
                sub.l   4(a1),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_152AA

.loc_1527E:
                move.w  $1A(a2),d0
                sub.w   $1A(a1),d0
                bpl.w   .loc_1529A
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                bmi.w   .loc_152AA
                bra.w   .loc_152D6


.loc_1529A:
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                cmp.w   #$40,d0 ; '@'
                ble.w   .loc_152D6

.loc_152AA:
                cmpa.l  #ram_FF1EAA,a1
                bne.w   .loc_152C6
                tst.w   (ram_FF1B1A).l
                beq.w   .loc_152C6
                move.w  #1,(Race_ram_GameEnded).l

.loc_152C6:
                move.b  #3,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15338


.loc_152D6:
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

.loc_15310:
                add.w   d1,d0
                move.w  d0,$30(a2)
                move.w  0.w(a1),d0
                add.w   d1,d0
                move.w  d0,0.w(a2)
                move.b  #4,$6E(a1)
                move.b  #4,$6E(a2)
                move.b  #$FF,$6F(a1)
                move.b  #$FF,$6F(a2)

.loc_15338:
                movem.l (sp)+,d0-d1
                rts
; End of function sub_151F0


; =============== S U B R O U T I N E =======================================


sub_1533E:
                movem.l d0-d1,-(sp)
                cmpi.b  #1,$6E(a1)
                bmi.w   .loc_15440
                bne.w   .loc_1536A
                cmpi.w  #0,$12(a1)
                bne.w   .loc_15440
                move.b  #2,$6E(a1)
                move.b  #$FF,$6F(a1)
                bra.w   .loc_15440


.loc_1536A:
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


.loc_153A0:
                move.l  4(a2),d0
                sub.l   4(a1),d0
                cmp.l   #$2000,d0
                bgt.w   .loc_15440

.loc_153B2:
                move.w  $1A(a2),d0
                sub.w   $1A(a1),d0
                bpl.w   .loc_153CE
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                blt.w   .loc_15440
                bra.w   .loc_153DE


.loc_153CE:
                move.w  $30(a2),d0
                sub.w   $30(a1),d0
                cmp.w   #$40,d0 ; '@'
                bgt.w   .loc_15440

.loc_153DE:
                bclr    #3,$69(a1)
                move.b  #4,$6E(a1)
                move.b  #4,$6E(a2)
                move.b  #$FF,$6F(a1)
                move.b  #$FF,$6F(a2)

.loc_153FC:
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

.loc_15430:
                add.w   d1,d0
                move.w  d0,$30(a2)
                move.w  0.w(a1),d0
                add.w   d1,d0
                move.w  d0,0.w(a2)

.loc_15440:
                movem.l (sp)+,d0-d1
                rts
; End of function sub_1533E


; =============== S U B R O U T I N E =======================================


sub_15446:
                move.w  d0,-(sp)
                move.b  $6E(a2),d0
                cmp.b   #3,d0
                bne.w   .loc_15468
                bra.w   .loc_1546E

                dc.b $4A ; J
                dc.b $6A ; j
                dc.b   0
                dc.b $12
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b $10
                dc.b $66 ; animation frame byte (IDA mis-named this as a struct offset)
                dc.b   0
                dc.b   0
                dc.b  $C
                dc.b $10
                dc.b $3C ; <
                dc.b   0
                dc.b   2


.loc_15468:
                addq.b  #1,d0
                move.b  d0,$6E(a2)

.loc_1546E:
                move.b  #$FF,$6F(a2)
                move.w  (sp)+,d0
                rts
; End of function sub_15446


; =============== S U B R O U T I N E =======================================


sub_15478:
                movem.l d1-d7/a0-a2,-(sp)
                lea     (unk_155A4).l,a0

.loc_15482:
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


.loc_154C0:
                move.b  d1,(ram_FF302A).l
                move.b  d2,(ram_FF302B).l
                movem.l (sp)+,d1-d7/a0-a2
                rts
; End of function sub_15478


; =============== S U B R O U T I N E =======================================


sub_154D2:
                tst.b   d1
                bmi.w   .loc_15506
                sub.b   (ram_FF304B).l,d2
                bpl.w   .loc_1550C
                add.b   2(a4),d2
                bpl.w   .loc_1550A

.loc_154EA:
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


.loc_15506:
                move.b  2(a4),d2

.loc_1550A:
                addq.b  #1,d1

.loc_1550C:
                move.b  d1,d4
                ext.w   d4
                asl.w   #2,d4
                move.b  3(a4,d4.w),d0

.loc_15516:
                move.b  4(a4,d4.w),d3
                move.b  5(a4,d4.w),d5
                move.b  6(a4,d4.w),d6
                ext.w   d0
                bmi.w   .loc_1552A
                add.w   (a4),d0

.loc_1552A:
                cmp.w   (word_3C7EA).l,d0
                bmi.w   .locret_15536
                nop

.locret_15536:
                rts
; End of function sub_154D2


; =============== S U B R O U T I N E =======================================


sub_15538:
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


sub_1555C:
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
unk_155A4:      dc.b   0
                dc.b   1
                dc.b $55 ; U
                dc.b $AC
                dc.b $FF
                dc.b $FF
                dc.b $FF
                dc.b $FF
unk_155AC:      dc.b   1
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
unk_155D0:      dc.b   0
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
unk_15618:      dc.b   6
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
unk_15624:      dc.b   0
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
unk_15CE0:      dc.b   0
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
unk_15CFC:      dc.b   0
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
byte_15FA8:     dc.b $3D
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


Rand_Init:
                movem.l d0-d1/a0-a1,-(sp)
                move.w  d0,d1

                lea     (byte_15FA8).l,a0
                lea     (ram_FF18BE).l,a1
                move.w  #$20,d0
.loc_15FFE:
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_15FFE

                lea     (ram_FF18BE).l,a0
                move.w  #$20,d0
.loc_1600E:
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


sub_16088:
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

.loc_160A8:
                move.w  d0,(ram_FF1B42).l
                rts
; End of function sub_1609A


; =============== S U B R O U T I N E =======================================


sub_160B0:
                moveq   #0,d0
                move.w  (ram_FF1B42).l,d0
                lsr.w   #1,d0
                bcc.s   .loc_160C0
                eori.w  #$B400,d0

.loc_160C0:
                move.w  d0,(ram_FF1B42).l
                divs.w  d2,d0
                swap    d0
                rts
; End of function sub_160B0


; =============== S U B R O U T I N E =======================================


sub_160CC:
                move.w  (ram_FF1B44).l,d0
                lsr.w   #1,d0
                bcc.s   .loc_160DA
                eori.w  #$B400,d0

.loc_160DA:
                move.w  d0,(ram_FF1B44).l
                rts
; End of function sub_160CC


; =============== S U B R O U T I N E =======================================


sub_160E2:
                lea     (ram_FF1EAA).l,a1
                btst    #4,$68(a1)
                beq.w   .loc_160FA
                tst.b   $6E(a1)
                bpl.w   .locret_16118

.loc_160FA:
                move.w  $5C(a1),d0
                add.w   (Race_ram_FrameDelay).l,d0
                cmp.w   (ram_FF18AA).l,d0
                bcs.w   .loc_16114
                move.w  (ram_FF18AA).l,d0

.loc_16114:
                move.w  d0,$5C(a1)

.locret_16118:
                rts
; End of function sub_160E2


; =============== S U B R O U T I N E =======================================


sub_1611A:
                move.w  #0,(ram_FF1904).l
                lea     (ram_FF1A08).l,a0
                movea.l (a0)+,a1
                move.l  4(a1),d0
                move.w  $30(a1),d2
                move.l  (a0),-(sp)
                move.l  #$7FFFFFFF,d4

.loc_1613A:
                movea.l (a0)+,a2
                cmpa.l  #$FFFFFFFF,a2
                beq.w   .loc_16176
                move.l  d0,d1
                sub.l   4(a2),d1
                bpl.w   .loc_16152
                neg.l   d1
.loc_16152:
                lsr.l   #8,d1
                move.l  d1,d3
                mulu.w  d3,d1
                clr.l   d3
                move.w  d2,d3
                sub.w   $30(a2),d3
                bpl.w   .loc_16166
                neg.w   d3
.loc_16166:
                move.w  d3,d5
                mulu.w  d5,d3
                add.l   d3,d1
                cmp.l   d4,d1
                bcc.s   .loc_1613A
                move.l  d1,d4
                move.l  a2,(sp)
                bra.s   .loc_1613A


.loc_16176:
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

.loc_161BE:
                tst.w   (ram_FF1ACC).l
                beq.w   .loc_161D2
                jsr     (sub_14FB4).l
                bra.w   .locret_162AE


.loc_161D2:
                tst.b   (ram_FF1B22).l
                beq.w   .loc_162AA
                btst    #5,(Race_ram_CurrentButtons).l
                beq.w   .loc_1621E
                btst    #6,$69(a1)
                bne.w   .loc_161FC
                btst    #0,$6B(a1)
                beq.w   .loc_1621E

.loc_161FC:
                move.w  (Race_ram_FrameDelay).l,d0
                sub.b   d0,$6D(a1)
                bgt.w   .locret_162AE
                cmpi.b  #0,$6C(a1)
                bne.w   .loc_1622C
                move.b  #0,$6D(a1)
                bra.w   .locret_162AE


.loc_1621E:
                move.w  (Race_ram_FrameDelay).l,d0
                sub.b   d0,$6D(a1)
                bgt.w   .locret_162AE

.loc_1622C:
                addi.b  #1,$6C(a1)
                cmpi.b  #1,$6C(a1)
                bne.w   .loc_16248
                move.w  #1,(ram_FF1904).l
                bsr.w   Audio_UpdateEngine0

.loc_16248:
                cmpi.b  #3,$6C(a1)
                bpl.w   .loc_16298
                btst    #6,$69(a1)
                bne.w   .loc_16282
                lea     (ram_FF1AB6).l,a4
                btst    #1,$6B(a1)
                beq.w   .loc_16272
                lea     (ram_FF1AC2).l,a4

.loc_16272:
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_162AE


.loc_16282:
                lea     (ram_FF1ABC).l,a4
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_162AE


.loc_16298:
                move.b  #0,(ram_FF1B22).l
                bclr    #4,$69(a1)
                bra.w   .locret_162AE


.loc_162AA:
                bsr.w   sub_162B0

.locret_162AE:
                rts
; End of function sub_1611A


; =============== S U B R O U T I N E =======================================


sub_162B0:
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

.loc_162EC:
                bclr    #0,$6B(a1)
                bclr    #6,$69(a1)
                btst    #0,d0
                beq.w   .loc_1630A
                bset    #0,$6B(a1)
                bra.w   .loc_16320


.loc_1630A:
                btst    #1,d0
                beq.w   .loc_16320
                bset    #6,$69(a1)
                move.b  (ram_FF1ABC).l,$6D(a1)

.loc_16320:
                movea.l (ram_FF1908).l,a0
                cmpa.l  #$FFFFFFFF,a0
                beq.w   .locret_1634C
                move.w  $30(a1),d1
                cmp.w   $30(a0),d1
                bpl.w   .loc_16346
                bclr    #5,$69(a1)
                bra.w   .locret_1634C


.loc_16346:
                bset    #5,$69(a1)

.locret_1634C:
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

loc_1636E:
                neg.l   d0
                cmp.l   #$10000,d0
                bmi.w   loc_1637E
                bra.w   locret_16456
; ---------------------------------------------------------------------------

loc_1637E:
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

loc_163AE:
                bclr    #5,$69(a1)

loc_163B4:
                btst    #1,d0
                bne.w   loc_163C6
                bclr    #6,$69(a1)
                bra.w   loc_163CC
; ---------------------------------------------------------------------------

loc_163C6:
                bset    #6,$69(a1)

loc_163CC:
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

loc_163FE:
                btst    #3,d0
                beq.w   loc_16428
                move.l  4(a2),d2
                sub.l   4(a1),d2
                cmp.l   #$8000,d0
                bpl.w   loc_16428
                bclr    #1,$68(a1)
                bset    #2,$68(a1)
                bsr.w   sub_13A92

loc_16428:
                btst    #4,d0
                beq.w   loc_16440
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d2
                neg.w   d2
                bra.w   loc_16452
; ---------------------------------------------------------------------------

loc_16440:
                btst    #5,d0
                beq.w   locret_16456
                movea.l (ram_FF1A68).l,a4
                move.w  6(a4),d2

loc_16452:
                move.w  d2,$46(a1)

locret_16456:
                rts
; End of function sub_1634E


; =============== S U B R O U T I N E =======================================


sub_16458:
                move.l  a4,-(sp)
                move.w  (Race_ram_FrameDelay).l,d0
                sub.w   d0,$5A(a1)
                bgt.w   loc_1646E
                move.w  #0,$5A(a1)

loc_1646E:
                btst    #4,$69(a1)
                beq.w   loc_1647C
                bsr.w   sub_16548

loc_1647C:
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

loc_164AA:
                jsr     (sub_13D44).l
                tst.w   (ram_FF18A4).l
                bne.w   locret_1651E
                lea     (ram_FF1EAA).l,a2

loc_164C0:
                cmpa.l  #ram_FF1F2A,a1
                beq.w   loc_16518
                btst    #4,$69(a1)
                bne.w   loc_16518
                move.l  4(a2),d0
                sub.l   4(a1),d0
                bpl.w   loc_164E2
                neg.l   d0

loc_164E2:
                movea.l (ram_FF1A68).l,a5
                move.w  0.w(a5),d6
                ext.l   d6
                swap    d6
                cmp.l   d6,d0
                bmi.w   loc_164FE
                movea.l 8(a4),a6
                bra.w   loc_1651C
; ---------------------------------------------------------------------------
loc_164FE:
                cmpa.l  (ram_FF1908).l,a1
                bne.w   loc_16510
                tst.w   $5A(a1)
                ble.w   loc_16518
loc_16510:
                movea.l 8(a4),a6
                bra.w   loc_1651C
; ---------------------------------------------------------------------------
loc_16518:
                movea.l $C(a4),a6
loc_1651C:
                jsr     (a6)
locret_1651E:
                rts
; End of function sub_16458

; =============== S U B R O U T I N E =======================================


Audio_UpdateEngine0:
                cmpi.b  #1,$6C(a1)
                bne.w   .locret_16546
                btst    #1,$6B(a1)
                beq.w   .locret_16546
                btst    #6,$69(a1)
                bne.w   .locret_16546
                move.b  #$E,(ram_FF1AD7).l

.locret_16546:
                rts
; End of function Audio_UpdateEngine0


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
                bsr.s   Audio_UpdateEngine0

.loc_16578:
                cmpi.b  #3,$6C(a1)
                bpl.w   .loc_165C8
                btst    #6,$69(a1)
                bne.w   .loc_165B2
                lea     (unk_257E8).l,a4
                btst    #1,$6B(a1)
                beq.w   .loc_165A2
                lea     (unk_257E2).l,a4

.loc_165A2:
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_165CE


.loc_165B2:
                lea     (unk_257EE).l,a4
                move.b  $6C(a1),d0
                asl.w   #1,d0
                move.b  (a4,d0.w),$6D(a1)
                bra.w   .locret_165CE


.loc_165C8:
                bclr    #4,$69(a1)

.locret_165CE:
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


sub_165E0:
                move.b  $72(a1),d0
                ext.w   d0
                bset    #1,$68(a1)
                bclr    #2,$68(a1)
                bsr.w   sub_1384C
                btst    #5,$68(a1)
                beq.w   .loc_1660C
                bset    #2,$68(a1)
                bclr    #1,$68(a1)

.loc_1660C:
                bsr.w   sub_13A92
                rts
; End of function sub_165E0


; =============== S U B R O U T I N E =======================================


sub_16612:
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


sub_1662C:
                jsr     (Rand_GetWord).l
                btst    #0,d0
                bne.w   .loc_1663E
                bsr.s   sub_16612
                rts


.loc_1663E:
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

.loc_1665C:
                move.w  #$FFC0,d1
                bsr.w   sub_1333C
                bsr.w   sub_131BE
                rts
; End of function sub_16644


; =============== S U B R O U T I N E =======================================


sub_1666A:
                bsr.w   sub_131BE
                move.l  (ram_FF1786).l,d0
                movea.l (ram_FF1A68).l,a4
                btst    #4,$68(a1)
                beq.w   .loc_1668E
                move.w  8(a4),$5A(a1)
                bra.w   .loc_1669A


.loc_1668E:
                move.w  2(a4),d7
                ext.l   d7
                cmp.l   d7,d0
                bmi.w   .loc_166A6

.loc_1669A:
                move.b  $72(a1),d0
                ext.w   d0
                bsr.w   sub_1384C
                rts


.loc_166A6:
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


.loc_166CE:
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


.loc_16720:
                bsr.w   sub_16732
                move.w  d1,-(sp)
                bsr.w   sub_131BE
                move.w  (sp)+,d1
                bsr.w   sub_1333C

.locret_16730:
                rts
; End of function sub_166F0


; =============== S U B R O U T I N E =======================================


sub_16732:
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

.loc_16760:
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


.loc_167BC:
                bclr    #6,$69(a1)
                move.b  (ram_FF1AB6).l,$6D(a1)
                move.w  (ram_FF1E9C).l,d0
                andi.b  #1,d0
                or.b    d0,$6B(a1)
                btst    #1,$6B(a1)
                beq.w   .locret_1685E
                move.b  #$3C,$6D(a1) ; '<'
                bra.w   .locret_1685E


.loc_167EC:
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


.loc_16828:
                bclr    #6,$69(a1)
                move.b  (ram_FF1AB6).l,$6D(a1)
                move.w  (ram_FF1E9C).l,d0
                andi.b  #1,d0
                or.b    d0,$6B(a1)
                btst    #1,$6B(a1)
                beq.w   .locret_1685E
                move.b  #$3C,$6D(a1) ; '<'
                bra.w   .locret_1685E


.loc_16858:
                bclr    #4,$69(a1)

.locret_1685E:
                rts
; End of function sub_16732

    include "animation.asm"

; =============== S U B R O U T I N E =======================================


TrackData_InitLevel:
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
                jsr     (TrackData_StartDecode).l
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                asl.w   #1,d0
                movea.l (ram_FF1A6C).l,a0
                move.w  (a0,d0.w),d2
                lea     (ram_FFDC58).l,a1
                move.w  #$7F,d0

.loc_16A08:
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


.loc_16A24:
                mulu.w  d2,d1
                swap    d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A08

.locret_16A30:
                rts
; End of function TrackData_InitLevel


; =============== S U B R O U T I N E =======================================


TrackData_DecodeNextChunk:
                addq.w  #1,d0
                cmp.w   #3,d0
                ble.w   .loc_16A44
                move.w  #0,d0
                bra.w   .loc_16A46


.loc_16A44:
                asl.w   #7,d0

.loc_16A46:
                lea     (ram_FFDC58).l,a1
                adda.w  d0,a1
                move.l  a1,-(sp)
                move.l  #$80,d0
                movea.l (RaceTrack_Data2).l,a2
                movea.l (RaceTrack_Data3).l,a3
                move.w  #$3F,d1 ; '?'
                jsr     (TrackData_DecodeChunk).l
                movea.l (sp)+,a1
                move.w  (Menu_ram_PlayerLevel).l,d0
                subq.w  #1,d0
                asl.w   #1,d0
                movea.l (ram_FF1A6C).l,a0
                move.w  (a0,d0.w),d2
                move.w  #$3F,d0 ; '?'

.loc_16A86:
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


.loc_16AA2:
                mulu.w  d2,d1
                swap    d1
                move.b  d1,(a1)
                addq.w  #2,a1
                dbf     d0,.loc_16A86

.locret_16AAE:
                rts
; End of function TrackData_DecodeNextChunk



off_16AB0:      dc.l word_16AC4
                dc.l word_16ACE
                dc.l word_16AD8
                dc.l word_16AE2
                dc.l word_16AEC
word_16AC4:     dc.w $B333
                dc.w $CCCC
                dc.w $D999
                dc.w $D999
word_16ACC:     dc.w $D999
word_16ACE:     dc.w $B333
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
                dc.w $E666
word_16AD8:     dc.w $B333
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
word_16AE0:     dc.w $E666
word_16AE2:     dc.w $A666
                dc.w $B333
                dc.w $C000
                dc.w $C000
                dc.w $C000
word_16AEC:     dc.w $B333
                dc.w $CCCC
                dc.w $D999
                dc.w $E666
                dc.w $E666



; =============== S U B R O U T I N E =======================================


sub_16AF6:
                btst    #7,(ram_FF1EAA + STRUCT_OFFSET_68).l
                bne.w   .return
                tst.w   (ram_FF1EA6).l
                beq.w   .loc_16B2E
                move.w  (ram_FF1EA6).l,d0
                sub.w   (Race_ram_FrameDelay).l,d0
                ble.w   .loc_16B26
                move.w  d0,(ram_FF1EA6).l
                bra.w   .return


.loc_16B26:
                move.w  #0,(ram_FF1EA6).l

.loc_16B2E:
                cmpi.w  #6,(ram_FF1A06).l
                bpl.w   .return
                cmpi.w  #6000,(ram_FF1EAA + STRUCT_OFFSET_SPEED).l
                bmi.w   .loc_16B54
                bsr.w   sub_16BD6
                cmpa.l  #$FFFFFFFF,a1
                bne.w   .loc_16B58

.loc_16B54:
                bsr.w   sub_16C1A

.loc_16B58:
                jsr     (Rand_GetWord).l
                andi.w  #$1FF,d0
                move.w  d0,(ram_FF1EA6).l

.return:
                rts
; End of function sub_16AF6


; =============== S U B R O U T I N E =======================================


sub_16B6A:
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


sub_16C1A:
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

.loc_16C4A:
                movea.l (sp)+,a2
                rts
; End of function sub_16C1A


; =============== S U B R O U T I N E =======================================


sub_16C4E:
                movem.l d0-d1/a2,-(sp)
                lea     (unk_25856).l,a0
                lea     (Menu_ram_PlayerAOpponents).l,a2
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_16C6E
                lea     (Menu_ram_PlayerBOpponents).l,a2

.loc_16C6E:
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


sub_16C9A:
                move.l  a2,-(sp)
                lea     (ram_FF1982).l,a2
                bsr.w   sub_16E48
                bsr.w   sub_16E26
                movea.l (sp)+,a2
                rts
; End of function sub_16C9A


; =============== S U B R O U T I N E =======================================


sub_16CAE:
                movem.l d0-d1/a2,-(sp)
                cmpa.l  #ram_FF1F2A,a1
                bne.w   .loc_16CE8
                move.w  (Menu_ram_PlayerLevel).l,d0
                cmp.w   (ram_FF1B38).l,d0
                bne.w   .loc_16CDC
                move.w  #0,(ram_FF1B36).l
                move.w  #0,(ram_FF1B34).l

.loc_16CDC:
                move.w  #0,(ram_FF1B38).l
                bra.w   .loc_16CF2


.loc_16CE8:
                lea     (ram_FF19C4).l,a2
                bsr.w   sub_16E48

.loc_16CF2:
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


sub_16D60:
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

.loc_16D96:
                movea.l (sp)+,a2
                rts
; End of function sub_16D60


; =============== S U B R O U T I N E =======================================


sub_16D9A:
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

.loc_16E16:
                move.w  d0,$1A(a1)
                move.w  d0,0.w(a1)
                jsr     (sub_13746).l
                rts
; End of function sub_16D9A


; =============== S U B R O U T I N E =======================================


sub_16E26:
                movem.l a2-a3,-(sp)
                lea     (ram_FF1A0C).l,a2

.loc_16E30:
                cmpa.l  (a2)+,a1
                bne.s   .loc_16E30
                movea.l a2,a3
                subq.l  #4,a3

.loc_16E38:
                move.l  (a2)+,(a3)+
                bpl.s   .loc_16E38
                subq.w  #1,(ram_FF1A06).l
                movem.l (sp)+,a2-a3
                rts
; End of function sub_16E26


; =============== S U B R O U T I N E =======================================


sub_16E48:
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
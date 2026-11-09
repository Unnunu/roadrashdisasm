; *************************************************
; race_core.asm - race top-level/init/results/actor data (split from race.asm)
; ROM range: $A4E2-$D277 (race_hud starts at $D278)
; *************************************************

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
                move.w  #0,(RacePlayerA + RaceActor_Type).l
                jsr     (Race_InitActorLists).l
                jsr     (Race_InitActorPositions).l
                jsr     (TrackData_InitLevel).l
                jsr     (Race_InitVdp).l
                jsr     (Race_SpawnOpponents).l
                jsr     (Race_LoadTrackParams).l
                move.w  #$FFFF,(Race_ram_HIntRasterDisabled).l
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
; Out: Race_ram_Engine1Target..C2, audio channels; ram_CurrentSong
; Clobbers: d0/d1/a0
; *************************************************

Race_InitAudio:
                move.b  #0,(ram_FF1AD5).l
                move.w  #2000,(Race_ram_Engine1Target).l
                move.w  #2000,(Race_ram_Engine1Current).l
                move.w  #1000,(Race_ram_Engine2Target).l
                move.w  #1000,(Race_ram_Engine2Current).l
                move.w  #$7D0,(Race_ram_Engine3Target).l
                move.w  #$7D0,(Race_ram_Engine3Current).l
                move.w  #60,(ram_FF36C2).l
                jsr     (Audio_Engine1Start).l
                move.w  (Race_ram_Engine1Current).l,d0
                move.w  #$1F,d1
                jsr     (Audio_Engine1Update).l
                jsr     (Audio_Engine2Start).l
                move.w  (Race_ram_Engine2Current).l,d0
                move.w  #$1F,d1
                jsr     (Audio_Engine2Update).l
                jsr     (Audio_Engine3Start).l
                move.w  (Race_ram_Engine3Target).l,d0
                move.w  #$1F,d1
                jsr     (Audio_Engine3Update).l
                tst.w   (ram_MusicEnabled).l
                beq.w   .return

                lea     (Race_dTrackSongs).l,a0
                move.w  (Menu_ram_CurrentTrackId).l,d0
                move.w  (a0,d0.w),d0
                ext.l   d0
                move.w  d0,(ram_CurrentSong).l
                jsr     (Audio_StartMusic).l
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
; Loads the road image, builds the pre-scaled road tile rows and calls Race_DrawRearviewMirror.
; In:  unk_9DDCC
; Out: VRAM $F880/$7800/$7900; Race_ram_RearviewTileRows tiles
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
                movea.l #Race_ram_RearviewTileRows,a1
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
                jsr     (Race_DrawRearviewMirror).l
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
                move.l  #$100,(Race_ram_PlayerProgress).l
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
                move.w  #0,(Race_ram_HIntScrollOffset).l
                move.w  #-1,(ram_FF3698).l
                move.w  #0,(ram_FF369A).l
                move.w  #0,(ram_FF1ACC).l
                move.l  #$FFFFFFFF,(Race_ram_NearestActor).l
                move.w  #0,(Race_ram_BikeDamage).l
                move.w  #$E10,(ram_FF1B32).l
                move.w  #$E10,(ram_FF1B34).l
                move.w  #0,(ram_FF1B36).l
                move.w  #0,(Race_ram_LevelIndex).l
                move.l  #0,(ram_FF1B3A).l
                move.w  #0,(ram_FF1AFA).l
                move.l  #$333,(ram_FF1AFC).l
                move.l  #0,(ram_FF1B00).l
                move.w  #0,(ram_FF1B04).l
                move.l  #$333,(ram_FF1B06).l
                move.l  #0,(ram_FF1B0A).l
                move.b  #$FF,(ram_FF302B).l
                move.b  #$FF,(ram_FF302A).l
                move.l  #1,(Race_ram_ProgressSnapshotB).l
                move.l  #1,(Race_ram_ProgressSnapshotA).l
                move.w  #1,(Race_ram_FrameDelay).l
                move.w  #0,(Race_ram_Started).l
                move.w  #0,(Race_ram_GameEnded).l
                move.w  #0,(Race_ram_DemoGameEnded).l
                move.w  #0,(ram_FF1B22).l
                move.w  #0,(ram_FF1B2E).l
                move.w  #0,(ram_FF1B30).l
                move.w  #0,(ram_FF1B3E).l
                move.w  #0,(Race_ram_PlayerPlace).l
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
                move.l  #$100,(Race_ram_PlayerProgress).l
                move.w  #0,(Race_ram_BestProgress).l
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
                move.w  #0,(Race_CopIndex).l
                move.w  #0,(ram_FF1B18).l
                move.w  #0,(Race_ram_PlayerXDifference).l
                move.l  #0,(ram_FF3038).l
                move.w  #0,(ram_FF303C).l
                move.w  #0,(ram_FF303E).l
                move.w  #0,(ram_FF3040).l
                move.w  #0,(ram_FF3042).l
                move.w  #0,(ram_FF3044).l
                move.w  #0,(Race_ram_SpeedDisplay).l
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
                move.w  #0,(Race_ram_HIntRasterDisabled).l
                move.w  #0,(ram_FF36AA).l
                move.w  #$70,(ram_FF36AC).l
                move.w  #0,(Race_ram_NearestBehindIndex).l
                move.w  #$FFFF,(Race_ram_NearestBehindSpeed).l
                move.w  #0,(Race_ram_NearestAheadIndex).l
                move.w  #$FFFF,(Race_ram_NearestAheadSpeed).l
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
                move.l  #0,(Race_ram_CameraOffset).l
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
; Builds the actor/object pointer tables and counts from Race_ActorList/Race_ActorListMid.
; In:  -
; Out: ram_FF1A08/ram_FF1982 lists; ram_FF1A06; sentinels
; Clobbers: d0/a1/a2
; *************************************************

Race_InitActorLists:
                move.w  #0,(Race_ram_SpawnTimer).l
                move.w  #0,(ram_FF19C4).l
                move.w  #1,(ram_FF1A06).l
; first actor pointer (player A) then the second actor group
                lea     (Race_ActorList).l,a1
                lea     (ram_FF1A08).l,a2
                move.l  (a1),(a2)+

; skip to the second group (+$24 from the second entry)
                adda.w  #$24,a1
                move.w  #6,d0
.loc_B6F2:
                addi.w  #1,(ram_FF1A06).l
                move.l  (a1)+,(a2)+
                dbf     d0,.loc_B6F2

                move.l  #$FFFFFFFF,(a2)
                lea     (ram_FF1982).l,a2
                move.w  #0,(a2)+
; middle group (exact 8+7 split TODO)
                lea     (Race_ActorListMid).l,a1
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
; Out: RaceBike_ram_PhysicsConstants/D330/D338, ram_FF1AE8..F4, ram_FF18A8..B6, ram_FF1A9E/A0
; Clobbers: d0/a0/a1
; *************************************************

Race_InitPhysicsConstants:
                move.w  #$20,(ram_FF1AC8).l
                move.w  #$20,(ram_FF1ACA).l
                move.w  #8,d0
                lea     (unk_257D0).l,a0
                lea     (RaceBike_ram_PhysicsConstants).l,a1
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
; Loads per-track parameters from unk_1471A into Race_ram_TrackParam0..3034.
; In:  Menu_ram_CurrentTrackId
; Out: Race_ram_TrackParam0/3030/3032/3034
; Clobbers: d0/a0
; *************************************************

Race_LoadTrackParams:
                lea     (unk_1471A).l,a0
                move.w  (Menu_ram_CurrentTrackId).l,d0
                asl.w   #2,d0
                adda.w  d0,a0
                move.w  (a0)+,(Race_ram_TrackParam0).l
                move.w  (a0)+,(Race_ram_TrackParam1).l
                move.w  (a0)+,(Race_ram_TrackParam2).l
                move.w  (a0),(Race_ram_TrackParam3).l
                rts
; End of function Race_LoadTrackParams


; *************************************************
; Function Race_LoadBikeData
; Loads the selected bike's parameter block and steering/engine values.
; In:  Menu_ram_Player, Menu_ram_BikeIdPlayerA/B
; Out: RaceBike_ram_Parameters (0x13 words); ram_FF1AA6/AAA; RaceBike_ram_*; ram_FF1AB2/B4
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

                lea     (RaceBike_ram_Parameters).l,a1
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
; Out: timer fields; Race_ram_ProgressSnapshotA frame count
; Clobbers: d0/d1
; *************************************************

Race_UpdateTime:
                addi.l  #1,(Race_ram_ProgressSnapshotA).l
                btst    #7,(RacePlayerA + STRUCT_OFFSET_68).l
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
                move.w  $A(a2),(Race_ram_HIntScrollOffset).l
                move.l  $C(a2),(a0)

                move.w  #-1,(Race_ram_HIntRasterDisabled).l
                tst.w   (Race_ram_State).l
                bmi.w   .loc_BAE6
                move.w  #0,(Race_ram_HIntRasterDisabled).l
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
                jsr     (Audio_Engine1Stop).l
                jsr     (Audio_Engine2Stop).l
                jsr     (Audio_Engine3Stop).l
                move.l  #0,(ram_UpdateFunction).l
                move.w  #-1,(Race_ram_HIntRasterDisabled).l
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
                bset    #1,(RacePlayerA + STRUCT_OFFSET_68).l
                bra.w   .loc_BF40
.loc_BF38:
                bclr    #1,(RacePlayerA + STRUCT_OFFSET_68).l
.loc_BF40:
                btst    #6,d0 ; check A
                beq.w   .loc_BF54
                bset    #2,(RacePlayerA + STRUCT_OFFSET_68).l
                bra.w   .loc_BF5C
.loc_BF54:
                bclr    #2,(RacePlayerA + STRUCT_OFFSET_68).l
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
                jsr     (Audio_StopMusic).l
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
                bclr    #1,(RacePlayerA + STRUCT_OFFSET_68).l
                bclr    #2,(RacePlayerA + STRUCT_OFFSET_68).l
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
                move.w  (RacePlayerA + RaceActor_Speed).l,d0
                jsr     (Race_UpdateSpeedDisplay).l ; HUD speed value
                jsr     (Race_SpawnTick).l ; dynamic opponent/traffic spawn
                tst.w   (Race_ram_Started).l
                beq.w   .loc_C15A
; race started ??
                jsr     (Race_UpdatePlayerAnimation).l
                lea     (RacePlayerA).l,a1
                jsr     (Race_UpdateBikeLean).l
                jsr     (sub_1383E).l
                lea     (RacePlayerA).l,a1
                jsr     (sub_13A92).l
                jsr     (Race_UpdateActorAI).l
                jsr     (sub_13E94).l
                jsr     (sub_10DBE).l
                jsr     (sub_10DDA).l
                jsr     (sub_13BF4).l
                jsr     (Race_UpdateStaticActors).l
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
                jsr     (Race_UpdateNearestOpponent).l
                jsr     (sub_12EA2).l
                jsr     (sub_13106).l
                move.w  (RacePlayerA + RaceActor_X).l,d0
                sub.w   (ram_FF1F2E).l,d0
                move.w  d0,(Race_ram_PlayerXDifference).l
                jsr     (Race_UpdateNearestTarget).l
.loc_C15A:
                jsr     (Race_UpdateCamera).l
                movea.l (Race_ram_CurrentFrameReady).l,a0
                tst.w   (a0)
                bne.w   .return

                jsr     (Race_IntegrateTrackCurve).l
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
                jsr     (Race_BuildVScrollInfo).l
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
                jsr     (Race_DrawRoadMarkingHud).l
                jsr     (Race_DrawRoadEdges).l

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
                jsr     (Race_DrawRearviewMirror).l
                jsr     (Race_BuildHScrollTable).l
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
                lea     (Race_EventBuffer).l,a0
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
                move.w  #0,(RaceResults_ram_Amount).l
                cmpi.w  #$FFFF,(Race_EventBuffer).l
                bne.w   .loc_C4E2
                tst.w   (Race_CopIndex).l
                beq.w   .loc_C4C0
                move.w  (Menu_ram_PlayerLevel).l,d0
                mulu.w  #$14,d0
                move.w  d0,(RaceResults_ram_Amount).l
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
                move.w  d0,(RaceResults_ram_Amount).l
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
                cmpi.w  #$FFFF,(Race_EventBuffer).l
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
                lea     (Race_ActorDefinitionTable).l,a4
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
                move.w  (a0,d0.w),(Race_ram_EngineSpeedBase).l
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


; *************************************************
; Function Race_CreateActors
; Fills the player/opponent actor structs from the actor definitions and the opponent
; id list, then initializes the static actor group and the player sprite fields.
; In:  Race_ActorList (player A + 15 opponents), Menu_ram_PlayerA/BOpponents,
;      Menu_ram_Player; Race_ActorDefinitionTable, Race_ActorGraphicsTable
; Out: actor structs at $FF1EAA + $80*i; static $FF2EAA/$FF2F2A; player A fields;
;      actor palette (Race_LoadActorPalette)
; Clobbers: all
; Notes: definition = type, pad, graphics index/sign, +$73, +$77, rating*100, name.
;        The 5 level pages (15 opponents each) are followed by "Player def" (id $4B).
; *************************************************

Race_CreateActors:
                clr.l   d0
                move.l  #$8000,(ram_FF1E76).l
                move.w  #0,(ram_FF1E94).l
; player A + 15 opponent actor structs (sentinels $FFFFFFFF)
                lea     (Race_ActorList).l,a0 ; get actor list
                lea     (Menu_ram_PlayerAOpponents).l,a3
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_CB00
                lea     (Menu_ram_PlayerBOpponents).l,a3
.loc_CB00:
                lea     (Race_ActorGraphicsTable).l,a4
                move.w  #0,d0
                move.w  #0,d1
.loopCreateActor:
                movea.l (a0)+,a1 ; get actor memory pointer
                cmpa.l  #$FFFFFFFF,a1 ; we reached the end of the list
                beq.w   .break

                move.b  d0,RaceActor_Index(a1) ; set actor index
                addq.w  #1,d0 ; increment index
; id list: $4B (player def) followed by the current level's 15 opponents
                move.w  (a3)+,d2 ; get actor id
                lea     (Race_ActorDefinitionTable).l,a2
                asl.w   #4,d2
                lea     (a2,d2.w),a2 ; load actor definition
                clr.w   d2
; definition byte 0 -> actor type/sprite; byte 1 -> +$74
                move.b  (a2)+,d2
                move.w  d2,RaceActor_Type(a1)
                move.b  (a2)+,STRUCT_OFFSET_74(a1)
                bclr    #1,STRUCT_OFFSET_6B(a1)
                move.b  (a2)+,d2
                bpl.w   .loc_CB50
                andi.b  #$7F,d2
                bset    #1,STRUCT_OFFSET_6B(a1)
.loc_CB50:
; byte 2 low 7 bits -> +$75 (graphics index); bit 7 -> +$6B bit1
                move.b  d2,RaceActor_GraphicsIndex(a1)
                ext.w   d2
                asl.w   #2,d2
                movea.l (a4,d2.w),a5
; graphics entry +$A/+$C/+$E -> actor sprite fields +$5E/+$60/+$5C
                move.w  $A(a5),STRUCT_OFFSET_5E(a1)
                move.w  $C(a5),STRUCT_OFFSET_60(a1)
                move.w  $E(a5),RaceActor_TileBase(a1)
                cmpa.l  #RacePlayerA,a1
                bne.w   .loc_CB80
                move.w  (ram_FF18AA).l,RaceActor_TileBase(a1)
.loc_CB80:
; bytes 3/4 -> +$73/+$77; byte 5 * 100 -> +$66 (actor rating/skill)
                move.b  (a2)+,STRUCT_OFFSET_73(a1)
                move.b  (a2)+,STRUCT_OFFSET_77(a1)
                move.b  (a2)+,d1
                ext.w   d1
                mulu.w  #100,d1
                move.w  d1,RaceActor_Rating(a1)
                move.b  #$FF,STRUCT_OFFSET_6E(a1)
                clr.l   d1
                move.w  d1,RaceActor_XLow(a1)
                move.w  d1,RaceActor_PosZ(a1)
                move.w  d1,STRUCT_OFFSET_1C(a1)
                move.w  d1,STRUCT_OFFSET_32(a1)
                move.w  d1,STRUCT_OFFSET_8(a1)
                move.w  d1,STRUCT_OFFSET_A(a1)
                move.w  d1,STRUCT_OFFSET_C(a1)
                move.w  d1,STRUCT_OFFSET_46(a1)
                move.w  d1,STRUCT_OFFSET_2C(a1)
                move.w  d1,STRUCT_OFFSET_22(a1)
                move.w  d1,STRUCT_OFFSET_24(a1)
                move.l  d1,RaceActor_FrameDistance(a1)
                move.w  d1,STRUCT_OFFSET_36(a1)
                move.w  d1,STRUCT_OFFSET_3A(a1)
                move.w  d1,STRUCT_OFFSET_38(a1)
                move.w  d1,STRUCT_OFFSET_3C(a1)
                move.w  d1,RaceActor_Speed(a1)
                move.w  d1,RaceActor_Acceleration(a1)
                move.w  d1,RaceActor_Gear(a1)
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
                move.w  (ram_FF18B2).l,(RacePlayerA + STRUCT_OFFSET_5E).l
                move.w  (ram_FF18B4).l,(RacePlayerA + STRUCT_OFFSET_60).l
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
; static actor group (type $10, indices $10+)
                lea     (Race_StaticActorList).l,a0
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


; per-level first opponent id (level 1-5)
Race_ActorLevelBase:
    dc.w 0, 15, 30, 45, 60

; Actor definitions: 16 bytes each: type, pad, graphics index (bit7 = special),
; +$73, +$77, rating*100, 10-byte name. Five pages of 15 opponents (levels 1-5),
; then the player definition (id $4B, all zero; player fields set separately).
Race_ActorDefinitionTable:
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


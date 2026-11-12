; *************************************************
; src/screens/menu_main.asm - main menu (player/track selection)
; ROM range: $003400-$004225 (src/screens/message.asm starts at $004226)
; Status:    analyzed (all functions line-by-line; card layout/demo visual TODO)
; Purpose:   main-menu background, player-mode and track selection, tooltips,
;            password-screen entry and the transition into a race.
; Flow:      TopLevel_Init -> Menu_Init -> Fade_InitFadeIn -> MainMenu_GameTick
; API:       Menu_Init, MainMenu_GameTick, MainMenu_HandleInput,
;            Menu_DrawPlayerInfo, Menu_DrawRaceSelection, Menu_DrawRaceCard,
;            Menu_ShowMessage, WriteNametableToBuffer,
;            Menu_WriteNametableMasked, Menu_BuildRaceTooltip
; Data:      Message_MsgArray, Menu_dRaceNameTable, Menu_ram_FrameBuffer,
;            Race_ram_ImageBuffer2
; Assets:    img_MainMenu_Background, img_MainMenu_RaceSelectionBackground,
;            img_PasswordMenu_PlayerSelection, img_Gamepad,
;            img_mainMenu_PlayerSelection, img_MainMenu_RaceBadges,
;            img_mainMenu_RaceCards, img_Intro_Font
; VRAM:      $0000 font tiles (50)
;            $4000 plane A/B nametable (128x32, shared; visible 40x28)
;            $6000 sprite table / H-scroll table (overlap; first 16 bytes cleared)
;            $7000 window nametable / 64x28 frame buffer
;            $7200 window row 4 (password-screen text; $7000 + $200)
;            $8000 main-menu background tiles (39)
;            $9000 race-selection background tiles (23)
;            $9400 password-screen selection border tiles (6)
;            $A000 gamepad tiles (90)
;            $B000 main-menu player-selection border tiles (6)
;            $C000 race-badge tiles (108)
;            $D000 race-card tiles (311)
;            $FFE0 default tile $7FF (all zero)
; *************************************************

; *************************************************
; Function Menu_Init
; Initializes the main menu screen and its persistent player/menu state.
; In:       - (reads Menu_ram_Player, player money, ram_MusicEnabled)
; Out:      VDP/VRAM/window frame buffer and menu state ready; no update
;           function is installed here (the caller sets MainMenu_GameTick).
; Clobbers: d0-d7/a0-a6
; Notes:    ROM $003400-$0037A9. Planes A/B share $4000; the window at $7000
;           holds the 64x28 frame buffer. WindowY=$1C with DOWN=0 places the
;           split at line 224, so every visible line (0-27) is a full-width
;           window line; the WindowX split is therefore unused. Caller runs the
;           fade-in afterwards.
; *************************************************

Menu_Init:
                move.w  #0,(MainMenu_ram_DemoMode).l
                move.w  #0,(MainMenu_ram_FrameCounter).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerA).l
                move.w  #0,(MainMenu_ram_ButtonsPlayerB).l
                move.w  #0,(MainMenu_ram_ChangedButtonsPlayerB).l
                move.w  #240,(Menu_ram_NextMessageTimer).l ; 240 frames = 4 s at 60 Hz
                move.w  #30,(Menu_ram_MessageBlinkTimer).l ; 30 frames = 0.5 s; negative reveals text
                move.w  #(8*6),(Menu_ram_CurrentMessageId).l ; index 6: "Press Start to race"
                move.l  #Global_ram_Palette,(Global_ram_PalettePtr).l ; use the global CRAM shadow
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l ; 64-frame cycle, 32 on / 32 off
                move.w  #9,(MenuPassword_ram_CursorY).l ; password cursor row
                move.w  #1,(MenuPassword_ram_CursorX).l ; password cursor column
; Reinitialize the selected profile only when its saved money is negative
; (an uninitialized/corrupt profile). Menu_ram_Player is 0 for A, $FFFF for B.
                tst.w   (Menu_ram_Player).l
                bne.w   .playerB ; nonzero -> player B
                tst.l   (Menu_ram_MoneyPlayerA).l
                bpl.w   .loc_3494 ; money >= 0: keep the profile
                jsr     (Intro_InitPlayerA).w ; negative -> reset A defaults
                bra.w   .loc_3494
.playerB:
                tst.l   (Menu_ram_MoneyPlayerB).l
                bpl.w   .loc_3494 ; money >= 0: keep the profile
                jsr     (Intro_InitPlayerB).w ; negative -> reset B defaults

.loc_3494:
; Program the VDP for the menu: shared plane A/B nametable at $4000, window
; at $7000, SAT/H-scroll table at $6000, 128x32 planes, H40, auto-increment 2.
                lea     (VdpCtrl).l,a0
                move.w  #$8004,(a0) ; H-int off, left column unblanked, HV counter normal, bit 2 fixed 1
                move.w  #$8174,(a0) ; display on, V-int on, DMA on, 28 rows
                move.w  #$8210,(a0) ; plane A nametable: $4000
                move.w  #$831C,(a0) ; window nametable: $7000
                move.w  #$8402,(a0) ; plane B nametable: $4000 (shared with A)
                move.w  #$8530,(a0) ; sprite attribute table: $6000
                move.w  #$870D,(a0) ; backdrop: palette 0, colour 13
                move.w  #$8AFF,(a0) ; H-int counter 255 (H-int stays disabled)
                move.w  #$8B00,(a0) ; external interrupt off, V-scroll full, H-scroll full
                move.w  #$8C81,(a0) ; H40, no interlace, shadow/highlight off
                move.w  #$8D18,(a0) ; H-scroll table: $6000
                move.w  #$8F02,(a0) ; auto-increment: 2
                move.w  #$9003,(a0) ; plane size: 128x32
                move.w  #$9100,(a0) ; WindowX split 0 (unused: Y split makes every line full-width window)
                move.w  #$921C,(a0) ; WindowY split line 224, DOWN=0 -> window covers rows 0-27
; Planes A/B share $4000; the window $7000 holds the 64x28 frame buffer.
; The 16-byte clear at $6000 covers SAT entries 0-1 and H-scroll entries 0-3;
; HSCR is full-screen, so this also zeros the only H-scroll entry that matters.
; clear sprites
                VDP_VRAM_WRITE $6000,(a0) ; SAT and H-scroll table are both at $6000
                move.w  #3,d0
.loopClearSprites:
                move.l  #0,(VdpData).l ; entry 0 link=0 terminates the sprite list
                dbf     d0,.loopClearSprites

                VDP_VSRAM_WRITE $0,(a0)
                move.l  #0,(VdpData).l ; clear VSRAM words 0-1 (full-screen V-scroll; plane A uses word 0)
; clear default tile
                movea.l #VdpData,a0 ; a0 = data port for fast longword stores
                VDP_VRAM_WRITE $FFE0,VdpCtrl
                move.w  #7,d0
.loopClearDefaultTile:
                move.l  #0,(a0) ; tile $7FF: all-zero default/transparent tile
                dbf     d0,.loopClearDefaultTile
; fill the visible 28 rows of the shared 128x32 plane with the default tile
                VDP_VRAM_WRITE $4000,VdpCtrl ; write to A/B nametable
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1 ; $07FF07FF: tile $7FF, low priority, palette 0, no flips
                move.w  #$6FF,d0 ; $700 longs = $E00 words = 128*28 cells
.loopFillBlack:
                move.l  d1,(a0)
                dbf     d0,.loopFillBlack
; Decompressions reuse Intro_ram_ImageBuffer; each map is consumed before the
; next decompression overwrites the buffer.
; Background: 39 tiles, 40x28 map at +$4E4/+$4E8; tiles -> VRAM $8000.
                lea     (img_MainMenu_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write background tiles to VRAM $8000
                move.l  #$8000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; write the 40x28 background map at (0,0)
                move.w  #40,d0 ; map width
                move.w  #28,d1 ; map height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; base tile $400 -> VRAM $8000
                move.w  #$4000,d5 ; plane A/B nametable
                move.w  #$80,d6 ; plane width = 128 cells
                lea     (Intro_ram_ImageBuffer + $4E8).l,a0
                jsr     (WriteNametable).w
; Race-selection background: 23 tiles, 40x14 map at +$2E4/+$2E8; tiles -> $9000.
                lea     (img_MainMenu_RaceSelectionBackground).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
; write race-selection tiles to VRAM $9000
                move.l  #$9000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; write the 40x14 race-selection map at (0,4)
                move.w  #40,d0 ; map width
                move.w  #14,d1 ; map height
                move.w  #0,d2 ; x
                move.w  #4,d3 ; y
                move.w  #$480,d4 ; base tile $480 -> VRAM $9000
                move.w  #$4000,d5 ; plane A/B nametable
                move.w  #$80,d6 ; plane width = 128 cells
                lea     (Intro_ram_ImageBuffer + $2E8).l,a0
                jsr     (WriteNametable).w
; Password-screen selection border: 6 tiles -> VRAM $9400. No map is written
; here; the border stays invisible until the password screen draws it.
                lea     (img_PasswordMenu_PlayerSelection).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write password-screen border tiles to VRAM $9400
                move.l  #$9400,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; Gamepad: 90 tiles -> VRAM $A000. Source map header is 12x9 at +$B44; this
; call copies only its top 12x6 rows (map at +$B48); base tile $500 -> $A000.
; @UNKNOWN(U-0002): why the header advertises 12x9 while only 12x6 rows are
; copied here and elsewhere | guess: lower 3 rows are unused padding | next:
; inspect img_Gamepad's full map and check for other readers of +$B48
                lea     (img_Gamepad).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressB).l
; write gamepad tiles to VRAM $A000
                move.l  #$A000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; write the top 12x6 gamepad map at (2,22)
                move.w  #12,d0 ; map width
                move.w  #6,d1 ; map height
                move.w  #2,d2 ; x
                move.w  #22,d3 ; y
                move.w  #$500,d4 ; base tile $500 -> VRAM $A000
                move.w  #$4000,d5 ; plane A/B nametable
                move.w  #$80,d6 ; plane width = 128 cells
                lea     (Intro_ram_ImageBuffer + $B48).l,a0
                jsr     (WriteNametable).w

; Main-menu player-selection border: 6 tiles -> VRAM $B000. Its 12x4 map at
; +$C8 is used later by Menu_DrawPlayerInfo with base tile $580.
                lea     (img_mainMenu_PlayerSelection).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.l  #$B000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; clear the 64x28 window frame buffer with the default tile $7FF
                lea     (Menu_ram_FrameBuffer).l,a0
                move.l  #$7FF07FF,d1 ; default tile
                move.w  #$37F,d0 ; $380 longs = $700 words = 64*28 cells
.loc_3670:
                move.l  d1,(a0)+
                dbf     d0,.loc_3670
; Race badges: 108 tiles -> VRAM $C000; 12x12 map at +$D84/+$D88.
                lea     (img_MainMenu_RaceBadges).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write race-badge tiles to VRAM $C000
                move.l  #$C000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; compose the 12x12 badge strip at (0,0) in Race_ram_ImageBuffer2
                move.w  #12,d0 ; width
                move.w  #12,d1 ; height
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #12,d6 ; plane width
                lea     (Race_ram_ImageBuffer2).l,a1 ; destination
                lea     (Intro_ram_ImageBuffer + $D88).l,a0 ; source map
                jsr     (WriteNametableToBuffer).l
; Race cards: 311 tiles -> VRAM $D000; 12x30 map at +$2764/+$2768.
                lea     (img_mainMenu_RaceCards).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write race-card tiles to VRAM $D000
                move.l  #$D000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; append the 12x30 card strip at (0,12); combined buffer is 12x42
                move.w  #12,d0 ; width
                move.w  #30,d1 ; height
                move.w  #0,d2 ; x
                move.w  #12,d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #12,d6 ; plane width
                lea     (Race_ram_ImageBuffer2).l,a1
                lea     (Intro_ram_ImageBuffer + $2768).l,a0
                jsr     (WriteNametableToBuffer).l
; Copy 4 palette lines (64 colours, 128 bytes) from the race-cards blob at
; +$26E4. This must happen before the font decompression overwrites the buffer.
                lea     (Intro_ram_ImageBuffer + $26E4).l,a0
                movea.l (Global_ram_PalettePtr).l,a1
; copy palette line 0
                move.w  #7,d0
.loopPalette0:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopPalette0
; copy palette line 1
                move.w  #7,d0
.loopPalette1:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopPalette1
; copy palette line 2
                move.w  #7,d0
.loopPalette2:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopPalette2
; copy palette line 3
                move.w  #7,d0
.loopPalette3:
                move.l  (a0)+,(a1)+
                dbf     d0,.loopPalette3
; Font: 50 tiles -> VRAM $0; header is $0808 plus the tile count.
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write font tiles to VRAM $0000
                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l

; Build the initial frame. The blink timer is still positive, so Menu_ShowMessage
; clears/hides the tooltip; MainMenu_GameTick reveals it after 30 frames.
                jsr     (Menu_ShowMessage).l
; select the first unfinished track, or the worst-placed finished track
                jsr     (MenuPassword_SelectCurrentTrack).w
                move.w  (Menu_ram_CurrentTrackId).l,d0 ; reload id for the draw call
; draw the selected race badge and the five race cards
                jsr     (Menu_DrawRaceSelection).l
; draw the active player's border, name and level
                jsr     (Menu_DrawPlayerInfo).l
; DMA the frame buffer to the window nametable $7000
                move.l  #Menu_ram_FrameBuffer,d0 ; source
                move.w  #$7000,d1 ; destination: window nametable
                move.w  #$700,d2 ; $700 words = 64x28 cells
                jsr     (DmaWriteVRAM).l

; Start the menu music only when enabled; the B button toggles this flag.
                tst.w   (ram_MusicEnabled).l
                beq.w   .return
                moveq   #1,d0
                jsr     (Audio_StartMusic).l

.return:
                rts
; End of function Menu_Init

; *************************************************
; Function WriteNametableToBuffer
; Copies a packed tile-word rectangle into a RAM nametable buffer with a fixed
; row stride (the RAM counterpart of WriteNametable).
; In:       d0 - width in cells (>= 1)
;           d1 - height in cells (>= 1)
;           d2 - topLeftX in cells
;           d3 - topLeftY in cells
;           d4 - base tile word added to every source word (tile number plus
;                palette/priority bits; 0 for prebuilt full words)
;           d6 - destination plane width in cells (row stride / 2)
;           a0 - source, packed width*height relative tile words
;           a1 - destination RAM buffer (not VRAM)
; Out:      a0 - past the source words
;           a1 - destination + (y+height)*planeWidth*2 + x*2
; Clobbers: d0-d3/d6/a0/a1 (d4/d5 untouched)
; Notes:    ROM $0037AA-$0037D1. Destination word address =
;           a1 + y*planeWidth*2 + x*2. Each source word is copied with d4
;           added; rows are separated by (planeWidth-width)*2 bytes. The
;           y*stride and x*2 offsets are added with adda.w, so only their low
;           16 bits are used (callers keep them small). No bounds checks; no
;           VDP access, so auto-increment is irrelevant.
; *************************************************

WriteNametableToBuffer:
                asl.w   #1,d6 ; d6 = bytes per destination row
                mulu.w  d6,d3 ; d3 = y * bytesPerRow
                sub.w   d0,d6
                sub.w   d0,d6 ; d6 = stride - width*2 (row tail to skip)
                adda.w  d3,a1 ; a1 += y*stride (low 16 bits)
                asl.w   #1,d2 ; d2 = x*2
                adda.w  d2,a1 ; a1 += x*2
                subq.w  #1,d1 ; height-1 rows
                subq.w  #1,d0 ; width-1 cells
                move.w  d0,d2 ; column counter

.loc_37BE:
                move.w  d2,d0 ; restore width-1 for this row

.loc_37C0:
                move.w  (a0)+,d3 ; source tile word
                add.w   d4,d3 ; apply base tile/palette bits
                move.w  d3,(a1)+ ; store into the RAM nametable
                dbf     d0,.loc_37C0
                adda.w  d6,a1 ; skip the unused row tail
                dbf     d1,.loc_37BE
                rts
; End of function WriteNametableToBuffer

; *************************************************
; Function Menu_WriteNametableMasked
; Like WriteNametableToBuffer, but overwrites only cells whose destination
; word already equals a sentinel word (used for the race cards).
; In:       d0 - width in cells (>= 1)
;           d1 - height in cells (>= 1)
;           d2 - topLeftX in cells
;           d3 - topLeftY in cells
;           d4 - base tile word added on a match
;           d5 - destination word to match (full nametable word, e.g. $7FF)
;           d6 - destination plane width in cells (row stride / 2)
;           a0 - source, packed width*height relative tile words
;           a1 - destination RAM buffer (not VRAM)
; Out:      a0 - past the source words
;           a1 - destination + (y+height)*planeWidth*2 + x*2
; Clobbers: d0-d3/d6/a0/a1 (d4/d5 untouched)
; Notes:    ROM $0037D2-$003801. Equality test, not a bitwise mask: only
;           cells whose current destination word equals d5 are replaced by
;           source+d4. Non-matching cells keep their old contents; a1 still
;           advances across them. Same offset/stride rules as
;           WriteNametableToBuffer; no bounds checks; no VDP access.
; *************************************************

Menu_WriteNametableMasked:
                asl.w   #1,d6 ; d6 = bytes per destination row
                mulu.w  d6,d3 ; d3 = y * bytesPerRow
                sub.w   d0,d6
                sub.w   d0,d6 ; d6 = stride - width*2 (row tail to skip)
                adda.w  d3,a1 ; a1 += y*stride (low 16 bits)
                asl.w   #1,d2 ; d2 = x*2
                adda.w  d2,a1 ; a1 += x*2
                subq.w  #1,d1 ; height-1 rows
                subq.w  #1,d0 ; width-1 cells
                move.w  d0,d2 ; column counter
.loc_37E6:
                move.w  d2,d0 ; restore width-1 for this row
.loc_37E8:
                move.w  (a0)+,d3 ; source tile word
                cmp.w   (a1)+,d5 ; destination word == sentinel?
                bne.w   .loc_37F6 ; no: keep the old cell
                add.w   d4,d3 ; apply base tile/palette bits
                move.w  d3,-2(a1) ; overwrite the cell just read
.loc_37F6:
                dbf     d0,.loc_37E8
                adda.w  d6,a1 ; skip the unused row tail
                dbf     d1,.loc_37E6
                rts
; End of function Menu_WriteNametableMasked

; *************************************************
; Function MainMenu_GameTick
; Main-menu per-frame update, called from VerticalInterrupt.
; In:       MainMenu_ram_FrameCounter/ButtonsPlayerA/B/ChangedButtonsPlayerA/B;
;           Menu_ram_MessageBlinkTimer/NextMessageTimer/CurrentMessageId;
;           Menu_ram_FrameBuffer; ram_UpdateFunction.
; Out:      button edges, timers/tooltip, frame buffer/VRAM and
;           ram_UpdateFunction updated; DemoMode set on timeout.
; Clobbers: d0-d6/a0-a1 directly; called handlers may clobber more.
;           VerticalInterrupt saves all registers around the callback.
; Notes:    ROM $003802-$0039AD. DMA uploads the previous frame buffer; input
;           and tooltip updates become visible on the next frame. 1800 idle
;           frames (30 s) set DemoMode=1 and end the stage; Start exits on
;           release from either pad. Tooltips advance about every 240 frames
;           and wrap to index 6.
; *************************************************

MainMenu_GameTick:
                addi.w  #1,(MainMenu_ram_FrameCounter).l ; idle/demo timer
                cmpi.w  #1800,(MainMenu_ram_FrameCounter).l ; 30 s at 60 Hz
                bcs.w   .inputPlayerA ; still below timeout
; 30 seconds without any button -> request high-score/demo stage
                move.w  #1,(MainMenu_ram_DemoMode).l ; top-level checks this
                move.w  #0,(MainMenu_ram_FrameCounter).l ; restart timeout
                bra.w   .endStage ; end the menu stage now

.inputPlayerA:
; DMA the previous frame buffer to the window nametable $7000
                move.l  #Menu_ram_FrameBuffer,d0 ; source
                move.w  #$7000,d1 ; destination: window nametable
                move.w  #$700,d2 ; $700 words = 64x28 cells
                jsr     (DmaWriteVRAM).l
; GetInputPlayerA/B define only d0.b; DmaWriteVRAM left d0 < $100, so the
; byte results can be stored and tested as words without masking.
; latch previous A state, then read the new state
                move.w  (MainMenu_ram_ButtonsPlayerA).l,(MainMenu_ram_ChangedButtonsPlayerA).l
                jsr     (GetInputPlayerA).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerA).l ; current A buttons
                beq.w   .loc_385E ; no A button held -> keep timeout
                move.w  #0,(MainMenu_ram_FrameCounter).l ; any A button held -> reset timer
.loc_385E:
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerA).l ; previous ^ new edges
; latch previous B state, then read the new state
                move.w  (MainMenu_ram_ButtonsPlayerB).l,(MainMenu_ram_ChangedButtonsPlayerB).l
                jsr     (GetInputPlayerB).w
                move.w  d0,(MainMenu_ram_ButtonsPlayerB).l ; current B buttons
                beq.w   .loc_3884 ; no B button held -> keep timeout
                move.w  #0,(MainMenu_ram_FrameCounter).l ; any B button held -> reset timer
.loc_3884:
                eor.w   d0,(MainMenu_ram_ChangedButtonsPlayerB).l ; previous ^ new edges
; Start is edge-triggered: keep waiting while held, exit on release
                move.w  (MainMenu_ram_ButtonsPlayerA).l,d0
                andi.w  #$80,d0
                bne.w   .checkPlayerBPressedStart ; A still holds Start -> wait
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d0
                andi.w  #$80,d0
                bne.w   .endStage ; A released Start (current=0, changed=1)
.checkPlayerBPressedStart:
                move.w  (MainMenu_ram_ButtonsPlayerB).l,d0
                andi.w  #$80,d0
                bne.w   .handleInputPlayerB ; B still holds Start -> wait
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d0
                andi.w  #$80,d0
                bne.w   .endStage ; B released Start

; Handle only newly pressed buttons: Changed & Buttons drops pure releases.
; B is handled first; if it enters the password screen, A is skipped this frame.
.handleInputPlayerB:
                move.w  (MainMenu_ram_ChangedButtonsPlayerB).l,d0 ; no B edge -> try A
                beq.w   .handleInputPlayerA
                and.w   (MainMenu_ram_ButtonsPlayerB).l,d0 ; only releases -> try A
                beq.w   .handleInputPlayerA
                move.l  #MainMenu_ram_ButtonsPlayerB,(Menu_ram_CurrentButtonsPtr).l ; identify B for C/password
                jsr     (MainMenu_HandleInput).l
                cmpi.l  #MainMenu_GameTick,(ram_UpdateFunction).l
                bne.w   .updateMessage ; B opened the password screen -> skip A input

.handleInputPlayerA:
                move.w  (MainMenu_ram_ChangedButtonsPlayerA).l,d0 ; no A edge -> update tooltip
                beq.w   .updateMessage
                and.w   (MainMenu_ram_ButtonsPlayerA).l,d0 ; only releases -> update tooltip
                beq.w   .updateMessage
                move.l  #MainMenu_ram_ButtonsPlayerA,(Menu_ram_CurrentButtonsPtr).l
                jsr     (MainMenu_HandleInput).l

.updateMessage:
                subq.w  #1,(Menu_ram_MessageBlinkTimer).l ; negative reveals the text
                subq.w  #1,(Menu_ram_NextMessageTimer).l ; negative -> advance tooltip
                bpl.w   .end ; still >= 0 -> keep this tooltip
                move.w  #30,(Menu_ram_MessageBlinkTimer).l ; re-hide text for 30 frames
                move.w  #240,(Menu_ram_NextMessageTimer).l ; next change in 240 frames
                addq.w  #8,(Menu_ram_CurrentMessageId).l ; next 8-byte MsgArray entry
                cmpi.w  #(8*6),(Menu_ram_CurrentMessageId).l ; first tooltip id
                bpl.w   .changeMessage ; id >= 6 -> keep it
                move.w  #(8*6),(Menu_ram_CurrentMessageId).l ; clamp to index 6
.changeMessage:
                move.w  (Menu_ram_CurrentMessageId).l,d0 ; fetch text pointer
                lea     (Message_MsgArray).l,a0
                movea.l (a0,d0.w),a0
                cmpa.l  #$FFFFFFFF,a0 ; -1 marks the end of the tooltip list
                bne.w   .end ; valid pointer -> draw it
                move.w  #(8*6),(Menu_ram_CurrentMessageId).l ; end marker -> wrap
                beq.w   .end ; redundant: Z is clear after the move, but .end follows
.end:
                jsr     (Menu_ShowMessage).l ; draw the current tooltip
                jsr     (Audio_Update).l ; flush the audio command mailbox
                move.w  #1,d2 ; divider: Rand_StepLfsrAMod returns remainder 0
                jsr     (Rand_StepLfsrAMod).l ; advance the Rand_ram_LfsrA LFSR
                jsr     (Rand_StepLfsrB).l ; advance the Rand_ram_LfsrB LFSR
                jsr     (Rand_NextWord).l ; advance the main lagged-sum PRNG
                rts
.endStage:
                jsr     (Audio_StopMusic).l ; stop music, let top-level advance
                move.l  #0,(ram_UpdateFunction).l ; stage finished
                bra.s   .end ; still run the common tail once
; End of function MainMenu_GameTick

; *************************************************
; Function Menu_DrawPlayerInfo
; Draws the selection border and the name + level of each enabled player.
; In:       Menu_ram_PlayerMode bits 0/1 select A/B info (1=A, 2=B, 3=both);
;           Menu_ram_Player (0=A, nonzero=B) selects the border side and the
;           palette for the highlighted player; player name/level globals;
;           Menu_ram_FrameBuffer.
; Out:      Frame-buffer rows 17-20 updated: border at x=1 or 27, name rows
;           at x=2 or 28.
; Clobbers: d0-d4/d6/a0-a3; d5 and d7 preserved.
; Notes:    ROM $0039AE-$003B55. Each row is 64 cells; the clear writes 7 longs
;           (14 cells) at x=0-13, skips 12 badge cells, writes 14 cells at
;           x=26-39, then skips 24 cells to reach the next row. The highlighted
;           player's text uses palette 2 ($4000), the other player palette 3
;           ($6000). The border image uses base tile word $580 (tile data at
;           $B000). The level is added to the ASCII '0', so the display
;           assumes a single decimal digit.
; *************************************************

Menu_DrawPlayerInfo:
                lea     (Menu_ram_FrameBuffer + $880).l,a0 ; row 17, x = 0
                move.l  #$7FF07FF,d0 ; two default-tile words per store
                move.w  #3,d1 ; 4 rows (dbf)
.loopClear:
; clear x = 0-13, leaving the x = 14-25 race-badge area intact
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                adda.w  #(12*2),a0 ; skip 12 badge cells (x = 14-25)
; clear x = 26-39
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                adda.w  #(2*24),a0 ; x = 40 -> next row x = 0
                dbf     d1,.loopClear
; load the 12x4 selection-border image into RAM
                lea     (img_mainMenu_PlayerSelection).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; write the border at x = 1 (A) or x = 27 (B), y = 17
                lea     (Intro_ram_ImageBuffer).l,a0
                move.w  #12,d0 ; width
                move.w  #4,d1 ; height
                move.w  #1,d2 ; x for player A
                tst.w   (Menu_ram_Player).l ; 0 = A highlighted
                beq.w   .playerA
                move.w  #27,d2 ; x for player B
.playerA:
                move.w  #17,d3 ; y
                move.w  #$580,d4 ; base tile word, tile data at $B000
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer + $C8).l,a0 ; tilemap at +$C8
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w

                btst    #0,(Menu_ram_PlayerMode + 1).l ; low byte of mode word
                beq.w   .drawPlayerBInfo ; mode 2 -> A hidden
; draw player A info
                lea     (Menu_ram_StrPlayerName).l,a1
                move.w  #18,(a1)+ ; y
                move.w  #2,(a1)+ ; x
                move.w  #2,(a1)+ ; height
                move.w  #10,(a1)+ ; width
; copy player name - 10 bytes
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; append "Level  0": add.w targets the ASCII '0', one digit only
                move.l  #'Leve',(a1)+
                move.l  #'l  0',d0
                add.w   (Menu_ram_PlayerALevel).l,d0
                move.l  d0,(a1)+
                move.w  #'  ',(a1)+
; EncodeString consumes 20 chars as 2 rows of 10 (name + level)
                lea     (Menu_ram_StrPlayerName).l,a0 ; string
                lea     (Intro_ram_ImageBuffer).l,a1 ; destination
                jsr     (EncodeString).w
; draw it to the framebuffer
                lea     (Menu_ram_StrPlayerName).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$4000,d4 ; palette 2 (highlighted-player text)
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_3AB0 ; A highlighted -> keep palette 2
                move.w  #$6000,d4 ; B highlighted -> A text uses palette 3
.loc_3AB0:
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w

.drawPlayerBInfo:
                btst    #1,(Menu_ram_PlayerMode + 1).l ; low byte of mode word
                beq.w   .return ; mode 1 -> B hidden
; draw player B info
                lea     (Menu_ram_StrPlayerName).l,a1
                move.w  #18,(a1)+ ; y
                move.w  #28,(a1)+ ; x
                move.w  #2,(a1)+ ; height
                move.w  #10,(a1)+ ; width
; copy player name - 10 bytes
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
; append "Level  0": add.w targets the ASCII '0', one digit only
                move.l  #'Leve',(a1)+
                move.l  #'l  0',d0
                add.w   (Menu_ram_PlayerBLevel).l,d0
                move.l  d0,(a1)+
                move.w  #'  ',(a1)+
; EncodeString consumes 20 chars as 2 rows of 10 (name + level)
                lea     (Menu_ram_StrPlayerName).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
; draw it to the framebuffer
                lea     (Menu_ram_StrPlayerName).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$4000,d4 ; palette 2 (highlighted-player text)
                tst.w   (Menu_ram_Player).l
                bne.w   .loc_3B40 ; B highlighted -> keep palette 2
                move.w  #$6000,d4 ; A highlighted -> B text uses palette 3

.loc_3B40:
                move.w  #$40,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w
.return:
                rts
; End of function Menu_DrawPlayerInfo

; *************************************************
; Function Menu_BuildRaceTooltip
; Copies a race-name record into TempString and inserts a one-decimal value
; before the "miles" text.
; In:       d0 - even track id (0,2,4,6,8); level from the highlighted player.
; Out:      Menu_ram_TempString gets an 8-byte text header + 5x20 chars; the
;           fractional digit lands at offset 97, '.' at 96, and the integer
;           digits follow backwards (94-95 for a two-digit value), so the value
;           ends immediately before "miles" at offset 98.
; Clobbers: d1/a0/a1; d0 is preserved.
; Notes:    ROM $003B56-$003BE1. Menu_dRaceNameTable/unk_25EC0 hold five
;           longword pointers; d0*2 is the byte offset (d0 is already even).
;           The name record is fixed at 5x20, so 108 bytes are copied. The
;           level table is indexed by level-1; value = level_word * 16 / $210
;           (tenths), then /10: the remainder is the fractional digit and the
;           quotient is written as integer digits in reverse. Level is not
;           bounds-checked.
; *************************************************

Menu_BuildRaceTooltip:
                move.w  d0,d1 ; even track id -> byte offset (id*2) for longword table
                asl.w   #1,d1
                lea     (Menu_dRaceNameTable).l,a0
                movea.l (a0,d1.w),a0 ; name text record
                lea     (Menu_ram_TempString).l,a1
                move.w  4(a0),d1 ; header: y,x,height,width -> height
                mulu.w  6(a0),d1 ; * width = character count (5*20 = 100)
                addq.w  #7,d1 ; dbf count: 8-byte header + 100 chars = 108 bytes

.loc_3B74:
                move.b  (a0)+,(a1)+ ; copy header and all 100 chars
                dbf     d1,.loc_3B74
                suba.w  #$B,a1 ; 108-11 = 97: write backwards from the last line
                lea     (unk_25EC0).l,a0
                move.w  d0,d1
                asl.w   #1,d1 ; byte offset into the five longword track pointers
                movea.l (a0,d1.w),a0 ; track record
                movea.l (a0),a0 ; +$00 = level-word table (5 words)
                move.w  (Menu_ram_PlayerALevel).l,d1
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_3BA4 ; A highlighted -> use A level
                move.w  (Menu_ram_PlayerBLevel).l,d1 ; B highlighted

.loc_3BA4:
                subq.w  #1,d1 ; levels are 1-based
                asl.w   #1,d1
                adda.w  d1,a0 ; level-word pointer
                move.w  (a0),d1 ; level word; @UNKNOWN(U-0001): physical meaning/unit | guess: distance in tenths of a mile | next: compare level words with the in-game tooltip
                mulu.w  #$10,d1
                divu.w  #$210,d1 ; d1 = level_word * 16 / 528
                andi.l  #$FFFF,d1 ; drop remainder word
                divu.w  #$A,d1 ; quotient = integer part, remainder = tenths
                swap    d1 ; low word = remainder (fractional digit)
                addi.w  #$30,d1 ; '0'
                move.b  d1,-(a1) ; write fractional digit
                move.b  #$2E,-(a1) ; '.'
                clr.w   d1
                swap    d1 ; low word = integer quotient

.loc_3BCE:
                divu.w  #$A,d1 ; next decimal digit in remainder
                swap    d1
                addi.w  #$30,d1 ; '0'
                move.b  d1,-(a1) ; build integer part backwards
                clr.w   d1
                swap    d1
                bne.s   .loc_3BCE
                rts
; End of function Menu_BuildRaceTooltip

; *************************************************
; Function MainMenu_HandleInput
; Handles a newly pressed button on the main menu.
; In:  d0 - newly pressed buttons (Changed & Buttons), SACBRLDU
;      Menu_ram_CurrentButtonsPtr - which player pressed
; Out: player mode/track/music/password screen updated
; Clobbers: d0-d2/a0-a1
; Notes: ROM $003BE2-$003F17. A cycles player mode 1 -> 3 -> 2 -> 1, B toggles
;        music, Up/Right and Down/Left move the current track by +-2 (wrapping
;        0..8), C opens the password screen for the player who pressed it.
;        Button bits: Start $80, A $40, C $20, B $10, Right $08, Left $04,
;        Down $02, Up $01.
; *************************************************

MainMenu_HandleInput:
                move.b  d0,(MainMenu_ram_CurrentButtons).l ; edge mask -> SACBRLDU byte
                btst    #6,(MainMenu_ram_CurrentButtons).l
                beq.w   .checkB
; A pressed
                cmpi.w  #1,(Menu_ram_PlayerMode).l ; if player A mode
                bne.w   .checkPlayerBMode
                move.w  #3,(Menu_ram_PlayerMode).l ; set two player mode
                move.w  #(8*1),(Menu_ram_CurrentMessageId).l ; two player mode selected
                bra.w   .loc_3C74
.checkPlayerBMode:
                cmpi.w  #2,(Menu_ram_PlayerMode).l ; if player B mode
                bne.w   .setPlayerBMode
                move.w  #1,(Menu_ram_PlayerMode).l ; set player A mode
                move.w  #(8*0),(Menu_ram_CurrentMessageId).l ; one player mode selected
                move.w  #0,(Menu_ram_Player).l
                jsr     (MenuPassword_SelectCurrentTrack).w
                move.w  (Menu_ram_CurrentTrackId).l,d0
                jsr     (Menu_DrawRaceSelection).l
                bra.w   .loc_3C74
.setPlayerBMode:
                move.w  #2,(Menu_ram_PlayerMode).l ; set player B mode
                move.w  #(8*0),(Menu_ram_CurrentMessageId).l ; one player mode selected
                move.w  #$FFFF,(Menu_ram_Player).l
                jsr     (MenuPassword_SelectCurrentTrack).w
                move.w  (Menu_ram_CurrentTrackId).l,d0
                jsr     (Menu_DrawRaceSelection).l
.loc_3C74:
                jsr     (Menu_DrawPlayerInfo).w
                move.w  #240,(Menu_ram_NextMessageTimer).l
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
.checkB:
                btst    #4,(MainMenu_ram_CurrentButtons).l
                beq.w   .checkUpRight
; handle B
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                move.w  #(8*3),(Menu_ram_CurrentMessageId).l ; music is off
                jsr     (Audio_StopMusic).l
                move.w  #0,(ram_CurrentSong).l
                eori.w  #1,(ram_MusicEnabled).l ; enable or disable music
                beq.w   .checkUpRight
                move.w  #(8*2),(Menu_ram_CurrentMessageId).l ; music is on
                moveq   #1,d0
                move.w  d0,(ram_CurrentSong).l
                jsr     (Audio_StartMusic).l
.checkUpRight:
                btst    #0,(MainMenu_ram_CurrentButtons).l
                bne.w   .handleUpRight
                btst    #3,(MainMenu_ram_CurrentButtons).l
                beq.w   .checkLeftDown
.handleUpRight:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                addq.w  #2,d0
                cmp.w   #8,d0 ; five tracks use ids 0,2,4,6,8
                ble.w   .loc_3D08
                move.w  #0,d0 ; wrap past the last track
.loc_3D08:
                move.w  d0,(Menu_ram_CurrentTrackId).l
                jsr     (Menu_DrawRaceSelection).l
                move.w  (Menu_ram_CurrentTrackId).l,d0
                bsr.w   Menu_BuildRaceTooltip
                move.w  #(8*4),(Menu_ram_CurrentMessageId).l
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                jsr     (Menu_DrawPlayerInfo).w
.checkLeftDown:
                btst    #1,(MainMenu_ram_CurrentButtons).l
                bne.w   .handleLeftDown
                btst    #2,(MainMenu_ram_CurrentButtons).l
                beq.w   .checkC
.handleLeftDown:
                move.w  (Menu_ram_CurrentTrackId).l,d0
                subq.w  #2,d0
                bpl.w   .loc_3D62 ; still >= 0
                move.w  #8,d0 ; wrap before the first track
.loc_3D62:
                move.w  d0,(Menu_ram_CurrentTrackId).l
                jsr     (Menu_DrawRaceSelection).l
                move.w  (Menu_ram_CurrentTrackId).l,d0
                bsr.w   Menu_BuildRaceTooltip
                move.w  #(8*4),(Menu_ram_CurrentMessageId).l
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                jsr     (Menu_DrawPlayerInfo).w
.checkC:
                btst    #5,(MainMenu_ram_CurrentButtons).l
                beq.w   .return
; C: open the password screen for the player who pressed it
                move.w  #(8*12),(Menu_ram_CurrentMessageId).l ; Press 'start' to exit
                move.w  #30,(Menu_ram_MessageBlinkTimer).l
                move.w  #240,(Menu_ram_NextMessageTimer).l
                move.w  #$FFFF,(MenuPassword_ram_HoldTimer).l ; no hold-repeat until a state change
                move.w  #0,(MenuPassword_ram_HeldButtons).l
                move.l  #MainMenu_ram_ChangedButtonsPlayerA,(Menu_ram_ChangedButtonsPtr).l
                move.l  #MenuPassword_ram_StrPlayerAName,(MenuPassword_ram_StrPlayerNamePtr).l
                move.l  #MenuPassword_ram_StrPlayerAPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
                cmpi.l  #MainMenu_ram_ButtonsPlayerA,(Menu_ram_CurrentButtonsPtr).l
                beq.w   .loc_3E12
; player B
                move.l  #MainMenu_ram_ChangedButtonsPlayerB,(Menu_ram_ChangedButtonsPtr).l
                move.l  #MenuPassword_ram_StrPlayerBName,(MenuPassword_ram_StrPlayerNamePtr).l
                move.l  #MenuPassword_ram_StrPlayerBPassword,(MenuPassword_ram_StrPlayerPasswordPtr).l
.loc_3E12:
                move.w  (dStringCodeTable + 2 * ' ').w,d0 ; space tile index
                addi.w  #$6000,d0 ; palette line 3
                swap    d0
                move.w  (dStringCodeTable + 2 * ' ').w,d0
                addi.w  #$6000,d0 ; build a 2-cell space/palette-3 longword
                lea     (Menu_ram_FrameBuffer + $200).l,a0 ; y = 4
; fill rows 4-20 (17 lines) with spaces
                move.w  #$21F,d1 ; $220 longs = 64*17 cells
.loopClear:
                move.l  d0,(a0)+
                dbf     d1,.loopClear
; load player selection border image
                lea     (img_PasswordMenu_PlayerSelection).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l

                move.w  #16,d0 ; width
                move.w  #14,d1 ; height
                move.w  #2,d2 ; x for player A
                cmpi.l  #MenuPassword_ram_StrPlayerBName,(MenuPassword_ram_StrPlayerNamePtr).l
                bne.w   .loc_3E64
                move.w  #22,d2 ; x for player B
.loc_3E64:
                move.w  #5,d3 ; y
                move.w  #$4A0,d4 ; base tile index, address = $9400
                move.w  #64,d6 ; plane width
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                lea     (Intro_ram_ImageBuffer + $C8).l,a0 ; source
                jsr     (WriteNametableToBuffer).w
; encode the static "Name"/"Password" labels (Menu_dPasswordLabels is a 7x12 text record)
                lea     (Menu_dPasswordLabels).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).w
; write the label text for player B at x=24, y=7
                lea     (Menu_dPasswordLabels).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  #24,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette line 3
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w
; write the same label text for player A at x=4, y=7
                lea     (Menu_dPasswordLabels).l,a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  #4,d2 ; x
                move.w  #7,d3 ; y
                move.w  #$6000,d4 ; base tile index 0, palette line 3
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (WriteNametableToBuffer).w

                jsr     (MenuPassword_DrawNamesAndPasswords).w
                cmpi.l  #FadeWithFunction_GameTick,(ram_UpdateFunction).l
                bne.w   .loc_3F0C
                move.l  #MenuPassword_GameTick,(Fade_ram_UpdateFunction).l
                bra.w   .return
.loc_3F0C:
                move.l  #MenuPassword_GameTick,(ram_UpdateFunction).l
.return:
                rts
; End of function MainMenu_HandleInput

; *************************************************
; Function Menu_DrawRaceSelection
; Clears the race area, then draws the selected race badge and the five-card
; carousel for the active player's places.
; In:  d0 - current race id (even: 0,2,4,6,8); Menu_ram_Player selects A/B
; Out: Menu_ram_FrameBuffer rows 6-19 updated; Menu_PlayerPlacesPtr set;
;      Menu_ram_CurrentlyDrawnRaceCard ends at the far-left card's id
; Clobbers: d0-d6/a0-a1
; Notes: ROM $003F18-$00408D. Rows 6-16 are cleared first. Race badges are 12x2
;        cells (48 bytes) each in Race_ram_ImageBuffer2; the id is even, so
;        id*$18 gives the byte offset. The five cards are R at
;        x=14, R+2 at x=21, R+4 at x=25, R+8 at x=7 and R+6 at x=3 (all mod 10);
;        each draws place[id] through Menu_DrawRaceCard.
; *************************************************

Menu_DrawRaceSelection:
                move.w  d0,(Menu_ram_CurrentlyDrawnRaceCard).l ; save the selected id
                lea     (Menu_ram_FrameBuffer + $300).l,a0 ; row 6 (64*2*6 = $300)
; clear rows 6-16 (11 rows)
                move.w  #$7FF,d1
                swap    d1
                move.w  #$7FF,d1 ; $7FF07FF: two default-tile words
                move.w  #$15F,d0 ; $160 longs = 64*11 cells
.loopClear:
                move.l  d1,(a0)+
                dbf     d0,.loopClear

                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d0
                andi.l  #$FFFF,d0
                divu.w  #10,d0 ; @UNKNOWN(U-0003): purpose of this even normalization | guess: leftover encoding; identity for even ids 0..8 | next: audit all writers and try an odd id
                swap    d0 ; low word = remainder (the id itself for 0..8)
                andi.w  #$FFFE,d0 ; force an even id
; draw race badge
                lea     (Race_ram_ImageBuffer2).l,a0 ; badge tilemaps (12x12 strip)
                mulu.w  #$18,d0 ; even id -> id*$18 = raceIndex*48 bytes (12x2 cells)
                adda.w  d0,a0
                move.w  #12,d0 ; width
                move.w  #2,d1 ; height
                move.w  #14,d2 ; x
                move.w  #18,d3 ; y
                move.w  #$600,d4 ; base tile index, address = $C000
                move.w  #64,d6 ; plane width
                lea     (Menu_ram_FrameBuffer).l,a1
                jsr     (WriteNametableToBuffer).w
; draw the selected race card (R) at x=14
                lea     (Menu_ram_PlayerAPlaces).l,a0 ; player A
                tst.w   (Menu_ram_Player).l
                beq.w   .loc_3F92
                lea     (Menu_ram_PlayerBPlaces).l,a0 ; player B
.loc_3F92:
                move.l  a0,(Menu_PlayerPlacesPtr).l
                move.w  #0,d0 ; place is loaded from the array below
                move.w  #14,d2 ; x
                move.w  #10,d3 ; y
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1
                andi.l  #$FFFF,d1
                divu.w  #$A,d1 ; same even-id normalization (identity for 0..8)
                swap    d1
                andi.w  #$FFFE,d1
                move.w  d1,(Menu_ram_CurrentlyDrawnRaceCard).l ; race id -> place-array byte offset
                move.w  (a0,d1.w),d0 ; place for this race
                jsr     (Menu_DrawRaceCard).l
; draw the next race (R+2) to the right, at x=21
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1
                addq.w  #2,d1 ; race id
                cmp.w   #10,d1
                bmi.w   .loc_3FDE
                move.w  #0,d1
.loc_3FDE:
                move.w  d1,(Menu_ram_CurrentlyDrawnRaceCard).l
                move.w  #21,d2 ; x
                move.w  #8,d3 ; y
                movea.l (Menu_PlayerPlacesPtr).l,a0
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l
; draw the race two ahead (R+4) at the far right, x=25
.loc_3FFC:
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1
                addq.w  #2,d1 ; race id
                cmp.w   #10,d1
                bmi.w   .loc_4010
                move.w  #0,d1
.loc_4010:
                move.w  d1,(Menu_ram_CurrentlyDrawnRaceCard).l
                move.w  #25,d2 ; x
                move.w  #6,d3 ; y
                movea.l (Menu_PlayerPlacesPtr).l,a0
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l
; draw the previous race (R-2 = R+8 mod 10) at x=7
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1
                addq.w  #2,d1 ; R+6: saved for the far-left card
                cmp.w   #$A,d1
                bmi.w   .loc_4042
                move.w  #0,d1
.loc_4042:
                move.w  d1,(Menu_ram_CurrentlyDrawnRaceCard).l
                addq.w  #2,d1 ; R+8: draw this one
                cmp.w   #$A,d1
                bmi.w   .loc_4056
                move.w  #0,d1
.loc_4056:
                move.w  #7,d2 ; x
                move.w  #8,d3 ; y
                movea.l (Menu_PlayerPlacesPtr).l,a0
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l
; draw the race two back (R-4 = R+6 mod 10) at the far left, x=3
                move.w  (Menu_ram_CurrentlyDrawnRaceCard).l,d1 ; R+6 saved above
                move.w  #3,d2 ; x
                move.w  #6,d3 ; y
                movea.l (Menu_PlayerPlacesPtr).l,a0
                move.w  (a0,d1.w),d0
                jsr     (Menu_DrawRaceCard).l

                rts
; End of function Menu_DrawRaceSelection

; *************************************************
; Function Menu_DrawRaceCard
; Copies one race card and writes its place text ("1st/2nd/3rd/Nth").
; In:  d0 - player place (0 = no text; 1..19 supported)
;      d1 - race id (even byte offset), d2 - x, d3 - y
; Out: Menu_ram_FrameBuffer updated (masked write)
; Clobbers: d0-d6/a0-a1
; Notes: ROM $00408E-$00417B. Each card is 12x6 = 72 words (144 bytes) at
;        Race_ram_ImageBuffer2+$120. Because d1 is even, d1*$48 steps by 144
;        bytes (one card) per two ids. Place text occupies the four cells at
;        row 5, columns 4-7; the surrounding cells are zeroed so card art does
;        not show through. Only 10-19 are handled for two-digit places; 20+
;        would emit a non-digit tile. Mask tile $7FF = default black, so only
;        those cells replace the background.
; *************************************************

Menu_DrawRaceCard:
                lea     (Race_ram_ImageBuffer2 + $120).l,a0 ; card tilemaps start here
                mulu.w  #$48,d1 ; even id * $48 = (id/2)*144 bytes = card offset
                adda.w  d1,a0
; copy one 12x6 card to Intro_ram_ImageBuffer
                lea     (Intro_ram_ImageBuffer).l,a1
                move.w  #35,d1 ; 36 longs = 72 words = 144 bytes ($90)
.loopCopy:
                move.l  (a0)+,(a1)+
                dbf     d1,.loopCopy

                tst.w   d0
                beq.w   .draw ; place 0 -> no text
                lea     (Intro_ram_ImageBuffer + $80).l,a0 ; cell 64 = row 5, col 4
                move.w  #0,-8(a0) ; clear row 5 cols 0-3
                move.w  #0,-6(a0)
                move.w  #0,-4(a0)
                move.w  #0,-2(a0)
                move.w  #0,8(a0) ; clear row 5 cols 8-11
                move.w  #0,$A(a0)
                move.w  #0,$C(a0)
                move.w  #0,$E(a0)
                move.w  (dStringCodeTable + 2 * ' ').w,(a0) ; leading space (or tens digit)
                move.w  (dStringCodeTable + 2 * 't').w,4(a0) ; default suffix "th"
                move.w  (dStringCodeTable + 2 * 'h').w,6(a0)
                cmp.w   #4,d0
                bpl.w   .drawTens ; 4th, 5th, ...
                move.w  (dStringCodeTable + 2 * 'r').w,4(a0) ; 3rd
                move.w  (dStringCodeTable + 2 * 'd').w,6(a0)
                cmp.w   #3,d0
                bpl.w   .drawTens
                move.w  (dStringCodeTable + 2 * 'n').w,4(a0) ; 2nd
                cmp.w   #2,d0
                bpl.w   .drawTens
                move.w  (dStringCodeTable + 2 * 's').w,4(a0) ; 1st
                move.w  (dStringCodeTable + 2 * 't').w,6(a0)
.drawTens:
                cmp.w   #10,d0
                bmi.w   .drawOnes ; single-digit place
                move.w  (dStringCodeTable + 2 * '1').w,(a0) ; 1X: tens digit
                subi.w  #10,d0
.drawOnes:
                move.w  (dStringCodeTable + 2 * '0').w,2(a0)
                add.w   d0,2(a0) ; ones digit = '0' + place
; The card map is written with base tile $680 (VRAM $D000), but these four
; words must select font tiles at VRAM $0000. Subtract the base so the masked
; writer's add.w d4 restores the original font tile index.
                subi.w  #$680,(a0)+
                subi.w  #$680,(a0)+
                subi.w  #$680,(a0)+
                subi.w  #$680,(a0)+
.draw:
                move.w  #12,d0 ; width
                move.w  #6,d1 ; height
                move.w  #$680,d4 ; base tile index, address $D000
                move.w  #$7FF,d5 ; mask tile - default black tile
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0 ; source
                lea     (Menu_ram_FrameBuffer).l,a1 ; destination
                jsr     (Menu_WriteNametableMasked).w ; write only on black/default tiles
                rts
; End of function Menu_DrawRaceCard

; *************************************************
; Function Menu_ShowMessage
; Draws the current tooltip (text + optional show function) with blinking.
; In:  Menu_ram_CurrentMessageId (multiple of 8), Message_MsgArray
; Out: Menu_ram_FrameBuffer / Message_* updated
; Clobbers: d0-d6/a0-a1
; Notes: ROM $00417C-$004225. Message_MsgArray has 8-byte entries:
;        +$00 text pointer, +$04 show-function pointer; $FFFFFFFF ends a group.
;        MessageBlinkTimer >= 0 hides the text (Message_ShowEmpty for static
;        prompts, Message_Clear for animated ones); a negative timer reveals it,
;        calls the show function, encodes and draws the text.
; *************************************************

Menu_ShowMessage:
                tst.w   (Menu_ram_MessageBlinkTimer).l
                bmi.w   .showText
; blink-off phase: hide the text but keep the appropriate blank field
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).l,a0
                movea.l 4(a0,d0.w),a0 ; show-function pointer
                cmpa.l  #Message_ShowEmpty,a0
                beq.w   .Message_ShowEmpty ; static prompt -> blank space field
                jsr     (Message_Clear).l ; animated prompt -> black field
                bra.w   .return
.Message_ShowEmpty:
                jsr     (Message_ShowEmpty).l
                bra.w   .return
.showText:
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).l,a0
                movea.l 4(a0,d0.w),a0 ; show-function pointer
                bmi.w   .return ; -1 marks the end of the tooltip group
                jsr     (a0) ; draw the prompt/icon for this id
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).l,a0
                movea.l (a0,d0.w),a0 ; text record pointer
                cmpa.l  #0,a0 ; negative pointer means -1: no text
                bmi.w   .return
                lea     (Intro_ram_ImageBuffer).l,a1
                bsr.w   EncodeString ; encode text -> tile indices
                move.w  (Menu_ram_CurrentMessageId).l,d0
                lea     (Message_MsgArray).l,a0
                movea.l (a0,d0.w),a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #0,d4 ; base tile
                move.w  #64,d6 ; plane width
                lea     (Intro_ram_ImageBuffer).l,a0
                lea     (Menu_ram_FrameBuffer).l,a1
                bsr.w   WriteNametableToBuffer ; write text to framebuffer
.return:
                rts
; End of function Menu_ShowMessage
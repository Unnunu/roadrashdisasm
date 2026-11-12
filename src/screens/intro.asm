; *************************************************
; src/screens/intro.asm - intro / title / credits screen
; ROM range: $001704-$002445
; Status:    analyzed (static; visual confirmation of the title wipe TODO)
; Purpose:   boot intro/title screen: VDP setup, background + "ROAD RASH" title +
;            font upload, 13 credit strings with a per-line H-scroll effect, Start
;            detection, and initialization of the persistent player/menu state.
; Flow:      TopLevel_Init -> Intro_Init -> Fade_InitFadeIn -> Intro_GameTick
;            (ram_UpdateFunction); on Start -> Fade_InitFadeOut -> menu; on timeout
;            -> demo high-score.
; API:       Intro_Init, Intro_GameTick, Intro_InitPlayerA/B, EncodeString,
;            DecodeString, WriteNametable
; Data:      Intro_dCreditStringTable, dStringCodeTable/dStringDecodeTable
; Assets:    img_Intro_Background, img_Intro_Title, img_Intro_Font (UncompressW blobs)
; *************************************************
;
; VRAM map (derived from the VDP registers below and the decompressed tile counts):
;   $0000-$063F  font tiles (img_Intro_Font, 50 tiles)
;   $0640-$1FFF  unused
;   $2000-$3FFF  plane B nametable (background, 128x32)
;   $4000-$5FFF  plane A nametable (title + credits, 128x32)
;   $6000-$627F  sprite attribute table (80 entries x 8 bytes)
;   $7000-$737F  H-scroll table (224 lines x 4 bytes; DMA $1C0 words)
;   $7380-$7FFF  unused
;   $8000-$B4DF  background tiles (423 tiles)
;   $B4E0-$DFFF  unused
;   $E000-$F19F  title tiles (141 tiles)
;   $F1A0-$FFFF  unused
; *************************************************


; *************************************************
; Function Intro_Init
; Initializes the intro/title screen and the persistent player/menu state.
; In:       -
; Out:      VDP configured; background/title/font in VRAM; background palette in
;           Global_ram_Palette; intro/menu/high-score state initialized
; Clobbers: d0-d7/a0-a6 (including called routines)
; Notes:    enables the display; the SAT and VSRAM are only partially cleared;
;           the background palette is reused by the title and the font.
; *************************************************

Intro_Init:
; Reset the Start latches and the per-string timer. TopLevel later uses the sign
; of TextTimer to choose the menu (Start pressed, timer >= 0) or the demo
; high-score (timed out, timer < 0).
                move.w  #0,(Intro_ram_PlayerAPressedStart).l
                move.w  #0,(Intro_ram_PlayerBPressedStart).l
                move.w  #180,(Intro_ram_TextTimer).l ; 180 frames = 3 s at 60 Hz
                move.w  #0,(Intro_ram_CurrentStringOffset).l ; byte offset into Intro_dCreditStringTable
                lea     (VdpCtrl).l,a0
                move.w  #$8004,(a0) ; reg0: H-int off, left column unblanked, HV counter normal (bit2 fixed 1)
                move.w  #$8174,(a0) ; reg1: display on, V-int on, DMA on, 28-row mode (M2=0)
                move.w  #$8210,(a0) ; reg2: plane A nametable = $4000
                move.w  #$8401,(a0) ; reg4: plane B nametable = $2000
                move.w  #$8530,(a0) ; reg5: sprite attribute table = $6000
                move.w  #$8701,(a0) ; reg7: backdrop = palette 0, colour 1
                move.w  #$8AFF,(a0) ; reg10: H-int counter 255 (H-int disabled by reg0)
                move.w  #$8B03,(a0) ; reg11: external int off, V-scroll full, H-scroll per line
                move.w  #$8C81,(a0) ; reg12: H40, no interlace, shadow/highlight off
                move.w  #$8D1C,(a0) ; reg13: H-scroll table = $7000
                move.w  #$8F02,(a0) ; reg15: auto-increment = 2 bytes
                move.w  #$9003,(a0) ; reg16: plane size 128x32 (VSZ=00, HSZ=11)
                move.w  #$9100,(a0) ; reg17: window X split 0 (window left of 0 -> disabled)
                move.w  #$9200,(a0) ; reg18: window Y split 0 (window above 0 -> disabled)
                VDP_VRAM_WRITE $6000,(a0) ; set VRAM write address $6000 (sprite table)
                move.l  #0,(VdpData).l ; clear only the first 4 bytes of the SAT (sprite 0)
                VDP_VSRAM_WRITE $0,(a0) ; set VSRAM write address 0
                move.l  #0,(VdpData).l ; clear VSRAM words 0-1 (word 0 = full-screen V-scroll)
                move.l  #Global_ram_Palette,(Global_ram_PalettePtr).l ; active palette = global buffer

; The decompressed background blob is a self-contained image package:
;   +$0000  word $0808 format marker (see docs/analysis/uncompress.md); ignored
;           by WriteTilesetToVRAM
;   +$0002  word tile count (423)
;   +$0004  tile data (423 * 32 bytes)
;   +$34E4  palette (32 longs = 64 colours)
;   +$3564  word width (40), word height (28)
;   +$3568  nametable (40 * 28 words)
; The title and font reuse this palette; the title blob has no palette of its own.

; decompress the background image into RAM
                lea     (img_Intro_Background).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; upload the 423 background tiles to VRAM $8000
                move.l  #$8000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; write the 40x28 background nametable to plane B at (0,0)
                move.w  #40,d0 ; width in cells
                move.w  #28,d1 ; height in cells
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$400,d4 ; tile base $400 -> VRAM $8000, palette line 0
                move.w  #$2000,d5 ; plane B nametable
                move.w  #$80,d6 ; plane width = 128 cells (reg16 = 128x32)
                lea     (Intro_ram_ImageBuffer + $3568).l,a0 ; nametable inside the blob
                jsr     (WriteNametable).l
; copy the background palette into the global palette buffer
                lea     (Intro_ram_ImageBuffer + $34E4).l,a0 ; palette inside the blob
                movea.l (Global_ram_PalettePtr).l,a1
                move.w  #$1F,d0 ; 32 longs = 64 colours
.copyBgPalette:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyBgPalette

; The title blob has the same package layout but no palette:
;   +$0000 word $0808 format marker, +$0002 word tile count (141),
;   +$0004 tile data,
;   +$11A4 word width (40), word height (28), +$11A8 nametable.

; decompress the title image into RAM
                lea     (img_Intro_Title).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; upload the 141 title tiles to VRAM $E000
                move.l  #$E000,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l
; write the 40x28 title nametable to plane A at (0,0)
                move.w  #40,d0 ; width in cells
                move.w  #28,d1 ; height in cells
                move.w  #0,d2 ; x
                move.w  #0,d3 ; y
                move.w  #$700,d4 ; tile base $700 -> VRAM $E000, palette line 0
                move.w  #$4000,d5 ; plane A nametable
                move.w  #$80,d6 ; plane width = 128 cells
                lea     (Intro_ram_ImageBuffer + $11A8).l,a0 ; nametable inside the blob
                jsr     (WriteNametable).l
; The title text occupies only rows 19-23, columns 2-38; the rest of its 40x28
; nametable is tile 0 (blank). The first write left columns 40-127 of the
; 128-cell plane uninitialized. The per-line H-scroll for lines 150-189 slides
; plane A by 400..492 px, so the visible window moves into that area. Fill the
; off-screen right part (x=40..127, y=18..23) with blank tiles so VRAM leftovers
; do not show as artifacts. The source is the blank prefix of the title
; nametable (the text starts at row 19, so the first 88*6 words are zero).
                move.w  #88,d0 ; width: x=40..127, the rest of the 128-cell plane
                move.w  #6,d1 ; rows 18-23 (title rows 19-23 plus one line above)
                move.w  #40,d2 ; start right of the 40-cell title image
                move.w  #18,d3 ; start at row 18
                move.w  #$700,d4 ; tile base $700 (blank title tile)
                move.w  #$4000,d5 ; plane A
                move.w  #$80,d6 ; plane width = 128 cells
                lea     (Intro_ram_ImageBuffer + $11A8).l,a0 ; blank prefix of the title nametable
                jsr     (WriteNametable).l

; Load the credit font (50 tiles) at VRAM $0. The font blob has no palette or
; nametable: +0 word $0808 format marker, +2 tile count (50),
; +4 tile data.

; decompress the font image into RAM
                lea     (img_Intro_Font).l,a3
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (UncompressW).l
; upload the 50 font tiles to VRAM $0
                moveq   #0,d0
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteTilesetToVRAM).l

; Encode and print the first credit string (Intro_String1). Each string header
; is four words: y, x, height, width, followed by height*width characters.
; EncodeString reads height/width from +4/+6, maps each character through
; dStringCodeTable (bytes >= $80 become space) and writes one word per cell.
                movea.l (Intro_dCreditStringTable).l,a0
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).l
; draw the first string on plane A using the encoded tile indices
                movea.l (Intro_dCreditStringTable).l,a0
                move.w  6(a0),d0 ; width in cells
                move.w  4(a0),d1 ; height in cells
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; tile index 0, palette line 3 -> font at VRAM $0
                move.w  #$4000,d5 ; plane A nametable
                move.w  #$80,d6 ; plane width = 128 cells
                lea     (Intro_ram_ImageBuffer).l,a0 ; encoded tile indices
                jsr     (WriteNametable).l

; Prepare the per-line H-scroll for the title slide-in.
; Each H-scroll entry is 4 bytes: high word = plane A (title) scroll, low word =
; plane B (background) scroll. Each speed entry is a 16.16 fixed-point
; pixels/frame value. Only the first 224 entries are DMA'd to VRAM $7000.
;
; Initial profile:
;   lines   0-149: scroll 0, speed 0
;   lines 150-189: line 150 = 492.625, line 189 = 400.0 (ramp downward),
;                  speed 12.0 on every line
;   lines 190-223: scroll 0, speed 0
; The 40-line block is built bottom-up: line 189 starts at 400.0, then the
; delta starts at 0 and grows by 0.125 per line, so line 150 reaches 492.625.
; The stored table value is the integer part (floor); the fractional part is
; kept in d1 to advance the next line. The title text is rows 19-23
; (scanlines 152-191); lines 190-191 fall outside the animated block and are
; cleared to 0. In the title tiles, the bottom pixel row (line 191) is blank
; for every cell in row 23; the row above (line 190) has only three non-zero
; pixels, at x=37 (tile 139, column 4) and x=38 (tile 140, columns 1 and 5),
; palette 0 color 10. BlastEm shows no visible tear from these two lines
; staying at scroll 0.

; clear lines 0-149 (the static top part of the screen)
                lea     (Intro_TitleScrollTable).l,a2
                lea     (Intro_TitleScrollSpeed).l,a3
                move.w  #149,d0
.clearHScroll:
                move.l  #0,(a2)+ ; clear both words: plane A and plane B scroll
                move.l  #0,(a3)+
                dbf     d0,.clearHScroll

; build the 40-line animated block (lines 150-189) bottom-up
                lea     (Intro_TitleScrollTable + $2F8).l,a2 ; line 190; predecrement writes 189..150
                lea     (Intro_TitleScrollSpeed + $2F8).l,a3
                move.w  #39,d0 ; 40 lines
                move.l  #$1900000,d1 ; line 189: 400.0 px (title off-screen left)
                moveq   #0,d2 ; delta for the next line
.loopTitleScroll:
                move.l  d1,d3
                clr.w   d3 ; low word = plane B scroll = 0; high word = plane A scroll
                move.l  d3,-(a2)
                move.l  #$C0000,-(a3) ; speed = 12.0 px/frame
                add.l   d2,d1 ; next line's scroll value
                addi.l  #$2000,d2 ; delta += 0.125 px
                dbf     d0,.loopTitleScroll

; clear lines 190-223 (below the animated block)
                lea     (Intro_TitleScrollTable + $2F8).l,a2 ; line 190
                lea     (Intro_TitleScrollSpeed + $2F8).l,a3
                move.w  #33,d0 ; 34 lines: 190..223
.clearHScroll2:
                move.l  #0,(a2)+
                move.l  #0,(a3)+
                dbf     d0,.clearHScroll2

; upload the 224-line H-scroll table to VRAM $7000
                move.l  #Intro_TitleScrollTable,d0 ; DMA source (RAM)
                move.w  #$7000,d1 ; VRAM destination
                move.w  #$1C0,d2 ; 448 words = 224 entries * 4 bytes
                jsr     (DmaWriteVRAM).l

; Start the intro song (song 1) and record the game-level current song id.
                moveq   #SONG_INTRO,d0
                move.w  d0,(ram_CurrentSong).l
                jsr     (Audio_StartMusic).l

; Pre-create the two player-name strings. Each is an 8-byte header
; (y, x, height, width) followed by 10 characters. Screens that draw the
; string directly use the header position (password menu); the race HUD
; copies only the 10 characters into its own message structure.
; Both start as "Player A  "; the B string is changed to "Player B  " below.

; Copy "Player A  " into the player A name record (y=9, x=5, 1x10).
                lea     (Menu_DefaultName).l,a0
                lea     (MenuPassword_ram_StrPlayerAName).l,a1
                move.w  #9,(a1)+ ; y
                move.w  #5,(a1)+ ; x
                move.w  #1,(a1)+ ; height
                move.w  #10,(a1)+ ; width
                move.w  #4,d0
.copyNameA:
                move.w  (a0)+,(a1)+
                dbf     d0,.copyNameA
; Same for player B, but at x=25 (right side of the screen).
                lea     (Menu_DefaultName).l,a0
                lea     (MenuPassword_ram_StrPlayerBName).l,a1
                move.w  #9,(a1)+ ; y
                move.w  #25,(a1)+ ; x
                move.w  #1,(a1)+ ; height
                move.w  #10,(a1)+ ; width
                move.w  #4,d0
.copyNameB:
                move.w  (a0)+,(a1)+
                dbf     d0,.copyNameB

; Change the 8th character of player B's name from 'A' to 'B'. a0 points past
; the 8-byte header, so 7(a0) is character index 7, the 'A' in "Player A".

                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a0
                addq.b  #1,7(a0)

; Reserve rows 5 and 6 of the 7x20 high-score table for the players
; (offset = row * 20). HighScore_Init uses these offsets to draw the player
; rows after a race, so they are persistent state, not demo-only.

                move.w  #(20*5),(HighScore_ram_PlayerATableOffset).l
                move.w  #(20*6),(HighScore_ram_PlayerBTableOffset).l
; Copy the 7x20 demo high-score table into the persistent table. The
; destination header was just written as (22,16,7,20).
                lea     (DemoHighScoreTable).l,a0
                lea     (HighScore_ram_Table).l,a1
                move.w  #22,(a1)+ ; y
                move.w  #16,(a1)+ ; x
                move.w  #7,(a1)+ ; height
                move.w  #20,(a1)+ ; width
                move.w  #34,d0 ; 35 longs = 140 bytes = exactly 7*20 characters
.copyHighScore:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyHighScore

; Default game state for a fresh profile: first track, player A, level 1,
; player A selected.

                move.w  #TRACK_ID_SIERRA_NEVADA,(Menu_ram_CurrentTrackId).l
                move.w  #PLAYER_MODE_A,(Menu_ram_PlayerMode).l
                move.w  #PLAYER_LEVEL_START,(Menu_ram_PlayerLevel).l
                move.w  #0,(ram_FF0520).l ; TODO: meaning not confirmed
                move.w  #PLAYER_SLOT_A,(Menu_ram_Player).l
; Build the persistent player A/B records (name/password, level, money, bike,
; places, opponent list) and put their names into the high-score table.
                bsr.w   Intro_InitPlayerA
                bsr.w   Intro_InitPlayerB
                move.w  #$3F,(Message_ram_ButtonBlinkPeriod).l ; button blink period = 63 frames
                jsr     (Rand_InitSum).l ; 32-word sum PRNG; seed = d0 ($FFFF left by the copy loops)
                jsr     (Rand_SeedLfsrs).l ; seed the two 16-bit LFSR state words
                move.w  #1,(ram_MusicEnabled).l ; music active: HInt skips engine audio
                rts
; End of function Intro_Init

; *************************************************
; Function Intro_InitPlayerA
; Resets player A's profile and high-score table row.
; In:  HighScore_ram_PlayerBTableOffset - row collision check
; Out: player A name/password/level/money/bike/places/opponents;
;      HighScore_ram_PlayerATableOffset and the high-score row contents
; Clobbers: d0/a0/a1
; Notes: also called by Menu_Init when player A's money is negative, so the
;        "Intro_" prefix is narrower than the actual use (rename candidate).
; *************************************************

Intro_InitPlayerA:
; Reserve a high-score row for player A: row 5 by default, but row 6 if
; player B already occupies row 5.
                move.w  #(20*5),(HighScore_ram_PlayerATableOffset).l
                cmpi.w  #(20*5),(HighScore_ram_PlayerBTableOffset).l
                bne.w   .loc_1A48 ; B is not in row 5, keep A there
                move.w  #(20*6),(HighScore_ram_PlayerATableOffset).l
.loc_1A48: ; player A row is now final
; The demo-table pointer below is dead: a0 is reloaded before it is used.
                lea     (DemoHighScoreTable + 8).l,a0
                adda.w  #(20*5),a0 ; dead: a0 is reloaded below

; Copy the 10-character player A name into the player's high-score row.

                lea     (HighScore_ram_Table + 8).l,a1 ; text starts after the header
                adda.w  (HighScore_ram_PlayerATableOffset).l,a1
                lea     (MenuPassword_ram_StrPlayerAName + 8).l,a0
                move.w  #4,d0
.copyName:
                move.w  (a0)+,(a1)+
                dbf     d0,.copyName

; Fill the remaining 10 characters of the 20-character row: 8 spaces then
; "$0" (default money). Race_UpdateHighScoreTable rewrites this later.

                move.l  #'    ',(a1)+ ; 4 spaces
                move.l  #'    ',(a1)+ ; 8 spaces total
                move.w  #'$0',(a1)+ ; "$0"

; Copy the 24-character password template. Its checksum is invalid; it is only
; the initial on-screen text and is replaced when a password is created/entered.

                lea     (Menu_DefaultPassword).l,a0
                lea     (MenuPassword_ram_StrPlayerAPassword).l,a1
                move.w  #15,(a1)+ ; y
                move.w  #4,(a1)+ ; x
                move.w  #2,(a1)+ ; height
                move.w  #12,(a1)+ ; width
                move.w  #5,d0 ; 6 longs = 24 characters
.copyPassword:
                move.l  (a0)+,(a1)+
                dbf     d0,.copyPassword

; Fresh player A state: level 1, no race outcome, no progress, $100, bike 0,
; and no recorded place in any of the five races.
                move.w  #PLAYER_LEVEL_START,(Menu_ram_PlayerALevel).l
                move.w  #RACE_OUTCOME_NONE,(ram_FF0526).l
                move.w  #0,(ram_FF0522).l ; 2-bit password field (meaning TODO)
                move.l  #0,(ram_FF0510).l ; 20-bit progress value
                move.l  #100,(Menu_ram_MoneyPlayerA).l ; starting money = $100
                move.w  #BIKE_ID_START,(Menu_ram_BikeIdPlayerA).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerAPlaces + 0).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerAPlaces + 2).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerAPlaces + 4).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerAPlaces + 6).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerAPlaces + 8).l

; Opponent id list for the upcoming race: $4B is the player's own definition
; id, followed by the 15 opponent definition ids for level 1 (0..14).
; Race_CreateActors consumes this list to build the player and 15 opponents.

                lea     (Menu_ram_PlayerAOpponents).l,a0
                move.w  #$4B,(a0)+ ; player definition id
                move.w  #0,(a0)+
                move.w  #1,(a0)+
                move.w  #2,(a0)+
                move.w  #3,(a0)+
                move.w  #4,(a0)+
                move.w  #5,(a0)+
                move.w  #6,(a0)+
                move.w  #7,(a0)+
                move.w  #8,(a0)+
                move.w  #9,(a0)+
                move.w  #$A,(a0)+
                move.w  #$B,(a0)+
                move.w  #$C,(a0)+
                move.w  #$D,(a0)+
                move.w  #$E,(a0)+
                rts
; End of function Intro_InitPlayerA

; *************************************************
; Function Intro_InitPlayerB
; Resets player B's profile and high-score table row.
; In:  HighScore_ram_PlayerATableOffset - row collision check
; Out: player B name/password/level/money/bike/places/opponents;
;      HighScore_ram_PlayerBTableOffset and the high-score row contents
; Clobbers: d0/a0/a1
; Notes: same layout as Intro_InitPlayerA, but B state and password x=24;
;        also called by Menu_Init when player B's money is negative.
; *************************************************

Intro_InitPlayerB:
; Reserve a high-score row for player B: row 5 by default, but row 6 if
; player A already occupies row 5.
                move.w  #(20*5),(HighScore_ram_PlayerBTableOffset).l
                cmpi.w  #(20*5),(HighScore_ram_PlayerATableOffset).l
                bne.w   .loc_1B64 ; A is not in row 5, keep B there
                move.w  #(20*6),(HighScore_ram_PlayerBTableOffset).l
.loc_1B64: ; player B row is now final
; The demo-table pointer below is dead: a0 is reloaded before it is used.
                lea     (DemoHighScoreTable + 8).l,a0
                adda.w  #(20*5),a0 ; dead: a0 is reloaded below

; Copy the 10-character player B name into the player's high-score row.
                lea     (HighScore_ram_Table + 8).l,a1 ; text starts after the header
                adda.w  (HighScore_ram_PlayerBTableOffset).l,a1
                lea     (MenuPassword_ram_StrPlayerBName + 8).l,a0
                move.w  #4,d0

.loc_1B84:
                move.w  (a0)+,(a1)+
                dbf     d0,.loc_1B84
; Fill the remaining 10 characters of the 20-character row: 8 spaces then
; "$0" (default money). Race_UpdateHighScoreTable rewrites this later.
                move.l  #'    ',(a1)+ ; 4 spaces
                move.l  #'    ',(a1)+ ; 8 spaces total
                move.w  #'$0',(a1)+ ; "$0"
; Copy the same 24-character password template (invalid checksum); for player B
; it is drawn at x=24 instead of x=4. It is replaced when a password is used.
                lea     (Menu_DefaultPassword).l,a0
                lea     (MenuPassword_ram_StrPlayerBPassword).l,a1

                move.w  #15,(a1)+ ; y
                move.w  #24,(a1)+ ; x
                move.w  #2,(a1)+ ; height
                move.w  #12,(a1)+ ; width
                move.w  #5,d0 ; 6 longs = 24 characters
.loc_1BBA:
                move.l  (a0)+,(a1)+
                dbf     d0,.loc_1BBA

; Fresh player B state: level 1, no race outcome, no progress, $100, bike 0,
; and no recorded place in any of the five races.
                move.w  #PLAYER_LEVEL_START,(Menu_ram_PlayerBLevel).l
                move.w  #RACE_OUTCOME_NONE,(ram_FF0528).l
                move.w  #0,(ram_FF0524).l ; 2-bit password field (meaning TODO)
                move.l  #0,(ram_FF0514).l ; 20-bit progress value
                move.l  #100,(Menu_ram_MoneyPlayerB).l ; starting money = $100
                move.w  #BIKE_ID_START,(Menu_ram_BikeIdPlayerB).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerBPlaces + 0).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerBPlaces + 2).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerBPlaces + 4).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerBPlaces + 6).l
                move.w  #RACE_PLACE_NONE,(Menu_ram_PlayerBPlaces + 8).l

; Opponent id list for the upcoming race: $4B is the player's own definition
; id, followed by the 15 opponent definition ids for level 1 (0..14).
                lea     (Menu_ram_PlayerBOpponents).l,a0
                move.w  #$4B,(a0)+ ; player definition id
                move.w  #0,(a0)+
                move.w  #1,(a0)+
                move.w  #2,(a0)+
                move.w  #3,(a0)+
                move.w  #4,(a0)+
                move.w  #5,(a0)+
                move.w  #6,(a0)+
                move.w  #7,(a0)+
                move.w  #8,(a0)+
                move.w  #9,(a0)+
                move.w  #$A,(a0)+
                move.w  #$B,(a0)+
                move.w  #$C,(a0)+
                move.w  #$D,(a0)+
                move.w  #$E,(a0)+
                rts
; End of function Intro_InitPlayerB

; *************************************************
; Function Intro_GameTick
; Runs one frame of the intro: uploads the title H-scroll table, polls Start,
; advances the credit pages and animates the title band.
; In:       -
; Out:      clears ram_UpdateFunction when the stage ends
; Clobbers: d0-d6/a0-a2
; Notes:    Start is edge-triggered (press then release); A is checked first.
;           The title band is scanlines 150-189. Once the credit offset reaches
;           $2C (12th page), the band starts wiping off to the right while the
;           last two credit pages are still displayed. A run that reaches the
;           table terminator leaves Intro_ram_TextTimer negative; TopLevel uses
;           that sign to enter demo mode instead of the main menu.
; *************************************************

Intro_GameTick:
; Upload all 224 H-scroll entries (lines 0-223) to VRAM $7000. Only the
; 40-line title band changes, but resending the whole table is cheap.
                move.l  #Intro_TitleScrollTable,d0
                move.w  #$7000,d1
                move.w  #$1C0,d2 ; size in words
                jsr     (DmaWriteVRAM).l
; Start is edge-triggered: latch it while held, end the stage on the first
; frame it is released. Both pads are polled every frame, A before B.
                jsr     (GetInputPlayerA).w
                andi.w  #$80,d0 ; get 'Start' bit
                bne.w   .playerAPressedStart
                tst.w   (Intro_ram_PlayerAPressedStart).l
                bne.w   .endStage ; player A presed start then released
                bra.w   .checkPlayerBStart
.playerAPressedStart:
                move.w  d0,(Intro_ram_PlayerAPressedStart).l
; check if player B pressed start
.checkPlayerBStart:
                jsr     (GetInputPlayerB).w
                andi.w  #$80,d0 ; get 'Start' bit
                bne.w   .playerBPressedStart
                tst.w   (Intro_ram_PlayerBPressedStart).l
                bne.w   .endStage ; player B presed start then released
                bra.w   .showIntro
.playerBPressedStart:
                move.w  d0,(Intro_ram_PlayerBPressedStart).l

.showIntro:
; Intro_Init already drew page 0. Advance one 4-byte table entry when the
; timer expires; the bpl makes each page last 181 ticks, not 180.
                subq.w  #1,(Intro_ram_TextTimer).l
                bpl.w   .updateScroll ; jump if text doesn't change
                addq.w  #4,(Intro_ram_CurrentStringOffset).l
                move.w  (Intro_ram_CurrentStringOffset).l,d0
                lea     (Intro_dCreditStringTable).l,a0
                movea.l (a0,d0.w),a0 ; get String
                cmpa.l  #$FFFFFFFF,a0 ; terminator after the 13 credit pages
                beq.w   .endStage
                lea     (Intro_ram_ImageBuffer).l,a1
                jsr     (EncodeString).l
; Draw the new page at the position from its header (y=25, x=1, 2x38)
; on plane A, palette line 3; EncodeString produced the tile indices.
                move.w  (Intro_ram_CurrentStringOffset).l,d0
                lea     (Intro_dCreditStringTable).l,a0
                movea.l (a0,d0.w),a0
                move.w  6(a0),d0 ; width
                move.w  4(a0),d1 ; height
                move.w  2(a0),d2 ; x
                move.w  (a0),d3 ; y
                move.w  #$6000,d4 ; first tile index = 0, palette line = 3
                move.w  #$4000,d5 ; VRAM address = Scroll A
                move.w  #$80,d6 ; plane width = 128
                lea     (Intro_ram_ImageBuffer).l,a0
                jsr     (WriteNametable).l

                move.w  #180,(Intro_ram_TextTimer).l ; 180 ticks (~3 s)
; Slide the 40-line title band left. Each entry is a 32-bit 16.16 value:
; the high word feeds plane A, the low word aliases the H-scroll plane-B
; word. Every fractional part is a multiple of 1/8 (0x2000), whose low 10
; bits are zero, so plane B is not disturbed.
;
; A line keeps its current speed (12 px/frame initially) while its remaining
; offset is above 16 px. Once it is within 16 px, its speed drops by 2 px
; per frame. If the reduced speed still fits in the remaining distance, the
; speed is clamped to that distance so the line lands exactly on 0; otherwise
; the line overshoots, the speed keeps falling, crosses zero and pulls the
; line back - the visible damped recoil.
.updateScroll:
                lea     (Intro_TitleScrollTable + $258).l,a0 ; y = 150
                lea     (Intro_TitleScrollSpeed + $258).l,a1 ; y = 150
                move.w  #39,d0 ; repeat for 40 lines
.loopSetScroll:
                move.l  (a1),d2 ; current speed
                cmpi.w  #$2C,(Intro_ram_CurrentStringOffset).l
                bpl.w   .setScroll ; last two pages: stop changing speed
                cmpi.l  #$100000,(a0)
                bgt.w   .setScroll ; still more than 16 px away: keep speed
                subi.l  #$20000,d2 ; near the target: speed -= 2 px/frame
                move.l  (a0),d1
                sub.l   d2,d1 ; remaining distance - reduced speed
                bmi.w   .setScroll ; negative: keep speed and overshoot
                move.l  (a0),d2 ; fits: clamp speed to the remaining distance
.setScroll:
                move.l  d2,(a1)+ ; update speed
                sub.l   d2,(a0)+ ; advance the scroll value
                dbf     d0,.loopSetScroll

; At $2C the 12th credit page has appeared: stop the normal edge pass and
; start moving the band off-screen. The last two pages keep showing meanwhile.
                cmpi.w  #$2C,(Intro_ram_CurrentStringOffset).l
                bpl.w   .moveOutOfScreen
; Bottom-up edge pass while the credits are still playing. Walk from line
; 190 up to line 150: d2 = line below - line above - 1. If the line below
; has advanced at least 1 px further left, pull the line above to one pixel
; behind it. This propagates the lower edge upward with a 1 px/scanline
; slope, so the band settles as a wave instead of a hard seam.
                lea     (Intro_TitleScrollTable + $2F8).l,a0 ; y = 190
                move.w  #39,d0
.loopRecoil:
                move.l  (a0),d2 ; lower line's scroll
                sub.l   -(a0),d2 ; d2 = lower - upper
                subi.l  #$10000,d2 ; subtract 1 px
                bmi.w   .loc_1D9A ; gap <= 1 px: keep the current slope
                move.l  4(a0),(a0) ; upper = lower
                subi.l  #$10000,(a0) ; one pixel behind the lower line
.loc_1D9A:
                dbf     d0,.loopRecoil
                bra.w   .end
.moveOutOfScreen:
; Move the band off to the right in a diagonal wipe. Line 189 gets
; 12 px/frame and line 190 becomes a -640 sentinel; the bottom line slides
; until it passes the sentinel (overshooting to about -648), then stops.
; The loop then copies (line below + 1) upward whenever the line below is
; more than 1 px further right, so the wipe travels up the band. It runs
; 40 times starting at line 189, so it also touches line 149, one line above
; the 40-line band; row 18 is blank, so the extra line is not visible.
                move.l  #$C0000,(Intro_TitleScrollSpeed + $2F4).l ; line 189: 12 px/frame
                move.l  #$FD800000,(Intro_TitleScrollTable + $2F8).l ; line 190: -640 sentinel
                lea     (Intro_TitleScrollTable + $2F8).l,a0 ; start at line 190
                move.w  #39,d0
                move.l  (a0),d2
                sub.l   -(a0),d2 ; line 190 - line 189
                bmi.w   .loc_1DD2
                move.l  #0,(Intro_TitleScrollSpeed + $2F4).l ; sentinel reached: stop line 189
.loc_1DD2:
                move.l  (a0),d2
                sub.l   -(a0),d2 ; line below - line above
                addi.l  #$10000,d2 ; add 1 px for the trailing line
                bpl.w   .loc_1DEA ; propagate only when below < above - 1
                move.l  4(a0),(a0) ; upper = lower
                addi.l  #$10000,(a0) ; one pixel behind the lower line
.loc_1DEA:
                dbf     d0,.loc_1DD2

                bra.w   .end
.end:
                jsr     (Audio_Update).l ; service audio on every frame, including the last
                rts
.endStage:
; Start released or credits exhausted: stop the song and clear the callback
; so TopLevel continues. If the table terminator was reached, TextTimer is
; negative here and TopLevel uses that sign to choose demo mode.
                jsr     (Audio_StopMusic).l
                move.l  #0,(ram_UpdateFunction).l
                bra.s   .end
; End of function Intro_GameTick

; Credit pages: 13 pointers followed by $FFFFFFFF. Each record is
;   +0 y, +2 x, +4 height, +6 width (words), then height*width ASCII bytes.
; All pages are 2x38 (76 bytes). Page 12 is blank and is shown while the
; title wipes out; page 13 moves up to y=24 for the start prompt.
Intro_dCreditStringTable:
                dc.l Intro_String1
                dc.l Intro_String2
                dc.l Intro_String3
                dc.l Intro_String4
                dc.l Intro_String5
                dc.l Intro_String6
                dc.l Intro_String7
                dc.l Intro_String8
                dc.l Intro_String9
                dc.l Intro_String10
                dc.l Intro_String11
                dc.l Intro_String12
                dc.l Intro_String13
                dc.l $FFFFFFFF
Intro_String1:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "    Copyright 1991 Electronic Arts    "
    dc.b "                                      "
Intro_String2:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "   Licensed by Sega Enterprises LTD.  "
    dc.b "                                      "
Intro_String3:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "             Programming:             "
    dc.b "       Dan Geisler, Walter Stein      "
Intro_String4:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                 Art:                 "
    dc.b "       Arthur Koch, Jeff Fennel       "
Intro_String5:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                 Art:                 "
    dc.b "   Sheryl Knowles, Cynthia Hamilton   "
Intro_String6:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                 Art:                 "
    dc.b "       Connie Braat, Paul Vernon      "
Intro_String7:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "                 Art:                 "
    dc.b "            Peggy Brennan             "
Intro_String8:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "           Sound and Music:           "
    dc.b "      Rob Hubbard, Mike Bartlow       "
Intro_String9:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "              Production:             "
    dc.b "              Randy Breen             "
Intro_String10:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "         Technical Direction:         "
    dc.b "               Carl Mey               "
Intro_String11:
    dc.w 25,1,2,38 ; y, x, height, width
    dc.b "         Production Assistant:        "
    dc.b "           Michael Lubuguin           "
Intro_String12:
    dc.w 25,1,2,38 ; y, x, height, width
; blank page: the title wipe-out starts when this page appears
    dc.b "                                      "
    dc.b "                                      "
Intro_String13:
    dc.w 24,1,2,38 ; y, x, height, width
; start prompt; the only page at y=24 (the title has already wiped out)
    dc.b "   Press the Start Button to Begin    "
    dc.b "                                      "

; *************************************************
; Function EncodeString
; Converts a text record into a row-major array of font tile indices.
; In:       a0 - record: y,x,height,width words then height*width chars
;           a1 - destination buffer (height*width words)
; Out:      a0 - past the record text; a1 - past the written words
; Clobbers: d0/d1/a0/a2
; Notes:    bytes >= $80 become space; characters index the 128-word
;           dStringCodeTable by byte offset (char*2). Uppercase/lowercase
;           share tiles; unsupported glyphs map to the space tile.
; *************************************************

EncodeString:
                lea     (dStringCodeTable).l,a2 ; get char codetable
                lea     4(a0),a0
                move.w  (a0)+,d0 ; get height
                move.w  (a0)+,d1 ; get width
                mulu.w  d0,d1 ; get number of chars
                subq.w  #1,d1
                clr.l   d0
.loop:
                move.b  (a0)+,d0 ; get char
                bpl.w   .skipInvalidChar
                move.b  #$20,d0 ; if char >= 0x80 then print ' '
.skipInvalidChar:
                asl.b   #1,d0
                move.w  (a2,d0.w),(a1)+ ; get char code and write to a1
                dbf     d1,.loop
                rts
; End of function EncodeString

; *************************************************
; Function DecodeString
; Converts a row-major array of font tile indices back to characters.
; In:       a0 - record: header at +0..+7, text area at +8
;           a1 - source tile-index buffer (height*width words)
; Out:      a0 - past the written text; a1 - past the read words
; Clobbers: d0/d1/a0/a2
; Notes:    inverse of EncodeString for tile indices 0..49; there is no
;           bounds check, so callers must pass valid indices. Header is
;           left unchanged.
; *************************************************

DecodeString:
                lea     (dStringDecodeTable).l,a2
                lea     4(a0),a0
                move.w  (a0)+,d0
                move.w  (a0)+,d1
                mulu.w  d0,d1
                subq.w  #1,d1
.loop:
                move.w  (a1)+,d0
                move.b  (a2,d0.w),(a0)+
                dbf     d1,.loop
                rts
; End of function DecodeString

; ASCII -> font tile index, 128 words for $00-$7F. Unsupported glyphs and
; control codes map to 36 (space); lowercase uses the uppercase tiles.
dStringCodeTable:
    dc.w 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36 ; '                '
    dc.w 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36 ; '                '
    dc.w 36, 38, 48, 36, 43, 36, 36, 49, 44, 45, 36, 46, 39, 47, 40, 36 ; ' !"#$%&'()*+,-./'
    dc.w  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 42, 41, 36, 36, 36, 37 ; '0123456789:;<=>?'
    dc.w 36, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 ; '@ABCDEFGHIJKLMNO'
    dc.w 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 36, 36, 36, 36 ; 'PQRSTUVWXYZ[\]^_'
    dc.w 36, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 ; '`abcdefghijklmno'
    dc.w 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 36, 36, 36, 36 ; 'pqrstuvwxyz{|}~ '

; tile index (0..49) -> ASCII byte; exact inverse of the supported subset
; of dStringCodeTable. There are only 50 entries, so DecodeString must not
; be fed larger tile indices.
dStringDecodeTable:
    dc.b "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ ?!,.", $3B, ":$()+-", $22, $27

; *************************************************
; Function WriteNametable
; Writes a row-major tile-index buffer to a plane nametable in VRAM.
; In:       a0 - source buffer (width*height words)
;           d0 - width in cells (>=1)
;           d1 - height in cells (>=1)
;           d2 - topLeftX in cells
;           d3 - topLeftY in cells
;           d4 - base tile word added to every source word: tile number plus
;                palette/priority bits (e.g. $6000 = tile 0, palette 3)
;           d5 - destination VRAM byte address (plane base, e.g. $4000)
;           d6 - plane width in cells (128 for the intro planes)
; Out:      a0 - past the source buffer; d5 - advanced VDP command
; Clobbers: d0-d3/d6
; Notes:    builds a VRAM-write command (CD=01) and streams words through
;           VdpData; requires auto-increment = 2. The address is
;           d5 + y*planeWidth*2 + x*2, truncated to 16 bits. The command's
;           high word holds CD + A13..A0 and its low word holds A15..A14;
;           adding (planeWidth*2)<<16 advances one row. Rows must stay
;           inside one A13..A0 window, or the carry corrupts CD; the intro
;           planes do. Writes exactly width*height words.
; *************************************************

WriteNametable:
                asl.w   #1,d6 ; d6 = bytes per plane row
                mulu.w  d6,d3 ; d3 = y * bytesPerRow
                add.w   d3,d5 ; d5 += row byte offset (low 16 bits)
                asl.w   #1,d2 ; d2 = x * 2 (two bytes per cell)
                add.w   d2,d5 ; d5 += column byte offset
; convert the byte address in d5 into a VDP VRAM-write command:
; first word = $4000 | A13..A0, second word = A15..A14
                andi.l  #$FFFF,d5 ; keep only the 16-bit address
                asl.l   #2,d5
                lsr.w   #2,d5 ; low word = A13..A0, high word bits 1..0 = A15..A14
                swap    d5 ; command word first, top address bits second
                ori.l   #$40000000,d5 ; CD=01: VRAM write
                swap    d6
                clr.w   d6 ; d6 = bytesPerRow << 16: per-row command increment
                subq.w  #1,d1 ; height-1
                subq.w  #1,d0 ; width-1
                move.w  d0,d2 ; column counter

.loc_2428:
                move.l  d5,(VdpCtrl).l ; set this row's VRAM address
                move.w  d2,d0

.loc_2430:
                move.w  (a0)+,d3 ; relative tile index
                add.w   d4,d3 ; apply tile base + palette/priority bits
                move.w  d3,(VdpData).l ; write the tile word
                dbf     d0,.loc_2430

                add.l   d6,d5 ; advance to the next row
                dbf     d1,.loc_2428

                rts
; End of function WriteNametable

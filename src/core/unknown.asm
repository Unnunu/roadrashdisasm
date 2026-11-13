Audio_Update equ $19F62 ; per-frame tick; flush command buffer to Z80 mailbox
Audio_Init equ $19F66 ; audio init; clear work RAM and load Z80 driver
Audio_StartMusic equ $19F6A ; start song (d0 = song id 0..11)
Audio_StopMusic equ $19F6E ; request stop/pause (processed by Audio_Update)
Audio_PlaySfx equ $19F72 ; SFX dispatcher (d0 0..18 -> jump table $1A6D6)
Audio_Engine1Start equ $19F76 ; engine ch.1 start ($FF0208=1/3)
Audio_Engine1Stop equ $19F7A ; engine ch.1 stop ($FF0208=3)
Audio_Engine1Update equ $19F7E ; engine ch.1 update ($FF0204/$FF0209)
Audio_Engine2Start equ $19F82 ; engine ch.2 start ($FF020E=1/3)
Audio_Engine2Stop equ $19F86 ; engine ch.2 stop ($FF020E=3)
Audio_Engine2Update equ $19F8A ; engine ch.2 update ($FF020A/$FF020F)
Audio_Engine3Start equ $19F8E ; engine ch.3 start ($FF0214=1/3)
Audio_Engine3Stop equ $19F92 ; engine ch.3 stop ($FF0214=3)
Audio_Engine3Update equ $19F96 ; engine ch.3 update ($FF0210/$FF0215)
; Audio_StopMusicChannel3..18 remain numeric until their roles are dynamically confirmed.
Audio_StopMusicChannel3 equ $19F9A ; stop music channel state ($FF011C=3)
Audio_SetEngineDistance equ $19F9E ; set distance-derived parameter ($FF021B=d1)
Audio_StopMusicChannel4 equ $19FA2 ; stop music channel state ($FF0164=3; $FF021D=0)
Audio_Resume equ $19FA6 ; resume/continue audio unless $FF01F4==1

; Actor/opponent tables now defined in race_engine_tables.asm/race_actor_tables.asm/
; race_actor_extra_tables.asm; track records in race_track_data.asm (see docs/analysis/race_actors.md)

; Rider intro portrait images (11 unique in the ROM tail).

; Results-screen track images (pointed to by RaceResults_TrackImagePtrs).

SONG_INTRO equ 1

; Menu_ram_PlayerMode values.
PLAYER_MODE_A equ 1
PLAYER_MODE_B equ 2
PLAYER_MODE_TWO_PLAYERS equ 3

; Menu_ram_Player values.
PLAYER_SLOT_A equ 0
PLAYER_SLOT_B equ $FFFF

; Menu_ram_CurrentTrackId values (five races, even ids).
TRACK_ID_SIERRA_NEVADA equ 0
TRACK_ID_PACIFIC_COAST equ 2
TRACK_ID_REDWOOD_FOREST equ 4
TRACK_ID_PALM_DESERT equ 6
TRACK_ID_GRASS_VALLEY equ 8

; Starting level for a fresh player profile.
PLAYER_LEVEL_START equ 1

; Default starting bike id.
BIKE_ID_START equ 0

; Race outcome values (Race_ram_PlayerAOutcome/BOutcome).
RACE_OUTCOME_NONE equ 0

; Race place value for a race that has not been played.
RACE_PLACE_NONE equ 0

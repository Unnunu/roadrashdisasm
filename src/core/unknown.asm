sub_13D44 equ $13D44


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


loc_7E6A2 equ $7E6A2

; Rider intro portrait images (11 unique in the ROM tail).

; Results-screen track images (pointed to by unk_7E670).

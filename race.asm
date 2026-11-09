; *************************************************
; race.asm - main gameplay (include split)
; ROM range: $A4E2-$16E6F
; Include order: race_core, race_hud, race_physics, road_marking, race_ai,
;                animation, race_spawn
; *************************************************

    include "race_core.asm"
    include "race_hud.asm"
    include "race_physics.asm"
    include "road_marking.asm"
    include "race_ai_road.asm"
    include "race_ai.asm"
    include "race_anim_audio.asm"
    include "animation.asm"
    include "race_spawn.asm"

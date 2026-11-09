; *************************************************
; race.asm - main gameplay (include split)
; ROM range: $A4E2-$16E6F
; Include order: combat_const, race_core, race_hud, race_physics, road_marking,
;                race_ai, race_anim_audio, race_combat, animation, race_spawn
; *************************************************

    include "combat_const.asm"
    include "race_core.asm"
    include "race_hud.asm"
    include "race_physics.asm"
    include "road_marking.asm"
    include "race_ai_road.asm"
    include "race_ai.asm"
    include "race_anim_audio.asm"
    include "race_combat.asm"
    include "animation.asm"
    include "race_spawn.asm"

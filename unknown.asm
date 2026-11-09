sub_13D44 equ $13D44

RiderIntro_RecordTable equ $19A12
RaceResults_LevelTablePos equ $19D32
RaceResults_LevelTableNeg equ $19DD2
RaceResults_CopTablePos equ $19E22
RaceResults_CopTableNeg equ $19EC2
EndLevel_LevelRiderTable equ $19F12

AudioFunc1 equ $19F62
AudioFunc2 equ $19F66
AudioFunc3 equ $19F6A
AudioFunc4 equ $19F6E
AudioFunc5 equ $19F72
AudioFunc6 equ $19F76
AudioFunc7 equ $19F7A
AudioFunc8 equ $19F7E
AudioFunc9 equ $19F82
AudioFunc10 equ $19F86
AudioFunc11 equ $19F8A
AudioFunc12 equ $19F8E
AudioFunc13 equ $19F92
AudioFunc14 equ $19F96
AudioFunc15 equ $19F9A
AudioFunc16 equ $19F9E
AudioFunc17 equ $19FA2
AudioFunc18 equ $19FA6

unk_257D0 equ $257D0
unk_257E2 equ $257E2
unk_257E8 equ $257E8
unk_257EE equ $257EE
unk_25802 equ $25802
unk_2580A equ $2580A
unk_25812 equ $25812
; Actor/opponent tables (see docs/analysis/race_actors.md)
Race_ActorList equ $25856 ; player A + 15 opponent actor pointers, FFFFFFFF-terminated
Race_ActorListMid equ $2585E ; sub-list used by Race_InitActorLists
Race_StaticActorList equ $2589A ; static actor pointers (type $10)
unk_258A6 equ $258A6
unk_258AE equ $258AE
Race_ActorGraphicsTable equ $258EE ; graphics entries indexed by actor definition byte2
unk_259B6 equ $259B6
unk_259C0 equ $259C0
unk_25A10 equ $25A10
unk_25A44 equ $25A44
unk_25AC4 equ $25AC4
unk_25B50 equ $25B50
unk_25B70 equ $25B70
unk_25EC0 equ $25EC0

Road_ShapeTable equ $3BF1A
word_3C7EA equ $3C7EA

unk_7DCA8 equ $7DCA8
unk_7DEAA equ $7DEAA
Shop_BikePalettes equ $7E370
unk_7E470 equ $7E470
unk_7E670 equ $7E670
unk_7E684 equ $7E684
unk_7E68E equ $7E68E
unk_7E698 equ $7E698
loc_7E6A2 equ $7E6A2
unk_7EA66 equ $7EA66
ImgHighScoreBadge equ $7EB72
unk_7ED66 equ $7ED66
img_MainMenu_RaceSelectionBackground equ $7F02C
EndLevel_WindowImage equ $7F400
img_Gamepad equ $7F834
Boot_CheckRomChecksum equ $7FF98
EndLevel_AnimationTiles equ $80000
EndLevel_AnimationData equ $8BF12
unk_9B2F0 equ $9B2F0
unk_9B7A6 equ $9B7A6
unk_9B494 equ $9B494
unk_9B89E equ $9B89E
unk_9C82A equ $9C82A
unk_9DA6A equ $9DA6A
unk_9DB68 equ $9DB68
unk_9DC4C equ $9DC4C
unk_9DDCC equ $9DDCC
unk_9E3A2 equ $9E3A2
ImgShopArrowLeft equ $9E784
ImgShopArrowRight equ $9E874
ImgShopBike1 equ $9EA1E
ImgShopBike2 equ $9FDDE
ImgShopBike3 equ $A122A
img_mainMenu_PlayerSelection equ $A270C
img_Intro_Font equ $A27D4
FontHighScoreTable equ $A2BAA
unk_A2E68 equ $A2E68
ImgHighScoreTitle equ $A2F5C
img_MainMenu_RaceBadges equ $A37AA
img_mainMenu_RaceCards equ $A4498
img_PasswordMenu_PlayerSelection equ $A7722
img_Intro_Background equ $A7834
img_Intro_Title equ $ACA00
img_MainMenu_Background equ $AE8CE
unk_AF26C equ $AF26C
unk_AF902 equ $AF902
unk_B1506 equ $B1506

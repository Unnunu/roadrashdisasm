; *************************************************
; rider_intro_quotes.asm - rider intro/results quote records
; ROM range: $16E70-$19A11; included from src/main.asm before race_data_tables.asm.
;
; Each record: word y, word x, word height, word width (characters), followed by
; height*width text bytes (row-major, space-padded). Header values are decimal.
; The 85 records referenced only by RiderIntro_RecordTable are named
; RiderIntro_Quote_<Rider>_<NN> from the portrait header names; results/end-level
; quotes keep the address-based RaceQuote_<addr> form.
; Consecutive records are 2-byte aligned with `align 2,0`; only the special case at
; $172D0 keeps an explicit byte (see the NOTE there).
; *************************************************

RiderIntro_Quote_Natasha_01:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "Some of these jerks"
    dc.b    "would rather fight "
    dc.b    "than race. Watch   "
    dc.b    "yourself out there."
    align 2,0

RiderIntro_Quote_Natasha_02:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Viper's got a club. "
    dc.b    "If he swings at you,"
    dc.b    "grab it.            "
    align 2,0

RiderIntro_Quote_Natasha_03:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "watch for intersection"
    dc.b    "signs. They can save  "
    dc.b    "you in a blind turn.  "
    align 2,0

RiderIntro_Quote_Natasha_04:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "Stay on the road. the"
    dc.b    "sand is slippery and "
    dc.b    "you may lose control."
    align 2,0

RiderIntro_Quote_Natasha_05:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "I don't like to     "
    dc.b    "fight, but if I have"
    dc.b    "to, i'll make the   "
    dc.b    "bruiser hate life.  "
    align 2,0

RiderIntro_Quote_Natasha_06:
    dc.w    7,16,4,21 ; y,x,height,width
    dc.b    "Ready for a new bike "
    dc.b    "yet? Don't spend all "
    dc.b    "your cash. Save some "
    dc.b    "for fines and wrecks."
    align 2,0

RiderIntro_Quote_Natasha_07:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "This course can be    "
    dc.b    "tough. tap the brake  "
    dc.b    "if you start to slide."
    align 2,0

RiderIntro_Quote_Natasha_08:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "Slater's crazed. he"
    dc.b    "jumped a cow last  "
    dc.b    "time we raced here."
    align 2,0

RiderIntro_Quote_Natasha_09:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "some trashers use "
    dc.b    "the roadside rocks"
    dc.b    "as ramps... once. "
    align 2,0

RiderIntro_Quote_Natasha_10:
    dc.w    7,16,3,17 ; y,x,height,width
    dc.b    "expect anything  "
    dc.b    "from spike. don't"
    dc.b    "trust him.       "
    align 2,0

RiderIntro_Quote_Natasha_11:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "ikira may be a bit  "
    dc.b    "serious but he's not"
    dc.b    "out to hurt anyone. "
    align 2,0

RiderIntro_Quote_Natasha_12:
    dc.w    7,16,5,18 ; y,x,height,width
    dc.b    "sometimes the only"
    dc.b    "way to lose a cop "
    dc.b    "is to sucker them "
    dc.b    "into slowing down,"
    dc.b    "then dust'em.     "
    align 2,0

RiderIntro_Quote_Natasha_13:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "Don't be afraid to "
    dc.b    "use the brake. you "
    dc.b    "can turn tighter by"
    dc.b    "slowing down.      "
    align 2,0

RiderIntro_Quote_Natasha_14:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "the cops are getting"
    dc.b    "smarter. watch out  "
    dc.b    "for roadblocks here."
    align 2,0

RiderIntro_Quote_Natasha_15:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "keep your distance"
    dc.b    "from helldog. the "
    dc.b    "guy's an animal.  "
    align 2,0

RiderIntro_Quote_Natasha_16:
    ; NOTE: the header says width=22, but the text was authored as 3 lines of 23.
    ; The renderer uses 22, so the game shows different line breaks than this source;
    ; the bytes are preserved exactly (3x23 text + the trailing $00).
    dc.w    7,16,3,22 ; y,x,height,width (width is wrong: should be 23)
    dc.b    "Watch out for the beef."
    dc.b    "there's a fence broken "
    dc.b    "down the road.         "

QuoteGap_1731D:
    dc.b    $00

RiderIntro_Quote_Natasha_17:
    dc.w    7,16,4,22 ; y,x,height,width
    dc.b    "you can sucker helldog"
    dc.b    "into a wreck. start a "
    dc.b    "fight with him and he "
    dc.b    "may forget the traffic"
    align 2,0

RiderIntro_Quote_Natasha_18:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "be careful. officer "
    dc.b    "o'connor is almost  "
    dc.b    "as tough as helldog."
    align 2,0

RiderIntro_Quote_Natasha_19:
    dc.w    7,16,4,21 ; y,x,height,width
    dc.b    "this course is really"
    dc.b    "windy toward the end."
    dc.b    "don't try pushing it "
    dc.b    "too hard.            "
    align 2,0

RiderIntro_Quote_Natasha_20:
    dc.w    7,16,2,19 ; y,x,height,width
    dc.b    "You're on your own "
    dc.b    "now. good luck.    "
    align 2,0

RiderIntro_Quote_Natasha_21:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "Don't count on me for"
    dc.b    "help when you hack me"
    dc.b    "out on the track.    "
    align 2,0

RiderIntro_Quote_Natasha_22:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "You should listen "
    dc.b    "to what Biff has  "
    dc.b    "to say. Great Guy!"
    align 2,0

RiderIntro_Quote_Natasha_23:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "out of my face, bud."
    dc.b    "you'd be wise to    "
    dc.b    "keep your distance. "
    align 2,0

RiderIntro_Quote_Natasha_24:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "I thought we had an "
    dc.b    "understanding? i can"
    dc.b    "trust you as much as"
    dc.b    "i trust biff.       "
    align 2,0

RiderIntro_Quote_Natasha_25:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "want to be a victim?"
    dc.b    "just pull up beside "
    dc.b    "me during the race. "
    align 2,0

RiderIntro_Quote_Natasha_26:
    dc.w    7,16,5,20 ; y,x,height,width
    dc.b    "if i see ya sprawled"
    dc.b    "out on the pavement "
    dc.b    "i'll do you a favor "
    dc.b    "and put you out of  "
    dc.b    "your misery.        "
    align 2,0

RiderIntro_Quote_Natasha_27:
    dc.w    7,16,2,17 ; y,x,height,width
    dc.b    "You touch me, you"
    dc.b    "die. Simple.     "
    align 2,0

RiderIntro_Quote_Natasha_28:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "i've got a big     "
    dc.b    "stick and it's got "
    dc.b    "your name on it.   "
    align 2,0

RiderIntro_Quote_Natasha_29:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "go face down on the"
    dc.b    "pavement lately or "
    dc.b    "do you always look "
    dc.b    "like that?         "
    align 2,0

RiderIntro_Quote_Natasha_30:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "Keep your distance."
    dc.b    "Get too close and  "
    dc.b    "I'll take you out. "
    align 2,0

RaceQuote_17720:
    dc.w    7,16,5,20 ; y,x,height,width
    dc.b    "you're pretty good. "
    dc.b    "Let's ride with the "
    dc.b    "next gang. Bigger   "
    dc.b    "risks for bigger    "
    dc.b    "bucks.              "
    align 2,0

RaceQuote_1778C:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "Are you ready to move"
    dc.b    "on? There's a tougher"
    dc.b    "crowd waiting for us."
    align 2,0

RaceQuote_177D4:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Watch yourself. The "
    dc.b    "game starts getting "
    dc.b    "rough from here out."
    align 2,0

RaceQuote_17818:
    dc.w    7,16,2,20 ; y,x,height,width
    dc.b    "We're up against the"
    dc.b    "vet rashers now.    "
    align 2,0

RaceQuote_17848:
    dc.w    7,16,4,21 ; y,x,height,width
    dc.b    "congratulations.     "
    dc.b    "you're now one of the"
    dc.b    "rasher vets. how long"
    dc.b    "can you stay on top? "
    align 2,0

RiderIntro_Quote_OLeary_01:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Now take it easy and"
    dc.b    "don't let me catch  "
    dc.b    "you speeding. Okay? "
    align 2,0

RiderIntro_Quote_OLeary_02:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "You don't want to   "
    dc.b    "get me mad. I can be"
    dc.b    "a pretty tough guy  "
    dc.b    "when I want to be.  "
    align 2,0

RiderIntro_Quote_OLeary_03:
    dc.w    7,16,4,18 ; y,x,height,width
    dc.b    "Please don't drive"
    dc.b    "so fast. The sarge"
    dc.b    "is getting upset  "
    dc.b    "with you people.  "
    align 2,0

RaceQuote_17990:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Be nice to the judge"
    dc.b    "and maybe you'll get"
    dc.b    "traffic school.     "
    align 2,0

RaceQuote_179D4:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "Excessive speed is  "
    dc.b    "dangerous. Does your"
    dc.b    "mother know where   "
    dc.b    "you are?            "
    align 2,0

RaceQuote_17A2C:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "Traveling at unsafe"
    dc.b    "speeds is wrong. I "
    dc.b    "must protect you   "
    dc.b    "from yourself.     "
    align 2,0

RaceQuote_17A80:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "Traffic codes have"
    dc.b    "been violated. You"
    dc.b    "must be fined.    "
    align 2,0

RaceQuote_17ABE:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "You've been caught "
    dc.b    "one too many times."
    dc.b    "Pick another hobby."
    align 2,0

RaceQuote_17B00:
    dc.w    7,16,2,21 ; y,x,height,width
    dc.b    "Out of money, go to  "
    dc.b    "jail, that's the law."
    align 2,0

RiderIntro_Quote_ORourke_01:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "You'd better not be "
    dc.b    "one of those wild   "
    dc.b    "biker types. I'm out"
    dc.b    "to get me a rasher. "
    align 2,0

RiderIntro_Quote_ORourke_02:
    dc.w    7,16,4,22 ; y,x,height,width
    dc.b    "the last rasher to try"
    dc.b    "outrunnin' me was a   "
    dc.b    "skidmark when i was   "
    dc.b    "through with'em.      "
    align 2,0

RiderIntro_Quote_ORourke_03:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "You punks think you're"
    dc.b    "so fast. Wait 'til you"
    dc.b    "see me on your tail.  "
    align 2,0

RiderIntro_Quote_ORourke_04:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "don't eyeball me,   "
    dc.b    "bud. i want a little"
    dc.b    "respect, ya hear?   "
    align 2,0

RaceQuote_17C78:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "Ah, what a feeling."
    dc.b    "First collar of the"
    dc.b    "day.               "
    align 2,0

RaceQuote_17CBA:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "believe me kid, this  "
    dc.b    "ticket is only the    "
    dc.b    "beginning of the hurt."
    align 2,0

RaceQuote_17D04:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "You've been cited for "
    dc.b    "speeding in the pre-  "
    dc.b    "sence of an officer.  "
    align 2,0

RaceQuote_17D4E:
    dc.w    7,16,3,16 ; y,x,height,width
    dc.b    "Cut the excuses."
    dc.b    "Save the whining"
    dc.b    "for the judge.  "
    align 2,0

RaceQuote_17D86:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "Serve and Protect."
    dc.b    "With you in jail, "
    dc.b    "I can do both.    "
    align 2,0

RaceQuote_17DC4:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "This is the worst "
    dc.b    "day of the rest of"
    dc.b    "your life.        "
    align 2,0

RiderIntro_Quote_Flynn_01:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "what's your name?   "
    dc.b    "i'm fillin' out some"
    dc.b    "tickets in advance. "
    align 2,0

RiderIntro_Quote_Flynn_02:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "be fly, sly boy or "
    dc.b    "i'm gonna put you  "
    dc.b    "out like the trash."
    align 2,0

RiderIntro_Quote_Flynn_03:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "do yourself some good"
    dc.b    "and ride home while  "
    dc.b    "you're still walkin'."
    align 2,0

RaceQuote_17ED0:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "Don't get uptight, "
    dc.b    "it's only money.   "
    dc.b    "Nothing for a big  "
    dc.b    "wheeler like you.  "
    align 2,0

RaceQuote_17F24:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "Yo, speedo. Give it"
    dc.b    "a rest or jail's in"
    dc.b    "your near future.  "
    align 2,0

RaceQuote_17F66:
    dc.w    7,16,5,18 ; y,x,height,width
    dc.b    "what part of ",$22,"slow"
    dc.b    "down",$22," didn't you  "
    dc.b    "understand? Try to"
    dc.b    "figure out this   "
    dc.b    "ticket.           "
    align 2,0

RaceQuote_17FC8:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "Keep driving like that"
    dc.b    "and you'll be walkin',"
    dc.b    "if you're lucky.      "
    align 2,0

RaceQuote_18012:
    dc.w    7,16,4,18 ; y,x,height,width
    dc.b    "Out of money big  "
    dc.b    "wheeler? Just roll"
    dc.b    "yourself into the "
    dc.b    "paddy wagon.      "
    align 2,0

RaceQuote_18062:
    dc.w    7,16,4,17 ; y,x,height,width
    dc.b    "It looks like you"
    dc.b    "should've been a "
    dc.b    "little smarter or"
    dc.b    "a lot richer.    "
    align 2,0

RiderIntro_Quote_OShea_01:
    dc.w    7,16,4,22 ; y,x,height,width
    dc.b    "i use to run with the "
    dc.b    "rashers before i wised"
    dc.b    "up. i know the tricks,"
    dc.b    "so heads up, bud.     "
    align 2,0

RiderIntro_Quote_OShea_02:
    dc.w    7,16,4,21 ; y,x,height,width
    dc.b    "hey, rookie. you sure"
    dc.b    "you belong in the big"
    dc.b    "leagues? these guys  "
    dc.b    "will spit you out.   "
    align 2,0

RiderIntro_Quote_OShea_03:
    dc.w    7,16,4,17 ; y,x,height,width
    dc.b    "i usually give   "
    dc.b    "the rasher a     "
    dc.b    "chance run before"
    dc.b    "I haul them in.  "
    align 2,0

RaceQuote_181B6:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "how do you expect to "
    dc.b    "win if you can't out-"
    dc.b    "run me on my hog?    "
    align 2,0

RaceQuote_181FE:
    dc.w    7,16,2,17 ; y,x,height,width
    dc.b    "you broke the law"
    dc.b    "and i won.       "
    align 2,0

RaceQuote_18228:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "kinda slow for a  "
    dc.b    "rasher. i had you "
    dc.b    "pegged as a loser."
    align 2,0

RaceQuote_18266:
    dc.w    7,16,2,21 ; y,x,height,width
    dc.b    "have a ticket and    "
    dc.b    "thanks for the dance."
    align 2,0

RaceQuote_18298:
    dc.w    7,16,3,17 ; y,x,height,width
    dc.b    "time for one last"
    dc.b    "roadtrip. we're  "
    dc.b    "going downtown!  "
    align 2,0

RaceQuote_182D4:
    dc.w    7,16,2,19 ; y,x,height,width
    dc.b    "you just made early"
    dc.b    "retirement, buddy. "
    align 2,0

RiderIntro_Quote_OConnor_01:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "you're all the same."
    dc.b    "high speed hamburger"
    dc.b    "waiting to happen.  "
    align 2,0

RiderIntro_Quote_OConnor_02:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "if i don't drop you,"
    dc.b    "helldog will. you'd "
    dc.b    "better hope it's me."
    align 2,0

RaceQuote_1838A:
    dc.w    7,16,4,21 ; y,x,height,width
    dc.b    "do you think i like  "
    dc.b    "chasing you people,  "
    dc.b    "knocking you down,   "
    dc.b    "dragging you in? yup."
    align 2,0

RaceQuote_183E6:
    dc.w    7,16,2,21 ; y,x,height,width
    dc.b    "seventh ticket today,"
    dc.b    "i'm on a roll!       "
    align 2,0

RaceQuote_18418:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "think you're cool?   "
    dc.b    "wrong. too much speed"
    dc.b    "and not enough heed. "
    align 2,0

RaceQuote_18460:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "Check your wallet."
    dc.b    "it's about to get "
    dc.b    "lighter.          "
    align 2,0

RaceQuote_1849E:
    dc.w    7,16,4,22 ; y,x,height,width
    dc.b    "walk your sorry self  "
    dc.b    "home. i'm confiscating"
    dc.b    "your bike and going   "
    dc.b    "for donuts and coffee."
    align 2,0

RaceQuote_184FE:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "you're at the end of  "
    dc.b    "your luck and the bill"
    dc.b    "is due. game over bud."
    align 2,0

RiderIntro_Quote_Biff_01:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "It's a great day to"
    dc.b    "face challenge on  "
    dc.b    "the open road. Best"
    dc.b    "of luck friend!    "
    align 2,0

RiderIntro_Quote_Biff_02:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "Did I tell you that"
    dc.b    "my bike was custom "
    dc.b    "built? Very pricey."
    align 2,0

RiderIntro_Quote_Biff_03:
    dc.w    7,16,4,17 ; y,x,height,width
    dc.b    "You don't have to"
    dc.b    "worry about me   "
    dc.b    "fighting dirty.  "
    dc.b    "I'm a sportsman! "
    align 2,0

RiderIntro_Quote_Biff_04:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "i'd spend everything i"
    dc.b    "had on a new bike at  "
    dc.b    "the first opportunity."
    align 2,0

RiderIntro_Quote_Biff_05:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "top speed is every- "
    dc.b    "thing. higher speed,"
    dc.b    "quicker finish.     "
    align 2,0

RiderIntro_Quote_Biff_06:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "be a sport. take a  "
    dc.b    "fall and drop out of"
    dc.b    "the race. there's   "
    dc.b    "money in it for you."
    align 2,0

RaceQuote_18710:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Nice piece of work, "
    dc.b    "your bike looks like"
    dc.b    "a Picasso.          "
    align 2,0

RaceQuote_18754:
    dc.w    7,16,4,16 ; y,x,height,width
    dc.b    "the conventional"
    dc.b    "riding style is "
    dc.b    "to hang on, not "
    dc.b    "fall off.       "
    align 2,0

RaceQuote_1879C:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "Is this nap time or"
    dc.b    "should I call an   "
    dc.b    "ambulance?         "
    align 2,0

RaceQuote_187DE:
    dc.w    7,16,3,15 ; y,x,height,width
    dc.b    "Out of money? i"
    dc.b    "knew you looked"
    dc.b    "middle class.  "
    align 2,0

RaceQuote_18814:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "Perhaps something on"
    dc.b    "four wheels is more "
    dc.b    "your style. Try     "
    dc.b    "training wheels!    "
    align 2,0

RaceQuote_1886C:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Great, I thought I  "
    dc.b    "left you behind with"
    dc.b    "the other lowlife.  "
    align 2,0

RiderIntro_Quote_Slater_01:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "vet thrashers run 15  "
    dc.b    "mile races. Our race  "
    dc.b    "is only about 5 miles."
    align 2,0

RiderIntro_Quote_Slater_02:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Cool place, huh. I'm"
    dc.b    "local. look out for "
    dc.b    "cars on blind turns."
    align 2,0

RiderIntro_Quote_Slater_03:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Do you believe that "
    dc.b    "Biff dude? Man, what"
    dc.b    "a mouth!            "
    align 2,0

RiderIntro_Quote_Slater_04:
    dc.w    7,16,4,21 ; y,x,height,width
    dc.b    "i was way loose that "
    dc.b    "last race, man. i saw"
    dc.b    "my race flash before "
    dc.b    "my eyes. whoa!       "
    align 2,0

RiderIntro_Quote_Slater_05:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "thrash and burn. if a"
    dc.b    "gomer takes me out,  "
    dc.b    "they come with me.   "
    align 2,0

RiderIntro_Quote_Slater_06:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "i am tweekin'. if i "
    dc.b    "see dread, i'm going"
    dc.b    "to take his club and"
    dc.b    "liberate his head.  "
    align 2,0

RiderIntro_Quote_Slater_07:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "i am sooo fast. some-"
    dc.b    "times it scares me,  "
    dc.b    "so i close my eyes.  "
    align 2,0

RiderIntro_Quote_Slater_08:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "Don't slam everyone,"
    dc.b    "amigo. No points for"
    dc.b    "bailin'.            "
    align 2,0

RiderIntro_Quote_Slater_09:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "serge is one strange"
    dc.b    "dude! he's polishing"
    dc.b    "his bike and breath-"
    dc.b    "ing heavy.          "
    align 2,0

RiderIntro_Quote_Slater_10:
    dc.w    7,16,4,17 ; y,x,height,width
    dc.b    "Chaos factor is  "
    dc.b    "my mantra. never "
    dc.b    "think or do the  "
    dc.b    "same thing twice."
    align 2,0

RiderIntro_Quote_Slater_11:
    dc.w    7,16,2,19 ; y,x,height,width
    dc.b    "witness me airborn."
    dc.b    "i'm slater, fly me."
    align 2,0

RaceQuote_18BDC:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "Heavy chew, speed    "
    dc.b    "master! You grew some"
    dc.b    "scabs on that one.   "
    align 2,0

RaceQuote_18C24:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "Extreme air on that"
    dc.b    "last bail, man.    "
    dc.b    "truely legendary.  "
    align 2,0

RaceQuote_18C66:
    dc.w    7,16,2,20 ; y,x,height,width
    dc.b    "Truly lame shred,   "
    dc.b    "gomer. What a squid!"
    align 2,0

RaceQuote_18C96:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "hella' slide, squidly"
    dc.b    "didly. stay clear of "
    dc.b    "me on your next bail."
    align 2,0

RaceQuote_18CDE:
    dc.w    7,16,2,21 ; y,x,height,width
    dc.b    "severe impact, gravel"
    dc.b    "tooth. highly flawed!"
    align 2,0

RaceQuote_18D10:
    dc.w    7,16,3,15 ; y,x,height,width
    dc.b    "your scooter is"
    dc.b    "fully tweeked, "
    dc.b    "gomer. tragic! "
    align 2,0

RaceQuote_18D46:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "flame city, speed "
    dc.b    "master, (not). you"
    dc.b    "gagged and burned."
    align 2,0

RaceQuote_18D84:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "superior technique, "
    dc.b    "speed miester. time "
    dc.b    "to fry bigger trout."
    align 2,0

RiderIntro_Quote_Ikira_01:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "be fast. that is the"
    dc.b    "best way to win. let"
    dc.b    "the rest fight      "
    dc.b    "amongst themselves. "
    align 2,0

RiderIntro_Quote_Ikira_02:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "don't let her name"
    dc.b    "fool ya. angel is "
    dc.b    "no saint.         "
    align 2,0

RiderIntro_Quote_Ikira_03:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "i have heard that  "
    dc.b    "viper is out to get"
    dc.b    "you. heads up.     "
    align 2,0

RiderIntro_Quote_Ikira_04:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "i prefer handling to"
    dc.b    "horsepower. power   "
    dc.b    "can't save you      "
    dc.b    "in a sharp turn.    "
    align 2,0

RiderIntro_Quote_Ikira_05:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "it is useless to fight"
    dc.b    "the police. it'll only"
    dc.b    "make matters worse.   "
    align 2,0

RiderIntro_Quote_Ikira_06:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "i believe the best"
    dc.b    "riders only fight "
    dc.b    "when forced to.   "
    align 2,0

RiderIntro_Quote_Ikira_07:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "sergio is a great   "
    dc.b    "mechanic, but a bit "
    dc.b    "strange. he calls   "
    dc.b    "his bike ",$22,"love muf",$22,"."
    align 2,0

RaceQuote_18FD8:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "in such a condition, "
    dc.b    "you have no chance to"
    dc.b    "impress anyone.      "
    align 2,0

RaceQuote_19020:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "it's hard to be cool"
    dc.b    "when you're bleeding"
    dc.b    "like that.          "
    align 2,0

RaceQuote_19064:
    dc.w    7,16,2,17 ; y,x,height,width
    dc.b    "i sympathize with"
    dc.b    "your stupidity.  "
    align 2,0

RaceQuote_1908E:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "in my opinion, you"
    dc.b    "should try not to "
    dc.b    "fall so often.    "
    align 2,0

RaceQuote_190CC:
    dc.w    7,16,2,22 ; y,x,height,width
    dc.b    "one should quit before"
    dc.b    "they run out of money."
    align 2,0

RaceQuote_19100:
    dc.w    7,16,3,15 ; y,x,height,width
    dc.b    "i told you, you"
    dc.b    "shouldn't fall "
    dc.b    "so much.       "
    align 2,0

RaceQuote_19136:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "great racing! there"
    dc.b    "is new competition "
    dc.b    "waiting for us.    "
    align 2,0

RiderIntro_Quote_Sergio_01:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "listen to my cycle,  "
    dc.b    "purring like a big   "
    dc.b    "cat, ready to pounce."
    align 2,0

RiderIntro_Quote_Sergio_02:
    dc.w    7,16,3,17 ; y,x,height,width
    dc.b    "i wait for you at"
    dc.b    "the finish line, "
    dc.b    "amico. yes, no?  "
    align 2,0

RiderIntro_Quote_Sergio_03:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "the handling of my "
    dc.b    "machine excites me."
    dc.b    "do not ask to ride."
    align 2,0

RiderIntro_Quote_Sergio_04:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "hoghide is the son"
    dc.b    "of helldog. like  "
    dc.b    "son, like father. "
    align 2,0

RiderIntro_Quote_Sergio_05:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "luna, she is loco."
    dc.b    "she swings her    "
    dc.b    "club into my face."
    align 2,0

RiderIntro_Quote_Sergio_06:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "your bike is dirty."
    dc.b    "a machine should be"
    dc.b    "respected like a   "
    dc.b    "beautiful woman.   "
    align 2,0

RiderIntro_Quote_Sergio_07:
    dc.w    7,16,4,21 ; y,x,height,width
    dc.b    "i do not need mirrors"
    dc.b    "on my motorbike. What"
    dc.b    "is behind me i do not"
    dc.b    "care about.          "
    align 2,0

RiderIntro_Quote_Sergio_08:
    dc.w    7,16,4,16 ; y,x,height,width
    dc.b    "look out for the"
    dc.b    "poliziotto. be  "
    dc.b    "prepared for a  "
    dc.b    "roadblock.      "
    align 2,0

RiderIntro_Quote_Sergio_09:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "if killjoy gets close"
    dc.b    "to me i will beat him"
    dc.b    "with his own club.   "
    align 2,0

RiderIntro_Quote_Sergio_10:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "helldog, he must be "
    dc.b    "knocked out. like-  "
    dc.b    "wise, he will not   "
    dc.b    "quit until you fall."
    align 2,0

RaceQuote_19452:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "it's finito amico. i"
    dc.b    "pray for you, but i "
    dc.b    "pity your camshaft. "
    align 2,0

RaceQuote_19496:
    dc.w    7,16,4,21 ; y,x,height,width
    dc.b    "listen to sergio when"
    dc.b    "he says, ",$22,"perhaps    "
    dc.b    "dual carburetors are "
    dc.b    "too much for you.",$22,"   "
    align 2,0

RaceQuote_194F2:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "the poliziotto should"
    dc.b    "arrest you for being "
    dc.b    "a road hazard.       "
    align 2,0

RaceQuote_1953A:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "dio mio, bambino. i "
    dc.b    "suggest lessons. you"
    dc.b    "do not fall well.   "
    align 2,0

RaceQuote_1957E:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "i weep for the bike"
    dc.b    "you treat without  "
    dc.b    "respect.           "
    align 2,0

RaceQuote_195C0:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "Disgraziato! your bike"
    dc.b    "is a garbage truck.   "
    dc.b    "start over, i beg you."
    align 2,0

RaceQuote_1960A:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "porco miseria,     "
    dc.b    "paisan! your crank-"
    dc.b    "case is in ruins!  "
    align 2,0

RaceQuote_1964C:
    dc.w    7,16,3,18 ; y,x,height,width
    dc.b    "fantastico, amico."
    dc.b    "we go on to ride  "
    dc.b    "with the best.    "
    align 2,0

RiderIntro_Quote_Helldog_01:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "i get pleasure from"
    dc.b    "dragging newcomers "
    dc.b    "down the road by   "
    dc.b    "their ankles.      "
    align 2,0

RiderIntro_Quote_Helldog_02:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "do yourself a favor"
    dc.b    "and keep your dis- "
    dc.b    "tance from me.     "
    align 2,0

RiderIntro_Quote_Helldog_03:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "sometimes i pull over"
    dc.b    "and scalp my victims "
    dc.b    "after they fall.     "
    align 2,0

RiderIntro_Quote_Helldog_04:
    dc.w    7,16,3,20 ; y,x,height,width
    dc.b    "the skulls on my gas"
    dc.b    "tank? they're like  "
    dc.b    "notches on a gun.   "
    align 2,0

RiderIntro_Quote_Helldog_05:
    dc.w    7,16,4,20 ; y,x,height,width
    dc.b    "if i miss the chance"
    dc.b    "to knock you down on"
    dc.b    "the road, i'll do   "
    dc.b    "it after the race.  "
    align 2,0

RiderIntro_Quote_Helldog_06:
    dc.w    7,16,4,22 ; y,x,height,width
    dc.b    "i think it's important"
    dc.b    "to enjoy what you do. "
    dc.b    "i enjoy causing pain  "
    dc.b    "and i do it well.     "
    align 2,0

RaceQuote_19864:
    dc.w    7,16,4,19 ; y,x,height,width
    dc.b    "tell me, does it   "
    dc.b    "hurt? you look like"
    dc.b    "you're in pain but "
    dc.b    "i want to be sure. "
    align 2,0

RaceQuote_198B8:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "don't worry, the birds"
    dc.b    "will pick up what you "
    dc.b    "have left behind.     "
    align 2,0

RaceQuote_19902:
    dc.w    7,16,3,17 ; y,x,height,width
    dc.b    "go home and enjoy"
    dc.b    "your suffering. i"
    dc.b    "know i will.     "
    align 2,0

RaceQuote_1993E:
    dc.w    7,16,3,19 ; y,x,height,width
    dc.b    "i'm the king of the"
    dc.b    "road and you're    "
    dc.b    "the king of pain.  "
    align 2,0

RaceQuote_19980:
    dc.w    7,16,3,21 ; y,x,height,width
    dc.b    "no one beats me. they"
    dc.b    "go home in pain or   "
    dc.b    "they don't go home.  "
    align 2,0

RaceQuote_199C8:
    dc.w    7,16,3,22 ; y,x,height,width
    dc.b    "you've won this battle"
    dc.b    "but my war isn't over."
    dc.b    "you'll see me again.  "
    align 2,0

RiderIntro_QuoteData equ RiderIntro_Quote_Natasha_01

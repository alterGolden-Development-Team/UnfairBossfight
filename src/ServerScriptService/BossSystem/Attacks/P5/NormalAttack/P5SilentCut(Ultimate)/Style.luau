 -- Silent Cut (ultimate, Normal Attack folder; after Devil May Cry 5's Judgment Cut End). He drops into a low draw
 -- stance for Stance seconds and the world goes still: every target's screen turns gold and drained, bars close in.
 -- He vanishes for Cuts seconds while Lines slash lines fill the space around each target (and across their screen).
 -- He is back behind the first one, sheathing slowly for Sheathe seconds - HOLD E - and as the blade clicks home every
 -- line detonates and the screen shatters. Whoever it catches loses HalfHealth of their health, which seeps back over
 -- RestoreTime. Then Follow quick silent cuts - a few lines, a click - TAP E for each, or lose FollowDamage.
return table.freeze({
	Name = "P5SilentCut(Ultimate)", Cooldown = 65,
	Stance = 1, Cuts = 0.9, Sheathe = 0.75, Lines = 26, Radius = 22,
	HalfHealth = 0.5, RestoreTime = 10,
	Follow = 3, FollowLines = 7, FollowLead = 0.55, FollowGap = 0.45, FollowDamage = 35,
})

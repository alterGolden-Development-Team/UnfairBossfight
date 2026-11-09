 -- Lightning Dash: P1's Golden Thrust a hundred times over. A crackle on him (the cue), then a hundred lightning
 -- dashes in about five seconds, each one straight through you from a fresh angle - any direction. Far too fast to
 -- time one by one: MASH E the whole way (one shield covers the flurry, so mashing never trips the lock) and every
 -- dash that lands within Mash seconds of a press is turned away. The last dash is bigger and ends in a burst.
return table.freeze({
	Name = "P5LightningDash", Cooldown = 12,
	Cue = 0.6, Dashes = 100, Every = 0.04, Time = 0.03,  -- about four seconds for all hundred
	Reach = 30, Through = 30, Width = 4.5, Damage = 6, Mash = 0.3, Clang = 8,
	FinalDamage = 55, FinalRadius = 12,
})

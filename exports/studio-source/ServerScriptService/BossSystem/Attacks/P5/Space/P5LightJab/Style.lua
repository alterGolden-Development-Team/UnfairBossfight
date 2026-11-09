 -- Light Jab (up close): he levels the rapier and spams it forward over and over, stepping in after you. Every stab
 -- is a spray of rapier dashes - several lanes side by side, each dash starting at a different depth with gaps between
 -- them - so look for the gaps. Then one long thrust of full-length rapiers that throws you back.
return table.freeze({
	Name = "P5LightJab", Cooldown = 7, UseRange = 34,
	Ready = 0.35, Jabs = 14, Every = 0.085, Damage = 9, Advance = 1.4,
	-- Reach: how far out the dashes can go (long); Lanes x LaneGap: how wide the spray is; RapierRadius: a dash's half width
	Reach = 40, Lanes = 5, LaneGap = 4.2, RapierRadius = 1.7,
	FinalReach = 52, FinalDamage = 35, FinalRapiers = 5,
})

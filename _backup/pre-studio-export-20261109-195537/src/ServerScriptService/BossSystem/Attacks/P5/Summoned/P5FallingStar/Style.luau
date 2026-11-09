 -- Falling Star (Space mode; after Aurelion Sol's Falling Star): he raises a hand to the sky. Small stars rain down
 -- first, Small of them, each marked by a circle for Fall seconds; then one great star falls on the target - its
 -- circle Radius wide - and crashes with a crater, a shockwave and BigDamage.
return table.freeze({
	Name = "P5FallingStar", Cooldown = 16,
	Tell = 0.5, Small = 4, SmallRadius = 10, SmallDamage = 45, SmallGap = 0.3, Fall = 1.3,
	Radius = 24, BigDamage = 110, BigFall = 1.6,
	SummonMin = 3, SummonMax = 5, SummonSpread = 16, SummonGap = 0.15,
	WaveSpeed = 140, WaveRange = 70, WaveWidth = 6, WaveHeight = 4, WaveDamage = 30,
})

 -- Fang-Dive (used up close): two swipes (TAP E each), an uppercut that throws him up into the air, then he dives down
 -- onto where you are and barrages the ground around his landing. Deflect the swipes, then roll, then roll again to
 -- get out from under the dive. The openings are tight: don't try to stagger him through it.
return table.freeze({
	Name = "P5Fang-Dive", Cooldown = 9, UseRange = 30,
	Lead = 0.3, SwipeReach = 14, SwipeAngle = 75, SwipeDamage = 40,
	UpperReach = 12, UpperDamage = 50, Rise = 24, RiseTime = 0.3, Hang = 0.35, DiveTime = 0.22, Predict = 0.4,
	Barrage = 8, BarrageEvery = 0.07, BarrageRadius = 12, BarrageDamage = 14, FinalRadius = 14, FinalDamage = 45,
})

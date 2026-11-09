 -- Fang-Cross (used up close): he flashes yellow, then two swipes - each aimed where you are going (walk in a
 -- zig-zag) - then a vertical slam: an explosion and a shockwave along the floor. Time a roll for the slam.
return table.freeze({
	Name = "P5Fang-Cross", Cooldown = 9, UseRange = 32,
	Flash = 0.4, Predict = 0.45, Step = 9, StepTime = 0.12, SwipeReach = 15, SwipeAngle = 70, SwipeDamage = 45,
	SlamTell = 0.45, SlamReach = 7, SlamRadius = 15, SlamDamage = 75,
	WaveSpeed = 110, WaveRange = 90, WaveDamage = 40,
})

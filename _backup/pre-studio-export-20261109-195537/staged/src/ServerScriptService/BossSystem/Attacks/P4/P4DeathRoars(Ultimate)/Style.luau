 
 
local BASE = table.freeze({
	Cooldown = 85,

	Yellow = Color3.fromRGB(255, 214, 50),
	Gold = Color3.fromRGB(255, 165, 20),
	White = Color3.fromRGB(255, 251, 228),

	 
	 
	Intro = { Duration = 1.8, Raise = 0.6, FirstStreaks = 1.0 },  -- short wind-up; no cutscene

	 
	Barrage = {
		Duration = 15,
		 
		StreakStart = 18, StreakEnd = 36,  
		StreakSpan = { 0.7, 1.1 },
		 
		FollowEvery = { 0.6, 0.4 },  
		FollowLag = 0.45,  
		 
		RandomStart = 12, RandomEnd = 24,  
		RandomGlint = 0.35,
		Crescents = { 10, 14 },
		FollowCrescents = { 3, 5 },  
		SwarmRadius = 12,
		FollowRadius = 6.5,
		HealthFraction = 0.01,
		TickEvery = 0.1,
	},


	Finish = { Duration = 0.3, Rings = 2, RingSegments = 64 },
	 
	 
	Finale = { Freeze = 1.4, Sweep = 0.28, After = 2.4, BladeLength = 250, BurstDamage = 50, SwordDamage = 150, BurstHeight = 8 },
	Poses = {
		 
		Raise = { RightShoulder = { 165, 0, 15 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { 25, 0, -25 }, LeftElbow = { 30, 0, 0 },
			Neck = { -18, 0, 0 }, Waist = { -6, 0, 0 } },
		 
		Command = { RightShoulder = { 95, 0, 25 }, RightElbow = { 8, 0, 0 }, LeftShoulder = { 10, 0, -12 }, LeftElbow = { 25, 0, 0 },
			Neck = { 4, 0, 0 }, Waist = { 0, -12, 0 } },
	},
})

 
return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = { Barrage = { Duration = 18, FollowEvery = { 0.45, 0.3 }, FollowLag = 0.3, RandomStart = 16, RandomEnd = 32 } },
	Hardcore = { Barrage = { Duration = 13, FollowEvery = { 0.7, 0.5 } } },
	NerfedHardcore = { Barrage = { Duration = 10, FollowEvery = { 0.85, 0.65 }, FollowLag = 0.6, RandomStart = 8, RandomEnd = 16 } },
})

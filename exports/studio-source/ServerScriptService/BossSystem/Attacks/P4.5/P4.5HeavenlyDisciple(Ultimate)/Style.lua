 
 
 
 
 
 
local BASE = table.freeze({
	Cooldown = 70,

	Gold = Color3.fromRGB(255, 196, 40),
	Yellow = Color3.fromRGB(255, 226, 80),
	Bright = Color3.fromRGB(255, 244, 170),
	White = Color3.fromRGB(255, 252, 232),
	Electric = Color3.fromRGB(255, 240, 150),
	Spark = Color3.fromRGB(200, 230, 255),  
	Night = Color3.fromRGB(120, 150, 255),  

	StarHeight = 78,  
	Levitate = 5,  

	 
	Intro = {
		Star = 1.0,  -- intro trimmed from 5.65 s to 3.85 s; no cutscene
		Charge = 0.8,  
		Draw = 0.6,  
		Flight = 0.55,  
		Bloom = 0.9,  
	},

	 
	Rain = {
		Count = 110, FinalVolley = 10,
		VolleySize = 5, VolleyInterval = 0.2,
		Telegraph = 0.6, Flight = 0.38,
		AimedShare = 0.3, Spread = 7, Lead = 0.35,
		Radius = 7,  -- bigger arrows, bigger blasts
		Damage = 6, Stun = 0.6, StunGrace = 0.9,
		JudgementRing = 9, JudgementTelegraph = 1.1, JudgementScale = 3.2,
	},

	 
	 
	 
	Quills = { Min = 0, Max = 3, Damage = 3, Rise = 0.45, Speed = { 34, 100 }, Turn = { 4, 16 }, Life = 7, HitRadius = 2.8, Cap = 160 },

	 
	Heal = 25,

	Poses = {
		Summon = { RightShoulder = { 165, 0, 10 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 20, 0, -20 }, LeftElbow = { 20, 0, 0 },
			Neck = { -28, 0, 0 }, Waist = { -8, 0, 0 } },
		Charge = { RightShoulder = { 10, 0, 75 }, RightElbow = { 25, 0, 0 }, LeftShoulder = { 10, 0, -75 }, LeftElbow = { 25, 0, 0 },
			Neck = { -10, 0, 0 }, Waist = { 0, 0, 0 } },
		Draw = { LeftShoulder = { 140, 0, -15 }, LeftElbow = { 0, 0, 0 }, RightShoulder = { 125, 0, 35 }, RightElbow = { 95, 0, 0 },
			Neck = { -35, 0, 0 }, Waist = { -14, 20, 0 } },
		Release = { LeftShoulder = { 145, 0, -15 }, LeftElbow = { 0, 0, 0 }, RightShoulder = { 105, 0, 75 }, RightElbow = { 30, 0, 0 },
			Neck = { -38, 0, 0 }, Waist = { -14, 25, 0 } },
		Conduct = { RightShoulder = { 160, 0, 15 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { 60, 0, -30 }, LeftElbow = { 20, 0, 0 },
			Neck = { -20, 0, 0 }, Waist = { -6, 0, 0 } },
		Point = { RightShoulder = { 95, 0, 0 }, RightElbow = { 0, 0, 0 }, RightWrist = { -10, 0, 0 }, LeftShoulder = { 30, 0, -45 },
			LeftElbow = { 30, 0, 0 }, Neck = { -6, 0, 0 }, Waist = { 0, -10, 0 } },
		Judgement = { RightShoulder = { 175, 0, 5 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 175, 0, -5 }, LeftElbow = { 0, 0, 0 },
			Neck = { -40, 0, 0 }, Waist = { -12, 0, 0 } },
	},
})

 
return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = {
		Rain = { Count = 180, FinalVolley = 18, VolleySize = 7, VolleyInterval = 0.13,
			Telegraph = 0.45, Flight = 0.32, AimedShare = 0.4, Spread = 5, Lead = 0.45,
			Radius = 7.5, JudgementTelegraph = 0.9 },
		Quills = { Max = 4 },
	},
	TrueHardcore = { Rain = { Count = 110 } },
	Hardcore = {
		Rain = { Count = 85, FinalVolley = 10, VolleySize = 4, VolleyInterval = 0.24,
			Telegraph = 0.7, AimedShare = 0.25, Spread = 8, Lead = 0.25, Radius = 6.5 },
	},
	NerfedHardcore = {
		Rain = { Count = 60, FinalVolley = 8, VolleySize = 3, VolleyInterval = 0.28,
			Telegraph = 0.85, AimedShare = 0.2, Spread = 9, Lead = 0.15, Radius = 6.25,
			JudgementTelegraph = 1.4 },
		Quills = { Max = 2 },
	},
	 
	Easy = {
		Rain = { Count = 32, FinalVolley = 6, VolleySize = 2, VolleyInterval = 0.34,
			Telegraph = 1.1, Flight = 0.5, AimedShare = 0.15, Spread = 11, Lead = 0,
			Radius = 6, Stun = 0.35, JudgementTelegraph = 1.7 },
		Quills = { Max = 1 },
	},
})

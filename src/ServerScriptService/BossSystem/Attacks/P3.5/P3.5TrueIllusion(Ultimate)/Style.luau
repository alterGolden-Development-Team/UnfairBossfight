local BASE = table.freeze({
	Cooldown = 90, CloneCount = 100, DialogueHold = 0.35,
	Dialogue = { "One hundred faces. One imagination.", "Try to keep up. TRUE ILLUSION!" },
	WindupStart = 0.45, WindupEnd = 0.18, GapStart = 0.55, GapEnd = 0.20,
	SpeedStart = 150, SpeedEnd = 230, Range = 340, CloneSpacing = 7,
	Suits = {
		Spade = { Symbol = "♠", Color = Color3.fromRGB(255, 168, 20), Count = 7, Spread = 10, Damage = 20, Radius = 3.5 },
		Ace = { Symbol = "♥", Color = Color3.fromRGB(255, 238, 70), Count = 5, Spread = 13, Damage = 26, Radius = 4.5 },
		Diamond = { Symbol = "♦", Color = Color3.fromRGB(255, 250, 175), Count = 7, Spread = 0, Damage = 17, Radius = 3, Interval = 0.05 },
		Club = { Symbol = "♣", Color = Color3.fromRGB(255, 214, 10), Count = 1, Spread = 0, Damage = 40, Radius = 11 },
	},
	Order = { "Spade", "Ace", "Diamond", "Club" },
	Gold = Color3.fromRGB(255, 218, 48), White = Color3.fromRGB(255, 247, 218), Shadow = Color3.fromRGB(38, 26, 4),

	 
	Mechanics = {
		LeadStart = 0.35, LeadEnd = 0.9,  
		ShuffleAfter = 8,  
		Homing = { Suit = "Ace", Turn = 2.4, Duration = 0.7 },  
		Hazard = { Suit = "Club", Duration = 2.6, Tick = 0.5, Damage = 5, Scale = 0.85 },  
		Crossfire = { Start = 0.3, Every = 3, Count = 3, Spread = 12, Damage = 16, Radius = 3, SpeedScale = 0.9 },  
	},

	 
	Launcher = { Scale = 0.92, Body = Color3.fromRGB(32, 28, 30), Trim = Color3.fromRGB(224, 170, 40), Grip = Color3.fromRGB(28, 20, 10) },

	 
	 
	Poses = {
		Ready = { RightShoulder = { 30, 0, 22 }, RightElbow = { 115, 0, 0 }, RightWrist = { -10, 0, 0 }, Waist = { 0, 10, 0 }, Neck = { 0, -8, 0 },
			LeftShoulder = { 20, 0, -62 }, LeftElbow = { 65, 0, 0 }, RightHip = { 0, 8, 3 }, LeftHip = { -6, -8, 0 } },
		Aim = { RightShoulder = { 92, -8, 24 }, RightElbow = { 0, 0, 0 }, RightWrist = { 0, 0, 0 }, Waist = { 0, 24, 0 }, Neck = { 0, -20, 0 },
			LeftShoulder = { 20, 0, -62 }, LeftElbow = { 65, 0, 0 }, LeftWrist = { 0, 0, -20 }, RightHip = { 0, 12, 4 }, LeftHip = { -8, -10, 0 }, LeftKnee = { 10, 0, 0 } },
		Recoil = { RightShoulder = { 106, -8, 24 }, RightElbow = { 20, 0, 0 }, RightWrist = { -8, 0, 0 }, Waist = { -6, 26, 0 }, Neck = { 4, -20, 0 },
			LeftShoulder = { 18, 0, -64 }, LeftElbow = { 65, 0, 0 }, LeftWrist = { 0, 0, -20 }, RightHip = { 0, 12, 4 }, LeftHip = { -8, -10, 0 }, LeftKnee = { 10, 0, 0 } },
		 
		Deal = { RightShoulder = { 30, 0, 22 }, RightElbow = { 115, 0, 0 }, Waist = { -8, 0, 0 }, Neck = { -18, 0, 0 },
			LeftShoulder = { 160, 0, -18 }, LeftElbow = { 10, 0, 0 }, RightHip = { 0, 8, 3 }, LeftHip = { -6, -8, 0 } },
		SkyShot = { RightShoulder = { 172, 0, 10 }, RightElbow = { 0, 0, 0 }, Waist = { -10, 6, 0 }, Neck = { -22, 0, 0 },
			LeftShoulder = { 20, 0, -62 }, LeftElbow = { 65, 0, 0 }, RightHip = { 0, 8, 3 }, LeftHip = { -6, -8, 0 } },
	},

	 
	Intro = { RevealTime = 0.45, TwirlTime = 0.7, CloneWave = 1.4, TitleHold = 0.35 },

	 
	FinaleDialogue = { "The hundredth face was always mine.", "ROYAL FLUSH!" },
	Finale = {
		Suit = "Spade",
		Ranks = { "10", "J", "Q", "K", "A" },
		Deal = { Interval = 0.18, Flight = 0.45, Height = 26, Radius = 17, CardHeight = 16, Settle = 0.48 },
		 
		 -- with separate gaps, slams spray cards, and the Ace beam leaves royal pillars along its path
		Prison = { Waves = 2, Count = 26, Radius = 30, OuterRadius = 48, OuterCount = 34, Gap = 3, Telegraph = 0.65, Speed = 120, Damage = 28, BurstRadius = 3.5, WaveGap = 0.25, Dive = 0.35 },
		 
		Slam = { Slams = 3, Telegraph = { 0.8, 0.7, 0.65, 0.6, 0.55, 0.5 }, Radius = 13, Damage = 50, Lead = 0.35, Fall = 0.14, Stuck = 0.18,
			Spray = { Count = 10, Speed = 90, Damage = 18, Radius = 3, Range = 70 } },
		 
		Ace = { Charge = 1.2, Lock = 0.3, Width = 7, Radius = 16, Damage = 90, Range = 480,
			Pillars = { Count = 5, Radius = 10, Damage = 45, Gap = 0.09 } },
	},

	 
	Fx = { Density = 1, Lights = true, Afterimage = true, Streak = true, GroundSigils = true, CloneAura = true, CloneFade = true },
})

 
return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = {  
		CloneCount = 130, SpeedEnd = 260, WindupEnd = 0.14, GapEnd = 0.15,
		Mechanics = { LeadStart = 0.6, LeadEnd = 1, ShuffleAfter = 4, Homing = { Turn = 3.2 }, Crossfire = { Every = 2, Count = 4 } },
	},
	Hardcore = { CloneCount = 80, Mechanics = { LeadStart = 0.25, LeadEnd = 0.7, Crossfire = { Every = 4 } } },
	NerfedHardcore = {  
		CloneCount = 60, SpeedEnd = 200, GapEnd = 0.3,
		Mechanics = { LeadStart = 0, LeadEnd = 0.4, Homing = { Turn = 1.4 }, Crossfire = { Every = 6, Count = 2 }, Hazard = { Duration = 1.5 } },
	},
})

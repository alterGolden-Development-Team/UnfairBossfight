 -- P5 Death Roar: the P4 Death Roars barrage as a Phase 5 normal attack. He plants himself in the middle of the arena and
 -- roars for 5 seconds while the yellow slash storm rages. Every TickEvery seconds the roar lands on everyone in the
 -- arena for TickFraction of their max HP unless they Deflect it. No finale, no title text.
return table.freeze({
	Name = "P5DeathRoar", Cooldown = 30,
	Invulnerable = true,  -- like the P4 roar: he can't be hurt or interrupted while he roars

	Intro = { Duration = 1.4, Raise = 0.5, FirstStreaks = 0.9 },  -- short wind-up, then the roar starts (scaled by the difficulty's Telegraph)
	Roar = {
		Duration = 5,        -- seconds of roaring, counted from the moment the roar ignites
		TickEvery = 1,       -- 5s / 1s = 5 ticks
		TickFraction = 0.2,  -- each tick that is not deflected takes 20% of max HP
		Deflect = "Tap",    -- "Hold" (keep E down through the tick) or "Tap" (press E just before each tick)
	},
	Recover = 0.6,

	 -- the slash storm (visual only; the damage is the tick)
	Storm = {
		StreakStart = 18, StreakEnd = 36, StreakSpan = { 0.7, 1.1 },
		FollowEvery = { 0.6, 0.4 }, FollowRadius = 6.5, FollowCrescents = { 3, 5 },
		RandomStart = 12, RandomEnd = 24, RandomGlint = 0.35, Crescents = { 10, 14 }, SwarmRadius = 12,
	},
	Poses = {
		Raise = { RightShoulder = { 165, 0, 15 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { 25, 0, -25 }, LeftElbow = { 30, 0, 0 },
			Neck = { -18, 0, 0 }, Waist = { -6, 0, 0 } },
		Command = { RightShoulder = { 95, 0, 25 }, RightElbow = { 8, 0, 0 }, LeftShoulder = { 10, 0, -12 }, LeftElbow = { 25, 0, 0 },
			Neck = { 4, 0, 0 }, Waist = { 0, -12, 0 } },
	},
})

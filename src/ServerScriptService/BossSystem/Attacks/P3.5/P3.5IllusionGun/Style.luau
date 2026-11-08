 -- P3.5 Illusion Gun: suit rounds come from P3.5TrueIllusion(Ultimate).Style.Suits; these are the gun's own numbers
local BASE = table.freeze({
	Cooldown = 13,
	Draw = 0.35,  -- the gun appears
	Aim = 0.3,  -- aim before each suit
	Gap = 0.3,  -- between suits
	Holster = 0.3,
	Speed = 170,
	Range = 300,
	Lead = 0.6,  -- share of the target's movement to lead
	 -- which single suit a cast fires: weights for Spade, Ace, Diamond and Club
	KindWeights = { 0.3, 0.25, 0.25, 0.2 },
	Spade = { Count = 9, Spread = 9 },
	Ace = { Count = 6, Spread = 13, Turn = 2.4, Homing = 0.7 },
	Diamond = { Count = 10, Interval = 0.05 },
	Club = { Count = 1, Hazard = 2.6, Tick = 0.5, TickDamage = 5, HazardScale = 0.85 },
})

return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = { KindWeights = { 0.2, 0.25, 0.25, 0.3 }, Speed = 190, Gap = 0.22 },
	Hardcore = { KindWeights = { 0.3, 0.25, 0.25, 0.2 } },
	NerfedHardcore = { KindWeights = { 0.35, 0.3, 0.25, 0.1 }, Speed = 150, Gap = 0.4 },
	Easy = { KindWeights = { 0.5, 0.3, 0.2, 0 }, Speed = 140, Gap = 0.5 },
})

local BASE = table.freeze({
	Cooldown = 10,

	 
	ModeWeights = table.freeze({ Regular = 1, DrawNear = 1, ErranticPhaser = 1 }),
	ModeNames = table.freeze({ Regular = "Regular", DrawNear = "Draw Near", ErranticPhaser = "Errantic Phaser" }),
	 
	Dashes = table.freeze({ Regular = 5, DrawNear = 3, ErranticPhaser = 4 }),

	Speed = 200,  
	FirstTelegraph = 0.28,  
	Telegraph = 0.14,  
	Pause = 0.08,  
	Recovery = 0.3,

	Damage = 28,  
	HitRadius = 5,
	HitHeight = 8,

	ArenaMargin = 8,
	RegularStarScale = 0.34,  
	DrawNearOvershoot = 9,  
	ErranticMin = 9,  
	ErranticMax = 17,  
	MinLeg = 6,

	AfterimageInterval = 0.035,
	AfterimageLife = 0.38,
})

 
return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = { Dashes = { Regular = 7, DrawNear = 4, ErranticPhaser = 6 }, FirstTelegraph = 0.2, Telegraph = 0.1, ModeWeights = { DrawNear = 2 } },
	Hardcore = { Telegraph = 0.18 },
	NerfedHardcore = { Dashes = { Regular = 4, DrawNear = 2, ErranticPhaser = 3 }, FirstTelegraph = 0.4, Telegraph = 0.24, ErranticMin = 12, ErranticMax = 20 },
})

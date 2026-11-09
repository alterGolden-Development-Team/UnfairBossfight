local BASE = table.freeze({
	Cooldown = 13,

	 
	LeapHeight = 20,
	LeapTime = 0.42,
	HangTime = 0.6,  
	DescendTime = 0.32,
	Recovery = 0.3,

	 
	OuterRadius = 60,  -- field centres ring the target this far out: neighbouring fields (radius FieldRadius)
	                   -- stay ~14 studs apart, so there is always a corridor out without touching one

	BombStagger = 0.07,  
	BombFlight = 0.95,  
	BombArc = 20,
	BombBlastRadius = 9,
	BombDamage = 18,

	 
	FieldRadius = 28,  
	FieldDuration = 7,
	FlowersPerField = 7,  
	FlowerScale = { 3.2, 4.2 },  
	FieldTick = 0.5,  
	FieldDamage = 10,
	FieldHeight = 6,  
})

 
return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = { FieldRadius = 30 },
	TrueHardcore = { FieldRadius = 28 },
	Hardcore = { FieldRadius = 27 },
	NerfedHardcore = { FieldRadius = 26 },
	Easy = { FieldRadius = 24 },
})

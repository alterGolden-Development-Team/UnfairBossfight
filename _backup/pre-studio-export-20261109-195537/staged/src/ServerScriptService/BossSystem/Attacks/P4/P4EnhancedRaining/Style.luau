local BASE = table.freeze({
 gold=Color3.fromRGB(255,215,25), bright=Color3.fromRGB(255,255,185),
 deep=Color3.fromRGB(205,142,12), white=Color3.fromRGB(255,255,238),
 Cooldown=16, Count=48, Interval=0.085, SummonDuration=0.7,
 NearMinRadius=6, NearMaxRadius=26, TargetEvery=3,
 ImpactRadius=7.5, WarningTime=0.65, SwordHeight=90, Damage=18,
})

 
return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = { Count = 70, Interval = 0.065, TargetEvery = 2, NearMaxRadius = 20, WarningTime = 0.5 },
	Hardcore = { Count = 40, TargetEvery = 3 },
	NerfedHardcore = { Count = 30, Interval = 0.1, TargetEvery = 4, WarningTime = 0.8 },
})

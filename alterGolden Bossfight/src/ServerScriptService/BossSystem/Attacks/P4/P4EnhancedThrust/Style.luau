local BASE = table.freeze({

	Cooldown=8, Windup=.16, DashDuration=.12, Range=160,
	Damage=80, HitRadius=6, HitHeight=8, Recovery=.12,
	Gold=Color3.fromRGB(255,210,25), White=Color3.fromRGB(255,255,190),

	Hot=Color3.fromRGB(255,110,25),

	Dash2Speed=1.25, Dash2HitRadius=1.15,

	SlashDamage=60, SlashRadius=24,

	SlashWindup=.08,

	SlashRise=4.5, SlashEcho=true,
})

 
return require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Variant(BASE, {
	Hellaven = { Windup = 0.1, SlashRadius = 30, SlashEcho = true },
	Hardcore = { Windup = 0.22 },
	NerfedHardcore = { Windup = 0.3, SlashRadius = 18, SlashEcho = false },
	Easy = { Windup = 0.34, SlashRadius = 16, SlashEcho = false },
})

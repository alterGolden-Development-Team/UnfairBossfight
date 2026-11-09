 -- Gravity Crush (Space mode; after Zarya's Graviton Surge): a singularity opens over his target and, for Delay seconds, sucks in
 -- everyone near it (SuckSpeed). Then it seizes everyone within Radius - i-frames or not, drags them spiralling into its centre and up to Lift studs over Pull seconds, holds
 -- them helpless for Float - HOLD E - then slams them into the ground (SlamDamage) with a shockwave.
return table.freeze({
	Name = "P5GravityCrush", Cooldown = 15,
	Tell = 0.4, Delay = 1.0, Radius = 30, SuckSpeed = 70, Pull = 1.1, Lift = 16, Float = 0.7, Slam = 0.12, SlamDamage = 85,
	WaveSpeed = 130, WaveRange = 40, WaveWidth = 5, WaveHeight = 4, WaveDamage = 25,
})

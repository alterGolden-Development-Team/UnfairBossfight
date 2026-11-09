 -- Great Wind: he gathers the air - everyone is snapped in close at once - and while it gathers two shockwaves roll out
 -- (jump them). Then it lets go: HOLD E as the gathered air blows, and keep holding through the wall it throws out
 -- (or dash through the wall).
return table.freeze({
	Name = "P5GreatWind", Cooldown = 13,
	 -- the pull is instant: everyone is placed PullDistance from him within PullTime and held there while it gathers
	Charge = 3, PullTime = 0.25, PullDistance = 13, PullRange = 720,
	 -- the small waves reach as far, and as fast, as the big wall
	Waves = { 1, 2 }, WaveSpeed = 140, WaveRange = 720, WaveDamage = 35,
	Fuse = 0.55, BlastRadius = 20, BlastDamage = 90,
	WallSpeed = 140, WallRange = 720, WallHeight = 16, WallDamage = 60,
})

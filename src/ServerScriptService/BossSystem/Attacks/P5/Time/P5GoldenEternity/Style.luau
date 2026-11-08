 -- Golden Eternity (Time mode; Phase 2's Golden Clock, far stronger). "Eternity." A great clock opens in the sky and
 -- time stops for StopTime seconds (TimeEffectController.StopTime: everyone frozen, only he moves). He blinks behind
 -- every player in turn, cuts the air and leaves a sphere of Blades hanging in the stopped time, all aimed at them.
 -- When time resumes every blade strikes at once - Hold Deflect turns them all away - and a shockwave rolls out of him.
return table.freeze({
	Name = "P5GoldenEternity", Cooldown = 22,
	Tell = 0.8, StopTime = 3.4, PerVictim = 0.55, Distance = 6,
	Blades = 10, BladeRadius = 9, BladeDamage = 14,
	WaveSpeed = 150, WaveRange = 120, WaveWidth = 6, WaveHeight = 4, WaveDamage = 35,
	Line = "Eternity.",
})

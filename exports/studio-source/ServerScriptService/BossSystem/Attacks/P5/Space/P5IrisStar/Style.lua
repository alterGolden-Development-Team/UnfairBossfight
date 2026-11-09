 -- Iris Star: the star radiates and blinds anyone near it (stronger the closer they are),
 -- then collapses and explodes. Only the pupil's shadow under the star is safe, so
 -- surviving means walking into the brightest light. Times are seconds after Windup.
return table.freeze({
	Name = "P5IrisStar",
	Cooldown = 24,
	Windup = 1.2,
	Height = 30,  -- star height above the boss
	EyeRadius = 10.5,
	ScreenRange = 100,

	RadianceTime = 6,  -- blinding light, no attacks
	BlindRange = 140,  -- blind starts at this distance from the star
	BlindInner = 12,  -- full strength inside this distance
	 -- its light burns: ticks every TickInterval, up to TickMax at BlindInner, fading to 0 at BlindRange
	TickInterval = 0.5,
	TickMax = 9,
	TickCurve = 1.5,
	SupernovaSlow = 0.3,
	SupernovaSlowSeconds = 2,

	CollapseTime = 2.4,
	PupilRadius = 10,
	BlastRadius = 190,
	BlastDamage = 70,

	Outro = 1.4,
	Sounds = table.freeze({
		Open = "rbxasset://sounds/electronicpingshort.wav",
		Boom = "rbxasset://sounds/impact_explosion_03.mp3",
	}),
})

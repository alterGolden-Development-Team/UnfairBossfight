 -- Night Tearer (ultimate, Normal Attack folder): he readies himself, then charges - a sphere of gold gathering in
 -- front of him (no lane is marked: the sphere shows where it will go) - and fires a huge beam, releasing a shockwave
 -- at the same moment. The beam takes LivesCost (777) lives: every life a player has. Get out of the lane, or dash through.
return table.freeze({
	Name = "P5NoonTearer", Cooldown = 22,  -- the Night Tearer, weakened: an ordinary attack
	Ready = 0.9, Charge = 4.5,
	 -- a really big beam: 306 studs across, its middle 40 studs up, out to the arena's far side
	BeamTime = 2.2, BeamRadius = 51,  -- 102 studs across
	 BeamHeight = 40, Range = 2000, Grow = 0.22,  -- Range 2000: map-wide (a part can't be longer than 2048); walls don't stop it, i-frames don't dodge it
	LivesCost = 2,
	WaveSpeed = 170, WaveRange = 140, WaveWidth = 7, WaveHeight = 4, WaveDamage = 45,
	Line = "Noon breaks. Burn in it.",
})

 -- Night Tearer (ultimate, Normal Attack folder): he readies himself, then charges - a sphere of gold gathering in
 -- front of him while the lane ahead is marked in red - and fires a huge beam down it, releasing a shockwave at the
 -- same moment. The beam takes LivesCost (777) lives: every life a player has. Get out of the lane, or dash through.
return table.freeze({
	Name = "P5NightTearer(Ultimate)", Cooldown = 70,
	Ready = 0.9, Charge = 3,
	 -- a really big beam: 52 studs across, its middle 20 studs up, out to the arena's far side
	BeamTime = 2.2, BeamRadius = 26, BeamHeight = 20, Range = 420, Grow = 0.22,
	LivesCost = 777,
	WaveSpeed = 170, WaveRange = 140, WaveWidth = 7, WaveHeight = 4, WaveDamage = 45,
	Line = "Night falls. Be torn with it.",
})

 -- Ultra Blue: a giant blue star gathers high in the sky over the middle of the map and hangs there (it does not follow
 -- him) while he goes on fighting. Now and then it fires a beam at someone, from any distance - rings pulse in toward the
 -- star first, and the beam comes on the last one: TAP E then. Then the star is thrown where you are going and goes off
 -- there: one big explosion - get clear of the circle the throw shows on the ground.
 -- It all runs in the background: he keeps moving and attacking the whole time.
return table.freeze({
	Name = "P5UltraBlue", Cooldown = 18,
	Rise = 1.4, SkyHeight = 150, OrbSize = 64,
	-- 2000: a beam part tops out at 2048 studs
	Beams = 5, Pulse = 0.75, BeamGap = 0.6, BeamWidth = 3, BeamRange = 2000, BeamDamage = 45,
	ThrowTell = 0.8, ThrowTime = 0.9, Predict = 0.4, CoreRadius = 45, CoreDamage = 90,
})

 -- Jump Kick: he crouches, leaps high toward his target, hangs a moment over where they are going (the ground
 -- lights up), then drops on it feet first - an explosion and a small shockwave. Move off the mark, then jump the wave.
return table.freeze({
	Name = "P5JumpKick", Cooldown = 8,
	Crouch = 0.3, Rise = 30, RiseTime = 0.35, Hang = 0.3, Predict = 0.35, KickTime = 0.2,
	Radius = 16, Damage = 80, WaveSpeed = 80, WaveRange = 40, WaveDamage = 30,
})

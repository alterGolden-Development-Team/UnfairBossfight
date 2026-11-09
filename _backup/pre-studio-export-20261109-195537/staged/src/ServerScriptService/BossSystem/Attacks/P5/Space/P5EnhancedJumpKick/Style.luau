 -- Enhanced Jump Kick: the Jump Kick, sharpened. He crouches, leaps, hangs over where you are going and drops on it feet
 -- first - but the mark on the ground is RED and small, the blast is much smaller (Radius 8 against the Jump Kick's 16), and
 -- the kick itself cannot be dodged by i-frames or soaked by defense: the dash, class invulnerability and defense do nothing
 -- against it. The only answer is not being under it. (Jump Kick: gold mark, big blast, normal hit.)
return table.freeze({
	Name = "P5EnhancedJumpKick", Cooldown = 10,
	Crouch = 0.3, Rise = 30, RiseTime = 0.35, Hang = 0.3, Predict = 0.35, KickTime = 0.2,
	Radius = 8, Damage = 85, WaveSpeed = 80, WaveRange = 26, WaveDamage = 22,
})

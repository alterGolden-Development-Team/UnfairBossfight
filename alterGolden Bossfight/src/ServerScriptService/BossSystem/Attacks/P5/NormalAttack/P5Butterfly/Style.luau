 -- Butterfly: he springs backward into the air, opens butterfly wings, takes aim, then dives in a
 -- straight line through the player's spot to just past it, hitting everyone along the way
return table.freeze({
	Name = "P5Butterfly", Cooldown = 6,
	 -- the thrust is near instant but short: he only starts it with someone close (NearRange)
	BackDistance = 14, JumpHeight = 11, JumpTime = 0.4, Hover = 0.3, DashTime = 0.06,
	NearRange = 26, ThrustRange = 40,
	Overshoot = 6, Lead = 0.15, HitRadius = 9, Damage = 70, BurstRadius = 12,
})

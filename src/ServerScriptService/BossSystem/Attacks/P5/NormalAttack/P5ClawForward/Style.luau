 -- Claw Forward: P4 Enhanced Ranged Slashes as a beast - every swing throws three parallel claw blades
 -- (camera-facing beams, rolled 45 degrees, VFXEngine P5Strikes.Claw), gold, big and fast. Those can be
 -- Tap Deflected. Then the finisher: one giant five-blade claw that can't be.
return table.freeze({
	Name = "P5ClawForward", Cooldown = 6,
	Windup = 0.35, Swings = 5, Gap = 0.2,
	Speed = 420, Range = 300, Width = 42, Spread = 8, Roll = 45,
	HitHalfWidth = 16, HitHeight = 7, Damage = 20, Height = 1,
	 -- the finisher
	FinalWindup = 0.4, FinalWidth = 78, FinalSpread = 11, FinalCount = 5, FinalSpeed = 380,
	FinalHalfWidth = 30, FinalHeight = 10, FinalDamage = 45,
})

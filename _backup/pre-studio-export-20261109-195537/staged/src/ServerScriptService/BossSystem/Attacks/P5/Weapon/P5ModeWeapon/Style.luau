 -- the swing of the mode weapon (Combat/P5ModeWeapon) - only during a Phase 5 mode, in place of his normal attacks
return table.freeze({
	Name = "P5ModeWeapon", Cooldown = 1.2,
	Reach = 14, LungeTime = 0.14,  -- he closes in first when the target is farther than Reach
	 -- Space - Star Saber: two cuts, then a fan of stars
	SaberRadius = 15, SaberDamage = 20, SaberGap = 0.18,
	StarCount = 5, StarSpread = 12, StarSpeed = 150, StarRange = 55, StarDamage = 12,
	 -- Natural - Aurora Glaive: one wide sweep all around him but his back
	SweepWindup = 0.3, SweepRadius = 19, SweepHalfAngle = 150, SweepDamage = 26,
	 -- Time - Clock Hand: a chop down a line, then its echo a beat later
	ChopWindup = 0.28, ChopLength = 26, ChopHalfWidth = 3.5, ChopDamage = 28, EchoDelay = 0.55, EchoDamage = 20,
})

 -- Overclock (Time mode; Phase 2's Acceleration and Deceleration together, far stronger). The clock hands around him
 -- spin up: he runs fast for Fast seconds (TimeEffectController.AccelerateBoss: quicker steps, cooldowns and windups)
 -- while every player is slowed to half time for Slow seconds (ApplyDeceleration), then he fires Volleys of
 -- clock-hand shots, Shots in a fan at each of them (Tap Deflect).
return table.freeze({
	Name = "P5Overclock", Cooldown = 18,
	Tell = 0.6, Fast = 8, Slow = 5,
	Volleys = 3, VolleyGap = 0.22, Shots = 3, Spread = 9, ShotSpeed = 240, ShotRange = 140, ShotRadius = 2.6, ShotDamage = 18,
	Line = "Your seconds are mine now.",
})

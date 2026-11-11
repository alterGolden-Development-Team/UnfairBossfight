 -- Assassination: he blinks behind a random player, a short draw, then cuts with black slashes that ring him.
 -- Each cast makes 0, 1 or 2 feints first (MaxFeints): a violet draw and a harmless false cut, then he blinks
 -- behind them again. With no feint he goes straight to the red draw, the real one.
return table.freeze({
	Name = "P5Assassination", Cooldown = 7,
	Distance = 5, Windup = 0.5, FeintWindup = 0.22, FeintGap = 0.08, MaxFeints = 2,  -- always behind them
	LivesCost = 2,  -- a cut that lands takes two lives
	 -- the cuts ring him (VFXEngine P5Strikes.BlackSlash), so they hit all the way around
	Slashes = 3, SlashGap = 0.1, Radius = 13, HalfAngle = 180, Damage = 26,
})

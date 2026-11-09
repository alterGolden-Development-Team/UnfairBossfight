 -- Chronobreak (Time mode; after Ekko's Chronobreak): he leaves a golden afterimage where he stands, then blinks in
 -- and slashes Slashes times; his path is remembered. Then he breaks time - HOLD E - and rewinds along everything he
 -- just did in RewindTime, cutting all on the path, back into his afterimage, where the moment explodes (BurstRadius).
return table.freeze({
	Name = "P5Chronobreak", Cooldown = 15,
	Slashes = 3, SlashGap = 0.32, SlashRadius = 12, SlashHalfAngle = 130, SlashDamage = 40,
	RewindTime = 0.45, PathRadius = 6, PathDamage = 35, BurstRadius = 20, BurstDamage = 90,
})

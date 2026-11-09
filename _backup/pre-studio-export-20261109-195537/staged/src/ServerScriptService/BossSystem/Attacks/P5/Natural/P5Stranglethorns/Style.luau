 -- Stranglethorns (Natural mode; after Zyra's Stranglethorns): he drives a hand down and areas of golden thorns break
 -- out of the ground at random spots, instantly - Areas of them over Duration seconds, every other one on a player.
 -- Each springs up in Grow seconds (nearly at once) and snaps: SnapDamage to anyone inside and a lift into the air.
return table.freeze({
	Name = "P5Stranglethorns", Cooldown = 14,
	Tell = 0.45,
	Areas = 9, Duration = 3.2, Grow = 0.18, Radius = 16, SnapDamage = 55, SnapLift = 26,
	Near = 10, Wide = 85,  -- how far a thicket may land from the player it is aimed at / from the arena's middle
})

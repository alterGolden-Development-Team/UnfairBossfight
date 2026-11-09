 -- Fire Ring: he winds up a massive circular cut - the sound rising with it - then spins it all the way round him:
 -- everyone inside Radius is cut, and the cut leaves a ring of golden fire burning along its edge for FireTime
 -- seconds; anyone in its flames (FireBand either side of the ring) burns for FireDamage every FireTick.
 -- He only opens with it when his target is within UseRange of him.
return table.freeze({
	Name = "P5FireRing", Cooldown = 10,
	Windup = 0.9, Radius = 56, Damage = 70, Height = 12, UseRange = 32,
	FireTime = 6, FireBand = 5, FireTick = 0.1, FireDamage = 50,  -- the flames burn like the arena's ruin fires
})

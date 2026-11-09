 -- Ultra Red: a red star swells over the middle of the arena and goes off (get out of its circle). Then it turns, and
 -- straight lines of burning tiles turn with it right across the whole map - each line broken by a gap in the middle,
 -- close under the star, which is the only clear ground. It stops, swells and goes off a second time, wider: run out
 -- of the middle, or HOLD E as it blows. It all runs in the background: he keeps moving and attacking the whole time.
return table.freeze({
	Name = "P5UltraRed", Cooldown = 18,
	Tell = 0.3, BlastRadius = 58, BlastDamage = 90,
	-- OrbHeight 0: the orb is a half sphere sitting on the ground (its lower half is in the floor)
	OrbHeight = 0, OrbScale = 2.2,
	OrbSize = 44,
	Lines = 2, HalfWidth = 7, Inner = 16, Outer = 420, Spin = 0.75, Warm = 0.9, SpinTime = 6, Tick = 0.25, TileDamage = 22,
	StopTell = 0.4, FinalRadius = 72, FinalDamage = 120,
})

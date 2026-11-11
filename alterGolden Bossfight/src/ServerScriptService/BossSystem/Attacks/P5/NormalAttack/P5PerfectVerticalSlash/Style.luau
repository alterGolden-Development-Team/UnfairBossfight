 -- Perfect Vertical Slash: he stops dead and holds his blade high, perfectly still, for Stance seconds - then one huge
 -- vertical slash, Height studs tall, rips down the ground at the player at Speed (it crosses the arena in a blink).
 -- Hold Deflect or take Damage (150); a deflect throws you DeflectPush studs a second off to the side, out of its line.
 -- Then the fire follows it: bursts of flame erupt one after another down the slash's line, BurstSpeed studs a second
 -- (like Phase 4's Rift Column, without the columns) - each hits for BurstDamage as it bursts and leaves a circle of
 -- fire BurstRadius across that burns for FlameTime (FlameDamage every FlameTick, the arena's fire damage).
return table.freeze({
	Name = "P5PerfectVerticalSlash", Cooldown = 10,
	Stance = 1.2, Speed = 650, Range = 720, HalfWidth = 14, Height = 150, Damage = 150, DeflectPush = 75,  -- it runs on to the map's edge
	BurstFirst = 16, BurstGap = 26, BurstSpeed = 150, BurstRadius = 16, BurstHeight = 14, BurstDamage = 40, FireRange = 340,
	FlameTime = 5, FlameTick = 0.1, FlameDamage = 50,
})

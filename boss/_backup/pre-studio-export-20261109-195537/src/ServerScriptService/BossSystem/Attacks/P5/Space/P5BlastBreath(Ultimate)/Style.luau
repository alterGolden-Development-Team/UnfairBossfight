 -- Blast Breath (Space's last stand - once, right after his Space shield breaks): he goes to the middle, a great
 -- sigil burns in front of him, then he breathes fire - a widening cone that turns after his target, slower than you
 -- can run, so keep circling him. All the while shockwaves roll out from him: a wall (HOLD E or dash through it), then
 -- a ground wave (jump it), then a wall, then a ground wave...
return table.freeze({
	Name = "P5BlastBreath(Ultimate)", Cooldown = 40,
	Line = "You broke my stars? Then I'll breathe you a new sun.",
	Sigil = 2.4, Breath = 8, Turn = 0.5, Range = 600, Base = 14, Spread = 15, Tick = 0.15, TickDamage = 16,  -- the whole map, and wide
	WaveEvery = 1.1, WaveRange = 720, WallSpeed = 120, WallHeight = 16, WallDamage = 50, GroundSpeed = 120, GroundDamage = 40,
})

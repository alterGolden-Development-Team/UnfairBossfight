 -- Plasma Ball: he launches the balls one at a time. Before each, an arrow on the floor shows its line (a couple at
 -- players, the rest anywhere); then the golden plasma ball goes, swelling the whole way - big to start, enormous by
 -- the far side of the map. They roll on while he keeps fighting.
return table.freeze({
	Name = "P5PlasmaBall", Cooldown = 11,
	Balls = 8, Aimed = 3, Tell = 0.12, Every = 0.08, Speed = 95, Range = 420, Size0 = 6, Size1 = 48, Height = 4,
	TickDamage = 8, Tick = 0.15,
})

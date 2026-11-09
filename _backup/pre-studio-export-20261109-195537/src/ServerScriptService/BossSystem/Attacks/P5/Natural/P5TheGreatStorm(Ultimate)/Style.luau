 -- The Great Storm (Natural's last stand - once, right after his Natural shield breaks): he rises over the middle
 -- of the arena and a storm closes over the whole map; for fifteen seconds lightning comes down everywhere (he is far up in the sky, out of sight; the strikes leave no marks on the ground), most of
 -- it on and around you (each strike's circle shows first). Then HE becomes a golden star up there and collapses
 -- onto the middle of the arena, and the wall it throws out kills whoever it touches: HOLD E as it reaches you, or
 -- dash through it.
return table.freeze({
	Name = "P5TheGreatStorm(Ultimate)", Cooldown = 45,
	Line = "Kneel. The heavens answer to me now.",
		-- Height 450: he flies far up out of sight and only the storm is left; the star then falls all that way
	Rise = 2, Height = 450, Storm = 15,
	Bolts = 110, Tell = 0.55, Radius = 7, Damage = 40, Near = 0.7, Predict = 0.4, Spread = 10,
	ArenaRadius = 150, Become = 0.9, StarFall = 1.7, StarRadius = 30, WallSpeed = 210, WallRange = 720, WallHeight = 40, Lives = 1,
})

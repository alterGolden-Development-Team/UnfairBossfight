 -- Judgement Zone: he points, and two golden zones open on every player and hunt them across the floor - fast
 -- (Speed), aiming Lead seconds ahead of where they are running and circling them (Orbit) from opposite sides - with
 -- their Timer counting down over them. At zero they stop dead, turn red for Flash seconds and explode: Damage to anyone
 -- still inside. The zones hunt on their own (a background cast), so he keeps fighting.
return table.freeze({
	Name = "P5JudgementZone", Cooldown = 15,
	Tell = 0.5, Radius = 36, Speed = 34, Timer = 5, Flash = 0.6, Damage = 95,
	PerPlayer = 2, Lead = 0.55, Orbit = 12, OrbitSpeed = 1.5,
})

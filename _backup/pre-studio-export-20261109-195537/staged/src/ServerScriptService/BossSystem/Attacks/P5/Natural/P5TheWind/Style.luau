 -- The Wind: a gale drags everyone in to him (no one can out-run it), then one vertical cut runs straight out along
 -- the way he faces. Step out of the lit lane, or TAP E as the cut reaches you.
return table.freeze({
	Name = "P5TheWind", Cooldown = 10,
	Pull = 0.25, PullTime = 0.2, PullDistance = 9, PullRange = 720,  -- the pull is instant: everyone is placed beside him within PullTime
	Tell = 0.5, Length = 170, HalfWidth = 7, Speed = 320, Damage = 85,
})

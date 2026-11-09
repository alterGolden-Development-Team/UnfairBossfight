 -- Double Golden-matter Beam: the Golden-matter Beam's charge, pull and full-circle sweeps, but two beams at once,
 -- pointing opposite ways (Spread 180) - each thinner and a little shorter, and they turn slower. (Attacks/Shared/P5MatterBeam)
return table.freeze({
	Name = "P5DoubleGolden-matterBeam", Label = "Double Golden-matter Beam", Cooldown = 14,
	Charge = 1.6, PullRange = 260, PullSpeed = 34, PullAccel = 1400,  -- the pull: gentler now, but it still holds until the beam is off
	Beams = 2, Spread = 180, Range = 62,  -- long reach
	Width = 3.4, Sweep = 360, SweepTime = 2.6, Pause = 0.4,
	Tick = 0.1, TickDamage = 15,  -- tick damage while a beam is on you
})

 -- Golden-matter Beam: he plants his feet and gathers golden matter in his palm, pulling everyone toward him for
 -- Charge seconds while a gold circle on the floor shows how far the beam reaches. Then the beam fires - Range studs, mid
 -- range - and sweeps a full circle clockwise round him, stops for Pause, and sweeps a full circle back the other way.
 -- Anyone it passes through takes Damage (once each way); TAP E as it reaches you, or be out of its reach.
 -- (Attacks/Shared/P5MatterBeam)
return table.freeze({
	Name = "P5Golden-matterBeam", Label = "Golden-matter Beam", Cooldown = 12,
	Charge = 1.6, PullRange = 260, PullSpeed = 34, PullAccel = 1400,  -- the pull: gentler now, but it still holds until the beam is off
	Beams = 1, Spread = 0, Range = 70,  -- long reach
	Width = 5, Sweep = 360, SweepTime = 1.8, Pause = 0.4,
	Tick = 0.1, TickDamage = 22,  -- tick damage while the beam is on you
})

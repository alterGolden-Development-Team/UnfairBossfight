 -- Distorted Counter: he raises a small gold spell circle and keeps it up for Stance seconds while he moves and
 -- attacks as usual. Hit him while it is up and he catches the blow (Attacks/Shared/BossDamageService,
 -- CounterStanceUntil), then answers with a piercing gold shot at whoever struck, out to mid range. If no one
 -- does, the circle fades.
return table.freeze({
	Name = "P5DistortedCounter", Cooldown = 10,
	Raise = 0.3, Stance = 4.5, ShotDelay = 0.12,
	ShotSpeed = 260, ShotRange = 70, ShotRadius = 3, ShotDamage = 55,
})

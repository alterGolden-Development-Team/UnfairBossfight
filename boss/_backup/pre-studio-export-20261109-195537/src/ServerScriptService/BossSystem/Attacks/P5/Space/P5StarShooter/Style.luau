 -- Star Shooter (Space): four 5-pointed stars gather round him and turn round him like a circle, each one spinning as it
 -- goes. Every Every seconds each star shoots a small star out of every one of its five points (twenty small stars a
 -- volley - read the gaps the turning points leave). After Volleys volleys the next one is the spam: a rapid burst of
 -- volleys, one after another. It runs in the background: he keeps moving and attacking the whole time.
 -- (Density adds stars, Telegraph stretches the gathering, Recovery the time between volleys, ProjectileSpeed the shots' speed.)
return table.freeze({
	Name = "P5StarShooter", Cooldown = 42,
	Stars = 4, Points = 5, Radius = 28, Height = 5, Reach = 6.5,
	 -- radians per second: the stars round him, and each star on its own axis
	Orbit = 1.9, Spin = -3.4,
	Tell = 0.9, Every = 2, Volleys = 9,
	ShotSpeed = 62, ShotRange = 1500,  -- ShotRange is only a cap: a shot flies until it hits a wall or the floor
	ShotRadius = 1.6, ShotDamage = 14,
	 -- the spam (the tenth shoot): SpamVolleys volleys SpamGap apart, smaller and quicker
	SpamVolleys = 8, SpamGap = 0.26, SpamSpeed = 76, SpamDamage = 9,
})

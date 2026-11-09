 -- Shotgun Blast: when his target is within UseRange he closes in, says a line, and a little white star glints in his
 -- eye - then a point-blank blast of fire and smoke out of his palm. The blast carries Range studs; the closer you
 -- are, the more it hurts (MaxDamage at his palm down to MinDamage at its edge).
return table.freeze({
	Name = "P5ShotgunBlast", Cooldown = 7,
	UseRange = 34, Approach = 9, Glint = 0.55, Range = 24, HalfAngle = 42, MaxDamage = 130, MinDamage = 30,
	Lines = { "Point blank.", "Too close.", "Don't blink.", "Hold still." },
})

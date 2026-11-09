 -- Hellavan Rampage: he throws his head back and roars - a red-gold blast of sound rolls off him - then sprints at his
 -- target, slashing wildly in front of him the whole way (a cut every SlashEvery; TAP E). Then he stops dead and locks
 -- onto a straight path, lit on the floor for Lock seconds, and cuts down it in one flash (HOLD E). At the end of the
 -- path the ground detonates: a massive explosion (BlastRadius), then a tall wall of force rolling out that can't be
 -- jumped (HOLD E or dash through it), then Waves ordinary shockwaves after it (jump them).
return table.freeze({
	Name = "P5HellavanRampage", Cooldown = 24,
	Roar = 1.1, RoarPush = 14,
	SprintTime = 2.2, SprintSpeed = 52, SlashEvery = 0.12, SlashReach = 13, SlashAngle = 80, SlashDamage = 28,
	Lock = 0.8, PathLength = 90, PathWidth = 8, CutDamage = 85, Fuse = 0.35,
	BlastRadius = 22, BlastDamage = 110,
	WallSpeed = 230, WallRange = 720, WallHeight = 16, WallWidth = 8, WallDamage = 60,  -- the whole map, the fastest wave there is
	Waves = 3, WaveDelay = 0.7, WaveGap = 0.45, WaveSpeed = 130, WaveRange = 720, WaveDamage = 40,  -- after the wall, also map-wide
})

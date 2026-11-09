 -- Golden Eternity (Time mode) - DIO's "The World" knife barrage and Sakuya's "Killing Doll", in gold.
 -- "Eternity." A great clock opens in the sky and time stops for StopTime seconds (TimeEffectController.StopTime:
 -- everyone frozen, only he moves). In the stopped time he flashes all the way round the arena and golden knives are
 -- left hanging in the air behind him - FieldKnives of them ringing the whole map, every one turned on a player - then
 -- When time resumes:
 --   the Rain comes down (HOLD E, or get out from under it),
 --   then the ring round the map attacks ONE KNIFE AT A TIME, each aimed at where its player is the moment it leaves;
 --   some fly fast, some slow: keep moving.
 -- (Difficulty Density scales the counts, ProjectileSpeed the flight times, Recovery the spacing.)
return table.freeze({
	Name = "P5GoldenEternity", Cooldown = 24,
	Tell = 0.8, StopTime = 3.6, Sweep = 2, Blinks = 4, PerVictim = 0.45, Distance = 7,
	FieldKnives = 190, Volleys = 6, VolleyStart = 1.3, Reach = 5,
	 -- the ring's knives leave ONE BY ONE (KnifeGap apart, in a random order), each with its own flight time: FastChance of
	 -- them are quick (FlightFast..FlightMid seconds), the rest slow (FlightMid..FlightSlow)
	KnifeGap = 0.04, KnifeDamage = 6, FastChance = 0.5, FlightFast = 0.28, FlightMid = 0.6, FlightSlow = 1.5,
	MapInset = 0.92,  -- the map ring's size, as a fraction of the arena's (workspace ArenaWidth x ArenaDepth)
	Rain = { Kind = "Dome", Count = 36, Radius = 16, Deflect = "Hold", Damage = 45, At = 0.8, Flight = 0.25 },
	Line = "Eternity.",
})

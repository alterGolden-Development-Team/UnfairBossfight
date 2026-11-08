 -- Golden Pierce: only right after an Upper Cut lands (P5UpperCut arms it; EncounterConfig.Phase5Combos chains it):
 -- a gold spell circle forms in front of him with smaller circles around it; each small one fires a laser beam at
 -- the player he launched, one after another (VFXEngine P5Strikes.PierceBeam), then the big circle fires a wide one.
 -- A player takes at most one tick per Tick however many beams cross them.
return table.freeze({
	Name = "P5GoldenPierce", Cooldown = 5,
	Form = 0.45, Lead = 0.1,
	Beams = 5, Ring = 4.5, Stagger = 0.09, BeamTime = 0.7, Radius = 2.6, TickDamage = 10,
	FinalTime = 0.9, FinalRadius = 4.4, FinalDamage = 14,
	Tick = 0.1, Range = 110,
})

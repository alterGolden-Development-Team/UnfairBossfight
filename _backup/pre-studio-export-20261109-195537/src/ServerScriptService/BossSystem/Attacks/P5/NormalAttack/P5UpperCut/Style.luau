 -- Upper Cut: 2-4 times in a row he blinks behind a random player, coils for a moment (Windup), then rips an
 -- uppercut slash up through where they stood (90 damage, launches them)
return table.freeze({
	Name = "P5UpperCut", Cooldown = 8,
	MinStrikes = 2, MaxStrikes = 4,
	Distance = 4.5, Reach = 3.5, Windup = 0.3, Gap = 0.18,
	Radius = 6.5, Height = 14, Damage = 90, Lift = 55,
	 -- a strike that lands may arm Golden Pierce for the player it launched (EncounterConfig.Phase5Combos)
	PierceChance = 0.5, PierceWindow = 2,
})

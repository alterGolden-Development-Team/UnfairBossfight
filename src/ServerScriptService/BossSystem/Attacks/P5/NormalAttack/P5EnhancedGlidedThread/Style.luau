 -- Enhanced Glided Thread (Normal Attack): Threads Gilded Threads (P1.5GildedThread's ricocheting gold line) are summoned in a
 -- ring round him, a glint opening at each point, and then every one shoots at a player, one after another, and bounces off
 -- the walls leaving its burning line behind. Keep moving and don't stand on a line.
 -- Scaling: Threads x the difficulty's Density (the Enraged Gate's 1.25 included), Tell x Telegraph, Stagger x Recovery,
 -- damage through Encounter.Damage (the difficulty's Damage, the Gate's 1.3) on top of DamageScale.
return table.freeze({
	Name = "P5EnhancedGlidedThread", Cooldown = 11,
	Threads = 7, Ring = 13, Tell = 0.9, Stagger = 0.12,
	 -- the thread's own defaults last 30s of travel and 8s of line: far too long for seven at once
	Lifetime = 7, SegmentLifetime = 5, SpeedScale = 1.1,
	 -- Phase 5 players have ten times the health the Phase 1.5 thread was tuned for
	DamageScale = 4,
})

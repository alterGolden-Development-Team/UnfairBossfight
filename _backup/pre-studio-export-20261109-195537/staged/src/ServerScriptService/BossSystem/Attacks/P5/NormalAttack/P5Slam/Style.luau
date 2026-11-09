 -- Slam: he raises his left arm high while gold gathers in the hand, then slams it into the ground in front of him:
 -- giant gold spikes burst out of the impact and a fast shockwave races out along the floor (jump it).
return table.freeze({
	Name = "P5Slam", UseRange = 36,  -- he only slams with someone close
	 Cooldown = 8,
	Windup = 0.5, Reach = 7,
	SpikeRadius = 16, SpikeDamage = 60, SpikeTall = 1.4, SpikeCount = 10, SpikeHeight = 24,
	WaveSpeed = 150, WaveRange = 100, WaveWidth = 6, WaveHeight = 4, WaveDamage = 35,
})

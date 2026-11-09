 -- Wild Hunt (ultimate, Normal Attack folder): two lunges there and back, then he slices the air relentlessly
 -- and every cut flies as a claw (Tap Deflect), then drags himself along the ground into a ferocious bite and a
 -- piercing shot (Hold Deflect), stops in an explosion (shockwave and spikes), and ends on the Death Scythe -
 -- pulled out with no warning, straight to GOODBYE (the scythe's Quick mode). The first Wild Hunt of a
 -- fight burns the world outside the arena once the scythe is done (Encounter/ArenaRuin).
return table.freeze({
	Name = "P5WildHunt(Ultimate)", Cooldown = 60,
	 -- every attack of the hunt begins with a blink next to the target: how far from them he lands
	BlinkDistance = 12, LungeFrom = 18, SliceFrom = 13, BurstFrom = 8,
	LungeWindup = 0.35, LungeTime = 0.2,  -- each lunge is Tap-deflectable; the burst is Hold-deflectable
	BurstWindup = 0.75, LungeOvershoot = 10, LungeRadius = 6, LungeDamage = 35, LungePause = 0.15,
	Slices = 12, SliceGap = 0.1, SliceSpeed = 420, SliceRange = 220, SliceWidth = 42, SliceSpread = 7,
	SliceDamage = 14, SliceHalfWidth = 10, SliceHeight = 6,
	DragDistance = 30, DragTime = 0.6, BiteRadius = 11, BiteHalfAngle = 70, BiteDamage = 50,
	PierceSpeed = 320, PierceRange = 90, PierceRadius = 3.5, PierceDamage = 45,
	BurstRadius = 26, BurstDamage = 40, BurstPause = 0.5,
	 -- the burst also sends a shockwave along the floor and a field of gold spikes up around him
	WaveSpeed = 150, WaveRange = 90, WaveDamage = 30, SpikeRadius = 18, SpikeDamage = 40,
	RuinLine = "Let it all burn. Only this ring of gold is left for you.",
})

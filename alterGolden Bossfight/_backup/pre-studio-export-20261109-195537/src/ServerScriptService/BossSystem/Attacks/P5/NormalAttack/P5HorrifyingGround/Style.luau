 -- Horrifying Ground: he drives his sword into the ground. Around his target, Circles warning circles light up in a
 -- ring; then gold spikes burst out of every one at once - each circle its own size and spike style - and a
 -- shockwave runs out across the ground as they rise: jump right when the spikes come up.
return table.freeze({
	Name = "P5HorrifyingGround", Cooldown = 9,
	Windup = 0.4, Warn = 0.8,
	Circles = 10, RingRadius = 16, CircleMin = 4, CircleMax = 6.5,
	SpikeDamage = 55, SpikeHeight = 26,
	WaveSpeed = 90, WaveRange = 26, WaveWidth = 3, WaveHeight = 4, WaveDamage = 50,
	Styles = { "crown", "needle", "ring", "scatter", "fan", "twin" },
})

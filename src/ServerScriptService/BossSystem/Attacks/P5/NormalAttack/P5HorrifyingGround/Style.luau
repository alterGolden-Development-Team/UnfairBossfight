 -- Horrifying Ground: he drives his sword into the ground. Around his target, Circles big warning circles light up in
 -- a ring, each a gold field with a crimson ring closing on its edge like the Flower Field's; then gold spikes burst out of every one at once - each circle its own size and spike style - and a
 -- shockwave runs out across the ground as they rise: jump right when the spikes come up. A wider ring of OuterCircles
 -- fields bursts with them.
return table.freeze({
	Name = "P5HorrifyingGround", Cooldown = 9,
	Windup = 0.4, Warn = 0.8,
	Circles = 10, RingRadius = 40, CircleMin = 10, CircleMax = 13, Spikes = { 18, 26 },  -- spikes in every circle
	SpikeScale = 1.5, Tall = { 2, 3.2 },  -- each spike half again as thick, two to three times as tall
	OuterCircles = 0, OuterRadius = 64, OuterSpikes = { 8, 12 },  -- (a second, wider ring: off)
	SpikeDamage = 55, SpikeHeight = 36,
	WaveSpeed = 110, WaveRange = 34, WaveWidth = 3, WaveHeight = 4, WaveDamage = 50,
	Styles = { "crown", "needle", "ring", "scatter", "fan", "twin" },
})

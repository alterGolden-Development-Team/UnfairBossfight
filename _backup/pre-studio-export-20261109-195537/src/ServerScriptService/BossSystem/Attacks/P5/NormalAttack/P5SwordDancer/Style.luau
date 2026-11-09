 -- Sword Dancer: a ring of gold swords forms round his target, every point aimed at them; then they launch, each
 -- flying straight through the spot it was aimed at. Move off the spot before they go. No warning cue: the rings
 -- appear farther out (Radius 46), and after the swords are done he summons another ring, up to Summons rings in all.
return table.freeze({
	Name = "P5SwordDancer", Cooldown = 10,
	Swords = 16, Radius = 46, Height = 4, Summons = 3, RoundGap = 0.35, Aim = 1.1, Stagger = 0.03, Speed = 170, Width = 3.5, Damage = 28, MaxHits = 3,
})

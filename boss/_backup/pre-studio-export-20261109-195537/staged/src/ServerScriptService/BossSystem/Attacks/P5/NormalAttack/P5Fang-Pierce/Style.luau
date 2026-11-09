 -- Fang-Pierce (used up close): he flashes yellow, teleports beside his target and cuts a cross (TAP E), backdashes
 -- with a kick - to the side opposite the way they are walking (walking right, he goes left) - then lunges through
 -- them, his blade scraping the ground, and lunges back slashing all round. Bait the backdash to stagger him.
return table.freeze({
	Name = "P5Fang-Pierce", Cooldown = 10, UseRange = 34,
	Flash = 0.4, CrossLead = 0.3, CrossReach = 14, CrossDamage = 50,
	Back = 16, BackTime = 0.18, KickReach = 8, KickDamage = 30,
	Prepare = 0.45, Lunge = 44, LungeTime = 0.18, LungeWidth = 5, LungeDamage = 55,
	Ring = 6, RingEvery = 0.07, RingRadius = 14, RingDamage = 15,
})

 -- Time Bomb (Time mode; after Zilean's Time Bomb): he points, and a ticking golden clock bomb fastens over every
 -- player, its blast radius drawn on the ground around them and the ticking speeding up. After Fuse seconds every bomb
 -- goes off - HOLD E - hitting everyone within Radius; a blast that also catches another bomb's holder hits harder
 -- (Chain per extra bomb), so spread out.
return table.freeze({
	Name = "P5TimeBomb", Cooldown = 14,
	Tell = 0.5, Fuse = 3.5, Radius = 14, Damage = 60, Chain = 0.5, Lift = 22,
})

 -- Nullified Zone: he slams his palm down and a golden barrier closes round his target - a ring wall Radius studs
 -- across and WallHeight tall: a solid wall (invisible collision panels under the gold) that nobody can walk, dash or
 -- jump through, in or out, for Duration seconds, while he goes on attacking: it runs in the background.
return table.freeze({
	Name = "P5NullifiedZone", Cooldown = 32,
	Tell = 0.6, Radius = 40, WallHeight = 26, Duration = 15, Panels = 64,
})

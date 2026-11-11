local script = script.Parent
local BossSystem = script:FindFirstAncestor("BossSystem")
return function(actor)
	return require(BossSystem.Mechanics.Time.GoldenHourAttacks).Factory(actor, "FrozenGoldenLances")
end

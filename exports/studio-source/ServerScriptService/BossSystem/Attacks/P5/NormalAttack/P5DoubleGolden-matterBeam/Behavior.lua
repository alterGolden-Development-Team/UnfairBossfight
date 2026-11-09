local B = script:FindFirstAncestor("BossSystem")
return function(actor)
	return require(B.Attacks.Shared.P5MatterBeam)(actor, require(script.Parent.Style))
end

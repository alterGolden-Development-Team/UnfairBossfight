local BossSystem = script:FindFirstAncestor("BossSystem")
return function(actor)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local api = { IsPassive = true }
	function api.Apply(character, actualDamage)
		if
			type(actualDamage) ~= "number"
			or actualDamage ~= actualDamage
			or actualDamage <= 0
			or actualDamage == math.huge
			or not actor.Parent
			or actor:GetAttribute("IsGoldenClone")
			or actor:GetAttribute("EncounterEnded")
			or math.floor(actor:GetAttribute("Phase") or 1) ~= 3
		then
			return 0
		end
		local h = actor:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 then
			return 0
		end
		return Status.ApplyGoldenMark(character, actor)
	end
	function api.Reset()
		Status.ClearGoldenMarksFor(actor)
	end
	api.Dispose = api.Reset
	return api
end

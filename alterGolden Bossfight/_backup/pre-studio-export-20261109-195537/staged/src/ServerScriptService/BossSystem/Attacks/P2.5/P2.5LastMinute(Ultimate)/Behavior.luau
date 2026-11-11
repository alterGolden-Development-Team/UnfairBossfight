local script = script.Parent
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Controller = require(BossSystem.Phases.Phase25Controller)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local api = { Duration = Config.LastMinuteDuration, TriggerOnly = true }
	function api.CanUse()
		local h = actor:FindFirstChildOfClass("Humanoid")
		local shield = actor:GetAttribute("Shield") or 0
		return actor.Parent ~= nil
			and h ~= nil
			and h.Health > 0
			and not actor:GetAttribute("EncounterEnded")
			and actor:GetAttribute("Phase") == 2.5
			and shield > 0
			and shield <= Config.LastMinuteShieldGate
			and not actor:GetAttribute("LastMinuteUsed")
			and not actor:GetAttribute("LastMinuteActive")
	end
	function api.Combo()
		return api.CanUse() and Controller.BeginLastMinute(actor) or false
	end
	function api.Dispose() end
	return api
end

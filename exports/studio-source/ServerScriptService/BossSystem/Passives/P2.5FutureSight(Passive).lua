local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Controller = require(BossSystem.Phases.Phase25Controller)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	return {
		IsPassive = true,
		Cooldown = Config.FutureSightCooldown,
		Tick = function()
			return Controller.ActivateFutureSight(actor)
		end,
		Reset = function()
			actor:SetAttribute("FutureSightCharges", 0)
			actor:SetAttribute("FutureSightUntil", 0)
		end,
	}
end

local script = script.Parent
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local Reality = require(BossSystem.Mechanics.Reality.RealityController)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local api = { Cooldown = Config.IllusionCooldown }
	function api.CanUse(target)
		return core.Active() and Reality.CanIllusion(actor, target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, "P3Illusion", function()
			core.PoseAngles({ RightShoulder = { 70, 0, -35 } }, 0.12)
			actor:SetAttribute("AttackState", "Illusion: gilded mirrored portal")
			return Reality.Illusion(actor, target)
		end)
	end
	return api
end

local script = script.Parent
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Controller = require(BossSystem.Phases.Phase25Controller)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local api = { Cooldown = Config.FalseFutureCooldown }
	 
	local WINDUP = 0.26
	function api.CanUse(character)
		return actor:GetAttribute("Phase") == 2.5
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and (actor:GetAttribute("FalseFutureCharges") or 0) <= 0
			and core.Active()
			and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P2.5FalseFuture", function()
			core.PoseAngles({ RightShoulder = { 90, 0, -10 }, LeftShoulder = { 35, 0, 15 } }, 0.12)
			actor:SetAttribute("AttackState", "False Future: predictions corrupted")
			Controller.PlayFalseFutureWindup(actor, WINDUP)
			if not core.WaitFor(WINDUP) then
				return false
			end
			return Controller.ArmFalseFuture(actor)
		end)
	end
	return api
end

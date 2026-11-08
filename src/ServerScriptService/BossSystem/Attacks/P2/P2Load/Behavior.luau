local script = script.Parent
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local Snapshots = require(BossSystem.Mechanics.Time.TimeSnapshotService)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local api = { Cooldown = Config.TimeLoadCooldown or 10 }
	function api.CanUse(character)
		local phase = actor:GetAttribute("Phase")
		return (phase == 2 or phase == 2.5)
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and core.Active()
			and core.Alive(character)
			and Snapshots.Has(actor)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P2Load", function()
			actor:SetAttribute("AttackState", "Load: returning to the saved moment")
			core.PoseAngles({ RightShoulder = { 90, 0, -10 }, RightElbow = { 35, 0, 0 } }, 0.12)
			if not core.WaitFor(Difficulty.Design("Load", "Channel", 0.25, actor)) then
				return false
			end
			return Snapshots.Load(actor)
		end)
	end
	return api
end

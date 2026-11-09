local script = script.Parent
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local Snapshots = require(BossSystem.Mechanics.Time.TimeSnapshotService)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local api = { Cooldown = Config.TimeSaveCooldown or 14 }
	function api.CanUse(character)
		local phase = actor:GetAttribute("Phase")
		return (phase == 2 or phase == 2.5)
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and core.Active()
			and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P2Save", function()
			actor:SetAttribute("AttackState", "Save: recording this moment")
			core.PoseAngles(
				{ LeftShoulder = { 85, -10, -20 }, LeftElbow = { 15, 0, 0 }, RightShoulder = { 25, 0, 10 } },
				0.12
			)
			if not core.WaitFor(Difficulty.Design("Save", "Channel", 0.2, actor)) then
				return false
			end
			return Snapshots.Save(actor)
		end)
	end
	return api
end

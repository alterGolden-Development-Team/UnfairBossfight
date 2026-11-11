local script = script.Parent
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local Reality = require(BossSystem.Mechanics.Reality.RealityController)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local api = { Cooldown = Config.ThiefCooldown }
	function api.CanUse(target)
		return math.floor(actor:GetAttribute("Phase") or 1) == 3 and core.Active() and Reality.AliveTarget(actor, target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, "P3Thief", function()
			core.PoseAngles({ RightShoulder = { 70, 0, -35 } }, 0.12)
			if not core.WaitFor(Difficulty.Design("Thief", "Windup", 0.2, actor)) then
				return false
			end
			local affected = 0
			 
			local victims = Difficulty.Design("Thief", "AllTargets", true, actor) and core.Characters() or { target }
			 
			local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
			local duration = Config.ThiefDuration or 8
			for _, character in ipairs(victims) do
				if character and character.Parent and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").Health > 0 then
					local key = ({ "F", "C", "V" })[math.random(1, 3)]
					local untilAt = workspace:GetServerTimeNow() + duration
					character:SetAttribute("ClassSealed_" .. key, untilAt)
					character:SetAttribute("ClassStatus_SkillStolen", untilAt)
					character:SetAttribute("ClassStatusText_SkillStolen", key)
					task.delay(duration, function()
						if character.Parent and (character:GetAttribute("ClassStatus_SkillStolen") or 0) <= workspace:GetServerTimeNow() + 0.05 then
							character:SetAttribute("ClassStatus_SkillStolen", nil)
							character:SetAttribute("ClassStatusText_SkillStolen", nil)
						end
					end)
					affected += 1
				end
			end
			actor:SetAttribute("LastThiefTargetCount", affected)
			return affected > 0
		end)
	end
	return api
end

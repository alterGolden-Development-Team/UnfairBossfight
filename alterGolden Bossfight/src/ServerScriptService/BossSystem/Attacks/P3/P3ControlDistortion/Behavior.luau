local script = script.Parent
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local Reality = require(BossSystem.Mechanics.Reality.RealityController)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local api = { Cooldown = Config.ControlDistortionCooldown or 24 }
	local function targetFor(target)
		if Reality.AliveTarget(actor, target) then
			return target
		end
		for _, character in ipairs(core.Characters()) do
			if Reality.AliveTarget(actor, character) then
				return character
			end
		end
	end
	function api.CanUse(target)
		return math.floor(actor:GetAttribute("Phase") or 1) == 3 and core.Active() and targetFor(target) ~= nil
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		target = targetFor(target)
		return core.Perform(target, "P3ControlDistortion", function()
			core.Face(target)
			core.PoseAngles(
				{ RightShoulder = { 70, 0, -35 }, LeftShoulder = { 55, 0, 35 }, Waist = { -6, 0, 0 } },
				0.15
			)
			actor:SetAttribute("AttackState", "Control Distortion: reality bends")
			Audio.Emit(actor, "TeleportWarp", core.Root, { VolumeScale = 0.55 })
			if not core.WaitFor(math.clamp(Config.ControlDistortionWarning or 0.45, 0.3, 1)) then
				return false
			end
			local affected = 0
			for _, character in ipairs(core.Characters()) do
				if Reality.ControlDistortion(actor, character) then
					affected += 1
				end
			end
			actor:SetAttribute("LastControlDistortionTargetCount", affected)
			actor:SetAttribute("ControlDistortionCasts", (actor:GetAttribute("ControlDistortionCasts") or 0) + 1)
			return affected > 0
		end)
	end
	return api
end

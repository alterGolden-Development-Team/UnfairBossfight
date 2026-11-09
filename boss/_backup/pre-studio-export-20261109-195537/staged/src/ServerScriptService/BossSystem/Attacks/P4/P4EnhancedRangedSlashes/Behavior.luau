local script = script.Parent
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local core = Registry.For(actor, "P1CombatCore")
	local ranged = Registry.For(actor, "P1RangedSlashes")
	local api = { Cooldown = Config.P4EnhancedRangedCooldown or 12 }
	function api.CanUse(target)
		return math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4 and core.Active() and core.Alive(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, "P4EnhancedRangedSlashes", function()
			core.Face(target)
			core.Melee.Pose("Windup", 0.15)
			actor:SetAttribute("AttackState", "Enhanced Ranged Slashes: drawing")
			if not core.WaitFor(0.45) then
				return false
			end
			local count = math.clamp(math.floor(Config.P4EnhancedRangedWaveCount or 8), 4, 10)
			local gap = math.clamp(Config.P4EnhancedRangedInterval or 0.16, 0.12, 0.3)
			local speed = math.clamp(Config.P4EnhancedRangedSpeed or 225, 120, 260)
			local damage = math.clamp(Config.P4EnhancedRangedDamage or 10, 1, 50)
			local range = math.clamp(Config.P4EnhancedRangedRange or 180, 80, 220)
			local emitted = 0
			for index = 1, count do
				if math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4 or not core.Active() then
					return false
				end
				if not core.Alive(target) then
					target = core.Melee.GetTarget()
				end
				if not target then
					return false
				end
				core.Face(target)
				core.Melee.Pose(index % 2 == 1 and "Slash1" or "Slash2", 0.09)
				actor:SetAttribute("AttackState", "Enhanced Ranged Slashes: " .. index)
				local frame = core.Root.CFrame
					* CFrame.new(0, 1, -3)
					* CFrame.Angles(0, math.rad((index % 3 - 1) * 9), 0)
				local wave = ranged.FireWave(target, index % 2 + 1, nil, damage, { Frame = frame, Speed = speed })
				if not wave then
					return false
				end
				wave.range = range
				emitted += 1
				if index < count and not core.WaitFor(gap) then
					return false
				end
			end
			Audio.Emit(actor, "RangedX", core.Root)
			actor:SetAttribute(
				"EnhancedRangedSlashesReleased",
				(actor:GetAttribute("EnhancedRangedSlashesReleased") or 0) + emitted
			)
			return core.WaitFor(0.15)
		end)
	end
	function api.Dispose() end
	return api
end

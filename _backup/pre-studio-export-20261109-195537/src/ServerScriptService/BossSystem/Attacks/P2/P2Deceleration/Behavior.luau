local script = script.Parent
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local core = Registry.For(actor, "P1CombatCore")
	local api = {
		Duration = 10,
		Cooldown = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig")).DecelerationCooldown,
	}
	local visuals = Visuals.new({ actor = actor, core = core, Effects = Effects })

	function api.CanUse(character)
		if
			(tonumber(actor:GetAttribute("Phase")) or 1) < 2
			or (actor:GetAttribute("Phase") or 1) >= 3
			or actor:GetAttribute("LastMinuteActive")
			or not core.Active()
			or not core.Alive(character)
		then
			return false
		end
		for _, target in ipairs(core.Characters()) do
			if
				core.Alive(target)
				and (target:GetAttribute("DecelerationUntil") or 0) <= workspace:GetServerTimeNow()
			then
				return true
			end
		end
		return false
	end

	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		api.Duration = Difficulty.Design("Deceleration", "Duration", 10, actor)
		return core.Perform(character, "P2Deceleration", function()
			core.Face(character)
			core.Melee.Pose("Windup", 0.16)
			actor:SetAttribute("AttackState", "Deceleration: temporal pulse")
			local cast = Effects.NewCast(actor, "DecelerationWarning", 1)

			local root = core.Root
			local model = actor:IsA("Model") and actor or (root and root:FindFirstAncestorOfClass("Model"))
			local sigilParts = root and visuals.Sigil(cast, root) or nil

			local marks = {}
			for _, target in ipairs(core.Characters()) do
				if core.Alive(target) then
					local hrp = target:FindFirstChild("HumanoidRootPart")
					if hrp then
						marks[target] = visuals.CreateWarning(cast, target, hrp, sigilParts)
					end
				end
			end
			if not core.WaitFor(0.5) then
				cast:Dispose()
				return false
			end

			local impactCast = root and visuals.BossImpact(root, model, sigilParts) or Effects.NewCast(actor, "DecelerationImpact", 1.1)

			local reference = actor:FindFirstChild("EncounterOwner")
			local applied = 0
			for _, target in ipairs(core.Characters()) do
				if core.Alive(target) then
					local handle = Time.ApplyDeceleration(target, api.Duration)
					if handle then
						handle.owner = reference and reference.Value or actor
						applied += 1
					end
					local mark = marks[target]
					visuals.ReleaseWarning(mark)
					local hrp = target:FindFirstChild("HumanoidRootPart")
					if hrp then
						visuals.TargetImpact(impactCast, hrp, mark and mark.ground or visuals.GroundCFrame(hrp, target))
						if handle then
							visuals.StartDebuff(target, hrp, api.Duration)
						end
					end
				end
			end
			core.Melee.Pose("Slash3", 0.08)
			actor:SetAttribute("DecelerationsApplied", (actor:GetAttribute("DecelerationsApplied") or 0) + applied)
			actor:SetAttribute("LastDecelerationTargetCount", applied)
			return applied > 0
		end)
	end

	return api
end

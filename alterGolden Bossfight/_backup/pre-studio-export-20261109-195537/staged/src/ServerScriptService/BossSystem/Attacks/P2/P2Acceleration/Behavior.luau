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
		Cooldown = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig")).AccelerationCooldown,
	}
	local visuals = Visuals.new({ actor = actor, core = core, Effects = Effects })

	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) >= 2
			and (actor:GetAttribute("Phase") or 1) < 3
			and not actor:GetAttribute("LastMinuteActive")
			and core.Active()
			and core.Alive(character)
			and (actor:GetAttribute("AccelerationUntil") or 0) <= workspace:GetServerTimeNow()
	end

	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		api.Duration = Difficulty.Design("Acceleration", "Duration", 10, actor)
		return core.Perform(character, "P2Acceleration", function()
			actor:SetAttribute("AttackState", "Acceleration: gathering momentum")
			core.Melee.Pose("Windup3", 0.1)
			if core.Root then
				visuals.Windup(core.Root)
			end
			if not core.WaitFor(Difficulty.Design("Acceleration", "Windup", 0.28, actor)) then
				return false
			end
			local handle = Time.AccelerateBoss(actor, api.Duration)
			if not handle then
				return false
			end
			local root = core.Root
			if root then
				local model = actor:IsA("Model") and actor or root:FindFirstAncestorOfClass("Model")
				visuals.Activate(root, model)
				visuals.StartAura(root, api.Duration)
				visuals.RunLoop(root, model, api.Duration)
			end
			actor:SetAttribute("AccelerationsActivated", (actor:GetAttribute("AccelerationsActivated") or 0) + 1)
			return true
		end)
	end

	return api
end

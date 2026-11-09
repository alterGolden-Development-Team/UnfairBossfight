local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Controller = require(BossSystem.Mechanics.Clones.CloneController)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Metadata = require(BossSystem.Combat.AbilityMetadata)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local api, random = { IsPassive = true }, Random.new()
	local disposed = false
	function api.Record(attackName, target)
		local humanoid = actor:FindFirstChildOfClass("Humanoid")
		 
		local echoAll = require(Shared.Config.DifficultyConfig).Mercy("EchoAllPhases", actor) == true
		if
			disposed and not echoAll
			or actor:GetAttribute("IsGoldenClone")
			or not actor.Parent
			or not humanoid
			or humanoid.Health <= 0
			 
			or (tonumber(actor:GetAttribute("Phase")) or 1) < 2
				and require(Shared.Config.DifficultyConfig).Mercy("EchoAllPhases", actor) ~= true
			or actor:GetAttribute("AIEnabled") == false
			or actor:GetAttribute("PhaseTransitionInProgress")
			or type(attackName) ~= "string"
			or not Metadata.CanCopy(attackName, "HourDebt")
			or not Metadata.Available(attackName, actor:GetAttribute("Phase"))
			or not Registry.Module(attackName)
		then
			return false
		end
		local cap = math.clamp(tonumber(actor:GetAttribute("HourDebtMaxCopies")) or 6, 1, 12)
		if Controller.Count(actor, "HourDebt") >= cap then
			return false
		end
		local chance = math.clamp(tonumber(actor:GetAttribute("HourDebtChance")) or Config.HourDebtProcChance, 0, 1)
		if random:NextNumber() >= chance then
			return false
		end
		return Controller.Create(actor, {
			Mode = "HourDebt",
			AttackName = attackName,
			Target = target,
			 
			Delay = (function()
				local phase = tonumber(actor:GetAttribute("Phase")) or 1
				return (phase >= 2 and phase < 3) and 15 or 6
			end)(),
			HoldDuration = 0,
			FadeDuration = 0.6,
		}) or false
	end
	function api.Dispose()
		disposed = true
		Controller.CancelMode(actor, "HourDebt", "Hour Debt cancelled")
	end
	function api.Start()
		disposed = false
	end
	api.ProcChance = Config.HourDebtProcChance
	api.Delay = 15
	api.MaxCopies = 6
	return api
end

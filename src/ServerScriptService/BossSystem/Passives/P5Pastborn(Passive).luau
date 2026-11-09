 -- P5Pastborn (Time mode's passive): while Time mode is up a clone from the past stands beside him and attacks with the moves he
 -- has used since Phase 1 - any attack from P1 to P4.5, ultimates included (Mechanics/Clones/CloneController, mode "Past": it
 -- casts them as the era they came from). It cannot be hurt; it goes when the mode ends. A new one comes P5PastRespawn seconds
local B = script:FindFirstAncestor("BossSystem")
return function(actor)
	local api = { IsPassive = true }
	local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
	local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
	local nextAt = 0
	function api.IsActive()
		return actor.Parent ~= nil and actor:GetAttribute("Phase") == 5 and actor:GetAttribute("P5Mode") == "Time"
			and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("IsGoldenClone")
	end
	function api.Tick(getTarget)
		local active = api.IsActive()
		actor:SetAttribute("Passive_P5Pastborn", active)
		local Clones = require(B.Mechanics.Clones.CloneController)
		if not active then
			if Clones.Count(actor, "Past") > 0 then
				Clones.CancelMode(actor, "Past", "Time mode ended")
			end
			return
		end
		if actor:GetAttribute("AIEnabled") == false or actor:GetAttribute("PhaseTransitionInProgress") or actor:GetAttribute("P5ShieldDown") then
			return
		end
		local now = os.clock()
		if now < nextAt or Clones.Count(actor, "Past") > 0 then
			return
		end
		local target = getTarget and getTarget()
		if not target then
			return
		end
		local interval = (Config.P5PastInterval or 5) * ((Difficulty.Get(actor) or {}).Cooldown or 1)
		local handle = Clones.Create(actor, { Mode = "Past", Target = target, MaterializeDuration = 1.2, AttackInterval = interval })
		nextAt = now + (Config.P5PastRespawn or 6)
		if handle then
			actor:SetAttribute("P5PastClones", (actor:GetAttribute("P5PastClones") or 0) + 1)
		end
	end
	function api.Reset()
		nextAt = 0
		pcall(function() require(B.Mechanics.Clones.CloneController).CancelMode(actor, "Past", "passive reset") end)
		if actor.Parent then actor:SetAttribute("Passive_P5Pastborn", false) end
	end
	return api
end

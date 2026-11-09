 -- P5Spacetrum (Space mode's passive): every attack from the Space mode drops a Falling Star (Attacks/P5/Summoned/P5FallingStar,
 -- Summon) on a player, at most one every P5SpacetrumCooldown seconds (the difficulty's Cooldown scales that). The star is not a cast of
 -- its own: he goes on with whatever he was doing. PassiveController calls OnAttack when an attack starts.
local B = script:FindFirstAncestor("BossSystem")
return function(actor)
	local api = { IsPassive = true }
	local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
	local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
	local Metadata = require(B.Combat.AbilityMetadata)
	local nextAt = 0
	function api.IsActive()
		return actor.Parent ~= nil and actor:GetAttribute("Phase") == 5 and actor:GetAttribute("P5Mode") == "Space"
			and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("IsGoldenClone")
	end
	function api.Tick() actor:SetAttribute("Passive_P5Spacetrum", api.IsActive()) end
	function api.OnAttack(name, target)
		if not api.IsActive() or not target then
			return false
		end
		local entry = Metadata.Get(name)
		if not entry or entry.P5Mode ~= "Space" then
			return false  -- only attacks of the Space mode
		end
		local now = os.clock()
		if now < nextAt then
			return false
		end
		nextAt = now + (Config.P5SpacetrumCooldown or 2) * ((Difficulty.Get(actor) or {}).Cooldown or 1)
		local ok, err = pcall(function()
			local star = require(B.Combat.AttackRegistry).For(actor, "P5FallingStar")
			star.Summon(target)
		end)
		if not ok then warn("[P5Spacetrum] " .. tostring(err)) end
		actor:SetAttribute("P5SpacetrumStars", (actor:GetAttribute("P5SpacetrumStars") or 0) + 1)
		return ok
	end
	function api.Reset()
		nextAt = 0
		if actor.Parent then actor:SetAttribute("Passive_P5Spacetrum", false) end
	end
	return api
end

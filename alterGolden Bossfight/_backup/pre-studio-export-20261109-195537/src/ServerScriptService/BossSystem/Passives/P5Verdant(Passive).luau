 -- P5Verdant (Natural mode's passive): his Natural shield mends itself - P5VerdantRegen (15) shield every second while the mode
 -- is up and the shield is not down - and every hit of a Natural attack poisons whoever it lands on (StatusEffectService.ApplyPoison).
 -- PassiveController ticks Regen and calls Poison when a hit lands.
local B = script:FindFirstAncestor("BossSystem")
return function(actor)
	local api = { IsPassive = true }
	local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
	local Metadata = require(B.Combat.AbilityMetadata)
	local last = os.clock()
	function api.IsActive()
		return actor.Parent ~= nil and actor:GetAttribute("Phase") == 5 and actor:GetAttribute("P5Mode") == "Natural"
			and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("IsGoldenClone")
	end
	function api.Tick()
		local now = os.clock()
		local dt = math.clamp(now - last, 0, 1)
		last = now
		actor:SetAttribute("Passive_P5Verdant", api.IsActive())
		if not api.IsActive() or actor:GetAttribute("P5ShieldDown") then
			return
		end
		local max = actor:GetAttribute("MaxShield") or 0
		local shield = actor:GetAttribute("Shield") or 0
		if shield > (Config.Phase5ShieldHold or 1) and shield < max then
			actor:SetAttribute("Shield", math.min(max, shield + (Config.P5VerdantRegen or 15) * dt))
		end
	end
	 -- a hit of the Natural mode landed: poison them
	function api.Poison(character, balance)
		if not api.IsActive() or not character or (balance and balance.IsStatusDamage) then
			return false
		end
		local skill = balance and balance.Skill or actor:GetAttribute("CurrentSkill")
		local entry = skill and Metadata.Get(skill)
		if not entry or entry.P5Mode ~= "Natural" then
			return false
		end
		local ok = pcall(function()
			require(B.Combat.StatusEffectService).ApplyPoison(character, nil, actor)
		end)
		return ok
	end
	function api.Reset()
		if actor.Parent then actor:SetAttribute("Passive_P5Verdant", false) end
	end
	return api
end

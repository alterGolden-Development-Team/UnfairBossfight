local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local api = { IsPassive = true }
	function api.Ready()
  return (actor:GetAttribute("Phase") == 4.5 or actor:GetAttribute("Phase") == 5)
			or workspace:GetServerTimeNow() >= (actor:GetAttribute("RegenerationDisabledUntil") or 0)
 end
 function api.OnShieldBroken()
  if math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4 then return end
  actor:SetAttribute("RegenerationDisabledUntil", workspace:GetServerTimeNow() + Config.Phase4RegenerationLockout)
  actor:SetAttribute("Passive_P4Regeneration", false)
 end
	function api.Apply(_, actualDamage)
		if
			not api.Ready()
			or type(actualDamage) ~= "number"
			or actualDamage ~= actualDamage
			or actualDamage <= 0
			or actualDamage == math.huge
			or not actor.Parent
			or actor:GetAttribute("IsGoldenClone")
			or actor:GetAttribute("EncounterEnded")
			or actor:GetAttribute("PhaseTransitionInProgress")
			or math.min(4, math.floor(tonumber(actor:GetAttribute("Phase")) or 1)) ~= 4
		then
			return 0
		end
		local h = actor:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 then
			return 0
		end
		local recovery = actualDamage * math.max(0, Config.Phase4RegenerationFraction or 2)
		if recovery ~= recovery or recovery <= 0 or recovery == math.huge then
			return 0
		end
		if (actor:GetAttribute("Phase") == 4.5 or actor:GetAttribute("Phase") == 5) then
			local before = h.Health
			h.Health = math.min(h.MaxHealth, before + recovery)
			local healed = math.max(0, h.Health - before)
			if healed > 0 then
				actor:SetAttribute("BossHealth", h.Health)
				actor:SetAttribute("RegenerationHealthApplied", (actor:GetAttribute("RegenerationHealthApplied") or 0) + healed)
			end
			return healed
		end
		local maximum = math.max(0, actor:GetAttribute("MaxShield") or Config.Phase4ShieldMaxHealth or 2500)
		local before = math.clamp(actor:GetAttribute("Shield") or 0, 0, maximum)
		local shield = math.min(maximum, before + recovery)
		local healed = shield - before
		if healed > 0 then
			actor:SetAttribute("Shield", shield)
			actor:SetAttribute("ShieldBroken", false)
			actor:SetAttribute(
				"RegenerationShieldApplied",
				(actor:GetAttribute("RegenerationShieldApplied") or 0) + healed
			)
			local glow = actor:FindFirstChild("ShieldGlow")
			if glow then
				glow.Enabled = true
			end
		end
		return healed
	end
	function api.Reset() end
	api.Dispose = api.Reset
	return api
end

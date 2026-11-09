local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local api = { IsPassive = true }
	function api.Tick()
		local h = actor:FindFirstChildOfClass("Humanoid")
		if
			not actor.Parent
			or not h
			or h.Health <= 0
			or actor:GetAttribute("EncounterEnded")
			or actor:GetAttribute("ShieldBroken")
			or actor:GetAttribute("PhaseTransitionInProgress")
			or actor:GetAttribute("ShieldDamageLocked")
			or actor:GetAttribute("LastMinuteActive")  -- Borrowed Time: the shield is the clock, no free time back
			or actor:GetAttribute("LastMinuteQueued")  -- don't lift the shield back over the Last Minute gate while it waits
			or actor:GetAttribute("AIEnabled") == false
			or (actor:GetAttribute("Phase") or 1) < 1
			or (actor:GetAttribute("Phase") or 1) >= 3
		then
			return false
		end
		local shield = actor:GetAttribute("Shield") or 0
		if shield <= 0 then
			actor:SetAttribute("UnstoppableDisabled", true)
			return false
		end
		local maximum = actor:GetAttribute("MaxShield") or Config.ShieldMaxHealth
		local restored = math.min(maximum, shield + Config.UnstoppableShieldRestore)
		actor:SetAttribute("Shield", restored)
		if restored > shield then
			Audio.Emit(actor, "GuardActivate", nil, { VolumeScale = 0.3 })
		end
		actor:SetAttribute("UnstoppableTicks", (actor:GetAttribute("UnstoppableTicks") or 0) + 1)
		return restored - shield
	end
	function api.Dispose() end
	return api
end

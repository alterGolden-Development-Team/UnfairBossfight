local BossSystem = script:FindFirstAncestor("BossSystem")
 
return function(actor)
	local Controller = require(BossSystem.Mechanics.Clones.CloneController)
	local whitelist = require(BossSystem.Mechanics.Clones.CloneWhitelist)
	local api = { IsPassive = true }
	function api.CanUse(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return not actor:GetAttribute("IsGoldenClone")
			and (tonumber(actor:GetAttribute("Phase")) or 1) >= 1.5
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and actor:GetAttribute("AIEnabled") ~= false
   and workspace:GetServerTimeNow()>=(actor:GetAttribute("ClassStunnedUntil") or 0)
			and Controller.Count(actor, "Normal") == 0
			and humanoid
			and humanoid.Health > 0
	end
	function api.Spawn(character)
		if not api.CanUse(character) then
			return false
		end
		local handle = Controller.Create(actor, { Mode = "Normal", Target = character })
		return handle and handle.Actor or false
	end
	function api.SpawnPersistent(character)
		return Controller.SpawnPersistent(actor, character, 2)
	end
	function api.Dispose()
		Controller.CancelMode(actor, "Normal", "normal echo ended")
	end
	api.Combo = api.Spawn
	api.Whitelist = whitelist
	return api
end

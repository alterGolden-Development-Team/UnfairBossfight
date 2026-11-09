local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local S = require(script.Parent.Style)
local function holdLead() return (Config.DeflectHoldTime or 0.2) + 0.45 end
local POINT = { RightShoulder = { 90, 0, -10 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 20, 0, -20 }, Waist = { 0, -20, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local ok, result = pcall(core.Perform, target, S.Name, function()
			core.Face(target)
			core.PoseAngles(POINT, 0.1)
			actor:SetAttribute("AttackState", "Time Bomb")
			if not c.Wait(c.Tell(S.Tell)) then return false end
			local bombs = {}
			for _, char in ipairs(c.Targets()) do
				bombs[#bombs + 1] = char
				c.Send("TimeBomb", { Victim = char, Time = S.Fuse, Radius = S.Radius })
			end
			pcall(Audio.Emit, actor, "GroundTension", c.Root)
			if not c.Wait(S.Fuse - holdLead()) then return false end
			for _, char in ipairs(c.Targets()) do
				c.Warn(char, "Hold", holdLead() + 0.1)
			end
			if not c.Wait(holdLead()) then return false end
			 -- every bomb at once, where its holder is now
			local centers = {}
			for _, char in ipairs(bombs) do
				local r = char:FindFirstChild("HumanoidRootPart")
				if r then
					centers[#centers + 1] = r.Position
					c.Send("TimeBombBlast", { Pos = r.Position, Radius = S.Radius })
				end
			end
			core.ScreenEffect("Shake", { Origin = c.Root.Position, Radius = 400, Intensity = 0.8, Duration = 0.35 })
			for _, char in ipairs(c.Targets()) do
				local p = char.HumanoidRootPart.Position
				local n = 0
				for _, at in ipairs(centers) do
					if (p - at).Magnitude <= S.Radius then n += 1 end
				end
				if n > 0 and not c.Deflected(char, "Hold") then
					c.Hit(char, S.Damage * (1 + S.Chain * (n - 1)), p, { Knock = { Direction = Vector3.yAxis, Speed = 4, Lift = S.Lift,
						Duration = 0.3, Sustain = 0.05, AllowPlayerControl = true, ContainsArena = true } })
				end
			end
			actor:SetAttribute("P5TimeBombs", (actor:GetAttribute("P5TimeBombs") or 0) + 1)
			return c.Wait(0.1)
		end)
		c.ReleaseAll()
		if not ok then
			warn("[" .. S.Name .. "] " .. tostring(result))
			return false
		end
		return result
	end
	function api.Dispose()
		c.ReleaseAll()
	end
	return api
end

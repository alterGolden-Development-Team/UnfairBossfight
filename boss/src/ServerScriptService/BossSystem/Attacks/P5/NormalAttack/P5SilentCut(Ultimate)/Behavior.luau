local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Ultimate = require(B.Combat.UltimateService)
local Encounter = require(B.Players.PlayerEncounter)
local S = require(script.Parent.Style)

 -- the draw stance: knees low, the left hand on the scabbard, the right on the hilt
local IAIDO = { RightShoulder = { 20, 0, 40 }, RightElbow = { 95, 0, 0 }, RightWrist = { -10, 0, 0 }, LeftShoulder = { 30, 0, -25 },
	LeftElbow = { 85, 0, 0 }, Waist = { 25, 30, 0 }, RightHip = { -55, 0, 0 }, RightKnee = { 75, 0, 0 }, LeftHip = { -20, 0, 0 },
	LeftKnee = { 45, 0, 0 } }
 -- sheathing: upright, the blade sliding home at his side
local SHEATHE = { RightShoulder = { -5, 0, 30 }, RightElbow = { 70, 0, 0 }, RightWrist = { -30, 0, 0 }, LeftShoulder = { 15, 0, -30 },
	LeftElbow = { 75, 0, 0 }, Waist = { 0, 15, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown, IsUltimate = true, UltimatePhase = 5 }
	local healing = setmetatable({}, { __mode = "k" })

	 -- the big cut takes a share of their health, then it seeps back in over RestoreTime
	local function halve(char)
		local h = char:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 or not Encounter.CanReceiveHit(char) then
			return false
		end
		local lost = h.Health * S.HalfHealth
		h.Health = math.max(1, h.Health - lost)
		c.Send("SilentHit", { Victim = char, Time = S.RestoreTime })
		local token = {}
		healing[char] = token
		task.spawn(function()
			local back, step = 0, 0.25
			while back < lost and healing[char] == token and h.Parent and h.Health > 0 do
				task.wait(step)
				local add = math.min(lost * step / S.RestoreTime, lost - back)
				back += add
				h.Health = math.min(h.MaxHealth, h.Health + add)
			end
		end)
		return true
	end

	function api.CanUse(target)
		return c.CanStart(target) and Ultimate.Ready(actor, S.Name)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local result = core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(IAIDO, 0.2)
			actor:SetAttribute("AttackState", "Silent Cut")
			pcall(Encounter.Say, "Close your eyes. You won't see this one anyway.", nil, { Duration = 2.4 })
			local stance = c.Tell(S.Stance)
			local lead = math.max(S.Sheathe, c.Tell(S.Sheathe))
			local victims = c.Targets()
			c.Send("SilentStart", { Victims = victims })
			c.Send("SilentStance", { Time = stance })
			if not c.Wait(stance) then
				return false
			end
			c.Send("SilentCuts", { Victims = victims, Time = S.Cuts, Count = S.Lines, Radius = S.Radius, Seed = math.random(1, 1e6) })
			pcall(Audio.Emit, actor, "SplitActivate", c.Root)
			if not c.Wait(S.Cuts) then
				return false
			end
			 -- back, behind the first of them, sheathing
			if victims[1] and core.Alive(victims[1]) then
				c.Blink(c.Behind(victims[1], 8))
			end
			core.PoseAngles(SHEATHE, lead * 0.8)
			c.Send("SilentSheathe", { Time = lead })
			for _, char in ipairs(victims) do
				c.Warn(char, "Hold", lead)
			end
			if not c.Wait(lead) then
				return false
			end
			c.Send("SilentShatter", { Victims = victims })
			pcall(Audio.Emit, actor, "SplitHum", c.Root)
			core.ScreenEffect("Shake", { Origin = core.Root.Position, Radius = 500, Intensity = 1.2, Duration = 0.4 })
			for _, char in ipairs(victims) do
				if core.Alive(char) and not c.Deflected(char, "Hold") then
					halve(char)
				end
			end
			if not c.Wait(0.6) then
				return false
			end
			for index = 1, S.Follow do
				local list = c.Targets()
				local flead = math.max(S.FollowLead, c.Tell(S.FollowLead))
				core.PoseAngles(IAIDO, 0.06)
				c.Send("SilentStart", { Victims = list, Short = true })
				c.Send("SilentCuts", { Victims = list, Time = flead * 0.7, Count = S.FollowLines, Radius = S.Radius * 0.6,
					Seed = math.random(1, 1e6), Small = true })
				c.Send("SilentSheathe", { Time = flead })
				for _, char in ipairs(list) do
					c.Warn(char, "Tap", flead)
				end
				if not c.Wait(flead) then
					return false
				end
				core.PoseAngles(SHEATHE, 0.05)
				c.Send("SilentShatter", { Victims = list, Small = true })
				for _, char in ipairs(list) do
					if core.Alive(char) and not c.Deflected(char, "Tap") then
						c.Hit(char, S.FollowDamage, char.HumanoidRootPart.Position)
					end
				end
				if index < S.Follow and not c.Wait(S.FollowGap) then
					return false
				end
			end
			actor:SetAttribute("P5SilentCuts", (actor:GetAttribute("P5SilentCuts") or 0) + 1)
			return c.Wait(0.1)
		end)
		c.Send("SilentEnd", {})
		return result
	end
	function api.Dispose() end
	return api
end

local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local Encounter = require(B.Players.PlayerEncounter)

local AIM = { RightShoulder = { 90, 0, -5 }, RightElbow = { 0, 0, 0 }, RightWrist = { -70, 0, 0 }, LeftShoulder = { 15, 0, -25 },
	Waist = { 0, -25, 0 } }
local RECOIL = { RightShoulder = { 120, 0, -5 }, RightElbow = { 20, 0, 0 }, RightWrist = { -40, 0, 0 }, LeftShoulder = { 10, 0, -30 },
	Waist = { -12, -25, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	function api.CanUse(target)
		 -- only up close: a point-blank shot
		return c.CanStart(target) and (target.HumanoidRootPart.Position - c.Root.Position).Magnitude <= S.UseRange
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			local r = target.HumanoidRootPart
			if (r.Position - c.Root.Position).Magnitude > S.Approach + 6 then
				c.Blink(c.Beside(target, S.Approach, math.pi))
			end
			core.Face(target)
			core.PoseAngles(AIM, 0.1)
			actor:SetAttribute("AttackState", "Shotgun Blast")
			pcall(Encounter.Say, S.Lines[math.random(1, #S.Lines)], nil, { Duration = 1.4 })
			local glint = math.max(0.35, c.Tell(S.Glint))
			c.Send("EyeGlint", { Time = glint })
			if not c.Over(glint, function()
				if core.Alive(target) then core.Face(target) end
			end) then
				return false
			end
			core.PoseAngles(RECOIL, 0.04)
			local frame = c.Root.CFrame * CFrame.new(0, 1.2, -1.5)
			pcall(Audio.Emit, actor, "RangedLaunch", c.Root)
			c.Send("ShotgunBlast", { Frame = frame, Range = S.Range, HalfAngle = S.HalfAngle })
			core.ScreenEffect("Shake", { Origin = frame.Position, Radius = 90, Intensity = 0.8, Duration = 0.25 })
			local cosHalf = math.cos(math.rad(S.HalfAngle))
			for _, char in ipairs(c.Targets()) do
				local p = frame:PointToObjectSpace(char.HumanoidRootPart.Position)
				local dist = p.Magnitude
				if dist <= S.Range + 1.5 and (dist < 2 or -p.Z / dist >= cosHalf) then
					local closeness = 1 - math.clamp(dist / S.Range, 0, 1)
					c.Hit(char, S.MinDamage + (S.MaxDamage - S.MinDamage) * closeness, frame.Position, { Knock = {
						Direction = frame.LookVector, Speed = 25 + 45 * closeness, Lift = 12, Duration = 0.3, Sustain = 0.06,
						AllowPlayerControl = true, ContainsArena = true } })
				end
			end
			actor:SetAttribute("P5ShotgunBlasts", (actor:GetAttribute("P5ShotgunBlasts") or 0) + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end

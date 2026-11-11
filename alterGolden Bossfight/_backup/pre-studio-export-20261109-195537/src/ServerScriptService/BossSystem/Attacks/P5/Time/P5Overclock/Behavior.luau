local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Time = require(B.Mechanics.Time.TimeEffectController)
local Encounter = require(B.Players.PlayerEncounter)
local S = require(script.Parent.Style)

local WIND = { RightShoulder = { 120, 0, 40 }, RightElbow = { 30, 0, 0 }, LeftShoulder = { 120, 0, -40 }, LeftElbow = { 30, 0, 0 },
	Waist = { -8, 0, 0 } }
local THROW = { RightShoulder = { 90, 0, -10 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 30, 0, -20 }, Waist = { 8, -15, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	function api.CanUse(target)
		return c.CanStart(target) and not actor:GetAttribute("AccelerationActive")
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(WIND, 0.12)
			actor:SetAttribute("AttackState", "Overclock")
			local tell = c.Tell(S.Tell)
			c.Send("Overclock", { Time = tell + S.Fast })
			pcall(Encounter.Say, S.Line, nil, { Duration = 2 })
			if not c.Wait(tell) then
				return false
			end
			pcall(Time.AccelerateBoss, actor, S.Fast)
			for _, char in ipairs(c.Targets()) do
				pcall(Time.ApplyDeceleration, char, S.Slow)
				c.Send("SlowClock", { Victim = char, Time = S.Slow })
			end
			core.ScreenEffect("Shake", { Origin = core.Root.Position, Radius = 200, Intensity = 0.5, Duration = 0.25 })
			for volley = 1, c.Count(S.Volleys) do
				for _, char in ipairs(c.Targets()) do
					core.Face(char)
					core.PoseAngles(THROW, 0.04)
					local origin = (core.Root.CFrame * CFrame.new(0, 1.5, -2.5)).Position
					local to = char.HumanoidRootPart.Position - origin
					for shot = 1, S.Shots do
						local yaw = math.rad((shot - (S.Shots + 1) / 2) * S.Spread)
						c.Bolt(origin, CFrame.Angles(0, yaw, 0):VectorToWorldSpace(to), { Speed = S.ShotSpeed, Range = S.ShotRange,
							Radius = S.ShotRadius, Damage = S.ShotDamage, Pierce = true, Deflect = "Tap", Look = "Gold" })
					end
				end
				if not c.Wait(S.VolleyGap) then
					return false
				end
			end
			actor:SetAttribute("P5Overclocks", (actor:GetAttribute("P5Overclocks") or 0) + 1)
			return c.Wait(0.3)
		end)
	end
	function api.Dispose() end
	return api
end

local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)

local RAISE = { LeftShoulder = { 175, 0, -10 }, LeftElbow = { 8, 0, 0 }, RightShoulder = { 10, 0, 30 }, Waist = { -14, -12, 0 } }
local SLAM = { LeftShoulder = { 45, 0, -15 }, LeftElbow = { 0, 0, 0 }, RightShoulder = { -25, 0, 40 }, Waist = { 32, -8, 0 },
	RightHip = { -35, 0, 0 }, RightKnee = { 55, 0, 0 }, LeftHip = { -50, 0, 0 }, LeftKnee = { 70, 0, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	function api.CanUse(target)
		 -- a melee slam: only with his target close (Style UseRange)
		return c.CanStart(target) and (target.HumanoidRootPart.Position - c.Root.Position).Magnitude <= S.UseRange
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(RAISE, 0.12)
			actor:SetAttribute("AttackState", "Slam: the arm rises")
			local windup = c.Tell(S.Windup)
			c.Send("SlamRaise", { Time = windup })
			if not c.Wait(windup) then
				return false
			end
			core.PoseAngles(SLAM, 0.05)
			local point = c.Ground((core.Root.CFrame * CFrame.new(-1.5, 0, -S.Reach)).Position)
			actor:SetAttribute("AttackState", "Slam!")
			c.Send("SlamImpact", { Pos = point, Radius = S.SpikeRadius })
			core.ScreenEffect("Shake", { Origin = point, Radius = 200, Intensity = 1, Duration = 0.45 })
			c.Shockwave(point, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = S.WaveWidth, Height = S.WaveHeight,
				Damage = S.WaveDamage, Knock = { Speed = 35, Lift = 18, Duration = 0.25, Sustain = 0.05, AllowPlayerControl = true,
					ContainsArena = true } })
			c.Spikes({ point }, { Radius = S.SpikeRadius, Damage = S.SpikeDamage, Tall = S.SpikeTall, Count = S.SpikeCount,
				Height = S.SpikeHeight, Knock = { Speed = 10, Lift = 45, Duration = 0.3, Sustain = 0.06, AllowPlayerControl = true,
					ContainsArena = true } })
			actor:SetAttribute("P5Slams", (actor:GetAttribute("P5Slams") or 0) + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end

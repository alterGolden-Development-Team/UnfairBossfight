local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)
local S = require(script.Parent.Style)

local LIFT = { RightShoulder = { 165, 0, 5 }, RightElbow = { 20, 0, 0 }, LeftShoulder = { 150, 0, -5 }, LeftElbow = { 20, 0, 0 },
	Waist = { -12, 0, 0 } }
local STAB = { RightShoulder = { 40, 0, 5 }, RightElbow = { 30, 0, 0 }, RightWrist = { -80, 0, 0 }, LeftShoulder = { 40, 0, -5 },
	LeftElbow = { 30, 0, 0 }, Waist = { 38, 0, 0 }, RightHip = { -45, 0, 0 }, RightKnee = { 75, 0, 0 }, LeftHip = { -30, 0, 0 },
	LeftKnee = { 60, 0, 0 } }

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
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(LIFT, 0.1)
			actor:SetAttribute("AttackState", "Horrifying Ground")
			local windup = c.Tell(S.Windup)
			c.Send("StabTell", { Time = windup })
			if not c.Wait(windup) then
				return false
			end
			core.PoseAngles(STAB, 0.05)
			local here = c.Ground((core.Root.CFrame * CFrame.new(0, 0, -2.5)).Position)
			c.Send("GroundStab", { Pos = here })
			core.ScreenEffect("Shake", { Origin = here, Radius = 160, Intensity = 0.8, Duration = 0.35 })
			if not core.Alive(target) then
				target = c.RandomTarget()
			end
			if not target then
				return c.Wait(0.3)
			end
			 -- the ring of circles around them, every one its own size and style
			local center = c.Ground(target.HumanoidRootPart.Position)
			local circles, spin = {}, math.random() * math.pi * 2
			local styles = table.clone(S.Styles)
			for i = #styles, 2, -1 do
				local j = math.random(1, i)
				styles[i], styles[j] = styles[j], styles[i]
			end
			for i = 1, S.Circles do
				local a = spin + i * math.pi * 2 / S.Circles + (math.random() - 0.5) * 0.25
				local radius = S.CircleMin + math.random() * (S.CircleMax - S.CircleMin)
				circles[i] = {
					Pos = c.Ground(center + Vector3.new(math.cos(a), 0, math.sin(a)) * (S.RingRadius + (math.random() - 0.5) * 3)),
					Radius = radius, Style = styles[(i - 1) % #styles + 1], Tall = 1.2 + math.random() * 1.1,
					Count = math.random(4, 9),
				}
			end
			local warn = c.Tell(S.Warn)
			for _, circle in ipairs(circles) do
				Net.Send("GroundShatter", "Warn", { Points = { circle.Pos }, Radius = circle.Radius, Time = warn })
			end
			if not c.Wait(warn) then
				return false
			end
			 -- they burst up together, and the ground shakes out a shockwave as they do
			for _, circle in ipairs(circles) do
				Net.Send("GroundShatter", "Erupt", { Points = { circle.Pos }, Radius = circle.Radius, Seed = math.random(1, 1e6),
					Tall = circle.Tall, Count = circle.Count, Style = circle.Style, Hold = 0.8 })
			end
			c.Shockwave(center, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = S.WaveWidth, Height = S.WaveHeight,
				Damage = S.WaveDamage, Look = "Gold" })
			core.ScreenEffect("Shake", { Origin = center, Radius = 140, Intensity = 0.9, Duration = 0.35 })
			for _, char in ipairs(c.Targets()) do
				local p = char.HumanoidRootPart.Position
				for _, circle in ipairs(circles) do
					local rel = p - circle.Pos
					if Vector3.new(rel.X, 0, rel.Z).Magnitude <= circle.Radius and rel.Y >= -4 and rel.Y <= S.SpikeHeight then
						c.Hit(char, S.SpikeDamage, circle.Pos + Vector3.new(0, 1, 0), { BreaksBlock = true })
						break
					end
				end
			end
			actor:SetAttribute("P5HorrifyingGrounds", (actor:GetAttribute("P5HorrifyingGrounds") or 0) + 1)
			return c.Wait(0.5)
		end)
	end
	function api.Dispose() end
	return api
end

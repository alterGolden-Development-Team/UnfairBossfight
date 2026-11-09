local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)
local Ultimate = require(B.Combat.UltimateService)
local Encounter = require(B.Players.PlayerEncounter)

local READY = { RightShoulder = { -30, 0, 40 }, RightElbow = { 30, 0, 0 }, LeftShoulder = { 30, 0, -30 }, Waist = { 20, 40, 0 },
	RightHip = { -40, 0, 0 }, RightKnee = { 60, 0, 0 }, LeftHip = { -20, 0, 0 }, LeftKnee = { 40, 0, 0 } }
 -- the charge: both hands cupped at his side around the gathering light
local CHARGE = { RightShoulder = { 40, 0, 50 }, RightElbow = { 70, 0, 0 }, LeftShoulder = { 70, 0, -10 }, LeftElbow = { 80, 0, 0 },
	Waist = { 10, 55, 0 }, RightHip = { -45, 0, 0 }, RightKnee = { 70, 0, 0 }, LeftHip = { -25, 0, 0 }, LeftKnee = { 45, 0, 0 } }
 -- the release: both arms thrust straight down the lane
local FIRE = { RightShoulder = { 90, 0, -8 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 90, 0, 8 }, LeftElbow = { 0, 0, 0 },
	Waist = { 12, 0, 0 }, RightHip = { -35, 0, 0 }, RightKnee = { 30, 0, 0 }, LeftHip = { 25, 0, 0 } }

local function segmentDistance(point, a, b)
	local d = b - a
	local t = d:Dot(d) > 0.0001 and math.clamp((point - a):Dot(d) / d:Dot(d), 0, 1) or 0
	return (point - (a + d * t)).Magnitude
end

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown, IsUltimate = true, UltimatePhase = 5 }

	function api.CanUse(target)
		return c.CanStart(target) and Ultimate.Ready(actor, S.Name)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			 -- 1. he readies himself, turning with his prey
			local ready, charge = c.Tell(S.Ready), c.Tell(S.Charge)
			core.Face(target)
			core.PoseAngles(READY, 0.15)
			actor:SetAttribute("AttackState", "Night Tearer: ready")
			c.Send("TearerReady", { Time = ready + charge })
			pcall(Encounter.Say, S.Line, nil, { Duration = 2.2 })
			if not c.Over(ready, function()
				if core.Alive(target) then core.Face(target) end
			end) then
				return false
			end
			 -- 2. the charge: the lane is set now, marked red on the floor, and everyone is warned what it costs
			local root = c.Root
			local ground = c.Ground(root.Position)
			local look = core.Alive(target) and (target.HumanoidRootPart.Position - root.Position) * Vector3.new(1, 0, 1)
				or root.CFrame.LookVector * Vector3.new(1, 0, 1)
			look = look.Magnitude > 0.1 and look.Unit or Vector3.zAxis
			local lane = CFrame.lookAt(ground, ground + look)
			root.CFrame = CFrame.lookAt(root.Position, root.Position + look)
			core.PoseAngles(CHARGE, 0.2)
			actor:SetAttribute("AttackState", "Night Tearer: charging")
			local origin = (lane * CFrame.new(0, S.BeamHeight, -4)).Position
			local wall = workspace:Raycast(origin, look * S.Range, core.Params())
			local reach = wall and wall.Distance or S.Range
			c.Send("TearerCharge", { Frame = lane, Origin = origin, Time = charge, Range = reach, HalfWidth = S.BeamRadius })
			if not c.Wait(charge) then
				return false
			end
			 -- 3. the beam, and the shockwave let loose with it
			core.PoseAngles(FIRE, 0.05)
			actor:SetAttribute("AttackState", "Night Tearer!")
			c.Send("TearerBeam", { Origin = origin, Dir = look, Range = reach, Time = S.BeamTime, Radius = S.BeamRadius, Grow = S.Grow })
			core.ScreenEffect("Shake", { Origin = ground, Radius = 500, Intensity = 1.6, Duration = S.BeamTime })
			c.Shockwave(ground, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = S.WaveWidth, Height = S.WaveHeight,
				Damage = S.WaveDamage, Knock = { Speed = 45, Lift = 20, Duration = 0.3, Sustain = 0.06, AllowPlayerControl = true,
					ContainsArena = true } })
			local hit, elapsed = {}, 0
			if not c.Over(S.BeamTime, function(_, dt)
				elapsed += dt
				local tip = origin + look * reach * math.min(elapsed / S.Grow, 1)
				for _, char in ipairs(c.Targets()) do
					local p = char.HumanoidRootPart.Position
					if not hit[char] and segmentDistance(p, origin, tip) <= S.BeamRadius + 1 then
						hit[char] = true
						if c.Execute(char, S.LivesCost, p) then
							actor:SetAttribute("P5NightTearerKills", (actor:GetAttribute("P5NightTearerKills") or 0) + 1)
						end
					end
				end
			end) then
				return false
			end
			actor:SetAttribute("P5NightTears", (actor:GetAttribute("P5NightTears") or 0) + 1)
			return c.Wait(0.5)
		end)
	end
	function api.Dispose() end
	return api
end

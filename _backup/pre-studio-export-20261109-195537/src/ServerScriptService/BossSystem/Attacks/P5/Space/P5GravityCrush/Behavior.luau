local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Runtime = require(B.Combat.CombatRuntime)
local S = require(script.Parent.Style)
local function holdLead() return (Config.DeflectHoldTime or 0.2) + 0.45 end
local function segmentDistance(point, a, b)
	local d = b - a
	local t = d:Dot(d) > 0.0001 and math.clamp((point - a):Dot(d) / d:Dot(d), 0, 1) or 0
	return (point - (a + d * t)).Magnitude
end
local CAST = { RightShoulder = { 120, 0, 20 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 120, 0, -20 }, LeftElbow = { 10, 0, 0 }, Waist = { -10, 0, 0 } }
local POINT = { RightShoulder = { 90, 0, -10 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 20, 0, -20 }, Waist = { 0, -20, 0 } }
local SLAM = { RightShoulder = { 30, 0, 20 }, LeftShoulder = { 30, 0, -20 }, Waist = { 30, 0, 0 }, RightHip = { -40, 0, 0 }, RightKnee = { 50, 0, 0 },
	LeftHip = { -40, 0, 0 }, LeftKnee = { 50, 0, 0 } }

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
			core.PoseAngles(CAST, 0.12)
			actor:SetAttribute("AttackState", "Gravity Crush")
			if not c.Wait(c.Tell(S.Tell)) then return false end
			local center = c.Ground(target.HumanoidRootPart.Position)
			c.Send("GravityWell", { Pos = center, Radius = S.Radius, Time = S.Delay + S.Pull + S.Float + S.Slam, Delay = S.Delay })
			pcall(Audio.Emit, actor, "TornadoBuild", center)
			 -- while the orb opens it already sucks in everyone near it, so whoever is close when it catches is right under it
			local field = c.PullField({ Center = function() return center end, Range = S.Radius * 2, Speed = S.SuckSpeed, Accel = 20000,
				Stop = 3, Ease = 6, Time = S.Delay + 1 })
			local sucked = c.Over(S.Delay, function() field.Update() end)
			field.Dispose()
			if not sucked then return false end
			local caught = {}
			for _, char in ipairs(c.Targets()) do
				local rel = char.HumanoidRootPart.Position - center
				if Vector3.new(rel.X, 0, rel.Z).Magnitude <= S.Radius and rel.Y <= S.Radius * 1.5 and c.Seize(char, true) then
					caught[#caught + 1] = { Char = char, From = char.HumanoidRootPart.Position, Angle = math.atan2(rel.Z, rel.X),
						Dist = Vector3.new(rel.X, 0, rel.Z).Magnitude }
				end
			end
			core.PoseAngles(POINT, 0.1)
			local top = center + Vector3.new(0, S.Lift + 3, 0)
			if not c.Over(S.Pull, function(alpha)
				local e = 1 - (1 - alpha) ^ 2
				for i, m in ipairs(caught) do
					local a = m.Angle + e * 3 + i
					local r = m.Dist * (1 - e) + 3 * e
					local p = Vector3.new(center.X + math.cos(a) * r, m.From.Y + (top.Y - m.From.Y) * e, center.Z + math.sin(a) * r)
					c.Move(m.Char, CFrame.new(p))
				end
			end) then return false end
			for _, m in ipairs(caught) do
				c.Warn(m.Char, "Hold", S.Float + S.Slam)
			end
			if not c.Over(S.Float, function(alpha)
				for i, m in ipairs(caught) do
					local a = m.Angle + 3 + i + alpha * 2
					c.Move(m.Char, CFrame.new(top + Vector3.new(math.cos(a) * 3, math.sin(alpha * 12) * 0.4, math.sin(a) * 3)))
				end
			end) then return false end
			core.PoseAngles(SLAM, 0.04)
			if not c.Over(S.Slam, function(alpha)
				for i, m in ipairs(caught) do
					local a = m.Angle + 5 + i
					local p = top + Vector3.new(math.cos(a) * 3, 0, math.sin(a) * 3)
					c.Move(m.Char, CFrame.new(p:Lerp(Vector3.new(p.X, center.Y + 3, p.Z), alpha * alpha)))
				end
			end) then return false end
			c.ReleaseAll()
			c.Send("GravitySlam", { Pos = center, Radius = S.Radius })
			c.Shockwave(center, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = S.WaveWidth, Height = S.WaveHeight, Damage = S.WaveDamage })
			core.ScreenEffect("Shake", { Origin = center, Radius = 300, Intensity = 1.2, Duration = 0.4 })
			for _, m in ipairs(caught) do
				if core.Alive(m.Char) and not c.Deflected(m.Char, "Hold") then
					c.Hit(m.Char, S.SlamDamage, center, { BreaksBlock = true })
				end
			end
			actor:SetAttribute("P5GravityCrushes", (actor:GetAttribute("P5GravityCrushes") or 0) + 1)
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

local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
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
	-- one star from the Space passive (Passives/P5Spacetrum): no cast of its own, so he goes on with whatever he is doing.
	-- A circle marks the spot (the Telegraph scales the warning), then a star lands on it.
	function api.Summon(target)
		if not (target and core.Alive(target)) or not c.Valid() then
			return false
		end
		local count = math.random(S.SummonMin or 3, S.SummonMax or 5)
		local radius, fall = S.SmallRadius * 1.2, c.Tell(S.Fall)
		local spread = S.SummonSpread or 16
		task.spawn(function()
			for k = 1, count do
				if not (core.Alive(target) and c.Valid()) then return end
				local root = target.HumanoidRootPart
				local lead = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * 0.3
				local a, r = math.random() * math.pi * 2, math.sqrt(math.random()) * spread
				local at = c.Ground(root.Position + lead + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
				c.Send("StarFall", { Pos = at, Radius = radius, Time = fall })
				task.delay(fall, function()
					if not c.Valid() then return end
					c.Send("StarImpact", { Pos = at, Radius = radius })
					for _, char in ipairs(c.Targets()) do
						local rel = char.HumanoidRootPart.Position - at
						if Vector3.new(rel.X, 0, rel.Z).Magnitude <= radius and rel.Y <= radius then
							c.Hit(char, S.SmallDamage, at + Vector3.new(0, 2, 0), { Knock = { Direction = rel, Speed = 25, Lift = 12, Duration = 0.3,
								Sustain = 0.06, AllowPlayerControl = true, ContainsArena = true } })
						end
					end
				end)
				task.wait(S.SummonGap or 0.15)
			end
		end)
		return true
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local ok, result = pcall(core.Perform, target, S.Name, function()
			c.Plant()  -- he stands and calls the stars: no walking, no other move, until the big one has landed
			core.Face(target)
			core.PoseAngles(CAST, 0.12)
			actor:SetAttribute("AttackState", "Falling Star")
			if not c.Wait(c.Tell(S.Tell)) then return false end
			local function star(at, radius, fall, damage, big)
				c.Send("StarFall", { Pos = at, Radius = radius, Time = fall, Big = big })
				task.delay(fall, function()
					if not c.Valid() then return end
					c.Send("StarImpact", { Pos = at, Radius = radius, Big = big })
					for _, char in ipairs(c.Targets()) do
						local rel = char.HumanoidRootPart.Position - at
						if Vector3.new(rel.X, 0, rel.Z).Magnitude <= radius and rel.Y <= radius then
							c.Hit(char, damage, at + Vector3.new(0, 2, 0), { BreaksBlock = big, Knock = { Direction = rel, Speed = big and 45 or 25,
								Lift = big and 25 or 12, Duration = 0.3, Sustain = 0.06, AllowPlayerControl = true, ContainsArena = true } })
						end
					end
					if big then
						c.Shockwave(at, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = S.WaveWidth, Height = S.WaveHeight, Damage = S.WaveDamage })
						core.ScreenEffect("Shake", { Origin = at, Radius = 400, Intensity = 1.3, Duration = 0.5 })
					end
				end)
			end
			local list = c.Targets()
			for i = 1, c.Count(S.Small) do
				local who = list[(i - 1) % math.max(#list, 1) + 1] or target
				local base = who.HumanoidRootPart.Position + Vector3.new(math.random(-14, 14), 0, math.random(-14, 14))
				star(c.Ground(base), S.SmallRadius, S.Fall, S.SmallDamage, false)
				if not c.Wait(S.SmallGap) then return false end
			end
			local center = core.Alive(target) and c.Ground(target.HumanoidRootPart.Position) or c.Ground(c.Root.Position)
			star(center, S.Radius, S.BigFall, S.BigDamage, true)
			actor:SetAttribute("P5FallingStars", (actor:GetAttribute("P5FallingStars") or 0) + 1)
			return c.Wait(S.BigFall + 0.3)
		end)
		c.ReleaseAll()
		c.Unplant()
		if not ok then
			warn("[" .. S.Name .. "] " .. tostring(result))
			return false
		end
		return result
	end
	function api.Dispose()
		c.ReleaseAll()
		c.Unplant()
	end
	return api
end

local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)
local Players = game:GetService("Players")

local CAST = { RightShoulder = { 95, 0, -10 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 95, 0, 10 }, LeftElbow = { 0, 0, 0 }, Waist = { -8, 0, 0 } }

local function segmentDistance(point, a, b)
	local d = b - a
	local t = d:Dot(d) > 0.0001 and math.clamp((point - a):Dot(d) / d:Dot(d), 0, 1) or 0
	return (point - (a + d * t)).Magnitude
end

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	function api.CanUse(target)
		return c.CanStart(target) and workspace:GetServerTimeNow() <= (actor:GetAttribute("P5GoldenPierceArmedUntil") or 0)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local who = actor:GetAttribute("P5GoldenPierceVictim")
		local player = who and Players:FindFirstChild(who)
		local victim = player and player.Character and core.Alive(player.Character) and player.Character or target
		actor:SetAttribute("P5GoldenPierceArmedUntil", 0)
		return core.Perform(victim, S.Name, function()
			actor:SetAttribute("AttackState", "Golden Pierce: the circles")
			core.Face(victim)
			core.PoseAngles(CAST, 0.1)
			local center = (core.Root.CFrame * CFrame.new(0, 2, -3)).Position
			local face = CFrame.lookAt(center, victim.HumanoidRootPart.Position)
			local count = c.Count(S.Beams)
			local origins = {}
			for i = 1, count do
				local a = (i - 1) * math.pi * 2 / count + math.pi / 2
				origins[i] = (face * CFrame.new(math.cos(a) * S.Ring, math.sin(a) * S.Ring, -0.5)).Position
			end
			local form = c.Tell(S.Form)
			local total = form + count * S.Stagger + S.BeamTime + S.FinalTime
			c.Send("PierceCircle", { Frame = face, Time = total })
			for _, o in ipairs(origins) do
				c.Send("PierceCircle", { Frame = CFrame.lookAt(o, victim.HumanoidRootPart.Position), Time = total, Small = true })
			end
			if not c.Wait(form) then return false end
			actor:SetAttribute("AttackState", "Golden Pierce: the beams")
			local lastTick = {}
			 -- one beam: aimed at where they are going, stopped by walls, burning its line for `seconds`
			local function fire(origin, radius, seconds, damage)
				local r = victim.HumanoidRootPart
				local aim = r.Position + r.AssemblyLinearVelocity * S.Lead
				local dir = (aim - origin).Magnitude > 0.1 and (aim - origin).Unit or core.Root.CFrame.LookVector
				local wall = workspace:Raycast(origin, dir * S.Range, core.Params())
				local tip = origin + dir * (wall and wall.Distance or S.Range)
				c.Send("PierceBeam", { Origin = origin, Dir = dir, Range = (tip - origin).Magnitude, Time = seconds, Width = radius })
				task.spawn(function()
					local ends = os.clock() + seconds
					while os.clock() < ends and c.Valid() do
						for _, char in ipairs(c.Targets()) do
							local now = os.clock()
							if now - (lastTick[char] or 0) >= S.Tick * 0.9
								and segmentDistance(char.HumanoidRootPart.Position, origin, tip) <= radius then
								lastTick[char] = now
								c.Hit(char, damage, origin)
							end
						end
						task.wait(S.Tick)
					end
				end)
			end
			for _, o in ipairs(origins) do
				if not core.Alive(victim) then break end
				fire(o, S.Radius, S.BeamTime, S.TickDamage)
				if not c.Wait(S.Stagger) then return false end
			end
			if not c.Wait(math.max(S.BeamTime - S.Stagger, 0.1)) then return false end
			if core.Alive(victim) then
				fire(center, S.FinalRadius, S.FinalTime, S.FinalDamage)
				core.ScreenEffect("Shake", { Origin = center, Radius = 140, Intensity = 0.6, Duration = S.FinalTime })
				if not c.Wait(S.FinalTime) then return false end
			end
			actor:SetAttribute("P5GoldenPierces", (actor:GetAttribute("P5GoldenPierces") or 0) + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end

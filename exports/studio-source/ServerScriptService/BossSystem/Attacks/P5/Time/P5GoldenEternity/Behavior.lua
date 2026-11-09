local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Time = require(B.Mechanics.Time.TimeEffectController)
local Encounter = require(B.Players.PlayerEncounter)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local S = require(script.Parent.Style)

local RAISE = { RightShoulder = { 160, 0, 10 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 20, 0, -30 }, Waist = { -10, 0, 0 } }
local THROW = { RightShoulder = { 90, 0, -30 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 70, 0, 30 }, LeftElbow = { 10, 0, 0 }, Waist = { 5, -25, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	 -- real time: inside the stop only he moves, so his steps run on the wall clock
	local function untilAt(at)
		while os.clock() < at do
			if not c.Valid() then
				return false
			end
			task.wait()
		end
		return true
	end
	local function flat(a, b)
		return (Vector3.new(a.X, b.Y, a.Z) - b).Magnitude
	end

	function api.CanUse(target)
		return c.CanStart(target) and not Time.IsStopped(actor)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(RAISE, 0.12)
			actor:SetAttribute("AttackState", "Golden Eternity")
			local tell = c.Tell(S.Tell)
			c.Send("EternityTell", { Time = tell })
			pcall(Encounter.Say, S.Line, nil, { Duration = 2 })
			if not c.Wait(tell) then
				return false
			end
			local stop = Time.StopTime(actor, S.StopTime)
			if not stop then
				return false
			end
			local started = os.clock()
			local resumeAt = started + S.StopTime
			local function bail()
				if not stop.closed then
					stop:Dispose("cancelled")
				end
				return false
			end
			actor:SetAttribute("AttackState", "Golden Eternity: time has stopped")
			 -- every player's frozen spot: the knives are all turned on these
			local marked, spots = {}, {}
			for _, char in ipairs(c.Targets()) do
				if core.Alive(char) then
					marked[#marked + 1] = { Char = char, Spot = char.HumanoidRootPart.Position }
					spots[#spots + 1] = char.HumanoidRootPart.Position
				end
			end
			if #marked == 0 then
				return bail()
			end
			 -- the map ring: an ellipse just inside the arena's walls; he flashes round it and the knives hang behind him
			local center = c.Ground(Vector3.new(0, 20, 0))
			local hx = (workspace:GetAttribute("ArenaWidth") or 336) / 2 * S.MapInset
			local hz = (workspace:GetAttribute("ArenaDepth") or 240) / 2 * S.MapInset
			local rel = c.Root.Position - center
			local start = math.atan2(rel.Z / hz, rel.X / hx)
			local knives = c.Count(S.FieldKnives)  -- scales with the difficulty's (and the Enraged Gate's) Density
			local fieldSeed = math.random(1, 1e6)
			c.Send("KnifeField", { Center = center, HX = hx, HZ = hz, Count = knives, Volleys = S.Volleys,
				Targets = spots, Sweep = S.Sweep, Start = start, Seed = fieldSeed })
			 -- where each knife hangs: the same numbers the client draws them from (Effects/P5Strikes KnifeField)
			local knifeAt = {}
			do
				local rng = Random.new(fieldSeed)
				for i = 1, knives do
					local u = (i - 1) / knives
					local a = start + u * math.pi * 2 + rng:NextNumber(-0.02, 0.02)
					local s = rng:NextNumber(0.9, 1.03)
					local h = 4 + (i % 3) * 9 + rng:NextNumber(0, 7)
					rng:NextNumber(-1, 1.5)
					knifeAt[i] = center + Vector3.new(math.cos(a) * hx * s, h, math.sin(a) * hz * s)
				end
			end
			 -- (the floor or a wall), and anyone it passes through on the way is cut
			local flying = {}
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.RespectCanCollide = true
			local function excludeList()
				local list = { actor }
				for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
					if p.Character then list[#list + 1] = p.Character end
				end
				return list
			end
			local flyConn
			flyConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
				if not actor.Parent or (#flying == 0 and os.clock() > resumeAt + 60) then
					flyConn:Disconnect()
					return
				end
				if #flying == 0 then return end
				rayParams.FilterDescendantsInstances = excludeList()
				for i = #flying, 1, -1 do
					local k = flying[i]
					local step = k.Speed * dt
					local hitWall = workspace:Raycast(k.Pos, k.Dir * step, rayParams)
					local to = hitWall and hitWall.Position or k.Pos + k.Dir * step
					if not k.Done then
						for _, char in ipairs(c.Targets()) do
							local p = char.HumanoidRootPart.Position
							local seg = to - k.Pos
							local along = math.clamp((p - k.Pos):Dot(seg) / math.max(seg:Dot(seg), 1e-6), 0, 1)
							if (p - (k.Pos + seg * along)).Magnitude <= 3.2 then
								k.Done = true
								c.Hit(char, S.KnifeDamage, p)
								break
							end
						end
					end
					k.Pos = to
					k.Travel += step
					if hitWall or k.Travel > 700 then
						table.remove(flying, i)
					end
				end
			end)
			for i = 1, S.Blinks do
				local a = start + (i - 0.5) / S.Blinks * math.pi * 2
				local at = center + Vector3.new(math.cos(a) * hx * 0.8, 3, math.sin(a) * hz * 0.8)
				if c.Blink(CFrame.lookAt(at, Vector3.new(spots[1].X, at.Y, spots[1].Z))) then
					core.PoseAngles(THROW, 0.04)
				end
				if not untilAt(started + i * S.Sweep / S.Blinks) then
					return bail()
				end
				core.PoseAngles(RAISE, 0.04)
			end
			 -- then point-blank: the cage and the rain round every player
			for _, m in ipairs(marked) do
				if os.clock() > resumeAt - 0.6 then
					break
				end
				if core.Alive(m.Char) and c.Blink(c.Beside(m.Char, S.Distance, math.random() * math.pi * 2)) then
					core.Face(m.Char)
					core.PoseAngles(THROW, 0.04)
					for wave, w in ipairs({ S.Rain }) do
						c.Send("KnifeSet", { Pos = m.Spot, From = c.Root.Position, Kind = w.Kind, Count = c.Count(w.Count), Radius = w.Radius,
							Wave = wave, Seed = math.random(1, 1e6) })
					end
					m.Caged = true
					if not untilAt(os.clock() + S.PerVictim) then
						return bail()
					end
					core.PoseAngles(RAISE, 0.04)
				end
			end
			 -- everything after the stop, in time order
			local events = {}
			local function at(t, fn)
				events[#events + 1] = { At = t, Fn = fn, N = #events }
			end
			for wave, w in ipairs({ S.Rain }) do
				 -- never inside the thaw protection players get as time resumes (EncounterConfig.TimeResumeGrace)
				local fireAt = resumeAt + math.max(w.At, (Config.TimeResumeGrace or 0.4) + 0.05 - w.Flight)
				local lead = w.Deflect == "Hold" and (Config.DeflectHoldTime or 0.2) + 0.4 or (Config.DeflectWarnLead or 0.4)
				at(fireAt - lead, function()
					for _, m in ipairs(marked) do
						if m.Caged and core.Alive(m.Char) then
							c.Warn(m.Char, w.Deflect, lead + 0.1)
						end
					end
				end)
				at(fireAt, function()
					c.Send("KnifeWave", { Wave = wave, Time = w.Flight })
				end)
				at(fireAt + w.Flight, function()
					for _, m in ipairs(marked) do
						local char = m.Char
						if m.Caged and core.Alive(char) and flat(char.HumanoidRootPart.Position, m.Spot) <= S.Reach
							and not c.Deflected(char, w.Deflect) then
							c.Hit(char, w.Damage, m.Spot + Vector3.new(0, 4, 0))
						end
					end
				end)
			end
			at(resumeAt, function()
				if not stop.closed then
					stop:Dispose("completed")
				end
				actor:SetAttribute("AttackState", "Golden Eternity: time resumes")
			end)
			 -- the ring's knives go ONE BY ONE in a shuffled order, each aimed at its player's spot the moment it leaves;
			 -- some are fast (barely a beat to react), some slow. Density scales how many, ProjectileSpeed how quick, Recovery how close together
			local profile = Difficulty.Get(actor) or {}
			local speedK = math.max(profile.ProjectileSpeed or 1, 0.4)
			local gapK = math.max(profile.Recovery or 1, 0.3)
			local order = {}
			for i = 1, knives do order[i] = i end
			for i = knives, 2, -1 do
				local j = math.random(1, i)
				order[i], order[j] = order[j], order[i]
			end
			for n = 1, knives do
				local index = order[n]
				local m = marked[(index - 1) % #marked + 1]  -- the same player the client turned this knife on
				local lo, hi = S.FlightFast, S.FlightMid
				if math.random() >= S.FastChance then lo, hi = S.FlightMid, S.FlightSlow end
				local flight = (lo + math.random() * (hi - lo)) / speedK
				local launch = resumeAt + S.VolleyStart + (n - 1) * S.KnifeGap * gapK
				local aim
				at(launch, function()
					aim = core.Alive(m.Char) and m.Char.HumanoidRootPart.Position or m.Spot
					c.Send("KnifeThrow", { Index = index, Aim = aim, Time = flight })
				end)
				at(launch + flight, function()
					local char = m.Char
					local hit = false
					if aim and core.Alive(char) and flat(char.HumanoidRootPart.Position, aim) <= S.Reach then
						hit = true
						c.Hit(char, S.KnifeDamage, aim + Vector3.new(0, 4, 0))
					end
					 -- and on it goes past the mark, at the speed it arrived with, until it lands on something
					local from = knifeAt[index]
					if aim and from then
						local dir = aim - from
						if dir.Magnitude > 1 then
							local dist = dir.Magnitude
							flying[#flying + 1] = { Pos = aim, Dir = dir.Unit, Speed = math.max(2 * dist / flight, 60), Travel = 0, Done = hit }
						end
					end
				end)
			end
			table.sort(events, function(a, b)
				return a.At < b.At or (a.At == b.At and a.N < b.N)
			end)
			 -- he waits it out a little way off, facing the first of them
			if core.Alive(marked[1].Char) then
				c.Blink(c.Beside(marked[1].Char, 26, math.random() * math.pi * 2))
				core.Face(marked[1].Char)
			end
			core.PoseAngles(RAISE, 0.1)
			for _, e in ipairs(events) do
				if not untilAt(e.At) then
					return bail()
				end
				e.Fn()
			end
			actor:SetAttribute("P5GoldenEternities", (actor:GetAttribute("P5GoldenEternities") or 0) + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end

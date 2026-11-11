local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local S = require(script.Parent.Style)
local Run = game:GetService("RunService")
local UP = Vector3.yAxis
local CALL = { RightShoulder = { 160, 0, 30 }, LeftShoulder = { 160, 0, -30 }, Waist = { -15, 0, 0 } }
local TAU = math.pi * 2
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local running, token, conn = false, nil, nil
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	local function stop()
		if conn then conn:Disconnect() conn = nil end
		token, running = nil, false
		actor:SetAttribute("P5BG_" .. S.Name, nil)
	end
	 -- waits inside the background cast; false once it was cancelled (Dispose, a new phase) or the fight moved on
	local function hold(mine, seconds)
		return c.Over(seconds, function()
			if token ~= mine then return false end
		end) and token == mine
	end
	function api.CanUse(target)
		return c.CanStart(target) and not running
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Star Shooter")
			core.Face(target)
			core.PoseAngles(CALL, 0.12)
			local profile = Difficulty.Get(actor) or {}
			local n = math.max(2, c.Count(S.Stars))
			local tell = c.Tell(S.Tell)
			local every = S.Every * (profile.Recovery or 1)
			local speedK = math.max(profile.ProjectileSpeed or 1, 0.4)
			local spamVolleys = math.max(3, c.Count(S.SpamVolleys))
			local born = workspace:GetServerTimeNow()
			local orbit0, spin0 = math.random() * TAU, math.random() * TAU
			local total = tell + S.Volleys * every + spamVolleys * S.SpamGap + 2
			c.Fx("P5Ascend", "StarRing", { Stars = n, Points = S.Points, Radius = S.Radius, Height = S.Height, Reach = S.Reach, Orbit = S.Orbit, Spin = S.Spin,
				Orbit0 = orbit0, Spin0 = spin0, Born = born, Time = total, Tell = tell })
			sound("RoyalSummon")
			 -- where every point of every star is, t seconds after the cast began (VFXEngine P5Ascend.StarRing draws the same)
			local function points(t)
				local list = {}
				local rootPos = c.Root.Position
				for k = 1, n do
					local oa = orbit0 + S.Orbit * t + (k - 1) / n * TAU
					local center = rootPos + Vector3.new(math.cos(oa), 0, math.sin(oa)) * S.Radius + UP * S.Height
					local spin = spin0 + S.Spin * t + (k - 1) * 0.7
					for j = 1, S.Points do
						local pa = spin + (j - 1) / S.Points * TAU
						local dir = Vector3.new(math.cos(pa), 0, math.sin(pa))
						list[#list + 1] = { Origin = center + dir * S.Reach, Dir = dir }
					end
				end
				return list
			end
			local mine = {}
			token, running = mine, true
			actor:SetAttribute("P5BG_" .. S.Name, true)
			local shots = {}
			local function fire(speed, damage)
				local list = points(workspace:GetServerTimeNow() - born)
				local send = {}
				 -- each shot flies until it meets something solid (a wall, a pillar, the floor)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.RespectCanCollide = true
				local ex = { actor }
				for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
					if pl.Character then ex[#ex + 1] = pl.Character end
				end
				params.FilterDescendantsInstances = ex
				for i, p in ipairs(list) do
					local wall = workspace:Raycast(p.Origin, p.Dir * S.ShotRange, params)
					local len = wall and wall.Distance or S.ShotRange
					shots[#shots + 1] = { Origin = p.Origin, Dir = p.Dir, Speed = speed, Damage = damage, At = os.clock(), Done = false, Len = len }
					send[i] = { Origin = p.Origin, Dir = p.Dir, Len = len }
				end
				c.Fx("P5Ascend", "StarShots", { List = send, Speed = speed, Range = S.ShotRange })
				sound("RangedLaunch")
			end
			 -- the small stars fly straight out of the points and hurt whoever they touch (once each)
			conn = Run.Heartbeat:Connect(function(dt)
				if token ~= mine or not c.Valid() then
					stop()
					return
				end
				local targets = c.Targets()
				local nowClock = os.clock()
				for i = #shots, 1, -1 do
					local s = shots[i]
					local dist = s.Speed * (nowClock - s.At)
					if s.Done or dist > s.Len then
						table.remove(shots, i)
					else
						local p0 = s.Origin + s.Dir * math.max(dist - s.Speed * dt, 0)
						local p1 = s.Origin + s.Dir * dist
						local seg = p1 - p0
						local len2 = seg:Dot(seg)
						for _, char in ipairs(targets) do
							local pos = char.HumanoidRootPart.Position
							local t = len2 > 1e-4 and math.clamp((pos - p0):Dot(seg) / len2, 0, 1) or 0
							if (pos - (p0 + seg * t)).Magnitude <= S.ShotRadius + 1.6 then
								s.Done = true
								c.Hit(char, s.Damage, p1)
								break
							end
						end
					end
				end
			end)
			task.spawn(function()
				local ok, err = pcall(function()
					if not hold(mine, tell) then return end
					for _ = 1, S.Volleys do
						fire(S.ShotSpeed * speedK, S.ShotDamage)
						if not hold(mine, every) then return end
					end
					for _ = 1, spamVolleys do
						fire(S.SpamSpeed * speedK, S.SpamDamage)
						if not hold(mine, S.SpamGap) then return end
					end
					hold(mine, 4)
				end)
				if not ok then warn("[" .. S.Name .. "] " .. tostring(err)) end
				if token == mine then
					actor:SetAttribute("P5StarShooterRuns", (actor:GetAttribute("P5StarShooterRuns") or 0) + 1)
					stop()
				end
			end)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose()
		stop()
	end
	return api
end

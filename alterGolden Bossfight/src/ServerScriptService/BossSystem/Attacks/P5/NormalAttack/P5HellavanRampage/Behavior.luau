local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Effects = require(B.Combat.EffectService)
local Audio = require(B.Presentation.CombatAudio)
local Placement = require(B.Encounter.ArenaPlacement)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)
local Runtime = require(B.Combat.CombatRuntime)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local function holdLead() return (Config.DeflectHoldTime or 0.2) + 0.45 end

local ROAR = { RightShoulder = { 40, 0, 70 }, RightElbow = { 30, 0, 0 }, LeftShoulder = { 40, 0, -70 }, LeftElbow = { 30, 0, 0 },
	Waist = { -25, 0, 0 }, RightHip = { -20, 0, 0 }, RightKnee = { 30, 0, 0 }, LeftHip = { -20, 0, 0 }, LeftKnee = { 30, 0, 0 } }
local SLASH_A = { RightShoulder = { 95, 0, 80 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 30, 0, -40 }, Waist = { 15, 50, 0 },
	RightHip = { -45, 0, 0 }, RightKnee = { 40, 0, 0 }, LeftHip = { 25, 0, 0 } }
local SLASH_B = { RightShoulder = { 90, 0, -70 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 30, 0, -40 }, Waist = { 15, -50, 0 },
	RightHip = { 25, 0, 0 }, LeftHip = { -45, 0, 0 }, LeftKnee = { 40, 0, 0 } }
local DRAW = { RightShoulder = { 30, 0, 100 }, RightElbow = { 20, 0, 0 }, LeftShoulder = { 60, 0, -30 }, Waist = { 10, 70, 0 },
	RightHip = { -50, 0, 0 }, RightKnee = { 70, 0, 0 }, LeftHip = { -10, 0, 0 }, LeftKnee = { 30, 0, 0 } }
local CUT = { RightShoulder = { 90, 0, -80 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 20, 0, -30 }, Waist = { 20, -70, 0 },
	RightHip = { 30, 0, 0 }, LeftHip = { -50, 0, 0 }, LeftKnee = { 60, 0, 0 } }
local STAB = { RightShoulder = { 40, 0, 5 }, RightElbow = { 30, 0, 0 }, RightWrist = { -80, 0, 0 }, LeftShoulder = { 40, 0, -5 },
	LeftElbow = { 30, 0, 0 }, Waist = { 38, 0, 0 }, RightHip = { -45, 0, 0 }, RightKnee = { 75, 0, 0 }, LeftHip = { -30, 0, 0 },
	LeftKnee = { 60, 0, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function send(stage, data)
		data.Boss = actor
		Net.Send("P5Arsenal", stage, data)
	end
	local function knock(dir, speed, lift)
		return { Direction = dir, Speed = speed, Lift = lift, Duration = 0.3, Sustain = 0.1, AllowPlayerControl = false, ContainsArena = true }
	end
	 -- the tall wall of force: a ring rolling out from `center`; it can't be jumped (HOLD E as it reaches you, or dash)
	local function wallWave(center)
		send("RampageWall", { Pos = center, Speed = S.WallSpeed, Range = S.WallRange, Height = S.WallHeight })
		local cast = Effects.NewCast(actor, "P5RampageWall", S.WallRange / S.WallSpeed + 0.5)
		cast.PersistsThroughEmitterStun = true
		local hit, cued, radius = {}, {}, 0
		cast:Step(function(dt)
			if actor:GetAttribute("Phase") ~= 5 then
				cast:Dispose()
				return false
			end
			local last = radius
			radius = math.min(radius + S.WallSpeed * dt, S.WallRange)
			for _, char in ipairs(c.Targets()) do
				if not hit[char] then
					local rel = char.HumanoidRootPart.Position - center
					local d = (rel * FLAT).Magnitude
					if not cued[char] and d > radius and d - radius <= S.WallSpeed * holdLead() and d <= S.WallRange then
						cued[char] = true
						c.Warn(char, "Hold", (d - radius) / S.WallSpeed + 0.1)
					end
					if d >= last - S.WallWidth and d <= radius + 1 and rel.Y <= S.WallHeight then
						hit[char] = true
						if not c.Deflected(char, "Hold") then
							c.Hit(char, S.WallDamage, center + Vector3.new(0, 2, 0), { Knock = knock(rel * FLAT, 45, 16) })
						end
					end
				end
			end
			if radius >= S.WallRange then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			local root = c.Root
			core.Face(target)
			core.PoseAngles(ROAR, 0.12)
			actor:SetAttribute("AttackState", "Hellavan Rampage: the roar")
			local roar = math.max(0.8, c.Tell(S.Roar))
			send("RampageRoar", { Time = roar + S.SprintTime + S.Lock + 0.6 })
			pcall(Audio.Emit, actor, "P1ShieldBreakScream", root)
			core.ScreenEffect("Shake", { Origin = root.Position, Radius = 260, Intensity = 1.4, Duration = roar })
			for _, char in ipairs(c.Targets()) do
				local rel = (char.HumanoidRootPart.Position - root.Position) * FLAT
				if rel.Magnitude <= S.RoarPush and core.CanHit(char, root.Position) then
					pcall(Runtime.Knockback, actor, char, rel.Magnitude > 0.1 and rel or root.CFrame.LookVector, knock(nil, 55, 10))
				end
			end
			if not c.Wait(roar) then
				return false
			end
			 -- 2. the rampage: he runs them down, cutting the whole way
			actor:SetAttribute("AttackState", "Hellavan Rampage!")
			send("RampageSprint", { Time = S.SprintTime })
			local swing, next = 0, 0
			local hitAt = {}
			if not c.Over(S.SprintTime, function(alpha, dt)
				if not core.Alive(target) then
					target = c.RandomTarget() or target
				end
				local goal = target.HumanoidRootPart.Position
				local d = (goal - root.Position) * FLAT
				local dir = d.Magnitude > 0.1 and d.Unit or (root.CFrame.LookVector * FLAT).Unit
				local step = math.min(math.max(d.Magnitude - 5, 0), S.SprintSpeed * dt)
				local p = root.Position + dir * step
				local valid = Placement.Validate(actor, CFrame.lookAt(p, p + dir), { Margin = 6 })
				if valid then
					p = Vector3.new(valid.X, root.Position.Y, valid.Z)
				else
					p = root.Position
				end
				root.CFrame = CFrame.lookAt(p, p + dir)
				root.AssemblyLinearVelocity = Vector3.zero
				next -= dt
				if next <= 0 then
					next = S.SlashEvery
					swing += 1
					core.PoseAngles(swing % 2 == 0 and SLASH_A or SLASH_B, 0.06)
					local frame = root.CFrame
					send("RampageSlash", { Frame = frame, Index = swing })
					for _, char in ipairs(c.Targets()) do
						local pos = char.HumanoidRootPart.Position
						local rel = frame:PointToObjectSpace(pos)
						if -rel.Z > 0 and -rel.Z <= S.SlashReach + 12 then
							c.Warn(char, "Tap", S.SlashEvery + 0.12)  -- the shield stays up while he bears down on them
						end
						if c.InArc(frame, pos, S.SlashReach, S.SlashAngle, 8) and (hitAt[char] or 0) <= os.clock() - 0.2 then
							hitAt[char] = os.clock()
							if not c.Deflected(char, "Tap") then
								c.Hit(char, S.SlashDamage, frame.Position, { Knock = knock(frame.LookVector, 22, 6) })
							end
						end
					end
					if swing % 2 == 0 then
						pcall(Audio.Emit, actor, "NormalSwing", root)
					end
				end
			end) then
				return false
			end
			 -- 3. he stops dead and locks onto a path
			core.PoseAngles(DRAW, 0.08)
			actor:SetAttribute("AttackState", "Hellavan Rampage: locked on")
			local from = root.Position
			local aim = core.Alive(target) and target.HumanoidRootPart.Position or from + root.CFrame.LookVector * 10
			local dir = (aim - from) * FLAT
			dir = dir.Magnitude > 0.1 and dir.Unit or (root.CFrame.LookVector * FLAT).Unit
			local length = S.PathLength
			local wall = workspace:Raycast(from, dir * length, core.Params())
			if wall then
				length = math.max(wall.Distance - 3, 8)
			end
			local goal = c.Ground(from + dir * length)
			length = ((goal - from) * FLAT).Magnitude
			local floor = c.Ground(from)
			local lane = CFrame.lookAt(floor, floor + dir)
			root.CFrame = CFrame.lookAt(from, from + dir)
			local lock = math.max(0.55, c.Tell(S.Lock))
			send("RampageLock", { Frame = lane, Length = length, Width = S.PathWidth, Time = lock, Blast = S.BlastRadius })
			for _, char in ipairs(c.Targets()) do
				local rel = lane:PointToObjectSpace(char.HumanoidRootPart.Position)
				if math.abs(rel.X) <= S.PathWidth + 6 and -rel.Z >= -4 and -rel.Z <= length + 6 then
					c.Warn(char, "Hold", lock + 0.1)
				end
			end
			if not c.Wait(lock) then
				return false
			end
			 -- 4. the cut: down the path in one flash
			core.PoseAngles(CUT, 0.04)
			local to = Vector3.new(goal.X, from.Y, goal.Z)
			send("RampageCut", { Frame = lane, Length = length, Width = S.PathWidth, From = from, To = to })
			pcall(Audio.Emit, actor, "ThrustBurst", root)
			root.CFrame = CFrame.lookAt(to, to + dir)
			root.AssemblyLinearVelocity = Vector3.zero
			core.ScreenEffect("Shake", { Origin = to, Radius = 220, Intensity = 1.1, Duration = 0.3 })
			for _, char in ipairs(c.Targets()) do
				local rel = lane:PointToObjectSpace(char.HumanoidRootPart.Position)
				if math.abs(rel.X) <= S.PathWidth and -rel.Z >= -3 and -rel.Z <= length + 3 and rel.Y <= 12 then
					if not c.Deflected(char, "Hold") then
						local side = rel.X >= 0 and lane.RightVector or -lane.RightVector
						c.Hit(char, S.CutDamage, char.HumanoidRootPart.Position, { Knock = knock(side, 40, 14) })
					end
				end
			end
			 -- 5. the blade goes into the ground at the end of the path, and it all goes off
			core.PoseAngles(STAB, 0.06)
			send("RampageFuse", { Pos = goal, Time = S.Fuse, Radius = S.BlastRadius })
			if not c.Wait(S.Fuse) then
				return false
			end
			send("RampageBlast", { Pos = goal, Radius = S.BlastRadius })
			pcall(Audio.Emit, actor, "GroundErupt", goal)
			core.ScreenEffect("Shake", { Origin = goal, Radius = 320, Intensity = 2, Duration = 0.6 })
			for _, char in ipairs(c.Targets()) do
				local rel = char.HumanoidRootPart.Position - goal
				local flat = rel * FLAT
				if flat.Magnitude <= S.BlastRadius and rel.Y <= 18 then
					c.Hit(char, S.BlastDamage, goal + Vector3.new(0, 2, 0), { Knock = knock(flat.Magnitude > 0.1 and flat or Vector3.zAxis, 60, 30), BreaksBlock = true })
				end
			end
			 -- 6. the wall of force, then the ordinary shockwaves after it
			wallWave(goal)
			if not c.Wait(S.WaveDelay) then  -- the ground waves come once the wall is well on its way
				return false
			end
			for i = 1, S.Waves do
				if i > 1 and not c.Wait(S.WaveGap) then
					return false
				end
				c.Shockwave(goal, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = 3, Height = 4, Damage = S.WaveDamage, Look = "Gold",
					Knock = { Speed = 30, Lift = 16, Duration = 0.25, Sustain = 0.05, AllowPlayerControl = false, ContainsArena = true } })
			end
			actor:SetAttribute("P5HellavanRampages", (actor:GetAttribute("P5HellavanRampages") or 0) + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end

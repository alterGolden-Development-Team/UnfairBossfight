local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Runtime = require(B.Combat.CombatRuntime)
local Placement = require(B.Encounter.ArenaPlacement)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local UP = Vector3.yAxis
local function holdLead() return (Config.DeflectHoldTime or 0.2) + 0.45 end
local SWING_A = { RightShoulder = { 95, 0, 80 }, RightElbow = { 10, 0, 0 }, Waist = { 15, 50, 0 }, RightHip = { -40, 0, 0 }, RightKnee = { 40, 0, 0 } }
local SWING_B = { RightShoulder = { 90, 0, -70 }, RightElbow = { 10, 0, 0 }, Waist = { 15, -50, 0 }, LeftHip = { -40, 0, 0 }, LeftKnee = { 40, 0, 0 } }
local RISE = { RightShoulder = { 170, 0, 10 }, RightElbow = { 0, 0, 0 }, Waist = { -20, 0, 0 } }
local DIVE = { RightShoulder = { 40, 0, 0 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 40, 0, 0 }, Waist = { 45, 0, 0 } }
local SLAM = { RightShoulder = { 30, 0, 0 }, LeftShoulder = { 30, 0, 0 }, Waist = { 40, 0, 0 }, RightHip = { -50, 0, 0 }, RightKnee = { 70, 0, 0 },
	LeftHip = { -30, 0, 0 }, LeftKnee = { 50, 0, 0 } }
local KICK = { RightHip = { 95, 0, 0 }, RightKnee = { 0, 0, 0 }, LeftShoulder = { 40, 0, -60 }, Waist = { -20, 0, 0 } }
local WIND = { LeftShoulder = { 30, 0, 100 }, LeftElbow = { 60, 0, 0 }, Waist = { 0, 40, 0 }, RightHip = { -30, 0, 0 }, RightKnee = { 40, 0, 0 } }
local LUNGE = { LeftShoulder = { 90, 0, -10 }, LeftElbow = { 0, 0, 0 }, Waist = { 20, -30, 0 }, LeftHip = { -50, 0, 0 }, RightHip = { 30, 0, 0 } }
local CALL = { RightShoulder = { 160, 0, 30 }, LeftShoulder = { 160, 0, -30 }, Waist = { -15, 0, 0 } }
 -- a quick slash in front of him: the gold crescent drawn, everyone in the arc hit (TAP deflects)
local function swing(c, index, reach, angle, damage, deflect)
	local core = c.Core
	core.PoseAngles(index % 2 == 0 and SWING_A or SWING_B, 0.05)
	local frame = c.Root.CFrame
	c.Fx("P5Arsenal", "RampageSlash", { Frame = frame, Index = index })
	pcall(Audio.Emit, c.Actor, "NormalSwing", c.Root)
	for _, char in ipairs(c.Targets()) do
		if c.InArc(frame, char.HumanoidRootPart.Position, reach, angle, 9) and not (deflect and c.Deflected(char, deflect)) then
			c.Hit(char, damage, frame.Position, { Knock = { Direction = frame.LookVector, Speed = 24, Lift = 8, Duration = 0.25, Sustain = 0.06,
				AllowPlayerControl = false, ContainsArena = true } })
		end
	end
	return frame
end
 -- the TAP shield for anyone in front of him who is about to be cut
local function cue(c, reach, seconds, kind)
	local frame = c.Root.CFrame
	for _, char in ipairs(c.Targets()) do
		local p = frame:PointToObjectSpace(char.HumanoidRootPart.Position)
		if -p.Z > -3 and -p.Z <= reach + 10 and math.abs(p.X) <= reach + 6 then
			c.Warn(char, kind or "Tap", seconds)
		end
	end
end
 -- slide the boss to `goal` (kept on the arena floor) over `seconds`
local function dash(c, goal, seconds, face)
	local root = c.Root
	local from = root.Position
	goal = Vector3.new(goal.X, from.Y, goal.Z)
	local valid = Placement.Validate(c.Actor, CFrame.new(goal), { Margin = 6 })
	if valid then goal = Vector3.new(valid.X, from.Y, valid.Z) end
	local dir = face or ((goal - from) * FLAT)
	dir = dir.Magnitude > 0.1 and dir.Unit or root.CFrame.LookVector
	return c.Over(seconds, function(alpha)
		local p = from:Lerp(goal, 1 - (1 - alpha) ^ 2)
		root.CFrame = CFrame.lookAt(p, p + dir)
		root.AssemblyLinearVelocity = Vector3.zero
	end), goal
end
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	function api.CanUse(target)
		return c.CanStart(target) and (target.HumanoidRootPart.Position - c.Root.Position).Magnitude <= S.UseRange
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Fang-Pierce")
			c.Fx("P5Ascend", "Flash", { Time = math.max(0.3, c.Tell(S.Flash)) })
			if not c.Wait(math.max(0.3, c.Tell(S.Flash))) then return false end
			if not core.Alive(target) then return c.Wait(0.1) end
			c.Blink(c.Beside(target, 6, math.pi * 0.5))
			core.Face(target)
			local lead = math.max(0.22, c.Tell(S.CrossLead))
			cue(c, S.CrossReach, lead + 0.1)
			if not c.Wait(lead) then return false end
			 -- the cross: two cuts at once
			local frame = swing(c, 1, S.CrossReach, 80, S.CrossDamage, "Tap")
			c.Fx("P5Arsenal", "RampageSlash", { Frame = frame, Index = 2 })
			 -- the backdash, away from the way they walk, with a kick on the way out
			local r = target.HumanoidRootPart
			local walk = r.AssemblyLinearVelocity * FLAT
			local right = c.Root.CFrame.RightVector
			local side = walk.Magnitude > 2 and (walk:Dot(right) > 0 and -right or right) or -c.Root.CFrame.LookVector
			core.PoseAngles(KICK, 0.04)
			for _, char in ipairs(c.Targets()) do
				if c.InArc(c.Root.CFrame, char.HumanoidRootPart.Position, S.KickReach, 60, 8) then
					c.Hit(char, S.KickDamage, c.Root.Position, { Knock = { Direction = c.Root.CFrame.LookVector, Speed = 40, Lift = 12, Duration = 0.25,
						Sustain = 0.06, AllowPlayerControl = false, ContainsArena = true } })
				end
			end
			local face = c.Root.CFrame.LookVector * FLAT
			if not dash(c, c.Root.Position + (side - c.Root.CFrame.LookVector * 0.6).Unit * S.Back, S.BackTime, face) then return false end
			core.Face(target)
			core.PoseAngles(SWING_A, 0.1)
			local from = c.Root.Position
			local dir = ((target.HumanoidRootPart.Position - from) * FLAT)
			dir = dir.Magnitude > 0.1 and dir.Unit or c.Root.CFrame.LookVector
			local lane = CFrame.lookAt(c.Ground(from), c.Ground(from) + dir)
			c.Fx("P5Arsenal", "RampageLock", { Frame = lane, Length = S.Lunge, Width = S.LungeWidth, Time = c.Tell(S.Prepare), Blast = 8 })
			if not c.Wait(c.Tell(S.Prepare)) then return false end
			local to = from + dir * S.Lunge
			c.Fx("P5Arsenal", "RampageCut", { Frame = lane, Length = S.Lunge, Width = S.LungeWidth, From = from, To = to })
			local ok, landed = dash(c, to, S.LungeTime, dir)
			if not ok then return false end
			for _, char in ipairs(c.Targets()) do
				local p = lane:PointToObjectSpace(char.HumanoidRootPart.Position)
				if math.abs(p.X) <= S.LungeWidth and -p.Z >= -2 and -p.Z <= S.Lunge + 2 then
					c.Hit(char, S.LungeDamage, char.HumanoidRootPart.Position)
				end
			end
			 -- and back, cutting all round him
			if not dash(c, from, S.LungeTime, -dir) then return false end
			for k = 1, S.Ring do
				c.Root.CFrame = c.Root.CFrame * CFrame.Angles(0, math.pi * 2 / S.Ring, 0)
				c.Fx("P5Arsenal", "RampageSlash", { Frame = c.Root.CFrame, Index = k })
				for _, char in ipairs(c.Targets()) do
					if ((char.HumanoidRootPart.Position - c.Root.Position) * FLAT).Magnitude <= S.RingRadius then
						c.Hit(char, S.RingDamage, c.Root.Position)
					end
				end
				if not c.Wait(S.RingEvery) then return false end
			end
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end

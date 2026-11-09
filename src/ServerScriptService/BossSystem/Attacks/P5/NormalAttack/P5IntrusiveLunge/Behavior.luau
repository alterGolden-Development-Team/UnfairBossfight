local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
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
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Intrusive Lunge")
			core.Face(target)
			core.PoseAngles(WIND, 0.12)
			local windup = c.Tell(S.Windup)
			c.Fx("P5Strikes", "RiverCharge", { Time = windup })
			if not c.Wait(windup) then return false end
			local from = c.Root.Position
			local dir = ((target.HumanoidRootPart.Position - from) * FLAT)
			dir = dir.Magnitude > 0.1 and dir.Unit or c.Root.CFrame.LookVector
			local length = S.Distance
			local wall = workspace:Raycast(from, dir * length, core.Params())
			if wall then length = math.max(wall.Distance - 3, 4) end
			local to = from + dir * length
			for _, char in ipairs(c.Targets()) do
				local along = (char.HumanoidRootPart.Position - from):Dot(dir)
				if along > 0 and along <= length then
					c.Warn(char, "Tap", along / length * S.Time + 0.12)
				end
			end
			core.PoseAngles(LUNGE, 0.04)
			c.Fx("P5Strikes", "RiverLunge", { From = from, To = to, Time = S.Time })
			pcall(Audio.Emit, actor, "ThrustBurst", c.Root)
			local hit, last = {}, from
			if not c.Over(S.Time, function(a)
				local p = from:Lerp(to, 1 - (1 - a) ^ 2)
				c.Root.CFrame = CFrame.lookAt(p, p + dir)
				c.Root.AssemblyLinearVelocity = Vector3.zero
				for _, char in ipairs(c.Targets()) do
					local q = char.HumanoidRootPart.Position
					local seg = p - last
					local t = seg:Dot(seg) > 1e-4 and math.clamp((q - last):Dot(seg) / seg:Dot(seg), 0, 1) or 0
					if not hit[char] and ((q - (last + seg * t)) * FLAT).Magnitude <= S.Width then
						hit[char] = true
						if not c.Deflected(char, "Tap") then
							c.Hit(char, S.Damage, p, { Knock = { Direction = dir, Speed = 45, Lift = 12, Duration = 0.3, Sustain = 0.08,
								AllowPlayerControl = false, ContainsArena = true } })
						end
					end
				end
				last = p
			end) then return false end
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end

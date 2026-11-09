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
		return c.CanStart(target) and (target.HumanoidRootPart.Position - c.Root.Position).Magnitude <= S.UseRange
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Fang-Cross")
			core.Face(target)
			c.Fx("P5Ascend", "Flash", { Time = math.max(0.3, c.Tell(S.Flash)) })
			if not c.Wait(math.max(0.3, c.Tell(S.Flash))) then return false end
			for i = 1, 2 do
				if not core.Alive(target) then break end
				 -- each swipe steps toward where they are heading
				local r = target.HumanoidRootPart
				local aim = r.Position + r.AssemblyLinearVelocity * FLAT * S.Predict
				local dir = (aim - c.Root.Position) * FLAT
				dir = dir.Magnitude > 0.1 and dir.Unit or c.Root.CFrame.LookVector
				cue(c, S.SwipeReach + S.Step, S.StepTime + 0.15)
				local ok = dash(c, c.Root.Position + dir * math.min(S.Step, math.max((aim - c.Root.Position).Magnitude - 4, 0)), S.StepTime, dir)
				if not ok then return false end
				swing(c, i, S.SwipeReach, S.SwipeAngle, S.SwipeDamage, "Tap")
				if not c.Wait(0.12) then return false end
			end
			core.Face(target)
			core.PoseAngles(RISE, 0.1)
			local point = c.Ground((c.Root.CFrame * CFrame.new(0, 0, -S.SlamReach)).Position)
			c.Fx("P5Arsenal", "RampageFuse", { Pos = point, Time = c.Tell(S.SlamTell), Radius = S.SlamRadius })
			if not c.Wait(c.Tell(S.SlamTell)) then return false end
			core.PoseAngles(SLAM, 0.04)
			c.Fx("P5Strikes", "VerticalSwing", { Frame = c.Root.CFrame })
			c.Explode(point, S.SlamRadius, S.SlamDamage, { Shake = 1.2 })
			c.Shockwave(point, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = 3, Height = 4, Damage = S.WaveDamage, Look = "Gold",
				Knock = { Speed = 30, Lift = 16, Duration = 0.25, Sustain = 0.05, AllowPlayerControl = false, ContainsArena = true } })
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end

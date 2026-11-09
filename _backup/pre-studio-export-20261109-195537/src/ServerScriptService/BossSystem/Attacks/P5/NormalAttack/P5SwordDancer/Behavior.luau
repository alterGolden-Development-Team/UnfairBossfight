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
	 -- he is free - walking and starting his other attacks - while the rings keep forming and cutting on their own
	local running, token = false, nil
	local function hold(mine, seconds)
		return c.Over(seconds, function()
			if token ~= mine then return false end
			if actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("PhaseTransitionInProgress") then return false end
		end) and token == mine
	end
	local function ring(mine, target)
		local center = c.Ground(target.HumanoidRootPart.Position)
		local n = c.Count(S.Swords)
		local spin = math.random() * math.pi * 2
		local swords = {}
		for i = 1, n do
			local a = spin + (i - 1) * math.pi * 2 / n
			swords[i] = center + Vector3.new(math.cos(a), 0, math.sin(a)) * S.Radius + UP * S.Height
		end
		local aim = c.Tell(S.Aim)
		c.Fx("P5Ascend", "SwordRing", { Points = swords, Center = center + UP * 2.5, Time = aim, Stagger = S.Stagger, Speed = S.Speed,
			Reach = S.Radius * 2 })
		if not hold(mine, aim) then return false end
		 -- they fly: everyone near a sword's line as it passes is cut (a few times at most)
		local hits = {}
		local flight = S.Radius * 2 / S.Speed
		local t = 0
		return c.Over(flight + n * S.Stagger, function(_, dt)
			if token ~= mine then return false end
			t += dt
			for i, from in ipairs(swords) do
				local u = t - (i - 1) * S.Stagger
				if u > 0 and u <= flight then
					local dir = ((center + UP * 2.5) - from).Unit
					local p = from + dir * S.Speed * u
					for _, char in ipairs(c.Targets()) do
						local key = char.Name .. i
						if not hits[key] and (char.HumanoidRootPart.Position - p).Magnitude <= S.Width + 1
							and (hits[char] or 0) < S.MaxHits then
							hits[key] = true
							hits[char] = (hits[char] or 0) + 1
							if not c.Deflected(char, "Tap") then
								c.Hit(char, S.Damage, p)
							end
						end
					end
				end
			end
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
			actor:SetAttribute("AttackState", "Sword Dancer")
			core.Face(target)
			core.PoseAngles(CALL, 0.12)
			local mine = {}
			token, running = mine, true
			actor:SetAttribute("P5BG_" .. S.Name, true)
			task.spawn(function()
				local ok, err = pcall(function()
					local who = target
					for round = 1, S.Summons do
						if not who or not core.Alive(who) then who = c.RandomTarget() end
						if not who then break end
						if not ring(mine, who) then break end
						if round < S.Summons and not hold(mine, S.RoundGap) then break end
						who = c.RandomTarget() or who  -- each new ring forms round someone (anyone) again
					end
				end)
				if not ok then warn("[" .. S.Name .. "] " .. tostring(err)) end
				if token == mine then running = false actor:SetAttribute("P5BG_" .. S.Name, nil) end
			end)
			return c.Wait(0.35)  -- just the call: he moves on straight away
		end)
	end
	function api.Dispose()
		token, running = nil, false
		actor:SetAttribute("P5BG_" .. S.Name, nil)
	end
	return api
end

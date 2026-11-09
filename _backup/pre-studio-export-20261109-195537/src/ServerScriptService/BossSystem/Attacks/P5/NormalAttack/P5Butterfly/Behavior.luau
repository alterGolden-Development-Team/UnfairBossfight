local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Placement = require(B.Encounter.ArenaPlacement)
local S = require(script.Parent.Style)

local CROUCH = { RightShoulder = { -30, 0, 30 }, LeftShoulder = { -30, 0, -30 }, Waist = { 20, 0, 0 },
	RightHip = { -40, 0, 0 }, RightKnee = { 60, 0, 0 }, LeftHip = { -40, 0, 0 }, LeftKnee = { 60, 0, 0 } }
 -- the dive is a sword thrust: drawn back while he takes aim, then the arm and blade drive straight out
local DRAW = { RightShoulder = { 15, 0, 15 }, RightElbow = { 75, 0, 0 }, RightWrist = { -60, 0, 0 }, Waist = { 5, 20, 0 },
	LeftShoulder = { -10, 0, -20 }, LeftElbow = { 50, 0, 0 } }
local THRUST = { RightShoulder = { 55, 0, -8 }, RightElbow = { 8, 0, 0 }, RightWrist = { -63, 0, 0 }, Waist = { 12, -20, 0 },
	LeftShoulder = { -20, 0, -15 }, LeftElbow = { 35, 0, 0 }, LeftHip = { -18, 0, 0 }, RightHip = { 22, 0, 0 } }

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
		local r = target and target:FindFirstChild("HumanoidRootPart")
		return c.CanStart(target) and r ~= nil
			and (r.Position - c.Root.Position).Magnitude <= S.NearRange
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			local root = c.Root
			core.Face(target)
			actor:SetAttribute("AttackState", "Butterfly: taking wing")
			core.PoseAngles(CROUCH, 0.1)
			 -- his own Phase 5 wings carry it: they lift and beat hard while gold light and butterflies come off them
			local wingTime = S.JumpTime + S.Hover + S.DashTime + 0.5
			pcall(function() require(B.Phases.Phase5Transition).BeatWings(actor, wingTime) end)
			c.Send("Wings", { Time = wingTime })
			 -- spring backward up into the air
			local start = root.CFrame
			local rootHeight = math.clamp(start.Position.Y - c.Ground(start.Position).Y, 2, 6)  -- root above the floor
			local landing = Placement.Validate(actor, start * CFrame.new(0, 0, S.BackDistance), { Margin = 6 }) or start
			local apex = landing + Vector3.new(0, S.JumpHeight, 0)
			if not c.Over(S.JumpTime, function(alpha)
				local lift = math.sin(alpha * math.pi / 2)
				root.CFrame = start:Lerp(landing, alpha) + Vector3.new(0, S.JumpHeight * lift, 0)
				root.AssemblyLinearVelocity = Vector3.zero
			end) then
				return false
			end
			 -- hang there with the wings open and take aim
			core.PoseAngles(DRAW, 0.12)
			local hover = c.Tell(S.Hover)
			for _, char in ipairs(c.Targets()) do  -- Tap Deflect for anyone the dive can reach
				if (char.HumanoidRootPart.Position - root.Position).Magnitude <= S.ThrustRange + 14 then
					c.Warn(char, "Tap", hover + S.DashTime + 0.15)
				end
			end
			local destination
			if not c.Over(hover, function()
				if not core.Alive(target) then
					target = core.Melee.GetTarget()
				end
				if target then
					local r = target.HumanoidRootPart
					local aim = r.Position + r.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * S.Lead
					destination = c.Ground(aim)
					local flat = Vector3.new(aim.X - apex.X, 0, aim.Z - apex.Z)
					root.CFrame = flat.Magnitude > 0.1 and CFrame.lookAt(apex.Position, apex.Position + flat) or apex
				else
					root.CFrame = apex
				end
				root.AssemblyLinearVelocity = Vector3.zero
			end) or not destination then
				return false
			end
			 -- the dive: straight through their spot to just past it
			local from = root.Position
			local flat = Vector3.new(destination.X - from.X, 0, destination.Z - from.Z)
			local direction = flat.Magnitude > 0.1 and flat.Unit or root.CFrame.LookVector * Vector3.new(1, 0, 1)
			if flat.Magnitude > S.ThrustRange then  -- it only reaches so far
				destination = c.Ground(Vector3.new(from.X, destination.Y, from.Z) + direction * S.ThrustRange)
			end
			local finish = destination + Vector3.new(0, rootHeight, 0) + direction * S.Overshoot
			local wall = workspace:Raycast(from, finish - from, core.Params())
			if wall then
				finish = wall.Position - (finish - from).Unit * 3
			end
			local frame = Placement.Validate(actor, CFrame.lookAt(finish, finish + direction), { Margin = 6 })
			finish = frame and frame.Position or finish
			c.Send("ButterflyDash", { From = from, To = finish, Time = S.DashTime })
			core.PoseAngles(THRUST, 0.05)
			actor:SetAttribute("AttackState", "Butterfly: the thrust")
			local hit = {}
			local last = from
			if not c.Over(S.DashTime, function(alpha)
				local position = from:Lerp(finish, alpha)
				root.CFrame = CFrame.lookAt(position, position + direction)
				root.AssemblyLinearVelocity = Vector3.zero
				for _, char in ipairs(c.Targets()) do
					if not hit[char] and segmentDistance(char.HumanoidRootPart.Position, last, position) <= S.HitRadius then
						hit[char] = true
						if not c.Deflected(char, "Tap") then c.Hit(char, S.Damage, last) end
					end
				end
				last = position
			end) then
				return false
			end
			 -- the landing bursts in wings: anyone right there who the dive missed is caught too
			c.Send("ButterflyBurst", { Pos = c.Ground(finish), Radius = S.BurstRadius })
			core.ScreenEffect("Shake", { Origin = finish, Radius = 80, Intensity = 0.4, Duration = 0.2 })
			for _, char in ipairs(c.Targets()) do
				if not hit[char] and (char.HumanoidRootPart.Position - finish).Magnitude <= S.BurstRadius then
					hit[char] = true
					c.Hit(char, S.Damage, finish + Vector3.new(0, 2, 0))
				end
			end
			actor:SetAttribute("P5ButterflyDives", (actor:GetAttribute("P5ButterflyDives") or 0) + 1)
			return c.Wait(0.25)
		end)
	end
	function api.Dispose() end
	return api
end

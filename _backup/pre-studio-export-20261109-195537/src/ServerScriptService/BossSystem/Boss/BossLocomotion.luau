local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Effects = require(BossSystem.Combat.EffectService)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local api = {}
local records = {}
local scheduler
local aliases = {
	["Right Shoulder"] = "RightShoulder",
	["Left Shoulder"] = "LeftShoulder",
	["Right Hip"] = "RightHip",
	["Left Hip"] = "LeftHip",
	RootJoint = "Waist",
}
local bones = {
	RightShoulder = true,
	LeftShoulder = true,
	RightElbow = true,
	LeftElbow = true,
	RightWrist = true,
	LeftWrist = true,
	RightHip = true,
	LeftHip = true,
	RightKnee = true,
	LeftKnee = true,
	RightAnkle = true,
	LeftAnkle = true,
	Waist = true,
	Neck = true,
	Root = true,  -- R15 LowerTorso to root: only moved by the float lift
}
 
 
local idle = {
	RightShoulder = { 12, -6, -8 },
	RightElbow = { 22, 0, 0 },
	RightWrist = { -10, 0, 3 },
	LeftShoulder = {
		-3,
		0,
		-4,
	},
}
local function priority(record, name)
	if record.Priority == name then
		return
	end
	record.Priority = name
	record.Actor:SetAttribute("BossAnimationPriority", name)
end
local function radians(a)
	return CFrame.Angles(math.rad(a[1]), math.rad(a[2]), math.rad(a[3]))
end
local function offset(joint, angles, translation)
	local physical = angles and radians(angles) or CFrame.identity
	 
	 
	return CFrame.new(translation or Vector3.zero) * joint.Origin * physical * joint.Basis
end
local function angles(pose, name, x, y, z)
	local value = pose[name]
	value[1] = x
	value[2] = y
	value[3] = z
end
local function drop(actor)
	local record = records[actor]
	if not record then
		return
	end
	for _, joint in pairs(record.Joints) do
		if joint.Motor.Parent then
			joint.Motor.C0 = joint.Base
		end
	end
	records[actor] = nil
end
local function locomotionPose(record, dt)
	local root = record.Root
	local displacement = root.Position - record.LastPosition
	record.LastPosition = root.Position
	local distance = Vector3.new(displacement.X, 0, displacement.Z).Magnitude
	 
	local measuredSpeed = distance < 8 and dt > 0 and distance / dt or 0
	if record.Moving and distance < 8 then
		record.Phase = (record.Phase + distance * 0.42) % (math.pi * 2)
	end
	 
	 
	local speed = record.MovementSpeed or measuredSpeed
	local moving = record.Moving and measuredSpeed > 0.3
	local walkSpeed = Config.BossWalkSpeed or 18
	local runSpeed = math.max(walkSpeed + 1, Config.BossRunSpeed or 32)
	local targetGait = moving and math.clamp(measuredSpeed / walkSpeed, 0, 1) or 0
	local targetRun = moving and math.clamp((speed - walkSpeed) / (runSpeed - walkSpeed), 0, 1) or 0
	local blend = 1 - math.exp(-10 * dt)
	record.Gait += (targetGait - record.Gait) * blend
	record.RunWeight += (targetRun - record.RunWeight) * blend
	local gait = record.Gait
	local run = record.RunWeight
	local wave = math.sin(record.Phase)
	local swing = wave * gait
	local recoil = math.cos(record.Phase) * gait
	local breath = math.sin(record.IdleClock * 1.75) * (1 - gait)
	local bodySway = math.sin(record.Phase * 2) * gait
	local lateral = distance < 8 and dt > 0 and root.CFrame:VectorToObjectSpace(displacement / dt).X or 0
	record.SideLean += (math.clamp(-lateral / runSpeed, -1, 1) * 3 - record.SideLean) * blend
	 
	 
	local pose = record.LocomotionPose
	local singleArm = record.SingleArm
	angles(
		pose,
		"RightShoulder",
		12 + (singleArm and 9 or 0) + run * 8 - swing * (12 + run * 9),
		-6 - bodySway * 2,
		-8 - run * 4 + recoil * 2 + breath * 0.6
	)
	angles(pose, "RightElbow", 22 + run * 12 + recoil * (5 + run * 3), 0, 0)
	angles(pose, "RightWrist", -10 - run * 4 - recoil * 3, bodySway * 1.5, 3)
	angles(pose, "LeftShoulder", -3 + swing * (28 + run * 12), bodySway * 2, -4 - run * 4)
	angles(pose, "LeftElbow", gait * (12 + run * 18) + math.max(0, swing) * 8, 0, 0)
	if record.Actor:GetAttribute("UnarmedCombat") then
		 
		 
		angles(pose, "RightShoulder", -12 + run * 8 - swing * (27 + run * 10), -4, -12 + breath)
		angles(pose, "RightElbow", 18 + run * 12 + math.max(0, -swing) * 10, 0, 0)
		angles(pose, "RightWrist", -4, 0, 0)
		angles(pose, "LeftShoulder", -12 + run * 8 + swing * (27 + run * 10), 4, 12 - breath)
		angles(pose, "LeftElbow", 18 + run * 12 + math.max(0, swing) * 10, 0, 0)
	end
	angles(pose, "RightHip", swing * (28 + run * 12), 0, 0)
	angles(pose, "LeftHip", -swing * (28 + run * 12), 0, 0)
	angles(pose, "RightKnee", math.max(0, -swing) * (22 + run * 12), 0, 0)
	angles(pose, "LeftKnee", math.max(0, swing) * (22 + run * 12), 0, 0)
	angles(pose, "RightAnkle", -math.max(0, -swing) * 7, 0, 0)
	angles(pose, "LeftAnkle", -math.max(0, swing) * 7, 0, 0)
	angles(
		pose,
		"Waist",
		gait * (3 + run * 5) + breath * 0.35,
		bodySway * (2 + run * 2),
		-swing * 1.5 + record.SideLean
	)
	angles(pose, "Neck", -gait * (2 + run * 4) - breath * 0.25, -bodySway, swing * 0.6 - record.SideLean * 0.4)
	return pose, Vector3.new(0, (1 - math.cos(record.Phase * 2)) * gait * 0.035 + breath * 0.015, 0)
end
 -- Phase 5 Space mode (P5ModeService sets P5Floating): he floats. The body rides a slow bob above the ground on
 -- the joint under the root while the legs hang loose, toes down, whether he walks or attacks; eased in and out.
local DANGLE = { RightHip = { -10, 0, 4 }, LeftHip = { 6, 0, -4 }, RightKnee = { 30, 0, 0 }, LeftKnee = { 18, 0, 0 },
	RightAnkle = { -28, 0, 0 }, LeftAnkle = { -22, 0, 0 } }
local function floating(record, pose, dt)
	local want = record.Actor:GetAttribute("P5Floating") and 1 or 0
	record.Float = (record.Float or 0) + (want - (record.Float or 0)) * (1 - math.exp(-4 * dt))
	local f = record.Float
	if f < 0.01 then
		record.Lift = nil
		return pose
	end
	local t = record.IdleClock
	record.Lift = Vector3.new(0, f * ((Config.P5FloatHeight or 3.4) + math.sin(t * 2.2) * 0.35), 0)
	local out = record.FloatPose or {}
	record.FloatPose = out
	for name in pairs(bones) do
		local a, d = pose[name], DANGLE[name]
		if d then
			local sway = math.sin(t * 1.6 + (name:find("Left", 1, true) and 1.3 or 0)) * 4
			local v = out[name] or { 0, 0, 0 }
			local x, y, z = a and a[1] or 0, a and a[2] or 0, a and a[3] or 0
			v[1], v[2], v[3] = x + (d[1] + sway - x) * f, y + (d[2] - y) * f, z + (d[3] - z) * f
			out[name] = v
		else
			out[name] = a
		end
	end
	return out
end
local function stopApproach(record)
	record.ApproachTarget = nil
	record.ApproachHumanoid = nil
	record.ApproachCharacter = nil
	if not record.Approaching then
		return
	end
	record.Approaching = false
	record.Moving = false
	record.MovementSpeed = nil
	record.Blend = 0.18
	if not record.Action and record.Actor.Parent then
		priority(record, "Idle")
	end
end
local function approachAllowed(record)
	local actor = record.Actor
	return actor.Parent
		and record.Root.Parent
		and record.Humanoid.Health > 0
		and not record.Action
		and not actor:GetAttribute("AttackInProgress")
		and not actor:GetAttribute("PhaseTransitionInProgress")
		and not actor:GetAttribute("ShieldBreakInProgress")
		and actor:GetAttribute("AIEnabled") ~= false
		and not actor:GetAttribute("TimeFrozen")
  and workspace:GetServerTimeNow()>=(actor:GetAttribute("ClassStunnedUntil") or 0)
		and not actor:GetAttribute("EncounterEnded")
end
local function driveApproach(record, dt)
	if not record.ApproachTarget then
		return
	end
	local target = record.ApproachTarget
	if
		not approachAllowed(record)
		or not target.Parent
		or not record.ApproachCharacter.Parent
		or not record.ApproachHumanoid.Parent
		or record.ApproachHumanoid.Health <= 0
		or workspace:GetServerTimeNow() > record.ApproachUntil
	then
		stopApproach(record)
		return
	end
	local root = record.Root
	local delta = target.Position - root.Position
	delta = Vector3.new(delta.X, 0, delta.Z)
	local stop = Config.BossApproachStopDistance or 8
	if delta.Magnitude <= stop + 0.1 then
		stopApproach(record)
		return
	end
	local speed = Config.BossWalkSpeed or 18
	local direction = delta.Unit
	local stride = math.min(speed * math.min(dt, 0.1), delta.Magnitude - stop)
	local destination = root.Position + direction * stride
	local ground = Placement.GroundPoint(destination, { Margin = 4 })
	if not ground or math.abs(ground.Y + record.StandingHeight - root.Position.Y) > 4 then
		stopApproach(record)
		return
	end
	destination = Vector3.new(destination.X, ground.Y + record.StandingHeight, destination.Z)
	local step = destination - root.Position
	if workspace:Blockcast(root.CFrame, Vector3.new(2.3, 2.7, 2.3), step, record.Params()) then
		stopApproach(record)
		return
	end
	local look = root.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	local yaw = look.Magnitude > 0.01 and math.atan2(-look.X, -look.Z) or math.atan2(-direction.X, -direction.Z)
	local goalYaw = math.atan2(-direction.X, -direction.Z)
	local turn = math.atan2(math.sin(goalYaw - yaw), math.cos(goalYaw - yaw))
	root.CFrame = CFrame.new(destination) * CFrame.Angles(0, yaw + turn * (1 - math.exp(-14 * dt)), 0)
	root.AssemblyLinearVelocity = Vector3.zero
	record.Moving = true
	record.MovementSpeed = speed
	priority(record, "Walk")
end
local function ensureScheduler()
	if scheduler and not scheduler.closed then
		return
	end
	scheduler = Effects.NewCast(nil, "BossLocomotion", math.huge)
	scheduler.TimeStopExempt = true
	local accumulator = 0
	scheduler:Step(function(dt)
		accumulator += dt
		if accumulator < 1 / 30 then
			return true
		end
		local step = accumulator
		accumulator = 0
		local any = false
		for actor, record in pairs(records) do
			if
				not actor.Parent
				or not record.Root.Parent
				or record.Humanoid.Health <= 0
				or actor:GetAttribute("EncounterEnded")
			then
				drop(actor)
			else
				any = true
				if actor:GetAttribute("ClassStunFrame") or workspace:GetServerTimeNow()<(actor:GetAttribute("ClassStunnedUntil") or 0) then
     stopApproach(record)
     local frame=actor:GetAttribute("ClassStunFrame")
     if typeof(frame)=="CFrame" then record.Root.CFrame=frame end
     record.Root.AssemblyLinearVelocity=Vector3.zero
     record.LastPosition=record.Root.Position
     continue
    end
    local rate = Time.BossRate(actor)
				if rate <= 0 then
					record.LastPosition = record.Root.Position
					continue
				end
				local scaled = math.min(step, 0.1) * rate
				record.IdleClock += scaled
				driveApproach(record, scaled)
				local pose, bob
				if record.Action then
					pose = record.Pose
					bob = Vector3.zero
					record.LastPosition = record.Root.Position
				else
					pose, bob = locomotionPose(record, scaled)
				end
				pose = floating(record, pose, scaled)
				 
				 
				local response = record.Action and 4.6 or 2.6
				local weight = 1 - math.exp(-scaled * response / math.max(record.Blend, 0.025))
				for name, joint in pairs(record.Joints) do
					if joint.Motor.Parent then
						local lift = record.Lift and joint.Motor.Part0 == record.Root and record.Lift or nil
						local target = offset(joint, pose[name], name == "Waist" and (lift and bob + lift or bob) or lift)
						joint.Motor.C0 = joint.Motor.C0:Lerp(target, weight)
					end
				end
			end
		end
		if not any then
			scheduler:Dispose()
			scheduler = nil
			return false
		end
		return true
	end)
end
local function get(actor)
	if actor:GetAttribute("BossDefeatPresentationStarted") then
		return nil
	end
	local record = records[actor]
	if record then
		return record
	end
	local h = actor:FindFirstChildOfClass("Humanoid")
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not h or not root then
		return nil
	end
	local leg = h.RigType == Enum.HumanoidRigType.R6
		and (actor:FindFirstChild("Right Leg") or actor:FindFirstChild("Left Leg"))
	record = {
		Actor = actor,
		Humanoid = h,
		Root = root,
		Joints = {},
		Pose = idle,
		Action = false,
		Moving = false,
		Params = Runtime.FilterFor(actor),
		StandingHeight = h.HipHeight + root.Size.Y * 0.5 + (leg and leg.Size.Y or 0),
		Blend = 0.14,
		Phase = 0,
		Gait = 0,
		RunWeight = 0,
		SideLean = 0,
		IdleClock = 0,
		LocomotionPose = {},
		LastPosition = root.Position,
	}
	for name in pairs(bones) do
		record.LocomotionPose[name] = { 0, 0, 0 }
	end
	for _, motor in ipairs(actor:GetDescendants()) do
		if motor:IsA("Motor6D") then
			local name = aliases[motor.Name] or motor.Name
			if not bones[name] then
				continue
			end
			local base = motor:GetAttribute("BossBaseC0") or motor.C0
			record.Joints[name] =
				{ Motor = motor, Base = base, Origin = CFrame.new(base.Position), Basis = base.Rotation }
			if motor:GetAttribute("BossBaseC0") == nil then
				motor:SetAttribute("BossBaseC0", base)
			end
			motor.Transform = CFrame.identity
		end
	end
	record.SingleArm = record.Joints.RightElbow == nil
	 
	 
	local animate = actor:FindFirstChild("Animate")
	if animate and (animate:IsA("Script") or animate:IsA("LocalScript")) then
		animate.Disabled = true
	end
	local animator = h:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end
	for _, joint in pairs(record.Joints) do
		joint.Motor.Transform = CFrame.identity
	end
	actor:SetAttribute("BossAnimationOwner", "BossLocomotion")
	priority(record, "Idle")
	records[actor] = record
	ensureScheduler()
	return record
end
function api.Pose(actor, pose, duration, exclusive)
	local record = get(actor)
	if not record then
		return
	end
	if record.HoldToken and not exclusive then
		return nil
	end
	stopApproach(record)
	record.Action = true
	record.Moving = false
	record.Pose = pose or idle
	record.Blend = duration or 0.14
	local token = {}
	record.PoseToken = token
	if exclusive then
		record.HoldToken = token
	end
	priority(record, "Action")
	return token
end
function api.Idle(actor, duration)
	local record = get(actor)
	if not record then
		return
	end
	if record.HoldToken then
		return false
	end
	stopApproach(record)
	record.Action = false
	record.Moving = false
	record.MovementSpeed = nil
	record.Blend = duration or 0.18
	record.PoseToken = nil
	record.LastPosition = record.Root.Position
	priority(record, "Idle")
end
function api.Run(actor, speed)
	local record = get(actor)
	if not record then
		return
	end
	if record.HoldToken then
		return false
	end
	stopApproach(record)
	record.Action = false
	record.Moving = true
	record.MovementSpeed = speed or Config.BossRunSpeed or 32
	record.Blend = 0.10
	record.PoseToken = nil
	priority(record, record.MovementSpeed > (Config.BossWalkSpeed or 18) and "Run" or "Walk")
end
function api.UpdateApproach(actor, target, dt)
	local record = get(actor)
	if not record then
		return false
	end
	local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = target and target:FindFirstChildOfClass("Humanoid")
	if not approachAllowed(record) or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		stopApproach(record)
		return false
	end
	local delta = targetRoot.Position - record.Root.Position
	if Vector3.new(delta.X, 0, delta.Z).Magnitude <= (Config.BossApproachStopDistance or 8) + 0.1 then
		stopApproach(record)
		return false
	end
	record.ApproachCharacter = target
	record.ApproachTarget = targetRoot
	record.ApproachHumanoid = targetHumanoid
	record.ApproachUntil = workspace:GetServerTimeNow() + math.max(0.3, math.min(dt or 0.1, 0.2) * 3)
	record.Approaching = true
	record.Blend = 0.14
	return true
end
function api.Release(actor)
	drop(actor)
end
 
 
function api.PredictMovement(actor, target, seconds)
	local record = get(actor)
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not record or not root or record.HoldToken or actor:GetAttribute("PhaseTransitionInProgress") then
		return root and root.CFrame or CFrame.identity
	end
	local frame = root.CFrame
	local goal = target and target:FindFirstChild("HumanoidRootPart")
	local remaining = math.clamp(seconds or 0, 0, 3)
	local speed = record.MovementSpeed or Config.BossWalkSpeed
	while goal and remaining > 0.001 do
		local dt = math.min(remaining, 1 / 30)
		remaining -= dt
		local delta = goal.Position - frame.Position
		delta = Vector3.new(delta.X, 0, delta.Z)
		local stride = math.min(speed * dt, math.max(0, delta.Magnitude - (Config.BossApproachStopDistance or 8)))
		if stride < 0.001 then
			break
		end
		local move = delta.Unit * stride
		local hit = workspace:Blockcast(frame, Vector3.new(2.3, 4.8, 2.3), move, record.Params())
		if hit then
			move = delta.Unit * math.max(0, hit.Distance - 0.2)
		end
		local ground = Placement.GroundPoint(frame.Position + move, { Margin = 5 })
		if not ground or math.abs(ground.Y + record.StandingHeight - frame.Position.Y) > 4 then
			break
		end
		local pos = Vector3.new(frame.X + move.X, ground.Y + record.StandingHeight, frame.Z + move.Z)
		frame = CFrame.lookAt(pos, pos + delta.Unit)
		if hit then
			break
		end
	end
	return frame
end
function api.AdvancePose(actor, seconds)
	local record = records[actor]
	if not record or record.HoldToken or actor:GetAttribute("PhaseTransitionInProgress") then
		return false
	end
	record.IdleClock += math.clamp(seconds or 0, 0, 3)
	record.Phase = (record.Phase + (record.MovementSpeed or 0) * math.clamp(seconds or 0, 0, 3) * 0.42) % (math.pi * 2)
	if record.Action then
		for name, joint in pairs(record.Joints) do
			if joint.Motor.Parent then
				joint.Motor.C0 = offset(joint, record.Pose[name], Vector3.zero)
			end
		end
	end
	return true
end
function api.HasOwner(actor)
	return records[actor] ~= nil
end
function api.ReleasePose(actor, token, duration)
	local record = records[actor]
	if not record or not token or record.PoseToken ~= token then
		return false
	end
	record.HoldToken = nil
	api.Idle(actor, duration)
	return true
end
function api.State(actor)
	local record = records[actor]
	if not record then
		return nil
	end
	return {
		Priority = record.Priority,
		Action = record.Action,
		Exclusive = record.HoldToken ~= nil,
		Gait = record.Gait,
		RunWeight = record.RunWeight,
		Phase = record.Phase,
		NativeRig = record.Humanoid.RigType.Name,
	}
end
return api

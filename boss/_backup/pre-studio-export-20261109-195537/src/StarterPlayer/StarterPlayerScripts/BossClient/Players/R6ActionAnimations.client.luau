local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("PlayerMovementConfig"))
local dashPoseDuration = Config.DashDuration + 0.1
local identity = CFrame.identity
local entries = {}
local beforeAnimation, afterAnimation
local jointNames = { "RootJoint", "Neck", "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip" }
local poseAngles = {
	Forward = {
		RootJoint = { -12, 0, 0 },
		Neck = { 8, 0, 0 },
		["Right Shoulder"] = { 70, 0, 15 },
		["Left Shoulder"] = { 30, 0, -18 },
		["Right Hip"] = { 22, 0, 0 },
		["Left Hip"] = { -15, 0, 0 },
	},
	Back = {
		RootJoint = { 9, 0, 0 },
		Neck = { -6, 0, 0 },
		["Right Shoulder"] = { 65, 0, 12 },
		["Left Shoulder"] = { 18, 0, -12 },
		["Right Hip"] = { -18, 0, 0 },
		["Left Hip"] = { 18, 0, 0 },
	},
	Left = {
		RootJoint = { -4, 0, 10 },
		Neck = { 2, 0, -6 },
		["Right Shoulder"] = { 68, 0, 10 },
		["Left Shoulder"] = { 25, 0, -22 },
		["Right Hip"] = { 8, 0, -15 },
		["Left Hip"] = { -8, 0, 12 },
	},
	Right = {
		RootJoint = { -4, 0, -10 },
		Neck = { 2, 0, 6 },
		["Right Shoulder"] = { 68, 0, 20 },
		["Left Shoulder"] = { 25, 0, -10 },
		["Right Hip"] = { -8, 0, -12 },
		["Left Hip"] = { 8, 0, 15 },
	},

}
local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
local function locked(entry)
	local char = entry.char
	return entry.h.Health <= 0
		or char:GetAttribute("ParryFrozen")
		or char:GetAttribute("AbilitiesLocked")
		or char:GetAttribute("MovementLocked")
		or char:GetAttribute("Chained")
		or entry.player:GetAttribute("AbilitiesLocked")
		or entry.player:GetAttribute("ExecutionPending")
end
local function restore(entry)
	for _, record in pairs(entry.joints) do
		if record.joint.Parent and record.output and record.joint.Transform == record.output then
			record.joint.Transform = record.input
		end
		record.output = nil
	end
end
local function stopScheduler()
	for _, entry in pairs(entries) do
		restore(entry)
	end
	if beforeAnimation then
		beforeAnimation:Disconnect()
		beforeAnimation = nil
	end
	if afterAnimation then
		afterAnimation:Disconnect()
		afterAnimation = nil
	end
end
local function targetFor(record, angles)
	if not angles then
		return identity
	end
	local physical = CFrame.Angles(math.rad(angles[1]), math.rad(angles[2]), math.rad(angles[3]))
	return record.basis:Inverse() * physical * record.basis
end
local function ensureScheduler()
	if afterAnimation then
		return
	end
	beforeAnimation = Run.PreAnimation:Connect(function()
		for _, entry in pairs(entries) do
			restore(entry)
		end
	end)
	afterAnimation = Run.PreSimulation:Connect(function(dt)
		local anyActive = false
		for _, entry in pairs(entries) do
			if not entry.char.Parent then
				continue
			end
			local rate = entry.char:GetAttribute("TemporalRate") or 1
			entry.actionTime = (entry.actionTime or 0) + dt * rate
			if entry.dashElapsed then
				entry.dashElapsed += dt * rate
			end
			local dashElapsed = entry.dashElapsed or math.huge
			local dashWeight = 0
			if not locked(entry) then
				if dashElapsed >= 0 and dashElapsed < dashPoseDuration then
					dashWeight = smooth(dashElapsed / 0.035) * smooth((dashPoseDuration - dashElapsed) / 0.10)
					if (entry.char:GetAttribute("DashCancelledAt") or 0) >= (entry.dashAt or math.huge) then
						dashWeight = 0
					end
				end
				if
					(dashElapsed >= 0 and dashElapsed < dashPoseDuration)
				then
					anyActive = true
				end
			end
			local blend = 1 - math.exp(-40 * math.min(dt, 0.1))
			for name, record in pairs(entry.joints) do
				local joint = record.joint
				if not joint.Parent then
					continue
				end
				local weight = dashWeight
				local target = record.poses[entry.kind or "Forward"] or record.poses.Forward
				record.weight += (weight - record.weight) * blend
				if record.weight < 0.0001 then
					record.weight = 0
				end
				record.target = record.target:Lerp(target, blend)
				record.input = joint.Transform
				record.output = record.input:Lerp(record.target, record.weight)
				joint.Transform = record.output
				if record.weight > 0 then
					anyActive = true
				end
			end
			if dashWeight > 0 then
				anyActive = true
			end
		end
		if not anyActive then
			stopScheduler()
		end
	end)
end
local function remove(player, char)
	local entry = entries[player]
	if not entry or (char and entry.char ~= char) then
		return
	end
	restore(entry)
	for track, speed in pairs(entry.frozenTracks or {}) do
		pcall(function()
			track:AdjustSpeed(speed)
		end)
	end
	if entry.frozenPlaying then
		entry.frozenPlaying:Disconnect()
	end
	for _, connection in ipairs(entry.connections) do
		connection:Disconnect()
	end
	entries[player] = nil
end
local function bind(player, char)
	local h = char:WaitForChild("Humanoid", 10)
	local torso = char:WaitForChild("Torso", 10)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not h or h.RigType ~= Enum.HumanoidRigType.R6 or not torso or not root or player.Character ~= char then
		return
	end
	remove(player)
	local entry = { char = char, h = h, player = player, joints = {}, connections = {} }
	entries[player] = entry
	local function freezeAnimations()
		local animator = h:FindFirstChildOfClass("Animator")
		if char:GetAttribute("TimeFrozen") then
			entry.frozenTracks = entry.frozenTracks or {}
			local function pause(track)
				if entry.frozenTracks[track] == nil then
					entry.frozenTracks[track] = track.Speed
				end
				track:AdjustSpeed(0)
			end
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					pause(track)
				end
				if not entry.frozenPlaying then
					entry.frozenPlaying = animator.AnimationPlayed:Connect(pause)
				end
			end
		else
			if entry.frozenPlaying then
				entry.frozenPlaying:Disconnect()
				entry.frozenPlaying = nil
			end
			for track, speed in pairs(entry.frozenTracks or {}) do
				pcall(function()
					track:AdjustSpeed(speed)
				end)
			end
			entry.frozenTracks = nil
			ensureScheduler()
		end
	end
	table.insert(entry.connections, char:GetAttributeChangedSignal("TimeFrozen"):Connect(freezeAnimations))
	freezeAnimations()
	local function register(joint)
		if not joint:IsA("Motor6D") or not table.find(jointNames, joint.Name) then
			return
		end
		local record = { joint = joint, basis = joint.C0.Rotation, weight = 0, target = identity, poses = {} }
		for poseName, angles in pairs(poseAngles) do
			record.poses[poseName] = targetFor(record, angles[joint.Name])
		end
		entry.joints[joint.Name] = record
	end
	for _, name in ipairs(jointNames) do
		local joint = char:FindFirstChild(name, true)
		if joint then
			register(joint)
		end
	end
	table.insert(entry.connections, char.DescendantAdded:Connect(register))
	local function dash()
		local started = char:GetAttribute("DashStartedAt") or 0
		local predicted = char:GetAttribute("PredictedDashStartedAt") or 0
		local kind = char:GetAttribute("DashDirection")
		if predicted >= started then
			started = predicted
			kind = char:GetAttribute("PredictedDashDirection")
		end
		if started > (entry.dashAt or 0) then
			entry.dashAt = started
			entry.dashElapsed = math.max(0, workspace:GetServerTimeNow() - started)
				* (char:GetAttribute("TemporalRate") or 1)
			entry.kind = kind
			ensureScheduler()
		end
	end
	for _, name in ipairs({ "DashStartedAt", "PredictedDashStartedAt" }) do
		table.insert(entry.connections, char:GetAttributeChangedSignal(name):Connect(dash))
	end
	dash()
end
local function joined(player)
	player.CharacterAdded:Connect(function(char)
		task.spawn(bind, player, char)
	end)
	player.CharacterRemoving:Connect(function(char)
		remove(player, char)
	end)
	if player.Character then
		task.spawn(bind, player, player.Character)
	end
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
	remove(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	joined(player)
end

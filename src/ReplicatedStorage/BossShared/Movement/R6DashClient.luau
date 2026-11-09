local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local Motion = require(Shared:WaitForChild("Movement"):WaitForChild("R6DashMotion"))
local player = Players.LocalPlayer
local remote = Replicated:WaitForChild("PlayerDash")
local api = {}
local state
 
 
local controlStates = setmetatable({}, { __mode = "k" })
local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < 1e12
end
local function flat(vector)
	if typeof(vector) ~= "Vector3" or not finite(vector.X) or not finite(vector.Y) or not finite(vector.Z) then
		return Vector3.zero
	end
	return Vector3.new(vector.X, 0, vector.Z)
end
local function forwardFor(char, forward)
	local face = flat(forward)
	if face.Magnitude < 0.01 then
		local root = char and char:FindFirstChild("HumanoidRootPart")
		face = root and flat(root.CFrame.LookVector) or Vector3.new(0, 0, -1)
	end
	return face.Magnitude > 0.01 and face.Unit or Vector3.new(0, 0, -1)
end
function api.GetControlState(char, timestamp)
	if not char or not char.Parent then
		return nil, nil
	end
	local now = finite(timestamp) and timestamp or workspace:GetServerTimeNow()
	local cache = controlStates[char]
	if not cache then
		cache = {}
		controlStates[char] = cache
	end
	local distortionUntil = char:GetAttribute("ControlDistortionUntil")
	local started, seed, degrees =
		char:GetAttribute("ControlDistortionStartedAt"),
		char:GetAttribute("ControlDistortionSeed"),
		char:GetAttribute("ControlDistortionMaxRotation")
	local distortion
	if finite(distortionUntil) and now < distortionUntil and finite(started) and finite(seed) and finite(degrees) then
		distortion = {
			Started = started,
			Seed = math.clamp(seed, 0, math.pi * 2),
			Rotation = math.rad(math.clamp(degrees, 0, 55)),
			Until = distortionUntil,
		}
	end
	return nil, distortion, cache
end
function api.TransformControlDirection(char, worldInput, rawKeys, forward, timestamp, remember)
	local now = finite(timestamp) and timestamp or workspace:GetServerTimeNow()
	local _, distortion, cache = api.GetControlState(char, now)
	local movement = flat(worldInput)
	local keys = flat(rawKeys)
	if keys.Magnitude > 0.001 then
		local face = forwardFor(char, forward)
		movement = Vector3.new(-face.Z, 0, face.X) * keys.X - face * keys.Z
	end
	if movement.Magnitude > 1 then
		movement = movement.Unit
	end
	if distortion and movement.Magnitude > 0.001 then
		local elapsed = math.max(0, now - distortion.Started)
		local ease = math.min(1, elapsed / 0.3, math.max(0, distortion.Until - now) / 0.3)
		local angle = math.sin(elapsed * math.pi * 2 / 1.8 + distortion.Seed) * distortion.Rotation * ease
		movement = CFrame.Angles(0, angle, 0):VectorToWorldSpace(movement)
	end
	if remember and cache then
		cache.LastMove = movement
		cache.LastAt = now
	end
	return movement
end
function api.ResolveDashDirection(char, rawKeys, moveDirection, forward, timestamp)
	local now = finite(timestamp) and timestamp or workspace:GetServerTimeNow()
	local _, distortion, cache = api.GetControlState(char, now)
	local keys = flat(rawKeys)
	local movement = flat(moveDirection)
	 
	 
	if
		keys.Magnitude < 0.001
		and movement.Magnitude > 0.001
		and distortion
		and cache
		and cache.LastMove
		and now - (cache.LastAt or 0) < 0.15
		and (movement - cache.LastMove).Magnitude < 0.01
	then
		return movement.Unit
	end
	if keys.Magnitude < 0.001 and movement.Magnitude < 0.001 then
		movement = forwardFor(char, forward)
	end
	movement = api.TransformControlDirection(char, movement, keys, forward, now, false)
	return Motion.FlatUnit(movement) or forwardFor(char, forward)
end
function api.RememberControlMovement(char, movement, timestamp)
	local cache = controlStates[char]
	if cache then
		cache.LastMove = flat(movement)
		cache.LastAt = finite(timestamp) and timestamp or workspace:GetServerTimeNow()
	end
end
local function locked(char, ignoreShieldRoar)
	return player:GetAttribute("AbilitiesLocked")
		or player:GetAttribute("Chained")
		or player:GetAttribute("ExecutionPending")
		or player:GetAttribute("PermanentlyDefeated")
		or char:GetAttribute("AbilitiesLocked")
		or char:GetAttribute("MovementLocked")
		or char:GetAttribute("DashLocked")
		or char:GetAttribute("FinalAttackLocked")
		or not ignoreShieldRoar and char:GetAttribute("ShieldBreakDashLocked")
		or char:GetAttribute("TimeFrozen")
		or char:GetAttribute("AbilityLocked")
		or char:GetAttribute("Chained")
		or char:GetAttribute("ParryFrozen")
end
local function stop(record, rejected)
	if record.connection then
		record.connection:Disconnect()
		record.connection = nil
	end
	record.active = false
	if record.velocity.Parent then
		record.velocity.Enabled = false
	end
	if record.hover.Parent then
		record.hover.Enabled = false
	end
	if record.char.Parent then
		record.char:SetAttribute("PredictedDashActive", false)
		if rejected then
			record.char:SetAttribute("DashCancelledAt", workspace:GetServerTimeNow())
		end
	end
	if
		record.h.Parent
		and record.h.Health > 0
		and not record.root.Anchored
		and not locked(record.char, true)
		and record.restoreRotate ~= nil
	then
		record.h.AutoRotate = record.restoreRotate
		record.restoreRotate = nil
	end
end
local function dispose(record)
	stop(record, true)
	for _, connection in ipairs(record.listeners) do
		connection:Disconnect()
	end
	record.velocity:Destroy()
	record.hover:Destroy()
	record.attachment:Destroy()
	if state == record then
		state = nil
	end
end
local function prepare(char)
	if state and state.char == char then
		return state
	end
	if state then
		dispose(state)
	end
	local h = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not h or h.RigType ~= Enum.HumanoidRigType.R6 or not root then
		return nil
	end
	local velocity, attachment = Motion.NewConstraint(root)
	local hover = Instance.new("LinearVelocity")
	hover.Name = "DashHoverVelocity"
	hover.Attachment0 = attachment
	hover.RelativeTo = Enum.ActuatorRelativeTo.World
	hover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
	hover.LineDirection = Vector3.yAxis
	hover.ForceLimitsEnabled = true
	hover.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	hover.MaxForce = math.max(root.AssemblyMass, 1) * (workspace.Gravity + 1200)
	hover.LineVelocity = 0
	hover.Enabled = false
	hover.Parent = root
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local exclude = { char }
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Character and other.Character ~= char then
			table.insert(exclude, other.Character)
		end
	end
	for _, name in ipairs({ "GoldenSummons", "GoldenCombatEffects", "BossEncounterActors", "BossEncounterEffects" }) do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(exclude, folder)
		end
	end
	params.FilterDescendantsInstances = exclude
	local record = {
		char = char,
		h = h,
		root = root,
		velocity = velocity,
		hover = hover,
		attachment = attachment,
		params = params,
		listeners = {},
		pending = {},
		active = false,
		staminaCap = char:GetAttribute("Stamina") or 100,
	}
	state = record
	table.insert(
		record.listeners,
		char:GetAttributeChangedSignal("Stamina"):Connect(function()
			record.staminaCap = char:GetAttribute("Stamina") or 0
		end)
	)
	local function checkLock()
		if locked(char) or root.Anchored then
			stop(record, true)
		elseif not record.active and h.Health > 0 and not root.Anchored and record.restoreRotate ~= nil then
			h.AutoRotate = record.restoreRotate
			record.restoreRotate = nil
		end
	end
	for _, name in ipairs({
		"AbilitiesLocked",
		"AbilityLocked",
		"MovementLocked",
		"DashLocked",
		"ShieldBreakDashLocked",
		"TimeFrozen",
		"Chained",
		"ParryFrozen",
	}) do
		table.insert(record.listeners, char:GetAttributeChangedSignal(name):Connect(checkLock))
	end
	for _, name in ipairs({ "AbilitiesLocked", "Chained", "ExecutionPending", "PermanentlyDefeated" }) do
		table.insert(record.listeners, player:GetAttributeChangedSignal(name):Connect(checkLock))
	end
	table.insert(record.listeners, root:GetPropertyChangedSignal("Anchored"):Connect(checkLock))
	table.insert(
		record.listeners,
		h.Died:Connect(function()
			stop(record, true)
		end)
	)
	return record
end
function api.Start(char, direction)
	if char ~= player.Character then
		return nil
	end
	local record = prepare(char)
	local flat = Motion.FlatUnit(direction)
	if not record or not flat then
		return nil
	end
	local h, root = record.h, record.root
	if h.Health <= 0 or root.Anchored or h.Sit or locked(char) then
		return nil
	end
	local reserved = 0
	local now = workspace:GetServerTimeNow()
	for id, request in pairs(record.pending) do
		if now - request.time > 1 then
			record.pending[id] = nil
		else
			reserved += Motion.Cost
		end
	end
	if math.min(char:GetAttribute("Stamina") or 0, record.staminaCap) - reserved < Motion.Cost then
		return nil
	end
	 
	 
	if record.connection then
		record.connection:Disconnect()
		record.connection = nil
	end
	if record.restoreRotate == nil then
		record.restoreRotate = h.AutoRotate
	end
	h.AutoRotate = false
	local starting = root.AssemblyLinearVelocity
	if not record.active then
		local floor = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), record.params)
		if floor and root.Position.Y - floor.Position.Y < 4 then
			record.chainBaseY = root.Position.Y
		else
			record.chainBaseY = math.min(record.chainBaseY or root.Position.Y, root.Position.Y)
		end
	end
	record.initialVelocity = Vector2.new(starting.X, starting.Z)
	record.id = now
	record.elapsed = 0
	record.direction = flat
	record.active = true
	record.pending[now] = { time = now }
	char:SetAttribute("PredictedDashDirection", Motion.Kind(root, flat))
	char:SetAttribute("PredictedDashStartedAt", now)
	char:SetAttribute("PredictedDashActive", true)
	record.velocity.MaxForce = math.max(root.AssemblyMass, 1) * 2500
	record.velocity.Enabled = true
	record.hover.Enabled = true
	local function step(dt)
		if
			state ~= record
			or not root.Parent
			or player.Character ~= char
			or h.Health <= 0
			or root.Anchored
			or locked(char)
		then
			stop(record, true)
			return
		end
		local rate = char:GetAttribute("TemporalRate") or 1
		record.elapsed += math.min(dt or 1 / 60, 0.1) * rate
		local elapsed = record.elapsed
		if elapsed >= Motion.Duration then
			stop(record, false)
			return
		end
		local move = h.MoveDirection * math.min(h.WalkSpeed, 40)
		local exitSpeed = math.max(0, move:Dot(flat))
		local target = Vector2.new(flat.X, flat.Z) * Motion.Speed(elapsed, exitSpeed / math.max(rate, 0.01)) * rate
		local handoff = Motion.Smooth((elapsed - (Motion.Duration - 0.075)) / 0.075)
		target += Vector2.new(move.X - flat.X * exitSpeed, move.Z - flat.Z * exitSpeed) * handoff
		target = record.initialVelocity:Lerp(target, Motion.Smooth(elapsed / 0.025))
		local displacement = Vector3.new(target.X, 0, target.Y) * math.min(math.max(dt or 1 / 60, 1 / 240), 0.05)
		local hit = displacement.Magnitude > 0.01
			and workspace:Blockcast(root.CFrame, Vector3.new(2.1, 3.4, 2.1), displacement, record.params)
		if hit then
			 
			record.velocity.PlaneVelocity = Vector2.zero
			stop(record, true)
			return
		end
		record.velocity.PlaneVelocity = target
		record.hover.LineVelocity = Motion.HoverVelocity(elapsed, root.Position.Y, record.chainBaseY, rate)
	end
	step(1 / 60)
	if record.active then
		record.connection = Run.PreSimulation:Connect(step)
	end
	return now
end
function api.Cancel()
	if state then
		stop(state, true)
	end
end
remote.OnClientEvent:Connect(function(id, approved, _, _, serverStamina)
	local record = state
	if not record then
		return
	end
	record.pending[id] = nil
	if approved and type(serverStamina) == "number" then
		record.staminaCap = math.min(record.staminaCap, serverStamina)
	end
	if not approved and record.id == id then
		stop(record, true)
	end
end)
player.CharacterRemoving:Connect(function(char)
	if state and state.char == char then
		dispose(state)
	end
end)
return api

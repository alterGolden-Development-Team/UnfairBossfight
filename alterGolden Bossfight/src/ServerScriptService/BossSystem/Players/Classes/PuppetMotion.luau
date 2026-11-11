--[[
 PuppetMotion - the movement a class kit asks "its client" to play, played on the server for a puppet (an NPC running a class,
 see ClassService.NewPuppet). A player's character is moved by its own client (BossClient.Players.ClassClient: Move, Leap,
 TwinPath, Blink, Waltz); a puppet has no client, so the same messages land here and move the server-owned body.
 Camera cutscenes (Cinema) and laser camera hints are dropped: a puppet has no camera, and the watching player's camera stays theirs.
]]
local Run = game:GetService("RunService")

local M = {}
local function rootOf(char): any
	return char:FindFirstChild("HumanoidRootPart")
end
local active = setmetatable({}, { __mode = "k" }) -- [character] = { conns, instances }

function M.Stop(char)
	local entry = active[char]
	if not entry then
		return
	end
	active[char] = nil
	for _, c in entry.conns do
		c:Disconnect()
	end
	for _, i in entry.instances do
		if i.Parent then
			i:Destroy()
		end
	end
end

local function begin(char)
	M.Stop(char)
	local entry = { conns = {}, instances = {} }
	active[char] = entry
	return entry
end

local function blocked(S, char, revision)
	return not S.Alive(char) or not S.CanAct(char) or (char:GetAttribute("ClassActionRevision") or 0) ~= revision
end

local function sightParams(S, char)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local ignore = { char }
	local fx = workspace:FindFirstChild("ClassEffects")
	if fx then
		table.insert(ignore, fx)
	end
	for _, target in S.Targets() do
		table.insert(ignore, target)
	end
	params.FilterDescendantsInstances = ignore
	return params
end

local function flat(v)
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 0.01 and f.Unit or nil
end

local handlers = {}

handlers.Move = function(S, char: any, data)
	local root = rootOf(char)
	local entry = begin(char)
	local att = Instance.new("Attachment")
	att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = 1e6
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.xAxis
	lv.SecondaryTangentAxis = Vector3.zAxis
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = root
	table.insert(entry.instances, lv)
	table.insert(entry.instances, att)
	local dir = flat(data.Direction or root.CFrame.LookVector) or Vector3.zAxis
	local ends = os.clock() + (data.Duration or 0.2)
	local revision = char:GetAttribute("ClassActionRevision") or 0
	table.insert(entry.conns, Run.Heartbeat:Connect(function()
		if os.clock() >= ends or not root.Parent or blocked(S, char, revision) then
			M.Stop(char)
			return
		end
		local homing = data.Homing
		if typeof(homing) == "Instance" and homing.Parent and homing:FindFirstChild("HumanoidRootPart") then
			dir = flat(rootOf(homing).Position - root.Position) or dir
		end
		local v = dir * (data.Speed or 50)
		lv.PlaneVelocity = Vector2.new(v.X, v.Z)
		root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
	end))
end

handlers.MoveStop = function(_, char)
	M.Stop(char)
end

handlers.Leap = function(_, char, data)
	if typeof(data and data.Velocity) ~= "Vector3" then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid and data.Velocity.Y > 0 then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	rootOf(char).AssemblyLinearVelocity = data.Velocity
end

handlers.TwinPath = function(S, char, data)
	local root = rootOf(char)
	local entry = begin(char)
	local revision = char:GetAttribute("ClassActionRevision") or 0
	local steps, started = data.Steps or {}, os.clock()
	local params = sightParams(S, char)
	local from, prevT, index = root.Position, 0, 1
	local function bossRoot(step)
		local boss = step.Boss
		return boss and boss.Parent and boss:FindFirstChild("HumanoidRootPart")
	end
	local function resolve(step)
		local target = bossRoot(step)
		if target then
			local b = target.Position
			local f = flat(b - from) or Vector3.zAxis
			local p = b - f * (step.Back or 0) + Vector3.new(0, step.Up or 0, 0)
			if step.Ground then
				local hit = workspace:Raycast(Vector3.new(p.X, b.Y + 20, p.Z), Vector3.new(0, -300, 0), params)
				p = Vector3.new(p.X, (hit and hit.Position.Y or b.Y - 3) + 3, p.Z)
			end
			return p
		end
		return step.To or root.Position
	end
	table.insert(entry.conns, Run.Heartbeat:Connect(function()
		if not root.Parent or blocked(S, char, revision) then
			M.Stop(char)
			return
		end
		local t = os.clock() - started
		while steps[index] and t >= steps[index].T do
			from = resolve(steps[index])
			prevT = steps[index].T
			index += 1
		end
		local step = steps[index]
		if not step then
			root.CFrame = CFrame.new(from) * root.CFrame.Rotation
			root.AssemblyLinearVelocity = Vector3.zero
			M.Stop(char)
			return
		end
		local k = math.clamp((t - prevT) / math.max(step.T - prevT, 0.001), 0, 1)
		if step.Ease == "in" then
			k = k * k
		elseif step.Ease == "out" then
			k = 1 - (1 - k) ^ 2
		end
		local pos = from:Lerp(resolve(step), k)
		local target = bossRoot(step)
		local look = target and (target.Position - pos) or (data.Face or root.CFrame.LookVector)
		local f = Vector3.new(look.X, 0, look.Z)
		root.CFrame = f.Magnitude > 0.1 and CFrame.lookAt(pos, pos + f) or CFrame.new(pos) * root.CFrame.Rotation
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end))
end

handlers.Blink = function(S, char, data)
	local root = rootOf(char)
	local entry = begin(char)
	local revision = char:GetAttribute("ClassActionRevision") or 0
	local dir = flat(data.Direction or root.CFrame.LookVector) or flat(root.CFrame.LookVector) or Vector3.zAxis
	task.spawn(function()
		if (data.Delay or 0) > 0 then
			task.wait(data.Delay)
		end
		if active[char] ~= entry or not root.Parent or blocked(S, char, revision) then
			return
		end
		local origin = root.Position
		local distance = data.Distance or 24
		local hit = workspace:Raycast(origin, dir * (distance + 3), sightParams(S, char))
		if hit then
			distance = math.max(0, hit.Distance - 2.5)
		end
		local dest = origin + dir * distance
		local duration = math.max(data.Time or 0.05, 0.016)
		local started = os.clock()
		table.insert(entry.conns, Run.Heartbeat:Connect(function()
			if not root.Parent or not S.Alive(char) then
				M.Stop(char)
				return
			end
			local a = math.clamp((os.clock() - started) / duration, 0, 1)
			local p = origin:Lerp(dest, a)
			root.CFrame = CFrame.lookAt(p, p + dir)
			root.AssemblyLinearVelocity = Vector3.zero
			if a >= 1 then
				M.Stop(char)
			end
		end))
	end)
end

handlers.Waltz = function(S, char, data)
	local boss = data and data.Boss
	if typeof(boss) ~= "Instance" or not boss:FindFirstChild("HumanoidRootPart") then
		return
	end
	local entry = begin(char)
	local revision = char:GetAttribute("ClassActionRevision") or 0
	task.spawn(function()
		for _, step in data.Steps or {} do
			local remaining = (data.Start or workspace:GetServerTimeNow()) + step.T - workspace:GetServerTimeNow()
			if remaining > 0 then
				task.wait(remaining)
			end
			if active[char] ~= entry or not char.Parent or not boss.Parent or blocked(S, char, revision) then
				break
			end
			local center = rootOf(boss).Position
			local root = rootOf(char)
			local y = root.Position.Y
			local pos = center + Vector3.new(math.cos(step.Angle) * step.Radius, 0, math.sin(step.Angle) * step.Radius)
			root.CFrame = CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(center.X, y, center.Z))
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

function M.Handle(S, puppet, kind, data)
	local char = puppet.Character
	local handler = handlers[kind]
	if not handler or not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") then
		return -- Cinema, LaserStart, LaserEnd and anything else meant for a camera or a HUD
	end
	local ok, err = pcall(handler, S, char, data or {})
	if not ok then
		warn("[PuppetMotion] " .. tostring(kind) .. ": " .. tostring(err))
	end
end

return M

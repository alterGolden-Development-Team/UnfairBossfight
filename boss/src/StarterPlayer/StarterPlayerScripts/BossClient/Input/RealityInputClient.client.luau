local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Context = game:GetService("ContextActionService")
local Controls = require(Shared:WaitForChild("Movement"):WaitForChild("R6DashClient"))
local player = Players.LocalPlayer
local character, humanoid, root, distortion
local bound = false
local connections = {}
local name = "RealityControlMapping"
local keys = { W = Enum.KeyCode.W, A = Enum.KeyCode.A, S = Enum.KeyCode.S, D = Enum.KeyCode.D }
local function publishRuntime()
	if character and character.Parent then
		local distorted = bound and distortion ~= nil
		if character:GetAttribute("ControlDistortionRuntimeActive") ~= distorted then
			character:SetAttribute("ControlDistortionRuntimeActive", distorted)
		end
	end
end
local function stop()
	if bound then
		bound = false
		Run:UnbindFromRenderStep(name)
		Context:UnbindAction(name)
		if humanoid and humanoid.Parent then
			humanoid:Move(Vector3.zero, false)
		end
	end
	distortion = nil
	publishRuntime()
end
local function safeArenaMovement(movement)
	local arena = workspace:FindFirstChild("GoldenGrasslandArena")
	local floor = arena and arena:FindFirstChild("Grassland")
	if not root or not root.Parent or not floor or not floor:IsA("BasePart") then
		return movement
	end
	local point = floor.CFrame:PointToObjectSpace(root.Position)
	local localMove = floor.CFrame:VectorToObjectSpace(movement)
	local margin = math.max(4, math.min(8, humanoid.WalkSpeed * 0.3))
	 
	 
	local x, z = localMove.X, localMove.Z
	if point.X >= floor.Size.X * 0.5 - margin and x > 0 or point.X <= -floor.Size.X * 0.5 + margin and x < 0 then
		x = 0
	end
	if point.Z >= floor.Size.Z * 0.5 - margin and z > 0 or point.Z <= -floor.Size.Z * 0.5 + margin and z < 0 then
		z = 0
	end
	return floor.CFrame:VectorToWorldSpace(Vector3.new(x, 0, z))
end
local function refresh()
	if not character or player.Character ~= character or not humanoid or humanoid.Health <= 0 then
		stop()
		return
	end
	local now = workspace:GetServerTimeNow()
	local _m
	_m, distortion = Controls.GetControlState(character, now)
	if not distortion then
		stop()
		return
	end
	if bound then
		publishRuntime()
		return
	end
	bound = true
	Context:BindActionAtPriority(name, function()
		if not distortion or Input:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)
	publishRuntime()
	Run:BindToRenderStep(name, Enum.RenderPriority.Input.Value + 2, function()
		if not character.Parent or player.Character ~= character or humanoid.Health <= 0 then
			stop()
			return
		end
		local tick = workspace:GetServerTimeNow()
		if tick >= (character:GetAttribute("ControlDistortionUntil") or 0) then
			distortion = nil
		end
		if not distortion then
			stop()
			return
		end
		publishRuntime()
		if
			Input:GetFocusedTextBox()
			or character:GetAttribute("MovementLocked")
			or character:GetAttribute("Dashing")
			or character:GetAttribute("PredictedDashActive")
			or character:GetAttribute("TimeFrozen")
		then
			return
		end
		 
		 
		local x = (Input:IsKeyDown(keys.D) and 1 or 0) - (Input:IsKeyDown(keys.A) and 1 or 0)
		local z = (Input:IsKeyDown(keys.S) and 1 or 0) - (Input:IsKeyDown(keys.W) and 1 or 0)
		local camera = workspace.CurrentCamera
		local look = camera and camera.CFrame.LookVector or root.CFrame.LookVector
		local movement = Controls.TransformControlDirection(
			character,
			humanoid.MoveDirection,
			Vector3.new(x, 0, z),
			look,
			tick,
			false
		)
		if distortion then
			movement = safeArenaMovement(movement)
		end
		Controls.RememberControlMovement(character, movement, tick)
		humanoid:Move(movement, false)
	end)
end
local function bind(char)
	stop()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	character = char
	humanoid = nil
	root = nil
	local nextHumanoid = char:WaitForChild("Humanoid")
	local nextRoot = char:WaitForChild("HumanoidRootPart")
	if player.Character ~= char or character ~= char then
		return
	end
	humanoid = nextHumanoid
	root = nextRoot
	for _, attribute in ipairs({
		"ControlDistortionUntil",
		"ControlDistortionStartedAt",
		"ControlDistortionSeed",
		"ControlDistortionMaxRotation",
	}) do
		connections[#connections + 1] = char:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	connections[#connections + 1] = humanoid.Died:Connect(stop)
	refresh()
end
local added = player.CharacterAdded:Connect(bind)
local removing = player.CharacterRemoving:Connect(function(char)
	if character == char then
		stop()
	end
end)
if player.Character then
	task.spawn(bind, player.Character)
end
script.Destroying:Connect(function()
	stop()
	added:Disconnect()
	removing:Disconnect()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
end)

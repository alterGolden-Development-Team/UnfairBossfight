local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Tween = game:GetService("TweenService")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
local gui = script.Parent
gui.Enabled = true
-- a place without the panel in its file (any other bossfight map) builds the same one (BossShared/Presentation/VitalsPanel)
local panel = gui:FindFirstChild("Panel") or require(Shared:WaitForChild("Presentation"):WaitForChild("VitalsPanel")).Build(gui)
local hp = panel.Health
local stamina = panel.Stamina
 
local heartDock = Instance.new("Frame")
heartDock.Name = "LivesHearts"
heartDock.AnchorPoint = Vector2.new(0, 1)
heartDock.Position = UDim2.fromOffset(0, -5)
heartDock.Size = UDim2.fromOffset(165, 28)
heartDock.BackgroundTransparency = 1
heartDock.Parent = hp
local hearts = {}
for index = 1, 5 do
	local heart = Instance.new("TextLabel")
	heart.Name = "LifeHeart" .. index
	heart.Size = UDim2.fromOffset(28, 28)
	heart.Position = UDim2.fromOffset((index - 1) * 32, 0)
	heart.BackgroundTransparency = 1
	heart.Font = Enum.Font.GothamBold
	heart.TextSize = 25
	heart.Text = "♥"
	heart.TextStrokeTransparency = 0.35
	heart.Parent = heartDock
	hearts[index] = heart
end
local extraLives = Instance.new("TextLabel")
extraLives.Name = "BonusLives"
extraLives.Position = UDim2.fromOffset(162, 0)
extraLives.Size = UDim2.fromOffset(58, 28)
extraLives.BackgroundTransparency = 1
extraLives.Font = Enum.Font.GothamBold
extraLives.TextSize = 18
extraLives.TextColor3 = Color3.fromRGB(255, 228, 136)
extraLives.TextXAlignment = Enum.TextXAlignment.Left
extraLives.Parent = heartDock
local function updateHearts()
	local remaining = math.max(0, math.floor(player:GetAttribute("LivesRemaining") or 5))
	extraLives.Visible = remaining > 5
	extraLives.Text = remaining > 5 and ("+" .. (remaining - 5)) or ""
	for index, heart in ipairs(hearts) do
		heart.TextColor3 = index <= remaining and Color3.fromRGB(255, 101, 104) or Color3.fromRGB(65, 50, 52)
		heart.TextTransparency = index <= remaining and 0 or 0.35
	end
end
local livesConnection = player:GetAttributeChangedSignal("LivesRemaining"):Connect(updateHearts)
updateHearts()
local green = ColorSequence.new(Color3.fromRGB(63, 173, 61), Color3.fromRGB(154, 241, 98))
local yellow = ColorSequence.new(Color3.fromRGB(226, 169, 16), Color3.fromRGB(255, 232, 72))
local remote = game:GetService("ReplicatedStorage"):WaitForChild("PlayerDash")
local connections = {}
local tweens = {}
local character
local predictor = require(Shared:WaitForChild("Movement"):WaitForChild("R6DashClient"))
local fillValues = {}
local function fill(row, value, max)
	local last = fillValues[row]
	if last and last.value == value and last.max == max then
		return
	end
	fillValues[row] = { value = value, max = max }
	if tweens[row] then
		tweens[row]:Cancel()
	end
	tweens[row] = Tween:Create(
		row.Track.Fill,
		TweenInfo.new(0.08),
		{ Size = UDim2.fromScale(math.clamp(value / math.max(1, max), 0, 1), 1) }
	)
	tweens[row]:Play()
	if max % 1 ~= 0 then
		row.Value.Text = string.format("%.2f / %.2f", math.min(value, max), max)
	else
		row.Value.Text = string.format("%d / %d", math.ceil(value), max)
	end
end
local function bind(char)
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	connections = {}
	character = char
	local h = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
	if not h or character ~= char then
		return
	end
	local function update()
		if character ~= char then
			return
		end
		fill(hp, h.Health, h.MaxHealth)
		fill(stamina, char:GetAttribute("Stamina") or 100, char:GetAttribute("MaxStamina") or 100)
		local phasingUntil=char:GetAttribute("ClassStatus_Phasing")
		local classId=char:GetAttribute("ClassId")
		local classIFrames=(classId=="Duelist" or classId=="Twinblade" or classId=="TrueWarrior") and type(phasingUntil)=="number"
			and (phasingUntil==-1 or workspace:GetServerTimeNow()<phasingUntil)
		hp.Track.Fill.UIGradient.Color = (char:GetAttribute("Invulnerable") or classIFrames) and yellow or green
	end
	table.insert(connections, h.HealthChanged:Connect(update))
	table.insert(connections, h:GetPropertyChangedSignal("MaxHealth"):Connect(update))
	table.insert(connections, char:GetAttributeChangedSignal("Stamina"):Connect(update))
	table.insert(connections, char:GetAttributeChangedSignal("Invulnerable"):Connect(update))
	table.insert(connections, char:GetAttributeChangedSignal("ClassStatus_Phasing"):Connect(update))
	table.insert(connections, char:GetAttributeChangedSignal("ClassId"):Connect(update))
	update()
end
local function dash(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end
	local char = player.Character
	local h = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if h and root and h.Health > 0 then
		local camera = workspace:FindFirstChildOfClass("Camera")
		local face = camera and Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
			or root.CFrame.LookVector
		if face.Magnitude < 0.01 then
			face = root.CFrame.LookVector
		end
		face = face.Unit
		local x = (Input:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
		local z = (Input:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
		local direction = predictor.ResolveDashDirection(char, Vector3.new(x, 0, -z), h.MoveDirection, face)
		if char:GetAttribute("StolenSecondRecording") then
			local sessionId = char:GetAttribute("StolenSecondSessionId")
			if sessionId then
				game.ReplicatedStorage.TemporalInput:FireServer("Dash", sessionId, 0, direction)
			end
			return Enum.ContextActionResult.Sink
		end
		local relative = CFrame.lookAt(Vector3.zero, face):VectorToObjectSpace(direction)
		local kind = math.abs(relative.X) > math.abs(relative.Z) and (relative.X < 0 and "Left" or "Right")
			or (relative.Z > 0 and "Back" or "Forward")
		local predictedAt = predictor.Start(char, direction, kind)
		if predictedAt then
			remote:FireServer(direction, face, predictedAt)
		end
	end
	return Enum.ContextActionResult.Sink
end
CAS:BindAction("PlayerDodge", dash, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
CAS:SetTitle("PlayerDodge", "Dash")
CAS:SetPosition("PlayerDodge", UDim2.new(1, -135, 1, -150))
task.spawn(function()
	for _ = 1, 8 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		end)
		if ok then
			break
		end
		task.wait(0.2)
	end
end)
local characterConnection = player.CharacterAdded:Connect(bind)
if player.Character then
	task.spawn(bind, player.Character)
end

 
local constraint = panel:FindFirstChildOfClass("UISizeConstraint")
if constraint then
	constraint.MinSize = Vector2.new(220, 86)
	constraint.MaxSize = Vector2.new(430, 86)
end
panel.AnchorPoint = Vector2.new(0, 1)
panel.Size = UDim2.new(0.30, 0, 0, 86)
panel.Position = UDim2.new(0.035, 0, 1, -28)
if panel:FindFirstChild("DashHint") then
	panel.DashHint.Visible = false
end
local request = Instance.new("BindableEvent")
request.Name = "RequestDash"
request.Parent = gui
local requestConnection = request.Event:Connect(function()
	dash("HUD", Enum.UserInputState.Begin)
end)
local function showVitals()
	panel.Visible = not player:GetAttribute("PermanentlyDefeated")
end
local visibilityConnection = player:GetAttributeChangedSignal("PermanentlyDefeated"):Connect(showVitals)
showVitals()
script.Destroying:Connect(function()
	character = nil
	livesConnection:Disconnect()
	characterConnection:Disconnect()
	requestConnection:Disconnect()
	visibilityConnection:Disconnect()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	for _, tween in pairs(tweens) do
		tween:Cancel()
	end
	heartDock:Destroy()
	CAS:UnbindAction("PlayerDodge")
end)

player:SetAttribute("EncounterVitalsReady", true)

local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
 
 
 
 
 
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")

local Settings = {
	Cinematic = true,
	Title = true,
	ReduceFlashing = false,
}
local GOLD = Color3.fromRGB(255, 196, 40)
local BRIGHT = Color3.fromRGB(255, 236, 160)
local WHITE = Color3.fromRGB(255, 252, 236)
local INK = Color3.fromRGB(16, 8, 0)
local FONT = Enum.Font.GrenzeGotisch

local tweens = {}
local function tween(object, time, goal, style, direction)
	local t = Tween:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
	tweens[t] = true
	t.Completed:Once(function() tweens[t] = nil end)
	t:Play()
	return t
end
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local gui = new("ScreenGui", { Name = "Phase5TransformHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 84, Enabled = false },
	player:WaitForChild("PlayerGui"))
local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, gui)
local edge = new("Frame", { Name = "Edge", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, gui)
local edgeStroke = new("UIStroke", { Color = Color3.new(), Thickness = 0, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, edge)
local barTop = new("Frame", { Name = "LetterboxTop", Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = 3 }, gui)
local barBottom = new("Frame", { Name = "LetterboxBottom", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0),
	BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = 3 }, gui)
local impact = new("Frame", { Name = "Impact", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6 }, gui)

 
local card = new("Frame", { Name = "Card", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(700, 330),
	BackgroundTransparency = 1, ZIndex = 7, Visible = false }, gui)
local seal = new("Frame", { Name = "Seal", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(170, 170),
	BackgroundColor3 = INK, BackgroundTransparency = 0.35, ZIndex = 7 }, card)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, seal)
local sealStroke = new("UIStroke", { Color = GOLD, Thickness = 3, Transparency = 0 }, seal)
local sealInner = new("Frame", { Name = "Inner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.82),
	BackgroundTransparency = 1, ZIndex = 7 }, seal)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, sealInner)
local innerStroke = new("UIStroke", { Color = BRIGHT, Thickness = 1.5, Transparency = 0.2 }, sealInner)
local numeral = new("TextLabel", { Name = "Numeral", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromScale(0.8, 0.8),
	BackgroundTransparency = 1, Font = FONT, Text = "V", TextScaled = true, TextColor3 = WHITE, TextStrokeColor3 = INK, TextStrokeTransparency = 0.4, ZIndex = 8 }, seal)
new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.55, BRIGHT), ColorSequenceKeypoint.new(1, GOLD) }),
	Rotation = 90 }, numeral)
local phaseLabel = new("TextLabel", { Name = "Phase", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.36, -94), Size = UDim2.fromOffset(300, 28),
	BackgroundTransparency = 1, Font = FONT, Text = "P H A S E", TextScaled = true, TextColor3 = BRIGHT, TextStrokeColor3 = INK, TextStrokeTransparency = 0.5, ZIndex = 8 }, card)
local nameLabel = new("TextLabel", { Name = "Title", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.36, 100), Size = UDim2.new(1, 0, 0, 52),
	BackgroundTransparency = 1, Font = FONT, Text = "", TextScaled = true, TextColor3 = WHITE, TextStrokeColor3 = INK, TextStrokeTransparency = 0.3, ZIndex = 8 }, card)
new("UITextSizeConstraint", { MaxTextSize = 52 }, nameLabel)
new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BRIGHT), ColorSequenceKeypoint.new(0.5, WHITE), ColorSequenceKeypoint.new(1, BRIGHT) }) }, nameLabel)
local ruleLeft = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.5, -10, 0.36, 168), Size = UDim2.fromOffset(0, 2), BackgroundColor3 = GOLD,
	BorderSizePixel = 0, ZIndex = 8 }, card)
local ruleRight = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, 10, 0.36, 168), Size = UDim2.fromOffset(0, 2), BackgroundColor3 = GOLD,
	BorderSizePixel = 0, ZIndex = 8 }, card)
local diamond = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.36, 168), Size = UDim2.fromOffset(10, 10), Rotation = 45,
	BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 8 }, card)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }, ruleLeft)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, ruleRight)

local active, cameraState, grade, ambience
local cameraTasks = {}
local function alive(token) return active and active.Token == token end

local function flashScreen(alpha, time, color)
	if Settings.ReduceFlashing then return end
	flash.BackgroundColor3 = color or WHITE
	flash.BackgroundTransparency = alpha
	tween(flash, time or 0.3, { BackgroundTransparency = 1 })
end
local function letterbox(on, time, height)
	local h = on and (height or 70) or 0
	tween(barTop, time or 0.4, { Size = UDim2.new(1, 0, 0, h) }, Enum.EasingStyle.Quart)
	tween(barBottom, time or 0.4, { Size = UDim2.new(1, 0, 0, h) }, Enum.EasingStyle.Quart)
end
local function setGrade(goal, time)
	if not grade then
		grade = new("ColorCorrectionEffect", { Name = "Phase5TransformGrade", Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }, Lighting)
	end
	if time and time > 0 then tween(grade, time, goal) else for k, v in pairs(goal) do grade[k] = v end end
end

 
local function stopCamera()
	for _, c in ipairs(cameraTasks) do c:Disconnect() end
	table.clear(cameraTasks)
end
local function releaseCamera()
	stopCamera()
	if not cameraState then return end
	local camera = workspace.CurrentCamera
	local state = cameraState
	cameraState = nil
	if camera then
		camera.CameraType = state.Type == Enum.CameraType.Scriptable and Enum.CameraType.Custom or state.Type
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		camera.CameraSubject = humanoid or state.Subject
		camera.FieldOfView = state.Fov
	end
end
local function takeCamera()
	local camera = workspace.CurrentCamera
	if not Settings.Cinematic or not camera then return false end
	if not cameraState then
		cameraState = { Type = camera.CameraType, Subject = camera.CameraSubject, Fov = Fov.Base(camera) }
		camera.CameraType = Enum.CameraType.Scriptable
	end
	return true
end
 
local punch = 0
local function path(time, fn)
	local camera = workspace.CurrentCamera
	if not cameraState or not camera then return end
	stopCamera()
	local token = active and active.Token
	local start = os.clock()
	local connection
	connection = Run.RenderStepped:Connect(function(dt)
		local t = (os.clock() - start) / time
		if not cameraState or not alive(token) then
			connection:Disconnect()
			return
		end
		punch *= math.exp(-dt * 9)
		local frame, fov = fn(math.min(t, 1))
		camera.CFrame, camera.FieldOfView = frame, fov + punch
	end)
	table.insert(cameraTasks, connection)
end
local function smooth(t) return t * t * (3 - 2 * t) end
local function headOf(owner)
	local head = owner and owner:FindFirstChild("Head")
	local root = owner and owner:FindFirstChild("HumanoidRootPart")
	return head and head.Position or (root and root.Position + Vector3.new(0, 2.5, 0))
end

local function chargeShots(data, token)
	local owner = data.Owner
	local frame = data.Frame
	if typeof(frame) ~= "CFrame" or not takeCamera() then return end
	local charge = math.clamp(tonumber(data.Charge) or 6, 2, 30)
	local look, right = frame.LookVector, frame.RightVector
	local a1, a2 = charge * 0.36, charge * 0.34
	local a3 = charge - a1 - a2
	 
	path(a1, function(t)
		local s = smooth(t)
		local a = math.rad(-35 + 55 * s)
		local p = frame.Position + (look * math.cos(a) + right * math.sin(a)) * (34 - 4 * s) + Vector3.new(0, 2.5 + 2 * s, 0)
		return CFrame.lookAt(p, (headOf(owner) or frame.Position) - Vector3.new(0, 1, 0)), 58
	end)
	task.delay(a1, function()
		if not alive(token) or not cameraState then return end
		 
		path(a2, function(t)
			local s = smooth(t)
			local head = headOf(owner) or frame.Position
			local p = frame.Position + look * (13 - 5 * s) + right * (2 - 1 * s) + Vector3.new(0, -1.2 + 1.5 * s, 0)
			return CFrame.lookAt(p, head), 50 - 8 * s
		end)
	end)
	task.delay(a1 + a2, function()
		if not alive(token) or not cameraState then return end
		 
		path(a3, function(t)
			local s = smooth(t)
			local a = math.rad(30 + 70 * s)
			local center = frame.Position
			local p = center + (look * math.cos(a) + right * math.sin(a)) * (20 - 4 * s) + Vector3.new(0, 42 - 16 * s, 0)
			return CFrame.lookAt(p, (headOf(owner) or center) - Vector3.new(0, 2, 0)), 66 - 6 * s
		end)
	end)
end
local function burstShot(data, token)
	local owner = active and active.Owner
	local frame = active and active.Frame
	if not frame or not takeCamera() then return end
	local duration = math.clamp(tonumber(data.Duration) or 2, 0.5, 6)
	local look = frame.LookVector
	 
	path(duration * 0.5, function(t)
		local head = headOf(owner) or frame.Position
		local shake = Vector3.new(math.noise(t * 40, 1), math.noise(t * 40, 2), math.noise(t * 40, 3)) * (0.15 + t * 0.6)
		local p = head + look * (14 - 9 * t ^ 2) + Vector3.new(0, -1.5 + 0.8 * t, 0) + shake
		return CFrame.lookAt(p, head), 46 - 22 * t ^ 1.5
	end)
end
local function revealShot(data, token)
	local owner = active and active.Owner
	local frame = active and active.Frame
	if not frame or not takeCamera() then return end
	local reveal = math.clamp(active.Reveal or 3, 1, 15)
	local look, right = frame.LookVector, frame.RightVector
	 
	path(reveal, function(t)
		local s = smooth(t)
		local head = headOf(owner) or frame.Position
		local p = frame.Position + look * (11 + 9 * s) + right * (4 + 3 * s) + Vector3.new(0, -2 + 1.5 * s, 0)
		return CFrame.lookAt(p, head + Vector3.new(0, 1 - 1.5 * s, 0)), 34 + 22 * s
	end)
	task.delay(math.max(0.5, reveal - 0.35), function() if alive(token) then releaseCamera() end end)
end

 
local function stamp(title, token)
	if not Settings.Title then return end
	card.Visible = true
	seal.Size, seal.Rotation, seal.BackgroundTransparency = UDim2.fromOffset(520, 520), -40, 1
	sealStroke.Transparency, innerStroke.Transparency = 1, 1
	numeral.TextTransparency, numeral.TextStrokeTransparency = 1, 1
	phaseLabel.TextTransparency, phaseLabel.TextStrokeTransparency = 1, 1
	nameLabel.Text, nameLabel.MaxVisibleGraphemes = title or "", 0
	nameLabel.TextTransparency, nameLabel.TextStrokeTransparency = 0, 0.3
	ruleLeft.Size, ruleRight.Size, diamond.BackgroundTransparency = UDim2.fromOffset(0, 2), UDim2.fromOffset(0, 2), 1
	tween(seal, 0.28, { Size = UDim2.fromOffset(170, 170), Rotation = 0, BackgroundTransparency = 0.35 }, Enum.EasingStyle.Back)
	tween(sealStroke, 0.28, { Transparency = 0 })
	tween(innerStroke, 0.4, { Transparency = 0.2 })
	numeral.Size = UDim2.fromScale(1.6, 1.6)
	tween(numeral, 0.3, { Size = UDim2.fromScale(0.8, 0.8), TextTransparency = 0, TextStrokeTransparency = 0.4 }, Enum.EasingStyle.Quart)
	task.delay(0.25, function()
		if not alive(token) then return end
		tween(phaseLabel, 0.4, { TextTransparency = 0, TextStrokeTransparency = 0.5 })
		tween(ruleLeft, 0.5, { Size = UDim2.fromOffset(240, 2) }, Enum.EasingStyle.Quart)
		tween(ruleRight, 0.5, { Size = UDim2.fromOffset(240, 2) }, Enum.EasingStyle.Quart)
		tween(diamond, 0.3, { BackgroundTransparency = 0 })
		local count = utf8.len(nameLabel.Text) or #nameLabel.Text
		for i = 1, count do
			task.delay(i * 0.035, function()
				if alive(token) then nameLabel.MaxVisibleGraphemes = i end
			end)
		end
	end)
	 
	local spin = Run.RenderStepped:Connect(function(dt)
		if card.Visible then sealInner.Rotation += dt * 20 end
	end)
	task.delay(3.4, function()
		spin:Disconnect()
		if not alive(token) then return end
		for _, item in ipairs({ numeral, phaseLabel, nameLabel }) do tween(item, 0.6, { TextTransparency = 1, TextStrokeTransparency = 1 }) end
		tween(seal, 0.6, { BackgroundTransparency = 1, Size = UDim2.fromOffset(200, 200) })
		tween(sealStroke, 0.6, { Transparency = 1 })
		tween(innerStroke, 0.6, { Transparency = 1 })
		tween(ruleLeft, 0.6, { Size = UDim2.fromOffset(0, 2) })
		tween(ruleRight, 0.6, { Size = UDim2.fromOffset(0, 2) })
		tween(diamond, 0.6, { BackgroundTransparency = 1 })
		task.delay(0.65, function() if alive(token) then card.Visible = false end end)
	end)
end

 
local function impactFrames(token)
	if Settings.ReduceFlashing then return end
	local steps = {
		{ 0.04, function() impact.BackgroundColor3, impact.BackgroundTransparency = WHITE, 0 end },
		{ 0.06, function()
			impact.BackgroundTransparency = 1
			setGrade({ Saturation = -1, Contrast = 3, Brightness = 0.3, TintColor = Color3.fromRGB(255, 200, 90) })
		end },
		{ 0.05, function() impact.BackgroundColor3, impact.BackgroundTransparency = Color3.new(), 0 end },
		{ 0.06, function()
			impact.BackgroundTransparency = 1
			setGrade({ Saturation = -1, Contrast = 2.4, Brightness = -0.35, TintColor = Color3.fromRGB(255, 220, 140) })
		end },
		{ 0.04, function() impact.BackgroundColor3, impact.BackgroundTransparency = GOLD, 0.2 end },
	}
	local at = 0
	for _, step in ipairs(steps) do
		task.delay(at, function() if alive(token) then step[2]() end end)
		at += step[1]
	end
	task.delay(at, function()
		if not alive(token) then return end
		impact.BackgroundTransparency = 1
		flashScreen(0.1, 0.9)
		setGrade({ Saturation = 0.1, Contrast = 0.2, Brightness = 0.05, TintColor = Color3.fromRGB(255, 240, 215) }, 0.6)
	end)
end

 
local ambienceWatch,ambienceTween
local function setAmbience(owner)
	if ambience then return end
	ambience = new("ColorCorrectionEffect", { Name = "Phase5Ambience", Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }, Lighting)
	ambienceTween=Tween:Create(ambience,TweenInfo.new(2),{Saturation=.08,Contrast=.1,TintColor=Color3.fromRGB(255,244,226)})
 ambienceTween:Play()
	local watch
	watch = Run.Heartbeat:Connect(function()
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not h or h.Health<=0 or workspace:GetAttribute("EncounterStarted")~=true or not owner.Parent or owner:GetAttribute("Phase") ~= 5 or owner:GetAttribute("EncounterEnded") or player:GetAttribute("ViewAsServer") then
			watch:Disconnect()
			local a = ambience
			ambience = nil
			if a then
				Tween:Create(a, TweenInfo.new(1), { Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }):Play()
				task.delay(1.05, function() a:Destroy() end)
			end
		end
	end)
 ambienceWatch=watch
end

local function clear()
	active = nil
	for t in pairs(tweens) do t:Cancel() end
	table.clear(tweens)
	releaseCamera()
	punch = 0
	barTop.Size, barBottom.Size = UDim2.new(1, 0, 0, 0), UDim2.new(1, 0, 0, 0)
	flash.BackgroundTransparency, impact.BackgroundTransparency = 1, 1
	edgeStroke.Thickness, edgeStroke.Transparency = 0, 1
	card.Visible = false
	if grade then
		local g = grade
		grade = nil
		Tween:Create(g, TweenInfo.new(0.8), { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }):Play()
		task.delay(0.85, function() g:Destroy() end)
	end
	gui.Enabled = false
end

local function stage(data)
	local name, token = data.Stage, data.Token
	if name == "Begin" then
		gui.Enabled = true
		letterbox(true, 0.6, 72)
		setGrade({ Saturation = -0.25, Contrast = 0.1, Brightness = -0.05, TintColor = Color3.fromRGB(255, 240, 220) }, 1)
		chargeShots(data, token)
	elseif name == "Beat" then
		local strength = math.clamp(tonumber(data.Strength) or 0.5, 0, 1)
		punch = 2 + 4 * strength
		edgeStroke.Thickness, edgeStroke.Transparency = 40 + 60 * strength, 0.35 - 0.2 * strength
		tween(edgeStroke, 0.35, { Thickness = 0, Transparency = 1 })
		setGrade({ Saturation = -0.25 - 0.6 * strength, Contrast = 0.1 + 0.35 * strength, Brightness = -0.05 - 0.05 * strength,
			TintColor = Color3.fromRGB(255, 235 - 20 * strength, 210 - 50 * strength) }, 0.25)
	elseif name == "Burst" then
		flashScreen(0.55, 0.4, GOLD)
		setGrade({ Saturation = -0.4, Contrast = 0.6, Brightness = 0.35, TintColor = Color3.fromRGB(255, 236, 190) }, (tonumber(data.Duration) or 2) * 0.45)
		burstShot(data, token)
	elseif name == "Shatter" then
		impactFrames(token)
		letterbox(true, 0.2, 52)
		revealShot(data, token)
		task.delay(0.35, function() if alive(token) then stamp(active.Title, token) end end)
		setAmbience(data.Owner)
	elseif name == "Land" then
		punch = 3
		letterbox(false, 0.8)
	end
end

local connection = remote.OnClientEvent:Connect(function(kind, data)
	if kind ~= "Phase5Transform" or type(data) ~= "table" then return end
	if player:GetAttribute("ViewAsServer") then return end
	local owner = data.Owner
	if typeof(owner) ~= "Instance" or not owner.Parent then return end
	if data.Stage == "Begin" then
		if active then clear() end
		active = { Token = data.Token, Owner = owner, Frame = data.Frame, Reveal = tonumber(data.Reveal) or 3,
			Title = owner:GetAttribute("Phase5TitleText") or data.Title, Until = os.clock() + (tonumber(data.Charge) or 6) + (tonumber(data.Burst) or 2) + (tonumber(data.Reveal) or 3) + 3 }
	elseif not (active and active.Token == data.Token) then
		return
	end
	stage(data)
end)

local heartbeat = Run.Heartbeat:Connect(function()
	if not active then return end
	local owner = active.Owner
	if os.clock() >= active.Until or not owner.Parent or owner:GetAttribute("EncounterEnded") or owner:GetAttribute("Phase") ~= 5
		or player:GetAttribute("ViewAsServer") or not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character.Humanoid.Health<=0 then
		clear()
	end
end)
local function hardReset()
 clear()
 if ambienceWatch then ambienceWatch:Disconnect()ambienceWatch=nil end
 if ambienceTween then ambienceTween:Cancel()ambienceTween=nil end
 if ambience then ambience:Destroy()ambience=nil end
end
require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset).Register(script,hardReset)
player.CharacterRemoving:Connect(hardReset)
script.Destroying:Connect(function()
	clear()
	connection:Disconnect()
	heartbeat:Disconnect()
	gui:Destroy()
	if ambience then ambience:Destroy() end
end)

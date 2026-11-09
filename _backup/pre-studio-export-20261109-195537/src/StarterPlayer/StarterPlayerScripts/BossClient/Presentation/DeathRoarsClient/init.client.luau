local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
local Reset=require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)
 
 
 
 
 
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")
local Spam = require(script:WaitForChild("Spam"))

local Settings = {
	Cinematic = false,  -- boss battle: no camera takeover or letterbox; title and grade still play
	Title = true,  
	ReduceFlashing = false,  
	Density = 1,  
}
Spam.SetDensity(Settings.ReduceFlashing and Settings.Density * 0.4 or Settings.Density)
local WHITE = Color3.fromRGB(255, 251, 228)
local YELLOW = Color3.fromRGB(255, 214, 50)
local GOLD = Color3.fromRGB(255, 165, 20)
local EMBER = Color3.fromRGB(255, 110, 30)
local DARK = Color3.fromRGB(40, 24, 0)
local rng = Random.new()

local visualTweens = {}
local function tween(object, time, goal, style, direction)
	local t = Tween:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
	visualTweens[t] = true
	t.Completed:Once(function() visualTweens[t] = nil end)
	t:Play()
	return t
end
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local gui = new("ScreenGui", { Name = "DeathRoarsHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 85, Enabled = false },
	player:WaitForChild("PlayerGui"))
local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, gui)
local streaks = new("Frame", { Name = "Streaks", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, ClipsDescendants = true }, gui)
local barTop = new("Frame", { Name = "LetterboxTop", Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = 4 }, gui)
local barBottom = new("Frame", { Name = "LetterboxBottom", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0),
	BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = 4 }, gui)
 
local impact = new("Frame", { Name = "Impact", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6 }, gui)

 
local titleBox = new("Frame", { Name = "Title", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.new(0.9, 0, 0, 130),
	BackgroundTransparency = 1, ZIndex = 7, Visible = false }, gui)
new("UISizeConstraint", { MaxSize = Vector2.new(980, 130) }, titleBox)
local function titleLayer(name, color, z)
	local label = new("TextLabel", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Font = Enum.Font.Garamond, Text = "DEATH ROARS", TextScaled = true, TextColor3 = color,
		TextStrokeColor3 = DARK, TextStrokeTransparency = 1, TextTransparency = 1, ZIndex = z }, titleBox)
	new("UITextSizeConstraint", { MaxTextSize = 110, MinTextSize = 28 }, label)
	return label
end
local titleGold = titleLayer("Gold", GOLD, 7)
local titleEmber = titleLayer("Ember", EMBER, 7)
local titleMain = titleLayer("Main", WHITE, 8)
local underline = new("Frame", { Name = "Underline", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, 6), Size = UDim2.new(0, 0, 0, 3),
	BackgroundColor3 = YELLOW, BorderSizePixel = 0, ZIndex = 8 }, titleBox)
local subtitle = new("TextLabel", { Name = "Subtitle", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 14), Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1, Font = Enum.Font.Garamond, Text = "", TextScaled = true, TextColor3 = YELLOW,
	TextStrokeColor3 = DARK, TextStrokeTransparency = 1, TextTransparency = 1, ZIndex = 8 }, titleBox)
new("UITextSizeConstraint", { MaxTextSize = 24, MinTextSize = 12 }, subtitle)

local grade, active, cameraState
local cameraTweens = {}
local hiddenGuis = {}  

 
local function screenStreak(heavy)
	if Settings.ReduceFlashing and not heavy then return end
	local size = streaks.AbsoluteSize
	local length = math.max(size.X, size.Y) * rng:NextNumber(0.6, 1.4)
	local thick = heavy and 5 or 2
	local holder = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95)),
		Size = UDim2.fromOffset(length * 0.3, thick), Rotation = rng:NextNumber(-75, 75), BackgroundTransparency = 1, ZIndex = 2 }, streaks)
	local glow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, thick * 4),
		BackgroundColor3 = YELLOW, BackgroundTransparency = 0.65, BorderSizePixel = 0, ZIndex = 2 }, holder)
	local line = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, holder)
	local alpha = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) })
	new("UIGradient", { Transparency = alpha }, line)
	new("UIGradient", { Transparency = alpha }, glow)
	tween(holder, 0.06, { Size = UDim2.fromOffset(length, thick) }, Enum.EasingStyle.Quart)
	task.delay(0.08, function()
		if not holder.Parent then return end
		tween(line, 0.22, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) })
		tween(glow, 0.3, { BackgroundTransparency = 1 })
	end)
	task.delay(0.42, function() holder:Destroy() end)
end
local function screenSlash(rotation)
	if Settings.ReduceFlashing then return end
	local size = streaks.AbsoluteSize
	local length = math.sqrt(size.X ^ 2 + size.Y ^ 2) * 1.1
	local holder = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 10),
		Rotation = rotation or -18, BackgroundTransparency = 1, ZIndex = 5 }, gui)
	local glow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = YELLOW, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 5 }, holder)
	local line = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }, holder)
	local alpha = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0), NumberSequenceKeypoint.new(0.92, 0), NumberSequenceKeypoint.new(1, 1) })
	new("UIGradient", { Transparency = alpha }, line)
	new("UIGradient", { Transparency = alpha }, glow)
	tween(holder, 0.07, { Size = UDim2.fromOffset(length, 10) }, Enum.EasingStyle.Quart)
	task.delay(0.12, function()
		if not holder.Parent then return end
		tween(line, 0.45, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
		tween(glow, 0.6, { Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1 })
	end)
	task.delay(0.8, function() holder:Destroy() end)
end
local function flashScreen(alpha, time, color)
	if Settings.ReduceFlashing then return end
	flash.BackgroundColor3 = color or WHITE
	flash.BackgroundTransparency = alpha
	tween(flash, time or 0.3, { BackgroundTransparency = 1 })
end
local function setGrade(goal, time)
	if not grade then
		grade = new("ColorCorrectionEffect", { Name = "DeathRoarsGrade", Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }, Lighting)
	end
	if time and time > 0 then
		tween(grade, time, goal)
	else
		for k, v in pairs(goal) do grade[k] = v end
	end
end
local function letterbox(on, time, height)
	local h = on and (height or 64) or 0
	tween(barTop, time or 0.4, { Size = UDim2.new(1, 0, 0, h) }, Enum.EasingStyle.Quart)
	tween(barBottom, time or 0.4, { Size = UDim2.new(1, 0, 0, h) }, Enum.EasingStyle.Quart)
end
 
local function impactFrames(after, afterTime)
	if Settings.ReduceFlashing then
		if after then setGrade(after, afterTime or 0.3) end
		return
	end
	local token = active and active.Token
	local steps = {
		{ 0.035, function() impact.BackgroundColor3, impact.BackgroundTransparency = WHITE, 0 end },
		{ 0.06, function()
			impact.BackgroundTransparency = 1
			setGrade({ Saturation = -1, Contrast = 2.6, Brightness = 0.25, TintColor = Color3.new(1, 1, 1) })
		end },
		{ 0.04, function() impact.BackgroundColor3, impact.BackgroundTransparency = Color3.new(), 0.15 end },
		{ 0.05, function()
			impact.BackgroundTransparency = 1
			setGrade({ Saturation = -1, Contrast = 2.2, Brightness = -0.35, TintColor = Color3.fromRGB(255, 220, 140) })
		end },
	}
	local at = 0
	for _, step in ipairs(steps) do
		task.delay(at, function() if active and active.Token == token then step[2]() end end)
		at += step[1]
	end
	task.delay(at, function()
		if not active or active.Token ~= token then return end
		impact.BackgroundTransparency = 1
		if after then setGrade(after, afterTime or 0.3) end
	end)
end
local function hideTitle(time)
	for _, label in ipairs({ titleGold, titleEmber, titleMain, subtitle }) do
		tween(label, time, { TextTransparency = 1, TextStrokeTransparency = 1 })
	end
	tween(underline, time, { BackgroundTransparency = 1 })
end
 
local function slamTitle(text, sub, hold)
	if not Settings.Title then return end
	local token = active and active.Token
	titleBox.Visible = true
	for _, label in ipairs({ titleGold, titleEmber, titleMain }) do label.Text = text end
	subtitle.Text = sub or ""
	titleMain.TextTransparency, titleMain.TextStrokeTransparency = 0, 0.2
	titleGold.TextTransparency, titleEmber.TextTransparency = 0.15, 0.15
	titleGold.Position, titleEmber.Position = UDim2.new(0.5, -26, 0.5, -4), UDim2.new(0.5, 26, 0.5, 4)
	titleMain.Size = UDim2.fromScale(1.35, 1.35)
	tween(titleMain, 0.22, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Back)
	tween(titleGold, 0.18, { Position = UDim2.new(0.5, -3, 0.5, 0) }, Enum.EasingStyle.Quart)
	tween(titleEmber, 0.18, { Position = UDim2.new(0.5, 3, 0.5, 0) }, Enum.EasingStyle.Quart)
	underline.BackgroundTransparency, underline.Size = 0, UDim2.new(0, 0, 0, 3)
	tween(underline, 0.35, { Size = UDim2.new(0.7, 0, 0, 3) }, Enum.EasingStyle.Quart)
	subtitle.TextTransparency, subtitle.TextStrokeTransparency = 1, 1
	task.delay(0.2, function()
		if active and active.Token == token then tween(subtitle, 0.3, { TextTransparency = 0, TextStrokeTransparency = 0.4 }) end
	end)
	 
	task.delay(0.25, function()
		if active and active.Token == token then
			tween(titleGold, hold, { Position = UDim2.new(0.5, -8, 0.5, 0), TextTransparency = 0.5 })
			tween(titleEmber, hold, { Position = UDim2.new(0.5, 8, 0.5, 0), TextTransparency = 0.5 })
		end
	end)
	task.delay(hold, function() if active and active.Token == token then hideTitle(0.35) end end)
end

 
local function stopCameraTweens()
	for _, t in ipairs(cameraTweens) do t:Cancel() end
	table.clear(cameraTweens)
end
local function showOtherGuis()
	for _, other in ipairs(hiddenGuis) do
		if other.Parent then other.Enabled = true end
	end
	table.clear(hiddenGuis)
end
local function hideOtherGuis()
	for _, other in ipairs(player.PlayerGui:GetChildren()) do
		if other:IsA("ScreenGui") and other ~= gui and other.Enabled then
			other.Enabled = false
			table.insert(hiddenGuis, other)
		end
	end
end
local function releaseCamera()
	stopCameraTweens()
	showOtherGuis()
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
	if not Reset.ViewAllowed() or not Settings.Cinematic or not camera then return false end
	if not cameraState then
		cameraState = { Type = camera.CameraType, Subject = camera.CameraSubject, Fov = Fov.Base(camera) }
		camera.CameraType = Enum.CameraType.Scriptable
		hideOtherGuis()
	end
	return true
end
local function shot(fromCFrame, toCFrame, fovFrom, fovTo, time, style, direction)
	local camera = workspace.CurrentCamera
	if not cameraState or not camera then return end
	stopCameraTweens()
	camera.CFrame, camera.FieldOfView = fromCFrame, fovFrom
	table.insert(cameraTweens, tween(camera, time, { CFrame = toCFrame, FieldOfView = fovTo }, style or Enum.EasingStyle.Sine, direction or Enum.EasingDirection.Out))
end
local function bossParts(owner)
	local root = owner and owner:FindFirstChild("HumanoidRootPart")
	local head = owner and owner:FindFirstChild("Head")
	return root, head and head.Position or (root and root.Position + Vector3.new(0, 2.5, 0))
end

 
local function entrance(data, token)
	local owner = data.Owner
	local root, headPosition = bossParts(owner)
	if not root or not takeCamera() then return end
	local boss = root.CFrame
	local duration = math.clamp(tonumber(data.Duration) or 4.2, 1.5, 8)
	local raise = math.clamp(tonumber(data.Raise) or 1.6, 0.3, duration - 1)
	local ignite = math.clamp(tonumber(data.Ignite) or raise + 0.6, raise, duration - 0.6)
	local function alive() return cameraState and active and active.Token == token end
	local function at(t, fn) task.delay(t, function() if alive() then fn() end end) end
	 
	shot(CFrame.lookAt((boss * CFrame.new(-6, -1.6, 9)).Position, headPosition + Vector3.new(0, 1, 0)),
		CFrame.lookAt((boss * CFrame.new(-2.5, -1.4, 10)).Position, headPosition + Vector3.new(0, 1, 0)), 38, 36, raise * 0.5)
	 
	at(raise * 0.5, function()
		local face = boss * CFrame.new(0.6, 2.2, -4.2)
		shot(CFrame.lookAt(face.Position, headPosition), CFrame.lookAt((boss * CFrame.new(0.4, 2.1, -3.2)).Position, headPosition), 30, 24, raise * 0.5, Enum.EasingStyle.Quad)
	end)
	 
	at(raise, function()
		local from = (boss * CFrame.new(3.5, -2.2, -6)).Position
		shot(CFrame.lookAt(from, headPosition + Vector3.new(0, 3, 0)), CFrame.lookAt(from + Vector3.new(0, -0.5, 0), headPosition + Vector3.new(0, 16, 0)), 55, 70,
			ignite - raise, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	end)
	 
	at(ignite, function()
		local look = boss.LookVector
		local from = boss.Position - look * 14 + Vector3.new(0, 8, 0)
		local to = boss.Position - look * 34 + boss.RightVector * 12 + Vector3.new(0, 42, 0)
		local aim = boss.Position + look * 30
		shot(CFrame.lookAt(from, aim), CFrame.lookAt(to, aim), 95, 78, duration - ignite, Enum.EasingStyle.Quart)
	end)
	task.delay(duration + 0.05, function() if alive() then releaseCamera() end end)
end

 
local function bladeTip(owner)
	local sword = owner and owner:FindFirstChild("Basic Sword")
	local blade = sword and sword:FindFirstChild("Blade")
	local root, headPosition = bossParts(owner)
	if not blade or not blade:IsA("BasePart") then return headPosition and headPosition + Vector3.new(0, 6, 0) or Vector3.zero end
	local size, frame = blade.Size, blade.CFrame
	local axis, half = frame.UpVector, size.Y / 2
	if size.X > size.Y and size.X > size.Z then axis, half = frame.RightVector, size.X / 2
	elseif size.Z > size.Y then axis, half = frame.LookVector, size.Z / 2 end
	local a, b = frame.Position + axis * half, frame.Position - axis * half
	local from = root and root.Position or frame.Position
	return (a - from).Magnitude > (b - from).Magnitude and a or b
end
local function finaleCamera(data, token)
	local root, headPosition = bossParts(data.Owner)
	if not root or not takeCamera() then return end
	local boss = root.CFrame
	local freeze = math.clamp(tonumber(data.Freeze) or 1.4, 0.3, 4)
	 
	shot(CFrame.lookAt((boss * CFrame.new(0.5, 2.1, -3.8)).Position, headPosition), CFrame.lookAt((boss * CFrame.new(0.4, 2.1, -3.3)).Position, headPosition), 30, 27, 0.35)
	 
	task.delay(0.35, function()
		if not cameraState or not active or active.Token ~= token then return end
		local look, right = boss.LookVector, boss.RightVector
		local from = boss.Position - look * 22 - right * 16 + Vector3.new(0, 1, 0)
		local aim = boss.Position + look * 8 + Vector3.new(0, 70, 0)
		shot(CFrame.lookAt(from, aim), CFrame.lookAt(from + look * 5 + Vector3.new(0, -1, 0), aim + Vector3.new(0, 20, 0)), 78, 66, freeze - 0.35, Enum.EasingStyle.Sine)
	end)
end
local function sweepCamera(data)
	if not cameraState or not active then return end
	local root = data.Owner and data.Owner:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local boss = root.CFrame
	local look, right = boss.LookVector, boss.RightVector
	local sweep = math.clamp(tonumber(data.Duration) or 0.28, 0.1, 1)
	 
	local from = boss.Position + right * 95 + look * 45 + Vector3.new(0, 30, 0)
	local aim = boss.Position + look * 55 + Vector3.new(0, 35, 0)
	shot(CFrame.lookAt(from, aim), CFrame.lookAt(from - right * 10, aim - Vector3.new(0, 25, 0)), 72, 64, sweep, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end
local function cutCamera(data, token)
	if not cameraState or not active then return end
	local root = data.Owner and data.Owner:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local after = math.clamp(tonumber(data.Duration) or 2, 0.5, 4)
	local center = active.Center or root.Position
	local boss = root.CFrame
	local from = center - boss.LookVector * 18 + Vector3.new(0, 20, 0)
	local to = center - boss.LookVector * 50 + boss.RightVector * 20 + Vector3.new(0, 75, 0)
	shot(CFrame.lookAt(from, center), CFrame.lookAt(to, center), 100, 70, after * 0.85, Enum.EasingStyle.Quint)
	task.delay(after * 0.85, function() if active and active.Token == token then releaseCamera() end end)
end

local function clear()
	active = nil
	for t in pairs(visualTweens) do t:Cancel() end
	table.clear(visualTweens)
	Spam.Stop(true)
	releaseCamera()
	barTop.Size, barBottom.Size = UDim2.new(1, 0, 0, 0), UDim2.new(1, 0, 0, 0)
	flash.BackgroundTransparency = 1
	impact.BackgroundTransparency = 1
	titleBox.Visible = false
	for _, label in ipairs({ titleGold, titleEmber, titleMain, subtitle }) do label.TextTransparency, label.TextStrokeTransparency = 1, 1 end
	for _, item in ipairs(streaks:GetChildren()) do item:Destroy() end
	if grade then grade:Destroy() grade = nil end
	gui.Enabled = false
end

local function resetView()
	for t in pairs(visualTweens) do t:Cancel() end
	table.clear(visualTweens)
	releaseCamera()
	barTop.Size, barBottom.Size = UDim2.new(1, 0, 0, 0), UDim2.new(1, 0, 0, 0)
	flash.BackgroundTransparency = 1
	impact.BackgroundTransparency = 1
	titleBox.Visible = false
	for _, label in ipairs({ titleGold, titleEmber, titleMain, subtitle }) do label.TextTransparency, label.TextStrokeTransparency = 1, 1 end
	for _, item in ipairs(streaks:GetChildren()) do item:Destroy() end
	if grade then grade:Destroy() grade = nil end
	gui.Enabled = false
end

local function stage(data)
 gui.Enabled=Reset.ViewAllowed()
	local name = data.Stage
	local token = data.Token
	if data.ArenaFrame then Spam.SetArena(data.ArenaFrame, data.HalfX, data.HalfZ, data.FloorY) end
	if typeof(data.Center) == "Vector3" and active then active.Center = data.Center end
	if name == "Intro" then
		gui.Enabled = true
		if Settings.Cinematic then letterbox(true, 0.18, 90) end
		 
		setGrade({ Saturation = -0.55, Contrast = 0.35, TintColor = Color3.fromRGB(255, 232, 196), Brightness = -0.22 }, 0.5)
		entrance(data, token)
		local raise = math.clamp(tonumber(data.Raise) or 1.6, 0.3, 6)
		local ignite = math.clamp(tonumber(data.Ignite) or raise + 0.6, raise, 7)
		 
		task.delay(raise, function()
			if active and active.Token == token then
				setGrade({ Saturation = -0.15, Contrast = 0.25, TintColor = Color3.fromRGB(255, 240, 200), Brightness = 0.18 }, ignite - raise)
			end
		end)
		task.delay(ignite, function()
			if not active or active.Token ~= token then return end
			impactFrames({ Saturation = -0.1, Contrast = 0.2, TintColor = Color3.fromRGB(255, 244, 222), Brightness = -0.02 }, 0.5)
			task.delay(0.18, function()
				if not active or active.Token ~= token then return end
				flashScreen(0.1, 0.5)
				for _ = 1, 8 do screenStreak(true) end
				if not data.NoText then slamTitle("DEATH ROARS", "", 1.6) end
			end)
			Spam.Burst({ ArenaCrescent = 120, ArenaCut = 300, Streak = 220 })
			Spam.SetRates({ ArenaCrescent = 200, ArenaCut = 500, Streak = 380 })
		end)
	elseif name == "Barrage" then
		releaseCamera()
		letterbox(false, 0.3)
		setGrade({ Saturation = -0.2, Contrast = 0.15, TintColor = Color3.fromRGB(255, 245, 225), Brightness = -0.05 }, 0.3)
	elseif name == "Finale" then
		 
		gui.Enabled = true
		Spam.SetRates({})
		Spam.Freeze(true)
		if Settings.Cinematic then letterbox(true, 0.12, 100) end
		setGrade({ Saturation = -0.95, Contrast = 0.55, TintColor = Color3.fromRGB(255, 236, 190), Brightness = -0.12 }, 0.12)
		flashScreen(0.6, 0.25)
		finaleCamera(data, token)
		 
		local freeze = math.clamp(tonumber(data.Freeze) or 1.4, 0.3, 4)
		local owner = data.Owner
		task.delay(0.35, function()
			if not active or active.Token ~= token then return end
			Spam.Converge(bladeTip(owner), freeze - 0.45)
			setGrade({ Saturation = -0.35, Contrast = 0.45, TintColor = Color3.fromRGB(255, 226, 150), Brightness = 0.04 }, freeze - 0.35)
		end)
	elseif name == "Sweep" then
		 
		sweepCamera(data)
		for _ = 1, Settings.ReduceFlashing and 0 or 10 do screenStreak(false) end
		flashScreen(0.75, 0.2)
	elseif name == "Cut" then
		local after = math.clamp(tonumber(data.Duration) or 2, 0.5, 4)
		impactFrames({ Saturation = 0.1, Contrast = 0.15, TintColor = Color3.fromRGB(255, 244, 215), Brightness = 0.35 }, 0.05)
		task.delay(0.19, function()
			if not active or active.Token ~= token then return end
			Spam.Shatter()
			Spam.Burst({ Streak = 260, ArenaCut = 300 })
			if typeof(data.Impact) == "Vector3" then Spam.Radial(data.Impact + Vector3.new(0, 1, 0), 320, 160) end
			screenSlash(-18)
			task.delay(0.08, function() if active and active.Token == token then screenSlash(14) end end)
			flashScreen(0, 0.9)
			for _ = 1, Settings.ReduceFlashing and 2 or 18 do screenStreak(true) end
			cutCamera(data, token)
			 
			setGrade({ Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1), Brightness = 0 }, after * 0.9)
			letterbox(false, after * 0.8)
		end)
		task.delay(0.55, function()
			if active and active.Token == token then slamTitle("DEATH ROARS", "— the roar falls silent —", after * 0.55) end
		end)
	elseif name == "Hit" then
		screenStreak(true)
		flashScreen(data.Heavy and 0.5 or 0.82, 0.2, YELLOW)
	end
end

local connection = remote.OnClientEvent:Connect(function(kind, data)
	if kind ~= "DeathRoars" or type(data) ~= "table" then return end
	if data.Stage == "End" then
		if active and active.Token == data.Token then clear(data.Interrupted == true) end
		return
	end
	if player:GetAttribute("ViewAsServer") then return end
	local owner = data.Owner
	if typeof(owner) ~= "Instance" or not owner.Parent or math.min(4, math.floor(owner:GetAttribute("Phase") or 0)) ~= 4 then return end
	if data.Stage == "Hit" or data.Stage == "Cut" or data.Stage == "Sweep" then
		if active and active.Token == data.Token then stage(data) end
		return
	end
	if not active or active.Token ~= data.Token then
		active = { Token = data.Token, Owner = owner }
	end
	active.Stage = data.Stage
	active.Began = os.clock()
	active.Duration = math.clamp(tonumber(data.Duration) or 1, 0.1, 20)
	active.Until = os.clock() + active.Duration + 8
	active.NextStreak = os.clock()
	stage(data)
end)

local heartbeat = Run.Heartbeat:Connect(function()
	if not active then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local owner = active.Owner
	if (active.Stage ~= "Barrage" and os.clock() >= active.Until) or not owner.Parent
		or player:GetAttribute("ViewAsServer") or owner:GetAttribute("EncounterEnded")
		or math.min(4, math.floor(owner:GetAttribute("Phase") or 0)) ~= 4 then clear(true) return end
	if not Reset.ViewAllowed() then resetView()end
	local elapsed = os.clock() - active.Began
	if active.Stage == "Barrage" then
		 
		local p = math.clamp(elapsed / active.Duration, 0, 1)
		Spam.SetRates({ Swirl = Reset.ViewAllowed() and (6 + 6 * p) or 0, Near = Reset.ViewAllowed() and (20 + 20 * p) or 0, ArenaCrescent = 350 + 400 * p, ArenaCut = 1000 + 900 * p, Streak = Reset.ViewAllowed() and (300 + 400 * p) or 0 })
		if os.clock() >= active.NextStreak then
			active.NextStreak = os.clock() + 0.16 - 0.1 * p + rng:NextNumber(0, 0.06)
			screenStreak(false)
		end
	end
end)
local removing = player.CharacterRemoving:Connect(resetView)
Reset.Register(script,clear,resetView)
script.Destroying:Connect(function()
	clear(true)
	connection:Disconnect()
	heartbeat:Disconnect()
	removing:Disconnect()
	gui:Destroy()
end)

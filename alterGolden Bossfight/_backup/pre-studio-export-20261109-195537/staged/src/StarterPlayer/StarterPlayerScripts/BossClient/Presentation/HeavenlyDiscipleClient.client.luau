local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
local Reset=require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)
 
 
 
 
 
 
 
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")

local Settings = {
	Cinematic = false,  -- boss battle: no camera takeover or letterbox; night, title and flashes still play
	Title = true,  
	Night = true,  
	ReduceFlashing = false,  
}
local TITLE = "HEAVENLY DISCIPLE"
local SUBTITLE = "the star answers"
local WHITE = Color3.fromRGB(255, 252, 232)
local YELLOW = Color3.fromRGB(255, 226, 80)
local GOLD = Color3.fromRGB(255, 196, 40)
local STARLIGHT = Color3.fromRGB(170, 195, 255)
local INK = Color3.fromRGB(10, 14, 40)
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
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

local gui = new("ScreenGui", { Name = "HeavenlyDiscipleHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 85, Enabled = false },
	player:WaitForChild("PlayerGui"))
local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, gui)
local bursts = new("Frame", { Name = "Bursts", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, gui)
local edge = new("Frame", { Name = "Edge", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3 }, gui)
local edgeStroke = new("UIStroke", { Color = GOLD, Thickness = 0, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, edge)
local barTop = new("Frame", { Name = "LetterboxTop", Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = 4 }, gui)
local barBottom = new("Frame", { Name = "LetterboxBottom", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0),
	BackgroundColor3 = Color3.new(), BorderSizePixel = 0, ZIndex = 4 }, gui)

 
local titleBox = new("Frame", { Name = "Constellation", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.new(0.9, 0, 0, 150), BackgroundTransparency = 1, ZIndex = 7, Visible = false }, gui)
new("UISizeConstraint", { MaxSize = Vector2.new(1150, 150) }, titleBox)
local lineLayer = new("Frame", { Name = "Lines", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 7 }, titleBox)
local letterRow = new("Frame", { Name = "Letters", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.new(1, 0, 0, 78),
	BackgroundTransparency = 1, ZIndex = 8 }, titleBox)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, letterRow)
local subtitle = new("TextLabel", { Name = "Subtitle", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.18, 86), Size = UDim2.new(0.6, 0, 0, 30),
	BackgroundTransparency = 1, Font = Enum.Font.Fondamento, Text = "~ " .. SUBTITLE .. " ~", TextScaled = true, TextColor3 = STARLIGHT,
	TextTransparency = 1, TextStrokeColor3 = INK, TextStrokeTransparency = 1, ZIndex = 8 }, titleBox)
new("UITextSizeConstraint", { MaxTextSize = 30 }, subtitle)
local letters = {}
for i = 1, #TITLE do
	local ch = TITLE:sub(i, i)
	local holder = new("Frame", { Name = "L" .. i, LayoutOrder = i, Size = UDim2.new(0, ch == " " and 26 or 50, 1, 0), BackgroundTransparency = 1, ZIndex = 8 }, letterRow)
	local label, dot, glint
	if ch ~= " " then
		label = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1),
			BackgroundTransparency = 1, Font = Enum.Font.Bodoni, Text = ch, TextScaled = true, TextColor3 = WHITE, TextTransparency = 1,
			TextStrokeColor3 = INK, TextStrokeTransparency = 1, ZIndex = 9 }, holder)
		new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 240, 190)),
			ColorSequenceKeypoint.new(1, GOLD) }), Rotation = 90 }, label)
		dot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(7, 7),
			BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10 }, holder)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		glint = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1, Image = SPARK, ImageColor3 = WHITE, ImageTransparency = 1, ZIndex = 10 }, holder)
	end
	letters[i] = { Holder = holder, Label = label, Dot = dot, Glint = glint, Char = ch }
end

local grade, active, cameraState, savedClock, lastToken
local cameraTweens = {}
local hiddenGuis = {}
local function alive(token) return active and active.Token == token end

local function flashScreen(alpha, time, color)
	if Settings.ReduceFlashing then return end
	flash.BackgroundColor3 = color or WHITE
	flash.BackgroundTransparency = alpha
	tween(flash, time or 0.3, { BackgroundTransparency = 1 })
end
local function edgeGlow(thickness, time, color)
	edgeStroke.Color = color or GOLD
	edgeStroke.Thickness, edgeStroke.Transparency = thickness, 0.15
	tween(edgeStroke, time or 0.4, { Thickness = 0, Transparency = 1 })
end
 
local function starburst(size, x, y, color, life)
	local img = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x or rng:NextNumber(0.1, 0.9), y or rng:NextNumber(0.1, 0.9)),
		Size = UDim2.fromOffset(size * 0.3, size * 0.3), Rotation = rng:NextNumber(0, 90), BackgroundTransparency = 1, Image = SPARK,
		ImageColor3 = color or WHITE, ImageTransparency = 0, ZIndex = 2 }, bursts)
	tween(img, (life or 0.4) * 0.35, { Size = UDim2.fromOffset(size, size) }, Enum.EasingStyle.Quart)
	tween(img, life or 0.4, { ImageTransparency = 1, Rotation = img.Rotation + 45 })
	task.delay((life or 0.4) + 0.05, function() img:Destroy() end)
end
local function setGrade(goal, time)
	if not grade then
		grade = new("ColorCorrectionEffect", { Name = "HeavenlyDiscipleGrade", Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }, Lighting)
	end
	if time and time > 0 then tween(grade, time, goal) else for k, v in pairs(goal) do grade[k] = v end end
end
local function letterbox(on, time, height)
	local h = on and (height or 64) or 0
	tween(barTop, time or 0.4, { Size = UDim2.new(1, 0, 0, h) }, Enum.EasingStyle.Quart)
	tween(barBottom, time or 0.4, { Size = UDim2.new(1, 0, 0, h) }, Enum.EasingStyle.Quart)
end
 
local nightRevision=0
 -- night goes through the VFXEngine lighting arbiter instead of tweening ClockTime directly
local LightingArbiter = require(game.ReplicatedStorage:WaitForChild("VFXEngine"):WaitForChild("Lighting"))
local function nightfall(on, time)
	if not Settings.Night then return end
	if on then
		LightingArbiter.Push("HeavenlyNight", { Lighting = { ClockTime = 0.2 } }, { Priority = 40, Fade = time })
	else
		LightingArbiter.Pop("HeavenlyNight", time)
	end
end

 
local function constellationTitle(hold)
	if not Settings.Title then return end
	local token = active and active.Token
	titleBox.Visible = true
	for _, line in ipairs(lineLayer:GetChildren()) do line:Destroy() end
	subtitle.TextTransparency, subtitle.TextStrokeTransparency = 1, 1
	local stars = {}
	for _, l in ipairs(letters) do
		if l.Label then
			l.Label.TextTransparency, l.Label.TextStrokeTransparency = 1, 1
			l.Label.Position = UDim2.fromScale(0.5, 0.62)
			l.Dot.BackgroundTransparency = 1
			l.Glint.ImageTransparency, l.Glint.Size = 1, UDim2.fromOffset(0, 0)
			 
			l.Dot.Position = UDim2.fromScale(0.5, rng:NextNumber(0.1, 0.9))
			table.insert(stars, l)
		end
	end
	local each = 0.045
	for i, l in ipairs(stars) do
		task.delay((i - 1) * each, function()
			if not alive(token) then return end
			l.Dot.BackgroundTransparency = 0
			l.Glint.ImageTransparency = 0
			l.Glint.Size = UDim2.fromOffset(4, 4)
			tween(l.Glint, 0.18, { Size = UDim2.fromOffset(46, 46) }, Enum.EasingStyle.Quart)
			tween(l.Glint, 0.5, { ImageTransparency = 1, Rotation = 45 })
			 
			local prev = stars[i - 1]
			if prev then
				local a = prev.Dot.AbsolutePosition + prev.Dot.AbsoluteSize / 2 - lineLayer.AbsolutePosition
				local b = l.Dot.AbsolutePosition + l.Dot.AbsoluteSize / 2 - lineLayer.AbsolutePosition
				local d = b - a
				local line = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(a.X, a.Y), Size = UDim2.fromOffset(0, 2),
					Rotation = math.deg(math.atan2(d.Y, d.X)), BackgroundColor3 = STARLIGHT, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 7 }, lineLayer)
				tween(line, 0.12, { Size = UDim2.fromOffset(d.Magnitude, 2) }, Enum.EasingStyle.Quad)
			end
		end)
	end
	 
	local bloomAt = #stars * each + 0.12
	task.delay(bloomAt, function()
		if not alive(token) then return end
		for i, l in ipairs(stars) do
			task.delay((i - 1) * 0.022, function()
				if not alive(token) then return end
				tween(l.Label, 0.35, { TextTransparency = 0, TextStrokeTransparency = 0.55, Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quart)
				tween(l.Dot, 0.5, { BackgroundTransparency = 0.5, Size = UDim2.fromOffset(4, 4) })
			end)
		end
		tween(subtitle, 0.6, { TextTransparency = 0.05, TextStrokeTransparency = 0.6 })
		for _, line in ipairs(lineLayer:GetChildren()) do tween(line, 0.8, { BackgroundTransparency = 0.6 }) end
	end)
	task.delay(bloomAt + hold, function()
		if not alive(token) then return end
		for _, l in ipairs(stars) do
			tween(l.Label, 0.6, { TextTransparency = 1, TextStrokeTransparency = 1, Position = UDim2.fromScale(0.5, 0.35) })
			tween(l.Dot, 0.9, { BackgroundTransparency = 1 })
		end
		tween(subtitle, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
		for _, line in ipairs(lineLayer:GetChildren()) do tween(line, 0.9, { BackgroundTransparency = 1 }) end
	end)
end

 
local function stopCameraTweens()
	for _, t in ipairs(cameraTweens) do t:Cancel() end
	table.clear(cameraTweens)
end
local function releaseCamera()
	stopCameraTweens()
	for _, other in ipairs(hiddenGuis) do if other.Parent then other.Enabled = true end end
	table.clear(hiddenGuis)
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
		for _, other in ipairs(player.PlayerGui:GetChildren()) do
			if other:IsA("ScreenGui") and other ~= gui and other.Enabled then
				other.Enabled = false
				table.insert(hiddenGuis, other)
			end
		end
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
 
local function path(time, fn)
	local camera = workspace.CurrentCamera
	if not cameraState or not camera then return end
	stopCameraTweens()
	local token = active and active.Token
	local start = os.clock()
	local connection
	connection = Run.RenderStepped:Connect(function()
		local t = (os.clock() - start) / time
		if not cameraState or not alive(token) or t > 1 then
			connection:Disconnect()
			return
		end
		local frame, fov = fn(t)
		camera.CFrame, camera.FieldOfView = frame, fov
	end)
	table.insert(cameraTweens, { Cancel = function() connection:Disconnect() end })
end
local function bossParts(owner)
	local root = owner and owner:FindFirstChild("HumanoidRootPart")
	local head = owner and owner:FindFirstChild("Head")
	return root, head and head.Position or (root and root.Position + Vector3.new(0, 2.5, 0))
end
local function smooth(t) return t * t * (3 - 2 * t) end

local function opening(data, token)
	local root, headPosition = bossParts(data.Owner)
	if not root or typeof(data.StarPosition) ~= "Vector3" or not takeCamera() then return end
	local boss = root.CFrame
	local star = data.StarPosition
	local tStar = math.clamp(tonumber(data.Star) or 1.8, 0.3, 4)
	local tCharge = math.clamp(tonumber(data.Charge) or 1.2, 0.3, 4)
	local tDraw = math.clamp(tonumber(data.Draw) or 0.8, 0.2, 3)
	local function at(t, fn) task.delay(t, function() if cameraState and alive(token) then fn() end end) end
	 
	path(tStar, function(t)
		local s = smooth(t)
		local position = (boss * CFrame.new(1.5, 1.5 + 9 * s, 9 - 3 * s)).Position
		local aim = headPosition:Lerp(star, s ^ 1.4)
		return CFrame.lookAt(position, aim), 55 + 15 * s
	end)
	 
	at(tStar, function()
		local _, head = bossParts(data.Owner)
		local chest = (head or headPosition) - Vector3.new(0, 1.2, 0)
		path(tCharge, function(t)
			local s = smooth(t)
			local a = math.rad(-60 + 140 * s)
			local r = 12 - 3 * s
			local offset = (boss.LookVector * math.cos(a) + boss.RightVector * math.sin(a)) * r
			return CFrame.lookAt(chest + offset + Vector3.new(0, 0.6 - 1.2 * s, 0), chest), 48 - 6 * s
		end)
	end)
	 
	at(tStar + tCharge, function()
		local hand = data.Owner and data.Owner:FindFirstChild("LeftHand")
		local h = hand and hand.Position or headPosition
		local dir = (star - h).Unit
		local side = dir:Cross(Vector3.yAxis)
		side = side.Magnitude > 1e-3 and side.Unit or Vector3.xAxis
		local from = h - dir * 5 + side * 1.6 - Vector3.new(0, 0.6, 0)
		shot(CFrame.lookAt(from, star), CFrame.lookAt(h - dir * 3.4 + side * 1.2, star), 58, 40, tDraw, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
end
local function rideArrow(data)
	if not cameraState then return end
	local from, to = data.From, data.To
	if typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3" then return end
	local flight = math.clamp(tonumber(data.Flight) or 0.5, 0.1, 2)
	local dir = (to - from).Unit
	local side = dir:Cross(Vector3.yAxis)
	side = side.Magnitude > 1e-3 and side.Unit or Vector3.xAxis
	shot(CFrame.lookAt(from - dir * 6 + side * 3, to), CFrame.lookAt(to - dir * 30 + side * 8, to), 70, 92, flight, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end
 
local function bloomShot(data, token)
	if not cameraState then return end
	local root = data.Owner and data.Owner:FindFirstChild("HumanoidRootPart")
	local star = data.StarPosition
	if not root or typeof(star) ~= "Vector3" then return end
	local hold = math.clamp(tonumber(data.Bloom) or 1.3, 0.5, 3)
	local ground = root.Position
	local out = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	out = out.Magnitude > 0.01 and out.Unit or Vector3.xAxis
	local side = out:Cross(Vector3.yAxis)
	path(hold, function(t)
		local s = smooth(t)
		local position = star + out * (70 + 10 * s) + side * (20 - 30 * s) + Vector3.new(0, 14 - 8 * s, 0)
		local aim = ground:Lerp(star, 0.42) + Vector3.new(0, -4, 0)
		return CFrame.lookAt(position, aim), 74 - 6 * s
	end)
	task.delay(hold, function() if alive(token) then releaseCamera() end end)
end

local function clear(immediate)
	active = nil
	for t in pairs(visualTweens) do t:Cancel() end
	table.clear(visualTweens)
	releaseCamera()
	barTop.Size, barBottom.Size = UDim2.new(1, 0, 0, 0), UDim2.new(1, 0, 0, 0)
	flash.BackgroundTransparency = 1
	edgeStroke.Thickness, edgeStroke.Transparency = 0, 1
	titleBox.Visible = false
	for _, item in ipairs(bursts:GetChildren()) do item:Destroy() end
	for _, line in ipairs(lineLayer:GetChildren()) do line:Destroy() end
	if grade then
		local g = grade
		grade = nil
		Tween:Create(g, TweenInfo.new(1), { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }):Play()
		task.delay(1.05, function() g:Destroy() end)
	end
	if immediate then
  nightRevision+=1
  LightingArbiter.Pop("HeavenlyNight",0.3)
 else nightfall(false,1.4)end
	gui.Enabled = false
end

local function resetView()
	for t in pairs(visualTweens) do t:Cancel() end
	table.clear(visualTweens)
	releaseCamera()
	barTop.Size, barBottom.Size = UDim2.new(1, 0, 0, 0), UDim2.new(1, 0, 0, 0)
	flash.BackgroundTransparency = 1
	edgeStroke.Thickness, edgeStroke.Transparency = 0, 1
	titleBox.Visible = false
	for _, item in ipairs(bursts:GetChildren()) do item:Destroy() end
	for _, line in ipairs(lineLayer:GetChildren()) do line:Destroy() end
	if grade then
		local g = grade
		grade = nil
		Tween:Create(g, TweenInfo.new(1), { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }):Play()
		task.delay(1.05, function() g:Destroy() end)
	end
	nightRevision+=1
 LightingArbiter.Pop("HeavenlyNight",0.3)
	gui.Enabled = false
end

local function stage(data)
 gui.Enabled=Reset.ViewAllowed()
	local name = data.Stage
	local token = data.Token
	if name == "Intro" then
		gui.Enabled = true
		if Settings.Cinematic then letterbox(true, 0.35, 78) end
		local tStar = math.clamp(tonumber(data.Star) or 1.8, 0.3, 4)
		nightfall(true, tStar)
		setGrade({ Saturation = -0.3, Contrast = 0.18, TintColor = Color3.fromRGB(205, 218, 255), Brightness = -0.04 }, tStar)
		opening(data, token)
		task.delay(tStar, function()
			if alive(token) then
				 
				setGrade({ Saturation = -0.15, Contrast = 0.25, TintColor = Color3.fromRGB(235, 232, 240), Brightness = 0 }, 0.5)
				flashScreen(0.75, 0.25, YELLOW)
			end
		end)
	elseif name == "Release" then
		flashScreen(0.6, 0.25)
		starburst(220, 0.5, 0.55, WHITE, 0.4)
		rideArrow(data)
	elseif name == "Bloom" then
		flashScreen(0.05, 0.9)
		for _ = 1, 8 do starburst(rng:NextNumber(90, 220), nil, nil, rng:NextNumber() < 0.5 and WHITE or YELLOW, rng:NextNumber(0.4, 0.8)) end
		starburst(700, 0.5, 0.5, WHITE, 0.7)
		setGrade({ Saturation = 0.05, Contrast = 0.15, TintColor = Color3.fromRGB(225, 232, 255), Brightness = 0.04 }, 0.9)
		constellationTitle(1.25)
		bloomShot(data, token)
	elseif name == "Rain" then
		letterbox(false, 0.6)
	elseif name == "Constellation" then
		edgeGlow(8, 0.6, STARLIGHT)
	elseif name == "Spiral" then
		edgeGlow(9, 0.5, GOLD)
	elseif name == "Final" then
		edgeGlow(16, tonumber(data.Duration) or 1)
		letterbox(true, 0.3, 40)
		setGrade({ Saturation = -0.4, Contrast = 0.4, TintColor = Color3.fromRGB(255, 236, 190), Brightness = -0.05 }, 0.3)
	elseif name == "Judged" then
		flashScreen(0.1, 0.8, WHITE)
		for _ = 1, 12 do starburst(rng:NextNumber(80, 260), nil, nil, rng:NextNumber() < 0.5 and WHITE or GOLD, rng:NextNumber(0.4, 0.9)) end
		letterbox(false, 0.5)
		setGrade({ Saturation = 0, Contrast = 0.15, TintColor = Color3.fromRGB(225, 232, 255), Brightness = 0.05 }, 0.5)
	elseif name == "Collapse" then
		flashScreen(0.55, 0.6)
		nightfall(false, 1.6)
		setGrade({ Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1), Brightness = 0 }, 1.4)
	end
end

 
local function hit(data)
	local wasEnabled = gui.Enabled
	gui.Enabled = true
	if data.Stun then
		flashScreen(0.7, 0.25, YELLOW)
		edgeGlow(10, 0.5)
		starburst(260, rng:NextNumber(0.4, 0.6), rng:NextNumber(0.45, 0.6), WHITE, 0.45)
		for _ = 1, 3 do starburst(rng:NextNumber(60, 120), nil, nil, YELLOW, 0.35) end
	else
		flashScreen(0.88, 0.16, YELLOW)
		starburst(rng:NextNumber(90, 140), rng:NextNumber(0.3, 0.7), rng:NextNumber(0.3, 0.7), YELLOW, 0.3)
	end
	if not wasEnabled and not active then
		task.delay(0.6, function() if not active then gui.Enabled = false end end)
	end
end

local function ownerValid(owner)
	local phase = typeof(owner) == "Instance" and owner:GetAttribute("Phase")
	return typeof(owner) == "Instance" and owner.Parent ~= nil and (phase == 4.5 or phase == 5)
end

local connection = remote.OnClientEvent:Connect(function(kind, data)
	if kind ~= "HeavenlyDisciple" or type(data) ~= "table" then return end
	if data.Stage == "End" then
		if active and active.Token == data.Token then clear() end
		return
	end
	if player:GetAttribute("ViewAsServer") then return end
	if not ownerValid(data.Owner) then return end
	 
	if data.Stage == "Hit" then
		if data.Token == lastToken then hit(data) end
		return
	end
	if data.Stage ~= "Intro" and not (active and active.Token == data.Token) then return end
	if data.Stage == "Intro" then
		if active then clear() end
		active = { Token = data.Token, Owner = data.Owner, Until = os.clock() + 60 }
		lastToken = data.Token
	end
	stage(data)
end)

local heartbeat = Run.Heartbeat:Connect(function()
	if not active then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local owner = active.Owner
	if os.clock() >= active.Until or not ownerValid(owner)
		or player:GetAttribute("ViewAsServer") or owner:GetAttribute("EncounterEnded") then
		clear(true)
	elseif not Reset.ViewAllowed() then resetView()end
end)
local removing = player.CharacterRemoving:Connect(resetView)
Reset.Register(script,function()clear(true)end,resetView)
script.Destroying:Connect(function()
	clear()
	connection:Disconnect()
	heartbeat:Disconnect()
	removing:Disconnect()
	gui:Destroy()
end)

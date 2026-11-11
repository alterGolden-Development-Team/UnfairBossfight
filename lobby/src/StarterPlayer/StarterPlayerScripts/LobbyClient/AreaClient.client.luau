--!nonstrict
-- Everything the player sees change between worlds: fades and title cards, each world's light and colour (a colour script: gold-hour sky, warm
-- gilded hall, bright noon sea, drained black and white), spinning portal rings, the brothers' endless fight and the cutscene when you reach them.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Fade = require(ReplicatedStorage.Lobby.Fade)
local Freeze = require(ReplicatedStorage.Lobby.Freeze)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)

local player = Players.LocalPlayer
local remote = LobbyRemotes.get("Area")

local TITLES = {
	Hub = "The Sanctum", Palace = "The Golden Palace", Island = "The Private Island", Forest = "The Divided Wood",
	Tutorial = "Azusa's Training Grounds", Glitch = "!A GL!TC3D PL@CE!",
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local MOODS = {
	Hub = { Clock = 16.4, Brightness = 2.6, Ambient = rgb(118, 108, 104), Outdoor = rgb(150, 138, 132), Density = 0.3, Offset = 0.15, AtmoColor = rgb(255, 214, 170), Decay = rgb(160, 120, 150), Haze = 1.2, Glare = 0.4, Saturation = 0.08, Contrast = 0.05, Tint = rgb(255, 248, 238), Bloom = 0.22, Exposure = -0.1 },
	Palace = { Clock = 18, Brightness = 0.2, Ambient = rgb(52, 40, 28), Outdoor = rgb(30, 24, 18), Density = 0.1, Offset = 0, AtmoColor = rgb(255, 200, 130), Decay = rgb(120, 80, 40), Haze = 0.5, Glare = 0, Saturation = 0.12, Contrast = 0.12, Tint = rgb(255, 240, 216), Bloom = 0.15, Exposure = -0.75 },
	Island = { Clock = 13.2, Brightness = 3.0, Ambient = rgb(130, 136, 146), Outdoor = rgb(160, 170, 180), Density = 0.4, Offset = 0.05, AtmoColor = rgb(214, 230, 242), Decay = rgb(150, 180, 210), Haze = 2.4, Glare = 0.2, Saturation = 0.16, Contrast = 0.04, Tint = rgb(255, 255, 255), Bloom = 0.2, Exposure = 0 },
	Forest = { Clock = 10, Brightness = 1.6, Ambient = rgb(120, 120, 120), Outdoor = rgb(120, 120, 120), Density = 0.58, Offset = 0.12, AtmoColor = rgb(214, 214, 214), Decay = rgb(120, 120, 120), Haze = 2.2, Glare = 0, Saturation = -1, Contrast = 0.22, Tint = rgb(255, 255, 255), Bloom = 0.1, Exposure = 0 },
	Stage = { Clock = 20, Brightness = 0.4, Ambient = rgb(96, 84, 76), Outdoor = rgb(60, 54, 50), Density = 0, Offset = 0, AtmoColor = rgb(40, 30, 28), Decay = rgb(20, 16, 14), Haze = 0, Glare = 0, Saturation = 0.1, Contrast = 0.1, Tint = rgb(255, 246, 232), Bloom = 0.2, Exposure = -0.2 },
}

local function effect(class)
	local e = Lighting:FindFirstChildOfClass(class)
	if not e then
		e = Instance.new(class)
		e.Parent = Lighting
	end
	return e
end

local function applyMood(name)
	local m = MOODS[name] or MOODS.Hub
	Lighting.ClockTime = m.Clock
	Lighting.Brightness = m.Brightness
	Lighting.Ambient = m.Ambient
	Lighting.OutdoorAmbient = m.Outdoor
	Lighting.ExposureCompensation = m.Exposure or 0
	local a = effect("Atmosphere")
	a.Density, a.Offset, a.Color, a.Decay, a.Haze, a.Glare = m.Density, m.Offset, m.AtmoColor, m.Decay, m.Haze, m.Glare
	local c = effect("ColorCorrectionEffect")
	c.Saturation, c.Contrast, c.TintColor = m.Saturation, m.Contrast, m.Tint
	local b = effect("BloomEffect")
	b.Intensity, b.Threshold, b.Size = m.Bloom, 1.4, 18
end
applyMood("Hub")

-- Only the area you are in is drawn. The worlds share one sky, far apart, and would otherwise hang on each other's horizon as floating
-- boxes. Parts are hidden with LocalTransparencyModifier on this client only: nothing is reparented, so every script still finds what
-- it waits for, and collisions do not change. (The island's sea is terrain, which cannot be hidden; it is far enough out to be lost in haze.)
local AREA_PARTS = {
	Hub = { "Hub", "Portals", "Shop" },
	Palace = { "Palace", "PartyRooms" },
	Island = { "Island" },
	Forest = { "Forest" },
	Stage = { "Stage", "ClassTrainingDummy", "Performers" }, -- the dummy lives in Workspace; its DPS label is always on top, so hide it elsewhere
}
local hidden = {} -- container -> true while hidden
local watching = {}

local function containers(area)
	local list = {}
	local world = workspace:FindFirstChild("World")
	for _, name in AREA_PARTS[area] or {} do
		local item = (world and world:FindFirstChild(name)) or workspace:FindFirstChild(name)
		if item then
			table.insert(list, item)
		end
	end
	return list
end

-- Hiding an area also switches off what LocalTransparencyModifier cannot reach: its lights, particles, fire, beams and floating signs,
-- so nothing from another world glows on the horizon. What was enabled is remembered and switched back on.
local switchedOff = {} -- instance -> true while this script turned it off
local function quiet(d, hide)
	if d:IsA("BasePart") then
		d.LocalTransparencyModifier = hide and 1 or 0
	elseif d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Sparkles") then
		if hide and d.Enabled then
			d.Enabled = false
			switchedOff[d] = true
		elseif not hide and switchedOff[d] then
			d.Enabled = true
			switchedOff[d] = nil
		end
	elseif d:IsA("LayerCollector") then -- BillboardGui and SurfaceGui
		if hide and d.Enabled then
			d.Enabled = false
			switchedOff[d] = true
		elseif not hide and switchedOff[d] then
			d.Enabled = true
			switchedOff[d] = nil
		end
	end
end

local function setHidden(container, hide)
	if (hidden[container] or false) == hide then
		return
	end
	hidden[container] = hide or nil
	for _, d in container:GetDescendants() do
		quiet(d, hide)
	end
	if not watching[container] then
		watching[container] = container.DescendantAdded:Connect(function(d)
			if hidden[container] then
				quiet(d, true)
			end
		end)
	end
end

local function reveal(area)
	for _, item in containers(area) do
		setHidden(item, false)
	end
end

local function showOnly(area)
	if not AREA_PARTS[area] then
		return
	end
	reveal(area)
	for name in AREA_PARTS do
		if name ~= area then
			for _, item in containers(name) do
				setHidden(item, true)
			end
		end
	end
end

local function currentArea()
	return player:GetAttribute("Area") or "Hub"
end

task.spawn(function()
	workspace:WaitForChild("World", 30)
	workspace:WaitForChild("PartyRooms", 30)
	showOnly(currentArea())
end)

-- the shop's showroom borrows the lighting while it is open
local api = Instance.new("BindableEvent")
api.Name = "UnfairMood"
api.Parent = player:WaitForChild("PlayerScripts")
api.Event:Connect(function(name)
	local area = name == "Area" and currentArea() or name
	applyMood(area)
	showOnly(area)
end)

remote.OnClientEvent:Connect(function(action, area)
	if action == "FadeOut" then
		reveal(area) -- draw where you are going before the server moves you there
		task.spawn(Fade.Out, 0.3, TITLES[area])
	elseif action == "FadeIn" then
		applyMood(area)
		showOnly(area)
		Fade.In(0.6)
	elseif action == "Notice" then
		local gui = player.PlayerGui:FindFirstChild("PadInfoGui")
		if gui then
			task.spawn(function()
				local toast = Instance.new("TextLabel")
				toast.AnchorPoint = Vector2.new(0.5, 1)
				toast.Position = UDim2.new(0.5, 0, 1, -220)
				toast.Size = UDim2.fromOffset(360, 34)
				toast.BackgroundColor3 = rgb(20, 17, 16)
				toast.TextColor3 = Color3.new(1, 1, 1)
				toast.Font = Enum.Font.GothamMedium
				toast.TextSize = 15
				toast.Text = tostring(area)
				toast.Parent = gui
				task.wait(3)
				toast:Destroy()
			end)
		end
	end
end)

player:GetAttributeChangedSignal("Area"):Connect(function()
	applyMood(player:GetAttribute("Area"))
	showOnly(currentArea())
end)

-- spinning portal rings (three or so at a time, cheap) ----------------------------------------------------------------
local spins = {}
local spinGuis = {}
local function addSpin(model)
	if model:IsA("Model") and model.PrimaryPart then
		table.insert(spins, { model = model, speed = model:GetAttribute("SpinSpeed") or 0.4, base = model:GetPivot() })
	end
end
for _, m in CollectionService:GetTagged("UnfairSpin") do
	addSpin(m)
end
CollectionService:GetInstanceAddedSignal("UnfairSpin"):Connect(addSpin)
for _, g in CollectionService:GetTagged("UnfairSpinGui") do
	table.insert(spinGuis, g)
end
CollectionService:GetInstanceAddedSignal("UnfairSpinGui"):Connect(function(g)
	table.insert(spinGuis, g)
end)

local spinTime = 0
RunService.RenderStepped:Connect(function(dt)
	spinTime += dt
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local position = root and root.Position or workspace.CurrentCamera.CFrame.Position
	for _, s in spins do
		-- only ones you can actually see from here
		if (s.base.Position - position).Magnitude < 400 then
			s.model:PivotTo(s.base * CFrame.Angles(0, 0, spinTime * s.speed))
		end
	end
	for _, g in spinGuis do
		g.Rotation = spinTime * 26
	end
end)

-- The brothers fight forever: a jointed duel (BrotherRig), the attacker swapping each exchange. Local, so it costs the server nothing.
task.spawn(function()
	local BrotherRig = require(ReplicatedStorage.Lobby.BrotherRig)
	local world = workspace:WaitForChild("World", 30)
	local forest = world and world:WaitForChild("Forest", 30)
	local fight = forest and forest:WaitForChild("TheFight", 30)
	if not fight then
		return
	end
	local jeff, fred = fight:WaitForChild("Jeff", 10), fight:WaitForChild("Fred", 10)
	if not jeff or not fred or not jeff:FindFirstChild("Torso") then
		return
	end
	local homes = { [jeff] = jeff:GetPivot(), [fred] = fred:GetPivot() }
	local center = (homes[jeff].Position + homes[fred].Position) / 2 + Vector3.new(0, 7, 0)

	local function spark(color)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Size = Vector3.new(1, 1, 1)
		p.Shape = Enum.PartType.Ball
		p.CFrame = CFrame.new(center + Vector3.new(math.random(-10, 10) / 10, math.random(-10, 10) / 10, math.random(-10, 10) / 10))
		p.Parent = workspace
		TweenService:Create(p, TweenInfo.new(0.3), { Size = Vector3.new(7, 7, 7), Transparency = 1 }):Play()
		task.delay(0.35, function()
			p:Destroy()
		end)
	end

	-- each brother walks his own list of beats; poses ease from one beat's pose to the next
	local function track(beats)
		local list, t = {}, 0
		for _, b in beats do
			t += b[2]
			table.insert(list, { pose = BrotherRig.POSES[b[1]], at = t, clash = b.clash })
		end
		return list, t
	end
	local attack, length = track(BrotherRig.EXCHANGE.attacker)
	local defend = track(BrotherRig.EXCHANGE.defender)

	local function sample(list, t)
		local prev = list[#list].pose
		local start = 0
		for _, beat in list do
			if t <= beat.at then
				local a = math.clamp((t - start) / (beat.at - start), 0, 1)
				a = a * a * (3 - 2 * a)
				return BrotherRig.lerp(prev, beat.pose, a)
			end
			prev, start = beat.pose, beat.at
		end
		return prev
	end

	local exchange, t, sparked = 0, 0, false
	RunService.Heartbeat:Connect(function(dt)
		if player:GetAttribute("Area") ~= "Forest" then
			return
		end
		t += dt
		if t >= length then
			t -= length
			exchange += 1
			sparked = false
		end
		local attacker = exchange % 2 == 0 and jeff or fred
		local defender = attacker == jeff and fred or jeff
		BrotherRig.pose(attacker, homes[attacker], sample(attack, t))
		BrotherRig.pose(defender, homes[defender], sample(defend, t))
		for _, beat in attack do
			if beat.clash and not sparked and t >= beat.at then
				sparked = true
				spark(Color3.new(1, 1, 1))
				spark(exchange % 2 == 0 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1))
			end
		end
	end)
end)

-- Doors that swing open as you come near (the golden gate's leaves). Each is a Model tagged UnfairDoor; Swing is the sign of
-- the turn that opens it, OpenAngle the angle, Range how close you must be.
task.spawn(function()
	local doors = {}
	local function addDoor(model)
		if model:IsA("Model") then
			table.insert(doors, { model = model, closed = model:GetPivot(), open = 0 })
		end
	end
	for _, d in CollectionService:GetTagged("UnfairDoor") do
		addDoor(d)
	end
	CollectionService:GetInstanceAddedSignal("UnfairDoor"):Connect(addDoor)
	RunService.Heartbeat:Connect(function(dt)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		for _, d in doors do
			local near = root and (root.Position - d.closed.Position).Magnitude < (d.model:GetAttribute("Range") or 40)
			local goal = near and 1 or 0
			if d.open ~= goal then
				d.open = goal > d.open and math.min(1, d.open + dt * 0.8) or math.max(0, d.open - dt * 0.6)
				local a = d.open * d.open * (3 - 2 * d.open)
				local angle = math.rad((d.model:GetAttribute("OpenAngle") or 90) * a) * (d.model:GetAttribute("Swing") or 1)
				d.model:PivotTo(d.closed * CFrame.Angles(0, angle, 0))
			end
		end
	end)
end)

-- The cutscene at the clearing: letterbox, a slow pass around the fight, two lines, then back to you. Once per visit. ---------
task.spawn(function()
	local world = workspace:WaitForChild("World", 30)
	local forest = world and world:WaitForChild("Forest", 30)
	local trigger = forest and forest:WaitForChild("CutTrigger", 30)
	if not trigger then
		return
	end
	local played = false
	player:GetAttributeChangedSignal("Area"):Connect(function()
		if player:GetAttribute("Area") ~= "Forest" then
			played = false
		end
	end)

	local function bar(top)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0, top and 1 or 0)
		f.Position = UDim2.fromScale(0, top and 0 or 1)
		f.Size = UDim2.fromScale(1, 0.14)
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		return f
	end

	local function play()
		local camera = workspace.CurrentCamera
		local center = trigger.Position + Vector3.new(0, -4, -66)
		local gui = Instance.new("ScreenGui")
		gui.Name = "CutGui"
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 900
		gui.Parent = player.PlayerGui
		local top, bottom = bar(true), bar(false)
		top.Parent, bottom.Parent = gui, gui
		TweenService:Create(top, TweenInfo.new(0.5), { Position = UDim2.fromScale(0, 0.14) }):Play()
		TweenService:Create(bottom, TweenInfo.new(0.5), { Position = UDim2.fromScale(0, 0.86) }):Play()
		local line = Instance.new("TextLabel")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromScale(0.5, 0.92)
		line.Size = UDim2.fromScale(0.8, 0.08)
		line.BackgroundTransparency = 1
		line.Font = Enum.Font.Garamond
		line.TextSize = 34
		line.TextColor3 = Color3.new(1, 1, 1)
		line.Text = ""
		line.Parent = gui

		local previousType, previousSubject = camera.CameraType, camera.CameraSubject
		camera.CameraType = Enum.CameraType.Scriptable
		Freeze.On()
		task.spawn(function()
			task.wait(1.2)
			line.Text = "\"Still standing, brother?\""
			task.wait(2.2)
			line.Text = "\"Only because you are.\""
			task.wait(2)
			line.Text = ""
		end)
		local t, duration = 0, 6
		while t < duration do
			t += RunService.RenderStepped:Wait()
			local a = t / duration
			local yaw = math.rad(-65 + a * 130)
			local position = center + Vector3.new(math.sin(yaw) * 24, 7 + math.sin(a * math.pi) * 3, math.cos(yaw) * 24)
			camera.CFrame = CFrame.lookAt(position, center + Vector3.new(0, 5, 0))
		end
		camera.CameraType, camera.CameraSubject = previousType, previousSubject
		Freeze.Off()
		gui:Destroy()
	end

	trigger.Touched:Connect(function(hit)
		if played or not player.Character or hit.Parent ~= player.Character or hit.Name ~= "HumanoidRootPart" then
			return
		end
		played = true
		task.spawn(play)
	end)
end)

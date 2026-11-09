local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RS = game:GetService("ReplicatedStorage")
local SB = require(RS:WaitForChild("BossShared"):WaitForChild("SonicBlaster"))
local Lib = require(RS:WaitForChild("VFXEngine"):WaitForChild("Library"))
local player = Players.LocalPlayer
local P = {}
local UP = Vector3.yAxis
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local GOLD = Color3.fromRGB(255, 206, 84)
local SHINE = Color3.fromRGB(255, 244, 200)
local ICE = Color3.fromRGB(190, 230, 255)
local VIOLET = Color3.fromRGB(150, 90, 255)
local DEEP = Color3.fromRGB(40, 16, 90)
local TAU = math.pi * 2
local FAR = CFrame.new(0, -5000, 0)
local PLAYER_R = 0.85
local BAR = 0.115  -- the letterbox bars' height (fraction of the screen)

local function rootOf(m) return m and m.Parent and m:FindFirstChild("HumanoidRootPart") end
local function now() return workspace:GetServerTimeNow() end
local function smooth(x) x = math.clamp(x, 0, 1) return x * x * (3 - 2 * x) end

local S = { bullets = {}, lasers = {}, columns = {}, localImmune = 0, lastBeat = 0, pulse = 0, bump = 0, zoom = 1 }
 -- under and behind him drift to them when the card changes
local PALETTE = {
	Prologue = { GOLD, VIOLET },
	Gilded = { GOLD, Color3.fromRGB(255, 150, 40) },
	Clock = { Color3.fromRGB(70, 235, 255), GOLD },
	World = { ICE, WHITE },
	Illusion = { Color3.fromRGB(255, 70, 90), VIOLET },
	Thread = { GOLD, SHINE },
	Cosmos = { Color3.fromRGB(170, 100, 255), Color3.fromRGB(255, 110, 200) },
	Breath = { Color3.fromRGB(80, 150, 255), WHITE },
	BlackHole = { VIOLET, Color3.fromRGB(255, 170, 80) },
}
S.palA, S.palB, S.goalA, S.goalB = GOLD, VIOLET, GOLD, VIOLET
 -- a character flickers while it can't be hit (after a hit, after a miss)
local blinking = setmetatable({}, { __mode = "k" })
local function blink(char, secs)
	if not char then return end
	local untilT = os.clock() + secs
	if blinking[char] then blinking[char] = math.max(blinking[char], untilT) return end
	blinking[char] = untilT
	task.spawn(function()
		local on = false
		while char.Parent and os.clock() < (blinking[char] or 0) do
			on = not on
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.LocalTransparencyModifier = on and 0.7 or 0 end
			end
			task.wait(0.07)
		end
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.LocalTransparencyModifier = 0 end
		end
		blinking[char] = nil
	end)
end

local folder
local function holder()
	if not folder or not folder.Parent then
		folder = Instance.new("Folder")
		folder.Name = "SonicBlasterLocal"
		folder.Parent = workspace
	end
	return folder
end
local function newPart(size, color, alpha, shape, parent)
	local p = Instance.new("Part")
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.Material = Enum.Material.Neon p.Color = color p.Transparency = alpha or 0 p.Size = size p.CFrame = FAR
	if shape then p.Shape = shape end
	p.Parent = parent or holder()
	return p
end
 -- a flat glowing image on a thin part (lit by nothing but itself): .set(at, radius, alpha)
local function flatRing(tex, color, alpha, parent, both)
	local p = newPart(Vector3.new(2, 0.05, 2), WHITE, 1, nil, parent)
	local img
	for _, face in ipairs(both and { Enum.NormalId.Top, Enum.NormalId.Bottom } or { Enum.NormalId.Top }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face gui.LightInfluence = 0 gui.Brightness = 2.2 gui.AlwaysOnTop = false
		gui.CanvasSize = Vector2.new(512, 512) gui.Parent = p
		local i = Instance.new("ImageLabel")
		i.BackgroundTransparency = 1 i.Size = UDim2.fromScale(1, 1) i.Image = Lib.Id(tex)
		i.ImageColor3 = color i.ImageTransparency = alpha or 0 i.Parent = gui
		img = img or i
		if face == Enum.NormalId.Bottom then
			local link = img
			link:GetPropertyChangedSignal("ImageTransparency"):Connect(function() i.ImageTransparency = link.ImageTransparency end)
			link:GetPropertyChangedSignal("ImageColor3"):Connect(function() i.ImageColor3 = link.ImageColor3 end)
		end
	end
	local ring = { Part = p, Image = img }
	function ring.set(at, radius, a)
		p.Size = Vector3.new(radius * 2, 0.05, radius * 2)
		if typeof(at) == "CFrame" then p.CFrame = at else p.CFrame = CFrame.new(at) end
		if a then img.ImageTransparency = a end
	end
	return ring
end
 -- a camera-facing glow far away (nebulae, the black hole's light): size in studs
local function billboard(pos, size, tex, color, alpha, parent)
	local a = newPart(Vector3.one * 0.2, WHITE, 1, nil, parent)
	a.CFrame = CFrame.new(pos)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(size, size) bb.LightInfluence = 0 bb.MaxDistance = 1e6 bb.Brightness = 1.4 bb.Parent = a
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1 img.Size = UDim2.fromScale(1, 1) img.Image = Lib.Id(tex)
	img.ImageColor3 = color img.ImageTransparency = alpha or 0 img.Parent = bb
	return { Part = a, Gui = bb, Image = img }
end

local cam = {}
local function shake(power, time)
	cam.shakePower, cam.shakeUntil, cam.shakeTime = power, os.clock() + time, time
end
local function shoot(fn, blend)
	local c = workspace.CurrentCamera
	if not cam.bound then
		cam.bound = true
		cam.savedFov = c.FieldOfView
		Run:BindToRenderStep("SonicBlasterCam", Enum.RenderPriority.Camera.Value + 3, function(dt)
			local f = cam.shot
			if not f then return end
			local t = os.clock() - cam.started
			local cf, fov = f(t, dt)
			local k = cam.blend > 0 and smooth(t / cam.blend) or 1
			local view = workspace.CurrentCamera
			view.CameraType = Enum.CameraType.Scriptable
			cf = cam.from:Lerp(cf, k)
			if cam.shakeUntil and os.clock() < cam.shakeUntil then
				local s = cam.shakePower * (cam.shakeUntil - os.clock()) / cam.shakeTime
				cf *= CFrame.Angles((math.random() - 0.5) * s, (math.random() - 0.5) * s, (math.random() - 0.5) * s * 0.5)
			end
			view.CFrame = cf
			if fov then view.FieldOfView += (fov - view.FieldOfView) * math.min(1, dt * 8) end
		end)
	end
	cam.from = c.CFrame
	cam.shot, cam.started, cam.blend = fn, os.clock(), blend or 0.8
end
local function release()
	if not cam.bound then return end
	cam.bound, cam.shot = false, nil
	Run:UnbindFromRenderStep("SonicBlasterCam")
	local c = workspace.CurrentCamera
	c.CameraType = Enum.CameraType.Custom
	c.FieldOfView = cam.savedFov or 70
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then c.CameraSubject = hum end
end
local function bossAt(boss, fallback)
	local r = rootOf(boss)
	return r and r.Position or fallback or Vector3.zero
end
local function orbit(boss, angle, radius, height, speed, fov, look)
	return function(t)
		local c = bossAt(boss, S.center) + UP * 1.6
		local a = angle + t * (speed or 0.1)
		return CFrame.lookAt(c + Vector3.new(math.cos(a) * radius, height, math.sin(a) * radius), c + UP * (look or 0.4)), fov or 52
	end
end
local function angleTo(center)
	local p = workspace.CurrentCamera.CFrame.Position - center
	return math.atan2(p.Z, p.X)
end
 -- the shmup camera: high over the stage, following you but leaning a little towards him
local function topDown()
	return function(_, dt)
		local hrp = rootOf(player.Character)
		local c = S.center or Vector3.zero
		local p = hrp and hrp.Position or c
		 -- below you so you sit above the health bar
		local focus = Vector3.new(p.X + (c.X - p.X) * 0.06, S.floorY or c.Y, p.Z + (c.Z - p.Z) * 0.06 + 7 * S.zoom)
		local z = S.zoom
		S.bump = math.max(0, S.bump - (dt or 0) * 5)
		S.tilt = (S.tilt or 0) + ((S.tiltGoal or 0) - (S.tilt or 0)) * math.min(1, (dt or 0) * 0.9)
		local tl = S.tilt
		return CFrame.lookAt(focus + Vector3.new(0, (96 - 50 * tl) * z, (42 + 29 * tl) * z), focus), 52 + 14 * tl - S.bump * 3
	end
end

local saved
local function spaceSky(on)
	if on and not saved then
		saved = { props = {}, kids = {} }
		for _, k in ipairs({ "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "FogEnd", "FogStart", "FogColor", "ExposureCompensation",
			"EnvironmentDiffuseScale", "EnvironmentSpecularScale" }) do
			saved.props[k] = Lighting[k]
		end
		for _, ch in ipairs(Lighting:GetChildren()) do
			if ch:IsA("Sky") or ch:IsA("Atmosphere") then
				saved.kids[#saved.kids + 1] = ch
				ch.Parent = nil
			end
		end
		local sky = Instance.new("Sky")
		sky.Name = "NothingSky" sky.CelestialBodiesShown = false sky.StarCount = 5000
		sky.Parent = Lighting
		saved.sky = sky
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.5
		Lighting.Ambient = Color3.fromRGB(38, 32, 66)
		Lighting.OutdoorAmbient = Color3.fromRGB(58, 50, 96)
		Lighting.FogStart = 1e5 Lighting.FogEnd = 1e5
		Lighting.ExposureCompensation = 0
		Lighting.EnvironmentDiffuseScale = 0.3
		Lighting.EnvironmentSpecularScale = 0.7
	elseif not on and saved then
		for k, v in pairs(saved.props) do pcall(function() Lighting[k] = v end) end
		for _, ch in ipairs(saved.kids) do pcall(function() ch.Parent = Lighting end) end
		if saved.sky then saved.sky:Destroy() end
		saved = nil
	end
end
local world
local function planet(parent, pos, size, color, glow, ring)
	local body = newPart(Vector3.one * size, color, 0, Enum.PartType.Ball, parent)
	body.Material = Enum.Material.SmoothPlastic
	body.CFrame = CFrame.new(pos)
	local halo = newPart(Vector3.one * size * 1.07, glow, 0.86, Enum.PartType.Ball, parent)
	halo.CFrame = CFrame.new(pos)
	local shade = newPart(Vector3.one * size * 1.002, BLACK, 0.45, Enum.PartType.Ball, parent)
	shade.Material = Enum.Material.SmoothPlastic
	shade.CFrame = CFrame.new(pos + Vector3.new(size * 0.05, -size * 0.02, size * 0.035))
	if ring then
		local r = flatRing("ring.multi", ring, 0.25, parent, true)
		r.set(CFrame.new(pos) * CFrame.Angles(0.42, 0.3, 0.18), size * 1.15, 0.25)
	end
	billboard(pos, size * 2.4, "glow.soft", glow, 0.75, parent)
end
local function buildWorld(center, radius)
	if world then return end
	world = { spin = {} }
	local f = Instance.new("Folder")
	f.Name = "NothingLocal"
	f.Parent = workspace
	world.folder = f
	 -- planets: one huge world far beneath the stage, a ringed giant, an ice world, a red star, a pale moon
	planet(f, center + Vector3.new(380, -2300, 520), 1700, Color3.fromRGB(70, 60, 140), Color3.fromRGB(140, 110, 255))
	planet(f, center + Vector3.new(-1300, -260, -1700), 760, Color3.fromRGB(205, 150, 95), Color3.fromRGB(255, 190, 120), Color3.fromRGB(255, 220, 160))
	planet(f, center + Vector3.new(1500, 380, -1000), 380, Color3.fromRGB(90, 150, 255), Color3.fromRGB(160, 210, 255))
	planet(f, center + Vector3.new(-900, 640, 1300), 150, Color3.fromRGB(230, 225, 240), Color3.fromRGB(255, 255, 255))
	local star = newPart(Vector3.one * 260, Color3.fromRGB(255, 120, 80), 0, Enum.PartType.Ball, f)
	star.CFrame = CFrame.new(center + Vector3.new(1900, -500, 1500))
	billboard(star.Position, 1300, "glow.soft", Color3.fromRGB(255, 140, 90), 0.35, f)
	billboard(star.Position, 900, "star.lens", Color3.fromRGB(255, 200, 150), 0.55, f)
	 -- nebulae and a galaxy far below
	local nebulae = { { Vector3.new(-2600, 400, 600), 2600, Color3.fromRGB(150, 70, 255) }, { Vector3.new(2400, -200, -2400), 3000, Color3.fromRGB(60, 120, 255) },
		{ Vector3.new(400, 900, 2800), 2200, Color3.fromRGB(255, 90, 180) }, { Vector3.new(-1800, -1200, -2600), 2800, Color3.fromRGB(80, 220, 255) },
		{ Vector3.new(2800, 1200, 1400), 2000, Color3.fromRGB(255, 180, 90) } }
	for _, nb in ipairs(nebulae) do
		billboard(center + nb[1], nb[2], "glow.soft", nb[3], 0.62, f)
		billboard(center + nb[1] * 1.02, nb[2] * 0.6, "fb.smoke", nb[3], 0.7, f)
	end
	local galaxy = flatRing("swirl.white", Color3.fromRGB(255, 220, 160), 0.35, f)
	galaxy.set(center + Vector3.new(-600, -1500, -900), 1600, 0.35)
	world.galaxy = galaxy
	local galaxy2 = flatRing("vortex.soft", Color3.fromRGB(160, 120, 255), 0.4, f)
	galaxy2.set(center + Vector3.new(-600, -1490, -900), 1900, 0.4)
	world.galaxy2 = galaxy2
	 -- star dust drifting round the stage
	local dust = newPart(Vector3.new(radius * 6, 300, radius * 6), WHITE, 1, nil, f)
	dust.CFrame = CFrame.new(center + UP * 40)
	local em = Instance.new("ParticleEmitter")
	em.Texture = Lib.Id("star.twinkle") em.Rate = 70 em.Lifetime = NumberRange.new(5, 10) em.Speed = NumberRange.new(0, 1.5)
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 1.1), NumberSequenceKeypoint.new(0.7, 0.9), NumberSequenceKeypoint.new(1, 0) })
	em.LightEmission = 1 em.LightInfluence = 0 em.Color = ColorSequence.new(WHITE, ICE)
	em.Shape = Enum.ParticleEmitterShape.Box em.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume em.Parent = dust
	 -- the stage's markings: the rim, rings, a turning sigil, crystals floating round the edge
	local floor = center + UP * 0.06
	world.edge = flatRing("ring.thin", GOLD, 0.1, f)
	world.edge.set(floor, radius + 1.5, 0.1)
	world.glow = flatRing("ring.soft", GOLD, 0.8, f)
	world.glow.set(floor, radius + 4, 0.8)
	world.inner = flatRing("ring.ticked", SHINE, 0.8, f)
	world.inner.set(floor + UP * 0.02, radius * 0.62, 0.8)
	world.mid = flatRing("ring.thin", VIOLET, 0.75, f)
	world.mid.set(floor + UP * 0.03, radius * 0.86, 0.75)
	world.sigil = flatRing("sigil.mandala", GOLD, 0.87, f)
	world.sigil.set(floor + UP * 0.01, radius * 0.42, 0.87)
	world.under = flatRing("glow.soft", VIOLET, 0.8, f, true)
	world.under.set(center - UP * 7, radius * 1.25, 0.8)
	 -- a galaxy turning under the glass
	world.swirl = flatRing("swirl.white", GOLD, 0.9, f)
	world.swirl.set(floor + UP * 0.035, radius * 0.98, 0.9)
	world.swirl2 = flatRing("vortex.soft", VIOLET, 0.9, f)
	world.swirl2.set(floor + UP * 0.03, radius * 1.02, 0.9)
	world.crystals = {}
	for k = 1, 16 do
		local cr = newPart(Vector3.new(1.2, 3.4, 1.2), k % 2 == 0 and GOLD or VIOLET, 0.1, nil, f)
		world.crystals[k] = cr
	end
	world.center, world.radius = center, radius
end
local function destroyWorld()
	if not world then return end
	world.folder:Destroy()
	world = nil
end

 -- drawn like the game's own Health bar (PlayerVitalsHUD: Guru "Health" and its value, a dark track ruled in green, the
 -- green gradient fill - yellow while you are untouchable); and your lives as yellow stars in the middle of it (lose a life,
 -- lose a star). Inside the bottom bar the music's bars stand in white.
local TOP, BOT = 0.1, 0.15  -- the bars' heights once the song starts (fractions of the screen)
local INK = Color3.fromRGB(12, 10, 16)
local STAR = Color3.fromRGB(255, 222, 40)
local GREEN_SEQ = ColorSequence.new(Color3.fromRGB(63, 173, 61), Color3.fromRGB(154, 241, 98))
local YELLOW_SEQ = ColorSequence.new(Color3.fromRGB(226, 169, 16), Color3.fromRGB(255, 232, 72))
local RED_SEQ = ColorSequence.new(Color3.fromRGB(190, 48, 40), Color3.fromRGB(255, 112, 92))
local GURU = Font.new("rbxasset://fonts/families/Guru.json")
local gui, top, bottom, hpFill, hpGhost, hpText, hpGrad, hpStroke, starRow, starMore, eq, banner
local eqBars, eqHeights, eqTargets, stars = {}, {}, {}, {}
local EQ_N = 44
local MAX_STARS = 10
local shownLives
local function text(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1 l.Font = Enum.Font.GothamBold l.TextColor3 = WHITE l.TextScaled = true
	for k, v in pairs(props) do l[k] = v end
	l.Parent = parent
	return l
end
local function letterbox(on)
	if on and not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "SonicBlasterCinema" gui.IgnoreGuiInset = true gui.DisplayOrder = 6 gui.ResetOnSpawn = false
		top = Instance.new("Frame")
		top.Name = "Top" top.BackgroundColor3 = BLACK top.BorderSizePixel = 0 top.Size = UDim2.fromScale(1, 0) top.ZIndex = 2 top.Parent = gui
		bottom = top:Clone()
		bottom.Name = "Bottom" bottom.AnchorPoint = Vector2.new(0, 1) bottom.Position = UDim2.fromScale(0, 1) bottom.Parent = gui
		for _, f in ipairs({ top, bottom }) do
			Tween:Create(f, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, BAR) }):Play()
		end
		gui.Parent = player:WaitForChild("PlayerGui")
	elseif not on and gui then
		local old = gui
		gui, top, bottom, hpFill, hpGhost, hpText, hpGrad, hpStroke, starRow, starMore, eq = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
		shownLives = nil
		table.clear(eqBars) table.clear(eqHeights) table.clear(eqTargets) table.clear(stars)
		for _, d in ipairs(old:GetDescendants()) do
			if d:IsA("TextLabel") then Tween:Create(d, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			elseif d:IsA("ImageLabel") then Tween:Create(d, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
			elseif d:IsA("UIStroke") then Tween:Create(d, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			elseif d:IsA("Frame") then Tween:Create(d, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play() end
		end
		task.delay(0.65, function() old:Destroy() end)
	end
end
local function frameOf(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in pairs(props) do f[k] = v end
	f.Parent = parent
	return f
end
local function setSpell() end
local function buildHud()
	if not gui or eq then return end
	Tween:Create(top, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, TOP) }):Play()
	Tween:Create(bottom, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, BOT) }):Play()
	 -- the song's name, on a black plate
	local plate = frameOf(gui, { Name = "Song", BackgroundColor3 = INK, AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1 - BOT, 0), Size = UDim2.fromScale(0.15, 0.036), ZIndex = 4 })
	text(plate, { Text = "♪  " .. SB.SongName, Font = Enum.Font.GothamBold, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.07, 0.14), Size = UDim2.fromScale(0.86, 0.72), ZIndex = 5 })
	 -- your health: the game's own Health bar
	local hp = frameOf(gui, { Name = "Health", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1 - BOT, -10), Size = UDim2.fromScale(0.46, 0.054), ZIndex = 4 })
	local title = text(hp, { Text = "Health", FontFace = GURU, TextColor3 = Color3.fromRGB(244, 239, 215), TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeColor3 = Color3.fromRGB(12, 15, 20), TextStrokeTransparency = 0.25, Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(0.5, 0.52), ZIndex = 6 })
	hpText = text(hp, { Text = "", FontFace = GURU, TextColor3 = Color3.fromRGB(252, 249, 230), TextXAlignment = Enum.TextXAlignment.Right,
		TextStrokeColor3 = Color3.fromRGB(12, 15, 20), TextStrokeTransparency = 0.25, Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.fromScale(0.5, 0.44), ZIndex = 6 })
	local track = frameOf(hp, { Name = "Track", BackgroundColor3 = Color3.fromRGB(20, 27, 30), Position = UDim2.fromScale(0, 0.57), Size = UDim2.fromScale(1, 0.31), ZIndex = 5 })
	hpStroke = Instance.new("UIStroke") hpStroke.Color = Color3.fromRGB(63, 173, 61) hpStroke.Thickness = 1 hpStroke.Transparency = 0.12
	hpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual hpStroke.Parent = track
	hpGhost = frameOf(track, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.55, Size = UDim2.fromScale(1, 1), ZIndex = 5 })
	hpFill = frameOf(track, { Name = "Fill", BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1), ZIndex = 6 })
	hpGrad = Instance.new("UIGradient") hpGrad.Color = GREEN_SEQ hpGrad.Parent = hpFill
	frameOf(hp, { Name = "Underline", BackgroundColor3 = Color3.fromRGB(232, 235, 229), BackgroundTransparency = 0.45, Position = UDim2.fromScale(0, 0.95), Size = UDim2.new(1, 0, 0, 1), ZIndex = 5 })
	 -- your lives: yellow stars in the middle, just over it
	starRow = frameOf(gui, { Name = "Stars", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1 - BOT - 0.054, -14), Size = UDim2.fromScale(0.46, 0.056), ZIndex = 4 })
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal layout.Padding = UDim.new(0, 6) layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center layout.SortOrder = Enum.SortOrder.LayoutOrder layout.Parent = starRow
	for k = 1, MAX_STARS do
		local s = Instance.new("ImageLabel")
		s.Name = "Star" .. k s.BackgroundTransparency = 1 s.Image = Lib.Id("star.anime") s.ImageColor3 = STAR s.LayoutOrder = k
		s.Size = UDim2.fromScale(0.8, 0.8) s.ZIndex = 6 s.Visible = false
		local ar = Instance.new("UIAspectRatioConstraint") ar.AspectRatio = 1 ar.DominantAxis = Enum.DominantAxis.Height ar.Parent = s
		local shadow = Instance.new("ImageLabel")  -- a dark rim so the stars read against the sky
		shadow.Name = "Rim" shadow.BackgroundTransparency = 1 shadow.Image = s.Image shadow.ImageColor3 = INK shadow.ImageTransparency = 0.15
		shadow.AnchorPoint = Vector2.new(0.5, 0.5) shadow.Position = UDim2.fromScale(0.5, 0.53) shadow.Size = UDim2.fromScale(1.22, 1.22) shadow.ZIndex = 5
		shadow.Parent = s
		s.Parent = starRow
		stars[k] = s
	end
	starMore = text(starRow, { Text = "", LayoutOrder = 99, Font = Enum.Font.GothamBlack, TextColor3 = STAR, TextStrokeColor3 = INK,
		TextStrokeTransparency = 0, Size = UDim2.fromScale(0.14, 0.7), ZIndex = 6, TextXAlignment = Enum.TextXAlignment.Left })
	 -- the music's bars, standing white in the bottom bar
	eq = frameOf(bottom, { Name = "Equalizer", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(1, 0, 1, -8), ZIndex = 3 })
	local slot = 1 / (EQ_N + 1)
	for i = 1, EQ_N do
		local b = frameOf(eq, { BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale((i - 0.5 + 0.5) * slot, 1),
			Size = UDim2.new(slot * 0.56, 0, 0.05, 0), ZIndex = 4 })
		eqBars[i], eqHeights[i], eqTargets[i] = b, 0.05, 0.05
	end
end
 -- a star breaks off the row and falls away
local function breakStar(k)
	local s = stars[k]
	if not s or not gui or not s.Visible then return end
	local pos, size = s.AbsolutePosition, s.AbsoluteSize
	local ghost = Instance.new("ImageLabel")
	ghost.BackgroundTransparency = 1 ghost.Image = s.Image ghost.ImageColor3 = WHITE ghost.ZIndex = 9
	ghost.AnchorPoint = Vector2.new(0.5, 0.5) ghost.Position = UDim2.fromOffset(pos.X + size.X / 2, pos.Y + size.Y / 2) ghost.Size = UDim2.fromOffset(size.X, size.Y)
	ghost.Parent = gui
	Tween:Create(ghost, TweenInfo.new(0.12), { Size = UDim2.fromOffset(size.X * 1.8, size.Y * 1.8), ImageColor3 = STAR }):Play()
	task.delay(0.12, function()
		Tween:Create(ghost, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(pos.X + size.X / 2 + 30, pos.Y + size.Y * 4),
			Rotation = 160, ImageTransparency = 1, Size = UDim2.fromOffset(size.X * 0.6, size.Y * 0.6) }):Play()
	end)
	for q = 1, 7 do
		local shard = Instance.new("ImageLabel")
		shard.BackgroundTransparency = 1 shard.Image = Lib.Id("star.crisp") shard.ImageColor3 = STAR shard.ZIndex = 9
		shard.AnchorPoint = Vector2.new(0.5, 0.5) shard.Position = ghost.Position shard.Size = UDim2.fromOffset(size.X * 0.5, size.Y * 0.5)
		shard.Parent = gui
		local a = q / 7 * TAU + math.random()
		local d = size.X * (1.2 + math.random() * 1.4)
		Tween:Create(shard, TweenInfo.new(0.55, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(pos.X + size.X / 2 + math.cos(a) * d, pos.Y + size.Y / 2 + math.sin(a) * d),
			ImageTransparency = 1, Size = UDim2.fromOffset(4, 4), Rotation = 90 }):Play()
		task.delay(0.6, function() shard:Destroy() end)
	end
	task.delay(1, function() ghost:Destroy() end)
end
local toastLabel
local function toast(msg)
	if not gui then return end
	if toastLabel then toastLabel:Destroy() end
	local l = text(gui, { Text = msg, Font = Enum.Font.GothamBlack, TextColor3 = STAR, TextStrokeColor3 = INK, TextStrokeTransparency = 0,
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1 - BOT - 0.17), Size = UDim2.fromScale(0.5, 0.04), ZIndex = 8, TextTransparency = 1 })
	toastLabel = l
	Tween:Create(l, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	task.delay(2.6, function()
		if l.Parent then
			Tween:Create(l, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			task.delay(0.55, function() l:Destroy() end)
		end
	end)
end
local peak, eqNext = 120, 0
local function updateHud(dt, clock, songT)
	if hpFill then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.MaxHealth > 0 then
			local k = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			hpFill.Size = UDim2.fromScale(k, 1)
			local g = hpGhost.Size.X.Scale
			hpGhost.Size = UDim2.fromScale(g > k and math.max(k, g - dt * 0.35) or k, 1)
			hpText.Text = string.format("%d / %d", math.floor(hum.Health + 0.5), math.floor(hum.MaxHealth + 0.5))
			local untouchable = clock < S.localImmune
			hpGrad.Color = untouchable and YELLOW_SEQ or (k < 0.3 and RED_SEQ or GREEN_SEQ)
			hpStroke.Color = untouchable and Color3.fromRGB(226, 169, 16) or (k < 0.3 and Color3.fromRGB(190, 48, 40) or Color3.fromRGB(63, 173, 61))
		end
		local lives = player:GetAttribute("LivesRemaining")
		lives = type(lives) == "number" and math.max(0, math.floor(lives)) or 0
		if lives ~= shownLives then
			if shownLives and lives < shownLives then
				for k = lives + 1, math.min(shownLives, MAX_STARS) do breakStar(k) end
			end
			local grew = shownLives and lives > shownLives
			shownLives = lives
			for k = 1, MAX_STARS do
				local was = stars[k].Visible
				stars[k].Visible = k <= lives
				if grew and not was and stars[k].Visible then
					stars[k].Rotation = -90
					Tween:Create(stars[k], TweenInfo.new(0.4, Enum.EasingStyle.Back), { Rotation = 0 }):Play()
				end
			end
			starMore.Text = lives > MAX_STARS and ("× " .. lives) or ""
			starMore.Visible = lives > MAX_STARS  -- (hidden otherwise, so the stars stay in the exact middle)
		end
		 -- the stars breathe with the beat
		local beat = 0.8 + S.pulse * 0.08
		for k = 1, math.min(lives, MAX_STARS) do
			stars[k].ImageColor3 = STAR:Lerp(WHITE, S.pulse * 0.35)
			stars[k].Size = UDim2.fromScale(beat, beat)
		end
	end
	if not eq then return end
	local music = SoundService:FindFirstChild("BossPhaseSoundtrack")
	local loud = music and music.IsPlaying and music.PlaybackLoudness or 0
	peak = math.max(peak * (1 - dt * 0.15), loud, 60)
	local level = loud / peak
	S.pulse = math.max(0, S.pulse - dt * 3.2)
	if clock >= eqNext then
		eqNext = clock + 0.055
		local kick, hat = S.kick or 5, S.hat or 5
		for i = 1, EQ_N do
			local x = (i - 1) / (EQ_N - 1)
			local band = (1 - x) * (0.45 + kick / 14) * (1 + S.pulse * 0.8) + x * (0.35 + hat / 16)
			eqTargets[i] = math.clamp(level * band * (0.3 + 0.7 * math.random() ^ 0.8), 0.05, 1)
		end
	end
	for i = 1, EQ_N do
		local h = eqHeights[i]
		local target = eqTargets[i]
		h += (target - h) * math.min(1, dt * (target > h and 26 or 8))
		eqHeights[i] = h
		eqBars[i].Size = UDim2.new(eqBars[i].Size.X.Scale, 0, h, 0)
	end
end
local HIDE_GUIS = { AlterGoldenBossHUD = true, PlayerVitalsHUD = true, ClassHUD = true, BossSettingsHUD = true, P5TPHUD = true }
local HIDE_PARTS = { PlayerStatusDock = true, EncounterTimerAndMusic = true, ActionDock = true }  -- (inside PlayerEncounterHUD; its dialogue and victory stay)
local hudSaved
local posSaved
local function enforceHud()
	if not hudSaved then return end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	for name in pairs(HIDE_GUIS) do
		local g = pg:FindFirstChild(name)
		if g and g.Enabled then
			if hudSaved[g] == nil then hudSaved[g] = true end
			g.Enabled = false
		end
	end
	local enc = pg:FindFirstChild("PlayerEncounterHUD")
	if enc then
		 -- never sit over your lives
		local q = enc:FindFirstChild("BossDialogue")
		if q and q:IsA("GuiObject") then
			if eq then
				posSaved = posSaved or {}
				if posSaved[q] == nil then posSaved[q] = q.Position end
				q.Position = UDim2.new(0.07, 0, TOP + 0.025, 0)
			elseif posSaved and posSaved[q] then
				q.Position = posSaved[q]
				posSaved[q] = nil
			end
		end
		for name in pairs(HIDE_PARTS) do
			local f = enc:FindFirstChild(name)
			if f and f:IsA("GuiObject") and f.Visible then
				if hudSaved[f] == nil then hudSaved[f] = true end
				f.Visible = false
			end
		end
	end
end
local function hideHud(on)
	if on then
		hudSaved = hudSaved or {}
		enforceHud()
	elseif hudSaved then
		if posSaved then
			for obj, pos in pairs(posSaved) do if obj.Parent then obj.Position = pos end end
			posSaved = nil
		end
		for obj in pairs(hudSaved) do
			if obj.Parent then
				if obj:IsA("ScreenGui") then obj.Enabled = true else obj.Visible = true end
			end
		end
		hudSaved = nil
	end
end
local function showBanner(title, sub)
	if not gui then return end
	if banner then banner:Destroy() end
	local f = Instance.new("Frame")
	f.BackgroundColor3 = BLACK f.BackgroundTransparency = 1 f.BorderSizePixel = 0 f.ZIndex = 5
	f.AnchorPoint = Vector2.new(0.5, 0.5) f.Position = UDim2.fromScale(0.5, 0.38) f.Size = UDim2.fromScale(1, 0.09) f.Parent = gui
	local grad = Instance.new("UIGradient")
	grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.35),
		NumberSequenceKeypoint.new(0.7, 0.35), NumberSequenceKeypoint.new(1, 1) })
	grad.Parent = f
	local ln = Instance.new("Frame")
	ln.BackgroundColor3 = GOLD ln.BorderSizePixel = 0 ln.AnchorPoint = Vector2.new(0.5, 1) ln.Position = UDim2.fromScale(0.5, 1) ln.ZIndex = 5
	ln.Size = UDim2.new(0, 0, 0, 2) ln.Parent = f
	local l = text(f, { Text = title, Font = Enum.Font.GothamBlack, TextColor3 = WHITE, TextStrokeColor3 = Color3.fromRGB(150, 90, 10),
		TextStrokeTransparency = 0.2, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.62, 0.5), Size = UDim2.fromScale(0.7, 0.62),
		TextTransparency = 1, ZIndex = 6 })
	if sub then
		text(f, { Text = sub, Font = Enum.Font.GothamBold, TextColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(0.3, 0.36), ZIndex = 6 })
	end
	banner = f
	Tween:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = 0.25 }):Play()
	Tween:Create(ln, TweenInfo.new(0.45, Enum.EasingStyle.Quint), { Size = UDim2.new(0.8, 0, 0, 2) }):Play()
	Tween:Create(l, TweenInfo.new(0.45, Enum.EasingStyle.Quint), { TextTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }):Play()
	task.delay(2.6, function()
		if banner ~= f then return end
		Tween:Create(f, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		Tween:Create(l, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		Tween:Create(ln, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		task.delay(0.55, function() f:Destroy() end)
	end)
end
local function flash(brightness, tint, t)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = brightness cc.Contrast = 0.15 cc.TintColor = tint or WHITE cc.Parent = Lighting
	Tween:Create(cc, TweenInfo.new(t or 0.4, Enum.EasingStyle.Quad), { Brightness = 0, Contrast = 0, TintColor = WHITE }):Play()
	task.delay((t or 0.4) + 0.05, function() cc:Destroy() end)
end
local function whiteout(t, color)
	local g = Instance.new("ScreenGui")
	g.Name = "SonicBlasterWhite" g.IgnoreGuiInset = true g.DisplayOrder = 40 g.ResetOnSpawn = false
	local f = Instance.new("Frame")
	f.BackgroundColor3 = color or WHITE f.BorderSizePixel = 0 f.Size = UDim2.fromScale(1, 1) f.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	Tween:Create(f, TweenInfo.new(t or 0.8, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	task.delay((t or 0.8) + 0.05, function() g:Destroy() end)
end
local grade
local function dim(on)
	if on and not grade then
		grade = Instance.new("ColorCorrectionEffect")
		grade.Name = "SonicBlasterGrade" grade.Parent = Lighting
		Tween:Create(grade, TweenInfo.new(1.2), { Brightness = -0.06, Contrast = 0.14, Saturation = -0.15, TintColor = Color3.fromRGB(230, 222, 255) }):Play()
	elseif not on and grade then
		local g = grade
		grade = nil
		Tween:Create(g, TweenInfo.new(1), { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = WHITE }):Play()
		task.delay(1.05, function() g:Destroy() end)
	end
end

local pool, corePool = {}, {}
local function takeVisual()
	local v = table.remove(pool)
	if not v then
		local p = newPart(Vector3.one, WHITE, 0.1)
		local m = Instance.new("SpecialMesh") m.MeshType = Enum.MeshType.Sphere m.Parent = p
		v = { P = p, M = m }
	end
	return v
end
local function takeCore()
	local v = table.remove(corePool)
	if not v then
		local p = newPart(Vector3.one, WHITE, 0)
		local m = Instance.new("SpecialMesh") m.MeshType = Enum.MeshType.Sphere m.Parent = p
		v = { P = p, M = m }
	end
	return v
end
local function dress(b)
	local kind = SB.Kinds[b.k] or SB.Kinds[1]
	local s, long = kind.Size, kind.Long
	local v = takeVisual()
	v.P.Color = SB.Colors[b.c] or WHITE
	if kind.Name == "Big" then
		local h = v.Halo
		if not h then
			local bb = Instance.new("BillboardGui")
			bb.LightInfluence = 0 bb.AlwaysOnTop = false bb.MaxDistance = 1e5 bb.Brightness = 1.2 bb.Parent = v.P
			local im = Instance.new("ImageLabel")
			im.BackgroundTransparency = 1 im.Image = Lib.Id("glow.soft") im.Size = UDim2.fromScale(1, 1) im.Parent = bb
			h = { Gui = bb, Img = im }
			v.Halo = h
		end
		h.Gui.Enabled = true
		h.Gui.Size = UDim2.fromScale(s * 2.3, s * 2.3)
		h.Img.ImageColor3 = SB.Colors[b.c] or WHITE
		h.Img.ImageTransparency = 0.55
	elseif v.Halo then
		v.Halo.Gui.Enabled = false
	end
	local cv = takeCore()
	if kind.Card then
		v.M.MeshType = Enum.MeshType.Brick
		v.M.Scale = Vector3.new(s * 1.1, 0.25, s * 0.75)
		v.P.Transparency = 0.15
		cv.M.MeshType = Enum.MeshType.Brick
		cv.M.Scale = Vector3.new(s * 0.8, 0.32, s * 0.45)
	else
		v.M.MeshType = Enum.MeshType.Sphere
		v.M.Scale = long and Vector3.new(long, s * 0.55, s * 0.8) or Vector3.new(s, s * 0.8, s)
		v.P.Transparency = b.k == 3 and 0.42 or 0.3
		cv.M.MeshType = Enum.MeshType.Sphere
		cv.M.Scale = long and Vector3.new(long * 0.75, s * 0.32, s * 0.4) or Vector3.new(s * 0.5, s * 0.45, s * 0.5)
	end
	v.Base = v.M.Scale
	b.vis = v
	cv.Base = cv.M.Scale
	b.core = cv
end
local function undress(b)
	if b.vis then b.vis.P.CFrame = FAR pool[#pool + 1] = b.vis b.vis = nil end
	if b.core then b.core.P.CFrame = FAR corePool[#corePool + 1] = b.core b.core = nil end
end
local hitRemote
local function report(kind, id)
	hitRemote = hitRemote or RS.BossShared:FindFirstChild("SonicBlasterHit")
	if hitRemote then hitRemote:FireServer(kind, id) end
end
local function hurtFlash()
	flash(0.18, Color3.fromRGB(255, 150, 150), 0.35)
	shake(0.012, 0.25)
end
local sparks = {}
local function spark(pos, color, size, life)
	local p = table.remove(sparks) or newPart(Vector3.one, WHITE, 0, Enum.PartType.Ball)
	p.Color = color or WHITE
	p.Size = Vector3.one * (size or 1)
	p.Transparency = 0
	p.CFrame = CFrame.new(pos)
	Tween:Create(p, TweenInfo.new(life or 0.3, Enum.EasingStyle.Quad), { Size = Vector3.one * 0.05, Transparency = 1 }):Play()
	task.delay((life or 0.3) + 0.05, function() p.CFrame = FAR sparks[#sparks + 1] = p end)
end

local stage
local function buildStage()
	if stage then return end
	stage = { waves = {} }
	stage.dot = newPart(Vector3.one * 0.9, WHITE, 0, Enum.PartType.Ball)
	stage.dotRing = newPart(Vector3.one * 2, Color3.fromRGB(255, 70, 90), 0.45, Enum.PartType.Ball)
	stage.dotRing.Material = Enum.Material.ForceField
	 -- his spell circles: one turning on the floor under him, one standing behind him, facing you
	stage.bossFloor = flatRing("sigil.mandala2", GOLD, 0.35)
	stage.bossHalo = flatRing("sigil.ring", GOLD, 0.3, nil, true)
	stage.bossGlow = billboard(Vector3.zero, 30, "glow.soft", GOLD, 0.6)
	stage.wipes = {}
end
local function clearStage()
	if not stage then return end
	for _, w in ipairs(stage.waves) do w.ring.Part:Destroy() end
	if stage.clock then for _, p in ipairs(stage.clock.parts) do p:Destroy() end end
	if stage.mirrors then for _, m in ipairs(stage.mirrors.list) do m.card:Destroy() m.face:Destroy() m.glow.Part:Destroy() end end
	stage.dot:Destroy() stage.dotRing:Destroy()
	stage.bossFloor.Part:Destroy() stage.bossHalo.Part:Destroy() stage.bossGlow.Part:Destroy()
	if stage.shock then stage.shock.ring.Part:Destroy() end
	for _, w in ipairs(stage.wipes) do w.ring.Part:Destroy() end
	stage = nil
end
local function soundWave(strength)
	if not stage then return end
	local w = { ring = flatRing("ring.thin", S.palA, 0.6), born = os.clock(), reach = 30 + strength * 8, life = 0.55 + strength * 0.04 }
	table.insert(stage.waves, w)
end
local function onBeat(i)
	local kick = SB.Kick[i] or 5
	S.kick, S.hat = kick, SB.Hat[i] or 5
	S.pulse = 1
	if S.running then soundWave(kick) end
	if kick >= 8 then S.bump = 1 end
	if world then world.edge.Image.ImageTransparency = 0 end
end

local hole
local function buildHole(d)
	if hole then return end
	local f = holder()
	hole = { pos = d.Pos, at = d.At, gone = d.Gone, parts = {} }
	hole.core = newPart(Vector3.one * 0.1, BLACK, 0, Enum.PartType.Ball, f)
	hole.core.CFrame = CFrame.new(d.Pos)
	hole.ring = billboard(d.Pos, 1, "ring.soft", Color3.fromRGB(255, 200, 130), 0, f)
	hole.ring.Gui.AlwaysOnTop = false
	hole.halo = billboard(d.Pos, 1, "glow.soft", Color3.fromRGB(150, 80, 255), 0.35, f)
	hole.rays = billboard(d.Pos, 1, "glow.rays", Color3.fromRGB(255, 170, 90), 0.6, f)
	hole.disk = flatRing("vortex.soft", Color3.fromRGB(255, 170, 80), 0.1, f, true)
	hole.disk2 = flatRing("swirl.lines", Color3.fromRGB(255, 230, 180), 0.25, f, true)
	hole.disk3 = flatRing("ring.multi", Color3.fromRGB(170, 110, 255), 0.35, f, true)
	local shell = newPart(Vector3.one * 400, WHITE, 1, Enum.PartType.Ball, f)
	shell.CFrame = CFrame.new(d.Pos)
	local em = Instance.new("ParticleEmitter")
	em.Texture = Lib.Id("star.crisp") em.Rate = 0 em.Lifetime = NumberRange.new(1.4, 2.2) em.Speed = NumberRange.new(90, 140)
	em.Shape = Enum.ParticleEmitterShape.Sphere em.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface em.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1), NumberSequenceKeypoint.new(1, 0.6) })
	em.Color = ColorSequence.new(Color3.fromRGB(255, 220, 160), Color3.fromRGB(170, 110, 255))
	em.LightEmission = 1 em.LightInfluence = 0 em.RotSpeed = NumberRange.new(-180, 180) em.Parent = shell
	hole.dust = em
	hole.shell = shell
	hole.grade = Instance.new("ColorCorrectionEffect")
	hole.grade.Name = "BlackHoleGrade" hole.grade.Parent = Lighting
end
local function updateHole(t)
	if not hole then return end
	local u = smooth((t - hole.at) / 2.2)
	local closing = hole.closing and math.clamp((os.clock() - hole.closing) / 0.45, 0, 1) or 0
	local size = 125 * u * (1 - closing) + math.sin(os.clock() * 3) * 1.8 * u
	local pos = hole.pos
	hole.core.Size = Vector3.one * math.max(size, 0.05)
	hole.ring.Gui.Size = UDim2.fromScale(size * 1.55, size * 1.55)
	hole.halo.Gui.Size = UDim2.fromScale(size * 4.2, size * 4.2)
	hole.rays.Gui.Size = UDim2.fromScale(size * 3, size * 3)
	hole.rays.Image.Rotation = os.clock() * 8
	 -- the bright photon ring and the rays sit just in front of the dark sphere (inside it they were hidden); the disk is
	 -- turned partly towards you so it reads as a ring of fire, not a line
	local toCam = workspace.CurrentCamera.CFrame.Position - pos
	toCam = toCam.Magnitude > 0.1 and toCam.Unit or Vector3.zAxis
	hole.ring.Part.CFrame = CFrame.new(pos + toCam * size * 0.62)
	hole.rays.Part.CFrame = CFrame.new(pos + toCam * size * 0.6)
	local tilt = CFrame.lookAt(pos, pos + toCam) * CFrame.Angles(-math.pi / 2 + 1.12, 0, 0.14)
	hole.disk.set(tilt * CFrame.Angles(0, os.clock() * 1.4, 0), size * 2.4, 0.1 + closing)
	hole.disk2.set(tilt * CFrame.Angles(0, -os.clock() * 2.1, 0), size * 1.9, 0.25 + closing)
	hole.disk3.set(tilt * CFrame.Angles(0, os.clock() * 0.6, 0), size * 3.1, 0.4 + closing * 0.6)
	hole.dust.Rate = 160 * u * (1 - closing)
	hole.grade.Brightness = -0.08 * u
	hole.grade.Saturation = -0.2 * u
	hole.grade.TintColor = WHITE:Lerp(Color3.fromRGB(220, 200, 255), u)
end
local function destroyHole()
	if not hole then return end
	hole.grade:Destroy()
	for _, k in ipairs({ "core", "shell" }) do if hole[k] then hole[k]:Destroy() end end
	for _, k in ipairs({ "ring", "halo", "rays", "disk", "disk2", "disk3" }) do if hole[k] then hole[k].Part:Destroy() end end
	hole = nil
end
local loop
local function frame(dt)
	local t = now()
	local clock = os.clock()
	local songT = t - (S.startAt or t)
	local parts, cfs = {}, {}
	local hrp = rootOf(player.Character)
	local px, pz
	if hrp then
		px, pz = hrp.Position.X, hrp.Position.Z
		 -- the stage keeps you in (here first, so it is smooth; the server keeps the same rule)
		if S.center and S.running and not hrp.Anchored then
			local rel = Vector3.new(px - S.center.X, 0, pz - S.center.Z)
			local d = rel.Magnitude
			if d < S.radius + 50 then
				if d > S.radius - 1.2 and d > 0.01 then
					local dir = rel / d
					hrp.CFrame += -dir * (d - (S.radius - 1.2))
					local v = hrp.AssemblyLinearVelocity
					hrp.AssemblyLinearVelocity = v - dir * math.max(0, v:Dot(dir))
				elseif d < S.core and d > 0.01 then
					hrp.CFrame += rel / d * (S.core - d)
				end
			end
			px, pz = hrp.Position.X, hrp.Position.Z
		end
	end
	local y = (S.floorY or 0) + SB.Height
	local list = S.bullets
	local i = 1
	while i <= #list do
		local b = list[i]
		local live = SB.Advance(b, t)
		local dying = b.dieAt and clock - b.dieAt
		local life = b.into and 1.5 or 0.35
		if dying and dying > life or live and not b.into and SB.Gone(b, t, S.cx, S.cz) then
			undress(b)
			list[i] = list[#list]
			list[#list] = nil
		else
			if live or b.into then
				if not b.vis then dress(b) end
				local v = b.vis
				local frozen = b.fz and t >= b.fz and not (b.go and t >= b.go)
				if frozen ~= (b.shownFrozen or false) then
					b.shownFrozen = frozen
					v.P.Color = frozen and ICE or (SB.Colors[b.c] or WHITE)
				end
				local cf
				if b.into then
					 -- drawn into the black hole: a spiral that closes on it
					local k = math.clamp(dying / life, 0, 1)
					local e = k * k
					local from = b.fromPos
					local p = from:Lerp(b.into, e)
					local side = (b.into - from):Cross(UP)
					if side.Magnitude > 0.01 then p += side.Unit * math.sin(k * math.pi) * 18 * (b.spin or 1) end
					cf = CFrame.lookAt(p, b.into)
					v.M.Scale = v.Base * (1 - k * 0.85)
					if b.core then b.core.M.Scale = b.core.Base * (1 - k * 0.85) end
				else
					if dying then
						local k = 1 - dying / life
						v.M.Scale = v.Base * (0.2 + k)
					end
					local x, z = SB.Where(b, t)
					cf = CFrame.new(x, y, z) * CFrame.Angles(0, -b.a, 0)
					if px and not dying and S.running then
						local kind = SB.Kinds[b.k] or SB.Kinds[1]
						local dx, dz = x - px, z - pz
						if dx < 8 and dx > -8 and dz < 8 and dz > -8 then
							local r = kind.Hit + PLAYER_R
							if dx * dx + dz * dz < r * r and not b.hit and clock >= S.localImmune then
								b.hit = true
								S.localImmune = clock + SB.HitGrace
								report("B", b.id)
								hurtFlash()
								blink(player.Character, SB.HitGrace)
							end
						end
					end
				end
				parts[#parts + 1] = v.P cfs[#cfs + 1] = cf
				if b.core then parts[#parts + 1] = b.core.P cfs[#cfs + 1] = cf end
			end
			i += 1
		end
	end
	 -- lasers (a ticking laser dims to a guide line while it rests)
	for id, l in pairs(S.lasers) do
		if t > l.Off + 0.35 then
			l.Outer:Destroy() l.Core:Destroy() l.Orb:Destroy() l.Glow:Destroy()
			S.lasers[id] = nil
		else
			local a = SB.LaserAngle(l, t)
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local mid = Vector3.new(l.X, y, l.Z) + dir * (l.Len / 2)
			local cf = CFrame.new(mid) * CFrame.Angles(0, -a, 0)
			 -- the orb it is fired from
			local orbK = t < l.On and 0.5 + 0.5 * smooth((t - l.T) / math.max(l.On - l.T, 0.05)) or t <= l.Off and (SB.LaserLive(l, t) and 1.25 + 0.12 * math.sin(clock * 26) or 0.7) or math.max(0, 1 - (t - l.Off) / 0.35)
			l.Orb.Size = Vector3.one * math.max(0.05, l.Wid * 1.9 * orbK)
			parts[#parts + 1] = l.Orb cfs[#cfs + 1] = CFrame.new(l.X, y, l.Z)
			local glowW, glowA = 0.3, 1
			if t < l.On then
				local blink = 0.55 + 0.25 * math.sin(clock * 30)
				l.Outer.Size = Vector3.new(l.Len, 0.35, 0.35)
				l.Outer.Transparency = blink
				l.Core.Transparency = 1
			elseif t <= l.Off then
				local burning = SB.LaserLive(l, t)
				local k = smooth((t - l.On) / 0.12)
				local w = burning and l.Wid * k or 0.5
				l.Outer.Size = Vector3.new(l.Len, w, w)
				l.Outer.Transparency = burning and 0.2 or 0.7
				l.Core.Size = Vector3.new(l.Len, w * 0.38, w * 0.38)
				l.Core.Transparency = burning and 0 or 1
				if burning then glowW, glowA = w * 2.6, 0.78 + 0.1 * math.sin(clock * 22) end
				if burning and px and S.running and t >= l.On + 0.1 then
					local dx, dz = px - l.X, pz - l.Z
					local along = dx * math.cos(a) + dz * math.sin(a)
					local across = math.abs(-dx * math.sin(a) + dz * math.cos(a))
					if along > 0 and along < l.Len and across < l.Wid * 0.5 + PLAYER_R and clock >= S.localImmune then
						S.localImmune = clock + SB.HitGrace
						report("L", l.Id)
						hurtFlash()
						blink(player.Character, SB.HitGrace)
					end
				end
			else
				local k = 1 - (t - l.Off) / 0.35
				l.Outer.Size = Vector3.new(l.Len, l.Wid * k, l.Wid * k)
				l.Core.Transparency = 1 - k
				l.Outer.Transparency = 1 - k * 0.8
				glowW, glowA = l.Wid * 2.6 * k, 1 - 0.22 * k
			end
			l.Glow.Size = Vector3.new(l.Len, glowW, glowW)
			l.Glow.Transparency = glowA
			parts[#parts + 1] = l.Glow cfs[#cfs + 1] = cf
			parts[#parts + 1] = l.Outer cfs[#cfs + 1] = cf
			parts[#parts + 1] = l.Core cfs[#cfs + 1] = cf
		end
	end
	 -- columns: the warning fills in, then the pillar comes down
	for id, col in pairs(S.columns) do
		local floor = Vector3.new(col.X, (S.floorY or 0) + 0.1, col.Z)
		if t > col.Off + 0.45 then
			col.ring.Part:Destroy() col.fill.Part:Destroy() col.pillar:Destroy() col.core:Destroy() col.drop:Destroy()
			S.columns[id] = nil
		elseif t < col.On then
			local k = math.clamp((t - col.T) / math.max(col.On - col.T, 0.05), 0, 1)
			col.ring.set(floor, col.R, 0.15 + 0.2 * math.sin(clock * 20))
			col.fill.set(floor + UP * 0.02, col.R * k, 0.55)
			 -- the blade / the star falls out of the sky onto the mark
			local fall = (col.On - t) / 0.5
			if fall < 1 then
				local h = 90 * math.max(fall, 0) ^ 1.7
				local lift = col.C == 5 and col.R * 0.3 or 13
				parts[#parts + 1] = col.drop cfs[#cfs + 1] = CFrame.new(floor + UP * (h + lift)) * CFrame.Angles(0, clock * 6, 0)
			end
		else
			if not col.struck then
				col.struck = true
				col.drop.CFrame = FAR
				col.fill.set(floor + UP * 0.02, col.R, 0.1)
				spark(floor + UP * 2, SHINE, col.R * 1.6, 0.35)
				if stage then
					table.insert(stage.wipes, { ring = flatRing("ring.thick", (SB.Colors[col.C] or GOLD):Lerp(WHITE, 0.35), 0.1), born = clock, pos = floor + UP * 0.2, r = col.R * 2.8 })
				end
				for q = 1, 7 do
					local a = q / 7 * TAU
					spark(floor + Vector3.new(math.cos(a) * col.R * 0.7, 2 + (q % 3) * 3, math.sin(a) * col.R * 0.7), SHINE, 2.6, 0.45)
				end
				if px and (px - col.X) ^ 2 + (pz - col.Z) ^ 2 < (col.R * 1.6) ^ 2 then shake(0.02, 0.3) end
			end
			local k = t <= col.Off and 1 or 1 - (t - col.Off) / 0.45
			local h = 48
			col.pillar.Size = Vector3.new(h, col.R * 2 * k, col.R * 2 * k)
			col.core.Size = Vector3.new(h, col.R * 0.8 * k, col.R * 0.8 * k)
			col.pillar.Transparency = 0.4 + (1 - k) * 0.55
			local cf = CFrame.new(floor + UP * h / 2) * CFrame.Angles(0, 0, math.pi / 2)
			parts[#parts + 1] = col.pillar cfs[#cfs + 1] = cf
			parts[#parts + 1] = col.core cfs[#cfs + 1] = cf
			col.ring.set(floor, col.R, 1 - k)
			col.fill.set(floor + UP * 0.02, col.R, 1 - k * 0.6)
		end
	end
	S.palA = S.palA:Lerp(S.goalA, math.min(1, dt * 1.6))
	S.palB = S.palB:Lerp(S.goalB, math.min(1, dt * 1.6))
	if stage then
		local br = S.boss and not S.vanished and rootOf(S.boss)
		if br and S.floorY then
			local bp = br.Position
			stage.bossFloor.set(CFrame.new(bp.X, S.floorY + 0.14, bp.Z) * CFrame.Angles(0, clock * 0.7, 0), 16 + S.pulse * 2, 0.45)
			local toCam = workspace.CurrentCamera.CFrame.Position - bp
			toCam = toCam.Magnitude > 0.1 and toCam.Unit or Vector3.zAxis
			local back = bp - toCam * 3
			stage.bossHalo.set(CFrame.lookAt(back, back + toCam) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, -clock * 0.9, 0), 9 + S.pulse * 1.2, 0.25)
			stage.bossGlow.Part.CFrame = CFrame.new(bp)
			stage.bossFloor.Image.ImageColor3 = S.palA
			stage.bossHalo.Image.ImageColor3 = S.palB
			stage.bossGlow.Image.ImageColor3 = S.palA
		else
			stage.bossFloor.Part.CFrame = FAR stage.bossHalo.Part.CFrame = FAR stage.bossGlow.Part.CFrame = FAR
		end
		 -- a new spell card: a ring of light rolls over the whole stage
		local sh = stage.shock
		if sh then
			local u = (clock - sh.born) / 1.1
			if u >= 1 then
				sh.ring.Part:Destroy()
				stage.shock = nil
			else
				sh.ring.set(Vector3.new(S.center.X, S.floorY + 0.3, S.center.Z), 6 + S.radius * 1.3 * smooth(u), 0.05 + 0.95 * u)
			end
		end
		 -- a miss: the ring that wipes the bullets round you
		for q = #stage.wipes, 1, -1 do
			local w = stage.wipes[q]
			local u = (clock - w.born) / 0.45
			if u >= 1 then
				w.ring.Part:Destroy()
				table.remove(stage.wipes, q)
			else
				w.ring.set(w.pos, 2 + w.r * smooth(u), u * u)
			end
		end
		local m = stage.mirrors
		if m then
			if t > m.Until then
				for _, mm in ipairs(m.list) do mm.card:Destroy() mm.face:Destroy() mm.glow.Part:Destroy() end
				stage.mirrors = nil
			else
				local fade = math.clamp((m.Until - t) / 0.5, 0, 1) * math.clamp((t - m.Born) / 0.5, 0, 1)
				for k, mm in ipairs(m.list) do
					local x, z = SB.Mirror(m.M, k, math.max(t, m.M.T0))
					local p = Vector3.new(x, (S.floorY or 0) + 7 + math.sin(clock * 2 + k) * 0.8, z)
					local look = Vector3.new(S.center.X, p.Y, S.center.Z)
					local cf = CFrame.lookAt(p, look) * CFrame.Angles(0, clock * 0.8, 0)
					parts[#parts + 1] = mm.card cfs[#cfs + 1] = cf
					parts[#parts + 1] = mm.face cfs[#cfs + 1] = cf * CFrame.new(0, 0, -0.1)
					mm.glow.Part.CFrame = CFrame.new(p)
					for _, im in ipairs(mm.imgs) do im.Image.ImageTransparency = im.Base + (1 - fade) * (1 - im.Base) end
				end
			end
		end
		local ck = stage.clock
		if ck then
			local fade = math.clamp((ck.Until - t) / 0.8, 0, 1) * math.clamp((clock - ck.Born) / 0.8, 0, 1)
			if fade <= 0 and t > ck.Until then
				for _, p in ipairs(ck.parts) do p:Destroy() end
				stage.clock = nil
			else
				ck.face.Image.ImageTransparency = 1 - fade * 0.55
				ck.inner.Image.ImageTransparency = 1 - fade * 0.4
				ck.inner.Part.CFrame = CFrame.new(S.center + UP * 0.1) * CFrame.Angles(0, -clock * 0.25, 0)
				for _, mk in ipairs(ck.marks) do mk.Transparency = 1 - fade * 0.8 end
				ck.hub.Image.ImageTransparency = 1 - fade * 0.62
				ck.hub.Part.CFrame = CFrame.new(S.center + UP * 0.12) * CFrame.Angles(0, clock * 0.5, 0)
				for _, lb in ipairs(ck.labels) do lb.TextTransparency = 1 - fade * 0.55 end
			end
		end
		local floor = Vector3.new(S.center.X, (S.floorY or 0) + 0.2, S.center.Z)
		local k = 1
		while k <= #stage.waves do
			local w = stage.waves[k]
			local u = (clock - w.born) / w.life
			if u >= 1 then
				w.ring.Part:Destroy()
				table.remove(stage.waves, k)
			else
				w.ring.set(floor, 4 + w.reach * smooth(u), 0.6 + 0.4 * u)
				k += 1
			end
		end
		if hrp then
			local head = hrp.Position + UP * 3.4
			parts[#parts + 1] = stage.dot cfs[#cfs + 1] = CFrame.new(head)
			parts[#parts + 1] = stage.dotRing cfs[#cfs + 1] = CFrame.new(head)
		end
	end
	if world then
		world.sigil.Part.CFrame = CFrame.new(world.center + UP * 0.07) * CFrame.Angles(0, clock * 0.2, 0)
		world.inner.Part.CFrame = CFrame.new(world.center + UP * 0.08) * CFrame.Angles(0, -clock * 0.35, 0)
		world.mid.Part.CFrame = CFrame.new(world.center + UP * 0.09) * CFrame.Angles(0, clock * 0.12, 0)
		world.galaxy.Part.CFrame = world.galaxy.Part.CFrame * CFrame.Angles(0, dt * 0.03, 0)
		world.galaxy2.Part.CFrame = world.galaxy2.Part.CFrame * CFrame.Angles(0, -dt * 0.02, 0)
		world.swirl.Part.CFrame = CFrame.new(world.center + UP * 0.035) * CFrame.Angles(0, -clock * 0.05, 0)
		world.swirl2.Part.CFrame = CFrame.new(world.center + UP * 0.03) * CFrame.Angles(0, clock * 0.03, 0)
		local A, Bc = S.palA, S.palB
		world.edge.Image.ImageColor3 = A
		world.glow.Image.ImageColor3 = A
		world.inner.Image.ImageColor3 = Bc:Lerp(WHITE, 0.4)
		world.mid.Image.ImageColor3 = Bc
		world.sigil.Image.ImageColor3 = A
		world.under.Image.ImageColor3 = Bc
		world.swirl.Image.ImageColor3 = A
		world.swirl2.Image.ImageColor3 = Bc
		for k2, cr in ipairs(world.crystals) do cr.Color = k2 % 2 == 0 and A or Bc end
		if clock >= (world.nextMeteor or 0) then
			world.nextMeteor = clock + 0.5 + math.random() * 1.3
			local a = math.random() * TAU
			local from = world.center + Vector3.new(math.cos(a) * 700, 120 + math.random() * 420, math.sin(a) * 700)
			local dir = Vector3.new(math.random() - 0.5, -0.3 - math.random() * 0.3, math.random() - 0.5).Unit
			local len = 120 + math.random() * 120
			local mt = newPart(Vector3.new(2.6, 2.6, len), math.random() < 0.5 and SHINE or ICE, 0.05, nil, world.folder)
			mt.CFrame = CFrame.lookAt(from, from + dir)
			local life = 0.7 + math.random() * 0.5
			Tween:Create(mt, TweenInfo.new(life, Enum.EasingStyle.Linear), { CFrame = CFrame.lookAt(from + dir * 900, from + dir * 901),
				Transparency = 1, Size = Vector3.new(0.6, 0.6, len * 0.3) }):Play()
			task.delay(life + 0.05, function() mt:Destroy() end)
		end
		local edgeA = world.edge.Image.ImageTransparency
		world.edge.Image.ImageTransparency = math.min(0.15, edgeA + dt * 0.5)
		for k2, cr in ipairs(world.crystals) do
			local a = (k2 - 1) / #world.crystals * TAU + clock * 0.05
			local p = world.center + Vector3.new(math.cos(a) * (world.radius + 6), 4 + math.sin(clock * 1.5 + k2) * 1.2, math.sin(a) * (world.radius + 6))
			parts[#parts + 1] = cr cfs[#cfs + 1] = CFrame.new(p) * CFrame.Angles(0, clock * 1.2 + k2, 0) * CFrame.Angles(0.6, 0, 0.6)
		end
	end
	if #parts > 0 then workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
	 -- the beat (it keeps going under the black hole: the bars still move with the music)
	if S.startAt and songT >= 0 and songT < SB.Length then
		local bi = SB.BeatAt(songT)
		if bi ~= S.lastBeat then
			S.lastBeat = bi
			if bi > 0 then onBeat(bi) end
		end
	end
	updateHole(t)
	updateHud(dt, clock, S.startAt and songT or nil)
	enforceHud()
end
local function startLoop()
	if loop then return end
	loop = Run.RenderStepped:Connect(function(dt)
		local ok, err = pcall(frame, dt)
		if not ok then warn("[SonicBlaster] " .. tostring(err)) end
	end)
end
 -- DEFEATED panel (EncounterRetryClient keeps itself hidden while the local FinalDefeatShow attribute is set, and afterwards
 -- unless the whole group is down). It sits at DisplayOrder 88, UNDER the win screen (PlayerEncounterClient, 90), and fades
 -- out the instant the fight is won, so a dead player still sees the victory screen and never a defeat layer over it.
local defeatGui, defeatGrade, defeatConn
local function endFinalDefeat(fast)
	local g, cc, conn = defeatGui, defeatGrade, defeatConn
	defeatGui, defeatGrade, defeatConn = nil, nil, nil
	if conn then conn:Disconnect() end
	pcall(function() player:SetAttribute("FinalDefeatShow", nil) end)
	if cc then
		local t = fast and 0.25 or 1
		Tween:Create(cc, TweenInfo.new(t), { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = WHITE }):Play()
		task.delay(t + 0.05, function() cc:Destroy() end)
	end
	if g then
		local root = g:FindFirstChild("Root")
		if root then Tween:Create(root, TweenInfo.new(fast and 0.2 or 0.5), { GroupTransparency = 1 }):Play() end
		task.delay(fast and 0.25 or 0.55, function() g:Destroy() end)
	end
end
local function finalDefeat()
	if defeatGui then return end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	pcall(function()
		player:SetAttribute("FinalDefeatShow", true)
		player:SetAttribute("FinalDefeatSpectate", true)
	end)
	local g = Instance.new("ScreenGui")
	g.Name = "SonicBlasterDefeat" g.IgnoreGuiInset = true g.ResetOnSpawn = false g.DisplayOrder = 88
	g.Parent = pg
	defeatGui = g
	local root = Instance.new("CanvasGroup")
	root.Name = "Root" root.BackgroundTransparency = 1 root.Size = UDim2.fromScale(1, 1) root.GroupTransparency = 0 root.Parent = g
	local function frame(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0 f.BackgroundColor3 = BLACK
		for k, v in pairs(props) do f[k] = v end
		f.Parent = root
		return f
	end
	local function label(props)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1 l.TextTransparency = 1 l.TextStrokeTransparency = 1 l.TextWrapped = true
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		for k, v in pairs(props) do l[k] = v end
		l.Parent = root
		return l
	end
	local function fadeIn(l, t)
		Tween:Create(l, TweenInfo.new(t or 0.7), { TextTransparency = 0, TextStrokeTransparency = 0.6 }):Play()
	end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "SonicBlasterDefeatGrade" cc.Parent = Lighting
	defeatGrade = cc
	Tween:Create(cc, TweenInfo.new(1.4), { Saturation = -0.95, Contrast = 0.22, Brightness = -0.08, TintColor = Color3.fromRGB(210, 200, 255) }):Play()
	local veil = frame({ Name = "Veil", BackgroundColor3 = Color3.fromRGB(8, 5, 18), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	Tween:Create(veil, TweenInfo.new(1.3), { BackgroundTransparency = 0.38 }):Play()
	local bars = {}
	for i = 1, 2 do
		bars[i] = frame({ Name = "Bar" .. i, BackgroundColor3 = BLACK, AnchorPoint = Vector2.new(0, i == 1 and 0 or 1), Position = UDim2.fromScale(0, i == 1 and 0 or 1),
			Size = UDim2.fromScale(1, 0), ZIndex = 2 })
		Tween:Create(bars[i], TweenInfo.new(1.1, Enum.EasingStyle.Quint), { Size = UDim2.fromScale(1, 0.12) }):Play()
	end
	local white = frame({ Name = "Flash", BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, ZIndex = 9 })
	Tween:Create(white, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	 -- the last star: it rises, spins, cracks and bursts
	local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local u = math.min(vs.X, vs.Y)
	local star = Instance.new("ImageLabel")
	star.Name = "LastStar" star.BackgroundTransparency = 1 star.Image = Lib.Id("star.anime") star.ImageColor3 = Color3.fromRGB(255, 222, 40)
	star.AnchorPoint = Vector2.new(0.5, 0.5) star.Position = UDim2.fromScale(0.5, 0.4) star.Size = UDim2.fromOffset(0, 0) star.ImageTransparency = 0.2 star.ZIndex = 4
	star.Parent = root
	Tween:Create(star, TweenInfo.new(1.1, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(u * 0.24, u * 0.24), Rotation = 72 }):Play()
	local glow = Instance.new("ImageLabel")
	glow.Name = "StarGlow" glow.BackgroundTransparency = 1 glow.Image = Lib.Id("glow.soft") glow.ImageColor3 = Color3.fromRGB(255, 200, 60)
	glow.AnchorPoint = Vector2.new(0.5, 0.5) glow.Position = star.Position glow.Size = UDim2.fromOffset(0, 0) glow.ImageTransparency = 0.45 glow.ZIndex = 3
	glow.Parent = root
	Tween:Create(glow, TweenInfo.new(1.3, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(u * 0.7, u * 0.7) }):Play()
	local t1 = label({ Name = "Spell", Text = "「 Universe of the Nothing 」", Font = Enum.Font.GothamBold, TextSize = math.max(14, math.floor(u * 0.026)),
		TextColor3 = Color3.fromRGB(255, 206, 84), Position = UDim2.fromScale(0.5, 0.63), Size = UDim2.fromScale(0.8, 0.05), ZIndex = 6 })
	local t2 = label({ Name = "Title", Text = "SWALLOWED BY THE NOTHING", Font = Enum.Font.GothamBlack, TextSize = math.max(22, math.floor(u * 0.07)),
		TextColor3 = WHITE, TextStrokeColor3 = Color3.fromRGB(80, 40, 150), Position = UDim2.fromScale(0.5, 0.71), Size = UDim2.fromScale(0.9, 0.1), ZIndex = 6 })
	local t3 = label({ Name = "Sub", Text = "The song plays on without you.", Font = Enum.Font.GothamMedium, TextSize = math.max(14, math.floor(u * 0.03)),
		TextColor3 = Color3.fromRGB(222, 214, 245), Position = UDim2.fromScale(0.5, 0.79), Size = UDim2.fromScale(0.8, 0.05), ZIndex = 6 })
	task.delay(1.0, function() if defeatGui == g then fadeIn(t1, 0.8) end end)
	task.delay(1.5, function() if defeatGui == g then fadeIn(t2, 0.9) end end)
	task.delay(2.5, function() if defeatGui == g then fadeIn(t3, 0.9) end end)
	 -- the crack: the star bursts into shards
	task.delay(1.9, function()
		if defeatGui ~= g then return end
		Tween:Create(white, TweenInfo.new(0.01), { BackgroundTransparency = 0.55 }):Play()
		task.delay(0.02, function() if white.Parent then Tween:Create(white, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play() end end)
		Tween:Create(star, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(u * 0.34, u * 0.34), ImageTransparency = 1 }):Play()
		Tween:Create(glow, TweenInfo.new(0.6), { ImageTransparency = 1 }):Play()
		for q = 1, 16 do
			local shard = Instance.new("ImageLabel")
			shard.BackgroundTransparency = 1 shard.Image = Lib.Id("star.crisp") shard.ZIndex = 5
			shard.ImageColor3 = q % 3 == 0 and WHITE or Color3.fromRGB(255, 222, 40)
			shard.AnchorPoint = Vector2.new(0.5, 0.5) shard.Position = star.Position
			local s0 = u * (0.04 + math.random() * 0.04)
			shard.Size = UDim2.fromOffset(s0, s0) shard.Parent = root
			local a = q / 16 * TAU + math.random() * 0.4
			local dist = u * (0.22 + math.random() * 0.4)
			Tween:Create(shard, TweenInfo.new(1.1 + math.random() * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, math.cos(a) * dist, 0.4, math.sin(a) * dist + u * 0.12), ImageTransparency = 1,
				Size = UDim2.fromOffset(s0 * 0.25, s0 * 0.25), Rotation = (math.random() - 0.5) * 360 }):Play()
			task.delay(1.7, function() shard:Destroy() end)
		end
	end)
	 -- he keeps singing: a quiet strip for the rest of the attack
	local ribbon = Instance.new("TextLabel")
	ribbon.Name = "Spectate" ribbon.BackgroundColor3 = BLACK ribbon.BackgroundTransparency = 1 ribbon.BorderSizePixel = 0
	ribbon.AnchorPoint = Vector2.new(0.5, 1) ribbon.Position = UDim2.fromScale(0.5, 0.86) ribbon.Size = UDim2.fromScale(0.34, 0.045)
	ribbon.Font = Enum.Font.GothamBold ribbon.Text = "Watching the final attack" ribbon.TextColor3 = Color3.fromRGB(255, 206, 84)
	ribbon.TextScaled = true ribbon.TextTransparency = 1 ribbon.ZIndex = 7 ribbon.Parent = g
	local rcon = Instance.new("UITextSizeConstraint") rcon.MaxTextSize = 20 rcon.MinTextSize = 10 rcon.Parent = ribbon
	 -- the whole cutscene lets go after ~6s; the strip stays until the fight is won or reset
	task.delay(5.6, function()
		if defeatGui ~= g then return end
		Tween:Create(root, TweenInfo.new(1.1), { GroupTransparency = 1 }):Play()
		Tween:Create(cc, TweenInfo.new(1.4), { Saturation = -0.25, Contrast = 0.05, Brightness = 0, TintColor = WHITE }):Play()
		Tween:Create(ribbon, TweenInfo.new(0.9), { BackgroundTransparency = 0.45, TextTransparency = 0 }):Play()
		pcall(function() player:SetAttribute("FinalDefeatShow", nil) end)
	end)
	 -- the fight is won (or reset): the cutscene and the strip are gone at once, the win screen is the only thing left
	defeatConn = workspace:GetAttributeChangedSignal("BossEncounterWon"):Connect(function()
		if workspace:GetAttribute("BossEncounterWon") then endFinalDefeat(true) end
	end)
	if workspace:GetAttribute("BossEncounterWon") then endFinalDefeat(true) end
end
local wheel, portalG, tunnel
local function teardown()
	endFinalDefeat(true)
	S.vanished = nil
	S.tilt, S.tiltGoal = 0, 0
	S.goalA, S.goalB = GOLD, VIOLET
	S.running = false
	S.startAt = nil
	S.blackHole = nil
	if loop then loop:Disconnect() loop = nil end
	if wheel then wheel:Disconnect() wheel = nil end
	for _, b in ipairs(S.bullets) do undress(b) end
	table.clear(S.bullets)
	for _, l in pairs(S.lasers) do l.Outer:Destroy() l.Core:Destroy() l.Orb:Destroy() l.Glow:Destroy() end
	table.clear(S.lasers)
	for _, col in pairs(S.columns) do col.ring.Part:Destroy() col.fill.Part:Destroy() col.pillar:Destroy() col.core:Destroy() col.drop:Destroy() end
	table.clear(S.columns)
	clearStage()
	destroyHole()
	release()
	hideHud(false)
	letterbox(false)
	dim(false)
	if portalG then pcall(function() portalG:Destroy() end) portalG = nil end
	if tunnel then tunnel:Destroy() tunnel = nil end
	if folder then folder:Destroy() folder = nil end
	table.clear(pool)
	table.clear(corePool)
	table.clear(sparks)
end
do
	local function release()
		endFinalDefeat(true)
		pcall(function() player:SetAttribute("FinalDefeatSpectate", nil) end)
		if S.running or S.startAt or S.blackHole then pcall(teardown) end
	end
	player:GetAttributeChangedSignal("EncounterRetrying"):Connect(function()
		if player:GetAttribute("EncounterRetrying") == true then release() end
	end)
	player:GetAttributeChangedSignal("PermanentlyDefeated"):Connect(function()
		if player:GetAttribute("PermanentlyDefeated") ~= true then release() end
	end)
	player.CharacterAdded:Connect(function()
		if not workspace:GetAttribute("SonicBlasterActive") then release() end
	end)
end
local hidden
local function hideBoss(boss, on)
	if on then
		hidden = boss
		for _, d in ipairs(boss:GetDescendants()) do
			if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 1 end
			if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("BillboardGui") or d:IsA("Light") then
				pcall(function() d.Enabled = false end)
			end
		end
		 -- he stays gone until the fight is over and a new one begins
		local conn
		conn = workspace:GetAttributeChangedSignal("BossEncounterWon"):Connect(function()
			if workspace:GetAttribute("BossEncounterWon") then return end
			conn:Disconnect()
			hideBoss(nil, false)
		end)
	elseif hidden then
		for _, d in ipairs(hidden:GetDescendants()) do
			if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 0 end
		end
		hidden = nil
	end
end
function P.Intro(E, d)
	teardown()
	S.boss, S.arena = d.Boss, d.Center
	S.center = d.Center
	S.lastBeat = 0
	letterbox(true)
	hideHud(true)
	dim(true)
	shoot(orbit(d.Boss, angleTo(d.Center), 26, 7, 0.14, 55), 1.4)
	startLoop()
end
local SHOTS = {
	function(boss)
		return function(t)
			local r = rootOf(boss)
			local c = (r and r.Position or S.center) + UP * 1.5
			local f = r and r.CFrame.LookVector or Vector3.new(0, 0, 1)
			return CFrame.lookAt(c + f * (9 - t * 0.4) + UP * 0.6, c), 42
		end
	end,
	function(boss) return orbit(boss, math.random() * TAU, 18, -1.5, 0.22, 60, 2.5) end,
	function(boss) return orbit(boss, math.random() * TAU, 46, 18, 0.08, 50) end,
	function(boss)
		return function(t)
			local r = rootOf(boss)
			local c = (r and r.Position or S.center) + UP * 1.5
			local me = rootOf(player.Character)
			local p = me and me.Position or c + Vector3.new(30, 0, 0)
			local back = (p - c) * Vector3.new(1, 0, 1)
			back = back.Magnitude > 0.1 and back.Unit or Vector3.new(1, 0, 0)
			local side = back:Cross(UP)
			return CFrame.lookAt(p + back * 7 + UP * 3 + side * 2.5, c), 48 - t * 0.6
		end
	end,
	function(boss) return orbit(boss, math.random() * TAU, 13, 2, -0.3, 50, 1) end,
	function(boss) -- looking up past him at the sky
		return function(t)
			local r = rootOf(boss)
			local c = (r and r.Position or S.center) + UP * 1.5
			local f = r and r.CFrame.LookVector or Vector3.new(0, 0, 1)
			return CFrame.lookAt(c + f * 10 - UP * 3, c + UP * (14 + t * 2)), 58
		end
	end,
	function(boss)
		return function(t)
			local r = rootOf(boss)
			local c = (r and r.Position or S.center) + UP * 1.5
			local f = r and r.CFrame.LookVector or Vector3.new(0, 0, 1)
			return CFrame.lookAt(c + f * math.max(5, 14 - t * 2) + UP * 0.8, c), 38
		end
	end,
}
function P.Shot(E, d)
	local make = SHOTS[d.Index] or SHOTS[3]
	shoot(make(d.Boss), 0.9)
end
 -- the warp portal: a dark eye ringed in violet and gold, tearing the arena loose into it
function P.Portal(E, d)
	local g = E.Group("NothingPortal")
	portalG = g
	local pos, facing = d.Pos, d.Facing or Vector3.zAxis
	local life = (d.Open or 1.6) + (d.Suck or 3.2) + 1
	local a = E.Anchor(g, CFrame.lookAt(pos, pos + facing))
	E.Sprite(a, { tex = "vortex.soft", size = { { 0, 4 }, { 0.3, 95 }, { 0.92, 110 }, { 1, 4 } }, alpha = { { 0, 0.6 }, { 0.2, 0.05 }, { 0.92, 0.05 }, { 1, 1 } }, color = VIOLET, spin = { -120, -120 } }, life)
	E.Sprite(a, { tex = "swirl.white", size = { { 0, 4 }, { 0.3, 80 }, { 0.92, 92 }, { 1, 2 } }, alpha = { { 0, 0.6 }, { 0.25, 0.1 }, { 0.92, 0.1 }, { 1, 1 } }, color = GOLD, spin = { 200, 200 } }, life)
	E.Sprite(a, { tex = "ring.crisp", size = { { 0, 6 }, { 0.3, 100 }, { 0.92, 112 }, { 1, 6 } }, alpha = { { 0, 0.5 }, { 0.25, 0 }, { 0.92, 0 }, { 1, 1 } }, color = SHINE }, life)
	E.Sprite(a, { tex = "glow.soft", size = { { 0, 10 }, { 0.3, 220 }, { 1, 240 } }, alpha = { { 0, 0.8 }, { 0.3, 0.4 }, { 1, 1 } }, color = DEEP }, life)
	local core = newPart(Vector3.one * 0.2, BLACK, 0, Enum.PartType.Ball, g.Folder)
	core.CFrame = CFrame.new(pos)
	E.Tween(core, d.Open or 1.6, { Size = Vector3.one * 52 })
	E.Light(g, a, VIOLET, 160, 6, life)
	E.Stream(a, { tex = "star.crisp", size = { { 0, 2 }, { 1, 0 } }, color = { { 0, WHITE }, { 1, VIOLET } }, life = { 0.4, 0.8 }, speed = { 30, 60 }, spread = 180, drag = 2 }, 60)
	flash(0.35, Color3.fromRGB(200, 170, 255), 0.6)
	shake(0.02, 1)
	 -- the arena torn loose: shards and light flung up into it
	local shards = {}
	local center = S.arena or pos - UP * 34
	local spawnUntil = os.clock() + life - 0.8
	local nextShard = os.clock() + (d.Open or 1.6) * 0.5
	E.Step(g, function()
		local c0 = os.clock()
		while c0 >= nextShard and c0 < spawnUntil do
			nextShard += 0.035
			local ang = math.random() * TAU
			local r = 20 + math.random() * 110
			local from = center + Vector3.new(math.cos(ang) * r, 1 + math.random() * 3, math.sin(ang) * r)
			local sz = 0.6 + math.random() * 2.4
			local p = newPart(Vector3.new(sz, sz * 0.6, sz * 1.2), math.random() < 0.3 and GOLD or Color3.fromRGB(120, 100, 85), 0, nil, g.Folder)
			p.Material = math.random() < 0.3 and Enum.Material.Neon or Enum.Material.Slate
			shards[#shards + 1] = { P = p, From = from, Born = c0, Life = 0.9 + math.random() * 0.9, R = CFrame.Angles(math.random() * 6, math.random() * 6, 0), Spin = (math.random() - 0.5) * 14 }
		end
		local ps, cs = {}, {}
		for k = #shards, 1, -1 do
			local s = shards[k]
			local u = (c0 - s.Born) / s.Life
			if u >= 1 then
				s.P:Destroy()
				table.remove(shards, k)
			else
				local e = u ^ 2.2
				local off = Vector3.new(math.cos(u * 8 + s.Spin), 0, math.sin(u * 8 + s.Spin)) * 10 * (1 - u)
				ps[#ps + 1] = s.P cs[#cs + 1] = CFrame.new(s.From:Lerp(pos, e) + off) * s.R * CFrame.Angles(u * s.Spin, u * s.Spin, 0)
				s.P.Transparency = math.max(0, u - 0.7) / 0.3
			end
		end
		if #ps > 0 then workspace:BulkMoveTo(ps, cs, Enum.BulkMoveMode.FireCFrameChanged) end
		return c0 < spawnUntil + 2
	end)
	E.After(g, life + 2.2, function() g:Destroy() end)
	 -- the camera: behind the players, looking up into it; then dragged in
	local open = d.Open or 1.6
	shoot(function(t)
		local k = math.clamp((t - open) / (d.Suck or 3.2), 0, 1)
		local from = pos + facing * (95 - 70 * k ^ 2) - UP * (24 - 18 * k)
		return CFrame.lookAt(from, pos) * CFrame.Angles(0, 0, k * k * 0.6), 62 + k * 30
	end, 0.9)
end
function P.Warp(E, d)
	local T = d.Time or 2
	whiteout(0.5, Color3.fromRGB(235, 220, 255))
	if tunnel then tunnel:Destroy() end
	local g = Instance.new("ScreenGui")
	g.Name = "NothingTunnel" g.IgnoreGuiInset = true g.DisplayOrder = 30 g.ResetOnSpawn = false
	local bg = Instance.new("Frame")
	bg.BackgroundColor3 = Color3.fromRGB(10, 4, 26) bg.BorderSizePixel = 0 bg.Size = UDim2.fromScale(1, 1) bg.Parent = g
	local vg = Instance.new("UIGradient")
	vg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 6, 34)), ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 20, 120)) })
	vg.Rotation = 45 vg.Parent = bg
	local eye = Instance.new("ImageLabel")
	eye.BackgroundTransparency = 1 eye.Image = Lib.Id("glow.soft") eye.ImageColor3 = SHINE eye.AnchorPoint = Vector2.new(0.5, 0.5)
	eye.Position = UDim2.fromScale(0.5, 0.5) eye.Size = UDim2.fromScale(0.08, 0.14) eye.Parent = bg
	local streaks = {}
	for k = 1, 90 do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0 f.AnchorPoint = Vector2.new(0, 0.5)
		f.BackgroundColor3 = ({ WHITE, GOLD, VIOLET, ICE })[k % 4 + 1]
		f.Parent = bg
		streaks[k] = { F = f, A = math.random() * TAU, R = math.random(), V = 0.6 + math.random() * 1.4 }
	end
	tunnel = g
	g.Parent = player:WaitForChild("PlayerGui")
	local start = os.clock()
	local conn
	conn = Run.RenderStepped:Connect(function(dt)
		local el = os.clock() - start
		if not g.Parent then conn:Disconnect() return end
		local speed = 1 + el * 2.4
		for _, s in ipairs(streaks) do
			s.R += dt * s.V * speed * (0.2 + s.R)
			if s.R > 1.3 then s.R = 0.02 + math.random() * 0.05 s.A = math.random() * TAU end
			local x, yy = 0.5 + math.cos(s.A) * s.R * 0.6, 0.5 + math.sin(s.A) * s.R * 0.6
			s.F.Position = UDim2.fromScale(x, yy)
			s.F.Rotation = math.deg(s.A)
			s.F.Size = UDim2.new(0.02 + s.R * 0.22 * speed * 0.3, 0, 0, math.max(1, s.R * 4))
			s.F.BackgroundTransparency = math.clamp(0.9 - s.R * 0.9, 0, 0.9)
		end
		eye.Size = UDim2.fromScale(0.08 + el * 0.06, 0.14 + el * 0.1)
		if el >= T then
			conn:Disconnect()
			whiteout(1.1, WHITE)
			g:Destroy()
			if tunnel == g then tunnel = nil end
		end
	end)
end
function P.Space(E, d)
	S.center, S.radius, S.core = d.Center, d.Radius or SB.Radius, d.Core or SB.Core
	S.cx, S.cz, S.floorY = d.Center.X, d.Center.Z, d.Center.Y
	S.boss = d.Boss
	spaceSky(true)
	buildWorld(d.Center, S.radius)
	buildStage()
	dim(true)
	 -- the arrival: high over the stage, sweeping down to you
	local c = d.Center
	shoot(function(t)
		local k = smooth(t / 3.2)
		local hrp = rootOf(player.Character)
		local me = hrp and hrp.Position or c + Vector3.new(0, 0, 60)
		local back = (me - c) * Vector3.new(1, 0, 1)
		back = back.Magnitude > 0.1 and back.Unit or Vector3.zAxis
		local high = c + Vector3.new(-160, 240, 200)
		local low = me + back * 26 + UP * 12
		local p = high:Lerp(low, k)
		local look = c:Lerp(bossAt(S.boss, c), k) + UP * 4
		return CFrame.lookAt(p, look), 70 - 18 * k
	end, 0)
	startLoop()
end
function P.Declare(E, d)
	local r = rootOf(d.Boss)
	flash(0.45, SHINE, 0.7)
	shake(0.03, 0.6)
	if r then
		local g = E.Group("SonicBlasterDeclare")
		local a = E.Anchor(g, r.CFrame)
		E.Sprite(a, { tex = "flare.burst", size = { { 0, 6 }, { 0.25, 70 }, { 1, 80 } }, alpha = { { 0, 0 }, { 1, 1 } }, color = WHITE }, 0.6)
		E.Sprite(a, { tex = "sigil.mandala", size = { { 0, 4 }, { 0.4, 44 }, { 1, 48 } }, alpha = { { 0, 0.1 }, { 0.7, 0.3 }, { 1, 1 } }, color = GOLD, spin = { 40, 40 } }, 1.4)
		E.Emit(a, { tex = "star.crisp", size = { { 0, 1.4 }, { 1, 0 } }, color = { { 0, WHITE }, { 1, GOLD } }, life = { 0.5, 1 }, speed = { 30, 70 }, spread = 180, drag = 3 }, 60)
		E.Light(g, a, GOLD, 80, 10, 0.9)
		E.After(g, 2, function() g:Destroy() end)
	end
	showBanner(d.Name or "「Universe of the Nothing」", d.Title or "Last Imagination")
	shoot(SHOTS[7](d.Boss), 0.8)
end
function P.Start(E, d)
	S.boss, S.center, S.radius, S.core = d.Boss, d.Center, d.Radius or SB.Radius, d.Core or SB.Core
	S.cx, S.cz, S.floorY = d.Center.X, d.Center.Z, d.Center.Y
	S.startAt = d.StartAt
	S.running = true
	if not gui then letterbox(true) end
	hideHud(true)
	if not world then spaceSky(true) buildWorld(d.Center, S.radius) end
	dim(true)
	buildHud()
	buildStage()
	shoot(topDown(), 1.1)
	S.zoom = 1.18
	wheel = wheel or UIS.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			S.zoom = math.clamp(S.zoom - input.Position.Z * 0.08, 0.7, 1.7)
		end
	end)
	startLoop()
end
function P.Volley(E, d)
	if not S.center then return end
	local origin
	local muzzles = 0
	for _, desc in ipairs(d.List or {}) do
		for _, b in ipairs(SB.Expand(desc)) do
			S.bullets[#S.bullets + 1] = b
		end
		local fromMiddle = desc.P == nil and desc.X == S.cx and desc.Z == S.cz
		origin = origin or fromMiddle
		if not fromMiddle and desc.P == nil and muzzles < 6 and S.floorY then
			muzzles += 1
			spark(Vector3.new(desc.X, S.floorY + SB.Height, desc.Z), (SB.Colors[desc.C] or WHITE):Lerp(WHITE, 0.4), 4.5, 0.22)
		end
	end
	if origin and S.boss then
		local r = rootOf(S.boss)
		if r then spark(r.Position, SHINE, 4, 0.18) end
	end
end
function P.Laser(E, d)
	for _, l in ipairs(d.List or {}) do
		local color = SB.Colors[l.C] or WHITE
		l.Outer = newPart(Vector3.new(l.Len, 0.3, 0.3), color, 0.6, Enum.PartType.Cylinder)
		l.Core = newPart(Vector3.new(l.Len, 0.1, 0.1), WHITE, 1, Enum.PartType.Cylinder)
		l.Orb = newPart(Vector3.one, color:Lerp(WHITE, 0.35), 0.15, Enum.PartType.Ball)
		l.Glow = newPart(Vector3.new(l.Len, 0.3, 0.3), color, 1, Enum.PartType.Cylinder)
		S.lasers[l.Id] = l
	end
end
function P.Column(E, d)
	for _, col in ipairs(d.List or {}) do
		local color = SB.Colors[col.C] or GOLD
		col.ring = flatRing("ring.crisp", color, 0.2)
		col.fill = flatRing("disc.soft", color, 0.55)
		col.pillar = newPart(Vector3.one, color, 1, Enum.PartType.Cylinder)
		col.core = newPart(Vector3.one, WHITE, 0.1, Enum.PartType.Cylinder)
		 -- what falls on the mark: a golden blade (Phase 1's Falling Blade) or a star
		if col.C == 5 then
			col.drop = newPart(Vector3.one * col.R * 0.6, Color3.fromRGB(255, 210, 255), 0, Enum.PartType.Ball)
		else
			col.drop = newPart(Vector3.new(col.R * 0.32, 26, col.R * 0.1), color:Lerp(WHITE, 0.25), 0)
		end
		S.columns[col.Id] = col
	end
end
function P.ClockFace(E, d)
	if not stage or not S.center then return end
	local parts = {}
	local face = flatRing("ring.ticked", GOLD, 1)
	face.set(S.center + UP * 0.09, S.radius * 0.97, 1)
	local inner = flatRing("sigil.ring", SHINE, 1)
	inner.set(S.center + UP * 0.1, S.radius * 0.7, 1)
	parts[#parts + 1] = face.Part
	parts[#parts + 1] = inner.Part
	local marks = {}
	for k = 0, 11 do
		local a = k / 12 * TAU
		local big = k % 3 == 0
		local mk = newPart(Vector3.new(big and 9 or 5, 0.25, big and 1.6 or 0.9), GOLD, 1)
		mk.CFrame = CFrame.new(S.center + Vector3.new(math.cos(a), 0, math.sin(a)) * S.radius * 0.84 + UP * 0.15) * CFrame.Angles(0, -a, 0)
		marks[#marks + 1] = mk
		parts[#parts + 1] = mk
	end
	local hub = flatRing("sigil.mandala2", GOLD, 1)
	hub.set(S.center + UP * 0.12, SB.Core + 9, 1)
	parts[#parts + 1] = hub.Part
	local labels = {}
	local ROMAN = { "XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI" }
	for k = 0, 11 do
		local a = k / 12 * TAU
		local nm = newPart(Vector3.new(9, 0.1, 5), WHITE, 1)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Top sg.LightInfluence = 0 sg.Brightness = 2.2 sg.CanvasSize = Vector2.new(360, 200) sg.Parent = nm
		local lb = text(sg, { Text = ROMAN[k + 1], Font = Enum.Font.Garamond, TextColor3 = SHINE, Size = UDim2.fromScale(1, 1), TextTransparency = 1 })
		local theta = math.atan2(-math.cos(a), -math.sin(a))
		nm.CFrame = CFrame.new(S.center + Vector3.new(math.cos(a), 0, math.sin(a)) * S.radius * 0.925 + UP * 0.16) * CFrame.Angles(0, theta, 0)
		parts[#parts + 1] = nm
		labels[#labels + 1] = lb
	end
	stage.clock = { face = face, inner = inner, marks = marks, parts = parts, hub = hub, labels = labels, Until = d.Until, Born = os.clock() }
	flash(0.2, SHINE, 0.5)
end
function P.Mirrors(E, d)
	if not stage then return end
	local list = {}
	for k = 1, d.M.Count do
		 -- carries the drawing on both faces)
		local tint = k % 2 == 0 and Color3.fromRGB(255, 70, 90) or VIOLET
		local card = newPart(Vector3.new(9, 13, 0.3), WHITE, 1)
		local imgs = {}
		for _, faceSide in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local sg = Instance.new("SurfaceGui")
			sg.Face = faceSide sg.LightInfluence = 0 sg.Brightness = 2 sg.CanvasSize = Vector2.new(360, 520) sg.Parent = card
			local function layer(tex, color, base, size, pos)
				local im = Instance.new("ImageLabel")
				im.BackgroundTransparency = 1 im.Image = Lib.Id(tex) im.ImageColor3 = color im.ImageTransparency = base
				im.AnchorPoint = Vector2.new(0.5, 0.5) im.Position = pos or UDim2.fromScale(0.5, 0.5) im.Size = size or UDim2.fromScale(1, 1) im.Parent = sg
				imgs[#imgs + 1] = { Image = im, Base = base }
			end
			layer("glow.soft", tint:Lerp(WHITE, 0.5), 0.2, UDim2.fromScale(0.9, 0.94))
			layer("sigil.ring", WHITE, 0.45, UDim2.fromScale(0.62, 0.44))
			layer("ring.thick", GOLD, 0, UDim2.fromScale(1, 1))
		end
		local face = newPart(Vector3.new(0.2, 0.2, 0.2), WHITE, 1)
		local glow = billboard(Vector3.zero, 26, "glow.soft", tint, 0.5)
		list[k] = { card = card, face = face, glow = glow, imgs = imgs }
	end
	stage.mirrors = { M = d.M, list = list, Until = d.Until, Born = now() }
end
function P.Section(E, d)
	setSpell(d.Title, d.Id == "BlackHole" and "Last Imagination" or nil)
	showBanner(d.Title, d.Id == "BlackHole" and "Last Imagination" or "Spell Card")
	flash(0.2, SHINE, 0.4)
	local pal = PALETTE[d.Id]
	if pal then S.goalA, S.goalB = pal[1], pal[2] end
	if stage and S.center then
		if stage.shock then stage.shock.ring.Part:Destroy() end
		stage.shock = { ring = flatRing("ring.thick", pal and pal[1] or SHINE, 0.05), born = os.clock() }
	end
	 -- his circles flare as he declares it
	local r = S.boss and rootOf(S.boss)
	if r then
		local g = E.Group("SonicBlasterCard")
		local a = E.Anchor(g, r.CFrame)
		E.Sprite(a, { tex = "sigil.mandala", size = { { 0, 6 }, { 0.35, 40 }, { 1, 46 } }, alpha = { { 0, 0.1 }, { 0.6, 0.3 }, { 1, 1 } }, color = pal and pal[1] or GOLD, spin = { 60, 60 } }, 1.2)
		E.Sprite(a, { tex = "flare.burst", size = { { 0, 4 }, { 0.3, 34 }, { 1, 40 } }, alpha = { { 0, 0 }, { 1, 1 } }, color = WHITE }, 0.45)
		E.Emit(a, { tex = "star.crisp", size = { { 0, 1.6 }, { 1, 0 } }, color = { { 0, WHITE }, { 1, pal and pal[2] or GOLD } }, life = { 0.5, 1 }, speed = { 30, 70 }, spread = 180, drag = 3 }, 40)
		E.After(g, 1.5, function() g:Destroy() end)
	end
end
 -- a miss: the hit would have killed. A star falls, the bullets round them burst, they flicker untouchable for a moment
function P.Miss(E, d)
	local y = (S.floorY or 0) + SB.Height
	local r2 = (d.R or SB.MissClear) ^ 2
	local t = now()
	local c0 = os.clock()
	local popped = 0
	for _, b in ipairs(S.bullets) do
		if not b.dieAt and not b.into and t >= b.t0 and (b.x - d.X) ^ 2 + (b.z - d.Z) ^ 2 < r2 then
			b.dieAt = c0
			b.hit = true
			if popped < 30 then
				popped += 1
				spark(Vector3.new(b.x, y, b.z), SB.Colors[b.c] or WHITE, 2.4, 0.3)
			end
		end
	end
	local pos = Vector3.new(d.X, y, d.Z)
	local yellow = Color3.fromRGB(255, 222, 40)
	local g = E.Group("SonicBlasterMiss")
	local a = E.Anchor(g, CFrame.new(pos))
	E.Sprite(a, { tex = "flare.burst", size = { { 0, 6 }, { 0.2, 46 }, { 1, 56 } }, alpha = { { 0, 0 }, { 1, 1 } }, color = WHITE }, 0.5)
	E.Sprite(a, { tex = "star.anime", size = { { 0, 4 }, { 0.25, 30 }, { 1, 8 } }, alpha = { { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } }, color = yellow, spin = { 120, 120 } }, 0.8)
	E.Emit(a, { tex = "star.anime", size = { { 0, 2.2 }, { 1, 0 } }, color = { { 0, WHITE }, { 1, yellow } }, life = { 0.5, 1 }, speed = { 25, 60 }, spread = 180, drag = 3 }, 40)
	E.Light(g, a, yellow, 50, 8, 0.6)
	E.After(g, 1.4, function() g:Destroy() end)
	if stage then
		table.insert(stage.wipes, { ring = flatRing("ring.thick", yellow, 0), born = c0, pos = Vector3.new(d.X, (S.floorY or 0) + 0.3, d.Z), r = d.R or SB.MissClear })
	end
	if d.Char then blink(d.Char, d.Grace or SB.MissGrace) end
	if d.Char and d.Char == player.Character then
		S.localImmune = c0 + (d.Grace or SB.MissGrace)
		flash(0.55, Color3.fromRGB(255, 240, 180), 0.7)
		shake(0.03, 0.5)
		if d.Last then finalDefeat() else toast("A star falls...") end
	end
end
 -- the clock's minute hand ticks onto a mark: a flare at the hub and a spark where its warning line meets the rim
function P.Tick(E, d)
	if not S.center or not S.floorY then return end
	local dir = Vector3.new(math.cos(d.Ang), 0, math.sin(d.Ang))
	local hub = Vector3.new(S.center.X, S.floorY + SB.Height, S.center.Z)
	spark(hub, GOLD, 9, 0.25)
	spark(hub + dir * (S.radius - 2), SHINE, 7, 0.4)
	shake(0.006, 0.12)
end
function P.Accent(E, d)
	if d.Kind == "Freeze" then
		flash(0.3, ICE, 0.9)
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Saturation = -0.85 cc.TintColor = ICE cc.Parent = Lighting
		task.delay(0.42, function()
			Tween:Create(cc, TweenInfo.new(0.2), { Saturation = 0, TintColor = WHITE }):Play()
			task.delay(0.25, function() cc:Destroy() end)
		end)
	elseif d.Kind == "Drop" then
		flash(0.5, WHITE, 0.5)
		shake(0.045, 0.7)
		S.bump = 1
	end
end
 -- every bullet is drawn into the black hole
function P.Cancel(E, d)
	local t = now()
	local y = (S.floorY or 0) + SB.Height
	local sparked = 0
	for _, b in ipairs(S.bullets) do
		if sparked < 36 and SB.Advance(b, t) then
			sparked += 1
			local x, z = SB.Where(b, t)
			spark(Vector3.new(x, y, z), SB.Colors[b.c] or WHITE, 2.4, 0.25)
		end
		undress(b)
	end
	table.clear(S.bullets)
	for _, l in pairs(S.lasers) do l.Off = math.min(l.Off, t) end
	for _, col in pairs(S.columns) do col.Off = math.min(col.Off, t) col.On = math.min(col.On, t) end
	if stage and stage.mirrors then stage.mirrors.Until = t end
	flash(0.35, SHINE, 0.8)
end
 -- the black hole: it opens behind the stage, and the camera turns to watch him say goodbye
function P.BlackHole(E, d)
	S.blackHole = true
	buildHole(d)
	shake(0.03, 1.4)
	flash(0.25, Color3.fromRGB(200, 170, 255), 1)
	S.tiltGoal = 1
end
function P.Fly(E, d)
	local r = rootOf(d.Boss)
	if r then
		local g = E.Group("NothingFlight")
		local a0 = Instance.new("Attachment") a0.Position = Vector3.new(0, 1.5, 0) a0.Parent = r
		local a1 = Instance.new("Attachment") a1.Position = Vector3.new(0, -1.5, 0) a1.Parent = r
		local tr = Instance.new("Trail")
		tr.Attachment0 = a0 tr.Attachment1 = a1 tr.Lifetime = 0.6 tr.LightEmission = 1 tr.LightInfluence = 0 tr.FaceCamera = true
		tr.Color = ColorSequence.new(SHINE, VIOLET) tr.Transparency = NumberSequence.new(0.1, 1) tr.WidthScale = NumberSequence.new(1, 0.2)
		tr.Parent = r
		local life = d.T1 - now() + 0.5
		task.delay(math.max(life, 0.5), function() tr:Destroy() a0:Destroy() a1:Destroy() end)
		E.After(g, life, function() g:Destroy() end)
	end
	 -- the camera follows him in, from the side
	local from, to = d.From, d.To
	shoot(function(t)
		local boss = bossAt(d.Boss, from)
		local dir = (to - from)
		dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.zAxis
		local side = dir:Cross(UP)
		side = side.Magnitude > 0.1 and side.Unit or Vector3.xAxis
		local p = from:Lerp(to, 0.22) + side * 48 + UP * 10 - dir * 30
		return CFrame.lookAt(p, boss:Lerp(to, 0.25)), 56 - t * 2
	end, 0.8)
end
function P.Vanish(E, d)
	S.vanished = true
	if d.Boss then hideBoss(d.Boss, true) end
	if hole then hole.closing = os.clock() end
	local g = E.Group("NothingVanish")
	local a = E.Anchor(g, CFrame.new(d.Pos))
	E.Sprite(a, { tex = "flare.burst", size = { { 0, 20 }, { 0.2, 260 }, { 1, 300 } }, alpha = { { 0, 0 }, { 1, 1 } }, color = WHITE }, 0.9)
	E.Sprite(a, { tex = "ring.thin", size = { { 0, 10 }, { 1, 520 } }, alpha = { { 0, 0 }, { 1, 1 } }, color = GOLD }, 1.4)
	E.Sprite(a, { tex = "star.lens", size = { { 0, 30 }, { 0.3, 200 }, { 1, 40 } }, alpha = { { 0, 0 }, { 1, 1 } }, color = SHINE, spin = { 30, 30 } }, 1.2)
	E.Emit(a, { tex = "star.crisp", size = { { 0, 3 }, { 1, 0 } }, color = { { 0, WHITE }, { 1, GOLD } }, life = { 0.8, 1.6 }, speed = { 60, 160 }, spread = 180, drag = 2 }, 80)
	E.Light(g, a, WHITE, 300, 12, 0.8)
	E.After(g, 2, function() g:Destroy() end)
	shake(0.05, 0.9)
	whiteout(1.2, Color3.fromRGB(255, 248, 230))
	S.running = false
	 -- the win screen takes over: the bars go, the camera is yours again
	task.delay(0.6, function()
		destroyHole()
		hideHud(false)
		letterbox(false)
		dim(false)
		release()
	end)
end
function P.Return(E, d)
	whiteout(1, WHITE)
	task.delay(0.3, function()
		teardown()
		destroyWorld()
		spaceSky(false)
	end)
end
function P.End(E, d)
	S.running = false
	flash(0.4, SHINE, 0.8)
	task.delay(0.4, function()
		teardown()
		destroyWorld()
		spaceSky(false)
	end)
end

return P

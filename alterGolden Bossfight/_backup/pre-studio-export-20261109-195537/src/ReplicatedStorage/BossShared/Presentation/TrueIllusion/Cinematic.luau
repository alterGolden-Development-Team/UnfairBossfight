local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
local Reset=require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Style = require(script.Parent.Style)

local Cinematic = {}
Cinematic.Settings = {
	Enabled = true,
	IntroCamera = true,  -- True Illusion is the boss's 1 HP last stand: it earns its cutscene
	Shake = 1,  
	Flash = 1,  
	ImpactFrame = true,
	DisplayOrder = -5,  
	Title = "TRUE ILLUSION",
	FinaleTitle = "ROYAL FLUSH",
}

local GOLD, WHITE, INK, IVORY, FLASH = Style.Gold, Style.White, Style.Ink, Style.Ivory, Style.Flash
local TAU = math.pi * 2
local SUIT_BY_NAME = Style.Suits
local function smooth(a) return a * a * (3 - 2 * a) end
local function easeOut(a) return 1 - (1 - a) ^ 3 end

local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	if parent then instance.Parent = parent end
	return instance
end
local function flashScale()
	local scale = Cinematic.Settings.Flash
	if player:GetAttribute("ReduceFlashing") then scale = math.min(scale, 0.2) end
	return scale
end

 
local gui, hud
local ui = {}
local function ensureGui()
	if gui and gui.Parent then return end
	local playerGui = player:WaitForChild("PlayerGui")
	gui = make("ScreenGui", { Name = "TrueIllusionCinematic", ResetOnSpawn = false, IgnoreGuiInset = true,
		DisplayOrder = Cinematic.Settings.DisplayOrder, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
	ui.top = make("Frame", { BackgroundColor3 = INK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), ZIndex = 5 }, gui)
	ui.bottom = make("Frame", { BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0), ZIndex = 5 }, gui)
	ui.flash = make("Frame", { BackgroundColor3 = FLASH, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 9 }, gui)
	 
	ui.title = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.8, 0.16),
		BackgroundTransparency = 1, Font = Enum.Font.Garamond, TextScaled = true, Text = "", TextColor3 = GOLD, TextTransparency = 1, ZIndex = 8 }, gui)
	ui.titleStroke = make("UIStroke", { Color = INK, Thickness = 4, Transparency = 1 }, ui.title)
	ui.titleScale = make("UIScale", { Scale = 1 }, ui.title)
	ui.subtitle = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromScale(0.5, 0.045),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true, Text = "", TextColor3 = WHITE, TextTransparency = 1, ZIndex = 8 }, gui)
	ui.subtitleStroke = make("UIStroke", { Color = INK, Thickness = 2, Transparency = 1 }, ui.subtitle)
	 
	ui.impact = make("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 10, Visible = false, ClipsDescendants = true }, gui)
	ui.lines = {}
	local taper = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.1), NumberSequenceKeypoint.new(1, 1) })
	for index = 1, 36 do
		local line = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 11 }, ui.impact)
		make("UIGradient", { Transparency = taper }, line)
		ui.lines[index] = line
	end
	ui.slashes = {}
	local soft = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) })
	for index = 1, 2 do
		local bar = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 12 }, ui.impact)
		make("UIGradient", { Transparency = soft }, bar)
		ui.slashes[index] = bar
	end
	ui.impactText = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.8, 0.16),
		BackgroundTransparency = 1, Font = Enum.Font.Garamond, TextScaled = true, Text = "", TextColor3 = INK, ZIndex = 13 }, ui.impact)
	 
	ui.hand = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.985), Size = UDim2.fromScale(0.42, 0.16),
		BackgroundTransparency = 1, ZIndex = 7, Visible = false }, gui)
	make("UIAspectRatioConstraint", { AspectRatio = 3.2 }, ui.hand)
	ui.cards = {}
	for index = 1, 5 do
		local slot = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.1 + (index - 1) * 0.2, 1.6),
			Size = UDim2.fromScale(0.17, 0.95), BackgroundColor3 = IVORY, BorderSizePixel = 0, Rotation = (index - 3) * 5, ZIndex = 7 }, ui.hand)
		make("UICorner", { CornerRadius = UDim.new(0.08, 0) }, slot)
		local stroke = make("UIStroke", { Color = GOLD, Thickness = 3 }, slot)
		local rank = make("TextLabel", { Position = UDim2.fromScale(0.06, 0.02), Size = UDim2.fromScale(0.5, 0.3), BackgroundTransparency = 1,
			Font = Enum.Font.Garamond, TextScaled = true, Text = "", TextColor3 = INK, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, slot)
		local pip = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Size = UDim2.fromScale(0.75, 0.55),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true, Text = "♠", TextColor3 = GOLD, ZIndex = 8 }, slot)
		make("UIStroke", { Color = INK, Thickness = 2 }, pip)
		local glow = make("UIStroke", { Color = WHITE, Thickness = 0, Transparency = 1 }, make("Frame", { Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1, ZIndex = 9 }, slot))
		ui.cards[index] = { Slot = slot, Stroke = stroke, Rank = rank, Pip = pip, Glow = glow, Home = slot.Position, Rotation = slot.Rotation }
	end

	 
	hud = make("Frame", { Name = "TrueIllusionHUD", AnchorPoint = Vector2.one, Position = UDim2.new(1, -20, 1, -68),
		Size = UDim2.fromOffset(260, 64), BackgroundColor3 = INK, BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false, ZIndex = 20 }, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, hud)
	make("UIStroke", { Color = GOLD, Thickness = 1.5, Transparency = 0.3 }, hud)
	ui.hudSuit = make("TextLabel", { Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextScaled = true, Text = "♠", TextColor3 = GOLD, ZIndex = 21 }, hud)
	make("UIStroke", { Color = INK, Thickness = 2 }, ui.hudSuit)
	ui.hudSuitScale = make("UIScale", { Scale = 1 }, ui.hudSuit)
	ui.hudTitle = make("TextLabel", { Position = UDim2.fromOffset(72, 8), Size = UDim2.fromOffset(180, 22), BackgroundTransparency = 1,
		Font = Enum.Font.Garamond, TextScaled = true, Text = "TRUE ILLUSION", TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21 }, hud)
	ui.hudCount = make("TextLabel", { Position = UDim2.fromOffset(72, 32), Size = UDim2.fromOffset(180, 16), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextScaled = true, Text = "", TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21 }, hud)
	local barBack = make("Frame", { Position = UDim2.fromOffset(72, 52), Size = UDim2.fromOffset(176, 4), BackgroundColor3 = Color3.fromRGB(60, 44, 10),
		BorderSizePixel = 0, ZIndex = 21 }, hud)
	ui.hudBar = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 22 }, barBack)
end

 
local run  
local camera = {}  
local shakeOffset, fovOffset, applied = CFrame.identity, 0, false

local function releaseCamera()
	if not camera.Saved then return end
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType=camera.Saved.Type==Enum.CameraType.Scriptable and Enum.CameraType.Custom or camera.Saved.Type
		cam.FieldOfView = camera.Saved.Fov
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		cam.CameraSubject = humanoid or camera.Saved.Subject
	end
	camera.Saved, camera.Shot = nil, nil
end
local function holdCamera(shot)
 if not Reset.ViewAllowed() then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	if not camera.Saved then
		camera.Saved = { Type = cam.CameraType, Subject = cam.CameraSubject, Fov = Fov.Base(cam), Frame = cam.CFrame }
	end
	camera.Shot = shot
	cam.CameraType = Enum.CameraType.Scriptable
end

local function setGrade(r, brightness, contrast, saturation, tint, bloom)
	if not r.cc then
		r.cc = make("ColorCorrectionEffect", { Name = "TrueIllusionGrade", Brightness = 0, Contrast = 0, Saturation = 0,
			TintColor = Color3.new(1, 1, 1) }, Lighting)
		r.bloom = make("BloomEffect", { Name = "TrueIllusionBloom", Intensity = 0, Size = 28, Threshold = 0.9 }, Lighting)
	end
	r.grade = { Brightness = brightness, Contrast = contrast, Saturation = saturation, TintColor = tint, Bloom = bloom }
end
local function letterbox(height, seconds)
	ensureGui()
	local info = TweenInfo.new(seconds or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ui.top, info, { Size = UDim2.fromScale(1, height) }):Play()
	TweenService:Create(ui.bottom, info, { Size = UDim2.fromScale(1, height) }):Play()
end
local function flash(strength, seconds, color)
	ensureGui()
	strength = math.clamp((strength or 0.8) * flashScale(), 0, 1)
	if strength <= 0 then return end
	ui.flash.BackgroundColor3 = color or FLASH
	ui.flash.BackgroundTransparency = 1 - strength
	TweenService:Create(ui.flash, TweenInfo.new(seconds or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
end
local function shake(r, intensity, seconds)
	table.insert(r.shakes, { Intensity = intensity, Start = os.clock(), Duration = math.max(seconds or 0.3, 0.05) })
end
local function punch(r, amount, seconds)
	table.insert(r.punches, { Amount = amount, Start = os.clock(), Duration = math.max(seconds or 0.3, 0.05) })
end

local function showTitle(text, sub, hold)
	ensureGui()
	ui.title.Text, ui.subtitle.Text = text, sub or ""
	ui.title.TextTransparency, ui.titleStroke.Transparency = 0, 0
	ui.subtitle.TextTransparency, ui.subtitleStroke.Transparency = sub and 0 or 1, sub and 0.2 or 1
	ui.titleScale.Scale = 1.8
	TweenService:Create(ui.titleScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local out = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, hold or 1)
	TweenService:Create(ui.title, out, { TextTransparency = 1 }):Play()
	TweenService:Create(ui.titleStroke, out, { Transparency = 1 }):Play()
	TweenService:Create(ui.subtitle, out, { TextTransparency = 1 }):Play()
	TweenService:Create(ui.subtitleStroke, out, { Transparency = 1 }):Play()
end

 
local IMPACT = {
	{ Share = 0.36, Back = WHITE, Ink = INK },
	{ Share = 0.34, Back = INK, Ink = WHITE },
	{ Share = 0.30, Back = FLASH, Ink = Color3.fromRGB(150, 92, 6) },
}
local function startImpact(r, duration, worldFocus, text)
	if not Cinematic.Settings.ImpactFrame then return end
	ensureGui()
	local cam = workspace.CurrentCamera
	local screen = cam.ViewportSize
	local diag = screen.Magnitude
	local focal = Vector2.new(screen.X * 0.5, screen.Y * 0.45)
	if worldFocus then
		local point, visible = cam:WorldToViewportPoint(worldFocus)
		if visible then focal = Vector2.new(point.X, point.Y) end
	end
	local rng = r.rng
	for index, line in ipairs(ui.lines) do
		local angle = ((index - 1) / #ui.lines) * TAU + rng:NextNumber(-0.06, 0.06)
		local length = diag * rng:NextNumber(0.22, 0.6)
		local middle = diag * rng:NextNumber(0.07, 0.2) + length * 0.5
		line.Size = UDim2.fromOffset(length, math.max(2, screen.Y * rng:NextNumber(0.003, 0.013)))
		line.Position = UDim2.fromOffset(focal.X + math.cos(angle) * middle, focal.Y + math.sin(angle) * middle)
		line.Rotation = math.deg(angle)
	end
	local tilt = math.rad(rng:NextNumber(-28, -14))
	for index, bar in ipairs(ui.slashes) do
		local shift = index == 1 and 0 or screen.Y * 0.07
		bar.Size = UDim2.fromOffset(diag * 1.4, screen.Y * (index == 1 and 0.07 or 0.016))
		bar.Position = UDim2.fromOffset(focal.X - math.sin(tilt) * shift, focal.Y + math.cos(tilt) * shift)
		bar.Rotation = math.deg(tilt)
	end
	ui.impactText.Text = text or ""
	r.impact = { Start = os.clock(), Duration = duration, Shown = nil }
end
local function updateImpact(r, now)
	local imp = r.impact
	if not imp then
		if ui.impact and ui.impact.Visible then ui.impact.Visible = false end
		return
	end
	local elapsed = now - imp.Start
	if elapsed >= imp.Duration then
		r.impact = nil
		ui.impact.Visible = false
		return
	end
	local reduced = flashScale() < 0.3
	local index, acc = #IMPACT, 0
	if not reduced then
		for i, spec in ipairs(IMPACT) do
			acc += spec.Share
			if elapsed / imp.Duration < acc then index = i break end
		end
	end
	if imp.Shown ~= index then
		imp.Shown = index
		local spec = IMPACT[index]
		ui.impact.Visible = true
		ui.impact.BackgroundColor3 = spec.Back
		ui.impact.BackgroundTransparency = reduced and 0.6 or (index == #IMPACT and 0.15 or 0)
		for _, line in ipairs(ui.lines) do line.Visible = not reduced; line.BackgroundColor3 = spec.Ink end
		for _, bar in ipairs(ui.slashes) do bar.Visible = not reduced; bar.BackgroundColor3 = spec.Ink end
		ui.impactText.TextColor3 = spec.Ink
		ui.impactText.Visible = not reduced
	end
end

 
local function introShot(r, t)
	local O, F = r.origin, r.facing
	local right = F:Cross(Vector3.yAxis)
	right = right.Magnitude > 0.01 and right.Unit or Vector3.xAxis
	local up = Vector3.yAxis
	local L1, title = r.line1, r.titleAt
	if t < L1 then
		 
		local a = smooth(math.clamp(t / L1, 0, 1))
		local angle = -0.55 + 1.1 * a
		local offset = (F * math.cos(angle) + right * math.sin(angle)) * (10 - 2.5 * a) + up * (1.6 + 0.8 * a)
		return CFrame.lookAt(O + offset, O + up * (2.2 + 0.3 * a)), 52 - 6 * a
	end
	 
	local a = smooth(math.clamp((t - L1) / math.max(title - L1, 0.1), 0, 1))
	local position = O - F * (6 + 22 * a) + right * (3 - 1 * a) + up * (4 + 26 * a)
	local look = O + F * (14 + 10 * a) + up * (2 - 2 * a)
	return CFrame.lookAt(position, look), 58 + 14 * a
end

local function cleanup(r)
	if r.done then return end
	r.done = true
	releaseCamera()
	for _, instance in ipairs({ r.cc, r.bloom }) do
		if instance then instance:Destroy() end
	end
	if gui then
		letterbox(0, 0.35)
		ui.hand.Visible = false
		ui.impact.Visible = false
		hud.Visible = false
	end
	if run == r then run = nil end
end

local function valid(r)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local owner = r.owner
	return owner and owner.Parent and not owner:GetAttribute("EncounterEnded") and owner:GetAttribute("Phase") == 3.5
		and os.clock() - r.began < 240
end

local GRADE_REST = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1), Bloom = 0 }

local function updateHud(dt)
	local owner = run and run.owner or workspace:FindFirstChild("alterGolden, the Nothing")
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local visible = owner and owner.Parent and owner:GetAttribute("Phase") == 3.5
		and owner:GetAttribute("TrueIllusionActive") and not owner:GetAttribute("EncounterEnded")
		and not player:GetAttribute("ViewAsServer") and hum and hum.Health > 0
		and workspace:GetServerTimeNow() >= (owner:GetAttribute("TrueIllusionMusicStartedAt") or math.huge) + 18.2
	if not visible then if hud then hud.Visible = false end return end
	ensureGui()
	hud.Visible = true
	local suit = SUIT_BY_NAME[owner:GetAttribute("TrueIllusionSuit")]
	if suit and ui.hudSuit.Text ~= suit.Symbol then
		ui.hudSuit.Text, ui.hudSuit.TextColor3 = suit.Symbol, suit.Color
		ui.hudSuitScale.Scale = 1.7
	end
	ui.hudSuitScale.Scale += (1 - ui.hudSuitScale.Scale) * math.min(1, dt * 12)
	local left = owner:GetAttribute("TrueIllusionClonesRemaining") or 0
	ui.hudCount.Text = string.format("CLONES LEFT  %d", left)
	ui.hudBar.Size = UDim2.fromScale(math.clamp(left / math.max(1, owner:GetAttribute("TrueIllusionCloneCount") or 100), 0, 1), 1)
end

local function step(dt)
	updateHud(dt)
	local r = run
	 
	local cam = workspace.CurrentCamera
	if not r then return end
	if not valid(r) then cleanup(r) return end
	if not Reset.ViewAllowed() then
	 releaseCamera() if r.cc then r.cc.Enabled=false end if r.bloom then r.bloom.Enabled=false end
	 if gui then gui.Enabled=false end return
	end
	if gui then gui.Enabled=true end if r.cc then r.cc.Enabled=true end if r.bloom then r.bloom.Enabled=true end
	local now = os.clock()
	local t = now - r.t0

	 
	if r.introShot and camera.Shot then
		if t < r.titleAt then
			local frame, fov = introShot(r, t)
			cam.CFrame = frame
			cam.FieldOfView = fov
		else
			r.introShot = false
			releaseCamera()  
		end
	end

	 
	if r.cc and r.grade then
		local k = 1 - math.exp(-dt * (r.gradeSpeed or 4))
		local g = r.grade
		r.cc.Brightness += (math.min(g.Brightness, g.Brightness * flashScale()) - r.cc.Brightness) * k
		r.cc.Contrast += (g.Contrast - r.cc.Contrast) * k
		r.cc.Saturation += (g.Saturation - r.cc.Saturation) * k
		r.cc.TintColor = r.cc.TintColor:Lerp(g.TintColor, k)
		r.bloom.Intensity += (g.Bloom - r.bloom.Intensity) * k
	end

	 
	for index = #r.beats, 1, -1 do
		local beat = r.beats[index]
		if t >= beat.At then
			table.remove(r.beats, index)
			beat.Fn(r)
		end
	end


	 
	if r.hand then
		for index, card in ipairs(ui.cards) do
			local state = r.hand[index]
			if state then
				local lift = state.Active and -0.18 or 0
				local goal = UDim2.new(card.Home.X.Scale, 0, 1 + lift, 0)
				if state.Dealt then
					card.Slot.Position = card.Slot.Position:Lerp(goal, math.min(1, dt * 14))
				end
				local glow = state.Active and (0.25 + 0.2 * math.sin(now * 12)) or 1
				card.Glow.Transparency = glow
				card.Glow.Thickness = state.Active and 4 or 0
				card.Slot.BackgroundTransparency = state.Spent and 0.55 or 0
				card.Pip.TextTransparency = state.Spent and 0.55 or 0
				card.Rank.TextTransparency = state.Spent and 0.55 or 0
			end
		end
	end

	updateImpact(r, now)

	 
	local amplitude, fov = 0, 0
	for index = #r.shakes, 1, -1 do
		local s = r.shakes[index]
		local a = (now - s.Start) / s.Duration
		if a >= 1 then table.remove(r.shakes, index) else amplitude += s.Intensity * math.min(a * 20, 1) * (1 - a) ^ 2 end
	end
	for index = #r.punches, 1, -1 do
		local p = r.punches[index]
		local a = (now - p.Start) / p.Duration
		if a >= 1 then table.remove(r.punches, index) else fov += p.Amount * math.min(a * 20, 1) * (1 - a) ^ 2 end
	end
	amplitude = math.min(amplitude, 2.5) * Cinematic.Settings.Shake
	fov *= Cinematic.Settings.Shake
	if amplitude > 0 or fov ~= 0 then
		local nx = math.noise(now * 23, r.seed, 0) * 2
		local ny = math.noise(r.seed, now * 21, 3.1) * 2
		local nz = math.noise(now * 17, r.seed, 7.7) * 2
		shakeOffset = CFrame.new(nx * amplitude * 0.8, ny * amplitude * 0.8, 0)
			* CFrame.Angles(ny * amplitude * 0.02, nx * amplitude * 0.02, nz * amplitude * 0.03)
		fovOffset = fov
		cam.CFrame = cam.CFrame * shakeOffset
		cam.FieldOfView += fovOffset
		applied = true
	end

	if r.finishAt and now >= r.finishAt then cleanup(r) end
end

RunService:BindToRenderStep("TrueIllusionCinematicUndo", Enum.RenderPriority.Camera.Value - 1, function()
	if not applied then return end
	applied = false
	local cam = workspace.CurrentCamera
	if not cam then return end
	cam.CFrame = cam.CFrame * shakeOffset:Inverse()
	cam.FieldOfView -= fovOffset
	shakeOffset, fovOffset = CFrame.identity, 0
end)
RunService:BindToRenderStep("TrueIllusionCinematic", Enum.RenderPriority.Camera.Value + 2, step)

local function begin(payload)
	ensureGui()
	if run then cleanup(run) end
	local r = {
		token = payload.Token, owner = payload.Owner, character = player.Character, began = os.clock(), t0 = os.clock(),
		shakes = {}, punches = {}, beats = {}, rng = Random.new(os.clock() * 1000), seed = math.random(1, 1000),
	}
	run = r
	return r
end
local function at(r, seconds, fn) table.insert(r.beats, { At = seconds, Fn = fn }) end

 
local function intro(payload)
	local r = begin(payload)
	r.origin = typeof(payload.Origin) == "Vector3" and payload.Origin or Vector3.zero
	local facing = typeof(payload.Facing) == "Vector3" and Vector3.new(payload.Facing.X, 0, payload.Facing.Z) or Vector3.new(0, 0, -1)
	r.facing = facing.Magnitude > 0.01 and facing.Unit or Vector3.new(0, 0, -1)
	r.line1 = math.max(payload.Line1 or 1.2, 0.3)
	r.titleAt = math.max(payload.TitleAt or 2.5, r.line1 + 0.3)
	letterbox(0.1, 0.45)
	setGrade(r, -0.03, 0.12, -0.25, Color3.fromRGB(255, 240, 205), 0.45)
	r.gradeSpeed = 3
	if Cinematic.Settings.IntroCamera then
		holdCamera(true)
		r.introShot = true
	end
	at(r, r.line1, function()
		setGrade(r, -0.06, 0.2, -0.35, Color3.fromRGB(255, 226, 150), 0.8)
		punch(r, -4, r.titleAt - r.line1)
	end)
	at(r, r.titleAt, function()
		startImpact(r, 0.16, r.origin + Vector3.new(0, 3, 0), Cinematic.Settings.Title)
		flash(0.7, 0.35)
		shake(r, 0.9, 0.45)
		punch(r, 10, 0.4)
		showTitle(Cinematic.Settings.Title, tostring(payload.CloneCount or 100) .. " FACES  ·  ONE IMAGINATION", 1.2)
		setGrade(r, 0.02, 0.08, -0.08, Color3.fromRGB(255, 246, 225), 0.3)
		r.gradeSpeed = 2
		letterbox(0, 0.6)
	end)
	at(r, r.titleAt + 0.4, function()
		r.hud = true
		hud.Visible = true
	end)
end

local function finale(payload)
	local r = run
	if not (r and r.token == payload.Token) then r = begin(payload) end
	r.hud = true
	if hud then hud.Visible = true end
	r.t0 = os.clock()
	r.beats = {}
	letterbox(0.06, 0.4)
	setGrade(r, -0.05, 0.25, -0.3, Color3.fromRGB(255, 214, 120), 1.0)
	r.gradeSpeed = 3
	local ranks = type(payload.Ranks) == "table" and payload.Ranks or { "10", "J", "Q", "K", "A" }
	local symbol = type(payload.Symbol) == "string" and payload.Symbol or "♠"
	ui.hand.Visible = true
	r.hand = {}
	for index, card in ipairs(ui.cards) do
		card.Rank.Text = ranks[index] or ""
		card.Pip.Text = symbol
		card.Slot.Position = UDim2.new(card.Home.X.Scale, 0, 1.7, 0)
		r.hand[index] = { Dealt = false }
		local dealAt = (index - 1) * (payload.DealInterval or 0.22) + (payload.DealFlight or 0.55)
		at(r, dealAt, function()
			r.hand[index].Dealt = true
			shake(r, 0.25, 0.15)
		end)
	end
	at(r, payload.TitleAt or 2, function()
		startImpact(r, 0.15, typeof(payload.Origin) == "Vector3" and payload.Origin + Vector3.new(0, 20, 0) or nil, Cinematic.Settings.FinaleTitle)
		flash(0.6, 0.35, GOLD)
		shake(r, 0.8, 0.4)
		punch(r, 8, 0.35)
		showTitle(Cinematic.Settings.FinaleTitle, ranks[1] .. "  " .. (ranks[2] or "") .. "  " .. (ranks[3] or "") .. "  " .. (ranks[4] or "") .. "  " .. (ranks[5] or "") .. "  " .. symbol, 1.1)
	end)
end

local function card(payload)
	local r = run
	if not (r and r.token == payload.Token and r.hand) then return end
	local index = tonumber(payload.Index) or 0
	for i, state in ipairs(r.hand) do
		if state.Active and i ~= index then state.Active = false; state.Spent = true end
		if i == index then state.Active = true; state.Dealt = true end
	end
	shake(r, 0.3, 0.2)
	if payload.Kind == "Ace" then
		setGrade(r, -0.1, 0.35, -0.45, Color3.fromRGB(255, 196, 80), 1.3)
		letterbox(0.09, 0.5)
		punch(r, -6, 1.4)
	end
end

local function strike(payload)
	local r = run
	if not (r and r.token == payload.Token) then return end
	startImpact(r, 0.18, typeof(payload.To) == "Vector3" and payload.To or nil, "")
	flash(0.9, 0.45, FLASH)
	shake(r, 1.6, 0.6)
	punch(r, 14, 0.45)
	setGrade(r, 0.1, 0.15, -0.1, Color3.fromRGB(255, 240, 200), 0.8)
	for _, state in ipairs(r.hand or {}) do
		if state.Active then state.Active = false; state.Spent = true end
	end
end

local function finish(payload)
	local r = run
	if not (r and r.token == payload.Token) then return end
	r.hud = false
	if hud then hud.Visible = false end
	releaseCamera()
	letterbox(0, 0.5)
	r.grade = GRADE_REST
	r.gradeSpeed = 3
	r.finishAt = os.clock() + (payload.Interrupted and 0.35 or 1.2)
end

 
function Cinematic.Handle(payload)
	if type(payload) ~= "table" or not Cinematic.Settings.Enabled then return end
	local stage = payload.Stage
	if stage == "End" then finish(payload) return end
	local owner = payload.Owner
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not workspace.CurrentCamera or typeof(owner) ~= "Instance" or not owner.Parent or owner:GetAttribute("Phase") ~= 3.5 then return end
	if stage == "Intro" then
		intro(payload)
	elseif stage == "Finale" then
		finale(payload)
	elseif stage == "Card" then
		card(payload)
	elseif stage == "Strike" then
		strike(payload)
	end
end

 
function Cinematic.Stop()
	if run then cleanup(run) end
end

function Cinematic.ResetView()
 releaseCamera()
 if run then run.introShot=false if run.cc then run.cc.Enabled=false end if run.bloom then run.bloom.Enabled=false end end
 if gui then gui.Enabled=false end
end
Reset.Register(script,Cinematic.Stop,Cinematic.ResetView)
return Cinematic

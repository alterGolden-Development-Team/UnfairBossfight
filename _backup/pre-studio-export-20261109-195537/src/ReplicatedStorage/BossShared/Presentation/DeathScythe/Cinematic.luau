local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
local Reset=require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)



local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local ScytheModel = require(script.Parent.ScytheModel)
local Style = require(script.Parent.Style)

local Cinematic = {}

Cinematic.Settings = {
	Enabled = true,
	Shake = 1,             
	Flash = 1,             
	ImpactFrame = true,    
	GiantScythe = false,   
						   
	DisplayOrder = -10,    
	Text = "GOODBYE",
	 
	Sounds = { Forming = "", Cue = "", Halted = "", Impact = "", Flash = "", End = "" },
}
 
 

local TAU = math.pi * 2
local GOLD = Style.BloodHot
local EDGE = Style.Edge
local DEEP = Style.Deep
local VOID = Style.Void
local VIGNETTE = Style.Vignette
local FLASH = Style.Flash
local WHITE = Color3.new(1, 1, 1)

 
 
local IMPACT_FRAMES = {
	{ Share = 0.36, Back = WHITE, Ink = VOID,  Accent = GOLD },   
	{ Share = 0.36, Back = VOID,  Ink = WHITE, Accent = EDGE },   
	{ Share = 0.28, Back = FLASH, Ink = DEEP,  Accent = WHITE },  
}
local IMPACT_LINES = 40

local CHANNELS = { "b", "c", "s", "dim", "vig", "blur", "fov", "shake", "tilt", "bloom" }
local NEUTRAL = { b = 0, c = 0, s = 0, dim = 1, vig = 1, blur = 0, fov = 0, shake = 0, tilt = 0, bloom = 0 }
local ABORT_TIME = 0.3

local run  

local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	if parent then instance.Parent = parent end
	return instance
end

local function smooth(a) return a * a * (3 - 2 * a) end

local function playSound(id, volume)
	if type(id) ~= "string" or id == "" then return end
	local sound = make("Sound", { SoundId = id, Volume = volume or 1 }, SoundService)
	sound:Play()
	Debris:AddItem(sound, 8)
end

local function flashScale()
	local scale = Cinematic.Settings.Flash
	if player:GetAttribute("ReduceFlashing") then scale = math.min(scale, 0.2) end
	return scale
end

 
 
 
 
 
local function buildKeys(Fd, Hd, Id, Sd, cueT)
	local H0, I0, S0, E0 = Fd, Fd + Hd, Fd + Hd + Id, Fd + Hd + Id + Sd
	local pop = cueT + (Fd - cueT) * 0.35  
	local loomEnd = H0 + Hd * 0.5
	local function k(t, b, c, s, tint, dim, vig, blur, fov, shake, tilt, bloom)
		return { t = t, b = b, c = c, s = s, tint = tint, dim = dim, vig = vig, blur = blur, fov = fov, shake = shake, tilt = tilt, bloom = bloom }
	end
	return {
		k(0,                 0,     0,     0,     WHITE,                       1,    1,    0,   0,    0,   0,     0),
		k(cueT * 0.5,        0,     0.05, -0.1,   Color3.fromRGB(255, 240, 205), 1,   0.8,  0,  -1.5, 0.5, 0.01,  0.25),   
		k(cueT,             -0.02,  0.12, -0.2,   Color3.fromRGB(255, 228, 150), 1,   0.6,  0,  -3.5, 0.6, 0.015, 0.45),   
		k(pop,               0.05,  0.15, -0.25,  Color3.fromRGB(255, 232, 160), 1,   0.5,  0,  -6,   1.3, 0.02,  0.95),   
		k(Fd,               -0.04,  0.2,  -0.3,   Color3.fromRGB(255, 208, 110), 1,   0.4,  0,  -7,   1.0, 0.03,  0.7),    
		 
		k(loomEnd,          -0.12,  0.25, -0.4,   Color3.fromRGB(255, 178, 62),  0.82, 0.3, 0.5, -9,  1.2, 0.05,  0.6),
		k(I0 - Hd * 0.1,    -0.2,   0.32, -0.5,   Color3.fromRGB(255, 150, 30),  0.7,  0.15, 1,  -12, 0.8, 0.07,  0.8),
		k(I0,               -0.2,   0.32, -0.5,   Color3.fromRGB(255, 150, 30),  0.7,  0.15, 1,  -12, 0.8, 0.07,  0.8),     
		k(S0,                0.42,  0.5,  -0.85,  FLASH,                         1,   1,    20,  14,   3.4, -0.05, 1.7),    
		k(S0 + Sd * 0.3,    -0.02,  0.28,  0.1,   Color3.fromRGB(255, 214, 100), 1,   0.55, 5,   8,   2.3, 0,     1.0),    
		k(S0 + Sd * 0.75,    0,     0.12,  0,     Color3.fromRGB(255, 226, 145), 1,   0.6,  0,   4,   1.4, 0,     0.6),
		k(E0,               -0.01,  0.05, -0.05,  Color3.fromRGB(255, 238, 195), 1,   0.7,  0,   1,   0.5, 0,     0.3),
		k(E0 + 0.35,         0,     0,     0,     WHITE,                       1,    1,    0,   0,    0,   0,     0),
	}
end

local function sampleKeys(keys, t, out)
	local a, b, alpha = keys[1], keys[1], 0
	if t >= keys[#keys].t then
		a, b = keys[#keys], keys[#keys]
	elseif t > keys[1].t then
		for i = 1, #keys - 1 do
			if t <= keys[i + 1].t then
				a, b = keys[i], keys[i + 1]
				alpha = smooth((t - a.t) / math.max(b.t - a.t, 1e-4))
				break
			end
		end
	end
	for _, channel in ipairs(CHANNELS) do
		out[channel] = a[channel] + (b[channel] - a[channel]) * alpha
	end
	out.tint = a.tint:Lerp(b.tint, alpha)
end

 
local FADE_IN = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
local SOFT_ENDS = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1),
})
local LINE_TAPER = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.1), NumberSequenceKeypoint.new(1, 1) })

local function box(props, parent)
	props.BorderSizePixel = 0
	if props.BackgroundTransparency == nil then props.BackgroundTransparency = 1 end
	return make("Frame", props, parent)
end

local function buildUI(r)
	local gui = make("ScreenGui", {
		Name = "DeathScytheCinematic", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = Cinematic.Settings.DisplayOrder,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, player:WaitForChild("PlayerGui"))
	r.gui = gui

	r.vignette = {}
	local function edge(position, size, rotation, anchor)
		local f = box({ BackgroundColor3 = VIGNETTE, Position = position, Size = size, AnchorPoint = anchor, ZIndex = 1 }, gui)
		make("UIGradient", { Rotation = rotation, Transparency = FADE_IN }, f)
		table.insert(r.vignette, f)
	end
	edge(UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.45), 90, Vector2.new(0, 0))
	edge(UDim2.fromScale(0, 1), UDim2.fromScale(1, 0.45), -90, Vector2.new(0, 1))
	edge(UDim2.fromScale(0, 0), UDim2.fromScale(0.4, 1), 0, Vector2.new(0, 0))
	edge(UDim2.fromScale(1, 0), UDim2.fromScale(0.4, 1), 180, Vector2.new(1, 0))

	r.dim = box({ BackgroundColor3 = VOID, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, gui)

	r.speckles = {}
	for index = 1, 70 do
		local size = r.rng:NextInteger(2, 6)
		r.speckles[index] = box({
			BackgroundColor3 = r.rng:NextNumber() < 0.3 and DEEP or GOLD, Size = UDim2.fromOffset(size, size),
			Position = UDim2.fromScale(r.rng:NextNumber(), r.rng:NextNumber(0.35, 1)), ZIndex = 3,
		}, gui)
	end

	r.bands = {}
	for index, spec in ipairs({ { y = 0.11, h = 0.05, rot = -3 }, { y = 0.17, h = 0.022, rot = 2 }, { y = 0.83, h = 0.035, rot = 3 } }) do
		local band = box({
			BackgroundColor3 = index == 2 and EDGE or GOLD, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1.4, spec.h), Position = UDim2.fromScale(1.5, spec.y), Rotation = spec.rot, ZIndex = 4,
		}, gui)
		make("UIGradient", { Transparency = SOFT_ENDS }, band)
		r.bands[index] = { Frame = band, Y = spec.y }
	end

	 
	 
	r.cue = box({
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
		Visible = false, ZIndex = 7,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, r.cue)
	r.cueStroke = make("UIStroke", { Color = GOLD, Thickness = 3, Transparency = 0.5 }, r.cue)

	 
	r.text = make("TextLabel", {
		Name = "Goodbye", Text = Cinematic.Settings.Text, Font = Enum.Font.Creepster, TextScaled = true, TextColor3 = GOLD,
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.8),
		Size = UDim2.fromScale(0.7, 0.17), Visible = false, ZIndex = 6,
	}, gui)
	make("UIStroke", { Color = Color3.fromRGB(40, 22, 0), Thickness = 5 }, r.text)
	r.textScale = make("UIScale", { Scale = 1 }, r.text)

	r.ripples = {}
	for index = 1, 3 do
		local ring = box({
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
			Visible = false, ZIndex = 8,
		}, gui)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
		r.ripples[index] = { Frame = ring, Stroke = make("UIStroke", { Color = index == 2 and GOLD or FLASH, Thickness = 6, Transparency = 0 }, ring) }
	end

	r.flash = box({ BackgroundColor3 = FLASH, Size = UDim2.fromScale(1, 1), ZIndex = 9 }, gui)

	 
	r.impact = box({
		BackgroundColor3 = WHITE, BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1), ZIndex = 10, Visible = false,
		ClipsDescendants = true,
	}, gui)
	r.impactLines = {}
	for index = 1, IMPACT_LINES do
		local line = box({
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = VOID, BackgroundTransparency = 0, Size = UDim2.fromOffset(0, 0), ZIndex = 11,
		}, r.impact)
		make("UIGradient", { Transparency = LINE_TAPER }, line)
		r.impactLines[index] = line
	end
	r.impactSlash = {}
	for index = 1, 2 do
		local bar = box({
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = VOID, BackgroundTransparency = 0, Size = UDim2.fromOffset(0, 0), ZIndex = 12,
		}, r.impact)
		make("UIGradient", { Transparency = SOFT_ENDS }, bar)
		r.impactSlash[index] = bar
	end
end

 
 
local function layoutImpact(r, cam)
	local screen = cam.ViewportSize
	local diag = screen.Magnitude
	local focal = Vector2.new(screen.X * 0.5, screen.Y * 0.5)
	if r.origin then
		local point, onScreen = cam:WorldToViewportPoint(r.origin + Vector3.new(0, 4, 0))
		if onScreen then focal = Vector2.new(point.X, point.Y) end
	end
	local rng = r.rng
	local count = #r.impactLines
	for index, line in ipairs(r.impactLines) do
		local angle = ((index - 1) / count) * TAU + rng:NextNumber(-0.06, 0.06)
		local length = diag * rng:NextNumber(0.22, 0.6)
		local middle = diag * rng:NextNumber(0.06, 0.2) + length * 0.5  
		line.Size = UDim2.fromOffset(length, math.max(2, screen.Y * rng:NextNumber(0.003, 0.014)))
		line.Position = UDim2.fromOffset(focal.X + math.cos(angle) * middle, focal.Y + math.sin(angle) * middle)
		line.Rotation = math.deg(angle)  
	end
	local tilt = rng:NextNumber(-30, -14)  
	local rad = math.rad(tilt)
	for index, bar in ipairs(r.impactSlash) do
		local shift = index == 1 and 0 or screen.Y * 0.075  
		bar.Size = UDim2.fromOffset(diag * 1.4, screen.Y * (index == 1 and 0.085 or 0.018))
		bar.Position = UDim2.fromOffset(focal.X - math.sin(rad) * shift, focal.Y + math.cos(rad) * shift)
		bar.Rotation = tilt
	end
end

local function impactIndex(r, elapsed)
	local share, acc = elapsed / math.max(r.Id, 1e-3), 0
	for index, spec in ipairs(IMPACT_FRAMES) do
		acc += spec.Share
		if share < acc then return index end
	end
	return #IMPACT_FRAMES
end

 
local function focus()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then return root.Position end
	local cam = workspace.CurrentCamera
	return cam.CFrame.Position + cam.CFrame.LookVector * 20
end

 
 
local function spawnShards(r, count, speedMin, speedMax, lenMin, lenMax, life, flat, inward)
	local origin = focus()
	local rng = r.rng
	for _ = 1, count do
		local yaw = rng:NextNumber(0, TAU)
		local pitch = flat and rng:NextNumber(-0.18, 0.18) or rng:NextNumber(-0.5, 0.9)
		local dir = Vector3.new(math.cos(yaw) * math.cos(pitch), math.sin(pitch), math.sin(yaw) * math.cos(pitch))
		local length = rng:NextNumber(lenMin, lenMax)
		local part = make("WedgePart", {
			Name = "Shard", Size = Vector3.new(0.12, 0.5, length), Anchored = true, CanCollide = false, CanQuery = false,
			CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = rng:NextNumber() < 0.25 and EDGE or GOLD,
			Transparency = 1,
		}, r.fx)
		table.insert(r.shards, {
			Part = part, Dir = inward and -dir or dir, Length = length, Speed = rng:NextNumber(speedMin, speedMax), Life = life * rng:NextNumber(0.8, 1.2),
			Drag = inward and 1.3 or -1.8,      
			FadeIn = inward and 0.15 or 0,      
			Born = os.clock() + rng:NextNumber(0, inward and 0.45 or 0.18),
			Pos = origin + dir * (inward and rng:NextNumber(16, 30) or rng:NextNumber(3, 12)) + Vector3.new(0, rng:NextNumber(0.5, 6), 0),
		})
	end
end

local function updateShards(r, now, dt)
	for index = #r.shards, 1, -1 do
		local shard = r.shards[index]
		if now >= shard.Born then
			local f = (now - shard.Born) / shard.Life
			if f >= 1 then
				shard.Part:Destroy()
				table.remove(r.shards, index)
			else
				shard.Pos = shard.Pos + shard.Dir * (shard.Speed * dt)
				shard.Speed = shard.Speed * math.exp(shard.Drag * dt)
				shard.Part.Size = Vector3.new(0.12, 0.5, shard.Length * (1 - 0.4 * f))
				shard.Part.CFrame = CFrame.lookAt(shard.Pos, shard.Pos + shard.Dir)
				local fadeIn = shard.FadeIn > 0 and math.clamp(f / shard.FadeIn, 0, 1) or 1
				shard.Part.Transparency = 1 - fadeIn * (1 - f * f * f)
			end
		end
	end
end

 
local function giantFrame(p)
	local e = smooth(p)
	return CFrame.new(24 - 48 * e, -5 + 11 * e, -(10.5 + 3 * math.sin(p * math.pi)))
		* CFrame.Angles(math.rad(-36), math.rad(16), -0.5 + 1.0 * e)
		* CFrame.new(13, -24, 0)  
end
Cinematic._giantFrame = giantFrame

local function updateGiant(r, t, cam)
	if not (ScytheModel and Cinematic.Settings.GiantScythe) then return end
	local p = (t - r.H0 - 0.02) / (r.Hd * 0.5 - 0.02)
	if p > 0 and p < 1 then
		if not r.giant then
			r.giant = ScytheModel.Build({ Detail = 1, Name = "GiantScythe" })
			ScytheModel.SetTransparency(r.giant, 1, 0)
			r.giant.Light.Brightness, r.giant.Light.Range = 6, 40
			r.giant.Model.Parent = r.fx
		end
		r.giant.Root.CFrame = cam.CFrame * giantFrame(p)
	elseif r.giant then
		r.giant.Model:Destroy()
		r.giant = nil
	end
end

 
local function cleanup(r)
	if r.done then return end
	r.done = true
	RunService:UnbindFromRenderStep("DeathScytheCinematic")
	local cam = workspace.CurrentCamera
	if cam == r.camera then cam.FieldOfView = r.baseFov end
	for _, instance in ipairs({ r.gui, r.fx, r.cc, r.blur, r.bloom }) do
		if instance then instance:Destroy() end
	end
	if run == r then run = nil end
end

local function applyUI(r, t, now, cur)
	local scale = flashScale()
	local cam = workspace.CurrentCamera
	local screen = cam.ViewportSize
	r.dim.BackgroundTransparency = cur.dim
	for _, f in ipairs(r.vignette) do f.BackgroundTransparency = cur.vig end

	 
	if not r.abort and t >= 0 and t < r.Fd then
		local a = t / r.Fd
		local big, small = math.max(screen.X, screen.Y) * 1.05, math.min(screen.X, screen.Y) * 0.2
		local size = big + (small - big) * a
		local open = t >= r.cueT
		r.cue.Visible = true
		r.cue.Size = UDim2.fromOffset(size, size)
		r.cueStroke.Color = open and EDGE or GOLD
		r.cueStroke.Thickness = open and 6 or 3
		r.cueStroke.Transparency = open and 0.05 or (0.55 - 0.3 * a)
	else
		r.cue.Visible = false
	end

	 
	local since = t - r.H0
	if since >= 0 and not r.abort then
		local pop = math.max(0, 1 - since / 0.16)
		local out = math.clamp((t - (r.S0 + 0.02)) / 0.12, 0, 1)  
		r.text.Visible = out < 1
		r.textScale.Scale = 1 + 1.3 * pop * pop
		r.text.TextTransparency = out
		r.text.Position = UDim2.new(0.5, math.floor(math.noise(now * 40, 3) * 7), 0.8, math.floor(math.noise(5, now * 40) * 5))
		r.text.Rotation = math.noise(now * 25, 9) * 4
	else
		r.text.Visible = false
	end

	 
	 
	local impactElapsed = t - r.I0
	if Cinematic.Settings.ImpactFrame and not r.abort and impactElapsed >= 0 and impactElapsed < r.Id then
		if not r.impactReady then
			r.impactReady = true
			layoutImpact(r, cam)
		end
		local reduced = scale < 0.3
		local index = reduced and #IMPACT_FRAMES or impactIndex(r, impactElapsed)
		if r.impactShown ~= index then
			r.impactShown = index
			local spec = IMPACT_FRAMES[index]
			r.impact.Visible = true
			r.impact.BackgroundColor3 = spec.Back
			r.impact.BackgroundTransparency = reduced and 0.55 or (index == #IMPACT_FRAMES and 0.1 or 0)
			for _, line in ipairs(r.impactLines) do
				line.Visible = not reduced
				line.BackgroundColor3 = spec.Ink
			end
			r.impactSlash[1].BackgroundColor3 = spec.Ink
			r.impactSlash[2].BackgroundColor3 = spec.Accent
			for _, bar in ipairs(r.impactSlash) do bar.Visible = not reduced end
		end
	elseif r.impact.Visible then
		r.impact.Visible = false
		r.impactShown = nil
	end

	 
	local ft = t - r.S0
	local flashLen = math.min(0.16, r.Sd * 0.4)
	local flashTransparency = 1
	if ft >= 0 and ft < flashLen then flashTransparency = 0.05 + 0.95 * (ft / flashLen) ^ 0.6 end
	r.flash.BackgroundTransparency = 1 - (1 - flashTransparency) * scale
	local reach = math.max(screen.X, screen.Y) * 1.7
	for index, ripple in ipairs(r.ripples) do
		local rt = ft - (index - 1) * 0.06
		if rt >= 0 and rt < 0.5 and scale > 0.05 then
			local a = rt / 0.5
			local size = reach * smooth(a)
			ripple.Frame.Visible = true
			ripple.Frame.Size = UDim2.fromOffset(size, size)
			ripple.Stroke.Transparency = math.clamp(a * 1.1 + (1 - scale), 0, 1)
			ripple.Stroke.Thickness = 7 - 5 * a
		else
			ripple.Frame.Visible = false
		end
	end

	 
	for index, band in ipairs(r.bands) do
		local bt = ft - 0.03 - (index - 1) * 0.05
		if bt >= 0 and bt < 0.7 then
			band.Frame.Position = UDim2.fromScale(0.5 + 0.95 * (1 - smooth(math.clamp(bt / 0.15, 0, 1))), band.Y)
			band.Frame.BackgroundTransparency = math.clamp((bt - 0.3) / 0.4, 0, 1)
		else
			band.Frame.BackgroundTransparency = 1
		end
	end
	local speckling = ft > 0.05 and ft < 0.7
	for index, speck in ipairs(r.speckles) do
		if speckling and (index * 7 + math.floor(now * 18)) % 3 ~= 0 then
			speck.BackgroundTransparency = math.clamp((ft - 0.4) / 0.3, 0, 1)
		else
			speck.BackgroundTransparency = 1
		end
	end
end

local function step(dt)
	local r = run
	if not r then return end
	local now = os.clock()
	local cam = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not cam or not r.owner or not r.owner.Parent or r.owner:GetAttribute("EncounterEnded")
		or math.min(4, math.floor(r.owner:GetAttribute("Phase") or 0)) ~= 4 then cleanup(r); return end
	local t = now - r.t0
	local viewAllowed=Reset.ViewAllowed()
	if not viewAllowed then Cinematic.ResetView() end
	if r.gui then r.gui.Enabled=viewAllowed end
	r.cc.Enabled=viewAllowed r.blur.Enabled=viewAllowed r.bloom.Enabled=viewAllowed
	local cur = r.cur

	if r.abort then
		local a = math.clamp((now - r.abort.at) / ABORT_TIME, 0, 1)
		for _, channel in ipairs(CHANNELS) do
			cur[channel] = r.abort.from[channel] * (1 - a) + NEUTRAL[channel] * a
		end
		cur.tint = r.abort.from.tint:Lerp(WHITE, a)
		if a >= 1 then
			cleanup(r)
			return
		end
	else
		sampleKeys(r.keys, t, cur)
		if t > r.E0 + 0.5 then
			cleanup(r)
			return
		end
		if not r.cuePlayed and t >= r.cueT then
			r.cuePlayed = true
			playSound(Cinematic.Settings.Sounds.Cue, 1)
		end
		if not r.haltedPlayed and t >= r.H0 then
			r.haltedPlayed = true
			playSound(Cinematic.Settings.Sounds.Halted, 1)
			spawnShards(r, math.floor(40 * r.power), 140, 230, 4, 9, 0.6, false, false)  
		end
		if not r.impactPlayed and t >= r.I0 then
			r.impactPlayed = true
			playSound(Cinematic.Settings.Sounds.Impact, 1)
		end
		if not r.flashed and t >= r.S0 then
			r.flashed = true
			playSound(Cinematic.Settings.Sounds.Flash, 1)
			spawnShards(r, math.floor(34 * r.power), 220, 340, 7, 14, 0.5, true, false)  
		end
	end

	 
	local scale = flashScale()
	local brightness, contrast = cur.b, cur.c
	if brightness > 0 then brightness *= scale end
	if contrast > 0.5 then contrast = 0.5 + (contrast - 0.5) * scale end
	r.cc.Brightness, r.cc.Contrast, r.cc.Saturation, r.cc.TintColor = brightness, contrast, cur.s, cur.tint
	r.blur.Size = cur.blur
	r.bloom.Intensity = cur.bloom

	 
	if viewAllowed then
	local amount = cur.shake * r.power * Cinematic.Settings.Shake
	local nt = now * 37
	local dx, dy, dz = math.noise(nt, 0.5, r.seed), math.noise(1.5, nt, r.seed), math.noise(nt, nt, r.seed)
	cam.CFrame = cam.CFrame * CFrame.new(dx * amount * 0.25, dy * amount * 0.25, 0)
		* CFrame.Angles(dy * amount * 0.006, dx * amount * 0.006, cur.tilt * Cinematic.Settings.Shake + dz * amount * 0.012)
	cam.FieldOfView = r.baseFov + cur.fov * r.power
	end

	updateShards(r, now, dt)
	updateGiant(r, t, cam)
	applyUI(r, t, now, cur)
end

local function begin(payload, alreadyElapsed)
	if run then cleanup(run) end
	local Fd = payload.FormationDuration or (payload.Stage == "Forming" and payload.Duration) or Style.FormationDuration
	local Hd = payload.HaltDuration or Style.HaltDuration
	local Id = payload.ImpactDuration or Style.ImpactDuration
	local Sd = payload.SweepDuration or Style.SweepDuration
	if payload.Stage == "Halted" and not payload.HaltDuration and payload.Duration then
		local total = Style.HaltDuration + Style.ImpactDuration + Style.SweepDuration
		Hd = payload.Duration * (Style.HaltDuration / total)
		Id = payload.Duration * (Style.ImpactDuration / total)
		Sd = payload.Duration - Hd - Id
	end
	 
	local cueT = math.clamp(Fd - (payload.JumpCueLead or Style.JumpCueLead), Fd * 0.25, Fd * 0.9)
	local isTarget = payload.TargetUserId == player.UserId
	local headcount = math.min(payload.Headcount or 0, 5)

	local cam = workspace.CurrentCamera
	local r = {
		token = payload.Token, owner = payload.Owner, camera = cam, character = player.Character, Fd = Fd, Hd = Hd, Id = Id, Sd = Sd, cueT = cueT,
		H0 = Fd, I0 = Fd + Hd, S0 = Fd + Hd + Id, E0 = Fd + Hd + Id + Sd,
		origin = typeof(payload.Origin) == "Vector3" and payload.Origin or nil,
		t0 = os.clock() - (alreadyElapsed or 0), power = 0.75 + (isTarget and 0.25 or 0) + 0.04 * headcount,
		shards = {}, cur = {}, baseFov = Fov.Base(cam), rng = Random.new(os.clock() * 1000), seed = math.random(1, 1000),
	}
	r.keys = buildKeys(Fd, Hd, Id, Sd, cueT)
	r.fx = make("Folder", { Name = "DeathScytheLocalFX" }, workspace)
	r.cc = make("ColorCorrectionEffect", { Name = "DeathScytheCC" }, Lighting)
	r.blur = make("BlurEffect", { Name = "DeathScytheBlur", Size = 0 }, Lighting)
	r.bloom = make("BloomEffect", { Name = "DeathScytheBloom", Intensity = 0, Size = 28, Threshold = 0.85 }, Lighting)
	buildUI(r)
	run = r

	 
	if (alreadyElapsed or 0) < Fd * 0.5 then
		spawnShards(r, math.floor(46 * r.power), 12, 24, 4, 10, Fd * 0.95, false, true)
	end
	playSound(Cinematic.Settings.Sounds.Forming, 1)
	RunService:BindToRenderStep("DeathScytheCinematic", Enum.RenderPriority.Camera.Value + 1, step)
end

 
function Cinematic.Handle(payload)
	if type(payload) ~= "table" then return end
	if payload.Stage ~= "End" then
		local owner = payload.Owner
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not Cinematic.Settings.Enabled or player:GetAttribute("ViewAsServer")
			or not workspace.CurrentCamera
			or typeof(owner) ~= "Instance" or not owner.Parent or math.min(4, math.floor(owner:GetAttribute("Phase") or 0)) ~= 4 then return end
	end
	local stage = payload.Stage
	if stage == "Forming" then
		begin(payload, 0)
	elseif stage == "Halted" then
		if run and run.token == payload.Token and not run.abort then
			run.t0 = os.clock() - run.Fd  
		else
			begin(payload, payload.FormationDuration or Style.FormationDuration)
		end
	elseif stage == "End" then
		if run and run.token == payload.Token then Cinematic.Stop() end
	end
end

 
function Cinematic.Stop(immediate)
	local r = run
	if not r then return end
	if immediate then cleanup(r); return end
	if r.abort then return end
	if os.clock() - r.t0 >= r.E0 - 0.3 then return end  
	local from = {}
	for _, channel in ipairs(CHANNELS) do from[channel] = r.cur[channel] or NEUTRAL[channel] end
	from.tint = r.cur.tint or WHITE
	r.abort = { at = os.clock(), from = from }
	r.text.Visible = false
	r.cue.Visible = false
end

function Cinematic.ResetView()
 local r=run if not r then return end
 if r.cc then r.cc.Enabled=false end if r.blur then r.blur.Enabled=false end if r.bloom then r.bloom.Enabled=false end
 if r.gui then r.gui.Enabled=false end
 local cam=workspace.CurrentCamera
 if cam and r.baseFov then cam.FieldOfView=r.baseFov end
end
Reset.Register(script,function()Cinematic.Stop(true)end,Cinematic.ResetView)
return Cinematic


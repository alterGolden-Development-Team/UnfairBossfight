 
local Tween = game:GetService("TweenService")
local Run = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local Time=require(script:FindFirstAncestor("BossSystem").Mechanics.Time.TimeEffectController)

local FX = {}
local function folder()
	local f = workspace:FindFirstChild("ClassEffects")
	if not f then
		f = Instance.new("Folder")
		f.Name = "ClassEffects"
		f.Parent = workspace
	end
	return f
end
FX.Folder = folder

function FX.Part(props, life)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = props.Parent or folder()
	if life then
		Debris:AddItem(p, life)
	end
	return p
end
local function fade(p, time, goal)
	goal = goal or {}
	goal.Transparency = 1
	Tween:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end
FX.Fade = fade

function FX.Flash(pos, color, size, time)
	time = time or 0.35
	local p = FX.Part({ Shape = Enum.PartType.Ball, Size = Vector3.one * size * 0.4, CFrame = CFrame.new(pos), Color = color, Transparency = 0.1 }, time + 0.1)
	fade(p, time, { Size = Vector3.one * size })
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = color, size * 2, 3
	light.Parent = p
	Tween:Create(light, TweenInfo.new(time), { Brightness = 0 }):Play()
	return p
end

function FX.Ring(pos, color, radius, time, thickness)
	time = time or 0.4
	local p = FX.Part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(thickness or 0.25, radius * 0.3, radius * 0.3),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Transparency = 0.2 }, time + 0.1)
	fade(p, time, { Size = Vector3.new(thickness or 0.25, radius * 2, radius * 2) })
	return p
end

function FX.Beam(a, b, color, width, time)
	time = time or 0.25
	local len = (b - a).Magnitude
	if len < 0.05 then
		return
	end
	local p = FX.Part({ Size = Vector3.new(width, width, len), CFrame = CFrame.lookAt((a + b) / 2, b), Color = color, Transparency = 0.1 }, time + 0.1)
	fade(p, time, { Size = Vector3.new(width * 0.15, width * 0.15, len) })
	return p
end

function FX.Burst(pos, color, count, speed, life)
	local p = FX.Part({ Size = Vector3.one * 0.2, CFrame = CFrame.new(pos), Transparency = 1 }, (life or 0.6) + 0.5)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1):Lerp(color, 0.4))
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new((life or 0.6) * 0.6, life or 0.6)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = p
	e:Emit(count)
	return p
end

 
function FX.Slash(frame, color, radius, arcDegrees, time)
	time = time or 0.22
	local pieces = 9
	for i = 0, pieces - 1 do
		local a = math.rad(-arcDegrees / 2 + arcDegrees * i / (pieces - 1))
		local dir = (frame * CFrame.Angles(0, a, 0)).LookVector
		local mid = frame.Position + dir * radius * 0.6
		local p = FX.Part({ Size = Vector3.new(0.15, 0.6, radius * 0.8), CFrame = CFrame.lookAt(mid, mid + dir), Color = color, Transparency = 0.15 + i * 0.05 }, time + 0.2)
		task.delay(i * time / pieces * 0.6, function()
			if p.Parent then
				fade(p, time * 0.7)
			end
		end)
	end
end

 
function FX.Projectile(origin, direction, speed, range, visual, onStep)
	local pos, travelled = origin, 0
	visual.CFrame = CFrame.lookAt(origin, origin + direction)
	local conn
	conn = Run.Heartbeat:Connect(function(dt)
  if Time.IsStopped() or workspace:GetAttribute("GoldenTimeStopped")==true then return end
		local step = speed * dt
		pos += direction * step
		travelled += step
		if visual.Parent then
			visual.CFrame = CFrame.lookAt(pos, pos + direction)
		end
		local stop = onStep(pos) or travelled >= range
		if stop then
			conn:Disconnect()
			if visual.Parent then
				fade(visual, 0.15)
				Debris:AddItem(visual, 0.2)
			end
		end
	end)
	return conn
end

function FX.Trail(part, color, width)
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, width / 2, 0), Vector3.new(0, -width / 2, 0)
	a0.Parent, a1.Parent = part, part
	local t = Instance.new("Trail")
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = ColorSequence.new(color)
	t.LightEmission = 1
	t.Lifetime = 0.25
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	t.Parent = part
	return t
end

function FX.Text(pos, text, color, size)
	local p = FX.Part({ Size = Vector3.one * 0.2, CFrame = CFrame.new(pos), Transparency = 1 }, 1.6)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(240, 60)
	g.AlwaysOnTop = true
	g.StudsOffset = Vector3.new(0, 1, 0)
	g.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.Parent = g
	Tween:Create(g, TweenInfo.new(1.4), { StudsOffset = Vector3.new(0, 4, 0) }):Play()
	Tween:Create(l, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	return p
end

 
 
 
 
local ICONS = {
	Blocking = "BLOCK", DamageBoost = "+ATK", DefenseBoost = "+DEF", HPRegen = "+HP REGEN", StaminaRegen = "+STA REGEN", SpeedBoost = "+SPD", Uninterrupted = "UNINTERRUPTED", ShieldRaised = "+DEF", ParryStance = "PARRY",
	ParryLocked = "LOCKED", LaserCharge = "CHARGING", Taunt = "TAUNT", Rampage = "+DEF",
	Almighty = "SHIELD", FateLinked = "LINKED", Undying = "UNDYING", SecondWind = "2ND WIND",
	Rolling = "+DEF", BadLuck = "-ATK", HeavyPockets = "-SPD", Exhausted = "-STA", LoadedHand = "+ATK", QuickDraw = "+FIRE RATE",
	LuckySix = "+ATK +FIRE RATE", TrustedGun = "EMPOWERED", Jackpot = "JACKPOT", Stunned = "STUNNED",
}
local SHAPES = {
	Almighty = "bubble", Undying = "halo", Stunned = "stars", Jackpot = "glow", SecondWind = "halo",
	Defender = "glow", BadLuck = "cloud", ParryStance = "glow",
}
local function torsoOf(model)
	return model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
end
local function weld(part, to, offset)
	part.Anchored = false
	part.Massless = true
	part.CFrame = to.CFrame * (offset or CFrame.identity)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = to, part
	w.Parent = part
	part.Parent = to.Parent
end

function FX.StatusOn(model, id)
	local def = ClassConfig.Statuses[id]
	local torso = torsoOf(model)
	if not def or not torso or model:FindFirstChild("ClassStatusFX_" .. id) then
		return
	end
	local holder = Instance.new("Folder")
	holder.Name = "ClassStatusFX_" .. id
	holder.Parent = model
	 
	local att = Instance.new("Attachment")
	att.Name = "ClassStatusAura_" .. id
	att.Parent = torso
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(def.Color)
	e.LightEmission = def.Kind == "buff" and 0.8 or 0.2
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.6, 1)
	e.Speed = NumberRange.new(def.Kind == "buff" and 2 or 0.5)
	e.Acceleration = Vector3.new(0, def.Kind == "buff" and 3 or -4, 0)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 14
	e.Shape = Enum.ParticleEmitterShape.Box
	e.Parent = att
	local link = Instance.new("ObjectValue")
	link.Name = "Aura"
	link.Value = att
	link.Parent = holder
	 
	local head = model:FindFirstChild("Head") or torso
	local g = Instance.new("BillboardGui")
	g.Name = "ClassStatusIcon_" .. id
	g.Size = UDim2.fromOffset(110, 22)
	g.StudsOffset = Vector3.new(0, 2.6 + (#model:GetChildren() % 3) * 0.55, 0)
	g.AlwaysOnTop = false
	g.MaxDistance = 90
	g.Adornee = head
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.Text = ICONS[id] or def.Name
	l.TextColor3 = def.Color
	l.TextStrokeTransparency = 0.3
	l.Parent = g
	g:Destroy()
	 
	local shape = SHAPES[id]
	if shape == "dome" or shape == "bubble" then
		local s = FX.Part({ Shape = Enum.PartType.Ball, Size = Vector3.one * (shape == "dome" and 7 or 8), Color = def.Color,
			Transparency = shape == "dome" and 0.78 or 0.82, Material = Enum.Material.ForceField, Parent = holder })
		weld(s, torso)
		s.Parent = holder
	elseif shape == "halo" then
		local s = FX.Part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2.4, 2.4), Color = def.Color, Transparency = 0.15, Parent = holder })
		weld(s, head, CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)))
		s.Parent = holder
	elseif shape == "stars" then
		for i = 1, 4 do
			local s = FX.Part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.7, Color = def.Color, Transparency = 0, Parent = holder })
			s.CFrame = head.CFrame
			s.Parent = holder
			local a0 = i * math.pi / 2
			task.spawn(function()
				while s.Parent and head.Parent do
					local t = os.clock() * 4 + a0
					s.CFrame = head.CFrame * CFrame.new(math.cos(t) * 2, 1.6, math.sin(t) * 2)
					Run.Heartbeat:Wait()
				end
			end)
		end
	elseif shape == "glow" then
		local h = Instance.new("Highlight")
		h.FillColor = def.Color
		h.OutlineColor = def.Color
		h.FillTransparency = 0.7
		h.OutlineTransparency = 0.2
		h.Adornee = model
		h.Parent = holder
	elseif shape == "cloud" then
		local s = FX.Part({ Shape = Enum.PartType.Ball, Size = Vector3.new(3, 1.2, 3), Color = def.Color, Transparency = 0.4, Material = Enum.Material.SmoothPlastic, Parent = holder })
		weld(s, head, CFrame.new(0, 2, 0))
		s.Parent = holder
	end
end

function FX.StatusOff(model, id)
	local holder = model and model:FindFirstChild("ClassStatusFX_" .. id)
	if holder then
		local aura = holder:FindFirstChild("Aura")
		if aura and aura.Value then
			aura.Value:Destroy()
		end
		holder:Destroy()
	end
end


 
 
 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local VFX = require(BossSystem.Attacks.Shared.ShieldBreakVFX)
local Effects = require(BossSystem.Combat.EffectService)
local owner
local function getOwner()
	if owner and owner.Parent then
		return owner
	end
	owner = Instance.new("Model")
	owner.Name = "ClassEffectOwner"
	owner.Parent = folder()
	return owner
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace:FindFirstChild("GoldenGrasslandArena") or workspace.Terrain }
local ctx = {
	Core = setmetatable({}, { __index = function(_, key)
		local boss = workspace:FindFirstChild("alterGolden, the Nothing")
		if boss then
			local ok, core = pcall(function()
				return require(BossSystem.Combat.AttackRegistry).For(boss, "P1CombatCore")
			end)
			if ok and core and core[key] then
				return core[key]
			end
		end
		return function() end
	end }),
	Filter = function()
		return params
	end,
	Part = function(cast, name, frame, size, color, alpha)
		local p = Instance.new("Part")
		p.Name = name or "ClassVFX"
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material = Enum.Material.Neon
		p.CFrame = frame
		p.Size = size
		p.Color = color
		p.Transparency = alpha or 0
		p.Parent = folder()
		return cast:Add(p)
	end,
}
local function cast(life)
	return Effects.NewCast(getOwner(), "ClassFX", life or 2)
end
FX.HQ = {}
for _, name in ipairs({ "Shake", "Tint", "Crescent", "Impact", "Shockwave", "Ring", "Sparks", "Streaks", "Spikes", "Glint", "Beam", "Bolt", "Light", "Debris", "Smoke", "Flash" }) do
	FX.HQ[name] = function(...)
		local args = table.pack(...)
		local ok, result = pcall(function()
			return VFX[name](ctx, cast(3), table.unpack(args, 1, args.n))
		end)
		if not ok then
			warn("ClassFX." .. name .. ": " .. tostring(result))
		end
		return result
	end
end

 
function FX.Text(pos, text, color)
	FX.HQ.Glint(pos, color or Color3.new(1, 1, 1), 3.2, 0.35)
	FX.HQ.Light(pos, color or Color3.new(1, 1, 1), 3, 14, 0.3)
end
FX.HQ.Shake = function(origin, radius, duration, intensity)
	pcall(VFX.Shake, ctx, origin, radius, duration, intensity)
end
FX.HQ.Tint = function(origin, color, intensity, duration, radius)
	pcall(VFX.Tint, ctx, origin, color, intensity, duration, radius)
end
 
local basicFlash, basicRing, basicBurst, basicSlash, basicBeam = FX.Flash, FX.Ring, FX.Burst, FX.Slash, FX.Beam
function FX.Flash(pos, color, size, time)
	FX.HQ.Flash(pos, color, math.clamp(size / 4, 0.8, 6), time or 0.3, 0)
	FX.HQ.Light(pos, color, 3, size * 1.6, time or 0.3)
	return basicFlash(pos, color, size * 0.5, (time or 0.3) * 0.6)
end
function FX.Ring(pos, color, radius, time, thickness)
	FX.HQ.Shockwave(CFrame.new(pos), radius * 0.25, radius, time or 0.4, color, 0.1, thickness or 0.6)
end
function FX.Burst(pos, color, count, speed, life)
	FX.HQ.Sparks(pos, color, Color3.new(1, 1, 1):Lerp(color, 0.35), count, speed * 0.6, speed * 1.2, 0.35)
end
function FX.Slash(frame, color, radius, arcDegrees, time)
	FX.HQ.Crescent(frame, radius, math.rad(arcDegrees), math.max(0.8, radius * 0.12), color, Color3.new(1, 1, 1), time or 0.25)
end
function FX.Beam(a, b, color, width, time)
	FX.HQ.Beam(a, b, width, color, Color3.new(1, 1, 1), time or 0.25)
end
function FX.Impact(pos, color, scale)
	FX.HQ.Impact(pos, color, Color3.new(1, 1, 1):Lerp(color, 0.3), scale or 1)
end

 
 
 
 
local WHITE = Color3.new(1, 1, 1)
 
function FX.Charge(at, color, duration, size)
	size = size or 1.5
	local p = FX.Part({ Size = Vector3.one * size * 3, CFrame = CFrame.new(at), Transparency = 1 }, duration + 0.4)
	local e = Instance.new("ParticleEmitter")
	e.Shape = Enum.ParticleEmitterShape.Sphere
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	e.Color = ColorSequence.new(WHITE, color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12 * size), NumberSequenceKeypoint.new(0.7, 0.3 * size), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.1), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.3)
	e.Speed = NumberRange.new(size * 4.5)
	e.Rate = 70
	e.Parent = p
	task.delay(duration, function()
		e.Enabled = false
	end)
	FX.HQ.Glint(at, color, size * 1.2, duration + 0.1)
	FX.HQ.Light(at, color, 4, size * 6, duration + 0.1)
end
 
function FX.Release(at, dir, color, scale)
	scale = scale or 1
	FX.HQ.Flash(at, color, 1.1 * scale, 0.16, 0)
	FX.HQ.Ring(CFrame.lookAt(at, at + dir), 0.4 * scale, 4 * scale, 0.3, color, 0.1, 0.35 * scale, 2)
	FX.HQ.Streaks(at, dir, color, WHITE, math.floor(8 * scale), 14, 50 * scale, 110 * scale, 3 * scale)
	FX.HQ.Light(at, color, 5, 18 * scale, 0.18)
end
 
function FX.Hit(at, color, scale, heavy)
	scale = scale or 1
	FX.HQ.Impact(at, color, WHITE:Lerp(color, 0.3), scale)
	FX.HQ.Sparks(at, color, WHITE, math.floor(14 * scale), 20 * scale, 55 * scale, 0.35)
	FX.HQ.Shockwave(CFrame.new(at - Vector3.new(0, 2.6, 0)), 1, 7 * scale, 0.4, color, 0.25, 0.5 * scale)
	FX.HQ.Smoke(at, Color3.fromRGB(70, 70, 80), 1.1 * scale, math.floor(3 * scale), 3, 2)
	FX.HQ.Light(at, color, 6, 20 * scale, 0.25)
	FX.HQ.Shake(at, 45 * scale, heavy and 0.28 or 0.14, heavy and 0.75 or 0.3)
	if heavy then
		FX.HQ.Tint(at, color, 0.3, 0.25, 100)
		FX.HQ.Spikes(at - Vector3.new(0, 2.6, 0), 4, 4 * scale, 9 * scale, color, WHITE, 0.5)
	end
end
 
 
function FX.Orb(color, size)
	size = size or 1.2
	local glowPart = FX.Part({ Shape = Enum.PartType.Ball, Size = Vector3.one * size * 1.8, Color = color, Transparency = 0.55 })
	local core = FX.Part({ Shape = Enum.PartType.Ball, Size = Vector3.one * size, Color = WHITE:Lerp(color, 0.25), Transparency = 0 })
	FX.Trail(core, color, size * 1.2)
	local att = Instance.new("Attachment")
	att.Parent = core
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(WHITE, color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25 * size), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.25, 0.45)
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 60
	e.Parent = att
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = color, 10 * size, 2.5, false
	light.Parent = core
	local conn
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		if not core.Parent then
			conn:Disconnect()
			if glowPart.Parent then
				glowPart:Destroy()
			end
			return
		end
		glowPart.CFrame = core.CFrame
	end)
	return core, function()
		if core.Parent then
			core:Destroy()
		end
		if glowPart.Parent then
			glowPart:Destroy()
		end
	end
end
 
 
 
 
local BODY_PARTS = { Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true }
 
 
local function afterimage(char, color, life, point, alpha)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	life = life or 0.45
	local base = root.CFrame
	local at = point and (CFrame.new(point) * base.Rotation) or base
	local group = Instance.new("Folder")
	group.Name = "DuelistAfterimage"
	group.Parent = folder()
	Debris:AddItem(group, life + 0.3)
	local function ghost(part, tint)
		local g = Instance.new("Part")
		g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch, g.CastShadow = true, false, false, false, false
		g.Material = Enum.Material.Neon
		g.Color = tint
		g.Size = part.Size
		g.CFrame = at * base:ToObjectSpace(part.CFrame)
		g.Transparency = alpha or 0.45
		if part:IsA("Part") and part.Shape ~= Enum.PartType.Block then
			g.Shape = part.Shape
		end
		g.Parent = group
		Tween:Create(g, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1, Size = part.Size * 0.72 }):Play()
	end
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("BasePart") and BODY_PARTS[child.Name] and child.Transparency < 0.95 then
			ghost(child, color)
		end
	end
	local gear = char:FindFirstChild("ClassGear")
	if gear then
		for _, piece in ipairs(gear:GetChildren()) do
			if piece:IsA("BasePart") and piece.Transparency < 0.95 and piece.Size.Magnitude > 0.3 then
				ghost(piece, piece.Name:find("^Blade") and WHITE or color)
			end
		end
	end
	return group
end

 
function FX.Afterimage(char, color, life, point, alpha)
	local ok, result = pcall(afterimage, char, color, life, point, alpha)
	if not ok then
		warn("ClassFX.Afterimage: " .. tostring(result))
	end
	return ok and result or nil
end

function FX.AfterimageTrail(char, color, from, to, count, life)
	count = count or 4
	for i = 1, count do
		local alpha = i / count
		local point = from:Lerp(to, alpha)
		task.delay((i - 1) * 0.012, function()
			FX.Afterimage(char, color, (life or 0.4) * (0.55 + 0.45 * alpha), point, 0.5 - 0.15 * alpha)
		end)
	end
end

return FX

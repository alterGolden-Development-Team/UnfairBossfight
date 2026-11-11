 
 
local B = script:FindFirstAncestor("BossSystem")
local Effects = require(B.Combat.EffectService)
local Runtime = require(B.Combat.CombatRuntime)
local Style = require(script.Parent.Style)
local V = {}

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local NK, CK = NumberSequenceKeypoint.new, ColorSequenceKeypoint.new
local rng = Random.new()

local function part(cast, name, frame, size, color, alpha, shape, material)
	local p = Effects.AcquirePart()
	p.Name, p.Shape = name, shape or Enum.PartType.Block
	p.CFrame, p.Size, p.Color, p.Transparency = frame, size, color, alpha or 0
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Material = material or Enum.Material.Neon
	p.Parent = Runtime.Effects
	return cast:Add(p)
end
local function tween(p, time, goal, style, direction)
	Effects:Create(p, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal):Play()
end
local function later(cast, t, fn) cast:Schedule(t, fn) end
local function release(cast, t, p) cast:Schedule(t, function() Effects.Release(p) end) end
local function randomUnit()
	local z = rng:NextNumber(-1, 1)
	local a = rng:NextNumber(0, math.pi * 2)
	local r = math.sqrt(1 - z * z)
	return Vector3.new(r * math.cos(a), z, r * math.sin(a))
end

local CRESCENT_ALPHA = NumberSequence.new({ NK(0, 1), NK(0.12, 0.25), NK(0.5, 0), NK(0.88, 0.25), NK(1, 1) })
local GLOW_ALPHA = NumberSequence.new({ NK(0, 1), NK(0.5, 0.55), NK(1, 1) })
local CRESCENT_COLOR = ColorSequence.new({ CK(0, Style.Yellow), CK(0.5, Style.White), CK(1, Style.Yellow) })

 
function V.Streak(cast, a, b, thickness)
	thickness = thickness or 0.2
	local length = (b - a).Magnitude
	if length < 1 then return end
	local direction = (b - a).Unit
	local mid = (a + b) / 2
	local frame = CFrame.lookAt(mid, mid + direction)
	local glow = part(cast, "DeathRoarsStreakGlow", frame, Vector3.new(thickness * 4, thickness * 4, length * 0.3), Style.Yellow, 0.6)
	local core = part(cast, "DeathRoarsStreak", frame, Vector3.new(thickness, thickness, length * 0.3), Style.White, 0)
	tween(glow, 0.07, { Size = Vector3.new(thickness * 4, thickness * 4, length) }, Enum.EasingStyle.Quart)
	tween(core, 0.07, { Size = Vector3.new(thickness, thickness, length) }, Enum.EasingStyle.Quart)
	local hold = rng:NextNumber(0.05, 0.14)
	later(cast, 0.07 + hold, function()
		tween(glow, 0.28, { Size = Vector3.new(0.02, 0.02, length), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(core, 0.22, { Size = Vector3.new(0.01, 0.01, length * 1.03), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	release(cast, 0.4 + hold, glow)
	release(cast, 0.4 + hold, core)
end

 
 
function V.Crescent(cast, center, radius, width, life)
	life = life or 0.3
	local u = randomUnit()
	local n = randomUnit()
	n = (n - u * n:Dot(u))
	if n.Magnitude < 1e-3 then n = u:Cross(Vector3.xAxis) end
	n = n.Unit
	local holder = part(cast, "DeathRoarsCrescent", CFrame.new(center), Vector3.one * 0.2, Style.White, 1)
	local base = -n * radius * 0.55
	local k = radius * 1.33
	local a0 = Instance.new("Attachment")
	a0.CFrame = CFrame.fromMatrix(base - u * radius, n, u)
	a0.Parent = holder
	local a1 = Instance.new("Attachment")
	a1.CFrame = CFrame.fromMatrix(base + u * radius, n, u)
	a1.Parent = holder
	local function beam(color, alpha, w, emission)
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = a0, a1
		b.FaceCamera, b.Segments = true, 24
		b.CurveSize0, b.CurveSize1 = k * 0.8, -k * 0.8
		b.Color, b.Transparency = color, alpha
		b.LightEmission, b.LightInfluence, b.Brightness = emission, 0, 3
		b.Width0, b.Width1 = 0, 0
		b.Parent = holder
		tween(b, 0.05, { Width0 = w, Width1 = w, CurveSize0 = k, CurveSize1 = -k }, Enum.EasingStyle.Quart)
		later(cast, 0.05, function()
			tween(b, life, { Width0 = 0, Width1 = 0, CurveSize0 = k * 1.15, CurveSize1 = -k * 1.15 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
		return b
	end
	beam(ColorSequence.new(Style.Yellow), GLOW_ALPHA, width * 3.2, 1)
	beam(CRESCENT_COLOR, CRESCENT_ALPHA, width, 1)
	release(cast, life + 0.1, holder)
end

 
function V.Swarm(cast, center, radius, count, spread)
	spread = spread or 0.22
	local flash = part(cast, "DeathRoarsSwarmFlash", CFrame.new(center), Vector3.one * 1, Style.White, 0.6, Enum.PartType.Ball)
	tween(flash, 0.12, { Size = Vector3.one * radius * 0.9, Transparency = 1 })
	release(cast, 0.18, flash)
	for i = 1, count do
		local delay = (i - 1) / math.max(1, count - 1) * spread
		local function one()
			V.Crescent(cast, center + randomUnit() * rng:NextNumber(0, radius * 0.25), radius * rng:NextNumber(0.7, 1.15), rng:NextNumber(0.35, 0.8), rng:NextNumber(0.22, 0.34))
		end
		if delay <= 0 then one() else later(cast, delay, one) end
	end
	local host = part(cast, "DeathRoarsSparks", CFrame.new(center), Vector3.one * 0.2, Style.Yellow, 1)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(Style.White, Style.Yellow)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NK(0, 0.5), NK(1, 0) })
	e.Transparency = NumberSequence.new({ NK(0, 0), NK(1, 1) })
	e.Lifetime = NumberRange.new(0.2, 0.45)
	e.Speed = NumberRange.new(14, 30)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 4
	e.Rate = 0
	e.Parent = host
	e:Emit(10 + count * 2)
	release(cast, 0.6, host)
end

 
function V.Glint(cast, center, life)
	local ball = part(cast, "DeathRoarsGlint", CFrame.new(center), Vector3.one * 0.3, Style.Yellow, 0.4, Enum.PartType.Ball)
	tween(ball, life, { Size = Vector3.one * 1.6, Transparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for i = 0, 1 do
		local axis = i == 0 and CFrame.Angles(0, 0, 0) or CFrame.Angles(0, 0, math.pi / 2)
		local ray = part(cast, "DeathRoarsGlintRay", CFrame.new(center) * axis, Vector3.new(0.1, 0.4, 0.1), Style.White, 0.3)
		tween(ray, life, { Size = Vector3.new(0.12, 5, 0.12), Transparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		release(cast, life, ray)
	end
	release(cast, life, ball)
end

 
function V.Charge(cast, center, floorY, radius, life)
	local shell = part(cast, "DeathRoarsChargeShell", CFrame.new(center), Vector3.one * radius * 2.6, Style.Yellow, 0.75, Enum.PartType.Ball, Enum.Material.ForceField)
	tween(shell, life, { Size = Vector3.one * radius * 0.5, Transparency = 0.3 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local feet = Vector3.new(center.X, floorY + 0.15, center.Z)
	local ring = part(cast, "DeathRoarsChargeRing", CFrame.new(feet) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.08, radius * 2, radius * 2), Style.Yellow, 0.7, Enum.PartType.Cylinder)
	tween(ring, life, { Transparency = 0.35 }, Enum.EasingStyle.Linear)
	later(cast, life * 0.8, function() ring.Color = Style.White end)
	V.Glint(cast, center, life)
	release(cast, life, shell)
	release(cast, life, ring)
end

 
function V.Aura(cast, actor)
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not root then return function() end end
	local holder = Instance.new("Attachment")
	holder.Name = "DeathRoarsAura"
	holder.Parent = root
	cast:Add(holder)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(Style.White, Style.Gold)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NK(0, 0.8), NK(1, 0) })
	e.Transparency = NumberSequence.new({ NK(0, 0.1), NK(1, 1) })
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(3, 9)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 45
	e.Parent = holder
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = Style.Yellow, 2.5, 22, false
	light.Parent = holder
	return function()
		if holder.Parent then
			e.Enabled, light.Enabled = false, false
			e:Clear()
		end
	end
end

function V.Finish(cast, center, bounds)
	local radius = math.sqrt(bounds.HalfX ^ 2 + bounds.HalfZ ^ 2) + 4
	local duration = Style.Finish.Duration
	local rings = {}
	for index = 1, Style.Finish.Rings do
		local holder = part(cast, "DeathRoarsFinishRing", CFrame.new(center + Vector3.new(0, 0.2 + index * 0.12, 0)), Vector3.one * 0.2, Style.Gold, 1)
		local points, beams = {}, {}
		for i = 1, Style.Finish.RingSegments do
			local attachment = Instance.new("Attachment")
			attachment.Parent = holder
			points[i] = attachment
		end
		for i = 1, #points do
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = points[i], points[i % #points + 1]
			beam.FaceCamera, beam.Segments = true, 1
			beam.Width0, beam.Width1 = 3, 3
			beam.Color = ColorSequence.new(index == 1 and Style.White or Style.Yellow)
			beam.LightEmission, beam.LightInfluence, beam.Brightness = 1, 0, 5
			beam.Parent = holder
			beams[i] = beam
		end
		rings[index] = { Points = points, Beams = beams }
	end
	local shell = part(cast, "DeathRoarsFinishNova", CFrame.new(center), Vector3.one * 8, Style.Yellow, 0.65, Enum.PartType.Ball, Enum.Material.ForceField)
	tween(shell, duration, { Size = Vector3.one * radius * 2, Transparency = 1 }, Enum.EasingStyle.Quart)
	local pillar = part(cast, "DeathRoarsFinishPillar", CFrame.new(center + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(80, 2, 2), Style.White, 0.15, Enum.PartType.Cylinder)
	tween(pillar, duration, { Size = Vector3.new(100, 16, 16), Transparency = 1 }, Enum.EasingStyle.Quart)
	for i = 1, 24 do
		local angle = i / 24 * math.pi * 2
		local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
		V.Streak(cast, center + out * 4 + Vector3.new(0, 2, 0), center + out * radius + Vector3.new(0, 5, 0), 1.2)
	end
	local born = cast:Now()
	cast:Step(function(_, now)
		local progress = math.clamp((now - born) / duration, 0, 1)
		for index, ring in ipairs(rings) do
			local t = math.clamp(progress * 1.2 - (index - 1) * 0.12, 0, 1)
			local reach = 4 + radius * (1 - (1 - t) ^ 3)
			for i, point in ipairs(ring.Points) do
				local angle = (i - 1) / #ring.Points * math.pi * 2
				point.Position = Vector3.new(math.cos(angle) * reach, 0, math.sin(angle) * reach)
			end
			for _, beam in ipairs(ring.Beams) do
				beam.Transparency = NumberSequence.new(progress ^ 2)
				beam.Width0, beam.Width1 = 3.5 * (1 - progress) + 0.1, 3.5 * (1 - progress) + 0.1
			end
		end
		return progress < 1
	end)
	return radius
end

 
function V.Gather(cast, tip, duration, count)
	count = count or 40
	local born = cast:Now()
	local orb = part(cast, "DeathRoarsGatherOrb", CFrame.new(tip()), Vector3.one * 0.4, Style.White, 0.05, Enum.PartType.Ball)
	local halo = part(cast, "DeathRoarsGatherHalo", CFrame.new(tip()), Vector3.one, Style.Yellow, 0.65, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = Style.Yellow, 0, 32, false
	light.Parent = orb
	cast:Step(function(_, now)
		if not orb.Parent then return false end
		local t = math.clamp((now - born) / duration, 0, 1)
		local at = tip()
		orb.CFrame = CFrame.new(at)
		orb.Size = Vector3.one * (0.4 + 2.4 * t ^ 1.5)
		halo.CFrame = CFrame.new(at)
		halo.Size = Vector3.one * (1 + 7 * t ^ 1.5) * (1 + 0.1 * math.sin(now * 45))
		light.Brightness = 7 * t
		return t < 1
	end)
	for i = 1, count do
		later(cast, (i - 1) / count * duration * 0.8, function()
			local target = tip()
			local from = target + randomUnit() * rng:NextNumber(22, 48)
			local length = rng:NextNumber(5, 15)
			local thread = part(cast, "DeathRoarsThread", CFrame.lookAt(from, target), Vector3.new(0.14, 0.14, length), rng:NextNumber() < 0.5 and Style.Yellow or Style.White, 0.15)
			local travel = rng:NextNumber(0.3, 0.55)
			tween(thread, travel, { CFrame = CFrame.lookAt(target, target + (target - from).Unit), Size = Vector3.new(0.04, 0.04, length * 0.2), Transparency = 0.9 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			release(cast, travel + 0.02, thread)
		end)
	end
	release(cast, duration + 0.05, orb)
	release(cast, duration + 0.05, halo)
end

 
function V.Highlight(cast, actor, fill)
	local h = Instance.new("Highlight")
	h.Name = "DeathRoarsHighlight"
	h.FillColor, h.OutlineColor = Style.Gold, Style.Yellow
	h.FillTransparency, h.OutlineTransparency = 1, 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = actor
	h.Parent = actor
	cast:Add(h)
	tween(h, 0.4, { FillTransparency = fill or 0.75, OutlineTransparency = 0 })
	return function(time)
		if h.Parent then tween(h, time or 0.4, { FillTransparency = 1, OutlineTransparency = 1 }) end
	end
end

 
function V.Shockwave(cast, center, radius, duration, color, width)
	local holder = part(cast, "DeathRoarsShockwave", CFrame.new(center), Vector3.one * 0.2, color, 1)
	local segments = 48
	local points, beams = {}, {}
	for i = 1, segments do
		local a = Instance.new("Attachment")
		a.Parent = holder
		points[i] = a
	end
	for i = 1, segments do
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = points[i], points[i % segments + 1]
		b.FaceCamera, b.Segments = true, 1
		b.Color = ColorSequence.new(color)
		b.LightEmission, b.LightInfluence, b.Brightness = 1, 0, 5
		b.Parent = holder
		beams[i] = b
	end
	local born = cast:Now()
	cast:Step(function(_, now)
		if not holder.Parent then return false end
		local t = math.clamp((now - born) / duration, 0, 1)
		local reach = 1 + radius * (1 - (1 - t) ^ 3)
		for i, p in ipairs(points) do
			local a = (i - 1) / segments * math.pi * 2
			p.Position = Vector3.new(math.cos(a) * reach, 0, math.sin(a) * reach)
		end
		local w = width * (1 - t) + 0.05
		for _, b in ipairs(beams) do b.Width0, b.Width1 = w, w end
		return t < 1
	end)
	release(cast, duration + 0.05, holder)
end

 
function V.Ignite(cast, tip, floorCenter, radius)
	local height = 600
	local frame = CFrame.new(tip + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	local pillar = part(cast, "DeathRoarsPillar", frame, Vector3.new(height, 1, 1), Style.White, 0, Enum.PartType.Cylinder)
	local sheath = part(cast, "DeathRoarsPillarGlow", frame, Vector3.new(height, 3, 3), Style.Yellow, 0.5, Enum.PartType.Cylinder)
	tween(pillar, 0.12, { Size = Vector3.new(height, 9, 9) }, Enum.EasingStyle.Quart)
	tween(sheath, 0.12, { Size = Vector3.new(height, 24, 24) }, Enum.EasingStyle.Quart)
	later(cast, 0.15, function()
		tween(pillar, 0.9, { Size = Vector3.new(height, 0.2, 0.2), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(sheath, 1.1, { Size = Vector3.new(height, 0.5, 0.5), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	release(cast, 1.3, pillar)
	release(cast, 1.3, sheath)
	local ground = Vector3.new(floorCenter.X, floorCenter.Y + 0.3, floorCenter.Z)
	V.Shockwave(cast, ground, radius, 0.7, Style.White, 3)
	later(cast, 0.08, function() V.Shockwave(cast, ground + Vector3.new(0, 0.2, 0), radius * 0.8, 0.9, Style.Yellow, 5) end)
	later(cast, 0.18, function() V.Shockwave(cast, ground + Vector3.new(0, 0.4, 0), radius * 0.6, 1.1, Style.Gold, 7) end)
	local flash = part(cast, "DeathRoarsIgniteFlash", CFrame.new(tip), Vector3.one * 2, Style.White, 0, Enum.PartType.Ball)
	tween(flash, 0.25, { Size = Vector3.one * 44, Transparency = 1 })
	release(cast, 0.3, flash)
	local host = part(cast, "DeathRoarsIgniteDust", CFrame.new(ground + Vector3.new(0, 1, 0)), Vector3.one * 0.2, Style.Gold, 1)
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(255, 228, 170), Color3.fromRGB(140, 112, 76))
	dust.Size = NumberSequence.new({ NK(0, 4), NK(1, 13) })
	dust.Transparency = NumberSequence.new({ NK(0, 0.45), NK(1, 1) })
	dust.Lifetime = NumberRange.new(0.8, 1.4)
	dust.Speed = NumberRange.new(40, 85)
	dust.SpreadAngle = Vector2.new(90, 90)
	dust.Drag = 3
	dust.Rate = 0
	dust.Parent = host
	dust:Emit(40)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = SPARK
	sparks.Color = ColorSequence.new(Style.White, Style.Gold)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NK(0, 0.9), NK(1, 0) })
	sparks.Transparency = NumberSequence.new({ NK(0, 0), NK(1, 1) })
	sparks.Lifetime = NumberRange.new(0.6, 1.2)
	sparks.Speed = NumberRange.new(40, 95)
	sparks.SpreadAngle = Vector2.new(90, 90)
	sparks.Drag = 2
	sparks.Rate = 0
	sparks.Parent = host
	sparks:Emit(90)
	release(cast, 2, host)
end

 
function V.FinaleCut(cast, center, bounds)
	local hx, hz = bounds.HalfX, bounds.HalfZ
	local y = center.Y + 5
	for _, corner in ipairs({ Vector3.new(hx, 0, hz), Vector3.new(hx, 0, -hz) }) do
		local a = bounds.Frame:PointToWorldSpace(-corner * 1.15)
		local b = bounds.Frame:PointToWorldSpace(corner * 1.15)
		a, b = Vector3.new(a.X, y, a.Z), Vector3.new(b.X, y, b.Z)
		V.Streak(cast, a, b, 2.6)
		V.Streak(cast, a + Vector3.new(0, 2, 0), b + Vector3.new(0, 2, 0), 0.7)
	end
	V.Shockwave(cast, center + Vector3.new(0, 0.5, 0), math.sqrt(hx * hx + hz * hz) * 1.1, 0.9, Style.White, 6)
	 
	local host = Effects.AcquirePart()
	host.Name = "DeathRoarsEmbers"
	host.CFrame = bounds.Frame.Rotation + (center + Vector3.new(0, 45, 0))
	host.Size = Vector3.new(math.min(hx * 2, 2000), 1, math.min(hz * 2, 2000))
	host.Transparency = 1
	host.Parent = Runtime.Effects
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new({ CK(0, Style.White), CK(0.4, Style.Yellow), CK(1, Style.Gold) })
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NK(0, 0.7), NK(0.7, 0.4), NK(1, 0) })
	e.Transparency = NumberSequence.new({ NK(0, 0), NK(0.8, 0.2), NK(1, 1) })
	e.Lifetime = NumberRange.new(2, 3.5)
	e.Speed = NumberRange.new(2, 6)
	e.Acceleration = Vector3.new(0, -10, 0)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(25, 25)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Rate = 0
	e.Parent = host
	e:Emit(math.clamp(math.floor(hx * hz / 25), 150, 450))
	Effects.ReleaseAfter(host, 4)
end

 
 
 
function V.GiantBlade(cast, root, tip, length, grow, floorY)
	local up = Vector3.yAxis
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z)
	forward = forward.Magnitude > 1e-3 and forward.Unit or Vector3.zAxis
	local width = 4.5
	local core = part(cast, "DeathRoarsGiantBlade", CFrame.new(tip()), Vector3.new(0.8, width, 0.1), Style.White, 0)
	local glow = part(cast, "DeathRoarsGiantBladeGlow", CFrame.new(tip()), Vector3.new(2.6, width * 2.4, 0.1), Style.Yellow, 0.55)
	local edge = part(cast, "DeathRoarsGiantBladeEdge", CFrame.new(tip()), Vector3.new(0.3, 0.6, 0.1), Style.Gold, 0.1)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(Style.White, Style.Gold)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NK(0, 1.2), NK(1, 0) })
	e.Transparency = NumberSequence.new({ NK(0, 0), NK(1, 1) })
	e.Lifetime = NumberRange.new(0.4, 0.9)
	e.Speed = NumberRange.new(4, 14)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 160
	e.Parent = core
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = Style.Yellow, 6, 60, false
	light.Parent = core
	local angle, reach, pivot, sweeping = 0, 0, nil, false
	local function place()
		local base = pivot or tip()
		local dir = up * math.cos(angle) + forward * math.sin(angle)
		local normal = up * -math.sin(angle) + forward * math.cos(angle)
		local length = math.max(reach, 0.1)
		local center = base + dir * (length / 2)
		local frame = CFrame.lookAt(center, center + dir, normal)
		core.CFrame, core.Size = frame, Vector3.new(0.8, width, length)
		glow.CFrame, glow.Size = frame, Vector3.new(2.6, width * 2.4, length * 1.02)
		edge.CFrame, edge.Size = frame * CFrame.new(0, width * 0.55, 0), Vector3.new(0.35, 0.7, length)
		return base, dir, frame
	end
	local born = cast:Now()
	cast:Step(function(_, now)
		if not core.Parent or sweeping then return false end
		local t = math.clamp((now - born) / grow, 0, 1)
		reach = length * (1 - (1 - t) ^ 3)
		place()
		return true
	end)
	local handle = {}
	function handle.Sweep(duration, onSweep)
		sweeping = true
		pivot = tip()
		local finalAngle = math.rad(100)
		local start = cast:Now()
		local strike
		local previousAngle = 0
		cast:Step(function(_, now)
			if not core.Parent then return false end
			local t = math.clamp((now - start) / duration, 0, 1)
			angle = finalAngle * t * t
			 
			if onSweep then
				local samples = math.max(1, math.ceil(math.abs(angle - previousAngle) / 0.02))
				for i = 1, samples do
					local sampleAngle = previousAngle + (angle - previousAngle) * i / samples
					local dir = up * math.cos(sampleAngle) + forward * math.sin(sampleAngle)
					local normal = up * -math.sin(sampleAngle) + forward * math.cos(sampleAngle)
					local middle = pivot + dir * reach * 0.5
					onSweep(CFrame.lookAt(middle, middle + dir, normal), Vector3.new(0.8, width, reach))
				end
			end
			previousAngle = angle
			local _, _, frame = place()
			 
			local ghost = part(cast, "DeathRoarsGiantBladeGhost", frame, Vector3.new(1.4, width * 2, reach), Style.Yellow, 0.35)
			tween(ghost, 0.35, { Transparency = 1, Size = Vector3.new(0.2, width * 0.5, reach) })
			release(cast, 0.37, ghost)
			return t < 1
		end)
		local base = pivot
		local dir = up * math.cos(finalAngle) + forward * math.sin(finalAngle)
		strike = base + dir * reach
		strike = Vector3.new(strike.X, floorY, strike.Z)
		 
		later(cast, duration + 0.03, function()
			e.Enabled = false
			tween(core, 0.4, { Size = Vector3.new(0.05, width * 3, reach), Transparency = 1 })
			tween(glow, 0.5, { Size = Vector3.new(0.1, width * 6, reach * 1.05), Transparency = 1 })
			tween(edge, 0.3, { Transparency = 1 })
			tween(light, 0.5, { Brightness = 0 })
		end)
		release(cast, duration + 0.6, core)
		release(cast, duration + 0.6, glow)
		release(cast, duration + 0.6, edge)
		return strike, forward
	end
	return handle
end

 
function V.Scar(cast, from, direction, floorY, length)
	local a = Vector3.new(from.X, floorY + 0.15, from.Z) - direction * length * 0.5
	local b = a + direction * length
	local mid = (a + b) / 2
	local frame = CFrame.lookAt(mid, mid + direction)
	local scar = part(cast, "DeathRoarsScar", frame, Vector3.new(5, 0.2, length), Style.White, 0)
	local burn = part(cast, "DeathRoarsScarBurn", frame + Vector3.new(0, 0.05, 0), Vector3.new(12, 0.15, length), Style.Gold, 0.4)
	tween(scar, 2.6, { Size = Vector3.new(1, 0.2, length), Color = Style.Gold, Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(burn, 1.6, { Size = Vector3.new(2, 0.15, length), Transparency = 1 })
	release(cast, 2.7, scar)
	release(cast, 1.7, burn)
	local count = math.clamp(math.floor(length / 14), 6, 24)
	for i = 0, count do
		local at = a + direction * (length * i / count)
		later(cast, i / count * 0.35, function()
			local height = rng:NextNumber(30, 70)
			local pillar = part(cast, "DeathRoarsScarPillar", CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				Vector3.new(height, 0.5, 0.5), Style.White, 0, Enum.PartType.Cylinder)
			tween(pillar, 0.08, { Size = Vector3.new(height, 4, 4) }, Enum.EasingStyle.Quart)
			later(cast, 0.08, function()
				tween(pillar, 0.45, { Size = Vector3.new(height * 1.2, 0.1, 0.1), Transparency = 1, Color = Style.Gold }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
			release(cast, 0.6, pillar)
		end)
	end
end

for _, name in ipairs({ "Streak", "Crescent", "Swarm", "Glint", "Charge", "Finish", "Gather", "Highlight", "Shockwave", "Ignite", "FinaleCut", "GiantBlade", "Scar" }) do
	local fn = V[name]
	V[name] = function(...)
		local ok, result = pcall(fn, ...)
		if not ok then warn("[DeathRoars VFX] " .. name .. " failed: " .. tostring(result)) return nil end
		return result
	end
end
return V

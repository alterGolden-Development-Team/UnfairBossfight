 
 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Effects = require(BossSystem.Combat.EffectService)

local FX = {}
FX.SPARK = "rbxasset://textures/particles/sparkles_main.dds"
FX.SMOKE = "rbxasset://textures/particles/smoke_main.dds"
FX.FIRE = "rbxasset://textures/particles/fire_main.dds"
FX.WHITE = Color3.fromRGB(255, 250, 232)

local function seq(...)
	local values = { ... }
	if #values == 1 then
		return NumberSequence.new(values[1])
	end
	local keys = table.create(#values)
	for i, v in ipairs(values) do
		keys[i] = NumberSequenceKeypoint.new((i - 1) / (#values - 1), v)
	end
	return NumberSequence.new(keys)
end
local function grad(...)
	local values = { ... }
	if #values == 1 then
		return ColorSequence.new(values[1])
	end
	local keys = table.create(#values)
	for i, v in ipairs(values) do
		keys[i] = ColorSequenceKeypoint.new((i - 1) / (#values - 1), v)
	end
	return ColorSequence.new(keys)
end
FX.Seq, FX.Grad = seq, grad

function FX.Release(cast, part)
	if part and cast.objects[part] then
		Effects.Release(part)
		cast.objects[part] = nil
	end
end

function FX.Tween(object, time, goal, style, direction)
	local t = Effects:Create(
		object,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	t:Play()
	return t
end

 
function FX.Temp(ctx, cast, name, frame, size, color, alpha, life)
	local p = ctx.Part(cast, name, frame, size, color, alpha)
	p.Material = Enum.Material.Neon
	if life then
		cast:Schedule(life, function()
			FX.Release(cast, p)
		end)
	end
	return p
end

function FX.Anchor(ctx, cast, frame, life)
	local p = FX.Temp(ctx, cast, "ShieldFXAnchor", typeof(frame) == "Vector3" and CFrame.new(frame) or frame,
		Vector3.one * 0.2, FX.WHITE, 1, life)
	return p
end

function FX.Emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = FX.SPARK
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Rate = 0
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = parent
	return e
end

 
 
 
function FX.Shake(ctx, origin, radius, duration, intensity)
	local core = ctx.Core
	if core and core.ScreenEffect then
		core.ScreenEffect("Shake", { Origin = origin, Radius = radius, Duration = duration, Intensity = intensity })
	end
end
function FX.Tint(ctx, origin, color, intensity, duration, radius)
	local core = ctx.Core
	if core and core.ScreenEffect then
		core.ScreenEffect("ImpactTint", {
			Origin = origin,
			Radius = radius or 140,
			Color = color,
			Intensity = intensity or 0.5,
			Duration = duration or 0.22,
		})
	end
end

 
 
 
 
local function keyed(...)
	local k = {}
	for _, p in ipairs({ ... }) do
		table.insert(k, NumberSequenceKeypoint.new(p[1], math.clamp(p[2], 0, 1)))
	end
	return NumberSequence.new(k)
end
FX.Keyed = keyed

 
 
local function curvedRing(host, plane, arcs)
	arcs = arcs or 4
	local atts, beams = {}, {}
	for i = 1, arcs do
		local a = Instance.new("Attachment")
		a.Parent = host
		atts[i] = a
	end
	for i = 1, arcs do
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = atts[i], atts[i % arcs + 1]
		b.FaceCamera, b.Segments, b.LightEmission, b.LightInfluence = true, 14, 1, 0
		b.Parent = host
		beams[i] = b
	end
	local span = math.pi * 2 / arcs
	return function(r, w, alpha, color)
		for i, a in ipairs(atts) do
			local ang = (i - 1) * span
			local c, s = math.cos(ang), math.sin(ang)
			if plane == "XZ" then
				a.CFrame = CFrame.fromMatrix(Vector3.new(c * r, 0, s * r), Vector3.new(-s, 0, c), Vector3.yAxis)
			else
				a.CFrame = CFrame.fromMatrix(Vector3.new(c * r, s * r, 0), Vector3.new(-s, c, 0), Vector3.zAxis)
			end
		end
		local curve = 4 / 3 * math.tan(span / 4) * r
		local t = typeof(alpha) == "NumberSequence" and alpha or NumberSequence.new(math.clamp(alpha, 0, 1))
		for _, b in ipairs(beams) do
			b.CurveSize0, b.CurveSize1 = curve, curve
			b.Width0, b.Width1 = w, w
			b.Transparency = t
			if color then
				b.Color = color
			end
		end
	end
end
FX.CurvedRing = curvedRing

 
local function glowSprite(ctx, cast, position, color, size, life, alpha)
	size = math.min(size, 14)  
	local host = FX.Anchor(ctx, cast, position, life + 0.2)
	FX.Emitter(host, {
		Color = grad(FX.WHITE, color),
		Size = keyed({ 0, size * 0.6 }, { 0.25, size }, { 1, size * 1.1 }),
		Transparency = keyed({ 0, math.max(alpha or 0.15, 0.3) }, { 1, 1 }),
		Lifetime = NumberRange.new(life),
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(0, 360),
	}):Emit(1)
	return host
end
FX.GlowSprite = glowSprite

 
function FX.Flash(ctx, cast, position, color, scale, duration, alpha)
	duration = duration or 0.25
	local ball = FX.Temp(ctx, cast, "ShieldFXFlash", CFrame.new(position), Vector3.one * scale * 0.2, color,
		math.max(alpha or 0.05, 0.2), duration + 0.05)
	ball.Shape = Enum.PartType.Ball
	FX.Tween(ball, duration * 0.8, { Size = Vector3.one * scale * 0.8, Transparency = 1 }, Enum.EasingStyle.Quint)
	glowSprite(ctx, cast, position, color, scale * 1.1, duration * 1.4, alpha)
	return ball
end

 
 
function FX.Shockwave(ctx, cast, frame, from, to, duration, color, alpha, thickness)
	frame = typeof(frame) == "Vector3" and CFrame.new(frame) or frame
	local host = FX.Temp(ctx, cast, "ShieldFXShockwave", frame, Vector3.one * 0.2, color, 1, duration + 0.1)
	local set = curvedRing(host, "XZ")
	local hot = color:Lerp(FX.WHITE, 0.35)
	local disc = FX.Temp(ctx, cast, "ShieldFXShockwaveDisc", frame * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.05, from, from), color, 0.8, duration + 0.05)
	disc.Shape = Enum.PartType.Cylinder
	FX.Tween(disc, duration, { Size = Vector3.new(0.05, to * 0.9, to * 0.9), Transparency = 1 })
	local born = cast:Now()
	local base = math.max(0.35, to * 0.035)
	cast:Step(function(_, now)
		if not host.Parent then
			return false
		end
		local t = math.clamp((now - born) / duration, 0, 1)
		local e = 1 - (1 - t) ^ 3
		set((from + (to - from) * e) * 0.5, base * (1.4 - t), (alpha or 0) + (1 - (alpha or 0)) * t ^ 1.5, ColorSequence.new(hot, color))
		return t < 1
	end)
	return host
end

 
function FX.Ring(ctx, cast, frame, from, to, duration, color, alpha, width, count)
	frame = typeof(frame) == "Vector3" and CFrame.new(frame) * CFrame.Angles(math.pi / 2, 0, 0) or frame
	local anchor = FX.Temp(ctx, cast, "ShieldFXRing", frame, Vector3.one * 0.2, color, 1, duration + 0.05)
	local set = curvedRing(anchor, "XY")
	local seqColor = ColorSequence.new(color)
	set(from * 0.5, width, alpha or 0, seqColor)
	local born = cast:Now()
	cast:Step(function(_, now)
		if not anchor.Parent then
			return false
		end
		local t = math.clamp((now - born) / duration, 0, 1)
		local eased = 1 - (1 - t) ^ 3
		set((from + (to - from) * eased) * 0.5, width * (1 - t * 0.7), (alpha or 0) + (1 - (alpha or 0)) * t * t)
		return t < 1
	end)
	return anchor
end

function FX.Light(ctx, cast, position, color, brightness, range, duration)
	local anchor = FX.Anchor(ctx, cast, position, duration + 0.05)
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = color, brightness, range, false
	light.Parent = anchor
	FX.Tween(light, duration, { Brightness = 0 })
	return light
end

function FX.Sparks(ctx, cast, position, color, glow, count, speedMin, speedMax, size)
	local anchor = FX.Anchor(ctx, cast, position, 1.2)
	FX.Emitter(anchor, {
		Color = grad(glow or FX.WHITE, color),
		Size = seq((size or 0.5), (size or 0.5) * 0.6, 0),
		Transparency = seq(0, 0.15, 1),
		Lifetime = NumberRange.new(0.3, 0.8),
		Speed = NumberRange.new(speedMin or 12, speedMax or 34),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -35, 0),
		Drag = 2.5,
		Rotation = NumberRange.new(0, 360),
	}):Emit(count or 20)
	return anchor
end

 
function FX.Streaks(ctx, cast, position, direction, color, glow, count, spread, speedMin, speedMax, length)
	direction = direction and direction.Magnitude > 0.01 and direction.Unit or Vector3.yAxis
	local up = math.abs(direction.Y) > 0.98 and Vector3.xAxis or Vector3.yAxis
	local anchor = FX.Anchor(ctx, cast, CFrame.lookAt(position, position + direction, up), 0.9)
	local size = math.clamp((length or 2.4) * 0.22, 0.25, 1)
	FX.Emitter(anchor, {
		Color = grad(glow or FX.WHITE, color),
		Size = keyed({ 0, size }, { 0.4, size * 0.7 }, { 1, 0 }),
		Transparency = keyed({ 0, 0 }, { 0.7, 0.2 }, { 1, 1 }),
		Lifetime = NumberRange.new(0.25, 0.6),
		Speed = NumberRange.new((speedMin or 40) * 0.6, (speedMax or 80) * 0.6),
		SpreadAngle = Vector2.new(spread or 35, spread or 35),
		EmissionDirection = Enum.NormalId.Front,
		Drag = 5,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-200, 200),
	}):Emit(count or 16)
	return anchor
end

function FX.Smoke(ctx, cast, position, color, size, count, speed, rise)
	local anchor = FX.Anchor(ctx, cast, position, 2.2)
	FX.Emitter(anchor, {
		Texture = FX.SMOKE,
		LightEmission = 0,
		LightInfluence = 1,
		Color = ColorSequence.new(color),
		Size = seq(size * 0.4, size),
		Transparency = seq(0.45, 0.7, 1),
		Lifetime = NumberRange.new(0.8, 1.6),
		Speed = NumberRange.new((speed or 14) * 0.4, speed or 14),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, rise or 3, 0),
		Drag = 2.2,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-50, 50),
	}):Emit(count or 8)
	return anchor
end

 
function FX.Glint(ctx, cast, position, color, size, duration, facing)
	duration = duration or 0.3
	local host = FX.Anchor(ctx, cast, position, duration + 0.2)
	for i, tint in ipairs({ FX.WHITE, color }) do
		FX.Emitter(host, {
			Color = ColorSequence.new(tint),
			Size = keyed({ 0, size * 0.2 }, { 0.25, size * (i == 1 and 1 or 1.4) }, { 1, 0 }),
			Transparency = keyed({ 0, 0 }, { 0.6, 0.1 }, { 1, 1 }),
			Lifetime = NumberRange.new(duration),
			Speed = NumberRange.new(0),
			Rotation = NumberRange.new(i == 1 and 0 or 45),
			RotSpeed = NumberRange.new(i == 1 and 90 or -60),
		}):Emit(1)
	end
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = color, 4, size * 2.5, false
	light.Parent = host
	FX.Tween(light, duration, { Brightness = 0 })
end

 
function FX.Bolt(ctx, cast, from, to, color, core, width, jitter, segments, duration, flicker)
	segments = segments or 7
	duration = duration or 0.22
	local delta = to - from
	local len = delta.Magnitude
	if len < 0.05 then
		return {}
	end
	jitter = jitter or len * 0.12
	local dir = delta.Unit
	local side = dir:Cross(math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis).Unit
	local up = side:Cross(dir).Unit
	local points = { from }
	for i = 1, segments - 1 do
		local t = i / segments
		local falloff = math.sin(t * math.pi)
		local offset = (side * (math.random() * 2 - 1) + up * (math.random() * 2 - 1)) * jitter * falloff
		points[i + 1] = from + delta * t + offset
	end
	points[#points + 1] = to
	local parts = {}
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local m = (b - a).Magnitude
		if m > 0.01 then
			local frame = CFrame.lookAt((a + b) / 2, b)
			local glow = FX.Temp(ctx, cast, "ShieldFXBoltGlow", frame, Vector3.new(width * 2.4, width * 2.4, m + width),
				color, 0.55, duration + 0.05)
			local hot = FX.Temp(ctx, cast, "ShieldFXBolt", frame, Vector3.new(width, width, m + width * 0.5),
				core or FX.WHITE, 0, duration + 0.05)
			FX.Tween(glow, duration, { Transparency = 1, Size = Vector3.new(width * 0.6, width * 0.6, m) })
			FX.Tween(hot, duration, { Transparency = 1, Size = Vector3.new(width * 0.15, width * 0.15, m) })
			table.insert(parts, glow)
			table.insert(parts, hot)
		end
	end
	if flicker then
		 
		cast:Schedule(duration * 0.35, function()
			FX.Bolt(ctx, cast, from, to, color, core, width * 0.7, jitter, segments, duration * 0.6, false)
		end)
	end
	return parts, points
end

 
function FX.ForkedBolt(ctx, cast, from, to, color, core, width, duration, forks)
	local _, points = FX.Bolt(ctx, cast, from, to, color, core, width, nil, 8, duration, true)
	if not points then
		return
	end
	local len = (to - from).Magnitude
	for _ = 1, forks or 3 do
		local i = math.random(2, math.max(2, #points - 1))
		local start = points[i]
		if start then
			local dir = ((to - from).Unit + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 1.6).Unit
			FX.Bolt(ctx, cast, start, start + dir * len * (0.15 + math.random() * 0.2), color, core, width * 0.5, nil, 4,
				duration * 0.8, true)
		end
	end
end

 
 
 
function FX.Crescent(ctx, cast, frame, radius, arc, thickness, color, core, duration, options)
	options = options or {}
	core = core or FX.WHITE
	local wipe = options.Wipe or 0.07
	local grow = options.Grow or 1.18
	local life = wipe + duration + 0.1
	local anchor = FX.Temp(ctx, cast, "ShieldFXSlash", frame, Vector3.one * 0.2, color, 1, life)
	local pieces = math.max(1, math.ceil(arc / math.rad(175)))
	local atts = {}
	for i = 0, pieces do
		local a = Instance.new("Attachment")
		a.Parent = anchor
		atts[i] = a
	end
	local hot = color:Lerp(core, 0.45)
	local layers = {
		{ Color = ColorSequence.new(color:Lerp(Color3.new(), 0.12), color), Width = thickness * 2.1, Base = 0.55, Emission = 0.85 },
		{ Color = ColorSequence.new(color, hot), Width = thickness, Base = 0.05, Emission = 1 },
		{ Color = ColorSequence.new(core), Width = thickness * 0.32, Base = 0, Emission = 1 },
	}
	local beams = {}
	for _, L in ipairs(layers) do
		for i = 1, pieces do
			local b = Instance.new("Beam")
			b.Attachment0, b.Attachment1 = atts[i - 1], atts[i]
			b.FaceCamera, b.Segments, b.LightEmission, b.LightInfluence = true, 30, L.Emission, 0
			b.Color = L.Color
			b.Transparency = NumberSequence.new(1)
			b.Parent = anchor
			table.insert(beams, { Beam = b, L = L, Index = i })
		end
	end
	 
	local shed = FX.Emitter(atts[pieces], {
		Color = grad(FX.WHITE, color),
		Size = keyed({ 0, thickness * 0.22 }, { 1, 0 }),
		Transparency = keyed({ 0, 0 }, { 1, 1 }),
		Lifetime = NumberRange.new(0.25, 0.5),
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
		Rate = 90,
	})
	local startA, endA = -arc / 2, arc / 2
	if options.Reverse then
		startA, endA = endA, startA
	end
	local sign = endA > startA and 1 or -1
	local function place(a, ang, r)
		a.CFrame = CFrame.fromMatrix(Vector3.new(math.sin(ang) * r, 0, -math.cos(ang) * r),
			Vector3.new(math.cos(ang), 0, math.sin(ang)) * sign, Vector3.yAxis)
	end
	local function transparency(index, a)
		local soft = math.min(1, a + 0.7)
		if pieces == 1 then
			return keyed({ 0, 1 }, { 0.3, a }, { 0.88, a }, { 1, soft })
		elseif index == 1 then
			return keyed({ 0, 1 }, { 0.6, a }, { 1, a })
		elseif index == pieces then
			return keyed({ 0, a }, { 0.8, a }, { 1, soft })
		end
		return NumberSequence.new(a)
	end
	local born = cast:Now()
	cast:Step(function(_, now)
		if not anchor.Parent then
			return false
		end
		local t = now - born
		local reveal = 1 - (1 - math.clamp(t / math.max(wipe, 0.001), 0, 1)) ^ 2
		local fade = math.clamp((t - wipe) / duration, 0, 1)
		local r = radius * (1 + (grow - 1) * (1 - (1 - math.clamp(t / (wipe + duration), 0, 1)) ^ 2))
		local tipA = startA + (endA - startA) * math.max(reveal, 0.02)
		local tailA = startA + (endA - startA) * (0.55 * fade ^ 1.5)
		local span = tipA - tailA
		for i = 0, pieces do
			place(atts[i], tailA + span * i / pieces, r)
		end
		local curve = 4 / 3 * math.tan(math.abs(span) / pieces / 4) * r
		local thin = 1 - 0.65 * fade
		for _, e in ipairs(beams) do
			local b, L = e.Beam, e.L
			local u0, u1 = (e.Index - 1) / pieces, e.Index / pieces
			b.CurveSize0, b.CurveSize1 = curve, curve
			b.Width0 = L.Width * thin * (0.06 + 0.94 * u0 ^ 0.8)
			b.Width1 = L.Width * thin * (0.06 + 0.94 * u1 ^ 0.8)
			b.Transparency = transparency(e.Index, L.Base + (1 - L.Base) * fade ^ 1.2)
		end
		shed.Rate = reveal < 1 and 90 or 0
		return t < wipe + duration
	end)
	return anchor
end

 
 
function FX.Spikes(ctx, cast, center, count, radius, height, color, core, duration, tilt)
	duration = duration or 0.6
	core = core or FX.WHITE
	local life = duration + 0.5
	local host = FX.Anchor(ctx, cast, center + Vector3.new(0, 0.1, 0), life)
	local bottom, top = Instance.new("Attachment"), Instance.new("Attachment")
	bottom.Parent, top.Parent = host, host
	top.Position = Vector3.new(0, 0.1, 0)
	local rays = {}
	for _, spec in ipairs({
		{ radius * 1.5, ColorSequence.new(color:Lerp(Color3.new(), 0.1), color), 0.35, 0.85 },
		{ radius * 0.65, ColorSequence.new(color, core), 0.05, 1 },
		{ radius * 0.2, ColorSequence.new(core), 0, 1 },
	}) do
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = bottom, top
		b.FaceCamera, b.Segments, b.LightEmission, b.LightInfluence = true, 6, spec[4], 0
		b.Color = spec[2]
		b.Width0, b.Width1 = spec[1], spec[1] * 0.8
		b.Parent = host
		table.insert(rays, { b, spec[1], spec[3] })
	end
	local setRing = curvedRing(host, "XZ")
	glowSprite(ctx, cast, center + Vector3.new(0, 0.6, 0), color, radius * 3, duration * 1.2, 0.3)
	FX.Emitter(host, {
		Color = grad(core, color),
		Size = keyed({ 0, 0.45 }, { 1, 0 }),
		Transparency = keyed({ 0, 0 }, { 0.7, 0.2 }, { 1, 1 }),
		Lifetime = NumberRange.new(0.8, 1.5),
		Speed = NumberRange.new(height * 0.3, height * 0.8),
		SpreadAngle = Vector2.new(22, 22),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, 2, 0),
		Drag = 1.5,
		Rotation = NumberRange.new(0, 360),
	}):Emit(math.clamp((count or 6) * 5, 12, 60))
	local born = cast:Now()
	cast:Step(function(_, now)
		if not host.Parent then
			return false
		end
		local t = now - born
		local rise = 1 - (1 - math.clamp(t / 0.12, 0, 1)) ^ 3
		local fade = math.clamp((t - duration * 0.3) / (duration * 0.7), 0, 1)
		top.Position = Vector3.new(0, height * (0.1 + 1.15 * rise) * (1 + 0.15 * fade), 0)
		for _, ray in ipairs(rays) do
			local b, w, a = ray[1], ray[2], ray[3]
			local alpha = a + (1 - a) * fade ^ 1.3
			b.Transparency = keyed({ 0, alpha }, { 0.45, math.min(1, alpha + 0.2) }, { 1, 1 })
			b.Width0 = w * (1 - 0.55 * fade)
			b.Width1 = w * 0.8 * (1 - 0.55 * fade)
		end
		local ringT = math.clamp(t / (duration * 0.7), 0, 1)
		setRing(radius * (0.5 + 1.3 * (1 - (1 - ringT) ^ 3)), math.max(0.15, radius * 0.14) * (1 - ringT * 0.7),
			0.1 + 0.9 * ringT ^ 1.5, ColorSequence.new(core, color))
		return t < life
	end)
end

 
function FX.Debris(ctx, cast, center, count, color, size, speed, material, life)
	life = life or 0.9
	local host = FX.Anchor(ctx, cast, center, life + 0.6)
	FX.Emitter(host, {
		Color = grad(FX.WHITE, color),
		Size = keyed({ 0, size * 0.55 }, { 0.6, size * 0.4 }, { 1, 0 }),
		Transparency = keyed({ 0, 0 }, { 0.75, 0.15 }, { 1, 1 }),
		Lifetime = NumberRange.new(life * 0.7, life * 1.3),
		Speed = NumberRange.new((speed or 30) * 0.35, (speed or 30) * 0.8),
		SpreadAngle = Vector2.new(55, 55),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -45, 0),
		Drag = 1,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-120, 120),
	}):Emit((count or 8) * 2)
end

 
function FX.Beam(ctx, cast, from, to, width, color, core, duration)
	if (to - from).Magnitude < 0.05 then
		return
	end
	core = core or FX.WHITE
	local host = FX.Anchor(ctx, cast, CFrame.new(from), duration + 0.1)
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = host, host
	a1.Position = to - from
	local layers = {}
	for _, spec in ipairs({
		{ width * 1.7, ColorSequence.new(color), 0.5, 0.85 },
		{ width * 0.8, ColorSequence.new(color, color:Lerp(core, 0.4)), 0.08, 1 },
		{ width * 0.28, ColorSequence.new(core), 0, 1 },
	}) do
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = a0, a1
		b.FaceCamera, b.Segments, b.LightEmission, b.LightInfluence = true, 2, spec[4], 0
		b.Color = spec[2]
		b.Width0, b.Width1 = spec[1], spec[1]
		b.Parent = host
		table.insert(layers, { b, spec[1], spec[3] })
	end
	glowSprite(ctx, cast, to, color, width * 3, duration, 0.25)
	local born = cast:Now()
	cast:Step(function(_, now)
		if not host.Parent then
			return false
		end
		local t = math.clamp((now - born) / duration, 0, 1)
		local squeeze = 1 - (1 - (1 - t) ^ 4)
		for _, l in ipairs(layers) do
			local b, w, a = l[1], l[2], l[3]
			local alpha = a + (1 - a) * t ^ 2
			b.Transparency = keyed({ 0, alpha }, { 0.9, alpha }, { 1, math.min(1, alpha + 0.4) })
			b.Width0, b.Width1 = w * math.max(0.03, squeeze), w * math.max(0.03, squeeze)
		end
		return t < 1
	end)
	return host
end


 
function FX.GroundMark(ctx, cast, frame, size, color, duration)
	local mark = FX.Temp(ctx, cast, "ShieldFXGroundMark", frame, Vector3.new(size.X, 0.06, size.Z), color, 0.7, duration + 0.2)
	local edge = FX.Temp(ctx, cast, "ShieldFXGroundEdge", frame, Vector3.new(size.X + 0.3, 0.04, size.Z + 0.3), FX.WHITE, 0.85,
		duration + 0.2)
	local born = cast:Now()
	cast:Step(function(_, now)
		local t = now - born
		if not mark.Parent then
			return false
		end
		local k = math.clamp(t / duration, 0, 1)
		local pulse = 0.5 + 0.5 * math.sin(t * (10 + k * 30))
		mark.Transparency = 0.75 - 0.35 * k - 0.1 * pulse
		edge.Transparency = 0.85 - 0.5 * k * pulse
		return t < duration
	end)
	return mark, edge
end

 
function FX.Impact(ctx, cast, position, color, glow, scale, options)
	options = options or {}
	scale = scale or 1
	FX.Flash(ctx, cast, position, glow or FX.WHITE, 6 * scale, 0.14, 0)
	FX.Flash(ctx, cast, position, color, 11 * scale, 0.32, 0.3)
	FX.Ring(ctx, cast, CFrame.new(position) * CFrame.Angles(math.pi / 2, 0, 0), 2 * scale, 18 * scale, 0.35, color, 0, 0.6 * scale)
	FX.Sparks(ctx, cast, position, color, glow, math.floor(26 * scale), 18, 46, 0.55 * scale)
	FX.Streaks(ctx, cast, position, options.Direction, color, glow, math.floor(16 * scale), options.Spread or 180, 50, 95,
		2.6 * scale)
	FX.Light(ctx, cast, position, color, 8, 22 * scale, 0.35)
	if options.Ground then
		FX.Shockwave(ctx, cast, options.Ground, 2 * scale, 20 * scale, 0.45, color, 0.2)
		FX.Smoke(ctx, cast, options.Ground.Position, options.Dust or Color3.fromRGB(190, 175, 150), 6 * scale, 8, 22, 2)
	end
	if options.Shake then
		FX.Shake(ctx, position, 90, 0.35, options.Shake)
	end
	if options.Tint then
		FX.Tint(ctx, position, color, options.Tint, 0.2)
	end
end

function FX.Floor(ctx, position, depth)
	local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -(depth or 40), 0), ctx.Filter())
	if hit and hit.Normal.Y > 0.5 then
		return CFrame.new(hit.Position + Vector3.new(0, 0.08, 0)), hit
	end
end

return FX

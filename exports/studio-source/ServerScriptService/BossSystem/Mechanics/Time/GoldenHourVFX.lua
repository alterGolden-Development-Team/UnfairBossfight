local BossSystem = script:FindFirstAncestor("BossSystem")
local Effects = require(BossSystem.Combat.EffectService)
local TAU = math.pi * 2
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local Keypoint = NumberSequenceKeypoint.new

local VFX = {
	GOLD = Color3.fromRGB(255, 205, 28),
	WHITE = Color3.fromRGB(255, 250, 173),
	AMBER = Color3.fromRGB(255, 150, 30),
	TAU = TAU,
	Quality = 1,
}

 
 
 
 
local function at(plane, u, v, h)
	h = h or 0
	if plane == "XY" then
		return Vector3.new(u, v, h)
	elseif plane == "YZ" then
		return Vector3.new(h, u, v)
	end
	return Vector3.new(u, h, v)
end
VFX.At = at

local function sequence(a0, a1)
	if a0 == a1 then
		return NumberSequence.new(a0)
	end
	return NumberSequence.new({ Keypoint(0, a0), Keypoint(1, a1) })
end

local function scaled(count, minimum)
	return math.max(minimum, math.floor(count * VFX.Quality + 0.5))
end

 
 
 
function VFX.Ribbon(parent, points, closed, o)
	o = o or {}
	local label = o.Label or "GoldenRibbon"
	local width = o.Width or 0.3
	local a0 = o.Alpha or 0.1
	local a1 = o.Alpha1 or a0
	local attachments, strands = {}, {}
	for index, point in ipairs(points) do
		local attachment = Instance.new("Attachment")
		attachment.Name = label .. "Point"
		attachment.Position = point
		attachment.Parent = parent
		attachments[index] = attachment
	end
	local count = closed and #attachments or #attachments - 1
	for index = 1, count do
		local beam = Instance.new("Beam")
		beam.Name = label
		beam.Attachment0 = attachments[index]
		beam.Attachment1 = attachments[index % #attachments + 1]
		beam.Width0 = o.Width0 or width
		beam.Width1 = o.Width1 or width
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Segments = 1
		beam.Color = ColorSequence.new(o.Color or VFX.GOLD)
		beam.Transparency = sequence(a0, a1)
		beam.Parent = parent
		strands[#strands + 1] = beam
		if o.Collect then
			o.Collect[#o.Collect + 1] = { Beam = beam, A0 = a0, A1 = a1 }
		end
	end
	return strands, attachments
end

 
function VFX.ApplyOpacity(records, opacity)
	for _, record in ipairs(records) do
		record.Beam.Transparency = sequence(1 - opacity * (1 - record.A0), 1 - opacity * (1 - record.A1))
	end
end

function VFX.Circle(parent, radius, sides, o)
	o = o or {}
	sides = scaled(sides, 6)
	local points = {}
	for index = 1, sides do
		local angle = (index - 1) / sides * TAU + (o.Offset or 0)
		points[index] = at(o.Plane, math.cos(angle) * radius, math.sin(angle) * radius, o.Height)
	end
	return VFX.Ribbon(parent, points, true, o)
end

 
function VFX.Cog(parent, innerRadius, outerRadius, teeth, o)
	o = o or {}
	teeth = scaled(teeth, 4)
	local step = TAU / teeth
	local layout = { { 0, innerRadius }, { 0.14, outerRadius }, { 0.5, outerRadius }, { 0.64, innerRadius } }
	local points = {}
	for tooth = 0, teeth - 1 do
		for _, entry in ipairs(layout) do
			local angle = tooth * step + entry[1] * step + (o.Offset or 0)
			points[#points + 1] = at(o.Plane, math.cos(angle) * entry[2], math.sin(angle) * entry[2], o.Height)
		end
	end
	return VFX.Ribbon(parent, points, true, o)
end

 
function VFX.Spokes(parent, count, innerRadius, outerRadius, o)
	o = o or {}
	for index = 1, count do
		local angle = (index - 1) / count * TAU + (o.Offset or 0)
		local c, s = math.cos(angle), math.sin(angle)
		VFX.Ribbon(parent, {
			at(o.Plane, c * innerRadius, s * innerRadius, o.Height),
			at(o.Plane, c * outerRadius, s * outerRadius, o.Height),
		}, false, o)
	end
end

 
function VFX.Link(attachment0, attachment1, o)
	o = o or {}
	local beam = Instance.new("Beam")
	beam.Name = o.Label or "GoldenLink"
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Width0 = o.Width0 or o.Width or 0.3
	beam.Width1 = o.Width1 or o.Width or 0.3
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 1
	beam.Color = ColorSequence.new(o.Color or VFX.GOLD)
	beam.Transparency = sequence(o.Alpha or 0.5, o.Alpha1 or o.Alpha or 0.5)
	beam.Parent = attachment0.Parent
	return beam
end

 
 
 
 
function VFX.Emitter(parent, o)
	o = o or {}
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = o.Name or "GoldenHourParticles"
	emitter.Texture = o.Texture or SPARKLE
	emitter.Color = ColorSequence.new(o.From or VFX.WHITE, o.To or VFX.GOLD)
	emitter.LightEmission = o.LightEmission or 1
	emitter.LightInfluence = 0
	emitter.Rate = o.Rate or 0
	emitter.Lifetime = o.Life or NumberRange.new(0.4, 0.8)
	emitter.Speed = o.Speed or NumberRange.new(4, 10)
	emitter.SpreadAngle = o.Spread or Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = o.RotSpeed or NumberRange.new(-90, 90)
	emitter.Acceleration = o.Acceleration or Vector3.zero
	emitter.Drag = o.Drag or 0
	emitter.Size = NumberSequence.new({ Keypoint(0, o.Size0 or 0.5), Keypoint(1, o.Size1 or 0) })
	emitter.Transparency = NumberSequence.new({ Keypoint(0, o.Fade0 or 0.1), Keypoint(1, 1) })
	emitter.Parent = parent
	if o.Exempt then
		emitter:SetAttribute("TimeStopExempt", true)
	end
	if o.Count then
		emitter:Emit(o.Count)
	end
	return emitter
end

 
function VFX.Trail(parent, z, halfWidth, life)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA"
	a0.Position = Vector3.new(-halfWidth, 0, z)
	a0.Parent = parent
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailB"
	a1.Position = Vector3.new(halfWidth, 0, z)
	a1.Parent = parent
	local trail = Instance.new("Trail")
	trail.Name = "GoldenTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = life or 0.3
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(VFX.WHITE, VFX.GOLD)
	trail.Transparency = NumberSequence.new({ Keypoint(0, 0.1), Keypoint(1, 1) })
	trail.WidthScale = NumberSequence.new({ Keypoint(0, 1), Keypoint(1, 0) })
	trail.Enabled = false
	trail.Parent = parent
	return trail
end

 

function VFX.Sparks(piece, position, power)
	power = power or 1
	local host = piece("GoldenHourSparks", CFrame.new(position), Vector3.one * 0.4, VFX.GOLD, 1)
	VFX.Emitter(host, {
		Name = "Sparks",
		Count = math.floor(26 * power),
		Speed = NumberRange.new(14, 34),
		Life = NumberRange.new(0.3, 0.7),
		Size0 = 0.55,
		Acceleration = Vector3.new(0, -40, 0),
		Drag = 2,
	})
	VFX.Emitter(host, {
		Name = "Dust",
		Texture = SMOKE,
		Count = math.floor(8 * power),
		From = Color3.fromRGB(255, 225, 150),
		To = Color3.fromRGB(120, 90, 40),
		LightEmission = 0.3,
		Speed = NumberRange.new(4, 12),
		Life = NumberRange.new(0.7, 1.3),
		Size0 = 3,
		Size1 = 8,
		Fade0 = 0.55,
		Spread = Vector2.new(70, 70),
	})
	Effects.ReleaseAfter(host, 1.6)
	return host
end

function VFX.Flash(piece, position, radius, duration)
	duration = duration or 0.28
	local ball = piece("GoldenHourFlash", CFrame.new(position), Vector3.one * 2, VFX.WHITE, 0.25)
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	Effects:Create(
		ball,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * radius * 1.6, Transparency = 1 }
	):Play()
	Effects.ReleaseAfter(ball, duration + 0.07)
	return ball
end

 
function VFX.Shockwave(piece, position, radius, duration, opts)
	opts = opts or {}
	local thickness = opts.Thickness or 0.25
	local wave = piece(
		"GoldenHourShockwave",
		CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(thickness, 2, 2),
		opts.Color or VFX.GOLD,
		opts.Alpha or 0.35
	)
	wave.Shape = Enum.PartType.Cylinder
	wave.Material = Enum.Material.Neon
	Effects:Create(
		wave,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(thickness, radius * 2, radius * 2), Transparency = 1 }
	):Play()
	Effects.ReleaseAfter(wave, duration + 0.05)
	return wave
end

 
function VFX.Pillar(piece, position, height, radius, duration, color)
	local pillar = piece(
		"GoldenHourPillar",
		CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(height, radius * 2, radius * 2),
		color or VFX.WHITE,
		0.2
	)
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Material = Enum.Material.Neon
	Effects:Create(
		pillar,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(height, 0.3, 0.3), Transparency = 1 }
	):Play()
	Effects.ReleaseAfter(pillar, duration + 0.05)
	return pillar
end

 
function VFX.Impact(piece, position, radius, power)
	VFX.Flash(piece, position, radius)
	VFX.Shockwave(piece, position + Vector3.new(0, 0.2, 0), radius * 1.15, 0.4)
	VFX.Sparks(piece, position, power)
end

return VFX

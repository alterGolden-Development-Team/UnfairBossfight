local Shared = require(script.Parent.Style)
local Effects = require(script:FindFirstAncestor("BossSystem").Combat.EffectService)
local FX = require(script:FindFirstAncestor("BossSystem").Attacks.Shared.ShieldBreakVFX)
local TEX_SMOKE, TEX_SPARK, EMBER, DUST = Shared.TEX_SMOKE, Shared.TEX_SPARK, Shared.EMBER, Shared.DUST
local Visuals = {}
local function gradient(...)
	local colors = { ... }
	local keys = table.create(#colors)
	for i, color in ipairs(colors) do
		keys[i] = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color)
	end
	return ColorSequence.new(keys)
end

local function curve(...)
	local values = { ... }
	local keys = table.create(#values)
	for i, value in ipairs(values) do
		keys[i] = NumberSequenceKeypoint.new((i - 1) / (#values - 1), value)
	end
	return NumberSequence.new(keys)
end

local function tween(instance, time, goal)
	Effects:Create(instance, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

 
local function hidden(part)
	part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
	return part
end

local function glow(part)
	hidden(part).Material = Enum.Material.Neon
	return part
end

local function ball(ctx, cast, name, position, size, color, transparency)
	local part = ctx.Part(cast, name, CFrame.new(position), Vector3.one * size, color, transparency)
	part.Shape = Enum.PartType.Ball
	return glow(part)
end

 
local function disc(ctx, cast, name, center, radius, thickness, color, transparency)
	local part = ctx.Part(
		cast,
		name,
		CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(thickness, radius * 2, radius * 2),
		color,
		transparency
	)
	part.Shape = Enum.PartType.Cylinder
	return hidden(part)
end

 
local function groundAt(ctx, position)
	local hit = workspace:Raycast(position, Vector3.new(0, -14, 0), ctx.Filter())
	if hit then
		return hit.Position + Vector3.new(0, 0.1, 0)
	end
	return position - Vector3.new(0, 3, 0)
end

 
 
 

local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_SPARK
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Rate = 0  
	for key, value in pairs(props) do
		e[key] = value
	end
	e.Parent = parent
	return e
end

local function sparkEmitter(parent, speedMin, speedMax, spread)
	return emitter(parent, {
		Texture = TEX_SPARK,
		Color = gradient(Shared.Bright, Shared.Gold, EMBER),
		Size = curve(0.45, 0.3, 0),
		Transparency = curve(0, 0.15, 1),
		Lifetime = NumberRange.new(0.4, 0.9),
		Speed = NumberRange.new(speedMin, speedMax),
		SpreadAngle = Vector2.new(spread or 180, spread or 180),
		Acceleration = Vector3.new(0, -40, 0),
		Drag = 2,
		Rotation = NumberRange.new(0, 360),
	})
end

local function dustEmitter(parent)
	return emitter(parent, {
		Texture = TEX_SMOKE,
		LightEmission = 0.1,
		Color = ColorSequence.new(DUST),
		Size = curve(2, 6),
		Transparency = curve(0.55, 0.8, 1),
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(8, 16),
		SpreadAngle = Vector2.new(80, 80),
		Acceleration = Vector3.new(0, 2, 0),
		Drag = 4,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-40, 40),
	})
end

 
 
 

 
local function groundBurst(ctx, cast, rootPosition)
	local point = groundAt(ctx, rootPosition)
	local anchor = hidden(ctx.Part(cast, "KnifeDust", CFrame.new(point), Vector3.one * 0.2, Shared.Gold, 1))

	local ring = glow(disc(ctx, cast, "KnifeShockwave", point, 1, 0.12, Shared.Bright, 0.2))
	tween(ring, 0.4, { Size = Vector3.new(0.05, 22, 22), Transparency = 1 })

	dustEmitter(anchor):Emit(14)
	sparkEmitter(anchor, 10, 26, 65):Emit(12)
	FX.Ring(ctx, cast, CFrame.new(point + Vector3.new(0, 0.3, 0)) * CFrame.Angles(math.pi / 2, 0, 0), 2, 18, 0.35, Shared.Bright, 0, 0.45)
	FX.Debris(ctx, cast, point + Vector3.new(0, 0.4, 0), 6, DUST, 0.4, 22, Enum.Material.Slate, 0.7)
	FX.Shake(ctx, point, 60, 0.2, 0.25)
end

 
local function releaseVfx(ctx, cast, origin, aimDirection)
	local flash = ball(ctx, cast, "KnifeReleaseFlash", origin, 0.6, Shared.Bright, 0.1)
	tween(flash, 0.22, { Size = Vector3.one * 5, Transparency = 1 })
	sparkEmitter(flash, 14, 34):Emit(20)

	 
	local ring = ctx.Part(
		cast,
		"KnifeReleaseRing",
		CFrame.lookAt(origin, origin + aimDirection) * CFrame.Angles(0, math.pi / 2, 0),
		Vector3.new(0.1, 1.5, 1.5),
		Shared.Bright,
		0.1
	)
	ring.Shape = Enum.PartType.Cylinder
	glow(ring)
	tween(ring, 0.35, { Size = Vector3.new(0.05, 16, 16), Transparency = 1 })

	 
	local flat = Vector3.new(aimDirection.X, 0, aimDirection.Z)
	if flat.Magnitude > 0.01 then
		local at = CFrame.lookAt(origin, origin + flat) * CFrame.new(0, 0, 2)
		FX.Crescent(ctx, cast, at, 7, math.rad(130), 1.6, Shared.Gold, Shared.Bright, 0.28, { Grow = 1.5 })
	end
	FX.Streaks(ctx, cast, origin, aimDirection, Shared.Gold, Shared.Bright, 24, 20, 70, 130, 3)
	FX.Ring(ctx, cast, CFrame.lookAt(origin, origin + aimDirection), 2, 20, 0.4, Shared.Gold, 0, 0.5)
	FX.Shake(ctx, origin, 70, 0.25, 0.35)
end

 
function Visuals.Summon(ctx, cast, origin, aimDirection, knifeFrames, hang)
	local facing = CFrame.lookAt(origin + aimDirection * 1.2, origin + aimDirection * 2)
	FX.Ring(ctx, cast, facing, 1, 9, hang + 0.15, Shared.Gold, 0.1, 0.3)
	FX.Ring(ctx, cast, facing * CFrame.Angles(0, 0, 0.3), 9, 6, hang + 0.1, Shared.Bright, 0.2, 0.15, 6)
	FX.Flash(ctx, cast, origin + aimDirection * 1.2, Shared.Bright, 4, 0.2, 0.1)
	for i, frame in ipairs(knifeFrames) do
		if i % 4 == 1 then
			cast:Schedule(math.min(hang * 0.8, i * 0.008), function()
				FX.Glint(ctx, cast, frame.Position, Shared.Gold, 1.8, 0.22, frame)
			end)
		end
	end
end

 
function Visuals.Hit(ctx, cast, position, direction)
	FX.Flash(ctx, cast, position, Shared.Bright, 3.5, 0.1, 0)
	FX.Streaks(ctx, cast, position, direction, Shared.Gold, Shared.Bright, 8, 40, 30, 60, 1.8)
	FX.Sparks(ctx, cast, position, Shared.Gold, Shared.Bright, 8, 10, 26, 0.35)
	local up = math.abs(direction.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
	local cut = FX.Temp(ctx, cast, "KnifeHitCut", CFrame.lookAt(position, position + direction, up) * CFrame.Angles(0, 0, math.random() * math.pi),
		Vector3.new(0.25, 4, 0.05), Shared.Bright, 0, 0.18)
	FX.Tween(cut, 0.15, { Size = Vector3.new(0.02, 6, 0.02), Transparency = 1 })
end

 
function Visuals.Clink(ctx, cast, position, direction)
	FX.Sparks(ctx, cast, position, Shared.Gold, Shared.Bright, 6, 8, 22, 0.3)
	FX.Streaks(ctx, cast, position, -direction, EMBER, Shared.Bright, 5, 70, 20, 45, 1.2)
end

Visuals.GroundBurst = groundBurst
Visuals.Release = releaseVfx
function Visuals.Ribbon(ctx, cast, from)
	local trailAnchor = hidden(ctx.Part(cast, "KnifeFlipTrail", from, Vector3.one * 0.2, Shared.Gold, 1))
	local top, bottom = Instance.new("Attachment"), Instance.new("Attachment")
	top.Position, bottom.Position = Vector3.new(0, 2.4, 0), Vector3.new(0, -2.4, 0)
	top.Parent, bottom.Parent = trailAnchor, trailAnchor

	local flipTrail = Instance.new("Trail")
	flipTrail.Attachment0, flipTrail.Attachment1 = top, bottom
	flipTrail.Color = gradient(Shared.Bright, Shared.Gold, EMBER)
	flipTrail.Transparency = curve(0.2, 0.6, 1)
	flipTrail.WidthScale = curve(1, 0.3)
	flipTrail.Lifetime = 0.45
	flipTrail.LightEmission = 1
	flipTrail.FaceCamera = true
	flipTrail.Parent = trailAnchor

	return trailAnchor, flipTrail
end
function Visuals.Knife(ctx, cast, frame)
	local blade = ctx.Part(cast, "GoldenBarrageKnife", frame, Vector3.new(0.15, 0.4, 2), Shared.Bright)
	local grip = ctx.Part(cast, "KnifeHandle", frame * CFrame.new(0, 0, 1.3), Vector3.new(0.2, 0.25, 0.7), Shared.Gold)
	glow(blade)
	hidden(grip).Material = Enum.Material.Metal
	blade.Transparency, grip.Transparency = 1, 1

	local tail0, tail1 = Instance.new("Attachment"), Instance.new("Attachment")
	tail0.Position, tail1.Position = Vector3.new(0, 0.22, 0.9), Vector3.new(0, -0.22, 0.9)
	tail0.Parent, tail1.Parent = blade, blade

	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = tail0, tail1
	trail.Color = gradient(Shared.Bright, Shared.Gold, EMBER)
	trail.Transparency = curve(0.15, 0.55, 1)
	trail.WidthScale = curve(1, 0)
	trail.Lifetime = 0.18
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Enabled = false  
	trail.Parent = blade

	local sparks = sparkEmitter(blade, 6, 20)
	sparks.Size = curve(0.3, 0.2, 0)

	return blade, grip, trail, sparks
end
return Visuals

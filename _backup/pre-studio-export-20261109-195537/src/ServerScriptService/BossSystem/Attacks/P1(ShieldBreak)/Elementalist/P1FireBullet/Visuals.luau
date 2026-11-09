local Shared = require(script.Parent.Style)
local Effects = require(script:FindFirstAncestor("BossSystem").Combat.EffectService)
local FX = require(script:FindFirstAncestor("BossSystem").Attacks.Shared.ShieldBreakVFX)
local TEX_FIRE, TEX_SMOKE, TEX_SPARK = Shared.TEX_FIRE, Shared.TEX_SMOKE, Shared.TEX_SPARK
local EMBER, SOOT = Shared.EMBER, Shared.SOOT
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

local function sparkEmitter(parent, speedMin, speedMax)
	return emitter(parent, {
		Texture = TEX_SPARK,
		Color = gradient(Shared.Bright, Shared.Gold, EMBER),
		Size = curve(0.45, 0.3, 0),
		Transparency = curve(0, 0.15, 1),
		Lifetime = NumberRange.new(0.4, 0.9),
		Speed = NumberRange.new(speedMin, speedMax),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -40, 0),
		Drag = 2,
		Rotation = NumberRange.new(0, 360),
	})
end

local function fireEmitter(parent, size)
	return emitter(parent, {
		Texture = TEX_FIRE,
		Color = gradient(Shared.Bright, Shared.Gold, EMBER),
		Size = curve(size * 0.4, size),
		Transparency = curve(0.15, 0.4, 1),
		Lifetime = NumberRange.new(0.35, 0.6),
		Speed = NumberRange.new(3, 10),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-120, 120),
	})
end

local function smokeEmitter(parent, size)
	return emitter(parent, {
		Texture = TEX_SMOKE,
		LightEmission = 0,
		Color = ColorSequence.new(SOOT),
		Size = curve(size * 0.4, size),
		Transparency = curve(0.55, 0.75, 1),
		Lifetime = NumberRange.new(0.8, 1.3),
		Speed = NumberRange.new(3, 9),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 5, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-40, 40),
	})
end

 
 
 

local function explosionVfx(ctx, cast, position, radius)
	local diameter = radius * 2
	local anchor = hidden(ctx.Part(cast, "GoldenFireBurst", CFrame.new(position), Vector3.one * 0.2, Shared.Gold, 1))

	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = Shared.Gold, radius * 3, 8, false
	light.Parent = anchor
	tween(light, 0.45, { Brightness = 0 })

	 
	local core = ball(ctx, cast, "GoldenFireCore", position, 0.5, Shared.Bright, 0)
	tween(core, 0.14, { Size = Vector3.one * diameter * 0.5, Transparency = 1 })

	local fireball = ball(ctx, cast, "GoldenFireExplosion", position, 0.8, Shared.Gold, 0.25)
	tween(fireball, 0.32, { Size = Vector3.one * diameter, Transparency = 1 })

	 
	local ring = disc(ctx, cast, "GoldenFireShockwave", position, 1, 0.2, Shared.Bright, 0.1)
	ring.Material = Enum.Material.Neon
	tween(ring, 0.4, { Size = Vector3.new(0.08, diameter * 1.4, diameter * 1.4), Transparency = 1 })

	sparkEmitter(anchor, 18, 46):Emit(30)
	fireEmitter(anchor, radius * 0.9):Emit(10)
	smokeEmitter(anchor, radius * 1.1):Emit(6)

	 
	FX.Ring(ctx, cast, CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi, 0), 1, diameter * 1.3, 0.3, EMBER, 0, 0.55)
	local column = FX.Temp(ctx, cast, "GoldenFireColumn", CFrame.new(position + Vector3.new(0, radius * 0.6, 0)),
		Vector3.new(radius * 1.2, radius * 0.9, radius * 0.9), Shared.Bright, 0.05, 0.4)
	column.Shape = Enum.PartType.Cylinder
	column.CFrame = column.CFrame * CFrame.Angles(0, 0, math.pi / 2)
	FX.Tween(column, 0.35, { Size = Vector3.new(radius * 3.5, 0.2, 0.2), Transparency = 1 }, Enum.EasingStyle.Quint)
	FX.Streaks(ctx, cast, position, Vector3.yAxis, EMBER, Shared.Bright, 10, 55, 40, 80, 2.4)
	FX.Debris(ctx, cast, position, 5, EMBER, 0.35, 28, Enum.Material.Neon, 0.7)
	local floor = FX.Floor(ctx, position, 6)
	if floor then
		local scorch = FX.Temp(ctx, cast, "GoldenFireScorch", floor * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.05, diameter * 0.9, diameter * 0.9), SOOT, 0.25, 2.2)
		scorch.Shape = Enum.PartType.Cylinder
		scorch.Material = Enum.Material.SmoothPlastic
		FX.Tween(scorch, 2.1, { Transparency = 1 })
	end
	FX.Shake(ctx, position, 45, 0.18, 0.22)
end

local function fizzleVfx(ctx, cast, position)
	local anchor = hidden(ctx.Part(cast, "GoldenFireFizzle", CFrame.new(position), Vector3.one * 0.2, Shared.Gold, 1))
	sparkEmitter(anchor, 6, 18):Emit(12)
	smokeEmitter(anchor, 3):Emit(4)
end

Visuals.Explosion = explosionVfx
Visuals.Fizzle = fizzleVfx
function Visuals.Pool(ctx, fireCast, center, fullRadius)
	 
	 
	local SQUARE = math.sqrt(2)
	local anchors = {}
	for i = 1, 2 do
		anchors[i] = hidden(
			ctx.Part(
				fireCast,
				"GoldenBurningEmitter",
				CFrame.new(center) * CFrame.Angles(0, (i - 1) * math.pi / 4, 0),
				Vector3.new(fullRadius * SQUARE, 0.2, fullRadius * SQUARE),
				Shared.Gold,
				1
			)
		)
	end

	 
	local flameRate = math.clamp(fullRadius * fullRadius * 0.8, 12, 70) / 2
	local emberRate = math.clamp(fullRadius * fullRadius * 0.25, 6, 30) / 2
	local smokeRate = math.clamp(fullRadius * 0.8, 3, 12) / 2

	local flames, embers, smoke = {}, {}, {}
	for i, anchor in ipairs(anchors) do
		flames[i] = emitter(anchor, {
			Texture = TEX_FIRE,
			Color = gradient(Shared.Bright, Shared.Gold, EMBER),
			Size = curve(2.8, 3.6, 0),
			Transparency = curve(0.25, 0.5, 1),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(2, 5),
			SpreadAngle = Vector2.new(10, 10),
			Rotation = NumberRange.new(-20, 20),
			Rate = flameRate,
		})
		embers[i] = emitter(anchor, {
			Texture = TEX_SPARK,
			Color = gradient(Shared.Bright, Shared.Gold),
			Size = curve(0.4, 0.25, 0),
			Transparency = curve(0, 0.3, 1),
			Lifetime = NumberRange.new(0.9, 1.7),
			Speed = NumberRange.new(5, 13),
			SpreadAngle = Vector2.new(30, 30),
			Acceleration = Vector3.new(0, 3, 0),
			Drag = 1,
			Rate = emberRate,
		})
		smoke[i] = emitter(anchor, {
			Texture = TEX_SMOKE,
			LightEmission = 0,
			Color = ColorSequence.new(SOOT),
			Size = curve(2, 5),
			Transparency = curve(0.7, 0.8, 1),
			Lifetime = NumberRange.new(1.2, 2),
			Speed = NumberRange.new(3, 6),
			SpreadAngle = Vector2.new(15, 15),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-30, 30),
			Rate = smokeRate,
		})
	end

	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = Shared.Gold, fullRadius * 1.6, 2, false
	light.Parent = anchors[1]

	 
	for i = 1, 2 do
		flames[i]:Emit(12)
		embers[i]:Emit(14)
	end

	return function(radius, fade, flare, pulse)
		local side = radius * SQUARE
		for i = 1, 2 do
			anchors[i].Size = Vector3.new(side, 0.2, side)
			flames[i].Rate = flameRate * fade * (1 + 0.6 * flare)  
			embers[i].Rate = emberRate * fade
			smoke[i].Rate = smokeRate * fade
		end
		light.Brightness = (1.6 + pulse * 0.8 + flare * 2.5) * fade
	end
end
function Visuals.Charge(ctx, cast, muzzle, windup, volleyEnd)
	local orb = ball(ctx, cast, "GoldenChargeOrb", muzzle(), 0.3, Shared.Bright, 0.05)
	local aura = hidden(ctx.Part(cast, "GoldenChargeAura", CFrame.new(muzzle()), Vector3.one * 7, Shared.Gold, 1))

	local orbLight = Instance.new("PointLight")
	orbLight.Color, orbLight.Range, orbLight.Brightness, orbLight.Shadows = Shared.Gold, 16, 0, false
	orbLight.Parent = orb

	local halo = emitter(orb, {
		Texture = TEX_FIRE,
		Color = gradient(Shared.Bright, Shared.Gold, EMBER),
		Size = curve(1.8, 2.6, 0),
		Transparency = curve(0.3, 0.55, 1),
		Lifetime = NumberRange.new(0.25, 0.4),
		Speed = NumberRange.new(0, 1.5),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-100, 100),
		Rate = 45,
	})
	local muzzleSparks = sparkEmitter(orb, 12, 28)
	 
	local converge = emitter(aura, {
		Texture = TEX_SPARK,
		Color = gradient(Shared.Bright, Shared.Gold),
		Size = curve(0.2, 0.45),
		Transparency = curve(1, 0.2, 0),
		Lifetime = NumberRange.new(0.5),
		Speed = NumberRange.new(7),
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Rate = 80,
	})
	cast:Schedule(windup, function()
		converge.Enabled = false
	end)

	 
	local circleHost = hidden(ctx.Part(cast, "GoldenFireSigil", CFrame.new(muzzle()), Vector3.one * 0.2, Shared.Gold, 1))
	local function ringOf(count, color, width)
		local pts, beams = {}, {}
		for i = 1, count do
			local a = Instance.new("Attachment")
			a.Parent = circleHost
			pts[i] = a
		end
		for i = 1, count do
			local b = Instance.new("Beam")
			b.Attachment0, b.Attachment1 = pts[i], pts[i % count + 1]
			b.Width0, b.Width1 = width, width
			b.FaceCamera, b.Segments, b.LightEmission, b.LightInfluence = true, 1, 1, 0
			b.Color = ColorSequence.new(color)
			b.Transparency = NumberSequence.new(i % 3 == 0 and 0.75 or 0.1)
			b.Parent = circleHost
			beams[i] = b
		end
		return pts, beams
	end
	local outerPts, outerBeams = ringOf(16, Shared.Gold, 0.18)
	local innerPts, innerBeams = ringOf(6, EMBER, 0.12)  
	local starPts, starBeams = ringOf(5, Shared.Bright, 0.08)
	for i = 1, 5 do
		starBeams[i].Attachment1 = starPts[(i + 1) % 5 + 1]  
		starBeams[i].Transparency = NumberSequence.new(0.15)
	end
	local sigilBeams = {}
	for _, list in ipairs({ outerBeams, innerBeams, starBeams }) do
		for _, b in ipairs(list) do
			table.insert(sigilBeams, b)
		end
	end
	local function placeRing(pts, radius, spin)
		for i, a in ipairs(pts) do
			local ang = spin + (i - 1) / #pts * math.pi * 2
			a.Position = Vector3.new(math.cos(ang) * radius, math.sin(ang) * radius, 0)
		end
	end

	local orbAge, kick = 0, 0
	cast:Step(function(dt)
		if not ctx.Valid() then
			cast:Dispose()
			return false
		end
		orbAge += dt
		kick = math.max(0, kick - dt * 7)

		local charge = math.clamp(orbAge / math.max(windup, 0.01), 0, 1)
		local base = 0.3 + 2.1 * (1 - (1 - charge) ^ 2)
		if orbAge > volleyEnd then
			base *= math.max(0, 1 - (orbAge - volleyEnd) / 0.25)
		end
		local size = base * (1 + 0.3 * kick) * (1 + 0.06 * math.sin(orbAge * 45))

		local cf = CFrame.new(muzzle())
		orb.CFrame = cf
		aura.CFrame = cf
		orb.Size = Vector3.one * math.max(size, 0.05)
		orbLight.Brightness = 1 + 4 * charge + 3 * kick

		 
		local look = ctx.Root.CFrame.LookVector
		circleHost.CFrame = CFrame.lookAt(cf.Position + look * 0.8, cf.Position + look * 2)
		local open = (1 - (1 - charge) ^ 3) * (1 + 0.18 * kick)
		local closing = orbAge > volleyEnd and math.max(0, 1 - (orbAge - volleyEnd) / 0.25) or 1
		local r = 3.2 * open * closing
		placeRing(outerPts, r, orbAge * 2.2)
		placeRing(innerPts, r * 0.68, -orbAge * 3.5)
		placeRing(starPts, r * 0.62, orbAge * 1.4)
		for _, b in ipairs(sigilBeams) do
			b.Enabled = r > 0.05
		end

		if orbAge >= volleyEnd + 0.25 then
			orb.Transparency = 1
			halo.Enabled, orbLight.Enabled = false, false
			for _, b in ipairs(sigilBeams) do
				b.Enabled = false
			end
			return false
		end
		return true
	end)

	return orb, function()
		kick = 1
		muzzleSparks:Emit(8)
		local look = ctx.Root.CFrame.LookVector
		local at = orb.Position + look * 1.2
		FX.Ring(ctx, cast, CFrame.lookAt(at, at + look), 1.5, 5, 0.18, Shared.Bright, 0, 0.25, 10)
		FX.Flash(ctx, cast, at, Shared.Bright, 2.5, 0.08, 0)
	end
end
function Visuals.Bullet(ctx, cast, origin)
	local bullet = ctx.Part(cast, "GoldenFireBullet", CFrame.new(origin), Vector3.one * 1.1, Shared.Bright)
	bullet.Shape = Enum.PartType.Ball
	glow(bullet)

	local top = Instance.new("Attachment")
	top.Position = Vector3.new(0, 0.6, 0)
	top.Parent = bullet
	local bottom = Instance.new("Attachment")
	bottom.Position = Vector3.new(0, -0.6, 0)
	bottom.Parent = bullet

	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = top, bottom
	trail.Color = gradient(Shared.Bright, Shared.Gold, EMBER)
	trail.Transparency = curve(0.1, 0.5, 1)
	trail.WidthScale = curve(1, 0)
	trail.Lifetime = 0.35
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Parent = bullet

	local flame = emitter(bullet, {
		Texture = TEX_FIRE,
		Color = gradient(Shared.Bright, Shared.Gold, EMBER),
		Size = curve(1.7, 1.2, 0),
		Transparency = curve(0.2, 0.5, 1),
		Lifetime = NumberRange.new(0.25, 0.4),
		Speed = NumberRange.new(0, 2),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-120, 120),
		Rate = 70,
	})
	local sparks = emitter(bullet, {
		Texture = TEX_SPARK,
		Color = gradient(Shared.Bright, Shared.Gold),
		Size = curve(0.3, 0.2, 0),
		Transparency = curve(0, 0.3, 1),
		Lifetime = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -14, 0),
		Rate = 30,
	})
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = Shared.Gold, 12, 2.5, false
	light.Parent = bullet

	 
	local function retire()
		bullet.Transparency = 1
		trail.Enabled, light.Enabled = false, false
		flame.Enabled, sparks.Enabled = false, false
	end

	return bullet, retire
end
return Visuals

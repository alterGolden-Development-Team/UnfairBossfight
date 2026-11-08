local Shared = require(script.Parent.Style)
local FX = require(script:FindFirstAncestor("BossSystem").Attacks.Shared.ShieldBreakVFX)
local TEX_SPARK, TEX_SMOKE = Shared.TEX_SPARK, Shared.TEX_SMOKE
local CYAN, ICE, DEEP, VIOLET, SEGMENTS = Shared.CYAN, Shared.ICE, Shared.DEEP, Shared.VIOLET, Shared.SEGMENTS
local Visuals = {}

 
 
 
 
 
 
local HIT_SLOTS = 5  
local SKY_HEIGHT = 60  
local SHOCK_CHARS = 4  
local FIELD_ARCS = 6  
local IMPACTS = 36  
local PILLAR_HEIGHT = 22  
local ARC_BANDS = 4  
local USE_HIGHLIGHT = true  
local RING_CANVAS, RING_FILL = 768, 0.94  

local function rootOf(char)
	return char and char:FindFirstChild("HumanoidRootPart")
end

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

 
local function glow(part)
	part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
	part.Material = Enum.Material.Neon
	return part
end

local function hidden(part)
	part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
	return part
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

local function jolt(r)
	return (math.random() - 0.5) * 2 * r
end

 
 
 
 

local function newBolt(ctx, cast, color, segments, flat)
	segments = segments or SEGMENTS
	local bolt = {
		Parts = table.create(segments),
		Points = table.create(segments + 1),
		Flat = flat or 1,
		Life = 0,
		Max = 0.3,
		Width = 0.2,
		A = Vector3.zero,
		B = Vector3.zero,
	}
	for i = 1, segments do
		bolt.Parts[i] = glow(ctx.Part(cast, "LightningStrikeArc", ctx.Root.CFrame, Vector3.one * 0.1, color, 1))
	end
	return bolt
end

local function hideBolt(bolt)
	for _, part in ipairs(bolt.Parts) do
		part.Transparency = 1
	end
end

local function shapeBolt(bolt, a, b, width, transparency, jitter)
	local parts = bolt.Parts
	local segments = #parts
	local offset = b - a
	local length = offset.Magnitude
	if length < 0.1 then
		hideBolt(bolt)
		return
	end
	local unit = offset / length
	jitter = jitter or math.min(length * 0.12, 2.5)

	local points = bolt.Points
	local previous = a
	points[1] = a
	for i = 1, segments do
		local point = b
		if i < segments then
			 
			local side = unit:Cross(Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5))
			if side.Magnitude > 0.05 then
				side = side.Unit * jitter * (0.4 + math.random() * 0.6)
				side = Vector3.new(side.X, side.Y * bolt.Flat, side.Z)
			else
				side = Vector3.zero
			end
			point = a + unit * (length * i / segments) + side
		end
		points[i + 1] = point
		local part = parts[i]
		part.CFrame = CFrame.lookAt((previous + point) / 2, point)
		part.Size = Vector3.new(width, width, math.max((point - previous).Magnitude, 0.05))
		part.Transparency = transparency
		previous = point
	end
end

local function pool(ctx, cast, count, color, segments, flat)
	local bolts = table.create(count)
	for i = 1, count do
		bolts[i] = newBolt(ctx, cast, color, segments, flat)
	end
	return bolts
end

 
 
 
 

local function newRing(ctx, cast, name, strokeColor, fillColor)
	local part = hidden(ctx.Part(cast, name, ctx.Root.CFrame, Vector3.new(1, 0.05, 1), strokeColor, 1))

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(RING_CANVAS, RING_CANVAS)
	gui.LightInfluence = 0
	gui.Parent = part

	local circle = Instance.new("Frame")
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromScale(0.5, 0.5)
	circle.Size = UDim2.fromScale(RING_FILL, RING_FILL)
	circle.BackgroundColor3 = fillColor
	circle.BackgroundTransparency = 1
	circle.BorderSizePixel = 0
	circle.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = circle

	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = 1
	stroke.Transparency = 1
	stroke.Parent = circle

	return { Part = part, Circle = circle, Stroke = stroke }
end

 
local function setRing(ring, center, diameter, width, strokeAlpha, fillAlpha)
	local size = math.max(diameter, 1) / RING_FILL
	ring.Part.CFrame = CFrame.new(center)
	ring.Part.Size = Vector3.new(size, 0.05, size)
	ring.Stroke.Thickness = math.clamp(width * RING_CANVAS / size, 1, 22)
	ring.Stroke.Transparency = strokeAlpha
	ring.Circle.BackgroundTransparency = fillAlpha
end

local function hideRing(ring)
	ring.Stroke.Transparency = 1
	ring.Circle.BackgroundTransparency = 1
end

 

function Visuals.Create(ctx, cast, radius, windup, total, shell)
	local floorHit = workspace:Raycast(ctx.Root.Position, Vector3.new(0, -14, 0), ctx.Filter())
	local floorY = (floorHit and floorHit.Position.Y or ctx.Root.Position.Y - 3) + 0.2

	local function onFloor(position, lift)
		return Vector3.new(position.X, floorY + lift, position.Z)
	end

	 
	local density = math.clamp(radius / 24, 1, 2.2)
	local groundCount = math.clamp(math.floor(radius / 3), 8, 14)
	local skyCount = math.clamp(math.floor(radius / 3.5), 8, 14)
	local pillarCount = math.clamp(math.floor(radius / 2.6), 12, 22)
	local arcsPerBand = math.clamp(math.floor(radius / 3.2), 10, 14)

	 
	 
	 
	local arcs = {}
	for i = 1, ARC_BANDS * arcsPerBand do
		local color = CYAN
		if i % 3 == 0 then
			color = Shared.Bright
		elseif i % 5 == 0 then
			color = VIOLET
		end
		arcs[i] = glow(ctx.Part(cast, "LightningWhirlwindArc", ctx.Root.CFrame, Vector3.one * 0.15, color, 1))
	end

	local core = ctx.Part(cast, "LightningBurst", ctx.Root.CFrame, Vector3.one * 2, ICE, 0.6)
	core.Shape = Enum.PartType.Ball
	glow(core)

	 
	local flash = ctx.Part(cast, "LightningFlash", ctx.Root.CFrame, Vector3.one, ICE, 1)
	flash.Shape = Enum.PartType.Ball
	glow(flash)

	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = CYAN, math.clamp(radius * 1.5, 24, 60), 0, false
	light.Parent = core

	local sparks = emitter(core, {
		Color = gradient(ICE, CYAN, DEEP),
		Size = curve(0.5, 0.3, 0),
		Transparency = curve(0, 0.2, 1),
		Lifetime = NumberRange.new(0.25, 0.55),
		Speed = NumberRange.new(8, 22),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -10, 0),
		Rotation = NumberRange.new(0, 360),
	})
	local flare = emitter(core, {
		Color = gradient(ICE, CYAN),
		Size = curve(5, 11),
		Transparency = curve(0.3, 1),
		Lifetime = NumberRange.new(0.15, 0.28),
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(0, 360),
	})
	 
	local nova = emitter(core, {
		Color = gradient(ICE, CYAN, DEEP),
		Size = curve(0.9, 0.55, 0),
		Transparency = curve(0, 0.2, 1),
		Lifetime = NumberRange.new(0.3, 0.45),
		Speed = NumberRange.new(radius * 2.2, radius * 3.2),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
	})

	 
	local auraRadius = math.clamp(radius * 0.5, 10, 24)
	local aura = hidden(ctx.Part(cast, "LightningChargeAura", ctx.Root.CFrame, Vector3.one * auraRadius * 2, CYAN, 1))
	local converge = emitter(aura, {
		Color = gradient(ICE, CYAN),
		Size = curve(0.3, 0.9),
		Transparency = curve(1, 0.2, 0),
		Lifetime = NumberRange.new(0.4),
		Speed = NumberRange.new(auraRadius / 0.4),
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Rate = 300,
	})
	converge.Enabled = windup > 0
	if windup > 0 then
		cast:Schedule(windup, function()
			converge.Enabled = false
		end)
	end

	 
	 
	 
	local zoneRing = newRing(ctx, cast, "LightningZoneRing", CYAN, DEEP)
	local chargeRing = newRing(ctx, cast, "LightningChargeRing", ICE, CYAN)
	local waves = {
		{ Ring = newRing(ctx, cast, "LightningShockwave", ICE, CYAN), Delay = 0, Slow = 1, Weight = 1 },
		{ Ring = newRing(ctx, cast, "LightningShockwave", CYAN, DEEP), Delay = 0.08, Slow = 1.3, Weight = 0.7 },
	}

	 
	 
	 
	local host = hidden(ctx.Part(cast, "LightningImpactHost", CFrame.new(ctx.Root.Position), Vector3.one * 0.2, CYAN, 1))
	local impacts = table.create(IMPACTS)
	for i = 1, IMPACTS do
		local att = Instance.new("Attachment")
		att.Parent = host
		impacts[i] = {
			Att = att,
			Sparks = emitter(att, {
				Color = gradient(ICE, CYAN, DEEP),
				Size = curve(0.8, 0.4, 0),
				Transparency = curve(0, 0.3, 1),
				Lifetime = NumberRange.new(0.3, 0.7),
				Speed = NumberRange.new(16, 38),
				SpreadAngle = Vector2.new(60, 60),
				Acceleration = Vector3.new(0, -50, 0),
				Rotation = NumberRange.new(0, 360),
			}),
			Glow = emitter(att, {
				Color = gradient(ICE, CYAN),
				Size = curve(7, 15),
				Transparency = curve(0.2, 1),
				Lifetime = NumberRange.new(0.14, 0.24),
				Speed = NumberRange.new(0),
				Rotation = NumberRange.new(0, 360),
			}),
			Dust = emitter(att, {
				Texture = TEX_SMOKE,
				LightEmission = 0.4,
				Color = gradient(CYAN, DEEP),
				Size = curve(2, 6),
				Transparency = curve(0.65, 1),
				Lifetime = NumberRange.new(0.5, 0.9),
				Speed = NumberRange.new(5, 14),
				SpreadAngle = Vector2.new(75, 75),
				Rotation = NumberRange.new(0, 360),
				RotSpeed = NumberRange.new(-60, 60),
			}),
		}
	end
	local nextImpact = 0
	 
	local function impact(position, power)
		nextImpact = nextImpact % IMPACTS + 1
		local slot = impacts[nextImpact]
		slot.Att.WorldPosition = position
		if power >= 2 then
			slot.Sparks:Emit(45)
			slot.Glow:Emit(2)
			slot.Dust:Emit(7)
		elseif power >= 1 then
			slot.Sparks:Emit(22)
			slot.Glow:Emit(1)
			slot.Dust:Emit(3)
		else
			slot.Sparks:Emit(6)
		end
	end

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	local groundBolts = pool(ctx, cast, groundCount, ICE, 6, 0.35)
	for _, bolt in ipairs(groundBolts) do
		bolt.Fork = { Bolt = newBolt(ctx, cast, CYAN, 3, 0.35), Index = 2, Angle = 0, Length = 0 }
	end
	local skyBolts = pool(ctx, cast, skyCount, ICE)
	local hitBolts = pool(ctx, cast, HIT_SLOTS, ICE)
	local smiteBolts = pool(ctx, cast, HIT_SLOTS, ICE)
	local fieldBolts = pool(ctx, cast, FIELD_ARCS, CYAN, 3, 0.35)
	local pillars = pool(ctx, cast, pillarCount, CYAN, 3)
	local shockBolts = pool(ctx, cast, SHOCK_CHARS * 2, CYAN)

	local timed = {}
	for _, list in ipairs({ groundBolts, skyBolts, hitBolts, smiteBolts, fieldBolts }) do
		for _, bolt in ipairs(list) do
			table.insert(timed, bolt)
		end
	end

	local shocked, shockUsed = {}, 0
	local kick, flashT, pillarBoost = 0, 0, 0
	local pillarSpin = math.random() * math.pi * 2
	local fieldIndex = 0

	 
	local function shapeFork(bolt, width, transparency)
		local fork = bolt.Fork
		local start = bolt.Points[fork.Index]
		local flat = bolt.B - bolt.A
		flat = Vector3.new(flat.X, 0, flat.Z)
		if not start or flat.Magnitude < 0.1 then
			hideBolt(fork.Bolt)
			return
		end
		local dir = CFrame.Angles(0, fork.Angle, 0):VectorToWorldSpace(flat.Unit)
		shapeBolt(fork.Bolt, start, start + dir * fork.Length, width, transparency, 1.4)
	end

	local function activate(bolt, a, b, width, follow, life, jitter)
		bolt.A, bolt.B, bolt.Width, bolt.Follow, bolt.Jitter = a, b, width, follow, jitter
		bolt.Life, bolt.Max = life, life
		shapeBolt(bolt, a, b, 0.12 + width, 0, jitter)
		if bolt.Fork then
			shapeFork(bolt, 0.1 + width * 0.6, 0)
		end
	end

	local api = {}

	 
	function api.Pulse(initial, origin, final)
		local big = initial or final
		kick = final and 1.6 or 1
		nova:Emit(math.floor((final and 240 or initial and 150 or 55) * density))
		flare:Emit(final and 4 or initial and 3 or 1)
		if big then
			flashT = final and 1 or 0.8
		end
		pillarBoost = final and 1 or initial and 0.8 or 0.35

		 
		local waveDur = final and 0.6 or initial and 0.45 or 0.32
		local wavePower = final and 1.5 or initial and 1.2 or 0.7
		for i, wave in ipairs(waves) do
			wave.Age = -wave.Delay
			wave.Dur = waveDur * wave.Slow
			wave.Power = wavePower * wave.Weight
			wave.Origin = onFloor(origin, 0.06 + i * 0.02)
			wave.Active = true
		end

		 
		local spin = math.random() * math.pi * 2
		for i = 1, groundCount do
			local bolt = groundBolts[i]
			local angle = spin + (i - 1) * math.pi * 2 / groundCount + jolt(0.12)
			local from = onFloor(origin, 0)
			local to = Vector3.new(origin.X + math.cos(angle) * radius, floorY, origin.Z + math.sin(angle) * radius)
			local fork = bolt.Fork
			fork.Index = math.random(2, #bolt.Parts)
			fork.Angle = (math.random() < 0.5 and -1 or 1) * (0.35 + math.random() * 0.4)
			fork.Length = radius * (0.16 + math.random() * 0.14)
			activate(bolt, from, to, big and 0.6 or 0.4, nil, big and 0.45 or 0.32, nil)
		end

		 
		local strikes = big and skyCount or math.ceil(skyCount * 0.6)
		local strikeSpin = math.random() * math.pi * 2
		for i = 1, strikes do
			local angle = strikeSpin + i * 2.39996
			local dist = math.clamp(radius * 0.95 * math.sqrt((i - 0.5) / strikes) + jolt(radius * 0.04), 0, radius * 0.97)
			local x, z = origin.X + math.cos(angle) * dist, origin.Z + math.sin(angle) * dist
			local ground = Vector3.new(x, floorY, z)
			local top = Vector3.new(x + jolt(6), floorY + SKY_HEIGHT, z + jolt(6))
			local bolt = skyBolts[i]
			local function strike()
				activate(bolt, top, ground, big and 1.1 or 0.7, nil, 0.3, 4)
				impact(ground, big and 2 or 1)
			end
			local delay = (i - 1) / strikes * 0.14
			if delay > 0.01 then
				cast:Schedule(delay, strike)
			else
				strike()
			end
		end

		 
		local floorPos = onFloor(origin, 0.05)
		FX.Shake(ctx, origin, radius * 3, final and 0.7 or initial and 0.45 or 0.2, final and 1 or initial and 0.6 or 0.22)
		if big then
			FX.Tint(ctx, origin, CYAN, final and 1 or 0.65, final and 0.35 or 0.22, radius * 3)
		end
		FX.Ring(ctx, cast, CFrame.new(floorPos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(math.pi / 2, 0, 0), 4,
			radius * 2.1, big and 0.45 or 0.3, ICE, 0, big and 1.1 or 0.55)

		 
		if initial then
			for i = 1, 6 do
				cast:Schedule(i * 0.03, function()
					FX.Ring(ctx, cast, CFrame.new(origin + Vector3.new(0, -2 + i * 2.2, 0)) * CFrame.Angles(math.pi / 2, 0, i * 0.4),
						3 + i, 9 + i * 2.5, 0.35, i % 2 == 0 and CYAN or ICE, 0, 0.5)
				end)
			end
			FX.Flash(ctx, cast, origin, ICE, 16, 0.2, 0)
		end

		 
		if final then
			local sky = floorPos + Vector3.new(0, SKY_HEIGHT * 1.6, 0)
			FX.Beam(ctx, cast, sky, floorPos, 11, DEEP, ICE, 0.6)
			FX.Beam(ctx, cast, sky, floorPos, 4, CYAN, Color3.new(1, 1, 1), 0.85)
			for i = 1, 5 do
				FX.ForkedBolt(ctx, cast, sky + Vector3.new(jolt(8), 0, jolt(8)), floorPos + Vector3.new(jolt(4), 0, jolt(4)),
					CYAN, ICE, 0.9, 0.4, 3)
			end
			FX.Flash(ctx, cast, floorPos + Vector3.new(0, 3, 0), Color3.new(1, 1, 1), radius * 0.9, 0.25, 0)
			FX.Flash(ctx, cast, floorPos + Vector3.new(0, 3, 0), CYAN, radius * 1.6, 0.5, 0.35)
			FX.Shockwave(ctx, cast, CFrame.new(floorPos), 6, radius * 2.4, 0.6, ICE, 0.1, 0.3)
			FX.Spikes(ctx, cast, floorPos, 14, radius * 0.45, 9, CYAN, ICE, 1.1, 35)
			FX.Spikes(ctx, cast, floorPos, 10, radius * 0.8, 6, DEEP, ICE, 0.9, 20)
			FX.Debris(ctx, cast, floorPos + Vector3.new(0, 1, 0), 16, Color3.fromRGB(90, 96, 110), 1, 48, Enum.Material.Slate, 1.1)
			FX.Streaks(ctx, cast, floorPos, Vector3.yAxis, CYAN, ICE, 40, 70, 60, 130, 4)
			FX.Light(ctx, cast, floorPos + Vector3.new(0, 6, 0), CYAN, 14, radius * 3, 0.7)
		end

		 
		if big then
			for i = 1, pillarCount, 2 do
				local angle = pillarSpin + (i - 1) * math.pi * 2 / pillarCount
				impact(Vector3.new(origin.X + math.cos(angle) * radius * 0.98, floorY, origin.Z + math.sin(angle) * radius * 0.98), 1)
			end
		end
	end

	function api.Hit(char, root, origin, slot, initial, final)
		local big = initial or final
		local life = big and 0.45 or 0.32
		local position = root.Position

		local bolt = hitBolts[slot]
		if bolt then
			activate(bolt, origin + Vector3.new(0, 1.5, 0), position, big and 0.55 or 0.35, root, life, nil)
		end
		local smite = smiteBolts[slot]
		if smite then
			local top = position + Vector3.new(jolt(3), SKY_HEIGHT, jolt(3))
			activate(smite, top, Vector3.new(position.X, floorY, position.Z), big and 1.2 or 0.8, nil, life, 4)
		end
		impact(position, big and 2 or 1)
		if big then
			FX.Impact(ctx, cast, position, CYAN, ICE, final and 1.2 or 0.8)
			FX.Bolt(ctx, cast, position + Vector3.new(0, 4, 0), position - Vector3.new(0, 3, 0), VIOLET, ICE, 0.35, 1.5, 4, 0.25, true)
		end

		if initial and not shocked[char] and shockUsed + 2 <= #shockBolts then
			local entry = { shockBolts[shockUsed + 1], shockBolts[shockUsed + 2] }
			shockUsed += 2
			if USE_HIGHLIGHT then
				local hl = Instance.new("Highlight")
				hl.Adornee = char
				hl.FillColor, hl.OutlineColor = CYAN, ICE
				hl.FillTransparency, hl.OutlineTransparency = 0.7, 0
				hl.DepthMode = Enum.HighlightDepthMode.Occluded
				hl.Parent = core  
				entry.Highlight = hl
			end
			shocked[char] = entry
		end
	end

	local age, visual, refresh = 0, 0, 0
	cast:Step(function(dt)
		if not ctx.Valid() then
			cast:Dispose()
			return false
		end
		age += dt
		visual += dt

		local center = ctx.Root.Position
		local live = age < total
		local charge = windup > 0 and math.clamp(age / windup, 0, 1) or 1
		local fade = math.clamp((age - total) / 0.15, 0, 1)
		kick = math.max(0, kick - dt * 5)

		 
		 
		 
		if windup > 0 and charge < 1 then
			 
			local ease = 1 - (1 - charge) ^ 2
			setRing(chargeRing, onFloor(center, 0.12), radius * 2 * (1.5 - 1.4 * ease), 0.5 + charge * 1.2, 0.1, 0.9)
		else
			hideRing(chargeRing)
		end

		for _, wave in ipairs(waves) do
			if wave.Active then
				wave.Age += dt
				local t = wave.Age / wave.Dur
				if wave.Age < 0 then
					hideRing(wave.Ring)
				elseif t >= 1 then
					wave.Active = false
					hideRing(wave.Ring)
				else
					local ease = 1 - (1 - t) ^ 3
					setRing(
						wave.Ring,
						wave.Origin,
						radius * 2 * (0.12 + 0.93 * ease),
						(0.4 + 1.6 * wave.Power) * (1 - t * 0.75),
						math.min(1, t ^ 1.5),
						1 - (1 - t) * 0.4 * wave.Power
					)
				end
			end
		end

		if flashT > 0 then
			flashT = math.max(0, flashT - dt / 0.25)
			flash.Position = center
			flash.Size = Vector3.one * math.min(radius, 34) * (0.4 + (1 - flashT) * 0.8)
			flash.Transparency = 1 - flashT * 0.4
		else
			flash.Transparency = 1
		end

		if visual < 0.05 then
			return true
		end
		local frameDt = visual
		visual = 0
		refresh += 1

		 
		 
		 

		 
		local zoneAlpha
		if windup > 0 and charge < 1 then
			zoneAlpha = 0.5 - 0.3 * math.sin(age * 30) * 0.5
		elseif live then
			zoneAlpha = math.random() < 0.15 and 0.9 or (0.35 - kick * 0.2)
		else
			zoneAlpha = 1
		end
		setRing(zoneRing, onFloor(center, 0), radius * 2, 0.7, math.max(zoneAlpha, fade), math.max(0.9 - 0.15 * kick, fade))

		 
		core.Position = center
		aura.Position = center
		if shell then
			core.Size = Vector3.one * (2 + math.min(age / 0.15, 1) * radius * 2)
			core.Transparency = math.min(1, 0.7 + age * 0.1)
		else
			core.Size = Vector3.one * ((2.2 + charge * 1.8 + kick * 5) * (0.9 + math.random() * 0.2))
			core.Transparency = math.clamp(0.3 + 0.5 * (1 - charge) - 0.3 * kick + fade, 0, 1)
		end
		light.Brightness = (3 + math.random() * 4 + kick * 10) * charge * (1 - fade)
		sparks.Rate = live and 80 * density * charge or 0
		flare.Rate = live and 10 * charge or 0

		 
		local reach = 0.15 + 0.85 * (1 - (1 - charge) ^ 2)
		for i, arc in ipairs(arcs) do
			local band = math.floor((i - 1) / arcsPerBand)
			local slot = (i - 1) % arcsPerBand
			local angle = slot * math.pi * 2 / arcsPerBand + age * (band % 2 == 0 and 10 or -10) + jolt(0.06)
			local r = radius * (0.55 + 0.15 * band) * reach  
			local y = -2.5 + band * 2.2 + math.sin(angle * 3 + age * 24) * 1
			local a = center + Vector3.new(math.cos(angle) * r, y, math.sin(angle) * r)
			local b = center
				+ Vector3.new(math.cos(angle + 0.4) * r, y + math.sin(i + age * 45) * 1.9, math.sin(angle + 0.4) * r)
			local thick = 0.14 + math.random() * 0.26
			arc.CFrame = CFrame.lookAt((a + b) / 2, b)
			arc.Size = Vector3.new(thick, thick, math.max((b - a).Magnitude, 0.05))
			 
			arc.Transparency = math.max(fade, math.random() < 0.15 and 1 or 0.5 * (1 - charge))
		end

		 
		 
		pillarBoost = math.max(0, pillarBoost - frameDt * 3)
		pillarSpin += frameDt * 0.5
		local grow = windup > 0 and (0.2 + 0.8 * charge) or 1
		for i, bolt in ipairs(pillars) do
			if fade >= 1 then
				hideBolt(bolt)
			elseif refresh % 2 == 0 then  
				local angle = pillarSpin + (i - 1) * math.pi * 2 / pillarCount
				local base = Vector3.new(center.X + math.cos(angle) * radius, floorY, center.Z + math.sin(angle) * radius)
				local height = PILLAR_HEIGHT * grow * (0.65 + math.random() * 0.35) * (1 + pillarBoost * 0.8)
				local top = base + Vector3.new(jolt(1.8), height, jolt(1.8))
				local alpha = math.random() < 0.18 and 1 or math.clamp(0.25 + 0.4 * (1 - charge) - pillarBoost * 0.3, 0, 1)
				shapeBolt(bolt, base, top, 0.2 + pillarBoost * 0.9, math.max(alpha, fade), 1.8)
			end
		end

		 
		if live and charge >= 1 and math.random() < 0.7 then
			local angle = math.random() * math.pi * 2
			local dist = math.sqrt(math.random()) * radius * 0.95
			local spot = onFloor(center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist), 0.1)
			impact(spot, 0)
			if math.random() < 0.5 then
				fieldIndex = fieldIndex % FIELD_ARCS + 1
				local dir = math.random() * math.pi * 2
				local length = 3 + math.random() * 5
				activate(
					fieldBolts[fieldIndex],
					spot,
					spot + Vector3.new(math.cos(dir) * length, 0, math.sin(dir) * length),
					0.1,
					nil,
					0.18,
					1
				)
			end
		end

		 
		for _, bolt in ipairs(timed) do
			if bolt.Life > 0 then
				bolt.Life -= frameDt
				if bolt.Life <= 0 then
					hideBolt(bolt)
					if bolt.Fork then
						hideBolt(bolt.Fork.Bolt)
					end
				else
					if bolt.Follow and bolt.Follow.Parent then
						bolt.B = bolt.Follow.Position
					end
					local t = bolt.Life / bolt.Max
					shapeBolt(bolt, bolt.A, bolt.B, 0.12 + bolt.Width * t, (1 - t) * 0.7, bolt.Jitter)
					if bolt.Fork then
						shapeFork(bolt, 0.1 + bolt.Width * 0.6 * t, (1 - t) * 0.8)
					end
				end
			end
		end

		 
		for char, entry in pairs(shocked) do
			local root = rootOf(char)
			if live and root and ctx.Core.Alive(char) then
				local p = root.Position
				shapeBolt(
					entry[1],
					p + Vector3.new(jolt(1.6), -3, jolt(1.6)),
					p + Vector3.new(jolt(1.6), 3, jolt(1.6)),
					0.2,
					math.random() < 0.25 and 1 or 0.05,
					1.2
				)
				shapeBolt(
					entry[2],
					p + Vector3.new(jolt(2.4), jolt(1.6), jolt(2.4)),
					p + Vector3.new(jolt(2.4), jolt(1.6), jolt(2.4)),
					0.16,
					math.random() < 0.25 and 1 or 0.05,
					0.9
				)
				if entry.Highlight then
					entry.Highlight.FillTransparency = math.random() < 0.3 and 0.35 or 0.75
				end
			else
				hideBolt(entry[1])
				hideBolt(entry[2])
				if entry.Highlight then
					entry.Highlight:Destroy()
				end
				shocked[char] = nil
			end
		end
		return true
	end)

	return api
end
return Visuals

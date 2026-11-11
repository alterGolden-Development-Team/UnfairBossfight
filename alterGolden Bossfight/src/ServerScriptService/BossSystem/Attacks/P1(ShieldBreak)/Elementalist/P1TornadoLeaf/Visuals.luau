local Shared = require(script.Parent.Style)
local FX = require(script:FindFirstAncestor("BossSystem").Attacks.Shared.ShieldBreakVFX)
local TEX_SPARK, TEX_SMOKE = Shared.TEX_SPARK, Shared.TEX_SMOKE
local BANDS = 6  
local BAND_POINTS = 18
local Visuals = {}

 
 
 
 
local HEIGHT = 26  
local BASE_DROP = 3  
local LEAF_DENSITY = 10  
local HIT_BURSTS = 6  

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

 
local function quiet(part)
	part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
	return part
end

local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_SPARK
	e.LightEmission = 0.3
	e.LightInfluence = 0
	e.Rate = 0  
	for key, value in pairs(props) do
		e[key] = value
	end
	e.Parent = parent
	return e
end

 
function Visuals.Create(ctx, cast, opts)
	local radius, windup, lifetime = opts.Radius, opts.Windup, opts.Lifetime
	local topR = radius
	local baseR = radius * .3
	local count = math.clamp(math.floor(radius * LEAF_DENSITY), 80, 160)

	local floorHit = workspace:Raycast(ctx.Root.Position, Vector3.new(0, -14, 0), ctx.Filter())
	local floorY = (floorHit and floorHit.Position.Y or ctx.Root.Position.Y - 3) + 0.15

	 
	 
	 
	local leaves = table.create(count)
	for i = 1, count do
		local color = Shared.Leaf
		if i % 4 == 0 then
			color = Shared.Gold
		elseif i % 3 == 0 then
			color = Shared.Light
		elseif i % 5 == 0 then
			color = Shared.Dark
		end
		local size = 1.4 + ((i * 0.6180339) % 1) * 1.2  
		local leaf = quiet(
			ctx.Part(cast, "TornadoLeaf", ctx.Root.CFrame, Vector3.new(0.35, 0.08, 1.1) * size, color, 0.05)
		)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = leaf
		leaves[i] = leaf
	end

	 
	 
	 
	 
	local layerH = HEIGHT / 3
	local layers = table.create(3)
	for i = 1, 3 do
		local half = baseR + (topR - baseR) * ((i - 0.5) / 3)
		local part = quiet(
			ctx.Part(cast, "TornadoAir", ctx.Root.CFrame, Vector3.new(half * 1.5, layerH, half * 1.5), Shared.Leaf, 1)
		)
		layers[i] = {
			Part = part,
			Half = half,
			AirRate = 8 + half * 3,
			FleckRate = 6 + half * 1.5,
			Air = emitter(part, {
				Texture = TEX_SMOKE,
				LightEmission = 0.15,
				Color = gradient(Shared.Wind, Shared.Leaf),
				Size = curve(1.5 + half * 0.25, 3 + half * 0.6),
				Transparency = curve(0.78, 0.9, 1),
				Lifetime = NumberRange.new(0.35, 0.6),
				Speed = NumberRange.new(0, 2),
				Acceleration = Vector3.new(0, 6, 0),
				Rotation = NumberRange.new(0, 360),
				RotSpeed = NumberRange.new(-120, 120),
			}),
			 
			Flecks = emitter(part, {
				Color = gradient(Shared.Gold, Shared.Light, Shared.Leaf),
				Size = curve(0.6, 0.4, 0),
				Transparency = curve(0.1, 0.3, 1),
				Lifetime = NumberRange.new(0.5, 0.9),
				Speed = NumberRange.new(3, 9),
				SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, -8, 0),
				Rotation = NumberRange.new(0, 360),
			}),
		}
	end
	local mid = layers[2].Part

	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = Shared.Light, math.clamp(radius * 3, 14, 30), 0, false
	light.Parent = mid

	 
	local launchLeaves = emitter(mid, {
		Color = gradient(Shared.Wind, Shared.Light, Shared.Leaf),
		Size = curve(0.9, 0.6, 0),
		Transparency = curve(0, 0.3, 1),
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(14, 30),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -12, 0),
		Rotation = NumberRange.new(0, 360),
	})
	local launchFlare = emitter(mid, {
		Color = gradient(Shared.Wind, Shared.Gold),
		Size = curve(6, 14),
		Transparency = curve(0.3, 1),
		Lifetime = NumberRange.new(0.15, 0.25),
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(0, 360),
	})

	 
	 
	 
	 
	local ground = quiet(
		ctx.Part(cast, "TornadoDust", CFrame.new(ctx.Root.Position), Vector3.one * 0.2, Shared.Dust, 1)
	)
	local dust = emitter(ground, {
		Texture = TEX_SMOKE,
		LightEmission = 0,
		Color = gradient(Shared.Dust, Shared.Wind),
		Size = curve(2.5, 7 + radius * 0.5),
		Transparency = curve(0.55, 1),
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, 2, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-60, 60),
	})
	local rain = emitter(ground, {
		Color = gradient(Shared.Light, Shared.Gold, Shared.Leaf),
		Size = curve(0.8, 0.5, 0),
		Transparency = curve(0, 0.3, 1),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(6, 14),
		SpreadAngle = Vector2.new(60, 60),
		Acceleration = Vector3.new(0, -14, 0),
		Rotation = NumberRange.new(0, 360),
	})

	 
	 
	 
	local host = quiet(ctx.Part(cast, "TornadoHitHost", CFrame.new(ctx.Root.Position), Vector3.one * 0.2, Shared.Leaf, 1))
	local hits = table.create(HIT_BURSTS)
	for i = 1, HIT_BURSTS do
		local att = Instance.new("Attachment")
		att.Parent = host
		hits[i] = {
			Att = att,
			Leaves = emitter(att, {
				Color = gradient(Shared.Wind, Shared.Light, Shared.Leaf),
				Size = curve(0.9, 0.6, 0),
				Transparency = curve(0, 0.3, 1),
				Lifetime = NumberRange.new(0.5, 1),
				Speed = NumberRange.new(12, 26),
				SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, -18, 0),
				Rotation = NumberRange.new(0, 360),
			}),
			Gust = emitter(att, {
				Texture = TEX_SMOKE,
				LightEmission = 0.2,
				Color = gradient(Shared.Wind, Shared.Leaf),
				Size = curve(3, 9),
				Transparency = curve(0.5, 1),
				Lifetime = NumberRange.new(0.4, 0.7),
				Speed = NumberRange.new(6, 14),
				SpreadAngle = Vector2.new(180, 180),
				Rotation = NumberRange.new(0, 360),
				RotSpeed = NumberRange.new(-90, 90),
			}),
			Flare = emitter(att, {
				Color = gradient(Shared.Wind, Shared.Gold),
				Size = curve(5, 10),
				Transparency = curve(0.3, 1),
				Lifetime = NumberRange.new(0.15, 0.25),
				Speed = NumberRange.new(0),
				Rotation = NumberRange.new(0, 360),
			}),
		}
	end
	local hitIndex = 0

	 
	 
	 
	 
	local bandHost = quiet(ctx.Part(cast, "TornadoBandHost", CFrame.new(ctx.Root.Position), Vector3.one * 0.2, Shared.Wind, 1))
	local bands = table.create(BANDS)
	for b = 1, BANDS do
		local points, beams = table.create(BAND_POINTS), table.create(BAND_POINTS)
		for i = 1, BAND_POINTS do
			local att = Instance.new("Attachment")
			att.Parent = bandHost
			points[i] = att
		end
		local arc = 0.45 + (b % 3) * 0.12  
		local color = b % 2 == 0 and Shared.Gold or Shared.Wind
		for i = 1, BAND_POINTS - 1 do
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = points[i], points[i + 1]
			beam.FaceCamera = true
			beam.Segments = 1
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.Color = ColorSequence.new(color)
			 
			local t0, t1 = (i - 1) / (BAND_POINTS - 1), i / (BAND_POINTS - 1)
			beam.Transparency = NumberSequence.new(0.15 + 0.85 * (1 - math.sin(math.pi * t0)), 0.15 + 0.85 * (1 - math.sin(math.pi * t1)))
			beam.Width0 = 0.15 + 0.6 * math.sin(math.pi * t0)
			beam.Width1 = 0.15 + 0.6 * math.sin(math.pi * t1)
			beam.Parent = bandHost
			beams[i] = beam
		end
		bands[b] = { Points = points, Beams = beams, Arc = arc, Height = (b - 0.5) / BANDS, Speed = 9 + b * 1.7, Phase = b * 1.3 }
	end
	local scarAt = 0

	 
	 
	 
	 
	local lane, edges, laneFrom
	if opts.Lane then
		lane = quiet(ctx.Part(cast, "TornadoLane", ctx.Root.CFrame, Vector3.new(1, 0.06, 1), Shared.Aim, 1))
		lane.Material = Enum.Material.Neon
		edges = {}
		for i = 1, 2 do
			edges[i] = quiet(ctx.Part(cast, "TornadoLaneEdge", ctx.Root.CFrame, Vector3.new(1, 0.08, 1), Shared.Aim, 1))
			edges[i].Material = Enum.Material.Neon
		end
	end

	local function setLane(from, direction, alpha)
		local flat = Vector3.new(direction.X, 0, direction.Z)
		if flat.Magnitude < 0.01 or alpha >= 1 then
			lane.Transparency, edges[1].Transparency, edges[2].Transparency = 1, 1, 1
			return
		end
		flat = flat.Unit
		local length = opts.Range
		local middle = Vector3.new(from.X + flat.X * length / 2, floorY, from.Z + flat.Z * length / 2)
		lane.CFrame = CFrame.lookAt(middle, middle + flat)
		lane.Size = Vector3.new(radius * 2, 0.06, length)
		lane.Transparency = alpha
		local side = Vector3.new(-flat.Z, 0, flat.X) * radius
		local edgeAlpha = 1 - math.min(1, (1 - alpha) * 3)  
		for i, edge in ipairs(edges) do
			local position = middle + side * (i == 1 and 1 or -1)
			edge.CFrame = CFrame.lookAt(position, position + flat)
			edge.Size = Vector3.new(0.35, 0.08, length)
			edge.Transparency = edgeAlpha
		end
	end

	local view = {}

	 
	function view.Launch(center, heading)
		laneFrom = center
		launchLeaves:Emit(math.floor(40 + radius * 8))
		launchFlare:Emit(3)
		 
		local floorPos = Vector3.new(center.X, floorY, center.Z)
		FX.Shockwave(ctx, cast, CFrame.new(floorPos), radius, radius * 4, 0.5, Shared.Wind, 0.35)
		FX.Ring(ctx, cast, CFrame.new(floorPos) * CFrame.Angles(math.pi / 2, 0, 0), radius, radius * 3.2, 0.45, Shared.Light, 0, 0.7)
		FX.Ring(ctx, cast, CFrame.lookAt(center, center + heading), 3, radius * 2.2, 0.35, Shared.Gold, 0, 0.5)
		FX.Streaks(ctx, cast, center, heading, Shared.Light, Shared.Wind, 26, 25, 50, 100, 3)
		FX.Smoke(ctx, cast, floorPos, Shared.Dust, 8, 10, 26, 2)
		FX.Shake(ctx, center, 80, 0.4, 0.4)
	end

	function view.Hit(char)
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		hitIndex = hitIndex % HIT_BURSTS + 1
		local slot = hits[hitIndex]
		slot.Att.WorldPosition = root.Position
		slot.Leaves:Emit(28)
		slot.Gust:Emit(5)
		slot.Flare:Emit(1)
		 
		local pos = root.Position
		local spinA = CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, math.rad(35))
		local spinB = CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, math.rad(-35))
		FX.Crescent(ctx, cast, spinA * CFrame.new(0, 0, 3), 4.5, math.rad(150), 1.1, Shared.Light, Shared.Wind, 0.25)
		FX.Crescent(ctx, cast, spinB * CFrame.new(0, 0, 3), 4, math.rad(140), 0.9, Shared.Gold, Shared.Wind, 0.25, { Reverse = true })
		FX.Impact(ctx, cast, pos, Shared.Light, Shared.Wind, 0.8, { Shake = 0.35, Tint = 0.35 })
	end

	 
	function view.Update(center, age, direction)
		local launched = age >= windup
		local grow = windup > 0 and math.clamp(age / windup, 0, 1) or 1
		local scale = 0.35 + 0.65 * grow  
		local fade = math.clamp((age - windup - lifetime + 0.3) / 0.3, 0, 1)
		local alive = 1 - fade

		local height, drop = HEIGHT * scale, BASE_DROP * scale
		for i, leaf in ipairs(leaves) do
			local h = (i / count + age * 0.55) % 1
			local r = (baseR + (topR - baseR) * h) * scale
			local angle = i * 2.399963 + age * (11 + (i % 3) * 2.5)
			local pos = center + Vector3.new(math.cos(angle) * r, h * height - drop, math.sin(angle) * r)
			leaf.CFrame = CFrame.new(pos) * CFrame.Angles(math.sin(angle) * 0.5, -angle, age * 4 + i)
			leaf.Transparency = math.max(0.05 + 0.95 * fade, 0.6 * (1 - grow))
		end

		for i, layer in ipairs(layers) do
			local y = (-BASE_DROP + layerH * (i - 0.5)) * scale
			local width = layer.Half * 1.5 * scale
			layer.Part.Position = center + Vector3.new(0, y, 0)
			layer.Part.Size = Vector3.new(width, layerH * scale, width)
			layer.Air.Rate = layer.AirRate * grow * alive
			layer.Flecks.Rate = layer.FleckRate * grow * alive
		end

		 
		bandHost.Position = center
		for _, band in ipairs(bands) do
			local h = band.Height
			local r = ((baseR + (topR - baseR) * h) * 1.08 + 0.6) * scale
			local y = h * height - drop
			local start = band.Phase + age * band.Speed
			local sweep = math.pi * 2 * band.Arc
			local wobble = math.sin(age * 3 + band.Phase) * 0.8 * scale
			for i, att in ipairs(band.Points) do
				local a = start + sweep * (i - 1) / (BAND_POINTS - 1)
				att.Position = Vector3.new(math.cos(a) * r, y + wobble * math.sin(a), math.sin(a) * r)
			end
			local fadeBand = math.max(1 - grow * alive, 0)
			for _, beam in ipairs(band.Beams) do
				beam.Enabled = fadeBand < 0.95
			end
		end

		 
		if launched and alive > 0.2 and age - scarAt > 0.12 then
			scarAt = age
			local at = Vector3.new(center.X, floorY + 0.05, center.Z)
			local flat = Vector3.new(direction.X, 0, direction.Z)
			if flat.Magnitude > 0.01 then
				for side = -1, 1, 2 do
					local off = Vector3.new(-flat.Unit.Z, 0, flat.Unit.X) * radius * 0.45 * side
					local scar = FX.Temp(ctx, cast, "TornadoScar", CFrame.lookAt(at + off, at + off + flat),
						Vector3.new(0.5, 0.06, 7), Shared.Light, 0.35, 0.9)
					FX.Tween(scar, 0.85, { Size = Vector3.new(0.05, 0.06, 9), Transparency = 1 })
				end
			end
		end

		ground.Position = Vector3.new(center.X, floorY, center.Z)
		dust.Rate = (launched and 45 or 6 * grow) * alive
		rain.Rate = (launched and 16 or 0) * alive
		light.Brightness = (1 + math.random() * 0.6) * 2 * grow * alive

		if lane then
			local alpha
			if not launched then
				alpha = 0.85 - 0.25 * grow + 0.05 * math.sin(age * 24)
			else
				alpha = math.min(1, 0.6 + (age - windup) / 0.5 * 0.4)
			end
			setLane((launched and laneFrom) or center, direction, alpha)
		end
	end

	return view
end

return Visuals

 
local Visuals = {}
function Visuals.projectCube(ctx)
	local rotationSpeed = ctx.rotationSpeed
	local hypercubeVertices = ctx.hypercubeVertices
	local depthW = ctx.depthW
	local viewDistance = ctx.viewDistance
	local dimension = ctx.dimension
	local cubePoints = ctx.cubePoints
	local function projectCube(time)
		local projected, maxRadius = {}, 0
		 
		local a1 = time * rotationSpeed + math.sin(time * 0.9) * 0.7
		local a2 = time * rotationSpeed * 0.67 + math.sin(time * 0.6 + 1.3) * 0.6
		local a3 = time * rotationSpeed * 0.43 + math.sin(time * 1.1 + 2.6) * 0.5
		local cx, sx = math.cos(a1), math.sin(a1)
		local cy, sy = math.cos(a2), math.sin(a2)
		local cz, sz = math.cos(a3), math.sin(a3)
		for index, v in ipairs(hypercubeVertices) do
			local x, y, z, w = v[1], v[2], v[3], v[4]
			x, w = x * cx - w * sx, x * sx + w * cx
			y, w = y * cy - w * sy, y * sy + w * cy
			z, w = z * cz - w * sz, z * sz + w * cz
			depthW[index] = w
			local perspective = viewDistance / (viewDistance - w)
			local point = Vector3.new(x, y, z) * (dimension * 0.31 * perspective)
			projected[index] = point
			maxRadius = math.max(maxRadius, point.Magnitude)
		end
		local scale = math.min(1, dimension * 0.5 * math.sqrt(2) / math.max(maxRadius, 0.001))
		for index, point in ipairs(projected) do
			cubePoints[index].Position = point * scale
		end
	end
	return projectCube
end
function Visuals.Create(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local sky = ctx.sky
	local GOLD = ctx.GOLD
	local Effects = ctx.Effects
	local chargePull = ctx.chargePull
	local chargeAura = ctx.chargeAura
	local cubePoints = ctx.cubePoints
	local hypercubeVertices = ctx.hypercubeVertices
	local SPARKLE = ctx.SPARKLE
	local WHITE = ctx.WHITE
	local NSK = ctx.NSK
	local projectCube = ctx.projectCube
	local AXIS = ctx.AXIS
	local beams = ctx.beams
	local ring = ctx.ring
	local dimension = ctx.dimension
	local center = ctx.center
	local orbitRadius = ctx.orbitRadius
	local dome = ctx.dome
	local burst = ctx.burst
	local actor = ctx.actor
	local remote = ctx.remote
	local token = ctx.token
	local endsAt = ctx.endsAt
	local duration = ctx.duration
	local solid = ctx.solid
	local loop = ctx.loop
	local seg = ctx.seg
	local gimbals = ctx.gimbals
	local orbitHeight = ctx.orbitHeight
	local sparkle = ctx.sparkle
	local rise = ctx.rise
	local PALE = ctx.PALE
	local emberEmitter = ctx.emberEmitter
	local screen = ctx.screen
	local LETTERBOX = ctx.LETTERBOX
	local sfx = ctx.sfx
	local CUE = ctx.CUE
	local cube, cubeLease, heart, heartAttachment, heartLight, halo
	cube = cast:Add(core.Part("EtherealTesseractAnchor", sky, Vector3.one * 0.1, GOLD, 1))
	cubeLease = Effects.LeaseId(cube)
	 
	if chargePull then
		chargePull.Enabled = false
	end
	if chargeAura then
		Effects.ReleaseAfter(chargeAura, 1)
	end
	local points = {}
	for index = 0, 15 do
		local vertex = {
			bit32.band(index, 1) > 0 and 1 or -1,
			bit32.band(index, 2) > 0 and 1 or -1,
			bit32.band(index, 4) > 0 and 1 or -1,
			bit32.band(index, 8) > 0 and 1 or -1,
		}
		local a = Instance.new("Attachment")
		a.Parent = cube
		points[index + 1] = a
		cubePoints[index + 1] = a
		hypercubeVertices[index + 1] = vertex
		 
		local glow = Instance.new("ParticleEmitter")
		glow.Name = "VertexGlow"
		glow.Texture = SPARKLE
		glow.LockedToPart = true
		glow.Rate = 6
		glow.Speed = NumberRange.new(0)
		glow.Lifetime = NumberRange.new(0.4, 0.6)
		glow.LightEmission = 1
		glow.Color = ColorSequence.new(index % 2 == 0 and GOLD or WHITE)
		glow.Size = NumberSequence.new({ NSK(0, 0), NSK(0.3, 3.5), NSK(1, 0) })
		glow.Parent = a
	end
	projectCube(0)
	local edgeNumber = 0
	for index = 0, 15 do
		for bit = 0, 3 do
			local neighbor = bit32.bxor(index, 2 ^ bit)
			if neighbor > index then
				edgeNumber += 1
				local beam = Instance.new("Beam")
				beam.Name = "EtherealYellowWhiteCubeEdge"
				beam.Attachment0 = points[index + 1]
				beam.Attachment1 = points[neighbor + 1]
				beam.Width0 = 0
				beam.Width1 = 0
				beam.FaceCamera = true
				beam.LightEmission = 1
				beam.Segments = 1
				beam.Transparency = NumberSequence.new(0.1)
				beam.Color = ColorSequence.new(AXIS[bit + 1], index % 2 == 0 and WHITE or GOLD)  
				beam.Parent = cube
				table.insert(beams, {
					Beam = beam,
					Phase = edgeNumber,
					Base = bit == 3 and 1.3 or 0.8,
					A = index + 1,
					B = neighbor + 1,
				})
			end
		end
	end
	 
	heart = cast:Add(core.Part("EtherealHeart", CFrame.new(sky.Position), Vector3.one * 0.1, WHITE, 0))
	heart.Shape = Enum.PartType.Ball
	heart.Material = Enum.Material.Neon
	heartAttachment = Instance.new("Attachment")
	heartAttachment.Parent = heart
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 80
	light.Brightness = 5
	light.Parent = heart
	heartLight = light
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = SPARKLE
	sparks.Rate = 40
	sparks.Speed = NumberRange.new(10, 22)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 3
	sparks.Lifetime = NumberRange.new(0.6, 1.1)
	sparks.LightEmission = 1
	sparks.Color = ColorSequence.new(GOLD, WHITE)
	sparks.Size = NumberSequence.new({ NSK(0, 1.2), NSK(1, 0) })
	sparks.Parent = heart
	
	 
	ring(sky.Position, WHITE, 4, dimension * 1.6, 0.6, 0.8)
	ring(center + Vector3.new(0, 0.3, 0), GOLD, 4, orbitRadius * 2.4, 0.8, 0.6)
	ring(sky.Position, GOLD, 4, dimension * 2.4, 0.9, 0.5)
	dome(sky.Position, GOLD, 6, dimension * 2.2, 0.9)
	burst(sky.Position, 140, ColorSequence.new(GOLD, WHITE), 60, 1.1, 2.4)
	cube:SetAttribute("CubeDimension", dimension)
	cube:SetAttribute("RotationDimensions", 4)
	actor:SetAttribute("EtherealAcumenChargeActive", false)
	actor:SetAttribute("EtherealCubeStartedAt", workspace:GetServerTimeNow())
	actor:SetAttribute("AttackState", "Ethereal Acumen: welcome to my world")
	remote:FireAllClients(
		"EtherealAcumenStart",
		{ Token = token, Owner = actor, EndsAt = endsAt, Center = center, Duration = duration }
	)
	
	 
	local radii, planes = { 0.55, 0.65, 0.74 }, { "Y", "X", "Z" }
	for index = 1, 3 do
		local g = solid("EtherealArmillaryRing", sky, Vector3.one * 0.2, GOLD, 1)
		loop(g, dimension * radii[index], seg(40), AXIS[index], 0.35, planes[index], 0.1)
		gimbals[index] = g
	end
	 
	halo = solid(
		"EtherealOrbitHalo",
		CFrame.new(center + Vector3.new(0, orbitHeight, 0)),
		Vector3.one * 0.2,
		GOLD,
		1
	)
	local haloPoints = loop(halo, orbitRadius, seg(64), GOLD, 0.45, "Y", 0.3)
	for index = 0, 3 do
		local a = haloPoints[index * math.floor(#haloPoints / 4) + 1]
		local comet = sparkle(
			a,
			18,
			NumberRange.new(0.5, 0.8),
			NumberRange.new(0, 1),
			3.2,
			ColorSequence.new(WHITE, GOLD)
		)
		comet.Drag = 2
	end
	 
	local snowfall = solid(
		"EtherealStarfall",
		CFrame.new(center + Vector3.new(0, rise + 8, 0)),
		Vector3.new(orbitRadius * 2, 1, orbitRadius * 2),
		GOLD,
		1
	)
	local snow = sparkle(
		snowfall,
		45,
		NumberRange.new(8, 10),
		NumberRange.new(5, 8),
		0.9,
		ColorSequence.new(PALE, WHITE)
	)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.1, 0.1), NSK(0.85, 0.2), NSK(1, 1) })
	emberEmitter.Rate = 110
	
	core.PoseAngles(
		{ RightShoulder = { 170, 0, -20 }, LeftShoulder = { 170, 0, 20 }, Waist = { -16, 0, 0 } },
		0.12
	)
	screen("Grade", { State = "Reveal", Time = 0.35 })
	if LETTERBOX then
		screen("Letterbox", { On = false })
	end
	screen("Flash", { Strength = 0.9, Duration = 0.7 })
	screen("Shake", { Intensity = 1.1, Duration = 0.9, Origin = sky.Position, Radius = 420 })
	screen("Punch", { Amount = 12, Duration = 0.7 })
	sfx(CUE.Reveal, sky.Position)
	return cube, cubeLease, heart, heartAttachment, heartLight, halo
end
return table.freeze(Visuals)

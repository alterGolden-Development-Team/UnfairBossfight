local Visuals = {}
function Visuals.part(ctx)
	local core = ctx.core
	local function part(cast, name, size, color, alpha, material)
		local body = cast:Add(core.Part(name, CFrame.identity, size, color, alpha))
		body.Shape = Enum.PartType.Block  
		body.Material = material or Enum.Material.Neon
		body.CastShadow = false
		return body
	end
	return part
end
function Visuals.burstRing(ctx)
	local part = ctx.part
	local HALF_PI = ctx.HALF_PI
	local Effects = ctx.Effects
	local OUT = ctx.OUT
	local function burstRing(cast, frame, fromDiameter, toDiameter, color, alpha, duration)
		local ring = part(cast, "GoldenLanceShockRing", Vector3.new(0.18, fromDiameter, fromDiameter), color, alpha)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = frame * CFrame.Angles(0, HALF_PI, 0)
		Effects:Create(
			ring,
			TweenInfo.new(duration, OUT, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.18, toDiameter, toDiameter), Transparency = 1 }
		):Play()
		return ring
	end
	return burstRing
end
function Visuals.CreateSpear(ctx)
	local part = ctx.part
	local GOLD = ctx.GOLD
	local HALF_PI = ctx.HALF_PI
	local WHITE = ctx.WHITE
	local BRIGHT = ctx.BRIGHT
	local Effects = ctx.Effects
	local function CreateSpear(cast, frame, alpha)
		alpha = alpha or 0.05
		local pieces, extras, halos = {}, {}, {}
		local function clampAlpha(value)
			return math.clamp(value, 0, 1)
		end
		local function piece(name, size, color, offset, options)
			options = options or {}
			local bias = options.Bias or 0
			local body = part(cast, name, size, color, clampAlpha(alpha + bias), options.Material)
			if options.Wedge then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Wedge
				mesh.Parent = body
				extras[#extras + 1] = mesh
			elseif options.Shape then
				body.Shape = options.Shape
			end
			pieces[#pieces + 1] = { Body = body, Offset = offset, Bias = bias }
			return body
		end
		local NEON, METAL = Enum.Material.Neon, Enum.Material.Metal
	
		local shaft = piece(
			"GoldenLanceShaft",
			Vector3.new(21, 0.5, 0.5),
			GOLD,
			CFrame.new(0, 0, 13.5) * CFrame.Angles(0, HALF_PI, 0),
			{ Shape = Enum.PartType.Cylinder, Material = METAL }
		)
		piece("GoldenLancePiercingCore", Vector3.new(0.12, 0.12, 29), WHITE, CFrame.new(0, 0, 9.5), { Material = NEON })
	
		 
		local tip
		for index = 0, 3 do
			local bright = index % 2 == 0
			local body = piece(
				"GoldenLanceSpearhead" .. index,
				Vector3.new(0.42, 1.7, 9.5),
				bright and BRIGHT or GOLD,
				CFrame.new(0, 0, -1.3) * CFrame.Angles(0, 0, index * HALF_PI) * CFrame.new(0, 0.85, 0),
				{ Wedge = true, Material = bright and NEON or METAL }
			)
			tip = tip or body
		end
	
		 
		for index, info in ipairs({ { 4.2, 1.5, BRIGHT }, { 9.5, 1.0, GOLD }, { 17, 0.9, GOLD } }) do
			piece(
				"GoldenLanceCollar" .. index,
				Vector3.new(0.55, info[2], info[2]),
				info[3],
				CFrame.new(0, 0, info[1]) * CFrame.Angles(0, HALF_PI, 0),
				{ Shape = Enum.PartType.Cylinder, Material = METAL }
			)
		end
	
		 
		for side = -1, 1, 2 do
			piece(
				"GoldenLanceWing",
				Vector3.new(0.28, 3.4, 5.5),
				BRIGHT,
				CFrame.new(0, 0, 5.4)
					* CFrame.Angles(0, 0, side * HALF_PI)
					* CFrame.new(0, 1.7, 0)
					* CFrame.Angles(0, math.pi, 0),
				{ Wedge = true, Material = NEON, Bias = 0.04 }
			)
		end
		 
		for side = -1, 1, 2 do
			piece(
				"GoldenLanceFletching",
				Vector3.new(0.25, 2.2, 4.5),
				GOLD,
				CFrame.new(0, 0, 21) * CFrame.Angles(0, 0, side * HALF_PI) * CFrame.new(0, 1.1, 0),
				{ Wedge = true, Material = NEON, Bias = 0.08 }
			)
		end
		piece(
			"GoldenLanceButtPommel",
			Vector3.one * 1.1,
			BRIGHT,
			CFrame.new(0, 0, 24.5),
			{ Shape = Enum.PartType.Ball }
		)
		piece(
			"GoldenLanceHeartOrb",
			Vector3.one * 1.9,
			BRIGHT,
			CFrame.new(0, 0, 4.6),
			{ Shape = Enum.PartType.Ball, Bias = 0.25 }
		)
	
		 
		for index = 1, 2 do
			halos[index] = piece(
				"GoldenLanceStreamRing",
				Vector3.new(0.16, 2, 2),
				BRIGHT,
				CFrame.identity,
				{ Shape = Enum.PartType.Cylinder, Bias = 0.3 }
			)
		end
	
		local visual = { Shaft = shaft, Tip = tip, Pieces = pieces, Alpha = alpha }
		function visual:Draw(nextFrame)
			for _, item in ipairs(pieces) do
				item.Body.CFrame = nextFrame * item.Offset
			end
			local clock = os.clock()
			for index, ring in ipairs(halos) do
				local phase = (clock * 1.7 + index / #halos) % 1
				local diameter = 0.5 + 3.2 * math.sin(phase * math.pi)
				ring.Size = Vector3.new(0.16, diameter, diameter)
				ring.CFrame = nextFrame * CFrame.new(0, 0, 4 + phase * 18) * CFrame.Angles(0, HALF_PI, 0)
			end
		end
		function visual:Reveal(duration)
			self.Alpha = 0.05
			for _, item in ipairs(pieces) do
				Effects:Create(item.Body, TweenInfo.new(duration), { Transparency = clampAlpha(0.05 + item.Bias) })
					:Play()
			end
		end
		function visual:SetHidden(hidden)
			for _, item in ipairs(pieces) do
				item.Body.Transparency = hidden and 1 or clampAlpha(self.Alpha + item.Bias)
			end
		end
		function visual:AddExtra(instance)
			extras[#extras + 1] = instance
		end
		function visual:Cleanup()
			for _, extra in ipairs(extras) do
				if extra.Parent then
					extra:Destroy()
				end
			end
			table.clear(extras)
		end
		visual:Draw(frame)
		return visual
	end
	return CreateSpear
end
function Visuals.ribbon(ctx)
	local shaft = ctx.shaft
	local visual = ctx.visual
	local trails = ctx.trails
	local function ribbon(name, halfWidth, colorA, colorB, lifetime, startAlpha)
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(-10, halfWidth, 0), Vector3.new(-10, -halfWidth, 0)
		a0.Parent, a1.Parent = shaft, shaft
		local trail = Instance.new("Trail")
		trail.Name = name
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(colorA, colorB)
		trail.LightEmission = 1
		trail.Lifetime = lifetime
		trail.FaceCamera = true
		trail.MinLength = 0.05
		trail.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, startAlpha), NumberSequenceKeypoint.new(1, 1) })
		trail.Parent = shaft
		visual:AddExtra(a0)
		visual:AddExtra(a1)
		visual:AddExtra(trail)
		trails[#trails + 1] = trail
	end
	return ribbon
end
function Visuals.impactFx(ctx)
	local direction = ctx.direction
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local BRIGHT = ctx.BRIGHT
	local OUT = ctx.OUT
	local burstRing = ctx.burstRing
	local GOLD = ctx.GOLD
	local random = ctx.random
	local TweenService = ctx.TweenService
	local get_hitNormal = ctx.get_hitNormal
	local get_position = ctx.get_position
	local function impactFx()
		local normal = get_hitNormal() or -direction
		local impactFrame = CFrame.lookAt(get_position(), get_position() + normal)
		local flash = Effects.NewCast(actor, "GoldenLanceImpact", 0.8)
		local orb = part(flash, "GoldenLanceImpactFlash", Vector3.one * 3, BRIGHT, 0.06)
		orb.Shape = Enum.PartType.Ball
		orb.CFrame = CFrame.new(get_position())
		Effects:Create(
			orb,
			TweenInfo.new(0.35, OUT, Enum.EasingDirection.Out),
			{ Size = Vector3.one * 16, Transparency = 1 }
		):Play()
		burstRing(flash, impactFrame, 2, 26, BRIGHT, 0.08, 0.45)
		burstRing(flash, impactFrame, 1, 16, GOLD, 0.3, 0.6)
		for index = 1, 8 do
			local dir = (normal + Vector3.new(
				random:NextNumber(-1, 1),
				random:NextNumber(-1, 1),
				random:NextNumber(-1, 1)
			) * 0.9).Unit
			local shard =
				part(flash, "GoldenLanceShard", Vector3.new(0.3, 0.3, 3), index % 2 == 0 and GOLD or BRIGHT, 0.05)
			shard.CFrame = CFrame.lookAt(get_position(), get_position() + dir)
			local endPos = get_position() + dir * random:NextNumber(9, 18)
			Effects:Create(shard, TweenInfo.new(random:NextNumber(0.35, 0.6), OUT, Enum.EasingDirection.Out), {
				CFrame = CFrame.lookAt(endPos, endPos + dir),
				Size = Vector3.new(0.08, 0.08, 0.7),
				Transparency = 1,
			}):Play()
		end
		local glow = Instance.new("PointLight")
		glow.Color = GOLD
		glow.Brightness = 5
		glow.Range = 30
		glow.Shadows = false
		glow.Parent = orb
		TweenService:Create(glow, TweenInfo.new(0.5), { Brightness = 0 }):Play()
		local burst = Instance.new("ParticleEmitter")
		burst.Enabled = false
		burst.Color = ColorSequence.new(BRIGHT, GOLD)
		burst.LightEmission = 1
		burst.Lifetime = NumberRange.new(0.3, 0.6)
		burst.Speed = NumberRange.new(14, 30)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Drag = 3
		burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		burst.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		burst.Parent = orb
		burst:Emit(28)
		task.delay(1, function()
			if glow.Parent then
				glow:Destroy()
			end
			if burst.Parent then
				burst:Destroy()
			end
		end)
	end
	return impactFx
end
return table.freeze(Visuals)

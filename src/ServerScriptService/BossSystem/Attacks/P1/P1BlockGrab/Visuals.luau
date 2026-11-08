local Visuals = {}
function Visuals.disc(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local function disc(position, startDiameter, endDiameter, duration, color, startAlpha)
		local d = core.Part(
			"BlockGrabShockDisc",
			CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.2, startDiameter, startDiameter),
			color,
			startAlpha or 0.4
		)
		d.Shape = Enum.PartType.Cylinder
		d.Material = Enum.Material.Neon
		Effects:Create(
			d,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.2, endDiameter, endDiameter), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(d, duration + 0.05)
	end
	return disc
end
function Visuals.glowBall(ctx)
	local core = ctx.core
	local BRIGHT = ctx.BRIGHT
	local Effects = ctx.Effects
	local function glowBall(position, size, duration, color)
		local f = core.Part("BlockGrabGlowBall", CFrame.new(position), Vector3.one * size * 0.25, color or BRIGHT, 0.1)
		f.Shape = Enum.PartType.Ball
		f.Material = Enum.Material.Neon
		Effects:Create(
			f,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * size, Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(f, duration + 0.05)
	end
	return glowBall
end
function Visuals.bolt(ctx)
	local random = ctx.random
	local core = ctx.core
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local function bolt(from, to, spread, width, segmentCount, fade)
		local dir = to - from
		local len = dir.Magnitude
		if len < 1 then
			return
		end
		local unit = dir / len
		local side = unit:Cross(Vector3.yAxis)
		side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
		local up = side:Cross(unit)
		local segments = segmentCount or math.clamp(math.floor(len / 2.5), 2, 8)
		local prev = from
		for i = 1, segments do
			local point = from + dir * (i / segments)
			if i < segments then
				point += side * random:NextNumber(-spread, spread) + up * random:NextNumber(-spread, spread) * 0.4
			end
			core.MotionLine("BlockGrabCrack", prev, point, width or 0.2, i % 2 == 0 and BRIGHT or GOLD, fade or 0.3)
			prev = point
		end
	end
	return bolt
end
function Visuals.radial(ctx)
	local random = ctx.random
	local core = ctx.core
	local GOLD = ctx.GOLD
	local BRIGHT = ctx.BRIGHT
	local function radial(center, axisA, axisB, count, inner, outer, width, fade)
		for i = 1, count do
			local angle = i / count * math.pi * 2 + random:NextNumber(-0.08, 0.08)
			local d = axisA * math.cos(angle) + axisB * math.sin(angle)
			core.MotionLine(
				"BlockGrabRay",
				center + d * inner,
				center + d * outer * random:NextNumber(0.7, 1.1),
				width,
				i % 2 == 0 and GOLD or BRIGHT,
				fade
			)
		end
	end
	return radial
end
function Visuals.fountain(ctx)
	local core = ctx.core
	local GOLD = ctx.GOLD
	local BRIGHT = ctx.BRIGHT
	local Effects = ctx.Effects
	local function fountain(position, count)
		local anchor = core.Part("BlockGrabEmberBurst", CFrame.new(position), Vector3.new(1, 0.2, 1), GOLD, 1)
		local e = Instance.new("ParticleEmitter")
		e.Name = "BlockGrabFountain"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(BRIGHT, GOLD)
		e.LightEmission = 1
		e.Rate = 0
		e.EmissionDirection = Enum.NormalId.Top
		e.SpreadAngle = Vector2.new(35, 35)
		e.Lifetime = NumberRange.new(0.6, 1.2)
		e.Speed = NumberRange.new(12, 26)
		e.Acceleration = Vector3.new(0, -30, 0)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = anchor
		e:Emit(count)
		Effects.ReleaseAfter(anchor, 1.6)
	end
	return fountain
end
function Visuals.dustPuff(ctx)
	local core = ctx.core
	local EARTH = ctx.EARTH
	local DUST = ctx.DUST
	local Effects = ctx.Effects
	local function dustPuff(position, count)
		local anchor = core.Part(
			"BlockGrabDustBurst",
			CFrame.new(position + Vector3.new(0, 0.5, 0)),
			Vector3.new(1, 0.2, 1),
			EARTH,
			1
		)
		local e = Instance.new("ParticleEmitter")
		e.Name = "BlockGrabDustPuff"
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(DUST, EARTH)
		e.Rate = 0
		e.EmissionDirection = Enum.NormalId.Top
		e.SpreadAngle = Vector2.new(75, 75)
		e.Lifetime = NumberRange.new(0.6, 1.2)
		e.Speed = NumberRange.new(8, 18)
		e.Drag = 2.5
		e.Acceleration = Vector3.new(0, -2, 0)
		e.Rotation = NumberRange.new(0, 360)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		e.Parent = anchor
		e:Emit(count)
		Effects.ReleaseAfter(anchor, 1.6)
	end
	return dustPuff
end
function Visuals.debris(ctx)
	local random = ctx.random
	local core = ctx.core
	local GOLD = ctx.GOLD
	local EARTH = ctx.EARTH
	local Effects = ctx.Effects
	local function debris(position, count)
		for i = 1, count do
			local direction = Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1))
			direction = direction.Magnitude > 0.1 and direction.Unit or Vector3.xAxis
			local size = random:NextNumber(0.8, 1.9)
			local gilded = i % 3 == 0
			local startPos = position + Vector3.new(0, 0.8, 0)
			local piece = core.Part(
				"BlockGrabDebris",
				CFrame.new(startPos) * CFrame.Angles(random:NextNumber(0, 3), random:NextNumber(0, 3), 0),
				Vector3.one * size,
				gilded and GOLD or EARTH,
				0
			)
			piece.Material = gilded and Enum.Material.Neon or Enum.Material.Slate
			local spin = piece.CFrame.Rotation
			local apex = startPos + direction * random:NextNumber(4, 10) + Vector3.new(0, random:NextNumber(7, 14), 0)
			local landing = position + direction * random:NextNumber(9, 18) + Vector3.new(0, 0.5, 0)
			Effects:Create(
				piece,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = CFrame.new(apex) * spin * CFrame.Angles(1.2, 0.8, 0) }
			):Play()
			Effects:Create(
				piece,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.25),
				{ CFrame = CFrame.new(landing) * spin * CFrame.Angles(2.4, 1.6, 0), Transparency = 1 }
			):Play()
			Effects.ReleaseAfter(piece, 0.7)
		end
	end
	return debris
end
function Visuals.chunk(ctx)
	local random = ctx.random
	local core = ctx.core
	local EARTH = ctx.EARTH
	local GOLD = ctx.GOLD
	local BRIGHT = ctx.BRIGHT
	local DUST = ctx.DUST
	local function chunk(cast, frame)
		local size = Vector3.new(random:NextNumber(5.5, 7), random:NextNumber(3.8, 5.2), random:NextNumber(5.5, 7))
		local body = cast:Add(core.Part("BlockGrabEarthChunk", frame, size, EARTH, 0))
		body.Material = Enum.Material.Slate
		local outline = Instance.new("Highlight")
		outline.Name = "GoldenBlockGrabEnergy"
		outline.Adornee = body
		outline.FillColor = GOLD
		outline.FillTransparency = 0.9
		outline.OutlineColor = BRIGHT
		outline.OutlineTransparency = 0.1
		outline.DepthMode = Enum.HighlightDepthMode.Occluded
		outline.Parent = body
		 
		local light = Instance.new("PointLight")
		light.Name = "BlockGrabGlow"
		light.Color = GOLD
		light.Brightness = 0.8
		light.Range = 12
		light.Parent = body
		local dust = Instance.new("ParticleEmitter")
		dust.Name = "BlockGrabDust"
		dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
		dust.Color = ColorSequence.new(DUST, EARTH)
		dust.Rate = 0
		dust.Lifetime = NumberRange.new(0.5, 1)
		dust.Speed = NumberRange.new(1, 4)
		dust.SpreadAngle = Vector2.new(180, 180)
		dust.Rotation = NumberRange.new(0, 360)
		dust.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(0.5, 3.5),
			NumberSequenceKeypoint.new(1, 5),
		})
		dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		dust.Parent = body
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "BlockGrabSparks"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(BRIGHT, GOLD)
		sparks.LightEmission = 1
		sparks.Rate = 0
		sparks.Lifetime = NumberRange.new(0.3, 0.7)
		sparks.Speed = NumberRange.new(4, 10)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
		sparks.Parent = body
		return body
	end
	return chunk
end
function Visuals.setChunkEmission(ctx)
	local function setChunkEmission(body, dustRate, sparkRate)
		local dust = body:FindFirstChild("BlockGrabDust")
		if dust then
			dust.Rate = dustRate
		end
		local sparks = body:FindFirstChild("BlockGrabSparks")
		if sparks then
			sparks.Rate = sparkRate
		end
	end
	return setChunkEmission
end
function Visuals.startAimVfx(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local core = ctx.core
	local GOLD = ctx.GOLD
	local BRIGHT = ctx.BRIGHT
	local random = ctx.random
	local function startAimVfx(body, duration)
		local vcast = Effects.NewCast(actor, "BlockGrabAimVfx", duration + 1)
		local outline = body:FindFirstChild("GoldenBlockGrabEnergy")
		local light = body:FindFirstChild("BlockGrabGlow")
		local orbs = {}
		for i = 1, 4 do
			local orb = vcast:Add(
				core.Part(
					"BlockGrabOrbit",
					CFrame.new(body.Position),
					Vector3.one * 0.8,
					i % 2 == 0 and GOLD or BRIGHT,
					0.1
				)
			)
			orb.Shape = Enum.PartType.Ball
			orb.Material = Enum.Material.Neon
			orbs[i] = orb
		end
		local elapsed, timer = 0, 0
		vcast:Step(function(dt)
			if not body.Parent then
				return false
			end
			elapsed += dt
			local progress = math.clamp(elapsed / duration, 0, 1)
			if outline then
				outline.FillTransparency = math.clamp(0.9 - 0.55 * progress + 0.05 * math.sin(elapsed * 18), 0, 1)
			end
			if light then
				light.Brightness = 0.8 + 4 * progress
				light.Range = 12 + 10 * progress
			end
			local radius = body.Size.Magnitude * 0.5 + 1.5
			for i, orb in ipairs(orbs) do
				local angle = elapsed * (5 + progress * 5) + i * math.pi / 2
				orb.CFrame = CFrame.new(
					body.Position
						+ Vector3.new(
							math.cos(angle) * radius,
							math.sin(elapsed * 4 + i) * 1.2,
							math.sin(angle) * radius
						)
				)
			end
			timer += dt
			if timer >= 0.06 then
				timer = 0
				for _ = 1, 1 + math.floor(progress * 2) do
					local dir =
						Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-0.4, 1), random:NextNumber(-1, 1))
					dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.yAxis
					local distance = random:NextNumber(6, 10) * (1 - progress * 0.3)
					core.MotionLine(
						"BlockGrabAimStreak",
						body.Position + dir * distance,
						body.Position + dir * distance * 0.25,
						0.1 + progress * 0.1,
						random:NextNumber() > 0.5 and GOLD or BRIGHT,
						0.18
					)
				end
				core.MotionLine(
					"BlockGrabTether",
					core.Root.Position + Vector3.new(0, 1, 0),
					body.Position,
					0.15,
					GOLD,
					0.12
				)
			end
			return true
		end)
		return vcast
	end
	return startAimVfx
end
return table.freeze(Visuals)

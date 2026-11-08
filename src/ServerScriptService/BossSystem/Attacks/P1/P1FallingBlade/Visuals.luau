local Visuals = {}
function Visuals.disc(ctx)
	local part = ctx.part
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function disc(position, startDiameter, endDiameter, duration, color, startAlpha)
		local d = part(
			"FallingBladeShockDisc",
			CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.25, startDiameter, startDiameter),
			color,
			startAlpha or 0.4
		)
		d.Shape = Enum.PartType.Cylinder
		d.Material = Enum.Material.Neon
		Tween:Create(
			d,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.25, endDiameter, endDiameter), Transparency = 1 }
		):Play()
		Debris:AddItem(d, duration + 0.05)
	end
	return disc
end
function Visuals.glowBall(ctx)
	local part = ctx.part
	local bright = ctx.bright
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function glowBall(position, size, duration, color)
		local f = part(
			"FallingBladeGlowBall",
			CFrame.new(position),
			Vector3.new(size * 0.25, size * 0.25, size * 0.25),
			color or bright,
			0.1
		)
		f.Shape = Enum.PartType.Ball
		f.Material = Enum.Material.Neon
		Tween:Create(
			f,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(size, size, size), Transparency = 1 }
		):Play()
		Debris:AddItem(f, duration + 0.05)
	end
	return glowBall
end
function Visuals.bolt(ctx)
	local rng = ctx.rng
	local motionLine = ctx.motionLine
	local bright = ctx.bright
	local gold = ctx.gold
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
				point += side * rng:NextNumber(-spread, spread) + up * rng:NextNumber(-spread, spread) * 0.4
			end
			motionLine("FallingBladeCrack", prev, point, width or 0.2, i % 2 == 0 and bright or gold, fade or 0.3)
			prev = point
		end
	end
	return bolt
end
function Visuals.radial(ctx)
	local rng = ctx.rng
	local motionLine = ctx.motionLine
	local gold = ctx.gold
	local bright = ctx.bright
	local function radial(center, axisA, axisB, count, inner, outer, width, fade)
		for i = 1, count do
			local angle = i / count * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
			local d = axisA * math.cos(angle) + axisB * math.sin(angle)
			motionLine(
				"FallingBladeRay",
				center + d * inner,
				center + d * outer * rng:NextNumber(0.7, 1.1),
				width,
				i % 2 == 0 and gold or bright,
				fade
			)
		end
	end
	return radial
end
function Visuals.fountain(ctx)
	local part = ctx.part
	local gold = ctx.gold
	local bright = ctx.bright
	local Debris = ctx.Debris
	local function fountain(position, count)
		local anchor = part("FallingBladeEmberBurst", CFrame.new(position), Vector3.new(1, 0.2, 1), gold, 1)
		local e = Instance.new("ParticleEmitter")
		e.Name = "FallingBladeFountain"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(bright, gold)
		e.LightEmission = 1
		e.Rate = 0
		e.EmissionDirection = Enum.NormalId.Top
		e.SpreadAngle = Vector2.new(35, 35)
		e.Lifetime = NumberRange.new(0.7, 1.4)
		e.Speed = NumberRange.new(16, 34)
		e.Acceleration = Vector3.new(0, -32, 0)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = anchor
		e:Emit(count)
		Debris:AddItem(anchor, 1.8)
	end
	return fountain
end
function Visuals.CreateShockwave(ctx)
	local Audio = ctx.Audio
	local actor = ctx.actor
	local b = ctx.b
	local Effects = ctx.Effects
	local part = ctx.part
	local gold = ctx.gold
	local bright = ctx.bright
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local glowBall = ctx.glowBall
	local deepGold = ctx.deepGold
	local disc = ctx.disc
	local radial = ctx.radial
	local rng = ctx.rng
	local bolt = ctx.bolt
	local fountain = ctx.fountain
	local function CreateShockwave(center)
		Audio.Emit(actor, "FallingImpact", center)
		Audio.Emit(actor, "FallingWave", center)
		local wave = {
			center = center,
			radius = b:GetAttribute("FallingBladeRadius") or 225,
			pieces = {},
			previous = 0,
			hit = {},
			height = b:GetAttribute("FallingWaveHeight") or 10,
			segments = 48,
			duration = b:GetAttribute("FallingWaveDuration") or 1.5,
		}
		wave.cast = Effects.NewCast(actor, "FallingBladeShockwave", wave.duration + 0.25)
		local segments = wave.segments
		for i = 0, segments - 1 do
			local angle = 2 * math.pi * (i + 0.5) / segments
			local p = part("FallingBladeGoldenRing", CFrame.new(center), Vector3.new(0.1, 0.35, 0.1), gold, 0.04)
			local edge = part("FallingBladeWhiteEdge", CFrame.new(center), Vector3.new(0.1, 0.2, 0.1), bright, 0.05)
			p.Material = Enum.Material.Neon
			edge.Material = Enum.Material.Neon
			 
			if i % 4 == 0 then
				local trail = Instance.new("ParticleEmitter")
				trail.Name = "FallingWaveEmbers"
				trail.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				trail.Color = ColorSequence.new(bright, gold)
				trail.LightEmission = 1
				trail.EmissionDirection = Enum.NormalId.Top
				trail.SpreadAngle = Vector2.new(40, 40)
				trail.Lifetime = NumberRange.new(0.5, 1)
				trail.Speed = NumberRange.new(6, 14)
				trail.Rate = 30
				trail.Acceleration = Vector3.new(0, 4, 0)
				trail.Size =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
				trail.Parent = p
			end
			table.insert(wave.pieces, { p = p, edge = edge, angle = angle })
			wave.cast:Add(p)
			wave.cast:Add(edge)
		end
		 
		local floorGlow = part(
			"FallingBladeWaveFloor",
			CFrame.new(center + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.2, 2, 2),
			gold,
			0.8
		)
		floorGlow.Shape = Enum.PartType.Cylinder
		floorGlow.Material = Enum.Material.Neon
		wave.floor = wave.cast:Add(floorGlow)
		 
		local impactFlash =
			part("FallingBladeImpact", CFrame.new(center + Vector3.new(0, 1.5, 0)), Vector3.new(2, 2, 2), bright, 0.2)
		impactFlash.Shape = Enum.PartType.Ball
		impactFlash.Material = Enum.Material.Neon
		Tween:Create(impactFlash, TweenInfo.new(0.3), { Size = Vector3.new(22, 8, 22), Transparency = 1 }):Play()
		Debris:AddItem(impactFlash, 0.35)
		glowBall(center + Vector3.new(0, 4, 0), 30, 0.4, deepGold)
		glowBall(center + Vector3.new(0, 4, 0), 16, 0.25, bright)
		local ground = center + Vector3.new(0, 0.2, 0)
		disc(ground, 6, 130, 0.6, gold, 0.3)
		disc(ground, 4, 80, 0.45, bright, 0.15)
		disc(ground, 2, 200, 0.9, deepGold, 0.55)
		 
		local pillar =
			part("FallingBladePillar", CFrame.new(center + Vector3.new(0, 30, 0)), Vector3.new(7, 60, 7), bright, 0.2)
		pillar.Material = Enum.Material.Neon
		Tween:Create(
			pillar,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = CFrame.new(center + Vector3.new(0, 55, 0)), Size = Vector3.new(2, 110, 2), Transparency = 1 }
		):Play()
		Debris:AddItem(pillar, 0.55)
		 
		radial(ground, Vector3.xAxis, Vector3.zAxis, 28, 6, 50, 0.35, 0.4)
		for i = 1, 12 do
			local angle = i / 12 * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
			local d = Vector3.new(math.cos(angle), 0, math.sin(angle))
			bolt(ground + d * 4, ground + d * rng:NextNumber(40, 70), 2.5, 0.3, 8, 0.45)
		end
		 
		fountain(ground, 45)
		for i = 1, 8 do
			local angle = i / 8 * math.pi * 2
			fountain(ground + Vector3.new(math.cos(angle) * 9, 0, math.sin(angle) * 9), 18)
		end
		 
		for i = 1, 18 do
			local angle = i * math.pi * 2 / 18
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local shard =
				part("GoldenImpactSpark", CFrame.new(center + direction * 3), Vector3.new(0.45, 2.5, 0.45), gold, 0.1)
			shard.Material = Enum.Material.Neon
			Tween:Create(
				shard,
				TweenInfo.new(0.4),
				{ CFrame = shard.CFrame + direction * 14 + Vector3.new(0, 5, 0), Transparency = 1 }
			):Play()
			Debris:AddItem(shard, 0.45)
		end
		 
		for i = 1, 10 do
			local angle = rng:NextNumber(0, math.pi * 2)
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local size = rng:NextNumber(1.2, 2.4)
			local startPos = center + direction * rng:NextNumber(2, 5) + Vector3.new(0, 0.8, 0)
			local chunk = part(
				"FallingBladeChunk",
				CFrame.new(startPos) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
				Vector3.new(size, size, size),
				i % 2 == 0 and gold or deepGold,
				0.05
			)
			chunk.Material = Enum.Material.Neon
			local apex = startPos + direction * rng:NextNumber(8, 16) + Vector3.new(0, rng:NextNumber(14, 26), 0)
			local landing = startPos + direction * rng:NextNumber(18, 32)
			Tween:Create(
				chunk,
				TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = CFrame.new(apex) * chunk.CFrame.Rotation * CFrame.Angles(1.5, 1, 0) }
			):Play()
			Tween:Create(
				chunk,
				TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.28),
				{ CFrame = CFrame.new(landing) * chunk.CFrame.Rotation, Transparency = 1 }
			):Play()
			Debris:AddItem(chunk, 0.7)
		end
		b:SetAttribute("FallingShockwaves", (b:GetAttribute("FallingShockwaves") or 0) + 1)
		return wave
	end
	return CreateShockwave
end
function Visuals.riseTrail(ctx)
	local motionLine = ctx.motionLine
	local deepGold = ctx.deepGold
	local gold = ctx.gold
	local bright = ctx.bright
	local function riseTrail(from, to)
		motionLine("FallingBladeRiseGlow", from, to, 2, deepGold, 0.3)
		motionLine("FallingBladeRiseTrail", from, to, 1, gold, 0.35)
		motionLine("FallingBladeRiseCore", from, to, 0.25, bright, 0.3)
	end
	return riseTrail
end
function Visuals.slamTrail(ctx)
	local motionLine = ctx.motionLine
	local deepGold = ctx.deepGold
	local gold = ctx.gold
	local bright = ctx.bright
	local bolt = ctx.bolt
	local function slamTrail(from, to)
		motionLine("FallingBladeSlamGlow", from, to, 4.5, deepGold, 0.3)
		motionLine("FallingBladeSlamTrail", from, to, 2, gold, 0.35)
		motionLine("FallingBladeSlamCore", from, to, 0.5, bright, 0.3)
		bolt(from, to, 1.6, 0.2, 3, 0.2)
	end
	return slamTrail
end
function Visuals.DownwardPose(ctx)
	local core = ctx.core
	local function DownwardPose(duration)
		local pose = {
			RightShoulder = { 10, 0, -12 },
			RightElbow = { 5, 0, 0 },
			RightWrist = { -75, 0, 0 },
			Waist = { 15, 0, 0 },
			LeftShoulder = { -15, 0, -20 },
			LeftElbow = { 35, 0, 0 },
			LeftHip = { -15, 0, 0 },
			RightHip = { 18, 0, 0 },
		}
		core.PoseAngles(pose, duration)
	end
	return DownwardPose
end
return table.freeze(Visuals)

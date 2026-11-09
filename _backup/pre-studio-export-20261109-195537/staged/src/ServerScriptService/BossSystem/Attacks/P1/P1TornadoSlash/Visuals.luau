local Visuals = {}
function Visuals.key(ctx)
	local function key(time, value)
		return NumberSequenceKeypoint.new(time, value)
	end
	return key
end
function Visuals.shake(ctx)
	local core = ctx.core
	local function shake(origin, radius, duration, intensity)
		if core.ScreenEffect then
			core.ScreenEffect("Shake", { Origin = origin, Radius = radius, Duration = duration, Intensity = intensity })
		end
	end
	return shake
end
function Visuals.sparkBurst(ctx)
	local core = ctx.core
	local gold = ctx.gold
	local SPARKLE = ctx.SPARKLE
	local bright = ctx.bright
	local key = ctx.key
	local Debris = ctx.Debris
	local function sparkBurst(position, count, speedMin, speedMax)
		local anchor = core.Part("GoldenTornadoSparkBurst", CFrame.new(position), Vector3.one * 0.2, gold, 1)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "GoldenTornadoSparks"
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(bright, gold)
		emitter.LightEmission = 1
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.25, 0.55)
		emitter.Speed = NumberRange.new(speedMin or 12, speedMax or 28)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Acceleration = Vector3.new(0, -18, 0)
		emitter.Size = NumberSequence.new({ key(0, 0.55), key(1, 0) })
		emitter.Transparency = NumberSequence.new({ key(0, 0.1), key(1, 1) })
		emitter.Parent = anchor
		emitter:Emit(count)
		Debris:AddItem(anchor, 0.8)
	end
	return sparkBurst
end
function Visuals.dustBurst(ctx)
	local core = ctx.core
	local dust = ctx.dust
	local SMOKE = ctx.SMOKE
	local key = ctx.key
	local Debris = ctx.Debris
	local function dustBurst(position, size, count)
		local anchor = core.Part("GoldenTornadoDustBurst", CFrame.new(position), Vector3.one * 0.2, dust, 1)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "GoldenTornadoDust"
		emitter.Texture = SMOKE
		emitter.Color = ColorSequence.new(dust)
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(10, 24)
		emitter.SpreadAngle = Vector2.new(88, 88)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.new(0, -8, 0)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-70, 70)
		emitter.Size = NumberSequence.new({ key(0, size * 0.4), key(1, size) })
		emitter.Transparency = NumberSequence.new({ key(0, 0.55), key(1, 1) })
		emitter.Parent = anchor
		emitter:Emit(count)
		Debris:AddItem(anchor, 1.2)
	end
	return dustBurst
end
function Visuals.flashBall(ctx)
	local core = ctx.core
	local bright = ctx.bright
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function flashBall(position, scale, duration, color)
		local ball =
			core.Part("GoldenTornadoFlash", CFrame.new(position), Vector3.one * scale * 0.3, color or bright, 0.1)
		ball.Shape = Enum.PartType.Ball
		Tween:Create(
			ball,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * scale, Transparency = 1 }
		):Play()
		Debris:AddItem(ball, duration + 0.05)
	end
	return flashBall
end
function Visuals.floorDisc(ctx)
	local core = ctx.core
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function floorDisc(position, from, to, duration, color, alpha, easing)
		local disc = core.Part(
			"GoldenTornadoDisc",
			CFrame.new(position) * CFrame.Angles(0, 0, math.pi * 0.5),
			Vector3.new(0.1, from, from),
			color,
			alpha
		)
		disc.Shape = Enum.PartType.Cylinder
		Tween:Create(
			disc,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, easing or Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.1, to, to), Transparency = 1 }
		):Play()
		Debris:AddItem(disc, duration + 0.05)
	end
	return floorDisc
end
function Visuals.HitFx(ctx)
	local flashBall = ctx.flashBall
	local bright = ctx.bright
	local sparkBurst = ctx.sparkBurst
	local function HitFx(position)
		flashBall(position, 6, 0.16, bright)
		sparkBurst(position, 10, 12, 26)
	end
	return HitFx
end
function Visuals.ChargeFx(ctx)
	local root = ctx.root
	local groundAt = ctx.groundAt
	local floorDisc = ctx.floorDisc
	local gold = ctx.gold
	local SPARKLE = ctx.SPARKLE
	local bright = ctx.bright
	local key = ctx.key
	local function ChargeFx(duration)
		local position = root.Position
		local floor = groundAt(position)
		floorDisc(
			Vector3.new(position.X, floor + 0.2, position.Z),
			30,
			4,
			duration,
			gold,
			0.45,
			Enum.EasingDirection.In
		)
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "GoldenTornadoGather"
		aura.Texture = SPARKLE
		aura.Color = ColorSequence.new(bright, gold)
		aura.LightEmission = 1
		aura.Rate = 70
		aura.Lifetime = NumberRange.new(0.3, 0.6)
		aura.Speed = NumberRange.new(3, 10)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Acceleration = Vector3.new(0, 8, 0)
		aura.Size = NumberSequence.new({ key(0, 0.5), key(1, 0) })
		aura.Transparency = NumberSequence.new({ key(0, 0.1), key(1, 1) })
		aura.Parent = root
		task.delay(duration, function()
			if aura.Parent then
				aura.Enabled = false
				task.delay(0.8, function()
					if aura.Parent then
						aura:Destroy()
					end
				end)
			end
		end)
	end
	return ChargeFx
end
function Visuals.PassBurst(ctx)
	local groundAt = ctx.groundAt
	local floorDisc = ctx.floorDisc
	local amber = ctx.amber
	local dustBurst = ctx.dustBurst
	local flashBall = ctx.flashBall
	local bright = ctx.bright
	local sparkBurst = ctx.sparkBurst
	local shake = ctx.shake
	local function PassBurst(position, finishing)
		local floor = groundAt(position)
		local base = Vector3.new(position.X, floor, position.Z)
		floorDisc(base + Vector3.new(0, 0.25, 0), 6, finishing and 26 or 34, 0.4, amber, 0.3)
		dustBurst(base + Vector3.new(0, 0.4, 0), finishing and 6 or 8, finishing and 10 or 14)
		flashBall(position, finishing and 9 or 12, 0.22, bright)
		sparkBurst(position, finishing and 14 or 22, 14, 30)
		shake(position, 70, 0.16, finishing and 0.22 or 0.32)
	end
	return PassBurst
end
function Visuals.addBeam(ctx)
	local get_ringBeams = ctx.get_ringBeams
	local function addBeam(parent, a0, a1, width0, width1, colorA, colorB, alphaA, alphaB, emission)
		local beam = Instance.new("Beam")
		beam.Name = "GoldenTornadoBeam"
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = width0
		beam.Width1 = width1
		beam.FaceCamera = true
		beam.Segments = 1
		beam.LightEmission = emission
		beam.Color = ColorSequence.new(colorA, colorB)
		beam.Transparency = NumberSequence.new(alphaA, alphaB)
		beam.Parent = parent
		table.insert(get_ringBeams(), { Beam = beam, A0 = alphaA, A1 = alphaB })
		return beam
	end
	return addBeam
end
return table.freeze(Visuals)

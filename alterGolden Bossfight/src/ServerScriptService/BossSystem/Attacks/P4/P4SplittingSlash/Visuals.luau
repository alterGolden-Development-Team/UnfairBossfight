local Visuals = {}
function Visuals.key(ctx)
	local function key(time, value)
		return NumberSequenceKeypoint.new(time, value)
	end
	return key
end
function Visuals.shake(ctx)
	local core = ctx.core
	local function shake(origin, duration, intensity)
		if core.ScreenEffect then
			core.ScreenEffect("Shake", { Origin = origin, Radius = 180, Duration = duration, Intensity = intensity })
		end
	end
	return shake
end
function Visuals.disc(ctx)
	local core = ctx.core
	local function disc(owner, position, diameter, color, alpha)
		local piece = owner:Add(
			core.Part(
				"SplittingSlashDisc",
				CFrame.new(position) * CFrame.Angles(0, 0, math.pi * 0.5),
				Vector3.new(0.1, diameter, diameter),
				color,
				alpha
			)
		)
		piece.Shape = Enum.PartType.Cylinder
		piece.Material = Enum.Material.Neon
		return piece
	end
	return disc
end
function Visuals.pulse(ctx)
	local disc = ctx.disc
	local Effects = ctx.Effects
	local function pulse(owner, position, from, to, duration, color, alpha)
		local wave = disc(owner, position, from, color, alpha)
		Effects:Create(
			wave,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.1, to, to), Transparency = 1 }
		):Play()
		owner:Schedule(duration + 0.05, function()
			Effects.Release(wave)
		end)
	end
	return pulse
end
function Visuals.sparkEmitter(ctx)
	local SPARKLE = ctx.SPARKLE
	local key = ctx.key
	local function sparkEmitter(parent, color, glow, speedMin, speedMax, spread)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "SplittingSlashSparks"
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(color, glow)
		emitter.LightEmission = 0.6
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.3, 0.65)
		emitter.Speed = NumberRange.new(speedMin, speedMax)
		emitter.SpreadAngle = Vector2.new(spread, spread)
		emitter.Acceleration = Vector3.new(0, -20, 0)
		emitter.Size = NumberSequence.new({ key(0, 0.5), key(1, 0) })
		emitter.Transparency = NumberSequence.new({ key(0, 0.1), key(1, 1) })
		emitter.Parent = parent
		return emitter
	end
	return sparkEmitter
end
function Visuals.dustEmitter(ctx)
	local SMOKE = ctx.SMOKE
	local DUST = ctx.DUST
	local key = ctx.key
	local function dustEmitter(parent, size)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "SplittingSlashDust"
		emitter.Texture = SMOKE
		emitter.Color = ColorSequence.new(DUST)
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(12, 24)
		emitter.SpreadAngle = Vector2.new(88, 88)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.new(0, -8, 0)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-70, 70)
		emitter.Size = NumberSequence.new({ key(0, size * 0.4), key(1, size) })
		emitter.Transparency = NumberSequence.new({ key(0, 0.55), key(1, 1) })
		emitter.Parent = parent
		return emitter
	end
	return dustEmitter
end
return table.freeze(Visuals)

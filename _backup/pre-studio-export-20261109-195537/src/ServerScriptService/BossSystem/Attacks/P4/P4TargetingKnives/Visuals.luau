local Visuals = {}
function Visuals.key(ctx)
	local function key(time, value)
		return NumberSequenceKeypoint.new(time, value)
	end
	return key
end
function Visuals.sound(ctx)
	local Audio = ctx.Audio
	local actor = ctx.actor
	local function sound(cue, position, pitch)
		Audio.Emit(actor, cue, position, pitch and { Pitch = pitch } or nil)
	end
	return sound
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
function Visuals.disc(ctx)
	local core = ctx.core
	local function disc(owner, position, diameter, color, alpha)
		local piece = owner:Add(
			core.Part(
				"P4KnifeDisc",
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
		emitter.Name = "P4KnifeSparks"
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
function Visuals.burstSparks(ctx)
	local core = ctx.core
	local sparkEmitter = ctx.sparkEmitter
	local Effects = ctx.Effects
	local function burstSparks(owner, position, color, glow, count, spread)
		local anchor = owner:Add(core.Part("P4KnifeSparkAnchor", CFrame.new(position), Vector3.one * 0.2, color, 1))
		sparkEmitter(anchor, color, glow, 10, 26, spread):Emit(count)
		owner:Schedule(1, function()
			Effects.Release(anchor)
		end)
	end
	return burstSparks
end
function Visuals.flightTrail(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local Style = ctx.Style
	return function(owner, from, to)
		local distance = (to - from).Magnitude
		if owner.closed or distance < 0.05 then
			return
		end
		 
		local anchor = owner:Add(core.Part(
			"P4KnifeFlightTrail", CFrame.lookAt((from + to) * 0.5, to),
			Vector3.one * 0.1, Style.RED, 1
		))
		local lease = Effects.LeaseId(anchor)
		local start = Instance.new("Attachment")
		start.Position = Vector3.new(0, 0, distance * 0.5)
		start.Parent = anchor
		local finish = Instance.new("Attachment")
		finish.Position = Vector3.new(0, 0, -distance * 0.5)
		finish.Parent = anchor
		local beam = Instance.new("Beam")
		beam.Name = "KnifeTravelStreak"
		beam.Attachment0, beam.Attachment1 = start, finish
		beam.FaceCamera = true
		beam.Segments = 1
		beam.LightEmission = 0.6
		beam.Color = ColorSequence.new(Style.EMBER, Style.RED)
		beam.Width0, beam.Width1 = 0.2, 0.65
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.75),
			NumberSequenceKeypoint.new(0.7, 0.15),
			NumberSequenceKeypoint.new(1, 0.05),
		})
		beam.Parent = anchor
		local fade = Effects:Create(beam, TweenInfo.new(Style.FlightTrailLifetime), { Width0 = 0, Width1 = 0 })
		fade:Play()
		owner:Schedule(Style.FlightTrailLifetime + 0.03, function()
			fade:Cancel()
			if anchor.Parent and Effects.LeaseId(anchor) == lease then
				Effects.Release(anchor)
			end
		end)
	end
end
return table.freeze(Visuals)

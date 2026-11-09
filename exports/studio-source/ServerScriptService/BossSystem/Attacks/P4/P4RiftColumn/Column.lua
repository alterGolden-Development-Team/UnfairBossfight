 
local Visuals = {}
function Visuals.Create(ctx)
	local point = ctx.point
	local part = ctx.part
	local r = ctx.r
	local color = ctx.color
	local WHITE = ctx.WHITE
	local Effects = ctx.Effects
	local cast = ctx.cast
	local pulse = ctx.pulse
	local accent = ctx.accent
	local disc = ctx.disc
	local SCORCH = ctx.SCORCH
	local activeDuration = ctx.activeDuration
	local column = ctx.column
	local ring = ctx.ring
	local height = ctx.height
	local SPARKLE = ctx.SPARKLE
	local key = ctx.key
	local SMOKE = ctx.SMOKE
	local DUST = ctx.DUST
	local Tween = ctx.Tween
	local Audio = ctx.Audio
	local actor = ctx.actor
	local base = CFrame.new(point + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
	local plume =
		part("GoldenRiftExplosionColumn", base, Vector3.new(0.6, r * 2, r * 2), color, 0.8)
	plume.Shape = Enum.PartType.Cylinder
	local beamCore = part("RiftColumnCore", base, Vector3.new(0.6, r * 0.8, r * 0.8), WHITE, 0.3)
	beamCore.Shape = Enum.PartType.Cylinder
	beamCore.Material = Enum.Material.Neon
	local energy = part("RiftSpiralEnergyAnchor", CFrame.new(point), Vector3.one * 0.1, color, 1)

	local dome = part(
		"RiftColumnFlash",
		CFrame.new(point + Vector3.new(0, 0.4, 0)),
		Vector3.new(r * 0.8, r * 0.4, r * 0.8),
		WHITE,
		0.1
	)
	dome.Shape = Enum.PartType.Ball
	dome.Material = Enum.Material.Neon
	Effects:Create(
		dome,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(r * 2.2, r * 1.1, r * 2.2), Transparency = 1 }
	):Play()
	cast:Schedule(0.3, function()
		Effects.Release(dome)
	end)
	pulse(cast, point + Vector3.new(0, 0.2, 0), r * 0.7, r * 2.1, 0.35, accent, 0.45)
	local scorch = disc(cast, point + Vector3.new(0, 0.1, 0), r * 1.7, SCORCH, 0.35)
	scorch.Material = Enum.Material.SmoothPlastic
	Effects:Create(
		scorch,
		TweenInfo.new(activeDuration + 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }
	):Play()
	for index = 1, 4 do
		local angle = index / 4 * math.pi * 2 + column.At * 3
		local length = r * (0.9 + (index % 3) * 0.25)
		local crack = part(
			"RiftColumnCrack",
			CFrame.new(point + Vector3.new(0, 0.14, 0))
				* CFrame.Angles(0, angle, 0)
				* CFrame.new(0, 0, -length / 2),
			Vector3.new(0.4, 0.08, length),
			accent,
			0.15
		)
		crack.Material = Enum.Material.Neon
		Effects:Create(
			crack,
			TweenInfo.new(activeDuration + 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Transparency = 1 }
		):Play()
	end

	local chunks = {}
	for index = 1, 4 do
		local angle = index / 4 * math.pi * 2 + column.At * 5
		local speed = r * (1.2 + (index % 2) * 0.6)
		local vertical = 18 + (index % 3) * 5
		local lit = index % 2 == 0
		local chunk = part(
			"RiftColumnDebris",
			CFrame.new(
				point + Vector3.new(math.cos(angle) * r * 0.5, 0.5, math.sin(angle) * r * 0.5)
			),
			Vector3.one * (0.7 + (index % 3) * 0.3),
			lit and accent or SCORCH,
			0.05
		)
		chunk.Material = lit and Enum.Material.Neon or Enum.Material.Slate
		chunks[index] = {
			Part = chunk,
			Origin = chunk.Position,
			Spin = index % 2 == 0 and 7 or -7,
			Velocity = Vector3.new(math.cos(angle) * speed, vertical, math.sin(angle) * speed),
			Life = (vertical + math.sqrt(vertical * vertical + 70 * 0.15)) / 35,
		}
	end

	local rings = {}
	local ringCount = 3
	for index = 1, ringCount do
		local fraction = (index - 0.5) / ringCount
		local band = ring(energy, r * (0.95 - 0.12 * fraction), height * fraction, 0.3, color, 0.48)
		band.Fraction = fraction
		table.insert(rings, band)
	end
	local streaks = {}
	for index = 1, (column.Main and 2 or 1) do
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Parent = energy
		b.Parent = energy
		local beam = Instance.new("Beam")
		beam.Name = "RiftFaintEnergyStreak"
		beam.Attachment0 = a
		beam.Attachment1 = b
		beam.Width0 = 0.14
		beam.Width1 = 0.04
		beam.FaceCamera = true
		beam.CurveSize0 = 3
		beam.CurveSize1 = -3
		beam.Segments = 5
		beam.LightEmission = 0.4
		beam.Color = ColorSequence.new(accent)
		beam.Transparency = NumberSequence.new(0.7)
		beam.Parent = energy
		streaks[index] = { A = a, B = b, Beam = beam }
	end
	local embers = Instance.new("ParticleEmitter")
	embers.Name = "GoldenRiftSparkles"
	embers.Texture = SPARKLE
	embers.Color = ColorSequence.new(accent, color)
	embers.LightEmission = 0.6
	embers.Rate = column.Main and 70 or 35
	embers.Lifetime = NumberRange.new(0.35, 0.8)
	embers.Speed = NumberRange.new(16, 34)
	embers.Acceleration = Vector3.new(0, -4, 0)
	embers.SpreadAngle = Vector2.new(14, 14)
	embers.EmissionDirection = Enum.NormalId.Top
	embers.Size = NumberSequence.new({ key(0, 0.45), key(1, 0) })
	embers.Transparency = NumberSequence.new({ key(0, 0.2), key(1, 1) })
	embers.Parent = energy
	embers:Emit(column.Main and 12 or 6)
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "RiftDust"
	dust.Texture = SMOKE
	dust.Color = ColorSequence.new(DUST)
	dust.Rate = 0
	dust.Lifetime = NumberRange.new(0.5, 0.9)
	dust.Speed = NumberRange.new(14, 26)
	dust.SpreadAngle = Vector2.new(88, 88)
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Acceleration = Vector3.new(0, -8, 0)
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-70, 70)
	dust.Size = NumberSequence.new({ key(0, r * 0.25), key(1, r * 0.7) })
	dust.Transparency = NumberSequence.new({ key(0, 0.55), key(1, 1) })
	dust.Parent = energy
	dust:Emit(column.Main and 8 or 4)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = r * 3
	light.Brightness = 3
	light.Shadows = false
	light.Parent = energy
	Tween:Create(light, TweenInfo.new(activeDuration + 0.3), { Brightness = 0 }):Play()
	Audio.Emit(
		actor,
		column.Main and "GroundErupt" or "EarthRise",
		point,
		{ VolumeScale = column.Main and 0.7 or 0.35 }
	)
	return plume, beamCore, energy, chunks, rings, streaks, embers
end
return table.freeze(Visuals)

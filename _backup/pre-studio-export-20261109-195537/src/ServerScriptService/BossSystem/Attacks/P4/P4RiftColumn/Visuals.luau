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
			core.ScreenEffect("Shake", { Origin = origin, Radius = 100, Duration = duration, Intensity = intensity })
		end
	end
	return shake
end
function Visuals.disc(ctx)
	local core = ctx.core
	local function disc(owner, position, diameter, color, alpha)
		local piece = owner:Add(
			core.Part(
				"RiftDisc",
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
function Visuals.part(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local function part(name, frame, size, color, alpha)
		return cast:Add(core.Part(name, frame, size, color, alpha))
	end
	return part
end
function Visuals.ring(ctx)
	local AMBER = ctx.AMBER
	local function ring(anchor, radius, y, width, color, alpha)
		local value = { Points = {}, Beams = {}, Radius = radius, Y = y, Alpha = alpha }
		for index = 1, 8 do
			local a = Instance.new("Attachment")
			local angle = (index - 1) * math.pi * 2 / 8
			a.Position = Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
			a.Parent = anchor
			value.Points[index] = a
		end
		for index, a in ipairs(value.Points) do
			local beam = Instance.new("Beam")
			beam.Name = "RiftSpiralRing"
			beam.Attachment0 = a
			beam.Attachment1 = value.Points[index % 8 + 1]
			beam.Width0 = width
			beam.Width1 = width * 0.8
			beam.FaceCamera = true
			beam.LightEmission = 0.5
			beam.Color = ColorSequence.new(color, AMBER)
			beam.Transparency = NumberSequence.new(alpha + (index % 3 == 0 and 0.15 or 0))
			beam.Segments = 2
			beam.Parent = anchor
			value.Beams[index] = beam
		end
		return value
	end
	return ring
end
return table.freeze(Visuals)

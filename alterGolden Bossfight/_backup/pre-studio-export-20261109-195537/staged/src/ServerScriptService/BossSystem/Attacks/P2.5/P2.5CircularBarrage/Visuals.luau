local Visuals = {}
function Visuals.makeSparks(ctx)
	local WHITE = ctx.WHITE
	local GOLD = ctx.GOLD
	local ORANGE = ctx.ORANGE
	local function makeSparks(spread, speedMin, speedMax, gravity)
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.Rate = 0
		e.Lifetime = NumberRange.new(0.3, 0.65)
		e.Speed = NumberRange.new(speedMin, speedMax)
		e.SpreadAngle = spread
		e.Drag = 4
		e.Acceleration = Vector3.new(0, gravity, 0)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE),
			ColorSequenceKeypoint.new(0.35, GOLD),
			ColorSequenceKeypoint.new(1, ORANGE),
		})
		e.LightEmission = 1
		e.RotSpeed = NumberRange.new(-240, 240)
		e.Rotation = NumberRange.new(0, 360)
		return e
	end
	return makeSparks
end
function Visuals.solid(ctx)
	local Effects = ctx.Effects
	local Runtime = ctx.Runtime
	local cast = ctx.cast
	local get_position = ctx.get_position
	local function solid(name, shape, size, color, alpha)
		local p = Effects.AcquirePart()
		p.Name = name
		p.Shape = shape
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = alpha
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = CFrame.new(get_position())
		p.Parent = Runtime.Effects
		cast:Add(p)
		return p
	end
	return solid
end
function Visuals.flashBall(ctx)
	local solid = ctx.solid
	local Effects = ctx.Effects
	local function flashBall(at, color, scale, time)
		local p = solid("CircularBarrageFlash", Enum.PartType.Ball, Vector3.one * 0.5, color, 0.1)
		p.CFrame = CFrame.new(at)
		Effects:Create(p, TweenInfo.new(time), { Size = Vector3.one * scale, Transparency = 1 }):Play()
		Effects.ReleaseAfter(p, time + 0.03)
	end
	return flashBall
end
function Visuals.ring(ctx)
	local solid = ctx.solid
	local Effects = ctx.Effects
	local function ring(at, direction, color, radius, time)
		local dir = direction.Magnitude > 0.01 and direction.Unit or Vector3.yAxis
		local up = math.abs(dir.Y) > 0.99 and Vector3.xAxis or Vector3.yAxis
		local p = solid("CircularBarrageRing", Enum.PartType.Cylinder, Vector3.new(0.1, 0.4, 0.4), color, 0.1)
		p.CFrame = CFrame.lookAt(at, at + dir, up) * CFrame.Angles(0, math.pi / 2, 0)
		Effects:Create(
			p,
			TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.1, radius * 2, radius * 2), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(p, time + 0.03)
	end
	return ring
end
function Visuals.sparks(ctx)
	local solid = ctx.solid
	local GOLD = ctx.GOLD
	local Debris = ctx.Debris
	local Effects = ctx.Effects
	local function sparks(at, amount, template, orientation)
		local anchor = solid("CircularBarrageSparks", Enum.PartType.Ball, Vector3.one * 0.2, GOLD, 1)
		anchor.CFrame = orientation or CFrame.new(at)
		local e = template:Clone()
		e.Parent = anchor
		e:Emit(amount)
		Debris:AddItem(e, 1.2)
		Effects.ReleaseAfter(anchor, 1.2)
	end
	return sparks
end
function Visuals.piece(ctx)
	local core = ctx.core
	local cast = ctx.cast
	local Effects = ctx.Effects
	local parts = ctx.parts
	local get_frame = ctx.get_frame
	local function piece(name, size, offset, color, alpha, material)
		local part = core.Part(name, get_frame() * offset, size, color, 1)
		part.Material = material or Enum.Material.Metal
		cast:Add(part)
		Effects:Create(part, TweenInfo.new(0.22), { Transparency = alpha or 0.08 }):Play()
		table.insert(parts, { Part = part, Offset = offset })
		return part
	end
	return piece
end
function Visuals.accent(ctx)
	local piece = ctx.piece
	local function accent(name, size, offset, color)
		return piece(name, size, offset, color, 0.15, Enum.Material.Neon)
	end
	return accent
end
function Visuals.buildDial(ctx)
	local floor = ctx.floor
	local solid = ctx.solid
	local gold = ctx.gold
	local Effects = ctx.Effects
	local dialRadius = ctx.dialRadius
	local WHITE = ctx.WHITE
	local dialParts = ctx.dialParts
	local count = ctx.count
	local rotation = ctx.rotation
	local TAU = ctx.TAU
	local dialTicks = ctx.dialTicks
	local function buildDial()
		local flat = CFrame.new(floor) * CFrame.Angles(0, 0, math.pi / 2)
		local outer =
			solid("CircularBarrageDialRing", Enum.PartType.Cylinder, Vector3.new(0.1, 0.5, 0.5), gold, 0.55)
		outer.CFrame = flat
		Effects:Create(
			outer,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.1, dialRadius * 2, dialRadius * 2) }
		):Play()
		local inner =
			solid("CircularBarrageDialInner", Enum.PartType.Cylinder, Vector3.new(0.08, 0.5, 0.5), WHITE, 0.8)
		inner.CFrame = flat
		Effects:Create(
			inner,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.08, dialRadius * 1.5, dialRadius * 1.5) }
		):Play()
		table.insert(dialParts, outer)
		table.insert(dialParts, inner)
		local quarter = math.max(1, math.floor(count / 4))
		for i = 1, count do
			local dir = (rotation * CFrame.Angles(0, (i - 1) * TAU / count, 0)).LookVector
			local at = floor + dir * dialRadius * 0.86
			local major = (i - 1) % quarter == 0
			local tick = solid(
				"CircularBarrageDialTick",
				Enum.PartType.Block,
				Vector3.new(0.3, 0.1, major and 1.9 or 1.1),
				major and WHITE or gold,
				1
			)
			tick.CFrame = CFrame.lookAt(at, at + dir)
			Effects:Create(tick, TweenInfo.new(0.3), { Transparency = 0.6 }):Play()
			dialTicks[i] = tick
			table.insert(dialParts, tick)
		end
	end
	return buildDial
end
function Visuals.litTick(ctx)
	local dialTicks = ctx.dialTicks
	local WHITE = ctx.WHITE
	local Effects = ctx.Effects
	local gold = ctx.gold
	local function litTick(index)
		local tick = dialTicks[index]
		if tick and tick.Parent then
			tick.Color = WHITE
			tick.Transparency = 0
			Effects:Create(tick, TweenInfo.new(0.45), { Color = gold, Transparency = 0.1 }):Play()
		end
	end
	return litTick
end
return table.freeze(Visuals)

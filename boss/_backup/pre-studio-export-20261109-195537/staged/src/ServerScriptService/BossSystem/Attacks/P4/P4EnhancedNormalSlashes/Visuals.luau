local Visuals = {}

local function aimed(position, axis)
	local up = math.abs(axis.Y) > 0.98 and Vector3.xAxis or Vector3.yAxis
	return CFrame.lookAt(position, position + axis, up)
end

function Visuals.key(ctx)
	local function key(time, value)
		return NumberSequenceKeypoint.new(time, value)
	end
	return key
end
function Visuals.taper(ctx)
	local function taper(p)
		return math.sin(math.pi * math.clamp(p, 0, 1)) ^ 0.65
	end
	return taper
end
function Visuals.aim(ctx)
	return aimed
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
				"P4EnhancedDisc",
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

function Visuals.ring(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local function ring(owner, cframe, from, to, duration, color, alpha, width)
		local anchor = owner:Add(core.Part("P4EnhancedRing", cframe, Vector3.one * 0.2, color, 1))
		local count = 14
		local points, beams = {}, {}
		for i = 1, count do
			local attachment = Instance.new("Attachment")
			attachment.Parent = anchor
			points[i] = attachment
		end
		for i = 1, count do
			local beam = Instance.new("Beam")
			beam.Name = "P4EnhancedRingBeam"
			beam.Attachment0 = points[i]
			beam.Attachment1 = points[i % count + 1]
			beam.Width0 = width
			beam.Width1 = width
			beam.FaceCamera = true
			beam.Segments = 1
			beam.LightEmission = 1
			beam.Color = ColorSequence.new(color)
			beam.Transparency = NumberSequence.new(alpha)
			beam.Parent = anchor
			beams[i] = beam
		end
		local began = owner:Now()
		owner:Step(function(_, now)
			if not anchor.Parent then
				return false
			end
			local t = math.clamp((now - began) / duration, 0, 1)
			local eased = 1 - (1 - t) ^ 2
			local radius = (from + (to - from) * eased) * 0.5
			for i = 1, count do
				local a = (i - 1) / count * math.pi * 2
				points[i].Position = Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
			end
			local fade = NumberSequence.new(alpha + (1 - alpha) * t * t)
			for _, beam in ipairs(beams) do
				beam.Transparency = fade
			end
			if t >= 1 then
				Effects.Release(anchor)
				return false
			end
			return true
		end)
	end
	return ring
end
function Visuals.flash(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local function flash(owner, position, color, scale, duration)
		local ball =
			owner:Add(core.Part("P4EnhancedFlash", CFrame.new(position), Vector3.one * scale * 0.3, color, 0.1))
		ball.Shape = Enum.PartType.Ball
		ball.Material = Enum.Material.Neon
		Effects:Create(
			ball,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * scale, Transparency = 1 }
		):Play()
		owner:Schedule(duration + 0.05, function()
			Effects.Release(ball)
		end)
	end
	return flash
end

function Visuals.glint(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local SPARKLE = ctx.SPARKLE
	local key = ctx.key
	local function glint(owner, position, color, size, duration)
		local anchor = owner:Add(core.Part("P4EnhancedGlintAnchor", CFrame.new(position), Vector3.one * 0.2, color, 1))
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "P4EnhancedGlint"
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(color)
		emitter.LightEmission = 1
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(duration)
		emitter.Speed = NumberRange.new(0)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Size = NumberSequence.new({ key(0, size * 0.35), key(0.25, size), key(1, 0) })
		emitter.Transparency = NumberSequence.new({ key(0, 0), key(0.7, 0.2), key(1, 1) })
		emitter.Parent = anchor
		emitter:Emit(1)
		owner:Schedule(duration + 0.1, function()
			Effects.Release(anchor)
		end)
	end
	return glint
end
function Visuals.streak(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local function streak(owner, cframe, fromSize, toSize, duration, color, alpha)
		local bar = owner:Add(core.Part("P4EnhancedStreak", cframe, fromSize, color, alpha))
		bar.Material = Enum.Material.Neon
		Effects:Create(
			bar,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = toSize, Transparency = 1 }
		):Play()
		owner:Schedule(duration + 0.05, function()
			Effects.Release(bar)
		end)
	end
	return streak
end
function Visuals.scar(ctx)
	local streak = ctx.streak
	local WHITE = ctx.WHITE
	local function scar(owner, position, direction, length, width)
		local flat = Vector3.new(direction.X, 0, direction.Z)
		if flat.Magnitude < 0.01 then
			return
		end
		local at = position + Vector3.new(0, 0.15, 0)
		streak(
			owner,
			CFrame.lookAt(at, at + flat.Unit),
			Vector3.new(width, 0.1, length),
			Vector3.new(0.05, 0.1, length * 1.5),
			0.3,
			WHITE,
			0.2
		)
	end
	return scar
end
function Visuals.sparkEmitter(ctx)
	local SPARKLE = ctx.SPARKLE
	local key = ctx.key
	local function sparkEmitter(parent, color, glow, speedMin, speedMax, spread)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "P4EnhancedSparks"
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

function Visuals.streakEmitter(ctx)
	local SPARKLE = ctx.SPARKLE
	local key = ctx.key
	local function streakEmitter(parent, color, glow, speedMin, speedMax, spread)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "P4EnhancedStreakSparks"
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(color, glow)
		emitter.LightEmission = 1
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.14, 0.3)
		emitter.Speed = NumberRange.new(speedMin, speedMax)
		emitter.SpreadAngle = Vector2.new(spread, spread)
		emitter.EmissionDirection = Enum.NormalId.Front
		emitter.Acceleration = Vector3.new(0, -30, 0)
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
		emitter.Size = NumberSequence.new({ key(0, 2.2), key(1, 0) })
		emitter.Transparency = NumberSequence.new({ key(0, 0), key(1, 1) })
		emitter.Parent = parent
		return emitter
	end
	return streakEmitter
end
function Visuals.dustEmitter(ctx)
	local SMOKE = ctx.SMOKE
	local DUST = ctx.DUST
	local key = ctx.key
	local function dustEmitter(parent, size)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "P4EnhancedDust"
		emitter.Texture = SMOKE
		emitter.Color = ColorSequence.new(DUST)
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(10, 22)
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
function Visuals.burstSparks(ctx)
	local core = ctx.core
	local sparkEmitter = ctx.sparkEmitter
	local Effects = ctx.Effects
	local function burstSparks(owner, position, color, glow, count, spread)
		local anchor = owner:Add(core.Part("P4EnhancedSparkAnchor", CFrame.new(position), Vector3.one * 0.2, color, 1))
		sparkEmitter(anchor, color, glow, 10, 26, spread):Emit(count)
		owner:Schedule(1, function()
			Effects.Release(anchor)
		end)
	end
	return burstSparks
end

function Visuals.burstStreaks(ctx)
	local core = ctx.core
	local streakEmitter = ctx.streakEmitter
	local Effects = ctx.Effects
	local function burstStreaks(owner, position, direction, color, glow, count, spread)
		local anchor =
			owner:Add(core.Part("P4EnhancedStreakAnchor", aimed(position, direction), Vector3.one * 0.2, color, 1))
		streakEmitter(anchor, color, glow, 28, 56, spread):Emit(count)
		owner:Schedule(0.8, function()
			Effects.Release(anchor)
		end)
	end
	return burstStreaks
end
function Visuals.burstDust(ctx)
	local core = ctx.core
	local DUST = ctx.DUST
	local dustEmitter = ctx.dustEmitter
	local Effects = ctx.Effects
	local function burstDust(owner, position, size, count)
		local anchor = owner:Add(core.Part("P4EnhancedDustAnchor", CFrame.new(position), Vector3.one * 0.2, DUST, 1))
		dustEmitter(anchor, size):Emit(count)
		owner:Schedule(1.2, function()
			Effects.Release(anchor)
		end)
	end
	return burstDust
end

function Visuals.cutMark(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local function cutMark(owner, position, axis, length, width, color, duration)
		local half = length * 0.5
		local anchor = owner:Add(core.Part("P4EnhancedCut", aimed(position, axis), Vector3.one * 0.2, color, 1))
		local a0, mid, a1 = Instance.new("Attachment"), Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent = anchor
		mid.Parent = anchor
		a1.Parent = anchor
		local function beam(from, to)
			local b = Instance.new("Beam")
			b.Name = "P4EnhancedCutBeam"
			b.Attachment0 = from
			b.Attachment1 = to
			b.Width0 = 0.02
			b.Width1 = 0.02
			b.FaceCamera = true
			b.Segments = 1
			b.LightEmission = 1
			b.Color = ColorSequence.new(color)
			b.Transparency = NumberSequence.new(0)
			b.Parent = anchor
			return b
		end
		local head, tail = beam(a0, mid), beam(mid, a1)
		local began = owner:Now()
		owner:Step(function(_, now)
			if not anchor.Parent then
				return false
			end
			local t = math.clamp((now - began) / duration, 0, 1)
			local reach = half * (0.3 + 0.7 * math.min(1, t * 4))
			a0.Position = Vector3.new(0, 0, -reach)
			a1.Position = Vector3.new(0, 0, reach)
			local w = math.max(0.02, width * (1 - t) ^ 1.5)
			head.Width1 = w
			tail.Width0 = w
			if t >= 1 then
				Effects.Release(anchor)
				return false
			end
			return true
		end)
	end
	return cutMark
end

function Visuals.slashMarks(ctx)
	local rng = ctx.rng
	local cutMark = ctx.cutMark
	local WHITE = ctx.WHITE
	local GOLD = ctx.GOLD
	local function slashMarks(owner, position, axes, length)
		for _, axis in ipairs(axes) do
			cutMark(owner, position, axis, length * 1.5, 1.1, WHITE, 0.22)
			local side = axis:Cross(Vector3.yAxis)
			if side.Magnitude < 0.05 then
				side = axis:Cross(Vector3.xAxis)
			end
			local offset = side.Unit * rng:NextNumber(0.5, 0.9) * (rng:NextNumber() < 0.5 and -1 or 1)
			cutMark(owner, position + offset, axis, length, 0.6, GOLD, 0.26)
		end
	end
	return slashMarks
end

local function cutAxes(frame, spec)
	if spec.Cross then
		local slope = math.atan(0.75)
		return {
			(frame * CFrame.Angles(0, 0, slope)).RightVector,
			(frame * CFrame.Angles(0, 0, -slope)).RightVector,
		},
			frame.LookVector
	end
	if spec.Uppercut then
		return { frame.UpVector }, frame.UpVector
	end
	local axis = (frame * CFrame.Angles(0, 0, spec.Tilt)).RightVector
	return { axis }, axis * (spec.Direction or 1)
end
function Visuals.hitFx(ctx)
	local flash = ctx.flash
	local glint = ctx.glint
	local ring = ctx.ring
	local WHITE = ctx.WHITE
	local slashMarks = ctx.slashMarks
	local burstSparks = ctx.burstSparks
	local burstStreaks = ctx.burstStreaks
	local GOLD = ctx.GOLD
	local EMBER = ctx.EMBER
	local shake = ctx.shake
	local function hitFx(owner, position, frame, spec)
		local big = spec.Big == true
		local axes, motion = cutAxes(frame, spec)
		flash(owner, position, WHITE, big and 9 or 6, 0.2)
		glint(owner, position, WHITE, big and 13 or 9, 0.22)
		slashMarks(owner, position, axes, big and 11 or 8)
		burstSparks(owner, position, GOLD, WHITE, big and 14 or 9, 180)
		burstStreaks(owner, position, motion, EMBER, WHITE, big and 16 or 10, 24)
		ring(owner, aimed(position, frame.LookVector), 1.5, big and 12 or 8, 0.22, WHITE, 0.3, 0.35)
		shake(position, 16, 0.12, big and 0.3 or 0.2)
	end
	return hitFx
end

local function crescent(p)
	return math.max(0, math.sin(math.pi * math.clamp(p, 0, 1) ^ 1.5)) ^ 0.7
end

function Visuals.slashRibbon(ctx)
	local core = ctx.core
	local GOLD = ctx.GOLD
	local AMBER = ctx.AMBER
	local WHITE = ctx.WHITE
	local EMBER = ctx.EMBER
	local DEEP = ctx.DEEP
	local key = ctx.key
	local Effects = ctx.Effects
	local sparkEmitter = ctx.sparkEmitter
	local streak = ctx.streak
	local rng = ctx.rng
	local BODY_SCALE, BODY_WIDTH = 0.96, 3.4

	local function alphaAt(item, t)
		if t < item.Reveal then
			return 1
		end
		local value = item.Alpha * math.clamp((t - item.Reveal) / 0.05, 0, 1)
		if t > item.Hide then
			value += (1 - value) * math.clamp((t - item.Hide) / 0.12, 0, 1)
		end
		return value
	end
	local function slashRibbon(cast, frame, spec)
		local uppercut = spec.Uppercut == true
		local radius = spec.Radius
		local direction = spec.Direction or 1
		local sweep = spec.Sweep
		local arcFrame = frame * CFrame.Angles(0, 0, spec.Tilt)
		local anchor = cast:Add(core.Part(spec.PartName, arcFrame, Vector3.one * 0.1, GOLD, 1))
		local segments = 16
		local function arcPoint(angle, r)
			if uppercut then
				return Vector3.new(0, math.sin(angle) * r, -math.cos(angle) * r)
			end
			return Vector3.new(math.sin(angle) * r, 0.6, -math.cos(angle) * r)
		end

		local function arcPoints(scale, lift)
			local points = {}
			for i = 0, segments do
				local p = i / segments
				local a = Instance.new("Attachment")
				a.Position = arcPoint((-sweep + p * sweep * 2) * direction, radius * scale + (lift and lift(p) or 0))
				a.Parent = anchor
				points[i + 1] = a
			end
			return points
		end
		local layers = {}
		local function addLayer(name, points, width, color, tip, alpha, emission, delay)
			for i = 1, segments do
				local p0, p1 = (i - 1) / segments, i / segments
				local beam = Instance.new("Beam")
				beam.Name = name
				beam.Attachment0 = points[i]
				beam.Attachment1 = points[i + 1]
				beam.Width0 = math.max(0.05, width * crescent(p0))
				beam.Width1 = math.max(0.05, width * crescent(p1))
				beam.FaceCamera = true
				beam.Segments = 1
				beam.LightEmission = emission
				beam.Color = ColorSequence.new(tip:Lerp(color, crescent(p0)), tip:Lerp(color, crescent(p1)))
				beam.Transparency = NumberSequence.new(1)
				beam.Parent = anchor
				table.insert(layers, {
					Beam = beam,
					Alpha = alpha,
					Reveal = delay + p0 * 0.08,
					Hide = 0.12 + delay + p0 * 0.1,
				})
			end
		end
		local body = arcPoints(BODY_SCALE)
		addLayer("EnhancedMeleeSwordGlow", arcPoints(0.92), 6.5, EMBER, DEEP, 0.7, 0.5, 0)
		addLayer("EnhancedMeleeSwordRibbon", body, BODY_WIDTH, GOLD, EMBER, 0.1, 0.6, 0)
		addLayer("EnhancedMeleeSwordCore", body, 1.1, WHITE, AMBER, 0, 1, 0.005)
		addLayer("EnhancedMeleeSwordEdge", arcPoints(BODY_SCALE, function(p)
			return BODY_WIDTH * 0.5 * crescent(p)
		end), 0.45, WHITE, WHITE, 0, 1, 0.01)
		addLayer("EnhancedMeleeSwordEcho", arcPoints(0.82), 1.6, DEEP, DEEP, 0.55, 0.6, 0.03)

		local function pivot(angle)
			if uppercut then
				return arcFrame * CFrame.Angles(angle, 0, 0)
			end
			return arcFrame * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, -angle, 0)
		end
		local blade = cast:Add(core.Part("P4EnhancedBlade", pivot(-sweep * direction), Vector3.one * 0.1, WHITE, 1))
		local b0, b1 = Instance.new("Attachment"), Instance.new("Attachment")
		b0.Position = uppercut and Vector3.new(1.8, 0, -radius * 1.08) or Vector3.new(0, 1.8, -radius * 1.08)
		b1.Position = uppercut and Vector3.new(-1.8, 0, -radius * 1.08) or Vector3.new(0, -1.8, -radius * 1.08)
		b0.Parent = blade
		b1.Parent = blade
		local bladeTrail = Instance.new("Trail")
		bladeTrail.Name = "EnhancedBladeTrail"
		bladeTrail.Attachment0 = b0
		bladeTrail.Attachment1 = b1
		bladeTrail.Lifetime = 0.2
		bladeTrail.LightEmission = 1
		bladeTrail.FaceCamera = false
		bladeTrail.MinLength = 0.05
		bladeTrail.Color = ColorSequence.new(WHITE, GOLD)
		bladeTrail.Transparency = NumberSequence.new({ key(0, 0.3), key(1, 1) })
		bladeTrail.Parent = blade

		local tip = Instance.new("Attachment")
		tip.Position = Vector3.new(0, 0, -radius * 1.08)
		tip.Parent = blade
		local shed = sparkEmitter(tip, GOLD, WHITE, 6, 16, 120)
		shed.Rate = 220

		for _ = 1, 6 do
			local p = 0.25 + rng:NextNumber() * 0.65
			local angle = (-sweep + p * sweep * 2) * direction
			local at = arcFrame:PointToWorldSpace(arcPoint(angle, radius * (0.8 + rng:NextNumber() * 0.7)))
			local tangent = uppercut and Vector3.new(0, math.cos(angle), math.sin(angle))
				or Vector3.new(math.cos(angle), 0, math.sin(angle))
			local along = arcFrame:VectorToWorldSpace(tangent * direction)
			local length = 3 + rng:NextNumber() * 4
			cast:Schedule(0.01 + p * 0.09, function()
				streak(
					cast,
					aimed(at, along),
					Vector3.new(0.16, 0.16, length * 0.4),
					Vector3.new(0.03, 0.03, length),
					0.2,
					WHITE,
					0.1
				)
			end)
		end

		local began = cast:Now()
		cast:Step(function(_, now)
			if not anchor.Parent then
				return false
			end
			local t = now - began
			local progress = math.clamp(t / 0.09, 0, 1)
			if blade.Parent then
				blade.CFrame = pivot((-sweep + progress * sweep * 2) * direction)
			end
			if progress >= 1 then
				shed.Rate = 0
			end
			for _, item in ipairs(layers) do
				item.Beam.Transparency = NumberSequence.new(alphaAt(item, t))
			end
			if t >= 0.4 then
				Effects.Release(anchor)
				if blade.Parent then
					Effects.Release(blade)
				end
				return false
			end
			return true
		end)
	end
	return slashRibbon
end

function Visuals.groundArc(ctx)
	local streak = ctx.streak
	local WHITE = ctx.WHITE
	local GOLD = ctx.GOLD
	local function groundArc(owner, frame, spec, groundY)
		if spec.Uppercut then
			return
		end
		local pieces = 7
		local radius = spec.Radius * 0.95
		local direction = spec.Direction or 1
		local function pointAt(i)
			local a = (-spec.Sweep + i * spec.Sweep * 2 / pieces) * direction
			local world = frame:PointToWorldSpace(Vector3.new(math.sin(a) * radius, 0, -math.cos(a) * radius))
			return Vector3.new(world.X, groundY + 0.15, world.Z)
		end
		for i = 0, pieces - 1 do
			local from, to = pointAt(i), pointAt(i + 1)
			local span = to - from
			if span.Magnitude > 0.1 then
				owner:Schedule(0.01 + (i / pieces) * 0.09, function()
					local mid = (from + to) * 0.5
					streak(
						owner,
						CFrame.lookAt(mid, mid + span),
						Vector3.new(0.9, 0.1, span.Magnitude * 1.15),
						Vector3.new(0.08, 0.1, span.Magnitude * 1.3),
						0.4,
						i % 2 == 0 and WHITE or GOLD,
						0.2
					)
				end)
			end
		end
	end
	return groundArc
end

function Visuals.slashFx(ctx)
	local slashRibbon = ctx.slashRibbon
	local groundOf = ctx.groundOf
	local core = ctx.core
	local AMBER = ctx.AMBER
	local Effects = ctx.Effects
	local pulse = ctx.pulse
	local burstSparks = ctx.burstSparks
	local GOLD = ctx.GOLD
	local WHITE = ctx.WHITE
	local flash = ctx.flash
	local glint = ctx.glint
	local ring = ctx.ring
	local burstDust = ctx.burstDust
	local scar = ctx.scar
	local groundArc = ctx.groundArc
	local shake = ctx.shake
	local function slashFx(cast, frame, spec)
		slashRibbon(cast, frame, spec)
		local ground = groundOf(frame.Position)
		local look = frame.LookVector
		if spec.Uppercut then
			local base = ground + look * 4
			local column = cast:Add(
				core.Part(
					"P4UppercutColumn",
					CFrame.new(base + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
					Vector3.new(12, 6, 6),
					AMBER,
					0.35
				)
			)
			column.Shape = Enum.PartType.Cylinder
			column.Material = Enum.Material.Neon
			Effects:Create(
				column,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = Vector3.new(26, 1.2, 1.2), Transparency = 1, Position = base + Vector3.new(0, 12, 0) }
			):Play()
			cast:Schedule(0.35, function()
				Effects.Release(column)
			end)
			pulse(cast, base + Vector3.new(0, 0.25, 0), 4, 20, 0.35, AMBER, 0.3)
			burstSparks(cast, frame:PointToWorldSpace(Vector3.new(0, 6.6, -2.4)), GOLD, WHITE, 16, 70)
			burstSparks(cast, frame:PointToWorldSpace(Vector3.new(0, 0, -8)), GOLD, WHITE, 8, 70)
			flash(cast, frame:PointToWorldSpace(Vector3.new(0, 6, -4)), WHITE, 6, 0.18)
			burstDust(cast, base + Vector3.new(0, 0.5, 0), 5, 10)
			glint(cast, frame:PointToWorldSpace(Vector3.new(0, 7.4, -3)), WHITE, 15, 0.24)

			ring(cast, CFrame.new(base + Vector3.new(0, 1, 0)) * CFrame.Angles(math.pi * 0.5, 0, 0), 4, 16, 0.3, AMBER, 0.35, 0.5)
		else
			local direction = spec.Direction or 1
			local endAngle = spec.Sweep * direction
			burstSparks(cast, frame:PointToWorldSpace(Vector3.new(0, 0.6, -9)), GOLD, WHITE, 14, 70)
			burstSparks(cast, frame:PointToWorldSpace(Vector3.new(8.5, 0.6, -3.1)), GOLD, WHITE, 7, 70)
			burstSparks(cast, frame:PointToWorldSpace(Vector3.new(-8.5, 0.6, -3.1)), GOLD, WHITE, 7, 70)
			flash(cast, frame:PointToWorldSpace(Vector3.new(0, 0.8, -8)), WHITE, 5, 0.16)
			groundArc(cast, frame, spec, ground.Y)
			scar(cast, ground + look * 7, look, 12, 0.5)
			pulse(cast, ground + look * 5 + Vector3.new(0, 0.2, 0), 3, 15, 0.25, AMBER, 0.4)

			cast:Schedule(0.09, function()
				glint(
					cast,
					frame:PointToWorldSpace(
						Vector3.new(math.sin(endAngle) * spec.Radius, 0.6, -math.cos(endAngle) * spec.Radius)
					),
					WHITE,
					12,
					0.2
				)
			end)
		end
		shake(frame.Position, 40, 0.1, spec.Uppercut and 0.22 or 0.14)
	end
	return slashFx
end

function Visuals.chargeFx(ctx)
	local groundOf = ctx.groundOf
	local pulse = ctx.pulse
	local AMBER = ctx.AMBER
	local disc = ctx.disc
	local GOLD = ctx.GOLD
	local Effects = ctx.Effects
	local sparkEmitter = ctx.sparkEmitter
	local WHITE = ctx.WHITE
	local Config = ctx.Config
	local core = ctx.core
	local ring = ctx.ring
	local glint = ctx.glint
	local key = ctx.key
	local SPARKLE = ctx.SPARKLE
	local function chargeFx(cast, root, windup, target)
		local ground = groundOf(root.Position)
		local state = { Active = true }
		local began = cast:Now()
		pulse(cast, ground + Vector3.new(0, 0.2, 0), 22, 5, windup, AMBER, 0.4)
		local pad = disc(cast, ground + Vector3.new(0, 0.12, 0), 8, GOLD, 0.6)
		Effects:Create(
			pad,
			TweenInfo.new(windup, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.1, 12, 12), Transparency = 0.25 }
		):Play()
		local aura = sparkEmitter(root, WHITE, GOLD, 3, 10, 180)
		aura.Rate = 70
		aura.Acceleration = Vector3.new(0, 6, 0)
		cast:Add(aura)

		local shell = cast:Add(core.Part("P4ChargeShell", CFrame.new(root.Position), Vector3.one * 15, GOLD, 1))
		local gather = Instance.new("ParticleEmitter")
		gather.Name = "P4ChargeGather"
		gather.Texture = SPARKLE
		gather.Color = ColorSequence.new(WHITE, GOLD)
		gather.LightEmission = 0.8
		gather.Rate = 110
		gather.Lifetime = NumberRange.new(0.2, 0.3)
		gather.Speed = NumberRange.new(26, 40)
		gather.Shape = Enum.ParticleEmitterShape.Sphere
		gather.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		gather.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
		gather.Orientation = Enum.ParticleOrientation.VelocityParallel
		gather.Size = NumberSequence.new({ key(0, 0.2), key(0.4, 1.8), key(1, 0.4) })
		gather.Transparency = NumberSequence.new({ key(0, 0.6), key(0.3, 0), key(1, 0.4) })
		gather.Parent = shell

		local floor = ground + Vector3.new(0, 0.18, 0)
		local runes = {}
		for index, sign in ipairs({ 1, -1 }) do
			local bar = cast:Add(core.Part("P4ChargeRune", CFrame.new(floor), Vector3.new(6, 0.1, 0.45), GOLD, 0.35))
			bar.Material = Enum.Material.Neon
			runes[index] = { Part = bar, Sign = sign }
		end
		cast:Step(function(_, now)
			if not state.Active or not root.Parent or not shell.Parent then
				return false
			end
			local t = now - began
			local grow = math.clamp(t / windup, 0, 1)
			shell.CFrame = CFrame.new(root.Position)
			for _, rune in ipairs(runes) do
				rune.Part.Size = Vector3.new(6 + 9 * grow, 0.1, 0.45)
				rune.Part.CFrame = CFrame.new(floor) * CFrame.Angles(0, t * 3.2 + rune.Sign * math.rad(45), 0)
			end
			return true
		end)

		local line
		if Config.P4EnhancedNormalTelegraph ~= false then
			local dashMax = math.clamp(Config.P4EnhancedNormalDashDistance or 40, 20, 55)
			local homing = Config.P4EnhancedNormalHoming ~= false
			line = cast:Add(core.Part("P4EnhancedDashLine", CFrame.new(ground), Vector3.new(1.6, 0.1, 1), GOLD, 1))
			line.Material = Enum.Material.Neon
			cast:Step(function(_, now)
				if not state.Active or not line.Parent then
					return false
				end
				local targetRoot = target.Parent and target:FindFirstChild("HumanoidRootPart")
				if not targetRoot then
					return false
				end
				local offset = targetRoot.Position - root.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				if flat.Magnitude < 0.01 then
					return true
				end

				local length = math.max(0, flat.Magnitude - 6)
				if not homing then
					length = math.min(length, dashMax)
				end
				if length < 0.5 then
					line.Transparency = 1
					return true
				end
				local direction = flat.Unit
				local center = Vector3.new(root.Position.X, ground.Y + 0.2, root.Position.Z) + direction * length * 0.5
				line.Size = Vector3.new(1.6, 0.1, length)
				line.CFrame = CFrame.lookAt(center, center + direction)

				line.Transparency = 0.8 - 0.25 * math.clamp((now - began) / windup, 0, 1)
				return true
			end)
		end
		function state.Stop()
			state.Active = false
			aura.Rate = 0
			gather.Rate = 0
			Effects:Create(pad, TweenInfo.new(0.15), { Transparency = 1 }):Play()
			for _, rune in ipairs(runes) do
				Effects:Create(rune.Part, TweenInfo.new(0.15), { Transparency = 1 }):Play()
			end
			if line and line.Parent then
				Effects:Create(line, TweenInfo.new(0.15), { Transparency = 1 }):Play()
			end
			if root.Parent then
				ring(cast, CFrame.lookAt(root.Position, root.Position + root.CFrame.LookVector), 12, 2, 0.16, WHITE, 0.15, 0.6)
				glint(cast, root.Position, WHITE, 10, 0.18)
			end
			cast:Schedule(0.2, function()
				Effects.Release(pad)
				Effects.Release(shell)
				for _, rune in ipairs(runes) do
					Effects.Release(rune.Part)
				end
				if line then
					Effects.Release(line)
				end
			end)
		end
		return state
	end
	return chargeFx
end

function Visuals.dashFx(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local pulse = ctx.pulse
	local burstDust = ctx.burstDust
	local burstSparks = ctx.burstSparks
	local flash = ctx.flash
	local glint = ctx.glint
	local ring = ctx.ring
	local shake = ctx.shake
	local sparkEmitter = ctx.sparkEmitter
	local dustEmitter = ctx.dustEmitter
	local AMBER = ctx.AMBER
	local WHITE = ctx.WHITE
	local GOLD = ctx.GOLD
	local EMBER = ctx.EMBER
	local SPARKLE = ctx.SPARKLE
	local key = ctx.key
	local function dashFx(cast, root, direction, groundY)
		local start = root.Position
		local floor = Vector3.new(start.X, groundY, start.Z)
		pulse(cast, floor + Vector3.new(0, 0.2, 0), 6, 22, 0.3, AMBER, 0.4)
		burstDust(cast, floor + Vector3.new(0, 0.4, 0), 6, 12)
		flash(cast, start, WHITE, 7, 0.18)
		glint(cast, start, WHITE, 12, 0.2)
		ring(cast, CFrame.lookAt(start, start + direction), 3, 20, 0.28, WHITE, 0.25, 0.5)
		shake(start, 60, 0.12, 0.25)

		local bar = cast:Add(core.Part("P4EnhancedDashStreak", root.CFrame, Vector3.new(0.3, 2.6, 0.5), AMBER, 0.45))
		bar.Material = Enum.Material.Neon

		local lines = Instance.new("ParticleEmitter")
		lines.Name = "P4DashLines"
		lines.Texture = SPARKLE
		lines.Color = ColorSequence.new(WHITE, AMBER)
		lines.LightEmission = 0.8
		lines.Rate = 80
		lines.Lifetime = NumberRange.new(0.14, 0.24)
		lines.Speed = NumberRange.new(30, 50)
		lines.EmissionDirection = Enum.NormalId.Back
		lines.SpreadAngle = Vector2.new(14, 14)
		lines.Orientation = Enum.ParticleOrientation.VelocityParallel
		lines.Size = NumberSequence.new({ key(0, 3), key(1, 0) })
		lines.Transparency = NumberSequence.new({ key(0, 0.15), key(1, 1) })
		lines.Parent = root
		cast:Add(lines)

		local wakeOrigin = Vector3.new(start.X, groundY + 0.3, start.Z)
		local wake = cast:Add(core.Part("P4DashWake", CFrame.lookAt(wakeOrigin, wakeOrigin + direction), Vector3.one * 0.2, GOLD, 1))
		local w0, w1 = Instance.new("Attachment"), Instance.new("Attachment")
		w0.Position = Vector3.new(-1.6, 0, 0)
		w1.Position = Vector3.new(1.6, 0, 0)
		w0.Parent = wake
		w1.Parent = wake
		local scrape = Instance.new("Trail")
		scrape.Name = "P4DashScrape"
		scrape.Attachment0 = w0
		scrape.Attachment1 = w1
		scrape.Lifetime = 0.4
		scrape.LightEmission = 1
		scrape.FaceCamera = false
		scrape.MinLength = 0.1
		scrape.Color = ColorSequence.new(WHITE, EMBER)
		scrape.Transparency = NumberSequence.new({ key(0, 0.35), key(1, 1) })
		scrape.Parent = wake
		local scrapeSparks = sparkEmitter(wake, EMBER, WHITE, 6, 16, 60)
		scrapeSparks.Rate = 40
		local scrapeDust = dustEmitter(wake, 3)
		scrapeDust.Rate = 18

		local state = { Heading = direction }
		local nextPuff = 7
		function state.Update(traveled, heading)
			state.Heading = heading
			local position = root.Position
			local span = position - start
			if span.Magnitude > 0.5 then
				local length = math.min(6, span.Magnitude)
				local mid = position - heading * (length * 0.5)
				bar.Size = Vector3.new(0.18, 1.2, length)
				bar.CFrame = CFrame.lookAt(mid, mid + heading)
			end
			local at = Vector3.new(position.X, groundY + 0.3, position.Z)
			wake.CFrame = CFrame.lookAt(at, at + heading)
			if traveled >= nextPuff then
				nextPuff += 7
				burstDust(cast, Vector3.new(position.X, groundY + 0.4, position.Z), 3.5, 3)
			end
		end
		function state.Finish(traveled)
			lines.Rate = 0
			scrapeSparks.Rate = 0
			scrapeDust.Rate = 0
			local position = root.Position
			local finalSpan = math.min(6, (position - start).Magnitude)
			Effects:Create(
				bar,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = 1, Size = Vector3.new(0.05, 0.6, math.max(0.5, finalSpan)) }
			):Play()
			cast:Schedule(0.3, function()
				Effects.Release(bar)
			end)

			cast:Schedule(0.6, function()
				Effects.Release(wake)
			end)
			if traveled > 1 then
				local arrival = Vector3.new(position.X, groundY, position.Z)
				pulse(cast, arrival + Vector3.new(0, 0.2, 0), 4, 18, 0.3, AMBER, 0.35)
				burstDust(cast, arrival + Vector3.new(0, 0.4, 0), 5, 10)
				burstSparks(cast, arrival + Vector3.new(0, 0.6, 0), EMBER, WHITE, 10, 60)
				ring(cast, CFrame.lookAt(position, position + state.Heading), 14, 3, 0.2, AMBER, 0.3, 0.5)
			end
		end
		return state
	end
	return dashFx
end

function Visuals.xTelegraph(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local groundOf = ctx.groundOf
	local GOLD = ctx.GOLD
	local WHITE = ctx.WHITE
	local glint = ctx.glint
	local function xTelegraph(cast, frame, width, length, duration)
		local ground = groundOf(frame.Position)
		local look = Vector3.new(frame.LookVector.X, 0, frame.LookVector.Z)
		look = look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1)
		local center = Vector3.new(frame.Position.X, ground.Y + 0.14, frame.Position.Z) + look * (length * 0.5)
		local laneFrame = CFrame.lookAt(center, center + look)
		local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local pieces = {}
		local lane = cast:Add(core.Part("P4XLane", laneFrame, Vector3.new(width, 0.1, length), GOLD, 1))
		lane.Material = Enum.Material.Neon
		Effects:Create(lane, info, { Transparency = 0.84 }):Play()
		table.insert(pieces, lane)
		for _, side in ipairs({ -1, 1 }) do
			local rim = cast:Add(
				core.Part("P4XLaneRim", laneFrame * CFrame.new(side * width * 0.5, 0.02, 0), Vector3.new(0.5, 0.12, length), WHITE, 1)
			)
			rim.Material = Enum.Material.Neon
			Effects:Create(rim, info, { Transparency = 0.45 }):Play()
			table.insert(pieces, rim)
		end

		local armLength = width / math.cos(math.atan(0.75))
		for _, sign in ipairs({ -1, 1 }) do
			local arm = cast:Add(
				core.Part("P4XForming", frame * CFrame.Angles(0, 0, math.atan(0.75) * sign), Vector3.new(1, 0.4, 0.4), WHITE, 0.2)
			)
			arm.Material = Enum.Material.Neon
			Effects:Create(arm, info, { Size = Vector3.new(armLength, 0.4, 0.4) }):Play()
			table.insert(pieces, arm)
		end
		glint(cast, frame.Position, WHITE, 9, duration)
		return function()
			for _, piece in ipairs(pieces) do
				Effects:Create(piece, TweenInfo.new(0.12), { Transparency = 1 }):Play()
			end
			cast:Schedule(0.2, function()
				for _, piece in ipairs(pieces) do
					Effects.Release(piece)
				end
			end)
		end
	end
	return xTelegraph
end

function Visuals.xBody(ctx)
	local core = ctx.core
	local GOLD = ctx.GOLD
	local AMBER = ctx.AMBER
	local WHITE = ctx.WHITE
	local EMBER = ctx.EMBER
	local DEEP = ctx.DEEP
	local SPARKLE = ctx.SPARKLE
	local key = ctx.key
	local taper = ctx.taper
	local sparkEmitter = ctx.sparkEmitter
	local dustEmitter = ctx.dustEmitter
	local ring = ctx.ring
	local groundOf = ctx.groundOf
	local function xBody(cast, frame, width)
		local half = width * 0.5
		local height = half * 0.75
		local bow = math.clamp(width * 0.1, 2, 4)
		local armSegments = 12
		local anchor = cast:Add(core.Part("EnhancedLargeXSlash", frame, Vector3.new(width, height * 1.6, 0.3), GOLD, 1))
		local layerDefs = {
			{ "EnhancedXGlow", 8, EMBER, DEEP, 0.7, 0.5 },
			{ "EnhancedXGoldenSwordRibbon", 3.6, GOLD, EMBER, 0.12, 0.6 },
			{ "EnhancedXCore", 1.2, WHITE, AMBER, 0, 1 },
		}
		for _, sign in ipairs({ -1, 1 }) do
			local points = {}
			for i = 0, armSegments do
				local p = i / armSegments
				local a = Instance.new("Attachment")
				a.Position = Vector3.new(-half + p * width, height * sign * (2 * p - 1), -bow * (1 - (2 * p - 1) ^ 2))
				a.Parent = anchor
				points[i + 1] = a
			end
			for _, def in ipairs(layerDefs) do
				for i = 1, armSegments do
					local p0, p1 = (i - 1) / armSegments, i / armSegments
					local beam = Instance.new("Beam")
					beam.Name = def[1]
					beam.Attachment0 = points[i]
					beam.Attachment1 = points[i + 1]
					beam.Width0 = math.max(0.1, def[2] * taper(p0))
					beam.Width1 = math.max(0.1, def[2] * taper(p1))
					beam.FaceCamera = true
					beam.Segments = 1
					beam.LightEmission = def[6]
					beam.Color = ColorSequence.new(def[4]:Lerp(def[3], taper(p0)), def[4]:Lerp(def[3], taper(p1)))
					beam.Transparency = NumberSequence.new(def[5])
					beam.Parent = anchor
				end
			end

			local first, last = points[1], points[armSegments + 1]
			local ghost = Instance.new("Trail")
			ghost.Name = "EnhancedXGhost"
			ghost.Attachment0 = first
			ghost.Attachment1 = last
			ghost.Lifetime = 0.28
			ghost.LightEmission = 0.8
			ghost.FaceCamera = false
			ghost.MinLength = 0.1
			ghost.Color = ColorSequence.new(GOLD, EMBER)
			ghost.Transparency = NumberSequence.new({ key(0, 0.4), key(1, 1) })
			ghost.Parent = anchor

			for _, tip in ipairs({ first, last }) do
				local tipSparks = sparkEmitter(tip, GOLD, WHITE, 4, 12, 40)
				tipSparks.Rate = 28
			end
			local midSparks = sparkEmitter(points[armSegments * 0.5 + 1], GOLD, WHITE, 3, 9, 60)
			midSparks.Rate = 16
		end

		local wind = Instance.new("ParticleEmitter")
		wind.Name = "EnhancedXWind"
		wind.Texture = SPARKLE
		wind.Color = ColorSequence.new(WHITE, AMBER)
		wind.LightEmission = 0.8
		wind.Rate = 80
		wind.Lifetime = NumberRange.new(0.18, 0.34)
		wind.Speed = NumberRange.new(8, 18)
		wind.EmissionDirection = Enum.NormalId.Back
		wind.SpreadAngle = Vector2.new(10, 10)
		wind.Orientation = Enum.ParticleOrientation.VelocityParallel
		wind.Size = NumberSequence.new({ key(0, 2.6), key(1, 0) })
		wind.Transparency = NumberSequence.new({ key(0, 0.2), key(1, 1) })
		wind.Parent = anchor
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 34
		light.Brightness = 3
		light.Shadows = false
		light.Parent = anchor

		local flare = cast:Add(core.Part("P4XFlare", frame, Vector3.one * 4, WHITE, 0.15))
		flare.Shape = Enum.PartType.Ball
		flare.Material = Enum.Material.Neon
		local star = Instance.new("ParticleEmitter")
		star.Name = "P4XStar"
		star.Texture = SPARKLE
		star.Color = ColorSequence.new(WHITE)
		star.LightEmission = 1
		star.Rate = 12
		star.Lifetime = NumberRange.new(0.14, 0.2)
		star.Speed = NumberRange.new(0)
		star.Rotation = NumberRange.new(0, 360)
		star.Size = NumberSequence.new({ key(0, 5), key(0.3, 11), key(1, 0) })
		star.Transparency = NumberSequence.new({ key(0, 0.1), key(1, 1) })
		star.Parent = flare

		local groundY = groundOf(frame.Position).Y
		local look = frame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		local wakeRotation =
			CFrame.lookAt(Vector3.zero, flatLook.Magnitude > 0.01 and flatLook or Vector3.new(0, 0, -1))
		local wake = cast:Add(
			core.Part(
				"P4XWake",
				CFrame.new(frame.Position.X, groundY + 0.3, frame.Position.Z) * wakeRotation,
				Vector3.one * 0.2,
				GOLD,
				1
			)
		)
		local w0, w1 = Instance.new("Attachment"), Instance.new("Attachment")
		w0.Position = Vector3.new(-half * 0.35, 0, 0)
		w1.Position = Vector3.new(half * 0.35, 0, 0)
		w0.Parent = wake
		w1.Parent = wake
		local scorch = Instance.new("Trail")
		scorch.Name = "EnhancedXScorch"
		scorch.Attachment0 = w0
		scorch.Attachment1 = w1
		scorch.Lifetime = 0.6
		scorch.LightEmission = 1
		scorch.FaceCamera = false
		scorch.MinLength = 0.1
		scorch.Color = ColorSequence.new(WHITE, GOLD)
		scorch.Transparency = NumberSequence.new({ key(0, 0.3), key(1, 1) })
		scorch.Parent = wake
		dustEmitter(wake, 4).Rate = 35
		sparkEmitter(wake, GOLD, WHITE, 8, 20, 70).Rate = 25

		local body = { Anchor = anchor, Wake = wake, GroundY = groundY }
		local nextRing = 16
		function body.Update(at, now, traveled)
			anchor.CFrame = at
			wake.CFrame = CFrame.new(at.Position.X, groundY + 0.3, at.Position.Z) * wakeRotation
			if flare.Parent then
				flare.CFrame = at * CFrame.new(0, 0, -bow)
				flare.Size = Vector3.one * (3.6 + math.sin((now or 0) * 45) * 0.8)
			end

			if traveled >= nextRing then
				nextRing += 16
				ring(
					cast,
					CFrame.lookAt(at.Position, at.Position + at.LookVector),
					width * 0.3,
					width * 0.95,
					0.34,
					AMBER,
					0.5,
					0.7
				)
			end
		end
		return body
	end
	return xBody
end

function Visuals.xRelease(ctx)
	local flash = ctx.flash
	local glint = ctx.glint
	local ring = ctx.ring
	local streak = ctx.streak
	local WHITE = ctx.WHITE
	local AMBER = ctx.AMBER
	local GOLD = ctx.GOLD
	local burstSparks = ctx.burstSparks
	local pulse = ctx.pulse
	local burstDust = ctx.burstDust
	local shake = ctx.shake
	local function xRelease(cast, frame, groundY, width)
		local floor = Vector3.new(frame.Position.X, groundY, frame.Position.Z)
		flash(cast, frame.Position, WHITE, 12, 0.25)
		glint(cast, frame.Position, WHITE, 20, 0.3)
		for _, sign in ipairs({ -1, 1 }) do
			streak(
				cast,
				frame * CFrame.Angles(0, 0, math.atan(0.75) * sign),
				Vector3.new(width * 1.5, 0.6, 0.6),
				Vector3.new(width * 2.1, 0.08, 0.08),
				0.3,
				WHITE,
				0.05
			)
		end
		ring(cast, CFrame.lookAt(frame.Position, frame.Position + frame.LookVector), 4, width * 1.2, 0.36, WHITE, 0.2, 0.9)
		burstSparks(cast, frame.Position, GOLD, WHITE, 26, 180)
		pulse(cast, floor + Vector3.new(0, 0.25, 0), 8, 34, 0.4, AMBER, 0.25)
		burstDust(cast, floor + Vector3.new(0, 0.4, 0), 7, 14)
		shake(frame.Position, 120, 0.22, 0.55)
	end
	return xRelease
end

function Visuals.xEndFx(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local flash = ctx.flash
	local glint = ctx.glint
	local ring = ctx.ring
	local streak = ctx.streak
	local WHITE = ctx.WHITE
	local AMBER = ctx.AMBER
	local burstSparks = ctx.burstSparks
	local burstStreaks = ctx.burstStreaks
	local GOLD = ctx.GOLD
	local EMBER = ctx.EMBER
	local pulse = ctx.pulse
	local burstDust = ctx.burstDust
	local shake = ctx.shake
	local function xEndFx(position, groundY, hitWall, direction)
		local ending = Effects.NewCast(actor, "P4EnhancedXEnd", 1.2)
		flash(ending, position, hitWall and WHITE or AMBER, hitWall and 14 or 10, 0.25)
		glint(ending, position, WHITE, hitWall and 22 or 16, 0.28)
		burstSparks(ending, position, GOLD, WHITE, hitWall and 28 or 16, 180)
		burstStreaks(ending, position, direction, EMBER, WHITE, hitWall and 24 or 14, 60)
		ring(ending, CFrame.lookAt(position, position + direction), 4, hitWall and 30 or 22, 0.4, AMBER, 0.3, 0.8)
		pulse(ending, Vector3.new(position.X, groundY + 0.25, position.Z), 6, hitWall and 32 or 22, 0.4, AMBER, 0.3)
		burstDust(ending, Vector3.new(position.X, groundY + 0.4, position.Z), 6, 12)

		local floor = Vector3.new(position.X, groundY + 0.2, position.Z)
		for _, sign in ipairs({ -1, 1 }) do
			streak(
				ending,
				CFrame.new(floor) * CFrame.Angles(0, sign * math.rad(45), 0),
				Vector3.new(1, 0.1, 14),
				Vector3.new(0.12, 0.1, 20),
				0.8,
				WHITE,
				0.15
			)
		end
		if hitWall then
			shake(position, 80, 0.16, 0.35)
		end
	end
	return xEndFx
end
return table.freeze(Visuals)

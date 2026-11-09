local Visuals = {}
function Visuals.seg(ctx)
	local DETAIL = ctx.DETAIL
	local function seg(count)
		return math.max(12, math.floor(count * DETAIL + 0.5))
	end
	return seg
end
function Visuals.screen(ctx)
	local token = ctx.token
	local remote = ctx.remote
	local function screen(kind, data)
		data = data or {}
		data.Kind = kind
		data.Token = token
		remote:FireAllClients("EtherealFX", data)
	end
	return screen
end
function Visuals.screenTo(ctx)
	local Players = ctx.Players
	local token = ctx.token
	local remote = ctx.remote
	local function screenTo(player, kind, data)
		if player and player.Parent == Players then
			data = data or {}
			data.Kind = kind
			data.Token = token
			remote:FireClient(player, "EtherealFX", data)
		end
	end
	return screenTo
end
function Visuals.sfx(ctx)
	local Audio = ctx.Audio
	local actor = ctx.actor
	local function sfx(name, position, scale)
		pcall(Audio.Emit, actor, name, position, { VolumeScale = scale or 1 })
	end
	return sfx
end
function Visuals.ring(ctx)
	local core = ctx.core
	local cast = ctx.cast
	local Effects = ctx.Effects
	local function ring(position, color, fromSize, toSize, time, thickness, detached)
		thickness = thickness or 0.5
		local p = core.Part(
			"EtherealShockRing",
			CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(thickness, fromSize, fromSize),
			color,
			0.2
		)
		if not detached then
			cast:Add(p)
		end
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		Effects:Create(
			p,
			TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = Vector3.new(thickness, toSize, toSize), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(p, time + 0.1)
		return p
	end
	return ring
end
function Visuals.dome(ctx)
	local core = ctx.core
	local cast = ctx.cast
	local Effects = ctx.Effects
	local function dome(position, color, fromSize, toSize, time, detached)
		local p = core.Part("EtherealShockSphere", CFrame.new(position), Vector3.one * fromSize, color, 0.2)
		if not detached then
			cast:Add(p)
		end
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.ForceField
		p.CastShadow = false
		Effects:Create(
			p,
			TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = Vector3.one * toSize, Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(p, time + 0.1)
		return p
	end
	return dome
end
function Visuals.pillar(ctx)
	local core = ctx.core
	local cast = ctx.cast
	local Effects = ctx.Effects
	local function pillar(position, height, width, time, color, detached)
		local p = core.Part(
			"EtherealLightPillar",
			CFrame.new(position + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(height, width, width),
			color,
			0.1
		)
		if not detached then
			cast:Add(p)
		end
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		Effects:Create(
			p,
			TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(height, 0.1, 0.1), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(p, time + 0.1)
		return p
	end
	return pillar
end
function Visuals.sparkle(ctx)
	local SPARKLE = ctx.SPARKLE
	local GOLD = ctx.GOLD
	local WHITE = ctx.WHITE
	local NSK = ctx.NSK
	local function sparkle(parent, rate, life, speed, size, colors)
		local e = Instance.new("ParticleEmitter")
		e.Texture = SPARKLE
		e.Rate = rate
		e.Lifetime = life
		e.Speed = speed
		e.LightEmission = 1
		e.Color = colors or ColorSequence.new(GOLD, WHITE)
		e.Size = NumberSequence.new({ NSK(0, 0), NSK(0.25, size), NSK(1, 0) })
		e.Transparency = NumberSequence.new({ NSK(0, 0), NSK(0.7, 0.15), NSK(1, 1) })
		e.Parent = parent
		return e
	end
	return sparkle
end
function Visuals.burst(ctx)
	local core = ctx.core
	local GOLD = ctx.GOLD
	local cast = ctx.cast
	local sparkle = ctx.sparkle
	local Effects = ctx.Effects
	local function burst(position, count, colors, speed, life, size, detached)
		local p = core.Part("EtherealBurst", CFrame.new(position), Vector3.one * 0.2, GOLD, 1)
		if not detached then
			cast:Add(p)
		end
		local e = sparkle(
			p,
			count * 10,
			NumberRange.new(life * 0.6, life),
			NumberRange.new(speed * 0.5, speed),
			size,
			colors
		)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Drag = 3
		task.delay(0.1, function()
			if e.Parent then
				e.Enabled = false
			end
		end)
		Effects.ReleaseAfter(p, life + 0.25)
		return p
	end
	return burst
end
function Visuals.solid(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local function solid(name, cframe, size, color, transparency, shape, material)
		local p = cast:Add(core.Part(name, cframe, size, color, transparency))
		if shape then
			p.Shape = shape
		end
		if material then
			p.Material = material
		end
		return p
	end
	return solid
end
function Visuals.loop(ctx)
	local function loop(part, radius, segments, color, width, plane, transparency)
		local points = {}
		for i = 1, segments do
			local t = (i - 1) / segments * math.pi * 2
			local c, s = math.cos(t) * radius, math.sin(t) * radius
			local a = Instance.new("Attachment")
			a.Position = plane == "Y" and Vector3.new(c, 0, s)
				or plane == "X" and Vector3.new(0, c, s)
				or Vector3.new(c, s, 0)
			a.Parent = part
			points[i] = a
		end
		for i = 1, segments do
			local b = Instance.new("Beam")
			b.Name = "EtherealRing"
			b.Attachment0 = points[i]
			b.Attachment1 = points[i % segments + 1]
			b.Segments = 1
			b.FaceCamera = true
			b.LightEmission = 1
			b.Width0 = width
			b.Width1 = width
			b.Color = ColorSequence.new(color)
			b.Transparency = NumberSequence.new(transparency or 0.15)
			b.Parent = part
		end
		return points
	end
	return loop
end
function Visuals.star(ctx)
	local function star(part, radius, count, skip, color, width)
		local verts = {}
		for i = 1, count do
			local t = (i - 1) / count * math.pi * 2
			local a = Instance.new("Attachment")
			a.Position = Vector3.new(math.cos(t) * radius, 0, math.sin(t) * radius)
			a.Parent = part
			verts[i] = a
		end
		for i = 1, count do
			local b = Instance.new("Beam")
			b.Name = "EtherealSigilStar"
			b.Attachment0 = verts[i]
			b.Attachment1 = verts[(i - 1 + skip) % count + 1]
			b.Segments = 1
			b.FaceCamera = true
			b.LightEmission = 1
			b.Width0 = width
			b.Width1 = width
			b.Color = ColorSequence.new(color)
			b.Transparency = NumberSequence.new(0.1)
			b.Parent = part
		end
	end
	return star
end
function Visuals.ticks(ctx)
	local function ticks(part, inner, outer, count, color, width)
		for i = 1, count do
			local t = (i - 1) / count * math.pi * 2
			local c, s = math.cos(t), math.sin(t)
			local reach = i % 3 == 0 and outer or inner + (outer - inner) * 0.55
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position = Vector3.new(c * inner, 0, s * inner)
			a1.Position = Vector3.new(c * reach, 0, s * reach)
			a0.Parent = part
			a1.Parent = part
			local b = Instance.new("Beam")
			b.Name = "EtherealSigilTick"
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Segments = 1
			b.FaceCamera = true
			b.LightEmission = 1
			b.Width0 = width
			b.Width1 = width
			b.Color = ColorSequence.new(color)
			b.Transparency = NumberSequence.new(0.2)
			b.Parent = part
		end
	end
	return ticks
end
Visuals.projectCube = require(script.Parent.Cube).projectCube
Visuals.fireworkBurst = require(script.Parent.Fireworks).fireworkBurst
Visuals.fireworkShell = require(script.Parent.Fireworks).fireworkShell
Visuals.firework = require(script.Parent.Fireworks).firework
Visuals.cardImpact = require(script.Parent.Fireworks).cardImpact
return table.freeze(Visuals)

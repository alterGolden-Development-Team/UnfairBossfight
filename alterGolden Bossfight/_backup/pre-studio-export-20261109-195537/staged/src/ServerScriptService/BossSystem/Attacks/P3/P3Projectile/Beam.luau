 
local Visuals = {}
function Visuals.Draw(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local a0 = ctx.a0
	local ACCENT = ctx.ACCENT
	local Effects = ctx.Effects
	local travel = ctx.travel
	local LINEAR = ctx.LINEAR
	local a1 = ctx.a1
	local isFinal = ctx.isFinal
	local HOT = ctx.HOT
	local WHITE = ctx.WHITE
	local QUAD = ctx.QUAD
	local IN = ctx.IN
	local SPARKLE = ctx.SPARKLE
	local points = ctx.points
	local index = ctx.index
	local sphere = ctx.sphere
	local ringAlong = ctx.ringAlong
	local normals = ctx.normals
	local panels = ctx.panels
	local anchor = cast:Add(
		core.Part("ProjectileGoldenReflectionBeam", CFrame.new(a0), Vector3.one * 0.1, ACCENT, 1)
	)
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Parent = anchor
	b.Parent = anchor
	a.Position = Vector3.zero
	b.Position = Vector3.zero
	Effects:Create(b, TweenInfo.new(travel, LINEAR), { Position = a1 - a0 }):Play()
	 
	local glowBeam = Instance.new("Beam")
	glowBeam.Name = "FixedGoldenMirrorSegment"
	glowBeam.Attachment0 = a
	glowBeam.Attachment1 = b
	local gw = isFinal and 10 or 7
	glowBeam.Width0 = gw
	glowBeam.Width1 = gw * 0.85
	glowBeam.Color = ColorSequence.new(ACCENT, HOT)
	glowBeam.FaceCamera = true
	glowBeam.LightEmission = 0.7
	glowBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0.5),
	})
	glowBeam.Parent = anchor
	 
	local coreBeam = Instance.new("Beam")
	coreBeam.Name = "FixedGoldenMirrorCore"
	coreBeam.Attachment0 = a
	coreBeam.Attachment1 = b
	local cw = isFinal and 4.4 or 3
	coreBeam.Width0 = cw
	coreBeam.Width1 = cw * 0.8
	coreBeam.Color = ColorSequence.new(WHITE, HOT)
	coreBeam.FaceCamera = true
	coreBeam.LightEmission = 1
	coreBeam.Transparency = NumberSequence.new(0.03)
	coreBeam.Parent = anchor
	 
	cast:Schedule(travel + 0.1, function()
		local burn = TweenInfo.new(1, QUAD, IN)
		Effects:Create(glowBeam, burn, { Width0 = 0, Width1 = 0 }):Play()
		Effects:Create(coreBeam, burn, { Width0 = 0, Width1 = 0 }):Play()
	end)
	 
	local head = cast:Add(
		core.Part("ProjectileBeamHead", CFrame.new(a0), Vector3.one * (isFinal and 6 or 4.5), WHITE, 0)
	)
	head.Shape = Enum.PartType.Ball
	head.Material = Enum.Material.Neon
	Effects:Create(head, TweenInfo.new(travel, LINEAR), { CFrame = CFrame.new(a1) }):Play()
	local headLight = Instance.new("PointLight")
	headLight.Color = ACCENT
	headLight.Brightness = isFinal and 16 or 10
	headLight.Range = isFinal and 30 or 22
	headLight.Parent = head
	local trail = Instance.new("ParticleEmitter")
	trail.Name = "BeamHeadSparks"
	trail.Texture = SPARKLE
	trail.Rate = 70
	trail.Color = ColorSequence.new(WHITE, ACCENT)
	trail.Lifetime = NumberRange.new(0.4, 0.8)
	trail.Speed = NumberRange.new(2, 8)
	trail.SpreadAngle = Vector2.new(180, 180)
	trail.LightEmission = 0.8
	trail.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	trail.Parent = head
	cast:Schedule(travel, function()
		trail.Enabled = false
		Effects:Create(head, TweenInfo.new(0.3), { Transparency = 1, Size = Vector3.one * 1 }):Play()
		Effects:Create(headLight, TweenInfo.new(0.4), { Brightness = 0, Range = 4 }):Play()
		 
		if not isFinal then
			local mirror = points[index + 1]
			sphere(mirror, WHITE, 2, 9, 0.35, 0.1)
			ringAlong(mirror, normals[index], WHITE, 2, 12, 0.45)
			local mirrorSparks = Instance.new("ParticleEmitter")
			mirrorSparks.Texture = SPARKLE
			mirrorSparks.Rate = 0
			mirrorSparks.Color = ColorSequence.new(WHITE, ACCENT)
			mirrorSparks.Lifetime = NumberRange.new(0.4, 0.8)
			mirrorSparks.Speed = NumberRange.new(10, 22)
			mirrorSparks.SpreadAngle = Vector2.new(180, 180)
			mirrorSparks.Drag = 2
			mirrorSparks.LightEmission = 0.8
			mirrorSparks.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.8),
				NumberSequenceKeypoint.new(1, 0),
			})
			if panels[index] and panels[index].Parent then
				mirrorSparks.Parent = panels[index]
				mirrorSparks:Emit(24)
			end
		end
	end)
	Effects.ReleaseAfter(head, travel + 0.5)
	Effects.ReleaseAfter(anchor, travel + 1.3)
end
return table.freeze(Visuals)

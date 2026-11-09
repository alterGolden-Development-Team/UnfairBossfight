local Visuals = {}
function Visuals.style(ctx)
	local function style(part, material)
		if material then
			part.Material = material
		end
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Massless = true
		return part
	end
	return style
end
function Visuals.makeRing(ctx)
	local function makeRing(part, thickness, color)
		part.Transparency = 1
		local gui = Instance.new("SurfaceGui")
		gui.Name = "GoldenChainRingGui"
		gui.Face = Enum.NormalId.Right  
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = Vector2.new(512, 512)
		gui.LightInfluence = 0
		gui.Brightness = 2
		gui.AlwaysOnTop = false
		gui.Parent = part
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = thickness
		stroke.Color = color
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = frame
		return stroke
	end
	return makeRing
end
function Visuals.sparks(ctx)
	local SPARK_TEXTURE = ctx.SPARK_TEXTURE
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local function sparks(parent, rate, speed, size, life)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "GoldenChainSparks"
		emitter.Texture = SPARK_TEXTURE
		emitter.Rate = rate
		emitter.Lifetime = NumberRange.new(life * 0.6, life)
		emitter.Speed = NumberRange.new(speed * 0.5, speed)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-180, 180)
		emitter.Drag = 2
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		emitter.Color = ColorSequence.new(BRIGHT, GOLD)
		emitter.LightEmission = 1
		emitter.LightInfluence = 0
		emitter.Parent = parent
		return emitter
	end
	return sparks
end
function Visuals.shock(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local GOLD = ctx.GOLD
	local style = ctx.style
	local makeRing = ctx.makeRing
	local BRIGHT = ctx.BRIGHT
	local TweenService = ctx.TweenService
	local function shock(position, from, to, duration, thickness)
		local part = cast:Add(
			core.Part(
				"GoldenChainShockwave",
				CFrame.new(position) * CFrame.Angles(0, 0, math.pi * 0.5),
				Vector3.new(0.1, from, from),
				GOLD,
				1
			)
		)
		part.Shape = Enum.PartType.Cylinder
		style(part)
		local stroke = makeRing(part, thickness or 24, BRIGHT)
		TweenService:Create(
			part,
			TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.1, to, to) }
		):Play()
		TweenService:Create(
			stroke,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Transparency = 1 }
		):Play()
	end
	return shock
end
return table.freeze(Visuals)

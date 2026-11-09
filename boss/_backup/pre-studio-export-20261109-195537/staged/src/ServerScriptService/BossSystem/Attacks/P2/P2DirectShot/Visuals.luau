local Visuals = {}
function Visuals.tw(ctx)
	local Effects = ctx.Effects
	local TweenService = ctx.TweenService
	local function tw(instance, duration, goal)
		local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween
		if instance:IsA("BasePart") then
			tween = Effects:Create(instance, info, goal)
		else
			tween = TweenService:Create(instance, info, goal)
		end
		tween:Play()
	end
	return tw
end
function Visuals.facing(ctx)
	local function facing(position, direction)
		local up = math.abs(direction.Y) > 0.98 and Vector3.xAxis or Vector3.yAxis
		return CFrame.lookAt(position, position + direction, up)
	end
	return facing
end
function Visuals.flashLight(ctx)
	local tw = ctx.tw
	local function flashLight(parent, brightness, range, color, duration)
		local light = Instance.new("PointLight")
		light.Brightness = brightness
		light.Range = range
		light.Color = color
		light.Shadows = false
		light.Parent = parent
		tw(light, duration, { Brightness = 0 })
	end
	return flashLight
end
function Visuals.vfxPart(ctx)
	local core = ctx.core
	local function vfxPart(cast, name, cf, size, color, transparency, shape)
		local p = cast:Add(core.Part(name, cf, size, color, transparency))
		p.Material = Enum.Material.Neon
		p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
		if shape then p.Shape = shape end
		return p
	end
	return vfxPart
end
function Visuals.ringPart(ctx)
	local vfxPart = ctx.vfxPart
	local function ringPart(cast, cf, diameter, color, thickness)
		local p = vfxPart(cast, "DirectShotRing", cf, Vector3.new(diameter, diameter, 0.05), color, 1)
		local strokes = {}
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			gui.CanvasSize = Vector2.new(256, 256)
			gui.LightInfluence = 0
			gui.Brightness = 2
			gui.Parent = p
			local circle = Instance.new("Frame")
			circle.AnchorPoint = Vector2.new(0.5, 0.5)
			circle.Position = UDim2.fromScale(0.5, 0.5)
			circle.Size = UDim2.fromScale(0.92, 0.92)
			circle.BackgroundTransparency = 1
			circle.Parent = gui
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = circle
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = thickness
			stroke.Color = color
			stroke.Parent = circle
			table.insert(strokes, stroke)
		end
		return p, strokes
	end
	return ringPart
end
function Visuals.shockwave(ctx)
	local ringPart = ctx.ringPart
	local tw = ctx.tw
	local function shockwave(cast, cf, from, to, color, duration)
		local p, strokes = ringPart(cast, cf, from, color, 14)
		tw(p, duration, { Size = Vector3.new(to, to, 0.05) })
		for _, stroke in ipairs(strokes) do
			tw(stroke, duration, { Transparency = 1, Thickness = 3 })
		end
	end
	return shockwave
end
function Visuals.sparkBurst(ctx)
	local vfxPart = ctx.vfxPart
	local WHITE = ctx.WHITE
	local KP = ctx.KP
	local function sparkBurst(cast, cf, count, color, speed, spread, life, size)
		local p = vfxPart(cast, "DirectShotSparks", cf, Vector3.one * 0.2, color, 1)
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.Color = ColorSequence.new(WHITE, color)
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Size = NumberSequence.new({ KP(0, size), KP(1, 0) })
		e.Transparency = NumberSequence.new({ KP(0, 0), KP(0.6, 0.15), KP(1, 1) })
		e.Lifetime = NumberRange.new(life * 0.6, life)
		e.Speed = NumberRange.new(speed * 0.4, speed)
		e.SpreadAngle = Vector2.new(spread, spread)
		e.Acceleration = Vector3.new(0, -50, 0)
		e.Drag = 3
		e.Rotation = NumberRange.new(0, 360)
		e.EmissionDirection = Enum.NormalId.Front
		e.Parent = p
		e:Emit(count)
	end
	return sparkBurst
end
function Visuals.piece(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local coils = ctx.coils
	local parts = ctx.parts
	local get_frame = ctx.get_frame
	local function piece(name, size, offset, color, neon)
		local p = cast:Add(core.Part(name, get_frame() * offset, size, color, 0))
		p.Material = neon and Enum.Material.Neon or Enum.Material.Metal
		table.insert(neon and coils or parts, { Part = p, Offset = offset })
	end
	return piece
end
return table.freeze(Visuals)

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
	local TAU = ctx.TAU
	local function makeRing(target, thickness, color, bothFaces, ticks)
		target.Transparency = 1
		local strokes = {}
		local faces = bothFaces and { Enum.NormalId.Right, Enum.NormalId.Left } or { Enum.NormalId.Right }
		for _, face in ipairs(faces) do
			local gui = Instance.new("SurfaceGui")
			gui.Name = "GoldenHandRingGui"
			gui.Face = face
			gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			gui.CanvasSize = Vector2.new(512, 512)
			gui.LightInfluence = 0
			gui.Brightness = 2
			gui.AlwaysOnTop = false
			gui.Parent = target
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
			strokes[#strokes + 1] = stroke
			if ticks then  
				for index = 1, ticks do
					local angle = index / ticks * TAU
					local tick = Instance.new("Frame")
					tick.AnchorPoint = Vector2.new(0.5, 0.5)
					tick.Position = UDim2.fromScale(0.5 + 0.4 * math.cos(angle), 0.5 + 0.4 * math.sin(angle))
					tick.Size = UDim2.fromScale(0.018, 0.09)
					tick.Rotation = math.deg(angle) + 90
					tick.BackgroundColor3 = color
					tick.BorderSizePixel = 0
					tick.Parent = frame
				end
			end
		end
		return strokes
	end
	return makeRing
end
function Visuals.sparks(ctx)
	local SPARK_TEXTURE = ctx.SPARK_TEXTURE
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local function sparks(parent, rate, speed, size, life)
		local e = Instance.new("ParticleEmitter")
		e.Name = "GoldenHandSparks"
		e.Texture = SPARK_TEXTURE
		e.Rate = rate
		e.Lifetime = NumberRange.new(life * 0.6, life)
		e.Speed = NumberRange.new(speed * 0.5, speed)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-180, 180)
		e.Drag = 2
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(BRIGHT, GOLD)
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Parent = parent
		return e
	end
	return sparks
end
function Visuals.dust(ctx)
	local SMOKE_TEXTURE = ctx.SMOKE_TEXTURE
	local function dust(parent, rate, size, life)
		local e = Instance.new("ParticleEmitter")
		e.Name = "GoldenHandDust"
		e.Texture = SMOKE_TEXTURE
		e.Rate = rate
		e.Lifetime = NumberRange.new(life * 0.7, life)
		e.Speed = NumberRange.new(2, 7)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-40, 40)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.5), NumberSequenceKeypoint.new(1, size) })
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Color = ColorSequence.new(Color3.fromRGB(255, 228, 120), Color3.fromRGB(200, 150, 40))
		e.LightEmission = 0.35
		e.LightInfluence = 0.5
		e.Parent = parent
		return e
	end
	return dust
end
function Visuals.part(ctx)
	local core = ctx.core
	local function part(cast, name, frame, size, color, alpha)
		return cast:Add(core.Part(name, frame, size, color, alpha))
	end
	return part
end
function Visuals.shock(ctx)
	local FLAT = ctx.FLAT
	local part = ctx.part
	local gold = ctx.gold
	local style = ctx.style
	local makeRing = ctx.makeRing
	local bright = ctx.bright
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function shock(cast, position, from, to, duration, thickness, facing)
		local frame = facing and CFrame.lookAt(position, position + facing) * CFrame.Angles(0, math.pi * 0.5, 0)
			or CFrame.new(position) * FLAT
		local ring = part(cast, "GoldenHandShockwave", frame, Vector3.new(0.15, from, from), gold, 1)
		ring.Shape = Enum.PartType.Cylinder
		style(ring)
		local strokes = makeRing(ring, thickness or 24, bright, facing ~= nil)
		Tween:Create(
			ring,
			TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.15, to, to) }
		):Play()
		for _, stroke in ipairs(strokes) do
			Tween:Create(
				stroke,
				TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Transparency = 1 }
			):Play()
		end
		Debris:AddItem(ring, duration + 0.1)
	end
	return shock
end
function Visuals.buildHand(ctx)
	local part = ctx.part
	local HAND_GOLD = ctx.HAND_GOLD
	local HAND_DARK = ctx.HAND_DARK
	local bright = ctx.bright
	local function buildHand(cast)
		local pieces, tips = {}, {}
		local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
		local METAL, NEON = Enum.Material.Metal, Enum.Material.Neon
		local ALONG_Y = CFrame.Angles(0, 0, math.pi * 0.5)  
		local ALONG_Z = CFrame.Angles(0, math.pi * 0.5, 0)  
		local function add(name, offset, size, color, material, shape, transparency)
			local piece = part(cast, name, CFrame.identity, size, color, transparency or 0)
			if shape then
				piece.Shape = shape
			end
			piece.Material = material
			piece.CastShadow = false
			if material == METAL then
				piece.Reflectance = 0.12
			end
			pieces[#pieces + 1] = { Part = piece, Offset = offset }
			return piece
		end
	
		 
		local palm = add("GoldenHandPalm", CFrame.identity, Vector3.new(8, 8, 2.4), HAND_GOLD, METAL)
		add("GoldenHandBackPlate", CFrame.new(0, 0.4, 1.45), Vector3.new(7, 6.6, 0.8), HAND_DARK, METAL)
		add(
			"GoldenHandPalmDisc",
			CFrame.new(0, -0.6, -1.25) * ALONG_Z,
			Vector3.new(0.3, 5.2, 5.2),
			bright,
			NEON,
			CYL,
			0.35
		)
		add("GoldenHandGem", CFrame.new(0, -0.6, -1.5), Vector3.one * 2.2, bright, NEON, BALL, 0.05)
	
		 
		local cuff =
			add("GoldenHandCuff", CFrame.new(0, -5.3, 0) * ALONG_Y, Vector3.new(2.6, 6.4, 6.4), HAND_DARK, METAL, CYL)
		add("GoldenHandCuffRingTop", CFrame.new(0, -4.05, 0) * ALONG_Y, Vector3.new(0.4, 7, 7), bright, NEON, CYL, 0.15)
		add(
			"GoldenHandCuffRingBottom",
			CFrame.new(0, -6.55, 0) * ALONG_Y,
			Vector3.new(0.4, 7, 7),
			bright,
			NEON,
			CYL,
			0.15
		)
	
		 
		 
		local function limb(basePosition, lean, segments)
			local frame = CFrame.new(basePosition) * CFrame.Angles(0, 0, lean)
			local last
			for _, seg in ipairs(segments) do
				frame = frame * CFrame.Angles(seg.Curl, 0, 0)
				add("GoldenHandJoint", frame, Vector3.one * seg.Diameter * 1.12, HAND_DARK, METAL, BALL)
				add(
					"GoldenHandSegment",
					frame * CFrame.new(0, seg.Length * 0.5, 0) * ALONG_Y,
					Vector3.new(seg.Length, seg.Diameter, seg.Diameter),
					HAND_GOLD,
					METAL,
					CYL
				)
				frame = frame * CFrame.new(0, seg.Length, 0)
				last = seg
			end
			tips[#tips + 1] = add("GoldenHandTip", frame, Vector3.one * last.Diameter * 1.05, bright, NEON, BALL, 0.05)
		end
		local fingerLengths = { { 2.6, 2.2, 1.8 }, { 2.9, 2.4, 2.0 }, { 2.7, 2.3, 1.9 }, { 2.1, 1.8, 1.5 } }
		local diameters, curls = { 1.8, 1.6, 1.4 }, { -0.08, -0.5, -0.55 }
		for index, lengths in ipairs(fingerLengths) do
			local x = (index - 2.5) * 2
			local segments = {}
			for s = 1, 3 do
				segments[s] = { Length = lengths[s], Diameter = diameters[s], Curl = curls[s] }
			end
			limb(Vector3.new(x, 3.8, 0), -x * 0.04, segments)  
		end
		limb(Vector3.new(-3.9, -1.4, -0.2), 0.85, {
			{ Length = 2.8, Diameter = 2.2, Curl = -0.15 },
			{ Length = 2.3, Diameter = 1.9, Curl = -0.45 },
		})
		return { Pieces = pieces, Palm = palm, Cuff = cuff, Tips = tips }
	end
	return buildHand
end
return table.freeze(Visuals)

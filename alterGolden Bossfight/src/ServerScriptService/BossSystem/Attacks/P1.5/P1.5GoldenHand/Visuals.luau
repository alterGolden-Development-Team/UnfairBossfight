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
	local MeshKit = require(game:GetService("ReplicatedStorage").BossShared.Presentation.MeshKit)
	-- finger poses: amount 0 = the reaching claw (the original static curls), 1 = a clenched fist (grabbing)
	local CLOSED = { 1.25, 1.5, 1.2 }
	local THUMB_CLOSED = { 0.5, 1.1 }
	local function buildHand(cast)
		local pieces, tips, limbs = {}, {}, {}
		local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
		local METAL, NEON = Enum.Material.Metal, Enum.Material.Neon
		local ALONG_Y = CFrame.Angles(0, 0, math.pi * 0.5)  
		local ALONG_Z = CFrame.Angles(0, math.pi * 0.5, 0)  
		-- the Blender hand (MeshKit kit BossHand, lobby/blender/boss_hand.py) when the place has it; else the old primitive one
		local meshes = MeshKit.Has("HandPalm") and MeshKit.Has("HandProx") and MeshKit.Has("HandMid") and MeshKit.Has("HandDist")
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
			local item = { Part = piece, Offset = offset }
			pieces[#pieces + 1] = item
			return piece, item
		end
		-- a Blender piece (its origin = the joint / palm centre), scaled along its own axes; returns the items so a pose can move them
		local container
		local function addMesh(model, offset, scale)
			local items = {}
			for _, p in ipairs(model:GetChildren()) do
				if p:IsA("BasePart") then
					local local_ = CFrame.new(p.Position * scale)
					p.Size = p.Size * scale
					p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
					p.Name = "GoldenHand" .. p.Name
					p.Parent = container
					cast:Add(p)
					local item = { Part = p, Offset = offset * local_, Local = local_ }
					pieces[#pieces + 1] = item
					items[#items + 1] = item
				end
			end
			model:Destroy()
			return items
		end
	
		local palm, cuff
		if meshes then
			-- invisible anchors keep the old contract: the palm hosts the trail/light/sparks, the cuff hosts the trail start
			palm = add("GoldenHandPalm", CFrame.identity, Vector3.one * 0.2, HAND_GOLD, METAL, nil, 1)
			container = palm.Parent
			cuff = add("GoldenHandCuff", CFrame.new(0, -5.3, 0), Vector3.one * 0.2, HAND_DARK, METAL, nil, 1)
			addMesh(MeshKit.Get("HandPalm"), CFrame.identity, Vector3.one)
			add("GoldenHandPalmDisc", CFrame.new(0, -0.6, -1.25) * ALONG_Z, Vector3.new(0.3, 3.4, 3.4), bright, NEON, CYL, 0.35)
			add("GoldenHandGem", CFrame.new(0, -0.6, -1.5), Vector3.one * 2.2, bright, NEON, BALL, 0.05)
			add("GoldenHandCuffRingTop", CFrame.new(0, -4.05, 0) * ALONG_Y, Vector3.new(0.3, 6.9, 6.9), bright, NEON, CYL, 0.3)
			add("GoldenHandCuffRingBottom", CFrame.new(0, -6.55, 0) * ALONG_Y, Vector3.new(0.3, 6.9, 6.9), bright, NEON, CYL, 0.3)
		else
			palm = add("GoldenHandPalm", CFrame.identity, Vector3.new(8, 8, 2.4), HAND_GOLD, METAL)
			add("GoldenHandBackPlate", CFrame.new(0, 0.4, 1.45), Vector3.new(7, 6.6, 0.8), HAND_DARK, METAL)
			add("GoldenHandPalmDisc", CFrame.new(0, -0.6, -1.25) * ALONG_Z, Vector3.new(0.3, 5.2, 5.2), bright, NEON, CYL, 0.35)
			add("GoldenHandGem", CFrame.new(0, -0.6, -1.5), Vector3.one * 2.2, bright, NEON, BALL, 0.05)
			cuff = add("GoldenHandCuff", CFrame.new(0, -5.3, 0) * ALONG_Y, Vector3.new(2.6, 6.4, 6.4), HAND_DARK, METAL, CYL)
			add("GoldenHandCuffRingTop", CFrame.new(0, -4.05, 0) * ALONG_Y, Vector3.new(0.4, 7, 7), bright, NEON, CYL, 0.15)
			add("GoldenHandCuffRingBottom", CFrame.new(0, -6.55, 0) * ALONG_Y, Vector3.new(0.4, 7, 7), bright, NEON, CYL, 0.15)
		end
	
		-- a finger (or the thumb): a chain of bones. Each bone knows how to put its pieces at a joint frame.
		local function limb(basePosition, lean, segments, closed)
			local record = { Base = basePosition, Lean = lean, Segments = segments, Closed = closed }
			for index, seg in ipairs(segments) do
				if meshes then
					local bone = index == #segments and "HandDist" or (index == 1 and "HandProx" or "HandMid")
					seg.Items = addMesh(MeshKit.Get(bone), CFrame.identity, Vector3.new(seg.Diameter, seg.Length, seg.Diameter))
					seg.Place = function(frame)
						for _, item in ipairs(seg.Items) do
							item.Offset = frame * item.Local
						end
					end
				else
					local _, joint = add("GoldenHandJoint", CFrame.identity, Vector3.one * seg.Diameter * 1.12, HAND_DARK, METAL, BALL)
					local _, body = add("GoldenHandSegment", CFrame.identity, Vector3.new(seg.Length, seg.Diameter, seg.Diameter), HAND_GOLD, METAL, CYL)
					seg.Place = function(frame)
						joint.Offset = frame
						body.Offset = frame * CFrame.new(0, seg.Length * 0.5, 0) * ALONG_Y
					end
				end
			end
			local last = segments[#segments]
			local tipSize = meshes and last.Diameter * 0.6 or last.Diameter * 1.05
			local tip, tipItem = add("GoldenHandTip", CFrame.identity, Vector3.one * tipSize, bright, NEON, BALL, 0.05)
			tips[#tips + 1] = tip
			record.Tip = tipItem
			limbs[#limbs + 1] = record
		end
		local fingerLengths = { { 2.6, 2.2, 1.8 }, { 2.9, 2.4, 2.0 }, { 2.7, 2.3, 1.9 }, { 2.1, 1.8, 1.5 } }
		local diameters, curls = { 1.8, 1.6, 1.4 }, { -0.08, -0.5, -0.55 }
		for index, lengths in ipairs(fingerLengths) do
			local x = (index - 2.5) * 2
			local segments = {}
			for s = 1, 3 do
				segments[s] = { Length = lengths[s], Diameter = diameters[s], Curl = curls[s] }
			end
			limb(Vector3.new(x, 3.8, 0), -x * 0.04, segments, CLOSED)  
		end
		limb(Vector3.new(-3.9, -1.4, -0.2), 0.85, {
			{ Length = 2.8, Diameter = 2.2, Curl = -0.15 },
			{ Length = 2.3, Diameter = 1.9, Curl = -0.45 },
		}, THUMB_CLOSED)
	
		-- amount 0..1: reaching claw -> fist. `flex` (radians, optional) is a small living wobble on the open fingers.
		local function setCurl(amount, flex)
			amount = math.clamp(amount, 0, 1)
			flex = (flex or 0) * (1 - amount)
			for _, record in ipairs(limbs) do
				local frame = CFrame.new(record.Base) * CFrame.Angles(0, 0, record.Lean * (1 - 0.6 * amount))
				for index, seg in ipairs(record.Segments) do
					local curl = seg.Curl + (-record.Closed[index] - seg.Curl) * amount - flex * (index == 1 and 0.6 or 1)
					frame = frame * CFrame.Angles(curl, 0, 0)
					seg.Place(frame)
					frame = frame * CFrame.new(0, seg.Length, 0)
				end
				record.Tip.Offset = frame
			end
		end
		setCurl(0)
		return { Pieces = pieces, Palm = palm, Cuff = cuff, Tips = tips, SetCurl = setCurl }
	end
	return buildHand
end
return table.freeze(Visuals)

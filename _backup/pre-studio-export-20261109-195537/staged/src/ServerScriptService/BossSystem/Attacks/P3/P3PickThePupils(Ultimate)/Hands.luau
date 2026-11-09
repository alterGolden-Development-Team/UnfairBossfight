 
local TweenService = game:GetService("TweenService")
local Style = require(script.Parent.Style)
local GOLD = Style.GOLD
local PALE = Style.PALE
local WHITE = Style.WHITE
local VIOLET = Style.VIOLET
local SPARKLE = Style.SPARKLE
local NEON_SOFTEN = Style.NEON_SOFTEN
local PULSE_SLOW = Style.PULSE_SLOW
local kp = NumberSequenceKeypoint.new
return function(context)
	local folder, frame = context.Folder, context.Frame
	local part, cylinder = context.Visuals.Part, context.Visuals.Cylinder
	local GOLD_HI = Color3.fromRGB(255, 208, 72)
	local GOLD_LO = Color3.fromRGB(190, 128, 18)

	 
	local function ellipsoid(parent, name, size, cf, color, material, alpha)
		local p = part(parent, name, size, cf, color, material, alpha)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		return p
	end
	local function sphere(parent, name, position, diameter, color, material, alpha)
		return part(
			parent,
			name,
			Vector3.one * diameter,
			CFrame.new(position),
			color,
			material,
			alpha,
			Enum.PartType.Ball
		)
	end
	 
	local function limb(parent, name, a, b, diameter, color, material)
		local delta = b - a
		local dir = delta.Unit
		local mid = (a + b) / 2
		local up = math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
		local cf = CFrame.lookAt(mid, mid + dir, up) * CFrame.Angles(-math.pi / 2, 0, 0)
		return cylinder(parent, name, diameter, delta.Magnitude, cf, color, material)
	end
	 
	local function pulse(object, property, from, to, seconds, phase)
		if property == "Transparency" then
			from += (1 - from) * NEON_SOFTEN
			to += (1 - to) * NEON_SOFTEN
		end
		object[property] = from
		local tween = TweenService:Create(
			object,
			TweenInfo.new(seconds * PULSE_SLOW, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ [property] = to }
		)
		object.Destroying:Connect(function()
			tween:Cancel()
		end)
		task.delay(phase or 0, function()
			if object.Parent then
				tween:Play()
			end
		end)
		return tween
	end
	 
	local function nail(parent, name, tip, dir, phase)
		local at = tip + Vector3.new(0, 0.7, 0) - dir * 0.3
		local n = ellipsoid(
			parent,
			name,
			Vector3.new(1.05, 0.28, 1.35),
			CFrame.lookAt(at, at + dir),
			WHITE,
			Enum.Material.Neon,
			0.1
		)
		pulse(n, "Transparency", 0.05, 0.6, 0.55, phase)
		return n
	end

	local function hand(side)
		local m = Instance.new("Model")
		m.Name = side < 0 and "GiantGoldenLeftHand" or "GiantGoldenRightHand"
		m.Parent = folder

		 
		local palm = part(m, "Palm", Vector3.new(6, 2, 5.5), CFrame.identity, GOLD, nil, 1)
		m.PrimaryPart = palm
		ellipsoid(m, "PalmBody", Vector3.new(9.8, 3.6, 8.8), CFrame.identity, GOLD)
		ellipsoid(m, "BackOfHand", Vector3.new(8.2, 2.3, 7), CFrame.new(0, 0.9, 0.2), GOLD_HI)
		ellipsoid(m, "PalmPad", Vector3.new(6.4, 1.2, 4.8), CFrame.new(0, -1.35, 0.3), GOLD_LO)

		 
		local lengths = { { 3.2, 2.8, 2.3 }, { 3.6, 3.1, 2.5 }, { 3.3, 2.9, 2.3 }, { 2.7, 2.3, 1.9 } }
		local curl = { 1, 0.85, 1.1, 1.35 }
		local widths = { 2.05, 1.85, 1.7 }
		local joints = { 2.4, 2.0, 1.85 }
		for r = 1, 4 do
			local point = Vector3.new(side * (3.3 - (r - 1) * 2.2), -0.1, -3.9)
			local lean = side * (0.12 - (r - 1) * 0.08)
			local k = curl[r]
			local pitches = { 0.1 * k, 0.34 * k, 0.6 * k }
			sphere(m, "Knuckle" .. r, point, joints[1], GOLD_HI)
			for s = 1, 3 do
				local dir = Vector3.new(lean, -math.sin(pitches[s]), -math.cos(pitches[s])).Unit
				local nextPoint = point + dir * lengths[r][s]
				limb(m, "Finger" .. r .. "_" .. s, point, nextPoint, widths[s], GOLD)
				if s < 3 then
					sphere(m, "Joint" .. r .. "_" .. s, nextPoint, joints[s + 1], GOLD_HI)
				else
					sphere(m, "Fingertip" .. r, nextPoint, 1.85, PALE)
					nail(m, "Nail" .. r, nextPoint, dir, r * 0.1)
				end
				if r == 3 and s == 1 then
					 
					local a, b = point + dir * 1.0, point + dir * 1.7
					limb(m, "Ring", a, b, widths[1] + 0.35, WHITE, Enum.Material.Neon)
					sphere(
						m,
						"RingGem",
						(a + b) / 2 + Vector3.new(0, 1.35, 0),
						1.0,
						VIOLET,
						Enum.Material.Neon
					)
				end
				point = nextPoint
			end
		end

		 
		local thumbBase = Vector3.new(side * 3.9, -0.3, 1.6)
		local d1 = Vector3.new(side * 0.72, -0.12, -0.62).Unit
		local d2 = Vector3.new(side * 0.4, -0.3, -0.85).Unit
		local t1 = thumbBase + d1 * 3.3
		local t2 = t1 + d2 * 2.8
		ellipsoid(
			m,
			"ThumbMuscle",
			Vector3.new(4.6, 3.2, 5.8),
			CFrame.new(side * 3.3, -0.5, 1.4) * CFrame.Angles(0, -side * 0.5, 0),
			GOLD
		)
		sphere(m, "ThumbBase", thumbBase, 2.8, GOLD_HI)
		limb(m, "Thumb1", thumbBase, t1, 2.5, GOLD)
		sphere(m, "ThumbJoint", t1, 2.4, GOLD_HI)
		limb(m, "Thumb2", t1, t2, 2.2, GOLD)
		sphere(m, "Thumbtip", t2, 2.2, PALE)
		nail(m, "ThumbNail", t2, d2, 0.5)

		 
		local function band(z, diameter, length, color, material, alpha)
			return cylinder(
				m,
				"Cuff",
				diameter,
				length,
				CFrame.new(0, 0, z) * CFrame.Angles(math.pi / 2, 0, 0),
				color,
				material,
				alpha
			)
		end
		band(4.6, 5.6, 2.2, GOLD)
		band(6.0, 7.4, 2.6, PALE)
		band(7.6, 7.9, 0.5, GOLD_HI)
		pulse(band(4.75, 7.7, 0.2, WHITE, Enum.Material.Neon, 0.1), "Transparency", 0.1, 0.65, 0.7)
		band(8.4, 7.0, 0.2, GOLD, Enum.Material.Neon, 0.2)
		sphere(m, "CuffGem", Vector3.new(0, 3.55, 6.0), 1.5, PALE, Enum.Material.Neon)

		 
		local fill = Instance.new("PointLight")
		fill.Color, fill.Range, fill.Brightness = PALE, 34, 2.5
		fill.Parent = palm
		pulse(fill, "Brightness", 1.8, 3.2, 1.1)

		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "HandSparkles"
		sparkles.Texture = SPARKLE
		sparkles.Color = ColorSequence.new(GOLD, WHITE)
		sparkles.LightEmission = 1
		sparkles.Rate = 10
		sparkles.Lifetime = NumberRange.new(0.6, 1.3)
		sparkles.Speed = NumberRange.new(2, 6)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new({ kp(0, 1), kp(1, 0) })
		sparkles.Parent = palm

		local ta0, ta1 = Instance.new("Attachment"), Instance.new("Attachment")
		ta0.Position, ta1.Position = Vector3.new(-4.6, 0.2, 1), Vector3.new(4.6, 0.2, 1)
		ta0.Parent, ta1.Parent = palm, palm
		local trail = Instance.new("Trail")
		trail.Name = "HandComet"
		trail.Attachment0, trail.Attachment1 = ta0, ta1
		trail.Lifetime, trail.MinLength = 0.45, 0.2
		trail.LightEmission, trail.FaceCamera = 1, true
		trail.Color = ColorSequence.new(PALE, GOLD)
		trail.Transparency = NumberSequence.new({ kp(0, 0.45), kp(1, 1) })
		trail.Parent = palm

		m:PivotTo(frame * CFrame.new(side * 95, 75, -60) * CFrame.Angles(0, math.pi, side * 0.6))
		return m
	end
	return { hand(-1), hand(1) }
end

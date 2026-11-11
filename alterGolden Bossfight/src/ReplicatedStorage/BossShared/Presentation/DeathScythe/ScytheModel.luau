


local Style = require(script.Parent.Style)
local Geometry = require(script.Parent.ScytheGeometry)

local ScytheModel = {}

local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	if parent then instance.Parent = parent end
	return instance
end

 
local function triangle(a, b, c, thickness, props, out)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b

	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))

	local w1 = make("WedgePart", props)
	w1.Size = Vector3.new(thickness, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)

	local w2 = make("WedgePart", props)
	w2.Size = Vector3.new(thickness, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)

	table.insert(out, w1)
	table.insert(out, w2)
end

function ScytheModel.Build(options)
	options = options or {}
	local geo = Geometry.Build(options.Detail or 1)
	local rng = Random.new(options.Seed or 11)
	local S = options.Scale or 1
	local low = options.Low == true
	local PS = math.max(1, math.sqrt(S))  

	local model = make("Model", { Name = options.Name or "DeathScythe" })
	local root = make("Part", {
		Name = "ScytheRoot", Size = Vector3.new(1, 1, 1), Transparency = 1, Anchored = true,
		CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
	}, model)
	model.PrimaryPart = root

	local entries = {}
	local gripPoint = Vector3.new(0, -3.4 * S, 0)  
	local function add(part, alpha)
		if S ~= 1 then  
			part.Size = part.Size * S
			part.CFrame = CFrame.new(part.CFrame.Position * S) * part.CFrame.Rotation
		end
		 
		 
		local dist = math.max(0, (part.CFrame.Position - gripPoint).Magnitude - part.Size.Magnitude * 0.4)
		part.Transparency = 1
		local weld = make("Weld", { Part0 = root, Part1 = part, C0 = root.CFrame:ToObjectSpace(part.CFrame) }, part)
		part.Parent = model
		table.insert(entries, { Part = part, Alpha = alpha or 0, Dist = dist, Level = 0, Fade = 0,
			Weld = weld, BaseSize = part.Size, BaseC0 = weld.C0 })  
		return part
	end
	local function solid(props)
		props.Anchored, props.CanCollide, props.CanQuery, props.CanTouch = false, false, false, false
		props.CastShadow, props.Massless = false, true
		return props
	end
	local function V(point, z)  
		return Vector3.new(-point[1], point[2], z or 0)
	end
	local function wedges(a, b, c, thickness, color, material)
		local out = {}
		triangle(a, b, c, thickness, solid({ Color = color, Material = material }), out)
		for _, wedge in ipairs(out) do add(wedge) end
	end
	local function cylinder(name, length, diameter, y, color, material)
		return add(make("Part", solid({
			Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter),
			CFrame = CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = color, Material = material,
		})))
	end
	local function glowLine(points, color, thick, wide)
		for i = 1, #points - 1 do
			local a, b = V(points[i]), V(points[i + 1])
			local length = (b - a).Magnitude
			if length > 0.05 then
				add(make("Part", solid({
					Name = "Glow", Size = Vector3.new(thick, wide, length + 0.2), CFrame = CFrame.lookAt((a + b) / 2, b),
					Color = color, Material = Enum.Material.Neon,
				})))
			end
		end
	end

	-- The Blender scythe (MeshKit "DeathScythe", lobby/blender/boss_gear.py): the blade is cut into slices along its length, so the
	-- grow-in still sweeps out from the grip. Without it, the scythe is built from wedges as before.
	local mesh = require(script.Parent.Parent.MeshKit).Get("DeathScythe")
	if mesh then
		for _, p in ipairs(mesh:GetChildren()) do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = false, false, false, false, false, true
				add(p, 0)
			end
		end
		mesh:Destroy()
	end
	for _, tri in ipairs(mesh and {} or geo.Triangles) do
		local kind = tri[5]
		local color, material
		if kind == "horn" then
			color, material = Style.BloodDark, Enum.Material.Slate
		elseif kind == "barb" then
			color, material = Style.Blood:Lerp(Style.BloodHot, 0.35), Style.BladeMaterial
		else
			local shade = 0.78 + rng:NextNumber() * 0.5  
			color = Color3.new(math.min(Style.Blood.R * shade, 1), math.min(Style.Blood.G * shade, 1), math.min(Style.Blood.B * shade, 1))
			material = Style.BladeMaterial
		end
		wedges(V(tri[1]), V(tri[2]), V(tri[3]), tri[4], color, material)
	end
	if not mesh then
		glowLine(geo.EdgeLine, Style.Edge, 0.55, 0.4)
		glowLine(geo.RimTop, Style.BloodHot, 0.5, 0.3)
		glowLine(geo.RimBottom, Style.BloodHot, 0.5, 0.3)
		cylinder("Shaft", 36, 1.3, 9.5, Style.BloodDark, Style.ShaftMaterial)
	end
	if options.Ghost then
		return { Model = model, Root = root, Entries = entries, Scale = S }
	end
	for _, y in ipairs(mesh and {} or { -6, -3.4, -0.8 }) do
		cylinder("Grip", 0.7, low and 1.4 or 1.9, y, Style.Blood, Enum.Material.Metal)
	end
	if not mesh then
	cylinder("Collar", 3.2, low and 1.5 or 3.6, 27.5, Style.BloodDark, Enum.Material.Metal)
	if not low then
		cylinder("CollarRing", 0.5, 4.2, 25.6, Style.Blood, Enum.Material.Metal)
		cylinder("CollarRing", 0.5, 4.2, 29.4, Style.Blood, Enum.Material.Metal)
	end
	for _, z in ipairs(low and { -0.58, 0.58 } or { -0.66, 0.66 }) do
		add(make("Part", solid({ Name = "Vein", Size = Vector3.new(0.22, 34, 0.22), CFrame = CFrame.new(0, 9.5, z),
			Color = Style.BloodHot, Material = Enum.Material.Neon })))
	end

	 
	local pommel = low and 1.4 or 1.9
	add(make("Part", solid({ Name = "Pommel", Shape = Enum.PartType.Ball, Size = Vector3.new(pommel, pommel, pommel),
		CFrame = CFrame.new(0, -9.2, 0), Color = Style.BloodHot, Material = Enum.Material.Neon })))
	local function spike(baseY, apexY, radius, thick, color)
		local apex = Vector3.new(0, apexY, 0)
		wedges(Vector3.new(-radius, baseY, 0), Vector3.new(radius, baseY, 0), apex, thick, color, Enum.Material.Metal)
		wedges(Vector3.new(0, baseY, -radius), Vector3.new(0, baseY, radius), apex, thick, color, Enum.Material.Metal)
	end
	if not low then
		spike(-9.6, -16.5, 1.0, 0.4, Style.Blood)
		spike(29.4, 41, 1.0, 0.45, Style.Blood)
	end
	for i = 0, low and -1 or 3 do
		local angle = math.pi * 0.25 + i * math.pi * 0.5
		local c, s = math.cos(angle), math.sin(angle)
		wedges(Vector3.new(1.6 * c, 26, 1.6 * s), Vector3.new(1.6 * c, 23.6, 1.6 * s), Vector3.new(5 * c, 19.5, 5 * s),
			0.4, Style.BloodDark, Enum.Material.Slate)
	end
	end -- not mesh

	 
	local gemPosition = Vector3.new(-2.8, 27.2, 0)
	local gem
	if low then  
		gem = add(make("Part", solid({ Name = "SoulGem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 3.4, 3.4),
			CFrame = CFrame.new(gemPosition) * CFrame.Angles(0, math.pi / 2, 0), Color = Style.BloodHot, Material = Enum.Material.Neon })), 0.05)
	else
		gem = add(make("Part", solid({ Name = "SoulGem", Shape = Enum.PartType.Ball, Size = Vector3.new(3.6, 3.6, 3.6),
			CFrame = CFrame.new(gemPosition), Color = Style.BloodHot, Material = Enum.Material.Neon })), 0.05)
	end
	local light = make("PointLight", { Color = Style.BloodHot, Range = math.min(60, 30 * S), Brightness = 0, Shadows = false }, gem)

	 
	local attachments = {}  
	local function attach(name, position)
		local attachment = make("Attachment", { Name = name, Position = position }, root)
		table.insert(attachments, { Attachment = attachment, Base = position })
		return attachment
	end
	local function emitterAt(position, props)
		local attachment = attach("Emitter", position * S)
		props.Enabled = false
		return make("ParticleEmitter", props, attachment)
	end
	local fade = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	local function size(from, to) return NumberSequence.new({ NumberSequenceKeypoint.new(0, from * PS), NumberSequenceKeypoint.new(1, to * PS) }) end
	local embers = emitterAt(gemPosition, {
		Rate = 26, Lifetime = NumberRange.new(0.7, 1.3), Speed = NumberRange.new(3, 9), SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 8, 0), LightEmission = 1, LightInfluence = 0, Transparency = fade,
		Size = size(0.8, 0),
		Color = ColorSequence.new(Style.BloodHot, Style.Blood), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120),
	})
	local drips = {}
	for _, point in ipairs(geo.DripPoints) do
		table.insert(drips, emitterAt(V(point), {
			Rate = 7, Lifetime = NumberRange.new(1, 1.6), Speed = NumberRange.new(0, 0.5), Acceleration = Vector3.new(0, -55, 0),
			LightEmission = 0.25, LightInfluence = 0.2, Orientation = Enum.ParticleOrientation.VelocityParallel,
			Size = size(0.55, 0.35),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.55) }),
			Color = ColorSequence.new(Style.Blood, Style.BloodDark),
		}))
	end
	local mist = emitterAt(V(geo.MistPoint), {
		Texture = "rbxasset://textures/particles/smoke_main.dds", Rate = 9, Lifetime = NumberRange.new(1.1, 1.8),
		Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(60, 60), LightEmission = 0.15, LightInfluence = 0.3,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40),
		Size = size(5, 11),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }),
		Color = ColorSequence.new(Style.Blood, Style.BloodDark),
	})
	local trailTip = attach("TrailTip", V(geo.Tip) * S)
	local trailBack = attach("TrailBack", V(geo.TrailBack) * S)
	local trail = make("Trail", {
		Attachment0 = trailTip, Attachment1 = trailBack, Enabled = false, Lifetime = 0.45, MinLength = 0.1, FaceCamera = true,
		LightEmission = 1, LightInfluence = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Style.Edge), ColorSequenceKeypoint.new(0.25, Style.BloodHot), ColorSequenceKeypoint.new(1, Style.Blood),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.6, 0.45), NumberSequenceKeypoint.new(1, 1),
		}),
	}, root)

	 
	 
	local scrape = {}
	if low then
		local points = { geo.Tip }
		for _, point in ipairs(geo.DripPoints) do table.insert(points, point) end
		for _, point in ipairs(points) do
			table.insert(scrape, emitterAt(V(point), {
				Rate = 55, Lifetime = NumberRange.new(0.25, 0.55), Speed = NumberRange.new(16, 38), SpreadAngle = Vector2.new(32, 32),
				EmissionDirection = Enum.NormalId.Back, Acceleration = Vector3.new(0, -80, 0), LightEmission = 1, LightInfluence = 0,
				Transparency = fade, Size = size(0.8, 0), Color = ColorSequence.new(Style.Edge, Style.BloodHot), Rotation = NumberRange.new(0, 360),
			}))
		end
	end

	local sorted = table.move(entries, 1, #entries, 1, {})
	table.sort(sorted, function(a, b) return a.Dist < b.Dist end)

	return {
		Model = model, Root = root, Entries = entries, Sorted = sorted, Gem = gem, Light = light,
		Embers = embers, Drips = drips, Mist = mist, Trail = trail, Scrape = scrape, Scale = S,
		Attachments = attachments, BaseLightRange = light.Range, CurrentScale = 1,
	}
end

 
function ScytheModel.SetTransparency(built, reveal, fade)
	local floor = math.max(1 - reveal, fade or 0)
	for _, entry in ipairs(built.Entries) do
		entry.Part.Transparency = math.max(entry.Alpha, floor)
	end
end

 
 
 
 
local MIN_PART = 0.001
function ScytheModel.SetScale(built, factor)
	factor = math.max(factor, 0.001)
	if built.CurrentScale == factor then return end
	built.CurrentScale = factor
	for _, entry in ipairs(built.Entries) do
		local size = entry.BaseSize * factor
		entry.Part.Size = Vector3.new(math.max(size.X, MIN_PART), math.max(size.Y, MIN_PART), math.max(size.Z, MIN_PART))
		entry.Weld.C0 = CFrame.new(entry.BaseC0.Position * factor) * entry.BaseC0.Rotation
	end
	for _, item in ipairs(built.Attachments or {}) do
		item.Attachment.Position = item.Base * factor
	end
	if built.Light then built.Light.Range = built.BaseLightRange * factor end
end

 
 
 
 
 
function ScytheModel.SetGrow(built, grow, fade)
	local list = built.Sorted
	local count = #list
	grow, fade = math.clamp(grow, 0, 1), fade or 0
	local shown = math.floor(grow * count + 0.5)
	local front = grow >= 1 and 0 or math.max(1, math.floor(count * 0.08))
	for index, entry in ipairs(list) do
		local level = 0
		if index <= shown - front then level = 2 elseif index <= shown then level = 1 end
		if entry.Level ~= level or entry.Fade ~= fade then
			entry.Level, entry.Fade = level, fade
			entry.Part.Transparency = level == 0 and 1 or math.max(entry.Alpha, fade, level == 1 and 0.6 or 0)
		end
	end
end

return ScytheModel


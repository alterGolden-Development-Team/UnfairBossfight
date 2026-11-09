local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local METAL, NEON, FABRIC, WOOD, LEATHER = Enum.Material.Metal, Enum.Material.Neon, Enum.Material.Fabric, Enum.Material.Wood, Enum.Material.Leather
local BALL, CYL, WEDGE = Enum.PartType.Ball, Enum.PartType.Cylinder, "Wedge"

local function holder(char)
	local h = char:FindFirstChild("ClassGear")
	if not h then
		h = Instance.new("Folder")
		h.Name = "ClassGear"
		h.Parent = char
	end
	return h
end
 
local function piece(char, limb, size, color, material, offset, shape, name, transparency)
	local to = char:FindFirstChild(limb)
	if not to then
		return
	end
	local p
	if shape == WEDGE then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if shape then
			p.Shape = shape
		end
	end
	p.Name = name or "Gear"
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CFrame = to.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = to, p
	w.Parent = p
	p.Parent = holder(char)
	return p
end
local function glow(p, color, range, brightness)
	if p then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = color, range or 8, brightness or 1.5, false
		l.Parent = p
	end
end
local function trail(p, color, length)
	if not p then
		return
	end
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 0, -length / 2), Vector3.new(0, 0, length / 2)
	a0.Parent, a1.Parent = p, p
	local t = Instance.new("Trail")
	t.Name = "SwingTrail"
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = ColorSequence.new(color, rgb(255, 255, 255))
	t.LightEmission = 1
	t.Lifetime = 0.18
	t.MinLength = 0.1
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
	t.Parent = p
end

local R = CFrame.Angles
local rad = math.rad
local WHITE_ = Color3.new(1, 1, 1)
local function W(p)
	if p then p:SetAttribute("ClassWeapon", true) end
	return p
end

local GRIP = CFrame.new(0, -1.05, 0)
local sin, cos = math.sin, math.cos
 
local function swingTrail(part, from, to, c1, c2, life)
	if not part then
		return
	end
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = from, to
	a0.Parent, a1.Parent = part, part
	local t = Instance.new("Trail")
	t.Name = "SwingTrail"
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = ColorSequence.new(c1, c2)
	t.LightEmission = 1
	t.Lifetime = life or 0.18
	t.MinLength = 0.05
	t.Enabled = false
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	t.Parent = part
end
local function tipAttachment(part, name)
	if part then
		local tip = Instance.new("Attachment")
		tip.Name = name or "Tip"
		tip.Parent = part
		return tip
	end
end
local function sparkle(att, c1, c2, rate, rise)
	if not att then
		return
	end
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(c1, c2)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.17), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(0.5, 1.3)
	e.Acceleration = Vector3.new(0, rise or 0, 0)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = rate or 9
	e.Parent = att
end

return {
	rgb = rgb,
	METAL = METAL,
	NEON = NEON,
	FABRIC = FABRIC,
	WOOD = WOOD,
	LEATHER = LEATHER,
	BALL = BALL,
	CYL = CYL,
	WEDGE = WEDGE,
	holder = holder,
	piece = piece,
	glow = glow,
	trail = trail,
	R = R,
	rad = rad,
	WHITE_ = WHITE_,
	W = W,
	GRIP = GRIP,
	sin = sin,
	cos = cos,
	swingTrail = swingTrail,
	tipAttachment = tipAttachment,
	sparkle = sparkle,
}

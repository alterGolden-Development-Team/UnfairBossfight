--!nonstrict
-- Small building toolkit for the lobby map builders. Everything is anchored, smooth and named; the builders yield now and then
-- so Studio stays responsive. Palette and materials live here so the areas stay consistent.
local CollectionService = game:GetService("CollectionService")

local Kit = {}
Kit.R = Random.new(1847)

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
Kit.rgb = rgb

Kit.C = {
	Gold = rgb(232, 182, 62), GoldDeep = rgb(150, 104, 28), GoldPale = rgb(255, 226, 150),
	Stone = rgb(150, 142, 128), StoneDark = rgb(92, 86, 80), StoneWarm = rgb(182, 164, 134), Marble = rgb(232, 226, 214),
	Grass = rgb(104, 142, 72), GrassDark = rgb(76, 112, 58), Wood = rgb(98, 66, 40), WoodDark = rgb(62, 42, 28), Plank = rgb(142, 102, 62),
	Sand = rgb(232, 208, 156), Rock = rgb(108, 98, 90), Sea = rgb(40, 150, 180), Leaf = rgb(70, 130, 62),
	Black = rgb(14, 14, 16), White = rgb(240, 240, 240), Ink = rgb(10, 9, 12), Cloud = rgb(245, 245, 250),
}
Kit.M = Enum.Material

local made = 0
local function pace()
	made += 1
	if made % 350 == 0 then
		task.wait()
	end
end

local function finish(p, parent, name, color, material, props)
	p.Name = name
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if color then p.Color = color end
	p.Material = material or Enum.Material.SmoothPlastic
	if props then
		for key, value in props do
			p[key] = value
		end
	end
	p.Parent = parent
	pace()
	return p
end

function Kit.folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Kit.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Kit.box(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Size, p.CFrame = size, cf
	return finish(p, parent, name, color, material, props)
end

function Kit.wedge(parent, name, size, cf, color, material, props)
	local p = Instance.new("WedgePart")
	p.Size, p.CFrame = size, cf
	return finish(p, parent, name, color, material, props)
end

function Kit.cyl(parent, name, length, diameter, cf, color, material, props)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size, p.CFrame = Vector3.new(length, diameter, diameter), cf
	return finish(p, parent, name, color, material, props)
end

function Kit.ball(parent, name, diameter, pos, color, material, props)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size, p.CFrame = Vector3.new(diameter, diameter, diameter), CFrame.new(pos)
	return finish(p, parent, name, color, material, props)
end

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

-- flat disc whose top is at pos.Y
function Kit.disc(parent, name, pos, diameter, thickness, color, material, props)
	return Kit.cyl(parent, name, thickness, diameter, CFrame.new(pos - Vector3.new(0, thickness / 2, 0)) * UPRIGHT, color, material, props)
end

-- standing cylinder from base upward
function Kit.column(parent, name, base, height, diameter, color, material, props)
	return Kit.cyl(parent, name, height, diameter, CFrame.new(base + Vector3.new(0, height / 2, 0)) * UPRIGHT, color, material, props)
end

function Kit.rock(parent, pos, size, color, material)
	local r = Kit.R
	local cf = CFrame.new(pos) * CFrame.Angles(r:NextNumber(-0.6, 0.6), r:NextNumber(0, 6.28), r:NextNumber(-0.6, 0.6))
	return Kit.box(parent, "Rock", size, cf, color or Kit.C.Rock, Kit.M.Slate)
end

function Kit.noShadow(part)
	part.CastShadow = false
	part.CanCollide = false
	return part
end

function Kit.tag(part, tagName)
	CollectionService:AddTag(part, tagName)
	return part
end

function Kit.light(part, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = color, range or 24, brightness or 1.5
	l.Parent = part
	return l
end

function Kit.particles(part, color, rate, speed, lifetime, size)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Rate = rate or 12
	e.Speed = NumberRange.new(speed or 2)
	e.Lifetime = NumberRange.new(lifetime or 2)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 0.7), NumberSequenceKeypoint.new(1, 0) })
	e.LightEmission = 0.8
	e.SpreadAngle = Vector2.new(40, 40)
	e.Parent = part
	return e
end

function Kit.sign(part, face, text, color, font, stroke)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color
	label.Font = font or Enum.Font.Garamond
	label.TextStrokeTransparency = stroke or 0.6
	label.Parent = gui
	return gui
end

-- A nameplate that floats over something.
function Kit.nameplate(part, title, subtitle, color, offset, range)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.fromOffset(340, 86)
	gui.StudsOffset = Vector3.new(0, offset or 4, 0)
	gui.MaxDistance = range or 170
	gui.LightInfluence = 0
	gui.Parent = part
	local head = Instance.new("TextLabel")
	head.Size = UDim2.new(1, 0, 0.62, 0)
	head.BackgroundTransparency = 1
	head.Font = Enum.Font.Garamond
	head.TextScaled = true
	head.Text = title
	head.TextColor3 = color
	head.TextStrokeTransparency = 0.25
	head.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Position = UDim2.fromScale(0, 0.62)
	sub.Size = UDim2.new(1, 0, 0.3, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextScaled = true
	sub.Text = subtitle
	sub.TextColor3 = Color3.new(1, 1, 1)
	sub.TextStrokeTransparency = 0.35
	sub.Parent = gui
	return gui
end

-- An invisible touch zone that sends whoever walks in to another area (PortalService listens for the tag).
function Kit.trigger(parent, size, cf, target)
	local t = Kit.box(parent, "Trigger", size, cf, nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	t:SetAttribute("Target", target)
	Kit.tag(t, "UnfairPortal")
	return t
end

-- A spot players arrive at. `cf` faces the way they should look.
function Kit.arrival(parent, cf, radius)
	local p = Kit.box(parent, "Arrival", Vector3.new(4, 0.2, 4), cf, nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	p:SetAttribute("Radius", radius or 8)
	return p
end

-- Ring of small blocks around a vertical portal face; tagged so the client slowly spins it.
function Kit.spinRing(parent, center, radius, count, color, material, speed, partSize)
	local model = Kit.model(parent, "SpinRing")
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		local cf = center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a)
		Kit.noShadow(Kit.box(model, "Link", partSize or Vector3.new(1.4, 0.9, 0.9), cf, color, material or Kit.M.Neon))
	end
	local anchor = Kit.box(model, "Center", Vector3.new(0.2, 0.2, 0.2), center, nil, nil, { Transparency = 1, CanCollide = false })
	model.PrimaryPart = anchor
	model:SetAttribute("SpinSpeed", speed or 0.4)
	Kit.tag(model, "UnfairSpin")
	return model
end

-- Small props that only decorate: no collision, no shadow, not hit by raycasts.
function Kit.detail(part)
	part.CastShadow = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- A broadleaf tree: tapered trunk with root flares and two limbs, and a canopy of overlapping balls in two shades so it is not one blob.
function Kit.tree(parent, base, height, trunkColor, leafColor, leafMaterial)
	local m = Kit.model(parent, "Tree")
	local r = Kit.R
	local bark = trunkColor or Kit.C.Wood
	local leaf = leafColor or Kit.C.Leaf
	local shade = leaf:Lerp(Color3.new(0, 0, 0), 0.18)
	local light = leaf:Lerp(Color3.new(1, 1, 0.7), 0.12)
	local d = height * 0.12
	Kit.column(m, "Trunk", base - Vector3.new(0, 0.5, 0), height * 0.55 + 0.5, d, bark, Kit.M.Wood)
	Kit.column(m, "TrunkTop", base + Vector3.new(0, height * 0.55, 0), height * 0.3, d * 0.72, bark, Kit.M.Wood)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2 + r:NextNumber(-0.3, 0.3)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local p = base + out * d * 0.55 + Vector3.new(0, d * 0.12, 0)
		Kit.detail(Kit.box(m, "Root", Vector3.new(d * 0.32, d * 0.3, d * 0.95), CFrame.lookAt(p, p + out - Vector3.new(0, 0.42, 0)), bark, Kit.M.Wood))
	end
	local top = base + Vector3.new(0, height * 0.82, 0)
	for _, side in { -1, 1 } do
		local a = r:NextNumber(0, 6.28)
		local out = Vector3.new(math.cos(a), 0, math.sin(a)) * side
		local from = base + Vector3.new(0, height * 0.5, 0)
		local to = from + out * height * 0.26 + Vector3.new(0, height * 0.26, 0)
		Kit.detail(Kit.box(m, "Limb", Vector3.new(d * 0.4, d * 0.4, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), bark, Kit.M.Wood))
		Kit.noShadow(Kit.ball(m, "Leaves", height * r:NextNumber(0.3, 0.38), to + Vector3.new(0, height * 0.04, 0), shade, leafMaterial or Kit.M.LeafyGrass))
	end
	Kit.noShadow(Kit.ball(m, "Leaves", height * r:NextNumber(0.5, 0.58), top, leaf, leafMaterial or Kit.M.LeafyGrass))
	for _ = 1, 3 do
		local offset = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-0.1, 0.7), r:NextNumber(-1, 1)) * height * 0.2
		Kit.noShadow(Kit.ball(m, "Leaves", height * r:NextNumber(0.3, 0.42), top + offset, r:NextNumber() > 0.5 and light or leaf, leafMaterial or Kit.M.LeafyGrass))
	end
	return m
end

-- A stylised pine: a short trunk under four overlapping cones, each cone a ring of wedges sloping outward.
function Kit.pine(parent, base, height, leafColor)
	local m = Kit.model(parent, "Pine")
	local r = Kit.R
	local leaf = leafColor or Kit.rgb(52, 98, 64)
	Kit.column(m, "Trunk", base - Vector3.new(0, 0.5, 0), height * 0.4, height * 0.07, Kit.C.WoodDark, Kit.M.Wood)
	local tiers, sides = 4, 7
	for i = 0, tiers - 1 do
		local t = i / tiers
		local radius = height * (0.3 - t * 0.19)
		local tierHeight = height * 0.3
		local bottom = height * (0.18 + t * 0.21)
		local yaw = r:NextNumber(0, 6.28)
		local tint = i % 2 == 0 and leaf or leaf:Lerp(Color3.new(0, 0, 0), 0.12)
		for k = 1, sides do
			local a = yaw + k / sides * math.pi * 2
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			local pos = base + Vector3.new(0, bottom + tierHeight / 2, 0) + out * radius / 2
			-- a wedge is tall at +Z and thin at -Z, so facing out puts the peak at the trunk
			Kit.noShadow(Kit.wedge(m, "Needles", Vector3.new(math.pi * 2 * radius / sides * 1.2, tierHeight, radius), CFrame.lookAt(pos, pos + out), tint, Kit.M.LeafyGrass))
		end
	end
	return m
end

-- A low bush: a few balls half sunk into the ground.
function Kit.bush(parent, base, size, color)
	local m = Kit.model(parent, "Bush")
	local r = Kit.R
	local leaf = color or Kit.C.GrassDark
	for i = 1, 3 do
		local s = size * r:NextNumber(0.6, 1)
		local offset = Vector3.new(r:NextNumber(-0.5, 0.5) * size, s * 0.18, r:NextNumber(-0.5, 0.5) * size)
		Kit.detail(Kit.ball(m, "Leaves", s, base + offset, i == 1 and leaf or leaf:Lerp(Color3.new(1, 1, 0.6), 0.1), Kit.M.LeafyGrass))
	end
	return m
end

-- A clump of flowers: little heads of one or two colours on a green cushion.
function Kit.flowers(parent, base, radius, colors)
	local m = Kit.model(parent, "Flowers")
	local r = Kit.R
	Kit.detail(Kit.ball(m, "Cushion", radius * 1.5, base - Vector3.new(0, radius * 0.5, 0), Kit.C.GrassDark, Kit.M.LeafyGrass))
	for _ = 1, math.floor(radius * 4) do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(0, radius * 0.75)
		local p = base + Vector3.new(math.cos(a) * d, radius * 0.18 + r:NextNumber(0, 0.35), math.sin(a) * d)
		Kit.detail(Kit.ball(m, "Bloom", r:NextNumber(0.45, 0.8), p, colors[r:NextInteger(1, #colors)], Kit.M.SmoothPlastic))
	end
	return m
end

-- Three blades of tall grass.
function Kit.tuft(parent, base, height, color)
	local m = Kit.model(parent, "Tuft")
	local r = Kit.R
	for i = 1, 3 do
		local yaw = i / 3 * math.pi * 2 + r:NextNumber(-0.4, 0.4)
		local h = height * r:NextNumber(0.7, 1)
		local cf = CFrame.new(base) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(r:NextNumber(0.15, 0.35), 0, 0) * CFrame.new(0, h / 2 - 0.2, 0)
		Kit.detail(Kit.wedge(m, "Blade", Vector3.new(0.18, h, 0.7), cf, color or Kit.C.GrassDark, Kit.M.Grass))
	end
	return m
end

local IRON = Color3.fromRGB(44, 40, 38)

-- The glass lantern itself, hanging from a hook whose top is 1.2 above `hang`.
local function lanternCage(m, hang, glowColor)
	Kit.detail(Kit.box(m, "Hook", Vector3.new(0.15, 1.6, 0.15), hang * CFrame.new(0, 1.2, 0), IRON, Kit.M.Metal))
	Kit.detail(Kit.box(m, "Cap", Vector3.new(1.7, 0.3, 1.7), hang * CFrame.new(0, 0.45, 0), IRON, Kit.M.Metal))
	Kit.detail(Kit.box(m, "CapTop", Vector3.new(0.9, 0.35, 0.9), hang * CFrame.new(0, 0.75, 0), IRON, Kit.M.Metal))
	Kit.detail(Kit.box(m, "Base", Vector3.new(1.4, 0.25, 1.4), hang * CFrame.new(0, -1.7, 0), IRON, Kit.M.Metal))
	for _, c in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
		Kit.detail(Kit.box(m, "Frame", Vector3.new(0.14, 2, 0.14), hang * CFrame.new(c[1] * 0.62, -0.6, c[2] * 0.62), IRON, Kit.M.Metal))
	end
	Kit.detail(Kit.box(m, "Glass", Vector3.new(1.15, 1.9, 1.15), hang * CFrame.new(0, -0.6, 0), Kit.rgb(255, 236, 190), Kit.M.Glass, { Transparency = 0.45 }))
	local flame = Kit.detail(Kit.ball(m, "Glow", 0.75, (hang * CFrame.new(0, -0.7, 0)).Position, glowColor or Kit.C.GoldPale, Kit.M.Neon))
	Kit.light(flame, Kit.rgb(255, 200, 120), 24, 1.3)
	return flame
end

-- A street lantern: stone foot, iron post, an arm, and a glass lantern hanging from it. `facing` is the way the arm points.
function Kit.lantern(parent, base, facing, color)
	local m = Kit.model(parent, "Lantern")
	local f = (facing or Vector3.new(0, 0, 1)) * Vector3.new(1, 0, 1)
	f = f.Magnitude > 0 and f.Unit or Vector3.new(0, 0, 1)
	local cf = CFrame.lookAt(base, base + f)
	Kit.box(m, "Foot", Vector3.new(2, 1.2, 2), cf * CFrame.new(0, 0.6, 0), Kit.C.StoneDark, Kit.M.Slate)
	Kit.column(m, "Post", base + Vector3.new(0, 1.2, 0), 11, 0.6, IRON, Kit.M.Metal)
	Kit.detail(Kit.ball(m, "Knob", 1, base + Vector3.new(0, 12.4, 0), IRON, Kit.M.Metal))
	Kit.detail(Kit.box(m, "Arm", Vector3.new(0.35, 0.35, 3.2), cf * CFrame.new(0, 11.6, -1.5), IRON, Kit.M.Metal))
	Kit.detail(Kit.box(m, "Brace", Vector3.new(0.25, 0.25, 2.2), cf * CFrame.new(0, 10.7, -0.8) * CFrame.Angles(math.rad(40), 0, 0), IRON, Kit.M.Metal))
	lanternCage(m, cf * CFrame.new(0, 9.6, -2.8), color)
	return m
end

-- A lantern on a wall bracket. `cf` sits on the wall's face with -Z pointing away from the wall; the lantern hangs just below it.
function Kit.wallLantern(parent, cf, color)
	local m = Kit.model(parent, "WallLantern")
	Kit.detail(Kit.box(m, "Plate", Vector3.new(1, 1.6, 0.2), cf * CFrame.new(0, 1.2, -0.1), IRON, Kit.M.Metal))
	Kit.detail(Kit.box(m, "Arm", Vector3.new(0.35, 0.35, 2.8), cf * CFrame.new(0, 1.6, -1.4), IRON, Kit.M.Metal))
	Kit.detail(Kit.box(m, "Brace", Vector3.new(0.25, 0.25, 2), cf * CFrame.new(0, 0.95, -0.75) * CFrame.Angles(math.rad(40), 0, 0), IRON, Kit.M.Metal))
	lanternCage(m, cf * CFrame.new(0, 0.4, -2.5), color)
	return m
end

-- A ring of short segments round a circle (fountain rims, chandeliers); a solid cylinder would hide what is inside.
function Kit.ring(parent, name, center, diameter, height, thickness, count, color, material)
	for i = 1, count do
		local a = i / count * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * diameter / 2, height / 2, math.sin(a) * diameter / 2)
		Kit.box(parent, name, Vector3.new(diameter * math.pi / count + 0.3, height, thickness), CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a))) * CFrame.Angles(0, math.rad(90), 0), color, material)
	end
end

-- A stone-footed wooden bench; `cf` is the centre of the seat on the ground, -Z is where you face when sitting.
function Kit.bench(parent, cf, length)
	local m = Kit.model(parent, "Bench")
	local l = length or 7
	for _, s in { -1, 1 } do
		Kit.box(m, "Leg", Vector3.new(0.9, 1.9, 2.2), cf * CFrame.new(s * (l / 2 - 0.9), 0.95, 0), Kit.C.Stone, Kit.M.Slate)
	end
	for i = 0, 2 do
		Kit.box(m, "Slat", Vector3.new(l, 0.3, 0.75), cf * CFrame.new(0, 2.05, -0.8 + i * 0.8), Kit.C.Plank, Kit.M.Wood)
	end
	for _, s in { -1, 1 } do
		Kit.detail(Kit.box(m, "Upright", Vector3.new(0.4, 2.6, 0.4), cf * CFrame.new(s * (l / 2 - 0.9), 3.3, 1.1) * CFrame.Angles(math.rad(-10), 0, 0), Kit.C.WoodDark, Kit.M.Wood))
	end
	for i = 0, 1 do
		Kit.detail(Kit.box(m, "Back", Vector3.new(l, 0.55, 0.25), cf * CFrame.new(0, 3.1 + i * 1, 1.2 + i * 0.17) * CFrame.Angles(math.rad(-10), 0, 0), Kit.C.Plank, Kit.M.Wood))
	end
	return m
end

function Kit.barrel(parent, base, height, diameter)
	local m = Kit.model(parent, "Barrel")
	local h, d = height or 4.4, diameter or 3.4
	Kit.column(m, "Staves", base, h, d, Kit.C.Wood, Kit.M.WoodPlanks)
	Kit.detail(Kit.column(m, "Belly", base + Vector3.new(0, h * 0.25, 0), h * 0.5, d + 0.3, Kit.C.Wood, Kit.M.WoodPlanks))
	for _, y in { 0.12, 0.88 } do
		Kit.detail(Kit.column(m, "Hoop", base + Vector3.new(0, h * y - 0.2, 0), 0.4, d + 0.12, Kit.rgb(60, 56, 54), Kit.M.Metal))
	end
	Kit.detail(Kit.column(m, "Lid", base + Vector3.new(0, h, 0), 0.12, d - 0.3, Kit.C.WoodDark, Kit.M.Wood))
	return m
end

function Kit.crate(parent, cf, size)
	local m = Kit.model(parent, "Crate")
	local s = size or 3.6
	Kit.box(m, "Box", Vector3.new(s, s, s), cf * CFrame.new(0, s / 2, 0), Kit.C.Plank, Kit.M.WoodPlanks)
	for _, y in { -1, 1 } do
		for _, z in { -1, 1 } do
			Kit.detail(Kit.box(m, "Edge", Vector3.new(s + 0.16, 0.36, 0.36), cf * CFrame.new(0, s / 2 + y * (s / 2 - 0.1), z * (s / 2 - 0.1)), Kit.C.WoodDark, Kit.M.Wood))
			Kit.detail(Kit.box(m, "Edge", Vector3.new(0.36, 0.36, s + 0.16), cf * CFrame.new(y * (s / 2 - 0.1), s / 2 + z * (s / 2 - 0.1), 0), Kit.C.WoodDark, Kit.M.Wood))
		end
	end
	return m
end

function Kit.palm(parent, base, height, lean)
	local m = Kit.model(parent, "Palm")
	local r = Kit.R
	local yaw = r:NextNumber(0, 6.28)
	local dir = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
	local p = base
	local segments = 6
	for i = 1, segments do
		local t = i / segments
		local nextP = base + Vector3.new(0, height * t, 0) + dir * (t * t) * (lean or height * 0.35)
		local mid = (p + nextP) / 2
		Kit.box(m, "Trunk", Vector3.new(height * 0.075 * (1.25 - t * 0.5), (nextP - p).Magnitude + 0.3, height * 0.075 * (1.25 - t * 0.5)), CFrame.lookAt(mid, nextP) * CFrame.Angles(math.rad(90), 0, 0), Kit.rgb(128, 98, 66), Kit.M.Wood)
		p = nextP
	end
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local length = height * 0.55
		local cf = CFrame.lookAt(p + out * length * 0.45 + Vector3.new(0, -length * 0.08, 0), p + out * length + Vector3.new(0, -length * 0.42, 0))
		Kit.noShadow(Kit.wedge(m, "Frond", Vector3.new(height * 0.16, 0.5, length), cf * CFrame.Angles(0, math.rad(180), 0), Kit.rgb(62, 142, 72), Kit.M.Grass))
	end
	return m
end

-- A stylised person made of blocks, standing at `cf` (feet on the ground). Used for statues and for the shopkeeper.
function Kit.figure(parent, name, cf, color, material, scale, options)
	options = options or {}
	local s = scale or 1
	local m = Kit.model(parent, name)
	local kneel = options.kneel
	local legLift = kneel and 0.7 * s or 0 -- kneeling shins lie on the ground (their half-height is 0.7)
	local torsoY = (kneel and 2.5 or 4.5) * s
	Kit.box(m, "Torso", Vector3.new(3, 3, 1.4) * s, cf * CFrame.new(0, torsoY, 0), color, material)
	Kit.box(m, "Head", Vector3.new(1.8, 1.8, 1.8) * s, cf * CFrame.new(0, torsoY + 2.45 * s, 0), options.headColor or color, material)
	if kneel then
		Kit.box(m, "LegL", Vector3.new(1.3, 1.4, 3.2) * s, cf * CFrame.new(-0.8 * s, legLift, 0.8 * s), color, material)
		Kit.box(m, "LegR", Vector3.new(1.3, 1.4, 3.2) * s, cf * CFrame.new(0.8 * s, legLift, 0.8 * s), color, material)
		Kit.box(m, "ArmL", Vector3.new(1.2, 3, 1.2) * s, cf * CFrame.new(-2.1 * s, torsoY + 0.6 * s, -1 * s) * CFrame.Angles(math.rad(70), 0, 0), color, material)
		Kit.box(m, "ArmR", Vector3.new(1.2, 3, 1.2) * s, cf * CFrame.new(2.1 * s, torsoY + 0.6 * s, -1 * s) * CFrame.Angles(math.rad(70), 0, 0), color, material)
	else
		Kit.box(m, "LegL", Vector3.new(1.35, 3, 1.35) * s, cf * CFrame.new(-0.8 * s, 1.5 * s, 0), options.legColor or color, material)
		Kit.box(m, "LegR", Vector3.new(1.35, 3, 1.35) * s, cf * CFrame.new(0.8 * s, 1.5 * s, 0), options.legColor or color, material)
		Kit.box(m, "ArmL", Vector3.new(1.2, 3, 1.2) * s, cf * CFrame.new(-2.1 * s, torsoY, 0), color, material)
		Kit.box(m, "ArmR", Vector3.new(1.2, 3, 1.2) * s, cf * CFrame.new(2.1 * s, torsoY, 0), color, material)
	end
	return m
end

return Kit

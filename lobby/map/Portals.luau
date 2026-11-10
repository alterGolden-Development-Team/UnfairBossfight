--!nonstrict
-- The three boss portals on the hub. Each one is built from its boss's world so it can be read from across the island without a sign:
-- gold and a crown for the Midas king, rough rock and sand for the island, black against white for the brothers.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local C, M = Kit.C, Kit.M

local Portals = {}

local function facing(pos, y)
	return CFrame.lookAt(pos, Vector3.new(0, y, 0))
end

local function steps(parent, cf, width, depth, count, color, material)
	for i = 1, count do
		Kit.box(parent, "Step", Vector3.new(width + (count - i) * 4, 1, depth + (count - i) * 4), cf * CFrame.new(0, i - 0.5, 0), color, material)
	end
end

-- The opening you walk into: a dark well with a slowly turning shimmer (ForceField material animates on its own), light pulled
-- inward by particles, and a soft glow on the ground. The trigger is just in front.
local function face(parent, cf, diameter, color, target, plain)
	local turned = CFrame.Angles(0, math.rad(90), 0)
	-- the front: a thin glowing skin you can see into, with a moving ForceField shimmer laid over it
	local disc = Kit.cyl(parent, "Face", 0.2, diameter, cf * turned, color, M.Neon, { Transparency = plain and 1 or 0.72, CanCollide = false, CastShadow = false })
	if not plain then
		Kit.noShadow(Kit.cyl(parent, "Shimmer", 0.2, diameter * 0.98, cf * CFrame.new(0, 0, -0.15) * turned, color:Lerp(Color3.new(1, 1, 1), 0.5), M.ForceField, { CanTouch = false, CanQuery = false, CanCollide = false }))
		-- behind it, a tunnel: rings stepping back, smaller and brighter toward a white-hot middle, over a dark well
		Kit.noShadow(Kit.cyl(parent, "Core", 0.3, diameter * 0.99, cf * CFrame.new(0, 0, 4.2) * turned, color:Lerp(Color3.new(0, 0, 0), 0.7), M.SmoothPlastic, { CanTouch = false, CanQuery = false }))
		for i, scale in { 0.86, 0.68, 0.5, 0.33, 0.18 } do
			local tone = color:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.16)
			Kit.noShadow(Kit.cyl(parent, "Tunnel", 0.2, diameter * scale, cf * CFrame.new(0, 0, 0.6 + i * 0.6) * turned, tone, M.Neon, { Transparency = 0.35 - i * 0.05, CanTouch = false, CanQuery = false, CanCollide = false }))
		end
		-- motes drifting in toward the middle
		local swirl = Instance.new("ParticleEmitter")
		swirl.Name = "Swirl"
		swirl.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5), color)
		swirl.LightEmission = 1
		swirl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
		swirl.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.2), NumberSequenceKeypoint.new(1, 1) })
		swirl.Lifetime = NumberRange.new(1.4, 2)
		swirl.Rate = 40
		swirl.Speed = NumberRange.new(-6, -4) -- negative: emitted from the rim, flying inward
		swirl.Shape = Enum.ParticleEmitterShape.Cylinder
		swirl.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		swirl.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
		swirl.RotSpeed = NumberRange.new(-90, 90)
		swirl.Parent = disc
		Kit.light(disc, color, 40, 1.6)
		-- the glow it throws on the ground in front
		Kit.noShadow(Kit.disc(parent, "Glow", (cf * CFrame.new(0, -diameter / 2 + 0.1, -5)).Position, diameter * 0.75, 0.06, color, M.Neon, { Transparency = 0.82, CanCollide = false, CanQuery = false, CanTouch = false }))
	end
	Kit.trigger(parent, Vector3.new(diameter * 0.9, diameter, 4), cf * CFrame.new(0, 0, -1), target)
	return disc
end

-- A store greatsword (Wirly_world's gothic blade) driven point-down into the ground at `base`, tinted through its own texture.
local function greatsword(parent, base, length, tint, lean)
	local model = Assets.Get("GothicSword")
	local blade = model:FindFirstChildWhichIsA("MeshPart", true)
	local k = length / math.max(blade.Size.X, blade.Size.Y, blade.Size.Z)
	blade.Size *= k
	-- the mesh's long axis is X with the hilt at +X; turned so the hilt is up and about a third of the blade is buried
	blade.CFrame = base * CFrame.Angles(0, 0, lean or 0) * CFrame.new(0, length * 0.36, 0) * CFrame.Angles(0, 0, math.rad(90))
	local look = blade:FindFirstChildOfClass("SurfaceAppearance")
	if look then
		look.Color = tint
	end
	blade.Name = "Greatsword"
	blade.Parent = parent
	model:Destroy()
	return blade
end

local function midas(root, pos, y)
	local m = Kit.model(root, "AlterGolden")
	local base = facing(pos, pos.Y)
	-- the top step is wide enough for the column feet (x = +-16, 7.5 across)
	steps(m, base, 42, 14, 3, C.GoldDeep, M.Metal)
	local cy = 3 + 15
	local center = base * CFrame.new(0, cy, 0)
	-- fluted columns of solid gold
	for _, side in { -1, 1 } do
		local x = side * 16
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			Kit.column(m, "Flute", (base * CFrame.new(x + math.cos(a) * 1.6, 3, math.sin(a) * 1.6)).Position, 34, 1.5, C.Gold, M.Foil)
		end
		Kit.column(m, "Core", (base * CFrame.new(x, 3, 0)).Position, 34, 3.4, C.GoldDeep, M.Metal)
		Kit.column(m, "Foot", (base * CFrame.new(x, 3, 0)).Position, 2, 7.5, C.Gold, M.Foil)
		Kit.column(m, "Head", (base * CFrame.new(x, 36, 0)).Position, 2.4, 7.5, C.Gold, M.Foil)
	end
	-- lintel, then a king's crown over the whole gate
	Kit.box(m, "Lintel", Vector3.new(42, 4, 7), base * CFrame.new(0, 40, 0), C.Gold, M.Foil)
	Kit.box(m, "CrownBand", Vector3.new(30, 3.4, 5.4), base * CFrame.new(0, 43.7, 0), C.GoldDeep, M.Metal)
	for i = -3, 3 do
		local height = 11 - math.abs(i) * 1.6
		local x = i * 4.4
		Kit.wedge(m, "Spike", Vector3.new(1.4, height, 3.6), base * CFrame.new(x, 45.4 + height / 2, 0.9) * CFrame.Angles(0, math.rad(90), 0), C.Gold, M.Foil)
		Kit.wedge(m, "Spike", Vector3.new(1.4, height, 3.6), base * CFrame.new(x, 45.4 + height / 2, -0.9) * CFrame.Angles(0, math.rad(-90), 0), C.Gold, M.Foil)
		local jewel = Kit.noShadow(Kit.ball(m, "Jewel", 2.2, (base * CFrame.new(x, 45.8 + height, 0)).Position, i % 2 == 0 and Kit.rgb(220, 50, 60) or Kit.rgb(60, 120, 230), M.Neon))
		jewel.Name = "Jewel"
	end
	face(m, center, 30, Kit.rgb(220, 150, 36), "Palace")
	Kit.spinRing(m, center * CFrame.new(0, 0, -0.5), 15.6, 44, C.GoldPale, M.Neon, 0.35)
	-- what the king's touch does: people turned to gold, kneeling at his door, and spilled coin
	for _, side in { -1, 1 } do
		-- on the grass beside the steps (the bottom step reaches x = +-27)
		local statue = base * CFrame.new(side * 31, 0, -6) * CFrame.Angles(0, side * math.rad(-20) + math.rad(180), 0)
		Kit.box(m, "Plinth", Vector3.new(9, 4, 9), statue * CFrame.new(0, 2, 0), C.StoneDark, M.Marble)
		Kit.noShadow(Kit.box(m, "PlinthTrim", Vector3.new(9.6, 0.5, 9.6), statue * CFrame.new(0, 3.9, 0), C.Gold, M.Foil))
		Kit.figure(m, "GildedVictim", statue * CFrame.new(0, 4.15, 0), C.Gold, M.Foil, 1.5, { kneel = true })
	end
	local r = Kit.R
	for _ = 1, 46 do
		-- spilled down the steps toward the plaza; each coin lies on the step it landed on (top step reaches z = -7, then -9, -11)
		local x, z = r:NextNumber(-20, 20), r:NextNumber(-15, -3)
		local y = (z >= -7 and 3 or z >= -9 and 2 or z >= -11 and 1 or 0) + 0.12
		local p = (base * CFrame.new(x, y, z)).Position
		Kit.noShadow(Kit.cyl(m, "Coin", 0.22, 1.5, CFrame.new(p + Vector3.new(0, r:NextNumber(0, 0.4), 0)) * CFrame.Angles(r:NextNumber(-0.2, 0.2), r:NextNumber(0, 6), math.rad(90) + r:NextNumber(-0.2, 0.2)), C.Gold, M.Foil))
	end
	Kit.nameplate(m:FindFirstChild("Lintel"), "alterGolden", "The Golden Encounter  -  Open", C.GoldPale, 19, 90)
	return m
end

local function fallen(root, pos, y)
	local m = Kit.model(root, "FallenNoob")
	local base = facing(pos, pos.Y)
	local r = Kit.R
	-- a beach dragged up into the sky
	Kit.disc(m, "Dune", pos + Vector3.new(0, 1.2, 0), 62, 1.6, C.Sand, M.Sand)
	Kit.disc(m, "DuneTop", pos + Vector3.new(0, 2.2, 0), 42, 1, C.Sand, M.Sand)
	for _ = 1, 16 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(18, 31)
		Kit.noShadow(Kit.disc(m, "Sandbank", pos + Vector3.new(math.cos(a) * d, 2.4, math.sin(a) * d), r:NextNumber(8, 18), 0.8, Kit.rgb(222, 196, 142), M.Sand))
	end
	-- the arch is piled boulders, wet at the foot and dry at the top
	local count = 19
	local radius = 18
	local center = base * CFrame.new(0, 16, 0)
	for i = 0, count do
		local a = math.rad(-22 + i / count * 224)
		local size = r:NextNumber(7.5, 10.5)
		local p = (center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, r:NextNumber(-0.8, 0.8))).Position
		Kit.rock(m, p, Vector3.new(size, size * r:NextNumber(0.8, 1.1), size * 0.9), i % 3 == 0 and C.StoneDark or C.Rock, M.Slate)
	end
	for _, side in { -1, 1 } do
		for h = 0, 2 do
			local size = 10 - h
			Kit.rock(m, (base * CFrame.new(side * 17.5, 4.5 + h * 6, r:NextNumber(-1, 1))).Position, Vector3.new(size + 2, size, size), C.Rock, M.Slate)
		end
	end
	face(m, center, 28, Kit.rgb(70, 190, 215), "Island")
	Kit.spinRing(m, center * CFrame.new(0, 0, -0.5), 14.5, 24, Kit.rgb(230, 214, 170), M.Sand, -0.22, Vector3.new(1.8, 1.2, 1.2))
	-- what washed up with it
	Kit.palm(m, (base * CFrame.new(-25, 2.6, -8)).Position, 30)
	Kit.palm(m, (base * CFrame.new(26, 2.6, 2)).Position, 24)
	Kit.box(m, "Driftwood", Vector3.new(17, 1.7, 2), base * CFrame.new(16, 3.2, -14) * CFrame.Angles(0.06, 0.5, 0.05), Kit.rgb(164, 142, 112), M.Wood)
	local anchor = base * CFrame.new(-19, 2.6, -14)
	Kit.box(m, "AnchorShaft", Vector3.new(1, 11, 1), anchor * CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, 0.32), C.StoneDark, M.CorrodedMetal)
	Kit.box(m, "AnchorBar", Vector3.new(6.5, 1, 1), anchor * CFrame.new(-1.6, 8.7, 0) * CFrame.Angles(0, 0, 0.32), C.StoneDark, M.CorrodedMetal)
	Kit.box(m, "AnchorFluke", Vector3.new(9, 1.1, 1.1), anchor * CFrame.new(1.2, 0.6, 0) * CFrame.Angles(0, 0, 0.32), C.StoneDark, M.CorrodedMetal)
	for _ = 1, 14 do
		local p = (base * CFrame.new(r:NextNumber(-22, 22), 2.8, r:NextNumber(-22, -7))).Position
		Kit.noShadow(Kit.ball(m, "Shell", r:NextNumber(0.6, 1.5), p, r:NextNumber() > 0.5 and Kit.rgb(248, 216, 200) or Kit.rgb(226, 158, 132), M.Marble))
	end
	Kit.nameplate(m:FindFirstChild("Face"), "TheFallenNoob's Private Island", "Coming soon", Kit.rgb(200, 240, 250), 19, 90)
	return m
end

-- Yin-yang drawn on a SurfaceGui so its curves are clean; rotates on the client (UnfairSpinGui).
local function yinYang(parent, cf, size)
	local plate = Kit.box(parent, "YinYangPlate", Vector3.new(size, size, 0.3), cf, nil, nil, { Transparency = 1, CanCollide = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(1024, 1024)
	gui.LightInfluence = 0
	gui.Parent = plate
	local function circle(frameParent, sizeScale, posX, posY, color, name)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Size = UDim2.fromScale(sizeScale, sizeScale)
		frame.Position = UDim2.fromScale(posX, posY)
		frame.BackgroundColor3 = color
		frame.BorderSizePixel = 0
		frame.Parent = frameParent
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
		return frame
	end
	local holder = circle(gui, 1, 0.5, 0.5, C.White, "Disc")
	holder.ClipsDescendants = false
	Kit.tag(holder, "UnfairSpinGui")
	local dark = circle(holder, 1, 0.5, 0.5, C.White, "Halves")
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.White), ColorSequenceKeypoint.new(0.4999, C.White),
		ColorSequenceKeypoint.new(0.5, C.Black), ColorSequenceKeypoint.new(1, C.Black),
	})
	gradient.Parent = dark
	circle(holder, 0.5, 0.5, 0.25, C.White, "HeadWhite")
	circle(holder, 0.5, 0.5, 0.75, C.Black, "HeadBlack")
	circle(holder, 0.16, 0.5, 0.25, C.Black, "EyeBlack")
	circle(holder, 0.16, 0.5, 0.75, C.White, "EyeWhite")
	return plate
end

local function brothers(root, pos, y)
	local m = Kit.model(root, "JeffAndFred")
	local base = facing(pos, pos.Y)
	-- the ground itself is split down the middle
	Kit.box(m, "GroundL", Vector3.new(29, 1, 34), base * CFrame.new(-14.5, 0.6, -6), C.White, M.Marble)
	Kit.box(m, "GroundR", Vector3.new(29, 1, 34), base * CFrame.new(14.5, 0.6, -6), C.Black, M.Slate)
	local center = base * CFrame.new(0, 15, 0)
	-- a ring of slabs, white on the black side and black on the white side, so each half carries a piece of the other
	local count = 36
	for i = 1, count do
		local a = i / count * math.pi * 2
		local onRight = math.cos(a) > 0
		local cf = center * CFrame.new(math.cos(a) * 15.5, math.sin(a) * 15.5, 0) * CFrame.Angles(0, 0, a)
		Kit.box(m, "RingSlab", Vector3.new(3.4, 2.9, 3.8), cf, onRight and C.Black or C.White, onRight and M.Slate or M.Marble)
	end
	for _, side in { -1, 1 } do
		local color, material = side > 0 and C.Black or C.White, side > 0 and M.Slate or M.Marble
		local spire = base * CFrame.new(side * 22, 1, -2)
		Kit.box(m, "Spire", Vector3.new(5, 34, 5), spire * CFrame.new(0, 17, 0), color, material)
		Kit.wedge(m, "SpireTip", Vector3.new(5, 9, 2.5), spire * CFrame.new(0, 38.5, 1.25), color, material)
		Kit.wedge(m, "SpireTip", Vector3.new(5, 9, 2.5), spire * CFrame.new(0, 38.5, -1.25) * CFrame.Angles(0, math.rad(180), 0), color, material)
		-- each brother's blade, driven into the ground on the other's side: white on the black ground, black on the white
		local tint = side > 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(52, 52, 58)
		greatsword(m, base * CFrame.new(side * 12, 1.1, -14), 17, tint, side * -0.12)
	end
	local plate = yinYang(m, center * CFrame.new(0, 0, -0.4), 28)
	face(m, center, 28, C.White, "Forest", true)
	Kit.nameplate(plate, "Jeff n' Fred Bizzare Brother", "Coming soon", C.White, 19, 90)
	return m
end

function Portals.Build(root, positions, y)
	local folder = Kit.folder(root, "Portals")
	midas(folder, positions.AlterGolden, y)
	fallen(folder, positions.FallenNoob, y)
	brothers(folder, positions.JeffAndFred, y)
	return folder
end

return Portals

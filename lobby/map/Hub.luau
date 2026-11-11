--!nonstrict
-- The floating island players start on (see docs/spec/lobby-redesign.md). Hub-and-spoke: spawn on the south edge looking north, with
-- all three boss portals on the skyline in front of you and the shop's giant sword on your right.
-- Nothing taller than a bench stands between the spawn and the portals. A spring on the west side runs off the edge as a waterfall.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local C, M = Kit.C, Kit.M

local Hub = {}
Hub.Y = 400
local Y = Hub.Y

local PORTALS = {
	AlterGolden = Vector3.new(0, Y, -84),
	FallenNoob = Vector3.new(-60, Y, -60),
	JeffAndFred = Vector3.new(60, Y, -60),
}
Hub.Portals = PORTALS

local WATER = Kit.rgb(78, 168, 206)
local POND = { x = -84, z = 34, d = 20 }
local FALLS = { x = -116, z = 42 } -- where the stream reaches the island edge
local FALLS_ANGLE = math.atan2(FALLS.z, FALLS.x)
local BLOOMS = {
	{ Kit.rgb(250, 236, 120), Kit.rgb(255, 255, 255) },
	{ Kit.rgb(236, 120, 150), Kit.rgb(255, 196, 214) },
	{ Kit.rgb(150, 130, 230), Kit.rgb(255, 255, 255) },
	{ Kit.rgb(255, 160, 80), Kit.rgb(250, 220, 110) },
}

local function v(x, z, y)
	return Vector3.new(x, Y + (y or 0), z)
end

local function angleGap(a, b)
	return math.abs((a - b + math.pi) % (math.pi * 2) - math.pi)
end

-- Places where nothing tall may grow: the spawn-to-portal view, the shop and its door, the paths, the plaza, the pond and the stream.
local function keepClear(x, z, margin)
	margin = margin or 0
	if z < -30 and math.abs(x) < 88 then return true end
	if x > 54 - margin and math.abs(z - 18) < 46 + margin then return true end
	if math.abs(x) < 14 + margin and z > 30 then return true end
	if x * x + z * z < (46 + margin) ^ 2 then return true end
	if (Vector2.new(x, z) - Vector2.new(POND.x, POND.z)).Magnitude < POND.d / 2 + 10 + margin then return true end
	if x < POND.x and math.abs(z - (POND.z + (x - POND.x) / (FALLS.x - POND.x) * (FALLS.z - POND.z))) < 10 + margin then return true end
	return false
end

-- Places where even knee-high growth would be in the way: buildings, paths, portal floors, the plaza and the water.
local function lowClear(x, z)
	if x > 58 and math.abs(z - 18) < 27 then return true end
	if math.abs(x) < 9 and math.abs(z) > 30 then return true end
	if x * x + z * z < 44 ^ 2 then return true end
	for _, p in PORTALS do
		if (Vector2.new(x, z) - Vector2.new(p.X, p.Z)).Magnitude < 33 then return true end
	end
	if (Vector2.new(x, z) - Vector2.new(POND.x, POND.z)).Magnitude < POND.d / 2 + 5 then return true end
	if x < POND.x and math.abs(z - (POND.z + (x - POND.x) / (FALLS.x - POND.x) * (FALLS.z - POND.z))) < 5 then return true end
	return false
end

local function piece(parent, name, cf, scale)
	local model = Assets.Get(name)
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

-- Stretches one mesh of a store asset to an exact size (mesh parts scale per axis; models only uniformly).
local function meshPiece(parent, name, size, cf, color, material)
	local part = Assets.Get(name):FindFirstChildWhichIsA("MeshPart", true)
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material
	part.Parent = parent
	return part
end

local function island(area)
	local land = Kit.folder(area, "Island")
	local r = Kit.R
	-- the walkable top stays a flat disc (paths, plaza and portals sit on it); the store meshes are the island around and under it:
	-- a grass cap whose ragged edge spills past the disc, and a long earth root hanging below (Starblaze Games' floating island)
	local WIDTH = 272
	Kit.disc(land, "Grass", v(0, 0), 250, 3, C.Grass, M.Grass)
	local capH = 26
	meshPiece(land, "IslandTop", Vector3.new(WIDTH, capH, WIDTH), CFrame.new(v(0, 0, -0.4 - capH / 2)), C.Grass, M.Grass)
	local baseH = 250
	local baseTop = Y - 0.4 - capH * 0.24
	meshPiece(land, "IslandBase", Vector3.new(WIDTH * 0.985, baseH, WIDTH * 0.985), CFrame.new(Vector3.new(0, baseTop - baseH / 2, 0)), Kit.rgb(161, 119, 91), M.SmoothPlastic)
	-- a few store rocks along the rim, half sunk, so the edge is not one clean line (none where the stream goes over)
	for a = 0, 350, 14 do
		local rad = math.rad(a + r:NextNumber(-4, 4))
		if angleGap(rad, FALLS_ANGLE) > math.rad(9) then
			local d = r:NextNumber(118, 126)
			local size = r:NextNumber(7, 14)
			local rock = Assets.Place(land, "Rock", CFrame.new(v(math.cos(rad) * d, math.sin(rad) * d, -size * 0.18)) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0), size, true)
			for _, part in rock:GetDescendants() do
				if part:IsA("BasePart") then
					part.Color = r:NextNumber() > 0.4 and C.Stone or C.StoneDark
					part.Material = M.Slate
				end
			end
		end
	end
	-- roots and vines trailing off the cap's edge
	local vine, root = Kit.rgb(70, 112, 58), Kit.rgb(92, 70, 50)
	for _ = 1, 40 do
		local a = r:NextNumber(0, 6.28)
		if angleGap(a, FALLS_ANGLE) > math.rad(8) then
			local d = r:NextNumber(128, 131)
			local length = r:NextNumber(8, 26)
			local top = v(math.cos(a) * d, math.sin(a) * d, -capH * 0.55)
			local isRoot = r:NextNumber() > 0.6
			Kit.detail(Kit.box(land, isRoot and "Root" or "Vine", Vector3.new(isRoot and 1.1 or 0.6, length, isRoot and 1.1 or 0.6), CFrame.new(top - Vector3.new(0, length / 2, 0)) * CFrame.Angles(r:NextNumber(-0.12, 0.12), a, r:NextNumber(-0.12, 0.12)), isRoot and root or vine, isRoot and M.Wood or M.LeafyGrass))
		end
	end
end

local function slabPath(area, from, to, width)
	local dir = to - from
	local length = dir.Magnitude
	local step = 6.5
	local right = dir.Unit:Cross(Vector3.yAxis)
	local r = Kit.R
	for i = 0, math.floor(length / step) do
		local p = from + dir.Unit * (i * step) + right * r:NextNumber(-0.5, 0.5)
		Kit.box(area, "Slab", Vector3.new(width + r:NextNumber(-1, 1.5), 0.6, step - 0.5), CFrame.lookAt(p + Vector3.new(0, 0.2, 0), p + dir) * CFrame.Angles(0, r:NextNumber(-0.05, 0.05), 0), r:NextNumber() > 0.5 and C.Stone or C.StoneWarm, M.Cobblestone, { CanCollide = false })
		-- grass creeping between the stones
		for _, side in { -1, 1 } do
			if r:NextNumber() > 0.55 then
				Kit.tuft(area, p + right * side * (width / 2 + r:NextNumber(0.3, 1.2)), r:NextNumber(1.2, 2), C.GrassDark)
			end
		end
	end
end

local function plaza(area)
	local f = Kit.folder(area, "Plaza")
	-- Blender paving (lobby/blender/hub.py HubPlaza): rings of pavers, gold rays and rings, a marble step for the fountain
	piece(f, "HubPlaza", CFrame.new(v(0, 0, 0))).Name = "Paving"
	-- the fountain (Blender, hub: HubFountain): three marble tiers, falling sheets, lion spouts, a gold armillary sphere on top
	local fountain = piece(f, "HubFountain", CFrame.new(v(0, 0, 1.5)))
	fountain.Name = "Fountain"
	for _, water in fountain:GetChildren() do
		if water.Name == "Water" then
			water.CanCollide, water.CanQuery = false, false
		end
	end
	-- spray off the top bowl and splash where the sheets land
	for _, spot in { { 16.6, 3.2, 10 }, { 11.0, 7.0, 6 }, { 4.1, 12.2, 3 } } do
		local e = Kit.detail(Kit.box(f, "Splash", Vector3.new(spot[2] * 2, 0.4, spot[2] * 2), CFrame.new(v(0, 0, 1.5 + spot[1])), nil, nil, { Transparency = 1, CanQuery = false, CanTouch = false }))
		local p = Instance.new("ParticleEmitter")
		p.Name = "Spray"
		p.Color = ColorSequence.new(Color3.fromRGB(235, 248, 255))
		p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.4) })
		p.Lifetime = NumberRange.new(0.6, 1.1)
		p.Rate = spot[3] * 3
		p.Speed = NumberRange.new(2, 5)
		p.SpreadAngle = Vector2.new(35, 35)
		p.Acceleration = Vector3.new(0, -18, 0)
		p.Parent = e
	end
	-- the old sundial: a ring of marble columns round the plaza, some whole, some broken with their drums lying beside them
	local r = Kit.R
	for i = 1, 10 do
		local a = (i + 0.5) / 10 * math.pi * 2
		local p = v(math.cos(a) * 41, math.sin(a) * 41, 0)
		if (p.Z > -20 or math.abs(p.X) > 30) and math.abs(p.X) > 16 then
			local whole = r:NextNumber() > 0.4
			local col = piece(f, whole and "HubColumn" or "HubColumnBroken", CFrame.lookAt(p, v(0, 0)) * CFrame.Angles(0, r:NextNumber(-0.4, 0.4), 0))
			col.Name = "Column"
			-- ivy climbing the shaft
			for k = 1, whole and 7 or 3 do
				local ia = k * 1.3 + i
				local ip = p + Vector3.new(math.cos(ia) * 2.35, 2 + k * 2.6, math.sin(ia) * 2.35)
				Kit.detail(Kit.box(f, "Ivy", Vector3.new(1.4, 1.8, 0.35), CFrame.lookAt(ip, ip + Vector3.new(math.cos(ia), 0, math.sin(ia))) * CFrame.Angles(0, 0, r:NextNumber(-0.6, 0.6)), k % 2 == 0 and C.GrassDark or C.Leaf, M.LeafyGrass))
			end
			Kit.bush(f, p + Vector3.new(math.cos(a) * 4, 0, math.sin(a) * 4), 4, C.GrassDark)
		end
	end
	-- benches round the fountain, facing it, away from the view to the portals; each one you can sit on
	for _, deg in { 45, 135, 180, 0 } do
		local a = math.rad(deg)
		local p = v(math.cos(a) * 30, math.sin(a) * 30, 0.85)
		local cf = CFrame.lookAt(p, v(0, 0, 0.85)) * CFrame.Angles(0, math.pi, 0)
		local bench = piece(f, "HubBench", cf)
		bench.Name = "Bench"
		local seat = Instance.new("Seat")
		seat.Name = "BenchSeat"
		seat.Size, seat.CFrame = Vector3.new(6, 0.4, 1.8), cf * CFrame.new(0, 2.1, 0.2)
		seat.Transparency, seat.Anchored = 1, true
		seat.Parent = bench
	end
	-- planters either side of the four ways into the plaza
	for _, deg in { 90, 270, 20, 160 } do
		local a = math.rad(deg)
		for _, side in { -1, 1 } do
			local p = v(math.cos(a) * 39 + math.cos(a + math.pi / 2) * side * 8, math.sin(a) * 39 + math.sin(a + math.pi / 2) * side * 8, 0)
			piece(f, "HubPlanter", CFrame.lookAt(p, v(0, 0))).Name = "Planter"
		end
	end
	-- a ball to kick about: plain physics, light and bouncy
	local ball = Kit.ball(f, "Ball", 4, v(18, 26, 4), Kit.rgb(230, 70, 60), M.SmoothPlastic, { Anchored = false })
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.4, 0.7)
end

local function water(area)
	local f = Kit.folder(area, "Spring")
	local r = Kit.R
	local center = v(POND.x, POND.z)
	Kit.noShadow(Kit.disc(f, "Pond", center + Vector3.new(0, 0.3, 0), POND.d, 0.5, WATER, M.SmoothPlastic, { Reflectance = 0.2, Transparency = 0.1, CanCollide = false }))
	Kit.noShadow(Kit.disc(f, "Shore", center + Vector3.new(0, 0.18, 0), POND.d + 4, 0.3, Kit.rgb(150, 136, 110), M.Pebble))
	for i = 1, 18 do
		local a = i / 18 * math.pi * 2
		local d = POND.d / 2 + 1.6
		Kit.rock(f, center + Vector3.new(math.cos(a) * d, 0.4, math.sin(a) * d), Vector3.new(r:NextNumber(1.8, 3.4), r:NextNumber(1.2, 2.2), r:NextNumber(1.8, 3.4)), r:NextNumber() > 0.5 and C.Stone or C.StoneDark)
	end
	-- lily pads
	for _ = 1, 6 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(2, POND.d / 2 - 2)
		Kit.noShadow(Kit.disc(f, "Lily", center + Vector3.new(math.cos(a) * d, 0.62, math.sin(a) * d), r:NextNumber(1.6, 2.6), 0.1, Kit.rgb(80, 150, 70), M.LeafyGrass))
	end
	-- the stream runs west and drops off the island
	local from = center + Vector3.new(-POND.d / 2 + 1, 0, 0)
	local to = v(FALLS.x, FALLS.z)
	local dir = to - from
	local steps = math.floor(dir.Magnitude / 4)
	for i = 0, steps do
		local t = i / steps
		local p = from + dir * t + dir.Unit:Cross(Vector3.yAxis) * math.sin(t * 6) * 1.2
		Kit.noShadow(Kit.box(f, "Stream", Vector3.new(5 + math.sin(i) * 0.6, 0.4, 4.6), CFrame.lookAt(p + Vector3.new(0, 0.26, 0), p + dir + Vector3.new(0, 0.26, 0)), WATER, M.SmoothPlastic, { Reflectance = 0.2, Transparency = 0.1, CanCollide = false }))
		for _, side in { -1, 1 } do
			if i % 2 == 0 then
				Kit.rock(f, p + dir.Unit:Cross(Vector3.yAxis) * side * 3.4 + Vector3.new(0, 0.3, 0), Vector3.new(r:NextNumber(1.2, 2.4), r:NextNumber(0.8, 1.6), r:NextNumber(1.2, 2.4)), C.Stone)
			end
		end
	end
	-- an arched stone footbridge where the stream is easiest to see
	local mid = from + dir * 0.45
	local across = dir.Unit:Cross(Vector3.yAxis)
	piece(f, "HubBridge", CFrame.lookAt(mid, mid + across)).Name = "Bridge"
	-- the falls: two sheets and mist where the water leaves the rock
	local out = Vector3.new(math.cos(FALLS_ANGLE), 0, math.sin(FALLS_ANGLE))
	local edge = v(FALLS.x, FALLS.z) + out * 6
	local face = CFrame.lookAt(edge, edge + out)
	Kit.noShadow(Kit.box(f, "Lip", Vector3.new(6, 0.8, 10), face * CFrame.new(0, 0.05, 1), WATER, M.SmoothPlastic, { Reflectance = 0.2, Transparency = 0.1, CanCollide = false }))
	local drop = 170
	local sheet = Kit.detail(Kit.box(f, "Falls", Vector3.new(5.4, drop, 1), face * CFrame.new(0, -drop / 2 + 0.4, -4.4), Kit.rgb(196, 230, 246), M.SmoothPlastic, { Transparency = 0.25 }))
	Kit.detail(Kit.box(f, "FallsOuter", Vector3.new(7.6, drop * 0.8, 0.5), face * CFrame.new(0, -drop * 0.4 - 4, -5.2), Kit.rgb(230, 246, 255), M.SmoothPlastic, { Transparency = 0.6 }))
	local streak = Instance.new("ParticleEmitter")
	streak.Name = "Streaks"
	streak.Color = ColorSequence.new(Color3.new(1, 1, 1))
	streak.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	streak.Size = NumberSequence.new(1.4)
	streak.Rate = 24
	streak.Speed = NumberRange.new(0)
	streak.Acceleration = Vector3.new(0, -40, 0)
	streak.Lifetime = NumberRange.new(2.4)
	streak.LightEmission = 0.2
	streak.Parent = sheet
	local mist = Kit.detail(Kit.box(f, "Mist", Vector3.new(6, 2, 6), face * CFrame.new(0, -2, -5), nil, nil, { Transparency = 1 }))
	Kit.particles(mist, Color3.new(1, 1, 1), 10, 1.5, 2.4, 4)
end

local function flora(area)
	local f = Kit.folder(area, "Flora")
	local r = Kit.R
	-- round-crowned trees from Blender (hub.py), most leafy, some in blossom
	for _ = 1, 30 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(58, 110)
		local p = v(math.cos(a) * d, math.sin(a) * d, 0)
		if not keepClear(p.X, p.Z, 4) then
			local blossom = r:NextNumber() < 0.22
			local tree = piece(f, blossom and "HubTree2" or "HubTree1", CFrame.new(p - Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0), r:NextNumber(0.8, 1.15))
			tree.Name = "Tree"
			local leaf = not blossom and tree:FindFirstChild("Leaf")
			if leaf then
				leaf.Color = ({ Kit.rgb(72, 121, 60), Kit.rgb(88, 140, 66), Kit.rgb(60, 104, 52) })[r:NextInteger(1, 3)]
			end
		end
	end
	-- low growth: bushes, flower clumps and grass tufts; all fine in sightlines because they are knee-high
	for _ = 1, 40 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(46, 112)
		local p = v(math.cos(a) * d, math.sin(a) * d, 0)
		if not lowClear(p.X, p.Z) then
			Kit.bush(f, p, r:NextNumber(3.5, 6), r:NextNumber() > 0.5 and C.GrassDark or C.Leaf)
		end
	end
	for _ = 1, 34 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(46, 114)
		local p = v(math.cos(a) * d, math.sin(a) * d, 0.2)
		if not lowClear(p.X, p.Z) then
			Kit.flowers(f, p, r:NextNumber(1.8, 3.2), BLOOMS[r:NextInteger(1, #BLOOMS)])
		end
	end
	for _ = 1, 110 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(42, 117)
		local p = v(math.cos(a) * d, math.sin(a) * d, 0)
		if not lowClear(p.X, p.Z) then
			Kit.tuft(f, p, r:NextNumber(1.4, 2.6), r:NextNumber() > 0.5 and C.GrassDark or C.Grass)
		end
	end
	-- a few mossy boulders
	for _ = 1, 8 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(70, 108)
		local p = v(math.cos(a) * d, math.sin(a) * d, 0)
		if not keepClear(p.X, p.Z, 2) then
			-- two or three stones leaning together, half buried
			local size = r:NextNumber(4, 8)
			for k = 1, r:NextInteger(2, 3) do
				local s2 = size * r:NextNumber(0.55, 1)
				Kit.rock(f, p + Vector3.new(r:NextNumber(-1, 1) * size * 0.5, s2 * 0.2, r:NextNumber(-1, 1) * size * 0.5), Vector3.new(s2 * 1.3, s2, s2 * 1.1), k == 1 and C.Stone or C.StoneDark)
			end
			Kit.tuft(f, p + Vector3.new(size * 0.7, 0, 0), 2.2, C.GrassDark)
		end
	end
end

local function satellites(area)
	local f = Kit.folder(area, "Satellites")
	local r = Kit.R
	-- small islands drifting round the hub: Starblaze Games' floating island, scaled down and turned so no two look alike
	for _, s in { { -190, 40, -34, 60 }, { 180, -130, 26, 50 }, { -150, -210, 40, 70 }, { 210, 130, -46, 54 }, { -40, 230, -58, 76 } } do
		local model = Assets.Get("SkyIsland")
		local _, box = model:GetBoundingBox()
		model:ScaleTo(model:GetScale() * s[4] / math.max(box.X, box.Z))
		model:PivotTo(CFrame.new(v(s[1], s[2], 0)) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0))
		-- put its grass on the height we want
		local cap
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") and part.MeshId == "rbxassetid://7383572612" then
				cap = part
			end
		end
		if cap then
			model:PivotTo(model:GetPivot() + Vector3.new(0, s[3] - (cap.Position.Y + cap.Size.Y / 2 - Y), 0))
		end
		model.Name = "Satellite"
		model.Parent = f
	end
	-- a sea of cloud below sells the height
	for _ = 1, 44 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(130, 620)
		local base = v(math.cos(a) * d, math.sin(a) * d, r:NextNumber(-290, -230))
		for _ = 1, 5 do
			local size = r:NextNumber(50, 130)
			Kit.noShadow(Kit.ball(f, "Cloud", size, base + Vector3.new(r:NextNumber(-50, 50), r:NextNumber(-14, 14), r:NextNumber(-50, 50)), C.Cloud, M.SmoothPlastic, { Transparency = 0.12 }))
		end
	end
end

-- A fingerpost by the spawn so a first-time player knows where things are.
local function signpost(area, base)
	local m = Kit.model(area, "Signpost")
	Kit.column(m, "Post", base, 11, 0.9, C.WoodDark, M.Wood)
	Kit.detail(Kit.ball(m, "Finial", 1.3, base + Vector3.new(0, 11.2, 0), C.Gold, M.Foil))
	local boards = {
		{ "THE RELIQUARY", Vector3.new(84, Y, 18), 9.2 },
		{ "THE BOSSES", Vector3.new(0, Y, -84), 7.6 },
		{ "THE SPRING", v(POND.x, POND.z), 6 },
	}
	for _, b in boards do
		local dir = ((b[2] - base) * Vector3.new(1, 0, 1)).Unit
		-- the board's +X runs along `dir`, so the tip and the arrows point the way
		local cf = CFrame.lookAt(base + Vector3.new(0, b[3], 0), base + Vector3.new(0, b[3], 0) + dir) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(3.4, 0, 0)
		local board = Kit.box(m, "Board", Vector3.new(6.4, 1.3, 0.3), cf, C.Plank, M.Wood)
		Kit.wedge(m, "Tip", Vector3.new(0.3, 1.3, 1), cf * CFrame.new(3.7, 0, 0) * CFrame.Angles(0, math.rad(-90), 0), C.Plank, M.Wood)
		Kit.sign(board, Enum.NormalId.Front, b[1] .. "  >", C.WoodDark, Enum.Font.Garamond, 1)
		Kit.sign(board, Enum.NormalId.Back, "<  " .. b[1], C.WoodDark, Enum.Font.Garamond, 1)
	end
	return m
end

function Hub.Build(root)
	local area = Kit.folder(root, "Hub")
	island(area)
	plaza(area)
	water(area)
	slabPath(area, v(0, 68), v(0, 40), 9)
	slabPath(area, v(0, -36), v(0, -74), 9)
	slabPath(area, v(-30, -24), v(-54, -52), 7)
	slabPath(area, v(30, -24), v(54, -52), 7)
	slabPath(area, v(38, 8), v(72, 18), 8)
	slabPath(area, v(-38, 6), v(POND.x + POND.d / 2 + 3, POND.z - 4), 6)
	flora(area)
	satellites(area)
	-- iron lamp posts along the paths
	for _, spot in { v(-10, 54), v(10, 54), v(-74, -30), v(74, -30), v(-14, -60), v(14, -60), v(56, 2), v(56, 34), v(-62, 26) } do
		local lamp = piece(area, "HubLamp", CFrame.new(spot))
		lamp.Name = "Lamp"
		local glow = Kit.noShadow(Kit.ball(lamp, "Flame", 1.1, spot + Vector3.new(0, 11, 0), C.GoldPale, M.Neon, { CanCollide = false, CanQuery = false, CanTouch = false }))
		Kit.light(glow, Kit.rgb(255, 214, 150), 26, 1.1)
	end
	-- a domed pavilion looking over the spring
	piece(area, "HubGazebo", CFrame.lookAt(v(-74, 72), v(POND.x, POND.z))).Name = "Gazebo"
	-- a big tree with a rope swing on its low bough (the bough runs out along the tree's front, local -Z)
	local treeCF = CFrame.lookAt(v(-40, 88, -0.4), v(-40, 60, -0.4))
	piece(area, "HubSwingTree", treeCF).Name = "SwingTree"
	local swing = Kit.model(area, "Swing")
	local branch = treeCF.LookVector
	local hangA, hangB = (treeCF * CFrame.new(0, 11.6, -13.4)).Position, (treeCF * CFrame.new(0, 11.6, -16.8)).Position
	local seatCenter = (hangA + hangB) / 2 - Vector3.new(0, 8.2, 0)
	local seatCF = CFrame.fromMatrix(seatCenter, branch, Vector3.yAxis)
	local plank = piece(swing, "HubSwingSeat", seatCF)
	local main = plank:FindFirstChild("Wood")
	for _, part in plank:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			if part ~= main then
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = main, part
				w.Parent = part
			end
		end
	end
	local seat = Instance.new("Seat")
	seat.Name = "SwingSeat"
	seat.Size, seat.CFrame = Vector3.new(4, 0.3, 1.6), seatCF * CFrame.new(0, 0.3, 0)
	seat.Transparency, seat.Anchored = 1, false
	seat.Parent = swing
	local sw = Instance.new("WeldConstraint")
	sw.Part0, sw.Part1 = main, seat
	sw.Parent = seat
	for _, hang in { hangA, hangB } do
		local top = Kit.box(swing, "Hook", Vector3.new(0.3, 0.3, 0.3), CFrame.new(hang), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		local a0 = Instance.new("Attachment")
		a0.Parent = top
		local a1 = Instance.new("Attachment")
		a1.Parent = main
		a1.WorldPosition = Vector3.new(hang.X, seatCenter.Y + 0.2, hang.Z)
		local rope = Instance.new("RopeConstraint")
		rope.Attachment0, rope.Attachment1 = a0, a1
		rope.Length = hang.Y - seatCenter.Y - 0.2
		rope.Visible, rope.Thickness = true, 0.18
		rope.Color = BrickColor.new("Brown")
		rope.Parent = top
	end
	signpost(area, v(13, 60))

	-- spawn: facing north at the portals, the first thing you see is every boss at once
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(v(0, 72, 0.6))
	spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
	spawn.Color, spawn.Material = C.Marble, M.Marble
	spawn.Parent = area
	Kit.noShadow(Kit.disc(area, "SpawnRing", v(0, 72, 1.2), 13, 0.2, C.Gold, M.Foil))
	Kit.noShadow(Kit.disc(area, "SpawnRingIn", v(0, 72, 1.3), 11.6, 0.2, C.Marble, M.Marble))
	Kit.arrival(area, CFrame.new(v(0, 66, 4)), 8)

	-- Azusa's spot beside the path out of spawn (SidePlaceService stands her here, in the mymeo125 avatar), with a ring of flowers
	local azusaAt = v(-13, 58, 0)
	Kit.box(area, "AzusaSpot", Vector3.new(1, 1, 1), CFrame.lookAt(azusaAt, v(0, 66, 0)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	Kit.noShadow(Kit.disc(area, "AzusaRing", azusaAt + Vector3.new(0, 0.2, 0), 7, 0.2, Kit.rgb(150, 196, 110), M.Grass))
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		Kit.noShadow(Kit.ball(area, "AzusaFlower", 0.5, azusaAt + Vector3.new(math.cos(a) * 3.3, 0.35, math.sin(a) * 3.3), i % 2 == 0 and Kit.rgb(255, 176, 214) or Kit.rgb(255, 240, 250), M.Neon))
	end
	return area
end

return Hub

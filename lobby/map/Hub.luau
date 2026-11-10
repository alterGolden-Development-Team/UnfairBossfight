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

local ringWall = Kit.ring

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

local function fountain(f)
	-- a store fountain (MR_MohamedTarek's two-tier marble one) on a gold-rimmed step
	local center = v(0, 0, 0.92)
	Kit.column(f, "FountainStep", v(0, 0, 0.1), 0.8, 28, C.Marble, M.Marble)
	ringWall(f, "FountainStepLip", v(0, 0, 0.6), 28, 0.35, 1, 32, C.Gold, M.Foil)
	local model = Assets.Place(f, "Fountain", CFrame.new(center), 26, true)
	model.Name = "Fountain"
end

local function plaza(area)
	local f = Kit.folder(area, "Plaza")
	Kit.disc(f, "Floor", v(0, 0, 0.5), 76, 1, C.StoneWarm, M.Slate)
	Kit.noShadow(Kit.disc(f, "Ring", v(0, 0, 0.62), 72, 0.2, C.Gold, M.Foil))
	Kit.noShadow(Kit.disc(f, "RingIn", v(0, 0, 0.72), 68, 0.2, C.StoneWarm, M.Slate))
	Kit.noShadow(Kit.disc(f, "Medallion", v(0, 0, 0.82), 26, 0.2, C.Gold, M.Foil))
	Kit.noShadow(Kit.disc(f, "MedallionIn", v(0, 0, 0.92), 22, 0.2, C.Stone, M.Slate))
	-- eight gold rays from the medallion to the ring, pointing at everything there is to do
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + math.pi / 8
		local p = v(math.cos(a) * 23.5, math.sin(a) * 23.5, 0.78)
		Kit.noShadow(Kit.box(f, "Ray", Vector3.new(0.9, 0.12, 21), CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a))), C.GoldDeep, M.Metal))
	end
	fountain(f)
	-- the old sundial: a ruined column ring around the plaza, overgrown
	local r = Kit.R
	for i = 1, 10 do
		local a = (i + 0.5) / 10 * math.pi * 2
		local p = v(math.cos(a) * 41, math.sin(a) * 41, 0)
		if (p.Z > -20 or math.abs(p.X) > 30) and math.abs(p.X) > 16 then
			local height = r:NextNumber() > 0.4 and 26 or r:NextNumber(7, 14)
			Kit.disc(f, "Base", p + Vector3.new(0, 1, 0), 7.5, 1.4, C.Marble, M.Marble)
			Kit.column(f, "Column", p + Vector3.new(0, 1, 0), height, 5, C.Marble, M.Marble)
			if height > 20 then
				Kit.disc(f, "Cap", p + Vector3.new(0, height + 2.2, 0), 7.5, 1.4, C.Marble, M.Marble)
				Kit.noShadow(Kit.disc(f, "CapTrim", p + Vector3.new(0, height + 0.9, 0), 6, 0.5, C.Gold, M.Foil))
			else
				-- the fallen top lies beside its stump
				local out = (p - v(0, 0)).Unit
				local tangent = out:Cross(Vector3.yAxis)
				local piece = p + out * 4 + tangent * r:NextNumber(-3, 3) + Vector3.new(0, 2.3, 0)
				Kit.cyl(f, "Drum", 6, 4.6, CFrame.lookAt(piece, piece + tangent) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(r:NextNumber(-0.2, 0.2), 0, 0), C.Marble, M.Marble)
				Kit.detail(Kit.cyl(f, "Chip", 1.4, 2.6, CFrame.new(p + out * -3 + tangent * 2 + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0.3, r:NextNumber(0, 6), 1.2), C.Marble, M.Marble))
			end
			-- ivy climbing the shaft
			for k = 1, math.floor(height / 3) do
				local ia = k * 1.3 + i
				local ip = p + Vector3.new(math.cos(ia) * 2.5, 1 + k * 2.6, math.sin(ia) * 2.5)
				Kit.detail(Kit.box(f, "Ivy", Vector3.new(1.4, 1.8, 0.35), CFrame.lookAt(ip, ip + Vector3.new(math.cos(ia), 0, math.sin(ia))) * CFrame.Angles(0, 0, r:NextNumber(-0.6, 0.6)), k % 2 == 0 and C.GrassDark or C.Leaf, M.LeafyGrass))
			end
			Kit.bush(f, p + Vector3.new(math.cos(a) * 3, 0, math.sin(a) * 3), 4, C.GrassDark)
		end
	end
	-- benches around the fountain, facing it, away from the view to the portals
	for _, deg in { 45, 135, 180 } do
		local a = math.rad(deg)
		local p = v(math.cos(a) * 30, math.sin(a) * 30, 0.72)
		Kit.bench(f, CFrame.lookAt(p, v(0, 0, 0.72)), 8)
	end
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
	-- a little plank bridge where the stream is easiest to see
	local mid = from + dir * 0.45
	for k = -2, 2 do
		local p = mid + dir.Unit * k * 1.75 + Vector3.new(0, 0.7, 0)
		Kit.box(f, "Bridge", Vector3.new(1.6, 0.4, 10), CFrame.lookAt(p, p + dir.Unit:Cross(Vector3.yAxis)) * CFrame.Angles(0, 0, Kit.R:NextNumber(-0.03, 0.03)), C.Plank, M.Wood)
	end
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
	-- trees are the store island's own low-poly tree (Starblaze Games), in three greens and a few in blossom
	local leafTints = { Kit.rgb(72, 121, 60), Kit.rgb(88, 140, 66), Kit.rgb(60, 104, 52) }
	for _ = 1, 30 do
		local a, d = r:NextNumber(0, 6.28), r:NextNumber(58, 110)
		local p = v(math.cos(a) * d, math.sin(a) * d, 0)
		if not keepClear(p.X, p.Z, 4) then
			local blossom = r:NextNumber() < 0.16
			local tree = Assets.Place(f, "Tree", CFrame.new(p - Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0), r:NextNumber(22, 34))
			for _, part in tree:GetDescendants() do
				if part:IsA("MeshPart") and part.MeshId == "rbxassetid://7383573087" then
					part.Color = blossom and Kit.rgb(240, 172, 196) or leafTints[r:NextInteger(1, #leafTints)]
					part.CastShadow = true
				end
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
	for _, spot in {
		{ v(-10, 54), Vector3.xAxis }, { v(10, 54), -Vector3.xAxis },
		{ v(-74, -30), Vector3.new(1, 0, -1) }, { v(74, -30), Vector3.new(-1, 0, -1) },
		{ v(-14, -60), Vector3.xAxis }, { v(14, -60), -Vector3.xAxis },
		{ v(56, 2), Vector3.zAxis }, { v(56, 34), -Vector3.zAxis },
		{ v(-62, 26), Vector3.new(0, 0, -1) },
	} do
		Kit.lantern(area, spot[1], spot[2])
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
	return area
end

return Hub

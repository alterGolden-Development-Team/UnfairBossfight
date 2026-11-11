--!nonstrict
--[[
 Builds Azusa's training grounds into Workspace.World (run in the Tutorial place's Studio window, edit mode):
   require(game.ServerStorage.MapBuilder).Build()
 A floating rock island at dusk. In the middle the round training floor (Dojo kit DojoArena, 70 radius; World.ArenaCenter marks its
 centre, TutorialService fights there), ringed by sakura trees, with training posts and stone lanterns. You arrive outside a red torii
 on the south side (World.Spawn) and walk in. Petals drift over everything.
 Blender pieces: the Dojo kit (lobby/blender/realm.py: DojoGate, DojoLantern, DojoPost, SakuraTree, DojoArena).
]]
local Lighting = game:GetService("Lighting")

local api = {}
local DOJO_KIT = 82016519813626
local R = Random.new(915)
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local M = Enum.Material
local SKIN = {
	Red = { M.SmoothPlastic, rgb(190, 40, 44) }, Black = { M.SmoothPlastic, rgb(24, 20, 22) }, Gold = { M.Foil, rgb(232, 182, 62) },
	Wood = { M.Wood, rgb(112, 76, 48) }, WoodDark = { M.Wood, rgb(64, 42, 28) }, Stone = { M.Slate, rgb(168, 160, 148) },
	StoneWarm = { M.Limestone, rgb(206, 186, 150) }, Rope = { M.Fabric, rgb(214, 190, 140) }, Bark = { M.Wood, rgb(80, 54, 46) },
	Blossom = { M.Grass, rgb(250, 182, 206) }, Neon = { M.Neon, rgb(255, 214, 150) },
}

local function box(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored = true
	p.Color, p.Material = color or rgb(150, 150, 150), material or M.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in props or {} do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local pieces = {}
local function loadKit()
	local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. DOJO_KIT)
	if not ok or not objects or not objects[1] then
		warn("[TutorialMap] could not load the Dojo kit: " .. tostring(objects))
		return
	end
	local AssetService = game:GetService("AssetService")
	local pivots, parts = {}, {}
	for _, d in objects[1]:GetDescendants() do
		if d:IsA("MeshPart") then
			local piece, rest = d.Name:match("^(.-)__(.+)$")
			if piece then
				if rest:match("^Pivot") then
					pivots[piece] = d.Position
				else
					local role, solid = rest:match("^(%a+)_(S?)%d+")
					local skin = SKIN[role] or SKIN.Stone
					d.Material, d.Color, d.TextureID = skin[1], skin[2], ""
					local isSolid = solid == "S"
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, isSolid, isSolid, false
					if isSolid then
						pcall(function()
							local precise = AssetService:CreateMeshPartAsync(d.MeshContent, { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition })
							d:ApplyMesh(precise)
							precise:Destroy()
						end)
					end
					d.Name = role
					parts[piece] = parts[piece] or {}
					table.insert(parts[piece], d)
				end
			end
		end
	end
	for piece, list in parts do
		local m = Instance.new("Model")
		m.Name = piece
		for _, p in list do
			p.Parent = m
		end
		m.WorldPivot = CFrame.new(pivots[piece] or Vector3.zero)
		pieces[piece] = m
	end
end

local function place(parent, name, cf, scale)
	local template = pieces[name]
	if not template then
		return nil
	end
	local m = template:Clone()
	if scale and scale ~= 1 then
		m:ScaleTo(scale)
	end
	m:PivotTo(cf)
	m.Parent = parent
	return m
end

local function lighting()
	for _, c in Lighting:GetChildren() do
		if c:IsA("Atmosphere") or c:IsA("PostEffect") or c:IsA("Sky") then
			c:Destroy()
		end
	end
	Lighting.ClockTime = 17.4
	Lighting.Brightness = 2.4
	Lighting.Ambient = rgb(120, 100, 110)
	Lighting.OutdoorAmbient = rgb(160, 132, 140)
	Lighting.GlobalShadows = true
	local atmo = Instance.new("Atmosphere")
	atmo.Density, atmo.Offset = 0.32, 0.2
	atmo.Color, atmo.Decay = rgb(255, 196, 200), rgb(150, 100, 140)
	atmo.Glare, atmo.Haze = 0.4, 1.6
	atmo.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.4, 28, 1.6
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.TintColor, grade.Saturation, grade.Contrast = rgb(255, 244, 240), 0.1, 0.05
	grade.Parent = Lighting
	Lighting:SetAttribute("Place", "Tutorial")
end

function api.Build()
	assert(not workspace:FindFirstChild("World") or workspace.World:GetAttribute("Place") == "Tutorial", "this does not look like the tutorial place")
	local old = workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	for _, c in workspace:GetChildren() do
		if c.Name == "Baseplate" or c:IsA("SpawnLocation") then
			c:Destroy()
		end
	end
	loadKit()
	lighting()
	workspace.FallenPartsDestroyHeight = -300
	local world = Instance.new("Folder")
	world.Name = "World"
	world:SetAttribute("Place", "Tutorial")
	world.Parent = workspace

	-- the island: a grass top with the arena in it, rock underneath
	box(world, "Grass", Vector3.new(4, 230, 230), CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(112, 150, 82), M.Grass, { Shape = Enum.PartType.Cylinder })
	for i = 1, 26 do
		local a = i / 26 * math.pi * 2
		local r = R:NextNumber(30, 100)
		local size = R:NextNumber(40, 80)
		box(world, "Rock", Vector3.new(size, size * R:NextNumber(0.8, 1.4), size), CFrame.new(math.cos(a) * r, -size * 0.95 - R:NextNumber(6, 30), math.sin(a) * r) * CFrame.Angles(R:NextNumber(0, 6), R:NextNumber(0, 6), R:NextNumber(0, 6)), rgb(120, 104, 100), M.Slate)
	end
	local arena = place(world, "DojoArena", CFrame.new(0, 0.05, 0))
	if not arena then
		box(world, "ArenaFloor", Vector3.new(1, 140, 140), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(168, 160, 148), M.Slate, { Shape = Enum.PartType.Cylinder })
	end
	box(world, "ArenaCenter", Vector3.new(1, 1, 1), CFrame.new(0, 0.1, 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })

	-- sakura round the rim, posts and lanterns between them
	for i = 0, 9 do
		local a = math.rad(i * 36 + 18)
		if math.abs(math.deg(a) - 90) > 20 then -- leave the south (gate) side open
			place(world, "SakuraTree", CFrame.new(math.cos(a) * 88, 0, math.sin(a) * 88) * CFrame.Angles(0, R:NextNumber(0, 6), 0), R:NextNumber(1.1, 1.5))
		end
		local b = math.rad(i * 36)
		local spot = Vector3.new(math.cos(b) * 78, 0, math.sin(b) * 78)
		if math.abs(math.deg(b) - 90) > 20 then
			if i % 2 == 0 then
				place(world, "DojoPost", CFrame.lookAt(spot, Vector3.zero))
			else
				place(world, "DojoLantern", CFrame.lookAt(spot, Vector3.zero))
			end
		end
	end
	-- the way in: a torii on the south side and lanterns along the path
	place(world, "DojoGate", CFrame.lookAt(Vector3.new(0, 0, 80), Vector3.new(0, 0, 200)))
	for _, z in { 92, 104 } do
		for _, s in { -1, 1 } do
			place(world, "DojoLantern", CFrame.lookAt(Vector3.new(s * 9, 0, z), Vector3.new(0, 0, z)), 0.9)
		end
	end
	box(world, "Path", Vector3.new(10, 0.4, 44), CFrame.new(0, 0.15, 96), rgb(206, 186, 150), M.Limestone)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.5, 108)
	spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = world
	-- petals
	local petals = box(world, "Petals", Vector3.new(200, 2, 200), CFrame.new(0, 40, 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(255, 190, 214), rgb(255, 236, 244))
	e.Size = NumberSequence.new(0.35)
	e.Lifetime = NumberRange.new(8, 12)
	e.Rate = 30
	e.Speed = NumberRange.new(2, 4)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.new(1.5, -1.2, 0.6)
	e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-60, 60)
	e.Shape, e.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	e.Parent = petals
	return #world:GetDescendants()
end

return api

--!nonstrict
--[[
 Builds Azusa's training grounds into Workspace.World (run in the Tutorial place's Studio window, edit mode):
   require(game.ServerStorage.MapBuilder).Build()
 Floating islands at dusk (Blender kit "Blossom", tutorial/blender/blossom.py):
   * the ShrineArena at the middle (World.ArenaCenter, radius 74): where Azusa fights you. A ring of invisible walls (World.Fence)
     keeps the fight on the floor; World.Fence.Gate closes the bridge gap while the fight is on (TutorialService).
   * the SpawnIsle to the south (World.Spawn), joined to the arena by the red ArchBridge, with the torii and lanterns (Dojo kit)
   * the GreatSakura on its own rock behind the arena, a Pagoda on a side rock, SkyRocks drifting around, petals everywhere
 Also stores Azusa's sword and attack shapes (kit "AzusaFX") in ReplicatedStorage.AzusaFX for TutorialService and the client.
]]
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local api = {}
local KITS = { Blossom = 80713024384595, Dojo = 82016519813626, AzusaFX = 121606459275439 }
local ARENA_R = 74
local R = Random.new(915)
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local M = Enum.Material
local SKIN = {
	Red = { M.SmoothPlastic, rgb(196, 42, 48) }, Black = { M.SmoothPlastic, rgb(28, 22, 26) }, Gold = { M.Foil, rgb(236, 186, 70) },
	Wood = { M.Wood, rgb(112, 76, 48) }, WoodDark = { M.Wood, rgb(64, 42, 28) }, Plank = { M.WoodPlanks, rgb(150, 92, 60) },
	Stone = { M.Slate, rgb(196, 188, 178) }, StoneWarm = { M.Limestone, rgb(222, 204, 170) }, Rock = { M.Slate, rgb(112, 96, 104) },
	Rope = { M.Fabric, rgb(214, 190, 140) }, Bark = { M.Wood, rgb(84, 56, 50) }, Grass = { M.Grass, rgb(116, 158, 84) },
	Blossom = { M.SmoothPlastic, rgb(250, 176, 204) }, Petal = { M.SmoothPlastic, rgb(255, 214, 230) }, Neon = { M.Neon, rgb(255, 214, 150) },
	Plaster = { M.Plaster, rgb(236, 226, 206) }, Tile = { M.Slate, rgb(46, 38, 48) }, Fabric = { M.Fabric, rgb(40, 30, 40) },
	Glow = { M.Neon, rgb(255, 255, 255) }, Ink = { M.SmoothPlastic, rgb(0, 0, 0) },
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

-- Loads a Blender kit: one Model per piece, parts named by role, coloured from SKIN; solid parts get precise collision.
local function loadKit(id, solidCollision)
	local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. id)
	if not ok or not objects or not objects[1] then
		warn("[TutorialMap] could not load kit " .. id .. ": " .. tostring(objects))
		return {}
	end
	local AssetService = game:GetService("AssetService")
	local pivots, parts, pieces = {}, {}, {}
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
					if isSolid and solidCollision ~= false then
						pcall(function()
							local precise = AssetService:CreateMeshPartAsync(d.MeshContent, { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition })
							d:ApplyMesh(precise)
							precise:Destroy()
						end)
					end
					if role == "Glow" or role == "Neon" then
						d.CastShadow = false
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
	return pieces
end

local kit = {}
local function place(parent, name, cf, scale)
	local template = kit[name]
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
	Lighting.ClockTime = 17.7
	Lighting.GeographicLatitude = 20
	Lighting.Brightness = 2.6
	Lighting.Ambient = rgb(126, 100, 118)
	Lighting.OutdoorAmbient = rgb(170, 134, 150)
	Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.5, 0.4
	Lighting.GlobalShadows = true
	local atmo = Instance.new("Atmosphere")
	atmo.Density, atmo.Offset = 0.36, 0.12
	atmo.Color, atmo.Decay = rgb(255, 190, 196), rgb(160, 96, 150)
	atmo.Glare, atmo.Haze = 0.6, 1.9
	atmo.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.SunAngularSize, sky.MoonAngularSize = 16, 9
	sky.StarCount = 1200
	sky.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.55, 30, 1.4
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity, rays.Spread = 0.12, 0.7
	rays.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.TintColor, grade.Saturation, grade.Contrast, grade.Brightness = rgb(255, 242, 244), 0.14, 0.08, 0.02
	grade.Parent = Lighting
	Lighting:SetAttribute("Place", "Tutorial")
end

local function petals(parent, cf, size, rate)
	local holder = box(parent, "Petals", size, cf, nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(255, 184, 212), rgb(255, 236, 244))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.25) })
	e.Lifetime = NumberRange.new(9, 14)
	e.Rate = rate or 30
	e.Speed = NumberRange.new(1.5, 4)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(2, -1.4, 0.8)
	e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-80, 80)
	e.LightEmission = 0.3
	e.Shape, e.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	e.Parent = holder
	return holder
end

local function lamp(parent, pos, color, range)
	local p = box(parent, "Glow", Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = color, range or 18, 1.4, false
	l.Parent = p
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
	kit = {}
	for name, id in KITS do
		for piece, model in loadKit(id, name ~= "AzusaFX") do
			kit[piece] = model
		end
	end
	lighting()
	workspace.FallenPartsDestroyHeight = -400
	local world = Instance.new("Folder")
	world.Name = "World"
	world:SetAttribute("Place", "Tutorial")
	world.Parent = workspace

	-- the arena island
	local arena = place(world, "ShrineArena", CFrame.new(0, 0, 0))
	if not arena then
		box(world, "ArenaFloor", Vector3.new(2, ARENA_R * 2, ARENA_R * 2), CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(196, 188, 178), M.Slate, { Shape = Enum.PartType.Cylinder })
	end
	box(world, "ArenaCenter", Vector3.new(1, 1, 1), CFrame.new(0, 0.1, 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	-- the fence: invisible walls round the rim; the gate (over the bridge gap) closes during the fight
	local fence = Instance.new("Folder")
	fence.Name = "Fence"
	fence.Parent = world
	local count = 40
	for i = 0, count - 1 do
		local a = (i + 0.5) / count * math.pi * 2
		local south = math.abs(math.atan2(math.sin(a - math.pi / 2), math.cos(a - math.pi / 2))) < 0.2
		local at = Vector3.new(math.cos(a) * (ARENA_R + 2.5), 12, math.sin(a) * (ARENA_R + 2.5))
		local wall = box(fence, south and "Gate" or "Wall", Vector3.new(2 * math.pi * (ARENA_R + 2.5) / count + 1, 26, 1), CFrame.lookAt(at, Vector3.new(0, 12, 0)), rgb(255, 170, 200), M.ForceField, { Transparency = 1, CanQuery = false, CanTouch = false })
		if south then
			wall.CanCollide = false
			wall:SetAttribute("Gate", true)
		end
	end

	-- the spawn island, the bridge, the torii and its lanterns
	place(world, "SpawnIsle", CFrame.new(0, 0, 166) * CFrame.Angles(0, math.pi, 0))
	place(world, "ArchBridge", CFrame.new(0, 0.2, 108))
	place(world, "DojoGate", CFrame.lookAt(Vector3.new(0, 0, 146), Vector3.new(0, 0, 100)), 1.15)
	for _, z in { 152, 164, 176 } do
		for _, s in { -1, 1 } do
			place(world, "DojoLantern", CFrame.lookAt(Vector3.new(s * 8, 0, z), Vector3.new(0, 0, z)), 0.9)
			lamp(world, Vector3.new(s * 8, 5.6, z), rgb(255, 196, 140), 16)
		end
	end
	for i = 0, 7 do -- lanterns standing just outside the arena's balustrade
		local a = i / 8 * math.pi * 2 + math.pi / 8
		if math.abs(math.atan2(math.sin(a - math.pi / 2), math.cos(a - math.pi / 2))) > 0.3 then
			local at = Vector3.new(math.cos(a) * (ARENA_R + 6), -3, math.sin(a) * (ARENA_R + 6))
			place(world, "DojoLantern", CFrame.lookAt(at, Vector3.new(0, -3, 0)), 1.3)
			lamp(world, at + Vector3.new(0, 8, 0), rgb(255, 190, 150), 22)
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.6, 176) * CFrame.Angles(0, 0, 0)
	spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
	spawn.Transparency, spawn.CanCollide = 1, false
	spawn.Parent = world

	-- the great tree behind the arena, the pagoda, the drifting rocks
	place(world, "SkyRock3", CFrame.new(0, -14, -150), 2.2)
	place(world, "GreatSakura", CFrame.new(0, -13, -150) * CFrame.Angles(0, math.rad(20), 0), 1.6)
	place(world, "Pagoda", CFrame.new(150, -6, -40) * CFrame.Angles(0, math.rad(-110), 0), 1.2)
	place(world, "SkyRock1", CFrame.new(-150, 18, -60) * CFrame.Angles(0, 1.2, 0), 1.4)
	place(world, "SkyRock2", CFrame.new(-120, -30, 120) * CFrame.Angles(0, 0.4, 0), 1.6)
	place(world, "SkyRock1", CFrame.new(130, 30, 130) * CFrame.Angles(0, 2.4, 0), 0.9)
	place(world, "SkyRock2", CFrame.new(-210, 50, 40) * CFrame.Angles(0, 3.1, 0), 1.1)
	place(world, "SkyRock3", CFrame.new(220, 40, -150) * CFrame.Angles(0, 0.8, 0), 0.8)
	place(world, "SkyRock1", CFrame.new(60, -60, -230) * CFrame.Angles(0, 1.9, 0), 1.8)
	for _ = 1, 10 do -- smaller sakura round the edges
		local a = R:NextNumber(0, math.pi * 2)
		local r = R:NextNumber(150, 260)
		local y = R:NextNumber(-40, 60)
		local rock = place(world, "SkyRock" .. R:NextInteger(1, 3), CFrame.new(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(0, R:NextNumber(0, 6), 0), R:NextNumber(0.5, 0.9))
		if rock and R:NextNumber() < 0.6 then
			place(world, "SakuraTree", CFrame.new(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(0, R:NextNumber(0, 6), 0), R:NextNumber(0.9, 1.4))
		end
	end
	petals(world, CFrame.new(0, 50, -20), Vector3.new(320, 4, 320), 60)
	petals(world, CFrame.new(0, 60, -150), Vector3.new(80, 4, 80), 25)

	-- Azusa's sword and attack shapes, for the server and the client
	local fx = ReplicatedStorage:FindFirstChild("AzusaFX")
	if fx then
		fx:Destroy()
	end
	fx = Instance.new("Folder")
	fx.Name = "AzusaFX"
	for _, name in { "Katana", "Crescent", "PetalBlade", "Sigil", "ThornRing", "BloomPillar", "SlashCore", "SlashAura", "BloomFlower", "Shockwave", "SigilOuter", "PetalKunai", "SpiritBlade", "CutMark" } do
		local m = kit[name]
		if m then
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
				end
			end
			m.Parent = fx
		end
	end
	fx.Parent = ReplicatedStorage
	return #world:GetDescendants()
end

return api

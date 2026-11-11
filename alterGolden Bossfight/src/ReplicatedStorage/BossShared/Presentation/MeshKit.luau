--!nonstrict
--[[
 MeshKit - Blender meshes for the boss place (sources: lobby/blender/boss_gear.py, weapons.py, boss_arena.py, nothing.py).
 Each upload is a "kit" of pieces. MeshKit.Fetch() (Studio command bar, edit mode) downloads the kits and prepares every piece in
 ReplicatedStorage.BlenderMeshes, a place-only folder (Rojo leaves unknown instances alone), skinned with a Roblox material and colour by
 the role in each MeshPart's name (<Piece>__<Role>_<n>; S before n = players stand on it, precise collision). Code asks for a copy
 with MeshKit.Get(name) and falls back to its old parts when the folder is missing, so nothing breaks before Fetch has run.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshKit = {}

MeshKit.Kits = {
	BossGear = 125652687679678, -- BossSword, BossCrown, BossHorns, BossPauldronL/R, BossCape, BossBelt, DeathScythe, RainSword
	BossArena = 71341379891494, -- ArenaPine, ArenaOak, ArenaSpire, ArenaRuinArch, ArenaColumn, TerraceRock, NothingStage
	-- WpnWarriorSword, WpnWarriorShield, WpnTankSword, WpnTankShield, WpnDuelist, WpnMage, WpnSupporter, WpnTrueWarrior, WpnTwinblade,
	-- and the Reality Disorderer's hand pieces DisPalm, DisPhalanx (unit), DisClaw (unit) (lobby/blender/weapons.py, disorder_hands.py)
	Weapons = 85078394033272,
	-- WallBayA/B (24 long wall bays), WallTower, BossGateFrame, BossGateLeaf (lobby/blender/boss_wall.py; placed by tools/boss-wall-build.luau)
	BossWall = 79435446129189,
	BossHand = 116565052753361, -- the Golden Hand: HandPalm (palm + cuff), HandProx / HandMid / HandDist (finger bones, unit length + diameter) (lobby/blender/boss_hand.py)
	-- alterGolden's clothes, each centred on the R15 part it is welded to: BossTunic, BossSkirt, BossSleeveUp/Low, BossTrouserUp/Low, BossBoot (lobby/blender/boss_cloth.py)
	BossCloth = 93516084790071,
	-- AlterStatue (the gate-court statue of the boss), CourtBoulderA/B, CourtRockCluster, CourtColumnStump, CourtSlab, CourtRubble (lobby/blender/boss_court.py)
	BossCourt = 132989446401030,
	-- ArenaTiles (the paved court: FloorA/B/C/GoldDeep tiles on FloorGrout) and ArenaMedallion (the black-marble gold sundial, lanes, chevrons) (lobby/blender/boss_floor.py)
	BossFloor = 72309938637898,
	-- TrainingDummy (the lobby showroom's target) and OrbShrine (where the Reality Orb rests outside the Golden Encounter) (lobby/blender/realm.py)
	Props = 121151175581159,
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local M = Enum.Material
MeshKit.Skin = {
	Gold = { M.Foil, rgb(232, 182, 62) }, GoldDeep = { M.Metal, rgb(150, 104, 28) }, GoldPale = { M.Foil, rgb(255, 226, 150) },
	Ink = { M.SmoothPlastic, rgb(16, 12, 14) }, Velvet = { M.Fabric, rgb(120, 20, 30) }, Gem = { M.Neon, rgb(230, 40, 60) },
	GemBlue = { M.Neon, rgb(70, 130, 240) }, Neon = { M.Neon, rgb(255, 240, 190) }, GemRed = { M.Neon, rgb(230, 40, 60) },
	ScytheBlade = { M.Metal, rgb(212, 150, 18) }, ScytheDark = { M.Metal, rgb(74, 46, 4) }, ScytheHot = { M.Neon, rgb(255, 196, 38) },
	ScytheEdge = { M.Neon, rgb(255, 244, 188) },
	Steel = { M.Metal, rgb(214, 218, 228) }, SteelDark = { M.Metal, rgb(52, 58, 70) }, Crimson = { M.Metal, rgb(170, 30, 34) },
	Leather = { M.Leather, rgb(60, 36, 24) }, Arcane = { M.Neon, rgb(150, 80, 255) }, Verdant = { M.Neon, rgb(80, 240, 130) },
	Ivory = { M.Marble, rgb(236, 228, 210) }, Ice = { M.Neon, rgb(150, 210, 255) }, EdgeGlow = { M.Neon, rgb(255, 170, 90) },
	Wood = { M.Wood, rgb(98, 66, 40) }, Blue = { M.Metal, rgb(40, 80, 170) }, Red = { M.SmoothPlastic, rgb(196, 64, 60) },
	Stone = { M.Slate, rgb(150, 142, 128) }, StoneWarm = { M.Limestone, rgb(196, 176, 138) }, Marble = { M.Marble, rgb(236, 230, 216) },
	MarbleDark = { M.Marble, rgb(30, 26, 28) }, Rock = { M.Slate, rgb(112, 104, 92) }, Grass = { M.Grass, rgb(96, 128, 64) },
	Leaf = { M.Grass, rgb(186, 150, 60) }, Bark = { M.Wood, rgb(74, 56, 44) }, Iron = { M.CorrodedMetal, rgb(60, 60, 66) },
	Fabric = { M.Fabric, rgb(236, 226, 200) }, Banner = { M.Fabric, rgb(150, 24, 30) }, Glass = { M.Glass, rgb(190, 225, 240), 0.5 },
	Void = { M.SmoothPlastic, rgb(8, 6, 14) }, Star = { M.Neon, rgb(255, 250, 230) }, Nebula = { M.Neon, rgb(170, 110, 255), 0.4 },
	Glow = { M.Neon, rgb(255, 255, 255), 0.3 },
	PineLeaf = { M.Grass, rgb(58, 92, 50) },
	WoodDark = { M.Wood, rgb(58, 36, 26) }, MageCloth = { M.Fabric, rgb(56, 32, 96) }, SupCloth = { M.Fabric, rgb(48, 120, 78) },
	DisDark = { M.Metal, rgb(19, 17, 28) }, DisAsh = { M.Metal, rgb(58, 50, 82) }, DisGlow = { M.Neon, rgb(255, 235, 255) },
	DisMag = { M.Neon, rgb(255, 80, 225) }, DisCyan = { M.Neon, rgb(70, 235, 255) },
	Sandstone = { M.Sandstone, rgb(214, 186, 138) }, SandDark = { M.Sandstone, rgb(150, 118, 78) },
	Cloth = { M.Fabric, rgb(22, 20, 27) }, ClothSheen = { M.Fabric, rgb(44, 40, 54) },
	FloorA = { M.Limestone, rgb(184, 170, 142) }, FloorB = { M.Limestone, rgb(166, 152, 124) }, FloorC = { M.Limestone, rgb(142, 128, 104) },
	FloorGrout = { M.Slate, rgb(66, 60, 50) },
	Thatch = { M.Grass, rgb(196, 160, 98) }, Rope = { M.Fabric, rgb(190, 160, 110) }, White = { M.SmoothPlastic, rgb(238, 232, 220) },
	Black = { M.SmoothPlastic, rgb(20, 18, 20) }, Moss = { M.Grass, rgb(70, 96, 52) }, Plank = { M.WoodPlanks, rgb(142, 102, 62) },
}

local function folder()
	local f = ReplicatedStorage:FindFirstChild("BlenderMeshes")
	if not f then
		f = Instance.new("Folder")
		f.Name = "BlenderMeshes"
		f.Parent = ReplicatedStorage
	end
	return f
end

local function split(root)
	local AssetService = game:GetService("AssetService")
	local pieces, pivots = {}, {}
	for _, d in root:GetDescendants() do
		if d:IsA("MeshPart") then
			local piece, rest = d.Name:match("^(.-)__(.+)$")
			if piece then
				if rest:match("^Pivot") then
					pivots[piece] = d.Position
				else
					local role, solidFlag = rest:match("^(%a+)_(S?)%d+")
					local skin = MeshKit.Skin[role] or MeshKit.Skin.Stone
					d.Material, d.Color, d.Transparency = skin[1], skin[2], skin[3] or 0
					d.TextureID = ""
					local sa = d:FindFirstChildWhichIsA("SurfaceAppearance")
					if sa then
						sa:Destroy()
					end
					local solid = solidFlag == "S"
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, solid, solid, false
					d.CastShadow = skin[1] ~= M.Neon
					if solid then
						pcall(function()
							local precise = AssetService:CreateMeshPartAsync(d.MeshContent, { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition })
							d:ApplyMesh(precise)
							precise:Destroy()
						end)
					end
					d.Name = role
					pieces[piece] = pieces[piece] or {}
					table.insert(pieces[piece], d)
				end
			end
		end
	end
	local models = {}
	for piece, parts in pieces do
		local model = Instance.new("Model")
		model.Name = piece
		for _, p in parts do
			p.Parent = model
		end
		model.WorldPivot = CFrame.new(pivots[piece] or Vector3.zero)
		model:PivotTo(CFrame.new())
		models[piece] = model
	end
	return models
end

-- Studio, edit mode only: (re)build ReplicatedStorage.BlenderMeshes from the kits (or just `only`).
function MeshKit.Fetch(only)
	local f = folder()
	local done = {}
	for name, id in MeshKit.Kits do
		if (only == nil or only == name) and id ~= 0 then
			local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. id)
			if ok and objects and objects[1] then
				for pieceName, model in split(objects[1]) do
					model:SetAttribute("Kit", name)
					local old = f:FindFirstChild(pieceName)
					if old then
						old:Destroy()
					end
					model.Parent = f
					table.insert(done, pieceName)
				end
				for _, o in objects do
					o:Destroy()
				end
			else
				warn("[MeshKit] could not load " .. name .. ": " .. tostring(objects))
			end
		end
	end
	table.sort(done)
	return done
end

-- True when the place has this prepared piece (cheap: no clone), for code that picks a mesh or primitive build up front.
function MeshKit.Has(name)
	local f = ReplicatedStorage:FindFirstChild("BlenderMeshes")
	return f ~= nil and f:FindFirstChild(name) ~= nil
end

-- A fresh copy of a prepared piece (pivot = its Blender origin), or nil when the place has not been given the meshes yet.
function MeshKit.Get(name)
	local f = ReplicatedStorage:FindFirstChild("BlenderMeshes")
	local item = f and f:FindFirstChild(name)
	return item and item:Clone() or nil
end

-- Clone `name`, put its origin at part.CFrame * offset and weld every piece to `part` (unanchored, massless, no collision).
-- `scale` sizes it first. Returns the model (parented to `parent` or `part`), or nil if the mesh is missing.
function MeshKit.Attach(name, part, offset, parent, scale)
	local model = MeshKit.Get(name)
	if not model or not part then
		return nil
	end
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(part.CFrame * (offset or CFrame.identity))
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = part, p
			w.Parent = p
		end
	end
	model.Parent = parent or part
	return model
end

return MeshKit

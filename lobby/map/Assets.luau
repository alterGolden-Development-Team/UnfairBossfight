--!nonstrict
-- Creator Store models the map uses. The builders never load anything from the web while building: they clone prepared copies from
-- ServerStorage.MapAssets, which is saved in the place file. Assets.Fetch() (re)creates that folder from the ids below and is the only
-- thing that touches the store. Run it from the test place's command bar:
--   require(game.ServerStorage.MapBuilder.Assets).Fetch()
-- Every fetched model has ALL scripts removed before it is kept: free models are props here, never code.
-- Credit: the creators are listed next to each id.
local ServerStorage = game:GetService("ServerStorage")
local AssetService = game:GetService("AssetService")

local Assets = {}

local FOLDER = "MapAssets"

-- id: Creator Store asset; pick: which piece of it to keep (nil = the whole model, "mesh:<MeshId>" = the first MeshPart with that mesh)
Assets.List = {
	Fountain = { id = 11423259371, credit = "MR_MohamedTarek", note = "two-tier marble fountain with water curtains" },
	GothicSword = { id = 79913196266344, credit = "Wirly_world", pick = "mesh:rbxassetid://73389996004524", note = "ornate greatsword; tint with SurfaceAppearance.Color" },
	-- Starblaze Games' free low-poly floating island: the pieces, and the whole island for the small ones around the hub
	SkyIsland = { id = 16519830532, credit = "Starblaze Games", note = "whole island (spawn removed)" },
	IslandBase = { id = 16519830532, credit = "Starblaze Games", pick = "mesh:rbxassetid://7383572521", note = "earth underside" },
	IslandTop = { id = 16519830532, credit = "Starblaze Games", pick = "mesh:rbxassetid://7383572612", note = "grass cap" },
	Tree = { id = 16519830532, credit = "Starblaze Games", pick = "model:Tree", note = "trunk + canopy" },
	Palm = { id = 10354687850, credit = "LoucDu44", note = "low-poly palm, 9 parts" },
	Rock = { id = 16519830532, credit = "Starblaze Games", pick = "mesh:rbxassetid://7383706173", note = "small rock" },
}

-- Our own meshes, modelled in Blender (sources and the export kit in lobby/blender/). One upload = one kit holding several pieces.
-- Each MeshPart is named <Piece>__<Role>_<S?><n>: the piece it belongs to, the role that picks its Roblox material and colour
-- (SKIN below) and S when players stand on or bump into it. <Piece>__Pivot marks the piece's origin and is removed.
Assets.Kits = {
	Portals = { id = 89294553232212, note = "PortalMidas, PortalFallen, PortalBrothers (lobby/blender/portal_*.py)" },
	Palace = { id = 99339102765698, note = "PalaceHall, PalaceGate, PalaceChandelier, PalaceUrn (lobby/blender/palace.py)" },
	Shop = { id = 110075362046997, note = "ShopHouse, ShopSignBoard, ShopShelf, ShopCounter, ShopKeeper and stock (lobby/blender/shop.py)" },
	Stage = { id = 106232215304499, note = "StageArena, StageDais, StageBagFrame, StageSandbag, StageRack, StageTarget, StagePost, StageBrazier, StageBoard (lobby/blender/stage.py)" },
	Hub = { id = 85413779856575, note = "HubPlaza, HubColumn(Broken), HubBench, HubLamp, HubGazebo, HubBridge, HubTree1/2, HubSwingTree, HubSwingSeat, HubPlanter (lobby/blender/hub.py)" },
	Gates = { id = 77622688158712, note = "GateGolden (+GoldenLeafL/R), GateFallen, GateBrothers, GateReturn, GateParty (lobby/blender/gates.py)" },
	Lobby3 = { id = 91244804503172, note = "GateReturnPalace/Island/Forest, IslandShellPortal, HubFountain, ForestMountain1/2, KeeperHat, KeeperBeard, BroHeadband (lobby/blender/lobby2.py)" },
	Figures = { id = 118150339553651, note = "Kneeler, BroPelvis/Torso/UpperArm/Forearm/Thigh/Shin/Sword (lobby/blender/figures.py)" },
	Forest = { id = 124425670320721, note = "ForestTree1..3, ForestGate, ForestLantern, ForestPillar (lobby/blender/forest.py)" },
	Island = { id = 81123087296809, note = "IslandLighthouse, IslandBoat, IslandPier, IslandHut, IslandArch, IslandCliff1/2 (lobby/blender/island.py)" },
	PortalWalls = { id = 128516303973129, note = "WallGolden, WallWreck, WallDivided: the wall behind each boss's portal and way back (lobby/blender/portal_walls.py)" },
	Realm = { id = 114250682217771, note = "ForestCabin, ForestCabinRuin, ForestWell, ForestRock1..3, ForestStump, ForestLogPile, ForestShrine, GlitchPortal, DoorWall (lobby/blender/realm.py)" },
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local MAT = Enum.Material
Assets.Skin = {
	Gold = { MAT.Foil, rgb(232, 182, 62) },
	GoldDeep = { MAT.Metal, rgb(150, 104, 28) },
	GoldPale = { MAT.Foil, rgb(255, 226, 150) },
	Ink = { MAT.SmoothPlastic, rgb(10, 9, 12) },
	Marble = { MAT.Marble, rgb(232, 226, 214) },
	MarbleDark = { MAT.Marble, rgb(24, 20, 22) },
	Slate = { MAT.Slate, rgb(30, 30, 34) },
	Stone = { MAT.Slate, rgb(150, 142, 128) },
	StoneWarm = { MAT.Limestone, rgb(182, 164, 134) },
	Rock = { MAT.Slate, rgb(108, 98, 90) },
	Sand = { MAT.Sand, rgb(232, 208, 156) },
	Wood = { MAT.Wood, rgb(98, 66, 40) },
	WoodDark = { MAT.Wood, rgb(62, 42, 28) },
	Plank = { MAT.WoodPlanks, rgb(142, 102, 62) },
	Fabric = { MAT.Fabric, rgb(240, 232, 214) },
	Rope = { MAT.Fabric, rgb(190, 160, 110) },
	White = { MAT.Marble, rgb(240, 240, 240) },
	Black = { MAT.Slate, rgb(14, 14, 16) },
	Blue = { MAT.SmoothPlastic, rgb(34, 92, 178) },
	Red = { MAT.SmoothPlastic, rgb(196, 64, 60) },
	Iron = { MAT.CorrodedMetal, rgb(60, 60, 66) },
	Glass = { MAT.Glass, rgb(190, 225, 240), 0.5 },
	Leaf = { MAT.Grass, rgb(70, 130, 62) },
	Grass = { MAT.Grass, rgb(104, 142, 72) },
	Bark = { MAT.Wood, rgb(74, 56, 44) },
	Neon = { MAT.Neon, rgb(255, 200, 120) },
	Thatch = { MAT.Grass, rgb(196, 160, 98) },
	Glow = { MAT.Neon, rgb(255, 255, 255), 0.3 },
	Blossom = { MAT.Grass, rgb(244, 176, 198) },
	Moss = { MAT.Grass, rgb(70, 96, 52) },
	Shell = { MAT.Marble, rgb(246, 214, 200) },
	Water = { MAT.Glass, rgb(150, 210, 240), 0.45 },
	Coral = { MAT.SmoothPlastic, rgb(232, 110, 96) },
	Body = { MAT.SmoothPlastic, rgb(236, 236, 236) },
	Sash = { MAT.Fabric, rgb(170, 34, 40) },
	Blade = { MAT.Metal, rgb(222, 226, 232) },
	Tile = { MAT.Slate, rgb(132, 62, 46) },
	Plaster = { MAT.Plaster, rgb(232, 220, 190) },
	Brick = { MAT.Brick, rgb(150, 86, 66) },
	GemRed = { MAT.Neon, rgb(220, 50, 60) },
	GemBlue = { MAT.Neon, rgb(60, 120, 230) },
}

-- Split a downloaded kit into its pieces: skinned, anchored, pivoted at the Blender origin.
local function splitKit(root)
	local pieces = {}
	local pivots = {}
	for _, d in root:GetDescendants() do
		if d:IsA("MeshPart") then
			local piece, rest = d.Name:match("^(.-)__(.+)$")
			if piece then
				if rest == "Pivot" or rest:match("^Pivot%.") then
					pivots[piece] = d.Position
				else
					local role, solidFlag = rest:match("^(%a+)_(S?)%d+")
					local skin = Assets.Skin[role]
					if not skin then
						warn("[Assets] no skin for role " .. tostring(role) .. " (" .. d.Name .. ")")
						skin = Assets.Skin.Stone
					end
					d.Material, d.Color = skin[1], skin[2]
					d.Transparency = skin[3] or 0
					d.TextureID = ""
					local sa = d:FindFirstChildWhichIsA("SurfaceAppearance")
					if sa then
						sa:Destroy()
					end
					d.Anchored = true
					local isSolid = solidFlag == "S"
					d.CanCollide = isSolid
					d.CanTouch = false
					d.CanQuery = isSolid
					if isSolid then
						-- Assigning CollisionFidelity on an existing MeshPart is silently ignored, and the default fidelity is a rough hull you
						-- can stand on in mid-air. Rebuild the part's geometry with precise collision instead.
						local ok, err = pcall(function()
							local precise = AssetService:CreateMeshPartAsync(d.MeshContent, {
								CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition,
								RenderFidelity = Enum.RenderFidelity.Automatic,
							})
							d:ApplyMesh(precise)
							precise:Destroy()
						end)
						if not ok then
							warn("[Assets] precise collision failed for " .. d.Name .. ": " .. tostring(err))
						end
					end
					d.CastShadow = skin[1] ~= MAT.Neon
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
		local origin = pivots[piece]
		if origin then
			model.WorldPivot = CFrame.new(origin)
		else
			local cf, size = model:GetBoundingBox()
			model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
		end
		-- park it at the origin so the copies in MapAssets are tidy
		model:PivotTo(CFrame.new())
		models[piece] = model
	end
	return models
end

local function folder()
	local f = ServerStorage:FindFirstChild(FOLDER)
	if not f then
		f = Instance.new("Folder")
		f.Name = FOLDER
		f.Parent = ServerStorage
	end
	return f
end

local function clean(root)
	for _, d in root:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("SpawnLocation") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("Tool") then
			d:Destroy()
		end
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

-- Pivot each kept model at the bottom-centre of its bounding box, so builders can place it standing on a point.
local function asModel(item, name)
	local model = item
	if not item:IsA("Model") then
		model = Instance.new("Model")
		item.Parent = model
	end
	model.Name = name
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	return model
end

local function pick(root, how)
	if not how then
		return root
	end
	local kind, key = how:match("^(%a+):(.+)$")
	for _, d in root:GetDescendants() do
		if kind == "mesh" and d:IsA("MeshPart") and d.MeshId == key then
			return d
		elseif kind == "model" and d:IsA("Model") and d.Name == key then
			return d
		end
	end
	return nil
end

function Assets.Fetch(only)
	-- the test lobby, or the live lobby since the user asked for live edits (2026-11-11). Fetch("<Kit>") touches only that kit.
	assert(game.PlaceId == 83310105029258 or game.PlaceId == 123789153131367 or game.PlaceId == 0, "fetch assets in a lobby place")
	local f = folder()
	local done = {}
	local loaded = {}
	for name, entry in Assets.List do
		if only == nil or only == name then
			local ok, objects = pcall(function()
				loaded[entry.id] = loaded[entry.id] or game:GetObjects("rbxassetid://" .. entry.id)
				return loaded[entry.id]
			end)
			if not ok or not objects or not objects[1] then
				warn("[Assets] could not load " .. name .. " (" .. entry.id .. "): " .. tostring(objects))
			else
				local root = objects[1]:Clone()
				clean(root)
				local piece = pick(root, entry.pick)
				if piece then
					piece = piece:Clone()
					clean(piece)
					local model = asModel(piece, name)
					model:SetAttribute("AssetId", entry.id)
					model:SetAttribute("Credit", entry.credit)
					local old = f:FindFirstChild(name)
					if old then
						old:Destroy()
					end
					model.Parent = f
					table.insert(done, name)
				else
					warn("[Assets] " .. name .. ": nothing matched " .. tostring(entry.pick))
				end
				root:Destroy()
				task.wait()
			end
		end
	end
	for _, objects in loaded do
		for _, o in objects do
			o:Destroy()
		end
	end
	for kitName, kit in Assets.Kits do
		if (only == nil or only == kitName) and kit.id ~= 0 then
			local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. kit.id)
			if not ok or not objects or not objects[1] then
				warn("[Assets] could not load kit " .. kitName .. " (" .. kit.id .. "): " .. tostring(objects))
			else
				for pieceName, model in splitKit(objects[1]) do
					clean(model)
					model:SetAttribute("Kit", kitName)
					model:SetAttribute("AssetId", kit.id)
					model:SetAttribute("Credit", "Unfair Bossfight (Blender)")
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
				task.wait()
			end
		end
	end
	table.sort(done)
	return done
end

-- A fresh copy of a prepared asset, pivoted at its bottom-centre. Errors with the fix if the folder has not been fetched.
function Assets.Get(name)
	local f = ServerStorage:FindFirstChild(FOLDER)
	local item = f and f:FindFirstChild(name)
	assert(item, "[Assets] " .. name .. " is missing: run require(game.ServerStorage.MapBuilder.Assets).Fetch() in the test place")
	return item:Clone()
end

-- Clone, scale and place: `cf` is where the bottom-centre goes; `size` is the wanted height (or the longest side if `byLongest`).
function Assets.Place(parent, name, cf, size, byLongest)
	local model = Assets.Get(name)
	if size then
		local _, box = model:GetBoundingBox()
		local current = byLongest and math.max(box.X, box.Y, box.Z) or box.Y
		if current > 0 then
			model:ScaleTo(model:GetScale() * size / current)
		end
	end
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

return Assets

--!nonstrict
-- Creator Store models the map uses. The builders never load anything from the web while building: they clone prepared copies from
-- ServerStorage.MapAssets, which is saved in the place file. Assets.Fetch() (re)creates that folder from the ids below and is the only
-- thing that touches the store. Run it from the test place's command bar:
--   require(game.ServerStorage.MapBuilder.Assets).Fetch()
-- Every fetched model has ALL scripts removed before it is kept: free models are props here, never code.
-- Credit: the creators are listed next to each id.
local ServerStorage = game:GetService("ServerStorage")

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
	assert(game.PlaceId == 83310105029258 or game.PlaceId == 0, "fetch assets in the test lobby place")
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

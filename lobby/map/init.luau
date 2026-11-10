--!nonstrict
-- Builds the lobby world into Workspace.World. Run from Studio (test place only):
--   require(game.ServerStorage.MapBuilder).Build("Hub")   -- or "All", "Clear", or one area name
-- The map is saved in the place file; Rojo does not sync Workspace. Keeping the builders in the repo means it can be reviewed and rebuilt.
local Hub = require(script.Hub)
local Portals = require(script.Portals)

local api = {}

local AREAS = {}

local function world()
	local w = workspace:FindFirstChild("World")
	if not w then
		w = Instance.new("Folder")
		w.Name = "World"
		w.Parent = workspace
	end
	return w
end

local function remove(name)
	local w = world()
	local old = w:FindFirstChild(name)
	if old then
		old:Destroy()
		task.wait()
	end
end

AREAS.Hub = function()
	remove("Hub")
	remove("Portals")
	Hub.Build(world())
	Portals.Build(world(), Hub.Portals, Hub.Y)
end

for _, name in { "Shop", "Palace", "Island", "Forest", "Stage" } do
	AREAS[name] = function()
		local ok, module = pcall(function()
			return script:FindFirstChild(name) and require(script[name])
		end)
		if ok and module then
			remove(name)
			module.Build(world())
		end
	end
end

-- Removes the first lobby's map (the old plaza, class hall, shop shell and pads).
function api.ClearOld()
	for _, name in { "Plaza", "Decor", "Pads", "ClassHall", "PartyRooms", "Shop", "Baseplate", "SpawnLocation" } do
		local item = workspace:FindFirstChild(name)
		if item then
			item:Destroy()
		end
	end
end

function api.Build(name)
	if name == "All" then
		for _, area in { "Hub", "Shop", "Palace", "Island", "Forest", "Stage" } do
			AREAS[area]()
		end
	elseif name == "Clear" then
		api.ClearOld()
		world():ClearAllChildren()
	else
		AREAS[name]()
	end
	return #world():GetDescendants()
end

return api

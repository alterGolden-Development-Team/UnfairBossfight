-- Paste into a side place's Studio window after tools/sync-place.ps1 -Place <name>; set PLACE first ("glitched" or "tutorial").
-- Replaces that place's code folders (and UnfairShared, and ServerStorage.MapBuilder) with the repo's version. Publishing is the user's step.
local PLACE = "glitched"
local IDS = { glitched = 120825718922899, tutorial = 105069596660916 }
assert(game.PlaceId == IDS[PLACE] or game.PlaceId == 0, "this window is not the " .. PLACE .. " place")
local built = game:GetObjects("rbxasset://unfair_" .. PLACE .. "sync.rbxm")[1]
local targets = {
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	ServerScriptService = game:GetService("ServerScriptService"),
	StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"),
	ServerStorage = game:GetService("ServerStorage"),
}
local done = {}
for name, service in targets do
	local group = built:FindFirstChild(name)
	for _, item in group and group:GetChildren() or {} do
		local old = service:FindFirstChild(item.Name)
		if old then
			old:Destroy()
		end
		item.Parent = service
		table.insert(done, name .. "." .. item.Name)
	end
end
built:Destroy()
return table.concat(done, ", ")

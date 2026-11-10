-- Paste into the TEST lobby Studio window after tools/sync-test-lobby.ps1. Replaces the code folders with the repo's version.
assert(game.PlaceId == 83310105029258, "not the test lobby place")
local root = game:GetObjects("rbxasset://unfair_lobbysync.rbxm")[1]
local RS, SSS, SPS, SS = game.ReplicatedStorage, game.ServerScriptService, game.StarterPlayer.StarterPlayerScripts, game.ServerStorage
local function swap(parent, item)
	local old = parent:FindFirstChild(item.Name)
	if old then
		-- things that only live in the place file (the VFX cue event and mesh assets) move across to the new copy
		for _, child in old:GetChildren() do
			if not child:IsA("LuaSourceContainer") and not item:FindFirstChild(child.Name) and (child.Name == "Event" or child.Name == "Assets") then
				child.Parent = item
			end
		end
		old:Destroy()
	end
	item.Parent = parent
end
swap(RS, root.ReplicatedStorage.Lobby)
swap(RS, root.ReplicatedStorage.UnfairShared)
swap(RS, root.ReplicatedStorage.BossShared)
swap(RS, root.ReplicatedStorage.VFXEngine)
swap(SSS, root.ServerScriptService.Lobby)
swap(SSS, root.ServerScriptService.BossSystem)
swap(SPS, root.StarterPlayerScripts.LobbyClient)
swap(SPS, root.StarterPlayerScripts.BossClient)
swap(SPS, root.StarterPlayerScripts.VFXEngineClient)
swap(SS, root.MapBuilder)
root:Destroy()
return "synced"

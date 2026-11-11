-- Paste into the LIVE lobby Studio window after tools/sync-live-lobby.ps1 (the user asked for live edits on 2026-11-11; publishing is still theirs). Replaces the code folders with the repo's version.
assert(game.PlaceId == 123789153131367, "not the live lobby place")
local root = game:GetObjects("rbxasset://unfair_livelobbysync.rbxm")[1]
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
swap(game:GetService("ReplicatedFirst"), root.ReplicatedFirst.TravelArrival)
root:Destroy()
return "synced"

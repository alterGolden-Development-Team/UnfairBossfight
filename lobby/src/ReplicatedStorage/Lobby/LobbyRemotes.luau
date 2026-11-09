--!strict
-- One place for the lobby's RemoteEvents. The server creates them on first use, the client waits for them, so
-- neither side needs a hand-made instance in the place file.
--   ClassPick     client -> server: "Select", classId | "Buy", classId      server -> client: "Result", { Message, Selected? }
--   PartyControl  client -> server: "Join", roomIndex | "Leave" | "SetConfig", difficulty, enraged? | "Start" | "Cancel"
--                 server -> client: "Result", { Message } | "DryRun", payloadJson

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "LobbyRemotes"

local LobbyRemotes = {}

function LobbyRemotes.get(name: string): RemoteEvent
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if folder == nil then
			local created = Instance.new("Folder")
			created.Name = FOLDER_NAME
			created.Parent = ReplicatedStorage
			folder = created
		end
		local existing = (folder :: Instance):FindFirstChild(name)
		if existing ~= nil then
			return existing :: RemoteEvent
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	return folder:WaitForChild(name) :: RemoteEvent
end

return LobbyRemotes

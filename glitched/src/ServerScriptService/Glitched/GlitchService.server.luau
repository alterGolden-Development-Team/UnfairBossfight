--!nonstrict
--[[
 GlitchService - the glitched place ("!A GL!TC3D PL@CE!", reached through the black-and-white portal in the lobby's Divided Wood).
 You walk a long broken road through the void to a glitched man sitting at the end of it. Talk to him (walk into him, or hold E).
   * Without the Reality Orb he asks for it, in broken words.
   * With it (found outside the Golden Encounter's walls, saved in your record) you can hand it over: the orb is taken from your record
     and the Reality Disorderer is unlocked in the same save (UnfairShared/RecordStore.TradeItemForClass). He takes it, rises into the
     sky, tears a hole in the world and the hole pulls you in. "Thank you..." - and you are back in the lobby, class unlocked.
 Glitch remote  client -> server: "Talk" | "Give"
                server -> client: "State", { HasOrb, Freed } | "Cutscene", { Man } | "Message", text
 The way back at the start sends you to the lobby without anything happening.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local Config = require(Shared.UnfairConfig)
local CashLedger = require(Shared.CashLedger)
local RecordStore = require(Shared.RecordStore)

local CLASS = "Disorderer"
local ITEM = "RealityOrb"
local CUTSCENE_SECONDS = 16

local remote = Instance.new("RemoteEvent")
remote.Name = "Glitch"
remote.Parent = ReplicatedStorage

local world = workspace:WaitForChild("World", 30)
local man = world and world:WaitForChild("GlitchedMan", 30)

local records = {} -- [Player] = last record read
local busy = {}

local function read(player)
	local ok, record = RecordStore.Read(player.UserId)
	if ok then
		records[player] = record
		RecordStore.PublishInventory(player, record)
	end
	return ok, record
end

local function nearMan(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return man and root and (root.Position - man:GetPivot().Position).Magnitude < 24
end

local function toLobby(player, data)
	if RunService:IsStudio() then
		remote:FireClient(player, "Message", "(Studio) would teleport you to the lobby now.")
		return
	end
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData(data or { from = "Glitched" })
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, Config.LobbyPlaceId(), { player }, options)
	if not ok then
		warn("[Glitch] teleport failed: " .. tostring(err))
		remote:FireClient(player, "Message", "Th3 w4y 1s cl0s3d... try 4g41n.")
	end
end

remote.OnServerEvent:Connect(function(player, action)
	if busy[player] or not nearMan(player) then
		return
	end
	busy[player] = true
	local ok, err = pcall(function()
		if action == "Talk" then
			local worked, record = read(player)
			remote:FireClient(player, "State", {
				HasOrb = worked and CashLedger.itemCount(record, ITEM) > 0,
				Freed = worked and CashLedger.owns(record, "Classes", CLASS),
				Failed = not worked,
			})
		elseif action == "Give" then
			local worked, applied, record = RecordStore.TradeItemForClass(player.UserId, ITEM, CLASS)
			if worked and applied then
				records[player] = record
				RecordStore.PublishInventory(player, record)
				remote:FireClient(player, "Cutscene", { Man = man })
				task.delay(CUTSCENE_SECONDS, function()
					if player.Parent == Players then
						toLobby(player, { from = "Glitched", unlocked = CLASS })
					end
				end)
			elseif worked then
				remote:FireClient(player, "Message", "y0u d0n't h4ve 1t... d0n't l13 t0 m3.")
			elseif RunService:IsStudio() then
				-- no save in Studio without API access: play the scene anyway so it can be seen
				remote:FireClient(player, "Cutscene", { Man = man, Studio = true })
			else
				remote:FireClient(player, "Message", "s0m3th1ng 1s wr0ng... try 4g41n.")
			end
		end
	end)
	busy[player] = nil
	if not ok then
		warn("[Glitch] " .. tostring(err))
	end
end)

-- the way back: walking into the gate at the start goes home with nothing changed
local function bindExit(part)
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if player and not busy[player] then
				busy[player] = true
				toLobby(player, { from = "Glitched" })
				task.delay(5, function()
					busy[player] = nil
				end)
			end
		end)
	end
end
for _, part in CollectionService:GetTagged("GlitchExit") do
	bindExit(part)
end
CollectionService:GetInstanceAddedSignal("GlitchExit"):Connect(bindExit)

-- falling off the road puts you back on it
local spawnPoint = world and world:FindFirstChild("Spawn", true)
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y < -120 then
				local back = character:GetAttribute("LastSafe") or (spawnPoint and spawnPoint.Position + Vector3.new(0, 4, 0)) or Vector3.new(0, 10, 0)
				character:PivotTo(CFrame.new(back))
				root.AssemblyLinearVelocity = Vector3.zero
			elseif root and root.Position.Y > -20 then
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { character }
				params.FilterType = Enum.RaycastFilterType.Exclude
				local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params)
				if hit then
					character:SetAttribute("LastSafe", hit.Position + Vector3.new(0, 4, 0))
				end
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(read, player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(read, player)
end
Players.PlayerRemoving:Connect(function(player)
	records[player] = nil
	busy[player] = nil
end)

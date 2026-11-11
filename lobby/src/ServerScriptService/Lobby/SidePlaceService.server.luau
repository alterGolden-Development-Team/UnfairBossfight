--!nonstrict
--[[
 SidePlaceService - Azusa and the two side places (UnfairConfig.SidePlaces).
   * Azusa stands in the hub, wearing the Roblox avatar of mymeo125. Hold E at her and she asks what you are looking for
     (AzusaClient). "Please teach me how to fight" sends you to her training grounds, the Tutorial place.
   * Parts tagged `UnfairPlacePortal` with attribute `Place` ("Glitched" | "Tutorial") send whoever walks in to that place
     (the black-and-white glitched portal in the Divided Wood).
   SidePlace remote  client -> server: "Go", placeName      server -> client: "Result", { Message }
 Teleports cannot run in Studio: there it only says what would have happened.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.UnfairShared.UnfairConfig)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)

local remote = LobbyRemotes.get("SidePlace")
local areaRemote = LobbyRemotes.get("Area")

local AZUSA_USER = "mymeo125"
local AZUSA_USER_ID = nil -- resolved from the name on start
local GAP = 4 -- seconds between teleport tries per player
local lastTry = {}

local function say(player, message)
	remote:FireClient(player, "Result", { Message = message })
end

local function go(player, placeName)
	local placeId = Config.SidePlaceId(placeName)
	if not placeId then
		return
	end
	if os.clock() - (lastTry[player] or -math.huge) < GAP then
		return
	end
	lastTry[player] = os.clock()
	if player:GetAttribute("PartyRoom") ~= nil or player:GetAttribute("PartyLocked") == true then
		say(player, "Leave your party first.")
		return
	end
	if RunService:IsStudio() then
		say(player, "(Studio) would teleport you to " .. placeName .. " (" .. placeId .. ").")
		return
	end
	areaRemote:FireClient(player, "FadeOut", placeName == "Glitched" and "Glitch" or "Tutorial")
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ from = "Lobby", place = placeName })
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, placeId, { player }, options)
	if not ok then
		warn("[SidePlace] teleport failed: " .. tostring(err))
		areaRemote:FireClient(player, "FadeIn", player:GetAttribute("Area"))
		say(player, "The way is closed right now. Try again in a moment.")
	end
end

remote.OnServerEvent:Connect(function(player, action, placeName)
	if action == "Go" and (placeName == "Tutorial") then
		-- only Azusa's choice comes from the client; the glitched place is reached by walking into its portal
		local azusa = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Hub") and workspace.World.Hub:FindFirstChild("Azusa")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if azusa and root and (root.Position - azusa:GetPivot().Position).Magnitude < 30 then
			go(player, "Tutorial")
		end
	end
end)

TeleportService.TeleportInitFailed:Connect(function(player, result, message)
	warn("[SidePlace] " .. player.Name .. ": " .. tostring(result) .. " " .. tostring(message))
	areaRemote:FireClient(player, "FadeIn", player:GetAttribute("Area"))
	say(player, "The way is closed right now. Try again in a moment.")
end)

-- portals into side places -----------------------------------------------------------------------------------------------
local function bindPortal(part)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local place = part:GetAttribute("Place")
		if player and type(place) == "string" then
			go(player, place)
		end
	end)
end
for _, part in CollectionService:GetTagged("UnfairPlacePortal") do
	bindPortal(part)
end
CollectionService:GetInstanceAddedSignal("UnfairPlacePortal"):Connect(bindPortal)

-- Azusa --------------------------------------------------------------------------------------------------------------------
local IDLE_R15 = "rbxassetid://507766388" -- Roblox's default R15 idle

local function buildAzusa(spot)
	local okId, userId = pcall(Players.GetUserIdFromNameAsync, Players, AZUSA_USER)
	if not okId then
		warn("[Azusa] could not look up " .. AZUSA_USER .. ": " .. tostring(userId))
		return nil
	end
	AZUSA_USER_ID = userId
	local okDesc, description = pcall(Players.GetHumanoidDescriptionFromUserIdAsync, Players, userId)
	if not okDesc then
		warn("[Azusa] could not load the avatar: " .. tostring(description))
		return nil
	end
	local okModel, model = pcall(Players.CreateHumanoidModelFromDescriptionAsync, Players, description, Enum.HumanoidRigType.R15)
	if not okModel then
		warn("[Azusa] could not build the avatar: " .. tostring(model))
		return nil
	end
	model.Name = "Azusa"
	model:SetAttribute("AvatarUserId", userId)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = "Azusa"
	humanoid.NameDisplayDistance = 40
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true
	model:PivotTo(spot)
	-- stand on the ground: the rig's feet go where the spot is
	local height = humanoid.HipHeight + root.Size.Y / 2
	model:PivotTo(spot + Vector3.new(0, height, 0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = "Azusa"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local idle = Instance.new("Animation")
	idle.AnimationId = IDLE_R15
	local okTrack, track = pcall(animator.LoadAnimation, animator, idle)
	if okTrack then
		track.Looped = true
		track:Play()
	end
	return model
end

task.spawn(function()
	local world = workspace:WaitForChild("World", 30)
	local hub = world and world:WaitForChild("Hub", 30)
	if not hub then
		return
	end
	local spot = hub:WaitForChild("AzusaSpot", 15)
	if not spot then
		warn("[Azusa] World.Hub.AzusaSpot is missing; Azusa stays away")
		return
	end
	local old = hub:FindFirstChild("Azusa")
	if old then
		old:Destroy()
	end
	local model = buildAzusa(spot.CFrame)
	if model then
		model.Parent = hub
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastTry[player] = nil
end)

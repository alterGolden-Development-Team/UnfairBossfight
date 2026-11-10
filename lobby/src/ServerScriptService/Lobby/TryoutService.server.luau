--!nonstrict
--[[
 TryoutService - the shop's showroom. A wooden dummy stands on the stage wearing the class you are looking at and uses its skills on
 a second dummy. The skills are not copies: the performer is your own character given a plain dummy body, and it runs the boss
 place's own class kits (ServerScriptService.BossSystem, mounted from ../boss) against the boss place's training dummy.
 If a kit changes in the boss project it changes here.
   Tryout remote  client -> server: "Enter", classId | "Class", classId | "Ready" | "Leave"
                  server -> client: "Result", { Message }
   "Ready" puts the performer back on its mark with every cooldown cleared; the client then sends the skill on ClassControl
   exactly as the fight's own input does.
   Player attribute `TryoutClass` is the class being shown (nil outside the showroom). Showing a class does not select or unlock it.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)

local remote = LobbyRemotes.get("Tryout")
local areaRemote = LobbyRemotes.get("Area")

local world = workspace:WaitForChild("World", 30)
local stage = world and world:WaitForChild("Stage", 10)
local bossSystem = ServerScriptService:FindFirstChild("BossSystem")
if not stage or not bossSystem then
	warn("[Tryout] the training hall or the class kits are missing; trying classes is off")
	return
end

-- The boss place keeps a few RemoteEvents in its place file, not in code. The kits wait for them, so this place needs them too.
local function needEvent(parent, name)
	if parent and not parent:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = parent
	end
end
needEvent(ReplicatedStorage:FindFirstChild("VFXEngine"), "Event") -- VFX cues
needEvent(ReplicatedStorage, "BossCombatEffects") -- skill sounds

-- Tells ClassService it is a guest here: the lobby owns unlocks and class choice (see ClassService.Start).
workspace:SetAttribute("ClassShowroom", true)
local ClassService = require(bossSystem.Players.Classes.ClassService)
local TrainingDummy = require(bossSystem.Players.Classes.TrainingDummy)
ClassService.Start()

local dummySpot = stage:WaitForChild("DummySpot")
if not workspace:FindFirstChild("ClassTrainingDummy") then
	TrainingDummy.Create(dummySpot.Position)
end

local FADE_TIME = 0.35
local MARKS = 8 -- performers stand in a ring round the target, one mark each
local REACH = 7 -- studs from the target: inside every melee range
local busy = {}
local markOf = {}

local function alive(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart") then
		return character, humanoid
	end
end

local function reply(player, message)
	remote:FireClient(player, "Result", { Message = message })
end

local function markCF(player)
	local taken = {}
	for other, index in markOf do
		if other ~= player then
			taken[index] = true
		end
	end
	if not markOf[player] then
		for index = 1, MARKS do
			if not taken[index] then
				markOf[player] = index
				break
			end
		end
	end
	local a = ((markOf[player] or 1) - 1) / MARKS * math.pi * 2 + math.pi
	local at = dummySpot.Position + Vector3.new(math.cos(a) * REACH, 3, math.sin(a) * REACH)
	return CFrame.lookAt(at, Vector3.new(dummySpot.Position.X, at.Y, dummySpot.Position.Z))
end

-- The performer: a plain grey R6 dummy (the kits are written for R6 bodies), named for the player so the kits treat it as theirs.
local function dummyBody(player, character, at)
	local description = Instance.new("HumanoidDescription")
	local grey = Color3.fromRGB(150, 146, 140)
	description.HeadColor, description.TorsoColor = grey, Color3.fromRGB(110, 104, 98)
	description.LeftArmColor, description.RightArmColor = grey, grey
	description.LeftLegColor, description.RightLegColor = Color3.fromRGB(96, 90, 86), Color3.fromRGB(96, 90, 86)
	local model = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R6)
	description:Destroy()
	model.Name = player.Name
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	model:PivotTo(at)
	player.Character = model
	model.Parent = workspace
	character:Destroy()
	return model
end

local function wear(player, classId)
	local character = alive(player)
	if not character then
		return
	end
	player:SetAttribute("TryoutClass", classId)
	ClassService.Apply(player, character)
end

local function enter(player, classId)
	local character, humanoid = alive(player)
	if not character then
		return
	end
	if player:GetAttribute("PartyRoom") ~= nil or player:GetAttribute("PartyLocked") == true then
		reply(player, "Leave your party first.")
		return
	end
	areaRemote:FireClient(player, "FadeOut", "Stage")
	task.wait(FADE_TIME)
	character, humanoid = alive(player)
	if not character then
		areaRemote:FireClient(player, "FadeIn", player:GetAttribute("Area"))
		return
	end
	local at = markCF(player)
	character = dummyBody(player, character, at)
	-- a swapped body counts as a new character: let the spawn handlers (spawn point, Area = Hub) run, then put it on its mark
	task.wait(0.15)
	character:PivotTo(at)
	player:SetAttribute("Area", "Stage")
	wear(player, classId)
	task.wait(0.25)
	areaRemote:FireClient(player, "FadeIn", "Stage")
end

local function leave(player)
	areaRemote:FireClient(player, "FadeOut", "Hub")
	task.wait(FADE_TIME)
	player:SetAttribute("TryoutClass", nil)
	markOf[player] = nil
	-- a new character is the clean way out of a class: no gear, buffs, speed or health left over
	player:LoadCharacter()
	local character = player.Character
	local back = world:FindFirstChild("Shop") and world.Shop:FindFirstChild("ShopArrival")
	if character and back then
		character:WaitForChild("HumanoidRootPart", 5)
		task.wait()
		character:PivotTo(back.CFrame + Vector3.new(0, 3, 0))
	end
	player:SetAttribute("Area", "Hub")
	task.wait(0.25)
	areaRemote:FireClient(player, "FadeIn", "Hub")
end

remote.OnServerEvent:Connect(function(player, action, classId)
	if busy[player] or type(action) ~= "string" then
		return
	end
	if action ~= "Leave" and action ~= "Ready" and (type(classId) ~= "string" or not ClassConfig.Classes[classId]) then
		return
	end
	local inHall = player:GetAttribute("TryoutClass") ~= nil
	busy[player] = true
	local ok, err = pcall(function()
		if action == "Enter" and not inHall then
			enter(player, classId)
		elseif (action == "Class" or action == "Enter") and inHall then
			wear(player, classId)
		elseif action == "Ready" and inHall then
			local character = alive(player)
			if character then
				ClassService.CancelActions(character)
				ClassService.ResetCooldowns(character)
				character:SetAttribute("Stamina", character:GetAttribute("MaxStamina"))
				character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
				character:PivotTo(markCF(player))
			end
		elseif action == "Leave" and inHall then
			leave(player)
		end
	end)
	busy[player] = nil
	if not ok then
		warn("[Tryout] " .. tostring(err))
	end
end)

-- Dying or resetting in the showroom puts you back in the hub as yourself.
local function onPlayer(player)
	player.CharacterAdded:Connect(function()
		if not busy[player] then
			markOf[player] = nil
			player:SetAttribute("TryoutClass", nil)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	busy[player] = nil
	markOf[player] = nil
end)

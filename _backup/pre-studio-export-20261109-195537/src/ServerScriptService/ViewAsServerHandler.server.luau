 
 

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OWNER_ID = game.CreatorId

local function isOwner(player)
	return game.CreatorType == Enum.CreatorType.User and player.UserId == OWNER_ID
end

local function applyToCharacter(player)
	local char = player.Character
	if char then
		char:SetAttribute("ViewAsServer", player:GetAttribute("ViewAsServer") == true)
	end
end

local remote = ReplicatedStorage:WaitForChild("ViewAsServerToggle")
local lastToggle = {}

remote.OnServerEvent:Connect(function(player)
	if not isOwner(player) then
		return
	end
	local now = os.clock()
	if now - (lastToggle[player] or -math.huge) < 0.2 then return end
	lastToggle[player] = now
	player:SetAttribute("ViewAsServer", player:GetAttribute("ViewAsServer") ~= true)
end)

local function onPlayerAdded(player)
	player:SetAttribute("ViewAsServer", false)
	player:GetAttributeChangedSignal("ViewAsServer"):Connect(function()
		applyToCharacter(player)
		if player:GetAttribute("ViewAsServer") == true then
			require(game.ServerScriptService.BossSystem.Combat.StatusEffectService).Clear(player)
		end
	end)
	player.CharacterAdded:Connect(function()
		applyToCharacter(player)
	end)
	if player.Character then
		applyToCharacter(player)
	end
end

Players.PlayerRemoving:Connect(function(player) lastToggle[player] = nil end)
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

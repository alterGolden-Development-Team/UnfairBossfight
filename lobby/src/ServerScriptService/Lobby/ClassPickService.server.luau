--!strict
-- Class picker, server side (plan task 13). The client only asks; this decides.
--   * the class must exist in ClassConfig, and any unlock (badge / game pass) is checked here on every pick
--   * the pick is stored as the player attribute `PlayerClass`; the party and the launch read it from the server
--   * `ClassUnlocked_<id>` attributes tell the UI which padlocks to show (the UI never decides anything)
--   * a player whose party is launching (`PartyLocked`) cannot change class

local BadgeService = game:GetService("BadgeService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClassConfig: any = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local ClassUnlocks: any = require(ReplicatedStorage.BossShared.Classes.ClassUnlocks)
local UnlockCheck = require(ReplicatedStorage.UnfairShared.UnlockCheck)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)
local PlayerData: any = require(script.Parent.PlayerData)

local remote = LobbyRemotes.get("ClassPick")
local classes: { [string]: any } = ClassConfig.Classes
local unlocks: { [string]: UnlockCheck.Entry } = ClassUnlocks

local REQUEST_GAP = 0.5 -- seconds between requests from one player
local lastRequest: { [Player]: number } = {}
local busy: { [Player]: boolean } = {}
local owned: { [Player]: { [string]: boolean } } = {} -- only "yes" is remembered; a "no" is asked again

-- Studio, the experience creator, and `ForceClassLocks` (to test padlocks) behave like the boss place.
local function bypass(player: Player): boolean
	if workspace:GetAttribute("ForceClassLocks") == true then
		return false
	end
	return RunService:IsStudio() or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId)
end

local function depsFor(player: Player): UnlockCheck.Deps
	return {
		bypass = function()
			return bypass(player)
		end,
		hasBadge = function(badgeId: number)
			local ok, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, badgeId)
			return ok, ok and has == true
		end,
		hasPass = function(passId: number)
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
			return ok, ok and has == true
		end,
		hasBought = function(classId: string)
			return PlayerData.OwnsClass(player, classId)
		end,
		isPresent = function()
			return player.Parent == Players
		end,
		wait = function(seconds: number)
			task.wait(seconds)
		end,
	}
end

local function refreshUnlocks(player: Player)
	local deps = depsFor(player)
	for id, entry in unlocks do
		local result = UnlockCheck.resolve(entry, deps, 3)
		if player.Parent ~= Players then
			return
		end
		if result ~= nil then
			player:SetAttribute("ClassUnlocked_" .. id, result)
			if result then
				owned[player] = owned[player] or {}
				owned[player][id] = true
			end
		end
	end
	player:SetAttribute("ClassUnlocksChecked", true)
end

local function onPlayerAdded(player: Player)
	if player:GetAttribute("PlayerClass") == nil then
		player:SetAttribute("PlayerClass", ClassConfig.Default)
	end
	task.spawn(refreshUnlocks, player)
end

remote.OnServerEvent:Connect(function(player: Player, action: any, classId: any)
	if type(action) ~= "string" or type(classId) ~= "string" then
		return
	end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < REQUEST_GAP or busy[player] then
		return
	end
	lastRequest[player] = now

	if action == "Buy" then
		local entry = unlocks[classId]
		if entry and entry.Kind == "GamePass" then
			if entry.Id > 0 then
				pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, entry.Id)
			else
				remote:FireClient(player, "Result", { Message = "This game pass is not on sale yet." })
			end
		end
		return
	end
	if action ~= "Select" then
		return
	end

	if player:GetAttribute("PartyLocked") == true then
		remote:FireClient(player, "Result", { Message = "Your party is launching." })
		return
	end

	busy[player] = true
	local result: UnlockCheck.PickResult?
	if owned[player] and owned[player][classId] and classes[classId] then
		result = { ok = true, message = "" }
	else
		result = UnlockCheck.pick(classId, classes, unlocks, depsFor(player))
	end
	busy[player] = nil

	if result == nil or player.Parent ~= Players then
		return -- unknown class, or the player left while we were asking
	end
	if not result.ok then
		remote:FireClient(player, "Result", { Message = result.message })
		return
	end
	if player:GetAttribute("PartyLocked") == true then
		return -- the party started launching while the check ran
	end
	owned[player] = owned[player] or {}
	owned[player][classId] = true
	player:SetAttribute("PlayerClass", classId)
	remote:FireClient(player, "Result", { Message = "", Selected = classId })
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
	if not purchased then
		return
	end
	for id, entry in unlocks do
		if entry.Kind == "GamePass" and entry.Id == passId then
			player:SetAttribute("ClassUnlocked_" .. id, true)
			owned[player] = owned[player] or {}
			owned[player][id] = true
		end
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player: Player)
	lastRequest[player] = nil
	busy[player] = nil
	owned[player] = nil
end)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

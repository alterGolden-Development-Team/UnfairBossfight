--!nonstrict
--[[
 PlayerData - the lobby's copy of each player's saved record (spec 6.3 and docs/spec/lobby-redesign.md).
 The boss place writes cash for wins; the lobby reads it and spends it in the shop. Every write is an UpdateAsync through the pure rules
 in UnfairShared/CashLedger, so a retry cannot charge twice and the balance cannot go negative. The client has no way to ask for cash.

 Published for the UI and for the Roblox player list:
   leaderstats.Cash      the number on the leaderboard
   Cash / CashState      "Loading" | "Ready" | "Error"
   OrbOwned_<id>         owned orbs
   PlayerOrb             the equipped orb
   Inventory             JSON { [itemId] = count } of the items found in the world (UnfairShared/ItemConfig)
]]
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local Config = require(Shared:WaitForChild("UnfairConfig"))
local CashLedger = require(Shared:WaitForChild("CashLedger"))
local OrbConfig = require(Shared:WaitForChild("OrbConfig"))

local api = {}
local records = {} -- [Player] = the last record read or written
local store = nil

local function getStore()
	if store == nil then
		local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, Config.CashStore(RunService:IsStudio()))
		if ok then
			store = result
		else
			warn("[PlayerData] cannot open the data store: " .. tostring(result))
		end
	end
	return store
end

local function publish(player, record)
	records[player] = record or {}
	local cash = CashLedger.balance(record)
	player:SetAttribute("Cash", cash)
	player:SetAttribute("CashState", "Ready")
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Cash")
	if value then
		value.Value = cash
	end
	for id in OrbConfig.Items do
		player:SetAttribute("OrbOwned_" .. id, CashLedger.owns(record, "Orbs", id))
	end
	player:SetAttribute("PlayerOrb", CashLedger.equippedOrb(record))
	-- the inventory (InventoryClient): items found in the world, e.g. the Reality Orb
	local ok, json = pcall(game:GetService("HttpService").JSONEncode, game:GetService("HttpService"), CashLedger.items(record))
	player:SetAttribute("Inventory", ok and json or "{}")
end

-- (lookup worked, record)
local function read(player)
	local ds = getStore()
	if not ds then
		return false, nil
	end
	local ok, value = pcall(ds.GetAsync, ds, CashLedger.key(player.UserId))
	if not ok then
		warn(`[PlayerData] read for {player.Name} failed: {tostring(value)}`)
		return false, nil
	end
	return true, value
end

local function track(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = stats
	stats.Parent = player

	player:SetAttribute("CashState", "Loading")
	task.spawn(function()
		local attempt = 0
		while player.Parent == Players do
			local ok, record = read(player)
			if ok then
				publish(player, record)
				break
			end
			player:SetAttribute("CashState", "Error")
			attempt += 1
			task.wait(math.min(30, 3 * attempt))
		end
		-- a player back from a win can arrive a moment before the boss place has finished saving
		for _, delay in { 8, 17 } do
			task.wait(delay)
			if player.Parent ~= Players then
				return
			end
			local ok, record = read(player)
			if ok then
				publish(player, record)
			end
		end
	end)
end

-- The saved record, waiting up to `seconds` for the first read. nil if it is not available.
function api.Get(player, seconds)
	local deadline = os.clock() + (seconds or 10)
	while records[player] == nil and player.Parent == Players and os.clock() < deadline do
		task.wait(0.1)
	end
	return records[player]
end

-- Runs one UpdateAsync with a pure rule. Returns the rule's result, or nil if the store could not be reached.
local function update(player, rule)
	local ds = getStore()
	if not ds then
		return nil
	end
	local outcome, written
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			ds:UpdateAsync(CashLedger.key(player.UserId), function(old)
				local new, result = rule(old)
				outcome, written = result, new
				return new
			end)
		end)
		if ok then
			publish(player, written)
			return outcome
		end
		warn(`[PlayerData] write for {player.Name} failed: {tostring(err)}`)
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	return nil
end

-- result: "Bought" | "AlreadyOwned" | "TooPoor" | "Invalid" | nil (the store could not be reached)
function api.Purchase(player, kind, id, price)
	return update(player, function(old)
		local new, result = CashLedger.purchase(old, kind, id, price)
		if result ~= "Bought" then
			return old or {}, result
		end
		return new, result
	end)
end

-- orbId nil takes the orb off. Returns true when it is done.
function api.EquipOrb(player, orbId)
	local result = update(player, function(old)
		local new, applied = CashLedger.equip(old, orbId)
		return new, applied
	end)
	return result == true
end

function api.OwnsClass(player, classId)
	local record = api.Get(player, 10)
	if record == nil then
		return false, false
	end
	return true, CashLedger.owns(record, "Classes", classId)
end

Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(player)
	records[player] = nil
end)
for _, player in Players:GetPlayers() do
	task.spawn(track, player)
end

return api

--!nonstrict
--[[
 Lobby CashService (plan task 22): reads each player's cash for the HUD. The lobby never writes cash (only the boss place does,
 spec 6.3) and the client has no way to ask for a write.

 Player attributes it publishes:
   Cash       whole number, only set once a read has succeeded
   CashState  "Loading" | "Ready" | "Error"   (the HUD shows "--" unless Ready)
 A failed read is retried with a growing wait. After a good read it reads twice more (8 s and 25 s after joining), because a
 player who has just come back from a win may arrive a moment before the boss place has finished saving.
]]
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local Config = require(Shared:WaitForChild("UnfairConfig"))
local CashLedger = require(Shared:WaitForChild("CashLedger"))

local store = nil
local function getStore()
	if store == nil then
		local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, Config.CashStore(RunService:IsStudio()))
		if ok then
			store = result
		else
			warn("[Cash] cannot open the data store: " .. tostring(result))
		end
	end
	return store
end

-- true plus the balance, or false
local function read(player)
	local ds = getStore()
	if not ds then
		return false, 0
	end
	local ok, value = pcall(ds.GetAsync, ds, CashLedger.key(player.UserId))
	if not ok then
		warn(`[Cash] read for {player.Name} failed: {tostring(value)}`)
		return false, 0
	end
	return true, CashLedger.balance(value)
end

local function publish(player, balance)
	player:SetAttribute("Cash", balance)
	player:SetAttribute("CashState", "Ready")
end

local function track(player)
	player:SetAttribute("CashState", "Loading")
	task.spawn(function()
		local attempt = 0
		while player.Parent == Players do
			local ok, balance = read(player)
			if ok then
				publish(player, balance)
				break
			end
			player:SetAttribute("CashState", "Error")
			attempt += 1
			task.wait(math.min(30, 3 * attempt))
		end
		for _, delay in ipairs({ 8, 17 }) do -- 8 s and 25 s after the first good read
			task.wait(delay)
			if player.Parent ~= Players then
				return
			end
			local ok, balance = read(player)
			if ok and balance ~= player:GetAttribute("Cash") then
				publish(player, balance)
			end
		end
	end)
end

Players.PlayerAdded:Connect(track)
for _, player in ipairs(Players:GetPlayers()) do
	track(player)
end

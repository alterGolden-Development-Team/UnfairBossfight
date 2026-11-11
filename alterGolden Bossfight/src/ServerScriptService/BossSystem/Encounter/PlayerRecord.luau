--!nonstrict
-- Read-only view of a player's saved record in the boss place (what the shop sold them). The lobby is the only place that sells,
-- the boss only checks, so a client or a forged teleport payload cannot grant a class or an orb.
-- Get returns (lookup worked, record). A failed read fails closed: callers treat it as "not verified".
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local Config = require(Shared:WaitForChild("UnfairConfig"))
local CashLedger = require(Shared:WaitForChild("CashLedger"))

local api = {}
local cache = {} -- [userId] = record; a good read is kept for this server, a run does not buy anything

function api.Get(userId)
	if cache[userId] ~= nil then
		return true, cache[userId]
	end
	local okStore, store = pcall(DataStoreService.GetDataStore, DataStoreService, Config.CashStore(RunService:IsStudio()))
	if not okStore then
		return false, nil
	end
	local ok, record = pcall(store.GetAsync, store, CashLedger.key(userId))
	if not ok then
		warn("[PlayerRecord] read failed: " .. tostring(record))
		return false, nil
	end
	cache[userId] = record or {}
	return true, cache[userId]
end

return api

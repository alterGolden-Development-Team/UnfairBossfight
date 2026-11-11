--!nonstrict
--[[
 RecordStore - server-side reads and writes of a player's saved record, for the places that are not the lobby shop: the boss place
 (finding the Reality Orb), the glitched place (handing it over), the tutorial. One UpdateAsync per change, through a pure rule from
 CashLedger, so a retried write cannot apply twice (an item at its limit is not added again; a class already owned is not re-granted).
 Same DataStore and key as the lobby's PlayerData and the boss's PlayerRecord (UnfairConfig.CashStore, CashLedger.key).
]]
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.UnfairConfig)
local CashLedger = require(script.Parent.CashLedger)

local api = {}
local store

local function getStore()
	if not store then
		local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, Config.CashStore(RunService:IsStudio()))
		if ok then
			store = result
		else
			warn("[RecordStore] cannot open the data store: " .. tostring(result))
		end
	end
	return store
end

-- (lookup worked, record)
function api.Read(userId)
	local ds = getStore()
	if not ds then
		return false, nil
	end
	local ok, record = pcall(ds.GetAsync, ds, CashLedger.key(userId))
	if not ok then
		warn("[RecordStore] read failed: " .. tostring(record))
		return false, nil
	end
	return true, record or {}
end

-- Applies rule(old) -> (new, applied) in one UpdateAsync. Returns (write worked, applied, new record).
function api.Update(userId, rule)
	local ds = getStore()
	if not ds then
		return false, false, nil
	end
	for attempt = 1, 3 do
		local applied, written = false, nil
		local ok, err = pcall(function()
			ds:UpdateAsync(CashLedger.key(userId), function(old)
				local new, did = rule(old)
				applied, written = did, new
				return new
			end)
		end)
		if ok then
			return true, applied, written
		end
		warn("[RecordStore] write failed: " .. tostring(err))
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	return false, false, nil
end

function api.AddItem(userId, itemId, count, limit)
	return api.Update(userId, function(old)
		return CashLedger.addItem(old, itemId, count or 1, limit)
	end)
end

-- Takes one `itemId` and grants `classId` in the same write: the hand-over of the Reality Orb.
function api.TradeItemForClass(userId, itemId, classId)
	return api.Update(userId, function(old)
		local taken, ok = CashLedger.takeItem(old, itemId)
		if not ok then
			return old or {}, false
		end
		local granted = CashLedger.grantClass(taken, classId)
		return granted, true
	end)
end

-- What a client may see of its own record: the inventory as a JSON-friendly table.
function api.PublishInventory(player, record)
	local items = CashLedger.items(record)
	local ok, json = pcall(game:GetService("HttpService").JSONEncode, game:GetService("HttpService"), items)
	player:SetAttribute("Inventory", ok and json or "{}")
end

return api

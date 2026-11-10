--!nonstrict
--[[
 CashService - pays cash for a win (spec 6.3, plan task 21). The boss place is the only writer; the lobby only reads.
 The rules are pure and tested: UnfairShared/CashRules (how much) and UnfairShared/CashLedger (how a record changes).

   * Only runs that came from the lobby pay (workspace LobbyMode + LobbyRunId); the old "walk up to the statue" game
     does not touch the DataStore at all.
   * PayWinners is called once by VictoryRewards when the boss falls, with the same players that get the victory badge.
   * One write per (runId, player): UpdateAsync adds the amount unless the record already lists that runId, so a retry
     (or a second server finishing the same write) cannot pay twice.
   * A failed write is retried with backoff; if it still fails the amount is kept in `unsaved` for the rest of the session,
     retried every 30 s and once more when the server closes, so the player is not silently robbed.
   * Studio writes go to Config.CashStoreNameStudio, never to the real store.
 WaitFor(player, seconds) lets "Return to Lobby" wait until that player's cash has been saved, so the lobby HUD is right
 when they arrive.
]]
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local Config = require(Shared:WaitForChild("UnfairConfig"))
local CashRules = require(Shared:WaitForChild("CashRules"))
local CashLedger = require(Shared:WaitForChild("CashLedger"))

local api = {}

local store = nil
local paid = {} -- ["runId:userId"] = true once a payout for that pair has been started in this server
local unsaved = {} -- ["runId:userId"] = { userId = n, runId = s, amount = n, name = s }
local working = {} -- [userId] = number of settle() calls still running for that player
local started = false

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

-- One UpdateAsync. Returns true when the record now contains this run (written now or already there).
local function writeOnce(entry)
	local ds = getStore()
	if not ds then
		return false
	end
	local ok, err = pcall(function()
		ds:UpdateAsync(CashLedger.key(entry.userId), function(old)
			local new, applied = CashLedger.apply(old, entry.runId, entry.amount)
			if not applied then
				return nil -- already paid (or nothing to pay): leave the stored record alone
			end
			return new
		end)
	end)
	if not ok then
		warn(`[Cash] write for {entry.name} failed: {tostring(err)}`)
	end
	return ok
end

local function settle(entry, attempts)
	local id = entry.runId .. ":" .. entry.userId
	working[entry.userId] = (working[entry.userId] or 0) + 1
	local saved = false
	for attempt = 1, attempts do
		if writeOnce(entry) then
			saved = true
			break
		end
		if attempt < attempts then
			task.wait(math.min(8, 2 ^ (attempt - 1)))
		end
	end
	if saved then
		unsaved[id] = nil
	else
		unsaved[id] = entry
		warn(`[Cash] {entry.amount} cash for {entry.name} is not saved yet; it will be retried`)
	end
	working[entry.userId] = working[entry.userId] - 1
	if working[entry.userId] <= 0 then
		working[entry.userId] = nil
	end
	return saved
end

-- Pay each of `winners` for a win on `difficulty`. Safe to call twice for the same run: nobody is paid twice.
function api.PayWinners(winners, difficulty, enraged)
	if workspace:GetAttribute("LobbyMode") ~= true then
		return 0
	end
	local runId = workspace:GetAttribute("LobbyRunId")
	if type(runId) ~= "string" or runId == "" then
		warn("[Cash] lobby run without a run id: nothing paid")
		return 0
	end
	local amount = CashRules.payout(difficulty, enraged == true)
	if amount <= 0 then
		warn("[Cash] no payout for difficulty " .. tostring(difficulty))
		return 0
	end
	local count = 0
	for _, player in ipairs(winners) do
		local id = runId .. ":" .. player.UserId
		if player.UserId > 0 and not paid[id] then
			paid[id] = true
			count += 1
			local okOrb, withOrb = pcall(require(script.Parent.Orbs).CashFor, player, amount)
			local earned = okOrb and withOrb or amount
			player:SetAttribute("CashEarned", earned)
			local entry = { userId = player.UserId, runId = runId, amount = earned, name = player.Name }
			task.spawn(settle, entry, Config.CashWriteAttempts)
		end
	end
	return count
end

-- Yield until nothing is being saved for this player (or the time is up). Returns true when everything is saved.
function api.WaitFor(player, seconds)
	local deadline = os.clock() + (seconds or Config.CashReturnWaitSeconds)
	local function pendingFor()
		if working[player.UserId] then
			return true
		end
		for _, entry in pairs(unsaved) do
			if entry.userId == player.UserId then
				return true
			end
		end
		return false
	end
	while pendingFor() and os.clock() < deadline do
		task.wait(0.25)
	end
	return not pendingFor()
end

-- Try every parked payout again. Each one runs in its own thread; settle() parks it again if it still fails.
local function flush(attempts)
	local batch = {}
	for id, entry in pairs(unsaved) do
		if not working[entry.userId] then
			table.insert(batch, { id = id, entry = entry })
		end
	end
	for _, item in ipairs(batch) do
		unsaved[item.id] = nil
		task.spawn(settle, item.entry, attempts)
	end
end

function api.Start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		while true do
			task.wait(30)
			if next(unsaved) then
				flush(2)
			end
		end
	end)
	game:BindToClose(function()
		-- the server is closing: one last pass, then give running writes a moment
		if next(unsaved) then
			flush(2)
		end
		local deadline = os.clock() + 20
		while next(working) and os.clock() < deadline do
			task.wait(0.25)
		end
	end)
end

return api

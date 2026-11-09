--!nonstrict
--[[
 LobbyReturn - "Return to Lobby" for one player (spec 6.4, plan task 19).
 EncounterLifecycle calls Request when a client fires "ReturnToLobby" on the EncounterLifecycle remote.
 The decision is pure and tested: UnfairShared/ReturnRules (lobby run, fight over for this player, cooldown).

   * It first waits (up to Config.CashReturnWaitSeconds) for that player's cash to be saved, so the lobby HUD is right.
   * Then it teleports that single player to the public lobby place. Everyone else stays: Retry keeps working for them.
   * Studio cannot teleport, so it only logs and tells the player what would have happened.
   * A failed teleport tells the player and lets them press the button again.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local Config = require(Shared:WaitForChild("UnfairConfig"))
local ReturnRules = require(Shared:WaitForChild("ReturnRules"))
local CashService = require(script.Parent.CashService)

local api = {}
local lastRequest = setmetatable({}, { __mode = "k" })
local sending = setmetatable({}, { __mode = "k" })
local replyTo = setmetatable({}, { __mode = "k" })
local listening = false

local function fail(player, text)
	sending[player] = nil
	local reply = replyTo[player]
	if reply and player.Parent == Players then
		reply(text)
	end
end

local function listen()
	if listening then
		return
	end
	listening = true
	TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
		if sending[player] then
			warn(`[Return] teleport for {player.Name} failed: {tostring(result)} {tostring(errorMessage)}`)
			fail(player, "Could not reach the lobby. Please try again.")
		end
	end)
end

-- reply(text) tells the requesting player something (a refusal or a failure).
function api.Request(player, reply)
	listen()
	replyTo[player] = reply
	if sending[player] then
		return
	end
	local now = os.clock()
	local allowed, reason = ReturnRules.decide({
		lobbyMode = workspace:GetAttribute("LobbyMode") == true,
		won = workspace:GetAttribute("BossEncounterWon") == true,
		defeated = player:GetAttribute("PermanentlyDefeated") == true,
		now = now,
		lastRequest = lastRequest[player],
	})
	lastRequest[player] = now
	if not allowed then
		reply(ReturnRules.message(reason))
		return
	end

	sending[player] = true
	task.spawn(function()
		CashService.WaitFor(player, Config.CashReturnWaitSeconds)
		if player.Parent ~= Players then
			return
		end
		local lobby = Config.LobbyPlaceId()
		if RunService:IsStudio() then
			warn(`[Return] Studio: {player.Name} would be teleported to the lobby place {lobby}`)
			fail(player, "Studio test: this would send you back to the lobby.")
			return
		end
		local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, lobby, { player })
		if not ok then
			warn(`[Return] TeleportAsync for {player.Name} failed: {tostring(err)}`)
			fail(player, "Could not reach the lobby. Please try again.")
			return
		end
		-- success: the player is on their way out. If the teleport quietly never happens, let them press again.
		task.delay(20, function()
			if sending[player] then
				sending[player] = nil
			end
		end)
	end)
end

return api

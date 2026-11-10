--!nonstrict
-- The shop's server side. The client names what it wants; the price comes from the server's own tables. Only classes sold for cash can be
-- bought here; badge classes are earned and game pass classes go through ClassPick "Buy".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassUnlocks = require(ReplicatedStorage.BossShared.Classes.ClassUnlocks)
local OrbConfig = require(ReplicatedStorage.UnfairShared.OrbConfig)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)
local PlayerData = require(script.Parent.PlayerData)

local remote = LobbyRemotes.get("Shop")
local busy = {}

local MESSAGES = {
	Bought = "Purchased!",
	AlreadyOwned = "You already own this.",
	TooPoor = "Not enough cash.",
	Invalid = "That is not for sale.",
}

local function reply(player, ok, message, extra)
	local data = extra or {}
	data.Ok, data.Message = ok, message
	remote:FireClient(player, "Result", data)
end

local function handle(player, action, id)
	if player:GetAttribute("CashState") ~= "Ready" then
		reply(player, false, "Your cash is still loading. Try again in a moment.")
		return
	end
	if action == "BuyClass" then
		local entry = ClassUnlocks[id]
		if type(id) ~= "string" or not entry or entry.Kind ~= "Cash" then
			reply(player, false, MESSAGES.Invalid)
			return
		end
		local result = PlayerData.Purchase(player, "Classes", id, entry.Price)
		if result == nil then
			reply(player, false, "The shop could not reach your save. Try again.")
			return
		end
		if result == "Bought" or result == "AlreadyOwned" then
			player:SetAttribute("ClassUnlocked_" .. id, true)
		end
		reply(player, result == "Bought", MESSAGES[result], { Bought = id })
	elseif action == "BuyOrb" then
		local orb = OrbConfig.Items[id]
		if type(id) ~= "string" or not orb then
			reply(player, false, MESSAGES.Invalid)
			return
		end
		local result = PlayerData.Purchase(player, "Orbs", id, orb.Price)
		if result == nil then
			reply(player, false, "The shop could not reach your save. Try again.")
			return
		end
		reply(player, result == "Bought", MESSAGES[result], { Bought = id })
	elseif action == "EquipOrb" then
		if id ~= nil and (type(id) ~= "string" or not OrbConfig.Items[id]) then
			return
		end
		if player:GetAttribute("PartyLocked") == true then
			reply(player, false, "Your party is launching.")
			return
		end
		if PlayerData.EquipOrb(player, id) then
			reply(player, true, id and "Equipped." or "Orb removed.", { Equipped = id or "" })
		else
			reply(player, false, "You do not own that orb.")
		end
	end
end

remote.OnServerEvent:Connect(function(player, action, id)
	if busy[player] or type(action) ~= "string" then
		return
	end
	busy[player] = true
	local ok, err = pcall(handle, player, action, id)
	busy[player] = nil
	if not ok then
		warn("[Shop] " .. tostring(err))
		reply(player, false, "Something went wrong. Try again.")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	busy[player] = nil
end)

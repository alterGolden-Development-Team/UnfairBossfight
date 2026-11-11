--!nonstrict
-- The orb a player brought from the lobby (spec: docs/spec/lobby-redesign.md). Intake calls Load once on arrival; ClassService calls
-- Apply every time it sets up a character. Numbers live in UnfairShared/OrbConfig. A failed read means no orb, never a free one.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local OrbConfig = require(Shared:WaitForChild("OrbConfig"))
local CashLedger = require(Shared:WaitForChild("CashLedger"))
local PlayerRecord = require(script.Parent.PlayerRecord)

local api = {}

function api.Load(player)
	local ok, record = PlayerRecord.Get(player.UserId)
	local id = ok and CashLedger.equippedOrb(record) or nil
	if id and OrbConfig.Items[id] then
		player:SetAttribute("PlayerOrb", id)
	else
		player:SetAttribute("PlayerOrb", nil)
	end
end

function api.Of(player)
	return OrbConfig.Items[player:GetAttribute("PlayerOrb")]
end

-- Called right after ClassService has set the class's base numbers on the character.
function api.Apply(player, char, humanoid, def)
	local orb = api.Of(player)
	if not orb then
		return
	end
	if orb.Stat == "MaxHealth" then
		humanoid.MaxHealth = math.floor(humanoid.MaxHealth * orb.Value)
		humanoid.Health = humanoid.MaxHealth
	elseif orb.Stat == "Speed" then
		char:SetAttribute("BaseWalkSpeed", def.Speed * orb.Value)
		humanoid.WalkSpeed = def.Speed * orb.Value
	elseif orb.Stat == "Stamina" then
		char:SetAttribute("MaxStamina", def.Stamina * orb.Value)
		char:SetAttribute("Stamina", def.Stamina * orb.Value)
	elseif orb.Stat == "DashCost" then
		char:SetAttribute("ClassDashCost", def.DashCost * orb.Value)
	end
end

-- Cash for a win after this player's orb.
function api.CashFor(player, amount)
	local orb = api.Of(player)
	if orb and orb.Stat == "Cash" then
		return math.floor(amount * orb.Value)
	end
	return amount
end

return api

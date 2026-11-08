 
local Players = game:GetService("Players")
local api = {}
function api.IsActive(player)
	return player ~= nil and player:GetAttribute("ViewAsServer") == true
end
function api.IsCharacter(character)
	return character ~= nil and api.IsActive(Players:GetPlayerFromCharacter(character))
end
return api

 
local api = {}
function api.Resolve(amount, defense)
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount == math.huge then
		return 0
	end
	defense = type(defense) == "number" and defense == defense and defense or 0
	return amount * (1 - math.clamp(defense, -1, 1))
end
return api

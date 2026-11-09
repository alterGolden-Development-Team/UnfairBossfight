--!strict
-- How much cash a win pays (spec 6.3). Pure: the table lives in UnfairConfig, this only applies the rules.
-- Used by the boss place when it pays out; the lobby can use it to show "worth X" hints.

local Config = require(script.Parent.UnfairConfig)

local CashRules = {}

-- Cash for one win. Enraged doubles it, except on Easy (Easy cannot be Enraged, so it pays the plain Easy value).
-- Anything that is not a known difficulty pays 0. Only a real `true` counts as Enraged.
function CashRules.payout(difficulty: any, enraged: any): number
	if not Config.IsDifficulty(difficulty) then
		return 0
	end
	local base = Config.CashByDifficulty[difficulty] or 0
	if enraged == true and Config.EnragedAllowed(difficulty) then
		return base * Config.EnragedCashMultiplier
	end
	return base
end

return CashRules

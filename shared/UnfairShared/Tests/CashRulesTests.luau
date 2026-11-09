--!strict
-- Plan task 20. Run: require(UnfairShared.Tests.CashRulesTests)() -> { passed, failed }

local Config = require(script.Parent.Parent.UnfairConfig)
local CashRules = require(script.Parent.Parent.CashRules)
local Harness = require(script.Parent.Harness)

local cases = Harness.new()

cases:add("the spec table: Easy 5, NerfedHardcore 15, Hardcore 25, TrueHardcore 35, Hellaven 50", function()
	Harness.eq(CashRules.payout("Easy", false), 5)
	Harness.eq(CashRules.payout("NerfedHardcore", false), 15)
	Harness.eq(CashRules.payout("Hardcore", false), 25)
	Harness.eq(CashRules.payout("TrueHardcore", false), 35)
	Harness.eq(CashRules.payout("Hellaven", false), 50)
end)

cases:add("Enraged doubles every difficulty except Easy", function()
	Harness.eq(CashRules.payout("NerfedHardcore", true), 30)
	Harness.eq(CashRules.payout("Hardcore", true), 50)
	Harness.eq(CashRules.payout("TrueHardcore", true), 70)
	Harness.eq(CashRules.payout("Hellaven", true), 100)
end)

cases:add("Enraged on Easy pays the plain Easy value", function()
	Harness.eq(CashRules.payout("Easy", true), 5)
end)

cases:add("every configured difficulty has a positive payout, and Enraged never pays less", function()
	for _, difficulty in Config.Difficulties do
		local plain = CashRules.payout(difficulty, false)
		Harness.truthy(plain > 0, `{difficulty} pays something`)
		Harness.truthy(CashRules.payout(difficulty, true) >= plain, `{difficulty} enraged is not worse`)
	end
end)

cases:add("unknown or malformed difficulty pays 0", function()
	local bad: { any } = { "Nightmare", "easy", "", 5, true, {} }
	for _, value in bad do
		Harness.eq(CashRules.payout(value, false), 0, `difficulty {tostring(value)}`)
		Harness.eq(CashRules.payout(value, true), 0, `enraged difficulty {tostring(value)}`)
	end
	Harness.eq(CashRules.payout(nil, false), 0)
end)

cases:add("only a real true counts as Enraged", function()
	local notTrue: { any } = { "true", 1, {}, false }
	for _, value in notTrue do
		Harness.eq(CashRules.payout("Hardcore", value), 25, `enraged = {tostring(value)}`)
	end
	Harness.eq(CashRules.payout("Hardcore", nil), 25)
end)

return function()
	return cases:run()
end

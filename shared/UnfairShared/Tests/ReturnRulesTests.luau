--!strict
-- Plan task 19 (pure half). Run: require(UnfairShared.Tests.ReturnRulesTests)() -> { passed, failed }

local ReturnRules = require(script.Parent.Parent.ReturnRules)
local Harness = require(script.Parent.Harness)

local cases = Harness.new()

local function state(overrides: { [string]: any }?): ReturnRules.State
	local base: any = { lobbyMode = true, won = false, defeated = false, now = 100, lastRequest = nil }
	if overrides then
		for key, value in overrides do
			base[key] = value
		end
	end
	return base
end

cases:add("a defeated player may return after a loss", function()
	local ok, reason = ReturnRules.decide(state({ defeated = true }))
	Harness.truthy(ok)
	Harness.isNil(reason)
end)

cases:add("anyone may return once the boss is won", function()
	local ok = ReturnRules.decide(state({ won = true }))
	Harness.truthy(ok)
end)

cases:add("a living player in a running fight may not return", function()
	local ok, reason = ReturnRules.decide(state())
	Harness.eq(ok, false)
	Harness.eq(reason, "FightNotOver")
end)

cases:add("outside a lobby run nobody returns, whatever the fight state", function()
	local variants: { { [string]: any } } = { { won = true }, { defeated = true }, {} }
	for _, overrides in variants do
		overrides.lobbyMode = false
		local ok, reason = ReturnRules.decide(state(overrides))
		Harness.eq(ok, false)
		Harness.eq(reason, "NotLobbyRun")
	end
end)

cases:add("a second request inside the cooldown is refused, a later one is not", function()
	local early, reason = ReturnRules.decide(state({ won = true, lastRequest = 99 }))
	Harness.eq(early, false)
	Harness.eq(reason, "TooSoon")
	local later = ReturnRules.decide(state({ won = true, lastRequest = 100 - ReturnRules.CooldownSeconds }))
	Harness.truthy(later)
end)

cases:add("every refusal reason has its own message", function()
	local seen: { [string]: boolean } = {}
	for _, reason in { "NotLobbyRun", "FightNotOver", "TooSoon" } do
		local text = ReturnRules.message(reason)
		Harness.truthy(#text > 0)
		Harness.isNil(seen[text] and text or nil, "duplicate message")
		seen[text] = true
	end
	Harness.truthy(#ReturnRules.message(nil) > 0)
end)

return function()
	return cases:run()
end

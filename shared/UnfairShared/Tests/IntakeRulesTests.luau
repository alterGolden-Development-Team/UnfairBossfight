--!strict
-- Plan tasks 8 and 10 (the case table). Run: require(UnfairShared.Tests.IntakeRulesTests)() -> { passed, failed }

local Config = require(script.Parent.Parent.UnfairConfig)
local IntakeRules = require(script.Parent.Parent.IntakeRules)
local Harness = require(script.Parent.Harness)

local NOW = 1_800_000_000

local function payload(overrides: { [string]: any }?): any
	local p: any = {
		v = Config.PayloadVersion,
		runId = "run-1",
		partyId = "party-1",
		leaderUserId = 1,
		difficulty = "Hardcore",
		enraged = false,
		members = { { userId = 1, class = "Mage" }, { userId = 2, class = "Tank" } },
		issuedAt = NOW,
	}
	if overrides then
		for key, value in overrides do
			p[key] = value
		end
	end
	return p
end

local function expectKind(decision: IntakeRules.Decision, kind: string, label: string)
	Harness.eq(decision.kind, kind, `{label}: decision`)
end

local cases = Harness.new()

cases:add("a valid payload is accepted for each of the 5 difficulties", function()
	for _, difficulty in Config.Difficulties do
		local session = IntakeRules.newSession()
		local decision = IntakeRules.admit(payload({ difficulty = difficulty }), 1, NOW, true, session)
		expectKind(decision, "Accept", difficulty)
		Harness.eq((decision.payload :: any).difficulty, difficulty)
		Harness.eq(decision.firstArrival, true)
		Harness.eq(decision.requestedClass, "Mage")
	end
end)

cases:add("Enraged is carried through (not on Easy)", function()
	local decision = IntakeRules.admit(payload({ difficulty = "Hellaven", enraged = true }), 1, NOW, true, IntakeRules.newSession())
	expectKind(decision, "Accept", "enraged Hellaven")
	Harness.eq((decision.payload :: any).enraged, true)
end)

cases:add("Enraged on Easy is rejected when the lobby is required, falls back otherwise", function()
	local forged = payload({ difficulty = "Easy", enraged = true })
	expectKind(IntakeRules.admit(forged, 1, NOW, true, IntakeRules.newSession()), "Reject", "enforced")
	expectKind(IntakeRules.admit(forged, 1, NOW, false, IntakeRules.newSession()), "Fallback", "not enforced")
end)

cases:add("no payload: reject when required, plain behaviour when not", function()
	expectKind(IntakeRules.admit(nil, 1, NOW, true, IntakeRules.newSession()), "Reject", "enforced")
	expectKind(IntakeRules.admit(nil, 1, NOW, false, IntakeRules.newSession()), "Fallback", "not enforced")
end)

cases:add("junk payloads are rejected when required", function()
	local junk: { any } = { 5, "party", true, {}, { v = 1 } }
	for _, value in junk do
		expectKind(IntakeRules.admit(value, 1, NOW, true, IntakeRules.newSession()), "Reject", tostring(value))
	end
end)

cases:add("a stale payload is rejected, a fresh one accepted", function()
	local session = IntakeRules.newSession()
	expectKind(IntakeRules.admit(payload({ issuedAt = NOW - Config.PayloadMaxAgeSeconds - 1 }), 1, NOW, true, session), "Reject", "stale")
	expectKind(IntakeRules.admit(payload({ issuedAt = NOW - 30 }), 1, NOW, true, session), "Accept", "fresh")
end)

cases:add("a player who is not in the payload's members is rejected", function()
	expectKind(IntakeRules.admit(payload(), 999, NOW, true, IntakeRules.newSession()), "Reject", "stranger")
	expectKind(IntakeRules.admit(payload(), 999, NOW, false, IntakeRules.newSession()), "Fallback", "stranger, not enforced")
end)

cases:add("each member gets their own class from the payload", function()
	local session = IntakeRules.newSession()
	Harness.eq(IntakeRules.admit(payload(), 1, NOW, true, session).requestedClass, "Mage")
	Harness.eq(IntakeRules.admit(payload(), 2, NOW, true, session).requestedClass, "Tank")
end)

cases:add("the second member of the same run is accepted and is not the first arrival", function()
	local session = IntakeRules.newSession()
	local first = IntakeRules.admit(payload(), 1, NOW, true, session)
	IntakeRules.remember(session, (first.payload :: any).runId, 1, "Mage")
	local second = IntakeRules.admit(payload(), 2, NOW, true, session)
	expectKind(second, "Accept", "second member")
	Harness.eq(second.firstArrival, false)
end)

cases:add("a payload from a different run is rejected once a run is established", function()
	local session = IntakeRules.newSession()
	IntakeRules.remember(session, "run-1", 1, "Mage")
	expectKind(IntakeRules.admit(payload({ runId = "run-2" }), 2, NOW, true, session), "Reject", "other run, enforced")
	expectKind(IntakeRules.admit(payload({ runId = "run-2" }), 2, NOW, false, session), "Reject", "other run, not enforced")
end)

cases:add("a player already let in may rejoin without teleport data, a stranger may not", function()
	local session = IntakeRules.newSession()
	IntakeRules.remember(session, "run-1", 1, "Mage")
	local back = IntakeRules.admit(nil, 1, NOW, true, session)
	expectKind(back, "Accept", "reconnect")
	Harness.eq(back.reconnect, true)
	Harness.eq(back.requestedClass, "Mage")
	expectKind(IntakeRules.admit(nil, 2, NOW, true, session), "Reject", "stranger without data")
end)

cases:add("a reconnecting player with forged data is still rejected", function()
	local session = IntakeRules.newSession()
	IntakeRules.remember(session, "run-1", 1, "Mage")
	expectKind(IntakeRules.admit(payload({ difficulty = "Nightmare" }), 1, NOW, true, session), "Reject", "forged")
end)

cases:add("remember fixes the run id once and tracks every member", function()
	local session = IntakeRules.newSession()
	IntakeRules.remember(session, "run-1", 1, "Mage")
	IntakeRules.remember(session, "run-2", 2, "Tank")
	Harness.eq(session.runId, "run-1")
	Harness.eq(session.members[1], "Mage")
	Harness.eq(session.members[2], "Tank")
end)

cases:add("resolveClass keeps a valid class", function()
	local class, message = IntakeRules.resolveClass("Mage", true, false, nil, "Warrior")
	Harness.eq(class, "Mage")
	Harness.isNil(message)
	class, message = IntakeRules.resolveClass("Duelist", true, true, true, "Warrior")
	Harness.eq(class, "Duelist")
	Harness.isNil(message)
end)

cases:add("a forged class that does not exist falls back to the default with a message", function()
	local class, message = IntakeRules.resolveClass("GodMode", false, false, nil, "Warrior")
	Harness.eq(class, "Warrior")
	Harness.truthy(message ~= nil and #message > 0, "message")
end)

cases:add("a locked class falls back to the default, never the locked class", function()
	local class, message = IntakeRules.resolveClass("Duelist", true, true, false, "Warrior")
	Harness.eq(class, "Warrior")
	Harness.truthy(message ~= nil and string.find(message, "locked", 1, true) ~= nil, "says locked")
end)

cases:add("an unverifiable unlock also falls back, with its own message", function()
	local class, message = IntakeRules.resolveClass("Duelist", true, true, nil, "Warrior")
	Harness.eq(class, "Warrior")
	Harness.truthy(message ~= nil and string.find(message, "verify", 1, true) ~= nil, "says could not verify")
end)

cases:add("the unlock result is ignored for a class with no requirement", function()
	local class = IntakeRules.resolveClass("Mage", true, false, false, "Warrior")
	Harness.eq(class, "Mage")
end)

return function()
	return cases:run()
end

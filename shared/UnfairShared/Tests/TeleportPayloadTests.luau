--!strict
-- Plan task 6. Run: require(UnfairShared.Tests.TeleportPayloadTests)() -> { passed, failed }

local Config = require(script.Parent.Parent.UnfairConfig)
local TeleportPayload = require(script.Parent.Parent.TeleportPayload)
local Harness = require(script.Parent.Harness)

local NOW = 1_800_000_000

local function party(): TeleportPayload.Party
	return {
		partyId = "party-1",
		leaderUserId = 101,
		difficulty = "Hardcore",
		enraged = true,
		members = { { userId = 101, class = "Warrior" }, { userId = 202, class = "Mage" } },
	}
end

-- A raw payload as it would arrive over the wire (loosely typed on purpose, tests tamper with it).
local function raw(): any
	return {
		v = Config.PayloadVersion,
		runId = "run-1",
		partyId = "party-1",
		leaderUserId = 101,
		difficulty = "Hardcore",
		enraged = true,
		members = { { userId = 101, class = "Warrior" }, { userId = 202, class = "Mage" } },
		issuedAt = NOW,
	}
end

local function rejects(payload: any, expectedFragment: string, options: TeleportPayload.ValidateOptions?)
	local out, err = TeleportPayload.validate(payload, options or { now = NOW })
	Harness.isNil(out, "payload should be rejected")
	Harness.truthy(err ~= nil and string.find(err, expectedFragment, 1, true) ~= nil, `error "{err}" should mention "{expectedFragment}"`)
end

local function members(count: number): { { userId: number, class: string } }
	local list = {}
	for i = 1, count do
		list[i] = { userId = 100 + i, class = "Warrior" }
	end
	return list
end

local cases = Harness.new()

cases:add("valid payload is accepted and returned as a copy", function()
	local input = raw()
	local out, err = TeleportPayload.validate(input, { now = NOW })
	Harness.isNil(err)
	Harness.truthy(out ~= nil, "payload accepted")
	local payload = out :: TeleportPayload.Payload
	Harness.eq(payload.runId, "run-1")
	Harness.eq(payload.difficulty, "Hardcore")
	Harness.eq(payload.enraged, true)
	Harness.eq(#payload.members, 2)
	Harness.eq(payload.members[2].class, "Mage")
	Harness.truthy(payload ~= input and payload.members ~= input.members, "result must not alias the input")
end)

cases:add("unknown fields are dropped", function()
	local input = raw()
	input.admin = true
	input.members[1].isAdmin = true
	local out = TeleportPayload.validate(input, { now = NOW }) :: any
	Harness.truthy(out ~= nil, "accepted")
	Harness.isNil(out.admin)
	Harness.isNil(out.members[1].isAdmin)
end)

cases:add("every configured difficulty is accepted, Enraged on all but Easy", function()
	for _, difficulty in Config.Difficulties do
		local input = raw()
		input.difficulty = difficulty
		input.enraged = false
		Harness.truthy(TeleportPayload.validate(input, { now = NOW }) ~= nil, `{difficulty} not enraged`)
		if difficulty ~= "Easy" then
			input.enraged = true
			Harness.truthy(TeleportPayload.validate(input, { now = NOW }) ~= nil, `{difficulty} enraged`)
		end
	end
end)

cases:add("non-table input is rejected", function()
	rejects(nil, "not a table")
	rejects(5, "not a table")
	rejects("payload", "not a table")
	rejects(true, "not a table")
	rejects(function() end, "not a table")
end)

cases:add("wrong or missing version is rejected", function()
	local input = raw()
	input.v = Config.PayloadVersion + 1
	rejects(input, "version")
	input.v = nil
	rejects(input, "version")
	input.v = tostring(Config.PayloadVersion)
	rejects(input, "version")
end)

cases:add("unknown or malformed difficulty is rejected", function()
	local badValues: { any } = { "Impossible", "easy", "", 3, true }
	for _, bad in badValues do
		local input = raw()
		input.difficulty = bad
		rejects(input, "difficulty")
	end
	local input = raw()
	input.difficulty = nil
	rejects(input, "difficulty")
end)

cases:add("Enraged on Easy is rejected", function()
	local input = raw()
	input.difficulty = "Easy"
	input.enraged = true
	rejects(input, "Easy")
end)

cases:add("enraged must be a real boolean", function()
	local badValues: { any } = { "true", 1, 0 }
	for _, bad in badValues do
		local input = raw()
		input.enraged = bad
		rejects(input, "enraged")
	end
	local input = raw()
	input.enraged = nil
	rejects(input, "enraged")
end)

cases:add("member count must be 1..PartyMax", function()
	local input = raw()
	input.members = {}
	rejects(input, "member count")
	input.members = members(Config.PartyMax + 1)
	input.leaderUserId = 101
	rejects(input, "member count")
	input.members = members(Config.PartyMax)
	Harness.truthy(TeleportPayload.validate(input, { now = NOW }) ~= nil, "full party accepted")
	input.members = members(1)
	Harness.truthy(TeleportPayload.validate(input, { now = NOW }) ~= nil, "solo party accepted")
end)

cases:add("duplicate members are rejected", function()
	local input = raw()
	input.members = { { userId = 101, class = "Warrior" }, { userId = 101, class = "Mage" } }
	rejects(input, "duplicate")
end)

cases:add("malformed members are rejected", function()
	local input = raw()
	input.members = "everyone"
	rejects(input, "members")

	input = raw()
	input.members = { [1] = { userId = 101, class = "Warrior" }, [3] = { userId = 202, class = "Mage" } }
	rejects(input, "array")

	input = raw()
	input.members = { a = { userId = 101, class = "Warrior" } }
	rejects(input, "array")

	input = raw()
	input.members = { 101, 202 }
	rejects(input, "member is not a table")

	input = raw()
	input.members[2].userId = "202"
	rejects(input, "userId")

	input = raw()
	input.members[2].class = ""
	rejects(input, "class")

	input = raw()
	input.members[2].class = string.rep("x", 33)
	rejects(input, "class")
end)

cases:add("bad user ids are rejected (fraction, NaN, infinity, zero, negative)", function()
	for _, bad in { 1.5, 0 / 0, math.huge, 0, -5 } do
		local input = raw()
		input.members[2].userId = bad
		rejects(input, "userId")
	end
	local input = raw()
	input.leaderUserId = 0 / 0
	rejects(input, "leaderUserId")
end)

cases:add("leader must be one of the members", function()
	local input = raw()
	input.leaderUserId = 999
	rejects(input, "leader")
end)

cases:add("arriving player must be a member when checked", function()
	Harness.truthy(TeleportPayload.validate(raw(), { now = NOW, arrivingUserId = 202 }) ~= nil, "member arrives")
	rejects(raw(), "player is not a member", { now = NOW, arrivingUserId = 999 })
end)

cases:add("stale payloads are rejected, the edge is accepted", function()
	local input = raw()
	input.issuedAt = NOW - Config.PayloadMaxAgeSeconds
	Harness.truthy(TeleportPayload.validate(input, { now = NOW }) ~= nil, "exactly at the limit")
	input.issuedAt = NOW - Config.PayloadMaxAgeSeconds - 1
	rejects(input, "expired")
end)

cases:add("payloads from the far future are rejected, small clock skew is fine", function()
	local input = raw()
	input.issuedAt = NOW + 30
	Harness.truthy(TeleportPayload.validate(input, { now = NOW }) ~= nil, "30 s skew")
	input.issuedAt = NOW + 3600
	rejects(input, "future")
end)

cases:add("bad issuedAt and ids are rejected", function()
	local input = raw()
	input.issuedAt = "now"
	rejects(input, "issuedAt")
	input.issuedAt = 0 / 0
	rejects(input, "issuedAt")

	input = raw()
	input.runId = ""
	rejects(input, "runId")
	input.runId = string.rep("r", 65)
	rejects(input, "runId")

	input = raw()
	input.partyId = 7
	rejects(input, "partyId")
end)

cases:add("build produces a payload that validates, with the party's settings", function()
	local payload, err = TeleportPayload.build(party(), "run-9", NOW)
	Harness.isNil(err)
	local built = payload :: TeleportPayload.Payload
	Harness.eq(built.v, Config.PayloadVersion)
	Harness.eq(built.runId, "run-9")
	Harness.eq(built.partyId, "party-1")
	Harness.eq(built.leaderUserId, 101)
	Harness.eq(built.difficulty, "Hardcore")
	Harness.eq(built.enraged, true)
	Harness.eq(built.issuedAt, NOW)
	Harness.eq(#built.members, 2)
	Harness.truthy(TeleportPayload.validate(built, { now = NOW + 5 }) ~= nil, "round trip")
end)

cases:add("build never emits Enraged on Easy", function()
	local input = party()
	input.difficulty = "Easy"
	input.enraged = true
	local payload, err = TeleportPayload.build(input, "run-9", NOW)
	Harness.isNil(payload)
	Harness.truthy(err ~= nil and string.find(err, "Easy", 1, true) ~= nil, "reason mentions Easy")
	input.enraged = false
	Harness.truthy(TeleportPayload.build(input, "run-9", NOW) ~= nil, "Easy without Enraged builds")
end)

cases:add("build rejects 0 and 7 members and a missing runId", function()
	local input = party()
	input.members = {}
	Harness.isNil(TeleportPayload.build(input, "run-9", NOW))
	input.members = members(Config.PartyMax + 1)
	Harness.isNil(TeleportPayload.build(input, "run-9", NOW))
	Harness.isNil(TeleportPayload.build(party(), "", NOW))
end)

return function()
	return cases:run()
end

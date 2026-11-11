--!strict
-- Plan task 17 (pure part). Run: require(UnfairShared.Tests.LaunchPlanTests)() -> { passed, failed }

local Config = require(script.Parent.Parent.UnfairConfig)
local LaunchPlan = require(script.Parent.Parent.LaunchPlan)
local TeleportPayload = require(script.Parent.Parent.TeleportPayload)
local Harness = require(script.Parent.Harness)

local NOW = 1_800_000_000

local function party(): TeleportPayload.Party
	return {
		partyId = "party-1",
		leaderUserId = 1,
		difficulty = "TrueHardcore",
		enraged = true,
		members = { { userId = 1, class = "Warrior" }, { userId = 2, class = "Mage" }, { userId = 3, class = "Tank" } },
	}
end

local function everyone(): boolean
	return true
end

local function snapshotClass(): string?
	return nil
end

local cases = Harness.new()

cases:add("everyone present: the payload carries the room's settings and members in order", function()
	local result = LaunchPlan.make(party(), everyone, snapshotClass, "run-1", NOW) :: LaunchPlan.Result
	Harness.truthy(result ~= nil, "plan made")
	Harness.eq(result.payload.difficulty, "TrueHardcore")
	Harness.eq(result.payload.enraged, true)
	Harness.eq(result.payload.leaderUserId, 1)
	Harness.eq(result.payload.runId, "run-1")
	Harness.eq(#result.payload.members, 3)
	Harness.eq(#result.userIds, 3)
	Harness.eq(result.userIds[1], 1)
	Harness.eq(result.userIds[3], 3)
end)

cases:add("the payload is valid for the boss place", function()
	local result = LaunchPlan.make(party(), everyone, snapshotClass, "run-1", NOW) :: LaunchPlan.Result
	Harness.truthy(TeleportPayload.validate(result.payload, { now = NOW + 1, arrivingUserId = 2 }) ~= nil, "validates")
end)

cases:add("players who left are dropped", function()
	local result = LaunchPlan.make(party(), function(id)
		return id ~= 2
	end, snapshotClass, "run-1", NOW) :: LaunchPlan.Result
	Harness.eq(#result.payload.members, 2)
	Harness.eq(result.userIds[1], 1)
	Harness.eq(result.userIds[2], 3)
end)

cases:add("if the leader left, the first remaining member leads", function()
	local result = LaunchPlan.make(party(), function(id)
		return id ~= 1
	end, snapshotClass, "run-1", NOW) :: LaunchPlan.Result
	Harness.eq(result.payload.leaderUserId, 2)
	Harness.eq(#result.payload.members, 2)
end)

cases:add("classes come from the server's record, not the snapshot", function()
	local result = LaunchPlan.make(party(), everyone, function(id)
		if id == 2 then
			return "Gambler"
		end
		return nil
	end, "run-1", NOW) :: LaunchPlan.Result
	Harness.eq(result.payload.members[1].class, "Warrior", "no record: the snapshot value is kept")
	Harness.eq(result.payload.members[2].class, "Gambler")
	Harness.eq(result.payload.members[3].class, "Tank")
end)

cases:add("nobody left is an error", function()
	local result, err = LaunchPlan.make(party(), function()
		return false
	end, snapshotClass, "run-1", NOW)
	Harness.isNil(result)
	Harness.truthy(err ~= nil and string.find(err, "nobody", 1, true) ~= nil, "reason given")
end)

cases:add("a solo party launches", function()
	local result = LaunchPlan.make(party(), function(id)
		return id == 3
	end, snapshotClass, "run-1", NOW) :: LaunchPlan.Result
	Harness.eq(#result.payload.members, 1)
	Harness.eq(result.payload.leaderUserId, 3)
end)

cases:add("Easy with Enraged is refused, Easy without it launches", function()
	local input = party()
	input.difficulty = "Easy"
	local result, err = LaunchPlan.make(input, everyone, snapshotClass, "run-1", NOW)
	Harness.isNil(result)
	Harness.truthy(err ~= nil and string.find(err, "Easy", 1, true) ~= nil, "reason mentions Easy")
	input.enraged = false
	Harness.truthy(LaunchPlan.make(input, everyone, snapshotClass, "run-1", NOW) ~= nil, "Easy plain launches")
end)

cases:add("a full party of PartyMax launches", function()
	local input = party()
	input.members = {}
	for id = 1, Config.PartyMax do
		table.insert(input.members, { userId = id, class = "Warrior" })
	end
	local result = LaunchPlan.make(input, everyone, snapshotClass, "run-1", NOW) :: LaunchPlan.Result
	Harness.eq(#result.payload.members, Config.PartyMax)
end)

cases:add("the input party is not modified", function()
	local input = party()
	LaunchPlan.make(input, function(id)
		return id ~= 1
	end, function()
		return "Gambler"
	end, "run-1", NOW)
	Harness.eq(#input.members, 3)
	Harness.eq(input.leaderUserId, 1)
	Harness.eq(input.members[2].class, "Mage")
end)

return function()
	return cases:run()
end

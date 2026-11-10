--!strict
-- Plan task 13 (pure part). Run: require(UnfairShared.Tests.UnlockCheckTests)() -> { passed, failed }

local UnlockCheck = require(script.Parent.Parent.UnlockCheck)
local Harness = require(script.Parent.Harness)

local classes = { Warrior = {}, Duelist = {}, Disorderer = {}, Twinblade = {} }
local unlocks: { [string]: UnlockCheck.Entry } = {
	Duelist = { Kind = "Badge", Id = 111, Hint = "Beat True Hardcore to unlock." },
	Twinblade = { Kind = "Badge", Id = 222, Hint = "Beat Hellaven to unlock." },
	Disorderer = { Kind = "GamePass", Id = 333, Hint = "Game pass class - 25 Robux." },
}

type Script = { badges: { [number]: boolean }?, passes: { [number]: boolean }?, failFirst: number? }

-- Fake lookups. `failFirst` = the first N lookups fail (could not reach the service).
local function deps(setup: Script?, extra: { bypass: boolean?, present: boolean? }?): UnlockCheck.Deps & { calls: number, waits: number }
	local state: any = setup or {}
	local remainingFailures = state.failFirst or 0
	local d: any = { calls = 0, waits = 0 }
	local function lookup(owned: { [number]: boolean }?, id: number): (boolean, boolean)
		d.calls += 1
		if remainingFailures > 0 then
			remainingFailures -= 1
			return false, false
		end
		return true, owned ~= nil and owned[id] == true
	end
	d.hasBadge = function(id: number)
		return lookup(state.badges, id)
	end
	d.hasPass = function(id: number)
		return lookup(state.passes, id)
	end
	d.wait = function()
		d.waits += 1
	end
	if extra and extra.bypass then
		d.bypass = function()
			return true
		end
	end
	if extra and extra.present == false then
		d.isPresent = function()
			return false
		end
	end
	return d
end

local cases = Harness.new()

cases:add("a class with no unlock entry is open to everybody", function()
	local result = UnlockCheck.pick("Warrior", classes, unlocks, deps())
	Harness.truthy(result ~= nil and result.ok, "Warrior is free")
	Harness.eq((result :: UnlockCheck.PickResult).message, "")
end)

cases:add("picking a class that does not exist does nothing", function()
	Harness.isNil(UnlockCheck.pick("Wizard", classes, unlocks, deps()))
	Harness.isNil(UnlockCheck.pick(nil, classes, unlocks, deps()))
	Harness.isNil(UnlockCheck.pick(42, classes, unlocks, deps()))
	Harness.isNil(UnlockCheck.pick({}, classes, unlocks, deps()))
end)

cases:add("an owned badge unlocks the class", function()
	local result = UnlockCheck.pick("Duelist", classes, unlocks, deps({ badges = { [111] = true } }))
	Harness.truthy(result ~= nil and result.ok, "badge owner may pick")
end)

cases:add("a missing badge is locked and shows the hint", function()
	local result = UnlockCheck.pick("Duelist", classes, unlocks, deps({ badges = {} })) :: UnlockCheck.PickResult
	Harness.eq(result.ok, false)
	Harness.eq(result.message, "Locked. Beat True Hardcore to unlock.")
end)

cases:add("a game pass class needs the pass", function()
	Harness.truthy((UnlockCheck.pick("Disorderer", classes, unlocks, deps({ passes = { [333] = true } })) :: UnlockCheck.PickResult).ok, "pass owner")
	local result = UnlockCheck.pick("Disorderer", classes, unlocks, deps({ passes = {} })) :: UnlockCheck.PickResult
	Harness.eq(result.ok, false)
	Harness.eq(result.message, "Locked. Game pass class - 25 Robux.")
end)

cases:add("a badge is not mistaken for a pass id and the other way round", function()
	local result = UnlockCheck.pick("Disorderer", classes, unlocks, deps({ badges = { [333] = true } })) :: UnlockCheck.PickResult
	Harness.eq(result.ok, false)
end)

cases:add("a game pass that is not set up (Id 0) can never be owned", function()
	local entry: UnlockCheck.Entry = { Kind = "GamePass", Id = 0, Hint = "Not on sale yet." }
	local probe = deps({ passes = { [0] = true } })
	Harness.eq(UnlockCheck.resolve(entry, probe, 2), false)
	Harness.eq(probe.calls, 0, "no lookup for an unset pass")
end)

cases:add("a failed lookup gives the retry message, never an unlock", function()
	local result = UnlockCheck.pick("Duelist", classes, unlocks, deps({ badges = { [111] = true }, failFirst = 99 })) :: UnlockCheck.PickResult
	Harness.eq(result.ok, false)
	Harness.eq(result.message, "Could not verify your unlock right now. Try again in a moment.")
end)

cases:add("one failed lookup is retried and then succeeds", function()
	local probe = deps({ badges = { [111] = true }, failFirst = 1 })
	local result = UnlockCheck.pick("Duelist", classes, unlocks, probe) :: UnlockCheck.PickResult
	Harness.truthy(result.ok, "second attempt works")
	Harness.eq(probe.calls, 2)
	Harness.eq(probe.waits, 1)
end)

cases:add("retries are limited to the attempt count", function()
	local probe = deps({ badges = { [111] = true }, failFirst = 99 })
	Harness.isNil(UnlockCheck.resolve(unlocks.Duelist, probe, 3))
	Harness.eq(probe.calls, 3)
	Harness.eq(probe.waits, 2)
end)

cases:add("the bypass (Studio or the creator) unlocks without any lookup", function()
	local probe = deps({ badges = {} }, { bypass = true })
	Harness.truthy((UnlockCheck.pick("Duelist", classes, unlocks, probe) :: UnlockCheck.PickResult).ok, "bypass")
	Harness.eq(probe.calls, 0)
end)

cases:add("a player who left gives nil and stops looking", function()
	local probe = deps({ badges = { [111] = true } }, { present = false })
	Harness.isNil(UnlockCheck.resolve(unlocks.Duelist, probe, 2))
	Harness.eq(probe.calls, 0)
end)

cases:add("an unknown entry kind is treated as unverifiable, not as open", function()
	local entry: UnlockCheck.Entry = { Kind = "Mystery", Id = 1 }
	Harness.isNil(UnlockCheck.resolve(entry, deps(), 1))
end)

local cashEntry: UnlockCheck.Entry = { Kind = "Cash", Id = 0, ClassId = "Supporter", Price = 100, Hint = "Buy in the shop for 100 cash." }

local function cashDeps(worked: boolean, owned: boolean): UnlockCheck.Deps
	local d: any = deps()
	d.hasBought = function(classId: string)
		Harness.eq(classId, "Supporter")
		return worked, owned
	end
	return d
end

cases:add("a bought class is unlocked, an unbought one is locked", function()
	Harness.eq(UnlockCheck.resolve(cashEntry, cashDeps(true, true), 1), true)
	Harness.eq(UnlockCheck.resolve(cashEntry, cashDeps(true, false), 1), false)
end)

cases:add("a cash class fails closed when the save cannot be read", function()
	Harness.isNil(UnlockCheck.resolve(cashEntry, cashDeps(false, true), 1))
	Harness.isNil(UnlockCheck.resolve(cashEntry, deps(), 1), "no lookup supplied")
end)

return function()
	return cases:run()
end

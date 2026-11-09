--!strict
-- Plan task 21 (pure half). Run: require(UnfairShared.Tests.CashLedgerTests)() -> { passed, failed }

local Ledger = require(script.Parent.Parent.CashLedger)
local Harness = require(script.Parent.Harness)

local cases = Harness.new()

cases:add("key is user_<id>", function()
	Harness.eq(Ledger.key(12345), "user_12345")
end)

cases:add("balance: missing, junk and negative records count as 0", function()
	Harness.eq(Ledger.balance(nil), 0)
	Harness.eq(Ledger.balance("50"), 0)
	Harness.eq(Ledger.balance({}), 0)
	Harness.eq(Ledger.balance({ Cash = "50" }), 0)
	Harness.eq(Ledger.balance({ Cash = -5 }), 0)
	Harness.eq(Ledger.balance({ Cash = 0 / 0 }), 0)
	Harness.eq(Ledger.balance({ Cash = math.huge }), 0)
	Harness.eq(Ledger.balance({ Cash = 40.9 }), 40)
	Harness.eq(Ledger.balance({ Cash = 70 }), 70)
end)

cases:add("apply to no record starts a record with the amount", function()
	local record, applied = Ledger.apply(nil, "run-1", 35)
	Harness.truthy(applied)
	Harness.eq(Ledger.balance(record), 35)
	Harness.truthy(Ledger.hasPaid(record, "run-1"))
end)

cases:add("apply adds to the existing balance and keeps other fields", function()
	local old = { Cash = 100, Shop = { Owned = { "Sword" } } }
	local record, applied = Ledger.apply(old, "run-2", 25)
	Harness.truthy(applied)
	Harness.eq(Ledger.balance(record), 125)
	Harness.eq(record.Shop.Owned[1], "Sword")
end)

cases:add("apply never changes the record it was given", function()
	local old = { Cash = 10, PaidRuns = { "a" } }
	Ledger.apply(old, "b", 5)
	Harness.eq(old.Cash, 10)
	Harness.eq(#old.PaidRuns, 1)
end)

cases:add("the same run is paid once, however often it is applied", function()
	local record, first = Ledger.apply(nil, "run-3", 50)
	Harness.truthy(first)
	local again, second = Ledger.apply(record, "run-3", 50)
	Harness.eq(second, false)
	Harness.eq(Ledger.balance(again), 50)
	local third, applied = Ledger.apply(again, "run-3", 999)
	Harness.eq(applied, false)
	Harness.eq(Ledger.balance(third), 50)
end)

cases:add("different runs each pay", function()
	local record = Ledger.apply(nil, "a", 5)
	record = Ledger.apply(record, "b", 15)
	record = Ledger.apply(record, "c", 25)
	Harness.eq(Ledger.balance(record), 45)
end)

cases:add("only the last RemembersRuns run ids are kept", function()
	local record: any = nil
	for i = 1, Ledger.RemembersRuns + 3 do
		record = Ledger.apply(record, `run-{i}`, 1)
	end
	Harness.eq(#record.PaidRuns, Ledger.RemembersRuns)
	Harness.eq(record.PaidRuns[1], "run-4")
	Harness.eq(Ledger.hasPaid(record, "run-1"), false)
	Harness.truthy(Ledger.hasPaid(record, `run-{Ledger.RemembersRuns + 3}`))
	Harness.eq(Ledger.balance(record), Ledger.RemembersRuns + 3)
end)

cases:add("bad run ids are refused and change nothing", function()
	local bad: { any } = { "", 5, true, {} }
	for _, runId in bad do
		local record, applied = Ledger.apply({ Cash = 7 }, runId, 10)
		Harness.eq(applied, false, `runId {tostring(runId)}`)
		Harness.eq(Ledger.balance(record), 7)
	end
	local _, nilRun = Ledger.apply({ Cash = 7 }, nil, 10)
	Harness.eq(nilRun, false)
end)

cases:add("bad amounts are refused and change nothing", function()
	local bad: { any } = { 0, -5, 2.5, "10", true, {}, 0 / 0, math.huge, Ledger.MaxSingleAward + 1 }
	for _, amount in bad do
		local record, applied = Ledger.apply({ Cash = 7 }, "run-x", amount)
		Harness.eq(applied, false, `amount {tostring(amount)}`)
		Harness.eq(Ledger.balance(record), 7)
		Harness.eq(Ledger.hasPaid(record, "run-x"), false)
	end
	local _, nilAmount = Ledger.apply({ Cash = 7 }, "run-x", nil)
	Harness.eq(nilAmount, false)
end)

cases:add("a damaged record is repaired when a payout is applied", function()
	local junkRuns: { any } = { 1, "ok", {} }
	local damaged: any = { Cash = "lots", PaidRuns = junkRuns }
	local record, applied = Ledger.apply(damaged, "run-y", 5)
	Harness.truthy(applied)
	Harness.eq(Ledger.balance(record), 5)
	Harness.eq(#record.PaidRuns, 2)
	Harness.eq(record.PaidRuns[1], "ok")
end)

cases:add("hasPaid is false for junk input", function()
	Harness.eq(Ledger.hasPaid(nil, "a"), false)
	Harness.eq(Ledger.hasPaid({}, "a"), false)
	Harness.eq(Ledger.hasPaid({ PaidRuns = "a" }, "a"), false)
	Harness.eq(Ledger.hasPaid({ PaidRuns = { "a" } }, 5), false)
end)

return function()
	return cases:run()
end

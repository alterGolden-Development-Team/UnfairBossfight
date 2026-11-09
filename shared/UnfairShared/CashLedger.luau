--!strict
-- The cash record both places agree on (spec 6.3, plan tasks 21-22). Pure: no DataStore here, only the rules for
-- reading a stored record and for adding one win to it, so they can be tested anywhere.
--
-- Stored under DataStore UnfairConfig.CashStore(...), key `user_<userId>`:
--   { Cash = <whole number>, PaidRuns = { <runId>, ... last few } }   (other fields, e.g. the future shop's, are kept)
-- `PaidRuns` makes a payout idempotent: UpdateAsync can run its callback again after a failed or lost write, and a
-- run that is already in the list is never added a second time.

local Ledger = {}

Ledger.RemembersRuns = 10 -- how many recent runIds the record keeps
Ledger.MaxSingleAward = 100000 -- anything larger is treated as a bug, not a payout

function Ledger.key(userId: number): string
	return `user_{userId}`
end

local function wholeNonNegative(value: any): number
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return 0
	end
	return math.floor(value)
end

-- Cash of a stored record. Anything that is not a record with a usable Cash field counts as 0.
function Ledger.balance(record: any): number
	if type(record) ~= "table" then
		return 0
	end
	return wholeNonNegative(record.Cash)
end

-- Whether this run was already paid into this record.
function Ledger.hasPaid(record: any, runId: any): boolean
	if type(record) ~= "table" or type(record.PaidRuns) ~= "table" or type(runId) ~= "string" then
		return false
	end
	return table.find(record.PaidRuns, runId) ~= nil
end

-- Returns (new record, applied). `record` itself is never changed. When `applied` is false the amount, the run id or the
-- record's history ruled the payout out and the returned record is only the cleaned-up copy of the old one.
function Ledger.apply(record: any, runId: any, amount: any): ({ [string]: any }, boolean)
	local out: { [string]: any } = {}
	if type(record) == "table" then
		for key, value in record do
			out[key] = value
		end
	end
	out.Cash = wholeNonNegative(out.Cash)

	local runs: { string } = {}
	if type(out.PaidRuns) == "table" then
		for _, id in out.PaidRuns do
			if type(id) == "string" then
				table.insert(runs, id)
			end
		end
	end
	out.PaidRuns = runs

	if type(runId) ~= "string" or runId == "" then
		return out, false
	end
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount ~= math.floor(amount) or amount > Ledger.MaxSingleAward then
		return out, false
	end
	if table.find(runs, runId) then
		return out, false
	end

	out.Cash += amount
	table.insert(runs, runId)
	while #runs > Ledger.RemembersRuns do
		table.remove(runs, 1)
	end
	return out, true
end

return Ledger

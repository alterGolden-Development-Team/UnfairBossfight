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

-- Shop half of the record: Owned = { Classes = { id, ... }, Orbs = { id, ... } }, EquippedOrb = id
-- Only the lobby server spends; everything goes through UpdateAsync with these pure functions, so a retried write cannot
-- charge twice (the item is already owned the second time) and a balance can never go negative.

local KINDS = { Classes = true, Orbs = true }

local function ownedList(record: any, kind: string): { string }
	if type(record) ~= "table" or type(record.Owned) ~= "table" or type(record.Owned[kind]) ~= "table" then
		return {}
	end
	local list: { string } = {}
	for _, id in record.Owned[kind] do
		if type(id) == "string" then
			table.insert(list, id)
		end
	end
	return list
end

function Ledger.owns(record: any, kind: string, id: any): boolean
	return KINDS[kind] == true and type(id) == "string" and table.find(ownedList(record, kind), id) ~= nil
end

-- Returns (new record, result). result: "Bought" | "AlreadyOwned" | "TooPoor" | "Invalid". Only "Bought" changes anything.
function Ledger.purchase(record: any, kind: any, id: any, price: any): ({ [string]: any }, string)
	local out: { [string]: any } = {}
	if type(record) == "table" then
		for key, value in record do
			out[key] = value
		end
	end
	out.Cash = wholeNonNegative(out.Cash)
	if type(kind) ~= "string" or not KINDS[kind] or type(id) ~= "string" or id == "" then
		return out, "Invalid"
	end
	if type(price) ~= "number" or price ~= price or price <= 0 or price ~= math.floor(price) or price > Ledger.MaxSingleAward then
		return out, "Invalid"
	end
	if Ledger.owns(out, kind, id) then
		return out, "AlreadyOwned"
	end
	if out.Cash < price then
		return out, "TooPoor"
	end
	local owned = { Classes = ownedList(out, "Classes"), Orbs = ownedList(out, "Orbs") }
	table.insert(owned[kind], id)
	out.Owned = owned
	out.Cash -= price
	return out, "Bought"
end

-- A class given for free (the Reality Disorderer quest). Returns (new record, applied); applied is false when it was already owned.
function Ledger.grantClass(record: any, id: any): ({ [string]: any }, boolean)
	local out: { [string]: any } = {}
	if type(record) == "table" then
		for key, value in record do
			out[key] = value
		end
	end
	if type(id) ~= "string" or id == "" or Ledger.owns(out, "Classes", id) then
		return out, false
	end
	local owned = { Classes = ownedList(out, "Classes"), Orbs = ownedList(out, "Orbs") }
	table.insert(owned.Classes, id)
	out.Owned = owned
	return out, true
end

-- Inventory: Items = { [itemId] = count }. Items are found in the world (the Reality Orb), never bought or sent by a client.
Ledger.MaxItemCount = 99

function Ledger.itemCount(record: any, id: any): number
	if type(record) ~= "table" or type(record.Items) ~= "table" or type(id) ~= "string" then
		return 0
	end
	return wholeNonNegative(record.Items[id])
end

-- Every item the record holds, as { [id] = count } (only counts above 0).
function Ledger.items(record: any): { [string]: number }
	local out: { [string]: number } = {}
	if type(record) == "table" and type(record.Items) == "table" then
		for id, count in record.Items do
			local n = type(id) == "string" and wholeNonNegative(count) or 0
			if n > 0 then
				out[id] = n
			end
		end
	end
	return out
end

local function withItems(record: any): { [string]: any }
	local out: { [string]: any } = {}
	if type(record) == "table" then
		for key, value in record do
			out[key] = value
		end
	end
	out.Items = Ledger.items(record)
	return out
end

-- Returns (new record, applied). `limit` caps how many of this item one record may hold (default MaxItemCount).
function Ledger.addItem(record: any, id: any, count: any, limit: number?): ({ [string]: any }, boolean)
	local out = withItems(record)
	if type(id) ~= "string" or id == "" or type(count) ~= "number" or count ~= math.floor(count) or count <= 0 then
		return out, false
	end
	local have = out.Items[id] or 0
	local cap = math.min(limit or Ledger.MaxItemCount, Ledger.MaxItemCount)
	if have >= cap then
		return out, false
	end
	out.Items[id] = math.min(cap, have + count)
	return out, true
end

-- Takes one of an item. Returns (new record, applied); applied is false when there was none.
function Ledger.takeItem(record: any, id: any): ({ [string]: any }, boolean)
	local out = withItems(record)
	local have = type(id) == "string" and out.Items[id] or 0
	if not have or have <= 0 then
		return out, false
	end
	out.Items[id] = have > 1 and have - 1 or nil
	return out, true
end

-- The orb to use, or nil. An equipped orb the record does not own counts as none.
function Ledger.equippedOrb(record: any): string?
	if type(record) ~= "table" then
		return nil
	end
	local id = record.EquippedOrb
	if type(id) == "string" and Ledger.owns(record, "Orbs", id) then
		return id
	end
	return nil
end

-- orbId = nil takes the orb off. Returns (new record, applied).
function Ledger.equip(record: any, orbId: any): ({ [string]: any }, boolean)
	local out: { [string]: any } = {}
	if type(record) == "table" then
		for key, value in record do
			out[key] = value
		end
	end
	if orbId == nil then
		out.EquippedOrb = nil
		return out, true
	end
	if not Ledger.owns(out, "Orbs", orbId) then
		return out, false
	end
	out.EquippedOrb = orbId
	return out, true
end

return Ledger

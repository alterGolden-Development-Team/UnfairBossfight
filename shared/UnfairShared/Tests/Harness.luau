--!strict
-- Tiny test runner for the pure modules. A test file builds a list of cases and returns a function that runs them:
--   local cases = Harness.new()
--   cases:add("name", function() Harness.eq(a, b) end)
--   return function() return cases:run() end
-- Run from Studio (execute_luau): `local r = require(...Tests.PartyStateTests)(); print(r.passed, #r.failed)`.

local Harness = {}

export type Result = { passed: number, failed: { string } }
export type Cases = {
	list: { { name: string, fn: () -> () } },
	add: (self: Cases, name: string, fn: () -> ()) -> (),
	run: (self: Cases) -> Result,
}

local Cases = {}
Cases.__index = Cases

function Cases.add(self: Cases, name: string, fn: () -> ())
	table.insert(self.list, { name = name, fn = fn })
end

function Cases.run(self: Cases): Result
	local result: Result = { passed = 0, failed = {} }
	for _, case in self.list do
		local outcome = table.pack(pcall(case.fn))
		if outcome[1] then
			result.passed += 1
		else
			table.insert(result.failed, `{case.name}: {tostring(outcome[2])}`)
		end
	end
	return result
end

function Harness.new(): Cases
	return setmetatable({ list = {} }, Cases) :: any
end

function Harness.eq(actual: any, expected: any, label: string?)
	if actual ~= expected then
		error(`{label or "values differ"}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
	end
end

function Harness.isNil(actual: any, label: string?)
	if actual ~= nil then
		error(`{label or "expected nil"}: got {tostring(actual)}`, 2)
	end
end

function Harness.truthy(actual: any, label: string?)
	if not actual then
		error(label or "expected a truthy value", 2)
	end
end

return Harness

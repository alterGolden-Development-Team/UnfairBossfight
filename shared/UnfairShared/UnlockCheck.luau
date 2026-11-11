--!strict
-- Who may pick a class (same rules as the boss place's ClassService.CheckUnlock), as pure logic.
-- The Roblox lookups (BadgeService, MarketplaceService, "is this the creator or Studio") are passed in as `deps`,
-- so the rules are tested without any service. The lobby's ClassPickService supplies the real ones.
--
-- Result of an ownership question is tri-state: true = owns it, false = does not, nil = could not find out.
-- A failed lookup never unlocks anything (fail closed).

export type Entry = { Kind: string, Id: number, Hint: string?, ClassId: string?, Price: number?, Quest: boolean? }

export type Deps = {
	bypass: (() -> boolean)?, -- true for Studio / the experience creator / nothing to check
	hasBadge: (badgeId: number) -> (boolean, boolean), -- (lookup worked, owns it)
	hasPass: (passId: number) -> (boolean, boolean),
	hasBought: ((classId: string) -> (boolean, boolean))?, -- cash classes: (lookup worked, owns it)
	isPresent: (() -> boolean)?, -- false once the player has left, stops the retries
	wait: ((seconds: number) -> ())?, -- between retries
}

export type PickResult = { ok: boolean, message: string }

local UnlockCheck = {}

local RETRY_MESSAGE = "Could not verify your unlock right now. Try again in a moment."

local function owns(entry: Entry, deps: Deps): boolean?
	if entry.Kind == "Badge" then
		local worked, has = deps.hasBadge(entry.Id)
		if worked then
			return has == true
		end
	elseif entry.Kind == "GamePass" then
		-- a pass class that can also be earned by a quest: the saved record says so
		if entry.Quest and deps.hasBought and type(entry.ClassId) == "string" then
			local worked, has = deps.hasBought(entry.ClassId)
			if worked and has then
				return true
			end
		end
		if type(entry.Id) ~= "number" or entry.Id <= 0 then
			return false -- a pass that is not set up yet cannot be owned
		end
		local worked, has = deps.hasPass(entry.Id)
		if worked then
			return has == true
		end
	elseif entry.Kind == "Cash" then
		if not deps.hasBought or type(entry.ClassId) ~= "string" then
			return nil
		end
		local worked, has = deps.hasBought(entry.ClassId)
		if worked then
			return has == true
		end
	end
	return nil
end

-- true / false / nil for one class entry. No entry means the class is open to everybody.
function UnlockCheck.resolve(entry: Entry?, deps: Deps, attempts: number?): boolean?
	if entry == nil then
		return true
	end
	if deps.bypass and deps.bypass() then
		return true
	end
	local tries = attempts or 2
	local result: boolean? = nil
	for attempt = 1, tries do
		if deps.isPresent and not deps.isPresent() then
			return nil
		end
		result = owns(entry, deps)
		if result ~= nil then
			break
		end
		if attempt < tries and deps.wait then
			deps.wait(0.5 * attempt)
		end
	end
	return result
end

-- A pick request. Returns nil when the class does not exist (the request is ignored, nothing is said),
-- otherwise whether the pick is allowed and the message to show.
function UnlockCheck.pick(
	classId: any,
	classes: { [string]: any },
	unlocks: { [string]: Entry },
	deps: Deps
): PickResult?
	if type(classId) ~= "string" or classes[classId] == nil then
		return nil
	end
	local entry = unlocks[classId]
	local owned = UnlockCheck.resolve(entry, deps, 2)
	if owned == true then
		return { ok = true, message = "" }
	end
	if owned == nil then
		return { ok = false, message = RETRY_MESSAGE }
	end
	local hint = entry and entry.Hint or "This class is locked."
	return { ok = false, message = "Locked. " .. hint }
end

return UnlockCheck

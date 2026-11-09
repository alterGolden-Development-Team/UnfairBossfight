--!strict
-- State machine for one party room (spec section 7). Pure data and rules, no Roblox services, no timers:
-- the caller passes `now` (os.time()) so the module is testable anywhere (Tests/PartyStateTests).
--
-- Every mutating function takes the state first and returns (ok, errorMessage). On failure NOTHING is changed.
--
--   Open      players can join, leave, pick a class; the leader sets the difficulty and Enraged
--   Countdown the leader pressed Start; joins and settings changes are refused, any leave cancels it
--   Locked    the countdown ended and the launch is under way; joins are refused, leaves just remove the player
--
-- members is ordered by join time, so "longest waiting" is simply the first entry.

local Config = require(script.Parent.UnfairConfig)
local TeleportPayload = require(script.Parent.TeleportPayload)

export type Member = TeleportPayload.Member
export type Phase = "Open" | "Countdown" | "Locked"

export type State = {
	members: { Member },
	leaderUserId: number?,
	difficulty: string,
	enraged: boolean,
	phase: Phase,
	countdownEndsAt: number?,
}

local PartyState = {}

function PartyState.new(): State
	return {
		members = {},
		leaderUserId = nil,
		difficulty = Config.DefaultDifficulty,
		enraged = false,
		phase = "Open",
		countdownEndsAt = nil,
	}
end

-- Back to an empty, open room with default settings. Works in place so whoever holds the table keeps a valid one.
function PartyState.reset(state: State)
	table.clear(state.members)
	state.leaderUserId = nil
	state.difficulty = Config.DefaultDifficulty
	state.enraged = false
	state.phase = "Open"
	state.countdownEndsAt = nil
end

local function indexOf(state: State, userId: number): number?
	for i, member in state.members do
		if member.userId == userId then
			return i
		end
	end
	return nil
end

function PartyState.has(state: State, userId: number): boolean
	return indexOf(state, userId) ~= nil
end

function PartyState.isLeader(state: State, userId: number): boolean
	return state.leaderUserId == userId
end

function PartyState.count(state: State): number
	return #state.members
end

function PartyState.join(state: State, userId: any, class: any): (boolean, string?)
	if not TeleportPayload.isUserId(userId) then
		return false, "bad user id"
	end
	if type(class) ~= "string" or class == "" then
		return false, "bad class"
	end
	if state.phase ~= "Open" then
		return false, "room is starting"
	end
	if indexOf(state, userId) ~= nil then
		return false, "already in room"
	end
	if #state.members >= Config.PartyMax then
		return false, "room is full"
	end
	table.insert(state.members, { userId = userId, class = class })
	if state.leaderUserId == nil then
		state.leaderUserId = userId
	end
	return true, nil
end

function PartyState.leave(state: State, userId: number): (boolean, string?)
	local index = indexOf(state, userId)
	if index == nil then
		return false, "not in room"
	end
	table.remove(state.members, index)

	if #state.members == 0 then
		if state.phase == "Locked" then
			state.leaderUserId = nil -- the launch finishes with whoever is left; finish() resets the room
		else
			PartyState.reset(state)
		end
		return true, nil
	end

	if state.leaderUserId == userId then
		state.leaderUserId = state.members[1].userId -- longest-waiting member takes over
	end
	if state.phase == "Countdown" then
		state.phase = "Open"
		state.countdownEndsAt = nil
	end
	return true, nil
end

function PartyState.setClass(state: State, userId: number, class: any): (boolean, string?)
	if type(class) ~= "string" or class == "" then
		return false, "bad class"
	end
	if state.phase == "Locked" then
		return false, "room is launching"
	end
	local index = indexOf(state, userId)
	if index == nil then
		return false, "not in room"
	end
	state.members[index].class = class
	return true, nil
end

-- Leader only. `enraged` nil keeps the current value. Easy never keeps Enraged: switching to Easy clears it, and
-- asking for Easy + Enraged together is an error.
function PartyState.setConfig(state: State, actorUserId: number, difficulty: any, enraged: any): (boolean, string?)
	if state.leaderUserId ~= actorUserId then
		return false, "only the leader can change settings"
	end
	if state.phase ~= "Open" then
		return false, "cancel the countdown first"
	end
	if not Config.IsDifficulty(difficulty) then
		return false, "unknown difficulty"
	end
	if enraged ~= nil and type(enraged) ~= "boolean" then
		return false, "bad enraged flag"
	end

	local nextEnraged = state.enraged
	if enraged ~= nil then
		nextEnraged = enraged
	end
	if not Config.EnragedAllowed(difficulty) then
		if enraged == true then
			return false, "Enraged is not allowed on Easy"
		end
		nextEnraged = false
	end

	state.difficulty = difficulty
	state.enraged = nextEnraged
	return true, nil
end

function PartyState.startCountdown(state: State, actorUserId: number, now: number): (boolean, string?)
	if state.leaderUserId ~= actorUserId then
		return false, "only the leader can start"
	end
	if state.phase ~= "Open" then
		return false, "already starting"
	end
	if #state.members == 0 then
		return false, "room is empty"
	end
	state.phase = "Countdown"
	state.countdownEndsAt = now + Config.CountdownSeconds
	return true, nil
end

function PartyState.cancelCountdown(state: State, actorUserId: number): (boolean, string?)
	if state.leaderUserId ~= actorUserId then
		return false, "only the leader can cancel"
	end
	if state.phase ~= "Countdown" then
		return false, "no countdown running"
	end
	state.phase = "Open"
	state.countdownEndsAt = nil
	return true, nil
end

function PartyState.isCountdownDue(state: State, now: number): boolean
	local endsAt = state.countdownEndsAt
	return state.phase == "Countdown" and endsAt ~= nil and now >= endsAt
end

-- Countdown finished: lock the room for the launch. Refused before the countdown has really run out.
function PartyState.lock(state: State, now: number): (boolean, string?)
	if state.phase ~= "Countdown" then
		return false, "no countdown running"
	end
	if not PartyState.isCountdownDue(state, now) then
		return false, "countdown not finished"
	end
	state.phase = "Locked"
	state.countdownEndsAt = nil
	return true, nil
end

-- Launch is over (teleported, failed or abandoned): empty the room for the next party.
function PartyState.finish(state: State): (boolean, string?)
	if state.phase ~= "Locked" then
		return false, "room is not launching"
	end
	PartyState.reset(state)
	return true, nil
end

-- A copy of what TeleportPayload.build needs, or nil for an empty room. partyId comes from the caller (a GUID).
function PartyState.snapshot(state: State, partyId: string): TeleportPayload.Party?
	local leader = state.leaderUserId
	if leader == nil or #state.members == 0 then
		return nil
	end
	local members: { Member } = {}
	for i, member in state.members do
		members[i] = { userId = member.userId, class = member.class }
	end
	return {
		partyId = partyId,
		leaderUserId = leader,
		difficulty = state.difficulty,
		enraged = state.enraged,
		members = members,
	}
end

return PartyState

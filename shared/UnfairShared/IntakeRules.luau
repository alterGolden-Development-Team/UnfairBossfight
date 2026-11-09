--!strict
-- The boss place's decision about an arriving player (spec 6.2, plan task 8), as pure logic.
-- The boss place's Intake module does the Roblox part (read the join data, set attributes, teleport away); this decides.
--
--   admit()         is the player allowed in, and with which payload?   (synchronous: the caller then claims the run)
--   resolveClass()  the class the player really gets (a forged or locked class falls back to the default)
--
-- Decision kinds:
--   Accept    play in lobby mode (settings come from the payload; later arrivals must carry the same runId)
--   Reject    send the player back to the lobby
--   Fallback  no usable payload and the lobby is not required: behave exactly like the boss place always did

local TeleportPayload = require(script.Parent.TeleportPayload)

export type Session = {
	runId: string?, -- the run this server accepted first
	members: { [number]: string }, -- userId -> class actually given, for players already let in
}

export type Decision = {
	kind: "Accept" | "Reject" | "Fallback",
	reason: string?,
	payload: TeleportPayload.Payload?, -- the validated payload (nil for a reconnect)
	requestedClass: string?,
	reconnect: boolean?,
	firstArrival: boolean?, -- this player's payload sets the run's settings
}

local IntakeRules = {}

function IntakeRules.newSession(): Session
	return { runId = nil, members = {} }
end

function IntakeRules.admit(teleportData: any, userId: number, now: number, enforce: boolean, session: Session): Decision
	local payload, err = TeleportPayload.validate(teleportData, { now = now, arrivingUserId = userId })
	if payload == nil then
		-- a player already let in who simply rejoined (a dropped connection) carries no teleport data
		local known = session.members[userId]
		if known ~= nil and teleportData == nil then
			return { kind = "Accept", requestedClass = known, reconnect = true }
		end
		if enforce then
			return { kind = "Reject", reason = err or "no teleport data" }
		end
		return { kind = "Fallback", reason = err or "no teleport data" }
	end

	if session.runId ~= nil and session.runId ~= payload.runId then
		return { kind = "Reject", reason = "this server is already running a different party" }
	end

	local requested = ""
	for _, member in payload.members do
		if member.userId == userId then
			requested = member.class
		end
	end
	return {
		kind = "Accept",
		payload = payload,
		requestedClass = requested,
		firstArrival = session.runId == nil,
	}
end

-- Record an accepted player. The first call fixes the run id.
function IntakeRules.remember(session: Session, runId: string?, userId: number, class: string)
	if session.runId == nil then
		session.runId = runId
	end
	session.members[userId] = class
end

-- The class the player gets and, when it differs from what they asked for, a message to show them.
--   exists    the class is in ClassConfig
--   hasEntry  the class has an unlock requirement
--   unlocked  the unlock check: true / false / nil (could not verify); ignored when there is no requirement
function IntakeRules.resolveClass(
	requested: string,
	exists: boolean,
	hasEntry: boolean,
	unlocked: boolean?,
	defaultClass: string
): (string, string?)
	if not exists then
		return defaultClass, "Your class was not available, so you are playing as the default class."
	end
	if hasEntry and unlocked ~= true then
		if unlocked == nil then
			return defaultClass, "Could not verify your class unlock, so you are playing as the default class."
		end
		return defaultClass, "That class is locked for you, so you are playing as the default class."
	end
	return requested, nil
end

return IntakeRules

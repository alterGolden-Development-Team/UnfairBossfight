--!strict
-- Turns a room's snapshot into the payload that is really sent, at the moment of launch (spec 6.1, plan task 17).
-- Pure: the server passes in who is still here and what class each player has picked *on the server*, so nothing the
-- client sent at the last second can change the party.
--
--   * players who have left since the snapshot are dropped
--   * every class is re-read from the server's own record (classOf), never from the snapshot's copy
--   * if the leader left, the first remaining member leads
--   * the result goes through TeleportPayload.build, so Enraged on Easy etc. can never be sent

local TeleportPayload = require(script.Parent.TeleportPayload)

local LaunchPlan = {}

export type Result = { payload: TeleportPayload.Payload, userIds: { number } }

function LaunchPlan.make(
	party: TeleportPayload.Party,
	isPresent: (userId: number) -> boolean,
	classOf: (userId: number) -> string?,
	runId: string,
	now: number?
): (Result?, string?)
	local members: { TeleportPayload.Member } = {}
	local userIds: { number } = {}
	local leader: number? = nil
	for _, member in party.members do
		if isPresent(member.userId) then
			local class = classOf(member.userId) or member.class
			table.insert(members, { userId = member.userId, class = class })
			table.insert(userIds, member.userId)
			if member.userId == party.leaderUserId then
				leader = member.userId
			end
		end
	end
	if #members == 0 then
		return nil, "nobody is left in the party"
	end

	local payload, err = TeleportPayload.build({
		partyId = party.partyId,
		leaderUserId = leader or members[1].userId,
		difficulty = party.difficulty,
		enraged = party.enraged,
		members = members,
	}, runId, now)
	if payload == nil then
		return nil, err
	end
	return { payload = payload, userIds = userIds }, nil
end

return LaunchPlan

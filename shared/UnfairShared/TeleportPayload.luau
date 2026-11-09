--!strict
-- The message the lobby sends with a party teleport and the boss place checks on arrival (spec 6.1, 6.2 rule 2).
-- Pure data, no Roblox services, so it is tested with plain assertions (Tests/TeleportPayloadTests).
--
-- validate() never trusts its input: it returns a fresh, cleaned copy (known fields only), so nothing the sender
-- smuggled in survives and the caller cannot alias the original table.

local Config = require(script.Parent.UnfairConfig)

export type Member = { userId: number, class: string }

-- What the lobby knows about a room when it launches. PartyState.snapshot produces exactly this.
export type Party = {
	partyId: string,
	leaderUserId: number,
	difficulty: string,
	enraged: boolean,
	members: { Member },
}

export type Payload = {
	v: number,
	runId: string,
	partyId: string,
	leaderUserId: number,
	difficulty: string,
	enraged: boolean,
	members: { Member },
	issuedAt: number,
}

export type ValidateOptions = {
	now: number?, -- os.time() by default (tests pass their own)
	arrivingUserId: number?, -- boss place: the player who just joined must be one of the members
}

local TeleportPayload = {}

local MAX_ID_LENGTH = 64
local MAX_CLASS_LENGTH = 32
local MAX_FUTURE_SKEW_SECONDS = 60 -- tolerate small clock differences between servers

-- Roblox user ids are positive whole numbers. Rejects NaN, infinity, fractions, zero and negatives.
function TeleportPayload.isUserId(value: any): boolean
	return type(value) == "number" and value == value and value >= 1 and value < 2 ^ 53 and value % 1 == 0
end

local function isText(value: any, maxLength: number): boolean
	return type(value) == "string" and #value >= 1 and #value <= maxLength
end

function TeleportPayload.validate(payload: any, options: ValidateOptions?): (Payload?, string?)
	local now = os.time()
	local arrivingUserId: number? = nil
	if options then
		now = options.now or now
		arrivingUserId = options.arrivingUserId
	end

	if type(payload) ~= "table" then
		return nil, "payload is not a table"
	end
	if payload.v ~= Config.PayloadVersion then
		return nil, "unsupported payload version"
	end
	if not isText(payload.runId, MAX_ID_LENGTH) then
		return nil, "bad runId"
	end
	if not isText(payload.partyId, MAX_ID_LENGTH) then
		return nil, "bad partyId"
	end
	if not TeleportPayload.isUserId(payload.leaderUserId) then
		return nil, "bad leaderUserId"
	end
	if not Config.IsDifficulty(payload.difficulty) then
		return nil, "unknown difficulty"
	end
	if type(payload.enraged) ~= "boolean" then
		return nil, "bad enraged flag"
	end
	if payload.enraged and not Config.EnragedAllowed(payload.difficulty) then
		return nil, "Enraged is not allowed on Easy"
	end

	-- members: a plain array of 1..PartyMax entries, no holes, no extra keys, no repeated players
	local rawMembers = payload.members
	if type(rawMembers) ~= "table" then
		return nil, "members is not a table"
	end
	local keyCount = 0
	for _ in rawMembers do
		keyCount += 1
	end
	if keyCount ~= #rawMembers then
		return nil, "members is not an array"
	end
	if keyCount < 1 or keyCount > Config.PartyMax then
		return nil, "member count out of range"
	end
	local members: { Member } = {}
	local seen: { [number]: boolean } = {}
	for i = 1, keyCount do
		local raw = rawMembers[i]
		if type(raw) ~= "table" then
			return nil, "member is not a table"
		end
		if not TeleportPayload.isUserId(raw.userId) then
			return nil, "bad member userId"
		end
		if not isText(raw.class, MAX_CLASS_LENGTH) then
			return nil, "bad member class"
		end
		if seen[raw.userId] then
			return nil, "duplicate member"
		end
		seen[raw.userId] = true
		members[i] = { userId = raw.userId, class = raw.class }
	end
	if not seen[payload.leaderUserId] then
		return nil, "leader is not a member"
	end
	if arrivingUserId ~= nil and not seen[arrivingUserId] then
		return nil, "player is not a member"
	end

	-- freshness: a payload is only good for PayloadMaxAgeSeconds after it was issued
	local issuedAt = payload.issuedAt
	if type(issuedAt) ~= "number" or issuedAt ~= issuedAt then
		return nil, "bad issuedAt"
	end
	local age = now - issuedAt
	if age > Config.PayloadMaxAgeSeconds then
		return nil, "payload expired"
	end
	if age < -MAX_FUTURE_SKEW_SECONDS then
		return nil, "payload issued in the future"
	end

	local clean: Payload = {
		v = Config.PayloadVersion,
		runId = payload.runId :: string,
		partyId = payload.partyId :: string,
		leaderUserId = payload.leaderUserId :: number,
		difficulty = payload.difficulty :: string,
		enraged = payload.enraged :: boolean,
		members = members,
		issuedAt = issuedAt,
	}
	return clean, nil
end

-- Builds the payload for a launch and runs it through validate(), so the lobby can never send one the boss
-- place would reject (Enraged on Easy, 7 members, ...). Returns nil and the reason instead.
function TeleportPayload.build(party: Party, runId: string, now: number?): (Payload?, string?)
	local issuedAt = now or os.time()
	return TeleportPayload.validate({
		v = Config.PayloadVersion,
		runId = runId,
		partyId = party.partyId,
		leaderUserId = party.leaderUserId,
		difficulty = party.difficulty,
		enraged = party.enraged,
		members = party.members,
		issuedAt = issuedAt,
	}, { now = issuedAt })
end

return TeleportPayload

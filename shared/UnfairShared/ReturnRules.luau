--!strict
-- When may a player leave the boss place for the lobby (spec 6.4, plan task 19)? Pure, so the answer is tested.
-- The boss server asks this on every "ReturnToLobby" request; the client button only mirrors the same rule.

local Rules = {}

Rules.CooldownSeconds = 3 -- ignore a second request that arrives right after the first

export type State = {
	lobbyMode: boolean, -- the run came from the lobby (workspace LobbyMode)
	won: boolean, -- the encounter is won (workspace BossEncounterWon)
	defeated: boolean, -- this player is permanently out (PermanentlyDefeated)
	now: number,
	lastRequest: number?, -- when this player last asked, same clock as `now`
}

-- Returns (allowed, reason). The reason is one of "NotLobbyRun", "FightNotOver", "TooSoon" when not allowed.
function Rules.decide(state: State): (boolean, string?)
	if state.lobbyMode ~= true then
		return false, "NotLobbyRun"
	end
	if state.won ~= true and state.defeated ~= true then
		return false, "FightNotOver"
	end
	local last = state.lastRequest
	if last ~= nil and state.now - last < Rules.CooldownSeconds then
		return false, "TooSoon"
	end
	return true, nil
end

-- Text the player sees for a refusal.
function Rules.message(reason: string?): string
	if reason == "NotLobbyRun" then
		return "There is no lobby to return to from here."
	elseif reason == "FightNotOver" then
		return "You can return to the lobby once you are defeated or the boss is down."
	elseif reason == "TooSoon" then
		return "One moment..."
	end
	return "Could not return to the lobby."
end

return Rules

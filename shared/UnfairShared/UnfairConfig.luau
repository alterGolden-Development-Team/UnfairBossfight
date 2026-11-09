--!strict
-- Settings both places read: which places exist, party limits, difficulty ids and cash per win.
-- Pure data plus tiny helpers (no Roblox services), so it can be tested anywhere.
--
-- Place ids for both universes are filled in (plan tasks 4 and 5). Env decides which set is used:
--   "Test" = the test universe (default while building), "Live" = the real game (switched at the cut-over).

local Config = {}

Config.Env = "Live" :: "Test" | "Live"

Config.Places = {
	Live = { Lobby = 92877530696258, Boss = 123789153131367 }, -- universe 10768840017: "Place1" (lobby, empty) and The Golden Encounter
	Test = { Lobby = 83310105029258, Boss = 76581021814220 }, -- "Unfair Bossfight TEST" universe 10775538032
}

-- Boss place: reject players who did not arrive through the lobby (reserved server + valid teleport payload).
-- Stays false until the cut-over; Studio always uses the old behaviour regardless.
Config.RequireLobby = true
-- The test universe already requires the lobby, so the "direct join bounces back" check (plan task 18) can run there.
Config.RequireLobbyTest = true

-- Studio only (ignored everywhere else): makes the boss place behave as if every joining player arrived with this
-- party payload, so lobby mode can be tried without a teleport (plan task 10). Leave nil normally.
--   { difficulty = "Hardcore", enraged = true, class = "Mage" }   -> a valid solo party for whoever joins
--   { raw = { ... } }                                                -> this exact (possibly forged) table is used
Config.DevPayload = nil :: { difficulty: string?, enraged: boolean?, class: string?, raw: any? }?

Config.PartyMax = 6
Config.PartyRooms = 4
Config.CountdownSeconds = 5
Config.RoomLeaveDistance = 14 -- studs from a room's Pad before the player is dropped from that room

-- Lobby: log the launch payload instead of teleporting. Studio always behaves as if this were true.
Config.DryRun = false
Config.PayloadVersion = 1
Config.PayloadMaxAgeSeconds = 600

-- Same ids as boss BossShared/Config/DifficultyConfig.luau (Order and Default).
Config.Difficulties = table.freeze({ "Hellaven", "TrueHardcore", "Hardcore", "NerfedHardcore", "Easy" })
Config.DefaultDifficulty = "TrueHardcore"

-- Cash paid per win; Enraged doubles it. Easy cannot be Enraged.
Config.CashByDifficulty = table.freeze({
	Hellaven = 50,
	TrueHardcore = 35,
	Hardcore = 25,
	NerfedHardcore = 15,
	Easy = 5,
})
Config.EnragedCashMultiplier = 2

-- Where cash lives (spec 6.3). DataStores are per universe, so the test universe has its own copy automatically.
-- Studio gets a separate store name so a Studio session never touches real balances in whichever universe is open.
Config.CashStoreName = "UnfairBossfight_PlayerData_v1"
Config.CashStoreNameStudio = "UnfairBossfight_PlayerData_v1_Studio"
Config.CashWriteAttempts = 4 -- boss: tries per payout before it is parked and retried in the background
Config.CashReturnWaitSeconds = 12 -- boss: how long "Return to Lobby" waits for that player's cash write

function Config.CashStore(isStudio: boolean): string
	return if isStudio then Config.CashStoreNameStudio else Config.CashStoreName
end

function Config.IsDifficulty(id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	return table.find(Config.Difficulties, id) ~= nil
end

function Config.EnragedAllowed(difficulty: string): boolean
	return difficulty ~= "Easy"
end

-- Whether the boss place bounces players who did not arrive through the lobby, for the current Env.
function Config.RequireLobbyActive(): boolean
	if Config.Env == "Test" then
		return Config.RequireLobbyTest
	end
	return Config.RequireLobby
end

function Config.LobbyPlaceId(): number
	return Config.Places[Config.Env].Lobby
end

function Config.BossPlaceId(): number
	return Config.Places[Config.Env].Boss
end

return Config

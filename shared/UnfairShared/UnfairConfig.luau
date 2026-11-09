--!strict
-- Settings both places read: which places exist, party limits, difficulty ids and cash per win.
-- Pure data plus tiny helpers (no Roblox services), so it can be tested anywhere.
--
-- Place ids are filled in once the places exist (plan task 5). Env decides which set is used:
--   "Test" = the test universe (default while building), "Live" = the real game (switched at the cut-over).

local Config = {}

Config.Env = "Test" :: "Test" | "Live"

-- 0 = not filled in yet
Config.Places = {
	Live = { Lobby = 0, Boss = 0 },
	Test = { Lobby = 0, Boss = 0 },
}

-- Boss place: reject players who did not arrive through the lobby (reserved server + valid teleport payload).
-- Stays false until the cut-over; Studio always uses the old behaviour regardless.
Config.RequireLobby = false

Config.PartyMax = 6
Config.PartyRooms = 4
Config.CountdownSeconds = 5
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

function Config.IsDifficulty(id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	return table.find(Config.Difficulties, id) ~= nil
end

function Config.EnragedAllowed(difficulty: string): boolean
	return difficulty ~= "Easy"
end

function Config.LobbyPlaceId(): number
	return Config.Places[Config.Env].Lobby
end

function Config.BossPlaceId(): number
	return Config.Places[Config.Env].Boss
end

return Config

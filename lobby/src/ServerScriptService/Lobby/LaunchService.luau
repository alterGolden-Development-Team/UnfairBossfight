--!strict
-- Sends a locked party to a fresh reserved boss server (plan task 17). Called by PartyService when a countdown ends.
--
--   * the payload is built from the server's own records at this moment (LaunchPlan): players who left are dropped,
--     classes come from the `PlayerClass` attribute, never from anything the client sent
--   * Studio (or Config.DryRun): nothing is teleported. The payload is printed, stored in the workspace attribute
--     `LastLaunchPayload` and sent to the members as a "DryRun" message so it can be inspected
--   * real run: ReserveServer, one TeleportAsync for the whole party (so they land together), 3 attempts; a player
--     whose teleport fails later (TeleportInitFailed) is retried up to 3 times, then told and left in the lobby

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.UnfairShared.UnfairConfig)
local LaunchPlan = require(ReplicatedStorage.UnfairShared.LaunchPlan)
local TeleportPayload = require(ReplicatedStorage.UnfairShared.TeleportPayload)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)

local LaunchService = {}

local MAX_ATTEMPTS = 3

type Pending = { placeId: number, options: TeleportOptions, attempts: number }
local pending: { [Player]: Pending } = {}
local failureHookConnected = false

local function control(): RemoteEvent
	return LobbyRemotes.get("PartyControl")
end

local function tell(players: { Player }, message: string)
	for _, player in players do
		control():FireClient(player, "Result", { Message = message })
	end
end

local function isDryRun(): boolean
	return RunService:IsStudio() or Config.DryRun
end

local function classOf(userId: number): string?
	local player = Players:GetPlayerByUserId(userId)
	local class = player and player:GetAttribute("PlayerClass")
	if type(class) == "string" then
		return class
	end
	return nil
end

local function connectFailureHook()
	if failureHookConnected then
		return
	end
	failureHookConnected = true
	TeleportService.TeleportInitFailed:Connect(function(player: Player, _result: Enum.TeleportResult, message: string)
		local info = pending[player]
		if info == nil then
			return
		end
		if info.attempts >= MAX_ATTEMPTS then
			pending[player] = nil
			warn(`[Launch] teleport for {player.Name} failed for good: {message}`)
			tell({ player }, "Could not reach the boss server. You are back in the lobby, try again.")
			return
		end
		info.attempts += 1
		task.wait(2)
		if player.Parent == Players then
			local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, info.placeId, { player }, info.options)
			if not ok then
				warn(`[Launch] retry for {player.Name}: {err}`)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		pending[player] = nil
	end)
end

-- Returns true when the party was sent (or, in a dry run, when the payload was produced).
function LaunchService.launch(party: TeleportPayload.Party): boolean
	local runId = HttpService:GenerateGUID(false)
	local plan, reason = LaunchPlan.make(party, function(userId: number)
		return Players:GetPlayerByUserId(userId) ~= nil
	end, classOf, runId, os.time())
	if plan == nil then
		warn("[Launch] no launch: " .. tostring(reason))
		return false
	end

	local players: { Player } = {}
	for _, userId in plan.userIds do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			table.insert(players, player)
		end
	end
	if #players == 0 then
		return false
	end

	local json = HttpService:JSONEncode(plan.payload)
	if isDryRun() then
		print("[Launch] DRY RUN payload: " .. json)
		workspace:SetAttribute("LastLaunchPayload", json)
		for _, player in players do
			control():FireClient(player, "DryRun", json)
		end
		return true
	end

	local placeId = Config.BossPlaceId()
	if placeId == 0 then
		warn("[Launch] boss place id is not set in UnfairConfig")
		tell(players, "The boss place is not available yet.")
		return false
	end

	local reserved, code = pcall(function()
		return TeleportService:ReserveServer(placeId)
	end)
	if not reserved then
		warn("[Launch] ReserveServer failed: " .. tostring(code))
		tell(players, "Could not start the run. Try again.")
		return false
	end

	local options = Instance.new("TeleportOptions")
	local loose: any = options -- ReservedServerAccessCode is missing from the analyzer's type definitions
	loose.ReservedServerAccessCode = code
	options:SetTeleportData(plan.payload)

	connectFailureHook()
	for _, player in players do
		pending[player] = { placeId = placeId, options = options, attempts = 1 }
	end
	task.delay(60, function()
		for _, player in players do
			pending[player] = nil
		end
	end)

	for attempt = 1, MAX_ATTEMPTS do
		local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, placeId, players, options)
		if ok then
			return true
		end
		warn(`[Launch] TeleportAsync attempt {attempt} failed: {err}`)
		if attempt < MAX_ATTEMPTS then
			task.wait(attempt)
		end
	end
	for _, player in players do
		pending[player] = nil
	end
	tell(players, "Could not start the run. Try again.")
	return false
end

return LaunchService

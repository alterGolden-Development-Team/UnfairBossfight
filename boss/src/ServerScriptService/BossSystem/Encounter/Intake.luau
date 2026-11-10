--!nonstrict
--[[
 Intake - how the boss place treats a player who arrives from the lobby (plan tasks 8-10, spec 6.2).
 The decisions are pure and tested: UnfairShared/IntakeRules. This module is the Roblox half.

 On every PlayerAdded it reads the teleport payload and, if it is valid ("lobby mode"):
   * the first arrival sets workspace SelectedDifficulty, EncounterEnraged, DifficultyLocked and LobbyMode/LobbyRunId;
     later arrivals must carry the same runId
   * the player's PlayerClass is the class from the payload; a missing, forged or locked class becomes the default class
     and the player gets a notice (LobbyNotice)
   * the difficulty statue, class statue and Enraged Gate are hidden and their prompts disabled (the services also check
     workspace LobbyMode, so a hacked client cannot use their remotes either)
 No payload / invalid payload:
   * UnfairConfig.RequireLobbyActive() and not Studio -> the player is sent back to the lobby (replaces the old server lock)
   * otherwise nothing happens: the place plays exactly as it did before the lobby existed.
 In Studio, UnfairConfig.DevPayload can stand in for the teleport payload (see UnfairConfig).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local BossSystem = script:FindFirstAncestor("BossSystem")
local Config = require(ReplicatedStorage:WaitForChild("UnfairShared"):WaitForChild("UnfairConfig"))
local IntakeRules = require(ReplicatedStorage.UnfairShared.IntakeRules)
local TeleportPayload = require(ReplicatedStorage.UnfairShared.TeleportPayload)
local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local Unlocks = require(ReplicatedStorage.BossShared.Classes.ClassUnlocks)

local api = {}
local session = IntakeRules.newSession()
local started = false
local propsHidden = false
local noticeCount = 0

local function enforce()
	return Config.RequireLobbyActive() and not RunService:IsStudio()
end

function api.IsLobbyMode()
	return workspace:GetAttribute("LobbyMode") == true
end

local function notice(player, text)
	noticeCount += 1
	player:SetAttribute("LobbyNotice", text)
	player:SetAttribute("LobbyNoticeId", noticeCount)
end

local function bounce(player, reason)
	warn("[Intake] " .. player.Name .. " is sent back to the lobby: " .. tostring(reason))
	if RunService:IsStudio() then
		return -- nowhere to teleport to from Studio; the log line is the result
	end
	local lobby = Config.LobbyPlaceId()
	if lobby ~= 0 then
		local ok = pcall(TeleportService.Teleport, TeleportService, lobby, player)
		if ok then
			return
		end
	end
	player:Kick("Please join through the lobby.")
end

-- Studio only: a payload for this player made from UnfairConfig.DevPayload.
local function devTeleportData(player)
	local dev = Config.DevPayload
	if not RunService:IsStudio() or type(dev) ~= "table" then
		return nil
	end
	if dev.raw ~= nil then
		return dev.raw
	end
	local built = TeleportPayload.build({
		partyId = "dev-party",
		leaderUserId = player.UserId,
		difficulty = dev.difficulty or Config.DefaultDifficulty,
		enraged = dev.enraged == true,
		members = { { userId = player.UserId, class = dev.class or ClassConfig.Default } },
	}, "dev-run", os.time())
	return built
end

-- Hide the three things that let a player change settings in the boss place (the party chose them in the lobby).
local function hide(root)
	for _, item in ipairs(root:GetDescendants()) do
		if item:IsA("BasePart") then
			item.Transparency = 1
			item.CanCollide = false
			item.CanTouch = false
		elseif item:IsA("ProximityPrompt") or item:IsA("ParticleEmitter") or item:IsA("Light") or item:IsA("Beam")
			or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles") or item:IsA("SurfaceGui")
			or item:IsA("BillboardGui") then
			item.Enabled = false
		end
	end
end

local function hideProps()
	if propsHidden then
		return
	end
	propsHidden = true
	task.spawn(function()
		local arena = workspace:WaitForChild("GoldenGrasslandArena", 60)
		if not arena then
			return
		end
		for _, name in ipairs({ "DifficultyStatue", "ClassStatue", "EnragedGate" }) do
			task.spawn(function()
				local model = arena:WaitForChild(name, 60)
				if model then
					hide(model)
				end
			end)
		end
	end)
end

local function applyRun(payload)
	workspace:SetAttribute("LobbyMode", true)
	workspace:SetAttribute("LobbyRunId", payload.runId)
	workspace:SetAttribute("ActiveDifficulty", nil)
	workspace:SetAttribute("SelectedDifficulty", payload.difficulty)
	workspace:SetAttribute("EncounterEnraged", payload.enraged or nil)
	workspace:SetAttribute("DifficultyLocked", true)
	hideProps()
end

local function handle(player)
	local ok, join = pcall(player.GetJoinData, player)
	local data = ok and join and join.TeleportData or nil
	local dev = devTeleportData(player)
	if dev ~= nil then
		data = dev
	end

	local decision = IntakeRules.admit(data, player.UserId, os.time(), enforce(), session)
	if decision.kind == "Fallback" then
		return
	elseif decision.kind == "Reject" then
		bounce(player, decision.reason)
		return
	end

	-- accepted: claim the run before anything yields, so a second player arriving right now is compared to it
	local payload = decision.payload
	if payload and decision.firstArrival then
		applyRun(payload)
	end
	IntakeRules.remember(session, payload and payload.runId or nil, player.UserId, decision.requestedClass)

	local ClassService = require(BossSystem.Players.Classes.ClassService)
	local requested = decision.requestedClass
	local entry = Unlocks[requested]
	local unlocked = nil
	if ClassConfig.Classes[requested] and entry then
		unlocked = ClassService.CheckUnlock(player, requested, 2) -- may wait for the web call
	end
	local class, message = IntakeRules.resolveClass(requested, ClassConfig.Classes[requested] ~= nil, entry ~= nil, unlocked, ClassConfig.Default)
	session.members[player.UserId] = class
	if player.Parent ~= Players then
		return
	end

	pcall(require(BossSystem.Encounter.Orbs).Load, player) -- may wait for the data store; before Apply below
	if player.Parent ~= Players then
		return
	end
	player:SetAttribute("PlayerClass", class)
	player:SetAttribute("LobbyArrival", true)
	if player.Character then
		pcall(ClassService.Apply, player, player.Character) -- the character may have spawned while we waited
	end
	if message then
		notice(player, message)
	end
end

function api.Start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(function(player)
		task.spawn(handle, player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(handle, player)
	end
end

return api

--!strict
-- Party rooms, server side (plan task 15). Binds one PartyState to each Workspace.PartyRooms.Room1..N (see lobby/MAP.md).
--
-- The client only sends intents on the PartyControl remote; every check happens here, and the room's rules live in
-- shared PartyState (leader-only settings, Enraged never on Easy, locking...). Room state reaches clients through
-- attributes, so there is no custom replication:
--   room model:  Phase, LeaderUserId, Difficulty, Enraged, CountdownEndsAt (server time), MemberCount, Roster (JSON)
--   player:      PartyRoom (room index, nil when in none), PartyLocked (true while that party is launching)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.UnfairShared.UnfairConfig)
local PartyState = require(ReplicatedStorage.UnfairShared.PartyState)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)
local LaunchService = require(script.Parent.LaunchService)
local ClassConfig: any = require(ReplicatedStorage.BossShared.Classes.ClassConfig)

local control = LobbyRemotes.get("PartyControl")

type Room = {
	index: number,
	model: Instance,
	pad: BasePart,
	state: PartyState.State,
	token: number, -- bumped whenever a countdown is cancelled, so its waiting thread knows to stop
	classWatch: { [Player]: RBXScriptConnection },
}

local rooms: { [number]: Room } = {}
local roomOf: { [Player]: Room } = {}
local lastRequest: { [Player]: number } = {}
local REQUEST_GAP = 0.2
local JOIN_REACH = Config.RoomLeaveDistance + 6 -- how far from the pad a Join request still counts

local function say(player: Player, message: string)
	control:FireClient(player, "Result", { Message = message })
end

local function playerClass(player: Player): string
	local class = player:GetAttribute("PlayerClass")
	if type(class) == "string" and class ~= "" then
		return class
	end
	return ClassConfig.Default
end

local function publish(room: Room)
	local state = room.state
	local roster = {}
	for _, member in state.members do
		local player = Players:GetPlayerByUserId(member.userId)
		table.insert(roster, { userId = member.userId, name = player and player.Name or "?", class = member.class })
	end
	local model = room.model
	model:SetAttribute("Phase", state.phase)
	model:SetAttribute("LeaderUserId", state.leaderUserId)
	model:SetAttribute("Difficulty", state.difficulty)
	model:SetAttribute("Enraged", state.enraged)
	model:SetAttribute("CountdownEndsAt", state.countdownEndsAt)
	model:SetAttribute("MemberCount", #state.members)
	model:SetAttribute("Roster", HttpService:JSONEncode(roster))
end

local function distanceToPad(room: Room, player: Player): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root == nil or not root:IsA("BasePart") or humanoid == nil or humanoid.Health <= 0 then
		return nil
	end
	return (root.Position - room.pad.Position).Magnitude
end

local function detach(room: Room, player: Player)
	roomOf[player] = nil
	player:SetAttribute("PartyRoom", nil)
	player:SetAttribute("PartyLocked", nil)
	local watch = room.classWatch[player]
	if watch then
		watch:Disconnect()
		room.classWatch[player] = nil
	end
end

local function leave(player: Player)
	local room = roomOf[player]
	if room == nil then
		return
	end
	local wasCounting = room.state.phase == "Countdown"
	local ok = PartyState.leave(room.state, player.UserId)
	if not ok then
		return
	end
	if wasCounting then
		room.token += 1
	end
	detach(room, player)
	publish(room)
end

local function join(player: Player, index: any)
	if type(index) ~= "number" or index % 1 ~= 0 then
		return
	end
	local room = rooms[index]
	if room == nil then
		return
	end
	if roomOf[player] ~= nil then
		say(player, "Leave your current room first.")
		return
	end
	local distance = distanceToPad(room, player)
	if distance == nil or distance > JOIN_REACH then
		say(player, "Stand on the pad to join.")
		return
	end
	local ok, err = PartyState.join(room.state, player.UserId, playerClass(player))
	if not ok then
		say(player, err or "Could not join.")
		return
	end
	roomOf[player] = room
	player:SetAttribute("PartyRoom", room.index)
	room.classWatch[player] = player:GetAttributeChangedSignal("PlayerClass"):Connect(function()
		PartyState.setClass(room.state, player.UserId, playerClass(player))
		publish(room)
	end)
	publish(room)
end

local function runLaunch(room: Room, myToken: number)
	-- wait for the countdown, unless someone cancels it (token bumped) or the phase changes
	while room.token == myToken and room.state.phase == "Countdown" do
		if PartyState.isCountdownDue(room.state, workspace:GetServerTimeNow()) then
			break
		end
		task.wait(0.2)
	end
	if room.token ~= myToken or room.state.phase ~= "Countdown" then
		return
	end
	local locked = PartyState.lock(room.state, workspace:GetServerTimeNow())
	if not locked then
		return
	end
	for _, member in room.state.members do
		local player = Players:GetPlayerByUserId(member.userId)
		if player then
			player:SetAttribute("PartyLocked", true)
		end
	end
	publish(room)

	local party = PartyState.snapshot(room.state, HttpService:GenerateGUID(false))
	if party then
		local ok, err = pcall(LaunchService.launch, party)
		if not ok then
			warn("[Party] launch error: " .. tostring(err))
		end
	end

	-- the launch is over: free the room (anyone still here simply stays in the lobby)
	for _, member in table.clone(room.state.members) do
		local player = Players:GetPlayerByUserId(member.userId)
		if player then
			detach(room, player)
		end
	end
	PartyState.finish(room.state)
	publish(room)
end

local function start(player: Player)
	local room = roomOf[player]
	if room == nil then
		return
	end
	local ok, err = PartyState.startCountdown(room.state, player.UserId, workspace:GetServerTimeNow())
	if not ok then
		say(player, err or "Could not start.")
		return
	end
	room.token += 1
	publish(room)
	task.spawn(runLaunch, room, room.token)
end

local function cancel(player: Player)
	local room = roomOf[player]
	if room == nil then
		return
	end
	local ok, err = PartyState.cancelCountdown(room.state, player.UserId)
	if not ok then
		say(player, err or "Could not cancel.")
		return
	end
	room.token += 1
	publish(room)
end

local function setConfig(player: Player, difficulty: any, enraged: any)
	local room = roomOf[player]
	if room == nil then
		return
	end
	local ok, err = PartyState.setConfig(room.state, player.UserId, difficulty, enraged)
	if not ok then
		say(player, err or "Could not change settings.")
		return
	end
	publish(room)
end

control.OnServerEvent:Connect(function(player: Player, action: any, a: any, b: any)
	if type(action) ~= "string" then
		return
	end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < REQUEST_GAP then
		return
	end
	lastRequest[player] = now

	if action == "Join" then
		join(player, a)
	elseif action == "Leave" then
		leave(player)
	elseif action == "SetConfig" then
		setConfig(player, a, b)
	elseif action == "Start" then
		start(player)
	elseif action == "Cancel" then
		cancel(player)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	leave(player)
	lastRequest[player] = nil
end)

-- Players who walk away from the pad leave the room (this also cancels a running countdown).
task.spawn(function()
	while true do
		task.wait(0.5)
		for player, room in roomOf do
			if room.state.phase ~= "Locked" then
				local distance = distanceToPad(room, player)
				if distance == nil or distance > Config.RoomLeaveDistance then
					leave(player)
				end
			end
		end
	end
end)

local function bindRoom(index: number, model: Instance)
	local pad = model:FindFirstChild("Pad")
	if pad == nil or not pad:IsA("BasePart") then
		warn(`[Party] {model.Name} has no Pad part, skipped (see lobby/MAP.md)`)
		return
	end
	local room: Room = { index = index, model = model, pad = pad, state = PartyState.new(), token = 0, classWatch = {} }
	rooms[index] = room
	publish(room)

	local joinPrompt: ProximityPrompt
	local existingPrompt = pad:FindFirstChild("JoinPrompt")
	if existingPrompt ~= nil and existingPrompt:IsA("ProximityPrompt") then
		joinPrompt = existingPrompt
	else
		joinPrompt = Instance.new("ProximityPrompt")
		joinPrompt.Name = "JoinPrompt"
		joinPrompt.Parent = pad
	end
	joinPrompt.ActionText = "Join party"
	joinPrompt.ObjectText = `Party Room {index}`
	joinPrompt.HoldDuration = 0.3
	joinPrompt.MaxActivationDistance = 10
	joinPrompt.RequiresLineOfSight = false
	joinPrompt.Triggered:Connect(function(player: Player)
		if roomOf[player] == room then
			leave(player) -- pressing it again while inside leaves
		else
			join(player, index)
		end
	end)
end

task.spawn(function()
	local folder = workspace:WaitForChild("PartyRooms", 30)
	if folder == nil then
		warn("[Party] Workspace.PartyRooms not found: build the lobby map first (lobby/MAP.md)")
		return
	end
	for index = 1, Config.PartyRooms do
		local model = folder:WaitForChild("Room" .. index, 10)
		if model then
			bindRoom(index, model)
		else
			warn(`[Party] Workspace.PartyRooms.Room{index} not found`)
		end
	end
end)

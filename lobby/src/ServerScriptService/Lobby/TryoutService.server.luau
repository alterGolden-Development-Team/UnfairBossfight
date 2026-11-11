--!nonstrict
--[[
 TryoutService - the shop's class showroom. You watch from the edge of the training stage while a wooden performer uses the class you
 are looking at on the target dummy. The performer is an NPC "puppet" running the boss place's own class kits
 (ServerScriptService.BossSystem, mounted from ../boss; ClassService.NewPuppet / ApplyPuppet). It is not you: your clicks and keys do
 nothing to it, and its dashes and blinks never touch your camera. If a kit changes in the boss project it changes here.
   Tryout remote  client -> server: "Enter", classId | "Class", classId | "Perform", moveId | "Leave"
                  server -> client: "Result", { Message } | "Performer", model | "Done", moveId
   Moves are listed in ReplicatedStorage.Lobby.ShowcaseMoves (every skill, its hold version and the hidden ones).
   Player attribute `TryoutClass` is the class being shown (nil outside the showroom). Showing a class does not select or unlock it.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)
local ShowcaseMoves = require(ReplicatedStorage.Lobby.ShowcaseMoves)

local remote = LobbyRemotes.get("Tryout")
local areaRemote = LobbyRemotes.get("Area")

local world = workspace:WaitForChild("World", 30)
local stage = world and world:WaitForChild("Stage", 10)
local bossSystem = ServerScriptService:FindFirstChild("BossSystem")
if not stage or not bossSystem then
	warn("[Tryout] the training hall or the class kits are missing; trying classes is off")
	return
end

-- The boss place keeps a few RemoteEvents in its place file, not in code. The kits wait for them, so this place needs them too.
local function needEvent(parent, name)
	if parent and not parent:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = parent
	end
end
needEvent(ReplicatedStorage:FindFirstChild("VFXEngine"), "Event") -- VFX cues
needEvent(ReplicatedStorage, "BossCombatEffects") -- skill sounds

-- Tells ClassService it is a guest here: the lobby owns unlocks and class choice (see ClassService.Start).
workspace:SetAttribute("ClassShowroom", true)
local ClassService = require(bossSystem.Players.Classes.ClassService)
local TrainingDummy = require(bossSystem.Players.Classes.TrainingDummy)
ClassService.Start()

local dummySpot = stage:WaitForChild("DummySpot")
if not workspace:FindFirstChild("ClassTrainingDummy") then
	TrainingDummy.Create(dummySpot.Position)
end

local FADE_TIME = 0.35
local MARKS = 8 -- performers stand in a ring round the target, one mark each
local REACH = 7 -- studs from the target: inside every melee range
local WATCH_DISTANCE = 22 -- the watcher stands this far out, on the far side of the ring from their performer

local sessions = {} -- [Player] = { mark, puppet, body, class, token }
local busy = {}

local function reply(player, message)
	remote:FireClient(player, "Result", { Message = message })
end

local function alive(model)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0 and model:FindFirstChild("HumanoidRootPart") and model.Parent ~= nil
end

local function freeMark(player)
	local taken = {}
	for other, session in sessions do
		if other ~= player then
			taken[session.mark] = true
		end
	end
	for index = 1, MARKS do
		if not taken[index] then
			return index
		end
	end
	return 1
end

local function markAngle(index)
	return (index - 1) / MARKS * math.pi * 2 + math.pi
end

local function markCF(index)
	local a = markAngle(index)
	local center = dummySpot.Position
	local at = center + Vector3.new(math.cos(a) * REACH, 3, math.sin(a) * REACH)
	return CFrame.lookAt(at, Vector3.new(center.X, at.Y, center.Z))
end

-- the watcher stands off to the side of the performer's line, far enough to see both performer and dummy
local function watchCF(index)
	local a = markAngle(index) + math.rad(70)
	local center = dummySpot.Position
	local at = center + Vector3.new(math.cos(a) * WATCH_DISTANCE, 3, math.sin(a) * WATCH_DISTANCE)
	return CFrame.lookAt(at, Vector3.new(center.X, at.Y, center.Z))
end

-- The performer: a wooden R6 body (the kits are written for R6), tagged ClassPuppet so every client animates it like a player.
local description
local function performerBody(player, at)
	if not description then
		description = Instance.new("HumanoidDescription")
		local wood, dark, straw = Color3.fromRGB(176, 128, 82), Color3.fromRGB(122, 84, 52), Color3.fromRGB(214, 180, 112)
		description.HeadColor, description.TorsoColor = straw, wood
		description.LeftArmColor, description.RightArmColor = wood, wood
		description.LeftLegColor, description.RightLegColor = dark, dark
	end
	local model = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R6)
	model.Name = player.DisplayName .. "'s Performer"
	model:SetAttribute("ClassPuppet", true)
	model:SetAttribute("PerformerFor", player.UserId)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.BreakJointsOnDeath = false
	end
	for _, d in model:GetDescendants() do
		if d:IsA("Decal") and d.Name == "face" then
			d:Destroy() -- a dummy has no face
		end
	end
	model:PivotTo(at)
	local folder = workspace:FindFirstChild("Performers")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Performers"
		folder.Parent = workspace
	end
	model.Parent = folder
	local root = model:FindFirstChild("HumanoidRootPart")
	if root then
		pcall(root.SetNetworkOwner, root, nil)
	end
	return model
end

local function dropPerformer(session)
	if session.body then
		ClassService.ReleasePuppet(session.body)
		session.body:Destroy()
		session.body = nil
	end
end

-- a fresh body and a fresh copy of the class: every move starts clean (no cooldowns, no leftovers from the last one)
local function freshPerformer(player, session)
	dropPerformer(session)
	local at = markCF(session.mark)
	local body = performerBody(player, at)
	session.body = body
	session.puppet = session.puppet or ClassService.NewPuppet(player.DisplayName .. "'s Performer")
	ClassService.ApplyPuppet(session.puppet, body, session.class)
	body:PivotTo(at)
	remote:FireClient(player, "Performer", body)
	return body
end

local function aimFor(session, step, body)
	if step.aim == "Watcher" then
		local character = session.player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			return root.Position
		end
	elseif step.aim == "Sky" then
		local root = body:FindFirstChild("HumanoidRootPart")
		if root then
			return root.Position - root.CFrame.LookVector * 30 + Vector3.new(0, 90, 0)
		end
	elseif step.aim == "Cube" then
		local st = ClassService.State(body)
		local cube = st and st.Data and st.Data.Cube
		if cube and cube.Pos then
			return cube.Pos
		end
	end
	local target = workspace:FindFirstChild("ClassTrainingDummy")
	return target and target:GetPivot().Position or dummySpot.Position + Vector3.new(0, 4, 0)
end

local function face(body, aim)
	local root = body:FindFirstChild("HumanoidRootPart")
	if root and aim then
		local flat = Vector3.new(aim.X, root.Position.Y, aim.Z)
		if (flat - root.Position).Magnitude > 1 then
			root.CFrame = CFrame.lookAt(root.Position, flat)
		end
	end
end

local function perform(player, session, move)
	session.token += 1
	local token = session.token
	local body = freshPerformer(player, session)
	task.wait(0.35) -- the gear settles and every client binds the animator to the new body
	local function current()
		return session.token == token and sessions[player] == session and session.body == body and alive(body)
	end
	for _, step in move.Steps do
		if not current() then
			return
		end
		if step.wait then
			task.wait(step.wait)
		elseif step.untilStatus then
			local deadline = os.clock() + (step.timeout or 3)
			while current() and body:GetAttribute("ClassStatus_" .. step.untilStatus) == nil and os.clock() < deadline do
				task.wait(0.05)
			end
		elseif step.key then
			local aim = aimFor(session, step, body)
			face(body, aim)
			ClassService.PuppetAction(body, step.key, "Begin", aim)
			if step.hold and step.hold > 0.05 then
				local held = os.clock()
				while current() and os.clock() - held < step.hold do
					aim = aimFor(session, step, body)
					ClassService.PuppetAction(body, "Aim", "Hold", aim)
					task.wait(0.1)
				end
			else
				task.wait(0.05)
			end
			if current() then
				ClassService.PuppetAction(body, step.key, "End", aimFor(session, step, body))
			end
		end
	end
	if current() then
		remote:FireClient(player, "Done", move.Id)
	end
end

local function enter(player, classId)
	local character = player.Character
	if not alive(character) then
		return
	end
	if player:GetAttribute("PartyRoom") ~= nil or player:GetAttribute("PartyLocked") == true then
		reply(player, "Leave your party first.")
		return
	end
	areaRemote:FireClient(player, "FadeOut", "Stage")
	task.wait(FADE_TIME)
	character = player.Character
	if not alive(character) then
		areaRemote:FireClient(player, "FadeIn", player:GetAttribute("Area"))
		return
	end
	local session = { player = player, mark = freeMark(player), class = classId, token = 0 }
	sessions[player] = session
	-- you watch from the edge of the stage, standing still, as yourself
	local root = character.HumanoidRootPart
	character:PivotTo(watchCF(session.mark))
	root.Anchored = true
	player:SetAttribute("Area", "Stage")
	player:SetAttribute("TryoutClass", classId)
	freshPerformer(player, session)
	task.wait(0.25)
	areaRemote:FireClient(player, "FadeIn", "Stage")
end

local function leave(player)
	local session = sessions[player]
	areaRemote:FireClient(player, "FadeOut", "Hub")
	task.wait(FADE_TIME)
	sessions[player] = nil
	if session then
		session.token += 1
		dropPerformer(session)
	end
	player:SetAttribute("TryoutClass", nil)
	local character = player.Character
	local back = world:FindFirstChild("Shop") and world.Shop:FindFirstChild("ShopArrival")
	if character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.Anchored = false
		if back then
			character:PivotTo(back.CFrame + Vector3.new(0, 3, 0))
		end
	end
	player:SetAttribute("Area", "Hub")
	task.wait(0.25)
	areaRemote:FireClient(player, "FadeIn", "Hub")
end

remote.OnServerEvent:Connect(function(player, action, arg)
	if type(action) ~= "string" then
		return
	end
	local session = sessions[player]
	if action == "Perform" then
		local move = session and type(arg) == "string" and ShowcaseMoves.Find(session.class, arg)
		if move then
			task.spawn(perform, player, session, move)
		end
		return
	end
	if busy[player] then
		return
	end
	if (action == "Enter" or action == "Class") and (type(arg) ~= "string" or not ClassConfig.Classes[arg]) then
		return
	end
	busy[player] = true
	local ok, err = pcall(function()
		if action == "Enter" and not session then
			enter(player, arg)
		elseif (action == "Class" or action == "Enter") and session then
			session.class = arg
			session.token += 1
			player:SetAttribute("TryoutClass", arg)
			freshPerformer(player, session)
		elseif action == "Leave" and session then
			leave(player)
		end
	end)
	busy[player] = nil
	if not ok then
		warn("[Tryout] " .. tostring(err))
	end
end)

-- Dying, resetting or leaving takes the performer away.
local function onPlayer(player)
	player.CharacterAdded:Connect(function()
		local session = sessions[player]
		if session and not busy[player] then
			sessions[player] = nil
			session.token += 1
			dropPerformer(session)
			player:SetAttribute("TryoutClass", nil)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	sessions[player] = nil
	busy[player] = nil
	if session then
		session.token += 1
		dropPerformer(session)
	end
end)

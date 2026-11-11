--!nonstrict
--[[
 TutorialService - Azusa's training grounds (the Tutorial place; reached by asking Azusa in the lobby "Please teach me how to fight").
 Azusa is a real boss here, built on the shared fight layer every bossfight map uses (UnfairShared/BossKit): you are a Warrior
 with the Golden Encounter's own kit (click to slash, C and V skills, F to switch, R to guard, Q to dash, E to deflect), you have
 3 lives, HP and stamina, and she has an HP bar (and a shield in phase 2).
   Phase 1 (100% to 50%): every attack is a lesson. The first time she uses one she tells you what to do, out loud, the way
   alterGolden talks (BossKit.Say: typed at the bottom of the screen); after that she just calls its name.
   Phase 2 (below 50%): she raises a shield, gets faster, and adds the Rush and the Bloom.
   Deflect her Iai or a Rush cut and she staggers: "OPEN", her defence drops for a moment.
 Lose all your lives and she picks you up and starts again. Beat her and she sends you back with her blessing.
   Tutorial remote  client -> server: "Begin" | "Leave"
                    server -> client: "Exposed", seconds | "Started" | "Won" | "Lost"
                                      | "FX", kind, data   (Shake { At, Power }, ImpactFrame { Strong }, Focus { Seconds }, Sky { On })
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local Config = require(Shared:WaitForChild("UnfairConfig"))
local BossKit = require(Shared:WaitForChild("BossKit"))
local Azusa = require(script.Parent.Azusa)
local Attacks = require(script.Parent.AzusaAttacks)

local remote = Instance.new("RemoteEvent")
remote.Name = "Tutorial"
remote.Parent = ReplicatedStorage

local MAX_HEALTH = 9000
local PHASE2_SHIELD = 1600
local PINK = Color3.fromRGB(255, 120, 180)

BossKit.Start({ Lives = 3, Class = "Warrior" })

local world = workspace:WaitForChild("World", 30)
local center = world and world:WaitForChild("ArenaCenter", 30)
local CENTER = center and center.Position or Vector3.zero
local fence = world and world:FindFirstChild("Fence")

local fight = nil -- { player, token, phase, shown = {}, exposedUntil }
local hintsShown: { [string]: boolean } = {}

local function gate(closed)
	for _, wall in fence and fence:GetChildren() or {} do
		if wall:GetAttribute("Gate") then
			wall.CanCollide = closed
		end
	end
end

local function say(text, player)
	return BossKit.Say(text, nil, player)
end

local function home()
	return CFrame.lookAt(CENTER + Vector3.new(0, 0, -20), CENTER + Vector3.new(0, 0, 60))
end

local model
local function spawnAzusa()
	model = Azusa.Build(home())
	if not model then
		return
	end
	BossKit.Register(model, { Title = "Azusa", Subtitle = "the Blossom Blade", MaxHealth = MAX_HEALTH, Shield = 0, Color = PINK })
	model:SetAttribute("BossHidden", true)
	model:SetAttribute("BossPhases", 2)
	model:SetAttribute("BossPhase", 1)
	model:SetAttribute("Invulnerable", true) -- not until the fight starts
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = "Azusa"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = Azusa.Root()
	model:FindFirstChildOfClass("Humanoid").HealthChanged:Connect(function(hp)
		if fight and fight.phase == 1 and hp <= MAX_HEALTH * 0.5 then
			fight.phase = 2
			fight.phaseChanged = true
		end
	end)
end
spawnAzusa()

local function stopped(token)
	return function()
		return not fight or fight.token ~= token or not Azusa.Alive()
	end
end

local function exposed(seconds)
	if not fight or not model then
		return
	end
	fight.exposedUntil = os.clock() + seconds
	model:SetAttribute("Defense", -0.5) -- takes 50% more while staggered
	remote:FireClient(fight.player, "Exposed", seconds)
	if not hintsShown["Open"] then
		hintsShown["Open"] = true
		say("Ngh-! You turned it aside. Now hit me while I'm open: click, then C and V!")
	else
		say("Tch.")
	end
	task.delay(seconds, function()
		if fight and os.clock() >= (fight.exposedUntil or 0) and model then
			model:SetAttribute("Defense", 0)
		end
	end)
end

local function context(token)
	local ctx = { Kit = BossKit, Azusa = Azusa, Phase = fight.phase, Speed = fight.phase == 2 and 1.25 or 1 }
	ctx.Stopped = stopped(token)
	ctx.Exposed = exposed
	-- the first time: the lesson; after that one of her quips (or `lesson` alone when there is no id)
	ctx.Say = function(id, lesson, quips)
		if not fight then
			return
		end
		if id == nil then
			say(lesson)
		elseif not hintsShown[id] then
			hintsShown[id] = true
			say(lesson)
		elseif quips and math.random() < 0.7 then
			say(quips[math.random(1, #quips)])
		end
	end
	ctx.FX = function(kind, data)
		remote:FireAllClients("FX", kind, data)
	end
	return ctx
end

local LESSONS = { "Sigils", "Crescent", "Iai", "Thorns", "PetalFan" }
local PHASE2 = { "Rush", "Crescent", "Iai", "Sigils", "Thorns", "PetalFan", "Rush", "Bloom" }

-- Keeps a fighting distance from the player between attacks.
local function reposition(ctx, target)
	local root, r = Azusa.Root(), target:FindFirstChild("HumanoidRootPart")
	if not root or not r then
		return
	end
	local away = (root.Position - r.Position) * Vector3.new(1, 0, 1)
	away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, -1)
	local side = Vector3.new(-away.Z, 0, away.X) * (math.random() < 0.5 and -1 or 1)
	local spot = r.Position + (away * 26 + side * math.random(6, 16))
	spot = Vector3.new(spot.X, 0, spot.Z)
	if spot.Magnitude > 60 then
		spot = spot.Unit * 60
	end
	if math.random() < 0.3 then
		Azusa.Blink(spot, r.Position)
	else
		Azusa.MoveTo(spot, nil, r.Position)
	end
	return not ctx.Stopped()
end

local function phaseTwo(ctx)
	Azusa.Charge(1.4)
	say("Not bad! Now I stop holding back.")
	model:SetAttribute("BossPhase", 2)
	model:SetAttribute("Invulnerable", true)
	Azusa.MoveTo(CENTER, 0.8)
	Azusa.Play("Summon", 2)
	task.wait(1.8)
	BossKit.SetShield(model, PHASE2_SHIELD)
	model:SetAttribute("Invulnerable", false)
	say("See that white bar over my health? That's my shield. Break it first!")
	return not ctx.Stopped()
end

local function runFight(player, token)
	local order = 0
	while fight and fight.token == token and Azusa.Alive() do
		local char = player.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") or player:GetAttribute("PermanentlyDefeated") then
			task.wait(0.3)
		else
			if fight.phaseChanged then
				fight.phaseChanged = false
				phaseTwo(context(token))
			end
			local ctx = context(token)
			order += 1
			local list = fight.phase == 2 and PHASE2 or LESSONS
			local name = list[(order - 1) % #list + 1]
			if fight.phase == 1 and order > #LESSONS and math.random() < 0.5 then
				name = LESSONS[math.random(1, #LESSONS)]
			end
			local ok, err = pcall(Attacks[name], ctx, char)
			if not ok then
				warn("[Azusa] " .. name .. ": " .. tostring(err))
			end
			if ctx.Stopped() then
				break
			end
			local rest = fight.phase == 2 and 0.6 or 1.1
			-- while she is staggered she does not attack
			while fight and fight.token == token and os.clock() < (fight.exposedUntil or 0) do
				task.wait(0.1)
			end
			reposition(ctx, char)
			task.wait(rest)
		end
	end
end

local function begin(player)
	if fight or not model or not Azusa.Alive() then
		return
	end
	local token = {}
	fight = { player = player, token = token, phase = 1 }
	hintsShown = {}
	local h = model:FindFirstChildOfClass("Humanoid")
	h.Health = h.MaxHealth
	model:SetAttribute("Shield", 0)
	model:SetAttribute("MaxShield", 0)
	model:SetAttribute("BossPhase", 1)
	model:SetAttribute("Defense", 0)
	-- everyone starts inside the arena, facing her, before the gate closes
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char:PivotTo(CFrame.lookAt(CENTER + Vector3.new(0, 3.2, 34), CENTER + Vector3.new(0, 3.2, -20)))
	end
	gate(true)
	-- no "E: Talk" over her while you fight (E is deflect)
	local prompt = Azusa.Root() and Azusa.Root():FindFirstChild("TalkPrompt")
	if prompt then
		prompt.Enabled = false
	end
	BossKit.Begin()
	remote:FireClient(player, "Started")
	say("Show me what you've got! Everything I throw flashes before it lands, so watch closely.")
	Azusa.Play("Point", 1.4)
	task.wait(1.4)
	model:SetAttribute("BossHidden", false)
	model:SetAttribute("Invulnerable", false)
	task.spawn(runFight, player, token)
end

local function finish(won)
	local f = fight
	fight = nil
	BossKit.End()
	gate(false)
	for _, d in workspace:FindFirstChild("AzusaFXLive") and workspace.AzusaFXLive:GetChildren() or {} do
		d:Destroy()
	end
	if not f then
		return
	end
	local player = f.player
	if won then
		player:SetAttribute("TutorialDone", true)
		remote:FireClient(player, "Won")
		task.wait(0.5)
		spawnAzusa()
		Azusa.Play("Kneel", 3)
		say("Hah... you really did it. You're ready for him. Go show him what I taught you!")
	else
		remote:FireClient(player, "Lost")
		say("Up you get! Again, from the top.")
		task.wait(3)
		if player.Parent == Players then
			BossKit.Revive(player, 3)
		end
		spawnAzusa()
	end
end

-- she falls: the fight is won
RunService.Heartbeat:Connect(function()
	if fight and model and model.Parent then
		local h = model:FindFirstChildOfClass("Humanoid")
		if h and h.Health <= 0 then
			task.spawn(finish, true)
		end
	end
end)

-- out of lives: lost. A life lost mid-fight brings you back inside the arena, not on the spawn island behind the closed gate.
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		if fight and fight.player == player then
			local root = char:WaitForChild("HumanoidRootPart", 5)
			task.wait(0.1)
			if root and fight and fight.player == player then
				char:PivotTo(CFrame.lookAt(CENTER + Vector3.new(0, 3.2, 40), CENTER + Vector3.new(0, 3.2, 0)))
			end
		end
	end)
	player:GetAttributeChangedSignal("PermanentlyDefeated"):Connect(function()
		if player:GetAttribute("PermanentlyDefeated") and fight and fight.player == player then
			task.spawn(finish, false)
		end
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	if fight and fight.player == player then
		finish(false)
	end
end)

local function toLobby(player)
	if RunService:IsStudio() then
		say("(Studio) would send you back to the lobby now.", player)
		return
	end
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ from = "Tutorial", done = player:GetAttribute("TutorialDone") == true })
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, Config.LobbyPlaceId(), { player }, options)
	if not ok then
		warn("[Tutorial] teleport failed: " .. tostring(err))
		say("The way back is closed right now. Try again in a moment.", player)
	end
end

remote.OnServerEvent:Connect(function(player, action)
	if action == "Begin" then
		begin(player)
	elseif action == "Leave" then
		if fight and fight.player == player then
			finish(false)
		end
		toLobby(player)
	end
end)

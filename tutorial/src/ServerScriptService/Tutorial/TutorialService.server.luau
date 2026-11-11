--!nonstrict
--[[
 TutorialService - Azusa's training grounds (the Tutorial place; reached by asking Azusa in the lobby "Please teach me how to fight").
 Azusa (the Roblox avatar of mymeo125) is the guide and the boss. Her attacks are small versions of alterGolden's, each one a lesson:
   1 Circles   red circles burst where you stand: step out of them
   2 Dash      a golden slash wave crosses the arena, too tall to jump: press Q to dash through it (you cannot be hurt while dashing)
   3 Guard     she charges a heavy strike at you: hold R to guard it
   4 Jump      shockwave rings run along the ground: jump over them
   5 Bullets   fans of golden shots: keep moving sideways
   6 Punish    after her combo she is open for a moment: click to hit her
   7 Exam      everything at once, a little faster
 Getting hurt never kills you here: drop low and she heals you and runs the lesson again. One player per server (the place's server
 size is 1), so the lessons follow that one player.
   Tutorial remote  client -> server: "Begin" | "Leave" | "Dash" | "Block", on | "Attack"
                    server -> client: "Lesson", { Index, Count, Title, Hint, Progress } | "Say", text | "Done" | "Hurt"
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("UnfairShared"):WaitForChild("UnfairConfig"))

local remote = Instance.new("RemoteEvent")
remote.Name = "Tutorial"
remote.Parent = ReplicatedStorage

local world = workspace:WaitForChild("World", 30)
local arenaCenter = world and world:WaitForChild("ArenaCenter", 30)
local CENTER = arenaCenter and arenaCenter.Position or Vector3.new(0, 0, 0)
local RADIUS = 62
local GOLD, RED, WHITE = Color3.fromRGB(255, 205, 90), Color3.fromRGB(255, 70, 70), Color3.new(1, 1, 1)
local fx = Instance.new("Folder")
fx.Name = "TutorialFX"
fx.Parent = workspace

-- Azusa ----------------------------------------------------------------------------------------------------------------
local azusa
local function buildAzusa()
	local okId, userId = pcall(Players.GetUserIdFromNameAsync, Players, "mymeo125")
	local description
	if okId then
		local ok, d = pcall(Players.GetHumanoidDescriptionFromUserIdAsync, Players, userId)
		description = ok and d or nil
	end
	description = description or Instance.new("HumanoidDescription")
	local ok, model = pcall(Players.CreateHumanoidModelFromDescriptionAsync, Players, description, Enum.HumanoidRigType.R15)
	if not ok then
		warn("[Tutorial] could not build Azusa: " .. tostring(model))
		return nil
	end
	model.Name = "Azusa"
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = "Azusa"
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.NameDisplayDistance = 60
	local root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true
	local home = CFrame.lookAt(CENTER + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0), CENTER + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 40))
	model:PivotTo(home)
	model:SetAttribute("Home", home)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = "Azusa"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	local glow = Instance.new("Highlight")
	glow.Name = "Charge"
	glow.FillColor, glow.OutlineColor = GOLD, WHITE
	glow.FillTransparency, glow.OutlineTransparency = 1, 1
	glow.Parent = model
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local idle = Instance.new("Animation")
	idle.AnimationId = "rbxassetid://507766388"
	local okTrack, track = pcall(animator.LoadAnimation, animator, idle)
	if okTrack then
		track.Looped = true
		track:Play()
	end
	model.Parent = world
	return model
end
azusa = buildAzusa()

local function azusaRoot()
	return azusa and azusa:FindFirstChild("HumanoidRootPart")
end

local function charge(on, color)
	local h = azusa and azusa:FindFirstChild("Charge")
	if h then
		h.FillColor = color or GOLD
		TweenService:Create(h, TweenInfo.new(0.25), { FillTransparency = on and 0.45 or 1, OutlineTransparency = on and 0 or 1 }):Play()
	end
end

local function faceTo(pos)
	local root = azusaRoot()
	if root then
		local p = root.Position
		root.CFrame = CFrame.lookAt(p, Vector3.new(pos.X, p.Y, pos.Z))
	end
end

-- helpers ------------------------------------------------------------------------------------------------------------------
local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in props do
		p[k] = v
	end
	p.Parent = fx
	return p
end

local function now()
	return workspace:GetServerTimeNow()
end

local session -- { player, hurtThisLesson, token }

local function alive(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
end

-- a hit on the player: dashing makes you untouchable, guarding takes 75% off
local function hurt(player, amount, guardable)
	local character, humanoid = alive(player)
	if not character then
		return false
	end
	if now() < (character:GetAttribute("IFrameUntil") or 0) then
		remote:FireClient(player, "Say", "Dodged!")
		return false
	end
	if guardable and character:GetAttribute("Blocking") then
		amount *= 0.25
		character:SetAttribute("Guarded", (character:GetAttribute("Guarded") or 0) + 1)
	end
	humanoid.Health = math.max(1, humanoid.Health - amount)
	if session then
		session.hurt += amount
	end
	remote:FireClient(player, "Hurt", amount)
	return true
end

local function say(player, text)
	remote:FireClient(player, "Say", text)
end

local function lesson(player, index, count, title, hint, progress)
	remote:FireClient(player, "Lesson", { Index = index, Count = count, Title = title, Hint = hint, Progress = progress })
end

-- the attacks --------------------------------------------------------------------------------------------------------------
local function circles(player, n, delay, radius)
	local _, _, root = alive(player)
	if not root then
		return
	end
	local spots = {}
	local v = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	for i = 1, n do
		local guess = root.Position + v * 0.4 + (i == 1 and Vector3.zero or Vector3.new(math.random(-18, 18), 0, math.random(-18, 18)))
		local flat = Vector3.new(guess.X, CENTER.Y + 0.15, guess.Z)
		local disc = part({ Shape = Enum.PartType.Cylinder, Color = RED, Transparency = 0.55, Size = Vector3.new(0.2, radius * 2, radius * 2), CFrame = CFrame.new(flat) * CFrame.Angles(0, 0, math.rad(90)) })
		table.insert(spots, { disc = disc, at = flat })
	end
	task.wait(delay)
	for _, s in spots do
		s.disc.Transparency = 0.05
		s.disc.Color = Color3.fromRGB(255, 220, 160)
		local _, _, r = alive(player)
		if r then
			local d = Vector3.new(r.Position.X - s.at.X, 0, r.Position.Z - s.at.Z).Magnitude
			if d < radius and r.Position.Y < s.at.Y + 8 then
				hurt(player, 18, false)
			end
		end
		TweenService:Create(s.disc, TweenInfo.new(0.3), { Transparency = 1, Size = Vector3.new(0.2, radius * 2.6, radius * 2.6) }):Play()
		game:GetService("Debris"):AddItem(s.disc, 0.35)
	end
end

-- a tall wall of light sweeping across the whole arena toward the player: only a dash gets you through
local function wave(player, speed)
	local _, _, root = alive(player)
	if not root then
		return
	end
	local dir = Vector3.new(root.Position.X - CENTER.X, 0, root.Position.Z - CENTER.Z)
	dir = dir.Magnitude > 1 and dir.Unit or Vector3.new(0, 0, 1)
	local side = dir:Cross(Vector3.yAxis)
	local start = CENTER - dir * (RADIUS + 4)
	local wall = part({ Color = GOLD, Transparency = 0.25, Size = Vector3.new(RADIUS * 2.4, 16, 1.2), CFrame = CFrame.lookAt(start + Vector3.new(0, 8, 0), start + Vector3.new(0, 8, 0) + dir) })
	charge(true)
	task.wait(0.9)
	charge(false)
	local travelled, hit = 0, false
	local last = os.clock()
	while travelled < RADIUS * 2 + 8 do
		local dt = task.wait()
		travelled += speed * dt
		local at = start + dir * travelled
		wall.CFrame = CFrame.lookAt(at + Vector3.new(0, 8, 0), at + Vector3.new(0, 8, 0) + dir)
		local _, _, r = alive(player)
		if r and not hit then
			local along = (r.Position - at):Dot(dir)
			if math.abs(along) < 2.2 and r.Position.Y < CENTER.Y + 16 then
				hit = true
				if not hurt(player, 26, false) then
					session.dodged = (session.dodged or 0) + 1
				end
			end
		end
		last = os.clock()
	end
	wall:Destroy()
	return hit
end

local function strike(player)
	local _, _, root = alive(player)
	local aroot = azusaRoot()
	if not root or not aroot then
		return
	end
	faceTo(root.Position)
	charge(true, RED)
	local line = part({ Color = RED, Transparency = 0.5, Size = Vector3.new(4, 0.2, 1) })
	local t0 = os.clock()
	while os.clock() - t0 < 1.3 do
		local _, _, r = alive(player)
		if not r then
			break
		end
		faceTo(r.Position)
		local from, to = aroot.Position, r.Position
		local flat = Vector3.new(to.X, CENTER.Y + 0.2, to.Z) - Vector3.new(from.X, CENTER.Y + 0.2, from.Z)
		line.Size = Vector3.new(4, 0.2, flat.Magnitude)
		line.CFrame = CFrame.lookAt(Vector3.new(from.X, CENTER.Y + 0.2, from.Z) + flat / 2, Vector3.new(to.X, CENTER.Y + 0.2, to.Z))
		task.wait()
	end
	line:Destroy()
	charge(false)
	-- a flash of gold from her to you
	local _, _, r = alive(player)
	if r then
		local from = aroot.Position
		local beam = part({ Color = GOLD, Transparency = 0.1, Size = Vector3.new(1.4, 1.4, (r.Position - from).Magnitude), CFrame = CFrame.lookAt((from + r.Position) / 2, r.Position) })
		TweenService:Create(beam, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		game:GetService("Debris"):AddItem(beam, 0.4)
		local guardedBefore = player.Character:GetAttribute("Guarded") or 0
		hurt(player, 40, true)
		return (player.Character and player.Character:GetAttribute("Guarded") or 0) > guardedBefore
	end
end

local function rings(player, count, gap)
	for _ = 1, count do
		task.spawn(function()
			local segments = {}
			for i = 1, 40 do
				segments[i] = part({ Color = GOLD, Size = Vector3.new(3.2, 1.6, 1) })
			end
			local radius, hit = 2, false
			while radius < RADIUS + 4 do
				local dt = task.wait()
				radius += 26 * dt
				for i, s in segments do
					local a = i / #segments * math.pi * 2
					local p = CENTER + Vector3.new(math.cos(a) * radius, 0.8, math.sin(a) * radius)
					s.CFrame = CFrame.lookAt(p, CENTER + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, math.rad(90), 0)
					s.Size = Vector3.new(2 * math.pi * radius / #segments + 0.3, 1.6, 1)
				end
				local _, _, r = alive(player)
				if r and not hit then
					local d = Vector3.new(r.Position.X - CENTER.X, 0, r.Position.Z - CENTER.Z).Magnitude
					if math.abs(d - radius) < 1.6 and r.Position.Y - CENTER.Y < 4.6 then
						hit = true
						hurt(player, 20, false)
					end
				end
			end
			for _, s in segments do
				s:Destroy()
			end
		end)
		task.wait(gap)
	end
	task.wait(RADIUS / 26)
end

local function bullets(player, volleys)
	local aroot = azusaRoot()
	for _ = 1, volleys do
		local _, _, root = alive(player)
		if not root or not aroot then
			return
		end
		faceTo(root.Position)
		charge(true)
		task.wait(0.5)
		charge(false)
		local from = aroot.Position
		local aim = Vector3.new(root.Position.X - from.X, 0, root.Position.Z - from.Z).Unit
		for k = -3, 3 do
			local dir = CFrame.Angles(0, math.rad(k * 9), 0):VectorToWorldSpace(aim)
			task.spawn(function()
				local b = part({ Shape = Enum.PartType.Ball, Color = GOLD, Size = Vector3.new(1.6, 1.6, 1.6) })
				local pos = Vector3.new(from.X, root.Position.Y, from.Z)
				for _ = 1, 160 do
					local dt = task.wait()
					pos += dir * 70 * dt
					b.CFrame = CFrame.new(pos)
					local _, _, r = alive(player)
					if r and (r.Position - pos).Magnitude < 2.6 then
						hurt(player, 12, true)
						break
					end
					if (pos - CENTER).Magnitude > RADIUS + 10 then
						break
					end
				end
				b:Destroy()
			end)
		end
		task.wait(1.1)
	end
end

-- the lessons ---------------------------------------------------------------------------------------------------------------
local LESSONS
local function healIfLow(player)
	local _, humanoid = alive(player)
	if humanoid and humanoid.Health < humanoid.MaxHealth * 0.25 then
		humanoid.Health = humanoid.MaxHealth
		return true
	end
	return false
end

LESSONS = {
	{ Title = "Circles", Hint = "Red circles burst where you stand. Step out before they do.", Intro = { "Lesson one. Watch the floor.", "When a red circle shows up under you, get out of it before it bursts!" },
		Run = function(player)
			for wave_ = 1, 4 do
				circles(player, 3 + wave_, 1.4 - wave_ * 0.12, 7)
				lesson(player, 1, #LESSONS, "Circles", nil, wave_ / 4)
				task.wait(0.6)
			end
			return session.hurt < 40
		end },
	{ Title = "Dash", Hint = "Press Q to dash through the golden wave. You can't be hurt while dashing.", Intro = { "Some things you can't walk away from.", "When the golden wave comes, press Q and dash straight through it. Dashing makes you untouchable for a moment." },
		Run = function(player)
			session.dodged = 0
			for i = 1, 4 do
				wave(player, 46)
				lesson(player, 2, #LESSONS, "Dash", nil, i / 4)
				task.wait(0.8)
			end
			return session.dodged >= 2
		end },
	{ Title = "Guard", Hint = "When I glow red and point at you, hold R to guard.", Intro = { "Now a heavy one. I'll point at you first, glowing red.", "Hold R to guard. You'll still feel it, but much less." },
		Run = function(player)
			local guarded = 0
			for i = 1, 3 do
				if strike(player) then
					guarded += 1
				end
				lesson(player, 3, #LESSONS, "Guard", nil, i / 3)
				task.wait(1)
			end
			return guarded >= 2
		end },
	{ Title = "Jump", Hint = "Jump (Space) over the golden rings running along the ground.", Intro = { "These rings run along the ground.", "Jump over them as they reach you. Space!" },
		Run = function(player)
			rings(player, 5, 1.3)
			lesson(player, 4, #LESSONS, "Jump", nil, 1)
			return session.hurt < 40
		end },
	{ Title = "Bullets", Hint = "Keep moving sideways. Don't run straight at or away from me.", Intro = { "He loves shooting. So do I.", "Keep moving sideways and the shots will pass you." },
		Run = function(player)
			bullets(player, 4)
			lesson(player, 5, #LESSONS, "Bullets", nil, 1)
			return session.hurt < 50
		end },
	{ Title = "Punish", Hint = "After my combo I'm open: run in and click to hit me.", Intro = { "Every attack ends. When it does, I'm open.", "When I'm dizzy, run in and click to hit me. Three hits!" },
		Run = function(player)
			session.hits = 0
			for round = 1, 3 do
				circles(player, 4, 1.1, 7)
				local aroot = azusaRoot()
				if azusa then
					azusa:SetAttribute("Exposed", true)
				end
				charge(true, Color3.fromRGB(120, 200, 255))
				say(player, "Now! I'm open!")
				local t0 = os.clock()
				while os.clock() - t0 < 4 and session.hits < round do
					task.wait(0.1)
				end
				if azusa then
					azusa:SetAttribute("Exposed", false)
				end
				charge(false)
				lesson(player, 6, #LESSONS, "Punish", nil, session.hits / 3)
				task.wait(0.6)
			end
			return session.hits >= 3
		end },
	{ Title = "Exam", Hint = "Everything at once. Circles, waves, strikes, rings, bullets.", Intro = { "Final exam. Everything I showed you, a little faster.", "Ready? Don't think. Move!" },
		Run = function(player)
			circles(player, 5, 1.0, 7)
			wave(player, 54)
			task.spawn(rings, player, 2, 1.4)
			bullets(player, 2)
			strike(player)
			circles(player, 6, 0.9, 7)
			wave(player, 58)
			lesson(player, 7, #LESSONS, "Exam", nil, 1)
			return session.hurt < 90
		end },
}

local function runLessons(player)
	session = { player = player, hurt = 0, token = (session and session.token or 0) + 1 }
	local token = session.token
	local index = 1
	while index <= #LESSONS do
		if not session or session.token ~= token or player.Parent ~= Players then
			return
		end
		local l = LESSONS[index]
		lesson(player, index, #LESSONS, l.Title, l.Hint, 0)
		for _, line in l.Intro do
			say(player, line)
			task.wait(math.clamp(#line / 20, 1.6, 4))
		end
		local _, humanoid = alive(player)
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
		session.hurt = 0
		local ok, passed = pcall(l.Run, player)
		if not ok then
			warn("[Tutorial] lesson " .. index .. ": " .. tostring(passed))
			passed = true
		end
		healIfLow(player)
		if passed then
			say(player, ({ "Nice!", "That's it!", "Good, good.", "See? Easy.", "Perfect!" })[math.random(5)])
			index += 1
		else
			say(player, "Ouch. Let's try that one again!")
			local _, h = alive(player)
			if h then
				h.Health = h.MaxHealth
			end
		end
		task.wait(1.6)
	end
	-- back home
	local aroot = azusaRoot()
	if aroot and azusa:GetAttribute("Home") then
		aroot.CFrame = azusa:GetAttribute("Home")
	end
	player:SetAttribute("TutorialDone", true)
	remote:FireClient(player, "Done")
	session = nil
end

local function toLobby(player)
	if RunService:IsStudio() then
		say(player, "(Studio) I'd send you back to the Sanctum now.")
		return
	end
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ from = "Tutorial", done = player:GetAttribute("TutorialDone") == true })
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, Config.LobbyPlaceId(), { player }, options)
	if not ok then
		warn("[Tutorial] teleport failed: " .. tostring(err))
		say(player, "The way back is stuck. Try again in a moment.")
	end
end

local lastAttack, lastDash = {}, {}
remote.OnServerEvent:Connect(function(player, action, arg)
	local character = player.Character
	if action == "Begin" then
		if not session then
			task.spawn(runLessons, player)
		end
	elseif action == "Leave" then
		if session then
			session.token += 1
			session = nil
		end
		toLobby(player)
	elseif action == "Dash" and character then
		if os.clock() - (lastDash[player] or 0) > 0.9 then
			lastDash[player] = os.clock()
			character:SetAttribute("IFrameUntil", now() + 0.42)
		end
	elseif action == "Block" and character then
		character:SetAttribute("Blocking", arg == true or nil)
	elseif action == "Attack" and character then
		if os.clock() - (lastAttack[player] or 0) < 0.35 then
			return
		end
		lastAttack[player] = os.clock()
		local root = character:FindFirstChild("HumanoidRootPart")
		local aroot = azusaRoot()
		if root and aroot and (root.Position - aroot.Position).Magnitude < 13 then
			if azusa:GetAttribute("Exposed") and session then
				session.hits = (session.hits or 0) + 1
				local spark = part({ Shape = Enum.PartType.Ball, Color = WHITE, Size = Vector3.new(2, 2, 2), CFrame = aroot.CFrame })
				TweenService:Create(spark, TweenInfo.new(0.3), { Size = Vector3.new(7, 7, 7), Transparency = 1 }):Play()
				game:GetService("Debris"):AddItem(spark, 0.35)
				say(player, ({ "Ow!", "Hey!", "Good hit!" })[math.random(3)])
			else
				say(player, "Not yet! Wait until I'm open.")
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if session and session.player == player then
		session.token += 1
		session = nil
	end
	lastAttack[player], lastDash[player] = nil, nil
end)

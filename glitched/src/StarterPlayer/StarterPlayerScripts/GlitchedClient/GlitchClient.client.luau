--!nonstrict
--[[
 The glitched place, client side.
   * Everything is broken: no colour, the screen tears, the camera twitches, limbs and road tiles skip, stray words flash up.
   * The man at the end of the road talks in broken words (UnfairShared/NpcDialog with a scrambler). With the Reality Orb you can
     give it to him: he takes it, rises into the sky and rips a hole in it; the hole pulls you in. "Thank you..." - and the server
     sends you back to the lobby with the Reality Disorderer unlocked (GlitchService).
]]
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local NpcDialog = require(Shared.NpcDialog)
local InventoryUI = require(Shared.InventoryUI)
local remote = ReplicatedStorage:WaitForChild("Glitch")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local rng = Random.new()
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.fromRGB(6, 6, 8)
local inCutscene = false

InventoryUI.Mount()

-- the look -------------------------------------------------------------------------------------------------------------
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "GlitchGrade"
grade.Saturation = -1
grade.Contrast = 0.32
grade.Brightness = 0.02
grade.Parent = Lighting
local blur = Instance.new("BlurEffect")
blur.Name = "GlitchBlur"
blur.Size = 0
blur.Parent = Lighting

local gui = Instance.new("ScreenGui")
gui.Name = "GlitchScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")

local bars = {}
for i = 1, 7 do
	local bar = Instance.new("Frame")
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = gui
	bars[i] = bar
end
local word = Instance.new("TextLabel")
word.BackgroundTransparency = 1
word.Font = Enum.Font.Code
word.TextSize = 42
word.TextColor3 = WHITE
word.TextStrokeTransparency = 0
word.Size = UDim2.fromOffset(600, 50)
word.Visible = false
word.Parent = gui
local WORDS = { "!A GL!TC3D PL@CE!", "R3TURN", "wh3r3 4m 1", "k33p w4lk1ng", "##########", "N0T R34L", "h3 1s w41t1ng", "0RB", "3RR0R", "th1s 1s f1n3" }

local SYMBOLS = { "#", "@", "!", "$", "%", "&", "0", "1", "|", "/", "?", "_" }
local function scramble(text)
	local out = {}
	for _, code in utf8.codes(text) do
		local ch = utf8.char(code)
		local roll = rng:NextNumber()
		if ch ~= " " and roll < 0.09 then
			ch = SYMBOLS[rng:NextInteger(1, #SYMBOLS)]
		elseif roll < 0.14 then
			ch = ch:upper()
		end
		table.insert(out, ch)
		if roll > 0.985 then
			table.insert(out, ch) -- a stutter
		end
	end
	return table.concat(out)
end

-- tears, words, camera twitches
RunService.RenderStepped:Connect(function()
	for _, bar in bars do
		if rng:NextNumber() < 0.045 then
			bar.Visible = true
			bar.BackgroundColor3 = rng:NextNumber() < 0.5 and WHITE or BLACK
			bar.BackgroundTransparency = rng:NextNumber(0, 0.5)
			bar.Position = UDim2.new(rng:NextNumber(-0.2, 0.4), 0, rng:NextNumber(), 0)
			bar.Size = UDim2.new(rng:NextNumber(0.3, 1.2), 0, 0, rng:NextInteger(2, 26))
		else
			bar.Visible = bar.Visible and rng:NextNumber() < 0.5
		end
	end
	if rng:NextNumber() < 0.006 then
		word.Text = scramble(WORDS[rng:NextInteger(1, #WORDS)])
		word.Position = UDim2.new(rng:NextNumber(0.05, 0.6), 0, rng:NextNumber(0.1, 0.85), 0)
		word.Visible = true
		task.delay(rng:NextNumber(0.05, 0.25), function()
			word.Visible = false
		end)
	end
	if rng:NextNumber() < 0.01 then
		grade.TintColor = rng:NextNumber() < 0.5 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
		grade.Contrast = rng:NextNumber(0.2, 0.9)
		task.delay(0.06, function()
			grade.TintColor = WHITE
			grade.Contrast = 0.32
		end)
	end
end)
RunService:BindToRenderStep("GlitchCamera", Enum.RenderPriority.Camera.Value + 1, function()
	if inCutscene then
		return
	end
	if rng:NextNumber() < 0.04 then
		camera.CFrame = camera.CFrame * CFrame.Angles(rng:NextNumber(-0.03, 0.03), rng:NextNumber(-0.03, 0.03), rng:NextNumber(-0.08, 0.08))
	end
end)

-- limbs skip and the road shivers
local world = workspace:WaitForChild("World", 30)
local road = world and world:FindFirstChild("Road")
local roadParts = road and road:GetDescendants() or {}
task.spawn(function()
	while true do
		task.wait(0.12)
		for _, other in Players:GetPlayers() do
			local character = other.Character
			if character and rng:NextNumber() < 0.5 then
				local limbs = {}
				for _, p in character:GetChildren() do
					if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
						table.insert(limbs, p)
					end
				end
				local limb = limbs[rng:NextInteger(1, math.max(1, #limbs))]
				if limb then
					limb.LocalTransparencyModifier = 1
					task.delay(rng:NextNumber(0.03, 0.12), function()
						limb.LocalTransparencyModifier = 0
					end)
				end
			end
		end
		for _ = 1, 3 do
			local part = roadParts[rng:NextInteger(1, math.max(1, #roadParts))]
			if part and part:IsA("BasePart") then
				local home = part.CFrame
				part.CFrame = home * CFrame.new(rng:NextNumber(-1.2, 1.2), rng:NextNumber(-0.6, 0.6), rng:NextNumber(-1.2, 1.2))
				task.delay(rng:NextNumber(0.05, 0.2), function()
					part.CFrame = home
				end)
			end
		end
	end
end)

-- the man ----------------------------------------------------------------------------------------------------------------
local man = world and world:WaitForChild("GlitchedMan", 30)
local talking = false

local function say(d, lines)
	for _, line in lines do
		if not d:Say(line) then
			return false
		end
	end
	return true
end

local pendingState
remote.OnClientEvent:Connect(function(action, data)
	if action == "State" then
		pendingState = data
	elseif action == "Message" then
		local d = NpcDialog.Current()
		if d then
			task.spawn(d.Say, d, data, 3)
		else
			InventoryUI.Toast(scramble(tostring(data)), 5)
		end
	elseif action == "Cutscene" then
		task.spawn(function()
			local playScene = _G.GlitchCutscene
			if playScene then
				playScene(data)
			end
		end)
	end
end)

local nextTalk = 0
local function talk()
	if talking or inCutscene or not man or os.clock() < nextTalk then
		return
	end
	talking = true
	pendingState = nil
	remote:FireServer("Talk")
	local d = NpcDialog.Open(man, { Name = scramble("???"), Color = Color3.fromRGB(235, 235, 235), Font = Enum.Font.Code, Glitch = scramble, Speed = 30 })
	local waited = 0
	while not pendingState and waited < 8 and d:IsOpen() do
		waited += task.wait(0.1)
	end
	local state = pendingState or {}
	if state.Failed then
		say(d, { "...1 c4n't s33 y0u. c0m3 b4ck l4t3r." })
	elseif state.HasOrb then
		if say(d, { "...y0u.", "y0u h4v3 1t. 1 c4n f33l 1t hum.", "th3 R3al1ty 0rb... g1v3 1t t0 m3?" }) then
			local pick = d:Choose({ "Give him the Reality Orb", "Not yet" })
			if pick == 1 then
				d:Say("...", 0.6)
				remote:FireServer("Give")
			elseif pick == 2 then
				d:Say("...1 w1ll w41t. 1 4lw4ys w41t.")
			end
		end
	elseif state.Freed then
		say(d, { "...y0u 4lr34dy s3t m3 fr33.", "s0 why 4m 1 st1ll h3r3?", "...g0 h0m3." })
	else
		say(d, {
			"...h-h3ll0?",
			"s0m30n3... c4m3 4ll th1s w4y.",
			"th1s pl4c3 1s br0k3n. 1 4m br0k3n.",
			"1 n33d th3 R3al1ty 0rb.",
			"1t f3ll 0uts1d3 th3 g0ld3n w4lls... 1n th3 s4nd.",
			"br1ng 1t... pl34s3.",
		})
	end
	d:Close()
	talking = false
	nextTalk = os.clock() + 6 -- bumping into him again right away does not restart it
end

if man then
	local prompt = man:FindFirstChild("TalkPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(who)
			if who == player then
				task.spawn(talk)
			end
		end)
	end
	-- "upon contact": walking into him starts the talk too
	local zone = man:FindFirstChild("ContactZone", true)
	if zone then
		zone.Touched:Connect(function(hit)
			if hit:IsDescendantOf(player.Character or game) and player.Character and hit.Parent == player.Character then
				task.spawn(talk)
			end
		end)
	end
end

-- the hand-over ----------------------------------------------------------------------------------------------------------
local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in props do
		p[k] = v
	end
	p.Parent = workspace
	return p
end

_G.GlitchCutscene = function(data)
	if inCutscene then
		return
	end
	inCutscene = true
	local current = NpcDialog.Current()
	if current then
		current:Close()
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not man then
		inCutscene = false
		return
	end
	humanoid.WalkSpeed, humanoid.JumpHeight = 0, 0
	local manRoot = man:FindFirstChild("HumanoidRootPart") or man.PrimaryPart
	local manAt = man:GetPivot()
	camera.CameraType = Enum.CameraType.Scriptable
	local function look(from, at, time)
		TweenService:Create(camera, TweenInfo.new(time or 1.2, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(from, at) }):Play()
	end
	-- 1. the orb leaves you and floats to him
	local orb = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, Material = Enum.Material.Neon, Color = WHITE, CFrame = root.CFrame * CFrame.new(0.8, 1, -1.5) })
	local glow = Instance.new("PointLight")
	glow.Range, glow.Brightness = 18, 3
	glow.Parent = orb
	local side = (root.Position - manAt.Position)
	side = Vector3.new(side.X, 0, side.Z).Unit:Cross(Vector3.yAxis)
	look((root.Position + manAt.Position) / 2 + side * 16 + Vector3.new(0, 5, 0), (root.Position + manAt.Position) / 2 + Vector3.new(0, 2, 0), 0.8)
	task.wait(0.8)
	TweenService:Create(orb, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { CFrame = manAt * CFrame.new(0, 2.5, -1.4) }):Play()
	task.wait(1.7)
	local d = NpcDialog.Open(man, { Name = scramble("???"), Color = WHITE, Font = Enum.Font.Code, Glitch = scramble, Speed = 26, Stay = true })
	d:Say("f1n4lly...", 1.2)
	d:Say("1 c4n g0 h0m3.", 1.4)
	d:Close()
	-- 2. he rises, the orb in his hands, into the sky
	local sky = manAt.Position + Vector3.new(0, 140, 0)
	-- thin the fog so the tear can be seen
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		TweenService:Create(atmo, TweenInfo.new(3), { Density = 0.12, Haze = 0.4 }):Play()
	end
	local rise = TweenInfo.new(3.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local start = man:GetPivot()
	local riseValue = Instance.new("NumberValue")
	riseValue.Changed:Connect(function(k)
		man:PivotTo(start:Lerp(CFrame.new(sky) * start.Rotation, k))
		orb.CFrame = man:GetPivot() * CFrame.new(0, 2.5, -1.4)
	end)
	look(manAt.Position + side * 40 + Vector3.new(0, -6, 0), manAt.Position + Vector3.new(0, 60, 0), 1.5)
	TweenService:Create(riseValue, rise, { Value = 1 }):Play()
	task.wait(1.2)
	look(root.Position + Vector3.new(0, 3, 0) - side * 6, sky, 2)
	task.wait(2.2)
	-- 3. the sky tears open
	local hole = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic, Color = BLACK, CFrame = CFrame.new(sky) * CFrame.Angles(0, 0, math.rad(90)) })
	local rim = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1, 1), Material = Enum.Material.Neon, Color = WHITE, CFrame = CFrame.new(sky - Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	TweenService:Create(rim, TweenInfo.new(2.4, Enum.EasingStyle.Back), { Size = Vector3.new(0.6, 176, 176) }):Play()
	TweenService:Create(hole, TweenInfo.new(2.4, Enum.EasingStyle.Back), { Size = Vector3.new(1, 160, 160) }):Play()
	local shards = {}
	for i = 1, 60 do
		local a = i / 60 * math.pi * 2
		local s = part({ Size = Vector3.new(rng:NextNumber(4, 14), rng:NextNumber(2, 6), rng:NextNumber(4, 14)), Material = Enum.Material.Neon, Color = i % 2 == 0 and WHITE or BLACK,
			CFrame = CFrame.new(sky + Vector3.new(math.cos(a) * 20, rng:NextNumber(-4, 4), math.sin(a) * 20)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0) })
		shards[i] = { part = s, a = a, r = rng:NextNumber(84, 116), h = rng:NextNumber(-10, 10) }
	end
	orb:Destroy()
	man:PivotTo(CFrame.new(0, -1000, 0)) -- gone into the hole
	local spin = 0
	local spinConn = RunService.RenderStepped:Connect(function(dt)
		spin += dt * 0.6
		for _, s in shards do
			s.r = math.max(30, s.r - dt * 6)
			local a = s.a + spin
			s.part.CFrame = CFrame.new(sky + Vector3.new(math.cos(a) * s.r, s.h, math.sin(a) * s.r)) * CFrame.Angles(spin * 2, a, 0)
		end
	end)
	blur.Size = 6
	task.wait(2.6)
	-- 4. it pulls you in
	root.Anchored = true
	local from = root.CFrame
	local pull = Instance.new("NumberValue")
	pull.Changed:Connect(function(k)
		local p = from.Position:Lerp(sky, k * k)
		root.CFrame = CFrame.new(p) * CFrame.Angles(k * 9, k * 14, k * 5)
		camera.CFrame = CFrame.lookAt(p + Vector3.new(0, -18 + k * 10, 0) + side * (12 - k * 10), sky) * CFrame.Angles(0, 0, k * 3)
		blur.Size = 6 + k * 30
		grade.Brightness = k * 0.6
	end)
	TweenService:Create(pull, TweenInfo.new(3.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 1 }):Play()
	task.wait(3.2)
	-- 5. white, then black: "Thank you..."
	local white = Instance.new("Frame")
	white.Size = UDim2.fromScale(1, 1)
	white.BackgroundColor3 = WHITE
	white.BackgroundTransparency = 1
	white.ZIndex = 50
	white.Parent = gui
	TweenService:Create(white, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
	task.wait(0.6)
	white.BackgroundColor3 = BLACK
	local thanks = Instance.new("TextLabel")
	thanks.Size = UDim2.fromScale(1, 1)
	thanks.BackgroundTransparency = 1
	thanks.Font = Enum.Font.Merriweather
	thanks.TextSize = 40
	thanks.TextColor3 = WHITE
	thanks.Text = ""
	thanks.ZIndex = 51
	thanks.Parent = gui
	spinConn:Disconnect()
	local line = "Thank you..."
	for i = 1, #line do
		thanks.Text = line:sub(1, i)
		task.wait(0.14)
	end
	task.wait(2.5)
	if data and data.Studio then
		thanks.Text = "(Studio: nothing was saved and no teleport happens here.)"
		task.wait(2.5)
		white:Destroy()
		thanks:Destroy()
		hole:Destroy()
		rim:Destroy()
		for _, s in shards do
			s.part:Destroy()
		end
		man:PivotTo(manAt)
		root.Anchored = false
		root.CFrame = from
		humanoid.WalkSpeed, humanoid.JumpHeight = 16, 7.2
		blur.Size, grade.Brightness = 0, 0.02
		if atmo then
			atmo.Density, atmo.Haze = 0.42, 2.5
		end
		camera.CameraType = Enum.CameraType.Custom
		inCutscene = false
	else
		thanks.Text = "Thank you...\n\n" .. scramble("r3tu4n1ng y0u h0m3")
	end
end

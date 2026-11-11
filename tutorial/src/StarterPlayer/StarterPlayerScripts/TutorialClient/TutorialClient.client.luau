--!nonstrict
--[[
 Azusa's training grounds, client side.
   * Talk to Azusa (hold E): fight her, ask how fighting works, or go back to the Sanctum.
   * The fight uses the shared fight layer (UnfairShared/BossKit): your HP, stamina and lives bottom-left (PlayerVitalsHUD), her HP
     and shield at the top (BossKit.BossBar), the Warrior's keys from the Golden Encounter (ClassClient).
   * Her lessons are spoken like alterGolden's lines (boss dialogue at the bottom, PlayerEncounterClient).
   * Every telegraph flashes (parts and highlights tagged AzusaFlash): faster and faster until the moment it lands; sigils turn
     (models tagged AzusaSpin).
   * Her hits shake the camera; Flash Draw and the Requiem's fall freeze one inverted "impact frame"; the Requiem darkens the sky.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local NpcDialog = require(Shared:WaitForChild("NpcDialog"))
local InventoryUI = require(Shared:WaitForChild("InventoryUI"))
local TravelScreen = require(Shared:WaitForChild("TravelScreen"))
local BossBar = require(Shared:WaitForChild("BossKit"):WaitForChild("BossBar"))
local remote = ReplicatedStorage:WaitForChild("Tutorial")

local player = Players.LocalPlayer
local PINK = Color3.fromRGB(255, 150, 200)
local WHITE = Color3.new(1, 1, 1)
InventoryUI.Mount()
BossBar.Mount()

local function make(className, props, parent)
	local i = Instance.new(className)
	for k, v in props do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local gui = make("ScreenGui", { Name = "TutorialHud", ResetOnSpawn = false, DisplayOrder = 15 }, player:WaitForChild("PlayerGui"))

-- big centre words: OPEN!, defeat, victory -----------------------------------------------------------------------------------
local shout = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(700, 90), BackgroundTransparency = 1,
	Font = Enum.Font.Fondamento, TextScaled = true, TextColor3 = WHITE, TextTransparency = 1, Text = "" }, gui)
local shoutStroke = make("UIStroke", { Color = Color3.fromRGB(120, 20, 70), Thickness = 3, Transparency = 1 }, shout)
local shoutSub = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.36, 50), Size = UDim2.fromOffset(700, 28), BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium, TextSize = 20, TextColor3 = Color3.fromRGB(255, 230, 240), TextStrokeTransparency = 0.4, TextTransparency = 1, Text = "" }, gui)
local function showShout(text, sub, color, seconds)
	shout.Text, shoutSub.Text = text, sub or ""
	shout.TextColor3 = color or WHITE
	shout.Size = UDim2.fromOffset(820, 110)
	for _, item in { shout, shoutSub } do
		item.TextTransparency = 0
	end
	shoutStroke.Transparency = 0
	TweenService:Create(shout, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(700, 90) }):Play()
	task.delay(seconds or 1.6, function()
		for _, item in { shout, shoutSub } do
			TweenService:Create(item, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		end
		TweenService:Create(shoutStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
	end)
end

-- the controls strip, shown when the fight starts
local strip = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -128), Size = UDim2.fromOffset(820, 26), BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = Color3.fromRGB(255, 240, 246), TextStrokeTransparency = 0.35, TextTransparency = 1,
	Text = "Click  slash      C / V  skills      F  switch mode      R  guard      Q  dash      E  deflect      Space  jump" }, gui)

-- Azusa and her voice ----------------------------------------------------------------------------------------------------
local function azusa()
	return workspace:FindFirstChild("Azusa")
end
local inFight = false
local talking = false
local function talk()
	local model = azusa()
	if talking or inFight or not model then
		return
	end
	talking = true
	local d = NpcDialog.Open(model, { Name = "Azusa", Color = PINK, Font = Enum.Font.GothamMedium })
	local done = player:GetAttribute("TutorialDone")
	if d:Say(done and "Back for more? I like that." or "So you want to fight alterGolden? Then you fight me first.") then
		local pick = d:Choose({ "Fight me!", "How do I fight?", "Take me back to the Sanctum" })
		if pick == 1 then
			d:Say("Don't worry, I'll go easy on you. At first.")
			d:Close()
			remote:FireServer("Begin")
		elseif pick == 2 then
			for _, line in {
				"You fight as a Warrior here, same as in his castle. Click to slash. C and V are your skills, F switches between attack and defence.",
				"Hold R to guard: you take far less. Tap R right before a hit for a perfect guard.",
				"Q dashes. While you dash, nothing can touch you. Use it to go THROUGH attacks.",
				"When a white shield flashes on you, press E: that's a deflect. Deflect my big cuts and I'm open.",
				"Bottom left: your hearts, health and stamina. Dashes and skills cost stamina, so watch it.",
				"Everything I throw flashes before it lands. The faster it flashes, the closer it is. Ready?",
			} do
				if not d:Say(line) then
					break
				end
			end
			d:Close()
		elseif pick == 3 then
			d:Say("Come back any time.")
			d:Close()
			TravelScreen.ForTeleport("Hub")
			TravelScreen.Show("Hub", 0.5)
			remote:FireServer("Leave")
			task.delay(8, function()
				TravelScreen.Hide(0.5) -- still here (Studio, or the teleport failed)
			end)
		else
			d:Close()
		end
	end
	talking = false
end
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local model = azusa()
	if model and prompt.Name == "TalkPrompt" and prompt:IsDescendantOf(model) then
		talk()
	end
end)

-- her effects ------------------------------------------------------------------------------------------------------------
local Lighting = game:GetService("Lighting")
local camera = workspace.CurrentCamera
local shake = 0
RunService:BindToRenderStep("AzusaShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if shake > 0.01 then
		camera.CFrame *= CFrame.new(math.random(-100, 100) / 100 * shake * 0.5, math.random(-100, 100) / 100 * shake * 0.5, 0)
			* CFrame.Angles(0, 0, math.random(-100, 100) / 100 * shake * 0.012)
		shake = math.max(0, shake - dt * 3.5)
	end
end)
local grade = Instance.new("ColorCorrectionEffect")
grade.Name = "AzusaGrade"
grade.Parent = Lighting
local overlay = make("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50 }, gui)
gui.IgnoreGuiInset = true
local skyOn = false
local function effect(kind, data)
	data = data or {}
	if kind == "Shake" then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local far = root and data.At and (root.Position - data.At).Magnitude or 0
		shake = math.max(shake, (data.Power or 0.5) * math.clamp(1.4 - far / 90, 0.2, 1.4))
	elseif kind == "ImpactFrame" then
		-- one inverted, high-contrast frame, then a white flash that fades
		grade.Saturation, grade.Contrast, grade.TintColor = -1, 1, Color3.fromRGB(255, 200, 225)
		overlay.BackgroundColor3 = data.Strong and WHITE or PINK
		overlay.BackgroundTransparency = 0.25
		task.delay(0.07, function()
			grade.Saturation, grade.Contrast, grade.TintColor = skyOn and -0.3 or 0, 0, skyOn and Color3.fromRGB(255, 190, 220) or WHITE
			TweenService:Create(overlay, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		end)
		shake = math.max(shake, data.Strong and 1.2 or 0.6)
	elseif kind == "Focus" then
		-- the world holds its breath before Flash Draw
		TweenService:Create(grade, TweenInfo.new(0.3), { Saturation = -0.45, Brightness = -0.05 }):Play()
		task.delay(data.Seconds or 1, function()
			TweenService:Create(grade, TweenInfo.new(0.4), { Saturation = skyOn and -0.3 or 0, Brightness = 0 }):Play()
		end)
	elseif kind == "Sky" then
		skyOn = data.On == true
		TweenService:Create(grade, TweenInfo.new(0.8), {
			TintColor = skyOn and Color3.fromRGB(255, 170, 210) or WHITE, Saturation = skyOn and -0.3 or 0, Brightness = skyOn and -0.08 or 0,
		}):Play()
		TweenService:Create(Lighting, TweenInfo.new(1.2), { ClockTime = skyOn and 19.2 or 17.7 }):Play()
	end
end
-- sigils turn (locally, round their pivots)
RunService.RenderStepped:Connect(function(dt)
	for _, model in CollectionService:GetTagged("AzusaSpin") do
		if model:IsA("Model") and model.Parent then
			model:PivotTo(model:GetPivot() * CFrame.Angles(0, (model:GetAttribute("Spin") or 1) * dt, 0))
		end
	end
end)

remote.OnClientEvent:Connect(function(kind, data, ...)
	if kind == "FX" then
		effect(data, select(1, ...))
	elseif kind == "Exposed" then
		showShout("OPEN!", "she is staggered: hit her now", PINK, math.min(data, 1.6))
	elseif kind == "Started" then
		inFight = true
		showShout("Azusa", "the Blossom Blade", PINK, 2)
		strip.TextTransparency = 0
		task.delay(12, function()
			TweenService:Create(strip, TweenInfo.new(1), { TextTransparency = 1 }):Play()
		end)
	elseif kind == "Won" then
		inFight = false
		showShout("Training complete", "talk to Azusa to go back to the Sanctum", Color3.fromRGB(255, 226, 150), 5)
	elseif kind == "Lost" then
		inFight = false
		showShout("You fell", "Azusa picks you up. Try again.", WHITE, 3)
	end
end)

-- the flashing ---------------------------------------------------------------------------------------------------------------
-- A tagged part blinks between its FlashColor and white, from FlashFrom to FlashTo (server time): 3 blinks a second at first,
-- 16 at the end. After FlashTo it holds FlashColor, fully lit. A tagged Highlight (her wind-up) pulses the same way.
RunService.RenderStepped:Connect(function()
	local t = workspace:GetServerTimeNow()
	for _, item in CollectionService:GetTagged("AzusaFlash") do
		local from, to = item:GetAttribute("FlashFrom"), item:GetAttribute("FlashTo")
		if from and to then
			local color = item:GetAttribute("FlashColor") or PINK
			local progress = math.clamp((t - from) / math.max(to - from, 0.01), 0, 1)
			local rate = 3 + 13 * progress * progress
			local on = progress >= 1 or math.sin((t - from) * rate * math.pi * 2) > 0
			if item:IsA("BasePart") then
				local base = item:GetAttribute("FlashBase") or 0.15
				item.Color = on and color or WHITE
				item.Transparency = on and base or math.min(1, base + 0.45)
			elseif item:IsA("Highlight") then
				item.FillColor = on and color or WHITE
				item.FillTransparency = progress >= 1 and 1 or (on and 0.35 or 0.75)
				item.OutlineTransparency = progress >= 1 and 1 or 0
			end
		end
	end
end)

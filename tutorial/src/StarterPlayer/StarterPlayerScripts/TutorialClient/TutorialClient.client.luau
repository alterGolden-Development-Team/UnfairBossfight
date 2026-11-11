--!nonstrict
--[[
 Azusa's training grounds, client side.
   * Talk to Azusa (hold E): start the lessons, look around, or go back to the Sanctum.
   * During the lessons her words float over her head and a banner at the top says what the lesson wants from you.
   * Controls here: Q dash (untouchable for a moment), hold R guard (much less damage), click to hit her when she is open.
]]
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("UnfairShared")
local NpcDialog = require(Shared.NpcDialog)
local InventoryUI = require(Shared.InventoryUI)
local remote = ReplicatedStorage:WaitForChild("Tutorial")

local player = Players.LocalPlayer
local PINK = Color3.fromRGB(255, 176, 214)
local GOLD = Color3.fromRGB(246, 211, 117)
InventoryUI.Mount()

local world = workspace:WaitForChild("World")
local azusa = world:WaitForChild("Azusa", 60)
local inLessons = false

-- the banner ----------------------------------------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TutorialHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 12)
banner.Size = UDim2.fromOffset(560, 74)
banner.BackgroundColor3 = Color3.fromRGB(16, 13, 12)
banner.BackgroundTransparency = 0.15
banner.Visible = false
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke")
stroke.Color, stroke.Transparency = GOLD, 0.3
stroke.Parent = banner
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position, title.Size = UDim2.fromOffset(16, 6), UDim2.new(1, -32, 0, 28)
title.Font, title.TextSize, title.TextColor3 = Enum.Font.Garamond, 26, GOLD
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = banner
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Position, hint.Size = UDim2.fromOffset(16, 34), UDim2.new(1, -32, 0, 22)
hint.Font, hint.TextSize, hint.TextColor3 = Enum.Font.Gotham, 15, Color3.fromRGB(236, 230, 218)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextWrapped = true
hint.Parent = banner
local track = Instance.new("Frame")
track.Position, track.Size = UDim2.new(0, 16, 1, -12), UDim2.new(1, -32, 0, 4)
track.BackgroundColor3, track.BorderSizePixel = Color3.fromRGB(58, 50, 40), 0
track.Parent = banner
local fill = Instance.new("Frame")
fill.Size, fill.BackgroundColor3, fill.BorderSizePixel = UDim2.fromScale(0, 1), GOLD, 0
fill.Parent = track
local keys = Instance.new("TextLabel")
keys.AnchorPoint = Vector2.new(0.5, 1)
keys.Position = UDim2.new(0.5, 0, 1, -16)
keys.Size = UDim2.fromOffset(620, 24)
keys.BackgroundTransparency = 1
keys.Font, keys.TextSize, keys.TextColor3 = Enum.Font.GothamMedium, 15, Color3.fromRGB(240, 236, 226)
keys.TextStrokeTransparency = 0.4
keys.Text = "Q  dash      hold R  guard      Space  jump      Click  hit her when she's open"
keys.Visible = false
keys.Parent = gui

-- her voice during lessons: one conversation that stays up while you move
local voice
local function speak(text)
	if not azusa then
		return
	end
	if not voice or not voice:IsOpen() then
		voice = NpcDialog.Open(azusa, { Name = "Azusa", Color = PINK, Font = Enum.Font.GothamMedium, Stay = true, Speed = 55 })
	end
	task.spawn(voice.Say, voice, text, math.clamp(#text / 18, 1.4, 4))
end

-- the controls ----------------------------------------------------------------------------------------------------------------
local dashUntil, nextDash = 0, 0
local function dash()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or os.clock() < nextDash then
		return
	end
	nextDash = os.clock() + 0.9
	dashUntil = os.clock() + 0.18
	remote:FireServer("Dash")
	local dir = humanoid.MoveDirection
	if dir.Magnitude < 0.1 then
		local look = workspace.CurrentCamera.CFrame.LookVector
		dir = Vector3.new(look.X, 0, look.Z)
	end
	dir = dir.Magnitude > 0.01 and dir.Unit or root.CFrame.LookVector
	-- a pale afterimage where you were
	for _, p in character:GetChildren() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local ghost = p:Clone()
			ghost:ClearAllChildren()
			ghost.Anchored, ghost.CanCollide, ghost.CanQuery, ghost.CanTouch = true, false, false, false
			ghost.Material, ghost.Color, ghost.Transparency = Enum.Material.Neon, Color3.fromRGB(255, 220, 160), 0.5
			ghost.Parent = workspace
			TweenService:Create(ghost, TweenInfo.new(0.35), { Transparency = 1 }):Play()
			game:GetService("Debris"):AddItem(ghost, 0.4)
		end
	end
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if os.clock() > dashUntil or not root.Parent then
			conn:Disconnect()
			return
		end
		root.AssemblyLinearVelocity = dir * 95 + Vector3.new(0, root.AssemblyLinearVelocity.Y * 0.3, 0)
	end)
end

local blocking = false
local function setBlock(on)
	if blocking == on then
		return
	end
	blocking = on
	remote:FireServer("Block", on)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = on and 7 or 16
	end
end

ContextActionService:BindAction("TutorialDash", function(_, state)
	if state == Enum.UserInputState.Begin then
		dash()
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
ContextActionService:BindAction("TutorialGuard", function(_, state)
	if state == Enum.UserInputState.Begin then
		setBlock(true)
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		setBlock(false)
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonL2)
ContextActionService:SetTitle("TutorialDash", "Dash")
ContextActionService:SetTitle("TutorialGuard", "Guard")
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		remote:FireServer("Attack")
	end
end)
player.CharacterAdded:Connect(function()
	blocking = false
end)

-- talking to her ----------------------------------------------------------------------------------------------------------------
local talking = false
local function talk(afterLessons)
	if talking or inLessons or not azusa then
		return
	end
	talking = true
	local d = NpcDialog.Open(azusa, { Name = "Azusa", Color = PINK, Font = Enum.Font.GothamMedium })
	local line = afterLessons and "You're ready. Go show him what you learned!" or "Welcome to my training grounds! Ready to learn how to survive him?"
	if d:Say(line, 0.5) then
		local pick = d:Choose(afterLessons and { "Take me back to the Sanctum", "Again, from the start!", "I'll stay a while" } or { "Teach me!", "Let me look around first", "Take me back to the Sanctum" })
		if (not afterLessons and pick == 1) or (afterLessons and pick == 2) then
			d:Say("Okay! Stay inside the circle and do what I say.", 1)
			d:Close()
			inLessons = true
			banner.Visible, keys.Visible = true, true
			remote:FireServer("Begin")
		elseif (not afterLessons and pick == 3) or (afterLessons and pick == 1) then
			d:Say("Take care! Come back any time.", 1.2)
			remote:FireServer("Leave")
		elseif pick then
			d:Say("Sure. Talk to me when you're ready.", 1.2)
		end
	end
	d:Close()
	talking = false
end

remote.OnClientEvent:Connect(function(action, data)
	if action == "Lesson" and type(data) == "table" then
		banner.Visible = true
		title.Text = string.format("Lesson %d / %d  ·  %s", data.Index, data.Count, data.Title)
		if data.Hint then
			hint.Text = data.Hint
		end
		TweenService:Create(fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(math.clamp(data.Progress or 0, 0, 1), 1) }):Play()
	elseif action == "Say" then
		if inLessons then
			speak(tostring(data))
		else
			local d = NpcDialog.Current()
			if d then
				task.spawn(d.Say, d, tostring(data), 2.5)
			else
				InventoryUI.Toast(tostring(data), 4)
			end
		end
	elseif action == "Hurt" then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		flash.BackgroundTransparency = 0.7
		flash.BorderSizePixel = 0
		flash.Parent = gui
		TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		game:GetService("Debris"):AddItem(flash, 0.4)
	elseif action == "Done" then
		inLessons = false
		banner.Visible, keys.Visible = false, false
		if voice then
			voice:Close()
			voice = nil
		end
		task.delay(0.8, talk, true)
	end
end)

if azusa then
	local prompt = azusa:WaitForChild("HumanoidRootPart"):WaitForChild("TalkPrompt", 10)
	if prompt then
		prompt.Triggered:Connect(function(who)
			if who == player then
				task.spawn(talk, player:GetAttribute("TutorialDone") == true)
			end
		end)
	end
end

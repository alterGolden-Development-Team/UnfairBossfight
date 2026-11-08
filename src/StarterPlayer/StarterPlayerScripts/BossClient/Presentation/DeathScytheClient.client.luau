local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local presentation = game:GetService("ReplicatedStorage"):WaitForChild("BossShared"):WaitForChild("Presentation"):WaitForChild("DeathScythe")
local Cinematic = require(presentation:WaitForChild("Cinematic"))
local Style = require(presentation:WaitForChild("Style"))
local GOLD, EDGE = Style.BloodHot, Style.Edge
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")
local gui = Instance.new("ScreenGui")
gui.Name = "DeathScytheHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 85
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.9, 0, 0, 156)
panel.BackgroundTransparency = 1
panel.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(680, 156)
limit.Parent = panel
local function label(name, y, height, textSize)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = UDim2.fromOffset(0, y)
	item.Size = UDim2.new(1, 0, 0, height)
	item.BackgroundTransparency = 1
	item.Font = Enum.Font.Garamond
	item.TextColor3 = GOLD
	item.TextStrokeColor3 = Color3.fromRGB(40, 22, 0)
	item.TextStrokeTransparency = 0.1
	item.TextScaled = true
	local size = Instance.new("UITextSizeConstraint")
	size.MaxTextSize, size.MinTextSize = textSize, 14
	size.Parent = item
	item.Parent = panel
	return item
end
local title = label("Command", 40, 76, 72)
local detail = label("SurvivalHint", 122, 28, 22)
 
local bar = Instance.new("Frame")
bar.Name = "TimingBar"
bar.Position = UDim2.fromOffset(0, 150)
bar.Size = UDim2.new(1, 0, 0, 5)
bar.BackgroundColor3 = Color3.fromRGB(30, 18, 0)
bar.BackgroundTransparency = 0.35
bar.BorderSizePixel = 0
bar.Visible = false
bar.Parent = panel
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = GOLD
barFill.BorderSizePixel = 0
barFill.Parent = bar
local barCue = Instance.new("Frame")
barCue.AnchorPoint = Vector2.new(0.5, 0.5)
barCue.Size = UDim2.new(0, 3, 1, 8)
barCue.Position = UDim2.fromScale(0.5, 0.5)
barCue.BackgroundColor3 = EDGE
barCue.BorderSizePixel = 0
barCue.ZIndex = 2
barCue.Parent = bar
local active
local function resetView()
 Cinematic.ResetView()
 gui.Enabled=false
end
local function clear(immediate)
	Cinematic.Stop(immediate)
	active = nil
	gui.Enabled = false
end
local connection = remote.OnClientEvent:Connect(function(kind, data)
	if kind ~= "DeathScythe" or type(data) ~= "table" then return end
	if data.Stage == "End" then
		Cinematic.Handle(data)
		if active and active.Token == data.Token then clear() end
		return
	end
	if player:GetAttribute("ViewAsServer") then return end
	local owner = data.Owner
	if typeof(owner) ~= "Instance" or not owner.Parent or math.min(4, math.floor(owner:GetAttribute("Phase") or 0)) ~= 4 then return end
	Cinematic.Handle(data)
	local forming = data.Stage == "Forming"
	local fd = data.FormationDuration or Style.FormationDuration
	local lead = data.JumpCueLead or Style.JumpCueLead
	active = { Token = data.Token, Owner = owner, Until = os.clock() + math.clamp(data.Duration or 2, 0.1, 8) + 0.5,
		Forming = forming, Began = os.clock(), Fd = fd, CueAt = math.clamp(fd - lead, fd * 0.25, fd * 0.9), Cued = false }
	gui.Enabled = true
	bar.Visible = forming
	barFill.Size = UDim2.fromScale(0, 1)
	barCue.Position = UDim2.fromScale(active.CueAt / fd, 0.5)
	title.Text = forming and "GET READY" or ""
	title.TextColor3 = GOLD
	detail.Text = forming and (data.TargetUserId == player.UserId and "THE SCYTHE HAS MARKED YOU - JUMP AT THE MARKER" or "Jump when the bar reaches the marker.") or ""
end)
local heartbeat = Run.Heartbeat:Connect(function()
	if not active then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local owner = active.Owner
	if os.clock() >= active.Until or not owner.Parent
		or player:GetAttribute("ViewAsServer") or owner:GetAttribute("EncounterEnded") or math.min(4, math.floor(owner:GetAttribute("Phase") or 0)) ~= 4 then clear(true); return end
	if not humanoid or humanoid.Health<=0 then resetView(); return end
	gui.Enabled=true
	if active.Forming then
		local elapsed = os.clock() - active.Began
		barFill.Size = UDim2.fromScale(math.clamp(elapsed / active.Fd, 0, 1), 1)
		local go = elapsed >= active.CueAt
		if go ~= active.Cued then
			active.Cued = go
			title.Text = go and "JUMP!" or "GET READY"
			title.TextColor3 = go and EDGE or GOLD
		end
	end
end)
local removing = player.CharacterRemoving:Connect(resetView)
script.Destroying:Connect(function()
	clear(true)
	connection:Disconnect()
	heartbeat:Disconnect()
	removing:Disconnect()
	gui:Destroy()
end)


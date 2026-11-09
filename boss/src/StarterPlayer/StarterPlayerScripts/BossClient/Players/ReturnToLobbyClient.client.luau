--!nonstrict
-- "Return to Lobby" button (spec 6.4, plan task 19). Only exists for runs that came from the lobby (workspace LobbyMode).
-- Shows at the bottom of the screen once this player is permanently defeated, or a few seconds after the boss is won, so it
-- never competes with the Retry panel or the victory presentation. The server decides (Encounter/LobbyReturn); this only
-- asks and shows the answer. It also shows the cash this run paid ("+70 cash"), which CashService sets as CashEarned.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReturnRules = require(ReplicatedStorage:WaitForChild("UnfairShared"):WaitForChild("ReturnRules"))

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("EncounterLifecycle")

local WIN_DELAY = 6 -- seconds after the win before the button appears
local GOLD = Color3.fromRGB(246, 211, 117)

local gui = Instance.new("ScreenGui")
gui.Name = "ReturnToLobbyHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 160
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 1)
holder.Position = UDim2.new(0.5, 0, 1, -28)
holder.Size = UDim2.fromOffset(300, 110)
holder.BackgroundTransparency = 1
holder.Parent = gui

local function label(name, y, height, size, color)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = UDim2.fromOffset(0, y)
	item.Size = UDim2.new(1, 0, 0, height)
	item.BackgroundTransparency = 1
	item.Font = Enum.Font.GothamBold
	item.TextSize = size
	item.TextColor3 = color
	item.TextStrokeTransparency = 0.5
	item.Text = ""
	item.Parent = holder
	return item
end

local earned = label("Earned", 0, 28, 20, GOLD)
local status = label("Status", 34, 22, 14, Color3.fromRGB(255, 160, 140))
local button = Instance.new("TextButton")
button.Name = "ReturnButton"
button.AnchorPoint = Vector2.new(0.5, 1)
button.Position = UDim2.new(0.5, 0, 1, 0)
button.Size = UDim2.fromOffset(250, 44)
button.BackgroundColor3 = Color3.fromRGB(34, 31, 42)
button.BorderSizePixel = 0
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 17
button.Text = "RETURN TO LOBBY"
button.Parent = holder
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button
local stroke = Instance.new("UIStroke")
stroke.Color = GOLD
stroke.Thickness = 1.5
stroke.Parent = button

local pending = false
local wonSince = nil

local function update()
	local won = workspace:GetAttribute("BossEncounterWon") == true
	if won and not wonSince then
		wonSince = os.clock()
	elseif not won then
		wonSince = nil
	end
	local allowed = ReturnRules.decide({
		lobbyMode = workspace:GetAttribute("LobbyMode") == true,
		won = won and wonSince ~= nil and os.clock() - wonSince >= WIN_DELAY,
		defeated = player:GetAttribute("PermanentlyDefeated") == true and player:GetAttribute("FinalDefeatShow") ~= true,
		now = os.clock(),
		lastRequest = nil,
	})
	gui.Enabled = allowed
	local amount = player:GetAttribute("CashEarned")
	earned.Text = (won and type(amount) == "number" and amount > 0) and `+{amount} cash` or ""
	button.Text = pending and "LEAVING..." or "RETURN TO LOBBY"
	button.Active = not pending
	button.AutoButtonColor = not pending
end

button.Activated:Connect(function()
	if pending then
		return
	end
	pending = true
	status.Text = ""
	update()
	remote:FireServer("ReturnToLobby")
	task.delay(25, function()
		if pending then
			pending = false
			update()
		end
	end)
end)

remote.OnClientEvent:Connect(function(action, text)
	if action == "ReturnRejected" then
		pending = false
		status.Text = type(text) == "string" and text or ""
		update()
		task.delay(6, function()
			if status.Text == text then
				status.Text = ""
			end
		end)
	end
end)

for _, name in ipairs({ "PermanentlyDefeated", "FinalDefeatShow", "CashEarned" }) do
	player:GetAttributeChangedSignal(name):Connect(update)
end
for _, name in ipairs({ "BossEncounterWon", "LobbyMode" }) do
	workspace:GetAttributeChangedSignal(name):Connect(update)
end
task.spawn(function()
	while true do
		task.wait(0.5) -- also covers the win delay running out
		update()
	end
end)
update()

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("EncounterLifecycle")
local gui = Instance.new("ScreenGui")
gui.Name = "EncounterRetryHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 150
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(8, 9, 13)
backdrop.BackgroundTransparency = 0.2
backdrop.BorderSizePixel = 0
backdrop.Parent = gui
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.86, 0, 0, 260)
panel.BackgroundTransparency = 1
panel.Parent = backdrop
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(520, 260)
constraint.Parent = panel
local function label(name, text, y, height, size, color)
	local item = Instance.new("TextLabel")
	item.Name, item.Text = name, text
	item.Position = UDim2.fromOffset(0, y)
	item.Size = UDim2.new(1, 0, 0, height)
	item.BackgroundTransparency = 1
	item.Font = Enum.Font.Garamond
	item.TextSize, item.TextColor3 = size, color
	item.TextWrapped = true
	item.Parent = panel
	return item
end
local gold = Color3.fromRGB(246, 211, 117)
local title = label("Title", "DEFEATED", 0, 66, 48, gold)
local message = label("Message", "Your story does not end here.", 76, 56, 22, Color3.fromRGB(223, 221, 215))
local button = Instance.new("TextButton")
button.Name = "RetryButton"
button.AnchorPoint = Vector2.new(0.5, 0)
button.Position = UDim2.new(0.5, 0, 0, 154)
button.Size = UDim2.fromOffset(240, 52)
button.BackgroundColor3 = gold
button.BorderSizePixel = 0
button.TextColor3 = Color3.fromRGB(22, 19, 12)
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.Text = "RETRY"
button.Modal = true
button.Parent = panel
local hint = label("Hint", "Return to the entrance and choose your next trial.", 218, 32, 18, Color3.fromRGB(169, 166, 156))
local pending = false
local function update()
	local retrying = player:GetAttribute("EncounterRetrying") == true
	local lost = player:GetAttribute("PermanentlyDefeated") == true
	local available = workspace:GetAttribute("EncounterRetryAvailable") == true
	 -- (P5SonicBlaster effect, local attributes FinalDefeatShow / FinalDefeatSpectate) instead of this panel. The panel stays
	 -- away while it plays, and afterwards unless the whole group is down (then Retry is available and the panel is needed).
	local cutscene = player:GetAttribute("FinalDefeatShow") == true
	local spectate = player:GetAttribute("FinalDefeatSpectate") == true
	local inFinal = workspace:GetAttribute("SonicBlasterActive") == true and workspace:GetAttribute("NothingDimension") == true
	local visible = lost and not retrying and not pending and workspace:GetAttribute("BossEncounterWon") ~= true
		and not cutscene and not ((spectate or inFinal) and not available)
	local wasVisible = gui.Enabled
	gui.Enabled = visible
	if not lost then
		pending = false
		if spectate then player:SetAttribute("FinalDefeatSpectate", nil) end
	end
	title.Text = "DEFEATED"
	message.Text = available and "Reset the battle and return to the entrance." or "The other players are still fighting."
	button.Text = (retrying or pending) and "RESTARTING..." or "RETRY"
	button.Active = lost and available and not retrying and not pending
	button.Selectable = button.Active
	button.AutoButtonColor = button.Active
	button.BackgroundTransparency = button.Active and 0 or 0.65
	hint.Text = available and "Change difficulty at the statue before starting again." or "Retry becomes available when the group is defeated."
	if visible and not wasVisible and button.Active and Input.GamepadEnabled then GuiService.SelectedObject = button end
	if not visible and GuiService.SelectedObject == button then GuiService.SelectedObject = nil end
end
button.Activated:Connect(function()
	if not button.Active then return end
	pending = true
	update()
	remote:FireServer("Retry")
	task.delay(5, function()
		if pending and not player:GetAttribute("EncounterRetrying") then pending = false; update() end
	end)
end)
remote.OnClientEvent:Connect(function(action, text)
	if action == "RetryRejected" then pending = false; update(); message.Text = text end
end)
for _, name in ipairs({ "PermanentlyDefeated", "EncounterRetrying", "FinalDefeatShow", "FinalDefeatSpectate" }) do
	player:GetAttributeChangedSignal(name):Connect(update)
end
for _, name in ipairs({ "EncounterRetryAvailable", "BossEncounterWon", "SonicBlasterActive", "NothingDimension" }) do
	workspace:GetAttributeChangedSignal(name):Connect(update)
end
update()

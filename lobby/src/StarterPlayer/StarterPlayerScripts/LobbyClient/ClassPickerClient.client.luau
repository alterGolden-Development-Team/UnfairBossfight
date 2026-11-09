--!nonstrict
-- Class picker UI (plan task 14). Everything shown comes from ClassConfig / ClassUnlocks and the server's attributes;
-- the client only sends "Select" / "Buy" and shows the answer. The server decides (ClassPickService).
--   * opens from a pedestal in Workspace.ClassHall (a ProximityPrompt is added to each pedestal here if the map has none)
--   * the chip at the bottom-left shows the current class and opens the picker too
--   * every player's class floats above their head (read from the replicated `PlayerClass` attribute)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local ClassUnlocks = require(ReplicatedStorage.BossShared.Classes.ClassUnlocks)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)

local player = Players.LocalPlayer
local remote = LobbyRemotes.get("ClassPick")

local GOLD = Color3.fromRGB(255, 196, 64)
local PANEL = Color3.fromRGB(24, 22, 30)
local CARD = Color3.fromRGB(38, 35, 46)

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function currentClass()
	local id = player:GetAttribute("PlayerClass")
	return ClassConfig.Classes[id] and id or ClassConfig.Default
end

local function isUnlocked(id)
	if not ClassUnlocks[id] then
		return true
	end
	return player:GetAttribute("ClassUnlocked_" .. id) == true
end

local gui = make("ScreenGui", { Name = "ClassPickerGui", ResetOnSpawn = false, DisplayOrder = 5 }, player:WaitForChild("PlayerGui"))

-- the chip --------------------------------------------------------------------------------------------------
local chip = make("TextButton", {
	Name = "ClassChip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -16), Size = UDim2.fromOffset(190, 40),
	BackgroundColor3 = PANEL, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 16, AutoButtonColor = true,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, chip)
make("UIStroke", { Color = GOLD, Thickness = 1.5 }, chip)

-- the picker ------------------------------------------------------------------------------------------------
local panel = make("Frame", {
	Name = "Picker", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.85),
	BackgroundColor3 = PANEL, Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
make("UIStroke", { Color = GOLD, Thickness = 2 }, panel)
make("UISizeConstraint", { MaxSize = Vector2.new(760, 520) }, panel)
make("TextLabel", {
	Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(16, 6), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Choose your class", TextColor3 = GOLD, Font = Enum.Font.GothamBold, TextSize = 24,
}, panel)
local closeButton = make("TextButton", {
	Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -46, 0, 8), BackgroundColor3 = CARD, Text = "X",
	TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18,
}, panel)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, closeButton)
local message = make("TextLabel", {
	Size = UDim2.new(1, -32, 0, 24), Position = UDim2.new(0, 16, 1, -32), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "", TextColor3 = Color3.fromRGB(255, 150, 130), Font = Enum.Font.Gotham, TextSize = 15,
}, panel)
local grid = make("ScrollingFrame", {
	Size = UDim2.new(1, -32, 1, -92), Position = UDim2.fromOffset(16, 54), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
make("UIGridLayout", { CellSize = UDim2.fromOffset(232, 120), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)

local cards = {}
for order, id in ClassConfig.Order do
	local def = ClassConfig.Classes[id]
	if def then
		local card = make("Frame", { Name = id, BackgroundColor3 = CARD, LayoutOrder = order }, grid)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
		local stroke = make("UIStroke", { Color = def.Color or GOLD, Thickness = 1.5 }, card)
		local name = make("TextLabel", {
			Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(8, 4), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Text = def.Name or id, TextColor3 = def.Color or GOLD, Font = Enum.Font.GothamBold, TextSize = 18,
		}, card)
		local tagline = make("TextLabel", {
			Size = UDim2.new(1, -16, 0, 56), Position = UDim2.fromOffset(8, 28), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = def.Tagline or "", TextColor3 = Color3.fromRGB(205, 200, 215), Font = Enum.Font.Gotham, TextSize = 12,
		}, card)
		local action = make("TextButton", {
			Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0, 8, 1, -32), BackgroundColor3 = def.Color or GOLD,
			TextColor3 = Color3.new(0, 0, 0), Font = Enum.Font.GothamBold, TextSize = 14, Text = "",
		}, card)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, action)
		action.Activated:Connect(function()
			if isUnlocked(id) then
				remote:FireServer("Select", id)
			elseif ClassUnlocks[id] and ClassUnlocks[id].Kind == "GamePass" then
				remote:FireServer("Buy", id)
			else
				message.Text = "Locked. " .. (ClassUnlocks[id] and ClassUnlocks[id].Hint or "")
			end
		end)
		cards[id] = { card = card, stroke = stroke, action = action, tagline = tagline, name = name, def = def }
	end
end

local function refresh()
	local selected = currentClass()
	local def = ClassConfig.Classes[selected]
	chip.Text = "Class: " .. (def and def.Name or selected)
	for id, ui in cards do
		local unlocked = isUnlocked(id)
		local entry = ClassUnlocks[id]
		ui.stroke.Thickness = id == selected and 4 or 1.5
		ui.card.BackgroundColor3 = id == selected and Color3.fromRGB(58, 52, 70) or CARD
		if id == selected then
			ui.action.Text = "Selected"
			ui.action.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
		elseif unlocked then
			ui.action.Text = "Pick"
			ui.action.BackgroundColor3 = ui.def.Color or GOLD
		elseif entry and entry.Kind == "GamePass" then
			ui.action.Text = "Buy" .. (entry.Price and (" - " .. entry.Price .. " Robux") or "")
			ui.action.BackgroundColor3 = Color3.fromRGB(110, 200, 120)
		else
			ui.action.Text = "Locked"
			ui.action.BackgroundColor3 = Color3.fromRGB(90, 85, 100)
		end
		ui.tagline.Text = (not unlocked and entry and entry.Hint) and ("\u{1F512} " .. entry.Hint) or (ui.def.Tagline or "")
	end
end

local function open()
	message.Text = ""
	panel.Visible = true
	refresh()
end
local function close()
	panel.Visible = false
end

chip.Activated:Connect(function()
	if panel.Visible then close() else open() end
end)
closeButton.Activated:Connect(close)

remote.OnClientEvent:Connect(function(action, data)
	if action == "Result" and type(data) == "table" then
		message.Text = data.Message or ""
	end
end)

player:GetAttributeChangedSignal("PlayerClass"):Connect(refresh)
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 14) == "ClassUnlocked_" then
		refresh()
	end
end)
refresh()

-- pedestals ---------------------------------------------------------------------------------------------------
local function bindPedestal(model)
	local part = model:IsA("BasePart") and model or model:FindFirstChild("Pedestal", true)
	if not part or not part:IsA("BasePart") then
		return
	end
	local prompt = part:FindFirstChild("PickPrompt")
	if not prompt then
		prompt = make("ProximityPrompt", { Name = "PickPrompt", ActionText = "Choose class", RequiresLineOfSight = false, MaxActivationDistance = 10, HoldDuration = 0 }, part)
	end
	local def = ClassConfig.Classes[model.Name]
	prompt.ObjectText = def and def.Name or model.Name
	prompt.Triggered:Connect(function(who)
		if who == player then open() end
	end)
end

task.spawn(function()
	local hall = workspace:WaitForChild("ClassHall", 30)
	if not hall then
		return -- the map is not built yet; the chip still works
	end
	for _, child in hall:GetChildren() do
		bindPedestal(child)
	end
	hall.ChildAdded:Connect(bindPedestal)
end)

-- class name above every player's head ------------------------------------------------------------------------
local tags = {}
local function updateTag(other)
	local character = other.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local id = other:GetAttribute("PlayerClass")
	local def = ClassConfig.Classes[id]
	local tag = tags[other]
	if not def then
		if tag then tag:Destroy() tags[other] = nil end
		return
	end
	if not tag or tag.Parent ~= head then
		if tag then tag:Destroy() end
		tag = make("BillboardGui", {
			Name = "ClassTag", Size = UDim2.fromOffset(150, 24), StudsOffset = Vector3.new(0, 3.2, 0), AlwaysOnTop = false, MaxDistance = 80, Adornee = head,
		}, head)
		make("TextLabel", {
			Name = "Label", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16,
			TextStrokeTransparency = 0.3,
		}, tag)
		tags[other] = tag
	end
	tag.Label.Text = def.Name or id
	tag.Label.TextColor3 = def.Color or GOLD
end

local function trackPlayer(other)
	other:GetAttributeChangedSignal("PlayerClass"):Connect(function() updateTag(other) end)
	other.CharacterAdded:Connect(function()
		task.wait(0.2)
		updateTag(other)
	end)
	updateTag(other)
end
for _, other in Players:GetPlayers() do trackPlayer(other) end
Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(other) tags[other] = nil end)

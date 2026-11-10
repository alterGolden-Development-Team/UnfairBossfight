--!nonstrict
-- The party portals in the palace. Reads the room's replicated attributes (see PartyService) and sends intents on the PartyControl remote.
-- Nothing here decides anything: a non-leader's buttons are read-only for show and the server refuses their requests anyway.
--   * the expedition board while you are in a room: five difficulty cards (what it pays, how hard it is), the Enraged seal, roster and Start
--   * a billboard over every portal
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.UnfairShared.UnfairConfig)
local CashRules = require(ReplicatedStorage.UnfairShared.CashRules)
local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)

local player = Players.LocalPlayer
local remote = LobbyRemotes.get("PartyControl")

local GOLD = Color3.fromRGB(246, 211, 117)
local INK = Color3.fromRGB(16, 13, 12)
local CARD = Color3.fromRGB(38, 32, 28)
local OFF = Color3.fromRGB(70, 64, 58)
local TITLE_FONT = Enum.Font.Garamond

-- Hardest on the left, the order the boss's own picker uses. Skulls say how hard, colour says the same thing again for a quick read.
local DIFFICULTY = {
	Hellaven = { Name = "Hellaven", Skulls = 5, Color = Color3.fromRGB(226, 64, 74), Blurb = "No mercy at all" },
	TrueHardcore = { Name = "True Hardcore", Skulls = 4, Color = Color3.fromRGB(232, 120, 60), Blurb = "The real fight" },
	Hardcore = { Name = "Hardcore", Skulls = 3, Color = Color3.fromRGB(240, 186, 70), Blurb = "A proper test" },
	NerfedHardcore = { Name = "Nerfed Hardcore", Skulls = 2, Color = Color3.fromRGB(150, 200, 96), Blurb = "Room to learn" },
	Easy = { Name = "Easy", Skulls = 1, Color = Color3.fromRGB(110, 190, 225), Blurb = "See the story" },
}
local function difficultyName(id)
	return DIFFICULTY[id] and DIFFICULTY[id].Name or tostring(id)
end

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function readRoster(room)
	local ok, list = pcall(function()
		return HttpService:JSONDecode(room:GetAttribute("Roster") or "[]")
	end)
	return ok and list or {}
end

local function classDef(id)
	return ClassConfig.Classes[id]
end

-- billboards over the portals ----------------------------------------------------------------------------------------
local rooms = {} -- index -> { model, pad, label }

local function describeRoom(room)
	local count = room:GetAttribute("MemberCount") or 0
	if count == 0 then
		return "Portal " .. (room:GetAttribute("Index") or "") .. "\nStep on the ring to gather a party"
	end
	local lines = { string.format("%d/%d  ·  %s%s", count, Config.PartyMax, difficultyName(room:GetAttribute("Difficulty")), room:GetAttribute("Enraged") and "  ·  ENRAGED" or "") }
	local leader = room:GetAttribute("LeaderUserId")
	for _, member in readRoster(room) do
		local def = classDef(member.class)
		table.insert(lines, (member.userId == leader and "\u{2605} " or "") .. member.name .. " (" .. (def and def.Name or tostring(member.class)) .. ")")
	end
	local phase = room:GetAttribute("Phase")
	if phase == "Countdown" then
		table.insert(lines, "Starting...")
	elseif phase == "Locked" then
		table.insert(lines, "Launching")
	end
	return table.concat(lines, "\n")
end

local function bindRoom(index, model)
	local pad = model:WaitForChild("Pad", 30)
	if not pad or not pad:IsA("BasePart") then
		return
	end
	model:SetAttribute("Index", index)
	local board = make("BillboardGui", { Name = "RosterBillboard", Size = UDim2.fromOffset(260, 130), StudsOffset = Vector3.new(0, 6, 0), MaxDistance = 90, Adornee = pad }, pad)
	local label = make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.25, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 14, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top }, board)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, label)
	make("UIStroke", { Color = GOLD, Thickness = 1.5 }, label)
	rooms[index] = { model = model, pad = pad, label = label }
	local function refreshBoard()
		label.Text = describeRoom(model)
	end
	for _, attribute in { "Phase", "LeaderUserId", "Difficulty", "Enraged", "MemberCount", "Roster" } do
		model:GetAttributeChangedSignal(attribute):Connect(refreshBoard)
	end
	refreshBoard()
end

-- the expedition board --------------------------------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "PartyGui", ResetOnSpawn = false, DisplayOrder = 6 }, player:WaitForChild("PlayerGui"))
local panel = make("Frame", { Name = "Expedition", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(0.96, 0, 0, 270), BackgroundColor3 = INK, BackgroundTransparency = 0.05, Visible = false }, gui)
make("UISizeConstraint", { MaxSize = Vector2.new(1060, 270) }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
make("UIStroke", { Color = GOLD, Thickness = 2 }, panel)

local title = make("TextLabel", { Position = UDim2.fromOffset(18, 8), Size = UDim2.new(0.5, 0, 0, 34), BackgroundTransparency = 1, Font = TITLE_FONT, TextSize = 30, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Text = "Portal" }, panel)
local hint = make("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 12), Size = UDim2.new(0.5, -18, 0, 24), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Color3.fromRGB(200, 192, 180), TextXAlignment = Enum.TextXAlignment.Right, Text = "" }, panel)

-- five cards across the top
local cardRow = make("Frame", { Position = UDim2.fromOffset(16, 46), Size = UDim2.new(1, -32, 0, 134), BackgroundTransparency = 1 }, panel)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, cardRow)

local cards = {}
for order, id in Config.Difficulties do
	local info = DIFFICULTY[id]
	local card = make("TextButton", { Name = id, LayoutOrder = order, Size = UDim2.new(0.2, -7, 1, 0), BackgroundColor3 = CARD, Text = "", AutoButtonColor = true }, cardRow)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
	local stroke = make("UIStroke", { Color = info.Color, Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
	make("Frame", { Size = UDim2.new(1, -20, 0, 4), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = info.Color, BorderSizePixel = 0 }, card)
	local name = make("TextLabel", { Position = UDim2.fromOffset(10, 20), Size = UDim2.new(1, -20, 0, 42), BackgroundTransparency = 1, Font = TITLE_FONT, TextSize = 24, TextColor3 = Color3.new(1, 1, 1), TextWrapped = true, Text = info.Name, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, card)
	local skulls = make("TextLabel", { Position = UDim2.fromOffset(10, 64), Size = UDim2.new(1, -20, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = info.Color, TextXAlignment = Enum.TextXAlignment.Left, Text = string.rep("\u{2620} ", info.Skulls) }, card)
	local blurb = make("TextLabel", { Position = UDim2.fromOffset(10, 84), Size = UDim2.new(1, -20, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(200, 192, 180), TextXAlignment = Enum.TextXAlignment.Left, Text = info.Blurb }, card)
	local pay = make("TextLabel", { Position = UDim2.fromOffset(10, 104), Size = UDim2.new(1, -20, 0, 22), BackgroundTransparency = 1, Font = TITLE_FONT, TextSize = 21, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, card)
	card.Activated:Connect(function()
		remote:FireServer("SetConfig", id)
	end)
	cards[id] = { button = card, stroke = stroke, name = name, skulls = skulls, blurb = blurb, pay = pay, color = info.Color }
end

-- bottom row: who is going, the Enraged seal, and the two actions
local rosterLabel = make("TextLabel", { Position = UDim2.fromOffset(16, 190), Size = UDim2.new(1, -620, 0, 68), BackgroundColor3 = CARD, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = "" }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, rosterLabel)
make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }, rosterLabel)

local enragedButton = make("TextButton", { Name = "Enraged", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -424, 0, 190), Size = UDim2.fromOffset(180, 68), BackgroundColor3 = CARD, Font = TITLE_FONT, TextSize = 24, TextColor3 = Color3.new(1, 1, 1), Text = "Enraged" }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, enragedButton)
make("UIStroke", { Color = Color3.fromRGB(226, 64, 74), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, enragedButton)

local startButton = make("TextButton", { Name = "Start", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -120, 0, 190), Size = UDim2.fromOffset(292, 68), BackgroundColor3 = GOLD, Font = TITLE_FONT, TextSize = 32, TextColor3 = INK, Text = "Enter" }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, startButton)
local leaveButton = make("TextButton", { Name = "Leave", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 190), Size = UDim2.fromOffset(92, 68), BackgroundColor3 = OFF, Font = TITLE_FONT, TextSize = 22, TextColor3 = Color3.new(1, 1, 1), Text = "Leave" }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, leaveButton)

local toast = make("TextLabel", { Name = "Toast", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -296), Size = UDim2.fromOffset(460, 34), BackgroundColor3 = INK, BackgroundTransparency = 0.1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 15, Text = "", Visible = false }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, toast)
local toastToken = 0
local function showToast(text, seconds)
	toastToken += 1
	local mine = toastToken
	toast.Text = text
	toast.Visible = text ~= ""
	task.delay(seconds or 3, function()
		if toastToken == mine then
			toast.Visible = false
		end
	end)
end

local function currentRoom()
	local index = player:GetAttribute("PartyRoom")
	return index and rooms[index] and rooms[index].model or nil
end

local function style(button, enabled, color)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = enabled and color or OFF
	button.TextTransparency = enabled and 0 or 0.45
end

local function refreshPanel()
	local room = currentRoom()
	panel.Visible = room ~= nil
	if not room then
		return
	end
	local leader = room:GetAttribute("LeaderUserId")
	local isLeader = leader == player.UserId
	local phase = room:GetAttribute("Phase")
	local difficulty = room:GetAttribute("Difficulty")
	local enraged = room:GetAttribute("Enraged") == true
	local open = phase == "Open"
	local canEdit = isLeader and open

	title.Text = "Portal " .. tostring(room:GetAttribute("Index")) .. "  -  Choose your trial"
	hint.Text = isLeader and "You lead. Pick a trial, then Enter." or "The leader chooses the trial."

	local lines = {}
	for _, member in readRoster(room) do
		local def = classDef(member.class)
		table.insert(lines, (member.userId == leader and "\u{2605} " or "    ") .. member.name .. "  -  " .. (def and def.Name or tostring(member.class)))
	end
	rosterLabel.Text = table.concat(lines, "\n")

	for id, ui in cards do
		local chosen = id == difficulty
		ui.button.Active, ui.button.AutoButtonColor = canEdit, canEdit
		ui.button.BackgroundColor3 = chosen and Color3.fromRGB(78, 62, 36) or CARD
		ui.stroke.Thickness = chosen and 3.5 or 1.2
		ui.stroke.Transparency = (chosen or canEdit) and 0 or 0.6
		local allow = enraged and Config.EnragedAllowed(id)
		local amount = CashRules.payout(id, allow)
		ui.pay.Text = "+" .. amount .. " cash"
		ui.name.TextTransparency = (chosen or canEdit) and 0 or 0.4
	end

	local allowed = Config.EnragedAllowed(difficulty)
	enragedButton.Text = not allowed and "No Enraged on Easy" or enraged and "ENRAGED  x2 cash" or "Enraged: off"
	enragedButton.TextSize = allowed and 24 or 18
	style(enragedButton, canEdit and allowed, enraged and Color3.fromRGB(190, 44, 54) or CARD)
	if enraged and allowed and not canEdit then
		enragedButton.BackgroundColor3 = Color3.fromRGB(120, 40, 46)
		enragedButton.TextTransparency = 0
	end

	if phase == "Countdown" then
		style(startButton, isLeader, Color3.fromRGB(230, 140, 90))
		startButton.Text = "Cancel"
	else
		style(startButton, canEdit, GOLD)
		startButton.Text = isLeader and "Enter" or "Waiting..."
	end
	style(leaveButton, phase ~= "Locked", OFF)
end

enragedButton.Activated:Connect(function()
	local room = currentRoom()
	if room and enragedButton.Active then
		remote:FireServer("SetConfig", room:GetAttribute("Difficulty"), not (room:GetAttribute("Enraged") == true))
	end
end)
startButton.Activated:Connect(function()
	local room = currentRoom()
	if room then
		remote:FireServer(room:GetAttribute("Phase") == "Countdown" and "Cancel" or "Start")
	end
end)
leaveButton.Activated:Connect(function()
	remote:FireServer("Leave")
end)

RunService.RenderStepped:Connect(function()
	local room = currentRoom()
	if not room or room:GetAttribute("Phase") ~= "Countdown" then
		return
	end
	local endsAt = room:GetAttribute("CountdownEndsAt")
	if endsAt then
		local left = math.max(0, endsAt - workspace:GetServerTimeNow())
		startButton.Text = room:GetAttribute("LeaderUserId") == player.UserId and string.format("Cancel  (%.0f)", left) or string.format("Starting in %.0f", left)
	end
end)

remote.OnClientEvent:Connect(function(action, data)
	if action == "Result" and type(data) == "table" and data.Message and data.Message ~= "" then
		showToast(data.Message, 3.5)
	elseif action == "DryRun" then
		print("[Lobby] dry-run launch payload: " .. tostring(data))
		showToast("Dry run: the party would launch now (payload printed in the output)", 5)
	end
end)

player:GetAttributeChangedSignal("PartyRoom"):Connect(refreshPanel)

local function watchRoom(model)
	for _, attribute in { "Phase", "LeaderUserId", "Difficulty", "Enraged", "Roster", "CountdownEndsAt" } do
		model:GetAttributeChangedSignal(attribute):Connect(refreshPanel)
	end
end

task.spawn(function()
	local folder = workspace:WaitForChild("PartyRooms", 30)
	if not folder then
		return
	end
	for index = 1, Config.PartyRooms do
		local model = folder:WaitForChild("Room" .. index, 10)
		if model then
			bindRoom(index, model)
			watchRoom(model)
		end
	end
	refreshPanel()
end)

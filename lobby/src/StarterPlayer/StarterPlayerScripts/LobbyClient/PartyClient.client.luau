--!nonstrict
-- The party portals in the palace. Reads the room's replicated attributes (see PartyService) and sends intents on the PartyControl remote.
-- Nothing here decides anything: a non-leader's buttons are read-only for show and the server refuses their requests anyway.
--   * a small panel while you are in a room: five difficulty buttons, what the pick pays, Enraged, Enter and Leave
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
local OFF = Color3.fromRGB(58, 53, 49)
local SOFT = Color3.fromRGB(200, 192, 180)

-- Hardest on the left, the order the boss's own picker uses. The chosen button takes the difficulty's colour.
local DIFFICULTY = {
	Hellaven = { Name = "Hellaven", Color = Color3.fromRGB(226, 64, 74), Blurb = "No mercy at all" },
	TrueHardcore = { Name = "True Hardcore", Color = Color3.fromRGB(232, 120, 60), Blurb = "The real fight" },
	Hardcore = { Name = "Hardcore", Color = Color3.fromRGB(240, 186, 70), Blurb = "A proper test" },
	NerfedHardcore = { Name = "Nerfed Hardcore", Color = Color3.fromRGB(150, 200, 96), Blurb = "Room to learn" },
	Easy = { Name = "Easy", Color = Color3.fromRGB(110, 190, 225), Blurb = "See the story" },
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

-- the party panel: five difficulty buttons, one line saying what the pick pays, Enraged, Enter, Leave ---------------------------
local gui = make("ScreenGui", { Name = "PartyGui", ResetOnSpawn = false, DisplayOrder = 6 }, player:WaitForChild("PlayerGui"))
local panel = make("Frame", { Name = "Party", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(0.96, 0, 0, 172), BackgroundColor3 = INK, BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false }, gui)
make("UISizeConstraint", { MaxSize = Vector2.new(540, 172) }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)

local function line(props)
	local base = { BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = SOFT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }
	for key, value in props do
		base[key] = value
	end
	return make("TextLabel", base, panel)
end
local function action(props)
	local base = { BackgroundColor3 = CARD, Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0) }
	for key, value in props do
		base[key] = value
	end
	local b = make("TextButton", base, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	return b
end

local title = line({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(0.4, 0, 0, 22), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = GOLD })
local rosterLabel = line({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.new(0.6, -20, 0, 22), TextXAlignment = Enum.TextXAlignment.Right })

local cardRow = make("Frame", { Position = UDim2.fromOffset(14, 36), Size = UDim2.new(1, -28, 0, 40), BackgroundTransparency = 1 }, panel)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, cardRow)
local cards = {}
for order, id in Config.Difficulties do
	local info = DIFFICULTY[id]
	local card = make("TextButton", { Name = id, LayoutOrder = order, Size = UDim2.new(0.2, -5, 1, 0), BackgroundColor3 = CARD, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 13, TextWrapped = true, TextColor3 = Color3.new(1, 1, 1), Text = info.Name }, cardRow)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, card)
	card.Activated:Connect(function()
		remote:FireServer("SetConfig", id)
	end)
	cards[id] = { button = card, color = info.Color }
end

local summary = line({ Position = UDim2.fromOffset(14, 82), Size = UDim2.new(1, -28, 0, 20) })

local leaveButton = action({ Name = "Leave", Position = UDim2.new(1, -14, 0, 110), Size = UDim2.fromOffset(84, 48), Text = "Leave" })
local startButton = action({ Name = "Start", Position = UDim2.new(1, -104, 0, 110), Size = UDim2.fromOffset(200, 48), Font = Enum.Font.GothamBold, TextSize = 18, Text = "Enter" })
local enragedButton = action({ Name = "Enraged", AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(14, 110), Size = UDim2.new(1, -332, 0, 48), Text = "Enraged" })

local toast = make("TextLabel", { Name = "Toast", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -196), Size = UDim2.fromOffset(460, 34), BackgroundColor3 = INK, BackgroundTransparency = 0.1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 15, Text = "", Visible = false }, gui)
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

local function style(button, enabled, color, textColor)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = enabled and color or OFF
	button.TextColor3 = enabled and textColor or Color3.new(1, 1, 1)
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
	local canEdit = isLeader and phase == "Open"

	title.Text = "Portal " .. tostring(room:GetAttribute("Index"))
	local names = {}
	for _, member in readRoster(room) do
		local def = classDef(member.class)
		table.insert(names, (member.userId == leader and "\u{2605} " or "") .. member.name .. " (" .. (def and def.Name or tostring(member.class)) .. ")")
	end
	rosterLabel.Text = table.concat(names, ",  ")

	for id, ui in cards do
		local chosen = id == difficulty
		ui.button.Active, ui.button.AutoButtonColor = canEdit, canEdit
		ui.button.BackgroundColor3 = chosen and ui.color or CARD
		ui.button.TextColor3 = chosen and INK or Color3.new(1, 1, 1)
		ui.button.TextTransparency = (chosen or canEdit) and 0 or 0.5
	end

	local allowed = Config.EnragedAllowed(difficulty)
	local info = DIFFICULTY[difficulty]
	summary.Text = string.format("%s  \u{00B7}  pays %d cash%s", info and info.Blurb or "", CashRules.payout(difficulty, enraged and allowed), isLeader and "" or "  \u{00B7}  the leader chooses")
	enragedButton.Text = not allowed and "No Enraged on Easy" or enraged and "Enraged: ON  (x2 cash)" or "Enraged: off"
	style(enragedButton, canEdit and allowed, enraged and Color3.fromRGB(190, 44, 54) or CARD, Color3.new(1, 1, 1))
	if enraged and allowed and not canEdit then
		enragedButton.BackgroundColor3 = Color3.fromRGB(120, 40, 46)
		enragedButton.TextTransparency = 0
	end

	if phase == "Countdown" then
		style(startButton, isLeader, Color3.fromRGB(230, 140, 90), INK)
		startButton.Text = "Cancel"
	else
		style(startButton, canEdit, GOLD, INK)
		startButton.Text = isLeader and "Enter" or "Waiting..."
	end
	style(leaveButton, phase ~= "Locked", CARD, Color3.new(1, 1, 1))
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

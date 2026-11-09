--!nonstrict
-- Party room UI (plan task 16). Reads the room's replicated attributes (see PartyService) and sends intents on the
-- PartyControl remote. Nothing here decides anything: a non-leader's buttons are disabled for show, and the server
-- refuses their requests anyway.
--   * a panel while you are in a room: roster with classes, difficulty buttons, Enraged toggle, Start / Cancel, Leave,
--     countdown. Non-leaders see the settings read-only.
--   * a billboard over every pad: room number, members, settings

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.UnfairShared.UnfairConfig)
local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)

local player = Players.LocalPlayer
local remote = LobbyRemotes.get("PartyControl")

local GOLD = Color3.fromRGB(255, 196, 64)
local PANEL = Color3.fromRGB(24, 22, 30)
local CARD = Color3.fromRGB(38, 35, 46)
local OFF = Color3.fromRGB(70, 66, 80)

local DIFFICULTY_NAMES = {
	Hellaven = "Hellaven", TrueHardcore = "True Hardcore", Hardcore = "Hardcore", NerfedHardcore = "Nerfed Hardcore", Easy = "Easy",
}
local function difficultyName(id)
	return DIFFICULTY_NAMES[id] or tostring(id)
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

local function className(id)
	local def = ClassConfig.Classes[id]
	return def and def.Name or tostring(id)
end

-- billboards over the pads ---------------------------------------------------------------------------------------
local rooms = {} -- index -> { model, pad, label }

local function describeRoom(room)
	local count = room:GetAttribute("MemberCount") or 0
	if count == 0 then
		return "Party Room " .. (room:GetAttribute("Index") or "") .. "\nEmpty - step on the pad"
	end
	local lines = { string.format("%d/%d  ·  %s%s", count, Config.PartyMax, difficultyName(room:GetAttribute("Difficulty")), room:GetAttribute("Enraged") and "  ·  ENRAGED" or "") }
	local leader = room:GetAttribute("LeaderUserId")
	for _, member in readRoster(room) do
		table.insert(lines, (member.userId == leader and "\u{2605} " or "") .. member.name .. " (" .. className(member.class) .. ")")
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
	local pad = model:WaitForChild("Pad", 30) -- the pad may still be streaming in
	if not pad or not pad:IsA("BasePart") then
		return
	end
	model:SetAttribute("Index", index)
	local board = make("BillboardGui", {
		Name = "RosterBillboard", Size = UDim2.fromOffset(260, 130), StudsOffset = Vector3.new(0, 6, 0), AlwaysOnTop = false, MaxDistance = 90, Adornee = pad,
	}, pad)
	local label = make("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = PANEL, BackgroundTransparency = 0.25, TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamMedium, TextSize = 14, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
	}, board)
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

-- the panel --------------------------------------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "PartyGui", ResetOnSpawn = false, DisplayOrder = 6 }, player:WaitForChild("PlayerGui"))
local panel = make("Frame", {
	Name = "PartyPanel", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(300, 470),
	BackgroundColor3 = PANEL, Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
make("UIStroke", { Color = GOLD, Thickness = 2 }, panel)
local title = make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 6), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Party Room", TextColor3 = GOLD, Font = Enum.Font.GothamBold, TextSize = 20,
}, panel)
local rosterLabel = make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 120), Position = UDim2.fromOffset(8, 38), BackgroundColor3 = CARD, TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextSize = 14, Text = "",
}, panel)
make("UICorner", { CornerRadius = UDim.new(0, 6) }, rosterLabel)
make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6) }, rosterLabel)

make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 164), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Difficulty", TextColor3 = Color3.fromRGB(205, 200, 215), Font = Enum.Font.GothamBold, TextSize = 14,
}, panel)
local difficultyButtons = {}
for i, id in Config.Difficulties do
	local button = make("TextButton", {
		Name = id, Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 186 + (i - 1) * 32), BackgroundColor3 = CARD,
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 14, Text = difficultyName(id),
	}, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
	button.Activated:Connect(function()
		remote:FireServer("SetConfig", id) -- enraged omitted: the server keeps it, and clears it on Easy
	end)
	difficultyButtons[id] = button
end
local enragedButton = make("TextButton", {
	Name = "Enraged", Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 350), BackgroundColor3 = CARD,
	TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, Text = "Enraged: OFF",
}, panel)
make("UICorner", { CornerRadius = UDim.new(0, 6) }, enragedButton)
local startButton = make("TextButton", {
	Name = "Start", Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 388), BackgroundColor3 = Color3.fromRGB(110, 200, 120),
	TextColor3 = Color3.new(0, 0, 0), Font = Enum.Font.GothamBold, TextSize = 16, Text = "Start",
}, panel)
make("UICorner", { CornerRadius = UDim.new(0, 6) }, startButton)
local leaveButton = make("TextButton", {
	Name = "Leave", Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 430), BackgroundColor3 = OFF,
	TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 13, Text = "Leave room",
}, panel)
make("UICorner", { CornerRadius = UDim.new(0, 6) }, leaveButton)

local toast = make("TextLabel", {
	Name = "Toast", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -70), Size = UDim2.fromOffset(420, 32),
	BackgroundColor3 = PANEL, BackgroundTransparency = 0.1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 15,
	Text = "", Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, toast)
local toastToken = 0
local function showToast(text, seconds)
	toastToken += 1
	local mine = toastToken
	toast.Text = text
	toast.Visible = text ~= ""
	task.delay(seconds or 3, function()
		if toastToken == mine then toast.Visible = false end
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
	button.TextTransparency = enabled and 0 or 0.5
end

local function refreshPanel()
	local room = currentRoom()
	panel.Visible = room ~= nil
	if not room then
		return
	end
	local isLeader = room:GetAttribute("LeaderUserId") == player.UserId
	local phase = room:GetAttribute("Phase")
	local difficulty = room:GetAttribute("Difficulty")
	local enraged = room:GetAttribute("Enraged") == true
	local open = phase == "Open"

	title.Text = "Party Room " .. tostring(room:GetAttribute("Index")) .. (isLeader and "  (leader)" or "")
	local lines = {}
	local leader = room:GetAttribute("LeaderUserId")
	for _, member in readRoster(room) do
		table.insert(lines, (member.userId == leader and "\u{2605} " or "   ") .. member.name .. "  -  " .. className(member.class))
	end
	rosterLabel.Text = table.concat(lines, "\n")

	for id, button in difficultyButtons do
		local selected = id == difficulty
		style(button, isLeader and open, selected and GOLD or CARD)
		button.TextColor3 = selected and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		if selected and not (isLeader and open) then
			button.BackgroundColor3 = GOLD
			button.TextTransparency = 0
		end
	end
	local enragedAllowed = difficulty ~= "Easy"
	enragedButton.Text = enragedAllowed and ("Enraged: " .. (enraged and "ON" or "OFF")) or "Enraged: not on Easy"
	style(enragedButton, isLeader and open and enragedAllowed, enraged and Color3.fromRGB(220, 60, 70) or CARD)
	if enraged and enragedAllowed and not (isLeader and open) then
		enragedButton.BackgroundColor3 = Color3.fromRGB(150, 50, 60)
		enragedButton.TextTransparency = 0
	end

	if phase == "Countdown" then
		style(startButton, isLeader, Color3.fromRGB(230, 140, 90))
		startButton.Text = "Cancel"
	else
		style(startButton, isLeader and phase == "Open", Color3.fromRGB(110, 200, 120))
		startButton.Text = isLeader and "Start" or "Waiting for the leader"
	end
	style(leaveButton, phase ~= "Locked", OFF)
end

enragedButton.Activated:Connect(function()
	local room = currentRoom()
	if room then
		remote:FireServer("SetConfig", room:GetAttribute("Difficulty"), not (room:GetAttribute("Enraged") == true))
	end
end)
startButton.Activated:Connect(function()
	local room = currentRoom()
	if not room then return end
	remote:FireServer(room:GetAttribute("Phase") == "Countdown" and "Cancel" or "Start")
end)
leaveButton.Activated:Connect(function()
	remote:FireServer("Leave")
end)

-- live countdown text on the Start button while counting down
RunService.RenderStepped:Connect(function()
	local room = currentRoom()
	if not room or room:GetAttribute("Phase") ~= "Countdown" then
		return
	end
	local endsAt = room:GetAttribute("CountdownEndsAt")
	if endsAt and room:GetAttribute("LeaderUserId") == player.UserId then
		startButton.Text = string.format("Cancel (%.0f)", math.max(0, endsAt - workspace:GetServerTimeNow()))
	elseif endsAt then
		startButton.Text = string.format("Starting in %.0f...", math.max(0, endsAt - workspace:GetServerTimeNow()))
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
		return -- the map is not built yet
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

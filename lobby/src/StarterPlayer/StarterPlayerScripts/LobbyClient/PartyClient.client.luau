--!nonstrict
-- The party portals in the palace. Reads the room's replicated attributes (see PartyService) and sends intents on the PartyControl remote.
-- Nothing here decides anything: a non-leader's buttons are read-only for show and the server refuses their requests anyway.
--   * the trial panel while you are in a room, in the look of the boss place's old trial picker (BossShared TrialMenuKit):
--     a plate per trial, the boss's words and the numbers for the one shown, Enraged, Enter and Leave
--   * a billboard over every portal
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.UnfairShared.UnfairConfig)
local CashRules = require(ReplicatedStorage.UnfairShared.CashRules)
local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local Difficulty = require(ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Kit = require(ReplicatedStorage.BossShared.Presentation.TrialMenuKit)
local StatusIcons = require(ReplicatedStorage.BossShared.Presentation.StatusIcons)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)

local player = Players.LocalPlayer
local remote = LobbyRemotes.get("PartyControl")
local C, F = Kit.Colors, Kit.Fonts

local INK = Color3.fromRGB(16, 13, 12)
local GOLD = C.Gold

local function profile(id)
	return Difficulty.Profiles[id]
end
local function difficultyName(id)
	local p = profile(id)
	return p and p.Name or tostring(id)
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

-- the trial panel ---------------------------------------------------------------------------------------------------------
local W, H = 820, 356
local gui = make("ScreenGui", { Name = "PartyGui", ResetOnSpawn = false, DisplayOrder = 6, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
local panel = make("Frame", { Name = "Party", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(W, H), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.04, BorderSizePixel = 0, Visible = false }, gui)
make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(34, 27, 19), Color3.fromRGB(7, 6, 5)) }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
make("UIStroke", { Color = C.GoldDim, Transparency = 0.25, Thickness = 1.2 }, panel)
local scale = make("UIScale", {}, panel)
local function rescale()
	local cam = workspace.CurrentCamera
	if cam then
		scale.Scale = math.min(1, (cam.ViewportSize.X - 24) / W, (cam.ViewportSize.Y * 0.62) / H)
	end
end
rescale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

Kit.Text(panel, { Text = Kit.Spaced("The Trial of Golden"), FontFace = F.Caps, TextSize = 12, TextColor3 = C.GoldDim, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(500, 14) })
local title = Kit.Text(panel, { Text = "Portal", FontFace = F.Title, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 26), Size = UDim2.fromOffset(500, 34) })
Kit.Ornament(panel, 62, 320)
local rosterLabel = Kit.Text(panel, { FontFace = F.Italic, TextSize = 14, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 78), Size = UDim2.fromOffset(760, 18), TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })

-- a tall plate per trial, hardest first
local plates, previewId = {}, nil
local show
local PW, PH, PGAP = 150, 176, 14
for i, id in Difficulty.Order do
	local p = profile(id)
	local lives = p.StartingLives == 1 and "One life" or (p.StartingLives .. " lives")
	local plate = Kit.Plate(panel, {
		Id = id, Glyph = "", Name = p.Name, NameSize = 15, Note = lives, Color = p.Color,
		Position = UDim2.fromOffset(24 + (i - 1) * (PW + PGAP), 108), Size = UDim2.fromOffset(PW, PH),
	})
	pcall(function()
		StatusIcons.Create(plate.Button, "Diff" .. id, UDim2.fromOffset(52, 52), UDim2.fromOffset((PW - 52) / 2, 34), p.Color)
	end)
	plates[id] = plate
	plate.Button.MouseEnter:Connect(function()
		previewId = id
		show(id)
	end)
	plate.Button.MouseLeave:Connect(function()
		if previewId == id then
			previewId = nil
			show(nil)
		end
	end)
	plate.Button.Activated:Connect(function()
		previewId = nil
		remote:FireServer("SetConfig", id)
	end)
end

-- the shown trial: name, the boss's words, the description, the numbers
local DX = 24 + #Difficulty.Order * (PW + PGAP) + 6
Kit.Frame(panel, { Position = UDim2.fromOffset(DX - 12, 112), Size = UDim2.fromOffset(1, 168), BackgroundTransparency = 0.6, BackgroundColor3 = C.GoldDim })
local DW = W - DX - 22
local detail = Kit.Frame(panel, { Position = UDim2.fromOffset(DX, 104), Size = UDim2.fromOffset(DW, 120) })
make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, detail)
local trialName = Kit.Text(detail, { FontFace = F.Title, TextSize = 26, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 28) })
local quote = Kit.Text(detail, { FontFace = F.Italic, TextSize = 15, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
Kit.Text(detail, { Text = Kit.Spaced("— alterGolden"), FontFace = F.Caps, TextSize = 10, TextColor3 = C.GoldDim, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 12) })
local blurb = Kit.Text(detail, { FontFace = F.Body, TextSize = 14, TextColor3 = C.Muted, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
local GW = math.floor((DW - 20) / 2)
local damage = Kit.Gauge(panel, UDim2.fromOffset(DX, 236), GW, "Boss damage")
local pace = Kit.Gauge(panel, UDim2.fromOffset(DX + GW + 20, 236), GW, "Attack pace")
local density = Kit.Gauge(panel, UDim2.fromOffset(DX, 270), GW, "Attack density")
local lives = Kit.Pips(panel, UDim2.fromOffset(DX + GW + 20, 270), GW, "Lives", 5)

-- the bottom row: what it pays, Enraged, Enter, Leave
local summary = Kit.Text(panel, { FontFace = F.Italic, TextSize = 15, TextColor3 = C.Gold, Position = UDim2.fromOffset(24, H - 46), Size = UDim2.fromOffset(250, 36), TextYAlignment = Enum.TextYAlignment.Center })

local function action(props)
	local base = { BackgroundColor3 = C.Plate, FontFace = F.Caps, TextSize = 18, TextColor3 = C.Ivory, BorderSizePixel = 0, AutoButtonColor = true }
	for key, value in props do
		base[key] = value
	end
	local b = make("TextButton", base, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	make("UIStroke", { Color = C.GoldDim, Transparency = 0.3, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	return b
end
local enragedButton = action({ Name = "Enraged", Position = UDim2.fromOffset(W - 520, H - 50), Size = UDim2.fromOffset(196, 40), Text = "Enraged: off" })
local startButton = action({ Name = "Start", Position = UDim2.fromOffset(W - 314, H - 50), Size = UDim2.fromOffset(190, 40), FontFace = F.Title, TextSize = 22, Text = "Enter" })
local leaveButton = action({ Name = "Leave", Position = UDim2.fromOffset(W - 114, H - 50), Size = UDim2.fromOffset(92, 40), Text = "Leave" })

local toast = make("TextLabel", { Name = "Toast", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -(H + 24)), Size = UDim2.fromOffset(460, 34), BackgroundColor3 = INK, BackgroundTransparency = 0.1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 15, Text = "", Visible = false }, gui)
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

local function frac(v, lo, hi)
	return (v - lo) / (hi - lo)
end
show = function(id)
	local room = currentRoom()
	id = id or (room and room:GetAttribute("Difficulty")) or Config.DefaultDifficulty
	local p = profile(id)
	if not p then
		return
	end
	trialName.Text = p.Name
	trialName.TextColor3 = p.Color
	quote.Text = "\u{201C}" .. table.concat(p.PickLines, " ") .. "\u{201D}"
	blurb.Text = p.Description
	local speed = 1 / (p.Recovery or 1)
	damage(frac(p.Damage, 0.3, 1.4), string.format("× %.2f", p.Damage), p.Color)
	pace(frac(speed, 0.45, 1.3), string.format("× %.2f", speed), p.Color)
	density(frac(p.Density or 1, 0.35, 1.3), string.format("× %.2f", p.Density or 1), p.Color)
	lives(p.StartingLives, p.StartingLives == 1 and "one" or tostring(p.StartingLives), p.Color)
end

local function style(button, enabled, color, textColor)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = enabled and color or Color3.fromRGB(44, 40, 36)
	button.TextColor3 = enabled and textColor or C.Muted
	button.TextTransparency = enabled and 0 or 0.35
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
	rosterLabel.Text = table.concat(names, ",  ") .. (isLeader and "" or "   ·   the leader chooses")

	for id, plate in plates do
		local chosen = id == difficulty
		plate:Set(chosen, chosen and (phase == "Locked" and "Sealed" or "Chosen") or nil)
		plate.Button.Active = canEdit
	end
	show(previewId)

	local allowed = Config.EnragedAllowed(difficulty)
	summary.Text = string.format("Pays %d cash", CashRules.payout(difficulty, enraged and allowed))
	enragedButton.Text = enraged and "Enraged: ON  (x2 cash)" or "Enraged: off"
	style(enragedButton, canEdit and allowed, enraged and Color3.fromRGB(150, 34, 44) or C.Plate, C.Ivory)
	if enraged and not canEdit then
		enragedButton.BackgroundColor3 = Color3.fromRGB(110, 36, 42)
		enragedButton.TextTransparency = 0
	end

	if phase == "Countdown" then
		style(startButton, isLeader, Color3.fromRGB(196, 120, 76), INK)
		startButton.Text = "Cancel"
	else
		style(startButton, canEdit, GOLD, INK)
		startButton.Text = isLeader and "Enter" or "Waiting..."
	end
	style(leaveButton, phase ~= "Locked", C.Plate, C.Ivory)
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

--!nonstrict
--[[
 The shop (docs/spec/lobby-redesign.md). Press E at the Keeper and he talks to you: his words float over his head and three numbered
 answers appear beside him (press 1, 2, 3 or click one). Walking away ends the conversation. No dialogue box.
   1. Classes  -> the class showroom: a wooden performer on the training stage uses the class's real skills on the target dummy
                  (TryoutService). You only watch; pick a skill on the right and the performer uses it.
   2. Orbs     -> the orb dais, a dummy that only exists on your client.
   3. Lore     -> he tells you the story himself.
 Every button only asks the server; prices and ownership are decided there (ShopService, ClassPickService).
]]
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local ClassUnlocks = require(ReplicatedStorage.BossShared.Classes.ClassUnlocks)
local StatusIcons = require(ReplicatedStorage.BossShared.Presentation.StatusIcons)
local OrbConfig = require(ReplicatedStorage.UnfairShared.OrbConfig)
local Fade = require(ReplicatedStorage.Lobby.Fade)
local Freeze = require(ReplicatedStorage.Lobby.Freeze)
local Lore = require(ReplicatedStorage.Lobby.Lore)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)
local NpcDialog = require(ReplicatedStorage.UnfairShared.NpcDialog)
local Rig = require(ReplicatedStorage.Lobby.Rig)
local ShowcaseMoves = require(ReplicatedStorage.Lobby.ShowcaseMoves)
local SkillDemos = require(ReplicatedStorage.Lobby.SkillDemos)

local player = Players.LocalPlayer
local shopRemote = LobbyRemotes.get("Shop")
local classRemote = LobbyRemotes.get("ClassPick")
local tryRemote = LobbyRemotes.get("Tryout")

local GOLD = Color3.fromRGB(246, 211, 117)
local GOLD_DIM = Color3.fromRGB(150, 124, 70)
local INK = Color3.fromRGB(18, 15, 14)
local CARD = Color3.fromRGB(38, 32, 28)
local TRACK = Color3.fromRGB(58, 50, 40)
local TEXT = Color3.fromRGB(226, 220, 208)
local DIM = Color3.fromRGB(160, 152, 140)
local HIDDEN = Color3.fromRGB(205, 150, 255)
local TITLE_FONT = Enum.Font.Garamond
local BODY_FONT = Enum.Font.Gotham

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function round(parent, radius, strokeColor, thickness)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
	if strokeColor then
		make("UIStroke", { Color = strokeColor, Thickness = thickness or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
	end
end

local function text(parent, props)
	local base = { BackgroundTransparency = 1, Font = BODY_FONT, TextColor3 = TEXT, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }
	for key, value in props do
		base[key] = value
	end
	return make("TextLabel", base, parent)
end

local function button(parent, props, onClick)
	local base = { BackgroundColor3 = CARD, Font = TITLE_FONT, TextColor3 = TEXT, TextSize = 22, AutoButtonColor = true }
	for key, value in props do
		base[key] = value
	end
	local b = make("TextButton", base, parent)
	round(b, 8, GOLD, 1.2)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

local gui = make("ScreenGui", { Name = "ShopGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50, Enabled = false }, player:WaitForChild("PlayerGui"))

-- The showroom UI: list on the left (Back under it), the stage in the middle, details on the right -----------------------
local view = make("Frame", { Name = "Showroom", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, gui)

local topBar = make("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = INK, BackgroundTransparency = 0.25, BorderSizePixel = 0 }, view)
local heading = text(topBar, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.5, 0, 1, 0), Font = TITLE_FONT, TextSize = 36, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center })
local cashLabel = text(topBar, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(220, 30), TextSize = 22, Font = TITLE_FONT, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center })

local listPanel = make("ScrollingFrame", { Name = "List", Position = UDim2.new(0, 14, 0, 72), Size = UDim2.new(0.22, 0, 1, -150), BackgroundColor3 = INK, BackgroundTransparency = 0.12, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, view)
round(listPanel, 10)
make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, listPanel)
make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, listPanel)
-- Back sits under the list, bottom left: well away from Roblox's own menu buttons in the top-left corner
local backButton = button(view, { Name = "Back", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -14), Size = UDim2.new(0.22, 0, 0, 54), Text = "\u{2190}  Back to the Keeper", TextSize = 24 })

local info = make("ScrollingFrame", { Name = "Info", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 72), Size = UDim2.new(0.34, 0, 1, -150), BackgroundColor3 = INK, BackgroundTransparency = 0.12, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, view)
round(info, 10)
make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, info)
make("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }, info)

local function auto(label, order)
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	return label
end

local titleRow = make("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, info)
local iconHolder = make("Frame", { Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1 }, titleRow)
local nameLabel = text(titleRow, { Position = UDim2.fromOffset(54, 2), Size = UDim2.new(1, -54, 1, 0), Font = TITLE_FONT, TextSize = 36, TextColor3 = GOLD, TextYAlignment = Enum.TextYAlignment.Center, TextScaled = false })
local tagLabel = auto(text(info, { TextSize = 14 }), 2)

-- the stat sheet, like the old armoury: a labelled bar per stat
local statFrame = make("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, info)
make("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, statFrame)
local statRows = {}
for order, stat in { "HP", "Stamina", "Dash", "Speed", "Base Defense" } do
	local row = make("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1 }, statFrame)
	text(row, { Size = UDim2.new(0, 104, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = GOLD, Text = stat .. ":", TextYAlignment = Enum.TextYAlignment.Center })
	local track = make("Frame", { Position = UDim2.new(0, 108, 0.5, -4), Size = UDim2.new(1, -184, 0, 8), BackgroundColor3 = TRACK, BorderSizePixel = 0 }, row)
	round(track, 4)
	local fill = make("Frame", { Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0 }, track)
	round(fill, 4)
	local value = text(row, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 70, 1, 0), TextSize = 13, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center })
	statRows[stat] = { fill = fill, value = value }
end

local passiveTitle = auto(text(info, { Font = TITLE_FONT, TextSize = 22, TextColor3 = GOLD, Text = "Passive" }), 4)
local passiveLabel = auto(text(info, { TextSize = 13 }), 5)
local skillsTitle = auto(text(info, { Font = TITLE_FONT, TextSize = 22, TextColor3 = GOLD, Text = "Skills: pick one to watch it" }), 6)
local skillGrid = make("Frame", { Name = "Skills", LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, info)
make("UIGridLayout", { CellSize = UDim2.new(0.333, -6, 0, 38), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, skillGrid)
local skillName = auto(text(info, { Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = GOLD }), 8)
local skillBody = auto(text(info, { TextSize = 13 }), 9)
local status = auto(text(info, { TextSize = 13, TextColor3 = Color3.fromRGB(255, 170, 150), TextXAlignment = Enum.TextXAlignment.Center }), 10)
local actionButton = button(view, { Name = "Action", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.new(0.34, 0, 0, 54), TextSize = 26, TextColor3 = INK, BackgroundColor3 = GOLD })

-- State ----------------------------------------------------------------------------------------------------------------
local mode = nil -- "Classes" | "Orbs"
local selected = nil
local rig, stageFolder
local rows = {}
local performer = nil
local markAt = nil -- where the performer's mark is: the camera frames it and the dummy, and never follows a dash

local function fmt(n)
	local s = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (s:gsub("^,", ""))
end

local function cash()
	return player:GetAttribute("Cash") or 0
end

local function classOwned(id)
	return ClassUnlocks[id] == nil or player:GetAttribute("ClassUnlocked_" .. id) == true
end

local function orbOwned(id)
	return player:GetAttribute("OrbOwned_" .. id) == true
end

local function classStatus(id)
	local entry = ClassUnlocks[id]
	if player:GetAttribute("PlayerClass") == id then
		return "Equipped", GOLD
	elseif classOwned(id) then
		return entry == nil and "Free" or "Owned", Color3.fromRGB(150, 225, 150)
	elseif entry.Kind == "Cash" then
		return fmt(entry.Price) .. " cash", TEXT
	elseif entry.Kind == "GamePass" then
		return (entry.Price or "?") .. " Robux" .. (entry.Quest and " or a quest" or ""), Color3.fromRGB(150, 220, 160)
	end
	return "Earned by badge", DIM
end

local function orbStatus(id)
	if player:GetAttribute("PlayerOrb") == id then
		return "Equipped", GOLD
	elseif orbOwned(id) then
		return "Owned", Color3.fromRGB(150, 225, 150)
	end
	return fmt(OrbConfig.Items[id].Price) .. " cash", TEXT
end

local function refreshAction()
	cashLabel.Text = fmt(cash()) .. " cash"
	for id, row in rows do
		local label, color
		if mode == "Classes" then
			label, color = classStatus(id)
		else
			label, color = orbStatus(id)
		end
		row.status.Text, row.status.TextColor3 = label, color
		row.frame.BackgroundColor3 = id == selected and Color3.fromRGB(70, 56, 34) or CARD
	end
	if not selected then
		return
	end
	local enabled = true
	if mode == "Classes" then
		local entry = ClassUnlocks[selected]
		if player:GetAttribute("PlayerClass") == selected then
			actionButton.Text, enabled = "Equipped", false
		elseif classOwned(selected) then
			actionButton.Text = "Equip"
		elseif entry.Kind == "Cash" then
			if cash() >= entry.Price then
				actionButton.Text = "Buy for " .. fmt(entry.Price) .. " cash"
			else
				actionButton.Text, enabled = "Need " .. fmt(entry.Price) .. " cash", false
			end
		elseif entry.Kind == "GamePass" then
			actionButton.Text = "Buy for " .. (entry.Price or "?") .. " Robux"
			if entry.Quest then
				status.Text = entry.Hint or ""
			end
		else
			actionButton.Text, enabled = "How to earn it", false
			status.Text = entry.Hint or ""
		end
	else
		local orb = OrbConfig.Items[selected]
		if player:GetAttribute("PlayerOrb") == selected then
			actionButton.Text = "Take off"
		elseif orbOwned(selected) then
			actionButton.Text = "Equip"
		elseif cash() >= orb.Price then
			actionButton.Text = "Buy for " .. fmt(orb.Price) .. " cash"
		else
			actionButton.Text, enabled = "Need " .. fmt(orb.Price) .. " cash", false
		end
	end
	actionButton.Active, actionButton.AutoButtonColor = enabled, enabled
	actionButton.BackgroundColor3 = enabled and GOLD or Color3.fromRGB(90, 84, 76)
end

actionButton.Activated:Connect(function()
	if not actionButton.Active or not selected then
		return
	end
	status.Text = ""
	if mode == "Classes" then
		local entry = ClassUnlocks[selected]
		if classOwned(selected) then
			classRemote:FireServer("Select", selected)
		elseif entry.Kind == "Cash" then
			shopRemote:FireServer("BuyClass", selected)
		elseif entry.Kind == "GamePass" then
			classRemote:FireServer("Buy", selected)
		end
	else
		if player:GetAttribute("PlayerOrb") == selected then
			shopRemote:FireServer("EquipOrb", nil)
		elseif orbOwned(selected) then
			shopRemote:FireServer("EquipOrb", selected)
		else
			shopRemote:FireServer("BuyOrb", selected)
		end
	end
end)

shopRemote.OnClientEvent:Connect(function(action, data)
	if action == "Result" and type(data) == "table" and data.Message then
		status.Text = data.Message
		status.TextColor3 = data.Ok and Color3.fromRGB(150, 225, 150) or Color3.fromRGB(255, 170, 150)
		refreshAction()
	end
end)
classRemote.OnClientEvent:Connect(function(action, data)
	if action == "Result" and type(data) == "table" and data.Message and data.Message ~= "" then
		status.Text = data.Message
		status.TextColor3 = Color3.fromRGB(255, 170, 150)
	end
end)

player.AttributeChanged:Connect(function(name)
	if gui.Enabled and view.Visible then
		if name == "Cash" or name == "PlayerClass" or name == "PlayerOrb" or name:find("^ClassUnlocked_") or name:find("^OrbOwned_") then
			refreshAction()
		end
	end
end)

-- stats ----------------------------------------------------------------------------------------------------------------
local maxima = { HP = 1, Stamina = 1, Dash = 1, Speed = 1, ["Base Defense"] = 0.01 }
for _, id in ClassConfig.Order do
	local d = ClassConfig.Classes[id]
	maxima.HP = math.max(maxima.HP, d.HP or 0)
	maxima.Stamina = math.max(maxima.Stamina, d.Stamina or 0)
	maxima.Dash = math.max(maxima.Dash, d.DashCost or 0)
	maxima.Speed = math.max(maxima.Speed, d.Speed or 0)
	maxima["Base Defense"] = math.max(maxima["Base Defense"], d.BaseDefense or 0)
end
local function setStat(stat, value, shown, color)
	local row = statRows[stat]
	row.fill.Size = UDim2.fromScale(math.clamp(value / maxima[stat], 0.03, 1), 1)
	row.fill.BackgroundColor3 = color
	row.value.Text = shown
end

local function setIcon(id, color)
	iconHolder:ClearAllChildren()
	if id then
		StatusIcons.Create(iconHolder, "Logo" .. id, UDim2.fromScale(1, 1), UDim2.new(), color)
	end
end

-- skills: the performer uses them, you watch ----------------------------------------------------------------------------
local skillButtons = {}
local function clearSkills()
	for _, child in skillGrid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	skillButtons = {}
	skillName.Text, skillBody.Text = "", ""
end

local function chooseMove(move, perform)
	skillName.Text = (move.Hidden and "\u{2605} " or "") .. move.Name
	skillName.TextColor3 = move.Hidden and HIDDEN or GOLD
	skillBody.Text = move.Text
	for id, b in skillButtons do
		local stroke = b:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = id == move.Id and 2.5 or 1.2
		end
	end
	if perform then
		tryRemote:FireServer("Perform", move.Id)
	end
end

local function showClass(id)
	selected = id
	status.Text = ""
	local def = ClassConfig.Classes[id]
	nameLabel.Text = def.Name
	nameLabel.TextColor3 = def.Color or GOLD
	setIcon(id, def.Color)
	tagLabel.Text = def.Tagline or ""
	statFrame.Visible = true
	local color = def.Color or GOLD
	setStat("HP", def.HP or 0, tostring(def.HP or 0), color)
	setStat("Stamina", def.Stamina or 0, tostring(def.Stamina or 0), color)
	setStat("Dash", def.DashCost or 0, (def.DashCost or 0) .. " stam", color)
	setStat("Speed", def.Speed or 0, tostring(def.Speed or 0), color)
	local defense = def.BaseDefense or 0
	setStat("Base Defense", defense, defense > 0 and string.format("%d%%", defense * 100) or "none", color)
	passiveTitle.Text = def.Passive and ("Passive: " .. def.Passive.Name) or "Passive"
	passiveLabel.Text = def.Passive and def.Passive.Text or ""
	skillsTitle.Text = "Skills: pick one to watch it"
	skillsTitle.Visible, skillGrid.Visible = true, true
	clearSkills()
	if player:GetAttribute("TryoutClass") ~= id then
		tryRemote:FireServer("Class", id)
	end
	local moves = ShowcaseMoves.For(id)
	for order, move in moves do
		local b = button(skillGrid, { Name = "Skill" .. move.Id, LayoutOrder = order, Text = (move.Hidden and "\u{2605} " or "") .. move.Label, TextSize = 17, Font = Enum.Font.GothamBold, TextColor3 = move.Hidden and HIDDEN or TEXT })
		local stroke = b:FindFirstChildOfClass("UIStroke")
		if stroke and move.Hidden then
			stroke.Color = HIDDEN
		end
		skillButtons[move.Id] = b
		b.Activated:Connect(function()
			chooseMove(move, true)
		end)
	end
	if moves[1] then
		chooseMove(moves[1], false)
	end
	refreshAction()
end

local orbVisual
local function showOrb(id)
	selected = id
	status.Text = ""
	local orb = OrbConfig.Items[id]
	nameLabel.Text = orb.Name
	nameLabel.TextColor3 = orb.Color
	setIcon(nil)
	tagLabel.Text = orb.Flavor
	statFrame.Visible = false
	passiveTitle.Text = "Passive"
	passiveLabel.Text = orb.Passive .. "\n\nOne orb can be equipped at a time. It works in every fight."
	skillsTitle.Visible, skillGrid.Visible = false, false
	clearSkills()
	if orbVisual then
		orbVisual:Destroy()
	end
	orbVisual = Instance.new("Part")
	orbVisual.Shape = Enum.PartType.Ball
	orbVisual.Size = Vector3.new(1.7, 1.7, 1.7)
	orbVisual.Anchored, orbVisual.CanCollide, orbVisual.CanQuery, orbVisual.CanTouch = true, false, false, false
	orbVisual.Material = Enum.Material.Neon
	orbVisual.Color = orb.Color
	orbVisual.CFrame = rig.root.CFrame * CFrame.new(1.5, 1.5, -2.6)
	orbVisual.Parent = stageFolder
	make("PointLight", { Color = orb.Color, Range = 18, Brightness = 2.5 }, orbVisual)
	make("ParticleEmitter", { Color = ColorSequence.new(orb.Color), Rate = 22, Speed = NumberRange.new(1.5), Lifetime = NumberRange.new(1.2), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }), LightEmission = 0.8 }, orbVisual)
	rig:pose({ RA = 1.45, RAo = -0.1, LA = 0.1 }, 0.2)
	SkillDemos.PlayOrb(rig, orb)
	refreshAction()
end

local function buildList()
	for _, child in listPanel:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	rows = {}
	local ids = mode == "Classes" and ClassConfig.Order or OrbConfig.Order
	for order, id in ids do
		local name, color
		if mode == "Classes" then
			local def = ClassConfig.Classes[id]
			name, color = def.Name, def.Color
		else
			local orb = OrbConfig.Items[id]
			name, color = orb.Name, orb.Color
		end
		local row = make("TextButton", { Name = id, Size = UDim2.new(1, 0, 0, 58), LayoutOrder = order, BackgroundColor3 = CARD, Text = "", AutoButtonColor = true }, listPanel)
		round(row, 8)
		make("Frame", { Size = UDim2.new(0, 4, 1, -14), Position = UDim2.fromOffset(5, 7), BackgroundColor3 = color, BorderSizePixel = 0 }, row)
		local x = 16
		if mode == "Classes" then
			StatusIcons.Create(row, "Logo" .. id, UDim2.fromOffset(36, 36), UDim2.fromOffset(14, 11), color)
			x = 58
		else
			local dot = make("Frame", { Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(18, 18), BackgroundColor3 = color, BorderSizePixel = 0 }, row)
			round(dot, 11)
			x = 50
		end
		text(row, { Position = UDim2.fromOffset(x, 7), Size = UDim2.new(1, -x - 6, 0, 24), Font = TITLE_FONT, TextSize = 22, TextColor3 = TEXT, Text = name, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
		local statusText = text(row, { Position = UDim2.fromOffset(x, 33), Size = UDim2.new(1, -x - 6, 0, 18), TextSize = 13, Font = Enum.Font.GothamMedium })
		rows[id] = { frame = row, status = statusText }
		row.Activated:Connect(function()
			if mode == "Classes" then
				showClass(id)
			else
				showOrb(id)
			end
		end)
	end
end

-- Going in and out -------------------------------------------------------------------------------------------------------
local camera = workspace.CurrentCamera
local previousCamera
local prompt
local mood
local transit = false

local function sink()
	return Enum.ContextActionResult.Sink
end

-- Classes: a fixed side view of your performer and the target dummy. The camera is yours alone: nothing the performer does moves it.
local function frameStage()
	local target = workspace:FindFirstChild("ClassTrainingDummy")
	if not markAt or not target then
		return
	end
	local from = markAt
	local to = target:GetPivot().Position
	local mid = (from + to) / 2
	local along = (to - from) * Vector3.new(1, 0, 1)
	along = along.Magnitude > 0.1 and along.Unit or Vector3.xAxis
	local side = along:Cross(Vector3.yAxis)
	-- look from the side the watcher stands on, so your own body is behind the camera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and (root.Position - mid):Dot(side) < 0 then
		side = -side
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 70
	camera.CFrame = CFrame.lookAt(mid + side * 19 + Vector3.new(0, 5.5, 0), mid + Vector3.new(0, 2.5, 0))
end

local function setupClassStage()
	ContextActionService:BindActionAtPriority("ShowroomStill", sink, false, 3000, table.unpack(Enum.PlayerActions:GetEnumItems()))
	Freeze.On()
	-- re-assert the framing every frame: a skill's camera effect can never take the view away
	pcall(RunService.UnbindFromRenderStep, RunService, "ShowroomCamera")
	RunService:BindToRenderStep("ShowroomCamera", Enum.RenderPriority.Last.Value + 10, function()
		if view.Visible and mode == "Classes" then
			frameStage()
		end
	end)
end

local function stopClassCamera()
	pcall(RunService.UnbindFromRenderStep, RunService, "ShowroomCamera")
end

tryRemote.OnClientEvent:Connect(function(action, data)
	if action == "Result" and type(data) == "table" and data.Message then
		status.Text = data.Message
	elseif action == "Performer" and typeof(data) == "Instance" and data:IsA("Model") then
		performer = data
		markAt = data:GetPivot().Position -- each fresh body is put on its mark before it is announced
	end
end)

local function stage()
	local world = workspace:WaitForChild("World")
	return world:WaitForChild("Stage"):WaitForChild("OrbSpot")
end

local function setupStage()
	local spot = stage()
	stageFolder = Instance.new("Folder")
	stageFolder.Name = "LocalShowroom"
	stageFolder.Parent = workspace
	local position = spot.Position + Vector3.new(-2.5, 3, 0)
	local targetAt = spot.Position + Vector3.new(4.5, 3, 0)
	rig = Rig.new(stageFolder, position, Vector3.new(0.9, 0, 1), targetAt)
	SkillDemos.Setup(stageFolder)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(spot.Position + Vector3.new(0.9, 4.2, 11.5), spot.Position + Vector3.new(0.9, 3.2, 0))
end

local function teardownStage()
	SkillDemos.Stop()
	if rig then
		rig:destroy()
		rig = nil
	end
	if stageFolder then
		stageFolder:Destroy()
		stageFolder = nil
	end
	orbVisual = nil
end

local function moodEvent(name)
	mood = mood or player.PlayerScripts:FindFirstChild("UnfairMood")
	if mood then
		mood:Fire(name)
	end
end

local talk -- the Keeper's conversation, defined below

local function openClasses()
	mode = "Classes"
	transit = true
	performer = nil
	gui.Enabled = true
	local first = player:GetAttribute("PlayerClass") or ClassConfig.Default
	tryRemote:FireServer("Enter", first)
	-- the server fades the screen, moves you to the stage and sets TryoutClass when the performer is on its mark
	local waited = 0
	while (not player:GetAttribute("TryoutClass") or not performer) and waited < 8 do
		waited += task.wait(0.05)
	end
	transit = false
	if not player:GetAttribute("TryoutClass") then
		gui.Enabled = false
		return
	end
	heading.Text = "Classes"
	view.Visible = true
	setupClassStage()
	buildList()
	showClass(player:GetAttribute("TryoutClass"))
end

local function closeClasses()
	view.Visible = false
	stopClassCamera()
	transit = true
	ContextActionService:UnbindAction("ShowroomStill")
	tryRemote:FireServer("Leave")
	local waited = 0
	while player:GetAttribute("TryoutClass") and waited < 8 do
		waited += task.wait(0.05)
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	transit = false
	Freeze.Off()
	gui.Enabled = false
	performer = nil
end

local function openShowcase(kind)
	if kind == "Classes" then
		openClasses()
		return
	end
	mode = kind
	gui.Enabled = true
	Freeze.On()
	Fade.Out(0.3, "The Reliquary", "Shop")
	previousCamera = { camera.CameraType, camera.CameraSubject }
	setupStage()
	moodEvent("Stage")
	heading.Text = "Orbs"
	view.Visible = true
	buildList()
	showOrb(player:GetAttribute("PlayerOrb") or OrbConfig.Order[1])
	Fade.In(0.5)
end

local function closeShowcase()
	if mode == "Classes" then
		closeClasses()
	else
		Fade.Out(0.3)
		view.Visible = false
		teardownStage()
		if previousCamera then
			camera.CameraType, camera.CameraSubject = previousCamera[1], previousCamera[2]
		end
		moodEvent("Area")
		gui.Enabled = false
		Freeze.Off()
		Fade.In(0.5)
	end
	-- back at the Keeper: he picks the conversation up again
	task.defer(function()
		if talk then
			talk(true)
		end
	end)
end
backButton.Activated:Connect(closeShowcase)

-- The Keeper's conversation ------------------------------------------------------------------------------------------------
local keeper
local GREETINGS = {
	"Everything here belonged to someone braver than you. Fair prices. No refunds.",
	"Back again? Good. The dead don't haggle.",
	"Look around. Touch nothing you can't afford.",
}
local AGAIN = { "Anything else?", "What else can I do for you?", "Still here? Then pick." }

local function paragraphs(body)
	local out = {}
	for chunk in (body .. "\n\n"):gmatch("(.-)\n\n") do
		if chunk:match("%S") then
			table.insert(out, chunk)
		end
	end
	return out
end

local function tellLore(d)
	if not d:Say("Which story do you want?") then
		return false
	end
	local pick = d:Choose({ "This place", "alterGolden", "The island and the forest" })
	if not pick then
		return false
	end
	local entries = pick == 1 and { Lore[1] } or pick == 2 and { Lore[2] } or { Lore[3], Lore[4] }
	for _, entry in entries do
		for _, line in paragraphs(entry.Text) do
			if not d:Say(line) then
				return false
			end
		end
	end
	return true
end

talk = function(again)
	if not keeper or gui.Enabled then
		return
	end
	local d = NpcDialog.Open(keeper, { Name = "The Keeper", Color = GOLD })
	if prompt then
		prompt.Enabled = false
	end
	local line = again and AGAIN[math.random(#AGAIN)] or GREETINGS[math.random(#GREETINGS)]
	while d:IsOpen() do
		if not d:Say(line, 0.6) then
			break
		end
		local pick = d:Choose({ "Show me the classes", "Show me the orbs", "Tell me a story" })
		if pick == 1 or pick == 2 then
			d:Close()
			openShowcase(pick == 1 and "Classes" or "Orbs")
			break
		elseif pick == 3 then
			if not tellLore(d) then
				break
			end
			line = AGAIN[math.random(#AGAIN)]
		else
			break
		end
	end
	d:Close()
	if prompt then
		prompt.Enabled = true
	end
end

task.spawn(function()
	local world = workspace:WaitForChild("World", 30)
	local shop = world and world:WaitForChild("Shop", 30)
	keeper = shop and shop:WaitForChild("Shopkeeper", 30)
	local torso = keeper and keeper:WaitForChild("Torso", 30)
	prompt = torso and torso:WaitForChild("ShopPrompt", 30)
	if prompt then
		prompt.ActionText = "Talk"
		prompt.ObjectText = "The Keeper"
		prompt.Triggered:Connect(function(who)
			if who == player then
				task.spawn(talk, false)
			end
		end)
	end
end)

player.CharacterRemoving:Connect(function()
	if transit then
		return
	end
	ContextActionService:UnbindAction("ShowroomStill")
	stopClassCamera()
	if gui.Enabled then
		if view.Visible and mode ~= "Classes" then
			teardownStage()
			moodEvent("Area")
		end
		view.Visible = false
		camera.CameraType = Enum.CameraType.Custom
		gui.Enabled = false
		Freeze.Off()
	end
end)

--!nonstrict
--[[
 The shop (docs/spec/lobby-redesign.md). Press E at the Keeper for three choices: Classes, Orbs, Lore.
 Classes and Orbs fade to the showroom: a dummy on a stage wearing what you are looking at. Click a skill and the dummy uses it on a
 second dummy. For classes that is the fight's real skill: the performer is your own character in a dummy's body, running the boss
 place's class kits (TryoutService). Orbs are shown by a dummy that only exists on your client.
 Every button only asks the server; prices and ownership are decided there (ShopService, ClassPickService).
]]
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassConfig = require(ReplicatedStorage.BossShared.Classes.ClassConfig)
local ClassUnlocks = require(ReplicatedStorage.BossShared.Classes.ClassUnlocks)
local OrbConfig = require(ReplicatedStorage.UnfairShared.OrbConfig)
local Fade = require(ReplicatedStorage.Lobby.Fade)
local Freeze = require(ReplicatedStorage.Lobby.Freeze)
local Lore = require(ReplicatedStorage.Lobby.Lore)
local LobbyRemotes = require(ReplicatedStorage.Lobby.LobbyRemotes)
local Rig = require(ReplicatedStorage.Lobby.Rig)
local SkillDemos = require(ReplicatedStorage.Lobby.SkillDemos)

local player = Players.LocalPlayer
local shopRemote = LobbyRemotes.get("Shop")
local classRemote = LobbyRemotes.get("ClassPick")
local tryRemote = LobbyRemotes.get("Tryout")

local GOLD = Color3.fromRGB(246, 211, 117)
local INK = Color3.fromRGB(18, 15, 14)
local CARD = Color3.fromRGB(38, 32, 28)
local TEXT = Color3.fromRGB(226, 220, 208)
local DIM = Color3.fromRGB(160, 152, 140)
local TITLE_FONT = Enum.Font.Garamond
local BODY_FONT = Enum.Font.Gotham
local SKILL_KEYS = { "M1", "F", "C", "V", "R" }
local KEY_LABEL = { M1 = "Click", F = "F", C = "C", V = "V", R = "R" }
-- skills the fight makes you hold: how long the performer holds them (Mage's C is a tap or a hold; the tap is the one shown)
local HOLD = { Tank = { F = 1.6 }, Mage = { C = 0.1 }, Duelist = { C = 1.2 }, Disorderer = { M1 = 1.2, C = 1.2, V = 1.2 } }

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

-- The Keeper's dialogue ---------------------------------------------------------------------------------------------
local menu = make("Frame", { Name = "Menu", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -28), Size = UDim2.new(0.92, 0, 0, 210), BackgroundColor3 = INK, BackgroundTransparency = 0.04, Visible = false }, gui)
make("UISizeConstraint", { MaxSize = Vector2.new(720, 210) }, menu)
round(menu, 12, GOLD, 2)
text(menu, { Size = UDim2.new(1, -40, 0, 34), Position = UDim2.fromOffset(20, 12), Font = TITLE_FONT, TextSize = 28, TextColor3 = GOLD, Text = "The Keeper" })
text(menu, { Size = UDim2.new(1, -40, 0, 44), Position = UDim2.fromOffset(20, 48), TextSize = 16, Text = "Everything here belonged to someone braver than you. Fair prices. No refunds." })

local openShowcase, openLore, closeAll

local menuRow = make("Frame", { Name = "Row", Size = UDim2.new(1, -40, 0, 64), Position = UDim2.fromOffset(20, 124), BackgroundTransparency = 1 }, menu)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, menuRow)
for order, item in { { "Buy Classes", "Classes" }, { "Buy Orbs", "Orbs" }, { "Lore", "Lore" }, { "Leave", "Leave" } } do
	button(menuRow, { Name = item[2], Size = UDim2.new(0.25, -9, 1, 0), LayoutOrder = order, Text = item[1], TextSize = 24 }, function()
		if item[2] == "Lore" then
			openLore()
		elseif item[2] == "Leave" then
			closeAll()
		else
			openShowcase(item[2])
		end
	end)
end

-- Lore ---------------------------------------------------------------------------------------------------------------
local lore = make("Frame", { Name = "Lore", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.9, 0, 0.74, 0), BackgroundColor3 = INK, BackgroundTransparency = 0.03, Visible = false }, gui)
make("UISizeConstraint", { MaxSize = Vector2.new(720, 520) }, lore)
round(lore, 12, GOLD, 2)
local loreTitle = text(lore, { Size = UDim2.new(1, -48, 0, 46), Position = UDim2.fromOffset(24, 18), Font = TITLE_FONT, TextSize = 38, TextColor3 = GOLD })
local loreBody = text(lore, { Size = UDim2.new(1, -48, 1, -140), Position = UDim2.fromOffset(24, 76), TextSize = 18, Font = Enum.Font.Merriweather })
local lorePage = 1
local function showLore()
	loreTitle.Text, loreBody.Text = Lore[lorePage].Title, Lore[lorePage].Text
end
button(lore, { Size = UDim2.fromOffset(120, 42), Position = UDim2.new(0, 24, 1, -60), Text = "Previous" }, function()
	lorePage = (lorePage - 2) % #Lore + 1
	showLore()
end)
button(lore, { Size = UDim2.fromOffset(120, 42), Position = UDim2.new(0, 156, 1, -60), Text = "Next" }, function()
	lorePage = lorePage % #Lore + 1
	showLore()
end)
button(lore, { AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(120, 42), Position = UDim2.new(1, -24, 1, -60), Text = "Back" }, function()
	lore.Visible = false
	menu.Visible = true
end)

-- The showroom UI: list on the left, the dummy in the middle, details on the right ---------------------------------------
local view = make("Frame", { Name = "Showroom", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, gui)

local topBar = make("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = INK, BackgroundTransparency = 0.25, BorderSizePixel = 0 }, view)
local heading = text(topBar, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.5, 0, 1, 0), Font = TITLE_FONT, TextSize = 36, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center })
local cashLabel = text(topBar, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(220, 30), TextSize = 22, Font = TITLE_FONT, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center })
local backButton = button(topBar, { Name = "Back", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(96, 38), Text = "Back" })

local listPanel = make("ScrollingFrame", { Name = "List", Position = UDim2.new(0, 14, 0, 72), Size = UDim2.new(0.22, 0, 1, -88), BackgroundColor3 = INK, BackgroundTransparency = 0.12, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, view)
round(listPanel, 10)
make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, listPanel)
make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, listPanel)

local info = make("Frame", { Name = "Info", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 72), Size = UDim2.new(0.33, 0, 1, -88), BackgroundColor3 = INK, BackgroundTransparency = 0.12 }, view)
round(info, 10)
local nameLabel = text(info, { Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -36, 0, 40), Font = TITLE_FONT, TextSize = 36, TextColor3 = GOLD })
local tagLabel = text(info, { Position = UDim2.fromOffset(18, 54), Size = UDim2.new(1, -36, 0, 40), TextSize = 14, TextColor3 = TEXT })
local statLabel = text(info, { Position = UDim2.fromOffset(18, 98), Size = UDim2.new(1, -36, 0, 18), TextSize = 13, TextColor3 = GOLD, Font = Enum.Font.GothamMedium })
text(info, { Position = UDim2.fromOffset(18, 122), Size = UDim2.new(1, -36, 0, 22), Font = TITLE_FONT, TextSize = 22, TextColor3 = GOLD, Text = "Passive" })
local passiveLabel = text(info, { Position = UDim2.fromOffset(18, 146), Size = UDim2.new(1, -36, 0, 74), TextSize = 13 })
local skillsTitle = text(info, { Position = UDim2.fromOffset(18, 224), Size = UDim2.new(1, -36, 0, 22), Font = TITLE_FONT, TextSize = 22, TextColor3 = GOLD, Text = "Skills: click one to see it" })
local skillRow = make("Frame", { Name = "Skills", Position = UDim2.fromOffset(18, 250), Size = UDim2.new(1, -36, 0, 40), BackgroundTransparency = 1 }, info)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, skillRow)
local skillName = text(info, { Position = UDim2.fromOffset(18, 296), Size = UDim2.new(1, -36, 0, 22), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = GOLD })
local skillBody = text(info, { Position = UDim2.fromOffset(18, 318), Size = UDim2.new(1, -36, 1, -402), TextSize = 13 })
local status = text(info, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -64), Size = UDim2.new(1, -36, 0, 18), TextSize = 13, TextColor3 = Color3.fromRGB(255, 170, 150), TextXAlignment = Enum.TextXAlignment.Center })
local actionButton = button(info, { Name = "Action", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -36, 0, 46), TextSize = 26, TextColor3 = INK, BackgroundColor3 = GOLD })

-- State ----------------------------------------------------------------------------------------------------------------
local mode = nil -- "Classes" | "Orbs"
local selected = nil
local rig, stageFolder, targetPart
local rows = {}

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
		return (entry.Price or "?") .. " Robux", Color3.fromRGB(150, 220, 160)
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
tryRemote.OnClientEvent:Connect(function(action, data)
	if action == "Result" and type(data) == "table" and data.Message then
		print("[Shop] " .. data.Message)
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

-- Has the performer use a skill for real: back to its mark with cooldowns cleared, then the same message the fight's input sends.
local performToken = 0
local function perform(classId, key)
	local control = ReplicatedStorage:FindFirstChild("ClassControl")
	local target = workspace:FindFirstChild("ClassTrainingDummy")
	if not control or not target or player:GetAttribute("TryoutClass") ~= classId then
		return
	end
	performToken += 1
	local mine = performToken
	tryRemote:FireServer("Ready")
	task.delay(0.25, function()
		if mine ~= performToken or player:GetAttribute("TryoutClass") ~= classId then
			return
		end
		local aim = target:GetPivot().Position
		control:FireServer("Action", key, "Begin", aim)
		local hold = HOLD[classId] and HOLD[classId][key]
		if hold then
			task.wait(hold)
			if mine == performToken then
				control:FireServer("Action", key, "End", aim)
			end
		end
	end)
end

local function clearSkills()
	for _, child in skillRow:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	skillName.Text, skillBody.Text = "", ""
end

local function showClass(id)
	selected = id
	status.Text = ""
	local def = ClassConfig.Classes[id]
	nameLabel.Text = def.Name
	tagLabel.Text = def.Tagline or ""
	statLabel.Text = string.format("HP %d   Stamina %d   Speed %d", def.HP or 0, def.Stamina or 0, def.Speed or 0)
	passiveLabel.Text = def.Passive and (def.Passive.Name .. ": " .. def.Passive.Text) or ""
	skillsTitle.Text = "Skills: click one to see it"
	clearSkills()
	performToken += 1
	if player:GetAttribute("TryoutClass") ~= id then
		tryRemote:FireServer("Class", id)
	end
	local order = 0
	for _, key in SKILL_KEYS do
		local skill = def[key]
		if type(skill) == "table" and skill.Name then
			order += 1
			local b = button(skillRow, { Name = "Skill" .. key, Size = UDim2.new(0, 56, 1, 0), LayoutOrder = order, Text = KEY_LABEL[key], TextSize = 18 })
			local function choose()
				skillName.Text, skillBody.Text = skill.Name, skill.Text or ""
				perform(id, key)
			end
			b.Activated:Connect(choose)
			if order == 1 then
				skillName.Text, skillBody.Text = skill.Name, skill.Text or ""
			end
		end
	end
	refreshAction()
end

local orbVisual
local function showOrb(id)
	selected = id
	status.Text = ""
	local orb = OrbConfig.Items[id]
	nameLabel.Text = orb.Name
	tagLabel.Text = orb.Flavor
	statLabel.Text = ""
	passiveLabel.Text = orb.Passive .. "\n\nOne orb can be equipped at a time. It works in every fight."
	skillsTitle.Text = ""
	clearSkills()
	skillName.Text, skillBody.Text = "", ""
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
		make("Frame", { Size = UDim2.new(0, 5, 1, -14), Position = UDim2.fromOffset(6, 7), BackgroundColor3 = color, BorderSizePixel = 0 }, row)
		text(row, { Position = UDim2.fromOffset(18, 7), Size = UDim2.new(1, -24, 0, 24), Font = TITLE_FONT, TextSize = 22, TextColor3 = TEXT, Text = name, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
		local statusText = text(row, { Position = UDim2.fromOffset(18, 33), Size = UDim2.new(1, -24, 0, 18), TextSize = 13, Font = Enum.Font.GothamMedium })
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

local function setControls(enabled)
	if enabled then
		Freeze.Off()
	else
		Freeze.On()
	end
end

local function stage()
	local world = workspace:WaitForChild("World")
	return world:WaitForChild("Stage"):WaitForChild("OrbSpot")
end

-- Classes: the performer and its target are real and already on the stage; this side only points the camera at them from the side
-- and stops the movement keys (the skill keys still work, so pressing F does what clicking F does).
local transit = false
local function sink()
	return Enum.ContextActionResult.Sink
end
local function setupClassStage()
	local character = player.Character
	local root = character and character:WaitForChild("HumanoidRootPart", 5)
	local target = workspace:WaitForChild("ClassTrainingDummy", 5)
	if not root or not target then
		return
	end
	local from, to = root.Position, target:GetPivot().Position
	local mid = (from + to) / 2
	local along = ((to - from) * Vector3.new(1, 0, 1)).Unit
	local side = along:Cross(Vector3.yAxis)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(mid + side * 13 + Vector3.new(0, 1.4, 0), mid + Vector3.new(0, 0.2, 0))
	ContextActionService:BindActionAtPriority("ShowroomStill", sink, false, 3000, table.unpack(Enum.PlayerActions:GetEnumItems()))
end

local function setupStage()
	local spot = stage()
	stageFolder = Instance.new("Folder")
	stageFolder.Name = "LocalShowroom"
	stageFolder.Parent = workspace
	local position = spot.Position + Vector3.new(-2.5, 3, 0)
	local targetAt = spot.Position + Vector3.new(4.5, 3, 0)
	rig = Rig.new(stageFolder, position, Vector3.new(0.9, 0, 1), targetAt)
	targetPart = make("Part", { Name = "Target", Size = Vector3.new(2.4, 5.4, 1.6), CFrame = CFrame.new(targetAt), Anchored = true, CanCollide = false, Color = Color3.fromRGB(120, 86, 56), Material = Enum.Material.Wood }, stageFolder)
	make("Part", { Name = "TargetFoot", Size = Vector3.new(4, 0.5, 4), CFrame = CFrame.new(targetAt - Vector3.new(0, 2.9, 0)), Anchored = true, CanCollide = false, Color = Color3.fromRGB(70, 50, 34), Material = Enum.Material.Wood }, stageFolder)
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

local function openClasses()
	mode = "Classes"
	menu.Visible = false
	transit = true
	local first = player:GetAttribute("PlayerClass") or ClassConfig.Default
	tryRemote:FireServer("Enter", first)
	-- the server fades the screen, swaps the body and sets TryoutClass when the performer is on its mark
	local waited = 0
	while not player:GetAttribute("TryoutClass") and waited < 6 do
		waited += task.wait(0.05)
	end
	transit = false
	if not player:GetAttribute("TryoutClass") then
		menu.Visible = true
		return
	end
	setupClassStage()
	heading.Text = "Classes"
	view.Visible = true
	buildList()
	showClass(player:GetAttribute("TryoutClass"))
end

local function closeClasses()
	view.Visible = false
	performToken += 1
	transit = true
	ContextActionService:UnbindAction("ShowroomStill")
	local performer = player.Character
	tryRemote:FireServer("Leave")
	-- done when the server has cleared TryoutClass AND handed back your own body (it does those in that order)
	local waited = 0
	while (player:GetAttribute("TryoutClass") or player.Character == performer) and waited < 8 do
		waited += task.wait(0.05)
	end
	local own = player.Character
	if own then
		own:WaitForChild("Humanoid", 5)
	end
	camera.CameraType = Enum.CameraType.Custom
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	transit = false
	-- back at the Keeper, in your own body
	Freeze.Off()
	Freeze.On()
	menu.Visible = true
end

openShowcase = function(kind)
	if kind == "Classes" then
		openClasses()
		return
	end
	mode = kind
	menu.Visible = false
	Fade.Out(0.3, kind == "Classes" and "The Armoury" or "The Reliquary")
	previousCamera = { camera.CameraType, camera.CameraSubject }
	setupStage()
	moodEvent("Stage")
	heading.Text = kind == "Classes" and "Classes" or "Orbs"
	view.Visible = true
	buildList()
	if kind == "Classes" then
		showClass(player:GetAttribute("PlayerClass") or ClassConfig.Default)
	else
		showOrb(player:GetAttribute("PlayerOrb") or OrbConfig.Order[1])
	end
	Fade.In(0.5)
end

local function closeShowcase()
	if mode == "Classes" then
		closeClasses()
		return
	end
	Fade.Out(0.3)
	view.Visible = false
	teardownStage()
	if previousCamera then
		camera.CameraType, camera.CameraSubject = previousCamera[1], previousCamera[2]
	end
	moodEvent("Area")
	menu.Visible = true
	Fade.In(0.5)
end
backButton.Activated:Connect(closeShowcase)

openLore = function()
	menu.Visible = false
	lore.Visible = true
	lorePage = 1
	showLore()
end

local function open()
	gui.Enabled = true
	menu.Visible = true
	lore.Visible = false
	view.Visible = false
	if prompt then
		prompt.Enabled = false
	end
	setControls(false)
end

closeAll = function()
	gui.Enabled = false
	menu.Visible = false
	if prompt then
		prompt.Enabled = true
	end
	setControls(true)
end

task.spawn(function()
	local world = workspace:WaitForChild("World", 30)
	local shop = world and world:WaitForChild("Shop", 30)
	local keeper = shop and shop:WaitForChild("Shopkeeper", 30)
	local torso = keeper and keeper:WaitForChild("Torso", 30)
	prompt = torso and torso:WaitForChild("ShopPrompt", 30)
	if prompt then
		prompt.Triggered:Connect(function(who)
			if who == player then
				open()
			end
		end)
	end
end)

player.CharacterRemoving:Connect(function()
	if transit then
		return -- the showroom swapping the body in or out
	end
	ContextActionService:UnbindAction("ShowroomStill")
	if gui.Enabled then
		if view.Visible then
			view.Visible = false
			teardownStage()
			moodEvent("Area")
			camera.CameraType = Enum.CameraType.Custom
		end
		closeAll()
	end
end)

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local gui = script.Parent
local p = gui:FindFirstChild("BossPanel") or gui:WaitForChild("Container"):WaitForChild("BossPanel")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Descriptions = require(Shared:WaitForChild("Presentation"):WaitForChild("EffectDescriptions"))
local Tween = game:GetService("TweenService")
local Run = game:GetService("RunService")
local Quality=require(Shared.Presentation.VisualQuality)
local TouchLayout=require(Shared.Presentation.TouchControlLayout)
local UIS=game:GetService("UserInputService")
local BOSS_NAME = "alterGolden, the Nothing"
 
 
local SoundService = game:GetService("SoundService")
local player = game:GetService("Players").LocalPlayer
local isOwner = game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
local viewAsServerRemote = game:GetService("ReplicatedStorage"):WaitForChild("ViewAsServerToggle")
local classControl = game.ReplicatedStorage:WaitForChild("ClassControl")
if SoundService:GetAttribute("BossMusicMuted") == nil then
	SoundService:SetAttribute("BossMusicMuted", false)
end
local settingsGui = Instance.new("ScreenGui")
settingsGui.Name = "BossSettingsHUD"
settingsGui.ResetOnSpawn = false
settingsGui.IgnoreGuiInset = false
settingsGui.DisplayOrder = math.max(100, gui.DisplayOrder + 1)
settingsGui.Parent = player:WaitForChild("PlayerGui")
local function settingsButton(name, parent, size, position, title)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(19, 17, 12)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Garamond
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(255, 228, 136)
	button.Text = title
	button.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(139, 115, 54)
	stroke.Transparency = 0.25
	stroke.Parent = button
	return button
end
local settings =
	settingsButton("SettingsButton", settingsGui, UDim2.fromOffset(106, 38), UDim2.new(1, -20, 1, -20), "Settings")
settings.AnchorPoint = Vector2.one
local settingsPanel = Instance.new("ScrollingFrame")
settingsPanel.ScrollBarThickness=6
settingsPanel.ScrollingDirection=Enum.ScrollingDirection.Y
settingsPanel.Name = "SettingsPanel"
settingsPanel.AnchorPoint = Vector2.one
settingsPanel.Position = UDim2.new(1, -20, 1, -68)
settingsPanel.Size = UDim2.fromOffset(240, 124)
settingsPanel.BackgroundColor3 = Color3.fromRGB(12, 11, 9)
settingsPanel.BackgroundTransparency = 0.08
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.Parent = settingsGui
local settingsStroke = Instance.new("UIStroke")
settingsStroke.Color = Color3.fromRGB(139, 115, 54)
settingsStroke.Parent = settingsPanel
local settingsTitle = Instance.new("TextLabel")
settingsTitle.Name = "Title"
settingsTitle.Size = UDim2.new(1, -64, 0, 30)
settingsTitle.Position = UDim2.fromOffset(16, 10)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Font = Enum.Font.Garamond
settingsTitle.TextSize = 23
settingsTitle.TextColor3 = Color3.fromRGB(255, 228, 136)
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.Text = "Settings"
settingsTitle.Parent = settingsPanel
local closeSettings =
	settingsButton("CloseButton", settingsPanel, UDim2.fromOffset(28, 28), UDim2.new(1, -40, 0, 12), "×")
closeSettings.Parent=settingsGui
closeSettings.Visible=false
closeSettings.ZIndex=10
closeSettings.Size=UDim2.fromOffset(42,42)
local musicToggle =
	settingsButton("MusicMuteButton", settingsPanel, UDim2.new(1, -32, 0, 42), UDim2.fromOffset(16, 58), "")
local autoAimToggle=settingsButton("AutoAimButton",settingsPanel,UDim2.new(1,-32,0,42),UDim2.fromOffset(16,104),"")
local effectsToggle=settingsButton("EffectsQualityButton",settingsPanel,UDim2.new(1,-32,0,42),UDim2.fromOffset(16,150),"")
local cutsceneToggle=settingsButton("SkillCutsceneButton",settingsPanel,UDim2.new(1,-32,0,42),UDim2.fromOffset(16,196),"")
local function effectsChanged()
 effectsToggle.Text="Effects: "..Quality.Mode().." ("..Quality.Get().Name..")"
end
local function classSettingsChanged()
 autoAimToggle.Text=player:GetAttribute("ClassAutoAim")~=false and "Auto aim: On" or "Auto aim: Off"
 cutsceneToggle.Text=player:GetAttribute("DisableSkillCutscenes")==true and "Skill cutscenes: Off" or "Skill cutscenes: On"
end
local viewAsServerToggle
if isOwner then
	viewAsServerToggle =
		settingsButton("ViewAsServerButton", settingsPanel, UDim2.new(1, -32, 0, 42), UDim2.fromOffset(16, 242), "")
end
local viewAsServerChanged
local function preferenceChanged()
	viewAsServerChanged()
 classSettingsChanged()
 effectsChanged()
	local muted = SoundService:GetAttribute("BossMusicMuted") == true
	musicToggle.Text = muted and "Music: Muted" or "Music: On"
	musicToggle.TextColor3 = muted and Color3.fromRGB(189, 180, 158) or Color3.fromRGB(255, 228, 136)
end
function viewAsServerChanged()
	if not viewAsServerToggle then
		return
	end
	local active = player:GetAttribute("ViewAsServer") == true
	viewAsServerToggle.Text = active and "View as Server: On" or "View as Server: Off"
	viewAsServerToggle.TextColor3 = active and Color3.fromRGB(189, 180, 158) or Color3.fromRGB(255, 228, 136)
end
local function activateSetting(action)
	if action == "TogglePanel" then
		settingsPanel.Visible = not settingsPanel.Visible
	elseif action == "Close" then
		settingsPanel.Visible = false
	elseif action == "ToggleMusic" then
		SoundService:SetAttribute("BossMusicMuted", SoundService:GetAttribute("BossMusicMuted") ~= true)
	elseif action=="ToggleAutoAim" then
  classControl:FireServer("Setting","ClassAutoAim",player:GetAttribute("ClassAutoAim")==false)
 elseif action=="ToggleCutscenes" then
   classControl:FireServer("Setting","DisableSkillCutscenes",player:GetAttribute("DisableSkillCutscenes")~=true)
  elseif action=="ToggleEffects" then
   Quality.Cycle()
  elseif action == "ToggleViewAsServer" then
		if viewAsServerRemote then
			viewAsServerRemote:FireServer()
		end
	end
 closeSettings.Visible=settingsPanel.Visible
	return SoundService:GetAttribute("BossMusicMuted") == true
end
local settingsConnections = {
	settings.Activated:Connect(function()
		activateSetting("TogglePanel")
	end),
	closeSettings.Activated:Connect(function()
		activateSetting("Close")
	end),
	musicToggle.Activated:Connect(function()
		activateSetting("ToggleMusic")
	end),
	autoAimToggle.Activated:Connect(function() activateSetting("ToggleAutoAim") end),
	cutsceneToggle.Activated:Connect(function() activateSetting("ToggleCutscenes") end),
	player:GetAttributeChangedSignal("DisableSkillCutscenes"):Connect(classSettingsChanged),
 effectsToggle.Activated:Connect(function() activateSetting("ToggleEffects") end),
 Quality.Changed:Connect(effectsChanged),
 player:GetAttributeChangedSignal("EffectsQuality"):Connect(effectsChanged),
 player:GetAttributeChangedSignal("ClassAutoAim"):Connect(classSettingsChanged),
 player:GetAttributeChangedSignal("ViewAsServer"):Connect(viewAsServerChanged),
	SoundService:GetAttributeChangedSignal("BossMusicMuted"):Connect(preferenceChanged),
}
if viewAsServerToggle then
	table.insert(
		settingsConnections,
		viewAsServerToggle.Activated:Connect(function()
			activateSetting("ToggleViewAsServer")
		end)
	)
end
local function settingsLayout()
 local height=viewAsServerToggle and 308 or 262
 local size=settingsGui.AbsoluteSize
 local touch=UIS.TouchEnabled
 local buttonHeight=touch and 44 or 38
 settings.Size=UDim2.fromOffset(106,buttonHeight)
 local right,bottom=size.X-20,size.Y-20
 local jumpTop,jumpBottom=TouchLayout.GetJumpBounds()
 if jumpTop then
  if size.X<size.Y then
   right=size.X-16
   bottom=jumpTop.Y-12
  else
   right=math.max(118,math.min(right,jumpTop.X-12))
   bottom=math.min(bottom,jumpBottom.Y)
  end
 end
 settings.Position=UDim2.fromOffset(right,bottom)
 local panelBottom=bottom-buttonHeight-10
 local panelHeight=math.min(height,math.max(100,panelBottom-12))
 local panelWidth=math.max(180,math.min(240,size.X-40,right-12))
 settingsPanel.Position=UDim2.fromOffset(right,panelBottom)
 settingsPanel.CanvasSize=UDim2.fromOffset(0,height)
 settingsPanel.Size=UDim2.fromOffset(panelWidth,panelHeight)
 closeSettings.Position=UDim2.fromOffset(right-48,panelBottom-panelHeight+8)
end
settingsConnections[#settingsConnections + 1] =
	settingsGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(settingsLayout)
settingsConnections[#settingsConnections+1]=TouchLayout.Changed:Connect(settingsLayout)
settingsLayout()
preferenceChanged()
 
 
 
gui.IgnoreGuiInset = false
p.Parent = gui
p.AnchorPoint = Vector2.new(0.5, 0)
p.Position = UDim2.new(0.5, 0, 0, 24)
p.Size = UDim2.fromOffset(850, 74)
p.BackgroundTransparency = 1
p.ClipsDescendants = false
local container = gui:FindFirstChild("Container")
if container then
	container.Visible = false
end
local legacyScale = p:FindFirstChildOfClass("UIScale")
if legacyScale then
	legacyScale.Scale = 1
end
local panelConstraint = p:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint")
panelConstraint.MinSize = Vector2.new(0, 0)
panelConstraint.MaxSize = Vector2.new(850, 100)
panelConstraint.Parent = p
p.Title.AnchorPoint = Vector2.zero
p.Title.Position = UDim2.fromOffset(0, 0)
p.Title.Size = UDim2.new(0.65, 0, 0, 28)
p.Title.TextSize = 25
p.Title.TextXAlignment = Enum.TextXAlignment.Left
p.Title.TextScaled = true
local titleLimit = p.Title:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
titleLimit.MinTextSize = 12
titleLimit.MaxTextSize = 25
titleLimit.Parent = p.Title
p.HealthBar.AnchorPoint = Vector2.zero
p.ShieldBar.AnchorPoint = Vector2.zero
p.ShieldValue.AnchorPoint = Vector2.zero
p.HealthBar.Position = UDim2.fromOffset(0, 34)
p.HealthBar.Size = UDim2.new(1, 0, 0, 17)
p.HealthBar.Value.Position = UDim2.fromScale(0, 0)
p.HealthBar.Value.Size = UDim2.fromScale(1, 1)
p.HealthBar.Value.TextSize = 16
p.ShieldBar.Position = UDim2.fromOffset(0, 56)
p.ShieldBar.Size = UDim2.new(1, 0, 0, 4)
p.ShieldValue.Position = UDim2.fromOffset(0, 62)
p.ShieldValue.Size = UDim2.new(1, 0, 0, 12)
p.ShieldValue.TextSize = 13
p.ShieldValue.TextXAlignment = Enum.TextXAlignment.Right
 
 
for _, name in ipairs({ "DefenseStatus", "AccelerationStatus", "BossPassiveDock", "BossBuffDock", "BossDebuffDock", "TrueCloneHealth" }) do
	local obsolete = p:FindFirstChild(name)
	if obsolete then
		obsolete:Destroy()
	end
end
local revealedVisibility = {}
for _, child in ipairs(p:GetChildren()) do
	if child:IsA("GuiObject") then
		revealedVisibility[child] = child.Visible
	end
end
local current, pendingActor
local pendingConnections, encounterConnections = {}, {}
local destroyed = false
local shieldVisible = true
local function responsiveLayout()
	local viewport = gui.AbsoluteSize
	local width = math.min(850, math.floor(viewport.X * (viewport.X < 700 and 0.9 or 0.58)))
	p.Size = UDim2.fromOffset(math.max(160, width), shieldVisible and 74 or 56)
	p.Position = UDim2.new(0.5, 0, 0, math.clamp(viewport.Y * 0.035, 16, 36))
	if current and current.Layout then
		current.Layout(width)
	end
end
local sizeConnection = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(responsiveLayout)
responsiveLayout()
local function available()
	return not destroyed
		and workspace:GetAttribute("EncounterStarted") == true
		and not workspace:GetAttribute("BossEncounterWon")
end
local function opening()
	p.Title.Text = "???"
	p.Title.Visible = true
	for child in pairs(revealedVisibility) do
		if child.Parent == p then
			child.Visible = child == p.Title
		end
	end
	gui.Enabled = available()
	Descriptions.RefreshTooltip()
end
local function clearPending()
	for _, connection in ipairs(pendingConnections) do
		connection:Disconnect()
	end
	table.clear(pendingConnections)
	pendingActor = nil
end
local function clearBoss()
	local binding = current
	current = nil
	if binding then
		binding.Clean()
	end
end
local function text(parent, name, size, position, value)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Garamond
	label.TextSize = 19
	label.TextColor3 = Color3.fromRGB(255, 228, 136)
	label.TextStrokeTransparency = 0.25
	label.Text = value
	label.Parent = parent
	return label
end
local function fmt(n)
	return tostring(math.ceil(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
local bindBoss
bindBoss = function(boss)
	if destroyed or not boss or not boss:IsA("Model") or not boss:IsDescendantOf(workspace) then
		return
	end
	if current and current.Actor == boss then
		current.Update()
		return
	end
	clearPending()
	clearBoss()
	opening()
	local h = boss:FindFirstChildOfClass("Humanoid")
	if not h then
		 
		 
		pendingActor = boss
		pendingConnections[1] = boss.ChildAdded:Connect(function(child)
			if pendingActor == boss and child:IsA("Humanoid") then
				bindBoss(boss)
			end
		end)
		pendingConnections[2] = boss.Destroying:Connect(function()
			if pendingActor == boss then
				clearPending()
			end
		end)
		pendingConnections[3] = boss.AncestryChanged:Connect(function()
			if pendingActor == boss and not boss:IsDescendantOf(workspace) then
				clearPending()
			end
		end)
		return
	end
	for child, visible in pairs(revealedVisibility) do
		if child.Parent == p then
			child.Visible = visible
		end
	end
	local binding = { Actor = boss }
	current = binding
	local passiveDock = Instance.new("Frame")
	passiveDock.Name = "BossPassiveDock"
	passiveDock.AnchorPoint = Vector2.new(1, 0)
	passiveDock.Position = UDim2.new(1, 0, 0, -1)
	passiveDock.Size = UDim2.new(0.34, 0, 0, 28)
	passiveDock.BackgroundTransparency = 1
	passiveDock.Parent = p
	local passiveLayout = Instance.new("UIListLayout")
	passiveLayout.FillDirection = Enum.FillDirection.Horizontal
	passiveLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	passiveLayout.Padding = UDim.new(0, 6)
	passiveLayout.SortOrder = Enum.SortOrder.LayoutOrder
	passiveLayout.Parent = passiveDock
	local passiveRows = {}
	for index, id in ipairs({
		"P1Unstoppable",
		"P15Clone",
		"P2HourDebt",
		"P25FutureSight",
		"P4Regeneration",
		"P4Enraged",
  "P4TrueSpirit",
  "P5God",
  "P5Spacetrum",
  "P5Verdant",
  "P5Pastborn",
  "P5Enraged",
  "P5SuperEnraged",
  "P4Karmanation",
		"P3GoldenMark",
  "P3Misdirection",
  "P35Debuffer",
		"LinkedClone",
		"DiffHellaven",
		"DiffTrueHardcore",
		"DiffHardcore",
		"DiffNerfedHardcore",
		"DiffEasy",
	}) do
		local entry = Descriptions.Entries[id]
		local icon = Instance.new("Frame")
		icon.Name = id
		icon.Size = UDim2.fromOffset(27, 27)
		icon.BackgroundColor3 = Color3.fromRGB(10, 9, 6)
		icon.BackgroundTransparency = 0.25
		icon.BorderSizePixel = 0
		icon.LayoutOrder = index
		icon.Visible = false
		icon.Parent = passiveDock
		Descriptions.CreateIcon(icon, id, UDim2.fromOffset(21, 21), UDim2.fromOffset(3, 3))
		local outline = Instance.new("UIStroke")
		outline.Color = Color3.fromRGB(139, 115, 54)
		outline.Transparency = 0.2
		outline.Parent = icon
		Descriptions.AttachTooltip(icon, id, "Passive ability")
		passiveRows[id] = icon
	end
	local buffDock = Instance.new("Frame")
	buffDock.Name = "BossBuffDock"
	buffDock.AnchorPoint = Vector2.new(1, 0)
	buffDock.Position = UDim2.new(1, 0, 1, 12)
	buffDock.Size = UDim2.new(0.27, 0, 0, 29)
	buffDock.BackgroundTransparency = 1
	buffDock.Parent = p
	local buffLayout = Instance.new("UIListLayout")
	buffLayout.FillDirection = Enum.FillDirection.Horizontal
	buffLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	buffLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buffLayout.Padding = UDim.new(0, 7)
	buffLayout.Parent = buffDock
	local function buff(id, order)
		local entry = Descriptions.Entries[id]
		local frame = Instance.new("Frame")
		frame.Name = id
		frame.Size = UDim2.fromOffset(29, 29)
		frame.BackgroundColor3 = Color3.fromRGB(10, 9, 6)
		frame.BackgroundTransparency = 0.25
		frame.BorderSizePixel = 0
		frame.LayoutOrder = order
		frame.Visible = false
		frame.Parent = buffDock
		local outline = Instance.new("UIStroke")
		outline.Color = Color3.fromRGB(139, 115, 54)
		outline.Transparency = 0.2
		outline.Parent = frame
		Descriptions.CreateIcon(frame, id, UDim2.fromOffset(23, 23), UDim2.fromOffset(3, 3))
		local value = text(frame, "Detail", UDim2.fromOffset(1, 1), UDim2.fromOffset(0, 0), "")
		value.Visible = false
		Descriptions.AttachTooltip(frame, id, function()
			if id == "P4Enraged" then
				return string.format("%d stacks · %.1fs remaining\nCrit chance %.0f%% · bonus damage +%.0f%%\nHit pulse cooldown: %.1fs",
					boss:GetAttribute("EnragedStacks") or 0,
					math.max(0, (boss:GetAttribute("EnragedUntil") or 0) - workspace:GetServerTimeNow()),
					(boss:GetAttribute("EnragedCritChance") or 0) * 100,
					(boss:GetAttribute("EnragedCritDamage") or 0) * 100,
					math.max(0, (boss:GetAttribute("EnragedHUDReadyAt") or 0) - workspace:GetServerTimeNow()))
			end
			return id == "P25FutureSight" and "Prediction active" or "Duration: " .. value.Text
		end)
		return frame, value
	end
	local debuffDock=Instance.new("Frame")
 debuffDock.Name="BossDebuffDock"
 debuffDock.Position=UDim2.new(0,0,1,12)
 debuffDock.Size=UDim2.new(.65,0,0,64)
 debuffDock.BackgroundTransparency=1 debuffDock.Parent=p
 local debuffLayout=Instance.new("UIGridLayout")
 debuffLayout.CellSize=UDim2.fromOffset(28,28) debuffLayout.CellPadding=UDim2.fromOffset(5,5)
 debuffLayout.SortOrder=Enum.SortOrder.LayoutOrder debuffLayout.Parent=debuffDock
 local definitions={
  {Id="BossStunned",Attributes={"ClassStunnedUntil","StunnedUntil"},Frame="ClassStunFrame"},
  {Id="BossTaunted",Attributes={"TauntedUntil"}},
  {Id="BossSlowed",Attributes={"SlowedUntil","SlowUntil","DecelerationUntil"}},
  {Id="BossVulnerable",Attributes={"VulnerabilityUntil","DisorderDebuff_Vulnerability"}},
  {Id="BossBleed",Attributes={"BleedUntil","DisorderDebuff_Bleed"}},
  {Id="BossPoison",Attributes={"PoisonUntil"}},
  {Id="BossBurn",Attributes={"GoldenBurnUntil","BurnUntil"}},
  {Id="BossHolyFlame",Attributes={"HolyFlameUntil"},Tint=Color3.fromRGB(255,232,150)},
 }
 for _,name in ipairs({"Hemorrhage","Rupture","Acid","Decay","Corruption","Frostbite","TemporalWound","ChainCurse","DeathMark","IllusionRot","Blur","Fear","JumpLock","CooldownIncrease","CooldownFreeze"}) do
  table.insert(definitions,{Id=name,Attributes={"DisorderDebuff_"..name},Tint=Color3.fromRGB(255,120,235)})
 end
 local debuffs={}
 for index,definition in ipairs(definitions) do
  local row=Instance.new("Frame") row.Name=definition.Id row.LayoutOrder=index
  row.BackgroundColor3=Color3.fromRGB(35,13,13) row.BackgroundTransparency=.12 row.BorderSizePixel=0 row.Visible=false row.Parent=debuffDock
  local stroke=Instance.new("UIStroke") stroke.Color=definition.Tint or Color3.fromRGB(224,108,103) stroke.Transparency=.2 stroke.Parent=row
  Descriptions.CreateIcon(row,definition.Id,UDim2.fromOffset(20,20),UDim2.fromOffset(3,4),definition.Tint or Color3.fromRGB(255,147,130))
  local timer=text(row,"Countdown",UDim2.new(1,-25,1,0),UDim2.fromOffset(25,0),"")
  timer.TextSize=12 timer.TextColor3=Color3.fromRGB(255,198,178) timer.Visible=false
  Descriptions.AttachTooltip(row,definition.Id,function()
   return definition.Id=="BossTaunted" and ("Defender: "..tostring(boss:GetAttribute("TauntedBy") or "")) or ("Remaining: "..timer.Text)
  end)
  debuffs[definition.Id]={Row=row,Timer=timer,Definition=definition}
 end
 local gateRowsVisible
 local function updateDebuffs()
  local now=workspace:GetServerTimeNow()
  local below=gateRowsVisible and gateRowsVisible() or 0
  debuffDock.Position=UDim2.new(0,0,1,12+below)
  for id,item in pairs(debuffs) do
   local deadline=0 for _,attribute in item.Definition.Attributes do deadline=math.max(deadline,boss:GetAttribute(attribute) or 0) end
   local held=item.Definition.Frame and boss:GetAttribute(item.Definition.Frame)~=nil
   item.Row.Visible=h.Health>0 and (held or deadline>now) and not boss:GetAttribute("EncounterEnded")
   item.Timer.Text=id=="BossTaunted" and "!" or held and deadline<=now and "…" or string.format("%.1f",math.max(0,deadline-now))
  end
 end
 local acceleration, accelerationValue = buff("Acceleration", 1)
	local futureSight, futureSightValue = buff("P25FutureSight", 2)
	local enraged, enragedValue = buff("P4Enraged", 3)
	local enragedOutline = enraged:FindFirstChildOfClass("UIStroke")
	local clonePanel = Instance.new("Frame")
	clonePanel.Name = "TrueCloneHealth"
	clonePanel.Position = UDim2.new(0, 0, 1, 12)
	clonePanel.Size = UDim2.new(0.48, 0, 0, 80)
	clonePanel.BackgroundTransparency = 1
	clonePanel.Visible = false
	clonePanel.Parent = p
	local cloneTitle =
		text(clonePanel, "Title", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 0), "alterGolden's Puppeteer")
	cloneTitle.TextSize = 21
	cloneTitle.TextXAlignment = Enum.TextXAlignment.Left
	cloneTitle.TextScaled = true
	local cloneTitleLimit = Instance.new("UITextSizeConstraint")
	cloneTitleLimit.MinTextSize = 12
	cloneTitleLimit.MaxTextSize = 21
	cloneTitleLimit.Parent = cloneTitle
	local cloneValue = text(clonePanel, "Value", UDim2.new(1, 0, 0, 13), UDim2.fromOffset(0, 46), "")
	cloneValue.TextXAlignment = Enum.TextXAlignment.Right
	cloneValue.TextSize = 13
	local cloneTrack = Instance.new("Frame")
	cloneTrack.Name = "Track"
	cloneTrack.Position = UDim2.fromOffset(0, 27)
	cloneTrack.Size = UDim2.new(1, 0, 0, 13)
	cloneTrack.BackgroundColor3 = Color3.fromRGB(14, 11, 6)
	cloneTrack.BackgroundTransparency = 0.2
	cloneTrack.BorderSizePixel = 0
	cloneTrack.Parent = clonePanel
	local cloneFill = Instance.new("Frame")
	cloneFill.Name = "Fill"
	cloneFill.Size = UDim2.fromScale(1, 1)
	cloneFill.BackgroundColor3 = Color3.fromRGB(255, 214, 67)
	cloneFill.BorderSizePixel = 0
	cloneFill.Parent = cloneTrack
	local cloneRule = Instance.new("Frame")
	cloneRule.Name = "ShieldBar"
	cloneRule.Position = UDim2.new(0, 0, 1, 4)
	cloneRule.Size = UDim2.new(1, 0, 0, 3)
	cloneRule.BackgroundColor3 = Color3.fromRGB(33, 29, 20)
	cloneRule.BorderSizePixel = 0
	cloneRule.Parent = cloneTrack
	local cloneShieldFill = Instance.new("Frame")
	cloneShieldFill.Name = "Fill"
	cloneShieldFill.Size = UDim2.fromScale(0, 1)
	cloneShieldFill.BackgroundColor3 = Color3.fromRGB(255, 246, 202)
	cloneShieldFill.BorderSizePixel = 0
	cloneShieldFill.Parent = cloneRule
	local cloneBuffDock = Instance.new("Frame")
	cloneBuffDock.Name = "BuffDock"
	cloneBuffDock.Position = UDim2.fromOffset(0, 62)
	cloneBuffDock.Size = UDim2.fromOffset(24, 24)
	cloneBuffDock.BackgroundColor3 = Color3.fromRGB(10, 9, 6)
	cloneBuffDock.BackgroundTransparency = 0.25
	cloneBuffDock.BorderSizePixel = 0
	cloneBuffDock.Parent = clonePanel
	Descriptions.CreateIcon(cloneBuffDock, "LinkedClone", UDim2.fromOffset(20, 20), UDim2.fromOffset(2, 2))
	Descriptions.AttachTooltip(cloneBuffDock, "LinkedClone")
	Descriptions.AttachTooltip(clonePanel, "LinkedClone", function()
		return cloneValue.Text
	end)
	local gatePanels = {}
	for index = 1, 2 do
		local panel = Instance.new("Frame")
		panel.Name = "ShieldGateClone" .. index
		panel.Position = UDim2.new((index - 1) * 0.52, 0, 1, 12)
		panel.Size = UDim2.new(0.48, 0, 0, 57)
		panel.BackgroundTransparency = 1
		panel.Visible = false
		panel.Parent = p
		local title = text(panel, "Title", UDim2.new(1, 0, 0, 23), UDim2.fromOffset(0, 0), "Golden Clone " .. index)
		title.TextSize = 20
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize = 11
		limit.MaxTextSize = 20
		limit.Parent = title
		local track = Instance.new("Frame")
		track.Name = "HealthBar"
		track.Position = UDim2.fromOffset(0, 26)
		track.Size = UDim2.new(1, 0, 0, 13)
		track.BackgroundColor3 = Color3.fromRGB(14, 11, 6)
		track.BorderSizePixel = 0
		track.Parent = panel
		local bar = Instance.new("Frame")
		bar.Name = "Fill"
		bar.Size = UDim2.fromScale(1, 1)
		bar.BackgroundColor3 = Color3.fromRGB(255, 214, 67)
		bar.BorderSizePixel = 0
		bar.Parent = track
		local value = text(panel, "Value", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 42), "")
		value.TextSize = 13
		value.TextXAlignment = Enum.TextXAlignment.Right
		gatePanels[index] = { Panel = panel, Title = title, Track = track, Value = value }
	end
	gateRowsVisible=function()
		if clonePanel.Visible then return 92 end
		for _,row in ipairs(gatePanels) do if row.Panel.Visible then return 66 end end
		return 0
	end
	local active, values, connections = {}, {}, {}
	local cleaned = false
	local lastEnragedPulse = boss:GetAttribute("EnragedHUDPulseAt") or 0
	local function updateEnraged()
		local now = workspace:GetServerTimeNow()
		local remaining = math.max(0, (boss:GetAttribute("EnragedUntil") or 0) - now)
		local stacks = boss:GetAttribute("EnragedStacks") or 0
		enraged.Visible = h.Health > 0 and math.floor(boss:GetAttribute("Phase") or 0) == 4
			and not boss:GetAttribute("EncounterEnded") and stacks > 0 and remaining > 0
		if not enraged.Visible then
			if active[enragedOutline] then active[enragedOutline]:Cancel(); active[enragedOutline] = nil end
			enragedOutline.Transparency = 0.2
			return
		end
		enragedValue.Text = string.format("%d stacks · %.1fs", stacks, remaining)
		local pulse = boss:GetAttribute("EnragedHUDPulseAt") or 0
		if pulse > lastEnragedPulse then
			lastEnragedPulse = pulse
			if gui.Enabled and now - pulse < 0.75 then
				if active[enragedOutline] then active[enragedOutline]:Cancel() end
				enragedOutline.Transparency = 0
				active[enragedOutline] = Tween:Create(enragedOutline, TweenInfo.new(0.55), { Transparency = 0.2 })
				active[enragedOutline]:Play()
			end
		end
	end
	function binding.Layout(width)
		local count = 0
		for _, icon in pairs(passiveRows) do
			if icon.Visible then
				count += 1
			end
		end
		local passiveWidth = math.max(0, count * 27 + math.max(0, count - 1) * 6)
		passiveDock.Size = UDim2.fromOffset(passiveWidth, 28)
		p.Title.Size = UDim2.new(1, -passiveWidth - 12, 0, 28)
		clonePanel.Size = UDim2.new(width < 500 and 0.65 or 0.48, 0, 0, 80)
	end
	local function fill(track, ratio)
		ratio = math.clamp(ratio, 0, 1)
		if values[track] == ratio then
			return
		end
		values[track] = ratio
		if active[track] then
			active[track]:Cancel()
		end
		active[track] = Tween:Create(track.Fill, TweenInfo.new(0.12), { Size = UDim2.fromScale(ratio, 1) })
		active[track]:Play()
	end
	local updateQueued = false
	function binding.Update()
		if updateQueued or cleaned then return end
		updateQueued = true
		task.defer(function()
			updateQueued = false
			if cleaned or current ~= binding then
				return
			end
			gui.Enabled = available()
			if not gui.Enabled then
				return
			end
			local shield = boss:GetAttribute("Shield") or 0
			local maximum = boss:GetAttribute("MaxShield") or Config.ShieldMaxHealth
			local linked = boss:GetAttribute("Phase4LinkedActive") == true
			local protection = boss:GetAttribute("LinkedProtection") == true
			fill(p.ShieldBar, linked and (protection and 1 or 0) or shield / math.max(1, maximum))
			fill(p.HealthBar, h.Health / math.max(1, h.MaxHealth))
			shieldVisible = shield > 0 and maximum > 0
			p.ShieldBar.Visible = shieldVisible
			p.ShieldValue.Visible = shieldVisible
			p.ShieldValue.Text = linked and (protection and "Infinite" or "NULL") or fmt(shield) .. " / " .. fmt(maximum)
			p.HealthBar.Value.Text = fmt(h.Health) .. " / " .. fmt(h.MaxHealth)
			local phase = boss:GetAttribute("Phase") or 1
			local override = boss:GetAttribute("PhaseTitleOverride")
			local title = phase >= 4.5 and (Config.Phase45Title or Config.Phase4Title)
				or phase >= 4 and Config.Phase4Title
				or phase >= 3.5 and Config.Phase35Title
				or phase >= 3 and Config.Phase3Title
				or phase >= 2 and Config.Phase2Title
				or Config.Phase1Title
			if type(override) == "string" and override ~= "" then
				title = override
			elseif boss:GetAttribute("IdentityRevealed") ~= true and phase < 2 then
				title = "???"
			end
			local mode = phase >= 5 and boss:GetAttribute("P5Mode")
			if type(mode) == "string" and mode ~= "" then
				title = title .. "  ·  " .. mode
			end
			p.Title.Text = title
			for id, icon in pairs(passiveRows) do
				icon.Visible = h.Health > 0
					and (id == "LinkedClone" and linked or boss:GetAttribute("Passive_" .. id) == true)
					and not (
						math.floor(phase) == 3
						and (id == "P1Unstoppable" or id == "P15Clone" or id == "P2HourDebt" or id == "P25FutureSight")
					)
			end
			acceleration.Visible = h.Health > 0 and phase < 3 and boss:GetAttribute("AccelerationActive") == true
			local charges = boss:GetAttribute("FutureSightCharges") or 0
			futureSight.Visible = h.Health > 0 and phase == 2.5 and charges > 0
			futureSightValue.Text = ""
			updateEnraged()
	  updateDebuffs()
			local cloneHealth = boss:GetAttribute("LinkedCloneHealth") or 0
			local cloneMaximum = boss:GetAttribute("LinkedCloneMaxHealth") or Config.TrueCloneMaxHealth
			cloneTitle.Text = boss:GetAttribute("LinkedCloneTitle") or "alterGolden's Puppeteer"
			clonePanel.Visible = linked and boss:GetAttribute("LinkedCloneAlive") == true and h.Health > 0
			cloneValue.Text = fmt(cloneHealth) .. " / " .. fmt(cloneMaximum)
			fill(cloneTrack, cloneHealth / math.max(1, cloneMaximum))
			local cloneShield = boss:GetAttribute("LinkedCloneShield") or 0
			local cloneMaxShield = boss:GetAttribute("LinkedCloneMaxShield") or 0
			fill(cloneRule, cloneShield / math.max(1, cloneMaxShield))
			cloneRule.Visible = cloneShield > 0 and cloneMaxShield > 0
			for index, row in ipairs(gatePanels) do
				local prefix = "ShieldGateClone" .. index
				local hp = boss:GetAttribute(prefix .. "Health") or 0
				local maxHP = boss:GetAttribute(prefix .. "MaxHealth") or 1000
				row.Panel.Visible = boss:GetAttribute("ShieldCloneGateActive") == true
					and boss:GetAttribute(prefix .. "Alive") == true
					and h.Health > 0
				row.Title.Text = boss:GetAttribute(prefix .. "Title") or "Golden Clone " .. index
				row.Value.Text = fmt(hp) .. " / " .. fmt(maxHP)
				fill(row.Track, hp / math.max(1, maxHP))
			end
			responsiveLayout()
		end)
	end
	function binding.Clean()
		if cleaned then
			return
		end
		cleaned = true
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		for _, tween in pairs(active) do
			tween:Cancel()
		end
		table.clear(connections)
		table.clear(active)
		table.clear(values)
		passiveDock:Destroy()
		buffDock:Destroy()
  debuffDock:Destroy()
		clonePanel:Destroy()
		for _, row in ipairs(gatePanels) do
			row.Panel:Destroy()
		end
		Descriptions.RefreshTooltip()
	end
	local function removed()
		if current == binding then
			clearBoss()
			opening()
		end
	end
	connections[1] = h.HealthChanged:Connect(binding.Update)
	connections[2] = h:GetPropertyChangedSignal("MaxHealth"):Connect(binding.Update)
	connections[3] = boss.Destroying:Connect(removed)
	connections[4] = boss.AncestryChanged:Connect(function()
		if not boss:IsDescendantOf(workspace) then
			removed()
		end
	end)
	for _, name in ipairs({
  "ClassStunnedUntil","ClassStunFrame","StunnedUntil","TauntedUntil","TauntedBy","SlowedUntil","SlowUntil","DecelerationUntil","VulnerabilityUntil","BleedUntil","PoisonUntil","GoldenBurnUntil","BurnUntil","HolyFlameUntil",
		"AccelerationActive",
		"Phase",
		"Shield",
		"MaxShield",
		"PhaseTitleOverride",
		"IdentityRevealed",
		"FutureSightCharges",
		"FutureSightUntil",
		"Phase4LinkedActive",
		"LinkedProtection",
		"LinkedCloneAlive",
		"LinkedCloneHealth",
		"LinkedCloneMaxHealth",
		"LinkedCloneTitle",
		"LinkedCloneShield",
		"LinkedCloneMaxShield",
		"Passive_P1Unstoppable",
		"Passive_P15Clone",
		"Passive_P2HourDebt",
		"Passive_P25FutureSight",
		"Passive_P4Regeneration",
		"Passive_P4Enraged",
  "Passive_P4TrueSpirit",
  "Passive_P5God",
  "Passive_P5Spacetrum",
  "Passive_P5Verdant",
  "Passive_P5Pastborn",
  "Passive_P5Enraged",
  "Passive_P5SuperEnraged",
  "P5Mode",
  "Passive_P4Karmanation",
		"EnragedStacks",
		"EnragedUntil",
		"EnragedCritChance",
		"EnragedCritDamage",
		"EnragedHUDPulseAt",
		"EnragedHUDReadyAt",
		"EncounterEnded",
		"Passive_P3GoldenMark",
  "Passive_P3Misdirection",
  "Passive_P35Debuffer",
		"Passive_DiffHellaven",
		"Passive_DiffTrueHardcore",
		"Passive_DiffHardcore",
		"Passive_DiffNerfedHardcore",
		"Passive_DiffEasy",
	}) do
		connections[#connections + 1] = boss:GetAttributeChangedSignal(name):Connect(binding.Update)
	end
	for _, field in ipairs({
		"ShieldCloneGateActive",
		"ShieldGateClone1Health",
		"ShieldGateClone1MaxHealth",
		"ShieldGateClone1Alive",
		"ShieldGateClone1Title",
		"ShieldGateClone2Health",
		"ShieldGateClone2MaxHealth",
		"ShieldGateClone2Alive",
		"ShieldGateClone2Title",
	}) do
		connections[#connections + 1] = boss:GetAttributeChangedSignal(field):Connect(binding.Update)
	end
	local elapsed = 0
	connections[#connections + 1] = Run.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		if acceleration.Visible then
			accelerationValue.Text = string.format(
				"%.1fs",
				math.max(0, (boss:GetAttribute("AccelerationUntil") or 0) - workspace:GetServerTimeNow())
			)
		end
		updateEnraged()
  updateDebuffs()
		Descriptions.RefreshTooltip()
	end)
	binding.Update()
end
local function refreshEncounter()
	if destroyed then
		return
	end
	if workspace:GetAttribute("EncounterStarted") ~= true then
		clearPending()
		clearBoss()
		opening()
		return
	end
	if current then
		current.Update()
	else
		opening()
		local boss = workspace:FindFirstChild(BOSS_NAME)
		if boss then
			bindBoss(boss)
		end
	end
end
encounterConnections[1] = workspace.ChildAdded:Connect(function(child)
	if child.Name == BOSS_NAME and workspace:GetAttribute("EncounterStarted") == true then
		bindBoss(child)
	end
end)
encounterConnections[2] = workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(refreshEncounter)
encounterConnections[3] = workspace:GetAttributeChangedSignal("BossEncounterWon"):Connect(refreshEncounter)
encounterConnections[4] = script.Destroying:Connect(function()
	if destroyed then
		return
	end
	destroyed = true
	clearPending()
	clearBoss()
	sizeConnection:Disconnect()
	for _, connection in ipairs(encounterConnections) do
		connection:Disconnect()
	end
	for _, connection in ipairs(settingsConnections) do
		connection:Disconnect()
	end
	settingsGui:Destroy()
	table.clear(encounterConnections)
	gui.Enabled = false
end)
refreshEncounter()

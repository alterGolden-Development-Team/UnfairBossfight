local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer
local events = game.ReplicatedStorage
 
 
task.spawn(function()
  for _ = 1, 8 do
    if pcall(function()
      StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end) then
      return
    end
    task.wait(0.25)
  end
end)
local DashMotion = require(Shared:WaitForChild("Movement"):WaitForChild("R6DashMotion"))
local Dialogue = require(Shared:WaitForChild("Presentation"):WaitForChild("DialoguePresentation"))
local Descriptions = require(Shared:WaitForChild("Presentation"):WaitForChild("EffectDescriptions"))
local combatRemote = events:WaitForChild("BossCombatEffects")
local gui = Instance.new("ScreenGui")
gui.Name = "PlayerEncounterHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 90
gui.Parent = player:WaitForChild("PlayerGui")
local function label(name, parent, size, pos, text)
  local item = Instance.new("TextLabel")
  item.Name = name
  item.Size = size
  item.Position = pos
  item.BackgroundTransparency = 1
  item.Font = Enum.Font.Garamond
  item.TextSize = 23
  item.TextColor3 = Color3.fromRGB(245, 244, 235)
  item.TextStrokeTransparency = 0.1
  item.Text = text
  item.Parent = parent
  return item
end
local function border(parent, color)
  local stroke = Instance.new("UIStroke")
  stroke.Color = color
  stroke.Thickness = 2
  stroke.Parent = parent
end
local buffs = Instance.new("Frame")
buffs.Name = "PlayerStatusDock"
buffs.Position = UDim2.new(0.035, 0, 0.27, 0)
buffs.Size = UDim2.fromOffset(270, 260)
buffs.AutomaticSize = Enum.AutomaticSize.None
buffs.BackgroundTransparency = 1
buffs.Parent = gui
local statusScroll=Instance.new("ScrollingFrame")
statusScroll.Name="EffectList"
statusScroll.Size=UDim2.new(1,0,1,-18)
statusScroll.BackgroundTransparency=1
statusScroll.BorderSizePixel=0
statusScroll.CanvasSize=UDim2.fromOffset(0,0)
statusScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
statusScroll.ScrollingDirection=Enum.ScrollingDirection.Y
statusScroll.ScrollBarThickness=4
statusScroll.ScrollBarImageColor3=Color3.fromRGB(224,181,92)
statusScroll.ElasticBehavior=Enum.ElasticBehavior.WhenScrollable
statusScroll.Active=true
statusScroll.ClipsDescendants=true
statusScroll.Parent=buffs
local statusHint=label("ScrollHint",buffs,UDim2.new(1,0,0,16),UDim2.new(0,0,1,-16),"Scroll for more effects")
statusHint.TextSize=14
statusHint.TextColor3=Color3.fromRGB(224,217,188)
statusHint.TextXAlignment=Enum.TextXAlignment.Left
statusHint.Visible=false
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = statusScroll
local buffScale = Instance.new("UIScale")
buffScale.Parent = buffs
local function group(name, title, order)
  local frame = Instance.new("Frame")
  frame.Name = name
  frame.Size = UDim2.fromOffset(260, 0)
  frame.AutomaticSize = Enum.AutomaticSize.Y
  frame.BackgroundTransparency = 1
  frame.LayoutOrder = order
  frame.Visible = false
  frame.Parent = statusScroll
  local layout = Instance.new("UIListLayout")
  layout.SortOrder = Enum.SortOrder.LayoutOrder
  layout.Padding = UDim.new(0, 5)
  layout.Parent = frame
  local heading = label("Heading", frame, UDim2.fromOffset(260, 20), UDim2.fromOffset(0, 0), title)
  heading.TextSize = 17
  heading.TextXAlignment = Enum.TextXAlignment.Left
  heading.TextColor3 = Color3.fromRGB(224, 217, 188)
  heading.LayoutOrder = -1
  return frame
end
local buffGroup = group("Buffs", "BUFFS", 1)
local debuffGroup = group("Debuffs", "DEBUFFS", 2)
local function buff(name, title, order, id, debuff)
  local frame = Instance.new("Frame")
  frame.Name = name
  frame.Size = UDim2.fromOffset(260, 34)
  frame.LayoutOrder = order
  frame.BackgroundColor3 = Color3.fromRGB(9, 9, 9)
  frame.BackgroundTransparency = 0.25
  frame.BorderSizePixel = 0
  frame.Visible = false
  frame.Parent = debuff and debuffGroup or buffGroup
  border(frame, debuff and Color3.fromRGB(72, 43, 32) or Color3.fromRGB(65, 58, 30))
  Descriptions.CreateIcon(
    frame,
    id,
    UDim2.fromOffset(23, 23),
    UDim2.fromOffset(5, 5),
    debuff and Color3.fromRGB(241, 167, 130) or Color3.fromRGB(255, 222, 100)
  )
  local text = label("Title", frame, UDim2.new(1, -105, 1, 0), UDim2.fromOffset(30, 0), title)
  text.TextSize = 20
  text.TextXAlignment = Enum.TextXAlignment.Left
 text.TextTruncate=Enum.TextTruncate.AtEnd
 local stack=label("StackCount",frame,UDim2.fromOffset(36,20),UDim2.new(1,-106,0,7),"")
 stack.TextSize=14
 stack.TextColor3=debuff and Color3.fromRGB(255,191,146) or Color3.fromRGB(255,222,100)
 stack.Visible=false
  local timer = label("Countdown", frame, UDim2.fromOffset(60, 34), UDim2.new(1, -65, 0, 0), "15.0s")
  timer.TextSize = 18
  Descriptions.AttachTooltip(frame, id, function()
    if id == "Halved" then
      return string.format(
        "Maximum HP remaining: %.2f%%. Removed by Cleanse or death.",
        (player:GetAttribute("HalvedHealthFraction") or 1) * 100
      )
    end
    if timer.Text == "" then
      return nil
    end
    local duration=timer.Text:match("^%d") and "Duration: "..timer.Text or "Active: "..timer.Text
  return stack.Visible and "Stacks: "..stack.Text:sub(2).." · "..duration or duration
  end)
  return frame, timer
end
local function stackCount(frame,title,count)
 local stacked=count>0
 frame.Title.Text=title
 frame.Title.Size=UDim2.new(1,stacked and -144 or -105,1,0)
 frame.StackCount.Visible=stacked
 frame.StackCount.Text="x"..tostring(count)
end
local slowBuff, slowCountdown = buff("SlowDebuff", "20% Slow", 1, "Slow", true)
local bleedBuff, bleedCountdown = buff("BleedDebuff", "Bleed", 2, "Bleed", true)
local chainBuff, chainCountdown = buff("ChainDebuff", "Chained", 3, "Chained", true)
local electricBuff,electricCountdown=buff("ElectricifiedDebuff","Electricified",4,"Electricified",true)
local flungBuff,flungCountdown=buff("FlungDebuff","Flung",4,"Flung",true)
local stunBuff, stunCountdown = buff("StunDebuff", "Stunned", 3, "Stunned", true)
local burnBuff, burnCountdown = buff("GoldenBurnDebuff", "Golden Burn", 4, "GoldenBurn", true)
local decelBuff, decelCountdown = buff("DecelerationDebuff", "Deceleration", 5, "Deceleration", true)
local halvedBuff, halvedCountdown = buff("HalvedDebuff", "Halved", 7, "Halved", true)
local markBuff, markCountdown = buff("GoldenMarkDebuff", "Golden Mark x0", 6, "GoldenMark", true)
local stolenBuff, stolenCountdown = buff("StolenSecondDebuff", "Stolen Second", 8, "StolenSecond", true)
local distortionBuff, distortionCountdown =
  buff("ControlDistortionDebuff", "Control Distortion", 11, "P3ControlDistortion", true)
local thiefBuff, thiefCountdown = buff("ThiefSealDebuff", "Abilities Sealed", 10, "P3Thief", true)
local p3Rows = {}
for order, row in ipairs({
  { "HPRegenBlock", "HP Regen Block", true },
  { "StaminaRegenBlock", "Stamina Regen Block", true },
  { "AttackDebuff", "25% Attack Down", true },
  { "CardBurn", "Burn", true },
  { "AstralBurn", "Burn", true },
 { "Poison", "Poison", true },
  { "Rupture", "Rupture", true },
  { "IllusionRot", "Illusion Rot", true },
  { "Frostbite", "Frostbite", true },
  { "Hemorrhage", "Hemorrhage", true },
  { "Corruption", "Corruption", true },
  { "Decay", "Decay", true },
  { "Vulnerability", "Vulnerability", true },
  { "CooldownIncrease", "Cooldown Increase", true },
  { "CooldownFreeze", "Cooldown Freeze", true },
  { "ChainCurse", "Chain Curse", true },
  { "TemporalWound", "Temporal Wound", true },
  { "Acid", "Acid", true },
  { "DeathMark", "Death Mark", true },
  { "JumpLock", "Jump Lock", true },
  { "Blur", "Blur", true },
 { "Fear", "Fear", true },
  { "ProjectileDarkness", "Darkness", true },
  { "Cleanse", "Cleanse", false },
  { "CupAttackBoost", "ATK Boost", false },
  { "CupRegenBoost", "HP Regen Boost", false },
}) do
  local frame, timer = buff(row[1] .. "Effect", row[2], 12 + order, row[1], row[3])
  table.insert(p3Rows, { frame, timer, row[1] .. "Until" })
end
local SoundService = game:GetService("SoundService")
local encounterInfo = Instance.new("Frame")
encounterInfo.Name = "EncounterTimerAndMusic"
encounterInfo.AnchorPoint = Vector2.new(0, 1)
encounterInfo.Position = UDim2.new(0.035, 0, 1, -153)
encounterInfo.Size = UDim2.new(0.35, 0, 0, 45)
encounterInfo.BackgroundTransparency = 1
encounterInfo.Visible = false
encounterInfo.Parent = gui
local soundtrack = label("SoundtrackName", encounterInfo, UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 0), "")
soundtrack.TextSize = 17
soundtrack.TextXAlignment = Enum.TextXAlignment.Left
soundtrack.TextTruncate = Enum.TextTruncate.AtEnd
local encounterTimer = label("EncounterTimer", encounterInfo, UDim2.new(1, 0, 0, 23), UDim2.fromOffset(0, 22), "00:00")
encounterTimer.TextSize = 22
encounterTimer.TextXAlignment = Enum.TextXAlignment.Left
local encounterStartedAt
local encounterFinishedAt
local function syncEncounterTimer()
  if workspace:GetAttribute("EncounterStarted") == true then
    encounterStartedAt = workspace:GetAttribute("EncounterStartedAt")
      or encounterStartedAt
      or workspace:GetServerTimeNow()
    encounterInfo.Visible = true
  else
    encounterStartedAt = nil
    encounterFinishedAt = nil
    encounterInfo.Visible = false
  end
end
local encounterConnection = workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(syncEncounterTimer)
local encounterTimeConnection = workspace:GetAttributeChangedSignal("EncounterStartedAt"):Connect(syncEncounterTimer)
syncEncounterTimer()
local dock = Instance.new("Frame")
dock.Name = "ActionDock"
dock.AnchorPoint = Vector2.new(1, 0.5)
dock.Position = UDim2.new(0.97, 0, 0.5, 0)
dock.Size = UDim2.fromOffset(220, 166)
dock.BackgroundTransparency = 1
dock.Parent = gui
local dockScale = Instance.new("UIScale")
dockScale.Parent = dock
local function layout()
  local scale =
    math.min(1, math.max(0.3, (gui.AbsoluteSize.X - 48) / 620), math.max(0.3, (gui.AbsoluteSize.Y - 180) / 200))
  buffScale.Scale = scale
 dockScale.Scale = scale
 local height=gui.AbsoluteSize.Y
 local bottom=height-210
 local top=math.min(height*.27,math.max(24,bottom-90))
 local room=math.max(36,bottom-top)
 buffs.Position=UDim2.new(.035,0,0,top)
 buffs.Size=UDim2.fromOffset(270,math.min(320*scale,room)/scale)
end
local layoutConnection = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()
local function skill(name, key, title, y)
  local button = Instance.new("TextButton")
  button.Name = name
  button.Position = UDim2.fromOffset(0, y)
  button.Size = UDim2.fromOffset(220, 46)
  button.BackgroundColor3 = Color3.fromRGB(62, 64, 66)
  button.BackgroundTransparency = 0.1
  button.BorderSizePixel = 0
  button.Text = ""
  button.Parent = dock
  border(button, Color3.fromRGB(139, 139, 139))
  local keybox = Instance.new("Frame")
  keybox.Name = "KeyBox"
  keybox.Size = UDim2.fromOffset(42, 46)
  keybox.BackgroundColor3 = Color3.fromRGB(76, 78, 80)
  keybox.BorderSizePixel = 0
  keybox.Parent = button
  border(keybox, Color3.fromRGB(139, 139, 139))
  label("Key", keybox, UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), key).TextSize = 27
  local text = label("SkillName", button, UDim2.new(1, -49, 0, 30), UDim2.fromOffset(49, 0), title)
  text.TextSize = 23
  local timer = label("Timer", button, UDim2.new(1, -49, 0, 16), UDim2.fromOffset(49, 29), "Ready")
  timer.TextSize = 14
  timer.TextColor3 = Color3.fromRGB(215, 215, 215)
  return button, timer
end
local dashButton, dashTimer = skill("DashButton", "Q", "Dash", 0)
dashTimer.Text = string.format("%d stamina", DashMotion.Cost)
Descriptions.AttachTooltip(dashButton, "Dash")
local quote = label("BossDialogue", gui, UDim2.new(0.86, 0, 0, 75), UDim2.new(0.07, 0, 0.69, 0), "")
quote.TextSize = 36
quote.TextColor3 = Color3.fromRGB(255, 244, 178)
quote.Visible = false
local victory = Instance.new("Frame")
victory.Name = "BossVictory"
victory.Size = UDim2.fromScale(1, 1)
victory.BackgroundColor3 = Color3.new(1, 1, 1)
victory.BackgroundTransparency = 1
victory.BorderSizePixel = 0
victory.Visible = false
victory.ZIndex = 20
victory.Parent = gui
local band = Instance.new("Frame")
band.Name = "VictoryBand"
band.Size = UDim2.fromScale(1, 0.28)
band.Position = UDim2.fromScale(0, 0.37)
band.BackgroundColor3 = Color3.new(0, 0, 0)
band.BackgroundTransparency = 1
band.BorderSizePixel = 0
band.ZIndex = 21
band.Parent = victory
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Transparency = NumberSequence.new({
  NumberSequenceKeypoint.new(0, 1),
  NumberSequenceKeypoint.new(0.38, 0.22),
  NumberSequenceKeypoint.new(0.5, 0),
  NumberSequenceKeypoint.new(0.62, 0.22),
  NumberSequenceKeypoint.new(1, 1),
})
gradient.Parent = band
local winTitle = label("VictoryTitle", band, UDim2.fromScale(0.94, 1), UDim2.fromScale(0.03, 0), "alterGolden Defeated")
winTitle.TextSize = 55
winTitle.TextColor3 = Color3.fromRGB(255, 225, 37)
winTitle.TextTransparency = 1
winTitle.TextStrokeTransparency = 1
winTitle.ZIndex = 22
local titleSize = Instance.new("UITextSizeConstraint")
titleSize.MaxTextSize = 55
titleSize.MinTextSize = 24
titleSize.Parent = winTitle
winTitle.TextScaled = true
local winSubtitle=label("VictorySubtitle",band,UDim2.fromScale(0.94,0.22),UDim2.fromScale(0.03,0.76),"")
winSubtitle.TextSize=22
winSubtitle.TextColor3=Color3.fromRGB(242,225,173)
winSubtitle.TextXAlignment=Enum.TextXAlignment.Center
winSubtitle.TextYAlignment=Enum.TextYAlignment.Center
winSubtitle.TextTransparency=1
winSubtitle.ZIndex=22
winTitle.Size=UDim2.fromScale(0.94,0.76)
local victoryShown = false
local victoryTweens = {}
local function cancelVictoryTweens()
  for _, tween in ipairs(victoryTweens) do
    tween:Cancel()
  end
  table.clear(victoryTweens)
end
local function showVictory(title,subtitle)
  if victoryShown then
    if type(title)=="string" then winTitle.Text=title end
    if type(subtitle)=="string" then winSubtitle.Text=subtitle end
    return
  end
  victoryShown = true
  victory.Visible = true
  winTitle.Text=title or "Golden Defeated"
 winSubtitle.Text=subtitle or workspace:GetAttribute("BossVictorySubtitle") or ""
 winSubtitle.Visible=true
  quote.Visible = false
  dock.Visible = false
  buffs.Visible = false
  encounterFinishedAt = workspace:GetServerTimeNow()
  Descriptions.RefreshTooltip()
  victoryTweens[1] = Tween:Create(band, TweenInfo.new(0.7), { BackgroundTransparency = 0.12 })
  victoryTweens[2] =
    Tween:Create(winTitle, TweenInfo.new(0.7), { TextTransparency = 0, TextStrokeTransparency = 0.35 })
  victoryTweens[3]=Tween:Create(winSubtitle,TweenInfo.new(0.7),{TextTransparency=0})
  for _, tween in ipairs(victoryTweens) do
    tween:Play()
  end
end
local dialogue
local function sealRemaining()
  local char = player.Character
  return math.max(
    0,
    math.max(
      player:GetAttribute("AbilitiesSealedUntil") or 0,
      char and char:GetAttribute("AbilitiesSealedUntil") or 0
    ) - workspace:GetServerTimeNow()
  )
end
local inputConnections = {}
inputConnections[#inputConnections + 1] = dashButton.Activated:Connect(function()
  local vitals = player.PlayerGui:FindFirstChild("PlayerVitalsHUD")
  local request = vitals and vitals:FindFirstChild("RequestDash")
  if request then
    request:Fire()
  end
end)
local combatConnection = combatRemote.OnClientEvent:Connect(function(kind, data)
  if kind == "BossDialogue" and not victoryShown then
    dialogue = Dialogue.Begin(quote, data.Text, data.Duration, data)
  elseif kind == "BossVictory" then
    showVictory(data.Title,data.Subtitle)
  end
end)
local victoryConnection = workspace:GetAttributeChangedSignal("BossEncounterWon"):Connect(function()
  if workspace:GetAttribute("BossEncounterWon") then
    showVictory(workspace:GetAttribute("BossVictoryTitle"))
  elseif victoryShown then
    cancelVictoryTweens()
    victoryShown = false
    victory.Visible = false
    victory.BackgroundTransparency = 1
    band.BackgroundTransparency = 1
    winTitle.TextTransparency = 1
  winSubtitle.TextTransparency=1
    winTitle.TextStrokeTransparency = 1
    encounterFinishedAt = nil
  end
end)
if workspace:GetAttribute("BossEncounterWon") then
  showVictory(workspace:GetAttribute("BossVictoryTitle"))
end
local uiElapsed = 0
local heartbeat = Run.Heartbeat:Connect(function(dt)
  if dialogue and not victoryShown and not Dialogue.Step(dialogue) then dialogue = nil end
  uiElapsed += dt
  if uiElapsed < 0.1 then return end
  uiElapsed %= 0.1
  if encounterStartedAt then
    local elapsed = math.max(0, (encounterFinishedAt or workspace:GetServerTimeNow()) - encounterStartedAt)
    encounterTimer.Text = string.format("%02d:%02d", math.floor(elapsed / 60), math.floor(elapsed % 60))
    local name = SoundService:GetAttribute("BossSoundtrackName") or ""
    soundtrack.Text = name ~= "" and "♫  " .. name or ""
  end
  if victoryShown then
    return
  end
  local now = workspace:GetServerTimeNow()
  local char = player.Character
  local h = char and char:FindFirstChildOfClass("Humanoid")
  local alive = (
    h
    and h.Health > 0
    and not player:GetAttribute("PermanentlyDefeated")
    and not player:GetAttribute("ExecutionPending")
  ) == true
  local distortionLeft = math.max(
    0,
    math.max(
      player:GetAttribute("ControlDistortionUntil") or 0,
      char and char:GetAttribute("ControlDistortionUntil") or 0
    ) - now
  )
  distortionBuff.Visible = alive and distortionLeft > 0
  distortionCountdown.Text = string.format("%.1fs", distortionLeft)
  local sealLeft = sealRemaining()
  local sealed = sealLeft > 0
  thiefBuff.Visible = alive and sealed
  thiefCountdown.Text = string.format("%.1fs", sealLeft)
  for _, row in ipairs(p3Rows) do
    local remaining = math.max(0, (player:GetAttribute(row[3]) or 0) - now)
    row[1].Visible = alive and remaining > 0
    row[2].Text = string.format("%.1fs", remaining)
  local kind=row[3]:match("^(.-)Until$")
  if kind=="Hemorrhage" or kind=="DeathMark" then
   stackCount(row[1],Descriptions.Entries[kind].Name,player:GetAttribute(kind.."Stacks") or 0)
  end
  end
  for _,row in ipairs({{electricBuff,electricCountdown,"ElectricifiedUntil"},{flungBuff,flungCountdown,"FlungUntil"}}) do
  local remaining=math.max(0,math.max(player:GetAttribute(row[3]) or 0,char and char:GetAttribute(row[3]) or 0)-now)
  row[1].Visible=alive and remaining>0
  row[2].Text=string.format("%.1fs",remaining)
 end
 local locked = player:GetAttribute("AbilitiesLocked") == true
  for _, row in ipairs({ { slowBuff, slowCountdown, "SlowUntil" }, { bleedBuff, bleedCountdown, "BleedUntil" } }) do
    local remaining = math.max(0, (player:GetAttribute(row[3]) or 0) - now)
    local inZone = row[3] == "SlowUntil" and player:GetAttribute("ZoneSlowActive") == true
    row[1].Visible = alive and (remaining > 0 or inZone)
    row[2].Text = inZone and "In area" or string.format("%.1fs", remaining)
    if row[3] == "SlowUntil" then
      slowBuff.Title.Text =
        string.format("%d%% Slow", math.floor((player:GetAttribute("SlowAmount") or 0.2) * 100 + 0.5))
    end
  end
  local stolen = alive and char:GetAttribute("StolenSecondActive") == true
  stolenBuff.Visible = stolen
  stolenCountdown.Text = stolen
      and (char:GetAttribute("StolenSecondReplaying") and "Replay" or string.format(
        "%.1fs",
        math.max(0, (player:GetAttribute("StolenSecondUntil") or 0) - now)
      ))
    or ""
  local cinematic = alive and char:GetAttribute("ShieldBreakCinematicLocked") == true
  local grabbed = alive and (char:GetAttribute("PickThePupilsCaptured") == true or char:GetAttribute("PlayerCloneCaptured") == true)
  local cardStunLeft=math.max(0,(char and char:GetAttribute("CardStunnedUntil") or 0)-now)
 stunBuff.Visible = grabbed or alive and cardStunLeft>0
 stunCountdown.Text = cardStunLeft>0 and string.format("%.1fs",cardStunLeft) or ""
  chainBuff.Visible = alive
    and not grabbed
    and not cinematic
    and not stolen
    and char:GetAttribute("TimeFrozen") ~= true
    and (player:GetAttribute("ChainedControlActive")==true
   or player:GetAttribute("ChainedControlActive")==nil and (locked or player:GetAttribute("MovementLocked")==true))
  chainCountdown.Text = ""
  burnBuff.Visible = alive and player:GetAttribute("GoldenBurnActive") == true
  local burnLeft=math.max(0,(player:GetAttribute("GoldenBurnUntil") or 0)-now)
 burnCountdown.Text = burnLeft>0 and string.format("%.1fs",burnLeft) or "In flame"
  local decel = math.max(0, (player:GetAttribute("DecelerationUntil") or 0) - now)
  decelBuff.Visible = alive and decel > 0
  decelCountdown.Text = string.format("%.1fs", decel)
  local halvedStacks = player:GetAttribute("HalvedStacks") or 0
  halvedBuff.Visible = alive and halvedStacks > 0
  stackCount(halvedBuff,"Halved",halvedStacks)
  halvedCountdown.Text = "Life"
  local markStacks = player:GetAttribute("GoldenMarkStacks") or 0
  local markLeft = math.max(0, (player:GetAttribute("GoldenMarkUntil") or 0) - now)
  markBuff.Visible = alive and markStacks > 0 and markLeft > 0
  stackCount(markBuff,"Golden Mark",markStacks)
  markCountdown.Text = string.format("%.1fs", markLeft)
  local frozen = math.max(0, (workspace:GetAttribute("TimeStopUntil") or 0) - now)
  local storingDash = stolen and char:GetAttribute("StolenSecondRecording") == true
  dashButton.Active = alive
      and not locked
      and (storingDash or player:GetAttribute("DashLocked") ~= true)
      and frozen <= 0
      and (char:GetAttribute("Stamina") or 0) >= DashMotion.Cost
    or false
  dashButton.AutoButtonColor = dashButton.Active
  dashTimer.Text = storingDash and "Store Dash" or tostring(DashMotion.Cost) .. " stamina"
  local lost = player:GetAttribute("PermanentlyDefeated") == true
  dock.Visible = not lost
  buffs.Visible = not lost
  for _, groupFrame in ipairs({ buffGroup, debuffGroup }) do
    local count=0
  for _,child in ipairs(groupFrame:GetChildren()) do
   if child:IsA("Frame") and child.Visible then count+=1 end
  end
  groupFrame.Visible=count>0
  groupFrame.Heading.Text=string.format("%s (%d)",groupFrame==debuffGroup and "DEBUFFS" or "BUFFS",count)
  end
  buffs.Visible=not lost and (buffGroup.Visible or debuffGroup.Visible)
 local maxScroll=math.max(0,statusScroll.AbsoluteCanvasSize.Y-statusScroll.AbsoluteWindowSize.Y)
 statusHint.Visible=maxScroll>1
 if statusScroll.CanvasPosition.Y>maxScroll then
  statusScroll.CanvasPosition=Vector2.new(0,maxScroll)
 end
  Descriptions.RefreshTooltip()
end)
script.Destroying:Connect(function()
  heartbeat:Disconnect()
  layoutConnection:Disconnect()
  combatConnection:Disconnect()
  victoryConnection:Disconnect()
  encounterConnection:Disconnect()
  encounterTimeConnection:Disconnect()
  for _, connection in ipairs(inputConnections) do
    connection:Disconnect()
  end
  cancelVictoryTweens()
  gui:Destroy()
end)


player:SetAttribute("EncounterHUDReady", true)
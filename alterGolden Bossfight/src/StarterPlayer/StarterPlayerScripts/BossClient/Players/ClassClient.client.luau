local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
 
 
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local ClassConfig = require(game.ReplicatedStorage:WaitForChild("BossShared"):WaitForChild("Classes"):WaitForChild("ClassConfig"))
local remote = game.ReplicatedStorage:WaitForChild("ClassControl")
local EnemyTargets=require(game.ReplicatedStorage.BossShared.Classes.EnemyTargetRules)

local DIM = Color3.fromRGB(157, 162, 172)
local function now()
  return workspace:GetServerTimeNow()
end
local function character()
  local c = player.Character
  local h = c and c:FindFirstChildOfClass("Humanoid")
  if c and h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart") then
    return c
  end
end
local function controlLocked(c)
 return not c or player.Character ~= c or not character()
  or player:GetAttribute("ChainBreakActive")==true
  or workspace:GetAttribute("BossEncounterWon")==true
  or player:GetAttribute("ViewAsServer") or player:GetAttribute("ExecutionPending")
  or player:GetAttribute("PermanentlyDefeated") or c.HumanoidRootPart.Anchored
  or workspace:GetAttribute("GoldenTimeStopped")==true or player:GetAttribute("TimeFrozen")
  or c:GetAttribute("ParryFrozen") or c:GetAttribute("TimeFrozen")
  or c:GetAttribute("AbilitiesLocked") or c:GetAttribute("StatusLocked") or c:GetAttribute("FinalAttackLocked")
  or c:GetAttribute("MovementLocked") or c:GetAttribute("ShieldBreakDashLocked")
  or c:GetAttribute("ShieldBreakCinematicLocked") or c:GetAttribute("DeathScytheHaltToken") ~= nil
  or now() < math.max(player:GetAttribute("AbilitiesSealedUntil") or 0,c:GetAttribute("AbilitiesSealedUntil") or 0)
end
local function classOf()
  local c = player.Character
  return ClassConfig.Get(c and c:GetAttribute("ClassId") or player:GetAttribute("PlayerClass"))
end

local aimTargets=setmetatable({},{__mode="k"})
local function trackAimTarget(object)
 if object:IsA("Humanoid") and object.Parent and object.Parent:IsA("Model") then aimTargets[object.Parent]=true end
end
for _,object in workspace:GetDescendants() do trackAimTarget(object) end
workspace.DescendantAdded:Connect(trackAimTarget)
 
local function aimPoint(key)
  local cam = workspace.CurrentCamera
  if not cam then return nil end
  local m
  if UIS.PreferredInput==Enum.PreferredInput.Touch or UIS.PreferredInput==Enum.PreferredInput.Gamepad then
   m=cam.ViewportSize*.5
  else
   local inset=GuiService:GetGuiInset()
   m=UIS:GetMouseLocation()-inset
  end
  local ray = cam:ViewportPointToRay(m.X, m.Y)
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  local ignore = { player.Character }
  for _,name in ipairs({"ClassEffects","GoldenCombatEffects","BossAttackAimTargets"}) do
   local effects=workspace:FindFirstChild(name) if effects then table.insert(ignore,effects) end
  end
  for target in pairs(aimTargets) do
   if target.Parent and EnemyTargets.IsOrdinaryClone(target) then table.insert(ignore,target) end
  end
  params.FilterDescendantsInstances = ignore
  local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
  local manual=hit and hit.Position or ray.Origin+ray.Direction*300
  local char=character()
  if player:GetAttribute("ClassAutoAim")==false or not char
   or char:GetAttribute("ClassId")=="Supporter" and (key=="F" or key=="C")
   or char:GetAttribute("ClassId")=="Mage" and key=="C"
   or char:GetAttribute("ClassId")=="Disorderer" and key=="F" then return manual end
  local sightParams=RaycastParams.new()
  sightParams.FilterType=Enum.RaycastFilterType.Exclude
  sightParams.RespectCanCollide=true
  sightParams.FilterDescendantsInstances=ignore
  local best,bestScore
  for target in pairs(aimTargets) do
   local root=target:FindFirstChild("HumanoidRootPart")
   local h=target:FindFirstChildOfClass("Humanoid")
   if root and h and EnemyTargets.Available(target) then
    local distance=(root.Position-char.HumanoidRootPart.Position).Magnitude
    local screen,visible=cam:WorldToViewportPoint(root.Position)
    if visible and distance<=240 then
     local pixels=(Vector2.new(screen.X,screen.Y)-m).Magnitude
     local obstruction=workspace:Raycast(ray.Origin,root.Position-ray.Origin,sightParams)
     local aimRadius=target:GetAttribute("IsShieldGateClone") and math.min(320,cam.ViewportSize.X*.4) or math.min(220,cam.ViewportSize.X*.3)
     if pixels<=aimRadius and (not obstruction or obstruction.Instance:IsDescendantOf(target)) then
      local score=pixels+distance*0.08
      if not bestScore or score<bestScore then best,bestScore=root.Position,score end
     end
    end
   end
  end
  return best or manual
end
local canUse
local FACE_AIM = { M1 = true, F = true, C = true, V = true }
 
canUse = function(c, id, key)
  local t = workspace:GetServerTimeNow()
  local chainF=id=="Mage" and key=="F" and (c:GetAttribute("MageNearbyOrbs") or 0)>=ClassConfig.Classes.Mage.F.OrbCost and t>=(c:GetAttribute("MageOrbDashReadyAt") or 0)
  if t < (c:GetAttribute("ClassCD_" .. key) or 0) and not chainF then
    if not (id == "Duelist" and ((key == "F" and c:GetAttribute("ClassStatus_FlashstepReady")) or (key == "C" and c:GetAttribute("ClassStatus_PhasingReady")))) and not (id == "Disorderer" and key == "V" and c:GetAttribute("ClassStatus_Checkpoint")) and not (id == "TrueWarrior" and (key == "C" or key == "F") and c:GetAttribute("TWHidden_" .. key)) then
      return false
    end
  end
  if t < (c:GetAttribute("ClassSealed_" .. key) or 0) then
    return false
  end
  local orbs = c:GetAttribute("MageOrbs") or 0
  local stamina = c:GetAttribute("Stamina") or 0
  if id == "Mage" and (key=="F" and (c:GetAttribute("MageNearbyOrbs") or 0)<ClassConfig.Classes.Mage.F.OrbCost or key=="C") then
    return false  
  end
  if id == "Gambler" and key == "C" and c:GetAttribute("ClassStatus_TrustedGun") then
    return false
  end
  local cost = ({ Supporter = { F = 15 }, Duelist = { F = 8, C = 15, V = 30 }, Disorderer = { F = 15 } })[id]
  if cost and cost[key] and stamina < cost[key] then
    return false
  end
  if id == "Supporter" and key == "F" then
    return false  
  end
  return true
end
local heldKeys={}
local hudHeldKeys,hudInputs={},{}
local function act(key, phase)
 local c=character()
 if phase=="End" then
  if c then remote:FireServer("Action",key,"End") end
  return
 end
 if controlLocked(c) then return end
 if key=="R" and phase=="Begin" and (c:GetAttribute("ClassHoldingSkill") and not c:GetAttribute("TWHidden_R") or now()<(c:GetAttribute("BlockBrokenUntil") or 0) or (now()<(c:GetAttribute("ClassCD_R") or 0) and not c:GetAttribute("TWHidden_R"))) then return end
 local id=c:GetAttribute("ClassId")
 local aimKey=key=="Aim" and ((heldKeys.C or hudHeldKeys.C) and id=="Mage" and "C" or "V") or key
 local aim=aimPoint(aimKey)
 if not aim then return end
 if phase=="Begin" and FACE_AIM[key] and not c:GetAttribute("ClassStatus_Blocking")
  and not (id=="Supporter" and (key=="F" or key=="C")) and canUse(c,id,key) then
  local root=c.HumanoidRootPart
  local flat=Vector3.new(aim.X,root.Position.Y,aim.Z)
  if (flat-root.Position).Magnitude>1 then root.CFrame=CFrame.lookAt(root.Position,flat) end
 end
 remote:FireServer("Action",key,phase,aim)
end

 
local moving
local twinPath
local function stopMove()
  if twinPath then twinPath:Disconnect() twinPath = nil end
  if moving then
    moving.Conn:Disconnect()
    if moving.LV.Parent then
      moving.LV:Destroy()
    end
    if moving.Att.Parent then
      moving.Att:Destroy()
    end
    moving = nil
  end
end
local function startMove(data)
  stopMove()
  local c = character()
  if controlLocked(c) then
    return
  end
  local root = c.HumanoidRootPart
  local att = Instance.new("Attachment")
  att.Parent = root
  local lv = Instance.new("LinearVelocity")
  lv.Attachment0 = att
  lv.MaxForce = 1e6
  lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
  lv.PrimaryTangentAxis = Vector3.xAxis
  lv.SecondaryTangentAxis = Vector3.zAxis
  lv.RelativeTo = Enum.ActuatorRelativeTo.World
  lv.Parent = root
  local dir = data.Direction or root.CFrame.LookVector
  local ends = os.clock() + (data.Duration or 0.2)
 local revision = c:GetAttribute("ClassActionRevision") or 0
  local conn
  conn = Run.Heartbeat:Connect(function()
    if os.clock() >= ends or not root.Parent or controlLocked(c)
   or (c:GetAttribute("ClassActionRevision") or 0) ~= revision then
      stopMove()
      return
    end
    local homing = data.Homing
    if homing and homing.Parent and homing:FindFirstChild("HumanoidRootPart") then
      local d = homing.HumanoidRootPart.Position - root.Position
      d = Vector3.new(d.X, 0, d.Z)
      if d.Magnitude > 0.5 then
        dir = d.Unit
      end
    end
    local v = Vector3.new(dir.X, 0, dir.Z) * (data.Speed or 50)
    lv.PlaneVelocity = Vector2.new(v.X, v.Z)
    root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(dir.X, 0, dir.Z))
  end)
  moving = { Conn = conn, LV = lv, Att = att }
end

 
 
 
local function startTwinPath(data)
  stopMove()
  local c = character()
  if controlLocked(c) then
    return
  end
  local root = c.HumanoidRootPart
  local revision = c:GetAttribute("ClassActionRevision") or 0
  local steps, started = data.Steps or {}, os.clock()
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  params.RespectCanCollide = true
  local ignore = { c }
  local fx = workspace:FindFirstChild("ClassEffects")
  if fx then
    table.insert(ignore, fx)
  end
  for model in pairs(aimTargets) do
    table.insert(ignore, model)
  end
  params.FilterDescendantsInstances = ignore
  local from, prevT, index = root.Position, 0, 1
  local function bossRoot(step)
    local boss = step.Boss
    return boss and boss.Parent and boss:FindFirstChild("HumanoidRootPart")
  end
  local function resolve(step)
    local target = bossRoot(step)
    if target then
      local b = target.Position
      local flat = Vector3.new(b.X - from.X, 0, b.Z - from.Z)
      flat = flat.Magnitude > 0.1 and flat.Unit or Vector3.zAxis
      local p = b - flat * (step.Back or 0) + Vector3.new(0, step.Up or 0, 0)
      if step.Ground then
        local hit = workspace:Raycast(Vector3.new(p.X, b.Y + 20, p.Z), Vector3.new(0, -300, 0), params)
        p = Vector3.new(p.X, (hit and hit.Position.Y or b.Y - 3) + 3, p.Z)
      end
      return p
    end
    return step.To or root.Position
  end
  twinPath = Run.Heartbeat:Connect(function()
    if not root.Parent or controlLocked(c) or (c:GetAttribute("ClassActionRevision") or 0) ~= revision then
      if twinPath then twinPath:Disconnect() twinPath = nil end
      return
    end
    local t = os.clock() - started
    while steps[index] and t >= steps[index].T do
      from = resolve(steps[index])
      prevT = steps[index].T
      index += 1
    end
    local step = steps[index]
    if not step then
      root.CFrame = CFrame.new(from) * root.CFrame.Rotation
      root.AssemblyLinearVelocity = Vector3.zero
      if twinPath then twinPath:Disconnect() twinPath = nil end
      return
    end
    local k = math.clamp((t - prevT) / math.max(step.T - prevT, 0.001), 0, 1)
    if step.Ease == "in" then k = k * k elseif step.Ease == "out" then k = 1 - (1 - k) ^ 2 end
    local pos = from:Lerp(resolve(step), k)
    local target = bossRoot(step)
    local look = target and (target.Position - pos) or (data.Face or root.CFrame.LookVector)
    local flat = Vector3.new(look.X, 0, look.Z)
    root.CFrame = flat.Magnitude > 0.1 and CFrame.lookAt(pos, pos + flat) or CFrame.new(pos) * root.CFrame.Rotation
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
  end)
end

local function startBlink(data)
  stopMove()
  local c = character()
  if controlLocked(c) then
    return
  end
  local root = c.HumanoidRootPart
  local revision = c:GetAttribute("ClassActionRevision") or 0
  local dir = data.Direction or root.CFrame.LookVector
  dir = Vector3.new(dir.X, 0, dir.Z)
  dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
  task.spawn(function()
    if (data.Delay or 0) > 0 then
      task.wait(data.Delay)
    end
    if not root.Parent or controlLocked(c) or (c:GetAttribute("ClassActionRevision") or 0) ~= revision then
      return
    end
    local origin = root.Position
    local distance = data.Distance or 24
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.RespectCanCollide = true
    local ignore = { c }
    local fx = workspace:FindFirstChild("ClassEffects")
    if fx then
      table.insert(ignore, fx)
    end
    for model in pairs(aimTargets) do
      table.insert(ignore, model)
    end
    params.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(origin, dir * (distance + 3), params)
    if hit then
      distance = math.max(0, hit.Distance - 2.5)
    end
    local dest = origin + dir * distance
    local duration = math.max(data.Time or 0.05, 0.016)
    local started = os.clock()
    local conn
    conn = Run.Heartbeat:Connect(function()
      if not root.Parent or controlLocked(c) then
        conn:Disconnect()
        return
      end
      local a = math.clamp((os.clock() - started) / duration, 0, 1)
      local p = origin:Lerp(dest, a)
      root.CFrame = CFrame.lookAt(p, p + dir)
      root.AssemblyLinearVelocity = Vector3.zero
      if a >= 1 then
        conn:Disconnect()
      end
    end)
  end)
end

 
 
local TweenService = game:GetService("TweenService")
local function twinStorm(data)
  local assets = game.ReplicatedStorage:FindFirstChild("VFXEngine") and game.ReplicatedStorage.VFXEngine:FindFirstChild("Assets")
  local template = assets and assets:FindFirstChild("ArcSlash")
  if not template then return end
  local def = ClassConfig.Classes.Twinblade
  local Debris = game:GetService("Debris")
  local white = Color3.new(1, 1, 1)
  local rng = Random.new(data.Seed)
  local folder = Instance.new("Folder")
  folder.Name = "TwinStormLocal"
  folder.Parent = workspace
  local half, frame = data.Half, data.Frame
  local function slash(cf, width, color, alpha, life)
    local p = template:Clone()
    p.Size = template.Size * (width / template.Size.X)
    p.Color, p.Material, p.TextureID, p.Transparency = color, Enum.Material.Neon, "", alpha
    p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
    p.CFrame = cf
    p.Parent = folder
    TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
    Debris:AddItem(p, life + 0.05)
  end
  task.spawn(function()
    local interval = data.Duration / data.Ticks
    for i = 1, data.Ticks do
      if i > 2 and not (data.Char and data.Char.Parent and data.Char:GetAttribute("TwinbladeVanished")) then break end
      for n = 1, data.Slashes do
        local at = frame * Vector3.new(rng:NextNumber(-half, half), rng:NextNumber(2, 28), rng:NextNumber(-half, half))
        local cf = CFrame.new(at) * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28))
        local width = rng:NextNumber(18, 40)
        slash(cf, width * 1.14, n % 2 == 0 and def.Color or def.Color2, 0.42, 0.26)
        if n % 2 == 0 then slash(cf, width, white, 0.05, 0.26) end
      end
      for n = 1, 6 do
        local cf = frame * CFrame.new(rng:NextNumber(-half, half), 0.4, rng:NextNumber(-half, half)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0) * CFrame.Angles(math.pi / 2, 0, 0)
        slash(cf, rng:NextNumber(20, 34), n % 2 == 0 and def.Color or def.Color2, 0.1, 0.8)
      end
      task.wait(interval)
    end
    task.delay(1.2, function() folder:Destroy() end)
  end)
end
local Cam = { fov = 0, roll = 0, push = 0, tFov = 0, tRoll = 0, tPush = 0, speed = 8, applied = 0 }
local cinemaGui, topBar, bottomBar
local function setBars(on, time)
  if not cinemaGui or not cinemaGui.Parent then
    cinemaGui = Instance.new("ScreenGui")
    cinemaGui.Name = "DuelistCinema"
    cinemaGui.IgnoreGuiInset = true
    cinemaGui.ResetOnSpawn = false
    cinemaGui.DisplayOrder = 50
    cinemaGui.Parent = player:WaitForChild("PlayerGui")
    local function bar(anchor)
      local f = Instance.new("Frame")
      f.BackgroundColor3 = Color3.new(0, 0, 0)
      f.BorderSizePixel = 0
      f.AnchorPoint = Vector2.new(0, anchor)
      f.Position = UDim2.fromScale(0, anchor)
      f.Size = UDim2.fromScale(1, 0)
      f.Parent = cinemaGui
      return f
    end
    topBar, bottomBar = bar(0), bar(1)
  end
  local goal = { Size = UDim2.fromScale(1, on and 0.1 or 0) }
  local info = TweenInfo.new(time or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
  TweenService:Create(topBar, info, goal):Play()
  TweenService:Create(bottomBar, info, goal):Play()
end
local function camTarget(fov, roll, push, speed)  
  Cam.tFov, Cam.tRoll, Cam.tPush, Cam.speed = fov, roll, push, speed or 8
end
local function camKick(fov, roll, push, speed)  
  Cam.fov, Cam.roll, Cam.push = fov, roll, push
  Cam.tFov, Cam.tRoll, Cam.tPush, Cam.speed = 0, 0, 0, speed or 9
end
Run:BindToRenderStep("DuelistCinemaCamera", Enum.RenderPriority.Camera.Value + 2, function(dt)
  local camera = workspace.CurrentCamera
  if not camera then
    return
  end
  local k = 1 - math.exp(-Cam.speed * dt)
  Cam.fov += (Cam.tFov - Cam.fov) * k
  Cam.roll += (Cam.tRoll - Cam.roll) * k
  Cam.push += (Cam.tPush - Cam.push) * k
  if Cam.tFov == 0 and math.abs(Cam.fov) < 0.01 then
    Cam.fov = 0
  end
  if Cam.tRoll == 0 and math.abs(Cam.roll) < 0.01 then
    Cam.roll = 0
  end
  if Cam.tPush == 0 and math.abs(Cam.push) < 0.01 then
    Cam.push = 0
  end
  Fov.Set(script,Cam.fov)
  Cam.applied = Cam.fov
  if Cam.roll ~= 0 or Cam.push ~= 0 then
    camera.CFrame = camera.CFrame * CFrame.new(0, 0, -Cam.push) * CFrame.Angles(0, 0, math.rad(Cam.roll))
  end
end)
local cinemaToken = 0
local function endCinema()
  cinemaToken += 1
  camTarget(0, 0, 0, 6)
  if cinemaGui and cinemaGui.Parent then
    setBars(false, 0.4)
  end
end
local function cinema(data)
  local mode = data and data.Mode
  if mode == "Charge" then
    cinemaToken += 1
    local token = cinemaToken
    setBars(true, 0.45)
    camTarget(-9, 0, 1.5, 1.4)  
    task.delay((data.Duration or 1) + 5, function()  
      if cinemaToken == token then
        endCinema()
      end
    end)
  elseif mode == "Blink" then
    camKick(data.Power == 2 and 24 or 13, 0, data.Power == 2 and 1.5 or 0, data.Power == 2 and 6 or 8)
  elseif mode == "Cut" then
    camKick(-3, ((data.Index or 1) % 2 == 0) and 2.4 or -2.4, 0.7, 11)
  elseif mode == "Raise" then
    camTarget(-7, 0, 1.4, 4)  
  elseif mode == "Finish" then
    camKick(20, 3.5, -2.2, 4.5)
  elseif mode == "End" then
    endCinema()
  end
end

 
local lasering = false
local function requestDash()
  local dashChar = player.Character
  if dashChar and dashChar:GetAttribute("TrueWarriorCinematic") then return end
  local vitals = player.PlayerGui:FindFirstChild("PlayerVitalsHUD")
  local request = vitals and vitals:FindFirstChild("RequestDash")
  if request then
    request:Fire()
  end
end
 
local shownPrompts = 0
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
  shownPrompts += 1
  prompt.PromptHidden:Once(function()
    shownPrompts = math.max(0, shownPrompts - 1)
  end)
end)
local function bind(name, key, handler)
  CAS:BindActionAtPriority(name, function(_, state, input)
    if key == Enum.KeyCode.E and shownPrompts > 0 then
      return Enum.ContextActionResult.Pass
    end
    if state == Enum.UserInputState.Begin then
      heldKeys[key.Name]=true
      handler("Begin")
    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
      heldKeys[key.Name]=nil
      handler("End")
    end
    return Enum.ContextActionResult.Sink
  end, false, 3000, key)
end
local function bindAll()
  for _, old in ipairs({ "PlayerDodge" }) do
    pcall(CAS.UnbindAction, CAS, old)
  end
  bind("ClassDash", Enum.KeyCode.Q, function(phase)
    if phase == "Begin" then
      requestDash()
    end
  end)
  bind("ClassBlock", Enum.KeyCode.R, function(phase)
    act("R", phase)
  end)
  for _, k in ipairs({ "F", "C", "V" }) do
    bind("Class" .. k, Enum.KeyCode[k], function(phase)
      act(k, phase)
    end)
  end
end
 
local m1Held = false
local inputLoopAlive=true
local function endHudInput(input)
 local key=hudInputs[input]
 if not key then return end
 hudInputs[input]=nil
 if hudHeldKeys[key]==input then hudHeldKeys[key]=nil end
 if key=="M1" then
  if not m1Held then act(key,"End") end
 elseif key~="Q" and not heldKeys[key] then act(key,"End") end
end
local function releaseHudInputs()
 for input in pairs(hudInputs) do endHudInput(input) end
end
UIS.InputBegan:Connect(function(input, processed)
  if processed then
    return
  end
  if input.UserInputType == Enum.UserInputType.MouseButton1 then
    m1Held = true
    act("M1", "Begin")
  end
end)
UIS.InputEnded:Connect(function(input)
  endHudInput(input)
  local key=input.KeyCode.Name
  if heldKeys[key] and ({F=true,C=true,V=true,R=true})[key] then heldKeys[key]=nil act(key,"End") end
  if input.UserInputType == Enum.UserInputType.MouseButton1 and m1Held then
    m1Held = false
    act("M1", "End")
  end
end)
local function releaseHeld()
 if m1Held then act("M1","End") end
 m1Held=false
 releaseHudInputs()
 for key in pairs(heldKeys) do
  if ({F=true,C=true,V=true,R=true})[key] then act(key,"End") end
  heldKeys[key]=nil
 end
end
UIS.WindowFocusReleased:Connect(releaseHeld)
player.CharacterRemoving:Connect(releaseHeld)
 
task.spawn(function()
  while inputLoopAlive do
    task.wait(0.1)
    if (m1Held or hudHeldKeys.M1) and not UIS:GetFocusedTextBox() then
      local c = character()
      if c and now() >= (c:GetAttribute("ClassCD_M1") or 0) then
        act("M1", "Begin")
      end
    end
    local sc = player.Character
    if (heldKeys.F or hudHeldKeys.F) and sc and sc:GetAttribute("ClassId")=="Tank" then
     if UIS:IsKeyDown(Enum.KeyCode.F) or hudHeldKeys.F then act("F","Hold") else heldKeys.F=nil act("F","End") end
    end
    if (heldKeys.R or hudHeldKeys.R) and sc and sc:GetAttribute("ClassStatus_Blocking") then act("R","Hold") end
    if lasering or heldKeys.C or hudHeldKeys.C or (sc and sc:GetAttribute("ClassAimStream")) then
      act("Aim", "Hold")
    end
  end
end)

 
local hud = Instance.new("ScreenGui")
hud.Name = "ClassHUD"
hud.ResetOnSpawn = false
hud.DisplayOrder = 5
hud.Parent = player:WaitForChild("PlayerGui")
local function hudLabel(name, parent, size, pos, text)
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
  return stroke
end
local KEYS = { "M1", "Q", "R", "F", "C", "V" }
local dock = Instance.new("Frame")
dock.Name = "ClassActionDock"
dock.AnchorPoint = Vector2.new(1, 0.5)
dock.Position = UDim2.new(0.97, 0, 0.5, 0)
dock.Size = UDim2.fromOffset(220, #KEYS * 60 - 14)
dock.BackgroundTransparency = 1
dock.Parent = hud
local dockScale = Instance.new("UIScale")
dockScale.Parent = dock

local slots = {}
for i, key in ipairs(KEYS) do
  local button = Instance.new("TextButton")
  button.Name = "Class" .. key .. "Button"
  button.Position = UDim2.fromOffset(0, (i - 1) * 60)
  button.Size = UDim2.fromOffset(220, 46)
  button.BackgroundColor3 = Color3.fromRGB(62, 64, 66)
  button.BackgroundTransparency = 0.1
  button.BorderSizePixel = 0
  button.Text = ""
  button.AutoButtonColor = false
  button.Parent = dock
  border(button, Color3.fromRGB(139, 139, 139))
  local keybox = Instance.new("Frame")
  keybox.Name = "KeyBox"
  keybox.Size = UDim2.fromOffset(42, 46)
  keybox.BackgroundColor3 = Color3.fromRGB(76, 78, 80)
  keybox.BorderSizePixel = 0
  keybox.Parent = button
  border(keybox, Color3.fromRGB(139, 139, 139))
  local keyLabel = hudLabel("Key", keybox, UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), key)
  keyLabel.TextSize = key == "M1" and 21 or 27
  local title = hudLabel("SkillName", button, UDim2.new(1, -49, 0, 30), UDim2.fromOffset(49, 0), "")
  title.TextSize = 23
  title.TextScaled = false
  title.TextTruncate = Enum.TextTruncate.AtEnd
  local timer = hudLabel("Timer", button, UDim2.new(1, -49, 0, 16), UDim2.fromOffset(49, 29), "Ready")
  timer.TextSize = 14
  timer.TextColor3 = Color3.fromRGB(215, 215, 215)
  slots[key] = { Button = button, Title = title, Timer = timer }
   
  button.InputBegan:Connect(function(input)
   local kind=input.UserInputType
   if kind~=Enum.UserInputType.Touch and kind~=Enum.UserInputType.MouseButton1
    and not (kind.Name:match("^Gamepad") and input.KeyCode==Enum.KeyCode.ButtonA) then return end
   if hudHeldKeys[key] or not hud.Enabled then return end
   hudHeldKeys[key]=input
   hudInputs[input]=key
   if key=="Q" then requestDash() else act(key,"Begin") end
  end)
  button.InputEnded:Connect(endHudInput)
  button.Activated:Connect(function(input)
   if input.UserInputType~=Enum.UserInputType.Keyboard then return end
   if key=="Q" then requestDash() else act(key,"Begin"); act(key,"End") end
  end)
end
 
local Descriptions = require(game.ReplicatedStorage:WaitForChild("BossShared"):WaitForChild("Presentation"):WaitForChild("EffectDescriptions"))
local TouchLayout=require(game.ReplicatedStorage.BossShared.Presentation.TouchControlLayout)
local function layout()
 local size=hud.AbsoluteSize
 local touch=UIS.TouchEnabled
 local columns=touch and (size.X<size.Y and 1 or 2) or 1
 local rows=math.ceil(#KEYS/columns)
 dock.Size=touch and UDim2.fromOffset(columns==1 and 104 or 216,rows*58-6) or UDim2.fromOffset(220,#KEYS*60-14)
 if touch then
  local jumpTop=TouchLayout.GetJumpBounds()
  local availableHeight=jumpTop and jumpTop.Y-20 or size.Y-24
  local scale=math.min(1,math.max(44/52,availableHeight/(rows*58-6)))
  dockScale.Scale=scale
  local halfHeight=(rows*58-6)*scale/2
  local centerY=size.Y*(columns==1 and .4 or .46)
  if jumpTop then centerY=math.min(centerY,jumpTop.Y-12-halfHeight) end
  dock.Position=UDim2.new(1,-16,0,math.max(8+halfHeight,centerY))
 else
  dock.Position=UDim2.new(.97,0,.5,0)
  dockScale.Scale=math.min(1,math.max(.3,(size.X-48)/620),math.max(.3,(size.Y-180)/200))
 end
 for i,key in ipairs(KEYS) do
  local slot=slots[key]
  slot.Button.Position=touch and UDim2.fromOffset(((i-1)%columns)*112,math.floor((i-1)/columns)*58) or UDim2.fromOffset(0,(i-1)*60)
  slot.Button.Size=touch and UDim2.fromOffset(104,52) or UDim2.fromOffset(220,46)
  slot.Button.KeyBox.Size=touch and UDim2.fromOffset(25,52) or UDim2.fromOffset(42,46)
  slot.Button.KeyBox.Key.TextSize=touch and 18 or (key=="M1" and 21 or 27)
  slot.Title.Position=UDim2.fromOffset(touch and 30 or 49,0)
  slot.Title.Size=UDim2.new(1,touch and -33 or -49,0,31)
  slot.Title.TextSize=touch and 15 or 23
  slot.Timer.Position=UDim2.fromOffset(touch and 30 or 49,31)
  slot.Timer.Size=UDim2.new(1,touch and -33 or -49,0,18)
  slot.Timer.TextSize=touch and 11 or 14
 end
end
hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
TouchLayout.Changed:Connect(layout)
layout()
local function statusGroup(debuff)
  local dock = player.PlayerGui:FindFirstChild("PlayerStatusDock", true)
  local list = dock and dock:FindFirstChild("EffectList")
  return list and list:FindFirstChild(debuff and "Debuffs" or "Buffs")
end
local chips = {}
local function chip(id)
  local existing = chips[id]
  if existing and existing.Frame.Parent then
    return existing
  end
  local def = ClassConfig.Statuses[id]
  local debuff = def and def.Kind == "debuff"
  local group = statusGroup(debuff)
  if not group then
    return nil
  end
  local frame = Instance.new("Frame")
  frame.Name = "Class" .. id
  frame.Size = UDim2.fromOffset(260, 34)
  frame.LayoutOrder = 500
  frame.BackgroundColor3 = Color3.fromRGB(9, 9, 9)
  frame.BackgroundTransparency = 0.25
  frame.BorderSizePixel = 0
  frame.Parent = group
  border(frame, debuff and Color3.fromRGB(72, 43, 32) or Color3.fromRGB(65, 58, 30))
  pcall(Descriptions.CreateIcon, frame, "Class" .. id, UDim2.fromOffset(23, 23), UDim2.fromOffset(5, 5),
    debuff and Color3.fromRGB(241, 167, 130) or Color3.fromRGB(255, 222, 100))
  local title = hudLabel("Title", frame, UDim2.new(1, -105, 1, 0), UDim2.fromOffset(30, 0), def and def.Name or id)
  title.TextSize = 20
  title.TextXAlignment = Enum.TextXAlignment.Left
  title.TextTruncate = Enum.TextTruncate.AtEnd
  local timer = hudLabel("Countdown", frame, UDim2.fromOffset(60, 34), UDim2.new(1, -65, 0, 0), "")
  timer.TextSize = 18
  pcall(Descriptions.AttachTooltip,frame,"Class"..id,function()
   local c=player.Character
   if id=="DefenseBoost" and c and c:GetAttribute("ClassId")=="Mage" then
    return {Description=string.format("Orb Ward grants +%.0f%% defense. Your total defense is %.0f%%, capped at 99%%. Each Orb Dash refreshes the duration.",
     (c:GetAttribute("MageWardDefense") or 0)*100,(c:GetAttribute("ClassDefense") or 0)*100),
     Detail=string.format("%.1fs remaining",math.max(0,(c:GetAttribute("ClassStatus_DefenseBoost") or 0)-now()))}
   end
   local modifier=c and c:GetAttribute("ClassStatusModifier_"..id)
   if type(modifier)=="number" then
    local statNames={DamageBoost="Attack damage",AttackDebuff="Attack damage",DefenseBoost="Defense",SpeedBoost="Movement speed",Slow="Movement speed",
     StaminaRegen="Stamina regeneration",StaminaRegenBlock="Stamina regeneration",HPRegen="Health regeneration",AttackSpeedBoost="Basic attack speed"}
    local name=statNames[id] or "Stat"
    local percentage=id=="DefenseBoost" and modifier*100 or (modifier-1)*100
    local description=id=="DefenseBoost" and string.format("%s is increased by %.0f percentage points. Total defense: %.0f%%.",name,percentage,(c:GetAttribute("ClassDefense") or 0)*100)
     or string.format("%s is %s by %.0f%%.",name,percentage>=0 and "increased" or "reduced",math.abs(percentage))
    if id=="DefenseBoost" and c:GetAttribute("ClassId")=="Tank" then description..=string.format(" Tank defense caps at %.0f%%.",ClassConfig.Classes.Tank.DefenseCap*100) end
    local deadline=c:GetAttribute("ClassStatus_"..id) or -1
    return {Description=description,Detail=deadline==-1 and "Active while held" or string.format("%.1fs remaining",math.max(0,deadline-now()))}
   end
  end)
  chips[id] = { Frame = frame, Time = timer, Group = group }
  return chips[id]
end
 
local shieldLine
local function updateShieldLine(c)
  local vitals = player.PlayerGui:FindFirstChild("PlayerVitalsHUD")
  local bar = vitals and vitals:FindFirstChild("Panel") and vitals.Panel:FindFirstChild("Health")
  if not bar then
    return
  end
  if not shieldLine or shieldLine.Parent ~= bar then
    shieldLine = Instance.new("Frame")
    shieldLine.Name = "ClassShieldLine"
    shieldLine.AnchorPoint = Vector2.new(0, 0)
    shieldLine.Position = UDim2.new(0, 0, 1, 2)
    shieldLine.BackgroundColor3 = Color3.new(1, 1, 1)
    shieldLine.BorderSizePixel = 0
    shieldLine.ZIndex = 10
    shieldLine.Parent = bar
  end
  local h = c:FindFirstChildOfClass("Humanoid")
  local shield = c:GetAttribute("ClassShieldHP") or 0
  local fraction = h and h.MaxHealth > 0 and math.clamp(shield / h.MaxHealth, 0, 1) or 0
  shieldLine.Visible = shield > 0
  shieldLine.Size = UDim2.new(fraction, 0, 0, 4)
end

local function slotTitle(def, key, c)
  if key == "Q" then
    return "Dash"
  elseif key == "R" then
    if def.Name == "True Warrior" and c and c:GetAttribute("TWHidden_R") then
      return "Holy Counter"
    end
    return def.R and def.R.Name or (def.Name == "Warrior" and "Aegis Guard" or "Block")
  end
  local ability = def[key]
  if not ability then
    return ""
  end
  if def.Name == "True Warrior" and c then
    if key == "C" and c:GetAttribute("TWHidden_C") then return "Supreme King Slash" end
    if key == "F" and c:GetAttribute("TWHidden_F") then return "The Truth" end
    if key == "V" and c:GetAttribute("TrueWarriorChain") then return "Last Stand " .. ({ "II", "III" })[c:GetAttribute("TrueWarriorChain")] end
  end
  if def.Name == "Warrior" and (key == "C" or key == "V") then
    local offensive = (c and c:GetAttribute("ClassMode") or "Offensive") == "Offensive"
    if key == "C" then
      return offensive and "X-Slash" or "Shield Charge"
    end
    return offensive and "Conclusion" or "Aegis Burst"
  end
  return ability.Name
end

local hudElapsed=0
local statusCharacter, statusConnection
local classStatuses = {}
local function bindStatusCharacter(char)
 if statusConnection then statusConnection:Disconnect(); statusConnection=nil end
 statusCharacter=char
 table.clear(classStatuses)
 if not char then return end
 local function changed(name)
  local id=name:match("^ClassStatus_(.+)$")
  if id then classStatuses[id]=char:GetAttribute(name) end
 end
 for name in pairs(char:GetAttributes()) do changed(name) end
 statusConnection=char.AttributeChanged:Connect(changed)
end
local hudConnection=Run.Heartbeat:Connect(function(dt)
 hudElapsed+=dt
 if hudElapsed<0.1 then return end
 hudElapsed=0
  local c = character()
  if c~=statusCharacter then bindStatusCharacter(c) end
  local def = classOf()
  hud.Enabled=c~=nil and c:GetAttribute("ClassId")~=nil and workspace:GetAttribute("BossEncounterWon")~=true and player:GetAttribute("ChainBreakActive")~=true
   and workspace:GetAttribute("ClassShowroom")~=true  -- the lobby's showroom has its own panel
  if not hud.Enabled then
    releaseHudInputs()
    for id,ch in pairs(chips) do ch.Frame:Destroy(); chips[id]=nil end
    return
  end
  local t = now()
  for _, key in ipairs(KEYS) do
    local s = slots[key]
    s.Title.Text = slotTitle(def, key, c)
    local text, ready = "Ready", true
    if key == "Q" then
      local cost = c:GetAttribute("ClassDashCost") or 10
      local stamina = c:GetAttribute("Stamina") or 0
      ready = stamina >= cost
      text = string.format("%d stamina", cost)
    elseif key == "R" then
      local remaining=math.max(0,(c:GetAttribute("ClassCD_R") or 0)-t)
      ready=remaining<=0
      text=c:GetAttribute("ClassStatus_Blocking") and "Blocking" or c:GetAttribute("ClassStatus_CounterStance") and "Countering" or remaining>0 and string.format("Cooldown · %.1fs",remaining) or (def.R and "Tap" or "Hold")
    else
      local remaining=math.max(0,(c:GetAttribute("ClassCD_"..key) or 0)-t)
      if def.Name=="Mage" and key=="F" and (c:GetAttribute("MageNearbyOrbs") or 0)>=def.F.OrbCost then
       remaining=math.max(0,(c:GetAttribute("MageOrbDashReadyAt") or 0)-t)
      end
      local stolen = math.max(0, (c:GetAttribute("ClassSealed_" .. key) or 0) - t)
      if stolen > 0 then
        ready = false
        text = string.format("Stolen \u{00B7} %.1fs", stolen)
      elseif remaining > 0 then
        ready = false
        text = string.format("Cooldown \u{00B7} %.1fs", remaining)
      elseif def.Name == "Mage" and key == "F" then
        text = string.format("Ready \u{00B7} %d/%d orbs", c:GetAttribute("MageNearbyOrbs") or 0, def.F.OrbCost)
      elseif def.Name == "Gambler" and key == "M1" and c:GetAttribute("ClassStatus_TrustedGun") then
        text=string.format("%d/%d rounds",c:GetAttribute("GamblerTrustedAmmo") or 0,def.C.Ammo)
      end
    end
    s.Timer.Text = text
    s.Button.BackgroundColor3 = ready and Color3.fromRGB(62, 64, 66) or Color3.fromRGB(44, 45, 47)
    s.Title.TextTransparency = ready and 0 or 0.35
  end
  updateShieldLine(c)
  
   
  local seen = {}
  for id, value in pairs(classStatuses) do
    if value then
      seen[id] = true
      local ch = chip(id)
      if ch then
        local custom = c:GetAttribute("ClassStatusText_" .. id)
        if id=="DefenseBoost" and def.Name=="Mage" then custom=nil end
        ch.Time.Text = custom or (value == -1 and "" or string.format("%.1fs", math.max(0, value - t)))
        ch.Group.Visible = true
        local dock = ch.Group:FindFirstAncestor("PlayerStatusDock")
        if dock then
          dock.Visible = true
        end
      end
    end
  end
  for id, ch in pairs(chips) do
    if not seen[id] then
      ch.Frame:Destroy()
      chips[id] = nil
    end
  end
end)
script.Destroying:Connect(function()
 inputLoopAlive=false
 releaseHeld()
 hudConnection:Disconnect()
 bindStatusCharacter(nil)
end)

local function hideOldButton(d)
 if d:IsA("GuiObject") and d.Name=="DashButton" then d.Visible=false end
end
for _,d in player.PlayerGui:GetDescendants() do hideOldButton(d) end
player.PlayerGui.DescendantAdded:Connect(hideOldButton)

 
local Kit = require(game.ReplicatedStorage.BossShared.Presentation.TrialMenuKit)
local KC, KF = Kit.Colors, Kit.Fonts
local menuScreen = Kit.Screen("ClassMenu", player.PlayerGui)
local menu, mstage, resize = menuScreen.Gui, menuScreen.Stage, menuScreen.Resize
local msub = Kit.Header(mstage, "The Golden Armory", "Choose Your Class")
msub.Text = "Your own choice. A class never changes with the difficulty."
local close = Kit.Close(mstage)
local cards, preview = {}, nil
local showDetail
local classCount = #ClassConfig.Order
local CGAP = classCount > 6 and 8 or 12
local CPW = math.min(148, math.floor((Kit.W - 40 - (classCount - 1) * CGAP) / classCount))
local cx0 = (Kit.W - (classCount * CPW + (classCount - 1) * CGAP)) / 2
local Unlocks = require(game.ReplicatedStorage.BossShared.Classes.ClassUnlocks)
local cardTitles = {
  Duelist = "THE RIPOSTE",
  Twinblade = "DUAL FURY",
  Disorderer = "REALITY BREAKER",
  TrueWarrior = "THE CHAMPION",
}
local function unlockState(id)
  if not Unlocks[id] then return "open" end
  local v = player:GetAttribute("ClassUnlocked_" .. id)
  if v == true then return "open" elseif v == false then return "locked" end
  return "pending"
end
local maxHP, maxSTA, maxSPD = 1, 1, 1
for _, id in ipairs(ClassConfig.Order) do
  local d = ClassConfig.Classes[id]
  maxHP, maxSTA, maxSPD = math.max(maxHP, d.HP), math.max(maxSTA, d.Stamina), math.max(maxSPD, d.Speed)
end
local function currentClass()
  return player:GetAttribute("PlayerClass") or ClassConfig.Default
end
local leaveToken = 0
local function leaveLocked(id)
  leaveToken += 1
  local token = leaveToken
  task.delay(0.4, function()
    if token == leaveToken and preview == id then
      preview = nil
      showDetail(currentClass())
    end
  end)
end
for i, id in ipairs(ClassConfig.Order) do
  local def = ClassConfig.Classes[id]
  local plate = Kit.Plate(mstage, {
    Id = id, Glyph = def.Name:sub(1, 1), Name = def.Short or def.Name, NameSize = classCount > 6 and 15 or 16, Color = def.Color,
    Note = cardTitles[id] or def.Passive.Name,
    Position = UDim2.fromOffset(cx0 + (i - 1) * (CPW + CGAP), 146), Size = UDim2.fromOffset(CPW, 164),
  })
  local okLogo = pcall(function()
    local Icons = require(game.ReplicatedStorage.BossShared.Presentation.StatusIcons)
    Icons.Create(plate.Button, "Logo" .. id, UDim2.fromOffset(56, 56), UDim2.fromOffset((CPW - 56) / 2, 31), def.Color)
  end)
  if okLogo then plate.Glyph.Text = "" end
  cards[id] = plate
  local overlay = Instance.new("Frame")
  overlay.Name = "LockOverlay"
  overlay.Size = UDim2.fromScale(1, 1)
  overlay.BackgroundColor3 = Color3.new(0, 0, 0)
  overlay.BackgroundTransparency = 0.45
  overlay.BorderSizePixel = 0
  overlay.ZIndex = 20
  overlay.Visible = false
  overlay.Parent = plate.Button
  local lockText = Instance.new("TextLabel")
  lockText.BackgroundTransparency = 1
  lockText.Size = UDim2.fromScale(1, 0.18)
  lockText.Position = UDim2.fromScale(0, 0.04)
  lockText.Font = Enum.Font.Garamond
  lockText.Text = "LOCKED"
  lockText.TextSize = 15
  lockText.TextColor3 = Color3.fromRGB(235, 215, 150)
  lockText.ZIndex = 21
  lockText.Parent = overlay
  plate.LockOverlay = overlay
  overlay.Interactable = false  -- the padlock veil never takes the cursor away from the card under it
  plate.Button.MouseEnter:Connect(function()
    leaveToken += 1
    preview = id
    showDetail(id)
  end)
  plate.Button.MouseLeave:Connect(function()
    if preview ~= id then return end
    if unlockState(id) ~= "open" then
      leaveLocked(id)
    else
      preview = nil
      showDetail(currentClass())
    end
  end)
  plate.Button.Activated:Connect(function()
    preview = id
    showDetail(id)
    remote:FireServer("Select", id)
  end)
end

local SW, SGAP = 212, 20
local sx0 = (Kit.W - (4 * SW + 3 * SGAP)) / 2
local hpGauge = Kit.Gauge(mstage, UDim2.fromOffset(sx0, 330), SW, "Health")
local staGauge = Kit.Gauge(mstage, UDim2.fromOffset(sx0 + (SW + SGAP), 330), SW, "Stamina")
local spdGauge = Kit.Gauge(mstage, UDim2.fromOffset(sx0 + 2 * (SW + SGAP), 330), SW, "Speed")
local defGauge = Kit.Gauge(mstage, UDim2.fromOffset(sx0 + 3 * (SW + SGAP), 330), SW, "Defense")

local DY = 380
local cname = Kit.Text(mstage, { FontFace = KF.Title, TextSize = 30, Position = UDim2.fromOffset(50, DY), Size = UDim2.fromOffset(360, 34) })
local tagline = Kit.Text(mstage, { FontFace = KF.Italic, TextSize = 16, Position = UDim2.fromOffset(50, DY + 38), Size = UDim2.fromOffset(360, 62) })
local passiveTitle = Kit.Text(mstage, { FontFace = KF.Caps, TextSize = 12, Position = UDim2.fromOffset(50, DY + 108), Size = UDim2.fromOffset(360, 16) })
local passiveText = Kit.Text(mstage, { FontFace = KF.Body, TextSize = 15, TextColor3 = KC.Muted, Position = UDim2.fromOffset(50, DY + 128), Size = UDim2.fromOffset(360, 84) })
Kit.Frame(mstage, { Position = UDim2.fromOffset(432, DY + 4), Size = UDim2.fromOffset(1, 200), BackgroundTransparency = 0.6, BackgroundColor3 = KC.GoldDim })
local abilityList = Kit.Frame(mstage, { Position = UDim2.fromOffset(460, DY), Size = UDim2.fromOffset(490, 210) })
local abilityFlow = Instance.new("UIListLayout")
abilityFlow.Padding = UDim.new(0, 7)
abilityFlow.SortOrder = Enum.SortOrder.LayoutOrder
abilityFlow.Parent = abilityList
local abilityRows = {}
for index, key in ipairs({ "M1", "F", "C", "V" }) do
  local row = Kit.Frame(abilityList, { LayoutOrder = index, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
  local badge = Kit.Frame(row, { Position = UDim2.fromOffset(0, 1), Size = UDim2.fromOffset(34, 24), BackgroundTransparency = 0, BackgroundColor3 = KC.Plate })
  local stroke = Instance.new("UIStroke")
  stroke.Parent = badge
  Kit.Text(badge, { Text = key, FontFace = KF.Caps, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1) })
  local title = Kit.Text(row, { FontFace = KF.Caps, TextSize = 15, Position = UDim2.fromOffset(46, 0), Size = UDim2.fromOffset(330, 18) })
  local cooldown = Kit.Text(row, { FontFace = KF.Italic, TextSize = 14, TextColor3 = KC.Muted, TextXAlignment = Enum.TextXAlignment.Right,
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(110, 18) })
  local text = Kit.Text(row, { FontFace = KF.Body, TextSize = 13, TextColor3 = KC.Muted, Position = UDim2.fromOffset(46, 18),
    Size = UDim2.new(1, -46, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
  abilityRows[key] = { Stroke = stroke, Title = title, Cooldown = cooldown, Text = text }
end

local status = Kit.Text(mstage, { FontFace = KF.Italic, TextSize = 16, TextColor3 = KC.Gold, TextXAlignment = Enum.TextXAlignment.Center,
  AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 594), Size = UDim2.fromOffset(820, 20) })

showDetail = function(id)
  local def = ClassConfig.Get(id)
  cname.Text = def.Name
  cname.TextColor3 = def.Color
  tagline.Text = def.Tagline
  passiveTitle.Text = Kit.Spaced("Passive") .. "   ·   " .. def.Passive.Name
  passiveTitle.TextColor3 = def.Color
  passiveText.Text = def.Passive.Text
  hpGauge(def.HP / maxHP, tostring(def.HP), def.Color)
  staGauge(def.Stamina / maxSTA, string.format("%d  ·  dash %d", def.Stamina, def.DashCost), def.Color)
  spdGauge(def.Speed / maxSPD, tostring(def.Speed), def.Color)
  local defense = def.BaseDefense or 0
  defGauge(defense / 0.2, defense > 0 and string.format("%d%%", defense * 100) or "none", def.Color)
  for key, row in pairs(abilityRows) do
    local a = def[key]
    row.Stroke.Color = def.Color
    row.Title.Text = a.Name
    row.Cooldown.Text = a.Cooldown and a.Cooldown >= 1 and (a.Cooldown .. " s") or ""
    row.Text.Text = a.Text
  end
end
local buyButton = Instance.new("TextButton")
buyButton.Name = "BuyButton"
buyButton.Visible = false
buyButton.AnchorPoint = Vector2.new(1, 0)
buyButton.Position = UDim2.fromOffset(Kit.W - 40, 586)
buyButton.Size = UDim2.fromOffset(190, 30)
buyButton.BackgroundColor3 = Color3.fromRGB(70, 150, 90)
buyButton.BorderSizePixel = 0
buyButton.Font = Enum.Font.Garamond
buyButton.TextSize = 20
buyButton.TextColor3 = Color3.new(1, 1, 1)
buyButton.Text = "Buy"
buyButton.Parent = mstage
buyButton.Activated:Connect(function()
  local id = buyButton:GetAttribute("ForClass")
  if id then remote:FireServer("Buy", id) end
end)
buyButton.MouseEnter:Connect(function() leaveToken += 1 end)
buyButton.MouseLeave:Connect(function()
  local id = buyButton:GetAttribute("ForClass")
  if id then leaveLocked(id) end
end)
local lockedHint
local baseShowDetail = showDetail
showDetail = function(id)
  baseShowDetail(id)
  if id == "TrueWarrior" and (player:GetAttribute("ChampionUnlocked") == true or workspace:GetAttribute("ForceChampion") == true) then
    cname.Text = ClassConfig.Classes.TrueWarrior.ChampionName
  end
  local entry = Unlocks[id]
  local state = unlockState(id)
  if entry and state ~= "open" then
    status.Text = state == "pending" and "Checking your unlocks..." or entry.Hint
    lockedHint = status.Text
    local pass = entry.Kind == "GamePass" and state == "locked"
    buyButton.Visible = pass
    buyButton.Text = (entry.Id or 0) > 0 and ("Buy  -  " .. tostring(entry.Price or "") .. " Robux") or "Coming soon"
    buyButton:SetAttribute("ForClass", id)
  else
    buyButton.Visible = false
    if lockedHint and status.Text == lockedHint then status.Text = "" end
    lockedHint = nil
  end
end
local function refreshMenu()
  local current = currentClass()
  local locked = workspace:GetAttribute("EncounterStarted") == true
  for id, plate in pairs(cards) do
    plate:Set(id == current, id == current and (locked and "Sealed" or "Chosen") or nil)
    if plate.LockOverlay then plate.LockOverlay.Visible = unlockState(id) ~= "open" end
  end
  showDetail(preview or current)
end
player.AttributeChanged:Connect(function(name)
  if name:sub(1, 14) == "ClassUnlocked_" then refreshMenu() end
end)
local function hideMenu()
  menu.Enabled = false
end
menuScreen.Backdrop.Activated:Connect(hideMenu)
close.Activated:Connect(hideMenu)
UIS.InputBegan:Connect(function(input, processed)
  if not processed and input.KeyCode == Enum.KeyCode.Escape then
    hideMenu()
  end
end)
player:GetAttributeChangedSignal("PlayerClass"):Connect(refreshMenu)
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
  refreshMenu()
  if workspace:GetAttribute("EncounterStarted") then
    hideMenu()
  end
end)

remote.OnClientEvent:Connect(function(kind, data)
  if kind == "Open" then
    preview = nil
    status.Text = ""
    refreshMenu()
    resize()
    menu.Enabled = true
  elseif kind == "Result" then
    status.Text = data and data.Message or ""
    refreshMenu()
  elseif kind == "Move" then
    startMove(data)
  elseif kind == "Leap" then
    local c = character()
    if c and data and typeof(data.Velocity) == "Vector3" and not controlLocked(c) then
      local hum = c:FindFirstChildOfClass("Humanoid")
      local root = c:FindFirstChild("HumanoidRootPart")
      if hum and root then
        if data.Velocity.Y > 0 then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
        root.AssemblyLinearVelocity = data.Velocity
      end
    end
  elseif kind == "MoveStop" then
    stopMove()
  elseif kind == "LaserStart" then
    lasering = true
    task.delay((data and data.Duration or 5) + 0.5, function()
      lasering = false
    end)
  elseif kind == "TwinStorm" then
    twinStorm(data)
  elseif kind == "TwinPath" then
    startTwinPath(data)
  elseif kind == "Blink" then
    startBlink(data)
  elseif kind == "Cinema" then
    if (data and data.Mode == "End") or player:GetAttribute("DisableSkillCutscenes") ~= true then cinema(data) end
  elseif kind == "Waltz" then
     
    task.spawn(function()
      local c = character()
      if not c or typeof(data.Boss) ~= "Instance" or not data.Boss:FindFirstChild("HumanoidRootPart") then
        return
      end
      if controlLocked(c) then
        return
      end
      local revision = c:GetAttribute("ClassActionRevision") or 0
      stopMove()
      for _, step in ipairs(data.Steps or {}) do
        local remaining = (data.Start or now()) + step.T - now()
        if remaining > 0 then
          task.wait(remaining)
        end
        if not c.Parent or not data.Boss.Parent or controlLocked(c)
          or (c:GetAttribute("ClassActionRevision") or 0) ~= revision then
          break
        end
        local center = data.Boss.HumanoidRootPart.Position
        local root = c.HumanoidRootPart
        local y = root.Position.Y
        local pos = center + Vector3.new(math.cos(step.Angle) * step.Radius, 0, math.sin(step.Angle) * step.Radius)
        root.CFrame = CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(center.X, y, center.Z))
        root.AssemblyLinearVelocity = Vector3.zero
      end
    end)
  elseif kind == "LaserEnd" then
    lasering = false
  end
end)

bindAll()
player.CharacterAdded:Connect(function()
  stopMove()
  endCinema()
  task.delay(1, bindAll)
end)
task.delay(2, bindAll)

local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local template =
  game.ServerStorage:WaitForChild("BossEncounter"):WaitForChild("Templates"):WaitForChild("alterGolden, the Nothing")
local remote = game.ReplicatedStorage:WaitForChild("BossCombatEffects")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Classes = require(Shared.Classes.ClassConfig)
local BattleScaling=require(Shared.Config.BattleScaling)
local DamageTracker=require(BossSystem.Combat.DamageTracker)
DamageTracker.Start()
local Story = require(BossSystem.Encounter.EncounterStory)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local DifficultyService = require(BossSystem.Encounter.DifficultyService)
local Arena = require(BossSystem.Encounter.ArenaController)
local scene = Arena.Ensure()
local started = false
local actor
local connections, playerConnections = {}, {}

local GOLD = Color3.fromRGB(255, 201, 20)
local PALE = Color3.fromRGB(255, 244, 146)
local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local FLAT = CFrame.Angles(0, 0, math.rad(90))
local vfxFolder, buildUp

local function safe(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    warn("Boss entrance VFX: " .. tostring(err))
  end
end
local function vfxParent()
  if not vfxFolder or not vfxFolder.Parent then
    vfxFolder = Instance.new("Folder")
    vfxFolder.Name = "BossEntranceVFX"
    vfxFolder.Parent = workspace
  end
  return vfxFolder
end
local function clearVFX()
  if vfxFolder then
    vfxFolder:Destroy()
    vfxFolder = nil
  end
  buildUp = nil
end
local function tween(inst, time, props, style, direction)
  local t = TweenService:Create(
    inst,
    TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
    props
  )
  t:Play()
  return t
end
local function lifetime(inst, seconds)
  Debris:AddItem(inst, seconds)
end
local function newPart(name, size, cframe, shape)
  local p = Instance.new("Part")
  p.Name = name
  p.Anchored = true
  p.CanCollide = false
  p.CanQuery = false
  p.CanTouch = false
  p.CastShadow = false
  p.Material = Enum.Material.Neon
  p.Color = GOLD
  if shape then
    p.Shape = shape
  end
  p.Size = size
  p.CFrame = cframe
  p.Parent = vfxParent()
  return p
end
local function emitterHost(name, size, position)
  local p = newPart(name, size, CFrame.new(position))
  p.Transparency = 1
  return p
end
local function disc(center, diameter, thickness)
  return newPart(
    "Disc",
    Vector3.new(thickness, diameter, diameter),
    CFrame.new(center) * FLAT,
    Enum.PartType.Cylinder
  )
end
local function ring(center, startRadius, endRadius, duration, height)
  local segments = 24
  local function chord(r)
    return math.max(2 * math.pi * r / segments * 1.2, 0.5)
  end
  for i = 1, segments do
    local angle = i / segments * math.pi * 2
    local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local function pose(r)
      local p = center + dir * r
      return CFrame.lookAt(p, p + dir)
    end
    local seg = newPart("RingSegment", Vector3.new(chord(startRadius), height, 1.4), pose(startRadius))
    seg.Transparency = 0.05
    tween(
      seg,
      duration,
      { CFrame = pose(endRadius), Size = Vector3.new(chord(endRadius), height * 0.35, 0.6), Transparency = 1 },
      Enum.EasingStyle.Quart
    )
    lifetime(seg, duration + 0.3)
  end
end
local function pillar(center, height, width, duration, startTransparency)
  local p = newPart(
    "LightPillar",
    Vector3.new(height, width, width),
    CFrame.new(center + Vector3.new(0, height * 0.5, 0)) * FLAT,
    Enum.PartType.Cylinder
  )
  p.Transparency = startTransparency
  tween(
    p,
    duration,
    { Size = Vector3.new(height, width * 0.08, width * 0.08), Transparency = 1 },
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.In
  )
  lifetime(p, duration + 0.2)
end
local function flash(position, range, brightness, duration)
  local host = emitterHost("FlashHost", Vector3.one, position)
  local light = Instance.new("PointLight")
  light.Color = PALE
  light.Range = math.min(range, 60)
  light.Brightness = brightness
  light.Shadows = false
  light.Parent = host
  tween(light, duration, { Brightness = 0, Range = math.min(range, 60) * 0.4 })
  lifetime(host, duration + 0.2)
end

local function startBuildUp(center)
  if buildUp then
    return buildUp
  end
  local b = {}
  b.Field = emitterHost("BuildUpField", Vector3.new(20, 20, 20), center + Vector3.new(0, 5, 0))
  local motes = Instance.new("ParticleEmitter")
  motes.Texture = SPARK_TEXTURE
  motes.Color = ColorSequence.new(PALE, GOLD)
  motes.LightEmission = 1
  motes.Shape = Enum.ParticleEmitterShape.Sphere
  motes.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
  motes.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
  motes.Lifetime = NumberRange.new(1.2, 1.6)
  motes.Speed = NumberRange.new(6, 8)
  motes.Rate = 0
  motes.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.25, 0.45),
    NumberSequenceKeypoint.new(1, 0),
  })
  motes.Parent = b.Field
  b.Motes = motes

  b.Core = emitterHost("BuildUpCore", Vector3.new(8, 0.4, 8), center + Vector3.new(0, 0.3, 0))
  local embers = Instance.new("ParticleEmitter")
  embers.Texture = SPARK_TEXTURE
  embers.Color = ColorSequence.new(GOLD)
  embers.LightEmission = 0.8
  embers.Lifetime = NumberRange.new(1.8, 3)
  embers.Speed = NumberRange.new(2, 5)
  embers.SpreadAngle = Vector2.new(25, 25)
  embers.EmissionDirection = Enum.NormalId.Top
  embers.Acceleration = Vector3.new(0, 5, 0)
  embers.Rate = 0
  embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
  embers.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
  embers.Parent = b.Core
  b.Embers = embers

  local light = Instance.new("PointLight")
  light.Color = GOLD
  light.Range = 30
  light.Brightness = 0
  light.Shadows = false
  light.Parent = b.Core
  b.Light = light

  b.Glow = disc(center + Vector3.new(0, 0.06, 0), 16, 0.2)
  b.Glow.Transparency = 1
  buildUp = b
  return b
end
local function updateBuildUp(center, progress)
  local b = startBuildUp(center)
  progress = math.clamp(progress, 0, 1)
  b.Motes.Rate = 20 + progress * 90
  b.Embers.Rate = 8 + progress * 35
  tween(b.Light, 1, { Brightness = 1 + progress * 5 })
  local d = 18 + progress * 12
  tween(b.Glow, 1, { Transparency = 0.88 - progress * 0.38, Size = Vector3.new(0.2, d, d) })
end

local function arrivalVFX(center, boss)
  if buildUp then
    local b = buildUp
    buildUp = nil
    b.Motes.Enabled = false
    b.Embers.Enabled = false
    tween(b.Light, 0.4, { Brightness = 0 })
    tween(b.Glow, 0.6, { Transparency = 1 })
    lifetime(b.Field, 3)
    lifetime(b.Core, 3)
    lifetime(b.Glow, 1)
  end

  flash(center + Vector3.new(0, 5, 0), 60, 14, 0.9)

  local pulse = disc(center + Vector3.new(0, 0.08, 0), 8, 0.25)
  pulse.Transparency = 0.2
  tween(pulse, 0.6, { Size = Vector3.new(0.25, 80, 80), Transparency = 1 }, Enum.EasingStyle.Quart)
  lifetime(pulse, 0.8)

  for i = 0, 2 do
    task.delay(i * 0.14, function()
      safe(ring, center + Vector3.new(0, 0.3, 0), 3, 46 + i * 14, 0.9 + i * 0.2, 1.1)
    end)
  end

  pillar(center, 110, 10, 1.1, 0.15)
  pillar(center, 110, 22, 1.4, 0.65)

  local host = emitterHost("ArrivalBurst", Vector3.new(4, 1, 4), center + Vector3.new(0, 0.5, 0))

  local sparks = Instance.new("ParticleEmitter")
  sparks.Texture = SPARK_TEXTURE
  sparks.Color = ColorSequence.new(PALE, GOLD)
  sparks.LightEmission = 1
  sparks.Lifetime = NumberRange.new(0.7, 1.6)
  sparks.Speed = NumberRange.new(18, 45)
  sparks.SpreadAngle = Vector2.new(55, 55)
  sparks.EmissionDirection = Enum.NormalId.Top
  sparks.Acceleration = Vector3.new(0, -22, 0)
  sparks.Rate = 0
  sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
  sparks.Parent = host
  sparks:Emit(160)

  local radial = Instance.new("ParticleEmitter")
  radial.Texture = SPARK_TEXTURE
  radial.Color = ColorSequence.new(GOLD)
  radial.LightEmission = 1
  radial.Lifetime = NumberRange.new(0.5, 0.9)
  radial.Speed = NumberRange.new(30, 60)
  radial.SpreadAngle = Vector2.new(85, 85)
  radial.EmissionDirection = Enum.NormalId.Top
  radial.Rate = 0
  radial.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
  radial.Parent = host
  radial:Emit(120)

  local dust = Instance.new("ParticleEmitter")
  dust.Texture = SMOKE_TEXTURE
  dust.Color = ColorSequence.new(Color3.fromRGB(255, 236, 170), Color3.fromRGB(150, 130, 90))
  dust.LightEmission = 0.3
  dust.Lifetime = NumberRange.new(1.2, 2)
  dust.Speed = NumberRange.new(14, 26)
  dust.SpreadAngle = Vector2.new(85, 85)
  dust.EmissionDirection = Enum.NormalId.Top
  dust.Drag = 4
  dust.Rate = 0
  dust.Rotation = NumberRange.new(0, 360)
  dust.RotSpeed = NumberRange.new(-40, 40)
  dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 12) })
  dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
  dust.Parent = host
  dust:Emit(28)

  local embers = Instance.new("ParticleEmitter")
  embers.Texture = SPARK_TEXTURE
  embers.Color = ColorSequence.new(GOLD)
  embers.LightEmission = 0.8
  embers.Lifetime = NumberRange.new(2, 3.5)
  embers.Speed = NumberRange.new(3, 9)
  embers.SpreadAngle = Vector2.new(180, 180)
  embers.Acceleration = Vector3.new(0, 7, 0)
  embers.Rate = 45
  embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
  embers.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
  embers.Parent = host
  task.delay(1.6, function()
    embers.Enabled = false
  end)
  lifetime(host, 6)

  if boss and boss.Parent then
    local glow = Instance.new("Highlight")
    glow.Name = "EntranceGlow"
    glow.FillColor = GOLD
    glow.OutlineColor = PALE
    glow.FillTransparency = 0.15
    glow.OutlineTransparency = 0
    glow.DepthMode = Enum.HighlightDepthMode.Occluded
    glow.Adornee = boss
    glow.Parent = boss
    tween(glow, 1.6, { FillTransparency = 1, OutlineTransparency = 1 }, Enum.EasingStyle.Sine)
    lifetime(glow, 1.8)
  end
end

local function resetPresentation()
 BattleScaling.Reset()
  workspace:SetAttribute("EncounterStarted", false)
  workspace:SetAttribute("EncounterStartedAt", 0)
  workspace:SetAttribute("BossEncounterReady", false)
  workspace:SetAttribute("BossEncounterWon", false)
  workspace:SetAttribute("BossVictoryTitle", nil)
 workspace:SetAttribute("BossVictorySubtitle",nil)
 workspace:SetAttribute("BossVictoryDifficulty",nil)
  workspace:SetAttribute("BossDisplayTitle", "???")
  workspace:SetAttribute("BossIdentityRevealed", false)
  workspace:SetAttribute("BossEntranceStartedAt", 0)
  workspace:SetAttribute("BossEntranceEndsAt", 0)
  workspace:SetAttribute("BossEntranceText", nil)
end
resetPresentation()
Arena.Reset()
local function positionPlayer(player, char, battlefield)
  local root = char:WaitForChild("HumanoidRootPart", 10)
  local h = char:WaitForChild("Humanoid", 10)
  if not root or not h or h.Health <= 0 or player.Character ~= char or player.Parent ~= Players then
    return
  end
   
   
  battlefield = started
  local destination = Arena.SpawnFrame(char, battlefield)
  char:PivotTo(destination * root.CFrame:Inverse() * char:GetPivot())
  root.AssemblyLinearVelocity = Vector3.zero
  root.AssemblyAngularVelocity = Vector3.zero
end
local function spawnPoint(circle, y)
  return Vector3.new(circle:GetAttribute("SpawnX"), y, circle:GetAttribute("SpawnZ"))
end
local function bossCircleCenter()
  local pads = scene.Arena.SpawnCircles
  local floor = scene.Floor
  local groundY = (floor.CFrame * CFrame.new(0, floor.Size.Y * 0.5, 0)).Y
  return spawnPoint(pads.BossCircle, groundY + 0.15)
end
local function resetEncounter()
   
   
  workspace:SetAttribute("BossEntranceSequence", (workspace:GetAttribute("BossEntranceSequence") or 0) + 1)
  started = false
  clearVFX()
  local old = actor
  actor = nil
  if old and old.Parent then
    old:SetAttribute("EncounterEnded", true)
    old:SetAttribute("AIEnabled", false)
    old:SetAttribute("PhaseGeneration", (old:GetAttribute("PhaseGeneration") or 0) + 1)
    old:SetAttribute("MovementRevision", (old:GetAttribute("MovementRevision") or 0) + 1)
    require(BossSystem.Mechanics.Time.TimeEffectController).ClearOwner(old)
    require(BossSystem.Phases.PhaseController).ResetLighting(old)
    require(BossSystem.Combat.EffectService).CancelOwner(old, "Encounter reset")
    old:Destroy()
  end
  resetPresentation()
  DifficultyService.Unlock()
  Arena.Reset()
  for _, player in ipairs(Players:GetPlayers()) do
    require(BossSystem.Players.R6DashService).Cancel(player, "Encounter reset")
    require(BossSystem.Combat.StatusEffectService).Clear(player)
    player:SetAttribute("LivesRemaining", Encounter.StartingLives)
  player:SetAttribute("StartingLives",Encounter.StartingLives)
    player:SetAttribute("PermanentlyDefeated", false)
    player:SetAttribute("ExecutionPending", false)
    player:SetAttribute("DefeatReason", nil)
    local character = player.Character
    if not character then
      task.spawn(function()
        if player.Parent == Players and not player.Character then Encounter.LoadCharacter(player) end
      end)
    end
    if character then
      character:SetAttribute("LivesRemaining", Encounter.StartingLives)
      character:SetAttribute("PermanentlyDefeated", false)
      character:SetAttribute("ExecutionPending", false)
      local h = character:FindFirstChildOfClass("Humanoid")
      if h and h.Health <= 0 then
        local sequence = workspace:GetAttribute("BossEntranceSequence")
        task.spawn(function()
          if
            player.Parent == Players
            and player.Character == character
            and not started
            and workspace:GetAttribute("BossEntranceSequence") == sequence
          then
            Encounter.LoadCharacter(player, true)
          end
        end)
      else
        if h then
          h.Health = h.MaxHealth
        end
        local def = Classes.Classes[player:GetAttribute("PlayerClass")] or Classes.Classes[Classes.Default]
        character:SetAttribute("Stamina", character:GetAttribute("MaxStamina") or def.Stamina)
        task.spawn(positionPlayer, player, character, false)
      end
    end
  end
end
local function entrance(sequence)
  local function current()
    return script.Parent ~= nil
      and started
      and workspace:GetAttribute("EncounterStarted") == true
      and workspace:GetAttribute("BossEntranceSequence") == sequence
  end
  local skipEntrance = require(BossSystem.Development.InstantPhaseOverride).Selected() ~= nil
  if skipEntrance then
    local now = workspace:GetServerTimeNow()
    workspace:SetAttribute("BossEntranceStartedAt", now)
    workspace:SetAttribute("BossEntranceEndsAt", now)
    workspace:SetAttribute("BossEntranceText", nil)
    for _, player in ipairs(Players:GetPlayers()) do
      if not current() then return end
      local char = player.Character
      local root = char and char:FindFirstChild("HumanoidRootPart")
      if root and not Arena.Contains(root.Position, 3) then
        positionPlayer(player, char, true)
      end
    end
    Arena.SetSealed(true)
  else
    local begin = workspace:GetServerTimeNow()
    workspace:SetAttribute("BossEntranceStartedAt", begin)
    workspace:SetAttribute("BossEntranceEndsAt", begin + Story.Duration(Story.Beginning))
    workspace:SetAttribute("BossEntranceText", Story.Beginning[1])
    remote:FireAllClients("Entrance", { EndsAt = workspace:GetAttribute("BossEntranceEndsAt"), Sequence = sequence })
  
    local buildCenter
    do
      local ok, result = pcall(bossCircleCenter)
      if ok then
        buildCenter = result
      end
    end
    local function buildUpStep(index)
      if not buildCenter or not current() then
        return
      end
      local progress = math.clamp(index / math.max(#Story.Beginning, 1), 0, 1)
      safe(updateBuildUp, buildCenter, progress)
      remote:FireAllClients("EntranceBuildUp", { Progress = progress, Sequence = sequence, Position = buildCenter })
    end
    buildUpStep(1)
  
    if
      not Story.Play(nil, Story.Beginning, {
        Valid = current,
        OnLine = function(text, index)
          workspace:SetAttribute("BossEntranceText", text)
          buildUpStep(index)
           
           
          if index == #Story.Beginning then
            for _, player in ipairs(Players:GetPlayers()) do
              if not current() then
                break
              end
              local char = player.Character
              local root = char and char:FindFirstChild("HumanoidRootPart")
              if root and not Arena.Contains(root.Position, 3) then
                positionPlayer(player, char, true)
              end
            end
            if current() then
              Arena.SetSealed(true)
            end
          end
        end,
      }) or not current()
    then
      return
    end
  end
  if not current() then return end
  workspace:SetAttribute("BossEntranceEndsAt", workspace:GetServerTimeNow())
  workspace:SetAttribute("BossEntranceText", nil)  -- the entrance is over (the P5 TP guide waits on this)
  local boss = template:Clone()
  boss:SetAttribute("EncounterDifficulty", workspace:GetAttribute("ActiveDifficulty"))
  local root = boss.HumanoidRootPart
  local h = boss.Humanoid
  h.BreakJointsOnDeath = false
  h.RequiresNeck = false
  h.MaxHealth = Config.BossMaxHealth
  h.Health = h.MaxHealth
  boss:SetAttribute("BossHealth", h.Health)
  boss:SetAttribute("Shield", Config.ShieldMaxHealth)
  boss:SetAttribute("MaxShield", Config.ShieldMaxHealth)
  boss:SetAttribute("Defense", 0)
  boss:SetAttribute("Phase", 1)
  boss:SetAttribute("EncounterEnded", false)
  for _, flag in ipairs({
    "ShieldBroken",
    "Phase15Triggered",
    "Phase15TransitionActive",
    "Phase2Triggered",
    "Phase25Triggered",
    "Phase3Triggered",
    "Phase4Triggered",
    "Phase4TransitionInProgress",
    "EtherealAcumenActive",
    "ShieldCloneGateActive",
    "Phase4ComboActive",
    "CircularBarrageGunHeld",
    "LastMinuteUsed",
    "LastMinuteActive",
    "ShieldDamageLocked",
    "FutureSightActive",
    "IdentityRevealed",
    "Invulnerable",
    "PhaseTransitionInProgress",
    "Phase25TransitionInProgress",
    "Phase3IntroActive",
    "ExecutionLocked",
    "ShieldBreakInProgress",
    "BossDefeatPresentationStarted",
  }) do
    boss:SetAttribute(flag, false)
  end
  boss:SetAttribute("FutureSightCharges", 0)
  boss:SetAttribute("FutureSightReadyAt", 0)
  boss:SetAttribute("PhaseTitleOverride", "???")
  boss:SetAttribute("PhaseGeneration", 0)
  boss:SetAttribute("MovementRevision", 0)
  local pads = scene.Arena.SpawnCircles
  local floor = scene.Floor
  local groundY = (floor.CFrame * CFrame.new(0, floor.Size.Y * 0.5, 0)).Y
  local y = groundY + h.HipHeight + root.Size.Y * 0.5 + 0.35
  local goal = CFrame.lookAt(spawnPoint(pads.BossCircle, y), spawnPoint(pads.PlayerCircle, y))
  boss:PivotTo(goal * root.CFrame:Inverse() * boss:GetPivot())
  boss:SetAttribute("AIEnabled", false)
  boss:SetAttribute("NextAttackAt", 0)
  boss:SetAttribute("ParryActive", false)
  boss:SetAttribute("AttackInProgress", false)
  boss:SetAttribute("AttackState", "Entrance")
  boss:SetAttribute("EncounterSpawnedAt", workspace:GetServerTimeNow())
  if not current() then
    boss:Destroy()
    return
  end
  actor = boss
  boss.Parent = workspace
  require(BossSystem.Presentation.CombatAudio).Emit(boss, "EntranceReveal", root)

  local impactCenter = spawnPoint(pads.BossCircle, groundY + 0.15)
  safe(arrivalVFX, impactCenter, boss)
  remote:FireAllClients("ArrivalImpact", { Position = impactCenter, Sequence = sequence })

  require(BossSystem.Boss.BossNoCollision).Configure(boss)
  require(BossSystem.Presentation.BossAttackIndicator).Configure(boss)
  local forcedPhase = require(BossSystem.Development.InstantPhaseOverride).ApplySelected(boss)
  require(BossSystem.Phases.PhaseController).Start(boss)
  require(BossSystem.Combat.AttackController).Start(boss)
  if forcedPhase then
    workspace:SetAttribute("BossEncounterReady", true)
    remote:FireAllClients("BossArrived", {})
    return
  end
  require(BossSystem.Presentation.CharacterEffects).Arrival(boss, function()
    if not current() or actor ~= boss or not boss.Parent or boss:GetAttribute("EncounterEnded") then
      return
    end
    boss:SetAttribute("PhaseTitleOverride", nil)
    boss:SetAttribute("AIEnabled", true)
    boss:SetAttribute("AttackState", "Idle")
    workspace:SetAttribute("BossEncounterReady", true)
    remote:FireAllClients("BossArrived", {})
  end)
end
local function startEncounter(player)
  if workspace:GetAttribute("BossStartupReady") ~= true
    or player:GetAttribute("EncounterClientReady") ~= true then return false end
  if started then
    return false
  end
 DifficultyService.Lock()
 BattleScaling.Lock()
 DamageTracker.Reset()
  started = true
  local sequence = (workspace:GetAttribute("BossEntranceSequence") or 0) + 1
  workspace:SetAttribute("BossEntranceSequence", sequence)
  workspace:SetAttribute("EncounterStartedAt", workspace:GetServerTimeNow())
  workspace:SetAttribute("EncounterStarted", true)
  Arena.SetActive(true)
  task.spawn(function()
    local ok, err = xpcall(entrance, debug.traceback, sequence)
    if not ok then
      warn("Boss entrance: " .. tostring(err))
      if workspace:GetAttribute("BossEntranceSequence") == sequence then
        resetEncounter()
      end
    end
  end)
  return true
end
Arena.BindActivation(startEncounter)
require(BossSystem.Players.EncounterLifecycle).Start(resetEncounter)
local function onPlayer(player)
 if started then task.defer(function() BattleScaling.RaiseForRoster(actor) end) end
  if playerConnections[player] then
    return
  end
  player.RespawnLocation = started and scene.BattlefieldSpawn or scene.ExteriorSpawn
  playerConnections[player] = player.CharacterAdded:Connect(function(char)
    task.spawn(positionPlayer, player, char, started)
  end)
  if player.Character then
    task.spawn(positionPlayer, player, player.Character, started)
  end
end
table.insert(connections, Players.PlayerAdded:Connect(onPlayer))
table.insert(
  connections,
  Players.PlayerRemoving:Connect(function(player)
    local connection = playerConnections[player]
    playerConnections[player] = nil
    if connection then
      connection:Disconnect()
    end
    local anyone = false
    for _, other in ipairs(Players:GetPlayers()) do
      if other ~= player then
        anyone = true
        break
      end
    end
    if started and not anyone then
      resetEncounter()
    end
  end)
)
table.insert(connections, workspace:GetAttributeChangedSignal("BossEncounterResetSequence"):Connect(resetEncounter))
for _, player in ipairs(Players:GetPlayers()) do
  onPlayer(player)
end
script.Destroying:Connect(function()
  resetEncounter()
  Arena.Destroy()
  for _, connection in ipairs(connections) do
    connection:Disconnect()
  end
  for _, connection in pairs(playerConnections) do
    connection:Disconnect()
  end
end)

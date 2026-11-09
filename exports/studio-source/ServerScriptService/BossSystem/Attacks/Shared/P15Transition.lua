local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
  local Registry = require(BossSystem.Combat.AttackRegistry)
  local Effects = require(BossSystem.Combat.EffectService)
  local Locomotion = require(BossSystem.Boss.BossLocomotion)
  local Story = require(BossSystem.Encounter.EncounterStory)
  local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
  local Audio = require(BossSystem.Presentation.CombatAudio)
  local boss = actor
  local Players = game:GetService("Players")
  local Run = game:GetService("RunService")
  local Tween = Effects
  local core = Registry.For(boss, "P1CombatCore")
  local encounter = require(BossSystem.Players.PlayerEncounter)
  local api = {}
  local activeCast
  function api.IsActive()
    return activeCast and activeCast:Alive() or false
  end
  local gold = Color3.fromRGB(255, 215, 25)
  local white = Color3.fromRGB(255, 255, 185)
  local function freezeStanding()
    local root = core.Root
    local floor = core.FloorY(root.Position + Vector3.new(0, 10, 0), core.Params())
    local frame = CFrame.new(root.Position.X, floor or root.Position.Y, root.Position.Z) * root.CFrame.Rotation
    local revision = boss:GetAttribute("MovementRevision") or 0
    local token = Locomotion.Pose(boss, {
      RightShoulder = { core.Humanoid.RigType == Enum.HumanoidRigType.R6 and 21 or 12, -6, -8 },
      RightElbow = { 22, 0, 0 },
      RightWrist = { -10, 0, 3 },
      LeftShoulder = { -3, 0, -4 },
    }, 0.1, true)
    local connections = {}
    local closed = false
    local function release()
      if closed then
        return
      end
      closed = true
      for _, connection in ipairs(connections) do
        connection:Disconnect()
      end
      Locomotion.ReleasePose(boss, token, 0.18)
    end
    local applying = false
    local function hold()
      if closed or applying then
        return
      end
      if
        not root.Parent
        or not boss.Parent
        or core.Humanoid.Health <= 0
        or boss:GetAttribute("EncounterEnded")
        or (boss:GetAttribute("MovementRevision") or 0) ~= revision
      then
        release()
        return
      end
      applying = true
      if root.CFrame ~= frame then
        root.CFrame = frame
      end
      root.AssemblyLinearVelocity = Vector3.zero
      root.AssemblyAngularVelocity = Vector3.zero
      applying = false
    end
    table.insert(connections, root:GetPropertyChangedSignal("CFrame"):Connect(hold))
    table.insert(connections, Run.Heartbeat:Connect(hold))
    hold()
    local sword = boss:FindFirstChild("Basic Sword")
    local blade = sword and sword:FindFirstChild("Blade")
    local trail = blade and blade:FindFirstChild("SlashTrail")
    if trail then
      trail.Enabled = false
    end
    local light = blade and blade:FindFirstChild("WindupLight")
    if light then
      light.Brightness = 0
    end
    return release
  end
  function api.ChoosePlayer()
    local selected, distance = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
      local char = p.Character
      local r = char and char:FindFirstChild("HumanoidRootPart")
      if r and core.Alive(char) and not encounter.IsDefeated(p) then
        local d = (r.Position - core.Root.Position).Magnitude
        if d < distance then
          selected = p
          distance = d
        end
      end
    end
    return selected
  end
  local function playerGround(player)
    local char = player.Character
    local r = char and char:FindFirstChild("HumanoidRootPart")
    local pos = r and r.Position or core.Root.Position
    local floor = workspace:Raycast(pos + Vector3.new(0, 15, 0), Vector3.new(0, -300, 0), core.Params(char))
    return Vector3.new(pos.X, floor and floor.Position.Y or 0, pos.Z)
  end
  function api.SkySword(player, valid)
    valid = valid
      or function()
        return boss.Parent and core.Humanoid.Health > 0 and not boss:GetAttribute("EncounterEnded")
      end
    if not valid() or player.Parent ~= Players then
      return false
    end
    local cast = Effects.NewCast(boss, "Phase15Judgment", 6)
    cast.TimeStopExempt = true
    local model = Instance.new("Model")
    model.Name = "Phase15JudgmentSword"
    model.Parent = core.Effects
    cast:Add(model)
    local ground = playerGround(player)
    local origin = CFrame.new(ground + Vector3.new(0, 90, 0))
    model.WorldPivot = origin
    local function piece(name, offset, size, color)
      local part = core.Part(name, origin * CFrame.new(offset), size, color, 0.05)
      part.Parent = model
      return part
    end
    piece("MassiveGoldenBlade", Vector3.new(0, 32, 0), Vector3.new(8, 56, 3), gold)
    local tip = Instance.new("WedgePart")
    tip.Name = "DownwardSwordPoint"
    tip.Size = Vector3.new(8, 8, 3)
    tip.CFrame = origin * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.pi)
    tip.Color = white
    tip.Material = Enum.Material.Neon
    tip.Anchored = true
    tip.CanCollide = false
    tip.CanTouch = false
    tip.CanQuery = false
    tip.Parent = model
    piece("BrightBladeCore", Vector3.new(0, 32, -1.55), Vector3.new(1, 56, 0.2), white)
    piece("GoldenGuard", Vector3.new(0, 62, 0), Vector3.new(32, 4, 7), gold)
    piece("GoldenHilt", Vector3.new(0, 75, 0), Vector3.new(4, 22, 4), white)
    local pommel = piece("GoldenPommel", Vector3.new(0, 88, 0), Vector3.new(8, 8, 8), gold)
    pommel.Shape = Enum.PartType.Ball
    boss:SetAttribute("JudgmentSwordSummonedAt", workspace:GetServerTimeNow())
    Audio.Emit(boss, "LifeCheckExecution", ground + Vector3.new(0, 90, 0))
    boss:SetAttribute("AttackState", "Phase 1.5: judgment sword from the sky")
    local begin = os.clock()
    repeat
      if not valid() or player.Parent ~= Players then
        cast:Dispose()
        return false
      end
      ground = playerGround(player)
      model:PivotTo(CFrame.new(ground + Vector3.new(0, 90, 0)))
      Run.Heartbeat:Wait()
    until os.clock() - begin >= 1.3 or not boss.Parent
    encounter.Say("BEGONE!", player, { ScreenOnly = true })
    boss:SetAttribute("JudgmentBegoneAt", workspace:GetServerTimeNow())
    begin = os.clock()
    boss:SetAttribute("JudgmentStrikeStartedAt", workspace:GetServerTimeNow())
    Audio.Emit(boss, "JudgmentFall", ground)
    repeat
      if not valid() or player.Parent ~= Players then
        cast:Dispose()
        return false
      end
      local alpha = math.clamp((os.clock() - begin) / 0.35, 0, 1)
      ground = playerGround(player)
      model:PivotTo(CFrame.new(ground + Vector3.new(0, 90 * (1 - alpha * alpha), 0)))
      if alpha >= 1 then
        break
      end
      Run.Heartbeat:Wait()
    until not boss.Parent
    model:PivotTo(CFrame.new(ground))
    boss:SetAttribute("JudgmentImpacts", (boss:GetAttribute("JudgmentImpacts") or 0) + 1)
    boss:SetAttribute("JudgmentImpactAt", workspace:GetServerTimeNow())
    Audio.Emit(boss, "JudgmentImpact", ground)
     
     
    encounter.ExhaustLives(player, "Phase 1.5 judgment")
    core.ScreenEffect("Shake", { Origin = ground, Radius = 1000, Duration = 1.4, Intensity = 1.8 })
    local flash = cast:Add(
      core.Part(
        "JudgmentImpactFlash",
        CFrame.new(ground + Vector3.new(0, 12, 0)),
        Vector3.new(8, 8, 8),
        white,
        0.2
      )
    )
    flash.Shape = Enum.PartType.Ball
    Tween:Create(flash, TweenInfo.new(0.7), { Size = Vector3.new(150, 45, 150), Transparency = 1 }):Play()
    local pieces = {}
    for index = 0, 63 do
      local angle = index * math.pi * 2 / 64
      local part = core.Part("JudgmentMassiveShockwave", CFrame.new(ground), Vector3.new(1, 20, 1), gold, 0.12)
      cast:Add(part)
      table.insert(pieces, { part = part, angle = angle })
    end
    local start = cast:Now()
    cast:Step(function(_, now)
      local alpha = math.clamp((now - start) / 1.2, 0, 1)
      local radius = 5 + 220 * alpha
      for _, item in ipairs(pieces) do
        if item.part.Parent then
          item.part.CFrame = CFrame.new(
            ground + Vector3.new(math.cos(item.angle) * radius, 10, math.sin(item.angle) * radius)
          ) * CFrame.Angles(0, -item.angle, 0)
          item.part.Size = Vector3.new(8, 20, 2 * radius * math.sin(math.pi / 64) + 0.4)
          item.part.Transparency = 0.12 + 0.88 * alpha
        end
      end
      return alpha < 1
    end)
    for _, part in ipairs(model:GetDescendants()) do
      if part:IsA("BasePart") then
        Tween:Create(part, TweenInfo.new(1), { Transparency = 1 }):Play()
      end
    end
    cast:Schedule(1.4, function()
      cast:Dispose()
    end)
    return true
  end
  function api.Begin(player)
    if
      api.IsActive()
      or boss:GetAttribute("Phase15Triggered")
      or (boss:GetAttribute("Phase") or 1) >= 2
      or (boss:GetAttribute("Shield") or Config.ShieldMaxHealth) > Config.Phase15ShieldThreshold
      or core.Humanoid.Health <= 0
    then
      return false
    end
    local character = player and player.Character
    if not player or player.Parent ~= Players or not core.Alive(character) or encounter.IsDefeated(player) then
      player = api.ChoosePlayer()
    end
    if not player then
      return false
    end
    local lives = player:GetAttribute("LivesRemaining") or 5
    local starting=player:GetAttribute("StartingLives") or encounter.StartingLives
  local punish=lives<=2 and lives<starting
    local pendingBefore = player:GetAttribute("ExecutionPending")
    boss:SetAttribute("Phase15Triggered", true)
    boss:SetAttribute("PhaseTransitionInProgress", true)
    boss:SetAttribute("Phase", 1.5)
    boss:SetAttribute("AIEnabled", false)
    boss:SetAttribute("ParryActive", false)
    boss:SetAttribute("Phase15Branch", punish and "Judgment" or "Continue")
    if punish then
      player:SetAttribute("ExecutionPending", true)
    end
    local revision = (boss:GetAttribute("MovementRevision") or 0) + 1
    boss:SetAttribute("MovementRevision", revision)
    local generation = (boss:GetAttribute("PhaseGeneration") or 0) + 1
    boss:SetAttribute("PhaseGeneration", generation)
    local cast = Effects.NewCast(boss, "Phase15Transition", 3 + Story.Duration(Story.Phase15Success) + 8)
    activeCast = cast
    cast.TimeStopExempt = true
    boss:SetAttribute("Phase15TransitionActive", true)
    local release
    if punish then
      release = freezeStanding()
      boss:SetAttribute("JudgmentPauseStartedAt", workspace:GetServerTimeNow())
      boss:SetAttribute("AttackState", "Phase 1.5: standing still")
    end
    local completed = false
    local function current()
      return not cast.closed
        and boss.Parent
        and core.Humanoid.Health > 0
        and not boss:GetAttribute("EncounterEnded")
        and (boss:GetAttribute("MovementRevision") or 0) == revision
        and (boss:GetAttribute("PhaseGeneration") or 0) == generation
    end
    local function waitFor(seconds)
      local ends = cast:Now() + seconds
      while current() and cast:Now() < ends do
        Run.Heartbeat:Wait()
      end
      return current()
    end
    cast:Step(function()
      if not current() then
        cast:Dispose()
        return false
      end
      return true
    end)
    cast.OnDispose = function()
      if activeCast == cast then
        activeCast = nil
      end
      if boss.Parent then
        boss:SetAttribute("Phase15TransitionActive", false)
      end
      if punish and not completed and player.Parent == Players and not encounter.IsDefeated(player) then
        player:SetAttribute("ExecutionPending", pendingBefore)
      end
      if boss.Parent and (boss:GetAttribute("PhaseGeneration") or 0) == generation then
        boss:SetAttribute("PhaseTransitionInProgress", false)
        boss:SetAttribute("AttackInProgress", false)
        boss:SetAttribute("AttackState", "Idle")
        if core.Humanoid.Health > 0 and not boss:GetAttribute("EncounterEnded") then
          boss:SetAttribute("AIEnabled", true)
          boss:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.5)
        end
      end
      if release then
        local released, err = pcall(release)
        if not released then
          warn("Phase 1.5 pose cleanup: " .. tostring(err))
        end
      end
    end
    task.spawn(function()
      local ok, err = xpcall(function()
         
         
         
        local options = { Valid = current, Wait = waitFor, Prefix = "Phase15" }
        if punish then
          if not waitFor(lives == 1 and 3 or 0.3) then
            return
          end
          boss:SetAttribute("JudgmentPauseFinishedAt", workspace:GetServerTimeNow())
          if not Story.Play(boss, Story.Phase15Failure, options) then
            return
          end
          completed = api.SkySword(player, current)
        else
          completed = Story.Play(boss, Story.Phase15Success, options)
        end
      end, debug.traceback)
      if not ok then
        warn("Phase 1.5 transition failed: " .. tostring(err))
      end
      cast:Dispose()
    end)
    return true
  end

  return api
end

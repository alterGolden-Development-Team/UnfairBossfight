local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Registry = require(BossSystem.Combat.AttackRegistry)
local Clones = require(BossSystem.Mechanics.Clones.CloneController)
local QTE = require(BossSystem.Combat.CataclysmQTEService)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Difficulty = require(Shared.Config.DifficultyConfig)
local Rewards = require(BossSystem.Encounter.VictoryRewards)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Effects = require(BossSystem.Combat.EffectService)
local Status = require(BossSystem.Combat.StatusEffectService)
local Weapon = require(BossSystem.Boss.WeaponController)
local Phase3Intro = require(BossSystem.Phases.Phase3Intro)
local Story = require(BossSystem.Encounter.EncounterStory)
local Phase25 = require(BossSystem.Phases.Phase25Controller)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Run = game:GetService("RunService")
local api = {}
local records = setmetatable({}, { __mode = "k" })
local shieldCasts = setmetatable({}, { __mode = "k" })
local phaseCasts = setmetatable({}, { __mode = "k" })
local skyRecords = setmetatable({}, { __mode = "k" })

 
local function clearShieldGateAttack(actor)
  actor:SetAttribute("AttackInProgress", false)
  actor:SetAttribute("ActiveAttackToken", nil)
  actor:SetAttribute("CurrentAttackFile", "Idle")
  actor:SetAttribute("CurrentSkill", nil)
  actor:SetAttribute("ExecutionLocked", false)
  actor:SetAttribute("ParryActive", false)
end
local function shieldGateGround(actor, fallback, useSpawn)
  local placement = require(BossSystem.Encounter.ArenaPlacement)
  local bounds = placement.GetBounds()
  if not bounds then
    return nil
  end
  local circles = bounds.Arena:FindFirstChild("SpawnCircles")
  local circle = circles and circles:FindFirstChild("BossCircle")
  local x, z = circle and circle:GetAttribute("SpawnX"), circle and circle:GetAttribute("SpawnZ")
  local point = useSpawn ~= false
      and type(x) == "number"
      and type(z) == "number"
      and Vector3.new(x, bounds.Frame.Y, z)
    or typeof(fallback) == "CFrame" and fallback.Position
    or bounds.Frame.Position
  local rotation = typeof(fallback) == "CFrame" and fallback.Rotation or CFrame.identity
  for distance = 0, 24, 4 do
    for index = 0, distance == 0 and 0 or 7 do
      local angle = index * math.pi / 4
      local frame = placement.Validate(
        actor,
        CFrame.new(point + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance) * rotation,
        { Margin = 6 }
      )
      if frame then
        return frame
      end
    end
  end
  return nil
end
local function shieldGatePerch(actor, ground)
  local placement = require(BossSystem.Encounter.ArenaPlacement)
  local runtime = require(BossSystem.Combat.CombatRuntime)
  local bounds = placement.GetBounds()
  local walls = bounds and bounds.Arena:FindFirstChild("SurroundingWalls")
  local root = actor:FindFirstChild("HumanoidRootPart")
  local h = actor:FindFirstChildOfClass("Humanoid")
  if not walls or not root or not h then
    return nil
  end
  local standing = root.Size.Y * 0.5 + h.HipHeight
  if h.RigType == Enum.HumanoidRigType.R6 then
    local leg = actor:FindFirstChild("Right Leg") or actor:FindFirstChild("Left Leg")
    standing += leg and leg.Size.Y or 2
  end
  local candidates = {}
   -- the designed perch is the wall straight behind the boss's spawn circle, so candidates are
   -- ranked by distance to that point (falls back to where the boss stands)
  local anchor = Vector3.new(ground.X, 0, ground.Z)
  local circles = bounds.Arena:FindFirstChild("SpawnCircles")
  local spawnCircle = circles and circles:FindFirstChild("BossCircle")
  local sx, sz = spawnCircle and spawnCircle:GetAttribute("SpawnX"), spawnCircle and spawnCircle:GetAttribute("SpawnZ")
  if type(sx) == "number" and type(sz) == "number" then
    local spawnLocal = bounds.Frame:PointToObjectSpace(Vector3.new(sx, bounds.Frame.Y, sz))
    local flat = Vector3.new(spawnLocal.X, 0, spawnLocal.Z)
    if flat.Magnitude > 1 then
      local dir = flat.Unit
      local reach = math.min(bounds.HalfX / math.max(math.abs(dir.X), 1e-3), bounds.HalfZ / math.max(math.abs(dir.Z), 1e-3))
      local edge = bounds.Frame:PointToWorldSpace(dir * (reach + 9))
      anchor = Vector3.new(edge.X, 0, edge.Z)
    end
  end
  for _, wall in ipairs(walls:GetDescendants()) do
    if
      wall:IsA("BasePart")
      and wall.Anchored
      and wall.CanCollide
      and wall.Size.Y >= 6
      and math.min(wall.Size.X, wall.Size.Z) >= 10  -- terrace blocks are chunky, not long walls
      and wall.CFrame.UpVector.Y > 0.98
    then
       -- the spot on this block's top nearest the designed perch (3 studs in from its edges)
      local p = wall.CFrame:PointToObjectSpace(Vector3.new(anchor.X, wall.Position.Y, anchor.Z))
      local top = Vector3.new(
        math.clamp(p.X, -wall.Size.X * 0.5 + 3, wall.Size.X * 0.5 - 3),
        wall.Size.Y * 0.5,
        math.clamp(p.Z, -wall.Size.Z * 0.5 + 3, wall.Size.Z * 0.5 - 3)
      )
      local point = wall.CFrame:PointToWorldSpace(top)
      table.insert(
        candidates,
        {
          Point = point,
          Distance = (Vector3.new(point.X, 0, point.Z) - anchor).Magnitude,
        }
      )
    end
  end
  table.sort(candidates, function(a, b)
    return a.Distance < b.Distance
  end)
  local ray = RaycastParams.new()
  ray.FilterType = Enum.RaycastFilterType.Include
  ray.FilterDescendantsInstances = { walls }
  ray.RespectCanCollide = true
  local overlap = OverlapParams.new()
  overlap.FilterType = Enum.RaycastFilterType.Exclude
  overlap.RespectCanCollide = true
  local excluded = { actor, runtime.Effects, runtime.Summons }
  for _, target in ipairs(runtime.AllTargets()) do
    table.insert(excluded, target)
  end
  overlap.FilterDescendantsInstances = excluded
  overlap.MaxParts = 24
  for _, candidate in ipairs(candidates) do
    local point = candidate.Point
    local hit = workspace:Raycast(point + Vector3.new(0, 40, 0), Vector3.new(0, -100, 0), ray)
    local mapPoint = bounds.Frame:PointToObjectSpace(point)
    if
      hit
      and hit.Normal.Y > 0.65
      and hit.Instance.Anchored
      and hit.Instance.CanCollide
       -- tier-1 terrace tops sit ~10 studs past the floor edge; the invisible knockback barriers
       -- start 12 past it, so the perch stays on tier 1, inside them
      and math.abs(mapPoint.X) <= bounds.HalfX + 10
      and math.abs(mapPoint.Z) <= bounds.HalfZ + 10
      and hit.Position.Y >= bounds.Frame.Y + 6
      and hit.Position.Y <= bounds.Frame.Y + 100
    then
      local position = hit.Position + Vector3.new(0, standing + 0.12, 0)
      local center = bounds.Frame.Position
      local direction = Vector3.new(center.X - position.X, 0, center.Z - position.Z)  -- face the arena
      if direction.Magnitude < 0.01 then
        direction = Vector3.new(0, 0, -1)
      end
      local frame = CFrame.lookAt(position, position + direction)
      local bodyHeight = standing + 2.7
      local box = frame + Vector3.new(0, bodyHeight * 0.5 - standing + 0.08, 0)
      local clear = true
      for _, obstacle in ipairs(workspace:GetPartBoundsInBox(box, Vector3.new(3.4, bodyHeight, 3.4), overlap)) do
        if obstacle.CanCollide then
          clear = false
          break
        end
      end
      if clear then
        return frame, hit.Instance
      end
    end
  end
  return nil
end

function api.ShieldBroken(actor, target)
  if math.floor(actor:GetAttribute("Phase") or 1) == 3 and (actor:GetAttribute("Shield") or 1) <= 0 then
    return api.BeginPhase4(actor, target)
  end
  if not actor.Parent or actor.Humanoid.Health <= 0 or actor:GetAttribute("EncounterEnded")
    or (actor:GetAttribute("Shield") or 1) > 0 then
    return false
  end
  if actor:GetAttribute("ShieldBroken") then
     
     
    local shieldCast, phaseCast = shieldCasts[actor], phaseCasts[actor]
    if (actor:GetAttribute("Phase") or 1) >= 2
      or shieldCast and not shieldCast.closed
      or phaseCast and not phaseCast.closed
      or (actor:GetAttribute("ShieldCloneGateCompletedAt") or 0) > 0 then
      return false
    end
  end
  local phase = actor:GetAttribute("Phase") or 1
  if phase == 2 or phase == 2.5 then
    return api.BeginPhase3(actor, target)
  end
  actor:SetAttribute("ShieldBroken", true)
  actor:SetAttribute("Defense", 0)
  actor:SetAttribute("ShieldBrokenAt", workspace:GetServerTimeNow())
  if math.min(4, math.floor(phase)) == 4 then Registry.For(actor, "P4Regeneration(Passive)").OnShieldBroken() end
  Audio.Emit(actor, "ShieldCrack", actor:FindFirstChild("HumanoidRootPart"))
  if phase >= 2 then
    return true
  end
  local core = Registry.For(actor, "P1CombatCore")
  local placement = require(BossSystem.Encounter.ArenaPlacement)
  local runtime = require(BossSystem.Combat.CombatRuntime)
  local passives = require(BossSystem.Combat.PassiveController)
  target = target or core.Melee.GetTarget()
  actor:SetAttribute("ShieldBreakInProgress", true)
  actor:SetAttribute("PhaseTransitionInProgress", true)
  actor:SetAttribute("Invulnerable", true)
  actor:SetAttribute("AIEnabled", false)
  actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
  actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
  clearShieldGateAttack(actor)
  actor:SetAttribute("UnstoppableDisabled", true)
  actor:SetAttribute("ShieldCloneGateActive", false)
  actor:SetAttribute("ShieldCloneGateCompletedAt", 0)
  actor:SetAttribute("ShieldCloneGateRevision", "observer-return-3")
  actor:SetAttribute("ShieldCloneGateLastError", nil)
  actor:SetAttribute("ShieldCloneGateReturnStartedAt", 0)
  actor:SetAttribute("ShieldCloneGateDefeatedCount", 0)
  actor:SetAttribute("ShieldCloneGateCount", 0)
  Clones.CancelAll(actor, "Shield-break gate")
  QTE.CancelForActor(actor, "Shield-break gate")
  passives.Stop(actor)
  require(BossSystem.Mechanics.Time.TimeEffectController).ClearOwner(actor)
  Effects.CancelOwner(actor, "Shield-break gate")
  Audio.StopMusic(actor, "P1ShieldBreakDialogue")
  local frozen = placement.Validate(actor, core.Root.CFrame) or shieldGateGround(actor, core.Root.CFrame)
  if not frozen then
    actor:SetAttribute("ShieldBreakInProgress", false)
    actor:SetAttribute("PhaseTransitionInProgress", false)
    actor:SetAttribute("Invulnerable", false)
    actor:SetAttribute("AIEnabled", true)
    actor:SetAttribute("AttackState", "Idle")
    passives.Start(actor, core.Melee.GetTarget)
    warn("Shield-break gate has no safe arena floor")
    return false
  end
  local ground = shieldGateGround(actor, frozen)
  local storyDuration = Story.Duration(Story.ShieldBreak)
  local roarStart = storyDuration + (Config.ShieldBreakRoarWindup or 0.9)
  local cast = Effects.NewCast(actor, "ShieldBreakCloneGate", roarStart + 10)
  cast.TimeStopExempt = true
  cast.TransitionControl = true
  local generation = actor:GetAttribute("PhaseGeneration") or 0
  local revision = actor:GetAttribute("MovementRevision") or 0
  local lockId = tostring(cast)
  local lockedCharacters, impulses, handles, defeated = {}, {}, {}, {}
  local cloneHealthConnections = {}
  local screamHandle
  local heldFrame = frozen
  local jumping, finished, returning = false, false, false
  local finishGate
  local roarEndsAt, roarScan = 0, 0
  local nextSniperAt, sniperBusy = math.huge, false
  local function owns()
    return actor.Parent
      and core.Root.Parent
      and core.Humanoid.Health > 0
      and not actor:GetAttribute("EncounterEnded")
      and (actor:GetAttribute("PhaseGeneration") or 0) == generation
      and (actor:GetAttribute("MovementRevision") or 0) == revision
  end
  local function current()
    return not cast.closed and owns() and (actor:GetAttribute("Phase") or 1) < 2
  end
  local function releasePlayers()
    for character, player in pairs(lockedCharacters) do
      Status.SetLocked(player, cast, false)
      if character.Parent and character:GetAttribute("ShieldBreakDashLockToken") == lockId then
        character:SetAttribute("ShieldBreakDashLocked", false)
        character:SetAttribute("ShieldBreakDashLockToken", nil)
        character:SetAttribute("ShieldBreakCinematicLocked", false)
      end
      if player.Parent and player:GetAttribute("ShieldBreakCinematicLockToken") == lockId then
        player:SetAttribute("ShieldBreakCinematicLocked", false)
        player:SetAttribute("ShieldBreakCinematicLockToken", nil)
      end
    end
    table.clear(lockedCharacters)
  end
  local function lockPlayer(character)
    if lockedCharacters[character] then
      return
    end
    local player = Players:GetPlayerFromCharacter(character)
    if not player or player.Character ~= character then
      return
    end
    lockedCharacters[character] = player
    character:SetAttribute("ShieldBreakDashLockToken", lockId)
    character:SetAttribute("ShieldBreakDashLocked", true)
    character:SetAttribute("ShieldBreakCinematicLocked", true)
    player:SetAttribute("ShieldBreakCinematicLockToken", lockId)
    player:SetAttribute("ShieldBreakCinematicLocked", true)
    Status.SetLocked(player, cast, true)
    require(BossSystem.Players.R6DashService).Cancel(player, "Shield-break scream")
  end
  local function publish(index, health, maxHealth, dead)
    if not owns() or shieldCasts[actor] ~= cast then
      return
    end
    local prefix = "ShieldGateClone" .. index
    actor:SetAttribute(prefix .. "Health", math.max(0, health or 0))
    actor:SetAttribute(prefix .. "MaxHealth", maxHealth or (Config.ShieldGateCloneMaxHealth or 1000))
    actor:SetAttribute(prefix .. "Alive", not dead and (health or 0) > 0)
    actor:SetAttribute(prefix .. "Title", index == 1 and "Elementalist" or "Swordsmaster")
  end
   
  local function recordDefeat(index, humanoid)
    if not current() or defeated[index] or not humanoid or humanoid.Health > 0 then return end
    defeated[index] = true
    publish(index, 0, humanoid.MaxHealth, true)
    actor:SetAttribute("ShieldCloneGateDefeatedCount", (defeated[1] and 1 or 0) + (defeated[2] and 1 or 0))
    if defeated[1] and defeated[2] then
       
       
      task.defer(function() finishGate() end)
    end
  end
  local function jumpTo(goal, seconds, height)
    if not current() or typeof(goal) ~= "CFrame" then
      return false
    end
    local from, elapsed = core.Root.CFrame, 0
    jumping = true
    core.Melee.Pose("Windup3", 0.1)
    while elapsed < seconds do
      if not current() then
        jumping = false
        return false
      end
      local dt = Run.Heartbeat:Wait()
      if not current() then
        jumping = false
        return false
      end
      elapsed += dt
      local alpha = math.clamp(elapsed / seconds, 0, 1)
      core.Root.CFrame = from:Lerp(goal, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * height, 0)
      core.Root.AssemblyLinearVelocity = Vector3.zero
    end
    heldFrame = goal
    jumping = false
    core.Root.CFrame = goal
    core.Melee.Pose("Idle", 0.15)
    return true
  end
  finishGate = function()
    if returning or not current() or not (defeated[1] and defeated[2]) then return end
    returning = true
    actor:SetAttribute("ShieldCloneGateReturnStartedAt", workspace:GetServerTimeNow())
    task.spawn(function()
      local ok, err = xpcall(function()
    actor:SetAttribute("ShieldCloneGateActive", false)
    actor:SetAttribute("AttackState", "Shield break: returning to arena")
    local returnFrame = placement.Validate(actor, ground, { Margin = 6 }) or shieldGateGround(actor, ground)
    if not returnFrame then
      error("Shield gate return floor is blocked")
    end
    if not jumpTo(returnFrame, Config.ShieldGateReturnDuration or 0.8, Config.ShieldGateJumpArcHeight or 12) then
      return
    end
    ground = returnFrame
    finished = true
      end, debug.traceback)
      if not ok then
        actor:SetAttribute("ShieldCloneGateLastError", tostring(err))
        warn("Shield gate return: " .. tostring(err))
      end
      if not cast.closed then cast:Dispose() end
    end)
  end
  shieldCasts[actor] = cast
  actor:SetAttribute("ShieldCloneGateToken", lockId)
  actor:SetAttribute("AttackState", "Shield break: dialogue")
  cast:Step(function(dt)
    if not current() then
      cast:Dispose()
      return false
    end
    if not jumping then
      core.Root.CFrame = heldFrame
      core.Root.AssemblyLinearVelocity = Vector3.zero
    end
    roarScan += dt
    if roarScan >= 0.1 and workspace:GetServerTimeNow() < roarEndsAt then
      roarScan = 0
      for _, player in ipairs(Players:GetPlayers()) do
        if core.Alive(player.Character) then
          lockPlayer(player.Character)
        end
      end
    end
    return true
  end)
  cast.OnDispose = function()
    roarEndsAt = 0
    releasePlayers()
    if screamHandle then
      screamHandle:Dispose()
      screamHandle = nil
    end
    for _, impulse in ipairs(impulses) do
      impulse:Dispose()
    end
    for _, connection in ipairs(cloneHealthConnections) do connection:Disconnect() end
    table.clear(cloneHealthConnections)
    for _, handle in ipairs(handles) do
      local ok, err = pcall(function() handle:Cancel("Shield gate disposed") end)
      if not ok then warn("Shield gate clone cleanup: " .. tostring(err)) end
    end
    table.clear(handles)
    table.clear(impulses)
    if shieldCasts[actor] ~= cast then
      return
    end
    shieldCasts[actor] = nil
    if actor.Parent and actor:GetAttribute("ShieldCloneGateToken") == lockId then
      actor:SetAttribute("ShieldCloneGateActive", false)
      actor:SetAttribute("ShieldCloneGateCount", 0)
      actor:SetAttribute("ShieldGateClone1Alive", false)
      actor:SetAttribute("ShieldGateClone2Alive", false)
      actor:SetAttribute("ShieldCloneGateToken", nil)
      actor:SetAttribute("ShieldBreakInProgress", false)
    end
    if not owns() then
      return
    end
    clearShieldGateAttack(actor)
    if finished then
      actor:SetAttribute("ShieldBreakSequenceCompletedAt", workspace:GetServerTimeNow())
      actor:SetAttribute("ShieldCloneGateCompletedAt", workspace:GetServerTimeNow())
      if api.BeginPhase2(actor) then
        return
      end
    elseif ground and core.Root.Parent then
      core.Root.CFrame = ground
      core.Root.AssemblyLinearVelocity = Vector3.zero
    end
    actor:SetAttribute("PhaseTransitionInProgress", false)
    actor:SetAttribute("Invulnerable", false)
    actor:SetAttribute("AIEnabled", true)
    actor:SetAttribute("AttackState", "Idle")
    actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.5)
    core.Melee.Pose("Idle", 0.15)
    passives.Start(actor, core.Melee.GetTarget)
  end

  local function sequence()
    if not Story.Play(actor, Story.ShieldBreak, { Valid = current }) or not current() then
      return
    end
    core.PoseAngles({ RightShoulder = { 65, 0, 65 }, LeftShoulder = { 65, 0, -65 }, Waist = { -15, 0, 0 } }, 0.35)
    local windupEnds = cast:Now() + (Config.ShieldBreakRoarWindup or 0.9)
    while current() and cast:Now() < windupEnds do
      Run.Heartbeat:Wait()
    end
    if not current() then
      return
    end
    local handle, reason =
      Audio.StartFinite(actor, "P1ShieldBreakScream", core.Root, { Pitch = 1, Valid = current })
    if not handle then
      if current() then
        warn("Shield-break scream unavailable: " .. tostring(reason))
      end
      return
    end
    if not current() then
      handle:Dispose()
      return
    end
    screamHandle = handle
    roarEndsAt = handle.EndsAt
    cast.expires = math.huge
    local origin = frozen.Position
    local now = workspace:GetServerTimeNow()
    actor:SetAttribute("AttackState", "Shield break: roaring")
    actor:SetAttribute("ShieldBreakScreamDuration", handle.Duration)
    actor:SetAttribute("ShieldBreakScreamEndsAt", roarEndsAt)
    actor:SetAttribute("ShieldBreakScreamAsset", "rbxassetid://111870313797501")
    actor:SetAttribute("ShieldBreakRoaredAt", now)
    actor:SetAttribute("ShieldBreakRoarStartedAt", now)
    actor:SetAttribute("ShieldBreakKnockbackStartedAt", now)
    Audio.Emit(actor, "ShieldShatter", origin)
    Audio.Emit(actor, "Knockback", origin)
    core.ScreenEffect(
      "Shake",
      { Origin = origin, Radius = Config.ShieldBreakRoarRadius, Duration = handle.Duration, Intensity = 2.6 }
    )
    for _, player in ipairs(Players:GetPlayers()) do
      if core.Alive(player.Character) then
        lockPlayer(player.Character)
      end
    end
    for _, character in ipairs(core.Characters()) do
      if
        core.Alive(character)
        and (character.HumanoidRootPart.Position - origin).Magnitude <= Config.ShieldBreakRoarRadius
      then
        local impulse = runtime.Knockback(actor, character, character.HumanoidRootPart.Position - origin, {
          TransitionControl = true,
          Speed = Config.ShieldBreakKnockbackSpeed,
          Lift = 55,
          Duration = handle.Duration,
          Sustain = 0.4,
          ContainsArena = true,
        })
        if impulse then
          table.insert(impulses, impulse)
        end
      end
    end
    local impact = Effects.NewCast(actor, "ShieldBreakRoarImpact", handle.Duration + 0.3)
    impact.TimeStopExempt = true
    local highlight = Instance.new("Highlight")
    highlight.Name = "ShieldBreakRoarEnergy"
    highlight.Adornee = actor
    highlight.FillColor = Color3.fromRGB(255, 206, 21)
    highlight.FillTransparency = 0.65
    highlight.OutlineColor = Color3.fromRGB(255, 221, 61)
    highlight.OutlineTransparency = 0.1
    highlight.Parent = actor
    impact:Add(highlight)
    for index = 1, 3 do
      local ring = impact:Add(
        core.Part(
          "GoldenRoarGroundWave",
          CFrame.new(origin - Vector3.new(0, 2.7 - index * 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2),
          Vector3.new(0.2, 4, 4),
          Color3.fromRGB(255, 205, 21),
          0.45
        )
      )
      ring.Shape = Enum.PartType.Cylinder
      ring:SetAttribute("TimeStopExempt", true)
      Effects:Create(ring, TweenInfo.new(handle.Duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.2, 130 + index * 35, 130 + index * 35),
        Transparency = 1,
      }):Play()
    end
    while current() and not handle:IsComplete() do
      Run.Heartbeat:Wait()
    end
    if not current() then
      return
    end
    roarEndsAt = 0
    for _, impulse in ipairs(impulses) do
      impulse:Dispose()
    end
    table.clear(impulses)
    releasePlayers()
    handle:Dispose()
    screamHandle = nil
    actor:SetAttribute("ShieldBreakRoarFinishedAt", workspace:GetServerTimeNow())
    if not ground then
      error("Shield gate ground destination is blocked")
    end
    local perch, support = shieldGatePerch(actor, ground)
    if not perch then
      error("Shield gate has no clear castle-wall perch")
    end
    actor:SetAttribute("AttackState", "Shield break: jumping to wall")
    if not jumpTo(perch, Config.ShieldGateJumpDuration or 1, Config.ShieldGateJumpArcHeight or 12) then
      return
    end
    if not Story.Play(actor, Story.ShieldGateChallenge, { Valid = current, Prefix = "ShieldGate" }) then return end
    actor:SetAttribute("ShieldCloneGateActive", true)
    actor:SetAttribute("ShieldCloneGateStartedAt", workspace:GetServerTimeNow())
    actor:SetAttribute("ShieldCloneGatePerchFrame", perch)
    actor:SetAttribute("ShieldCloneGatePerchPart", support:GetFullName())
    actor:SetAttribute("AttackState", "Shield break: defeat the echoes")
  local bounds = placement.GetBounds()
  local arenaCenter = bounds and bounds.Frame.Position or ground.Position + ground.LookVector
  local inward = Vector3.new(arenaCenter.X, ground.Y, arenaCenter.Z)
  local formation = (inward - ground.Position).Magnitude > .01 and CFrame.lookAt(ground.Position, inward) or ground
    for index = 1, 2 do
   local role = index == 1 and "Elementalist" or "Swordsmaster"
   local side = Config.ShieldGateCloneSpawnSideOffset or 12
   local desired = formation * CFrame.new(index == 1 and -side or side, 0, 0)
      local frame = placement.Validate(actor, desired, { Margin = 6 })
        or shieldGateGround(actor, desired, false)
      if not frame then
        error("Shield gate clone has no clear floor")
      end
      local newHandle = Clones.Create(actor, {
        Mode = "ShieldGate",
        Role = role,
        AttackInterval = require(BossSystem.Attacks.Shared.ShieldBreakCombat).AttackInterval(role),
        Frame = frame,
        Target = target,
        MaxHealth = Config.ShieldGateCloneMaxHealth or 1000,
        MaterializeDuration = Config.ShieldGateCloneAppearanceDuration or 1.5,
        OnHealthUpdate = function(health, maxHealth)
          publish(index, health, maxHealth, false)
        end,
        OnDefeated = function(cloneHandle)
          recordDefeat(index, cloneHandle.Actor:FindFirstChildOfClass("Humanoid"))
        end,
      })
      if not newHandle then
        error("Shield gate clone factory rejected its owned summon")
      end
      handles[index] = newHandle
      newHandle.Actor:SetAttribute("ShieldGateIndex", index)
      local h = newHandle.Actor:FindFirstChildOfClass("Humanoid")
      assert(h, "Shield gate clone has no Humanoid")
      table.insert(cloneHealthConnections, h.HealthChanged:Connect(function(health)
        if health <= 0 then recordDefeat(index, h) end
      end))
      recordDefeat(index, h)
      publish(index, h.Health, h.MaxHealth, defeated[index])
      actor:SetAttribute("ShieldCloneGateCount", index)
    end
    local gateInterval = Config.P1ShieldGateBossInterval or Config.P1SnipingCooldown
    nextSniperAt = workspace:GetServerTimeNow() + gateInterval
    local GateAttacks = require(BossSystem.Mechanics.Clones.ShieldGateAttacks)
    while current() and not (defeated[1] and defeated[2]) do
    -- the boss's own skills (Sniping, Ground Shatter) take turns; each one's cooldown sets the pace
   local gateSkill = not sniperBusy and workspace:GetServerTimeNow() >= nextSniperAt and GateAttacks.Select(actor, "alterGolden", nil)
   if gateSkill then
    sniperBusy = true
    task.spawn(function()
     local ok, err = xpcall(function()
      actor:SetAttribute("AttackInProgress", true)
      GateAttacks.Cast(actor, "alterGolden", nil, gateSkill)
     end, debug.traceback)
     if current() then actor:SetAttribute("AttackInProgress", false) end
     sniperBusy = false
     if not ok then warn("Shield-break sniper: " .. tostring(err)) end
    end)
   end
      for index, cloneHandle in ipairs(handles) do
        recordDefeat(index, cloneHandle.Actor:FindFirstChildOfClass("Humanoid"))
        if not defeated[index] and not cloneHandle:IsActive() then
          error("Shield gate clone was cancelled before defeat")
        end
      end
      Run.Heartbeat:Wait()
    end
    if not current() then
      return
    end
    finishGate()
  end

  task.spawn(function()
    local ok, err = xpcall(sequence, debug.traceback)
    if not ok then
      actor:SetAttribute("ShieldCloneGateLastError", tostring(err))
      warn("Shield-break gate: " .. tostring(err))
    end
    if not cast.closed and not returning then
      cast:Dispose()
    end
  end)
  return true
end

function api.ResetLighting(actor)
  local record = skyRecords[actor]
  if not record then
    return
  end
  skyRecords[actor] = nil
  for _, tween in ipairs(record.Tweens) do
    tween:Cancel()
  end
  for key, value in pairs(record.Lighting) do
    Lighting[key] = value
  end
  if record.CreatedAtmosphere then
    record.Atmosphere:Destroy()
  elseif record.Atmosphere.Parent then
    for key, value in pairs(record.AtmosphereValues) do
      record.Atmosphere[key] = value
    end
  end
end
local function goldenSky(actor)
   -- Hellaven keeps its red night all fight (EncounterTheme, applied on each client): no golden afternoon
  if require(Shared.Presentation.EncounterTheme).IsHellaven() then
    workspace:SetAttribute("Phase2SkyTransitionAt", workspace:GetServerTimeNow())
    return
  end
  local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
  local created = not atmosphere
  if created then
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "EncounterAtmosphere"
    atmosphere.Parent = Lighting
  end
  local record =
    { Tweens = {}, Lighting = {}, Atmosphere = atmosphere, CreatedAtmosphere = created, AtmosphereValues = {} }
  for _, key in ipairs({ "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "ClockTime" }) do
    record.Lighting[key] = Lighting[key]
  end
  for _, key in ipairs({ "Color", "Decay", "Density", "Haze", "Glare" }) do
    record.AtmosphereValues[key] = atmosphere[key]
  end
  skyRecords[actor] = record
  record.Tweens[1] = Effects:Create(Lighting, TweenInfo.new(4, Enum.EasingStyle.Sine), {
    Ambient = Color3.fromRGB(205, 169, 75),
    OutdoorAmbient = Color3.fromRGB(255, 226, 143),
    ColorShift_Top = Color3.fromRGB(255, 224, 99),
    ColorShift_Bottom = Color3.fromRGB(133, 94, 26),
    ClockTime = 16,
  })
  record.Tweens[2] = Effects:Create(atmosphere, TweenInfo.new(4, Enum.EasingStyle.Sine), {
    Color = Color3.fromRGB(255, 229, 126),
    Decay = Color3.fromRGB(224, 171, 51),
    Density = 0.4,
    Haze = 2,
    Glare = 0.6,
  })
  for _, tween in ipairs(record.Tweens) do
    tween:Play()
  end
  workspace:SetAttribute("Phase2SkyTransitionAt", workspace:GetServerTimeNow())
end

function api.BeginPhase2(actor)
  if actor:GetAttribute("Phase2Triggered") or not actor.Parent or actor.Humanoid.Health <= 0 then
    return false
  end
  if
    actor:GetAttribute("ShieldBreakInProgress")
    or actor:GetAttribute("ShieldCloneGateActive")
    or (actor:GetAttribute("ShieldCloneGateCompletedAt") or 0) <= 0
  then
    return false
  end
  clearShieldGateAttack(actor)
  actor:SetAttribute("Phase2Triggered", true)
  actor:SetAttribute("MainPhaseIntroActive", true)
  Audio.StopMusic(actor, "Phase2Introduction")
  actor.Humanoid.Health = Config.Phase2HealthThreshold
  actor:SetAttribute("BossHealth", Config.Phase2HealthThreshold)
  actor:SetAttribute("Invulnerable", true)
  if shieldCasts[actor] then
    shieldCasts[actor]:Dispose()
  end
  actor:SetAttribute("PhaseTransitionInProgress", true)
  actor:SetAttribute("AIEnabled", false)
  actor:SetAttribute("ParryActive", false)
  actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
  actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
  Clones.CancelAll(actor)
  QTE.CancelForActor(actor, "Phase 2 transition")
  require(BossSystem.Combat.PassiveController).Stop(actor)
  require(BossSystem.Mechanics.Time.TimeEffectController).ClearOwner(actor)
  Effects.CancelOwner(actor, "Phase 2 transition")
  local core = Registry.For(actor, "P1CombatCore")
  core.Melee.Pose("Idle", 0.2)
  local generation = actor:GetAttribute("PhaseGeneration") or 0
  local pause = Config.Phase2PauseDuration
  local duration = pause
    + Story.Duration(Story.Phase2BeforeIdentity)
    + Story.Duration(Story.Phase2Identity)
    + Story.Duration(Story.Phase2Power)
    + Story.Duration(Story.Phase2Art)
    + Story.Duration(Story.Phase2AfterTime)
  local frozen = require(BossSystem.Encounter.ArenaPlacement).Validate(actor, core.Root.CFrame) or core.Root.CFrame
  core.Root.CFrame = frozen
  core.Root.AssemblyLinearVelocity = Vector3.zero
  local cast = Effects.NewCast(actor, "Phase2Transition", duration + 4)
  cast.TimeStopExempt = true
  phaseCasts[actor] = cast
  local completed = false
  local function current()
    return not cast.closed
      and actor.Parent
      and core.Humanoid.Health > 0
      and not actor:GetAttribute("EncounterEnded")
      and (actor:GetAttribute("PhaseGeneration") or 0) == generation
  end
  local function waitFor(seconds)
    local ends = cast:Now() + seconds
    while current() and cast:Now() < ends do
      game:GetService("RunService").Heartbeat:Wait()
    end
    return current()
  end
  cast:Step(function()
    if not current() then
      cast:Dispose()
      return false
    end
    core.Root.CFrame = frozen
    core.Root.AssemblyLinearVelocity = Vector3.zero
    return true
  end)
  cast.OnDispose = function()
    if phaseCasts[actor] ~= cast then
      return
    end
    phaseCasts[actor] = nil
    if not actor.Parent or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
      return
    end
    actor:SetAttribute("PhaseTransitionInProgress", false)
    actor:SetAttribute("MainPhaseIntroActive", false)
    clearShieldGateAttack(actor)
    actor:SetAttribute("Invulnerable", false)
    actor:SetAttribute("ExecutionLocked", false)
    actor:SetAttribute("PhaseTitleOverride", nil)
    if not completed then
      actor:SetAttribute("Phase2Triggered", false)
      api.ResetLighting(actor)
    end
    if core.Humanoid.Health > 0 and not actor:GetAttribute("EncounterEnded") then
      actor:SetAttribute("AIEnabled", true)
      actor:SetAttribute("AttackState", "Idle")
      actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.35)
      core.Melee.Pose("Idle", 0.2)
      require(BossSystem.Combat.PassiveController).Start(actor, core.Melee.GetTarget)
    end
  end
  task.spawn(function()
    local ok, err = xpcall(function()
      if not waitFor(pause) then
        return
      end
      local options = { Valid = current, Wait = waitFor, Prefix = "Phase2" }
      if
        not Story.Play(actor, Story.Phase2BeforeIdentity, options)
        or not Story.Play(actor, Story.Phase2Identity, options)
      then
        return
      end
      actor:SetAttribute("IdentityRevealed", true)
      actor:SetAttribute("PhaseTitleOverride", "alterGolden, The True Imaginator")
      if not Story.Play(actor, Story.Phase2Power, options) or not Story.Play(actor, Story.Phase2Art, options) then
        return
      end
      actor:SetAttribute("PhaseTitleOverride", "alterGolden, Time Manipulator")
      goldenSky(actor)
      if not Story.Play(actor, Story.Phase2AfterTime, options) then
        return
      end
      actor:SetAttribute("Phase", 2)
      actor:SetAttribute("MaxShield", Config.Phase2ShieldMaxHealth)
      actor:SetAttribute("Shield", Config.Phase2ShieldMaxHealth)
      actor:SetAttribute("ShieldBroken", false)
      actor:SetAttribute("Defense", 0)
      actor:SetAttribute("UnstoppableDisabled", false)
      local glow = actor:FindFirstChild("ShieldGlow")
      if glow then
        glow.Enabled = true
      end
      actor:SetAttribute("Phase2StartedAt", workspace:GetServerTimeNow())
      Audio.Phase(actor, 2)
      completed = true
      cast:Dispose()
    end, debug.traceback)
    if not ok then
      warn("Phase 2 transition: " .. tostring(err))
    end
    if not cast.closed then
      cast:Dispose()
    end
  end)
  return true
end

function api.BeginPhase3(actor, target)
  if (actor:GetAttribute("Shield") or 1) <= 0 and not Phase3Intro.Active(actor) then
    Phase25.Cancel(actor, "Phase 3 transformation")
  end
  return Phase3Intro.Begin(actor, target)
end

function api.BeginPhase35(actor)
 local h = actor:FindFirstChildOfClass("Humanoid")
 local shield = actor:GetAttribute("Shield") or 0
 if not actor.Parent or not h or h.Health <= 0 or actor:GetAttribute("EncounterEnded")
  or actor:GetAttribute("Phase") ~= 3 or actor:GetAttribute("Phase35Triggered")
  or shield <= 0 or shield > Config.Phase35ShieldThreshold then return false end
 actor:SetAttribute("Phase35Triggered", true)
 actor:SetAttribute("Phase", 3.5)
 actor:SetAttribute("PhaseTransitionInProgress", true)
 actor:SetAttribute("AIEnabled", false)
 actor:SetAttribute("Invulnerable", true)
 actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
 actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
 local generation = actor:GetAttribute("PhaseGeneration")
 require(BossSystem.Combat.PassiveController).Stop(actor)
 require(BossSystem.Mechanics.Reality.RealityController).Cancel(actor)
 Clones.CancelAll(actor, "Phase 3.5")
 Effects.CancelOwner(actor, "Phase 3.5")
 Status.ClearProjectileDarknessFor(actor)
 clearShieldGateAttack(actor)
 actor:SetAttribute("AttackState", "Phase 3.5: the real illusion")
 local root = actor.HumanoidRootPart
 local frame = root.CFrame
 local cast = Effects.NewCast(actor, "Phase35Transition", Story.Duration(Story.Phase35) + 2)
 cast.TimeStopExempt = true
 phaseCasts[actor] = cast
 local function current()
  return not cast.closed and actor.Parent and h.Health > 0 and not actor:GetAttribute("EncounterEnded")
   and actor:GetAttribute("PhaseGeneration") == generation and actor:GetAttribute("Phase") == 3.5
 end
 cast:Step(function()
  if not current() then cast:Dispose(); return false end
  root.CFrame = frame
  root.AssemblyLinearVelocity = Vector3.zero
  return true
 end)
 cast.OnDispose = function()
  if phaseCasts[actor] ~= cast then return end
  phaseCasts[actor] = nil
  if not actor.Parent or actor:GetAttribute("PhaseGeneration") ~= generation then return end
  actor:SetAttribute("PhaseTransitionInProgress", false)
  actor:SetAttribute("Invulnerable", false)
  clearShieldGateAttack(actor)
  if h.Health > 0 and not actor:GetAttribute("EncounterEnded") then
   actor:SetAttribute("AIEnabled", true)
   actor:SetAttribute("AttackState", "Idle")
   actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.35)
   require(BossSystem.Combat.PassiveController).Start(actor, Registry.For(actor,"P1CombatCore").Melee.GetTarget)
  end
 end
 actor:SetAttribute("Phase35StartedAt", workspace:GetServerTimeNow())
 task.spawn(function()
  local ok, err = xpcall(function() Story.Play(actor, Story.Phase35, { Valid = current, Prefix = "Phase35" }) end, debug.traceback)
  if not ok then warn("Phase 3.5: " .. tostring(err)) end
  cast:Dispose()
 end)
 return true
end

 
 
function api.BeginPhase4(actor, target)
  local h = actor:FindFirstChildOfClass("Humanoid")
  if
    not actor.Parent
    or not h
    or h.Health <= 0
    or actor:GetAttribute("EncounterEnded")
    or actor:GetAttribute("IsGoldenClone")
    or actor:GetAttribute("IsClone")
    or math.floor(actor:GetAttribute("Phase") or 1) ~= 3
    or (actor:GetAttribute("Shield") or 1) > 0
    or actor:GetAttribute("Phase4Triggered")
  then
    return false
  end
  actor:SetAttribute("Phase4Triggered", true)
  actor:SetAttribute("MainPhaseIntroActive", true)
  Audio.StopMusic(actor, "Phase4Introduction")
  actor:SetAttribute("Phase4TransitionInProgress", true)
  actor:SetAttribute("PhaseTransitionInProgress", true)
  actor:SetAttribute("Invulnerable", true)
  actor:SetAttribute("AIEnabled", false)
  actor:SetAttribute("AttackInProgress", false)
  actor:SetAttribute("ParryActive", false)
  actor:SetAttribute("ActiveAttackToken", nil)
  actor:SetAttribute("Phase4ComboActive", false)
  actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
  actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
  local generation = actor:GetAttribute("PhaseGeneration") or 0
  local passives = require(BossSystem.Combat.PassiveController)
  passives.Stop(actor)
  require(BossSystem.Mechanics.Reality.RealityController).Cancel(actor)
  Phase25.Cancel(actor, "Phase 4")
  Clones.CancelAll(actor, "Phase 4")
  QTE.CancelForActor(actor, "Phase 4")
  require(BossSystem.Mechanics.Time.TimeEffectController).ClearOwner(actor)
  Effects.CancelOwner(actor, "Phase 4")
  Phase3Intro.ClearVisual(actor)
  Weapon.SetUnarmed(actor, false)
  actor:SetAttribute("Phase4LinkedActive", false)
  actor:SetAttribute("LinkedProtection", false)
  local carry = h.Health
  local lines = Story.Phase4After
  local cast = Effects.NewCast(actor, "Phase4ShortStory", Story.Duration(lines) + 2)
  phaseCasts[actor] = cast
  cast.TimeStopExempt = true
  local completed = false
  cast.OnDispose = function()
    if phaseCasts[actor] ~= cast then
      return
    end
    phaseCasts[actor] = nil
    if
      not actor.Parent
      or h.Health <= 0
      or actor:GetAttribute("EncounterEnded")
      or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
    then
      return
    end
    actor:SetAttribute("Phase4TransitionInProgress", false)
    actor:SetAttribute("MainPhaseIntroActive", false)
    actor:SetAttribute("PhaseTransitionInProgress", false)
    actor:SetAttribute("Invulnerable", false)
    actor:SetAttribute("AIEnabled", true)
    actor:SetAttribute("AttackInProgress", false)
    actor:SetAttribute("AttackState", "Idle")
    if not completed then
      actor:SetAttribute("Phase4Triggered", false)
    end
    actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + (Config.Phase4NormalAttackInterval or 0.6))
    if completed then
      passives.Start(actor, Registry.For(actor, "P1CombatCore").Melee.GetTarget)
    end
  end
  local function valid()
    return not cast.closed
      and actor.Parent
      and h.Health > 0
      and not actor:GetAttribute("EncounterEnded")
      and (actor:GetAttribute("PhaseGeneration") or 0) == generation
  end
  task.spawn(function()
    local ok, reason = xpcall(function()
      actor:SetAttribute("AttackState", "Phase 4: beyond illusion")
      if not Story.Play(actor, lines, { Prefix = "Phase4", Valid = valid }) or not valid() then
        return
      end
      actor:SetAttribute("Phase", 4)
      actor:SetAttribute("PhaseTitleOverride", Config.Phase4Title)
      h.DisplayName = Config.Phase4Title or actor.Name
      h.Health = carry
      actor:SetAttribute("BossHealth", carry)
      local shield = math.max(0, Config.Phase4ShieldMaxHealth or 2500)
      actor:SetAttribute("MaxShield", shield)
      actor:SetAttribute("Shield", shield)
      actor:SetAttribute("ShieldBroken", shield <= 0)
      actor:SetAttribute("Defense", 0)
      actor:SetAttribute("UnstoppableDisabled", true)
      actor:SetAttribute("ShieldDamageLocked", false)
      actor:SetAttribute("ExecutionLocked", false)
      actor:SetAttribute("CurrentAttackFile", "Idle")
      actor:SetAttribute("CurrentSkill", nil)
      local glow = actor:FindFirstChild("ShieldGlow")
      if glow then
        glow.Enabled = shield > 0
      end
      actor:SetAttribute("Phase4StartedAt", workspace:GetServerTimeNow())
      Registry.For(actor, "P1CombatCore").Melee.Pose("Idle", 0.2)
      Audio.Phase(actor, 4)
      completed = true
    end, debug.traceback)
    if not ok then
      warn("Phase 4 transition: " .. tostring(reason))
    end
    if not cast.closed then
      cast:Dispose()
    end
  end)
  return true
end

 
 
function api.BeginPhase45(actor)
  if Difficulty.FinalPhase(actor) < 4.5 then return false end
  local h = actor:FindFirstChildOfClass("Humanoid")
  if
    not actor.Parent
    or not h
    or h.Health <= 0
    or actor:GetAttribute("EncounterEnded")
    or actor:GetAttribute("IsGoldenClone")
    or actor:GetAttribute("IsClone")
    or actor:GetAttribute("Phase") ~= 4
    or actor:GetAttribute("Phase45Triggered")
    or actor:GetAttribute("Phase4TransitionInProgress")
    or h.Health > (Config.Phase45HealthThreshold or 0)
  then
    return false
  end
  actor:SetAttribute("Phase45Triggered", true)
  actor:SetAttribute("Phase", 4.5)
  actor:SetAttribute("PhaseTransitionInProgress", true)
  actor:SetAttribute("AIEnabled", false)
  actor:SetAttribute("Invulnerable", true)
  actor:SetAttribute("AttackInProgress", false)
  actor:SetAttribute("ActiveAttackToken", nil)
  actor:SetAttribute("Phase4ComboActive", false)
  actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
  actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
  local generation = actor:GetAttribute("PhaseGeneration")
  local passives = require(BossSystem.Combat.PassiveController)
  passives.Stop(actor)
  Clones.CancelAll(actor, "Phase 4.5")
  Effects.CancelOwner(actor, "Phase 4.5")
  Status.ClearProjectileDarknessFor(actor)
  clearShieldGateAttack(actor)
  actor:SetAttribute("AttackState", "Phase 4.5: crimson bloom")
  local root = actor.HumanoidRootPart
  local frame = root.CFrame
  local lines = Story.Phase45 or {}
  local duration = math.max(#lines > 0 and Story.Duration(lines) or 0, Config.Phase45TransitionDuration or 2.6)
  local cast = Effects.NewCast(actor, "Phase45Transition", duration + 2)
  cast.TimeStopExempt = true
  phaseCasts[actor] = cast
  local function current()
    return not cast.closed
      and actor.Parent
      and h.Health > 0
      and not actor:GetAttribute("EncounterEnded")
      and actor:GetAttribute("PhaseGeneration") == generation
      and actor:GetAttribute("Phase") == 4.5
  end
  cast:Step(function()
    if not current() then
      cast:Dispose()
      return false
    end
    root.CFrame = frame
    root.AssemblyLinearVelocity = Vector3.zero
    return true
  end)
  cast.OnDispose = function()
    if phaseCasts[actor] ~= cast then
      return
    end
    phaseCasts[actor] = nil
    if not actor.Parent or actor:GetAttribute("PhaseGeneration") ~= generation then
      return
    end
    actor:SetAttribute("PhaseTransitionInProgress", false)
    actor:SetAttribute("Invulnerable", false)
    clearShieldGateAttack(actor)
    if h.Health > 0 and not actor:GetAttribute("EncounterEnded") then
      actor:SetAttribute("AIEnabled", true)
      actor:SetAttribute("AttackState", "Idle")
      actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.35)
      passives.Start(actor, Registry.For(actor, "P1CombatCore").Melee.GetTarget)
    end
  end
  local title = Config.Phase45Title or Config.Phase4Title
  actor:SetAttribute("PhaseTitleOverride", title)
  h.DisplayName = title or h.DisplayName
  actor:SetAttribute("Phase45StartedAt", workspace:GetServerTimeNow())
  local okVisual, visualErr = pcall(function()
    require(BossSystem.Phases.Phase45Transition).Play(actor, cast, duration)
  end)
  if not okVisual then
    warn("Phase 4.5 visuals: " .. tostring(visualErr))
  end
  task.spawn(function()
    local started = os.clock()
    local ok, err = xpcall(function()
      if #lines > 0 then
        Story.Play(actor, lines, { Valid = current, Prefix = "Phase45" })
      end
      while current() and os.clock() - started < duration do
        task.wait(0.05)
      end
    end, debug.traceback)
    if not ok then
      warn("Phase 4.5: " .. tostring(err))
    end
    cast:Dispose()
  end)
  return true
end

 
 
 
 
function api.BeginPhase5(actor)
  if Difficulty.FinalPhase(actor) < 5 then return false end
  local h = actor:FindFirstChildOfClass("Humanoid")
  if
    not actor.Parent
    or not h
    or h.Health <= 0
    or actor:GetAttribute("EncounterEnded")
    or actor:GetAttribute("IsGoldenClone")
    or actor:GetAttribute("IsClone")
    or math.floor(tonumber(actor:GetAttribute("Phase")) or 0) ~= 4
    or actor:GetAttribute("Phase5Triggered")
    or actor:GetAttribute("Phase4TransitionInProgress")
    or h.Health > (Config.Phase5HealthThreshold or 0)
  then
    return false
  end
   
  local previous = phaseCasts[actor]
  actor:SetAttribute("Phase5Triggered", true)
  actor:SetAttribute("Phase45Triggered", true)
  actor:SetAttribute("Phase", 5)
  actor:SetAttribute("PhaseTransitionInProgress", true)
  actor:SetAttribute("AIEnabled", false)
  actor:SetAttribute("Invulnerable", true)
  actor:SetAttribute("AttackInProgress", false)
  actor:SetAttribute("ActiveAttackToken", nil)
  actor:SetAttribute("Phase4ComboActive", false)
  actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
  actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
  local generation = actor:GetAttribute("PhaseGeneration")
  if previous and not previous.closed then previous:Dispose() end
  local passives = require(BossSystem.Combat.PassiveController)
  passives.Stop(actor)
  Clones.CancelAll(actor, "Phase 5")
  Effects.CancelOwner(actor, "Phase 5")
  Status.ClearProjectileDarknessFor(actor)
  clearShieldGateAttack(actor)
  actor:SetAttribute("AttackState", "Phase 5: ascension")
  local root = actor.HumanoidRootPart
  local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
  local Placement = require(BossSystem.Encounter.ArenaPlacement)
  local anchored = root.Anchored

   
  local frame = root.CFrame
  local bounds = Placement.GetBounds()
  if bounds then
    local core = Registry.For(actor, "P1CombatCore")
    local center = Placement.GroundPoint(bounds.Frame.Position, { Clamp = true }) or bounds.Frame.Position
    local floorRoot = core.FloorY(center + Vector3.new(0, 8, 0), core.Params())
    if floorRoot then
      local position = Vector3.new(center.X, floorRoot, center.Z)
      local look = position + root.CFrame.LookVector * Vector3.new(1, 0, 1)
      local best
      for _, char in ipairs(core.Characters()) do
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and (not best or (hrp.Position - position).Magnitude < (best - position).Magnitude) then best = hrp.Position end
      end
      if best and (Vector3.new(best.X, 0, best.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude > 0.5 then
        look = Vector3.new(best.X, position.Y, best.Z)
      end
      frame = CFrame.lookAt(position, look)
      frame = Placement.Validate(actor, frame, { Margin = 8 }) or frame
    end
  end
  Audio.Emit(actor, "TeleportWarp", root)
  actor:PivotTo(frame)
  Time.SetAnchored(root, true)

  local before = Story.Phase5Before or {}
  local after = Story.Phase5After or {}
   
  local Dialogue = require(BossSystem.Encounter.DialogueScripts)
  local function spoken(set)
    local list = {}
    for i, text in ipairs(set) do list[i] = Dialogue.Translate(text, actor) end
    return list
  end
  local charge = math.max(#before > 0 and Story.Duration(spoken(before)) + 0.4 or 0, Config.Phase5ChargeDuration or 5.5)
  local burst = Config.Phase5BurstDuration or 2
  local reveal = math.max(#after > 0 and Story.Duration(spoken(after)) + 0.9 or 0, Config.Phase5RevealDuration or 3)
  local duration = charge + burst + reveal
  local cast = Effects.NewCast(actor, "Phase5Transition", duration + 4)
  cast.TimeStopExempt = true
  phaseCasts[actor] = cast
  local function current()
    return not cast.closed
      and actor.Parent
      and h.Health > 0
      and not actor:GetAttribute("EncounterEnded")
      and actor:GetAttribute("PhaseGeneration") == generation
      and actor:GetAttribute("Phase") == 5
  end
  cast:Step(function()
    if not current() then
      cast:Dispose()
      return false
    end
    return true
  end)
  local Transition = require(BossSystem.Phases.Phase5Transition)
  cast.OnDispose = function()
    if phaseCasts[actor] ~= cast then
      return
    end
    phaseCasts[actor] = nil
    if not actor.Parent or actor:GetAttribute("PhaseGeneration") ~= generation then
      return
    end
     
    pcall(Transition.ApplyForm, actor)
    local title = Config.Phase5Title or Config.Phase45Title
    actor:SetAttribute("PhaseTitleOverride", title)
    h.DisplayName = title or h.DisplayName
    local ground = Placement.Validate(actor, frame, { Margin = 8 }) or frame
    root.CFrame = ground
    root.AssemblyLinearVelocity = Vector3.zero
    Time.SetAnchored(root, anchored)
    actor:SetAttribute("PhaseTransitionInProgress", false)
    actor:SetAttribute("Invulnerable", false)
    clearShieldGateAttack(actor)
    if h.Health > 0 and not actor:GetAttribute("EncounterEnded") then
      Registry.For(actor, "P1CombatCore").Melee.Pose("Idle", 0.4)
      actor:SetAttribute("AIEnabled", true)
      actor:SetAttribute("AttackState", "Idle")
      actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.6)
      passives.Start(actor, Registry.For(actor, "P1CombatCore").Melee.GetTarget)
    end
  end
  actor:SetAttribute("Phase5StartedAt", workspace:GetServerTimeNow())
  local token = game:GetService("HttpService"):GenerateGUID(false)
  local okVisual, visualErr = pcall(function()
    Transition.Play(actor, cast, {
      Charge = charge, Burst = burst, Reveal = reveal, Frame = frame, Token = token,
      Title = Config.Phase5Title,
      OnReveal = function()
        if not current() then return end
        local title = Config.Phase5Title or Config.Phase45Title
        actor:SetAttribute("PhaseTitleOverride", title)
        h.DisplayName = title or h.DisplayName
      end,
    })
  end)
  if not okVisual then
    warn("Phase 5 visuals: " .. tostring(visualErr))
  end
  task.spawn(function()
    local started = os.clock()
    local ok, err = xpcall(function()
      if #before > 0 then
        Story.Play(actor, before, { Valid = current, Prefix = "Phase5" })
      end
      while current() and os.clock() - started < charge + burst do
        task.wait(0.05)
      end
      if #after > 0 and current() then
        Story.Play(actor, after, { Valid = current, Prefix = "Phase5After" })
      end
      while current() and os.clock() - started < duration do
        task.wait(0.05)
      end
    end, debug.traceback)
    if not ok then
      warn("Phase 5: " .. tostring(err))
    end
    if not cast.closed then cast:Dispose() end
  end)
  return true
end

 
 
function api.Recover(actor)
  local h = actor and actor:FindFirstChildOfClass("Humanoid")
  if not actor or not actor.Parent or not h or h.Health <= 0 or actor:GetAttribute("EncounterEnded") then
    return false
  end
  local phase = actor:GetAttribute("Phase") or 1
  local intro = Phase3Intro.Active(actor)
  if intro and intro:IsActive() then
    return true
  end
  if intro then
    Phase3Intro.Cancel(actor, "Lost transition ownership")
  end
  local shield = shieldCasts[actor]
  if shield and not shield.closed then
    return true
  end
  local transition = phaseCasts[actor]
  if transition and not transition.closed then
    return true
  end
  local phase15 = Registry.For(actor, "P15Transition")
  if phase15.IsActive and phase15.IsActive() or Phase25.IsActive(actor) then
    return true
  end
  if actor:GetAttribute("Phase15TransitionActive") then
    actor:SetAttribute("Phase15TransitionActive", false)
  end
  if
    actor:GetAttribute("Phase25TransitionInProgress")
    or actor:GetAttribute("LastMinuteActive")
    or actor:GetAttribute("ShieldDamageLocked") and phase == 2.5
  then
     
     
     
    local collapse = actor:GetAttribute("LastMinuteActive") or actor:GetAttribute("ShieldDamageLocked")
    if collapse and phase == 2.5 and not actor:GetAttribute("LastMinuteCompleted") then
      return Phase25.RecoverLastMinute(actor, "Expired temporal transition lease")
    end
    Phase25.Cancel(actor, "Expired temporal transition lease")
    actor:SetAttribute("Phase25TransitionInProgress", false)
    actor:SetAttribute("TransitionKeepsTemporal", false)
    actor:SetAttribute("LastMinuteActive", false)
    actor:SetAttribute("ShieldDamageLocked", false)
    actor:SetAttribute("LastMinuteAttackMultiplier", 1)
    actor:SetAttribute("LastMinuteEndsAt", 0)
    if collapse and phase == 2.5 then
      actor:SetAttribute("LastMinuteUsed", true)
      actor:SetAttribute("Shield", 0)
      workspace:SetAttribute("LastMinuteActive", false)
      workspace:SetAttribute("LastMinuteEndsAt", 0)
      return api.BeginPhase3(actor) ~= false
    end
  end
  if
    actor:GetAttribute("PhaseTransitionInProgress")
    or actor:GetAttribute("Phase3IntroActive")
    or actor:GetAttribute("AIEnabled") == false and actor:GetAttribute("AttackState") ~= "Entrance"
  then
    actor:SetAttribute("PhaseTransitionInProgress", false)
    actor:SetAttribute("Phase3IntroActive", false)
    actor:SetAttribute("Phase4TransitionInProgress", false)
    actor:SetAttribute("ShieldBreakInProgress", false)
    actor:SetAttribute("AttackInProgress", false)
    actor:SetAttribute("Invulnerable", false)
    actor:SetAttribute("ExecutionLocked", false)
    actor:SetAttribute("Phase3GravityActive", false)
    actor:SetAttribute("AIEnabled", true)
    if phase < 3 then
      actor:SetAttribute("Phase3Triggered", false)
    end
    actor:SetAttribute("AttackState", "Idle")
    actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.15)
    actor:SetAttribute("TransitionRecoveredAt", workspace:GetServerTimeNow())
    require(BossSystem.Combat.PassiveController).Start(actor, Registry.For(actor, "P1CombatCore").Melee.GetTarget)
  end
  if phase < 2 and (actor:GetAttribute("Shield") or 1) <= 0
    and (actor:GetAttribute("ShieldCloneGateCompletedAt") or 0) <= 0 then
    return api.ShieldBroken(actor)
  end
  if (phase == 2 or phase == 2.5) and (actor:GetAttribute("Shield") or 1) <= 0 then
    return api.BeginPhase3(actor) ~= false
  end
  if phase == 3 and api.BeginPhase35(actor) then return true end
  if math.floor(phase) == 3 and (actor:GetAttribute("Shield") or 1) <= 0 then
    return api.BeginPhase4(actor)
  end
  if phase == 4 and api.BeginPhase45(actor) then return true end
  if math.floor(phase) == 4 and api.BeginPhase5(actor) then return true end
  if
    phase < 2
    and actor:GetAttribute("ShieldBroken")
    and (actor:GetAttribute("ShieldCloneGateCompletedAt") or 0) > 0
  then
    return api.BeginPhase2(actor)
  end
  return false
end

function api.Start(actor)
  if records[actor] then
    return
  end
  local record = {}
  records[actor] = record
  local phase = Registry.For(actor, "P15Transition")
  Phase25.Start(actor)
  local function shieldChanged()
    if (actor:GetAttribute("Phase") or 1) < 2 then
      phase.Begin()
    end
    Phase25.OnShieldChanged(actor)
    api.BeginPhase35(actor)
    if (actor:GetAttribute("Shield") or 1) == 0 then
      api.ShieldBroken(actor)
    end
  end
  local function healthChanged()
    if actor.Humanoid.Health <= 0 then
      if actor:GetAttribute("BossDefeatPresentationStarted") then
        return
      end
      actor:SetAttribute("BossDefeatPresentationStarted", true)
      actor:SetAttribute("EncounterEnded", true)
      Rewards.AwardEncounter(actor)
      Clones.CancelAll(actor)
      QTE.CancelForActor(actor, "Boss ended")
      Phase25.Cancel(actor, "Boss ended")
      Phase3Intro.Cancel(actor, "Boss ended")
      Phase3Intro.ClearVisual(actor)
      actor:SetAttribute("AIEnabled", false)
      actor:SetAttribute("Invulnerable", true)
      actor:SetAttribute("ParryActive", false)
      actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
      actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
      require(BossSystem.Combat.PassiveController).Stop(actor)
      require(BossSystem.Mechanics.Time.TimeEffectController).ClearOwner(actor)
      Effects.CancelOwner(actor, "Boss defeated")
      Registry.Release(actor)
      require(BossSystem.Boss.BossLocomotion).Release(actor)
      actor:SetAttribute("AttackInProgress", false)
      actor:SetAttribute("ExecutionLocked", false)
      actor:SetAttribute("PhaseTransitionInProgress", false)
      actor:SetAttribute("AttackState", "Defeated")
      require(BossSystem.Presentation.CharacterEffects).BossDeath(actor, function()
        local victory = Difficulty.Victory(actor)
        require(BossSystem.Combat.DamageTracker).Flush()
        workspace:SetAttribute("BossVictoryTitle", victory.Title)
        workspace:SetAttribute("BossVictorySubtitle", victory.Subtitle)
        workspace:SetAttribute("BossVictoryDifficulty", Difficulty.Id(actor))
        workspace:SetAttribute("BossEncounterWon", true)
        local remote = game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
        if remote then
          remote:FireAllClients("BossVictory",{Title=victory.Title,Subtitle=victory.Subtitle,Difficulty=actor:GetAttribute("EncounterDifficulty")})
        end
      end)
    elseif
      actor:GetAttribute("ShieldBroken")
      and actor.Humanoid.Health <= Config.Phase2HealthThreshold
      and (actor:GetAttribute("Phase") or 1) < 2
    then
      actor.Humanoid.Health = Config.Phase2HealthThreshold
      api.BeginPhase2(actor)
    end
  end
  local function clean()
    if not records[actor] then
      return
    end
    records[actor] = nil
    Clones.CancelAll(actor)
    QTE.CancelForActor(actor, "Boss removed")
    Phase25.Cancel(actor, "Boss removed")
    if shieldCasts[actor] then
      shieldCasts[actor]:Dispose()
    end
    if phaseCasts[actor] then
      phaseCasts[actor]:Dispose()
    end
    Phase3Intro.Cancel(actor, "Boss removed")
    Phase3Intro.ClearVisual(actor)
    for _, connection in ipairs(record) do
      connection:Disconnect()
    end
  end
  table.insert(record, actor:GetAttributeChangedSignal("Shield"):Connect(shieldChanged))
  table.insert(
    record,
    actor:GetAttributeChangedSignal("EncounterEnded"):Connect(function()
      if actor:GetAttribute("EncounterEnded") then
        Phase25.Cancel(actor, "Encounter ended")
        if shieldCasts[actor] then
          shieldCasts[actor]:Dispose()
        end
        if phaseCasts[actor] then
          phaseCasts[actor]:Dispose()
        end
        Phase3Intro.Cancel(actor, "Encounter ended")
        Phase3Intro.ClearVisual(actor)
      end
    end)
  )
  table.insert(record, actor.Humanoid.HealthChanged:Connect(healthChanged))
  table.insert(record, actor.Destroying:Connect(clean))
  shieldChanged()
end
return api

-- Reality Disorderer (game pass class). Two floating hands at the shoulders, attack-proof diamonds, a team save point and one hidden combo.
-- The server here owns rules and damage only. Every visual is drawn on the clients by ReplicatedStorage.VFXEngine.Effects.Disorderer.
-- Tuning numbers live in ClassConfig.Classes.Disorderer. Everything damaging goes through S.HitBoss.
local Players = game:GetService("Players")
local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Wall = require(BossSystem.Combat.DisorderWall)
local D = ClassConfig.Classes.Disorderer
local MAG, CYAN = D.Color, D.Color2
local K = {}
local rng = Random.new()

local function send(stage, data) Net.Send("Disorderer", stage, data) end
local function encounter() return require(BossSystem.Players.PlayerEncounter) end
local serial = 0
local function nextId() serial += 1 return serial end

-- must match HAND_REST in the client effect
local function handPos(char, side)
  return (char.HumanoidRootPart.CFrame * CFrame.new(side * 6.4, 3.4, 3.8)).Position
end
local function flatDistance(a, b)
  local d = a - b
  return Vector3.new(d.X, 0, d.Z).Magnitude
end
local function groundAt(S, char, position)
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  params.RespectCanCollide = true
  local ignore = { char, workspace:FindFirstChild("GoldenCombatEffects") }
  local fx = workspace:FindFirstChild("ClassEffects")
  if fx then table.insert(ignore, fx) end
  for _, target in ipairs(S.Targets()) do table.insert(ignore, target) end
  for _, other in ipairs(Players:GetPlayers()) do
    if other.Character then table.insert(ignore, other.Character) end
  end
  params.FilterDescendantsInstances = ignore
  local hit = workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -300, 0), params)
  return hit and hit.Position or position - Vector3.new(0, 3, 0)
end

local function setGlitch(S, char, st, n)
  n = math.clamp(n, 0, D.M1.GlitchMax)
  st.Data.Glitch = n
  char:SetAttribute("DisorderGlitch", n)
  if n <= 0 then
    if S.HasBuff(char, "Glitch") then S.Unbuff(char, "Glitch") end
    S.RemoveStatBuff(char, "GlitchSelf")
    char:SetAttribute("ClassStatusText_Glitch", nil)
    return
  end
  S.Buff(char, "Glitch", D.M1.GlitchDuration)
  char:SetAttribute("ClassStatusText_Glitch", "x" .. n)
end
local function pushGlitchBuffs(S, char, st)
  local n = st.Data.Glitch or 0
  if n <= 0 then return end
  S.StatBuff(char, "GlitchSelf", 1.2, { Attack = 1 + D.M1.GlitchSelf * n })
  for _, ally in ipairs(S.Allies(false, char)) do
    S.StatBuff(ally, "GlitchTeam:" .. st.Player.UserId, 1.2, { Attack = 1 + D.M1.GlitchTeam * n })
  end
end
-- the boss wears the corruption: the clients draw it from these two attributes
local function markBoss(S, target, stacks, seconds)
  target:SetAttribute("DisorderGlitchStacks", stacks)
  target:SetAttribute("DisorderGlitchUntil", math.max(target:GetAttribute("DisorderGlitchUntil") or 0, S.Now() + seconds))
end

local BUFFS = {
  { Name = "ATTACK UP", Mods = { Attack = 1.35 } },
  { Name = "DEFENSE UP", Mods = { Defense = 0.25 } },
  { Name = "SPEED UP", Mods = { Speed = 1.3 } },
  { Name = "REGEN UP", Mods = { HealthRegen = 3 } },
  { Name = "STAMINA UP", Mods = { StaminaRegen = 2 } },
  { Name = "HASTE", Mods = { AttackSpeed = 1.3 } },
  { Name = "RESTORED", Heal = 0.1 },
}
local function randomBuff(S, ally, source, seconds)
  local buff = BUFFS[rng:NextInteger(1, #BUFFS)]
  if buff.Heal then
    local h = ally:FindFirstChildOfClass("Humanoid")
    if h then h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * buff.Heal) end
  else
    S.StatBuff(ally, source .. buff.Name, seconds, buff.Mods)
  end
  return buff.Name
end

local DEBUFFS = {
  { "Bleed", "Dot" }, { "Hemorrhage", "Dot" }, { "Rupture", "Dot" }, { "Acid", "Dot" }, { "Decay", "Dot" }, { "Corruption", "Dot" },
  { "Frostbite", "Dot" }, { "TemporalWound", "Dot" }, { "ChainCurse", "Dot" },
  { "Vulnerability", "Vuln" }, { "DeathMark", "Vuln" },
  { "IllusionRot", "Weak" }, { "Blur", "Weak" },
  { "Fear", "Delay" }, { "JumpLock", "Delay" }, { "CooldownIncrease", "Delay" }, { "CooldownFreeze", "Delay" },
}
local function applyBossDebuff(S, char, target)
  local entry = DEBUFFS[rng:NextInteger(1, #DEBUFFS)]
  local name, kind = entry[1], entry[2]
  local seconds = D.V.DebuffTime
  local deadline = S.Now() + seconds
  target:SetAttribute("DisorderDebuff_" .. name, deadline)
  -- a debuff landing on one of his clones still shows on his own status row
  local boss = S.Boss()
  if boss and boss ~= target then boss:SetAttribute("DisorderDebuff_" .. name, deadline) end
  if kind == "Vuln" then
    target:SetAttribute("DisorderVulnUntil", deadline)
    target:SetAttribute("DisorderVulnMult", D.V.Vulnerable)
  elseif kind == "Weak" then
    target:SetAttribute("DisorderWeakUntil", deadline)
    target:SetAttribute("DisorderWeakMult", D.V.Weakened)
  elseif kind == "Delay" then
    if not tostring(target:GetAttribute("CurrentSkill") or ""):find("(Ultimate)", 1, true) then
      target:SetAttribute("NextAttackAt", math.max(target:GetAttribute("NextAttackAt") or 0, S.Now() + 1.4))
    end
  elseif kind == "Dot" then
    task.spawn(function()
      for _ = 1, math.floor(seconds * 2) do
        task.wait(0.5)
        if not S.Alive(target) then return end
        S.DotBoss(char, target, D.V.DotDamage, "DisorderDot")
      end
    end)
  end
  send("BossDebuff", { Target = target, Name = name })
end

local checkpoints = {}  -- keyed by player, so a Disorderer who dies can still load it after respawning
Players.PlayerRemoving:Connect(function(player) checkpoints[player] = nil end)
local function currentCheckpoint(player)
  local cp = checkpoints[player]
  if cp and cp.Sequence ~= workspace:GetAttribute("BossEntranceSequence") then
    checkpoints[player] = nil
    send("CheckpointClear", { Owner = player.UserId })
    return nil
  end
  return cp
end

local function setAimStream(char, st)
  local on = st.Data.Laser ~= nil or st.Data.CDown ~= nil
  char:SetAttribute("ClassAimStream", on or nil)
end
local function stopLaser(S, char, st)
  local laser = st.Data.Laser
  if not laser then return end
  st.Data.Laser = nil
  if S.HasBuff(char, "DisorderLaserSlow") then S.Unbuff(char, "DisorderLaserSlow") end
  setAimStream(char, st)
  S.Cooldown(char, "M1", D.M1.LaserCooldown)
  send("LaserEnd", { Id = laser.Id })
end
local function closeWindow(S, char, st)
  if st.Data.FWindow then
    st.Data.FWindow = nil
    if S.HasBuff(char, "MisplaceReady") then S.Unbuff(char, "MisplaceReady") end
    S.Cooldown(char, "F", D.F.Cooldown)
  end
end
local function endCast(S, char, st)
  st.Busy, st.Data.Casting = false, false
  for _, id in ipairs({ "Phasing", "Recovering" }) do
    if S.HasBuff(char, id) then S.Unbuff(char, id) end
  end
  if char.Parent then char:SetAttribute("TrueWarriorCinematic", nil) end
end

function K.Start(S, player, char, st)
  st.Data.Glitch, st.Data.Tick = 0, 0
  char:SetAttribute("DisorderGlitch", 0)
  if currentCheckpoint(player) then S.Buff(char, "Checkpoint", nil, {}) end
end
function K.Cleanup(S, char, st)
  st.Data.M1Down, st.Data.Laser, st.Data.CDown, st.Data.VDown = nil, nil, nil, nil
  send("Cancel", { Char = char })
  if char.Parent then
    char:SetAttribute("DisorderGlitch", nil)
    char:SetAttribute("ClassStatusText_Glitch", nil)
    char:SetAttribute("ClassAimStream", nil)
    char:SetAttribute("TrueWarriorCinematic", nil)
  end
end
function K.CancelActions(S, char, st, reason)
  st.Data.M1Down = nil
  stopLaser(S, char, st)
  if st.Data.CDown then
    st.Data.CDown = nil
    send("CubeCancel", { Char = char })
  end
  st.Data.VDown = nil
  setAimStream(char, st)
  if st.Data.Channel then
    st.Data.Channel = nil
    st.Busy = false
    if S.HasBuff(char, "DisorderCharge") then S.Unbuff(char, "DisorderCharge") end
    send("Cancel", { Char = char })
  end
  if st.Data.Casting then
    endCast(S, char, st)
    send("Cancel", { Char = char })
  end
end
function K.OnBuffEnded(S, char, st, id)
  if id == "Glitch" then
    st.Data.Glitch = 0
    char:SetAttribute("DisorderGlitch", 0)
    char:SetAttribute("ClassStatusText_Glitch", nil)
    S.RemoveStatBuff(char, "GlitchSelf")
  end
end
function K.Step(S, player, char, st, dt)
  if st.Data.FWindow and os.clock() >= st.Data.FWindow then closeWindow(S, char, st) end
  st.Data.Tick = (st.Data.Tick or 0) + dt
  if st.Data.Tick < 0.5 then return end
  st.Data.Tick = 0
  pushGlitchBuffs(S, char, st)
end

function K.OnHitBoss(S, char, st, target, tag)
  if tag ~= "DisorderBolt" and tag ~= "DisorderLaser" then return end
  if tag == "DisorderLaser" then
    st.Data.LaserStack = (st.Data.LaserStack or 0) + 1
    if st.Data.LaserStack % 3 ~= 0 then return end
  end
  setGlitch(S, char, st, (st.Data.Glitch or 0) + 1)
  markBoss(S, target, st.Data.Glitch, D.M1.GlitchDuration)
  if tag == "DisorderBolt" then
    local root = char.HumanoidRootPart
    local best, bestFraction
    for _, ally in ipairs(S.Allies(true)) do
      local h = ally:FindFirstChildOfClass("Humanoid")
      if h and h.Health > 0 and h.Health < h.MaxHealth and (ally.HumanoidRootPart.Position - root.Position).Magnitude <= D.M1.HealRange then
        local f = h.Health / h.MaxHealth
        if not bestFraction or f < bestFraction then best, bestFraction = ally, f end
      end
    end
    if best then
      local h = best:FindFirstChildOfClass("Humanoid")
      h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * D.M1.AllyHeal)
      S.FX.Beam(root.Position, best.HumanoidRootPart.Position, CYAN, 0.2, 0.15)
    end
  end
end

local function fireOrb(S, char, side, aim)
  local attack = S.NewAttack(char, "DisorderBolt")
  if not attack then return end
  local origin = handPos(char, side)
  local dir = C.AimDir3D(origin, aim, char.HumanoidRootPart.CFrame.LookVector)
  local id = nextId()
  send("Orb", { Char = char, Side = side, Id = id, Origin = origin, Dir = dir, Speed = D.M1.Speed, Range = D.M1.Range })
  task.spawn(function()
    local travelled, prev, last = 0, origin, os.clock()
    while travelled < D.M1.Range do
      task.wait()
      if not S.AttackValid(char, attack) then break end
      local t = os.clock()
      travelled = math.min(D.M1.Range, travelled + D.M1.Speed * (t - last))
      last = t
      local pos = origin + dir * travelled
      local target = C.SegmentTarget(S, prev, pos, D.M1.Radius)
      if target then
        attack.Origin = pos
        if S.HitBoss(char, target, D.M1.Damage, "DisorderBolt", attack) then S.Sound(char, "RangedImpact") end
        send("OrbHit", { Id = id, Pos = pos })
        return
      end
      prev = pos
    end
    send("OrbEnd", { Id = id })
  end)
end
local function startLaser(S, player, char, st)
  if st.Data.Laser or st.Data.Casting then return end
  local attack = S.NewAttack(char, "DisorderLaser")
  if not attack then return end
  local laser = { Id = nextId() }
  st.Data.Laser = laser
  setAimStream(char, st)
  S.Anim(char, "Stance")
  S.Sound(char, "RoyalFinalCharge")
  local function pick()
    local target = player:GetAttribute("ClassAutoAim") ~= false and S.AimTarget(char, st.Aim, D.M1.LaserRange) or nil
    local root = char.HumanoidRootPart
    return target, target and target.HumanoidRootPart.Position or st.Aim or (root.Position + root.CFrame.LookVector * D.M1.LaserRange)
  end
  local target, point = pick()
  send("LaserStart", { Char = char, Id = laser.Id, Target = target, Point = point, Converge = D.M1.LaserConverge })
  task.spawn(function()
    local started, nextTick, nextAim, lastTarget = os.clock(), os.clock() + D.M1.LaserConverge, 0, target
    while st.Data.Laser == laser do
      local elapsed = os.clock() - started
      if elapsed >= D.M1.LaserMax or not S.AttackValid(char, attack) then
        stopLaser(S, char, st)
        return
      end
      S.Buff(char, "DisorderLaserSlow", 0.35, { Speed = D.M1.LaserSpeed })
      local now = os.clock()
      if now >= nextAim or target ~= lastTarget then
        nextAim = now + 0.15
        target, point = pick()
        send("LaserAim", { Id = laser.Id, Target = target, Point = point })
        lastTarget = target
      end
      if now >= nextTick then
        nextTick = now + D.M1.LaserTick
        if target then
          local root = char.HumanoidRootPart
          attack.Origin = root.Position + root.CFrame.LookVector * 5 + Vector3.new(0, 1.2, 0)
          S.HitBoss(char, target, D.M1.LaserDamage, "DisorderLaser", attack)
        end
      end
      task.wait()
    end
  end)
end
local function m1Begin(S, player, char, st)
  if st.Data.M1Down or not S.Ready(char, "M1") then return end
  st.Data.M1Down = os.clock()
  local mark = st.Data.M1Down
  S.Cooldown(char, "M1", D.M1.Cooldown)
  S.Anim(char, "Cast")
  S.Sound(char, "RangedLaunch")
  fireOrb(S, char, 1, st.Aim)
  task.delay(0.07, function()
    if S.State(char) == st and S.CanAct(char) then fireOrb(S, char, -1, st.Aim) end
  end)
  task.delay(D.M1.HoldTime, function()
    if S.State(char) == st and st.Data.M1Down == mark and S.CanAct(char) then startLaser(S, player, char, st) end
  end)
end
local function m1End(S, char, st)
  st.Data.M1Down = nil
  stopLaser(S, char, st)
end

local function spawnDecoy(S, char, st, from)
  local id = nextId()
  send("DecoySpawn", { Char = char, Id = id, CFrame = from, Life = D.F.DecoyLife })
  task.spawn(function()
    local pos, started, last, nextSend = from.Position, os.clock(), os.clock(), 0
    while os.clock() - started < D.F.DecoyLife do
      task.wait()
      if S.State(char) ~= st and not S.Alive(char) then break end
      local now = os.clock()
      local dt, target, best = now - last, nil, nil
      last = now
      for _, candidate in ipairs(S.Targets()) do
        local d = flatDistance(candidate.HumanoidRootPart.Position, pos)
        if not best or d < best then target, best = candidate, d end
      end
      if target then
        if best <= D.F.DecoyFuse then break end
        local dir = C.Flat(target.HumanoidRootPart.Position - pos)
        if dir then pos += dir * math.min(D.F.DecoySpeed * dt, best) end
      end
      if now >= nextSend then
        nextSend = now + 0.2
        send("DecoyMove", { Id = id, Pos = pos })
      end
    end
    send("DecoyFuse", { Id = id })
    task.wait(0.22)  -- a beat of anticipation before the blast
    send("DecoyExplode", { Id = id, Pos = pos, Radius = D.F.DecoyRadius })
    S.Sound(char, "RangedImpact")
    local attack = S.NewAttack(char, "DisorderDecoy")
    if attack then
      attack.IgnoreSight = true
      attack.Origin = pos + Vector3.new(0, 2, 0)
      for _, target in ipairs(S.Targets()) do
        if flatDistance(target.HumanoidRootPart.Position, pos) <= D.F.DecoyRadius + 4 and math.abs(target.HumanoidRootPart.Position.Y - pos.Y) <= 18 then
          if S.HitBoss(char, target, D.F.DecoyDamage, "DisorderDecoy", attack) then
            markBoss(S, target, math.max(st.Data.Glitch or 0, 3), 3)
          end
        end
      end
    end
  end)
end

local function falter(S, player, char, st, cube)
  local H = D.Hidden
  local attack = S.NewAttack(char, "DisorderFalter")
  if not attack then return end
  attack.IgnoreSight = true
  cube.Flying, cube.Grabbed = false, true
  st.Data.Cube = nil
  closeWindow(S, char, st)
  st.Busy, st.Data.Casting = true, true
  local total = H.Ascend + H.Charge + H.Fall + H.After
  S.Buff(char, "Phasing", total + 0.5)
  S.Buff(char, "Recovering", total + 0.5, { Speed = 0 })
  char:SetAttribute("TrueWarriorCinematic", true)
  S.Cooldown(char, "C", H.Cooldown)
  S.Cooldown(char, "F", H.FCooldown)
  S.Sound(char, "RoyalFinalCharge")
  local root = char.HumanoidRootPart
  local ground = root.Position
  local boss = S.Boss()
  local dir = boss and C.Flat(boss.HumanoidRootPart.Position - ground) or C.Flat(root.CFrame.LookVector) or Vector3.zAxis
  local sky = ground + Vector3.new(0, H.Height, 0)
  S.Remote():FireClient(player, "TwinPath", { Face = dir, Steps = {
    { T = H.Ascend, To = sky, Ease = "out" },
    { T = H.Ascend + H.Charge + H.Fall + 0.2, To = sky },
    { T = total, To = ground, Ease = "in" },
  } })
  send("FalterStart", { Char = char, Id = cube.Id, From = cube.Pos, Sky = sky, Ground = ground, Dir = dir, Boss = boss,
    Ascend = H.Ascend, Charge = H.Charge, Fall = H.Fall, After = H.After, Radius = H.Radius })
  if boss then pcall(S.Stun, boss, total, char, attack) end
  task.spawn(function()
    local function hold(seconds)
      local ends = os.clock() + seconds
      while os.clock() < ends do
        if not S.AttackValid(char, attack) then return false end
        task.wait()
      end
      return S.AttackValid(char, attack)
    end
    local function stopped()
      if st.Data.Casting then
        endCast(S, char, st)
        send("Cancel", { Char = char })
      end
    end
    if not hold(H.Ascend + H.Charge) then stopped() return end
    S.Sound(char, "FallingCharge")
    local aimAt = boss and S.Alive(boss) and boss.HumanoidRootPart.Position or (ground + dir * 90)
    send("FalterRelease", { Char = char, Target = boss, Point = aimAt })
    if not hold(H.Fall) then stopped() return end
    local at = boss and S.Alive(boss) and boss.HumanoidRootPart.Position or aimAt
    S.Sound(char, "RoyalFinalImpact")
    S.Sound(char, "CataclysmSlam")
    S.FX.HQ.Shake(at, 400, 1.2, 2)
    send("FalterImpact", { Char = char, Pos = at, Radius = H.Radius })
    attack.Origin = at + Vector3.new(0, 6, 0)
    for _, target in ipairs(S.Targets()) do
      if flatDistance(target.HumanoidRootPart.Position, at) <= H.Radius then
        if S.HitBoss(char, target, H.Damage, "DisorderFalter", attack) then
          markBoss(S, target, D.M1.GlitchMax, 10)
        end
      end
    end
    hold(H.After)
    if st.Data.Casting then
      endCast(S, char, st)
      send("CastEnd", { Char = char })
    end
  end)
end
local function tryCombo(S, player, char, st, aim)
  local cube = st.Data.Cube
  if not cube or not cube.Flying or not aim or os.clock() - cube.At > D.Hidden.Window then return false end
  local from = char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)
  if (aim - from).Magnitude < 1 then return false end
  local far = from + (aim - from).Unit * 400
  if C.SegmentDistance(cube.Pos, from, far) > D.Hidden.AimRadius and (aim - cube.Pos).Magnitude > D.Hidden.AimRadius then return false end
  falter(S, player, char, st, cube)
  return true
end

local function misplace(S, player, char, st, aim, dir)
  if tryCombo(S, player, char, st, aim) then return end
  if os.clock() < (st.Data.FNext or 0) then return end
  local second = st.Data.FWindow ~= nil
  if not second and not S.Ready(char, "F") then return end
  local root = char.HumanoidRootPart
  if not S.SpendStamina(char, D.F.StaminaCost) then
    S.FX.Text(root.Position + Vector3.new(0, 3, 0), "NO STAMINA", CYAN)
    return
  end
  st.Data.FNext = os.clock() + 0.25
  if second then
    closeWindow(S, char, st)
  else
    st.Data.FWindow = os.clock() + D.F.Window
    S.Buff(char, "MisplaceReady", D.F.Window)
  end
  local ally = aim and S.AimedAlly(char, aim, D.F.Range)
  if ally and (ally.HumanoidRootPart.Position - aim).Magnitude > 9 then ally = nil end
  S.Anim(char, "Flash")
  S.Sound(char, "TeleportOut")
  local from = root.CFrame
  local old, landed = from.Position, nil
  if ally then
    local to = ally.HumanoidRootPart.CFrame
    char:PivotTo(to)
    ally:PivotTo(from)
    S.Buff(char, "Undying", D.F.IFrames, {})
    S.Buff(ally, "Undying", D.F.IFrames, {})
    landed = to.Position
  else
    local target = aim or (old + dir * 20)
    local flat = C.Flat(target - old) or dir
    local distance = math.min(D.F.Range, flatDistance(target, old))
    local dest = C.Path(S, char, flat, distance)
    landed = Vector3.new(dest.X, old.Y, dest.Z)
    char:PivotTo(CFrame.new(landed) * from.Rotation)
  end
  send("Teleport", { Char = char, From = old, To = landed })
  spawnDecoy(S, char, st, from)
end

local function deployZone(S, player, char, st)
  S.Cooldown(char, "C", D.C.Cooldown)
  S.Anim(char, "Stance")
  S.Sound(char, "CloneMaterialize")
  local root = char.HumanoidRootPart
  local ground = groundAt(S, char, root.Position)
  local center = ground + Vector3.new(0, 3, 0)  -- the diamond is widest at body height, so its floor outline is the real edge
  local zone = Wall.Add(center, D.C.ZoneRadius, D.C.ZoneUpper, D.C.ZoneLower, D.C.ZoneDuration)
  local id = nextId()
  send("ZoneOn", { Char = char, Id = id, Center = center, Radius = D.C.ZoneRadius, Upper = D.C.ZoneUpper, Lower = D.C.ZoneLower, Duration = D.C.ZoneDuration })
  task.spawn(function()
    local started, nextBuff = os.clock(), 0
    while os.clock() - started < D.C.ZoneDuration and workspace:GetAttribute("BossEncounterWon") ~= true do
      local inside = {}
      for _, ally in ipairs(S.Allies(true)) do
        if Wall.Contains(ally.HumanoidRootPart.Position) then
          table.insert(inside, ally)
          S.Buff(ally, "Redacted", 0.6, {})
        end
      end
      if os.clock() >= nextBuff then
        nextBuff = os.clock() + D.C.BuffInterval
        local shown
        for _, ally in ipairs(inside) do shown = randomBuff(S, ally, "Diamond:", D.C.BuffTime) end
        if shown then send("ZonePulse", { Id = id, Name = shown }) end
      end
      task.wait(0.2)
    end
    Wall.Remove(zone)
    send("ZoneOff", { Id = id })
  end)
end
local function throwCube(S, player, char, st)
  S.Cooldown(char, "C", D.C.CubeCooldown)
  local attack = S.NewAttack(char, "DisorderCube")
  if not attack then return end
  attack.IgnoreSight = true
  S.Anim(char, "Cast")
  S.Sound(char, "BlockLaunch")
  local root = char.HumanoidRootPart
  local origin = root.Position + root.CFrame.LookVector * 3.4 + Vector3.new(0, 1.2, 0)
  local dir = C.AimDir3D(origin, st.Aim, root.CFrame.LookVector)
  local cube = { Id = nextId(), Pos = origin, At = os.clock(), Flying = true }
  st.Data.Cube = cube
  send("CubeThrow", { Char = char, Id = cube.Id, Origin = origin, Dir = dir, Speed = D.C.CubeSpeed, Range = D.C.CubeRange })
  task.spawn(function()
    local travelled, prev, last = 0, origin, os.clock()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.RespectCanCollide = true
    local ignore = { char, workspace:FindFirstChild("GoldenCombatEffects") }
    for _, target in ipairs(S.Targets()) do table.insert(ignore, target) end
    params.FilterDescendantsInstances = ignore
    while travelled < D.C.CubeRange do
      task.wait()
      if not cube.Flying then return end
      local t = os.clock()
      travelled = math.min(D.C.CubeRange, travelled + D.C.CubeSpeed * (t - last))
      last = t
      local pos = origin + dir * travelled
      cube.Pos = pos
      local target = C.SegmentTarget(S, prev, pos, D.C.CubeHitRadius)
      local wall = workspace:Raycast(prev, pos - prev, params)
      if wall then cube.Pos = wall.Position end
      if target or wall then break end
      prev = pos
    end
    if not cube.Flying then return end
    cube.Flying = false
    st.Data.Cube = nil
    local at = cube.Pos
    send("CubeExplode", { Id = cube.Id, Pos = at, Radius = D.C.CubeRadius })
    S.Sound(char, "RangedImpact")
    if not S.AttackValid(char, attack) then return end
    attack.Origin = at + Vector3.new(0, 2, 0)
    for _, target in ipairs(S.Targets()) do
      if (target.HumanoidRootPart.Position - at).Magnitude <= D.C.CubeRadius + 5 then
        if S.HitBoss(char, target, D.C.CubeDamage, "DisorderCube", attack) then
          markBoss(S, target, math.max(st.Data.Glitch or 0, 4), 4)
        end
      end
    end
    S.FX.HQ.Shake(at, 110, 0.4, 0.9)
  end)
end
local function cBegin(S, player, char, st)
  if st.Data.CDown or not S.Ready(char, "C") then return end
  local down = { At = os.clock() }
  st.Data.CDown = down
  st.Data.CHeld = true
  setAimStream(char, st)
  task.delay(D.C.HoldTime, function()
    if st.Data.CDown == down and S.State(char) == st and S.CanAct(char) then
      down.Forging = true
      S.Anim(char, "Stance")
      S.Sound(char, "CrescentCharge")
      send("CubeCharge", { Char = char })
    end
  end)
end
local function cEnd(S, player, char, st)
  local down = st.Data.CDown
  if not down then return end
  st.Data.CDown = nil
  st.Data.CHeld = false
  setAimStream(char, st)
  if not S.Ready(char, "C") then
    if down.Forging then send("CubeCancel", { Char = char }) end
    return
  end
  if down.Forging then
    throwCube(S, player, char, st)
  else
    deployZone(S, player, char, st)
  end
end

local function saveCheckpoint(S, player, char, st)
  S.Sound(char, "CloneMaterialize")
  S.Anim(char, "Stance")
  local snap, marks = {}, {}
  for _, ally in ipairs(S.Allies(true)) do
    local p = Players:GetPlayerFromCharacter(ally)
    local h = ally:FindFirstChildOfClass("Humanoid")
    if p and h then
      local maxStamina = math.max(ally:GetAttribute("MaxStamina") or 100, 1)
      table.insert(snap, { UserId = p.UserId, CFrame = ally.HumanoidRootPart.CFrame, HealthFraction = h.Health / math.max(h.MaxHealth, 1),
        StaminaFraction = (ally:GetAttribute("Stamina") or 0) / maxStamina, Lives = p:GetAttribute("LivesRemaining") })
      table.insert(marks, { Pos = ally.HumanoidRootPart.Position, Name = p.DisplayName })
    end
  end
  checkpoints[player] = { Snap = snap, Marks = marks, Sequence = workspace:GetAttribute("BossEntranceSequence") }
  S.Buff(char, "Checkpoint", nil, {})
  send("CheckpointSet", { Owner = player.UserId, Marks = marks })
end
local function restoreOne(S, snap)
  local p = Players:GetPlayerByUserId(snap.UserId)
  if not p or p.Parent ~= Players or p:GetAttribute("ViewAsServer") or p:GetAttribute("ExecutionPending") then return end
  local ally = p.Character
  if encounter().IsDefeated(p) or not S.Alive(ally) then
    ally = encounter().CheckpointRestore(p, snap)
  end
  if not ally or not S.Alive(ally) or ally:GetAttribute("PickThePupilsCaptured") or ally.HumanoidRootPart.Anchored then return end
  local h = ally:FindFirstChildOfClass("Humanoid")
  -- a death since the checkpoint is undone even if they had already respawned
  if type(snap.Lives) == "number" and (p:GetAttribute("LivesRemaining") or 0) < snap.Lives then
    p:SetAttribute("LivesRemaining", snap.Lives)
    ally:SetAttribute("LivesRemaining", snap.Lives)
  end
  ally:PivotTo(snap.CFrame)
  ally.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
  h.Health = math.clamp(h.MaxHealth * snap.HealthFraction, 1, h.MaxHealth)
  local maxStamina = ally:GetAttribute("MaxStamina") or 100
  ally:SetAttribute("Stamina", math.clamp(maxStamina * snap.StaminaFraction, 0, maxStamina))
  S.Buff(ally, "Undying", 0.6, {})
end
local function reloadCheckpoint(S, player, char, st, cp)
  checkpoints[player] = nil
  if S.HasBuff(char, "Checkpoint") then S.Unbuff(char, "Checkpoint") end
  S.Cooldown(char, "V", D.V.Cooldown)
  S.Anim(char, "Flash")
  S.Sound(char, "TeleportIn")
  send("CheckpointReload", { Owner = player.UserId, Marks = cp.Marks })
  for _, snap in ipairs(cp.Snap) do task.spawn(restoreOne, S, snap) end
end
local function arenaGlitch(S, player, char, st)
  S.Cooldown(char, "V", D.V.GlitchCooldown)
  st.Data.Channel, st.Busy = true, true
  S.Buff(char, "DisorderCharge", D.V.Charge, { Speed = 0.35 })
  S.Anim(char, "Stance")
  S.Sound(char, "RoyalFinalCharge")
  send("ArenaCharge", { Char = char, Duration = D.V.Charge })
  local revision = st.ActionRevision
  task.spawn(function()
    task.wait(D.V.Charge)
    if S.State(char) ~= st or not st.Data.Channel or st.ActionRevision ~= revision or not S.CanAct(char) then return end
    st.Data.Channel, st.Busy = nil, false
    local center = char.HumanoidRootPart.Position
    S.Sound(char, "CataclysmSlam")
    S.FX.HQ.Shake(center, 300, 0.7, 1.4)
    send("ArenaGlitch", { Char = char, Center = groundAt(S, char, center), Duration = D.V.GlitchDuration })
    local started, nextBuff, nextDebuff = os.clock(), 0, 0
    while os.clock() - started < D.V.GlitchDuration and workspace:GetAttribute("BossEncounterWon") ~= true do
      local now = os.clock()
      if now >= nextBuff then
        nextBuff = now + D.V.BuffEvery
        for _, ally in ipairs(S.Allies(true)) do randomBuff(S, ally, "ArenaGlitch:", D.V.BuffTime) end
      end
      for _, target in ipairs(S.Targets()) do
        local attack = S.NewAttack(char, "DisorderArena")
        if attack then
          attack.IgnoreSight = true
          attack.Origin = target.HumanoidRootPart.Position
          if S.HitBoss(char, target, rng:NextNumber(D.V.MinDamage, D.V.MaxDamage), "DisorderArena", attack) then
            send("ArenaStrike", { Pos = target.HumanoidRootPart.Position + Vector3.new(0, 2, 0) })
          end
        end
        markBoss(S, target, D.M1.GlitchMax, 1)
      end
      if now >= nextDebuff then
        nextDebuff = now + D.V.DebuffEvery
        local victims = S.Targets()
        local boss = S.Boss()
        if boss and not table.find(victims, boss) then table.insert(victims, boss) end
        for _, target in ipairs(victims) do applyBossDebuff(S, char, target) end
      end
      task.wait(D.V.GlitchTick)
    end
  end)
end
local function vBegin(S, player, char, st)
  if st.Data.VDown or st.Data.Channel then return end
  local down = { At = os.clock() }
  st.Data.VDown = down
  task.delay(D.V.HoldTime, function()
    if st.Data.VDown == down and S.State(char) == st and S.CanAct(char) and S.Ready(char, "V") then
      down.Charged = true
      arenaGlitch(S, player, char, st)
    end
  end)
end
local function vEnd(S, player, char, st)
  local down = st.Data.VDown
  if not down then return end
  st.Data.VDown = nil
  if down.Charged then return end
  local cp = currentCheckpoint(player)
  if cp then
    reloadCheckpoint(S, player, char, st, cp)
  elseif S.Ready(char, "V") then
    saveCheckpoint(S, player, char, st)
  end
end

function K.Action(S, player, char, st, key, phase, aim)
  if key == "Aim" or st.Data.Casting then return end
  if key == "M1" then
    if phase == "Begin" then m1Begin(S, player, char, st)
    elseif phase == "End" then m1End(S, char, st) end
  elseif key == "F" then
    if phase == "Begin" then misplace(S, player, char, st, aim, C.AimDir(char, aim)) end
  elseif key == "C" then
    if phase == "Begin" then cBegin(S, player, char, st)
    elseif phase == "End" then cEnd(S, player, char, st) end
  elseif key == "V" then
    if phase == "Begin" then vBegin(S, player, char, st)
    elseif phase == "End" then vEnd(S, player, char, st) end
  end
end
return K

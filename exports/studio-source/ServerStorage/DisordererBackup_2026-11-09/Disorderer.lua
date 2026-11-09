--[==[ BACKUP of ServerScriptService.BossSystem.Players.Classes.Kits.Disorderer (ModuleScript) ]==]
return nil
--[==[
-- Reality Disorderer (game pass class): the team's glitch engine. Strong ranged damage whose Glitch stacks power up the whole
-- team, plus the rescue / protection tools of Misplace, Redact and Overwrite. Everything damaging goes through S.HitBoss.
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local D = ClassConfig.Classes.Disorderer
local MAG, CYAN, WHITE = D.Color, D.Color2, Color3.new(1, 1, 1)
local K = {}

local function statusService()
  return require(script:FindFirstAncestor("BossSystem").Combat.StatusEffectService)
end
local function cleanseOne(S, ally)
  local ok, name = pcall(function() return statusService().RemoveOneDebuff(ally) end)
  if ok and name then
    S.FX.HQ.Glint(ally.HumanoidRootPart.Position + Vector3.new(0, 1, 0), CYAN, 4, 0.3)
    S.FX.Text(ally.HumanoidRootPart.Position + Vector3.new(0, 4, 0), "REDACTED", CYAN)
    return true
  end
  return false
end
local function flatDistance(a, b)
  local d = a - b
  return Vector3.new(d.X, 0, d.Z).Magnitude
end

-- ===== Glitch =====
local function setGlitch(S, char, st, n)
  n = math.clamp(n, 0, D.M1.GlitchMax)
  st.Data.Glitch = n
  char:SetAttribute("DisorderGlitch", n)
  if n <= 0 then
    if S.HasBuff(char, "Glitch") then S.Unbuff(char, "Glitch") end
    S.RemoveStatBuff(char, "Glitch")
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

function K.Start(S, player, char, st)
  st.Data.Glitch, st.Data.GlitchUntil, st.Data.Overwrite, st.Data.Tick = 0, 0, nil, 0
  char:SetAttribute("DisorderGlitch", 0)
end
function K.Cleanup(S, char, st)
  st.Data.Overwrite = nil
  if char.Parent then
    char:SetAttribute("DisorderGlitch", nil)
    char:SetAttribute("ClassStatusText_Glitch", nil)
  end
end
function K.OnBuffEnded(S, char, st, id)
  if id == "Glitch" then
    st.Data.Glitch = 0
    char:SetAttribute("DisorderGlitch", 0)
    char:SetAttribute("ClassStatusText_Glitch", nil)
    S.RemoveStatBuff(char, "GlitchSelf")
  elseif id == "Overwrite" then
    st.Data.Overwrite = nil
    if S.HasBuff(char, "Checkpoint") then S.Unbuff(char, "Checkpoint") end
  end
end

function K.Step(S, player, char, st, dt)
  st.Data.Tick = (st.Data.Tick or 0) + dt
  if st.Data.Tick < 0.5 then return end
  st.Data.Tick = 0
  local overwrite = st.Data.Overwrite
  if overwrite then
    setGlitch(S, char, st, D.M1.GlitchMax)  -- Overwrite holds Glitch at the maximum
    local root = char.HumanoidRootPart
    for _, ally in ipairs(S.Allies(true)) do
      if (ally.HumanoidRootPart.Position - root.Position).Magnitude <= D.V.Radius then
        S.StatBuff(ally, "Overwrite:" .. player.UserId, 0.8, { Attack = D.V.TeamBoost, StaminaRegen = 1.25 })
      end
    end
  end
  pushGlitchBuffs(S, char, st)
end

-- every Static Bolt stacks Glitch and patches up the weakest ally nearby
function K.OnHitBoss(S, char, st, target, tag)
  if tag ~= "DisorderBolt" and tag ~= "DisorderEcho" then return end
  setGlitch(S, char, st, (st.Data.Glitch or 0) + 1)
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

-- ===== M1: Static Bolt =====
local function bolt(S, player, char, st, aim)
  local root = char.HumanoidRootPart
  if not S.Ready(char, "M1") then return end
  S.Cooldown(char, "M1", D.M1.Cooldown)
  S.Anim(char, "Cast")
  S.Sound(char, "RangedLaunch")
  local from = C.Hand(char)
  local dir = C.AimDir3D(from, aim, root.CFrame.LookVector)
  local attack = S.NewAttack(char, "DisorderBolt")
  if not attack then return end
  local visual = S.FX.Orb(MAG, 1)
  S.FX.Release(from, dir, CYAN, 0.6)
  S.FX.HQ.Glint(from, WHITE, 2.5, 0.15)
  local step = 0
  S.FX.Projectile(from, dir, D.M1.Speed, D.M1.Range, visual, function(pos)
    step += 1
    if step % 2 == 0 then S.FX.HQ.Sparks(pos, step % 4 == 0 and MAG or CYAN, WHITE, 2, 4, 10, 0.2) end
    if not S.AttackValid(char, attack) then return true end
    local target = S.TargetNear(pos, D.M1.Radius)
    if target then
      attack.Origin = pos
      if S.HitBoss(char, target, D.M1.Damage, "DisorderBolt", attack) then
        S.FX.Hit(pos, MAG, 1.5, false)
        S.FX.Ring(pos, CYAN, 9, 0.3)
        S.FX.HQ.Shake(pos, 45, 0.15, 0.3)
        S.Sound(char, "RangedImpact")
        if st.Data.Overwrite then  -- Overwrite: the bolt echoes
          task.delay(0.12, function()
            local echo = S.NewAttack(char, "DisorderEcho")
            if echo and S.Alive(target) then
              echo.Origin = pos
              if S.HitBoss(char, target, D.M1.Damage * D.V.EchoFraction, "DisorderEcho", echo) then
                S.FX.Hit(pos + Vector3.new(0, 1, 0), CYAN, 1.1, false)
              end
            end
          end)
        end
      end
      return true
    end
  end)
end

-- ===== F: Misplace =====
local function misplace(S, player, char, st, aim, dir)
  local root = char.HumanoidRootPart
  if not S.Ready(char, "F") then return end
  if not S.SpendStamina(char, D.F.StaminaCost) then
    S.FX.Text(root.Position + Vector3.new(0, 3, 0), "NO STAMINA", CYAN)
    return
  end
  local ally = aim and S.AimedAlly(char, aim, D.F.Range)
  if ally and (ally.HumanoidRootPart.Position - aim).Magnitude > 9 then ally = nil end
  S.Cooldown(char, "F", D.F.Cooldown)
  S.Anim(char, "Flash")
  S.Sound(char, "TeleportOut")
  local from = root.CFrame
  local old = from.Position
  if ally then
    local to = ally.HumanoidRootPart.CFrame
    char:PivotTo(to)
    ally:PivotTo(from)
    S.Buff(char, "Undying", D.F.IFrames, {})
    S.Buff(ally, "Undying", D.F.IFrames, {})
    S.FX.Beam(old, to.Position, CYAN, 0.6, 0.35)
    S.FX.Flash(to.Position, MAG, 9, 0.35)
    S.FX.Text(ally.HumanoidRootPart.Position + Vector3.new(0, 4, 0), "MISPLACED", MAG)
  else
    local target = aim or (old + dir * 20)
    local flat = C.Flat(target - old) or dir
    local distance = math.min(D.F.Range, flatDistance(target, old))
    local dest = C.Path(S, char, flat, distance)
    char:PivotTo(CFrame.new(dest.X, old.Y, dest.Z) * from.Rotation)
    S.FX.Beam(old, dest, CYAN, 0.6, 0.35)
  end
  S.FX.Flash(old, CYAN, 9, 0.35)
  S.FX.HQ.Sparks(old + Vector3.new(0, 1, 0), MAG, CYAN, 24, 20, 50, 0.4)
  -- the spot you left stays glitched and keeps hurting the boss
  local ground = old - Vector3.new(0, 2.6, 0)
  local patch = S.FX.Part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, D.F.PatchRadius * 2, D.F.PatchRadius * 2), Color = MAG,
    Material = Enum.Material.Neon, Transparency = 0.55, CFrame = CFrame.new(ground + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
  Debris:AddItem(patch, D.F.PatchTime + 0.3)
  task.spawn(function()
    local ticks = math.floor(D.F.PatchTime / D.F.PatchInterval)
    for i = 1, ticks do
      task.wait(D.F.PatchInterval)
      if not S.Alive(char) or S.State(char) ~= st then break end
      S.FX.Ring(ground, i % 2 == 0 and MAG or CYAN, D.F.PatchRadius * 1.3, 0.25)
      local attack = S.NewAttack(char, "DisorderPatch")
      if attack then
        for _, target in ipairs(S.Targets()) do
          if flatDistance(target.HumanoidRootPart.Position, old) <= D.F.PatchRadius + 4 and math.abs(target.HumanoidRootPart.Position.Y - old.Y) <= 14 then
            attack.Origin = old
            S.HitBoss(char, target, D.F.PatchDamage, "DisorderPatch", attack)
          end
        end
      end
    end
    if patch.Parent then S.FX.Fade(patch, 0.2) end
  end)
end

-- ===== C: Redact =====
local function redact(S, player, char, st, aim, dir)
  local root = char.HumanoidRootPart
  if not S.Ready(char, "C") then return end
  local center = aim or (root.Position + dir * 12)
  local flatFrom = Vector3.new(root.Position.X, 0, root.Position.Z)
  local flatTo = Vector3.new(center.X, 0, center.Z)
  if (flatTo - flatFrom).Magnitude > D.C.Range then
    center = root.Position + (C.Flat(center - root.Position) or dir) * D.C.Range
  end
  center = Vector3.new(center.X, root.Position.Y - 2.6, center.Z)
  S.Cooldown(char, "C", D.C.Cooldown)
  S.Anim(char, "Cast")
  S.Sound(char, "CloneMaterialize")
  local duration = D.C.Duration + D.C.DurationPerGlitch * (st.Data.Glitch or 0)
  local zone = S.FX.Part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, D.C.Radius * 2, D.C.Radius * 2), Color = CYAN,
    Material = Enum.Material.Neon, Transparency = 0.7, CFrame = CFrame.new(center + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
  Debris:AddItem(zone, duration + 0.4)
  S.FX.HQ.Spikes(center, 10, D.C.Radius * 0.85, 7, MAG, CYAN, 0.8)
  S.FX.HQ.Shockwave(CFrame.new(center + Vector3.new(0, 0.2, 0)), 2, D.C.Radius * 1.2, 0.5, CYAN, 0.2, 1)
  S.FX.Text(center + Vector3.new(0, 5, 0), "REDACT", CYAN)
  task.spawn(function()
    local t0, nextTick, nextClean = os.clock(), 0, 1
    while os.clock() - t0 < duration and S.Alive(char) and S.State(char) == st do
      local t = os.clock() - t0
      if t >= nextTick then
        nextTick = t + D.C.Interval
        S.FX.Ring(center, nextTick % 1 < 0.5 and MAG or CYAN, D.C.Radius * 0.9, 0.35)
        local clean = t >= nextClean
        if clean then nextClean = t + 1 end
        for _, ally in ipairs(S.Allies(true)) do
          if flatDistance(ally.HumanoidRootPart.Position, center) <= D.C.Radius then
            S.Buff(ally, "Redacted", 0.8, { Incoming = 1 - D.C.Reduction })
            S.StatBuff(ally, "RedactBoost", 0.8, { Attack = D.C.AllyBoost })
            if clean then cleanseOne(S, ally) end
          end
        end
        local attack = S.NewAttack(char, "DisorderRedact")
        if attack then
          for _, target in ipairs(S.Targets()) do
            if flatDistance(target.HumanoidRootPart.Position, center) <= D.C.Radius + 4 then
              attack.Origin = center + Vector3.new(0, 4, 0)
              if S.HitBoss(char, target, D.C.Damage, "DisorderRedact", attack) then
                S.FX.HQ.Sparks(target.HumanoidRootPart.Position, MAG, CYAN, 6, 10, 24, 0.25)
              end
            end
          end
        end
      end
      task.wait(0.1)
    end
    if zone.Parent then S.FX.Fade(zone, 0.3) end
  end)
end

-- ===== V: Overwrite / Checkpoint reload =====
local function reload(S, char, st)
  local overwrite = st.Data.Overwrite
  if not overwrite then return end
  st.Data.Overwrite = nil
  for _, snap in ipairs(overwrite.Snap) do
    local ally = snap.Char
    if ally.Parent and S.Alive(ally) then
      local h = ally:FindFirstChildOfClass("Humanoid")
      ally:PivotTo(snap.CFrame)
      -- a reload only ever helps: HP and stamina are the better of "then" and "now", and nobody is revived
      if h then h.Health = math.max(h.Health, math.min(h.MaxHealth, snap.Health)) end
      local maxStamina = ally:GetAttribute("MaxStamina") or 100
      ally:SetAttribute("Stamina", math.min(maxStamina, math.max(ally:GetAttribute("Stamina") or 0, snap.Stamina)))
      S.FX.Beam(snap.CFrame.Position, snap.CFrame.Position + Vector3.new(0, 12, 0), CYAN, 0.5, 0.5)
      S.FX.Flash(snap.CFrame.Position, CYAN, 10, 0.4)
      S.FX.Text(snap.CFrame.Position + Vector3.new(0, 4, 0), "RELOADED", CYAN)
    end
  end
  if S.HasBuff(char, "Overwrite") then S.Unbuff(char, "Overwrite") end
  if S.HasBuff(char, "Checkpoint") then S.Unbuff(char, "Checkpoint") end
  S.Sound(char, "TeleportIn")
end
local function overwrite(S, player, char, st)
  local root = char.HumanoidRootPart
  if st.Data.Overwrite then reload(S, char, st) return end
  if not S.Ready(char, "V") then return end
  S.Cooldown(char, "V", D.V.Cooldown)
  local snap = {}
  for _, ally in ipairs(S.Allies(true)) do
    if (ally.HumanoidRootPart.Position - root.Position).Magnitude <= D.V.Radius then
      local h = ally:FindFirstChildOfClass("Humanoid")
      table.insert(snap, { Char = ally, CFrame = ally.HumanoidRootPart.CFrame, Stamina = ally:GetAttribute("Stamina") or 0, Health = h and h.Health or 0 })
    end
  end
  st.Data.Overwrite = { Snap = snap }
  S.Buff(char, "Overwrite", D.V.Duration)
  S.Buff(char, "Checkpoint", D.V.Duration)
  setGlitch(S, char, st, D.M1.GlitchMax)
  S.Anim(char, "Stance")
  S.Sound(char, "RoyalFinalCharge")
  S.FX.Flash(root.Position, MAG, 22, 0.6)
  S.FX.HQ.Spikes(root.Position - Vector3.new(0, 2.5, 0), 10, 8, 20, MAG, CYAN, 0.9)
  S.FX.HQ.Shockwave(CFrame.new(root.Position - Vector3.new(0, 2.5, 0)), 3, D.V.Radius, 0.7, CYAN, 0.2, 1.2)
  S.FX.HQ.Tint(root.Position, MAG, 0.25, 0.4, 120)
  S.FX.Text(root.Position + Vector3.new(0, 4.5, 0), "OVERWRITE", MAG)
  for _, s in ipairs(snap) do
    if s.Char ~= char then S.FX.Beam(root.Position, s.CFrame.Position, CYAN, 0.3, 0.5) end
  end
end

function K.Action(S, player, char, st, key, phase, aim)
  if key == "Aim" or phase ~= "Begin" then return end
  local dir = C.AimDir(char, aim)
  if key == "M1" then bolt(S, player, char, st, aim)
  elseif key == "F" then misplace(S, player, char, st, aim, dir)
  elseif key == "C" then redact(S, player, char, st, aim, dir)
  elseif key == "V" then overwrite(S, player, char, st) end
end
return K

]==]
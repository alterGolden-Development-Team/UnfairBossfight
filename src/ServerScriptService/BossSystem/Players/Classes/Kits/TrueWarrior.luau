local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)
local D = ClassConfig.Classes.TrueWarrior
local GOLD, WHITE = D.Color, Color3.new(1, 1, 1)
local FLAME = Color3.fromRGB(255, 130, 40)
local K = {}

local function send(stage, data)
  Net.Send("TrueWarrior", stage, data)
end

local function beginCast(S, char, st, seconds)
  st.Busy, st.Data.Casting = true, true
  S.Buff(char, "Phasing", seconds)
  S.Buff(char, "Recovering", seconds, { Speed = 0 })
  char:SetAttribute("TrueWarriorCinematic", true)
end
local function endCast(S, char, st)
  st.Busy, st.Data.Casting = false, false
  for _, id in ipairs({ "Phasing", "Recovering", "VowCharge", "TruthCast" }) do
    if S.HasBuff(char, id) then S.Unbuff(char, id) end
  end
  if char.Parent then char:SetAttribute("TrueWarriorCinematic", nil) end
end
local function hold(S, char, attack, seconds)
  local ends = os.clock() + seconds
  while os.clock() < ends do
    if not S.AttackValid(char, attack) then return false end
    task.wait()
  end
  return S.AttackValid(char, attack)
end

local function shieldHidden(char, st, hidden)
  st.Data.ShieldLocks = math.max(0, (st.Data.ShieldLocks or 0) + (hidden and 1 or -1))
  local gear = char:FindFirstChild("ClassGear")
  if not gear then return end
  for _, part in ipairs(gear:GetDescendants()) do
    if part:IsA("BasePart") and part.Name:find("^Shield") then
      if hidden then
        if part:GetAttribute("TWBaseAlpha") == nil then part:SetAttribute("TWBaseAlpha", part.Transparency) end
        part.Transparency = 1
      elseif st.Data.ShieldLocks == 0 and part:GetAttribute("TWBaseAlpha") ~= nil then
        part.Transparency = part:GetAttribute("TWBaseAlpha")
        part:SetAttribute("TWBaseAlpha", nil)
      end
    end
  end
end

local function flyLine(S, char, attack, origin, dir, speed, range, radius, onHit)
  task.spawn(function()
    local travelled, prev, last = 0, origin, os.clock()
    while travelled < range do
      task.wait()
      if not S.AttackValid(char, attack) then return end
      local t = os.clock()
      travelled = math.min(range, travelled + speed * (t - last))
      last = t
      local pos = origin + dir * travelled
      local target = C.SegmentTarget(S, prev, pos, radius)
      if target then
        attack.Origin = pos
        onHit(target, pos)
        return
      end
      prev = pos
    end
  end)
end

local function takeHidden(S, char, st, key)
  if not st.Data.Hidden or not st.Data.Hidden[key] then return false end
  st.Data.Hidden[key] = nil
  char:SetAttribute("TWHidden_" .. key, nil)
  if next(st.Data.Hidden) == nil and S.HasBuff(char, "HiddenReady") then S.Unbuff(char, "HiddenReady") end
  return true
end

local function aimAssist(S, player, char, st, range)
  local target = player:GetAttribute("ClassAutoAim") ~= false and S.AimTarget(char, st.Aim, range or 240)
  return C.AimDir(char, target and target.HumanoidRootPart.Position or st.Aim)
end

function K.Start(S, player, char, st)
  st.Data.Combo, st.Data.LastM1, st.Data.Tick, st.Data.Dealt = 0, 0, 0, 0
  st.Data.Hidden, st.Data.LastChain = {}, 0
  st.Data.Champion = S.ClassTier(player) > 0
  char:SetAttribute("TrueWarriorChampion", st.Data.Champion or nil)
  if st.Data.Champion then
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.MaxHealth = h.MaxHealth * D.ChampionHP h.Health = h.MaxHealth end
  end
end
function K.Cleanup(S, char, st)
  send("Cancel", { Char = char })
  if char.Parent then
    char:SetAttribute("TrueWarriorChampion", nil)
    char:SetAttribute("TrueWarriorCinematic", nil)
    char:SetAttribute("TrueWarriorChain", nil)
    for _, key in ipairs({ "C", "F", "R" }) do char:SetAttribute("TWHidden_" .. key, nil) end
  end
end
function K.CancelActions(S, char, st, reason)
  if S.HasBuff(char, "CounterStance") then S.Unbuff(char, "CounterStance") end
  if S.HasBuff(char, "HolyStance") then
    S.Unbuff(char, "HolyStance")
    send("Cancel", { Char = char })
  end
  if st.Data.Casting then
    endCast(S, char, st)
    if st.Data.SupremeHidden then
      st.Data.SupremeHidden = false
      shieldHidden(char, st, false)
    end
    send("Cancel", { Char = char })
  end
end

function K.Step(S, player, char, st, dt)
  st.Data.Tick += dt
  if st.Data.Tick < 0.5 then return end
  st.Data.Tick = 0
  local solo = #S.Allies(false, char) == 0
  S.StatBuff(char, "Unbroken", 1.2, { Attack = 1 + (solo and D.SoloDamage or D.TeamDamage), Defense = solo and D.SoloDefense or 0 })
  S.Buff(char, "Unbroken", 1.2)
  char:SetAttribute("ClassStatusText_Unbroken", solo and "SOLO" or "TEAM")
  if st.Data.Champion and workspace:GetAttribute("EncounterStarted") then
    local sequence = workspace:GetAttribute("BossEntranceSequence") or 0
    if player:GetAttribute("ChampionLifeSequence") ~= sequence then
      player:SetAttribute("ChampionLifeSequence", sequence)
      local ok, granted = pcall(function()
        return require(script:FindFirstAncestor("BossSystem").Players.PlayerEncounter).GrantLife(player)
      end)
      if ok and granted then S.FX.Text(char.HumanoidRootPart.Position + Vector3.new(0, 3, 0), "+1 LIFE", GOLD) end
    end
  end
end

local function counterSlash(S, player, char, st)
  if not S.CanAct(char) then return end
  local attack = S.NewAttack(char, "TrueWarriorCounter")
  if not attack then return end
  st.Data.PerfectAt = os.clock()
  S.Cooldown(char, "R", D.R.SuccessCooldown)
  S.Buff(char, "Phasing", 0.3)
  S.Anim(char, "TW_Counter")
  S.Sound(char, "ParryContact")
  local root = char.HumanoidRootPart
  local dir = aimAssist(S, player, char, st)
  local origin = root.Position + dir * 3 + Vector3.new(0, 0.8, 0)
  S.FX.HQ.Glint(origin, WHITE, 6, 0.3)
  S.FX.Ring(root.Position - Vector3.new(0, 2.6, 0), GOLD, 10, 0.35)
  send("CounterSlash", { Char = char, Origin = origin, Dir = dir, Speed = D.R.Speed, Range = D.R.Range })
  flyLine(S, char, attack, origin, dir, D.R.Speed, D.R.Range, D.R.HitRadius, function(target, pos)
    S.HitBoss(char, target, D.R.Damage, "TrueWarriorCounter", attack)
    S.FX.Hit(pos, GOLD, 1.8, true)
    S.Sound(char, "CounterImpact")
  end)
end

local function igniteHolyFlame(S, char, st, target)
  local seconds = D.R.HolyFlameDuration
  target:SetAttribute("HolyFlameUntil", S.Now() + seconds)
  send("HolyFlame", { Target = target, Duration = seconds })
  task.spawn(function()
    for _ = 1, math.floor(seconds / D.R.HolyFlameTick) do
      task.wait(D.R.HolyFlameTick)
      if not S.Alive(target) then return end
      S.DotBoss(char, target, D.R.HolyFlameDamage, "TrueWarriorHolyFlame")
    end
  end)
end

local function holyCounter(S, char, st, received)
  local attack = S.NewAttack(char, "TrueWarriorHolyCounter")
  if not attack then return end
  attack.IgnoreSight = true
  S.Cooldown(char, "R", D.R.SuccessCooldown)
  S.Buff(char, "Phasing", 0.6)
  S.Anim(char, "TW_Counter")
  S.Sound(char, "ParryContact")
  S.Sound(char, "CrescentRelease")
  local root = char.HumanoidRootPart
  local boss = S.Boss()
  local target = boss and table.find(S.Targets(), boss) and boss or S.AimTarget(char, nil, D.C.Range)
  local aim = target and target.HumanoidRootPart.Position or st.Aim
  local dir = C.AimDir(char, aim)
  local origin = root.Position + dir * 3 + Vector3.new(0, 0.8, 0)
  local length = target and (target.HumanoidRootPart.Position - origin).Magnitude or D.R.Range
  send("HolyCounter", { Char = char, Origin = origin, Dir = dir, Length = length, Target = target })
  S.FX.HQ.Shake(origin, 120, 0.4, 1)
  if not target then return end
  attack.Origin = origin
  local damage = math.min(D.R.HolyCap, received * D.R.HolyMultiplier)
  if S.HitBoss(char, target, damage, "TrueWarriorHolyCounter", attack) then
    igniteHolyFlame(S, char, st, target)
    local p = target.HumanoidRootPart.Position
    S.FX.Hit(p, WHITE, 3, true)
    S.FX.Text(p + Vector3.new(0, 7, 0), "HOLY COUNTER " .. math.floor(damage), GOLD)
  end
end

function K.GuardAction(S, player, char, st, phase)
  if phase ~= "Begin" or st.Data.Casting or S.HasBuff(char, "CounterStance") or S.HasBuff(char, "HolyStance") then return end
  local hiddenReady = st.Data.Hidden and st.Data.Hidden.R
  if not S.CanBlock(char) and not (hiddenReady and S.CanAct(char)) then return end
  if takeHidden(S, char, st, "R") then
    S.Cooldown(char, "R", D.R.Cooldown)
    S.Buff(char, "HolyStance", D.R.HolyWindow)
    S.Sound(char, "ParryStance")
    send("HolyStance", { Char = char, Duration = D.R.HolyWindow })
    return
  end
  S.Cooldown(char, "R", D.R.Cooldown)
  S.Buff(char, "CounterStance", D.R.Window)
  S.Sound(char, "ParryStance")
  local p = char.HumanoidRootPart.Position
  S.FX.HQ.Glint(C.Hand(char), WHITE, 3.5, 0.3)
  S.FX.HQ.Shockwave(CFrame.new(p - Vector3.new(0, 2.7, 0)), 1, 5, 0.3, GOLD, 0.3, 0.35)
end

function K.Incoming(S, char, st, amount, balance)
  if S.HasBuff(char, "HolyStance") and not (balance and balance.IsStatusDamage) then
    S.Unbuff(char, "HolyStance")
    task.spawn(holyCounter, S, char, st, amount)
    return 0
  end
  if S.HasBuff(char, "CounterStance") and not (balance and balance.IsStatusDamage) then
    S.Unbuff(char, "CounterStance")
    local p = char.HumanoidRootPart.Position
    S.FX.Flash(p, GOLD, 10, 0.3)
    S.FX.HQ.Tint(p, GOLD, 0.25, 0.2, 80)
    task.spawn(counterSlash, S, st.Player, char, st)
    return 0
  end
  return amount
end

local NOT_COUNTED = { TrueWarriorFinisher = true, TrueWarriorSupreme = true, TrueWarriorTruth = true, TrueWarriorHolyCounter = true, TrueWarriorHolyFlame = true }
function K.OnHitBoss(S, char, st, target, tag, dealt)
  if S.HasBuff(char, "LastStand") and not NOT_COUNTED[tag] and type(dealt) == "number" then
    st.Data.Dealt += dealt
  end
end

local function finisher(S, char, st)
  local damage = math.min(D.V.FinisherCap, st.Data.Dealt * D.V.FinisherFraction)
  st.Data.Dealt = 0
  local boss = S.Boss()
  if not boss or not table.find(S.Targets(), boss) then boss = S.AimTarget(char, st.Aim, D.C.Range) end
  if damage < 1 or not boss then return end
  local attack = S.NewAttack(char, "TrueWarriorFinisher")
  if not attack then return end
  local p = boss.HumanoidRootPart.Position
  S.Anim(char, "XSlash")
  S.Sound(char, "CataclysmSlam")
  attack.Origin = char.HumanoidRootPart.Position
  attack.IgnoreSight = true
  if S.HitBoss(char, boss, damage, "TrueWarriorFinisher", attack) then
    S.FX.Hit(p, GOLD, 3, true)
    S.FX.HQ.Shockwave(CFrame.new(p - Vector3.new(0, 3, 0)), 3, 22, 0.6, GOLD, 0.1, 1.4)
    S.FX.HQ.Spikes(p - Vector3.new(0, 3, 0), 8, 8, 18, GOLD, WHITE, 0.7)
    S.FX.HQ.Shake(p, 110, 0.5, 1)
    S.FX.Text(p + Vector3.new(0, 6, 0), "LAST STAND " .. math.floor(damage), GOLD)
  end
end
function K.OnBuffEnded(S, char, st, id)
  if id ~= "LastStand" then return end
  S.RemoveStatBuff(char, "LastStandAtk")
  if not st.Data.LastCasting then
    if st.Data.Hidden and next(st.Data.Hidden) then
      for key in pairs(st.Data.Hidden) do char:SetAttribute("TWHidden_" .. key, nil) end
      st.Data.Hidden = {}
      if S.HasBuff(char, "HiddenReady") then S.Unbuff(char, "HiddenReady") end
    end
    if (st.Data.LastChain or 0) > 0 then
      local nextStage = st.Data.LastChain + 1
      st.Data.LastChain = 0
      char:SetAttribute("TrueWarriorChain", nil)
      S.Cooldown(char, "V", D.V.MissCooldowns[nextStage])
    end
  end
  if st.Data.Casting then
    task.delay(1.2, function()
      if S.State(char) == st then finisher(S, char, st) end
    end)
  else
    finisher(S, char, st)
  end
end

local function m1(S, player, char, st)
  local root = char.HumanoidRootPart
  if not S.Ready(char, "M1") then return end
  S.Cooldown(char, "M1", D.M1.Cooldown)
  local t = os.clock()
  st.Data.Combo = (t - st.Data.LastM1 < 1.1) and (st.Data.Combo % D.M1.Combo) + 1 or 1
  st.Data.LastM1 = t
  local hit = st.Data.Combo
  local attack = S.NewAttack(char, "TrueWarriorM1")
  if not attack then return end
  S.Anim(char, ({ "SlashA", "SlashB", "Chop" })[hit])
  S.Sound(char, "NormalSwing")
  task.delay(hit == 3 and 0.2 or 0.1, function()
    if not S.AttackValid(char, attack) then return end
    local dir = C.AimDir(char, st.Aim)
    local eye = root.Position + Vector3.new(0, 0.7, 0)
    local frame = CFrame.lookAt(eye, eye + dir)
    if hit == 3 then
      S.FX.HQ.Crescent(frame * CFrame.Angles(0, 0, math.rad(90)), 9, math.rad(160), 2, GOLD, WHITE, 0.32, { Reverse = true })
      S.FX.Ring(root.Position + dir * 6 - Vector3.new(0, 2.6, 0), GOLD, 13, 0.45, 0.8)
    else
      S.FX.HQ.Crescent(frame, D.M1.Range * 0.95, math.rad(170), 1.5, GOLD, WHITE, 0.26, hit == 1 and { Reverse = true } or nil)
      S.FX.HQ.Crescent(frame, D.M1.Range * 0.7, math.rad(150), 0.6, WHITE, WHITE, 0.18, hit == 1 and { Reverse = true } or nil)
    end
    local target = S.TargetNear(root.Position + dir * (D.M1.Range * 0.5), D.M1.Range * 0.75)
    if target and C.InFront(char, target, D.M1.Range + 5, -0.2) then
      S.HitBoss(char, target, hit == 3 and D.M1.FinisherDamage or D.M1.Damage, "TrueWarriorM1", attack)
      local p = target.HumanoidRootPart.Position
      S.FX.Hit(p, GOLD, hit == 3 and 2 or 1.2, hit == 3)
      S.FX.HQ.Shake(p, 50, 0.15, hit == 3 and 0.6 or 0.3)
      S.Sound(char, hit == 3 and "CounterImpact" or "NormalImpact")
    end
  end)
end

local throwSerial = 0
local function victoriousThrow(S, player, char, st, dir)
  if not S.Ready(char, "F") then return end
  S.Cooldown(char, "F", D.F.Cooldown)
  local attack = S.NewAttack(char, "TrueWarriorThrow")
  if not attack then return end
  S.Anim(char, "TW_Throw")
  S.Sound(char, "BlockLaunch")
  throwSerial += 1
  local id = throwSerial
  task.spawn(function()
    task.wait(0.12)
    if not S.AttackValid(char, attack) then return end
    local root = char.HumanoidRootPart
    dir = aimAssist(S, player, char, st)
    local origin = root.Position + dir * 2 + Vector3.new(0, 0.6, 0)
    shieldHidden(char, st, true)
    S.FX.HQ.Streaks(origin, dir, GOLD, WHITE, 12, 10, 60, 120, 3)
    send("ShieldThrow", { Char = char, Id = id, Origin = origin, Dir = dir, Speed = D.F.Speed, Range = D.F.Range, ReturnSpeed = D.F.ReturnSpeed })
    local pos, prev, travelled, last, hit = origin, origin, 0, os.clock(), false
    while travelled < D.F.Range and S.Alive(char) do
      task.wait()
      local t = os.clock()
      travelled = math.min(D.F.Range, travelled + D.F.Speed * (t - last))
      last = t
      pos = origin + dir * travelled
      local target = S.AttackValid(char, attack) and C.SegmentTarget(S, prev, pos, D.F.Radius)
      if target then
        hit = true
        attack.Origin = pos
        if S.HitBoss(char, target, D.F.Damage, "TrueWarriorThrow", attack) then
          S.Stun(target, st.Data.Champion and D.F.ChampionStun or D.F.Stun, char, attack)
        end
        local p = target.HumanoidRootPart.Position
        S.FX.Hit(p, GOLD, 2.2, true)
        S.FX.Ring(p - Vector3.new(0, 3, 0), GOLD, 16, 0.5)
        S.FX.HQ.Shake(p, 80, 0.3, 0.7)
        S.Sound(char, "BlockImpact")
        send("ShieldHit", { Char = char, Id = id, Pos = pos })
        break
      end
      prev = pos
    end
    if not hit then send("ShieldTurn", { Char = char, Id = id, Pos = pos }) end
    local started = os.clock()
    last = started
    while S.Alive(char) and os.clock() - started < 4 do
      task.wait()
      local t = os.clock()
      local to = root.Position + Vector3.new(0, 0.6, 0) - pos
      if to.Magnitude <= 5 then break end
      pos += to.Unit * math.min(D.F.ReturnSpeed * (t - last), to.Magnitude)
      last = t
    end
    send("ShieldCaught", { Char = char, Id = id })
    if S.State(char) == st then
      shieldHidden(char, st, false)
      if S.Alive(char) then
        S.FX.HQ.Glint(char.HumanoidRootPart.Position + Vector3.new(0, 0.5, 0), GOLD, 4, 0.25)
        S.Sound(char, "GuardActivate")
      end
    end
  end)
end

local function theTruth(S, player, char, st)
  local attack = S.NewAttack(char, "TrueWarriorTruth")
  if not attack then return end
  attack.IgnoreSight = true
  local f = D.F
  S.Cooldown(char, "F", f.Cooldown)
  beginCast(S, char, st, f.TruthCharge + f.TruthDuration + 0.5)
  S.Buff(char, "TruthCast", f.TruthCharge + f.TruthDuration)
  S.Sound(char, "RoyalFinalCharge")
  send("TruthCharge", { Char = char, Dir = aimAssist(S, player, char, st, f.TruthRange), Duration = f.TruthCharge, Beam = f.TruthDuration })
  task.spawn(function()
    if not hold(S, char, attack, f.TruthCharge) then
      if st.Data.Casting then endCast(S, char, st) send("Cancel", { Char = char }) end
      return
    end
    local dir = aimAssist(S, player, char, st, f.TruthRange)
    local origin = C.Hand(char, "Left") + dir
    local flatFrom = Vector3.new(origin.X, 0, origin.Z)
    local flatTo = flatFrom + dir * f.TruthRange
    attack.Origin = origin
    S.Sound(char, "CrescentRelease")
    S.Sound(char, "RoyalFinalImpact")
    S.FX.HQ.Shake(origin, 200, f.TruthDuration, 1.2)
    send("TruthFire", { Char = char, Origin = origin, Dir = dir, Range = f.TruthRange, Radius = f.TruthRadius, Duration = f.TruthDuration })
    local interval = f.TruthDuration / f.TruthTicks
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    for _ = 1, f.TruthTicks do
      if not S.AttackValid(char, attack) then break end
      if humanoid and humanoid.Health > 0 then
        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + humanoid.MaxHealth * f.TruthHeal / f.TruthTicks)
      end
      for _, target in ipairs(S.Targets()) do
        local p = target.HumanoidRootPart.Position
        if C.SegmentDistance(Vector3.new(p.X, 0, p.Z), flatFrom, flatTo) <= f.TruthRadius + 2.5 and math.abs(p.Y - origin.Y) <= 40 then
          if S.HitBoss(char, target, f.TruthDamage, "TrueWarriorTruth", attack) then
            S.FX.Hit(p, GOLD, 2, true)
          end
        end
      end
      if not hold(S, char, attack, interval) then break end
    end
    if st.Data.Casting then
      endCast(S, char, st)
      send("CastEnd", { Char = char })
    end
  end)
end

local function vowSlash(S, player, char, st, dir)
  local root = char.HumanoidRootPart
  if not S.Ready(char, "C") then return end
  S.Cooldown(char, "C", D.C.Cooldown)
  local attack = S.NewAttack(char, "TrueWarriorVow")
  if not attack then return end
  local boosted = st.Data.Champion and os.clock() - (st.Data.PerfectAt or -100) <= D.C.PerfectMemory
  if boosted then st.Data.PerfectAt = -100 end
  local damage = D.C.Damage * (boosted and D.C.ChampionMultiplier or 1)
  beginCast(S, char, st, D.C.Charge + 0.6)
  S.Buff(char, "VowCharge", D.C.Charge)
  S.Sound(char, "CrescentCharge")
  send("VowCharge", { Char = char, Dir = dir, Duration = D.C.Charge, Boosted = boosted })
  task.spawn(function()
    if not hold(S, char, attack, D.C.Charge) then
      if st.Data.Casting then endCast(S, char, st) send("Cancel", { Char = char }) end
      return
    end
    S.Unbuff(char, "VowCharge")
    dir = aimAssist(S, player, char, st, D.C.Range)
    local origin = root.Position + dir * 3 + Vector3.new(0, 0.8, 0)
    S.Anim(char, "TW_VowRelease")
    S.Sound(char, "CrescentRelease")
    S.FX.HQ.Shake(origin, 120, 0.4, 1)
    send("VowRelease", { Char = char, Origin = origin, Dir = dir, Speed = D.C.Speed, Range = D.C.Range, LineLife = D.C.LineLife, Boosted = boosted })
    flyLine(S, char, attack, origin, dir, D.C.Speed, D.C.Range, D.C.HitRadius, function(target, pos)
      S.HitBoss(char, target, damage, "TrueWarriorVow", attack)
      S.FX.Hit(pos, GOLD, boosted and 3 or 2.2, true)
      S.FX.HQ.Spikes(target.HumanoidRootPart.Position - Vector3.new(0, 3, 0), 6, 7, 14, GOLD, WHITE, 0.6)
      S.FX.HQ.Shake(pos, 90, 0.4, 0.9)
      if boosted then S.FX.Text(pos + Vector3.new(0, 5, 0), "CHAMPION'S VOW x2", GOLD) end
      send("VowHit", { Char = char, Pos = pos, Boosted = boosted })
    end)
    task.wait(0.45)
    if st.Data.Casting then
      endCast(S, char, st)
      send("CastEnd", { Char = char })
    end
  end)
end

local function setHidden(S, char, st, keys)
  st.Data.Hidden = {}
  for _, key in ipairs({ "C", "F", "R" }) do char:SetAttribute("TWHidden_" .. key, nil) end
  for _, key in ipairs(keys) do
    st.Data.Hidden[key] = true
    char:SetAttribute("TWHidden_" .. key, true)
  end
  if #keys > 0 then
    S.Buff(char, "HiddenReady", D.V.Duration)
  elseif S.HasBuff(char, "HiddenReady") then
    S.Unbuff(char, "HiddenReady")
  end
end

local function endChain(S, char, st, cooldown)
  st.Data.LastChain = 0
  char:SetAttribute("TrueWarriorChain", nil)
  S.Cooldown(char, "V", cooldown)
end

local HIDDEN_BY_STAGE = { { "R" }, { "R", "F" }, { "C" } }
local function lastStand(S, player, char, st)
  local root = char.HumanoidRootPart
  if not S.Ready(char, "V") then return end
  local attack = S.NewAttack(char, "TrueWarriorLastSlash")
  if not attack then return end
  attack.IgnoreSight = true
  local stage = (st.Data.LastChain or 0) + 1
  local function missed()
    st.Data.LastCasting = false
    endChain(S, char, st, D.V.MissCooldowns[stage])
  end
  st.Data.LastCasting = true
  S.Cooldown(char, "V", D.V.Charge + 3)
  beginCast(S, char, st, D.V.Charge + 0.8)
  S.Anim(char, "TW_LastCharge")
  S.Sound(char, "RoyalFinalCharge")
  send("LastStandCharge", { Char = char, Dir = C.AimDir(char, st.Aim), Duration = D.V.Charge, Stage = stage })
  task.spawn(function()
    if not hold(S, char, attack, D.V.Charge) then
      if st.Data.Casting then endCast(S, char, st) send("Cancel", { Char = char }) end
      missed()
      return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
      humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (humanoid.MaxHealth - humanoid.Health) * D.V.HealLost)
    end
    local center = root.Position
    local radius = D.V.SlashSizes[stage] / 2
    S.Anim(char, "TW_LastSpin")
    char:SetAttribute("ClassSpinDegrees", 360)
    char:SetAttribute("TwinbladeSpinDur", 0.32)
    char:SetAttribute("TwinbladeSpinEnd", S.Now() + 0.32)
    S.Sound(char, "CrescentRelease")
    S.Sound(char, "RoyalFinalImpact")
    S.FX.HQ.Shake(center, 140, 0.5, 1.1)
    send("LastStandSlash", { Char = char, Origin = center, Radius = radius, Stage = stage })
    attack.Origin = center
    local landed, victim = false, nil
    local height = math.max(40, radius)
    for _, target in ipairs(S.Targets()) do
      local delta = target.HumanoidRootPart.Position - center
      if Vector3.new(delta.X, 0, delta.Z).Magnitude <= radius + 2.5 and math.abs(delta.Y) <= height then
        if S.HitBoss(char, target, D.V.SlashDamage, "TrueWarriorLastSlash", attack) then
          landed, victim = true, target
          S.FX.Hit(target.HumanoidRootPart.Position, GOLD, 2.6, true)
        end
      end
    end
    if landed then
      st.Data.LastCasting = false
      if stage == 1 then st.Data.Dealt = 0 end
      S.Buff(char, "LastStand", D.V.Duration)
      S.StatBuff(char, "LastStandAtk", D.V.Duration, { Attack = D.V.Attack })
      setHidden(S, char, st, HIDDEN_BY_STAGE[stage])
      if stage >= 3 then
        endChain(S, char, st, D.V.Cooldown)
      else
        st.Data.LastChain = stage
        char:SetAttribute("TrueWarriorChain", stage)
        S.Cooldown(char, "V", D.V.ChainCooldown)
      end
    else
      missed()
    end
    send("LastStandResult", { Char = char, Hit = landed, Target = victim, Stage = stage })
    task.wait(0.5)
    if st.Data.Casting then
      endCast(S, char, st)
      send("CastEnd", { Char = char })
    end
  end)
end

local function supremeKingSlash(S, player, char, st, dir)
  local attack = S.NewAttack(char, "TrueWarriorSupreme")
  if not attack then return end
  attack.IgnoreSight = true
  S.Cooldown(char, "C", D.C.Cooldown)
  local root = char.HumanoidRootPart
  local charge, swing = D.C.SupremeCharge, D.C.SupremeSwing
  beginCast(S, char, st, charge + swing + 1.2)
  st.Data.SupremeHidden = true
  shieldHidden(char, st, true)
  S.Anim(char, "TW_KingCharge")
  S.Sound(char, "RoyalFinalCharge")
  send("SupremeCharge", { Char = char, Dir = dir, Duration = charge, Swing = swing, Length = D.C.SupremeLength })
  local function abort()
    if st.Data.Casting then endCast(S, char, st) send("Cancel", { Char = char }) end
    if st.Data.SupremeHidden then
      st.Data.SupremeHidden = false
      shieldHidden(char, st, false)
    end
  end
  task.spawn(function()
    if not hold(S, char, attack, charge) then return abort() end
    S.Anim(char, "TW_KingSwing")
    S.Sound(char, "FallingCharge")
    send("SupremeSwing", { Char = char, Duration = swing })
    if not hold(S, char, attack, swing) then return abort() end
    local origin = root.Position
    local tip = origin + dir * D.C.SupremeLength
    local flatA, flatB = Vector3.new(origin.X, 0, origin.Z), Vector3.new(tip.X, 0, tip.Z)
    attack.Origin = origin
    for _, target in ipairs(S.Targets()) do
      local p = target.HumanoidRootPart.Position
      local flatP = Vector3.new(p.X, 0, p.Z)
      if C.SegmentDistance(flatP, flatA, flatB) <= D.C.SupremeRadius + 2.5 or (flatP - flatB).Magnitude <= D.C.SupremeBlast then
        S.HitBoss(char, target, D.C.SupremeDamage, "TrueWarriorSupreme", attack)
        S.FX.Hit(p, FLAME, 3, true)
      end
    end
    S.Sound(char, "RoyalFinalImpact")
    S.Sound(char, "CataclysmSlam")
    S.FX.HQ.Shake(origin + dir * 60, 300, 0.9, 1.6)
    send("SupremeImpact", { Char = char, Origin = origin, Dir = dir, Length = D.C.SupremeLength, Radius = D.C.SupremeRadius, Blast = D.C.SupremeBlast })
    task.wait(1.0)
    if st.Data.Casting then
      endCast(S, char, st)
      send("CastEnd", { Char = char })
    end
    if st.Data.SupremeHidden then
      st.Data.SupremeHidden = false
      shieldHidden(char, st, false)
    end
  end)
end

function K.Action(S, player, char, st, key, phase, aim)
  if key == "Aim" or phase ~= "Begin" then return end
  if st.Data.Casting or S.HasBuff(char, "CounterStance") or S.HasBuff(char, "HolyStance") then return end
  local dir = C.AimDir(char, aim)
  if key == "M1" then m1(S, player, char, st)
  elseif key == "F" then
    if takeHidden(S, char, st, "F") then
      theTruth(S, player, char, st)
    else
      victoriousThrow(S, player, char, st, dir)
    end
  elseif key == "C" then
    if takeHidden(S, char, st, "C") then
      supremeKingSlash(S, player, char, st, aimAssist(S, player, char, st, D.C.Range))
    else
      vowSlash(S, player, char, st, dir)
    end
  elseif key == "V" then lastStand(S, player, char, st) end
end
return K

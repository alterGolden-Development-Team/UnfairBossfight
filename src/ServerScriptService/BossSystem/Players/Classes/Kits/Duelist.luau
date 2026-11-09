 
 
 
 
 
 
local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local D = ClassConfig.Classes.Duelist
local BLUE, WHITE, SILVER = D.Color, Color3.new(1, 1, 1), Color3.fromRGB(215, 225, 240)
local ICE = Color3.fromRGB(190, 225, 255)
local CHEST = Vector3.new(0, 0.6, 0)
local GROUND = Vector3.new(0, 2.9, 0)  

local K = {}
function K.Start(S, player, char, st)
  st.Data.Tempo = 0
  st.Data.SecondUntil, st.Data.PhaseUntil = 0, 0
  st.Data.Waltzing = false
end

 
local function addTempo(S, char, st)
  st.Data.Tempo = math.min(D.TempoMax, (st.Data.Tempo or 0) + 1)
  S.Buff(char, "Tempo", D.TempoDuration)
  char:SetAttribute("ClassStatusText_Tempo", "+" .. (st.Data.Tempo * 5) .. "%")
end
function K.OnHitBoss(S, char, st, target, tag, actualDamage)
  if tag and tag:find("Duelist", 1, true) then
    local h = char:FindFirstChildOfClass("Humanoid")
    if h and h.Health > 0 and type(actualDamage) == "number" and actualDamage > 0 and actualDamage < math.huge then
      h.Health = math.min(h.MaxHealth, h.Health + actualDamage * D.Lifesteal * (workspace:GetAttribute("Phase5HealthMultiplier") or 1))
    end
    addTempo(S, char, st)
  end
end
function K.OnBuffEnded(S, char, st, id)
  if id == "Tempo" then
    st.Data.Tempo = 0
    char:SetAttribute("ClassStatusText_Tempo", nil)
  elseif id == "Riposte" and not st.Data.Countered and not st.Data.CHeld then
    S.FX.HQ.Smoke(char.HumanoidRootPart.Position, Color3.fromRGB(120, 120, 130), 1.5, 6, 3, 2)
  end
end
 
function K.OnDodged(S, char, st)
  if not S.HasBuff(char, "DuelistGuard") then
    S.Buff(char, "DuelistGuard", D.GuardDuration)
    S.FX.HQ.Glint(char.HumanoidRootPart.Position + Vector3.new(0, 1, 0), WHITE, 5, 0.4)
    S.FX.Ring(char.HumanoidRootPart.Position - Vector3.new(0, 2.6, 0), SILVER, 7, 0.35)
    S.Sound(char, "ParryStance")
  end
end

 
local function slashHit(S, p, dir, scale)
  scale = scale or 1
  S.FX.HQ.Crescent(CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, math.rad(math.random(-35, 35))), 9 * scale, math.rad(190), 1.6 * scale, BLUE, WHITE, 0.3)
  S.FX.Hit(p, BLUE, 1.3 * scale, false)
  S.FX.HQ.Shake(p, 50, 0.15, 0.35)
end

local function counterSlash(S, player, char, st)
  if not S.CanAct(char) then
    return
  end
  S.Buff(char, "Phasing", 0.55)
  local attack = S.NewAttack(char, "DuelistRiposte")
  local root = char.HumanoidRootPart
  char:SetAttribute("Stamina", math.min(char:GetAttribute("MaxStamina") or D.Stamina, (char:GetAttribute("Stamina") or 0) + D.C.CounterStamina))
  S.Cooldown(char, "C", D.C.SuccessCooldown)
  local riposteHum = char:FindFirstChildOfClass("Humanoid")
  if riposteHum and riposteHum.Health > 0 then riposteHum.Health = math.min(riposteHum.MaxHealth, riposteHum.Health + riposteHum.MaxHealth * D.RiposteHeal) end
  S.Anim(char, "RiposteStrike")
  S.Sound(char, "ParryContact")
  local boss = S.AimTarget(char, st.Aim, 40) or S.Boss()
  local dir = boss and C.AimDir(char, boss.HumanoidRootPart.Position) or C.AimDir(char, nil)
  local eye = root.Position + Vector3.new(0, 0.6, 0)
  S.FX.HQ.Glint(eye + dir * 1.5, WHITE, 7, 0.3)
  S.FX.HQ.Crescent(CFrame.lookAt(eye, eye + dir) * CFrame.Angles(0, 0, math.rad(10)), 16, math.rad(200), 2.4, WHITE, WHITE, 0.4)
  S.FX.HQ.Crescent(CFrame.lookAt(eye, eye + dir) * CFrame.Angles(0, 0, math.rad(10)), 13, math.rad(180), 1.2, BLUE, WHITE, 0.32)
  S.FX.HQ.Streaks(eye, dir, BLUE, WHITE, 18, 14, 80, 150, 5)
  S.FX.HQ.Tint(eye, WHITE, 0.3, 0.25, 90)
  if boss and (boss.HumanoidRootPart.Position - root.Position).Magnitude <= 40 then
    S.HitBoss(char, boss, D.C.CounterDamage, "DuelistRiposte", attack)
    local p = boss.HumanoidRootPart.Position
    S.FX.Hit(p, BLUE, 2.4, true)
    S.FX.HQ.Crescent(CFrame.lookAt(p, p + dir), 12, math.rad(220), 2, BLUE, WHITE, 0.4)
    S.FX.HQ.Shake(p, 80, 0.35, 0.8)
    S.Sound(char, "CounterImpact")
  end
end
function K.Incoming(S, char, st, amount)
  if S.HasBuff(char, "Riposte") then
    st.Data.Countered = true
    S.Unbuff(char, "Riposte")
    task.spawn(counterSlash, S, st.Player, char, st)
    return 0
  end
  if S.HasBuff(char, "DuelistGuard") then
    S.Unbuff(char, "DuelistGuard")
    S.FX.HQ.Glint(char.HumanoidRootPart.Position + Vector3.new(0, 1, 0), SILVER, 4, 0.3)
    return amount * (1 - D.GuardReduction)
  end
  return amount
end

 
 
 
 
local function blink(S, player, char, st, dir, damage, second)
  local attack = S.NewAttack(char, "DuelistFlash")
  if not attack then
    return
  end
  local root = char.HumanoidRootPart
  local windup, travel = D.F.Windup, D.F.BlinkTime
  local from = root.Position
  S.Buff(char, "Phasing", windup + travel + 0.3)
  S.Anim(char, second and "FlashB" or "Flash")
  S.Sound(char, "TeleportOut")
  S.Remote():FireClient(player, "Blink", { Direction = dir, Distance = D.F.Distance, Delay = windup, Time = travel })
  S.Remote():FireClient(player, "Cinema", { Mode = "Blink", Power = 1 })
   
  S.FX.Afterimage(char, BLUE, 0.55)
  S.FX.HQ.Flash(from + CHEST, WHITE, 2.6, 0.2, 0)
  S.FX.HQ.Glint(from + CHEST, BLUE, 4.5, 0.25)
  S.FX.Ring(from - GROUND, BLUE, 10, 0.35, 0.8)
  S.FX.HQ.Light(from + CHEST, BLUE, 6, 24, 0.25)
  task.delay(windup, function()
    if not S.AttackValid(char, attack) then
      return
    end
    local origin = root.Position
    local dest = C.Path(S, char, dir, D.F.Distance)
    local a, b = origin + CHEST, dest + CHEST
     
    S.FX.AfterimageTrail(char, BLUE, origin, dest, 4, 0.42)
    S.FX.HQ.Beam(a, b, 1.1, BLUE, WHITE, 0.42)
    S.FX.HQ.Beam(a, b, 0.4, WHITE, WHITE, 0.28)
    S.FX.HQ.Streaks(a, dir, BLUE, WHITE, 16, 10, 80, 150, 3.5)
    local target = C.SegmentTarget(S, origin, dest, 7.5)
    task.delay(travel, function()
      if not S.Alive(char) then
        return
      end
      local landing = dest + CHEST
      S.Sound(char, "TeleportIn")
      S.FX.HQ.Flash(landing, WHITE, 3.2, 0.22, 0)
      S.FX.Ring(dest - GROUND, ICE, 12, 0.4, 1)
      S.FX.HQ.Sparks(landing, BLUE, WHITE, 18, 25, 60, 0.45)
      S.FX.HQ.Light(landing, BLUE, 7, 26, 0.3)
       
      S.FX.HQ.Crescent(CFrame.lookAt(landing, landing + dir) * CFrame.Angles(0, 0, math.rad(second and 10 or -10)), 7, math.rad(165), 1.3, ICE, WHITE, 0.28, { Reverse = second })
      S.FX.HQ.Shake(landing, 40, 0.12, 0.3)
      if target and S.Alive(target) and S.AttackValid(char, attack) then
        local landed = S.HitBoss(char, target, damage, "DuelistFlash", attack)
        slashHit(S, target.HumanoidRootPart.Position, dir)
        S.Sound(char, "NormalImpact")
        if landed and not second then
          st.Data.SecondUntil = os.clock() + D.F.Window
          S.Buff(char, "FlashstepReady", D.F.Window)
        end
      end
    end)
  end)
end

 
 
 
local function phaseDash(S, player, char, st, dir, second)
  local attack = S.NewAttack(char, "DuelistPhase")
  if not attack then
    return
  end
  local root = char.HumanoidRootPart
  local from = root.Position
  local distance, time = D.C.DashDistance, D.C.DashTime
  local dest = C.Path(S, char, dir, distance)
  S.Buff(char, "Phasing", time + 0.2)
  S.Anim(char, second and "PhaseB" or "PhaseA")
  S.Sound(char, "ThrustBurst")
   
  local origin = from + CHEST + dir * 3
  local frame = CFrame.lookAt(origin, origin + dir) * CFrame.Angles(math.rad(8), 0, math.rad(second and 8 or -8))
  S.FX.HQ.Crescent(frame, 6.8, math.rad(170), 1.4, SILVER, WHITE, 0.2, { Reverse = second })
  S.FX.HQ.Crescent(frame, 5.4, math.rad(150), 0.6, BLUE, WHITE, 0.16, { Reverse = second })
  S.FX.AfterimageTrail(char, BLUE, from, dest, 3, 0.4)
  S.FX.HQ.Streaks(from + CHEST, dir, BLUE, WHITE, 12, 14, 70, 130, 3)
  S.FX.HQ.Glint(from + CHEST, WHITE, 3, 0.2)
  S.FX.Ring(from - GROUND, BLUE, 7, 0.3, 0.6)
  local hit = false
  C.Move(S, player, char, dir, distance / time, time, {
    ContactRadius = 6.5,
    OnContact = function(target)
      if hit then
        return
      end
      hit = true
      S.HitBoss(char, target, D.C.DashDamage, "DuelistPhase", attack)
      slashHit(S, target.HumanoidRootPart.Position, dir)
      S.Sound(char, "NormalImpact")
    end,
  })
   
  task.delay(time + 0.08, function()
    if not S.Alive(char) then
      return
    end
    S.FX.HQ.Beam(from + CHEST, root.Position + CHEST, 0.7, BLUE, WHITE, 0.35)
    S.FX.Ring(root.Position - GROUND, ICE, 8, 0.3, 0.7)
  end)
end

 
local function phaseSlash(S, player, char, st)
  local attack = S.NewAttack(char, "DuelistPhaseSlash")
  if not attack then
    return
  end
  local root = char.HumanoidRootPart
  local boss = S.AimTarget(char, st.Aim, 40) or S.Boss()
  local dir = C.AimDir(char, st.Aim)
  local from = root.Position
  local distance, time = D.C.SlashDistance, 0.12
  S.Buff(char, "Phasing", 0.55)
  S.Anim(char, "PhaseSlash")
  S.Sound(char, "CrescentRelease")
  S.Sound(char, "ThrustBurst")
  S.FX.Release(from + CHEST, dir, BLUE, 1.4)
  S.FX.HQ.Flash(from + CHEST, WHITE, 4, 0.2, 0)
  S.FX.Ring(from - GROUND, BLUE, 12, 0.4, 1)
  S.Remote():FireClient(player, "Cinema", { Mode = "Blink", Power = 1 })
  local hit = false
  local function land(target)
    if hit or not S.Alive(target) then
      return
    end
    hit = true
    S.HitBoss(char, target, D.C.SlashDamage, "DuelistPhaseSlash", attack)
    local p = target.HumanoidRootPart.Position
    S.FX.Hit(p, BLUE, 2.2, true)
    S.FX.HQ.Crescent(CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, math.rad(12)), 13, math.rad(200), 2.2, BLUE, WHITE, 0.4)
    S.FX.HQ.Shake(p, 80, 0.3, 0.8)
    S.FX.HQ.Tint(p, BLUE, 0.3, 0.25, 100)
    S.Sound(char, "CounterImpact")
  end
  local homing = boss and (boss.HumanoidRootPart.Position - from).Magnitude <= 40 and boss or nil
  C.Move(S, player, char, dir, distance / time, time, { Homing = homing, ContactRadius = 9, OnContact = land })
  S.FX.AfterimageTrail(char, BLUE, from, C.Path(S, char, dir, distance), 4, 0.45)
   
  task.delay(0.06, function()
    if not S.Alive(char) then
      return
    end
    local origin = root.Position + CHEST + dir * 4.5
    local frame = CFrame.lookAt(origin, origin + dir) * CFrame.Angles(math.rad(8), 0, math.rad(-6))
    S.FX.HQ.Crescent(frame, 13, math.rad(210), 2.8, BLUE, WHITE, 0.45)
    S.FX.HQ.Crescent(frame, 10.5, math.rad(190), 1.2, ICE, WHITE, 0.36)
    S.FX.HQ.Streaks(origin, dir, BLUE, WHITE, 24, 40, 90, 170, 4)
    S.FX.HQ.Shake(origin, 60, 0.18, 0.5)
  end)
   
  task.delay(time + 0.05, function()
    if hit or not S.AttackValid(char, attack) then
      return
    end
    local target = S.TargetNear(root.Position + dir * 4, 13)
    if target then
      land(target)
    end
  end)
end

 
local function beginPhaseCharge(S, player, char, st, started)
  local root = char.HumanoidRootPart
  char:SetAttribute("ClassAimStream", true)  
  S.Buff(char, "PhaseCharge", D.C.ChargeTime - D.C.HoldThreshold + 0.3)
  S.Buff(char, "Riposte", D.C.Stance)
  S.Sound(char, "ParryStance")
  S.FX.HQ.Glint(C.Hand(char), WHITE, 4, 0.3)
  task.spawn(function()
    while st.Data.CStart == started and S.Alive(char) and not st.Data.Countered and st.Data.CHeld and S.CanAct(char) do
      local elapsed = os.clock() - started
      if elapsed >= D.C.ChargeTime then
        st.Data.CHeld = false
        S.Unbuff(char, "PhaseCharge")
        S.Unbuff(char, "Riposte")
        char:SetAttribute("ClassAimStream", nil)
        phaseSlash(S, player, char, st)
        return
      end
      local p = elapsed / D.C.ChargeTime
      S.FX.Charge(C.Hand(char), p < 0.7 and BLUE or WHITE, 0.25, 0.9 + p * 1.6)
      S.FX.HQ.Shockwave(CFrame.new(root.Position - GROUND), 11, 1.5, 0.3, BLUE, 0.4, 0.3)
      task.wait(0.15)
    end
     
    S.Unbuff(char, "PhaseCharge")
    char:SetAttribute("ClassAimStream", nil)
  end)
end

 
 
 
 
 
 
 
 
local CUTS = {
  { Angle = 0.0, Radius = 6.5, Anim = "WaltzCutA", Roll = 0, Reverse = false },  
  { Angle = 2.5, Radius = 8.0, Anim = "WaltzCutB", Roll = 0, Reverse = true },  
  { Angle = -1.4, Radius = 7.0, Anim = "WaltzCutC", Roll = 90, Reverse = true },  
  { Angle = 4.0, Radius = 8.5, Anim = "WaltzCutD", Roll = 90, Reverse = false },  
  { Angle = 1.2, Radius = 6.5, Anim = "WaltzCutA", Roll = -45, Reverse = false },  
}
local function spot(center, angle, radius, y)
  return Vector3.new(center.X + math.cos(angle) * radius, y, center.Z + math.sin(angle) * radius)
end
local function buildCuts(count, base)
  local list = {}
  for i = 1, count do
    local spec = CUTS[(i - 1) % #CUTS + 1]
    local lap = math.floor((i - 1) / #CUTS)
    list[i] = { Angle = base + spec.Angle + lap * 0.8, Radius = spec.Radius, Spec = spec }
  end
  return list
end

 
local function vanish(S, player, char, from, to)
  S.Sound(char, "TeleportOut")
  S.FX.Afterimage(char, BLUE, 0.6)
  S.FX.HQ.Flash(from + CHEST, WHITE, 4, 0.25, 0)
  S.FX.HQ.Streaks(from + CHEST, Vector3.yAxis, BLUE, WHITE, 24, 25, 60, 140, 3)
  S.FX.Ring(from - GROUND, BLUE, 16, 0.5, 1.2)
  S.FX.HQ.Light(from + CHEST, BLUE, 8, 34, 0.35)
  S.FX.HQ.Bolt(from + CHEST, to + CHEST, BLUE, WHITE, 0.9, 2.2, 9, 0.35, true)
  S.FX.HQ.Beam(from + CHEST, to + CHEST, 1.6, BLUE, WHITE, 0.5)
  S.Remote():FireClient(player, "Cinema", { Mode = "Blink", Power = 2 })
end

 
local function charge(S, player, char, attack)
  local root = char.HumanoidRootPart
  local time = D.V.ChargeTime
  S.Buff(char, "WaltzCharge", time + 0.25)
  S.Buff(char, "Recovering", time, { Speed = 0.25 })  
  S.Sound(char, "RoyalFinalCharge")
  S.Remote():FireClient(player, "Cinema", { Mode = "Charge", Duration = time })
  S.FX.HQ.Spikes(root.Position - GROUND, 1, 3, 20, BLUE, WHITE, time)
  S.FX.HQ.Tint(root.Position, BLUE, 0.2, time, 90)
  local started = os.clock()
  while os.clock() - started < time do
    if not S.AttackValid(char, attack) then
      return false
    end
    local p = (os.clock() - started) / time
    S.FX.Charge(C.Hand(char), p < 0.6 and BLUE or WHITE, 0.3, 1.1 + p * 2.4)
    S.FX.HQ.Shockwave(CFrame.new(root.Position - GROUND), 16, 2, 0.3, BLUE, 0.4, 0.4)
    task.wait(0.2)
  end
  return S.AttackValid(char, attack)
end

local function waltz(S, player, char, st, boss, teleported)
  local attack = S.NewAttack(char, "DuelistWaltz")
  if not attack then
    return false
  end
  local root = char.HumanoidRootPart
  local remote = S.Remote()
  local count, interval = D.V.Cuts, 0.17

  if teleported and not charge(S, player, char, attack) then
    return false
  end
  if not S.Alive(boss) then
    return false
  end

  local center = boss.HumanoidRootPart.Position
  local py = root.Position.Y
  local offset = root.Position - center
  local base = math.atan2(offset.Z, offset.X)
  local cuts = buildCuts(count, base)
  S.Buff(char, "Phasing", 6)  

  if teleported then
     
    local arrival = spot(center, cuts[1].Angle, cuts[1].Radius, py)
    vanish(S, player, char, root.Position, arrival)
    S.Unbuff(char, "WaltzCharge")
    remote:FireClient(player, "Waltz", { Boss = boss, Start = workspace:GetServerTimeNow(), Steps = { { T = 0, Angle = cuts[1].Angle, Radius = cuts[1].Radius } } })
    local deadline = os.clock() + 0.7
    while os.clock() < deadline and S.Alive(boss) and (root.Position - boss.HumanoidRootPart.Position).Magnitude > 18 do
      task.wait()
    end
    if not S.AttackValid(char, attack) or not S.Alive(boss) then
      return false
    end
     
    if not S.ResolveBossDefense(char, boss, attack) then
      return false
    end
    S.Sound(char, "TeleportIn")
    S.FX.Impact(boss.HumanoidRootPart.Position, BLUE, 1.6)
    S.FX.HQ.Light(arrival + CHEST, BLUE, 8, 30, 0.35)
  end

   
  center = boss.HumanoidRootPart.Position
  local firstT = 0.08
  local lastCutT = firstT + (count - 1) * interval
  local raiseT = lastCutT + 0.18  
  local impactT = raiseT + 0.30  
  local finish = { Angle = base + 0.35, Radius = 6 }
  local steps = {}
  for i = 1, count do
    steps[#steps + 1] = { T = firstT + (i - 1) * interval, Angle = cuts[i].Angle, Radius = cuts[i].Radius }
  end
  steps[#steps + 1] = { T = raiseT, Angle = finish.Angle, Radius = finish.Radius }
  remote:FireClient(player, "Waltz", { Boss = boss, Start = workspace:GetServerTimeNow(), Steps = steps })
  local t0 = os.clock()
  local function waitUntil(t)
    local remaining = t0 + t - os.clock()
    if remaining > 0 then
      task.wait(remaining)
    end
  end
  py = root.Position.Y
  local prev = root.Position
  for i = 1, count do
    waitUntil(firstT + (i - 1) * interval)
    if not S.AttackValid(char, attack) or not S.Alive(boss) then
      return true
    end
    center = boss.HumanoidRootPart.Position
    local spec = cuts[i].Spec
    local pos = spot(center, cuts[i].Angle, cuts[i].Radius, py)
    local face = C.Flat(center - pos) or Vector3.zAxis
    local chest = pos + Vector3.new(0, 0.8, 0)
    S.Anim(char, spec.Anim)
    S.Sound(char, "NormalSwing")
    S.HitBoss(char, boss, D.V.CutDamage, "DuelistWaltz", attack)
    remote:FireClient(player, "Cinema", { Mode = "Cut", Index = i })
    if i > 1 then
      S.FX.Afterimage(char, BLUE, 0.35, prev)  
    end
     
    S.FX.HQ.Beam(prev + CHEST, pos + CHEST, 0.45, BLUE, WHITE, 0.6)
    local frame = CFrame.lookAt(chest, chest + face) * CFrame.Angles(0, 0, math.rad(spec.Roll))
    S.FX.HQ.Crescent(frame, cuts[i].Radius + 1, math.rad(165), 1.8, BLUE, WHITE, 0.3, { Reverse = spec.Reverse })
    S.FX.HQ.Crescent(frame, cuts[i].Radius, math.rad(150), 0.7, WHITE, WHITE, 0.22, { Reverse = spec.Reverse })
    S.FX.HQ.Sparks(center, BLUE, WHITE, 12, 20, 50, 0.3)
    S.FX.HQ.Flash(center, WHITE, 2, 0.12, 0)
    S.FX.HQ.Shake(center, 45, 0.1, 0.3)
    prev = pos
  end

   
  waitUntil(raiseT)
  if not S.AttackValid(char, attack) or not S.Alive(boss) then
    return true
  end
  center = boss.HumanoidRootPart.Position
  local finishPos = spot(center, finish.Angle, finish.Radius, py)
  S.Anim(char, "WaltzFinish")
  S.Sound(char, "RoyalFinalCharge")
  S.FX.Afterimage(char, BLUE, 0.4, prev)
  S.FX.HQ.Beam(prev + CHEST, finishPos + CHEST, 0.6, BLUE, WHITE, 0.4)
  S.FX.HQ.Glint(finishPos + Vector3.new(0, 5, 0), WHITE, 7, 0.3)
  S.FX.HQ.Spikes(finishPos - GROUND, 1, 2, 14, BLUE, WHITE, 0.3)
  remote:FireClient(player, "Cinema", { Mode = "Raise" })

   
  waitUntil(impactT)
  if not S.AttackValid(char, attack) or not S.Alive(boss) then
    return true
  end
  center = boss.HumanoidRootPart.Position
  local face = C.Flat(center - finishPos) or Vector3.zAxis
  local chest = finishPos + Vector3.new(0, 0.8, 0)
  local ground = Vector3.new(center.X, py - GROUND.Y + 0.1, center.Z)
  S.Sound(char, "CrescentRelease")
  S.Sound(char, "RoyalFinalImpact")
  S.HitBoss(char, boss, D.V.FinishDamage, "DuelistWaltz", attack)
  remote:FireClient(player, "Cinema", { Mode = "Finish" })
   
  local vertical = CFrame.lookAt(chest, chest + face) * CFrame.Angles(0, 0, math.rad(90))
  S.FX.HQ.Crescent(vertical, 11, math.rad(200), 3, BLUE, WHITE, 0.5, { Reverse = true })
  S.FX.HQ.Crescent(vertical * CFrame.Angles(0, 0, math.rad(-12)), 9.5, math.rad(185), 1.4, WHITE, WHITE, 0.4, { Reverse = true })
  S.FX.Hit(center, BLUE, 2.8, true)
  S.FX.HQ.Impact(center, BLUE, WHITE, 1.8)
   
  S.FX.HQ.Shockwave(CFrame.new(ground), 3, D.V.ShockwaveRadius, 0.55, BLUE, 0.1, 1.4)
  task.delay(0.08, function()
    S.FX.HQ.Shockwave(CFrame.new(ground), 2, D.V.ShockwaveRadius * 0.7, 0.45, WHITE, 0.2, 0.9)
  end)
  S.FX.HQ.Spikes(ground, 5, 6, 16, BLUE, WHITE, 0.6)
  S.FX.HQ.Debris(ground, 14, Color3.fromRGB(150, 150, 165), 1.1, 42, nil, 1.1)
  S.FX.HQ.Smoke(ground, Color3.fromRGB(190, 200, 215), 5, 8, 20, 2)
  S.FX.HQ.Light(center, BLUE, 10, 40, 0.5)
  S.FX.HQ.Shake(center, 100, 0.45, 1)
  S.FX.HQ.Tint(center, WHITE, 0.4, 0.3, 120)
  for _, target in ipairs(S.Targets()) do
    if target ~= boss then
      local delta = target.HumanoidRootPart.Position - ground
      if Vector3.new(delta.X, 0, delta.Z).Magnitude <= D.V.ShockwaveRadius then
        S.HitBoss(char, target, D.V.ShockwaveDamage, "DuelistWaltz", attack)
      end
    end
  end

   
  waitUntil(impactT + 0.3)
  if S.AttackValid(char, attack) then
    local away = C.Flat(root.Position - center) or -face
    C.Move(S, player, char, away, 14 / 0.2, 0.2)
  end
  waitUntil(impactT + 0.8)
  S.Buff(char, "Recovering", 0.6, { Speed = 0.5 })
  return true
end

local function runWaltz(S, player, char, st, boss, teleported)
  st.Data.Waltzing = true
   
  S.Buff(char, "Phasing", D.V.ChargeTime + D.V.Cuts * 0.17 + 4)
  local ok, result = pcall(waltz, S, player, char, st, boss, teleported)
  st.Data.Waltzing = false
  S.Unbuff(char, "WaltzCharge")
  S.Unbuff(char, "Phasing")
  S.Remote():FireClient(player, "Cinema", { Mode = "End" })
  if not ok then
    warn("Duelist Final Waltz: " .. tostring(result))
  end
  if not ok or result == false then
    S.Cooldown(char, "V", D.V.MissCooldown)  
  end
end

 
local function rushWaltz(S, player, char, st, boss, dir)
  local root = char.HumanoidRootPart
  S.Buff(char, "Phasing", 1.2)  
  S.Anim(char, "WaltzRush")
  S.FX.Release(root.Position, dir, BLUE, 1)
  S.Sound(char, "FallingCharge")
  S.FX.HQ.Glint(C.Hand(char), WHITE, 5, 0.25)
  S.FX.HQ.Streaks(root.Position, dir, BLUE, WHITE, 12, 10, 80, 140, 4)
  local attack = S.NewAttack(char, "DuelistWaltzOpener")
  local opened = false
  C.Move(S, player, char, player:GetAttribute("ClassAutoAim") ~= false and boss and C.AimDir(char, boss.HumanoidRootPart.Position) or dir, 90, 0.45, {
    Homing = boss,
    ContactRadius = 7,
    StopOnContact = true,
    OnContact = function(target)
      if not S.ResolveBossDefense(char, target, attack) then
        return
      end
      opened = true
      S.FX.Impact(target.HumanoidRootPart.Position, BLUE, 1.6)
      task.spawn(runWaltz, S, player, char, st, target, false)
    end,
    OnEnd = function()
      if not opened then
        S.Unbuff(char, "Phasing")
        S.Cooldown(char, "V", D.V.MissCooldown)
      end
    end,
  })
end

function K.Action(S, player, char, st, key, phase, aim)
  local root = char.HumanoidRootPart
  local dir = C.AimDir(char, aim)
  if key == "Aim" then
    return
  end
  if st.Data.Waltzing then
    return  
  end
  if key == "M1" and phase == "Begin" then
    if not S.Ready(char, "M1") then
      return
    end
    S.Cooldown(char, "M1", D.M1.Cooldown / (1 + D.TempoPerHit * (st.Data.Tempo or 0)))
    local attack = S.NewAttack(char, "DuelistM1")
     
    st.Data.Swing = not st.Data.Swing
    local forward = st.Data.Swing
    S.Anim(char, forward and "SwiftA" or "SwiftB")
    S.Sound(char, "NormalSwing")
     
    task.delay(0.09, function()
      if not attack or not S.AttackValid(char, attack) then
        return
      end
      local eye = root.Position + Vector3.new(0, 0.8, 0)
      local frame = CFrame.lookAt(eye, eye + dir) * CFrame.Angles(math.rad(10), 0, 0)
      S.FX.HQ.Crescent(frame, 6.4, math.rad(150), 1.1, SILVER, WHITE, 0.2, { Reverse = not forward })
      S.FX.HQ.Crescent(frame, 5.2, math.rad(130), 0.5, BLUE, WHITE, 0.15, { Reverse = not forward })
      S.FX.Release(eye + dir * 3.5, dir, BLUE, 0.4)
      local target = S.TargetNear(root.Position + dir * 4.5, D.M1.Range * 0.65)
      if target and C.InFront(char, target, D.M1.Range + 4, -0.2) then
        S.HitBoss(char, target, D.M1.Damage, "DuelistM1", attack)
        S.FX.Hit(target.HumanoidRootPart.Position, BLUE, 0.85, false)
      end
    end)
  elseif key == "F" and phase == "Begin" then
    local second = (st.Data.SecondUntil or 0) > os.clock()
    if not second and not S.Ready(char, "F") then
      return
    end
    if not S.SpendStamina(char, D.F.StaminaCost) then
      return
    end
    if second then
      st.Data.SecondUntil = 0
      S.Unbuff(char, "FlashstepReady")
      blink(S, player, char, st, dir, D.F.SecondDamage, true)
    else
      S.Cooldown(char, "F", D.F.Cooldown)
      blink(S, player, char, st, dir, D.F.Damage, false)
    end
  elseif key == "C" then
    if phase == "Begin" then
       
      if (st.Data.PhaseUntil or 0) > os.clock() then
        if not S.SpendStamina(char, D.C.SecondStaminaCost) then
          return
        end
        st.Data.PhaseUntil = 0
        S.Unbuff(char, "PhasingReady")
        phaseDash(S, player, char, st, dir, true)
        return
      end
      if not S.Ready(char, "C") or not S.SpendStamina(char, D.C.StaminaCost) then
        return
      end
      S.Cooldown(char, "C", D.C.Cooldown)
      local started = os.clock()
      st.Data.CStart, st.Data.CHeld, st.Data.Countered = started, true, false
      S.Buff(char, "Phasing", D.C.ChargeTime + 0.5)  
      task.delay(D.C.HoldThreshold, function()
        if st.Data.CHeld and st.Data.CStart == started and S.Alive(char) and S.CanAct(char) then
          beginPhaseCharge(S, player, char, st, started)
        end
      end)
    elseif phase == "End" and st.Data.CHeld then
      st.Data.CHeld = false
      if os.clock() - (st.Data.CStart or 0) < D.C.HoldThreshold then
         
        st.Data.PhaseUntil = os.clock() + D.C.Window
        S.Buff(char, "PhasingReady", D.C.Window)
        phaseDash(S, player, char, st, dir, false)
      else
         
        S.Unbuff(char, "Phasing")
        S.Unbuff(char, "PhaseCharge")
        S.Unbuff(char, "Riposte")
        char:SetAttribute("ClassAimStream", nil)
        if not st.Data.Countered then
          S.Cooldown(char, "C", D.C.CancelCooldown)
        end
      end
    end
  elseif key == "V" and phase == "Begin" then
    if not S.Ready(char, "V") or not S.SpendStamina(char, D.V.StaminaCost) then
      return
    end
    S.Cooldown(char, "V", D.V.Cooldown)
    local boss = S.AimTarget(char, st.Aim, D.V.TeleportRadius) or S.Boss()
    if boss and (boss.HumanoidRootPart.Position - root.Position).Magnitude <= D.V.TeleportRadius then
      task.spawn(runWaltz, S, player, char, st, boss, true)
    else
      rushWaltz(S, player, char, st, boss, dir)
    end
  end
end
return K

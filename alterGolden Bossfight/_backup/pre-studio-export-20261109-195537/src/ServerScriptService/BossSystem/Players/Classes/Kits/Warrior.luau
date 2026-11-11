 
local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local D = ClassConfig.Classes.Warrior
local RED, STEEL, GOLD = D.Color, Color3.fromRGB(205, 210, 220), Color3.fromRGB(240, 200, 90)
local WHITE = Color3.new(1, 1, 1)

 
local SWEEP_STRIKE = 0.11  
local SLAM_STRIKE = 0.22  
local CONCLUSION_TIME = 0.12  
local BASH_DELAY = 0.1  

 
 
local function targetOnPath(S, a, b, radius)
  local best, bestD
  for _, m in ipairs(S.Targets()) do
    local p = m.HumanoidRootPart.Position
    if math.abs(p.Y - a.Y) <= 9 then
      local d = C.SegmentDistance(Vector3.new(p.X, a.Y, p.Z), a, b)
      if d <= radius and (not bestD or d < bestD) then
        best, bestD = m, d
      end
    end
  end
  return best
end

local K = {}

function K.Start(S, player, char, st)
  st.Data.Mode = "Offensive"
  char:SetAttribute("ClassMode", "Offensive")
end
 
function K.OnDamaged(S, char, st)
  S.StatBuff(char, "BattleHardened", D.PassiveDuration, { Attack = D.PassiveAttack, Defense = D.PassiveDefense })
end
 
function K.Incoming(S, char, st, amount)
  if S.HasBuff(char, "ParryStance") then
    st.Data.Parried = true
    S.Unbuff(char, "ParryStance")
    S.StatBuff(char, "PerfectParry", D.V.ParryBuff, { HealthRegen = 4, StaminaRegen = 2, Attack = 1.3 })
    local p = char.HumanoidRootPart.Position
    S.FX.Flash(p, Color3.fromRGB(255, 236, 150), 10, 0.35)
    S.FX.Ring(p, GOLD, 9, 0.4)
    S.FX.Text(p + Vector3.new(0, 3, 0), "PARRY!", GOLD)
    S.Anim(char, "ParrySuccess")
    S.Sound(char, "ParryContact")
    S.FX.HQ.Glint(p + Vector3.new(0, 1, -1), Color3.new(1, 1, 1), 6, 0.3)
    S.FX.HQ.Spikes(p - Vector3.new(0, 2.6, 0), 6, 4, 9, GOLD, Color3.new(1, 1, 1), 0.5)
    S.FX.Hit(p, GOLD, 1.4, true)
    S.FX.HQ.Shake(p, 40, 0.2, 0.4)
    return 0
  end
  return amount
end
function K.OnBuffEnded(S, char, st, id)
  if id == "ParryStance" and not st.Data.Parried then
     
    S.Buff(char, "ParryLocked", D.V.ParryFailLock)
    S.Cooldown(char, "V", D.V.Cooldown - D.V.ParryWindow + D.V.ParryFailLock)
    S.FX.Text(char.HumanoidRootPart.Position + Vector3.new(0, 3, 0), "PARRY FAILED", Color3.fromRGB(170, 170, 180))
  end
end

function K.Action(S, player, char, st, key, phase, aim)
  if phase ~= "Begin" or not S.Ready(char, key) then
    return
  end
  local root = char.HumanoidRootPart
  local dir = C.AimDir(char, aim)
  if key == "M1" then
    S.Cooldown(char, "M1", D.M1.Cooldown)
     
    local now = os.clock()
    st.Data.Combo = (now - (st.Data.LastM1 or 0) < 1.1) and (st.Data.Combo % 3) + 1 or 1
    st.Data.LastM1 = now
    local attack = S.NewAttack(char, "WarriorM1")
    local hit = st.Data.Combo
    S.Anim(char, ({ "SlashA", "SlashB", "Chop" })[hit])
    S.Sound(char, "NormalSwing")
    task.wait(hit == 3 and SLAM_STRIKE or SWEEP_STRIKE)  
    if not S.CanAct(char) then
      return
    end
    local eye = root.Position + Vector3.new(0, 0.6, 0)
    local frame = CFrame.lookAt(eye, eye + dir)
    S.FX.Release(eye + dir * 2, dir, RED, hit == 3 and 0.9 or 0.6)
    if hit == 3 then
      S.Sound(char, "FallingImpact")
       
      S.FX.HQ.Crescent(frame * CFrame.Angles(0, 0, math.rad(90)), 8, math.rad(150), 1.8, RED, WHITE, 0.32, { Reverse = true })
      local ground = root.Position + dir * 6 - Vector3.new(0, 2.6, 0)
      S.FX.Ring(ground, RED, 12, 0.45, 0.8)
      S.FX.HQ.Debris(ground, 8, Color3.fromRGB(150, 120, 90), 0.55, 28)
      S.FX.HQ.Shake(ground, 45, 0.2, 0.45)
    else
       
      local sweep = hit == 1 and { Reverse = true } or nil
      local side = frame.RightVector * (hit == 1 and -1 or 1)
      S.FX.HQ.Crescent(frame, D.M1.Range * 0.95, math.rad(170), 1.4, Color3.fromRGB(255, 120, 105), WHITE, 0.26, sweep)
      S.FX.HQ.Crescent(frame, D.M1.Range * 0.7, math.rad(150), 0.6, WHITE, WHITE, 0.18, sweep)
      S.FX.HQ.Streaks(eye + dir * 3, (side + dir * 0.35).Unit, RED, WHITE, 7, 30, 30, 70, 2.5)
    end
    local target = S.TargetNear(root.Position + dir * (D.M1.Range * 0.5), D.M1.Range * 0.75)
    if target and C.InFront(char, target, D.M1.Range + 5, -0.2) then
      S.HitBoss(char, target, D.M1.Damage, "WarriorM1", attack)
      local p = target.HumanoidRootPart.Position
      S.FX.Hit(p, RED, hit == 3 and 1.8 or 1.1, hit == 3)
      S.Sound(char, hit == 3 and "CounterImpact" or "NormalImpact")
      S.FX.HQ.Shake(p, 45, 0.15, hit == 3 and 0.55 or 0.3)
    end
  elseif key == "F" then
    S.Cooldown(char, "F", D.F.Cooldown)
    st.Data.Mode = st.Data.Mode == "Offensive" and "Defensive" or "Offensive"
    char:SetAttribute("ClassMode", st.Data.Mode)
    S.Anim(char, "Stance")
    S.Sound(char, "GuardActivate")
    S.FX.Ring(root.Position - Vector3.new(0, 2.5, 0), st.Data.Mode == "Offensive" and RED or GOLD, 7, 0.35)
    S.FX.HQ.Glint(C.Hand(char), st.Data.Mode == "Offensive" and RED or GOLD, 3, 0.4)
    S.FX.Text(root.Position + Vector3.new(0, 3, 0), string.upper(st.Data.Mode), st.Data.Mode == "Offensive" and RED or GOLD)
  elseif key == "C" then
    S.Cooldown(char, "C", D.C.Cooldown)
    if st.Data.Mode == "Offensive" then
       
   local attack = S.NewAttack(char,"WarriorX")
      S.Anim(char, "XSlash")
      S.Sound(char, "CrescentCharge")
      S.FX.Charge(C.Hand(char), RED, 0.24, 1.6)
      task.wait(0.24)  
      if not S.CanAct(char) then
        return
      end
      dir = C.AimDir(char, aim)
      local eye = root.Position + Vector3.new(0, 0.8, 0)
      S.FX.Slash(CFrame.lookAt(eye, eye + dir) * CFrame.Angles(0, 0, math.rad(45)), RED, 6, 160, 0.3)
      S.FX.Slash(CFrame.lookAt(eye, eye + dir) * CFrame.Angles(0, 0, math.rad(-45)), RED, 6, 160, 0.3)
      local origin = root.Position + dir * 3 + Vector3.new(0, 0.8, 0)
       
      S.FX.HQ.Crescent(CFrame.lookAt(origin, origin + dir) * CFrame.Angles(0, 0, math.rad(45)), 10, math.rad(190), 2.2, RED, Color3.new(1, 1, 1), 0.35)
      S.FX.HQ.Crescent(CFrame.lookAt(origin, origin + dir) * CFrame.Angles(0, 0, math.rad(-45)), 10, math.rad(190), 2.2, RED, Color3.new(1, 1, 1), 0.35)
      S.FX.HQ.Streaks(origin, dir, RED, Color3.new(1, 1, 1), 14, 18, 60, 120, 4)
      S.FX.HQ.Light(origin, RED, 5, 24, 0.3)
      S.Sound(char, "CrescentRelease")
       
      local carrier = S.FX.Part({ Size = Vector3.one * 0.2, Transparency = 1 })
      local core = S.FX.Part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, Color = Color3.new(1, 1, 1), Transparency = 0.1 })
      S.FX.Trail(core, RED, 5)
      local hit, step = false, 0
      S.FX.Projectile(origin, dir, D.C.XSpeed, D.C.XRange, carrier, function(pos)
        step += 1
        if core.Parent then
          core.CFrame = CFrame.new(pos)
        end
        if step % 3 == 0 then
          local f = CFrame.lookAt(pos, pos + dir)
          S.FX.HQ.Crescent(f * CFrame.Angles(0, 0, math.rad(45)), 5.5, math.rad(170), 1.4, RED, Color3.new(1, 1, 1), 0.2)
          S.FX.HQ.Crescent(f * CFrame.Angles(0, 0, math.rad(-45)), 5.5, math.rad(170), 1.4, RED, Color3.new(1, 1, 1), 0.2)
        end
        if not S.AttackValid(char,attack) then return true end
    local target = S.TargetNear(pos, 6)
        if target and not hit then
          hit = true
          attack.Origin=pos
     S.HitBoss(char,target,D.C.XDamage,"WarriorX",attack)
          local f = CFrame.lookAt(pos, pos + dir)
          S.FX.Hit(pos, RED, 2.4, true)
          S.FX.HQ.Crescent(f * CFrame.Angles(0, 0, math.rad(45)), 14, math.rad(220), 2.6, RED, Color3.new(1, 1, 1), 0.45)
          S.FX.HQ.Crescent(f * CFrame.Angles(0, 0, math.rad(-45)), 14, math.rad(220), 2.6, RED, Color3.new(1, 1, 1), 0.45)
          S.FX.Ring(target.HumanoidRootPart.Position - Vector3.new(0, 3, 0), RED, 20, 0.6, 1)
          S.FX.HQ.Spikes(target.HumanoidRootPart.Position - Vector3.new(0, 3, 0), 5, 7, 14, RED, Color3.new(1, 1, 1), 0.6)
          S.FX.HQ.Sparks(pos, RED, Color3.new(1, 1, 1), 40, 30, 80, 0.5)
          S.FX.HQ.Shake(pos, 90, 0.4, 0.85)
          S.FX.HQ.Tint(pos, RED, 0.35, 0.3, 120)
          S.Sound(char, "RangedX")
          if core.Parent then
            core:Destroy()
          end
          return true
        end
      end)
      task.delay(D.C.XRange / D.C.XSpeed + 0.2, function()
        if core.Parent then
          core:Destroy()
        end
      end)
    else
       
       
      local attack = S.NewAttack(char, "WarriorSlam")
      S.Buff(char, "ShieldRaised", D.C.SlamDuration, { Defense = D.C.SlamDefense, Speed = D.C.SlamSpeed })
      S.Sound(char, "FallingCharge")
      S.FX.HQ.Glint(C.Hand(char, "Left"), GOLD, 4, 0.3)
      S.FX.HQ.Streaks(root.Position, dir, GOLD, WHITE, 10, 12, 40, 80, 3)
      local started = os.clock()
      C.Move(S, player, char, dir, 48, D.C.SlamDuration, {
        ContactRadius = 6, StopOnContact = true,
        OnContact = function(target)
           
          S.Unbuff(char, "ShieldRaised")
          local left = D.C.SlamDuration - (os.clock() - started)
          if left > 0.05 then
            S.StatBuff(char, "ShieldSlamGuard", left, { Defense = D.C.SlamDefense })
          end
          S.Anim(char, "ShieldSlam")
          task.delay(BASH_DELAY, function()
            if not S.AttackValid(char, attack) then
              return
            end
            if S.Alive(target) then  
              S.HitBoss(char, target, D.C.SlamDamage, "WarriorSlam", attack)
            end
            local at = root.Position + dir * 3 + Vector3.new(0, 0.4, 0)
            S.FX.HQ.Flash(at, WHITE, 1.6, 0.18, 0)
            S.FX.Hit(at, GOLD, 1.8, true)
            S.Sound(char, "BlockImpact")
            S.FX.Ring(root.Position - Vector3.new(0, 2.5, 0), GOLD, 14, 0.45)
            S.FX.HQ.Debris(root.Position - Vector3.new(0, 2.5, 0), 8, Color3.fromRGB(150, 130, 100), 0.6, 30)
            S.FX.HQ.Shake(at, 60, 0.25, 0.6)
          end)
        end,
      })
    end
  elseif key == "V" then
    if st.Data.Mode == "Offensive" then
      S.Cooldown(char, "V", D.V.Cooldown)
       
       
      local attack = S.NewAttack(char, "WarriorConclusion")
      S.Anim(char, "Conclusion")
      S.Sound(char, "ThrustBurst")
      local from = root.Position
      local to = from + dir * D.V.ConclusionDistance
      local lineA, lineB = from + Vector3.new(0, 0.6, 0), to + Vector3.new(0, 0.6, 0)
      S.FX.Release(from + dir * 2, dir, RED, 1.1)
      S.FX.Beam(lineA, lineB, RED, 1.5, 0.3)
      S.FX.Beam(lineA, lineB, WHITE, 0.5, 0.2)
      S.FX.HQ.Streaks(from, dir, RED, WHITE, 12, 6, 90, 150, 3.5)
      local hit = false
      local function strike(target)
        if hit then
          return
        end
        hit = true
        S.HitBoss(char, target, D.V.ConclusionDamage, "WarriorConclusion", attack)
        local p = target.HumanoidRootPart.Position
        S.FX.Hit(p, RED, 1.8, true)
        S.FX.HQ.Shake(p, 55, 0.2, 0.5)
        S.FX.HQ.Sparks(p, RED, WHITE, 30, 30, 80, 0.45)
         
        local cut = p - dir * 8 + Vector3.new(0, 0.8, 0)
        S.FX.HQ.Crescent(CFrame.lookAt(cut, cut + dir), 8, math.rad(80), 1.3, RED, WHITE, 0.22, { Reverse = true })
      end
      C.Move(S, player, char, dir, D.V.ConclusionDistance / CONCLUSION_TIME, CONCLUSION_TIME, {
        ContactRadius = 7,
        OnContact = strike,
      })
       
       
      task.delay(CONCLUSION_TIME * 0.5, function()
        if hit or not S.AttackValid(char, attack) then
          return
        end
        local target = targetOnPath(S, from, to, 9.5)
        if target then
          strike(target)
        end
      end)
       
      task.delay(CONCLUSION_TIME + 0.02, function()
        if not S.AttackValid(char, attack) then
          return
        end
        local at = to + Vector3.new(0, 0.6, 0)
        S.FX.HQ.Crescent(CFrame.lookAt(at, at + dir), 8.5, math.rad(160), 1.5, RED, WHITE, 0.26, { Reverse = true })
        S.FX.Ring(to - Vector3.new(0, 2.5, 0), RED, 8, 0.3)
      end)
    else
       
      S.Cooldown(char, "V", D.V.Cooldown)
      st.Data.Parried = false
      S.Buff(char, "ParryStance", D.V.ParryWindow)
      S.Sound(char, "ParryStance")
      S.FX.HQ.Glint(C.Hand(char, "Left"), Color3.fromRGB(255, 236, 150), 4, D.V.ParryWindow)
    end
  end
end
return K

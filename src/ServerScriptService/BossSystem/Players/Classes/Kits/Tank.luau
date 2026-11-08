 
local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local D = ClassConfig.Classes.Tank
local STEEL, BLUE = Color3.fromRGB(150, 160, 175), D.Color

local K = {}
function K.StopDefender(S,char,st)
 S.StopDefender(char)
 require(script:FindFirstAncestor("BossSystem").Combat.TauntService).Refresh()
end

function K.Start(S, player, char, st)
  st.Def = table.clone(st.Def)
  st.Def.BaseDefense = D.BaseDefense
  S.StatBuff(char, "Bulwark", nil, { Defense = D.PassiveMin })
end

function K.Step(S, player, char, st, dt)
  local h = char:FindFirstChildOfClass("Humanoid")
  local b = st.StatSources.Bulwark
  if h and b then
    local missing = 1 - math.clamp(h.Health / math.max(1, h.MaxHealth), 0, 1)
    b.Mods.Defense = D.PassiveMin + (D.PassiveMax - D.PassiveMin) * missing
    char:SetAttribute("TankBulwark", b.Mods.Defense)
    S.RefreshStatBuffs(char)
  end
  if S.IsDefending(char) and S.Now()>=(st.Data.DefenderLeaseUntil or 0) then K.StopDefender(S,char,st) end
  if S.IsDefending(char) then
    char:SetAttribute("TauntingUntil", S.Now() + D.F.HoldLease)
    st.Data.DefenderPulse = (st.Data.DefenderPulse or 0) + dt
    if st.Data.DefenderPulse > 0.8 then
      st.Data.DefenderPulse = 0
      local r=char.HumanoidRootPart
      local ground=require(script:FindFirstAncestor("BossSystem").Encounter.ArenaPlacement).GroundPoint(r.Position)
       or r.Position-Vector3.new(0,h.HipHeight+r.Size.Y*.5+2,0)
      S.FX.HQ.Shockwave(CFrame.new(ground+Vector3.new(0,.08,0)),3,200,1.1,BLUE,.72,.35)
    end
  end
end

function K.Action(S, player, char, st, key, phase, aim)
  local root = char.HumanoidRootPart
  local dir = C.AimDir(char, aim)
   
  local near = S.AimTarget(char,aim,18)
  if key == "M1" and player:GetAttribute("ClassAutoAim")~=false and near and (near.HumanoidRootPart.Position - root.Position).Magnitude < 18 then
    dir = C.AimDir(char, near.HumanoidRootPart.Position)
  end
  if key == "F" then
    if phase=="End" then K.StopDefender(S,char,st) return end
    if phase=="Hold" and S.IsDefending(char) then st.Data.DefenderLeaseUntil=S.Now()+D.F.HoldLease return end
    if phase == "Begin" and S.Ready(char, "F") and not S.IsDefending(char) then
      st.Data.DefenderHeld=true
      st.Data.DefenderPulse=.8
      char:SetAttribute("TankDefenderHeld",true)
      S.StatBuff(char,"Defender",nil,{Defense=D.F.Defense})
      S.Buff(char,"Taunt",nil,{Speed=D.F.SpeedMultiplier})
      st.Data.DefenderLeaseUntil=S.Now()+D.F.HoldLease
      char:SetAttribute("TauntingUntil",S.Now()+D.F.HoldLease)
      S.Cooldown(char,"F",D.F.Cooldown)
      S.Sound(char, "GuardActivate")
      S.FX.Release(root.Position + dir * 2, dir, BLUE, 0.8)
      S.FX.HQ.Shockwave(CFrame.lookAt(root.Position, root.Position + dir) * CFrame.Angles(math.rad(90), 0, 0), 1, 6, 0.35, BLUE, 0.2, 0.5)
      S.FX.HQ.Glint(C.Hand(char, "Left"), Color3.fromRGB(140, 200, 255), 4, 0.35)
    end
    return
  end
  if phase ~= "Begin" or not S.Ready(char, key) then
    return
  end
  if key == "M1" then
    S.Cooldown(char, "M1", D.M1.Cooldown)
  local attack = S.NewAttack(char,"TankSlam")
    S.Anim(char, "Bash")
    S.Sound(char, "BlockLaunch")
    local hit = false
    C.Move(S, player, char, dir, D.M1.Lunge / 0.18, 0.18, {
      ContactRadius = D.M1.Range * 0.7,
      OnContact = function(target)
        if hit then
          return
        end
        hit = true
        S.HitBoss(char, target, D.M1.Damage, "TankSlam", attack)
        S.FX.Hit(root.Position + dir * 2.5, BLUE, 1.5, false)
        S.FX.HQ.Shake(root.Position, 50, 0.2, 0.45)
        S.FX.HQ.Debris(root.Position + dir * 2.5 - Vector3.new(0, 2.5, 0), 6, Color3.fromRGB(140, 120, 95), 0.5, 26)
        S.Sound(char, "BlockImpact")
        S.FX.Ring(root.Position + dir * 2 - Vector3.new(0, 2.5, 0), STEEL, 8, 0.3)
      end,
      OnEnd = function(didHit, interrupted)
    if not didHit and not interrupted then
          local target = S.TargetNear(root.Position + dir * 3, D.M1.Range * 0.6)
          if target then
            S.HitBoss(char, target, D.M1.Damage, "TankSlam", attack)
            S.FX.Flash(root.Position + dir * 2, BLUE, 8, 0.25)
          end
        end
      end,
    })
  elseif key == "C" then
    S.Cooldown(char, "C", D.C.Cooldown)
  local attack = S.NewAttack(char,"TankRampage")
    S.Buff(char, "Rampage", D.C.MaxTime, { Defense = D.C.Defense })
    S.Sound(char, "FallingCharge")
    S.FX.HQ.Streaks(root.Position, dir, BLUE, Color3.new(1, 1, 1), 12, 10, 40, 80, 4)
     
    task.spawn(function()
      local t0 = os.clock()
      while os.clock() - t0 < D.C.MaxTime and S.HasBuff(char, "Rampage") and S.Alive(char) do
        local feet = root.Position - Vector3.new(0, 2.7, 0)
        S.FX.HQ.Debris(feet, 3, Color3.fromRGB(140, 120, 95), 0.4, 14)
        S.FX.HQ.Shockwave(CFrame.new(feet), 1, 5, 0.3, Color3.fromRGB(160, 200, 255), 0.4, 0.35)
        task.wait(0.14)
      end
    end)
    C.Move(S, player, char, dir, D.C.Speed, D.C.MaxTime, {
      ContactRadius = 6.5, StopOnContact = true,
      OnContact = function(target)
        S.Unbuff(char, "Rampage")
        if not S.HitBoss(char,target,D.C.Damage,"TankRampage",attack) then return end
        S.Stun(target,D.C.Stun,char,attack)
        S.Sound(char, "CataclysmSlam")
        S.FX.Hit(target.HumanoidRootPart.Position, BLUE, 2.2, true)
        S.FX.HQ.Shake(target.HumanoidRootPart.Position, 80, 0.35, 0.7)
        S.FX.HQ.Spikes(target.HumanoidRootPart.Position - Vector3.new(0, 3, 0), 5, 6, 12, Color3.fromRGB(255, 240, 120), Color3.new(1, 1, 1), 0.6)
        S.FX.HQ.Tint(target.HumanoidRootPart.Position, Color3.fromRGB(140, 190, 255), 0.25, 0.3, 100)
        S.FX.Flash(target.HumanoidRootPart.Position, Color3.fromRGB(255, 240, 120), 14, 0.4)
        S.FX.Ring(target.HumanoidRootPart.Position, STEEL, 16, 0.5)
        S.FX.Text(target.HumanoidRootPart.Position + Vector3.new(0, 5, 0), "STUNNED", Color3.fromRGB(255, 240, 120))
      end,
      OnEnd = function()
        S.Unbuff(char, "Rampage")
      end,
    })
  elseif key == "V" then
    S.Cooldown(char, "V", D.V.Cooldown)
    S.Anim(char, "Almighty")
    S.FX.Charge(C.Hand(char, "Left") + Vector3.new(0, 2, 0), Color3.fromRGB(140, 200, 255), 0.4, 2)
    task.delay(0.42, function()
      if S.Alive(char) then
        S.FX.Hit(root.Position + dir * 2, Color3.fromRGB(140, 200, 255), 2, true)
      end
    end)
    S.Sound(char, "RoyalFinalImpact")
    S.FX.HQ.Spikes(root.Position - Vector3.new(0, 2.5, 0), 6, 8, 14, Color3.fromRGB(120, 210, 255), Color3.new(1, 1, 1), 0.9)
    S.FX.Ring(root.Position - Vector3.new(0, 2.5, 0), Color3.fromRGB(120, 210, 255), D.V.Radius, 0.7, 0.6)
    S.FX.Flash(root.Position, Color3.fromRGB(120, 210, 255), 12, 0.5)
    for _, ally in ipairs(S.Allies(true)) do
      if (ally.HumanoidRootPart.Position - root.Position).Magnitude <= D.V.Radius then
        ally:SetAttribute("ClassShieldHP", math.max(ally:GetAttribute("ClassShieldHP") or 0, D.V.Shield))
        S.Buff(ally, "Almighty", nil)
        S.FX.Beam(root.Position, ally.HumanoidRootPart.Position, Color3.fromRGB(120, 210, 255), 0.4, 0.4)
      end
    end
  end
end
return K

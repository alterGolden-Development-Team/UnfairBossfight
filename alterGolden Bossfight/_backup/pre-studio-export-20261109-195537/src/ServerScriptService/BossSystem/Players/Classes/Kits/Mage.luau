 
local Players = game:GetService("Players")
local C = require(script.Parent.Common)
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local D=ClassConfig.Classes.Mage
local Time=require(script:FindFirstAncestor("BossSystem").Mechanics.Time.TimeEffectController)
local Effects=require(script:FindFirstAncestor("BossSystem").Combat.EffectService)
local Runtime=require(script:FindFirstAncestor("BossSystem").Combat.CombatRuntime)
local Placement=require(script:FindFirstAncestor("BossSystem").Encounter.ArenaPlacement)
local PURPLE, PALE = D.Color, Color3.fromRGB(225, 205, 255)
local rng = Random.new()

local K = {}

local function setCount(char, st)
  local n = #st.Data.Orbs
  char:SetAttribute("MageOrbs", n)
   
  char:SetAttribute("ClassStatus_Orbs", n > 0 and -1 or nil)
  char:SetAttribute("ClassStatusText_Orbs", n > 0 and ("x" .. n) or nil)
end
 
function K.CancelActions(S,char,st,reason)
 if reason=="Time" and st.Data.CloneCharge then return end
 local charge=st.Data.CloneCharge
 if charge then charge.Cast:Dispose() end
 st.Data.CHeldAt=nil
 char:SetAttribute("MageCloneCharging",nil)
 char:SetAttribute("MageCloneTargetName",nil)
end
function K.Cleanup(S, char, st)
  K.CancelActions(S,char,st,"Cleanup")
  for _, o in ipairs(st.Data.Orbs or {}) do
    if o.Part then
      o.Part:Destroy()
    end
  end
  st.Data.Orbs={}
 for _,clone in st.Data.Clones or {} do if clone.Parent then clone:Destroy() end end
 st.Data.Clones={}
  if char.Parent then
    setCount(char, st)
    char:SetAttribute("MageLasering", nil)
  end
end
function K.Start(S, player, char, st)
  st.Data.Orbs = {}
  st.Data.WardStacks=0
 st.Data.Clones={}
  setCount(char, st)
end

local function spawnOrb(S, char, st, near)
  if #st.Data.Orbs >= D.OrbMax then
    return
  end
  local a = rng:NextNumber(0, math.pi * 2)
  local r = rng:NextNumber(4, 9)
  local pos = near + Vector3.new(math.cos(a) * r, rng:NextNumber(1, 5), math.sin(a) * r)
  local orb = S.FX.Part({ Name = "MageOrb", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.1, CFrame = CFrame.new(pos), Color = PALE, Transparency = 0.05 })
  if #st.Data.Orbs<4 then
  local l=Instance.new("PointLight")
  l.Color,l.Range,l.Brightness=PURPLE,7,1.2 l.Parent=orb
 end
  table.insert(st.Data.Orbs, { Part = orb, Home = pos, Phase = rng:NextNumber(0, 6) })
  S.FX.Flash(pos, PURPLE, 2.5, 0.25)
  setCount(char, st)
end
local function nearbyOrbs(char,st)
 local count=0 local root=char.HumanoidRootPart
 for _,o in st.Data.Orbs do
  if o.Part and o.Part.Parent and (o.Part.Position-root.Position).Magnitude<=D.F.PickupRadius then count+=1 end
 end
 return count
end
local function takeOrbs(char, st, count, near, radius)
  local orbs = st.Data.Orbs
  if near then
    table.sort(orbs, function(a, b)
      return (a.Part.Position-near).Magnitude<(b.Part.Position-near).Magnitude
    end)
  end
  local taken = {}
  for _=1,math.min(count,#orbs) do
    if radius and (orbs[1].Part.Position-near).Magnitude>radius then break end
    table.insert(taken,table.remove(orbs,1))
  end
  setCount(char, st)
  return taken
end

 
function K.OnHitBoss(S, char, st, target, tag)
  if tag == "MageOrb" then
    for _ = 1, rng:NextInteger(D.OrbSpawnMin, D.OrbSpawnMax) do
      spawnOrb(S, char, st, target.HumanoidRootPart.Position)
    end
  elseif tag == "MageLaser" then
    st.Data.LaserHits = (st.Data.LaserHits or 0) + 1
    if st.Data.LaserHits % D.V.OrbEvery == 0 then
      spawnOrb(S, char, st, target.HumanoidRootPart.Position)
    end
  end
end

local beginCloneCharge
local function copySource(S,char,aim)
 local best,bestDistance=char,D.C.CloneAimRadius
 if aim then for _,ally in S.Allies(true,char) do
  local root=ally.HumanoidRootPart
  if (root.Position-char.HumanoidRootPart.Position).Magnitude<=D.C.CloneCopyRange then
   local distance=(root.Position-aim).Magnitude
   if distance<bestDistance then best,bestDistance=ally,distance end
  end
 end end
 return best
end
function K.Step(S, player, char, st, dt)
  local t=Time.EncounterNow(nil)
  if not st.StatSources.OrbWard then st.Data.WardStacks=0 char:SetAttribute("MageWardDefense",nil) end
  if st.Data.CHeldAt and not st.Data.CloneCharge and t-st.Data.CHeldAt>=D.C.HoldTime then beginCloneCharge(S,player,char,st) end
  char:SetAttribute("MageNearbyOrbs",nearbyOrbs(char,st))
  for _, o in ipairs(st.Data.Orbs) do
    if o.Part.Parent then
      o.Part.CFrame = CFrame.new(o.Home + Vector3.new(0, math.sin(t * 2 + o.Phase) * 0.5, 0))
    end
  end
end

local function shootOrb(S, char, st, from, dir, damage, source)
 local attack = S.NewAttack(char,"MageOrb",{Source=source or char})
  local visual = S.FX.Orb(PURPLE, 1)
  S.FX.Projectile(from, dir, D.M1.Speed, D.M1.Range, visual, function(pos)
    if not S.AttackValid(char,attack) then return true end
  local target = S.TargetNear(pos, D.M1.Radius)
    if target then
      attack.Origin=pos
   if S.HitBoss(char,target,damage,"MageOrb",attack) then
      S.FX.Hit(pos, PURPLE, 1.7, false)
      S.FX.Ring(pos, PALE, 11, 0.4)
      S.FX.HQ.Shake(pos, 50, 0.18, 0.35)
      S.Sound(char, "RangedImpact")
   end
      return true
    end
  end)
end

local function summonClone(S,player,char,st,orbCount,source)
 source=source or char
 local wasArchivable=source.Archivable source.Archivable=true
 local ok,clone=pcall(function()return source:Clone()end)
 source.Archivable=wasArchivable
 if not ok or not clone then return end
 local copiedPlayer=Players:GetPlayerFromCharacter(source)
 local copiedClass=source:GetAttribute("ClassId") or "Mage"
 for _,object in clone:GetDescendants() do
  if object:IsA("LuaSourceContainer") or object:IsA("Tool") or object:IsA("Animator")
   or object.Name=="ClassAvatarAccessories" or object.Name:find("ClassStatusFX_",1,true)
   or object.Name=="FateLinkBeam" or object.Name=="FateLinkFrom" or object.Name=="FateLinkTo" then object:Destroy()
  elseif object:IsA("Motor6D") then object.Transform=CFrame.identity
  elseif object:IsA("BasePart") then
   object.Transparency=math.max(object.Transparency,0.35)
   object.CanCollide=false object.CanTouch=false object.Anchored=false
   object.AssemblyLinearVelocity=Vector3.zero object.AssemblyAngularVelocity=Vector3.zero
  end
 end
 for key in clone:GetAttributes() do clone:SetAttribute(key,nil) end
 clone.Name=player.Name.."'s Orb Clone"
 clone:SetAttribute("ClassId",copiedClass)
 clone:SetAttribute("MageClone",true)
 clone:SetAttribute("MageCloneOwner",player.UserId)
 clone:SetAttribute("MageCloneCopiedUserId",copiedPlayer and copiedPlayer.UserId or player.UserId)
 local hum=clone:FindFirstChildOfClass("Humanoid")
 local root=clone:FindFirstChild("HumanoidRootPart")
 if not hum or not root then clone:Destroy() return end
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 hum.MaxHealth=math.max(1,D.C.CloneHPPerOrb*orbCount) hum.Health=hum.MaxHealth
 hum.PlatformStand=false hum.Sit=false hum.AutoRotate=false hum.EvaluateStateMachine=false
 root.Anchored=true clone.PrimaryPart=root
 local desiredSpawn=char.HumanoidRootPart.CFrame*CFrame.new(5,0,2)
 local spawnFrame=Placement.Validate(clone,desiredSpawn) or Placement.ResolveRecorded(clone,desiredSpawn,{SearchRadius=9})
 if not spawnFrame and workspace:GetAttribute("EncounterStarted")~=true then spawnFrame=desiredSpawn end
 if not spawnFrame then clone:Destroy() return end
 clone:PivotTo(spawnFrame)
 local glow=Instance.new("Highlight")
 glow.Name="MageCloneAura" glow.FillColor=PURPLE glow.OutlineColor=PALE glow.FillTransparency=0.65 glow.Parent=clone
 clone.Parent=Runtime.Summons
 table.insert(st.Data.Clones,clone)
 local life=Effects.NewCast(char,"MageOrbClone",D.C.CloneLifetime)
 local ended=false
 local function cleanup()
  if ended then return end ended=true
  if clone.Parent then S.FX.Burst(root.Position,PURPLE,20,16,0.4) clone:Destroy() end
  local index=table.find(st.Data.Clones,clone) if index then table.remove(st.Data.Clones,index) end
 end
 life.OnDispose=cleanup life.OnExpire=cleanup
 local damage=D.C.CloneShotDamage+D.C.CloneShotDamagePerOrb*orbCount
 local nextShot=life:Now()+0.4
 local movementClock=0
 local filter=Runtime.FilterFor(clone)
 life:Step(function(dt,at)
  if not clone.Parent or hum.Health<=0 or not S.Alive(char) or S.State(char)~=st then life:Dispose() return false end
  if S.TimeStopped(char) or not S.CanAct(char) then
   if clone:GetAttribute("MageCloneMoveSpeed")~=0 then clone:SetAttribute("MageCloneMoveSpeed",0) end
   return true
  end
  movementClock+=dt if movementClock<1/30 then return true end
  local step=math.min(movementClock,0.1) movementClock=0
  local target=S.AimTarget(clone,nil,D.M1.Range)
  if not target then clone:SetAttribute("MageCloneMoveSpeed",0) return true end
  local destination=target.HumanoidRootPart.Position
  local delta=Vector3.new(destination.X-root.Position.X,0,destination.Z-root.Position.Z)
  local nextPosition=root.Position
  if delta.Magnitude>22 then
   local travel=delta.Unit*math.min(D.C.CloneSpeed*step,delta.Magnitude-22)
   local wall=workspace:Blockcast(root.CFrame,Vector3.new(2.6,4.5,2.6),travel,filter())
   if wall then travel=travel.Unit*math.max(0,wall.Distance-0.1) end
   local desired=Placement.Validate(clone,CFrame.new(root.Position+travel)*root.CFrame.Rotation)
   if desired then nextPosition=desired.Position end
  end
  local speed=math.round((nextPosition-root.Position).Magnitude/math.max(step,0.001))
  if clone:GetAttribute("MageCloneMoveSpeed")~=speed then clone:SetAttribute("MageCloneMoveSpeed",speed) end
  local focus=Vector3.new(destination.X,nextPosition.Y,destination.Z)
  clone:PivotTo((focus-nextPosition).Magnitude>0.01 and CFrame.lookAt(nextPosition,focus) or CFrame.new(nextPosition)*root.CFrame.Rotation)
  if at>=nextShot and (destination-root.Position).Magnitude<=D.M1.Range then
   nextShot=at+D.C.CloneFireInterval
   local animation=({Warrior="XSlash",Tank="Bash",Supporter="Sweep",Gambler="Shoot",Duelist="RiposteStrike"})[copiedClass] or "Cast"
   S.Anim(clone,animation)
   local from=root.Position+Vector3.new(0,1,0)
   shootOrb(S,char,st,from,(destination-from).Unit,damage,clone)
  end
  return true
 end)
end

beginCloneCharge=function(S,player,char,st)
 if st.Data.CloneCharge or not S.CanAct(char) or #st.Data.Orbs==0 then return end
 local source=copySource(S,char,st.Aim)
 local reserved=takeOrbs(char,st,#st.Data.Orbs)
 local cast=Effects.NewCast(char,"MageWandCloneCharge",D.C.ClonePullDuration+1)
 local charge={Cast=cast,Orbs=reserved,Source=source,Starts={},Completed=false}
 st.Data.CloneCharge=charge st.Data.CHeldAt=nil
 S.Cooldown(char,"C",D.C.Cooldown)
 char:SetAttribute("MageCloneCharging",true)
 local selected=Players:GetPlayerFromCharacter(source)
 char:SetAttribute("MageCloneTargetName",selected and selected.DisplayName or player.DisplayName)
 for i,orb in reserved do charge.Starts[i]=orb.Part.Position end
 local began=cast:Now()
 local function finish()
  if st.Data.CloneCharge==charge then st.Data.CloneCharge=nil end
  char:SetAttribute("MageCloneCharging",nil) char:SetAttribute("MageCloneTargetName",nil)
  for i,orb in reserved do
   if orb.Part and orb.Part.Parent then
    if not charge.Completed and S.Alive(char) and S.State(char)==st then
     orb.Home=charge.Starts[i] orb.Part.CFrame=CFrame.new(orb.Home) orb.Part.Size=Vector3.one*1.1
     table.insert(st.Data.Orbs,orb)
    else orb.Part:Destroy() end
   end
  end
  if S.State(char)==st then setCount(char,st) end
 end
 cast.OnDispose=finish
 cast:Step(function(_,at)
  if not S.Alive(char) or S.State(char)~=st then cast:Dispose() return false end
  if not S.CanAct(char) then return true end
  local progress=math.clamp((at-began)/D.C.ClonePullDuration,0,1)
  local tip=C.Hand(char)
  for i,orb in reserved do if orb.Part.Parent then
   local position=charge.Starts[i]:Lerp(tip,1-(1-progress)^3)
   local swirl=Vector3.new(math.cos(progress*math.pi*4+i),math.sin(progress*math.pi*4+i),0)*(1-progress)*1.5
   orb.Part.CFrame=CFrame.new(position+swirl)
   orb.Part.Size=Vector3.one*math.max(0.08,1.1*(1-progress))
  end end
  if progress>=1 then
   charge.Completed=true
   local copied=source.Parent and source or char
   S.Anim(char,"Summon") S.Sound(char,"CloneMaterialize")
   S.FX.Flash(tip,PURPLE,7,0.4)
   summonClone(S,player,char,st,#reserved,copied)
   cast:Dispose()
   return false
  end
  return true
 end)
end

function K.Action(S, player, char, st, key, phase, aim)
  local root = char.HumanoidRootPart
  if st.Data.CloneCharge and key~="C" and key~="Aim" then return end
  if key == "Aim" then
    return
  end
  if key == "M1" and phase == "Begin" and S.Ready(char, "M1") and not st.Data.Lasering then
    S.Cooldown(char, "M1", D.M1.Cooldown)
    S.Anim(char, "Cast")
    S.Sound(char, "RangedLaunch")
    local from = C.Hand(char)
    local shotDir = C.AimDir3D(from, aim, root.CFrame.LookVector)
     
    S.FX.HQ.Ring(CFrame.lookAt(from, from + shotDir), 0.4, 2.6, 0.3, PURPLE, 0.15, 0.25, 2)
    S.FX.Release(from, shotDir, PURPLE, 0.6)
    S.FX.HQ.Glint(from, PALE, 3, 0.2)
    shootOrb(S, char, st, from, shotDir, D.M1.Damage)
  elseif key == "F" and phase == "Begin" then
    if not S.CanAct(char) or os.clock()<(st.Data.NextOrbDashAt or 0) then return end
    local available=nearbyOrbs(char,st)
    if available<D.F.OrbCost then
      S.FX.Text(root.Position + Vector3.new(0, 3, 0), "NEED " .. D.F.OrbCost .. " ORBS", PALE)
      return
    end
    if S.Ready(char,"F") then S.Cooldown(char,"F",D.F.Cooldown) end
    st.Data.NextOrbDashAt=os.clock()+D.F.MinDashInterval
    char:SetAttribute("MageOrbDashReadyAt",S.Now()+D.F.MinDashInterval)
    for _,o in takeOrbs(char,st,D.F.OrbCost,root.Position,D.F.PickupRadius) do
      S.FX.Beam(o.Home, root.Position, PURPLE, 0.4, 0.3)
      o.Part:Destroy()
    end
    S.Anim(char, "OrbDash")
    S.FX.Release(root.Position, C.AimDir(char, aim), PURPLE, 0.9)
    S.FX.HQ.Glint(root.Position, PURPLE, 4, 0.3)
    S.FX.HQ.Streaks(root.Position, C.AimDir(char, aim), PURPLE, PALE, 10, 15, 50, 90, 3)
    S.FX.Ring(root.Position - Vector3.new(0, 2.6, 0), PURPLE, 9, 0.35)
    S.Sound(char, "TeleportWarp")
    st.Data.WardStacks = (st.Data.WardStacks or 0) + 1
    local wardDefense=math.min(D.F.DefenseCap,D.F.DefensePerStack*st.Data.WardStacks)
    S.StatBuff(char,"OrbWard",D.F.StackDuration,{Defense=wardDefense})
    char:SetAttribute("MageWardDefense",wardDefense)
    char:SetAttribute("MageWardStacks",st.Data.WardStacks)
    char:SetAttribute("MageNearbyOrbs",nearbyOrbs(char,st))
    local from = root.Position
    C.Move(S, player, char, C.AimDir(char, aim), D.F.Distance / 0.3, 0.3, { OnEnd = function()
      S.FX.Beam(from, root.Position, PURPLE, 1, 0.4)
    end })
  elseif key=="C" then
    if phase=="Begin" then
     if not S.Ready(char,"C") or st.Data.CHeldAt or st.Data.CloneCharge then return end
     if #st.Data.Orbs==0 then S.FX.Text(root.Position+Vector3.new(0,3,0),"NO ORBS",PALE) return end
     st.Data.CHeldAt=Time.EncounterNow(nil)
    elseif phase=="End" then
     if st.Data.CloneCharge then st.Data.CHeldAt=nil return end
     local pressedAt=st.Data.CHeldAt
     if not pressedAt then return end
     local held=Time.EncounterNow(nil)-pressedAt
     if held>=D.C.HoldTime then beginCloneCharge(S,player,char,st) return end
     st.Data.CHeldAt=nil
     if #st.Data.Orbs==0 then return end
     S.Cooldown(char,"C",D.C.Cooldown)
     local orbs=takeOrbs(char,st,#st.Data.Orbs)
         
    local attack=S.NewAttack(char,"MageBombard")
    local spent=0
    local bombard=Effects.NewCast(char,"MageBombardment",#orbs*0.03+1)
        S.Anim(char, "Bombard")
         
        for i = 2, math.min(#orbs, 14) do
          S.FX.HQ.Bolt(orbs[i - 1].Home, orbs[i].Home, PURPLE, PALE, 0.25, 0.6, 6, 0.3, true)
        end
        S.Sound(char, "HandExplosion")
        for i, o in ipairs(orbs) do
          bombard:Add(o.Part)
          bombard:Schedule(i*0.03,function()
            if not S.AttackExists(char,attack) then return end
            S.FX.Hit(o.Home, PURPLE, 1.3, false)
            S.FX.HQ.Shake(o.Home, 40, 0.12, 0.25)
            local target = S.TargetNear(o.Home, D.C.OrbRadius)
            if target then
       attack.Origin=o.Home
       local amount=math.min(D.C.OrbDamage,D.C.TotalDamageCap-spent)
       if amount>0 and S.HitBoss(char,target,amount,"MageBombard",attack) then spent+=amount end
      end
            o.Part:Destroy()
          end)
        end
    end
  elseif key == "V" and phase == "Begin" and S.Ready(char, "V") then
    S.Cooldown(char, "V", D.V.Cooldown)
  local attack = S.NewAttack(char,"MageLaser")
    st.Data.Lasering = true
    S.Buff(char, "LaserCharge", D.V.Charge, { Speed = 0.4 })
    S.Sound(char, "ThrustCharge")
    S.FX.HQ.Glint(C.Hand(char), PALE, 4, D.V.Charge)
    S.FX.Charge(C.Hand(char), PURPLE, D.V.Charge, 2.6)
    local chargeBall = S.FX.Part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.5, Color = PALE, CFrame = CFrame.new(C.Hand(char)) })
    local t0 = os.clock()
    task.spawn(function()
      while os.clock() - t0 < D.V.Charge and S.AttackValid(char,attack) do
        local k = (os.clock() - t0) / D.V.Charge
        chargeBall.CFrame = CFrame.new(C.Hand(char))
        chargeBall.Size = Vector3.one * (0.5 + 3 * k)
        if math.random() < 0.3 then
          S.FX.Beam(chargeBall.Position + Vector3.new(math.random(-6, 6), math.random(-3, 6), math.random(-6, 6)), chargeBall.Position, PURPLE, 0.15, 0.2)
        end
        task.wait(0.05)
      end
      chargeBall:Destroy()
   if not S.AttackValid(char,attack) then
    st.Data.Lasering=false
    char:SetAttribute("MageLasering",nil)
    S.Remote():FireClient(player,"LaserEnd")
    return
   end
      S.Remote():FireClient(player, "LaserStart", { Duration = D.V.Ticks * D.V.TickInterval })
      char:SetAttribute("MageLasering", true)
      S.Sound(char, "CrescentFlame")
      local releaseDir=C.AimDir3D(C.Hand(char),st.Aim,root.CFrame.LookVector)
   S.FX.Release(C.Hand(char), releaseDir, PURPLE, 1.6)
      local beam = S.FX.Part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2.4, 2.4), Color = PURPLE, Transparency = 0.15 })
      local core = S.FX.Part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 0.9, 0.9), Color = Color3.new(1, 1, 1), Transparency = 0 })
      for tick = 1, D.V.Ticks do
        if not S.AttackValid(char,attack) then
     break
    end
        local from = C.Hand(char)
        local dir = C.AimDir3D(from, st.Aim, char.HumanoidRootPart.CFrame.LookVector)
        local to = from + dir * D.V.Range
        local len = D.V.Range
        local mid = from + dir * len / 2
        local frame = CFrame.lookAt(mid, to) * CFrame.Angles(0, math.rad(90), 0)
        local pulse = 1 + math.sin(tick) * 0.12
        beam.Size = Vector3.new(len, 3.2 * pulse, 3.2 * pulse)
        if tick % 3 == 0 then
          S.FX.HQ.Glint(from, PALE, 3.5, 0.15)
        end
        beam.CFrame = frame
        core.Size = Vector3.new(len, 0.9, 0.9)
        core.CFrame = frame
        for _, target in ipairs(S.Targets()) do
          if C.SegmentDistance(target.HumanoidRootPart.Position, from, to) <= 4.5 then
            if S.HitBoss(char, target, D.V.TickDamage, "MageLaser", attack) then
            if tick % 2 == 0 then
              S.FX.HQ.Sparks(target.HumanoidRootPart.Position, PURPLE, PALE, 6, 10, 26, 0.3)
            end
            if tick % 4 == 0 then
              S.FX.Burst(target.HumanoidRootPart.Position, PALE, 6, 16, 0.3)
            end
            end
          end
        end
        task.wait(D.V.TickInterval)
      end
      S.FX.Fade(beam, 0.25)
      S.FX.Fade(core, 0.25)
      game:GetService("Debris"):AddItem(beam, 0.3)
      game:GetService("Debris"):AddItem(core, 0.3)
      st.Data.Lasering = false
      char:SetAttribute("MageLasering", nil)
      S.Remote():FireClient(player, "LaserEnd")
    end)
  end
end
return K

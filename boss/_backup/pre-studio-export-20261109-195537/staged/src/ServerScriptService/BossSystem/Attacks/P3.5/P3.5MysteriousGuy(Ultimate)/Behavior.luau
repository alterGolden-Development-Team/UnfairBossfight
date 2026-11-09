local B=script:FindFirstAncestor("BossSystem")
local Registry=require(B.Combat.AttackRegistry)
local Effects=require(B.Combat.EffectService)
local Encounter=require(B.Players.PlayerEncounter)
local Placement=require(B.Encounter.ArenaPlacement)
local Runtime=require(B.Combat.CombatRuntime)
local Status=require(B.Combat.StatusEffectService)
local Taunt=require(B.Combat.TauntService)
local Classes=require(B.Players.Classes.ClassService)
local Ultimate=require(B.Combat.UltimateService)
local V=require(script.Parent.Visuals)
local S=require(script.Parent.Style)
local G=require(script.Parent.Geometry)
local Net=require(game.ReplicatedStorage.VFXEngine.Net)
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local safe,cinema,lerp=V.Safe,V.Cinema,G.Lerp
local V3=Vector3.new
local QUAD,OUT=Enum.EasingStyle.Quad,Enum.EasingDirection.Out
local flatSwept=G.FlatSwept
local function emergeFactor(elapsed)return G.EmergeFactor(elapsed,S)end

return function(actor)
 local core=Registry.For(actor,"P1CombatCore")
 local current
 local api={Cooldown=S.Cooldown,IsUltimate=true,UltimatePhase=3.5}

 local function playerTarget(char)
  local p=char and Players:GetPlayerFromCharacter(char)
  local r=char and char:FindFirstChild("HumanoidRootPart")
  return p and p.Character==char and core.Alive(char) and r and Placement.Contains(r.Position,S.Margin)
   and not Encounter.IsDefeated(p) and not p:GetAttribute("ViewAsServer")
 end
 function api.CanUse(target)
  return not current and actor:GetAttribute("Phase")==3.5 and core.Active() and playerTarget(target)
   and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("IsIllusion")
   and not actor:GetAttribute("PhaseTransitionInProgress") and Ultimate.Ready(actor,S.Name)
   and not actor:GetAttribute("IllusionBombActive")  -- never stacked on a bomb volley
 end
 function api.Combo(target)
  if not api.CanUse(target)then return false end
  return core.Perform(target,S.Name,function()
   local generation=actor:GetAttribute("PhaseGeneration") or 0
   local revision=actor:GetAttribute("MovementRevision") or 0
   local charge=S.Charge
   local cast=Effects.NewCast(actor,S.Name,S.SummonTime+S.ChaseDuration+S.DissolveTime+charge+S.Recovery+3)
   cast.PersistsThroughEmitterStun=true  -- the shadow hunts on its own; a stun on the boss doesn't end it
   current=cast
   local root=core.Root
   local born=cast:Now()
   local control={name=S.Name}
   local captured,heldFrame,chargeFrame,chargeAt,capturePoint
   local restoreSword
   local hit=false
   local finished=false
   local ghost
   local reposed=false
   local chargePose={RightShoulder={75,-35,-60},LeftShoulder={25,0,35},Waist={0,35,0}}

   local visuals
   local victimPlayer
   local hunting,endAt=false,nil
   local slowUntil,whiffReadyAt=0,0
   local nextBlinkAt=born+S.SummonTime+S.BlinkInterval
   local blast,erupted
   local coiled,relaxed=false,false
    -- the boss fights on while the shadow hunts, so this checks the encounter only; once he
    -- steps in for the punch, anything else moving him (a new MovementRevision) ends it
   local function valid()
    local h=actor:FindFirstChildOfClass("Humanoid")
    return cast:Alive() and actor.Parent~=nil and h~=nil and h.Health>0 and actor:GetAttribute("AIEnabled")~=false
     and actor:GetAttribute("Phase")==3.5
     and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
     and (actor:GetAttribute("PhaseGeneration") or 0)==generation
     and (not chargeAt or (actor:GetAttribute("MovementRevision") or 0)==revision)
   end
   local function release()
    if captured then Status.ReleaseRestraint(captured,control)end
    captured=nil heldFrame=nil
   end
   cast.OnDispose=function()
    release()
    if visuals then safe(visuals.Clear)end
    if victimPlayer then safe(cinema,victimPlayer,"Release")victimPlayer=nil end
    if restoreSword then restoreSword()end
    if current==cast then current=nil end
    if actor.Parent then
     actor:SetAttribute("MysteriousGuyActive",false)
     if actor:GetAttribute("MysteriousGuyPunching") then
      actor:SetAttribute("MysteriousGuyPunching",false)
      if (actor:GetAttribute("MovementRevision") or 0)==revision and not actor:GetAttribute("PhaseTransitionInProgress") then
       core.Melee.Pose("Idle",.2)
       actor:SetAttribute("AttackState","Idle")
       actor:SetAttribute("NextAttackAt",math.max(actor:GetAttribute("NextAttackAt") or 0,workspace:GetServerTimeNow()+.4))
      end
     end
    end
   end

   local function onWhiff(char,now)
    if now<whiffReadyAt then return end
    whiffReadyAt=now+S.WhiffCooldown slowUntil=now+S.WhiffSlowTime
    safe(visuals.Whiff,char,slowUntil)
   end
   local function slowFactor(now)
    if now>=slowUntil then return 1 end
    local a=1-(slowUntil-now)/S.WhiffSlowTime
    return lerp(S.WhiffSlow,1,a*a)
   end

   local function beginDissolve(now)
    endAt=now actor:SetAttribute("AttackState","Mysterious Guy: the shadow erupts")
     -- it caught no one: it collapses into a void and erupts in swords where it stands
    if not erupted and ghost then
     erupted=true
     local point=ghost.Root.Position
     local ground=Placement.GroundPoint(point,{Clamp=true})or point-Vector3.yAxis*3
     Net.Send("ShadowSwords","Erupt",{Pos=ground,Radius=S.EruptRadius,Giant=false,Seed=math.random(1,1e6)})
     safe(visuals.Erupt,point)
     for _,char in ipairs(core.Characters())do
      if playerTarget(char)then
       local p=char.HumanoidRootPart.Position
       if((p-point)*Vector3.new(1,0,1)).Magnitude<=S.EruptRadius and math.abs(p.Y-point.Y)<=9 and core.CanHit(char,point)then
        Encounter.Damage(char,S.EruptDamage,actor,nil,{Skill=S.Name})
        pcall(Status.ApplySlow,char,S.EruptSlow,S.EruptSlowSeconds,"P35MysteriousGuyErupt")
       end
      end
     end
    end
    safe(visuals.Dissolve)
   end

    
    
    
   local function chooseTarget()
    local taunted=ghost and Taunt.Target(ghost.Model)
    if playerTarget(taunted)then return taunted end
    if playerTarget(target)then return target end
    local best,distance
    for _,char in ipairs(core.Characters())do
     if playerTarget(char)then
      local d=(char.HumanoidRootPart.Position-ghost.Root.Position).Magnitude
      if not distance or d<distance then best,distance=char,d end
     end
    end
    return best
   end
   local function capture(char,now)
    if not playerTarget(char)or not Encounter.CanReceiveHit(char)or Status.IsUninterrupted(char)then return false end
     -- never cut into another ultimate or a phase change that is waiting to start
    if actor:GetAttribute("PhaseTransitionQueued")
     or actor:GetAttribute("AttackInProgress") and tostring(actor:GetAttribute("CurrentSkill") or ""):find("(Ultimate)",1,true)then return false end
    local r=char.HumanoidRootPart
    local frame=Placement.Validate(actor,ghost.Root.CFrame,{Margin=S.Margin})
     or Placement.ResolveRecorded(actor,ghost.Root.CFrame,{Margin=S.Margin,SearchRadius=9})
    if not frame then return false end
    local toward=Vector3.new(r.Position.X-frame.X,0,r.Position.Z-frame.Z)
    if toward.Magnitude>.01 then frame=CFrame.lookAt(frame.Position,frame.Position+toward)end
    if not Status.Restrain(char,control,charge+S.Recovery+.8,{Effect="Stunned",AllowDefense=false})then return false end
    captured,heldFrame=char,r.CFrame
    capturePoint=r.Position
    victimPlayer=Players:GetPlayerFromCharacter(char)
    Classes.CancelActions(char)
     -- the boss drops whatever he is doing and steps out of the shadow: a new MovementRevision
     -- ends his current attack, and the controller waits on MysteriousGuyPunching
    revision=(actor:GetAttribute("MovementRevision") or 0)+1
    actor:SetAttribute("MovementRevision",revision)
    Effects.CancelEmitter(actor,"Mysterious Guy seize",function(c)
     return c~=cast and not c.PersistsThroughEmitterStun and c.name~="ShieldGateMovement"
    end)
    actor:SetAttribute("MysteriousGuyPunching",true)
    actor:SetAttribute("CurrentSkill",S.Name)
    local previous=root.CFrame
    core.Afterimage(previous)
    safe(visuals.StopChase)
    root.CFrame=frame root.AssemblyLinearVelocity=Vector3.zero
    chargeFrame=frame chargeAt=now
    ghost.Update(previous,now,.35)
    safe(visuals.ClearTrail)
    restoreSword=V.HideSword(actor)
    actor:SetAttribute("AttackState","Mysterious Guy: the illusion was Golden")
     
    core.PoseAngles(chargePose,charge*.78)
    safe(visuals.Seize,char,previous,frame)
    safe(visuals.Charge)
    return true
   end

   local function run()
    local point=Placement.GroundPoint((root.CFrame*CFrame.new(0,0,-S.SpawnOffset)).Position,{Clamp=true,Margin=S.Margin})
    if not point then return false end
    ghost=V.Monster(cast,core.Effects,CFrame.new(point+Vector3.yAxis*3)*root.CFrame.Rotation)
    visuals=V.Create(actor,core,ghost,charge,function()return victimPlayer end)
    actor:SetAttribute("MysteriousGuyActive",true)
    actor:SetAttribute("AttackState","Mysterious Guy: something is watching")
    core.PoseAngles({RightShoulder={115,0,-45},LeftShoulder={115,0,45},Waist={-8,0,0}},S.SummonTime)
    safe(visuals.Summon,point)
    safe(visuals.BuildChase,point)
    local carry=0
    cast:Step(function(dt,now)
     if not valid()then cast:Dispose()return false end
     carry+=dt if carry<1/30 then return true end
     local step=carry carry=0
     local elapsed=now-born
     if blast and not V.UpdateBlast(blast,now)then blast=nil end
     if chargeAt then
      local held=now-chargeAt
      if not hit and captured and not playerTarget(captured)then
       release()
       if victimPlayer then safe(cinema,victimPlayer,"Release")victimPlayer=nil end
      end
      if not hit then
       root.CFrame=chargeFrame root.AssemblyLinearVelocity=Vector3.zero
        -- the attack he dropped resets him to idle as it unwinds: take the pose back once
       if not reposed and held>=.12 then
        reposed=true
        core.PoseAngles(chargePose,math.max(charge*.78-held,.05))
        actor:SetAttribute("AttackState","Mysterious Guy: the illusion was Golden")
       end
       if captured and Status.ExclusivelyRestrainedBy(captured,control)then
        local rise=TweenService:GetValue(math.clamp(held/charge,0,1),QUAD,OUT)
        captured.HumanoidRootPart.CFrame=heldFrame+V3(0,S.LiftHeight*rise,0)
        captured.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
       end
       ghost.Update(ghost.Root.CFrame,now,math.clamp(held/charge,0,1))
       if not coiled and held>=charge*.78 then
        coiled=true
        core.PoseAngles({RightShoulder={85,-45,-70},LeftShoulder={20,0,40},Waist={0,42,0}},charge*.22)
       end
       if held>=charge then
        hit=true
        local victim=captured
        local impact=capturePoint+V3(0,S.LiftHeight,0)
        release()
        core.PoseAngles({RightShoulder={100,0,15},LeftShoulder={30,0,-30},Waist={0,-30,0}},.1)
        local actual=0
        if victim and playerTarget(victim)and core.CanHit(victim,chargeFrame.Position)then
         actual=Encounter.Damage(victim,S.PunchDamage,actor,nil,{Skill=S.Name,BreaksBlock=true}) or 0
          -- then the giant sword tears up under them
         actual+=Encounter.Damage(victim,S.SwordDamage,actor,nil,{Skill=S.Name}) or 0
        end
        if actual>0 then
         Runtime.Knockback(actor,victim,victim.HumanoidRootPart.Position-root.Position,
          {Speed=S.LaunchSpeed,Lift=S.LaunchLift,Duration=.35,Sustain=.1,AllowPlayerControl=true,ContainsArena=true,UnscaledDifficulty=true})
        end
        if actual>0 then pcall(Status.ApplyFear,victim,S.FearSeconds,actor)end
         -- the punch erupts in swords: everyone else close by is hit and thrown
        local ground=Placement.GroundPoint(impact,{Clamp=true})or impact-Vector3.yAxis*3
        Net.Send("ShadowSwords","Erupt",{Pos=ground,Radius=S.ShockRadius,Giant=true,Seed=math.random(1,1e6)})
        for _,char in ipairs(core.Characters())do
         if char~=victim and playerTarget(char)then
          local p=char.HumanoidRootPart.Position
          if((p-impact)*Vector3.new(1,0,1)).Magnitude<=S.ShockRadius and math.abs(p.Y-impact.Y)<=9 and core.CanHit(char,impact)then
           if(Encounter.Damage(char,S.ShockDamage,actor,nil,{Skill=S.Name})or 0)>0 then
            Runtime.Knockback(actor,char,p-impact,{Speed=34,Lift=10,Duration=.25,Sustain=.06,AllowPlayerControl=true,ContainsArena=true})
           end
          end
         end
        end
        core.ScreenEffect("Shake",{Origin=impact,Radius=140,Duration=.35,Intensity=1.1})
        safe(visuals.Punch,impact,actual>0)
        if victimPlayer then safe(cinema,victimPlayer,"Punch")end
       end
      end
      if hit and not relaxed and held>=charge+.3 then  
       relaxed=true
       core.PoseAngles({RightShoulder={40,0,8},LeftShoulder={15,0,-12},Waist={0,-10,0}},.3)
      end
      if held>=charge+math.max(S.Recovery,.8)then finished=true cast:Dispose()return false end
     elseif endAt then  
      local a=math.clamp((now-endAt)/S.DissolveTime,0,1)
      ghost.Update(ghost.Root.CFrame,now,a)
      if a>=1 then finished=true cast:Dispose()return false end
     elseif elapsed>=S.SummonTime then
      target=chooseTarget()
      if not target then
       ghost.Update(ghost.Root.CFrame,now)
       if elapsed>=S.SummonTime+S.ChaseDuration then beginDissolve(now)end
       return true
      end
      if not hunting then hunting=true safe(visuals.Hunt)end
      actor:SetAttribute("AttackState","Mysterious Guy: the shadow is chasing")
      local previous=ghost.Root.Position
      local r=target.HumanoidRootPart
      local flat=(r.Position-previous)*Vector3.new(1,0,1)
      local dist=flat.Magnitude
      local dir=dist>.01 and flat.Unit or Vector3.zero
       -- blink: every BlinkInterval the shadow tears most of the way to its prey
      if now>=nextBlinkAt and dist>S.BlinkMin and dist<S.BlinkMax then
       nextBlinkAt=now+S.BlinkInterval
       local jump=math.min(dist*S.BlinkShare,dist-S.CatchRadius-2)
       local landing=jump>4 and Placement.GroundPoint(previous+dir*jump,{Clamp=true,Margin=S.Margin})
       if landing then
        local to=landing+Vector3.yAxis*3
        safe(visuals.Blink,previous,to)
        ghost.Update(CFrame.lookAt(to,to+dir),now)
        previous=to
        flat=(r.Position-previous)*Vector3.new(1,0,1)
        dist=flat.Magnitude
        dir=dist>.01 and flat.Unit or Vector3.zero
       end
      end
      if dist>.01 and S.Weave>0 then  
       local sway=S.Weave*math.sin(elapsed*2.6)*math.clamp((dist-S.CatchRadius*2)/16,0,1)
       dir=CFrame.Angles(0,sway,0):VectorToWorldSpace(dir)
      end
      local speed=S.ChaseSpeed*emergeFactor(elapsed)*slowFactor(now)
      local movement=dir*math.min(dist,speed*step)
      local ground=Placement.GroundPoint(previous+movement,{Clamp=true,Margin=S.Margin})
      if not ground then finished=true cast:Dispose()return false end
      local nextPosition=ground+Vector3.yAxis*3
      local facing=dir.Magnitude>.01 and CFrame.lookAt(nextPosition,nextPosition+dir)or CFrame.new(nextPosition)
      ghost.Update(facing,now)
      safe(visuals.Chase,ground,r,dist,now)
      local dy=math.abs(r.Position.Y-nextPosition.Y)
      if dy<=S.CatchHeight
       and V.SweptDistance(r.Position,previous,nextPosition)<=S.CatchRadius
       and core.CanHit(target,nextPosition)then
       if Status.IsUninterrupted(target)or not Encounter.CanReceiveHit(target)then onWhiff(target,now)
       else capture(target,now)end
      elseif dy>S.CatchHeight and flatSwept(r.Position,previous,nextPosition)<=S.WhiffRadius then
       onWhiff(target,now)  
      end
      if not chargeAt and elapsed>=S.SummonTime+S.ChaseDuration then beginDissolve(now)end
     else ghost.Update(ghost.Root.CFrame,now,1-math.clamp(elapsed/S.SummonTime,0,1))end
     return true
    end)
     -- the boss only holds the summon; the shadow hunts on its own while he keeps fighting
    while cast:Alive()and valid()and cast:Now()-born<S.SummonTime do Run.Heartbeat:Wait()end
    return cast:Alive()
   end
   local ok,result=xpcall(run,debug.traceback)
   if not ok or not result then cast:Dispose()end
   if not ok then error(result,0)end
   return result
  end)
 end
 function api.Dispose()if current then current:Dispose()end end
 return api
end

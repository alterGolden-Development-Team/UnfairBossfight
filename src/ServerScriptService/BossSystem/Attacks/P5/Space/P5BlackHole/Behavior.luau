 
local B=script:FindFirstAncestor("BossSystem")
local S=require(script.Parent.Style)
local G=require(script.Parent.Geometry)
local V=require(script.Parent.Visuals)
local Pull=require(script.Parent.Pull)
local Registry=require(B.Combat.AttackRegistry)
local Effects=require(B.Combat.EffectService)
local Encounter=require(B.Players.PlayerEncounter)
local Placement=require(B.Encounter.ArenaPlacement)
local Cooldowns=require(B.Combat.AbilityCooldownService)
local Status=require(B.Combat.StatusEffectService)
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
require(script.Parent.Presentation).Publish()

local PULLED="BlackHolePulled"  
-- the hole hangs overhead, so the kill zone is a flat disc in its ground shadow
local FOOTPRINT=S.KillRadius or G.Footprint(S.CoreRadius,S.HoverHeight,S.TargetHeight)
local FLAT=Vector3.new(1,0,1)

return function(actor)
 local core=Registry.For(actor,"P1CombatCore")
 local current
 local api={Cooldown=S.Cooldown,ManagesCooldown=true}

 local function targetValid(char)
  local p=char and Players:GetPlayerFromCharacter(char)
  return p and p.Character==char and core.Alive(char) and not Encounter.IsDefeated(p)
   and not p:GetAttribute("ViewAsServer") and not p:GetAttribute("ExecutionPending")
 end

 function api.CanUse(target)
  return not current and actor:GetAttribute("Phase")==5 and core.Active() and targetValid(target)
   and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("IsIllusion")
   and not actor:GetAttribute("PhaseTransitionInProgress") and Placement.GetBounds()~=nil
   and Cooldowns.Ready(actor,S.Name)
 end

 function api.Combo(target)
  local S=require(B.Attacks.Shared.P5AstralCore).Tune(actor,S,{Speed={"MoveSpeed","PullMinSpeed","PullMaxSpeed","PullSpeedLimit","ShockSpeed"},Tell={"HoldTime","ArmDelay"}})
  if not api.CanUse(target) then return false end
  return core.Perform(target,S.Name,function()
   Cooldowns.Start(actor,S.Name,S.Cooldown)
   local generation=actor:GetAttribute("PhaseGeneration") or 0
   local cast=Effects.NewCast(actor,S.Name,S.SummonTime+S.ActiveDuration+S.FadeTime+2)
   cast.TimeStopExempt=true cast.PersistsThroughEmitterStun=true current=cast
   local born=cast:Now()
   local ground=Placement.GroundPoint((core.Root.CFrame*CFrame.new(0,0,-S.SpawnOffset)).Position,{Clamp=true,Margin=S.Margin})
   if not ground then cast:Dispose() current=nil return false end
   local groundY=ground.Y
   local center=ground+Vector3.yAxis*S.HoverHeight
   local initial=center
   local direction=G.Direction(center,target.HumanoidRootPart.Position)
   local hands=core.Root.Position+Vector3.yAxis*S.HandHeight  -- the hole forms above the boss's raised hands
   local forces,previousPlayers,executed={},{},{}
   local visual
   local warned=false
   local collapseStart=nil
   local burstFired=false

   local function cosmetic(fn,...)
    local ok,result=pcall(fn,...)
    if not ok and not warned then warned=true warn("P5BlackHole visuals: "..tostring(result))end
    return ok and result or nil
   end
   local function release(char)
    local record=forces[char]
    if record then Pull.Release(record) forces[char]=nil end
    char:SetAttribute(PULLED,nil)
   end
   local function valid()
    return cast:Alive() and actor.Parent and core.Humanoid.Health>0 and actor:GetAttribute("AIEnabled")~=false
     and actor:GetAttribute("Phase")==5 and not actor:GetAttribute("EncounterEnded")
     and not actor:GetAttribute("PhaseTransitionInProgress")
     and (actor:GetAttribute("PhaseGeneration") or 0)==generation
   end
   cast.OnDispose=function()
    for char in pairs(forces)do release(char)end
    if visual then cosmetic(visual.Destroy)end
    if current==cast then current=nil end
    if actor.Parent then
     local breather=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig).HeavyBreather or 1.2
     actor:SetAttribute("NextAttackAt",math.max(actor:GetAttribute("NextAttackAt")or 0,workspace:GetServerTimeNow()+breather))
     if actor:GetAttribute("Phase")==5 then actor:SetAttribute("FillerDebt",require(game.ReplicatedStorage.BossShared.Config.EncounterConfig).Phase5FillerBetween or 2)end
    end
    if actor.Parent then actor:SetAttribute("BlackHoleActive",false) actor:SetAttribute("BlackHoleStage","") actor:SetAttribute("BlackHolePullTargets",0)end
   end
   local function chooseTarget()
    if targetValid(target)then return target end
    local best,distance
    for _,char in ipairs(core.Characters())do
     if targetValid(char)then local d=(char.HumanoidRootPart.Position-center).Magnitude if not distance or d<distance then best,distance=char,d end end
    end
    return best or core.RetainTarget(target)
   end
    
   local function beginCollapse(now)
    if collapseStart then return end
    collapseStart=now
    for char in pairs(forces)do release(char)end
    actor:SetAttribute("BlackHoleStage","Collapse")
    actor:SetAttribute("BlackHolePullTargets",0)
    if visual then cosmetic(visual.Stage,"Collapse")end
   end

   local function run()
    actor:SetAttribute("BlackHoleActive",true) actor:SetAttribute("BlackHoleKills",0)
    actor:SetAttribute("BlackHoleStage","Summon") actor:SetAttribute("AttackState","Black Hole: condensing a singularity")
    core.Face(target)
    core.PoseAngles({RightShoulder={150,0,-25},LeftShoulder={150,0,25},Waist={-10,0,0}},S.SummonTime*.8)
    visual=cosmetic(V.Build,cast,core.Effects,hands,S,{Footprint=FOOTPRINT,GroundY=groundY})
    local carry=0 local emerged=false
    cast:Step(function(dt,now)
     if not valid()then cast:Dispose()return false end
     carry+=dt if carry<1/S.StepRate then return true end local step=carry carry=0
     local elapsed=now-born

      
     if elapsed<S.SummonTime then
       -- grows between the boss's hands, then drifts out and up to hang over the landing point
      local pos,scale=hands,.05+.4*G.Smooth(elapsed/S.HoldTime)
      if elapsed>=S.HoldTime then
       local u=G.Smooth((elapsed-S.HoldTime)/(S.SummonTime-S.HoldTime))
       pos=hands:Lerp(initial,u)+Vector3.yAxis*math.sin(math.pi*u)*6
       scale=.45+.55*u
      end
      if visual then cosmetic(visual.Update,pos,scale,groundY)end
      return true
     end
     if not emerged then
      emerged=true
      actor:SetAttribute("BlackHoleStage","Hunt")
      if visual then cosmetic(visual.Update,center,1,groundY) cosmetic(visual.Stage,"Hunt")end
      core.ScreenEffect("Shake",{Origin=center,Radius=S.PullRange,Intensity=.9,Duration=.45})
     end

      
     local active=elapsed-S.SummonTime
     if not collapseStart and active>=S.ActiveDuration then beginCollapse(now)end
     if not collapseStart then
      target=chooseTarget() or target  
     end

      
     if collapseStart then
      local fade=math.clamp((now-collapseStart)/S.FadeTime,0,1)
      if not burstFired and fade>=S.BurstAt then
       burstFired=true
        -- the collapse explodes: everyone near the hole's shadow is hit
       for _,char in ipairs(core.Characters())do
        if targetValid(char)and((char.HumanoidRootPart.Position-center)*FLAT).Magnitude<=S.BurstRadius then
         Encounter.Damage(char,S.BurstDamage,actor,nil,{Skill=S.Name})
         Status.ApplySlow(char,S.BurstSlow,S.BurstSlowSeconds,"P5BlackHoleBurst")
        end
       end
       core.ScreenEffect("Shake",{Origin=center,Radius=S.PullRange,Intensity=1.2,Duration=.7})
      end
      if visual then cosmetic(visual.Update,center,1-fade,groundY)end
      if fade>=1 then cast:Dispose()return false end
      return true
     end

      
     local ramp=active/S.ActiveDuration
     local power=G.Power(S,ramp)
     local arming=active<S.ArmDelay  
     if visual then cosmetic(visual.Power,power)end
     local previousCenter=center
     if not arming then
      local retained=core.RetainTarget(target)
      local desired=retained and G.Direction(center,retained.HumanoidRootPart.Position) or Vector3.zero
      direction=direction:Lerp(desired,math.clamp(step*S.TrackingRate,0,1))
      if direction.Magnitude>.01 then direction=direction.Unit end
      local speed=S.MoveSpeed*(1+S.MoveRamp*ramp)
      local nextGround=Placement.GroundPoint(center+direction*speed*step,{Clamp=true,Margin=S.Margin})
      if nextGround then center=nextGround+Vector3.yAxis*S.HoverHeight groundY=nextGround.Y end
     end

     local present={}
     for _,char in ipairs(core.Characters())do
      if targetValid(char)then
       local player=Players:GetPlayerFromCharacter(char) local r=char.HumanoidRootPart
       local previous=previousPlayers[char] or r.Position
       if not arming and not executed[player] and G.SweptContains(previous*FLAT,r.Position*FLAT,previousCenter*FLAT,center*FLAT,FOOTPRINT) then
        if Encounter.ExecuteHit(char,1,"P5BlackHole",nil,{UnavoidableFrom=actor})then
         executed[player]=true release(char)
         actor:SetAttribute("BlackHoleKills",(actor:GetAttribute("BlackHoleKills") or 0)+1)
         if visual then cosmetic(visual.Devour,r.Position)end
         core.ScreenEffect("Shake",{Origin=center,Radius=90,Intensity=.8,Duration=.2})
        end
       elseif not executed[player] and not r.Anchored and not char:GetAttribute("TimeFrozen")
        and not char:GetAttribute("Dashing") and Encounter.CanReceiveHit(char)
        and ((r.Position-center)*FLAT).Magnitude<(arming and S.ShockRadius or S.PullRange) then
        present[char]=true
        local record=forces[char]
        if record and record.Root~=r then release(char) record=nil end
        if not record then record=Pull.Attach(cast,r) forces[char]=record end
        if arming then Pull.Push(record,center,S) else Pull.Update(record,center,S,power)end
        char:SetAttribute(PULLED,not arming)
       end
       previousPlayers[char]=r.Position
      end
     end
     for char in pairs(forces)do if not present[char]then release(char)end end
     local count=0 for _ in pairs(forces)do count+=1 end
     actor:SetAttribute("BlackHolePullTargets",arming and 0 or count)
     if visual then cosmetic(visual.Update,center,1,groundY)end
     actor:SetAttribute("BlackHolePosition",center)
     return true
    end)
    while valid()and cast:Now()-born<S.SummonTime do Run.Heartbeat:Wait()end
    if not valid()then cast:Dispose()return false end
    return true
   end
   local ok,result=xpcall(run,debug.traceback)
   if not ok then cast:Dispose()error(result,0)end
   return result
  end)
 end
 function api.Dispose()if current then current:Dispose()end end
 return api
end

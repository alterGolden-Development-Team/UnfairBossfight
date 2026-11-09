local B=script:FindFirstAncestor("BossSystem")
local Registry=require(B.Combat.AttackRegistry)
local Effects=require(B.Combat.EffectService)
local Encounter=require(B.Players.PlayerEncounter)
local Placement=require(B.Encounter.ArenaPlacement)
local Difficulty=require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local V=require(B.Attacks.Shared.P35IllusionFX)
local VFX=require(script.Parent.Visuals)
local S=require(script.Parent.Style)
local Run=game:GetService("RunService")

local PALETTE={Neutral=S.NeutralColor,Real=S.RealColor,Fake=S.FakeColor}
 
 

 
local warned=false
local function fx(fn,...)
 local ok,result=pcall(fn,...)
 if not ok then
  if not warned then warned=true warn("[IllusionBomb] VFX error, attack keeps running: "..tostring(result))end
  return nil
 end
 return result
end

 
 
 

local function shuffle(list,rng)
 for i=#list,2,-1 do
  local j=rng:NextInteger(1,i)
  list[i],list[j]=list[j],list[i]
 end
end

 
local function scatter(n,hx,hz,rng)
 local points={}
 for _=1,n do
  local best,bestGap
  for _=1,12 do
   local candidate=Vector2.new(rng:NextNumber(-hx,hx),rng:NextNumber(-hz,hz))
   local gap=math.huge
   for _,p in ipairs(points)do gap=math.min(gap,(p-candidate).Magnitude)end
   if gap>=S.MinSpacing then best=candidate break end
   if not bestGap or gap>bestGap then best,bestGap=candidate,gap end
  end
  points[#points+1]=best
 end
 return points
end

 
local function spiral(n,hx,hz,rng)
 local points={}
 local start=rng:NextNumber(0,math.pi*2)
 for k=1,n do
  local r=math.sqrt((k-.5)/n)*.94
  local a=start+k*2.39996
  points[k]=Vector2.new(math.cos(a)*r*hx,math.sin(a)*r*hz)
 end
 return points
end

 
local function ring(n,hx,hz,rng)
 local points={}
 local start=rng:NextNumber(0,math.pi*2)
 for k=1,n do
  local a=start+(k-1)/n*math.pi*2
  points[k]=Vector2.new(math.cos(a)*hx*.72,math.sin(a)*hz*.72)
 end
 return points
end

 
 
 
local function buildPlan(count,bounds,margin,windup,rng)
 local hx,hz=bounds.HalfX-margin,bounds.HalfZ-margin
 local entries={}
 local remaining=count
 local volleys=S.Volleys
 for index,volley in ipairs(volleys)do
  local n=index==#volleys and remaining or math.min(remaining,math.floor(count*volley.Share+.5))
  remaining-=n
  local points
  if volley.Kind=="Spiral" then points=spiral(n,hx,hz,rng)
  elseif volley.Kind=="Ring" then points=ring(n,hx,hz,rng)
  else points=scatter(n,hx,hz,rng)end
  local hunters={}
  if volley.Kind=="Scatter" then
   local order={}
   for i=1,n do order[i]=i end
   shuffle(order,rng)
   for i=1,math.floor(n*S.HuntShare+.5)do hunters[order[i]]=true end
  end
  for i,point in ipairs(points)do
   entries[#entries+1]={Local=point,Hunt=hunters[i]==true,Volley=index}
  end
 end

 local realCount=math.floor(#entries*S.RealChance+.5)
 local bag={}
 for i=1,#entries do bag[i]=i<=realCount end
 shuffle(bag,rng)

 local t=windup
 for i,entry in ipairs(entries)do
  if i>1 then
   t+=S.LaunchGap
   if entry.Volley~=entries[i-1].Volley then t+=S.VolleyPause end
  end
  entry.Time=t
  entry.Real=bag[i]
 end
 return entries
end

 
 
 

return function(actor)
 local core=Registry.For(actor,"P1CombatCore")
 local rng=Random.new()
 local current
 local api={Cooldown=S.Cooldown}
 function api.CanUse(target)
  return not current and actor:GetAttribute("Phase")==3.5 and core.Active() and core.Alive(target)
   and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("IsIllusion")
   and not actor:GetAttribute("PhaseTransitionInProgress") and Placement.GetBounds()~=nil
   and not actor:GetAttribute("MysteriousGuyActive")  -- never stacked on the shadow chase
 end
 function api.Combo(target)
  if not api.CanUse(target) then return false end
  return core.Perform(target,S.Name,function()
   local generation=actor:GetAttribute("PhaseGeneration") or 0
   local count=math.max(1,math.floor(Difficulty.Count(S.Bombs,actor)+.5))
   local windup=S.Windup*Difficulty.Get(actor).Telegraph
   local bounds=Placement.GetBounds()
   local margin=math.min(S.Margin,bounds.HalfX*.25,bounds.HalfZ*.25)
   local plan=buildPlan(count,bounds,margin,windup,rng)
   local lastLaunch=plan[#plan] and plan[#plan].Time or windup
   local lastLand=lastLaunch+S.FlightTime
   local total=lastLand+.8
   local cast=Effects.NewCast(actor,S.Name,total+1)
   cast.PersistsThroughEmitterStun=true  -- a class stun stops the boss, not bombs already thrown
   current=cast
   local bombs,pops,owned={},{},{}
   local orbsFaded,kicked=false,false
   local born=cast:Now()
   local nextBomb=1
   local rightArm=actor:FindFirstChild("Right Arm")
   local leftArm=actor:FindFirstChild("Left Arm")
   local rightOrb,leftOrb
   local huntIndex=rng:NextInteger(0,7)

   local function own(object)
    if object then owned[#owned+1]=object end
    return object
   end
    -- the volleys outlive the windup while the boss fights on, so this checks the
    -- encounter only, not what he is doing (MovementRevision, the current Perform)
   local function valid()
    local h=actor:FindFirstChildOfClass("Humanoid")
    return cast:Alive() and actor.Parent~=nil and h~=nil and h.Health>0 and actor:GetAttribute("AIEnabled")~=false
     and actor:GetAttribute("Phase")==3.5
     and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
     and (actor:GetAttribute("PhaseGeneration") or 0)==generation
   end
   cast.OnDispose=function()
    if current==cast then current=nil end
    for _,object in ipairs(owned)do pcall(function()object:Destroy()end)end
    for _,entry in ipairs(bombs)do
     if entry.Tel then pcall(function()entry.Tel:Destroy()end)end
     if entry.Trail then pcall(function()entry.Trail:Destroy()end)end
    end
    if actor.Parent then actor:SetAttribute("IllusionBombActive",false)end
   end

    
   local function huntPosition()
    local roots={}
    for _,char in ipairs(core.Characters())do
     local humanoid=char:FindFirstChildOfClass("Humanoid")
     local rootPart=char:FindFirstChild("HumanoidRootPart")
     if humanoid and humanoid.Health>0 and rootPart then roots[#roots+1]=rootPart end
    end
    if #roots==0 then return nil end
    huntIndex+=1
    local rootPart=roots[(huntIndex-1)%#roots+1]
    local velocity=rootPart.AssemblyLinearVelocity*Vector3.new(1,0,1)
    local angle=rng:NextNumber(0,math.pi*2)
    local offset=Vector3.new(math.cos(angle),0,math.sin(angle))*rng:NextNumber(0,S.HuntSpread)
    return rootPart.Position+velocity*S.HuntLead+offset
   end
   local function clampToArena(world)
    local localPos=bounds.Frame:PointToObjectSpace(world)
    local hx,hz=bounds.HalfX-margin,bounds.HalfZ-margin
    return bounds.Frame:PointToWorldSpace(Vector3.new(math.clamp(localPos.X,-hx,hx),0,math.clamp(localPos.Z,-hz,hz)))
   end

   local function launch(entry,index)
    local desired
    if entry.Hunt then
     local ok,hunted=pcall(huntPosition)
     if ok and hunted then desired=clampToArena(hunted)end
    end
    desired=desired or bounds.Frame:PointToWorldSpace(Vector3.new(entry.Local.X,0,entry.Local.Y))
    local point=Placement.GroundPoint(desired,{Margin=margin})
    if not point then return end

    local rightHand=index%2==1
    local arm=rightHand and rightArm or leftArm
    local orb=rightHand and rightOrb or leftOrb
    if orb then fx(orb.Pulse,orb)end

    local start=arm and (arm.CFrame*CFrame.new(0,-1.1,0)).Position or core.Root.Position+Vector3.yAxis*3
    local obj=V.Bomb(cast,core.Effects,start)
    local tint=PALETTE.Neutral
    bombs[#bombs+1]={
     Part=obj,Start=start,Point=point,
     At=born+entry.Time,Real=entry.Real,
     Trail=fx(VFX.Trail,core.Effects,start,tint,S.AccentColor),
    }
   end

   local function land(entry,now)
    entry.Done=true
    if entry.Tel then fx(entry.Tel.LockIn,entry.Tel)entry.Tel=nil end
    if entry.Trail then fx(entry.Trail.Destroy,entry.Trail)entry.Trail=nil end
    Effects.Release(entry.Part)
     -- real and illusion bombs burst the same golden way; only a real one hurts
    pops[#pops+1]=V.Pop(cast,core.Effects,entry.Point,true,S.Radius,now,rng)
    if entry.Real then
     fx(VFX.RealImpact,core.Effects,entry.Point,S.Radius,PALETTE.Real,S.AccentColor)
     for _,char in ipairs(core.Characters())do
      if V.AreaHit(char,entry.Point,S.Radius,S.HitHeight) and core.CanHit(char,entry.Point+Vector3.yAxis) then
       Encounter.Damage(char,S.Damage,actor,nil,{Skill=S.Name})
       if S.HitSlow then pcall(require(B.Combat.StatusEffectService).ApplySlow,char,S.HitSlow,S.HitSlowSeconds,"P35IllusionBomb") end
       fx(VFX.Hit,core.Effects,char:FindFirstChild("HumanoidRootPart"),PALETTE.Real,S.AccentColor)
      end
     end
     core.ScreenEffect("Shake",{Origin=entry.Point,Radius=45,Intensity=.2,Duration=.18})
    else
     fx(VFX.RealImpact,core.Effects,entry.Point,S.Radius,PALETTE.Fake,S.AccentColor)
    end
   end

   local function run()
    actor:SetAttribute("IllusionBombActive",true)
    actor:SetAttribute("AttackState","Illusion Bomb: a sky full of surprises")
    core.Face(target)
    core.PoseAngles({RightShoulder={140,0,-30},LeftShoulder={110,0,35},Waist={-7,0,0}},windup)
    rightOrb=own(fx(VFX.HandOrb,core.Effects,rightArm,PALETTE.Neutral,S.AccentColor,windup))
    leftOrb=own(fx(VFX.HandOrb,core.Effects,leftArm,PALETTE.Neutral,S.AccentColor,windup))

    local carry=0
    local stepTime=1/S.StepRate
    cast:Step(function(dt,now)
     if not valid() then cast:Dispose()return false end
     carry+=dt if carry<stepTime*.9 then return true end carry=0
     local elapsed=now-born

     while nextBomb<=#plan and elapsed>=plan[nextBomb].Time do
      if not kicked then
       kicked=true
       core.ScreenEffect("Shake",{Origin=core.Root.Position,Radius=70,Intensity=.1,Duration=.25})
      end
      launch(plan[nextBomb],nextBomb)
      nextBomb+=1
     end

     for _,entry in ipairs(bombs)do
      if not entry.Done then
       local progress=math.clamp((now-entry.At)/S.FlightTime,0,1)
       local point=V.Arc(entry.Start,entry.Point+Vector3.yAxis,S.ArcHeight,progress)
       entry.Part.CFrame=CFrame.new(point)*CFrame.Angles(progress*12,progress*6,0)
       if entry.Trail then entry.Trail.Part.CFrame=CFrame.new(point)end
       if progress>=1 then land(entry,now)end
      end
     end
     for i=#pops,1,-1 do if not V.UpdatePop(pops[i],now)then table.remove(pops,i)end end

     if not orbsFaded and nextBomb>#plan and elapsed>=lastLaunch+.2 then
      orbsFaded=true
      if rightOrb then fx(rightOrb.Fade,rightOrb)end
      if leftOrb then fx(leftOrb.Fade,leftOrb)end
     end

     if elapsed>=total then cast:Dispose()return false end
     return true
    end)
     -- the boss only holds the windup; the volleys keep flying from his hands while he fights on
    while cast:Alive() and valid() and cast:Now()-born<windup do Run.Heartbeat:Wait()end
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

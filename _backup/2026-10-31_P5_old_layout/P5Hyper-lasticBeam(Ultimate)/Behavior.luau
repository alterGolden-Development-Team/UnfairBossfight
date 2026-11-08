local B=script:FindFirstAncestor("BossSystem")
require(script.Parent.Presentation).Publish()
local S=require(script.Parent.Style)
local G=require(script.Parent.Geometry)
local BeamMath=G
local Registry=require(B.Combat.AttackRegistry)
local Effects=require(B.Combat.EffectService)
local Encounter=require(B.Players.PlayerEncounter)
local Placement=require(B.Encounter.ArenaPlacement)
local Time=require(B.Mechanics.Time.TimeEffectController)
local Cooldowns=require(B.Combat.AbilityCooldownService)
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local BALANCE=table.freeze({Skill=S.Name})

 
local PARAM_KEYS={"Charge","FireDuration","BeamRange","BeamWidth","BeamHeight","MuzzleOffset","GrowTime","OpenTime",
 "CloseTime","HitPadding","AimLockWindow","HoldTime","RingCount","RingInterval","RingSpeed","RingMaxRadius",
 "RingThickness","LowHeight","TallHeight","White","Yellow","Gold","Amber","Soot","Dust"}
local PARAMS={}
for _,key in ipairs(PARAM_KEYS) do PARAMS[key]=S[key] end

local AIM_SEND_INTERVAL=1/15  
local BOSS_TURN_RATE=math.rad(200)

 
local function segDist(p,a,b)
 local ab=b-a
 local len2=ab:Dot(ab)
 if len2<1e-6 then return (p-a).Magnitude end
 local t=math.clamp((p-a):Dot(ab)/len2,0,1)
 return (p-(a+ab*t)).Magnitude
end

return function(actor)
 local core=Registry.For(actor,"P1CombatCore")
 local current
 local api={Cooldown=S.Cooldown,IsUltimate=true,UltimatePhase=5,ManagesCooldown=true}
 function api.CanUse(target)
  return not current and actor:GetAttribute("Phase")==5 and core.Active() and core.Alive(target)
   and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("PhaseTransitionInProgress")
   and Placement.GetBounds()~=nil and Cooldowns.Ready(actor,S.Name)
 end
 function api.Combo(target)
  local S=require(B.Attacks.Shared.P5AstralCore).Tune(actor,S,{Speed={"HuntMaxSpeed","RingSpeed"},Agile={"AcquireTurnRate"},Count={"RingCount"},Tell={"Charge"}})  -- difficulty knobs, this cast only
  if not api.CanUse(target) then return false end
  return core.Perform(target,S.Name,function()
   Cooldowns.Start(actor,S.Name,S.Cooldown)
   Encounter.Say("Run as far as you like. Light bends back to me.",nil,{Duration=3.2})
   local root=core.Root
   local generation=actor:GetAttribute("PhaseGeneration") or 0
   local revision=actor:GetAttribute("MovementRevision") or 0
   local total=S.Charge+S.FireDuration+S.RingMaxRadius/S.RingSpeed+2
   local cast=Effects.NewCast(actor,S.Name,total);cast.TimeStopExempt=true;current=cast
   local token=Http:GenerateGUID(false)
   local anchored=root.Anchored
   local rings,beamHit={},{}
   local ended=false
   local function valid()
    return cast:Alive() and core.Active() and actor:GetAttribute("Phase")==5
     and actor:GetAttribute("PhaseGeneration")==generation
     and (actor:GetAttribute("MovementRevision") or 0)==revision
     and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
   end
   local function send(stage,data)
    data=data or {};data.Stage=stage;data.Token=token;data.Owner=actor;data.Origin=root.Position;data.Radius=1000
    data.Params=PARAMS
    core.ScreenEffect("HyperElastic",data)
   end
    
   local function sendAim(heading,speed,locked)
    core.ScreenEffect("HyperElastic",{Stage="Aim",Token=token,Owner=actor,Origin=root.Position,Radius=1000,
     Heading=heading,Speed=speed,Locked=locked,At=workspace:GetServerTimeNow()})
   end
   cast.OnDispose=function()
    if current==cast then current=nil end
    if actor.Parent then
     actor:SetAttribute("HyperElasticActive",false)
     if actor:GetAttribute("PhaseGeneration")==generation and (actor:GetAttribute("MovementRevision") or 0)==revision then Time.SetAnchored(root,anchored) end
    end
    if not ended then pcall(send,"End",{Interrupted=true}) end
   end
   Time.SetAnchored(root,true)
   actor:SetAttribute("HyperElasticActive",true)
   actor:SetAttribute("HyperElasticRings",0)
   actor:SetAttribute("HyperElasticTallRings",0)
   actor:SetAttribute("HyperElasticBeamHits",0)
   actor:SetAttribute("HyperElasticChargeStartedAt",workspace:GetServerTimeNow())
   actor:SetAttribute("AttackState","Hyper-lastic Beam: charging")

    
   local pivot=root.Position+Vector3.yAxis*S.BeamHeight
   local function aimTarget()
    if target and target.Parent and core.Alive(target) then return target end
    local best,bestDistance
    for _,char in ipairs(core.Characters()) do
     local hrp=char:FindFirstChild("HumanoidRootPart")
     if hrp and Players:GetPlayerFromCharacter(char) and core.Alive(char) then
      local distance=(hrp.Position-pivot).Magnitude
      if not bestDistance or distance<bestDistance then best,bestDistance=char,distance end
     end
    end
    return best
   end
    
   local function desiredHeading(fallback)
    local char=aimTarget()
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return fallback end
    local flat=Vector3.new(hrp.Position.X-pivot.X,0,hrp.Position.Z-pivot.Z)
    if flat.Magnitude<4 then return fallback end
    return BeamMath.Heading(flat)
   end
   local flatLook=root.CFrame.LookVector*Vector3.new(1,0,1)
   local aim={Heading=desiredHeading(flatLook.Magnitude>.01 and BeamMath.Heading(flatLook) or 0),Speed=0}
   local bossHeading=flatLook.Magnitude>.01 and BeamMath.Heading(flatLook) or aim.Heading
   local function turnBoss(dt)
    if not S.BossFollowsAim then return end
    local step=BOSS_TURN_RATE*dt
    bossHeading=bossHeading+math.clamp(BeamMath.Wrap(aim.Heading-bossHeading),-step,step)
    pcall(function()
     root.CFrame=CFrame.lookAt(root.Position,root.Position+BeamMath.Dir(bossHeading))
    end)
   end

   core.Face(target)
   core.PoseAngles({RightShoulder={95,0,0},LeftShoulder={95,0,0},RightElbow={0,0,0},LeftElbow={0,0,0}},.25)
   local floor=Placement.GroundPoint(root.Position,{Clamp=true}) or root.Position-Vector3.yAxis*3
    
   send("Charge",{StartedAt=workspace:GetServerTimeNow(),BeamOrigin=pivot,Heading=aim.Heading,Floor=floor})

    
   local began=os.clock()
   local lastStep,lastSend=began,0
   local lockAt=S.Charge-S.AimLockWindow
   repeat
    Run.Heartbeat:Wait() if not valid() then cast:Dispose();return false end
    local now=os.clock()
    local dt=math.min(now-lastStep,.1);lastStep=now
    local elapsed=now-began
    local locked=elapsed>=lockAt
    local speed=0
    if not locked and dt>0 then
     local before=aim.Heading
     aim.Heading=BeamMath.AcquireStep(aim.Heading,desiredHeading(aim.Heading),dt,S)
     speed=(aim.Heading-before)/dt
    end
    aim.Speed=0
    if elapsed>.35 then turnBoss(dt) end
    if now-lastSend>=AIM_SEND_INTERVAL then lastSend=now;sendAim(aim.Heading,speed,locked) end
   until elapsed>=S.Charge

    
   local fireStart=workspace:GetServerTimeNow()
   actor:SetAttribute("HyperElasticFiredAt",fireStart)
   actor:SetAttribute("AttackState","Hyper-lastic Beam: firing")
   send("Fire",{StartedAt=fireStart,BeamOrigin=pivot,Heading=aim.Heading,Floor=floor})
   local nextRing=1
   local function emitRing(index)
    local tall=index%3==0
    local born=workspace:GetServerTimeNow()
    table.insert(rings,{Index=index,Born=born,Radius=0,Tall=tall,Hit={}})
    actor:SetAttribute("HyperElasticRings",index)
    if tall then actor:SetAttribute("HyperElasticTallRings",actor:GetAttribute("HyperElasticTallRings")+1) end
    send("Ring",{Index=index,Tall=tall,StartedAt=born,Center=floor})
   end
   local lastClock,lastAimSend=workspace:GetServerTimeNow(),0
   while valid() do
    local clock=workspace:GetServerTimeNow()
    local elapsed=clock-fireStart
    local dt=math.min(clock-lastClock,.1);lastClock=clock
    if elapsed<S.FireDuration then
     while nextRing<=S.RingCount and elapsed>=(nextRing-1)*S.RingInterval do emitRing(nextRing);nextRing+=1 end
      
     if dt>0 then
      BeamMath.HuntStep(aim,desiredHeading(aim.Heading),dt,elapsed,S)
      turnBoss(dt)
     end
     if clock-lastAimSend>=AIM_SEND_INTERVAL then lastAimSend=clock;sendAim(aim.Heading,aim.Speed,true) end
      
     local a,b=BeamMath.Segment(pivot,aim.Heading,elapsed,S)
     local reach=BeamMath.Width(elapsed,S)*.5+S.HitPadding
     if reach>S.HitPadding+.5 then
      for _,char in ipairs(core.Characters()) do
       local player=Players:GetPlayerFromCharacter(char)
       local hrp=char:FindFirstChild("HumanoidRootPart")
       if player and hrp and core.Alive(char) and not beamHit[player] and segDist(hrp.Position,a,b)<=reach then
        if Encounter.ExecuteHit(char,S.BeamLives,"Hyper-lastic Beam") then
         beamHit[player]=true
         actor:SetAttribute("HyperElasticBeamHits",actor:GetAttribute("HyperElasticBeamHits")+1)
         send("Impact",{Position=hrp.Position})
        end
       end
      end
     end
    end
    for i=#rings,1,-1 do
     local ring=rings[i]
     local radius=(workspace:GetServerTimeNow()-ring.Born)*S.RingSpeed
     local height=ring.Tall and S.TallHeight or S.LowHeight
     for _,char in ipairs(core.Characters()) do
      local hrp=char:FindFirstChild("HumanoidRootPart")
      if hrp and core.Alive(char) and not ring.Hit[char] then
       local offset=hrp.Position-floor
       local distance=Vector3.new(offset.X,0,offset.Z).Magnitude
       local padding=S.RingThickness*.5+2
       if distance>=ring.Radius-padding and distance<=radius+padding
        and G.Feet(char,hrp)<floor.Y+height and hrp.Position.Y+hrp.Size.Y*.5>floor.Y then
        ring.Hit[char]=true
        Encounter.Damage(char,ring.Tall and S.TallDamage or S.RingDamage,actor,nil,BALANCE)
       end
      end
     end
     ring.Radius=radius
     if radius>=S.RingMaxRadius then table.remove(rings,i) end
    end
    if elapsed>=S.FireDuration and #rings==0 then break end
    task.wait(1/30)
   end
   if not valid() then cast:Dispose();return false end
   ended=true;send("End",{});cast:Dispose()
   actor:SetAttribute("HyperElasticCompletedAt",workspace:GetServerTimeNow())
   return true
  end)
 end
 function api.Dispose() if current then current:Dispose() end end
 return api
end

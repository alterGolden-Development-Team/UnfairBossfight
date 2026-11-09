local B=script:FindFirstAncestor("BossSystem")
local S=require(script.Parent.Style)
local G=require(script.Parent.Geometry)
local Pull=require(script.Parent.Pull)
local Waves=require(script.Parent.Waves)
require(script.Parent.Presentation).Publish()
local Registry=require(B.Combat.AttackRegistry)
local Effects=require(B.Combat.EffectService)
local Encounter=require(B.Players.PlayerEncounter)
local Placement=require(B.Encounter.ArenaPlacement)
local Time=require(B.Mechanics.Time.TimeEffectController)
local Cooldowns=require(B.Combat.AbilityCooldownService)
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")

 
 
local function pose(rs,ls,re,le,waist)
 return {RightShoulder=rs,LeftShoulder=ls,RightElbow=re,LeftElbow=le,Waist=waist}
end
local POSES={
 Invoke  =pose({70,0,28},{70,0,-28},{40,0,0},{40,0,0},{-6,0,0}),      
 Gather  =pose({140,0,24},{140,0,-24},{30,0,0},{30,0,0},{-4,0,0}),    
 Collapse=pose({152,0,14},{152,0,-14},{34,0,0},{34,0,0},{-8,0,0}),    
 Critical=pose({165,0,6},{165,0,-6},{40,0,0},{40,0,0},{-12,0,0}),     
 Breath  =pose({172,0,2},{172,0,-2},{46,0,0},{46,0,0},{-16,0,0}),     
 Release =pose({35,0,52},{35,0,-52},{8,0,0},{8,0,0},{16,0,0}),        
 Spent   =pose({8,0,10},{8,0,-10},{14,0,0},{14,0,0},{24,0,0}),        
}
local function chargeStage(progress)
 if progress<.15 then return "Invoke" elseif progress<.55 then return "Gather" elseif progress<.85 then return "Collapse" end
 return "Critical"
end

return function(actor)
 local core=Registry.For(actor,"P1CombatCore")
 local current
 local api={Cooldown=S.Cooldown,IsUltimate=true,UltimatePhase=5,ManagesCooldown=true}
 function api.CanUse(target)
  return not current and actor:GetAttribute("Phase")==5 and core.Active() and core.Alive(target)
   and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("PhaseTransitionInProgress")
   and Placement.GetBounds()~=nil and (Cooldowns.Ready(actor,S.Name) or actor:GetAttribute("P5LastStand")==S.Name)
 end
 function api.Combo(target)
  local S=require(B.Attacks.Shared.P5AstralCore).Tune(actor,S,{Speed={"PullStart","PullEnd","PullSpeedLimit","ShockwaveSpeed"},Rate={"ShockwaveInterval","ShockwaveIntervalEnd"},Tell={"Breath"}})
  if not api.CanUse(target) then return false end
  return core.Perform(target,S.Name,function()
   Cooldowns.Start(actor,S.Name,S.Cooldown)
   if actor:GetAttribute("P5LastStand")==S.Name then actor:SetAttribute("P5LastStand",nil) end  -- paid (Combat/P5ModeService owes it when the Time shield is down)
   Encounter.Say("This is where every story ends. Breathe in... it will be your last.",nil,{Duration=3.2})
   local root=core.Root
   local generation=actor:GetAttribute("PhaseGeneration") or 0
   local revision=actor:GetAttribute("MovementRevision") or 0
   local anchored=root.Anchored
   local center=Placement.GroundPoint(root.Position,{Clamp=true}) or root.Position-Vector3.yAxis*3
   local cast=Effects.NewCast(actor,S.Name,S.Charge+S.Breath+S.PillarDuration+S.Recovery+2)
   cast.TimeStopExempt=true current=cast
   local token=Http:GenerateGUID(false)
   local forces,hit={},{}
   local waves=Waves.New(actor,core,center,S)
   local ended=false
   local hover=0  
   local function valid()
    return cast:Alive() and core.Active() and actor:GetAttribute("Phase")==5
     and (actor:GetAttribute("PhaseGeneration") or 0)==generation
     and (actor:GetAttribute("MovementRevision") or 0)==revision
     and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
   end
   local function unchanged()
    return (actor:GetAttribute("PhaseGeneration") or 0)==generation and (actor:GetAttribute("MovementRevision") or 0)==revision
   end
   local function send(stage,data)
    data=data or {} data.Stage=stage data.Token=token data.Owner=actor data.Center=center data.Params=S
    data.Radius=1000 core.ScreenEffect("Finality",data)
   end
   local function removeForce(char)
    local record=forces[char]
    if record then Pull.Release(record) forces[char]=nil end
   end
    
    
   local function setHover(h)
    if h==hover or not root.Parent then return end
    root.CFrame+=Vector3.yAxis*(h-hover)
    hover=h
   end
   cast.OnDispose=function()
    waves.Dispose()
    for char in pairs(forces) do removeForce(char) end
    if current==cast then current=nil end
    if actor.Parent then
     local same=unchanged()
     if same and hover~=0 and root.Parent then root.CFrame-=Vector3.yAxis*hover hover=0 end
     actor:SetAttribute("FinalityActive",false)
     actor:SetAttribute("FinalityRecovering",false)
     actor:SetAttribute("FinalityStage","")
     if same then Time.SetAnchored(root,anchored) end
    end
    if not ended then pcall(send,"End",{Interrupted=true}) end
   end
   Time.SetAnchored(root,true)
   actor:SetAttribute("FinalityActive",true)
   actor:SetAttribute("FinalityHits",0)
   actor:SetAttribute("FinalityBeat",0)
   actor:SetAttribute("FinalityWaveHits",0)
   actor:SetAttribute("FinalityPullTargets",0)
   actor:SetAttribute("AttackState","Finality: gathering")
   actor:SetAttribute("FinalityStage","Charge")
   core.Face(target)

    
    
    
   local started=workspace:GetServerTimeNow()
   send("Charge",{StartedAt=started})
   local stageName,lastBeat="",0
   while valid() do
    local t=workspace:GetServerTimeNow()-started
    if t>=S.Charge then break end
    local progress=t/S.Charge
    local beats=G.BeatPhase(t,S)
    if math.floor(beats)~=lastBeat then
     while lastBeat<math.floor(beats) do
      lastBeat+=1
      waves.Add(G.ChargeWave(lastBeat,S),started)
     end
     actor:SetAttribute("FinalityBeat",lastBeat)  
    end
    local name=chargeStage(progress)
    if name~=stageName then
     stageName=name
     core.PoseAngles(POSES[name],name=="Invoke" and .3 or .55)
    end
    setHover(S.Hover*G.Smooth(t/S.HoverRise))
    local present={}
    for _,char in ipairs(core.Characters()) do
     local r=char:FindFirstChild("HumanoidRootPart")
     local player=Players:GetPlayerFromCharacter(char)
     if player and player.Character==char and r and core.Alive(char) and not r.Anchored
      and not char:GetAttribute("TimeFrozen") and not char:GetAttribute("Dashing")
      and Encounter.CanReceiveHit(char) and not Encounter.IsDefeated(player) then
      local d=center-r.Position local flat=Vector3.new(d.X,0,d.Z)
      if flat.Magnitude<S.PullRange then
       present[char]=true
       local record=forces[char]
       if record and record.Root~=r then removeForce(char) record=nil end
       if not record then record=Pull.Attach(cast,r) forces[char]=record end
       Pull.Update(record,center,progress,S,beats)
      end
     end
    end
    for char in pairs(forces) do if not present[char] then removeForce(char) end end
    local pullCount=0 for _ in pairs(forces) do pullCount+=1 end
    actor:SetAttribute("FinalityPullTargets",pullCount)
    waves.Step(workspace:GetServerTimeNow())
    task.wait(1/30)
   end
   if not valid() then cast:Dispose() return false end
   for char in pairs(forces) do removeForce(char) end
   actor:SetAttribute("FinalityPullTargets",0)

    
    
    
    
   actor:SetAttribute("AttackState","Finality: collapse")
   actor:SetAttribute("FinalityStage","Breath")
   local breathAt=workspace:GetServerTimeNow()
   send("Breath",{StartedAt=breathAt})
   core.PoseAngles(POSES.Breath,S.Breath*.7)
   local hoverBase=hover
   while valid() do
    local t=workspace:GetServerTimeNow()-breathAt
    if t>=S.Breath then break end
    setHover(hoverBase+S.Hover*.4*G.Smooth(t/S.Breath))
    waves.Step(workspace:GetServerTimeNow())
    task.wait(1/30)
   end
   if not valid() then cast:Dispose() return false end

    
    
    
   actor:SetAttribute("AttackState","Finality: annihilation")
   actor:SetAttribute("FinalityStage","Pillar")
   local fired=workspace:GetServerTimeNow()
   waves.Clear()
   for _,spec in ipairs(G.BurstWaves(S)) do waves.Add(spec,fired) end
   send("Pillar",{StartedAt=fired})
   core.PoseAngles(POSES.Release,.1)
   local hoverPeak=hover
   while valid() do
    local t=workspace:GetServerTimeNow()-fired
    if t>=S.PillarDuration then break end
    setHover(hoverPeak*(1-G.EaseOut(t/.16,3)))  
    local radius=G.PillarRadius(t,S)
    for _,char in ipairs(core.Characters()) do
     local player=Players:GetPlayerFromCharacter(char)
     if player and not hit[player] and G.Contains(char,center,S,radius)
      and Encounter.ExecuteHit(char,1,"P5Finality",nil,{UnavoidableFrom=actor}) then
      hit[player]=true
      actor:SetAttribute("FinalityHits",(actor:GetAttribute("FinalityHits") or 0)+1)
     end
    end
    waves.Step(workspace:GetServerTimeNow())
    task.wait(1/30)
   end
   if not valid() then cast:Dispose() return false end
   setHover(0)

    
    
    
   if S.Recovery>0 then
    actor:SetAttribute("AttackState","Finality: spent")
    actor:SetAttribute("FinalityStage","Recovery")
    actor:SetAttribute("FinalityRecovering",true)
    local spent=workspace:GetServerTimeNow()
    send("Aftermath",{StartedAt=spent})
    core.PoseAngles(POSES.Spent,.35)
    while valid() and workspace:GetServerTimeNow()-spent<S.Recovery do task.wait(1/30) end
    if not valid() then cast:Dispose() return false end
   end

   ended=true send("End",{}) cast:Dispose()
   actor:SetAttribute("FinalityCompletedAt",workspace:GetServerTimeNow())
   return true
  end)
 end
 function api.Dispose() if current then current:Dispose() end end
 return api
end

local B=script:FindFirstAncestor("BossSystem")
local A=require(B.Attacks.Shared.P5AstralCore)
local S=require(script.Parent.Style)
local Visuals=require(script.Parent.Visuals)
local UP=Vector3.yAxis
local CollectionService=game:GetService("CollectionService")
local Placement=require(B.Encounter.ArenaPlacement)
local FlightPoint=require(game.ReplicatedStorage.BossShared.Presentation.DyingStarFlight)

return function(actor)
 local current
 local api={Cooldown=S.Cooldown,ManagesCooldown=true}
 function api.CanUse(target)return A.Ready(actor,S,current,target)end
 function api.Combo(target)
  local S=require(B.Attacks.Shared.P5AstralCore).Tune(actor,S,{Speed={"DiveSpeed"},Count={"Beams"},Tell={"SummonTime","ThrowDelay"}})  -- difficulty knobs, this cast only
   -- summon, beam volley, throw delay, flight budget, fuse, tail
  local TOTAL=S.SummonTime+(S.Beams-1)*S.BeamGap+S.ThrowDelay+S.OrbLife+S.Fuse+S.Tail+.75
  local HIT_RADIUS=S.BeamRadius+S.BeamHitPadding
  if not api.CanUse(target)then return false end
  local core=require(B.Combat.AttackRegistry).For(actor,"P1CombatCore")
  return core.Perform(target,S.Name,function()
   A.StartCooldown(actor,S)
   local fx
   local ctx=A.Create(actor,S,TOTAL+.5,function()
    if fx then Visuals.Finish(fx)end
    current=nil
   end)
   current=ctx.Cast
   ctx.Send("Start",{Duration=TOTAL})
   fx=Visuals.Build(ctx,core,S,TOTAL)
   pcall(core.PoseAngles,{RightShoulder={165,0,-15},LeftShoulder={40,0,-20},Waist={-8,0,0}},S.SummonTime*.6)
   local shots=0
   local thrownAt,flight,fuseAt,burstAt
   local finishAt=TOTAL
   local position=core.Root.Position+UP*S.StarHeight

   local function fireBeam()
    shots+=1
    local retained=core.RetainTarget(target)
    local look=core.Root.CFrame.LookVector
    local aim=retained and retained.HumanoidRootPart.Position or position+look*S.BeamRange
    local delta=aim-position
    local dir=delta.Magnitude>.01 and delta.Unit or look
    local endpoint=position+dir*S.BeamRange
    local best,distance
    for _,char in ipairs(ctx.Targets(S.LatchRange,position))do
     local d=A.SegmentDistance(char.HumanoidRootPart.Position,position,endpoint)
     if d<=S.LatchRadius and(not distance or d<distance)then best,distance=char,d end
    end
    if best then endpoint=best.HumanoidRootPart.Position end
    if S.BeamsBlockedByWalls then
     local span=endpoint-position
     local wall=workspace:Raycast(position,span,core.Params())
     if wall and(wall.Position-position).Magnitude<span.Magnitude-1 then endpoint=wall.Position end
    end
    for _,char in ipairs(ctx.Targets())do
     if A.SegmentDistance(char.HumanoidRootPart.Position,position,endpoint)<=HIT_RADIUS then
      ctx.Damage(char,S.BeamDamage,false,position)
     end
    end
    Visuals.BeamFire(fx,position,endpoint,shots)
   end

    -- the star lands; damage lands when the fuse ends (Fuse=0: the same step)
   local function critical(t)
    fuseAt=t
    Visuals.Critical(fx,position,S.Fuse,S.ExplosionRadius)
   end
   local function detonate(t)
    burstAt=t finishAt=t+S.Tail+.75
    for _,char in ipairs(ctx.Targets(S.ExplosionRadius,position))do
     ctx.Damage(char,S.BurstDamage,false,position)
     ctx.Burn(char,S.BurnAmounts,S.BurnInterval,ctx.Cast,nil,position)
    end
    ctx.Send("Burst",{Center=position})
    pcall(core.ScreenEffect,"Shake",{Origin=position,Radius=180,Intensity=1.4,Duration=.8})
    Visuals.Burst(fx,position,S.ExplosionRadius)
   end

   ctx.Step(function(dt,t)
    if not thrownAt then
     position=core.Root.Position+UP*S.StarHeight
     local fireT=t-S.SummonTime
     while fireT>=0 and shots<S.Beams and fireT>=shots*S.BeamGap do fireBeam()end
     if shots>=S.Beams and fireT>=(S.Beams-1)*S.BeamGap+S.ThrowDelay then
      thrownAt=t
       -- aimed at the ground under the target (or ahead of the boss)
      local retained=core.RetainTarget(target)
      local aim=retained and retained.HumanoidRootPart.Position or core.Root.Position+core.Root.CFrame.LookVector*40
       -- combo with the black hole (EncounterConfig.Phase5Combos): land on its pull point, the
       -- shadow everyone is being dragged toward
      for _,hole in ipairs(CollectionService:GetTagged("P5BlackHoleRoot"))do
       if hole:IsDescendantOf(workspace)then
        aim=Placement.GroundPoint(hole.Position,{Clamp=true})or hole.Position
        break
       end
      end
      local floor=workspace:Raycast(aim+UP*4,-UP*80,core.Params())
      aim=floor and floor.Position or aim-UP*3
       -- the star climbs high above the landing point, hangs for a beat, then dives straight down
      flight={From=position,Apex=aim+UP*S.DiveHeight,Impact=aim,Rise=S.RiseTime,Hang=S.HangTime,Dive=S.DiveHeight/S.DiveSpeed}
      flight.ETA=flight.Rise+flight.Hang+flight.Dive
      pcall(core.PoseAngles,{RightShoulder={160,0,-20},LeftShoulder={40,0,20},Waist={-6,0,0}},.15)
      Visuals.Throw(fx,flight)
     end
    elseif not fuseAt then
      -- follows the shared path; players caught near the landing take the blast
     local u=t-thrownAt
     position=FlightPoint(flight,u)
     if u>=flight.ETA or u>=S.OrbLife then
      position=flight.Impact
      critical(t)
      if S.Fuse<=0 then detonate(t)end
     end
    elseif not burstAt then
     if t-fuseAt>=S.Fuse then detonate(t)end
    end
    if burstAt and t>=finishAt then ctx.Cast:Dispose()return false end
    return true
   end)
   ctx.Wait()
   return true
  end)
 end
 function api.Dispose()if current then current:Dispose()end end
 return api
end

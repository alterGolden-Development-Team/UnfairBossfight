local B=script:FindFirstAncestor("BossSystem")
local A=require(B.Attacks.Shared.P5AstralCore)
local S=require(script.Parent.Style)
require(script.Parent.Presentation).Publish()
local Visuals=require(script.Parent.Visuals)
local Players=game:GetService("Players")
local CollectionService=game:GetService("CollectionService")

local Encounter=require(B.Players.PlayerEncounter)
local Status=require(B.Combat.StatusEffectService)
local BorealisStyle=require(script.Parent.Parent.P5Borealis.Style)
local BorealisVisuals=require(script.Parent.Parent.P5Borealis.Visuals)
local TAG="PolarisCaster"  

 
local BASE_POSE={
 RightShoulder={35,0,35},LeftShoulder={35,0,-35},
 RightHip={65,25,10},LeftHip={65,-25,-10},
 Waist={0,0,0}
}
local ARM={RightShoulder=true,LeftShoulder=true}
local beatSeq=0

local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end
 
local function riseCurve(x)
 x=math.clamp(x,0,1)
 if x<.7 then return 1.04*smooth(x/.7)end
 return 1.04-.04*smooth((x-.7)/.3)
end

 
local warned={}
local function safe(fn,...)
 local ok,err=pcall(fn,...)
 if not ok and not warned[fn]then
  warned[fn]=true
  warn("[Polaris] cosmetic error (attack continues): "..tostring(err))
 end
 return ok
end

 
 
local function rootOf(v)
 local ok,root=pcall(function()
  if typeof(v)~="Instance"then return nil end
  local m=v:IsA("Model")and v or v:FindFirstAncestorOfClass("Model")
  return m and m:FindFirstChild("HumanoidRootPart")
 end)
 return ok and root or nil
end

local warnedKeys={}
local function warnOnce(key,msg)
 if warnedKeys[key]then return end
 warnedKeys[key]=true
 warn(msg)
end

return function(actor)
 local current
 local api={Cooldown=S.Cooldown,ManagesCooldown=true,IsUltimate=true,UltimatePhase=5}
 function api.CanUse(target)return A.Ready(actor,S,current,target)end
 function api.Combo(target)
  local S=require(B.Attacks.Shared.P5AstralCore).Tune(actor,S,{Speed={"ProjectileSpeed"},Agile={"TurnRate"},Count={"Shots"},Tell={"Telegraph"}})
  if not api.CanUse(target)then return false end
  local core=require(B.Combat.AttackRegistry).For(actor,"P1CombatCore")
  return core.Perform(target,S.Name,function()
    -- he takes the middle of the map first: Polaris is always cast from the centre (blinks there, on his own floor height)
   do
    local ok,err=pcall(function()
     local sc=require(B.Attacks.Shared.P5StrikeCore).Context(actor,S.Name)
     local floor=sc.Ground(Vector3.new(0,20,0))
     local lift=core.Root.Position.Y-sc.Ground(core.Root.Position).Y
     local goal=CFrame.new(floor.X,floor.Y+lift,floor.Z)*core.Root.CFrame.Rotation
     if((core.Root.Position-goal.Position)*Vector3.new(1,0,1)).Magnitude>3 then
      if not sc.Blink(goal)then core.Root.CFrame=goal end
     end
    end)
    if not ok then warnOnce("center","[Polaris] could not move to the centre: "..tostring(err))end
   end
   A.StartCooldown(actor,S)
    -- the stars are synced to the cast's timer: the cast lasts S.Duration and the volleys are spread over all of it, so
    -- stars keep attacking until the time is up (the last one leaves FinalTail seconds before the end)
   local gap=math.max((S.Duration-S.Charge-S.Recovery-S.FinalTail)/math.max(S.Shots-1,1),.1)
   S=table.clone(S)S.ShotGap=gap  -- the visuals, sounds and clients read the real gap from this cast's style
   local total=S.Charge+(S.Shots-1)*gap+S.FinalTail+S.Recovery
   local fx  
   local ctx
   ctx=A.Create(actor,S,total+.3,function()
    if ctx and ctx.Tweens then
     for _,tw in ipairs(ctx.Tweens)do tw:Cancel()end
     table.clear(ctx.Tweens)
    end
    current=nil
    if fx then pcall(Visuals.Restore,fx)end
    actor:SetAttribute("PolarisActive",false)
    CollectionService:RemoveTag(actor,TAG)
   end)
   current=ctx.Cast ctx.AnchorBoss()actor:SetAttribute("PolarisActive",true)

    
   CollectionService:AddTag(actor,TAG)
   local function beat(kind,victim)
     
     
    beatSeq=beatSeq+1
    local seq=beatSeq
    local ok,err=pcall(function()
     local uid=0
     if typeof(victim)=="Instance"then
      if victim:IsA("Player")then
       uid=victim.UserId
      else
       local plr=Players:GetPlayerFromCharacter(victim:IsA("Model")and victim or victim:FindFirstAncestorOfClass("Model")or victim)
       if plr then uid=plr.UserId end
      end
     end
     actor:SetAttribute("PolarisBeat",kind..":"..seq..":"..uid)
    end)
    if not ok then warnOnce("beat","[Polaris] camera cue failed (attack continues): "..tostring(err))end
   end

   local function pose(k,dur)
    local arm,leg=math.min(k,1.75),math.min(k,1.15)
    local m={}
    for joint,a in pairs(BASE_POSE)do
     local f=(joint=="Waist")and 0 or(ARM[joint]and arm or leg)
     m[joint]={a[1]*f,a[2]*f,a[3]*f}
    end
    safe(core.PoseAngles,m,dur)
   end

   pose(.25,.3)  
   Encounter.Say("Night falls on my command. Look up... the north star has already chosen you.",nil,{Duration=3.6})
   ctx.Send("Start",{Center=core.Root.Position,Duration=total})
   beat("charge")

   do
    local ok,res=pcall(Visuals.Build,ctx,core.Root,S)
    if ok then fx=res else warnOnce("build","[Polaris] Visuals.Build failed, running without VFX: "..tostring(res))end
   end

   local targets=ctx.Targets()
    -- ground blast centred under the hovering boss
   local function blast(radius,damage)
    local c=core.Root.Position
    for _,char in ipairs(ctx.Targets())do
     local p=char.HumanoidRootPart.Position
     if((p-c)*Vector3.new(1,0,1)).Magnitude<=radius then ctx.Damage(char,damage,false,p+Vector3.yAxis*3)end
    end
   end
   local projectiles={}    
   local pending={}        
   local teleN,ci=0,1
   local finaleT=S.Charge+(S.Shots-1)*gap

    
   local cues={
    {S.Rise*.5,function()pose(1,.55)end},
    {S.Charge,function()
      pose(1.55,.1)
      beat("release")
      if fx then safe(Visuals.Release,ctx,fx,core.Root)end
      blast(S.ReleaseRadius,S.ReleaseDamage)
    end},
    {S.Charge+.25,function()pose(1.15,.45)end},
    {finaleT,function()
      pose(1.75,.1)
      beat("finale")
      Encounter.Say("Every star in this sky is aimed at you.",nil,{Duration=2.6})
      if fx then safe(Visuals.Finale,ctx,fx,core.Root)end
    end},
    {finaleT+.35,function()pose(1.1,.5)end},
    {total-S.Recovery,function()pose(0,S.Recovery*.9)end}
   }
    -- Starfall and North Cross: extra cues after the volley, inside the same cast time
   local SF,CR=S.Starfall,S.Cross
   local startPos=core.Root.Position
   local rayParams=RaycastParams.new()
   rayParams.FilterType=Enum.RaycastFilterType.Exclude
   do
    local ignore={actor}
    for _,ch in ipairs(targets)do ignore[#ignore+1]=ch end
    rayParams.FilterDescendantsInstances=ignore
   end
   local function groundAt(p)
    local hit=workspace:Raycast(p+Vector3.new(0,6,0),Vector3.new(0,-300,0),rayParams)
    return hit and hit.Position or p-Vector3.new(0,3,0)
   end
   local function living()
    local out={}
    for _,ch in ipairs(targets)do
     if ctx.Target(ch)and ch:FindFirstChild("HumanoidRootPart")then out[#out+1]=ch end
    end
    return out
   end
   if SF then
    for i=1,S.Shots-1 do
     cues[#cues+1]={finaleT+SF.Start+(i-1)*SF.Gap,function()
      local alive=living()
      if #alive==0 then return end
      local r=alive[(i-1)%#alive+1].HumanoidRootPart
      local lead=r.AssemblyLinearVelocity*Vector3.new(1,0,1)*SF.Lead
      local jitter=Vector3.new(math.random()*2-1,0,math.random()*2-1)*SF.Jitter
      local spot=groundAt(r.Position+lead+jitter)
      local color=A.Palette[(i-1)%#A.Palette+1]
      if fx then safe(Visuals.Starfall,ctx,fx,{Index=i,To=spot,Warn=SF.Warn,Color=color,Radius=SF.Radius})end
      ctx.Cast:Schedule(SF.Warn,function()
       for _,ch in ipairs(living())do
        local p=ch.HumanoidRootPart.Position
        if((p-spot)*Vector3.new(1,0,1)).Magnitude<=SF.Radius and math.abs(p.Y-spot.Y)<=10 then
         ctx.Damage(ch,SF.Damage,false,spot)
         beat("hit",ch)
        end
       end
       if fx then safe(Visuals.StarfallHit,ctx,fx,spot,color,SF.Radius)end
      end)
     end}
    end
   end
   if CR then
    local firstAngle
    local function cross(at,index)
     cues[#cues+1]={at,function()
      local center=groundAt(startPos)
      local ang
      if index==1 then
        -- aim one blade at the nearest target
       ang=0
       local best
       for _,ch in ipairs(living())do
        local o=(ch.HumanoidRootPart.Position-center)*Vector3.new(1,0,1)
        if o.Magnitude>.1 and(not best or o.Magnitude<best.Magnitude)then best=o end
       end
       if best then ang=math.atan2(best.Z,best.X)end
       firstAngle=ang
      else
        -- the follow-up covers the gaps the first one left
       ang=(firstAngle or 0)+math.pi/4
      end
      local spec={Center=center,Angle=ang,Length=CR.Length,Width=CR.Width,Warn=CR.Warn,Index=index}
      if fx then safe(Visuals.Cross,ctx,fx,spec)end
      ctx.Cast:Schedule(CR.Warn,function()
       for _,ch in ipairs(living())do
        local o=ch.HumanoidRootPart.Position-center
        if math.abs(o.Y)<=CR.Height then
         local flat=o*Vector3.new(1,0,1)
         for k=0,3 do
          local a=ang+k*math.pi/2
          local dir=Vector3.new(math.cos(a),0,math.sin(a))
          local along=flat:Dot(dir)
          if along>=-CR.Width*.5 and along<=CR.Length and(flat-dir*along).Magnitude<=CR.Width*.5 then
           ctx.Damage(ch,CR.Damage,false,center+dir*along)
           beat("hit",ch)
           break
          end
         end
        end
       end
       if fx then safe(Visuals.CrossHit,ctx,fx,spec)end
      end)
     end}
    end
    cross(finaleT+CR.Start,1)
    cross(finaleT+CR.Start+CR.Second,2)
   end
    -- the north star explodes (client draws it at the same moment)
   cues[#cues+1]={total-1.65,function()blast(S.FinalRadius,S.FinalDamage)end}
   table.sort(cues,function(a,b)return a[1]<b[1]end)

   local function fireShot(p)
    local rec={Color=p.Color,Last=p.From,Hit=false}
    local scale=p.Final and 1.5 or 1
    rec.Proj=A.Shoot(ctx,p.From,p.Char,S,p.Color,function(victim,impact)
     rec.Hit=true
     ctx.Damage(victim,S.HitDamage,false,impact)ctx.Burn(victim,S.Burn,S.BurnInterval,ctx.Cast,nil,impact)
     if fx then
      local r=rootOf(victim)
      safe(Visuals.Impact,ctx,fx,r and r.Position or rec.Last,p.Color,p.Final)
     end
     beat("hit",victim)
    end,function(c,origin,color)
     local ok,part=pcall(Visuals.Projectile,c,origin,color,scale)
     if not ok or not part then
      warnOnce("projectile","[Polaris] Visuals.Projectile failed, using plain projectile: "..tostring(part))
      part=c.Part("AuroraProjectile",Vector3.one*2.2,origin,color,.08)
     end
     rec.Part=part
     return part
    end)
    if rec.Proj then projectiles[#projectiles+1]=rec end
    if fx then safe(Visuals.Fire,ctx,fx,p.From,p.Color,p.Volley,p.Final)end
   end

   -- Borealis rains down while the stars fall: AU.Roaming beams wander the arena on their own (they follow no one) and
    -- AU.Hunting beams follow a player. They use the beacon P5Borealis already draws, but just burn and chill whoever
   do
    local AU=require(script.Parent.Style).Aurora
    if AU then
     local BS=table.clone(BorealisStyle)
     local spawnAt=S.Charge
     BS.Windup=AU.Windup BS.Capture=0
     BS.Chase=math.max(total-S.Recovery-spawnAt-AU.Windup-AU.Tail,1)
     local endAt=spawnAt+AU.Windup+BS.Chase
     local centre=groundAt(startPos)
     local FLAT=Vector3.new(1,0,1)
     local beams,spawned={},false
     -- anywhere on the map: a random spot across the whole arena floor
     local function anywhere()
      local okB,bounds=pcall(function() return require(B.Encounter.ArenaPlacement).GetBounds() end)
      if okB and bounds then
       local x=(math.random()*2-1)*(bounds.HalfX-8)
       local z=(math.random()*2-1)*(bounds.HalfZ-8)
       return ctx.Ground(bounds.Frame:PointToWorldSpace(Vector3.new(x,0,z)))
      end
      local a,d=math.random()*math.pi*2,AU.Roam*math.sqrt(math.random())
      return ctx.Ground(centre+Vector3.new(math.cos(a)*d,0,math.sin(a)*d))
     end
     local function roamGoal() return anywhere() end
     local function addBeam(kind,index)
      local rec={Kind=kind,Point=anywhere(),Inside={},NextTick=0,Token={name="PolarisBorealis"}}
      if kind=="Roam" then rec.Goal=roamGoal()
      else
       local alive=living()
       rec.Target=#alive>0 and alive[(index-1)%#alive+1] or nil
      end
      rec.Anchor=BorealisVisuals.Build(ctx,rec.Target,rec.Point,100+index,BS)
      beams[#beams+1]=rec
     end
     ctx.Step(function(dt,t)
      if t<spawnAt then return true end
      if not spawned then
       spawned=true
       for i=1,AU.Roaming do addBeam("Roam",i) end
       for i=1,AU.Hunting do addBeam("Hunt",i) end
      end
      for _,rec in ipairs(beams)do
       if not rec.Done then
        if t>=endAt then
         BorealisVisuals.Finish(rec,false)
        else
         if rec.Kind=="Roam" then
          local delta=(rec.Goal-rec.Point)*FLAT
          if delta.Magnitude<3 then rec.Goal=roamGoal()
          else rec.Point+=delta.Unit*math.min(delta.Magnitude,AU.RoamSpeed*dt)end
         else
          if not(rec.Target and ctx.Target(rec.Target))then
           local alive=living()
           rec.Target=#alive>0 and alive[math.random(1,#alive)] or nil
          end
          local r=rec.Target and rec.Target:FindFirstChild("HumanoidRootPart")
          if r then
           local delta=(r.Position-rec.Point)*FLAT
           if delta.Magnitude>.01 then rec.Point+=delta.Unit*math.min(delta.Magnitude,AU.HuntSpeed*dt)end
          end
         end
         rec.Anchor.Position=rec.Point
         if t>=spawnAt+AU.Windup then
          local tick=t>=rec.NextTick
          if tick then rec.NextTick=t+BS.TickInterval end
          for _,ch in ipairs(living())do
           local p=ch.HumanoidRootPart.Position
           local inside=((p-rec.Point)*FLAT).Magnitude<=BS.Radius and p.Y>=rec.Point.Y-3 and p.Y<=rec.Point.Y+BS.Height
           if inside then
            if not rec.Inside[ch] then
             rec.Inside[ch]=true
             Status.ApplySlow(ch,BS.FrostSlow,BS.FrostSeconds,"P5BorealisFrost")
            end
            if tick then ctx.Damage(ch,AU.TickDamage,true,rec.Point+Vector3.yAxis*3)end
           else
            rec.Inside[ch]=nil
           end
          end
         end
        end
       end
      end
      return t<total
     end)
    end
   end

   ctx.Step(function(dt,t)
     
    local h=S.Hover
    if t<S.Rise then h=S.Hover*riseCurve(t/S.Rise)end
    local bobK=math.clamp((t-S.Rise)/1,0,1)*math.clamp((total-S.Recovery-t)/.5,0,1)
    h=h+math.sin((t-S.Rise)*1.4)*1.1*bobK
    if t>=total-S.Recovery then h=S.Hover*smooth((total-t)/S.Recovery)end
    ctx.Hover(h)

    while ci<=#cues and t>=cues[ci][1]do
     local fn=cues[ci][2]
     ci=ci+1
     safe(fn)
    end

     
    while teleN<S.Shots and t>=S.Charge+teleN*gap-S.Telegraph do
     teleN=teleN+1
     local v=teleN
     local final=v==S.Shots
     local fireAt=S.Charge+(v-1)*gap
     local color=A.Palette[(v-1)%#A.Palette+1]
     for ti,char in ipairs(targets)do
      if ctx.Target(char)then
       local r=char:FindFirstChild("HumanoidRootPart")
       if r then
        local from
        if final then
         from=r.Position+Vector3.new(0,S.GateHeight*1.15,0)  
        else
          
         local ang=v*2.39996+ti*1.7
         local rad=S.GateRadius*(.55+.45*((v*3)%5)/4)
         from=r.Position+Vector3.new(math.cos(ang)*rad,S.GateHeight,math.sin(ang)*rad)
        end
        pending[#pending+1]={Volley=v,Char=char,From=from,Color=color,FireAt=fireAt,Final=final}
        if fx then
         safe(Visuals.Telegraph,ctx,fx,{From=from,Root=r,Color=color,Start=t,Duration=math.max(fireAt-t,.05),Volley=v,Final=final})
        end
       end
      end
     end
    end

     
    local i=1
    while i<=#pending do
     local p=pending[i]
     if t>=p.FireAt then
      table.remove(pending,i)
      if ctx.Target(p.Char)then fireShot(p)end
     else
      i=i+1
     end
    end

    for j=#projectiles,1,-1 do
     local rec=projectiles[j]
     local part=rec.Part
     if part and part.Parent then rec.Last=part.Position end
     if not rec.Proj.Step(dt)then
      if fx and not rec.Hit then safe(Visuals.Fizzle,ctx,fx,rec.Last,rec.Color)end
      table.remove(projectiles,j)
     end
    end

    if fx then safe(Visuals.Update,fx,core.Root,t,dt)end
    if t>=total then ctx.Cast:Dispose()return false end
    return true
   end)
   ctx.Wait()return true
  end)
 end
 function api.Dispose()if current then current:Dispose()end end
 return api
end

local B=script:FindFirstAncestor("BossSystem")
local A=require(B.Attacks.Shared.P5AstralCore)
local S=require(script.Parent.Style)
require(script.Parent.Presentation).Publish()
local Visuals=require(script.Parent.Visuals)
local Players=game:GetService("Players")
local CollectionService=game:GetService("CollectionService")

local Encounter=require(B.Players.PlayerEncounter)
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
  local S=require(B.Attacks.Shared.P5AstralCore).Tune(actor,S,{Speed={"ProjectileSpeed"},Agile={"TurnRate"},Count={"Shots"},Tell={"Telegraph"}})  -- difficulty knobs, this cast only
  if not api.CanUse(target)then return false end
  local core=require(B.Combat.AttackRegistry).For(actor,"P1CombatCore")
  return core.Perform(target,S.Name,function()
   A.StartCooldown(actor,S)
   local total=S.Charge+(S.Shots-1)*S.ShotGap+S.ProjectileLife+#S.Burn*S.BurnInterval+S.Recovery
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
   local finaleT=S.Charge+(S.Shots-1)*S.ShotGap

    
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

     
    while teleN<S.Shots and t>=S.Charge+teleN*S.ShotGap-S.Telegraph do
     teleN=teleN+1
     local v=teleN
     local final=v==S.Shots
     local fireAt=S.Charge+(v-1)*S.ShotGap
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
